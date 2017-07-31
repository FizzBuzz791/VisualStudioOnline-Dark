Imports System.Data.SqlClient
Imports System.Web.UI
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports System.Web.UI.WebControls

Namespace Approval
    Public Class ApprovalFactorListTabPage
        Inherits ReconcilorAjaxPage

#Region " Const "
        Public Const TIMESTAMPFORMAT = "yyyy-MM-dd"
#End Region

#Region " Members "
        Private IsPitLevel As Boolean
        Private IsApproved As Boolean
        Private SignoffDate As String
        Private IsCompanyLevel As Boolean
        Private ApproverName As String
#End Region

#Region " Properties "
        Private Property DalApproval() As IApproval
        Private Property GroupForm As New HtmlFormTag()
        Private Property SelectedMonth As Date
        Private Property LocationId As Integer
#End Region

#Region " Function "

        Private Function GetUnapprovalButtonCell() As TableCell
            Dim cell As New TableCell()
            With cell
                Dim unapproveInputButton As New InputTags.InputButtonFormless
                With unapproveInputButton
                    .Style.Add("width", "100px")
                    .Style.Add("padding", "5px")
                    .Text = "Unapprove"
                    .ID = "UnapproveInputButton"
                    .Attributes.Add("onclick", "UnapproveAll(" & LocationId.ToString & ", '" & SelectedMonth.ToString(TIMESTAMPFORMAT) & "', false);")
                End With
                cell.Controls.Add(unapproveInputButton)
                cell.Style.Add("padding", "5px")
                If (Not IsApproved) Then
                    unapproveInputButton.Attributes.Add("disabled", "disabled")
                    unapproveInputButton.Attributes.Add("hidden", "true")
                End If
            End With
            Return cell
        End Function

        Private Function GetProgressCell() As TableCell
            Dim cell As New TableCell()
            With cell
                .RowSpan = 2
                .BorderStyle = BorderStyle.Solid
                .BorderWidth = Unit.Pixel(1)
                Dim progressDiv As New HtmlDivTag
                With progressDiv
                    .ID = "itemDetail"
                    .InnerHtml = ""
                    'If there is an approval/unapproval pending
                    Dim pendingApproval = DalApproval.GetBhpbioPendingApprovalId(Resources.UserSecurity.UserId.Value, LocationId)
                    If (pendingApproval IsNot Nothing) Then
                        .Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript, "DisplayApprovalProgress(" & pendingApproval & ", false);"))
                    Else
                        .Style.Add(HtmlTextWriterStyle.Display, "none")
                    End If
                End With
                .Controls.Add(progressDiv)
            End With
            Return cell
        End Function

        Private Function GetApprovalButtonCell() As TableCell
            Dim cell As New TableCell()
            With cell
                Dim approveInputButton As New InputTags.InputButtonFormless
                With approveInputButton
                    .Style.Add("width", "100px")
                    .Style.Add("padding", "5px")
                    .Text = "Approve"
                    .ID = "ApproveInputButton"
                    .Attributes.Add("onclick", "ApproveAll(" & LocationId.ToString & ", '" & SelectedMonth.ToString(TIMESTAMPFORMAT) & "', false);")
                End With
                .Controls.Add(approveInputButton)
                .Style.Add("padding", "5px")
            End With
            Return cell
        End Function

        Private Function GetApprovedByCell() As TableCell
            Dim cell As New TableCell()
            With cell
                Dim lit As New HtmlDivTag() With {
                    .InnerHtml = String.Format("Approved by: {0} {1}", ApproverName, SignoffDate)
                }

                If (IsApproved) Then
                    .HorizontalAlign = HorizontalAlign.Right
                    .Controls.Add(lit)
                End If
            End With
            Return cell
        End Function

        Private Function GetStatementCell() As TableCell
            Dim cell As New TableCell()
            With cell
                .Controls.Add(New LiteralControl("I have reviewed the data assessment, most notable outliers, other movements and the reconciliation results"))
                Dim checkBox As New CheckBox()
                With checkBox
                    .ID = "chkStatement"
                    If (IsApproved) Then
                        .Attributes.Add("disabled", "disabled")
                    End If
                End With

                .Controls.Add(checkBox)
            End With
            Return cell
        End Function

        Private Function GetBlastBlockCell() As TableCell
            Dim cell As New TableCell()
            With cell
                Dim anchorTag As New HtmlAnchorTag(String.Format("../Approval/Default.aspx?LocationId={0}&SelectedMonth={1:yyyy-MMM-dd}", LocationId, SelectedMonth), "", "View Blastblocks")
                .Controls.Add(anchorTag)
            End With
            Return cell
        End Function

#End Region

