IF OBJECT_ID('dbo.GetBhpbioShippingTargets') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioShippingTargets
GO 
  
CREATE PROCEDURE dbo.GetBhpbioShippingTargets
(
	@iProductTypeId int,
	@iActiveInDateTime DATETIME
)
WITH ENCRYPTION
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioShippingTargets',
		@TransactionCount = @@TranCount

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY
		
		-- declare a temporary table used to update shipping targets with their effective end date
		DECLARE @shippingTargets TABLE (
			[TemporaryId] INT IDENTITY (1,1),
			[ShippingTargetPeriodId] INT NOT NULL,
			[ProductTypeId] INT NOT NULL,
			[EffectiveFromDateTime] DATETIME NOT NULL,
			[EffectiveToDateTime] DATETIME NULL,
			[LastModifiedDateTime] DATETIME NULL,
			[LastModifiedUserId] INT NULL
		)

		DECLARE @attributes TABLE (
			AttributeId Int,
			AttributeIdColumnName varchar(50),
			Name VARCHAR(50)
		)

		INSERT INTO @attributes(AttributeId, AttributeIdColumnName, Name)
		SELECT g.Grade_Id, 'Attribute_' + convert(varchar(50),g.Grade_Id), g.Grade_Name
		FROM GRADE g
		UNION
		SELECT -1, 'Attribute_Neg1', 'Oversize'
		UNION
		SELECT -2, 'Attribute_Neg2', 'Undersize'

		-- insert shipping targts
		INSERT INTO @shippingTargets ([ShippingTargetPeriodId], [ProductTypeId], [EffectiveFromDateTime], [LastModifiedDateTime], [LastModifiedUserId])
		SELECT tp.ShippingTargetPeriodId, tp.ProductTypeId, tp.EffectiveFromDateTime, tp.LastModifiedDateTime, tp.LastModifiedUserId
		FROM BhpbioShippingTargetPeriod tp
		WHERE (tp.ProductTypeId = @iProductTypeId OR @iProductTypeId IS NULL)
		ORDER BY tp.ProductTypeId, tp.EffectiveFromDateTime
		 
		-- update effective end dates
		UPDATE s1
			SET s1.[EffectiveToDateTime] = DateAdd(millisecond,-100, s2.[EffectiveFromDateTime])
		FROM @shippingTargets s1
			INNER JOIN @shippingTargets s2 ON s2.ProductTypeId = s1.ProductTypeId AND s2.TemporaryId = s1.TemporaryId + 1
		;

		With PivotData AS 
		(
				SELECT st.ShippingTargetPeriodId, 
					pt.ProductTypeId, 
					pt.ProductTypeCode, 
					st.EffectiveFromDateTime, 
					st.EffectiveToDateTime, 
					att.AttributeId,
					att.AttributeIdColumnName,
					'Upper Control' as ValueType, 
					stv.UpperControl as Value
				FROM @shippingTargets st
					INNER JOIN BhpbioProductType pt ON pt.ProductTypeId = st.ProductTypeId
					CROSS JOIN @attributes att
					LEFT JOIN BhpbioShippingTargetPeriodValue stv ON stv.[ShippingTargetPeriodId] = st.ShippingTargetPeriodId AND stv.[AttributeId] = att.AttributeId

				UNION

				SELECT st.ShippingTargetPeriodId, 
					pt.ProductTypeId, 
					pt.ProductTypeCode, 
					st.EffectiveFromDateTime, 
					st.EffectiveToDateTime, 
					att.AttributeId, 
					att.AttributeIdColumnName,
					'Target' as ValueType, 
					stv.[Target] as Value
				FROM @shippingTargets st
					INNER JOIN BhpbioProductType pt ON pt.ProductTypeId = st.ProductTypeId
					CROSS JOIN @attributes att
					LEFT JOIN BhpbioShippingTargetPeriodValue stv ON stv.[ShippingTargetPeriodId] = st.ShippingTargetPeriodId AND stv.[AttributeId] = att.AttributeId

				UNION

				SELECT st.ShippingTargetPeriodId, 
					pt.ProductTypeId, 
					pt.ProductTypeCode, 
					st.EffectiveFromDateTime, 
					st.EffectiveToDateTime, 
					att.AttributeId, 
					att.AttributeIdColumnName,
					'Lower Control' as ValueType, 
					stv.[LowerControl] as Value
				FROM @shippingTargets st
					INNER JOIN BhpbioProductType pt ON pt.ProductTypeId = st.ProductTypeId
					CROSS JOIN @attributes att
					LEFT JOIN BhpbioShippingTargetPeriodValue stv ON stv.[ShippingTargetPeriodId] = st.ShippingTargetPeriodId AND stv.[AttributeId] = att.AttributeId
		)

		SELECT pr.ShippingTargetPeriodId, 
			   pr.ProductTypeId,
			   pr.ProductTypeCode,
			   pr.EffectiveFromDateTime,
			   pr.EffectiveToDateTime,
			   pr.ValueType,
			   Max(Attribute_1) as Attribute_1,
			   Max(Attribute_2) as Attribute_2,
			   Max(Attribute_3) as Attribute_3,
			   Max(Attribute_4) as Attribute_4,
			   Max(Attribute_5) as Attribute_5,
			   Max(Attribute_6) as Attribute_6,
			   Max(Attribute_7) as Attribute_7,
			   Max(Attribute_8) as Attribute_8,
			   Max(Attribute_9) as Attribute_9,
			   Max(Attribute_10) as Attribute_10,
			   Max(Attribute_11) as Attribute_11,
			   Max(Attribute_12) as Attribute_12,
			   Max(Attribute_13) as Attribute_13,
			   Max(Attribute_14) as Attribute_14,
			   Max(Attribute_15) as Attribute_15,
			   Max(Attribute_16) as Attribute_16,
			   Max(Attribute_17) as Attribute_17,
			   Max(Attribute_18) as Attribute_18,
			   Max(Attribute_19) as Attribute_19,
			   Max(Attribute_20) as Attribute_20,
			   Max(Attribute_Neg1) as Attribute_Neg1,
			   Max(Attribute_Neg2) as Attribute_Neg2
		FROM PivotData pd
		PIVOT(SUM(pd.Value) FOR pd.AttributeIdColumnName IN (Attribute_1,Attribute_2,Attribute_3,Attribute_4,Attribute_5,Attribute_6,Attribute_7,Attribute_8,Attribute_9,Attribute_10,Attribute_11,Attribute_12,Attribute_13,Attribute_14,Attribute_15,Attribute_16,Attribute_17,Attribute_18,Attribute_19,Attribute_20,Attribute_Neg1,Attribute_Neg2)) 
			as pr
		WHERE (@iActiveInDateTime IS NULL OR (pr.EffectiveFromDateTime <= @iActiveInDateTime AND (pr.EffectiveToDateTime IS NULL OR pr.EffectiveToDateTime >= @iActiveInDateTime )))
			AND (@iProductTypeId IS NULL OR (pr.ProductTypeId = @iProductTypeId))
		GROUP BY pr.ShippingTargetPeriodId, pr.ProductTypeCode, pr.ProductTypeId, pr.EffectiveFromDateTime, pr.EffectiveToDateTime, pr.ValueType
		ORDER BY pr.EffectiveFromDateTime DESC, pr.ValueType DESC

		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioShippingTargets TO BhpbioGenericManager
GO
