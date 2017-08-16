CREATE PROCEDURE [dbo].[InsertModel]
	@BlockId Int,
	@Name Nvarchar(50),
	@Filename Nvarchar(200),
	@OreType Nvarchar(50),
	@Volume Real,
	@Tonnes Real,
	@Density Real,
	@LastModifiedDate Datetime = Null,
	@LastModifiedUser Nvarchar(50),
	@FeGradeValue Decimal(12, 6),
	@PGradeValue Decimal(12, 6),
	@SiO2GradeValue Decimal(12, 6),
	@Al2O3GradeValue Decimal(12, 6),
	@LoiGradeValue Decimal(12, 6)
As
Begin

	Set NoCount On

	Set Transaction Isolation Level Repeatable Read
	Begin Transaction

		Declare @modelId Int,
				@gradeId Int

		Insert Into dbo.Models
		(
			[BlockId]
			,[Density]
			,[Filename]
			,[LastModifiedDate]
			,[LastModifiedUser]
			,[LumpPercent]
			,[Name]
			,[OreType]
			,[Tonnes]
			,[Volume]
		)
		Select @BlockId, @Density, @Filename, @LastModifiedDate, @LastModifiedUser, Null, @Name, @OreType, @Tonnes, @Volume

		Set @modelId = SCOPE_IDENTITY()

		Insert Into dbo.Grades
		(
			[Name]
			,[HeadValue]
		)
		Select 'FE', @FeGradeValue

		Set @gradeId = SCOPE_IDENTITY()

		Insert Into dbo.ModelGrades
		(
			[GradeId], [ModelId]
		)
		Select @gradeId, @modelId

		Insert Into dbo.Grades
		(
			[Name]
			,[HeadValue]
		)
		Select 'P', @PGradeValue

		Set @gradeId = SCOPE_IDENTITY()

		Insert Into dbo.ModelGrades
		(
			[GradeId], [ModelId]
		)
		Select @gradeId, @modelId

		Insert Into dbo.Grades
		(
			[Name]
			,[HeadValue]
		)
		Select 'SIO2', @SiO2GradeValue

		Set @gradeId = SCOPE_IDENTITY()

		Insert Into dbo.ModelGrades
		(
			[GradeId], [ModelId]
		)
		Select @gradeId, @modelId

		Insert Into dbo.Grades
		(
			[Name]
			,[HeadValue]
		)
		Select 'AL2O3', @Al2O3GradeValue

		Set @gradeId = SCOPE_IDENTITY()

		Insert Into dbo.ModelGrades
		(
			[GradeId], [ModelId]
		)
		Select @gradeId, @modelId

		Insert Into dbo.Grades
		(
			[Name]
			,[HeadValue]
		)
		Select 'LOI', @LoiGradeValue

		Set @gradeId = SCOPE_IDENTITY()

		Insert Into dbo.ModelGrades
		(
			[GradeId], [ModelId]
		)
		Select @gradeId, @modelId

	Commit Transaction

End
Go

GRANT EXECUTE ON dbo.InsertModel TO public
GO