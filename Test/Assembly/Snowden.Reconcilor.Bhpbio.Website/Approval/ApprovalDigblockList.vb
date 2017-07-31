Imports System.Text
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports System.Web

Namespace Approval
    Public Class ApprovalDigblockList
		Inherits WebpageTemplates.ReconcilorAjaxPage

#Region " Properties "
        Private _approvalMonth As DateTime
        Private _disposed As Boolean
		Private _dalApproval As Database.DalBaseObjects.IApproval
        Private _dalUtility As Core.Database.DalBaseObjects.IUtility
        Private _dalPurge As IPurge
		Private _returnTable As ReconcilorTable
        Private _layoutTable As New Tags.HtmlTableTag
        Private _limitRecords As Boolean
        Private _locationId As Int32
        Private _editPermissions As Boolean
        Private _dalSecurityLocation As Database.DalBaseObjects.ISecurityLocation
        Private _percentageFormat As String = "#,##0.0%"
        
		Public Property DalApproval() As Database.DalBaseObjects.IApproval
			Get
				Return _dalApproval
			End Get
			Set(ByVal value As Database.DalBaseObjects.IApproval)
				_dalApproval = value
			End Set
		End Property

        Public Property DalUtility() As Core.Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Core.Database.DalBaseObjects.IUtility)
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

		Public Property ReturnTable() As ReconcilorTable
			Get
				Return _returnTable
			End Get
			Set(ByVal value As ReconcilorTable)
				_returnTable = value
			End Set
		End Property

        Public ReadOnly Property LayoutTable() As Tags.HtmlTableTag
            Get
                Return _layoutTable
            End Get
        End Property

        Protected Property LimitRecords() As Boolean
            Get
                Return _limitRecords
            End Get
            Set(ByVal value As Boolean)
                _limitRecords = value
            End Set
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
#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                    End If

                    If (Not DalPurge Is Nothing) Then
                        DalPurge.Dispose()
                        DalPurge = Nothing
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
            If (CheckSecurity AndAlso (Not Resources.UserSecurity.HasAccess("APPROVAL_DIGBLOCK"))) Then
                ReportAccessDenied()
            End If

            MyBase.HandlePageSecurity()
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalApproval Is Nothing) Then
				DalApproval = New Database.SqlDal.SqlDalApproval(Resources.Connection)
            End If

            If (_dalSecurityLocation Is Nothing) Then
				_dalSecurityLocation = New Database.SqlDal.SqlDalSecurityLocation(Resources.Connection)
            End If

            If (DalPurge Is Nothing) Then
                DalPurge = New Database.SqlDal.SqlDalPurge(Resources.Connection)
            End If

            If (DalUtility Is Nothing) Then
                DalUtility = New Core.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            LocationId = RequestAsInt32("ApprovalFilterLocationId")
            LimitRecords = RequestAsBoolean("LimitRecords")
            _approvalMonth = RequestAsDateTime("MonthValueApprovalFilter")

            Resources.UserSecurity.SetSetting("Approval_Filter_Date", _approvalMonth.ToString())
            Resources.UserSecurity.SetSetting("Approval_Filter_LocationId", _locationId.ToString())
        End Sub

        Protected Overridable Sub SetupPageControls()
            CreateReturnTable()

            With LayoutTable
                .AddCellInNewRow().Controls.Add(ReturnTable)
                If EditPermissions Then
                    .CurrentCell.HorizontalAlign = Web.UI.WebControls.HorizontalAlign.Right
                End If
            End With
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            EditPermissions = _dalSecurityLocation.IsBhpbioUserInLocation( _
            Resources.UserSecurity.UserId.Value, LocationId)

            SetupPageControls()

            Controls.Add(LayoutTable)

            'Add call to update the Help Box
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript,
             Tags.ScriptLanguage.JavaScript, "", "ShowApprovalList('" & GetApprovalRestrictions() & "');"))
        End Sub

        Protected Function GetApprovalRestrictions() As String
			Dim locationLevel As String = Data.FactorLocation.GetLocationTypeName(DalUtility, LocationId).ToUpper()
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
                restrictions.Append(GetItemTag(String.Format( _
                "Cannot approve because user does not have permissions at this location. User locations are: {0}", _
                GetUserLocations(_dalSecurityLocation, Resources.UserSecurity.UserId.Value))))
            End If

            ' Geology Model
            If locationLevel <> "PIT" Then
                restrictions.Append(GetItemTag("The blast block\'s can only be approved at a pit location."))
            End If

            Return restrictions.ToString()
        End Function

        Protected Overridable Function GetDigblockApprovalTable( _
         ByVal reportSession As Types.ReportSession, ByVal locationEditable As Boolean, _
         ByVal locationLevel As String) As DataTable

            Dim approvalDigblockList As DataTable
            Dim recordLimit As Integer = NullValues.Int32
            Dim lockedMessage As String = ""

            If Data.ApprovalData.IsAnyTagGroupApproved(reportSession, LocationId, _approvalMonth, "F1Factor", "F1GeologyModel") Then
                lockedMessage = "Cannot unapprove blastblock data as Geology model data has been approved."
            ElseIf Data.ApprovalData.IsAnyTagGroupApproved(reportSession, LocationId, _approvalMonth, "F1Factor") Then
                lockedMessage = "Cannot unapprove blastblock data as F1 data has been approved."
            ElseIf Data.ApprovalData.IsAnyTagGroupApproved(reportSession, LocationId, _approvalMonth, "OtherMaterial") Then
                lockedMessage = "Cannot unapprove blastblock data as Other Movements data has been approved."
            End If

            ' Sort out limit records
            If LimitRecords And locationLevel.ToUpper() <> "PIT" Then
                If Not Integer.TryParse(DalUtility.GetSystemSetting("DEFAULTRECORDLIMIT"), recordLimit) Then
                    recordLimit = NullValues.Int32
                End If
            End If

            approvalDigblockList = DalApproval.GetBhpbioApprovalDigblockList(LocationId, _approvalMonth, recordLimit)

            ' Create the new check box column for approvals
            approvalDigblockList.Columns.Add("DigblockLink", GetType(String), _
              "'<a target=""new"" href=""../Digblocks/DigblockDetails.aspx?DigblockId=' + DigblockId + '"">' + DigblockId + '</a>'")

            AddLocked(approvalDigblockList, lockedMessage)

            'Force it to be disabled every time by passing forceDisabled is True
            'Previously it passed isMonthPurged where isMonthPurged was set by
            'Dim isMonthPurged As Boolean = DalPurge.IsMonthPurged(_approvalMonth)
            AddApprovalCheck(approvalDigblockList, LocationId, locationEditable, "DigblockId", "", True)

            Return approvalDigblockList
        End Function

        Protected Overridable Sub CreateReturnTable()
			Dim approvalDigblockList As DataTable

			Dim reportSession As New Types.ReportSession(Resources.ConnectionString)
			reportSession.Context = Types.ReportContext.ApprovalListing

			Dim tableColumns As Dictionary(Of String, ReconcilorTableColumn)
			Dim locationLevel As String = Data.FactorLocation.GetLocationTypeName( _
			reportSession.DalUtility, LocationId)
			Dim locationEditable As Boolean = (locationLevel.ToUpper() = "PIT" And EditPermissions)

			tableColumns = ReconcilorTable.GetUserInterfaceColumns(DalUtility, "Approval_Digblock")

			approvalDigblockList = GetDigblockApprovalTable(reportSession, locationEditable, locationLevel)

			reportSession.Dispose()

			ReturnTable = New ReconcilorTable(approvalDigblockList, tableColumns.Keys.ToArray())
            With ReturnTable
                For Each colName As String In tableColumns.Keys
                    .Columns.Add(colName, tableColumns(colName))
                Next

                If .Columns.ContainsKey("SignOffDate") Then
                    .Columns("SignOffDate").DateTimeFormat = DalUtility.GetSystemSetting("FORMAT_DATE")
                End If

                .ItemDataBoundCallback = AddressOf ApprovalsTable_ItemDataboundCallback
                .DataBind()
            End With

        End Sub

        Protected Overridable Function ApprovalsTable_ItemDataboundCallback(ByVal textData As String, ByVal columnName As String, ByVal row As DataRow) As String
            Dim returnValue As String = textData

            Select Case columnName
                Case "GeologyTonnes"
                    returnValue = FormatTonnes(textData, row("GeologyModelFilename").ToString)
                Case "MiningTonnes"
                    returnValue = FormatTonnes(textData, row("MiningModelFilename").ToString)
                Case "ShortTermGeologyTonnes"
                    returnValue = FormatTonnes(textData, row("ShortTermGeologyModelFilename").ToString)
                Case "GradeControlTonnes"
                    returnValue = FormatTonnes(textData, row("GradeControlModelFilename").ToString)
                Case "TotalMinedPercent"
                    returnValue = FormatPercentage(row(columnName).ToString)
                Case "MonthlyMinedPercent"
                    returnValue = FormatPercentage(row(columnName).ToString)
                Case "BestTonnes"
                    returnValue = FormatTonnes(textData)
                Case "RemainingTonnes"
                    returnValue = FormatTonnes(textData)
                Case Else
                    returnValue = textData
            End Select

            Return returnValue
        End Function

        Private Function FormatTonnes(ByVal tonnes As String, ByVal tooltip As String) As String
            tonnes = tonnes.Trim
            If tonnes = String.Empty Then
                Return "-"
            Else
                If String.IsNullOrEmpty(tooltip) Then
                    tooltip = "-"
                Else
                    tooltip = HttpUtility.HtmlEncode(tooltip)
                End If
                Return "<span title=""" & tooltip & """>" & Convert.ToDouble(tonnes).ToString(Application("NumericFormat").ToString) & "</span>"
            End If
        End Function

        Private Function FormatPercentage(ByVal percent As String) As String
            percent = percent.Trim

            If percent = String.Empty Then
                Return "-"
            Else
                If Not Application("PercentageFormat") Is Nothing Then
                    _percentageFormat = Application("PercentageFormat").ToString
                End If
                Return Convert.ToDouble(percent).ToString(_percentageFormat)
            End If
        End Function

        Private Function FormatTonnes(ByVal tonnes As String) As String
            tonnes = tonnes.Trim
            If tonnes = String.Empty Then
                Return "-"
            Else
                Dim numbericTonnes As Double
                If Double.TryParse(tonnes, numbericTonnes) Then
                    Return numbericTonnes.ToString(Application("NumericFormat").ToString)
                Else
                    Return tonnes
                End If
            End If
        End Function

    End Class
End Namespace
