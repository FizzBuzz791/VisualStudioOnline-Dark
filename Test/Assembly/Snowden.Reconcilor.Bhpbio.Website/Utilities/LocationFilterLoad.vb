Imports System.Web.UI.WebControls
Imports Snowden.Reconcilor.Core.Globalisation.Resources
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports System.Web
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.Report.GenericDataTableExtensions


Namespace Utilities
	Public Class LocationFilterLoad
		Inherits Core.Website.Utilities.LocationFilterLoad

		Private _currentHub As String = ""

#Region " Properties "
		Private _overrideType As String
		Public Property OverrideType() As String
			Get
				Return _overrideType
			End Get
			Set(ByVal value As String)
				_overrideType = value.Trim()
			End Set
		End Property

		Private _requiresMonth As Boolean
		Public Property RequiresMonth() As Boolean
			Get
				Return _requiresMonth
			End Get
			Set(ByVal value As Boolean)
				_requiresMonth = value
			End Set
		End Property

		Private _startDate As DateTime
        Public Property StartDate() As DateTime
            Get
                Return _startDate
            End Get
            Set(ByVal value As DateTime)
                _startDate = value
            End Set
        End Property

        Private _dalUtility As Database.DalBaseObjects.IUtility
        Public Overloads Property DalUtility() As Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Database.DalBaseObjects.IUtility)
                If (Not value Is Nothing) Then
                    _dalUtility = value
                End If
            End Set
        End Property

        Public Property LocationGroupId As Integer

        Public Property ShowLocationGroups As Boolean

        Private _locationGroupData As DataTable = Nothing

        Public ReadOnly Property LocationGroupData As DataTable
            Get
                If DalUtility Is Nothing Then
                    Return _locationGroupData
                End If

                If _locationGroupData Is Nothing Then
                    _locationGroupData = DalUtility.GetBhpbioDepositList(LocationId)
                End If

                Return _locationGroupData
            End Get
        End Property

        ' this should be a generic location group, but the data source doesn't allow for that atm
        Public ReadOnly Property SelectedDeposit As DataRow
            Get
                If Not HasLocationGroups OrElse LocationGroupId < 0 Then
                    Return Nothing
                End If

                Return LocationGroupData.AsEnumerable.FirstOrDefault(Function(r) r.AsInt("LocationGroupId") = LocationGroupId)
            End Get
        End Property

        Public ReadOnly Property HasLocationGroups As Boolean
            Get
                Return LocationGroupData IsNot Nothing AndAlso LocationGroupData.Rows.Count > 0
            End Get
        End Property



