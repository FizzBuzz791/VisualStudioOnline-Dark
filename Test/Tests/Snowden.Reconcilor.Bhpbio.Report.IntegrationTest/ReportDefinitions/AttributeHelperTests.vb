Imports System.Collections.Generic
Imports System.Data
Imports System.Text
Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports Snowden.Reconcilor.Core

<TestClass()> Public Class AttributeHelperTests

    Dim gradeDictionary As Dictionary(Of String, Grade)

    Const CSV As String = "Fe,P,LOI"

    <TestInitialize>
    Public Sub InitalizeTests()
        ' Dummy up a result set
        gradeDictionary = AttributeHelperTestsHelper.BuildGradeDictionary()
    End Sub

    <TestMethod()> Public Sub TestSerialization()
        Dim xml = AttributeHelper.ConvertAttributeCsvToXml(CSV, gradeDictionary)

        Assert.AreEqual("<Attributes><Attribute id=""1"" name=""Fe""/><Attribute id=""2"" name=""P""/><Attribute id=""5"" name=""LOI""/></Attributes>", xml)
    End Sub

    <TestMethod()> Public Sub TestEmptyStringSerialization()
        Dim xml = AttributeHelper.ConvertAttributeCsvToXml("", gradeDictionary)

        Assert.AreEqual("<Attributes></Attributes>", xml)
    End Sub


End Class