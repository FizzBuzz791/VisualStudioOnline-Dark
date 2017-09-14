Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions

Namespace Utilities
    Public Class StratigraphyHierarchy
        Inherits WebpageTemplates.UtilitiesTemplate

        Protected Const SORT_ORDER As String = "SortOrder"
        Protected Const STRAT_NUM As String = "Strat Num"

        Protected ReadOnly SpanText As String = String.Join("", Enumerable.Repeat("&nbsp;", 13).ToArray())

        Protected Property DalUtility As IUtility

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalUtility Is Nothing Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub

        Protected Overrides Sub SetupPageLayout()
            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", String.Empty))

            Dim headerDiv As New Tags.HtmlDivTag
            Dim ReturnTable As ReconcilorTable
            Dim stratigraphyHierarchyContent As Tags.HtmlDivTag

            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Stratigraphy List"))
            End With

            With ReconcilorContent.ContainerContent
                .Controls.Add(headerDiv)
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
            End With

            stratigraphyHierarchyContent = New Tags.HtmlDivTag("StratigraphyHierarchyContent")

            ReconcilorContent.ContainerContent.Controls.Add(stratigraphyHierarchyContent)

            MyBase.SetupPageLayout()

            Dim stratHierachyType = DalUtility.GetBhpbioStratigraphyHierarchyTypeList

            Dim pivotColumns = BuildPivotColumns(stratHierachyType)

            Dim stratData = DalUtility.GetBhpbioStratigraphyHierarchyList

            Dim formattedStratTable = BuildDisplayTable(stratData, pivotColumns)

            ReturnTable = New ReconcilorTable(formattedStratTable)
            With ReturnTable
                .ExcludeColumns = {"Id"}
                .ID = "ReturnTable"
                .DataBind()
            End With
            ReturnTable.Height = 400 ' Restrict the height to ensure everything fits without _page_ scrolling.

            stratigraphyHierarchyContent.Controls.Add(ReturnTable)

        End Sub

        Public Function BuildDisplayTable(sourceTable As DataTable, pivotColumns As Dictionary(Of Int32, String)) As DataTable
            Dim returnDataTable = New DataTable()

            For Each item In pivotColumns
                returnDataTable.Columns.Add(item.Value)
            Next

            returnDataTable.Columns.Add("Description")
            returnDataTable.Columns.Add(STRAT_NUM)
            returnDataTable.Columns.Add("Colour")
            returnDataTable.Columns.Add("Display")

            AddLevelForParent(sourceTable, returnDataTable, 1, Nothing)

            Return returnDataTable
        End Function

        Public Function BuildPivotColumns(hierarchy As DataTable) As Dictionary(Of Int32, String)
            Dim dictionary = New Dictionary(Of Int32, String)

            For Each row As DataRow In hierarchy.Rows
                Dim level = CInt(row("Level"))
                Dim type = CStr(row("Type"))
                dictionary.Add(level, type)
            Next

            Return dictionary
        End Function

        Public Sub AddLevelForParent(ByRef sourceTable As DataTable, ByRef outputTable As DataTable, level As Int32, parentId As Int32?)
            Dim filter = BuildFilter(level, parentId)

            Dim levelRows = sourceTable.Select(filter, SORT_ORDER)

            For Each row In levelRows
                Dim newRow = outputTable.NewRow()

                Dim typeCol As String = row.AsString("Type")
                Dim stratigraphy As String = row.AsString("Stratigraphy")
                Dim description As String = row.AsString("Description")
                Dim colour As String = row.AsString("Colour")
                Dim stratNum As String = Nothing
                Dim rowId As Int32

                If Not IsDBNull(row("StratNum")) Then
                    stratNum = row.AsString("StratNum")
                End If

                rowId = row.AsInt("id")

                newRow(typeCol) = stratigraphy
                newRow("Description") = description
                newRow("Colour") = colour
                newRow(STRAT_NUM) = stratNum
                newRow("Display") = $"<span id=""{rowId}"" style=""background-color:{colour}"">{SpanText}</span>"   '13 spaces gives a nice column width in the span

                outputTable.Rows.Add(newRow)
                AddLevelForParent(sourceTable, outputTable, level + 1, rowId)
            Next

        End Sub

        Public Function BuildFilter(level As Int32, parentId As Integer?) As String
            Return If(parentId Is Nothing, $"Level={level}", $"Level={level} and Parent_Id = {parentId}")
        End Function

    End Class
End Namespace