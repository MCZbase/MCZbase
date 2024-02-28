<!--- info/bugs.cfm allow users to report issues

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2024 President and Fellows of Harvard College

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
<cfset pageTitle="Report Bug">
<cfinclude template="/shared/_header.cfm">

<cfset FEEDBACK_INSTRUCTIONS="Include DETAILS of the problem plus the text of any error you received, the catalog number of the record causing the issue, or the URL of the non-functioning page.">

<cfif NOT isDefined("action")>
	<cfset action= "bugReportForm">
</cfif>

<cfswitch expression="#action#">
	<cfcase value="bugReportForm">
		<cfoutput>
			<cfset reportedName ="">
			<cfset email = "">
			<cfif isDefined("session.username") AND len(session.username) GT 0>
				<cfif isDefined("session.username") AND listcontainsnocase(session.roles,"coldfusion_user")>
					<cfquery name="getUserInfo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT username, preferred_agent_name.agent_name, GET_EMAILADDRESSES(agent_name.agent_id,', ') emails
						FROM cf_users
							left join agent_name on cf_users.username = agent_name.agent_name and agent_name.agent_name_type = 'login'
							left join preferred_agent_name on agent_name.agent_id = preferred_agent_name.agent_id
						WHERE
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
				<cfelse>
					<cfquery name="getUserInfo" datasource="cf_dbuser" >
						SELECT username, first_name || ' ' || last_name as agent_name, email as emails
						FROM cf_users
							left join cf_user_data on cf_users.user_id = cf_user_data.user_id
						WHERE
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
				</cfif>
				<cfif getUserInfo.recordcount EQ 1>
					<cfloop query="getUserInfo">
						<cfset reportedName ="#getUserInfo.agent_name#">
						<cfset email = "#getUserInfo.emails#">
					</cfloop>
				</cfif>
			</cfif>
			<cfif isdefined("session.roles") AND listcontainsnocase(session.roles,"coldfusion_user")>
				<!--- captcha not needed --->
			<cfelse>
				<script src="https://www.google.com/recaptcha/api.js" async defer></script>
			</cfif>
			<main class="container py-3" id="content">
				<section class="container-fluid">
					<div class="row mx-0 mb-3">
						<div class="search-box">
							<div class="search-box-header">
								<h1 class="h2 text-white mb-1 pt-2" id="formheading">Provide Feedback</h1>
							</div>
							<div class="col-12 px-4 py-1">
								<ul class="pt-3">
									<cfif isdefined("session.roles") AND listcontainsnocase(session.roles,"coldfusion_user")>
										<li class="mb-1">Use this form to ask questions about how to use MCZbase when you can&apos;t find the answer on the <a href="https://code.mcz.harvard.edu/wiki/index.php/Using_MCZbase" target="_blank">wiki</a> (Select: <i>I have a question</i>).</li>
										<li class="my-1">Use this form to report problems that you have encountered while using the database, including bulkoading data (Select: <i>A bug or issue with MCZbase</i> and priority low, normal, or high).</li>
										<li class="mb-1">Use this form to make suggestions to improve MCZbase (Select: <i>Enhancement Request</i>).</li>
										<li class="mb-1">Use this form to make a request for assistance from the informatics team with importing or exporting data in support of a workflow for tasks not addressed by the bulkloaders (Select: <i>Workflow Support</i>).</li>
										<li class="mb-1">Use this form to report problems with agent, locality, event, etc. data that you are not able to resolve yourself (Select: <i>A problem with data</i>).</li>
										<li class="mb-1">You can use this form to report errors with specimen, taxon, publication, or project data that you are not able to resolve yourself, but use of annotation with the "Report Bad Data" links included on the Specimen Detail and other pages is preferrable, as you can review and comment on annotations.</li>
									<cfelseif isdefined("session.username") and len(session.username) GT 0>
										<li class="my-1">Use this form to report problems you have encountered while using the database.</li>
										<li class="mb-1">You can use this form to report errors with specimen data or you can use the "Report Bad Data" link included on Search Results or Specimen Detail pages.</li>
										<cfif NOT isDefined("email") OR len(email) EQ 0>
											<li class="mb-1">Include your email address if you wish to be contacted when the issue has been addressed. Your email address will <b>not</b> be released or publicly displayed on our site.</li>
										</cfif>
									<cfelse>
										<li class="my-1">Use this form to report problems you have encountered while using the database.</li>
										<li class="mb-1">To report problems or errors with specimen data, you may use this form, or if logged in, you may use the "Report Bad Data" link included on Search Results or Specimen Detail pages.</li>
										<li class="mb-1">Include your email address if you wish to be contacted when the issue has been addressed. Your email address will <b>not</b> be released or publicly displayed on our site.</li>
									</cfif>
								</ul>
							</div>
							<div class="col-12 px-4 py-1">
								<form name="bug" method="post" action="bugs.cfm" onsubmit="return validateBugs();">
									<input type="hidden" name="action" value="save">
									<div class="form-row mb-2">
										<div class="col-12 col-md-6">
											<label for="reported_name" class="data-entry-label">Name</label>
											<input type="text" name="reported_name" id="reported_name" class="data-entry-input" value="#reportedName#">
										</div>
										<div class="col-12 col-md-6">
											<label for="user_email" class="data-entry-label">Email</label>
											<input type="text" name="user_email" id="user_email" class="data-entry-input" value="#email#">
										</div>
										<div class="col-12">
											<h2 class="h4 pt-3 px-1">Please provide as much detail as possible. We do not know what you see unless you write about it in the report.</h3>
											<cfif isdefined("session.roles") AND listcontainsnocase(session.roles,"coldfusion_user")>
												<h2 class="h4 pt-1 px-1">Please include the page you are seeing the issue on, and the specific catalog number, loan number, etc. that you are seeing the problem with.</h3>
											</cfif>
										</div>
										<cfif isdefined("session.roles") AND listcontainsnocase(session.roles,"coldfusion_user")>
											<div class="col-12 py-3">
												<label for="component" class="data-entry-label">What would you like to report:</label>
												<select name="bugzilla_component" id="component" size="1" class="data-entry-select">
													<option value="Web Interface" selected>A bug or issue with MCZbase</option>
													<option value="Questions" >I have a question</option>
													<option value="Data" >A problem with data</option>
													<option value="EnhancementRequest" >I have an Enhancement Request</option>
													<option value="WorkflowSupport">I am requesting Workflow Support</option>
												</select>
											</div>
											<script>
												$(document).ready(function(){ 
													$('##component').on('change',setPriorityList);
													setPriorityList();
												});
												function setPriorityList() { 
													var targetComponent = $('##component').val();
													var currentPriority = $('##user_priority').val();
													if (targetComponent==="WorkflowSupport") {
														$('##user_priority').empty().append('<option selected="selected" value="0">Low Priority</option>');
													}
													if (targetComponent==="EnhancementRequest") {
														$('##user_priority').empty().append('<option selected="selected" value="6">Enhancement Request</option>');
													}
													if (targetComponent==="Questions") {
														var sel2 = "selected";
														var sel4 = "";
														if (currentPriority=="4") { 
															var sel2 = "";
															var sel4 = "selected";
														}
														$('##user_priority').empty().append('<option '+sel2+' value="2">Normal Priority</option>');
														$('##user_priority').append('<option '+sel4+' value="4">High Priority</option>');
													}
													if (targetComponent==="Data") {
														var sel2 = "selected";
														var sel4 = "";
														if (currentPriority=="4") { 
															var sel2 = "";
															var sel4 = "selected";
														}
														$('##user_priority').empty().append('<option '+sel2+' value="2">Normal Priority</option>');
														$('##user_priority').append('<option '+sel4+' value="4">High Priority</option>');
													}
													if (targetComponent==="Web Interface") {
														var sel0 = "";
														var sel2 = "selected";
														var sel4 = "";
														var sel6 = "";
														if (currentPriority=="0") { 
															var sel0 = "selected";
															var sel2 = "";
															var sel4 = "";
															var sel6 = "";
														}
														if (currentPriority=="4") { 
															var sel0 = "";
															var sel2 = "";
															var sel4 = "selected";
															var sel6 = "";
														}
														if (currentPriority=="6") { 
															var sel0 = "";
															var sel2 = "";
															var sel4 = "";
															var sel6 = "selected";
														}
														$('##user_priority').empty().append('<option '+sel0+' value="0">Low Priority</option>');
														$('##user_priority').append('<option '+sel2+' value="2">Normal Priority</option>');
														$('##user_priority').append('<option '+sel4+' value="4">High Priority</option>');
													}
												}
											</script>
										<cfelse>
											<input type="hidden" name="component" value="Web Interface">
										</cfif>
										<div class="col-12">
											<label for="complaint" class="data-entry-label">Feedback</label>
											<textarea name="complaint" id="complaint" rows="15"  class="data-entry-textarea reqdClr autogrow" style = "min-height: 100px;" placeholder="#FEEDBACK_INSTRUCTIONS#" required></textarea>
										</div>
										<script>
											// Make textarea with autogrow class be bound to the autogrow function on key up
											$(document).ready(function() { 
												$("textarea.autogrow").keyup(autogrow);
												$('textarea.autogrow').keyup();
											});
										</script>
										<div class="col-12 py-3">
											<label for="user_priority" class="data-entry-label">Priority</label>
											<select name="user_priority" id="user_priority" size="1" class="data-entry-select">
												<option value="0">Low Priority</option>
												<option value="2" SELECTED >Normal Priority</option>
												<option value="6" >Enhancement Request</option>
												<option value="4">High Priority</option>
											</select>
										</div>
										<cfif isdefined("session.roles") AND listcontainsnocase(session.roles,"coldfusion_user")>
											<!--- captcha not needed --->
										<cfelse>
											<div class="col-12">
												<div class="g-recaptcha" data-sitekey="#application.g_sitekey#"></div>
											</div>
										</cfif>
										<div class="col-12 mt-1">
											<input type="submit" value="Submit Bug Report" class="btn btn-xs btn-primary my-1" >
										</div>
									</div>
								</form>
							</div>
						</div>
					</div>
				</section>
			</main>
		</cfoutput>
	</cfcase>
	<!------------------------------------------------------------>
	<cfcase value="save">
		<cfoutput>
		<main class="container py-3" id="content" >
			<cfif NOT isdefined("session.username") OR len(session.username) EQ 0>
				<cfif REFind("http(s){0,1}://(?!#Application.hostName#)",complaint) GT 0>
					<cfthrow message="You must be logged in to submit this bug report.">
				</cfif>
			</cfif>
			<cfif isDefined("bugzilla_component") AND bugzilla_component EQ "EnhancementRequest">
				<cfset bugzilla_component = "Web Interface">
				<cfset user_priority = "6">
			</cfif>
			<cfset user_id=0>
			<cfif isdefined("session.username") and len(#session.username#) gt 0>
				<cfquery name="isUser"datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT user_id 
					FROM cf_users 
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfset user_id = #isUser.user_id#>
			</cfif>
			<cfquery name="bugID"datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select max(bug_id) + 1 as id from cf_bugs
			</cfquery>
			<cfset thisDate = #dateformat(now(),"yyyy-mm-dd")#>
			<!--- strip out the crap....--->
			<cfset badStuff = "---a href,---script,[link,[url">
			<cfset concatSub = "#reported_name# #complaint# #user_email#">
			<cfset concatSub = replace(concatSub,"#chr(60)#","---","all")>
	
	
			<cfif isdefined("session.roles") AND listcontainsnocase(session.roles,"coldfusion_user")>
				<!--- capcha not needed ---->
			<cfelse>
				<cftry>
					<cfobject action = "create" 
						type = "java" 
						class = "edu.harvard.mcz.recaptchavalidate.RecaptchaValidate" 
						name = "Validator"> 
					<cfif structKeyExists(FORM,"g-recaptcha-response") >
						<cfset response = FORM['g-recaptcha-response'] >
						<cfset valid = Validator.validate("#response#","#CGI.REMOTE_ADDR#") >
					<cfelse>
						<cfset valid = FALSE >
					</cfif>
					<cfif not valid >
						Captcha not validated.
						<cfabort>
					</cfif>
				<cfcatch>
					#cfcatch.message#
				</cfcatch>
				</cftry>
			</cfif>
	
			<cfif #complaint# eq #FEEDBACK_INSTRUCTIONS#>
				Please provide a description of the problem.
				<cfabort>
			</cfif>
			<cfif trim(#complaint#) eq "">
				Please provide a description of the problem.
				<cfabort>
			</cfif>
			<cfif #ucase(concatSub)# contains "invalidTag">
				Bug reports may not contain markup or script.
				<cfabort>
			</cfif>
			<cfloop list="#badStuff#" index="i">
				<cfif #ucase(concatSub)# contains #ucase(i)#>
					Bug reports may not contain markup or script.
					<cfabort>
				</cfif>
			</cfloop>
			<cfset insertErrorMessage = "">
			<cftry>
				<cfquery name="newBug" datasource="cf_dbuser">
					INSERT INTO cf_bugs (
						bug_id,
						user_id,
						reported_name,
						form_name,
						complaint,
						suggested_solution,
						user_priority,
						user_remarks,
						user_email,
						submission_date)
					VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bugID.id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#user_id#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#reported_name#">,
						'',
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#complaint#">,
						'',
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#user_priority#">,
						'',
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#user_email#">,
						<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#thisDate#">
					)
				</cfquery>
			<cfcatch>
				<cfset insertErrorMessage="Insert into cf_bugs failed: #cfcatch.message#">
			</cfcatch>
			</cftry>
			<cfset sentok="true">
			<cfif isDefined("bugzilla_component") AND ListContains("Web Interface,Data,Questions,WorkflowSupport",bugzilla_component)>
				<cfset bugzilla_component="#bugzilla_component#">
			<cfelse>
				<cfset bugzilla_component="Web Interface">
			</cfif>
			<cftry>
				<cfmail to="#Application.bugReportEmail#" subject="ColdFusion bug report submitted" from="BugReport@#Application.fromEmail#" type="html">
<p>Reported Name: #reported_name# (AKA #session.username#) submitted a bug report on #thisDate#.</p>

<p>Complaint: #complaint#</p>

<p>Priority: #user_priority#</p>

<p>Email: #user_email#</p>

<p>Request: #bugzilla_component#</p>

#insertErrorMessage#
				</cfmail>
			<cfcatch>
				<div>Error: Unable to send bugmail to admin. #cfcatch.Message#</div>
				<div>Contact the <a HREF="mailto:#Application.PageProblemEmail#" aria-label="email_to_system_admin">System Administrator</a>.</div>
				<cfset sentok="false">
			</cfcatch>
			</cftry>
	
			<!--- create a bugzilla bug from the bugreport --->
			<cfset summary=left(#complaint#,60)><!--- obtain the begining of the complaint as a bug summary --->
	 		<cfset bugzilla_mail="#Application.bugzillaToEmail#"><!--- address to access email_in.pl script --->
			<!---cfset bugzilla_user="test@example.com"---><!--- bugzilla user for testing integration as bugreport@software can have alias resolution problems --->
			<cfset bugzilla_user="#Application.bugzillaFromEmail#"><!--- bugs submitted by email can only come from a registered bugzilla user --->
			<cfset bugzilla_priority="@priority = P3">
			<cfset bugzilla_severity="@bug_severity = normal">
			<cfset human_importance="Submitter Importance = Normal Priority [#user_priority#]">
			<cfif #user_priority# eq "0" >
				<cfset bugzilla_priority="@priority = P5">
				<cfset bugzilla_severity="@bug_severity = minor">
				<cfset human_importance="Submitter Importance = Low Priority [#user_priority#]">
			</cfif>
			<cfif #user_priority# eq "1" >
				<cfset bugzilla_priority="@priority = P4">
			</cfif>
			<cfif #user_priority# eq "2" >
				<cfset bugzilla_priority="@priority = P3">
			</cfif>
			<cfif #user_priority# eq "6" >
				<cfset bugzilla_priority="@priority = P3">
				<cfset bugzilla_severity="@bug_severity = enhancement">
				<cfset human_importance="Submitter Importance = Enhancement Request [#user_priority#]">
			</cfif>
			<cfif #user_priority# eq "3" >
				<cfset bugzilla_priority="@priority = P2">
			</cfif>
			<cfif #user_priority# eq "4" >
				<cfset bugzilla_priority="@priority = P1">
				<cfset bugzilla_severity="@bug_severity = major">
				<cfset human_importance="Submitter Importance = High Priority [#user_priority#]">
			</cfif>
			<cfset newline= Chr(13) & Chr(10)>
			<cftry>
				<cfmail to="#bugzilla_mail#" subject="#summary#" from="#bugzilla_user#" type="text">
@rep_platform = PC
@op_sys = Linux
@product = MCZbase
@component = #bugzilla_component#
@version = 2.5.1merge
#bugzilla_priority##newline#
#bugzilla_severity#
	
Bug report by: #reported_name# (Username: #session.username#)
Email: #user_email#
Complaint: #complaint#
#newline##newline#
#human_importance#
				</cfmail>
			<cfcatch>
				<div>Error: Unable to send bugreport to bugzilla. #cfcatch.Message#</div>
				<cfset sentok="false">
			</cfcatch>
			</cftry>
			<div class="basic_box">
				<cfif sentok eq "true">
					<p align="center">Your report has been successfully submitted.</p>
					<p align="center">Thank you for helping to improve this site!</p>
				</cfif>
				<p align="center">Click <a href="/SpecimenSearch.cfm">here</a> to search MCZbase.</p>
			</div>
		</main>
		</cfoutput>
	</cfcase>
	<!------------------------------------------------------------>
	<cfcase value="read">
		<!--- deprecated, view/edit bugs replaced by bugzilla --->
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
			<cfoutput>
				<form name="filter" method="post" action="bugs.cfm">
					<input type="hidden" name="action" value="read">
					<table>
						<tr>
							<td colspan="2">
								<i><b>Filter results:</b></i>
							</td>
						</tr>
						<tr>
							<td align="right">Submitter:</td>
							<td><input type="text" name="reported_name"></td>
						</tr>
						<tr>
							<td align="right">Form:</td>
							<td><input type="text" name="FORM_NAME"></td>
						</tr>
						<tr>
							<td align="right">Complaint:</td>
							<td><input type="text" name="Complaint" size="60"></td>
						</tr>
						<tr>
							<td align="right">Suggested Solution:</td>
							<td><input type="text" name="suggested_solution" size="60"></td>
						</tr>
						<tr>
							<td align="right">Our Solution:</td>
							<td><input type="text" name="admin_solution" size="60"></td>
						</tr>
						<tr>
							<td align="right">User Remarks:</td>
							<td><input type="text" name="user_remarks" size="60"></td>
						</tr>
						<tr>
							<td align="right">Our Remarks:</td>
							<td><input type="text" name="admin_remarks" size="60"></td>
						</tr>
						<tr>
							<td align="right">User Priority:</td>
							<td>
								<select name="user_priority" size="1">
									<option value=""></option>
									<option value="0"
										style="background-color:##00FF00"
										onClick="document.filter.user_priority.style.backgroundColor='##00FF00';">Low priority</option>
									<option value="1"
										style="background-color:##99CCFF"
										onClick="document.filter.user_priority.style.backgroundColor='##99CCFF';">Just a suggestion</option>
									<option value="2"
										style="background-color:##FFFF33"
										onClick="document.filter.user_priority.style.backgroundColor='##FFFF33';">It would make my life easier</option>
									<option value="3"
										style="background-color:##FF6600"
										onClick="document.filter.user_priority.style.backgroundColor='##FF6600';">I can&apos;t do what I need to without it</option>
									<option value="4" style="background-color:##FF0000"
										onClick="document.filter.user_priority.style.backgroundColor='##FF0000';">Urgent: High Priority</option>
									<option value="5" style="background-color: ##000000; color:##FFFFFF"
										onClick="document.filter.user_priority.style.backgroundColor='##000000';document.filter.user_priority.style.color='##FFFFFF';">
										Data are missrepresented</option>
								</select>
							</td>
						</tr>
						<tr>
							<td align="right">Our Priority:</td>
							<td>
								<select name="admin_priority" size="1">
									<option value=""></option>
									<option value="0"
										style="background-color:##00FF00"
										onClick="document.filter.admin_priority.style.backgroundColor='##00FF00';">Low priority</option>
									<option value="1"
										style="background-color:##99CCFF"
										onClick="document.filter.admin_priority.style.backgroundColor='##99CCFF';">Just a suggestion</option>
									<option value="2"
										style="background-color:##FFFF33"
										onClick="document.filter.admin_priority.style.backgroundColor='##FFFF33';">It would make my life easier</option>
									<option value="3"
										style="background-color:##FF6600"
										onClick="document.filter.admin_priority.style.backgroundColor='##FF6600';">Urgent High Priority</option>
									<option value="4" style="background-color:##FF0000"
										onClick="document.filter.admin_priority.style.backgroundColor='##FF0000';">Something is broken</option>
									<option value="5" style="background-color: ##000000; color:##FFFFFF"
										onClick="document.filter.admin_priority.style.backgroundColor='##000000';document.filter.admin_priority.style.color='##FFFFFF';">
										Data are missrepresented</option>
								</select>
							</td>
						</tr>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							<tr>
								<td align="right"><font color="##FF0000">username</font>: </td>
								<td><input type="text" name="cf_username" size="60"></td>
							</tr>
							<tr>
								<td align="right"><font color="##FF0000">email</font>:</td>
								<td><input type="text" name="user_email" size="60"></td>
							</tr>
						</cfif>
						<tr>
							<td align="right">Show only unresolved bugs:</td>
							<td><input type="checkbox" name="resolved" value="1" checked></td>
						</tr>
						<tr>
							<td colspan="2">
								<div align="center">
									<input type="submit" value="Filter" class="schBtn"
										onmouseover="this.className='schBtn btnhov'" onmouseout="this.className='schBtn'">
									<input type="button" value="Remove Filter" class="clrBtn"
										onmouseover="this.className='clrBtn btnhov'" onmouseout="this.className='clrBtn'" onClick="reset(); submit();">
								</div>
							</td>
						</tr>
					</table>
				</form>
			</cfoutput>
	
			<cfquery name="getBug"datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					BUG_ID,
					cf_bugs.USER_ID,
					REPORTED_NAME,
					FORM_NAME,
					COMPLAINT,
					SUGGESTED_SOLUTION,
					ADMIN_SOLUTION,
					USER_PRIORITY,
					ADMIN_PRIORITY,
					USER_REMARKS,
					ADMIN_REMARKS,
					SOLVED_FG,
					USER_EMAIL,
					SUBMISSION_DATE,
					username
				from
					cf_bugs,
					cf_users
				where
					cf_bugs.user_id = cf_users.user_id (+) AND
					bug_id > 0
					<cfif isdefined("FORM_NAME") and len(#FORM_NAME#) gt 0>
						AND upper(FORM_NAME) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(FORM_NAME))#%">
					</cfif>
					<cfif isdefined("reported_name") and len(#reported_name#) gt 0>
						AND upper(reported_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(reported_name))#%">
					</cfif>
					<cfif isdefined("complaint") and len(#complaint#) gt 0>
						AND upper(complaint) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(complaint))#%">
					</cfif>
					<cfif isdefined("suggested_solution") and len(#suggested_solution#) gt 0>
						AND upper(suggested_solution) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(suggested_solution))#%">
					</cfif>
					<cfif isdefined("admin_solution") and len(#admin_solution#) gt 0>
						AND upper(admin_solution) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(admin_solution))#%">
					</cfif>
					<cfif isdefined("user_remarks") and len(#user_remarks#) gt 0>
						AND upper(user_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(user_remarks))#%">
					</cfif>
					<cfif isdefined("user_priority") and len(#user_priority#) gt 0>
						AND user_priority = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#user_priority#">
					</cfif>
					<cfif isdefined("admin_priority") and len(#admin_priority#) gt 0>
						AND admin_priority = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#admin_priority#">
					</cfif>
					<cfif isdefined("cf_username") and len(#cf_username#) gt 0>
						AND upper(username) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(cf_username))#%">
					</cfif>
					<cfif isdefined("email") and len(#email#) gt 0>
						AND upper(email) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(email))#%">
					</cfif>
					<cfif isdefined("resolved") and len(#resolved#) gt 0>
						AND solved_fg =1
					<cfelse>
						AND (solved_fg <> 1 OR solved_fg is null)
					</cfif>
					<cfif isdefined("bug_id") and len(#bug_id#) gt 0>
						AND bug_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bug_id#">
					</cfif>
				order by submission_date DESC
			</cfquery>
	
			<cfoutput query="getBug">
				<cfif currentrow MOD 2>
					<cfset bgc = "##C7D5D6">
				<cfelse>
					<cfset bgc = "##F5F5F5">
				</cfif>
				<div style="background-color:#bgc# ">
					<form name="admin#CurrentRow#" method="post" action="bugs.cfm">
						<input type="hidden" name="action" value="saveAdmin">
						<input type="hidden" name="bug_id" value="#bug_id#">
						<i><b>Filed by:</b></i> #reported_name# &nbsp;&nbsp;&nbsp;
						<cfif #solved_fg# is 1>
							<font color="##00FF00" size="+1">Resolved</font>
						</cfif>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							<br>
							<font color="##FF0000"><i>username: #username#
							<br>email: #user_email#
							<br>Date Submitted: #dateformat(submission_date,"dd mmm yyyy")#</i></font>
						</cfif>
						<br><i><b>Concerning form:</b></i> #form_name#
						<br><i><b>Complaint:</b></i> #complaint#
						<br><i><b>Suggested Solution:</b></i> #suggested_solution#
						<br>
						<font color="##0000FF"><i><b>Our Solution:</b></i> #admin_solution#</font>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							<br>
							<font color="##FF0000"><i>Update admin solution to:</i></font>
							<br>
							<textarea name="admin_solution" rows="6" cols="50">#admin_solution#</textarea>
						</cfif>
						<br><i><b>Submitted Priority:</b></i> #user_priority#
						<br>
						<font color="##0000FF"><i><b>Our Priority:</b></i> #admin_priority#</font>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							<font color="##FF0000"><i>Update admin priority to:</i></font>
							<select name="admin_priority" size="1" style="background-color:##00FF00">
								<option value="0"
									style="background-color:##00FF00 ">Low priority</option>
								<option value="1"
									style="background-color:##99CCFF"
									onClick="document.bug.admin_priority.style.backgroundColor='##99CCFF';">Just a suggestion</option>
								<option value="2"
									style="background-color:##FFFF33"
									onClick="document.bug.admin_priority.style.backgroundColor='##FFFF33';">It would make my life easier</option>
								<option value="3"
									style="background-color:##FF6600"
									onClick="document.bug.admin_priority.style.backgroundColor='##FF6600';">I can&apos;t do what I need to without it</option>
								<option value="4" style="background-color:##FF0000"
									onClick="document.bug.admin_priority.style.backgroundColor='##FF0000';">Something is broken</option>
								<option value="5" style="background-color: ##000000; color:##FFFFFF"
									onClick="document.bug.admin_priority.style.backgroundColor='##000000';document.bug.admin_priority.style.color='##FFFFFF';">
									Critical Priority</option>
							</select>
						</cfif>
						<br><i><b>Submitted Remarks:</b></i> #user_remarks#
						<br><i><b>Our Remarks:</b></i> #admin_remarks#
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							<br><textarea name="admin_remarks" rows="6" cols="50">#admin_remarks#</textarea>
						</cfif>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							<input type="hidden" name="solved_fg" value="0">
							<br><input type="submit" value="update">
							<br><input type="button" value="Update and Mark Resolved" onclick="admin#CurrentRow#.solved_fg.value=1;submit();">
						</cfif>
					</form>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
						<form name="killit#CurrentRow#" method="post" action="bugs.cfm">
							<input type="hidden" name="action" value="killit">
							<input type="hidden" name="bug_id" value="#bug_id#">
							<input type="submit" value="delete">
						</form>
					</cfif>
		 		</div>
			</cfoutput>
		</cfif>
	</cfcase>
	<!------------------------------------------------------------>
	<cfcase value="saveAdmin">
		<!--- deprecated, view/edit bugs replaced by bugzilla --->
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
			<cfquery name="upAd" datasource="cf_dbuser">
				UPDATE cf_bugs SET
					admin_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#admin_remarks#">,
					admin_priority = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#admin_priority#">,
					admin_solution = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#admin_solution#">,
					solved_fg=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#solved_fg#">
				WHERE
					bug_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bug_id#">
			</cfquery>
			<cflocation url="bugs.cfm?action=read">
		</cfif>
	</cfcase>
	<!------------------------------------------------------------>
	<cfcase value="killit">
		<!--- deprecated, view/edit bugs replaced by bugzilla --->
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
			<cfquery name="upAd" datasource="cf_dbuser">
				DELETE FROM cf_bugs 
				WHERE bug_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bug_id#">
			</cfquery>
			<cflocation url="bugs.cfm?action=read">
		</cfif>
	</cfcase>
</cfswitch>

<cfinclude template="/shared/_footer.cfm">
