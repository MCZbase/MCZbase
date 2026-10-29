<!---
dataentry/customizeDataEntry.cfm

Copyright 2026 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Edit the current user's Data Entry field settings: hide, show or carry each field.  Replaces
/form/customizeDataEntry.cfm; not yet linked from Data Entry.

TODO: cf_form_permissions limits this page and /dataentry/component/functions.cfc to global_admin while
it is unlinked; change both rows to data_entry if the page goes into production.
--->
<cfset pageTitle = "Customize Data Entry">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/dataentry/component/functions.cfc" runOnce="true">

<cfoutput>
	<main class="container py-3" id="content">
		<section class="row border rounded my-2 px-2">
			<div class="col-12">
				<h1 class="h2 mt-2">Customize Data Entry for #encodeForHtml(session.username)#</h1>
				<p class="mb-1">Choose what each field does on the data entry screen when you enter new records:</p>
				<ul>
					<li><strong>hide</strong>: remove the field from the screen and clear it. Offered only for fields the screen can remove, marked <i class="fas fa-eye-slash" aria-hidden="true"></i><span class="sr-only">with a crossed out eye</span>; hiding a coordinate, elevation or depth units field, a part name, a geology attribute or an identifier removes the fields that go with it. A record can still be saved with values in hidden fields, so hide with care.</li>
					<li><strong>show</strong>: show the field, cleared after each record is saved.</li>
					<li><strong>carry</strong>: show the field and carry its value over to the next record.</li>
				</ul>
				<p>The data entry screen reads these settings when it changes to Enter New Record and after each new record is saved. If the data entry screen is already open in another tab, reload it or change it to Enter New Record to pick up settings saved here.</p>
				<cfset settingsForm = getDataEntrySettingsFormHtml(feedbackId="saveFeedback")>
				#settingsForm#
				<div class="mb-4">
					<button type="button" class="btn btn-xs btn-primary" onClick="saveDataEntrySettings('dataEntrySettingsForm','saveFeedback');">Save</button>
					<output id="saveFeedback" class="ml-2"></output>
				</div>
			</div>
		</section>
	</main>
	<script>
		/** Set every setting select within an element to one value, skipping any select that does not
		 * offer it, as hide is offered only for fields the data entry screen can remove.
		 *
		 * @param containerId the id of the element holding the selects.
		 * @param settingValue 0 hide, 1 show, 2 carry.
		 * @param feedbackId the id of the output element for save feedback.
		 */
		function setDataEntrySettings(containerId, settingValue, feedbackId) {
			$("##" + containerId + " select").each(function() {
				if ($(this).find("option[value='" + settingValue + "']").length > 0) {
					$(this).val(String(settingValue));
				}
			});
			setFeedbackControlState(feedbackId, "unsaved");
		}
		/** Save every setting in the form.
		 *
		 * @param formId the id of the form holding the setting selects.
		 * @param feedbackId the id of the output element for save feedback.
		 * @see saveDataEntrySettings in /dataentry/component/functions.cfc
		 */
		function saveDataEntrySettings(formId, feedbackId) {
			var settings = {};
			$("##" + formId + " select").each(function() {
				settings[$(this).attr("name")] = Number($(this).val());
			});
			setFeedbackControlState(feedbackId, "saving");
			$.ajax({
				url: "/dataentry/component/functions.cfc",
				type: "POST",
				dataType: "json",
				data: {
					method: "saveDataEntrySettings",
					settings: JSON.stringify(settings),
					returnformat: "json"
				},
				success: function(result) {
					setFeedbackControlState(feedbackId, "saved");
				},
				error: function(jqXHR, textStatus, error) {
					setFeedbackControlState(feedbackId, "error");
					handleFail(jqXHR, textStatus, error, "saving Data Entry settings");
				}
			});
		}
	</script>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
