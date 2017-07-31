Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Database.DataHelper
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace Utilities
    Public Class CustomFieldsLocationsDetails
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

#Region "Properties"
        Private _locationId As Int32
        Private _thresholdFactor As String
        Private _locationInput As New InputTags.InputHidden()
        Private _dalUtility As IUtility
        Private _layoutTable As New Tags.HtmlTableTag()
        Private _valuesTable As New Tags.HtmlTableTag()
        Private _layoutForm As New Tags.HtmlFormTag()
        Private _thresholdFactorDropDown As New InputTags.SelectBox()
        Private _disposed As Boolean
        Private _groupBoxWidth As Int32 = 380
        Private _inheritTable As ReconcilorTable
        Private _removeThresholdButton As New InputTags.InputButton
        Private _applyThresholdButton As New InputTags.InputButton

        Public Shared ReadOnly Property SingleValueThresholds() As ICollection(Of String)
            Get
                Dim singleValThresholds As New Generic.List(Of String)
                singleValThresholds.Add("graphthreshold")
                Return singleValThresholds
            End Get
        End Property


        Protected Property DalUtility() As IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As IUtility)
                _dalUtility = value
            End Set
        End Property

        Protected ReadOnly Property LayoutTable() As Tags.HtmlTableTag
            Get
                Return _layoutTable
            End Get
        End Property

        Protected ReadOnly Property LocationInput() As InputTags.InputHidden
            Get
                Return _locationInput
            End Get
        End Property

        Protected Property LocationId() As Int32
            Get
                Return _locationId
            End Get
            Set(ByVal value As Int32)
                _locationId = value
            End Set
        End Property

        Protected Property ThresholdFactor() As String
            Get
                Return _thresholdFactor
            End Get
            Set(ByVal value As String)
                _thresholdFactor = value
            End Set
        End Property

        Protected ReadOnly Property LayoutForm() As Tags.HtmlFormTag
            Get
                Return _layoutForm
            End Get
        End Property

        Protected ReadOnly Property ThresholdFactorDropDown() As InputTags.SelectBox
            Get
                Return _thresholdFactorDropDown
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

        Protected ReadOnly Property ValuesTable() As Tags.HtmlTableTag
            Get
                Return _valuesTable
            End Get
        End Property

        Protected ReadOnly Property RemoveThresholdButton() As InputTags.InputButton
            Get
                Return _removeThresholdButton
            End Get
        End Property

        Protected ReadOnly Property ApplyThresholdButton() As InputTags.InputButton
            Get
                Return _applyThresholdButton
            End Get
        End Property
#End Region

