Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports OfficeOpenXml
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes.Approval
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes.Analysis
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes.Report
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace Reports
    Public Class YearlyReconciliationReport
        Inherits WebpageTemplates.ReportsTemplate

        Public Property DalUtility As IUtility

#Region "Properties"
        Private _disposed As Boolean
        Private _filterBox As AnnualReportFilterBox
        Protected Property FilterBox() As AnnualReportFilterBox
            Get
                Return _filterBox
            End Get
            Set(ByVal value As AnnualReportFilterBox)
                _filterBox = value
            End Set
        End Property

#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If (Not _filterBox Is Nothing) Then
                            _filterBox.Dispose()
                            _filterBox = Nothing
                        End If
                    End If
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region

        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("Report_40"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            With PageHeader.ScriptTags
                .Add(New HtmlScriptTag(ScriptType.TextJavaScript, ScriptLanguage.JavaScript, "../js/BhpbioLocationControl.js", ""))
                .Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/reports.js", ""))
                .Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioReports.js", ""))
            End With
        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            Dim systemStartDate As String = Convert.ToDateTime(DalUtility.GetSystemSetting("SYSTEM_START_DATE")).ToString("MM-dd-yyyy")

            FilterBox = CType(Resources.DependencyFactories.FilterBoxFactory.Create("AnnualReportFilterBox", Resources), AnnualReportFilterBox)
            FilterBox.Resources = Me.Resources
            FilterBox.GroupBoxTitle = " Annual Report "
            FilterBox.SubmitAction = "GetAnnualReport.aspx"
            FilterBox.SubmitClientAction = String.Format("return RenderBhpbioAnnualReport('{0}');", systemStartDate)
            FilterBox.LowestLocationTypeDescription = "PIT"
            FilterBox.DisplayDateBreakDown = True

            Dim startDate As DateTime
            If DateTime.TryParse(Resources.UserSecurity.GetSetting("AnnualReport_Export_Date_From"), startDate) Then
                FilterBox.StartDate = startDate
            End If

            Dim endDate As DateTime
            If DateTime.TryParse(Resources.UserSecurity.GetSetting("AnnualReport_Export_Date_To"), endDate) Then
                FilterBox.EndDate = endDate
            End If


            ReconcilorContent.ContainerContent.Controls.Add(FilterBox)
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            DalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.ConnectionString)
        End Sub

    End Class
End Namespace

