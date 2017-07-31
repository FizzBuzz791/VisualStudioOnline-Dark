Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment

Namespace Utilities
    Public Class WeightometerSampleList
        Inherits WebpageTemplates.UtilitiesAjaxTemplate

#Region "Properties"
        Private _DalUtility As Database.DalBaseObjects.IUtility
        Private _WeightometerID As String
        Private _DateFrom As DateTime
        Private _DateTo As DateTime
        Private _DisplayType As String
        Private _LocationId As Int32 = 0
        Private _LimitRecords As Boolean = True
        Private _recordLimit As Int32 = DoNotSetValues.Int32

        Public Property DalUtility() As Database.DalBaseObjects.IUtility
            Get
                Return _DalUtility
            End Get
            Set(ByVal value As Database.DalBaseObjects.IUtility)
                If (Not value Is Nothing) Then
                    _DalUtility = value
                End If
            End Set
        End Property
        Public Property WeightometerID() As String
            Get
                Return _WeightometerID
            End Get
            Set(ByVal value As String)
                _WeightometerID = value
            End Set
        End Property
        Public Property DateFrom() As DateTime
            Get
                Return _DateFrom
            End Get
            Set(ByVal value As DateTime)
                _DateFrom = value
            End Set
        End Property
        Public Property DateTo() As DateTime
            Get
                Return _DateTo
            End Get
            Set(ByVal value As DateTime)
                _DateTo = value
            End Set
        End Property
        Public Property DisplayType() As String
            Get
                Return _DisplayType
            End Get
            Set(ByVal value As String)
                _DisplayType = value
            End Set
        End Property
        Public Property LocationId() As Int32
            Get
                Return _LocationId
            End Get
            Set(ByVal value As Int32)
                _LocationId = value
            End Set
        End Property
        Public Property LimitRecords() As Boolean
            Get
                Return _LimitRecords
            End Get
            Set(ByVal value As Boolean)
                _LimitRecords = value
            End Set
        End Property
        Public Property RecordLimit() As Int32
            Get
                Return _recordLimit
            End Get
            Set(ByVal value As Int32)
                _recordLimit = value
            End Set
        End Property

