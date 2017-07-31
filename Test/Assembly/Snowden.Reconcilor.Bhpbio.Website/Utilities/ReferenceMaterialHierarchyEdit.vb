Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports System.Web.UI.WebControls

Namespace Utilities
    Public Class ReferenceMaterialHierarchyEdit
        Inherits Core.Website.Utilities.ReferenceMaterialHierarchyEdit

        Protected Overrides Sub LayoutForm()
            MyBase.LayoutForm()

            Dim Row As TableRow
            Dim Cell As TableCell

            Row = New TableRow
            Cell = New TableCell

            Cell.Controls.Add(New ReconcilorControls.FieldLabel("Attached Locations:"))
            Cell.HorizontalAlign = HorizontalAlign.Right
            Cell.VerticalAlign = VerticalAlign.Top
            Row.Cells.Add(Cell)

            Cell = New TableCell
            Cell.Controls.Add(New Tags.HtmlDivTag("materialLocationList"))
            Row.Cells.Add(Cell)

            LayoutTable.Rows.AddAt(LayoutTable.Rows.Count - 1, Row)
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            'RunAjax
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetBhpbioMaterialTypeLocationList('" & MaterialTypeId.Value.ToString & "');"))
        End Sub
    End Class
End Namespace