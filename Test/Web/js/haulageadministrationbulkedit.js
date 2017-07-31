/****  Global Variables used on the Bulk Edit Page *****/
var boolFiltersChanged = false;
var hasHaulageData = false;
var haulageTotalRecords = null;
var haulageHasSourceStockpile = null;
var haulageHasSourceDigblock = null;
var haulageHasSourceMill = null;
var haulageHasDestinationStockpile = null;
var haulageHasDestinationCrusher = null;
var haulageHasDestinationMill = null;
var haulageSumTonnes = null;
var haualgeCheckedTonnes = null;

function GetHaulageAdministrationBulkEditFilter(locationId) {
	GetHaulageAdministrationBulkEditList();
	
	if (locationId == undefined) {
		GetHaulageAdministrationBulkEditOptions(-1);		
	} 
	else {
		GetHaulageAdministrationBulkEditOptions(locationId);	
	}
	
	boolFiltersChanged = false;
	return false;
}

function GetHaulageAdministrationBulkEditList() {
    //SubmitForm('bulkEditForm', 'itemList', './HaulageAdministrationList.aspx?BulkEdit=True', 'imageWide');
    SubmitFormWithDateValidation(false, 'bulkEditForm', 'itemList', './HaulageAdministrationList.aspx?BulkEdit=True', 'imageWide');
  return false;
}

function GetHaulageAdministrationBulkEditOptions(locationId) {
    SubmitForm('bulkEditForm', 'bulkEditOptions', './HaulageAdministrationBulkEditOptions.aspx?lid=' + locationId, 'imageWide');
    //SubmitFormWithDateValidation(false, 'bulkEditForm', 'bulkEditOptions', './HaulageAdministrationBulkEditOptions.aspx?lid=' + locationId, 'imageWide');
	return false;
}

function ProcessUpdate() {
  SubmitForm('bulkEditForm', '', './HaulageAdministrationBulkEditSave.aspx');
  return false;
}

function ProcessDelete() {
  SubmitForm('bulkEditForm', '', './HaulageAdministrationBulkEditSave.aspx?BulkDelete=True');
  return false;
}


var validateDateOld = calMgr.validateDate;
function validateDateChanged(eInput, bRequired, dStartDate, dEndDate)
{
	validateDateOld.call(calMgr, eInput, bRequired, dStartDate, dEndDate);
	filtersChanged();
}
calMgr.validateDate = validateDateChanged;


function noHaulageData()
{
  hasHaulageData = false;
  haulageTotalRecords = null;
  haulageHasSourceStockpile = null;
  haulageHasSourceDigblock = null;
  haulageHasSourceMill = null;
  haulageHasDestinationStockpile = null;
  haulageHasDestinationCrusher = null;
  haulageHasDestinationMill = null;
  haulageSumTonnes = null;
}

function enterHaulageData(cRecords, cSrcStockpile, cSrcDigblock, cSrcMill, cDestStockpile, cDestCrusher, cDestMill, sumTonnes)
{
  hasHaulageData = true;
  haulageTotalRecords = cRecords;
  haulageHasSourceStockpile = cSrcStockpile;
  haulageHasSourceDigblock = cSrcDigblock;
  haulageHasSourceMill = cSrcMill;
  haulageHasDestinationStockpile = cDestStockpile;
  haulageHasDestinationCrusher = cDestCrusher;
  haulageHasDestinationMill = cDestMill;
  haulageSumTonnes = sumTonnes;
}

function filtersChanged()
{
  if (boolFiltersChanged == false)
  {
    var chkSelectAllBox = document.getElementById('chkSelectiveEdit');

	  if (chkSelectAllBox) 
	  { // Turn off the haulage selectivity.
	    chkSelectAllBox.checked = true;
	    chkSelectAllBox.disabled = true;
	  }
	  
	  boolFiltersChanged = true;
	  updateDisplay();
  }
}

function clickBulkDelete()
{
  var returnValue = true;
  var chkSlctEditBox = document.getElementById('chkSelectiveEdit');
  var UsingSelectiveHaulage = false;
  if (chkSlctEditBox) UsingSelectiveHaulage = !chkSlctEditBox.checked

	if (boolFiltersChanged == true)
		return false;

	// --- Checks ---
	// Check to total records number
  if (!UsingSelectiveHaulage && haulageTotalRecords < 1)
  {
	  alert('There are no haulage records to change.\nRefine the filter to display at least one haulage record.');
	  returnValue = false;
  }
  else if (UsingSelectiveHaulage && SelectiveHaulageCount() < 1)
  {
	  alert('There are no haulage records to change.\nSelect at least one haulage to update.');
	  returnValue = false;
  }

	// Last check the user to see if their sure.
	if (returnValue == true) {
	  if (!UsingSelectiveHaulage) 
  		returnValue = confirm('This update will permanently delete ' + haulageTotalRecords + ' haulage records and cannot be undone.\nAre you sure you wish to bulk delete?');
    else
  		returnValue = confirm('This update will permanently delete ' + SelectiveHaulageCount() + ' haulage records and cannot be undone.\nAre you sure you wish to make the delete?');
	}
	
	if (returnValue)
	  ProcessDelete();
	  
  return false;
}


