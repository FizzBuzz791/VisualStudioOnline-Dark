Imports System.Text
Imports Snowden.Reconcilor.Bhpbio.Report.Types

Namespace Cache

    Public Class BlockModel
        Inherits Cache.DataCache

        Public Property GeometType As GeometTypeSelection

        Public ReadOnly Property GeometTypeString As String
            Get
                Select Case GeometType
                    Case GeometTypeSelection.AsDropped : Return "As-Dropped"
                    Case GeometTypeSelection.AsShipped : Return "As-Shipped"
                    Case Else : Throw New ArgumentException("Unknown GeometType " + GeometType.ToString)
                End Select
            End Get
        End Property

        Public Sub New(ByVal session As Types.ReportSession, geometType As GeometTypeSelection)
            MyBase.New(session)
            Me.GeometType = geometType
        End Sub

        Protected Overrides Function AcquireFromDatabase(ByVal startDate As Date,
         ByVal endDate As Date, ByVal dateBreakdownText As String, ByVal locationId As Integer,
         ByVal childLocations As Boolean) As System.Data.DataSet

            Dim modelNameList As String = Nothing

            If Session.ThrowTestExceptionInDAL Then
                Throw New Exception("Test ReportSession DAL Exception (Turn this off by setting Session.ThrowTestExceptionInDAL to False)")
            End If

            If Session.ShouldIncludeApprovedData And Session.ForwardModelFactorCalculation Then
                Throw New Exception("The ForwardModelFactorCalculation flag is only valid when querying for LIVE only data")
            End If

            ' When this is not set, we will just return all models, and then pull them from the cache when each
            ' calculation class needs them. However in certain situations (such as when getting the Resclass data), 
            ' this is very slow, so we only want to get exactly those models that are required. The model names are 
            ' put in the RequiredModelList in this situation.
            If (Not Session.RequiredModelList Is Nothing AndAlso Session.RequiredModelList.Count > 0) Then
                modelNameList = String.Join(",", Session.RequiredModelList.ToArray)
            End If

            If Session.GetModelDesignDataByBlockoutDate Then
                ' there are some reports where we want to run all the F1, F1.5 calculations etc, but using the design model
                ' data, filtered by the blockout date (this is used by the Reconciliation Reisk Blockout summary report, for
                ' example), setting the GetModelDataByBlockoutDate flag will do that. It calls a different proc that returns
                ' the data in the same format. 
                '
                ' This will produce nonsense results if it is used to get data above the F1 or F1.5 level
                Return Session.DalReport.GetBhpbioReportDataBlockModelBlockOuts(startDate, endDate, locationId, childLocations, Session.OverrideModelDataLocationTypeBreakdown)
            Else
                Dim dataOptions = New Database.SqlDal.ReportDataBlockModelOptions() With {
                    .HighGradeOnly = False,
                    .IncludeLumpAndFines = Session.IncludeProductSizeBreakdown,
                    .IncludeResourceClassification = Session.IncludeResourceClassification,
                    .OverrideChildLocationType = Session.OverrideModelDataLocationTypeBreakdown,
                    .UseRemainingMaterialAtDateFrom = Session.ForwardModelFactorCalculation,
                    .GeometType = GeometTypeString
                    }

                Return Session.DalReport.GetBhpbioReportDataBlockModel(startDate, endDate,
                     dateBreakdownText, locationId, childLocations, Session.IncludeModelDataForInactiveLocations, modelNameList,
                     Session.ShouldIncludeLiveData, Session.ShouldIncludeApprovedData, dataOptions)
            End If


        End Function
    End Class

End Namespace
