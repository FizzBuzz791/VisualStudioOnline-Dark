Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace Reports
    Public Class GetLocationsByLocationType
        Inherits WebpageTemplates.ReportsAjaxTemplate

#Region "Properties"
        Private _disposed As Boolean
        Private _locationId As Integer
		Private _divName As String
		Private _startDate As DateTime?
        Private _dalUtility As Database.DalBaseObjects.IUtility

        Public Property DalUtility() As Database.DalBaseObjects.IUtility
            Get
                Return _dalUtility
            End Get
            Set(ByVal value As Database.DalBaseObjects.IUtility)
                _dalUtility = value
            End Set
        End Property
#End Region

#Region " Destructors "
        Protected Overrides Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        DisposeObject(_dalUtility)
                        _dalUtility = Nothing
                    End If

                    'Clean up unmanaged resources ie: Pointers & Handles
                End If

                _disposed = True
            Finally
                MyBase.Dispose(disposing)
            End Try
        End Sub
#End Region

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If (DalUtility Is Nothing) Then
				DalUtility = New Database.SqlDal.SqlDalUtility(Resources.Connection)
            End If

        End Sub

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            _locationId = RequestAsInt32("LocationId")
			_divName = RequestAsString("DivName")

			Dim startDate As String = RequestAsString("startDate")

			If (IsDate(startDate)) Then
				_startDate = Convert.ToDateTime(startDate)
			End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

			Dim locations As DataTable
            Dim checkBox As InputTags.InputCheckBoxFormless
            Dim layoutTable As New Tags.HtmlTableTag
            Dim currentCount As Integer = 0
            Dim checkAll As New Tags.HtmlAnchorTag
            Dim uncheckAll As New Tags.HtmlAnchorTag
            Dim checkboxPrefix As String = "chkLocation_"

			layoutTable.AddRow()

			If (_startDate.HasValue) Then
				locations = DalUtility.GetBhpbioLocationListWithOverride(_locationId, Convert.ToInt16(True), _startDate.Value)
			Else
				locations = DalUtility.GetLocationList(1, _locationId, DoNotSetValues.Int32, DoNotSetValues.Int16, Convert.ToInt16(True))
			End If

            For Each row As DataRow In locations.Rows
                checkBox = New InputTags.InputCheckBoxFormless()
                checkBox.ID = checkboxPrefix + row("Location_Id").ToString
                checkBox.Checked = True

                layoutTable.AddCell().Controls.Add(checkBox)
                layoutTable.CurrentCell.Controls.Add(New Web.UI.LiteralControl(row("Name").ToString))
                layoutTable.AddCell().Controls.Add(New Web.UI.LiteralControl("&nbsp;"))

                currentCount += 1

                If currentCount = 3 Then
                    currentCount = 0
                    layoutTable.AddRow()
                End If
            Next

            If currentCount = 0 Then
                layoutTable.AddCell()
            Else
                layoutTable.AddCellInNewRow()
            End If

            layoutTable.CurrentCell.Controls.Add(checkAll)
            layoutTable.CurrentCell.Controls.Add(New Web.UI.LiteralControl("&nbsp;"))
            layoutTable.CurrentCell.Controls.Add(uncheckAll)

            checkAll.InnerText = "[Check All]"
            uncheckAll.InnerText = "[Un-check All]"

            checkAll.Attributes("onclick") = String.Format("return CheckAll('{0}','');", checkboxPrefix)
            uncheckAll.Attributes("onclick") = String.Format("return UncheckAll('{0}','');", checkboxPrefix)

            Controls.Add(layoutTable)
        End Sub
    End Class
End Namespace
