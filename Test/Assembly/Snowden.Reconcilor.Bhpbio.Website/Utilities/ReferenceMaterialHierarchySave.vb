Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment

Namespace Utilities
    Public Class ReferenceMaterialHierarchySave
        Inherits Core.Website.Utilities.ReferenceMaterialHierarchySave

        Protected Overrides Sub ProcessData()
            MyBase.ProcessData()

            Dim Key As String
            Dim dal As Bhpbio.Database.DalBaseObjects.IUtility = DirectCast(DalUtility, Bhpbio.Database.DalBaseObjects.IUtility)

            dal.DataAccess.BeginTransaction()

            Try
                dal.DeleteBhpbioMaterialTypeLocationAll(MaterialTypeId)

                For Each Key In Request.Form.AllKeys
                    If (Key.StartsWith("location_") AndAlso (Request(Key).Trim = "on")) Then
                        dal.AddBhpbioMaterialTypeLocation(MaterialTypeId, Convert.ToInt32(Key.Replace("location_", "").Trim))
                    End If
                Next

                dal.DataAccess.CommitTransaction()
            Catch ex As Exception
                Try
                    dal.DataAccess.RollbackTransaction()
                Catch
                End Try
            End Try
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

    End Class
End Namespace