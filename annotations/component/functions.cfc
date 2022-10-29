
<!---
/transactions/component/functions.cfc

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

--->
<cfcomponent>

<cfinclude template = "/shared/functionLib.cfm">

<cffunction name="getAnnotationDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="target_type" type="string" required="yes">
	<cfargument name="target_id" type="numeric" required="yes">
	
	<cfthread name="getAnnotationDialogHtmlThread">
		<cftry>
			<cfoutput>
				<cfquery name="hasEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select email from cf_user_data,cf_users
					where cf_user_data.user_id = cf_users.user_id and
					cf_users.username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfif hasEmail.recordcount is 0 OR len(hasEmail.email) is 0>
					<cfthrow message="You must be an authenticated user and have provided an email address to view annotations or annotate specimens.">
				</cfif>
				<cfset found = FALSE>
				<cfset manageIRI = "">
				<cfquery name="ctmotivation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT motivation, description
					FROM ctmotivation
					ORDER by motivation
				</cfquery>
				<cfswitch expression="#target_type#">
					<cfcase value="collection_object">
						<cfset collection_object_id = target_id>
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select 
								collection.collection,
								collection.collection_cde,
								cat_num,
								mczbase.get_scientific_name_auths(collection_object_id) display_name
							from 
								cataloged_item
								left join collection on cataloged_item.collection_id = collection.collection_id
							where 
								cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						</cfquery>
						<cfloop query="d">
							<cfset summary="Cataloged Item <strong><a href='/guid/MCZ:#collection_cde#:#cat_num#' target='_blank'>MCZ:#collection#:#cat_num#</a></strong> #display_name#" >
							<!--- TODO: Manage dialog for individual annotations --->
							<cfset manageIRI = "/info/reviewAnnotation.cfm?action=show&type=collection_object_id&collection=#d.collection#&collection_object_id=#collection_object_id#">
						</cfloop>
						<!--- TODO: Change from fixed foreign key fields to primarykey/targettable pair to generalize annotations to any object type --->
						<cfquery name="prevAnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select annotations.ANNOTATION_ID ANNOTATION_ID,
								annotations.ANNOTATE_DATE ANNOTATE_DATE,
								annotations.CF_USERNAME CF_USERNAME,
								annotations.COLLECTION_OBJECT_ID COLLECTION_OBJECT_ID,
								annotations.TAXON_NAME_ID TAXON_NAME_ID,
								annotations.PROJECT_ID PROJECT_ID,
								annotations.PUBLICATION_ID PUBLICATION_ID,
								annotations.ANNOTATION ANNOTATION,
								annotations.REVIEWER_AGENT_ID REVIEWER_AGENT_ID,
								annotations.REVIEWED_FG REVIEWED_FG,
								annotations.REVIEWER_COMMENT REVIEWER_COMMENT,
								annotations.TARGET_TABLE TARGET_TABLE,
								annotations.TARGET_PRIMARY_KEY TARGET_PRIMARY_KEY,
								annotations.STATE STATE,
								annotations.RESOLUTION RESOLUTION,
								annotations.motivation,
								revname.agent_name revewer_name,
								annotator.first_name annotator_first_name,
								annotator.middle_name annotator_middle_name,
								annotator.last_name annotator_last_name,
								annotator.affiliation annotator_affiliation,
								annotator.email annotator_email
							from annotations 
								left outer join agent rev on annotations.reviewer_agent_id = rev.agent_id
								left outer join agent_name revname on rev.PREFERRED_AGENT_NAME_ID = revname.agent_NAME_ID
								left outer join cf_users on annotations.cf_username = cf_users.username
								left outer join cf_user_data annotator on cf_users.user_id = annotator.user_id
							where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
							order by annotations.STATE, annotate_date
						</cfquery>
					</cfcase>
					<cfcase value="taxon_name">
						<cfset taxon_name_id = target_id>
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select 
								display_name, author_text
							from 
								taxonomy
							where 
								taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
						</cfquery>
						<cfloop query="d">
							<cfset summary="Taxon <strong>#display_name# <span class='sm-caps'>#author_text#</span></strong>">
						</cfloop>
						<cfquery name="prevAnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select annotations.ANNOTATION_ID ANNOTATION_ID,
								annotations.ANNOTATE_DATE ANNOTATE_DATE,
								annotations.CF_USERNAME CF_USERNAME,
								annotations.COLLECTION_OBJECT_ID COLLECTION_OBJECT_ID,
								annotations.TAXON_NAME_ID TAXON_NAME_ID,
								annotations.PROJECT_ID PROJECT_ID,
								annotations.PUBLICATION_ID PUBLICATION_ID,
								annotations.ANNOTATION ANNOTATION,
								annotations.REVIEWER_AGENT_ID REVIEWER_AGENT_ID,
								annotations.REVIEWED_FG REVIEWED_FG,
								annotations.REVIEWER_COMMENT REVIEWER_COMMENT,
								annotations.TARGET_TABLE TARGET_TABLE,
								annotations.TARGET_PRIMARY_KEY TARGET_PRIMARY_KEY,
								annotations.STATE STATE,
								annotations.RESOLUTION RESOLUTION,
								annotations.motivation,
								revname.agent_name revewer_name,
								annotator.first_name annotator_first_name,
								annotator.middle_name annotator_middle_name,
								annotator.last_name annotator_last_name,
								annotator.affiliation annotator_affiliation,
								annotator.email annotator_email
							from annotations 
								left outer join agent rev on annotations.reviewer_agent_id = rev.agent_id
								left outer join agent_name revname on rev.PREFERRED_AGENT_NAME_ID = revname.agent_NAME_ID
								left outer join cf_users on annotations.cf_username = cf_users.username
								left outer join cf_user_data annotator on cf_users.user_id = annotator.user_id
							where taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
							order by annotations.STATE, annotate_date
						</cfquery>
						<!--- TODO: Manage dialog for individual annotations --->
						<cfset manageIRI = "/info/reviewAnnotation.cfm?action=show&type=taxon_name_id&taxon_name_id=#taxon_name_id#">
					</cfcase>
					<cfcase value="project">
						<cfset project_id = target_id>
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select 
								PROJECT_NAME
							from 
								project
							where 
								project_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
						</cfquery>
						<cfloop query="d">
							<cfset summary="Project <strong>#project_name#</strong>">
						</cfloop>
						<cfquery name="prevAnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select annotations.ANNOTATION_ID ANNOTATION_ID,
								annotations.ANNOTATE_DATE ANNOTATE_DATE,
								annotations.CF_USERNAME CF_USERNAME,
								annotations.COLLECTION_OBJECT_ID COLLECTION_OBJECT_ID,
								annotations.TAXON_NAME_ID TAXON_NAME_ID,
								annotations.PROJECT_ID PROJECT_ID,
								annotations.PUBLICATION_ID PUBLICATION_ID,
								annotations.ANNOTATION ANNOTATION,
								annotations.REVIEWER_AGENT_ID REVIEWER_AGENT_ID,
								annotations.REVIEWED_FG REVIEWED_FG,
								annotations.REVIEWER_COMMENT REVIEWER_COMMENT,
								annotations.TARGET_TABLE TARGET_TABLE,
								annotations.TARGET_PRIMARY_KEY TARGET_PRIMARY_KEY,
								annotations.STATE STATE,
								annotations.RESOLUTION RESOLUTION,
								annotations.motivation,
								revname.agent_name revewer_name,
								annotator.first_name annotator_first_name,
								annotator.middle_name annotator_middle_name,
								annotator.last_name annotator_last_name,
								annotator.affiliation annotator_affiliation,
								annotator.email annotator_email
							from annotations 
								left outer join agent rev on annotations.reviewer_agent_id = rev.agent_id
								left outer join agent_name revname on rev.PREFERRED_AGENT_NAME_ID = revname.agent_NAME_ID
								left outer join cf_users on annotations.cf_username = cf_users.username
								left outer join cf_user_data annotator on cf_users.user_id = annotator.user_id
							where project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
							order by annotations.STATE, annotate_date
						</cfquery>
						<!--- TODO: Manage dialog for individual annotations --->
						<cfset manageIRI = "/info/reviewAnnotation.cfm?action=show&type=project_id&project_id=#project_id#">
					</cfcase>
					<cfcase value="publication">
						<cfset publication_id = target_id>
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select 
								formatted_publication
							from 
								formatted_publication
							where 
								format_style = 'long' AND
								publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
						</cfquery>
						<cfloop query="d">
							<cfset summary="Publication <strong>#formatted_publication#</strong>">
						</cfloop>
						<cfquery name="prevAnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select annotations.ANNOTATION_ID ANNOTATION_ID,
								annotations.ANNOTATE_DATE ANNOTATE_DATE,
								annotations.CF_USERNAME CF_USERNAME,
								annotations.COLLECTION_OBJECT_ID COLLECTION_OBJECT_ID,
								annotations.TAXON_NAME_ID TAXON_NAME_ID,
								annotations.PROJECT_ID PROJECT_ID,
								annotations.PUBLICATION_ID PUBLICATION_ID,
								annotations.ANNOTATION ANNOTATION,
								annotations.REVIEWER_AGENT_ID REVIEWER_AGENT_ID,
								annotations.REVIEWED_FG REVIEWED_FG,
								annotations.REVIEWER_COMMENT REVIEWER_COMMENT,
								annotations.TARGET_TABLE TARGET_TABLE,
								annotations.TARGET_PRIMARY_KEY TARGET_PRIMARY_KEY,
								annotations.STATE STATE,
								annotations.RESOLUTION RESOLUTION,
								annotations.motivation,
								revname.agent_name revewer_name,
								annotator.first_name annotator_first_name,
								annotator.middle_name annotator_middle_name,
								annotator.last_name annotator_last_name,
								annotator.affiliation annotator_affiliation,
								annotator.email annotator_email
							from annotations 
								left outer join agent rev on annotations.reviewer_agent_id = rev.agent_id
								left outer join agent_name revname on rev.PREFERRED_AGENT_NAME_ID = revname.agent_NAME_ID
								left outer join cf_users on annotations.cf_username = cf_users.username
								left outer join cf_user_data annotator on cf_users.user_id = annotator.user_id
							where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
							order by annotations.STATE, annotate_date
						</cfquery>
					</cfcase>
					<cfdefaultcase>
						<!--- TODO: Support annotations on at least agents, media (with ROI), and other annotations --->
						<cfthrow message="Annotation on an unsupported target type.">
					</cfdefaultcase>
				</cfswitch>
				<section class="container-fluid">
					<div class="row">
						<div class="col-12">
							<h1 class="h3" tabindex="0">Annotations for #summary#</h2>
						</div>
					</div>
					<div class="row d-block">
						<form name="annotate" method="post" action="/info/annotate.cfm" class="form-row">
							<input type="hidden" name="action" value="insert">
							<input type="hidden" name="idtype" id="idtype" value="#target_type#">
							<input type="hidden" name="idvalue" id="idvalue" value="#target_id#">
							<div class="col-12">
								<label for="annotation" class="data-entry-label">Annotation Text (<span id="length_annotation"></span>)</label>
								<textarea rows="2" name="annotation" id="annotation"
										onkeyup="countCharsLeft('annotation', 4000, 'length_annotation');"
										class="autogrow reqdClr form-control data-entry-textarea" required></textarea>
								<script>
									$(document).ready(function() { 
										$("##annotation").keyup(autogrow);  
										$("##annotation").keyup();  
									});
								</script>
							</div>
							<div class="col-12 col-md-6">
								<label for="motivation" class="data-entry-label">Your motivation for making this annotation</label>
								<select id="motivation" name="motivation" class="data-entry-select">
									<cfloop query="ctmotivation">
										<cfif motivation EQ "commenting"><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
										<option value="#motivation#"#selected#>#motivation# (#description#)</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12">
								<input type="button" class="btn btn-xs btn-primary mt-2" value="Save Annotation" onclick="saveThisAnnotation()">
							</div>
						</form>
					</div>
					<div class="row">
						<div class="col-12">
							<cfif prevAnn.recordcount gt 0>
								<h2 class="h4 mt-5">Annotations on this Record</h2>
								<table id="tbl" class="table table-responsive table-striped">
									<thead class="thead-light">
										<th>Annotation Body</th>
										<th>Created</th>
										<th>Motivation</th>
										<th>Reviewed</th>
										<th>State</th>
										<th>Resolution</th>
									</thead>
									<tbody>
										<cfloop query="prevAnn">
										<tr>
											<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
												<td>#annotation#</td>
											<cfelse>
												<td>#rereplace(annotation,"^.* reported:","[Masked] reported:")#</td>
											</cfif>
											<td>#dateformat(ANNOTATE_DATE,"yyyy-mm-dd")#</td>
											<td>#motivation#</td>
											<td>
												<cfif len(REVIEWER_COMMENT) gt 0>
													#REVIEWER_COMMENT#
												<cfelseif REVIEWED_FG is 0>
													Not Reviewed
												<cfelse>
													Reviewed
												</cfif>
											</td>
											<td>#state#</td>
											<td>#resolution#</td>
										</tr>
									</cfloop>
									</tbody>
								</table>
								<cfif len(manageIRI) GT 0 AND isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user")>
									<a href="#manageIRI#" target="_blank">Manage Annotations</a>
								</cfif>
							<cfelse>
								<h2 class="h3">There are no annotations for this record.</h2>
							</cfif>
						</div>
					</div>
				<section>
			</cfoutput>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
			<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAnnotationDialogHtmlThread" />
	<cfreturn getAnnotationDialogHtmlThread.output>