#End Region

        Protected Overrides Sub RetrieveRequestData()
			MyBase.RetrieveRequestData()

			Try
				If (Request.UrlReferrer.AbsoluteUri.Contains("/Approval/Default.aspx") OrElse Request.UrlReferrer.AbsoluteUri.Contains("/Approval/ApprovalData.aspx") OrElse Request.UrlReferrer.AbsoluteUri.Contains("/Approval/ApprovalOther.aspx")) Then
					OverrideType = "approval"
                ElseIf (Not String.IsNullOrEmpty(RequestAsString("reportStartDateElementName"))) OrElse Request.UrlReferrer.AbsoluteUri.EndsWith("DataExport.aspx") Then
                    OverrideType = "report"
				Else
                    OverrideType = String.Empty
				End If

				RequiresMonth = Not String.IsNullOrEmpty(OverrideType)

                If (RequiresMonth) Then
                    Dim startDateTemp As String = RequestAsString("startDate")

                    If (Not DateTime.TryParse(startDateTemp, StartDate)) Then
                        Throw New ApplicationException("A month needs to be supplied.")
                    End If

                    'Set to start of month
                    StartDate = New DateTime(StartDate.Year, StartDate.Month, 1)
                End If

                If StartDate <= New Date(2000, 1, 1) Then
                    StartDate = DateTime.Now.Date
                    StartDate = New DateTime(StartDate.Year, StartDate.Month, 1)
                End If

                LocationGroupId = RequestAsInt32("LocationGroupId")
                ShowLocationGroups = RequestAsBoolean("ShowLocationGroups")

            Catch ex As Exception
				JavaScriptAlert(ex.Message, "Error Retrieving Location Request:\n")
			End Try
		End Sub

		'Replace Location Filter setup completely to pass month and call new DB procs for
		'location override when required.
		Protected Overrides Sub SetupPageControls()
			Const dynamicControlNameSuffix As String = "Dynamic"

			Dim loadScript As Tags.HtmlScriptTag

			Dim locationDropdownId As String
			Dim locationNameId As String
			Dim locationTypeDescriptionId As String

			Dim locationData As DataTable
			Dim parentLocationId As Integer
			Dim childData As DataTable
            Dim childLocationType As String = Nothing
            Dim locationTypeDesc As String


            'determine the control names
            locationDropdownId = ControlId
			If ControlId.Contains("Id") Then
				locationNameId = ControlId.Replace("Id", "Name")
				locationTypeDescriptionId = ControlId.Replace("Id", "TypeDescription")
			Else
				locationNameId = ControlId & "Name"
				locationTypeDescriptionId = ControlId & "TypeDescription"
			End If

			'rename the controls
			loadScript = New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript)

			loadScript.InnerScript = String.Format("LocationReconfigureControls('{0}', '{1}', '{2}', '{3}', '{4}', '{5}');", _
			 locationDropdownId, locationDropdownId & dynamicControlNameSuffix, _
			 locationNameId, locationNameId & dynamicControlNameSuffix, _
			 locationTypeDescriptionId, locationTypeDescriptionId & dynamicControlNameSuffix)

			Controls.Add(loadScript)

			'apply temporary names to the real controls as they will be renamed later
			LocationDropdown.ID = locationDropdownId & dynamicControlNameSuffix
			LocationName.ID = locationNameId & dynamicControlNameSuffix
			LocationTypeDescription.ID = locationTypeDescriptionId & dynamicControlNameSuffix

			'format the controls, ...
			LayoutTable.Width = Unit.Percentage(100)
			LocationLabel.Text = "Location:"

            If LocationId >= 0 Then

                If (RequiresMonth) Then
                    locationData = DalUtility.GetBhpbioLocationListWithOverride(LocationId, Convert.ToInt16(False), StartDate)
                    If locationData.Rows.Count = 0 Then ' if the current location no longer exists on StartDate, then just get the company location
                        LocationId = 1
                        locationData = DalUtility.GetBhpbioLocationListWithOverride(LocationId, Convert.ToInt16(False), StartDate)
                    End If
                    childData = DalUtility.GetBhpbioLocationListWithOverride(LocationId, Convert.ToInt16(True), StartDate)
                Else
                    locationData = DalUtility.GetLocationList(DoNotSetValues.Int16, DoNotSetValues.Int32, LocationId, DoNotSetValues.Int16, Convert.ToInt16(True))
                    childData = DalUtility.GetLocationList(DoNotSetValues.Int16, LocationId, DoNotSetValues.Int32, DoNotSetValues.Int16, Convert.ToInt16(True))
                End If

                If locationData.Rows.Count > 0 Then
                    LocationName.Value = locationData.Rows(0)("Name").ToString
                    parentLocationId = Convert.ToInt32(locationData.Rows(0)("Parent_Location_Id"))
                    locationTypeDesc = locationData.Rows(0)("Location_Type_Description").ToString()
                    LocationTypeDescription.Value = locationTypeDesc

                    ' If it has reached it's provided lowest level, do not provide children data.
                    If Not LowestLocationTypeDescription Is Nothing AndAlso Not locationTypeDesc Is Nothing AndAlso
                     locationTypeDesc.ToUpper() = LowestLocationTypeDescription.ToUpper() Then
                        childData.Clear()

                        If (RequiresMonth) Then
                            childData = DalUtility.GetBhpbioLocationListWithOverride(parentLocationId, Convert.ToInt16(True), StartDate)
                        Else
                            childData = DalUtility.GetLocationList(DoNotSetValues.Int16, parentLocationId, DoNotSetValues.Int32, DoNotSetValues.Int16, Convert.ToInt16(True))
                        End If
                    End If

                    If childData.Rows.Count > 0 AndAlso SelectedDeposit Is Nothing Then
                        childLocationType = childData.Rows(0)("Location_Type_Description").ToString.ToLower & "(s)"
                        locationData.Rows(0)("Name") = locationData.Rows(0)("Name").ToString & "  - " & childLocationType & " added to dropdown "
                    End If

                End If

                ' if a location groups has been selected, then we need to do things a bit differently to get the name and type
                ' to appear properly
                If SelectedDeposit IsNot Nothing Then
                    locationData.Rows(0)("Location_Type_Description") = "Deposit"
                    locationData.Rows(0)("Name") = String.Format("{0} - {1} added to dropdown", SelectedDeposit.AsString("Name"), childLocationType)
                End If

                locationData.Merge(childData)
                locationData.Columns.Add(New DataColumn("Location_Name_Type", GetType(String), "Location_Type_Description + ': '+ Name"))

                For Each row As DataRow In locationData.Rows
                    LocationDropdown.Items.Add(New ListItem(row.AsString("Location_Name_Type"), row.AsString("Location_Id")))
                Next

                ' if location groups are activated, and there is data for that particular parent location, then we want to 
                ' add them below the direct sublocations in the picker.
                '
                ' The location groups are separated from the regular locations by having a different sort of id - instead of just a
                ' regular int, they are a string in the format "<parentLocationId>G<locationGroupID>". For example "9G1". This will get
                ' parsed when sent to the server to turn it into a locationId and a locationGroupId, so that the proper list of sublocations
                ' is retreived. If the location picker is being used on a report, then the locationGroupId will *automatically* be mapped
                ' if there is a parameter present called LocationGroupId
                If ShowLocationGroups AndAlso LocationGroupData.Rows.Count > 0 Then
                    Dim topLevelId = locationData.AsEnumerable.First.AsInt("Location_Id")
                    LocationDropdown.Items.Add(New ListItem("---", topLevelId.ToString))

                    For Each row As DataRow In LocationGroupData.Rows
                        Dim locationIdWithGroupId = String.Format("{0}G{1}", topLevelId, row.AsString("LocationGroupId"))
                        LocationDropdown.Items.Add(New ListItem("Deposit: " + row.AsString("Name"), locationIdWithGroupId))
                    Next
                End If

                ' if a locationGroup has been selected, make sure the id is in the correct format
                If LocationGroupId > 0 Then
                    LocationDropdown.Items(0).Value = String.Format("{0}G{1}", LocationId, LocationGroupId)
                End If

                With LocationDropdown

                        If LocationId = 0 Then
                            .Items.Insert(0, New ListItem("", "-1"))
                        End If

                        .OnSelectChange = String.Empty

                        If UseCallbackDown Then
                            .OnSelectChange += CallbackMethodDown
                        End If

                        If (RequiresMonth) Then
                            .OnSelectChange += String.Format("LocationDropDownChangedOverride(this, '{0}', {1}, {2}, '{3}', '{4}', '{5}', '{6}', '{7}', '{8}');",
                  LocationDivId, LocationLabelCellWidth.ToString, ShowCaptions.ToString.ToLower, ControlId, CallbackMethodUp, CallbackMethodDown, HtmlHelper.FormatForJavaScript(HttpUtility.UrlEncode(OnChange)), LowestLocationTypeDescription, OverrideType)
                        Else
                            .OnSelectChange += String.Format("LocationDropDownChanged(this, '{0}', {1}, {2}, '{3}', '{4}', '{5}', '{6}', '{7}');",
                    LocationDivId, LocationLabelCellWidth.ToString, ShowCaptions.ToString.ToLower, ControlId, CallbackMethodUp, CallbackMethodDown, HtmlHelper.FormatForJavaScript(HttpUtility.UrlEncode(OnChange)), LowestLocationTypeDescription)
                        End If
                    End With
                End If

                With LocationDetail
				If LocationId < 1 Then
					.Text = MenuItems.NoLocationSelected
				Else
					.Text = GetLocationDetailText()
				End If
			End With

			With UpLevelButton
				.Href = "#"
				.Attributes("onclick") = String.Empty
				If UseCallbackUp Then
					.Attributes("onclick") = CallbackMethodUp
				End If

                If (RequiresMonth) Then
                    .Attributes("onclick") = String.Format("LoadLocationOverride(false, {0}, '{1}', {2}, {3}, '{4}', '{5}', '{6}', '{7}', '{8}', null, null, '{9}');", _
                        parentLocationId.ToString, LocationDivId, LocationLabelCellWidth.ToString, ShowCaptions.ToString.ToLower, ControlId, CallbackMethodUp, CallbackMethodDown, HtmlHelper.FormatForJavaScript(HttpUtility.UrlEncode(OnChange)), LowestLocationTypeDescription, StartDate.ToString("yyyy-MM-dd"))
                Else
                    .Attributes("onclick") = String.Format("LoadLocation(false, {0}, '{1}', {2}, {3}, '{4}', '{5}', '{6}', '{7}', '{8}');", _
                        parentLocationId.ToString, LocationDivId, LocationLabelCellWidth.ToString, ShowCaptions.ToString.ToLower, ControlId, CallbackMethodUp, CallbackMethodDown, HtmlHelper.FormatForJavaScript(HttpUtility.UrlEncode(OnChange)), LowestLocationTypeDescription)
                End If

				.Controls.Add(New Tags.HtmlImageTag(Page.ResolveUrlExtRemoving(Request.ApplicationPath, Request.Url.AbsoluteUri, Request.RawUrl) & "/images/Filter-Location-Back.gif"))
				.Controls.Add(New LiteralControl(MenuItems.UpOneLevel))
			End With

			If Not (OmitInitialChange = True And InitialLoad = True) Then
				If OnChange <> "" Then
					Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
					 OnChange & "(" & LocationId & ");"))
				End If
			End If

			If (RequiresMonth) Then
				Dim overrideLocationDates = System.Configuration.ConfigurationManager.AppSettings("overrideLocationDates").Split(New String() {","}, StringSplitOptions.None).ToList()
				Dim monthList As String = (From overrideLocationDate In overrideLocationDates Where (IsDate(overrideLocationDate)) Select Convert.ToDateTime(overrideLocationDate)).Aggregate("", Function(current, locationDate) current & String.Format("new Date({0}, {1}, {2}),", locationDate.Year, locationDate.Month - 1, locationDate.Day - 1))

				Dim hubData = DalUtility.GetLocationList(DoNotSetValues.Int16, DoNotSetValues.Int32, DoNotSetValues.Int32, 2, Convert.ToInt16(True))

				Dim hubIdArray As String = ""
				Dim hubDescriptionArray As String = ""
				Dim overrideLocationHubList = System.Configuration.ConfigurationManager.AppSettings("overrideLocationHubList").Split(New String() {","}, StringSplitOptions.None).ToList()

				For Each row As DataRow In hubData.Rows
					If (overrideLocationHubList.Contains(row("Name").ToString())) Then
						hubIdArray &= Convert.ToString(row("Location_Id")) & ","
						hubDescriptionArray &= "'" & Convert.ToString(row("Name")) & "',"
					End If
				Next

				If (monthList.Length > 0) Then monthList = monthList.Substring(0, monthList.Length - 1)
				If (hubIdArray.Length > 0) Then hubIdArray = hubIdArray.Substring(0, hubIdArray.Length - 1)
				If (hubDescriptionArray.Length > 0) Then hubDescriptionArray = hubDescriptionArray.Substring(0, hubDescriptionArray.Length - 1)

				monthList = "[" & monthList & "]"
				hubIdArray = "[" & hubIdArray & "]"
				hubDescriptionArray = "[" & hubDescriptionArray & "]"

				loadScript.InnerScript &= "monthList = " & monthList & "; currentHub = '" & _currentHub & "'; hubList = " & hubDescriptionArray & "; hubIdList = " & hubIdArray & "; locationDivId = '" & LocationDivId & "';"
			End If
		End Sub

		<Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1024:UsePropertiesWhereAppropriate")> _
		Protected Overrides Function GetLocationDetailText() As String
            Dim locationHeirarchy As DataTable = Nothing
            Dim returnStr As New Text.StringBuilder()

            ' note that there is a bug with the override method that causes it not to work for anything under the
            ' pit level. So if we detect that situation, just use the normal method to generate the description, even 
            ' though this might mean the text can be wrong under some circumstances
            If RequiresMonth AndAlso Not IsLocationUnderPitLevel() Then
                locationHeirarchy = DalUtility.GetBhpbioLocationParentHeirarchyWithOverride(LocationId, StartDate)
            Else
                locationHeirarchy = DalUtility.GetLocationParentHeirarchy(LocationId)
			End If

			_currentHub = ""
            For Each row As DataRow In locationHeirarchy.Rows
                returnStr.Append(row("Location_Type_Description").ToString())
                returnStr.Append(" - ")
                returnStr.Append(row("Name").ToString())
                returnStr.Append("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;")

                ' Populate current hub
                Dim currentLocationTypeId = row("Location_Type_Id").ToString()
                If (currentLocationTypeId = "2") Then
                    _currentHub = row("Name").ToString()
                End If
            Next

            If SelectedDeposit IsNot Nothing Then
                returnStr.AppendFormat("Deposit - {0}", SelectedDeposit.AsString("Name"))
            End If

            Return returnStr.ToString()
		End Function

        Protected Function IsLocationUnderPitLevel() As Boolean
            Dim pitLocationTypeId = 4
            Return GetLocationTypeId() > pitLocationTypeId
        End Function

        Protected Function GetLocationTypeId() As Integer
            Return Convert.ToInt32(DalUtility.GetLocation(LocationId).Rows(0)("Location_Type_Id"))
        End Function

        Protected Overrides Sub SetupDalObjects()
			'use the bhbpio dal routines
			If (DalUtility Is Nothing) Then
				DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
			End If

			MyBase.SetupDalObjects()
		End Sub
	End Class
End Namespace