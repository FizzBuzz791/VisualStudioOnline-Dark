Imports System.Runtime.CompilerServices
Imports System.Drawing

Namespace ReportDefinitions
    Public Module ColorHelper

        Public Const LOCATION_COLOR_COLUMN = "LocationColor"
        Public Const LABEL_TEXT_COLUMN = "LabelTextColor"
        Public Const BLACK = "Black"
        Public Const WHITE = "White"

        Public Function Brightness(ByVal red As Integer, ByVal green As Integer, ByVal blue As Integer) As Double
            If (red < 0 Or red > 255 Or green < 0 Or green > 255 Or blue < 0 Or blue > 255) Then
                Throw New ArgumentException("Arguments must be between 0 and 255 inclusive.")
            End If
            Dim retVal = 1 - ((red * 0.299 + green * 0.587 + blue * 0.114) / 255)
            Return retVal
        End Function

        Public Function GetColourFromString(ByVal colourString As String) As Color

            Dim returnColor As Color
            Try
                Returncolor = ColorTranslator.FromHtml(colourString)
            Catch ex As Exception
                returnColor = Color.Transparent
            End Try

            GetColourFromString = returnColor
        End Function

        Public Function GetContrastingLabel(ByVal colorString As String) As String
            Dim color = ColorHelper.GetColourFromString(colorString)
            Return GetContrastingLabel(color.R, color.G, color.B)
        End Function

        Public Function GetContrastingLabel(ByVal color As Color) As String
            Return GetContrastingLabel(color.R, color.G, color.B)
        End Function

        Public Function GetContrastingLabel(ByVal red As Integer, ByVal green As Integer, ByVal blue As Integer) As String
            Dim brightness = ColorHelper.Brightness(red, green, blue)
            If (brightness < 0.5) Then
                GetContrastingLabel = BLACK
            Else
                GetContrastingLabel = WHITE
            End If
        End Function


        <Extension()>
        Public Sub AddLabelColor(ByVal table As DataTable)
            table.AddLabelColor(LOCATION_COLOR_COLUMN, LABEL_TEXT_COLUMN)
        End Sub
        <Extension()>
        Public Sub AddLabelColor(ByVal table As DataTable, ByVal BackgroundColorColumn As String)
            table.AddLabelColor(BackgroundColorColumn, LABEL_TEXT_COLUMN)
        End Sub

        <Extension()>
        Public Sub AddLabelColor(ByVal table As DataTable, ByVal backgroundColorColumn As String, ByVal labelColumn As String)
            If (Not table.Columns.Contains(labelColumn)) Then
                table.Columns.Add(labelColumn)
            End If

            For Each dataRow As DataRow In table.Rows
                Dim contrastingColor = ColorHelper.GetContrastingLabel(dataRow(backgroundColorColumn).ToString())
                dataRow(labelColumn) = contrastingColor
            Next

        End Sub
    End Module
End Namespace