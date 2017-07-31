--
-- this was previously done automatically, but lets try updating the version number automatically
-- to save a deployment step and reduce errors
--

Declare @Major int = 4
Declare @Minor int = 1
Declare @Build int = 0
Declare @Revision int = 0

IF Not Exists (Select 1 
	From [BCDdb2mi].[Version] 
	Where Major = @Major 
		And Minor = @Minor 
		And Build = @Build 
		And Revision = @Revision
	)
Begin
	Update [BCDdb2mi].[Version] Set Active = 0
	exec [BCDdb2mi].[SetVersion] @Major, @Minor, @Build, @Revision
End