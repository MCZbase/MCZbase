<cfset pageTitle = "Agent Management">
<!--
agents/editAgent.cfm

Form for editing agent details and creating new agents.

Copyright 2021 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->

<!--- if we were given an action, use that, and let errors arise if requirements for action weren't met. --->
<cfif NOT isdefined("action")>
	<!--- if no action was given, but an agent_id was given, then assume we want to edit the agent, otherwise newAgent form. --->
	<cfif isdefined("agent_id")>
		<cfset action = "editAgent">
		<cfif len(agent_id) GT 0 and REFind("^[0-9]*$",agent_id) EQ 0>
			<cfinclude template="/errors/autoblacklist.cfm">
			<cfabort>
		</cfif>
	<cfelse>
		<cfset action = "new">
	</cfif>
<cfelse>
	<!--- support old api call --->
	<cfif action IS "newAgent"><cfset action = "new"></cfif>
</cfif>

<cfswitch expression="#action#">
<cfcase value="editAgent">
	<cfset pageTitle = "Edit Agent">
</cfcase>
<cfcase value="new">
	<cfset pageTitle = "Create Agent">
	<cfif isDefined("agent_type") AND len(agent_type) GT 0>
		<cfset curAgentType = agent_type>
	<cfelse>
		<!--- default expectations of the new agent page are that a person is being created, and a change of agent type hides the person elements. --->
		<cfset curAgentType = 'person'>
	</cfif>
</cfcase>
<cfcase value="createAgent">
	<cfset pageTitle = "Saving New Agent">
</cfcase>
</cfswitch>

<cfset includeJQXEditor='true'>
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/agents/component/functions.cfc" runOnce="true">

<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>
<cfquery name="ctAgentType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select agent_type from ctagent_type order by agent_type
</cfquery>
<cfquery name="ctNameType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select agent_name_type as agent_name_type from ctagent_name_type where agent_name_type != 'preferred' order by agent_name_type
</cfquery>
<cfquery name="ctAddrType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select addr_type from ctaddr_type
	where addr_type <> 'temporary'
</cfquery>
<cfquery name="ctElecAddrType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select address_type from ctelectronic_addr_type
</cfquery>
<cfquery name="ctprefix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select prefix from ctprefix order by prefix
</cfquery>
<cfquery name="ctsuffix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select suffix from ctsuffix order by suffix
</cfquery>
<cfquery name="ctRelns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select AGENT_RELATIONSHIP from CTAGENT_RELATIONSHIP
</cfquery>
<cfquery name="ctguid_type_agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
   from ctguid_type 
   where applies_to like '%agent.agentguid%'
</cfquery>

