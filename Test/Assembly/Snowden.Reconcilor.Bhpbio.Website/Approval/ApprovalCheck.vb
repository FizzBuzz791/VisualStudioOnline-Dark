Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports System.Text
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Bhpbio.Report.Calc
Imports Snowden.Reconcilor.Bhpbio.Report.Constants

Namespace Approval
    Public Module ApprovalCheck

        Public Const COLUMN_LOCATION_ID As String = "LocationId"
        Public Const COLUMN_LOCATION_NAME As String = "LocationName"
        Public Const COLUMN_LOCATION_TYPE As String = "LocationType"
        Public Const COLUMN_MATERIAL_NAME As String = "MaterialName"
        Public Const COLUMN_NODE_ROW_ID As String = "NodeRowId"
        Public Const COLUMN_CALC_BLOCK_TOP As String = "CalcBlockTop"
        Public Const COLUMN_CALC_BLOCK_MID As String = "CalcBlockMid"
        Public Const COLUMN_PRESENTATION_EDITABLE As String = "PresentationEditable"

        Public Function GetItemTag(text As String) As String
            Dim returnText As String = text
            If text <> "" Then
                returnText = "<DIV class=sideNavItem><li>" & text & "</li></DIV>"
            End If
            Return returnText
        End Function

        Public Function GetUserLocations(dalSecurity As ISecurityLocation, userId As Int32) As String
            Dim row As DataRow
            Dim locationNames As New StringBuilder("")
            Dim locations As DataTable = dalSecurity.GetBhpbioUserLocationList(userId)

            For Each row In locations.Rows
                locationNames.Append(row("Name").ToString() & ", ")
            Next

            If locationNames.Length > 2 Then
                locationNames.Remove(locationNames.Length - 2, 2)
            End If

            If locationNames.Length = 0 Then
                locationNames.Append("None")
            End If

            Return locationNames.ToString()
        End Function

        ''' <summary>
        ''' Adds the Presentation Editable column to the table which is set depending on the location type.
        ''' </summary>
        Public Sub AddPresentationEditableCheck(table As DataTable, allowedLocationTypeName As String)
            Dim row As DataRow

            ' Add the column if it does not exists.
            If Not table.Columns.Contains(COLUMN_PRESENTATION_EDITABLE) Then
                table.Columns.Add(New DataColumn(COLUMN_PRESENTATION_EDITABLE, GetType(Boolean), ""))
            End If

            For Each row In table.Rows
                ' If the types are the same, then it is editable.
                Dim editable = False
                If row(COLUMN_LOCATION_TYPE).ToString.ToUpper().Equals(allowedLocationTypeName.ToUpper()) Then
                    editable = True
                End If

                row(COLUMN_PRESENTATION_EDITABLE) = editable
            Next
        End Sub

        ''' <summary>
        ''' Adds the column with the locked message to each column in the table.
        ''' </summary>
        Public Sub AddLocked(table As DataTable, lockedMessage As String)
            table.Columns.Add(New DataColumn("PresentationLocked", GetType(String), String.Format("'{0}'", lockedMessage)))
        End Sub

        ' 'AddLocked' adds the lock message as an expression column - this means it has to be the same for each
        ' row, and can't be changed. This isn't always what we want, so this does the same thing, but adds the
        ' message to each row so that it can be changed later on, on a row by row basis
        Public Sub AddLockedAllRows(table As DataTable, lockedMessage As String)
            Const LOCKED_COLUMN = "PresentationLocked"

            If Not table.Columns.Contains(LOCKED_COLUMN) Then
                table.Columns.Add(LOCKED_COLUMN, GetType(String))
            End If

            For Each row As DataRow In table.Rows
                row(LOCKED_COLUMN) = lockedMessage
            Next
        End Sub

        Public Sub AddApprovalCheck(table As DataTable, locationId As Int32, editPermissions As Boolean, checkBoxColumnId As String,
            editableColumnName As String, forceDisabled As Boolean)

            AddApprovalCheck(table, locationId, editPermissions, checkBoxColumnId, editableColumnName, Nothing, 0, forceDisabled)
        End Sub

        ''' <summary>
        ''' Read the row and get the edit permissions for the user. Use a cache mechanism to reduce hits to database.
        ''' </summary>
        Private Function GetRowLocationEditPermission(row As DataRow, userId As Int32, session As ReportSession,
            cache As IDictionary(Of Integer, Boolean)) As Boolean

            Dim editPermissions = False
            Dim rowLocationId As Int32
            Dim locationRetrieved As Boolean

            ' If the session isn't supplied, this call does not support row level permissions.
            If Not session Is Nothing Then
                ' Find the location first from the row.
                If row.Table.Columns.Contains("LocationId") Then
                    locationRetrieved = Int32.TryParse(row("LocationId").ToString(), rowLocationId)
                End If

                If locationRetrieved Then
                    If cache.ContainsKey(rowLocationId) Then
                        ' Get from the cache if it exists.
                        editPermissions = cache(rowLocationId)
                    Else
                        ' Retrieve from database and store it
                        editPermissions = session.DalSecurityLocation.IsBhpbioUserInLocation(userId, rowLocationId)
                        cache.Add(rowLocationId, editPermissions)
                    End If
                End If
            End If

            Return editPermissions
        End Function

        Public Function IsEditable(editPermissions As Boolean, row As DataRow, editableColumnName As String, rowLocationEditPermission As Boolean,
            table As DataTable) As Boolean

            Return ((editPermissions Or rowLocationEditPermission) And (IsRowEditable(row, table, editableColumnName)))
        End Function

        Private Function IsRowEditable(row As DataRow, table As DataTable, editableColumnName As String) As Boolean
            Return ((Not table.Columns.Contains(editableColumnName)) Or (table.Columns.Contains(editableColumnName) AndAlso
                                                                    Not IsDBNull(row(editableColumnName)) AndAlso
                                                                    Convert.ToBoolean(row(editableColumnName)) = True))
        End Function

        ''' <summary>
        ''' The row("PresentationLocked") value is used to determine whether
        ''' or not the checkbox will be enabled. Now that we have a drill down tree we need to remove the value in the
        ''' row("PresentationLocked") in some circumstances, but not others. The only differentiation I can find is the
        ''' value in row("PresentationLocked"). So, I'm forced to empty the row("PresentationLocked") value under certain
        ''' conditions, and *only for certain row("PresentationLocked") values*.
        '''
        ''' This method confirms whether or not the Checkbox should've been disabled due to not all blastblocks/F1/F2/F3 being
        ''' approved at the current level, not the parent level.
        ''' </summary>
        ''' <param name="presentationLocked"></param>
        ''' <param name="locationId"></param>
        ''' <param name="reportSession"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Private Function IsApprovalLocked(presentationLocked As String, locationId As Int32, reportSession As ReportSession) As Boolean
            Dim startDate As DateTime = reportSession.RequestParameter.StartDate

            Select Case presentationLocked
                Case "Not all Blastblocks for this pit have been approved."
                    If (Report.Data.ApprovalData.GetDigblockApprovalValid(reportSession, locationId, startDate)) Then
                        Return False
                    End If
                Case "All F1.5 data for this site must be approved."
                    If (Report.Data.ApprovalData.IsAllTagGroupApproved(reportSession, locationId, startDate, "F15Factor")) Then
                        Return False
                    End If
                Case "All F1 data for this pit must be approved."
                    If (Report.Data.ApprovalData.IsAllTagGroupApproved(reportSession, locationId, startDate, "F1Factor")) Then
                        Return False
                    End If
                Case "All F2 data for this site must be approved."
                    If (Report.Data.ApprovalData.IsAllTagGroupApproved(reportSession, locationId, startDate, "F2Factor")) Then
                        Return False
                    End If

                    ' These two messages only occur for F1, so they need to be treated as a special case, otherwise when the user expands the
                    ' location tree they can approve things they shouldn't be allowed to. If either of these errors happen, then we need
                    ' to check BOTH contitions before unlocking the record.
                    '
                    ' This results in another bug where the record is locked, but the message shown in incorrect. Will just have to live with
                    ' this for now, until we have time to refactor the approvals so that a calculation can work with mulitple approval inputs,
                    ' instead of just expecting a linear flow.
                Case "All Other Material Movement data for this pit must be approved.", "All Geology Model data for this pit must be approved."
                    If Report.Data.ApprovalData.IsAllTagGroupApproved(reportSession, locationId, startDate, "F1Factor", "F1GeologyModel") _
                        AndAlso Report.Data.ApprovalData.IsAllTagGroupApproved(reportSession, locationId, startDate, "OtherMaterial") Then
                        Return False
                    End If
            End Select

            Return True
        End Function

        ''' <summary>
        ''' Determines if the current row is locked due to approval at a higher level.
        ''' </summary>
        ''' <param name="presentationLocked"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Private Function IsLockedByParent(presentationLocked As String) As Boolean
            Return Not (presentationLocked = "Not all Blastblocks for this pit have been approved." _
                Or presentationLocked = "All F1 data for this pit must be approved." _
                Or presentationLocked = "All F1.5 data for this site must be approved." _
                Or presentationLocked = "All F2 data for this site must be approved." _
                Or presentationLocked = "All Other Material Movement data for this site must be approved." _
                Or presentationLocked = "All Other Material Movement data for this pit must be approved." _
                Or presentationLocked = "All Geology Model data for this pit must be approved.")
        End Function

        ''' <summary>
        '''
        ''' </summary>
        ''' <param name="table"></param>
        ''' <param name="locationId"></param>
        ''' <param name="editPermissions"></param>
        ''' <param name="checkBoxColumnId"></param>
        ''' <param name="editableColumnName"></param>
        ''' <param name="session"></param>
        ''' <param name="userId"></param>
        ''' <param name="forceDisabled">Force the approval control to be disabled regardless of user permissions</param>
        ''' <remarks>
        ''' TODO: Use Snowden.Common.Web.BaseHtmlControls.Tags to set up controls instead of hard-coded text. The .GetHtmlString() method can be used at the end to assign to the cell.
        '''</remarks>
        Public Sub AddApprovalCheck(table As DataTable, locationId As Int32, editPermissions As Boolean, checkBoxColumnId As String,
            editableColumnName As String, session As ReportSession, userId As Int32, forceDisabled As Boolean)

            Dim expression As String
            Dim row As DataRow
            ' text-align: centre doesn't work for some reason, it's slightly off to the right, so it was quicker to do this than to investigate as nothing was glaringly obvious
            Const IMG_TAG_TICK = "<IMG border=0 alt="""" src=""../images/sqlTick.gif"" style=""display: block; margin-left: auto; margin-right: auto; margin-top: -15px;"">"
            Const IMG_TAG_BOX = "<IMG border=0 alt="""" src=""../images/sqlBox.gif"" style=""display: block; margin-left: auto; margin-right: auto; margin-top: -15px;"">"
            Dim editable As Boolean
            Dim rowLocationEditPermission As Boolean
            Dim locationEditCache As New Dictionary(Of Int32, Boolean)
            Dim isApprovalLockedCacheDictionary As New Dictionary(Of String, Boolean)
            Dim isApprovalLockedValue As Boolean

            table.Columns.Add("ApprovedCheck", GetType(String), "")

            Dim tableContainsProductSizeAndTypeInformation = False

            If table.Columns.Contains(ColumnNames.PRODUCT_SIZE) And table.Columns.Contains("Type") Then
                tableContainsProductSizeAndTypeInformation = True
            End If

            For Each row In table.Rows
                Dim approved = False
                Dim approvedValid As Boolean = Not IsDBNull(row("Approved"))
                If approvedValid Then
                    approved = Convert.ToBoolean(row("Approved"))
                End If

                ' For lump and fines values, can only approve at the ratio level
                If (tableContainsProductSizeAndTypeInformation) Then
                    Dim rowType As Integer = -1
                    Int32.TryParse(row("Type").ToString, rowType)

                    ' approval is only value for TOTAL product size, LUMP and FINES ratios, or LUMP and FINES Geology model
                    approvedValid = (approvedValid And (rowType = 0 OrElse
                                                        row(ColumnNames.PRODUCT_SIZE).ToString() = CalculationConstants.PRODUCT_SIZE_TOTAL) OrElse
                                                        row("CalcId").ToString() = ModelGeology.CalculationId)
                End If

                If (forceDisabled) Then
                    editable = False
                Else
                    ' If the call is set up to handle checking row level permissions, do a check to see if the user can edit this row.
                    ' This is new with the ability to drill into a tree and have some rows editable and others not.
                    rowLocationEditPermission = GetRowLocationEditPermission(row, userId, session, locationEditCache)
                    editable = IsEditable(editPermissions, row, editableColumnName, rowLocationEditPermission, table)
                End If

                Dim enabled = True

                ' Row has been locked by the parent level's blastblock/F1/F2/F3 data being (or not being) approved
                If (table.Columns.Contains("PresentationLocked") AndAlso
                   row("PresentationLocked").ToString() <> "") AndAlso
                   table.Columns.Contains("LocationId") AndAlso
                   Not IsDBNull(row("LocationId")) AndAlso
                   Not session.RequestParameter Is Nothing Then

                    Dim rowLocationId As Int32 = Convert.ToInt32(row("LocationId").ToString)

                    Dim isApprovalLockedCacheKey As String = String.Format("{0}|{1}", row("PresentationLocked").ToString, rowLocationId)

                    If Not isApprovalLockedCacheDictionary.TryGetValue(isApprovalLockedCacheKey, isApprovalLockedValue) Then
                        isApprovalLockedValue = IsApprovalLocked(row("PresentationLocked").ToString, rowLocationId, session)
                        isApprovalLockedCacheDictionary(isApprovalLockedCacheKey) = isApprovalLockedValue
                    End If

                    If Not isApprovalLockedValue Then
                        row("PresentationLocked") = String.Empty
                    End If
                End If

                If (table.Columns.Contains("PresentationLocked") AndAlso row("PresentationLocked").ToString() <> "") Then
                    Dim lockedMessage As String = row("PresentationLocked").ToString()
                    ' prevent chicken & egg scenario - disable checkbox only if not approved currently, the editable flag
                    ' will prevent lower tier items becoming approvable
                    If (Not approved Or IsLockedByParent(lockedMessage)) Then
                        enabled = False
                    End If
                End If

                If Not approvedValid Then
                    expression = ""
                ElseIf approved Then
                    expression = IMG_TAG_TICK
                Else
                    expression = IMG_TAG_BOX
                End If

                ' I *think* this is used to help with the Approve / Unapprove buttons at the top of the page, so refactoring/leaving in for now.
                If editable Then
                    Dim uniqueId As String = Guid.NewGuid().ToString().Replace("-", "")

                    ' Add an extra hidden field to state that there is a field to be approved.
                    If enabled Then
                        expression = String.Format("{0}<input type=""hidden"" name=""{1}"" id=""{1}"" value=""{2}""/>", expression, "approvedTagId_" & uniqueId, row(checkBoxColumnId).ToString())
                        ' Add a *second* extra field... is this right? Looks more like it should use one or the other...
                        If row.Table.Columns.Contains("LocationId") Then
                            expression = String.Format("{0}<input type=""hidden"" name=""{1}"" id=""{1}"" value=""{2}""/>", expression, "approvedLocation_" & uniqueId, row("LocationId").ToString())
                        End If
                    End If
                End If

                row("ApprovedCheck") = expression
            Next
        End Sub
    End Module
End Namespace