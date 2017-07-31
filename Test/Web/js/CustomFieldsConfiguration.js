//Custom Fields Configuration Scripts

// Tab
function GetCustomFieldsLocationsTabContent() {
    if (document.getElementById('locationsContent').innerHTML == '')
    {
    CallAjax('locationsContent', './CustomFieldsLocations.aspx', 'image');
    }
    return false;
}

function GetCustomFieldsColorsTabContent() {
    if (document.getElementById('colorsContent').innerHTML == '')
    {
        GetCustomFieldsColorsDetails();
    }
    return false;
}

function GetCustomFieldsLocationColorTabContent() {
    if (document.getElementById('locationColorsContent').innerHTML == '') {
        GetCustomFieldsLocationColorsDetails();
    }
    return false;
}

function GetCustomFieldsMessagesTabContent() {
    if (document.getElementById('messagesContent').innerHTML == '') {
        GetCustomFieldsMessagesDetails();
    }
    return false;
}

function GetCustomFieldsStockpileTabContent() {
    if (document.getElementById('stockpileContent').innerHTML == '') {
        GetCustomFieldsStockpileDetails();
    }
    return false;
}

// Custom Fields - Location Colors Tab


function LoadLocationColorsDetails(locationId) {
    var qrystr = '?LocationId=' + locationId;
    CallAjax('locationColorsDetails', './CustomFieldsLocationColorsDetails.aspx' + qrystr, 'image');
    return false;
}

function SaveLocationsColor() {
    SubmitForm('LocationColorCustomFields', '', './CustomFieldsLocationColorsDetailsSave.aspx');
    return false;
}

// Custom Fields - Colors Tab
function GetCustomFieldsColorsDetails() {
    CallAjax('colorsContent', './CustomFieldsColors.aspx', 'image');
    return false;
}


function GetCustomFieldsLocationColorsDetails() {
    CallAjax('locationColorsContent', './CustomFieldsLocationColors.aspx', 'image');
    return false;
}

function GetCustomFieldsMessagesDetails() {
    CallAjax('messagesContent', './CustomFieldsMessages.aspx', 'image');
    return false;
}


function GetCustomFieldsMessagesList() {
    CallAjax('listMessagesDiv', './CustomFieldsMessagesDetails.aspx', 'image');
    ClearElement('saveMessagesDiv');
    return false;
}

function GetCustomFieldsMessagesEdit(messageName) {
    //Select the right tab.
    tpgMessages.select();
    
    //Wait a couple of seconds for the list to populate.
    CallAjax('saveMessagesDiv', './CustomFieldsMessagesDetailsEdit.aspx?Name='+messageName, 'image');
    return false;
}

function GetCustomFieldsMessagesDelete(messageName) {
    CallAjax('saveMessagesDiv', './CustomFieldsMessagesDetailsDelete.aspx?Name=' + messageName, 'image');
    return false;
}

function GetCustomFieldsMessagesActivate(messageName,activated) {
    CallAjax('listMessagesDiv', './CustomFieldsMessagesDetailsActivate.aspx?Name=' + messageName + '&Activated=' + activated, 'image');
    GetCustomFieldsMessagesList();
    return false;
}



function SaveCustomFieldsColors() {
    SubmitForm('detailsForm', '', './CustomFieldsColorsSave.aspx');
    return false;
}

function PreviewCustomFieldColour(colourCtrl) {
    var colour = colourCtrl.options[colourCtrl.selectedIndex].value;
    var thatchCell = document.getElementById(colourCtrl.id + 'Thatch');
    thatchCell.style.backgroundColor = colour;
}


function PreviewCustomFieldLineStyle(lineStyleCtrl) {
    var lineStyle = lineStyleCtrl.options[lineStyleCtrl.selectedIndex].value;
    var previewImage = document.getElementById(lineStyleCtrl.id + 'Preview');
    previewImage.src = '../images/linestyle_' + lineStyle.toLowerCase() + '.gif';
}

