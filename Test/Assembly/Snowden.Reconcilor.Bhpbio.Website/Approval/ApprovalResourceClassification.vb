Imports Snowden.Reconcilor.Bhpbio.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI
Imports System.Text
Imports System.Web.Services.Description
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports ReconcilorFunctions = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorFunctions
Imports Snowden.Reconcilor.Core
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Approval
    Public Class ApprovalResourceClassification
        Inherits ReconcilorWebpage


#Region " Properties "
        Private _disposed As Boolean

        Private _calcId As String
        Private _dateFrom As DateTime
        Private _dateTo As DateTime
        Private _locationId As Int32
        Private _productSize As String

        Private _totalTonnes As Double
        Private _headerDiv As New Tags.HtmlDivTag()
        Private _reconTable As ReconcilorTable
        Private _data As DataTable
        Private _dalReport As Bhpbio.Database.SqlDal.SqlDalReport
        Private _dalUtility As Bhpbio.Database.SqlDal.SqlDalUtility

        Private _gradeDictionary As Dictionary(Of String, Grade) = Nothing
        Private _locationName As String

        Protected ReadOnly Property IsFactor() As Boolean
            Get
                Return _calcId IsNot Nothing AndAlso _calcId.EndsWith("Factor")
            End Get
        End Property


        Protected ReadOnly Property GradeDictionary() As Dictionary(Of String, Grade)
            Get
                If _gradeDictionary Is Nothing Then
                    _gradeDictionary = DalUtility.GetGradeObjectsList(NullValues.Int16, Application("NumericFormat").ToString)
                End If

                Return _gradeDictionary
            End Get
        End Property


        Protected ReadOnly Property HeaderDiv() As Tags.HtmlDivTag
            Get
                Return _headerDiv
            End Get
        End Property

        Protected Property DalReport() As Bhpbio.Database.SqlDal.SqlDalReport
            Get
                Return _dalReport
            End Get
            Set(ByVal value As Bhpbio.Database.SqlDal.SqlDalReport)
                _dalReport = value
            End Set
        End Property

        Protected Property DalUtility() As Bhpbio.Database.SqlDal.SqlDalUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Bhpbio.Database.SqlDal.SqlDalUtility)
                _dalUtility = value
            End Set
        End Property
