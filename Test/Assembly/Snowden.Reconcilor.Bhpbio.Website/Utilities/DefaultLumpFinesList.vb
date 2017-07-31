Imports System.Web.UI
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal

Namespace Utilities
    Public Class DefaultLumpFinesList
        Inherits Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _dalUtility As IUtility
        Private _returnTable As ReconcilorTable
        Private _locationId As Int32? = Nothing
        Private _locationTypeId As Int32? = Nothing

        Protected Property DalUtility() As IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As IUtility)
                _dalUtility = value
            End Set
        End Property

        Protected Property ReturnTable() As ReconcilorTable
            Get
                Return _returnTable
            End Get
            Set(ByVal value As ReconcilorTable)
                _returnTable = value
            End Set
        End Property

        Protected Property LocationId() As Int32?
            Get
                Return _locationId
            End Get
            Set(ByVal value As Int32?)
                _locationId = value
            End Set
        End Property

        Protected Property LocationTypeId() As Int32?
            Get
                Return _locationTypeId
            End Get
            Set(ByVal value As Int32?)
                _locationTypeId = value
            End Set
        End Property

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            Dim val As Int32

            If Not Request("LocationTypeFilter") Is Nothing Then
                If Int32.TryParse(Request("LocationTypeFilter").ToString, val) Then
                    LocationTypeId = val
                End If
            End If

            If Not Request("LocationFilter") Is Nothing Then
                If Int32.TryParse(Request("LocationFilter").ToString, val) Then
                    If val > 0 Then 'only set valid location id
                        LocationId = val
                    End If
                End If
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Dim dataTable As DataTable = DalUtility.GetBhpbioDefaultLumpFinesList(LocationId, LocationTypeId)

            If Resources.UserSecurity.HasAccess("BHPBIO_DEFAULT_LUMP_FINES_EDIT") Then
                With dataTable.Columns
                    .Add("Edit", GetType(String), "'<a href=""#"" onclick=""EditDefaultLumpFines(''' + BhpbioDefaultLumpFinesId + ''')"">Edit</a>'")
                    .Add("Delete", GetType(String))
                End With

                For Each row As DataRow In dataTable.Rows
                    If Convert.ToBoolean(row("IsNonDeletable")) Then
                        row("Delete") = "Default"
                    Else
                        row("Delete") = String.Format("<a href=""#"" onclick=""DeleteDefaultLumpFines('{0}')"">Delete</a>", row("BhpbioDefaultLumpFinesId"))
                    End If
                Next
            End If

            Dim excludeColumns() As String = {"BhpbioDefaultLumpFinesId", "IsNonDeletable"}

            Dim dateFormat As String = "dd-MMM-yyyy"
            If Not Application("DateFormat") Is Nothing Then
                dateFormat = Application("DateFormat").ToString
            End If

            ReturnTable = New ReconcilorTable(dataTable)
            With ReturnTable
                .ExcludeColumns = excludeColumns
                .Columns.Add("LocationName", New ReconcilorTableColumn("Location Name"))
                .Columns.Add("LocationType", New ReconcilorTableColumn("Location Type"))
                .Columns.Add("StartDate", New ReconcilorTableColumn("Start Date"))
                .Columns("StartDate").DateTimeFormat = dateFormat
                .Columns.Add("LumpPercentage", New ReconcilorTableColumn("Lump Percentage"))
                .Columns("LumpPercentage").NumericFormat = "#,##0.00"
                .DataBind()
            End With

            Controls.Add(ReturnTable)
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If _dalUtility Is Nothing Then
                _dalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub

    End Class
End Namespace

