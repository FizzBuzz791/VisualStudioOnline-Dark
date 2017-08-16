Imports System.Data.SqlClient
Imports System.Text
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates

Namespace Utilities
    Public Class DefaultSampleStationTargetSave
        Inherits UtilitiesAjaxTemplate

        Private Property DalUtility As IUtility

        Private Property SampleStationId As Integer
        Private Property TargetId As Integer?
        Private Property StartDate As DateTime
        Private Property CoverageTarget As Integer
        Private Property CoverageWarning As Integer
        Private Property RatioTarget As Integer
        Private Property RatioWarning As Integer

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            SampleStationId = RequestAsInt32("SampleStationId")
            TargetId = RequestAsInt32("TargetId")
            If TargetId = Integer.MinValue Then
                TargetId = Nothing
            End If
            StartDate = RequestAsDateTime("MonthValueMonthFrom")
            CoverageTarget = RequestAsInt32("CoverageTarget")
            CoverageWarning = RequestAsInt32("CoverageWarning")
            RatioTarget = RequestAsInt32("RatioTarget")
            RatioWarning = RequestAsInt32("RatioWarning")
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalUtility Is Nothing Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub

        Protected Overrides Function ValidateData() As String
            Dim validationResult = New StringBuilder()
            validationResult.Append(MyBase.ValidateData())

            If SampleStationId = Integer.MinValue Then
                validationResult.AppendLine(" - Must create Sample Station before adding Target(s).")
            End If

            If CoverageTarget = Integer.MinValue Then
                validationResult.AppendLine(" - Coverage Target must be specified.")
            End If

            If CoverageWarning = Integer.MinValue Then
                validationResult.AppendLine(" - Coverage Warning must be specified.")
            End If

            If CoverageTarget <> Integer.MinValue And CoverageWarning <> Integer.MinValue And CoverageTarget <= CoverageWarning Then
                validationResult.AppendLine(" - Coverage Target must be greater than Coverage Warning")
            End If

            If RatioTarget = Integer.MinValue Then
                validationResult.AppendLine(" - Ratio Target must be specified.")
            End If

            If RatioWarning = Integer.MinValue Then
                validationResult.AppendLine(" - Ratio Warning must be specified.")
            End If

            If RatioTarget <> Integer.MinValue And RatioWarning <> Integer.MinValue And RatioTarget >= RatioWarning Then
                validationResult.AppendLine(" - Ratio Target must be less than Ratio Warning")
            End If

            Return validationResult.ToString()
        End Function

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                Dim errorMessage = ValidateData()
                If String.IsNullOrEmpty(errorMessage) Then
                    If TargetId <> Integer.MinValue Then
                        EventLogDescription = String.Format($"Save update to Sample Station Target record ID: {TargetId}")
                    Else
                        EventLogDescription = "Save new Sample Station Target"
                    End If

                    ProcessData()
                    ' TODO: Is EditSampleStation the correct call? Does the list need to be stripped out like Sample Station List?
                    JavaScriptAlert("Sample Station Target saved successfully.", String.Empty, String.Format($"EditSampleStation({SampleStationId})"))
                Else
                    JavaScriptAlert(errorMessage, "Please fix the following issue(s):")
                End If
            Catch ex As SqlException
                JavaScriptAlert(String.Format($"Error while saving Sample Station Target: {ex.Message}"))
            End Try
        End Sub

        Protected Overrides Sub ProcessData()
            MyBase.ProcessData()

            DalUtility.DataAccess.BeginTransaction()

            Try
                Dim convertedCoverageTarget = CType(CoverageTarget, Decimal) / 100 ' Convert it so that it's easier for stored procs to work with (reports)
                Dim convertedCoverageWarning = CType(CoverageWarning, Decimal) / 100 ' Convert it so that it's easier for stored procs to work with (reports)

                DalUtility.AddOrUpdateBhpbioSampleStationTarget(TargetId, SampleStationId, StartDate, convertedCoverageTarget, convertedCoverageWarning, RatioTarget, RatioWarning)
                DalUtility.DataAccess.CommitTransaction()
            Catch ex As Exception
                Try
                    DalUtility.DataAccess.RollbackTransaction()
                Catch
                    Throw
                End Try
            End Try
        End Sub
    End Class
End Namespace