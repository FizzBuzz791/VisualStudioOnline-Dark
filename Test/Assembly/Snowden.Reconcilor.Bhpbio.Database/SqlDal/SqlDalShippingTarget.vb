Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports CommonDataHelper = Snowden.Common.Database.DataHelper
Imports Snowden.Reconcilor.Core

Namespace SqlDal
    Public Class SqlDalShippingTarget
        Inherits Core.Database.DalBaseObjects.SqlDalBase
        Implements Bhpbio.Database.DalBaseObjects.IShippingTarget

#Region " Constructors "
        Public Sub New()
            MyBase.New()
        End Sub

        Public Sub New(ByVal connectionString As String)
            MyBase.New(connectionString)
        End Sub

        Public Sub New(ByVal databaseConnection As IDbConnection)
            MyBase.New(databaseConnection)
        End Sub

        Public Sub New(ByVal dataAccessConnection As IDataAccessConnection)
            MyBase.New(dataAccessConnection)
        End Sub
#End Region

        ''' <summary>
        ''' Get a list of shipping target values in a layout that suits user interface display
        ''' </summary>
        ''' <param name="productTypeId">optional product type filter</param>
        ''' <param name="activeInMonth">optional month filter</param>
        ''' <returns>all shipping target periods that match filter criteria with their associated valuesin a denormalised form suited for display</returns>
        Public Function GetBhpbioShippingTargets(productTypeId As Integer?, activeInMonth As Date?) As DataTable Implements IShippingTarget.GetBhpbioShippingTargets

            Dim productTypeIdToSet As Integer = NullValues.Int32
            Dim activeInDateTimeToSet As Date = NullValues.DateTime

            If Not productTypeId Is Nothing Then productTypeIdToSet = productTypeId.Value
            If Not activeInMonth Is Nothing Then activeInDateTimeToSet = activeInMonth.Value

            With DataAccess
                .CommandText = "dbo.GetBhpbioShippingTargets"
                With .ParameterCollection
                    .Clear()
                    .Add("@iProductTypeId", CommandDataType.Int, CommandDirection.Input, productTypeIdToSet)
                    .Add("@iActiveInDateTime", CommandDataType.DateTime, CommandDirection.Input, activeInDateTimeToSet)
                End With
                Return .ExecuteDataTable()
            End With
        End Function

        ''' <summary>
        ''' Add a new shipping target period
        ''' </summary>
        ''' <param name="producTypeId">identifies the type of product the shipping target relates to</param>
        ''' <param name="effectiveFrom">specifies the month the target relates to</param>
        ''' <param name="userId">specifies the related user Id</param>
        ''' <returns>The Id of the new shipping target</returns>
        Public Function AddBhpbioShippingTarget(producTypeId As Integer, effectiveFrom As Date, userId As Integer) As Integer Implements IShippingTarget.AddBhpbioShippingTarget
            With DataAccess
                .CommandText = "dbo.AddBhpbioShippingTarget"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iProductTypeId", CommandDataType.Int, CommandDirection.Input, producTypeId)
                .ParameterCollection.Add("@iEffectiveFromDateTime", CommandDataType.DateTime, CommandDirection.Input, effectiveFrom)
                .ParameterCollection.Add("@iUserId", CommandDataType.Int, CommandDirection.Input, userId)
                .ParameterCollection.Add("@oShippingTargetPeriodId", CommandDataType.Int, CommandDirection.Output, NullValues.Int32)
                .ExecuteNonQuery()

                Return Convert.ToInt32(.ParameterCollection.Item("@oShippingTargetPeriodId").Value)
            End With
        End Function

        ''' <summary>
        ''' Update a shipping target modified date and user
        ''' </summary>
        ''' <param name="shippingTargetPeriodId">Identifies the shipping target to be updated</param>
        ''' <param name="userId">identifies the user responsible for the update</param>
        Public Sub UpdateBhpbioShippingTarget(producTypeId As Integer, shippingTargetPeriodId As Integer, effectiveFrom As Date, userId As Integer) Implements IShippingTarget.UpdateBhpbioShippingTarget
            With DataAccess
                .CommandText = "dbo.UpdateBhpbioShippingTarget"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iProductTypeId", CommandDataType.Int, CommandDirection.Input, producTypeId)
                .ParameterCollection.Add("@iShippingTargetPeriodId", CommandDataType.Int, CommandDirection.Input, shippingTargetPeriodId)
                .ParameterCollection.Add("@iEffectiveFromDateTime", CommandDataType.DateTime, CommandDirection.Input, effectiveFrom)
                .ParameterCollection.Add("@iUserId", CommandDataType.Int, CommandDirection.Input, userId)
                .ExecuteNonQuery()
            End With
        End Sub

        ''' <summary>
        ''' Add or update the upper, target , a lower control values assocaited with a target period and attribute combination
        ''' </summary>
        ''' <param name="shippingTargetPeriodId">Identifies the shipping target period to be updated</param>
        ''' <param name="attributeId">the attribute of the shipping target value to be updated</param>
        ''' <param name="upper">optional upper control</param>
        ''' <param name="target">optional target</param>
        ''' <param name="lower">optional lower control</param>
        Public Sub AddOrUpdateBhpbioShippingTargetValue(shippingTargetPeriodId As Integer, attributeId As Integer, upper As Double?, target As Double?, lower As Double?) Implements IShippingTarget.AddOrUpdateBhpbioShippingTargetValue

            Dim upperToSet As Double = NullValues.Double
            Dim targetToSet As Double = NullValues.Double
            Dim lowerToSet As Double = NullValues.Double

            If Not upper Is Nothing Then upperToSet = upper.Value
            If Not target Is Nothing Then targetToSet = target.Value
            If Not lower Is Nothing Then lowerToSet = lower.Value

            With DataAccess
                .CommandText = "dbo.AddOrUpdateBhpbioShippingTargetValue"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iShippingTargetPeriodId", CommandDataType.Int, CommandDirection.Input, shippingTargetPeriodId)
                .ParameterCollection.Add("@iAttributeId", CommandDataType.Int, CommandDirection.Input, attributeId)
                .ParameterCollection.Add("@iUpperControl", CommandDataType.Decimal, CommandDirection.Input, upperToSet)
                .ParameterCollection.Add("@iTarget", CommandDataType.Decimal, CommandDirection.Input, targetToSet)
                .ParameterCollection.Add("@iLowerControl", CommandDataType.Decimal, CommandDirection.Input, lowerToSet)
                .ExecuteNonQuery()
            End With
        End Sub

        ''' <summary>
        ''' Delete a shipping target and all associated values
        ''' </summary>
        ''' <param name="shippingTargetPeriodId">Identifies the shipping target to be deleted</param>
        Public Sub DeleteBhpbioShippingTarget(shippingTargetPeriodId As Integer) Implements IShippingTarget.DeleteBhpbioShippingTarget
            With DataAccess
                .CommandText = "dbo.DeleteBhpbioShippingTarget"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iShippingTargetPeriodId", CommandDataType.Int, CommandDirection.Input, shippingTargetPeriodId)
                .ExecuteNonQuery()
            End With
        End Sub

        ''' <summary>
        ''' Delete the values of a shipping target
        ''' </summary>
        ''' <param name="shippingTargetPeriodId">Identifies the shipping target whose values are to be deleted</param>
        Public Sub DeleteBhpbioShippingTargetValues(shippingTargetPeriodId As Integer) Implements IShippingTarget.DeleteBhpbioShippingTargetValues
            With DataAccess
                .CommandText = "dbo.DeleteBhpbioShippingTargetPeriodValues"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iShippingTargetPeriodId", CommandDataType.Int, CommandDirection.Input, shippingTargetPeriodId)
                .ExecuteNonQuery()
            End With
        End Sub
    End Class
End Namespace
