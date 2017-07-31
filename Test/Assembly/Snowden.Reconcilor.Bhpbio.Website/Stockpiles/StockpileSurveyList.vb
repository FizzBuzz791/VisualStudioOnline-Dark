Namespace Stockpiles
    Public Class StockpileSurveyList
        Inherits Core.Website.Stockpiles.StockpileSurveyList

        Protected Overrides Sub SetupPageControls()
            Dim useColumns As String()
            Dim index As Int32

            MyBase.SetupPageControls()

            'remove the columns and re-bind
            useColumns = Nothing
            For index = 0 To SurveyTable.UseColumns.Length - 1
                If SurveyTable.UseColumns(index) <> "Approval" _
                     And SurveyTable.UseColumns(index) <> "Delete" _
                     And SurveyTable.UseColumns(index) <> "View" Then
                    If useColumns Is Nothing Then
                        ReDim Preserve useColumns(0)
                    Else
                        ReDim Preserve useColumns(useColumns.Length)
                    End If

                    useColumns(useColumns.Length - 1) = SurveyTable.UseColumns(index)
                End If
            Next
            SurveyTable.UseColumns = useColumns

            SurveyTable.DataBind()
        End Sub
    End Class
End Namespace
