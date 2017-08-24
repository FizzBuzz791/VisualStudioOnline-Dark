var blockModelsId = "BlockModels";
var locationIdField = "LocationId";
var locationTypeDescField = "LocationTypeDescription";
var locationTypeMinField = "LocationTypeMin";
var locationTypeMinActualsField = "LocationTypeMinActuals";
var locationTypeMaxField = "LocationTypeMax";
var locationTypeValidListField = "LocationValidTypesList";
var locationTypeValidActualsListField = "LocationValidTypesActualsList";
var sourceActualsField = "chkSource_MineProductionActuals";
var factorPrefix = "chkFactor_";
var attributePrefix = "chkAttribute_";
var sourcePrefix = "chkSource_";
var gradePrefix = "chkGrade_";
var productPrefix = "chkProduct_";
var productTypePrefix = "chkProductType_";
var lumpFinesBreakdown = "chkLump_Fines";
var locationBreakdownField = "LocationBreakdown";
var factorField = "Factor";
var includeResourceClassificationField = "includeResourceClassification";


function GetStockpileListByLocation() {

    var locationControl = document.getElementById(locationIdField);
    var isVisible = document.getElementById("iIs_Visible");

    ClearElement('stockpileListDiv');
    CallAjax('stockpileListDiv', './GetStockpilesByLocation.aspx?StockpileId=iStockpile_Id&LocationId=' + locationControl.value + '&IsVisible=' + isVisible.checked, 'image');

    return false;
}

function BhpbioRunReport(reportId) {
    CallAjax('validateInfo', './ReportValidate.aspx?ReportId=' + reportId);
    return false;

    // document.getElementById('ReportForm').action = 'ReportsRun.aspx?ReportId=' + reportId;
}

function BhpbioValidateReportLocationAndDateOnly() {
    var locationID = document.getElementById(locationIdField);
    var datebreakdown = GetDateBreakdown();

    if ((locationID == null) || (locationID.value == '') || (locationID.value == '-1')) {
        alert('Please select a Location');
        return false;
    } else if (!ValidateDateRange(datebreakdown, { validateAll: true })) {
        // dont set the error message - ValidateDateRange shows its own alert
        return false;
    }

    return true;
}

function BhpbioValidateStockpileBalanceReport(systemStartDate) {
    var success = true;

    var startDateText = document.getElementsByName("StartDateText").item(0).value;
    var endDateText = document.getElementsByName("EndDateText").item(0).value;

    if (!ValidateCoreReportDates(startDateText, endDateText, systemStartDate)) {
        success = false;
    }
    return success;
}

function BhpbioValidateHaulageVsPlantReport(systemStartDate, longRunningWarning) {
    var success = true;
    
    var locationID = document.getElementById(locationIdField).value;
    var startDateElement = document.getElementsByName("iStartDateText").item(0) || document.getElementById("StartDayText");
    var endDateElement = document.getElementsByName("iEndDateText").item(0) || document.getElementById("EndDayText");
    var startDateText = startDateElement.value;
    var endDateText = endDateElement.value;
    var validateLocationId = null;

    if (longRunningWarning === true) {
        validateLocationId = locationID;
    }

    if (!ValidateCoreReportDates(startDateText, endDateText, systemStartDate, validateLocationId)) {
        success = false;
    }

    return success;
}

function ValidateCoreReportDates(startDate, endDate, systemStartDate, locationId) {
    locationId = locationId || -1;

    var success = true;
    var currentDate = getCurrentDate();

    var startDateStr = startDate.toString();
    var startDateArray = startDateStr.split('-');
    startDateStr = new Date(startDateArray[2], GetMonthFromString(startDateArray[1]), startDateArray[0]);

    var endDateStr = endDate.toString();
    var endDateArray = endDateStr.split('-');
    endDateStr = new Date(endDateArray[2], GetMonthFromString(endDateArray[1]), endDateArray[0]);

    systemStartDate = new Date(systemStartDate);

    var dateValid = (function (d) { return d && d.getTime && !isNaN(d.getTime()); });

    if (!dateValid(startDateStr) || !dateValid(endDateStr)) {
        alert('Selected Start or End Date is invalid');
        success = false;
    } else if (startDateStr > endDateStr) {
        alert('Selected Start Date is greater than Selected End Date');
        success = false;
    } else if (startDateStr < systemStartDate) {
        alert('Selected Start Date is before than System Start Date');
        success = false;
    } else if (endDateStr < systemStartDate) {
        alert('Selected End Date is before than System Start Date');
        success = false;
    } else if (startDateStr > currentDate) {
        alert('Selected Start Date is after the Current Date');
        success = false;
    } else if (endDateStr > currentDate) {
        alert('Selected End Date is after the Current Date');
        success = false;
    }
    
    if (success) {
        success = ShowLongRunningWarning();
    }

    return success;
}

function BhpbioValidateSupplyChainMonitoringReport(systemStartDate) {

    var success = BhpbioValidateErrorDistributionReport(systemStartDate);

    if (success) {
        // either the show grades or show metals units checkbox needs to be selected
        somethingSelected = false;
        showMetalUnitsInput = document.getElementById('ShowMetalUnits')
        showGradesInput = document.getElementById('ShowGrades')

        if (showMetalUnitsInput && showMetalUnitsInput.checked) {
            somethingSelected = true;
        }

        if (showGradesInput && showGradesInput.checked) {
            somethingSelected = true;
        }

        if (somethingSelected == false) {
            alert('Either Grades or Metal Units must be selected');
            success = false;
        }
    }


    if (success == true) {
        if (!ValidateReconciliationDateFrom(GetDateBreakdown(), systemStartDate, '')) {
            success = false;
        }
    }

    if (success == true) {
        if (!ValidateDateTo(GetDateBreakdown(), systemStartDate, '')) {
            success = false;
        }
    }

    return success;
}

function BhpbioValidateErrorDistributionByLocationReport(systemStartDate) {
    var success = BhpbioValidateErrorDistributionReport(systemStartDate);

    if (success) {
        // cannot compare the same model against itself
        if (document.getElementById('BlockModelId1') && document.getElementById('BlockModelId2') &&
                document.getElementById('BlockModelId1').value == document.getElementById('BlockModelId2').value) {

            alert('Model One and Model Two cannot be the same - Cannot compare a Model against itself');
            success = false;
        }
    }

    return success;
}

function BhpbioValidateErrorDistributionRangeReport(systemStartDate) {
    var success = BhpbioValidateErrorDistributionReport(systemStartDate);

    if (success) {
        // cannot compare the same model against itself
        if (HasCheckBoxes(sourcePrefix) && document.getElementById('BlockModelId1')) {

            var controlModelId = document.getElementById('BlockModelId1').value;
            var sourceIds = GetCheckBoxSelectionValues(sourcePrefix);

            if (sourceIds && sourceIds.length == 1 && controlModelId == sourceIds[0]) {
                alert('Cannot select Control Model as the only source - cannot compare a model against itself');
                success = false;
            }
        }
    }

    return success;
}


function GetDateBreakdown() {
    var datebreakdown = document.getElementById("DateBreakdown");

    if (!datebreakdown) {
        datebreakdown = document.getElementById("nonParameterDateBreakdown");
    }

    if (datebreakdown) {
        return datebreakdown.options[datebreakdown.selectedIndex].value;
    } else {
        return 'MONTH';
    }
}

function BhpbioValidateErrorDistributionReport(systemStartDate) {
    var success = true;
    var error = null;
    var locationID = "";
    var productInput = document.getElementById('ProductTypeId');
    var productTypeId = null;

    if (productInput) {
        productTypeId = productInput.value;
    }

    if (document.getElementById(locationIdField) != null) {
        locationID = document.getElementById(locationIdField).value;
        if ((locationID == '') || (locationID == '-1')) {
            error = 'Please select a Location';
        }
    }

    var datebreakdown = GetDateBreakdown();

    if (HasCheckBoxes(sourcePrefix) && !EnsureAtleastOneCheckboxIsSelected(sourcePrefix)) {
        error = 'Please select at least one Source';
    } else if (HasCheckBoxes(attributePrefix) && !EnsureAtleastOneCheckboxIsSelected(attributePrefix)) {
        error = 'Please select at least one Attribute';
    } else if (HasCheckBoxes(productPrefix) && !EnsureAtleastOneCheckboxIsSelected(productPrefix)) {
        error = 'Please select at least one Product';
    } else if (HasCheckBoxes(productTypePrefix) && !EnsureAtleastOneCheckboxIsSelected(productTypePrefix)) {
        error = 'Please select at least one Product Type';
    } else if (productInput && (productTypeId == '' || productTypeId == '-1')) {
        alert('Please select a Product Type');
        success = false;
    } else if (!ValidateDateRange(datebreakdown)) {
        // dont set the error message - ValidateDateRange shows its own alert
        success = false;
    } else {
        // only check minimum tonnes if it exists
        if (document.getElementById('MinimumTonnes')) {
            error = ValidateNumericField('MinimumTonnes', true);
        }
    }

    if (error) {
        alert(error);
        success = false;
    }

    if (success == true) {
        var benchFilter = document.getElementById('BenchFilter');
        var onlyGraphs = document.getElementById('OnlyGraphs');
        if (benchFilter && benchFilter.value == 'ALL' && onlyGraphs && !onlyGraphs.checked) {
            success = confirm('You have opted to display all Benches in the supporting table. This might make the report very big. Continue?')
        }
    }

    return success;
}

function BhpbioValidateQuarterlyReconciliationReport(reportLocationType, reportName) {
    var success = true;
    var error = null;
    var isCompanyOrHub = false;

    var elements = reportLocationType.toLowerCase().split(",");

    if (elements.length == 2) {
        if (elements.indexOf('hub') > -1 &&
            elements.indexOf('company')) {
            isCompanyOrHub = true;
        }
    }

    var locationID = document.getElementById(locationIdField).value;
    var datebreakdown = 'QUARTER';

    if (reportName == 'BhpbioMonthlySiteReconciliationReport') {
        datebreakdown = 'MONTH'
    }

    var selectedLocationType = document.getElementById('LocationTypeDescriptionDynamic').value;

    if (!ValidateDateRange(datebreakdown, { validateAll: true })) {
        // dont set the error message - ValidateDateRange shows its own alert
        return false;
    }

    if ((locationID == '') || (locationID == '-1')) {
        error = 'Please select a Location.';
    }

    if (isCompanyOrHub) {
        if (!(selectedLocationType.toLowerCase() == 'hub' || selectedLocationType.toLowerCase() == 'company')) {
            error = 'You must select a Hub or Company location for this report.';
        }
    }
    else {
        if (reportLocationType.toLowerCase() == 'hub' && selectedLocationType.toLowerCase() != 'hub') {
            error = 'You must select a Hub location for this report.';
        }
        else if (reportLocationType.toLowerCase() != 'hub' && reportLocationType.toLowerCase() != selectedLocationType.toLowerCase()) {
            error = 'You must select a ' + reportLocationType + ' location for this report.';
        }
    }

    if (error) {
        alert(error);
        success = false;
    }

    return success;
}

// looks for the field in the form. returns an error message
function ValidateNumericField(parameterName, mustBePositive) {
    if (document.getElementById(parameterName)) {
        var v = document.getElementById(parameterName).value;

        if (v.length > 0) {
            v = parseInt(v, 10);

            if (isNaN(v)) {
                return parameterName + ' must be numeric';
            } else if (mustBePositive == true && v < 0) {
                return parameterName + ' cannot be negative';
            }
        } else {
            return parameterName + ' must have a value'
        }
    }

    return null;
}


function BhpbioValidateYearlyReconciliationReport(systemStartDate) {
    var datebreakdown = GetDateBreakdown();

    var datebreakdown = document.getElementById("DateBreakdown");
    if (!datebreakdown)
        datebreakdown = document.getElementById("nonParameterDateBreakdown");

    var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;

    success = true;

    if (!ValidateDateFrom(dateBreakdownValue, systemStartDate)) {
        success = false;
    } else if (!ValidateDateTo(dateBreakdownValue, systemStartDate)) {
        success = false;
    } else if (!ValidateDateRange(dateBreakdownValue)) {
        success = false;
    }

    return success;
}

function BhpbioValidateReport(locationList, actualsList, minLocation, maxLocation, minLocationActuals, systemStartDate) {

    var success = true;
    var locationID = document.getElementById(locationIdField).value;

    var sourceValid = EnsureAtleastOneCheckboxIsSelected(sourcePrefix);
    var attributeValid = EnsureAtleastOneCheckboxIsSelected(gradePrefix);

    var locationTypeDesc = document.getElementById(locationTypeDescField).value;
    var actualsSelected = document.getElementById("chkSource_MineProductionActuals").checked;
    var isActuals = document.getElementById(sourceActualsField).checked;

    var datebreakdown = document.getElementById("DateBreakdown");
    if (!datebreakdown)
        datebreakdown = document.getElementById("nonParameterDateBreakdown");

    var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;

    if ((locationID == '') || (locationID == '-1')) {
        alert('Please select a Location');
        success = false;
    } else if (!BhpbioValidateLocationType(locationIdField, isActuals)) {
        success = false;
    } else if (!sourceValid) {
        alert('Please select at least one Source');
        success = false;
    } else if (!attributeValid) {
        alert('Please select at least one Attribute');
        success = false;
    } else if (!ValidateDateFrom(dateBreakdownValue, systemStartDate)) {
        success = false;
    } else if (!ValidateDateTo(dateBreakdownValue, systemStartDate)) {
        success = false;
    } else if (!ValidateDateRange(dateBreakdownValue)) {
        success = false;
    }

    return success;

}

