Imports System.Data
Imports System.IO
Imports System.Text
Imports Microsoft.VisualStudio.TestTools.UnitTesting
Imports Newtonsoft.Json
Imports Snowden.Reconcilor.Bhpbio.Database.SqlDal.JSONConverters

<TestClass()>
Public Class BhpbioDataTableConverterTests

    Const COL1 = "Col1"
    Const COL2 = "Col2"
    Const COL3 = "Column 3"

    Dim _dt As DataTable
    Dim _emptyDt As DataTable
    Dim _ds As DataSet
    Dim _dataTableConverter As BhpbioDataTableConverter
    Dim _dataSetConverter As BhpbioDataSetConverter

    <TestInitialize()>
    Public Sub InitalizeTests()
        _dataTableConverter = New BhpbioDataTableConverter()
        _dataSetConverter = New BhpbioDataSetConverter()

        _dt = New DataTable("TestTableName")
        _dt.Columns.Add(New DataColumn(COL1, GetType(Integer)))
        _dt.Columns.Add(New DataColumn(COL2, GetType(String)))

        AddRow(_dt, 1, "Row1")
        AddRow(_dt, 2, "Row2")

        _emptyDt = New DataTable("EmptyDataTable")
        _emptyDt.Columns.Add(New DataColumn(COL1, GetType(Integer)))
        _emptyDt.Columns.Add(New DataColumn(COL2, GetType(String)))
        _emptyDt.Columns.Add(New DataColumn(COL3, GetType(Boolean)))

        _ds = New DataSet()

        _ds.Tables.Add(_dt)
        _ds.Tables.Add(_emptyDt)

    End Sub
    <TestMethod()>
    Public Sub DoesDataTableSerialize()
        Dim json As String = JsonConvert.SerializeObject(_dt, Formatting.Indented, _dataTableConverter)

        Dim dt As DataTable = JsonConvert.DeserializeObject(Of DataTable)(json, _dataTableConverter)

        Assert.AreEqual(_dt.Columns.Count, dt.Columns.Count)

        For i As Integer = 0 To _dt.Columns.Count - 1
            Assert.AreEqual(_dt.Columns(i).ColumnName, dt.Columns(i).ColumnName)
            Assert.AreEqual(_dt.Columns(i).GetType, dt.Columns(i).GetType)
        Next

        AssertRowEquals(dt.Rows(0), 1, "Row1")
        AssertRowEquals(dt.Rows(1), 2, "Row2")

    End Sub

    <TestMethod()>
    Public Sub DoesDataSetSerialize()
        Dim json As String = JsonConvert.SerializeObject(_ds, Formatting.Indented, _dataSetConverter, _dataTableConverter)

        Dim ds As DataSet = JsonConvert.DeserializeObject(Of DataSet)(json, _dataSetConverter, _dataTableConverter)


        Assert.AreEqual(ds.Tables.Count, 2)

        Dim dt As DataTable = ds.Tables(0)

        Assert.AreEqual(_dt.TableName, dt.TableName)

        Assert.AreEqual(_dt.Columns.Count, dt.Columns.Count)

        For i As Integer = 0 To _dt.Columns.Count - 1
            Assert.AreEqual(_dt.Columns(i).ColumnName, dt.Columns(i).ColumnName)
            Assert.AreEqual(_dt.Columns(i).GetType, dt.Columns(i).GetType)
        Next

        AssertRowEquals(dt.Rows(0), 1, "Row1")
        AssertRowEquals(dt.Rows(1), 2, "Row2")

        dt = ds.Tables(1)

        For i As Integer = 0 To _dt.Columns.Count - 1
            Assert.AreEqual(_dt.Columns(i).ColumnName, dt.Columns(i).ColumnName)
            Assert.AreEqual(_dt.Columns(i).GetType, dt.Columns(i).GetType)
        Next

        Assert.AreEqual(0, dt.Rows.Count)

    End Sub

    Private Sub AddRow(dt As DataTable, column1 As Integer, column2 As String)
        Dim dr As DataRow = dt.NewRow()
        dr(COL1) = column1
        dr(COL2) = column2
        dt.Rows.Add(dr)
    End Sub

    Private Sub AssertRowEquals(dr As DataRow, column1 As Integer, column2 As String)
        Assert.AreEqual(column1, dr(COL1))
        Assert.AreEqual(column2, dr(COL2))
    End Sub
End Class