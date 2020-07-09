/**
 * Place scripts that should be available on all web pages for all users here.
*/

/** Creates a simple message dialog with an OK button.  Creates a new div, 
 * types it as a jquery-ui modal dialog and displays it.
 *
 * @param dialogText the text to place in the dialog.
 * @prarm dialogTitle
 */
function messageDialog(dialogText, dialogTitle) {
	var messageDialog = $('<div style="padding: 10px; max-width: 500px; word-wrap: break-word;">' + dialogText + '</div>').dialog({
		modal: true,
		resizable: false,
		draggable: true,
		width: 'auto',
		minHeight: 80,
		title: dialogTitle,
		buttons: {
			OK: function () {
				$(this).dialog('destroy');
			}
		},
		close: function() {
			$(this).dialog( "destroy" );
		},
		open: function (event, ui) { 
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
		} 
	});
	messageDialog.dialog('moveToTop');
};

/** Creates a simple confirm dialog with OK and cancel buttons.  Creates a new div, 
 * types it as a jquery-ui modal dialog and displays it, invokes the specified callback 
 * function when OK is pressed.
 *
 * @param dialogText the text to place in the dialog.
 * @prarm dialogTitle for the dialog header.
 * @param okFunction callback function to invoke upon a press of the OK button.
 */
function confirmDialog(dialogText, dialogTitle, okFunction) {
	$('<div style="padding: 10px; max-width: 500px; word-wrap: break-word;">' + dialogText + '</div>').dialog({
		modal: true,
		resizable: false,
		draggable: true,
		width: 'auto',
		minHeight: 80,
		title: dialogTitle,
		buttons: {
			OK: function () {
				 setTimeout(okFunction, 30);
				 $(this).dialog('destroy');
			},
			Cancel: function () {
				 $(this).dialog('destroy');
			}
		},
		close: function() {
			 $(this).dialog( "destroy" );
		}
	});
};


// Create a generic jquery-ui dialog that loads content from some page in an iframe and binds a callback
// function to the ok button.
//
// @param page uri for the page to load into the dialog
// @param id an id for a div on the calling page which will have its content replaced with the dialog, iframe 
//    in the dialog is also given the id {id}_iframe
// @param title to display in the dialog's heading
// @param okcallback callback function to execute when the OK button is clicked.
// @param dialogHeight the height of the dialog, 650 may be a good default value
// @param dialogWidth the width of the dialog, 800 may be a good default value
function opendialogcallback(page,id,title,okcallback,dialogHeight,dialogWidth) {
  var content = '<iframe style="border: 0px; " src="' + page + '" width="100%" height="100%" id="' + id +  '_iframe"></iframe>';
  var adialog = $("#"+id)
  .html(content)
  .dialog({
    title: title,
    autoOpen: false,
    dialogClass: 'dialog_fixed,ui-widget-header',
    modal: true,
    stack: true,
    zindex: 2000,
    height: dialogHeight,
    width: dialogWidth,
    minWidth: 400,
    minHeight: 450,
    draggable:true,
    buttons: {
        "Ok": function(){ if (jQuery.type(okcallback)==='function') okcallback();} ,
        "Cancel": function() {  $("#"+id).html('').dialog('destroy'); }
    }
  });
  adialog.dialog('open');
};

/** exportGridToCSV given the id of a jqxgrid control and a filename, export the coutent of the grid to a csv file
 * with the specified filename for direct download.
 * @param idOfGrid the id of the jqx grid control, without a leading # selector.
 * @param filename the filename to provide the user for the downloaded data.
 */
function exportGridToCSV (idOfGrid, filename) {
   var exportHeader = true;
   var rows = null; // null for all rows
   var exportHiddenColumns = true;
   var csvStringData = $('#' + idOfGrid).jqxGrid('exportdata', 'csv',null,exportHeader,rows,exportHiddenColumns);
   exportToCSV(csvStringData, filename);  
};

/** exportToCSV given csv data as from an exportdata from a jqxgrid, provide the data to the user for download 
 * with the specified filename.
 * @param csvStringData the csv data to export to a file.
 * @param filename the name to provide to the user for download of the data.
 */
function exportToCSV (csvStringData, filename) {
   var downloadLink = document.createElement("a");
   var csvblob = new Blob(["\ufeff", csvStringData]);
   var url = URL.createObjectURL(csvblob);
   downloadLink.href = url;
   downloadLink.download = filename;
   document.body.appendChild(downloadLink);
   downloadLink.click();
   document.body.removeChild(downloadLink);
}; 


/** Allow textarea controls to grow in size as text is entered into them 
 *  to bind to all textareas currently defined on a page use:
 *  $("textarea").keyup(autogrow);
*/
function autogrow (event) {
	$(this).css('overflow-y','hidden');  // temporarily hide the vertical scrollbar so as not to flash
	while($(this).outerHeight() < this.scrollHeight +
		parseFloat($(this).css("borderTopWidth")) +
		parseFloat($(this).css("borderBottomWidth"))) 
	{
	// increase the height until the text fits into the scroll bar height, taking borders into account.
	$(this).height($(this).height()+1);
	}
	$(this).css('overflow-y','auto');
};

