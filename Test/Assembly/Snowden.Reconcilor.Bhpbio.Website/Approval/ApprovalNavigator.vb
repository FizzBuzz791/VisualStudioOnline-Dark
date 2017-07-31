Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports System.Web.UI.HtmlControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports System.Data.SqlClient
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Common.Web.BaseHtmlControls

Namespace Approval

    Public Class ApprovalNavigator
        Inherits ReconcilorAjaxPage


#Region "Properties"
        Private Property LocationSelectorForm As New HtmlFormTag()
        Private Property LocationSelector As New Controls.ReconcilorLocationSelector()
        Private Property MonthFilter As New MonthFilter()
        Private Property HyperlinkApprovalStatus As New HtmlAnchor()
        Private Property HyperlinkApprovals As New HtmlAnchor()
        Private Property LayoutTable As New HtmlTableTag()
#End Region

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()
        End Sub



        Protected Sub SetupControls()
            Dim approvalMonth As DateTime
            Dim locationId As Int32
            Dim settingDate As String = Resources.UserSecurity.GetSetting("Approval_Filter_Date", DateTime.Now.ToString("O"))
            Dim settingLocation As String = Resources.UserSecurity.GetSetting("Approval_Filter_LocationId", "0")

            With LocationSelector
                .ID = "LocationId"
                .LowestLocationTypeDescription = "PIT"
                If Int32.TryParse(settingLocation, locationId) AndAlso locationId > 0 Then
                    .LocationId = locationId
                End If
                If DateTime.TryParse(settingDate, approvalMonth) Then
                    MonthFilter.SelectedDate = approvalMonth
                    .StartDate = approvalMonth
                End If

            End With

            With MonthFilter
                .OnSelectChangeCallback = "CheckMonthLocationApproval();"
            End With

            With HyperlinkApprovalStatus
                .ID = "HyperlinkApprovalStatus"
                .InnerHtml = "Approval Summary"
                .HRef = "#"
                .Attributes.Add("onclick", "return LoadApprovalSummary();")
            End With

            With HyperlinkApprovals
                .ID = "HyperlinkApprovals"
                .InnerHtml = "Monthly Approvals"
                .HRef = "#"
                .Attributes.Add("onclick", "return _LoadFactorApprovalScreen();")
            End With
        End Sub

        Private Sub SetLayout()
            With LayoutTable
                .AddCellInNewRow().Controls.Add(New LiteralControl("Month:"))
                .AddCell().Controls.Add(MonthFilter)

                Dim rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    Dim cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("&nbsp;"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).ID = "oldLocationSelectorCell"
                    .Cells(cellIndex).Controls.Add(HyperlinkApprovalStatus)
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    'Dim cellIndex = .Cells.Add(New TableCell)
                    '.Cells(cellIndex).Controls.Add(New LiteralControl("Location:"))
                    Dim cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).ID = "locationSelectorCell"
                    .Cells(cellIndex).Controls.Add(LocationSelector)
                    .Cells(cellIndex).ColumnSpan = 2
                End With

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    Dim cellIndex = .Cells.Add(New TableCell)

                    .Cells(cellIndex).Controls.Add(New LiteralControl("&nbsp;"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(HyperlinkApprovals)
                End With

            End With
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                Dim errorMessage As String = ValidateData()

                If errorMessage = String.Empty Then

                    SetupControls()
                    SetLayout()

                    With LocationSelectorForm
                        .ID = "LocationSelectionForm"
                        .Controls.Add(LayoutTable)
                    End With


                    Controls.Add(LocationSelectorForm)
                Else
                    JavaScriptAlert(errorMessage, "Please fix the following issues:")
                End If
            Catch ex As SqlException
                JavaScriptAlert("Error while loading location selector: {0}", ex.Message)
            End Try
        End Sub
    End Class
End Namespace
