Imports System.Data.SqlClient
Imports System.Web.UI
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

        Protected Property EditForm As HtmlFormTag = New HtmlFormTag

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
                Controls.Add(EditForm)
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

            Dim sampleStationDetails = New WebDevelopment.Controls.TabPage("details", "detailsScript", "Details")
            sampleStationDetails.Controls.Add(detailsLayoutTable)
            Dim weightometers = New ReconcilorTable(DalUtility.GetWeightometerListWithLocations())
            With weightometers
                .ID = "WeightometerList"
                .DataBind()
            End With

            Dim weightometerListDiv = New HtmlDivTag With {
                .StyleClass = "hidden"
            }
            weightometerListDiv.Controls.Add(weightometers)
            Dim hiddenSampleStationId = New InputHidden With {
                .ID = "SampleStationId"
            }
            If Not IsNew Then
                hiddenSampleStationId.Value = targetSampleStation.Rows(0)("Id").ToString()
            End If
            weightometerListDiv.Controls.Add(hiddenSampleStationId)
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
                cell = .AddCell()
                Dim dataTable = New DataTable
                With dataTable.Columns
                    .Add("Id", GetType(Integer))
                    .Add("Effective From", GetType(Date))
                    .Add("Effective To", GetType(Date))
                    .Add("Coverage Low (?)", GetType(Decimal))
                    .Add("Coverage High (?)", GetType(Decimal))
                    .Add("Ratio Low (?)", GetType(Integer))
                    .Add("Ratio High (?)", GetType(Integer))
                    .Add("Edit", GetType(String), "'<a href=""#"" onclick=""EditSampleStation(''' + Id + ''')"">Edit</a>'")
                    .Add("Delete", GetType(String), "'<a href=""#"" onclick=""DeleteSampleStation(''' + Id + ''')"">Delete</a>'")
                End With

                Dim resultsTable = New ReconcilorTable(dataTable) With {
                    .ExcludeColumns = {"Id"}
                }
                cell.Controls.Add(resultsTable)

                cell = .AddCellInNewRow()
                Dim addNewButton = New InputButton() With {
                    .ID = "AddNewTargetButton",
                    .Text = "Add New"
                }
                cell.Controls.Add(addNewButton)

                ' TODO: "New Target" Controls
            End With

            Dim sampleStationTargets = New WebDevelopment.Controls.TabPage("targets", "targetsScript", "Targets")
            sampleStationTargets.Controls.Add(targetsLayoutTable)

            Dim tabPane = New TabPane("tabPaneSampleStationLocation", "tabPaneSampleStationScript")
            tabPane.TabPages.Add(sampleStationDetails)
            tabPane.TabPages.Add(sampleStationTargets)

            Dim layoutBox = New GroupBox With {
                .Title = CType(IIf(IsNew, "Add Sample Station", "Edit Sample Station"), String),
                .Width = Unit.Percentage(100)
            }
            layoutBox.Controls.Add(tabPane)

            EditForm.ID = "SampleStationEditForm"
            EditForm.OnSubmit = $"return SubmitForm('{EditForm.ID}', 'itemList', './DefaultSampleStationSave.aspx');"
            EditForm.Controls.Add(layoutBox)
        End Sub
    End Class
End Namespace