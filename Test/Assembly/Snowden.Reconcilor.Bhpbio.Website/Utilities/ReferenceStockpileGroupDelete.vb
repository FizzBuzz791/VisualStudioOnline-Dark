Namespace Utilities
    Public Class ReferenceStockpileGroupDelete
        Inherits Reconcilor.Core.Website.Utilities.ReferenceStockpileGroupDelete

        Protected Overrides Sub ProcessData()
            MyBase.ProcessData()

            DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)

            Dim dal As Bhpbio.Database.DalBaseObjects.IUtility = DirectCast(DalUtility, Bhpbio.Database.DalBaseObjects.IUtility)

            dal.BhpbioDataExceptionStockpileGroupLocationMissing()
        End Sub
    End Class
End Namespace