/**
 * Place scripts that should be available on all web pages for all users here.
*/

/** Make some readable content for a message dialog from an error message,
 * message may be empty, in which case placeholder text is returned, message
 * may start with the coldfusion responseText for a server error of <!-- \" --->,
 * which renders the text unreadable, response in that case is the error text, with
 * html markup stripped out, trimming all before the phrase 'Error Occurred While 
 * Processing Request', otherwise returns the provided message.
 * @param message the error message to clean up.
 * @return the error message cleaned up to be visible in a message dialog.
 */
function prepareErrorMessage(message) { 
	var result = "";
	if (message) { 
		result = message;
	} else { 
		result = "No Error Message Text";
		message = "No Error Message Text";
	}
	if (message.indexOf('<!-- \" --->')>-1) {
		result = message.replace(/<\/?[^>]+(>|$)/g, "");
		if (result.indexOf("Error Occurred While Processing Request") > -1) { 
			result = result.substr(result.indexOf("Error Occurred While Processing Request")+40);
			if (result.indexOf("Error Occurred While Processing Request") > -1) { 
				result = result.substr(result.indexOf("Error Occurred While Processing Request"));
			}
		}
	}
	return result;
}

/** Creates a simple message dialog with an OK button.  Creates a new div, 
 * types it as a jquery-ui modal dialog and displays it.
 *
 * @param dialogText the text to place in the dialog.
 * @prarm dialogTitle
 */
function messageDialog(dialogText, dialogTitle) {
	if (!dialogTitle) { dialogTitle = "Error"; } 
	console.log(dialogTitle);
	if (dialogTitle=="Internal Server Error" && dialogText=="") { 
		// internal server errors cause duplicate copies of message dialog to launch, one containing the message, one without
		// supress the one without, but log to console.
		console.log("messageDialog invoked with no message text");
	} else { 
		// normal case, display a dialog with the message.
		var titleTrimmed = dialogTitle.substring(0,50);
		var messageDialog = $('<div style="padding: 10px; max-width: 500px; word-wrap: break-word;">' + dialogText + '</div>').dialog({
			modal: true,
			resizable: false,
			draggable: true,
			width: 'auto',
			minHeight: 80,
			title: titleTrimmed,
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
	}
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
	var confirmDialog = $('<div style="padding: 10px; max-width: 500px; word-wrap: break-word;">' + dialogText + '</div>').dialog({
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
		},
		open: function (event, ui) { 
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
		} 
	});
	confirmDialog.dialog('moveToTop');
};

/** Creates a simple confirm dialog with OK and cancel buttons.  Creates a new div, 
 * types it as a jquery-ui modal dialog styled as a warning and displays it, invokes 
 * the specified callback function when OK is pressed.
 *
 * @param dialogText the text to place in the dialog.
 * @prarm dialogTitle for the dialog header.
 * @param okFunction callback function to invoke upon a press of the OK button.
 */
function confirmWarningDialog(dialogText, dialogTitle, okFunction) {
	var confirmDialog = $('<div style="padding: 10px; max-width: 500px; word-wrap: break-word;">' + dialogText + '</div>').dialog({
		modal: true,
		resizable: false,
		draggable: true,
		width: 'auto',
		minHeight: 80,
		title: dialogTitle,
		classes: {
			"ui-dialog-titlebar": "bg-danger",
			"ui-dialog-title": "text-light"
		},
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
		},
		open: function (event, ui) { 
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
		} 
	});
	confirmDialog.dialog('moveToTop');
};


function confirmDelete(formName,msg){
	console.log('TODO: use confirmDialog instead of confirmDelete.');
	// TODO: Old code, don't use, rewrite invocations to use confirmDialog instead. 
	// var formName;var msg=msg||"this record";
	// confirmWin=windowOpener("/includes/abort.cfm?formName="+formName+"&msg="+msg,"confirmWin","width=200,height=150,resizable")
}


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
    minWidth: 375,
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
	var exportTo = null; // null to export to local variable
   var exportHiddenColumns = true;
	var csvStringData = $('#' + idOfGrid).jqxGrid('exportdata', 'csv', exportTo ,exportHeader,rows,exportHiddenColumns);
   exportToCSV(csvStringData, filename);  
};

