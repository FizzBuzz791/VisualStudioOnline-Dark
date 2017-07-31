Declare @H2OGradeId Int

Select @H2OGradeId = Grade_Id
From dbo.Grade
Where Grade_Name = 'H2O'

Select 'The following Nomination Item records do not have the corresponding Nomination Item Parcel records. Their H2O values will be deleted. They have duplicates based on the following fields:' As WARNING

Select i.NominationKey, i.ItemNo, i.OfficialFinishTime
From dbo.BhpbioShippingNominationItem i
	Left Outer Join dbo.BhpbioShippingNominationItemParcel p
		On i.BhpbioShippingNominationItemId = p.BhpbioShippingNominationItemId
Where i.H2O Is Not Null And p.BhpbioShippingNominationItemParcelId Is Null
Order By i.OfficialFinishTime

Begin Transaction

-- First, migrate existing H2O values
Insert Into dbo.BhpbioShippingNominationItemParcelGrade
(
	BhpbioShippingNominationItemParcelId, GradeId, GradeValue
)
Select p.BhpbioShippingNominationItemParcelId, @H2OGradeId, i.H2O
From dbo.BhpbioShippingNominationItem i
	Inner Join dbo.BhpbioShippingNominationItemParcel p
		On i.BhpbioShippingNominationItemId = p.BhpbioShippingNominationItemId
Where i.H2O Is Not Null

-- Second, delete the column
Alter Table dbo.BhpbioShippingNominationItem
Drop Column H2O

Commit Transaction
