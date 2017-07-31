Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports System.Text
Imports System.Runtime.CompilerServices

Imports System.Linq
Imports System.Data

' these modules add LINQ methods to the datatable + datarow
Imports System.Data.DataTableExtensions
Imports System.Data.DataRowExtensions

Namespace ReportDefinitions

    Public Class BenchErrorDistributionByAttributeReport
        Inherits ReportBase

        'Public Shared Function GetRangeData(ByVal session As Types.ReportSession, ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal locationId As Integer, _
        '                       ByVal controlModel As Integer, ByVal models As String, ByVal attributes As String, _
        '                       ByVal minimumTonnes As Double) As DataTable

        '    Return GetData(session, startDate, endDate, locationId, controlModel, models, attributes, minimumTonnes, 0, True)

        'End Function

        Public Shared Function GetData(ByVal session As Types.ReportSession, ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal locationId As Integer, _
                                       ByVal controlModel As Integer, ByVal models As String, ByVal attributes As String, _
                                       ByVal minimumTonnes As Double, ByVal designationMaterialTypeId As Integer, Optional ByVal GroupLocations As Boolean = False, Optional ByVal locationGrouping As String = Nothing) As DataTable


            Dim resultTable As DataTable = Nothing

            Dim attributeList As String() = AttributeReportHelper.GetAttributeList(attributes)
            Dim modelList As String() = AttributeReportHelper.GetModelList(models)

            For Each modelId As Integer In modelList
                Dim ds = session.DalReport.GetBhpbioReportDataBenchErrorByLocation(startDate, endDate, locationId, controlModel, modelId, minimumTonnes, session.ShouldIncludeLiveData, _
                    session.ShouldIncludeApprovedData, designationMaterialTypeId, GroupLocations, GroupLocations, locationGrouping)

                Dim table As DataTable = ds.Tables(0)

                If resultTable Is Nothing Then
                    resultTable = table
                Else
                    resultTable.Merge(ds.Tables(0))
                End If
            Next

            FilterByAttrbiutes(resultTable, attributeList)
            AddPresentationColors(resultTable, session)
            F1F2F3ReportEngine.FixModelNames(resultTable)

            Return resultTable
        End Function

        Private Shared Sub AddPresentationColors(ByRef table As DataTable, ByVal session As Types.ReportSession)
            If Not table.Columns.Contains("PresentationColor") Then
                table.Columns.Add("PresentationColor", GetType(String))
            End If

            Dim colorList = Data.ReportColour.GetColourList(session)
            For Each row As DataRow In table.Rows
                Dim tagId = row("BlockModelName2").ToString.Replace(" ", "") + "Model"
                Dim color = colorList.FirstOrDefault(Function(c) c.Key = tagId).Value

                If Not color Is Nothing Then
                    row("PresentationColor") = color
                End If
            Next

        End Sub

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

    Module BenchDataSetExtensions



    End Module

End Namespace

