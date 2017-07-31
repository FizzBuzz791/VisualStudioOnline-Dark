Imports System.Web.UI.WebControls
Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment.ReconcilorControls

Namespace ReconcilorControls.Inputs
    Public Class MonthFilter
        Inherits Common.Web.BaseHtmlControls.GenericControlBase

#Region " Properties "
        Private Const _monthDropDownBaseId As String = "MonthPickerMonthPart"
        Private Const _yearDrowDownBaseId As String = "MonthPickerYearPart"

        Private _disposed As Boolean
        Private _monthBox As New InputTags.SelectBox
        Private _yearBox As New InputTags.SelectBox

        Private _startYear As Integer = 2009
        Private _onSelectChangeCallback As String

        Private _monthValue As New InputTags.InputHidden
        Private _onSelectChange As String
        Private _layoutTable As New Tags.HtmlTableTag
        Private _index As String = ""
        Private _selectedDate As DateTime? = Nothing

        Protected ReadOnly Property YearDropDownBaseId() As String
            Get
                Return _yearDrowDownBaseId
            End Get
        End Property

        Protected ReadOnly Property MonthBox() As InputTags.SelectBox
            Get
                Return _monthBox
            End Get
        End Property

        Protected ReadOnly Property YearBox() As InputTags.SelectBox
            Get
                Return _yearBox
            End Get
        End Property

        Public Property StartYear() As Integer
            Get
                Return _startYear
            End Get
            Set(ByVal value As Integer)
                _startYear = value
            End Set
        End Property

        Public Property OnSelectChangeCallback() As String
            Get
                Return _onSelectChangeCallback
            End Get
            Set(ByVal value As String)
                _onSelectChangeCallback = value
            End Set
        End Property

        Public Property Index() As String
            Get
                Return _index
            End Get
            Set(ByVal value As String)
                _index = value
            End Set
        End Property

        Public Property SelectedDate() As DateTime?
            Get
                Return _selectedDate
            End Get
            Set(ByVal value As DateTime?)
                _selectedDate = value
            End Set
        End Property

        Public ReadOnly Property MonthValue() As InputTags.InputHidden
            Get
                Return _monthValue
            End Get
        End Property

        Public ReadOnly Property LayoutTable() As Tags.HtmlTableTag
            Get
                Return _layoutTable
            End Get
        End Property
#End Region

#Region " Destructors "
        'Seal Dispose()
        Public NotOverridable Overrides Sub Dispose()
            Dispose(True)
            GC.SuppressFinalize(Me)
        End Sub

        Protected Overridable Overloads Sub Dispose(ByVal disposing As Boolean)
            Try
                If (Not _disposed) Then
                    If (disposing) Then
                        'Clean up managed Resources ie: Objects

                    End If

                    'Clean up unmanaged resources ie: Pointers & Handles				
                End If

                _disposed = True
            Finally
                MyBase.Dispose()
            End Try
        End Sub
#End Region

        ''' <summary>
        ''' This is formatted for JavaScript element extraction.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Overridable Function GetStartDateElements() As String
            Return String.Format("{0}{1},{2}{3}", _monthDropDownBaseId, Index, _yearDrowDownBaseId, Index)
        End Function

        Protected Overrides Sub OnInit(ByVal e As EventArgs)
            SetupLayout()

            MyBase.OnInit(e)

            SetupControls()

            CompleteLayout()
        End Sub


        Protected Overridable Sub SetupLayout()

            With LayoutTable
                .AddCellInNewRow.Controls.Add(MonthBox)
                .AddCell.Controls.Add(YearBox)
                .AddCell.Controls.Add(MonthValue)
            End With

            Controls.Add(LayoutTable)
        End Sub

        Protected Overridable Sub CompleteLayout()

            Controls.Add(New Tags.HtmlScriptTag(Tags.ScriptType.TextJavaScript, _onSelectChange))
        End Sub

        Protected Overridable Sub SetupControls()
            Dim monthPicker As Date
            Dim item As ListItem
            Dim year As Integer
            Dim currentMonth As Date
            Dim monthParsed As Boolean

            _onSelectChange = "document.getElementById('MonthValue" & Index & "').value = '1-' + " _
                & "document.getElementById('MonthPickerMonthPart" & Index & "').options[document.getElementById('MonthPickerMonthPart" & Index & "').selectedIndex].value" _
                & " + '-' + " _
                & "document.getElementById('MonthPickerYearPart" & Index & "').options[document.getElementById('MonthPickerYearPart" & Index & "').selectedIndex].value"

            If (Not String.IsNullOrEmpty(OnSelectChangeCallback)) Then
                _onSelectChange &= ";" & OnSelectChangeCallback
            End If

            '  monthPicker = DateAdd(DateInterval.Month, -1, DateTime.Now)
            monthPicker = DateTime.Now

            If SelectedDate.HasValue Then
                monthPicker = SelectedDate.Value
            End If

            Me.ID = "MonthFilterBox" & Index

            With _monthValue
                .ID = "MonthValue" & Index
            End With

            With MonthBox
                .ID = _monthDropDownBaseId & Index
                .OnSelectChange = _onSelectChange

                .Items.Add(New ListItem("January", "Jan"))
                .Items.Add(New ListItem("February", "Feb"))
                .Items.Add(New ListItem("March", "Mar"))
                .Items.Add(New ListItem("April", "Apr"))
                .Items.Add(New ListItem("May", "May"))
                .Items.Add(New ListItem("June", "Jun"))
                .Items.Add(New ListItem("July", "Jul"))
                .Items.Add(New ListItem("August", "Aug"))
                .Items.Add(New ListItem("September", "Sep"))
                .Items.Add(New ListItem("October", "Oct"))
                .Items.Add(New ListItem("November", "Nov"))
                .Items.Add(New ListItem("December", "Dec"))

                For Each item In .Items
                    monthParsed = Date.TryParse("1-" & item.Value & "-2000", currentMonth)

                    If monthParsed AndAlso currentMonth.Month = monthPicker.Month Then
                        item.Selected = True
                    End If
                Next

            End With

            With YearBox
                .ID = _yearDrowDownBaseId & Index
                .OnSelectChange = _onSelectChange
                For year = _startYear To Date.Now.Year + 1
                    .Items.Add(New ListItem(year.ToString, year.ToString))
                Next

                If Not SelectedDate Is Nothing AndAlso SelectedDate.HasValue Then
                    .SelectedValue = monthPicker.Year.ToString()
                End If
            End With
        End Sub

    End Class
End Namespace
