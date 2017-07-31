Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.Website.Analysis
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes.Analysis

Namespace Analysis

    Public Class ProdReconciliationExport
        Inherits Analysis.ReconciliationDataExport

        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("ANALYSIS_PROD_RECON_DATA_EXPORT"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub


        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            ' get the lump fines cutover date from the settings. If its not there then we use a default of 
            ' Sept-2014
            Dim lumpFinesCutoverDate = Date.Parse("2014-09-01")
            Dim lumpFinesCutoverString = lumpFinesCutoverDate.ToString("MM-dd-yyyy")

            If DateTime.TryParse(DalUtility.GetSystemSetting("LUMP_FINES_CUTOVER_DATE"), lumpFinesCutoverDate) Then
                lumpFinesCutoverString = lumpFinesCutoverDate.ToString("MM-dd-yyyy")
            End If

            With FilterBox
                .GroupBoxTitle = " Product Reconciliation Data Export "
                .IncludeLumpFines = False
                .DisplayLumpFines = False
                .DisplayIncludeSublocations = False
                .DisplayIncludeResourceClassifications = False
                FilterBox.SubmitClientAction = String.Format("return RenderBhpbioProdDataExport('{0}');", lumpFinesCutoverString)

                .DisplayProductPicker = True
                .DalUtility = New SqlDalUtility(Resources.Connection)



            End With
            FilterBox.ProductTypeCode = Resources.UserSecurity.GetSetting("Reconciliation_Data_Export_ProductPicker", String.Empty)
        End Sub

    End Class

End Namespace