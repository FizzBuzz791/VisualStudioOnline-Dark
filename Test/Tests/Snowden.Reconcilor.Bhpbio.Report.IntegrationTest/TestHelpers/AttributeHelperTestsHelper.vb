Imports System.Collections.Generic
Imports System.Data
Imports Snowden.Reconcilor.Core
Module AttributeHelperTestsHelper
    Public Function BuildGradeDictionary() As Dictionary(Of String, Grade)
        Dim gradeDictionary = New Dictionary(Of String, Grade)
        Dim dt = New DataTable

        dt.Columns.Add("Grade_Name")
        dt.Columns.Add("Grade_Id")
        dt.Columns.Add("Description")
        dt.Columns.Add("Order_No")
        dt.Columns.Add("Units")
        dt.Columns.Add("Display_Precision")
        dt.Columns.Add("Display_Format")
        dt.Columns.Add("Grade_Type_Id")
        dt.Columns.Add("Is_Visible")



        gradeDictionary.Add("Fe", New Grade(BuildRow(dt, "Fe", 1, 20, "%", 2), "#0"))
        gradeDictionary.Add("P", New Grade(BuildRow(dt, "P", 2, 30, "%", 2), "#0"))
        gradeDictionary.Add("SiO2", New Grade(BuildRow(dt, "SiO2", 3, 40, "%", 2), "#0"))
        gradeDictionary.Add("Al2O3", New Grade(BuildRow(dt, "Al2O3", 4, 50, "%", 2), "#0"))
        gradeDictionary.Add("LOI", New Grade(BuildRow(dt, "LOI", 5, 60, "%", 2), "#0"))
        gradeDictionary.Add("Density", New Grade(BuildRow(dt, "Density", 6, 10, "t/m3", 2), "#0"))
        gradeDictionary.Add("H2O", New Grade(BuildRow(dt, "H2O", 7, 70, "%", 2), "#0"))
        gradeDictionary.Add("H2O-As-Dropped", New Grade(BuildRow(dt, "H2O-As-Dropped", 8, 80, "%", 2), "#0"))
        gradeDictionary.Add("H2O-As-Shipped", New Grade(BuildRow(dt, "H2O-As-Shipped", 9, 90, "%", 2), "#0"))
        gradeDictionary.Add("Ultrafines", New Grade(BuildRow(dt, "Ultrafines", 10, 95, "%", 2), "#0"))

        Return gradeDictionary
    End Function

    Private Function BuildRow(dt As DataTable, name As String, id As Integer, orderNo As Integer, units As String, displayPrecision As Integer) As DataRow
        Dim dr As DataRow = dt.NewRow

        dr("Grade_Name") = name
        dr("Grade_Id") = id
        dr("Description") = name
        dr("Order_No") = orderNo
        dr("Units") = units
        dr("Display_Precision") = displayPrecision
        dr("Display_Format") = "DP"
        dr("Grade_Type_Id") = If(name.Equals("Density"), "Density", "Normal")
        dr("Is_Visible") = True

        Return dr
    End Function
End Module
