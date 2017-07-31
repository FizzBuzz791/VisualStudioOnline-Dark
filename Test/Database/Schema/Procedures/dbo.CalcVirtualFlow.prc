IF OBJECT_ID('dbo.CalcVirtualFlow') IS NOT NULL
	DROP PROCEDURE dbo.CalcVirtualFlow
GO 
  
CREATE PROCEDURE dbo.CalcVirtualFlow
AS 
BEGIN 

	SET NOCOUNT ON 
	
	BEGIN TRY

		DECLARE @CalcDate DATETIME
		DECLARE @CalcVirtualFlowId INT

		SET @CalcVirtualFlowId = 0
		SELECT TOP 1 @CalcDate = Calc_Date, @CalcVirtualFlowId = Calc_Virtual_Flow_Id
		FROM CalcVirtualFlowQueue
		ORDER BY Calc_Date, Calc_Virtual_Flow_Id Desc

		WHILE (COALESCE(@CalcVirtualFlowId, 0) > 0)
		BEGIN
			EXEC dbo.CalcWhalebackVirtualFlowBene
				@iCalcDate = @CalcDate		

			EXEC dbo.CalcWhalebackVirtualFlowOHP4
				@iCalcDate = @CalcDate
											
			EXEC dbo.CalcWhalebackVirtualFlowC2
				@iCalcDate = @CalcDate
											
			EXEC dbo.CalcYandiVirtualFlow
				@iCalcDate = @CalcDate	
				
			EXEC dbo.CalcNjvVirtualFlow
				@iCalcDate = @CalcDate	
			
			DELETE FROM CalcVirtualFlowQueue
			WHERE Calc_Date = @CalcDate
				AND Calc_Virtual_Flow_Id <= @CalcVirtualFlowId
			
			EXEC RecalcL1Raise @CalcDate
					  
			SET @CalcVirtualFlowId = 0
			SELECT TOP 1 @CalcDate = Calc_Date, @CalcVirtualFlowId = Calc_Virtual_Flow_Id
			FROM CalcVirtualFlowQueue
			ORDER BY Calc_Date, Calc_Virtual_Flow_Id Desc
		END
		
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.CalcVirtualFlow TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.CalcVirtualFlow">
 <Procedure>
	Processes the Calc Virtual Flow Queue in date order, and calls the Whaleback and  Yandi calc virtual flows
 </Procedure>
</TAG>
*/

