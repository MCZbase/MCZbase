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
 * types it as a jquery-ui modal dialog and displays it, invokes the specified callback 
 * function when OK is pressed, or an alternative callback if canceled or closed.
 *
 * @param dialogText the text to place in the dialog.
 * @prarm dialogTitle for the dialog header.
 * @param okFunction callback function to invoke upon a press of the OK button.
 * @param cancelFunction callback function to invoke upon a press of the Cancel button.
 */
function confirmOrCancelDialog(dialogText, dialogTitle, okFunction, cancelFunction) {
	var confirmDialog = $('<div style="padding: 10px; max-width: 500px; word-wrap: break-word;">' + dialogText + '</div>').dialog({
		modal: true,
		resizable: false,
		draggable: true,
		width: 'auto',
		minHeight: 80,
		title: dialogTitle,
		buttons: {
			OK: function () {
				if (jQuery.type(okFunction)==='function') {
					okFunction();
				} 
				cancelFunction = "";
				$(this).dialog('destroy');
			},
			Cancel: function () {
				if (jQuery.type(cancelFunction)==='function') {
					cancelFunction();
				} 
				cancelFunction = "";
				$(this).dialog('destroy');
			}
		},
		close: function() {
			if (jQuery.type(cancelFunction)==='function') {
				cancelFunction();
			} 
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
    dialogClass: 'ui-widget-header',
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

/** Make a paired hidden agent_id and text agent_name control into an autocomplete agent picker, where an agent_name
 *  must be selected from the list.
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a (hidden or not) input that is to hold the selected agent_id (without a leading # selector).
 */
function makeAgentPicker(nameControl, idControl) { 
	$('#'+nameControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/agents/component/search.cfc",
				data: { term: request.term, method: 'getAgentAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up agents for an agent picker");
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
				// and clear the name control, so that e.g. a search cannot be run on a text substring
				$('#'+nameControl).val("");
			}
		},
		minLength: 3
	});
};

/** Make a paired hidden agent_id and text agent_name control into an autocomplete agent picker that displays meta 
 *  on picklist and value on selection.
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected agent_id (without a leading # selector).
 *  @param clear, optional, default false, set to true for data entry controls to clear both controls when change
 *   is made other than selection from picklist.
 *  @see makeAgentAutocompleteMetaID to include agent_id in metadata.
 */
function makeAgentAutocompleteMeta(nameControl, idControl, clear=false) { 
	$('#'+nameControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/agents/component/search.cfc",
				data: { term: request.term, method: 'getAgentAutocompleteMeta' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up agents for an autocomplete");
				}
			})
		},
		select: function (event, result) {
			$('#'+idControl).val(result.item.id);
		},
		change: function(event,ui) { 
			if(!ui.item && clear){
				// handle a change that isn't a selection from the pick list, clear both controls.
				$('#'+idControl).val("");
				$('#'+nameControl).val("");
			} else if(!ui.item && !clear){
				// support use with searches
				// handle a change that isn't a selection from the pick list, clear just the id control.
				$('#'+idControl).val("");
			}
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
 *  Not intended for use to pick agents for transaction roles where agent flags may apply, also not intended
 *  for use in searches where a substring may apply, as fields are all cleared on edit not on list.
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
	makeConstrainedRichAgentPickerConfig(nameControl, idControl, iconControl, linkControl, agentId, constraint,true);
}
/** as makeConstraineRichAgentPicker but configurable to not clear for use with searches
 *  @param clear boolean if true clear controls when not selecting from the picklist, if false then 
 *    leave the value in nameControl but clear the other controls.
 */
function makeConstrainedRichAgentPickerConfig(nameControl, idControl, iconControl, linkControl, agentId, constraint, clear) { 
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
			if(!ui.item && clear){
				// handle a change that isn't a selection from the pick list, clear the controls.
				$('#'+idControl).val("");
				$('#'+nameControl).val("");
				$('#'+iconControl).removeClass('bg-lightgreen');
				$('#'+iconControl).addClass('bg-light');	
				$('#'+linkControl).html("");
				$('#'+linkControl).removeAttr('aria-label');
			} else if(!ui.item && !clear){
				// support use with searches
				// handle a change that isn't a selection from the pick list, clear the controls.
				$('#'+idControl).val("");
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
 *  with agent controls on searches, to limit selections to relevant agent names, but to allow a text value not on
 *  the list without an id value, as in a name substring.
 *
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected agent_id (without a leading # selector).
 *  @param constraint to limit the agents returned, see getAgentAutocompleteMeta for supported values
 */
function makeConstrainedAgentPicker(nameControl, idControl, constraint) {
	makeConstrainedAgentPickerConfig(nameControl, idControl, constraint, false); 
} 
	 
/** Make a paired hidden agent_id and text agent_name control into an autocomplete agent picker, intended for use
 *  with agent controls for editing or searches, to limit selections to relevant agent names, configurable to allow 
 *  a text value not on the list without an id value, as in a name substring, or to only support selections from the 
 *  picklist.
 *
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected agent_id (without a leading # selector).
 *  @param constraint to limit the agents returned, see getAgentAutocompleteMeta for supported values
 *  @param clearBoth boolean if true clear both controls when not selecting from the picklist, if false then 
 *    leave the value in nameControl but clear the id control.
 */
function makeConstrainedAgentPickerConfig(nameControl, idControl, constraint, clearBoth) { 
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
			if (!ui.item && clearBoth) {
				// handle a change that isn't a selection from the pick list, clear the controls.
				$('#'+idControl).val("");
				$('#'+nameControl).val("");
			} else if(!ui.item) {
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
 *@param omitArray optional array of datarecord keys (columns) to omit from the display.
 */
function createRowDetailsDialog(gridId, rowDetailsTargetId, datarecord,rowIndex, omitArray = []) {
	var content = "<div id='" + gridId+  "RowDetailsDialog" + rowIndex + "'><ul>";
	var columns = $('#' + gridId).jqxGrid('columns').records;
	var gridWidth = $('#' + gridId).width();
	var dialogWidth = Math.round(gridWidth/2);
	if (dialogWidth < 150) { dialogWidth = 150; }
	for (i = 1; i < columns.length; i++) {
		var text = columns[i].text;
		var datafield = columns[i].datafield;
		if (!omitArray || !omitArray.includes(datafield)) { 
			content = content + "<li><strong>" + text + ":</strong> " + datarecord[datafield] +  "</li>";
		}
	}
	content = content + "</ul></div>";
	$("#" + rowDetailsTargetId + rowIndex).html(content);
	$("#"+ gridId +"RowDetailsDialog" + rowIndex ).dialog(
		{ 
			autoOpen: true, 
			closeOnEscape: true,
			buttons: [ { text: "Ok", click: function() { $( this ).dialog( "close" ); } } ],
			width: dialogWidth,
			title: 'Record Details'		
		}
	);
	$("#"+ gridId +"RowDetailsDialog" + rowIndex ).on("dialogclose", function(event,ui) { 
		$("#" + gridId).jqxGrid('hiderowdetails',rowIndex); 
		try { 
			$("#"+ gridId +"RowDetailsDialog" + rowIndex ).dialog("destroy");
		} catch(error) {}
	});
	$("#"+ gridId +"RowDetailsDialog" + rowIndex ).dialog("moveToTop");
	// Workaround, expansion sits below row in zindex.
	var maxZIndex = getMaxZIndex();
	$("#"+gridId+"RowDetailsDialog" + rowIndex ).parent().css('z-index', maxZIndex + 1);
};

/** function createRowDetailsDialogNoBlanks works as createRowDetailsDialog, but leaves out fields 
  for which there is no value in the specified rowIndex.

  @see createRowDetailsDialog
*/
function createRowDetailsDialogNoBlanks(gridId, rowDetailsTargetId, datarecord,rowIndex) {
	var content = "<div id='" + gridId+  "RowDetailsDialog" + rowIndex + "'><ul>";
	var columns = $('#' + gridId).jqxGrid('columns').records;
	var gridWidth = $('#' + gridId).width();
	var dialogWidth = Math.round(gridWidth/2);
	if (dialogWidth < 150) { dialogWidth = 150; }
	for (i = 1; i < columns.length; i++) {
		var text = columns[i].text;
		var datafield = columns[i].datafield;
		if (datarecord[datafield]) { 
			content = content + "<li><strong>" + text + ":</strong> " + datarecord[datafield] +  "</li>";
		}
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
 *  @param clear optional if true (default) clear both name and id controls if change is not a selection from the pick list.
 *    if false, then just clear the idControl if the value is not a selection from the pick list to support search 
 *    on substrings.
 */
function makeNamedCollectionPicker(nameControl,idControl,clear=true) {
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
		change: function(event,ui) { 
			if(!ui.item && clear){
				// handle a change that isn't a selection from the pick list, clear both controls
				$('#'+idControl).val("");
				$('#'+nameControl).val("");
			} else if(!ui.item && !clear){
				// just clear the id control
				$('#'+idControl).val("");
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


/** Make a text name control into an autocomplete media_id picker, with media metadata displayed in the autocomplete.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 */
function makeMediaPickerOneControlMeta(valueControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/media/component/search.cfc",
				data: { term: request.term, method: 'getMediaAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up media for a media_id picker");
				}
			})
		},
		select: function (event, result) {
			$('#'+valueControl).val(result.item.id);
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};
/** Make a text name control into an autocomplete media_id picker, with media metadata displayed in the autocomplete,
 * includes media type and mime type in the metadata, can be limited by media_type.
 *
 *  @param type the type of media record to limit to, use empty value for no limitation.
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 */
function makeRichMediaPickerOneControlMeta(valueControl,typeLimit) { 
	if (!typeLimit) { 
		typeLimit = "";
	} 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/media/component/search.cfc",
				data: { 
					term: request.term, 
					type: typeLimit,
					method: 'getRichMediaAutocomplete' 
				},
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up media for a media_id picker");
				}
			})
		},
		select: function (event, result) {
			$('#'+valueControl).val(result.item.id);
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};
/** Make a text name control and media_id control into an autocomplete media_id picker, 
 *  with media metadata displayed in the autocomplete,
 *  includes media type and mime type in the metadata, can be limited by media_type.
 *
 *  @param type the type of media record to limit to, use empty value for no limitation.
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for an input that is to be the media_id field (without a leading # selector).
 */
function makeRichMediaPickerControlMeta(valueControl,idControl,typeLimit) { 
	if (!typeLimit) { 
		typeLimit = "";
	} 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/media/component/search.cfc",
				data: { 
					term: request.term, 
					type: typeLimit,
					method: 'getRichMediaAutocomplete' 
				},
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up media for a media_id picker");
				}
			})
		},
		select: function (event, result) {
			$('#'+valueControl).val(result.item.value);
			$('#'+idControl).val(result.item.id);
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** Make a paired hidden id and text name control into an autocomplete media license picker.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected license_id (without a leading # selector).
 */
function makeLicenseAutocompleteMeta(valueControl, idControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/media/component/search.cfc",
				data: { term: request.term, method: 'getLicenseAutocompleteMeta' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up licenses for a license picker");
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
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up publications for a publication picker");
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
/** Make a text name control into an autocomplete journal picker.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 */
function makeJournalAutocomplete(valueControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/vocabularies/component/search.cfc",
				data: { term: request.term, method: 'getJournalAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up journals for a journal picker");
				}
			})
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** Make a text name control into an autocomplete type status picker.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 */
function makeTypeStatusSearchAutocomplete(valueControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/publications/component/search.cfc",
				data: { term: request.term, method: 'getTypeStatusSearchAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up type status");
				}
			})
		},
		minLength: 3
	});
};
/** Make a text name control into an autocomplete doi picker.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 */
function makeDOIAutocomplete(valueControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/publications/component/search.cfc",
				data: { term: request.term, method: 'getDOIAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up DOIs for a doi picker");
				}
			})
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
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a project autocomplete");
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
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up cataloged items");
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
function makeLocalityAutocompleteMeta(valueControl, idControl, selectCallback=null) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/specimens/component/search.cfc",
				data: { term: request.term, method: 'getLocalityAutocompleteMeta' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up localities for a locality picker");
				}
			})
		},
		select: function (event, result) {
			$('#'+idControl).val(result.item.id);
			if (jQuery.type(selectCallback)==='function') {
				selectCallback();
			}
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
 *  @param limitType limitation to apply to the matches
 */
function makeLocalityAutocompleteMetaLimited(valueControl, idControl, limitType, selectCallback=null) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/specimens/component/search.cfc",
				data: { 
					term: request.term, 
					limitType: limitType,
					method: 'getLocalityAutocompleteMeta'
				 },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up localities for a locality picker");
				}
			})
		},
		select: function (event, result) {
			$('#'+idControl).val(result.item.id);
			if (jQuery.type(selectCallback)==='function') {
				selectCallback();
			}
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
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up collecting events for a collecting event picker");
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

/** Make a text control into an autocomplete part name  picker.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 */
function makePartNameAutocompleteMeta(valueControl ) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/specimens/component/search.cfc",
				data: { term: request.term, method: 'getPartNameAutocompleteMeta' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up part names for a part name picker");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+valueControl).val("=" + result.item.value);
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** Make a text control into an autocomplete specimen relationship picker.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 */
function makeBiolIndivRelationshipAutocompleteMeta(valueControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/vocabularies/component/search.cfc",
				data: { term: request.term, method: 'getBiolIndivRelationshipAutocompleteMeta' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up relationships for a biol_indiv_relations picker");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+valueControl).val("=" + result.item.value);
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** Make a text control into an autocomplete preserve method picker.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 */
function makePreserveMethodAutocompleteMeta(valueControl ) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/specimens/component/search.cfc",
				data: { term: request.term, method: 'getPreserveMethodAutocompleteMeta' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up part names for a preserve method picker");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+valueControl).val("=" + result.item.value);
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** Make a paired hidden id and text name control into an autocomplete scientific name picker
 *  intended for use on searches, to allow selection of scientific names, but to allow a text value not on
 *  the list without an id value, as in a name substring.
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
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a scientific name autocomplete");
				}
			})
		},
		select: function (event, result) {
			$('#'+idControl).val(result.item.id);
		},
		change: function (event, ui) {
			// clear the id control if the action wasn't a selection of an item on the list
			if(!ui.item){ 
				$('#'+idControl).val("");
			}
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};
/** Make a text name control into an autocomplete scientific name picker, displays authorship in meta, but not in selection
 * intended for use with a scientific name search, prepends = to input control on selection from picklist.
 *
 *  @param include_authorship if false, matched value is just the scientific_name, otherwise scientific_name plus author_text.
 *  @param scope allows limitation to some use of taxonomy records, see getScientificNameAutocomplete method documentation
 *    for supported values of scope.
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 */
function makeScientificNameAutocomplete(valueControl, include_authorship, scope) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/taxonomy/component/search.cfc",
				data: { 
					term: request.term, 
					include_authorship: include_authorship,
					scope: scope,
					method: 'getScientificNameAutocomplete' 
				},
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a scientific name autocomplete");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+valueControl).val("=" + result.item.value);
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

/** makeCTFieldSearchAutocomplete make an input control into a picker for a code table 
 *  where the code table name matches the field name.
 *  Prefixes the selected value with an = for exact match search, and is
 *  intended as a picker for code table controlled search fields.
 * @param fieldId the id for the input without a leading # selector.
 * @param codetable the name of the codetable and field without a leading CT.
**/
function makeCTFieldSearchAutocomplete(fieldId,codetable) { 
	jQuery("#"+fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/vocabularies/component/search.cfc",
				data: { 
					term: request.term, 
					codetable: codetable, 
					method: 'getCTAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a code table search autocomplete");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+fieldId).val("=" + result.item.value);
		},
		minLength: 1
	}).autocomplete( "instance" )._renderItem = function( ul, item ) {
		return $("<li>").append( "<span>" + item.value + "</span>").appendTo( ul );
	};
};