#Region "Destructors"
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        'Clean up managed Resources ie: Objects

                        If (Not _dalUtility Is Nothing) Then
                            _dalUtility.Dispose()
                            _dalUtility = Nothing
                        End If

                        If (Not _locationInput Is Nothing) Then
                            _locationInput.Dispose()
                            _locationInput = Nothing
                        End If

                        If (Not _layoutTable Is Nothing) Then
                            _layoutTable.Dispose()
                            _layoutTable = Nothing
                        End If

                        If (Not _valuesTable Is Nothing) Then
                            _valuesTable.Dispose()
                            _valuesTable = Nothing
                        End If

                        If (Not _layoutForm Is Nothing) Then
                            _layoutForm.Dispose()
                            _layoutForm = Nothing
                        End If

                        If (Not _thresholdFactorDropDown Is Nothing) Then
                            _thresholdFactorDropDown.Dispose()
                            _thresholdFactorDropDown = Nothing
                        End If

                        If (Not _thresholdFactorDropDown Is Nothing) Then
                            _thresholdFactorDropDown.Dispose()
                            _thresholdFactorDropDown = Nothing
                        End If

                        If (Not _inheritTable Is Nothing) Then
                            _inheritTable.Dispose()
                            _inheritTable = Nothing
                        End If

                        If (Not _removeThresholdButton Is Nothing) Then
                            _removeThresholdButton.Dispose()
                            _removeThresholdButton = Nothing
                        End If

                        If (Not _applyThresholdButton Is Nothing) Then
                            _applyThresholdButton.Dispose()
                            _applyThresholdButton = Nothing
                        End If
                    End If
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region

        Protected Sub SetupPageControls()
            Dim thresholdType As DataTable = DalUtility.GetBhpbioReportThresholdTypeList()

            ' Default the Threshold factor if it was not provided.
            If ThresholdFactor = "" AndAlso thresholdType.Rows().Count > 1 Then
                ThresholdFactor = thresholdType.Rows(0).Item(0).ToString()
            End If

            LayoutForm.ID = "ThresholdForm"

            With ThresholdFactorDropDown
                .ID = "thresholdFactorSelect"
                .DataSource = thresholdType
                .DataTextField = "Description"
                .DataValueField = "ThresholdTypeId"
                .DataBind()
                .SelectedValue = ThresholdFactor
                .OnSelectChange = "LoadLocationsDetails(" & LocationId & ");"
            End With

            SetupInheritedThresholdTable()
            SetupValuesTable()

            ' Requires Threshold Table
            With LayoutTable
                .Width = _groupBoxWidth
                .AddCellInNewRow().Controls.Add(New LiteralControl("Location: " & GetAppendedLocationName()))
                .AddCell().Controls.Add(New LiteralControl("Threshold:"))
                .CurrentCell.Controls.Add(ThresholdFactorDropDown)
                .CurrentCell.VerticalAlign = VerticalAlign.Top
                .CurrentCell.HorizontalAlign = HorizontalAlign.Right
                .AddCellInNewRow().Controls.Add(New LiteralControl("<hr>"))
                .CurrentCell.ColumnSpan = 2
                .AddCellInNewRow().Controls.Add(ValuesTable)
                .CurrentCell.ColumnSpan = 2
                .AddCellInNewRow().Controls.Add(InheritTable)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Center
                .CurrentCell.ColumnSpan = 2
                .AddCellInNewRow().Controls.Add(RemoveThresholdButton)
                .AddCell().Controls.Add(ApplyThresholdButton)
            End With

            With RemoveThresholdButton
                .Text = "Remove Threshold Override"
                .ID = "removeThresholdOverrideButton"
                .OnClientClick = String.Format("return RemoveThresholdOverride({0},'{1}');", LocationId, ThresholdFactor)
                .Font.Size = 8
                .Width = 160
            End With

            With ApplyThresholdButton
                .Text = "Apply Threshold Settings"
                .ID = "applyThresholdSettingsButton"
                .OnClientClick = String.Format("return ApplyThresholdSettings({0},'{1}');", LocationId, ThresholdFactor)
                .Font.Size = 8
                .Width = 160
            End With

        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            ThresholdFactor = RequestAsString("ThresholdFactor")
            LocationId = RequestAsInt32("LocationId")
        End Sub

        Protected Sub SetupPageLayout()
            LayoutForm.Controls.Add(LayoutTable)

            Controls.Add(LayoutForm)
        End Sub

        Protected Sub SetupValuesTable()
            Dim row As DataRow
            Dim gradeId As String
            Dim gradeName As String
            Dim inputLow As InputTags.InputText = Nothing
            Dim inputHigh As InputTags.InputText = Nothing
            Dim inputDifference As InputTags.InputCheckBox = Nothing
            Dim thresholds As DataTable = DalUtility.GetBhpbioReportThresholdList(LocationId, _
             ThresholdFactor, False, True)



            ' Cycle through each row and add the fields.
            With ValuesTable
                For Each row In thresholds.Rows
                    gradeId = row("FieldId").ToString
                    gradeName = row("FieldName").ToString
                    inputLow = New InputTags.InputText()
                    With inputLow
                        .ID = "Threshold_" & gradeId & "_Low"
                        'Ensure graph threshold factors are displayed properly as a "10%"
                        If SingleValueThresholds.Contains(ThresholdFactor.ToLower) Then
                            If Not row("LowThreshold") Is DBNull.Value Then
                                .Text = (100 - DirectCast(row("LowThreshold"), Double) * 100).ToString
                            End If
                        Else
                            .Text = row("LowThreshold").ToString
                        End If
                        .Width = 30
                        .MaxLength = 5
                    End With

                    If Not SingleValueThresholds.Contains(ThresholdFactor.ToLower) Then
                        inputHigh = New InputTags.InputText()
                        With inputHigh
                            .ID = "Threshold_" & gradeId & "_High"
                            .Text = row("HighThreshold").ToString
                            .Width = 30
                            .MaxLength = 5
                        End With
                        inputDifference = New InputTags.InputCheckBox()
                        With inputDifference
                            .ID = "Threshold_" & gradeId & "_Absolute"
                            If Not Boolean.TryParse(row("AbsoluteThreshold").ToString(), .Checked) Then
                                .Checked = False
                            End If
                            .Text = "Absolute Diff"
                            .ToolTip = "When checked, this threshold is based on the attributes absolute difference as opposed to factor percentage."
                        End With
                    End If


                    .AddCellInNewRow().Controls.Add(New LiteralControl(gradeName & ":"))
                    .CurrentCell.Width = 50

                    If Not SingleValueThresholds.Contains(ThresholdFactor.ToLower) Then
                        .AddCell().Controls.Add(New LiteralControl("Low < "))
                        .AddCell().Controls.Add(inputLow)
                        .AddCell().Controls.Add(New LiteralControl("<= Medium < "))
                        .AddCell().Controls.Add(inputHigh)
                        .AddCell().Controls.Add(New LiteralControl("<= High."))
                    Else
                        .AddCell().Controls.Add(inputLow)
                    End If
                    If Not inputDifference Is Nothing Then
                        .AddCell().Controls.Add(inputDifference)
                    End If
                Next
            End With
        End Sub


        Protected Sub SetupInheritedThresholdTable()
            Dim useColumns() As String
            Dim inheritedText As String
            Dim fieldNameWidth As Integer = 50
            Dim thresholds As DataTable = DalUtility.GetBhpbioReportThresholdList(LocationId, ThresholdFactor, True, False)
            Dim absolute As Boolean
            Dim absoluteString As String

            thresholds.Columns.Add("Threshold", GetType(String), "")

            For Each row As DataRow In thresholds.Rows
                absoluteString = ""
                If Boolean.TryParse(row("AbsoluteThreshold").ToString(), absolute) Then
                    If Not absolute Then
                        absoluteString = "%"
                    End If
                End If
                'If this is a GraphThreshold.
                If SingleValueThresholds.Contains(ThresholdFactor.ToLower) Then
                    If Not row("LowThreshold") Is DBNull.Value Then
                        row("Threshold") = (100 - DirectCast(row("LowThreshold"), Double) * 100).ToString & "%"
                    Else
                        row("Threshold") = ""
                    End If
                Else
                    row("Threshold") = String.Format("Low < {0}{2} <= Medium < {1}{2} <= High", _
               row("LowThreshold").ToString(), row("HighThreshold").ToString(), absoluteString)
                End If

            Next

            If thresholds.Rows.Count > 0 Then
                inheritedText = "Inherited from " & thresholds.Rows(0)("LocationName").ToString()
            Else
                inheritedText = "No inheritable thresholds"
            End If

            useColumns = ("FieldName,Threshold").Split(Convert.ToChar(","))

            ' Setup the Reconcilor Table
            InheritTable = New ReconcilorTable(thresholds, useColumns)
            With InheritTable
                .IsSortable = False
                .Columns.Add("FieldName", New ReconcilorControls.ReconcilorTableColumn("Field", fieldNameWidth))
                .Columns.Add("Threshold", New ReconcilorControls.ReconcilorTableColumn(inheritedText))
                .Width = _groupBoxWidth
                .IsExpandable = False
                .IsSortable = False
                .CanExportCsv = False
                If thresholds.Rows.Count > 0 Then
                    .Height = 110
                Else
                    .Height = 0
                End If

                .DataBind()
            End With

        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            SetupPageControls()
            SetupPageLayout()
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalUtility Is Nothing Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub

        ' Retrieve the Location Name.
        Private Function GetAppendedLocationName() As String
            Dim locationRow As DataRow
            Dim locationTable As DataTable
            Dim locationName As String
            Dim parentLocationId As Int32

            locationRow = DalUtility.GetLocationList(1, DoNotSetValues.Int32, _locationId, DoNotSetValues.Int16).Rows(0)
            parentLocationId = IfDBNull(locationRow("Parent_Location_Id"), DoNotSetValues.Int32)
            locationName = locationRow("Name").ToString

            While Not parentLocationId = DoNotSetValues.Int32

                locationTable = DalUtility.GetLocationList(1, DoNotSetValues.Int32, parentLocationId, DoNotSetValues.Int16)
                If locationTable.Rows.Count > 0 Then
                    locationRow = locationTable.Rows(0)
                    locationName = locationRow("Name").ToString + ", " + locationName
                    parentLocationId = IfDBNull(locationRow("Parent_Location_Id"), DoNotSetValues.Int32)
                Else
                    parentLocationId = DoNotSetValues.Int32
                End If

            End While

            Return locationName.ToString
        End Function

    End Class
End Namespace

