Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports System.Text

Namespace Utilities
    Public Class CustomFieldsStockpileDetailsSave
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate


#Region "Properties"
        Private _locationId As Int32
        Private _dalUtility As IUtility
        Private _disposed As Boolean
        Private _stockpileFile As System.Web.HttpPostedFile
        Private _promote As Boolean
        Private _saveAction As Boolean

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
                        If Not _dalUtility Is Nothing Then
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

        Protected Overrides Sub OnInit(ByVal e As System.EventArgs)
            MyBase.OnInit(e)
            Me.EnableViewStateMac = False
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            _locationId = RequestAsInt32("LocationId")
            _stockpileFile = Page.Request.Files("ImgStockpileImageLocation")
            _promote = RequestAsBoolean("PromoteStockpile")

            If Request.Form("SaveOrDeleteAction").ToLower = "save" Then
                _saveAction = True
            ElseIf Request.Form("SaveOrDeleteAction").ToLower = "delete" Then
                _saveAction = False
            End If

        End Sub

        Protected Overrides Function ValidateData() As String
            Dim validateMessages As String = String.Empty

            'Check the image mime types.
            'If Not _stockpileFile.ContentType.ToLower.Contains("image/") Then
            '    validateMessages = "The file uploaded was not an image file"
            'End If
            Return validateMessages
        End Function

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Dim validMessage As String = ValidateData()
            'Dim buffer(CInt(_stockpileFile.InputStream.Length)) As Byte
            Dim deleteBuffer(0) As Byte

            Try
                If validMessage = String.Empty Then
                    If _saveAction Then
                        '_stockpileFile.InputStream.Read(Buffer, 0, CInt(_stockpileFile.InputStream.Length))
                        DalUtility.AddOrUpdateBhpbioStockpileLocationConfiguration(_locationId, deleteBuffer, _promote, _
                                                                           False, True)
                    Else
                        DalUtility.AddOrUpdateBhpbioStockpileLocationConfiguration(_locationId, deleteBuffer, _promote, True, False)
                    End If
                Else
                    JavaScriptAlert(validMessage)
                End If
            Catch ex As SqlClient.SqlException
                JavaScriptAlert(ex.Message)
            End Try
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub
    End Class
End Namespace

