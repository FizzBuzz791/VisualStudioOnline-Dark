var _controlId = null;
var _onChange = null;
var _lowestLocationTypeDescription = null;

function LoadLocationOverride(isLocationMandatory, locationId, locationDivId, locationColWidth, showCaptions, controlId,
 callbackMethodUp, callbackMethodDown, onChange, lowestLocationTypeDescription, initialLoad, omitInitialChange, startDate, options) {
    options = options || {};

    if (typeof options.showLocationGroups == 'undefined') {
        options.showLocationGroups = $('#ShowLocationGroups').val() === 'true';
    }

	if (!lowestLocationTypeDescription) {
		lowestLocationTypeDescription = '';
	}
	if (!onChange) {
		onChange = '';
	}

	_controlId = controlId;
	_onChange = onChange;
	_lowestLocationTypeDescription = lowestLocationTypeDescription;
	
	if(!startDate) {
		return LoadLocation(false, locationId, locationDivId, locationColWidth, showCaptions, controlId,
			callbackMethodUp, callbackMethodDown, onChange, lowestLocationTypeDescription, initialLoad, omitInitialChange);
	}

	var qryStr = '../Utilities/LocationFilterLoad.aspx?LocationId=' + locationId +
		'&LocationDivId=' + locationDivId + '&LocationColWidth=' + locationColWidth +
		'&ShowCaptions=' + showCaptions + '&ControlId=' + controlId +
		'&CallbackMethodUp=' + callbackMethodUp + '&CallbackMethodDown=' + callbackMethodDown +
        '&onChange=' + onChange + '&lowestLocationTypeDescription=' + lowestLocationTypeDescription +
        '&initialLoad=' + initialLoad + '&omitInitialChange=' + omitInitialChange + +'&Mandatory=' + isLocationMandatory +
        '&reportStartDateElementName=' + reportStartDateElementName + '&startDate=' + startDate;

	if (options.locationGroupId && options.locationGroupId > 0) {
	    qryStr += '&locationGroupId=' + options.locationGroupId
	}

	if (options.showLocationGroups === true) {
        qryStr += '&showLocationGroups=true'
	} else {
	    qryStr += '&showLocationGroups=false'
	}

	CallAjax(locationDivId, qryStr, 'image');

	return false;
}

var reportStartDateElementName = '';
var reportStartQuarterElementName = '';

function LocationDropDownChangedOverride(locationCtrl, locationDivId, locationColWidth, showCaptions, controlId,
 callbackMethodUp, callbackMethodDown, onChange, lowestLocationTypeDescription, overrideType) {
	if (locationCtrl.selectedIndex > -1) {
	    var locationId = locationCtrl.options[locationCtrl.selectedIndex].value;
	    var locationGroupId = -1;
		var startDate = null;

		var locationComponents = locationId.split("G");
		if (locationComponents.length > 1) {
		    locationId = locationComponents[0];
		    locationGroupId = locationComponents[1];
		}
		
		if (overrideType == 'approval') {
			var month = document.getElementById('MonthPickerMonthPart').value;
			var year = document.getElementById('MonthPickerYearPart').value;
			startDate = new Date('1 ' + month + ', ' + year);
		}

		if (overrideType == 'report') {
			var dateBreakdownType = 'MONTH';

			if (document.getElementById('DateBreakdown') != null) {
				if (document.getElementById('DateBreakdown').value == 'QUARTER') {
					dateBreakdownType = 'QUARTER';
				}
			} else if (document.getElementById('nonParameterDatebreakdown') != null) {
				if (document.getElementById('nonParameterDatebreakdown').value == 'QUARTER') {
					dateBreakdownType = 'QUARTER';
				}
			}

			if (dateBreakdownType == 'MONTH') {
				if (reportStartDateElementName != '') {
					if (reportStartDateElementName.indexOf(',', 0) > -1) {
						var monthPart = document.getElementById(reportStartDateElementName.split(',')[0]).value;
						var yearPart = document.getElementById(reportStartDateElementName.split(',')[1]).value;
						startDate = new Date('1 ' + monthPart + ', ' + yearPart);
					} else {
						startDate = calMgr.getDateFromFormat(document.getElementsByName(reportStartDateElementName)[0].value, calMgr.defaultDateFormat);
					}
				}
			} else {
				if (reportStartQuarterElementName != '') {
					if (reportStartQuarterElementName.indexOf(',', 0) > -1) {
						var quarterMonthPart = document.getElementById(reportStartQuarterElementName.split(',')[0]).value;
						var quarterYearPart = document.getElementById(reportStartQuarterElementName.split(',')[1]).value;
						startDate = QuarterToMonth(quarterMonthPart, quarterYearPart);
					}
				}
			}
		}

		if (startDate) {
			LoadLocationOverride(false, locationId, locationDivId, locationColWidth, showCaptions, controlId,
				callbackMethodUp, callbackMethodDown, onChange, lowestLocationTypeDescription, null, null,
                startDate.getFullYear() + '-' + ('0' + (startDate.getMonth() + 1)).slice(-2) + '-' + ('0' + startDate.getDate()).slice(-2),
			    {locationGroupId: locationGroupId}
            );
		} else {
			LoadLocationOverride(false, locationId, locationDivId, locationColWidth, showCaptions, controlId,
				callbackMethodUp, callbackMethodDown, onChange, lowestLocationTypeDescription, null, null, null);
		}
	}
}