function FilterContextForFactorType() {
    var factorName = $('input[name=SingleSource]:checked').val();

    $('input[name^=chkContext_]').each(function (k, v) {
        var name = v.name.replace("chkContext_", "");

        if (((factorName == 'F1Factor' || factorName == 'F15Factor') && (name == 'HaulageContext' || name === "SampleCoverage" || name === "SampleRatio"))
            || (factorName === "F3Factor" && (name === "SampleCoverage" || name === "SampleRatio"))) {
            $('#' + name).hide();
            $('#' + name).find("input").removeAttr('checked');
        } else {
            $('#' + name).show();
        }
    });
};

function FilterSourceForFactorContextReport() {
    var locationTypeName = document.getElementById(locationTypeDescField).value;

    FilterSourceForLocation(function (calcId, locationTypeName) {
        if (locationTypeName.toUpperCase() == "COMPANY") {
            return true;
        } else if (locationTypeName.toUpperCase() == "HUB") {
            return true;
        } else if (locationTypeName.toUpperCase() == "SITE") {
            return calcId == "F1Factor" || calcId == "F15Factor" || calcId == "F2Factor";
        } else if (locationTypeName.toUpperCase() == "PIT") {
            return calcId == "F1Factor" || calcId == "F15Factor";
        } else {
            return calcId == "F1Factor" || calcId == "F15Factor";
        }
    });
}

function FilterSourceForLocation(fnValidForLocationType) {
    var sourceIndex;

    var sources = document.getElementsByName("SingleSource");
    var locationTypeDesc = document.getElementById(locationTypeDescField).value;

    for (sourceIndex = 0; sourceIndex < sources.length; sourceIndex++) {
        if (sources[sourceIndex].value != null) {
            var source = sources[sourceIndex];
            source.disabled = !fnValidForLocationType(source.value, locationTypeDesc);

            if (source.disabled == true) {
                // uncheck disabled radio button so user cannot run report on disabled source and hide parent table datacell
                source.checked = false
                source.parentNode.style.display = 'none'
            } else {
                source.parentNode.style.display = 'inline'
            }
        }
    }
}

/* FilterSourceForLocationOnF1F2F3ComparisonReport is used to disable options in the SingleSource RadioButtonList
based on the LocationType (Company, Hub or Site). The business rules for which options are unavailable are evident
in the ShouldSourceBeDisabledForLocationType function used here. BW. */
function FilterSourceForLocationOnF1F2F3ComparisonReport() {
    var sourceIndex;

    var sources = document.getElementsByName("SingleSource");
    var locationTypeDesc = document.getElementById(locationTypeDescField).value;

    for (sourceIndex = 0; sourceIndex < sources.length; sourceIndex++) {
        if (sources[sourceIndex].value != null) {
            var source = sources[sourceIndex]
            source.disabled = (ShouldSourceBeDisabledForLocationType(source.value, locationTypeDesc));
            if (source.disabled == true) {
                // uncheck disabled radio button so user cannot run report on disabled source and hide parent table datacell
                source.checked = false
                source.parentNode.style.display = 'none'
            } else {
                source.parentNode.style.display = 'inline'
            }
        }
    }
}

/* Used by FilterSourceForLocationOnF1F2F3ComparisonReport to determine whether the option in the Source RadioButtonList
should be disabled. */
function ShouldSourceBeDisabledForLocationType(sourceName, locationType) {
    switch (locationType) {
        case "Hub":
            switch (sourceName) {
                case "OreForRail":
                case "MiningModelOreForRailEquivalent":
                case "OreShipped":
                case "MiningModelShippingEquivalent":
                case "F3Factor": return true; break;
            }
            break;
        case "Site":
            switch (sourceName) {
                case "MineProductionExpitEqulivent":
                case "OreShipped":
                case "OreForRail":
                case "MiningModelOreForRailEquivalent":
                case "MiningModelShippingEquivalent":
                case "F2Factor":
                case "F25Factor":
                case "F3Factor": return true; break;
            }
            break;
    }

    return false;
}

function HideF3FactoronMonth() {
    var F3Factor = document.getElementById("F3Factor");
    var MiningModelShippingEquivalent = document.getElementById("MiningModelShippingEquivalent");
    var datebreakdown = document.getElementById("DateBreakdown");
    var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;
    var canShowF3 = (dateBreakdownValue == 'QUARTER');

    // this is the forward error report - we never show the F3 here
    if ($('#ReportForm').attr('action').indexOf('ReportId=54') > -1) {
        canShowF3 = false;
    }

    if (canShowF3) {
        if (F3Factor) {
            F3Factor.style.display = "inline";
        }

        if (MiningModelShippingEquivalent != null) {
            MiningModelShippingEquivalent.style.display = "inline";
        }
    } else {
        if (F3Factor) {
            F3Factor.style.display = "none";
        }

        if (MiningModelShippingEquivalent != null) {
            MiningModelShippingEquivalent.style.display = "none";
        }
    }
}

function ValidateFactorAnalysisContextReport() {
    var result = true;
    var attributeSelectionIsValid = EnsureAtleastOneCheckboxIsSelected(attributePrefix);
    var monthSelectionIsValid = BhpbioValidateReportLocationAndDateOnly();
    var contextSelectionIsValid = EnsureContextSelectionIsValid()

    if (!attributeSelectionIsValid) {
        alert('Please select at least one Attribute');
        result = false;
    } else if (!monthSelectionIsValid) {
        result = false;
    } else if (!contextSelectionIsValid) {
        alert("Please ensure Tonnes/Sample is selected in isolation");
        result = false;
    }

    return result;
}

function EnsureContextSelectionIsValid() {
    // Context selection is valid only if Tonnes/Sample is selected in isolation (or not selected at all)
    var contextSelectionIsValid = false;

    var tonnesPerSampleIsSelected = $("#chkContext_SampleRatio").is(":checked");
    if (tonnesPerSampleIsSelected) {
        $('input[name^=chkContext_]').each(function(k, v) {
            if (v.name !== "chkContext_SampleRatio") {
                contextSelectionIsValid = !($("#" + v.name).is(":checked"));
            }
        });
    } else {
        contextSelectionIsValid = true;
    }

    return contextSelectionIsValid;
}

function ValidateBhpbioFactorsVsTimeResourceClassificationReport()
{
    var result = false;
    if (BhpbioValidateReportLocationAndDateOnly()) {
        if (IsSingleSourceSelected) {
            if (EnsureAtleastOneCheckboxIsSelected(attributePrefix)) {
                if (ValidateResourceClassification()) {
                    result = true;
                }
                else {
                    alert('Please select at least one Resource Classification')
                }
            }
            else {
                alert('Please select at least one Attribute');
            }
        }
    }

    return result;
}

function ValidateErrorContributionReport() {
    var result = false;
    var LocationBreakdown = document.getElementById("LocationBreakdown");
    var Location = document.getElementById("LocationTypeDescription");
    var factorValid = EnsureAtleastOneCheckboxIsSelected(factorPrefix);
    var attributeValid = EnsureAtleastOneCheckboxIsSelected(attributePrefix);
    var validateMonth = BhpbioValidateReportLocationAndDateOnly();

    if (!attributeValid) {
        alert('Please select at least one Attribute');
        result = false;
    } else if (!factorValid) {
        alert('Please select at least one Factor');
        result = false;
    } else {
        if (validateMonth) {
            var selectedindex = 1;

            switch (Location.value) {
                case "Hub":
                    selectedindex = 2;
                    break;
                case "Site":
                    selectedindex = 3;
                    break;
                case "Pit":
                    selectedindex = 4;
                    break;
                case "Bench":
                    selectedindex = 5;
                    break;
            }

            if (LocationBreakdown.value <= selectedindex) {
                alert("The selected Location does not correspond to the selected Location Breakdown");
            } else {
                result = true;
            }
        }
    }

    if (result) {
        result = ShowLongRunningWarning();
    }

    return result;
}

function ShowLongRunningWarning(options) {
    options = options || {};

    var result = true;
    var showWarning = false;
    var locationId = document.getElementById(locationIdField).value;
    var locationType = $('#LocationTypeDescriptionDynamic').val();
    var locationBreakdown = $('#LocationBreakdown').val();
    var blastLocationTypeId = 6

    // show a warning if the report duration is very long, and it is being
    // run at the top level
    if (locationId > 0) {
        var hour = 1000 * 3600;
        var day = hour * 24;

        var warningDurationMs = options.warnDuration || (day * 180); // 6 months
        if (locationId == 1 && GetDateTimeSpan() > warningDurationMs) {
            showWarning = true;
        }
    }

    if ((locationType == 'Site' || locationType == 'Hub' || locationType == 'Company') && locationBreakdown >= blastLocationTypeId) {
        showWarning = true;
    }

    if (showWarning) {
        result = confirm('This report may take a long time to run with these parameters. Continue?');
    }

    return result;
}

// gets the duration in ms between the start and the end dates
function GetDateTimeSpan() {
    return GetBhpbioEndDate() - GetBhpbioStartDate();
}

function HideProdReconAttributeMonth() {
    var F3Factor = document.getElementById("F3Factor");
    var MiningModelCrusherEquivalent = document.getElementById("MiningModelCrusherEquivalent");
    var SitePostCrusherStockpileDelta = document.getElementById("SitePostCrusherStockpileDelta");
    var HubPostCrusherStockpileDelta = document.getElementById("HubPostCrusherStockpileDelta");
    var PostCrusherStockpileDelta = document.getElementById("PostCrusherStockpileDelta");
    var PortStockpileDelta = document.getElementById("PortStockpileDelta");
    var OreShipped = document.getElementById("OreShipped");
    var MiningModelShippingEquivalent = document.getElementById("MiningModelShippingEquivalent");
    var F25Factor = document.getElementById("F25Factor");
    var MiningModelOreForRailEquivalent = document.getElementById("MiningModelOreForRailEquivalent");

    var datebreakdown = document.getElementById("DateBreakdown");
    var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;

    if (dateBreakdownValue == 'QUARTER') {
        if (F3Factor) {
            F3Factor.style.display = "inline";
        }

        if (MiningModelCrusherEquivalent) {
            MiningModelCrusherEquivalent.style.display = "inline";
        }

        if (SitePostCrusherStockpileDelta) {
            SitePostCrusherStockpileDelta.style.display = "inline";
        }

        if (HubPostCrusherStockpileDelta) {
            HubPostCrusherStockpileDelta.style.display = "inline";
        }

        if (PostCrusherStockpileDelta) {
            PostCrusherStockpileDelta.style.display = "inline";
        }

        if (PortStockpileDelta) {
            PortStockpileDelta.style.display = "inline";
        }

        if (OreShipped) {
            OreShipped.style.display = "inline";
        }

        if (MiningModelShippingEquivalent) {
            MiningModelShippingEquivalent.style.display = "inline";
        }

        if (F25Factor) {
            F25Factor.style.display = "inline";
        }

        if (MiningModelOreForRailEquivalent) {
            MiningModelOreForRailEquivalent.style.display = "inline";
        }
    } else if (dateBreakdownValue == 'MONTH') {
        if (F3Factor) {
            F3Factor.style.display = "none";
        }

        if (MiningModelCrusherEquivalent) {
            MiningModelCrusherEquivalent.style.display = "none";
        }

        if (SitePostCrusherStockpileDelta) {
            SitePostCrusherStockpileDelta.style.display = "none";
        }

        if (HubPostCrusherStockpileDelta) {
            HubPostCrusherStockpileDelta.style.display = "none";
        }

        if (PostCrusherStockpileDelta) {
            PostCrusherStockpileDelta.style.display = "none";
        }

        if (PortStockpileDelta) {
            PortStockpileDelta.style.display = "none";
        }

        if (OreShipped) {
            OreShipped.style.display = "none";
        }

        if (MiningModelShippingEquivalent) {
            MiningModelShippingEquivalent.style.display = "none";
        }

        if (F25Factor) {
            F25Factor.style.display = "none";
        }

        if (MiningModelOreForRailEquivalent) {
            MiningModelOreForRailEquivalent.style.display = "none";
        }
    }
}

function HideF3FactoronMonthRadio() {
    var dateBreakdownValue = document.getElementById("DateBreakdown").value;
    var singleSource = document.getElementById("SingleSource");

    if (!singleSource) {
        return;
    }

    var labels = singleSource.getElementsByTagName('LABEL');
    var hiddenList = ["F3Factor",
        "MiningModelCrusherEquivalent",
        "SitePostCrusherStockpileDelta",
        "HubPostCrusherStockpileDelta",
        "PostCrusherStockpileDelta",
        "PortStockpileDelta",
        "OreShipped",
        "MiningModelShippingEquivalent",
        "F25Factor",
        "MiningModelOreForRailEquivalent"];

    for (var i = 0; i < labels.length; i++) {
        var label = labels[i];
        if (!label || !label.htmlFor) {
            continue;
        }

        var radioButton = document.getElementById(labels[i].htmlFor);

        if (!radioButton) {
            continue;
        }

        var calcId = radioButton.value;

        if (dateBreakdownValue == 'QUARTER') {
            label.style.display = 'inline';
            radioButton.style.display = 'inline';
        } else if (dateBreakdownValue == 'MONTH' && hiddenList.indexOf(calcId) != -1) {
            label.style.display = 'none';
            radioButton.style.display = 'none';
        }

    }

}


