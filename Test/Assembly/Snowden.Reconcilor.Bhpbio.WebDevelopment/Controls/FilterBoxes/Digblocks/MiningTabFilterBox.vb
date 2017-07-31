Imports Snowden.Common.Web.BaseHtmlControls

Namespace ReconcilorControls.FilterBoxes.Digblocks
    Public Class MiningTabFilterBox
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.Digblocks.MiningTabFilterBox

        Protected Overrides Sub SetupFormAndDatePickers()
            MyBase.SetupFormAndDatePickers()
            FilterButton.OnClientClick = "return ValidateDigblockDetailFilterParameters();"
        End Sub

    End Class
End Namespace
