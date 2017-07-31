Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports System.Linq
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI
Imports Snowden.Common.Database.DataHelper

Namespace Utilities
    Public Class ReferenceStockpileGroupStockpileList
        Inherits Core.Website.Utilities.ReferenceStockpileGroupStockpileList

#Region " Properties "
        Private isVisible As Int16
        Private inGroups As Int16
        Private locationId As Int32 = DoNotSetValues.Int32
        Private dalSecurityLocation As Bhpbio.Database.SqlDal.SqlDalSecurityLocation
        Private userFilteringOutsideLocation As Boolean
        Private allowUserToFilterOutsideLocation As Boolean = False
#End Region

        Protected Overrides Sub CreateListTable()
            Dim editPermissions As Boolean
            Dim locationCache As New Generic.Dictionary(Of Int32, Boolean)
            Dim Stockpile_Id As Int32
            Dim Is_Included As Boolean
            Dim stockpileLocation As Int32
            Dim stockpileGroupExists As Boolean

            'Determine if stockpile group exists
            stockpileGroupExists = StockpileGroupId <> "" AndAlso (DalUtility.GetStockpileGroup(StockpileGroupId).Rows.Count > 0)

            ListTable = DalUtility.GetStockpileGroupStockpileList(StockpileGroupId, IsIncluded, DoNotSetValues.Int32, isVisible, locationId, inGroups)

            With ListTable
                .Columns.Add("Include", GetType(String), Nothing)
            End With

            For Each row As DataRow In ListTable.Rows

                stockpileLocation = IfDBNull(row("Stockpile_Location_Id"), NullValues.Int32)

                If stockpileLocation <> NullValues.Int32 Then
                    'Get the status of whether the user is allowed to edit,
                    'cache this value, so that we are not spamming the database.
                    If locationCache.ContainsKey(stockpileLocation) Then
                        editPermissions = locationCache(stockpileLocation)
                    Else
                        editPermissions = dalSecurityLocation.IsBhpbioUserInLocation(Resources.UserSecurity.UserId.Value, stockpileLocation)
                        locationCache.Add(stockpileLocation, editPermissions)
                    End If
                Else
                    editPermissions = True
                End If

                'If filtering against an actual stockpile group and this is not just a new stockpile
                '
                If stockpileGroupExists Then
                    Is_Included = Convert.ToBoolean(row("Is_Included"))
                End If

                Stockpile_Id = Convert.ToInt32(row("Stockpile_Id"))

                If editPermissions Then
                    row("Include") = "<input type=""checkbox"" id=""stockpile_" + Stockpile_Id.ToString + """ name=""stockpile_" + Stockpile_Id.ToString + """ " + IIf(Is_Included, "checked=""checked""", " ").ToString + "/>"
                Else
                    row("Include") = "<input type=""checkbox"" disabled id=""stockpile_" + Stockpile_Id.ToString + """ name=""stockpile_" + Stockpile_Id.ToString + """ " + IIf(Is_Included, "checked=""checked""", " ").ToString + "/>"
                End If
            Next

        End Sub

        Protected Overrides Sub CreateReturnTable()
            If locationId <> NullValues.Int32 Then
                MyBase.CreateReturnTable()
                ReturnTable.Columns("Include").CheckUncheckAllPart = Nothing
            Else
                ReturnTable = New ReconcilorControls.ReconcilorTable(New DataTable())
            End If
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            Dim visibleRadio As String = String.Empty
            Dim groupsRadio As String = String.Empty
            Dim location As Int32

            visibleRadio = RequestAsString("visibilityradio")
            groupsRadio = RequestAsString("groupradio")
            location = RequestAsInt32("locationid")
            StockpileGroupId = RequestAsString("StockpileGroupId")

            IsIncluded = 0

            Select Case visibleRadio
                Case "visible"
                    isVisible = 1
                Case "notvisible"
                    isVisible = 0
                Case "all"
                    isVisible = NullValues.Int16
                Case Else
                    isVisible = NullValues.Int16
            End Select

            Select Case groupsRadio
                Case "ingroup"
                    inGroups = 1
                    IsIncluded = NullValues.Int16
                Case "notingroup"
                    inGroups = 0
                Case "thisgroup"
                    IsIncluded = 1
                    inGroups = NullValues.Int16
                Case "notinthisgroup"
                    IsIncluded = 0
                    inGroups = NullValues.Int16
                Case "all"
                    IsIncluded = NullValues.Int16
                    inGroups = NullValues.Int16
                Case Else
                    inGroups = NullValues.Int16
            End Select

            'Use the current one, i.e in case the user starts typing in the text box to change it
            'and then wants to filter.
            StockpileGroupId = RequestAsString("LastStockpileGroupId")
            If StockpileGroupId Is Nothing Then
                StockpileGroupId = ""
            End If

            If location <= 0 Then
                locationId = NullValues.Int32
            Else
                locationId = location
            End If

            Resources.UserSecurity.SetSetting("STOCKPILEGROUP_GROUPING_FILTER", groupsRadio)
            Resources.UserSecurity.SetSetting("STOCKPILEGROUP_VISIBLE_FILTER", visibleRadio)
            Resources.UserSecurity.SetSetting("STOCKPILEGROUP_LOCATION_FILTER", location.ToString)

            'If the user tries to filter all sites throw up an alert.
            If locationId = NullValues.Int32 OrElse _
                dalSecurityLocation.IsBhpbioUserInLocation(Resources.UserSecurity.UserId.Value, locationId) = False Then
                userFilteringOutsideLocation = True
            End If

        End Sub


        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()
            If dalSecurityLocation Is Nothing Then
                dalSecurityLocation = New Bhpbio.Database.SqlDal.SqlDalSecurityLocation(Resources.ConnectionString)
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            'if location is not selected, then don't create the list
            If locationId <> NullValues.Int32 Then
                CreateListTable()
                CreateReturnTable()
                Controls.Add(ReturnTable)
                ReturnTable.Width = 700
                ReturnTable.Columns("Other_Group_List").Width = 500
                ReturnTable.Columns("Stockpile_Name").Width = 150
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "document.getElementById('SubmitEdit').style.display = 'block';"))
            End If
        End Sub

    End Class
End Namespace
