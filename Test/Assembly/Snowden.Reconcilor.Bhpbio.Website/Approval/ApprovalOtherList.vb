Imports System.Text
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace Approval
    Public Class ApprovalOtherList
        Inherits WebpageTemplates.ReconcilorAjaxPage

#Region " Properties "
        Private _disposed As Boolean
        Private _dalApproval As Bhpbio.Database.DalBaseObjects.IApproval
        Private _dalUtility As Bhpbio.Database.DalBaseObjects.IUtility
        Private _dalPurge As IPurge
        Private _returnTable As Core.WebDevelopment.ReconcilorControls.ReconcilorTable
        Private _locationId As Int32
        Private _approvalMonth As DateTime
        Private _editPermissions As Boolean
        Private _dalSecurityLocation As Database.SqlDal.SqlDalSecurityLocation
        Private _updateApprovedButton As New InputButtonFormless
        Private _layoutTable As New Tags.HtmlTableTag
        Private _stagingDiv As New Tags.HtmlDivTag("itemStage")

        Public Property DalApproval() As Bhpbio.Database.DalBaseObjects.IApproval
            Get
                Return _dalApproval
            End Get
            Set(ByVal value As Bhpbio.Database.DalBaseObjects.IApproval)
                _dalApproval = value
            End Set
        End Property

        Public Property DalUtility() As Bhpbio.Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Bhpbio.Database.DalBaseObjects.IUtility)
                _dalUtility = value
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

        Public Property ReturnTable() As Core.WebDevelopment.ReconcilorControls.ReconcilorTable
            Get
                Return _returnTable
            End Get
            Set(ByVal value As Core.WebDevelopment.ReconcilorControls.ReconcilorTable)
                _returnTable = value
            End Set
        End Property

        Public ReadOnly Property UpdateApprovedButton() As InputButtonFormless
            Get
                Return _updateApprovedButton
            End Get
        End Property

        Public ReadOnly Property LayoutTable() As Tags.HtmlTableTag
            Get
                Return _layoutTable
            End Get
        End Property

        Public ReadOnly Property StagingDiv() As Tags.HtmlDivTag
            Get
                Return _stagingDiv
            End Get
        End Property
