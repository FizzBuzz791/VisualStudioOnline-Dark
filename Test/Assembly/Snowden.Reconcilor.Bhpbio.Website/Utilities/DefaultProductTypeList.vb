Imports System.Web.UI
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal

Namespace Utilities
    Public Class DefaultProductTypeList
        Inherits Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _dalUtility As IUtility
        Private _returnTable As ReconcilorTable
        Private _locationId As Int32? = Nothing
        Private _locationTypeId As Int32? = Nothing

        Protected Property DalUtility() As IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As IUtility)
                _dalUtility = value
            End Set
        End Property

        Protected Property ReturnTable() As ReconcilorTable
            Get
                Return _returnTable
            End Get
            Set(ByVal value As ReconcilorTable)
                _returnTable = value
            End Set
        End Property


        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Dim dataTable As DataTable = DalUtility.GetBhpbioProductTypeList()

            If Resources.UserSecurity.HasAccess("BHPBIO_DEFAULT_LUMP_FINES_EDIT") Then
                With dataTable.Columns
                    .Add("Edit", GetType(String), "'<a href=""#"" onclick=""EditProductTypeLocation(''' + ProductTypeId + ''')"">Edit</a>'")
                    .Add("Delete", GetType(String), "'<a href=""#"" onclick=""DeleteProductTypeLocation(''' + ProductTypeId + ''')"">Delete</a>'")
                End With

            End If
            Dim excludeColumns() As String = {"ProductTypeId"}

            ReturnTable = New ReconcilorTable(dataTable)
            With ReturnTable
                .Columns.Add("ProductTypeCode", New ReconcilorTableColumn("Product Type"))
                .Columns.Add("Description", New ReconcilorTableColumn("Description"))
                .Columns.Add("Hubs", New ReconcilorTableColumn("Hubs"))
                .Columns.Add("ProductSize", New ReconcilorTableColumn("Product Size"))
                .ExcludeColumns = excludeColumns
                .ID = "ReturnTable"
                .DataBind()
            End With

            Controls.Add(ReturnTable)
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If _dalUtility Is Nothing Then
                _dalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub

    End Class
End Namespace

