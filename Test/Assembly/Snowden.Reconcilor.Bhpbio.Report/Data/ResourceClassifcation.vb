Imports Snowden.Reconcilor.Bhpbio.Report.ReportDefinitions

Namespace Data
    Public NotInheritable Class ResourceClassifcation
        Public Shared Property ResourceClassificationFields() As String() = New String() {
                "ResourceClassification1",
                "ResourceClassification2",
                "ResourceClassification3",
                "ResourceClassification4",
                "ResourceClassification5",
                "ResourceClassificationUnknown"
            }


        Public Shared ReadOnly Property ResourceClassificationDescriptions() As List(Of String)
            Get
                Return ResourceClassificationFields.Select(Function(r) F1F2F3ReportEngine.GetResourceClassificationDescription(r, "F1Factor")).ToList
            End Get
        End Property
    End Class
End Namespace
