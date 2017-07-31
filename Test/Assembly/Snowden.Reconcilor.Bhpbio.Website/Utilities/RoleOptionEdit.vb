Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports System.Web.UI

Namespace Utilities
    Public Class RoleOptionEdit
        Inherits Snowden.Reconcilor.Core.Website.Utilities.RoleOptionEdit

        Protected Overrides Function GetDescription(ByVal optionDescription As String) As String
            Dim newDescription As String = String.Copy(optionDescription)

            'Approval
            newDescription = ReplaceTerminology(optionDescription, "Approval", "Approvals")

            'Approved
            newDescription = ReplaceTerminology(optionDescription, "Approved", "Approved")

            'Assigned
            newDescription = ReplaceTerminology(optionDescription, "Assigned", "Assigned")

            'Assignment
            newDescription = ReplaceTerminology(optionDescription, "Assignment", "Assignments")

            'Color
            newDescription = ReplaceTerminology(optionDescription, "Color", "Colors")

            'Depletion
            newDescription = ReplaceTerminology(newDescription, "Depletion", "Depletions")

            'Digblock
            newDescription = ReplaceTerminology(newDescription, "Digblock", "Digblocks")

            'Grade
            newDescription = ReplaceTerminology(newDescription, "Grade", "Grades")

            'Grade Control
            newDescription = ReplaceTerminology(newDescription, "Grade Control", "Grade Control")

            'Haulage
            newDescription = ReplaceTerminology(newDescription, "Haulage", "Haulage")

            'Hauled
            newDescription = ReplaceTerminology(newDescription, "Hauled", "Hauled")

            'Material Type
            newDescription = ReplaceTerminology(newDescription, "Material Type", "Material Type")

            'Mining
            newDescription = ReplaceTerminology(newDescription, "Mining", "Mining")

            'Not Approved
            newDescription = ReplaceTerminology(newDescription, "Not Approved", "Not Approved")

            'Reassigned
            newDescription = ReplaceTerminology(newDescription, "Reassigned", "Reassigned")

            'Reassignment
            newDescription = ReplaceTerminology(newDescription, "Reassignment", "Reassignment")

            'Scheduled
            newDescription = ReplaceTerminology(newDescription, "Scheduled", "Scheduled")

            'Stockpile
            newDescription = ReplaceTerminology(newDescription, "Stockpile", "Stockpiles")

            'Survey
            newDescription = ReplaceTerminology(newDescription, "Survey", "Surveys")

            Return newDescription
        End Function

        Private Function ReplaceTerminology(ByVal description As String, ByVal terminologyId As String, ByVal terminologyPlural As String) As String
            Dim replacedDesc As String = description

            If (description.Contains(terminologyPlural)) Then
                replacedDesc = description.Replace(terminologyPlural, ReconcilorFunctions.GetSiteTerminologyPlural(terminologyId))
            ElseIf (description.Contains(terminologyPlural.ToLower)) Then
                replacedDesc = description.Replace(terminologyPlural.ToLower, ReconcilorFunctions.GetSiteTerminologyPlural(terminologyId).ToLower)
            ElseIf (description.Contains(terminologyId)) Then
                replacedDesc = description.Replace(terminologyId, ReconcilorFunctions.GetSiteTerminology(terminologyId))
            ElseIf (description.Contains(terminologyId.ToLower)) Then
                replacedDesc = description.Replace(terminologyId.ToLower, ReconcilorFunctions.GetSiteTerminology(terminologyId).ToLower)
            End If

            Return replacedDesc
        End Function
    End Class

End Namespace
