Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Database
Imports System.Web.UI

Namespace Utilities
    Public Class CustomFieldsMessages
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Dim layoutTable As New Tags.HtmlTableTag
            Dim listDiv As New Tags.HtmlDivTag("listMessagesDiv")
            Dim saveDiv As New Tags.HtmlDivTag("saveMessagesDiv")

            With layoutTable
                .CellSpacing = 2
                .CellPadding = 2
                .AddCellInNewRow()
                .CurrentCell.Controls.Add(listDiv)
                .CurrentCell.VerticalAlign = Web.UI.WebControls.VerticalAlign.Top
                .AddCellInNewRow().Controls.Add(saveDiv)
                .CurrentCell.VerticalAlign = Web.UI.WebControls.VerticalAlign.Top
            End With

            Controls.Add(layoutTable)

            'Call the list
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, _
                            String.Empty, "GetCustomFieldsMessagesList();"))


        End Sub

    End Class
End Namespace
