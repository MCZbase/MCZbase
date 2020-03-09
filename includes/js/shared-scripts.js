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

