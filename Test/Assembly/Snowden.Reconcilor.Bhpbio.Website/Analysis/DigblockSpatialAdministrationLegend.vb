Imports System.Text
Imports Snowden.Reconcilor.Core.Website.Analysis
Imports System.Web.UI
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI.WebControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace Analysis
    Public Class DigblockSpatialAdministrationLegend
        Inherits Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates.AnalysisAjaxTemplate

#Region "Properties"
        Private _locationId As Int32
        Private _dalUtility As IUtility
        Private _disposed As Boolean

        Protected Property DalUtility() As IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As IUtility)
                _dalUtility = value
            End Set
        End Property
#End Region


#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If (Not _dalUtility Is Nothing) Then
                            _dalUtility.Dispose()
                            _dalUtility = Nothing
                        End If
                    End If
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region


        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim validMessage As String = ValidateData()

            Try
                DrawLegend()

            Catch ex As SqlClient.SqlException
                JavaScriptAlert(ex.Message)
            End Try
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            _locationId = RequestAsInt32("LocationId")
        End Sub


        Public Sub LoadVarianceSettings(ByVal percentage As Dictionary(Of String, String), _
         ByVal colour As Dictionary(Of String, String))
            Dim rows As DataRow()
            Dim variances As DataTable
            Dim variance As String

            variances = _dalUtility.GetBhpbioAnalysisVarianceList(_locationId, False, False)

            For i As Integer = DigblockSpatialCommon.VarianceIndexA To DigblockSpatialCommon.VarianceIndexE
                variance = DigblockSpatialCommon.VarianceLetter(i)
                rows = variances.Select("VarianceType = '" & variance & "'")

                If rows.Length = 1 Then
                    percentage.Add(variance, rows(0)("Percentage").ToString)
                    colour.Add(variance, rows(0)("Color").ToString)
                Else
                    percentage.Add(variance, DalUtility.GetSystemSetting("VARIANCE_PERCENTAGE_" & variance))
                    colour.Add(variance, DalUtility.GetSystemSetting("VARIANCE_COLOUR_" & variance))
                End If
            Next

        End Sub

        Protected Overridable Sub DrawLegend()
            Dim legendTable As New Common.Web.BaseHtmlControls.Tags.HtmlTableTag
            Dim variancePercentages As New Dictionary(Of String, String)
            Dim varianceColours As New Dictionary(Of String, String)
            Dim initaliseScript As New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript)
            Dim previousVariance As String

            LoadVarianceSettings(variancePercentages, varianceColours)

            With legendTable
                .AddCellInNewRow().Controls.Add(New LiteralControl("<b>Percentage</b>"))
                .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
                .AddCell().Controls.Add(New LiteralControl("<b>Circle</b>"))
                .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
                .AddCell().Controls.Add(New LiteralControl("<b>Colour</b>"))

                previousVariance = ""
                'For Each variance In varianceRadius.Keys
                '    hiddenInp = New ReconcilorControls.InputTags.InputHidden()
                '    hiddenInp.ID = "color" & variance
                '    hiddenInp.Value = varianceColours(variance)

                '    If previousVariance = "" Then
                '        percentageDesc = variancePercentages(variance) & "+"
                '    Else
                '        percentageDesc = variancePercentages(variance) & " - " & variancePercentages(previousVariance)
                '    End If



                '    initaliseScript.InnerScript &= "PreviewVarianceColour2(document.getElementById('color" & variance & "')); "

                '    .AddCellInNewRow().HorizontalAlign = HorizontalAlign.Center
                '    .CurrentCell.Controls.Add(New LiteralControl(percentageDesc))
                '    .CurrentCell.Controls.Add(hiddenInp)
                '    .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
                '    .AddCell().Controls.Add(New LiteralControl("NO CIRCLE"))
                '    .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
                '    .AddCell().ID = "thatch" & variance
                '    .CurrentCell.Controls.Add(New LiteralControl("&nbsp;"))

                '    previousVariance = variance
                'Next

                .AddCellInNewRow().HorizontalAlign = HorizontalAlign.Center
                .CurrentCell.Controls.Add(New LiteralControl("No Data"))
                .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
                .AddCell().Controls.Add(New LiteralControl("NO CIRCLE"))
                .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
                .AddCell().Controls.Add(New LiteralControl("&nbsp;"))
                .CurrentCell.BackColor = Drawing.Color.White
            End With

            Controls.Add(legendTable)
            Controls.Add(initaliseScript)
            If (CheckSecurity AndAlso Resources.UserSecurity.HasAccess("ANALYSIS_SPATIAL_VARIANCE_SETUP")) Then
                legendTable.Attributes("onClick") = "window.location = './DigblockSpatialVarianceView.aspx';"
            End If
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub


    End Class
End Namespace
