Imports Snowden.Common.Database.DataAccessBaseObjects
Imports DataHelper = Snowden.Common.Database.DataHelper

Public NotInheritable Class LocationDataUncachedHelper
    Private Shared _utilityDal As Bhpbio.Database.DalBaseObjects.IUtility

    'location data
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

    Public Shared Function GetLocationId(ByVal locationName As String, _
     ByVal locationType As String, ByVal parentLocationId As Nullable(Of Int32)) As Nullable(Of Int32)

        Dim locationTypeId As Byte?
        Dim parentLocationIdDal As Int32
        Dim result As Nullable(Of Int32)

        If _utilityDal Is Nothing Then
            Throw New InvalidOperationException("The Utility Dal is not active.")
        End If

        'look up the location type id based on the location type name provided
        locationTypeId = ReferenceDataCachedHelper.GetLocationTypeId(locationType, Nothing)

        If locationTypeId Is Nothing Then
            result = Nothing
        Else
            If parentLocationId.HasValue Then
                parentLocationIdDal = parentLocationId.Value
            Else
                parentLocationIdDal = NullValues.Int32
            End If
            result = _utilityDal.GetLocationIdByName(locationName, locationTypeId.Value, parentLocationIdDal)

            If result = NullValues.Int32 Then
                result = Nothing
            End If
        End If

        Return result
    End Function

    Public Shared Function GetParentLocationId(ByVal locationId As Int32) As Int32?
        Dim result As Nullable(Of Int32)

        If _utilityDal Is Nothing Then
            Throw New InvalidOperationException("The Utility Dal is not active.")
        End If

        result = _utilityDal.GetLocationParentLocationId(locationId)

        If result = NullValues.Int32 Then
            result = Nothing
        End If

        Return result
    End Function

    Public Shared Function GetLocationLookup(ByVal rootLocationId As Int32, _
     ByVal highestLocationType As String, ByVal lowestLocationType As String) As Int32()
        Dim result As New Generic.List(Of Int32)
        Dim resultRows As DataRow()
        Dim resultRow As DataRow
        Dim highestLocationTypeId As Int16
        Dim lowestLocationTypeId As Int16

        If _utilityDal Is Nothing Then
            Throw New InvalidOperationException("The Utility Dal is not active.")
        End If

        If highestLocationType Is Nothing Then
            highestLocationTypeId = NullValues.Byte
        Else
            highestLocationTypeId = ReferenceDataCachedHelper.GetLocationTypeId(highestLocationType, Nothing).Value
        End If

        If lowestLocationType Is Nothing Then
            lowestLocationTypeId = NullValues.Byte
        Else
            lowestLocationTypeId = ReferenceDataCachedHelper.GetLocationTypeId(lowestLocationType, Nothing).Value
        End If

        resultRows = _utilityDal.GetLocationLookup(rootLocationId, highestLocationTypeId, lowestLocationTypeId).Select()
        For Each resultRow In resultRows
            result.Add(DirectCast(resultRow("Location_Id"), Int32))
        Next

        Return result.ToArray()
    End Function
End Class
