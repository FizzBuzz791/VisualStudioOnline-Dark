Namespace Types

    ''' <summary>
    ''' A Reporting Context type
    ''' </summary>
    ''' <remarks>
    ''' Note that this is used to drive report behaviour so that reports include data appropriate for the context.
    ''' e.g When reporting in preparation for approvals, it is neccessary to include Live and Approved summary data
    ''' </remarks>
    Public Enum ReportContext

        ''' <summary>
        ''' A standard reporting context
        ''' </summary>
        ''' <remarks>typically approved summary data is used as the source for reporting display</remarks>
        Standard = 0

        ''' <summary>
        ''' A reporting context specifically for approvals viewing
        ''' </summary>
        ''' <remarks>This context requires a mix of live and approved summary data</remarks>
        ApprovalListing = 1

        ''' <summary>
        ''' A Reporting Context that uses live data only
        ''' </summary>
        ''' <remarks></remarks>
        LiveOnly = 2

    End Enum

End Namespace
