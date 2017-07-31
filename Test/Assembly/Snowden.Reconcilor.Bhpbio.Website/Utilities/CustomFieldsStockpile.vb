Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Database
Imports System.Web.UI

Namespace Utilities
    Public Class CustomFieldsStockpile
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

#Region " Properties "
        Private _disposed As Boolean
        Private _dalUtility As Bhpbio.Database.DalBaseObjects.IUtility
        Private _locationBox As New GroupBox("Location Selection")
        Private _stockpilesBox As New GroupBox("Stockpiles")
        Private _locationsTreeDiv As New Tags.HtmlDivTag("locationsStockpileTree")
        Private _locationsDetailsDiv As New Tags.HtmlDivTag("stockpileDetails")
        Private _layoutTable As New Tags.HtmlTableTag()
        Private _locationPicker As New Bhpbio.WebDevelopment.ReconcilorControls.Inputs.LocationPicker("LocationPicker2")

        Protected ReadOnly Property LocationPicker() As Bhpbio.WebDevelopment.ReconcilorControls.Inputs.LocationPicker
            Get
                Return _locationPicker
            End Get
        End Property

        Protected Property DalUtility() As DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As DalBaseObjects.IUtility)
                _dalUtility = value
            End Set
        End Property

        Protected ReadOnly Property LocationBox() As GroupBox
            Get
                Return _locationBox
            End Get
        End Property

        Protected ReadOnly Property StockpilesBox() As GroupBox
            Get
                Return _stockpilesBox
            End Get
        End Property

        Protected ReadOnly Property LocationsTreeDiv() As Tags.HtmlDivTag
            Get
                Return _locationsTreeDiv
            End Get
        End Property


        Protected ReadOnly Property LocationsDetailsDiv() As Tags.HtmlDivTag
            Get
                Return _locationsDetailsDiv
            End Get
        End Property

        Protected ReadOnly Property LayoutTable() As Tags.HtmlTableTag
            Get
                Return _layoutTable
            End Get
        End Property
#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If (Not DalUtility Is Nothing) Then
                            _dalUtility.Dispose()
                            _dalUtility = Nothing
                        End If

                        If (Not LocationBox Is Nothing) Then
                            _locationBox.Dispose()
                            _locationBox = Nothing
                        End If

                        If (Not LocationsTreeDiv Is Nothing) Then
                            _locationsTreeDiv.Dispose()
                            _locationsTreeDiv = Nothing
                        End If

                        If (Not LocationsDetailsDiv Is Nothing) Then
                            _locationsDetailsDiv.Dispose()
                            _locationsDetailsDiv = Nothing
                        End If

                        If (Not LayoutTable Is Nothing) Then
                            _layoutTable.Dispose()
                            _layoutTable = Nothing
                        End If
                    End If

                End If

                'Clean up unmanaged resources ie: Pointers & Handles
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

        Protected Sub SetupPageControls()

            LocationBox.Width = 240
            StockpilesBox.Width = 380

            With LayoutTable
                .CellSpacing = 2
                .CellPadding = 2
                .AddCellInNewRow()
                .CurrentCell.Controls.Add(LocationBox)
                .CurrentCell.VerticalAlign = Web.UI.WebControls.VerticalAlign.Top
                .AddCell().Controls.Add(StockpilesBox)
                .CurrentCell.VerticalAlign = Web.UI.WebControls.VerticalAlign.Top
            End With

            With LocationsDetailsDiv
                .Controls.Add(New LiteralControl("Select a location to view the associated image."))
            End With

            With LocationPicker
                .LowestLocationTypeDescription = "SITE"
                .ID = "LocationPickerTree"
                .PopupTable = False
                .LocationJavaScript = "LoadLocationsStockpileDetails"
                .Width = 180
                .ShowLocationTypes = False
            End With
        End Sub

        Protected Sub SetupPageLayout()
            LocationBox.Controls.Add(LocationPicker)

            StockpilesBox.Controls.Add(LocationsDetailsDiv)
            'ToDo: Change this to load the first node

            Controls.Add(LayoutTable)
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            SetupPageControls()
            SetupPageLayout()
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If Not DalUtility Is Nothing Then
                DalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

    End Class
End Namespace