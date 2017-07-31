Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment

Namespace Digblocks
    Public Class DigblockTreeviewGetNode
        Inherits Core.Website.Digblocks.DigblockTreeviewGetNode

        Protected Overrides Function GetDigblockDataList() As System.Data.DataTable
            Dim digblockTable As DataTable
            digblockTable = MyBase.GetDigblockDataList()
            Return DigblockList.CreateBhpDigblockListing(digblockTable, _
                DirectCast(DalDigblock, Bhpbio.Database.DalBaseObjects.IDigblock), Convert.ToInt32(NodeId.Split("_"c)(3)))
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
