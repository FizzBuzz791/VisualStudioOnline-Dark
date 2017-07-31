Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports System.Data.SqlClient
Imports IUtility = Snowden.Reconcilor.Core.Database.DalBaseObjects.IUtility
Imports SqlDalUtility = Snowden.Reconcilor.Core.Database.SqlDal.SqlDalUtility
Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Utilities
    Public Class DataExceptionListDismissAll
        Inherits ReconcilorAjaxPage

        Private _DalUtility As Database.DalBaseObjects.IUtility

        Protected Property DalUtility() As Database.DalBaseObjects.IUtility
            Get
                Return _DalUtility
            End Get
            Set(ByVal value As Database.DalBaseObjects.IUtility)
                If (Not value Is Nothing) Then
                    _DalUtility = value
                End If
            End Set
        End Property

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub



        Protected Overridable Sub SetupPageControls()

        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                ProcessData()
                Dim message = "Exceptions Dismissed"
                Dim js = String.Format("GetDataExceptionList();alert('{0}');", message)
                Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript, js))
            Catch ex As Exception
                JavaScriptAlert(ex.Message, "Error: Could not dismiss exceptions")
            End Try
        End Sub

        Protected Overrides Sub ProcessData()
            Dim IncludeActive = ((Not Request("IncludeActive") Is Nothing) AndAlso (Request("IncludeActive").ToLower = "on"))
            Dim IncludeDismissed = ((Not Request("IncludeDismissed") Is Nothing) AndAlso (Request("IncludeDismissed").ToLower = "on"))
            Dim IncludeResolved = ((Not Request("IncludeResolved") Is Nothing) AndAlso (Request("IncludeResolved").ToLower = "on"))
            Dim DateFrom = RequestAsDateTime("DateFromText")
            Dim DateTo = RequestAsDateTime("DateToText")
            Dim DataExceptionTypeId = RequestAsInt32("DataExceptionTypeId")
            Dim DescriptionContains = RequestAsString("DescriptionContains")
            Dim LocationId = RequestAsInt32("LocationId")
            Dim MaxRows = 100000 ' don't use the max rows from the request - just dismiss everything up to some high limit

            DalUtility.UpdateBhpbioDataExceptionDismissAll( _
                IncludeActive, _
                IncludeDismissed, _
                IncludeResolved, _
                DateFrom, DateTo, _
                DataExceptionTypeId, _
                DescriptionContains, _
                MaxRows, _
                LocationId _
            )

        End Sub
    End Class
End Namespace
