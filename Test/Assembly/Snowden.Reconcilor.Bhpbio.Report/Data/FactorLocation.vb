Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Data
    Public NotInheritable Class FactorLocation
        Private Sub New()
        End Sub

        Shared Function IsLocationInLocationType(ByVal session As Types.ReportSession, _
         ByVal locationId As Int32?, ByVal locationTypeDescription As String) As Boolean
            Dim found As Boolean = False
            Dim locationTypeList As Generic.IList(Of String)
            Dim type As String

            If locationId.HasValue AndAlso locationId.Value > 0 Then
                locationTypeList = GetLocationTypeIdParentList(locationTypeDescription, session.DalUtility)
                type = Location.GetLocationType(session, locationId.Value)
                found = locationTypeList.Contains(type)
            Else
                found = True
            End If

            Return found
        End Function

        Shared Function GetLocationTypeName(ByVal dalUtility As Core.Database.DalBaseObjects.IUtility, _
         ByVal locationId As Int32?) As String
            Dim locationTypeColumn As String = "Location_Type_Id"
            Dim locationTypeNameColumn As String = "Description"
            Dim locationTypeId As Int16
            Dim locationType As DataTable
            Dim location As DataTable
            Dim locationTypeName As String = "Unknown"

            If locationId.HasValue Then

                location = dalUtility.GetLocation(locationId.Value)

                If location.Rows.Count = 1 AndAlso Not IsDBNull(location.Rows(0).Item(locationTypeColumn)) Then
                    locationTypeId = Convert.ToInt16(location.Rows(0).Item(locationTypeColumn))

                    locationType = dalUtility.GetLocationType(locationTypeId)
                    If locationType.Rows.Count = 1 AndAlso Not IsDBNull(locationType.Rows(0).Item(locationTypeNameColumn)) Then
                        locationTypeName = locationType.Rows(0).Item(locationTypeNameColumn).ToString()
                    End If
                End If
            End If

            Return locationTypeName
        End Function

        Shared Function GetLocationTypeIdParentList(ByVal locationTypeDescription As String, _
         ByVal dalUtility As Core.Database.DalBaseObjects.IUtility) As Generic.IList(Of String)
            Dim list As New Generic.List(Of String)
            Dim row As DataRow
            Dim table As DataTable

            table = dalUtility.GetLocationTypeParentList(NullValues.Int16, locationTypeDescription)

            For Each row In table.Rows
                list.Add(row("Location_Type_Id").ToString)
            Next

            Return list
        End Function

        Shared Function GetLocationTypeDescriptionParentList(ByVal locationTypeDescription As String, _
         ByVal dalUtility As Core.Database.DalBaseObjects.IUtility) As Generic.IList(Of String)
            Dim list As New Generic.List(Of String)
            Dim row As DataRow
            Dim table As DataTable

            table = dalUtility.GetLocationTypeParentList(NullValues.Int16, locationTypeDescription)

            For Each row In table.Rows
                list.Add(row("Description").ToString().ToLower())
            Next

            Return list
        End Function
    End Class
End Namespace
