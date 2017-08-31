Imports System.Data.SqlClient
Imports System.Web.UI
Imports System.Web.UI.HtmlControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions

Namespace Approval
    Public Class ApprovalSummaryList
        Inherits ReconcilorAjaxPage
#Region " Const "
        Private Const PITAPPROVALTIMESTAMPFORMAT = "dd/MM/yyyy HH:mm"
        Public Const TIMESTAMPFORMAT = "yyyy-MM-dd"
        Private Const TABLEHEADERTIMESTAMPFORMAT = "MMMMMMMM yyyy"
#End Region

#Region " Properties "
        Private Property DalApproval As IApproval

        Private Property GroupApprovalSummary As New GroupBox("Approval Summary")
        Private Property HeaderDiv As New HtmlDivTag()

        Private Property ReturnTable As Control

        Private Property SelectedMonth As Date?
        Private Property NumberPreviousMonths As Int32?
#End Region

#Region " Overrides "
        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                Dim errorMessage As String = ValidateData()

                If errorMessage = String.Empty Then

                    SetupPageControls()
                    With HeaderDiv
                        .StyleClass = "largeHeaderText"
                        .Style.Add("margin-bottom", "5px")
                        .Controls.Add(New LiteralControl("Approval Summary"))
                    End With

                    With GroupApprovalSummary
                        .ID = "GroupApprovalSummary"
                        .Controls.Add(ReturnTable)
                        .Width = 600
                    End With

                    Controls.Add(HeaderDiv)
                    Controls.Add(GroupApprovalSummary)

                    'Add call to update the Help Box
                    Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript,
                                                     ScriptLanguage.JavaScript, "",
                                                     "ShowApprovalList('" & GetLegend() & "');"))
                Else
                    JavaScriptAlert(errorMessage, "Please fix the following issues:")
                End If
            Catch ex As SqlException
                JavaScriptAlert("Error while generating approval summary page: {0}", ex.Message)
            Catch e As Exception
                Throw
            End Try
        End Sub

        Protected Function GetLegend() As String
            ' This seems a bit hacky, but other areas do it similar, so...
            Dim legendHtml As String = ""
            legendHtml += "<div>"
            legendHtml += "    <table>"
            legendHtml += "        <tr>"
            legendHtml += "            <td><img src=""../images/reports/tickGreen.gif"" alt="""" style=""height:16px;width:16px;""></td>"
            legendHtml += "            <td>Location and/or sub Location(s) approval is complete.</td>"
            legendHtml += "        </tr>"
            legendHtml += "        <tr>"
            legendHtml += "            <td><img src=""../images/reports/tickOrange.gif"" alt="""" style=""height:16px;width:16px;""></td>"
            legendHtml += "            <td>Location and/or sub Location(s) approval is partially complete.</td>"
            legendHtml += "        </tr>"
            legendHtml += "        <tr>"
            legendHtml += "            <td><a href=""#"">Hub/Site</a></td>"
            legendHtml += "            <td>Location and/or sub Location(s) approval has not started.</td>"
            legendHtml += "        </tr>"
            legendHtml += "        <tr>"
            legendHtml += "            <td><a href=""#"" style=""color: grey;"">Hub/Site</a></td>"
            legendHtml += "            <td>Location and/or sub Location(s) is inactive.</td>"
            legendHtml += "        </tr>"
            legendHtml += "    </table>"
            legendHtml += "</div>"
            Return legendHtml
        End Function

        Protected Overridable Sub SetupPageControls()
            Dim i As Integer
            Dim data As New DataSet()
            For i = 0 To NumberPreviousMonths.Value
                Dim month = SelectedMonth.Value.AddMonths(-i)
                Dim table = DalApproval.GetBhpbioApprovalSummary(month)
                table.TableName = month.ToString(TIMESTAMPFORMAT)
                data.Tables.Add(table)
            Next
            ReturnTable = RenderTable(data)
            With ReturnTable
                .ID = "ReturnTable"
            End With
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()
            If (Not Request("SelectedMonth") Is Nothing) Then
                SelectedMonth = RequestAsDateTime("SelectedMonth")
            Else
                SelectedMonth = DateTime.Now
            End If
            If (Not Request("NumberPreviousMonths") Is Nothing) Then
                NumberPreviousMonths = RequestAsInt32("NumberPreviousMonths")
            Else
                NumberPreviousMonths = 2
            End If

            If SelectedMonth IsNot Nothing Then
                Resources.UserSecurity.SetSetting("Approval_Filter_Date", CType(SelectedMonth, Date).ToString("O"))
            End If
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalApproval Is Nothing) Then
                DalApproval = New SqlDalApproval(Resources.Connection)
            End If
            MyBase.SetupDalObjects()
        End Sub
