Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.Extensibility.DependencyFactoryKeys
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.Website.Internal.SettingsModule

Namespace Utilities
    Public Class DefaultSampleStationsAdministration
        Inherits WebpageTemplates.UtilitiesTemplate

        Public Property LocationFilter As ReconcilorControls.ReconcilorLocationSelector = New ReconcilorControls.ReconcilorLocationSelector
        Public Property LumpFilter As ReconcilorControls.InputTags.InputCheckBox = New ReconcilorControls.InputTags.InputCheckBox
        Public Property FinesFilter As ReconcilorControls.InputTags.InputCheckBox = New ReconcilorControls.InputTags.InputCheckBox
        Public Property RomFilter As ReconcilorControls.InputTags.InputCheckBox = New ReconcilorControls.InputTags.InputCheckBox
        Public Property FilterButton As ReconcilorControls.InputTags.InputButton = New ReconcilorControls.InputTags.InputButton
        Public Property FilterTable As Tags.HtmlTableTag = New Tags.HtmlTableTag
        Public Property LocationContainer As Tags.HtmlDivTag = New Tags.HtmlDivTag("LocationFilter")
        Public Property FilterForm As Tags.HtmlFormTag = New Tags.HtmlFormTag

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            Dim SideNavigation = CType(Resources.DependencyFactories.SideNavigationFactory.Create(SideNavigationKeys.SampleStation.ToString, Resources),
                WebDevelopment.ReconcilorControls.SideNavigationBoxes.SampleStationSideNavigation)
            SideNavigation.LoadItems()
            ReconcilorContent.SideNavigation = SideNavigation

            With LocationFilter
                .LocationLabelCellWidth = 90
                .LocationId = Convert.ToInt32(Resources.UserSecurity.GetSetting(SettingsDictionary.Item(SettingsNames.SampleStationFilterLocation), "1"))
                .LowestLocationTypeDescription = "Site"
            End With

            With LumpFilter
                .ID = "LumpFilter"
                .Text = "Lump"
                .Checked = Convert.ToBoolean(Resources.UserSecurity.GetSetting(SettingsDictionary.Item(SettingsNames.SampleStationFilterLump), "True"))
            End With

            With FinesFilter
                .ID = "FinesFilter"
                .Text = "Fines"
                .Checked = Convert.ToBoolean(Resources.UserSecurity.GetSetting(SettingsDictionary.Item(SettingsNames.SampleStationFilterFines), "True"))
            End With

            With RomFilter
                .ID = "RomFilter"
                .Text = "Unscreened"
                .Checked = Convert.ToBoolean(Resources.UserSecurity.GetSetting(SettingsDictionary.Item(SettingsNames.SampleStationFilterRom), "True"))
            End With

            With FilterButton
                .ID = "FilterButton"
                .Text = "Filter"
            End With

            With FilterTable
                Dim cell = .AddCellInNewRow
                cell.Controls.Add(LocationFilter)

                cell = .AddCellInNewRow
                cell.Controls.Add(New LiteralControl("Product Size:"))
                cell = .AddCell
                cell.Controls.Add(New LiteralControl("&nbsp;")) ' This forces the LumpFilter to line up with the Location Filter.
                cell = .AddCell
                cell.Controls.Add(LumpFilter)
                cell = .AddCell
                cell.Controls.Add(FinesFilter)
                cell = .AddCell
                cell.Controls.Add(RomFilter)
                cell = .AddCell
                cell.Controls.Add(FilterButton)
                cell.CssClass = "left-pad"
            End With

            LocationContainer.Controls.Add(FilterTable)

            With FilterForm
                .ID = "FilterForm"
                .OnSubmit = "return GetSampleStations();"
                .Controls.Add(LocationContainer)
            End With
        End Sub

        Protected Overrides Sub SetupPageLayout()
            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", String.Empty))

            Dim headerDiv As New Tags.HtmlDivTag
            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Sample Station List"))
            End With

            With ReconcilorContent.ContainerContent
                .Controls.Add(headerDiv)
                .Controls.Add(FilterForm)
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
                .Controls.Add(New Tags.HtmlDivTag("SampleStationContent"))
            End With

            MyBase.SetupPageLayout()
            ' *Must* add this script here so that it comes *after* common.js
            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioCommon.js", String.Empty))
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetSampleStations();"))
        End Sub
    End Class
End Namespace