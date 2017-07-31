Imports Snowden.Common.Web.BaseHtmlControls

Namespace Utilities
    Public Class EventViewer
        Inherits Core.Website.Utilities.EventViewer

        Private _dalUtility As Snowden.Reconcilor.Core.Database.DalBaseObjects.IUtility

        Public Property DalUtility() As Core.Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Core.Database.DalBaseObjects.IUtility)
                If (Not value Is Nothing) Then
                    _dalUtility = value
                End If
            End Set
        End Property

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalUtility Is Nothing Then
                DalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If
        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            With PageHeader.ScriptTags
                .Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioUtilities.js", ""))
            End With
        End Sub
    End Class
End Namespace