/** makeCTOtherIDTypeAutocomplete make an input control into a picker for 
 *  CTCOLL_OTHER_ID_TYPE (where the matched field is OTHER_ID_TYPE)
 *  Prefixes the selected value with an = for exact match search, and is
 *  intended as a picker for the code table controlled search field.
 * @param fieldId the id for the input without a leading # selector.
**/
function makeCTOtherIDTypeAutocomplete(fieldId) { 
	jQuery("#"+fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/vocabularies/component/search.cfc",
				data: { 
					term: request.term, 
					codetable: 'COLL_OTHER_ID_TYPE', 
					method: 'getCTAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a CTCOLL_OTHER_ID_TYPE search autocomplete");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+fieldId).val("=" + result.item.value);
		},
		minLength: 1
	}).autocomplete( "instance" )._renderItem = function( ul, item ) {
		return $("<li>").append( "<span>" + item.value + "</span>").appendTo( ul );
	};
};

/** makeSpecLocalitySearchAutocomplete make an input control into a picker for a spec_locality field.
 *  Prefixes the selected value with an = for exact match search, and is
 *  intended as a picker for spec_locality search fields.
 * @param fieldId the id for the input without a leading # selector.
**/
function makeSpecLocalitySearchAutocomplete(fieldId) { 
	jQuery("#"+fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/localities/component/search.cfc",
				data: { term: request.term, method: 'getSpecLocalityAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a spec_locality search autocomplete");
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

/** makeHigherGeogAutocomplete make an input control into a picker for paried higher_geog 
 *  and geog_auth_rec_id fields.
 *  This version of the function uses the value as returned and is intended for 
 *  intended as a picker for data entry and exact matching, and clears both inputs if a value is not selected.
 * @param nameControl the id for the input for higher_geog that is to become the autocomplete, without a leading # selector.
 * @param idControl the id for the input holding geog_auth_rec_id without a leading # selector.
**/
function makeHigherGeogAutocomplete(nameControl, idControl) { 
	jQuery("#"+nameControl).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/localities/component/search.cfc",
				data: { term: request.term, method: 'getHigherGeogAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a higher geography autocomplete");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+nameControl).val(result.item.value);
			$('#'+idControl).val(result.item.id);
		},
		change: function(event,ui) { 
			if(!ui.item){
				// handle a change that isn't a selection from the pick list, clear the id control.
				$('#'+idControl).val("");
				// and clear the name control, so that e.g. a search cannot be run on a text substring
				$('#'+nameControl).val("");
			}
		},
		minLength: 3
	}).autocomplete( "instance" )._renderItem = function( ul, item ) {
		return $("<li>").append( "<span>" + item.value + "</span>").appendTo( ul );
	};
};

/** makeSovereignNationAutocomplete make an input control into a picker for a sovereign_nation field.
 *  This version of the function uses the value as returned and is intended for 
 *  intended as a picker for data entry and exact matching.
 * @param fieldId the id for the input without a leading # selector.
**/
function makeSovereignNationAutocomplete(fieldId) { 
	jQuery("#"+fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/localities/component/search.cfc",
				data: { term: request.term, method: 'getSovereignNationAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a sovereign nation autocomplete");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+fieldId).val(result.item.value);
		},
		minLength: 3
	}).autocomplete( "instance" )._renderItem = function( ul, item ) {
		return $("<li>").append( "<span>" + item.value + "</span>").appendTo( ul );
	};
};

