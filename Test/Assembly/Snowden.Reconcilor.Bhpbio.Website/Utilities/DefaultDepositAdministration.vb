Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.Extensibility.DependencyFactoryKeys

Namespace Utilities
    Public Class DefaultDepositAdministration
        Inherits WebpageTemplates.UtilitiesTemplate

        Private _depositSideNavigation As WebDevelopment.ReconcilorControls.SideNavigationBoxes.DepositSideNavigationBox

#Region "Properties"
        Public Property LocationFilter As ReconcilorControls.ReconcilorLocationSelector = New ReconcilorControls.ReconcilorLocationSelector

        Public Property LocationContainer As Tags.HtmlDivTag = New Tags.HtmlDivTag("LocationFilter")

        Public Property FilterForm As Tags.HtmlFormTag = New Tags.HtmlFormTag

        Public Property FilterButton As ReconcilorControls.InputTags.InputButton = New ReconcilorControls.InputTags.InputButton

        Public Property FilterTable As Tags.HtmlTableTag = New Tags.HtmlTableTag

        Public Property DepositConfiguration As Tags.HtmlDivTag = New Tags.HtmlDivTag("depositConfiguration")
#End Region

        Protected Overrides Sub OnPreInit(e As EventArgs)
            MyBase.OnPreInit(e)
        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            _depositSideNavigation = CType(Resources.DependencyFactories.SideNavigationFactory.Create(SideNavigationKeys.Deposit.ToString, Resources),
                WebDevelopment.ReconcilorControls.SideNavigationBoxes.DepositSideNavigationBox)
            _depositSideNavigation.LoadItems()
            ReconcilorContent.SideNavigation = _depositSideNavigation

            Dim cell As TableCell
            Const LABEL_WIDTH = 90
            Dim locationId As Int32 = Convert.ToInt32(Resources.UserSecurity.GetSetting("Deposit_Filter_Location", DoNotSetValues.Int32.ToString))

            With LocationFilter
                .LocationLabelCellWidth = LABEL_WIDTH
                If locationId <> DoNotSetValues.Int32 Then
                    .LocationId = locationId
                End If
                .LowestLocationTypeDescription = "Site"
            End With

            With FilterButton
                .ID = "FilterButton"
                .Text = "Refresh"
            End With

            With FilterTable
                cell = .AddCellInNewRow
                cell.Controls.Add(LocationFilter)
                cell = .AddCell
                cell.Controls.Add(FilterButton)
                cell.CssClass = "left-pad"

                .AddCellInNewRow.Controls.Add(New Tags.HtmlDivTag("DepositContent"))
            End With

            LocationContainer.Controls.Add(FilterTable)

            With FilterForm
                .ID = "FilterForm"
                .OnSubmit = "return GetDepositsForSite();"
                .Controls.Add(LocationContainer)
            End With

        End Sub

        Protected Overrides Sub SetupPageLayout()
            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript,
                Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", String.Empty))

            Dim headerDiv As New Tags.HtmlDivTag()
            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Deposit Configuration"))
            End With

            With DepositConfiguration
                .Controls.Add(FilterForm)
            End With

            With ReconcilorContent.ContainerContent
                .Controls.Add(headerDiv)
                .Controls.Add(DepositConfiguration)
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
                .Controls.Add(New Tags.HtmlDivTag("itemDetail"))
            End With

            MyBase.SetupPageLayout()
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetDepositsForSite();"))
        End Sub

    End Class
End Namespace