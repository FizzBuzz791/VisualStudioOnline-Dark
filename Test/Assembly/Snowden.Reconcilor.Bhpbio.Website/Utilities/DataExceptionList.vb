Imports System.Text
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Database
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Report
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects

Namespace Utilities
    Public Class DataExceptionList
        Inherits Core.Website.Utilities.DataExceptionList

        Private _DalUtility As Database.DalBaseObjects.IUtility
        Private _dismissAllButton As New InputButtonFormless

        Public ReadOnly Property DismissAllButton() As InputButtonFormless
            Get
                Return _dismissAllButton
            End Get
        End Property

        Protected Overrides Function FilterTypeData() As DataTable
            Dim ReturnTable As DataTable
            Dim Dal As Bhpbio.Database.DalBaseObjects.IUtility _
                = DirectCast(DalUtility, Bhpbio.Database.DalBaseObjects.IUtility)

            ReturnTable = Dal.GetBhpbioDataExceptionTypeFilteredList(IncludeActive, IncludeDismissed, IncludeResolved, DateFrom, DateTo, DataExceptionTypeId, DescriptionContains, LocationId)

            'Add Primary Key for Merge to match on
            Dim Keys() As DataColumn = {ReturnTable.Columns("Data_Exception_Type_ID")}
            ReturnTable.PrimaryKey = Keys

            Return ReturnTable
        End Function

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If Not LocationId Is Nothing Then
                Resources.UserSecurity.SetSetting("DataException_Filter_LocationId", LocationId.ToString())
            End If
        End Sub

        Protected Overrides Sub SetupDalObjects()
            If (DalUtility Is Nothing) Then
                DalUtility = New Bhpbio.Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

            MyBase.SetupDalObjects()
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            SetupPageControls()
        End Sub

        Protected Overridable Sub SetupPageControls()

            With DismissAllButton
                .ID = "DismissAllButton"
                .Text = "Dismiss All"
                .OnClientClick = "DismissAllClick()"

                ' Hopefully these style tags work in older browsers properly... not just mine.
                .Style.Add("margin-top", "4px")
                .Style.Add("float", "right")
            End With

            Dim clear As New Tags.HtmlDivTag()
            clear.Style.Add("clear", "both")

            Me.Controls.Add(DismissAllButton)
            Me.Controls.Add(clear)
        End Sub

    End Class
End Namespace