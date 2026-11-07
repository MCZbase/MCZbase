/** Scripts for the pages in /collections/. **/

/** Load a Collection Panel widget: replace the content of a target element with the HTML a method of
 *  /collections/component/functions.cfc returns for a collection, showing the loading indicator meanwhile.
 *  @param targetId the id of the element to fill, without a leading # selector.
 *  @param method the remote method returning the widget's HTML.
 *  @param collectionId the collection_id of the collection to report on.
 *  @param params optional object of further arguments for the method.
 */
function loadCollectionWidget(targetId, method, collectionId, params) {
	$('#'+targetId).html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>');
	$.ajax({
		url: "/collections/component/functions.cfc",
		data: $.extend({ method: method, returnformat: "plain", collection_id: collectionId }, params || {}),
		type: "get",
		success: function (data) {
			$('#'+targetId).html(data);
		},
		error: function (jqXHR, textStatus, error) {
			$('#'+targetId).html('<p class="text-danger">This widget could not be loaded.</p>');
			handleFail(jqXHR, textStatus, error, "loading the " + method + " widget");
		}
	});
}

/** Open the bug report form, in a new tab, with a request to remove the accounts ticked in the
 * Collection Access widget, either from the collection or as MCZbase users, to review and send.
 *
 * @param collectionId the collection_id of the collection shown.
 * @param containerId the id of the element holding the ticked accounts and the removal choice, without a leading #.
 * @param feedbackId the id of the element for a message when no account is ticked, without a leading #.
 */
function draftAccessRemovalRequest(collectionId, containerId, feedbackId) {
	var accounts = $('#' + containerId + ' input.removalAccount:checked').map(function() {
		return $(this).val();
	}).get();
	if (accounts.length == 0) {
		$('#' + feedbackId).text('Tick one or more accounts first.');
		return;
	}
	$('#' + feedbackId).text('');
	var kind = $('#' + containerId + ' input[name="removalKind"]:checked').val();
	window.open('/info/bugs.cfm?action=bugReportForm'
		+ '&access_removal=' + encodeURIComponent(kind)
		+ '&collection_id=' + encodeURIComponent(collectionId)
		+ '&accounts=' + encodeURIComponent(accounts.join(',')), '_blank');
}
