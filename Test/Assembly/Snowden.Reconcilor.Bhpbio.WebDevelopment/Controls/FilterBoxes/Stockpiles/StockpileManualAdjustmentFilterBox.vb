Imports System.Web.UI
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorFunctions
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.FilterBoxes

Namespace ReconcilorControls.FilterBoxes.Stockpiles
    Public Class StockpileManualAdjustmentFilterBox
        Inherits Reconcilor.Core.WebDevelopment.ReconcilorControls.FilterBoxes.Stockpiles.StockpileManualAdjustmentFilterBox

        Protected Overrides Sub SetupControls()
            MyBase.SetupControls()
            LocationFilter.LowestLocationTypeDescription = "SITE"
        End Sub

        Protected Overrides Sub SetupFormAndDatePickers()
            MyBase.SetupFormAndDatePickers()
            ServerForm.OnSubmit() = "return ValidateBhpbioStockpileManualAdjustmentList();"
        End Sub
        
    End Class
End Namespace