#Region " Overrides "
        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                Dim errorMessage As String = ValidateData()

                If errorMessage = String.Empty Then
                    SetupPageControls()
                    Controls.Add(GroupForm)
                Else
                    JavaScriptAlert(errorMessage, "Please fix the following issues:")
                End If
            Catch ex As SqlException
                JavaScriptAlert("Error while generating monthly approval page: {0}", ex.Message)
            Catch e As Exception
                Throw e
            End Try
        End Sub

        Delegate Function GetControls() As IEnumerable(Of Control)

        Private Function GenerateSection(sectionName As String, gc As GetControls, isCollapsed As Boolean) As GroupBox
            Dim groupBox As New GroupBox(sectionName)
            With groupBox
                .IsCollapsable = True
                .StartCollapsed = isCollapsed

                With .Controls
                    If (Not gc Is Nothing) Then
                        For Each c In gc.Invoke
                            .Add(c)
                        Next
                    End If
                End With
            End With
            Return groupBox
        End Function


        Private Function GenerateSection(sectionName As String, groupDivName As String, urlFormat As String, Optional isCollapsed As Boolean = True) As GroupBox
            Dim groupBox As New GroupBox(sectionName)
            With groupBox
                .IsCollapsable = True
                .StartCollapsed = isCollapsed

                .Controls.Add(New HtmlDivTag(groupDivName))
                Dim url = String.Format(urlFormat, LocationId, SelectedMonth.ToString(TIMESTAMPFORMAT), RequestAsString("LocationName"), RequestAsString("LocationType"))
                .CollapseOnClick = String.Format("LoadOnExpand(this,'{0}','{1}');", groupDivName, url)
                If Not isCollapsed Then
                    .Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript, String.Format("CallAjax('{0}', '{1}', 'image');", groupDivName, url)))
                End If
            End With

            Return groupBox
        End Function

        Private Function GetTabFooter() As Control
            Dim rowIndex As Integer
            Dim ackTable As New HtmlTableTag()

            Dim table = DalApproval.GetBhpbioLocationTypeAndApprovalStatus(LocationId, SelectedMonth)
            Dim dt = table.AsEnumerable.FirstOrDefault()

            IsCompanyLevel = dt.AsInt("LocationTypeId") = 1 '1 = CompanyLevel
            IsPitLevel = dt.AsInt("LocationTypeId") = 4     '4 = PitLevel
            IsApproved = dt.AsBool("IsApproved")
            If (IsApproved) Then
                ApproverName = dt.AsString("ApproverName")
                SignoffDate = dt.AsDate("SignoffDate").ToString("dd-MMM-yyyy hh:mm:ss tt")
            End If

            With ackTable
                If (IsPitLevel) Then
                    rowIndex = .Rows.Add(New TableRow)
                    With .Rows(rowIndex)
                        .Cells.Add(GetBlastBlockCell())
                    End With
                End If

                If (Not IsCompanyLevel) Then
                    If (Not IsApproved) Then
                        rowIndex = .Rows.Add(New TableRow)
                        With .Rows(rowIndex)
                            .Cells.Add(GetStatementCell())
                            .Cells.Add(GetApprovalButtonCell())
                        End With
                    End If

                    If (IsApproved) Then
                        rowIndex = .Rows.Add(New TableRow)
                        With .Rows(rowIndex)
                            .Cells.Add(GetApprovedByCell())
                            .Cells.Add(GetUnapprovalButtonCell())
                            .Cells.Add(New TableCell())
                        End With
                    End If

                    .Rows(rowIndex).Cells.Add(GetProgressCell())
                End If
            End With
            Return ackTable
        End Function
#End Region

#Region " Protected "
        Protected Overridable Sub SetupPageControls()
            With GroupForm

                Dim headingControl = New HtmlDivTag()
                headingControl.InnerHtml = "Review the data assessment, most notable outliers, other movements and reconciliation results."
                headingControl.StyleInline = "padding-top: 8px;"

                .Controls.Add(headingControl)
                .Controls.Add(New HtmlBRTag)
                .Controls.Add(GenerateSection("Data Assessment Section", "ApprovalAssessmentDiv", "./ApprovalAssessmentList.aspx?SelectedMonth={1}&LocationId={0}&LocationName={2}&LocationType={3}"))
                .Controls.Add(New HtmlBRTag)
                .Controls.Add(GenerateSection("Most Notable Outliers Section", "outlierAnalysisDiv", "../Analysis/OutlierAnalysisGrid.aspx?MonthValueStart={1}&MonthValueEnd={1}&location={0}&AnalysisGroup=All&productTypeProductSize=All&AttributeFilter=All&deviations=0&limitSubLocationOnly=false"))
                .Controls.Add(New HtmlBRTag)
                .Controls.Add(GenerateSection("Other Movements", "approvalOtherDiv", "./ApprovalOtherList.aspx?MonthValue={1}&LocationId={0}"))
                .Controls.Add(New HtmlBRTag)
                .Controls.Add(GenerateSection("Factors", "divKtoN", "./ApprovalDataList.aspx?MonthValue={1}&LocationId={0}"))
                .Controls.Add(New HtmlBRTag)
                .Controls.Add(GetTabFooter())
                .Controls.Add(New HtmlBRTag)
                .Controls.Add(New HtmlImageTag("../images/Approval/ApprovalF2.gif"))
                .Controls.Add(New HtmlImageTag("../images/Approval/ApprovalMMCE.gif"))
                .Controls.Add(New HtmlBRTag)
                .Controls.Add(New HtmlImageTag("../images/Approval/ApprovalF25.gif"))
                .Controls.Add(New HtmlImageTag("../images/Approval/ApprovalF3.gif"))
            End With
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            SelectedMonth = RequestAsDateTime("SelectedMonth")
            LocationId = RequestAsInt32("LocationId")
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