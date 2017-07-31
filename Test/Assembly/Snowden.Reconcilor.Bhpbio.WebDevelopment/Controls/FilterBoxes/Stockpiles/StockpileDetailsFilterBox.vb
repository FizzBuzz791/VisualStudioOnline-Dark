Imports Snowden.Common.Web.BaseHtmlControls

Namespace ReconcilorControls.FilterBoxes.Stockpiles
    Public Class StockpileDetailsFilterBox
        Inherits Reconcilor.Core.WebDevelopment.ReconcilorControls.FilterBoxes.Stockpiles.StockpileDetailsFilterBox

        Protected Overrides Sub SetupFormAndDatePickers()
            MyBase.SetupFormAndDatePickers()
            ServerForm.OnSubmit = "return ValidateStockpileDetailsFilterParameters();"
        End Sub
    End Class
End Namespace
