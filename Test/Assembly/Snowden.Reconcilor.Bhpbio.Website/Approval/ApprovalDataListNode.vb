Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports System.Web.UI.WebControls
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Reconcilor.Core
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace Approval
    Public Class ApprovalDataListNode
        Inherits WebpageTemplates.AnalysisAjaxTemplate

#Region " Properties "
        Private _dalUtility As Core.Database.DalBaseObjects.IUtility
        Private _dalPurge As IPurge
        Private _nodeLevel As Int32
        Private _nodeRowId As String
        Private _locationId As Int32
        Private _approvalMonth As DateTime
        Private _calcId As String
        Private _dateFormat As String = "dd/MM/yyyy"

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

        Public Property NodeLevel() As Int32
            Get
                Return _nodeLevel
            End Get
            Set(ByVal value As Int32)
                _nodeLevel = value
            End Set
        End Property

        Public Property NodeRowId() As String
            Get
                Return _nodeRowId
            End Get
            Set(ByVal value As String)
                _nodeRowId = value
            End Set
        End Property

        Public Property LocationId() As Int32
            Get
                Return _locationId
            End Get
            Set(ByVal value As Int32)
                _locationId = value
            End Set
        End Property

        Public Property ApprovalMonth() As DateTime
            Get
                Return _approvalMonth
            End Get
            Set(ByVal value As DateTime)
                _approvalMonth = value
            End Set
        End Property

        Public Property CalcId() As String
            Get
                Return _calcId
            End Get
            Set(ByVal value As String)
                _calcId = value
            End Set
        End Property
#End Region

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            Try
                NodeRowId = RequestAsString("NodeRowId")
                NodeLevel = RequestAsInt32("NodeLevel")
                LocationId = RequestAsInt32("LocationId")
                CalcId = RequestAsString("CalcId")
                ApprovalMonth = RequestAsDateTime("ApprovalMonth")
            Catch ex As Exception
                JavaScriptAlert(ex.Message, "Error retrieving location picker node request:\n")
            End Try
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                ProcessData()
            Catch ea As Threading.ThreadAbortException
                Return
            Catch ex As Exception
                JavaScriptAlert(ex.Message, "Error retrieving location picker tree:\n")
            End Try
        End Sub


        Protected Overrides Sub ProcessData()
            MyBase.ProcessData()

            Try
                ' this will be used later on when formatting table fields, but get it here so that it only
                ' has to be done once
                _dateFormat = DalUtility.GetSystemSetting("FORMAT_DATE")

                Dim nodeData As DataTable
                Dim data As DataRow
                Dim returnTable As New HtmlTableTag
                Dim columns As List(Of String) = ReconcilorTable.GetUserInterfaceColumns(DalUtility, _
                    "Approval_Data").Select(Function(a) a.Key.ToUpper()).ToList()

                Dim isMonthPurged As Boolean = DalPurge.IsMonthPurged(_approvalMonth)

                Dim nextOutlierCalculationDateTime As Nullable(Of DateTime) = ApprovalDataListData.DetermineMonthForNextOutlierQueueEntry(Resources.ConnectionString)

                Dim areOutliersDisplayed As Boolean
                nodeData = ApprovalDataListData.CreateValidationTableData(Resources.ConnectionString, NodeLevel, LocationId, True, False, CalcId, NodeRowId,
                    Resources.UserSecurity.UserId.Value, isMonthPurged, Resources.UserSecurity, areOutliersDisplayed, nextOutlierCalculationDateTime)

                Dim outlierDictionary As Dictionary(Of String, OutlierDetails) = Nothing
                If (areOutliersDisplayed) Then
                    outlierDictionary = CreateOutlierDetectionDictionary(Resources.ConnectionString, LocationId)
                End If

                returnTable.ID = "StageTable"

                ' If there are no valid data for expanded row, Feed this back to user in a new row.
                If nodeData.Rows.Count = 0 Then
                    data = nodeData.NewRow()
                    data("Description") = "<font color=red>No valid data under this location</font>"
                    data("nodeRowId") = String.Format("{0}_NoData", NodeRowId)
                    nodeData.Rows.Add(data)
                End If

                For Each data In nodeData.Rows
                    AddNodeTableRow(returnTable, data, columns, outlierDictionary)
                Next

                Controls.Add(returnTable)

                'Add call to append nodes
                Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _
                 Tags.ScriptLanguage.JavaScript, "", "AppendApprovalNodes('" & NodeRowId & "');"))
            Catch ex As Exception
                Dim s As String = ex.Message
            End Try

        End Sub

        Friend Overridable Sub AddNodeTableRow(ByVal returnTable As HtmlTableTag,
         ByVal data As DataRow, ByVal columns As ICollection(Of String), ByVal outlierDictionary As Dictionary(Of String, OutlierDetails))
            Dim tonnesFormat As String = ReconcilorFunctions.SetNumericFormatDecimalPlaces(2)
            Dim gradeData As DataTable = DalUtility.GetGradeList(Convert.ToInt16(True))
            Dim gradeRow As DataRow
            Dim grades As New Generic.Dictionary(Of String, Grade)
            Dim descriptionTable As WebControls.Table
            Dim indentedRow As TableRow
            Dim indentedCell As TableCell
            Dim literal As LiteralControl


            Dim callback = Function(ByVal textData As String, ByVal colName As String, ByVal row As DataRow) As String
                               Return ValidationTable_ItemCallbackWithOutlierCheck(textData, colName, row, outlierDictionary)
                           End Function

            For Each gradeRow In gradeData.Rows
                grades.Add(gradeRow("Grade_Name").ToString, New Grade(gradeRow, Application("NumericFormat").ToString))
            Next

            descriptionTable = GetIndentedNodeTable(data, "Description", NodeLevel, callback)
            indentedRow = TryCast(descriptionTable.Controls(0), TableRow)
            indentedCell = TryCast(indentedRow.Controls(indentedRow.Controls.Count - 1), TableCell)
            literal = TryCast(indentedCell.Controls(0), LiteralControl)
            returnTable.AddCellInNewRow().Controls.Add(descriptionTable)

            ProcessRow(returnTable, data, "Tonnes", tonnesFormat, ReconcilorTableColumn.Alignment.Right, callback, columns)

            For Each currentGrade As Grade In grades.Values
                ProcessRowGrade(returnTable, data, currentGrade.Name, grades, callback, columns)
            Next

            ' not sure why we need to process each column and row here, where the top level table does it automatically, but if you
            ' add a new column, this is where it needs to be added (grades should be handled automatically above)
            ProcessRow(returnTable, data, "ApprovedCheck", "", ReconcilorTableColumn.Alignment.Left, callback, columns) ' ApprovedCheck
            ProcessRow(returnTable, data, "SignOff", "", ReconcilorTableColumn.Alignment.Left, callback, columns) ' SignOff
            ProcessRow(returnTable, data, "SignOffDate", _dateFormat, ReconcilorTableColumn.Alignment.Right, callback, columns) ' SignOff
            ProcessRow(returnTable, data, "", ReconcilorTableColumn.Alignment.Right) ' Investigation
            returnTable.CurrentRow.ID = data("nodeRowId").ToString()
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalUtility Is Nothing Then
                DalUtility = New Core.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            If DalPurge Is Nothing Then
                DalPurge = New Database.SqlDal.SqlDalPurge(Resources.Connection)
            End If
        End Sub
    End Class
End Namespace