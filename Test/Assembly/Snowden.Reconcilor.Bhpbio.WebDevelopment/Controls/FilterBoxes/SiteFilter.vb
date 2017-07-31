Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core

Namespace ReconcilorControls.FilterBoxes
    Public Class SiteFilter
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.ReconcilorFilterBox

#Region " Properties "
        Private _locationFilter As New Core.WebDevelopment.ReconcilorControls.ReconcilorLocationSelector()

        Protected ReadOnly Property LocationFilter() As Core.WebDevelopment.ReconcilorControls.ReconcilorLocationSelector
            Get
                Return _locationFilter
            End Get
        End Property
#End Region

        Protected Overrides Sub SetupControls()
            MyBase.SetupControls()

            ID = "SiteFilterBox"

            ButtonOnNewRow = False

            With FilterButton
                .ID = "SiteFilterButton"
                .Text = "View"
                .CssClass = "inputButtonSmall"
            End With

            With LayoutGroupBox
                .Title = "Site Drilldown"
            End With

        End Sub

        Protected Overrides Sub SetupFormAndDatePickers()
            MyBase.SetupFormAndDatePickers()
        End Sub

        Protected Overrides Sub SetupLayout()
            MyBase.SetupLayout()

            With LayoutTable
                .AddCellInNewRow.Controls.Add(LocationFilter)
            End With

        End Sub
    End Class
End Namespace