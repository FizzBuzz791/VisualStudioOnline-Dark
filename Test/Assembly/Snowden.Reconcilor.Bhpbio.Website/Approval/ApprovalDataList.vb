Imports Snowden.Reconcilor.Bhpbio.Report.Data
Imports Snowden.Reconcilor.Core
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports System.Web.UI.WebControls
Imports System.Text
Imports System.Web.UI
Imports System.Web.UI.HtmlControls
Imports ReconcilorFunctions = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorFunctions
Imports Snowden.Reconcilor.Bhpbio.Report

Namespace Approval
    Public Class ApprovalDataList
        Inherits ReconcilorAjaxPage

#Region " Properties "

        Private _approvalMonth As DateTime
        Private _disposed As Boolean
        Private _dalApproval As IApproval
        Private _dalUtility As IUtility
        Private _dalSecurityLocation As SqlDalSecurityLocation
        Private _dalPurge As IPurge
        Private _validationTable As ReconcilorTable
        Private _updateApprovedButton As New InputButtonFormless
        Private _layoutTable As New HtmlTableTag
        Private _locationId As Int32
        Private _editPermissions As Boolean
        Private _grades As New Dictionary(Of String, Grade)
        Private _fImageLayout As New HtmlTableTag
        Private _gridLayout As New HtmlTableTag
        Private _notebleoutlier As New HtmlTableTag
        Private _stagingDiv As New HtmlDivTag("itemStage")
        Private _approvalDataList As DataTable

        Public ReadOnly Property Grades() As Dictionary(Of String, Grade)
            Get
                Return _grades
            End Get
        End Property

        'Public ReadOnly Property FImageLayout() As HtmlTableTag
        '    Get
        '        Return _fImageLayout
        '    End Get
        'End Property
        Public ReadOnly Property GridLayout() As HtmlTableTag
            Get
                Return _gridLayout
            End Get
        End Property
        Public ReadOnly Property NotableOutlier() As HtmlTableTag
            Get
                Return _notebleoutlier
            End Get
        End Property

        Public Property DalApproval() As IApproval
            Get
                Return _dalApproval
            End Get
            Set(ByVal value As IApproval)
                _dalApproval = value
            End Set
        End Property

        Public Property DalPurge() As IPurge
            Get
                Return _dalPurge
            End Get
            Set(ByVal value As IPurge)
                _dalPurge = value
            End Set
        End Property

        Public Property DalUtility() As IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As IUtility)
                _dalUtility = value
            End Set
        End Property

        Public Property ValidationTable() As ReconcilorTable
            Get
                Return _validationTable
            End Get
            Set(ByVal value As ReconcilorTable)
                _validationTable = value
            End Set
        End Property

        Public ReadOnly Property UpdateApprovedButton() As InputButtonFormless
            Get
                Return _updateApprovedButton
            End Get
        End Property

        Public ReadOnly Property LayoutTable() As HtmlTableTag
            Get
                Return _layoutTable
            End Get
        End Property

        Protected Property LocationId() As Int32
            Get
                Return _locationId
            End Get
            Set(ByVal value As Int32)
                _locationId = value
            End Set
        End Property

        Protected Property EditPermissions() As Boolean
            Get
                Return _editPermissions
            End Get
            Set(ByVal value As Boolean)
                _editPermissions = value
            End Set
        End Property

        Public ReadOnly Property StagingDiv() As HtmlDivTag
            Get
                Return _stagingDiv
            End Get
        End Property

        Private Property ApprovalDataList() As DataTable
            Get
                Return _approvalDataList
            End Get
            Set(ByVal value As DataTable)
                _approvalDataList = value
            End Set
        End Property

#End Region

