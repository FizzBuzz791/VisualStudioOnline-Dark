Imports Snowden.Common.Web.BaseHtmlControls

Namespace Internal
    Public Class StockpileImageLoaderPage
        Inherits Core.WebDevelopment.WebpageTemplates.ReconcilorAjaxPage

        Private _locationId As Integer
        Private _height As Integer?
        Private _maxWidth As Integer?

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()
            Dim height As Integer
            Dim maxWidth As Integer
            _locationId = RequestAsInt32("LocationId")
            If Integer.TryParse(Request.Form("Height"), height) Then
                _height = height
            End If
            If Integer.TryParse(Request.Form("MaxWidth"), maxWidth) Then
                _maxWidth = maxWidth
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim maxWidth As String = String.Empty
            Dim height As String = String.Empty
            If _maxWidth.HasValue Then
                maxWidth = _maxWidth.Value.ToString
            End If
            If _height.HasValue Then
                height = _height.Value.ToString
            End If

            Response.Cache.SetCacheability(Web.HttpCacheability.NoCache)
            Controls.Add(New Tags.HtmlImageTag("../Internal/StockpileImageLoader.aspx?LocationId=" + _locationId.ToString + "&Height=" + _
                                               height + "&Guid=" + Now.Ticks.ToString + _
                                               "&MaxWidth=" + maxWidth))
        End Sub

    End Class
End Namespace
