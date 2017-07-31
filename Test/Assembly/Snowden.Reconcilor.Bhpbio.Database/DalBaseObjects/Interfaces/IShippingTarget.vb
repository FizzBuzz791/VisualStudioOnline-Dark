Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace DalBaseObjects
    ''' <summary>
    ''' Interface supporting by DAL objects used for Shipping Target operations
    ''' </summary>
    Public Interface IShippingTarget
        Inherits Snowden.Common.Database.SqlDataAccessBaseObjects.ISqlDal

        ''' <summary>
        ''' Get a list of shipping target values in a layout that suits user interface display
        ''' </summary>
        ''' <param name="productTypeId">optional product type filter</param>
        ''' <param name="activeInMonth">optional month filter</param>
        ''' <returns>all shipping target periods that match filter criteria with their associated valuesin a denormalised form suited for display</returns>
        Function GetBhpbioShippingTargets(ByVal productTypeId As Nullable(Of Integer), ByVal activeInMonth As Nullable(Of Date)) As DataTable

        ''' <summary>
        ''' Add a new shipping target period
        ''' </summary>
        ''' <param name="producTypeId">identifies the type of product the shipping target relates to</param>
        ''' <param name="effectiveFrom">specifies the month the target relates to</param>
        ''' <param name="userId">specifies the related user Id</param>
        ''' <returns>The Id of the new shipping target</returns>
        Function AddBhpbioShippingTarget(ByVal producTypeId As Integer, ByVal effectiveFrom As Date, ByVal userId As Integer) As Integer

        ''' <summary>
        ''' Update a shipping target modified date and user
        ''' </summary>
        ''' <param name="shippingTargetPeriodId">Identifies the shipping target to be updated</param>
        ''' <param name="userId">identifies the user responsible for the update</param>
        Sub UpdateBhpbioShippingTarget(ByVal producTypeId As Integer, ByVal shippingTargetPeriodId As Integer, effectiveFrom As Date, ByVal userId As Integer)

        ''' <summary>
        ''' Add or update the upper, target , a lower control values assocaited with a target period and attribute combination
        ''' </summary>
        ''' <param name="shippingTargetPeriodId">Identifies the shipping target period to be updated</param>
        ''' <param name="attributeId">the attribute of the shipping target value to be updated</param>
        ''' <param name="upper">optional upper control</param>
        ''' <param name="target">optional target</param>
        ''' <param name="lower">optional lower control</param>
        Sub AddOrUpdateBhpbioShippingTargetValue(ByVal shippingTargetPeriodId As Integer, ByVal attributeId As Integer, ByVal upper As Nullable(Of Double), ByVal target As Nullable(Of Double), ByVal lower As Nullable(Of Double))

        ''' <summary>
        ''' Delete a shipping target and all associated values
        ''' </summary>
        ''' <param name="shippingTargetPeriodId">Identifies the shipping target to be deleted</param>
        Sub DeleteBhpbioShippingTarget(ByVal shippingTargetPeriodId As Integer)

        ''' <summary>
        ''' Delete the values of a shipping target
        ''' </summary>
        ''' <param name="shippingTargetPeriodId">Identifies the shipping target whose values are to be deleted</param>
        Sub DeleteBhpbioShippingTargetValues(ByVal shippingTargetPeriodId As Integer)

    End Interface

End Namespace
