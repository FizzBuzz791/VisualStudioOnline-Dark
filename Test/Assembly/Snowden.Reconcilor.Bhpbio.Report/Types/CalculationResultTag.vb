Namespace Types


    <DebuggerDisplayAttribute("TagId:{_tagId}, CalendarDate:{_calendarDate}, Type:{_type}, Value:{_value}")> _
    Public Class CalculationResultTag
        Private _tagId As String
        Private _type As System.Type
        Private _value As Object
        Private _calendarDate As DateTime?
        Private _locationId As Int32?
        Private _dateSet As Boolean
        Private _locationSet As Boolean

        Public Property TagId() As String
            Get
                Return _tagId
            End Get
            Set(ByVal value As String)
                _tagId = value
            End Set
        End Property

        Public Property CalendarDate() As DateTime?
            Get
                Return _calendarDate
            End Get
            Set(ByVal value As DateTime?)
                _calendarDate = value
            End Set
        End Property

        Public Property DateSet() As Boolean
            Get
                Return _dateSet
            End Get
            Set(ByVal value As Boolean)
                _dateSet = value
            End Set
        End Property

        Public Property LocationId() As Int32?
            Get
                Return _locationId
            End Get
            Set(ByVal value As Int32?)
                _locationId = value
            End Set
        End Property

        Public Property LocationSet() As Boolean
            Get
                Return _locationSet
            End Get
            Set(ByVal value As Boolean)
                _locationSet = value
            End Set
        End Property

        Public Property DataType() As System.Type
            Get
                Return _type
            End Get
            Set(ByVal value As System.Type)
                _type = value
            End Set
        End Property

        Public Property Value() As Object
            Get
                Return _value
            End Get
            Set(ByVal value As Object)
                _value = value
            End Set
        End Property

        Public Sub New(ByVal tagId As String, ByVal type As System.Type, ByVal value As Object)
            _tagId = tagId
            _type = type
            _value = value
            _dateSet = False
            _locationSet = False
        End Sub

        Public Sub New(ByVal tagId As String, ByVal calendarDate As DateTime?, _
         ByVal type As System.Type, ByVal value As Object)
            Me.New(tagId, type, value)
            _calendarDate = calendarDate
            _dateSet = True
        End Sub

        Public Sub New(ByVal tagId As String, ByVal locationId As Int32?, _
         ByVal type As System.Type, ByVal value As Object)
            Me.New(tagId, type, value)
            _locationId = locationId
            _locationSet = True
        End Sub

        Public Function Clone() As CalculationResultTag
            If _dateSet Then
                Clone = New CalculationResultTag(TagId, CalendarDate, DataType, Value)
            ElseIf _locationSet Then
                Clone = New CalculationResultTag(TagId, LocationId, DataType, Value)
            Else
                Clone = New CalculationResultTag(TagId, DataType, Value)
            End If
        End Function

        ''' <summary>
        ''' Adds this tag to a data row. This should be called when the calculation set is being turned into a data table.
        ''' </summary>
        ''' <param name="row">Row for the tag to be added to.</param>
        Public Sub AddTagToRow(ByVal row As DataRow)
            Dim table As DataTable = row.Table

            If Not table Is Nothing Then
                ' Add the column if it does not yet exist.
                If Not table.Columns.Contains(TagId) Then
                    table.Columns.Add(New DataColumn(TagId, DataType, ""))
                End If

                row(TagId) = Value
            End If
        End Sub


        Public Shared Sub AddTagsToRecord(ByVal tags As IEnumerable(Of CalculationResultTag), ByVal recordTable As DataTable, _
          ByVal record As CalculationResultRecord)
            Dim filteredTags As IEnumerable(Of CalculationResultTag)
            Dim tag As CalculationResultTag
            Dim row As DataRow

            ' Get all tags where location and date is not set, or where they are set but match.
            filteredTags = From t In tags _
                           Where (t.LocationSet = False And t.DateSet = False) _
                           Or (t.LocationSet = True And NullEqual(t.LocationId, record.LocationId)) _
                           Or (t.DateSet = True And NullEqual(t.CalendarDate, record.CalendarDate))

            For Each tag In filteredTags
                For Each row In recordTable.Rows
                    tag.AddTagToRow(row)
                Next
            Next
        End Sub

        ''' <summary>
        ''' Returns true if the two nullable int32's are equal, this includes both being nothing. 
        ''' </summary>
        Private Shared Function NullEqual(ByVal left As Int32?, ByVal right As Int32?) As Boolean
            Return (left.HasValue AndAlso right.HasValue AndAlso left.Value = right.Value) _
                Or (Not left.HasValue And Not right.HasValue)
        End Function

        ''' <summary>
        ''' Returns true if the two nullable datetime's are equal, this includes both being nothing. 
        ''' </summary>
        Private Shared Function NullEqual(ByVal left As DateTime?, ByVal right As DateTime?) As Boolean
            Return (left.HasValue AndAlso right.HasValue AndAlso left.Value = right.Value) _
                Or (Not left.HasValue And Not right.HasValue)
        End Function

    End Class
End Namespace
