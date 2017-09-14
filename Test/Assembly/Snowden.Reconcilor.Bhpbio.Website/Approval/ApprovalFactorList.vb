Imports System.Data.SqlClient
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Common.Web.BaseHtmlControls.WebpageControls
Imports System.Text
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions

Namespace Approval
    Public Class ApprovalFactorList
        Inherits ReconcilorAjaxPage

        Public Const TIMESTAMPFORMAT = "yyyy-MM-dd"

#Region " Properties "

        Private Property DalApproval As IApproval

        Private Property GroupFactorApprovalSummary As New GroupBox("Monthly Approval")
        Private Property HeaderDiv As New HtmlDivTag()
        Private Property ReturnTable As New HtmlDivTag()

        Private Property LocationTabPages As WebDevelopment.Controls.TabPage()
        Private Property LocationTabPane As TabPane
        Private Property TabPageContentDiv As New HtmlDivTag()
        Private Property SelectedMonth As Date?
        Private Property LocationId As Integer
        Private Property SelectedTabPage As String = Nothing
        Private Property SelectedTabPageId As Integer

#End Region

#Region " Overrides "

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                Dim errorMessage As String = ValidateData()

                If errorMessage = String.Empty Then
                    SetupPageControls()
                    Dim headerText = String.Format("Monthly Approval - {0:MMM yyyy}", SelectedMonth)

                    With HeaderDiv
                        .StyleClass = "largeHeaderText"
                        .Style.Add("margin-bottom", "5px")
                        .Controls.Add(New LiteralControl(headerText))
                    End With

                    With GroupFactorApprovalSummary
                        .ID = "GroupFactorApprovalSummary"
                        .Controls.Add(ReturnTable)
                    End With

                    Controls.Add(HeaderDiv)
                    Controls.Add(GroupFactorApprovalSummary)
                    Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript, LoadTabScript(SelectedTabPage, SelectedTabPageId, SelectedMonth.Value)))

                    'Add call to update the Help Box
                    Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript, ScriptLanguage.JavaScript, "", "ShowApprovalList('" & GetLegend() & "');"))
                Else
                    JavaScriptAlert(errorMessage, "Please fix the following issues:")
                End If
            Catch ex As SqlException
                JavaScriptAlert("Error while generating factor approval page: {0}", ex.Message)
            Catch e As Exception
                Throw
            End Try
        End Sub

        Protected Function GetLegend() As String
            ' This seems a bit hacky, but other areas do it similar, so...
            Dim legendHtml As New StringBuilder()
            legendHtml.Append(GetItemTag($"<span style=""background-color:{OUTLIER_BACKGROUND_ABOVE};"">&nbsp;&nbsp;&nbsp;&nbsp;</span>&nbsp;Value is an outlier above projection"))
            legendHtml.Append(GetItemTag($"<span style=""background-color:{OUTLIER_BACKGROUND_BELOW};"">&nbsp;&nbsp;&nbsp;&nbsp;</span>&nbsp;Value is an outlier below projection"))
            Return legendHtml.ToString()
        End Function

        Private Shared Function LoadTabScript(tabId As String, locationId As Integer, month As DateTime) As String
            Return String.Format("LoadTabPageContentDiv('{0}',{1},'{2:yyyy-MM-dd}');", tabId, locationId.ToString, month)
        End Function

        Private Shared Function PreselectTabPage(tabPageName As String, tabpages As IEnumerable(Of WebDevelopment.Controls.TabPage)) As IEnumerable(Of WebDevelopment.Controls.TabPage)
            'This will make the requested tab the first one. A group instead of two identical comparisons would make it nicer.
            Dim enumerable As IEnumerable(Of WebDevelopment.Controls.TabPage) = If(TryCast(tabpages, List(Of WebDevelopment.Controls.TabPage)), tabpages.ToList())
            Dim requestedTabPAge = enumerable.Where(Function(x) x.PageTitle = tabPageName)
            Return requestedTabPAge.Union(enumerable.Where(Function(x) x.PageTitle <> tabPageName))
        End Function

        Protected Overridable Sub SetupPageControls()
            Dim locationsDt = DalApproval.GetBhpbioSiblingLocations(LocationId, CType(SelectedMonth, Date))

            ReDim LocationTabPages(locationsDt.Rows.Count)
            LocationTabPane = New TabPane("tabPaneLocation", "tabPaneHub")

            With TabPageContentDiv
                .ID = "TabPageContentDiv"
            End With

            With LocationTabPane
                Dim requestedTabPAgeName = ""
                Dim tabPages As New List(Of WebDevelopment.Controls.TabPage)

                For Each dr As DataRow In locationsDt.Rows
                    Dim tabPageName = dr.AsString("Name")
                    Dim tabPageLocationId = dr.AsInt("Location_Id")

                    Dim table = DalApproval.GetBhpbioLocationTypeAndApprovalStatus(tabPageLocationId, SelectedMonth.Value)
                    Dim dt = table.AsEnumerable.FirstOrDefault()

                    Dim isApproved = dt.AsBool("IsApproved")
                    Dim imageSource = ""
                    If (isApproved) Then
                        imageSource = "../images/reports/tickGreen.gif"
                    End If

                    Dim tabPageId = "LocationTabPage_" & tabPageLocationId.ToString
                    If (tabPageLocationId = LocationId) Then
                        requestedTabPAgeName = tabPageName
                        SelectedTabPage = tabPageId
                        SelectedTabPageId = tabPageLocationId
                    End If
                    Dim tabPage = New WebDevelopment.Controls.TabPage(tabPageId, "script" & tabPageId, tabPageName, imageSource)
                    With tabPage
                        .OnClickScript = LoadTabScript(tabPageId, tabPageLocationId, SelectedMonth.Value)
                        .Controls.Add(TabPageContentDiv)
                    End With
                    tabPages.Add(tabPage)

                Next

                'Add the tabs with the requested one first
                For Each t In PreselectTabPage(requestedTabPAgeName, tabPages)
                    .TabPages.Add(t)
                Next
            End With

            With ReturnTable
                .Controls.Add(LocationTabPane)
                Dim locationIds = String.Join(",", locationsDt.Select().Select(Function(row) row.AsString("Location_Id")).ToArray())
                .Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript, String.Format("PreLoadKtoNSections('{0}');", locationIds)))
            End With
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            SelectedMonth = RequestAsDateTime("SelectedMonth")
            LocationId = RequestAsInt32("LocationId")

            If SelectedMonth IsNot Nothing Then
                Resources.UserSecurity.SetSetting("Approval_Filter_Date", CType(SelectedMonth, Date).ToString("O"))
            End If

            Resources.UserSecurity.SetSetting("Approval_Filter_LocationId", LocationId.ToString())
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalApproval Is Nothing) Then
                DalApproval = New SqlDalApproval(Resources.Connection)
            End If
            MyBase.SetupDalObjects()
        End Sub

#End Region
    End Class
End Namespace