Imports System.IO
Imports Snowden.Reconcilor.Core

Namespace ReportDefinition
    Public Class AutomaticContentSelectionModeFile
        Inherits AutomaticContentSelectionModeBase

        Private Const FILE_PATH_NAME = "{0}\Files\PowerPointContentMockWebServiceFiles\AutomaticContentSelectionMode_{1}_{2}_{3}.csv"
        Private _rootPath As String
        Sub New(gradeDictionary As Dictionary(Of String, Grade), ByVal rootPath As String)
            MyBase.New(gradeDictionary)
            _rootPath = rootPath
        End Sub

        Public Overrides Function BuildCompactDataTable(dataTable As DataTable, ByVal locationId As Int32, locationName As String, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, factor As AutomaticContentSelectionModeFactorEnum) As DataTable
            Dim fileName = String.Format(FILE_PATH_NAME, _rootPath, locationId, factor, COMPACT)

            If Not File.Exists(fileName) Then
                Throw New FileNotFoundException("Unable to find file for BuildCompactDataTable", fileName)
            End If

            Return ReadFile(fileName)
        End Function

        Public Overrides Function BuildExpandedDataTable(dataTable As DataTable, ByVal locationId As Int32, locationName As String, ByVal dateBreakdown As Types.ReportBreakdown, ByVal periodStart As DateTime, factor As AutomaticContentSelectionModeFactorEnum) As DataTable
            Dim fileName = String.Format(FILE_PATH_NAME, _rootPath, locationId, factor, EXPANDED)

            If Not File.Exists(fileName) Then
                Throw New FileNotFoundException("Unable to find file for BuildExpandedDataTable", fileName)
            End If

            Return ReadFile(fileName)
        End Function

        Private Function ReadFile(fileName As String) As DataTable
            Dim firstLine = True
            Dim dt As New DataTable
            AddColumns(dt)
            Dim lines = IO.File.ReadAllLines(fileName)

            For Each line In lines
                If firstLine And line.StartsWith(LOCATIONID_COLUMN) Then
                    firstLine = False
                    Continue For    '   We have a file with a header
                End If
                If (Not String.IsNullOrEmpty(line)) Then
                    Dim objFields = line.Split(","c)
                    Dim newRow = dt.NewRow
                    newRow.ItemArray = objFields.ToArray()
                    PopulateXmlColumn(newRow, _gradeDictionary)
                    dt.Rows.Add(newRow)
                End If
                firstLine = False
            Next

            Return dt

        End Function
    End Class
End Namespace