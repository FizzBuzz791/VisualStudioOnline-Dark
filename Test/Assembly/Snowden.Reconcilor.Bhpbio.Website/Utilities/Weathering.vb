Imports System.Web.UI
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Namespace Utilities
    Public Class Weathering
        Inherits WebpageTemplates.UtilitiesTemplate

        Private _weatheringContent As Tags.HtmlDivTag
        Protected Property ReturnTable As ReconcilorTable
        Protected Property DalUtility As IUtility

        Protected Overrides Sub SetupPageLayout()
            Dim colour As String

            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", String.Empty))

            Dim headerDiv As New Tags.HtmlDivTag
            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Weathering"))
            End With

            With ReconcilorContent.ContainerContent
                .Controls.Add(headerDiv)
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
            End With

            _weatheringContent = New Tags.HtmlDivTag("WeatheringContent")

            ReconcilorContent.ContainerContent.Controls.Add(_weatheringContent)

            MyBase.SetupPageLayout()
            ' *Must* add this script here so that it comes *after* common.js
            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioCommon.js", String.Empty))

            DalUtility = New SqlDalUtility(Resources.Connection)

            Dim table = DalUtility.GetWeatheringList()
            table.Columns("DisplayValue").ColumnName = "Display Value"

            table.Columns.Add("Display")
            For Each row As DataRow In table.Rows
                colour = CStr(row("Colour"))
                row("Display") = $"<span id=""{ID}"" style=""background-color:{colour}"">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>"
            Next

            ReturnTable = New ReconcilorTable(table)
            With ReturnTable
                .ExcludeColumns = {"Id"}
                .ID = "ReturnTable"
                .NegativeValueColour = Drawing.Color.Black
                .DataBind()
            End With
            ReturnTable.Height = 200 ' Restrict the height to ensure everything fits without _page_ scrolling.

            _weatheringContent.Controls.Add(ReturnTable)

        End Sub

    End Class

End Namespace