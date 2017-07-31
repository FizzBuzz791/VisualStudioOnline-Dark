Namespace Internal
    Public Class StockpileImageLoader
        Inherits ImageHandler

        Private _dalUtility As Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
        Private _locationId As Integer

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()
            If Not Integer.TryParse(Request("LocationId"), _locationId) Then
                Throw New MissingFieldException("LocationId was not provided")
            End If
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()
            _dalUtility = New Reconcilor.Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
        End Sub

        Protected Overrides Function GetImageSourceStream() As System.IO.Stream
            Dim byteArray As Byte() = Nothing
            Dim stream As System.IO.MemoryStream
            Dim data As DataTable = Nothing

            Try
                stream = New System.IO.MemoryStream
                data = _dalUtility.GetBhpbioStockpileLocationConfiguration(_locationId)

                If data.Rows.Count > 0 Then
                    byteArray = CType(data.Rows(0)("ImageData"), Byte())
                End If
                If Not byteArray Is Nothing AndAlso byteArray.Length > 1 Then
                    stream.Write(byteArray, 0, byteArray.Length)
                End If

            Finally
                If Not data Is Nothing Then
                    data.Dispose()
                    data = Nothing
                End If
            End Try

            Return stream
        End Function

        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            MyBase.Dispose(disposing)
            If disposing Then
                If Not _dalUtility Is Nothing Then
                    _dalUtility.Dispose()
                    _dalUtility = Nothing
                End If
            End If

        End Sub

    End Class
End Namespace
