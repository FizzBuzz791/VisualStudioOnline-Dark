Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace SqlDal
    Public Class SqlDalPortImport
        Inherits Snowden.Common.Database.SqlDataAccessBaseObjects.SqlDalBase
        Implements Bhpbio.Database.DalBaseObjects.IPortImport

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

        Public Sub New(ByVal dataAccessConnection As Snowden.Common.Database.DataAccessBaseObjects.IDataAccessConnection)
            MyBase.New(dataAccessConnection)
        End Sub
#End Region

        Function AddBhpbioShippingNominationItem(ByVal nominationKey As Int32, ByVal itemNo As Int32, _
         ByVal officialFinishTime As DateTime, ByVal lastAuthorisedDate As DateTime, ByVal vesselName As String, _
         ByVal customerNo As Int32, ByVal customerName As String, ByVal shippedProduct As String, _
         ByVal shippedProductSize As String, ByVal coa As Nullable(Of DateTime), _
         ByVal undersize As Nullable(Of Double), _
         ByVal oversize As Nullable(Of Double)) As Int32 _
         Implements Bhpbio.Database.DalBaseObjects.IPortImport.AddBhpbioShippingNominationItem

            DataAccess.CommandText = "dbo.AddBhpbioShippingNominationItem"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iNominationKey", nominationKey)
            DataAccess.ParameterCollection.Add("@iItemNo", itemNo)
            DataAccess.ParameterCollection.Add("@iOfficialFinishTime", officialFinishTime)
            DataAccess.ParameterCollection.Add("@iLastAuthorisedDate", lastAuthorisedDate)
            DataAccess.ParameterCollection.Add("@iVesselName", vesselName)
            DataAccess.ParameterCollection.Add("@iCustomerNo", customerNo)
            DataAccess.ParameterCollection.Add("@iCustomerName", customerName)
            DataAccess.ParameterCollection.Add("@iShippedProduct", shippedProduct)
            DataAccess.ParameterCollection.Add("@iShippedProductSize", shippedProductSize)
            DataAccess.ParameterCollection.Add("@iCOA", coa)
            DataAccess.ParameterCollection.Add("@iOversize", oversize)
            DataAccess.ParameterCollection.Add("@iUndersize", undersize)
            DataAccess.ParameterCollection.Add("@oBhpbioShippingNominationItemId", _
             Common.Database.DataAccessBaseObjects.CommandDataType.Int, _
             Common.Database.DataAccessBaseObjects.CommandDirection.Output, NullValues.Int32)

            DataAccess.ExecuteNonQuery()

            Return DirectCast(DataAccess.ParameterCollection("@oBhpbioShippingNominationItemId").Value, Int32)
        End Function

        Sub UpdateBhpbioShippingNominationItem(ByVal bhpbioShippingNominationItemId As Int32, _
         ByVal nominationKey As Int32, ByVal itemNo As Int32, _
         ByVal officialFinishTime As DateTime, ByVal lastAuthorisedDate As DateTime, ByVal vesselName As String, _
         ByVal customerNo As Int32, ByVal customerName As String, ByVal shippedProduct As String, _
         ByVal shippedProductSize As String, ByVal coa As Nullable(Of DateTime), _
         ByVal undersize As Nullable(Of Double), ByVal oversize As Nullable(Of Double)) _
         Implements Bhpbio.Database.DalBaseObjects.IPortImport.UpdateBhpbioShippingNominationItem

            DataAccess.CommandText = "dbo.UpdateBhpbioShippingNominationItem"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioShippingNominationItemId", bhpbioShippingNominationItemId)
            DataAccess.ParameterCollection.Add("@iNominationKey", nominationKey)
            DataAccess.ParameterCollection.Add("@iItemNo", itemNo)
            DataAccess.ParameterCollection.Add("@iOfficialFinishTime", officialFinishTime)
            DataAccess.ParameterCollection.Add("@iLastAuthorisedDate", lastAuthorisedDate)
            DataAccess.ParameterCollection.Add("@iVesselName", vesselName)
            DataAccess.ParameterCollection.Add("@iCustomerNo", customerNo)
            DataAccess.ParameterCollection.Add("@iCustomerName", customerName)
            DataAccess.ParameterCollection.Add("@iShippedProduct", shippedProduct)
            DataAccess.ParameterCollection.Add("@iShippedProductSize", shippedProductSize)
            DataAccess.ParameterCollection.Add("@iCOA", coa)
            DataAccess.ParameterCollection.Add("@iOversize", oversize)
            DataAccess.ParameterCollection.Add("@iUndersize", undersize)

            DataAccess.ExecuteNonQuery()
        End Sub


        Public Sub DeleteBhpbioShippingNominationItem(ByVal bhpbioShippingNominationItemId As Int32) _
         Implements Bhpbio.Database.DalBaseObjects.IPortImport.DeleteBhpbioShippingNominationItem

            DataAccess.CommandText = "dbo.DeleteBhpbioShippingNominationItem"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioShippingNominationItemId", bhpbioShippingNominationItemId)

            DataAccess.ExecuteNonQuery()
        End Sub


        Function AddBhpbioShippingNominationItemParcel(ByVal bhpbioShippingNominationItemId As Int32, _
         ByVal hubLocationId As Int32, ByVal hubProduct As String, ByVal hubProductSize As String, _
         ByVal tonnes As Double) As Int32 _
          Implements Bhpbio.Database.DalBaseObjects.IPortImport.AddBhpbioShippingNominationItemParcel

            DataAccess.CommandText = "dbo.AddBhpbioShippingNominationItemParcel"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioShippingNominationItemId", bhpbioShippingNominationItemId)
            DataAccess.ParameterCollection.Add("@iHubLocationId", hubLocationId)
            DataAccess.ParameterCollection.Add("@iHubProduct", hubProduct)
            DataAccess.ParameterCollection.Add("@iHubProductSize", hubProductSize)
            DataAccess.ParameterCollection.Add("@iTonnes", tonnes)
            DataAccess.ParameterCollection.Add("@oBhpbioShippingNominationItemParcelId", _
             Common.Database.DataAccessBaseObjects.CommandDataType.Int, _
             Common.Database.DataAccessBaseObjects.CommandDirection.Output, NullValues.Int32)

            DataAccess.ExecuteNonQuery()

            Return DirectCast(DataAccess.ParameterCollection("@oBhpbioShippingNominationItemParcelId").Value, Int32)
        End Function

        Sub UpdateBhpbioShippingNominationItemParcel(ByVal bhpbioShippingNominationItemParcelId As Int32, _
         ByVal bhpbioShippingNominationItemId As Int32, ByVal hubLocationId As Int32, _
         ByVal hubProduct As String, ByVal hubProductSize As String, _
         ByVal tonnes As Double) _
          Implements Bhpbio.Database.DalBaseObjects.IPortImport.UpdateBhpbioShippingNominationItemParcel

            DataAccess.CommandText = "dbo.UpdateBhpbioShippingNominationItemParcel"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioShippingNominationItemParcelId", bhpbioShippingNominationItemParcelId)
            DataAccess.ParameterCollection.Add("@iHubLocationId", hubLocationId)
            DataAccess.ParameterCollection.Add("@iHubProduct", hubProduct)
            DataAccess.ParameterCollection.Add("@iHubProductSize", hubProductSize)
            DataAccess.ParameterCollection.Add("@iTonnes", tonnes)

            DataAccess.ExecuteNonQuery()
        End Sub


        Sub DeleteBhpbioShippingNominationItemParcel(ByVal bhpbioShippingNominationItemParcelId As Int32) _
         Implements Bhpbio.Database.DalBaseObjects.IPortImport.DeleteBhpbioShippingNominationItemParcel

            DataAccess.CommandText = "dbo.DeleteBhpbioShippingNominationItemParcel"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioShippingNominationItemParcelId", bhpbioShippingNominationItemParcelId)

            DataAccess.ExecuteNonQuery()

        End Sub

        Public Sub AddOrUpdateBhpbioShippingNominationItemParcelGrade(ByVal bhpbioShippingNominationItemParcelId As Int32, _
         ByVal gradeId As Int16, ByVal gradeValue As Single) _
         Implements Bhpbio.Database.DalBaseObjects.IPortImport.AddOrUpdateBhpbioShippingNominationItemParcelGrade

            DataAccess.CommandText = "dbo.AddOrUpdateBhpbioShippingNominationItemParcelGrade"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioShippingNominationItemParcelId", bhpbioShippingNominationItemParcelId)
            DataAccess.ParameterCollection.Add("@iGradeId", gradeId)
            DataAccess.ParameterCollection.Add("@iGradeValue", gradeValue)

            DataAccess.ExecuteNonQuery()
        End Sub



        Public Function AddBhpbioPortBalances(ByVal HubLocationId As Int32, _
            ByVal balanceDate As DateTime, ByVal tonnes As Double, ByVal product As String, ByVal productSize As String) As Int32 _
            Implements Bhpbio.Database.DalBaseObjects.IPortImport.AddBhpbioPortBalances

            DataAccess.CommandText = "dbo.AddBhpbioPortBalance"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iHubLocationId", HubLocationId)
            DataAccess.ParameterCollection.Add("@iBalanceDate", balanceDate)
            DataAccess.ParameterCollection.Add("@iTonnes", tonnes)
            If Not product Is Nothing Then
                DataAccess.ParameterCollection.Add("@iProduct", product)
            End If
            If Not productSize Is Nothing Then
                DataAccess.ParameterCollection.Add("@iProductSize", productSize)
            End If
            DataAccess.ParameterCollection.Add("@oBhpbioPortBalanceId", _
             Common.Database.DataAccessBaseObjects.CommandDataType.Int, _
             Common.Database.DataAccessBaseObjects.CommandDirection.Output, NullValues.Int32)

            DataAccess.ExecuteNonQuery()

            Return DirectCast(DataAccess.ParameterCollection("@oBhpbioPortBalanceId").Value, Int32)
        End Function

        Public Sub UpdateBhpbioPortBalances(ByVal bhpbioPortBalanceId As Int32, ByVal tonnes As Double, _
            ByVal product As String, ByVal productSize As String) _
            Implements Bhpbio.Database.DalBaseObjects.IPortImport.UpdateBhpbioPortBalances

            DataAccess.CommandText = "dbo.UpdateBhpbioPortBalance"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioPortBalanceId", bhpbioPortBalanceId)
            DataAccess.ParameterCollection.Add("@iTonnes", tonnes)
            If Not product Is Nothing Then
                DataAccess.ParameterCollection.Add("@iProduct", product)
            End If
            If Not productSize Is Nothing Then
                DataAccess.ParameterCollection.Add("@iProductSize", productSize)
            End If

            DataAccess.ExecuteNonQuery()
        End Sub

        Public Sub DeleteBhpbioPortBalances(ByVal bhpbioPortBalanceId As Int32) _
         Implements Bhpbio.Database.DalBaseObjects.IPortImport.DeleteBhpbioPortBalances

            DataAccess.CommandText = "dbo.DeleteBhpbioPortBalance"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioPortBalanceId", bhpbioPortBalanceId)

            DataAccess.ExecuteNonQuery()
        End Sub

        Public Sub AddOrUpdateBhpbioPortBalanceGrade(ByVal bhpbioPortBalanceId As Int32, ByVal gradeId As Int16, ByVal gradeValue As Double) _
            Implements Bhpbio.Database.DalBaseObjects.IPortImport.AddOrUpdateBhpbioPortBalanceGrade

            DataAccess.CommandText = "dbo.AddOrUpdateBhpbioPortBalanceGrade"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioPortBalanceId", CommandDataType.Int, CommandDirection.Input, bhpbioPortBalanceId)
            DataAccess.ParameterCollection.Add("@iGradeId", CommandDataType.SmallInt, CommandDirection.Input, gradeId)
            DataAccess.ParameterCollection.Add("@iGradeValue", CommandDataType.Float, CommandDirection.Input, gradeValue)

            DataAccess.ExecuteNonQuery()
        End Sub

        Public Function AddBhpbioPortBlending(ByVal sourceHubLocationId As Int32, ByVal destinationHubLocationId As Int32, _
            ByVal sourceProduct As String, ByVal sourceProductSize As String, ByVal destinationProduct As String, ByVal destinationProductSize As String, _
            ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal loadSiteLocationId As Int32, ByVal tonnes As Double) As Int32 _
            Implements Bhpbio.Database.DalBaseObjects.IPortImport.AddBhpbioPortBlending

            DataAccess.CommandText = "dbo.AddBhpbioPortBlending"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iSourceHubLocationId", sourceHubLocationId)
            DataAccess.ParameterCollection.Add("@iDestinationHubLocationId", destinationHubLocationId)
            DataAccess.ParameterCollection.Add("@iStartDate", startDate)
            DataAccess.ParameterCollection.Add("@iEndDate", endDate)
            DataAccess.ParameterCollection.Add("@iSourceProductSize", CommandDataType.VarChar, CommandDirection.Input, sourceProductSize)
            DataAccess.ParameterCollection.Add("@iDestinationProductSize", CommandDataType.VarChar, CommandDirection.Input, destinationProductSize)
            DataAccess.ParameterCollection.Add("@iSourceProduct", CommandDataType.VarChar, CommandDirection.Input, sourceProduct)
            DataAccess.ParameterCollection.Add("@iDestinationProduct", CommandDataType.VarChar, CommandDirection.Input, destinationProduct)
            DataAccess.ParameterCollection.Add("@iLoadSiteLocationId", loadSiteLocationId)
            DataAccess.ParameterCollection.Add("@iTonnes", tonnes)
            DataAccess.ParameterCollection.Add("@oBhpbioPortBlendingId", CommandDataType.Int, CommandDirection.Output, NullValues.Int32)

            DataAccess.ExecuteNonQuery()

            Return DirectCast(DataAccess.ParameterCollection("@oBhpbioPortBlendingId").Value, Int32)
        End Function

        Public Sub AddUpdateDeleteBhpbioPortBlendingGrade(ByVal bhpbioPortBlendingId As Int32, _
         ByVal gradeId As Int16, ByVal gradeValue As Single) _
         Implements Bhpbio.Database.DalBaseObjects.IPortImport.AddUpdateDeleteBhpbioPortBlendingGrade

            DataAccess.CommandText = "dbo.AddUpdateDeleteBhpbioPortBlendingGrade"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioPortBlendingId", bhpbioPortBlendingId)
            DataAccess.ParameterCollection.Add("@iGradeId", gradeId)
            DataAccess.ParameterCollection.Add("@iGradeValue", gradeValue)

            DataAccess.ExecuteNonQuery()
        End Sub

        Public Sub UpdateBhpbioPortBlending(ByVal bhpbioPortBlendingId As Int32, ByVal sourceProductSize As String, _
            ByVal destinationProductSize As String, ByVal tonnes As Double) _
            Implements Bhpbio.Database.DalBaseObjects.IPortImport.UpdateBhpbioPortBlending

            DataAccess.CommandText = "dbo.UpdateBhpbioPortBlending"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioPortBlendingId", bhpbioPortBlendingId)
            DataAccess.ParameterCollection.Add("@iSourceProductSize", CommandDataType.VarChar, CommandDirection.Input, sourceProductSize)
            DataAccess.ParameterCollection.Add("@iDestinationProductSize", CommandDataType.VarChar, CommandDirection.Input, destinationProductSize)
            DataAccess.ParameterCollection.Add("@iTonnes", CommandDataType.Float, CommandDirection.Input, tonnes)

            DataAccess.ExecuteNonQuery()
        End Sub

        Public Sub DeleteBhpbioPortBlending(ByVal bhpbioPortBlendingId As Int32) _
         Implements Bhpbio.Database.DalBaseObjects.IPortImport.DeleteBhpbioPortBlending

            DataAccess.CommandText = "dbo.DeleteBhpbioPortBlending"

            DataAccess.ParameterCollection.Clear()
            DataAccess.ParameterCollection.Add("@iBhpbioPortBlendingId", bhpbioPortBlendingId)

            DataAccess.ExecuteNonQuery()
        End Sub


        Public Function GetBhpbioShippingNomination(ByVal nominationId As Int32) As DataTable _
        Implements DalBaseObjects.IPortImport.GetBhpbioShippingNomination
            With DataAccess
                .CommandText = "dbo.GetBhpbioShippingNominationById"
                .ParameterCollection.Clear()
                .ParameterCollection.Add("@iBhpbioShippingNominationItemId", nominationId)
                Return .ExecuteDataTable
            End With
        End Function

    End Class
End Namespace
