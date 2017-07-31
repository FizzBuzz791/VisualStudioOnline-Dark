Imports System.Globalization
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal

Namespace Utilities
    Public Class ImportList
        Inherits Core.Website.Utilities.ImportList

        Private _validationDateFrom As Date = Nothing
        Private _month As Integer = Nothing
        Private _year As Integer = Nothing
        Private _locationId As Integer = Nothing
        Private _locationName As String = Nothing
        Private _locationType As String = Nothing
        Private _useMonthLocation As Boolean = Nothing

        Public ReadOnly Property BhpbioDalImport As SqlDalImportManager
            Get
                Return DirectCast(DalImport, SqlDalImportManager)
            End Get
        End Property

        Protected Overrides Sub SetupDalObjects()
            If DalImport Is Nothing Then
                DalImport = New SqlDalImportManager(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Function GetImportListData() As DataTable
            Return BhpbioDalImport.GetBhpbioImportList(_validationDateFrom, _month, _year, _locationId, _useMonthLocation)
        End Function

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            Dim radioGroup As String = RequestAsString("ImportsFilterRadioGroup")
            Select Case radioGroup
                Case "DateFromSelected"
                    _useMonthLocation = False
                Case "MonthLocationSelected"
                    _useMonthLocation = True
            End Select

            If Not Date.TryParse(RequestAsString("ImportDateFromText"), _validationDateFrom) Then
                _validationDateFrom = New Date(Date.Now.Year, 1, 1)
            End If

            Dim tempDate As Date
            If Not Date.TryParseExact(RequestAsString("MonthPickerMonthPart"), "MMM", CultureInfo.CurrentCulture, DateTimeStyles.None, tempDate) Then
                _month = 1
            Else
                _month = tempDate.Month
            End If

            If (Request("MonthPickerYearPart") = "null") Then
                _year = Date.Now.Year 'Doesn't matter, it's not going to be used, just give it *any* value so that things don't break.
            Else
                _year = RequestAsInt32("MonthPickerYearPart")
            End If

            _locationId = RequestAsInt32("LocationId")
            _locationName = RequestAsString("LocationName")
            _locationType = RequestAsString("LocationType")
        End Sub

    End Class
End Namespace
