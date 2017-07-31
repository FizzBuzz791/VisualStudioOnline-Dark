Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc

    Public MustInherit Class CalculationModel
        Inherits Calculation
        Implements IAllMaterialTypesCalculation

#Region "Properties"

        ' H2O As Dropped indicator
        Public Const H2OOverideAsDropped As String = "H2OAsDropped"
        ' H2O As Shipped indicator
        Public Const H2OOverideAsShipped As String = "H2OAsShipped"

        Private _h2OOverride As String = Nothing
        Private _shouldAppendH2OOverrideToCalculationIdAndDescription As Boolean = False
        Private _includeAllMaterialTypes As Boolean = False

        Public Property GeometType As GeometTypeSelection = DefaultGeometType

        Protected MustOverride ReadOnly Property ModelName() As String
        Protected MustOverride ReadOnly Property DefaultGeometType As GeometTypeSelection

        ''' <summary>
        ''' By default, all factors on F1F2F3 Validation + Approval screen are high grade only. By default this flag is set to false to mean include high grade only.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property IncludeAllMaterialTypes() As Boolean Implements IAllMaterialTypesCalculation.IncludeAllMaterialTypes
            Get
                Return _includeAllMaterialTypes
            End Get
            Set(ByVal value As Boolean)
                _includeAllMaterialTypes = value
            End Set
        End Property

        ''' <summary>
        ''' Value that indicates the type of H2O override in place if any
        ''' </summary>
        ''' <value>The type of H2O override required</value>
        ''' <returns>The name of the override in place, if any</returns>
        ''' <remarks>Use the CalculationModel.H2OOverride... constants</remarks>
        Public Property H2OOverride() As String
            Get
                Return _h2OOverride
            End Get
            Set(ByVal value As String)
                _h2OOverride = value
            End Set
        End Property

        ''' <summary>
        ''' A flag indicating whether the H2O override in place should cause the calculation Id to be modified or not
        ''' </summary>
        ''' <value>If true, the name of the H2O override in place will be appended to the CalculationId</value>
        ''' <returns>true if the name of the H2O override in place will be appended to the CalculationId</returns>
        Public Property ShouldAppendH2OOverrideToIdAndDescription() As Boolean
            Get
                Return _shouldAppendH2OOverrideToCalculationIdAndDescription
            End Get
            Set(ByVal value As Boolean)
                _shouldAppendH2OOverrideToCalculationIdAndDescription = value
            End Set
        End Property

        ''' <summary>
        ''' Creates a CalculatiomModel of the specified type explicitly for a H2O Override
        ''' </summary>
        ''' <param name="calcType">The type of model calculation</param>
        ''' <param name="session">The report session</param>
        ''' <param name="h2OOverride">The type of H2O Override being performed</param>
        ''' <returns>A calculation object setup for the H2O override required</returns>
        Public Shared Function CreateForExplicitH2OOverride(ByVal calcType As CalcType, ByVal session As ReportSession, ByVal h2OOverride As String) As CalculationModel
            Dim model As CalculationModel = CType(Calc.Calculation.Create(calcType, session), CalculationModel)
            model.H2OOverride = h2OOverride
            model.ShouldAppendH2OOverrideToIdAndDescription = True
            Return model
        End Function

        Public Shared Function CreateWithGeometType(ByVal calcType As CalcType, session As ReportSession, geometType As GeometTypeSelection) As CalculationModel
            Dim model As CalculationModel = CType(Calc.Calculation.Create(calcType, session), CalculationModel)
            model.GeometType = geometType
            Return model
        End Function

        Protected Overrides ReadOnly Property ResultType() As CalculationResultType
            Get
                Return CalculationResultType.Tonnes
            End Get
        End Property

#End Region

        ''' <summary>
        ''' Get the CalculationId with an optional suffix
        ''' </summary>
        ''' <param name="calculationId">The calculation Id</param>
        ''' <returns>The calculation Id with an optional suffix where there is an H2O override</returns>
        Protected Function GetCalculationIdWithOptionalSuffix(ByVal calculationId As String) As String
            Return String.Format("{0}{1}", calculationId, IIf(ShouldAppendH2OOverrideToIdAndDescription, H2OOverride, String.Empty))
        End Function

        Public Overrides Sub Initialise(ByVal session As Types.ReportSession)
            MyBase.Initialise(session)
            CanLoadHistoricData = True
        End Sub

        Protected Overrides Sub SetupOperation()
            Dim modelData = Session.GetCacheBlockModel(GeometType).RetrieveData()
            Dim query As String = String.Format("ModelName = '{0}'", ModelName)

            If Not IncludeAllMaterialTypes Then
                query += " And IsHighGrade = 1"
            End If

            Dim calcResult = Types.CalculationResult.ToCalculationResult(modelData,
                Session.RequestParameter.StartDate, Session.RequestParameter.EndDate, Session.RequestParameter.DateBreakdown, query)

            Calculations.Add(New CalculationOperation(CalculationStep.Assign, calcResult))

        End Sub

        Public Overrides Function Calculate() As Types.CalculationResult
            Dim result = MyBase.Calculate()

            If H2OOverride = H2OOverideAsDropped Then
                For Each record In result
                    record.H2O = record.H2ODropped
                Next
            ElseIf H2OOverride = H2OOverideAsShipped Then
                For Each record In result
                    record.H2O = record.H2OShipped
                Next
            Else
                For Each record In result
                    If record.ProductSize.ToUpper <> "TOTAL" Then record.H2O = Nothing
                Next
            End If

            result.GeometType = GeometType

            ' If overriding and the description should be updated on the result..update it now
            ' NOTE: It is possible that the description will be further updated later in some cases
            If Not String.IsNullOrEmpty(H2OOverride) And ShouldAppendH2OOverrideToIdAndDescription Then
                result.ReplaceDescription(CalcId, String.Format("{0} {1}", Description, H2OOverride.Replace("As", " As ")))
            ElseIf GeometType = GeometTypeSelection.AsShipped Then
                result.TagId = result.TagId + "_AS"
            ElseIf GeometType = GeometTypeSelection.AsDropped Then
                ' AD is the default, so leave the tags as is...
            End If

            If GeometType = GeometTypeSelection.AsShipped Then
                result.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), True))
            End If

            Return result
        End Function

        Protected Overrides ReadOnly Property CalcId() As String
            Get

            End Get
        End Property

        Protected Overrides ReadOnly Property Description() As String
            Get

            End Get
        End Property
    End Class
End Namespace
