'Namespace Types
'    Public Class CalendarDateList
'        Inherits ObjectModel.Collection(Of DateTime)


'        ''' <summary>
'        ''' Adds the value if it does not already exist.
'        ''' </summary>
'        Public Function AddIfNotExists(ByVal value As DateTime) As Boolean
'            If Not Contains(value) Then
'                Add(value)
'            End If
'        End Function

'        ''' <summary>
'        ''' Performs a deep copy of the Date list.
'        ''' </summary>
'        Public Function Clone() As CalendarDateList
'            Dim datePeriod As DateTime
'            Dim newList As New CalendarDateList

'            For Each datePeriod In Me
'                newList.Add(datePeriod)
'            Next
'            Return newList
'        End Function

'        ''' <summary>
'        ''' Copies the source rows into the list.
'        ''' </summary>
'        Public Sub Copy(ByVal source As CalendarDateList)
'            Merge(Me, source)
'        End Sub

'        ''' <summary>
'        '''  Merges the items in Source into Dest if they do not already exist.
'        ''' </summary>
'        Public Shared Sub Merge(ByVal dest As CalendarDateList, ByVal source As CalendarDateList)
'            Dim datePeriod As DateTime
'            For Each datePeriod In source
'                If Not dest.Contains(datePeriod) Then
'                    dest.Add(datePeriod)
'                End If
'            Next
'        End Sub

'        ''' <summary>
'        ''' Combines two lists into a single list.
'        ''' </summary>
'        Public Shared Function Combine(ByVal l As CalendarDateList, ByVal r As CalendarDateList) As CalendarDateList
'            Dim newList As CalendarDateList = l.Clone()
'            Merge(newList, r)
'            Return newList
'        End Function
'    End Class
'End Namespace