function clickBulkUpdate()
{
	var returnValue = true;
	var selectedDest = ''
	var selectedSrc = ''
  var inputs = document.getElementsByTagName('input');
	var strSources = '';
	var strDestinations = '';
  var chkSlctEditBox = document.getElementById('chkSelectiveEdit');
  var UsingSelectiveHaulage = false;
  if (chkSlctEditBox) UsingSelectiveHaulage = !chkSlctEditBox.checked
  
	if (boolFiltersChanged == true)
		return false;
	
	// Compile the Source and Destination strings and get the selected values.
	if (haulageHasSourceStockpile > 0) strSources = haulageHasSourceStockpile + ' Stockpiles';
	if (haulageHasSourceDigblock > 0) {
		if (strSources.length > 0) strSources = strSources + ', '
		strSources = strSources + haulageHasSourceDigblock + ' Digblocks';
	}
	if (haulageHasSourceMill > 0) {
		if (strSources.length > 0) strSources = strSources + ', '
		strSources = haulageHasSourceMill + ' Mills';
	}

	if (haulageHasDestinationStockpile > 0) strDestinations = haulageHasDestinationStockpile + ' Stockpiles';
	if (haulageHasDestinationCrusher > 0) {
		if (strDestinations.length > 0) strDestinations = strDestinations + ', '
		strDestinations = strDestinations + haulageHasDestinationCrusher + ' Crushers';
	}
	
	if (haulageHasDestinationMill > 0) {
		if (strDestinations.length > 0) strDestinations = strDestinations + ', '
		strDestinations = strDestinations + haulageHasDestinationMill + ' Mills';
	}

  for(var i=0;i<inputs.length;i++){
      if (/^Dest/.test(inputs[i].name)) { if (inputs[i].checked) selectedDest = inputs[i].name }
      if (/^Src/.test(inputs[i].name)) { if (inputs[i].checked) selectedSrc = inputs[i].name }
  }

  if (selectedDest == 'Dest_Stockpile')
		selectedDest = 'Stockpile';
  else if (selectedDest == 'Dest_Crusher')
		selectedDest = 'Crusher';
  else if (selectedDest == 'Dest_Mill') 
		selectedDest = 'Mill';
	else
		selectedDest = 'Unknown';

  if (selectedSrc == 'Src_Stockpile') 
		selectedSrc = 'Stockpile'
  else if (selectedSrc == 'Src_Digblock') 
		selectedSrc = 'Digblock'
  else if (selectedSrc == 'Src_Mill') 
		selectedSrc = 'Mill'
	else
		selectedSrc = 'Unknown';

	// --- Checks ---
	// Check to total records number
  if (!UsingSelectiveHaulage && haulageTotalRecords < 1)
  {
	  alert('There are no haulage records to change.\nRefine the filter to display at least one haulage record.');
	  returnValue = false;
  }
  else if (UsingSelectiveHaulage && SelectiveHaulageCount() < 1)
  {
	  alert('There are no haulage records to change.\nSelect at least one haulage to update.');
	  returnValue = false;
  }

	// Check properties flagged
	if (returnValue == true && !isValid('Dest') &&  !isValid('Src') && !isValid('Truck')) {
		alert('No properties have been flagged to change the haulage records.');
		returnValue = false;
	}

  if (!UsingSelectiveHaulage) 
  {
	  // Check for a change in destination type.
	  if (returnValue == true) {
		  if ((selectedDest == 'Stockpile' && (haulageHasDestinationCrusher > 0 || haulageHasDestinationMill > 0))
			  || (selectedDest == 'Crusher' && (haulageHasDestinationStockpile > 0 || haulageHasDestinationMill > 0))
			  || (selectedDest == 'Mill' && (haulageHasDestinationCrusher > 0 || haulageHasDestinationStockpile > 0)))
		  {
			  returnValue = confirm('Warning: You are changing the Destination type to \'' + selectedDest + '\' when there are records of other types.\nThe selected records consist of ' + strDestinations + ' Destinations.\nProceed with the update?');
		  }
	  }
  	
	  // Check for a change in source type.
	  if (returnValue == true) {
		  if ((selectedSrc == 'Stockpile' && (haulageHasSourceDigblock > 0 || haulageHasSourceMill > 0))
			  || (selectedSrc == 'Digblock' && (haulageHasSourceStockpile > 0 || haulageHasSourceMill > 0))
			  || (selectedSrc == 'Mill' && (haulageHasSourceDigblock > 0 || haulageHasSourceStockpile > 0)))
		  {
			  returnValue = confirm('Warning: You are changing the Source type to \'' + selectedSrc + '\' when there are records of other types.\nThe selected records consist of ' + strSources + ' Sources.\nProceed with the update?');
		  }
	  }
	}
	
	// Last check the user to see if their sure.
	if (returnValue == true) {
	  if (!UsingSelectiveHaulage) 
  		returnValue = confirm('This update will modify ' + haulageTotalRecords + ' haulage records and cannot be undone.\nAre you sure you wish to make the update?');
    else
  		returnValue = confirm('This update will modify the ' + SelectiveHaulageCount() + ' haulage records that were selected and cannot be undone.\nAre you sure you wish to make the update?');
	}
	
	if (returnValue)
	  ProcessUpdate();
	  
  return false;
}