function BhpbioValidateLumpDates(lumpDates) {
    var datebreakdown = document.getElementById("DateBreakdown");
    
    if (!datebreakdown) {
        datebreakdown = document.getElementById("nonParameterDateBreakdown");
    }

    lumpDates = new Date(lumpDates);
    var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;
    var selectedmonth;
    var selectedyear;
    var dateSelected;
    var dateFromMonthPicker;
    var dateFromYearPicker;


    if (dateBreakdownValue == 'QUARTER') {
        dateFromMonthPicker = document.getElementById("dateFromQuarterSelect") || document.getElementById("QuarterSelectStartAndEnd");
        dateFromYearPicker = document.getElementById("dateFromYearSelect") || document.getElementById("YearSelectStartAndEnd");
        if (dateFromMonthPicker != null && dateFromYearPicker != null) {
            var quarterValue = dateFromMonthPicker.options[dateFromMonthPicker.selectedIndex].value;
            var yearValue = dateFromYearPicker.options[dateFromYearPicker.selectedIndex].value;

            selectedmonth = resolveQuarter(quarterValue);
            selectedyear = yearValue;

            if (selectedmonth > 5)
                selectedyear = parseInt(yearValue) - 1;
            dateSelected = new Date(selectedyear, selectedmonth, 1);

        }
    }
    else if (dateBreakdownValue == 'MONTH') {
        dateFromMonthPicker = document.getElementById("MonthPickerMonthPartDateFrom");
        dateFromYearPicker = document.getElementById("MonthPickerYearPartDateFrom");

        if (dateFromMonthPicker == null && dateFromYearPicker == null) {
            dateFromMonthPicker = document.getElementById("MonthPickerMonthPartStartDate");
            dateFromYearPicker = document.getElementById("MonthPickerYearPartStartDate");
        }

        if (dateFromMonthPicker != null && dateFromYearPicker != null) {
            var monthValue = dateFromMonthPicker.options[dateFromMonthPicker.selectedIndex].value;
            var yearValue = dateFromYearPicker.options[dateFromYearPicker.selectedIndex].value;

            dateSelected = new Date(parseInt(yearValue), GetMonthFromString(monthValue), 1);
        }
    }

    if (dateSelected < lumpDates) {
        BhpbioDisplayLumpFinesDateValidationErrorMessage(lumpDates, "report");
        return false;
    }

    return true;
}

function BhpbioValidateProductSupplyChainMonitoringReport(lumpDates, systemStartDate) {
    var success = BhpbioValidateSupplyChainMonitoringReport(systemStartDate);

    if (success) {
        success = BhpbioValidateLumpDates(lumpDates);
    }

    return success;

}

function FormatFactorControlsForF1F2F3() {
    var datebreakdown = document.getElementById("DateBreakdown");
    var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;

    var locationID = document.getElementById("LocationIdDynamic")
    var locationText = locationID.options[locationID.selectedIndex].text;
    var locationValue = locationText.substring(0, locationText.indexOf(':'));

    var F1Factor = document.getElementById("F1Factor");
    var F15Factor = document.getElementById("F15Factor");
    var F2Factor = document.getElementById("F2Factor");
    var F25Factor = document.getElementById("F25Factor");
    var F3Factor = document.getElementById("F3Factor");




    if (locationValue == 'Company') {
        if (dateBreakdownValue == 'QUARTER') {

            F1Factor.style.display = "inline";
            F2Factor.style.display = "inline";
            F25Factor.style.display = "inline";
            F3Factor.style.display = "inline";
        }
        else if (dateBreakdownValue == 'MONTH') {

            F1Factor.style.display = "inline";
            F2Factor.style.display = "inline";
            F25Factor.style.display = "none";
            document.getElementById("chkFactor_F25Factor").checked = false;
            F3Factor.style.display = "none";
            document.getElementById("chkFactor_F3Factor").checked = false;
        }
    }
    else if (locationValue == 'Hub') {
        if (dateBreakdownValue == 'QUARTER') {


            F1Factor.style.display = "inline";
            F2Factor.style.display = "inline";
            F25Factor.style.display = "inline";
            F3Factor.style.display = "inline";
        }
        else if (dateBreakdownValue == 'MONTH') {

            F1Factor.style.display = "inline";
            F2Factor.style.display = "inline";
            F25Factor.style.display = "none";
            document.getElementById("chkFactor_F25Factor").checked = false;
            F3Factor.style.display = "none";
            document.getElementById("chkFactor_F3Factor").checked = false;
        }
    }
    else if (locationValue == 'Site') {

        F1Factor.style.display = "inline";
        F2Factor.style.display = "inline";
        F25Factor.style.display = "none";
        document.getElementById("chkFactor_F25Factor").checked = false;
        F3Factor.style.display = "none";
        document.getElementById("chkFactor_F3Factor").checked = false;
    }
    else if (locationValue == 'Pit') {

        F1Factor.style.display = "inline";
        F2Factor.style.display = "none";
        F25Factor.style.display = "none";
        F3Factor.style.display = "none";
        document.getElementById("chkFactor_F2Factor").checked = false;
        document.getElementById("chkFactor_F25Factor").checked = false;
        document.getElementById("chkFactor_F3Factor").checked = false;
    }
    else {

        F1Factor.style.display = "inline";
        F2Factor.style.display = "inline";
        F25Factor.style.display = "inline";
        F3Factor.style.display = "inline";
    }

    if (F15Factor) {
        // F1.5 is always going to be the same as the F1
        F15Factor.style.display = F1Factor.style.display;
    }

}


