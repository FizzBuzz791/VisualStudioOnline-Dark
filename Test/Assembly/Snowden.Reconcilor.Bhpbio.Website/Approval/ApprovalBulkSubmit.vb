Imports System.Data.SqlClient
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates

Namespace Approval
    Public Class ApprovalBulkSubmit
        Inherits ReconcilorAjaxPage

#Region "Properties"
        Private Property DalApproval As Database.DalBaseObjects.IApproval
        Private Property ApprovalType As Boolean
        Private Property IsBulk As Boolean
        Private Property UserId As Integer
        Private Property LocationId As Integer
        Private Property LocationTypeId As Integer
        Private Property MonthValueFrom As DateTime
        Private Property MonthValueTo As DateTime
        Private Property HighestLocationType As Integer
        Private Property LowestLocationType As Integer

        Private Property IsBasicView As Boolean
#End Region

        Private Function MapTrueFalseException(data As String, trueString As String, falseString As String) As Boolean
            If (data = trueString) Then Return True
            If (data = falseString) Then Return False
            Throw New ArgumentException
        End Function

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            ApprovalType = MapTrueFalseException(Request("Type"), "Approve", "Unapprove")

            If (Request("IsBulk") IsNot Nothing) Then
                IsBulk = RequestAsBoolean("IsBulk")
            End If

            LocationId = RequestAsInt32("BulkApproveLocationId")

            If LocationId < 0 Then
                LocationId = RequestAsInt32("LocationId")
            End If

            If (Not Request("IsBasicView") Is Nothing) Then
                IsBasicView = RequestAsBoolean("IsBasicView")
            End If

            If (Not Request("MonthValue") Is Nothing) Then
                MonthValueFrom = RequestAsDateTime("MonthValue")
                MonthValueTo = MonthValueFrom.AddMonths(1).AddDays(-1)
            Else
                MonthValueFrom = RequestAsDateTime("MonthValueFrom")
                MonthValueTo = RequestAsDateTime("MonthValueTo")
            End If

            If Not String.IsNullOrEmpty(RequestAsString("BulkApproveLocationTypeDescription")) Then
                LocationTypeId = DalApproval.GetLocationTypeId(Request.Params("BulkApproveLocationTypeDescription"))
            ElseIf Not String.IsNullOrEmpty(RequestAsString("BulkApproveLocationTypeDescriptionDynamic")) Then
                LocationTypeId = DalApproval.GetLocationTypeId(Request.Params("BulkApproveLocationTypeDescriptionDynamic"))
            Else
                If LocationId > 0 Then
                    Dim dr As DataRow = DalApproval.GetBhpbioLocationTypeAndApprovalStatus(LocationId, MonthValueFrom).AsEnumerable().FirstOrDefault()
                    LocationTypeId = dr.AsInt("LocationTypeId")
                End If
            End If

            HighestLocationType = RequestAsInt32("HighestLocationType", LocationTypeId)
            LowestLocationType = RequestAsInt32("LowestLocationType", LocationTypeId)

            UserId = Resources.UserSecurity.UserId.Value
        End Sub

        'TODO add to a more global place
        Private Overloads Function RequestAsInt32(ByVal requestId As String, Optional defaultValue As Integer = Common.Database.DataAccessBaseObjects.DoNotSetValues.Int32) As Int32
            Dim ret As Int32

            If (Not Request(requestId) Is Nothing) AndAlso Request(requestId).Trim <> "" Then
                ret = Convert.ToInt32(Request(requestId).Trim)
            Else
                ret = defaultValue
            End If
            Return ret
        End Function

        Protected Overrides Sub ProcessData()
            MyBase.ProcessData()

            Try
                ' every time an approval happens we need to clear t he cache
                Dim reportCache = New ReportFileCache(Server.MapPath("~"))
                reportCache.ClearCache()
            Catch ex As Exception
                ' sometimes clearing the cache will fail if the files are locked. We just ignore this, as it shouldn't happen
                ' every time
            End Try

            Resources.UserSecurity.SetSetting("Bulk_Approval_Filter_Location", LocationId.ToString())
            Resources.UserSecurity.SetSetting("Bulk_Approval_Month_From", MonthValueFrom.ToShortDateString())
            Resources.UserSecurity.SetSetting("Bulk_Approval_Month_To", MonthValueTo.ToShortDateString())
            Resources.UserSecurity.SetSetting("Bulk_Approval_Location_Type_From", HighestLocationType.ToString())
            Resources.UserSecurity.SetSetting("Bulk_Approval_Location_Type_To", LowestLocationType.ToString())

            If LowestLocationType = Types.LocationTypes.Pit Then
                LowestLocationType = Convert.ToInt32(Types.LocationTypes.Block)
            End If

            Dim approvalId = DalApproval.EnqueueBhpbioBulkApproval(
                ApprovalType, UserId, LocationId,
                MonthValueFrom, MonthValueTo,
                HighestLocationType, LowestLocationType, IsBulk)

            ' The page doesn't refresh, so we need to do this here for the user to see it.
            Controls.Add(New HtmlScriptTag(ScriptType.TextJavaScript, String.Format("DisplayApprovalProgress( {0},{1} );", approvalId, IsBasicView.ToString.ToLower)))
        End Sub

        Protected Overrides Function ValidateData() As String
            Dim ReturnValue As String = MyBase.ValidateData()
            Dim now = DateTime.Now
            Dim endOfMonth = New DateTime(now.Year, now.Month, DateTime.DaysInMonth(now.Year, now.Month))


            If LocationId < 0 Then
                Return "A location is required to be selected"
            End If

            If (MonthValueFrom > endOfMonth) Then
                Return "From Date cannot be after the current month"
            End If

            If (MonthValueTo < MonthValueFrom) Then
                Return "The From Date must be before the To Date"
            End If


            If (MonthValueTo > endOfMonth) Then
                Return "To Date cannot be after the current month"
            End If

            'Happily the IDs of the location types are in a hierarchical order, otherwise this wont work!
            ' TODO: Seriously? Talk about brittle code...
            If HighestLocationType < LocationTypeId Then
                Return "The highest location type cannot be higher than the reference location"
            End If

            If LowestLocationType < HighestLocationType Then
                Return "The lowest location type cannot be higher than the highest location type"
            End If

            If Not Resources.UserSecurity.UserId.HasValue Then
                Return "User Id not specified"
            End If

            ' Approval Heirarchy Rules
            Dim months As New List(Of DateTime)
            Dim currentMonth = MonthValueFrom
            ' Determine all the months, inclusive.
            While (currentMonth <= MonthValueTo)
                months.Add(currentMonth)
                currentMonth = currentMonth.AddMonths(1) ' Adding here because vb.net datetime object is immutable
            End While

            Dim summaries As New List(Of DataTable)
            For Each mnth In months
                Dim result = DalApproval.GetBhpbioApprovalSummary(mnth, True) ' This is a bit slow, added an index "Haulage_SourceDigblock_Id_Date_ForApprovalSummary" on the Haulage table which *should* help.
                result.ExtendedProperties.Add("Month", mnth.ToString("MMM yyyy")) ' TODO: This works well! Should fix other places where TableName is used to stored the month.
                summaries.Add(result)
            Next

            For Each monthlySummary In summaries
                Dim location = monthlySummary.Select().SingleOrDefault(Function(row) row.AsInt("Location_Id") = LocationId)
                If (location Is Nothing) Then
                    ' i.e. Unable to find LocationId "1" in the available data for "Jan 2016".
                    Return "Unable to find LocationId """ & LocationId & """ in the available data for """ & monthlySummary.ExtendedProperties("Month").ToString() & """."
                Else
                    Dim errorMessage As String
                    If ApprovalType Then 'ApprovalType = true means Approval. False means Unapproval
                        errorMessage = ValidateApprovalHeirarchy(location, monthlySummary)
                    Else
                        errorMessage = ValidateUnapprovalHeirarchy(location, monthlySummary)
                    End If

                    If (Not String.IsNullOrEmpty(errorMessage)) Then
                        Return errorMessage
                    End If
                End If
            Next
            ' End Approval Heirarchy Rules

            Return ReturnValue
        End Function

        Private Function ValidateApprovalHeirarchy(location As DataRow, monthlySummary As DataTable) As String
            Dim subLocations As New List(Of DataRow)

            Select Case LowestLocationType
                Case Types.LocationTypes.Hub
                    Dim sites = monthlySummary.Select().Where(Function(l) l.AsString("LocationType") = "Site" AndAlso l.AsInt("Parent_Location_Id") = LocationId).ToList()
                    subLocations.AddRange(sites)
                    For Each siteLocation In sites
                        subLocations.AddRange(monthlySummary.Select().Where(Function(l) l.AsString("LocationType") = "Pit" AndAlso l.AsInt("Parent_Location_Id") = siteLocation.AsInt("Location_Id") AndAlso l.AsString("ActiveStatus").Equals("Active")))
                    Next
                Case Types.LocationTypes.Site
                    subLocations = monthlySummary.Select().Where(Function(l) l.AsString("LocationType") = "Pit" AndAlso l.AsInt("Parent_Location_Id") = LocationId AndAlso l.AsString("ActiveStatus").Equals("Active")).ToList()
                    ' If it's a pit, there's no sublocations to check
            End Select

            Dim errorMessage = ""
            For Each s In subLocations
                If (s.AsString("ApprovalStatus") <> "Approved") Then
                    ' i.e. Site "AreaC" is not approved for "Jan 2016".
                    errorMessage += $"{s.AsString("LocationType")} ""{s.AsString("Name")}"" is not approved for ""{monthlySummary.ExtendedProperties("Month").ToString()}"".{vbCrLf}"
                End If
            Next

            Return errorMessage
        End Function

        Private Function ValidateUnapprovalHeirarchy(location As DataRow, monthlySummary As DataTable) As String
            Dim parentLocations As New List(Of DataRow)
            Select Case HighestLocationType
                ' If it's a hub, there's no parent locations to check.
                Case Types.LocationTypes.Site
                    parentLocations = monthlySummary.Select().Where(Function(l) l.AsString("LocationType") = "Hub" AndAlso l.AsInt("Location_Id") = location.AsInt("Parent_Location_Id")).ToList()
                Case Types.LocationTypes.Pit
                    Dim sites = monthlySummary.Select().Where(Function(l) l.AsString("LocationType") = "Site" AndAlso l.AsInt("Location_Id") = location.AsInt("Parent_Location_Id")).ToList()
                    parentLocations.AddRange(sites)
                    For Each siteLocation In sites
                        parentLocations.AddRange(monthlySummary.Select().Where(Function(l) l.AsString("LocationType") = "Hub" AndAlso l.AsInt("Location_Id") = siteLocation.AsInt("Parent_Location_Id")))
                    Next
            End Select

            Dim errorMessage = ""
            For Each p In parentLocations
                If (p.AsString("ApprovalStatus") = "Approved") Then
                    ' i.e. Site "AreaC" is still approved for "Jan 2016"
                    errorMessage += $"{p.AsString("LocationType")} ""{p.AsString("Name")}"" is still approved for ""{monthlySummary.ExtendedProperties("Month").ToString()}"".{vbCrLf}"
                End If
            Next

            Return errorMessage
        End Function

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                Dim errorMessage As String = ValidateData()

                If errorMessage = String.Empty Then
                    ProcessData()
                Else
                    JavaScriptAlert(errorMessage, "Please fix the following issues:")
                End If
            Catch ex As SqlException
                JavaScriptAlert(String.Format("Error while bulk approving: {0}", ex.Message))
            End Try
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalApproval Is Nothing Then
                DalApproval = New SqlDalApproval(Resources.Connection)
            End If
        End Sub
    End Class

End Namespace
