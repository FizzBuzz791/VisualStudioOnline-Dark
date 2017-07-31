Imports Bhc = Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace Digblocks
    Public Class DigblockTreeview
        Inherits Core.Website.Digblocks.DigblockTreeview

        Private _dalSecurityLocation As Bhpbio.Database.DalBaseObjects.ISecurityLocation

        Protected Overrides Sub SetupPageControls()
            SetDigblockTreeLocationDefaults()

            MyBase.SetupPageControls()

            'remove the edit/delete columns
            If DigblockTree.Columns.ContainsKey("Edit") Then
                DigblockTree.Columns.Remove("Edit")
            End If

            If DigblockTree.Columns.ContainsKey("Delete") Then
                DigblockTree.Columns.Remove("Delete")
            End If
        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            ReconcilorContent.SideNavigation.TryRemoveItem("DIGBLOCK_ADD")
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If (_dalSecurityLocation Is Nothing) Then
                _dalSecurityLocation = New Bhpbio.Database.SqlDal.SqlDalSecurityLocation(Resources.Connection)
            End If
        End Sub

        ''' <summary>
        ''' Creates Digblock Tree defaults for a specified user.
        ''' The defaults are determined by which Role the user is part of.
        ''' Each role will have a specific location.
        ''' </summary>
        ''' <remarks></remarks>
        Private Sub SetDigblockTreeLocationDefaults()
            Dim userId As Int32
            Dim locationId As Int32
            Dim yandiLocationId As Int32
            Dim yandiLocationTypeId As Int16

            Resources.Connection.BeginTransaction(IsolationLevel.RepeatableRead)

            'check if there are defaults
            If Not _dalSecurityLocation.IsDigblockTreeUserSettingAvailable(Resources.UserSecurity.UserId.Value) Then
                'there were no defaults found - if the user's role has a location assigned then create the defaults
                userId = Resources.UserSecurity.UserId.Value
                locationId = _dalSecurityLocation.GetBhpbioUserLocation(userId)

                If locationId <> Snowden.Common.Database.DataAccessBaseObjects.NullValues.Int32 Then
                    _dalSecurityLocation.SetDigblockTreeUserDefaults(locationId, Resources.UserSecurity.UserId.Value)
                End If

                If locationId = Common.Database.DataAccessBaseObjects.NullValues.Int32 Then
                    'Determine the yandi location id to use as the default if the user has no associated location
                    yandiLocationTypeId = Convert.ToInt16(DalUtility.GetLocationTypeList(Common.Database.DataAccessBaseObjects.NullValues.Int16).Select("Description = 'Hub'")(0)("Location_Type_Id"))

                    yandiLocationId = DalUtility.GetLocationIdByName("NJV", yandiLocationTypeId, 1)
                    _dalSecurityLocation.SetDigblockTreeUserDefaults(yandiLocationId, Resources.UserSecurity.UserId.Value)

                    yandiLocationId = DalUtility.GetLocationIdByName("Yandi", yandiLocationTypeId, 1)
                    _dalSecurityLocation.SetDigblockTreeUserDefaults(yandiLocationId, Resources.UserSecurity.UserId.Value)

                    yandiLocationId = DalUtility.GetLocationIdByName("AreaC", yandiLocationTypeId, 1)
                    _dalSecurityLocation.SetDigblockTreeUserDefaults(yandiLocationId, Resources.UserSecurity.UserId.Value)
                End If

            End If

            Resources.Connection.CommitTransaction()
        End Sub
    End Class
End Namespace