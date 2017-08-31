Imports System.Web.Services
Imports System.ComponentModel
Imports NullValues = Snowden.Common.Database.DataAccessBaseObjects.NullValues
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
Imports System.Text
Imports Snowden.Reconcilor.Core
Imports System.Configuration
Imports System.Runtime.CompilerServices
Imports System.Web.Hosting
Imports System.Xml
Imports Snowden.Reconcilor.Bhpbio.Report.Calc
Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinition

<WebService(Namespace:="http://www.reconcilor.com.au/ReconcilorBHPBIO/Reporting/2008/11/")>
<WebServiceBinding(ConformsTo:=WsiProfiles.BasicProfile1_1)>
<ToolboxItem(False)>
Public Class WebService
    Inherits Web.Services.WebService

    Public Const USE_CSV_OVERRIDE_FILE_FOR_GETPOWERPOINTCONTENTSELECTION = "useCsvOverrideFileForGetPowerPointContentSelection"

    Private _overrideConnectionString As String = Nothing
    Private _overrideReportContext As ReportContext? = Nothing

    Public Shared AllowPatternLevelReconExports As Boolean = True
    Public Shared AllowForwardEstimatesInReconExports As Boolean = False

    Public Enum FactorsVsTimeReportSubType
        Moisture = 1
        Density = 2
        Volume = 3
        Product = 4
    End Enum

    Public Sub SetOverrideConnectionString(overrideConnectionString As String)
        _overrideConnectionString = overrideConnectionString
    End Sub

    Public Sub SetOverrideReportContext(overrideReportContext As ReportContext)
        _overrideReportContext = overrideReportContext
    End Sub

    ' Assistant Functions
    Public Function CreateReportSession() As ReportSession
        Dim reportSession As New ReportSession
        Dim connectionString As String = GetConnectionString()

        If (_overrideReportContext IsNot Nothing) Then
            reportSession.Context = _overrideReportContext.Value
        End If

        reportSession.FileSystemRoot = Server.MapPath("~")
        reportSession.SetupDal(connectionString)

        Return reportSession
    End Function

    Private Function GetConnectionString() As String
        Dim connectionString As String

        If (_overrideConnectionString IsNot Nothing) Then
            connectionString = _overrideConnectionString
        Else
            connectionString = Application("ConnectionString").ToString
        End If

        Return connectionString
    End Function

    'Obtain a list of Product Type Codes given a comma delimited list of Ids
    <WebMethod>
    Public Function GetProductTypeCodes(productTypeIds As String) As String
        Dim codeListString As New StringBuilder

        Using reportSession As ReportSession = CreateReportSession()
            If Not String.IsNullOrEmpty(productTypeIds) Then

                Dim productTypeIdStrings As String() = productTypeIds.Split({","c})
                Dim productTypeIdIntegerValues As List(Of Integer) = productTypeIdStrings.Select(Of Integer)(Function(s) Integer.Parse(s)).ToList()

                For Each ptId As Integer In productTypeIdIntegerValues

                    Dim pt As ProductType = reportSession.ProductTypes.FirstOrDefault(Function(p) p.ProductTypeID = ptId)

                    If (pt IsNot Nothing) Then
                        If (codeListString.Length > 0) Then
                            codeListString.Append(", ")
                        End If
                        codeListString.Append(pt.ProductTypeCode)
                    End If
                Next

                Return codeListString.ToString()
            Else
                Return ""
            End If
        End Using
    End Function

    ' Web Methods
    <WebMethod>
    Public Function FHUBReport(locationId As Int32, dateFrom As String, dateTo As String, dateBreakdown As String, lumpFinesBreakdown As Boolean,
                               f25Required As Boolean, productTypeIds As String, reportContext As String, isRFGMRequired As Boolean, isRFMMRequired As Boolean,
                               isRFSTMRequired As Boolean) As DataTable

        Using reportSession As ReportSession = CreateReportSession()
            reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown
            reportSession.Context = GetReportContext(reportContext)

            Dim data = F1F2F3HubReconciliationReport.GetF1F2F3HubWithGeometReportData(reportSession, locationId, Convert.ToDateTime(dateFrom),
                                                                                      Convert.ToDateTime(dateTo), dateBreakdown, f25Required, productTypeIds,
                                                                                      isRFGMRequired, isRFMMRequired, isRFSTMRequired)

            data.AcceptChanges()
            Return data
        End Using
    End Function

    <WebMethod>
    Public Function GetBhpbioSupplyChainMoistureProfileReport(locationId As Int32, dateFrom As String, dateTo As String, dateBreakdown As String,
                                                              lumpFinesBreakdown As Boolean, f25Required As Boolean) As DataTable

        Using reportSession As ReportSession = CreateReportSession()
            reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown
            reportSession.IgnoreLumpFinesCutover = True
            reportSession.OptionalCalculationTypesToInclude.Add(CalcType.RecoveryFactorMoisture)

            Dim data As DataTable
            data = F1F2F3HubReconciliationReport.GetF1F2F3HubReportData(reportSession, locationId, Convert.ToDateTime(dateFrom), Convert.ToDateTime(dateTo),
                                                                        dateBreakdown, f25Required)

            ' we need to rename some calculations. It would be better to do this the normal way inside the calculation classes, but that would
            ' require more refactoring than is feasible at the moment. Instead we will just do a search and replace of the descriptions here
            For Each row As DataRow In data.Rows
                If row("Description").ToString.StartsWith("F3") Then
                    row("Description") = "F3 - Ore Shipped / Mining Model (As Shipped)"
                End If
            Next

            data.AcceptChanges()

            Return data
        End Using
    End Function

    <WebMethod>
    Public Function F1F2F3TestReport(locationId As Int32, dateFrom As String, dateTo As String, dateBreakdown As String, lumpFinesBreakdown As Boolean,
                                     reportContext As String) As DataTable

        Dim data As DataTable

        Select Case reportContext.ToUpper
            Case "LIVE" : SetOverrideReportContext(Types.ReportContext.LiveOnly)
            Case "APPROVED" : SetOverrideReportContext(Types.ReportContext.Standard)
            Case "COMBINED" : SetOverrideReportContext(Types.ReportContext.ApprovalListing)
        End Select

        Using reportSession As ReportSession = CreateReportSession()
            reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown

            reportSession.OptionalCalculationTypesToInclude.Add(CalcType.RecoveryFactorMoisture)
            reportSession.OptionalCalculationTypesToInclude.Add(CalcType.RecoveryFactorDensity)

            data = F1F2F3HubReconciliationReport.GetF1F2F3HubReportData(reportSession, locationId, Convert.ToDateTime(dateFrom), Convert.ToDateTime(dateTo),
                                                                        dateBreakdown, True)
            data.AcceptChanges()
        End Using

        Return data
    End Function

    <WebMethod>
    Public Function GetBhpbioReconciliationDataExportDataExcelReady(productTypeCode As String, locationId As Int32, dateFrom As DateTime, dateTo As DateTime,
                                                                    dateBreakdown As String, lumpFinesBreakdown As Boolean, includeSublocations As Boolean,
                                                                    includeResourceClassifications As Boolean, useFowardEstimates As Boolean) As DataTable

        Using reportSession As ReportSession = CreateReportSession()
            If AllowPatternLevelReconExports AndAlso includeSublocations AndAlso reportSession.GetLocationTypeName(locationId) = "Pit" Then
                reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown
                reportSession.IncludeResourceClassification = includeResourceClassifications
                reportSession.ForwardModelFactorCalculation = useFowardEstimates

                Dim table = ReconciliationDataExportReport.GetPatternLevelFactors(reportSession, locationId, dateFrom, dateTo)
                table.TableName = "Values"
                table.AcceptChanges()
                Return table
            Else
                Dim data = GetBhpbioReconciliationDataExportData(productTypeCode, locationId, dateFrom, dateTo, dateBreakdown, lumpFinesBreakdown,
                                                                 includeSublocations, includeResourceClassifications)
                Return ReconciliationDataExportReport.ConvertDataTableForExcel(data)
            End If
        End Using
    End Function

    <WebMethod>
    Public Function GetBhpbioResourceClassificationNamesAndColours(factor As String) As DataTable
        Dim effectiveFactor As String = factor
        Dim dt As New DataTable With {
            .TableName = "Values"
        }

        If (effectiveFactor.Contains("F15")) Then
            effectiveFactor = "F15Factor"
        End If

        For Each resourceClassificationCode In ResourceContributionReports.ResourceClassificationFieldNames
            dt.Columns.Add(resourceClassificationCode + "Description", GetType(String))
            dt.Columns.Add(resourceClassificationCode + "Colour", GetType(String))
        Next

        Dim dr = dt.NewRow()
        dt.Rows.Add(dr)

        For Each resourceClassificationCode In ResourceContributionReports.ResourceClassificationFieldNames
            dr(resourceClassificationCode + "Description") = F1F2F3ReportEngine.GetResourceClassificationDescription(resourceClassificationCode, effectiveFactor)
            dr(resourceClassificationCode + "Colour") = F1F2F3ReportEngine.GetResourceClassificationColor(resourceClassificationCode)
        Next

        Return dt
    End Function

    <WebMethod>
    Public Function GetBhpbioResourceClassificationData(locationId As Int32, dateFrom As DateTime, dateTo As DateTime, dateBreakdown As String,
                                                        includeSublocations As Boolean, reportContext As String, returnEmptyDataSet As Boolean) As DataTable

        If returnEmptyDataSet Then
            Dim data = New DataTable() With {
                .TableName = "Values"
            }
            Return data
        End If

        Using reportSession As ReportSession = CreateReportSession()
            reportSession.RethrowCalculationSetErrors = True
            reportSession.IncludeProductSizeBreakdown = False
            reportSession.ExplicitlyIncludeExtendedH2OModelCalculations = False
            reportSession.IncludeResourceClassification = True

            reportSession.Context = GetReportContext(reportContext)

            Dim data = F1F2F3OverviewReconciliationReport.GetFactorsAndChildren(reportSession, locationId, dateFrom, dateTo)

            If Not data.Columns.Contains("ContributionColour") Then
                data.Columns.Add("ContributionColour", GetType(String))
            End If

            data.AsEnumerable.Where(Function(r) Not r.HasValue("ResourceClassification")).SetField("ResourceClassification", "ResourceClassificationTotal")
            F1F2F3ReportEngine.AddResourceClassificationDescriptions(data)

            For Each row As DataRow In data.Rows
                Dim id = row.AsString("ResourceClassification")
                Dim desc = row.AsString("ResourceClassificationDescription")

                row("ContributionColour") = F1F2F3ReportEngine.GetResourceClassificationColor(id)

                If Not id.EndsWith("Total") Then
                    row("Description") = String.Format("{0} - {1}", row.AsString("Description"), desc)
                End If
            Next

            If data.Columns.Contains("Order_No") Then
                Return data.DefaultView.ToTable
            Else
                Return data
            End If

        End Using
    End Function

    <WebMethod>
    Public Function GetBhpbioReconciliationDataExportData(productTypeCode As String, locationId As Int32, dateFrom As DateTime, dateTo As DateTime,
                                                          dateBreakdown As String, lumpFinesBreakdown As Boolean, includeSublocations As Boolean,
                                                          includeResourceClassifications As Boolean) As DataTable

        Using reportSession As ReportSession = CreateReportSession()
            reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown
            reportSession.IncludeGeometData = reportSession.IncludeProductSizeBreakdown
            reportSession.ExplicitlyIncludeExtendedH2OModelCalculations = False
            reportSession.IncludeAsShippedModelsInHubSet = True
            reportSession.IncludeResourceClassification = includeResourceClassifications

            'Add RF calcs
            reportSession.OptionalCalculationTypesToInclude.Add(CalcType.RFGM)
            reportSession.OptionalCalculationTypesToInclude.Add(CalcType.RFMM)
            reportSession.OptionalCalculationTypesToInclude.Add(CalcType.RFSTM)

            If reportSession.IncludeProductSizeBreakdown AndAlso reportSession.GeometReportingEnabled Then
                reportSession.OptionalCalculationTypesToInclude.Add(CalcType.ModelMiningBene)
            End If

            If productTypeCode IsNot Nothing Then
                ' this will automatically set the location id and product size filter as required (in the session)
                reportSession.ProductTypeCode = productTypeCode

                ' however many of the methods used after this take a location_id parameter directly 
                ' instead of using the report session, so lets set this now (even though it is kind of 'wrong'
                ' to do it this way)
                locationId = reportSession.SelectedProductType.LocationId
            End If

            Dim data = ReconciliationDataExportReport.GetF1F2F3AllLocationsReconciliationReportData(reportSession, locationId,
                dateFrom, dateTo, dateBreakdown, includeSublocations)

            ' if we have lump/fines in the table, then we want to have geomet as well
            If reportSession.IncludeProductSizeBreakdown AndAlso reportSession.GeometReportingEnabled AndAlso reportSession.SelectedProductType Is Nothing Then
                Dim geomet = New F1F2F3GeometDataHelper(reportSession)
                data = geomet.AddGeometData(data)
            End If

            data.AcceptChanges()

            If data.Columns.Contains("ResourceClassification") Then
                ' Update row descriptions
                F1F2F3ReportEngine.AddResourceClassificationDescriptions(data)

                For Each row As DataRow In data.Rows
                    If row.HasValue("ResourceClassification") Then
                        Dim classificationDescription = row.AsString("ResourceClassificationDescription")

                        If Not String.IsNullOrEmpty(classificationDescription) Then
                            row("Description") = String.Format("{0} - {1}", row("Description"), classificationDescription)
                        End If
                    End If
                Next
            End If

            If data.Columns.Contains("Order_No") Then
                Return data.DefaultView.ToTable
            Else
                Return data
            End If
        End Using
    End Function

    <WebMethod>
    Public Function GetF2AnalysisReportData(locationId As Integer, dateBreakdown As String, dateFrom As DateTime, dateTo As DateTime, factor As String,
                                            attributes As String, contextSelection As String, liveApprovedContext As String) As DataTable

        Using reportSession As ReportSession = CreateReportSession()
            reportSession.Context = GetReportContext(liveApprovedContext)
            reportSession.RethrowCalculationSetErrors = True

            Dim attributeList = GetAttributeListFromString(attributes)
            Dim contextSelectionList = contextSelection.Split(","c).Select(Function(a) a.Trim).Where(Function(a) Not String.IsNullOrEmpty(a))
            Dim dateBreakdownEnum = ReportSession.ConvertReportBreakdown(dateBreakdown)

            Dim table = F2AnalysisReport.GetData(reportSession, locationId, dateBreakdownEnum, dateFrom, dateTo, factor, attributeList.ToArray,
                                                 contextSelectionList.ToArray)
            table.TableName = "Values"
            table.AcceptChanges()
            Return table
        End Using
    End Function

    <WebMethod>
    Public Function GetBhpbioPatternBlockoutData(locationId As Integer, dateFrom As DateTime, dateTo As DateTime) As DataTable
        Using reportSession As ReportSession = CreateReportSession()
            Dim table = BlockOutSummaryReport.GetPatternFactors(reportSession, locationId, dateFrom, dateTo)

            table.TableName = "Values"
            table.AcceptChanges()
            Return table
        End Using
    End Function

    <WebMethod>
    Public Function GetPatternValidationData(locationId As Integer, dateFrom As DateTime, dateTo As DateTime) As DataTable
        Using reportSession As ReportSession = CreateReportSession()
            Dim table = BlockOutSummaryReport.GetPatternValidationData(reportSession, locationId, dateFrom, dateTo)
            table.TableName = "Values"
            table.AcceptChanges()
            Return table
        End Using
    End Function

    <WebMethod>
    Public Function GetBhpbioReportThresholdList(locationId As Int32, thresholdTypeId As String) As DataTable
        Dim reportSession As ReportSession = CreateReportSession()
        Dim data As DataTable = reportSession.DalUtility.GetBhpbioReportThresholdList(locationId, thresholdTypeId, False, False)

        Dim dr As DataRow

        For Each dr In data.Rows
            If dr("LowThreshold").Equals(DBNull.Value) Then
                dr("LowThreshold") = False
            End If
            If dr("HighThreshold").Equals(DBNull.Value) Then
                dr("HighThreshold") = False
            End If
            If dr("AbsoluteThreshold").Equals(DBNull.Value) Then
                dr("AbsoluteThreshold") = False
            End If
        Next

        data.TableName = "ReportThresholdList"
        reportSession.Dispose()

        Return data
    End Function

    Private Shared Function GetReportContext(reportContext As String) As ReportContext
        If (String.IsNullOrEmpty(reportContext)) Then
            Return Types.ReportContext.Standard
        End If

        Select Case reportContext.ToLower()
            Case "liveonly"
                Return Types.ReportContext.LiveOnly
            Case "live"
                Return Types.ReportContext.LiveOnly
            Case "approvallisting"
                Return Types.ReportContext.ApprovalListing
            Case "combined"
                Return Types.ReportContext.ApprovalListing
            Case Else
                Return Types.ReportContext.Standard
        End Select
    End Function

    <WebMethod>
    Public Function GetBhpbioF1F2F3HUBReconAttributeReport(locationId As Int32, dateFrom As String, dateTo As String, dateBreakdown As String,
                                                           attributes As String, factors As String, lumpFinesBreakdown As Boolean, productTypeId As Integer,
                                                           reportContext As String, includeGeometData As Boolean, reportName As String) As DataTable

        Dim data As DataTable

        Using reportSession As ReportSession = CreateReportSession()
            reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown
            reportSession.IncludeGeometData = includeGeometData And lumpFinesBreakdown
            reportSession.Context = GetReportContext(reportContext)
            reportSession.ReportName = reportName

            Dim startDate = Convert.ToDateTime(dateFrom)
            Dim endDate = Convert.ToDateTime(dateTo)
            Dim reportDateBreakdown = ReportSession.ConvertReportBreakdown(dateBreakdown)

            If productTypeId > 0 Then
                data = F1F2F3ReconciliationByAttributeReport.GetDataProductType(
                    reportSession, productTypeId, startDate, endDate,
                    attributes, factors, reportDateBreakdown)
            Else
                data = F1F2F3ReconciliationByAttributeReport.GetData(
                     reportSession, locationId, startDate, endDate,
                    reportDateBreakdown, attributes, factors)
            End If

            data.AcceptChanges()
        End Using

        ' Ensure that every data series has data going back to the beginning of the report.. this is neccessary to ensure that the Reporting Services charts operate as expected
        If lumpFinesBreakdown AndAlso Not includeGeometData Then
            ' only required for Lump and Fines though. It should work regardless, but in order to limit possible regressions
            ' we will only run when L/F is turned on
            CalculationResult.FillInDataTableMissingLeadingDataPoints(data)
        End If

        If includeGeometData Then
            ' for this particular report, we want to remove all other product sizes when the geomet
            ' data is included. This is not always the case, but it is for this report
            data.AsEnumerable.Where(Function(r) r.AsString("ProductSize") <> "GEOMET").DeleteRows()
        End If

        Return data
    End Function

    <WebMethod>
    Public Function GetBhpbioSupplyChainMonitoringReport(locationId As Int32, dateFrom As String, dateTo As String, attributes As String,
                                                         productTypeId As Integer, reportContext As String) As DataTable

        Using reportSession As ReportSession = CreateReportSession()
            reportSession.IncludeProductSizeBreakdown = False
            reportSession.Context = GetReportContext(reportContext)
            Dim data As DataTable
            If productTypeId > 0 Then
                data = SupplyChainMonitoringReport.GetDataProductType(
                reportSession, productTypeId, Convert.ToDateTime(dateFrom), Convert.ToDateTime(dateTo), attributes)
            Else
                reportSession.IncludeProductSizeBreakdown = False
                data = SupplyChainMonitoringReport.GetData(
                reportSession, locationId, Convert.ToDateTime(dateFrom), Convert.ToDateTime(dateTo), attributes)
            End If

            data.AcceptChanges()
            Return data
        End Using
    End Function

    <WebMethod>
    Public Function GetBhpbioBenchErrorByAttributeReport(locationId As Int32, dateFrom As String, dateTo As String, attributes As String,
                                                         controlModel As Integer, models As String, minimumTonnes As Integer,
                                                         designationMaterialTypeId As Int32) As DataTable

        Dim reportSession As ReportSession = CreateReportSession()
        reportSession.IncludeProductSizeBreakdown = False

        Dim data As DataTable = BenchErrorDistributionByAttributeReport.GetData(
            reportSession, Convert.ToDateTime(dateFrom), Convert.ToDateTime(dateTo), locationId,
            controlModel, models, attributes, minimumTonnes, designationMaterialTypeId)

        data.AcceptChanges()
        reportSession.Dispose()

        Return data
    End Function

    <WebMethod>
    Public Function GetBhpbioBenchErrorByLocationReport(locationId As Int32, dateFrom As String, dateTo As String, attributes As String,
            blockModelId1 As Integer, blockModelId2 As Integer, minimumTonnes As Integer, designationMaterialTypeId As Int32) As DataTable
        Dim reportSession As ReportSession = CreateReportSession()
        reportSession.IncludeProductSizeBreakdown = False

        Dim data As DataTable = BenchErrorDistributionByLocationReport.GetData(
            reportSession, Convert.ToDateTime(dateFrom), Convert.ToDateTime(dateTo), locationId, attributes,
            blockModelId1, blockModelId2, minimumTonnes, designationMaterialTypeId)

        data.AcceptChanges()
        reportSession.Dispose()

        Return data
    End Function

    <WebMethod>
    Public Function GetBhpbioReconciliationRangeReport(locationId As Int32, dateFrom As String, dateTo As String, attributes As String,
            controlModel As Integer, models As String, designationMaterialTypeId As Int32,
            minimumTonnes As Integer, locationGrouping As String) As DataTable

        Dim reportSession As ReportSession = CreateReportSession()
        reportSession.IncludeProductSizeBreakdown = False

        If locationGrouping.ToUpper <> "PIT" And locationGrouping.ToUpper <> "BENCH" Then
            Throw New Exception("Only PIT and BENCH are valid location groupings for this report")
        End If

        Dim data As DataTable = BenchErrorDistributionByAttributeReport.GetData(
            reportSession, Convert.ToDateTime(dateFrom), Convert.ToDateTime(dateTo), locationId,
            controlModel, models, attributes, minimumTonnes, designationMaterialTypeId, True, locationGrouping)

        data.AcceptChanges()
        reportSession.Dispose()

        Return data
    End Function

    <WebMethod>
    Public Function GetF1F2F3ReconciliationComparisonReport(locationId As Int32, dateFrom As String, dateTo As String, dateBreakdown As String,
                                                            attributes As String, factor As String, locations As String, lumpFinesBreakdown As Boolean,
                                                            reportContext As String) As DataTable

        Dim reportSession As ReportSession = CreateReportSession()
        reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown
        reportSession.Context = GetReportContext(reportContext)

        Dim data As DataTable = F1F2F3ReconciliationComparisonReport.GetData(
        reportSession, locationId, Convert.ToDateTime(dateFrom), Convert.ToDateTime(dateTo),
        ReportSession.ConvertReportBreakdown(dateBreakdown), attributes, factor, locations)
        data.AcceptChanges()

        reportSession.Dispose()

        Return data
    End Function

    <WebMethod>
    Public Function GetBhpbioShippingTargetsByLocationReport(productTypeId As Integer, locationId As Int32, dateFrom As DateTime, dateTo As DateTime,
                                                             singleSource As String, attributes As String, dateBreakdown As String,
                                                             reportContext As String) As DataTable

        Using reportSession As ReportSession = CreateReportSession()
            Dim breakdown = dateBreakdown.ToReportBreakdown()
            Dim attributeList = ConvertXmlToCsv(attributes, "Attribute", "name").Split(","c).Select(Function(c) c.Trim).ToArray
            Dim factorList = New String() {singleSource}

            If productTypeId > 0 Then
                reportSession.ProductTypeId = productTypeId
            Else
                reportSession.IncludeProductSizeBreakdown = False
            End If
            
            reportSession.Context = GetReportContext(reportContext)

            Dim report = New ShippingTargetsReport() With {
                .IncludeChildLocations = True
            }

            Dim data As DataTable = report.GetShippingData(reportSession, productTypeId, dateFrom, dateTo, attributeList, factorList, breakdown)
            data.AcceptChanges()
            Return data
        End Using
    End Function

    <WebMethod>
    Public Function GetBhpbioShippingTargetsReport(productTypeId As Integer, locationId As Int32, dateFrom As DateTime, dateTo As DateTime, factors As String,
                                                   attributes As String, dateBreakdown As String, reportContext As String) As DataTable

        Using reportSession As ReportSession = CreateReportSession()
            Dim breakdown = dateBreakdown.ToReportBreakdown()
            Dim attributeList = ConvertXmlToCsv(attributes, "Attribute", "name").Split(","c).Select(Function(c) c.Trim).ToArray
            Dim factorList = ConvertXmlToCsv(factors, "Factor", "id").Split(","c).Select(Function(c) c.Trim).ToArray

            If productTypeId > 0 Then
                reportSession.ProductTypeId = productTypeId
            Else
                reportSession.IncludeProductSizeBreakdown = False
            End If
            reportSession.Context = GetReportContext(reportContext)

            Dim report = New ShippingTargetsReport() With {
                .IncludeChildLocations = False
            }

            Dim data As DataTable = report.GetShippingData(reportSession, productTypeId, dateFrom, dateTo, attributeList, factorList, breakdown)
            data.AcceptChanges()
            Return data
        End Using
    End Function

    <WebMethod>
    Public Function GetF1F2F3UnpivotedErrorContributionData(productTypeId As Integer, locationId As Int32, dateFrom As DateTime, dateTo As DateTime,
                                                            dateBreakdown As String, byResourceClassification As Boolean, reportContext As String,
                                                            lumpFinesBreakdown As Boolean, returnEmptyDataSet As Boolean) As DataTable

        Dim allowedFactors = New String() {"F1Factor", "F15Factor", "F2Factor", "F25Factor", "F3Factor"}

        If returnEmptyDataSet Then
            Dim data = New DataTable() With {
                .TableName = "Values"
            }
            Return data
        End If

        Using reportSession As ReportSession = CreateReportSession()
            reportSession.RethrowCalculationSetErrors = True

            reportSession.Context = GetReportContext(reportContext)
            Dim breakdown = dateBreakdown.ToReportBreakdown()
            Dim includeChildLocations As Boolean = True
            Dim report As F1F2F3ReconciliationByAttributeReport

            reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown

            If (byResourceClassification) Then
                reportSession.IncludeResourceClassification = True
                includeChildLocations = False

                ' use a version of the repor that retrieves resource classification only information
                report = New ResourceClassificationContributionReport
            Else
                report = New F1F2F3ReconciliationByAttributeReport
            End If

            If productTypeId > 0 Then
                reportSession.ProductTypeId = productTypeId
            End If

            Dim data As DataTable = report.GetContributionData(reportSession, productTypeId, locationId, dateFrom, dateTo, breakdown, includeChildLocations, True)
            data.AsEnumerable.Where(Function(r) Not r.HasValue("ResourceClassification")).SetField("ResourceClassification", "ResourceClassificationTotal")
            F1F2F3ReportEngine.AddResourceClassificationDescriptions(data)

            For Each row As DataRow In data.Rows

                If byResourceClassification Then
                    Dim id = row.AsString("ResourceClassification")
                    Dim desc = row.AsString("ResourceClassificationDescription")

                    row("LocationColor") = F1F2F3ReportEngine.GetResourceClassificationColor(id)
                    If Not id.EndsWith("Total") Then
                        row("Description") = String.Format("{0} - {1}", row.AsString("Description"), desc)
                    End If
                End If

                If (lumpFinesBreakdown) Then
                    row("Description") = String.Format("{0} - {1}", row.AsString("Description"), row.AsString("ProductSize"))
                End If
            Next

            F1F2F3ReportEngine.FilterTableByFactors(data, allowedFactors)
            F1F2F3ReportEngine.AddTagOrderNo(data)
            data.AddLabelColor()
            data.AcceptChanges()
            Return data
        End Using
    End Function

    <WebMethod>
    Public Function GetBhpbioModelComparisonReport(dateFrom As DateTime, dateTo As DateTime, dateBreakdown As String, locationId As Int32,
                                                   includeBlockModels As Boolean, blockModels As String, includeActuals As Boolean,
                                                   designationMaterialTypeId As Int32, includeDesignationMaterialTypeId As Boolean, includeTonnes As Boolean,
                                                   grades As String, lumpFinesBreakdown As Boolean) As DataSet

        Dim result As DataSet
        Dim reportSession As ReportSession = CreateReportSession()
        reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown

        Try
            result = ModelComparisonReport.GetData(
             reportSession, dateFrom, dateTo, dateBreakdown,
            locationId, includeBlockModels, blockModels, includeActuals,
            designationMaterialTypeId, includeDesignationMaterialTypeId,
            includeTonnes, grades, lumpFinesBreakdown)
        Finally
            If (reportSession IsNot Nothing) Then
                reportSession.Dispose()
            End If
        End Try

        Return result
    End Function

    <WebMethod>
    Public Function GetBhpbioGradeRecoveryReport(dateFrom As DateTime, dateTo As DateTime, locationId As Int32, includeBlockModels As Boolean,
                                                 blockModels As String, includeActuals As Boolean, designationMaterialTypeId As Int32,
                                                 includeDesignationMaterialTypeId As Boolean, includeTonnes As Boolean, includeVolume As Boolean,
                                                 grades As String, lumpFinesBreakdown As Boolean) As DataSet

        Dim result As DataSet
        Dim reportSession As ReportSession = CreateReportSession()

        Try
            result = GradeRecoveryReport.GetData(reportSession, dateFrom, dateTo, locationId, includeBlockModels, blockModels, includeActuals,
                                                 designationMaterialTypeId, includeDesignationMaterialTypeId, includeTonnes, includeVolume, grades,
                                                 lumpFinesBreakdown)

            result.AcceptChanges()
        Finally
            If (reportSession IsNot Nothing) Then
                reportSession.Dispose()
            End If
        End Try

        Return result
    End Function

    <WebMethod>
    Public Function GetBhpbioMovementRecoveryReport(dateTo As DateTime, locationId As Int32, comparison1IsActual As Boolean, comparison1BlockModelId As Int32,
                                                    comparison2IsActual As Boolean, comparison2BlockModelId As Int32, lumpFinesBreakdown As Boolean) As DataSet

        Dim result As DataSet
        Dim reportSession As ReportSession = CreateReportSession()
        reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown

        Try
            result = reportSession.DalReport.GetBhpbioMovementRecoveryReport(dateTo, locationId, Convert.ToInt16(comparison1IsActual), comparison1BlockModelId,
                                                                             Convert.ToInt16(comparison2IsActual), comparison2BlockModelId,
                                                                             reportSession.ShouldIncludeLiveData, reportSession.ShouldIncludeApprovedData)
        Finally
            If (reportSession IsNot Nothing) Then
                reportSession.Dispose()
            End If
        End Try

        Return result
    End Function

    <WebMethod>
    Public Function GetBhpbioRecoveryAnalysisReport(dateFrom As DateTime, dateTo As DateTime, dateBreakdown As String, locationId As Int32,
                                                    includeBlockModels As Boolean, blockModels As String, includeActuals As Boolean,
                                                    designationMaterialTypeId As Int32, includeDesignationMaterialTypeId As Boolean,
                                                    lumpFinesBreakdown As Boolean) As DataSet

        Dim result As DataSet
        Dim reportSession As ReportSession = CreateReportSession()
        reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown

        Try
            result = RecoveryAnalysisReport.GetData(reportSession, dateFrom, dateTo, ReportSession.ConvertReportBreakdown(dateBreakdown), locationId,
                                                    includeBlockModels, blockModels, includeActuals, designationMaterialTypeId, includeDesignationMaterialTypeId)
        Finally
            If (reportSession IsNot Nothing) Then
                reportSession.Dispose()
            End If
        End Try

        Return result
    End Function

    <WebMethod>
    Public Function GetResourceClassificationByLocationData(locationId As Int32, blockModels As String, blockedDateFrom As DateTime?,
                                                            blockedDateTo As DateTime?) As DataTable

        Using reportSession As ReportSession = CreateReportSession()
            Dim blockModelList = blockModels.Split(","c).Select(Function(m) m.Trim).ToArray
            Dim table = BlastByBlastReconciliationReport.GetResourceClassificationByLocation(reportSession, locationId, blockModelList, blockedDateFrom,
                                                                                             blockedDateTo)
            table.TableName = "Values"
            table.AcceptChanges()
            Return table
        End Using
    End Function

    <WebMethod>
    Public Function ListResourceClassifications() As DataTable
        Dim table = New DataTable()

        table.Columns.AddIfNeeded("CalcId", GetType(String))
        table.Columns.AddIfNeeded("ResourceClassification", GetType(String))
        For Each calcId In New String() {"F1Factor", "F15Factor"}
            For Each resourceClassification In ResourceContributionReports.ResourceClassificationFieldNames
                Dim row = table.NewRow()
                row("ResourceClassification") = resourceClassification
                row("CalcId") = calcId
                table.Rows.Add(row)
            Next

            F1F2F3ReportEngine.AddResourceClassificationColor(table)
            F1F2F3ReportEngine.AddResourceClassificationDescriptions(table)
        Next

        table.TableName = "Values"
        table.AcceptChanges()
        Return table
    End Function

    <WebMethod>
    Public Function GetBhpbioBlastByBlastReconciliation(blastLocationId As Int32) As DataSet
        Dim result As DataSet
        Dim reportSession As ReportSession = CreateReportSession()

        Try
            result = BlastByBlastReconciliationReport.GetData(reportSession, blastLocationId)
        Finally
            If (reportSession IsNot Nothing) Then
                reportSession.Dispose()
            End If
        End Try

        Return result
    End Function

    <WebMethod>
    Public Function GetBhpbioBlastByBlastReconciliationF1Factor(blastLocationId As Int32) As DataTable
        Dim reportSession As ReportSession = CreateReportSession()
        Dim table As DataTable
        table = BlastByBlastReconciliationReport.GetF1FactorAll(reportSession, blastLocationId)
        table.TableName = "FFactors"
        reportSession.Dispose()
        Return table
    End Function

    <WebMethod>
    Public Function GetBhpbioColourList() As DataTable
        Dim reportSession As ReportSession = CreateReportSession()
        Dim table As DataTable
        table = reportSession.DalUtility.GetBhpbioReportColorList(NullValues.String, True)
        reportSession.Dispose()
        table.TableName = "Colours"
        Return table
    End Function

    <WebMethod>
    Public Function GetBhpbioLocationList(locationId As Integer, startDate As DateTime, endDate As DateTime) As DataTable
        Using reportSession As ReportSession = CreateReportSession()
            Dim table = reportSession.DalUtility.GetBhpbioLocationListWithOverride(locationId, 1, startDate)
            Dim blockCountTable = reportSession.DalUtility.GetBhpbioPitListWithBlockCounts(locationId, startDate, endDate)

            table.TableName = "Locations"
            table.Columns.Add("BlockCount", GetType(Integer))

            ' we use the blockcount data to allow the reports to exclude pits that have no data in a given month
            For Each row As DataRow In table.Rows
                Dim locationRow = row
                Dim blockCount = blockCountTable.AsEnumerable.Where(Function(r) r.AsInt("PitLocationId") = locationRow.AsInt("Location_Id")).Select(Function(r) r.AsInt("BlockCount")).FirstOrDefault()

                row("BlockCount") = blockCount
            Next

            table.AcceptChanges()
            Return table
        End Using
    End Function

    <WebMethod>
    Public Function GetBhpbioQuarterDateBreakdown(dateFrom As DateTime, dateTo As DateTime) As DataTable
        Dim table As New DataTable With {
            .TableName = "QuarterBreakdown"
        }
        table.Columns.Add("DateFrom", GetType(DateTime))
        table.Columns.Add("DateTo", GetType(DateTime))
        table.Columns.Add("CalendarDate", GetType(DateTime))

        Const periodMonths = 3
        Dim currentDate = dateFrom.Date

        While currentDate < dateTo
            Dim row = table.NewRow()
            row("DateFrom") = currentDate
            row("DateTo") = currentDate.AddMonths(periodMonths).AddDays(-1)
            row("CalendarDate") = currentDate
            table.Rows.Add(row)

            currentDate = currentDate.AddMonths(periodMonths)
        End While

        table.AcceptChanges()
        Return table
    End Function

    <WebMethod>
    Public Function ConvertGradesXmlToCsv(xml As String) As String
        Dim result As String
        Dim reportSession As ReportSession = CreateReportSession()

        Try
            result = ReportDisplayParameter.ConvertGradesXmlToCsv(reportSession, xml)
        Finally
            If (reportSession IsNot Nothing) Then
                reportSession.Dispose()
            End If
        End Try

        Return result
    End Function

    <WebMethod>
    Public Function ConvertBlocksModelsAndActualsXmlToCsv(xml As String, includeActuals As Boolean) As String
        Dim result As String
        Dim reportSession As ReportSession = CreateReportSession()

        Try
            result = ReportDisplayParameter.ConvertBlocksModelsAndActualsXmlToCsv(reportSession, xml, includeActuals)
        Finally
            If (reportSession IsNot Nothing) Then
                reportSession.Dispose()
            End If
        End Try

        Return result
    End Function

    <WebMethod>
    Public Function GetLocationComment(locationId As Int32) As String
        Dim result As String
        Dim reportSession As ReportSession = CreateReportSession()

        Try
            result = ReportDisplayParameter.GetLocationComment(reportSession, locationId)
        Finally
            If (reportSession IsNot Nothing) Then
                reportSession.Dispose()
            End If
        End Try

        Return result
    End Function

    <WebMethod>
    Public Function GetProductLocationCommentByDate(productTypeIds As String, startDate As DateTime) As String
        If String.IsNullOrEmpty(productTypeIds) Then
            Return Nothing
        End If

        Dim producttypeList = productTypeIds.Split(","c)
        Dim reportSession As ReportSession = CreateReportSession()
        Dim result = ""

        Try
            For Each prodtype In producttypeList
                reportSession.ProductTypeId = Int32.Parse(prodtype)
                Dim locationId = reportSession.SelectedProductType.LocationId
                If result <> "" Then
                    result = result & "," & ReportDisplayParameter.GetLocationCommentByDate(reportSession, locationId, startDate)
                Else
                    result = ReportDisplayParameter.GetLocationCommentByDate(reportSession, locationId, startDate)
                End If
            Next
        Finally
            If (reportSession IsNot Nothing) Then
                reportSession.Dispose()
            End If
        End Try

        Return result
    End Function

    <WebMethod>
    Public Function GetLocationCommentByDate(locationId As Int32, startDate As DateTime) As String
        If locationId < 0 Then
            Return Nothing
        End If

        Using reportSession As ReportSession = CreateReportSession()
            Return ReportDisplayParameter.GetLocationCommentByDate(reportSession, locationId, startDate)
        End Using
    End Function

    <WebMethod>
    Public Function GetLocationComment2(locationId As Int32) As String
        Using reportSession As ReportSession = CreateReportSession()
            Return ReportDisplayParameter.GetLocationComment2(reportSession, locationId)
        End Using
    End Function

    <WebMethod>
    Public Function GetLocationComment2ByDate(locationId As Int32, startDate As DateTime) As String
        Using reportSession As ReportSession = CreateReportSession()
            Return ReportDisplayParameter.GetLocationComment2ByDate(reportSession, locationId, startDate)
        End Using
    End Function

    <WebMethod>
    Public Function GetLocationDepositComment(locationId As Int32?, depositId As Int32?) As String
        Using reportSession As ReportSession = CreateReportSession()
            Return ReportDisplayParameter.GetLocationDepositComment(reportSession, locationId, depositId)
        End Using
    End Function

    <WebMethod>
    Public Function GetMaterialName(materialTypeId As Int32) As String
        Dim result As String
        Dim reportSession As ReportSession = CreateReportSession()

        Try
            result = ReportDisplayParameter.GetMaterialName(reportSession, materialTypeId)
        Finally
            If (reportSession IsNot Nothing) Then
                reportSession.Dispose()
            End If
        End Try

        Return result
    End Function

    <WebMethod>
    Public Function GetBlockModelActualName(isActual As Boolean, blockModelId As Int32) As String
        Dim result As String
        Dim reportSession As ReportSession = CreateReportSession()

        Try
            result = ReportDisplayParameter.GetBlockModelActualName(reportSession, isActual, blockModelId)
        Finally
            If (reportSession IsNot Nothing) Then
                reportSession.Dispose()
            End If
        End Try

        Return result
    End Function

    <WebMethod>
    Public Function GetNumberFormating(seriesId As Integer) As String
        Dim valueFormat = ""
        Dim reportSession As ReportSession = CreateReportSession()
        Dim attributeTable As DataTable = reportSession.DalApproval.GetBhpbioOutlierAnalysisSeriesAttributes(seriesId)
        attributeTable.TableName = "ValueFormat"

        If attributeTable IsNot Nothing And attributeTable.Rows.Count > 0 Then
            Dim row As DataRow = attributeTable.Rows(0)
            Dim tagId = row.AsString("SeriesTypeId")
            If tagId.Contains("_") Then
                tagId = tagId.Substring(0, tagId.IndexOf("_", StringComparison.Ordinal))
                'If TagID does not contain '_', then it can`t be Factor. so, it will return the default decimal places for the current grade
            End If
            Dim grade = row.AsString("Grade")
            If grade Is Nothing Then
                valueFormat = F1F2F3ReportEngine.GetAttributeValueFormat("Tonnes", tagId)
            Else
                valueFormat = F1F2F3ReportEngine.GetAttributeValueFormat(grade, tagId)
            End If

        End If
        Return valueFormat
    End Function

    <WebMethod>
    Public Function GetOutlierAnalysisChartData(seriesId As Integer, dateFrom As DateTime, dateTo As DateTime) As DataTable
        Dim result As DataTable
        Dim reportSession As ReportSession = CreateReportSession()

        Try
            result = reportSession.DalApproval.GetBhpbioOutlierAnalysisPoints(seriesId, dateFrom, dateTo)
            result.TableName = "PointValues"
        Finally
            If (reportSession IsNot Nothing) Then
                reportSession.Dispose()
            End If
        End Try

        Return result
    End Function

    <WebMethod>
    Public Function GetOutlierAnalysisChartAttributes(seriesId As Integer, dateFrom As DateTime, dateTo As DateTime) As DataTable
        Dim result As DataTable
        Dim reportSession As ReportSession = CreateReportSession()

        Try
            result = New DataTable("Attributes")
            result.Columns.Add("Title", GetType(String))
            result.Columns.Add("SubTitle", GetType(String))
            result.Columns.Add("ProjectionMethod", GetType(String))

            result.Columns.Add("SeriesTypeId", GetType(String))
            result.Columns.Add("IsFactor", GetType(Boolean))

            Dim dataRow As DataRow = result.NewRow()
            Dim attributeTable As DataTable = reportSession.DalApproval.GetBhpbioOutlierAnalysisSeriesAttributes(seriesId)

            If (attributeTable IsNot Nothing And attributeTable.Rows.Count <> 0) Then
                Dim attributeRow As DataRow = attributeTable.Rows()(0)
                Dim title As New StringBuilder()

                title.Append(attributeRow.AsString("LocationType"))
                title.Append(": ")

                If (attributeRow.AsString("LocationType") = "PIT") Then
                    title.Append(attributeRow.AsString("ParentLocationName"))
                    title.Append(" - ")
                End If
                
                title.Append(attributeRow.AsString("LocationName"))

                If (attributeRow.AsString("MaterialType") IsNot Nothing) Then
                    title.Append(", ")
                    title.Append(attributeRow.AsString("MaterialType"))
                End If

                If (attributeRow.AsString("ProductSize") IsNot Nothing) Then
                    title.Append(", ")
                    title.Append(attributeRow.AsString("ProductSize"))
                End If

                If (attributeRow.AsString("Attribute") IsNot Nothing) Then
                    If (attributeRow.AsString("Grade") IsNot Nothing) Then
                        title.Append(", ")
                        title.Append(attributeRow.AsString("Grade"))
                    Else
                        title.Append(", ")
                        If attributeRow.AsString("Attribute") = "Tonnes" Then
                            title.Append("kTonnes")
                        Else
                            title.Append(attributeRow.AsString("Attribute"))
                        End If

                    End If
                End If

                dataRow("Title") = title.ToString()
                dataRow("SubTitle") = attributeRow.AsString("SeriesTypeName")
                dataRow("ProjectionMethod") = attributeRow.AsString("ProjectionMethod")

                ' is the calculation a factor or not? Assume the first part of the serieTypeId is the 
                ' calculationID. This is not 100 %, as not all the outlier series are based on calculations
                ' but it does work most of the time. Generally we just want the calcId to know if the data is
                ' a factor or not, so it doesn't have to be 100 % reliable
                Dim seriesTypeId = attributeRow.AsString("SeriesTypeId")

                If Not String.IsNullOrEmpty(seriesTypeId) Then
                    Dim calculationId = seriesTypeId.Split("_"c).FirstOrDefault().Trim()
                    Dim isFactor = calculationId.EndsWith("Factor") OrElse calculationId.Contains("BeneRatio")

                    dataRow("IsFactor") = isFactor
                    dataRow("SeriesTypeId") = seriesTypeId
                End If

                result.Rows.Add(dataRow)
            End If
        Finally
            If (reportSession IsNot Nothing) Then
                reportSession.Dispose()
            End If
        End Try

        Return result
    End Function

    <WebMethod>
    Public Function ConvertFactorXmlToCsv(xml As String, isForwardEstimate As Boolean) As String
        Try
            Dim resultList = ReportDisplayParameter.GetXmlAsList(xml, "Factor", "id").Cast(Of String)
            resultList = resultList.Select(Function(f)
                                               Select Case f
                                                   Case "F15Factor" : Return "F1.5"
                                                   Case "F25Factor" : Return "F2.5"
                                                   Case Else : Return f.Replace("Factor", "")
                                               End Select
                                           End Function)

            If isForwardEstimate Then
                resultList = resultList.Select(Function(f) f + "f")
            End If

            Return String.Join(", ", resultList.ToArray)
        Catch ex As XmlException
            Return String.Format("Error encountered: {0}", ex.Message)
        End Try
    End Function

    <WebMethod>
    Public Function ConvertXmlToCsv(xml As String, elementId As String, attributeName As String) As String
        Try
            Dim resultList = ReportDisplayParameter.GetXmlAsList(xml, elementId, attributeName)
            Return String.Join(", ", resultList.Cast(Of String).ToArray())
        Catch ex As XmlException
            Return String.Format("Error encountered: {0}", ex.Message)
        End Try
    End Function

    <WebMethod>
    Public Function GetAttributes() As DataTable
        Using reportSession As ReportSession = CreateReportSession()
            Return GradeProperties.GetAttributesTable(reportSession)
        End Using
    End Function

    <WebMethod>
    Public Function GetLocationChanges(locationId As Integer, dateFrom As DateTime, dateTo As DateTime) As DataTable
        Using reportSession As ReportSession = CreateReportSession()
            Dim table As DataTable = reportSession.DalUtility.GetBhpbioLocationListWithOverrideAndDates(locationId, "PIT", dateFrom, dateTo)

            For Each row In table.AsEnumerable.Where(Function(r) r.AsDate("IncludeStart") = dateFrom And r.AsDate("IncludeEnd") = dateTo).ToList
                row.Delete()
            Next
            table.AcceptChanges()
            Return table
        End Using
    End Function

    <WebMethod>
    Public Function GetShippingTargets(producttypeid As Integer, dateTo As DateTime) As DataTable
        Using reportSession As ReportSession = CreateReportSession()
            Dim table = reportSession.DalShippingTarget.GetBhpbioShippingTargets(producttypeid, dateTo)
            table.TableName = "Values"
            Return table
        End Using
    End Function

    <WebMethod>
    Public Function GetFAttributes(locationId As Int32) As DataTable
        Using reportSession As ReportSession = CreateReportSession()
            Return GradeProperties.GetFAttributeProperties(reportSession, locationId)
        End Using
    End Function

    ' Methods for Core Reports
    <WebMethod>
    Public Function GetPotentialReportDataExceptions() As DataTable
        Using reportSession As ReportSession = CreateReportSession()
            Dim table = reportSession.DalReport.GetPotentialReportDataExceptions()
            table.TableName = "PotentialReportDataExceptions"
            Return table
        End Using
    End Function

    <WebMethod>
    Public Function GetBhpbioHaulageVsPlantReport(locationId As Int32?, fromDate As DateTime?, toDate As DateTime?) As DataTable
        Dim reportSession As ReportSession = CreateReportSession()
        Dim table As DataTable
        table = reportSession.DalReport.GetBhpbioHaulageVsPlantReport(locationId, fromDate, toDate)
        reportSession.Dispose()
        table.TableName = "GetBhpbioHaulageVsPlantReport"
        Return table
    End Function

    <WebMethod>
    Public Function GetBhpbioStockpileBalanceReport(locationId As Int32?, stockpileId As Int32?, startDate As DateTime?, startShift As Char?,
                                                    endDate As DateTime?, endShift As Char?, isVisible As Boolean?) As DataTable
        Dim reportSession As ReportSession = CreateReportSession()
        Dim table As DataTable
        table = reportSession.DalReport.GetBhpbioStockpileBalanceReport(locationId, stockpileId, startDate, startShift, endDate, endShift, isVisible)
        reportSession.Dispose()
        table.TableName = "GetBhpbioStockpileBalanceReport"
        Return table
    End Function

    <WebMethod>
    Public Function GetBhpbioF1F2F3OverviewReconReport(locationId As Int32?, dateFrom As String, dateTo As String, dateBreakdown As String,
                                                       lumpFinesBreakdown As Boolean, f25Required As Boolean, reportContext As String) As DataTable

        Dim data As DataTable = Nothing
        Dim reportSession As ReportSession = CreateReportSession()
        reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown
        reportSession.Context = GetReportContext(reportContext)

        If ((dateFrom IsNot Nothing) And (dateTo IsNot Nothing) And (dateBreakdown IsNot Nothing)) Then
            data = F1F2F3OverviewReconciliationReport.GetData(
            reportSession, locationId, Convert.ToDateTime(dateFrom), Convert.ToDateTime(dateTo),
            ReportSession.ConvertReportBreakdown(dateBreakdown), f25Required)
            data.AcceptChanges()

            reportSession.Dispose()
        End If

        Return data
    End Function

    <WebMethod>
    Public Function GetBhpbioF1F2F3OverviewReconContributionReport(productTypeId As Integer, locationId As Int32?, dateFrom As String, dateTo As String,
                                                                   dateBreakdown As String, lumpFinesBreakdown As Boolean, f25Required As Boolean,
                                                                   reportContext As String) As DataTable

        Using reportSession As ReportSession = CreateReportSession()
            reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown
            reportSession.Context = GetReportContext(reportContext)

            If productTypeId > 0 Then
                reportSession.ProductTypeId = productTypeId
                locationId = reportSession.SelectedProductType.LocationId
            End If

            If ((dateFrom IsNot Nothing) And (dateTo IsNot Nothing) And (dateBreakdown IsNot Nothing)) Then

                Dim data As DataTable = F1F2F3OverviewReconciliationReport.GetContributionData(
                    reportSession, locationId, Convert.ToDateTime(dateFrom), Convert.ToDateTime(dateTo),
                    ReportSession.ConvertReportBreakdown(dateBreakdown), f25Required)

                data.AcceptChanges()
                Return data
            Else
                Throw New Exception("Missing required arguments")
            End If
        End Using
    End Function

    <WebMethod>
    Public Function GetBhpbioLiveVersusSummaryReport(locationId As Int32?, dateFrom As String, dateTo As String, dateBreakdown As String) As DataTable
        Dim data As DataTable = Nothing
        Dim liveSession As ReportSession = CreateReportSession()

        liveSession.Context = ReportContext.LiveOnly
        liveSession.IncludeProductSizeBreakdown = True
        liveSession.AllowActualMinedVisible = True
        liveSession.ExplicitlyIncludeExtendedH2OModelCalculations = False
        liveSession.IncludeAsShippedModelsInHubSet = True
        ' Include the Recovery Factor which is normally not required for factor calculations
        liveSession.OptionalCalculationTypesToInclude.Add(CalcType.RecoveryFactorMoisture)
        liveSession.OptionalCalculationTypesToInclude.Add(CalcType.RecoveryFactorDensity)

        Dim summarySession As ReportSession = CreateReportSession()
        summarySession.Context = ReportContext.Standard
        summarySession.IncludeProductSizeBreakdown = True
        summarySession.AllowActualMinedVisible = True
        summarySession.ExplicitlyIncludeExtendedH2OModelCalculations = False
        summarySession.IncludeAsShippedModelsInHubSet = True
        ' Include the Recovery Factor which is normally not required for factor calculations
        summarySession.OptionalCalculationTypesToInclude.Add(CalcType.RecoveryFactorMoisture)
        summarySession.OptionalCalculationTypesToInclude.Add(CalcType.RecoveryFactorDensity)

        If ((dateFrom IsNot Nothing) And (dateTo IsNot Nothing) And (dateBreakdown IsNot Nothing)) Then
            data = LiveVersusSummaryComparisonReport.GetData(liveSession, summarySession, locationId, Convert.ToDateTime(dateFrom), Convert.ToDateTime(dateTo),
                                                             ReportSession.ConvertReportBreakdown(dateBreakdown))
            data.AcceptChanges()

            liveSession.Dispose()
            summarySession.Dispose()
        End If

        Return data
    End Function

    <WebMethod>
    Public Function GetBhpbioF1F2F3OverviewReconReport2(locationId As Int32, dateFrom As String, dateTo As String, dateBreakdown As String,
                                                        lumpFinesBreakdown As Boolean, f25Required As Boolean) As DataTable

        Dim data As DataTable = Nothing
        Dim reportSession As ReportSession = CreateReportSession()
        reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown

        If ((dateFrom IsNot Nothing) And (dateTo IsNot Nothing) And (dateBreakdown IsNot Nothing)) Then
            data = F1F2F3OverviewReconciliationReport.GetData(
            reportSession, locationId, Convert.ToDateTime(dateFrom), Convert.ToDateTime(dateTo),
            ReportSession.ConvertReportBreakdown(dateBreakdown), f25Required)
            data.AcceptChanges()

            reportSession.Dispose()
        End If

        Return data
    End Function

    <WebMethod>
    Public Function GetBhpbioFactorsVsTimeProductReport(productTypeIds As String, locationId As Int32, dateFrom As DateTime, dateTo As DateTime,
                                                        factors As String, attributes As String, dateBreakdown As String, reportContext As String) As DataTable

        Dim breakdown = dateBreakdown.ToReportBreakdown()
        Dim attributeList = attributes.Split(","c).Select(Function(c) c.Trim).ToArray
        Dim factorList = factors.Split(","c).Select(Function(c) c.Trim + "Factor").ToArray
        Dim productTypeList = productTypeIds.Split(","c).Select(Function(p) Convert.ToInt32(p)).ToArray

        Dim data As DataTable = Nothing

        For Each productTypeId In productTypeList
            Using reportSession As ReportSession = CreateReportSession()
                reportSession.ProductTypeId = productTypeId
                reportSession.Context = GetReportContext(reportContext)

                Dim report = New ShippingTargetsReport() With {
                    .IncludeChildLocations = False
                }
                Dim productTypeTable As DataTable = report.GetShippingData(reportSession, productTypeId, dateFrom, dateTo, attributeList, factorList, breakdown)

                If data Is Nothing Then
                    data = productTypeTable
                Else
                    data.Merge(productTypeTable)
                End If
            End Using
        Next

        data.AcceptChanges()
        Return data
    End Function

    <WebMethod>
    Public Function GetBhpbioFactorsVsTimeReport(reportType As FactorsVsTimeReportSubType, locationId As Int32, dateFrom As String, dateTo As String,
                                                 dateBreakdown As String, attributes As String, factors As String, lumpFinesBreakdown As Boolean,
                                                 designationMaterialTypeId As Integer, productTypeIds As String) As DataTable

        Dim fullAttributes As String
        Dim recoveryFactorName As String = String.Empty
        Dim recoveryFactorAttributeName As String = String.Empty

        Select Case reportType
            Case FactorsVsTimeReportSubType.Moisture
                fullAttributes = attributes + ",H2O"
                recoveryFactorName = "RecoveryFactorMoisture"
                recoveryFactorAttributeName = "H2O"
            Case FactorsVsTimeReportSubType.Density
                fullAttributes = attributes + ",Density"
                recoveryFactorName = "RecoveryFactorDensity"
                recoveryFactorAttributeName = "Density"
            Case FactorsVsTimeReportSubType.Volume
                fullAttributes = attributes + ",Volume"
            Case FactorsVsTimeReportSubType.Product
                fullAttributes = attributes
            Case Else
                Throw New ArgumentException("Report type not supported.")
        End Select

        Dim includeMaterialTypes = False

        If reportType = FactorsVsTimeReportSubType.Density Then
            includeMaterialTypes = True
        End If

        Dim reportSession As ReportSession = CreateReportSession()
        reportSession.IncludeProductSizeBreakdown = lumpFinesBreakdown

        Dim gradeDictionary As Dictionary(Of String, Grade) = reportSession.DalUtility.GetGradeObjectsList(NullValues.Int16,
                                                                                                           Application("NumericFormat").ToString)
        Dim data As DataTable = F1F2F3ReconciliationByAttributeReport.GetData(reportSession, locationId, Convert.ToDateTime(dateFrom),
                                                                              Convert.ToDateTime(dateTo), ReportSession.ConvertReportBreakdown(dateBreakdown),
                                                                              ConvertAttributeCsvToXml(fullAttributes, gradeDictionary),
                                                                              ConvertFactorCsvToXml(factors), True, includeMaterialTypes,
                                                                              designationMaterialTypeId)

        If reportType = FactorsVsTimeReportSubType.Density Then
            Dim deleteList As New ArrayList

            For Each row As DataRow In data.Rows
                Dim reportTagId = row("ReportTagId").ToString()
                If (reportTagId = recoveryFactorName Or reportTagId = "F2DensityFactor") AndAlso row("Attribute").ToString <> recoveryFactorAttributeName Then
                    deleteList.Add(row)
                End If
            Next

            For Each row As DataRow In deleteList
                row.Table.Rows.Remove(row)
            Next
        End If

        AddSupportingTableDescription(data, lumpFinesBreakdown, includeMaterialTypes And designationMaterialTypeId = 0)

        data.AcceptChanges()
        reportSession.Dispose()
        Return data
    End Function

    <WebMethod>
    Public Function GetBhpbioFactorsVsTimeReportResourceClassification(locationId As Int32, locationGroupId As Int32?, dateFrom As DateTime, dateTo As DateTime,
                                                                       dateBreakdown As String, attributes As String, factor As String,
                                                                       resourceClassifications As String, reportContext As String) As DataTable

        ' Set Override - the override is used when set during CreateReportSession
        Select Case reportContext.ToUpper
            Case "LIVE", "LIVEONLY" : SetOverrideReportContext(Types.ReportContext.LiveOnly)
            Case "APPROVED", "STANDARD" : SetOverrideReportContext(Types.ReportContext.Standard)
            Case "COMBINED", "APPROVALLISTING" : SetOverrideReportContext(Types.ReportContext.ApprovalListing)
        End Select

        ' Create the session
        Using reportSession As ReportSession = CreateReportSession()
            Dim attributeList = GetAttributeListFromString(attributes)
            Dim resourceClassificationList = GetResourceClassificationListFromString(resourceClassifications)
            Dim dateBreakdownEnum = ReportSession.ConvertReportBreakdown(dateBreakdown)

            Dim table = FactorsVsTimeReportResourceClassification.GetData(reportSession, locationId, locationGroupId, dateBreakdownEnum, dateFrom, dateTo,
                                                                          factor, attributeList.ToArray, resourceClassificationList.ToArray)
            table.TableName = "Values"
            table.AcceptChanges()
            Return table
        End Using
    End Function

    Private Function GetResourceClassificationListFromString(resourceClassification As String) As List(Of String)
        Dim resourceClassificationCsv As String

        If String.IsNullOrEmpty(resourceClassification) Then
            Throw New ArgumentNullException("resourceClassification")
        End If

        If resourceClassification.ToLower.StartsWith("<resourceClassification>") Then
            resourceClassificationCsv = ConvertXmlToCsv(resourceClassification, "ResourceClassification", "name")
        Else
            resourceClassificationCsv = resourceClassification
        End If

        Return resourceClassificationCsv.Split(","c).Select(Function(c) c.Trim).ToList
    End Function

    <WebMethod>
    Public Function GetBhpbioDensityReconciliationReport(locationId As Int32, dateFrom As DateTime, dateTo As DateTime,
                                                         breakdownDensityByDesignation As Boolean, isSupportingDetailsData As Boolean) As DataTable

        Dim result As DataTable
        Dim reportSession As ReportSession = CreateReportSession()

        Try
            If isSupportingDetailsData Then
                result = DensityReconciliationReport.GetSupportingDetailsData(reportSession, locationId, dateFrom, dateTo, breakdownDensityByDesignation)
            Else
                result = DensityReconciliationReport.GetFactorData(reportSession, locationId, dateFrom, dateTo, breakdownDensityByDesignation)
            End If

            result.AcceptChanges()
            reportSession.Dispose()
            Return result

        Finally
            If (reportSession IsNot Nothing) Then
                reportSession.Dispose()
            End If
        End Try
    End Function

    <WebMethod>
    Public Function GetBhpbioDensityAnalysisReport(locationId As Int32, dateFrom As DateTime, dateTo As DateTime, sources As String) As DataTable
        Dim sourceList As New List(Of String)

        For Each source In sources.Split(","c)
            Dim result As String = source

            Select Case source
                Case "F1", "F15", "F2Density" : result = source + "Factor"
                Case "RFD" : result = "RecoveryFactorDensity"
            End Select

            sourceList.Add(result)
        Next

        Using reportSession As ReportSession = CreateReportSession()
            Dim result As DataTable
            result = DensityAnalysisReport.GetSupportingDetailsData(reportSession, locationId, dateFrom, dateTo, sourceList.ToArray)
            result.AcceptChanges()
            Return result
        End Using
    End Function

    <WebMethod>
    Public Function GetBhpbioSampleCoverageReport(locationId As Int32, dateFrom As DateTime, dateTo As DateTime, groupBy As String) As DataTable
        Dim result As DataTable
        Using reportSession As ReportSession = CreateReportSession()
            result = SampleCoverageReport.GetData(reportSession, locationId, dateFrom, dateTo, groupBy)
            result.AcceptChanges()
            Return result
        End Using
    End Function

    <WebMethod>
    Public Function GetErrorContributionDataForSubLocations(locationId As Int32, dateFrom As DateTime, dateTo As DateTime, locationBreakdown As Integer,
                                                            attributes As String, factors As String, reportContext As String,
                                                            forwardLookingError As Boolean) As DataTable

        Dim attributeList = GetAttributeListFromString(attributes)
        Dim factorList = GetSourceListFromString(factors)

        ' we take 1 from the passed in breakdown id, because we are getting the data with children. This means that to
        ' get benches we only need to run the queries for pits, and the procs will break down to the lower location
        Dim locationTypeList = GetLocationTypeList()
        Dim breakdownLocationTypeId = locationBreakdown - 1
        Dim breakdownLocationType = locationTypeList(breakdownLocationTypeId)

        Using reportSession As ReportSession = CreateReportSession()
            reportSession.RethrowCalculationSetErrors = True
            reportSession.Context = GetReportContext(reportContext)

            If forwardLookingError Then
                reportSession.Context = Types.ReportContext.LiveOnly
                reportSession.ForwardModelFactorCalculation = True
                reportSession.OverrideModelDataLocationTypeBreakdown = locationTypeList(locationBreakdown)
            End If

            ' when doing to forward looking error contribution, we can do a quicker method of calling the procs
            ' by passing the location breakdown directly to the proc, so we do that if possible, but it is only
            ' possible when the parent location is above the Bench level
            Dim parentLocationTypeId = reportSession.GetLocationTypeId(locationId)

            ' When thebreakdown is at the lowest level, and the parent location is not the next level up, we want to
            ' set the breakdown override to speed up the query. Actually we could use this override all the time, but
            ' it needs too much refactoring of the original code to do this, and the testing is already mostly complete
            If breakdownLocationType = "Bench" AndAlso parentLocationTypeId < breakdownLocationTypeId Then
                breakdownLocationType = "Pit"
                reportSession.OverrideModelDataLocationTypeBreakdown = locationTypeList(locationBreakdown)
            End If

            Dim result = ResourceContributionReports.GetErrorContextContributionReportData(reportSession, locationId, dateFrom, dateTo, breakdownLocationType,
                                                                                           attributeList.ToArray, factorList.ToArray)

            result.AddLabelColor()
            result.TableName = "Values"
            result.AcceptChanges()
            Return result
        End Using
    End Function

    <WebMethod>
    Public Function GetResourceClassificationReportDataByLocation(locationId As Int32, dateFrom As DateTime, dateTo As DateTime, locationBreakdown As Integer,
                                                                  attributes As String, reportContext As String, forwardLookingError As Boolean) As DataTable

        Dim attributeList = GetAttributeListFromString(attributes)

        ' we take 1 from the passed in breakdown id, because we are getting the data with children. This means that to
        ' get benches we only need to run the queries for pits, and the procs will breakdown to the lower location
        Dim locationTypeList = GetLocationTypeList()
        Dim breakdownLocationTypeId = locationBreakdown - 1
        Dim breakdownLocationType = locationTypeList(breakdownLocationTypeId)

        Using reportSession As ReportSession = CreateReportSession()
            reportSession.RethrowCalculationSetErrors = True
            reportSession.Context = GetReportContext(reportContext)

            If forwardLookingError Then
                reportSession.Context = Types.ReportContext.LiveOnly
                reportSession.ForwardModelFactorCalculation = True
                reportSession.OverrideModelDataLocationTypeBreakdown = locationTypeList(locationBreakdown)
            End If

            ' when doing to forward looking error contribution, we can do a quicker method of calling the procs
            ' by passing the location breakdown directly to the proc, so we do that if possible, but it is only
            ' possible when the parent location is above the Bench level
            Dim parentLocationTypeId = reportSession.GetLocationTypeId(locationId)

            ' When thebreakdown is at the lowest level, and the parent location is not the next level up, we want to
            ' set the breakdown override to speed up the query. Actually we could use this override all the time, but
            ' it needs too much refactoring of the original code to do this, and the testing is already mostly complete
            If breakdownLocationType = "Bench" AndAlso parentLocationTypeId < breakdownLocationTypeId Then
                breakdownLocationType = "Pit"
                reportSession.OverrideModelDataLocationTypeBreakdown = locationTypeList(locationBreakdown)
            End If

            Dim result = ResourceContributionReports.GetResourceContextReportData(reportSession, locationId, dateFrom, dateTo, breakdownLocationType,
                                                                                  attributeList.ToArray)

            result.TableName = "Values"
            result.AcceptChanges()
            Return result
        End Using
    End Function

    ' returns a list of location type names indexed by id. Yes this should really come from the 
    ' database, but these are so unlikely to ever change that I am ok with this shortcut
    Public Function GetLocationTypeList() As Dictionary(Of Integer, String)
        Return New Dictionary(Of Integer, String) From {
            {1, "Company"},
            {2, "Hub"},
            {3, "Site"},
            {4, "Pit"},
            {5, "Bench"},
            {6, "Blast"},
            {7, "Block"}
        }
    End Function

    ' somtimes this is called the factor list as well.
    ' this will convert either an xml list of sources, or a comma separated list into a List<string>
    Public Function GetSourceListFromString(factors As String) As List(Of String)
        Dim factorsCsv As String

        ' some of the names are different in the csv - the factors use a short version of their name for some
        ' reason, so we need to detect this and convert them
        Dim shortFactorNames = New String() {"F1", "F15", "F2", "F25", "F3"}

        If String.IsNullOrEmpty(factors) Then
            Throw New ArgumentNullException("factors")
        End If

        If factors.ToLower.StartsWith("<factors>") Then
            factorsCsv = ConvertXmlToCsv(factors, "Factor", "id")
        Else
            factorsCsv = factors
        End If

        Return factorsCsv.Split(","c).
            Select(Function(c) c.Trim).
            Select(Function(c) If(shortFactorNames.Contains(c), c + "Factor", c)).
            ToList
    End Function

    ' this will handle both the xml and csv based formats
    Public Function GetAttributeListFromString(attributes As String) As List(Of String)
        Dim attributesCsv As String

        If String.IsNullOrEmpty(attributes) Then
            Throw New ArgumentNullException("attributes")
        End If

        If attributes.ToLower.StartsWith("<attributes>") Then
            attributesCsv = ConvertXmlToCsv(attributes, "Attribute", "name")
        Else
            attributesCsv = attributes
        End If

        Return attributesCsv.Split(","c).Select(Function(c) c.Trim).ToList
    End Function

    Public Function GetBlastblockDataExportReport(locationId As Int32, dateFrom As DateTime, dateTo As DateTime) As DataTable
        Using reportSession As ReportSession = CreateReportSession()
            Dim data As DataTable = BlastByBlastReconciliationReport.GetBlastblockDataExportReport(reportSession, locationId, dateFrom, dateTo)
            data.AcceptChanges()
            Return data
        End Using
    End Function

    ''' <summary>
    ''' Method used to obtain additional colours needed by the RiskProfileReport
    ''' </summary>
    ''' <returns>A data table containing a single row with a column per required colour</returns>
    <WebMethod>
    Public Function GetRiskProfileReportColours() As DataTable
        Dim dt As New DataTable With {
            .TableName = "Values"
        }

        dt.Columns.Add("BlockedOutRemainGCColour", GetType(String))
        dt.Columns.Add("AnnualisedMPRColour", GetType(String))
        dt.Columns.Add("LastMonthProductionColour", GetType(String))


        Dim dr As DataRow = dt.NewRow()
        dt.Rows.Add(dr)

        Using reportSession As ReportSession = CreateReportSession()
            Dim colTable As DataTable = reportSession.DalUtility.GetBhpbioReportColorList("BlockedOutRemainGC", True)
            If (colTable.Rows.Count > 0) Then
                dr("BlockedOutRemainGCColour") = colTable.AsEnumerable.First().AsString("Color")
            End If

            colTable = reportSession.DalUtility.GetBhpbioReportColorList("AnnualisedMPR", True)
            If (colTable.Rows.Count > 0) Then
                dr("AnnualisedMPRColour") = colTable.AsEnumerable.First().AsString("Color")
            End If

            colTable = reportSession.DalUtility.GetBhpbioReportColorList("GradeControlModel", True)
            If (colTable.Rows.Count > 0) Then
                dr("LastMonthProductionColour") = colTable.AsEnumerable.First().AsString("Color")
            End If
        End Using

        Return dt
    End Function

    <WebMethod>
    Public Function GetPowerPointContentSelection(locationId As Int32, dateBreakdown As String, periodStart As DateTime, factorOption As String,
                                                  selectionMode As String) As DataTable

        Dim dataTable As DataTable
        Using reportSession As ReportSession = CreateReportSession()
            Dim gradeDictionary As Dictionary(Of String, Grade) = reportSession.DalUtility.GetGradeObjectsList(NullValues.Int16,
                                                                                                               Application("NumericFormat").ToString)
            Dim acsm As IAutomaticContentSelectionMode
            Dim locationName As String = reportSession.GetLocationName(locationId)
            Dim useCsvFile = False

            Dim dateBreakdownEnum As ReportBreakdown

            If dateBreakdown = Nothing Then
                dateBreakdown = String.Empty
            End If

            Select Case dateBreakdown.ToUpper()
                Case ReportBreakdown.CalendarQuarter.ToString().ToUpper()
                Case "QUARTER"
                    dateBreakdownEnum = ReportBreakdown.CalendarQuarter
                Case ReportBreakdown.Monthly.ToString().ToUpper()
                Case "MONTH"
                    dateBreakdownEnum = ReportBreakdown.Monthly
                Case Else
                    Throw New InvalidEnumArgumentException(String.Format("dateBreakdown must be {0} or {1}", ReportBreakdown.Monthly,
                                                                         ReportBreakdown.CalendarQuarter))
            End Select

            If (ConfigurationManager.AppSettings.AllKeys.Contains(USE_CSV_OVERRIDE_FILE_FOR_GETPOWERPOINTCONTENTSELECTION)) Then
                Dim stringvalue = ConfigurationManager.AppSettings(USE_CSV_OVERRIDE_FILE_FOR_GETPOWERPOINTCONTENTSELECTION)
                Boolean.TryParse(stringvalue, useCsvFile)
            End If

            If (useCsvFile) Then
                Dim rootPath = HostingEnvironment.MapPath("~")
                acsm = New AutomaticContentSelectionModeFile(gradeDictionary, rootPath)
            Else

                Dim maximumContributors As Integer
                If Not Integer.TryParse(reportSession.DalUtility.GetSystemSetting("BHPBIO_AUTOMATIC_CONTENT_SELECTION_MAXIMUM_CONTRIBUTORS"),
                                        maximumContributors) Then
                    maximumContributors = 50
                End If

                Dim mininumErrorContribution As Double

                If Not Double.TryParse(reportSession.DalUtility.GetSystemSetting("BHPBIO_AUTOMATIC_CONTENT_SELECTION_MINIMUM_ERROR_CONTRIBUTION"),
                                       mininumErrorContribution) Then
                    mininumErrorContribution = 0.1
                End If

                Dim combinationOfInterestIdentifier As ICombinationOfInterestIdentifier = New CombinationOfInterestIdentifier(reportSession,
                                                                                                                              maximumContributors,
                                                                                                                              mininumErrorContribution)
                acsm = New AutomaticContentSelectionMode(gradeDictionary, reportSession.DalUtility, combinationOfInterestIdentifier)
            End If

            dataTable = acsm.GetDataTable(locationId, locationName, dateBreakdownEnum, periodStart, factorOption, selectionMode)

        End Using

        Return dataTable
    End Function

    <WebMethod>
    Public Function GetRiskProfileReport(locationId As Int32, atDate As DateTime, factor As String, locationBreakdown As Integer) As DataTable
        Dim locationTypeList = GetLocationTypeList()
        Dim breakdownLocationType = locationTypeList(locationBreakdown)

        Using reportSession As ReportSession = CreateReportSession()
            reportSession.Context = ReportContext.LiveOnly

            Dim data As DataTable = RiskProfilereport.GetData(reportSession, locationId, atDate, breakdownLocationType, factor)
            data.AcceptChanges()
            Return data
        End Using
    End Function

    Public Function GetBlastblockByOretypeDataExportReport(locationId As Int32, dateFrom As DateTime, dateTo As DateTime,
                                                           includeLumpFines As Boolean) As DataTable

        Using reportSession As ReportSession = CreateReportSession()
            Dim data As DataTable = BlastByBlastReconciliationReport.GetBlastblockbyOreTypeDataExportReport(reportSession, locationId, dateFrom, dateTo,
                                                                                                            includeLumpFines)
            data.AcceptChanges()
            Return data
        End Using
    End Function

    Private Shared Function ConvertFactorCsvToXml(csvList As String) As String
        Dim factorArray As String() = csvList.Split(CChar(","))

        Dim returnVal = New StringBuilder("<Factors>")

        For Each val As String In factorArray
            Select Case val
                Case "RFD"
                    returnVal.Append("<Factor id=""RecoveryFactorDensity""/>")
                Case "RFM"
                    returnVal.Append("<Factor id=""RecoveryFactorMoisture""/>")
                Case Else
                    returnVal.Append(String.Format("<Factor id=""{0}Factor""/>", val))
            End Select
        Next

        returnVal.Append("</Factors>")
        Return returnVal.ToString
    End Function

    Private Shared Sub AddSupportingTableDescription(ByRef data As DataTable, lumpFinesBreakdown As Boolean, Optional ByVal isAllMaterials As Boolean = False)
        data.Columns.Add("SupportingTableDesc", GetType(String))

        Dim description As String
        For Each row As DataRow In data.Rows
            Dim reportTagId As String = row("ReportTagId").ToString

            Select Case reportTagId
                Case "RecoveryFactorDensity", "RecoveryFactorMoisture"
                    description = "RF"
                Case Else
                    description = row("Description").ToString.Split("-"c).FirstOrDefault()
            End Select

            If isAllMaterials Then
                description += "*"
            End If

            row("SupportingTableDesc") = IIf(lumpFinesBreakdown, String.Format("{0} : {1}", description, row("ProductSize")), description)
        Next
    End Sub
End Class

Module ReportingExtensions
    <Extension>
    Public Function ToReportBreakdown(s As String) As ReportBreakdown
        If s Is Nothing Then
            Throw New ArgumentNullException("s")
        End If

        Dim breakdown = s.ToUpper

        Select Case breakdown
            Case "MONTH", "MONTHLY"
                Return ReportBreakdown.Monthly
            Case "QUARTER", "QUARTERLY"
                Return ReportBreakdown.CalendarQuarter
            Case "YEAR", "YEARLY"
                Return ReportBreakdown.Yearly
            Case "NONE"
                Return ReportBreakdown.None
            Case Else
                Throw New Exception("Unsupported Date breakdown: " + breakdown)
        End Select
    End Function
End Module