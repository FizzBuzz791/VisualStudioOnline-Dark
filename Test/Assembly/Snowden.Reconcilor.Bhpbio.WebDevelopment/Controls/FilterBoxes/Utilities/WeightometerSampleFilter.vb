Imports Snowden.Common.Web.BaseHtmlControls

Namespace ReconcilorControls.FilterBoxes.Utilities
    Public Class WeightometerSampleFilter
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.WeightometerSampleFilter

        Private _lowestLocationTypeDescription As String = "Site"

        Protected Overrides Sub SetupFormAndDatePickers()
            MyBase.SetupFormAndDatePickers()
            ServerForm.OnSubmit = "return ValidateWeightometerSampleFilterParameters();"
        End Sub

        Protected Overrides Sub SetupControls()
            MyBase.SetupControls()

            With LayoutGroupBox
                .Width = 700
            End With

            LocationFilter.LowestLocationTypeDescription = _lowestLocationTypeDescription
        End Sub

    End Class
End Namespace

