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
    Public Class CustomFieldsLocationColorsDetails
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate


#Region "Properties"

        Private _colorList As New ArrayList
        Private _colorTerm As String = ReconcilorFunctions.GetSiteTerminology("Color")

        Private _locationId As Int32
        Private _locationInput As New InputTags.InputHidden()

        Private _hiddenLocationId As New ReconcilorControls.InputTags.InputHidden
        Private _formAction As New ReconcilorControls.InputTags.InputHidden()

        Private _disposed As Boolean
        Private _dalUtility As IUtility
        Private _layoutTable As New Tags.HtmlTableTag()
        Private _layoutForm As New Tags.HtmlFormTag()
        Private _holdingTable As New Tags.HtmlTableTag

        Private _saveButton As New ReconcilorControls.InputTags.InputButtonFormless
        Private _colourPicker As New ReconcilorControls.InputTags.SelectBox
        Private _groupBoxWidth As Int32 = 350

        Protected Property ColourPicker() As ReconcilorControls.InputTags.SelectBox
            Get
                Return _colourPicker
            End Get
            Set(ByVal value As ReconcilorControls.InputTags.SelectBox)
                _colourPicker = value
            End Set
        End Property

        Protected Property SaveButton() As ReconcilorControls.InputTags.InputButtonFormless
            Get
                Return _saveButton
            End Get
            Set(ByVal value As ReconcilorControls.InputTags.InputButtonFormless)
                _saveButton = value
            End Set
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

        Protected ReadOnly Property LayoutForm() As Tags.HtmlFormTag
            Get
                Return _layoutForm
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

                        If (Not _layoutForm Is Nothing) Then
                            _layoutForm.Dispose()
                            _layoutForm = Nothing
                        End If
                    End If
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region


        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()
            LocationId = RequestAsInt32("LocationId")
            _hiddenLocationId.Value = LocationId.ToString
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            SetupPageColours()
            SetupPageControls()
            SetupPageLayout()
        End Sub

        Private Sub SetupPageColours()
            Dim enumColour As New System.Drawing.KnownColor
            Dim colours As Array = [Enum].GetValues(enumColour.GetType())
            Dim clr As Object

            'Colors
            Dim drawColour As System.Drawing.Color
            For Each clr In colours
                drawColour = System.Drawing.Color.FromKnownColor(CType(clr, System.Drawing.KnownColor))

                If (Not drawColour.IsSystemColor) And (drawColour <> Drawing.Color.Transparent) And (drawColour <> Drawing.Color.White) Then
                    _colorList.Add(drawColour.ToString.Replace("Color [", "").Replace("]", ""))
                End If
            Next

        End Sub

        Protected Sub SetupPageControls()
            Dim correctLocations As Integer

            correctLocations = (From n In DalUtility.GetLocation(LocationId) _
                                   Join a In DalUtility.GetLocationTypeList(NullValues.Int16) _
                                    On Convert.ToInt16(a("Location_Type_Id")) Equals _
                                        Convert.ToInt16(n("Location_Type_Id")) Where _
                                        New String() {"Site"}.Contains(a.Field(Of String)("Description"))).Count

            Dim savedLocationColorDataTable As DataTable = DalUtility.GetBhpbioReportColorList(LocationId.ToString(), True)
            Dim savedLocationColor As String = String.Empty

            If (Not savedLocationColorDataTable.Rows.Count = 0) Then
                savedLocationColor = savedLocationColorDataTable.Rows(0)("color").ToString()
            End If

            _colorList.Insert(0, String.Empty)
            With ColourPicker
                .ID = "colorSelectPicker"
                .DataSource = _colorList
                .DataBind()
                .OnSelectChange = "PreviewCustomFieldColour(this);"
                .SelectedValue = savedLocationColor
            End With

            With SaveButton
                .Text = "Save"
                .OnClientClick = "return SaveLocationsColor();"
            End With

            _hiddenLocationId.ID = "LocationId"
        End Sub

        Protected Sub SetupPageLayout()

            With LayoutTable

                .Width = _groupBoxWidth
                .AddCellInNewRow().Controls.Add(New LiteralControl("Location: " & GetAppendedLocationName()))
                .CurrentCell.VerticalAlign = VerticalAlign.Top
                .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                .AddCellInNewRow().Controls.Add(New LiteralControl("<hr>"))

                .AddCellInNewRow()
                .AddCell()
                .AddCell().Text = _colorTerm

                .AddCell().Controls.Add(ColourPicker)
                .CurrentCell.Width = 150

                'Create a new cell which will contain the colour that is picked
                .AddCell().ID = "colorSelectPickerThatch"
                .CurrentCell.Width = WebControls.Unit.Pixel(35)
                .CurrentCell.Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "PreviewCustomFieldColour(document.getElementById('colorSelectPicker'));;"))
                .AddCell()
                .CurrentCell.Width = 100

                .AddCell().Controls.Add(SaveButton)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Right

            End With

            With LayoutForm
                .Controls.Add(LayoutTable)
                .ID = "LocationColorCustomFields"
                .Action = String.Empty
                .Controls.Add(_hiddenLocationId)
            End With

            Controls.Add(LayoutForm)
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
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

