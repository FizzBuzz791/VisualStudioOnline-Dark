Imports Snowden.Reconcilor.Bhpbio.Report.Constants
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions

Namespace Types
    Public Class CalculationResultRow : Inherits CalculationResultRecord
        Public Sub New()
            MyBase.New()
        End Sub

        Public Property CalcId As String

        Public ReadOnly Property TagId As String
            Get
                If ProductSize IsNot Nothing And ProductSize.ToUpper <> CalculationConstants.PRODUCT_SIZE_TOTAL Then
                    Return ReportTagId + ProductSize
                Else
                    Return ReportTagId
                End If
            End Get
        End Property

        Public Property ReportTagId As String

        Public Property Description As String
    End Class

    <DebuggerDisplay("CalendarDate:{_calendarDate}, LocationId:{_locationId}, MaterialId:{_materialTypeId}, Product:{_productSize}, Tonnes:{_tonnes}")> _
    Public Class CalculationResultRecord
        ' it would be possible to get these grades from the database, but in order not to introduce a new
        ' dependency to this class, we just have them hardcoded here.
        '
        ' Note: after adding a new grade here you also have to add it to AggregateRecords in CalculateResult.vb
        ' since this aggregation is done by a linq statement, I couldn't work out a way to avoid hardcoding the
        ' grades
        '
        ' The standard grade names are the ones that would be shown on the approval page by default
        '
        Public Shared GradeNames As String() = New String() {"Density", "Fe", "P", "SiO2", "Al2O3", "LOI", "H2O", "H2O-As-Dropped", "H2O-As-Shipped", "Ultrafines"}
        Public Shared StandardGradeNames As String() = New String() {"Fe", "P", "SiO2", "Al2O3", "LOI", "H2O"}

        ' The set of grades that should be excluded from Reconciliation Export
        Public Shared GradeNamesNotApplicableForReconciliationExport As String() = New String() {"H2O-As-Dropped", "H2O-As-Shipped"}

        ' The set of GradeNames for grades for which a GradeTonnes representation does not make sense (for export and other display)
        Public Shared GradeNamesNotApplicableForGradeTonnesCalculation As String() = New String() {"Density"}

        Public Shared Function AttributeNames() As String()
            Dim attributes = New List(Of String)(GradeNames.ToList)
            attributes.Insert(0, "Tonnes")
            attributes.Insert(1, "Volume")
            Return attributes.ToArray
        End Function

#Region "Properties"

        'Dodgy aggregate fields for use
        ' See Calculation.vb Sub Calculate Answer for description of Dodgy Aggregate.

        Public Property Parent As CalculationResult

        Public Property CalendarDate As DateTime

        Public Property DateFrom As DateTime

        Public Property DateTo As DateTime

        Public Property LocationId As Int32?

        Public Property MaterialTypeId As Int32?

        Public Property ProductSize As String

        Public Property SortKey As String

        Public ReadOnly Property EffectiveProductSize As String
            Get
                Return IIf(ProductSize Is Nothing, CalculationConstants.PRODUCT_SIZE_TOTAL, ProductSize).ToString
            End Get
        End Property

        Public Property Tonnes As Double?

        Public Property Volume As Double? = Nothing

        Public Property ResourceClassification As String = Nothing

        Public Property DodgyAggregateGradeTonnes As Double?

        Public Property DodgyAggregateEnabled As Boolean?

        Public Property Fe As Double?

        Public Property P As Double?

        Public Property SiO2 As Double?

        Public Property Al2O3 As Double?

        Public Property Loi As Double?

        Public Property Density As Double?

        Public Property H2O As Double?

        Public Property H2ODropped As Double?

        Public Property H2OShipped As Double?

        Public Property UltraFines As Double?

        Public Property StratNum As String

        Public Property StratLevel As String

        Public Property Weathering As Integer?
#End Region

