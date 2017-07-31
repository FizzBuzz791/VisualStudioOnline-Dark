Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Utilities
    Public Class DefaultDepositList
        Inherits WebpageTemplates.UtilitiesAjaxTemplate

        #Region "Properties"

        Private ReadOnly _locationId As New InputTags.InputHidden

        Protected Property ReturnTable As ReconcilorTable

        Protected Property DalUtility As IUtility

#End Region

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            _LocationId.Value = RequestAsInt32("LocationId").ToString

            _LocationId.ID = "FilteredLocationId"
            If RequestAsInt32("LocationId") = - 1 Then
                _LocationId.Value = DoNotSetValues.Int32.ToString
            ElseIf RequestAsInt32("LocationId") <= - 100000 Then
                '-2147483648
                'In some not initialtes state we get a very small no
                _LocationId.Value = DoNotSetValues.Int32.ToString
            Else
                Resources.UserSecurity.SetSetting("Deposit_Filter_Location", _LocationId.Value)
            End If

            Dim deposit As DataTable = DalUtility.GetBhpbioDepositList(Integer.Parse(_locationId.Value))
            With deposit.Columns
                .Add("Edit", GetType(String), "'<a href=""#"" onclick=""EditDepositLocation(''' + LocationGroupId + ''')"">Edit</a>'")
                .Add("Delete", GetType(String), "'<a href=""#"" onclick=""DeleteDepositLocation(''' + LocationGroupId + ''')"">Delete</a>'")
            End With

            ReturnTable = New ReconcilorTable(deposit)
            With ReturnTable
                .Columns.Add("Name", New ReconcilorTableColumn("Name"))
                .Columns.Add("Pits", New ReconcilorTableColumn("Pits"))
                .ExcludeColumns = {"LocationGroupId"}
                .ID = "ReturnTable"
                .Width = 400
                .DataBind()
            End With

            Controls.Add(ReturnTable)
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalUtility Is Nothing Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub
    End Class
End Namespace