/** exportToCSV given csv data as from an exportdata from a jqxgrid, provide the data to the user for download 
 * with the specified filename.
 * @param csvStringData the csv data to export to a file.
 * @param filename the name to provide to the user for download of the data.
 */
function exportToCSV (csvStringData, filename) {
   var downloadLink = document.createElement("a");
   var csvblob = new Blob(["\ufeff", csvStringData],{type: 'text/csv;charset=utf-8'});
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
/*
function autogrow (event) {
	// this fails in Firefox 78, while loop does not seem to be recognizing changing outerHeight
	$(this).css('overflow-y','hidden');  // temporarily hide the vertical scrollbar so as not to flash
	while( 
		($(this).outerHeight() < $(this)[0].scrollHeight +
		parseFloat($(this).css("borderTopWidth")) +
		parseFloat($(this).css("borderBottomWidth"))
		) && $(this).height()<400 ) 
	{
		// increase the height until the text fits into the scroll bar height, taking borders into account.
		$(this).height($(this).height()+2);
	}
	$(this).css('overflow-y','auto');
};
*/

/** Allow textarea controls to grow in size as text is entered into them 
 *  to bind to all textareas currently defined on a page use:
 *  $("textarea").keyup(autogrow);
*/
function autogrow (event) {
	var tb = parseFloat($(this).css("borderTopWidth"));
	var bb = parseFloat($(this).css("borderBottomWidth"));
	$(this).css('overflow-y','hidden');  // temporarily hide the vertical scrollbar so as not to flash
	if ( Math.ceil($(this).outerHeight()) < $(this)[0].scrollHeight + tb + bb )       
	{
		// estimate how much height is needed for the textarea to contain all its text 
		// calcluate the length of the string in em.
		var em = $(this).val().length * parseInt(window.getComputedStyle(document.getElementsByTagName('html')[0])['fontSize']);
		var width = $(this).width();
		var fontsize = Number.parseFloat($(this).css("font-size"));
		// calculate how many lines the string needs from its length in em/sreen width, floor and add 1 to ensure a minimum of 1 line.
		var lines = Math.floor(em/width)+1;  
		var newlines = $(this).val().split("\n").length-1; // number of new line characters in the string.
		lines=newlines+lines;  // add estimated lines for the characters plus the number of newlines 
		lines=lines+2; // add two lines to ensure blank space at the end
		// calculate how many pixels are needed to fit the text plus newlines.
		// we won't increase the size of the text area over this needs estimate.
		var needs = lines*fontsize;
		// if our calculation failed or if the height is less that the estimaged needed height, increase the height.
		// this if statement is needed as some browsers with some fonts appear to provide an overestimate of 
		// scrollHeight plus top/bottom borders and end up growing with each keystroke.
		if (Number.isNaN(needs) || $(this)[0].scrollHeight+tb+bb < needs) { 
			// increase the height such that the text fits into the scroll bar height, taking borders into account.
			$(this).height($(this)[0].scrollHeight+tb+bb);
		}
	}
	$(this).css('overflow-y','auto');
};

// function noenter prevents form submission when a user presses enter from a specific field.
// example:
//<input type="text" name="idBy" class="reqdClr" size="50" 
//	  onchange="getAgent('newIdById','idBy','newID',this.value); return false;"
//	  onKeyPress="return noenter(event);"> 
// note the '(event)' bit - that's required for FireFox to process this correctly
function noenter (e) 
	{
	var key;
	var keychar;
	var reg;
	
	if(window.event) {
		// for IE, e.keyCode or window.event.keyCode can be used
		key = e.keyCode; 
	}
	else if(e.which) {
		// netscape
		key = e.which; 
	}
	if (key == 13) {
			// enter
			return false;
	}
}

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
               } else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
                  message = ' Backing method did not return JSON.';
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

/** Make a paired hidden agent_id and text agent_name control into an autocomplete agent picker that displays meta 
 *  on picklist and value on selection.
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected agent_id (without a leading # selector).
 */
