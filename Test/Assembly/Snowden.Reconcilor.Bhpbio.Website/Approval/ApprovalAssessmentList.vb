Imports System.Data.SqlClient
Imports System.Web.UI
Imports System.Web.UI.HtmlControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates

Namespace Approval
    Public Class ApprovalAssessmentList
        Inherits ReconcilorAjaxPage

#Region " Const "
        Public Const TIMESTAMPFORMAT = "yyyy-MM-dd"
#End Region

#Region " Properties "
        Private Property DalHaulage As IHaulage
        Private Property DalSecurityLocation As ISecurityLocation
        Private Property DalUtility As IUtility
        Private Property DalApproval As IApproval
        Private Property DalImportManager As IImportManager
        Private Property ReturnTable As Control
        Private Property SelectedMonth As DateTime
        Private Property LocationId As Integer
        Private Property LocationName As String
        Private Property LocationType As String
#End Region

#Region " Overrides "
        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                Dim errorMessage As String = ValidateData()

                If errorMessage = String.Empty Then
                    SetupPageControls()
                    Controls.Add(ReturnTable)
                Else
                    JavaScriptAlert(errorMessage, "Please fix the following issues:")
                End If
            Catch ex As SqlException
                JavaScriptAlert("Error while generating approval summary page: {0}", ex.Message)
            Catch e As Exception
                Throw
            End Try
        End Sub

        Protected Overridable Sub SetupPageControls()
            ReturnTable = RenderTable()
            With ReturnTable
                .ID = "ReturnTable"
            End With
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            SelectedMonth = RequestAsDateTime("SelectedMonth")
            LocationId = RequestAsInt32("LocationId")
            LocationName = RequestAsString("LocationName")
            LocationType = RequestAsString("LocationType")
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalHaulage Is Nothing) Then
                DalHaulage = New Database.SqlDal.SqlDalHaulage(Resources.Connection)
            End If
            If (DalSecurityLocation Is Nothing) Then
                DalSecurityLocation = New Database.SqlDal.SqlDalSecurityLocation(Resources.Connection)
            End If
            If (DalUtility Is Nothing) Then
                DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If
            If (DalImportManager Is Nothing) Then
                DalImportManager = New Database.SqlDal.SqlDalImportManager(Resources.Connection)
            End If
            If (DalApproval Is Nothing) Then
                DalApproval = New Database.SqlDal.SqlDalApproval(Resources.Connection)
            End If
            MyBase.SetupDalObjects()
        End Sub
#End Region

        Private Function RenderTable() As Control
            Dim getExceptionCount = Function() As Integer
                                        Return DalUtility.GetBhpbioDataExceptionCount(LocationId, SelectedMonth)
                                    End Function

            Dim getValidationFailures = Function() As Integer
                                            Dim dal = DirectCast(DalImportManager, Database.SqlDal.SqlDalImportManager)
                                            Dim row = dal.GetBhpbioImportList(Date.Today, SelectedMonth.Month, SelectedMonth.Year, LocationId, True).AsEnumerable()
                                            Return row.Sum(Function(r) Convert.ToInt32(r("ValidateCount")))
                                        End Function

            Dim getUngroupedStockpiles = Function() As Integer
                                             Return DalApproval.GetBhpbioUngroupedStockpileCount(LocationId, SelectedMonth)
                                         End Function

            Dim getErrorLinkCell = Function(caption As String, link As String) As Control
                                       Dim anchor As New HtmlAnchor
                                       With anchor
                                           .HRef = String.Format(link, LocationId, SelectedMonth.ToString(TIMESTAMPFORMAT))
                                           .InnerText = caption
                                           If caption.Equals("More Information") Then
                                               .Target = "_blank"
                                           End If
                                       End With
                                       Return anchor
                                   End Function

            Dim errorRow = Function(caption As String, link As String, errors As Integer) As HtmlTableRow
                               Dim row As New HtmlTableRow()
                               Dim cell As HtmlTableCell

                               cell = New HtmlTableCell
                               cell.Controls.Add(getErrorLinkCell(caption, link))
                               row.Cells.Add(cell)

                               ' Saves us creating a new function for the "more info" row, just pass -1.
                               If (errors >= 0) Then
                                   cell = New HtmlTableCell
                                   cell.Controls.Add(New LiteralControl(errors.ToString))
                                   row.Cells.Add(cell)
                               End If

                               Return row
                           End Function

            Dim table As New HtmlTable
            With table.Rows
                .Add(errorRow("Haulage Errors", "../Utilities/HaulageCorrection.aspx?LocationId={0}", DalHaulage.GetBhpbioHaulageErrorCount(LocationId, SelectedMonth)))
                .Add(errorRow("Data Exceptions", "../Utilities/DataExceptionAdministration.aspx?LocationId={0}&SelectedMonth={1}", getExceptionCount()))
                .Add(errorRow("Validation Failures", "../Utilities/ImportAdministration.aspx?Tab=Validation&LocationId={0}&SelectedMonth={1}", getValidationFailures()))
                .Add(errorRow("Ungrouped Stockpiles", "../Stockpiles/Default.aspx?LocationId={0}&SelectedMonth={1}", getUngroupedStockpiles()))
                .Add(errorRow("More Information", DalUtility.GetSystemSetting("BHPBIO_APPROVALASSESSMENT_MOREINFORMATION"), -1))
            End With
            Return table
        End Function
    End Class
End Namespace