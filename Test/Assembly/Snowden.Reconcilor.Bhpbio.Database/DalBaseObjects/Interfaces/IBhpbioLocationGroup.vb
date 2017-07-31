Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace DalBaseObjects
    Public Interface IBhpbioLocationGroup
        Inherits Snowden.Common.Database.SqlDataAccessBaseObjects.ISqlDal

        Function GetBhpbioLocationGroup(locationGroupId As Integer) As DataTable
    End Interface
End Namespace
