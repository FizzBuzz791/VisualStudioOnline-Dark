Imports System.Text
Imports Snowden.Common.Database.DataAccessBaseObjects
Namespace Analysis
    Public Class DigblockSpatialView
        Inherits Snowden.Reconcilor.Core.Website.Analysis.DigblockSpatialView

        Private _attributeFilter As String
        Private _disposed As Boolean
        Private _designationMaterialTypeId As Int32?

        Public Property AttributeFilter() As String
            Get
                Return _attributeFilter
            End Get
            Set(ByVal value As String)
                _attributeFilter = value
            End Set
        End Property

        Public Property DesignationMaterialTypeId() As Int32?
            Get
                Return _designationMaterialTypeId
            End Get
            Set(ByVal value As Int32?)
                _designationMaterialTypeId = value
            End Set
        End Property

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                    End If

                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region

        Protected Overrides Function ValidateData() As String
            Dim retStr As New StringBuilder(MyBase.ValidateData())

            If (StartDate > EndDate) Then
                retStr.Append(" - The start date is greater than the end date.\n")
            End If

            If (StartDate > Date.Now) Then
                retStr.Append(" - The start date is greater than the current date.\n")
            End If

            If (EndDate > Date.Now) Then
                retStr.Append(" - The end date is greater than the current date.\n")
            End If

            Return retStr.ToString
        End Function

        Protected Overrides Sub RetrieveRequestData()
            Dim requestText As String
            Dim locationIdFilter As Int32

            Try
                _attributeFilter = RequestAsString("AttributeFilter")

                _designationMaterialTypeId = RequestAsInt32("Designation")
                If _designationMaterialTypeId = -1 Then
                    _designationMaterialTypeId = Nothing
                End If
            Catch ex As Exception
                JavaScriptAlert(ex.Message, "Error retrieving spatial comparison request:\n")
            End Try

            MyBase.RetrieveRequestData()

            'Location
            requestText = Request("LocationId").Trim
            If (requestText <> "") AndAlso (requestText <> "-1") _
             AndAlso Int32.TryParse(requestText, locationIdFilter) Then
                LocationId = locationIdFilter
                Resources.UserSecurity.SetSetting("Spatial_Comparison_Filter_LocationId", requestText)
            Else
                LocationId = Nothing
                Resources.UserSecurity.SetSetting("Spatial_Comparison_Filter_LocationId", "")
            End If

            'other defaults
            requestText = Request("Designation").Trim
            If requestText <> "" Then
                Resources.UserSecurity.SetSetting("Spatial_Comparison_Filter_Designation", requestText)
            Else
                Resources.UserSecurity.SetSetting("Spatial_Comparison_Filter_Designation", "")
            End If

            requestText = Request("LeftComparison").Trim
            If requestText <> "" Then
                Resources.UserSecurity.SetSetting("Spatial_Comparison_Filter_LeftComparison", requestText)
            Else
                Resources.UserSecurity.SetSetting("Spatial_Comparison_Filter_LeftComparison", "")
            End If
            requestText = Request("RightComparison").Trim
            If requestText <> "" Then
                Resources.UserSecurity.SetSetting("Spatial_Comparison_Filter_RightComparison", requestText)
            Else
                Resources.UserSecurity.SetSetting("Spatial_Comparison_Filter_RightComparison", "")
            End If

            requestText = Request("LeftBlockModel").Trim
            If requestText <> "" Then
                Resources.UserSecurity.SetSetting("Spatial_Comparison_Filter_LeftBlockModel", requestText)
            Else
                Resources.UserSecurity.SetSetting("Spatial_Comparison_Filter_LeftBlockModel", "")
            End If
            requestText = Request("RightBlockModel").Trim
            If requestText <> "" Then
                Resources.UserSecurity.SetSetting("Spatial_Comparison_Filter_RightBlockModel", requestText)
            Else
                Resources.UserSecurity.SetSetting("Spatial_Comparison_Filter_RightBlockModel", "")
            End If

            requestText = Request("AttributeFilter").Trim
            If requestText <> "" Then
                Resources.UserSecurity.SetSetting("Spatial_Comparison_Filter_AttributeFilter", requestText)
            Else
                Resources.UserSecurity.SetSetting("Spatial_Comparison_Filter_AttributeFilter", "")
            End If
        End Sub

        Public Sub New()
            MyBase.New()
            If Not MapRender Is Nothing Then
                MapRender.Dispose()
            End If
            MapRender = New Bhpbio.Website.Analysis.DigblockSpatialRender()
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If DalDigblock Is Nothing Then
                DalDigblock = New Bhpbio.Database.SqlDal.SqlDalDigblock(Resources.Connection)
            End If

            If DalUtility Is Nothing Then
                DalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub RunAjax()
            Dim bhpbioMapRender As Bhpbio.Website.Analysis.DigblockSpatialRender
            bhpbioMapRender = DirectCast(MapRender, Bhpbio.Website.Analysis.DigblockSpatialRender)

            bhpbioMapRender.AttributeFilter = AttributeFilter
            bhpbioMapRender.DesignationMaterialTypeId = _designationMaterialTypeId

            MyBase.RunAjax()
        End Sub

    End Class
End Namespace
