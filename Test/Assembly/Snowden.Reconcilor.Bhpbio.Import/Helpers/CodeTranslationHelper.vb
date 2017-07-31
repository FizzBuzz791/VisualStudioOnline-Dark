Public Class CodeTranslationHelper

    Private Shared _relevantGrades As String() = Nothing
    Public Shared GEOMET_TYPE_NA As String = "NA"
    Public Shared GEOMET_TYPE_AS_SHIPPED As String = "As-Shipped"
    Public Shared GEOMET_TYPE_AS_DROPPED As String = "As-Dropped"


    Public Shared ReadOnly Property RelevantGrades() As String()
        Get
            If (_relevantGrades Is Nothing) Then
                _relevantGrades = ReferenceDataCachedHelper.GetGradeList().ToArray()
            End If

            Return _relevantGrades
        End Get
    End Property


    Private Sub New()
        'prevent instantiation
    End Sub

    Public Shared Function GetRelevantGrade(ByVal gradeName As Object) As String

        If TypeOf gradeName Is String Then
            ' these are a special set of grades that get sent by BH for the RC data. They are used by the
            ' ReconBlockInsertUpdate import, but they don't get inserted into the Staging Grade table - they
            ' go into the StageBlockModelResourceClassification table
            If gradeName.ToString.Contains("ResourceClassification") Then
                Return gradeName.ToString
            End If

            For Each grade As String In RelevantGrades
                If grade.Equals(DirectCast(gradeName, String), StringComparison.InvariantCultureIgnoreCase) Then
                    Return grade
                End If
            Next
        End If

        Return Nothing
    End Function

    Public Shared Function GradeCodeBhpbioToReconcilor(ByVal gradeCode As String) As String

        For Each gradeName As String In RelevantGrades
            If gradeName.Equals(gradeCode, StringComparison.InvariantCultureIgnoreCase) Then
                Return gradeName
            End If
        Next

        Return Nothing
    End Function

    Public Shared Function ToGeometTypeString(ByVal value As Object) As String
        Dim geometType As String = GEOMET_TYPE_NA

        If (IsNothing(value) OrElse value Is DBNull.Value OrElse String.IsNullOrEmpty(value.ToString())) Then
            ' do nothing.. Geomet type is not applicable
        Else
            geometType = value.ToString()
        End If

        Return geometType
    End Function


    Public Shared Function HubCodeMESToReconcilor(ByVal siteCode As String) As String
        Select Case siteCode.ToUpper
            Case "MAC" : Return "AreaC"
            Case "YND" : Return "Yandi"
            Case "NHG" : Return "NJV"
            Case "YR" : Return "Yarrie"
            Case "GWY" : Return "Yarrie"
            Case "JMB" : Return "Jimblebar"
            Case "JIM" : Return "Jingbao"
            Case Else : Return Nothing
        End Select
    End Function

    Public Shared Function Mq2SiteToReconcilor(ByVal siteCode As String) As String
        Select Case siteCode.ToUpper
            Case "WB" : Return "Newman"
            Case "MW" : Return "Newman"
            Case "YD" : Return "Yandi"
            Case "AC" : Return "AreaC"
            Case "JB" : Return "Jimblebar"
            Case "JH" : Return "Jimblebar"
            Case "18" : Return "OB18"
            Case "25" : Return "Eastern Ridge"
            Case "NM" : Return "Yarrie"
            Case "YR" : Return "Yarrie"
            Case "CN" : Return "Yarrie"
            Case "25, MW" : Return "Newman"
            Case "MW, 25" : Return "Newman"
            Case Else : Return Nothing
        End Select
    End Function

    ''' <summary>
    ''' Handle the translation of block related site data to Reconcilor codes
    ''' </summary>
    ''' <param name="siteCode">the site code as specified in source systems for Block data</param>
    ''' <returns>The Reconcilor equivalent code</returns>
    Public Shared Function BlockDataSiteToReconcilor(ByVal siteCode As String) As String
        Select Case siteCode.ToUpper
            Case "OB23/25" : Return "Eastern Ridge"
            Case Else : Return siteCode
        End Select
    End Function

    Public Shared Function Mq2HubToReconcilor(ByVal hubCode As String) As String
        Select Case hubCode.ToUpper
            Case "NH" : Return "NJV"
            Case Else : Return Nothing
        End Select
    End Function

    Public Shared Function SiteCodeFromReconcilor(ByVal siteCode As String, Optional ByVal toShortCode As Boolean = True) As IList(Of String)
        Dim result As New List(Of String)

        If (toShortCode) Then
            ' Conversion from a site name, to a short-form code.. or from a Reconcilor short-code to a source system short code (if different)
            Select Case siteCode.ToLower
                Case "Newman".ToLower
                    result.Add("WB")
                    result.Add("MW")
                Case "Yandi".ToLower
                    result.Add("YD")
                Case "AreaC".ToLower
                    result.Add("AC")
                Case "Jimblebar".ToLower
                    result.Add("JB")
                Case "OB18".ToLower
                    result.Add("18")
                Case "Eastern Ridge".ToLower
                    result.Add("25")
                Case "ER".ToLower
                    result.Add("25")
                Case "Yarrie".ToLower
                    result.Add("NM")
                    result.Add("YR")
                    result.Add("CN")
                Case Else
                    result.Add(siteCode.ToUpper)
            End Select
        Else
            ' Conversion from a site name, to a long form code suitable for source systems
            Select Case siteCode.ToLower
                Case "Eastern Ridge".ToLower
                    result.Add("OB23/25")
                Case Else
                    result.Add(siteCode.ToUpper)
            End Select
        End If

        Return result
    End Function

    ''' <summary>
    ''' Converts a site code as used by reconcilor to an equivalent for source systems in either short or long code form
    ''' </summary>
    ''' <param name="siteCode">the site code to convert</param>
    ''' <param name="toShortCode">if true, the code will be converted from long form to short</param>
    ''' <returns>The converted code, or the original code if no conversion was made</returns>
    Public Shared Function SingleSiteCodeFromReconcilor(ByVal siteCode As String, Optional ByVal toShortCode As Boolean = True) As String
        Dim result As IList(Of String) = SiteCodeFromReconcilor(siteCode, toShortCode)

        If (Not result Is Nothing) AndAlso result.Count = 1 Then
            Return result.First()
        Else
            ' return the passed in code as no clear mapping
            Return siteCode
        End If
    End Function

    Public Shared Function RecodeTransaction(ByVal code As String, ByVal type As String, _
     ByVal site As String) As String

        Dim blockCode As String()
        Dim pit As String
        Dim bench As String
        Dim patternNumber As String
        Dim blockName As String

        If (type <> "Blast Block") Then
            'prefix with the site name
            Return (site & "-" & code)
        ElseIf (type = "Blast Block") Then
            'split the code into its constituent bits (separated by the "-")
            blockCode = code.Split("-"c)
            If blockCode.Length = 4 Then
                pit = blockCode(0)
                bench = blockCode(1)
                patternNumber = blockCode(2)
                blockName = blockCode(3)

                Return CorrectPit(pit) & "-" & CorrectBench(bench) & "-" & _
                 CorrectPatternNumber(patternNumber) & "-" & CorrectBlockName(blockName)
            Else
                'if the code isn't quite right then return it unchanged
                Return code
            End If
        Else
            'return the code unchanged
            Return code
        End If
    End Function

    Public Shared Function CorrectPit(ByVal pit As String) As String
        Dim scrubbedPit As String

        'Pit - (2to3)P

        'ensure the Pit is clean
        'only remove leading/trailing whitespace
        scrubbedPit = pit.Trim(" "c).ToUpper

        Return scrubbedPit
    End Function

    Public Shared Function CorrectBench(ByVal bench As String) As String
        Dim scrubbedBench As String

        'Bench-bbbb

        'ensure the Bench is clean and padded to 4 characters
        scrubbedBench = bench.Trim(" "c).ToUpper
        If scrubbedBench.Length = 1 Then
            scrubbedBench = "000" & scrubbedBench
        ElseIf scrubbedBench.Length = 2 Then
            scrubbedBench = "00" & scrubbedBench
        ElseIf scrubbedBench.Length = 3 Then
            scrubbedBench = "0" & scrubbedBench
        End If

        Return scrubbedBench
    End Function

    Public Shared Function CorrectPatternNumber(ByVal patternNumber As String) As String
        Dim scrubbedPatternNumber As String

        'Pattern-pppp

        'ensure the Pattern is clean
        scrubbedPatternNumber = patternNumber.Trim(" "c).ToUpper
        If scrubbedPatternNumber.Length = 1 Then
            scrubbedPatternNumber = "000" & scrubbedPatternNumber
        ElseIf scrubbedPatternNumber.Length = 2 Then
            scrubbedPatternNumber = "00" & scrubbedPatternNumber
        ElseIf scrubbedPatternNumber.Length = 3 Then
            scrubbedPatternNumber = "0" & scrubbedPatternNumber
        End If

        Return scrubbedPatternNumber
    End Function

    Public Shared Function CorrectBlockName(ByVal blockName As String) As String
        Dim scrubbedBlockName As String

        'BlockName-(1to5)n

        'ensure the BlockName is clean
        scrubbedBlockName = blockName.Trim(" "c).ToUpper
        If scrubbedBlockName.Length > 1 Then
            'remove any leading 0's
            'if they were all zero's - make sure we have one left!
            scrubbedBlockName = scrubbedBlockName.TrimStart("0"c)
            If scrubbedBlockName.Length = 0 Then
                scrubbedBlockName = "0"
            End If
        End If

        Return scrubbedBlockName
    End Function

    Public Shared Function GenerateBlockCode(ByVal blockName As String, ByVal pit As String, _
     ByVal bench As String, ByVal patternNumber As String) As String
        Return pit & "-" & bench & "-" & patternNumber & "-" & blockName
    End Function
End Class
