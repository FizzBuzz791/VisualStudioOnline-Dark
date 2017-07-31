Imports Snowden.Common.Database.DataAccessBaseObjects

Namespace Stockpiles
    Public Class StockpileManualAdjustmentList
        Inherits Core.Website.Stockpiles.StockpileManualAdjustmentList

        Protected Overrides Sub RetrieveRequestData()

            MyBase.RetrieveRequestData()

            If (Not Request("Stockpile") Is Nothing) AndAlso (Request("Stockpile").Trim <> "") Then
                Stockpile = Convert.ToInt32(Request("Stockpile").Trim)
            End If
        End Sub

        Protected Overrides Sub SetupPageLayout()
            Dim useColumns As String()
            Dim index As Int32

            MyBase.SetupPageLayout()

            'remove the columns & databind
            useColumns = Nothing
            For index = 0 To AdjustmentTable.UseColumns.Length - 1
                If AdjustmentTable.UseColumns(index) <> "Delete" Then
                    If useColumns Is Nothing Then
                        ReDim Preserve useColumns(0)
                    Else
                        ReDim Preserve useColumns(useColumns.Length)
                    End If

                    useColumns(useColumns.Length - 1) = AdjustmentTable.UseColumns(index)
                End If
            Next

            AdjustmentTable.UseColumns = useColumns
            AdjustmentTable.DataBind()
        End Sub

        Protected Overrides Sub SaveFilterOptions()
            MyBase.SaveFilterOptions()
            Resources.UserSecurity.SetSetting("Stockpile_Manual_Adjustment_Filter_Stockpile", Stockpile.ToString())
        End Sub

    End Class
End Namespace