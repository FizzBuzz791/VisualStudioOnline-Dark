//Home scripts

function GetFFactorData(siteId) {
    //var messageOnly = document.getElementById('MessageOnlyValue');
    //messageOnly.value = 'False';

    var element = document.getElementById('fFactorList');

    if ((isDateValid()) && (element != null)) {
       SubmitForm('homeForm', 'fFactorList', './HomeList.aspx?SiteId='+siteId, 'image');
    }
    
    return false;
}

function GetMessageOnly() {

    var element = document.getElementById('fFactorList');

    if (element != null) {
        SubmitForm('homeForm', 'fFactorList', './HomeList.aspx', 'image');
    }

    return false;
}


function PrintFFactorReport(reportId, locationId) {
        if (reportId && isFinite(reportId) && reportId > 0) {
        if (isDateValid()) {
            SetFFactorReportParameters();

            document.getElementById('HomeForm').action = '../Reports/ReportsRun.aspx?ReportId=' + reportId;
            document.getElementById('HomeForm').submit();
        }
    }
}

function SelectSite() {
    var element = document.getElementById('HomeSiteFilter');

    if (element != null) {
        if (element.value != '') {
            location.href = './Default.aspx?SiteID=' + element.value;
        }
    }
   
    return false;
}

// Date filter management
// HomePeriodFilter values: (Calendar Month, MONTH), (Financial Quarter, QUARTER), (Calendar Year, YEAR)
// HomePeriodFromMonthQuarter:
//     storing calendar months/years: (id, text), (January, 1), (February, 2), etc
//     storing financial quarters   : (id, text), (Quarter 1, Q1), (Quarter 2, Q2), etc

var financialQuarters = new Array();
var calendarMonths = new Array();

function AddFinancialQuarter(financialYearId, financialYearText, quarterId, quarterText) {
    // adds a Year/Quarter combination
    
    var financialQuarter = new Array();

    financialQuarter[0] = financialYearId;
    financialQuarter[1] = financialYearText;
    financialQuarter[2] = quarterId;
    financialQuarter[3] = quarterText;

    financialQuarters.push(financialQuarter);
}

function AddCalendarMonth(calendarYearId, calendarYearText, calendarMonthId, calendarMonthText) {
    //adds a Year/Month combination

    var calendarMonth = new Array();

    calendarMonth[0] = calendarYearId;
    calendarMonth[1] = calendarYearText;
    calendarMonth[2] = calendarMonthId;
    calendarMonth[3] = calendarMonthText;

    calendarMonths.push(calendarMonth);
}

function ClearListItems(dropDown) {
    while (dropDown.options.length > 0) {
        dropDown.remove(0);
    }
}

function GetHomePeriodFilter() {
    // can be: MONTH, QUARTER, YEAR

    var homePeriodFilter = document.getElementById('HomePeriodFilter');

    return homePeriodFilter.value;
}

function GetListToUse() {
    var homePeriodFilter = GetHomePeriodFilter();

    if (homePeriodFilter == 'YEAR' || homePeriodFilter == 'MONTH') {
        listToUse = calendarMonths;
    }
    else {
        listToUse = financialQuarters;
    }

    return listToUse;
}

function RenderHomePeriodYear(defaultFromYearId, defaultToYearId,
 defaultFromMonthQuarterId, defaultToMonthQuarterId) {

    // draws the Period-From-Year list based on the Home Period Filter
    // and the known valid Years

    var homePeriodFromYear = document.getElementById('HomePeriodFromYear');
    var homePeriodToYear = document.getElementById('HomePeriodToYear');

    var listToUse;
    var index;
    var firstEntry;
    var newOption;
    var entry;
    var previousYearId;
    var yearId;
    var yearText;
    var monthQuarterId;
    var monthQuarterText;

    ClearListItems(homePeriodFromYear);
    ClearListItems(homePeriodToYear);

    listToUse = GetListToUse();
    
    // populate the YEAR list boxes
    previousYearId = null;
    firstEntry = true;
    for (index = 0; index < listToUse.length; index += 1) {
        entry = listToUse[index];
       
        yearId = entry[0];
        yearText = entry[1];
        if (yearId != previousYearId) {
            // FROM box
            newOption = document.createElement("Option");
            newOption.value = yearId;
            newOption.text = yearText;
            homePeriodFromYear.options.add(newOption);

            // TO box
            newOption = document.createElement("Option");
            newOption.value = yearId;
            newOption.text = yearText;
            homePeriodToYear.options.add(newOption);

            // try to set the defaults - if it matches
            if (firstEntry) {
                // set it to the first item in case there are no future matches
                homePeriodFromYear.value = yearId;
                homePeriodToYear.value = yearId;
                firstEntry = false; 
            }
            else {
                if (defaultFromYearId == yearId) {
                    homePeriodFromYear.value = defaultFromYearId;
                }
                if (defaultToYearId == yearId) {
                    homePeriodToYear.value = defaultToYearId;
                }
            }
            
            previousYearId = yearId;
        }
    }

    // re-render the MONTH/QUARTER boxes
    RenderHomePeriodMonthQuarter(defaultFromYearId, defaultToYearId,
     defaultFromMonthQuarterId, defaultToMonthQuarterId);
}

