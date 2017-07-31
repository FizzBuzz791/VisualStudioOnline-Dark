Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI.WebControls
Imports Snowden.Reconcilor.Core.WebDevelopment.Reports

Namespace Reports
    Public Class GetStockpilesByLocation
        Inherits WebpageTemplates.ReportsAjaxTemplate

#Region "Properties"

        Private _disposed As Boolean
        Private _stockpileId As String
        Private _locationId As Integer
        Private _isVisible As Boolean
        Private _dalStockpiles As Database.DalBaseObjects.IStockpile

        Public Property DalStockpile() As Database.DalBaseObjects.IStockpile
            Get
                Return _dalStockpiles
            End Get
            Set(ByVal value As Database.DalBaseObjects.IStockpile)
                _dalStockpiles = value
            End Set
        End Property


#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        DisposeObject(_dalStockpiles)
                        _dalStockpiles = Nothing

                    End If

                    'Clean up unmanaged resources ie: Pointers & Handles
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If (DalStockpile Is Nothing) Then
                DalStockpile = New Bhpbio.Database.SqlDal.SqlDalStockpile(Resources.Connection)
            End If

        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()
            _stockpileId = RequestAsString("StockpileId")
            _locationId = RequestAsInt32("LocationId")
            _isVisible = RequestAsBoolean("IsVisible")
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Dim dropdown As New ReconcilorControls.InputTags.SelectBoxFormless

            Dim stockpileListByLocation As DataTable = _
            DalStockpile.GetStockpileList(DoNotSetValues.Int16, DoNotSetValues.String, _
            DoNotSetValues.String, Convert.ToInt16(_isVisible), DoNotSetValues.Int32, DoNotSetValues.Int32, _
            DoNotSetValues.Int16, DoNotSetValues.DateTime, DoNotSetValues.DateTime, _locationId, _
            DoNotSetValues.Int32, DoNotSetValues.Int16, DoNotSetValues.DateTime, DoNotSetValues.DateTime)

            'Dim stockpileListByLocation As DataTable = DalStockpile.GetStockpileIdList(DoNotSetValues.Int32, DoNotSetValues.String, Convert.ToInt16(True))

            With dropdown

                .ID = _stockpileId
                .DataSource = stockpileListByLocation
                .DataTextField = "Stockpile_Name"
                .DataValueField = "Stockpile_Id"
                .DataBind()

                .Items.Insert(0, New ListItem("All", ""))

            End With
            Controls.Add(dropdown)

        End Sub
    End Class
End Namespace
