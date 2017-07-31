Imports Snowden.Common.Web.BaseHtmlControls.Tags

Namespace Extensibility

    Public Class FactorFormatHelper
        ' Note that these formats apply ONLY to the factor values, not the actual grade values
        ' themselves
        Public Shared Function GetFormat(ByVal gradeName As String) As String
            Select Case gradeName.ToUpper
                Case "FE" : Return "N3"
                Case Else : Return "#,##0.00"
            End Select
        End Function
    End Class

    Module StandardLibraryExtensions
        ' the Soap error messages are terrible, so we try to extract something useful from it if possible
        <Runtime.CompilerServices.Extension()>
        Public Function ShortMessage(ex As System.Web.Services.Protocols.SoapException) As String
            If Not ex.Message.Contains("Soap Fault:") Then
                Return ex.Message
            End If

            Dim errorMessage As String = ""
            Dim errorLines = ex.Message.Split("   at").First.Split(ControlChars.CrLf.ToCharArray(), StringSplitOptions.RemoveEmptyEntries).ToList()
            errorLines.RemoveRange(0, 2)

            Dim messageLine = String.Join(", ", errorLines.ToArray).Replace(".,", ",")
            errorMessage = messageLine.Replace("System.Web.Services.Protocols.SoapException: Server was unable to process request. ---&gt;", "").Trim()
            errorMessage = errorMessage.Replace("System.Web.Services.Protocols.SoapException:", "").Trim()
            Return errorMessage
        End Function

        <Runtime.CompilerServices.Extension()>
        Public Function Split(s As String, separator As String) As String()
            Return s.Split(New String() {separator}, StringSplitOptions.None)
        End Function

        <Runtime.CompilerServices.Extension()>
        Public Function Truncate(s As String, maxLength As Integer) As String
            If s.Length < maxLength Then
                Return s
            Else
                Return s.Substring(0, maxLength)
            End If
        End Function

        <Runtime.CompilerServices.Extension()>
        Public Function JavaScript(control As HtmlScriptTag, script As String) As HtmlScriptTag
            control.ScriptLanguageType = ScriptType.TextJavaScript
            control.Language = ScriptLanguage.JavaScript
            control.InnerScript = script
            Return control
        End Function


    End Module
End Namespace

