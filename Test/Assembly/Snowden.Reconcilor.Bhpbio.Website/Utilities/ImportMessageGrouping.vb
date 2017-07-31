Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal

Namespace Utilities
    Public Class ImportMessageGrouping
        Inherits Core.Website.Utilities.ImportMessageGrouping

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

            _month = RequestAsInt32("Month")
            _year = RequestAsInt32("Year")
            _locationId = RequestAsInt32("LocationId")
            _locationName = RequestAsString("LocationName")
            _locationType = RequestAsString("LocationType")
            _useMonthLocation = RequestAsBoolean("UseMonthLocation")
        End Sub

        Protected Overrides Function GetData(groupingType As String) As DataTable
            Select Case groupingType
                Case "Validate"
                    Return BhpbioDalImport.GetBhpbioImportSyncValidateGrouping(ImportId, _validationDateFrom, _month, _year, _locationId, _locationName, _locationType, _useMonthLocation)
                Case "Critical"
                    Return BhpbioDalImport.GetBhpbioImportExceptionGrouping(ImportId, _validationDateFrom)
                Case Else
                    Return MyBase.GetData(groupingType)
            End Select
        End Function
    End Class
End Namespace