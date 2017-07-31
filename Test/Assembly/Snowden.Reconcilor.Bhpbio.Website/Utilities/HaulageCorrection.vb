Imports Snowden.Common.Web.BaseHtmlControls

Namespace Utilities
    Public Class HaulageCorrection
        Inherits Core.Website.Utilities.HaulageCorrection


#Region " Properties "
        Private _dalSecurityLocation As Bhpbio.Database.DalBaseObjects.ISecurityLocation

        Public Property DalSecurityLocation() As Bhpbio.Database.DalBaseObjects.ISecurityLocation
            Get
                Return _dalSecurityLocation
            End Get
            Set(ByVal value As Bhpbio.Database.DalBaseObjects.ISecurityLocation)
                _dalSecurityLocation = value
            End Set
        End Property

#End Region

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()
            With PageHeader.ScriptTags
                .Add(New WebDevelopment.Controls.HtmlVersionedScriptTag("../js/BhpbioUtilities.js"))
            End With

            DirectCast(HaulageCorrectionFilter, Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.HaulageCorrectionFilter).DalSecurityLocation = DalSecurityLocation
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalSecurityLocation Is Nothing) Then
                DalSecurityLocation = New Bhpbio.Database.SqlDal.SqlDalSecurityLocation(Resources.Connection)
            End If

            If (DalHaulage Is Nothing) Then
                DalHaulage = New Bhpbio.Database.SqlDal.SqlDalHaulage(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            LocationId = Convert.ToInt32(Resources.UserSecurity.GetSetting("Haulage_Correction_Filter_Location", "-1"))
            If Not Request("LocationId") Is Nothing Then
                LocationId = RequestAsInt32("LocationId")
                Resources.UserSecurity.SetSetting("Haulage_Correction_Filter_Location", LocationId.ToString())
            End If
        End Sub

        Protected Overrides Sub SetupPageLayout()
            Dim cont As System.Web.UI.Control
            MyBase.SetupPageLayout()

            ReconcilorContent.SideNavigation.TryRemoveItem("UTILITIES_HAULAGE_BULK_CORRECTION")
            ReconcilorContent.SideNavigation.TryRemoveItem("UTILITIES_HAULAGE_SPLITTING")

            DirectCast(HaulageCorrectionFilter, Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.HaulageCorrectionFilter).LocationId = LocationId

            For Each cont In Controls
                If TypeOf (cont) Is Tags.HtmlScriptTag Then
                    If DirectCast(cont, Tags.HtmlScriptTag).InnerScript = "GetHaulageCorrectionList();" Then
                        Controls.Remove(cont)
                    End If
                End If
            Next
        End Sub

        Protected Overrides Sub SetupFinalJavascriptCalls()
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "AjaxFinalCall = 'GetHaulageCorrectionList();';"))

            MyBase.SetupFinalJavaScriptCalls()
        End Sub
    End Class
End Namespace

