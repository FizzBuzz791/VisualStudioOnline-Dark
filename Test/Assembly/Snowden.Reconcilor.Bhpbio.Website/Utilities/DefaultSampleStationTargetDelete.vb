Imports System.Data.SqlClient
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates

Namespace Utilities
    Public Class DefaultSampleStationTargetDelete
        Inherits UtilitiesAjaxTemplate

        Private Property DalUtility As IUtility
        Private Property TargetId As Integer

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If Request("TargetId") IsNot Nothing Then
                Integer.TryParse(Request("TargetId"), TargetId)
            End If
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalUtility Is Nothing Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                EventLogDescription = $"Delete Sample Station Target record ID: {TargetId}"

                DalUtility.DeleteBhpbioSampleStationTarget(TargetId)
                JavaScriptAlert("Sample Station Target deleted successfully.", String.Empty, "GetSampleStations();")
            Catch ex As SqlException
                JavaScriptAlert($"Error while deleting Sample Station Target: {ex.Message}")
            End Try
        End Sub
    End Class
End Namespace