Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.Extensibility.DependencyFactoryKeys

Namespace Utilities
    Public Class CustomFieldsConfiguration
        Inherits WebpageTemplates.UtilitiesTemplate

#Region " Properties "
        Private ReadOnly _colorTermPlural As String = ReconcilorFunctions.GetSiteTerminologyPlural("Color")
        Private _disposed As Boolean
        Private _tabPane As New WebpageControls.TabPane("tabPaneCustomFields", "tabCustomFields")
        Private Const TAB_WIDTH As Int16 = 700
        Private _customFieldsSideNavigation As WebDevelopment.ReconcilorControls.SideNavigationBoxes.CustomFieldsNavigationBox

        Protected Property MessagesTab As WebDevelopment.Controls.TabPage = New WebDevelopment.Controls.TabPage("tabMessages", "tpgMessages", "Messages")

        Protected Property LocationColorTab As WebDevelopment.Controls.TabPage = New WebDevelopment.Controls.TabPage("tabLocationColor", "tpgLocationColor", "Location Colors")

        Protected Property LocationsTab As WebDevelopment.Controls.TabPage = New WebDevelopment.Controls.TabPage("tabLocations", "tpgLocations", "Locations")

        Protected Property TabPane As WebpageControls.TabPane
            Get
                Return _tabPane
            End Get
            Set
                _tabPane = Value
            End Set
        End Property

        Protected Property ColorsTab As WebDevelopment.Controls.TabPage = New WebDevelopment.Controls.TabPage("tabColours", "tpgColours", _colorTermPlural)

        Protected Property StockpileTab As WebDevelopment.Controls.TabPage = New WebDevelopment.Controls.TabPage("tabStockpile", "tpgStockpile", "Stockpiles")

#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If Not LocationsTab Is Nothing Then
                            LocationsTab.Dispose()
                            LocationsTab = Nothing
                        End If

                        If (Not _tabPane Is Nothing) Then
                            _tabPane.Dispose()
                            _tabPane = Nothing
                        End If

                        If (Not ColorsTab Is Nothing) Then
                            ColorsTab.Dispose()
                            ColorsTab = Nothing
                        End If
                    End If

                    'Clean up unmanaged resources ie: Pointers & Handles
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region

        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("MANAGE_BHPBIO_CUSTOM_FIELDS_CONFIGURATION"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub SetupPageLayout()
            Dim headerDiv As New Tags.HtmlDivTag()

            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
             Tags.ScriptLanguage.JavaScript, "../js/LocationPicker.js", ""))
            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
             Tags.ScriptLanguage.JavaScript, "../js/CustomFieldsConfiguration.js", ""))

            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
                                                             Tags.ScriptLanguage.JavaScript, "../js/aim.js", ""))



            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Custom Fields Configuration"))
            End With

            HasCalendarControl = True

            With TabPane
                .TabPages.Add(LocationsTab)
                .TabPages.Add(ColorsTab)
                .TabPages.Add(StockpileTab)
                .TabPages.Add(MessagesTab)
                .TabPages.Add(LocationColorTab)
            End With

            With ReconcilorContent.ContainerContent.Controls
                .Add(headerDiv)
                .Add(TabPane)
                .Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
            End With

            MyBase.SetupPageLayout()

            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetCustomFieldsLocationsTabContent();"))
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetCustomFieldsMessagesDetails();"))
        End Sub

        Protected Overrides Sub SetupPageControls()
            HasCalendarControl = True
            MyBase.SetupPageControls()

            _customFieldsSideNavigation = CType(Resources.DependencyFactories.SideNavigationFactory.Create(SideNavigationKeys.CustomFields.ToString, Resources),
                                Bhpbio.WebDevelopment.ReconcilorControls.SideNavigationBoxes.CustomFieldsNavigationBox)
            _customFieldsSideNavigation.LoadItems()
            ReconcilorContent.SideNavigation = _customFieldsSideNavigation

            SetupLocationsTabPage()
            SetupColourTabPage()
            SetupStockpileTabPage()
            SetupMessagesTabPage()
            SetupLocationColorTabPage()
        End Sub

        Private Sub SetupLocationColorTabPage()
            With LocationColorTab
                .OnClickScript = "GetCustomFieldsLocationColorTabContent();"
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
                .Controls.Add(New Tags.HtmlDivTag("locationColorsContent"))
                .StyleInline &= "width: " & TAB_WIDTH & "px;"
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
            End With
        End Sub

        Private Sub SetupMessagesTabPage()
            With MessagesTab
                .OnClickScript = "GetCustomFieldsMessagesTabContent();"
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
                .Controls.Add(New Tags.HtmlDivTag("messagesContent"))
                .StyleInline &= "width: " & TAB_WIDTH & "px;"
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
            End With
        End Sub

        Private Sub SetupLocationsTabPage()
            With LocationsTab
                .OnClickScript = "GetCustomFieldsLocationsTabContent();"
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
                .Controls.Add(New Tags.HtmlDivTag("locationsContent"))
                .StyleInline &= "width: " & TAB_WIDTH & "px;"
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
            End With
        End Sub

        Private Sub SetupColourTabPage()
            With ColorsTab
                .OnClickScript = "GetCustomFieldsColorsTabContent();"
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
                .Controls.Add(New Tags.HtmlDivTag("colorsContent"))
                .StyleInline &= "width: " & TAB_WIDTH & "px;"
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
            End With
        End Sub

        Private Sub SetupStockpileTabPage()
            With StockpileTab
                .OnClickScript = "GetCustomFieldsStockpileTabContent();"
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
                .Controls.Add(New Tags.HtmlDivTag("stockpileContent"))
                .StyleInline &= "width: " & TAB_WIDTH & "px;"
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
            End With
        End Sub

    End Class
End Namespace