Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Web.BaseHtmlControls
Imports System.Web.UI.WebControls
Imports System.Web.UI

Namespace Utilities
    Public Class HaulageAdministrationDetails
        Inherits Core.Website.Utilities.HaulageAdministrationDetails

#Region "Properties"

        Private _bestHauledTonnesTerm As String = Reconcilor.Core.WebDevelopment.ReconcilorFunctions.GetSiteTerminology("Tonnes")
        Private _originalHauledTonnesTerm As String = "Original Hauled Tonnes"

#End Region

        Protected Overrides Sub SetupPageLayout()
            MyBase.SetupPageLayout()

            ' Remove the Bulk Edit and New Record links on the side menu
            ReconcilorContent.SideNavigation.TryRemoveItem("UTILITIES_HAULAGE_BULK_EDIT")
            ReconcilorContent.SideNavigation.TryRemoveItem("UTILITIES_HAULAGE_NEW_RECORD")

            ' Remove the Haulage Menu side menu
            TasksSidebar.Visible = False
        End Sub

        Protected Overrides Sub SetupDetailsTabPage()
            Dim Layout As New Tags.HtmlTableTag
            Dim HaulageTable As DataTable = DalHaulage.GetHaulageManagementDetail(Convert.ToInt32(HaulageId.Value))
            Dim HaulageData As DataRow

            Layout.Width = 600
            If HaulageTable.Rows.Count = 1 Then
                HaulageData = HaulageTable.Rows.Item(0)
                Editable = Convert.ToBoolean(HaulageData("Is_Editable"))

                With Layout.Rows
                    With .Item(.Add(New TableRow)).Cells
                        With .Item(.Add(New TableCell))
                            .Controls.Add(New LiteralControl("<b>Haulage Date:</b>"))
                        End With

                        With .Item(.Add(New TableCell))
                            .Controls.Add(New LiteralControl(Convert.ToDateTime(HaulageData("Haulage_Date")).ToString(Application("DateFormat").ToString)))
                        End With

                        With .Item(.Add(New TableCell))
                            .Attributes("width") = "25%"
                            .Controls.Add(New LiteralControl("<b>ID:</b>"))
                        End With

                        With .Item(.Add(New TableCell))
                            .Attributes("width") = "25%"
                            .Controls.Add(New LiteralControl(HaulageData("Haulage_ID").ToString))
                        End With
                    End With

                    With .Item(.Add(New TableRow)).Cells
                        With .Item(.Add(New TableCell))
                            .Controls.Add(New LiteralControl("<b>Haulage Shift:</b>"))
                        End With

                        With .Item(.Add(New TableCell))
                            .Controls.Add(New LiteralControl(HaulageData("Haulage_Shift").ToString))
                        End With

                        With .Item(.Add(New TableCell))
                            .Controls.Add(New LiteralControl("<b>" + _bestHauledTonnesTerm + "</b>"))
                        End With

                        With .Item(.Add(New TableCell))

                            Try
                                .Controls.Add(New LiteralControl(Convert.ToDouble(HaulageData("Tonnes")).ToString(Application("NumericFormat").ToString)))
                            Catch ex As FormatException
                                .Controls.Add(New LiteralControl(HaulageData("Tonnes").ToString))
                            End Try
                        End With

                    End With

                    With .Item(.Add(New TableRow)).Cells
                        With .Item(.Add(New TableCell))
                            .Attributes("width") = "25%"
                            .Controls.Add(New LiteralControl("<b>Added Date & Time:</b>"))
                        End With

                        With .Item(.Add(New TableCell))
                            .Attributes("width") = "25%"
                            .Controls.Add(New LiteralControl(Convert.ToDateTime(HaulageData("Added_DateTime")).ToString(Application("DateFormat").ToString)))
                        End With

                        With .Item(.Add(New TableCell))
                            .Controls.Add(New LiteralControl("<b>Loads:</b>"))
                        End With

                        With .Item(.Add(New TableCell))
                            .Controls.Add(New LiteralControl(HaulageData("Loads").ToString))
                        End With
                    End With

                    With .Item(.Add(New TableRow)).Cells

                        With .Item(.Add(New TableCell))
                            .Controls.Add(New LiteralControl("<b>Source:</b>"))
                        End With

                        With .Item(.Add(New TableCell))
                            .Controls.Add(New LiteralControl(HaulageData("Source").ToString))
                        End With

                        With .Item(.Add(New TableCell))
                            .Controls.Add(New LiteralControl("<b>Truck ID:</b>"))
                        End With

                        With .Item(.Add(New TableCell))
                            .Controls.Add(New LiteralControl(HaulageData("Truck_ID").ToString))
                        End With
                    End With

                    With .Item(.Add(New TableRow)).Cells
                        With .Item(.Add(New TableCell))
                            .Controls.Add(New LiteralControl("<b>Destination:</b>"))
                        End With

                        With .Item(.Add(New TableCell))
                            .Controls.Add(New LiteralControl(HaulageData("Destination").ToString))
                        End With

                        With .Item(.Add(New TableCell))
                        End With

                        With .Item(.Add(New TableCell))
                        End With
                    End With
                End With
            End If

            With DataItems
                .Width = 600
                .IsCollapsable = False

                If HaulageTable.Rows.Count = 1 Then
                    .Controls.Add(Layout)
                Else
                    .Controls.Add(New LiteralControl("No haulage could be located with this ID."))
                    Editable = False
                End If
                .Visible = True
            End With

            With DataTab
                .Controls.Add(DataItems)
            End With

        End Sub


        Protected Overridable Function FormatHeaderText(ByVal headerText As String) As String

            Dim formattedText As String = headerText

            Select Case headerText
                Case "AerialSurveyTonnes"
                    formattedText = _bestHauledTonnesTerm
                Case "HauledTonnes"
                    formattedText = _originalHauledTonnesTerm
            End Select

            Return formattedText

        End Function

        Protected Overrides Sub SetupNormalizedDetails(ByVal TabType As String, _
   ByVal Items As ReconcilorControls.GroupBox, _
   ByVal Tab As WebpageControls.TabPage)
            Dim Layout As New Tags.HtmlTableTag
            Dim NormalizedTable As DataTable = DalHaulage.GetHaulageManagementDetailNormalized(TabType, Convert.ToInt32(HaulageId.Value), Convert.ToInt16(False))
            Dim i As Integer
            Dim Cells As TableCellCollection
            Dim gradeName As String
            Dim gradeValue As Single

            If NormalizedTable.Rows.Count > 0 Then
                Layout.Width = 580

                Cells = Layout.Rows.Item(Layout.Rows.Add(New TableRow)).Cells
                For i = 0 To NormalizedTable.Rows.Count - 1

                    With Cells.Item(Cells.Add(New TableCell))
                        .Attributes("width") = "25%"
                        .Controls.Add(New LiteralControl("<b>" & FormatHeaderText(NormalizedTable.Rows.Item(i).Item("Display_Name").ToString) & ":</b>"))
                    End With

                    With Cells.Item(Cells.Add(New TableCell))
                        .Attributes("width") = "25%"

                        If TabType = "Grade" Then
                            Try
                                gradeName = NormalizedTable.Rows.Item(i).Item("Item").ToString
                                gradeValue = Convert.ToSingle(NormalizedTable.Rows.Item(i).Item("Value"))

                                .Controls.Add(New LiteralControl(GradeFormat(gradeName).ToString(gradeValue)))
                            Catch ex As FormatException
                                .Controls.Add(New LiteralControl(NormalizedTable.Rows.Item(i).Item("Value").ToString))
                            End Try
                        Else
                            .Controls.Add(New LiteralControl(NormalizedTable.Rows.Item(i).Item("Value").ToString))
                        End If
                    End With

                    If (i + 1) Mod 2 = 0 Then
                        Cells = Layout.Rows.Item(Layout.Rows.Add(New TableRow)).Cells
                    End If
                Next

                With Items
                    .Width = 600
                    .IsCollapsable = False
                    .Controls.Add(Layout)
                    .Visible = True
                End With
                Tab.Controls.Add(Items)
                HaulageTabPane.TabPages.Add(Tab)
            End If

        End Sub

    End Class
End Namespace