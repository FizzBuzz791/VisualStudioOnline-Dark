Imports System.Web.UI.WebControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace ReconcilorControls.Inputs

    ' This overrides the 
    '
    Public Class MonthQuarterFilter
        Inherits MonthFilter

#Region " Properties "
        Private Const _quarterDropDownBaseId As String = "QuarterPickerPart"

        Private _dateBreakdown As String = "MONTH"
        Private _quarterBox As New InputTags.SelectBox

        Protected ReadOnly Property QuarterBox() As InputTags.SelectBox
            Get
                Return _quarterBox
            End Get
        End Property

        Public Property DateBreakdown() As String
            Get
                Return _dateBreakdown
            End Get
            Set(ByVal value As String)
                _dateBreakdown = value
            End Set
        End Property

#End Region

        ''' <summary>
        ''' This is formatted for JavaScript element extraction.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Overridable Function GetStartQuarterElements() As String
            Return String.Format("{0}{1},{2}{3}", _quarterDropDownBaseId, Index, MyBase.YearDropDownBaseId, Index)
        End Function

        ' --
        ' Init Order:
        '  SetupLayout()
        '  MyBase.OnInit(e)
        '  SetupControls()
        '  CompleteLayout()
        ' --

        Protected Overrides Sub SetupLayout()

            Dim monthCell = LayoutTable.AddCellInNewRow
            Dim quarterCell = LayoutTable.AddCell

            If DateBreakdown = "MONTH" Then
                quarterCell.Style.Add("display", "none")
            ElseIf DateBreakdown = "QUARTER" Then
                monthCell.Style.Add("display", "none")
            End If

            monthCell.Controls.Add(MonthBox)
            quarterCell.Controls.Add(QuarterBox)
            LayoutTable.AddCell.Controls.Add(YearBox)
            LayoutTable.AddCell.Controls.Add(MonthValue)

            Controls.Add(LayoutTable)
        End Sub

        Protected Overrides Sub CompleteLayout()
            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, String.Format("DateHelpers.onDateChange('{0}')", Index)))
        End Sub

        Protected Overrides Sub SetupControls()
            MyBase.SetupControls()

            Dim onSelectChangeEvents As String = String.Format("DateHelpers.onDateChange('{0}')", Index)

            If (Not String.IsNullOrEmpty(MyBase.OnSelectChangeCallback)) Then
                onSelectChangeEvents &= ";" & MyBase.OnSelectChangeCallback
            End If

            With QuarterBox
                .ID = _quarterDropDownBaseId & Index
                .OnSelectChange = onSelectChangeEvents

                .Items.Add(New ListItem("Quarter 1", "Q1"))
                .Items.Add(New ListItem("Quarter 2", "Q2"))
                .Items.Add(New ListItem("Quarter 3", "Q3"))
                .Items.Add(New ListItem("Quarter 4", "Q4"))

            End With

            If SelectedDate.HasValue Then
                QuarterBox.SelectedValue = DateToQuarter(SelectedDate.Value)

                If DateBreakdown = "QUARTER" Then
                    ' soemtimes we need to change the the year so it is the correct value
                    YearBox.SelectedValue = DateToQuarterYear(SelectedDate.Value).ToString
                End If
            End If

            YearBox.OnSelectChange = String.Format("DateHelpers.onDateChange('{0}')", Index)

        End Sub

        Protected Function DateToQuarter(ByVal dateValue As DateTime) As String

            Select Case dateValue.Month
                Case 1, 2, 3 : Return "Q3"
                Case 4, 5, 6 : Return "Q4"
                Case 7, 8, 9 : Return "Q1"
                Case 10, 11, 12 : Return "Q2"
                Case Else : Return "Q1"
            End Select

        End Function

        ' the year of the calendar date is not always the year of the FY date, so we need to convert
        ' between the two so we can set the select box properly from the saved values
        Protected Function DateToQuarterYear(ByVal dateValue As DateTime) As Integer
            Dim quarter = DateToQuarter(dateValue)

            If quarter = "Q1" Or quarter = "Q2" Then
                Return dateValue.Year + 1
            Else
                Return dateValue.Year
            End If

        End Function

    End Class
End Namespace
