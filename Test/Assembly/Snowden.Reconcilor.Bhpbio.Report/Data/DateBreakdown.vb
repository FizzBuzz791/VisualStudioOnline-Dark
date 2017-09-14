Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Data

    Public NotInheritable Class DateBreakdown
        Private Sub New()
        End Sub

        Public Shared Function GetQuarterList(ByVal endDate As Date) As InputTags.SelectBox
            Dim quarterList As New InputTags.SelectBox
            Dim quarter As String = ""

            With quarterList
                .Items.Add(New ListItem("Quarter 1", "Q1"))
                .Items.Add(New ListItem("Quarter 2", "Q2"))
                .Items.Add(New ListItem("Quarter 3", "Q3"))
                .Items.Add(New ListItem("Quarter 4", "Q4"))

                Select Case endDate.Month
                    Case 1, 2, 3
                        quarter = "Q3"
                    Case 4, 5, 6
                        quarter = "Q4"
                    Case 7, 8, 9
                        quarter = "Q1"
                    Case 10, 11, 12
                        quarter = "Q2"
                    Case Else
                End Select

                .SelectedValue = quarter
            End With

            Return quarterList
        End Function

        Public Shared Function GetDateFromUsingMonth(ByVal dateFromMonth As String, ByVal dateFromYear As String) As String
            Dim dateFrom As New Date

            dateFrom = Convert.ToDateTime("1-" & dateFromMonth & "-" & dateFromYear)

            Return dateFrom.ToString("O")
        End Function

        Public Shared Function GetDateToUsingMonth(ByVal dateToMonth As String, ByVal dateToYear As String) As String
            Dim dateTo As New Date
            Dim daysInMonth As Integer

            daysInMonth = Date.DaysInMonth(Convert.ToInt32(dateToYear), Month(Convert.ToDateTime("1-" & dateToMonth & "-" & dateToYear)))
            dateTo = Convert.ToDateTime(daysInMonth.ToString & "-" & dateToMonth & "-" & dateToYear)

            Return dateTo.ToString("O")
        End Function

        Public Shared Function GetDateFromUsingQuarter(ByVal dateFromQuarter As String, ByVal dateFromYear As String) As DateTime
            Dim resolvedDate As DateTime
            Dim month As String = ""

            month = ResolveDateFrom(dateFromQuarter)

            resolvedDate = Date.Parse("01-" + month + "-" + dateFromYear)

            If (resolvedDate.Month > 6) Then
                resolvedDate = resolvedDate.AddYears(-1)
            End If

            Return resolvedDate

        End Function

        Public Shared Function GetDateToUsingQuarter(ByVal dateFromQuarter As String, ByVal dateToYear As String) As DateTime
            Dim resolvedDate As DateTime
            Dim daysInMonth As Integer
            Dim dateFromMonth As String = ""

            dateFromMonth = ResolveDateTo(dateFromQuarter)

            daysInMonth = Date.DaysInMonth(Convert.ToInt32(dateToYear), Month(Convert.ToDateTime("1-" & dateFromMonth & "-" & dateToYear)))

            resolvedDate = Date.Parse(daysInMonth.ToString() + dateFromMonth + "-" + dateToYear)

            If (resolvedDate.Month > 6) Then
                resolvedDate = resolvedDate.AddYears(-1)
            End If

            Return resolvedDate

        End Function

        Public Shared Function ResolveYear(ByVal dateFrom As DateTime) As DateTime

            Dim resolvedDate As DateTime = dateFrom

            If dateFrom.Month > 6 Then
                resolvedDate = dateFrom.AddYears(1)
            End If

            Return resolvedDate

        End Function

        Public Shared Function GetDateToQuarter(ByVal month As String) As String

            Dim quarterToReturn As String = ""
            Dim monthAsInt As Integer = Int32.Parse(month)

            Select Case monthAsInt
                Case 1, 2, 3
                    quarterToReturn = "Q3"
                Case 4, 5, 6
                    quarterToReturn = "Q4"
                Case 7, 8, 9
                    quarterToReturn = "Q1"
                Case 10, 11, 12
                    quarterToReturn = "Q2"
            End Select

            Return quarterToReturn

        End Function

        Public Shared Function GetDateFromQuarter(ByVal month As String) As String

            Dim quarterToReturn As String = ""
            Dim monthAsInt As Integer = Int32.Parse(month)

            Select Case monthAsInt
                Case 1, 2, 3
                    quarterToReturn = "Q3"
                Case 4, 5, 6
                    quarterToReturn = "Q4"
                Case 7, 8, 9
                    quarterToReturn = "Q1"
                Case 10, 11, 12
                    quarterToReturn = "Q2"
            End Select

            Return quarterToReturn

        End Function


        Public Shared Function ResolveDateTo(ByVal quarter As String) As String

            Dim resolvedMonth As String = ""

            If quarter = "Q1" Then
                resolvedMonth = "Sep"
            ElseIf quarter = "Q2" Then
                resolvedMonth = "Dec"
            ElseIf quarter = "Q3" Then
                resolvedMonth = "Mar"
            ElseIf quarter = "Q4" Then
                resolvedMonth = "Jun"
            End If

            Return resolvedMonth
        End Function

        Public Shared Function ResolveDateFrom(ByVal quarter As String) As String

            Dim resolvedMonth As String = ""

            If quarter = "Q1" Then
                resolvedMonth = "Jul"
            ElseIf quarter = "Q2" Then
                resolvedMonth = "Oct"
            ElseIf quarter = "Q3" Then
                resolvedMonth = "Jan"
            ElseIf quarter = "Q4" Then
                resolvedMonth = "Apr"
            End If

            Return resolvedMonth

        End Function


        Public Shared Sub AddDateText(ByVal dateBreakdown As Types.ReportBreakdown,
         ByVal table As DataTable, ByVal dateColumn As String)
            Dim columnName As String = "DateText"
            table.Columns.Add(New DataColumn(columnName, GetType(String), ""))
            MergeDateText(dateBreakdown, table, dateColumn, columnName)
        End Sub

        Public Shared Sub AddDateText(ByVal breakdown As Types.ReportBreakdown,
         ByVal data As Types.CalculationSet)
            Dim result As Types.CalculationResult
            Dim resultItem As Types.CalculationResult
            Dim currentDate As DateTime
            Dim quarter As String = ""
            Dim year As String = ""
            Dim dateString As String = ""

            For Each result In data
                For Each resultItem In result.GetAllCalculations()
                    For Each currentDate In resultItem.CalendarDateCollection
                        If breakdown = Types.ReportBreakdown.Monthly Then
                            dateString = Format(currentDate, "MMM-yyyy")

                        ElseIf breakdown = Types.ReportBreakdown.CalendarQuarter Then
                            Select Case Month(currentDate)
                                Case 1, 2, 3
                                    quarter = "Q3"
                                    year = Format(currentDate, "yyyy")
                                Case 4, 5, 6
                                    quarter = "Q4"
                                    year = Format(currentDate, "yyyy")
                                Case 7, 8, 9
                                    quarter = "Q1"
                                    year = Format(DateAdd(DateInterval.Year, 1, currentDate), "yyyy")
                                Case Else
                                    quarter = "Q2"
                                    year = Format(DateAdd(DateInterval.Year, 1, currentDate), "yyyy")
                            End Select
                            dateString = String.Format("{0} {1}", quarter, year)
                        ElseIf breakdown = Types.ReportBreakdown.Yearly Then
                            dateString = Format(currentDate, "yyyy")
                        Else
                            dateString = Format(currentDate, "dd-MMM-yyyy")
                        End If

                        resultItem.Tags.Add(New Types.CalculationResultTag("DateText", currentDate,
                         GetType(String), dateString))
                    Next
                Next
            Next
        End Sub

        Public Shared Sub MergeDateText(ByVal dateBreakdown As Types.ReportBreakdown,
         ByVal table As DataTable, ByVal dateColumn As String, ByVal textColumn As String)
            Dim row As DataRow

            For Each row In table.Rows
                Dim quarter As String = ""
                Dim year As String = ""

                If table.Columns.Contains(dateColumn) AndAlso table.Columns.Contains(textColumn) _
                 AndAlso Not IsDBNull(row(dateColumn)) Then
                    row(textColumn) = GetDateText(row.AsDate(dateColumn), dateBreakdown)
                ElseIf table.Columns.Contains(textColumn) Then
                    row(textColumn) = DBNull.Value
                End If
            Next
        End Sub

        Public Shared Function GetDateText(dateValue As Date, dateBreakdown As ReportBreakdown) As String
            If dateBreakdown = ReportBreakdown.Monthly Then
                Return Format(dateValue, "MMM-yyyy")
            ElseIf dateBreakdown = ReportBreakdown.CalendarQuarter Then
                Dim quarter As String = ""
                Dim year As String = ""

                Select Case Month(Convert.ToDateTime(dateValue))
                    Case 1, 2, 3
                        quarter = "Q3"
                        Year = Format(dateValue, "yyyy")
                    Case 4, 5, 6
                        quarter = "Q4"
                        Year = Format(dateValue, "yyyy")
                    Case 7, 8, 9
                        quarter = "Q1"
                        Year = Format(DateAdd(DateInterval.Year, 1, Convert.ToDateTime(dateValue)), "yyyy")
                    Case Else
                        quarter = "Q2"
                        Year = Format(DateAdd(DateInterval.Year, 1, Convert.ToDateTime(dateValue)), "yyyy")
                End Select

                Return String.Format("{0} {1}", quarter, year)
            ElseIf dateBreakdown = ReportBreakdown.Yearly Then
                Return Format(dateValue, "yyyy")
            Else
                Return Format(dateValue, "dd-MMM-yyyy")
            End If
        End Function

        Shared Sub AddDateText(ByVal table As DataTable, ByVal breakdown As Types.ReportBreakdown,
         ByVal sourceDateColumnName As String, ByVal parsedDateTextColumName As String)
            table.Columns.Add(parsedDateTextColumName, GetType(String), "")
            Data.DateBreakdown.MergeDateText(breakdown, table, sourceDateColumnName, parsedDateTextColumName)
        End Sub

        ''' <summary>
        ''' Find the date that begins a breakdown period
        ''' </summary>
        ''' <param name="referencedDateTime">date time used as a reference point</param>
        ''' <param name="breakdown">date breakdown to be used</param>
        ''' <returns>Date that is the start of the breakdown period that the referenced date time belongs to</returns>
        Shared Function FindStartOfBreakdownPeriod(ByVal referencedDateTime As DateTime, ByVal breakdown As Types.ReportBreakdown) As DateTime
            Dim returnDate As DateTime = Nothing

            ' Form monthly breakdowns
            If (breakdown = ReportBreakdown.Monthly) Then
                ' the period is the start of the month
                returnDate = New DateTime(referencedDateTime.Year, referencedDateTime.Month, 1)
            ElseIf (breakdown = ReportBreakdown.CalendarQuarter) Then
                ' the period is the start of the first month in the quarter
                Dim startMonthOfPeriod As Integer = referencedDateTime.Month - ((referencedDateTime.Month - 1) Mod 3)
                returnDate = New DateTime(referencedDateTime.Year, startMonthOfPeriod, 1)
            ElseIf (breakdown = ReportBreakdown.Yearly) Then
                ' the period is the start of july
                returnDate = New DateTime(referencedDateTime.Year, 7, 1)
                ' if the reference month is early in the calendar year than july then jump back a year
                If (referencedDateTime.Month < 7) Then
                    returnDate = returnDate.AddYears(-1)
                End If
            End If

            Return returnDate
        End Function


    End Class

    Module DateBreakdownExtensions

        ' convert to a string as used in the DAL methods (ie MONTH, QUARTER etc)
        <Runtime.CompilerServices.Extension()>
        Public Function ToParameterString(dateBreakdown As ReportBreakdown) As String
            Select Case dateBreakdown
                Case ReportBreakdown.None : Return "NONE"
                Case ReportBreakdown.Monthly : Return "MONTH"
                Case ReportBreakdown.Yearly : Return "YEAR"
                Case ReportBreakdown.CalendarQuarter : Return "QUARTER"
                Case Else : Return dateBreakdown.ToString()
            End Select

        End Function
    End Module
End Namespace