#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If (Not _dalSecurityLocation Is Nothing) Then
                            _dalSecurityLocation.Dispose()
                            _dalSecurityLocation = Nothing
                        End If

                        If (Not DalPurge Is Nothing) Then
                            DalPurge.Dispose()
                            DalPurge = Nothing
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

        Protected Overrides Sub SetupDalObjects()
            If (DalApproval Is Nothing) Then
                DalApproval = New Database.SqlDal.SqlDalApproval(Resources.Connection)
            End If

            If (DalUtility Is Nothing) Then
                DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            If (DalPurge Is Nothing) Then
                DalPurge = New Database.SqlDal.SqlDalPurge(Resources.Connection)
            End If

            If (_dalSecurityLocation Is Nothing) Then
                _dalSecurityLocation = New Database.SqlDal.SqlDalSecurityLocation(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            _editPermissions = _dalSecurityLocation.IsBhpbioUserInLocation( _
                 Resources.UserSecurity.UserId.Value, _locationId)

            SetupPageControls()

            Controls.Add(LayoutTable)
            Controls.Add(StagingDiv)

            'Add call to update the Help Box
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript,
             Tags.ScriptLanguage.JavaScript, "", "ShowApprovalList('" & GetApprovalLegend() & "');"))
        End Sub

        Protected Function GetApprovalLegend() As String
            Dim locationLevel As String = Data.FactorLocation.GetLocationTypeName(DalUtility, _locationId).ToUpper()
            Dim restrictions As New StringBuilder()

            restrictions.Append(GetItemTag($"<span style=""background-color:{OUTLIER_BACKGROUND_ABOVE};"">&nbsp;&nbsp;&nbsp;&nbsp;</span>&nbsp;Value is an outlier above projection"))
            restrictions.Append(GetItemTag($"<span style=""background-color:{OUTLIER_BACKGROUND_BELOW};"">&nbsp;&nbsp;&nbsp;&nbsp;</span>&nbsp;Value is an outlier below projection"))

            ' Purged
            Dim isMonthPurged As Boolean = DalPurge.IsMonthPurged(_approvalMonth)

            If (isMonthPurged) Then
                restrictions.Append(GetItemTag("Data for this period has already been purged.  Approval / Unapproval is not possible."))
            End If

            ' User
            If Not _editPermissions Then
                restrictions.Append(GetItemTag(String.Format(
                "Cannot approve because user does not have permissions at this location. User locations are: {0}",
                GetUserLocations(_dalSecurityLocation, Resources.UserSecurity.UserId.Value))))
            End If

            ' Geology Model
            If locationLevel <> "PIT" Then
                restrictions.Append(GetItemTag("Other movements can only be approved at a pit location. Drilldown further to modify approvals."))
            End If

            Return restrictions.ToString()
        End Function

        Protected Overridable Sub SetupPageControls()
            CreateReturnTable()

            With UpdateApprovedButton
                .ID = "ApprovalButton"
                .Text = "Update Approved Status"
                .OnClientClick = "ApproveOtherMovement()"
            End With

            With LayoutTable
                .AddCellInNewRow().Controls.Add(ReturnTable)
            End With

            Dim footerMessage As New Tags.HtmlDivTag()
            footerMessage.InnerText = "* Relatively large values within the red boxes might indicate trucking errors or stockpile grouping errors."

            LayoutTable.AddCellInNewRow().Controls.Add(footerMessage)
            LayoutTable.CurrentCell.HorizontalAlign = Web.UI.WebControls.HorizontalAlign.Right

            'TODO With integration in tabcontrol button not req any more. 
            'If _editPermissions Then
            '    LayoutTable.AddCellInNewRow().Controls.Add(UpdateApprovedButton)
            '    LayoutTable.CurrentCell.HorizontalAlign = Web.UI.WebControls.HorizontalAlign.Right
            'End If
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            _locationId = RequestAsInt32("LocationId")
            _approvalMonth = RequestAsDateTime("MonthValue")

            Resources.UserSecurity.SetSetting("Approval_Filter_Date", _approvalMonth.ToString())
            Resources.UserSecurity.SetSetting("Approval_Filter_LocationId", _locationId.ToString())

            If _locationId < 1 Then ' Update the Location Id if null was presented.
                _locationId = DalUtility.GetBhpbioLocationRoot()
            End If
        End Sub

        ' Adds styles to the list, which includes the left and top borders. This is done in 
        ' ApprovalTree.GetIndentedNodeTable but due to not being able to use controls can not be used here.
        Public Function CellBoundCallbackEventHandler(ByVal textData As String, ByVal columnName As String, _
            ByVal row As System.Data.DataRow) As String
            Dim rowstyle As String
            Dim cellAttributes As String = textData

            If columnName.ToUpper() = COLUMN_MATERIAL_NAME.ToUpper() Then
                rowstyle = ""
                If Not IsDBNull(row(COLUMN_CALC_BLOCK_MID)) Then
                    rowstyle = String.Format("{0}border-left: buttonshadow 1px solid; ", rowstyle)
                End If
                If Not IsDBNull(row(COLUMN_CALC_BLOCK_TOP)) Then
                    rowstyle = String.Format("{0}border-top: buttonshadow 1px solid; ", rowstyle)
                End If

                cellAttributes = String.Format(" style=""{0}""", rowstyle)
            End If

            Return cellAttributes
        End Function


        Protected Overridable Sub CreateReturnTable()
            Dim tableColumns As Generic.Dictionary(Of String, ReconcilorControls.ReconcilorTableColumn)
            Dim useColumns As New Generic.List(Of String)
            Dim reportSession As New Types.ReportSession(Resources.ConnectionString)

            'Dim locationLevel As String = Report.Data.FactorLocation.GetLocationTypeName( _
            ' reportSession.DalUtility, _locationId)
            'Dim locationEditable As Boolean = (locationLevel.ToUpper() = "PIT" And _editPermissions)

            ' Find out whether the month is purged
            Dim isMonthPurged As Boolean = _dalPurge.IsMonthPurged(_approvalMonth)

            Dim approvalOtherList As DataTable = ApprovalOtherListData.CreateApprovalDigblockList(reportSession, _
             _approvalMonth, _locationId, False, Nothing, 0, Resources.UserSecurity.UserId.Value, isMonthPurged)

            'AddListStyles(approvalOtherList) ' Add material name formatting only for the list.

            reportSession.Dispose()

            tableColumns = ReconcilorTable.GetUserInterfaceColumns(DalUtility, "Approval_Other")

            For Each item As String In tableColumns.Keys
                useColumns.Add(item)
            Next

            ReturnTable = New ReconcilorTable(approvalOtherList, useColumns.ToArray())

            With ReturnTable
                .IsSortable = False
                .Height = 460
                .RowIdColumn = COLUMN_NODE_ROW_ID
                .ItemDataBoundCallback = AddressOf ApprovalOtherListData.OtherDisplayTable_ItemCallback
                .CellBoundCallback = AddressOf CellBoundCallbackEventHandler

                For Each item In tableColumns.Keys
                    .Columns.Add(item, tableColumns(item))
                Next

                If .Columns.ContainsKey("SignOffDate") Then
                    .Columns("SignOffDate").DateTimeFormat = DalUtility.GetSystemSetting("FORMAT_DATE")
                End If

                If .Columns.ContainsKey("Signoff") Then
                    .Columns("Signoff").HeaderText = "Signed Off By"
                End If

                .DataBind()
            End With
        End Sub
    End Class
End Namespace
