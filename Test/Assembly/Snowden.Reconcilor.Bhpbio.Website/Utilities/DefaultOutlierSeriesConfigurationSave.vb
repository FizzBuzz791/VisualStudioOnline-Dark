Imports System.Text
Imports System.Data.SqlClient
Imports Snowden.Consulting.DataSeries.DataAccess
Imports Snowden.Reconcilor.Bhpbio.Website.Extensibility

Namespace Utilities
    Public Class DefaultOutlierSeriesConfigurationSave
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _outlierSeriesConfigurationId As String = ""
        Private _description As String = ""
        Private _isactive As Boolean = True
        Private _priorityBox As Integer = 0
        Private _outlierThreshold As Double = 0
        Private _minimumDataPoints As Integer = 0
        Private _rollingSeriesSize As Integer = 0
        Private _projectValueMethod As String = Nothing
        Private _triggerOutlierProcessing As Boolean = False

        Private Property OutlierSeriesConfigurationId() As String
            Get
                Return _outlierSeriesConfigurationId
            End Get
            Set
                _outlierSeriesConfigurationId = Value
            End Set
        End Property

        Private Property Description() As String
            Get
                Return _description
            End Get
            Set(ByVal value As String)
                _description = value
            End Set
        End Property

        Protected Property IsActive() As Boolean
            Get
                Return _isactive
            End Get
            Set(ByVal value As Boolean)
                _isactive = value
            End Set
        End Property
        Protected Property PriorityBox() As Integer
            Get
                Return _priorityBox
            End Get
            Set(ByVal value As Integer)
                _priorityBox = value
            End Set
        End Property
        Protected Property OutlierThreshold() As Double
            Get
                Return _outlierThreshold
            End Get
            Set(ByVal value As Double)
                _outlierThreshold = value
            End Set
        End Property
        Protected Property MinimumDataPoints() As Integer
            Get
                Return _minimumDataPoints
            End Get
            Set(ByVal value As Integer)
                _minimumDataPoints = value
            End Set
        End Property
        Protected Property RollingSeriesSize() As Integer
            Get
                Return _rollingSeriesSize
            End Get
            Set(ByVal value As Integer)
                _rollingSeriesSize = value
            End Set
        End Property
        Protected Property ProjectValueMethod() As String
            Get
                Return _projectValueMethod
            End Get
            Set(ByVal value As String)
                _projectValueMethod = value
            End Set
        End Property

        Protected Property TriggerOutlierProcessing() As Boolean
            Get
                Return _triggerOutlierProcessing
            End Get
            Set(value As Boolean)
                _triggerOutlierProcessing = value
            End Set
        End Property


        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            Description = RequestAsString("Description")
            If OutlierHelper.IsNumericPriority(RequestAsString("Priority")) Then
                PriorityBox = RequestAsInt32("Priority")
            Else
                PriorityBox = 0
            End If

            If OutlierHelper.IsNumericThreshold(RequestAsString("OutlierThreshold")) Then
                OutlierThreshold = RequestAsDouble("OutlierThreshold")
            Else
                OutlierThreshold = 0
            End If

            If OutlierHelper.IsIntegerAndValidRange(RequestAsString("MinimumDataPoints"), 1, 100) Then
                MinimumDataPoints = RequestAsInt32("MinimumDataPoints")
            Else
                MinimumDataPoints = 0
            End If

            If OutlierHelper.IsIntegerAndValidRange(RequestAsString("RollingSeriesSize"), 1, 100) Then
                RollingSeriesSize = RequestAsInt32("RollingSeriesSize")
            Else
                RollingSeriesSize = 0
            End If

            TriggerOutlierProcessing = RequestAsBoolean("TriggerOutlierProcessing")
            IsActive = RequestAsBoolean("IsActive")
            OutlierSeriesConfigurationId = RequestAsString("OutlierSeriesConfigurationId")
            ProjectValueMethod = RequestAsString("projectValueMethod")

        End Sub

        Protected Overrides Function ValidateData() As String
            Dim errorMessage As New StringBuilder(MyBase.ValidateData())

            If Request("OutlierSeriesConfigurationId") = String.Empty Then
                OutlierSeriesConfigurationId = ""
            End If

            If PriorityBox = 0 Then ' a valid value could not be read
                errorMessage.Append("\nPriority must be an integer value between 1 and 1000.")
            End If
            If Description Is Nothing Then
                errorMessage.Append("\nDescription was not provided.")
            ElseIf Description.Length > 1000 Then
                errorMessage.Append("\n Description must be 1000 characters or less.")
            End If
            If OutlierThreshold = 0 Then
                errorMessage.Append("\nOutlier Threshold must be a decimal value between 1 and 10 with .5 increments.")
            End If
            If MinimumDataPoints = 0 Then
                errorMessage.Append("\nMinimum Data Points must be an integer between 1 and 100.")
            End If
            If RollingSeriesSize = 0 Then
                errorMessage.Append("\nRolling Series Size must be an integer between 1 and 100.")
            End If

            Return errorMessage.ToString
        End Function
       

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                If OutlierSeriesConfigurationId Is Nothing Then
                    EventLogDescription = "Update Outlier Series Configuration record"
                Else
                    EventLogDescription = String.Format("Save update to Outlier Series Configuration record ID: {0}", OutlierSeriesConfigurationId)
                End If

                Dim errorMessage As String = ValidateData()

                If errorMessage = String.Empty Then
                    'Save

                    OutlierHelper.SaveOutlierSeries(Resources.ConnectionString, OutlierSeriesConfigurationId, PriorityBox, ProjectValueMethod, OutlierThreshold,
                                                    MinimumDataPoints, RollingSeriesSize, Description, IsActive, TriggerOutlierProcessing)

                    JavaScriptAlert("Outlier Series Configuration saved successfully.", String.Empty, "GetDefaultOutlierSeriesList();")
                Else
                    JavaScriptAlert(errorMessage, "Please fix the following issues:")
                End If
            Catch ex As SqlException
                JavaScriptAlert(String.Format("Error while saving Outlier Series Configuration: {0}", ex.Message))
            End Try
        End Sub

    End Class
End Namespace
