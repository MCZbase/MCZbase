/**  vocabulary_scripts.js
 * Place scripts that should be available to support GUIDs and other external controlled vocabularies here.

Copyright 2020 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

/** Given a paired guid text input and guid anchor control, and a guid type, look up the metadata on the guid type,
 *  validate the content of the guid text input with the pattern for that guid type, set the placeholder for the 
 *  input, and construct a resolvable link for the href of the anchor from the text input of the guid, and update
 *  a search link for text on the guid provider.
 *
 *  @param guid_type a value from ctguid_type for the current type of guid expected to be found in inputControl.
 *  @param inputControl the id for the guid text input (without a leading # selector).
 *  @param linkControl the id for the anchor that is to take the resolvable guid as an href (without a leading # selector).
 *  @param searchControl the id for the anchor that is to take a guid search link as an href (without a leading # selector).
 *  @param searchText the text to append to the end of the search_uri in the searchControl href to lookup a guid.
 */
function getGuidTypeInfo(guid_type, inputControl, linkControl, searchControl, searchText) {
	$.ajax({
		url: "/shared/component/vocab_control.cfc",
		data: { 
			guid_type: guid_type, 
			method: 'getGuidTypeInfo' 
		},
		dataType: 'json',
		success : function (data) {
			console.log(data);
			var guid = $('#'+inputControl).val();
			$('#'+inputControl).attr("pattern",data[0].pattern_regex);
			$('#'+inputControl).attr("placeholder",data[0].placeholder);
			$('#'+inputControl).attr("title","Enter a guid in the form " +  data[0].placeholder);
			var valid = false;
			if (guid != "") { 
				// validate input control content against the regex
				valid = $('#'+inputControl).get(0).reportValidity();
			};
			var regex = new RegExp(data[0].resolver_regex);
			var replacement = data[0].resolver_replacement; 
			var newlink = guid.replace(regex,replacement);
			console.log(regex);
			console.log(newlink);
			if (valid===true) { 
				// update link
				$('#'+linkControl).attr("href",newlink); 
				$('#'+linkControl).html(guid); 
				// hide input
				$('#'+inputControl).hide();
			} 
			$('#'+searchControl).attr("href",data[0].search_uri + encodeURIComponent(searchText)); 
			if (searchText && searchText.length > 0) { 
				if (guid.length > 0) { 
					$('#'+searchControl).html("Replace"); 
				} else { 
					$('#'+searchControl).html("Find GUID"); 
				}
				$('#'+searchControl).addClass("smallBtn external");
			} else {
				$('#'+searchControl).html(""); 
				$('#'+searchControl).removeClass("smallBtn external");
			}
		},
		error : function (jqXHR, status, error) {
			var message = "";
			if (error == 'timeout') {
				message = ' Server took too long to respond.';
			} else {
				message = jqXHR.responseText;
			}
			if (message=="" && error =="") { 
				// Case of empty error when guid input is modal and save is pressed, closing page 
				// and triggering empty error dialog briefly before page closes (at least on firefox)
				console.log(status);
				console.log("ajax request for getGuidTypeInfo failed with no error or message");
			} else { 
			   messageDialog('Error:' + message ,'Error: ' + error);
			}
		}
	});
};

