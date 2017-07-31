Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Common.Database
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.Website.Analysis
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports System.Drawing
Imports System.Web.UI.WebControls
Imports System.Web.UI

Namespace Analysis
    Public Class DigblockSpatialVarianceViewSetup
        Inherits Core.WebDevelopment.WebpageTemplates.AnalysisAjaxTemplate

#Region " Properties "
        Private _dalUtility As Database.DalBaseObjects.IUtility
        Private _locationId As Int32
        Private _varianceForm As New Tags.HtmlFormTag
        Private _varianceLayoutTable As New HtmlTableTag
        Private _layoutTable As New HtmlTableTag
        Private _inheritTable As ReconcilorTable
        Private _groupBoxWidth As Int32 = 350
        Private _removeButton As New InputTags.InputButton
        Private _applyButton As New InputTags.InputButton
        Private _disposed As Boolean

        Public Property DalUtility() As Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Database.DalBaseObjects.IUtility)
                _dalUtility = value
            End Set
        End Property

        Public Property VarianceForm() As Tags.HtmlFormTag
            Get
                Return _varianceForm
            End Get
            Set(ByVal value As Tags.HtmlFormTag)
                _varianceForm = value
            End Set
        End Property

        Public Property VarianceLayoutTable() As HtmlTableTag
            Get
                Return _varianceLayoutTable
            End Get
            Set(ByVal value As HtmlTableTag)
                _varianceLayoutTable = value
            End Set
        End Property

        Protected ReadOnly Property LayoutTable() As HtmlTableTag
            Get
                Return _layoutTable
            End Get
        End Property

        Protected Property InheritTable() As ReconcilorTable
            Get
                Return _inheritTable
            End Get
            Set(ByVal value As ReconcilorTable)
                _inheritTable = value
            End Set
        End Property

        Protected ReadOnly Property RemoveButton() As InputTags.InputButton
            Get
                Return _removeButton
            End Get
        End Property

        Protected ReadOnly Property ApplyButton() As InputTags.InputButton
            Get
                Return _applyButton
            End Get
        End Property
#End Region