var lastMonth = null;
var monthList = [];
var currentHub = '';
var hubList = [];
var hubIdList = [];
var locationDivId = '';

function CheckMonthLocation(currentMonth) {
	var loadLocation = false;
    //alert(currentMonth)
	if (currentHub == '') {
	    var locationName = document.getElementById('LocationName')
	    if (locationName != null) {
	        currentHub = locationName.value
	    }
	}
	
	if ((currentHub != '') && (hubList.indexOf(currentHub) > -1)) {
		for (var i = 0; i < monthList.length; i++) {
			if ((lastMonth < monthList[i] && currentMonth >= monthList[i]) || (currentMonth < monthList[i] && lastMonth >= monthList[i])) {
				loadLocation = true;
				LoadLocationOverride(false, hubIdList[hubList.indexOf(currentHub)], locationDivId, 0, true, _controlId, '', '', _onChange, _lowestLocationTypeDescription, null, null, currentMonth.getFullYear() + '-' + ('0' + (currentMonth.getMonth() + 1)).slice(-2) + '-' + ('0' + currentMonth.getDate()).slice(-2));
				break;
			}
		}
	}

	lastMonth = currentMonth;

	return loadLocation;
}

function CheckMonthLocationApproval(index) {
    var id = 'MonthPickerMonthPart';
    if (index !== undefined) {
        id += index
    }
	var month = document.getElementById(id).value;
	var year = document.getElementById(id).value;
	var currentMonth = new Date('1 ' + month + ', ' + year);

	CheckMonthLocation(currentMonth);
}

function CheckMonthLocationPartStart() {
    var month = document.getElementById('MonthPickerMonthPartStart').value;
    var year = document.getElementById('MonthPickerYearPartStart').value;
    var currentMonth = new Date('1 ' + month + ', ' + year);

    CheckMonthLocation(currentMonth);
}

function CheckMonthLocationReport() {

    // first check whether the report actually has a location element at all
    var locationElement = document.getElementById('LocationName')
    if (typeof (locationElement) == 'undefined' || locationElement == null) {
        // this page has no location control and therefore there is no date based location check to perform
        return true;
    }

    var currentMonth;
	var dateBreakdownType = 'MONTH';

	if (document.getElementById('DateBreakdown') != null) {
		if (document.getElementById('DateBreakdown').value == 'QUARTER') {
			dateBreakdownType = 'QUARTER';
		}
	} else if (document.getElementById('nonParameterDatebreakdown') != null) {
		if (document.getElementById('nonParameterDatebreakdown').value == 'QUARTER') {
			dateBreakdownType = 'QUARTER';
		}
	}

	if (dateBreakdownType == 'MONTH' && reportStartDateElementName.indexOf(',', 0) > -1) {
		var monthPart = document.getElementById(reportStartDateElementName.split(',')[0]).value;
		var yearPart = document.getElementById(reportStartDateElementName.split(',')[1]).value;
		currentMonth = new Date('1 ' + monthPart + ', ' + yearPart);
	} else if (dateBreakdownType == 'QUARTER' && reportStartQuarterElementName.indexOf(',', 0) > -1) {
		var quarterMonthPart = document.getElementById(reportStartQuarterElementName.split(',')[0]).value;
		var quarterYearPart = document.getElementById(reportStartQuarterElementName.split(',')[1]).value;
		currentMonth = QuarterToMonth(quarterMonthPart, quarterYearPart);
	} else {
		currentMonth = calMgr.getDateFromFormat(document.getElementsByName(reportStartDateElementName)[0].value, calMgr.defaultDateFormat);
		if (currentMonth == 0) {
			currentMonth = lastMonth;
		}
	}

	return CheckMonthLocation(currentMonth);
}

