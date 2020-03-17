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
	$('<div style="padding: 10px; max-width: 500px; word-wrap: break-word;">' + dialogText + '</div>').dialog({
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
		}
	});
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

