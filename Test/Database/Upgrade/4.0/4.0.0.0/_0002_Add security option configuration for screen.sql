

IF NOT EXISTS (SELECT * FROM [dbo].[SecurityOption] so WHERE so.Application_Id='REC' AND so.Option_Id='UTILITIES_DEPOSITS')
BEGIN
	INSERT INTO [dbo].[SecurityOption]  VALUES
	(
	'REC',
	'UTILITIES_DEPOSITS',
	'Utilities',
	'Access to Deposit Management',
	99
	)
END
GO