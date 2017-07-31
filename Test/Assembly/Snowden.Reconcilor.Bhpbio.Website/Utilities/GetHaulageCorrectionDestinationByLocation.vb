Imports System.Web.UI.WebControls
Imports Snowden.Reconcilor.Core.WebDevelopment

Namespace Utilities
    Public Class GetHaulageCorrectionDestinationByLocation
        Inherits WebpageTemplates.UtilitiesAjaxTemplate

#Region "Properties"
        Private _disposed As Boolean
        Private _locationId As Integer
        Private _dalHaulage As Database.DalBaseObjects.IHaulage
        Private _domainUserName As String

        Public Property DalHaulage() As Database.DalBaseObjects.IHaulage
            Get
                Return _dalHaulage
            End Get
            Set(ByVal value As Database.DalBaseObjects.IHaulage)
                _dalHaulage = value
            End Set
        End Property

#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        DisposeObject(_dalHaulage)
                        _dalHaulage = Nothing
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

            If (DalHaulage Is Nothing) Then
                DalHaulage = New Bhpbio.Database.SqlDal.SqlDalHaulage(Resources.Connection)
            End If
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()
            _locationId = RequestAsInt32("LocationId")
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Dim dropdown As New ReconcilorControls.InputTags.SelectBoxFormless

            With dropdown

                .ID = "Destination"

                If .DataSource Is Nothing Then
                    .DataSource = DalHaulage.GetBhpbioHaulageCorrectionListFilter("Destination", _locationId)
                End If
                .DataTextField = "Filter"
                .DataValueField = "Filter"
                .DataBind()

                .Items.Insert(0, New ListItem("All", ""))

            End With

            Controls.Add(dropdown)

        End Sub

    End Class
End Namespace

