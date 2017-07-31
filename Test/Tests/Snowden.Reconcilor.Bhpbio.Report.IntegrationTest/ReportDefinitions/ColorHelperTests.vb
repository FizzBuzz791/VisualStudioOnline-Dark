Imports System.Data
Imports System.Drawing
Imports System.Text
Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions

<TestClass()> Public Class ColorHelperTests

    Public Const BACKGROUND = "Background"
    Public Const VERIFICATION = "Verification"
    Public Const ALLOWABLE_DELTA = 0.0000001

    <TestMethod()>
    Public Sub Brightness_0_0_0()
        Dim result = ColorHelper.Brightness(0, 0, 0)

        Assert.AreEqual(1.0, result)
    End Sub

    <TestMethod()>
    Public Sub Brightness_255_255_255()
        Dim result = ColorHelper.Brightness(255, 255, 255)

        Assert.AreEqual(0.0, result, ALLOWABLE_DELTA)
    End Sub

    <TestMethod()>
    Public Sub Brightness_100_100_100()
        Dim result = ColorHelper.Brightness(100, 100, 100)

        Assert.AreEqual(0.607843137254902, result, ALLOWABLE_DELTA)
    End Sub

    <TestMethod()>
    Public Sub Brightness_100_150_200()
        Dim result = ColorHelper.Brightness(100, 150, 200)

        Assert.AreEqual(0.448039215686274, result, ALLOWABLE_DELTA)
    End Sub

    <TestMethod()>
    Public Sub Brightness_200_150_100()
        Dim result = ColorHelper.Brightness(200, 150, 100)

        Assert.AreEqual(0.375490196078431, result, ALLOWABLE_DELTA)
    End Sub

    <TestMethod()>
    <ExpectedException(GetType(ArgumentException),
    "Arguments must be between 0 and 255 inclusive.")>
    Public Sub Does_Brightness_Negative_Red_Throw_Exception()
        Dim result = ColorHelper.Brightness(-1, 100, 100)
    End Sub

    <TestMethod()>
    <ExpectedException(GetType(ArgumentException),
    "Arguments must be between 0 and 255 inclusive.")>
    Public Sub Does_Brightness_Negative_Green_Throw_Exception()
        Dim result = ColorHelper.Brightness(100, -1, 100)
    End Sub

    <TestMethod()>
    <ExpectedException(GetType(ArgumentException),
    "Arguments must be between 0 and 255 inclusive.")>
    Public Sub Does_Brightness_Negative_Blue_Throw_Exception()
        Dim result = ColorHelper.Brightness(100, 100, -1)
    End Sub

    <TestMethod()>
    <ExpectedException(GetType(ArgumentException),
    "Arguments must be between 0 and 255 inclusive.")>
    Public Sub Does_Brightness_Too_High_Red_Throw_Exception()
        Dim result = ColorHelper.Brightness(256, 100, 100)
    End Sub

    <TestMethod()>
    <ExpectedException(GetType(ArgumentException),
    "Arguments must be between 0 and 255 inclusive.")>
    Public Sub Does_Brightness_Too_High_Green_Throw_Exception()
        Dim result = ColorHelper.Brightness(100, 256, 100)
    End Sub

    <TestMethod()>
    <ExpectedException(GetType(ArgumentException),
    "Arguments must be between 0 and 255 inclusive.")>
    Public Sub Does_Brightness_Too_Highe_Blue_Throw_Exception()
        Dim result = ColorHelper.Brightness(100, 256, -1)
    End Sub

    <TestMethod()>
    Public Sub GetColourFromString_Red()
        Dim result = ColorHelper.GetColourFromString("Red")

        AssertRGB(result, 255, 0, 0)
    End Sub

    <TestMethod()>
    Public Sub GetColourFromString_HashRed()
        Dim result = ColorHelper.GetColourFromString("#FF0000")

        AssertRGB(result, 255, 0, 0)
    End Sub

    <TestMethod()>
    Public Sub GetColourFromString_MediumSeaGreen()
        Dim result = ColorHelper.GetColourFromString("MediumSeaGreen")

        AssertRGB(result, 60, 179, 113)
    End Sub

    <TestMethod()>
    Public Sub GetColourFromString_Moccasin()
        Dim result = ColorHelper.GetColourFromString("Moccasin")

        AssertRGB(result, 255, 228, 181)
    End Sub

    <TestMethod()>
    Public Sub GetColourFromString_hashFD09FD()
        Dim result = ColorHelper.GetColourFromString("#FD09FD")

        AssertRGB(result, 253, 9, 253)
    End Sub

    <TestMethod()>
    Public Sub GetColourFromString_Goldenrod()
        Dim result = ColorHelper.GetColourFromString("Goldenrod")

        AssertRGB(result, 218, 165, 32)
    End Sub

    <TestMethod()>
    Public Sub Does_GetContrastingLabel_Black_Return_White()
        Dim result = ColorHelper.GetContrastingLabel("Black")

        Assert.AreEqual("White", result)
    End Sub

    <TestMethod()>
    Public Sub Does_GetContrastingLabel_InvalidValue_Return_Black()
        Dim result = ColorHelper.GetContrastingLabel("NONE")

        Assert.AreEqual("Black", result)
    End Sub

    <TestMethod()>
    Public Sub Does_GetContrastingLabel_Black_Return_Black()
        Dim result = ColorHelper.GetContrastingLabel(255, 255, 255)

        Assert.AreEqual("Black", result)
    End Sub

    <TestMethod()>
    Public Sub Does_GetContrastingLabel_Red_Return_White()
        Dim result = ColorHelper.GetContrastingLabel(255, 0, 0)

        Assert.AreEqual("White", result)
    End Sub

    <TestMethod()>
    Public Sub Does_GetContrastingLabel_HashRed_Return_White()
        Dim result = ColorHelper.GetContrastingLabel("#FF0000")

        Assert.AreEqual("White", result)
    End Sub

    <TestMethod()>
    Public Sub Does_GetContrastingLabel_RedString_Return_White()
        Dim result = ColorHelper.GetContrastingLabel("Red")

        Assert.AreEqual("White", result)
    End Sub

    <TestMethod()>
    Public Sub Does_GetContrastingLabel_Green_Return_White()
        Dim result = ColorHelper.GetContrastingLabel("Green")

        Assert.AreEqual("White", result)
    End Sub

    <TestMethod()>
    Public Sub Does_GetContrastingLabel_Blue_Return_White()
        Dim result = ColorHelper.GetContrastingLabel(0, 0, 255)

        Assert.AreEqual("White", result)
    End Sub

    <TestMethod()>
    Public Sub Does_GetContrastingLabel_Moccasin_Return_Black()
        Dim result = ColorHelper.GetContrastingLabel("Moccasin")

        Assert.AreEqual("Black", result)
    End Sub

    <TestMethod()>
    Public Sub Does_AddLabelColor_Adds_Column()
        Dim dt As DataTable

        dt = New DataTable
        dt.Columns.Add(BACKGROUND)

        dt.AddLabelColor(BACKGROUND)

        Assert.IsTrue(dt.Columns.Contains(ColorHelper.LABEL_TEXT_COLUMN))
    End Sub

    <TestMethod()>
    Public Sub Does_AddLabelColor_Fills_LabelColors()
        Dim dt As DataTable

        dt = New DataTable
        dt.Columns.Add(BACKGROUND)
        dt.Columns.Add(VERIFICATION)

        AddColor(dt, "#99CC00", "Black")
        AddColor(dt, "#FD09FD", "White")
        AddColor(dt, "#FF0000", "White")
        AddColor(dt, "#FF9A00", "Black")
        AddColor(dt, "Aquamarine", "Black")
        AddColor(dt, "Beige", "Black")
        AddColor(dt, "Bisque", "Black")
        AddColor(dt, "Black", "White")
        AddColor(dt, "Blue", "White")
        AddColor(dt, "BlueViolet", "White")
        AddColor(dt, "Brown", "White")
        AddColor(dt, "BurlyWood", "Black")
        AddColor(dt, "CadetBlue", "Black")
        AddColor(dt, "Chartreuse", "Black")
        AddColor(dt, "Chocolate", "Black")
        AddColor(dt, "Coral", "Black")
        AddColor(dt, "CornflowerBlue", "Black")
        AddColor(dt, "Cyan", "Black")
        AddColor(dt, "DarkCyan", "White")
        AddColor(dt, "DarkGoldenrod", "Black")
        AddColor(dt, "DarkGreen", "White")
        AddColor(dt, "DarkKhaki", "Black")
        AddColor(dt, "DarkOliveGreen", "White")
        AddColor(dt, "DarkOrange", "Black")
        AddColor(dt, "DarkOrchid", "White")
        AddColor(dt, "DarkRed", "White")
        AddColor(dt, "DarkSalmon", "Black")
        AddColor(dt, "DarkViolet", "White")
        AddColor(dt, "DeepPink", "White")
        AddColor(dt, "DeepSkyBlue", "Black")
        AddColor(dt, "DodgerBlue", "White")
        AddColor(dt, "ForestGreen", "White")
        AddColor(dt, "Gold", "Black")
        AddColor(dt, "Goldenrod", "Black")
        AddColor(dt, "Green", "White")
        AddColor(dt, "GreenYellow", "Black")
        AddColor(dt, "Honeydew", "Black")
        AddColor(dt, "HotPink", "Black")
        AddColor(dt, "IndianRed", "White")
        AddColor(dt, "Khaki", "Black")
        AddColor(dt, "LawnGreen", "Black")
        AddColor(dt, "LightBlue", "Black")
        AddColor(dt, "LightCoral", "Black")
        AddColor(dt, "LightCyan", "Black")
        AddColor(dt, "LightGreen", "Black")
        AddColor(dt, "LightSalmon", "Black")
        AddColor(dt, "LimeGreen", "Black")
        AddColor(dt, "Magenta", "White")
        AddColor(dt, "MediumOrchid", "Black")
        AddColor(dt, "MediumPurple", "Black")
        AddColor(dt, "MediumSeaGreen", "Black")
        AddColor(dt, "MediumTurquoise", "Black")
        AddColor(dt, "Moccasin", "Black")
        AddColor(dt, "Navy", "White")
        AddColor(dt, "OliveDrab", "White")
        AddColor(dt, "Orange", "Black")
        AddColor(dt, "OrangeRed", "White")
        AddColor(dt, "Orchid", "Black")
        AddColor(dt, "PaleVioletRed", "Black")
        AddColor(dt, "PeachPuff", "Black")
        AddColor(dt, "Pink", "Black")
        AddColor(dt, "Plum", "Black")
        AddColor(dt, "PowderBlue", "Black")
        AddColor(dt, "Purple", "White")
        AddColor(dt, "Red", "White")
        AddColor(dt, "RosyBrown", "Black")
        AddColor(dt, "RoyalBlue", "White")
        AddColor(dt, "Salmon", "Black")
        AddColor(dt, "SandyBrown", "Black")
        AddColor(dt, "SeaGreen", "White")
        AddColor(dt, "SkyBlue", "Black")
        AddColor(dt, "Tan", "Black")
        AddColor(dt, "Teal", "White")
        AddColor(dt, "Turquoise", "Black")
        AddColor(dt, "Yellow", "Black")
        AddColor(dt, "YellowGreen", "Black")

        dt.AddLabelColor(BACKGROUND)

        For Each dr As DataRow In dt.Rows
            VerifyLabel(dr)
        Next

        Assert.IsTrue(dt.Columns.Contains(ColorHelper.LABEL_TEXT_COLUMN))
    End Sub


    Private Sub AssertRGB(ByVal color As Color, ByVal red As Byte, ByVal green As Byte, ByVal blue As Byte)
        Assert.AreEqual(red, color.R)
        Assert.AreEqual(green, color.G)
        Assert.AreEqual(blue, color.B)
    End Sub

    Private Sub AddColor(ByVal dataTable As DataTable, ByVal color As String, ByVal verificationColor As String)
        Dim newRow = dataTable.NewRow
        newRow(BACKGROUND) = color
        newRow(VERIFICATION) = verificationColor
        dataTable.Rows.Add(newRow)
    End Sub

    Private Sub VerifyLabel(ByVal dataRow As DataRow)
        Assert.AreEqual(dataRow(VERIFICATION), dataRow(ColorHelper.LABEL_TEXT_COLUMN), dataRow(BACKGROUND))
    End Sub

End Class