</cffunction>


<!--- Given an entity and id to annotate and the text of an annotation, save the annotation of the data record.
  * @param target_type the entity to be annotated (e.g. collection_object, taxon_name, publication, permit, annotation)
  * @param target_id the surrogate numeric primary key value for the row in the table specified by target_type to be annotated.
  * @param annotation the text body of an annotation to associate with the record specified by target_type and target_id.
--->
<cffunction name="addAnnotation" access="remote">
	<cfargument name="target_type" type="string" required="yes">
	<cfargument name="target_id" type="numeric" required="yes">
	<cfargument name="annotation" type="string" required="yes">
	<cfargument name="motivation" type="string" required="no">

	<cfif not isDefined("motivation") OR len(motivation) EQ 0>
		<cfset motivation = "commenting">
	</cfif>
	<cfset motivation = rereplace(motivation,"[^a-zA-z]","all")>

	<cfset annotatable = false>
	<cfset mailTo = "">
	<cftry>
		<cfswitch expression="#target_type#">
			<cfcase value="collection_object">
				<cfset annotatable = true>
				<cfquery name="annotated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select guid as annorecord
					from <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> FLAT
					where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_NUMERIC" value="#target_id#">
				</cfquery>
				<cfif annotated.recordcount EQ 0>
					<cfthrow message="Catalged item to annotate not found.">
				</cfif>
				<cfquery name="whoTo" datasource="uam_god">
					select distinct
						address
					FROM
						cataloged_item,
						collection,
						collection_contacts,
						electronic_address
					WHERE
						cataloged_item.collection_id = collection.collection_id AND
						collection.collection_id = collection_contacts.collection_id AND
						collection_contacts.contact_agent_id = electronic_address.agent_id AND
						collection_contacts.CONTACT_ROLE = 'data quality' and
						electronic_address.ADDRESS_TYPE='e-mail' and
						cataloged_item.collection_object_id= <cfqueryparam cfsqltype='CF_SQL_NUMERIC' value='#target_id#' >
				</cfquery>
				<cfset mailTo = valuelist(whoTo.address)>
			</cfcase>
			<cfcase value="taxon_name">
				<cfset annotatable = true>
				<cfquery name="annotated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select 'Taxon:' || scientific_name || ' ' || author_text as annorecord
					from taxonomy
					where taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_NUMERIC" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfcase value="publication">
				<cfset annotatable = true>
				<cfquery name="annotated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select 'Publication:' || MCZBASE.getshortcitation(publication_id) as annorecord
					from publication
					where publication_id = <cfqueryparam cfsqltype="CF_SQL_NUMERIC" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfdefaultcase>
				<cfthrow message="Only annotation of collection objects, publications, and taxa are supported at this time">
			</cfdefaultcase>
		</cfswitch>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
		<cfoutput>
			<div class="container">
				<div class="row">
					<div class="alert alert-danger" role="alert">
						<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
						<h2>Internal Server Error.</h2>
						<p>#message#</p>
						<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
					</div>
				</div>
			</div>
		</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfif annotatable>
		<cftry>
			<cfquery name="annotator" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select username, first_name, last_name, affiliation, email 
				from cf_users u left join cf_user_data ud on u.user_id = ud.user_id
				where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="insAnn" datasource="uam_god">
				insert into annotations (
					cf_username,
					<cfif target_type EQ 'collection_object'>
						collection_object_id,
					<cfelseif target_type EQ 'taxon_name'>
						taxon_name_id,
					<cfelseif target_type EQ 'publication'>
						publication_id,
					</cfif>
					annotation,
					target_table, 
					target_primary_key,
					state,
					motivation
				) values (
					<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#session.username#' >,
					<cfqueryparam cfsqltype='CF_SQL_NUMERIC' value='#target_id#' >,
					<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='For #annotated.annorecord# #annotator.first_name# #annotator.last_name# #annotator.affiliation# #annotator.email# reported: #urldecode(annotation)#' >,
					<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#target_type#' >,
					<cfqueryparam cfsqltype='CF_SQL_NUMERIC' value='#target_id#' >,
					'New',
					<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#motivation#' >
				)
			</cfquery>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
			<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
			<cfabort>
		</cfcatch>
		</cftry>

		<cftry>
			<cfset mailTo=listappend(mailTo,Application.bugReportEmail,",")>
			<cfmail to="#mailTo#" from="annotation@#Application.fromEmail#" subject="Annotation Submitted" type="html">