#Region "Constructors"

        Public Sub New()
            Parent = Nothing
        End Sub

        Public Sub New(parent As CalculationResult)
            Me.Parent = parent
        End Sub

        Public Sub New(parent As CalculationResult, dateFrom As DateTime, dateTo As DateTime)
            Me.New(parent)
            CalendarDate = dateFrom
            Me.DateFrom = dateFrom
            Me.DateTo = dateTo
            ProductSize = CalculationConstants.PRODUCT_SIZE_TOTAL
        End Sub

        Public Sub New(value As DataRow, grades As IEnumerable(Of DataRow))
            Merge(value, grades)
        End Sub

        Public Sub New(parent As CalculationResult, value As DataRow, grades As IEnumerable(Of DataRow))
            Me.New(parent)
            Merge(value, grades)
        End Sub

        ' GetGrade / SetGrade : Get and set the grade properties by string name. Use this in
        ' conjuntion with the GradeNames array to loop through all the grades and operate on 
        ' each one
        '
        ' we could do this by using reflection to get the grades by the property name
        ' but it would be less reliable, and much slower. The calculation methods in this
        ' class get called a lot, so speed is actually important here
        Public Function GetGrade(gradeName As String) As Double?
            Select Case gradeName.ToLower
                Case "fe" : Return Fe
                Case "p" : Return P
                Case "sio2" : Return SiO2
                Case "al2o3" : Return Al2O3
                Case "loi" : Return Loi
                Case "density" : Return Density
                Case "h2o" : Return H2O
                Case "h2o-as-dropped" : Return H2ODropped
                Case "h2o-as-shipped" : Return H2OShipped
                Case "ultrafines" : Return UltraFines
            End Select
        End Function

        Public Sub SetGrade(gradeName As String, value As Double?)
            Select Case gradeName.ToLower
                Case "fe" : Fe = value
                Case "p" : P = value
                Case "sio2" : SiO2 = value
                Case "al2o3" : Al2O3 = value
                Case "loi" : Loi = value
                Case "density" : Density = value
                Case "h2o" : H2O = value
                Case "h2o-as-dropped" : H2ODropped = value
                Case "h2o-as-shipped" : H2OShipped = value
                Case "ultrafines" : UltraFines = value
            End Select
        End Sub

        Public Sub Merge(value As DataRow, grades As IEnumerable(Of DataRow))
            'Dim dates As New Dictionary(Of DateTime, DataRow)
            Dim columns As DataColumnCollection
            Dim colsExists As Boolean
            Dim calDate As DateTime
            Dim parsedMaterialTypeId As Int32
            Dim parsedLocationId As Int32

            If Not value Is Nothing Then
                ' Gather up the listings from the data table.
                columns = value.Table.Columns

                colsExists = columns.Contains(ColumnNames.DATE_CAL) And
                    columns.Contains(ColumnNames.PARENT_LOCATION_ID) And
                    columns.Contains(ColumnNames.MATERIAL_TYPE_ID)

                If colsExists Then
                    If DateTime.TryParse(value(ColumnNames.DATE_CAL).ToString(), calDate) Then
                        CalendarDate = calDate
                        DateFrom = Convert.ToDateTime(value(ColumnNames.DATE_FROM).ToString())
                        DateTo = Convert.ToDateTime(value(ColumnNames.DATE_TO).ToString())

                        If Int32.TryParse(value(ColumnNames.PARENT_LOCATION_ID).ToString(), parsedLocationId) Then
                            LocationId = parsedLocationId
                        End If

                        If Int32.TryParse(value(ColumnNames.MATERIAL_TYPE_ID).ToString(), parsedMaterialTypeId) Then
                            MaterialTypeId = parsedMaterialTypeId
                        End If

                        If columns.Contains(ColumnNames.PRODUCT_SIZE) Then
                            ProductSize = value(ColumnNames.PRODUCT_SIZE).ToString()
                        End If

                        Tonnes = Convert.ToDouble(value("Tonnes").ToString)

                        If value.Table.Columns.Contains("Volume") AndAlso Not IsDBNull(value("Volume")) AndAlso Not value("Volume") Is Nothing Then
                            Volume = Convert.ToDouble(value("Volume").ToString)
                        Else
                            Volume = Nothing
                        End If

                        If value.HasColumn(ColumnNames.RESOURCE_CLASSIFICATION) AndAlso value.HasValue(ColumnNames.RESOURCE_CLASSIFICATION) Then
                            ResourceClassification = value.AsString(ColumnNames.RESOURCE_CLASSIFICATION)
                        End If

                        If value.HasColumn(ColumnNames.STRAT_NUM) AndAlso value.HasValue(ColumnNames.STRAT_NUM) Then
                            StratNum = value.AsString(ColumnNames.STRAT_NUM)
                        End If

                        If value.HasColumn(ColumnNames.STRAT_LEVEL) AndAlso value.HasValue(ColumnNames.STRAT_LEVEL) Then
                            StratLevel = value.AsString(ColumnNames.STRAT_LEVEL)
                        End If

                        If value.HasColumn(ColumnNames.WEATHERING) Then
                            Weathering = value.AsIntN(ColumnNames.WEATHERING)
                        End If

                        ' Set the intial value of the dodgy aggregate to the tonnes value
                        ' See Calculation.vb Sub Calculate Answer for description of Dodgy Aggregate.
                        DodgyAggregateGradeTonnes = Tonnes

                        ' Pivot the grade data
                        If Not grades Is Nothing Then

                            Dim gradeFiltered As IEnumerable(Of DataRow)
                            ' filter the records to only those appropriate for the value data row
                            gradeFiltered = grades.Where(Function(g) Convert.ToDateTime(g(ColumnNames.DATE_CAL).ToString()) = CalendarDate _
                                             And ParseNullableInt32(g(ColumnNames.PARENT_LOCATION_ID), LocationId) _
                                             And ParseNullableInt32(g(ColumnNames.MATERIAL_TYPE_ID), MaterialTypeId) _
                                             And SafeParseString(g, ColumnNames.PRODUCT_SIZE, CalculationConstants.PRODUCT_SIZE_TOTAL, EffectiveProductSize) _
                                             And SafeParseString(g, ColumnNames.RESOURCE_CLASSIFICATION, Nothing, ResourceClassification)).ToArray

                            For Each gradeName In GradeNames
                                SetGrade(gradeName, GetGradeValue(gradeName, gradeFiltered))
                            Next
                        Else
                            NullOutGrades()
                        End If

                    End If
                Else
                    Throw New ArgumentException(String.Format("Values rows must contain all required columns."))
                End If
            End If
        End Sub

        Private Shared Function SafeParseString(ByRef dataRow As DataRow, columnName As String, defaultWhenNothingOrEmpty As String, right As String) As Boolean
            SafeParseString = False

            Dim leftValue As String = Nothing

            If Not dataRow Is Nothing And Not columnName Is Nothing And dataRow.Table.Columns.Contains(columnName) Then
                leftValue = dataRow.Item(columnName).ToString()
            End If

            If String.IsNullOrEmpty(leftValue) Then
                leftValue = defaultWhenNothingOrEmpty
            End If

            If Not leftValue Is Nothing Then
                If Not right Is Nothing AndAlso leftValue = right Then
                    SafeParseString = True
                End If
            ElseIf right Is Nothing Then
                SafeParseString = True
            End If
        End Function

        Private Shared Function ParseNullableInt32(left As Object, right As Int32?) As Boolean
            Dim number As Int32
            ParseNullableInt32 = False
            If Int32.TryParse(left.ToString(), number) Then
                If right.HasValue AndAlso number = right.Value Then
                    ParseNullableInt32 = True
                End If
            ElseIf Not right.HasValue Then
                ParseNullableInt32 = True
            End If
        End Function

        ''' <summary>
        ''' Returns a value from the row if it exists.
        ''' </summary>
        ''' <param name="gradeName">Name of the grade to obtain the value for</param>
        ''' <param name="gradeFiltered">All relevant rows, pre-filtered but may contain multiple rows..one per grade</param>
        Private Shared Function GetGradeValue(gradeName As String, gradeFiltered As IEnumerable(Of DataRow)) As Double?
            Dim valueParsed As Double
            Dim returnValue As Double? = Nothing
            Dim row As DataRow

            For Each row In gradeFiltered
                If Not row.Table.Columns.Contains("GradeName") Or Not row.Table.Columns.Contains("GradeValue") Then
                    Throw New ArgumentException("Grade rows must contain the GradeName and GradeValue field.")
                End If

                If row("GradeName").ToString = gradeName Then
                    If Double.TryParse(row("GradeValue").ToString(), valueParsed) Then
                        returnValue = valueParsed
                    End If
                End If
            Next

            Return returnValue
        End Function
#End Region

#Region "Operations"
        '' replace the current density value with one based off the volume / tonnes
        Public Sub CalculateDensity()
            ' Note that density is calculated as Volume / Tonnes (m3/t) it has to be this way so that it aggregates properly
            ' later on, when the data is displayed, the value is inverted to the more traditional units
            If Tonnes <> 0 Then
                Density = Volume / Tonnes
            Else
                Density = Nothing
            End If
        End Sub

        ' This will recalculate the density based off the volume and tonnes. The difference beween this and the CalculateDensity function
        ' is that this method will only replace the value if it can calculate something - it will never replace the density with a null
        Public Sub RecalculateDensity()
            If Not Tonnes Is Nothing AndAlso Not Volume Is Nothing AndAlso Tonnes <> 0 AndAlso Volume <> 0 Then
                CalculateDensity()
            End If
        End Sub

        Public Shared Operator *(left As CalculationResultRecord, right As CalculationResultRecord) As CalculationResultRecord
            Return Multiply(left, right)
        End Operator

        Public Shared Function Multiply(left As CalculationResultRecord, right As CalculationResultRecord) As CalculationResultRecord
            Dim result As New CalculationResultRecord(Nothing)
            If Not left Is Nothing And Not right Is Nothing Then
                If left.CalendarDate = right.CalendarDate Then
                    result.CalendarDate = left.CalendarDate
                End If
                If left.DateFrom = right.DateFrom Then
                    result.DateFrom = left.DateFrom
                End If
                If left.DateTo = right.DateTo Then
                    result.DateTo = left.DateTo
                End If
                If left.LocationId = right.LocationId Then
                    result.LocationId = left.LocationId
                End If
                If left.MaterialTypeId = right.MaterialTypeId Then
                    result.MaterialTypeId = left.MaterialTypeId
                End If
                If left.ProductSize = right.ProductSize Then
                    result.ProductSize = left.ProductSize
                End If
                If Not right.Tonnes Is Nothing AndAlso Not left.Tonnes Is Nothing AndAlso right.Tonnes <> 0 Then
                    result.Tonnes = left.Tonnes * right.Tonnes
                    result.Volume = left.Volume * right.Volume

                    ' As there is no additions or subtractions set the dodgy aggregate to the tonnes value
                    ' See Calculation.vb Sub Calculate Answer for description of Dodgy Aggregate.
                    result.DodgyAggregateGradeTonnes = result.Tonnes

                    For Each gradeName In GradeNames
                        result.SetGrade(gradeName, left.GetGrade(gradeName) * right.GetGrade(gradeName))
                    Next

                End If
                If left.StratNum = right.StratNum Then
                    result.StratNum = left.StratNum
                End If
                If left.StratLevel = right.StratLevel Then
                    result.StratLevel = left.StratLevel
                End If
                If left.Weathering = right.Weathering Then
                    result.Weathering = left.Weathering
                End If
            ElseIf Not right Is Nothing Then
                result = right.Clone()
            ElseIf Not left Is Nothing Then
                result = left.Clone()
            End If

            Return result
        End Function

        Public Shared Operator /(left As CalculationResultRecord, right As CalculationResultRecord) As CalculationResultRecord
            Return Divide(left, right)
        End Operator

        Public Shared Function Divide(left As CalculationResultRecord, right As CalculationResultRecord) As CalculationResultRecord
            Dim result As New CalculationResultRecord(Nothing)
            If Not left Is Nothing And Not right Is Nothing Then
                If left.CalendarDate = right.CalendarDate Then
                    result.CalendarDate = left.CalendarDate
                End If
                If left.DateFrom = right.DateFrom Then
                    result.DateFrom = left.DateFrom
                End If
                If left.DateTo = right.DateTo Then
                    result.DateTo = left.DateTo
                End If
                If left.LocationId = right.LocationId Then
                    result.LocationId = left.LocationId
                End If
                If left.MaterialTypeId = right.MaterialTypeId Then
                    result.MaterialTypeId = left.MaterialTypeId
                End If
                If left.ProductSize = right.ProductSize Then
                    result.ProductSize = left.ProductSize
                End If
                If left.ResourceClassification = right.ResourceClassification Then
                    result.ResourceClassification = left.ResourceClassification
                End If

                If Not right.Volume Is Nothing AndAlso Not left.Volume Is Nothing AndAlso right.Volume <> 0 Then
                    result.Volume = left.Volume / right.Volume
                End If

                If Not right.Tonnes Is Nothing AndAlso Not left.Tonnes Is Nothing AndAlso right.Tonnes <> 0 Then
                    result.Tonnes = left.Tonnes / right.Tonnes
                    result.Volume = left.Volume / right.Volume

                    ' As there is no additions or subtractions set the dodgy aggregate to the tonnes value
                    ' See Calculation.vb Sub Calculate Answer for description of Dodgy Aggregate.
                    result.DodgyAggregateGradeTonnes = result.Tonnes

                    For Each gradeName In GradeNames
                        result.SetGrade(gradeName, RatioGrade(left.GetGrade(gradeName), right.GetGrade(gradeName)))
                    Next
                End If

                If left.StratNum = right.StratNum Then
                    result.StratNum = left.StratNum
                End If

                If left.StratLevel = right.StratLevel Then
                    result.StratLevel = left.StratLevel
                End If

                If left.Weathering = right.Weathering Then
                    result.Weathering = left.Weathering
                End If
            ElseIf Not right Is Nothing Then
                result = right.Clone()
                ' When dividing null against a value, zero out all values as it will be invalid.
                result.Tonnes = 0
                result.Volume = 0
                result.ZeroOutGrades()
            ElseIf Not left Is Nothing Then
                ' When dividing a value against null, zero out all values as it will be invalid.
                result = left.Clone()
                result.Tonnes = 0
                result.Volume = 0
                result.ZeroOutGrades()
            End If

            Return result
        End Function

        ''' <summary>
        ''' Gets the ratio of a grade
        ''' </summary>
        Public Shared Function RatioGrade(leftGrade As Double?, rightGrade As Double?) As Double?
            Dim result As Double?
            If Not leftGrade.HasValue Then
                result = Nothing
            ElseIf Not rightGrade.HasValue Then
                result = Nothing
            ElseIf Math.Abs(rightGrade.Value - 0) < Double.Epsilon Then
                result = 0
            Else
                result = leftGrade / rightGrade
            End If
            Return result
        End Function

        Public Shared Operator +(left As CalculationResultRecord, right As CalculationResultRecord) As CalculationResultRecord
            Return Add(left, right)
        End Operator

        Public Shared Function Add(left As CalculationResultRecord, right As CalculationResultRecord) As CalculationResultRecord
            Dim result = NewRecord(left, right)
            Dim additionTonnes As Double?
            Dim leftTonnes As Double?
            Dim rightTonnes As Double?
            If Not left Is Nothing And Not right Is Nothing Then
                result.Tonnes = left.Tonnes + right.Tonnes
                result.Volume = left.Volume + right.Volume

                'If the dodgy aggregate is enabled then set the left and right tonnes equal to their dodgy aggregate equivelants.
                ' See Calculation.vb Sub Calculate Answer for description of Dodgy Aggregate.
                If left.DodgyAggregateEnabled Then
                    leftTonnes = Math.Abs(left.DodgyAggregateGradeTonnes.Value)
                    rightTonnes = Math.Abs(right.DodgyAggregateGradeTonnes.Value)
                    result.DodgyAggregateGradeTonnes = leftTonnes + rightTonnes
                    result.DodgyAggregateEnabled = True
                Else
                    leftTonnes = left.Tonnes.Value
                    rightTonnes = right.Tonnes.Value
                    result.DodgyAggregateGradeTonnes = result.Tonnes
                    result.DodgyAggregateEnabled = False
                End If
                additionTonnes = leftTonnes + rightTonnes
                If additionTonnes.HasValue AndAlso Math.Abs(additionTonnes.Value - 0) > Double.Epsilon Then
                    For Each gradeName In GradeNames
                        Dim v = AssignGradeIfNotNull(((left.GetGrade(gradeName) * leftTonnes) + (right.GetGrade(gradeName) * rightTonnes)) / additionTonnes, left.GetGrade(gradeName), right.GetGrade(gradeName))
                        result.SetGrade(gradeName, v)
                    Next
                End If
            ElseIf Not right Is Nothing Then
                result = right.Clone()
            ElseIf Not left Is Nothing Then
                result = left.Clone()
            End If

            Return result
        End Function

        Public Shared Operator -(left As CalculationResultRecord, right As CalculationResultRecord) As CalculationResultRecord
            Return Subtract(left, right)
        End Operator

        Public Shared Function Subtract(left As CalculationResultRecord, right As CalculationResultRecord) As CalculationResultRecord
            Dim result = NewRecord(left, right)
            Dim additionTonnes As Double?
            Dim leftTonnes As Double?
            Dim rightTonnes As Double?
            If Not left Is Nothing And Not right Is Nothing Then
                result.Tonnes = left.Tonnes - right.Tonnes
                result.Volume = left.Volume - right.Volume

                'If the dodgy aggregate is enabled then set the left and right tonnes equal to their dodgy aggregate equivelants.
                ' See Calculation.vb Sub Calculate Answer for description of Dodgy Aggregate.
                If left.DodgyAggregateEnabled Then
                    leftTonnes = Math.Abs(left.DodgyAggregateGradeTonnes.Value)
                    rightTonnes = Math.Abs(right.DodgyAggregateGradeTonnes.Value)
                    result.DodgyAggregateGradeTonnes = leftTonnes + rightTonnes
                    result.DodgyAggregateEnabled = True
                Else
                    leftTonnes = left.Tonnes.Value
                    rightTonnes = -right.Tonnes.Value
                    result.DodgyAggregateGradeTonnes = result.Tonnes
                    result.DodgyAggregateEnabled = False
                End If
                additionTonnes = leftTonnes + rightTonnes
                If additionTonnes.HasValue AndAlso Math.Abs(additionTonnes.Value - 0) > Double.Epsilon Then
                    For Each gradeName In GradeNames
                        Dim v = AssignGradeIfNotNull(((left.GetGrade(gradeName) * leftTonnes) + (right.GetGrade(gradeName) * rightTonnes)) / additionTonnes, left.GetGrade(gradeName), right.GetGrade(gradeName))
                        result.SetGrade(gradeName, v)
                    Next
                End If
            ElseIf Not right Is Nothing Then
                result = right.Clone()
                ' When the right value is being taken and there is nothing to take it against, make the tonnes negative.
                result.Tonnes = -result.Tonnes
            ElseIf Not left Is Nothing Then
                result = left.Clone()
            End If

            Return result
        End Function

        Private Shared Function AssignGradeIfNotNull(gradeValue As Double?,
         leftGradeValue As Double?, rightGradeValue As Double?) As Double?
            If gradeValue Is Nothing Then
                If Not rightGradeValue Is Nothing Then
                    AssignGradeIfNotNull = rightGradeValue
                Else
                    AssignGradeIfNotNull = leftGradeValue
                End If
            Else
                AssignGradeIfNotNull = gradeValue
            End If
        End Function

        Public Shared Function Difference(left As CalculationResultRecord, right As CalculationResultRecord) As CalculationResultRecord
            Dim result = NewRecord(left, right)
            If Not left Is Nothing And Not right Is Nothing Then
                result.Tonnes = left.Tonnes - right.Tonnes
                result.Volume = left.Volume - right.Volume

                ' As there is no additions or subtractions set the dodgy aggregate to the tonnes value
                ' See Calculation.vb Sub Calculate Answer for description of Dodgy Aggregate.
                result.DodgyAggregateGradeTonnes = result.Tonnes

                For Each gradeName In GradeNames
                    result.SetGrade(gradeName, left.GetGrade(gradeName) - right.GetGrade(gradeName))
                Next
            ElseIf Not right Is Nothing Then
                result = right.Clone()
            ElseIf Not left Is Nothing Then
                result = left.Clone()
            End If

            Return result
        End Function

        Private Shared Function NewRecord(left As CalculationResultRecord, right As CalculationResultRecord) As CalculationResultRecord
            Dim result As New CalculationResultRecord(Nothing)
            If Not left Is Nothing And Not right Is Nothing Then
                If left.CalendarDate = right.CalendarDate Then
                    result.CalendarDate = left.CalendarDate
                End If
                If left.DateFrom = right.DateFrom Then
                    result.DateFrom = left.DateFrom
                End If
                If left.DateTo = right.DateTo Then
                    result.DateTo = left.DateTo
                End If
                If left.LocationId = right.LocationId Then
                    result.LocationId = left.LocationId
                End If
                If left.MaterialTypeId = right.MaterialTypeId Then
                    result.MaterialTypeId = left.MaterialTypeId
                End If
                If left.ProductSize = right.ProductSize Then
                    result.ProductSize = left.ProductSize
                End If
                If left.ResourceClassification = right.ResourceClassification Then
                    result.ResourceClassification = left.ResourceClassification
                End If
                If left.StratNum = right.StratNum Then
                    result.StratNum = left.StratNum
                End If
                If left.StratLevel = right.StratLevel Then
                    result.StratLevel = left.StratLevel
                End If
                If left.Weathering = right.Weathering Then
                    result.Weathering = left.Weathering
                End If
            End If

            Return result
        End Function
