Imports System.Runtime.Remoting.Messaging
Imports Snowden.Consulting.DataSeries.DataAccess
Imports Snowden.Consulting.DataSeries.DataAccess.DataTypes

Namespace Extensibility
    Public Class OutlierHelper

        Public Const Ascending As String = "ASC"
        Public Const Descending As String = "DESC"
        Private Const OutlierSeriesTypeGroup As String = "OutlierSeriesTypeGroup"
        Private Const OutlierQueueEntryType As String = "OutlierProcessRequest"

        Public Shared Function SortDataTable(ByRef dt As DataTable, colName As String, direction As String) As DataTable
            Dim sortExpression As String = String.Format("{0} {1}", colName, direction)
            dt.DefaultView.Sort = sortExpression
            Return dt.DefaultView.ToTable()
        End Function

        Public Shared Function GetAnalysisGroups(connection As String) As DataTable

            Dim outlierProvider = New SqlServerDataSeriesDataAccessProvider(connection)
            Dim resultList = outlierProvider.GetSeriesTypeGroups()

            'Build datatable
            Dim datatable = New DataTable()
            datatable.Columns.Add(New DataColumn("Id", GetType(String)))
            datatable.Columns.Add(New DataColumn("Name", GetType(String)))

            For Each entry In resultList.Where(Function(seriesTypeGroup As SeriesTypeGroup) seriesTypeGroup.ContextKey = "OutlierAnalysisGroup" )
                Dim row = datatable.NewRow()
                row("id") = entry.Id
                row("Name") = entry.Name
                datatable.Rows.Add(row)
            Next
            Return datatable
        End Function
        Public Shared Function ReturnOutlierSeriesDataTable(connection As String, sort As Boolean) As DataTable

            Dim underlyingProvider = New SqlServerDataSeriesDataAccessProvider(connection)
            Dim outlierProvider = New OutlierDetectionDataAccessProvider(underlyingProvider)
            Dim resultList As List(Of KeyValuePair(Of SeriesType, OutlierDetectionConfiguration)) = outlierProvider.GetSeriesTypesWithOutlierConfiguration()

            'Build datatable
            Dim datatable = New DataTable()
            datatable.Columns.Add(New DataColumn("Id", GetType(String)))
            datatable.Columns.Add(New DataColumn("isActive", GetType(Boolean)))
            datatable.Columns.Add(New DataColumn("Name", GetType(String)))
            datatable.Columns.Add(New DataColumn("byAttribute", GetType(String)))
            datatable.Columns.Add(New DataColumn("locationGranularity", GetType(String)))
            datatable.Columns.Add(New DataColumn("byMaterialType", GetType(String)))
            datatable.Columns.Add(New DataColumn("byProductSize", GetType(String)))
            datatable.Columns.Add(New DataColumn("priority", GetType(Int32)))
            datatable.Columns.Add(New DataColumn("projectedValueMethod", GetType(String)))
            datatable.Columns.Add(New DataColumn("outlierThresholdValue", GetType(Double)))
            datatable.Columns.Add("View/Edit", GetType(String), "'<a href=""#"" onclick=""EditOutlierSeriesConfiguration(''' + id + ''')"">View/Edit</a>'")

            For Each entry As KeyValuePair(Of SeriesType, OutlierDetectionConfiguration) In resultList
                Dim row = datatable.NewRow()
                Dim seriesType As SeriesType = entry.Key
                Dim outlierConfiguration As OutlierDetectionConfiguration = entry.Value

                row("id") = seriesType.Id
                row("isActive") = outlierConfiguration.IsActive
                row("byAttribute") = AttributeHelper.GetStringValueOrDefault(seriesType.Attributes, "Attribute", String.Empty)
                row("locationGranularity") = AttributeHelper.GetStringValueOrDefault(seriesType.Attributes, "LocationType", String.Empty)

                Dim seriesName = seriesType.Name
                row("Name") = seriesName

                Dim matType As Boolean = AttributeHelper.GetValueOrDefault(seriesType.Attributes, "ByMaterialType", False)

                If matType Then
                    row("byMaterialType") = "Yes"
                Else
                    row("byMaterialType") = "No"
                End If

                Dim prodSize = AttributeHelper.GetValueOrDefault(seriesType.Attributes, "ByProductSize", False)

                If prodSize Then
                    row("byProductSize") = "Total, Lump, Fines"
                Else
                    row("byProductSize") = "No"
                End If

                row("priority") = outlierConfiguration.Priority
                row("projectedValueMethod") = outlierConfiguration.ProjectedValueMethod
                row("outlierThresholdValue") = outlierConfiguration.OutlierThreshold

                datatable.Rows.Add(row)
            Next

            If sort Then
                datatable = SortDataTable(datatable, "Name", Ascending)
            End If
            Return datatable
        End Function

        Public Shared Function GetConfigurationForSeriesType(connection As String, id As String) As OutlierDetectionConfiguration
            Dim underlyingProvider = New SqlServerDataSeriesDataAccessProvider(connection)
            Dim outlierProvider = New OutlierDetectionDataAccessProvider(underlyingProvider)
            Dim outlierconfig = outlierProvider.GetConfigurationForSeriesType(id)
            Return outlierconfig
        End Function

        Public Shared Function GetSeriesType(connection As String, id As String) As SeriesType
            Dim underlyingProvider = New SqlServerDataSeriesDataAccessProvider(connection)
            Return underlyingProvider.GetSeriesType(id)
        End Function

        Public Shared Sub SaveOutlierSeries(connection As String, id As String, priority As Integer, projvaluemethod As String, outlierthreshold As Double,
                                            minimumdatapoints As Integer, rollingseriessize As Integer, description As String, isactive As Boolean, triggerProcessing As Boolean)
            Dim underlyingProvider = New SqlServerDataSeriesDataAccessProvider(connection)
            Dim outlierProvider = New OutlierDetectionDataAccessProvider(underlyingProvider)
            Dim outlierconfig = outlierProvider.GetConfigurationForSeriesType(id)
            Dim seriesQueueEntry As New SeriesQueueEntry()

            outlierconfig.IsActive = isactive
            outlierconfig.Priority = priority
            outlierconfig.ProjectedValueMethod = projvaluemethod
            outlierconfig.OutlierThreshold = outlierthreshold
            outlierconfig.MinimumDataPoints = minimumdatapoints
            outlierconfig.RollingSeriesSize = rollingseriessize
            outlierconfig.Description = description

            outlierProvider.AddOrUpdateConfiguration(outlierconfig)

            If (triggerProcessing) Then
                With seriesQueueEntry
                    .Ordinal = 1
                    .QueueEntryType = OutlierQueueEntryType
                    .SeriesTypeGroupId = OutlierSeriesTypeGroup
                End With
                underlyingProvider.AddQueueEntry(seriesQueueEntry)
            End If
        End Sub

        Public Shared Function IsNumericThreshold(input As String) As Boolean

            Dim thresholdValue As Double = 0
            If (Not String.IsNullOrEmpty(input) AndAlso Information.IsNumeric(input)) Then
                If (Double.TryParse(input, thresholdValue)) Then
                    If thresholdValue >= 1 And thresholdValue <= 10 Then
                        Dim indexOfDecimalPoint As Integer = input.ToString().IndexOf(".", StringComparison.Ordinal)
                        If indexOfDecimalPoint >= 0 AndAlso (input.ToString().Length <> 3 Or input.ToString().Substring(indexOfDecimalPoint + 1) <> "5") Then
                            Return False
                        Else
                            Return True
                        End If
                    End If
                End If
            End If

            Return False
        End Function

        Public Shared Function IsIntegerAndValidRange(input As String, min As Integer, max As Integer) As Boolean

            Dim intParse As Integer = 0

            If (Not String.IsNullOrEmpty(input) AndAlso Information.IsNumeric(input)) Then
                If Integer.TryParse(input, intParse) Then
                    If intParse >= min And intParse <= max Then
                        Return True
                    End If
                End If
            End If

            Return False

        End Function



        Public Shared Function IsNumericPriority(input As String) As Boolean
            Dim intParse As Integer = 0

            If (Not String.IsNullOrEmpty(input) AndAlso Information.IsNumeric(input)) Then
                If Integer.TryParse(input, intParse) Then
                    If intParse >= 1 And intParse <= 1000 Then
                        Return True
                    End If
                End If
            End If

            Return False
        End Function

    End Class

    Module SeriesTypeExtensions
        '<System.Runtime.CompilerServices.Extension()>
        'Public Function GetValueOrDefault(Of ValueType)(attributeList As List(Of IAttribute), name As String, defaultValue As ValueType) As ValueType
        '    Return AttributeHelper.GetValueOrDefault(attributeList, name, defaultValue)
        'End Function


    End Module

End Namespace
