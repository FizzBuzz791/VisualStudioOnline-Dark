'Namespace Types
'    Public Class IdList
'        Inherits ObjectModel.Collection(Of Int32?)

'        ''' <summary>
'        ''' Adds the value if it does not already exist.
'        ''' </summary>
'        Public Function AddIfNotExists(ByVal value As Int32?) As Boolean
'            If Not Contains(value) Then
'                Add(value)
'            End If
'        End Function

'        ''' <summary>
'        ''' Performs a deep copy of the Id list.
'        ''' </summary>
'        Public Function Clone() As IdList
'            Dim id As Int32?
'            Dim newList As New IdList

'            For Each id In Me
'                newList.Add(id)
'            Next
'            Return newList
'        End Function

'        ''' <summary>
'        ''' Copies the source rows into the list.
'        ''' </summary>
'        Public Sub Copy(ByVal source As IdList)
'            Merge(Me, source)
'        End Sub

'        ''' <summary>
'        '''  Merges the items in Source into Dest if they do not already exist.
'        ''' </summary>
'        Public Shared Sub Merge(ByVal dest As IdList, ByVal source As IdList)
'            Dim id As Int32?
'            For Each id In source
'                If Not dest.Contains(id) Then
'                    dest.Add(id)
'                End If
'            Next
'        End Sub

'        ''' <summary>
'        ''' Combines two lists into a single list.
'        ''' </summary>
'        Public Shared Function Combine(ByVal l As IdList, ByVal r As IdList) As IdList
'            Dim newList As IdList = l.Clone()
'            Merge(newList, r)
'            Return newList
'        End Function
'    End Class
'End Namespace
