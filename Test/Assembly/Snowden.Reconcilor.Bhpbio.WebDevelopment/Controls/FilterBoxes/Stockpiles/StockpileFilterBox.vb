Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Xml
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Common.Web.BaseHtmlControls.WebpageControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports IStockpile = Snowden.Reconcilor.Core.Database.DalBaseObjects.IStockpile

Namespace ReconcilorControls.FilterBoxes.Stockpiles
    Public Class StockpileFilterBox
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.Stockpiles.StockpileFilterBox

        Private _stockpileType As New SelectBox
        Private ReadOnly _stockpileTerminologyPlural As String = ReconcilorFunctions.GetSiteTerminologyPlural("Stockpile")
        Private ReadOnly _stockpileGroupCheckBoxDictionary As New Dictionary(Of Int32, InputCheckBox)
        Private _includeLocationsBelow As New InputCheckBox

        Public Property IncludeLocationsBelow As InputCheckBox
            Get
                Return _includeLocationsBelow
            End Get
            Set
                If (Not value Is Nothing) Then
                    _includeLocationsBelow = value
                End If
            End Set
        End Property

        Public Property StockpileType As SelectBox
            Get
                Return _stockpileType
            End Get
            Set
                If (Not value Is Nothing) Then
                    _stockpileType = value
                End If
            End Set
        End Property

        Public Property DalStockpile As IStockpile

        Protected Overrides Sub SetupControls()
            MyBase.SetupControls()

            Dim foundItem As ListItem
            Dim includeLocations As Boolean

            'set up the DALs (share the connection only)
            Dim bhpDalUtility = New SqlDalUtility(DalUtility.DataAccess.DataAccessConnection)
            Dim dalSecurityLocation As ISecurityLocation = New SqlDalSecurityLocation(DalUtility.DataAccess.DataAccessConnection)

            'Override to accomodate for reset filter button
            With LayoutGroupBox
                .Width = 730
                .Title = "Filter " & _StockpileTerminologyPlural
            End With

            With IncludeLocationsBelow
                .ID = "IncludeLocationsBelow"
                If .Enabled Then
                    If Boolean.TryParse(Resources.UserSecurity.GetSetting("Stockpile_Filter_Include_Locations_Below", "True").ToLower, includeLocations) Then
                        .Checked = includeLocations
                    Else
                        .Checked = True
                    End If
                End If
            End With

            'Override the material type filter box
            With MaterialTypeId
                .ID = "MaterialTypeId"

                .DataSource = bhpDalUtility.GetBhpMaterialTypeList(DoNotSetValues.Int16, Convert.ToInt16(True), DoNotSetValues.Int32, DoNotSetValues.String, DoNotSetValues.Int32)
                .DataTextField = "Abbreviation"
                .DataValueField = "Material_Type_ID"
                .DataBind()

                .Items.Insert(0, New ListItem("All " & ReconcilorFunctions.GetSiteTerminologyPlural("Material Type"), ""))

                foundItem = .Items.FindByValue(Resources.UserSecurity.GetSetting("Stockpile_Filter_Material_Type_ID", ""))
                If (Not foundItem Is Nothing) Then
                    foundItem.Selected = True
                End If
            End With

            With StateType
                .ID = "StateType"
                .Items.Clear()

                .Items.Add(New ListItem("All " & _StockpileTerminologyPlural, ""))
                .Items.Add(New ListItem("Active " & _StockpileTerminologyPlural, "1"))
                .Items.Add(New ListItem("Inactive " & _StockpileTerminologyPlural, "0"))

                foundItem = .Items.FindByValue(Resources.UserSecurity.GetSetting("Stockpile_Filter_State_Type", "1"))
                If (Not foundItem Is Nothing) Then
                    foundItem.Selected = True
                Else
                    .Items.FindByValue("1").Selected = True
                End If
            End With

            'Need to toggle "stockpile groups" if group stockpiles is visible then show groups
            GroupStockpiles.Attributes.Add("onClick", "SetStockpileGroupsDisplay();")

            'set the new default on the location filter
            'if no location is specified set the default based on the user's location
            If Not LocationFilter.LocationId.HasValue Then
                LocationFilter.LocationId = dalSecurityLocation.GetBhpbioUserLocation(Resources.UserSecurity.UserId.Value)
            End If
        End Sub

        Protected Overrides Sub SetupFormAndDatePickers()
            MyBase.SetupFormAndDatePickers()

            ServerForm.OnSubmit = "return ValidateFilterParameters();"

            DatePickers.Add("TransactionStartDate",
                            New DatePicker("TransactionStartDate", ServerForm.ID,
                                           Convert.ToDateTime(Resources.UserSecurity.GetSetting("Stockpile_Filter_Transaction_Start_Date",
                                                                                                DatePicker.NoDate.ToString))))
            DatePickers.Add("TransactionEndDate",
                            New DatePicker("TransactionEndDate", ServerForm.ID,
                                           Convert.ToDateTime(Resources.UserSecurity.GetSetting("Stockpile_Filter_Transaction_End_Date",
                                                                                                DatePicker.NoDate.ToString))))

            DatePickers("TransactionStartDate").Required = FromRequired
            DatePickers("TransactionStartDate").ShowAlerts = ShowAlerts
            DatePickers("TransactionEndDate").Required = FromRequired
            DatePickers("TransactionEndDate").ShowAlerts = ShowAlerts
        End Sub

        Protected Overridable Sub SetupStockpileGroupControls()
            Dim stockpileGroups As DataTable = DalUtility.GetStockpileGroupList(0, 0)
            Dim stockpileGroupCheckBox As InputCheckBox
            Dim nodesSelected As XmlNodeList = GetStockpileGroupUserSettings()

            For Each dr As DataRow In stockpileGroups.Rows
                Dim stockpileGroupId As String = dr("Stockpile_Group_ID").ToString()

                stockpileGroupCheckBox = New InputCheckBox
                stockpileGroupCheckBox.ID = "CheckBox" + stockpileGroupId.Trim().Replace(" ", "")
                stockpileGroupCheckBox.Text = stockpileGroupId

                If (Not nodesSelected Is Nothing) Then
                    For Each groupNode As XmlNode In nodesSelected
                        If (groupNode.InnerText = stockpileGroupCheckBox.Text) Then
                            stockpileGroupCheckBox.Checked = True
                        End If
                    Next
                Else
                    stockpileGroupCheckBox.Checked = True
                End If

                _stockpileGroupCheckBoxDictionary.Add(stockpileGroups.Rows.IndexOf(dr), stockpileGroupCheckBox)
            Next

            stockpileGroupCheckBox = New InputCheckBox
            stockpileGroupCheckBox.ID = "CheckBoxStockpilesNOTGrouped"

            If Not (nodesSelected Is Nothing) Then
                For Each groupNode As XmlNode In nodesSelected
                    If (groupNode.InnerText = "Stockpiles NOT Grouped") Then
                        stockpileGroupCheckBox.Checked = True
                    End If
                Next
            Else
                stockpileGroupCheckBox.Checked = True

            End If

            stockpileGroupCheckBox.Text = "Stockpiles NOT Grouped"
            _stockpileGroupCheckBoxDictionary.Add(_stockpileGroupCheckBoxDictionary.Keys.Count, stockpileGroupCheckBox)
        End Sub

        Protected Overridable Function CreateCheckBoxLinks() As HtmlTableTag
            Dim checkTable As New HtmlTableTag
            Dim checkAll As New HyperLink
            Dim uncheckAll As New HyperLink

            checkAll.Text = "[Check All]"
            checkAll.NavigateUrl = "javascript:CheckAllGroups();"

            uncheckAll.Text = "[Un-check All]"
            uncheckAll.NavigateUrl = "javascript:UncheckAllGroups();"

            With checkTable
                .CellPadding = 2
                .AddCellInNewRow.Controls.Add(checkAll)
                .AddCell.Controls.Add(uncheckAll)
            End With

            Return checkTable
        End Function

        Protected Overridable Function GetStockpileGroupUserSettings() As XmlNodeList
            Dim stockpileGroupsString As String = Resources.UserSecurity.GetSetting("Stockpile_Filter_Stockpile_Groups", "")
            Dim stockpileGroupsList As XmlNodeList = Nothing
            Dim stockpileGroupsUserSetting As New XmlDocument

            If (stockpileGroupsString <> String.Empty) Then
                Try
                    stockpileGroupsUserSetting.InnerXml = stockpileGroupsString
                    stockpileGroupsList = stockpileGroupsUserSetting.SelectNodes("/docElement/Id")
                Catch ex As XmlException
                    stockpileGroupsList = Nothing
                End Try
            End If

            Return stockpileGroupsList
        End Function

        Protected Overrides Sub SetupLayout()
            MyBase.SetupLayout()

            With LayoutTable
                .ID = "StockpileLayoutTable"

                .Rows(0).Cells(0).ColumnSpan = .Rows.Item(0).Cells.Item(0).ColumnSpan - 2
                .Rows(0).Cells(0).VerticalAlign = VerticalAlign.Top
                .CurrentRow = .Rows(0)
                IncludeLocationsBelow.Text = "Include Stockpiles Below This Location"
                .AddCell.Controls.Add(IncludeLocationsBelow)
                .CurrentCell.VerticalAlign = VerticalAlign.Top

                .AddCellInNewRow.Controls.Add(New LiteralControl("Transaction Date From:"))
                .AddCell.Controls.Add(DatePickers("TransactionStartDate").ControlScript)
                .AddCell.Controls.Add(New LiteralControl("Transaction Date To:"))
                .AddCell.Controls.Add(DatePickers("TransactionEndDate").ControlScript)

                ' Build Stockpile Groups Check Boxes
                SetupStockpileGroupControls()
                Dim counter = 0
                Dim stockpileGroupsRow As New TableRow
                Dim stockpileGroupsTableCell As New TableCell

                stockpileGroupsTableCell.Controls.Add(New LiteralControl("Stockpile Groups: "))
                stockpileGroupsRow.Cells.Add(stockpileGroupsTableCell)
                stockpileGroupsRow.ID = "StockpileGroupsRow0"

                Dim stockpileGroupEnabled As String = Resources.UserSecurity.GetSetting("Stockpile_Filter_Group_Stockpiles", "True").ToLower()

                For Each stockpileGroupsCheckBox As InputCheckBox In _stockpileGroupCheckBoxDictionary.Values
                    counter += 1

                    stockpileGroupsTableCell = New TableCell
                    stockpileGroupsTableCell.Controls.Add(stockpileGroupsCheckBox)
                    stockpileGroupsRow.Controls.Add(stockpileGroupsTableCell)

                    If counter Mod 3 = 0 Then
                        If (stockpileGroupEnabled = "true") Then
                            stockpileGroupsRow.Style.Item("display") = "inline"
                        Else
                            stockpileGroupsRow.Style.Item("display") = "none"
                        End If

                        .AddCellInNewRow.Controls.Add(stockpileGroupsRow)
                        stockpileGroupsRow = New TableRow
                        stockpileGroupsRow.ID = "StockpileGroupsRow" + (counter/3).ToString()
                        stockpileGroupsRow.Cells.Add(New TableCell)
                    End If
                Next

                If counter Mod 3 > 0 Then
                    .AddCellInNewRow.Controls.Add(stockpileGroupsRow)
                End If

                stockpileGroupsRow.ID = "StockpileGroupsRowBottom"
                stockpileGroupsTableCell = New TableCell
                stockpileGroupsTableCell.Controls.Add(CreateCheckBoxLinks())

                ' spacing before the check-all, un-check all boxes
                Dim spacerCellsNeeded As Integer = 3 - (counter Mod 3)
                Dim spacerIndex = 1
                While spacerIndex <= spacerCellsNeeded
                    stockpileGroupsRow.Cells.Add(New TableCell)
                    spacerIndex = spacerIndex + 1
                End While
                stockpileGroupsRow.Cells.Add(stockpileGroupsTableCell)

                If (stockpileGroupEnabled = "true") Then
                    stockpileGroupsRow.Style.Item("display") = "inline"
                Else
                    stockpileGroupsRow.Style.Item("display") = "none"
                End If

                .AddCellInNewRow.Controls.Add(stockpileGroupsRow)
                .AddCellInNewRow.Controls.Add(ResetButton)
            End With
        End Sub

        Protected Overrides Sub SetupResetButton()
            ' do not allow Core to insert the reset button prematurely
        End Sub
    End Class
End Namespace