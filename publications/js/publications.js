/** Scripts specific to publications pages. **/
/**

Copyright 2022 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

**/

/** function monitorForChanges bind a change monitoring function to inputs 
 * on a given form.  Note: text inputs must have type=text to be bound to change function.
 * @param formId the id of the form, not including the # id selector to monitor.
 * @param changeFunction the function to fire on change events for inputs on the form.
 */
function monitorForChanges(formId,changeFunction) { 
	$('#'+formId+' input[type=text]').on("change",changeFunction);
	$('#'+formId+' input[type=checkbox]').on("change",changeFunction);
	$('#'+formId+' select').on("change",changeFunction);
	$('#'+formId+' textarea').on("change",changeFunction);
}

function lookupDOI(publication_id, doiInput, doiLinkDiv) {
	jQuery.ajax({
		dataType: "json",
		url: "/publications/component/functions.cfc",
		data: { 
			method : "crossRefLookup",
			publication_id : publication_id,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error looking up DOI: " + status + " " + jqXHR.responseText ,'Error: '+ status);
		},
		success: function (result) {
			var matches = result.DATA.matches[0];
			var doi = result.DATA.doi[0];
			if (matches=='1') {
				$('#'+doiInput).val(doi);
				$('#'+doiLinkDiv).html("<a class='external' target='_blank' href='https://doi.org/"+doi+"'>"+doi+"</a>");
			}
		}
	});
}
