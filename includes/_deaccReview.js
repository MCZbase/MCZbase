function updateCondition (partID) {
var s = "document.getElementById('condition" + partID + "').value";
	var condition = eval(s);
	var transaction_id = document.getElementById('transaction_id').value;
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
function success_updateCondition (r) {
	var result=r.DATA;
	var partID = result.PART_ID;
	var message = result.MESSAGE;
	//alert(partID);
	//alert(message);
	if (message == 'success') {
		var ins = "document.getElementById('condition" + partID + "')";
		var condition = eval(ins);
		condition.className = '';
	} else {
		alert('An error occured: \n' + message);
	}
}
function updateDeaccItemRemarks ( partID ) {
	var s = "document.getElementById('deacc_Item_Remarks" + partID + "').value";
	var loan_Item_Remarks = eval(s);
	var transaction_id = document.getElementById('transaction_id').value;
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "updateDeaccItemRemarks",
			part_id : partID,
			transaction_id : transaction_id,
			loan_item_remarks : deacc_Item_Remarks,
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
	//alert(partID);
	//alert(message);
	if (message == 'success') {
		var ins = "document.getElementById('deacc_Item_Remarks" + partID + "')";
		var deacc_Item_Remarks = eval(ins);
		deacc_Item_Remarks.className = '';
	} else {
		alert('An error occured: \n' + message);
	}
}
function remPartFromDeacc( partID ) {
	var s = "document.getElementById('coll_obj_disposition" + partID + "')";
	var dispnFld = eval(s);
	var thisDispn = dispnFld.value;
	var isS = "document.getElementById('isSubsample" + partID + "')";
	var isSslFld = eval(isS);
	varisSslVal = isSslFld.value;
	var transaction_id = document.getElementById('transaction_id').value;
	if (varisSslVal > 0) {
		var m = "Would you like to DELETE this subsample? \n OK: permanently remove from database \n Cancel: remove from loan";
		var answer = confirm (m);
		if (answer) {
			jQuery.getJSON("/component/functions.cfc",
				{
					method : "del_remPartFromDeacc",
					part_id : partID,
					transaction_id : transaction_id,
					returnformat : "json",
					queryformat : 'column'
				},
				success_remPartFromDeacc
			);
		} else {
			if (thisDispn <> 'in collection') {
				alert('The part cannot be removed because the disposition is "on loan".');
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
	} else if (thisDispn == 'on loan') {
		alert('That part cannot be removed because the disposition is "Deaccessioned".');
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
function success_remPartFromLoan (r) {
	var result=r.DATA;
	var partID = result.PART_ID;
	var message = result.MESSAGE;
	if (message == 'success') {
		var tr = "document.getElementById('rowNum" + partID + "')";
		var theRow = eval(tr);
		theRow.style.display='none';
	} else {
		alert('An error occured: \n' + message);
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
		alert('An error occured:\n' + disposition);
	}
}