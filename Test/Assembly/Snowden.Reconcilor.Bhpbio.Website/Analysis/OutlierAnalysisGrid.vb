Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions.GenericDataTableExtensions

Namespace Analysis
    Public Class OutlierAnalysisGrid
        Inherits Core.WebDevelopment.WebpageTemplates.AnalysisAjaxTemplate
        Private Property ReturnTable As ReconcilorTable

        Private _dateFormat As String = Nothing

        Protected Property DalUtility As IUtility

        Private Property AnalysisGroupId As String = Nothing

        Private Property MonthStart As DateTime

        Private Property LimitSubLocationOnly As Boolean = False

        Private Property MonthEnd As DateTime

        Private Property ProductSize As String = Nothing

        Private Property Attribute As String = Nothing

        Protected Property LocationId As Integer = Nothing

        Protected Property Deviation As Decimal = Nothing

        Public Property LayoutTable As HtmlTableTag = New HtmlTableTag

        Protected Property DalApproval As IApproval

        Protected ReadOnly Property DateFormatString As String
            Get
                If _dateFormat Is Nothing Then
                    _dateFormat = Application("DateFormat").ToString

                    If String.IsNullOrEmpty(_dateFormat) Then
                        _dateFormat = "dd-MMM-yyyy"
                    End If
                End If

                Return _dateFormat
            End Get
        End Property

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            LocationId = ConvertValue(Of Integer)(RequestAsString("location"))
            AnalysisGroupId = ConvertValue(Of String)(RequestAsString("AnalysisGroup"))
            ProductSize = ConvertValue(Of String)(RequestAsString("productTypeProductSize"))
            Attribute = ConvertValue(Of String)(RequestAsString("AttributeFilter"))
            Deviation = ConvertValue(Of Decimal)(RequestAsString("deviations"))
            LimitSubLocationOnly = RequestAsBoolean("limitSubLocationOnly")

            If Not Date.TryParse(RequestAsString("MonthValueStart"), MonthStart) Then
                MonthStart = New Date(Date.Now.Year, Date.Now.Month, 1)
            End If

            If Not Date.TryParse(RequestAsString("MonthValueEnd"), MonthEnd) Then
                MonthEnd = MonthStart.AddMonths(1).AddDays(-1)
            End If

            'TODO: find a better way to save settings. Do not save settings if grid is called from most notable outliers (approval) screen.
            'todo: save settings is grid is called from analysis screen 
            If Attribute <> Nothing Then
                SetSettings()
            End If

        End Sub
        Private Sub SetSettings()
            Resources.UserSecurity.SetSetting("AnalysisOutlier_LocationId", LocationId.ToString())
            Resources.UserSecurity.SetSetting("AnalysisOutlier_AnalysisGroup", If(AnalysisGroupId = "All" Or String.IsNullOrEmpty(AnalysisGroupId), Nothing, AnalysisGroupId))
            Resources.UserSecurity.SetSetting("AnalysisOutlier_productTypeProductSize", ProductSize.ToString())
            Resources.UserSecurity.SetSetting("AnalysisOutlier_AttributeFilter", Attribute)
            Resources.UserSecurity.SetSetting("AnalysisOutlier_deviations", Deviation.ToString())
            Resources.UserSecurity.SetSetting("AnalysisOutlier_MonthValueStart", MonthStart.ToString())
            Resources.UserSecurity.SetSetting("AnalysisOutlier_MonthValueEnd", MonthEnd.ToString())
        End Sub

        Private Shared Function ConvertValue(Of T)(value As String) As T
            If Not String.IsNullOrEmpty(value) Then
                Return DirectCast(Convert.ChangeType(value, GetType(T)), T)
            Else
                Return Nothing
            End If
        End Function

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                SetupFormControls()
                Controls.Add(LayoutTable)
            Catch ex As Exception
                JavaScriptAlert(ex.Message)
            End Try

        End Sub

        Protected Overridable Sub SetupFormControls()

            Dim dt As DataTable = DalApproval.GetBhpbioOutliersForLocation(
                If(AnalysisGroupId = "All", Nothing, AnalysisGroupId),
                MonthStart, MonthEnd, LocationId,
                If(ProductSize = "All", Nothing, ProductSize),
                If(Attribute = "All", Nothing, Attribute),
                Deviation,
                True, Not LimitSubLocationOnly, excludeTotalMaterialDuplicates:=True)

            If Not dt.Columns.Contains("Chart") Then
                dt.Columns.Add("Chart", GetType(String))
            End If

            ' always generate the report to the last complete month
            Dim currentDate As Date = Date.Now
            Dim monthTo = currentDate.AddMonths(-1)
            Dim dateTo As Date = New DateTime(monthTo.Year, monthTo.Month, 1)
            Dim dateFrom As Date = Convert.ToDateTime(DalUtility.GetSystemSetting("SYSTEM_START_DATE"))

            Dim reportId = 48

            For Each dr As DataRow In dt.Rows
                Dim chartUrl = String.Format("../Reports/ReportsRun.aspx?ReportId={3}&SeriesId={0}&DateFrom={4}&DateTo={1}&DateHighlight={2}&ExportFormat=11", dr.AsString("SeriesId"), dateTo.ToString("yyyy-MM-dd"), dr.AsDate("month").ToString("yyyy-MM-dd"), reportId, dateFrom.ToString("yyyy-MM-dd"))
                dr("Chart") = String.Format("<a href='{0}' target='_blank'><img src='../images/outlieranalysischart.png'></a>", chartUrl)
            Next

            ' Gets only 25 first rows if comes from the Approval page
            If Attribute = Nothing AndAlso dt.Rows.Count > 0 Then
                'checks if its from the Approval page and if the source datatable has rows. We need a better way to check this
                dt = dt.AsEnumerable().Take(25).CopyToDataTable()
            End If

            Dim usecolumns() As String = {
                "SeriesTypeName", "Month", "LocationType",
                "LocationName", "ProductSize", "Attribute",
                "MaterialTypeAbbreviation", "SeriesSD",
                "ProjectedValue", "Value", "DeviationInSD",
                "Priority", "Chart"
            }

            ReturnTable = New ReconcilorTable(dt)

            With ReturnTable

                .ItemDataBoundCallback = AddressOf ItemDataBoundCallbackEventHandler
                .Columns.Add("SeriesTypeName", New ReconcilorTableColumn("Series Type"))
                .Columns.Add("Month", New ReconcilorTableColumn("Month"))
                .Columns("Month").DateTimeFormat = Me.DateFormatString
                .Columns.Add("LocationType", New ReconcilorTableColumn("Location " & vbCrLf & "Type"))
                .Columns.Add("LocationName", New ReconcilorTableColumn("Location"))
                .Columns.Add("ProductSize", New ReconcilorTableColumn("Product" & vbCrLf & " Size"))
                .Columns.Add("Attribute", New ReconcilorTableColumn("Attribute"))
                .Columns.Add("MaterialTypeAbbreviation", New ReconcilorTableColumn("Material" & vbCrLf & " Type"))
                .Columns.Add("SeriesSD", New ReconcilorTableColumn("Standard" & vbCrLf & " Deviation(SD)"))
                .Columns.Add("ProjectedValue", New ReconcilorTableColumn("Projected" & vbCrLf & " Value"))
                .Columns.Add("Value", New ReconcilorTableColumn("Value"))
                .Columns.Add("DeviationInSD", New ReconcilorTableColumn("Difference " & vbCrLf & " in SD"))
                .Columns.Add("Priority", New ReconcilorTableColumn("Series " & vbCrLf & " Priority"))
                .Columns.Add("Chart", New ReconcilorTableColumn(vbCrLf & vbCrLf & vbCrLf))
                .UseColumns = usecolumns
                .Columns("Chart").Width = 40
                .Columns("Chart").TextAlignment = ReconcilorTableColumn.Alignment.Center
                .ColourNegativeValues = False
                .ID = "ReturnTable"

                .DataBind()

            End With

            With LayoutTable
                .AddCellInNewRow().Controls.Add(ReturnTable)
            End With
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalApproval Is Nothing Then
                DalApproval = New SqlDalApproval(Resources.Connection)
            End If

            If DalUtility Is Nothing Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If

        End Sub

        Private Function SeriesIsFactor(seriesTypeId As String) As Boolean
            Return seriesTypeId.Contains("Factor") OrElse Report.Calc.Calculation.RecoveryFactors.Any(Function(rf) seriesTypeId.Contains(rf))
        End Function

        Private Function FormatStringDouble(ByVal cellValue As Double, ByVal seriesTypeId As String, ByVal attributeName As String) As String

            If Not SeriesIsFactor(seriesTypeId) AndAlso Not seriesTypeId.Contains("Ratio") AndAlso Not seriesTypeId.Contains("HaulageToOreVsNonOre") AndAlso attributeName = "Tonnes" Then
                ' Divides by 1000. it's kTonnes (tonnes but not a factor or ratio)
                cellValue = (cellValue / 1000)
            End If

            Dim formatString = F1F2F3ReportEngine.GetAttributeValueFormat(attributeName, SeriesIsFactor(seriesTypeId))

            If seriesTypeId.Contains("Ratio") Or seriesTypeId.Contains("HaulageToOreVsNonOre") Then
                ' Ratios are special cases not handled through the normal methods
                formatString = "N2"
            End If

            If attributeName = "Diff" Then
                ' the SD difference field is specific to this screen, so we hardcode the format 
                ' string
                formatString = "N1"
            End If

            If String.IsNullOrEmpty(formatString) Then
                ' this shold never happen - the GetAttributeValue method will always
                ' return a valid format, but in case it changes in the future, this is
                ' a good fail safe
                formatString = "N2"
            End If

            Return cellValue.ToString(formatString)

        End Function
        Private Function ItemDataBoundCallbackEventHandler(ByVal textData As String, ByVal columnName As String, ByVal row As DataRow) As String

            Dim cellContent As String = textData
            Dim attributeName = row.AsString("Attribute")
            Dim seriesTypeId = row.AsString("SeriesTypeId")

            Select Case columnName.ToUpper()
                Case "SERIESTYPENAME"
                    Dim cellIcon As String = String.Format("<img src=""../images/1x1Trans.gif"" style=""filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='../images/{0}', sizingMethod='image');"" border=0></img>", "information.png")
                    cellContent = String.Format("<span title=""{0}"">{1}</span>&nbsp;{2}", System.Web.HttpUtility.HtmlEncode(row("SeriesTypeDescription").ToString()).Replace("""", "'"), cellIcon, row("SeriesTypeName"))
                Case "ATTRIBUTE"
                    If ((Not SeriesIsFactor(row("SeriesTypeId").ToString)) AndAlso (Not row("SeriesTypeId").ToString().Contains("Ratio")) AndAlso (Not row("SeriesTypeId").ToString().Contains("HaulageToOreVsNonOre")) AndAlso cellContent = "Tonnes") Then
                        cellContent = "kTonnes"
                    End If
                Case "DEVIATIONINSD" 'Difference in SD
                    If Not String.IsNullOrEmpty(cellContent) Then
                        Dim deviationInSD = row.AsDbl("DeviationInSD")
                        cellContent = FormatStringDouble(deviationInSD, seriesTypeId, "Diff")

                        If deviationInSD > 0 Then
                            cellContent = "+" + cellContent
                        End If
                    End If
                Case "SERIESSD" 'Standard Deviation (SD)
                    If row.HasValue("SeriesSD") Then
                        cellContent = FormatStringDouble(row.AsDbl("SeriesSD"), seriesTypeId, attributeName)
                    End If
                Case "PROJECTEDVALUE" 'Projected Value
                    If row.HasValue("ProjectedValue") Then
                        cellContent = FormatStringDouble(row.AsDbl("ProjectedValue"), seriesTypeId, attributeName)
                    End If
                Case "VALUE" 'Value
                    If row.HasValue("Value") Then
                        cellContent = FormatStringDouble(row.AsDbl("Value"), seriesTypeId, attributeName)
                    End If

            End Select
            Return cellContent
        End Function
    End Class
End Namespace