#End Region

#Region "Object Functions"
        Public Function Clone() As CalculationResultRecord
            Clone = Clone(Nothing)
        End Function

        Public Function Clone(calcResultParent As CalculationResult) As CalculationResultRecord
            Clone = New CalculationResultRecord(calcResultParent) With {
                .Tonnes = Tonnes,
                .Volume = Volume,
                .DodgyAggregateGradeTonnes = DodgyAggregateGradeTonnes
            }

            For Each gradeName In GradeNames
                Clone.SetGrade(gradeName, GetGrade(gradeName))
            Next

            Clone.CalendarDate = CalendarDate
            Clone.DateFrom = DateFrom
            Clone.DateTo = DateTo
            Clone.MaterialTypeId = MaterialTypeId
            Clone.LocationId = LocationId
            Clone.ProductSize = ProductSize
            Clone.SortKey = SortKey
            Clone.ResourceClassification = ResourceClassification
            Clone.StratNum = StratNum
            Clone.StratLevel = StratLevel
            Clone.Weathering = Weathering
        End Function

        Public Sub NullOutGrades()
            For Each gradeName In GradeNames
                SetGrade(gradeName, Nothing)
            Next
        End Sub

        Public Sub ZeroOutGrades()
            For Each gradeName In GradeNames
                SetGrade(gradeName, 0.0)
            Next
        End Sub

        Public Sub ZeroOutNullGrades()
            For Each gradeName In GradeNames
                If GetGrade(gradeName) Is Nothing Then
                    SetGrade(gradeName, 0.0)
                End If
            Next
        End Sub

        Public Function ToDataTable(normalizedData As Boolean) As DataTable
            Dim table As New DataTable()
            table.Columns.Add(New DataColumn(ColumnNames.DATE_CAL, GetType(DateTime)))
            table.Columns.Add(New DataColumn(ColumnNames.DATE_FROM, GetType(DateTime)))
            table.Columns.Add(New DataColumn(ColumnNames.DATE_TO, GetType(DateTime)))
            table.Columns.Add(New DataColumn(ColumnNames.LOCATION_ID, GetType(Int32)))
            table.Columns.Add(New DataColumn(ColumnNames.MATERIAL_TYPE_ID, GetType(Int32)))
            table.Columns.Add(New DataColumn(ColumnNames.PRODUCT_SIZE, GetType(String)))
            table.Columns.Add(New DataColumn(ColumnNames.RESOURCE_CLASSIFICATION, GetType(String)))
            table.Columns.Add(New DataColumn(ColumnNames.SORT_KEY, GetType(String)))
            table.Columns.Add(New DataColumn(ColumnNames.STRAT_NUM, GetType(String)))
            table.Columns.Add(New DataColumn(ColumnNames.STRAT_LEVEL, GetType(String)))
            table.Columns.Add(New DataColumn(ColumnNames.WEATHERING, GetType(Integer)))

            If Not normalizedData Then
                table.Columns.Add(New DataColumn("Tonnes", GetType(Double)))
                table.Columns.Add(New DataColumn("Volume", GetType(Double)))
                table.Columns.Add(New DataColumn("DodgyAggregateGradeTonnes", GetType(Double)))

                For Each gradeName In GradeNames
                    table.Columns.Add(New DataColumn(gradeName, GetType(Double)))
                Next

                table.Rows.Add(AddDenormalizedRow(table))
            Else
                table.Columns.Add(New DataColumn("Attribute", GetType(String)))
                table.Columns.Add(New DataColumn("AttributeValue", GetType(Double)))

                table.Rows.Add(AddNormalizedRow("Tonnes", Tonnes, table))
                table.Rows.Add(AddNormalizedRow("Volume", Volume, table))
                table.Rows.Add(AddNormalizedRow("DodgyAggregateGradeTonnes", DodgyAggregateGradeTonnes, table))

                For Each gradeName In GradeNames
                    table.Rows.Add(AddNormalizedRow(gradeName, GetGrade(gradeName), table))
                Next
            End If

            Return table
        End Function

        Private Function AddNormalizedRow(gradeName As String, gradeValue As Double?, table As DataTable) As DataRow
            Dim row = AddBaseRow(table)
            row("Attribute") = gradeName
            row("AttributeValue") = IIf(gradeValue Is Nothing, DBNull.Value, gradeValue)
            Return row
        End Function

        Private Function AddDenormalizedRow(table As DataTable) As DataRow
            Dim row = AddBaseRow(table)
            row("Tonnes") = IIf(Tonnes Is Nothing, DBNull.Value, Tonnes)
            row("Volume") = IIf(Volume Is Nothing, DBNull.Value, Volume)
            row("DodgyAggregateGradeTonnes") = IIf(DodgyAggregateGradeTonnes Is Nothing, DBNull.Value, DodgyAggregateGradeTonnes)

            For Each gradeName In GradeNames
                row(gradeName) = IIf(GetGrade(gradeName) Is Nothing, DBNull.Value, GetGrade(gradeName))
            Next

            Return row
        End Function

        Private Function AddBaseRow(table As DataTable) As DataRow
            Dim row = table.NewRow()
            row(ColumnNames.DATE_CAL) = CalendarDate
            row(ColumnNames.DATE_FROM) = DateFrom
            row(ColumnNames.DATE_TO) = DateTo
            row(ColumnNames.MATERIAL_TYPE_ID) = IIf(MaterialTypeId Is Nothing, DBNull.Value, MaterialTypeId)
            row(ColumnNames.LOCATION_ID) = IIf(LocationId Is Nothing, DBNull.Value, LocationId)
            row(ColumnNames.PRODUCT_SIZE) = IIf(ProductSize Is Nothing, DBNull.Value, ProductSize)
            row(ColumnNames.RESOURCE_CLASSIFICATION) = IIf(ResourceClassification Is Nothing, DBNull.Value, ResourceClassification)
            row(ColumnNames.SORT_KEY) = IIf(SortKey Is Nothing, DBNull.Value, SortKey)
            row(ColumnNames.STRAT_NUM) = IIf(String.IsNullOrEmpty(StratNum), DBNull.Value, StratNum)
            row(ColumnNames.STRAT_LEVEL) = IIf(String.IsNullOrEmpty(StratLevel), DBNull.Value, StratLevel)
            row(ColumnNames.WEATHERING) = IIf(Weathering Is Nothing, DBNull.Value, Weathering)
            Return row
        End Function

