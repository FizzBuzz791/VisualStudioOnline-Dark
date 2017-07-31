Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags

Namespace ReconcilorControls.FilterBoxes.Analysis
    Public Class DigblockSpatialFilterBox
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.Analysis.DigblockSpatialFilterBox

        Private Const _designationCategoryId As String = "Designation"

        Private _leftComparisonSelection As Int32?
        Private _rightComparisonSelection As Int32?
        Private _attributeRadio As New Generic.Dictionary(Of Int16, InputRadio)
        Private _resetButton As InputButtonFormless
        Private _designationFilter As SelectBox

        Private _AttributeFilter As String

        Public ReadOnly Property AttributeFilter() As String
            Get
                Return _AttributeFilter
            End Get
        End Property

        Public ReadOnly Property ResetButton() As Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags.InputButtonFormless
            Get
                Return _resetButton
            End Get
        End Property

        Public ReadOnly Property DesignationFilter() As SelectBox
            Get
                Return _designationFilter
            End Get
        End Property

        Protected Overrides Function GetBlockModelData() As System.Data.DataTable
            Return DalBlockModel.GetBlockModelList(DoNotSetValues.Int32, DoNotSetValues.String, 1)
        End Function

        Protected Overrides Sub SetupControls()
            Dim setting As String
            Dim locationId As Int32
            Dim attributeKey As Int16

            MyBase.SetupControls()

            'Remove options from the analysis selection
            LeftComparison.Items.Remove(LeftComparison.Items.FindByText("Mine Plan"))
            LeftComparison.Items.Remove(LeftComparison.Items.FindByText("Actual Survey"))
            RightComparison.Items.Remove(RightComparison.Items.FindByText("Mine Plan"))
            RightComparison.Items.Remove(RightComparison.Items.FindByText("Actual Survey"))

            'load the default for the location filter
            setting = Resources.UserSecurity.GetSetting("Spatial_Comparison_Filter_LocationId", Nothing)
            If (setting Is Nothing) OrElse Not Int32.TryParse(setting, locationId) Then
                'there is no applicable default
                LocationFilter.LocationId = Nothing
            Else
                LocationFilter.LocationId = locationId
            End If

            'load the defaults
            setting = Resources.UserSecurity.GetSetting("Spatial_Comparison_Filter_Designation", Nothing)
            If (setting Is Nothing) Then
                DesignationFilter.SelectedValue = Nothing
            Else
                DesignationFilter.SelectedValue = setting
            End If

            setting = Resources.UserSecurity.GetSetting("Spatial_Comparison_Filter_LeftComparison", Nothing)
            If (setting Is Nothing) Then
                LeftComparison.SelectedValue = Nothing
            Else
                LeftComparison.SelectedValue = setting
            End If

            setting = Resources.UserSecurity.GetSetting("Spatial_Comparison_Filter_RightComparison", Nothing)
            If (setting Is Nothing) Then
                RightComparison.SelectedValue = Nothing
            Else
                RightComparison.SelectedValue = setting
            End If

            setting = Resources.UserSecurity.GetSetting("Spatial_Comparison_Filter_LeftBlockModel", Nothing)
            If (setting Is Nothing) Then
                LeftBlockModel.SelectedValue = Nothing
            Else
                LeftBlockModel.SelectedValue = setting
            End If

            setting = Resources.UserSecurity.GetSetting("Spatial_Comparison_Filter_RightBlockModel", Nothing)
            If (setting Is Nothing) Then
                RightBlockModel.SelectedValue = Nothing
            Else
                RightBlockModel.SelectedValue = setting
            End If

            For Each attributeKey In _attributeRadio.Keys
                _attributeRadio(attributeKey).Checked = False
            Next
            setting = Resources.UserSecurity.GetSetting("Spatial_Comparison_Filter_AttributeFilter", Nothing)
            If Not (setting Is Nothing) AndAlso Int16.TryParse(setting, attributeKey) Then
                If _attributeRadio.ContainsKey(attributeKey) Then
                    _attributeRadio(attributeKey).Checked = True
                End If
            Else
                _attributeRadio(0).Checked = True
            End If

            'call into custom bhp form validation
            Me.ServerForm.OnSubmit = "return RenderBhpbioSpatialComparison();"

            'put the Filter button on the same row... as we have a Reset Filters button coming
            ButtonOnNewRow = False
        End Sub

        Protected Overrides Sub SetupLayout()
            MyBase.SetupLayout()

            Dim attributeSelector As InputRadio
            Dim row As WebControls.TableRow
            Dim cell As WebControls.TableCell
            Dim counter As Integer 'Used to determine when new row required, 3 elements per row.
            Dim dateFormat As String = Context.Application("DateFormat").ToString
            Dim defaultFromDateText As String
            Dim defaultToDateText As String

            'add the designation filter
            CreateDesignationFilter()

            row = New WebControls.TableRow()
            cell = New WebControls.TableCell()
            cell.Controls.Add(New LiteralControl("Designation: "))
            row.Cells.Add(cell)

            cell = New WebControls.TableCell()
            cell.Controls.Add(_designationFilter)
            row.Cells.Add(cell)

            LayoutTable.Rows.AddAt(2, row)

            'add the attribute filter
            CreateAttributes()

            row = New WebControls.TableRow()

            'add Label
            cell = New WebControls.TableCell()
            cell.Controls.Add(New LiteralControl("Attribute: "))
            row.Cells.Add(cell)

            'add the attributes
            counter = 0
            For Each attributeSelector In _attributeRadio.Values
                If counter > 0 Then
                    cell = New TableCell()
                    cell.Controls.Add(New LiteralControl("&nbsp;"))
                    row.Cells.Add(cell)
                End If

                cell = New WebControls.TableCell()
                cell.Controls.Add(attributeSelector)
                row.Cells.Add(cell)

                'increment the row element counter
                counter += 1

                'if the no of elements on this row is already 3 create a new row
                If counter Mod 3 = 0 Then
                    LayoutTable.Rows.Add(row)
                    row = New WebControls.TableRow()
                End If
            Next

            'if the counter shows remaining elements add the final record
            If counter Mod 3 > 0 Then
                LayoutTable.Rows.Add(row)
            End If

            'add the filter box (on a separate row for the moment, may need to be cleaned up)
            row = New WebControls.TableRow()
            cell = New WebControls.TableCell
            row.Cells.Add(cell)
            LayoutTable.Rows.Add(row)

            'remove the filter boxes for: Mine Plan Type and Mine Plan
            Me.TableRows(TableRowTypes.MinePlan).Visible = False
            Me.TableRows(TableRowTypes.MinePlanType).Visible = False

            'define the reset button
            defaultFromDateText = Resources.UserSecurity.GetSetting("Spatial_Comparison_Filter_Date_From", New DateTime(Now.Year, Now.Month, 1).ToString(dateFormat))
            defaultToDateText = Resources.UserSecurity.GetSetting("Spatial_Comparison_Filter_Date_To", Now.ToString(dateFormat))

            _resetButton = New Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags.InputButtonFormless
            _resetButton.ID = "AnalysisFilterResetButton"
            _resetButton.Value = " Reset Filters "
            _resetButton.OnClientClick = "ResetBhpbioAnalysisFilters('" & _
             defaultFromDateText & "', '" & defaultToDateText & "', " & _
             LocationFilter.LocationLabelCellWidth.ToString & ", '" & _
             LocationFilter.LocationDiv.ID & "' );"

            'add the reset button
            row = New WebControls.TableRow()

            cell = New WebControls.TableCell()
            cell.Controls.Add(_resetButton)
            cell.Controls.Add(New LiteralControl("&nbsp;"))
            cell.HorizontalAlign = HorizontalAlign.Right
            row.Cells.Add(cell)

            LayoutTable.Controls.Add(row)
        End Sub

        Private Sub CreateDesignationFilter()
            Dim designations As DataTable
            Dim designation As DataRow

            designations = DalUtility.GetMaterialTypeList(NullValues.Int16, NullValues.Int16, _
             NullValues.Int32, _designationCategoryId, NullValues.Int32)
            Try
                _designationFilter = New SelectBox()
                _designationFilter.Items.Add(New WebControls.ListItem("", "-1"))
                _designationFilter.ID = "Designation"

                For Each designation In designations.Select("", "Abbreviation")
                    _designationFilter.Items.Add(New WebControls.ListItem( _
                     DirectCast(designation("Abbreviation"), String), _
                     designation("Material_Type_Id").ToString))
                Next
            Finally
                If Not (designations Is Nothing) Then
                    designations.Dispose()
                    designations = Nothing
                End If
            End Try
        End Sub

        Private Sub CreateAttributes()
            Dim gradeData As DataTable
            Dim attributeSelector As InputRadio

            'add the attributes: tonnes
            attributeSelector = New InputRadio()
            attributeSelector.ID = "Tonnes"
            attributeSelector.GroupName = "AttributeFilter"
            attributeSelector.Value = "Tonnes"
            attributeSelector.Text = "Tonnes"
            attributeSelector.Checked = True
            _attributeRadio.Add(0, attributeSelector)

            'add the attributes: grades

            gradeData = DalUtility.GetGradeList(Convert.ToInt16(True))

            For Each gradeRow As DataRow In gradeData.Select("", "Order_No")
                ' Create the Input Radio Button
                attributeSelector = New InputRadio()
                attributeSelector.ID = gradeRow("Grade_Id").ToString
                attributeSelector.GroupName = "AttributeFilter"
                attributeSelector.Value = gradeRow("Grade_Id").ToString
                attributeSelector.Text = gradeRow("Description").ToString
                _attributeRadio.Add(DirectCast(gradeRow("Grade_Id"), Int16), attributeSelector)
            Next
        End Sub

        Protected Overrides Sub CompleteLayout()
            MyBase.CompleteLayout()

            'force the select change on Comparison A / B
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
             "SpatialComparisonSeletion(document.getElementById('LeftComparison'), 'Left');"))
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
             "SpatialComparisonSeletion(document.getElementById('RightComparison'), 'Right');"))
        End Sub
    End Class
End Namespace
