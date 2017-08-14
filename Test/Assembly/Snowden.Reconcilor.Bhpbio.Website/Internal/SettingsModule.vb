Namespace Internal
    Module SettingsModule
        Enum SettingsNames
            SampleStationFilterLocation
            SampleStationFilterLump
            SampleStationFilterFines
            SampleStationFilterRom
        End Enum

        Public ReadOnly Property SettingsDictionary As Dictionary(Of SettingsNames, String)
            Get
                Return New Dictionary(Of SettingsNames, String) From {
                {SettingsNames.SampleStationFilterLocation, "Sample_Station_Filter_Location"},
                {SettingsNames.SampleStationFilterLump, "Sample_Station_Filter_Lump"},
                {SettingsNames.SampleStationFilterFines, "Sample_Station_Filter_Fines"},
                {SettingsNames.SampleStationFilterRom, "Sample_Station_Filter_Rom"}
            }
            End Get
        End Property
    End Module
End Namespace