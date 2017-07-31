Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags

Namespace Approval
    Public Class BulkApproval
        Inherits WebpageTemplates.ApprovalTemplate

#Region "Properties"
        Private Property DalApproval As IApproval
        Private Property DalUtility As IUtility
        Private Property BulkApprovalForm As New Tags.HtmlFormTag
        Private Property HeaderDiv As New Tags.HtmlDivTag()
        Private Property LocationSelector As New ReconcilorLocationSelector
        Private Property MonthFromSelector As New MonthFilter()
        Private Property MonthToSelector As New MonthFilter()
        Private Property HighestLocationType As New SelectBox
        Private Property LowestLocationType As New SelectBox
        Private Property LayoutTable() As New Tags.HtmlTableTag
        Private Property LayoutBox As New GroupBox
        Private Property SubmitApprove As New InputButton
        Private Property SubmitUnApprove As New InputButton
#End Region

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

        End Sub

        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("APPROVAL_BULK"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()
            Dim rowIndex, cellIndex As Integer

            'Borrow that function from utilities
            Dim locationTypes = DalUtility.GetLocationTypeList(NullValues.Int16)
            Dim ignoredLocationTypes = New List(Of String) From {
                "Company", "Bench", "Blast", "Block"
            }
            Dim index As Integer
            For index = 0 To locationTypes.Rows.Count - 1
                If (ignoredLocationTypes.Contains(locationTypes.Rows(index)("Description").ToString())) Then
                    locationTypes.Rows(index).Delete()
                End If
            Next

            With SubmitUnApprove
                .ID = "SubmitUnApprove"
                .Text = "Unapprove"
                .OnClientClick = "return ApproveOrUnapprove('Unapprove');"
            End With

            With SubmitApprove
                .ID = "SubmitApprove"
                .Text = "Approve"
                .OnClientClick = "return ApproveOrUnapprove('Approve');"
            End With

            With MonthFromSelector
                .ID = "MonthfromSelector"
                .Index = "From"
                .SelectedDate = Convert.ToDateTime(Resources.UserSecurity.GetSetting("Bulk_Approval_Month_From", DateTime.Today.ToShortDateString()))
            End With

            With MonthToSelector
                .ID = "MonthToSelector"
                .Index = "To"
                .SelectedDate = Convert.ToDateTime(Resources.UserSecurity.GetSetting("Bulk_Approval_Month_To", DateTime.Today.ToShortDateString()))
            End With

            With HighestLocationType
                .ID = "HighestLocationType"
                .DataSource = locationTypes
                .DataTextField = "Description"
                .DataValueField = "Location_Type_Id"
                .DataBind()
                .SelectedValue = Resources.UserSecurity.GetSetting("Bulk_Approval_Location_Type_From", "1")
            End With

            With LowestLocationType
                .ID = "LowestLocationType"
                .DataSource = locationTypes
                .DataTextField = "Description"
                .DataValueField = "Location_Type_Id"
                .DataBind()
                .SelectedValue = Resources.UserSecurity.GetSetting("Bulk_Approval_Location_Type_To", "1")
            End With

            Dim locId As Int32 = Convert.ToInt32(Resources.UserSecurity.GetSetting("Bulk_Approval_Filter_Location", DoNotSetValues.Int32.ToString))
            With LocationSelector
                .ID = "BulkApproveLocationId"
                If (locId <> DoNotSetValues.Int32) Then
                    .LocationId = locId
                End If
                .LowestLocationTypeDescription = "PIT"
            End With

            With LayoutTable
                .ID = "DefaultBulkApprovalLayout"
                .Width = Unit.Percentage(100)
                .CellPadding = 5
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Reference Location:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(LocationSelector)
                End With
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("From Month:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(MonthFromSelector)
                End With
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("To Month:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(MonthToSelector)
                End With
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Highest Location Type:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(HighestLocationType)
                End With
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Lowest Location Type:"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(LowestLocationType)
                End With
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(SubmitUnApprove)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(SubmitApprove)
                End With
            End With

            With BulkApprovalForm
                .ID = "BulkApprovalForm"
                .Controls.Add(LayoutTable)
            End With

            With HeaderDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Bulk Approval & Unapproval"))
            End With

            With HelpBox
                .Container.Style.Add("display", "none")
                .Container.ID = "ApprovalHelpBox"
                .Content.ID = "ApprovalHelpBoxContent"
                .Title = "Approval Restrictions"
            End With
        End Sub

        Protected Overrides Sub SetupPageLayout()
            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript,
                Tags.ScriptLanguage.JavaScript, "../js/BhpbioApproval.js", String.Empty))

            With LayoutBox
                .Width = Unit.Percentage(100)
                .Controls.Add(BulkApprovalForm)
            End With

            With ReconcilorContent.ContainerContent
                .Controls.Add(HeaderDiv)
                .Controls.Add(LayoutBox)
                .Controls.Add(New Tags.HtmlDivTag(Nothing, "", "tabs_spacer"))

                Dim progressDiv As New Tags.HtmlDivTag
                With progressDiv
                    .ID = "itemDetail"
                    .InnerHtml = ""
                    'If there is an approval pending
                    Dim pendingApproval = DalApproval.GetBhpbioPendingApprovalId(Resources.UserSecurity.UserId.Value, -1)
                    If (pendingApproval IsNot Nothing) Then
                        .Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "DisplayApprovalProgress(" & pendingApproval & ", false);"))
                    Else
                        .Style.Add(HtmlTextWriterStyle.Display, "none")
                    End If
                End With

                .Controls.Add(progressDiv)
            End With

            MyBase.SetupPageLayout()
        End Sub

        Protected Overrides Sub OnPreInit(e As EventArgs)
            MyBase.OnPreInit(e)
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()
            If _DalApproval Is Nothing Then
                _DalApproval = New SqlDalApproval(Resources.Connection)
            End If
            If _DalUtility Is Nothing Then
                _DalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub
    End Class
End Namespace