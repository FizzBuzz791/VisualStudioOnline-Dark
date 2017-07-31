Imports System.Runtime.CompilerServices
Imports System.Web.UI

Namespace Utilities
	<HideModuleName()> _
	Public Module ResolveUrlExtension
		'''<summary>
		'''Extension Method to correctly resolve page's URL. Should be used to avoid broken images and links. Works for websites and web applications.
		'''</summary>
		<Extension()> _
		Public Function ResolveUrlExt(ByVal currentPage As Page, ByVal applicationPath As String, ByVal absoluteUri As String, ByVal rawUrl As String) As String
			If applicationPath = "/" Then 'Is WebSite
				Dim length As Integer = absoluteUri.LastIndexOf("/")
				If length > 0 Then
					Dim result As String = absoluteUri.Substring(0, length)
					Return result
				End If
			End If ' Is Virtual Dir
			Return applicationPath
		End Function
		'''<summary>
		'''Extension Method to correctly resolve page's URL. It also removes characters after the last '/'. Should be used to avoid broken images and links. Works for websites and web applications.
		'''</summary>
		<Extension()> _
		Public Function ResolveUrlExtRemoving(ByVal currentPage As Page, ByVal ApplicationPath As String, ByVal AbsoluteUri As String, ByVal RawUrl As String) As String
			If ApplicationPath = "/" Then 'Is WebSite
				Dim url As String = AbsoluteUri.Substring(0, AbsoluteUri.LastIndexOf("/"))
				url = url.Remove(url.LastIndexOf("/"))
				Return url
			End If ' Is Virtual Dir
			Return ApplicationPath
		End Function
	End Module
End Namespace