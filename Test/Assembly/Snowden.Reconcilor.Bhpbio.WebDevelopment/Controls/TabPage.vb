Imports System.Web.UI

Namespace Controls
    Public Class TabPage
        Inherits Common.Web.BaseHtmlControls.WebpageControls.TabPage

        Public Property ImageSource As String

        Public Sub New(inId As String, inTabPageScriptId As String, inPageTitle As String)
            MyBase.New(inId, inTabPageScriptId, inPageTitle)
        End Sub

        Public Sub New(inId As String, inTabPageScriptId As String, inPageTitle As String, inImgSource As String)
            MyBase.New(inId, inTabPageScriptId, inPageTitle)
            ImageSource = inImgSource
        End Sub

        Protected Overrides Sub OnPreRender(e As EventArgs)
            MyBase.OnPreRender(e)

            ' Base class inserts the title at index 0, so this is always going to work.
            Controls.RemoveAt(0)
            Controls.AddAt(0, New LiteralControl($"<h2 class=""tab-header""><div id=""left""></div><div id=""middle"">{PageTitle}<img src=""{ImageSource}"" height=""12"" width=""12""></div><div id=""right""></div></h2>"))
        End Sub

    End Class
End NameSpace