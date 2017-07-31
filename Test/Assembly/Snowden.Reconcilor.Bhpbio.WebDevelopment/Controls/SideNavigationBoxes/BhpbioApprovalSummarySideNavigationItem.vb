Imports System.Web.UI
Imports System.Web.UI.HtmlControls
Imports System.Windows.Forms
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes.Approval
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes

Public Class BhpbioApprovalSummarySideNavigationItem
    Inherits SideNavigationItem

    Public Sub New()

    End Sub



    Protected Sub SetupControls()


    End Sub

    Protected Overrides Sub OnPreRender(ByVal e As System.EventArgs)
        MyBase.OnPreRender(e)


        Dim navigatorDiv As New HtmlDivTag()
        With navigatorDiv
            .ID = "approvalNavigatorDiv"
        End With
        Controls.Add(navigatorDiv)

        Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript, "CallAjax('approvalNavigatorDiv', './ApprovalNavigator.aspx' , 'image');"))
    End Sub

End Class