function isValid(disType)
{
    var valid = 0;
    var inputs = document.getElementsByTagName('input');
    for(var i=0;i<inputs.length;i++){
        if (/^Res/.test(inputs[i].name) & disType == 'Res') { if (inputs[i].checked) valid = 1  }
        if (/^Dest/.test(inputs[i].name) & disType == 'Dest') { if (inputs[i].checked) valid = 1  }
        if (/^Src/.test(inputs[i].name) & disType == 'Src') { if (inputs[i].checked) valid = 1  }
        if (/^Truck/.test(inputs[i].name) & disType == 'Truck') { if (inputs[i].checked) valid = 1  }
    }
    return valid;
}


// Disabled and enables all selective mining in the 
// appropriate manner based on the status of the main check box.
function checkAllHaulage(obj)
{
  var checkboxs = document.getElementsByTagName('INPUT')
  var checkedState, disabledState
  disabledState = obj.checked
  checkedState = obj.checked
  
  for(var i=0;i<checkboxs.length;i++)
  {
    if (checkboxs[i].name.substring(0, 14) == 'SelectiveHaul_') 
    {
      checkboxs[i].checked = checkedState
      checkboxs[i].disabled = disabledState
    }
  }
  
  updateDisplay();
}

// Returns the number of selected haulage records
function SelectiveHaulageCount()
{
  var count = 0;
  var checkboxs = document.getElementsByTagName('INPUT')
  
  for(var i=0;i<checkboxs.length;i++)
  {
    if (checkboxs[i].name.substring(0, 14) == 'SelectiveHaul_') 
    {
      if (checkboxs[i].checked)
        count++;
    }
  }
  return count
}

// Adds up all the selected haualge tonnes and stores it in haualgeCheckedTonnes.
function calculateHaulageSum()
{
  var chkAllBox = document.getElementById('chkSelectiveEdit');
  var checkboxs = document.getElementsByTagName('INPUT')
  var haualgeTotal = 0;
  
  if (chkAllBox)
  {
    if (!chkAllBox.checked)
    {
      for(var i=0;i<checkboxs.length;i++)
      {
        if (checkboxs[i].name.substring(0, 14) == 'SelectiveHaul_') 
        { 
          if (checkboxs[i].parentElement.previousSibling.innerHTML != '' && checkboxs[i].checked)
          {
            haualgeTotal = haualgeTotal + parseFloat(checkboxs[i].parentElement.previousSibling.innerHTML.replace(',', ''));
          }
        }
      }

      haualgeCheckedTonnes = haualgeTotal;
    }
    else
      haualgeCheckedTonnes = null;
  }
}


// Update the 'Bulk Edit' Display controls.
function updateDisplay()
{
  var chkAllBox = document.getElementById('chkSelectiveEdit');
  var controlsExist = document.getElementById('divDescButtons');
  var displayHaulage = '';
  var descLine = '';
  var controlDisabled = true;
  var UsingSelectiveHaulage = false;
  if (chkAllBox) UsingSelectiveHaulage = !chkAllBox.checked
 
  // Only do the processing if some of the controls exist.
  if (controlsExist)
  {
    calculateHaulageSum();

    if (UsingSelectiveHaulage)
      displayHaulage = haualgeCheckedTonnes
    else if (hasHaulageData)
      displayHaulage = haulageSumTonnes
      
    if (boolFiltersChanged) {
      descLine = '<font color=red>The filters have been changed so the list must be refreshed.</font>';
      controlDisabled = true;
    }
    else if (UsingSelectiveHaulage) {
      descLine = 'These changes will be made only against checked haulage records in the table below.';
      controlDisabled = false;
    }
    else if (hasHaulageData) {
      descLine = 'These changes will be made to the table below.';
      controlDisabled = false;
    }
    else {
      descLine = 'Currently retrieving haulage data.';
      controlDisabled = true;
    }
      
    changeDisplay(controlDisabled, displayHaulage, descLine);
  }
}

// Update the display with the supplied paramters. Assist function of updateDisplay.
function changeDisplay(disableControls, haulageSumValue, lineMsg)
{
  var haulageSum = document.getElementById('haulageSum');
  var btnBulkDelete = document.getElementById('btnBulkDelete');
  var btnBulkUpdate = document.getElementById('btnBulkUpdate');
  var divDescButtons = document.getElementById('divDescButtons');

  if (haulageSum)
    haulageSum.innerHTML = '<b>Haulage Tonnes: </b>' + parseInt(haulageSumValue);
  
  if (btnBulkDelete)
    btnBulkDelete.disabled = disableControls;
  
  if (btnBulkUpdate)
    btnBulkUpdate.disabled = disableControls;
    
  if (divDescButtons)
    divDescButtons.innerHTML = lineMsg;
}