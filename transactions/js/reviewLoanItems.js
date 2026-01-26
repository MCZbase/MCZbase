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
function openRemoveLoanItemDialog(loan_item_id, dialogId, callback) { 
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
			loan_item_id: loan_item_id
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
	$("#"+targetDiv).html("Saving...");
	jQuery.ajax({
		url: "/transactions/component/itemFunctions.cfc",
		data : {
			method : "updateLoanItemDisposition",
			transaction_id: transaction_id,
			part_id: part_id,
			coll_obj_disposition: new_disposition,
			returnformat : "json",
			queryformat : 'column'
		},
		success: function (result) {
			if (typeof result == 'string') { result = JSON.parse(result); } 
			if (result.DATA.STATUS[0]==1) {
				$("#"+targetDiv).html(result.DATA.MESSAGE[0]);
			} else { 
				$("#"+targetDiv).html("Error");
			}
		},
		error: function (jqXHR, textStatus, error) {
			$("#"+targetDiv).html("Error");
			handleFail(jqXHR,textStatus,error,"updating the disposition for a loan item");
		},
		dataType: "html"
	});
};

function removeLoanItemFromLoan(loan_item_id,targetDiv,callback=null) { 
	$("#"+targetDiv).html("Saving...");
	jQuery.ajax({
		url: "/transactions/component/itemFunctions.cfc",
		data : {
			method : "removePartFromLoan",
			loan_item_id: loan_item_id,
			returnformat : "json",
			queryformat : 'column'
		},
		success: function (result) {
			if (typeof result == 'string') { result = JSON.parse(result); } 
			if (result.DATA.STATUS[0]==1) {
				if (typeof callback === 'function') {
					callback();
				}
				$("#"+targetDiv).html(result.DATA.MESSAGE[0]);
			} else { 
				$("#"+targetDiv).html("Error");
			}
		},
		error: function (jqXHR, textStatus, error) {
			$("#"+targetDiv).html("Error");
			handleFail(jqXHR,textStatus,error,"removing loan item from loan");
		},
		dataType: "html"
	});
};

/** Resolve a loan item, marking it as returned or consumed.
 *
 * @param loan_item_id the primary key for the loan item to resolve.
 * @param targetDiv the id of the div to update with the result of the operation.
 * @param loan_item_state the new state for the loan item, either 'returned' or 'consumed'.
 * @param callback a callback function to invoke on success.
 */
function resolveLoanItem(loan_item_id,targetDiv,loan_item_state,callback) { 
	$("#"+targetDiv).html("Saving...");
	jQuery.ajax({
		url: "/transactions/component/itemFunctions.cfc",
		data : {
			method : "markLoanItemResolved",
			loan_item_id: loan_item_id,
			loan_item_state: loan_item_state,
			returnformat : "json",
			queryformat : 'column'
		},
		success: function (result) {
			if (typeof callback === 'function') {
				callback();
			}
			if (typeof result == 'string') { result = JSON.parse(result); } 
			if (result.DATA.STATUS[0]==1) {
				$("#"+targetDiv).html(result.DATA.MESSAGE[0]);
			} else { 
				$("#"+targetDiv).html("Error");
			}
		},
		error: function (jqXHR, textStatus, error) {
			$("#"+targetDiv).html("Error");
			handleFail(jqXHR,textStatus,error,"removing loan item from loan");
		},
		dataType: "html"
	});
}

/** Create a dialog to add items to a loan 
 */
function openAddLoanItemDialog(guid,transaction_id, dialogId, callback) { 
	var title = "Add Part To Loan.";
	var content = '<div id="'+dialogId+'_div">Loading....</div>';
	var thedialog = $("#"+dialogId).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		minWidth: 600,
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
			method: 'getAddLoanItemDialogHtml',
			returnformat: "plain",
			collection_object_id: '',
			guid: guid,
			transaction_id: transaction_id
		},
		success: function(data) {
			$("#"+dialogId+"_div").html(data);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening add loan item dialog");
		}
	});
}

/** Add an item to a loan, creating a loan_item record linking a specimen part 
 * to a loan.
 *
 * @param part_id the collection_object_id of  the part to add to the loan.
 * @param transaction_id the transaction_id of the loan to add the part to.
 * @param remark any remark to associate with the loan item.
 * @param instructions any special instructions to associate with the loan item.
 * @param subsample boolean indicating whether the item is to be created as a subsample 
 *   of the specified part.
 * @param targetDiv the id of the div to update with the result of the operation.
 */
function addItemToLoan(part_id,transaction_id,remark,instructions,subsample,targetDiv) { 
	var subsampleInt = 0;
	if (subsample=="true" || subsample==1 || subsample=="1") {
		subsampleInt = 1;
	}
	$("#"+targetDiv).html("Saving...");
	jQuery.ajax({
		url: "/transactions/component/itemFunctions.cfc",
		data : {
			method : "addPartToLoan",
			transaction_id: transaction_id,
			part_id: part_id,
			remark: remark,
			instructions: instructions,
			subsample: subsampleInt,
			returnformat : "json",
			queryformat : 'column'
		},
		success: function (result) {
			if (typeof result == 'string') { result = JSON.parse(result); } 
			if (result.DATA.STATUS[0]==1) {
				$("#"+targetDiv).html(result.DATA.MESSAGE[0]);
			} else { 
				$("#"+targetDiv).html("Error");
			}
		},
		error: function (jqXHR, textStatus, error) {
			$("#"+targetDiv).html("Error");
			handleFail(jqXHR,textStatus,error,"adding a part as a loan item to a loan");
		},
		dataType: "html"
	});
};

/** openEditLoanItemDialog open a dialog for editing a loan item.
 *
 * @param loan_item_id the primary key for the loan item to edit.
 * @param dialogId the id in the dom for the div to turn into the dialog without 
 *  a leading # selector.
 * @param name text to display in the dialog title
 * @param callback a callback function to invoke on closing the dialog.
 */
function openLoanItemDialog(loan_item_id,dialogId,name,callback) {
   var title = "Edit " + name;
   createGenericEditDialog(dialogId,title,callback);
   jQuery.ajax({
      url: "/transactions/component/itemFunctions.cfc",
      data : {
         method : "getLoanItemDialogHtml",
         loan_item_id: loan_item_id
      },
      success: function (result) {
         $("#" + dialogId + "_div").html(result);
      },
      error: function (jqXHR, textStatus, error) {
         handleFail(jqXHR,textStatus,error,"opening edit loan item dialog");
      },
      dataType: "html"
   });
};

