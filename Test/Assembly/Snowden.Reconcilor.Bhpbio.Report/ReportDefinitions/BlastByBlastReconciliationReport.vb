Imports RecCoreDb = Snowden.Reconcilor.Core.Database
Imports ReconcilorControls = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports System.Drawing
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions.GenericDataTableExtensions

Namespace ReportDefinitions

    Public Class BlastByBlastReconciliationReport
        Inherits ReportBase

        Public Shared Function GetData(ByVal session As Types.ReportSession, _
         ByVal blastLocationId As Int32) As DataSet

            Dim digblockDal As Reconcilor.Core.Database.SqlDal.SqlDalDigblock
            Dim result As DataSet
            Dim polygonMapTable As DataTable
            Dim polygonMapRow As DataRow

            'at this stage - no transactions are being employed
            digblockDal = New Reconcilor.Core.Database.SqlDal.SqlDalDigblock()
            digblockDal.DataAccess.DataAccessConnection = session.DalReport.DataAccess.DataAccessConnection

            Try
                result = session.DalReport.GetBhpbioBlastByBlastReconciliation(blastLocationId)

                polygonMapTable = result.Tables.Add("PolygonMap")
                polygonMapTable.Columns.Add("Map", GetType(Byte()))
                polygonMapRow = polygonMapTable.NewRow()
                polygonMapTable.Rows.Add(polygonMapRow)
                polygonMapRow("Map") = GetPolygon(session, digblockDal, blastLocationId)

                result.AcceptChanges()
            Finally
                If Not (digblockDal Is Nothing) Then
                    digblockDal.Dispose()
                    digblockDal = Nothing
                End If
            End Try

            Return result
        End Function

        Private Shared Function GetPolygon(ByVal session As Types.ReportSession, _
         ByVal digblockDal As RecCoreDb.DalBaseObjects.IDigblock, _
         ByVal blastBlockLocationId As Int32) As Byte()

            Dim colourList As System.Collections.Generic.Dictionary(Of String, String) = DirectCast(Report.Data.ReportColour.GetColourList(session, True), System.Collections.Generic.Dictionary(Of String, String))
            Dim polygonData As DataTable = digblockDal.GetDigblockPolygonList(DoNotSetValues.String, blastBlockLocationId)
            Dim factorData As DataTable = GetF1Factors(session, blastBlockLocationId)
            Dim thresholds As DataTable = session.DalUtility.GetBhpbioReportThresholdList(blastBlockLocationId, "F1Factor", False, False)

            digblockDal.CreateDigblockLocationFilterTable()
            digblockDal.AddDigblockListFilterLocationId(blastBlockLocationId)

            Dim digblcokData As DataTable = digblockDal.GetDigblockList(DoNotSetValues.Int32, DoNotSetValues.String, DoNotSetValues.Int32, _
             DoNotSetValues.DateTime, DoNotSetValues.DateTime, 1, 1, 1, 0, DoNotSetValues.Int32, DoNotSetValues.Int16)

            digblockDal.DropDigblockLocationFilterTable()

            Return RenderPolygonMap(polygonData, digblcokData, factorData, colourList, thresholds)
        End Function

        Public Shared Function GetF1FactorAll(ByVal session As ReportSession, _
         ByVal blastLocationId As Int32) As DataTable
            Dim table As DataTable
            table = session.DalReport.GetBhpbioReportDataBlockModelTotal(blastLocationId, False)
            table.TableName = "FFactors"
            Return table
        End Function

        Private Shared Function GetF1Factors(ByVal session As Types.ReportSession, _
         ByVal blastLocationId As Int32) As DataTable
            Dim table As DataTable
            table = session.DalReport.GetBhpbioReportDataBlockModelTotal(blastLocationId, True)
            table.TableName = "FFactors"
            Return table
        End Function

        Private Shared Function RenderPolygonMap(ByVal polygonData As DataTable,
         ByVal digblockData As DataTable,
         ByVal factorData As DataTable,
         ByVal colourList As System.Collections.Generic.Dictionary(Of String, String),
         ByVal thresholds As DataTable) As Byte()

            If (polygonData.Rows.Count = 0) Then
                Return Nothing
            Else
                'setup polygon map object
                Dim polygonMap As New ReconcilorControls.PolygonMapper("")

                With polygonMap
                    .CanvasWidth = 600
                    .CanvasHeight = 400

                    .ChartMarginBottom = 20
                    .ChartMarginLeft = 40
                    .ChartMarginRight = 20
                    .ChartMarginTop = 20

                    .DrawText = True
                    .DrawCentroidCircle = False

                    .MapTitleFont = New Font("Arial", 10, FontStyle.Bold)
                    .ScaleFont = New Font("Arial", 7, FontStyle.Regular)
                End With

                'get tonnes threshold
                Dim lowThreshold, highThreshold As Decimal

                With thresholds.Select("FieldName = 'Tonnes'")
                    If (.Count > 0) Then
                        lowThreshold = Convert.ToDecimal(.First.Item("LowThreshold"))
                        highThreshold = Convert.ToDecimal(.First.Item("HighThreshold"))
                    Else
                        lowThreshold = 5
                        highThreshold = 10
                    End If
                End With

                'get threshold display colours
                Dim colourRatioGood As Color
                Dim colourRatioOK As Color
                Dim colourRatioBad As Color

                If (colourList.ContainsKey("RatioGood")) Then
                    colourRatioGood = Drawing.ColorTranslator.FromHtml(colourList("RatioGood"))
                Else
                    colourRatioGood = Color.LimeGreen
                End If

                If (colourList.ContainsKey("RatioOk")) Then
                    colourRatioOK = Drawing.ColorTranslator.FromHtml(colourList("RatioOk"))
                Else
                    colourRatioOK = Color.Orange
                End If

                If (colourList.ContainsKey("RatioBad")) Then
                    colourRatioBad = Drawing.ColorTranslator.FromHtml(colourList("RatioBad"))
                Else
                    colourRatioBad = Color.Crimson
                End If

                Dim polygon As ReconcilorControls.Polygon = Nothing
                Dim backgroundColour As Color
                Dim digblockId As String = ""
                Dim polygonName As String
                Dim digblockFactor As DataRow() = Nothing

                'Base it on polygon data because we want to draw the digblock even
                'if there is no data for it for this period.
                For Each polygonRow As DataRow In polygonData.Rows

                    'If its a new digblock we are dealing with
                    If digblockId <> polygonRow("Digblock_ID").ToString Then

                        'Retrieve the variance data for this digblock
                        digblockId = polygonRow("Digblock_ID").ToString
                        digblockFactor = factorData.Select("Code = '" & digblockId & "'")
                        With digblockFactor
                            If (.Count > 0) Then
                                If (Not polygon Is Nothing) Then
                                    polygonMap.Polygons.Add(polygon)
                                End If

                                If (Convert.ToDecimal(.First.Item("Tonnes")) >= 1.0 - (lowThreshold / 100.0) _
                                    And Convert.ToDecimal(.First.Item("Tonnes")) <= 1.0 + (lowThreshold / 100.0)) Then
                                    backgroundColour = colourRatioGood
                                ElseIf (Convert.ToDecimal(.First.Item("Tonnes")) >= 1.0 - (highThreshold / 100.0) _
                                    And Convert.ToDecimal(.First.Item("Tonnes")) <= 1.0 + (highThreshold / 100.0)) Then
                                    backgroundColour = colourRatioOK
                                Else
                                    backgroundColour = colourRatioBad
                                End If


                                With digblockData.Select("Digblock_Id = '" & digblockId & "'")
                                    If (.Count > 0) Then
                                        polygonName = .First.Item("Location_Block").ToString
                                    Else
                                        polygonName = digblockId
                                    End If
                                End With

                                polygon = New ReconcilorControls.Polygon(backgroundColour, polygonName, New Font("Arial", 8, Drawing.FontStyle.Bold))
                            Else
                                backgroundColour = Color.Blue
                            End If
                        End With
                    End If

                    If Not digblockFactor Is Nothing AndAlso digblockFactor.Count > 0 Then
                        polygon.Points.Add(New Point(Convert.ToInt32(polygonRow("X")), Convert.ToInt32(polygonRow("Y"))))
                    End If
                Next

                'Trailing Read
                If (Not polygon Is Nothing) Then
                    polygonMap.Polygons.Add(polygon)
                End If

                polygonMap.CalculateMapBounds()

                'Save image to memory stream
                Dim OutputStream As New System.IO.MemoryStream
                polygonMap.Save(OutputStream, System.Drawing.Imaging.ImageFormat.Png)

                Return OutputStream.ToArray
            End If
        End Function

        Public Shared Function GetResourceClassificationByLocation(ByVal session As Types.ReportSession, ByVal locationId As Int32, ByVal blockModelList As String(), blockedDateFrom As DateTime?, blockedDateTo As DateTime?) As DataTable
            Dim table As DataTable = Nothing

            If blockedDateFrom.HasValue AndAlso blockedDateTo.HasValue Then
                table = session.DalReport.GetBhpbioResourceClassificationByLocation(locationId, blockedDateFrom.Value, blockedDateTo.Value)
            Else
                table = session.DalReport.GetBhpbioResourceClassificationByLocation(locationId, Date.Today)
            End If

            ' filter the table based on the list of models
            Dim unneededRows = table.AsEnumerable.Where(Function(r) Not blockModelList.Contains(r.AsString("BlockModelName")))
            table.DeleteRows(unneededRows.AsEnumerable)

            ' add the RC description column. Soon there will be a shared method for this, and we can use that instead
            If Not table.Columns.Contains("ResourceClassificationDescription") Then
                table.Columns.Add("ResourceClassificationDescription", GetType(String))
            End If

            If Not table.Columns.Contains("PresentationColor") Then
                table.Columns.Add("PresentationColor", GetType(String))
            End If

            For Each row As DataRow In table.Rows
                Dim classification = row.AsString("ResourceClassification")
                Dim blockModel = row.AsString("BlockModelName")

                row("ResourceClassificationDescription") = F1F2F3ReportEngine.GetResourceClassificationDescription(classification, blockModel)
                row("PresentationColor") = F1F2F3ReportEngine.GetResourceClassificationColor(classification)
            Next

            Return table
        End Function

        Public Shared Function GetBlastblockDataExportReport(ByVal session As Types.ReportSession, ByVal locationId As Int32,
            ByVal dateFrom As DateTime, ByVal dateTo As DateTime) As DataTable

            Return session.DalReport.GetBhpbioBlastblockDataExportReportForExcel(locationId, dateFrom, dateTo, session.ShouldIncludeLiveData, session.ShouldIncludeApprovedData)
        End Function
        Public Shared Function GetBlastblockbyOreTypeDataExportReport(ByVal session As Types.ReportSession, ByVal locationId As Int32,
            ByVal dateFrom As DateTime, ByVal dateTo As DateTime, ByVal includeLumpFines As Boolean) As DataTable

            Return session.DalReport.GetBhpbioBlastblockbyOreTypeDataExportReportForExcel(locationId, dateFrom, dateTo, includeLumpFines, session.ShouldIncludeLiveData, session.ShouldIncludeApprovedData)
        End Function

    End Class
End Namespace
