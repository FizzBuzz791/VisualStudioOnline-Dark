Imports Snowden.Reconcilor.Bhpbio.Report.Constants
Imports Snowden.Reconcilor.Bhpbio.Report.Extensions
Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions

Namespace Types


    Public Class CalculationResultRow
        Inherits CalculationResultRecord

        Public Sub New()
            MyBase.New()
        End Sub

        Private _reportTagId As String
        Private _calcId As String
        Private _description As String

        Public Property CalcId() As String
            Get
                Return _calcId
            End Get
            Set(ByVal value As String)
                _calcId = value
            End Set
        End Property

        Public ReadOnly Property TagId() As String
            Get
                If ProductSize IsNot Nothing And ProductSize.ToUpper <> "TOTAL" Then
                    Return ReportTagId + ProductSize
                Else
                    Return ReportTagId
                End If
            End Get
        End Property

        Public Property ReportTagId() As String
            Get
                Return _reportTagId
            End Get
            Set(ByVal value As String)
                _reportTagId = value
            End Set
        End Property

        Public Property Description() As String
            Get
                Return _description
            End Get
            Set(ByVal value As String)
                _description = value
            End Set
        End Property

    End Class

    <DebuggerDisplayAttribute("CalendarDate:{_calendarDate}, LocationId:{_locationId}, MaterialId:{_materialTypeId}, Product:{_productSize}, Tonnes:{_tonnes}")> _
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
        Private _parent As CalculationResult
        Private _calendarDate As DateTime
        Private _dateFrom As DateTime
        Private _dateTo As DateTime
        Private _locationId As Int32?
        Private _materialTypeId As Int32?
        Private _tonnes As Double?
        Private _volume As Double? = Nothing
        Private _fe As Double?
        Private _p As Double?
        Private _siO2 As Double?
        Private _al2O3 As Double?
        Private _loi As Double?
        Private _density As Double?
        Private _h2O As Double?
        Private _h2ODropped As Double?
        Private _h2OShipped As Double?
        Private _ultraFines As Double?

        Private _productSize As String
        Private _sortKey As String

        'Dodgy aggregate fields for use
        ' See Calculation.vb Sub Calculate Answer for description of Dodgy Aggregate.
        Private _dodgyAggregateGradeTonnes As Double?
        Private _dodgyAggregateEnabled As Boolean?

        Public Property Parent() As CalculationResult
            Get
                Return _parent
            End Get
            Set(ByVal value As CalculationResult)
                _parent = value
            End Set
        End Property

        Public Property CalendarDate() As DateTime
            Get
                Return _calendarDate
            End Get
            Set(ByVal value As DateTime)
                _calendarDate = value
            End Set
        End Property

        Public Property DateFrom() As DateTime
            Get
                Return _dateFrom
            End Get
            Set(ByVal value As DateTime)
                _dateFrom = value
            End Set
        End Property

        Public Property DateTo() As DateTime
            Get
                Return _dateTo
            End Get
            Set(ByVal value As DateTime)
                _dateTo = value
            End Set
        End Property

        Public Property LocationId() As Int32?
            Get
                Return _locationId
            End Get
            Set(ByVal value As Int32?)
                _locationId = value
            End Set
        End Property

        Public Property MaterialTypeId() As Int32?
            Get
                Return _materialTypeId
            End Get
            Set(ByVal value As Int32?)
                _materialTypeId = value
            End Set
        End Property

        Public Property ProductSize() As String
            Get
                Return _productSize
            End Get
            Set(ByVal value As String)
                _productSize = value
            End Set
        End Property

        Public Property SortKey() As String
            Get
                Return _sortKey
            End Get
            Set(ByVal value As String)
                _sortKey = value
            End Set
        End Property

        Public ReadOnly Property EffectiveProductSize() As String
            Get
                Return IIf(ProductSize Is Nothing, CalculationConstants.PRODUCT_SIZE_TOTAL, ProductSize).ToString
            End Get
        End Property

        Public Property Tonnes() As Double?
            Get
                Return _tonnes
            End Get
            Set(ByVal value As Double?)
                _tonnes = value
            End Set
        End Property

        Public Property Volume() As Double?
            Get
                Return _volume
            End Get
            Set(ByVal value As Double?)
                _volume = value
            End Set
        End Property

        Public Property ResourceClassification As String = Nothing

        Public Property DodgyAggregateGradeTonnes() As Double?
            Get
                Return _dodgyAggregateGradeTonnes
            End Get
            Set(ByVal value As Double?)
                _dodgyAggregateGradeTonnes = value
            End Set
        End Property

        Public Property DodgyAggregateEnabled() As Boolean?
            Get
                Return _dodgyAggregateEnabled
            End Get
            Set(ByVal value As Boolean?)
                _dodgyAggregateEnabled = value
            End Set
        End Property

        Property Fe() As Double?
            Get
                Return _fe
            End Get
            Set(ByVal value As Double?)
                _fe = value
            End Set
        End Property

        Property P() As Double?
            Get
                Return _p
            End Get
            Set(ByVal value As Double?)
                _p = value
            End Set
        End Property

        Property SiO2() As Double?
            Get
                Return _siO2
            End Get
            Set(ByVal value As Double?)
                _siO2 = value
            End Set
        End Property

        Property Al2O3() As Double?
            Get
                Return _al2O3
            End Get
            Set(ByVal value As Double?)
                _al2O3 = value
            End Set
        End Property

        Property Loi() As Double?
            Get
                Return _loi
            End Get
            Set(ByVal value As Double?)
                _loi = value
            End Set
        End Property

        Property Density() As Double?
            Get
                Return _density
            End Get
            Set(ByVal value As Double?)
                _density = value
            End Set
        End Property

        Public Property H2O() As Double?
            Get
                Return _h2O
            End Get
            Set(ByVal value As Double?)
                _h2O = value
            End Set
        End Property

        Public Property H2ODropped() As Double?
            Get
                Return _h2ODropped
            End Get
            Set(ByVal value As Double?)
                _h2ODropped = value
            End Set
        End Property

        Public Property H2OShipped() As Double?
            Get
                Return _h2OShipped
            End Get
            Set(ByVal value As Double?)
                _h2OShipped = value
            End Set
        End Property

        Public Property UltraFines() As Double?
            Get
                Return _ultraFines
            End Get
            Set(ByVal value As Double?)
                _ultraFines = value
            End Set
        End Property