#End Region

        Private Shared Function RenderTable(data As DataSet) As Control
            Dim table As New HtmlTable
            With table
                .Border = 0
                .Width = "400"

                For Each dt As DataTable In data.Tables
                    Dim approvalMonth = DateTime.Parse(dt.TableName)
                    dt.TableName = approvalMonth.ToString(TABLEHEADERTIMESTAMPFORMAT)
                    .Rows.Add(GetMonthHeaderRow(dt)) 'i.e. February 2016
                    .Rows.Add(GetLocationTypeCaptionRow()) 'Hub Approvals, Site Approvals
                    For Each dr In GetContentRows(approvalMonth, dt)
                        .Rows.Add(dr)
                    Next
                Next
            End With
            Return table
        End Function

        Private Shared Function GetContentRows(month As DateTime, dt As DataTable) As HtmlTableRow()
            Dim dataRows = dt.Select()
            Dim hubs = dataRows.Where((Function(d) d.AsString("LocationType") = "Hub")).ToArray()
            Dim sites = dataRows.Where((Function(d) d.AsString("LocationType") = "Site")).ToArray()
            Dim pits = dataRows.Where((Function(d) d.AsString("LocationType") = "Pit")).ToArray()
            ' Not sure why but initialise adds 1 to the size of the array for some odd reason
            Dim maxRows = CType(IIf(hubs.Count > sites.Count, hubs.Count - 1, sites.Count - 1), Integer)
            Dim rows(maxRows) As HtmlTableRow
            Dim rowIndex As Integer = 0
            Dim isFirstHubSite = True

            For Each hub In hubs
                For Each hubSite In sites.Where(Function(s) s.AsInt("Parent_Location_Id") = hub.AsInt("Location_Id"))
                    rows(rowIndex) = GetDataRow(month, rowIndex, hub, hubSite, sites, pits, isFirstHubSite)
                    If (isFirstHubSite) Then
                        isFirstHubSite = False
                    End If
                    rowIndex += 1
                Next
                isFirstHubSite = True ' Reset for the next round of Sites
            Next
            Return rows
        End Function

        Private Shared Function GetLocationId(d As DataRow) As Integer
            Return d.AsInt("Location_Id")
        End Function

        Private Shared Function GetParentLocationId(d As DataRow) As Integer
            Return d.AsInt("Parent_Location_Id")
        End Function

        Private Shared Function GetSignedOffMonth(d As DataRow) As Date
            Return d.AsDate("SignOffDate")
        End Function

        Private Shared Function GetHyperlink(d As DataRow, month As DateTime, sites As IEnumerable(Of DataRow), pits As IEnumerable(Of DataRow)) As HtmlAnchor
            Dim anchor = New HtmlAnchor()
            With anchor
                .HRef = "#"
                .Attributes.Add("onclick", "return LoadFactorApprovalScreen('" & month.ToString(TIMESTAMPFORMAT) & "', " & GetLocationId(d) & ");")
                .InnerText = d.AsString("Name")

                Dim childLocations As IEnumerable(Of DataRow)
                Dim pitCount As Integer
                If (d.AsString("LocationType") = "Hub") Then
                    childLocations = GetChildLocations(d, sites).ToList()
                    pitCount = childLocations.Sum(Function(childLocation) GetChildLocations(childLocation, pits).Count())

                Else
                    childLocations = GetChildLocations(d, pits).ToList()
                    pitCount = childLocations.Count
                End If

                If (pitCount = 0) Then
                    .Style.Add("color", "grey")
                End If
            End With
            Return anchor
        End Function

        Private Shared Function GetIsApproved(d As DataRow) As Boolean
            Return d.AsString("ApprovalStatus") = "Approved"
        End Function

        Private Shared Function GetChildLocations(location As DataRow, allLocations As IEnumerable(Of DataRow)) As IEnumerable(Of DataRow)
            Dim locationId = GetLocationId(location)
            Return allLocations.Where(Function(l) GetParentLocationId(l) = locationId)
        End Function

        Private Shared Function GetPitApprovalInfo(numberApprovedPits As Integer, numberAllPits As Integer) As LiteralControl
            Return New LiteralControl("(" & numberApprovedPits & " of " & numberAllPits & " active pits approved)")
        End Function

        Private Shared Function Align(element As Control, direction As String) As HtmlDivTag
            Dim alignmentDiv As New HtmlDivTag
            With alignmentDiv
                .Attributes.Add("style", "float: " & direction & ";")
                .Controls.Add(element)
            End With
            Return alignmentDiv
        End Function

        Private Shared Function LeftAlign(element As Control) As HtmlDivTag
            Return Align(element, "left")
        End Function

        Private Shared Function RightAlign(element As Control) As HtmlDivTag
            Return Align(element, "right")
        End Function

        Private Shared Function WrapDiv(element1 As Control, element2 As Control) As HtmlDivTag
            Dim div As New HtmlDivTag
            With div
                .Controls.Add(element1)
                .Controls.Add(element2)
            End With
            Return div
        End Function

        Private Shared Function GenerateTooltipText(tooltipPits As DataRow()) As String
            If (tooltipPits.Count = 0) Then
                Return String.Empty
            End If
            Dim earliestPitApproval = tooltipPits.Min(Function(d) GetSignedOffMonth(d))
            Dim latestPitApproval = tooltipPits.Max(Function(d) GetSignedOffMonth(d))

            Dim earliestPiApprovalString = CType(IIf(earliestPitApproval = Nothing, String.Empty, earliestPitApproval.ToString(PITAPPROVALTIMESTAMPFORMAT)), String)
            Dim latestPitApprovalString = CType(IIf(latestPitApproval = Nothing, String.Empty, latestPitApproval.ToString(PITAPPROVALTIMESTAMPFORMAT)), String)
            Return "Earliest Pit approval: " + earliestPiApprovalString + vbCr +
                   "Latest Pit approval:   " + latestPitApprovalString
        End Function

        Private Shared Function GetApprovalStatusImage(locationRow As DataRow, childRows As IEnumerable(Of DataRow), pits As DataRow()) As HtmlImageTag
            Dim childLocations = GetChildLocations(locationRow, childRows).ToList()
            If (childLocations.Count = 0) Then ' No children, can only be approved or unapproved
                If GetIsApproved(locationRow) Then
                    Return New HtmlImageTag("../images/reports/tickGreen.gif", Nothing, "Approved", 0, 16, 16)
                Else
                    Return New HtmlImageTag("", Nothing, Nothing, 0, 16, 16)
                End If
            Else
                Dim childLocationApprovalCount = childLocations.Where(Function(c) GetIsApproved(c)).Count
                If (childLocationApprovalCount = childLocations.Count) Then ' All children are approved
                    ' Check all childrens' children
                    Dim childrensChildren = New List(Of DataRow)
                    For Each childLocation In childLocations
                        childrensChildren.AddRange(GetChildLocations(childLocation, pits))
                    Next

                    If (childrensChildren.Count = 0) Then ' No children, can only be approved or unapproved
                        If GetIsApproved(locationRow) Then
                            Return New HtmlImageTag("../images/reports/tickGreen.gif", Nothing, "Approved", 0, 16, 16)
                        Else
                            Return New HtmlImageTag("../images/reports/tickOrange.gif", Nothing, "Partial", 0, 16, 16)
                        End If
                    Else
                        Dim childrensChildrenApprovalCount = childrensChildren.Where(Function(c) GetIsApproved(c)).Count
                        If (childrensChildrenApprovalCount = childrensChildren.Count) Then ' All children are approved
                            If GetIsApproved(locationRow) Then
                                Return New HtmlImageTag("../images/reports/tickGreen.gif", Nothing, "Approved", 0, 16, 16)
                            Else
                                Return New HtmlImageTag("../images/reports/tickOrange.gif", Nothing, "Partial", 0, 16, 16)
                            End If
                        ElseIf (childrensChildrenApprovalCount > 0) Then ' Only some children are approved
                            Return New HtmlImageTag("../images/reports/tickOrange.gif", Nothing, "Partial", 0, 16, 16)
                        Else ' No children approved
                            If GetIsApproved(locationRow) Then
                                Return New HtmlImageTag("../images/reports/tickOrange.gif", Nothing, "Partial", 0, 16, 16)
                            Else
                                Return New HtmlImageTag("", Nothing, Nothing, 0, 16, 16)
                            End If
                        End If
                    End If
                ElseIf (childLocationApprovalCount > 0) Then ' Only some children are approved
                    Return New HtmlImageTag("../images/reports/tickOrange.gif", Nothing, "Partial", 0, 16, 16)
                Else ' No children approved
                    If GetIsApproved(locationRow) Then
                        Return New HtmlImageTag("../images/reports/tickOrange.gif", Nothing, "Partial", 0, 16, 16)
                    Else
                        Return New HtmlImageTag("", Nothing, Nothing, 0, 16, 16)
                    End If
                End If
            End If
        End Function

        Private Shared Function GetDataRow(month As DateTime, rowIndex As Integer, hub As DataRow, siteRow As DataRow, sites As DataRow(), pits As DataRow(),
                                           isFirstHubSite As Boolean) As HtmlTableRow

            Dim row As New HtmlTableRow()

            'empty column
            Dim cell As New HtmlTableCell
            cell.Controls.Add(New LiteralControl("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"))
            row.Cells.Add(cell)

            'First column "Hub Approvals"
            cell = New HtmlTableCell
            If isFirstHubSite Then
                Dim hyperlink = GetHyperlink(hub, month, sites, pits)
                Dim image = GetApprovalStatusImage(hub, sites, pits)
                cell.Controls.Add(hyperlink)
                cell.Controls.Add(image)
            End If
            row.Cells.Add(cell)

            'Second column "Site Approvals"
            cell = New HtmlTableCell
            If (rowIndex < sites.Count) Then
                Dim myPits = GetChildLocations(siteRow, pits).ToArray()
                Dim approvedPits = myPits.Where(Function(x) GetIsApproved(x)).ToArray()
                cell.Attributes.Add("title", GenerateTooltipText(approvedPits))
                Dim hyperlink = GetHyperlink(siteRow, month, sites, pits)
                Dim image = GetApprovalStatusImage(siteRow, myPits, pits)
                cell.Controls.Add(LeftAlign(WrapDiv(hyperlink, image)))
                If (myPits.Count <> 0) Then
                    cell.Controls.Add(RightAlign(GetPitApprovalInfo(approvedPits.Count, myPits.Count)))
                End If
            End If
            row.Cells.Add(cell)
            Return row
        End Function

        Private Shared Function GetLocationTypeCaptionRow() As HtmlTableRow
            Dim row As New HtmlTableRow()
            Dim cell As New HtmlTableCell
            cell.Controls.Add(New LiteralControl())
            row.Cells.Add(cell)
            cell = New HtmlTableCell
            Dim lit = New LiteralControl("Hub Approvals")
            cell.Style.Add("font-weight", "bold")
            cell.Controls.Add(lit)
            row.Cells.Add(cell)
            cell = New HtmlTableCell
            lit = New LiteralControl("Site Approvals")
            cell.Style.Add("font-weight", "bold")
            cell.Controls.Add(lit)
            row.Cells.Add(cell)
            Return row
        End Function

        Private Shared Function GetMonthHeaderRow(dt As DataTable) As HtmlTableRow
            Dim row = New HtmlTableRow()
            Dim cell = New HtmlTableCell()
            cell.Style.Add("font-size", "150%")
            cell.ColSpan = 3
            cell.Controls.Add(New LiteralControl(dt.TableName))
            row.Cells.Add(cell)
            Return row
        End Function
    End Class
End Namespace