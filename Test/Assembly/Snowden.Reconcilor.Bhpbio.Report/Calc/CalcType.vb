Namespace Calc

    Public Enum CalcType
        BeneProduct
        BeneRatio
        <System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", MessageId:="ExPit")> ExPitToOreStockpile
        F0
        F05
        F1
        F15
        F2
        F25
        F3
        F2Density
        HubPostCrusherStockpileDelta
        ActualMined
        MineProductionActuals
        MineProductionExpitEquivalent
        MiningModelCrusherEquivalent
        MiningModelShippingEquivalent
        MiningModelOreForRailEquivalent
        ModelGeology
        ModelShortTermGeology
        ModelGradeControl
        ModelGradeControlSTGM
        ModelMining
        ModelMiningBene ' note this is not actually a separate class, we use it for getting the Bene adjusted MM
        PortBlendedAdjustment
        PortOreShipped
        PortStockpileDelta
        PostCrusherStockpileDelta
        RFGM
        RFMM
        RFSTM
        SitePostCrusherStockpileDelta
        StockpileToCrusher
        OreForRail
        DirectFeed
        RecoveryFactorMoisture
        RecoveryFactorDensity
    End Enum



End Namespace