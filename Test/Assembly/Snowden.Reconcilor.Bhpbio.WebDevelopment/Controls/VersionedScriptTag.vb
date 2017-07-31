Imports System.Reflection.Assembly
Imports Snowden.Common.Web.BaseHtmlControls.Tags

Namespace Controls

    Public Class HtmlVersionedScriptTag
        Inherits HtmlScriptTag

        Public Sub New(path As String)
            MyBase.New(
                ScriptType.TextJavaScript,
                ScriptLanguage.JavaScript,
                path,
                ""
            )

            If Not Source.EndsWith(".js") Then
                ' no inline scripts, make sure this is only given a path to a js file...
                Throw New Exception("Not a .js file. Inline scripts cannot be used with versioned script tags")
            End If

            ' change the script source to include the version number. When this changes it will force the client
            ' to get the latest version of it
            Dim versionString = GetAssembly(GetType(HtmlVersionedScriptTag)).GetName().Version.ToString()
            Source = String.Format("{0}?v={1}", Source, versionString)

        End Sub

    End Class
End Namespace