function FormatFactorControls() {

    var datebreakdown = document.getElementById("DateBreakdown");
    var locationBreakdown = document.getElementById("LocationBreakdown");

    if (!datebreakdown) {
        datebreakdown = document.getElementById("nonParameterDateBreakdown");
    }

    var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;

    var locationID = document.getElementById("LocationIdDynamic");
    var locationText = locationID.options[locationID.selectedIndex].text;
    var locationValue = locationText.substring(0, locationText.indexOf(':'));

    // on some reports we have a location breakdown selection - this should be used to determin which
    // factors are shown, instead of the location picker
    if (locationBreakdown) {
        if (!locationBreakdown.onchange) {
            locationBreakdown.onchange = FormatFactorControls;
        }

        locationValue = $(locationBreakdown).children('option:selected').html() || locationValue;

        // if the location select goes below Pit, then just use Pit to determine the visibilty rules
        if (locationValue == 'Bench' || locationValue == 'Blast' || locationValue == 'Block') {
            locationValue = 'Pit';
        }

        // for the forward error contribution report, we always want it to be stuck at the Pit
        // level - it is not possible to run it for F2 or above
        if ($('#ReportForm').attr('action').indexOf('ReportId=54') > -1) {
            locationValue = 'Pit'
        }
    }

    var ShortTermGeologyModel = document.getElementById("ShortTermGeologyModel");
    var GeologyModel = document.getElementById("GeologyModel");
    var MiningModel = document.getElementById("MiningModel");
    var GradeControlModel = document.getElementById("GradeControlModel");
    var MineProductionExpitEqulivent = document.getElementById("MineProductionExpitEqulivent");
    var MiningModelCrusherEquivalent = document.getElementById("MiningModelCrusherEquivalent");
    var PostCrusherStockpileDelta = document.getElementById("PostCrusherStockpileDelta");
    var HubPostCrusherStockpileDelta = document.getElementById("HubPostCrusherStockpileDelta");
    var SitePostCrusherStockpileDelta = document.getElementById("SitePostCrusherStockpileDelta");
    var OreForRail = document.getElementById("OreForRail");
    var MiningModelOreForRailEquivalent = document.getElementById("MiningModelOreForRailEquivalent");
    var PortStockpileDelta = document.getElementById("PortStockpileDelta");
    var OreShipped = document.getElementById("OreShipped");
    var MiningModelShippingEquivalent = document.getElementById("MiningModelShippingEquivalent");

    var F2DensityFactor = document.getElementById("F2DensityFactor");
    var RecoveryFactorDensity = document.getElementById("RecoveryFactorDensity");
    var RecoveryFactorMoisture = document.getElementById("RecoveryFactorMoisture");

    var F1Factor = document.getElementById("F1Factor");
    var F15Factor = document.getElementById("F15Factor");
    var F2Factor = document.getElementById("F2Factor");
    var F25Factor = document.getElementById("F25Factor");
    var F3Factor = document.getElementById("F3Factor");

    var Rfgm = document.getElementById("RFGM");
    var Rfmm = document.getElementById("RFMM");
    var Rfstm = document.getElementById("RFSTM");

    if (locationValue == 'Company') {
        if (dateBreakdownValue == 'QUARTER') {

            if (GeologyModel != null) {
                GeologyModel.style.display = "inline";
            }
            if (ShortTermGeologyModel != null) {
                ShortTermGeologyModel.style.display = "inline";
            }
            if (MiningModel != null) {
                MiningModel.style.display = "inline";
            }
            if (GradeControlModel != null) {
                GradeControlModel.style.display = "inline";
            }
            if (MineProductionExpitEqulivent != null) {
                MineProductionExpitEqulivent.style.display = "inline";
            }
            if (MiningModelCrusherEquivalent != null) {
                MiningModelCrusherEquivalent.style.display = "inline";
            }
            if (PostCrusherStockpileDelta != null) {
                PostCrusherStockpileDelta.style.display = "inline";
            }
            if (SitePostCrusherStockpileDelta != null) {
                SitePostCrusherStockpileDelta.style.display = "inline";
            }
            if (OreForRail != null) {
                OreForRail.style.display = "inline";
            }
            if (MiningModelOreForRailEquivalent != null) {
                MiningModelOreForRailEquivalent.style.display = "inline";
            }
            if (HubPostCrusherStockpileDelta != null) {
                HubPostCrusherStockpileDelta.style.display = "inline";
            }
            if (PortStockpileDelta != null) {
                PortStockpileDelta.style.display = "inline";
            }
            if (OreShipped != null) {
                OreShipped.style.display = "inline";
            }
            if (MiningModelShippingEquivalent != null) {
                MiningModelShippingEquivalent.style.display = "inline";
            }
            if (F2DensityFactor != null) {
                F2DensityFactor.style.display = "inline";
            }
            if (RecoveryFactorDensity != null) {
                RecoveryFactorDensity.style.display = "inline";
            }
            if (RecoveryFactorMoisture != null) {
                RecoveryFactorMoisture.style.display = "inline";
            }

            F1Factor.style.display = "inline";
            if (F2Factor != null) {
                F2Factor.style.display = "inline";
            }
            if (F25Factor != null) {
                F25Factor.style.display = "inline";
            }
            if (F3Factor != null) {
                F3Factor.style.display = "inline";
            }
        }
        else if (dateBreakdownValue == 'MONTH') {

            if (GeologyModel != null) {
                GeologyModel.style.display = "inline";
            }
            if (ShortTermGeologyModel != null) {
                ShortTermGeologyModel.style.display = "inline";
            }
            if (MiningModel != null) {
                MiningModel.style.display = "inline";
            }
            if (GradeControlModel != null) {
                GradeControlModel.style.display = "inline";
            }
            if (MineProductionExpitEqulivent != null) {
                MineProductionExpitEqulivent.style.display = "inline";
            }
            if (MiningModelCrusherEquivalent != null) {
                MiningModelCrusherEquivalent.style.display = "none";
                document.getElementById("chkFactor_MiningModelCrusherEquivalent").checked = false;
            }
            if (PostCrusherStockpileDelta != null) {
                PostCrusherStockpileDelta.style.display = "none";
                document.getElementById("chkFactor_PostCrusherStockpileDelta").checked = false;
            }
            if (SitePostCrusherStockpileDelta != null) {
                SitePostCrusherStockpileDelta.style.display = "none";
                document.getElementById("chkFactor_HubPostCrusherStockpileDelta").checked = false;
            }
            if (OreForRail != null) {
                OreForRail.style.display = "inline";
                document.getElementById("chkFactor_OreForRail").checked = false;
            }
            if (MiningModelOreForRailEquivalent != null) {
                MiningModelOreForRailEquivalent.style.display = "inline";
                document.getElementById("chkFactor_MiningModelOreForRailEquivalent").checked = false;
            }
            if (HubPostCrusherStockpileDelta != null) {
                HubPostCrusherStockpileDelta.style.display = "none";
                document.getElementById("chkFactor_SitePostCrusherStockpileDelta").checked = false;
            }
            if (PortStockpileDelta != null) {
                PortStockpileDelta.style.display = "none";
                document.getElementById("chkFactor_PortStockpileDelta").checked = false;
            }
            if (OreShipped != null) {
                OreShipped.style.display = "none";
                document.getElementById("chkFactor_OreShipped").checked = false;
            }
            if (MiningModelShippingEquivalent != null) {
                MiningModelShippingEquivalent.style.display = "none";
                document.getElementById("chkFactor_MiningModelShippingEquivalent").checked = false;
            }
            if (F2DensityFactor != null) {
                F2DensityFactor.style.display = "inline";
            }
            if (RecoveryFactorDensity != null) {
                RecoveryFactorDensity.style.display = "inline";
            }
            if (RecoveryFactorMoisture != null) {
                RecoveryFactorMoisture.style.display = "inline";
            }

            F1Factor.style.display = "inline";
            if (F2Factor != null) {
                F2Factor.style.display = "inline";
            }
            if (F25Factor != null) {
                F25Factor.style.display = "none";
                document.getElementById("chkFactor_F25Factor").checked = false;
            }
            if (F3Factor != null) {
                F3Factor.style.display = "none";
                document.getElementById("chkFactor_F3Factor").checked = false;
            }
        }

        if (Rfgm != null) {
            Rfgm.style.display = "inline";
        }

        if (Rfmm != null) {
            Rfmm.style.display = "inline";
        }

        if (Rfstm != null) {
            Rfstm.style.display = "inline";
        }
    }
    else if (locationValue == 'Hub') {
        if (dateBreakdownValue == 'QUARTER') {

            if (GeologyModel != null) {
                GeologyModel.style.display = "inline";
            }
            if (ShortTermGeologyModel != null) {
                ShortTermGeologyModel.style.display = "inline";
            }
            if (MiningModel != null) {
                MiningModel.style.display = "inline";
            }
            if (GradeControlModel != null) {
                GradeControlModel.style.display = "inline";
            }
            if (MineProductionExpitEqulivent != null) {
                MineProductionExpitEqulivent.style.display = "inline";
            }
            if (MiningModelCrusherEquivalent != null) {
                MiningModelCrusherEquivalent.style.display = "inline";
            }
            if (PostCrusherStockpileDelta != null) {
                PostCrusherStockpileDelta.style.display = "inline";
            }
            if (SitePostCrusherStockpileDelta != null) {
                SitePostCrusherStockpileDelta.style.display = "inline";
            }
            if (OreForRail != null) {
                OreForRail.style.display = "inline";
            }
            if (MiningModelOreForRailEquivalent != null) {
                MiningModelOreForRailEquivalent.style.display = "inline";
            }
            if (HubPostCrusherStockpileDelta != null) {
                HubPostCrusherStockpileDelta.style.display = "inline";
            }
            if (PortStockpileDelta != null) {
                PortStockpileDelta.style.display = "inline";
            }
            if (OreShipped != null) {
                OreShipped.style.display = "inline";
            }
            if (MiningModelShippingEquivalent != null) {
                MiningModelShippingEquivalent.style.display = "inline";
            }
            if (F2DensityFactor != null) {
                F2DensityFactor.style.display = "inline";
            }
            if (RecoveryFactorDensity != null) {
                RecoveryFactorDensity.style.display = "inline";
            }
            if (RecoveryFactorMoisture != null) {
                RecoveryFactorMoisture.style.display = "inline";
            }

            F1Factor.style.display = "inline";
            if (F2Factor != null) {
                F2Factor.style.display = "inline";
            }
            if (F25Factor != null) {
                F25Factor.style.display = "inline";
            }
            if (F3Factor != null) {
                F3Factor.style.display = "inline";
            }
        }
        else if (dateBreakdownValue == 'MONTH') {

            if (GeologyModel != null) {
                GeologyModel.style.display = "inline";
            }
            if (ShortTermGeologyModel != null) {
                ShortTermGeologyModel.style.display = "inline";
            }
            if (MiningModel != null) {
                MiningModel.style.display = "inline";
            }
            if (GradeControlModel != null) {
                GradeControlModel.style.display = "inline";
            }
            if (MineProductionExpitEqulivent != null) {
                MineProductionExpitEqulivent.style.display = "inline";
            }
            if (MiningModelCrusherEquivalent != null) {
                MiningModelCrusherEquivalent.style.display = "none";
                document.getElementById("chkFactor_MiningModelCrusherEquivalent").checked = false;
            }
            if (PostCrusherStockpileDelta != null) {
                PostCrusherStockpileDelta.style.display = "none";
                document.getElementById("chkFactor_PostCrusherStockpileDelta").checked = false;
            }
            if (SitePostCrusherStockpileDelta != null) {
                SitePostCrusherStockpileDelta.style.display = "none";
                document.getElementById("chkFactor_HubPostCrusherStockpileDelta").checked = false;
            }
            if (OreForRail != null) {
                OreForRail.style.display = "inline";
                document.getElementById("chkFactor_OreForRail").checked = false;
            }
            if (MiningModelOreForRailEquivalent != null) {
                MiningModelOreForRailEquivalent.style.display = "inline";
                document.getElementById("chkFactor_MiningModelOreForRailEquivalent").checked = false;
            }
            if (HubPostCrusherStockpileDelta != null) {
                HubPostCrusherStockpileDelta.style.display = "none";
                document.getElementById("chkFactor_SitePostCrusherStockpileDelta").checked = false;
            }
            if (PortStockpileDelta != null) {
                PortStockpileDelta.style.display = "none";
                document.getElementById("chkFactor_PortStockpileDelta").checked = false;
            }
            if (OreShipped != null) {
                OreShipped.style.display = "none";
                document.getElementById("chkFactor_OreShipped").checked = false;
            }
            if (MiningModelShippingEquivalent != null) {
                MiningModelShippingEquivalent.style.display = "none";
                document.getElementById("chkFactor_MiningModelShippingEquivalent").checked = false;
            }
            if (F2DensityFactor != null) {
                F2DensityFactor.style.display = "inline";
            }
            if (RecoveryFactorDensity != null) {
                RecoveryFactorDensity.style.display = "inline";
            }
            if (RecoveryFactorMoisture != null) {
                RecoveryFactorMoisture.style.display = "inline";
            }

            F1Factor.style.display = "inline";
            if (F2Factor != null) {
                F2Factor.style.display = "inline";
            }
            if (F25Factor != null) {
                F25Factor.style.display = "none";
                document.getElementById("chkFactor_F25Factor").checked = false;
            }
            if (F3Factor != null) {
                F3Factor.style.display = "none";
                document.getElementById("chkFactor_F3Factor").checked = false;
            }
        }

        if (Rfgm != null) {
            Rfgm.style.display = "inline";
        }

        if (Rfmm != null) {
            Rfmm.style.display = "inline";
        }

        if (Rfstm != null) {
            Rfstm.style.display = "inline";
        }
    }
    else if (locationValue == 'Site') {

        if (GeologyModel != null) {
            GeologyModel.style.display = "inline";
        }
        if (ShortTermGeologyModel != null) {
            ShortTermGeologyModel.style.display = "inline";
        }
        if (MiningModel != null) {
            MiningModel.style.display = "inline";
        }
        if (GradeControlModel != null) {
            GradeControlModel.style.display = "inline";
        }
        if (MineProductionExpitEqulivent != null) {
            MineProductionExpitEqulivent.style.display = "inline";
        }
        if (MiningModelCrusherEquivalent != null) {
            MiningModelCrusherEquivalent.style.display = "none";
            document.getElementById("chkFactor_MiningModelCrusherEquivalent").checked = false;
        }
        if (PostCrusherStockpileDelta != null) {
            PostCrusherStockpileDelta.style.display = "none";
            document.getElementById("chkFactor_PostCrusherStockpileDelta").checked = false;
        }
        if (SitePostCrusherStockpileDelta != null) {
            SitePostCrusherStockpileDelta.style.display = "none";
            document.getElementById("chkFactor_HubPostCrusherStockpileDelta").checked = false;
        }
        if (OreForRail != null) {
            OreForRail.style.display = "none";
            document.getElementById("chkFactor_OreForRail").checked = false;
        }
        if (MiningModelOreForRailEquivalent != null) {
            MiningModelOreForRailEquivalent.style.display = "none";
            document.getElementById("chkFactor_MiningModelOreForRailEquivalent").checked = false;
        }
        if (HubPostCrusherStockpileDelta != null) {
            HubPostCrusherStockpileDelta.style.display = "none";
            document.getElementById("chkFactor_SitePostCrusherStockpileDelta").checked = false;
        }
        if (PortStockpileDelta != null) {
            PortStockpileDelta.style.display = "none";
            document.getElementById("chkFactor_PortStockpileDelta").checked = false;
        }
        if (OreShipped != null) {
            OreShipped.style.display = "none";
            document.getElementById("chkFactor_OreShipped").checked = false;
        }
        if (MiningModelShippingEquivalent != null) {
            MiningModelShippingEquivalent.style.display = "none";
            document.getElementById("chkFactor_MiningModelShippingEquivalent").checked = false;
        }
        if (F2DensityFactor != null) {
            F2DensityFactor.style.display = "inline";
        }
        if (RecoveryFactorDensity != null) {
            RecoveryFactorDensity.style.display = "inline";
        }
        if (RecoveryFactorMoisture != null) {
            RecoveryFactorMoisture.style.display = "inline";
        }

        F1Factor.style.display = "inline";
        if (F2Factor != null) {
            F2Factor.style.display = "inline";
        }
        if (F25Factor != null) {
            F25Factor.style.display = "none";
            document.getElementById("chkFactor_F25Factor").checked = false;
        }
        if (F3Factor != null) {
            F3Factor.style.display = "none";
            document.getElementById("chkFactor_F3Factor").checked = false;
        }

        if (Rfgm != null) {
            Rfgm.style.display = "inline";
        }

        if (Rfmm != null) {
            Rfmm.style.display = "inline";
        }

        if (Rfstm != null) {
            Rfstm.style.display = "inline";
        }
    }
    else if (locationValue == 'Pit') {

        if (GeologyModel != null) {
            GeologyModel.style.display = "inline";
        }
        if (ShortTermGeologyModel != null) {
            ShortTermGeologyModel.style.display = "inline";
        }
        if (MiningModel != null) {
            MiningModel.style.display = "inline";
        }
        if (GradeControlModel != null) {
            GradeControlModel.style.display = "inline";
        }
        if (MineProductionExpitEqulivent != null) {
            MineProductionExpitEqulivent.style.display = "none";
            document.getElementById("chkFactor_MineProductionExpitEqulivent").checked = false;
        }
        if (MiningModelCrusherEquivalent != null) {
            MiningModelCrusherEquivalent.style.display = "none";
            document.getElementById("chkFactor_MiningModelCrusherEquivalent").checked = false;
        }
        if (PostCrusherStockpileDelta != null) {
            PostCrusherStockpileDelta.style.display = "none";
            document.getElementById("chkFactor_PostCrusherStockpileDelta").checked = false;
        }
        if (SitePostCrusherStockpileDelta != null) {
            SitePostCrusherStockpileDelta.style.display = "none";
            document.getElementById("chkFactor_HubPostCrusherStockpileDelta").checked = false;
        }
        if (OreForRail != null) {
            OreForRail.style.display = "none";
            document.getElementById("chkFactor_OreForRail").checked = false;
        }
        if (MiningModelOreForRailEquivalent != null) {
            MiningModelOreForRailEquivalent.style.display = "none";
            document.getElementById("chkFactor_MiningModelOreForRailEquivalent").checked = false;
        }
        if (HubPostCrusherStockpileDelta != null) {
            HubPostCrusherStockpileDelta.style.display = "none";
            document.getElementById("chkFactor_SitePostCrusherStockpileDelta").checked = false;
        }
        if (PortStockpileDelta != null) {
            PortStockpileDelta.style.display = "none";
            document.getElementById("chkFactor_PortStockpileDelta").checked = false;
        }
        if (OreShipped != null) {
            OreShipped.style.display = "none";
            document.getElementById("chkFactor_OreShipped").checked = false;
        }
        if (MiningModelShippingEquivalent != null) {
            MiningModelShippingEquivalent.style.display = "none";
            document.getElementById("chkFactor_MiningModelShippingEquivalent").checked = false;
        }
        if (F2DensityFactor != null) {
            F2DensityFactor.style.display = "none";
            document.getElementById("chkFactor_F2DensityFactor").checked = false;
        }
        if (RecoveryFactorDensity != null) {
            RecoveryFactorDensity.style.display = "none";
            document.getElementById("chkFactor_RecoveryFactorDensity").checked = false;
        }
        if (RecoveryFactorMoisture != null) {
            RecoveryFactorMoisture.style.display = "none";
            document.getElementById("chkFactor_RecoveryFactorMoisture").checked = false;
        }

        F1Factor.style.display = "inline";
        if (F2Factor != null) {
            F2Factor.style.display = "none";
            document.getElementById("chkFactor_F2Factor").checked = false;
        }
        if (F25Factor != null) {
            F25Factor.style.display = "none";
            document.getElementById("chkFactor_F25Factor").checked = false;
        }
        if (F3Factor != null) {
            F3Factor.style.display = "none";
            document.getElementById("chkFactor_F3Factor").checked = false;
        }

        if (Rfgm != null) {
            Rfgm.style.display = "none";
            document.getElementById("chkFactor_RFGM").checked = false;
        }

        if (Rfmm != null) {
            Rfmm.style.display = "none";
            document.getElementById("chkFactor_RFMM").checked = false;
        }

        if (Rfstm != null) {
            Rfstm.style.display = "none";
            document.getElementById("chkFactor_RFSTM").checked = false;
        }
    }
    else {

        if (GeologyModel != null) {
            GeologyModel.style.display = "inline";
        }
        if (ShortTermGeologyModel != null) {
            ShortTermGeologyModel.style.display = "inline";
        }
        if (MiningModel != null) {
            MiningModel.style.display = "inline";
        }
        if (GradeControlModel != null) {
            GradeControlModel.style.display = "inline";
        }
        if (MineProductionExpitEqulivent != null) {
            MineProductionExpitEqulivent.style.display = "inline";
        }
        if (MiningModelCrusherEquivalent != null) {
            MiningModelCrusherEquivalent.style.display = "inline";
        }
        if (PostCrusherStockpileDelta != null) {
            PostCrusherStockpileDelta.style.display = "inline";
        }
        if (SitePostCrusherStockpileDelta != null) {
            SitePostCrusherStockpileDelta.style.display = "inline";
        }
        if (OreForRail != null) {
            OreForRail.style.display = "inline";
        }
        if (MiningModelOreForRailEquivalent != null) {
            MiningModelOreForRailEquivalent.style.display = "inline";
        }
        if (HubPostCrusherStockpileDelta != null) {
            HubPostCrusherStockpileDelta.style.display = "inline";
        }
        if (PortStockpileDelta != null) {
            PortStockpileDelta.style.display = "inline";
        }
        if (OreShipped != null) {
            OreShipped.style.display = "inline";
        }
        if (MiningModelShippingEquivalent != null) {
            MiningModelShippingEquivalent.style.display = "inline";
        }
        if (F2DensityFactor != null) {
            F2DensityFactor.style.display = "inline";
        }
        if (RecoveryFactorDensity != null) {
            RecoveryFactorDensity.style.display = "inline";
        }
        if (RecoveryFactorMoisture != null) {
            RecoveryFactorMoisture.style.display = "inline";
        }

        F1Factor.style.display = "inline";
        if (F2Factor != null) {
            F2Factor.style.display = "inline";
        }
        if (F25Factor != null) {
            F25Factor.style.display = "inline";
        }
        if (F3Factor != null) {
            F3Factor.style.display = "inline";
        }

        if (Rfgm != null) {
            Rfgm.style.display = "inline";
        }

        if (Rfmm != null) {
            Rfmm.style.display = "inline";
        }

        if (Rfstm != null) {
            Rfstm.style.display = "inline";
        }
    }

    if (F15Factor) {
        // F1.5 is always going to be the same as the F1
        F15Factor.style.display = F1Factor.style.display;
    }

}

