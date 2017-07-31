Imports Snowden.Common.Web.BaseHtmlControls
Imports Snowden.Reconcilor.Core.WebDevelopment
Imports Snowden.Common.Database.DataAccessBaseObjects


Namespace Utilities
    Public Class ReferenceMaterialHierarchyList
        Inherits Reconcilor.Core.Website.Utilities.ReferenceMaterialHierarchyList

        Protected Overrides Sub RunAjax()
            MyBase.RunAjax()
            MaterialTree.Columns.Add("Location_Description_CSV", New ReconcilorControls.ReconcilorTreeViewTableColumn("Attached Locations", 100, ReconcilorControls.ReconcilorTreeViewTableColumn.Alignment.Center))
        End Sub
    End Class
End Namespace