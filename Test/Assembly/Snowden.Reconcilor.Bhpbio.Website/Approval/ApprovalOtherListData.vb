Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Approval

    Public Class ApprovalOtherListData
        Private Const OtherDataLocationType As String = "PIT"

        Public Shared Function CreateApprovalDigblockList(ByVal session As ReportSession, _
         ByVal approvalMonth As DateTime, ByVal locationId As Int32, ByVal includeChildren As Boolean, ByVal parentNodeRowId As String, _
         ByVal nodeLevel As Int32, ByVal userId As Int32, _
         ByVal forceApprovalCheckDisabled As Boolean) As DataTable
            Dim approvalOtherList As DataTable
            Dim editable As Boolean = False
            Dim totalRows As New Collection()
            Dim blankRow As DataRow
            Dim lockedMessage As String = GetLockedMessage(session, approvalMonth, locationId)

            approvalOtherList = session.DalApproval.GetBhpbioApprovalOtherMaterial( _
             locationId, approvalMonth, includeChildren)

            For Each row As DataRow In approvalOtherList.Rows
                If IsDBNull(row("ParentMaterialTypeId")) Then
                    totalRows.Add(row)
                End If
            Next

            For Each row As DataRow In totalRows
                ' If it is not the last row of this location id
                If row.Table.Rows.IndexOf(row) <> row.Table.Rows.IndexOf(GetLastLocationRow(row)) Then
                    blankRow = approvalOtherList.NewRow()
                    blankRow(COLUMN_LOCATION_ID) = row(COLUMN_LOCATION_ID)
                    approvalOtherList.Rows.InsertAt(blankRow, approvalOtherList.Rows.IndexOf(row) + 1)
                End If
            Next

            Report.Data.ApprovalData.AddApprovalFromTags(session, approvalOtherList, approvalMonth)

            ApprovalCheck.AddPresentationEditableCheck(approvalOtherList, OtherDataLocationType)
            ApprovalCheck.AddLockedAllRows(approvalOtherList, lockedMessage)
            UnlockForUnapproval(approvalOtherList)

            ApprovalCheck.AddApprovalCheck(approvalOtherList, locationId, _
                False, "TagId", COLUMN_PRESENTATION_EDITABLE, session, userId, forceApprovalCheckDisabled)

            CreatePresentationTable(approvalOtherList, session, includeChildren, parentNodeRowId,
                locationId, approvalMonth, nodeLevel)

            Return approvalOtherList
        End Function

        ' If there are some blastblocks that are unapproved, then all the other movements checkboxes will be locked, however this 
        ' is not actually what we want, because it can results in a circular lock. The user should always be able unapprove OM records
        ' regardless of the BB situation. This method unlocks those rows that are approved, if they have been locked because of the
        ' Blastblocks
        Protected Shared Sub UnlockForUnapproval(ByRef table As DataTable)
            If Not table.Columns.Contains("PresentationLocked") Then
                Return
            End If

            For Each row As DataRow In table.Rows
                ' look for rows that are locked because of the Blastblocks, and unlock them if they are approved. It is pretty bad to
                ' be looking for these based off the lock message, but this is the way it is done in general in the app, and there is
                ' no time now to refactor this to some sort of enum column
                If row("PresentationLocked").ToString.EndsWith("as blast block data has not been approved.") AndAlso _
                    Not IsDBNull(row("Approved")) AndAlso Convert.ToBoolean(row("Approved")) = True Then

                    row("PresentationLocked") = DBNull.Value
                End If
            Next
        End Sub

        Private Shared Function CreatePresentationTable(ByVal presentation As DataTable, _
         ByVal session As ReportSession, ByVal childLocations As Boolean, ByVal parentNodeRowId As String, _
         ByVal locationId As Int32, ByVal approvalMonth As DateTime, ByVal nodeLevel As Int32) As DataTable
            Dim expandImage As String = "<img src=""../images/plus.png"" id=""Image_{0}"" onclick=""ToggleApprovalOtherNode('Node_{0}', {1}, {2}, '{3}')"">"
            Dim expandImageSpaces As String = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
            Dim row As DataRow
            Dim rowLocationId As Int32
            Dim lastLocationRow As DataRow
            Dim lastLocationNodeId As String = ""
            Dim locationType As String
            Dim materialName As String

            presentation.Columns.Add(New DataColumn(COLUMN_CALC_BLOCK_TOP, GetType(Boolean), ""))
            presentation.Columns.Add(New DataColumn(COLUMN_CALC_BLOCK_MID, GetType(Boolean), ""))

            If childLocations Then
                AddLocationHeadings(presentation) ' Add the heading rows if there are children.
            End If
            AssignRowNodeId(presentation, parentNodeRowId) ' Assign a row id to all the table's rows

            ' Parse each row and modify each column.
            For Each row In presentation.Rows
                row(COLUMN_CALC_BLOCK_MID) = True ' each row has a side. Will be formated later by the tree shared functions.

                If Not Int32.TryParse(row(COLUMN_LOCATION_ID).ToString(), rowLocationId) Then
                    rowLocationId = locationId
                End If

                locationType = row(COLUMN_LOCATION_TYPE).ToString().ToUpper()
                materialName = row(COLUMN_MATERIAL_NAME).ToString()

                ' Add the grey line on top if it is the top.
                If IsLocationTopRow(row) Then
                    row(COLUMN_CALC_BLOCK_TOP) = True
                End If

                ' If it is the top location and not the lowest level, add an expand button.
                If IsLocationTopRow(row) AndAlso locationType <> OtherDataLocationType Then
                    ' Get the last location's node id so that we can use it to expand.
                    lastLocationRow = GetLastLocationRow(row)
                    If Not lastLocationRow Is Nothing Then
                        lastLocationNodeId = lastLocationRow(COLUMN_NODE_ROW_ID).ToString().Replace("Node_", "")
                    End If

                    ' Add the expand image html in front of the top node.
                    row(COLUMN_MATERIAL_NAME) = String.Format(expandImage, lastLocationNodeId, nodeLevel + 1, _
                        rowLocationId, approvalMonth) & materialName
                Else
                    ' Add the spacing for the expand image.
                    row(COLUMN_MATERIAL_NAME) = String.Format("{0}{1}", expandImageSpaces, materialName)
                End If
            Next

            Return presentation
        End Function


        ''' <summary>
        ''' Adds the location headers to the presentation table.
        ''' </summary>
        Private Shared Sub AddLocationHeadings(ByVal table As DataTable)
            Dim locationHeader As DataRow

            ' Parse each row from the bottom up, adding a new heading for each location change.
            For i = table.Rows.Count - 1 To 0 Step -1
                If IsLocationTopRow(table(i)) Then
                    ' Create the header row and put it in.
                    locationHeader = table.NewRow()
                    locationHeader(COLUMN_MATERIAL_NAME) = String.Format("<b>{0}</b>", table(i)(COLUMN_LOCATION_NAME))
                    locationHeader(COLUMN_LOCATION_ID) = table(i)(COLUMN_LOCATION_ID)
                    locationHeader(COLUMN_LOCATION_TYPE) = table(i)(COLUMN_LOCATION_TYPE)
                    table.Rows.InsertAt(locationHeader, i)
                End If
            Next
        End Sub

        ''' <summary>
        ''' Returns true if this row is the top of it's location.
        ''' </summary>
        Private Shared Function IsLocationTopRow(ByVal row As DataRow) As Boolean
            Dim rowPosition As Int32 = row.Table.Rows.IndexOf(row)
            Dim previousRow As DataRow = Nothing
            Dim topRow As Boolean = False

            ' Get the previous row
            If (rowPosition - 1 >= 0) Then
                previousRow = row.Table(rowPosition - 1)
            End If

            ' If there is no previous row, or the previous row is not the same location then it is the top row.
            topRow = previousRow Is Nothing OrElse _
                previousRow(COLUMN_LOCATION_ID).ToString() <> row(COLUMN_LOCATION_ID).ToString()

            Return topRow
        End Function

        ''' <summary>
        ''' Returns the datarow of the row which is last in the series of location ids.
        ''' </summary>
        Private Shared Function GetLastLocationRow(ByVal row As DataRow) As DataRow
            Dim i As Int32
            Dim startLocationId As String
            Dim dataRowId As String = ""
            Dim startRow As Int32 = row.Table.Rows.IndexOf(row)
            Dim lastRow As DataRow = Nothing

            startLocationId = row(COLUMN_LOCATION_ID).ToString()
            ' continue down the table rows from the starting point
            For i = startRow To row.Table.Rows.Count - 1

                If (i = row.Table.Rows.Count - 1) Then
                    ' If its the last row then assign this row
                    lastRow = row.Table.Rows(i)
                ElseIf (row.Table.Rows(i)(COLUMN_LOCATION_ID).ToString() <> startLocationId) Then
                    ' If the location has changed, grab the row before it.
                    lastRow = row.Table.Rows(i - 1)
                    Exit For
                End If
            Next

            Return lastRow
        End Function


        ''' <summary>
        ''' Assign a row ID to every row in the table
        ''' </summary>
        Private Shared Sub AssignRowNodeId(ByVal table As DataTable, ByVal parentNodeId As String)
            table.Columns.Add(New DataColumn(COLUMN_NODE_ROW_ID, GetType(String), ""))
            Dim row As DataRow
            Dim rowIdIncrementer As Int32 = 0

            For Each row In table.Rows
                ' Obtain the Node Row Id
                If parentNodeId = String.Empty Then
                    row(COLUMN_NODE_ROW_ID) = String.Format("Node_R{0}", rowIdIncrementer.ToString())
                Else
                    row(COLUMN_NODE_ROW_ID) = String.Format("{0}_R{1}", parentNodeId, rowIdIncrementer.ToString())
                End If
                rowIdIncrementer = rowIdIncrementer + 1
            Next
        End Sub

        ' This method is only used when getting the sublocations lock messages for OM - the parent level has its own checks elsewhere
        Private Shared Function GetLockedMessage(ByVal reportSession As ReportSession, _
         ByVal approvalMonth As DateTime, ByVal locationId As Int32) As String
            Dim lockedMessage As String = ""

            If Not Report.Data.ApprovalData.GetDigblockApprovalValid(reportSession, locationId, approvalMonth) Then
                lockedMessage = "Cannot approve other movements data as blast block data has not been approved."
            End If

            ' Check for F1 to stop it being editable. Must have no F1 approved.
            If Report.Data.ApprovalData.IsAnyTagGroupApproved(reportSession, locationId, approvalMonth, "F1Factor", Nothing, True) Then
                lockedMessage = "F1 Data has already been approved."
            End If

            Return lockedMessage
        End Function

        Public Shared Function OtherDisplayTable_ItemCallback(ByVal textData As String, _
         ByVal columnName As String, ByVal row As DataRow) As String
            Dim ReturnValue As String = textData.Trim
            Dim tonnes As Double

            If row("TagId").ToString = "" And columnName = "ApprovedCheck" Then
                ReturnValue = ""
            ElseIf row("TagId").ToString <> "" And ReturnValue = "" And _
             (columnName = "Geology" Or columnName = "Mining" Or columnName = "Actual" Or columnName = "Grade Control") Then
                ReturnValue = "0"
            End If

            If Double.TryParse(ReturnValue, tonnes) Then
                ReturnValue = (tonnes / 1000).ToString(Core.WebDevelopment.ReconcilorFunctions.SetNumericFormatDecimalPlaces(1))
            End If

            If IsDBNull(row("ParentMaterialTypeId")) Then
                If columnName = "ApprovalCheck" Then
                    ReturnValue = ""
                ElseIf columnName = "HaulageTotal" AndAlso row("MaterialName").ToString.ToLower.EndsWith("total:") Then
                    ReturnValue = String.Format("H: <b style='border:1px solid black; padding: 1px;'>{0}</b>", ReturnValue)
                Else
                    ReturnValue = "<b>" & ReturnValue & "</b>"
                End If
            End If

            If IsHightlightedValue(row, columnName) Then
                ReturnValue = String.Format("<span style='border: 1px solid red; padding: 1px 2px;'>{0}</span>", ReturnValue)
            End If

            Return ReturnValue
        End Function


        Public Shared Function IsHightlightedValue(ByRef row As DataRow, ByVal columnName As String) As Boolean
            Dim rowName As String = row("MaterialName").ToString.ToLower

            Return (columnName = "HauledToOreStockpile" AndAlso rowName.Contains("total non-ore")) Or _
                (columnName = "HauledToNonOreStockpile" AndAlso rowName.Contains("total ore")) Or _
                (columnName = "HauledToCrusher" AndAlso rowName.Contains("total non-ore"))

        End Function
    End Class
End Namespace
