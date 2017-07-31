

Imports System.CodeDom
Imports System.Web.UI.WebControls
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Bhpbio.Report.GenericDataTableExtensions
Imports System.Linq

Namespace ReconcilorControls.Inputs
    Public Class PitSelectList
        Private _dalUtility As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility


        Public Function GetPitList(locationGroupId As Integer?, associatedPits As DataTable, allPits As DataTable) As ReconcilorTable
            Dim ReturnTable As ReconcilorTable = Nothing

            Dim myPits = New Dictionary(Of Integer, Boolean)

            For Each pit In associatedPits.Select()
                Dim lid = CType(pit("LocationId"), Integer)
                Dim lgid = CType(pit("LocationGroupId"), Integer)
                Dim x = False
                If (locationGroupId.HasValue) Then
                    x = lgid = locationGroupId.Value
                End If
                myPits.Add(lid, x)
            Next

            allPits.Columns.Add("Include", GetType(String), Nothing)


            For Each row As DataRow In allPits.Rows
                Dim idd = CType(row("Location_Id"), Integer)
                Dim isAssigned = myPits.ContainsKey(idd)
                Dim isAssignedToDeposit = isAssigned AndAlso myPits(idd)

                Dim checked = isAssigned And isAssignedToDeposit
                Dim enabled = Not isAssigned Or isAssignedToDeposit

                row("Include") = String.Format("<input type=""checkbox"" id=""pit_{0}"" name=""pit_{0}"" {1} {2}/>", idd,
                                               IIf(checked, "checked=""checked""", " "),
                                               IIf(enabled, "", "disabled=""true"""))  ' TODo required??
            Next

            Dim excludeColumns() As String = {"Location_Id"}

            'ReturnTable = New ReconcilorTable(DataSource)
            ReturnTable = New ReconcilorTable(allPits) 'TODO not suer about conceopt THIS PARAM IS WRONG THOUGH

            With ReturnTable
                .ID = "PitSelectTable"
                .Columns.Add("Include", New ReconcilorTableColumn("", 50))
                .Columns.Add("Name", New ReconcilorTableColumn("Pit"))
                .ExcludeColumns = excludeColumns
                .DataBind()
            End With

            Return ReturnTable

        End Function

    End Class
End Namespace

