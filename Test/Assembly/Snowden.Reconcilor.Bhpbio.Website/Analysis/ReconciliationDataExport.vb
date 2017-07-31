Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.Website.Analysis
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes.Analysis
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace Analysis

    Public Class ReconciliationDataExport
        Inherits WebpageTemplates.AnalysisTemplate

        Private _disposed As Boolean
        Private _filterBox As DataExportFilterBox
        Private _dalUtility As IUtility



        Protected Property FilterBox() As DataExportFilterBox
            Get
                Return _filterBox
            End Get
            Set(ByVal value As DataExportFilterBox)
                _filterBox = value
            End Set
        End Property

        Public Property DalUtility() As IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As IUtility)
                _dalUtility = value
            End Set
        End Property

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
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("ANALYSIS_RECON_DATA_EXPORT"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            With PageHeader.ScriptTags
                .Add(New WebDevelopment.Controls.HtmlVersionedScriptTag("../js/BhpbioCommon.js"))
                .Add(New WebDevelopment.Controls.HtmlVersionedScriptTag("../js/BhpbioAnalysis.js"))
                .Add(New WebDevelopment.Controls.HtmlVersionedScriptTag("../js/BhpbioLocationControl.js"))
            End With
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            FilterBox = CType(Resources.DependencyFactories.FilterBoxFactory.Create("AnalysisDataExport", Resources), DataExportFilterBox)

            ' set filter behaviour
            FilterBox.Resources = Me.Resources
            FilterBox.GroupBoxTitle = " Reconciliation Data Export "
            FilterBox.SubmitAction = "../Reports/GetReconciliationDataExportReport.aspx"
            FilterBox.SubmitClientAction = "return RenderBhpbioDataExport();"
            FilterBox.DisplayDateBreakDown = True
            FilterBox.DisplayApprovalStatus = True
            FilterBox.DisplayLumpFines = True
            FilterBox.DisplayIncludeSublocations = True
            FilterBox.DisplayIncludeResourceClassifications = True
            FilterBox.DisplayUseForwardEstimates = Report.WebService.AllowForwardEstimatesInReconExports
            FilterBox.LowestLocationTypeDescription = "PIT"

            ' set saved user settings
            Dim locationId As Integer
            If Integer.TryParse(Resources.UserSecurity.GetSetting("Reconciliation_Data_Export_Location_Id"), locationId) Then
                FilterBox.LocationId = locationId
            End If

            Dim defaultDatesRequired As Boolean = False
            Dim startDate As DateTime
            If DateTime.TryParse(Resources.UserSecurity.GetSetting("Reconciliation_Data_Export_Date_From"), startDate) Then
                FilterBox.StartDate = startDate
            Else
                ' default dates are required as DateFrom could not be determined based on saved user settings
                defaultDatesRequired = True
            End If

            Dim endDate As DateTime
            If DateTime.TryParse(Resources.UserSecurity.GetSetting("Reconciliation_Data_Export_Date_To"), endDate) Then
                FilterBox.EndDate = endDate
            Else
                ' default dates are required as DateTo could not be determined based on saved user settings
                defaultDatesRequired = True
            End If

            If defaultDatesRequired Then
                ' if was not possible to read one or more of DateFrom or DateTo from user settings... set these to the start and end of the most recently completed month (ie last month)
                startDate = DateTime.Now.AddMonths(-1)
                ' set from to be the first of the month
                startDate = New DateTime(startDate.Year, startDate.Month, 1)
                endDate = startDate.AddMonths(1).AddDays(-1)

                FilterBox.StartDate = startDate
                FilterBox.EndDate = endDate
                FilterBox.DateBreakdown = "MONTH"
            Else
                FilterBox.DateBreakdown = Resources.UserSecurity.GetSetting("Reconciliation_Data_Export_Date_Breakdown", String.Empty)
            End If

            FilterBox.ApprovalSelection = Resources.UserSecurity.GetSetting("Reconciliation_Data_Export_Approval_Status", String.Empty)

            Dim includeLumpFines As Boolean
            If Boolean.TryParse(Resources.UserSecurity.GetSetting("Reconciliation_Data_Export_Lump_Fines"), includeLumpFines) Then
                FilterBox.IncludeLumpFines = includeLumpFines
            End If

            Dim includeSublocations As Boolean
            If Boolean.TryParse(Resources.UserSecurity.GetSetting("Reconciliation_Data_Export_Sublocations"), includeSublocations) Then
                FilterBox.IncludeSublocations = includeSublocations
            End If

            Dim includeResourceClassifications As Boolean
            If Boolean.TryParse(Resources.UserSecurity.GetSetting("Reconciliation_Data_Export_Resource_Classifications"), includeResourceClassifications) Then
                FilterBox.IncludeResourceClassifications = includeResourceClassifications
            End If

            ReconcilorContent.ContainerContent.Controls.Add(FilterBox)
        End Sub

    End Class

End Namespace