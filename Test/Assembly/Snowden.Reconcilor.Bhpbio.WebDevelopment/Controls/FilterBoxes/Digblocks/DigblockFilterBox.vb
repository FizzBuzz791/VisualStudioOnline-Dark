Imports Snowden.Common.Web.BaseHtmlControls

Namespace ReconcilorControls.FilterBoxes.Digblocks
    Public Class DigblockFilterBox
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.Digblocks.DigblockFilterBox

        Protected Overrides Sub SetupFormAndDatePickers()
            MyBase.SetupFormAndDatePickers()
            ServerForm.OnSubmit = "return ValidateDigblockFilterParameters();"
        End Sub
    End Class
End Namespace

