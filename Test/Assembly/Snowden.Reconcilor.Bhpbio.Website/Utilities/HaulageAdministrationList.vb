Imports System.Text
Imports System.Web.UI
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls

Namespace Utilities
    Public Class HaulageAdministrationList
        Inherits Core.Website.Utilities.HaulageAdministrationList

#Region "Properties"
        Private _hauledTonnesTerm As String = Reconcilor.Core.WebDevelopment.ReconcilorFunctions.GetSiteTerminology("Tonnes")
        Private _dalHaulage As Bhpbio.Database.DalBaseObjects.IHaulage

        Public Overloads Property DalHaulage() As Bhpbio.Database.DalBaseObjects.IHaulage
            Get
                Return _dalHaulage
            End Get
            Set(ByVal value As Database.DalBaseObjects.IHaulage)
                If (Not value Is Nothing) Then
                    _dalHaulage = value
                End If
            End Set
        End Property

        '' This is already implemented in the base class
        'Private _LocationId As Int32 = DoNotSetValues.Int32
        'Public Property LocationId() As Int32
        '    Get
        '        Return _LocationId
        '    End Get
        '    Set(ByVal value As Int32)
        '        _LocationId = value
        '    End Set
        'End Property
#End Region

        Protected Overrides Sub ProcessData()

            If LocationId = DoNotSetValues.Int32 Or LocationId = -1 Then
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Location", "")
            Else
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Location", LocationId.ToString)
            End If

            If (FilterDateFrom = NullValues.DateTime Or FilterDateFrom = Nothing) Then
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Date_From", "")
            Else
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Date_From", FilterDateFrom.ToString)
            End If

            If (FilterDateTo = NullValues.DateTime Or FilterDateFrom = Nothing) Then
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Date_To", "")
            Else
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Date_To", FilterDateTo.ToString)
            End If

            If FilterShiftFrom Is Nothing Then
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Shift_From", "")
            Else
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Shift_From", FilterShiftFrom.ToString)
            End If

            If FilterShiftTo Is Nothing Then
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Shift_To", "")
            Else
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Shift_To", FilterShiftTo.ToString)
            End If

            If FilterTruck Is Nothing Then
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Truck", "")
            Else
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Truck", FilterTruck.ToString)
            End If

            If FilterSource = "All" Or FilterSource = "" Then
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Source", "")
            ElseIf Not FilterSource Is Nothing Then
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Source", FilterSource.ToString)
            End If

            If FilterDestination = "All" Or FilterDestination = "" Then
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Destination", "")
            ElseIf Not FilterDestination Is Nothing Then
                Resources.UserSecurity.SetSetting("Haulage_Administration_Filter_Destination", FilterDestination.ToString)
            End If
        End Sub

        Protected Overrides Sub RunAjax()

            Dim cRecords, cSrcStockpile, cSrcDigblock, cSrcMill, cDestStockpile, cDestCrusher, cDestMill As Int32
            Dim sumTonnes As Double
         
            ProcessData()
            CreateBhpbioListTable(LocationId, cRecords, cSrcStockpile, cSrcDigblock, cSrcMill, cDestStockpile, cDestCrusher, cDestMill, sumTonnes)

            CreateReturnTable()
            Controls.Add(ReturnTable)

            ' Add the haulage details to the javascript and refresh the display.
            If BulkEdit Then
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
                 "enterHaulageData(" & cRecords.ToString() & "," & cSrcStockpile.ToString() & "," & _
                 cSrcDigblock.ToString() & "," & cSrcMill.ToString() & "," & cDestStockpile.ToString() & "," & _
                 cDestCrusher.ToString() & "," & cDestMill.ToString() & "," & sumTonnes.ToString() & "); updateDisplay();"))
            End If
            'End If

        End Sub

        Protected Overrides Sub SetupDalObjects()
            'use the bhbpio dal routines

            If (DalHaulage Is Nothing) Then
                DalHaulage = New Reconcilor.Bhpbio.Database.SqlDal.SqlDalHaulage(Resources.Connection)
            End If
            If (DalUtility Is Nothing) Then
                DalUtility = New Reconcilor.Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overridable Sub CreateBhpbioListTable(ByRef LocationId As Int32, ByRef cRecords As Int32, ByRef cSourceStockpile As Int32, _
        ByRef cSourceDigblock As Int32, ByRef cSourceMill As Int32, ByRef cDestinationStockpile As Int32, ByRef cDestinationCrusher As Int32, _
        ByRef cDestinationMill As Int32, ByRef sumTonnes As Double)

            ListTable = DalHaulage.GetBhpbioHaulageManagementList(LocationId, FilterDateFrom, FilterDateTo, FilterShiftFrom, _
             FilterShiftTo, FilterSource, FilterDestination, FilterTruck, Convert.ToInt16(Not BulkEdit), Top, cDestinationCrusher, cDestinationMill, cDestinationStockpile _
             , cRecords, cSourceDigblock, cSourceMill, cSourceStockpile, sumTonnes, RecordLimit)

            ListTable.DefaultView.Sort() = "Haulage_Date Desc"

            For Each col As DataColumn In ListTable.Columns
                Dim str As String = col.ColumnName
            Next

            If BulkEdit Then
                With ListTable.Columns
                    .Add("Haulage_Selection", _
                     GetType(String), "'<Input type=checkbox disabled checked name=""SelectiveHaul_' + Haulage_ID + '"" value=""' + Haulage_ID + '"" onclick=""updateDisplay(this);"">'")
                End With
            Else

                With ListTable.Columns
                    .Add("View", GetType(String), "'<a href=""./HaulageAdministrationDetails.aspx?HaulageId=' + Haulage_ID + '"">View</a>'")
                    .Add("Edit", GetType(String), "IIF(Editable = 1, '<a href=""./HaulageAdministrationEdit.aspx?Type=Edit&HaulageId=' + Haulage_ID + '"">Edit</a>', '')")
                    .Add("Delete", GetType(String), "IIF(Editable = 1, '<a href=""#"" onclick=""DeleteHaulage(''' + Haulage_ID + ''')"">Delete</a>', '')")
                End With

            End If

        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            Dim RequestText As String

            'Required to get User Settings here - source and destination are controls
            'loaded by ajax calls so they don't exist on the first page load

            RequestText = Trim(Request("Source"))

            If RequestText = "All" Or RequestText = "" Then
                FilterSource = Nothing
            Else
                FilterSource = RequestText
            End If



            RequestText = Trim(Request("Destination"))
            If RequestText = "All" Or RequestText = "" Then
                FilterDestination = Nothing
            Else
                FilterDestination = RequestText
            End If




            RequestText = Trim(Request("LocationId"))
            If Not Int32.Parse(RequestText) = 0 And Not Int32.Parse(RequestText) = -1 Then
                LocationId = RequestAsInt32("LocationId")
            Else
                LocationId = DoNotSetValues.Int32
            End If

        End Sub

        Protected Overrides Sub CreateReturnTable()

            ReDim Preserve UseColumns(UseColumns.Length)
            UseColumns(UseColumns.Length - 1) = UseColumns(UseColumns.Length - 2)
            UseColumns(UseColumns.Length - 2) = UseColumns(UseColumns.Length - 3)
            UseColumns(UseColumns.Length - 3) = UseColumns(UseColumns.Length - 4)
            UseColumns(UseColumns.Length - 4) = "OriginalDestination"

            Dim sometable As DataTable = ListTable

            MyBase.CreateReturnTable()

            ' Remove Edit and Delete Columns by excluding them
            ReDim Preserve ReturnTable.ExcludeColumns(ReturnTable.ExcludeColumns.Length + 1)
            ReturnTable.ExcludeColumns(ReturnTable.ExcludeColumns.Length - 2) = "Edit"
            ReturnTable.ExcludeColumns(ReturnTable.ExcludeColumns.Length - 1) = "Delete"

            If ReturnTable.Columns.ContainsKey("OriginalDestination") Then
                ReturnTable.Columns("OriginalDestination").HeaderText = " Original Destination"

                ReturnTable.Columns("OriginalDestination").TextAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
                ReturnTable.Columns("Destination").TextAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
                ReturnTable.Columns("Truck").TextAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
                ReturnTable.Columns("Source").TextAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Center
            End If

            If ReturnTable.Columns.ContainsKey("Tonnes") Then
                ReturnTable.Columns("Tonnes").HeaderText = _hauledTonnesTerm
            End If

            ' Rebind the data to generate the new data table
            ReturnTable.DataBind()
        End Sub

    End Class
End Namespace
