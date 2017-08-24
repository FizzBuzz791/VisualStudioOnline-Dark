Imports System.Web.UI
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Namespace Utilities
    Public Class Weathering
        Inherits WebpageTemplates.UtilitiesTemplate

        Protected Property DalUtility As IUtility

        Protected ReadOnly SpanText As String = String.Join("", Enumerable.Repeat("&nbsp;", 13).ToArray())

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            DalUtility = New SqlDalUtility(Resources.Connection)
        End Sub

        Protected Overrides Sub SetupPageLayout()
            Dim weatheringContent As Tags.HtmlDivTag
            Dim ReturnTable As ReconcilorTable
            Dim headerDiv As New Tags.HtmlDivTag

            MyBase.SetupPageLayout()

            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Weathering"))
            End With

            With ReconcilorContent.ContainerContent
                .Controls.Add(headerDiv)
                .Controls.Add(New Tags.HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
            End With

            weatheringContent = New Tags.HtmlDivTag("WeatheringContent")

            ReconcilorContent.ContainerContent.Controls.Add(weatheringContent)

            Dim table = DalUtility.GetWeatheringList()
            table.Columns("DisplayValue").ColumnName = "Display Value"

            table.Columns.Add("Display")
            Dim colour As String

            For Each row As DataRow In table.Rows
                colour = row.AsString("Colour")
                row("Display") = $"<span id=""{ID}"" style=""background-color:{colour}"">{SpanText}</span>"
            Next

            ReturnTable = New ReconcilorTable(table)
            With ReturnTable
                .ExcludeColumns = {"Id"}
                .ID = "ReturnTable"
                .NegativeValueColour = Drawing.Color.Black
                .DataBind()
            End With
            ReturnTable.Height = 200 ' Restrict the height to ensure everything fits without _page_ scrolling.

            weatheringContent.Controls.Add(ReturnTable)

        End Sub

    End Class

End Namespace