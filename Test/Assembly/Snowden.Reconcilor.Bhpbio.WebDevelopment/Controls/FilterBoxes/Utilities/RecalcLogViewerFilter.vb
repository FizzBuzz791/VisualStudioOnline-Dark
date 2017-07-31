Imports Snowden.Common.Web.BaseHtmlControls

Namespace ReconcilorControls.FilterBoxes.Utilities
    Public Class RecalcLogViewerFilter
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.RecalcLogViewerFilter

        Protected Overrides Sub SetupFormAndDatePickers()
            MyBase.SetupFormAndDatePickers()

            ServerForm.OnSubmit = "return ValidateRecalcLogViewerFilterParameters();"
        End Sub

    End Class
End Namespace