function makeAgentAutocompleteMeta(nameControl, idControl) { 
	$('#'+nameControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/agents/component/search.cfc",
				data: { term: request.term, method: 'getAgentAutocompleteMeta' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
               } else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
                  message = ' Backing method did not return JSON.';
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
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta "matched name * (preferred name)" instead of value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** Make a set of hidden agent_id and text agent_name, agent link control, and agent icon controls into an 
 *  autocomplete agent picker.  Not intended for use to pick agents for transaction roles where agent flags may apply.
 *  
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected agent_id (without a leading # selector).
 *  @param iconControl the id for an input that can take a background color to indicate a successfull pick of an agent
 *    (without an leading # selector)
 *  @param linkControl the id for a page element that can contain a hyperlink to an agent, by agent id.
 *  @param agentID null, or an id for an agent, if an agentid value is provided, then the idControl, linkControl, and
 *    iconControl are initialized in a picked agent state.
 */
function makeRichAgentPicker(nameControl, idControl, iconControl, linkControl, agentId) { 
	makeConstrainedRichAgentPicker(nameControl, idControl, iconControl, linkControl, agentId, '');
};

/** Make a set of hidden agent_id and text agent_name, agent link control, and agent icon controls into an 
 *  autocomplete agent picker, with a limitation on which agents are shown to agents relevant to the context,
 *  Not intended for use to pick agents for transaction roles where agent flags may apply
 *  
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected agent_id (without a leading # selector).
 *  @param iconControl the id for an input that can take a background color to indicate a successfull pick of an agent
 *    (without an leading # selector)
 *  @param linkControl the id for a page element that can contain a hyperlink to an agent, by agent id.
 *  @param agentID null, or an id for an agent, if an agentid value is provided, then the idControl, linkControl, and
 *    iconControl are initialized in a picked agent state.
 *  @param the constraint to place on which agents are returned, see getAgentAutocompleteMeta for supported values
 */
function makeConstrainedRichAgentPicker(nameControl, idControl, iconControl, linkControl, agentId, constraint) { 
	// initialize the controls for appropriate state given an agentId or not.
	if (agentId) { 
		$('#'+idControl).val(agentId);
		$('#'+iconControl).addClass('bg-lightgreen');
		$('#'+iconControl).removeClass('bg-light');
		$('#'+linkControl).html(" <a href='/agents/Agent.cfm?agent_id=" + agentId + "' target='_blank'>View</a>");
		$('#'+linkControl).attr('aria-label', 'View details for this agent');
	} else {
		$('#'+idControl).val("");
		$('#'+iconControl).removeClass('bg-lightgreen');
		$('#'+iconControl).addClass('bg-light');
		$('#'+linkControl).html("");
		$('#'+linkControl).removeAttr('aria-label');
	}
	$('#'+nameControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/agents/component/search.cfc",
				data: { 
					term: request.term, 
					constraint: constraint, 
					method: 'getAgentAutocompleteMeta' 
				},
				dataType: 'json',
				success : function (data) { 
					// return the result to the autocomplete widget, select event will fire if item is selected.
					response(data); 
				},
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
               } else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
                  message = ' Backing method did not return JSON.';
					} else { 
						message = jqXHR.responseText;
					}
					messageDialog('Error:' + message ,'Error: ' + error);
					$('#'+idControl).val("");
					$('#'+iconControl).removeClass('bg-lightgreen');
					$('#'+iconControl).addClass('bg-light');
					$('#'+linkControl).html("");
					$('#'+linkControl).removeAttr('aria-label');
				}
			})
		},
		select: function (event, result) {
			// Handle case of a selection from the pick list.  Indicate successfull pick.
			$('#'+idControl).val(result.item.id);
			$('#'+linkControl).html(" <a href='/agents/Agent.cfm?agent_id=" + result.item.id + "' target='_blank'>View</a>");
			$('#'+linkControl).attr('aria-label', 'View details for this agent');
			$('#'+iconControl).addClass('bg-lightgreen');
			$('#'+iconControl).removeClass('bg-light');
		},
		change: function(event,ui) { 
			if(!ui.item){
				// handle a change that isn't a selection from the pick list, clear the controls.
				$('#'+idControl).val("");
				$('#'+nameControl).val("");
				$('#'+iconControl).removeClass('bg-lightgreen');
				$('#'+iconControl).addClass('bg-light');	
				$('#'+linkControl).html("");
				$('#'+linkControl).removeAttr('aria-label');
			}
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta "matched name * (preferred name)" instead of value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** Make a paired hidden agent_id and text agent_name control into an autocomplete agent picker, intended for use
 *  with agent controls on searches, to limit selections to relevant agent names.
 *
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected agent_id (without a leading # selector).
 *  @param constraint to limit the agents returned, see getAgentAutocompleteMeta for supported values
 */
function makeConstrainedAgentPicker(nameControl, idControl, constraint) { 
	$('#'+nameControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/agents/component/search.cfc",
				data: { 
					term: request.term, 
					method: 'getAgentAutocompleteMeta',
					constraint: constraint
					 },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
               } else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
                  message = ' Backing method did not return JSON.';
					} else { 
						message = jqXHR.responseText;
					}
					messageDialog('Error:' + message ,'Error: ' + error);
				}
			})
		},
		select: function (event, result) {
			// Handle case of a selection from the pick list, set value in id control
			$('#'+idControl).val(result.item.id);
		},
		change: function(event,ui) { 
			if(!ui.item){
				// handle a change that isn't a selection from the pick list, clear the id control.
				$('#'+idControl).val("");
			}
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta "matched name * (preferred name)" instead of value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
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
			

/** Make a paired hidden underscore_collection_id and text collection_name control into an autocomplete agent picker
 *     the underscore_collection_id control is optional, and can be left off on a search form that can take a free text
 *     search term.
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the optional id for a hidden input that is to hold the selected id (without a leading # selector),
 *    use null if there is no control to hold the selected underscore_collection_id (as in a search widget).
 */
function makeNamedCollectionPicker(nameControl,idControl) {
   $('#'+nameControl).autocomplete({
      source: function (request, response) {
         $.ajax({
            url: "/grouping/component/search.cfc",
            data: { term: request.term, method: 'getNamedCollectionAutocomplete' },
            dataType: 'json',
            success : function (data) { response(data); },
            error : function (jqXHR, textStatus, error) {
               var message = "";
               if (error == 'timeout') {
                  message = ' Server took too long to respond.';
               } else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
                  message = ' Backing method did not return JSON.';
               } else {
                  message = jqXHR.responseText;
               }
					console.log(error);
               messageDialog('Error:' + message ,'Error: ' + error);
            }
         })
      },
      select: function (event, result) {
			if (idControl) { 
				// if idControl is non null, non-empty, non-false
				$('#'+idControl).val(result.item.id);
			}
      },
      minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta "collection name * (description)" instead of value in picklist.
		return $("<li>").append("<span>" + item.value + " (" + item.meta + ")</span>").appendTo(ul);
	};
};

/** Make a paired hidden publication_id and text publication_name control into an autocomplete publication picker
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected publication_id (without a leading # selector).
 */
function makePublicationPicker(nameControl, idControl) { 
	$('#'+nameControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/publications/component/search.cfc",
				data: { term: request.term, method: 'getPublicationAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
               } else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
                  message = ' Backing method did not return JSON.';
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

	})._renderItem = function(ul, item) {
		// lets lines wrap so that each full citation is visible in dropdown
		return $("<li>").append("<span>" + item.value + "</span>").appendTo(ul);
	};
};