function BhpbioValidateRecoveryAnalysisReport(systemStartDate) {
    var success = true;
    var locationID = document.getElementById(locationIdField).value;
    var sourceValid = EnsureAtleastOneCheckboxIsSelected(sourcePrefix);
    var isActuals = document.getElementById(sourceActualsField).checked;

    var datebreakdown = document.getElementById("DateBreakdown");
    if (!datebreakdown)
        datebreakdown = document.getElementById("nonParameterDateBreakdown");

    var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;

    if ((locationID == '') || (locationID == '-1')) {
        alert('Please select a Location');
        success = false;
    } else if (!BhpbioValidateLocationType(locationIdField, isActuals)) {
        success = false;
    } else if (!sourceValid) {
        alert('Please select at least one Source');
        success = false;
    } else if (!ValidateDateFrom(dateBreakdownValue, systemStartDate)) {
        success = false;
    } else if (!ValidateDateTo(dateBreakdownValue, systemStartDate)) {
        success = false;
    } else if (!ValidateDateRange(dateBreakdownValue)) {
        success = false;
    }

    return success;
}

function BhpbioValidateMovementRecoveryReport(systemStartDate) {
    var success = true;

    var locationID = document.getElementById(locationIdField).value;
    var isActuals = false;

    var datebreakdown = document.getElementById("DateBreakdown");
    if (!datebreakdown)
        datebreakdown = document.getElementById("nonParameterDateBreakdown");

    var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;

    if ((document.getElementById("Comparison1BlockModelId").value == "Actuals") || (document.getElementById("Comparison2BlockModelId").value == "Actuals")) {
        isActuals = true;
    }

    if ((locationID == '') || (locationID == '-1')) {
        alert('Please select a Location');
        success = false;
    } else if (!BhpbioValidateLocationType(locationIdField, isActuals)) {
        success = false;
    } else if (!ValidateDateFrom(dateBreakdownValue, systemStartDate)) {
        success = false;
    } else if (!ValidateDateTo(dateBreakdownValue, systemStartDate)) {
        success = false;
    } else if (!ValidateDateRange(dateBreakdownValue)) {
        success = false;
    }

    return success;
}


function BhpbioValidateLocationType(fieldName, isActuals) {
    var success = false;
    var validLocationsTypes;

    if (document.getElementById(fieldName) == null) {
        // if the location picker isn't present on the page, then just return
        // success for the location validation
        return true;
    }

    var minLocation = document.getElementById(locationTypeMinField).value;
    var maxLocation = document.getElementById(locationTypeMaxField).value;
    var locationTypeList = document.getElementById(locationTypeValidListField).value;
    var locationTypeDesc = document.getElementById(fieldName.replace('Id', 'TypeDescription')).value;

    if (isActuals) {
        minLocation = document.getElementById(locationTypeMinActualsField).value;
        locationTypeList = document.getElementById(locationTypeValidActualsListField).value;
    }

    if ((locationTypeList != null) && (locationTypeList != '')) {
        validLocationTypes = locationTypeList.split("|");

        for (var i = 0; i < validLocationTypes.length; i++) {
            if (locationTypeDesc == validLocationTypes[i]) {
                success = true;
            }
        }
    }
    else {
        success = true
    }

    if (!success) {
        if (minLocation == maxLocation) {
            alert('Please select a ' + minLocation + ' for the location');
        } else {
            if (isActuals) {
                alert('The Location cannot be set to a ' + locationTypeDesc + ' when the "Mine Production (Actuals)" option is selected. Please change the Location.');
            } else {
                alert('Please select a location between a ' + maxLocation + ' and a ' + minLocation);
            }

        }
    }

    return success;
}

function BhpbioValidateLocation(fieldName, checkActuals, systemStartDate) {
    var success = true;
    var isActuals = false;

    var datebreakdown = document.getElementById("DateBreakdown");
    if (!datebreakdown)
        datebreakdown = document.getElementById("nonParameterDateBreakdown");

    var locationID = document.getElementById(fieldName).value;

    if ((locationID == '') || (locationID == '-1')) {
        alert('Please select a Location');
        success = false;
    }
    else if (datebreakdown) {
        var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;

        if (!ValidateDateFrom(dateBreakdownValue, systemStartDate)) {
            success = false;
        } else if (!ValidateDateTo(dateBreakdownValue, systemStartDate)) {
            success = false;
        } else if (!ValidateDateRange(dateBreakdownValue)) {
            success = false;
        }
    }


    if (success) {
        if (checkActuals) {
            isActuals = document.getElementById(sourceActualsField).checked;
        }

        success = BhpbioValidateLocationType(fieldName, isActuals);
    }

    return success;
}

function BhpbioValidateHubReconciliationReportWithLumpFines(fieldName, checkActuals, historicalStartDate, systemStartDate, historicalAggregateStartDate, lumpFinesCutoverDate) {
    var success = BhpbioValidateHubReconciliationReport(fieldName, checkActuals, historicalStartDate, systemStartDate, historicalAggregateStartDate);

    if (success) {
        // a lump fines cutover date was defined.. the dates should be checked against it
        if (lumpFinesCutoverDate) {
            success = BhpbioValidateLumpDates(lumpFinesCutoverDate);
        }
    }

    return success;
}

function BhpbioValidateF1F2F3OverviewReconReport(fieldName, checkActuals, historicalStartDate, systemStartDate, historicalAggregateStartDate, lumpFinesCutoverDate) {
    var success = BhpbioValidateHubReconciliationReport(fieldName, checkActuals, historicalStartDate, systemStartDate, historicalAggregateStartDate);

    if (success) {
        // a lump fines cutover date was defined.. the dates should be checked against it
        if (lumpFinesCutoverDate) {
            success = BhpbioValidateLumpDates(lumpFinesCutoverDate);
        }
    }

    return success;
}

function BhpbioF1F2F3ProductReconContributionReport(lumpDates, fieldName, checkActuals, historicalStartDate, systemStartDate, historicalAggregateStartDate) {
    var success = BhpbioValidateLumpDates(lumpDates);

    if (success) {
        success = BhpbioValidateHubReconciliationReport(fieldName, checkActuals, historicalStartDate, systemStartDate, historicalAggregateStartDate);

    }
    return success;
}

function BhpbioValidateLiveVersusSummaryReport(fieldName, checkActuals, historicalStartDate, systemStartDate, historicalAggregateStartDate) {
    return BhpbioValidateHubReconciliationReport(fieldName, checkActuals, historicalStartDate, systemStartDate, historicalAggregateStartDate);
}

function BhpbioValidateHubReconciliationReport(fieldName, checkActuals, historicalStartDate, systemStartDate, historicalAggregateStartDate) {
    var success = true;
    var isActuals = false;
    var dateMonthComponent;
    var dateYearComponent;

    var dateFromMonthPicker;
    var dateFromYearPicker;
    var dateToMonthPicker;
    var dateToYearPicker;
    var validationStartDate = new Date();
    var validationDateMessage;
    var productInput = document.getElementById('ProductTypeId');
    var productTypeId = null;

    var datebreakdown = document.getElementById("DateBreakdown");
    if (!datebreakdown)
        datebreakdown = document.getElementById("nonParameterDateBreakdown");

    var locationInput = document.getElementById(fieldName);

    if (locationInput) {
        var locationID = locationInput.value;
        if ((locationID == '') || (locationID == '-1')) {
            alert('Please select a Location');
            success = false;
        }
    }

    if (productInput) {
        productTypeId = productInput.value;

        if (productInput && (productTypeId == '' || productTypeId == '-1')) {
            alert('Please select a Product Type');
            success = false;
        }
    } else if (HasCheckBoxes(productPrefix) && !EnsureAtleastOneCheckboxIsSelected(productPrefix)) {
        alert('Please select at least one Product Type');
        success = false;
    } else if (HasCheckBoxes(productTypePrefix) && !EnsureAtleastOneCheckboxIsSelected(productTypePrefix)) {
        alert('Please select at least one Product Type');
        success = false;
    }

    if (success && datebreakdown) {

        var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;

        if (dateBreakdownValue.toUpperCase() == "QUARTER" || dateBreakdownValue.toUpperCase() == "MONTH") {

            dateMonthComponent = document.getElementById("dateFromQuarterSelect");
            dateYearComponent = document.getElementById("dateFromYearSelect");
            dateFromMonthPicker = dateMonthComponent.options[dateMonthComponent.selectedIndex].value;
            dateFromYearPicker = dateYearComponent.options[dateYearComponent.selectedIndex].value;

            dateMonthComponent = document.getElementById("dateToQuarterSelect");
            dateYearComponent = document.getElementById("dateToYearSelect");
            dateToMonthPicker = dateMonthComponent.options[dateMonthComponent.selectedIndex].value;
            dateToYearPicker = dateYearComponent.options[dateYearComponent.selectedIndex].value;

            if ((dateFromMonthPicker == dateToMonthPicker) && (dateFromYearPicker == dateToYearPicker)) {
                validationStartDate = historicalStartDate;
                validationDateMessage = "Please Select Dates After: " + calMgr.scFormatDate(calMgr.getDateFromFormat(validationStartDate, "MM-dd-yyyy"), calMgr.defaultDateFormat) + " - the first available historical data";
            } else {
                validationStartDate = historicalAggregateStartDate;
                validationDateMessage = "Please Select Dates After: " + calMgr.scFormatDate(calMgr.getDateFromFormat(validationStartDate, "MM-dd-yyyy"), calMgr.defaultDateFormat) + " - the first available historical data available for aggregation";
            }

        } else {
            alert('Please select a Date Breakdown');
            success = false;
        }

        if (!ValidateReconciliationDateFrom(dateBreakdownValue, validationStartDate, validationDateMessage)) {
            success = false;
        } else if (!ValidateDateTo(dateBreakdownValue, validationStartDate)) {
            success = false;
        } else if (!ValidateDateRange(dateBreakdownValue)) {
            success = false;
        } else if (dateBreakdownValue.toUpperCase() == "MONTH" && !BhpbioValidateMonthlyReportingIsAfterSystemStart(systemStartDate)) {
            success = false;
        }
    }

    if (success) {
        if (checkActuals) {
            isActuals = document.getElementById(sourceActualsField).checked;
        }

        success = BhpbioValidateLocationType(fieldName, isActuals);
    }

    return success;
}

// searches the main page form for checkboxes starting with the
// passed in key. This is so we can find out if a given set of 
// checkboxes needs to be validated
function HasCheckBoxes(key) {
    var containsSelection = false;

    for (var i = 0; i < document.forms[0].elements.length; i++) {
        var e = document.forms[0].elements[i];

        if ((e.type == 'checkbox')) {
            if (e.name.search(key) != -1) {
                return true;
            }
        }
    }

    return false;
}

function GetCheckBoxSelectionValues(key) {

    var containsSelection = false;
    var selectedValues = [];

    for (var i = 0; i < document.forms[0].elements.length; i++) {
        var e = document.forms[0].elements[i];

        if (e.type == 'checkbox') {
            if (e.name.search(key) != -1) {
                if (key == factorPrefix) {
                    if (document.getElementById(e.name.replace(key, '')).style.display == "inline") {
                        if (e.checked == true) {
                            selectedValues.push(e.name.replace(key, ''));
                        }
                    }
                } else {
                    if (e.checked == true) {
                        selectedValues.push(e.name.replace(key, ''));
                    }
                }
            }
        }
    }

    return selectedValues;
}

function EnsureAtleastOneCheckboxIsSelected(key) {

    //alert(key);

    var containsSelection = false;

    for (var i = 0; i < document.forms[0].elements.length; i++) {
        var e = document.forms[0].elements[i];

        if ((e.type == 'checkbox')) {
            if (e.name.search(key) != -1) {
                if (key == factorPrefix) {
                    if (document.getElementById(e.name.replace(key, '')).style.display != 'none') {
                        if (e.checked == true)
                            containsSelection = true;
                    }
                }
                else {
                    if (e.checked == true)
                        containsSelection = true;
                }
            }
        }
    }

    return containsSelection;
}

function ValidateResourceClassification() {
    return EnsureAtleastOneCheckboxIsSelected("chkResourceClassifications_");
}

function BhpbioValidateF1F2F3ByAttributeReportWithLumpFines(historicalStartDate, systemStartDate, historicalAggregateStartDate, skipAttributeSelectionCheck, lumpFinesCutoverDate) {

    var success = BhpbioValidateF1F2F3ByAttributeReport(historicalStartDate, systemStartDate, historicalAggregateStartDate, skipAttributeSelectionCheck);

    if (success) {
        success = BhpbioValidateLumpDates(lumpFinesCutoverDate || "2014-09-01");
    }

    return success;
}

