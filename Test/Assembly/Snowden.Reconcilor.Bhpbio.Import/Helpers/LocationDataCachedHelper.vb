Imports Snowden.Common.Database.DataAccessBaseObjects
Imports DataHelper = Snowden.Common.Database.DataHelper

Public NotInheritable Class LocationDataCachedHelper
    Private Shared _utilityDal As Bhpbio.Database.DalBaseObjects.IUtility

    'location data
    Private Shared _locationLookup As DataTable

    Public Shared Property UtilityDal() As Bhpbio.Database.DalBaseObjects.IUtility
        Get
            Return _utilityDal
        End Get
        Set(ByVal value As Bhpbio.Database.DalBaseObjects.IUtility)
            _utilityDal = value
        End Set
    End Property

    Private Sub New()
        'prevent instantiation
        'i.e.  YOU CAN'T TOUCH THIS. Hammer time.
    End Sub

    Public Shared Sub SetStaleDataForLocation()
        _locationLookup = Nothing
    End Sub

    Private Shared Sub PrepareLocationLookup()
        If _utilityDal Is Nothing Then
            Throw New InvalidOperationException("The Utility Dal is not active.")
        End If

        If _locationLookup Is Nothing Then
            _locationLookup = _utilityDal.GetLocationList(DoNotSetValues.Byte, DoNotSetValues.Int32, _
             DoNotSetValues.Int32, DoNotSetValues.Byte, Int32.MaxValue)
        End If
    End Sub

    Public Shared Function GetLocationId(ByVal locationName As String, _
     ByVal locationType As String, ByVal parentLocationId As Nullable(Of Int32)) As Nullable(Of Int32)

        Dim locationTypeId As Byte?
        Dim lookupRows As DataRow()
        Dim result As Nullable(Of Int32)

        PrepareLocationLookup()

        'look up the location type id based on the location type name provided
        locationTypeId = ReferenceDataCachedHelper.GetLocationTypeId(locationType, Nothing)

        If locationTypeId Is Nothing Then
            result = Nothing
        Else
            'look up the location based on the location type, name and parent provided
            If parentLocationId.HasValue Then
                lookupRows = _locationLookup.Select("Name = '" & locationName & "' " & _
                                                    "And Location_Type_Id = " & locationTypeId.Value.ToString() & " " & _
                                                    "And Parent_Location_Id = " & parentLocationId)
            Else
                lookupRows = _locationLookup.Select("Name = '" & locationName & "' " & _
                                                    "And Location_Type_Id = " & locationTypeId.Value.ToString())
            End If

            If lookupRows.Length = 0 Then
                result = Nothing
            Else
                result = DirectCast(lookupRows(0)("Location_Id"), Int32)
            End If
        End If

        Return result
    End Function

    Public Shared Function GetParentLocationId(ByVal locationId As Int32) As Int32?
        Dim lookupRows As DataRow()
        Dim result As Nullable(Of Int32)

        PrepareLocationLookup()

        lookupRows = _locationLookup.Select("Location_Id = " & locationId.ToString)
        If lookupRows.Length = 0 Then
            result = Nothing
        Else
            If lookupRows(0)("Parent_Location_Id") Is DBNull.Value Then
                result = Nothing
            Else
                result = DirectCast(lookupRows(0)("Parent_Location_Id"), Int32)
            End If
        End If

        Return result
    End Function

    Public Shared Function GetMQ2SiteOrHubLocationId(ByVal code As String) As Int32?
        Dim locationId As Int32?

        'note: order is important!  site first, then hub.  if you need to change this then
        'consider all places this routine is called.

        locationId = LocationDataCachedHelper.GetLocationId( _
         CodeTranslationHelper.Mq2SiteToReconcilor(code), "Site", Nothing)
        If Not locationId.HasValue Then
            locationId = LocationDataCachedHelper.GetLocationId( _
             CodeTranslationHelper.Mq2HubToReconcilor(code), "Hub", Nothing)
        End If

        Return locationId
    End Function
End Class
