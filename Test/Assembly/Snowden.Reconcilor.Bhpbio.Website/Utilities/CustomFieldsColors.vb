Imports System.Drawing
Imports System.Drawing.Drawing2D
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports System.Web.UI.WebControls
Imports ChartFX.WebForms
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates

Namespace Utilities
    Public Class CustomFieldsColors
        Inherits UtilitiesAjaxTemplate

#Region " Properties "
        Private _disposed As Boolean
        Private _colorList As New ArrayList
        Private _lineStyleList As New ArrayList
        Private _markerShapeList As New ArrayList
        Private ReadOnly _colorTerm As String = ReconcilorFunctions.GetSiteTerminology("Color")
        Private Const GROUP_BOX_WIDTH As Int16 = 698

        Protected Property SaveButton As InputButton = New InputButton

        Protected Property LayoutTable As HtmlTableTag = New HtmlTableTag()

        Protected Property LayoutBox As GroupBox = New GroupBox($"{_colorTerm} Configuration")

        Public Property DalUtility As IUtility

        Public Property DetailsForm As HtmlFormTag = New HtmlFormTag()
#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                    End If

                    If (Not LayoutBox Is Nothing) Then
                        LayoutBox.Dispose()
                        LayoutBox = Nothing
                    End If

                    If (Not LayoutTable Is Nothing) Then
                        LayoutTable.Dispose()
                        LayoutTable = Nothing
                    End If

                    If (Not SaveButton Is Nothing) Then
                        SaveButton.Dispose()
                        SaveButton = Nothing
                    End If

                    If (Not DetailsForm Is Nothing) Then
                        DetailsForm.Dispose()
                        DetailsForm = Nothing
                    End If

                    If (Not DalUtility Is Nothing) Then
                        DalUtility.Dispose()
                        DalUtility = Nothing
                    End If
                End If

                _colorList = Nothing
                _lineStyleList = Nothing
                _markerShapeList = Nothing

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region

        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("MANAGE_BHPBIO_CUSTOM_FIELDS_CONFIGURATION"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Private Sub SetupPageColours()
            Dim enumColour As New KnownColor
            Dim enumLineStyle As New DashStyle
            Dim enumMarkerShape As New MarkerShape
            Dim colours As Array = [Enum].GetValues(enumColour.GetType())
            Dim lineStyles As Array = [Enum].GetValues(enumLineStyle.GetType())
            Dim markerShapes As Array = [Enum].GetValues(enumMarkerShape.GetType())
            Dim clr As Object

            'Colors
            For Each clr In colours
                Dim drawColour As Color = Color.FromKnownColor(CType(clr, KnownColor))

                If (Not drawColour.IsSystemColor) And (drawColour <> Color.Transparent) And (drawColour <> Color.White) Then
                    _colorList.Add(drawColour.ToString.Replace("Color [", "").Replace("]", ""))
                End If
            Next

            'Line Styles
            For Each lineStyle As DashStyle In lineStyles
                If (lineStyle <> DashStyle.Custom) Then
                    _lineStyleList.Add(lineStyle)
                End If
            Next

            'Marker Shapes
            For Each markerShape As MarkerShape In markerShapes
                If (markerShape <> MarkerShape.Picture) And (markerShape <> MarkerShape.Many) Then
                    _markerShapeList.Add(markerShape)
                End If
            Next
        End Sub
        
        'TODO: See if there's somewhere better for this
        Private Shared Function GetRowValue(Of T)(row As DataRow, propertyName As String, defaultValue As T) As T
            If (row(propertyName) IsNot DBNull.Value) Then
                Return DirectCast(Convert.ChangeType(row(propertyName), GetType(T)), T)
            Else 
                Return defaultValue
            End If
        End Function

        Protected Overridable Sub SetupPageControls()
            Dim colorSettings As DataTable = DalUtility.GetBhpbioReportColorList(DoNotSetValues.String, True)
            Dim row As DataRow

            With LayoutBox
                .Width = GROUP_BOX_WIDTH
            End With

            With DetailsForm
                .ID = "detailsForm"
            End With

            With SaveButton
                .ID = "SaveColors"
                .Text = " Save "
                .Font.Size = 8
                .Width = 160
                .OnClientClick = "return SaveCustomFieldsColors();"
            End With

            With LayoutTable
                'Set up spacings
                .CellSpacing = 2
                .CellPadding = 2

                'Set up header row
                .AddCellInNewRow()
                .AddCell()
                .AddCell().Text = _colorTerm
                .AddCell().Text = "Preview"
                .AddCell().Text = "Line Style"
                .AddCell().Text = "Preview"
                .AddCell().Text = "Marker"
                .AddCell().Text = "Preview"

                For Each row In colorSettings.Rows()
                    .AddCellInNewRow().Text = row("Description").ToString
                    
                    Dim tagId As String = row("TagId").ToString()
                    Dim configIdTag = New InputHidden() With {
                            .ID = $"colorConfigId{tagId}",
                            .Value = tagId
                            }
                    .AddCell().Controls.Add(configIdTag)

                    'Create a new cell and add the colour picker.
                    Dim colourPicker = New SelectBox()
                    With colourPicker
                        .ID = $"colorSelect{tagId}"
                        .DataSource = _colorList
                        .DataBind()
                        .OnSelectChange = "PreviewCustomFieldColour(this);"

                        Dim color As String = GetRowValue(row, "Color", "Black") 'Default to a known value. Less likely to cause unknown behaviour
                        If color <> NullValues.String Then
                            If (Not _colorList.Contains(color)) Then
                                colourPicker.Items.Add(New ListItem($"Custom {_colorTerm}: {color}", color))
                            End If
                            colourPicker.SelectedValue = color
                        End If
                    End With
                    .AddCell().Controls.Add(colourPicker)

                    'Create a new cell which will contain the colour that is picked
                    .AddCell().ID = $"colorSelect{tagId}Thatch"
                    .CurrentCell.Width = Unit.Pixel(35)
                    .CurrentCell.Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript,
                                                                $"PreviewCustomFieldColour(document.getElementById('colorSelect{tagId}'));;"))

                    'Create a new cell and add the line style
                    Dim lineStylePicker = New SelectBox()
                    With lineStylePicker
                        .ID = $"lineStyleSelect{tagId}"
                        .DataSource = _lineStyleList
                        .DataBind()

                        .OnSelectChange = "PreviewCustomFieldLineStyle(this);"
                        Dim lineStyle As String = GetRowValue(row, "LineStyle", "Solid") 'Default to a known value. Less likely to cause unknown behaviour
                        If lineStyle <> NullValues.String Then
                            lineStylePicker.SelectedValue = CovertLineStyleFrom2008(lineStyle)
                        End If
                    End With
                    .AddCell().Controls.Add(lineStylePicker)

                    'Create a new cell which will contain the colour that is picked
                    Dim lineStyleImage As New Web.UI.WebControls.Image With {
                        .Width = 46,
                        .Height = 2,
                        .ID = $"lineStyleSelect{tagId}Preview"
                            }
                    .AddCell().Controls.Add(lineStyleImage)
                    .CurrentCell.Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript,
                                                                $"PreviewCustomFieldLineStyle(document.getElementById('lineStyleSelect{tagId}'));;"))

                    'Create a new cell and add the line style
                    Dim markerShapePicker = New SelectBox()
                    With markerShapePicker
                        .ID = $"markerShapeSelect{tagId}"
                        .DataSource = _markerShapeList
                        .DataBind()

                        .OnSelectChange = "PreviewCustomFieldMarkerShape(this);"
                        Dim markerShape As String = GetRowValue(row, "MarkerShape", "None") ' Default to a known value. Less likely to cause unknown behaviour
                        If markerShape <> NullValues.String Then
                            markerShapePicker.SelectedValue = markerShape
                        End If
                    End With
                    .AddCell().Controls.Add(markerShapePicker)

                    Dim markerShapeImage As New Web.UI.WebControls.Image With {
                        .Width = 16,
                        .ID = $"markerShapeSelect{tagId}Preview"
                            }
                    .AddCell().Controls.Add(markerShapeImage)
                    .CurrentCell.Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript,
                                                                $"PreviewCustomFieldMarkerShape(document.getElementById('markerShapeSelect{tagId}'));;"))
                Next

                .AddCellInNewRow().HorizontalAlign = HorizontalAlign.Right
                .CurrentCell.Controls.Add(SaveButton)
            End With
        End Sub

        Protected Sub SetupPageLayout()
            'Add the layout table to the form
            DetailsForm.Controls.Add(LayoutTable)

            'Add the form to the group box.
            LayoutBox.Controls.Add(DetailsForm)

            ' Add the layout box to the Page.
            Controls.Add(LayoutBox)
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            SetupPageColours()
            SetupPageControls()
            SetupPageLayout()

        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        ' SSRS 2008 uses new names for the line styles, so we need to convert to and from when 
        ' setting the drop down boxes on the utilities page
        Protected Function CovertLineStyleFrom2008(lineStyle As String) As String
            Select Case lineStyle
                Case "Dashed" : Return "Dash"
                Case "Dotted" : Return "Dot"
                Case Else : Return lineStyle
            End Select
        End Function

    End Class
End Namespace