Imports Snowden.Reconcilor.Bhpbio.Database
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Common.Database.DataAccessBaseObjects

Public Class ParameterHelper
    Private Const _minimumDateText As String = "1-Jan-1900"

    Private Sub New()
        'prevent instantiation
    End Sub

    Public Shared Function ValidateStandardDateParameters(ByVal Parameters As IDictionary(Of String, String), _
     ByRef validates As Boolean) As String
        Dim testDate As DateTime
        Dim testInt32 As Int32
        Dim parseSucceeded As Boolean
        Dim validationMessage As String = ""
        Dim currentParameter As String = ""

        validates = True

        'check that all parameters exists
        If Not Parameters.ContainsKey("DateTo") Then
            validates = False
            validationMessage = "Cannot find the DateTo parameter."
        ElseIf Not Parameters.ContainsKey("DateFrom") Then
            validates = False
            validationMessage = "Cannot find the DateFrom parameter."
        ElseIf Not Parameters.ContainsKey("DateFromLookbackDays") Then
            validates = False
            validationMessage = "Cannot find the DateFromLookbackDays parameter."
        ElseIf Not Parameters.ContainsKey("DateFromAbsoluteMinimum") Then
            validates = False
            validationMessage = "Cannot find the DateFromAbsoluteMinimum parameter."
        ElseIf Parameters("DateFrom") = Nothing And _
         Parameters("DateFromLookbackDays") = Nothing And _
         Parameters("DateFromAbsoluteMinimum") = Nothing Then
            validates = False
            validationMessage = "Values must be specified for at least one of the DateFrom, DateFromLookbackDays or DateFromAbsoluteMinumum parameters."
        Else
            'check that the parameters contain the correct contents

            For Each currentParameter In New String() {"DateTo", "DateFrom", "DateFromAbsoluteMinimum"}
                'check the parameter is either Empty and a valid date w/ no time component
                If Not (Parameters(currentParameter) = Nothing) Then
                    parseSucceeded = DateTime.TryParse(Parameters(currentParameter), testDate)
                    If Not parseSucceeded Then
                        validates = False
                        validationMessage = "The " & currentParameter & " parameter must be a valid date."
                    ElseIf testDate <> TruncateDate(testDate) Then
                        validates = False
                        validationMessage = "The " & currentParameter & " parameter must be a whole date (without a time)."
                    End If
                End If
            Next

            'check that the DateFromLookbackDays is a valid number
            If validates Then
                If Not (Parameters("DateFromLookbackDays") = Nothing) Then
                    parseSucceeded = Int32.TryParse(Parameters("DateFromLookbackDays"), testInt32)
                    If Not parseSucceeded Then
                        validates = False
                        validationMessage = "The DateFromLookbackDays parameter must be a whole number."
                    End If
                End If
            End If
        End If

        Return validationMessage
    End Function

    ''' <summary>
    ''' Load Standard Date Filters based on supplied parameters and the current system state
    ''' </summary>
    ''' <param name="Parameters">Set of parameters</param>
    ''' <param name="connection">A connection used to obtain system state information</param>
    ''' <param name="returnDateFrom">This paramter is set to the determined DateFrom</param>
    ''' <param name="returnDateTo">This paramter is set to the determined DateTo</param>
    ''' <remarks>This method is used to setup date filters on import, ensuring that the DateFrom is not earlier than purge and other rules are followed</remarks>
    Public Shared Sub LoadStandardDateFilters(ByVal Parameters As IDictionary(Of String, String), _
    ByVal connection As IDataAccessConnection, ByRef returnDateFrom As DateTime, ByRef returnDateTo As DateTime)

        Dim _purgeDal As IPurge = New SqlDal.SqlDalPurge(connection)

        Try
            Dim latestPurgedMonth As DateTime? = _purgeDal.GetLatestPurgeMonth()
            Dim earliestDateFrom As DateTime? = Nothing
            ' if there has been a purge

            If (Not latestPurgedMonth Is Nothing) Then
                ' the earliest date from is the start of the month after the purged month
                earliestDateFrom = latestPurgedMonth.Value.AddMonths(1)
            End If

            LoadStandardDateFilters(Parameters, returnDateFrom, returnDateTo, earliestDateFrom)
        Catch ex As Exception

        Finally
            If (TypeOf (_purgeDal) Is IDisposable) Then
                _purgeDal.Dispose()
                _purgeDal = Nothing
            End If
        End Try
    End Sub

    ''' <summary>
    ''' Load Standard Date Filters based on supplied parameters and an earliest allowed from date
    ''' </summary>
    ''' <param name="Parameters">Set of parameters</param>
    ''' <param name="returnDateFrom">This paramter is set to the determined DateFrom</param>
    ''' <param name="returnDateTo">This paramter is set to the determined DateTo</param>
    ''' <param name="forceEarliestDateFrom">If specified, the returnDateFrom will not be earlier than this date</param>
    ''' <remarks>This method is used to setup date filters on import, ensuring that the DateFrom is not earlier than purge and other rules are followed</remarks>
    Private Shared Sub LoadStandardDateFilters(ByVal Parameters As IDictionary(Of String, String), _
     ByRef returnDateFrom As DateTime, ByRef returnDateTo As DateTime, ByVal forceEarliestDateFrom As DateTime?)
        Dim dateFromLookback As DateTime
        Dim dateFrom As DateTime
        Dim dateTo As DateTime
        Dim dateFromAbsoluteMinimum As DateTime


        dateFromAbsoluteMinimum = Convert.ToDateTime( _
            IIf(Parameters("DateFromAbsoluteMinimum") <> "", Parameters("DateFromAbsoluteMinimum"), _minimumDateText))

        'determine the final from/to dates based on the parameters above
        If Parameters("DateTo") = Nothing Then
            dateTo = RoundDateUp(DateTime.UtcNow())
        Else
            dateTo = Convert.ToDateTime(Parameters("DateTo"))
        End If

        'take the earliest date defined from the two "from" date options
        If Parameters("DateFrom") = Nothing Then
            dateFrom = Nothing
        Else
            dateFrom = Convert.ToDateTime(Parameters("DateFrom"))
        End If

        If Parameters("DateFromLookbackDays") <> Nothing Then
            dateFromLookback = dateTo.AddDays(-CInt(Parameters("DateFromLookbackDays")))
            If (dateFrom = Nothing) OrElse (dateFromLookback < dateFrom) Then
                dateFrom = dateFromLookback
            End If
        End If

        If (dateFrom = Nothing) OrElse (dateFrom < dateFromAbsoluteMinimum) Then
            dateFrom = dateFromAbsoluteMinimum
        End If

        If (Not forceEarliestDateFrom Is Nothing And dateFrom < forceEarliestDateFrom.Value) Then
            dateFrom = forceEarliestDateFrom.Value
        End If

        ' Don't allow the DateTo to be prior to the DateFrom
        If (dateTo < dateFrom) Then
            dateTo = dateFrom
        End If

        returnDateFrom = dateFrom
        returnDateTo = dateTo
    End Sub

    Public Shared Function TruncateDate(ByVal dateTime As DateTime) As DateTime
        'simply removes the time component
        Return Convert.ToDateTime(dateTime.ToString("dd-MMM-yyyy"))
    End Function

    Public Shared Function RoundDateUp(ByVal dateTime As DateTime) As DateTime
        'if the time component is present then roll the date forward
        'if there is no time component then don't change anything
        If dateTime = TruncateDate(dateTime) Then
            Return dateTime
        Else
            Return TruncateDate(dateTime).AddDays(1)
        End If
    End Function
End Class
