Namespace Utilities
	Public Class HaulageCorrectionNameResolution
		Inherits Core.Website.Utilities.HaulageCorrectionNameResolution

		Protected Overrides Sub SetupPageLayout()
			MyBase.SetupPageLayout()

			' Remove the Bulk Record Correction and Haulage Splitting links on the side menu
            ReconcilorContent.SideNavigation.TryRemoveItem("UTILITIES_HAULAGE_BULK_CORRECTION")
            ReconcilorContent.SideNavigation.TryRemoveItem("UTILITIES_HAULAGE_SPLITTING")
        End Sub

	End Class
End Namespace

