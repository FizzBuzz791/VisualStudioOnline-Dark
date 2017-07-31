Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.Website.Analysis
Imports System.Web.UI
Imports System.Web.UI.WebControls

Namespace Analysis
    Public Class DigblockSpatialAdministration
        Inherits Core.Website.Analysis.DigblockSpatialAdministration

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            With PageHeader.ScriptTags
                .Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioAnalysis.js", ""))
            End With
        End Sub

        Protected Overrides Sub SetupPageControls()
            Dim locationFilter As ReconcilorControls.ReconcilorLocationSelector

            locationFilter = New ReconcilorControls.ReconcilorLocationSelector()
            locationFilter.OnChange = "getVarianceLegend"
            FilterBox.LocationFilter = locationFilter

            MyBase.SetupPageControls()
        End Sub

        'Protected Overrides Function DrawLegend() As ReconcilorControls.GroupBox
        '    Dim div As New Tags.HtmlDivTag("legendDiv")
        '    Dim groupBox As New ReconcilorControls.GroupBox("Legend")
        '    groupBox.Controls.Add(div)
        '    Return groupBox
        'End Function
    End Class
End Namespace