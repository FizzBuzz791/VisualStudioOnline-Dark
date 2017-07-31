Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal

Namespace Utilities
    Public Class MonthlyApprovalList
        Inherits Snowden.Reconcilor.Core.Website.Utilities.MonthlyApprovalList

        Protected Overrides Sub SetupControls()
            MyBase.SetupControls()

            ApprovalGroup.Title = "Calculated Data Approval"
            UnapproveGroup.Title = "Calculated Data Unapproval"
        End Sub

        Protected Overrides Sub ProcessData()
            Dim LastApprovedMonth, FirstMonth, ApprovalMonth As DateTime
            Dim dateFormat = Application("DateFormat").ToString()

            DalUtility.GetMonthlyApprovalMonth(LastApprovedMonth, ApprovalMonth, FirstMonth)

            ApprovalLabel.Text = String.Format("Approve calculated data and set the recalculation start date to: <b> {0} </b> <br />", ApprovalMonth.EndOfMonth.ToString(dateFormat))
            ApproveDate.Value = ApprovalMonth.ToString("dd-MMM-yyyy")

            If LastApprovedMonth > DateTime.MinValue Then
                UnapprovalLabel.Text = String.Format("Unapprove calculated data and set the recalculation start date to: <b> {0} </b> <br />", LastApprovedMonth.AddDays(-1).ToString(dateFormat))
                UnapproveDate.Value = LastApprovedMonth.ToString("dd-MMM-yyyy")
            Else
                UnapprovalLabel.Text = "There are no months that have been approved."
                UnapproveDate.Value = ""
                UnapproveButton.Visible = False
            End If
        End Sub

    End Class

    Module DateTimeExtensions
        <Runtime.CompilerServices.Extension()> _
        Public Function EndOfMonth(ByRef d As DateTime) As DateTime
            Return New DateTime(d.Year, d.Month, 1).AddMonths(1).AddDays(-1)
        End Function
    End Module
End Namespace