/** makeSovereignNationSearchAutocomplete make an input control into a picker for a sovereign nation field.
 *  This version of the function prefixes the selected value with an = for exact match search, and is
 *  intended as a picker for soveregin nation search fields.
 * @param fieldId the id for the input without a leading # selector.
**/
function makeSovereignNationSearchAutocomplete(fieldId) { 
	jQuery("#"+fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/localities/component/search.cfc",
				data: { term: request.term, method: 'getSovereignNationAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a sovereign nation search autocomplete");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+fieldId).val("=" + result.item.value);
		},
		minLength: 3
	}).autocomplete( "instance" )._renderItem = function( ul, item ) {
		return $("<li>").append( "<span>" + item.value + " " + item.meta +"</span>").appendTo( ul );
	};
};

/** makeCountrySearchAutocomplete make an input control into a picker for a country field.
 *  This version of the function prefixes the selected value with an = for exact match search, and is
 *  intended as a picker for country search fields.
 * @param fieldId the id for the input without a leading # selector.
**/
function makeCountrySearchAutocomplete(fieldId) { 
	jQuery("#"+fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/localities/component/search.cfc",
				data: { term: request.term, method: 'getCountryAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a country search autocomplete");
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

/** makeGeogSearchAutocomplete make an input control into a picker for a geog_auth_rec field of arbitrary rank.
 *  This version of the function prefixes the selected value with an = for exact match search, and is
 *  intended as a picker for higher geography search fields.
 * @param fieldId the id for the input without a leading # selector.
 * @param targetRank the geographic rank (field in geog_auth_rec) to bind the autocomplete to.  
**/
function makeGeogSearchAutocomplete(fieldId, targetRank) { 
	jQuery("#"+fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/localities/component/search.cfc",
				data: { term: request.term, method: 'getGeogAutocomplete', rank: targetRank },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a geography search autocomplete");
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


/** Make a paired hidden collection_id and text collection_id control into an autocomplete collection picker
 *     the collection_id control is optional, and can be left off on a search form that can take a free text
 *     search term, collection names are a short list, so this autocomplete will start with a single character
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the optional id for a hidden input that is to hold the selected id (without a leading # selector),
 *    use null if there is no control to hold the selected collection_id.
 */
function makeCollectionPicker(nameControl,idControl) {
   $('#'+nameControl).autocomplete({
      source: function (request, response) {
         $.ajax({
            url: "/collections/component/search.cfc",
            data: { term: request.term, method: 'getCollectionAutocomplete' },
            dataType: 'json',
            success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a collection search autocomplete");
				}
         })
      },
      select: function (event, result) {
			if (idControl) { 
				// if idControl is non null, non-empty, non-false
				$('#'+idControl).val(result.item.id);
			}
      },
      minLength: 1
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// this overrides the renderItem to display meta "collection name (count)" instead of just the value in the picklist.
		return $("<li>").append("<span>" + item.value + " (" + item.meta + ")</span>").appendTo(ul);
	};
};


/** Make a text input control into an autocomplete collection_cde picker.
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 */
function makeCollectionCdePicker(nameControl) {
   $('#'+nameControl).autocomplete({
      source: function (request, response) {
         $.ajax({
            url: "/collections/component/search.cfc",
            data: { term: request.term, method: 'getCollectionCdeAutocomplete' },
            dataType: 'json',
            success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a collection code search autocomplete");
				}
         })
      },
		select: function (event, result) {
			event.preventDefault();
			$('#'+nameControl).val("=" + result.item.value);
		},
      minLength: 1
	});
};

/** Make a text input control into an autocomplete media label (the types, not the label values) picker
 *
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 */
function makeMediaLabelTypePicker(nameControl) {
   $('#'+nameControl).autocomplete({
      source: function (request, response) {
         $.ajax({
            url: "/media/component/search.cfc",
            data: { term: request.term, method: 'getMediaLabelTypeAutocomplete' },
            dataType: 'json',
            success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a media label search autocomplete");
				}
         })
      },
		select: function (event, result) {
			event.preventDefault();
			$('#'+nameControl).val("=" + result.item.value);
		},
      minLength: 1
	});
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

/** 
 Switch a set of image controls to display the previous image in a set.
 @param counter one based position within array of images represented by imageMetadataArray
 @param imageMetadataArray an array of media medtadata objects containing media_id, media_uri, media_des
 @param media_img id of the img element in the page into which the image is to be placed, not including # selector
 @param media_des id of the element in the page containing the description of the image, not including # selector
 @param detail_a id of the anchor tag in the page that is the link to a media details page, not including # selector
 @param media_a id of the anchor tag in the page that is the link to the media object, not including # selector
 @param image_counter id of the control showing the counter value, not including # selector
 @param sizeparams specification for size of image in the form &height={y}&width={x}
 @return the new value for counter.
*/ 
function goPreviousImage(counter, imageMetadataArray, media_img, media_des, detail_a, media_a, image_counter, sizeparams) { 
	$('#'+media_img).attr('src','/shared/images/indicator_for_load.gif');
	console.log( $('#'+media_img).attr('src'));
	currentCounter = counter;
	currentCounter = currentCounter - 1;
	if (currentCounter < 1) { 
		currentCounter = imageMetadataArray.length;
	}
	console.log(currentCounter);
	// array is zero based, counter is one based (so display of zeroth element in array is 1 for first image)
	var currentImageMetadataRecord = imageMetadataArray[currentCounter - 1];
	$("#"+detail_a).attr("href","/media/" + currentImageMetadataRecord.media_id);
	$("#"+media_a).attr("href",currentImageMetadataRecord.media_uri);
	$("#"+media_img).attr("src","/media/rescaleImage.cfm?media_id="+currentImageMetadataRecord.media_id+sizeparams);
	$("#"+media_img).attr("alt",currentImageMetadataRecord.alt);
	$("#"+image_counter).val(currentCounter);
	$("#"+media_des).html(currentImageMetadataRecord.alt);
	return currentCounter;
}
/** 
 Switch a set of image controls to display the next image in a set.
 @param counter one based position within array of images represented by imageMetadataArray
 @param imageMetadataArray an array of media medtadata objects containing media_id, media_uri, media_des
 @param media_img id of the img element in the page into which the image is to be placed, not including # selector
 @param media_des id of the element in the page containing the description of the image, not including # selector
 @param detail_a id of the anchor tag in the page that is the link to a media details page, not including # selector
 @param media_a id of the anchor tag in the page that is the link to the media object, not including # selector
 @param image_counter id of the control showing the counter value, not including # selector
 @param sizeparams specification for size of image in the form &height={y}&width={x}
 @return the new value for counter.
*/ 
function goNextImage(counter, imageMetadataArray, media_img, media_des, detail_a, media_a, image_counter,sizeparams) { 
	$('#'+media_img).attr('src','/shared/images/indicator_for_load.gif');
	console.log( $('#'+media_img).attr('src'));
	currentCounter = counter;
	currentCounter = currentCounter + 1;
	if (currentCounter > imageMetadataArray.length) { 
		currentCounter = 1;
	}
	console.log(currentCounter);
	// array is zero based, counter is one based (so display of zeroth element in array is 1 for first image)
	var currentImageMetadataRecord = imageMetadataArray[currentCounter - 1];
	console.log(currentImageMetadataRecord);
	$("#"+detail_a).attr("href","/media/" + currentImageMetadataRecord.media_id);
	$("#"+media_a).attr("href",currentImageMetadataRecord.media_uri);
	$("#"+media_img).attr("src","/media/rescaleImage.cfm?media_id="+currentImageMetadataRecord.media_id+sizeparams);
	$("#"+media_img).attr("alt",currentImageMetadataRecord.alt);
	$("#"+image_counter).val(currentCounter);
	$("#"+media_des).html(currentImageMetadataRecord.alt);
	return currentCounter;
}
/** 
 Switch a set of image controls to display a specified image in a set, if a valid position is specfied in the value
 of image_counter, then that image is moved to, otherwise the image remains at the current counter value.
 @param counter one based current position within array of images represented by imageMetadataArray
 @param imageMetadataArray an array of media medtadata objects containing media_id, media_uri, media_des
 @param media_img id of the img element in the page into which the image is to be placed, not including # selector
 @param media_des id of the element in the page containing the description of the image, not including # selector
 @param detail_a id of the anchor tag in the page that is the link to a media details page, not including # selector
 @param media_a id of the anchor tag in the page that is the link to the media object, not including # selector
 @param image_counter id of the control showing the counter value, not including # selector
 @param sizeparams specification for size of image in the form &height={y}&width={x}
 @return the new value for counter.
*/ 
function goImageByNumber(counter, imageMetadataArray, media_img, media_des, detail_a, media_a, image_counter,sizeparams) { 
	$('#'+media_img).attr('src','/shared/images/indicator_for_load.gif');
	console.log( $('#'+media_img).attr('src'));
	currentCounter = counter;
	var targetCounterValue = currentCounter;
	var inputVal = Number($("#"+image_counter).val());
	if(Number.isInteger(inputVal)) {
		targetCounterValue = inputVal;
	}
	if (targetCounterValue > imageMetadataArray.length) { 
		targetCounterValue = imageMetadataArray.length;
	}
	if (targetCounterValue < 1) { 
		targetCounterValue = 1;
	}
	currentCounter = targetCounterValue;
	// array is zero based, counter is one based (so display of zeroth element in array is 1 for first image)
	var currentImageMetadataRecord = imageMetadataArray[currentCounter - 1];
	$("#"+detail_a).attr("href","/media/" + currentImageMetadataRecord.media_id);
	$("#"+media_a).attr("href",currentImageMetadataRecord.media_uri);
	$("#"+media_img).attr("src","/media/rescaleImage.cfm?media_id="+currentImageMetadataRecord.media_id+sizeparams);
	$("#"+media_img).attr("alt",currentImageMetadataRecord.alt);
	$("#"+image_counter).val(currentCounter);
	$("#"+media_des).html(currentImageMetadataRecord.alt);
	return currentCounter;
}

/** Ajax reload method to accompany getMediaBlockHtml backing method 
 * load an html block to display an image with metadata as a media widget,
 * replaces the html of targetDiv with the response from the backing method,
 * uses the default values for optional parameters.
 *
 * @param media_id the media object for which to return a media widget.
 * @param targetDiv the id div for which to replace the html with the returned
 *   media widget, as in an ajax refresh of the display of a media record, with
 *   no leading # selector.
 * @See getMediaBlock getMediaBlockHtml(media_id, targetDiv, displayAs, captionAs, size)
 *   for more control on what is returned.
 * @See backing method getMediaBlockHtml in /media/component/search for details.
 */
function getMediaBlockHtml(media_id,targetDiv) {
	getMediaBlockHtml(media_id,targetDiv,"full","textFull","600","white");
}

/** Ajax reload method to accompany getMediaBlockHtml backing method 
 * load an html block to display an image with metadata as a media widget,
 * replaces the html of targetDiv with the response from the backing method.
 *
 * @param media_id the media object for which to return a media widget.
 * @param targetDiv the id div for which to replace the html with the returned
 *   media widget, as in an ajax refresh of the display of a media record, with
 *   no leading # selector.
 * @param displayAs how the image is to be displayed: full, thumb, fixedSmallThumb
 * @param captionAs what information is to be displayed as a caption: 
 *   textFull, textLinks, textNone.
 * @param size an integer for the pixel height and width of the returned image.
 * @param background_color the background color to use if fixedSmallThumb is specified.
 * @See backing method getMediaBlockHtml in /media/component/search for details.
 */
function getMediaBlockHtml(media_id, targetDiv, displayAs, captionAs, size, background_color) { 
	jQuery.ajax(
	{
		dataType: "json",
		url: "/media/component/public.cfc",
		data: { 
			method : "getMediaBlockHtml",
			media_id : media_id,
			displayAs : displayAs,
			captionAs : captionAs,
			size : size,
			background_color : background_color,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error updating item count: " + status + " " + jqXHR.responseText ,'Error: '+ status);
		},
		success: function (result) {
			$('#' + targetDiv).html(result);
		}
	});
}
/*Scroll to top when arrow up clicked BEGIN*/
$(window).scroll(function() {
    var height = $(window).scrollTop();
    if (height > 100) {
        $('#back2Top').fadeIn();
    } else {
        $('#back2Top').fadeOut();
    }
});
$(document).ready(function() {
    $("#back2Top").click(function(event) {
        event.preventDefault();
        $("html, body").animate({ scrollTop: 0 }, "slow");
        return false;
    });

});
 /*Scroll to top when arrow up clicked END*/

// open the download dialog to pick a profile for download fields
function openDownloadDialog(dialogid, result_id, filename) { 
	var title = "Download as CSV";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.6);
	h = Math.floor(h *.4);
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		zindex: 2000,
		height: h,
		width: w,
		minWidth: 300,
		minHeight: 250,
		draggable:true,
		buttons: {
		 	"Close Dialog": function() { 
			 	$("#"+dialogid+"_div").html("");
				$("#"+dialogid).dialog('close'); 
				$("#"+dialogid).dialog('destroy'); 
			}
		},
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/specimens/component/search.cfc",
		type: "post",
		data: { 
			method: "getDownloadDialogHTML",
			returnformat: "plain",
			result_id : result_id,
			filename : filename
		},
		success: function (data) { 
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading download result dialog");
		}
	});
}


// open the download agreement dialog
function openDownloadAgreeDialog(dialogid, result_id, filename) { 
	var title = "Download Agreement";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.9);
	h = Math.floor(h *.9);
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		zindex: 2000,
		height: h,
		width: w,
		minWidth: 400,
		minHeight: 450,
		draggable:true,
		buttons: {
		 	"Close Dialog": function() { 
			 	$("#"+dialogid+"_div").html("");
				$("#"+dialogid).dialog('close'); 
				$("#"+dialogid).dialog('destroy'); 
			}
		},
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/specimens/component/search.cfc",
		type: "post",
		data: { 
			method: "getDownloadAgreeDialogHTML",
			returnformat: "plain",
			result_id : result_id,
			filename : filename
		},
		success: function (data) { 
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading download agreement dialog");
		}
	});
}

