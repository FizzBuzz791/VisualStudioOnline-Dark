Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports NullValues = Snowden.Common.Database.DataAccessBaseObjects.NullValues

Namespace Utilities
    Public Class ImportMessageGroupingExportXml
        Inherits Core.Website.Utilities.ImportMessageGroupingExportXml

        Private _validationDateFrom As Date = Nothing
        Private _month As Int32 = Nothing
        Private _year As Int32 = Nothing
        Private _locationId As Int32 = Nothing
        Private _locationName As String = Nothing
        Private _locationType As String = Nothing
        Private _useMonthLocation As Boolean = Nothing

        Public ReadOnly Property BhpbioDalImport() As SqlDalImportManager
            Get
                Return DirectCast(ImportManagerDal, SqlDalImportManager)
            End Get
        End Property

        Protected Overrides Sub SetupDalObjects()
            If ImportManagerDal Is Nothing Then
                ImportManagerDal = New SqlDalImportManager(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If Not Date.TryParse(RequestAsString("ValidationDateFrom"), _validationDateFrom) Then
                _validationDateFrom = New Date(Date.Now.Year, 1, 1)
            End If

            ' It doesn't *really* matter what we default these too, as long as _useMonthLocation defaults to false, these won't even be used.
            _month = RequestAsInt32("Month", _validationDateFrom.Month)
            _year = RequestAsInt32("Year", _validationDateFrom.Year)
            _locationId = RequestAsInt32("LocationId", 1)
            _locationName = RequestAsString("LocationName", "WAIO")
            _locationType = RequestAsString("LocationType", "Company")
            _useMonthLocation = RequestAsBoolean("UseMonthLocation", False)
        End Sub

        Private Overloads Function RequestAsInt32(param As String, defaultValue As Integer) As Int32
            Dim result As Int32

            If (Request(param) IsNot Nothing) AndAlso Not String.IsNullOrEmpty(Request(param).Trim) Then
                result = Convert.ToInt32(Request(param).Trim)
            Else
                result = defaultValue
            End If

            Return result
        End Function

        Private Overloads Function RequestAsString(param As String, defaultValue As String) As String
            Dim result As String

            If (Request(param) IsNot Nothing) AndAlso Not String.IsNullOrEmpty(Request(param).Trim) Then
                result = Request(param).Trim
            Else
                result = defaultValue
            End If

            Return result
        End Function

        Private Overloads Function RequestAsBoolean(param As String, defaultValue As Boolean) As Boolean
            Dim result As Boolean

            If (Request(param) IsNot Nothing) AndAlso Not String.IsNullOrEmpty(Request(param).Trim) Then
                result = Convert.ToBoolean(Request(param).Trim)
            Else
                result = defaultValue
            End If

            Return result
        End Function

        Protected Overrides Function GetData(groupingType As String) As DataSet

            Select Case groupingType.ToLower
                Case "validate"
                    Return BhpbioDalImport.GetBhpbioImportSyncValidateRecords(UserMessage, ImportId, NullValues.Int32, NullValues.Int32, _validationDateFrom, _month, _year, _locationId, _locationName, _locationType, _useMonthLocation)
                Case "critical"
                    Return BhpbioDalImport.GetBhpbioImportExceptionRecords(UserMessage, ImportId, NullValues.Int32, NullValues.Int32, _validationDateFrom)
                Case Else
                    Return MyBase.GetData(groupingType)
            End Select

        End Function

    End Class
End Namespace