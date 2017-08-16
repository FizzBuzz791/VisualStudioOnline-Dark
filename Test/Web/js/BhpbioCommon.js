
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

var originalSubmitForm = SubmitForm;

// overrides core.common as it's using ancient methods
SubmitForm = function (formName, elementId, urlToLoad, showLoading, finalCall) {
    // PP: Disabling this call until updated based on code-review
    // validateDates();

    var QueryString = '?';
    var ServerForm = $('#' + formName);
    var vars = new Object();

    if (urlToLoad.indexOf('?') != -1) {
        QueryString += urlToLoad.substring(urlToLoad.indexOf('?') + 1) + '&';
        urlToLoad = urlToLoad.substring(0, urlToLoad.indexOf('?'));
    }
    ServerForm.find('input').each(function (i) {
        var el = $(this);
        var type = el.attr('type').toLowerCase();
        var name = el.attr('name');
        switch (type) {
        case 'hidden':
            if (name.substring(0, 2) != '__') {
                vars[name] = el.val();
            }
            break;
        case 'text':
            vars[name] = el.val();
            break;
        case 'radio':
            el = el[0]; // I *think* this is because of the upgrade to jQuery 1.7... The others didn't need this change though...
            name = el.id;
            if (el.checked === true) {
                vars[name] = el.value;
            }
            break;
        case 'checkbox':
            // el.is() *should* work for all versions of jquery
            vars[name] = el.is(':checked') === true ? el.val() : '';
            break;
        case 'button':
        case 'submit':
            vars[name] = el.val();
            break;
        }
    });
    ServerForm.find('select').each(function (i) {
        var el = $(this);
        if (el.find('option').length > 0) {
            var name = el.attr('name');
            vars[name] = el.val();
        }
    });
    ServerForm.find('textarea').each(function (i) {
        var el = $(this);
        var name = el.attr('name');
        vars[name] = el.val();
    });
    CallAjax(elementId, urlToLoad + QueryString, showLoading, finalCall, vars);
    return false;
}