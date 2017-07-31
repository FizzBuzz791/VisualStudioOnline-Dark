//Depletion scripts
function AddHaulage(){
	SubmitForm('serverForm', '', './DepletionHaulageAdd.aspx');
	return false;
}

function AddNewDepletionDate(){
	SubmitForm('serverForm', '', './DepletionDateAdd.aspx');
	return false;
}

function AddUserDigblocks(){
	CallAjax('', './DepletionAddUserDigblocks.aspx');
	
	return false;
}

function ApproveDepletion(){
    var t = event.target == undefined ? event.srcElement : event.target;
    var el = $(t);
    window.currentButton = el;
    el.attr('disabled', true);
    CallAjax('', './DepletionApprove.aspx', null, null, 'ReenableApproveDepletion()');
    return false;
}

function ReenableApproveDepletion() {
    if (window.currentButton != undefined && window.currentButton != null) {
        window.currentButton.attr('disabled', false);
        window.currentButton = null;
        delete window.currentButton;
    }
}

function BeginDepletion(DigblockSurveyId){
	CallAjax('depletionContent', './DepletionInitialiseDigblockSurvey.aspx?DigblockSurveyId=' + DigblockSurveyId, 'image');
	return false;
}

function DeleteHaulage(DigblockSurveyActualId, DigblockId, DigblockSurveySummaryId){
	if(confirm('Delete the haulage record from \'' + DigblockId + '\'')){
		CallAjax('', './DepletionHaulageDelete.aspx?dsaId=' + DigblockSurveyActualId + '&DigblockSurveySummaryId=' + DigblockSurveySummaryId);
	}
	
	return false;
}

function DigblockPolygonMapClick(DigblockId){
	var w = window.open('../Digblocks/DigblockDetails.aspx?DigblockId=' + DigblockId, '_digblock');
	w.focus();

	return false;
}

function CheckControls(formName) {
	var checked = 0;
	var formControls = document.getElementById(formName).elements;
	
	for (var i = 0; i < formControls.length; i++) {		
		if (formControls[i].name.indexOf('deplete_') >= 0) {
			if (formControls[i].checked == true) {
				checked = checked + 1				
			} else {
				formControls[i].value = 'off';
			}
		}
	}	
	return (checked > 0);
}

function NewDepletionDigblockDetails(DigblockSurveySummaryId){
	var w = window.open('./DepletionBegin.aspx?dssid=' + DigblockSurveySummaryId, '_depletion');
	w.focus();
	return false;
}

function GetDepletionDigblockDetails(DigblockSurveySummaryId, RecordNo, UseList){
	CallAjax('depletionContent', './DepletionDigblockDetails.aspx?list=' + UseList + '&dssid=' + DigblockSurveySummaryId + '&recno=' + RecordNo, 'image');
	return false;
}

function GetDepletionSelectedDigblockDetails(){
	if (CheckControls('DepletionDigblocksForm') == true) {
		SubmitForm('DepletionDigblocksForm', 'depletionContent', './DepletionDigblockDetails.aspx?list=true', 'image');
	}
	else {
		alert('Please select one or more records to Edit!');
	}
	return false;
}

function GetDepletionDigblockList(){
	CallAjax('depletionContent', './DepletionDigblockList.aspx', 'image');
	return false;
}

function GetDepletionDigblockSurveyList(){
	CallAjax('digblockSurveyList', './DepletionDigblockSurveyList.aspx', 'image');
	return false;
}

function GetDepletionSummaryList(DigblockSurveyId){
	CallAjax('summaryList', './DepletionSummaryList.aspx?DigblockSurveyId=' + DigblockSurveyId, 'image');
	return false;
}

function RemoveDepletion(DigblockSurveyId, digblockSurveyDate, digblockSurveyShift){
    if (confirm("Are you sure you wish to delete the depletion period? (Ending on "+digblockSurveyDate+", " + digblockSurveyShift + ")")) {
		CallAjax('', './DepletionDeleteProcess.aspx?DigblockSurveyId=' + DigblockSurveyId);
	}
	return false;
}

function SelectDigblock(e){
	CallAjax('depletionContent', './DepletionSaveDigblockSelection.aspx?dssid=' + VbReplace(e.id, 'deplete_', '') + '&select=' + e.checked);
}

function UndoDepletion(DigblockSurveyId){
	CallAjax('', './DepletionUnapproveProcess.aspx?DigblockSurveyId=' + DigblockSurveyId);
	return false;
}

function EditDepletion(digblockId, tonnes, comment)
{
	document.getElementById('SourceDigblock').value = digblockId;
	document.getElementById('Tonnes').value = tonnes;
	document.getElementById('Comment').value = comment;

	return false;
}