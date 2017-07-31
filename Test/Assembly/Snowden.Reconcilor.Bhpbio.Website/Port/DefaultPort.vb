Imports WebpageControls = Snowden.Common.Web.BaseHtmlControls.WebpageControls
Imports Tags = Snowden.Common.Web.BaseHtmlControls.Tags
Imports FilterBoxes = Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.FilterBoxes
Imports DalBaseObjects = Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports SqlDal = Snowden.Reconcilor.Bhpbio.Database.SqlDal

Namespace Port
    Public Class DefaultPort
        Inherits WebDevelopment.WebpageTemplates.PortTemplate

        Private _disposed As Boolean
        Private _DalReport As DalBaseObjects.IReport
        Private _dalUtility As Snowden.Reconcilor.Core.Database.DalBaseObjects.IUtility
        Private _ShippingTab As New WebDevelopment.Controls.TabPage("tabShipping", "tpgShipping", "Shipping")
        Private _PortBlendingTab As New WebDevelopment.Controls.TabPage("tabPortBlending", "tpgPortBlending", "Port Blending")
        Private _PortBalancesTab As New WebDevelopment.Controls.TabPage("tabPortBalances", "tpgPortBalances", "Port Balances")
        Private _PortTabPane As New WebpageControls.TabPane("tabPanePort", "tabShipping")
        Private _portFilter As FilterBoxes.Port.PortFilter
        Const _tabPageWidth As Int32 = 640

        Public Property DalReport() As DalBaseObjects.IReport
            Get
                Return _DalReport
            End Get
            Set(ByVal value As DalBaseObjects.IReport)
                _DalReport = value
            End Set
        End Property

        Public Property DalUtility() As Core.Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Core.Database.DalBaseObjects.IUtility)
                If (Not value Is Nothing) Then
                    _dalUtility = value
                End If
            End Set
        End Property

        Public Property ShippingTab() As WebDevelopment.Controls.TabPage
            Get
                Return _ShippingTab
            End Get
            Set
                If (Not value Is Nothing) Then
                    _ShippingTab = value
                End If
            End Set
        End Property

        Public Property PortTabPane() As WebpageControls.TabPane
            Get
                Return _PortTabPane
            End Get
            Set(ByVal value As WebpageControls.TabPane)
                If (Not value Is Nothing) Then
                    _PortTabPane = value
                End If
            End Set
        End Property

        Public ReadOnly Property PortFilter() As FilterBoxes.Port.PortFilter
            Get
                If _portFilter Is Nothing Then
                    _portFilter = CType(Resources.DependencyFactories.FilterBoxFactory.Create("Port", Resources),  _
                     FilterBoxes.Port.PortFilter)
                End If

                Return _portFilter
            End Get
        End Property

        Public Property PortBlendingTab() As WebDevelopment.Controls.TabPage
            Get
                Return _PortBlendingTab
            End Get
            Set
                If (Not value Is Nothing) Then
                    _PortBlendingTab = value
                End If
            End Set
        End Property

        Public Property PortBalancesTab() As WebDevelopment.Controls.TabPage
            Get
                Return _PortBalancesTab
            End Get
            Set
                If (Not value Is Nothing) Then
                    _PortBalancesTab = value
                End If
            End Set
        End Property

        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then

                        If (Not _DalReport Is Nothing) Then
                            _DalReport.Dispose()
                            _DalReport = Nothing
                        End If

                        If Not (_portFilter Is Nothing) Then
                            _portFilter.Dispose()
                            _portFilter = Nothing
                        End If
                    End If

                    'Clean up unmanaged resources ie: Pointers & Handles
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub

        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("PORT_GRANT"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If (DalReport Is Nothing) Then
                DalReport = New SqlDal.SqlDalReport(Resources.Connection)
            End If

            If (DalUtility Is Nothing) Then
                DalUtility = New Core.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            SetupShippingTabPage()
            SetupPortBlendingTabPage()
            SetupPortBalancesTabPage()
        End Sub

        Private Sub SetupPortBlendingTabPage()

            With PortBlendingTab
                .OnClickScript = "clearDate(); GetPortBlendingTabContent();"
                .Controls.Add(New Tags.HtmlDivTag("portBlendingFilterDiv"))
                .Controls.Add(New Tags.HtmlDivTag("portBlendingContent"))
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
            End With
        End Sub

        Private Sub SetupPortBalancesTabPage()
            With PortBalancesTab
                .OnClickScript = "clearDate();GetPortBalancesTabContent();"
                .Controls.Add(New Tags.HtmlDivTag("portBalancesFilterDiv"))
                .Controls.Add(New Tags.HtmlDivTag("portBalancesContent"))
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
            End With
        End Sub

        Private Sub SetupShippingTabPage()
            With ShippingTab
                .OnClickScript = "clearDate();GetShippingTabContent();"
                .Controls.Add(New Tags.HtmlDivTag("shippingFilterDiv"))
                .Controls.Add(New Tags.HtmlDivTag("shippingContent"))
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
            End With
        End Sub

        Protected Overrides Sub SetupPageLayout()
            HasCalendarControl = True

            With PortTabPane
                .TabPages.Add(ShippingTab)
                .TabPages.Add(PortBlendingTab)
                .TabPages.Add(PortBalancesTab)
            End With

            With PortFilter
                .Style.Add("margin-top", "15px")
                .Attributes.Add("class", "hide")
                .DalUtility = DalUtility
            End With

            With ReconcilorContent.ContainerContent.Controls
                .Add(PortFilter)
                .Add(PortTabPane)
                .Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))
            End With

            MyBase.SetupPageLayout()
        End Sub

        Protected Overrides Sub SetupFinalJavascriptCalls()
            MyBase.SetupFinalJavaScriptCalls()

            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetShippingTabContent();"))
        End Sub
    End Class
End Namespace


