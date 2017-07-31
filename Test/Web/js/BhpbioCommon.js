
// Display an error message indicating that the selected date range can not be used as it begins prior to the lump/fines cutover
function BhpbioDisplayLumpFinesDateValidationErrorMessage(lumpDates, outputType) {
    // the report cannot be run... build an explanatory message based on the lump / fines cutover date
    var monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

    var lumpMonth = lumpDates.getMonth();  // getMonth() returns a value between 0 to 11..
    var lumpMonthName = monthNames[lumpMonth];
    var lumpYear = lumpDates.getYear();

    // work out the display financial quarter
    var distanceFromQuarterStart = lumpMonth % 3; // find out if the cutover does not align with a quarter

    var quarterStart = lumpMonth;
    var adjustedForwardToQuarterStart = false;

    if (distanceFromQuarterStart > 0) {
        adjustedForwardToQuarterStart = true;
        quarterStart = quarterStart + 3 - distanceFromQuarterStart; // move forward to the next quarter start
    }

    // quarter start is guaranteed to be a multiple of 3
    // work out the calendar quarter
    var calendarQuarter = (quarterStart / 3) + 1;

    // then convert to a financial quarter.. add 2 so that calendar Q1 becomes financial Q3 etc
    var financialQuarter = calendarQuarter + 2;
    if (financialQuarter > 4) {
        // calendar Q3 and Q4 would now be financial Q5 and Q6... these need to be adjusted back
        financialQuarter = financialQuarter - 4;
    }

    var lumpFinancialYear = lumpYear;
    if (calendarQuarter == 3 || calendarQuarter == 4 || (calendarQuarter == 1 && adjustedForwardToQuarterStart)) {
        // perform the financial year adjustment
        lumpFinancialYear = lumpYear + 1;
    }

    alert("The Date From must be greater than the lump/fines cutover date. This " + outputType + " cannot be run prior to " + lumpMonthName + " " + lumpYear + " or Q" + financialQuarter + " " + lumpFinancialYear + " as no GeoMet / product data is present prior to these dates.");
}
