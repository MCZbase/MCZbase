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
 *  input, and construct a resolvable link for the href of the anchor from the text input of the guid.
 *
 *  @param guid_type a value from ctguid_type for the current type of guid expected to be found in inputControl.
 *  @param inputControl the id for the guid text input (without a leading # selector).
 *  @param linkControl the id for the anchor that is to take the resolvable guid as an href (without a leading # selector).
 */
function getGuidTypeInfo(guid_type, inputControl, linkControl) {
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
			$('#'+inputControl).attr("pattern",data.pattern_regex);
			$('#'+inputControl).attr("placeholder",data.placeholder);
			if (guid != "") { 
				// validate input control content against the regex
				$('#'+inputControl).reportValidity();
			};
			// update link
			$('#'+linkControl).attr("href",guid.replace(data.resolver_regex,data.resolver_replacement)); 
		},
		error : function (jqXHR, status, error) {
			var message = "";
			if (error == 'timeout') {
				message = ' Server took too long to respond.';
			} else {
				message = jqXHR.responseText;
			}
			messageDialog('Error:' + message ,'Error: ' + error);
		}
	});
};

