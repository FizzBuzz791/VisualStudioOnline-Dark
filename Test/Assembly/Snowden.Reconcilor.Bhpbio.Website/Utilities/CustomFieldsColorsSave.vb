Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Web.BaseHtmlControls

Namespace Utilities
    Public Class CustomFieldsColorsSave
        Inherits Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

#Region "Properties"
        Private Const _colorPrefix As String = "colorSelect"
        Private Const _lineStylePrefix As String = "lineStyleSelect"
        Private Const _markerShapePrefix As String = "markerShapeSelect"
        Private _colorUpdate As New Generic.Dictionary(Of String, String)
        Private _lineStyleUpdate As New Generic.Dictionary(Of String, String)
        Private _markerShapeUpdate As New Generic.Dictionary(Of String, String)
        Private _dalUtility As Database.DalBaseObjects.IUtility
        Private _disposed As Boolean

        Protected ReadOnly Property ColourUpdate() As Generic.Dictionary(Of String, String)
            Get
                Return _colorUpdate
            End Get
        End Property

        Protected ReadOnly Property LineStyleUpdate() As Generic.Dictionary(Of String, String)
            Get
                Return _lineStyleUpdate
            End Get
        End Property

        Protected ReadOnly Property MarkerShapeUpdate() As Generic.Dictionary(Of String, String)
            Get
                Return _markerShapeUpdate
            End Get
        End Property

        Public Property DalUtility() As Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Database.DalBaseObjects.IUtility)
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

                    _colorUpdate = Nothing
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region


        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Dim ValidMessage As String = ValidateData()
            Dim colorTerm As String = ReconcilorFunctions.GetSiteTerminology("Color")

            Try
                If (ValidMessage = "") Then
                    ProcessData()
                    'Response.Write("GetCustomFieldsColorsDetails(); alert('" & colorTerm & " settings have been updated.');")
                    Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetCustomFieldsColorsDetails(); alert('" & colorTerm & " settings have been updated.');"))
                Else
                    JavaScriptAlert(ValidMessage, "Error saving settings:")
                End If
            Catch ex As SqlClient.SqlException
                JavaScriptAlert(ex.Message)
            End Try
        End Sub


        Protected Overrides Function ValidateData() As String
            Dim ReturnValue As String = MyBase.ValidateData()
            Dim key As String
            Dim tagId As String
            Dim value As String

            For Each key In Request.Form.Keys
                If (key.StartsWith(_colorPrefix)) Then
                    tagId = key.ToString.Replace(_colorPrefix, "")
                    value = RequestAsString(key)
                    ColourUpdate.Add(tagId, value)
                ElseIf (key.StartsWith(_lineStylePrefix)) Then
                    tagId = key.ToString.Replace(_lineStylePrefix, "")
                    value = RequestAsString(key)
                    LineStyleUpdate.Add(tagId, CovertLineStyleTo2008(value))
                ElseIf (key.StartsWith(_markerShapePrefix)) Then
                    tagId = key.ToString.Replace(_markerShapePrefix, "")
                    value = RequestAsString(key)
                    MarkerShapeUpdate.Add(tagId, value)
                End If
            Next

            Return ReturnValue
        End Function

        Protected Overrides Sub ProcessData()
            Dim tagId As String


            For Each tagId In ColourUpdate.Keys
                DalUtility.AddOrUpdateBhpbioReportColor(tagId, DoNotSetValues.String, _
                  DoNotSetValues.Boolean, ColourUpdate(tagId), LineStyleUpdate(tagId), MarkerShapeUpdate(tagId))
            Next

        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        ' SSRS 2008 uses new names for the line styles, so we need to convert to and from when 
        ' setting the drop down boxes on the utilities page
        Protected Function CovertLineStyleTo2008(ByVal lineStyle As String) As String
            Select Case lineStyle
                Case "Dash" : Return "Dashed"
                Case "Dot" : Return "Dotted"
                Case Else : Return lineStyle
            End Select
        End Function
    End Class
End Namespace

