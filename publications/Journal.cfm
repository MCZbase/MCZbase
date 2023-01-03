<!---
publications/Journal.cfm 

Journal name code table editor 

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

--->

<cfif not isdefined("action")>
	<cfif isDefined("journal_name") AND len(journal_name) GT 0>
		<cfset action="edit">
	<cfelse>
		<cfset action="new">
	</cfif>
</cfif>
<cfswitch expression="#action#">
	<cfcase value="new">
		<cfset pageTitle = "Add New Serial/Journal Title">
	</cfcase>
	<cfcase value="edit">
		<cfset pageTitle = "Edit a Serial/Journal Title">
	</cfcase>
	<cfdefaultcase>
		<!--- save new, delete --->
		<cfset pageTitle = "Updating Serial/Journal Title">
	</cfdefaultcase>
</cfswitch>
<!---------------------------------------------------------------------------------->
<cfinclude template = "/shared/_header.cfm">
<cfswitch expression="#action#">
	<!--- Check for finer granularity permissions than rolecheck called in _header.cfm provides --->
	<cfcase value="new">
		<cfif NOT isdefined("session.roles") OR NOT listfindnocase(session.roles,"manage_codetables")>
			<cfthrow message="Insufficient permissions to add a new journal name.">
		</cfif>
	</cfcase>
	<cfcase value="edit">
		<cfif NOT isdefined("session.roles") OR NOT listfindnocase(session.roles,"manage_codetables")>
			<cfthrow message="Insufficient permissions to edit a journal name.">
		</cfif>
	</cfcase>