#End Region

#Region "Constructors"

        Public Sub New()
            _parent = Nothing
        End Sub

        Public Sub New(ByVal parent As CalculationResult)
            _parent = parent
        End Sub

        Public Sub New(ByVal parent As CalculationResult, ByVal dateFrom As DateTime, ByVal dateTo As DateTime)
            Me.New(parent)
            _calendarDate = dateFrom
            _dateFrom = dateFrom
            _dateTo = dateTo
            _productSize = CalculationConstants.PRODUCT_SIZE_TOTAL
        End Sub

        Public Sub New(ByVal value As DataRow, ByVal grades As IEnumerable(Of DataRow))
            Merge(value, grades)
        End Sub

        Public Sub New(ByVal parent As CalculationResult, ByVal value As DataRow, ByVal grades As IEnumerable(Of DataRow))
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
        Public Function GetGrade(ByVal gradeName As String) As Double?
            Select Case gradeName.ToLower
                Case "fe" : Return Me.Fe
                Case "p" : Return Me.P
                Case "sio2" : Return Me.SiO2
                Case "al2o3" : Return Me.Al2O3
                Case "loi" : Return Me.Loi
                Case "density" : Return Me.Density
                Case "h2o" : Return Me.H2O
                Case "h2o-as-dropped" : Return Me.H2ODropped
                Case "h2o-as-shipped" : Return Me.H2OShipped
                Case "ultrafines" : Return Me.UltraFines
            End Select
        End Function

        Public Sub SetGrade(ByVal gradeName As String, ByVal value As Double?)
            Select Case gradeName.ToLower
                Case "fe" : Me.Fe = value
                Case "p" : Me.P = value
                Case "sio2" : Me.SiO2 = value
                Case "al2o3" : Me.Al2O3 = value
                Case "loi" : Me.Loi = value
                Case "density" : Me.Density = value
                Case "h2o" : Me.H2O = value
                Case "h2o-as-dropped" : Me.H2ODropped = value
                Case "h2o-as-shipped" : Me.H2OShipped = value
                Case "ultrafines" : Me.UltraFines = value
            End Select
        End Sub

        Public Sub Merge(ByVal value As DataRow, ByVal grades As IEnumerable(Of DataRow))
            'Dim dates As New Dictionary(Of DateTime, DataRow)
            Dim columns As DataColumnCollection
            Dim colsExists As Boolean
            Dim calDate As DateTime
            Dim parsedMaterialTypeId As Int32
            Dim parsedLocationId As Int32

            If Not value Is Nothing Then
                ' Gather up the listings from the data table.
                columns = value.Table.Columns

                colsExists = columns.Contains(CalculationConstants.COLUMN_NAME_DATE_CAL) And
                    columns.Contains(CalculationConstants.COLUMN_NAME_LOCATION_ID) And
                    columns.Contains(CalculationConstants.COLUMN_NAME_MATERIAL_TYPE)

                If colsExists Then
                    If DateTime.TryParse(value(CalculationConstants.COLUMN_NAME_DATE_CAL).ToString(), calDate) Then
                        CalendarDate = calDate
                        DateFrom = Convert.ToDateTime(value(CalculationConstants.COLUMN_NAME_DATE_FROM).ToString())
                        DateTo = Convert.ToDateTime(value(CalculationConstants.COLUMN_NAME_DATE_TO).ToString())

                        If Int32.TryParse(value(CalculationConstants.COLUMN_NAME_LOCATION_ID).ToString(), parsedLocationId) Then
                            LocationId = parsedLocationId
                        End If

                        If Int32.TryParse(value(CalculationConstants.COLUMN_NAME_MATERIAL_TYPE).ToString(), parsedMaterialTypeId) Then
                            MaterialTypeId = parsedMaterialTypeId
                        End If

                        If columns.Contains(CalculationConstants.COLUMN_NAME_PRODUCT_SIZE) Then
                            ProductSize = value(CalculationConstants.COLUMN_NAME_PRODUCT_SIZE).ToString()
                        End If

                        Tonnes = Convert.ToDouble(value("Tonnes").ToString)

                        If value.Table.Columns.Contains("Volume") AndAlso Not IsDBNull(value("Volume")) AndAlso Not value("Volume") Is Nothing Then
                            Volume = Convert.ToDouble(value("Volume").ToString)
                        Else
                            Volume = Nothing
                        End If

                        If value.HasColumn("ResourceClassification") AndAlso value.HasValue("ResourceClassification") Then
                            ResourceClassification = value.AsString("ResourceClassification")
                        End If

                        ' Set the intial value of the dodgy aggregate to the tonnes value
                        ' See Calculation.vb Sub Calculate Answer for description of Dodgy Aggregate.
                        DodgyAggregateGradeTonnes = Tonnes

                        ' Pivot the grade data
                        If Not grades Is Nothing Then

                            Dim gradeFiltered As IEnumerable(Of DataRow)
                            ' filter the records to only those appropriate for the value data row
                            gradeFiltered = grades.Where(Function(g) Convert.ToDateTime(g(CalculationConstants.COLUMN_NAME_DATE_CAL).ToString()) = CalendarDate _
                                             And ParseNullableInt32(g(CalculationConstants.COLUMN_NAME_LOCATION_ID), LocationId) _
                                             And ParseNullableInt32(g(CalculationConstants.COLUMN_NAME_MATERIAL_TYPE), MaterialTypeId) _
                                             And SafeParseString(g, CalculationConstants.COLUMN_NAME_PRODUCT_SIZE, CalculationConstants.PRODUCT_SIZE_TOTAL, EffectiveProductSize) _
                                             And SafeParseString(g, "ResourceClassification", Nothing, ResourceClassification)).ToArray

                            For Each gradeName As String In GradeNames
                                Me.SetGrade(gradeName, GetGradeValue(gradeName, gradeFiltered))
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

        Private Shared Function SafeParseString(ByRef dataRow As DataRow, ByVal columnName As String, ByVal defaultWhenNothingOrEmpty As String, ByVal right As String) As Boolean
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

        Private Shared Function ParseNullableInt32(ByVal left As Object, ByVal right As Int32?) As Boolean
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
        Private Function GetGradeValue(ByVal gradeName As String, ByVal gradeFiltered As IEnumerable(Of DataRow)) As Double?
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
            If Me.Tonnes <> 0 Then
                Density = Volume / Tonnes
            Else
                Density = Nothing
            End If
        End Sub

        ' This will recalculate the density based off the volume and tonnes. The difference beween this and the CalculateDensity function
        ' is that this method will only replace the value if it can calculate something - it will never replace the density with a null
        Public Sub RecalculateDensity()
            If Not Me.Tonnes Is Nothing AndAlso Not Me.Volume Is Nothing AndAlso Me.Tonnes <> 0 AndAlso Me.Volume <> 0 Then
                Me.CalculateDensity()
            End If
        End Sub

        Public Shared Operator *(ByVal left As CalculationResultRecord, ByVal right As CalculationResultRecord) As CalculationResultRecord
            Return Multiply(left, right)
        End Operator

        Public Shared Function Multiply(ByVal left As CalculationResultRecord, ByVal right As CalculationResultRecord) As CalculationResultRecord
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

                    For Each gradeName As String In GradeNames
                        result.SetGrade(gradeName, left.GetGrade(gradeName) * right.GetGrade(gradeName))
                    Next

                End If
            ElseIf Not right Is Nothing Then
                result = right.Clone()
            ElseIf Not left Is Nothing Then
                result = left.Clone()
            End If

            Return result
        End Function

        Public Shared Operator /(ByVal left As CalculationResultRecord, ByVal right As CalculationResultRecord) As CalculationResultRecord
            Return Divide(left, right)
        End Operator

        Public Shared Function Divide(ByVal left As CalculationResultRecord, ByVal right As CalculationResultRecord) As CalculationResultRecord
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

                    For Each gradeName As String In GradeNames
                        result.SetGrade(gradeName, RatioGrade(left.GetGrade(gradeName), right.GetGrade(gradeName)))
                    Next
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
        Public Shared Function RatioGrade(ByVal leftGrade As Double?, ByVal rightGrade As Double?) As Double?
            Dim result As Double?
            If Not leftGrade.HasValue Then
                result = Nothing
            ElseIf Not rightGrade.HasValue Then
                result = Nothing
            ElseIf rightGrade.Value = 0 Then
                result = 0
            Else
                result = leftGrade / rightGrade
            End If
            Return result
        End Function

        Public Shared Operator +(ByVal left As CalculationResultRecord, ByVal right As CalculationResultRecord) As CalculationResultRecord
            Return Add(left, right)
        End Operator

        Public Shared Function Add(ByVal left As CalculationResultRecord, ByVal right As CalculationResultRecord) As CalculationResultRecord
            Dim result As CalculationResultRecord = NewRecord(left, right)
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
                If additionTonnes.HasValue AndAlso additionTonnes.Value <> 0 Then
                    For Each gradeName As String In GradeNames
                        Dim v As Double? = AssignGradeIfNotNull(((left.GetGrade(gradeName) * leftTonnes) + (right.GetGrade(gradeName) * rightTonnes)) / additionTonnes, left.GetGrade(gradeName), right.GetGrade(gradeName))
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

        Public Shared Operator -(ByVal left As CalculationResultRecord, ByVal right As CalculationResultRecord) As CalculationResultRecord
            Return Subtract(left, right)
        End Operator

        Public Shared Function Subtract(ByVal left As CalculationResultRecord, ByVal right As CalculationResultRecord) As CalculationResultRecord
            Dim result As CalculationResultRecord = NewRecord(left, right)
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
                If additionTonnes.HasValue AndAlso additionTonnes.Value <> 0 Then
                    For Each gradeName As String In GradeNames
                        Dim v As Double? = AssignGradeIfNotNull(((left.GetGrade(gradeName) * leftTonnes) + (right.GetGrade(gradeName) * rightTonnes)) / additionTonnes, left.GetGrade(gradeName), right.GetGrade(gradeName))
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

        Private Shared Function AssignGradeIfNotNull(ByVal gradeValue As Double?,
         ByVal leftGradeValue As Double?, ByVal rightGradeValue As Double?) As Double?
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

        Public Shared Function Difference(ByVal left As CalculationResultRecord, ByVal right As CalculationResultRecord) As CalculationResultRecord
            Dim result As CalculationResultRecord = NewRecord(left, right)
            If Not left Is Nothing And Not right Is Nothing Then
                result.Tonnes = left.Tonnes - right.Tonnes
                result.Volume = left.Volume - right.Volume

                ' As there is no additions or subtractions set the dodgy aggregate to the tonnes value
                ' See Calculation.vb Sub Calculate Answer for description of Dodgy Aggregate.
                result.DodgyAggregateGradeTonnes = result.Tonnes

                For Each gradeName As String In GradeNames
                    result.SetGrade(gradeName, left.GetGrade(gradeName) - right.GetGrade(gradeName))
                Next
            ElseIf Not right Is Nothing Then
                result = right.Clone()
            ElseIf Not left Is Nothing Then
                result = left.Clone()
            End If

            Return result
        End Function

        Private Shared Function NewRecord(ByVal left As CalculationResultRecord, ByVal right As CalculationResultRecord) As CalculationResultRecord
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
            End If

            Return result
        End Function
