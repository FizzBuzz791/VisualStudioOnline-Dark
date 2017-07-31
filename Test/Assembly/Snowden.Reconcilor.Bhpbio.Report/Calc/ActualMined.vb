Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Calc
    Public NotInheritable Class ActualMined
        Inherits CalculationBasic

        Public Const CalculationId As String = "ActualMined"
        Public Const CalculationDescription As String = "Total Hauled 'H' Value"

        Protected Overrides ReadOnly Property CalcId() As String
            Get
                Return CalculationId
            End Get
        End Property

        Protected Overrides ReadOnly Property Description() As String
            Get
                Return CalculationDescription
            End Get
        End Property

        Protected Overrides ReadOnly Property GetCache() As Cache.DataCache
            Get
                Return Session.GetCacheActualMined()
            End Get
        End Property

        Protected Sub SetPresentation()
            Dim validLocationType As String = "PIT"
            Dim locationTypeName As String = Report.Data.FactorLocation.GetLocationTypeName(Session.DalUtility, Session.RequestParameter.LocationId)
            Dim valid As Boolean = Report.Data.FactorLocation.IsLocationInLocationType(Session, Session.RequestParameter.LocationId, validLocationType)

            For Each calcResult In Result.GetAllCalculations()
                calcResult.Tags.Add(New CalculationResultTag("PresentationValid", GetType(Boolean), valid))
            Next
        End Sub

        Protected Overrides Sub ProcessTags()
            SetPresentation()
        End Sub

        Public Overrides Function Calculate() As Types.CalculationResult
            Dim result = MyBase.Calculate()
            Dim gradeControlCalc As Calc.ModelGradeControl = DirectCast(Calculation.Create(CalcType.ModelGradeControl, Session), Calc.ModelGradeControl)
            gradeControlCalc.IncludeAllMaterialTypes = True
            Dim gradeControlResult As CalculationResult = gradeControlCalc.Calculate()

            ' for actual mined, we have to calculate the density based off the volume from grade control... 
            For Each currentRecord In result
                Dim volume As Double? = gradeControlResult.GetCorrespondingRecord(currentRecord).Select(Function(r) r.Volume).FirstOrDefault()

                ' its likely that volume is Nothing here, but thats ok. We want to overwrite any existing values that somehow
                ' got in with the Nothing if thats the case. Any math operations including Nothing will return Nothing (as long
                ' as the types are Nullable?)
                '
                ' Note that density is calculated as Volume / Tonnes (m3/t) it has to be this way so that it aggregates properly
                ' later on, when the data is displayed, the value is inverted to the more traditional units
                currentRecord.Volume = volume
                currentRecord.CalculateDensity()
            Next

            Return result
        End Function
    End Class

    Public Module CalculationResultExtensions
        <Runtime.CompilerServices.Extension()> _
        Public Function GetCorrespondingRecord(ByRef result As Types.CalculationResult, ByVal record As CalculationResultRecord) As IEnumerable(Of CalculationResultRecord)
            Return result.Where(Function(r) _
                                    r.DateFrom = record.DateFrom AndAlso _
                                    r.ProductSize = record.ProductSize AndAlso _
                                    Nullable.Equals(r.MaterialTypeId, record.MaterialTypeId) AndAlso _
                                    (Nullable.Equals(r.LocationId, record.LocationId) OrElse record.LocationId Is Nothing) _
                                )
        End Function
    End Module
End Namespace