function BhpbioValidateF1F2F3GeometByAttributeReport(historicalStartDate, systemStartDate, historicalAggregateStartDate, skipAttributeSelectionCheck, lumpFinesCutoverDate) {

    var success = BhpbioValidateF1F2F3ByAttributeReport(historicalStartDate, systemStartDate, historicalAggregateStartDate, skipAttributeSelectionCheck);
    
    if (success) {
        success = BhpbioValidateLumpDates(lumpFinesCutoverDate || "2014-09-01");
    }

    return success;
}

function BhpbioValidateF1F2F3ByAttributeReport(historicalStartDate, systemStartDate, historicalAggregateStartDate, skipAttributeSelectionCheck, overrideFactorValidationMessage) {

    skipAttributeSelectionCheck = (skipAttributeSelectionCheck === true) ? true : false;
    var success = true;
    var locationInput = document.getElementById(locationIdField)
    var locationID = (locationInput || { value: null }).value;
    var adjustdate = new Date();
    var productInput = document.getElementById('ProductTypeId');
    var productTypeId = null;

    var factorValid = EnsureAtleastOneCheckboxIsSelected(factorPrefix);
    //alert(locationID);
    var attributeValid = skipAttributeSelectionCheck || EnsureAtleastOneCheckboxIsSelected(attributePrefix);
    var datebreakdown = document.getElementById("DateBreakdown");

    if (!datebreakdown)
        datebreakdown = document.getElementById("nonParameterDateBreakdown");

    if (productInput) {
        productTypeId = productInput.value;
    }

    var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;

    if ((locationID == '') || (locationID == '-1')) {
        alert('Please select a Location');
        success = false;
    } else if (HasCheckBoxes(productPrefix) && !EnsureAtleastOneCheckboxIsSelected(productPrefix)) {
        alert('Please select at least one Product');
        success = false;
    } else if (HasCheckBoxes(productTypePrefix) && !EnsureAtleastOneCheckboxIsSelected(productTypePrefix)) {
        alert('Please select at least one Product Type');
        success = false;
    } else if (!BhpbioValidateLocationType(locationIdField, false)) {
        success = false;
    } else if (!attributeValid) {
        alert('Please select at least one Attribute');
        success = false;
    } else if (HasCheckBoxes(factorPrefix) && !factorValid) {
        if (overrideFactorValidationMessage) {
            alert(overrideFactorValidationMessage);
        } else {
            alert('Please select at least one Factor');
        }
        success = false;
    } else if (HasCheckBoxes(sourcePrefix) && !EnsureAtleastOneCheckboxIsSelected(sourcePrefix)) {
        alert('Please select at least one source');
        success = false;
    } else if (productInput && (productTypeId == '' || productTypeId == '-1')) {
        alert('Please select a Product Type');
        success = false;
    } else {
        if (dateBreakdownValue.toUpperCase() == "QUARTER" || dateBreakdownValue.toUpperCase() == "MONTH") {

            dateMonthComponent = document.getElementById("dateFromQuarterSelect");
            dateYearComponent = document.getElementById("dateFromYearSelect");
            dateFromMonthPicker = dateMonthComponent.options[dateMonthComponent.selectedIndex].value;
            dateFromYearPicker = dateYearComponent.options[dateYearComponent.selectedIndex].value;

            dateMonthComponent = document.getElementById("dateToQuarterSelect");
            dateYearComponent = document.getElementById("dateToYearSelect");
            dateToMonthPicker = dateMonthComponent.options[dateMonthComponent.selectedIndex].value;
            dateToYearPicker = dateYearComponent.options[dateYearComponent.selectedIndex].value;

            if ((dateFromMonthPicker == dateToMonthPicker) && (dateFromYearPicker == dateToYearPicker)) {
                validationStartDate = historicalStartDate;
                validationDateMessage = "Please Select Dates After: " + calMgr.scFormatDate(calMgr.getDateFromFormat(validationStartDate, "MM-dd-yyyy"), calMgr.defaultDateFormat) + " - the first available historical data";
            } else {
                validationStartDate = historicalAggregateStartDate;
                validationDateMessage = "Please Select Dates After: " + calMgr.scFormatDate(calMgr.getDateFromFormat(validationStartDate, "MM-dd-yyyy"), calMgr.defaultDateFormat) + " - the first available historical data available for aggregation";
            }

        } else {
            alert('Please select a Date Breakdown');
            success = false;
        }

        if (!ValidateReconciliationDateFrom(dateBreakdownValue, validationStartDate, validationDateMessage)) {
            success = false;
        } else if (!ValidateDateTo(dateBreakdownValue, validationStartDate)) {
            success = false;
        } else if (!ValidateDateRange(dateBreakdownValue)) {
            success = false;
        } else if (dateBreakdownValue.toUpperCase() == "MONTH" && !BhpbioValidateMonthlyReportingIsAfterSystemStart(systemStartDate)) {
            success = false;
        }
    }
    return success;
}

function BhpbioValidateRiskProfileReport(systemStartDate) {
    var success = true;

    var locationID = document.getElementById(locationIdField).value;
    var includeResourceClassification = document.getElementById(includeResourceClassificationField).checked;
    var factor = document.getElementById(factorField).value;
    var locationBreakdown = document.getElementById(locationBreakdownField).value;
    var locationTypeDesc = document.getElementById(locationTypeDescField).value;

    var datebreakdown = document.getElementById("DateBreakdown");
    if (!datebreakdown)
        datebreakdown = document.getElementById("nonParameterDateBreakdown");

    var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;

    if ((locationID == '') || (locationID == '-1')) {
        alert('Please select a Location');
        success = false;
    } else if ((locationBreakdown == '') || (locationBreakdown == '-1')) {
        alert('Please select a location breakdown');
        success = false;
    } else if (!ValidateDateFrom(dateBreakdownValue, systemStartDate)) {
        success = false;
    } else if (factor == "F15" && includeResourceClassification) {
        alert("Including resource classification information in combination with F1.5f is not supported by this report.");
        success = false;
    }

    if (success) {
        var locationBreakdownInt = parseInt(locationBreakdown)
        var locationBreakdownMinValue = 1

        if (locationTypeDesc == "Hub") {
            locationBreakdownMinValue = 2
        } else if (locationTypeDesc == "Site") {
            locationBreakdownMinValue = 3
        } else if (locationTypeDesc == "Pit") {
            locationBreakdownMinValue = 4
        } else if (locationTypeDesc == "Bench") {
            locationBreakdownMinValue = 5
        } 

        if (locationBreakdownInt < locationBreakdownMinValue) {
            alert("The location breakdown selected is invalid for the selected location.");
            success = false;
        }
    }
    
    return success;
}

function BhpbioValidateProductFactorsByLocationAgainstShippingTargetsReport(historicalStartDate, systemStartDate, historicalAggregateStartDate, isFactorVsTime) {

    //isFactorVsTime = (isFactorVsTime === true) ? true : false;

    var success = true;
    var locationID = document.getElementById(locationIdField).value;

    var factorValid = EnsureAtleastOneCheckboxIsSelected(factorPrefix);
    var attributeValid = EnsureAtleastOneCheckboxIsSelected(attributePrefix); //isFactorVsTime || EnsureAtleastOneCheckboxIsSelected(attributePrefix);
    var productValid = EnsureAtleastOneCheckboxIsSelected(productPrefix);
    var datebreakdown = document.getElementById("DateBreakdown");

    if (!datebreakdown) {
        datebreakdown = document.getElementById("nonParameterDateBreakdown");
    }

    var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;

    if ((locationID == '') || (locationID == '-1')) {
        alert('Please select a Location');
        success = false;
    } else if (!BhpbioValidateLocationType(locationIdField, false)) {
        success = false;
    } else if (!productValid) {
        alert('Please select at least one Product');
        success = false;
    } else if (!attributeValid) {
        alert('Please select at least one Attribute');
        success = false;
    } else if (!factorValid) {
        alert('Please select at least one Factor');
        success = false;
    } else {
        if (dateBreakdownValue.toUpperCase() == "QUARTER" || dateBreakdownValue.toUpperCase() == "MONTH") {

            dateMonthComponent = document.getElementById("dateFromQuarterSelect");
            dateYearComponent = document.getElementById("dateFromYearSelect");
            dateFromMonthPicker = dateMonthComponent.options[dateMonthComponent.selectedIndex].value;
            dateFromYearPicker = dateYearComponent.options[dateYearComponent.selectedIndex].value;

            dateMonthComponent = document.getElementById("dateToQuarterSelect");
            dateYearComponent = document.getElementById("dateToYearSelect");
            dateToMonthPicker = dateMonthComponent.options[dateMonthComponent.selectedIndex].value;
            dateToYearPicker = dateYearComponent.options[dateYearComponent.selectedIndex].value;

            if ((dateFromMonthPicker == dateToMonthPicker) && (dateFromYearPicker == dateToYearPicker)) {
                validationStartDate = historicalStartDate;
                validationDateMessage = "Please Select Dates After: " + calMgr.scFormatDate(calMgr.getDateFromFormat(validationStartDate, "MM-dd-yyyy"), calMgr.defaultDateFormat) + " - the first available historical data";
            } else {
                validationStartDate = historicalAggregateStartDate;
                validationDateMessage = "Please Select Dates After: " + calMgr.scFormatDate(calMgr.getDateFromFormat(validationStartDate, "MM-dd-yyyy"), calMgr.defaultDateFormat) + " - the first available historical data available for aggregation";
            }

        } else {
            alert('Please select a Date Breakdown');
            success = false;
        }

        if (!ValidateReconciliationDateFrom(dateBreakdownValue, validationStartDate, validationDateMessage)) {
            success = false;
        } else if (!ValidateDateTo(dateBreakdownValue, validationStartDate)) {
            success = false;
        } else if (!ValidateDateRange(dateBreakdownValue)) {
            success = false;
        } else if (dateBreakdownValue.toUpperCase() == "MONTH" && !BhpbioValidateMonthlyReportingIsAfterSystemStart(systemStartDate)) {
            success = false;
        }
    }

    return success;
}

function CheckAllFactors(key, listId) {
    for (var i = 0; i < document.forms[0].elements.length; i++) {
        var e = document.forms[0].elements[i];

        if ((e.type == 'checkbox') && (e.name.indexOf(key) > -1)) {
            if (document.getElementById(e.name.replace('chkFactor_', '')).style.display != "none") {
                e.checked = true;
            }
        }
    }

    return false;
}

function UncheckAllFactors(key, listId) {
    for (var i = 0; i < document.forms[0].elements.length; i++) {
        var e = document.forms[0].elements[i];

        if ((e.type == 'checkbox') && (e.name.indexOf(key) > -1)) {
            if (document.getElementById(e.name.replace('chkFactor_', '')).style.display != "none") {
                e.checked = false;
            }
        }
    }

    return false;
}


function CheckAll(key, listId) {
    for (var i = 0; i < document.forms[0].elements.length; i++) {
        var e = document.forms[0].elements[i];

        if ((e.type == 'checkbox') && (e.name.indexOf(key) > -1))
            e.checked = true;
    }

    return false;
}

function UncheckAll(key, listId) {
    for (var i = 0; i < document.forms[0].elements.length; i++) {
        var e = document.forms[0].elements[i];

        if ((e.type == 'checkbox') && (e.name.indexOf(key) > -1))
            e.checked = false;
    }

    return false;
}

// Resolve Quarter Operations

function resolveQuarter(quarter) {
    var month;
    if (quarter == 'Q1')
        month = 6;
    else if (quarter == 'Q2')
        month = 9
    else if (quarter == 'Q3')
        month = 0;
    else if (quarter == 'Q4')
        month = 3

    return month;
}

function GetLastMonthOfQuarter(month) {
    var endMonth;
    switch (month) {
        case 0:
        case 1:
        case 2: endMonth = 3; break;
        case 3:
        case 4:
        case 5: endMonth = 6; break;
        case 6:
        case 7:
        case 8: endMonth = 9; break;
        case 9:
        case 10:
        case 11: endMonth = 12; break;
    }

    return endMonth;
}

function GetFirstMonthOfQuarter(month) {
    var startMonth;
    switch (month) {
        case 0:
        case 1:
        case 2: startMonth = 0; break;
        case 3:
        case 4:
        case 5: startMonth = 3; break;
        case 6:
        case 7:
        case 8: startMonth = 6; break;
        case 9:
        case 10:
        case 11: startMonth = 9; break;
    }

    return startMonth;
}

function getCurrentDate() {
    var currentTime = new Date();
    var currentDay = currentTime.getDate();
    var currentMonth = currentTime.getMonth();
    var currentYear = currentTime.getFullYear();
    var currentDate = new Date(currentYear, currentMonth, currentDay);

    return currentDate;
}

function ShowDateValidationAlert(dateSelected, systemDate, currentDate, dateType) {
    var success = true;

    if (dateSelected < systemDate) {
        alert('Selected Date ' + dateType + ' is before System Start Date');
        success = false;
    }
    else if (dateSelected > currentDate) {
        alert('Selected Date ' + dateType + ' is after Current Quarter');
        success = false;
    }

    return success;
}

function GetQuarterStartDate(dateToConvert) {
    var startDateOfQuarter = new Date(dateToConvert);
    var startMonth = GetFirstMonthOfQuarter(startDateOfQuarter.getMonth());

    startDateOfQuarter = new Date(startDateOfQuarter.getFullYear(), startMonth, 1);

    return startDateOfQuarter;
}

function GetQuarterEndDate(dateToConvert) {
    var endDateOfQuarter = new Date(dateToConvert);
    var endMonth = GetLastMonthOfQuarter(endDateOfQuarter.getMonth());

    endDateOfQuarter = new Date(endDateOfQuarter.getFullYear(), endMonth, 0);

    return endDateOfQuarter;
}

