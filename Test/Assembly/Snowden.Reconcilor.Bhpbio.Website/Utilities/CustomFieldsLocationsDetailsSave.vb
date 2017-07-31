Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports System.Text
Imports Snowden.Common.Web.BaseHtmlControls

Namespace Utilities
    Public Class CustomFieldsLocationsDetailsSave
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Structure ThresholdContainer
            Dim high As Double
            Dim low As Double
            Dim absolute As Boolean
        End Structure

#Region "Properties"
        Private _locationId As Int32
        Private _thresholdtypeId As String
        Private _removeOverrides As Boolean
        Private _applySettings As Boolean
        Private _dalUtility As IUtility
        Private _thresholdVales As New Dictionary(Of Int16, ThresholdContainer)
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
                        If Not _dalUtility Is Nothing Then
                            _dalUtility.Dispose()
                            _dalUtility = Nothing
                        End If
                    End If

                    _thresholdVales = Nothing
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
            _thresholdtypeId = RequestAsString("ThresholdTypeId")
            _applySettings = (RequestAsString("ApplyThreshold") = "true")
            _removeOverrides = (RequestAsString("ResetThreshold") = "true")
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim validMessage As String = ValidateData()

            Try
                If (validMessage = "") Then
                    If _removeOverrides Then
                        DalUtility.DeleteBhpbioReportThreshold(_locationId, _thresholdtypeId, DoNotSetValues.Int16)
                        '    Response.Write("LoadLocationsDetails(" & _locationId & "); alert('Reporting Thresholds have been removed.');")
                        Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "LoadLocationsDetails(" & _locationId & "); alert('Reporting Thresholds have been removed.');"))

                    ElseIf _applySettings Then
                        ProcessData()
                        '    Response.Write("LoadLocationsDetails(" & _locationId & "); alert('Reporting Thresholds have been applied.');")
                        Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "LoadLocationsDetails(" & _locationId & "); alert('Reporting Thresholds have been applied.');"))

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
            Dim thresholdPrefix As String = "Threshold_"
            Dim highPostFix As String = "_High"
            Dim lowPostfix As String = "_Low"
            Dim absolutePostfix As String = "_Absolute"
            Dim thresholds As DataTable
            Dim fieldId As Int16
            Dim row As DataRow
            Dim threshold As ThresholdContainer

            If _thresholdtypeId = "" Then
                returnValue.Append("\nThreshold type was not provided.")
            ElseIf _applySettings Then
                thresholds = DalUtility.GetBhpbioReportThresholdList(_locationId, _
                 _thresholdtypeId, False, True)

                For Each row In thresholds.Rows
                    fieldId = Convert.ToInt16(row("FieldId"))
                    threshold = New ThresholdContainer

                    threshold.low = RequestAsDouble(thresholdPrefix & fieldId & lowPostfix)
                    threshold.high = RequestAsDouble(thresholdPrefix & fieldId & highPostFix)

                    If CustomFieldsLocationsDetails.SingleValueThresholds.Contains(_thresholdtypeId.ToLower) Then
                        'Not relevant at this point for graph threshold. 
                        'Use a null high threshold.

                        threshold.high = threshold.low

                        'Simple validation logic for only a single value.
                        If threshold.low = DoNotSetValues.Double Then
                            returnValue.Append("\nThe threshold  " & row("FieldName").ToString & " value was not a valid number.")
                        End If

                        If Not threshold.low >= 0 Then
                            returnValue.Append("\nThe threshold must be positive")
                        End If

                        threshold.absolute = False

                        threshold.low = threshold.low / 100
                        threshold.high = threshold.high / 100

                        'Set up scaling factors for the graph.
                        threshold.low = 1 - threshold.low
                        threshold.high = 1 + threshold.high


                        _thresholdVales.Add(fieldId, threshold)

                    Else

                        ' Check the low and high threshold before adding the threshold.
                        If threshold.high = DoNotSetValues.Double Then
                            returnValue.Append("\nThe high threshold  " & row("FieldName").ToString & " value was not a valid number.")
                        End If
                        If threshold.low = DoNotSetValues.Double Then
                            returnValue.Append("\nThe low threshold  " & row("FieldName").ToString & " value was not a valid number.")
                        End If

                        If threshold.high <> DoNotSetValues.Double And threshold.low <> DoNotSetValues.Double Then
                            If threshold.low > threshold.high Then
                                returnValue.Append("\nThe low threshold can not be greater than the high threshold for " & row("FieldName").ToString & ".")

                            Else ' Passed all checks, Add to list.
                                threshold.absolute = RequestAsBoolean(thresholdPrefix & fieldId & absolutePostfix)
                                _thresholdVales.Add(fieldId, threshold)
                            End If
                        End If

                    End If


                Next
            End If

            Return returnValue.ToString
        End Function

        Protected Overrides Sub ProcessData()
            Dim fieldId As Short
            Dim threshold As ThresholdContainer

            ' Insert each of the thresholds.
            For Each fieldId In _thresholdVales.Keys
                threshold = _thresholdVales.Item(fieldId)
                DalUtility.AddOrUpdateBhpbioReportThreshold(_locationId, _thresholdtypeId, _
                 fieldId, threshold.low, threshold.high, threshold.absolute)
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

