Imports Snowden.Reconcilor.Bhpbio.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI
Imports System.Text
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports ReconcilorFunctions = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorFunctions
Imports Snowden.Reconcilor.Core

Namespace Approval
    Public Class ApprovalDataReview
        Inherits ReconcilorWebpage


#Region " Properties "
        Private _disposed As Boolean
        Private _tagId As String
        Private _dateFrom As DateTime
        Private _dateTo As DateTime
        Private _locationId As Int32
        Private _productSize As String
        Private _headerDiv As New Tags.HtmlDivTag()
        Private _reconTable As ReconcilorTable
        Private _data As DataTable
        Private _dalReport As Bhpbio.Database.SqlDal.SqlDalReport
        Private _dalUtility As Bhpbio.Database.SqlDal.SqlDalUtility
        Private _group As New GroupBox("Filter")

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
            MyBase.RetrieveRequestData()

            _tagId = RequestAsString("TagId")
            _dateFrom = RequestAsDateTime("DateFrom")
            _dateTo = RequestAsDateTime("DateTo")
            _locationId = RequestAsInt32("LocationId")
            _productSize = RequestAsString("ProductSize")

            If _tagId.EndsWith("LUMP") Then
                _tagId = _tagId.Replace("LUMP", "")
            Else
                If _tagId.EndsWith("FINES") Then
                    _tagId = _tagId.Replace("FINES", "")
                End If
            End If

            If _productSize = "TOTAL" Then
                _productSize = Nothing
            End If

            _data = DalReport.GetBhpbioReportDataReview(_tagId, _locationId, _dateFrom, _dateTo, _productSize)
        End Sub

        Protected Overrides Sub SetupPageControls()
            MyBase.SetupPageControls()

            Dim table As New Tags.HtmlTableTag()
            Dim form As New Tags.HtmlFormTag()

            Dim dateFromPicker As WebpageControls.DatePicker = _
                New WebpageControls.DatePicker("FilterDateFrom", "FormId", _dateFrom)
            Dim dateToPicker As WebpageControls.DatePicker = _
                New WebpageControls.DatePicker("FilterDateTo", "FormId", _dateTo)

            Dim location As New Core.WebDevelopment.ReconcilorControls.ReconcilorLocationSelector()
            Dim button As New Core.WebDevelopment.ReconcilorControls.InputTags.InputButtonFormless()
            Dim product As New Core.WebDevelopment.ReconcilorControls.InputTags.SelectBox()

            HasCalendarControl = True

            PageHeader.ScriptTags.Add(dateFromPicker.InitialiseScript)
            PageHeader.ScriptTags.Add(dateToPicker.InitialiseScript)

            With HeaderDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")
                .Controls.Add(New LiteralControl("Live Data Investigation for " & _tagId))
            End With

            With button
                .Text = "Filter"
                .OnClientClick = String.Format("ApprovalInvestigationFilter('{0}');", _tagId)
            End With

            With form
                .ID = "FormId"
            End With

            With location
                .LocationId = _locationId
                .ID = "LocationPicker"
            End With

            With product
                .ID = "ProductFilter"
                .Items.Add("TOTAL")
                .Items.Add("LUMP")
                .Items.Add("FINES")
                .SelectedValue = _productSize
            End With

            With table
                .AddCellInNewRow().Controls.Add(New LiteralControl("DateFrom:"))
                .AddCell().Controls.Add(dateFromPicker.ControlScript)
                .AddCell().Controls.Add(New LiteralControl("DateTo:"))
                .AddCell().Controls.Add(dateToPicker.ControlScript)
                .AddCell().Controls.Add(location)
                .AddCell().Controls.Add(New LiteralControl("Product:"))
                .AddCell().Controls.Add(product)
                .AddCell().Controls.Add(button)
            End With


            form.Controls.Add(table)
            _group.Controls.Add(form)

            Dim dataMessageDivTag As New Tags.HtmlDivTag()
            dataMessageDivTag.StyleClass = "smallHeaderText"
            dataMessageDivTag.Style.Add("margin-bottom", "5px")
            dataMessageDivTag.Controls.Add(New LiteralControl("* This screen shows Live data only.  As a result, data is only visible in periods that have not yet been purged."))
            _group.Controls.Add(dataMessageDivTag)

            _group.Controls.Add(New LiteralControl())

        End Sub

        Protected Overridable Function GetReconcilorTable() As ReconcilorTable
            Dim tableColumns As New Generic.Dictionary(Of String, ReconcilorTableColumn)
            Dim useColumns As New Generic.List(Of String)

            Dim gradeDictionary As Dictionary(Of String, Grade) = DalUtility.GetGradeObjectsList(NullValues.Int16, Application("NumericFormat").ToString)

            For Each column As DataColumn In _data.Columns
                tableColumns.Add(column.ColumnName, New ReconcilorTableColumn(column.ColumnName))

                Select Case column.DataType.Name
                    Case "Double", "Single"

                        If gradeDictionary.ContainsKey(column.ColumnName) Then
                            tableColumns(column.ColumnName).NumericFormat = ReconcilorFunctions.SetNumericFormatDecimalPlaces( _
                                gradeDictionary(column.ColumnName).Precision)
                        ElseIf column.ColumnName.Contains("Percentage") Then
                            tableColumns(column.ColumnName).NumericFormat = "#,##0.00%"
                        ElseIf column.ColumnName.EndsWith("Id") = False Then
                            tableColumns(column.ColumnName).NumericFormat = ReconcilorFunctions.SetNumericFormatDecimalPlaces(2)
                        Else
                            tableColumns(column.ColumnName).NumericFormat = "0"
                        End If

                    Case "Int32"
                        If column.ColumnName.EndsWith("Id") Then
                            tableColumns(column.ColumnName).NumericFormat = "0"
                        End If

                    Case "DateTime"
                        tableColumns(column.ColumnName).DateTimeFormat = Application("DateFormat").ToString
                End Select
            Next

            For Each item As String In tableColumns.Keys
                useColumns.Add(item)
            Next

            _reconTable = New ReconcilorTable(_data, useColumns.ToArray())
            For Each colName As String In tableColumns.Keys
                _reconTable.Columns.Add(colName, tableColumns(colName))
            Next
            _reconTable.Height = 500
            _reconTable.DataBind()
            Return _reconTable
        End Function

        Protected Overrides Sub SetupPageLayout()
            HasCalendarControl = True
            MyBase.SetupPageLayout()

            PageHeader.ScriptTags.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, Tags.ScriptLanguage.JavaScript, "../js/BhpbioApproval.js", ""))

            With ReconcilorContent.ContainerContent
                .Controls.Add(HeaderDiv)
                .Controls.Add(_group)
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
