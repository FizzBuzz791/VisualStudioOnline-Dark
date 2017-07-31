Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes.Utilities
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags

Namespace Utilities
    Public Class DefaultLumpFinesAdministration
        Inherits WebpageTemplates.UtilitiesTemplate

        Private _searchFilter As DefaultLumpFinesFilterBox
        Private _addButton As New InputButtonFormless
        Private _cancelButton As New InputButtonFormless

        Protected Property SearchFilter() As DefaultLumpFinesFilterBox
            Get
                Return _searchFilter
            End Get
            Set(ByVal value As DefaultLumpFinesFilterBox)
                _searchFilter = value
            End Set
        End Property

        Protected Overrides Sub OnPreInit(ByVal e As System.EventArgs)
            MyBase.OnPreInit(e)

            SearchFilter = CType(Resources.DependencyFactories.FilterBoxFactory.Create("DefaultLumpFines", Resources),  _
                     DefaultLumpFinesFilterBox)
        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
                Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", String.Empty))

            _searchFilter = CType(Resources.DependencyFactories.FilterBoxFactory.Create("DefaultLumpFines", Resources), DefaultLumpFinesFilterBox)

            _addButton.OnClientClick = "return AddDefaultLumpFines();"
            _addButton.Text = "Add New"
            If Not Resources.UserSecurity.HasAccess("BHPBIO_DEFAULT_LUMP_FINES_EDIT") Then
                _addButton.Disabled = True
            End If

            _cancelButton.OnClientClick = "window.location='./Default.aspx'"
            _cancelButton.Text = " Cancel "

            Dim headerDiv As New Tags.HtmlDivTag()
            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Default Lump Fines"))
            End With

            Dim itemDiv As New Tags.HtmlDivTag("itemDetail")
            itemDiv.StyleInline = "width:500px;"

            With ReconcilorContent.ContainerContent
                .Controls.Add(headerDiv)
                .Controls.Add(SearchFilter)
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
                .Controls.Add(New Tags.HtmlDivTag("itemList"))
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
                .Controls.Add(_addButton)
                .Controls.Add(New LiteralControl("&nbsp;&nbsp;"))
                .Controls.Add(_cancelButton)
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
                .Controls.Add(itemDiv)
            End With

            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetDefaultLumpFinesList();"))
        End Sub
    End Class
End Namespace