#End Region

        Protected Overrides Sub RunAjax()
            Dim tableControl As Core.WebDevelopment.ReconcilorControls.ReconcilorTable
            Dim weightometerTable As DataTable

            If DisplayType = "Sample" Then
                RenderWeightometerSampleListBySample()
            ElseIf DisplayType = "Weightometer" Then
                RenderWeightometerSampleListByWeightometer()
            End If

            SaveFilterSettings()

            'retrieve a list of weightometers
            weightometerTable = DalUtility.GetWeightometerList(Convert.ToInt16(False))
            Try
                For Each control As System.Web.UI.Control In Controls
                    'If this control is the Reconcilor table.
                    If control.GetType Is GetType(Core.WebDevelopment.ReconcilorControls.ReconcilorTable) Then
                        tableControl = DirectCast(control, Core.WebDevelopment.ReconcilorControls.ReconcilorTable)

                        With tableControl
                            If DisplayType = "Weightometer" Then
                                .Columns("Shift_Name").HeaderText = "Shift"

                                For Each tableControlColumn In .Columns()
                                    For Each weightometerTableRow As DataRow In weightometerTable.Rows()
                                        Dim weightometerId As String = weightometerTableRow("Weightometer_Id").ToString

                                        If tableControlColumn.Key.ToLower = weightometerId.ToLower Then
                                            Dim weightometerColumnDescription As String = weightometerTableRow("Description").ToString()

                                            Dim delimiterText As String = " to "

                                            If weightometerColumnDescription.ToLower.Contains(delimiterText) Then
                                                Dim delimiterIndex As Integer = weightometerColumnDescription.IndexOf(delimiterText)
                                                weightometerColumnDescription = weightometerColumnDescription.Insert(delimiterIndex, "<br />")
                                            End If

                                            .Columns(tableControlColumn.Key).HeaderText = weightometerColumnDescription
                                            .Columns(tableControlColumn.Key).Width = 0
                                        End If
                                    Next
                                Next
                            End If
                        End With

                        tableControl.DataBind()
                    End If
                Next
            Finally
                If Not (weightometerTable Is Nothing) Then
                    weightometerTable.Dispose()
                    weightometerTable = Nothing
                End If
            End Try
        End Sub

        Protected Overrides Sub HandlePageSecurity()
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("ADMIN_USER"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If (Request("WeightometerID") = "" Or Request("WeightometerID") Is Nothing) Then
                WeightometerID = Nothing
            Else
                WeightometerID = Request("WeightometerID").Trim
            End If

            If (Not Request("SampleDateFromText") Is Nothing) Then
                DateFrom = Convert.ToDateTime(Request("SampleDateFromText"))
            End If

            If (Not Request("SampleDateToText") Is Nothing) Then
                DateTo = Convert.ToDateTime(Request("SampleDateToText"))
            End If

            If (Not Request("SampleSort") Is Nothing) Then
                DisplayType = Request("SampleSort").Trim
            End If

            LimitRecords = RequestAsBoolean("LimitRecords")
            If LimitRecords Then
                RecordLimit = Convert.ToInt32(DalUtility.GetSystemSetting("DefaultRecordLimit"))
            End If

            LocationId = RequestAsInt32("LocationId")
            If LocationId = -1 Then
                LocationId = DoNotSetValues.Int32
            End If
        End Sub

        Private Sub RenderWeightometerSampleListBySample()
            Dim SampleList As DataTable
            Dim SampleTable As ReconcilorControls.ReconcilorTable
            Dim UseColumns As String() = {"Weightometer_ID", "Weightometer_Sample_Date", _
             "Shift_Name", "Order_No", "Tonnes", "Corrected_Tonnes", _
             "Source", "Destination", "Shift_Order_No", "View"}

            Dim ExcludeColumns As String() = {"Shift_Order_No"}

            SampleList = DalUtility.GetWeightometerSampleList(WeightometerID, DateFrom, DateTo, DoNotSetValues.Int16, LocationId, RecordLimit).Tables("Data")

            With SampleList
                .Columns.Add("View", GetType(String), "'<a href=""./WeightometerSampleEdit.aspx?WeightometerSampleID=' + Weightometer_Sample_ID + '&AllowEdit=False"">View</a>'")
            End With

            SampleTable = New ReconcilorControls.ReconcilorTable(SampleList, UseColumns)

            With SampleTable
                'Formatting - Must be done PreBind & must create column before binding
                .Columns.Add("Weightometer_Sample_Date", New ReconcilorControls.ReconcilorTableColumn("Sample Date"))
                .Columns("Weightometer_Sample_Date").DateTimeFormat = Application("DateFormat").ToString
                .ExcludeColumns = ExcludeColumns
                .DataBind()

                'Headers
                .Columns("Weightometer_ID").HeaderText = "Weightometer"
                .Columns("Shift_Name").HeaderText = "Shift"
                .Columns("Corrected_Tonnes").HeaderText = "Corrected <br />Tonnes "

                'Cell Alignment
                .Columns("Shift_Name").TextAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
                .Columns("Weightometer_Sample_Date").TextAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center

                'Widths
                .Columns("Corrected_Tonnes").Width = 75
            End With

            Controls.Add(SampleTable)
        End Sub

        Private Sub RenderWeightometerSampleListByWeightometer()
            Dim SampleList As DataTable
            Dim SampleTable As ReconcilorControls.ReconcilorTable
            Dim UseColumns As String() = {"Weightometer_Sample_Date", "Shift_Name"}
            Dim ExcludeColumns As String() = {"Weightometer_Sample_Shift", "Shift_Order_No"}

            SampleList = DalUtility.GetWeightometerSampleListPivoted(WeightometerID, DateFrom, DateTo, DoNotSetValues.Int16, LocationId, RecordLimit)

            'Append pivoted weightometers to Use Columns
            Dim Col As DataColumn
            For Each Col In SampleList.Columns
                If Array.IndexOf(ExcludeColumns, Col.ColumnName) = -1 _
                 And Array.IndexOf(UseColumns, Col.ColumnName) = -1 Then
                    ReDim Preserve UseColumns(UseColumns.Length)
                    UseColumns(UseColumns.Length - 1) = Col.ColumnName
                End If
            Next

            SampleTable = New ReconcilorControls.ReconcilorTable(SampleList, UseColumns)

            With SampleTable
                'Formatting
                .Columns.Add("Weightometer_Sample_Date", New ReconcilorControls.ReconcilorTableColumn("Sample Date"))
                .Columns("Weightometer_Sample_Date").DateTimeFormat = Application("DateFormat").ToString

                .ExcludeColumns = ExcludeColumns
                .DataBind()
            End With

            Controls.Add(SampleTable)
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Private Sub SaveFilterSettings()
            If (DateFrom = NullValues.DateTime) Then
                Resources.UserSecurity.SetSetting("Weightometer_Sample_Filter_Date_From", "")
            Else
                Resources.UserSecurity.SetSetting("Weightometer_Sample_Filter_Date_From", DateFrom.ToString)
            End If

            If (DateTo = NullValues.DateTime) Then
                Resources.UserSecurity.SetSetting("Weightometer_Sample_Filter_Date_To", "")
            Else
                Resources.UserSecurity.SetSetting("Weightometer_Sample_Filter_Date_To", DateTo.ToString)
            End If

            If (DisplayType Is Nothing) Then
                Resources.UserSecurity.SetSetting("Weightometer_Sample_Filter_Display_Type", "")
            Else
                Resources.UserSecurity.SetSetting("Weightometer_Sample_Filter_Display_Type", DisplayType.ToString)
            End If

            If (WeightometerID Is Nothing) Then
                Resources.UserSecurity.SetSetting("Weightometer_Sample_Filter_Weightometer_ID", "")
            Else
                Resources.UserSecurity.SetSetting("Weightometer_Sample_Filter_Weightometer_ID", WeightometerID.ToString)
            End If

            Resources.UserSecurity.SetSetting("Weightometer_Sample_Filter_Location", LocationId.ToString)
        End Sub

    End Class
End Namespace

