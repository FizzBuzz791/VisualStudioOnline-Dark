Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports System.Web.UI.WebControls
Imports System.Web.UI
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Utilities
    Public Class ReferenceStockpileGroupEdit
        Inherits Reconcilor.Core.Website.Utilities.ReferenceStockpileGroupEdit

        Private visibleRadio As New ReconcilorControls.InputTags.InputRadio
        Private invisibleRadio As New ReconcilorControls.InputTags.InputRadio
        Private allvisibleRadio As New ReconcilorControls.InputTags.InputRadio
        Private ingroupRadio As New ReconcilorControls.InputTags.InputRadio
        Private notingroupsRadio As New ReconcilorControls.InputTags.InputRadio
        Private allgroupsRadio As New ReconcilorControls.InputTags.InputRadio
        Private onlyThisGroupRadio As New ReconcilorControls.InputTags.InputRadio
        Private notInThisGroupRadio As New ReconcilorControls.InputTags.InputRadio
        Private locationDropDown As New ReconcilorControls.ReconcilorLocationSelector
        Private Const paddingCharacters As String = "&nbsp&nbsp&nbsp&nbsp&nbsp"
        Private filterButton As New ReconcilorControls.InputTags.InputButtonFormless
        Private groupingRadioList As New Generic.Dictionary(Of String, ReconcilorControls.InputTags.InputRadio)
        Private visibleRadioList As New Generic.Dictionary(Of String, ReconcilorControls.InputTags.InputRadio)
        Private dalSecurityLocation As Bhpbio.Database.SqlDal.SqlDalSecurityLocation

        Protected Overrides Sub SetupFormControls()
            MyBase.SetupFormControls()

            'Disable the rename functionality as v6 can't support it properly for multiple locations
            'only do this if we are editing an existing site.
            If StockpileGroupId.Text.Trim <> "" Then
                StockpileGroupId.Enabled = False
            End If

            'Disable it by default.
            'SubmitEdit.Enabled = False
            SubmitEdit.Style.Add("display", "none")

            With visibleRadio
                .GroupName = "visibilityradio"
                .Text = " Visible"
                .Checked = False
                .Value = "visible"
                .ID = "visible"
            End With
            visibleRadioList.Add(visibleRadio.Value, visibleRadio)
            With invisibleRadio
                .GroupName = "visibilityradio"
                .Text = " Not Visible"
                .Checked = False
                .Value = "notvisible"
                .ID = "notvisible"
            End With
            visibleRadioList.Add(invisibleRadio.Value, invisibleRadio)
            With allvisibleRadio
                .GroupName = "visibilityradio"
                .Text = " All"
                .Checked = True
                .Value = "all"
                .ID = "allvisible"
            End With
            visibleRadioList.Add(allvisibleRadio.Value, allvisibleRadio)
            With ingroupRadio
                .GroupName = "groupradio"
                .Text = " In any group"
                .Checked = False
                .Value = "ingroup"
                .ID = "ingroup"
            End With
            groupingRadioList.Add(ingroupRadio.Value, ingroupRadio)
            With notingroupsRadio
                .GroupName = "groupradio"
                .Text = " Not In any groups"
                .Checked = False
                .Value = "notingroup"
                .ID = "notingroup"
            End With
            groupingRadioList.Add(notingroupsRadio.Value, notingroupsRadio)
            With allgroupsRadio
                .GroupName = "groupradio"
                .Text = " All"
                .Checked = False
                .Value = "all"
                .ID = "allgroup"
            End With
            groupingRadioList.Add(allgroupsRadio.Value, allgroupsRadio)
            With onlyThisGroupRadio
                .GroupName = "groupradio"
                .Text = " Only in this group "
                .Checked = True
                .Value = "thisgroup"
                .ID = "thisgroup"
            End With
            groupingRadioList.Add(onlyThisGroupRadio.Value, onlyThisGroupRadio)
            With notInThisGroupRadio
                .GroupName = "groupradio"
                .Text = " Not in this group "
                .Checked = False
                .Value = "notinthisgroup"
                .ID = "notinthisgroup"
            End With
            groupingRadioList.Add(notInThisGroupRadio.Value, notInThisGroupRadio)

            With locationDropDown
                .ID = "locationid"
            End With
            With filterButton
                .ID = "Filter"
                .Text = " Filter "
                .Value = " Filter "
                .OnClientClick = "return GetBhpbioStockpileGroupStockpileList();"
            End With

            GetUserSettings()

        End Sub

        Protected Overridable Sub GetUserSettings()

            Dim stockpileGroupingFilter As String = String.Empty
            Dim stockpileVisibleFilter As String = String.Empty
            Dim stockpileLocationFilter As Int32 = NullValues.Int32
            Dim defaultLocationIdForUser As Int32

            stockpileGroupingFilter = Resources.UserSecurity.GetSetting("STOCKPILEGROUP_GROUPING_FILTER", NullValues.String)
            stockpileVisibleFilter = Resources.UserSecurity.GetSetting("STOCKPILEGROUP_VISIBLE_FILTER", NullValues.String)
            stockpileLocationFilter = Convert.ToInt32(Resources.UserSecurity.GetSetting("STOCKPILEGROUP_LOCATION_FILTER", Convert.ToString(NullValues.Int32)))

            If (stockpileLocationFilter > 0 AndAlso DalUtility.GetLocation(stockpileLocationFilter).Rows.Count > 0) Then
                'If a valid location id was supplied then use it.
                locationDropDown.LocationId = stockpileLocationFilter
            Else
                'Get the default location for the current user, and use that.
                defaultLocationIdForUser = dalSecurityLocation.GetBhpbioUserLocation(Resources.UserSecurity.UserId.Value)
                If defaultLocationIdForUser <> NullValues.Int32 Then
                    locationDropDown.LocationId = defaultLocationIdForUser
                End If
            End If

            'Set the correct grouping radio option to true
            If groupingRadioList.ContainsKey(stockpileGroupingFilter) Then
                'Reset all radio check boxes
                For Each radio As ReconcilorControls.InputTags.InputRadio In groupingRadioList.Values
                    radio.Checked = False
                Next
                groupingRadioList(stockpileGroupingFilter).Checked = True
            End If
            'Set the correct radio visiblity option to true
            If visibleRadioList.ContainsKey(stockpileVisibleFilter) Then
                'Reset all radio check boxes
                For Each radio As ReconcilorControls.InputTags.InputRadio In visibleRadioList.Values
                    radio.Checked = False
                Next
                visibleRadioList(stockpileVisibleFilter).Checked = True
            End If

        End Sub

        Protected Overrides Sub LayoutForm()

            MyBase.LayoutForm()

            Dim visibleRow As New TableRow
            Dim groupRow As New TableRow
            Dim locationRow As New TableRow
            Dim locationRowTableHolder As New Table
            Dim cellIndex As Int32
            Dim locationFilterGroupBox As New GroupBox()
            Dim divContainer As New Tags.HtmlDivTag()


            With visibleRow
                cellIndex = .Cells.Add(New TableCell)
                .Cells(cellIndex).Controls.Add(New LiteralControl("Stockpile Visibility: " + paddingCharacters))
                .Cells(cellIndex).HorizontalAlign = HorizontalAlign.Right
                cellIndex = .Cells.Add(New TableCell)
                .Cells(cellIndex).Controls.Add(visibleRadio)
                .Cells(cellIndex).Width = 125
                cellIndex = .Cells.Add(New TableCell)
                .Cells(cellIndex).Controls.Add(invisibleRadio)
                .Cells(cellIndex).Width = 100
                cellIndex = .Cells.Add(New TableCell)
                .Cells(cellIndex).Controls.Add(allvisibleRadio)
                .Cells(cellIndex).ColumnSpan = 3
            End With

            With groupRow
                cellIndex = .Cells.Add(New TableCell)
                .Cells(cellIndex).Controls.Add(New LiteralControl("Grouping: " + paddingCharacters))
                .Cells(cellIndex).HorizontalAlign = HorizontalAlign.Right
                cellIndex = .Cells.Add(New TableCell)
                .Cells(cellIndex).Controls.Add(onlyThisGroupRadio)
                .Cells(cellIndex).Width = 125
                cellIndex = .Cells.Add(New TableCell)
                .Cells(cellIndex).Controls.Add(notInThisGroupRadio)
                .Cells(cellIndex).Width = 125
                cellIndex = .Cells.Add(New TableCell)
                .Cells(cellIndex).Controls.Add(ingroupRadio)
                .Cells(cellIndex).Width = 100
                cellIndex = .Cells.Add(New TableCell)
                .Cells(cellIndex).Controls.Add(notingroupsRadio)
                .Cells(cellIndex).Width = 125
                cellIndex = .Cells.Add(New TableCell)
                .Cells(cellIndex).Controls.Add(allgroupsRadio)
                .Cells(cellIndex).ColumnSpan = 1
                .Cells(cellIndex).Width = 118
            End With

            With locationRow
                cellIndex = .Cells.Add(New TableCell)
                .Cells(cellIndex).Width = 37
                cellIndex = .Cells.Add(New TableCell)
                .Cells(cellIndex).HorizontalAlign = HorizontalAlign.Left
                .Cells(cellIndex).ColumnSpan = 5
                .Cells(cellIndex).Controls.Add(locationDropDown)
                locationDropDown.LowestLocationTypeDescription = "Blast"
            End With

            With locationRowTableHolder
                .Rows.Add(locationRow)
            End With

            divContainer.Controls.Add(locationRowTableHolder)

            LayoutBox.Width = 855



            With LayoutTable
                .Width = 735
                'Add the location filter control
                .Rows.AddAt(.Rows.Count - 2, New TableRow)
                cellIndex = .Rows(.Rows.Count - 3).Cells.Add(New TableCell)
                .Rows(.Rows.Count - 3).Cells(cellIndex).Controls.Add(divContainer)
                .Rows(.Rows.Count - 3).Cells(cellIndex).ColumnSpan = 6
                'Add additional radio controls before the stockpile listing reconcilor table
                .Rows.AddAt(.Rows.Count - 2, visibleRow)
                .Rows.AddAt(.Rows.Count - 2, groupRow)
                'Add the filter button
                .Rows.AddAt(.Rows.Count - 2, New TableRow)
                cellIndex = .Rows(.Rows.Count - 3).Cells.Add(New TableCell)
                .Rows(.Rows.Count - 3).Cells(cellIndex).HorizontalAlign = HorizontalAlign.Right
                .Rows(.Rows.Count - 3).Cells(cellIndex).Controls.Add(filterButton)
                'Add a horizontal divider line between filter and list
                .Rows.AddAt(.Rows.Count - 2, New TableRow)
                cellIndex = .Rows(.Rows.Count - 3).Cells.Add(New TableCell)
                .Rows(.Rows.Count - 3).Cells(cellIndex).Controls.Add(New LiteralControl("<hr>"))
            End With

            AddProgressIndicator()
        End Sub

        Private Sub AddProgressIndicator()
            Dim imageLoader As New Tags.HtmlDivTag("saveLoadDiv")
            Dim buttonTable As New Tags.HtmlTableTag()
            Dim buttonParent As Control = SubmitEdit.Parent

            buttonParent.Controls.Remove(SubmitEdit)
            buttonTable.AddCellInNewRow().Controls.Add(imageLoader)
            buttonTable.AddCell().Controls.Add(SubmitEdit)
            buttonParent.Controls.Add(buttonTable)

            EditForm.OnSubmit = "return SubmitForm('" & EditForm.ID & "', 'saveLoadDiv', './ReferenceStockpileGroupSave.aspx', 'image');"
        End Sub

        Protected Overrides Sub RunAjax()

            'Override onloadscript so page does not do anything.
            OnLoadScriptTag = New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "")

            MyBase.RunAjax()


        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()
            If dalSecurityLocation Is Nothing Then
                dalSecurityLocation = New Bhpbio.Database.SqlDal.SqlDalSecurityLocation(Resources.Connection)
            End If
        End Sub



    End Class
End Namespace
