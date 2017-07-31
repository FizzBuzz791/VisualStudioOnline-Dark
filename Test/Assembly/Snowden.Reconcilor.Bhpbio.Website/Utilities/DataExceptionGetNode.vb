Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Utilities
    Public Class DataExceptionGetNode
        Inherits Core.Website.Utilities.DataExceptionGetNode

        Protected Overrides Function FilterNodeData(ByVal ExceptionTypeID As Integer) As System.Data.DataTable
            Dim ReturnTable As DataTable
            Dim settingLocation As Int32
            Dim Dal As Bhpbio.Database.DalBaseObjects.IUtility _
                = DirectCast(DalUtility, Bhpbio.Database.DalBaseObjects.IUtility)

            If Not Int32.TryParse(Resources.UserSecurity.GetSetting("DataException_Filter_LocationId", "0"), settingLocation) Then
                settingLocation = DoNotSetValues.Int32
            End If


            'Get the schema from a deliberate call to procedure that returns nothing
            ReturnTable = Dal.GetBhpbioDataExceptionFilteredList(IncludeActive, IncludeDismissed, IncludeResolved, DateFrom, DateTo, ExceptionTypeID, DescriptionContains, _
                                                                  CInt(IIf(MaxDataExceptionsOfEachType Is Nothing OrElse MaxDataExceptionsOfEachType.Value <= 0, DefaultMaxDataExceptionsEachNode, MaxDataExceptionsOfEachType.Value)), _
                                                                  LocationId)

            Return ReturnTable
        End Function



        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub
    End Class
End Namespace