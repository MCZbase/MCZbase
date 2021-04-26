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
function openRemoveLoanItemDialog(part_id, transaction_id, dialogId, callback) { 
	var title = "Remove Part from Loan.";
	var content = '<div id="'+dialogId+'_div">Loading....</div>';
	var thedialog = $("#"+dialogId).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		minWidth: 550,
		minHeight: 200,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$(this).dialog('close');
				//$("#"+dialogId).dialog('close');
			}
		},
		open: function (event, ui) {
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
		},
		close: function(event,ui) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
			$("#"+dialogId+"_div").html("");
			$("#"+dialogId).empty();
			try {
				$("#"+dialogId).dialog('destroy');
			} catch (err) {
				console.log(err);
			}
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/transactions/component/itemFunctions.cfc",
		type: "get",
		data: {
			method: 'getRemoveLoanItemDialogContent',
			returnformat: "plain",
			part_id: part_id,
			transaction_id: transaction_id
		},
		success: function(data) {
			$("#"+dialogId+"_div").html(data);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening remove loan item dialog");
		}
	});
}

function updateLoanItemDisposition(part_id, transaction_id, new_disposition,targetDiv) { 
	jQuery.ajax({
		url: "/transactions/component/itemFunctions.cfc",
		data : {
			method : "updateLoanItemDisposition",
			transaction_id: transaction_id,
			part_id: part_id,
			coll_obj_disposition: new_disposition
		},
		success: function (result) {
			$("#"+targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"obtaining restrictions and agreed benefits for a borrow");
		},
		dataType: "html"
	});
};

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
