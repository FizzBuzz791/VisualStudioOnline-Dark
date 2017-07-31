''' <summary>
''' Represents a data combination of interest for reporting
''' </summary>
Public Structure CombinationOfInterest

    Private ReadOnly _calculationId As String
    Private ReadOnly _locationId As Integer
    Private ReadOnly _analyte As String
    Private ReadOnly _periodStart As DateTime


    Public ReadOnly Property CalculationId As String
        Get
            Return _calculationId
        End Get
    End Property

    Public ReadOnly Property LocationId As Integer
        Get
            Return _locationId
        End Get
    End Property
    Public ReadOnly Property Analyte As String
        Get
            Return _analyte
        End Get
    End Property

    Public ReadOnly Property PeriodStart As DateTime
        Get
            Return _periodStart
        End Get
    End Property

    ''' <summary>
    ''' Constructs a combination of interest given the attribute values that make up the combination
    ''' </summary>
    ''' <param name="calculationId">Identifies the calculation of interest</param>
    ''' <param name="locationId">Identifies the location of interest</param>
    ''' <param name="analyte">Identifies the analyte of interest</param>
    ''' <param name="periodStart">The period that forms part of the combination of interest</param>
    Sub New(ByVal calculationId As String, ByVal locationId As Integer, ByVal analyte As String, ByVal periodStart As DateTime)
        _calculationId = calculationId
        _locationId = locationId
        _analyte = analyte
        _periodStart = periodStart
    End Sub
End Structure