</cfswitch>
<!---------------------------------------------------------------------------------->
<cfswitch expression="#action#">
	<cfcase value="new">
		<!--- Add a new ctjournal_name record ---> 
		<cfoutput>
			<main class="container mt-3">
				<section class="row">
					<div class="col-12">
						<h1 class="h2 pl-2 ml-2" id="formheading">New Serial/Journal</h1>
						<div class="h3 pl-2 ml-2" id="formheading">Make sure that you have <a href="/publications/Journals.cfm">searched for</a> and not found an existing record for this serial/journal name.</div>
						<div class="border rounded px-2 pt-2" aria-labelledby="formheading">
							<form name="newJournalTitle" id="newJournalTitle" action="/publications/Journal.cfm" method="post" class="px-2">
								<input type="hidden" id="action" name="action" value="saveNew" >
								<div class="form-row mt-2 mb-2">
									<div class="col-12 col-md-10">
										<label for="journal_name" id="journal_name_label" class="data-entry-label">Serial/Journal Title</label>
										<input type="text" id="journal_name" name="journal_name" class="data-entry-input reqdClr" required aria-labelledby="journal_name_label" >
										<script>
											$(document).ready(function () {
												$('##pref_name').change(function () {
													checkJournalExists($('##journal_name').val(),'matchesFeedback');
												});
											});
										</script>
									</div>
									<div class="col-12 col-md-2">
										<label for="matchesFeedback" class="data-entry-label">Duplicate check</label>
										<output id="matchesFeedback" class="text-success font-weight-lessbold p-1"></output>
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-12 col-md-12">
										<label for="short_name" id="short_name_label" class="data-entry-label">Short Title</label>
										<input type="text" id="short_name" name="short_name" class="data-entry-input" aria-labelledby="short_name_label" >
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-12 col-md-12">
										<label for="remarks" id="remarks_label" class="data-entry-label">Remarks</label>
										<input type="text" id="remarks" name="remarks" class="data-entry-input" aria-labelledby="remarks_label" >
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-12 col-md-4">
										<label for="issn" id="issn_label" class="data-entry-label">ISSN</label>
										<input type="text" id="issn" name="issn" class="data-entry-input" aria-labelledby="issn_label" >
									</div>
									<div class="col-12 col-md-4">
										<label for="start_year" id="start_year_label" class="data-entry-label">Start Year</label>
										<input type="text" id="start_year" name="start_year" class="data-entry-input" aria-labelledby="start_year_label" placeholder="yyyy" >
									</div>
									<div class="col-12 col-md-4">
										<label for="end_year" id="end_year_label" class="data-entry-label">End Year</label>
										<input type="text" id="end_year" name="end_year" class="data-entry-input" aria-labelledby="end_year_label" placeholder="yyyy">
									</div>
								</div>
								<div class="form-row mb-1">
									<div class="col-12 row mx-0 px-1 my-3">
										<input type="button" 
													value="Create" title="Create" aria-label="Create"
													class="btn btn-xs btn-primary"
													onClick="if (checkFormValidity($('##newJournalTitle')[0])) { submit(); } " 
													>
									</div>
								</div>
							</form>
						</div>
						<!--- region ---> 
					</div>
					<!--- col ---> 
				</section>
				<!--- section ---> 
			</main>
			<!--- container ---> 
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfcase value="saveNew">
		<cftry>
			<cfif not isdefined("journal_name") OR len(trim(#journal_name#)) EQ 0 >
				<cfthrow type="Application" message="Error: No value provided for required value journal_name">
			</cfif>
			<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insertResult">
				insert into ctjournal_name (
					journal_name
					<cfif isdefined("remarks")>
						,remarks
					</cfif>
					<cfif isdefined("short_name")>
						,short_name
					</cfif>
					<cfif isdefined("issn")>
						,issn
					</cfif>
					<cfif isdefined("start_year") and len(start_year) GT 0 >
						,start_year
					</cfif>
					<cfif isdefined("end_year") and len(end_year) GT 0 >
						,end_year
					</cfif>
				) values (
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#journal_name#">
					<cfif isdefined("remarks")>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
					</cfif>
					<cfif isdefined("short_name")>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#short_name#">
					</cfif>
					<cfif isdefined("issn")>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#issn#">
					</cfif>
					<cfif isdefined("start_year") and len(start_year) GT 0 >
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#start_year#">
					</cfif>
					<cfif isdefined("end_year") and len(end_year) GT 0 >
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#end_year#">
					</cfif>
				)
			</cfquery>
			<cflocation url="/publications/Journal.cfm?action=edit&journal_name=#encodeForUrl(journal_name)#" addtoken="false">
			<cfcatch>
				<cfthrow type="Application" message="Error Saving new Serial/Journal Title: #cfcatch.Message# #cfcatch.Detail#">
			</cfcatch>
		</cftry>
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfcase value="edit">
		<cfif not isDefined("journal_name")>
			<cfset journal_name = "">
		</cfif>
		<cfif len(journal_name) EQ 0>
			<cfthrow type="Application" message="Error: No value provided for journal_name">
		<cfelse>
			<cfquery name="journalTitle" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="journalTitle_result">
				SELECT 
					journal_name,
					short_name,
					start_year,
					end_year,
					issn,
					remarks
				FROM ctjournal_name
				WHERE
					journal_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#journal_name#">
			</cfquery>
			<cfif journalTitle_result.recordcount EQ 0>
				<cfthrow message="No matching journal name found [#encodeForHtml(journal_name)#]" >
			</cfif>
			<cfquery name="uses" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="uses_result">
				SELECT count(*) ct
				FROM 
					publication_attributes
				WHERE
					publication_attribute = 'journal name'
					AND pub_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#journal_name#">
			</cfquery>
			<cfif uses.ct GT 0>
				<cfset inUse = true>
			<cfelse>
				<cfset inUse = false>
			</cfif>
			<cfoutput query="journalTitle">
				<main id="content" class="pb-5">
					<section class="container pt-3">
						<h1 class="h2" id="formheading">
							Edit Serial/Journal Title: <span id="headingJournalTitle">#encodeForHtml(journal_name)#</span>
						</h1>
					<div class="row border rounded py-3" aria-labelledby="formheading">
						<div class="col-12 px-3">
							<cfif NOT inUse>
								<form name="deleteJournalName" id="deleteJournalName" method="post" action="/publications/Journal.cfm">
									<input type="hidden" id="delete_journal_name" name="journal_name" value="#encodeForHtml(journal_name)#" >
									<input type="hidden" id="delete_action" name="action" value="delete" >
								</form>
							</cfif>
							<form name="editJournalName" id="editJournalName">
								<input type="hidden" id="old_journal_name" name="old_journal_name" value="#encodeForHtml(journal_name)#" >
								<input type="hidden" id="method" name="method" value="saveJournalName" >
								<div class="form-row mb-2">
									<div class="col-12 col-md-9">
										<cfif inUse><cfset titleClass="disabled"><cfelse><cfset titleClass=""></cfif>
										<label for="journal_name" id="journal_name_label" class="data-entry-label">Serial/Journal Title</label>
										<input type="text" id="journal_name" name="journal_name" class="data-entry-input reqdClr #titleClass#" 
												<cfif inUse> disabled </cfif>
												required value="#encodeForHtml(journal_name)#" aria-labelledby="journal_name_label" >
									</div>
									<div class="col-12 col-md-3">
										<cfif inUse>
											<label for="delete_button" class="data-entry-label">In use in <a href="/Publications.cfm?execute=true&journal_name=#encodeForURL(journal_name)#" target="_blank">#uses.ct# Publication Records</a>.</label>
										<cfelse>
											<label for="delete_button" class="data-entry-label">In use in #uses.ct# Publication Records.</label>
										</cfif>
										<input type="button" 
												<cfif inUse>
													class="btn btn-xs btn-warning disabled"
													onClick=" return false; " 
												<cfelse>
													class="btn btn-xs btn-warning"
													onClick=" event.preventDefault(); confirmDialog('Delete this Journal?','Confirm Delete Serial/Journal', function() { $('##deleteJournalName').submit(); } ); " 
												</cfif>
												value="Delete" title="Delete" aria-label="Delete"
												>
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-md-12">
										<label for="short_name" id="short_name_label" class="data-entry-label">Short Title</label>
										<input type="text" id="short_name" name="short_name" class="data-entry-input" aria-labelledby="short_name_label" value="#encodeForHtml(short_name)#">
									</div>
								</div>
								<div class="form-row mb-0">
									<div class="col-12 col-md-4">
										<label for="issn" id="issn_label" class="data-entry-label">ISSN</label>
										<input type="text" id="issn" name="issn" class="data-entry-input" aria-labelledby="issn_label" value="#encodeForHtml(issn)#" >
									</div>
									<div class="col-12 col-md-4">
										<label for="start_year" id="start_year_label" class="data-entry-label">Start Year</label>
										<input type="text" id="start_year" name="start_year" class="data-entry-input" aria-labelledby="start_year_label" value="#start_year#">
									</div>
									<div class="col-12 col-md-4">
										<label for="end_year" id="end_year_label" class="data-entry-label">Start Year</label>
										<input type="text" id="end_year" name="end_year" class="data-entry-input" aria-labelledby="end_year_label" value="#end_year#">
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-md-12">
										<label for="remarks" id="remarks_label" class="data-entry-label">Remarks</label>
										<input type="text" id="remarks" name="remarks" class="data-entry-input" aria-labelledby="remarks_label" value="#encodeForHtml(remarks)#">
									</div>
								</div>
								<script>
									function changed(){
										$('##saveResultDiv').html('Unsaved changes.');
										$('##saveResultDiv').addClass('text-danger');
										$('##saveResultDiv').removeClass('text-success');
										$('##saveResultDiv').removeClass('text-warning');
									};
									$(document).ready(function() {
										$('##editJournalName input[type=text]').on("change",changed);
										$('##editJournalName input[type=checkbox]').on("change",changed);
										$('##editJournalName select').on("change",changed);
										$('##editJournalName textarea').on("change",changed);
										$('##description').on("change",changed);
									});
									function updateFromSave() { 
										console.log($("##old_journal_name").val());
										<cfif NOT inUse>
											$('##headingJournalTitle').html($('##journal_name').val());
											$('##old_journal_name').val($('##journal_name').val());
											$('##delete_journal_name').val($('##journal_name').val());
										</cfif>
									}
									function saveChanges(){ 
										saveEditsFromFormCallback("editJournalName","/publications/component/functions.cfc","saveResultDiv","saving journal name",updateFromSave);
									};
								</script> 
								<div class="form-row mb-0">
									<div class="col-12 row mx-0 px-1 mt-3">
										<input type="button" 
												value="Save" title="Save" aria-label="Save"
												class="btn btn-xs btn-primary"
												onClick="if (checkFormValidity($('##editJournalName')[0])) { saveChanges(); } " 
												>
										<output id="saveResultDiv" class="ml-2">&nbsp;</output>
									</div>
								</div>
							</form>
						</div>
					</div>
					</section>

				</main><!--- container ---> 
			</cfoutput>
		</cfif>
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfcase value="delete">
		<cftry>
			<cfif not isdefined("journal_name") OR len(trim(#journal_name#)) EQ 0 >
				<cfthrow type="Application" message="Error: No value provided for required value journal_name">
			</cfif>
			<cfquery name="confirmOne" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="confirmOne_result">
					SELECT journal_name
					FROM ctjournal_name
					WHERE
						journal_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#journal_name#">
			</cfquery>
			<cfif confirmOne.recordCount NEQ 1>
				<cfthrow type="Application" message="Error: Specified journal_name does not match exactly one ctjournal_name record.">
			</cfif>
			<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="delete_result">
					DELETE FROM ctjournal_name
					WHERE
						journal_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#journal_name#">
			</cfquery>
			<cfoutput>
				<h1 class="h2">Serial/Journal title "#encodeForHtml(journal_name)#" successfully deleted.</h1>
				<ul>
					<li><a href="/Publications.cfm">Search for Publications</a>.</li>
					<li><a href="/publications/Journals.cfm">Search for Serial/Journal Titles</a>.</li>
					<li><a href="/publications/Journal.cfm?action=new">Create a new Serial/Journal Title</a>.</li>
				</ul>
			</cfoutput>
		<cfcatch>
			<cfthrow type="Application" message="Error deleting CTJOURNAL_TITLE record: #cfcatch.Message# #cfcatch.Detail#">
		</cfcatch>
		</cftry>
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfdefaultcase>
		<cfthrow type="Application" message="Unknown action.">
	</cfdefaultcase>
</cfswitch>
<!---------------------------------------------------------------------->
<cfinclude template = "/shared/_footer.cfm">