/** Make a paired hidden agent_id and text agent_name control into an autocomplete agent picker
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected agent_id (without a leading # selector).
 */
function makeAgentPicker(nameControl, idControl) { 
	$('#'+nameControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/agents/component/search.cfc",
				data: { term: request.term, method: 'getAgentAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
					} else { 
						message = jqXHR.responseText;
					}
					messageDialog('Error:' + message ,'Error: ' + error);
				}
			})
		},
		select: function (event, result) {
			$('#'+idControl).val(result.item.id);
		},
		minLength: 3
	});
};

/**
 * Determine the largest z-index value currently on an element in the DOM.
 * 
 * @returns integer value for the current largest z-index value.
 */
function getMaxZIndex() { 
  return Math.max.apply(null, $.map($('body > *'), function (element,n) {  return parseInt($(element).css('z-index')) || 1 })); 
}

/**
 * Create a jquery-ui dialog to display row details for a jqxgrid.  Iterates through columns and 
 * a data record and displays a variable height dialog showing the columns and details as 
 * key-value pairs for a particular row index in the grid.
 *
 * in the grid definition include: 

			initrowdetails: initRowDetails,
			rowdetailstemplate: {
				rowdetails: "<div style='margin: 10px;'>Row Details</div>",
				rowdetailsheight:  1 // row details will be placed in popup dialog
			},

 * invoke from rowexpand event handler

      $('#searchResultsGrid').on('rowexpand', function (event) {
         //  Create a content div, add it to the detail row, and make it into a dialog.
         var args = event.args;
         var rowIndex = args.rowindex;
         var datarecord = args.owner.source.records[rowIndex];
         createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
      });

 * and from an initRowDetails function, bound to initrowdetails in the grid definition

      var initRowDetails = function (index, parentElement, gridElement, datarecord) {
         // could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
         var details = $($(parentElement).children()[0]);
         details.html("<div id='rowDetailsTarget" + index + "'></div>");

         createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index);
         // Workaround, expansion sits below row in zindex.
         var maxZIndex = getMaxZIndex();
         $(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
      }

 * destroy the resulting dialog from the rowcollapse event handler

      $('#searchResultsGrid').on('rowcollapse', function (event) {
         // remove the dialog holding the row details
         var args = event.args;
         var rowIndex = args.rowindex;
			// id for dialog is gridId + 'RowDetailsDialog", created in createRowDetailsDialog.
         $("#searchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
      });

 *
 *@param gridId the id, without a leading # selector for the grid. 
 *@param rowDetailsTargetId the id, without the leading # selector or the trailing rowid created in the initrowdetails function.
 *@param datarecord the jqxgrid datarecord.
 *@param rowIndex the row index for the selected grid row, available as index in initRowDetails() or event.args.rowIndex in rowexpand event handler.
 */
function createRowDetailsDialog(gridId, rowDetailsTargetId, datarecord,rowIndex) {
	var content = "<div id='" + gridId+  "RowDetailsDialog" + rowIndex + "'><ul>";
	var columns = $('#' + gridId).jqxGrid('columns').records;
	var gridWidth = $('#' + gridId).width();
	var dialogWidth = Math.round(gridWidth/2);
	if (dialogWidth < 150) { dialogWidth = 150; }
	for (i = 1; i < columns.length; i++) {
		var text = columns[i].text;
		var datafield = columns[i].datafield;
		var content = content + "<li><strong>" + text + ":</strong> " + datarecord[datafield] +  "</li>";
	}
	content = content + "</ul></div>";
	$("#" + rowDetailsTargetId + rowIndex).html(content);
	$("#"+ gridId +"RowDetailsDialog" + rowIndex ).dialog(
		{ 
			autoOpen: true, 
			buttons: [ { text: "Ok", click: function() { $( this ).dialog( "close" ); $("#" + gridId).jqxGrid('hiderowdetails',rowIndex); } } ],
			width: dialogWidth,
			title: 'Record Details'		
		}
	);
	// Workaround, expansion sits below row in zindex.
	var maxZIndex = getMaxZIndex();
	$("#"+gridId+"RowDetailsDialog" + rowIndex ).parent().css('z-index', maxZIndex + 1);
};

/** function countCharsLeft count the characters available for data entry in an input
 * (typically a text area) and report used and remaining characters as the content of
 * a specified control. Example use bound to onkeyup event of a textarea:
 * 
 	<label for="remarks" id="remarks_label">Remarks (<span id="length_remarks"></span>)</label>
 	<textarea id="remarks" name="remarks" class="data-entry-textarea mt-1"
 		onkeyup="countCharsLeft('remarks',4000,'length_remarks');"
 		rows="3" aria-labelledby="remarks_label" ></textarea>
 *
 * @param elementid the id without a # selector for the input to count characters in.
 * @param maxsize the maximum number of allowed characters in elementid.
 * @param outputelementid the id without a # selector for the dom element to display
 *  the results.
 */
function countCharsLeft(elementid, maxsize, outputelementid){ 
	var current = $('#'+elementid).val().length;
	var remaining = maxsize - current;
	var result = current + " characters, " + remaining + " left";
	$('#'+outputelementid).html(result);
}
