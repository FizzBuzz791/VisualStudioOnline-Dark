Imports Snowden.Common.Web.BaseHtmlControls

Namespace ReconcilorControls.FilterBoxes.Digblocks
    Public Class TransactionsFilterBox
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.Digblocks.TransactionsFilterBox

        Protected Overrides Sub SetupFormAndDatePickers()
            MyBase.SetupFormAndDatePickers()
            FilterButton.OnClientClick = "return ValidateTransactionDetailFilterParameters();"
        End Sub

    End Class
End Namespace
