
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal

Namespace Utilities
    Public Class ImportMessage
        Inherits Core.Website.Utilities.ImportMessage

        Private _validationDateFrom As Date = Nothing
        Private _month As Int32 = Nothing
        Private _year As Int32 = Nothing
        Private _locationId As Int32 = Nothing
        Private _locationName As String = Nothing
        Private _locationType As String = Nothing
        Private _useMonthLocation As Boolean = Nothing

        Public ReadOnly Property BhpbioDalImport As SqlDalImportManager
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

            _month = RequestAsInt32("Month")
            _year = RequestAsInt32("Year")
            _locationId = RequestAsInt32("LocationId")
            _locationName = RequestAsString("LocationName")
            _locationType = RequestAsString("LocationType")
            _useMonthLocation = RequestAsBoolean("UseMonthLocation")
        End Sub

        Protected Overrides Function GetData(statusType As ImportStatusTypes) As DataSet
            Select Case ImportStatusType
                Case ImportStatusTypes.Validate
                    Return BhpbioDalImport.GetBhpbioImportSyncValidateRecords(UserMessage, ImportId, CurrentPage, PageSize, _validationDateFrom, _month, _year, _locationId, _locationName, _locationType, _useMonthLocation)
                Case ImportStatusTypes.Critical
                    Return BhpbioDalImport.GetBhpbioImportExceptionRecords(UserMessage, ImportId, CurrentPage, PageSize, _validationDateFrom)
                Case Else
                    Return MyBase.GetData(statusType)
            End Select
        End Function

        Protected Overrides Function GetExportUrl(exportType As String) As String
            ' append the validation date item to the end of the existing url
            Return String.Format("{0}&ValidationDateFrom={1:yyyy-MM-dd}&Month={2}&Year={3}&LocationId={4}&LocationName={5}&LocationType={6}&UseMonthLocation={7}", MyBase.GetExportUrl(exportType), _validationDateFrom, _month, _year, _locationId, _locationName, _locationType, _useMonthLocation)
        End Function

    End Class
End Namespace