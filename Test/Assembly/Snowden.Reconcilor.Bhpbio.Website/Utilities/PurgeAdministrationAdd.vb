Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.WebpageTemplates
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports System.Web.UI

Namespace Utilities
    Public Class PurgeAdministrationAdd
        Inherits PurgeAdministrationTemplate


        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Me.PurgeableMonths = MyBase.GetPurgeableQuarters().ToList
            Controls.Add(CreateLayout())
        End Sub

        Private _purgeableMonths As IEnumerable(Of DateTime)
        Public Property PurgeableMonths() As IEnumerable(Of DateTime)
            Get
                If _purgeableMonths Is Nothing Then
                    Return Enumerable.Empty(Of DateTime)()
                End If
                Return _purgeableMonths
            End Get
            Private Set(ByVal value As IEnumerable(Of DateTime))
                _purgeableMonths = value
            End Set
        End Property
        Private Function GetMonths() As SelectBoxFormless
            Dim dictionary As Dictionary(Of String, String) = PurgeableMonths().ToDictionary(Function(o) o.ToString("dd-MMM-yyyy"), Function(o) o.ToString("MMM yyyy"))
            Dim control As New SelectBoxFormless
            With control
                .ID = "Months"
                .DataSource = dictionary
                .DataValueField = "Key"
                .DataTextField = "Value"
                .Width = 100
                .DataBind()
            End With
            Return control
        End Function

        Private Function GetSubmitButton() As InputButtonFormless
            Dim control As New InputButtonFormless
            With control
                .ID = "SubmitButton"
                .Text = "Add"
                .Attributes("onclick") = "SavePurgeRequest();"
            End With
            Return control
        End Function

        Private Function GetCancelButton() As InputButtonFormless
            Dim control As New InputButtonFormless
            With control
                .ID = "CancelButton"
                .Text = "Cancel"
                .Attributes("onclick") = "CancelPurgeRequest();"
            End With
            Return control
        End Function

        Protected Overridable Function CreateLayout() As GroupBox
            Dim groupBox As New GroupBox
            With groupBox
                .Title = "Add Purge Request"
                .Width = 530
            End With
            Dim table As New HtmlTableTag
            With table
                .CellSpacing = 2
                .CellPadding = 2

                .AddCellInNewRow()
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Right
                .CurrentCell.Width = 150
                .CurrentCell.Controls.Add(New LiteralControl("<b>Month (Quarter End):</b>"))

                .AddCell()
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top
                .CurrentCell.Controls.Add(GetMonths())

                .AddCell()
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top
                .CurrentCell.Controls.Add(New LiteralControl("<b>Note:</b>&nbsp;Only the last month of each quarter that has been fully approved may be selected"))

                .AddCellInNewRow()
                .CurrentCell.Controls.Add(New LiteralControl("&nbsp;"))
                .AddCell()
                .CurrentCell.Controls.Add(GetSubmitButton)
                .CurrentCell.Controls.Add(New LiteralControl("&nbsp;"))
                .CurrentCell.Controls.Add(GetCancelButton)
            End With
            groupBox.Controls.Add(table)
            Return groupBox
        End Function

    End Class
End Namespace