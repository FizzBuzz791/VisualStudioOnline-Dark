Public Module XmlReaderExtensions

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadElementAsStringWithDbNull(ByVal payload As Xml.XmlReader, _
     ByVal trimWhitespace As Boolean, ByVal nullSentinel As String) As Object
        'returns as a STRING or DBNULL

        Dim result As Object

        If payload.IsEmptyElement Then
            result = DBNull.Value
        Else
            payload.Read()

            If trimWhitespace Then
                result = payload.Value.Trim(" "c)
            Else
                result = payload.Value
            End If
        End If

        'try to replace with the sentinel if one is supplied
        If TypeOf result Is String _
         AndAlso Not nullSentinel Is Nothing _
         AndAlso DirectCast(result, String) = nullSentinel Then
            result = DBNull.Value
        End If

        Return result
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadElementAsStringWithDbNull(ByVal payload As Xml.XmlReader, _
     ByVal trimWhitespace As Boolean) As Object
        Return payload.ReadElementAsStringWithDbNull(trimWhitespace, Nothing)
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadElementAsStringWithDbNull(ByVal payload As Xml.XmlReader) As Object
        Return payload.ReadElementAsStringWithDbNull(True, Nothing)
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadElementAsStringWithDbNull(ByVal payload As Xml.XmlReader, _
     ByVal nullSentinel As String) As Object
        Return payload.ReadElementAsStringWithDbNull(True, nullSentinel)
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadElementAsDatetimeWithDbNull(ByVal payload As Xml.XmlReader, _
     ByVal nullSentinel As String) As Object
        'returns either:
        '* a DATETIME (where it's valid)
        '* a STRING (where it's not valid)
        '* a DBNULL (where it's a missing element)

        Dim dateResult As DateTime
        Dim result As Object

        result = payload.ReadElementAsStringWithDbNull(True, nullSentinel)

        'try to convert to a datetime... if it succeeds then change to a datetime result
        If Not (result Is DBNull.Value) Then
            If DateTime.TryParse(DirectCast(result, String), dateResult) Then
                result = dateResult
            End If
        End If

        Return result
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadElementAsDatetimeWithDbNull(ByVal payload As Xml.XmlReader) As Object
        Return payload.ReadElementAsDatetimeWithDbNull(Nothing)
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadElementAsDoubleWithDbNull(ByVal payload As Xml.XmlReader, _
     ByVal nullSentinel As String) As Object
        'returns either:
        '* a DOUBLE (where it's valid)
        '* a STRING (where it's not valid)
        '* a DBNULL (where it's a missing element)

        Dim doubleResult As Double
        Dim result As Object

        result = payload.ReadElementAsStringWithDbNull(True, nullSentinel)

        'try to convert to a datetime... if it succeeds then change to a datetime result
        If Not (result Is DBNull.Value) Then
            If Double.TryParse(DirectCast(result, String), doubleResult) Then
                result = doubleResult
            End If
        End If

        Return result
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadElementAsDoubleWithDbNull(ByVal payload As Xml.XmlReader) As Object
        Return payload.ReadElementAsDoubleWithDbNull(DirectCast(Nothing, String))
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadElementAsDoubleWithDbNull(ByVal payload As Xml.XmlReader, _
     ByVal nullSentinel As Double) As Object
        'returns either:
        '* a DOUBLE (where it's valid)
        '* a STRING (where it's not valid)
        '* a DBNULL (where it's a missing element)

        Dim doubleResult As Double
        Dim result As Object

        result = payload.ReadElementAsStringWithDbNull(True)

        'try to convert to a datetime... if it succeeds then change to a datetime result
        'if the value returned matches the sentinel then make it null
        If Not (result Is DBNull.Value) Then
            If Double.TryParse(DirectCast(result, String), doubleResult) Then
                If doubleResult = nullSentinel Then
                    result = DBNull.Value
                Else
                    result = doubleResult
                End If
            End If
        End If

        Return result
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadElementAsInt32WithDbNull(ByVal payload As Xml.XmlReader, _
     ByVal nullSentinel As String) As Object
        'returns either:
        '* a INT32 (where it's valid)
        '* a STRING (where it's not valid)
        '* a DBNULL (where it's a missing element)

        Dim int32Result As Int32
        Dim result As Object

        result = payload.ReadElementAsStringWithDbNull(True, nullSentinel)

        'try to convert to a datetime... if it succeeds then change to a datetime result
        If Not (result Is DBNull.Value) Then
            If Int32.TryParse(DirectCast(result, String), int32Result) Then
                result = int32Result
            End If
        End If

        Return result
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadElementAsInt32WithDbNull(ByVal payload As Xml.XmlReader) As Object
        Return payload.ReadElementAsDoubleWithDbNull(DirectCast(Nothing, String))
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadElementAsSingleWithDbNull(ByVal payload As Xml.XmlReader, _
     ByVal nullSentinel As String) As Object
        'returns either:
        '* a SINGLE (where it's valid)
        '* a STRING (where it's not valid)
        '* a DBNULL (where it's a missing element)

        Dim singleResult As Single
        Dim result As Object

        result = payload.ReadElementAsStringWithDbNull(True, nullSentinel)

        'try to convert to a datetime... if it succeeds then change to a datetime result
        If Not (result Is DBNull.Value) Then
            If Single.TryParse(DirectCast(result, String), singleResult) Then
                result = singleResult
            End If
        End If

        Return result
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadElementAsSingleWithDbNull(ByVal payload As Xml.XmlReader) As Object
        Return payload.ReadElementAsSingleWithDbNull(DirectCast(Nothing, String))
    End Function

    <System.Runtime.CompilerServices.Extension()> _
    Public Function ReadElementAsSingleWithDbNull(ByVal payload As Xml.XmlReader, _
     ByVal nullSentinel As Single) As Object
        'returns either:
        '* a SINGLE (where it's valid)
        '* a STRING (where it's not valid)
        '* a DBNULL (where it's a missing element)

        Dim singleResult As Single
        Dim result As Object

        result = payload.ReadElementAsStringWithDbNull(True)

        'try to convert to a datetime... if it succeeds then change to a datetime result
        'if the value returned matches the sentinel then make it null
        If Not (result Is DBNull.Value) Then
            If Single.TryParse(DirectCast(result, String), singleResult) Then
                If singleResult = nullSentinel Then
                    result = DBNull.Value
                Else
                    result = singleResult
                End If
            End If
        End If

        Return result
    End Function
End Module
