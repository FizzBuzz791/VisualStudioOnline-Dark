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
    Public Class CustomFieldsStockpileDetails
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

#Region "Properties"
        Private _locationId As Int32
        Private _locationInput As New InputTags.InputHidden()
        Private _dalUtility As IUtility
        Private _layoutTable As New Tags.HtmlTableTag()
        Private _layoutForm As New Tags.HtmlFormTag()
        Private _disposed As Boolean
        Private _groupBoxWidth As Int32 = 350
        Private _saveButton As New InputTags.InputButtonFormless
        Private _removeButton As New InputTags.InputButtonFormless
        Private _imageUpload As New ReconcilorControls.InputTags.InputFile
        Private _promoteCheckbox As New ReconcilorControls.InputTags.InputCheckBox
        Private _hiddenLocationId As New ReconcilorControls.InputTags.InputHidden
        Private _formAction As New ReconcilorControls.InputTags.InputHidden()
        Private _span As New Tags.HtmlSpanTag
        Private _holdingTable As New Tags.HtmlTableTag

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


                        If (Not _saveButton Is Nothing) Then
                            _saveButton.Dispose()
                            _saveButton = Nothing
                        End If

                        If (Not _removeButton Is Nothing) Then
                            _removeButton.Dispose()
                            _removeButton = Nothing
                        End If

                        If (Not _imageUpload Is Nothing) Then
                            _imageUpload.Dispose()
                            _imageUpload = Nothing
                        End If

                        If (Not _promoteCheckbox Is Nothing) Then
                            _promoteCheckbox.Dispose()
                            _promoteCheckbox = Nothing
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

            Dim stockpileData As DataTable = Nothing
            Dim correctLocations As Integer

            Try

                correctLocations = (From n In DalUtility.GetLocation(LocationId) _
                                       Join a In DalUtility.GetLocationTypeList(NullValues.Int16) _
                                        On Convert.ToInt16(a("Location_Type_Id")) Equals _
                                            Convert.ToInt16(n("Location_Type_Id")) Where _
                                            New String() {"Site"}.Contains(a.Field(Of String)("Description"))).Count

                With LayoutTable
                    .Width = _groupBoxWidth
                    .AddCellInNewRow().Controls.Add(New LiteralControl("Location: " & GetAppendedLocationName()))
                    .CurrentCell.VerticalAlign = VerticalAlign.Top
                    .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                    .AddCellInNewRow().Controls.Add(New LiteralControl("<hr>"))

                    If correctLocations > 0 Then

                        _imageUpload.ID = "ImgStockpileImageLocation"
                        _promoteCheckbox.ID = "PromoteStockpile"
                        _hiddenLocationId.ID = "LocationId"
                        _formAction.ID = "SaveOrDeleteAction"

                        'Disable the image textbox controls, to stop random entry.
                        _imageUpload.Attributes.Add("onkeydown", "return (event.keyCode==9);")
                        _imageUpload.Attributes.Add("onpaste", "return false;")

                        stockpileData = DalUtility.GetBhpbioStockpileLocationConfiguration(LocationId)

                        If stockpileData.Rows.Count > 0 Then
                            _promoteCheckbox.Checked = Convert.ToBoolean(stockpileData.Rows(0)("PromoteStockpiles"))
                        End If

                        ' Requires Threshold Table

                        .AddCellInNewRow()
                        With .CurrentCell
                            .Controls.Add(_promoteCheckbox)
                            .Controls.Add(New LiteralControl("&nbsp;&nbsp;Promote Stockpiles to Hub for Post Crusher Delta Calculations"))
                        End With
                        .AddCellInNewRow()

                        '----IMAGE VIEW CODE ---
                        '.AddCellInNewRow()
                        'With .CurrentCell
                        '    .Controls.Add(New LiteralControl("Location Image:&nbsp;&nbsp;"))
                        '    .Controls.Add(_imageUpload)
                        'End With
                        '.AddCellInNewRow()
                        'With _holdingTable
                        '    .AddCellInNewRow()
                        '    With .CurrentCell
                        '        .Controls.Add(New LiteralControl("Current Image:&nbsp;&nbsp;"))
                        '        .VerticalAlign = VerticalAlign.Top
                        '    End With
                        '    .AddCell().Controls.Add(New Tags.HtmlDivTag("stockpileImageContent"))
                        '    .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                        'End With
                        '_span.Controls.Add(_holdingTable)
                        '.CurrentCell.Controls.Add(_span)

                        .AddCellInNewRow().Controls.Add(New Tags.HtmlDivTag(String.Empty, String.Empty, "tabs_spacer"))
                        .AddCellInNewRow().Controls.Add(New Tags.HtmlDivTag(String.Empty, String.Empty, "tabs_spacer"))

                        '----IMAGE VIEW CODE---
                        '.AddCellInNewRow().Controls.Add(_removeButton)
                        '.CurrentCell.Controls.Add(New LiteralControl("&nbsp;&nbsp;"))

                        .CurrentCell.Controls.Add(_saveButton)
                        .CurrentCell.Controls.Add(_hiddenLocationId)
                        .CurrentCell.Controls.Add(_formAction)
                        .CurrentCell.VerticalAlign = VerticalAlign.Bottom
                        .CurrentCell.HorizontalAlign = HorizontalAlign.Right

                        With _saveButton
                            .Text = "Save"
                            .ID = "Save"
                            .OnClientClick = "return SaveStockpileImageLocation();"
                        End With


                        With _removeButton
                            .Text = " Remove Image "
                            .ID = "Remove"
                            .OnClientClick = "return DeleteStockpileImageLocation();"

                        End With


                        Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, _
                                                            "", "LoadStockpileImage();"))

                    Else

                        .AddCellInNewRow()
                        With .CurrentCell
                            .Controls.Add(New LiteralControl("Please select a site location..."))
                        End With

                    End If

                End With


            Finally
                If Not stockpileData Is Nothing Then
                    stockpileData.Dispose()
                    stockpileData = Nothing
                End If
            End Try


        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()
            LocationId = RequestAsInt32("LocationId")
            _hiddenLocationId.Value = LocationId.ToString
        End Sub

        Protected Sub SetupPageLayout()


            LayoutForm.Controls.Add(LayoutTable)
            LayoutForm.ID = "stockpileCustomFields"
            LayoutForm.Action = String.Empty
            Controls.Add(LayoutForm)
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

