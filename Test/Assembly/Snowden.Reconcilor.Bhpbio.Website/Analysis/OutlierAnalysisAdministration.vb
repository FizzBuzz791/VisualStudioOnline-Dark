Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports System.Web.UI
Imports Snowden.Common.Web.BaseHtmlControls.Tags

Namespace Analysis
    Public Class OutlierAnalysisAdministration
        Inherits Core.WebDevelopment.WebpageTemplates.AnalysisTemplate
        Protected Overrides Sub OnPreInit(ByVal e As System.EventArgs)
            MyBase.OnPreInit(e)
        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()
            With PageHeader.ScriptTags
                .Add(New WebDevelopment.Controls.HtmlVersionedScriptTag("../js/BhpbioAnalysis.js"))
                .Add(New WebDevelopment.Controls.HtmlVersionedScriptTag("../js/BhpbioLocationControl.js"))
            End With

            Dim headerDiv As New Tags.HtmlDivTag()
            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Outlier Analysis"))
            End With

            With ReconcilorContent.ContainerContent
                .Controls.Add(headerDiv)
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
                .Controls.Add(New Tags.HtmlDivTag("itemList"))
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
                .Controls.Add(New Tags.HtmlDivTag("itemDetail"))

            End With
            If Not String.IsNullOrEmpty(RequestAsString("AnalysisGroup")) Then
                ' Comes from the Approval page
                Dim requests() As String = {RequestAsString("AnalysisGroup"), RequestAsString("MonthStart"), RequestAsString("MonthEnd"),
                    RequestAsString("LocationId"), RequestAsString("ProductSize"), RequestAsString("AttributeFilter")}
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, String.Format("GetOutlierAnalysisFilterQstr('{0}');", String.Join("','", requests))))
            Else
                ' Comes from the Analysis Menu
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetOutlierAnalysisFilter();"))
            End If

        End Sub
        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("ANALYSIS_OUTLIER_ANALYSIS"))) Then
                ReportAccessDenied()
            End If
            MyBase.HandlePageSecurity()
        End Sub

    End Class
End Namespace