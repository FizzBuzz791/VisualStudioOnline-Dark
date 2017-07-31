If Not Exists (Select 1 From Crusher Where Crusher_Id = 'JB-C3')
Begin

	Insert Into Crusher (Crusher_Id, Description, Is_Visible)
		Select 'JB-C3', 'Jimblebar Crusher 3', 1


	Insert Into CrusherLocation (Crusher_Id, Location_Type_Id, Location_Id)
		Select 'JB-C3', 3, 12
	
End

If Not Exists (Select 1 From Weightometer Where Weightometer_Id = 'JB-C3OutFlow')
Begin

	print 'skipping weightometers...'

	--Insert Into Weightometer ( Weightometer_Id, Description, Is_Visible, Weightometer_Type_Id, Weightometer_Group_Id)
	--	Select 'JB-C3OutFlow', 'Jimblebar Crusher 3 OutFlow', 1, 'CVF+L1', NULL
		
		
	--Insert Into WeightometerLocation (Weightometer_Id, Location_Type_Id, Location_Id)
	--	Select 'JB-C3OutFlow', 3, 12
		
		
	----Insert Into WeightometerFlowPeriod (Weightometer_Id, End_Date, Source_Stockpile_Id, Source_Crusher_Id, Source_Mill_Id, Destination_Stockpile_Id, Destination_Crusher_Id, 
	----	Destination_Mill_Id, Is_Calculated, Processing_Order_No)
	----		Select 'JB-C3OutFlow', Null, Null, 'JB-C3', Null, Null, Null, Null, 0, 24
	


End

If Not Exists (Select 1 From BhpbioProductionResolveBasic Where Code = 'JB-CR03')
Begin

	Insert Into BhpbioProductionResolveBasic ([Code], [Resolve_From_Date], [Resolve_From_Shift], [Crusher_Id], [Description], [Production_Direction])
		Select 'JB-CR03', '2016-01-01', 'D', 'JB-OHP1', 'JB Crusher 3 to JB-OHP 1', 'B'

	Insert Into HaulageResolveBasic (Code, Resolve_From_Date, Resolve_From_Shift, Resolve_To_Date, Resolve_To_Shift, Stockpile_Id, Build_Id, Component_Id, 
                      Digblock_Id, Crusher_Id, Mill_Id, Description, Haulage_Direction)
		Select 	'JB-CR03', '2016-01-01', 'D', NULL, NULL, NULL, NULL, NULL, NULL, 'JB-OHP1', NULL, 'Jimblebar CR03 to OHP1', 'B'
		

End

Go