/** Scripts for the pages in /collections/. **/

/** Load a Collection Panel widget: replace the content of a target element with the HTML a method of
 *  /collections/component/functions.cfc returns for a collection, showing the loading indicator meanwhile.
 *  @param targetId the id of the element to fill, without a leading # selector.
 *  @param method the remote method returning the widget's HTML.
 *  @param collectionId the collection_id of the collection to report on.
 */
function loadCollectionWidget(targetId, method, collectionId) {
	$('#'+targetId).html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>');
	$.ajax({
		url: "/collections/component/functions.cfc",
		data: { method: method, returnformat: "plain", collection_id: collectionId },
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