function PreviewCustomFieldMarkerShape(markerShapeCtrl) {
    var markerShape = markerShapeCtrl.options[markerShapeCtrl.selectedIndex].value;
    var previewImage = document.getElementById(markerShapeCtrl.id + 'Preview');
    previewImage.src = '../images/marker_' + markerShape.toLowerCase() + '.gif';
}

// Custom Fields - Locations Tab


function GetCustomFieldsStockpileDetails() {
    CallAjax('stockpileContent', './CustomFieldsStockpile.aspx', 'image');
    return false;
}

function LoadLocationsStockpileDetails(locationId) {
    var qrystr = '?LocationId=' + locationId;
    CallAjax('stockpileDetails', './CustomFieldsStockpileDetails.aspx' + qrystr, 'image');
    return false;
}

function SaveStockpileImageLocation() {
    AIM.submit(document.getElementById('stockpileCustomFields'), './CustomFieldsStockpileDetailsSave.aspx', { 'onComplete': LoadStockpileImage });
    document.getElementById('SaveOrDeleteAction').value = 'Save';
    document.getElementById('stockpileCustomFields').submit();
    return true;
}

function DeleteStockpileImageLocation() {
    if (confirm('Are you sure you wish to delete the stockpile image?')) {
        AIM.submit(document.getElementById('stockpileCustomFields'), './CustomFieldsStockpileDetailsSave.aspx?Remove=True', { 'onComplete': LoadStockpileImage });
        document.getElementById('SaveOrDeleteAction').value = 'Delete';
        document.getElementById('stockpileCustomFields').submit();
    }
    return true;
}

function LoadStockpileImage(response) {
    try {
        eval(response);
    } catch (err) {
    }
    var locationId = document.getElementById('locationId').value;
    //CallAjax('stockpileImageContent','../Internal/StockpileImageLoaderPage.aspx?height=75&locationId='+locationId);
}
// Custom Fields - Reporting Thresholds Locations Tab

function LoadLocationsDetails(locationId) {
    var qrystr = '?LocationId=' + locationId;
    var threshold = document.getElementById('thresholdFactorSelect');
    if (threshold)
    {
        qrystr = qrystr + '&ThresholdFactor=' + threshold.value;
    }
    
    CallAjax('locationsDetails', './CustomFieldsLocationsDetails.aspx' + qrystr, 'image');
    return false;
}

function ApplyThresholdSettings(locationId, thresholdTypeId) {
    var qrystr = '?ApplyThreshold=true&LocationId=' + locationId + '&ThresholdTypeId=' + thresholdTypeId;
    SubmitForm('ThresholdForm', '', './CustomFieldsLocationsDetailsSave.aspx' + qrystr);
    return false;
}

function RemoveThresholdOverride(locationId, thresholdTypeId) {
    var qrystr = '?ResetThreshold=true&LocationId=' + locationId + '&ThresholdTypeId=' + thresholdTypeId;
    SubmitForm('ThresholdForm', '', './CustomFieldsLocationsDetailsSave.aspx' + qrystr);
    return false;
}


// Location Picker JS
function GetCustomFieldsLocationsTree() {
    CallAjax('locationsTree', './CustomFieldsLocationsTree.aspx', 'image');
    return false;
}

function ToggleLocationTreeNode(nodeRowId, nodeLevel, locationId) {
    //If no hidden rows were found then we havent got this node through ajax yet
    if (!ToggleNode(nodeRowId)) {
        GetLocationTreeNode(nodeRowId, nodeLevel, locationId);
    }
}

function AppendLocationTreeNodes(nodeRowId) {
    var stage = document.getElementById('StageTable');
    var curRow = document.getElementById(nodeRowId);
    var table = curRow.parentNode;

    AppendNodeRows(stage, table, curRow);

    document.getElementById('itemStage').innerHTML = '';
}

function GetLocationTreeNode(nodeRowId, nodeLevel, locationId) {
    var qryStr = './CustomFieldsLocationsTreeNode.aspx?NodeRowId=' + nodeRowId +
        '&NodeLevel=' + nodeLevel +
		'&LocationId=' + locationId;

    CallAjax('itemStage', qryStr);
}
