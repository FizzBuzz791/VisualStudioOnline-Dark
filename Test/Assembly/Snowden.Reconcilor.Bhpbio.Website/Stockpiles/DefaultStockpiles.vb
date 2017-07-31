Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment

Namespace Stockpiles
    Public Class DefaultStockpiles
        Inherits Core.Website.Stockpiles.DefaultStockpiles

#Region " Const "
        Public Const TIMESTAMPFORMAT = "yyyy-MM-dd"
#End Region

#Region " Properties "
        Private Property SelectedMonth As DateTime
        Private Property LocationId As Integer
#End Region

        Public Sub New()
            MyBase.New()

            StockpileFilter = New ReconcilorControls.FilterBoxes.Stockpiles.StockpileFilterBox()
        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            With PageHeader.ScriptTags
                .Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioAnalysis.js", ""))
                .Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioStockpiles.js", ""))
            End With
        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            Dim stockpileTerm As String = Core.WebDevelopment.ReconcilorFunctions.GetSiteTerminology("Stockpile")

            ReconcilorContent.SideNavigation.TryRemoveItem("STOCKPILE_ADD")
            ReconcilorContent.SideNavigation.TryRemoveItem("STOCKPILE_SURVEY_LIST")
            ReconcilorContent.SideNavigation.AddItem("UTILITIES_STOCKPILE_GROUP",
                                                     New Core.WebDevelopment.ReconcilorControls.SideNavigationBoxes.SideNavigationLinkItem(
                                                         New Tags.HtmlAnchorTag("../Utilities/ReferenceStockpileGroupAdministration.aspx", "",
                                                                                "Manage " & stockpileTerm & " Groups", ""),
                                                         New Tags.HtmlImageTag("../images/showAll.gif")))
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub SetupFinalJavascriptCalls()

            If (LocationId <> 0) Then
                Dim jscall = String.Format("GetStockpileListLocationDate({0},'{1:dd-MMM-yyyy}','{2:dd-MMM-yyyy}','{3}',{4},'{5}');", LocationId, SelectedMonth,
                                           SelectedMonth.AddMonths(1).AddDays(-1), StockpileFilter.LocationFilter.LocationDiv.ID,
                                           StockpileFilter.LocationFilter.LocationLabelCellWidth, StockpileFilter.LocationFilter.LowestLocationTypeDescription)
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, jscall))
            End If

            MyBase.SetupFinalJavaScriptCalls()
        End Sub

        Protected Overrides Sub OnPreInit(e As EventArgs)
            MyBase.OnPreInit(e)

            If Not Request("SelectedMonth") Is Nothing Then
                SelectedMonth = RequestAsDateTime("SelectedMonth")
            End If

            If Not Request("LocationId") Is Nothing Then
                LocationId = RequestAsInt32("LocationId")
            End If
        End Sub
    End Class
End Namespace