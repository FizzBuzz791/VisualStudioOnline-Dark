
Imports NullValues = Snowden.Common.Database.DataAccessBaseObjects.NullValues

Namespace Internal
    Public MustInherit Class ImageHandler
        Inherits Core.WebDevelopment.WebpageTemplates.ReconcilorAjaxPage

        Private _width As Integer?
        Private _height As Integer?
        Private _maxHeight As Integer?
        Private _maxWidth As Integer?

        Protected Overrides Sub RetrieveRequestData()
            Dim width As Integer
            Dim height As Integer
            Dim maxHeight As Integer
            Dim maxWidth As Integer
            MyBase.RetrieveRequestData()
            If Not Integer.TryParse(Request("Width"), width) Then
                _width = Nothing
            Else
                _width = width
            End If
            If Not Integer.TryParse(Request("Height"), height) Then
                _height = Nothing
            Else
                _height = height
            End If
            If Not Integer.TryParse(Request("MaxWidth"), maxWidth) Then
                _maxWidth = Nothing
            Else
                _maxWidth = maxWidth
            End If
            If Not Integer.TryParse(Request("MaxHeight"), maxHeight) Then
                _maxHeight = Nothing
            Else
                _maxHeight = maxHeight
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim stream As System.IO.Stream
            Dim responseImage As System.Drawing.Image


            stream = GetImageSourceStream()
            stream.Position = 0
            Response.Clear()

            Response.Cache.SetCacheability(Web.HttpCacheability.NoCache)
            Response.ContentType = "image/gif"
            If stream.Length > 0 Then

                responseImage = System.Drawing.Image.FromStream(stream)

                'Do any required transformations.
                ScaleImage(responseImage)
                responseImage.Save(Response.OutputStream, System.Drawing.Imaging.ImageFormat.Gif)


            Else
                responseImage = System.Drawing.Image.FromFile(Server.MapPath("../images/") & "MissingImage.png")
                responseImage.Save(Response.OutputStream, System.Drawing.Imaging.ImageFormat.Gif)
            End If
            Response.End()

        End Sub

        Private Function ScaleImage(ByRef image As System.Drawing.Image) As System.Drawing.Image
            Dim width As Integer
            Dim height As Integer

            'If the maximum allowed width has a value

            If _maxHeight.HasValue Then

            End If

            Dim rescaleCallbackAbort As System.Drawing.Image.GetThumbnailImageAbort

            rescaleCallbackAbort = New System.Drawing.Image.GetThumbnailImageAbort(AddressOf ScaleImageAbort)

            If _width.HasValue Or _
                _height.HasValue Then
                If _width.HasValue AndAlso _
                _height.HasValue Then
                    width = _width.Value
                    height = _height.Value
                ElseIf _width Is Nothing Then
                    'Rescale using height
                    width = Convert.ToInt32((_height.Value / image.Size.Height) * image.Size.Width)
                    height = _height.Value
                ElseIf _height Is Nothing Then
                    'Rescale using width
                    height = Convert.ToInt32((_width.Value / image.Size.Width) * image.Size.Height)
                    width = _width.Value
                End If
            End If

            If _maxHeight.HasValue Or _maxWidth.HasValue Then

                width = image.Width
                height = image.Height

                'If a maximum width is set and the current width is greater
                If _maxWidth.HasValue AndAlso width > _maxWidth Then
                    height = Convert.ToInt32((_maxWidth.Value / width) * height)
                    width = _maxWidth.Value
                End If

                If _maxHeight.HasValue AndAlso height > _maxHeight Then
                    width = Convert.ToInt32((_maxHeight.Value / height) * width)
                    height = _maxHeight.Value
                End If

            End If

            'Do the final scaling now that all values have been calculated.
            image = image.GetThumbnailImage(width, height, rescaleCallbackAbort, IntPtr.Zero)

            Return image
        End Function

        Protected Overridable Function ScaleImageAbort() As Boolean
            Return False
        End Function

        Protected MustOverride Function GetImageSourceStream() As System.IO.Stream

    End Class
End Namespace
