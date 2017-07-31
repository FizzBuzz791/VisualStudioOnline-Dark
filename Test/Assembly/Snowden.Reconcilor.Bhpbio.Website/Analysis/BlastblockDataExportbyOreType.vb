Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes.Approval
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes.Analysis

Namespace Analysis
    Public Class BlastblockDataExportOreType
        Inherits AnalysisTemplate

#Region "Properties"
        Private _disposed As Boolean
        Private _filterBox As DataExportFilterBox

        Protected Property FilterBox() As DataExportFilterBox
            Get
                Return _filterBox
            End Get
            Set(ByVal value As DataExportFilterBox)
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
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("ANALYSIS_BLASTBLOCK_DATA_EXPORT_ORE_TYPE"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            With PageHeader.ScriptTags
                .Add(New WebDevelopment.Controls.HtmlVersionedScriptTag("../js/BhpbioAnalysis.js"))
                .Add(New WebDevelopment.Controls.HtmlVersionedScriptTag("../js/BhpbioLocationControl.js"))
            End With
        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            FilterBox = CType(Resources.DependencyFactories.FilterBoxFactory.Create("AnalysisDataExport", Resources), DataExportFilterBox)

            FilterBox.Resources = Me.Resources
            FilterBox.GroupBoxTitle = " Blastblock Data by Ore Type Export "
            FilterBox.SubmitAction = "../Reports/GetBlastblockOreTypeDataExportReport.aspx"
            FilterBox.SubmitClientAction = "return RenderBhpbioDataExport();"
            FilterBox.LowestLocationTypeDescription = "PIT"
            FilterBox.DisplayApprovalStatus = True
            FilterBox.DisplayLumpFines = True

            ' set saved user settings
            Dim locationId As Integer
            If Integer.TryParse(Resources.UserSecurity.GetSetting("Blastblock_OreTyepe_Data_Export_Location_Id"), locationId) Then
                FilterBox.LocationId = locationId
            End If

            Dim defaultDatesRequired As Boolean = False
            Dim startDate As DateTime
            If DateTime.TryParse(Resources.UserSecurity.GetSetting("Blastblock_OreTyepe_Data_Export_Date_From"), startDate) Then
                FilterBox.StartDate = startDate
            Else
                ' default dates are required as DateFrom could not be determined based on saved user settings
                defaultDatesRequired = True
            End If

            Dim endDate As DateTime
            If DateTime.TryParse(Resources.UserSecurity.GetSetting("Blastblock_OreTyepe_Data_Export_Date_To"), endDate) Then
                FilterBox.EndDate = endDate
            Else
                ' default dates are required as DateTo could not be determined based on saved user settings
                defaultDatesRequired = True
            End If

            Dim includeLumpFines As Boolean
            If Boolean.TryParse(Resources.UserSecurity.GetSetting("Blastblock_OreTyepe_Data_Export_Lump_Fines"), includeLumpFines) Then
                FilterBox.IncludeLumpFines = includeLumpFines
            End If

            If defaultDatesRequired Then
                ' if was not possible to read one or more of DateFrom or DateTo from user settings... set these to the start and end of the most recently completed month (ie last month)
                startDate = DateTime.Now.AddMonths(-1)
                ' set from to be the first of the month
                startDate = New DateTime(startDate.Year, startDate.Month, 1)
                endDate = startDate.AddMonths(1).AddDays(-1)

                FilterBox.StartDate = startDate
                FilterBox.EndDate = endDate
            End If

            FilterBox.ApprovalSelection = Resources.UserSecurity.GetSetting("Blastblock_OreTyepe_Data_Export_Approval_Status", String.Empty)

            ReconcilorContent.ContainerContent.Controls.Add(FilterBox)
        End Sub

    End Class
End Namespace

