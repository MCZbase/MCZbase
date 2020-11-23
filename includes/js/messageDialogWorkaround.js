/** Temporary file, to allow resolution of Redmine 674 Bugfix to f2fee81  making javascript messageDialog() available to Taxonomy.cfm without adding /shared/js/shared-scripts.js as an include in alwaysInclude.cfm */


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
