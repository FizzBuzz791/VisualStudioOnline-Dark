Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Database
Imports System.Web.UI

Namespace Utilities
    Public Class HelpDocumentation
        Inherits Core.WebDevelopment.WebpageTemplates.ReconcilorWebpage

        Protected Function CreatePDFImage() As Tags.HtmlImageTag
            Dim pdfImage As New Tags.HtmlImageTag("..\images\PDF.gif")
            pdfImage.Border = 0
            pdfImage.Height = 30
            Return pdfImage
        End Function

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()
            Dim trainingGuide As New Tags.HtmlAnchorTag("..\Files\Bhpbio\HelpDocumentation\RECONCILOR BHPBIO Training Guide.pdf")
            Dim userGuide As New Tags.HtmlAnchorTag("..\Files\Bhpbio\HelpDocumentation\Reconcilor BHPBIO User Guide.pdf")
            Dim userManual As New Tags.HtmlAnchorTag("..\Files\Bhpbio\HelpDocumentation\Reconcilor BHPBIO User Manual.pdf")
            
            With trainingGuide
                .Controls.Add(CreatePDFImage())
                .Controls.Add(New LiteralControl("RECONCILOR BHPBIO Training Guide"))
            End With

            With userGuide
                .Controls.Add(CreatePDFImage())
                .Controls.Add(New LiteralControl("RECONCILOR BHPBIO User Guide"))
            End With

            With userManual
                .Controls.Add(CreatePDFImage())
                .Controls.Add(New LiteralControl("RECONCILOR BHPBIO User Manual"))
            End With

            With ReconcilorContent.ContainerContent

                .Controls.Add(trainingGuide)
                .Controls.Add(New Tags.HtmlBRTag())
                .Controls.Add(New Tags.HtmlBRTag())
                .Controls.Add(userGuide)
                .Controls.Add(New Tags.HtmlBRTag())
                .Controls.Add(New Tags.HtmlBRTag())
                .Controls.Add(userManual)
            End With
        End Sub

    End Class
End Namespace