#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If (Not _dalUtility Is Nothing) Then
                            _dalUtility.Dispose()
                            _dalUtility = Nothing
                        End If

                        If (Not _varianceForm Is Nothing) Then
                            _varianceForm.Dispose()
                            _varianceForm = Nothing
                        End If

                        If (Not _varianceLayoutTable Is Nothing) Then
                            _varianceLayoutTable.Dispose()
                            _varianceLayoutTable = Nothing
                        End If

                        If (Not _layoutTable Is Nothing) Then
                            _layoutTable.Dispose()
                            _layoutTable = Nothing
                        End If

                        If (Not _inheritTable Is Nothing) Then
                            _inheritTable.Dispose()
                            _inheritTable = Nothing
                        End If

                        If (Not _removeButton Is Nothing) Then
                            _removeButton.Dispose()
                            _removeButton = Nothing
                        End If

                        If (Not _applyButton Is Nothing) Then
                            _applyButton.Dispose()
                            _applyButton = Nothing
                        End If
                    End If

                    'Clean up unmanaged resources ie: Pointers & Handles
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region

        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("ANALYSIS_SPATIAL_VARIANCE_SETUP"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            _locationId = RequestAsInt32("LocationId")
        End Sub

        Protected Function GetColorList() As ArrayList
            Dim colour As Color
            Dim enumColour As New KnownColor
            Dim colours As Array = [Enum].GetValues(enumColour.GetType())
            Dim colourList As New ArrayList
            Dim clr As Object

            For Each clr In colours
                colour = Color.FromKnownColor(CType(clr, KnownColor))

                If (Not colour.IsSystemColor) And (colour <> Drawing.Color.Transparent) And (colour <> Drawing.Color.White) Then
                    colourList.Add(colour.ToString.Replace("Color [", "").Replace("]", ""))
                End If
            Next

            Return colourList
        End Function

        ' Get the Variance and Raduis url dictionary
        'Public Shared Function GetVarianceList() As Dictionary(Of String, String)
        '    Dim varianceList As New Dictionary(Of String, String)
        '    Dim radius As String

        '    ' Retrieve hard coded core values.
        '    For i = DigblockSpatialCommon.VarianceIndexA To DigblockSpatialCommon.VarianceIndexE
        '        Select Case i
        '            Case DigblockSpatialCommon.VarianceIndexA
        '                radius = DigblockSpatialCommon.CircleRenderUrl & DigblockSpatialCommon.VarianceRadiusA
        '            Case DigblockSpatialCommon.VarianceIndexB
        '                radius = DigblockSpatialCommon.CircleRenderUrl & DigblockSpatialCommon.VarianceRadiusB
        '            Case DigblockSpatialCommon.VarianceIndexC
        '                radius = DigblockSpatialCommon.CircleRenderUrl & DigblockSpatialCommon.VarianceRadiusC
        '            Case DigblockSpatialCommon.VarianceIndexD
        '                radius = DigblockSpatialCommon.CircleRenderUrl & DigblockSpatialCommon.VarianceRadiusD
        '            Case DigblockSpatialCommon.VarianceIndexE
        '                radius = DigblockSpatialCommon.CircleRenderUrl & DigblockSpatialCommon.VarianceRadiusE
        '            Case Else
        '                radius = ""
        '        End Select
        '        varianceList.Add(DigblockSpatialCommon.VarianceLetter(i), radius)
        '    Next

        '    Return varianceList
        'End Function

        ' Setup the Variance table
        'Protected Sub SetupVarianceTable()
        '    Dim circle As Tags.HtmlImageTag
        '    Dim input As ReconcilorControls.InputTags.InputText
        '    Dim colour As ReconcilorControls.InputTags.SelectBox
        '    Dim varianceData As DataTable = DalUtility.GetBhpbioAnalysisVarianceList(_locationId, _
        '        DoNotSetValues.Char, False, True)
        '    Dim variance As String
        '    Dim varianceList As Dictionary(Of String, String) = GetVarianceList()
        '    Dim colorList As ArrayList = GetColorList()
        '    Dim rows As DataRow()
        '    Dim percentageValue As String = ""
        '    Dim colorValue As String = ""

        '    ' Add header to the table
        '    With VarianceLayoutTable
        '        .AddCellInNewRow().Controls.Add(New LiteralControl("<b>Variance</b>"))
        '        .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
        '        .AddCell().Controls.Add(New LiteralControl("<b>Percentage</b>"))
        '        .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
        '        .AddCell().Controls.Add(New LiteralControl("<b>Circle</b>"))
        '        .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
        '        .AddCell().Controls.Add(New LiteralControl("<b>Colour</b>"))
        '        .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
        '        .AddCell().Controls.Add(New LiteralControl("<b>Preview</b>"))
        '    End With

        '    ' Add in the row per variance
        '    For Each variance In varianceList.Keys
        '        rows = varianceData.Select("VarianceType = '" & variance & "'")
        '        If rows.Length = 1 Then
        '            percentageValue = rows(0)("Percentage").ToString
        '            colorValue = rows(0)("Color").ToString
        '        Else
        '            percentageValue = ""
        '            colorValue = ""
        '        End If

        '        ' Setup controls
        '        circle = New Tags.HtmlImageTag
        '        circle.ID = "circle" & variance
        '        circle.Source = varianceList(variance)

        '        colour = New ReconcilorControls.InputTags.SelectBox
        '        With colour
        '            .ID = "color" & variance
        '            .DataSource = colorList
        '            .DataBind()
        '            .OnSelectChange = "PreviewVarianceColour(this);"
        '            .SelectedValue = colorValue
        '        End With

        '        input = New ReconcilorControls.InputTags.InputText
        '        With input
        '            .ID = "variance" & variance
        '            .Width = 50
        '            .Text = percentageValue
        '        End With

        '        With VarianceLayoutTable
        '            .AddCellInNewRow().Controls.Add(New LiteralControl(variance))
        '            .CurrentCell.HorizontalAlign = HorizontalAlign.Center
        '            .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
        '            .AddCell().Controls.Add(input)
        '            .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
        '            .AddCell().Controls.Add(circle)
        '            .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
        '            .AddCell().Controls.Add(colour)
        '            .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
        '            .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
        '            .CurrentCell.Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "PreviewVarianceColour(document.getElementById('color" & variance & "'));"))
        '            .CurrentCell.ID = "thatch" & variance
        '        End With
        '    Next
        'End Sub

        ' Setup the Inheritable Variance table
        Protected Sub SetupInheritedThresholdTable()
            Dim useColumns() As String
            Dim inheritedText As String
            Dim fieldNameWidth As Integer = 50
            Dim variance As DataTable = DalUtility.GetBhpbioAnalysisVarianceList(_locationId, _
              DoNotSetValues.Char, True, False)
            variance.Columns.Add("VarianceSetting", GetType(String), "'Variance ' + VarianceType + ': '" & _
             " + Percentage + '%, ' + Color + '.'")

            If variance.Rows.Count > 0 Then
                inheritedText = "Inherited from " & variance.Rows(0)("LocationName").ToString()
            Else
                inheritedText = "No inheritable variance"
            End If

            useColumns = ("VarianceType,VarianceSetting").Split(Convert.ToChar(","))

            ' Setup the Reconcilor Table
            InheritTable = New ReconcilorTable(variance, useColumns)
            With InheritTable
                .IsSortable = False
                .Columns.Add("VarianceType", New ReconcilorControls.ReconcilorTableColumn("Variance", fieldNameWidth))
                .Columns.Add("VarianceSetting", New ReconcilorControls.ReconcilorTableColumn(inheritedText))
                .Width = _groupBoxWidth
                .IsExpandable = False
                .IsSortable = False
                .CanExportCsv = False
                If variance.Rows.Count > 0 Then
                    .Height = 110
                Else
                    .Height = 0
                End If

                .DataBind()
            End With
        End Sub


        Protected Sub SetupPageControls()
            'SetupVarianceTable()
            SetupInheritedThresholdTable()

            VarianceForm.ID = "VarianceForm"

            With RemoveButton
                .Text = "Remove Variance Override"
                .ID = "removeVarianceOverrideButton"
                .OnClientClick = String.Format("return RemoveVarianceOverride({0});", _locationId)
                .Font.Size = 8
                .Width = 160
            End With

            With ApplyButton
                .Text = "Apply Variance Settings"
                .ID = "applyVarianceSettingsButton"
                .OnClientClick = String.Format("return ApplyVarianceSettings({0});", _locationId)
                .Font.Size = 8
                .Width = 160
            End With

            With LayoutTable
                .Width = _groupBoxWidth
                .AddCellInNewRow().Controls.Add(New LiteralControl("Location: " & GetAppendedLocationName()))
                .CurrentCell.VerticalAlign = VerticalAlign.Top
                .CurrentCell.ColumnSpan = 2
                .AddCellInNewRow().Controls.Add(New LiteralControl("<hr>"))
                .CurrentCell.ColumnSpan = 2
                .AddCellInNewRow().Controls.Add(VarianceLayoutTable)
                .CurrentCell.ColumnSpan = 2
                .AddCellInNewRow().Controls.Add(InheritTable)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Center
                .CurrentCell.ColumnSpan = 2
                .AddCellInNewRow().Controls.Add(RemoveButton)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                .AddCell().Controls.Add(ApplyButton)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Right
            End With
        End Sub

        Protected Sub SetupPageLayout()
            VarianceForm.Controls.Add(LayoutTable)

            With Controls
                .Add(VarianceForm)
            End With
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                SetupPageLayout()
                SetupPageControls()
            Catch ea As Threading.ThreadAbortException
                Return
            Catch ex As Exception
                JavaScriptAlert(ex.Message, "Error obtaining variance:\n")
            End Try
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalUtility Is Nothing Then
                DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If
        End Sub


        ' Retrieve the Location Name.
        Private Function GetAppendedLocationName() As String
            Dim locationRow As DataRow
            Dim locationTable As DataTable
            Dim locationName As String
            Dim parentLocationId As Int32

            locationRow = DalUtility.GetLocationList(1, DoNotSetValues.Int32, _locationId, DoNotSetValues.Int16).Rows(0)
            parentLocationId = DataHelper.IfDBNull(locationRow("Parent_Location_Id"), DoNotSetValues.Int32)
            locationName = locationRow("Name").ToString

            While Not parentLocationId = DoNotSetValues.Int32

                locationTable = DalUtility.GetLocationList(1, DoNotSetValues.Int32, parentLocationId, DoNotSetValues.Int16)
                If locationTable.Rows.Count > 0 Then
                    locationRow = locationTable.Rows(0)
                    locationName = locationRow("Name").ToString + ", " + locationName
                    parentLocationId = DataHelper.IfDBNull(locationRow("Parent_Location_Id"), DoNotSetValues.Int32)
                Else
                    parentLocationId = DoNotSetValues.Int32
                End If

            End While

            Return locationName.ToString
        End Function

    End Class
End Namespace
