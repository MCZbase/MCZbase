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

/** loadFullCitDivHTML load a block of html showing the current full form
 * of the citation for a publication.
 * @param publication_id the publication for which to show the citation.
 * @param targetDivId the id without a leading # selector of the element in 
 *  the dom the content of which to replace with the returned html.
*/
function loadFullCitDivHTML(publication_id,targetDivId) { 
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "getCitationForPubHtml",
			form: "full",
			publication_id: publication_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading publication citation text");
		},
		dataType: "html"
	});
};
/** loadPlainCitDivHTML load the value of the current full form
 * of the citation for a publication without html markup into an input control.
 * @param publication_id the publication for which to show the citation.
 * @param targetDivId the id without a leading # selector of the element in 
 *  the dom the value of which to replace with the returned text.
*/
function loadPlainCitDivHTML(publication_id,targetDivId) { 
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "getCitationForPubHtml",
			form: "plain",
			publication_id: publication_id
		},
		success: function (result) {
			$("#" + targetDivId ).val(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading publication citation plain text");
		},
		dataType: "html"
	});
};

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

/** lookupDOI use information from a publication record to find a DOI for that 
 * publication.
 * @param publication_id the publication for which to lookup the doi.
 * @param doiInput the id without a leading pound selector of the input whos value
 *  is to be set to the returned doi on success.
 * @param doiLinkDiv the id without a leading pound selector of a div that is to
 *  have its html replaced by a link for the doi on success.
 */
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
			console.log(result);
			var match = result[0].match;
			if (match=='1') {
				var doi = result[0].doi;
				$('#'+doiInput).val(doi);
				$('#'+doiLinkDiv).html("<a class='external' target='_blank' href='https://doi.org/"+doi+"'>"+doi+"</a>");
			}
		}
	});
}

/** deleteAttribute delete an attribute from a publication.
 * @param publication_attribute_id the primary key of the publication attribute
 *  to delete.
 * @param okcallback a callback function to invoke on success.
 */
function deleteAttribute(publication_attribute_id, okcallback) { 
	jQuery.ajax({
		dataType: "json",
		url: "/publications/component/functions.cfc",
		data: { 
			method : "deleteAttribute",
			publication_attribute_id : publication_attribute_id,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error deleting publication attribute: " + status + " " + jqXHR.responseText ,'Error: '+ status);
		},
		success: function (result) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
			var status = result[0].status;
			if (status=='deleted') {
				console.log(status);
			}
		}
	});
}

/** loadAuthorsDivHTML load a block of html for editing/viewing
 *  authors and editors of a publication.
 * @param publication_id the publication for which to load authors/editors
 * @param targetDivId the id without a leading # selector of the element in 
 *  the dom the content of which to replace with the returned html.
*/
function loadAuthorsDivHTML(publication_id,targetDivId) { 
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "getAuthorsForPubHtml",
			publication_id: publication_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading authors/editors for publication");
		},
		dataType: "html"
	});
};

/** loadAttributesDivHTML load a block of html for editing/viewing
 *  attributes of a publication.
 * @param publication_id the publication for which to load attributes
 * @param targetDivId the id without a leading # selector of the element in 
 *  the dom the content of which to replace with the returned html.
*/
function loadAttributesDivHTML(publication_id,targetDivId) { 
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "getAttributesForPubHtml",
			publication_id: publication_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading attributes for publication");
		},
		dataType: "html"
	});
};

/** loadMediaDivHTML load a block of html for editing/viewing
 *  media related a publication.
 * @param publication_id the publication for which to load media
 * @param targetDivId the id without a leading # selector of the element in 
 *  the dom the content of which to replace with the returned html.
*/
function loadMediaDivHTML(publication_id,targetDivId) { 
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "getMediaForPubHtml",
			publication_id: publication_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading media for publication");
		},
		dataType: "html"
	});
};
