Imports System.Text
Imports rf = Snowden.Reconcilor.Core.WebDevelopment.ReconcilorFunctions
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI

Namespace Digblocks
    Public Class DigblockList
        Inherits Core.Website.Digblocks.DigblockList

        Protected Overrides Sub RunAjax()
            Dim useColumns As New Generic.List(Of String)
            Dim index As Int32

            MyBase.RunAjax()

            If Not DigblockTable Is Nothing Then
                If DigblockTable.DataSource.Rows.Count = 0 Then
                    Controls.Remove(DigblockTable)
                    Dim message As New Tags.HtmlPTag
                    message.InnerText = "   No Records Returned."
                    Controls.Add(message)
                Else
                    For index = 0 To DigblockTable.UseColumns.Length - 1
                        If DigblockTable.UseColumns(index) <> "Delete" _
                             And DigblockTable.UseColumns(index) <> "Edit" Then

                            useColumns.Add(DigblockTable.UseColumns(index))
                        End If
                    Next

                    DigblockTable.UseColumns = useColumns.ToArray()
                    DigblockTable.DataBind()

                End If
            End If

        End Sub

        Protected Overrides Function GetDigblockListData(ByVal excludeGrades As Boolean) As DataTable
            Dim digblockList As New DataTable

            digblockList = MyBase.GetDigblockListData(excludeGrades)

            digblockList = CreateBhpDigblockListing(digblockList, DirectCast(DalDigblock, Bhpbio.Database.DalBaseObjects.IDigblock), LocationId)

            Return digblockList
        End Function

        Public Shared Function CreateBHPDigblockListing(ByVal digblock As DataTable, _
            ByRef dal As Bhpbio.Database.DalBaseObjects.IDigblock, ByVal FilterLocationId As Integer) As DataTable

            Dim minedPercentage As DataTable = Nothing
            Dim digblockRowToModify As DataRow()

            digblock.Columns.Add("Depleted_Blast_Block", GetType(Double), Nothing)
            digblock.Columns.Add("Depleted_Resource", GetType(Double), Nothing)
            digblock.Columns.Add("Depleted_Reserve", GetType(Double), Nothing)

            Try
                minedPercentage = dal.GetBhpbioReconciliationMovements(FilterLocationId)
                For Each row As DataRow In minedPercentage.Rows
                    digblockRowToModify = digblock.Select("Digblock_Id = '" + row("Digblock_Id").ToString + "'")
                    If digblockRowToModify.Length > 0 Then
                        digblockRowToModify(0)("Depleted_Blast_Block") = row("Depleted_Blast_Block")
                        digblockRowToModify(0)("Depleted_Resource") = row("Depleted_Resource")
                        digblockRowToModify(0)("Depleted_Reserve") = row("Depleted_Reserve")
                    End If
                Next
            Finally
                If Not minedPercentage Is Nothing Then
                    minedPercentage.Dispose()
                    minedPercentage = Nothing
                End If
            End Try
            Return digblock
        End Function

        Protected Overrides Sub SetupDalObjects()
            If (DalDigblock Is Nothing) Then
                DalDigblock = New Bhpbio.Database.SqlDal.SqlDalDigblock(Resources.Connection)
            End If

            If (DalUtility Is Nothing) Then
                DalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

    End Class
End Namespace
