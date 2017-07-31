// Location Picker
function locationFilter(id) {
    this.id = id;

}

function locationFilter_LoadNode(pickerId, locationJS, width, showLocationType, showNodeImage, autoSelectNode, lowestLocationTypeDescription) {
    var treeDiv = document.getElementById(pickerId + 'tree')
    var qryString = '?pickerId=' + pickerId;
    qryString += '&locationJavaScript=' + locationJS;
    qryString += '&Width=' + width;
    qryString += '&showLocationType=' + showLocationType;
    qryString += '&showNodeImage=' + showNodeImage;
    qryString += '&autoSelectNode=' + autoSelectNode;
    qryString += '&lowestLocationTypeDescription=' + lowestLocationTypeDescription;
    CallAjax(treeDiv.id, '../Internal/LocationPickerTree.aspx' + qryString, 'image');
}


// Static Javascript Functions
function locationFilter_LoadStatic(pickerId, locationJS, width, showLocationType, showNodeImage, autoSelectNode, lowestLocationTypeDescription) {
    locationFilter_LoadNode(pickerId, locationJS, width, showLocationType, showNodeImage, autoSelectNode, lowestLocationTypeDescription);
}

// Popup Javascript Functions
function locationFilter_Click(button, pickerId) {
    var div = document.getElementById(pickerId + 'div')
    var treeDiv = document.getElementById(pickerId + 'tree')

    if (div && treeDiv) {
        if (isButtonPressed(button)) {
            button.src = button.src.replace(button.imageDown, button.imageOver)
            button.src = button.src.replace(button.imageUp, button.imageOver)

            // Hide the tree
            div.style.visibility = 'hidden';
        }
        else {
            button.src = button.src.replace(button.imageOver, button.imageDown)
            button.src = button.src.replace(button.imageUp, button.imageDown)

            // Show the tree
            div.style.visibility = 'visible';

            div.style.left = getOffsetLeft(button);
            div.style.top = getOffsetTop(button) + button.height + 2;

            if (treeDiv.innerHTML == '') {
                CallAjax(treeDiv.id, '../Internal/LocationPickerTree.aspx?pickerId=' + pickerId, 'image');
            }
        }
    }
}

function isButtonPressed(button) {
    return (button.src.indexOf(button.imageDown) > -1)
}

function locationFilter_MouseOut(button) {
    button.src = button.src.replace(button.imageOver, button.imageUp)
}

function locationFilter_MouseOver(button) {
    button.src = button.src.replace(button.imageUp, button.imageOver)
}


function selectLocationPickerNode(locationId) {
    alert('location id : ' + locationId + ' selected.');
}

function getOffsetLeft(el) {
    var ol = el.offsetLeft;
    while ((el = el.offsetParent) != null)
        ol += el.offsetLeft;
    return ol;
}

function getOffsetTop(el) {
    var ot = el.offsetTop;
    while ((el = el.offsetParent) != null)
        ot += el.offsetTop;
    return ot;
}

// Tree Node Navigation
function ToggleLocationPickerNode(nodeRowId, nodeLevel, locationId, locationTypeId, locationJs, showNodeImage, pickerId, lowestType) {
    //If no hidden rows were found then we havent got this node through ajax yet
    if (!ToggleNode(nodeRowId)) {
        GetLocationPickerNode(nodeRowId, nodeLevel, locationId, locationTypeId, locationJs, showNodeImage, pickerId, lowestType );
    }
}

function GetLocationPickerNode(nodeRowId, nodeLevel, locationId, locationTypeId, locationJs, showNodeImage, pickerId, lowestType) {
    var qryStr = '../Internal/LocationPickerTreeNode.aspx?LocationId=' + locationId +
		'&LocationTypeId=' + locationTypeId +
		'&NodeLevel=' + nodeLevel +
        '&NodeRowId=' + nodeRowId +
        '&pickerId=' + pickerId +
        '&lowestLocationTypeDescription=' + lowestType;
    if (locationJs) {
        qryStr = qryStr + '&locationJavaScript=' + locationJs;
    }
    if (showNodeImage) {
        qryStr = qryStr + '&showNodeImage=' + showNodeImage;
    }

    CallAjax('itemStage', qryStr);
}

function AppendLocationPickerNodes(nodeRowId) {
    var stage = document.getElementById('StageTable');
    var curRow = document.getElementById(nodeRowId);
    var table = curRow.parentNode;

    AppendNodeRows(stage, table, curRow);

    document.getElementById('itemStage').innerHTML = '';
}