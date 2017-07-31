--USE [ReconcilorImportMockWS]
--GO

--IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InsertBlock]') AND type in (N'P', N'PC'))
--DROP PROCEDURE [dbo].[InsertBlock]
--GO

CREATE PROCEDURE [dbo].[InsertBlock]
	@BlastedDate Datetime, 
	@BlockedDate Datetime,
	@GeoType Nvarchar(50),
	@LastModifiedDate Datetime,
	@LastModifiedUser Nvarchar(50),
	@Mq2PitCode Nvarchar(50),
	@Name Nvarchar(50),
	@Number Nvarchar(50),
	@IsDelete Bit = 0,
	@PatternSite Nvarchar(50),
	@PatternOrebody Nvarchar(50),
	@PatternPit Nvarchar(50),
	@PatternBench Nvarchar(50),
	@PatternNumber Nvarchar(50),
	@CentroidEasting Real,
	@CentroidNorthing Real,
	@CentroidRL Real,
	@oBlockId Int Output,
	@oPolygonId Int Output
As
Begin

	Declare @patternId Int,
			@polygonId Int

	Set Transaction Isolation Level Repeatable Read
	Begin Transaction

		Insert Into dbo.Patterns
		(
			[Bench]
			,[Number]
			,[Orebody]
			,[Pit]
			,[Site]
		)
		Select @PatternBench, @PatternNumber, @PatternOrebody, @PatternPit, @PatternSite

		Set @patternId = SCOPE_IDENTITY()

		Insert Into dbo.Polygons
		(
			[CentroidEasting]
			,[CentroidNorthing]
			,[CentroidRL]
		)
		Select @CentroidEasting, @CentroidNorthing, @CentroidRL

		Set @polygonId = SCOPE_IDENTITY()

		Insert Into dbo.Blocks
		(
			[BlastedDate]
		  ,[BlockedDate]
		  ,[GeoType]
		  ,[LastModifiedDate]
		  ,[LastModifiedUser]
		  ,[MQ2PitCode]
		  ,[Name]
		  ,[Number]
		  ,[PatternId]
		  ,[PolygonId]
		  ,[IsDelete]
		)
		Select @BlastedDate, 
		@BlockedDate,
		@GeoType,
		@LastModifiedDate,
		@LastModifiedUser,
		@Mq2PitCode,
		@Name,
		@Number,
		@patternId,
		@polygonId,
		@IsDelete

		Set @oBlockId = SCOPE_IDENTITY()

	Commit Transaction

	Set @oPolygonId = @polygonId

End
Go