Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports System.Text
Imports System.Runtime.CompilerServices

Imports System.Linq
Imports System.Data

' these modules add LINQ methods to the datatable + datarow
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions

Namespace ReportDefinitions

    Public Class BenchErrorDistributionByLocationReport
        Inherits ReportBase

        Public Shared Function GetData(ByVal session As Types.ReportSession, ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal locationId As Integer, ByVal attributes As String, _
                                       ByVal blockModelId1 As Integer, ByVal blockModelId2 As Integer, ByVal minimumTonnes As Double, ByVal designationMaterialTypeId As Integer) As DataTable

            Dim ds = session.DalReport.GetBhpbioReportDataBenchErrorByLocation(startDate, endDate, locationId, blockModelId1, blockModelId2, minimumTonnes, _
                session.ShouldIncludeLiveData, session.ShouldIncludeApprovedData, designationMaterialTypeId)

            Dim table As DataTable = ds.Tables(0)

            ' filter by attribute
            Dim attributeList As String() = AttributeReportHelper.GetAttributeList(attributes)
            FilterByAttrbiutes(table, attributeList)

            Return table
        End Function

        ' the standard calculations return data for all the grades/attributes, however on the report we only specify
        ' the attributes we want, this method deletes the rows that don't have the attrbiutes we want
        Private Shared Sub FilterByAttrbiutes(ByRef table As DataTable, ByVal attributeList As String())
            ' delete rows that are not in the list of ones that we want
            Dim attributeColumn As String = "Grade"
            Dim deleteList As List(Of DataRow) = table.AsEnumerable.Where(Function(r) Not attributeList.Contains(r(attributeColumn).ToString.ToLower)).ToList
            For Each row In deleteList
                row.Table.Rows.Remove(row)
            Next
        End Sub



    End Class

    Public Class AttributeReportHelper
        Public Shared Function GetAttributeList(ByVal attributes As String) As String()
            Dim attributeList As String()
            If attributes.Trim.StartsWith("<") Then
                attributeList = Data.ReportDisplayParameter.GetXmlAsList(attributes.ToLower, "attribute", "name").Cast(Of String).ToArray
            Else
                attributeList = attributes.ToLower.Split(","c).ToArray
            End If
            Return attributeList
        End Function

        Public Shared Function GetModelList(ByVal xml As String) As String()
            Dim result As String()
            If xml.Trim.StartsWith("<") Then
                result = Data.ReportDisplayParameter.GetXmlAsList(xml, "BlockModel", "id").Cast(Of String).ToArray
            Else
                result = xml.ToLower.Split(","c).ToArray
            End If
            Return result
        End Function
    End Class


End Namespace

