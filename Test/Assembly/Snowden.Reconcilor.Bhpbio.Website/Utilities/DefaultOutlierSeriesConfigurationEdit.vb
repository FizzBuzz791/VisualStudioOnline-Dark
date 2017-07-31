Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports System.Web.UI.WebControls
Imports System.Web.UI
Imports Snowden.Consulting.DataSeries.DataAccess
Imports Snowden.Reconcilor.Bhpbio.Website.Extensibility
Namespace Utilities

    Public Class DefaultOutlierSeriesConfigurationEdit
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

#Region "Properties"

        Private _outlierSeriesConfigurationId As New InputHidden
        Private _isactive As New CheckBox
        Private _priorityBox As New InputText
        Private _outlierThreshold As New InputText
        Private _minimumDataPoints As New InputText
        Private _rollingSeriesSize As New InputText
        Private _description As New InputTextArea
        Private _projectValueMethod As New SelectBox
        Private _editForm As New HtmlFormTag
        Private _layoutBox As New GroupBox
        Private _layoutTable As New HtmlTableTag
        Private _submitEdit As New InputButton
        Private _cancelEdit As New InputButton
        Private _returnTable As ReconcilorTable
        Protected Property OutlierSeriesConfigurationId() As InputHidden
            Get
                Return _outlierSeriesConfigurationId
            End Get
            Set(ByVal value As InputHidden)
                _outlierSeriesConfigurationId = value
            End Set
        End Property
        Protected Property IsActive() As CheckBox
            Get
                Return _isactive
            End Get
            Set(ByVal value As CheckBox)
                _isactive = value
            End Set
        End Property
        Protected Property PriorityBox() As InputText
            Get
                Return _priorityBox
            End Get
            Set(ByVal value As InputText)
                _priorityBox = value
            End Set
        End Property

        Protected Property OutlierThreshold() As InputText
            Get
                Return _outlierThreshold
            End Get
            Set(ByVal value As InputText)
                _outlierThreshold = value
            End Set
        End Property
        Protected Property MinimumDataPoints() As InputText
            Get
                Return _minimumDataPoints
            End Get
            Set(ByVal value As InputText)
                _minimumDataPoints = value
            End Set
        End Property
        Protected Property RollingSeriesSize() As InputText
            Get
                Return _rollingSeriesSize
            End Get
            Set(ByVal value As InputText)
                _rollingSeriesSize = value
            End Set
        End Property

        Protected Property Description() As InputTextArea
            Get
                Return _description
            End Get
            Set(ByVal value As InputTextArea)
                _description = value
            End Set
        End Property
        Public Property EditForm() As HtmlFormTag
            Get
                Return _editForm
            End Get
            Set(ByVal value As HtmlFormTag)
                If (Not value Is Nothing) Then
                    _editForm = value
                End If
            End Set
        End Property

        Public Property LayoutBox() As GroupBox
            Get
                Return _layoutBox
            End Get
            Set(ByVal value As GroupBox)
                If (Not value Is Nothing) Then
                    _layoutBox = value
                End If
            End Set
        End Property

        Public Property LayoutTable() As HtmlTableTag
            Get
                Return _layoutTable
            End Get
            Set(ByVal value As HtmlTableTag)
                If (Not value Is Nothing) Then
                    _layoutTable = value
                End If
            End Set
        End Property

        Public Property SubmitEdit() As InputButton
            Get
                Return _submitEdit
            End Get
            Set(ByVal value As InputButton)
                If (Not value Is Nothing) Then
                    _submitEdit = value
                End If
            End Set
        End Property

        Private Property CancelEdit() As InputButton
            Get
                Return _cancelEdit
            End Get
            Set(ByVal value As InputButton)
                _cancelEdit = value
            End Set
        End Property
