Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports System.Data.SqlClient

Namespace Utilities
    Public Class DefaultProductTypeDelete
        Inherits Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _bhpbioDefaultProductTypeId As Integer = 0
        Private _dalUtility As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility

        Protected Property BhpbioDefaultProductTypeId() As Integer
            Get
                Return _bhpbioDefaultProductTypeId
            End Get
            Set(ByVal value As Integer)
                _bhpbioDefaultProductTypeId = value
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

            If Not Request("ProductTypeId") Is Nothing Then
                Integer.TryParse(Request("ProductTypeId"), BhpbioDefaultProductTypeId)
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                EventLogDescription = String.Format("Deleting Product Type record ID: {0}", BhpbioDefaultProductTypeId)

                DalUtility.DeleteBhpbioProductTypeRecord(BhpbioDefaultProductTypeId)
                JavaScriptAlert("Product Type deleted successfully.", String.Empty, "GetDefaultProductTypeList();")
            Catch ex As SqlException
                JavaScriptAlert(String.Format("Error while deleting Product Type: {0}", ex.Message))
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
