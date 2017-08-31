Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports System.Web.UI.WebControls
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions.GenericDataTableExtensions
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace Approval

    Public Class ApprovalProgress
        Inherits UtilitiesAjaxTemplate

#Region "Properties"
        Private Property LayoutTable As New HtmlTableTag

        Private Property GroupBox As New GroupBox()
        Private Property DalApproval As IApproval

        ''' <summary>
        ''' There are two view types. basic and comprehensive. basic has Total progress, elapsed time, comprehensive 
        ''' additionally has processing month, processing location type, processing location
        ''' </summary>
        Private _isBasicView As Boolean = False
        Private _approvalId As Integer = -1
#End Region

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If Not Request("IsBasicView") Is Nothing Then
                _isBasicView = RequestAsBoolean("IsBasicView")
            End If

            If Request("ApprovalId") IsNot Nothing Then
                _approvalId = RequestAsInt32("ApprovalId")
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                SetupFormControls()
                Controls.Add(GroupBox)
            Catch ex As Exception
                Dim errorDiv As New HtmlDivTag
                Dim errorMessage As New LiteralControl With {
                    .Text = ex.Message
                }
                errorDiv.Controls.Add(errorMessage)
                If (GroupBox.Controls.OfType(Of HtmlScriptTag).Any(Function(script As HtmlScriptTag) script.InnerScript.Contains("Process"))) Then
                    errorDiv.Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript, "StopUpdateApprovalProcess();"))
                End If
                Controls.Add(errorDiv)
            End Try
        End Sub

        Private Class ApprovalProgress
            Private ReadOnly _row As DataRow

            Public Sub New(dataRow As DataRow)
                _row = dataRow
            End Sub

            Public ReadOnly Property OperationType As String
                Get
                    Return CType(IIf(_row.AsBool("Approval"), "Approval", "Unapproval"), String)
                End Get
            End Property
            Public ReadOnly Property BatchStatus As String
                Get
                    Return _row.AsString("BatchStatus")
                End Get
            End Property
            Public ReadOnly Property ProcessingMonthField As String
                Get
                    If Not _row("ProcessingMonth") Is DBNull.Value Then
                        Return _row.AsDate("ProcessingMonth").ToString("MMM-yy")
                    End If
                    Return String.Empty
                End Get
            End Property
            Public ReadOnly Property ProcessingLocationTypeField As String
                Get
                    If Not _row("ProcessingLocationType") Is DBNull.Value Then
                        Return _row.AsString("ProcessingLocationType")
                    End If
                    Return String.Empty
                End Get
            End Property
            Public ReadOnly Property ProcessingLocationField As String
                Get
                    If Not _row("ProcessingLocation") Is DBNull.Value Then
                        Return _row.AsString("ProcessingLocation")
                    End If
                    Return String.Empty
                End Get
            End Property
            Public ReadOnly Property LastApprovalProcessedField As String
                Get
                    If Not _row("LastApprovalProcessed") Is DBNull.Value Then
                        Return _row.AsString("LastApprovalProcessed")
                    End If
                    Return String.Empty
                End Get
            End Property

            Public ReadOnly Property HasFinished As Boolean
                Get
                    Return (ProgressField = TotalProgressField) AndAlso (TotalProgressField > 0)
                End Get
            End Property

            Public ReadOnly Property ProgressField As Int32
                Get
                    If Not _row("Progress") Is DBNull.Value Then
                        Return _row.AsInt("Progress")
                    End If
                    Return 0
                End Get
            End Property
            Public ReadOnly Property TotalProgressField As Int32
                Get
                    If Not _row("TotalProgress") Is DBNull.Value Then
                        Return _row.AsInt("TotalProgress")
                    End If
                    Return 0
                End Get
            End Property
            Public ReadOnly Property ElapsedTimeField As String
                Get
                    If Not _row("ElapsedTime") Is DBNull.Value Then
                        Return _row.AsString("ElapsedTime")
                    End If
                    Return String.Empty
                End Get
            End Property

        End Class

        Protected Overridable Sub SetupFormControls()
            Dim rowIndex As Integer
            Dim cellIndex As Integer

            Dim progressTable = DalApproval.BhpbioGetApprovalProgress(_approvalId)

            If progressTable Is Nothing Then
                Throw New Exception("The approval data cannot be retrieved")
            End If

            Dim progress = New ApprovalProgress(progressTable(0))

            With GroupBox
                .ID = "ApprovalGroupBox"
                .Title = progress.OperationType & " Progress: " & progress.BatchStatus
                .CssClass = progress.BatchStatus.ToLower()
                .Controls.Add(LayoutTable)
            End With

            With LayoutTable
                .ID = "ApprovalProgressLayout"
                .Width = Unit.Percentage(100)

                If (Not _isBasicView) Then
                    rowIndex = .Rows.Add(New TableRow)
                    With .Rows(rowIndex)
                        cellIndex = .Cells.Add(New TableCell)
                        .Cells(cellIndex).Controls.Add(New LiteralControl("Processing Month:"))
                        .Cells(cellIndex).Style.Add(HtmlTextWriterStyle.FontWeight, "bold")
                        .Cells(cellIndex).Style.Add(HtmlTextWriterStyle.TextAlign, "right")
                        cellIndex = .Cells.Add(New TableCell)
                        .Cells(cellIndex).Controls.Add(New LiteralControl("&nbsp;"))
                        cellIndex = .Cells.Add(New TableCell)
                        .Cells(cellIndex).Controls.Add(New LiteralControl(progress.ProcessingMonthField))
                    End With
                    rowIndex = .Rows.Add(New TableRow)
                    With .Rows(rowIndex)
                        cellIndex = .Cells.Add(New TableCell)
                        .Cells(cellIndex).Controls.Add(New LiteralControl("Processing Location Type:"))
                        .Cells(cellIndex).Style.Add(HtmlTextWriterStyle.FontWeight, "bold")
                        .Cells(cellIndex).Style.Add(HtmlTextWriterStyle.TextAlign, "right")
                        cellIndex = .Cells.Add(New TableCell)
                        .Cells(cellIndex).Controls.Add(New LiteralControl("&nbsp;"))
                        cellIndex = .Cells.Add(New TableCell)
                        .Cells(cellIndex).Controls.Add(New LiteralControl(progress.ProcessingLocationTypeField))
                    End With
                    rowIndex = .Rows.Add(New TableRow)
                    With .Rows(rowIndex)
                        cellIndex = .Cells.Add(New TableCell)
                        .Cells(cellIndex).Controls.Add(New LiteralControl("Processing Location:"))
                        .Cells(cellIndex).Style.Add(HtmlTextWriterStyle.FontWeight, "bold")
                        .Cells(cellIndex).Style.Add(HtmlTextWriterStyle.TextAlign, "right")
                        cellIndex = .Cells.Add(New TableCell)
                        .Cells(cellIndex).Controls.Add(New LiteralControl("&nbsp;"))
                        cellIndex = .Cells.Add(New TableCell)
                        .Cells(cellIndex).Controls.Add(New LiteralControl(progress.ProcessingLocationField))
                    End With
                End If

                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Last Approval Processed:"))
                    .Cells(cellIndex).Style.Add(HtmlTextWriterStyle.FontWeight, "bold")
                    .Cells(cellIndex).Style.Add(HtmlTextWriterStyle.TextAlign, "right")
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("&nbsp;"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl(progress.LastApprovalProcessedField))
                End With
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Total Progress:"))
                    .Cells(cellIndex).Style.Add(HtmlTextWriterStyle.FontWeight, "bold")
                    .Cells(cellIndex).Style.Add(HtmlTextWriterStyle.TextAlign, "right")
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("&nbsp;"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl($"{progress.ProgressField} of {progress.TotalProgressField} {progress.BatchStatus.ToLower}(s)"))
                End With
                rowIndex = .Rows.Add(New TableRow)
                With .Rows(rowIndex)
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("Elapsed Time:"))
                    .Cells(cellIndex).Style.Add(HtmlTextWriterStyle.FontWeight, "bold")
                    .Cells(cellIndex).Style.Add(HtmlTextWriterStyle.TextAlign, "right")
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl("&nbsp;"))
                    cellIndex = .Cells.Add(New TableCell)
                    .Cells(cellIndex).Controls.Add(New LiteralControl(progress.ElapsedTimeField))
                End With
            End With

            ' Don't check batch status because the engine may not have finished writing to the progress table.
            ' HasFinished checks that both counts are equal, so it's a better test.
            If Not (progress.HasFinished) Then
                ' Queue up another update.
                Dim scriptText = String.Format("UpdateApprovalProcessDelayed({0}, {1}, {2});", _approvalId, _isBasicView.ToString().ToLower(), 1500)
                GroupBox.Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript, scriptText))
            End If
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalApproval Is Nothing Then
                DalApproval = New SqlDalApproval(Resources.Connection)
            End If
        End Sub
    End Class
End Namespace