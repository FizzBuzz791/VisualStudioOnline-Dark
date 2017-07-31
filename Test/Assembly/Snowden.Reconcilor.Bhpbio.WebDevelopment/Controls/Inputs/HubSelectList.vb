

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
    Public Class HubSelectList


        Private _producttypeSelect As New InputTags.SelectBox
        Private _ProductLocations As DataTable
        Private _dalUtility As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
        Private _locations As ArrayList = New ArrayList()
        Private _dataSource As Data.DataTable = Nothing
        Public Property DataSource() As Data.DataTable
            Get
                Return _dataSource
            End Get
            Set(ByVal value As Data.DataTable)
                If (Not value Is Nothing) Then
                    _dataSource = value
                End If
            End Set
        End Property

        Public Sub New()
            MyBase.New()

        End Sub

        Public Property DalUtility() As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects.IUtility)
                _dalUtility = value
            End Set
        End Property

        Public Sub LoadData()
            If DalUtility Is Nothing Then Throw New Exception("Cannot Load Hub Select data without DalUtility")

            If DataSource Is Nothing Then
                DataSource = DalUtility.GetBhpbioLocationChildrenNameWithOverride(1, DateTime.Now, DateTime.Now)
            End If

        End Sub

        Public Function GetHubSelectList() As ReconcilorTable
            Return GetHubSelectList(New ArrayList)
        End Function


        Public Function GetHubSelectList(SelectedHubs As ArrayList) As ReconcilorTable
            Dim ReturnTable As ReconcilorTable = Nothing

            LoadData()

            With DataSource
                .Columns.Add("Include", GetType(String), Nothing)
            End With

            For Each row As DataRow In DataSource.Rows
                Dim idd As String = row("Location_Id").ToString()
                Dim Is_Location = SelectedHubs.Contains(idd)
                row("Include") = String.Format("<input type=""checkbox"" id=""hub_{0}"" name=""hub_{0}"" {1}/>", idd, IIf(Is_Location, "checked=""checked""", " "))
            Next

            Dim excludeColumns() As String = {"Location_Id", "Location_Type_Description"}

            ReturnTable = New ReconcilorTable(DataSource)

            With ReturnTable
                .ID = "HubSelectTable"
                .Columns.Add("Include", New ReconcilorTableColumn("", 50))
                .Columns.Add("Name", New ReconcilorTableColumn("Hub"))
                .ExcludeColumns = excludeColumns
                .DataBind()
            End With

            Return ReturnTable

        End Function

    End Class
End Namespace

