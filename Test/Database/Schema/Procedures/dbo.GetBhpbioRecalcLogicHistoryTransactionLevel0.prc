If object_id('dbo.GetBhpbioRecalcLogicHistoryTransactionLevel0') Is Not Null 
     Drop Procedure dbo.GetBhpbioRecalcLogicHistoryTransactionLevel0 
Go 
  
Create Procedure dbo.GetBhpbioRecalcLogicHistoryTransactionLevel0 
( 
	@iFrom_Date Datetime ,		
	@iFrom_Shift Char(1),			
	@iTo_Date Datetime,				
	@iTo_Shift Char(1),				
	@iSource Varchar(31) = Null,			
	@iDestination Varchar(31) = Null,		
	@iTransaction_Type Varchar(31) = Null,
	@iInclude_Grades Bit = 0,
	@iSource_Type VARCHAR(31) = Null
) 
With Encryption As 
Begin 
    Set NoCount On 
  
    Set Transaction Isolation Level Repeatable Read 
    Begin Transaction 
  
		-- Create a temporary table to hold the main listing information
		Create Table dbo.#TRANSACTION_LIST
		(
			Transaction_List_Id Int Identity(1, 1) Not Null,
			Date Datetime Null,
			Shift Char(1) Collate Database_Default Null,
			Original_Source Varchar(31) Collate Database_Default Null,
			Original_Destination Varchar(31) Collate Database_Default Null,
			Transaction_Type Varchar(31) Collate Database_Default Null,
			Record_Id BigInt Null,
			Recalc_History_Id BigInt Null,
			Recalc_Logic_History_Id BigInt Null,
			Min_Data_Transaction_Tonnes_Id BigInt Null,
			Equipment Varchar(31) Collate Database_Default Null,
			Action Varchar(128) Collate Database_Default Not Null,
			Orig_Tonnes Float Null,
			New_Tonnes Float Null,
			Tonnes_Perc_Diff Real Null,
			Tonnes_Abs_Diff Float Null
			
			--Primary Key (Transaction_List_Id)
		)

		Create NonClustered Index IX_TRANSACTION_LIST_01
			On dbo.#TRANSACTION_LIST (Record_Id)

		-- Create the related grade temporary tables
		Create Table dbo.#TRANSACTION_LIST_GRADE
		(
			Transaction_List_Id Int Not Null,
			Grade_Id Int Not Null,
			Grade_Name Varchar(31) Collate Database_Default Not Null,
			Grade_Value Real Null
	
			Primary Key(Transaction_List_Id, Grade_Name)
		)  
		
		Create Table dbo.#VALID_SOURCES
		(
			Source_Id VARCHAR(31) Collate Database_Default not Null
			primary key (source_id)
		)  


		Declare @From_Shift_Order Int,
			@To_Shift_Order Int

		Select @From_Shift_Order = dbo.GetShiftTypeOrderNo(@iFrom_Shift),
			@To_Shift_Order = dbo.GetShiftTypeOrderNo(@iTo_Shift)

		-- If the option is to include haulage data
		If (IsNull(@iTransaction_Type, 'Haulage') = 'Haulage')
		Begin
			-- Insert the details for haulage records into the temporary table
			Insert Into dbo.#TRANSACTION_LIST
			(
				Date, Shift, Original_Source, Original_Destination,
				Transaction_Type, Record_Id, Min_Data_Transaction_Tonnes_Id,
				Equipment, Action, Orig_Tonnes, New_Tonnes
			)
			Select H.Haulage_Date, H.Haulage_Shift,
				Coalesce(H.Source_Digblock_Id, SS.Stockpile_Name, H.Source_Mill_Id),
				Coalesce(DS.Stockpile_Name, H.Destination_Crusher_Id, H.Destination_Mill_Id),
				'Haulage', H.Haulage_Id, RHLDTT.Min_Data_Transaction_Tonnes_Id,
				H.Truck_Id, 'Summary', H.Tonnes, 0
			From dbo.Haulage As H
				Inner Join dbo.ShiftType As ST
					On (H.Haulage_Shift = ST.Shift)
				Inner Join 
					(
						--Get the minimum DTT Id and ensure that this haulage record has 
						--a logic history record attached to it.
						Select H.Haulage_Id, Min(DTT.Data_Transaction_Tonnes_Id) As Min_Data_Transaction_Tonnes_Id
						From dbo.Haulage As H
							Left Outer Join dbo.DataTransactionTonnes As DTT
								On (DTT.Haulage_Id = H.Haulage_Id)
						Where H.Haulage_Date Between @iFrom_Date And @iTo_Date --Cut down on grouping
							And Exists 
								( 
									Select Top 1 1 
									From dbo.RecalcLogicHistory AS RLH
									Where RLH.Data_Transaction_Tonnes_Id = DTT.Data_Transaction_Tonnes_Id
									Union
									Select Top 1 1 
									From dbo.RecalcLogicHistory AS RLH 
									Where RLH.Haulage_Id = H.Haulage_Id
								)
						Group by H.Haulage_Id
					) As RHLDTT
					On (H.Haulage_Id = RHLDTT.Haulage_Id)
				Left Outer Join dbo.Stockpile As SS
					On (H.Source_Stockpile_Id = SS.Stockpile_Id)
				Left Outer Join dbo.Stockpile As DS
					On (H.Destination_Stockpile_Id = DS.Stockpile_Id)
			Where H.Haulage_Date Between @iFrom_Date And @iTo_Date --Index Optimisation
				And dbo.GetDateShiftAsInt(H.Haulage_Date, ST.Order_No) >= dbo.GetDateShiftAsInt(@iFrom_Date, @From_Shift_Order)
				And dbo.GetDateShiftAsInt(H.Haulage_Date, ST.Order_No) <= dbo.GetDateShiftAsInt(@iTo_Date, @To_Shift_Order)
				And (@iSource Is Null
					Or Coalesce(H.Source_Digblock_Id, Convert(Varchar, SS.Stockpile_Id), H.Source_Mill_Id) = @iSource)
				And (@iDestination Is Null
					Or Coalesce(Convert(Varchar, DS.Stockpile_Id), H.Destination_Crusher_Id, H.Destination_Mill_Id) = @iDestination)



			-- Set the new value for tonnes, based on the final version from the transaction table
			-- If the record has no DTT record (ie haulage to crusher with no weightometer sample and the Use CV tonnes setting is true)
			-- Then this is valid as being 0.
			Update TL
			Set	New_Tonnes = IsNull(
				(
					Select Sum(DPT2.Tonnes)
					From dbo.DataProcessTransaction As DPT2
						Inner Join DataTransactionTonnes DTT2
							On DPT2.Data_Transaction_Tonnes_Id = DTT2.Data_Transaction_Tonnes_Id
					Where TL.Record_Id = DTT2.Haulage_Id
				), 0)
			From #TRANSACTION_LIST As TL
			Where TL.Transaction_Type = 'Haulage'


			If @iInclude_Grades = 1 
			Begin
				--Get Original Haulage Grade
				Insert Into #TRANSACTION_LIST_GRADE
				(
					Transaction_List_Id, Grade_Id, Grade_Name, Grade_Value
				)
				Select TL.Transaction_List_Id, G.Grade_Id, 
					'Orig_' + G.Grade_Name, HG.Grade_Value
				From dbo.#TRANSACTION_LIST As TL
					Inner Join dbo.HaulageGrade As HG
						On (TL.Record_Id = HG.Haulage_Id)
					Inner Join dbo.Grade As G
						On (G.Grade_Id = HG.Grade_Id)
				Where TL.Transaction_Type = 'Haulage'

				--Get the new mass averaged DPT Grade
				Insert Into #TRANSACTION_LIST_GRADE
				(
					Transaction_List_Id, Grade_Id, Grade_Name, Grade_Value
				)
				Select TL.Transaction_List_Id, G.Grade_Id, 'New_' + G.Grade_Name, 
					Sum(DPTG.Grade_Value * DPT.Tonnes) / NullIf(Sum(DPT.Tonnes), 0)
				From dbo.#TRANSACTION_LIST As TL
					Inner Join dbo.DataTransactionTonnes As DTT
						On (TL.Record_Id = DTT.Haulage_Id)
					Inner Join dbo.DataProcessTransaction As DPT
						On (DPT.Data_Transaction_Tonnes_Id = DTT.Data_Transaction_Tonnes_Id)
					Inner Join dbo.DataProcessTransactionGrade As DPTG
						On (DPT.Data_Process_Transaction_Id = DPTG.Data_Process_Transaction_Id)
					Inner Join dbo.Grade As G
						On (G.Grade_Id = DPTG.Grade_Id)
				Where TL.Transaction_Type = 'Haulage'
				Group By TL.Transaction_List_Id, G.Grade_Id, G.Grade_Name
			End
		End

		-- If the option is to include weightometer data
		If (IsNull(@iTransaction_Type, 'Weightometer') = 'Weightometer')
		Begin
			-- Insert the details for weightometer sample records into the temporary table
			Insert Into #TRANSACTION_LIST
			(
				Date, Shift, Original_Source, Original_Destination,
				Transaction_Type, Record_Id, Min_Data_Transaction_Tonnes_Id,
				Equipment, Action, Orig_Tonnes, New_Tonnes
			)
			Select WS.Weightometer_Sample_Date, WS.Weightometer_Sample_Shift,
				Coalesce(SS.Stockpile_Name, WFP.Source_Crusher_Id, WFP.Source_Mill_Id),
				Coalesce(DS.Stockpile_Name, WFP.Destination_Crusher_Id, WFP.Destination_Mill_Id),
				'Weightometer', WS.Weightometer_Sample_Id, RHLDTT.Min_Data_Transaction_Tonnes_Id,
				WS.Weightometer_Id, 'Summary', Coalesce(WS.Corrected_Tonnes, WS.Tonnes), 0
			From dbo.WeightometerSample As WS
				Inner Join dbo.ShiftType As ST
					On (WS.Weightometer_Sample_Shift = ST.Shift)
				Inner Join 
					(
						--Get the minimum DTT Id and ensure that this haulage record has 
						--a logic history record attached to it.
						Select WS.Weightometer_Sample_Id, Min(DTTF.Data_Transaction_Tonnes_Id) As Min_Data_Transaction_Tonnes_Id
						From dbo.WeightometerSample As WS
							Left Outer Join dbo.DataTransactionTonnesFlow As DTTF
								On (WS.Weightometer_Sample_Id = DTTF.Weightometer_Sample_Id)
						Where WS.Weightometer_Sample_Date Between @iFrom_Date And @iTo_Date --Cut down on grouping
							And Exists 
								( 
									Select Top 1 1 
									From dbo.RecalcLogicHistory AS RLH
									Where RLH.Data_Transaction_Tonnes_Id = DTTF.Data_Transaction_Tonnes_Id
									Union
									Select Top 1 1 
									From dbo.RecalcLogicHistory AS RLH 
									Where RLH.Weightometer_Sample_Id = WS.Weightometer_Sample_Id
								)
						Group by WS.Weightometer_Sample_Id
					) As RHLDTT
					On (WS.Weightometer_Sample_Id = RHLDTT.Weightometer_Sample_Id)
				Left Outer Join dbo.WeightometerFlowPeriod As WFP
					On (WS.Weightometer_Id = WFP.Weightometer_Id
						And IsNull(WFP.End_Date, '1900-01-01') = IsNull(	
							( --This sub query adds a second, theres gotta be a better way to optimise
								Select Max(WFP2.End_Date)
								From dbo.WeightometerFlowPeriod As WFP2
								Where WFP2.Weightometer_Id = WS.Weightometer_Id
									And WFP2.End_Date >= WS.Weightometer_Sample_Date
							), '1900-01-01')
						)
				Left Outer Join dbo.Stockpile As SS
					On (Coalesce(WS.Source_Stockpile_Id, WFP.Source_Stockpile_Id) = SS.Stockpile_Id)
				Left Outer Join dbo.Stockpile As DS
					On (Coalesce(WS.Destination_Stockpile_Id, WFP.Destination_Stockpile_Id) = DS.Stockpile_Id)
			Where WS.Weightometer_Sample_Date Between @iFrom_Date And @iTo_Date --Index Optimisation
				And dbo.GetDateShiftAsInt(WS.Weightometer_Sample_Date, ST.Order_No) >= dbo.GetDateShiftAsInt(@iFrom_Date, @From_Shift_Order)
				And dbo.GetDateShiftAsInt(Ws.Weightometer_Sample_Date, ST.Order_No) <= dbo.GetDateShiftAsInt(@iTo_Date, @To_Shift_Order)
				And (@iSource Is Null
					Or Coalesce(Convert(Varchar, SS.Stockpile_Id), WFP.Source_Crusher_Id, WFP.Source_Mill_Id) = @iSource)
				And (@iDestination Is Null
					Or Coalesce(Convert(Varchar, DS.Stockpile_Id), WFP.Destination_Crusher_Id, WFP.Destination_Mill_Id) = @iDestination)

			-- Set the new value for tonnes, based on the final version from the transaction table
			Update TL
			Set	New_Tonnes = AGG.Tonnes
			From dbo.#TRANSACTION_LIST As TL
				Inner Join
					(
						Select TL.Transaction_List_Id, Sum(DPT.Tonnes) As Tonnes
						From dbo.DataProcessTransaction As DPT
							Inner Join dbo.DataTransactionTonnesFlow As DTTF
								On (DPT.Data_Transaction_Tonnes_Id = DTTF.Data_Transaction_Tonnes_Id)
							Inner Join dbo.#TRANSACTION_LIST As TL
								On (TL.Record_Id = DTTF.Weightometer_Sample_Id)	
						Group By TL.Transaction_List_Id
					) As AGG
					On (TL.Transaction_List_Id = AGG.Transaction_List_Id)
			Where TL.Transaction_Type = 'Weightometer'

			-- Insert the related grade records into the grade tables
			If @iInclude_Grades = 1 
			Begin
				Insert Into #TRANSACTION_LIST_GRADE
				(
					Transaction_List_Id, Grade_Id, Grade_Name, Grade_Value
				)
				Select TL.Transaction_List_Id, G.Grade_Id, 'Orig_' + G.Grade_Name, WSG.Grade_Value
				From dbo.#TRANSACTION_LIST As TL
					Inner Join dbo.WeightometerSampleGrade As WSG
						On (TL.Record_Id = WSG.Weightometer_Sample_Id)
					Inner Join dbo.Grade As G
						On (G.Grade_Id = WSG.Grade_Id)
				Where TL.Transaction_Type = 'Weightometer'

				Insert Into #TRANSACTION_LIST_GRADE
				(
					Transaction_List_Id,
					Grade_Id, Grade_Name, Grade_Value
				)
				Select TL.Transaction_List_Id, G.Grade_Id, 'New_' + G.Grade_Name, 
					Sum(DPTG.Grade_Value * DPT.Tonnes) / NullIf(Sum(DPT.Tonnes), 0)
				From #TRANSACTION_LIST As TL
					Inner Join dbo.DataTransactionTonnesFlow DTTF
						On TL.Record_Id = DTTF.Weightometer_Sample_Id
					Inner Join dbo.DataProcessTransaction As DPT
						On DPT.Data_Transaction_Tonnes_Id = DTTF.Data_Transaction_Tonnes_Id
					Inner Join dbo.DataProcessTransactionGrade DPTG
						On DPT.Data_Process_Transaction_Id = DPTG.Data_Process_Transaction_Id
					Inner Join dbo.Grade As G
						On (G.Grade_Id = DPTG.Grade_Id)
				Where TL.Transaction_Type = 'Weightometer'
				Group By TL.Transaction_List_Id, G.Grade_Id, G.Grade_Name
			End
		End
			
		-------------------------------------------------------------------------
		-- Update the difference details	
		-------------------------------------------------------------------------
		Update TL
		Set	Tonnes_Perc_Diff = Round((New_Tonnes - Orig_Tonnes) / Orig_Tonnes, 8)
		From dbo.#TRANSACTION_LIST As TL
		Where Orig_Tonnes > 0
			And New_Tonnes > 0

		Update TL
		Set	Tonnes_Abs_Diff = Round(New_Tonnes - Orig_Tonnes, 2)
		From dbo.#TRANSACTION_LIST As TL

		If @iInclude_Grades = 1
		Begin
			Insert Into dbo.#TRANSACTION_LIST_GRADE
			(
				Transaction_List_Id,
				Grade_Id, Grade_Name, Grade_Value
			)
			Select TLOG.Transaction_List_Id,
				TLOG.Grade_Id, G.Grade_Name + '_Perc_Diff',
				Case When (TLOG.Grade_Value > 0 And TLNG.Grade_Value > 0) Then
					Round((TLNG.Grade_Value - TLOG.Grade_Value) / TLOG.Grade_Value, 8)
				Else
					Null
				End
			From dbo.#TRANSACTION_LIST_GRADE As TLOG
				Inner Join dbo.#TRANSACTION_LIST_GRADE As TLNG
					On (TLOG.Transaction_List_Id = TLNG.Transaction_List_Id
						And TLOG.Grade_Id = TLNG.Grade_Id)
				Inner Join dbo.Grade As G
					On (TLOG.Grade_Id = G.Grade_Id)
			Where CharIndex('Orig_', TLOG.Grade_Name) > 0
				And CharIndex('New_', TLNG.Grade_Name) > 0

			Insert Into dbo.#TRANSACTION_LIST_GRADE
			(
				Transaction_List_Id,
				Grade_Id, Grade_Name, Grade_Value
			)
			Select TLOG.Transaction_List_Id,
				TLOG.Grade_Id, G.Grade_Name + '_Abs_Diff',
				TLNG.Grade_Value - TLOG.Grade_Value
			From dbo.#TRANSACTION_LIST_GRADE As TLOG
				Inner Join dbo.#TRANSACTION_LIST_GRADE As TLNG
					On (TLOG.Transaction_List_Id = TLNG.Transaction_List_Id
						And TLOG.Grade_Id = TLNG.Grade_Id)
				Inner Join dbo.Grade As G
					On (TLOG.Grade_Id = G.Grade_Id)
			Where CharIndex('Orig_', TLOG.Grade_Name) > 0
				And CharIndex('New_', TLNG.Grade_Name) > 0
			
			--Add Missing Grades to the mix to ensure maximum pivot and then pivot
			Insert Into dbo.#TRANSACTION_LIST_GRADE
			(
				Transaction_List_Id, Grade_Id, Grade_Name
			)
			Select -1, G.Grade_Id, 'Orig_' + G.Grade_Name
			From dbo.Grade As G
			Union All
			Select -1, G.Grade_Id, 'New_' + G.Grade_Name
			From dbo.Grade As G
			Union All
			Select -1, G.Grade_Id, G.Grade_Name + '_Abs_Diff' 
			From dbo.Grade As G
			Union All
			Select -1, G.Grade_Id, G.Grade_Name + '_Perc_Diff'
			From dbo.Grade As G

			-- Pivot the grade fields as required
			Exec dbo.PivotTable
				@iTargetTable = '#TRANSACTION_LIST',
				@iPivotTable = '#TRANSACTION_LIST_GRADE',
				@iJoinColumns = '#TRANSACTION_LIST.Transaction_List_Id = #TRANSACTION_LIST_GRADE.Transaction_List_Id',
				@iPivotColumn = 'Grade_Name',
				@iPivotValue = 'Grade_Value',
				@iPivotType = 'Real'
		End
		
		If ISNULL(@iSource_Type, '2') = '2'
		begin
			insert into #VALID_SOURCES
			Select stockpile_name from dbo.stockpile
		end

		If ISNULL(@iSource_Type, '3') = '3'
		begin
			insert into #VALID_SOURCES
			Select crusher_id from dbo.crusher
		end

		If ISNULL(@iSource_Type, '1') = '1'
		begin
			insert into #VALID_SOURCES
			Select digblock_id from dbo.digblock
		end
		
		Select TL.*
		From  dbo.#TRANSACTION_LIST As TL
			Left Outer Join dbo.ShiftType As ST
				On (ST.Shift = TL.Shift)
		Where Tl.Original_Source in (Select Source_Id From dbo.#VALID_SOURCES)
		Order By Date, ST.Order_No, Min_Data_Transaction_Tonnes_Id, 
			Transaction_Type, Record_Id
			
		Drop Table dbo.#VALID_SOURCES
		Drop Table dbo.#TRANSACTION_LIST
		Drop Table dbo.#TRANSACTION_LIST_GRADE  
	
    Commit Transaction 
End 
Go 
GRANT EXECUTE ON dbo.GetBhpbioRecalcLogicHistoryTransactionLevel0 TO BhpbioGenericManager

/*
<TAG Name="Data Dictionary" ProcedureName="GetBhpbioRecalcLogicHistoryTransactionLevel0">
 <Procedure>
	Returns the base level recalc logic records and the necessary before and after comparison details.
	Transaction type is exclusively, 'Weightometer' or 'Haulage'.
 </Procedure>
</TAG>
*/	

