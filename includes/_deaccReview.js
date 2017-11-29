function updateCondition (partID) {
	var condition = $('#condition' + partID).val();
        if (!condition || 0 === condition.length) {
		messageDialog('You must supply a value for condition.','Error');
        } else {
		var transaction_id = $('transaction_id').val();
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "updateCondition",
				part_id : partID,
				condition : condition,
				returnformat : "json",
				queryformat : 'column'
			},
			success_updateCondition
		);
 	}
}
function success_updateCondition (r) {
	var result=r.DATA;
	var partID = result.PART_ID;
	var message = result.MESSAGE;
	if (message == 'success') {
		var ins = "document.getElementById('condition" + partID + "')";
		var condition = eval(ins);
		condition.className = 'reqdClr';
	} else {
		messageDialog('An error occured: \n' + message,'Error');
	}
}
function updateDeaccItemRemarks ( partID ) {
	var s = "document.getElementById('deacc_Item_Remarks" + partID + "').value";
	var deacc_Item_Remarks = eval(s);
	var transaction_id = document.getElementById('transaction_id').value;
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "updateDeaccItemRemarks",
			part_id : partID,
			transaction_id : transaction_id,
			deacc_item_remarks : deacc_Item_Remarks,
			returnformat : "json",
			queryformat : 'column'
		},
		success_updateDeaccItemRemarks
	);
}
function success_updateDeaccItemRemarks (r) {
	var result=r.DATA;
	var partID = result.PART_ID;
	var message = result.MESSAGE;
	if (message == 'success') {
		var ins = "document.getElementById('deacc_Item_Remarks" + partID + "')";
		var deacc_Item_Remarks = eval(ins);
		deacc_Item_Remarks.className = '';
	} else {
		messageDialog('An error occured: \n' + message,'Error');
	}
}
function updateDeaccItemInstructions ( partID ) {
	var s = "document.getElementById('item_instructions" + partID + "').value";
	var deacc_Item_Instructions = eval(s);
	var transaction_id = document.getElementById('transaction_id').value;
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "updateDeaccItemInstructions",
			part_id : partID,
			transaction_id : transaction_id,
			item_instructions : deacc_Item_Instructions,
			returnformat : "json",
			queryformat : 'column'
		},
		success_updateDeaccItemInstructions
	);
}
function success_updateDeaccItemInstructions (r) {
	var result=r.DATA;
	var partID = result.PART_ID;
	var message = result.MESSAGE;
	if (message == 'success') {
		var ins = "document.getElementById('item_instructions" + partID + "')";
		var deacc_Item_Instructions = eval(ins);
		deacc_Item_Instructions.className = '';
	} else {
		messageDialog('An error occured: \n' + message,'Error');
	}
}
function remPartFromDeacc( partID, collObjectID ) {
	var s = "document.getElementById('coll_obj_disposition" + partID + "')";
	var dispnFld = eval(s);
	var thisDispn = dispnFld.value;
	var isS = "document.getElementById('isSubsample" + partID + "')";
	var isSslFld = eval(isS);
	varisSslVal = isSslFld.value;
	var transaction_id = document.getElementById('transaction_id').value;
	if (varisSslVal > 0) {
		var dialogText = "Would you like to remove this subsample from the Deaccession?  If you do, check the parts and part counts for the <a href='/SpecimenDetail.cfm?collection_object_id=" + collObjectID +  "' target='_blank'>cataloged item</a> when done, you may wish to manually merge the subsample part back into its parent lot.";
                confirmAction(dialogText, "Remove subsample from Deaccession", function(){ remPartFromDeaccSubsample(thisDispn,partID,transaction_id) } );
	} else if (thisDispn != 'in collection') {
		messageDialog('That part cannot be removed because the disposition is not "in collection".','Unable to remove part.');
	} else {
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "remPartFromDeacc",
				part_id : partID,
				transaction_id : transaction_id,
				returnformat : "json",
				queryformat : 'column'
			},
			success_remPartFromDeacc
		);
	}
}
function remPartFromDeaccSubsample(thisDispn,partID,transaction_id) { 
	if (thisDispn != 'in collection') {
		messageDialog('The part cannot be removed because the disposition is not "in collection".','Unable to remove part.');
	} else {
		jQuery.getJSON("/component/functions.cfc",
		{
		method : "remPartFromDeacc",
		part_id : partID,
		transaction_id : transaction_id,
		returnformat : "json",
		queryformat : 'column'
		},
		success_remPartFromDeacc
		);
	}
}
function success_remPartFromDeacc (r) {
	var result=r.DATA;
	var partID = result.PART_ID;
	var message = result.MESSAGE;
	if (message == 'success') {
		var tr = "document.getElementById('rowNum" + partID + "')";
		var theRow = eval(tr);
		theRow.style.display='none';
	} else {
		messageDialog('An error occured: \n' + message,'Error');
	}
}
function updateDispn( partID ) {
	var s = "document.getElementById('coll_obj_disposition" + partID + "')";
	var dispnFld = eval(s);
	var thisDispn = dispnFld.value;
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "updatePartDisposition",
			part_id : partID,
			disposition : thisDispn,
			returnformat : "json",
			queryformat : 'column'
		},
		success_updateDispn
	);
}
function success_updateDispn (r) {
	var result=r.DATA;
	var partID = result.PART_ID;
	var status = result.STATUS;
	var disposition = result.DISPOSITION;
	if (status == 'success') {
		var s = "document.getElementById('coll_obj_disposition" + partID + "')";
		var dispnFld = eval(s);
		dispnFld.className='';
	} else {
		messageDialog('An error occured: \n' + message,'Error');
	}
}