function SetupReportMonthControl() {
	if (reportStartDateElementName != '') {
		if (reportStartDateElementName.indexOf(',', 0) > -1) {
			var monthElement = document.getElementById(reportStartDateElementName.split(',')[0]);
			var yearElement = document.getElementById(reportStartDateElementName.split(',')[1]);

			if (monthElement != null && yearElement != null) {

			    var monthOnChange = monthElement.getAttribute('onchange');
			    var yearOnChange = yearElement.getAttribute('onchange');

			    monthElement.onchange = function() {
			        CheckMonthLocationReport();

			        if (monthOnChange != null) {
			            monthOnChange();
			        }
			    };

			    yearElement.onchange = function() {
			        CheckMonthLocationReport();

			        if (yearOnChange != null) {
			            yearOnChange();
			        }
			    };

			    if (lastMonth == null) {
			        lastMonth = new Date('1 ' + monthElement.value + ', ' + yearElement.value);
			    }
			}
		} else {
			var dateElement = document.getElementsByName(reportStartDateElementName)[0];
			var originalOnChange = dateElement.getAttribute('onchange');

			dateElement.onchange = function() {
				CheckMonthLocationReport();

				if (originalOnChange != null) {
					originalOnChange();
				}
			};

			CalendarControls.Lookup(reportStartDateElementName.substring(0, reportStartDateElementName.length - 4)).JStoRunOnSelect = 'CheckMonthLocationReport();';

			if (lastMonth == null) {
				lastMonth = calMgr.getDateFromFormat(dateElement.value, calMgr.defaultDateFormat);
			}
		}
	}

	if (reportStartQuarterElementName != '') {
		if (reportStartQuarterElementName.indexOf(',', 0) > -1) {
			var monthQuarterElement = document.getElementById(reportStartQuarterElementName.split(',')[0]);
			var yearQuaraterElement = document.getElementById(reportStartQuarterElementName.split(',')[1]);

			if (monthQuarterElement) {
			    var monthQuarterOnChange = monthQuarterElement.getAttribute('onchange');
			    monthQuarterElement.onchange = function() {
			        CheckMonthLocationReport();
			        if (monthQuarterOnChange != null) {
			            monthQuarterOnChange();
			        }
			    };
			}

			if (yearQuaraterElement) {
			    var yearQuarterOnChange = yearQuaraterElement.getAttribute('onchange');
			    yearQuaraterElement.onchange = function() {
			        CheckMonthLocationReport();
			        if (yearQuarterOnChange != null) {
			            yearQuarterOnChange();
			        }
			    };
			}

			if (lastMonth == null) {
				lastMonth = QuarterToMonth(monthQuarterElement.value, yearQuaraterElement.value);
			}
		}
	}
}

function QuarterToMonth(quarter, year) {
	var month;

	switch (quarter) {
	case 'Q3':
		month = 'Jan';
		break;
	case 'Q4':
		month = 'Apr';
		break;
	case 'Q1':
		month = 'Jul';
		year--;
		break;
	default:
		month = 'Oct';
		year--;
		break;
	}

	return new Date('1 ' + month + ', ' + year);
}

if (!Array.prototype.indexOf) {
	Array.prototype.indexOf = function(val) {
		for (var i = 0; i < this.length; i++) {
			if (this[i] === val) {
				return i;
			}
		}
		return -1;
	};
}