IF OBJECT_ID('Staging.LogMessage') IS NOT NULL
     DROP PROCEDURE Staging.LogMessage
GO 
  
CREATE PROCEDURE Staging.LogMessage
(
	@iReceivedDateTime DATETIME,
	@iMessageTimestamp DATETIME,
	@iMessageBody NTEXT,
	@iMessageType NVARCHAR(50),
	@iDataKey NVARCHAR(50)
)
WITH ENCRYPTION
AS
BEGIN 
	INSERT INTO Staging.MessageLog(MessageReceivedDateTime, MessageTimestamp, [Message], MessageType, DataKey)
		VALUES (@iReceivedDateTime, @iMessageTimestamp, @iMessageBody, @iMessageType, @iDataKey)
END 
GO

GRANT EXECUTE ON Staging.LogMessage TO BhpbioGenericManager
GO
