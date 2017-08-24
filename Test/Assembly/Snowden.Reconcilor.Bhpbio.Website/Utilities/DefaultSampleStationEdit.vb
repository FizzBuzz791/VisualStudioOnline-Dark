Imports System.Data.SqlClient
Imports System.Web.UI
Imports System.Web.UI.HtmlControls
Imports System.Web.UI.WebControls
Imports Snowden.Common.Web.BaseHtmlControls.Tags
Imports Snowden.Common.Web.BaseHtmlControls.WebpageControls
Imports Snowden.Reconcilor.Bhpbio.Database.DalBaseObjects
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls.InputTags
Imports Snowden.Reconcilor.Core.WebDevelopment.WebpageTemplates

Namespace Utilities
    Public Class DefaultSampleStationEdit
        Inherits UtilitiesAjaxTemplate

        Protected Property IsNew As Boolean = True
        Protected Property SampleStationId As Integer?
        Protected Property DalUtility As IUtility

        Protected Overrides Sub RetrieveRequestData()
            MyBase.RetrieveRequestData()

            If Request("SampleStationId") IsNot Nothing Then
                SampleStationId = RequestAsInt32("SampleStationId")
                IsNew = False
            End If
        End Sub

        Protected Overrides Sub SetupDalObjects()
            MyBase.SetupDalObjects()

            If DalUtility Is Nothing Then
                DalUtility = New SqlDalUtility(Resources.Connection)
            End If
        End Sub

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()

            Try
                SetupFormControls()
            Catch ex As SqlException
                JavaScriptAlert($"Error while setting up Sample Station form: {ex.Message}")
            End Try
        End Sub

        Protected Overridable Sub SetupFormControls()
            Const LABEL_WIDTH = 80

            Dim targetSampleStation As DataTable = Nothing
            If Not IsNew AndAlso SampleStationId IsNot Nothing Then
                targetSampleStation = DalUtility.GetBhpbioSampleStation(CType(SampleStationId, Integer))
            End If

            Dim detailsLayoutTable = New HtmlTableTag
            With detailsLayoutTable
                Dim cell = .AddCellInNewRow()
                cell.Controls.Add(New LiteralControl("Name:"))
                cell = .AddCell()
                cell.Controls.Add(New LiteralControl("&nbsp;&nbsp;")) ' This cell is a spacer to help alignment
                cell = .AddCell()
                Dim nameBox = New InputText With {
                    .ID = "Name"
                }
                If Not IsNew Then
                    nameBox.Text = targetSampleStation.Rows(0)("Name").ToString()
                End If
                cell.Controls.Add(nameBox)
                cell = .AddCell
                cell.Controls.Add(New LiteralControl("&nbsp;")) ' This cell is a spacer to help alignment
                cell.Width = Unit.Percentage(50)

                cell = .AddCellInNewRow()
                cell.Controls.Add(New LiteralControl("Description:"))
                cell = .AddCell()
                cell.Controls.Add(New LiteralControl("&nbsp;&nbsp;")) ' This cell is a spacer to help alignment
                cell = .AddCell()
                Dim descriptionBox = New InputText With {
                    .ID = "Description",
                    .Width = Unit.Pixel(300)
                }
                If Not IsNew Then
                    descriptionBox.Text = targetSampleStation.Rows(0)("Description").ToString()
                End If
                cell.Controls.Add(descriptionBox)
                cell = .AddCell
                cell.Controls.Add(New LiteralControl("&nbsp;")) ' This cell is a spacer to help alignment
                cell.Width = Unit.Percentage(50)

                cell = .AddCellInNewRow()
                Dim locationPicker = New ReconcilorLocationSelector With {
                    .ID = "SampleStationLocationID",
                    .LocationLabelCellWidth = LABEL_WIDTH,
                    .LowestLocationTypeDescription = "Site",
                    .OnChange = "PopulateWeightometer" ' No need to add braces; LocationFilterLoad.vb does that.
                }
                If Not IsNew Then
                    locationPicker.LocationId = CType(targetSampleStation.Rows(0)("Location_Id"), Integer)
                End If
                cell.Controls.Add(locationPicker)

                cell = .AddCellInNewRow()
                cell.Controls.Add(New LiteralControl("Product Size:"))
                cell = .AddCell()
                cell.Controls.Add(New LiteralControl("&nbsp;")) ' This cell is a spacer to help alignment
                cell = .AddCell()
                Dim lumpRadio = New InputRadio() With {
                    .ID = "LumpOption",
                    .GroupName = "ProductSizeGroup",
                    .Text = "Lump",
                    .Value = "LUMP"
                }
                If Not IsNew Then
                    lumpRadio.Checked = targetSampleStation.Rows(0)("ProductSize").ToString().Equals("LUMP")
                End If
                cell.Controls.Add(lumpRadio)
                cell = .AddCell
                cell.Controls.Add(New LiteralControl("&nbsp;")) ' This cell is a spacer to help alignment
                cell.Width = Unit.Percentage(50)

                cell = .AddCellInNewRow()
                cell.Controls.Add(New LiteralControl("&nbsp;"))
                cell = .AddCell()
                cell.Controls.Add(New LiteralControl("&nbsp;")) ' This cell is a spacer to help alignment
                cell = .AddCell()
                Dim finesRadio = New InputRadio() With {
                    .ID = "FinesOption",
                    .GroupName = "ProductSizeGroup",
                    .Text = "Fines",
                    .Value = "FINES"
                }
                If Not IsNew Then
                    finesRadio.Checked = targetSampleStation.Rows(0)("ProductSize").ToString().Equals("FINES")
                End If
                cell.Controls.Add(finesRadio)
                cell = .AddCell
                cell.Controls.Add(New LiteralControl("&nbsp;")) ' This cell is a spacer to help alignment
                cell.Width = Unit.Percentage(50)

                cell = .AddCellInNewRow()
                cell.Controls.Add(New LiteralControl("&nbsp;"))
                cell = .AddCell()
                cell.Controls.Add(New LiteralControl("&nbsp;")) ' This cell is a spacer to help alignment
                cell = .AddCell()
                Dim romRadio = New InputRadio() With {
                    .ID = "RomOption",
                    .GroupName = "ProductSizeGroup",
                    .Text = "Unscreened",
                    .Value = "ROM"
                }
                If Not IsNew Then
                    romRadio.Checked = targetSampleStation.Rows(0)("ProductSize").ToString().Equals("ROM")
                End If
                cell.Controls.Add(romRadio)
                cell = .AddCell
                cell.Controls.Add(New LiteralControl("&nbsp;")) ' This cell is a spacer to help alignment
                cell.Width = Unit.Percentage(50)

                cell = .AddCellInNewRow()
                cell.Controls.Add(New LiteralControl("Weightometer:"))
                cell = .AddCell()
                cell.Controls.Add(New LiteralControl("&nbsp;")) ' This cell is a spacer to help alignment
                cell = .AddCell()
                Dim weightometer = New SelectBox() With {
                    .ID = "FilteredWeightometerList",
                    .DataTextField = "Weightometer_Id",
                    .DataValueField = "Weightometer_Id"
                }
                If Not IsNew Then
                    weightometer.SelectedValue = targetSampleStation.Rows(0)("Weightometer_Id").ToString()
                End If
                cell.Controls.Add(weightometer)
                cell = .AddCell
                cell.Controls.Add(New LiteralControl("&nbsp;")) ' This cell is a spacer to help alignment
                cell.Width = Unit.Percentage(50)

                cell = .AddCellInNewRow()
                Dim submitButton = New InputButton With {
                    .ID = "SampleStationSubmit",
                    .Text = String.Format(" Save ")
                }
                cell.Controls.Add(submitButton)
                cell.Controls.Add(New LiteralControl("&nbsp;&nbsp;"))
                Dim cancelButton = New InputButton With {
                    .ID = "CancelSubmit",
                    .Text = String.Format(" Cancel "),
                    .OnClientClick = "return CancelEditSampleStation();"
                }
                cell.Controls.Add(cancelButton)
            End With

            Dim sampleStationEditForm = New HtmlFormTag With {
                .ID = "SampleStationEditForm"
            }
            sampleStationEditForm.OnSubmit = $"return SubmitForm('{sampleStationEditForm.ID}', 'itemList', './DefaultSampleStationSave.aspx');"
            sampleStationEditForm.Controls.Add(detailsLayoutTable)
            Dim hiddenSampleStationId = New InputHidden With {
                    .ID = "SampleStationId"
                    }
            If Not IsNew Then
                hiddenSampleStationId.Value = targetSampleStation.Rows(0)("Id").ToString()
            End If
            Dim temp = New HtmlDivTag
            temp.Controls.Add(hiddenSampleStationId)
            sampleStationEditForm.Controls.Add(temp)

            Dim sampleStationDetails = New WebDevelopment.Controls.TabPage("details", "detailsScript", "Details")
            sampleStationDetails.Controls.Add(sampleStationEditForm)
            Dim weightometers = New ReconcilorTable(DalUtility.GetWeightometerListWithLocations())
            With weightometers
                .ID = "WeightometerList"
                .DataBind()
            End With

            Dim weightometerListDiv = New HtmlDivTag With {
                .StyleClass = "hidden"
            }
            weightometerListDiv.Controls.Add(weightometers)
            sampleStationDetails.Controls.Add(weightometerListDiv)

            Dim targetsLayoutTable = New HtmlTableTag With {
                .ID = "SampleStationTargetsLayout",
                .Width = Unit.Percentage(100),
                .CellPadding = 2,
                .CellSpacing = 2
            }

            With targetsLayoutTable
                Dim cell = .AddCellInNewRow()
                cell.Controls.Add(New LiteralControl("Active Dates:"))

                Dim dataTable = New DataTable()
                If Not IsNew Then
                    dataTable = DalUtility.GetBhpbioSampleStationTargetsForSampleStation(CType(SampleStationId, Integer))

                    With dataTable.Columns
                        .Add("Edit", GetType(String), "'<a href=""#"" onclick=""EditSampleStationTarget(''' + Id + ''')"">Edit</a>'")
                        .Add("Delete", GetType(String), "'<a href=""#"" onclick=""DeleteSampleStationTarget(''' + Id + ''')"">Delete</a>'")
                    End With
                Else
                    ' Require this for "Add New" or we just get an empty table with no columns
                    With dataTable.Columns
                        .Add("StartDate")
                        .Add("EndDate")
                        .Add("CoverageTarget")
                        .Add("CoverageWarning")
                        .Add("RatioTarget")
                        .Add("RatioWarning")
                        .Add("Edit")
                        .Add("Delete")
                    End With
                End If

                Dim dateFormat = "dd-MMM-yyyy"
                If Not Application("DateFormat") Is Nothing Then
                    dateFormat = Application("DateFormat").ToString
                End If
                Dim resultsTable = New ReconcilorTable(dataTable) With {
                    .ExcludeColumns = {"TempId", "Id", "SampleStation_Id"}
                }
                With resultsTable
                    .Columns.Add("StartDate", New ReconcilorTableColumn("Effective From"))
                    .Columns.Add("EndDate", New ReconcilorTableColumn("Effective To"))
                    .Columns.Add("CoverageTarget", New ReconcilorTableColumn("Coverage Target"))
                    .Columns.Add("CoverageWarning", New ReconcilorTableColumn("Coverage Warning"))
                    .Columns.Add("RatioTarget", New ReconcilorTableColumn("Tonnes/Sample Target"))
                    .Columns.Add("RatioWarning", New ReconcilorTableColumn("Tonnes/Sample Warning"))

                    .Columns("StartDate").DateTimeFormat = dateFormat
                    .Columns("EndDate").DateTimeFormat = dateFormat
                    .DataBind()
                End With
                resultsTable.Height = 100 ' Otherwise it's too big and the use doesn't notice the added controls after click "Add Target".
                cell = .AddCell()
                cell.Controls.Add(resultsTable)

                cell = .AddCellInNewRow()
                Dim addNewTargetButton = New HtmlInputButton() With { ' I have wasted far too much time wondering why "InputButton" doesn't work here. This does. Leave it.
                    .ID = "AddNewTargetSubmit",
                    .Value = String.Format(" Add New ")
                }
                addNewTargetButton.Attributes.Add("class", "inputButton")
                addNewTargetButton.Attributes.Add("onclick", $"return AddSampleStationTarget({SampleStationId});")
                cell.Controls.Add(addNewTargetButton)

                cell = .AddCellInNewRow()
                cell.Controls.Add(New HtmlDivTag("TargetContent"))
            End With

            Dim sampleStationTargets = New WebDevelopment.Controls.TabPage("targets", "targetsScript", "Targets")
            sampleStationTargets.Controls.Add(targetsLayoutTable)

            Dim tabPane = New TabPane("tabPaneSampleStationLocation", "tabPaneSampleStationScript")
            tabPane.TabPages.Add(sampleStationDetails)
            tabPane.TabPages.Add(sampleStationTargets)

            Dim layoutBox = New GroupBox With {
                .ID = "SampleStationDetailsForm",
                .Title = CType(IIf(IsNew, "Add Sample Station", "Edit Sample Station"), String),
                .Width = Unit.Percentage(100)
            }
            layoutBox.Controls.Add(tabPane)
            Controls.Add(layoutBox)
        End Sub
    End Class
End Namespace