Imports System.Data.SqlClient
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates

Namespace Utilities
    Public Class DefaultSampleStationDelete
        Inherits UtilitiesAjaxTemplate

        Protected Property DalUtility As IUtility
        Private _sampleStationId As Integer

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()
            If Request("SampleStationId") IsNot Nothing Then
                Integer.TryParse(Request("SampleStationId"), _sampleStationId)
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
                EventLogDescription = $"Deleting Sample Station record ID: {_sampleStationId }"

                DalUtility.DeleteBhpbioSampleStation(_sampleStationId)
                JavaScriptAlert("Sample Station deleted successfully.", String.Empty, "GetSampleStations();")
            Catch ex As SqlException
                JavaScriptAlert(String.Format("Error while deleting Sample Station: {0}", ex.Message))
            End Try
        End Sub
    End Class
End Namespace