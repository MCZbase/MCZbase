/**** projects/js/projects.js
Search-field autocomplete bindings for /Projects.cfm.
 ******/

/**
 * makeProjectTitleSearchAutocomplete binds a text input to a substring-matching
 * autocomplete of existing project titles (projects/component/search.cfc's
 * getProjectAutocompleteMeta), so the Title search field suggests real project names
 * instead of accepting unconstrained free text.
 *
 * @param fieldId the id of the text input to bind (without a leading # selector).
 */
function makeProjectTitleSearchAutocomplete(fieldId) {
	jQuery("#" + fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/projects/component/search.cfc",
				data: { term: request.term, method: "getProjectAutocompleteMeta" },
				dataType: "json",
				success: function (data) { response(data); },
				error: function (jqXHR, textStatus, error) {
					handleFail(jqXHR, textStatus, error, "making a project title autocomplete");
				}
			});
		},
		select: function (event, result) {
			event.preventDefault();
			$("#" + fieldId).val(result.item.value);
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function (ul, item) {
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
}
