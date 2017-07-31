Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Web.BaseHtmlControls

Namespace ReconcilorControls.FilterBoxes.Utilities
    Public Class HaulageAdministrationFilter
        Inherits Core.WebDevelopment.ReconcilorControls.FilterBoxes.Utilities.HaulageAdministrationFilter

        Protected Overrides Sub SetupFormAndDatePickers()
            If Not BulkEdit Then
                ServerForm.ID = "filterForm"
            Else
                ServerForm.ID = "bulkEditForm"
            End If

            DatePickers.Add("HaulageDateFrom", New WebpageControls.DatePicker("HaulageDateFrom", ServerForm.ID, Convert.ToDateTime(Resources.UserSecurity.GetSetting("Haulage_Administration_Filter_Date_From", DateAdd(DateInterval.Day, -7, Now).ToString))))
            DatePickers.Add("HaulageDateTo", New WebpageControls.DatePicker("HaulageDateTo", ServerForm.ID, Convert.ToDateTime(Resources.UserSecurity.GetSetting("Haulage_Administration_Filter_Date_To", Now.ToString))))

            ServerForm.OnSubmit = "return ValidateHaulageFilterParameters('" + LocationId.ToString() + "', '" + BulkEdit.ToString() + "');"
        End Sub

        Protected Overrides Sub SetupControls()
            MyBase.SetupControls()

            Dim UserSelectedSetting As Web.UI.WebControls.ListItem
            Dim ShiftList As DataTable = DalDigblock.GetShiftTypeList
            Dim LabelWidth As Int32 = 90

            ID = "HaulageAdministrationFilterBox"

            'Handling onchange of locations differently in BHP, button resides in core - dont want it.
            LocationFilterButton.Visible = False

            With LocationFilter

                'Call Javascript to populate source and destination when location changes
                .OnChange = "GetHaulageAdministrationSourceAndDestinationByLocation();"

                .LocationLabelCellWidth = LabelWidth
                If (LocationId <> DoNotSetValues.Int32) AndAlso (LocationId <> -1) Then
                    .LocationId = LocationId
                Else
                    LocationId = DoNotSetValues.Int32
                End If

            End With

            With FilterButton
                .ID = "HaulageFilterButton"
                .Text = " Filter List "
            End With

            With LayoutGroupBox
                .Title = "Filter Haulage"
            End With

            With Truck
                .ID = "Truck"

                .DataSource = DalHaulage.GetHaulageManagementListFilter("Truck", DoNotSetValues.Int32)
                .DataTextField = "Filter_Display"
                .DataValueField = "Filter_Value"
                .DataBind()

                .Items.Insert(0, New ListItem("All", ""))
                UserSelectedSetting = .Items.FindByValue(Resources.UserSecurity.GetSetting("Haulage_Administration_Filter_Truck", ""))
                If Not UserSelectedSetting Is Nothing Then
                    UserSelectedSetting.Selected = True
                End If
            End With

            With ShiftTo
                .ID = "ShiftTo"
                .DataSource = ShiftList
                .DataTextField = "Name"
                .DataValueField = "Shift"
                .DataBind()

                UserSelectedSetting = .Items.FindByValue(Resources.UserSecurity.GetSetting("Haulage_Administration_Filter_Shift_To", ""))
                If Not UserSelectedSetting Is Nothing Then
                    UserSelectedSetting.Selected = True
                End If
            End With

            With ShiftFrom
                .ID = "ShiftFrom"
                .DataSource = ShiftList
                .DataTextField = "Name"
                .DataValueField = "Shift"
                .DataBind()

                UserSelectedSetting = .Items.FindByValue(Resources.UserSecurity.GetSetting("Haulage_Administration_Filter_Shift_From", ""))
                If Not UserSelectedSetting Is Nothing Then
                    UserSelectedSetting.Selected = True
                End If
            End With

            With LimitRecords
                .ID = "LimitRecords"
                .Checked = True
            End With
        End Sub

        Protected Overrides Sub SetupLayout()
            ' MyBase.SetupLayout()

            Dim Cell As TableCell

            With LayoutTable
                .AddCellInNewRow.Controls.Add(LocationFilter)

                Cell = .AddCellInNewRow
                Cell.HorizontalAlign = HorizontalAlign.Left
                Cell.Controls.Add(LocationFilterButton)

                With .Rows(.Rows.Add(New WebControls.TableRow))
                    With .Cells(.Cells.Add(New TableCell))
                        .Controls.Add(New LiteralControl("Haulage From: "))
                    End With

                    With .Cells(.Cells.Add(New TableCell))
                        .ID = "DateFromControl"
                        .Controls.Add(DatePickers("HaulageDateFrom").ControlScript)
                    End With

                    With .Cells(.Cells.Add(New TableCell))
                        .Controls.Add(ShiftFrom)
                    End With

                    With .Cells(.Cells.Add(New TableCell))
                        .Controls.Add(New LiteralControl("Source: "))
                    End With

                    With .Cells(.Cells.Add(New TableCell))
                        Dim SourceDiv As New Tags.HtmlDivTag
                        SourceDiv.ID = "sourceDiv"
                        .Controls.Add(SourceDiv)
                    End With

                    With .Cells(.Cells.Add(New TableCell))
                        .Controls.Add(New LiteralControl("Truck: "))
                    End With

                    With .Cells(.Cells.Add(New TableCell))
                        .Controls.Add(Truck)
                    End With
                End With

                With .Rows(.Rows.Add(New WebControls.TableRow))
                    With .Cells(.Cells.Add(New TableCell))
                        .Controls.Add(New LiteralControl("Haulage To: "))
                    End With

                    With .Cells(.Cells.Add(New TableCell))
                        .ID = "DateToControl"
                        .Controls.Add(DatePickers("HaulageDateTo").ControlScript)
                    End With

                    With .Cells(.Cells.Add(New TableCell))
                        .Controls.Add(ShiftTo)
                    End With

                    With .Cells(.Cells.Add(New TableCell))
                        .Controls.Add(New LiteralControl("Destination: "))
                    End With

                    With .Cells(.Cells.Add(New TableCell))
                        Dim DestinationDiv As New Tags.HtmlDivTag
                        DestinationDiv.ID = "destinationDiv"
                        .Controls.Add(DestinationDiv)
                    End With

                    With .Cells(.Cells.Add(New TableCell))
                        .Controls.Add(New LiteralControl("Limit To " & RecordLimit & " Records: "))
                    End With

                    With .Cells(.Cells.Add(New TableCell))
                        .Controls.Add(LimitRecords)
                    End With
                End With
            End With
        End Sub

    End Class
End Namespace
