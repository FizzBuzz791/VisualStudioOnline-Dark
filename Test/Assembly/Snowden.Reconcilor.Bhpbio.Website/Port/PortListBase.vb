Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Common.Web.BaseHtmlControls.Tags

Namespace Port
    Public MustInherit Class PortListBase
        Inherits ReconcilorAjaxPage

#Region "Properties"

        Private _dateFrom As DateTime?
        Private _dateTo As DateTime?
        Private _locationId As Int32?

        Private _disposed As Boolean
        Private _dalReport As IReport
        Private _dalUtility As IUtility
        Private _grades As New Dictionary(Of String, Grade)

        Private Const _portListHeight As Int32 = 200
        Private Const _portListHeaderHeight As Int32 = 9
        Private Const _portListContainerPadding As Int32 = 100
        Private Const _portListWidth As Int32 = 800

        Public Property DalReport() As IReport
            Get
                Return _dalReport
            End Get
            Set (ByVal value As IReport)
                If (Not value Is Nothing) Then
                    _dalReport = value
                End If
            End Set
        End Property

        Public Property DalUtility() As IUtility
            Get
                Return _dalUtility
            End Get
            Set (ByVal value As IUtility)
                If (Not value Is Nothing) Then
                    _dalUtility = value
                End If
            End Set
        End Property

        Public Property DateFrom() As DateTime?
            Get
                Return _dateFrom
            End Get
            Set (ByVal value As DateTime?)
                _dateFrom = value
            End Set
        End Property

        Public Property DateTo() As DateTime?
            Get
                Return _dateTo
            End Get
            Set (ByVal value As DateTime?)
                _dateTo = value
            End Set
        End Property

        Public Property LocationId() As Int32?
            Get
                Return _locationId
            End Get
            Set (ByVal value As Int32?)
                _locationId = value
            End Set
        End Property

#End Region

        Protected Sub New()
            MyBase.New()
        End Sub

        Protected Overrides Sub Dispose (ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If (Not _dalReport Is Nothing) Then
                            _dalReport.Dispose()
                            _dalReport = Nothing
                        End If

                        If (Not _dalUtility Is Nothing) Then
                            _dalUtility.Dispose()
                            _dalUtility = Nothing
                        End If

                        _grades = Nothing
                    End If
                End If

                _disposed = True
            Finally
                MyBase.Dispose (disposing)
            End Try
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If _dalReport Is Nothing Then
                _dalReport = New SqlDalReport (Resources.Connection)
            End If

            If _dalUtility Is Nothing Then
                _dalUtility = New SqlDalUtility (Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            Dim RequestText As String
            Dim locationIdFilter As Int32
            Dim dateFilter As DateTime

            'Date From
            RequestText = Trim (Request ("PortDateFromText"))
            If RequestText <> "" AndAlso DateTime.TryParse (RequestText, dateFilter) Then
                DateFrom = dateFilter
            Else
                DateFrom = Date.Parse (Resources.UserSecurity.GetSetting ("Port_Filter_DateFrom", Date.Now.ToString()))
            End If

            'Date To
            RequestText = Trim (Request ("PortDateToText"))
            If RequestText <> "" AndAlso DateTime.TryParse (RequestText, dateFilter) Then
                DateTo = dateFilter
            Else
                DateTo = Date.Parse (Resources.UserSecurity.GetSetting ("Port_Filter_DateTo", Date.Now.ToString()))
            End If

            If (Trim (Request ("PortDateToText")) = String.Empty And Trim (Request ("PortDateFromText")) = String.Empty) _
                Then
                Dim _
                    strPopulateDate As String = "populateDate('" + DateFrom.Value.ToString ("dd-MMM-yyyy") + "', '" + _
                                                DateTo.Value.ToString ("dd-MMM-yyyy") + "');"
                Controls.Add (New HtmlScriptTag (ScriptType.TextJavaScript, strPopulateDate))
            End If

            'Location
            RequestText = Trim (Request ("LocationId"))
            If (RequestText <> "") _
               AndAlso (RequestText <> "-1") _
               AndAlso Int32.TryParse (RequestText, locationIdFilter) Then
                LocationId = locationIdFilter
                Resources.UserSecurity.SetSetting ("Port_Filter_LocationId", RequestText)
            Else
                LocationId = Nothing
                Resources.UserSecurity.SetSetting ("Port_Filter_LocationId", "")
            End If
        End Sub

        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess ("PORT_GRANT"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            SetupDalObjects()

            'load the grade data
            Dim grades As DataTable
            Dim grade As DataRow

            Resources.UserSecurity.SetSetting ("Port_Filter_DateTo", DateTo.Value.ToString())
            Resources.UserSecurity.SetSetting ("Port_Filter_DateFrom", DateFrom.Value.ToString())

            _grades = New Dictionary(Of String, Grade)

            grades = DalUtility.GetGradeList (NullValues.Int16)
            For Each grade In grades.Rows
                _grades.Add (DirectCast (grade ("Grade_Name"), String), _
                             New Grade (grade, DirectCast (Application ("NumericFormat"), String)))
            Next

        End Sub

        Protected Sub FormatListingTable (ByVal reconcilorTable As ReconcilorTable)
            reconcilorTable.Height = _portListHeight
            reconcilorTable.HeaderHeight = _portListHeaderHeight
            reconcilorTable.ContainerPadding = _portListContainerPadding
        End Sub

        Protected Sub AddConfigurableColumns (ByVal tableName As String, _
                                              ByVal reconcilorTable As ReconcilorTable)

            Dim tableColumns As Dictionary(Of String, ReconcilorTableColumn)
            Dim useColumns As New List(Of String)

            'retrieve the list of columns
            tableColumns = _
                Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.ReconcilorTable.GetUserInterfaceColumns ( _
                                                                                                                   DalUtility, _
                                                                                                                   tableName)
            For Each item As String In tableColumns.Keys
                useColumns.Add (item)
            Next

            reconcilorTable.UseColumns = useColumns.ToArray()
            For Each key As String In tableColumns.Keys
                Dim recColumn As ReconcilorTableColumn = tableColumns (key)

                'These two columns automaticall get numeric format set - set to string.empty
                If (recColumn.HeaderText = "Customer No" Or recColumn.HeaderText = "Nomination Key") Then
                    recColumn.NumericFormat = String.Empty
                End If

                reconcilorTable.Columns.Add (key, recColumn)
            Next
            useColumns = Nothing

        End Sub

        Protected Function TableItemDataboundCallback (ByVal textData As String, ByVal columnName As String, _
                                                       ByVal row As DataRow) As String
            Dim returnValue As String = textData.Trim

            ' Enhancements to allow more imported shipping data
            Dim shippingImportedFields() As String = {"H2O", "Undersize", "Oversize"}

            If _grades.ContainsKey (columnName) Then
                'we've found a grade column
                If row (columnName) Is DBNull.Value Then
                    returnValue = "-"
                Else
                    returnValue = _grades(columnName).ToString(Convert.ToSingle(row(columnName)), False)
                End If

            ElseIf shippingImportedFields.Contains(columnName) Then
                ' If the column is one of our new ones, we want it in decimal. If we don't do this it does not display any decimal places
                If row(columnName) Is DBNull.Value Then
                    returnValue = ""
                Else
                    returnValue = Convert.ToDecimal(row(columnName)).ToString
                End If
            End If

            Return returnValue
        End Function
    End Class
End Namespace
