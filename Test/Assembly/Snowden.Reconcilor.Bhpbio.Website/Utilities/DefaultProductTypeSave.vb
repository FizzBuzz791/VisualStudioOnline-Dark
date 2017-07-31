Imports System.Text
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports System.Data.SqlClient
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace Utilities
    Public Class DefaultProductTypeSave
        Inherits Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates.UtilitiesAjaxTemplate

        Private _bhpbioDefaultProductTypeId As Integer? = Nothing
        Private _isNonDeletable As Boolean
        Private _locationId As Integer = Nothing
        Private _startDate As Date = Nothing
        Private _dalUtility As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
        Private _description As String = Nothing
        Private _defaultProductTypeSize As String = Nothing
        Private _codeBox As String = Nothing
        Private _returnTable As ReconcilorTable
        Private _locations As ArrayList = New ArrayList()

        Protected Property BhpbioDefaultProductTypeId() As Integer?
            Get
                Return _bhpbioDefaultProductTypeId
            End Get
            Set(ByVal value As Integer?)
                _bhpbioDefaultProductTypeId = value
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

        Public Property Description() As String
            Get
                Return _description
            End Get
            Set(ByVal value As String)
                _description = value
            End Set
        End Property

        Protected Property ProductSize() As String
            Get
                Return _defaultProductTypeSize
            End Get
            Set(ByVal value As String)
                _defaultProductTypeSize = value
            End Set
        End Property
        Protected Property CodeBox() As String
            Get
                Return _codeBox
            End Get
            Set(ByVal value As String)
                _codeBox = value
            End Set
        End Property

        Protected Property DalUtility() As Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Database.DalBaseObjects.IUtility)
                _dalUtility = value
            End Set
        End Property
        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            Description = RequestAsString("Description")
            ProductSize = RequestAsString("productTypeProductSize")
            CodeBox = RequestAsString("CodeBox")
            BhpbioDefaultProductTypeId = RequestAsInt32("BhpbioDefaultProductTypeId")
            Dim hubsDataTable As DataTable = DalUtility.GetBhpbioLocationChildrenNameWithOverride(1, DateTime.Now, DateTime.Now)
            For Each row As DataRow In hubsDataTable.Rows
                Dim idd As String = row("Location_Id").ToString()
                If Not RequestAsString("hub_" + idd) Is Nothing Then
                    _locations.Add(idd)
                End If
            Next
        End Sub

        Protected Overrides Function ValidateData() As String
            Dim errorMessage As New StringBuilder(MyBase.ValidateData())

            If Request("BhpbioDefaultProductTypeId") = String.Empty Then 'New record
                BhpbioDefaultProductTypeId = 0
            End If

            If CodeBox = "" Then
                errorMessage.Append("\nCode parameter was not provided.")
            End If
            If Description = "" Then
                errorMessage.Append("\nDescription parameter was not provided.")
            End If
            If _locations.Count = 0 Then
                errorMessage.Append("\nHUB parameter was not provided.")
            End If

            Return errorMessage.ToString
        End Function

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            Try
                If BhpbioDefaultProductTypeId Is Nothing Then
                    EventLogDescription = "Save new Product Type record"
                Else
                    EventLogDescription = String.Format("Save update to Product Type record ID: {0}", BhpbioDefaultProductTypeId)
                End If

                Dim errorMessage As String = ValidateData()

                If errorMessage = String.Empty Then

                    DalUtility.AddOrUpdateProductTypeRecord(BhpbioDefaultProductTypeId, CodeBox, Description, ProductSize, _locations)

                    JavaScriptAlert("Product Type saved successfully.", String.Empty, "GetDefaultProductTypeList();")
                Else
                    JavaScriptAlert(errorMessage, "Please fix the following issues:")
                End If
            Catch ex As SqlException
                If ex.Message.Contains("Violation of UNIQUE KEY") Then
                    JavaScriptAlert(String.Format("Product Type: {0} already exists.", CodeBox))
                Else
                    JavaScriptAlert(String.Format("Error while saving Product Type: {0}", ex.Message))
                End If

            End Try
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If _dalUtility Is Nothing Then
                _dalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub
    End Class
End Namespace
