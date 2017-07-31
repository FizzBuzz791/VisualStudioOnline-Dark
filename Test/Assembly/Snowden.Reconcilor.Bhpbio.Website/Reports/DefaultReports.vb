Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports System.Web.UI
Imports System.Drawing
Imports System.Web.UI.HtmlControls
Imports System.IO
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports System.Drawing.Imaging

Namespace Reports

    Public Class DefaultReports
        Inherits Snowden.Reconcilor.Core.Website.Reports.DefaultReports

        Private Const _sizeInputControlId As String = "ThumbnailSizeText"
        Private Const _fileExtension As String = "png"
        Private _thumbnailSize As Int32 = 25

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            Try
                'delete previously created thumbnails (if any)
                Dim dir As DirectoryInfo = New DirectoryInfo(String.Format("{0}/images/reports/", System.AppDomain.CurrentDomain.BaseDirectory))
                For Each thumbnailFile As FileInfo In dir.GetFiles("*.thumb." + _fileExtension)
                    thumbnailFile.Delete()
                Next
            Catch ex As UnauthorizedAccessException
                ' it would be good to show a message here, telling the users how this is fixed. But not sure how to have this
                ' filter through to the rendering method (in a way that is thread safe)
            End Try

            'retrieve new size
            Dim sizeText As String
            Dim size As Int32
            If Not Request(_sizeInputControlId) Is Nothing Then
                sizeText = Request(_sizeInputControlId).ToString
                If Int32.TryParse(sizeText, size) Then
                    If size > 0 AndAlso size < 200 Then 'prevent users from using ridiculous sizes
                        _thumbnailSize = size
                    End If
                End If
            End If
        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            Dim submitForm As New HtmlFormTag
            Dim optionRow As New HtmlDivTag()

            Dim label = New HtmlSpanTag()
            label.InnerText = "Thumbnail Size:"

            'Dim si = New 
            Dim sizeInput = New HtmlSelect()
            sizeInput.ID = _sizeInputControlId
            sizeInput.Items.Add(New WebControls.ListItem("Small", "15"))
            sizeInput.Items.Add(New WebControls.ListItem("Medium", "25"))
            sizeInput.Items.Add(New WebControls.ListItem("Large", "35"))
            sizeInput.Value = _thumbnailSize.ToString

            Dim submitButton As InputButton = New InputButton()
            submitButton.Text = "  Refresh  "

            optionRow.Attributes("style") = "vertical-align: middle; border: 1px solid #ccc; padding: 4px; margin-bottom: 4px;"
            label.Attributes("style") = "vertical-align: middle;"
            sizeInput.Attributes("style") = "vertical-align: middle; margin-left: 4px;"
            submitButton.Attributes("style") = "vertical-align: middle; margin-left: 4px;"

            optionRow.Controls.Add(label)
            optionRow.Controls.Add(sizeInput)
            optionRow.Controls.Add(submitButton)

            submitForm.Controls.Add(optionRow)
            ReconcilorContent.ContainerContent.Controls.AddAt(0, submitForm)
        End Sub

        Protected Overrides Sub RenderReportLink(ByVal ReportId As Integer, ByVal ReportRow As DataRow, ByVal GroupBoxTitle As String)
            Dim reportLink, reportName, thumbnailFileName, relativePath As String
            Dim rn As New Random

            'Check that the report is allowed also
            If Resources.UserSecurity.HasAccess("Report_" & ReportId.ToString) Then
                reportName = ReportRow("Name").ToString

                If ReportHasCustomParametersPage(reportName) Then
                    reportLink = String.Format("./{0}.aspx", reportName.Replace("Bhpbio", ""))
                Else
                    reportLink = "./ReportsView.aspx?ReportId=" & ReportRow("Report_Id").ToString
                End If


                thumbnailFileName = String.Format("{0}-{1}.thumb.{2}", reportName, rn.Next(0, Integer.MaxValue), _fileExtension) 'append random number such that browser doesn't cache thumbnail
                relativePath = ResizeImage(thumbnailFileName, reportName)
                Dim thumbnailTag = New HtmlImageTag(relativePath)
                Dim reportLinkTag = New HtmlAnchorTag(reportLink, String.Empty, ReportRow("Description").ToString)

                ' css classes woul dbe much better here, but reconcilor doesn't make this easy to do
                thumbnailTag.Attributes("style") = "border: 1px solid #ccc; padding: 2px; vertical-align: middle; margin: 2px;"
                reportLinkTag.Attributes("style") = "vertical-align: middle; padding-left: 8px;"

                With ReportGroupBoxes(GroupBoxTitle)
                    .Controls.Add(New HtmlImageAnchorTag(String.Format("../images/reports/{0}.{1}", reportName, _fileExtension), thumbnailTag, thumbnailTag, "_blank", False))
                    .Controls.Add(reportLinkTag)
                    .Controls.Add(New HtmlBRTag)
                End With
                End If
        End Sub

        ' most of the reports go to the ReportsView page to render the parameters (which in turn calls ReportsStandardRender)
        ' but for some we need a custom parameters page. If this method returns true then the user will be sent to
        ' /Reports/<reportName>.aspx, which can render whatever the user wants
        '
        ' If the reportName starts with a Bhpbio, then this will be removed
        Protected Function ReportHasCustomParametersPage(reportName As String) As Boolean
            Return reportName = "BhpbioYearlyReconciliationReport"
        End Function

        Private Function ResizeImage(ByVal thumbnailFileName As String, ByVal reportName As String) As String

            Dim sourceFile As FileInfo = New FileInfo(String.Format("{0}/images/reports/{1}.{2}", System.AppDomain.CurrentDomain.BaseDirectory, reportName, _fileExtension))

            If sourceFile.Exists Then
                Try
                    Using img As Image = Image.FromFile(sourceFile.FullName)
                        Dim thumbnail As Bitmap = New Bitmap(_thumbnailSize, _thumbnailSize, img.PixelFormat)
                        Dim g As Graphics = Graphics.FromImage(thumbnail)

                        g.CompositingQuality = Drawing2D.CompositingQuality.HighQuality
                        g.SmoothingMode = Drawing2D.SmoothingMode.HighQuality
                        g.InterpolationMode = Drawing2D.InterpolationMode.HighQualityBilinear

                        Dim rect As Rectangle = New Rectangle(0, 0, _thumbnailSize, _thumbnailSize)
                        g.DrawImage(img, rect)

                        ' save to file in GIF format
                        thumbnail.Save(String.Format("{0}/images/reports/{1}", System.AppDomain.CurrentDomain.BaseDirectory, thumbnailFileName), _
                            System.Drawing.Imaging.ImageFormat.Png)
                        Return String.Format("../images/reports/{0}", thumbnailFileName) 'return relative path for HtmlImageTag
                    End Using
                Catch ex As Exception
                    Return Nothing
                End Try
            End If

            Return Nothing

        End Function

    End Class
End Namespace