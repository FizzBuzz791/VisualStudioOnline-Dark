Imports System.Web.UI
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace ReconcilorControls.FilterBoxes.Utilities
    Public Class DataExceptionFilter
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.DataExceptionFilter

#Region " Properties "
        Private _locationSelector As New ReconcilorLocationSelector
        Private _locationPicker As New Inputs.LocationPicker("LocationTreeId")
        Private _dalSecurityLocation As Database.DalBaseObjects.ISecurityLocation

        Public Property DalSecurityLocation() As Database.DalBaseObjects.ISecurityLocation
            Get
                Return _dalSecurityLocation
            End Get
            Set(ByVal value As Database.DalBaseObjects.ISecurityLocation)
                _dalSecurityLocation = value
            End Set
        End Property

        Public Property LocationSelector() As ReconcilorLocationSelector
            Get
                Return _locationSelector
            End Get
            Set(ByVal value As ReconcilorLocationSelector)
                _locationSelector = value
            End Set
        End Property

        Protected ReadOnly Property LocationPicker() As Inputs.LocationPicker
            Get
                Return _locationPicker
            End Get
        End Property

        Public Property DateFrom As Date
        Public Property DateTo As Date
#End Region

        Protected Overrides Sub SetupControls()
            MyBase.SetupControls()

            Dim locationId As Int32
            Dim settingLocation As String = Resources.UserSecurity.GetSetting("DataException_Filter_LocationId", "0")


            With LocationSelector
                .ID = "LocationId"
                .LowestLocationTypeDescription = "PIT"
                ' Don't reset LocationId if something (a link) has already set it.
                If .LocationId <= 0 AndAlso Int32.TryParse(settingLocation, locationId) AndAlso locationId > 0 Then
                    .LocationId = locationId
                End If
            End With

            'set the new default on the location filter
            'if no location is specified set the default based on the user's location
            If Not LocationSelector.LocationId.HasValue Then
                LocationSelector.LocationId = DalSecurityLocation.GetBhpbioUserLocation(Resources.UserSecurity.UserId.Value)
            End If

            If DatePickers.ContainsKey("DateFrom") And Not (DateFrom.Equals(DateTime.MinValue)) Then
                Dim dateFromPicker = DatePickers("DateFrom")
                dateFromPicker.DateSet = DateFrom
            End If

            If DatePickers.ContainsKey("DateTo") And Not (DateTo.Equals(DateTime.MinValue)) Then
                Dim dateToPicker = DatePickers("DateTo")
                dateToPicker.DateSet = DateTo
            End If
        End Sub

        Protected Overrides Sub SetupLayout()
            MyBase.SetupLayout()

            With LayoutTable
                .AddCellInNewRow()
                .AddCell().Controls.Add(LocationSelector)
                .CurrentCell.VerticalAlign = WebControls.VerticalAlign.Top
                .CurrentCell.HorizontalAlign = WebControls.HorizontalAlign.Left
                .CurrentCell.ColumnSpan = 3
                .AddCellInNewRow()
            End With
        End Sub
    End Class
End Namespace