#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If (Not _dalReport Is Nothing) Then
                            _dalReport.Dispose()
                            _dalReport = Nothing
                        End If

                    End If

                    'Clean up unmanaged resources ie: Pointers & Handles
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region

        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("APPROVAL_FREPORT"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub


        Protected Overrides Sub SetupDalObjects()
            If (DalReport Is Nothing) Then
                DalReport = New Bhpbio.Database.SqlDal.SqlDalReport(Resources.Connection)
            End If

            If (DalUtility Is Nothing) Then
                DalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            Try

                MyBase.RetrieveRequestData()

                _calcId = RequestAsString("CalculationID")
                _dateFrom = RequestAsDateTime("DateFrom")
                _dateTo = RequestAsDateTime("DateTo")
                _locationId = RequestAsInt32("LocationId")
                _productSize = RequestAsString("ProductSize")

                Using session As New ReportSession(Resources.ConnectionString)
                    _data = F1F2F3SingleCalculationReport.GetResourceClassificationCalculation(session, _calcId, _locationId, _dateFrom, _dateTo, _productSize)
                    _data = F1F2F3ReportEngine.AddResourceClassificationDescriptions(_data)

                    ' add column to hold the % values
                    If Not _data.Columns.Contains("Percentage") Then
                        _data.Columns.Add("Percentage", GetType(Double))
                    End If

                    ' Moves "Total row" to the top, and set the total tonnes
                    Dim totalsRow = _data.AsEnumerable.FirstOrDefault(Function(r) Not r.HasValue("ResourceClassification"))

                    If totalsRow.HasValue("Tonnes") Then
                        If IsFactor() Then
                            _totalTonnes = totalsRow.AsDbl("FactorTonnes")
                        Else
                            _totalTonnes = totalsRow.AsDbl("Tonnes")
                        End If
                    End If

                    If totalsRow IsNot Nothing Then
                        Dim newRow = totalsRow.Copy()
                        _data.Rows.Remove(totalsRow)
                        _data.Rows.InsertAt(newRow, 0)
                    End If

                    ' 'Removes "No Information" if equals zero
                    Dim emptyRows = _data.AsEnumerable.Where(Function(r) r.AsString("ResourceClassification") = "ResourceClassificationUnknown" AndAlso Not r.HasValue("Tonnes")).ToList
                    _data.DeleteRows(emptyRows.AsEnumerable)

                    ' get the location name string
                    _locationName = Data.ReportDisplayParameter.GetLocationCommentByDate(session, _locationId, Date.Now.Date)
                    _locationName = _locationName.Replace("\", " \ ")
                End Using

            Catch ex As Exception

                Dim errorTag = New HtmlControls.HtmlGenericControl("div")
                errorTag.InnerText = ex.Message

                ReconcilorContent.Controls.Clear()
                ReconcilorContent.Controls.Add(errorTag)
            End Try
        End Sub
        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()
            Dim table As New Tags.HtmlTableTag()
            Dim form As New Tags.HtmlFormTag()

            With HeaderDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl(_dateFrom.ToString("MMMM yyyy") & " | " & _locationName))
            End With
            With form
                .ID = "FormId"
            End With
            form.Controls.Add(table)
        End Sub

        Protected Function GetLocationName(locationId As Int32) As String
            Dim locationName = ""

            'Gets Location Name based on date range and LocationID
            Dim dt = DalUtility.GetBhpbioLocationNameWithOverride(_locationId, _dateFrom, _dateTo)
            If dt IsNot Nothing Then
                locationName = dt.Rows(0)("Name").ToString()
            End If

            Return locationName
        End Function

        Private Function ItemDataBoundCallbackEventHandler(ByVal textData As String, ByVal columnName As String, ByVal row As DataRow) As String

            Dim cellContent As String = textData
            Dim formatString As String = "N2"
            Dim attributeName = columnName
            Dim gradeColumns = CalculationResultRecord.StandardGradeNames

            If columnName.ToUpper() = "TONNES" Then
                If Not String.IsNullOrEmpty(cellContent) Then
                    Dim tonnesValue = row.AsDbl("tonnes")
                    If Not IsFactor() Then tonnesValue = tonnesValue / 1000
                    formatString = F1F2F3ReportEngine.GetAttributeValueFormat(attributeName, _calcId)
                    cellContent = tonnesValue.ToString(formatString)
                End If
            ElseIf columnName.ToUpper() = "PERCENTAGE" Then
                Dim tonnesValue = 0.0

                If IsFactor Then
                    tonnesValue = row.AsDbl("FactorTonnes")
                Else
                    tonnesValue = row.AsDbl("Tonnes")
                End If

                cellContent = (tonnesValue / _totalTonnes * 100).ToString(formatString)
            ElseIf gradeColumns.Contains(columnName) Then
                If row.HasValue(columnName) Then
                    formatString = F1F2F3ReportEngine.GetAttributeValueFormat(attributeName, _calcId)
                    cellContent = row.AsDbl(columnName).ToString(formatString)
                Else
                    cellContent = (0.0).ToString(formatString)
                End If
            End If

            Dim isTotalRow = row("ResourceClassificationDescription").ToString().Contains("INVALID_RC")

            If isTotalRow Then
                If columnName = "ResourceClassificationDescription" Then
                    cellContent = row.AsString("Description")

                    If HasProductSize() Then
                        cellContent = String.Format("{0} ({1})", cellContent, _productSize)
                    End If

                ElseIf columnName = "Percentage" Then
                    cellContent = ""
                End If

                cellContent = "<b>" + cellContent + "</b>"
            End If

            If columnName = "ResourceClassificationDescription" AndAlso textData <> "INVALID_RC" Then
                cellContent = "&nbsp;&nbsp;&nbsp;&nbsp;" & cellContent
            End If

            Return cellContent
        End Function

        Protected Function HasProductSize() As Boolean
            Return _productSize IsNot Nothing And _productSize.ToUpper <> "TOTAL"
        End Function

        Protected Overridable Function GetReconcilorTable() As ReconcilorTable
            Dim useColumns() As String
            useColumns = {"ResourceClassificationDescription", "Percentage", "Tonnes", "Fe", "P", "SiO2", "Al2O3", "LOI", "H2O"}

            _reconTable = New ReconcilorTable(_data, useColumns)
            With _reconTable
                .Columns.Add("ResourceClassificationDescription", New ReconcilorTableColumn("Description"))
                .Columns("ResourceClassificationDescription").Width = 270

                .Columns.Add("Percentage", New ReconcilorTableColumn("%"))
                .Columns.Add("Tonnes", New ReconcilorTableColumn("Ktonnes"))
                .Columns.Add("Fe", New ReconcilorTableColumn("Fe"))
                .Columns.Add("P", New ReconcilorTableColumn("P"))
                .Columns.Add("SiO2", New ReconcilorTableColumn("SiO2"))
                .Columns.Add("Al2O3", New ReconcilorTableColumn("Al2O3"))
                .Columns.Add("LOI", New ReconcilorTableColumn("LOI"))
                .Columns.Add("H2O", New ReconcilorTableColumn("H2O"))
                .CanExportCsv = False
                .Height = 300
                .ItemDataBoundCallback = AddressOf ItemDataBoundCallbackEventHandler
                .DataBind()
            End With

            Return _reconTable
        End Function

        Protected Overrides Sub SetupPageLayout()
            HasCalendarControl = True
            MyBase.SetupPageLayout()

            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioApproval.js", ""))

            With ReconcilorContent.ContainerContent
                .Style.Add("padding-left", "32px")
                .Controls.Add(HeaderDiv)
                .Controls.Add(New Tags.HtmlBRTag())

                If Not _data Is Nothing Then
                    _reconTable = GetReconcilorTable()
                End If

                If Not _reconTable Is Nothing Then
                    .Controls.Add(_reconTable)
                End If
            End With

        End Sub


    End Class
End Namespace
