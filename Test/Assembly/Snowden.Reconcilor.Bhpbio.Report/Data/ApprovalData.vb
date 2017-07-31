Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports System.Text
Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal

Namespace Data

    Public NotInheritable Class ApprovalData
        Public Const ColumnNameEditable As String = "PresentationEditable"
        Public Const ColumnNameLocked As String = "PresentationLocked"

        Private Sub New()
        End Sub

        ''' <summary>
        ''' Sets the Presentation Editable on the calculation set. Accounts for the location id's of each result or if 
        ''' the location id is not set (dont include children) then it will used the null location id. 
        ''' </summary>
        ''' <param name="utilityDal">Requires a valid connected Utility DAL object</param>
        ''' <param name="calcSet">The set of calculation results to add the tag to.</param>
        ''' <param name="validLocationType">The location type required for it to be valid</param>
        ''' <param name="nullLocationId">If the location ID is null, use this one instead. This will be used when children are not included.</param>
        ''' <remarks></remarks>
        Public Shared Sub AssignEditableOnLocationType(ByVal utilityDal As SqlDalUtility,
            ByVal calcSet As CalculationSet, ByVal validLocationType As String, ByVal nullLocationId As Int32?)

            Dim calcResult As CalculationResult
            Dim locationsValiditity As New Dictionary(Of Int32?, Boolean)
            Dim allLocations As IEnumerable(Of Int32?)
            Dim resolvedLocationType As String
            Dim nullableValid As Boolean = False

            ' Parse each result for each location to load into the dictionary.
            allLocations = (From c In calcSet
                            From id In c.LocationIdCollection
                            Select id).Distinct()

            For Each location In allLocations
                resolvedLocationType = "" ' Reset the location type.

                If location.HasValue Then
                    'If location is valid then just add in to the dictionary if it is valid.
                    resolvedLocationType = FactorLocation.GetLocationTypeName(utilityDal, location.Value)

                    ' Add the result to the dictionary and if it matches the location type.
                    locationsValiditity.Add(location, (validLocationType.ToUpper() = resolvedLocationType.ToUpper()))
                Else
                    ' If the location is null but the null location id has been specified, get that location type 
                    ' and assign it to a boolean just for nulled locations. Can't add nulls to dictionary.
                    If nullLocationId.HasValue Then
                        resolvedLocationType = FactorLocation.GetLocationTypeName(utilityDal, nullLocationId.Value)
                        nullableValid = (validLocationType.ToUpper() = resolvedLocationType.ToUpper())
                    End If
                End If
            Next

            For Each calcResult In calcSet
                For Each valid In locationsValiditity
                    calcResult.Tags.Add(New CalculationResultTag(ColumnNameEditable, valid.Key,
                        GetType(String), valid.Value))
                Next
                calcResult.Tags.Add(New CalculationResultTag(ColumnNameEditable, DirectCast(Nothing, Int32?),
                        GetType(String), nullableValid))
            Next

        End Sub


        Public Shared Sub AddApprovalTagLocation(ByVal taggedSet As CalculationSet, ByVal locationId As Int32?,
         ByVal childLocations As Boolean, ByVal dalUtility As Core.Database.DalBaseObjects.IUtility)
            Dim result As CalculationResult
            Dim locationTypeDescription As String
            Dim locations As Generic.IList(Of String)
            Dim expandable As Boolean

            locationTypeDescription = Data.FactorLocation.GetLocationTypeName(dalUtility, locationId)
            locations = Data.FactorLocation.GetLocationTypeDescriptionParentList(locationTypeDescription, dalUtility)

            For Each result In taggedSet.GetAllParentResults()
                ' Need to check for the location above because it is the parent which is being checked.
                If result.CalcId = Calc.F1.CalculationId Or result.CalcId = Calc.F15.CalculationId Then
                    ' F1 and F1.5 both expand at the same level
                    ' leaving commented as we expect they'll want this functionality back
                    'expandable = (Not childLocations And Not locations.Contains("pit")) Or (childLocations And Not locations.Contains("site"))
                    expandable = False
                    result.Tags.Add(New CalculationResultTag("LocationExpandable", GetType(Boolean), expandable))
                ElseIf result.CalcId = Calc.F2.CalculationId Then
                    ' leaving commented as we expect they'll want this functionality back
                    'expandable = (Not childLocations And Not locations.Contains("site")) Or (childLocations And Not locations.Contains("hub"))
                    expandable = False
                    result.Tags.Add(New CalculationResultTag("LocationExpandable", GetType(Boolean), expandable))
                ElseIf result.CalcId = Calc.F25.CalculationId Then
                    ' leaving commented as we expect they'll want this functionality back
                    'expandable = (Not childLocations And Not locations.Contains("hub")) Or (childLocations And Not locations.Contains("company"))
                    result.Tags.Add(New CalculationResultTag("LocationExpandable", GetType(Boolean), expandable))
                    expandable = False
                ElseIf result.CalcId = Calc.F3.CalculationId Then
                    ' leaving commented as we expect they'll want this functionality back
                    'expandable = (Not childLocations And Not locations.Contains("hub")) Or (childLocations And Not locations.Contains("company"))
                    expandable = False
                    result.Tags.Add(New CalculationResultTag("LocationExpandable", GetType(Boolean), expandable))
                ElseIf result.CalcId = Calc.ModelGeology.CalculationId Then
                    ' leaving commented as we expect they'll want this functionality back
                    'expandable = (Not childLocations And Not locations.Contains("pit")) Or (childLocations And Not locations.Contains("site"))
                    expandable = False
                    result.Tags.Add(New CalculationResultTag("LocationExpandable", GetType(Boolean), expandable))
                End If
            Next
        End Sub

#Region "Unfactored Classes"


        Public Shared Function GetPitApprovalMovementsExist(ByVal session As Types.ReportSession,
         ByVal locationId As Int32?, ByVal month As DateTime) As Boolean
            Dim movementsExist As Boolean =
             session.DalApproval.IsBhpbioApprovalPitMovedDate(locationId, month)

            Return movementsExist
        End Function


        Public Shared Function GetOtherMovementApprovalValid(ByVal session As Types.ReportSession,
         ByVal locationId As Int32?, ByVal month As DateTime) As Boolean
            Dim movementsExist As Boolean =
             session.DalApproval.IsBhpbioApprovalOtherMovementDate(locationId, month)

            Return movementsExist
        End Function

        Public Shared Function GetDigblockApprovalValid(ByVal session As Types.ReportSession,
         ByVal locationId As Int32?, ByVal month As DateTime) As Boolean
            Dim allApproved As Boolean =
             session.DalApproval.IsBhpbioApprovalAllBlockLocationDate(locationId, month)

            Return allApproved
        End Function

        Public Shared Function IsAnyTagGroupApproved(ByVal session As Types.ReportSession,
         ByVal locationId As Int32?, ByVal month As DateTime,
         ByVal tagGroupId As String, Optional ByVal tagId As String = Nothing, Optional ByVal CheckChildren As Boolean = False) As Boolean
            Dim approvalData As DataTable = session.CreateApprovedData(month).Tables("Approval")

            Dim queryString = "TagGroupId = '{0}' And LocationId = {1}"

            ' for some reason the GeologyModel is part of the F1Factor in the database, but we actually don't
            ' want to look at it this way when looking to see if any approvals have happened. The correct solution
            ' here is to change the tag group for the geo model, but this could have many other side effects, so
            ' we just have to ignore it here as a special case. This code will still work properly if it is changed
            ' later.
            If tagGroupId = "F1Factor" And tagId Is Nothing Then
                queryString += " And TagId Not Like 'F1GeologyModel%'"
            End If

            ' in some cases we want to search not just the entire tag group, but actually for a specific tag
            ' as well. Once do this search if the optional parameter is set though
            If Not tagId Is Nothing Then
                queryString += String.Format(" And TagId = '{0}'", tagId)
            End If

            If (Not session.RequestParameter Is Nothing AndAlso session.RequestParameter.ChildLocations) OrElse CheckChildren Then
                ' when we are reporting with child locations, we need to check to see if any of the child locations
                ' have been approved as well. This doesn't come through in the 'Approved' feild because it will be
                ' false until *every* child location has been approved. 'NumberApproved' has the data we want.
                '
                ' IsAllTagGroupApproved doesn't need special handling for this because the stored proc will automatically
                ' set Approved to true when all the children are approved
                queryString += " And (Approved = True Or NumberApproved > 0)"
            Else
                queryString += " And Approved = True"
            End If

            Dim rows As DataRow() = approvalData.Select(String.Format(queryString, tagGroupId, locationId.ToString()))
            Return (rows.Count > 0)
        End Function

        Public Shared Function IsAllTagGroupApproved(ByVal session As Types.ReportSession,
         ByVal locationId As Int32?, ByVal month As DateTime,
         ByVal tagGroupId As String, Optional ByVal tagId As String = Nothing) As Boolean
            Dim approvalData As DataTable = session.CreateApprovedData(month).Tables("Approval")

            Dim rows As DataRow()
            Dim queryString As String = "TagGroupId = '{0}' And LocationId = {1} And Approved = False"

            ' the Lump + Fines tags still get created, even before the cut over date, we need to ignore
            ' it though when looking to see if something is approved, otherwise the system will always think
            ' that the required calculations are unapproved, and the user won't be able to fix it, because
            ' these measures are not shown.
            If (month < session.GetLumpFinesCutoverDate) Then
                queryString += " And Not (TagId Like '%Lump' Or TagId Like '%Fines')"
            End If

            ' in some cases we want to search not just the entire tag group, but actually for a specific tag
            ' as well. Once do this search if the optional parameter is set though
            If Not tagId Is Nothing Then
                queryString += String.Format(" And TagId = '{0}'", tagId)
            End If

            rows = approvalData.Select(String.Format(queryString, tagGroupId, locationId.ToString()))
            Return (rows.Count = 0)
        End Function

        <Obsolete("This method is deprecated, use 'Data.ApprovalData.IsAllTagGroupApproved' instead.")>
        Public Shared Function IsAllF1Approved(ByVal session As Types.ReportSession, ByVal locationId As Int32?, ByVal month As DateTime) As Boolean
            Dim allApproved As Boolean = session.DalApproval.IsBhpbioAllF1Approved(locationId, month)
            Return allApproved
        End Function

        <Obsolete("This method is deprecated, use 'Data.ApprovalData.IsAllTagGroupApproved' instead.")>
        Public Shared Function IsBhpbioAllOtherMovementsApproved(ByVal session As Types.ReportSession,
                    ByVal locationId As Int32?, ByVal month As DateTime) As Boolean
            Dim allApproved As Boolean = session.DalApproval.IsBhpbioAllOtherMovementsApproved(locationId, month)
            Return allApproved
        End Function

        ''' <summary>
        ''' Returns the Denormalized form of the sign off users.
        ''' </summary>
        Private Shared Function GetSignOffDenorm(ByVal approvalData As DataSet, ByVal tagId As String, ByVal locationId As Int32?) As String

            Dim signOff As DataTable = approvalData.Tables("SignOff")
            Dim rows As DataRow()
            Dim SignOffDate As Date = Date.MinValue
            Dim user As New StringBuilder("")

            rows = signOff.Select(String.Format("TagId = '{0}' And LocationId = {1}", tagId, locationId))

            For Each row In rows
                user.Append(row("FirstName").ToString() & " " & row("LastName").ToString() & ", ")
            Next

            If user.Length > 2 Then
                user.Remove(user.Length - 2, 2)
            End If

            Return user.ToString()
        End Function

        ''' <summary>
        ''' Returns the Denormalized form of the sign off date users.
        ''' </summary>
        Private Shared Function GetSignOffDateDenorm(ByVal approvalData As DataSet, ByVal tagId As String, ByVal locationId As Int32?) As DateTime?

            Dim signOff As DataTable = approvalData.Tables("SignOff")
            Dim SignOffDate As Date? = Nothing
            Dim rows As DataRow() = signOff.Select(String.Format("TagId = '{0}' And LocationId = {1}", tagId, locationId))

            ' lets get the data through linq, instead of by looping through the table, as this is more standard
            ' for .net now.
            '
            ' First we reduce the dataset to just a list of date strings
            ' then remove the null values
            ' then convert everything to a date time
            ' then get the max value
            Dim SignOffDates = rows.AsEnumerable().
                Select(Function(row) row("SignOffDate").ToString()).
                Where(Function(d) Not String.IsNullOrEmpty(d)).
                Select(Function(d) Convert.ToDateTime(d))

            If SignOffDates.Count > 0 Then
                SignOffDate = SignOffDates.Max()
            End If

            Return SignOffDate
        End Function

        ' The default AddApprovalFromTags method doesn't work properly if the data spans mulitple months
        ' - it will only get the data for the first month, and copy it to all months for that tag. This method will
        ' get the approvals for all months in the dataset between the start and end dates
        Public Shared Sub AddApprovalFromTagsForMulitpleMonths(ByVal session As Types.ReportSession, ByVal data As DataTable)
            Dim currentMonth As DateTime = session.RequestParameter.StartDate

            While currentMonth < session.RequestParameter.EndDate
                AddApprovalFromTags(session, data, currentMonth, True, True)
                currentMonth = currentMonth.AddMonths(1)
            End While

        End Sub

        Public Shared Sub AddApprovalFromTags(ByVal session As Types.ReportSession, ByVal data As DataTable)
            AddApprovalFromTags(session, data, session.RequestParameter.StartDate)
        End Sub

        Public Shared Sub AddApprovalFromTags(ByVal session As Types.ReportSession, _
         ByVal data As DataTable, ByVal month As DateTime, Optional ByVal MatchDates As Boolean = False, Optional ByVal MapApprovals As Boolean = False)
            Dim approvaldata As DataSet = session.CreateApprovedData(month)
            Dim row As DataRow
            Dim approvalRows As DataRow()
            Dim locationId As Int32
            Dim approvedColumnName As String = "Approved"
            Dim signOffColumnName As String = "SignOff"
            Dim signoffDateColumnName As String = "SignOffDate"

            ' Get a list of TagId -> ApprovalTagId mappings. See the comments on GetApprovalMappings() for why this is necessary.
            Dim approvalMappings As List(Of BhpbioApprovalMapping) = GetApprovalMappings()

            If Not data.Columns.Contains(approvedColumnName) Then
                data.Columns.Add(New DataColumn(approvedColumnName, GetType(Boolean), ""))
            End If

            If Not data.Columns.Contains(signOffColumnName) Then
                data.Columns.Add(New DataColumn(signOffColumnName, GetType(String), ""))
            End If

            If Not data.Columns.Contains(signoffDateColumnName) Then
                data.Columns.Add(New DataColumn(signoffDateColumnName, GetType(Date), ""))
            End If

            For Each row In data.Rows
                ' if the match dates parameter is set, then we want to explicitly check that the DateFrom field in the
                ' data table matches the approval month, if it doesn't (for this row), just skip setting the data. But
                ' continue to the next row in the table, as there might be others where the dates match
                If MatchDates AndAlso CType(row("DateFrom"), DateTime).Date <> month.Date Then
                    Continue For
                End If

                Dim approvalTagId As String = row("TagId").ToString()

                ' If a mapping exists for this tag, then we want to switch the TagId from the table to use the mapped
                ' ApprovalTagId for looking up the approval value. This should only happen in a minority of cases
                ' - most of the time the TagId in the datatable is the one that is entered into the approval table
                '
                ' This mapping has to be optional, because otherwise the approval screens will not work properly -
                ' it should only be activated for reporting
                If MapApprovals AndAlso approvalMappings.Any(Function(a) a.TagId = approvalTagId) Then
                    approvalTagId = approvalMappings.First(Function(a) a.TagId = approvalTagId).ApprovalTagId
                End If

                If Int32.TryParse(row("LocationId").ToString(), locationId) Then
                    If Not approvalTagId Is Nothing AndAlso approvalTagId.Length > 0 Then
                        approvalRows = approvaldata.Tables("Approval").Select(String.Format("LocationId = {0} And TagId = '{1}'", locationId.ToString(), approvalTagId))
                        If approvalRows.Length = 1 Then
                            row(approvedColumnName) = Convert.ToBoolean(approvalRows(0)("Approved"))
                            row(signOffColumnName) = GetSignOffDenorm(approvaldata, approvalTagId, locationId)

                            Dim signOffDate = GetSignOffDateDenorm(approvaldata, approvalTagId, locationId)
                            If signOffDate.HasValue AndAlso Not String.IsNullOrEmpty(signOffColumnName) Then
                                row(signoffDateColumnName) = signOffDate.Value
                            End If

                        End If
                    End If
                End If
            Next
        End Sub

        ' This method returns a list of TagIds that get their approval from somewhere else. The TagId is the id of the calculation item
        ' in the datatable, and the ApprovalTagId is the TagId it should looked at to find out if it is approved.
        '
        ' I am just hardcoding these values here for now, as there are so few of them, but if we need to add lots more later on, due to 
        ' changes required for moisture and density, then these mapping should be moved out to a table in the database.
        Public Shared Function GetApprovalMappings() As List(Of BhpbioApprovalMapping)
            Dim approvalMappings As List(Of BhpbioApprovalMapping) = New List(Of BhpbioApprovalMapping)

            ' the Hub + Site post crusher stockpile deltas don't have a checkbox on the approval screen, or any enteries in the approval
            ' table, so we have to look at the parent tag (F25PostCrusherStockpileDelta) to work out if they have been approved or not
            ' otherwise they will always appear as unapproved
            approvalMappings.Add(New BhpbioApprovalMapping() With {.TagId = "F25HubPostCrusherStockpileDelta", .ApprovalTagId = "F25PostCrusherStockpileDelta"})
            approvalMappings.Add(New BhpbioApprovalMapping() With {.TagId = "F25SitePostCrusherStockpileDelta", .ApprovalTagId = "F25PostCrusherStockpileDelta"})

            ' geology model is a special case, since it gets approved as part of the F1, even though it really isnt in
            ' that calculation, so in order for some of the data exports to work properly, we will conver that tag name if it 
            ' gets handed in
            approvalMappings.Add(New BhpbioApprovalMapping() With {.TagId = "GeologyModel", .ApprovalTagId = "F1GeologyModel"})

            ' The H2O As Dropped and As Shipped variations on models are approved with the model approval in F1 or F15
            approvalMappings.Add(New BhpbioApprovalMapping() With {.TagId = "GeologyModelH2OAsDropped", .ApprovalTagId = "F1GeologyModel"})
            approvalMappings.Add(New BhpbioApprovalMapping() With {.TagId = "GeologyModelH2OAsShipped", .ApprovalTagId = "F1GeologyModel"})
            approvalMappings.Add(New BhpbioApprovalMapping() With {.TagId = "MiningModelH2OAsDropped", .ApprovalTagId = "F1MiningModel"})
            approvalMappings.Add(New BhpbioApprovalMapping() With {.TagId = "MiningModelH2OAsShipped", .ApprovalTagId = "F1MiningModel"})
            approvalMappings.Add(New BhpbioApprovalMapping() With {.TagId = "GradeControlModelH2OAsDropped", .ApprovalTagId = "F1GradeControlModel"})
            approvalMappings.Add(New BhpbioApprovalMapping() With {.TagId = "GradeControlModelH2OAsShipped", .ApprovalTagId = "F1GradeControlModel"})
            approvalMappings.Add(New BhpbioApprovalMapping() With {.TagId = "ShortTermGeologyModelH2OAsDropped", .ApprovalTagId = "F15ShortTermGeologyModel"})
            approvalMappings.Add(New BhpbioApprovalMapping() With {.TagId = "ShortTermGeologyModelH2OAsShipped", .ApprovalTagId = "F15ShortTermGeologyModel"})

            ' On F1 Approval, indicate that Actual Mined (H-Value) is approved
            approvalMappings.Add(New BhpbioApprovalMapping() With {.TagId = "F2DensityActualMined", .ApprovalTagId = "F1Factor"})

            ' The Grade Control Model All Material Calc is locked away with F1GradeControlModel
            approvalMappings.Add(New BhpbioApprovalMapping() With {.TagId = "F2DensityGradeControlModel", .ApprovalTagId = "F1GradeControlModel"})

            Return approvalMappings
        End Function

#End Region

    End Class

    Public Class BhpbioApprovalMapping
        Private _tagId As String = Nothing
        Private _approvalTagId As String = Nothing

        Public Property TagId() As String
            Get
                Return _tagId
            End Get
            Set(ByVal value As String)
                _tagId = value
            End Set
        End Property

        Public Property ApprovalTagId() As String
            Get
                Return _approvalTagId
            End Get
            Set(ByVal value As String)
                _approvalTagId = value
            End Set
        End Property

    End Class

End Namespace
