Imports System.Web.UI
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.WebDevelopment.ReconcilorControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports System.Web.UI.WebControls
Imports Snowden.Reconcilor.Core.WebDevelopment

Namespace ReconcilorControls.FilterBoxes.Utilities
    Public Class HaulageCorrectionFilter
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.HaulageCorrectionFilter


#Region " Properties "
        Private _locationSelector As New Core.WebDevelopment.ReconcilorControls.ReconcilorLocationSelector
        Private _locationPicker As New Inputs.LocationPicker("LocationTreeId")
        Private _dalSecurityLocation As Bhpbio.Database.DalBaseObjects.ISecurityLocation
        Private _LocationFilterButton As New InputTags.InputButton
        Private _locationId As Int32

        Public Property LocationId() As Int32
            Get
                Return _locationId
            End Get
            Set(ByVal value As Int32)
                _locationId = value
            End Set
        End Property
        Public Property DalSecurityLocation() As Bhpbio.Database.DalBaseObjects.ISecurityLocation
            Get
                Return _dalSecurityLocation
            End Get
            Set(ByVal value As Bhpbio.Database.DalBaseObjects.ISecurityLocation)
                _dalSecurityLocation = value
            End Set
        End Property

        Public Property LocationSelector() As Core.WebDevelopment.ReconcilorControls.ReconcilorLocationSelector
            Get
                Return _locationSelector
            End Get
            Set(ByVal value As Core.WebDevelopment.ReconcilorControls.ReconcilorLocationSelector)
                _locationSelector = value
            End Set
        End Property

        Protected ReadOnly Property LocationPicker() As Inputs.LocationPicker
            Get
                Return _locationPicker
            End Get
        End Property
        Public Property LocationFilterButton() As InputTags.InputButton
            Get
                Return _LocationFilterButton
            End Get
            Set(ByVal value As InputTags.InputButton)
                _LocationFilterButton = value
            End Set
        End Property
#End Region

        Protected Overrides Sub SetupControls()
            Dim haulageDal As Bhpbio.Database.DalBaseObjects.IHaulage _
                = DirectCast(DalHaulage, Bhpbio.Database.DalBaseObjects.IHaulage)
            Dim settingLocation As String = Resources.UserSecurity.GetSetting("Haulage_Correction_Filter_Location", "0")

            With LocationSelector
                .ID = "LocationId"
                .LowestLocationTypeDescription = "PIT"
                If Int32.TryParse(settingLocation, LocationId) AndAlso LocationId > 0 Then
                    .LocationId = LocationId
                End If

                .OnChange = "GetHaulageCorrectionSourceAndDestinationByLocation();"

            End With

            'set the new default on the location filter
            'if no location is specified set the default based on the user's location
            If Not LocationSelector.LocationId.HasValue Then
                LocationSelector.LocationId = DalSecurityLocation.GetBhpbioUserLocation(Resources.UserSecurity.UserId.Value)
            End If

            With LocationFilterButton
                .ID = "LocationFilterButton"
                .Text = " Filter Filtering Choices "
                .OnClientClick = "return FilterBhpbioHaulageCorrectionLocations();"
            End With

            'button not required in bhp
            LocationFilterButton.Visible = False

            Destination.DataSource = haulageDal.GetBhpbioHaulageCorrectionListFilter("Destination", LocationId)
            Source.DataSource = haulageDal.GetBhpbioHaulageCorrectionListFilter("Source", LocationId)
            Description.DataSource = haulageDal.GetBhpbioHaulageCorrectionListFilter("Description", LocationId)

            ID = "HaulageCorrectionFilterBox"

            With FilterButton
                .ID = "HaulageFilterButton"
            End With

            With LayoutGroupBox
                .Title = "Filter Haulage Errors"
            End With

            With Description
                .ID = "Description"
                If .DataSource Is Nothing Then
                    .DataSource = DalHaulage.GetHaulageCorrectionListFilter("Description")
                End If
                .DataTextField = "Filter"
                .DataValueField = "Filter"
                .DataBind()

                .Items.Insert(0, New WebControls.ListItem("All", ""))
            End With

            With LimitRecords
                .ID = "LimitRecords"
                .Checked = True
            End With

            MyBase.SetupControls()
        End Sub

        Protected Overrides Sub SetupLayout()
            Dim Cell As TableCell

            With LayoutTable
                .AddCellInNewRow.Controls.Add(LocationSelector)
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Left
                .CurrentCell.Width = 500

                Cell = .AddCellInNewRow
                Cell.HorizontalAlign = HorizontalAlign.Left
                Cell.Controls.Add(LocationFilterButton)

                Dim SourceDiv As New Tags.HtmlDivTag
                SourceDiv.ID = "sourceDiv"
                SourceDiv.Controls.Add(Source)
                .AddCellInNewRow.Controls.Add(New LiteralControl("Source: "))
                .AddCell.Controls.Add(SourceDiv)

                Dim DestinationDiv As New Tags.HtmlDivTag
                DestinationDiv.ID = "destinationDiv"
                DestinationDiv.Controls.Add(Destination)
                .AddCell.Controls.Add(New LiteralControl("Destination: "))
                .AddCell.Controls.Add(DestinationDiv)

                .AddCellInNewRow.Controls.Add(New LiteralControl("Description: "))
                .AddCell.Controls.Add(Description)
                .AddCell.Controls.Add(New LiteralControl("Limit To " & RecordLimit & " Records: "))
                .AddCell.Controls.Add(LimitRecords)

            End With


        End Sub
    End Class
End Namespace
