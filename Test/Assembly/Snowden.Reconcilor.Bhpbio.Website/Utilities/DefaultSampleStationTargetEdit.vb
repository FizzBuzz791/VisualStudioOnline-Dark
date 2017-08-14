Imports System.Data.SqlClient
Imports System.Web.UI
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls.Inputs
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates

Namespace Utilities
    Public Class DefaultSampleStationTargetEdit
        Inherits UtilitiesAjaxTemplate

        Protected Property IsNew As Boolean = True
        Protected Property SampleStationId As Integer
        Protected Property SampleStationTargetId As Integer?
        Protected Property DalUtility As IUtility

        Protected Property EditForm As HtmlFormTag = New HtmlFormTag

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If Request("TargetId") IsNot Nothing Then
                SampleStationTargetId = RequestAsInt32("TargetId")
                IsNew = False
            End If

            SampleStationId = RequestAsInt32("SampleStationId")
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalUtility Is Nothing Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                SetupFormControls()
                Controls.Add(EditForm)
            Catch ex As SqlException
                JavaScriptAlert($"Error while setting up Targets form: {ex.Message}")
            End Try
        End Sub

        Protected Overridable Sub SetupFormControls()
            Dim targetSampleStationTarget As DataTable = Nothing
            If Not IsNew AndAlso SampleStationTargetId IsNot Nothing Then
                targetSampleStationTarget = DalUtility.GetBhpbioSampleStationTarget(CType(SampleStationTargetId, Integer))
                SampleStationId = Integer.Parse(targetSampleStationTarget.Rows(0)("SampleStation_Id").ToString())
            End If

            Dim layoutTable = New HtmlTableTag
            With layoutTable
                Dim cell = .AddCellInNewRow()
                cell.Controls.Add(New LiteralControl("<hr>"))
                cell = .AddCellInNewRow()
                cell.Controls.Add(New LiteralControl("Effective From:"))
                cell = .AddCell()
                Dim monthFromPicker = New MonthFilter() With {
                    .ID = "MonthFrom",
                    .Index = "MonthFrom",
                    .SelectedDate = DateTime.Today
                }
                If Not IsNew Then
                    monthFromPicker.SelectedDate = DateTime.Parse(targetSampleStationTarget.Rows(0)("StartDate").ToString())
                End If
                cell.ColumnSpan = 3
                cell.Controls.Add(monthFromPicker)

                cell = .AddCell()
                cell.Controls.Add(New LiteralControl("Effective To:"))
                cell = .AddCell()
                Dim dateTo = New LiteralControl()
                If IsNew Then
                    dateTo.Text = "Current"
                Else
                    dateTo.Text = targetSampleStationTarget.Rows(0)("EndDate").ToString()
                End If
                cell.ColumnSpan = 2
                cell.Controls.Add(dateTo)

                cell = .AddCellInNewRow()
                cell.Controls.Add(New LiteralControl("Coverage Thresholds:"))
                cell = .AddCell()
                cell.Controls.Add(New LiteralControl("Low <"))
                cell = .AddCell()
                Dim coverageTarget = New InputText() With {
                    .ID = "CoverageTarget",
                    .NumericOnly = True
                }
                If Not IsNew Then
                    coverageTarget.Text = CType(Decimal.Parse(targetSampleStationTarget.Rows(0)("CoverageTarget").ToString()) * 100, Integer).ToString()
                End If
                cell.Controls.Add(coverageTarget)
                cell = .AddCell()
                cell.Controls.Add(New LiteralControl("<= Medium <"))
                cell = .AddCell()
                Dim coverageWarning = New InputText() With {
                    .ID = "CoverageWarning",
                    .NumericOnly = True
                }
                If Not IsNew Then
                    coverageWarning.Text = CType(Decimal.Parse(targetSampleStationTarget.Rows(0)("CoverageWarning").ToString()) * 100, Integer).ToString()
                End If
                cell.Controls.Add(coverageWarning)
                cell = .AddCell()
                cell.Controls.Add(New LiteralControl("<= High"))

                cell = .AddCellInNewRow()
                cell.Controls.Add(New LiteralControl("Ratio Thresholds:"))
                cell = .AddCell()
                cell.Controls.Add(New LiteralControl("Low <"))
                cell = .AddCell()
                Dim ratioTarget = New InputText() With {
                    .ID = "RatioTarget",
                    .NumericOnly = True
                }
                If Not IsNew Then
                    ratioTarget.Text = targetSampleStationTarget.Rows(0)("RatioTarget").ToString()
                End If
                cell.Controls.Add(ratioTarget)
                cell = .AddCell()
                cell.Controls.Add(New LiteralControl("<= Medium <"))
                cell = .AddCell()
                Dim ratioWarning = New InputText() With {
                    .ID = "RatioWarning",
                    .NumericOnly = True
                }
                If Not IsNew Then
                    ratioWarning.Text = targetSampleStationTarget.Rows(0)("RatioWarning").ToString()
                End If
                cell.Controls.Add(ratioWarning)
                cell = .AddCell()
                cell.Controls.Add(New LiteralControl("<= High"))

                cell = .AddCellInNewRow()
                Dim saveButton = New InputButton With {
                    .ID = "SaveTargetSubmit",
                    .Text = String.Format(" Save ")
                }
                cell.Controls.Add(saveButton)
                cell.Controls.Add(New LiteralControl("&nbsp;&nbsp;"))
                Dim cancelButton = New InputButton With {
                    .ID = "CancelTargetSubmit",
                    .Text = String.Format(" Cancel"),
                    .OnClientClick = "return CancelEditSampleStationTarget();"
                }
                cell.Controls.Add(cancelButton)
            End With

            EditForm.ID = "SampleStationTargetsEditForm"
            EditForm.OnSubmit = $"return SubmitForm('{EditForm.ID}', 'itemList', './DefaultSampleStationTargetSave.aspx?TargetId={SampleStationTargetId}&SampleStationId={SampleStationId}');"
            EditForm.Controls.Add(layoutTable)
        End Sub
    End Class
End Namespace