#Region " Destructors "

        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If Not _dalApproval Is Nothing Then
                            _dalApproval.Dispose()
                        End If

                        If Not _dalUtility Is Nothing Then
                            _dalUtility.Dispose()
                        End If

                        If Not _dalSecurityLocation Is Nothing Then
                            _dalSecurityLocation.Dispose()
                        End If

                        If Not _dalPurge Is Nothing Then
                            _dalPurge.Dispose()
                        End If

                        If Not _updateApprovedButton Is Nothing Then
                            _updateApprovedButton.Dispose()
                        End If

                        If Not _updateApprovedButton Is Nothing Then
                            _updateApprovedButton.Dispose()
                        End If

                        If Not _layoutTable Is Nothing Then
                            _layoutTable.Dispose()
                        End If

                    End If
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

        Protected Overridable Sub RetrieveGradeFormats()
            Dim gradeData As DataTable = DalUtility.GetGradeList(Convert.ToInt16(True))
            Dim gradeRow As DataRow

            For Each gradeRow In gradeData.Rows
                Grades.Add(gradeRow("Grade_Name").ToString,
                            New Grade(gradeRow, Application("NumericFormat").ToString))
            Next
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalApproval Is Nothing) Then
                DalApproval = New SqlDalApproval(Resources.Connection)
            End If

            If (DalUtility Is Nothing) Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If

            If (DalPurge Is Nothing) Then
                DalPurge = New SqlDalPurge(Resources.Connection)
            End If

            If (_dalSecurityLocation Is Nothing) Then
                _dalSecurityLocation = New SqlDalSecurityLocation(Resources.Connection)
            End If

            MyBase.SetupDalObjects()

            ApprovalDataListData.DalUtility = DalUtility
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()



            LocationId = RequestAsInt32("LocationId")
            _approvalMonth = RequestAsDateTime("MonthValue")

            'LocationId = Convert.ToInt32(UserSecurity.GetSetting("Haulage_Error_Filter_Location", 1, "0"))
        End Sub


        Protected Overridable Sub SetupPageControls()
            'Dim f2image As New HtmlImageTag
            'Dim mmceimage As New HtmlImageTag
            'Dim f25image As New HtmlImageTag
            'Dim f3image As New HtmlImageTag
            Dim areOutliersDisplayed As Boolean = False

            Dim called As New HtmlInputHidden
            called.ID = "GridShown"
            Dim nextOutlierCalculationDateTime As Nullable(Of DateTime) = ApprovalDataListData.DetermineMonthForNextOutlierQueueEntry(Resources.ConnectionString)
            CreateValidationTable(nextOutlierCalculationDateTime, areOutliersDisplayed)

            With UpdateApprovedButton
                .ID = "ApprovalButton"
                .Text = "Update Approved Status"
                .OnClientClick = "ApproveData()"
            End With
            Dim param = String.Format("'{0}','{1}','0', true", _locationId, _approvalMonth)

            With NotableOutlier
                If areOutliersDisplayed Then
                    .AddHeaderCellInNewHeaderRow().Controls.Add(New LiteralControl("<a href=""#"" onclick=""GetOutlierAnalysisApprovalGrid(" + param + "); return false;""><div id='outlierimg' style='float:left;'></div>Most Notable Outliers</a>"))
                Else
                    .AddHeaderCellInNewHeaderRow().Controls.Add(New LiteralControl("<div id='outlierimg' style='float:left;visibility:hidden'></div>"))
                End If
            End With

            With GridLayout

                .AddCellInNewRow().Controls.Add(New HtmlDivTag("itemOutlier", String.Empty, String.Empty))
                .CurrentCell.HorizontalAlign = HorizontalAlign.Left
                .AddCellInNewRow().Controls.Add(called)
            End With

            With LayoutTable
                'If (_approvalMonth >= nextOutlierCalculationDateTime) Then
                '    Dim outlierMessage As New Literal()

                '    Dim messageText As String = String.Format("<i><b>NOTE: </b>{0}{1}</i>",
                '                                              "An outlier detection process is pending.",
                '                                              If(areOutliersDisplayed, String.Empty, " Outlier detection results are not displayed."))

                '    outlierMessage.Text = messageText
                '    .AddCellInNewRow().Controls.Add(outlierMessage)
                'End If

                .AddCellInNewRow().Controls.Add(ValidationTable)
                'not required any more .AddCellInNewRow().Controls.Add(UpdateApprovedButton)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Right
                .AddCellInNewRow().Controls.Add(New HtmlDivTag(Nothing, String.Empty, "tabs_spacer"))
                .AddCellInNewRow().Controls.Add(NotableOutlier)
                .AddCellInNewRow().Controls.Add(GridLayout)
                'Image not required any more
                '.AddCellInNewRow().Controls.Add(FImageLayout)
                .CurrentCell.HorizontalAlign = HorizontalAlign.Center
                ' show or hide the outlier legend based on whether outliers are visible or not
                'Dim showHideScript As New Literal()
                'showHideScript.Text = String.Format("<script>document.getElementById(""{0}"").style.visibility = '{1}';</script>",
                '                        ApprovalDataListData.outlierLegendDivId,
                '                                   "Visible")
                ''If(areOutliersDisplayed, "Visible", "Hidden")
                '.CurrentCell.Controls.Add(showHideScript)

            End With

            'f2image.Source = "..\images\Approval\ApprovalF2.gif"
            'mmceimage.Source = "..\images\Approval\ApprovalMMCE.gif"
            'f25image.Source = "..\images\Approval\ApprovalF25.gif"
            'f3image.Source = "..\images\Approval\ApprovalF3.gif"

            'With FImageLayout
            '    .AddCellInNewRow.Controls.Add(f2image)
            '    .AddCell.Controls.Add(mmceimage)
            '    .AddCellInNewRow.Controls.Add(f25image)
            '    .AddCell.Controls.Add(f3image)
            'End With
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            EditPermissions = _dalSecurityLocation.IsBhpbioUserInLocation(
                                                                           Resources.UserSecurity.UserId.Value,
                                                                           LocationId)

            RetrieveGradeFormats()
            SetupPageControls()

            Resources.UserSecurity.SetSetting("Approval_Filter_Date", _approvalMonth.ToString())
            Resources.UserSecurity.SetSetting("Approval_Filter_LocationId", _locationId.ToString())

            Controls.Add(LayoutTable)
            Controls.Add(StagingDiv)

            'Add call to update the Help Box
            Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript,
                                             ScriptLanguage.JavaScript, "",
                                             "ShowApprovalList('" & GetApprovalRestrictions() & "');"))

            Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript,
                                            ScriptLanguage.JavaScript, "", String.Format(
                                            "GetOutlierAnalysisApprovalGrid('{0}','{1}',1, true);", _locationId, _approvalMonth)))

        End Sub

        Protected Function GetApprovalRestrictions() As String
            Dim locationLevel As String = FactorLocation.GetLocationTypeName(DalUtility, LocationId).ToUpper()
            Dim restrictions As New StringBuilder()

            restrictions.Append(GetItemTag($"<span style=""background-color:{OUTLIER_BACKGROUND_ABOVE};"">&nbsp;&nbsp;&nbsp;&nbsp;</span>&nbsp;Value is an outlier above projection"))
            restrictions.Append(GetItemTag($"<span style=""background-color:{OUTLIER_BACKGROUND_BELOW};"">&nbsp;&nbsp;&nbsp;&nbsp;</span>&nbsp;Value is an outlier below projection"))

            ' Purged
            Dim isMonthPurged As Boolean = DalPurge.IsMonthPurged(_approvalMonth)

            If (isMonthPurged) Then
                restrictions.Append(GetItemTag("Data for this period has already been purged.  Approval / Unapproval is not possible."))
            End If

            ' User
            If Not EditPermissions Then
                restrictions.Append(GetItemTag(String.Format(
                                                                "Cannot approve because user does not have permissions at this location. User locations are: {0}",
                                                                GetUserLocations(_dalSecurityLocation,
                                                                                  Resources.UserSecurity.UserId.Value))))
            End If

            ' Geology Model
            If locationLevel <> "PIT" Then
                restrictions.Append(
                                     GetItemTag(
                                                 " Geology Model cannot be approved as the location is not the pit level."))
            Else
                restrictions.Append(
                                     GetItemTag(GetLockedMessage("GeologyModel", "Geology Model can not be approved:")))
            End If

            ' F1
            If locationLevel <> "PIT" Then
                restrictions.Append(GetItemTag("F1 cannot be approved as the location is not the pit level."))
                restrictions.Append(GetItemTag("F1.5 cannot be approved as the location is not the pit level."))
            Else
                restrictions.Append(GetItemTag(GetLockedMessage("F1Factor", "F1 can not be approved:")))
                restrictions.Append(GetItemTag(GetLockedMessage("F15Factor", "F1.5 can not be approved:")))
            End If

            ' F2
            If locationLevel <> "SITE" Then
                restrictions.Append(GetItemTag("F2 cannot be approved as the location is not the site level."))
            Else
                restrictions.Append(GetItemTag(GetLockedMessage("F2Factor", "F2 can not be approved:")))
            End If

            ' F2.5
            If locationLevel <> "HUB" Then
                restrictions.Append(GetItemTag("F2.5 cannot be approved as the location is not the hub level."))
            Else
                restrictions.Append(GetItemTag(GetLockedMessage("F25Factor", "F2.5 can not be approved:")))
            End If

            ' F3
            If locationLevel <> "HUB" Then
                restrictions.Append(GetItemTag("F3 cannot be approved as the location is not the hub level."))
            Else
                restrictions.Append(GetItemTag(GetLockedMessage("F3Factor", "F3 can not be approved:")))
            End If

            Return restrictions.ToString()
        End Function


        Protected Function GetLockedMessage(ByVal calcId As String, ByVal prefix As String) As String
            Dim row As DataRow
            Dim returnText As String = Nothing
            row = (From r In ApprovalDataList.Select()
                   Where r.Item("CalcId").ToString() = calcId
                   Select r).First()

            If Not row Is Nothing Then
                returnText = row("PresentationLocked").ToString()
            End If

            If returnText <> "" Then
                returnText = String.Format("{0} {1}", prefix, returnText)
            End If

            Return returnText
        End Function


        Protected Overridable Sub CreateValidationTable(ByVal nextOutlierCalculationDateTime As Nullable(Of DateTime), ByRef areOutliersDisplayed As Boolean)
            Dim columnName As String
            Dim tableColumns As Dictionary(Of String, ReconcilorTableColumn)
            Dim useColumns As New List(Of String)

            tableColumns = ReconcilorTable.GetUserInterfaceColumns(DalUtility, "Approval_Data")

            For Each columnName In tableColumns.Keys
                useColumns.Add(columnName)
            Next

            ' Find out whether the month is purged
            Dim isMonthPurged As Boolean = _dalPurge.IsMonthPurged(_approvalMonth)

            areOutliersDisplayed = True
            ApprovalMonth = _approvalMonth
            ApprovalDataList = CreateValidationTableData(Resources.ConnectionString, 0,
                                                          _locationId, False, _editPermissions, Nothing, Nothing,
                                                          Resources.UserSecurity.UserId.Value,
                                                          isMonthPurged, Resources.UserSecurity, areOutliersDisplayed, nextOutlierCalculationDateTime)

            ValidationTable = New ReconcilorTable(ApprovalDataList, useColumns.ToArray())
            Dim outlierDictionary As Dictionary(Of String, OutlierDetails) = Nothing
            If (areOutliersDisplayed) Then
                outlierDictionary = CreateOutlierDetectionDictionary(Resources.ConnectionString, _locationId)
            End If

            ' create a call back function with access to the outlier dictionary
            Dim itemCallBack = Function(ByVal textData As String, ByVal colName As String, ByVal row As DataRow) As String
                                   Return ValidationTable_ItemCallbackWithOutlierCheck(textData, colName, row, outlierDictionary)
                               End Function

            With ValidationTable

                .ItemDataBoundCallback = itemCallBack
                .RowBoundCallback = AddressOf FReportDisplayTable_RowCallback
                .IsSortable = False
                .Height = 460
                .ColourNegativeValues = False
                .ContainerPadding = 200
                .RowIdColumn = "NodeRowId"
                .CanExportCsv = False

                For Each colName As String In tableColumns.Keys
                    .Columns.Add(colName, tableColumns(colName))
                Next

                If .Columns.ContainsKey("Tonnes") Then
                    .Columns("Tonnes").NumericFormat = ReconcilorFunctions.SetNumericFormatDecimalPlaces(2)
                End If

                If .Columns.ContainsKey("SignOffDate") Then
                    .Columns("SignOffDate").DateTimeFormat = DalUtility.GetSystemSetting("FORMAT_DATE")
                End If

                If .Columns.ContainsKey("SignOff") Then
                    .Columns("SignOff").HeaderText = "Signed Off By"
                End If

                For Each currentGrade As Grade In Grades.Values
                    If .Columns.ContainsKey(currentGrade.Name) Then
                        .Columns(currentGrade.Name).NumericFormat = ReconcilorFunctions.SetNumericFormatDecimalPlaces(currentGrade.Precision)
                    End If
                Next

                For Each columnName In .Columns.Keys
                    .Columns(columnName).ColumnSortType = ReconcilorTableColumn.SortType.NoSort
                Next

                .DataBind()
            End With
        End Sub

        Protected Overridable Function FReportDisplayTable_RowCallback(ByVal rowAttributes As String,
                                                                        ByVal row As DataRow) As String
            Dim validRow As Boolean = True
            Dim returnValue As String = rowAttributes

            If Not IsDBNull(row("PresentationValid")) Then
                validRow = DirectCast(row("PresentationValid"), Boolean)
            End If

            If validRow = False Then
                returnValue = "style=""BACKGROUND-COLOR: lightgrey;"""
            End If

            Return returnValue
        End Function
    End Class
End Namespace


