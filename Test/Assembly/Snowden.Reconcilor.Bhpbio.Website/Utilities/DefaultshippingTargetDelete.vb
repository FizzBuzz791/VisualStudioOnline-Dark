Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports System.Data.SqlClient
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace Utilities
    Public Class DefaultshippingTargetDelete
        Inherits Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _shippingTargetPeriodId As Integer = 0
        Private _dalUtility As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
        Private _dalShippingTarget As IShippingTarget

        Protected Property ShippingTargetPeriodId() As Integer
            Get
                Return _shippingTargetPeriodId
            End Get
            Set(ByVal value As Integer)
                _shippingTargetPeriodId = value
            End Set
        End Property
        Protected Property DalShippingTarget() As IShippingTarget
            Get
                Return _dalShippingTarget
            End Get
            Set(ByVal value As IShippingTarget)
                _dalShippingTarget = value
            End Set
        End Property

        Protected Property DalUtility() As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility)
                _dalUtility = value
            End Set
        End Property

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If Not Request("ShippingTargetPeriodId") Is Nothing Then
                Integer.TryParse(Request("ShippingTargetPeriodId"), ShippingTargetPeriodId)
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                EventLogDescription = String.Format("Deleting Shipping Target record ID: {0}", ShippingTargetPeriodId)
                DalShippingTarget.DeleteBhpbioShippingTarget(ShippingTargetPeriodId)
                JavaScriptAlert("Shipping Target deleted successfully.", String.Empty, "GetDefaultshippingTargetList();")
            Catch ex As SqlException
                JavaScriptAlert(String.Format("Error while deleting Shipping Target: {0}", ex.Message))
            End Try
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If _dalUtility Is Nothing Then
                _dalUtility = New SqlDalUtility(Resources.Connection)
            End If
            If _dalShippingTarget Is Nothing Then
                _dalShippingTarget = New SqlDalShippingTarget(Resources.Connection)
            End If
        End Sub

    End Class
End Namespace