function GetMonthFromString(monthAsString) {
    var month;
    switch (monthAsString) {
        case "Jan": month = 0; break;
        case "Feb": month = 1; break;
        case "Mar": month = 2; break;
        case "Apr": month = 3; break;
        case "May": month = 4; break;
        case "Jun": month = 5; break;
        case "Jul": month = 6; break;
        case "Aug": month = 7; break;
        case "Sep": month = 8; break;
        case "Oct": month = 9; break;
        case "Nov": month = 10; break;
        case "Dec": month = 11; break;
    }

    return month;
}

function ValidateDateFrom(dateBreakdown, systemStartDate) {
    var success;
    var dateType = "From";
    var selectedmonth;
    var selectedyear;
    var dateSelected;

    var dateFromMonthPicker;
    var dateFromYearPicker;

    var currentDate = getCurrentDate();
    var parsedSystemDate = new Date(systemStartDate);

    if (dateBreakdown == 'QUARTER') {
        dateFromMonthPicker = document.getElementById("dateFromQuarterSelect") || document.getElementById("QuarterSelectStartAndEnd");
        dateFromYearPicker = document.getElementById("dateFromYearSelect") || document.getElementById("YearSelectStartAndEnd");

        if (dateFromMonthPicker != null && dateFromYearPicker != null) {

            var quarterValue = dateFromMonthPicker.options[dateFromMonthPicker.selectedIndex].value;
            var yearValue = dateFromYearPicker.options[dateFromYearPicker.selectedIndex].value;

            selectedmonth = resolveQuarter(quarterValue);
            selectedyear = yearValue;

            if (selectedmonth > 5)
                selectedyear = parseInt(yearValue) - 1;

            dateSelected = new Date(selectedyear, selectedmonth, 1);
            currentDate = GetQuarterStartDate(currentDate);
            parsedSystemDate = GetQuarterStartDate(parsedSystemDate);
        }
    }
    else if (dateBreakdown == 'MONTH') {
        dateFromMonthPicker = document.getElementById("MonthPickerMonthPartDateFrom");
        dateFromYearPicker = document.getElementById("MonthPickerYearPartDateFrom");

        if (dateFromMonthPicker == null && dateFromYearPicker == null) {
            dateFromMonthPicker = document.getElementById("MonthPickerMonthPartStartDate");
            dateFromYearPicker = document.getElementById("MonthPickerYearPartStartDate");
        }

        if (dateFromMonthPicker != null && dateFromYearPicker != null) {
            var monthValue = dateFromMonthPicker.options[dateFromMonthPicker.selectedIndex].value;
            var yearValue = dateFromYearPicker.options[dateFromYearPicker.selectedIndex].value;

            dateSelected = new Date(parseInt(yearValue), GetMonthFromString(monthValue), 1);
            currentDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
            parsedSystemDate = new Date(parsedSystemDate.getFullYear(), parsedSystemDate.getMonth(), 1);
        }
    }

    success = ShowDateValidationAlert(dateSelected, parsedSystemDate, currentDate, dateType);

    return success;
}


function ValidateReconciliationDateFrom(dateBreakdown, systemStartDate, validationMessage) {
    var success = true;
    var dateType = "From";
    var selectedmonth;
    var selectedyear;
    var dateSelected;

    var dateFromMonthPicker;
    var dateFromYearPicker;

    var currentDate = getCurrentDate();
    var parsedSystemDate = new Date(systemStartDate);

    if (dateBreakdown == 'QUARTER') {
        dateFromMonthPicker = document.getElementById("dateFromQuarterSelect");
        dateFromYearPicker = document.getElementById("dateFromYearSelect");

        if (dateFromMonthPicker != null && dateFromYearPicker != null) {
            var quarterValue = dateFromMonthPicker.options[dateFromMonthPicker.selectedIndex].value;
            var yearValue = dateFromYearPicker.options[dateFromYearPicker.selectedIndex].value;

            selectedmonth = resolveQuarter(quarterValue);
            selectedyear = yearValue;

            if (selectedmonth > 5)
                selectedyear = parseInt(yearValue) - 1;

            dateSelected = new Date(selectedyear, selectedmonth, 1);
            currentDate = GetQuarterStartDate(currentDate);
            parsedSystemDate = GetQuarterStartDate(parsedSystemDate);
        }
    }
    else if (dateBreakdown == 'MONTH') {
        dateFromMonthPicker = document.getElementById("MonthPickerMonthPartDateFrom");
        dateFromYearPicker = document.getElementById("MonthPickerYearPartDateFrom");

        if (dateFromMonthPicker == null && dateFromYearPicker == null) {
            dateFromMonthPicker = document.getElementById("MonthPickerMonthPartStartDate");
            dateFromYearPicker = document.getElementById("MonthPickerYearPartStartDate");
        }

        if (dateFromMonthPicker != null && dateFromYearPicker != null) {
            var monthValue = dateFromMonthPicker.options[dateFromMonthPicker.selectedIndex].value;
            var yearValue = dateFromYearPicker.options[dateFromYearPicker.selectedIndex].value;

            dateSelected = new Date(parseInt(yearValue), GetMonthFromString(monthValue), 1);
            currentDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
            parsedSystemDate = new Date(parsedSystemDate.getFullYear(), parsedSystemDate.getMonth(), 1);
        }
    }

    if (dateSelected < parsedSystemDate) {
        alert(validationMessage);
        success = false;
    }
    else if (dateSelected > currentDate) {
        alert('Selected Date ' + dateType + ' is after Current Quarter');
        success = false;
    }

    return success;
}

function BhpbioValidateMonthlyReportingIsAfterSystemStart(systemStartDate) {
    validationStartDate = systemStartDate;
    validationDateMessage = "Monthly Reconciliation Data is only available after: " + calMgr.scFormatDate(calMgr.getDateFromFormat(validationStartDate, "MM-dd-yyyy"), calMgr.defaultDateFormat) + " - please change the dates selected, or change the report breakdown to Quarter.";

    return ValidateReconciliationDateFrom("MONTH", validationStartDate, validationDateMessage)
}

function ValidateDateTo(dateBreakdown, systemStartDate) {
    var success = false;
    var dateType = "To"
    var selectedmonth = 0;
    var selectedyear = 0;
    var dateSelected;
    var currentDateEndQuarter;

    var dateToMonthPicker;
    var dateToYearPicker;

    var currentDate = getCurrentDate();
    var parsedSystemDate = new Date(systemStartDate);

    if (dateBreakdown == 'QUARTER') {
        dateToMonthPicker = document.getElementById("dateToQuarterSelect");
        dateToYearPicker = document.getElementById("dateToYearSelect");

        if (dateToMonthPicker != null && dateToYearPicker != null) {
            var quarterValue = dateToMonthPicker.options[dateToMonthPicker.selectedIndex].value;
            var yearValue = dateToYearPicker.options[dateToYearPicker.selectedIndex].value;

            //getting last month of quarter (so add 2 months)                                                                                                         
            selectedmonth = resolveQuarter(quarterValue) + 2;
            selectedyear = yearValue;

            if (selectedmonth > 5)
                selectedyear = parseInt(yearValue) - 1;

            dateSelected = new Date(selectedyear, selectedmonth + 1, 0);
            currentDate = GetQuarterEndDate(currentDate);
            parsedSystemDate = GetQuarterEndDate(parsedSystemDate);
        }
    }
    else if (dateBreakdown == 'MONTH') {
        dateToMonthPicker = document.getElementById("MonthPickerMonthPartDateTo");
        dateToYearPicker = document.getElementById("MonthPickerYearPartDateTo");

        if (dateToMonthPicker == null && dateToYearPicker == null) {
            dateToMonthPicker = document.getElementById("MonthPickerMonthPartEndDate");
            dateToYearPicker = document.getElementById("MonthPickerYearPartEndDate");
        }

        if (dateToMonthPicker != null && dateToYearPicker != null) {
            var monthValue = dateToMonthPicker.options[dateToMonthPicker.selectedIndex].value;
            var yearValue = dateToYearPicker.options[dateToYearPicker.selectedIndex].value;

            dateSelected = new Date(parseInt(yearValue), GetMonthFromString(monthValue) + 1, 0);
            currentDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0);
            parsedSystemDate = new Date(parsedSystemDate.getFullYear(), parsedSystemDate.getMonth() + 1, 0);
        }
    }

    success = ShowDateValidationAlert(dateSelected, parsedSystemDate, currentDate, dateType);

    return success;
}

// there are many ways of getting the start and end dates in the reports
// but these are the preferred ones now...
function GetBhpbioStartDate() {
    if (HasBhpbioDaySelection()) {
        return GetBhpbioCoreDate('Start');
    } else if (GetDateBreakdown() == 'QUARTER') {
        return GetBhpbioQuarterStartDate();
    } else {
        return GetBhpbioMonthStartDate();
    }
}

function GetBhpbioEndDate() {
    if (HasBhpbioDaySelection()) {
        return GetBhpbioCoreDate('End');
    } else if (GetDateBreakdown() == 'QUARTER') {
        return GetBhpbioQuarterEndDate();
    } else {
        return GetBhpbioMonthEndDate();
    }
}

function GetBhpbioQuarterStartDate() {
    return GetBhpbioQuarterDate('Start');
}

function GetBhpbioQuarterEndDate() {
    return GetBhpbioQuarterDate('End');
}

function GetBhpbioMonthStartDate() {
    return GetBhpbioMonthDate('Start');
}

function GetBhpbioMonthEndDate() {
    return GetBhpbioMonthDate('End');
}

function HasBhpbioDaySelection() {
    return !!(document.getElementsByName('iStartDateText').item(0) || document.getElementById('StartDayText'));
}

function GetBhpbioCoreDate(startOrEnd) {
    startOrEnd = (startOrEnd || 'Start').toLowerCase();

    var dateResult = null;
    var elementIds = {
        start: "iStartDateText",
        end: "iEndDateText",
        fallback: {
            start: "StartDayText",
            end: "EndDayText"
        }
    };

    var dateElement = document.getElementsByName(elementIds[startOrEnd]).item(0) || document.getElementById(elementIds.fallback[startOrEnd]);

    if (dateElement && dateElement.value) {
        var dateText = dateElement.value;
        var dateArray = dateText.toString().split('-');
        dateResult = new Date(dateArray[2], GetMonthFromString(dateArray[1]), dateArray[0]);
    }

    return dateResult;
}

function GetBhpbioMonthDate(startOrEnd) {
    startOrEnd = startOrEnd || 'Start';

    var elementIds = {
        yearStart: "MonthPickerYearPartDateFrom",
        yearEnd: "MonthPickerYearPartDateTo",
        monthStart: "MonthPickerMonthPartDateFrom",
        monthEnd: "MonthPickerMonthPartDateTo",
        fallback: {
            yearStart: "MonthPickerYearPartStartDate",
            yearEnd: "MonthPickerYearPartEndDate",
            monthStart: "MonthPickerMonthPartStartDate",
            monthEnd: "MonthPickerMonthPartEndDate"
        }
    };

    var monthId = elementIds['month' + startOrEnd];
    var yearId = elementIds['year' + startOrEnd];

    monthPicker = document.getElementById(monthId);
    yearPicker = document.getElementById(yearId);

    if (monthPicker == null && yearPicker == null) {
        monthId = elementIds.fallback['month' + startOrEnd];
        yearId = elementIds.fallback['year' + startOrEnd];
        monthPicker = document.getElementById(monthId);
        yearPicker = document.getElementById(yearId);
    }

    var dateSelected = null;
    if (monthPicker != null && yearPicker != null) {
        var monthValue = monthPicker.options[monthPicker.selectedIndex].value;
        var yearValue = yearPicker.options[yearPicker.selectedIndex].value;

        if (startOrEnd.toLowerCase() == 'start') {
            dateSelected = new Date(parseInt(yearValue), GetMonthFromString(monthValue), 1);
        } else {
            dateSelected = new Date(parseInt(yearValue), GetMonthFromString(monthValue) + 1, 0);
        }
        
    }

    return dateSelected;
}

function GetBhpbioQuarterDate(startOrEnd) {
    startOrEnd = startOrEnd || 'Start';

    var elementIds = {
        yearStart: "dateFromYearSelect",
        yearEnd: "dateToYearSelect",
        quarterStart: "dateFromQuarterSelect",
        quarterEnd: "dateToQuarterSelect"
    }

    var dateSelected = null;

    var quarterElementId = elementIds['quarter' + startOrEnd];
    var yearElementId = elementIds['year' + startOrEnd];
    var dateToMonthPicker = document.getElementById(quarterElementId);
    var dateToYearPicker = document.getElementById(yearElementId);

    if (dateToMonthPicker != null && dateToYearPicker != null) {
        var quarterValue = dateToMonthPicker.options[dateToMonthPicker.selectedIndex].value;
        var yearValue = dateToYearPicker.options[dateToYearPicker.selectedIndex].value;

        var selectedmonth = resolveQuarter(quarterValue);
        var selectedyear = yearValue;

        if (startOrEnd.toLowerCase() == 'end') {
            // move it to the month at the end of the quarter
            selectedmonth += 2;
        }

        if (selectedmonth > 5) {
            selectedyear = parseInt(yearValue) - 1;
        }

        if (startOrEnd.toLowerCase() == 'start') {
            dateSelected = new Date(selectedyear, selectedmonth, 1);
        } else {
            dateSelected = new Date(selectedyear, selectedmonth + 1, 0);
        }
    }

    return dateSelected;
}


