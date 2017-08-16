-- =============================================
-- Author:		John Nickerson
-- Create date: 2013-07-11
-- Description:	
-- =============================================
CREATE PROCEDURE GetShipping 
	@iStartDate Datetime,
	@iEndDate Datetime
AS
BEGIN
	SET NOCOUNT ON;

	-- Shipping Nomination + Items
	Select n.Id, s.NominationKey, s.VesselName, n.ItemNo, n.CustomerNo, n.CustomerName, n.LastAuthorisedDate, n.OfficialFinishTime, n.Oversize, n.Undersize, n.COA, n.ShippedProduct, n.ShippedProductSize
	From dbo.ShippingNominationItem n
	Inner Join dbo.ShippingNomination s
	On s.Id = n.ShippingNominationId
	Where n.LastAuthorisedDate Between @iStartDate And @iEndDate
	
	-- Hub Items
	Select n.Id As ShippingNominationItemId, h.Id, h.Hub, h.HubProduct, h.HubProductSize, h.Tonnes
	From dbo.ShippingNominationItemHub h
	Inner Join dbo.ShippingNominationItem n
	On h.ShippingNominationItemId = n.Id
	Where n.LastAuthorisedDate Between @iStartDate And @iEndDate

	-- Grades
	Select n.Id As ShippingNominationItemId, h.Id As ShippingNominationItemHubId, g.GradeName, g.HeadValue, g.FinesValue, g.LumpValue
	From dbo.ShippingNominationItemHubGrade g
	Inner Join dbo.ShippingNominationItemHub h
		On g.ShippingNominationItemHubId = h.Id
	Inner Join dbo.ShippingNominationItem n
		On h.ShippingNominationItemId = n.Id
	Where n.LastAuthorisedDate Between @iStartDate And @iEndDate

END
GO

GRANT EXECUTE ON dbo.GetShipping TO public
GO