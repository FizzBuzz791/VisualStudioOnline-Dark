Imports Snowden.Common.Database.DataAccessBaseObjects
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports System.Web.UI.WebControls
Imports System.Web.UI

Namespace Utilities
    Public Class WeightometerSampleEdit
        Inherits Core.Website.Utilities.WeightometerSampleEdit

#Region "Properties"

        Private _SampleDateReadOnly As New ReconcilorControls.InputTags.InputText
        Private _AllowEdit As New Boolean

        Public Property SampleDateReadOnly() As ReconcilorControls.InputTags.InputText
            Get
                Return _SampleDateReadOnly
            End Get
            Set(ByVal value As ReconcilorControls.InputTags.InputText)
                If (Not value Is Nothing) Then
                    _SampleDateReadOnly = value
                End If
            End Set
        End Property

        Public Property AllowEdit() As Boolean
            Get
                Return _AllowEdit
            End Get
            Set(ByVal value As Boolean)
                _AllowEdit = value
            End Set
        End Property

#End Region

        Protected Overrides Sub SetupPageLayout()

            HasCalendarControl = True 'Needs to be before the base call
            MyBase.SetupPageLayout()

            Dim headerDiv As New Tags.HtmlDivTag()

            With headerDiv
                .StyleClass = "largeHeaderText"
                .Style.Add("margin-bottom", "5px")

                If (Not Request("WeightometerSampleID") Is Nothing) Then
                    .Controls.Add(New LiteralControl("View Weightometer Sample"))
                Else
                    .Controls.Add(New LiteralControl("Add Weightometer Sample"))
                End If
            End With

            With ReconcilorContent.ContainerContent
                .Controls.Clear()
                .Controls.Add(headerDiv)
                .Controls.Add(SampleForm)
            End With

            If CType(Request("AllowEdit"), Boolean) = True Then
                AllowEdit = True
            Else
                AllowEdit = False
            End If

        End Sub

        Protected Overrides Sub SetupPageControls()

            MyBase.SetupPageControls()

            'Setup readonly date text box 

            SampleDateReadOnly.Enabled = AllowEdit
            SampleDateReadOnly.Text = SampleDate.DateSet.ToString(Application("DateFormat").ToString())
            SampleDateReadOnly.Width = 75

            'Toggle controls as enabled depending on view or edit status

            Weightometer.Enabled = AllowEdit
            SampleShift.Enabled = AllowEdit
            OrderNo.Enabled = AllowEdit
            Tonnes.Enabled = AllowEdit
            CorrectedTonnes.Enabled = AllowEdit
            LatestOrderNo.Enabled = AllowEdit
            SourceUseDefault.Enabled = AllowEdit
            SourceUseStockpile.Enabled = AllowEdit
            SourceStockpile.Enabled = AllowEdit
            DestinationUseDefault.Enabled = AllowEdit
            DestinationUseStockpile.Enabled = AllowEdit
            DestinationStockpile.Enabled = AllowEdit
            SourceGroupBox.Enabled = AllowEdit
            DestinationGroupBox.Enabled = AllowEdit
            SaveButton.Visible = AllowEdit
            SampleDateReadOnly.Enabled = AllowEdit

            SideNavigation.RemoveItem("UTILITIES_WEIGHTOMETER_SAMPLE_ADD")
            ReconcilorContent.SideNavigation = SideNavigation
        End Sub

        Protected Overrides Sub SetupDataTab()
            Dim Cell As TableCell
            Dim Row As TableRow

            Dim i As Integer

            DataLayoutTable.Width = 440

            For i = 1 To 8
                Row = New TableRow

                Select Case i
                    Case 1
                        Cell = New TableCell
                        Cell.Controls.Add(New ReconcilorControls.RequiredFieldLabel("Sample Date: "))
                        Row.Cells.Add(Cell)

                        Cell = New TableCell
                        Cell.ID = "SampleDateCell"

                        If AllowEdit Then
                            Cell.Controls.Add(SampleDate.ControlScript)
                        Else
                            Cell.Controls.Add(SampleDateReadOnly)
                        End If

                        Row.Cells.Add(Cell)
                    Case 2
                        Cell = New TableCell
                        Cell.Controls.Add(New LiteralControl("Sample Shift: "))
                        Row.Cells.Add(Cell)

                        Cell = New TableCell
                        Cell.Controls.Add(SampleShift)
                        Row.Cells.Add(Cell)
                    Case 3
                        Cell = New TableCell
                        Cell.Controls.Add(New LiteralControl("Order Number: "))
                        Row.Cells.Add(Cell)

                        Cell = New TableCell
                        Cell.Controls.Add(OrderNo)
                        Cell.Controls.Add(LatestOrderNo)
                        Row.Cells.Add(Cell)
                    Case 4
                        Cell = New TableCell
                        Cell.Controls.Add(New ReconcilorControls.RequiredFieldLabel("Weightometer: "))
                        Row.Cells.Add(Cell)

                        Cell = New TableCell
                        Cell.Attributes("colspan") = "2"
                        Cell.Controls.Add(Weightometer)
                        Row.Cells.Add(Cell)
                    Case 5
                        Cell = New TableCell
                        Cell.Controls.Add(New ReconcilorControls.RequiredFieldLabel("Tonnes: "))
                        Row.Cells.Add(Cell)

                        Cell = New TableCell
                        Cell.Controls.Add(Tonnes)
                        Row.Cells.Add(Cell)
                    Case 6
                        Cell = New TableCell
                        Cell.Controls.Add(New LiteralControl("Corrected Tonnes: "))
                        Row.Cells.Add(Cell)

                        Cell = New TableCell
                        Cell.Controls.Add(CorrectedTonnes)
                        Row.Cells.Add(Cell)
                    Case 7
                        Cell = New TableCell
                        Cell.Controls.Add(SourceGroupBox)
                        Row.Cells.Add(Cell)
                    Case 8
                        Cell = New TableCell
                        Cell.Controls.Add(DestinationGroupBox)
                        Row.Cells.Add(Cell)
                End Select

                DataLayoutTable.Rows.Add(Row)
            Next

            DataTab.Controls.Add(DataLayoutTable)
        End Sub

        Protected Overrides Sub SetupGradesTab()
            Dim GradeRow As DataRow
            Dim Cell As TableCell
            Dim Row As TableRow
            Dim GradeInput As ReconcilorControls.InputTags.InputText

            Dim i As Integer = 0

            GradesLayoutTable.Width = 440
            Row = Nothing

            For Each GradeRow In GradeData.Rows
                i = i + 1

                If i Mod 2 <> 0 Then
                    Row = New TableRow
                Else
                    Cell = New TableCell
                    Cell.Width = 10
                    Row.Cells.Add(Cell)
                End If

                Cell = New TableCell
                Cell.Controls.Add(New LiteralControl(GradeRow("Grade_Name").ToString & ": "))
                Row.Cells.Add(Cell)

                Cell = New TableCell
                GradeInput = New ReconcilorControls.InputTags.InputText()
                GradeInput.ID = "Grade_" & GradeRow("Grade_ID").ToString
                GradeInput.Width = 75
                GradeInput.Enabled = AllowEdit

                GradeControls.Add(GradeRow("Grade_ID").ToString, GradeInput)

                Cell.Controls.Add(GradeInput)
                Row.Cells.Add(Cell)

                If i Mod 2 = 0 Then
                    GradesLayoutTable.Rows.Add(Row)
                End If
            Next

            'Last row wasnt added
            If i Mod 2 <> 0 Then
                GradesLayoutTable.Rows.Add(Row)
            End If

            GradesGroupBox.Controls.Add(GradesLayoutTable)
            GradesGroupBox.Title = ReconcilorFunctions.GetSiteTerminology("Grade")
            GradesTab.Controls.Add(GradesGroupBox)
        End Sub

    End Class
End Namespace
