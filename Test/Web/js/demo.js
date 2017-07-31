//Reference Rail Car Scripts
function AddNewRailCar(){
	CallAjax('itemDetail', './ReferenceRailCarEdit.aspx');
	return false;
}

function AddNewRailCarType(){
	CallAjax('itemDetail', './ReferenceRailCarTypeEdit.aspx');
	return false;
}

function DeleteRailCar(TruckId, Description){
	ClearElement('itemDetail');
	
	if(confirm('Delete the rail car \'' + Description + '\'')){
		CallAjax('', './ReferenceRailCarDelete.aspx?TruckId=' + TruckId);
	}
	
	return false;
}

function DeleteRailCarType(TruckTypeId, Description){
	ClearElement('itemDetail');
	
	if(confirm('Delete the rail car type \'' + Description + '\'')){
		CallAjax('', './ReferenceRailCarTypeDelete.aspx?TruckTypeId=' + TruckTypeId);
	}
	
	return false;
}

function DeleteRailCarTypeFactorPeriod(TruckTypeId){
	CallAjax('', './ReferenceRailCarTypeFactorPeriodDelete.aspx?TruckTypeId=' + TruckTypeId);
	
	return false;
}

function EditRailCar(TruckId){
	CallAjax('itemDetail', './ReferenceRailCarEdit.aspx?TruckId=' + TruckId);
	return false;
}

function EditRailCarType(TruckTypeId){
	CallAjax('itemDetail', './ReferenceRailCarTypeEdit.aspx?TruckTypeId=' + TruckTypeId);
	return false;
}

function EditRailCarTypeFactorPeriod(TruckTypeId){
	CallAjax('TruckTypeFactorPeriodContainer', './ReferenceRailCarTypeFactorPeriodEdit.aspx?TruckTypeId=' + TruckTypeId);
	return false;
}

function GetRailCarTypeList(){
	CallAjax('TruckTypeContent', './ReferenceRailCarTypeList.aspx');
	return false;
}

function GetRailCarList(){
	CallAjax('TruckContent', './ReferenceRailCarList.aspx');
	return false;
}

function GetRailCarTypeFactorPeriodList(TruckTypeId){
	CallAjax('TruckTypeFactorPeriodListContainer', './ReferenceRailCarTypeFactorPeriodList.aspx?TruckTypeId=' + TruckTypeId);
	return false;
}

function GetRailCarTypeTabContent(){
	ClearElement('itemDetail');
	CallAjax('sidenav_layout_nav_container', './ReferenceRailCarTypeSideNavigation.aspx');
	if(document.getElementById('TruckTypeContent').innerHTML == ''){
		GetRailCarTypeList()
	}
	
	return false;
}

function GetRailCarTabContent(){
	ClearElement('itemDetail');
	CallAjax('sidenav_layout_nav_container', './ReferenceRailCarSideNavigation.aspx');
	if(document.getElementById('TruckContent').innerHTML == ''){
		GetRailCarList()
	}
	
	return false;
}