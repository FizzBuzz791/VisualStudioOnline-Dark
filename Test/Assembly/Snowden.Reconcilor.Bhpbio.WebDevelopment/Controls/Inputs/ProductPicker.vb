

Imports System.CodeDom
Imports System.Web.UI.WebControls
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database
Imports Snowden.Reconcilor.Core.WebDevelopment

Namespace ReconcilorControls.Inputs
    Public Class ProductPicker
        Inherits SelectBox

        Private _producttypeSelect As New InputTags.SelectBox
        Private _productTypeData As DataTable
        Private _dalUtility As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility

        Public Property DalUtility() As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility)
                _dalUtility = value
            End Set
        End Property

        Public Sub New()
            MyBase.New()
        End Sub

        Public Sub New(dal As DalBaseObjects.IUtility, ByVal useId As Boolean)
            MyBase.New()
            DalUtility = dal
            Populate(useId)
        End Sub
        Public Sub New(dal As DalBaseObjects.IUtility)
            MyBase.New()
            DalUtility = dal
            Populate(False)
        End Sub

        Public Sub Populate(ByVal useId As Boolean)
            If DalUtility Is Nothing Then
                Throw New Exception("Cannot populate ProductType dropdown without DalUtility")
            End If
            Dim productTypeId As String
            _productTypeData = DalUtility.GetBhpbioProductTypeList()

            ID = "productTypeCode"

            If useId Then
                Items.Insert(0, New ListItem("(Select)", "-1"))
            Else
                Items.Insert(0, New ListItem("(Select)", "NONE"))
            End If


            For Each row As DataRow In _productTypeData.Rows
                Dim description = String.Format("{0} - {1}", row("ProductTypeCode"), row("Description"))
                If useId Then
                    productTypeId = row("ProductTypeId").ToString
                Else
                    productTypeId = row("ProductTypeCode").ToString
                End If

                Items.Add(New ListItem(description, productTypeId.ToString))
            Next

        End Sub


    End Class
End Namespace

