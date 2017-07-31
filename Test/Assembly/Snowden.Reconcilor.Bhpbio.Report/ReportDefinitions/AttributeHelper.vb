Imports System.Text
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Core

Public Module AttributeHelper
    Public Function ConvertAttributeCsvToXml(ByVal csvList As String, gradeDictionary As Dictionary(Of String, Grade)) As String
        Dim id As Integer
        Dim attrArray As String() = csvList.Split(CChar(","))

        Dim returnVal As StringBuilder = New StringBuilder("<Attributes>")

        For Each attribute As String In attrArray
            If (attribute <> String.Empty) Then
                If attribute = "Tonnes" Then
                    id = 0
                ElseIf attribute = "Volume" Then
                    id = 99
                ElseIf gradeDictionary.ContainsKey(attribute) Then
                    id = gradeDictionary(attribute).Id
                End If
                returnVal.Append(String.Format("<Attribute id=""{0}"" name=""{1}""/>", id, attribute))
            End If
        Next

        returnVal.Append("</Attributes>")
        Return returnVal.ToString

    End Function

End Module
