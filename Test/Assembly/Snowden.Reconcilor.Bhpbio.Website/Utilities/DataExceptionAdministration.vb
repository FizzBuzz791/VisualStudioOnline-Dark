Imports Snowden.Common.Web.BaseHtmlControls

Namespace Utilities
    Public Class DataExceptionAdministration
        Inherits Core.Website.Utilities.DataExceptionAdministration

        Private _dalSecurityLocation As Database.DalBaseObjects.ISecurityLocation

        Private Property LocationId As Integer
        Private Property FromDate As Date
        Private Property ToDate As Date

        Public Property DalSecurityLocation() As Database.DalBaseObjects.ISecurityLocation
            Get
                Return _dalSecurityLocation
            End Get
            Set(ByVal value As Database.DalBaseObjects.ISecurityLocation)
                _dalSecurityLocation = value
            End Set
        End Property

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(
                                      Tags.ScriptType.TextJavaScript,
                                      Tags.ScriptLanguage.JavaScript,
                                      "../js/BhpbioUtilities.js", ""))

            Dim dataExceptionFilter = DirectCast(MyBase.DataExceptionFilter, WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.DataExceptionFilter)

            dataExceptionFilter.DalSecurityLocation = DalSecurityLocation
            dataExceptionFilter.LocationSelector.LocationId = LocationId
            dataExceptionFilter.DateFrom = FromDate
            dataExceptionFilter.DateTo = ToDate
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalSecurityLocation Is Nothing) Then
                DalSecurityLocation = New Database.SqlDal.SqlDalSecurityLocation(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If Not Request("LocationId") Is Nothing Then
                LocationId = RequestAsInt32("LocationId")
            End If

            If Not Request("SelectedMonth") Is Nothing Then
                FromDate = RequestAsDateTime("SelectedMonth")
                ToDate = FromDate.EndOfMonth()
            End If
        End Sub
    End Class
End Namespace