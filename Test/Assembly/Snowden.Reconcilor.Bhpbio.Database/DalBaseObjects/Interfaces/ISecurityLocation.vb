Namespace DalBaseObjects
    Public Interface ISecurityLocation
        Inherits Snowden.Common.Database.SqlDataAccessBaseObjects.ISqlDal

        Function IsBhpbioUserInLocation(ByVal userId As Integer, ByVal locationId As Integer) As Boolean

        Function GetBhpbioUserLocation(ByVal userId As Int32) As Int32

        Function GetBhpbioUserLocationList(ByVal userId As Integer) As DataTable

        <System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId:="Login")> _
        Sub SetDigblockTreeUserDefaults(ByVal locationId As Int32, ByVal userId As Int32)

        Function IsDigblockTreeUserSettingAvailable(ByVal userId As Int32) As Boolean
    End Interface
End Namespace