/** 
 * function handleFail general handler for ajax fail methods.
 *	fail: function(jqXHR,textStatus,error){
 *		handleFail(jqXHR,textStatus,error,"removing media from transaction record");
 *	}
 * @param jqXHR error object from ajax fail invocation
 * @param textStatus error status value from ajax fail invocation
 * @param error error value from ajax fail invocation
 * @param context text added by calling fail implementation to indicate the origin of the message. 
 */
function handleFail(jqXHR,textStatus,error,context) { 
	var message = "";
	if (error == 'timeout') {
		message = ' Server took too long to respond.';
	} else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
		message = ' Backing method did not return JSON.';
	} else {
		if (jqXHR.responseText == jqXHR.statusText) {
			message = jqXHR.statusText;
		} else { 
			message = prepareErrorMessage(jqXHR.responseText) + ' ' + jqXHR.statusText;
		}
	}
	var details = 'Error:' + context + ': ' + message;
	console.log(details);
	if (!error) { error = ""; } 
	messageDialog(details, 'Error: '+error.toString().substring(0,50));
}

/** Make a paired hidden id and text name control into an autocomplete publication picker.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected publication_id (without a leading # selector).
 */
function makePublicationAutocompleteMeta(valueControl, idControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/publications/component/search.cfc",
				data: { term: request.term, method: 'getPublicationAutocompleteMeta' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
					} else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
						message = ' Backing method did not return JSON.';
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
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** Make a paired hidden id and text name control into an autocomplete project picker.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected publication_id (without a leading # selector).
 */
function makeProjectAutocompleteMeta(valueControl, idControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/projects/component/search.cfc",
				data: { term: request.term, method: 'getProjectAutocompleteMeta' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
               } else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
                  message = ' Backing method did not return JSON.';
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
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** Make a paired hidden id and text name control into an autocomplete specimen (cataloged item, by guid)  picker.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected collection_object_id (without a leading # selector).
 */
function makeCatalogedItemAutocompleteMeta(valueControl, idControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/specimens/component/search.cfc",
				data: { term: request.term, method: 'getCatalogedItemAutocompleteMeta' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
               } else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
                  message = ' Backing method did not return JSON.';
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
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** Make a paired hidden id and text name control into an autocomplete locality picker.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected collection_object_id (without a leading # selector).
 */
function makeLocalityAutocompleteMeta(valueControl, idControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/specimens/component/search.cfc",
				data: { term: request.term, method: 'getLocalityAutocompleteMeta' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
               } else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
                  message = ' Backing method did not return JSON.';
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
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** Make a paired hidden id and text name control into an autocomplete collecting event picker.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected collection_object_id (without a leading # selector).
 */
function makeCollectingEventAutocompleteMeta(valueControl, idControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/specimens/component/search.cfc",
				data: { term: request.term, method: 'getCollectingEventAutocompleteMeta' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
               } else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
                  message = ' Backing method did not return JSON.';
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
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** Make a paired hidden id and text name control into an autocomplete scientific name picker
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected collection_object_id (without a leading # selector).
 */
function makeScientificNameAutocompleteMeta(valueControl, idControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/taxonomy/component/search.cfc",
				data: { term: request.term, method: 'getScientificNameAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
               } else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
                  message = ' Backing method did not return JSON.';
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
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** makeTaxonAutocomplete make an input control into a picker for a taxon field of arbitrary rank.
 *  This version of the function does not prefix the selected value with an = for exact match search.
 * @param fieldId the id for the input without a leading # selector.
 * @param targetRank the taxonomic rank (field in taxonomy.cfm, including author_text as an option)
 *  to bind the autocomplete to.  
 * @see makeTaxonSearchAutocomplete
**/
function makeTaxonAutocomplete(fieldId, targetRank) { 
	jQuery("#"+fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/taxonomy/component/search.cfc",
				data: { term: request.term, method: 'getHigherRankAutocomplete', rank: targetRank },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a taxon autocomplete");
				}
			})
		},
		minLength: 3
	}).autocomplete( "instance" )._renderItem = function( ul, item ) {
		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
	};
};
/** makeTaxonSearchAutocomplete make an input control into a picker for a taxon field of arbitrary rank.
 *  This version of the function prefixes the selected value with an = for exact match search, and is
 *  intended as a picker for taxon search fields.
 * @param fieldId the id for the input without a leading # selector.
 * @param targetRank the taxonomic rank (field in taxonomy.cfm, including author_text as an option)
 *  to bind the autocomplete to.  
 * @see makeTaxonAutocomplete
**/
function makeTaxonSearchAutocomplete(fieldId, targetRank) { 
	jQuery("#"+fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/taxonomy/component/search.cfc",
				data: { term: request.term, method: 'getHigherRankAutocomplete', rank: targetRank },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a taxon search autocomplete");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+fieldId).val("=" + result.item.value);
		},
		minLength: 3
	}).autocomplete( "instance" )._renderItem = function( ul, item ) {
		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
	};
};


/** function getColumnVisibilities obtain the current set of hidden properties for a search results grid
 in the form of an object containing key value pairs where the key is the datafield name for the column
 and the value is the value of the hidden column property for that column.
 @param gridId the id for the jqxGrid object in the dom for which to obtain the columns without a 
	leading # selector (typically searchResultsGrid)
 @return an object with datafields as keys and hidden properies as values.
 @see setColumnVisibilities
**/
function getColumnVisibilities(gridId) { 
	var hiddenValues = new Object();
	var cols = $('#' + gridId).jqxGrid('columns').records;
	var numcols = cols.length
	for (i=0; i<numcols; i++) {
		var field = cols[i].datafield;
		if (field) { 
			var hiddenvalue = $('#'+gridId).jqxGrid('getcolumnproperty',field,'hidden');
			hiddenValues[field] = hiddenvalue;
		}
	}
	return hiddenValues;
};

/** function setColumnVisibilities update hidden column properties for a search results grid.
 @param targetGridId the id for the jqxGrid object in the dom for which to set the hidden
	properties of the columns, without leading # selector (typically searchResultsGrid)
 @param fieldHiddenValues an object with datafields as keys and hidden properies as values.
 @see setColumnVisibilities
 @see getColHidProp
 @deprecated set properties in grid creation with getColHidProp instead
**/
function setColumnVisibilities(fieldHiddenValues,targetGridId) {
	$('#'+targetGridId).jqxGrid('beginupdate',true)
	for (field in fieldHiddenValues) { 
		if ($('#'+targetGridId).jqxGrid('getcolumn',field)!==null) { 
			if (fieldHiddenValues[field]==true) {
				if ($('#'+targetGridId).jqxGrid('getcolumnproperty',field,'hidable')==true) { 
					$('#'+targetGridId).jqxGrid('hidecolumn',field);
				}
			} else {
				$('#'+targetGridId).jqxGrid('showcolumn',field);
			}
		}
	}
	$('#'+targetGridId).jqxGrid('endupdate')
};

/** saveColumnVisibilities persist the grid column hidden properties in the database 
 * @param page the page on which the grid for which to save the column hidden properites appears.
 * @param fieldHiddenValues an object containing key value pairs where the key is a datafield and the
 *  value is the hidden property for that datafield in a grid's properties, this would be expected
 *  to be the window.columnHiddenSettings global variable.
 * @param label the label for the user's configuration of visible grid columns on that page, default
 *  value is Default
 * @param feeebackdiv optional, the id for a page element which can display feedback from the save, without 
 *  a leading # selector.
 */
function saveColumnVisibilities(pageFilePath,fieldHiddenValues,label,feedbackDiv) { 
	if (typeof feedbackDiv !== 'undefined') { 
		$('#'+feedbackDiv).html('Saving...');
	}
	if (typeof fieldHiddenValues === 'undefined') { 
		messageDialog("Error saving column visibilities: columnHiddenSettings object was not passed in ","Error: saving column visibilities.");
	}
	var settings = JSON.stringify(fieldHiddenValues);
	if (settings=="") { settings = "{}"; } 
	console.log(settings);
	jQuery.ajax({
		dataType: "json",
		url: "/shared/component/functions.cfc",
		data: { 
			method : "saveGridColumnHiddenSettings",
			page_file_path: pageFilePath,
			columnhiddensettings: settings,
			label: label,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			if (typeof feedbackDiv !== 'undefined') { 
				$('#'+feedbackDiv).html('Error.');
			}
			messageDialog("Error saving column visibilities: " + status + " " + jqXHR.responseText ,'Error: '+ status);
		},
		success: function (result) {
			if (typeof feedbackDiv === 'undefined') { 
				console.log(result.DATA.MESSAGE[0]);
			} else { 
				$('#'+feedbackDiv).html(result.DATA.MESSAGE[0]);
			}
		}
	});
}

/** lookupColumnVisibilities retrieve the persisted grid column hidden properties from the database 
 * @param page the page on which the grid for which to load the column hidden properites appears.
 * @param label the label for the user's configuration of visible grid columns on that page, default
 *  value is Default
 */
function lookupColumnVisibilities (pageFilePath,label) { 
	jQuery.ajax({
		dataType: "json",
		url: "/shared/component/functions.cfc",
		data: { 
			method : "getGridColumnHiddenSettings",
			page_file_path: pageFilePath,
			label: label,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error looking up column visibilities: " + status + " " + jqXHR.responseText ,'Error: '+ status);
		},
		success: function (result) {
			console.log(result[0]);
			var settings = result[0];
			if (typeof settings !== "undefined" && settings!=null) { 
				window.columnHiddenSettings = JSON.parse(settings.columnhiddensettings);
			}
		}
	});
}

// return either the value of the hidden property for the provided column from columnHiddenSettings
// or if none is set, the provided default value.
function getColHidProp(columnName, defaultValue) { 
	if (window.columnHiddenSettings.hasOwnProperty(columnName)) { 
		return window.columnHiddenSettings[columnName];
	} else {
		return defaultValue
	}
}
