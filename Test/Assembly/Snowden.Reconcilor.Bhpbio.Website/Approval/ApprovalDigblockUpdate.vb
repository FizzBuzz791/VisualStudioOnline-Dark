Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Database
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports System.Web.UI
Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Approval
    Public Class ApprovalDigblockUpdate
        Inherits Core.WebDevelopment.WebpageTemplates.ReconcilorAjaxPage

#Region " Properties "
        Private _approvalMonth As DateTime
        Private _disposed As Boolean
        Private _dalApproval As Bhpbio.Database.DalBaseObjects.IApproval
        Private _dalBlock As Bhpbio.Database.DalBaseObjects.IBhpbioBlock
        Private _dalUtility As Core.Database.DalBaseObjects.IUtility
        Private _digblockApprovalUpdate As New Dictionary(Of String, Boolean)
        Private _editPermissions As Boolean
        Private _locationId As Integer
        Private _dalSecurityLocation As Bhpbio.Database.DalBaseObjects.ISecurityLocation
        Private _limitRecords As Boolean

        Public Property DalApproval() As Bhpbio.Database.DalBaseObjects.IApproval
            Get
                Return _dalApproval
            End Get
            Set(ByVal value As Bhpbio.Database.DalBaseObjects.IApproval)
                _dalApproval = value
            End Set
        End Property


        Public Property DalBlock() As Bhpbio.Database.DalBaseObjects.IBhpbioBlock
            Get
                Return _dalBlock
            End Get
            Set(ByVal value As Bhpbio.Database.DalBaseObjects.IBhpbioBlock)
                _dalBlock = value
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

        Protected ReadOnly Property DigblockApprovalUpdate() As Dictionary(Of String, Boolean)
            Get
                Return _digblockApprovalUpdate
            End Get
        End Property

        Protected Property EditPermissions() As Boolean
            Get
                Return _editPermissions
            End Get
            Set(ByVal value As Boolean)
                _editPermissions = value
            End Set
        End Property

        Protected Property LocationId() As Integer
            Get
                Return _locationId
            End Get
            Set(ByVal value As Integer)
                _locationId = value
            End Set
        End Property
#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
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
                DalApproval = New Bhpbio.Database.SqlDal.SqlDalApproval(Resources.Connection)
            End If

            If (_dalSecurityLocation Is Nothing) Then
                _dalSecurityLocation = New Bhpbio.Database.SqlDal.SqlDalSecurityLocation(Resources.Connection)
            End If

            If (DalUtility Is Nothing) Then
                DalUtility = New Core.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            If (DalBlock Is Nothing) Then
                DalBlock = New Bhpbio.Database.SqlDal.SqlDalBhpbioBlock(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Function ValidateData() As String
            Dim ReturnValue As String = MyBase.ValidateData()
            Dim approved As Boolean
            Dim approvedList As DataTable
            Dim dataRows As DataRow()
            Dim key As String
            Dim rowId As String
            Dim digblockId As String
            Dim tagIdKey As String = "approvedTagId_"
            Dim locationKey As String = "approvedLocation_"
            Dim approvedKey As String = "approved_"

            approvedList = DalApproval.GetBhpbioApprovalDigblockList( _
              LocationId, _approvalMonth, NullValues.Int32)

            If ReturnValue = "" Then


                For Each key In Request.Form.Keys
                    If (key.StartsWith(tagIdKey)) Then
                        rowId = key.ToString().Replace(tagIdKey, "")
                        digblockId = Request(key)
                        approved = Request(approvedKey & rowId).ToUpper.Contains("ON")

                        dataRows = approvedList.Select("DigblockId = '" & digblockId & "'")
                        If dataRows.Length() = 1 AndAlso Convert.ToBoolean(dataRows(0)("Approved")) <> approved Then
                            DigblockApprovalUpdate.Add(digblockId, approved)
                            approvedList.Rows.Remove(dataRows(0))
                        End If

                    End If
                Next
            End If

                    Return ReturnValue
        End Function

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            _approvalMonth = RequestAsDateTime("MonthValue")
            LocationId = RequestAsInt32("LocationId")
            _limitRecords = RequestAsBoolean("LimitRecords")
        End Sub


        Protected Overridable Sub SetupPageControls()

        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            EditPermissions = _dalSecurityLocation.IsBhpbioUserInLocation( _
                 Resources.UserSecurity.UserId.Value, LocationId)

            Dim ValidMessage As String = ValidateData()

            Try
                If Not EditPermissions Then
                    JavaScriptAlert("User does not have enough permissions to perform this action.", "Security Issue: ")
                ElseIf (ValidMessage = "") Then
                    ProcessData()
                    Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, "GetApprovalDigblockList();alert('Approval status have been updated.');"))

                    'Response.Write("GetApprovalDigblockList(); alert('Approval status have been updated.');")
                Else
                    JavaScriptAlert(ValidMessage, "Please fix the following issues:")
                End If
            Catch ex As SqlClient.SqlException
                JavaScriptAlert(ex.Message)
            End Try
        End Sub

        Protected Overrides Sub ProcessData()
            Dim digblockId As String
            Dim unapproval As Boolean = False

            For Each digblockId In DigblockApprovalUpdate.Keys
                If DigblockApprovalUpdate(digblockId) Then
                    DalApproval.ApproveBhpbioApprovalDigblock(digblockId, _approvalMonth, Resources.UserSecurity.UserId.Value)
                Else
                    DalApproval.UnapproveBhpbioApprovalDigblock(digblockId, _approvalMonth)
                    unapproval = True
                End If
            Next

            ' if one or more blocks are unapproved then re-run recon movements update to ensure latest recon movements are applied
            If (unapproval) Then
                DalBlock.UpdateBhpbioReconciliationMovement(LocationId)
            End If

        End Sub


    End Class
End Namespace
