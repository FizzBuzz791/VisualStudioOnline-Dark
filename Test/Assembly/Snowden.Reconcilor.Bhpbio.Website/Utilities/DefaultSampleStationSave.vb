Imports System.Data.SqlClient
Imports System.Text
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates

Namespace Utilities
    Public Class DefaultSampleStationSave
        Inherits UtilitiesAjaxTemplate

        Private Property DalUtility As IUtility

        Private Property SampleStationId As Int32?
        Private Property Name As String
        Private Property Description As String
        Private Property LocationId As Int32
        Private Property LocationType As String ' Purely for validation
        Private Property WeightometerId As String
        Private Property ProductSize As String

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalUtility Is Nothing Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            SampleStationId = RequestAsInt32("SampleStationId")

            Name = RequestAsString("Name")
            Description = RequestAsString("Description")
            LocationId = RequestAsInt32("SampleStationLocationId")
            LocationType = RequestAsString("SampleStationLocationIDTypeDescription")

            ProductSize = RequestAsString("LumpOption")
            If String.IsNullOrEmpty(ProductSize) Then
                ProductSize = RequestAsString("FinesOption")
            End If
            If String.IsNullOrEmpty(ProductSize) Then
                ProductSize = RequestAsString("RomOption")
            End If

            WeightometerId = RequestAsString("FilteredWeightometerList") ' Seems a bit odd, but it actually gets *only* the selected Weightometer 
        End Sub

        Protected Overrides Function ValidateData() As String
            Dim validationResult = New StringBuilder()
            validationResult.Append(MyBase.ValidateData())

            If String.IsNullOrEmpty(Name) Then
                validationResult.AppendLine(" - Name of Sample Station must be specified.")
            End If

            If String.IsNullOrEmpty(Description) Then
                validationResult.AppendLine(" - Description of Sample Station must be specified.")
            End If

            If String.IsNullOrEmpty(LocationType) Then
                validationResult.AppendLine(" - Location of Sample Station must be specified.")
            ElseIf LocationType.ToUpper() <> "HUB" AndAlso LocationType.ToUpper() <> "SITE" Then ' ToUpper just to be certain we avoid ambiguity
                validationResult.AppendLine(" - Location of Sample Station must be a HUB or SITE.")
            End If

            If String.IsNullOrEmpty(ProductSize) Then
                validationResult.AppendLine(" - Product Size of Sample Station must be specified.")
            End If

            If String.IsNullOrEmpty(WeightometerId) Then
                validationResult.AppendLine(" - Weightometer to attach Sample Station to must be specified.")
            End If

            If SampleStationId <> Integer.MinValue AndAlso Not String.IsNullOrEmpty(Name) AndAlso LocationId <> Integer.MinValue AndAlso Not String.IsNullOrEmpty(ProductSize) Then
                ' If we're here, we must be editing an existing sample station, check for dupes at this location
                Dim sampleStations = DalUtility.GetBhpbioSampleStationList(LocationId, "LUMP,FINES,ROM")
                Dim foundDuplicate = False
                For Each sampleStation As DataRow In sampleStations.Rows
                    ' Ignore the "current" Sample Station or we'll get a false positive.
                    If CType(sampleStation("Id"), Integer) <> SampleStationId And sampleStation("Name").Equals(Name) Then
                        foundDuplicate = True
                    End If
                Next
                If foundDuplicate Then
                    validationResult.AppendLine(" - Name of Sample Station must be unique for the location.")
                End If
            End If

            Return validationResult.ToString()
        End Function

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                Dim errorMessage = ValidateData()
                If String.IsNullOrEmpty(errorMessage) Then
                    ' TODO: This'll get more complex when editing is added.
                    EventLogDescription = "Save new Sample Station"

                    ProcessData()
                    JavaScriptAlert("Sample Station saved successfully.", String.Empty, "GetSampleStations();")
                Else
                    JavaScriptAlert(errorMessage, "Please fix the following issue(s):")
                End If
            Catch ex As SqlException
                JavaScriptAlert(String.Format($"Error while saving Sample Station: {ex.Message}"))
            End Try
        End Sub

        Protected Overrides Sub ProcessData()
            MyBase.ProcessData()

            DalUtility.DataAccess.BeginTransaction()

            Try
                DalUtility.AddOrUpdateBhpbioSampleStation(SampleStationId, Name, Description, LocationId, WeightometerId, ProductSize)
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