#End Region

#Region "Object Functions"
        Public Function Clone() As CalculationResultRecord
            Clone = Clone(Nothing)
        End Function

        Public Function Clone(ByVal parent As CalculationResult) As CalculationResultRecord
            Clone = New CalculationResultRecord(parent)
            Clone.Tonnes = Tonnes
            Clone.Volume = Volume
            Clone.DodgyAggregateGradeTonnes = DodgyAggregateGradeTonnes

            For Each gradeName As String In GradeNames
                Clone.SetGrade(gradeName, Me.GetGrade(gradeName))
            Next

            Clone.CalendarDate = CalendarDate
            Clone.DateFrom = DateFrom
            Clone.DateTo = DateTo
            Clone.MaterialTypeId = MaterialTypeId
            Clone.LocationId = LocationId
            Clone.ProductSize = ProductSize
            Clone.SortKey = SortKey
            Clone.ResourceClassification = ResourceClassification

        End Function

        Public Sub NullOutGrades()
            For Each gradeName As String In GradeNames
                Me.SetGrade(gradeName, Nothing)
            Next
        End Sub

        Public Sub ZeroOutGrades()
            For Each gradeName As String In GradeNames
                Me.SetGrade(gradeName, 0.0)
            Next
        End Sub

        Public Sub ZeroOutNullGrades()

            For Each gradeName As String In GradeNames
                If Me.GetGrade(gradeName) Is Nothing Then
                    Me.SetGrade(gradeName, 0.0)
                End If
            Next

        End Sub

        Public Function ToDataTable(ByVal normalizedData As Boolean) As DataTable
            Dim table As New DataTable()
            table.Columns.Add(New DataColumn("CalendarDate", GetType(DateTime), ""))
            table.Columns.Add(New DataColumn("DateFrom", GetType(DateTime), ""))
            table.Columns.Add(New DataColumn("DateTo", GetType(DateTime), ""))
            table.Columns.Add(New DataColumn("LocationId", GetType(Int32), ""))
            table.Columns.Add(New DataColumn("MaterialTypeId", GetType(Int32), ""))
            table.Columns.Add(New DataColumn(CalculationConstants.COLUMN_NAME_PRODUCT_SIZE, GetType(String), ""))
            table.Columns.Add(New DataColumn("ResourceClassification", GetType(String)))
            table.Columns.Add(New DataColumn(CalculationConstants.COLUMN_NAME_SORT_KEY, GetType(String), ""))

            If Not normalizedData Then
                table.Columns.Add(New DataColumn("Tonnes", GetType(Double), ""))
                table.Columns.Add(New DataColumn("Volume", GetType(Double), ""))
                table.Columns.Add(New DataColumn("DodgyAggregateGradeTonnes", GetType(Double), ""))

                For Each gradeName As String In GradeNames
                    table.Columns.Add(New DataColumn(gradeName, GetType(Double), ""))
                Next

                table.Rows.Add(AddDenormalizedRow(table))
            Else
                table.Columns.Add(New DataColumn("Attribute", GetType(String), ""))
                table.Columns.Add(New DataColumn("AttributeValue", GetType(Double), ""))

                table.Rows.Add(AddNormalizedRow("Tonnes", Tonnes, table))
                table.Rows.Add(AddNormalizedRow("Volume", Volume, table))
                table.Rows.Add(AddNormalizedRow("DodgyAggregateGradeTonnes", DodgyAggregateGradeTonnes, table))

                For Each gradeName As String In GradeNames
                    table.Rows.Add(AddNormalizedRow(gradeName, GetGrade(gradeName), table))
                Next
            End If

            Return table
        End Function

        Private Function AddNormalizedRow(ByVal gradeName As String, ByVal gradeValue As Double?,
         ByVal table As DataTable) As DataRow
            Dim row As DataRow = AddBaseRow(table)
            row("Attribute") = gradeName
            row("AttributeValue") = IIf(gradeValue Is Nothing, DBNull.Value, gradeValue)
            Return row
        End Function

        Private Function AddDenormalizedRow(ByVal table As DataTable) As DataRow
            Dim row As DataRow = AddBaseRow(table)
            row("Tonnes") = IIf(Tonnes Is Nothing, DBNull.Value, Tonnes)
            row("Volume") = IIf(Volume Is Nothing, DBNull.Value, Volume)
            row("DodgyAggregateGradeTonnes") = IIf(DodgyAggregateGradeTonnes Is Nothing, DBNull.Value, DodgyAggregateGradeTonnes)

            For Each gradeName As String In GradeNames
                row(gradeName) = IIf(Me.GetGrade(gradeName) Is Nothing, DBNull.Value, Me.GetGrade(gradeName))
            Next

            Return row
        End Function

        Private Function AddBaseRow(ByVal table As DataTable) As DataRow
            Dim row As DataRow = table.NewRow()
            row("CalendarDate") = CalendarDate
            row("DateFrom") = DateFrom
            row("DateTo") = DateTo
            row("MaterialTypeId") = IIf(MaterialTypeId Is Nothing, DBNull.Value, MaterialTypeId)
            row("LocationId") = IIf(LocationId Is Nothing, DBNull.Value, LocationId)
            row(CalculationConstants.COLUMN_NAME_PRODUCT_SIZE) = IIf(ProductSize Is Nothing, DBNull.Value, ProductSize)
            row("ResourceClassification") = IIf(ResourceClassification Is Nothing, DBNull.Value, ResourceClassification)
            row(CalculationConstants.COLUMN_NAME_SORT_KEY) = IIf(SortKey Is Nothing, DBNull.Value, SortKey)
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
                       Volume.Equals(comparisonObj.Volume)
            End If
        End Function
    End Class
End Namespace