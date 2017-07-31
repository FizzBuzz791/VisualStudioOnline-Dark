Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment

Namespace Utilities
    Public Class ReferenceBhpbioMaterialTypeLocationList
        Inherits WebpageTemplates.UtilitiesAjaxTemplate

#Region " Properties "
        Private _disposed As Boolean
        Private _DalUtility As Database.DalBaseObjects.IUtility
        Private _MaterialTypeId As Int32 = DoNotSetValues.Int32
        Private _IsIncluded As Int16 = DoNotSetValues.Int16
        Private _ListTable As New DataTable
        Private _ReturnTable As ReconcilorControls.ReconcilorTable

        Public Property DalUtility() As Database.DalBaseObjects.IUtility
            Get
                Return _DalUtility
            End Get
            Set(ByVal value As Database.DalBaseObjects.IUtility)
                If (Not value Is Nothing) Then
                    _DalUtility = value
                End If
            End Set
        End Property

        Public Property MaterialTypeId() As Int32
            Get
                Return _MaterialTypeId
            End Get
            Set(ByVal value As Int32)
                _MaterialTypeId = value
            End Set
        End Property

        Public Property IsIncluded() As Int16
            Get
                Return _IsIncluded
            End Get
            Set(ByVal value As Int16)
                _IsIncluded = value
            End Set
        End Property

        Public Property ListTable() As DataTable
            Get
                Return _ListTable
            End Get
            Set(ByVal value As DataTable)
                If (Not value Is Nothing) Then
                    _ListTable = value
                End If
            End Set
        End Property

        Public Property ReturnTable() As ReconcilorControls.ReconcilorTable
            Get
                Return _ReturnTable
            End Get
            Set(ByVal value As ReconcilorControls.ReconcilorTable)
                If (Not value Is Nothing) Then
                    _ReturnTable = value
                End If
            End Set
        End Property
#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        If (Not _DalUtility Is Nothing) Then
                            _DalUtility.Dispose()
                            _DalUtility = Nothing
                        End If
                    End If

                    'Clean up unmanaged resources ie: Pointers & Handles
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region

        Protected Overridable Sub CreateListTable()
            ListTable = DalUtility.GetBhpbioMaterialTypeLocationList(MaterialTypeId)
            With ListTable
                .Columns.Add("Include", GetType(String), "'<input type=""checkbox"" id=""location_' + LocationID + '"" name=""location_' + LocationID + '""' + IIF(IsIncluded = 1, ' checked=""checked""', ' ') + '/>'")
            End With
        End Sub

        Protected Overridable Sub CreateReturnTable()
            Dim UseColumns() As String = {"Include", "LocationName"}

            ReturnTable = New ReconcilorControls.ReconcilorTable(ListTable, UseColumns)
            With ReturnTable
                .Columns.Add("Include", New ReconcilorControls.ReconcilorTableColumn(""))
                .Columns.Add("LocationName", New ReconcilorControls.ReconcilorTableColumn("Location"))

                With .Columns("Include")
                    .Width = 40
                    .ColumnSortType = ReconcilorControls.ReconcilorTableColumn.SortType.NoSort
                    .HeaderAlignment = ReconcilorControls.ReconcilorTableColumn.Alignment.Left
                    .CheckUncheckAllPart = "location_"
                End With

                .DataBind()
                .Height = 200
            End With
        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            Dim RequestText As String

            If (Not Request("MaterialTypeId") Is Nothing) Then
                RequestText = Request("MaterialTypeId").Trim

                If Not Int32.TryParse(RequestText.ToString.Trim, MaterialTypeId) Then
                    MaterialTypeId = DoNotSetValues.Int32
                End If
            End If

            If (Not Request("IsIncluded") Is Nothing) Then
                RequestText = Request("IsIncluded").Trim

                IsIncluded = Convert.ToInt16(ReconcilorFunctions.ParseNumeric(RequestText))
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            CreateListTable()
            CreateReturnTable()

            Controls.Add(ReturnTable)
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

    End Class
End Namespace