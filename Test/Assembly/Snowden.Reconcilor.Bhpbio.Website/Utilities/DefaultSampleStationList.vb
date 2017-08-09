Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Bhpbio.Website.Internal.SettingsModule
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace Utilities
    Public Class DefaultSampleStationList
        Inherits WebpageTemplates.UtilitiesAjaxTemplate

        Protected Property ReturnTable As ReconcilorTable
        Protected Property DalUtility As IUtility

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalUtility Is Nothing Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Dim locationId = RequestAsInt32("LocationId")

            If locationId = -1 Then
                locationId = DoNotSetValues.Int32
            Else
                Resources.UserSecurity.SetSetting(SettingsDictionary.Item(SettingsNames.SampleStationFilterLocation), locationId.ToString)
            End If

            Dim lumpFilter = RequestAsBoolean("LumpFilter")
            Resources.UserSecurity.SetSetting(SettingsDictionary.Item(SettingsNames.SampleStationFilterLump), lumpFilter.ToString)
            Dim finesFilter = RequestAsBoolean("FinesFilter")
            Resources.UserSecurity.SetSetting(SettingsDictionary.Item(SettingsNames.SampleStationFilterFines), finesFilter.ToString)
            Dim romFilter = RequestAsBoolean("RomFilter")
            Resources.UserSecurity.SetSetting(SettingsDictionary.Item(SettingsNames.SampleStationFilterRom), romFilter.ToString)

            Dim productSizeList As List(Of String) = New List(Of String)
            If lumpFilter Then
                productSizeList.Add("LUMP")
            End If
            If finesFilter Then
                productSizeList.Add("FINES")
            End If
            If romFilter Then
                productSizeList.Add("ROM")
            End If
            Dim productSizes As String = String.Join(",", productSizeList.ToArray())

            Dim sampleStations As DataTable = DalUtility.GetBhpbioSampleStationList(locationId, productSizes)
            With sampleStations.Columns
                .Add("Edit", GetType(String), "'<a href=""#"" onclick=""EditSampleStation(''' + Id + ''')"">Edit</a>'")
                .Add("Delete", GetType(String), "'<a href=""#"" onclick=""DeleteSampleStation(''' + Id + ''')"">Delete</a>'")
            End With

            ReturnTable = New ReconcilorTable(sampleStations)
            With ReturnTable
                .ExcludeColumns = {"Id"}
                .ID = "ReturnTable"
                .DataBind()
            End With

            Controls.Add(ReturnTable)
        End Sub
    End Class
End Namespace