Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports System.Data.SqlClient

Namespace Utilities
    Public Class DefaultDepositDelete
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _depositId As Integer

        Protected Property DalUtility As Database.DalBaseObjects.IUtility

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()
            If Not Request("BhpbioDefaultDepositId") Is Nothing Then
                Integer.TryParse(Request("BhpbioDefaultDepositId"), _depositId)
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                EventLogDescription = String.Format("Deleting Deposit record ID: {0}", _depositId)

                DalUtility.DeleteDeposit(_depositId)
                JavaScriptAlert("Deposit deleted successfully.", String.Empty, "GetDepositsForSite();")
            Catch ex As SqlException
                JavaScriptAlert(String.Format("Error while deleting Deposit: {0}", ex.Message))
            End Try
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalUtility Is Nothing Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub
    End Class
End Namespace