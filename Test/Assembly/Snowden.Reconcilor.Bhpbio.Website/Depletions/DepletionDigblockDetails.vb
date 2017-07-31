Namespace Depletions
    Public Class DepletionDigblockDetails
        Inherits Core.Website.Depletions.DepletionDigblockDetails


        Protected Overrides Sub SetupDalObjects()
            If (DalDepletion Is Nothing) Then
                DalDepletion = New Reconcilor.Bhpbio.Database.SqlDal.SqlDalDepletion(Resources.Connection)
            End If

            If (DalDigblock Is Nothing) Then
                DalDigblock = New Reconcilor.Bhpbio.Database.SqlDal.SqlDalDigblock(Resources.Connection)
            End If

            If (DalUtility Is Nothing) Then
                DalUtility = New Reconcilor.Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

    End Class
End Namespace
