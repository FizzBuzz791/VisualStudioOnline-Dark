Imports Snowden.Reconcilor.Bhpbio.WebDevelopment

Namespace Reports
    Public Class ReportsView
        Inherits Core.Website.Reports.ReportsView

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            ReconcilorHeader.Controls.Add(New Controls.HtmlVersionedScriptTag("../js/BhpbioCommon.js"))
            ReconcilorHeader.Controls.Add(New Controls.HtmlVersionedScriptTag("../js/BhpbioReports.js"))
            ReconcilorHeader.Controls.Add(New Controls.HtmlVersionedScriptTag("../js/BhpbioLocationControl.js"))

            RenderScript.InnerScript &= "AjaxFinalCall = 'SetupReportMonthControl();';"
        End Sub

    End Class


End Namespace


