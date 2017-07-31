Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports System.Data.SqlClient

Namespace Utilities
    Public Class DefaultLumpFinesDelete
        Inherits Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _bhpbioDefaultLumpFinesId As Integer = 0
        Private _dalUtility As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility

        Protected Property BhpbioDefaultLumpFinesId() As Integer
            Get
                Return _bhpbioDefaultLumpFinesId
            End Get
            Set(ByVal value As Integer)
                _bhpbioDefaultLumpFinesId = value
            End Set
        End Property

        Protected Property DalUtility() As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility)
                _dalUtility = value
            End Set
        End Property

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If Not Request("BhpbioDefaultLumpFinesId") Is Nothing Then
                Integer.TryParse(Request("BhpbioDefaultLumpFinesId"), BhpbioDefaultLumpFinesId)
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                EventLogDescription = String.Format("Deleting Lump Percentage record ID: {0}", BhpbioDefaultLumpFinesId)

                DalUtility.DeleteBhpbioLumpFinesRecord(BhpbioDefaultLumpFinesId)
                JavaScriptAlert("Lump Percentage deleted successfully.", String.Empty, "GetDefaultLumpFinesList();")
            Catch ex As SqlException
                JavaScriptAlert(String.Format("Error while deleting Lump Percentage: {0}", ex.Message))
            End Try
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If _dalUtility Is Nothing Then
                _dalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub

    End Class
End Namespace
