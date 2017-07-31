//Spatial Comparison functions
function SpatialComparisonSeletion(comparisonCtrl, prefix)
{
	if(comparisonCtrl.selectedIndex > -1)
	{
		var selection = comparisonCtrl.options[comparisonCtrl.selectedIndex].value;
		
		ForceDisabled(prefix + 'MinePlanType');
		ForceDisabled(prefix + 'MinePlan');
		ForceDisabled(prefix + 'BlockModel');

		//Protected Const SpatialMinePlanItem As Int16 = 0
		//Protected Const SpatialModelBlockItem As Int16 = 1
		//Enable controls based on above constants (defined in Filter)
		if(selection == 0)
		{
			ForceEnabled(prefix + 'MinePlanType');
		}
		else if(selection == 1)
		{
			ForceEnabled(prefix + 'BlockModel');
		}
	}
}

function RenderSpatialComparison()
{
    SubmitForm('DigblockSpatialForm', 'RenderArea', './DigblockSpatialView.aspx', 'image');
	return false;
}

function PreviewVarianceColour(colourCtrl)
{
	var colour = colourCtrl.options[colourCtrl.selectedIndex].value;
	var thatchId = colourCtrl.id.replace("color", "thatch");
	var thatchCell = document.getElementById(thatchId);
	
	thatchCell.style.backgroundColor = colour;
}

function PreviewVarianceColour2(colourCtrl)
{
	var colour = colourCtrl.value;
	var thatchId = colourCtrl.id.replace("color", "thatch");
	var thatchCell = document.getElementById(thatchId);
	
	thatchCell.style.backgroundColor = colour;
}

function SaveVariances()
{
	SubmitForm('VarianceForm', '', './DigblockSpatialVarianceSave.aspx');
	return false;
}

function GetMinePlans(targetDiv, controlName, typeCtrl)
{
	if(typeCtrl.selectedIndex > -1)
	{
		var typeId = typeCtrl.options[typeCtrl.selectedIndex].value;
		var qryStr = 'DigblockSpatialGetMinePlans.aspx?'
			+ 'MinePlanTypeId=' + typeId
			+ '&ControlName=' + controlName;

		CallAjax(targetDiv, qryStr);
	}
}

//Recalc Logging Functions
function GetSourceDestFilterType(filterTypeCtrl, targetId, ctrlId)
{
	if(filterTypeCtrl.selectedIndex > -1)
	{
		var filterType = filterTypeCtrl.options[filterTypeCtrl.selectedIndex].value;
		var qryStr = 'RecalcLogicGetSourceDestFilter.aspx?FilterTypeId=' + filterType +
			'&ControlId=' + ctrlId;

		CallAjax(targetId, qryStr);
	}
}

function GetRecalcLogicDetail() {
    var startDate = document.getElementsByName("RecalcLogicDateFromText").item(0).value;
    var endDate = document.getElementsByName("RecalcLogicDateToText").item(0).value;
    ClearElement('itemDetail');
    if (ValidateStartEndDates(startDate, endDate)) {
        SubmitForm('RecalcLogicForm', 'itemList', './RecalcLogicList.aspx', 'imageWide');
    }
    return false;
}

function ValidateStartEndDates(startDate, endDate) {
    var success = true;
    var alertStr = "";
    var currentDate = new Date();

    startDate = calMgr.getDateFromFormat(startDate, calMgr.defaultDateFormat)
    endDate = calMgr.getDateFromFormat(endDate, calMgr.defaultDateFormat)

    if (startDate == "") {
        alertStr = alertStr + '- Start Date not selected \n';
        success = false;
    } else if (startDate > currentDate) {
        alertStr = alertStr + '- Start Date cannot be later than Current Date \n';
        success = false;
    }

    if (endDate == "") {
        alertStr = alertStr + '- End Date not selected \n';
        success = false;
    } else if (endDate > currentDate) {
        alertStr = alertStr + '- End Date cannot be later than Current Date \n';
        success = false;
    }

    if (startDate != "" && endDate != "") {
        if (startDate > endDate) {
            alertStr = alertStr + '- Start Date cannot be later than End Date \n';
            success = false;
        }
    }

    if (alertStr != "") {
        alertStr = 'Please Fix the following Errors : \n' + alertStr;
        alert(alertStr);
    }

    return success
}

function GetRecalcLogicDescription(recalcHistoryId)
{
	CallAjax('itemDetail', './RecalcLogicDescriptionView.aspx?HistoryId='+recalcHistoryId, 'imageWide');
	return false;
}

function GetRecalcLogicNode(nodeRowId, nodeLevel, recordId, transactionType, includeGrades)
{
	var qryStr = './RecalcLogicGetNode.aspx?NodeRowId=' + nodeRowId +
		'&NodeLevel=' + nodeLevel +
		'&RecordId=' + recordId +
		'&TransactionType=' + transactionType +
		'&IncludeGrades=' + includeGrades;

	CallAjax('itemStage', qryStr);
}

function AppendRecalcLogicNodes(nodeRowId)
{
	var stage = document.getElementById('StageTable');
	var curRow = document.getElementById(nodeRowId);
	var table = curRow.parentNode;

	AppendNodeRows(stage, table, curRow);
	
	document.getElementById('itemStage').innerHTML = '';
}

function ToggleRecalcLogicNode(nodeRowId, nodeLevel, recordId, transactionType, includeGrades)
{
	//If no hidden rows were found then we havent got this node through ajax yet
	if(!ToggleNode(nodeRowId))
	{
		GetRecalcLogicNode(nodeRowId, nodeLevel, recordId, transactionType, includeGrades);
	}	
}