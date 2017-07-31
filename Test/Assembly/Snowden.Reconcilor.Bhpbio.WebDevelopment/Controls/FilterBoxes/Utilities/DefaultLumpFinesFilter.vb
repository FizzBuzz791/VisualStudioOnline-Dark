Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports System.Web.UI
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports System.Web.UI.WebControls

Namespace ReconcilorControls.FilterBoxes.Utilities
    Public Class DefaultLumpFinesFilterBox
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.ReconcilorFilterBox

        Private _dalUtility As IUtility = Nothing
        Private _locationType As New SelectBox
        Private _location As New ReconcilorLocationSelector


        Public Property DalUtility() As IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As IUtility)
                _dalUtility = value
            End Set
        End Property

        Protected Property LocationType() As SelectBox
            Get
                Return _locationType
            End Get
            Set(ByVal value As SelectBox)
                _locationType = value
            End Set
        End Property

        Protected Property Location() As ReconcilorLocationSelector
            Get
                Return _location
            End Get
            Set(ByVal value As ReconcilorLocationSelector)
                _location = value
            End Set
        End Property

        Protected Overrides Sub SetupControls()
            MyBase.SetupControls()

            DalUtility = New SqlDalUtility(Resources.Connection)

            With LocationType
                .ID = "LocationTypeFilter"
                .DataSource = GetLocationTypeList()
                .DataTextField = "Description"
                .DataValueField = "Location_Type_Id"
                .DataBind()

                .Items.Insert(0, New ListItem("-- All --", String.Empty))
            End With

            Location.ID = "LocationFilter"
        End Sub

        Protected Overrides Sub SetupLayout()
            MyBase.SetupLayout()

            With LayoutTable
                .AddCellInNewRow.Controls.Add(Location)
                .CurrentCell.ColumnSpan = 2

                .AddCellInNewRow.Controls.Add(New LiteralControl("Location Type:"))
                .AddCell.Controls.Add(LocationType)
            End With
        End Sub

        Protected Overrides Sub SetupFormAndDatePickers()
            MyBase.SetupFormAndDatePickers()

            ServerForm.ID = "DefaultLumpFinesForm"
            ServerForm.OnSubmit = "return GetDefaultLumpFinesList();"
        End Sub

        Private Function GetLocationTypeList() As DataTable
            Dim locationTypeDataTable As DataTable
            locationTypeDataTable = DalUtility.GetLocationTypeList(DoNotSetValues.Int16)

            For Each row As DataRow In locationTypeDataTable.Rows
                If row("Description").ToString = "Bench" Then
                    locationTypeDataTable.Rows.Remove(row)
                    Exit For
                End If
            Next

            For Each row As DataRow In locationTypeDataTable.Rows
                If row("Description").ToString = "Blast" Then
                    locationTypeDataTable.Rows.Remove(row)
                    Exit For
                End If
            Next

            For Each row As DataRow In locationTypeDataTable.Rows
                If row("Description").ToString = "Block" Then
                    locationTypeDataTable.Rows.Remove(row)
                    Exit For
                End If
            Next

            Return locationTypeDataTable
        End Function

    End Class
End Namespace
