Imports Snowden.Common.Web.BaseHtmlControls

Namespace ReconcilorControls.FilterBoxes.Utilities
    Public Class EventViewerFilter
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.EventViewerFilter

        Protected Overrides Sub SetupFormAndDatePickers()
            MyBase.SetupFormAndDatePickers()
            ServerForm.OnSubmit = "return ValidateEventFilterParameters();"
        End Sub

    End Class
End Namespace
