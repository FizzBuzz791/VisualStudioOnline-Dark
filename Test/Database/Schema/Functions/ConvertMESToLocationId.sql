IF Object_ID('ConvertMESToLocationId') IS NOT NULL
     DROP FUNCTION [ConvertMESToLocationId]
GO

CREATE FUNCTION [dbo].[ConvertMESToLocationId] (@MESCode NVARCHAR(3))
RETURNS INT
AS
BEGIN
  -- MES Codes translate to Hubs, so enforce Location_Type_Id = 2.
  RETURN CASE @MESCode
    WHEN 'MAC' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'AreaC' AND Location_Type_Id = 2)
    WHEN 'YND' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'Yandi' AND Location_Type_Id = 2)
    WHEN 'NHG' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'NJV' AND Location_Type_Id = 2)
    WHEN 'YR' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'Yarrie' AND Location_Type_Id = 2)
    WHEN 'GWY' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'Yarrie' AND Location_Type_Id = 2)
    WHEN 'JMB' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'Jimblebar' AND Location_Type_Id = 2)
    WHEN 'JIM' THEN
      (SELECT TOP 1 Location_Id FROM Location WHERE Name = 'Jingbao' AND Location_Type_Id = 2)
    ELSE
      ''
  END
END