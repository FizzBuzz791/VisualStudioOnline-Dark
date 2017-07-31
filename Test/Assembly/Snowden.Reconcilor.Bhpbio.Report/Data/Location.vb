Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Data
    ''' <summary>
    ''' Provides shared interface for the reports to query Locational questions.
    ''' </summary>
    ''' <remarks></remarks>
    Public NotInheritable Class Location

        ' Static Class
        Private Sub New()
        End Sub

        ''' <summary>
        ''' Function to aquire if a given location id is within two location types.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function IsLocationBetween(ByVal session As ReportSession, ByVal locationId As Int32, _
         ByVal highestLocationType As String, ByVal lowLocationType As String) As Boolean
            Dim locationList As IList = GetLocationParentDescriptionList(highestLocationType, lowLocationType, session)
            Dim locationIsIn As Boolean = locationList.Contains(GetLocationType(session, locationId))

            Return locationIsIn
        End Function


        ''' <summary>
        ''' Returns the Location Type assoicated with the Location Id
        ''' </summary>
        ''' <returns>Location Type</returns>
        ''' <remarks></remarks>
        Shared Function GetLocationType(ByVal session As Types.ReportSession, _
         ByVal locationId As Int32) As String
            Dim locationTypeColumn As String = "Location_Type_Id"
            Dim locationType As String = "Unknown"
            Dim location As DataTable

            location = session.DalUtility.GetLocation(locationId)

            If location.Rows.Count = 1 AndAlso Not IsDBNull(location.Rows(0).Item(locationTypeColumn)) Then
                locationType = location.Rows(0).Item(locationTypeColumn).ToString()
            End If

            Return locationType
        End Function

        ''' <summary>
        ''' Returns the location list of the location types description between two location types.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Shared Function GetLocationParentDescriptionList(ByVal highLocationTypeDescription As String, _
         ByVal lowLocationTypeDescription As String, ByVal session As ReportSession) As IList
            Dim list As New ArrayList
            Dim row As DataRow
            Dim table As DataTable
            Dim startPointFound As Boolean = False

            table = session.DalUtility.GetLocationTypeParentList(NullValues.Int16, lowLocationTypeDescription)

            For Each row In table.Rows
                If Not startPointFound And _
                 row("Description").ToString.ToUpper() = highLocationTypeDescription.ToUpper() Then
                    startPointFound = True
                End If

                If startPointFound Then
                    list.Add(row("Description").ToString)
                End If
            Next

            Return list
        End Function

        ''' <summary>
        ''' Returns the location list of the location type and all it's parent descriptions.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Shared Function GetLocationParentDescriptionList(ByVal locationTypeDescription As String, _
         ByVal session As ReportSession) As IList
            Dim list As New ArrayList
            Dim row As DataRow
            Dim table As DataTable

            table = session.DalUtility.GetLocationTypeParentList(NullValues.Int16, locationTypeDescription)

            For Each row In table.Rows
                list.Add(row("Location_Type_Id").ToString)
            Next

            Return list
        End Function
    End Class
End Namespace
