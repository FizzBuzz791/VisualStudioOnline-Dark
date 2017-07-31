Namespace Utilities
    Public Class HaulageCorrectionList
        Inherits Core.Website.Utilities.HaulageCorrectionList

#Region " Properties "
        Private _locationId As Int32
        Private _dalSecurityLocation As Bhpbio.Database.DalBaseObjects.ISecurityLocation

        Public Property LocationId() As Int32
            Get
                Return _locationId
            End Get
            Set(ByVal value As Int32)
                _locationId = value
            End Set
        End Property

        Public Property DalSecurityLocation() As Bhpbio.Database.DalBaseObjects.ISecurityLocation
            Get
                Return _dalSecurityLocation
            End Get
            Set(ByVal value As Bhpbio.Database.DalBaseObjects.ISecurityLocation)
                _dalSecurityLocation = value
            End Set
        End Property
#End Region
        Protected Overrides Sub CreateListTable()
            Dim dal As Bhpbio.Database.DalBaseObjects.IHaulage _
                = DirectCast(DalHaulage, Bhpbio.Database.DalBaseObjects.IHaulage)

            LocationId = Convert.ToInt32(Resources.UserSecurity.GetSetting("Haulage_Correction_Filter_Location", "-1"))
            'If Not LocationId >= 0 Then
            '    LocationId = DalSecurityLocation.GetBhpbioUserLocation(Resources.UserSecurity.UserId.Value)
            'End If

            ListTable = dal.GetBhpbioHaulageCorrectionList(FilterSource, FilterDestination, FilterDescription, Top, RecordLimit, LocationId)
        End Sub

        Protected Overrides Sub CreateReturnTable()
            useColumns() = New String() {"Haulage_Date", "Haulage_Shift_Str", "Source", "Destination", "Description"}

            MyBase.CreateReturnTable()
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If Not Request("LocationId") Is Nothing Then
                LocationId = RequestAsInt32("LocationId")
                Resources.UserSecurity.SetSetting("Haulage_Correction_Filter_Location", LocationId.ToString())
            End If
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalHaulage Is Nothing) Then
                DalHaulage = New Bhpbio.Database.SqlDal.SqlDalHaulage(Resources.Connection)
            End If

            If (DalSecurityLocation Is Nothing) Then
                DalSecurityLocation = New Bhpbio.Database.SqlDal.SqlDalSecurityLocation(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub
    End Class
End Namespace

