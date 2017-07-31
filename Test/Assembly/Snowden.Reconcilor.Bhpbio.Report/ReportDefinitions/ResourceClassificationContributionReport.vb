Imports Snowden.Reconcilor.Bhpbio.Report.Types
Imports System.Text

Namespace ReportDefinitions
    Public Class ResourceClassificationContributionReport
        Inherits F1F2F3ReconciliationByAttributeReport

        Private _calcIds As Dictionary(Of String, Calc.CalcType) = Nothing

        Public Property IncludeChildLocations() As Boolean
        Public Property SingleSource() As String = Nothing

        Public Overrides Function GetCustomCalculationSet(ByVal session As Types.ReportSession,
            ByVal locationId As Int32, ByVal startDate As DateTime, ByVal endDate As DateTime,
            Optional ByVal includeChildLocations As Boolean = False) As CalculationSet

            If SingleSource Is Nothing Then
                ' if we are not getting the child locations, then return null and run the default
                ' calc set method. This can only occur when the normal shipping targets report is
                ' run, and this report can contain mulitple factors/calculations
                Return Nothing
            End If

            Dim holdingData As New CalculationSet()

            ' Always get raw data monthly, even if then aggregating to a higher level
            Dim dateBreakdown As Types.ReportBreakdown = ReportBreakdown.Monthly
            session.CalculationParameters(startDate, endDate, dateBreakdown, locationId, includeChildLocations)
            session.UseHistorical = True

            ' F1 is relevant for Resource Classification reporting
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.F1, session).Calculate())

            ' always need the GC + MM model for the context bars and the F1
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGradeControl, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelMining, session).Calculate())

            ' F1.5 is relevant for Resource Classification reporting
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelShortTermGeology, session).Calculate())
            holdingData.Add(Calc.Calculation.Create(Calc.CalcType.ModelGradeControlSTGM, session).Calculate())

            Return holdingData

        End Function

        Public Overrides Sub AddErrorContributionToResults(ByRef table As DataTable, ByVal parentLocationId As Integer)
            ErrorContributionEngine.AddErrorContributionByResourceClassification(table)
        End Sub

    End Class
End Namespace
