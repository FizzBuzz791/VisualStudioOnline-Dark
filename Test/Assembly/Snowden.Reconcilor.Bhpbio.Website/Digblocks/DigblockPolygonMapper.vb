Namespace Digblocks
    Public Class DigblockPolygonMapper
        Inherits Core.Website.Digblocks.DigblockPolygonMapper

        Protected Overrides Sub SetupDalObjects()
            If (DalDepletion Is Nothing) Then
                DalDepletion = New Reconcilor.Bhpbio.Database.SqlDal.SqlDalDepletion(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

    End Class
End Namespace