<cfswitch expression="#action#">
<cfcase value="editAgent">
	<cfif NOT isdefined("agent_id")>
		<cfoutput>
			<cfthrow message="Agent to edit not specified.  No Agent ID provided">
		</cfoutput>
	<cfelse>
		<cfoutput>
			<main class="container py-3" id="content">
				<script>
					function getAssembledName() {
						var result = "";
						if ($('##last_name').val()!="") {
							result = $('##last_name').val();
						}
						if ($('##middle_name').val()!="") {
							result = $('##middle_name').val() + " " + result;
						}
						if ($('##first_name').val()!="") {
							result = $('##first_name').val() + " " + result;
						}
						if (result == "") {
							result = $('##pref_name').val();
						}
						return result;
					}
				</script>
				<cfquery name="getAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAgent_result">
					SELECT 
						agent.agent_id,
						agent.agent_type, 
						agent.edited, 
						agent.agent_remarks, 
						agent.biography,
						agent.agentguid_guid_type, agentguid,
						agent.eori_number,
						prefername.agent_name as preferred_agent_name,
						person.prefix,
						person.suffix,
						person.first_name,
						person.last_name,
						person.middle_name,
						person.birth_date,
						person.death_date,
						null as start_date,
						null as end_date,
						MCZBASE.get_collectorscope(agent.agent_id,'collections') as collections_scope
					FROM 
						agent
						left join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
						left join person on agent.agent_id = person.person_id
					WHERE
						agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
				</cfquery>
				<cfif getAgent.recordcount EQ 0>
					<h1>No such agent as agent_id = #encodeForHtml(agent_id)#.</h1>
				<cfelse>
					<cfloop query="getAgent">
						<cfset relatedTo = StructNew() >
						<cfset okToDelete = false>
						<cftry>
							<cfquery name="getFKFields" datasource="uam_god">
								SELECT dba_constraints.table_name, column_name, delete_rule 
								FROM dba_constraints
									left join dba_cons_columns on dba_constraints.constraint_name = dba_cons_columns.constraint_name and dba_constraints.owner = dba_cons_columns.owner
								WHERE r_constraint_name in (select constraint_name from dba_constraints where table_name='AGENT')
								ORDER BY dba_constraints.table_name
							</cfquery>
							<cfset okToDelete = true>
							<cfloop query="getFKFields">
								<cfif getFKFields.delete_rule EQ "NO ACTION">
									<cfquery name="getRels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getRels_result">
										SELECT count(*) as ct 
										FROM #getFKFields.table_name#
										WHERE #getFKFields.column_name# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
									</cfquery>
									<cfif getRels.ct GT 0>
										<!--- note, since preferred name is required, and can't be deleted, and agent_name fk agent_id fk delete rule is NO ACTION, this will never be enabled --->
										<cfset okToDelete = false>
										<cfset relatedTo["#getFkFields.table_name#.#getFkFields.column_name#"] = getRels.ct>
									</cfif>
								</cfif>
							</cfloop>
						<cfcatch>
							<!--- some issue with user access to metadata tables --->
						</cfcatch>
						</cftry>
						<cfif getAgent.edited EQ 1>
							<cfset vetted="*">
						<cfelse>
							<cfset vetted="">
						</cfif>
						<cfset nameStr = "<strong>#getAgent.preferred_agent_name##vetted#</strong>">  <!--- " --->
						<cfif getAgent.agent_type EQ "person">
							<!--- add birth death years --->
							<cfset nameStr = nameStr & assembleYearRange(start_year="#birth_date#",end_year="#death_date#",year_only=false) >
						</cfif>
						<div class="container">
							<div class="form-row">
								<div class="col-12">
									<h1 class="h2 my-2">Edit #getAgent.agent_type# agent: #nameStr# [Agent ID: <a href="/agents/Agent.cfm?agent_id=#getAgent.agent_id#">#getAgent.agent_id#</a>]</h1>
									<cfif len(getAgent.collections_scope) GT 0>
										<p class="mb-1">Collector of MCZ material: #collections_scope#</p>
									</cfif>
								</div>
 								<cfif listcontainsnocase(session.roles, "manage_transactions")>
									<div class="col-12 col-md-4">
										<h2 class="h3"><a href="/agents/Agent.cfm?agent_id=#agent_id#" target="_blank">Agent Activity</a></h2>
									</div>
									<div class="col-12 col-md-4">
										<cfquery name="rank" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT count(*) || ' ' || agent_rank agent_rank
											FROM agent_rank
											WHERE agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											group by agent_rank
										</cfquery>
										<span id="agentRankSummary" style="font-size: 13px;margin: 1em 0;">
											<cfif rank.recordcount gt 0>
												Previous Ranking: #valuelist(rank.agent_rank,"; ")#
												<cfif #valuelist(rank.agent_rank,"; ")# contains 'F'>
													<img src='/agents/images/flag-red.svg.png' width='16'>
												<cfelseif #valuelist(rank.agent_rank,"; ")# contains 'D'>
													<img src='/agents/images/flag-yellow.svg.png' width='16'>
												<cfelseif #valuelist(rank.agent_rank,"; ")# contains 'C'>
													<img src='/agents/images/flag-yellow.svg.png' width='16'>
												<cfelseif #valuelist(rank.agent_rank,"; ")# contains 'B'>
													<img src='/agents/images/flag-yellow.svg.png' width='16'>
												</cfif>
											</cfif>
										</span>
									</div>
									<div class="col-12 col-md-4">
										<cfif listcontainsnocase(session.roles,"manage_transactions")>
											<script>
												function reloadAgentRanks() { 
													loadAgentRankSummary('agentRankSummary',#agent_id#);
												}
											</script>
											<cfif listcontainsnocase(session.roles,"manage_agent_ranking")>
												<cfset rankButtonText = "View/Add Rankings">
												<cfset rankButtonLabel = "View or Add Rankings for this agent">
											<cfelse>
												<cfset rankButtonText = "View Rankings">
												<cfset rankButtonLabel = "View Rankings for this agent">
											</cfif>
 											<input type="button" class="btn btn-xs btn-secondary" value="#rankButtonText#" aria-label="#rankButtonLabel#" 
												onclick="openRankDialog('agentRankDlg_#agent_id#','Rank Agent #getAgent.preferred_agent_name#',#agent_id#, reloadAgentRanks); ">
											&nbsp;&nbsp;
											<i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Agent_Ranking')" aria-label="help link"></i>
										</cfif>
										<div id="agentRankDlg_#agent_id#"></div>
									</div>
								</cfif>
							</div>
						</div>
						<section class="row mx-0 border rounded my-2 pt-3 pb-0">
							<form class="col-12" name="editAgentForm" id="editAgentForm" action="/agents/editAgent.cfm" method="post">
								<input type="hidden" name="method" value="saveAgent">
								<input type="hidden" name="agent_id" value="#getAgent.agent_id#">
								<!--- function handleChange: action to take when an input has its value changed, binding to inputs below --->
								<script>
									function handleChange(){
										$('##saveResultDiv').html('Unsaved changes.');
										$('##saveResultDiv').addClass('text-danger');
										$('##saveResultDiv').removeClass('text-success');
										$('##saveResultDiv').removeClass('text-warning');
									};
									function changeType() { 
										var selectedType = $('##agent_type').val();
										if (selectedType == 'person') { 
											$('##personRow').show();
											$('##headingTypeSpan').html("Person");
											$('##last_name').prop('required',true);
											$('##start_date_label').html("Date of Birth");
											$('##end_date_label').html("Date of Death");
											$('##start_date').prop('disabled', false);
											$('##end_date').prop('disabled', false);
											$('##eoriDiv').hide();
										} else { 
											$('##eoriDiv').hide();
											if (selectedType == 'organization') {
												$('##eoriDiv').show();
											} 
											$('##personRow').hide();
											$('##headingTypeSpan').html(selectedType);
											$('##last_name').removeAttr('required');
											$('##start_date_label').html("Start Date");
											$('##end_date_label').html("End Date");
											$('##start_date').prop('disabled', true);
											$('##end_date').prop('disabled', true);
										}
									};
									function resetToPerson() { 
										$("##agent_type option[value='person']").prop('selected',true);
									}
									function changeTypeFromPerson() { 
										confirmOrCancelDialog("Change this agent from a person to a non-person type.  On save, name will be moved to an aka name and birth/death dates will be moved to remarks.", "Confirm Change From Person", changeType, resetToPerson);
									};
									$(document).ready(function(){
										changeType();
									});
								</script>
								<div class="form-row mb-1">
									<div class="col-12 col-md-4">
										<label for="agent_type" class="data-entry-label">Type of Agent</label>
										<cfset curAgentType = getAgent.agent_type>
										<cfif curAgentType EQ "person">
											<!--- Backing suppors allow change of person to non-person, saving names and dates as remarks, but ask user first --->
											<select name="agent_type" id="agent_type" size="1" onChange=" changeTypeFromPerson(); " class="data-entry-select reqdClr" required>
												<cfloop query="ctAgentType">
													<cfif isdefined("curAgentType") and len(curAgentType) GT 0 and curAgentType IS ctAgentType.agent_type>
														<cfset selected = "selected='selected'">
													<cfelse>
														<cfset selected = "">
													</cfif>
													<option value="#ctAgentType.agent_type#" #selected#>#ctAgentType.agent_type#</option>
												</cfloop>
											</select>
										<cfelse>
											<!--- no potential loss of information, just make the change --->
											<select name="agent_type" id="agent_type" size="1" onChange=" changeType(); " class="data-entry-select reqdClr" required>
												<cfloop query="ctAgentType">
													<cfif isdefined("curAgentType") and len(curAgentType) GT 0 and curAgentType IS ctAgentType.agent_type>
														<cfset selected = "selected='selected'">
													<cfelse>
														<cfset selected = "">
													</cfif>
													<option value="#ctAgentType.agent_type#" #selected#>#ctAgentType.agent_type#</option>
												</cfloop>
											</select>
										</cfif>
									</div>
									<div class="col-12 col-md-1">
										<label for="vetted" class="data-entry-label">Vetted</label>
										<select name="vetted" size="1" id="vetted" class="data-entry-select">
											<option value=1 <cfif #getAgent.edited# EQ 1>selected</cfif>>yes *</option>
											<option value=0 <cfif #getAgent.edited# EQ 0 or #getAgent.edited# EQ "">selected</cfif>>no</option>
										</select>
									</div>
									<div class="col-12 col-md-5">
										<label for="pref_name" class="data-entry-label">Preferred Name</label>
											<input type="text" name="pref_name" id="pref_name" class="data-entry-input reqdClr" required value="#getAgent.preferred_agent_name#">
											<script>
												$(document).ready(function () {
													$('##pref_name').change(function () {
														checkNameExistsAlso($('##pref_name').val(),'name_matches',#agent_id#);
													});
													checkNameExistsAlso($('##pref_name').val(),'name_matches',#agent_id#);
												});
											</script>
										</div>
									<div class="col-12 col-md-2">
										<label for="name_matches" class="data-entry-label">Duplicate check</label>
										<div id="name_matches" class="text-success p-1 small90 font-weight-lessbold"></div>
									</div>
								</div>
								<div id="personRow" class="form-row mb-1">
									<!--- we'll load the page as if for a person, and if editing a person, will hide this row (allowing a non-person to be changed into a person). --->
									<div class="col-12 col-md-2">
										<label for="prefix" class="data-entry-label">Prefix</label>
										<select name="prefix" id="prefix" size="1" class="data-entry-select">
											<option value=""></option>
											<cfloop query="ctprefix">
												<cfif ctprefix.prefix EQ getAgent.prefix><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option value="#ctprefix.prefix#" #selected#>#ctprefix.prefix#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-3">
										<label for="first_name"class="data-entry-label">First Name</label>
										<input type="text" name="first_name" id="first_name"class="data-entry-input" value="#getAgent.first_name#">
									</div>
									<div class="col-12 col-md-2">
										<label for="middle_name" class="data-entry-label">Middle Name</label>
										<input type="text" name="middle_name" id="middle_name"class="data-entry-input" value="#getAgent.middle_name#">
									</div>
									<div class="col-12 col-md-3">
										<cfif getAgent.agent_type EQ "person"><cfset req="required"><cfelse><cfset req=""></cfif>
										<label for="last_name"class="data-entry-label">Last Name</label>
										<input type="text" name="last_name" id="last_name" class="data-entry-input reqdClr" #req# value="#getAgent.last_name#">
									</div>
									<div class="col-12 col-md-2">
										<label for="suffix"class="data-entry-label">Suffix</label>
										<select name="suffix" size="1" id="suffix" class="data-entry-select">
											<option value=""></option>
											<cfloop query="ctsuffix">
												<cfif ctsuffix.suffix EQ getAgent.suffix><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option value="#suffix#" #selected#>#suffix#</option>
											</cfloop>
									  	</select>
									</div>
								</div>
								<div class="form-row mb-1">
									<div class="col-12 col-md-6">
										<cfset pattern = "">
										<cfset placeholder = "">
										<cfset regex = "">
										<cfset replacement = "">
										<cfset searchlink = "" >
										<cfset searchtext = "" >
										<cfset searchclass = "" >
										<cfloop query="ctguid_type_agent">
						 					<cfif getAgent.agentguid_guid_type is ctguid_type_agent.guid_type OR ctguid_type_agent.recordcount EQ 1 >
												<cfset searchlink = ctguid_type_agent.search_uri & replace(EncodeForURL(trim(getAgent.first_name & ' ' & trim(getAgent.middle_name & ' ' & getAgent.last_name))),'+','%20') >
												<cfif len(getAgent.agentguid) GT 0>
													<cfset searchtext = "Edit" >
													<cfset searchclass = 'class="btn btn-xs btn-secondary editGuidButton"' >
												<cfelse>
													<cfset searchtext = "Find GUID" >
													<cfset searchclass = 'class="btn btn-xs btn-info findGuidButton external"' >
												</cfif>
											</cfif>
										</cfloop>
										<div class="col-6 col-md-4 px-0 float-left">
											<label for="agentguid"class="data-entry-label">GUID for Agent&nbsp;<i class="fas fas-info fa-info-circle" onclick="getMCZDocs('Add_Agent_GUID_from_ORCID')" aria-label="help link"></i></label>
											<select name="agentguid_guid_type" id="agentguid_guid_type" size="1" class="data-entry-select">
												<cfif searchtext EQ "">
													<option value=""></option>
												</cfif>
												<cfloop query="ctguid_type_agent">
													<cfset sel="">
													<cfif ctguid_type_agent.guid_type EQ getAgent.agentguid_guid_type OR ctguid_type_agent.recordcount EQ 1 >
														<cfset sel="selected='selected'">
														<cfset placeholder = "#ctguid_type_agent.placeholder#">
														<cfset pattern = "#ctguid_type_agent.pattern_regex#">
														<cfset regex = "#ctguid_type_agent.resolver_regex#">
														<cfset replacement = "#ctguid_type_agent.resolver_replacement#">
													</cfif>
													<option #sel# value="#ctguid_type_agent.guid_type#">#ctguid_type_agent.guid_type#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-6 col-md-2 w-100 px-0 float-left"> 
											<label class="data-entry-label">&nbsp;</label>
											<a href="#searchlink#" id="agentguid_search" target="_blank" #searchclass#>#searchtext#</a>
										</div>
										<div class="col-12 col-md-6 pl-0 float-left">
											<label class="data-entry-label">&nbsp;</label>
											<input class="data-entry-input" name="agentguid" id="agentguid" 
												value="#getAgent.agentguid#" placeholder="#placeholder#" pattern="#pattern#" title="Enter a guid in the form #placeholder#">
											<cfif len(regex) GT 0 >
												<cfset link = REReplace(getAgent.agentguid,regex,replacement)>
											<cfelse>
												<cfset link = getAgent.agentguid>
											</cfif>
											<a id="agentguid_link" href="#link#" target="_blank" class="px-1 pt-0 pb-3 d-block line-height-sm small90">#agentguid#</a>
										</div>
										<script>
											$(document).ready(function () {
												if ($('##agentguid').val().length > 0) {
													$('##agentguid').hide();
												}
												$('##agentguid_search').click(function (evt) {
													switchGuidEditToFind('agentguid','agentguid_search','agentguid_link',evt);
												});
												$('##agentguid_guid_type').change(function () {
													// On selecting a guid_type, remove an existing guid value.
													$('##agentguid').val("");
													// On selecting a guid_type, change the pattern.
													getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
												});
												$('##agentguid').blur( function () {
													// On loss of focus for input, validate against the regex, update link
													getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
												});
												$('##first_name').change(function () {
													// On changing prefered name, update search.
													getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
												});
												$('##middle_name').change(function () {
													// On changing prefered name, update search.
													getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
												});
												$('##last_name').change(function () {
													// On changing prefered name, update search.
													getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
												});
												$('##pref_name').change(function () {
													// On changing prefered name, update search.
													getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
												});
											});
										</script>
									</div>
									<div class="col-12 col-md-3">
										<cfif curAgentType EQ "person">
											<cfset label="Date of Birth">
											<cfset sd = getAgent.birth_date>
										<cfelse>
											<cfset label="Start Date">
											<cfset sd = getAgent.start_date>
										</cfif>
										<label id="start_date_label" for="start_date" class="data-entry-label">#label#</label>
										<input type="text" name="start_date" id="start_date" value="#sd#" class="data-entry-input" placeholder="yyyy, yyyy-mm-dd, or yyyy-mm">
									</div>
									<div class="col-12 col-md-3">
										<cfif curAgentType EQ "person">
											<cfset label="Date of Death">
											<cfset ed = getAgent.death_date>
										<cfelse>
											<cfset label="End Date">
											<cfset ed = getAgent.end_date>
										</cfif>
										<label id="end_date_label" for="end_date" class="data-entry-label">#label#</label>
										<input type="text" name="end_date" id="end_date" value="#ed#" class="data-entry-input" placeholder="yyyy, yyyy-mm-dd, or yyyy-mm">
									</div>
									<script>
										$(document).ready(function() {
											$("##start_date").datepicker({ dateFormat: 'yy-mm-dd'});
											$("##end_date").datepicker({ dateFormat: 'yy-mm-dd'});
										});
									</script>
									<cfset eoriStyle = "display: none; ">
									<cfif curAgentType EQ "organization">
										<cfset eoriStyle = "">
									</cfif>
									<div class="col-12 col-md-4" id="eoriDiv" style="#eoriStyle#">
										<label id="eori_number_label" for="eori_number" class="data-entry-label">EORI Number</label>
										<input type="text" name="eori_number" id="eori_number" value="#eori_number#" class="data-entry-input">
									</div>
								</div>
								<div class="form-row mb-1">
									<div class="col-12 col-md-6 mt-1" >
										<label for="biography" class="data-entry-label">Public Biography</label>
										<textarea name="biography" id="biography" class="w-100"></textarea>
										<script>
											$(document).ready(function () {
												$('##biography').jqxEditor({lineBreak:"p"});
												$('##biography').jqxEditor("val","#encodeForJavaScript(trim(biography))#");
											});
										</script>
									</div>
									<div class="col-12 col-md-6 mt-1">
										<label for="agent_remarks" class="data-entry-label">Internal Remarks</label>
										<textarea name="agent_remarks" id="agent_remarks" class="w-100"></textarea>
										<script>
											$(document).ready(function () {
												$('##agent_remarks').jqxEditor({lineBreak:"p"});
												$('##agent_remarks').jqxEditor("val","#encodeForJavascript(trim(agent_remarks))#");
											});
										</script>
									</div>
								</div>
								</div>
								<div class="form-row mt-1 mb-1">
									<div class="form-group col-12">
										<input type="button" value="Save" class="btn btn-xs btn-primary mr-2"
											onClick="if (checkFormValidity($('##editAgentForm')[0])) { saveEdits();  } " 
											id="submitButton" >
										<output id="saveResultDiv" class="text-danger">&nbsp;</output>	
										<cfif okToDelete>
											<input type="button" value="Delete Agent" class="btn btn-xs btn-danger float-right"
											onClick=" $('##action').val('editAgent'); confirmDialog('Delete this Agent?','Confirm Delete Agent', function() { $('##action').val('deleAgent'); $('##editAgentForm').submit(); } );">
										<cfelse>
											<div class="float-right">
												<cfset relCount = StructCount(relatedTo)>
												<cfif relCount GT 0>
													<cfif relCount EQ 1 ><cfset plural = ""><cfelse><cfset plural="s"></cfif>
													<button type="button" class="btn btn-xs btn-outline-primary" id="showRelatedDataBtn">Related to #relCount# other table#plural#</button>
													<cfset relations = "">
													<cfset sep = "">
													<cfloop collection="#relatedTo#" item="key">
														<cfset relations = "#relations##sep##key# (#relatedTo[key]#)">
														<cfset sep = "; <br>">
													</cfloop>
													<script>
														$(document).ready(function() {
															$('##showRelatedDataBtn').click(function (evt) {
																messageDialog("#relations#","Numbers of related records for this agent");
															});
														});
													</script>
												</cfif>
											</div>
										</cfif>
									</div>
								</div>
								<script>
									$(document).ready(function() {
										monitorForChanges('editAgentForm',handleChange);
									});
									function saveEdits(){ 
										saveEditsFromFormCallback("editAgentForm","/agents/component/functions.cfc","saveResultDiv","saving agent record",reloadAgentNames);
									};
									function suggestName(ntype,targetInput){
										try {
											var fName= $('##first_name').val();
											var mName= $('##middle_name').val();
											var lName= $('##last_name').val();
											var name='';
											if (ntype=='initials plus last'){
												if (fName.length>0){
													name=fName.substring(0,1) + '. ';
												}
												if (mName.length>0){
													name+=mName.substring(0,1) + '. ';
												}
												if (lName.length>0){
													name+=lName;
												} else {
													name='';
												}
											}
											if (ntype=='last plus initials'){
												if (lName.length>0){
													name=lName + ', ';
													if (fName.length>0){
														name+=fName.substring(0,1) + '. ';
													}
													if (mName.length>0){
														name+=mName.substring(0,1) + '. ';
													}
												} else {
													name='';
												}
											}
											if (name.length>0){
												var rf = $('##agent_name');
												var tName=name.replace(/^\s+|\s+$/g,""); // trim spaces
												if ($('##'+targetInput).val().length==0){
													$('##'+tergetInput).val(tName);
												}
											}
										}
										catch(e){
										}
									}
								</script>
							</form>
						</section>
						<div class="row">
							<div class="col-12 col-lg-12 col-xl-5 pr-xl-2">
								<section class="row border rounded my-2 mx-0 px-1 pt-2 pb-3">
									<div class="col-12">
										<script>
											// callback for ajax methods to reload names for agent
											function reloadAgentNames() { 
												updateAgentNames(#getAgent.agent_id#,'namesDiv');
											};
										</script>
										<h2 class="h3">Names for this agent</h2>
										<cfset namesBlock = getAgentNamesHTML(agent_id="#agent_id#")>
										<div id="namesDiv" class="pb-1">#namesBlock#</div>
									</div>
								</section>
							</div>
							<div class="col-12 col-lg-12 col-xl-7 pl-xl-2">
								<section class="row border rounded my-2 mx-0 px-1 pt-2 pb-3">
									<div class="col-12">
										<h2 class="h3">Relationships for this agent</h2>
										<cfset relationsBlock = getAgentRelationshipsHTML(agent_id="#agent_id#")>
										<div id="relationsDiv" class="pb-1">#relationsBlock#</div>
										<script>
											// callback for ajax methods to reload 
											function reloadRelationships() { 
												updateAgentRelationships(#getAgent.agent_id#,'relationsDiv');
											};
										</script>
									</div>
								</section>
							</div>
						</div>
						<cfif #getAgent.agent_type# IS "group" OR #getAgent.agent_type# IS "expedition" OR #getAgent.agent_type# IS "vessel">
							<section class="row border rounded my-2 px-1 pt-2 pb-3 mx-0">
								<div class="col-12">
									<script>
										// callback for ajax methods to reload group members for agent
										function reloadGroupMembers() { 
											updateGroupMembers(#getAgent.agent_id#,'groupMembersDiv');
										};
									</script>
									<h2 class="h3">Group Members</h2>
									<cfset groupMembersBlock = getGroupMembersHTML(agent_id="#agent_id#")>
									<div id="groupMembersDiv" class="pb-1">#groupMembersBlock#</div>
								</div>
							</section>
						</cfif>
						<div class="row">
							<div class="col-12 col-lg-12 col-xl-6 pr-xl-2">
								<section class="row border rounded mx-0 my-2 px-1 pt-2 pb-3">
									<div class="col-12">
										<h2 class="h3">Addresses for this agent</h2>
										<cfset addressesBlock = getAgentAddressesHTML(agent_id="agent_id")>
										<div id="addressesDiv" class="pb-1">#addressesBlock#</div>
										<script>
											// callback for ajax methods to reload group members for agent
											function reloadAddresses() { 
												updateAgentAddresses(#getAgent.agent_id#,'addressesDiv');
											};
										</script>
									</div>
								</section>
							</div>
							<div class="col-12 col-lg-12 col-xl-6 pl-xl-2">
								<section class="row border rounded my-2 px-1 pt-2 pb-3 mx-0">
									<div class="col-12">
										<h2 class="h3">Phone numbers/Email addresses</h2>
										<cfset electronicAddressesBlock = getElectronicAddressesHTML(agent_id="#agent_id#")>
										<div id="electronicAddressesDiv" class="pb-1">#electronicAddressesBlock#</div>
										<script>
											// callback for ajax methods to reload 
											function reloadElectronicAddresses() { 
												updateElectronicAddresses(#getAgent.agent_id#,'electronicAddressesDiv');
											};
										</script>
									</div>
								</section>
							</div>
						</div>
					</cfloop>
				</cfif>
			</main>
		</cfoutput>
	</cfif>
</cfcase>
<cfcase value="new">
	<cfoutput>
		<script>
			function getAssembledName() {
				var result = "";
				if ($('##last_name').val()!="") {
					result = $('##last_name').val();
				}
				if ($('##middle_name').val()!="") {
					result = $('##middle_name').val() + " " + result;
				}
				if ($('##first_name').val()!="") {
					result = $('##first_name').val() + " " + result;
				}
				if (result == "") {
					result = $('##pref_name').val();
				}
				return result;
			}
		</script>
		<main id="content">
			<section class="container-fluid container-xl mt-2">
				<div class="row">
					<div class="col-12 mt-2 mb-3">
						<cfif isdefined("agent_type") and len(agent_type) GT 0>
							<h1 class="h2 mt-3 pl-1 ml-2">Create New <span id="headingTypeSpan">#encodeForHtml(agent_type)#</span> Agent</h2>
						<cfelse>
							<h1 class="h2 pl-1 ml-2 mt-3">Create New <span id="headingTypeSpan"></span> Agent</h2>
						</cfif>
						<div class="border rounded px-3 py-3">
							<form id="newAgentForm" name="newAgentForm" method="post" action="/agents/editAgent.cfm">
							<input type="hidden" name="action" value="createAgent">
							<div class="form-row mb-1">
								<div class="col-12 col-md-4">
									<script>
										function changeType() { 
											var selectedType = $('##agent_type').val();
											if (selectedType == 'person') { 
												$('##personRow').show();
												$('##headingTypeSpan').html("Person");
												$('##last_name').prop('required',true);
												$('##start_date_label').html("Date of Birth");
												$('##end_date_label').html("Date of Death");
												$('##start_date').prop('disabled', false);
												$('##end_date').prop('disabled', false);
												$('##eoriDiv').hide();
											} else { 
												$('##eoriDiv').hide();
												if (selectedType == 'organization') {
													$('##eoriDiv').show();
												} 
												$('##personRow').hide();
												$('##headingTypeSpan').html(selectedType);
												$('##last_name').removeAttr('required');
												$('##start_date_label').html("Start Date");
												$('##end_date_label').html("End Date");
												$('##start_date').prop('disabled', true);
												$('##end_date').prop('disabled', true);
											}
										}
									</script>
									<label for="agent_type" class="data-entry-label">Type of Agent</label>
									<select name="agent_type" id="agent_type" size="1" onChange=" changeType(); " class="data-entry-select reqdClr" required>
										<cfloop query="ctAgentType">
											<cfif isdefined("curAgentType") and len(curAgentType) GT 0 and curAgentType IS ctAgentType.agent_type>
												<cfset selected = "selected='selected'">
											<cfelse>
												<cfset selected = "">
											</cfif>
											<option value="#ctAgentType.agent_type#" #selected#>#ctAgentType.agent_type#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-1">
									<label for="vetted" class="data-entry-label">Vetted</label>
									<select name="vetted" size="1" id="vetted" class="data-entry-select" required>
										<option value=0 selected >no</option>
										<option value=1 >yes *</option>
									</select>
								</div>
								<div class="col-12 col-md-5">
									<label for="pref_name" class="data-entry-label">Preferred Name</label>
									<input type="text" name="pref_name" id="pref_name" class="data-entry-input reqdClr" required>
									<script>
										$(document).ready(function () {
											$('##pref_name').change(function () {
												checkNameExists($('##pref_name').val(),'name_matches',false);
											});
										});
									</script>
								</div>
								<div class="col-12 col-md-2">
									<label for="name_matches" class="data-entry-label">Duplicate check</label>
									<output id="name_matches" class="text-success font-weight-lessbold p-1"></output>
								</div>
							</div>
							<div id="personRow" class="form-row mb-1">
								<!--- we'll load the page as if for a new person, and if not a new person, will hide this row. --->
								<div class="col-12 col-md-2">
									<label for="prefix" class="data-entry-label">Prefix</label>
									<select name="prefix" id="prefix" size="1" class="data-entry-select">
										<option value=""></option>
										<cfloop query="ctprefix">
											<option value="#prefix#">#prefix#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-2">
									<label for="first_name"class="data-entry-label">First Name</label>
									<input type="text" name="first_name" id="first_name"class="data-entry-input">
								</div>
								<div class="col-12 col-md-2">
									<label for="middle_name" class="data-entry-label">Middle Name</label>
									<input type="text" name="middle_name" id="middle_name"class="data-entry-input">
								</div>
								<div class="col-12 col-md-2">
									<cfif curAgentType EQ "person"><cfset req="required"><cfelse><cfset req=""></cfif>
									<label for="last_name"class="data-entry-label">Last Name</label>
									<input type="text" name="last_name" id="last_name" class="data-entry-input reqdClr" #req#>
								</div>
								<div class="col-12 col-md-2">
									<label for="suffix"class="data-entry-label">Suffix</label>
									<select name="suffix" size="1" id="suffix" class="data-entry-select">
										<option value=""></option>
										<cfloop query="ctsuffix">
											<option value="#suffix#">#suffix#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-2">
									<label for="paste_to_preferred"class="data-entry-label">Copy to preferred name</label>
									<input type="button" id="paste_to_preferred" class="btn btn-secondary btn-xs" value="Copy" onclick="pasteFMLtoPreferred();">
								</div>
								<script>
									function pasteFMLtoPreferred() {
										if ($('##pref_name').val()=='') { 
											var fml = $('##prefix option:selected').text() + " " + $('##first_name').val() + " " + $('##middle_name').val() + " " + $('##last_name').val() + " " +  $('##suffix option:selected').text();
											$('##pref_name').val(fml.trim().replace("  "," "));
										} else { 
											messageDialog("You must edit an existing preferred name by hand.");
										} 
									}
								</script>
							</div>
							<div class="form-row mb-1">
								<div class="col-12 col-md-6">
									<label for="agentguid"class="data-entry-label">GUID for Agent</label>
									<cfset pattern = "">
									<cfset placeholder = "">
									<cfset regex = "">
									<cfset replacement = "">
									<cfset searchlink = "" >
									<cfset searchtext = "" >
									<div class="col-6 col-md-3 col-xl-3 px-0 float-left">
										<select name="agentguid_guid_type" id="agentguid_guid_type" size="1" class="data-entry-select">
											<cfif searchtext EQ "">
												<option value=""></option>
											</cfif>
											<cfloop query="ctguid_type_agent">
												<cfset sel="">
												<cfif ctguid_type_agent.recordcount EQ 1 >
													<cfset sel="selected='selected'">
													<cfset placeholder = "#ctguid_type_agent.placeholder#">
													<cfset pattern = "#ctguid_type_agent.pattern_regex#">
													<cfset regex = "#ctguid_type_agent.resolver_regex#">
													<cfset replacement = "#ctguid_type_agent.resolver_replacement#">
												</cfif>
												<option #sel# value="#ctguid_type_agent.guid_type#">#ctguid_type_agent.guid_type#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-6 col-md-7 col-xl-3 w-100 px-0 float-left"> 
										<a href="#searchlink#" id="agentguid_search" target="_blank" class="small90">#searchtext#</a>
									</div>
									<div class="col-12 col-md-7 col-xl-6 pl-0 float-left">
										<input class="data-entry-input" name="agentguid" id="agentguid" 
											value="" placeholder="#placeholder#" pattern="#pattern#" title="Enter a guid in the form #placeholder#">
										<a id="agentguid_link" href="" target="_blank" class="px-1 py-0 d-block line-height-sm mt-1 small90"></a> 
									</div>
									<script>
										$(document).ready(function () {
											if ($('##agentguid').val().length > 0) {
												$('##agentguid').hide();
											}
											$('##agentguid_search').click(function (evt) {
												switchGuidEditToFind('agentguid','agentguid_search','agentguid_link',evt);
											});
											$('##agentguid_guid_type').change(function () {
												// On selecting a guid_type, remove an existing guid value.
												$('##agentguid').val("");
												// On selecting a guid_type, change the pattern.
												getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
											});
											$('##agentguid').blur( function () {
												// On loss of focus for input, validate against the regex, update link
												getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
											});
											$('##first_name').change(function () {
												// On changing prefered name, update search.
												getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
											});
											$('##middle_name').change(function () {
												// On changing prefered name, update search.
												getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
											});
											$('##last_name').change(function () {
												// On changing prefered name, update search.
												getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
											});
											$('##pref_name').change(function () {
												// On changing prefered name, update search.
												getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
											});
										});
									</script>
								</div>
								<div class="col-12 col-md-3">
									<cfif curAgentType EQ "person">
										<cfset label="Date of Birth">
									<cfelse>
										<cfset label="Start Date">
									</cfif>
									<label id="start_date_label" for="start_date" class="data-entry-label">#label#</label>
									<input type="text" name="start_date" id="start_date" class="data-entry-input" placeholder="yyyy, yyyy-mm-dd, or yyyy-mm">
								</div>
								<div class="col-12 col-md-3">
									<cfif curAgentType EQ "person">
										<cfset label="Date of Death">
									<cfelse>
										<cfset label="End Date">
									</cfif>
									<label id="end_date_label" for="end_date" class="data-entry-label">#label#</label>
									<input type="text" name="end_date" id="end_date" class="data-entry-input" placeholder="yyyy, yyyy-mm-dd, or yyyy-mm">
								</div>
								<script>
									$(document).ready(function() {
										$("##start_date").datepicker({ dateFormat: 'yy-mm-dd'});
										$("##end_date").datepicker({ dateFormat: 'yy-mm-dd'});
									});
								</script>
								<div class="col-12 col-md-4" id="eoriDiv" style="display: none;">
									<label id="eori_number_label" for="eori_number" class="data-entry-label">EORI Number</label>
									<input type="text" name="eori_number" id="eori_number" value="" class="data-entry-input">
								</div>
							</div>
							<div class="form-row mb-1">
								<div class="col-12">
									<label for="biography" class="data-entry-label">Public Biography</label>
									<textarea name="biography" id="biography" class="w-100"></textarea>
									<script>
										$(document).ready(function () {
											$('##biography').jqxEditor({width:'auto',height: '223px'});
										});
									</script>
								</div>
							</div>
							<div class="form-row mb-1">
								<div class="col-12">
									<label for="agent_remarks" class="data-entry-label">Internal Remarks</label>
									<textarea name="agent_remarks" id="agent_remarks" class="w-100"></textarea>
									<script>
										$(document).ready(function () {
											$('##agent_remarks').jqxEditor({width:'auto',height: '223px'});
										});
									</script>
								</div>
							</div>
							<div class="form-row mt-2">
								<div class="col-12 col-md-3">
									<input type="submit" value="Add New Agent" class="btn btn-xs btn-primary">
								</div>
							</div>
							<cfif isdefined("curAgentType") and len(curAgentType) GT 0 and curAgentType IS "person">
								<!--- no action needed, this is the default load state for this form --->
							<cfelse>
								<!--- change elements appropriately --->
								<script>
									$(document).ready(function () {
										changeType();
									});
								</script>
							</cfif>
						</form>
						</div>
					</div>
				</div>
			</section>
		</main>
	</cfoutput>
</cfcase>
<cfcase value="createAgent">
	<cfoutput>
		<cfif NOT isdefined('agent_type') OR len(trim(agent_type)) EQ 0>
			<cfthrow message="Unable to create agent: agent type is required and was not supplied">
		</cfif>
		<cfif agent_type EQ "person" AND (NOT isdefined('LAST_NAME') OR len(trim(LAST_NAME)) EQ 0)>
			<cfthrow message="Unable to create agent: last name is required for agents of type person and was not supplied">
		</cfif>
		<cfif NOT isdefined('pref_name') OR len(trim(pref_name)) EQ 0>
			<cfthrow message="Unable to create agent: preferred name is required and was not supplied">
		</cfif>
		<cfquery name="agentTypeCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT agent_type 
			FROM ctagent_type 
			WHERE agent_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_type#">
		</cfquery>
		<cfif agentTypeCheck.recordcount NEQ 1>
			<cfthrow message="Unable to create agent.  Unknown agent type [#encodeForHtml(agent_type)#]">
		</cfif>
		<cftransaction>
			<cftry>
				<cfquery name="agentID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select sq_agent_id.nextval nextAgentId from dual
				</cfquery>
				<cfquery name="agentNameID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select sq_agent_name_id.nextval nextAgentNameId from dual
				</cfquery>
				<cfquery name="insAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					INSERT INTO agent (
						agent_id,
						agent_type,
						preferred_agent_name_id,
						edited
						<cfif isdefined("agentguid_guid_type") AND len(#agentguid_guid_type#) GT 0>
							,agentguid_guid_type
						</cfif>
						<cfif isdefined("agentguid") AND len(#agentguid#) gt 0>
							,agentguid
						</cfif>
						<cfif isdefined("agent_remarks") AND len(#agent_remarks#) gt 0>
							,agent_remarks
						</cfif>
						<cfif isdefined("biography") AND len(#biography#) gt 0>
							,biography
						</cfif>
						<cfif isdefined("eori_number") AND len(#eori_number#) gt 0>
							,eori_number
						</cfif>
					) VALUES (
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#agentID.nextAgentId#'>,
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agent_type#">,
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#agentNameID.nextAgentNameId#'>,
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#vetted#'>
						<cfif isdefined("agentguid_guid_type") AND len(#agentguid_guid_type#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agentguid_guid_type#">
						</cfif>
						<cfif isdefined("agentguid") AND len(#agentguid#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agentguid#">
						</cfif>
						<cfif isdefined("agent_remarks") AND len(#agent_remarks#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agent_remarks#">
						</cfif>
						<cfif isdefined("biography") AND len(#biography#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#biography#">
						</cfif>
						<cfif isdefined("eori_number") AND len(#eori_number#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#eori_number#">
						</cfif>
					)
				</cfquery>
				<cfif agent_type EQ 'person'>
					<cfquery name="insPerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO person (
							PERSON_ID
							<cfif isdefined("prefix") AND len(#prefix#) gt 0>
								,prefix
							</cfif>
							<cfif isdefined("LAST_NAME") AND len(#LAST_NAME#) gt 0>
								,LAST_NAME
							</cfif>
							<cfif isdefined("FIRST_NAME") AND len(#FIRST_NAME#) gt 0>
								,FIRST_NAME
							</cfif>
							<cfif isdefined("MIDDLE_NAME") AND len(#MIDDLE_NAME#) gt 0>
								,MIDDLE_NAME
							</cfif>
							<cfif isdefined("SUFFIX") AND len(#SUFFIX#) gt 0>
								,SUFFIX
							</cfif>
							<cfif isdefined("start_date") AND len(#start_date#) gt 0>
								,birth_date
							</cfif>
							<cfif isdefined("end_date") AND len(#end_date#) gt 0>
								,death_date
							</cfif>
						) VALUES (
							<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value="#agentID.nextAgentId#">
							<cfif isdefined("prefix") AND len(#prefix#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#prefix#'>
							</cfif>
							<cfif isdefined("LAST_NAME") AND len(#LAST_NAME#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#LAST_NAME#'>
							</cfif>
							<cfif isdefined("FIRST_NAME") AND len(#FIRST_NAME#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#FIRST_NAME#'>
							</cfif>
							<cfif isdefined("MIDDLE_NAME") AND len(#MIDDLE_NAME#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#MIDDLE_NAME#'>
							</cfif>
							<cfif isdefined("SUFFIX") AND len(#SUFFIX#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#SUFFIX#'>
							</cfif>
							<cfif isdefined("start_date") AND len(#start_date#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#start_date#'>
							</cfif>
							<cfif isdefined("end_date") AND len(#end_date#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#end_date#'>
							</cfif>
						)
					</cfquery>
				</cfif>
				<cfif len(pref_name) is 0>
					<!--- unused block, preferred name is required field on form --->
					<cfset name = "">
					<cfif len(#prefix#) gt 0>
						<cfset name = "#name# #prefix#">
					</cfif>
					<cfif len(#FIRST_NAME#) gt 0>
						<cfset name = "#name# #FIRST_NAME#">
					</cfif>
					<cfif len(#MIDDLE_NAME#) gt 0>
						<cfset name = "#name# #MIDDLE_NAME#">
					</cfif>
					<cfif len(#LAST_NAME#) gt 0>
						<cfset name = "#name# #LAST_NAME#">
					</cfif>
					<cfif len(#SUFFIX#) gt 0>
						<cfset name = "#name# #SUFFIX#">
					</cfif>
					<cfset pref_name = #trim(name)#>
				</cfif>
				<cfset okToAddAgent = true>
				<cfif not isdefined("ignoreDupCheck") or ignoreDupCheck is false>
					<cfquery name="duplicatePreferredCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT agent_name, agent_id 
						FROM preferred_agent_name
						WHERE 
							agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pref_name#">
					</cfquery>
					<cfif duplicatePreferredCheck.recordcount gt 0>
						<!--- allow possible optional creation of agents that duplicate the preferred name of other agents --->
						<cfquery name="findPreferredNameDups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							select
								agent.agent_type, 
								preferred_agent_name.agent_id, 
								preferred_agent_name.agent_name,
								agent.edited as vetted,
								MCZBASE.get_collectorscope(agent.agent_id,'collections') as collections_scope,
								substr(person.birth_date,0,4) as birth_date,
								substr(person.death_date,0,4) as death_date
							from preferred_agent_name
								left join agent on preferred_agent_name.agent_id = agent.agent_id
								left join person on preferred_agent_name.agent_id = person.person_id
							where 
								preferred_agent_name.agent_name = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#pref_name#'>
						</cfquery>
						<cfif findPreferredNameDups.recordcount gt 0>
							<!--- potential duplicates exist, require confirmation before continuing --->
							<!--- continuing involves resubmission of this action on this page from the form below, rollback the transaction and skip further inserts --->
							<cftransaction action="rollback">
							<cfset okToAddAgent = false>
							<main class="container py-3" id="content">
								<h2 class="h3">An <strong>exact match</strong> for the preferred name you provided <a href="/Agents.cfm?execute=true&anyName=#encodeForURL(pref_name)#" target="_blank">#encodeForHTML(pref_name)#</a> already exists.</h2>
								<section class="border rounded my-2 px-1 pt-1 pb-2">
									<div class="form-row">
										<div class="col-12">
											<p>The name you entered already exists as a name as a preferred name for an existing agent.</p>
											<p>Click duplicated names below to see details. Add the fullest version of the name if it can be differentiated from another. Only add the duplicate record if there is a legitimate reason for two different agents to have the same preferred name, as duplicate preferred names block bulkload of data using the duplicated name.</p>
										</div>
										<div class="col-12">
											<ul>
												<cfloop query="findPreferredNameDups">
													<cfif findPreferredNameDups.vetted EQ 1>
														<cfset displayname = replace(agent_name,pref_name,"<strong>#pref_name# *</strong>")>
													<cfelse>
														<cfset displayname = replace(agent_name,pref_name,"<strong>#pref_name#</strong>")>
													</cfif>
													<cfset dateString ="">
													<cfif len(birth_date) gt 0>
														<cfset dateString="#dateString# (#birth_date#">
													<cfelse>
														<cfset dateString="#dateString# (unknown">
													</cfif>
													<cfif len(death_date) gt 0>
														<cfset dateString="#dateString#-#death_date#)">
													<cfelse>
														<cfset dateString="#dateString#-unknown)">
													</cfif>
													<li><a href="/agents/Agent.cfm?agent_id=#agent_id#">#displayname#</a> #dateString# [agent ID ## #agent_id# - #agent_type#] #collections_scope#</li>
												</cfloop>
											</ul>
										</div>
										<div class="col-12">
											<label for="createAnywayButton">Do you still want to create this Agent?</p>
											<form name="ac" method="post" action="/agents/editAgent.cfm">
												<!--- Resubmit to this action, but with parameter ignoreDupCheck set so as to skip this section --->
												<input type="hidden" name="action" value="createAgent">
												<input type="hidden" name="agent_type" value="#agent_type#">
												<input type="hidden" name="LAST_NAME" value="#LAST_NAME#">
												<input type="hidden" name="pref_name" value="#pref_name#">
												<cfif isdefined('vetted') AND len(vetted) GT 0>
													<input type="hidden" name="vetted" value="#vetted#">
												</cfif>
												<cfif isdefined('prefix') AND len(prefix) GT 0>
													<input type="hidden" name="prefix" value="#prefix#">
												</cfif>
												<cfif isdefined('FIRST_NAME') AND len(FIRST_NAME) GT 0>
													<input type="hidden" name="FIRST_NAME" value="#FIRST_NAME#">
												</cfif>
												<cfif isdefined('MIDDLE_NAME') AND len(MIDDLE_NAME) GT 0>
													<input type="hidden" name="MIDDLE_NAME" value="#MIDDLE_NAME#">
												</cfif>
												<cfif isdefined('SUFFIX') AND len(SUFFIX) GT 0>
													<input type="hidden" name="SUFFIX" value="#SUFFIX#">
												</cfif>
												<cfif isdefined('start_date') AND len(start_date) GT 0>
													<input type="hidden" name="start_date" value="#start_date#">
												</cfif>
												<cfif isdefined('end_date') AND len(end_date) GT 0>
													<input type="hidden" name="end_date" value="#end_date#">
												</cfif>
												<cfif isdefined('agent_remarks') AND len(agent_remarks) GT 0>
													<input type="hidden" name="agent_remarks" value="#agent_remarks#">
												</cfif>
												<cfif isdefined('biography') AND len(biography) GT 0>
													<input type="hidden" name="biography" value="#biography#">
												</cfif>
												<cfif isdefined('agentguid') AND len(agentguid) GT 0>
													<input type="hidden" name="agentguid" value="#agentguid#">
												</cfif>
												<cfif isdefined('agentguid_guid_type') AND len(agentguid_guid_type) GT 0>
													<input type="hidden" name="agentguid_guid_typoe" value="#agentguid_guid_type#">
												</cfif>
												<input type="hidden" name="ignoreDupCheck" value="true">
												<input type="submit" class="btn btn-xs btn-warning" value="Create Agent" id="createAnywayButton">
											</form>
										</div>
									</div>
								</section>
							</main>
						</cfif>
					<cfelse>
						<!--- allow possible optional creation of agents that duplicate other names names of other agents --->
						<cfquery name="findPotentialDups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT 
								agent.agent_type, 
								agent_name.agent_id, 
								agent_name.agent_name,
								agent.edited as vetted,
								MCZBASE.get_collectorscope(agent.agent_id,'collections') as collections_scope,
								substr(person.birth_date,0,4) as birth_date,
								substr(person.death_date,0,4) as death_date
							FROM agent_name
								left join agent on agent_name.agent_id = agent.agent_id
								left join person on agent_name.agent_id = person.person_id
							WHERE 
								upper(agent_name.agent_name) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(pref_name)#%'>
						</cfquery>
						<cfif findPotentialDups.recordcount gt 0>
							<!--- potential duplicates exist, require confirmation before continuing --->
							<!--- continuing involves resubmission of this action on this page from the form below, rollback the transaction and skip further inserts --->
							<cftransaction action="rollback">
							<cfset okToAddAgent = false>
							<main class="container py-3" id="content">
								<h2 class="h3">The agent <a href="/Agents.cfm?execute=true&anyName=#encodeForURL(pref_name)#" target="_blank">#encodeForHTML(pref_name)#</a> may already exist.</h2>
								<section class="border rounded my-2 px-1 pt-1 pb-2">
									<div class="form-row">
										<div class="col-12">
											<p>The name you entered is already exists as a name (other than a preferred name) for an existing agent.</p>
											<p>Click duplicated names below to see details. Add the fullest version of the name if it can be differentiated from another. If the need for a duplicate agent should arise, please merge the pre-existing matches (bad duplicates) so they will not create problems.</p>
										</div>
										<div class="col-12">
											<ul>
												<cfloop query="findPotentialDups">
													<cfif findPotentialDups.vetted EQ 1>
														<cfset displayname = replace(agent_name,pref_name,"<strong>#pref_name# *</strong>")>
													<cfelse>
														<cfset displayname = replace(agent_name,pref_name,"<strong>#pref_name#</strong>")>
													</cfif>
													<cfset dateString ="">
													<cfif len(birth_date) gt 0>
														<cfset dateString="#dateString# (#birth_date#">
													<cfelse>
														<cfset dateString="#dateString# (unknown">
													</cfif>
													<cfif len(death_date) gt 0>
														<cfset dateString="#dateString#-#death_date#)">
													<cfelse>
														<cfset dateString="#dateString#-unknown)">
													</cfif>
													<li><a href="/agentsAgent.cfm?agent_id=#agent_id#">#displayname#</a> #dateString# [agent ID ## #agent_id# - #agent_type#] #collections_scope#</li>
												</cfloop>
											</ul>
										</div>
										<div class="col-12">
											<label for="createAnywayButton">Do you still want to create this Agent?</p>
											<form name="ac" method="post" action="/agents/editAgent.cfm">
												<!--- Resubmit to this action, but with parameter ignoreDupCheck set so as to skip this section --->
												<input type="hidden" name="action" value="createAgent">
												<input type="hidden" name="agent_type" value="#agent_type#">
												<input type="hidden" name="LAST_NAME" value="#LAST_NAME#">
												<input type="hidden" name="pref_name" value="#pref_name#">
												<cfif isdefined('vetted') AND len(vetted) GT 0>
													<input type="hidden" name="vetted" value="#vetted#">
												</cfif>
												<cfif isdefined('prefix') AND len(prefix) GT 0>
													<input type="hidden" name="prefix" value="#prefix#">
												</cfif>
												<cfif isdefined('FIRST_NAME') AND len(FIRST_NAME) GT 0>
													<input type="hidden" name="FIRST_NAME" value="#FIRST_NAME#">
												</cfif>
												<cfif isdefined('MIDDLE_NAME') AND len(MIDDLE_NAME) GT 0>
													<input type="hidden" name="MIDDLE_NAME" value="#MIDDLE_NAME#">
												</cfif>
												<cfif isdefined('SUFFIX') AND len(SUFFIX) GT 0>
													<input type="hidden" name="SUFFIX" value="#SUFFIX#">
												</cfif>
												<cfif isdefined('start_date') AND len(start_date) GT 0>
													<input type="hidden" name="start_date" value="#start_date#">
												</cfif>
												<cfif isdefined('end_date') AND len(end_date) GT 0>
													<input type="hidden" name="end_date" value="#end_date#">
												</cfif>
												<cfif isdefined('agent_remarks') AND len(agent_remarks) GT 0>
													<input type="hidden" name="agent_remarks" value="#agent_remarks#">
												</cfif>
												<cfif isdefined('biography') AND len(biography) GT 0>
													<input type="hidden" name="biography" value="#biography#">
												</cfif>
												<cfif isdefined('agentguid') AND len(agentguid) GT 0>
													<input type="hidden" name="agentguid" value="#agentguid#">
												</cfif>
												<cfif isdefined('agentguid_guid_type') AND len(agentguid_guid_type) GT 0>
													<input type="hidden" name="agentguid_guid_typoe" value="#agentguid_guid_type#">
												</cfif>
												<input type="hidden" name="ignoreDupCheck" value="true">
												<input type="submit" class="btn btn-xs btn-warning" value="Create Agent" id="createAnywayButton">
											</form>
										</div>
									</div>
								</section>
							</main>
						</cfif> <!--- end findPotentialDups.recordcount gt 0 --->
					</cfif> <!--- end cfelse of duplicatePreferredCheck.recordcount gt 0 --->
				</cfif><!--- end  not isdefined("ignoreDupCheck") or ignoreDupCheck is false --->
				<cfif okToAddAgent IS true >
					<!--- either the duplicate checks passed, or ignoreDupCheck was true --->
					<!--- finish creating the agent record by adding a preferred name, and then committing the transaction --->
					<!--- NOTE: Retaining donor_card_fg_present_fg for now, this likely indicates names created through the MCZbase coldfusion UI as opposed to loads of data --->
					<cfquery name="insName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO agent_name (
							agent_name_id,
							agent_id,
							agent_name_type,
							agent_name,
							donor_card_present_fg)
						VALUES (
							<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value="#agentNameID.nextAgentNameId#">,
							<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value="#agentID.nextAgentId#">,
							'preferred',
							<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#pref_name#'>,
							0
						)
					</cfquery>
					<cftransaction action="commit">
					<cflocation url="/agents/editAgent.cfm?agent_id=#agentID.nextAgentId#">
				</cfif>
			<cfcatch>
				<cftransaction action="rollback">
				<section class="container">
					<cfif cfcatch.message contains "Duplicate preferred name">
						<div class="row">
							<div class="alert alert-danger" role="alert">
								<img src="/shared/images/Process-stop.png" alt="[ Error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h1 class="h2">#encodeForHtml(cfcatch.message)#<h1>
								<p>You cannot create a new agent record with a preferred name that duplicates an existing preferred name.</p>
								<p></p>
								<p><a href="/Agents.cfm?execute=true&anyName=#encodeForURL(pref_name)#">Search for Agents with this name</a></p>
							</div>
						</div>
					<cfelse>
						<div class="row">
							<div class="alert alert-danger" role="alert">
								<img src="/shared/images/Process-stop.png" alt="[ Error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h1 class="h2">Creation of new agent record failed.<h1>
								<p>There was an error creating this taxon record, please file a bug report describing the problem.</p>
								<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
							</div>
						</div>
						<p><cfdump var=#cfcatch#></p>
					</cfif>
				</section>
			</cfcatch>
			</cftry>
		</cftransaction>
	</cfoutput>
</cfcase>
</cfswitch>

<cfinclude template = "/shared/_footer.cfm">
