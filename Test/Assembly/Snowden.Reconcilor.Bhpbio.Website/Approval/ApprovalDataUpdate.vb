Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports System.Data.SqlClient
Imports IUtility = Snowden.Reconcilor.Core.Database.DalBaseObjects.IUtility
Imports SqlDalUtility = Snowden.Reconcilor.Core.Database.SqlDal.SqlDalUtility
Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Approval
    Public Class ApprovalDataUpdate
        Inherits ReconcilorAjaxPage

#Region " Properties "

        Private _disposed As Boolean
        Private _approvalMonth As DateTime
        Private _locationId As Integer
        Private _dalApproval As IApproval
        Private _dalUtility As IUtility
        Private _dataApprovalUpdate As New List(Of ApprovalItem)
        Private _editPermissions As Boolean
        Private _dalSecurityLocation As ISecurityLocation
        Private _otherMovement As Boolean

        Public Property DalApproval() As IApproval
            Get
                Return _dalApproval
            End Get
            Set(ByVal value As IApproval)
                _dalApproval = value
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

        Protected ReadOnly Property DataApprovalUpdate() As ICollection(Of ApprovalItem)
            Get
                Return _dataApprovalUpdate
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
                DalApproval = New SqlDalApproval(Resources.Connection)
            End If

            If (_dalSecurityLocation Is Nothing) Then
                _dalSecurityLocation = New SqlDalSecurityLocation(Resources.Connection)
            End If

            If (DalUtility Is Nothing) Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Function ValidateData() As String
            Dim ReturnValue As String = MyBase.ValidateData()
            Dim tagIdKey As String = "approvedTagId_"
            Dim locationKey As String = "approvedLocation_"
            Dim approvedKey As String = "approved_"
            Dim currentlyApproved As DataTable
            Dim dataRows As DataRow()
            Dim key As String
            Dim rowId As String
            Dim locationId As Int32
            Dim tagId As String
            Dim approved As Boolean
            Dim locationIdParsed As Boolean
            Dim item As ApprovalItem
            Dim approvalOrder As Int32 = 0

            Dim maxApprovedOrderNumberByTagAndLocationId As New Dictionary(Of String, Integer)
            Dim minUnapprovedOrderNumberByTagAndLocationId As New Dictionary(Of String, Integer)
            Dim approvalOrderByTagIdAndGroup As New Dictionary(Of String, Integer)
            Dim tagGroupByTagId As New Dictionary(Of String, String)
            
            currentlyApproved = DalApproval.GetBhpbioApprovalDataRaw(_approvalMonth, True)

            ' Get information about data tags in the system
            ' This is required so that we check approvals are occuring in the correct order within a level (location)
            Dim dataTagsTable As DataTable = DalApproval.GetBhpbioReportDataTagsDetailed()

            ' build a structure (dictionary) of approval orders by a combined key of tag group and tag 
            ' this dictionary will be looked up later so that we can check the approval order of any tag being processed
            For Each row As DataRow In dataTagsTable.Rows
                Dim rowTagId As String = row("TagId").ToString().ToUpper()
                Dim rowTagGroupId As String = row("TagGroupId").ToString()
                Dim rowTagGroupAndTagKey As String = String.Format("{0}|{1}", rowTagId, rowTagGroupId)

                tagGroupByTagId(rowTagId) = rowTagGroupId
                Int32.TryParse(row("ApprovalOrder").ToString, approvalOrder)
                approvalOrderByTagIdAndGroup(rowTagGroupAndTagKey) = approvalOrder
            Next

            ' iterate through all keys in the form
            For Each key In Request.Form.Keys
                If (key.StartsWith(tagIdKey)) Then
                    rowId = key.ToString().Replace(tagIdKey, "")
                    tagId = Request(key)

                    ' Get the TagGroupId of the current tag
                    Dim tagGroupId As String = Nothing
                    If Not tagGroupByTagId.TryGetValue(tagId.ToUpper, tagGroupId) Then
                        Throw _
                            New ArgumentException( _
                                                   String.Format("Unable to determine the group of the tag passed for approval '{0}'.", tagId))
                    End If

                    ' Build a group and tag combination
                    Dim tagGroupAndTagKey As String = String.Format("{0}|{1}", tagId.ToUpper(), tagGroupId)
                    If Not approvalOrderByTagIdAndGroup.TryGetValue(tagGroupAndTagKey, approvalOrder) Then
                        Throw _
                            New ArgumentException( _
                                                   String.Format("Unable to determine approval order of tag '{0}'.", tagId))
                    End If

                    ' Determine the location for this tag
                    locationIdParsed = Int32.TryParse(Request(locationKey & rowId), locationId)
                    If Not locationIdParsed Or tagId = "" Then
                        Throw _
                            New ArgumentException( _
                                                   "The Location and/or Tag Id could not be collected for one of the values to be updated.")
                    End If

                    ' Determine the approval state (from the screen) of this approval
                    approved = Request(approvedKey & rowId).ToUpper.Contains("ON")

                    ' Build a key common to all tags at this location and group level
                    Dim tagGroupLocationKey As String = String.Format("{0}|{1}", tagGroupId, locationId)

                    ' determine the maximum approved level for this group and location combination seen so far
                    Dim maxApprovedOrder As Integer
                    If Not maxApprovedOrderNumberByTagAndLocationId.TryGetValue(tagGroupLocationKey, maxApprovedOrder) Then
                        maxApprovedOrder = Integer.MinValue
                    End If


                    ' if the approval order of the current tag is larger than the max seen so far than change the max recorded against this location and tag group
                    If approved AndAlso maxApprovedOrder < approvalOrder Then
                        maxApprovedOrderNumberByTagAndLocationId(tagGroupLocationKey) = approvalOrder
                        maxApprovedOrder = approvalOrder
                    End If

                    ' determine the minimum unapproved order number for this group and location combination
                    Dim minUnapprovedOrder As Integer
                    If Not minUnapprovedOrderNumberByTagAndLocationId.TryGetValue(tagGroupLocationKey, minUnapprovedOrder) Then
                        minUnapprovedOrder = Integer.MaxValue
                    End If

                    ' if the approval order of the current tag is less than the min seen so far then, change the max recorded against this location and tag group
                    If Not approved AndAlso minUnapprovedOrder > approvalOrder Then
                        minUnapprovedOrderNumberByTagAndLocationId(tagGroupLocationKey) = approvalOrder
                        minUnapprovedOrder = approvalOrder
                    End If

                    ' if the maximum approval order for this tag group and location exceeds 1 and is greater than the minimum unapproved item then there is a problem
                    If maxApprovedOrder > 1 And minUnapprovedOrder < maxApprovedOrder Then
                        ' This is an invalid situation
                        ' If this happens then there is a tag that is approved, that has a later approval order then a tag left unapproved
                        Dim validationMessage As String = String.Format("Approvals must be performed in order.\r\nLine items must be approved before summary levels.\r\n\r\nViolation detected within group '{1}' involving approval '{0}'", tagId, tagGroupId)
                        ReturnValue = String.Format("{0}{1}", ReturnValue, validationMessage)

                        ' break out of the loop as an error has been encountered
                        Exit For
                    End If

                    item = New ApprovalItem(tagId, locationId, approved)
                    dataRows = currentlyApproved.Select(String.Format("TagId = '{0}' And LocationId = {1}", _
                                                                        tagId, locationId))
                    ' If its not in the database and it needs to be approved, 
                    ' or it is approved in the db but isn't in the UI
                    If (dataRows.Length() = 0 AndAlso approved) Or _
                       (dataRows.Length() = 1 AndAlso Not approved) Then
                        DataApprovalUpdate.Add(item)
                    End If
                End If
            Next

            Return ReturnValue
        End Function

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            _approvalMonth = RequestAsDateTime("MonthValue")
            LocationId = RequestAsInt32("LocationId")
            _otherMovement = RequestAsBoolean("Other")
        End Sub


        Protected Overridable Sub SetupPageControls()

        End Sub

        Protected Overrides Sub RunAjax()
            Dim javascriptCallback As String
            MyBase.RunAjax()

            If _otherMovement Then
                javascriptCallback = "GetApprovalOtherList();"
            Else
                javascriptCallback = "GetApprovalDataList();"

            End If

            Dim ValidMessage As String = ValidateData()

            Try
                If (ValidMessage = "") Then
                    ProcessData()
                    Controls.Add( _
                                  New HtmlScriptTag(ScriptType.TextJavaScript, _
                                                     javascriptCallback & _
                                                     " alert('Approval status have been updated.');"))
                    ' Response.Write(javascriptCallback & " alert('Approval status have been updated.');")
                Else
                    JavaScriptAlert(ValidMessage, "Please fix the following issues:")
                End If
            Catch ex As SqlException
                JavaScriptAlert(ex.Message)
            End Try
        End Sub

        Protected Overrides Sub ProcessData()
            Dim item As ApprovalItem
            Dim processedKeys As HashSet(Of String) = New HashSet(Of String)()

            For Each item In DataApprovalUpdate
                ' because some approval forms contain more than one row representing the same approval
                ' it is neccessary to ensure we don't double process in the same approval or unapproval in the one call
                ' build a string representing the approval or unapproval
                Dim itemKey As String
                itemKey = String.Format("{0}:{1}:{2}", item.TagId, item.LocationId, item.Approved)

                ' if we haven't already seen an item like this in this operation
                If (Not processedKeys.Contains(itemKey)) Then
                    ' process the approval or unapproval
                    If item.Approved Then
                        DalApproval.ApproveBhpbioApprovalData(item.TagId, item.LocationId, _approvalMonth, _
                                                               Resources.UserSecurity.UserId.Value)
                    Else
                        DalApproval.UnapproveBhpbioApprovalData(item.TagId, item.LocationId, _approvalMonth)
                    End If

                    ' add the item key to the hashset so that we know that we have already processed this kind of approval or unapproval
                    processedKeys.Add(itemKey)
                End If
            Next

        End Sub
    End Class
End Namespace