function ValidateDateRange(dateBreakdown, options) {
    options = options || {};
    validateAll = options.validateAll === true ? true : false;

    var success = true;
    var currentDate = getCurrentDate();
    var systemStartDate = new Date(2007, 0, 1);

    if (validateAll && !ValidateDateFrom(dateBreakdown, systemStartDate)) {
        success = false;
        return success;
    }
    else if (validateAll && !ValidateDateTo(dateBreakdown, systemStartDate)) {
        success = false;
        return success;
    }

    if (dateBreakdown == 'QUARTER') {
        var dateFromMonthPicker = document.getElementById("dateFromQuarterSelect");
        var dateFromYearPicker = document.getElementById("dateFromYearSelect");

        var dateToMonthPicker = document.getElementById("dateToQuarterSelect");
        var dateToYearPicker = document.getElementById("dateToYearSelect");

        if (dateFromMonthPicker != null && dateFromYearPicker != null && dateToMonthPicker != null && dateToYearPicker != null) {
            var dateFromquarterValue = dateFromMonthPicker.options[dateFromMonthPicker.selectedIndex].value;
            var dateFromyearValue = dateFromYearPicker.options[dateFromYearPicker.selectedIndex].value;

            var dateToquarterValue = dateToMonthPicker.options[dateToMonthPicker.selectedIndex].value;
            var dateToyearValue = dateToYearPicker.options[dateToYearPicker.selectedIndex].value;

            var dateToNumericQuarterValue = parseInt(dateToquarterValue.replace('Q', ''));
            var dateFromNumericQuarterValue = parseInt(dateFromquarterValue.replace('Q', ''));

            if ((dateFromyearValue > dateToyearValue) || (dateFromyearValue == dateToyearValue && dateFromNumericQuarterValue > dateToNumericQuarterValue)) {
                alert('Selected Date From is greater than selected Date To');
                success = false;
            }
        }
    }
    else if (dateBreakdown == 'MONTH') {
        var dateFromMonthPicker = document.getElementById("monthpickermonthpartdatefrom");
        var dateFromYearPicker = document.getElementById("monthpickeryearpartdatefrom");

        var dateToMonthPicker = document.getElementById("monthpickermonthpartdateto");
        var dateToYearPicker = document.getElementById("monthpickeryearpartdateto");

        if (dateFromMonthPicker == null && dateFromYearPicker == null && dateToMonthPicker == null && dateToYearPicker == null) {
            dateFromMonthPicker = document.getElementById("monthpickermonthpartstartdate");
            dateFromYearPicker = document.getElementById("monthpickeryearpartstartdate");

            dateToMonthPicker = document.getElementById("monthpickermonthpartenddate");
            dateToYearPicker = document.getElementById("monthpickeryearpartenddate");
        }

        if (dateFromMonthPicker != null && dateFromYearPicker != null && dateToMonthPicker != null && dateToYearPicker != null) {
            var dateFromMonthValue = dateFromMonthPicker.options[dateFromMonthPicker.selectedIndex].value;
            var dateFromYearValue = dateFromYearPicker.options[dateFromYearPicker.selectedIndex].value;

            var dateToMonthValue = dateToMonthPicker.options[dateToMonthPicker.selectedIndex].value;
            var dateToYearValue = dateToYearPicker.options[dateToYearPicker.selectedIndex].value;

            var dateToMonthInt = returnMonth(dateToMonthValue);
            var dateFromMonthInt = returnMonth(dateFromMonthValue);

            if ((dateFromYearValue > dateToYearValue) || (dateFromYearValue == dateToYearValue && dateFromMonthInt > dateToMonthInt)) {
                alert('Selected Date From is greater than Selected Date To');
                success = false;
            }
        }
    }

    return success;
}

function returnMonth(month) {
    var monthInt = null;
    var months = new Array(12);

    months[0] = "Jan";
    months[1] = "Feb";
    months[2] = "Mar";
    months[3] = "Apr";
    months[4] = "May";
    months[5] = "Jun";
    months[6] = "Jul";
    months[7] = "Aug";
    months[8] = "Sep";
    months[9] = "Oct";
    months[10] = "Nov";
    months[11] = "Dec";

    for (var i = 0; i < months.length; i++) {
        if (months[i] == month)
            monthInt = i + 1;
    }

    return monthInt;
}

// Show and Hide Quarter / Date Controls

function toggleParameterDateControls(toggleCommand) {
    if (document.getElementById("MonthFilterBoxDateFrom") != null) {
        document.getElementById("MonthFilterBoxDateFrom").style.display = toggleCommand;
    }
    if (document.getElementById("MonthFilterBoxDateTo") != null) {
        document.getElementById("MonthFilterBoxDateTo").style.display = toggleCommand;
    }
    if (document.getElementById("MonthFilterBoxStartDate") != null) {
        document.getElementById("MonthFilterBoxStartDate").style.display = toggleCommand;
    }
    if (document.getElementById("MonthFilterBoxEndDate") != null) {
        document.getElementById("MonthFilterBoxEndDate").style.display = toggleCommand;
    }
}

function toggleCustomDateControls(toggleCommand) {
    if (document.getElementById("dateToQuarterSelect") != null &&
    document.getElementById("dateToYearSelect") != null) {
        document.getElementById("dateToQuarterSelect").style.display = toggleCommand;
        document.getElementById("dateToYearSelect").style.display = toggleCommand;
    }

    if (document.getElementById("dateFromQuarterSelect") != null &&
    document.getElementById("dateFromYearSelect") != null) {
        document.getElementById("dateFromQuarterSelect").style.display = toggleCommand;
        document.getElementById("dateFromYearSelect").style.display = toggleCommand;
    }
}

function toggleDateControlsForBreakdown(dateBreakdownType) {
    if (dateBreakdownType == 'QUARTER') {
        toggleParameterDateControls('none');
        toggleCustomDateControls('inline');
    }
    else if (dateBreakdownType == 'MONTH') {
        toggleParameterDateControls('inline');
        toggleCustomDateControls('none');
    }
}

function toggleQuarterDropList() {
    var dateBreakdownType;

    if (document.getElementById('nonParameterDatebreakdown') != null) {
        if (document.getElementById('nonParameterDatebreakdown').value == 'QUARTER')
            dateBreakdownType = 'QUARTER';
        else if (document.getElementById('nonParameterDatebreakdown').value == 'MONTH')
            dateBreakdownType = 'MONTH';
    }
    else if (document.getElementById('dateBreakdown') != null) {
        if (document.getElementById('dateBreakdown').value == 'QUARTER')
            dateBreakdownType = 'QUARTER';
        else if (document.getElementById('dateBreakdown').value == 'MONTH')
            dateBreakdownType = 'MONTH';
    }

    toggleDateControlsForBreakdown(dateBreakdownType);
}

function CheckFormatFactorControlsForF1F2F3() {
    if (!CheckMonthLocationReport()) {
        FormatFactorControlsForF1F2F3();
    }
}

function CheckFormatFactorControls() {
    if (!CheckMonthLocationReport()) {

        FormatFactorControls();
    }
}

function FormatFactorControlsForDensityAnalysis() {
    // Nothing to do here unless the set of parameters for this report is expanded
}


//Comparison Report Location Functions
function RenderLocationCheckboxes(divName, selectBoxName) {
    var selectBox = document.getElementById(selectBoxName);
    var locationId = selectBox.value;
    var month = document.getElementById('MonthPickerMonthPartDateFrom').value;
    var year = document.getElementById('MonthPickerYearPartDateFrom').value;
    var startDate = new Date('1 ' + month + ', ' + year);

    CallAjax(divName, './GetLocationsByLocationType.aspx?LocationId='
        + locationId + '&DivName=' + divName + '&startDate=' + startDate.getFullYear() + '-' + ('0' + (startDate.getMonth() + 1)).slice(-2) + '-' + ('0' + startDate.getDate()).slice(-2), 'image');
}

function CreateLocationsXML(key) {
    var xml;
    var found = false;

    xml = '<Locations>';

    for (var i = 0; i < document.forms[0].elements.length; i++) {
        var e = document.forms[0].elements[i];

        if ((e.type == 'checkbox') && (e.name.indexOf(key) > -1) && (e.checked == true)) {
            found = true;
            xml = xml + '<Location id="' + e.name.replace(key, '') + '" />'
        }
    }

    xml = xml + '</Locations>';

    if (!found)
        xml = '';

    return xml;
}

function IsSingleSourceSelected() {
    var sources = document.getElementsByName("SingleSource");
    var isSelected = false;
    var sourceIndex

    for (sourceIndex = 0; sourceIndex < sources.length; sourceIndex++) {
        if (sources[sourceIndex].value != null) {
            var source = sources[sourceIndex]
            if (source.checked) {
                isSelected = true;
            }
        }
    }

    return isSelected;
}


function BhpbioValidateShippingTargetReport(historicalStartDate, systemStartDate, historicalAggregateStartDate, lumpDates) {
    var success = BhpbioValidateF1F2F3ReconciliationComparison(historicalStartDate, systemStartDate, historicalAggregateStartDate)

    if (success) {
        success = BhpbioValidateLumpDates(lumpDates);
    }

    return success;
}

function BhpbioValidateF1F2F3ReconciliationComparison(historicalStartDate, systemStartDate, historicalAggregateStartDate) {
    var success = true;
    var productInput = document.getElementById('ProductTypeId');
    var locationInput = document.getElementById(locationIdField);
    var locationID = '';
    var productTypeId = null;

    if (locationInput) {
        locationID = locationInput.value;
    }

    if (productInput) {
        productTypeId = productInput.value;
    }

    var adjustdate = new Date();

    var factorValid = EnsureAtleastOneCheckboxIsSelected(factorPrefix);
    var attributeValid = EnsureAtleastOneCheckboxIsSelected(attributePrefix);
    var datebreakdown = document.getElementById("DateBreakdown");
    var singleSourceElement = document.getElementsByName("SingleSource");


    if (!datebreakdown)
        datebreakdown = document.getElementById("nonParameterDateBreakdown");

    var dateBreakdownValue = datebreakdown.options[datebreakdown.selectedIndex].value;

    var locations = document.getElementById('LocationIds');

    if (locations) {
        locations.value = CreateLocationsXML('chkLocation_');
    }
    var hasFactorCheckBoxes = HasCheckBoxes(factorPrefix);
    var hasSourceCheckBoxes = HasCheckBoxes(sourcePrefix);

    if (locationInput && (locationID == '' || locationID == '-1')) {
        alert('Please select a Location');
        success = false;
    } else if (productInput && (productTypeId == '' || productTypeId == '-1')) {
        alert('Please select a Product Type');
        success = false;
    } else if (locations && locations.value == '') {
        alert('Please select at least one location checkbox');
        success = false;
    } else if (!BhpbioValidateLocationType(locationIdField, false)) {
        success = false;
    } else if (hasSourceCheckBoxes && !EnsureAtleastOneCheckboxIsSelected(sourcePrefix)) {
        alert('Please select at least one Source');
        success = false;
    } else if (singleSourceElement && singleSourceElement.length > 0 && !hasSourceCheckBoxes && !IsSingleSourceSelected()) {
        alert("Please select a Source");
        success = false;
    } else if (!attributeValid) {
        alert('Please select at least one Attribute');
        success = false;
    } else if (hasFactorCheckBoxes && !factorValid) {
        alert('Please select at least one Factor');
        success = false;
    } else {
        if (dateBreakdownValue.toUpperCase() == "QUARTER" || dateBreakdownValue.toUpperCase() == "MONTH") {
            dateMonthComponent = document.getElementById("dateFromQuarterSelect");
            dateYearComponent = document.getElementById("dateFromYearSelect");
            dateFromMonthPicker = dateMonthComponent.options[dateMonthComponent.selectedIndex].value;
            dateFromYearPicker = dateYearComponent.options[dateYearComponent.selectedIndex].value;

            dateMonthComponent = document.getElementById("dateToQuarterSelect");
            dateYearComponent = document.getElementById("dateToYearSelect");
            dateToMonthPicker = dateMonthComponent.options[dateMonthComponent.selectedIndex].value;
            dateToYearPicker = dateYearComponent.options[dateYearComponent.selectedIndex].value;


            if ((dateFromMonthPicker == dateToMonthPicker) && (dateFromYearPicker == dateToYearPicker)) {
                validationStartDate = historicalStartDate;
                validationDateMessage = "Please Select Dates After: " + calMgr.scFormatDate(calMgr.getDateFromFormat(validationStartDate, "MM-dd-yyyy"), calMgr.defaultDateFormat) + " - the first available historical data";
            } else {
                validationStartDate = historicalAggregateStartDate;
                validationDateMessage = "Please Select Dates After: " + calMgr.scFormatDate(calMgr.getDateFromFormat(validationStartDate, "MM-dd-yyyy"), calMgr.defaultDateFormat) + " - the first available historical data available for aggregation";
            }
        } else {
            alert('Please select a Date Breakdown');
            success = false;
        }

        if (success) {
            if (!ValidateReconciliationDateFrom(dateBreakdownValue, validationStartDate, validationDateMessage)) {
                success = false;
            } else if (!ValidateDateTo(dateBreakdownValue, validationStartDate)) {
                success = false;
            } else if (!ValidateDateRange(dateBreakdownValue)) {
                success = false;
            } else if (dateBreakdownValue.toUpperCase() == "MONTH" && !BhpbioValidateMonthlyReportingIsAfterSystemStart(systemStartDate)) {
                success = false;
            }
        }
    }

    return success;
}
function RenderBhpbioAnnualReport(systemStartDate) {

    var validInput = BhpbioValidateYearlyReconciliationReport(systemStartDate)

    if (validInput) {
        // remove the viewstate so we don't get crazy errors when posting to the server
        document.getElementById('__VIEWSTATE').value = '';
    }

    return validInput;
}