#End Region
        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()
            If Not Request("OutlierSeriesConfigurationId") Is Nothing Then
                OutlierSeriesConfigurationId.Value = Request("OutlierSeriesConfigurationId").Trim
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                SetupFormControls()
                Controls.Add(EditForm)
            Catch ex As Exception
                JavaScriptAlert(ex.Message)
            End Try
        End Sub

        Protected Overridable Sub SetupFormControls()
            Dim rowIndex, cellIndex As Integer
            Dim title As String = "View / Edit"
            SubmitEdit.ID = "DefaultProductTypeSubmit"
            SubmitEdit.Text = " Save "

            CancelEdit.ID = "CancelSubmit"
            CancelEdit.Text = " Cancel "
            CancelEdit.OnClientClick = "return CancelEditOutlierSeriesConfiguration();"

            EditForm.ID = "EditOutlierSeriesConfigurationEditForm"
            IsActive.ID = "IsActive"

            PriorityBox.ID = "Priority"
            OutlierThreshold.ID = "OutlierThreshold"
            Description.ID = "Description"
            MinimumDataPoints.ID = "MinimumDataPoints"
            RollingSeriesSize.ID = "RollingSeriesSize"

            Dim scriptBuilder As New System.Text.StringBuilder()

            scriptBuilder.Append("var triggerOutlierProcessing = false;")
            ' the save operation will be performed regardless of the user choice, however the user must be asked whether outlier processing should be triggered after the save or not
            ' the JavaScript confirm window will have OK and Cancel buttons.. these are fixed so the message needs to be worded around this limitation... it must be clear the Cancel option is not cancelling the save itself
            scriptBuilder.Append("if (confirm('Press OK to continue with outlier reprocessing after save.')) {")
            scriptBuilder.Append("   triggerOutlierProcessing = true;")
            scriptBuilder.Append("}")
            scriptBuilder.Append("return SubmitForm('" & EditForm.ID & "', 'itemList', './DefaultOutlierSeriesConfigurationSave.aspx?TriggerOutlierProcessing='.concat(triggerOutlierProcessing));")

            EditForm.OnSubmit = scriptBuilder.ToString()

            OutlierSeriesConfigurationId.ID = "OutlierSeriesConfigurationId"
            EditForm.Controls.Add(OutlierSeriesConfigurationId)

            _projectValueMethod = New SelectBox()
            With _projectValueMethod
                .ID = "projectValueMethod"
                .Items.Insert(0, New ListItem("Linear Projection", "LinearProjection"))
                .Items.Insert(1, New ListItem("Rolling Average", "RollingAverage"))
            End With
            Dim seriestype = OutlierHelper.GetSeriesType(Resources.ConnectionString, OutlierSeriesConfigurationId.Value)
            Dim outlierconfig = OutlierHelper.GetConfigurationForSeriesType(Resources.ConnectionString, OutlierSeriesConfigurationId.Value)
            If outlierconfig IsNot Nothing Then
                PriorityBox.Text = outlierconfig.Priority.ToString()
                OutlierThreshold.Text = outlierconfig.OutlierThreshold.ToString()
                MinimumDataPoints.Text = outlierconfig.MinimumDataPoints.ToString()
                RollingSeriesSize.Text = outlierconfig.RollingSeriesSize.ToString()
                Description.Value = outlierconfig.Description.ToString()
                IsActive.Checked = outlierconfig.IsActive
                _projectValueMethod.SelectedValue = outlierconfig.ProjectedValueMethod
            End If

            With LayoutTable
                .ID = "DefaultOutlierSeriesLayout"
                .Width = Unit.Percentage(100)
                .CellPadding = 2
                .CellSpacing = 2

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Is Active:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(IsActive)
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Name:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl(seriestype.Name))
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("By Attribute:"))
                    cellIndex = .Cells.Add(New TableCell)

                    .Cells(cellIndex).Controls.Add(New LiteralControl(AttributeHelper.GetStringValueOrDefault(seriestype.Attributes, "Attribute", String.Empty)))
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Location Granularity:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl(AttributeHelper.GetStringValueOrDefault(seriestype.Attributes, "LocationType", String.Empty)))
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("By Product Size :"))
                    cellIndex = .Cells.Add(New TableCell)

                    Dim prodsize = "No"

                    If AttributeHelper.GetValueOrDefault(seriestype.Attributes, "ByProductSize", False) Then
                        prodsize = "Total, Lump, Fines"
                    Else
                        prodsize = "No"
                    End If

                    .Cells(cellIndex).Controls.Add(New LiteralControl(prodsize))
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("By Material Type :"))
                    cellIndex = .Cells.Add(New TableCell)

                    Dim matType As String = "Unknown"

                    If AttributeHelper.GetValueOrDefault(seriestype.Attributes, "ByMaterialType", False) Then
                        matType = "Yes"
                    Else
                        matType = "No"
                    End If

                    .Cells(cellIndex).Controls.Add(New LiteralControl(matType))
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Priority :"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(PriorityBox)
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Projected Value Method :"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(_projectValueMethod)
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Outlier Threshold :"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(OutlierThreshold)
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Minimum Data Points :"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(MinimumDataPoints)
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Rolling Series Size :"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(RollingSeriesSize)
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Description :"))
                    cellIndex = .Cells.Add(New TableCell)
                    Description.Rows = 6
                    Description.Cols = 55
                    .Cells(cellIndex).Controls.Add(Description)
                End With

                Dim dateFormat = CType(Application("DateFormat"), String)
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Absolute Start Month :"))
                    cellIndex = .Cells.Add(New TableCell)
                    Dim startdate = Date.Parse("01/01/1900").ToString(dateFormat)
                    If outlierconfig.AbsoluteStart.HasValue Then
                        startdate = outlierconfig.AbsoluteStart.Value.ToString(dateFormat)
                    End If
                    .Cells(cellIndex).Controls.Add(New LiteralControl(startdate))
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Absolute End Month :"))
                    cellIndex = .Cells.Add(New TableCell)
                    Dim enddate = Date.Parse("31/12/2050").ToString(dateFormat)
                    If outlierconfig.AbsoluteEnd.HasValue Then
                        enddate = outlierconfig.AbsoluteEnd.Value.ToString(dateFormat)
                    End If
                    .Cells(cellIndex).Controls.Add(New LiteralControl(enddate))
                End With
            End With

            Dim noteTable As New HtmlTableTag()
            With noteTable
                Dim noteRowIndex = .Rows.Add(New TableRow)
                With .Rows(noteRowIndex)
                    cellIndex = .Cells.Add(New TableCell())
                    .Cells(cellIndex).Controls.Add(New LiteralControl("<BR/>NOTE: Processing is only required when one or more of the following fields are changed: Minimum Data Points, Rolling Series Size, Projected Value Method."))
                End With
            End With

            With LayoutBox
                .Title = title
                .Width = Unit.Percentage(56)
                .Controls.Add(LayoutTable)
                .Controls.Add(New LiteralControl("<BR/>"))
                .Controls.Add(SubmitEdit)
                .Controls.Add(New LiteralControl("&nbsp;&nbsp;"))
                .Controls.Add(CancelEdit)
                .Controls.Add(noteTable)
            End With

            EditForm.Controls.Add(LayoutBox)
        End Sub

    End Class

End Namespace
