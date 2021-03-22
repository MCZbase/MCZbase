/*
transactions/js/reviewLoanItems.js

scripts to support transactions/reviewLoanItems.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2021 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/
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
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"updating part condition for a loan");
	});
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
function updateLoanItemRemarks ( partID ) {
	var s = "document.getElementById('loan_Item_Remarks" + partID + "').value";
	var loan_Item_Remarks = eval(s);
	var transaction_id = document.getElementById('transaction_id').value;
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "updateLoanItemRemarks",
			part_id : partID,
			transaction_id : transaction_id,
			loan_item_remarks : loan_Item_Remarks,
			returnformat : "json",
			queryformat : 'column'
		},
		success_updateLoanItemRemarks
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"updating item remarks for a loan item");
	});
}
function success_updateLoanItemRemarks (r) {
	var result=r.DATA;
	var partID = result.PART_ID;
	var message = result.MESSAGE;
	//alert(partID);
	//alert(message);
	if (message == 'success') {
		var ins = "document.getElementById('loan_Item_Remarks" + partID + "')";
		var loan_Item_Remarks = eval(ins);
		loan_Item_Remarks.className = '';
	} else {
		alert('An error occured: \n' + message);
	}
}
function updateInstructions ( partID ) {
	var s = "document.getElementById('item_instructions" + partID + "').value";
	var item_instructions = eval(s);
	var transaction_id = document.getElementById('transaction_id').value;
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "updateInstructions",
			part_id : partID,
			transaction_id : transaction_id,
			item_instructions : item_instructions,
			returnformat : "json",
			queryformat : 'column'
		},
		success_updateInstructions
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"updating instructions for a loan item");
	});
}
function success_updateInstructions (r) {
	var result=r.DATA;
	var partID = result.PART_ID;
	var message = result.MESSAGE;
	if (message == 'success') {
		var ins = "document.getElementById('item_instructions" + partID + "')";
		var item_instructions = eval(ins);
		item_instructions.className = '';
	} else {
		alert('An error occured: \n' + message);
	}
}
function remPartFromLoan( partID ) {
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
					method : "del_remPartFromLoan",
					part_id : partID,
					transaction_id : transaction_id,
					returnformat : "json",
					queryformat : 'column'
				},
				success_remPartFromLoan
			).fail(function(jqXHR,textStatus,error){
				handleFail(jqXHR,textStatus,error,"deleting subsampled loan item");
			});
		} else {
			if (thisDispn == 'on loan') {
				alert('The part cannot be removed because the disposition is "on loan".');
			} else {
				jQuery.getJSON("/component/functions.cfc",
					{
						method : "remPartFromLoan",
						part_id : partID,
						transaction_id : transaction_id,
						returnformat : "json",
						queryformat : 'column'
					},
					success_remPartFromLoan
				).fail(function(jqXHR,textStatus,error){
					handleFail(jqXHR,textStatus,error,"removing subsampled item from loan");
				});
			}
		}
	} else if (thisDispn == 'on loan') {
		alert('That part cannot be removed because the disposition is "on loan".');
	} else {
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "remPartFromLoan",
				part_id : partID,
				transaction_id : transaction_id,
				returnformat : "json",
				queryformat : 'column'
			},
			success_remPartFromLoan
		).fail(function(jqXHR,textStatus,error){
			handleFail(jqXHR,textStatus,error,"removing item from loan")
		});
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
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"updating item disposition for loan")
	});
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