function RenderHomePeriodMonthQuarter(defaultFromYearId, defaultToYearId,
 defaultFromMonthQuarterId, defaultToMonthQuarterId) {
    var homePeriodFromMonthQuarter = document.getElementById('HomePeriodFromMonthQuarter');
    var homePeriodToMonthQuarter = document.getElementById('HomePeriodToMonthQuarter');
    var homePeriodFromYear = document.getElementById('HomePeriodFromYear');
    var homePeriodToYear = document.getElementById('HomePeriodToYear');
    var homePeriodFilter = document.getElementById('HomePeriodFilter');
    var firstEntry;
    var newOption;
    var fromYearId;
    var toYearId;
    var listToUse;
    var currentYearId;

    var selectedFromYearId;
    var selectedToYearId;
    var selectedFromMonthQuarterId;
    var selectedToMonthQuarterId;

    // find out the currently selected FROM/TO years
    fromYearId = homePeriodFromYear.value;
    toYearId = homePeriodToYear.value;

    // find out the currently selected MONTH/QUARTER values
    if (defaultFromMonthQuarterId == null) {
        selectedFromMonthQuarterId = homePeriodFromMonthQuarter.value;
    } else {
        selectedFromMonthQuarterId = defaultFromMonthQuarterId;
    }
    if (defaultToMonthQuarterId == null) {
        selectedToMonthQuarterId = homePeriodToMonthQuarter.value;
    } else {
        selectedToMonthQuarterId = defaultToMonthQuarterId;
    }
    if (defaultFromYearId == null) {
        selectedFromYearId = homePeriodFromYear.value;
    } else {
        selectedFromYearId = defaultFromYearId;
    }
    if (defaultToYearId == null) {
        selectedToYearId = homePeriodToYear.value;
    } else {
        selectedToYearId = defaultToYearId;
    }

    // clear the lists
    ClearListItems(homePeriodFromMonthQuarter);
    ClearListItems(homePeriodToMonthQuarter);

    listToUse = GetListToUse();

    // populate the MONTH/QUARTER list boxes
    previousYearId = null;
    firstEntry = true;
    for (index = 0; index < listToUse.length; index += 1) {
        entry = listToUse[index];

        currentYearId = entry[0];
        monthQuarterId = entry[2];
        monthQuarterText = entry[3];

        if (currentYearId == fromYearId) {
            // FROM box
            newOption = document.createElement("Option");
            newOption.value = monthQuarterId;
            newOption.text = monthQuarterText;
            homePeriodFromMonthQuarter.options.add(newOption);
        }

        if (currentYearId == toYearId) {
            // TO box
            newOption = document.createElement("Option");
            newOption.value = monthQuarterId;
            newOption.text = monthQuarterText;
            homePeriodToMonthQuarter.options.add(newOption);
        }

        // try to set the defaults, if they're relevant
        if (firstEntry) {
            // set it to the first item in case there are no future matches
            homePeriodFromMonthQuarter.value = monthQuarterId;
            homePeriodToMonthQuarter.value = monthQuarterId;
            firstEntry = false;
        } else {
            if ((selectedFromMonthQuarterId == monthQuarterId) && (selectedFromYearId == currentYearId)) {
                homePeriodFromMonthQuarter.value = selectedFromMonthQuarterId;
            }
            if ((selectedToMonthQuarterId == monthQuarterId) && (selectedToYearId == currentYearId)) {
                homePeriodToMonthQuarter.value = selectedToMonthQuarterId;
            }
        }
    }

    // set the visibility accordingly
    if (homePeriodFilter.value != "YEAR") {
        homePeriodFromMonthQuarter.style.display = 'inline';
        homePeriodToMonthQuarter.style.display = 'inline';
    } else if (homePeriodFilter.value == "YEAR") {
        homePeriodFromMonthQuarter.style.display = 'none';
        homePeriodToMonthQuarter.style.display = 'none';
    }
}

