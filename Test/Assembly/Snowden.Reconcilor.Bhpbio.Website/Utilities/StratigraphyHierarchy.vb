Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.Extensibility.DependencyFactoryKeys
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.Website.Internal.SettingsModule
Imports System.Web.UI.WebControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports System.Text
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace Utilities
    Public Class StratigraphyHierarchy
        Inherits WebpageTemplates.UtilitiesTemplate

        Protected Const SORT_ORDER As String = "SortOrder"
        Protected Const STRAT_NUM As String = "Strat Num"

        Protected Property ReturnTable As ReconcilorTable
        Protected Property DalUtility As IUtility

        Private _stratigraphyHierarchyContent As Tags.HtmlDivTag

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

        End Sub

        Protected Overrides Sub SetupPageLayout()
            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", String.Empty))

            Dim headerDiv As New Tags.HtmlDivTag
            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Stratigraphy List"))
            End With

            With ReconcilorContent.ContainerContent
                .Controls.Add(headerDiv)
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
            End With

            _stratigraphyHierarchyContent = New Tags.HtmlDivTag("StratigraphyHierarchyContent")

            ReconcilorContent.ContainerContent.Controls.Add(_stratigraphyHierarchyContent)

            MyBase.SetupPageLayout()
            ' *Must* add this script here so that it comes *after* common.js
            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioCommon.js", String.Empty))

            DalUtility = New SqlDalUtility(Resources.Connection)

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

            _stratigraphyHierarchyContent.Controls.Add(ReturnTable)

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

        Public Sub AddLevelForParent(ByRef sourceTable As DataTable, ByRef outputTable As DataTable, level As Int32, parent As Int32?)
            Dim filter = BuildFilter(level, parent)

            Dim levelRows = sourceTable.Select(filter, SORT_ORDER)

            For Each row In levelRows
                Dim newRow = outputTable.NewRow()

                Dim typeCol As String = CStr(row("Type"))
                Dim stratigraphy As String = CStr(row("Stratigraphy"))
                Dim description As String = CStr(row("Description"))
                Dim colour As String = CStr(row("Colour"))
                Dim stratNum As String = Nothing
                Dim id As Int32

                If Not IsDBNull(row("StratNum")) Then
                    stratNum = CStr(row("StratNum"))
                End If

                id = CInt(row("id"))

                newRow(typeCol) = stratigraphy
                newRow("Description") = description
                newRow("Colour") = colour
                newRow(STRAT_NUM) = stratNum
                newRow("Display") = $"<span id=""{id}"" style=""background-color:{colour}"">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>"

                outputTable.Rows.Add(newRow)
                AddLevelForParent(sourceTable, outputTable, level + 1, id)
            Next

        End Sub

        Public Function BuildFilter(level As Int32, parent As Integer?) As String
            Return If(parent Is Nothing, $"Level={level}", $"Level={level} and Parentid = {parent}")
        End Function

    End Class
End Namespace