An MCZbase User: #session.username# (#annotator.first_name# #annotator.last_name# #annotator.affiliation# #annotator.email#) has submitted an annotation to report problematic data concerning #annotated.annorecord#.  Motivation: #motivation#.
    
    			<blockquote>
    				#annotation#
    			</blockquote>
    
    			View details at
    			<a href="#Application.ServerRootUrl#/info/reviewAnnotation.cfm?action=show&type=#target_type#&id=#target_id#">
    			#Application.ServerRootUrl#/info/annotate.cfm?action=show&type=#target_type#&id=#target_id#
    			</a>
			</cfmail>
			<cfset newline= Chr(13) & Chr(10)>
			<cfset reported_name = "#annotator.first_name# #annotator.last_name# #annotator.affiliation#">
			<cfset summary=left("#annotated.guid# #annotation#",60)><!--- obtain the begining of the complaint as a bug summary --->
			<cfset bugzilla_mail="#Application.bugzillaToEmail#"><!--- address to access email_in.pl script --->
			<cfset bugzilla_user="#Application.bugzillaFromEmail#"><!--- bugs submitted by email can only come from a registered bugzilla user --->
			<cfmail to="#bugzilla_mail#" subject="#summary#" from="#bugzilla_user#" type="text">@rep_platform = PC
@op_sys = Linux
@product = MCZbase
@component = Data
@version = 2.5.1merge
@priority = P3
@bug_severity = enhancement

Bug report by: #reported_name# (Username: #session.username#)
Email: #annotator.email#
Complaint: #annotation#
#newline##newline#
Annotation to report problematic data concerning #annotated.annorecord#
			</cfmail>
			<cfset result = "success saving annotatation and sending notification email">
		<cfcatch>
			<cfset result = "success saving annotation, error sending notification email">
		</cfcatch>
		</cftry>
	</cfif>
	<cfreturn result>
</cffunction>
</cfcomponent>