function SetFFactorReportParameters() {
    // breakdown param - the value in this determines
    // whether the MONTH or QUARTER picker control sets are used
    var dateBreakdown = document.getElementById('DateBreakdown');
    
    // month picker params - targets
    var mpStartMonth = document.getElementById('MonthPickerMonthPartStartDate');
    var mpStartYear = document.getElementById('MonthPickerYearPartStartDate');
    var mpEndMonth = document.getElementById('MonthPickerMonthPartEndDate');
    var mpEndYear = document.getElementById('MonthPickerYearPartEndDate');

    // quarter picker params - targets
    var qpStartQuarter = document.getElementById('DateFromQuarterSelect');
    var qpStartYear = document.getElementById('DateFromYearSelect');
    var qpEndQuarter = document.getElementById('DateToQuarterSelect');
    var qpEndYear = document.getElementById('DateToYearSelect');

    // picker controls that
    var homePeriodFilter = document.getElementById('HomePeriodFilter');
    var homePeriodFromYear = document.getElementById('HomePeriodFromYear');
    var homePeriodToYear = document.getElementById('HomePeriodToYear');
    var homePeriodFromMonthQuarter = document.getElementById('HomePeriodFromMonthQuarter');
    var homePeriodToMonthQuarter = document.getElementById('HomePeriodToMonthQuarter');

    if (homePeriodFilter.value == "MONTH") {
        dateBreakdown.value = "MONTH";
        mpStartMonth.value = homePeriodFromMonthQuarter.value;
        mpStartYear.value = homePeriodFromYear.value;
        mpEndMonth.value = homePeriodToMonthQuarter.value;
        mpEndYear.value = homePeriodToYear.value;
    } else if (homePeriodFilter.value == "QUARTER") {
        dateBreakdown.value = "QUARTER";
        qpStartQuarter.value = homePeriodFromMonthQuarter.value;
        qpStartYear.value = homePeriodFromYear.value;
        qpEndQuarter.value = homePeriodToMonthQuarter.value;
        qpEndYear.value = homePeriodToYear.value;
    } else if (homePeriodFilter.value == "YEAR") {
        dateBreakdown.value = "QUARTER";
        qpStartQuarter.value = 'Q3';
        qpStartYear.value = homePeriodFromYear.value;
        qpEndQuarter.value = 'Q2';
        qpEndYear.value = +homePeriodToYear.value + 1;
    }
}

function GetQuarterFirstMonth(quarter) {
    var month = 1;

    if (quarter == "Q1") {
        month = 7
    } else if (quarter == "Q2") {
        month = 10
    } else if (quarter == "Q3") {
        month = 1
    } else if (quarter == "Q4") {
        month = 4
    }

    return month;
}

function GetQuarterLastMonth(quarter) {
    var month = 3;

    if (quarter == "Q1") {
        month = 9
    } else if (quarter == "Q2") {
        month = 12
    } else if (quarter == "Q3") {
        month = 3
    } else if (quarter == "Q4") {
        month = 6
    }

    return month;
}

function GetQuarterYear(year, quarter) {
    var correctedYear = year;

    if (quarter == "Q1" || quarter == "Q2") {
        correctedYear -= 1;
    }

    return correctedYear;
}

function isDateValid() {
    var dateFrom;
    var dateTo;
    var isValid = true;

    var homePeriodFromMonthQuarter = document.getElementById('HomePeriodFromMonthQuarter');
    var homePeriodToMonthQuarter = document.getElementById('HomePeriodToMonthQuarter');
    var homePeriodFromYear = document.getElementById('HomePeriodFromYear');
    var homePeriodToYear = document.getElementById('HomePeriodToYear');
    var homePeriodFilter = document.getElementById('HomePeriodFilter');

    if (homePeriodFilter.value == "MONTH") {
        dateFrom = '1-' + homePeriodFromMonthQuarter.value + '-' + homePeriodFromYear.value;
        dateTo = '1-' + homePeriodToMonthQuarter.value + '-' + homePeriodToYear.value;
    } else if (homePeriodFilter.value == "QUARTER") {
        dateFrom = '1-' + GetQuarterFirstMonth(homePeriodFromMonthQuarter.value) + '-' + GetQuarterYear(homePeriodFromYear.value, homePeriodFromMonthQuarter.value);
        dateTo = '1-' + GetQuarterFirstMonth(homePeriodToMonthQuarter.value) + '-' + GetQuarterYear(homePeriodToYear.value, homePeriodToMonthQuarter.value);
    } else if (homePeriodFilter.value == "YEAR") {
        dateFrom = '1-1-' + homePeriodFromYear.value;
        dateTo = '1-1-' + homePeriodToYear.value;
    }

    if (Date.parse(dateFrom) > Date.parse(dateTo)) {
        alert('Please change the \'From\' period to be before the \'To\' period');
        isValid = false
    }

    return isValid;
}
