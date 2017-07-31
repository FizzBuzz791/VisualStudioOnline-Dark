function GetPurgeAdministrationList() {
   
    if (typeof (CallAjax) == 'function') {
        CallAjax('itemList', './PurgeAdministrationList.aspx');
    } else {
        alert('Unable to get purge list');
    }
}

function ShowPurgeRequestAddForm() {
    if (typeof (CallAjax) == 'function') {
        CallAjax('itemDetail', './PurgeAdministrationAdd.aspx');
    } else {
        alert('Unable to show purge add form');
    }
}

function CancelPurgeRequest() {
    $('#itemDetail').html('');
}

function FinishedSavingPurgeRequest() {
    CancelPurgeRequest();
    GetPurgeAdministrationList();
}

function CancelPurgeRequestSubmission(requestId) {
    if (typeof (CallAjax) == 'function') {
            var payload = { RequestId: Array(requestId, false) };
            CallAjax('itemDetail', './PurgeAdministrationCancel.aspx', '', 'GetPurgeAdministrationList()', payload);
    } else {
        alert('Unable to cancel purge request submission');
    }
}

function ApprovePurgeRequest(requestId) {
    if (typeof (CallAjax) == 'function') {
        // show confirmation dialog
        if (confirm('Are you sure you wish to approve this Purge?\r\n\r\nBefore approving a Purge you should ensure that appropriate backup operations and other pre-purge steps have been performed.')) {
            var payload = { RequestId: Array(requestId, false) };
            CallAjax('itemDetail', './PurgeAdministrationApprove.aspx', '', 'GetPurgeAdministrationList()', payload);
        }
    } else {
        alert('Unable to approve request');
    }

}


function SavePurgeRequest() {
    if (typeof (CallAjax) == 'function') {
        var payload = { SelectedMonth: Array($('#Months').val(), false) };
        CallAjax('itemDetail', './PurgeAdministrationSave.aspx', '', 'FinishedSavingPurgeRequest()', payload);
    } else {
        alert('Unable to save purge request');
    }   
}