/** makeCEFieldAutocomplete make an input control into a picker for arbitrary collecting event fields.
 *  This version of the function prefixes the selected value with an = for exact match search, and is
 *  intended as a picker for collecting event search fields
 * @param fieldId the id for the input without a leading # selector.
 * @param targetRank the field in collecting_event to bind the autocomplete to.  
**/
function makeCEFieldAutocomplete(fieldId, targetField) { 
	jQuery("#"+fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/localities/component/search.cfc",
				data: { term: request.term, method: 'getCEFieldAutocomplete', field: targetField },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a collecting event field search autocomplete");
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

/** Make a paired text attribute and text attribute value control into an autocomplete geological attribute picker that displays meta 
 *  on picklist and value on selection.
 *  @param attributeControl the id for a text input that is to hold the attribute for the selected value (without a leading # selector).
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param hierarchyIdControl the id for a hidden input that is to hold the geological_attribute_hierarchy_id for the selection.
 *  @param mode if search, then include all matching values, otherwise only return values allowed for data entry..
 *  @param type to limit the results to a specific ctgeology_attribute.type of attribute.
 */
function makeGeologyAutocompleteMeta(attributeControl, valueControl, hierarchyIdControl, mode, type) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/vocabularies/component/search.cfc",
				data: { 
					term: request.term, 
					mode: mode,
					type: type,
					method: 'getGeologyAutoComplete' 
				},
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up geological attributes for an autocomplete");
				}
			})
		},
		select: function (event, result) {
			$('#'+attributeControl).val(result.item.attribute);
			$('#'+hierarchyIdControl).val(result.item.geology_attribute_hierarchy_id);
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta "matched name * (preferred name)" instead of value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** lookuGeoAttParents lookup the path from a geological attribute node
  to root in the geological heirarchy tree.
  @param geology_attribute_hierarchy_id the node to look up.
  @param targetDiv the id (without a leading # selector) of a node in the 
   DOM the html of which to populate with the returned result.
*/
function lookupGeoAttParents(geology_attribute_hierarchy_id,targetDiv) { 
	$.ajax({
		url: "/vocabularies/component/functions.cfc",
		data: { 
			geology_attribute_hierarchy_id: geology_attribute_hierarchy_id,
			method: 'getNodeToRootGeologyTreeHtml'
		},
		dataType: 'html',
		success : function (result) { 
			$('#'+targetDiv).html(result)
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error, "Error looking up parentage for geological attribute: "); 
		}
	});
};

/** given a table and column retrieve a comment on the column from the schema 
 * @param table the table for the column
 * @param column for which to obtain any comment
 * @param targetId the id for a element in the dom the html of which to replace with
 * the returned comment.
 */
function lookupComment(table, column ,targetID) { 
	$.ajax({
		url: "/shared/component/functions.cfc",
		data: { 
			table: table,
			column: column,
			method: 'getCommentForField'
		},
		dataType: 'html',
		success : function (result) { 
			$('#'+targetID).html(result)
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error, "Error looking up metadata for column "); 
		}
	});
};
