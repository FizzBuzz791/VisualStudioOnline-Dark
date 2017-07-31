Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports System.Xml
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal

Namespace Stockpiles
    Public Class StockpileList
        Inherits Snowden.Reconcilor.Core.Website.Stockpiles.StockpileList

#Region "Properties"

        Dim _transactionStartDate As DateTime
        Dim _transactionEndDate As DateTime
        Dim _includeLocationsBelow As Boolean
        Dim _stockpileGroupsXml As String

        Private _disposed As Boolean

        Public Property TransactionStartDate() As DateTime
            Get
                Return _transactionStartDate
            End Get
            Set (ByVal value As DateTime)
                _transactionStartDate = value
            End Set
        End Property

        Public Property TransactionEndDate() As DateTime
            Get
                Return _transactionEndDate
            End Get
            Set (ByVal value As DateTime)
                _transactionEndDate = value
            End Set
        End Property

        Public Property IncludeLocationsBelow() As Boolean
            Get
                Return _includeLocationsBelow
            End Get
            Set (ByVal value As Boolean)
                _includeLocationsBelow = value
            End Set
        End Property

#End Region

        Protected Overrides Sub RunAjax()

            RetrieveGradeFormats()
            CreateListTable()
            CreateReturnTable()

            If ReturnTable.DataSource.Rows.Count = 0 Then
                Controls.Remove (ReturnTable)
                Dim message As New HtmlPTag
                message.ID = "stockpileMessage"
                message.InnerText = "   No Records Returned."
                Controls.Add (message)
            Else
                Controls.Add (ReturnTable)
            End If

            'Controls.Add(New Tags.HtmlDivTag("StockpileImageLocation"))
            'If LocationId <> DoNotSetValues.Int32 AndAlso LocationId <> NullValues.Int32 AndAlso LocationId > 0 Then
            '    Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
            '                                        Tags.ScriptLanguage.JavaScript, String.Empty, _
            '                                        "CallAjax('StockpileImageLocation','../Internal/StockpileImageLoaderPage.aspx?LocationId=" + LocationId.ToString + "&Height=500&MaxWidth=700')"))
            'End If


        End Sub


        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            TransactionStartDate = RequestAsDateTime ("TransactionStartDateText")
            TransactionEndDate = RequestAsDateTime ("TransactionEndDateText")
            IncludeLocationsBelow = RequestAsBoolean ("IncludeLocationsBelow")

            If (LocationId = DoNotSetValues.Int32) Then
                LocationId = 1
            End If

            Dim userSettingXml As String = BuildStockpileGroupUserSettingXml()

            If GroupStockpiles = True Then
                _stockpileGroupsXml = BuildStockpileGroupXml()
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Stockpile_Groups", userSettingXml)
            End If

        End Sub

        Protected Overridable Function BuildStockpileGroupUserSettingXml() As String
            Dim stockpileGroups As DataTable = DalUtility.GetStockpileGroupList (0, 0)
            Dim xmlDoc As New XmlDocument()
            Dim documentElement As XmlElement = xmlDoc.CreateElement ("docElement")
            Dim stockpileGroupAttribute As XmlElement
            Dim controlCheck As Boolean

            Dim StockpileGroupRow As DataRow
            StockpileGroupRow = stockpileGroups.NewRow
            stockpileGroups.Rows.Add (StockpileGroupRow)

            StockpileGroupRow.Item ("Stockpile_Group_Id") = "Stockpiles NOT Grouped"

            For Each dr As DataRow In stockpileGroups.Rows

                Dim currentGroup As String = dr ("Stockpile_Group_Id").ToString()
                Dim stockpileGroupControlId As String = "CheckBox" + currentGroup.Trim().Replace (" ", "")

                controlCheck = RequestAsBoolean (stockpileGroupControlId)

                If (controlCheck) Then
                    stockpileGroupAttribute = xmlDoc.CreateElement ("Id")
                    stockpileGroupAttribute.InnerText = currentGroup
                    documentElement.AppendChild (stockpileGroupAttribute)
                    xmlDoc.AppendChild (documentElement)
                End If
            Next

            Return xmlDoc.OuterXml

        End Function

        Protected Overridable Function BuildStockpileGroupXml() As String
            Dim stockpileGroups As DataTable = DalUtility.GetStockpileGroupList (0, 0)
            Dim xmlDoc As New XmlDocument()
            Dim documentElement As XmlElement = xmlDoc.CreateElement ("docElement")

            Dim StockpileGroupRow As DataRow
            StockpileGroupRow = stockpileGroups.NewRow
            stockpileGroups.Rows.Add (StockpileGroupRow)

            StockpileGroupRow.Item ("Stockpile_Group_Id") = "Stockpiles NOT Grouped"

            For Each dr As DataRow In stockpileGroups.Rows

                Dim currentGroup As String = dr ("Stockpile_Group_Id").ToString()
                Dim stockpileGroupControlId As String = "CheckBox" + currentGroup.Trim().Replace (" ", "")

                Dim controlCheck As Boolean = RequestAsBoolean (stockpileGroupControlId)

                If (controlCheck) Then

                    Dim rootXmlElement As XmlElement = xmlDoc.CreateElement ("StockpileGroups")
                    Dim stockpileGroupAttribute As XmlElement = xmlDoc.CreateElement ("GroupId")

                    stockpileGroupAttribute.InnerText = currentGroup
                    rootXmlElement.AppendChild (stockpileGroupAttribute)
                    documentElement.AppendChild (rootXmlElement)
                End If
            Next

            xmlDoc.AppendChild (documentElement)

            Return xmlDoc.OuterXml

        End Function

        Protected Overridable Function GetTableColumns (ByVal rows As DataRow()) _
            As Dictionary(Of String, ReconcilorTableColumn)
            Dim tableColumns As New Dictionary(Of String, ReconcilorTableColumn)
            Dim width As Int32
            Dim recColumn As ReconcilorTableColumn
            Dim field As String

            For Each column In rows
                field = column ("Field_Name").ToString()
                Int32.TryParse (column ("Pixel_Width").ToString(), width)

                If field = "Stockpile_Name" Then
                    field = "Stockpile_Name_Link"
                End If

                recColumn = New ReconcilorTableColumn (column ("Display_Name").ToString, width)
                If field.Contains ("Date") Then
                    recColumn.DateTimeFormat = Application ("DateFormat").ToString
                End If

                tableColumns.Add (field, recColumn)
            Next

            Return tableColumns
        End Function

        Protected Overridable Function GetUseColumns (ByVal rows As DataRow()) As ICollection(Of String)
            Dim useColumns As New List(Of String)
            Dim field As String

            For Each column In rows
                field = column ("Field_Name").ToString()

                If field = "Stockpile_Name" Then
                    field = "Stockpile_Name_Link"
                End If

                useColumns.Add (field)
            Next

            Return useColumns
        End Function

        Protected Overridable Function GetTotalColumns (ByVal rows As DataRow()) As ICollection(Of String)
            Dim totalColumns As New List(Of String)
            Dim sum As Boolean
            Dim field As String

            For Each column In rows
                field = column ("Field_Name").ToString()

                If field = "Stockpile_Name" Then
                    field = "Stockpile_Name_Link"
                End If

                If Boolean.TryParse (column ("Sum_Field").ToString(), sum) AndAlso sum Then
                    totalColumns.Add (field)
                End If
            Next

            Return totalColumns
        End Function

        Protected Overrides Sub CreateReturnTable()
            Dim tableColumns As Dictionary(Of String, ReconcilorTableColumn)
            Dim useColumns As ICollection(Of String)
            Dim totalColumns As ICollection(Of String)
            Dim interfaceRows As DataRow()

            ProcessData()

            interfaceRows = ReconcilorTable.GetUserInterfaceList (DalUtility, "Stockpile_Listing")
            tableColumns = GetTableColumns (interfaceRows)
            useColumns = GetUseColumns (interfaceRows)
            totalColumns = GetTotalColumns (interfaceRows)

            'add a column with tonnes * grade to datatable to be used ReturnTable_SummedItemCallback function call
            For Each fieldName In totalColumns
                If fieldName <> "Current_Tonnes" And fieldName <> "Approved_Added_Tonnes_This_Month" Then
                    StockpileList.Columns.Add ("Weighted_" & fieldName, GetType (Double), _
                                               "Current_Tonnes * " & fieldName)
                End If
            Next

            ReturnTable = New ReconcilorTable (StockpileList, useColumns.ToArray())

            With ReturnTable
                .Columns = tableColumns
                .TotalColumns = totalColumns.ToArray()
                .GroupingColumn = "Stockpile_Group_Id"
                .GroupData = GroupStockpiles
                .Height = 400
                .ItemDataBoundCallback = AddressOf ReturnTable_ItemDataboundCallback
                .SummedItemCallback = AddressOf StockpileList_SummedItemCallback
                .GrandTotalItemCallback = AddressOf StockpileList_GrandTotalItemCallback

                If totalColumns.Count > 0 Then
                    .DisplayGrandTotal = True
                    .DisplayGroupSubtotals = True
                End If

                .DataBind()

                ' Reset the widths so that wrapping will occur.
                tableColumns = GetTableColumns (interfaceRows)
                For Each recColumn In tableColumns
                    If .Columns.ContainsKey (recColumn.Key) AndAlso recColumn.Value.Width > 0 Then
                        .Columns (recColumn.Key).Width = recColumn.Value.Width
                    End If
                Next

                If (.Columns.ContainsKey ("Edit")) Then
                    With .Columns ("Edit")
                        .ColumnSortType = ReconcilorTableColumn.SortType.NoSort
                    End With
                End If

                If (.Columns.ContainsKey ("View")) Then
                    With .Columns ("View")
                        .ColumnSortType = ReconcilorTableColumn.SortType.NoSort
                    End With
                End If

                If (.Columns.ContainsKey ("Delete")) Then
                    With .Columns ("Delete")
                        .ColumnSortType = ReconcilorTableColumn.SortType.NoSort
                    End With
                End If
            End With


        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalStockpile Is Nothing) Then
                DalStockpile = New SqlDalStockpile (Resources.Connection)
            End If

            If (DalUtility Is Nothing) Then
                DalUtility = New SqlDalUtility (Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub CreateListTable()

            If LocationId = 0 Then
                LocationId = DoNotSetValues.Int32
            End If

            Dim dal As IStockpile = DirectCast (DalStockpile, IStockpile)

            StockpileList = dal.GetStockpileListByGroups (1, DoNotSetValues.String, StockpileIdFilter, StateType, _
                                                          MaterialTypeId, DoNotSetValues.Int32, Convert.ToInt16 (True), _
                                                          StartDate, EndDate, LocationId, RecordLimit, _
                                                          DoNotSetValues.Byte, TransactionStartDate, TransactionEndDate, _
                                                          _stockpileGroupsXml, IncludeLocationsBelow)

            If Resources.UserSecurity.HasAccess ("STOCKPILE_VIEW") Then
                StockpileList.Columns.Add ("Stockpile_Name_Link", GetType (String), _
                                           "'<a href=""./StockpileDetails.aspx?StockpileId=' + Stockpile_ID + '"">'+ Stockpile_Name +'</a>'")
                StockpileList.Columns.Add ("View", GetType (String), _
                                           "'<a href=""./StockpileDetails.aspx?StockpileId=' + Stockpile_ID + '"">View</a>'")
            Else
                StockpileList.Columns.Add ("Stockpile_Name_Link", GetType (String), _
                                           "'<span title=""You do not have access to do this"">'+ Stockpile_Name +'</span>'")
                StockpileList.Columns.Add ("View", GetType (String), _
                                           "'<span title=""You do not have access to do this"">View</span>'")
            End If

            If Resources.UserSecurity.HasAccess ("STOCKPILE_EDIT") Then
                StockpileList.Columns.Add ("Edit", GetType (String), _
                                           "'<a href=""./StockpileEdit.aspx?StockpileId=' + Stockpile_ID + '"">Edit</a>'")
            Else
                StockpileList.Columns.Add ("Edit", GetType (String), _
                                           "'<span title=""You do not have access to do this"">Edit</span>'")
            End If

            If Resources.UserSecurity.HasAccess ("STOCKPILE_DELETE") Then
                StockpileList.Columns.Add ("Delete", GetType (String), _
                                           "'<a href=""#"" onclick=""DeleteStockpile(' + Stockpile_ID + ', ''' + Stockpile_Name + ''')"">Delete</a>'")
            Else
                StockpileList.Columns.Add ("Delete", GetType (String), _
                                           "'<span title=""You do not have access to do this"">Delete</span>'")
            End If
        End Sub

        Protected Overridable Function StockpileList_SummedItemCallback (ByVal textData As String, _
                                                                         ByVal columnName As String, _
                                                                         ByVal group As String) As String
            Dim returnValue As String = textData.Trim
            Dim massAveraged As Double
            Dim weightedValue As Object
            Dim sumTonnes As Object
            Dim filter As String = "Stockpile_Group_Id = '" & group & "'"

            Try
                If Grades.ContainsKey (columnName) Then
                    weightedValue = StockpileList.Compute ("Sum(Weighted_" & columnName & ")", filter)
                    sumTonnes = StockpileList.Compute ("Sum(Current_Tonnes)", filter)

                    If weightedValue Is DBNull.Value Or sumTonnes Is DBNull.Value OrElse Convert.ToInt32 (sumTonnes) = 0 _
                        Then
                        sumTonnes = 0
                    Else
                        massAveraged = Convert.ToDouble (weightedValue)/Convert.ToDouble (sumTonnes)
                    End If

                    returnValue = Grades (columnName).ToString (Convert.ToSingle (massAveraged), False)
                End If
            Catch ex As FormatException
                returnValue = textData.Trim
            End Try

            Return returnValue
        End Function

        Protected Overridable Function StockpileList_GrandTotalItemCallback (ByVal textData As String, _
                                                                             ByVal columnName As String, _
                                                                             ByVal group As String) As String

            Dim returnValue As String = textData.Trim
            Dim massAveraged As Double
            Dim weightedValue As Object
            Dim sumTonnes As Object

            Try
                If Grades.ContainsKey (columnName) Then
                    weightedValue = StockpileList.Compute ("Sum(Weighted_" & columnName & ")", "")
                    sumTonnes = StockpileList.Compute ("Sum(Current_Tonnes)", "")

                    If weightedValue Is DBNull.Value Or sumTonnes Is DBNull.Value OrElse Convert.ToInt32 (sumTonnes) = 0 _
                        Then
                        sumTonnes = 0
                    Else
                        massAveraged = Convert.ToDouble (weightedValue)/Convert.ToDouble (sumTonnes)
                    End If

                    returnValue = Grades (columnName).ToString (Convert.ToSingle (massAveraged), False)
                End If
            Catch ex As FormatException
                returnValue = textData.Trim
            End Try

            Return returnValue
        End Function

        Protected Overrides Sub ProcessData()
            If (StateType = NullValues.Int16) Then
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_State_Type", "")
            Else
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_State_Type", StateType.ToString)
            End If

            If (MaterialTypeId = DoNotSetValues.Int32) Then
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Material_Type_ID", "")
            Else
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Material_Type_ID", MaterialTypeId.ToString)
            End If

            If (StartDate = DoNotSetValues.DateTime) Then
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Date_From", "")
            Else
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Date_From", _
                                                   StartDate.ToString (Application ("DateFormat").ToString))
            End If

            If (EndDate = DoNotSetValues.DateTime) Then
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Date_To", "")
            Else
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Date_To", _
                                                   EndDate.ToString (Application ("DateFormat").ToString))
            End If

            If (StockpileIdFilter Is Nothing) Then
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Stockpile_ID", "")
            Else
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Stockpile_ID", StockpileIdFilter)
            End If

            If (LocationId = DoNotSetValues.Int32) Then
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Location", "1")
            Else
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Location", LocationId.ToString)
            End If

            Resources.UserSecurity.SetSetting ("Stockpile_Filter_Group_Stockpiles", GroupStockpiles.ToString)
            Resources.UserSecurity.SetSetting ("Stockpile_Filter_LimitRecords", LimitRecords.ToString.ToUpper)

            If (TransactionStartDate = DoNotSetValues.DateTime) Then
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Transaction_Start_Date", "")
            Else
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Transaction_Start_Date", _
                                                   TransactionStartDate.ToString (Application ("DateFormat").ToString))
            End If

            If (TransactionEndDate = DoNotSetValues.DateTime) Then
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Transaction_End_Date", "")
            Else
                Resources.UserSecurity.SetSetting ("Stockpile_Filter_Transaction_End_Date", _
                                                   TransactionEndDate.ToString (Application ("DateFormat").ToString))
            End If

            Resources.UserSecurity.SetSetting ("Stockpile_Filter_Include_Locations_Below", _
                                               IncludeLocationsBelow.ToString)

        End Sub
    End Class
End Namespace

