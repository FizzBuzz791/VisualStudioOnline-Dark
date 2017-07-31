Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.Website.Analysis
Imports Snowden.Common.Web.BaseHtmlControls

Imports System.Text

Namespace Analysis
    Public Class DigblockSpatialVarianceSave
        Inherits Core.WebDevelopment.WebpageTemplates.AnalysisAjaxTemplate

        Private Structure VarianceContainer
            Dim percentage As Double
            Dim color As String
        End Structure

#Region "Properties"
        Private _locationId As Int32
        Private _removeOverrides As Boolean
        Private _applySettings As Boolean
        Private _dalUtility As IUtility
        Private _varianceValues As New Dictionary(Of String, VarianceContainer)
        Private _disposed As Boolean

        Protected Property DalUtility() As IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As IUtility)
                _dalUtility = value
            End Set
        End Property
#End Region


#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If (Not _dalUtility Is Nothing) Then
                            _dalUtility.Dispose()
                            _dalUtility = Nothing
                        End If

                    End If

                    _varianceValues = Nothing
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region


        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            _locationId = RequestAsInt32("LocationId")
            _applySettings = (RequestAsString("ApplyVariance") = "true")
            _removeOverrides = (RequestAsString("ResetVariance") = "true")
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim validMessage As String = ValidateData()

            Try
                If (validMessage = "") Then
                    If _removeOverrides Then
                        DalUtility.DeleteBhpbioAnalysisVariance(_locationId, DoNotSetValues.Char)
                        'Response.Write("getVarianceDetails(" & _locationId & "); alert('Variance Settings have been removed.');")
                        Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "getVarianceDetails(" & _locationId & "); alert('Variance Settings have been removed.');"))

                    ElseIf _applySettings Then
                        ProcessData()
                        'Response.Write("getVarianceDetails(" & _locationId & "); alert('Variance Settings have been applied.');")
                        Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "getVarianceDetails(" & _locationId & "); alert('Variance Settings have been applied.');"))
                    End If

                Else
                    JavaScriptAlert(validMessage, "Error saving settings:")
                End If
            Catch ex As SqlClient.SqlException
                JavaScriptAlert(ex.Message)
            End Try
        End Sub


        Protected Overrides Function ValidateData() As String
            Dim returnValue As New StringBuilder(MyBase.ValidateData())
            Dim varianceList As New ArrayList
            Dim variance As String
            Dim varianceValues As VarianceContainer

            If _applySettings Then
                ' Retrieve hard coded core values.
                For i = DigblockSpatialCommon.VarianceIndexA To DigblockSpatialCommon.VarianceIndexE
                    varianceList.Add(DigblockSpatialCommon.VarianceLetter(i))
                Next

                For Each variance In varianceList
                    varianceValues = New VarianceContainer
                    varianceValues.color = RequestAsString("color" & variance)
                    varianceValues.percentage = RequestAsDouble("variance" & variance)

                    If varianceValues.color = DoNotSetValues.String Then
                        returnValue.Append("\nThe color for Variance " & variance & " was not a valid number.")
                    End If

                    If varianceValues.percentage = DoNotSetValues.Double Then
                        returnValue.Append("\nThe percentage for Variance " & variance & " was not a valid number.")
                    End If

                    _varianceValues.Add(variance, varianceValues)
                Next
            End If

            Return returnValue.ToString
        End Function

        Protected Overrides Sub ProcessData()
            Dim variance As String
            Dim varianceValues As VarianceContainer

            ' Insert each of the thresholds.
            For Each variance In _varianceValues.Keys
                varianceValues = _varianceValues.Item(variance)
                DalUtility.AddOrUpdateBhpbioAnalysisVariance(_locationId, variance, _
                 varianceValues.percentage, varianceValues.color)
            Next
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub



    End Class
End Namespace