#End Region

        Public Overrides Function Equals(obj As Object) As Boolean
            If obj.GetType() IsNot GetType(CalculationResultRecord) Then
                Return False
            Else
                Dim comparisonObj = CType(obj, CalculationResultRecord)
                Return Al2O3.Equals(comparisonObj.Al2O3) And
                       CalendarDate = comparisonObj.CalendarDate And
                       DateFrom = comparisonObj.DateFrom And
                       DateTo = comparisonObj.DateTo And
                       Density.Equals(comparisonObj.Density) And
                       DodgyAggregateEnabled.Equals(comparisonObj.DodgyAggregateEnabled) And
                       DodgyAggregateGradeTonnes.Equals(comparisonObj.DodgyAggregateGradeTonnes) And
                       EffectiveProductSize = comparisonObj.EffectiveProductSize And
                       Fe.Equals(comparisonObj.Fe) And
                       H2O.Equals(comparisonObj.H2O) And
                       H2ODropped.Equals(comparisonObj.H2ODropped) And
                       H2OShipped.Equals(comparisonObj.H2OShipped) And
                       LocationId.Equals(comparisonObj.LocationId) And
                       Loi.Equals(comparisonObj.Loi) And
                       MaterialTypeId.Equals(comparisonObj.MaterialTypeId) And
                       P.Equals(comparisonObj.P) And
                       Equals(Parent, comparisonObj.Parent) And 'Parent.Equals... breaks if Parent is null, this works correctly.
                       ProductSize = comparisonObj.ProductSize And
                       ResourceClassification = comparisonObj.ResourceClassification And
                       SiO2.Equals(comparisonObj.SiO2) And
                       SortKey = comparisonObj.SortKey And
                       Tonnes.Equals(comparisonObj.Tonnes) And
                       UltraFines.Equals(comparisonObj.UltraFines) And
                       Volume.Equals(comparisonObj.Volume) And
                       StratNum = comparisonObj.StratNum And
                       StratLevel = comparisonObj.StratLevel And
                       Weathering.Equals(comparisonObj.Weathering)
            End If
        End Function
    End Class
End Namespace