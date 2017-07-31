IF Object_ID('ConvertMQ2ToLocationId') IS NOT NULL
     DROP FUNCTION [ConvertMQ2ToLocationId]
GO

CREATE FUNCTION [dbo].[ConvertMQ2ToLocationId] (@MQ2Code NVARCHAR(MAX))
RETURNS INT
AS
BEGIN
  -- MQ2 Codes translate to Sites (usually), so enforce Location_Type_Id = 3.
  RETURN CASE @MQ2Code
    WHEN '18' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'OB18' AND Location_Type_Id = 3)
    WHEN '25' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'Eastern Ridge' AND Location_Type_Id = 3)
    WHEN 'AC' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'AreaC' AND Location_Type_Id = 3)
    WHEN 'JB' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'Jimblebar' AND Location_Type_Id = 3)
    WHEN 'NH' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'NJV' AND Location_Type_Id = 2)
    WHEN 'WB' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'Newman' AND Location_Type_Id = 3)
    WHEN 'YD' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'Yandi' AND Location_Type_Id = 3)
    WHEN 'YR' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'Yarrie' AND Location_Type_Id = 3)
    ELSE
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = @MQ2Code AND Location_Type_Id = 3)
  END
END