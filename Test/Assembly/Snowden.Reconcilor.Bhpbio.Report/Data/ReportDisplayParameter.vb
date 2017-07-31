Imports NullValues = Snowden.Common.Database.DataAccessBaseObjects.NullValues
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports System.Text

Namespace Data
    Public NotInheritable Class ReportDisplayParameter
        Private Sub New()
        End Sub

        Public Shared Function ConvertGradesXmlToCsv(ByVal session As ReportSession, ByVal xml As String) As String
            Dim doc As Xml.XmlDocument
            Dim node As Xml.XmlNode
            Dim gradeId As Int16
            Dim gradeName As String
            Dim gradeList As Generic.List(Of String)
            Dim result As String
            Dim grades As DataTable
            Dim gradeLookup() As DataRow
            Dim csv As Text.StringBuilder

            result = Nothing

            Try
                If xml.Length > 0 Then
                    grades = session.DalUtility.GetGradeList(NullValues.Int16)

                    'extract the list of grades
                    gradeList = New Generic.List(Of String)
                    doc = New Xml.XmlDocument()
                    doc.LoadXml(xml)
                    For Each node In doc.GetElementsByTagName("Grade")
                        gradeId = Convert.ToInt16(node.Attributes("id").Value)

                        gradeLookup = grades.Select("Grade_Id = " & gradeId.ToString)
                        If gradeLookup.Length = 1 Then
                            gradeName = DirectCast(gradeLookup(0)("Grade_Name"), String)
                        Else
                            gradeName = "Unknown"
                        End If

                        gradeList.Add(gradeName)
                    Next

                    doc = Nothing
                    grades = Nothing

                    'produce the CSV output
                    csv = New Text.StringBuilder()
                    For Each gradeName In gradeList
                        If gradeList.IndexOf(gradeName) = 0 Then
                            csv.Append(gradeName)
                        Else
                            csv.Append(", " & gradeName)
                        End If
                    Next
                    result = csv.ToString
                    csv = Nothing
                End If
            Catch ex As Xml.XmlException
                result = "Unable to determine grades."
            End Try

            Return result
        End Function

        Public Shared Function ConvertBlocksModelsAndActualsXmlToCsv(ByVal session As ReportSession,
         ByVal xml As String, ByVal includeActuals As Boolean) As String

            Dim result As String = Nothing

            Try
                If xml.Length > 0 Then
                    Dim blockModelNameList = New Generic.List(Of String)
                    Dim blockModels = session.DalBlockModel.GetBlockModelList(NullValues.Int32, NullValues.String, NullValues.Int16)

                    If includeActuals Then
                        blockModelNameList.Add("Mine Production (Actuals)")
                    End If

                    Dim doc = New Xml.XmlDocument()
                    doc.LoadXml(xml)

                    For Each node As Xml.XmlNode In doc.GetElementsByTagName("BlockModel")
                        Dim blockModelId = Convert.ToInt16(node.Attributes("id").Value)
                        Dim blockModelLookup = blockModels.AsEnumerable.FirstOrDefault(Function(r) r.AsInt("Block_Model_Id") = blockModelId)
                        Dim blockModelName = "Unknown"

                        If blockModelLookup IsNot Nothing Then
                            blockModelName = blockModelLookup.AsString("Description")
                        End If

                        blockModelNameList.Add(blockModelName)
                    Next

                    result = String.Join(",", blockModelNameList.ToArray)
                End If
            Catch ex As Xml.XmlException
                result = "Unable to determine block models."
            End Try

            Return result
        End Function

        Public Shared Function GetXmlAsList(ByVal xml As String, ByVal elementId As String, ByVal attributeName As String) As IList
            Dim doc As New Xml.XmlDocument()
            Dim list As New ArrayList

            doc.LoadXml(xml)
            For Each node As Xml.XmlNode In doc.GetElementsByTagName(elementId)
                list.Add(node.Attributes(attributeName).Value)
            Next

            Return list
        End Function

        Public Shared Function GetLocationComment(ByVal session As ReportSession,
         ByVal locationId As Int32) As String

            Dim locationHierarchy As DataTable
            Dim row As DataRow
            Dim comment As Text.StringBuilder
            Dim rows() As DataRow
            Dim lastLocationType As String
            Dim currentLocationType As String
            Dim currentLocationName As String

            Dim separator As String
            Dim locationName As String

            'build a location string from the location code provided
            locationHierarchy = session.DalUtility.GetLocationParentHeirarchy(locationId)

            comment = New Text.StringBuilder()

            rows = locationHierarchy.Select("", "Order_No Desc")
            If rows.Length > 0 Then
                'find the lowest and levels
                lastLocationType = DirectCast(rows(rows.Length - 1)("Location_Type_Description"), String)

                'build the comments
                For Each row In rows
                    currentLocationType = DirectCast(row("Location_Type_Description"), String)
                    currentLocationName = DirectCast(row("Name"), String)

                    If lastLocationType = "Block" Or lastLocationType = "Blast" Then
                        ' build the short list
                        Select Case currentLocationType
                            Case "Company"
                                locationName = currentLocationName
                                separator = "\"
                            Case "Hub"
                                locationName = ""
                                separator = ""
                            Case "Site"
                                locationName = currentLocationName
                                separator = ": "
                            Case "Pit", "Bench", "Blast", "Block", "Block"
                                locationName = currentLocationName
                                separator = "-"
                            Case Else
                                'you(shouldn) 't see this, but just in case...
                                locationName = "Unknown location type"
                                separator = "-"
                        End Select
                    Else
                        '  build the long list
                        Select Case currentLocationType
                            Case "Company"
                                locationName = currentLocationName
                                separator = ""
                            Case "Hub"
                                ' If only the "company" portion exists, return only that value.
                                ' If there's more, remove the company portion.
                                comment.Remove(0, comment.Length)
                                locationName = currentLocationName
                                separator = "\"
                            Case "Site"
                                locationName = currentLocationName
                                separator = "\"
                            Case "Pit", "Bench"
                                locationName = currentLocationName
                                separator = "\"
                            Case "Blast", "Block"
                                locationName = ""
                                separator = "\"
                            Case Else
                                ' you(shouldn) 't see this, but just in case...
                                locationName = "Unknown location type"
                                separator = "\"
                        End Select
                    End If

                    comment.Append(locationName)
                    If currentLocationType <> lastLocationType Then
                        comment.Append(separator)
                    End If
                Next
            Else
                'we shouldn't see this - but just in case...
                comment.Append("Unknown location")
            End If

            Return comment.ToString
        End Function

        Public Shared Function GetLocationCommentByDate(ByVal session As ReportSession,
 ByVal locationId As Int32, ByVal startDate As DateTime) As String

            Dim locationHierarchy As DataTable
            Dim row As DataRow
            Dim comment As Text.StringBuilder
            Dim rows() As DataRow
            Dim lastLocationType As String
            Dim currentLocationType As String
            Dim currentLocationName As String

            Dim separator As String
            Dim locationName As String

            'build a location string from the location code provided
            locationHierarchy = session.DalUtility.GetBhpbioLocationParentHeirarchyWithOverride(locationId, startDate)

            comment = New Text.StringBuilder()

            rows = locationHierarchy.Select("", "Order_No Desc")
            If rows.Length > 0 Then
                'find the lowest and levels
                lastLocationType = DirectCast(rows(rows.Length - 1)("Location_Type_Description"), String)

                'build the comments
                For Each row In rows
                    currentLocationType = DirectCast(row("Location_Type_Description"), String)
                    currentLocationName = DirectCast(row("Name"), String)

                    If lastLocationType = "Block" Or lastLocationType = "Blast" Then
                        ' build the short list
                        Select Case currentLocationType
                            Case "Company"
                                locationName = currentLocationName
                                separator = "\"
                            Case "Hub"
                                locationName = ""
                                separator = ""
                            Case "Site"
                                locationName = currentLocationName
                                separator = ": "
                            Case "Pit", "Bench", "Blast", "Block", "Block"
                                locationName = currentLocationName
                                separator = "-"
                            Case Else
                                'you(shouldn) 't see this, but just in case...
                                locationName = "Unknown location type"
                                separator = "-"
                        End Select
                    Else
                        '  build the long list
                        Select Case currentLocationType
                            Case "Company"
                                locationName = currentLocationName
                                separator = ""
                            Case "Hub"
                                ' If only the "company" portion exists, return only that value.
                                ' If there's more, remove the company portion.
                                comment.Remove(0, comment.Length)
                                locationName = currentLocationName
                                separator = "\"
                            Case "Site"
                                locationName = currentLocationName
                                separator = "\"
                            Case "Pit", "Bench"
                                locationName = currentLocationName
                                separator = "\"
                            Case "Blast", "Block"
                                locationName = ""
                                separator = "\"
                            Case Else
                                ' you(shouldn) 't see this, but just in case...
                                locationName = "Unknown location type"
                                separator = "\"
                        End Select
                    End If

                    comment.Append(locationName)
                    If currentLocationType <> lastLocationType Then
                        comment.Append(separator)
                    End If
                Next
            Else
                'we shouldn't see this - but just in case...
                comment.Append("Unknown location")
            End If

            Return comment.ToString
        End Function


        'Return Type and Name
        Public Shared Function GetLocationComment2(ByVal session As ReportSession,
         ByVal locationId As Int32) As String

            Dim locationHierarchy As DataTable
            Dim row As DataRow
            Dim comment As Text.StringBuilder
            Dim rows() As DataRow
            Dim currentLocationType As String
            Dim lastLocationType As String

            'build a location string from the location code provided
            locationHierarchy = session.DalUtility.GetLocationParentHeirarchy(locationId)

            comment = New Text.StringBuilder()

            rows = locationHierarchy.Select("", "Order_No Desc")
            If rows.Length > 0 Then
                lastLocationType = rows(rows.Length - 1)("Location_Type_Description").ToString

                'build the comments
                For Each row In rows
                    currentLocationType = row("Location_Type_Description").ToString

                    If lastLocationType = "Company" Or currentLocationType <> "Company" Then
                        comment.Append(currentLocationType)
                        comment.Append(": ")
                        comment.Append(row("Name").ToString)
                        comment.Append("  ")
                    End If
                Next
            Else
                'we shouldn't see this - but just in case...
                comment.Append("Unknown location")
            End If

            Return comment.ToString
        End Function

        'Return Type and Name
        Public Shared Function GetLocationComment2ByDate(ByVal session As ReportSession,
         ByVal locationId As Int32, ByVal startDate As DateTime) As String

            Dim locationHierarchy As DataTable
            Dim row As DataRow
            Dim comment As Text.StringBuilder
            Dim rows() As DataRow
            Dim currentLocationType As String
            Dim lastLocationType As String

            'build a location string from the location code provided
            locationHierarchy = session.DalUtility.GetBhpbioLocationParentHeirarchyWithOverride(locationId, startDate)

            comment = New Text.StringBuilder()

            rows = locationHierarchy.Select("", "Order_No Desc")
            If rows.Length > 0 Then
                lastLocationType = rows(rows.Length - 1)("Location_Type_Description").ToString

                'build the comments
                For Each row In rows
                    currentLocationType = row("Location_Type_Description").ToString

                    If lastLocationType = "Company" Or currentLocationType <> "Company" Then
                        comment.Append(currentLocationType)
                        comment.Append(": ")
                        comment.Append(row("Name").ToString)
                        comment.Append("  ")
                    End If
                Next
            Else
                'we shouldn't see this - but just in case...
                comment.Append("Unknown location")
            End If

            Return comment.ToString
        End Function

        Public Shared Function GetLocationDepositComment(ByVal session As ReportSession,
         ByVal locationId? As Int32, ByVal depositId As Int32?, Optional locationDate As DateTime? = Nothing) As String

            Dim retVal As String = String.Empty

            If Not (locationId.HasValue Or depositId.HasValue) Then
                Throw New ArgumentNullException("You must specify a value for either locationId or depositId")
            ElseIf depositId.HasValue AndAlso depositId > 0 Then
                '' Todo Need to call Tobia's deposit code
                retVal = GetDepositComment(session, depositId.Value)
            Else
                If locationDate Is Nothing Then
                    locationDate = DateTime.Now
                End If

                retVal = GetLocationComment2ByDate(session, locationId.Value, locationDate.Value)
            End If

            Return retVal
        End Function

        Public Shared Function GetDepositComment(ByVal session As ReportSession, ByVal depositId As Int32) As String

            Dim deposit As DataTable = session.DalBhpbioLocationGroup.GetBhpbioLocationGroup(depositId)

            If deposit Is Nothing OrElse deposit.Rows.Count = 0 Then
                Return "Unknown Deposit"
            End If

            If (deposit.Rows.Count > 1) Then
                Throw New Exception("Deposit id returned more than 1 row of data")
            End If

            Return String.Format("Deposit: {0}", deposit.AsEnumerable.First.AsString("Name"))
        End Function

        Public Shared Function GetMaterialName(ByVal session As ReportSession, _
         ByVal materialTypeId As Int32) As String

            Dim materials As DataTable
            Dim material As DataRow
            Dim result As String

            materials = session.DalUtility.GetMaterialType(materialTypeId)
            If materials.Rows.Count = 1 Then
                material = materials.Rows(0)
                result = DirectCast(material("Description"), String)
            Else
                'you wouldn't expect to see this, but just in case...
                result = "Unknown material."
            End If

            Return result
        End Function

        Public Shared Function GetBlockModelActualName(ByVal session As ReportSession, _
         ByVal isActual As Boolean, ByVal blockModelId As Int32) As String

            Dim result As String

            If isActual Then
                result = "Mine Production (Actuals)"
            Else
                Dim blockModels = session.DalBlockModel.GetBlockModelList(NullValues.Int32, NullValues.String, NullValues.Int16)
                Dim blockModelRow = blockModels.Select("Block_Model_Id = " & blockModelId.ToString).FirstOrDefault()

                If blockModelRow IsNot Nothing Then
                    result = blockModelRow.AsString("Description")
                Else
                    result = "Unknown block model."
                End If
            End If

            Return result
        End Function
    End Class
End Namespace