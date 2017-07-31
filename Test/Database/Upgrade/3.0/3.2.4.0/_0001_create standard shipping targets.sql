
-- clear all the existing shipping targets
Delete From BhpbioShippingTargetPeriodValue
Delete From BhpbioShippingTargetPeriod

-- insert the actual shipping targets
Declare @oShippingTargetPeriodId INT 
 IF NOT EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ProductTypeId = ((select producttypeid from BhpbioProductType where ProductTypeCode = 'YNDF')) AND EffectiveFromDateTime = convert(datetime, '01/07/2014', 103)) 
 BEGIN 

  INSERT INTO dbo.BhpbioShippingTargetPeriod(ProductTypeId, EffectiveFromDateTime, LastModifiedUserId, LastModifiedDateTime) 
     VALUES (((select producttypeid from BhpbioProductType where ProductTypeCode = 'YNDF')), convert(datetime, '01/07/2014', 103), 740, GetDate() ) 
     SET @oShippingTargetPeriodId = SCOPE_IDENTITY() 
 END 

 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 58.05, [Target] = 57.3, LowerControl = 56.55
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 1 , 58.05, 57.3, 56.55) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0.051, [Target] = 0.042, LowerControl = 0.033
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 2 , 0.051, 0.042, 0.033) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =3) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 6.2, [Target] = 5.9, LowerControl = 5.3
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 3 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 3 , 6.2, 5.9, 5.3) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =4) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 1.8, [Target] = 1.5, LowerControl = 1.2
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 4 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 4 , 1.8, 1.5, 1.2) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =5) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0, [Target] = 10.3, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 5 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 5 , 0, 10.3, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =7) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 10.5, [Target] = 9.5, LowerControl = 8.5
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 7 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 7 , 10.5, 9.5, 8.5) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 15, [Target] = 12, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -1 , 15, 12, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 10, [Target] = 8, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -2 , 10, 8, 0) END 
 END  SET @oShippingTargetPeriodId = NULL  IF NOT EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ProductTypeId = ((select producttypeid from BhpbioProductType where ProductTypeCode = 'JMBF')) AND EffectiveFromDateTime = convert(datetime, '01/07/2014', 103)) 
 BEGIN 

  INSERT INTO dbo.BhpbioShippingTargetPeriod(ProductTypeId, EffectiveFromDateTime, LastModifiedUserId, LastModifiedDateTime) 
     VALUES (((select producttypeid from BhpbioProductType where ProductTypeCode = 'JMBF')), convert(datetime, '01/07/2014', 103), 740, GetDate() ) 
     SET @oShippingTargetPeriodId = SCOPE_IDENTITY() 
 END 

 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 62.8, [Target] = 61.3, LowerControl = 60
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 1 , 62.8, 61.3, 60) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 1.136, [Target] = 0.115, LowerControl = 0.094
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 2 , 1.136, 0.115, 0.094) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =3) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 6, [Target] = 4.8, LowerControl = 3.6
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 3 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 3 , 6, 4.8, 3.6) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =4) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 3.1, [Target] = 2.65, LowerControl = 2.2
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 4 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 4 , 3.1, 2.65, 2.2) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =5) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0, [Target] = 4.5, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 5 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 5 , 0, 4.5, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =7) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 7.5, [Target] = 6.5, LowerControl = 5.5
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 7 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 7 , 7.5, 6.5, 5.5) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 15, [Target] = 12, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -1 , 15, 12, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 28, [Target] = 26, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -2 , 28, 26, 0) END 
 END  SET @oShippingTargetPeriodId = NULL  IF NOT EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ProductTypeId = ((select producttypeid from BhpbioProductType where ProductTypeCode = 'MACF')) AND EffectiveFromDateTime = convert(datetime, '01/07/2014', 103)) 
 BEGIN 

  INSERT INTO dbo.BhpbioShippingTargetPeriod(ProductTypeId, EffectiveFromDateTime, LastModifiedUserId, LastModifiedDateTime) 
     VALUES (((select producttypeid from BhpbioProductType where ProductTypeCode = 'MACF')), convert(datetime, '01/07/2014', 103), 740, GetDate() ) 
     SET @oShippingTargetPeriodId = SCOPE_IDENTITY() 
 END 

 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 61.85, [Target] = 60.8, LowerControl = 60
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 1 , 61.85, 60.8, 60) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0.1, [Target] = 0.085, LowerControl = 0.07
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 2 , 0.1, 0.085, 0.07) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =3) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 5.15, [Target] = 4.4, LowerControl = 3.65
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 3 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 3 , 5.15, 4.4, 3.65) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =4) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 2.6, [Target] = 2.3, LowerControl = 2
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 4 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 4 , 2.6, 2.3, 2) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =5) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0, [Target] = 6, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 5 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 5 , 0, 6, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =7) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 8.8, [Target] = 7.8, LowerControl = 6.8
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 7 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 7 , 8.8, 7.8, 6.8) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 15, [Target] = 12, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -1 , 15, 12, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 28, [Target] = 26, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -2 , 28, 26, 0) END 
 END  SET @oShippingTargetPeriodId = NULL  IF NOT EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ProductTypeId = ((select producttypeid from BhpbioProductType where ProductTypeCode = 'NHGF')) AND EffectiveFromDateTime = convert(datetime, '01/07/2014', 103)) 
 BEGIN 

  INSERT INTO dbo.BhpbioShippingTargetPeriod(ProductTypeId, EffectiveFromDateTime, LastModifiedUserId, LastModifiedDateTime) 
     VALUES (((select producttypeid from BhpbioProductType where ProductTypeCode = 'NHGF')), convert(datetime, '01/07/2014', 103), 740, GetDate() ) 
     SET @oShippingTargetPeriodId = SCOPE_IDENTITY() 
 END 

 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 63.55, [Target] = 62.5, LowerControl = 61.45
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 1 , 63.55, 62.5, 61.45) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0.095, [Target] = 0.08, LowerControl = 0.065
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 2 , 0.095, 0.08, 0.065) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =3) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 5.15, [Target] = 4.4, LowerControl = 3.65
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 3 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 3 , 5.15, 4.4, 3.65) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =4) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 2.5, [Target] = 2.2, LowerControl = 1.9
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 4 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 4 , 2.5, 2.2, 1.9) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =5) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0, [Target] = 3.1, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 5 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 5 , 0, 3.1, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =7) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 8.1, [Target] = 7, LowerControl = 6.1
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 7 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 7 , 8.1, 7, 6.1) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 15, [Target] = 12, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -1 , 15, 12, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 28, [Target] = 25, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -2 , 28, 25, 0) END 
 END  SET @oShippingTargetPeriodId = NULL  IF NOT EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ProductTypeId = ((select producttypeid from BhpbioProductType where ProductTypeCode = 'NBLL')) AND EffectiveFromDateTime = convert(datetime, '01/07/2014', 103)) 
 BEGIN 

  INSERT INTO dbo.BhpbioShippingTargetPeriod(ProductTypeId, EffectiveFromDateTime, LastModifiedUserId, LastModifiedDateTime) 
     VALUES (((select producttypeid from BhpbioProductType where ProductTypeCode = 'NBLL')), convert(datetime, '01/07/2014', 103), 740, GetDate() ) 
     SET @oShippingTargetPeriodId = SCOPE_IDENTITY() 
 END 

 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 64.55, [Target] = 63.5, LowerControl = 62.45
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 1 , 64.55, 63.5, 62.45) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0.09, [Target] = 0.075, LowerControl = 0.06
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 2 , 0.09, 0.075, 0.06) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =3) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 4.35, [Target] = 3.6, LowerControl = 2.85
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 3 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 3 , 4.35, 3.6, 2.85) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =4) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 1.7, [Target] = 1.4, LowerControl = 1.1
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 4 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 4 , 1.7, 1.4, 1.1) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =5) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0, [Target] = 4.4, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 5 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 5 , 0, 4.4, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =7) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 5, [Target] = 4, LowerControl = 3
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 7 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 7 , 5, 4, 3) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 16, [Target] = 12, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -1 , 16, 12, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 7, [Target] = 5, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -2 , 7, 5, 0) END 
 END  SET @oShippingTargetPeriodId = NULL  IF NOT EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ProductTypeId = ((select producttypeid from BhpbioProductType where ProductTypeCode = 'YNDF')) AND EffectiveFromDateTime = convert(datetime, '01/07/2015', 103)) 
 BEGIN 

  INSERT INTO dbo.BhpbioShippingTargetPeriod(ProductTypeId, EffectiveFromDateTime, LastModifiedUserId, LastModifiedDateTime) 
     VALUES (((select producttypeid from BhpbioProductType where ProductTypeCode = 'YNDF')), convert(datetime, '01/07/2015', 103), 740, GetDate() ) 
     SET @oShippingTargetPeriodId = SCOPE_IDENTITY() 
 END 

 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 58.05, [Target] = 57.3, LowerControl = 56.55
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 1 , 58.05, 57.3, 56.55) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0.05, [Target] = 0.043, LowerControl = 0.034
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 2 , 0.05, 0.043, 0.034) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =3) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 6.2, [Target] = 5.9, LowerControl = 5.3
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 3 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 3 , 6.2, 5.9, 5.3) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =4) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 1.8, [Target] = 1.5, LowerControl = 1.2
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 4 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 4 , 1.8, 1.5, 1.2) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =5) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0, [Target] = 10.3, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 5 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 5 , 0, 10.3, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =7) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 10.5, [Target] = 9.5, LowerControl = 8.5
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 7 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 7 , 10.5, 9.5, 8.5) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 15, [Target] = 12, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -1 , 15, 12, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 10, [Target] = 8, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -2 , 10, 8, 0) END 
 END  SET @oShippingTargetPeriodId = NULL  IF NOT EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ProductTypeId = ((select producttypeid from BhpbioProductType where ProductTypeCode = 'JMBF')) AND EffectiveFromDateTime = convert(datetime, '01/07/2015', 103)) 
 BEGIN 

  INSERT INTO dbo.BhpbioShippingTargetPeriod(ProductTypeId, EffectiveFromDateTime, LastModifiedUserId, LastModifiedDateTime) 
     VALUES (((select producttypeid from BhpbioProductType where ProductTypeCode = 'JMBF')), convert(datetime, '01/07/2015', 103), 740, GetDate() ) 
     SET @oShippingTargetPeriodId = SCOPE_IDENTITY() 
 END 

 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 62.6, [Target] = 61.25, LowerControl = 60
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 1 , 62.6, 61.25, 60) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0.131, [Target] = 0.11, LowerControl = 0.089
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 2 , 0.131, 0.11, 0.089) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =3) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 5.9, [Target] = 4.9, LowerControl = 3.8
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 3 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 3 , 5.9, 4.9, 3.8) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =4) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 3.15, [Target] = 2.7, LowerControl = 2.25
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 4 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 4 , 3.15, 2.7, 2.25) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =5) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0, [Target] = 4.4, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 5 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 5 , 0, 4.4, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =7) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 8.1, [Target] = 7.1, LowerControl = 6.1
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 7 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 7 , 8.1, 7.1, 6.1) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 15, [Target] = 12, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -1 , 15, 12, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 28, [Target] = 26, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -2 , 28, 26, 0) END 
 END  SET @oShippingTargetPeriodId = NULL  IF NOT EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ProductTypeId = ((select producttypeid from BhpbioProductType where ProductTypeCode = 'MACF')) AND EffectiveFromDateTime = convert(datetime, '01/07/2015', 103)) 
 BEGIN 

  INSERT INTO dbo.BhpbioShippingTargetPeriod(ProductTypeId, EffectiveFromDateTime, LastModifiedUserId, LastModifiedDateTime) 
     VALUES (((select producttypeid from BhpbioProductType where ProductTypeCode = 'MACF')), convert(datetime, '01/07/2015', 103), 740, GetDate() ) 
     SET @oShippingTargetPeriodId = SCOPE_IDENTITY() 
 END 

 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 61.85, [Target] = 60.8, LowerControl = 60
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 1 , 61.85, 60.8, 60) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0.1, [Target] = 0.085, LowerControl = 0.07
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 2 , 0.1, 0.085, 0.07) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =3) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 5.25, [Target] = 4.5, LowerControl = 3.75
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 3 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 3 , 5.25, 4.5, 3.75) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =4) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 2.7, [Target] = 2.4, LowerControl = 2.1
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 4 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 4 , 2.7, 2.4, 2.1) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =5) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0, [Target] = 6, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 5 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 5 , 0, 6, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =7) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 9, [Target] = 8, LowerControl = 7
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 7 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 7 , 9, 8, 7) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 15, [Target] = 12, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -1 , 15, 12, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 28, [Target] = 26, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -2 , 28, 26, 0) END 
 END  SET @oShippingTargetPeriodId = NULL  IF NOT EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ProductTypeId = ((select producttypeid from BhpbioProductType where ProductTypeCode = 'NHGF')) AND EffectiveFromDateTime = convert(datetime, '01/07/2015', 103)) 
 BEGIN 

  INSERT INTO dbo.BhpbioShippingTargetPeriod(ProductTypeId, EffectiveFromDateTime, LastModifiedUserId, LastModifiedDateTime) 
     VALUES (((select producttypeid from BhpbioProductType where ProductTypeCode = 'NHGF')), convert(datetime, '01/07/2015', 103), 740, GetDate() ) 
     SET @oShippingTargetPeriodId = SCOPE_IDENTITY() 
 END 

 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 63.75, [Target] = 62.7, LowerControl = 61.65
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 1 , 63.75, 62.7, 61.65) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0.101, [Target] = 0.08, LowerControl = 0.059
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 2 , 0.101, 0.08, 0.059) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =3) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 5.15, [Target] = 4.4, LowerControl = 3.65
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 3 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 3 , 5.15, 4.4, 3.65) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =4) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 2.5, [Target] = 2.2, LowerControl = 1.9
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 4 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 4 , 2.5, 2.2, 1.9) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =5) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0, [Target] = 3.1, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 5 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 5 , 0, 3.1, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =7) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 8, [Target] = 7, LowerControl = 6
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 7 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 7 , 8, 7, 6) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 15, [Target] = 12, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -1 , 15, 12, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 28, [Target] = 25, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -2 , 28, 25, 0) END 
 END  SET @oShippingTargetPeriodId = NULL  IF NOT EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ProductTypeId = ((select producttypeid from BhpbioProductType where ProductTypeCode = 'NBLL')) AND EffectiveFromDateTime = convert(datetime, '01/07/2015', 103)) 
 BEGIN 

  INSERT INTO dbo.BhpbioShippingTargetPeriod(ProductTypeId, EffectiveFromDateTime, LastModifiedUserId, LastModifiedDateTime) 
     VALUES (((select producttypeid from BhpbioProductType where ProductTypeCode = 'NBLL')), convert(datetime, '01/07/2015', 103), 740, GetDate() ) 
     SET @oShippingTargetPeriodId = SCOPE_IDENTITY() 
 END 

 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 64.05, [Target] = 63, LowerControl = 61.95
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 1 , 64.05, 63, 61.95) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0.095, [Target] = 0.08, LowerControl = 0.065
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 2 , 0.095, 0.08, 0.065) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =3) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 4.25, [Target] = 3.5, LowerControl = 2.75
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 3 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 3 , 4.25, 3.5, 2.75) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =4) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 1.65, [Target] = 1.35, LowerControl = 1.05
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 4 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 4 , 1.65, 1.35, 1.05) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =5) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 0, [Target] = 4.4, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 5 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 5 , 0, 4.4, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =7) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 5, [Target] = 4, LowerControl = 3
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = 7 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, 7 , 5, 4, 3) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-1) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 25, [Target] = 20, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -1 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -1 , 25, 20, 0) END 
 END 
 IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @OShippingTargetPeriodId) 
 BEGIN 
    IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId =-2) 
 BEGIN 
     UPDATE BhpbioShippingTargetPeriodValue
     SET UpperControl = 7, [Target] = 5, LowerControl = 0
     WHERE ShippingTargetPeriodId = @oShippingTargetPeriodId AND AttributeId = -2 
 END 
 ELSE 
 BEGIN 
    INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl) 
     VALUES (@oShippingTargetPeriodId, -2 , 7, 5, 0) END 
 END  SET @oShippingTargetPeriodId = NULL 