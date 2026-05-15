<!---
/annotations/component/functions.cfc

Copyright 2020-2026 President and Fellows of Harvard College

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

<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- Given an entity and id to annotate, return the HTML for a dialog to view existing annotations and add a new annotation for the specified record. The dialog HTML is returned as a string to be placed into a jQuery UI dialog by the calling function.
  * @param target_type the entity to be annotated (e.g. collection_object, taxon_name, publication, permit, annotation)
  * @param target_id the surrogate numeric primary key value for the row in the table specified by target_type to be annotated.
  * @param dialogId the html id value for the dialog to contain the returned HTML; used to set the id attribute of the form within the dialog and for callback functions to close the dialog after saving an annotation.
  * @return HTML string for a dialog to view existing annotations and add a new annotation for the specified record.
--->
<cffunction name="getAnnotationDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="target_type" type="string" required="yes">
	<cfargument name="target_id" type="numeric" required="yes">
	<cfargument name="dialogId" type="string" required="yes">
	
	<cfsavecontent variable="dialogHtml">
		<cftry>
			<cfoutput>
				<cfquery name="hasEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
					select email from cf_user_data,cf_users
					where cf_user_data.user_id = cf_users.user_id and
					cf_users.username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfif hasEmail.recordcount GT 0 AND len(hasEmail.email) GT 0>
					<cfset canAnnotate = true>
				<cfelse>
					<cfset canAnnotate = false>
				</cfif>
				<cfset manageIRI = "">
				<cfset dialogTargetId = target_id>
				<cfset responseRootAnnotationId = "">
				<cfset dialogFieldQualifier = "_" & rereplace(dialogId,"[^A-Za-z0-9_]","","all")>
				<cfset idtypeFieldId = "idtype" & dialogFieldQualifier>
				<cfset idvalueFieldId = "idvalue" & dialogFieldQualifier>
				<cfset annotationFieldId = "annotation" & dialogFieldQualifier>
				<cfset annotationLengthId = "length_annotation" & dialogFieldQualifier>
				<cfset motivationFieldId = "motivation" & dialogFieldQualifier>
				<cfset maskFieldId = "mask_annotation_fg" & dialogFieldQualifier>
				<cfset rootReviewedFieldId = "root_reviewed_fg" & dialogFieldQualifier>
				<cfset rootMaskFieldId = "root_mask_annotation_fg" & dialogFieldQualifier>
				<cfset annotationResultDivId = "annotationResultDiv" & dialogFieldQualifier>
				<cfif canAnnotate>
					<cfquery name="ctmotivation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
						SELECT motivation, description
						FROM ctmotivation
						ORDER by motivation
					</cfquery>
				</cfif>
				<cfswitch expression="#target_type#">
					<cfcase value="collection_object">
						<cfset collection_object_id = target_id>
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
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
							<cfset manageIRI = "/annotations/Annotations.cfm?action=show&type=collection_object_id&collection=#d.collection#&collection_object_id=#collection_object_id#">
						</cfloop>
					</cfcase>
					<cfcase value="taxon_name">
						<cfset taxon_name_id = target_id>
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
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
						<!--- TODO: Manage dialog for individual annotations --->
						<cfset manageIRI = "/annotations/Annotations.cfm?action=show&type=taxon_name_id&taxon_name_id=#taxon_name_id#">
					</cfcase>
					<cfcase value="project">
						<cfset project_id = target_id>
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
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
						<!--- TODO: Manage dialog for individual annotations --->
						<cfset manageIRI = "/annotations/Annotations.cfm?action=show&type=project_id&project_id=#project_id#">
					</cfcase>
					<cfcase value="publication">
						<cfset publication_id = target_id>
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
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
						<!--- TODO: Manage dialog for individual annotations --->
						<cfset manageIRI = "/annotations/Annotations.cfm?action=show&type=publication_id&publication_id=#publication_id#">
					</cfcase>
					<cfcase value="annotation">
						<cfset annotation_id = target_id>
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
							select
								a.annotation_id,
								atb.body_value
							from
								annotations a
								left outer join (
									select annotation_id, body_value,
									       row_number() over (partition by annotation_id order by created_date) rn
									from annotation_textualbody
								) atb on a.annotation_id = atb.annotation_id and atb.rn = 1
							where
								a.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#annotation_id#">
						</cfquery>
						<cfif d.recordcount EQ 0>
							<cfthrow message="Annotation to annotate not found.">
						</cfif>
						<cfset targetAnnotationId = d.annotation_id>
						<cfset targetAnnotationBody = d.body_value>
						<cfif len(targetAnnotationBody) GT 0>
							<cfset summary="Annotation <strong>#targetAnnotationId#</strong>: #encodeForHTML(targetAnnotationBody)#">
						<cfelse>
							<cfset summary="Annotation <strong>#targetAnnotationId#</strong>">
						</cfif>
						<cfquery name="annotationRootForDialog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT annotation_id
							FROM (
								SELECT annotation_id, LEVEL hierarchy_level
								FROM annotations
								START WITH annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#targetAnnotationId#">
								CONNECT BY PRIOR target_primary_key = annotation_id AND PRIOR target_table = 'ANNOTATIONS'
								ORDER BY LEVEL DESC
							)
							WHERE ROWNUM = 1
						</cfquery>
						<cfif annotationRootForDialog.recordcount EQ 1>
							<cfset responseRootAnnotationId = annotationRootForDialog.annotation_id>
							<cfset dialogTargetId = annotationRootForDialog.annotation_id>
						<cfelse>
							<cfset responseRootAnnotationId = targetAnnotationId>
						</cfif>
						<cfif responseRootAnnotationId NEQ targetAnnotationId>
							<cfif len(targetAnnotationBody) GT 0>
								<cfset summary="Response Annotation <strong>#targetAnnotationId#</strong>: #encodeForHTML(targetAnnotationBody)#">
							<cfelse>
								<cfset summary="Response Annotation <strong>#targetAnnotationId#</strong>">
							</cfif>
							<cfquery name="rootAnnotationSummaryForDialog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT a.annotation_id, atb.body_value
								FROM annotations a
								LEFT OUTER JOIN (
									SELECT annotation_id, body_value,
									       row_number() over (partition by annotation_id order by created_date) rn
									FROM annotation_textualbody
								) atb ON a.annotation_id = atb.annotation_id AND atb.rn = 1
								WHERE a.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#responseRootAnnotationId#">
							</cfquery>
							<cfif rootAnnotationSummaryForDialog.recordcount EQ 1>
								<cfif len(rootAnnotationSummaryForDialog.body_value) GT 0>
									<cfset summary = summary & '<span class="small d-block mt-1">Root Annotation <strong>' & responseRootAnnotationId & '</strong>: ' & encodeForHTML(rootAnnotationSummaryForDialog.body_value) & '</span>'>
								<cfelse>
									<cfset summary = summary & '<span class="small d-block mt-1">Root Annotation <strong>' & responseRootAnnotationId & '</strong></span>'>
								</cfif>
							</cfif>
						</cfif>
					</cfcase>
					<cfdefaultcase>
						<!--- TODO: Support annotations on at least agents, media (with ROI), and other annotations --->
						<cfthrow message="Annotation on an unsupported target type.">
					</cfdefaultcase>
				</cfswitch>
				<!--- Single shared query for all target types; WHERE clause varies by target_type using cfif, not by SQL variable. --->
				<cfquery name="prevAnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
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
						revname.agent_name reviewer_name,
						annotator.first_name annotator_first_name,
						annotator.middle_name annotator_middle_name,
						annotator.last_name annotator_last_name,
						annotator.affiliation annotator_affiliation,
						annotator.email annotator_email,
						annotations.ANNOTATOR_AGENT_ID ANNOTATOR_AGENT_ID,
						annotations.MASK_ANNOTATION_FG MASK_ANNOTATION_FG,
						atb.body_value BODY_VALUE
					from annotations
						left outer join agent rev on annotations.reviewer_agent_id = rev.agent_id
						left outer join agent_name revname on rev.PREFERRED_AGENT_NAME_ID = revname.agent_NAME_ID
						left outer join cf_users on annotations.cf_username = cf_users.username
						left outer join cf_user_data annotator on cf_users.user_id = annotator.user_id
						left outer join (
							select annotation_id, body_value,
								row_number() over (partition by annotation_id order by created_date) rn
							from annotation_textualbody
						) atb on annotations.annotation_id = atb.annotation_id and atb.rn = 1
					where
					<cfif target_type EQ "collection_object">
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					<cfelseif target_type EQ "taxon_name">
						taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
					<cfelseif target_type EQ "project">
						project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
					<cfelseif target_type EQ "publication">
						publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
					<cfelseif target_type EQ "annotation">
						annotations.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#responseRootAnnotationId#">
						OR (
							target_table in ('ANNOTATION','ANNOTATIONS')
							and target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#responseRootAnnotationId#">
						)
					<cfelse>
						1=0
					</cfif>
					order by annotations.STATE, annotate_date
				</cfquery>
				<section class="container-fluid">
					<div class="row">
						<div class="col-12 px-0 px-md-3">
							<h2 class="h3 my-1 px-1" tabindex="0">Annotations for #summary#</h2>
							<cfif canAnnotate>
							<div class="col-12 px-0 add-form">
								<div class="add-form-header px-2 pb-1">
									<h3 class="h4 my-0 px-1 py-1" tabindex="0">Add New Annotation</h3>
								</div>
								<div class="row col-12 mx-0 mt-1 d-block">
									<form name="annotate" onSubmit="return false;" class="form-row">
										<input type="hidden" name="action" value="insert">
										<input type="hidden" name="idtype" id="#idtypeFieldId#" value="#target_type#">
										<input type="hidden" name="idvalue" id="#idvalueFieldId#" value="#dialogTargetId#">
										<div class="col-12 pb-1">
											<label for="#annotationFieldId#" class="data-entry-label">Annotation Text (<span id="#annotationLengthId#"></span>)</label>
											<textarea rows="2" name="annotation" id="#annotationFieldId#"
													onkeyup="countCharsLeft('#annotationFieldId#', 4000, '#annotationLengthId#');"
													class="autogrow reqdClr form-control data-entry-textarea" required></textarea>
											<script>
												$(document).ready(function() { 
													$("###annotationFieldId#").keyup(autogrow);  
													$("###annotationFieldId#").keyup();  
												});
											</script>
										</div>
										<div class="col-12 pb-1">
											<label for="#motivationFieldId#" class="data-entry-label">Your motivation for making this annotation</label>
											<select id="#motivationFieldId#" name="motivation" class="data-entry-select">
												<cfloop query="ctmotivation">
													<cfif target_type EQ "annotation">
														<cfif motivation EQ "replying"><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
													<cfelse>
														<cfif motivation EQ "commenting"><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
													</cfif>
													<option value="#motivation#"#selected#>#motivation# (#description#)</option>
												</cfloop>
											</select>
										</div>
										<cfif target_type EQ "annotation">
											<div class="col-12 col-md-3 pb-1">
												<label for="#rootReviewedFieldId#" class="data-entry-label">Mark Parent Reviewed?</label>
												<select id="#rootReviewedFieldId#" name="root_reviewed_fg" class="data-entry-select">
													<option value="" selected="selected">No Change</option>
													<option value="0">No</option>
													<option value="1">Yes</option>
												</select>
											</div>
										</cfif>
										<cfif isdefined("session.roles") AND listfindnocase(session.roles,"manage_collection")>
											<div class="col-12 <cfif target_type EQ "annotation">col-md-3<cfelse>col-md-6</cfif> pb-1">
												<label for="#maskFieldId#" class="data-entry-label"><cfif target_type EQ "annotation">Response Visibility:<cfelse>Visibility:</cfif></label>
												<select id="#maskFieldId#" name="mask_annotation_fg" class="data-entry-select">
													<option value="0" selected="selected">Public</option>
													<option value="1">Hidden</option>
												</select>
											</div>
											<cfif target_type EQ "annotation">
												<div class="col-12 col-md-3 pb-1">
													<label for="#rootMaskFieldId#" class="data-entry-label">Parent Visibility:</label>
													<select id="#rootMaskFieldId#" name="root_mask_annotation_fg" class="data-entry-select">
														<option value="" selected="selected">No Change</option>
														<option value="0">Public</option>
														<option value="1">Hidden</option>
													</select>
												</div>
											</cfif>
										</cfif>
										<div class="col-12 pt-1">
											<input type="button"
												class="btn btn-xs btn-primary mt-1" 
												value="Save Annotation" 
												onclick="saveThisAnnotation('#annotationResultDivId#', function(){ closeAnnotationDialogById('#encodeForJavaScript(dialogId)#'); }, '#dialogFieldQualifier#')">
											<output id="#annotationResultDivId#" class="ml-2" aria-live="polite"></output>
										</div>
									</form>
								</div>
							</div>
							<cfelse>
								<p class="px-1 py-1 text-muted small">To add an annotation, you must be logged in with a registered email address.</p>
							</cfif>
							<div class="col-12 mx-0 px-0 mt-2">
								<cfif prevAnn.recordcount gt 0>
									<div class="d-flex justify-content-between align-items-center mt-1 px-1">
											<h2 class="h4 mb-0">Annotations on this Record</h2>
											<cfif len(manageIRI) GT 0 AND isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user")>
												<a href="#manageIRI#" class="btn btn-xs btn-primary" target="_blank">Manage Annotations</a>
											</cfif>
										</div>
										<cfquery name="rootDialogAnnotations" dbtype="query">
											SELECT *
											FROM prevAnn
											WHERE target_table IS NULL OR UPPER(target_table) <> 'ANNOTATIONS'
											ORDER BY ANNOTATE_DATE
										</cfquery>
										<cfif rootDialogAnnotations.recordcount GT 0>
											<cfset dialogChildAnno = getChildAnnotationsForRoots(valueList(rootDialogAnnotations.annotation_id))>
											<div class="card border-0 mt-1">
												<cfloop query="rootDialogAnnotations">
													<cfif len(body_value) GT 0>
														<cfset dialogAnnotationDisplay = body_value>
													<cfelse>
														<cfset dialogAnnotationDisplay = annotation>
													</cfif>
													<cfset dialogRootRowHtml = renderAnnotationReviewRow(
														annotation_id=annotation_id,
														annotation_display=dialogAnnotationDisplay,
														cf_username=CF_USERNAME,
														email=annotator_email,
														annotate_date=ANNOTATE_DATE,
														motivation=motivation,
														reviewed_fg=reviewed_fg,
														reviewer=reviewer_name,
														reviewer_comment=reviewer_comment,
														mask_annotation_fg=mask_annotation_fg,
														is_response=false,
														root_annotation_id=annotation_id,
														show_reply_action=true)>
													#dialogRootRowHtml#
													#renderAnnotationConversationSection(rootAnnotationId=rootDialogAnnotations.annotation_id, childAnnotations=dialogChildAnno)#
												</cfloop>
											</div>
										</cfif>
								<cfelse>
									<p class="px-1 mt-1 text-muted">There are no annotations for this record.</p>
								</cfif>
							</div>
						</div>
					</div>
				</section>
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
	</cfsavecontent>
	<cfreturn dialogHtml>
</cffunction>


<!--- Given an entity and id to annotate and the text of an annotation, save the annotation of the data record.
  * @param target_type the entity to be annotated (e.g. collection_object, taxon_name, publication, permit, annotation)
 * @param target_id the surrogate numeric primary key value for the row in the table specified by target_type to be annotated.
 * @param annotation the text body of an annotation to associate with the record specified by target_type and target_id.
 * @param motivation the motivation for the annotation (optional, defaults to commenting).
 * @param mask_annotation_fg optional; 1 to hide the annotation from public, 0 for public; only applied for manage_collection role.
 * @param root_state optional state to set on the root annotation when target_type is annotation.
 * @param root_resolution optional resolution to set on the root annotation when target_type is annotation.
 * @param root_reviewed_fg optional reviewed value (0/1) to set on the root annotation when target_type is annotation.
 * @param root_mask_annotation_fg optional mask value (0/1) to set on the root annotation when target_type is annotation; only applied for manage_collection role.
--->
<cffunction name="addAnnotation" access="remote">
	<cfargument name="target_type" type="string" required="yes">
	<cfargument name="target_id" type="numeric" required="yes">
	<cfargument name="annotation" type="string" required="yes">
	<cfargument name="motivation" type="string" required="no">
	<cfargument name="mask_annotation_fg" type="string" required="no" default="">
	<cfargument name="root_state" type="string" required="no" default="">
	<cfargument name="root_resolution" type="string" required="no" default="">
	<cfargument name="root_reviewed_fg" type="string" required="no" default="">
	<cfargument name="root_mask_annotation_fg" type="string" required="no" default="">

	<cfif not isDefined("motivation") OR len(motivation) EQ 0>
		<cfset motivation = "commenting">
	</cfif>
	<cfset motivation = rereplace(motivation,"[^a-zA-Z]","","all")>
	<cfif target_type EQ "annotation">
		<cfset targetTableName = "ANNOTATIONS">
	<cfelse>
		<cfset targetTableName = UCase(target_type)>
	</cfif>

	<cfset annotatable = false>
	<cfset mailTo = "">
	<cfset rootAnnotationId = target_id>
	<cftry>
		<cfswitch expression="#target_type#">
			<cfcase value="collection_object">
				<cfset annotatable = true>
				<cfquery name="annotated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT guid as annorecord
					FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> FLAT
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
				<cfif annotated.recordcount EQ 0>
					<cfthrow message="Catalged item to annotate not found.">
				</cfif>
				<cfquery name="whoTo" datasource="uam_god">
					SELECT DISTINCT
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
						cataloged_item.collection_object_id= <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#target_id#' >
				</cfquery>
				<cfset mailTo = valuelist(whoTo.address)>
			</cfcase>
			<cfcase value="taxon_name">
				<cfset annotatable = true>
				<cfquery name="annotated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 'Taxon:' || scientific_name || ' ' || author_text as annorecord
					FROM taxonomy
					WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfcase value="publication">
				<cfset annotatable = true>
				<cfquery name="annotated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 'Publication:' || MCZBASE.getshortcitation(publication_id) as annorecord
					FROM publication
					WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfcase value="project">
				<cfset annotatable = true>
				<cfquery name="annotated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 'Project:' || project_name as annorecord
					FROM project
					WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfcase value="annotation">
				<cfset annotatable = true>
				<cfquery name="annotated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						'Annotation:' || annotation_id as annorecord
					FROM annotations
					WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
				<cfif annotated.recordcount EQ 0>
					<cfthrow message="Annotation to annotate not found.">
				</cfif>
				<cfquery name="annotationRoot" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT annotation_id
					FROM (
						SELECT annotation_id, LEVEL hierarchy_level
						FROM annotations
						START WITH annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
						CONNECT BY PRIOR target_primary_key = annotation_id AND PRIOR target_table = 'ANNOTATIONS'
						ORDER BY LEVEL DESC
					)
					WHERE ROWNUM = 1
				</cfquery>
				<cfif annotationRoot.recordcount EQ 1>
					<cfset rootAnnotationId = annotationRoot.annotation_id>
				</cfif>
			</cfcase>
			<cfdefaultcase>
				<cfthrow message="Only annotation of collection objects, projects, publications, taxa, and annotations are supported at this time">
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
		<cftransaction>
			<cftry>
				<cfset var storedTargetTable = "">
				<cfswitch expression="#target_type#">
					<cfcase value="annotation">
						<cfset storedTargetTable = "ANNOTATIONS">
					</cfcase>
					<cfdefaultcase>
						<cfset storedTargetTable = UCase(target_type)>
					</cfdefaultcase>
				</cfswitch>
				<cfquery name="agentLookup" datasource="uam_god">
					SELECT MIN(an.agent_id) AS annotator_agent_id
					FROM agent_name an
					WHERE an.agent_name_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="login">
					AND an.agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfif agentLookup.recordcount GT 0 AND val(agentLookup.annotator_agent_id) GT 0>
					<cfset annotatorAgentId = agentLookup.annotator_agent_id>
				<cfelse>
					<cfset annotatorAgentId = "">
				</cfif>
				<cfquery name="annotator" datasource="uam_god">
					SELECT username, first_name, last_name, affiliation, email 
					FROM cf_users u left join cf_user_data ud on u.user_id = ud.user_id
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfset setMaskFg = isdefined("session.roles") AND listfindnocase(session.roles,"manage_collection") AND len(mask_annotation_fg) GT 0 AND REFind("^[01]$", trim(mask_annotation_fg)) GT 0>
				<cfquery name="insAnn" datasource="uam_god" result="insAnn_result">
					INSERT INTO annotations (
						cf_username,
						annotation,
						target_table, 
						target_primary_key,
						state,
						motivation
						<cfif len(annotatorAgentId) GT 0>,annotator_agent_id</cfif>
						<cfif setMaskFg>,mask_annotation_fg</cfif>
					) VALUES (
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#session.username#' >,
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='For #annotated.annorecord# #annotator.first_name# #annotator.last_name# #annotator.affiliation# #annotator.email# reported: #urldecode(annotation)#' >,
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#storedTargetTable#' >,
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#target_id#' >,
						'New',
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#motivation#' >
						<cfif len(annotatorAgentId) GT 0>,<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#annotatorAgentId#'></cfif>
						<cfif setMaskFg>,<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#mask_annotation_fg#'></cfif>
					)
				</cfquery>
				<!--- obtain the inserted annotation_id value from the generated key obtained from the result --->
				<cfquery name="getAnnotationID" datasource="uam_god">
					SELECT annotations.annotation_id 
					FROM annotations
					WHERE ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#insAnn_result.GENERATEDKEY#">
				</cfquery>
				<!--- place the annotation text into a textual body --->
				<cfquery name="insTextualBody" datasource="uam_god">
					INSERT INTO annotation_textualbody (
						annotation_id,
						body_value,
						body_format,
						body_language,
						created_date
					) VALUES (
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#getAnnotationID.annotation_id#'>,
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#urldecode(annotation)#'>,
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='text/plain'>,
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' null="yes">,
						SYSDATE
					)
				</cfquery>
				<cfif target_type EQ "annotation" AND (len(trim(root_state)) GT 0 OR len(trim(root_resolution)) GT 0)>
					<cfquery name="updRootAnnStateResolution" datasource="uam_god">
						UPDATE annotations
						SET
							<cfif len(trim(root_state)) GT 0 AND len(trim(root_resolution)) GT 0>
								state = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#trim(root_state)#'>,
								resolution = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#trim(root_resolution)#'>
							<cfelseif len(trim(root_state)) GT 0>
								state = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#trim(root_state)#'>
							<cfelse>
								resolution = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#trim(root_resolution)#'>
							</cfif>
						WHERE annotation_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#rootAnnotationId#'>
					</cfquery>
				</cfif>
				<cfif target_type EQ "annotation" AND len(trim(root_reviewed_fg)) GT 0 AND REFind("^[01]$", trim(root_reviewed_fg)) GT 0>
					<cfquery name="updRootAnnReviewed" datasource="uam_god">
						UPDATE annotations
						SET
							reviewed_fg = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#trim(root_reviewed_fg)#'>,
							reviewer_agent_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#session.myAgentId#'>
						WHERE annotation_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#rootAnnotationId#'>
					</cfquery>
				</cfif>
				<cfif target_type EQ "annotation"
					AND isdefined("session.roles")
					AND listfindnocase(session.roles,"manage_collection")
					AND len(trim(root_mask_annotation_fg)) GT 0
					AND REFind("^[01]$", trim(root_mask_annotation_fg)) GT 0>
					<cfquery name="updRootAnnMask" datasource="uam_god">
						UPDATE annotations
						SET
							mask_annotation_fg = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#trim(root_mask_annotation_fg)#'>
						WHERE annotation_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#rootAnnotationId#'>
					</cfquery>
				</cfif>
				<cftransaction action="commit">
			<cfcatch>
				<cftransaction action="rollback">
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
		</cftransaction>

		<cftry>
			<cfset mailTo=listappend(mailTo,Application.bugReportEmail,",")>
			<cfmail to="#mailTo#" from="annotation@#Application.fromEmail#" subject="Annotation Submitted" type="html">
An MCZbase User: #session.username# (#annotator.first_name# #annotator.last_name# #annotator.affiliation# #annotator.email#) has submitted an annotation to report problematic data concerning #annotated.annorecord#.  Motivation: #motivation#.
    
    			<blockquote>
    				#annotation#
    			</blockquote>
    
    			View details at
    			<a href="#Application.ServerRootUrl#/annotations/Annotations.cfm?action=show&type=#target_type#&id=#target_id#">
    			#Application.ServerRootUrl#/annotations/Annotations.cfm?action=show&type=#target_type#&id=#target_id#
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


<!--- Deliver html for a dialog to review and manage annotations on a cataloged item.
 Delegates to getAnnotationDialogHtml for a unified annotation dialog.
 @param collection_object_id the surrogate numeric primary key value for the cataloged_item.
 @return html for a dialog to review and manage annotations on a cataloged item.
--->
<cffunction name="getReviewCIAnnotationHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfset var generatedDialogId = "reviewAnnotationsDialog_" & val(arguments.collection_object_id)>
	<cfreturn getAnnotationDialogHtml(
		target_type = "collection_object",
		target_id = val(arguments.collection_object_id),
		dialogId = generatedDialogId
	)>
</cffunction>

<!--- Update the review status and optional comment for an annotation.
 @param annotation_id the surrogate numeric primary key value for the annotation to be updated.
 @param reviewed_fg 1 if the annotation has been reviewed, 0 if not.
 @param reviewer_comment optional text comment about the review of the annotation.
 @param mask_annotation_fg optional; 1 to hide the annotation from public, 0 to show; only applied for manage_collection role.
 @return json with status=updated or an http 500 error if the update fails.
--->
<cffunction name="updateAnnotationReview" returntype="any" access="remote" returnformat="json">
	<cfargument name="annotation_id" type="string" required="yes">
   <cfargument name="reviewed_fg" type="string" required="yes">
	<cfargument name="reviewer_comment" type="string" required="no" default="">
	<cfargument name="mask_annotation_fg" type="string" required="no" default="">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="updateAnnotation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateAnnotation_result">
				UPDATE annotations
				SET
					reviewer_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
					reviewed_fg=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#reviewed_fg#">,
					reviewer_comment=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#reviewer_comment#">
					<cfif isdefined("session.roles") AND listfindnocase(session.roles,"manage_collection") AND len(mask_annotation_fg) GT 0>
						,mask_annotation_fg=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(mask_annotation_fg)#">
					</cfif>
				WHERE
					annotation_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#annotation_id#">
			</cfquery>
			<cfif updateAnnotation_result.recordcount NEQ 1>
				<cfthrow message="Annotation to update not found.">
			</cfif>
			<cftransaction action="commit">
			<cfset row = StructNew()>
			<cfset row["status"] = "updated">	
			<cfset data[1] = row>
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(data)>
</cffunction>


<!--- Update the mask_annotation_fg flag for an annotation.
 @param annotation_id the surrogate numeric primary key value for the annotation to be updated.
 @param mask_annotation_fg 1 to hide the annotation from users without coldfusion_user role, 0 to show.
 @return json with status=updated or an http 500 error if the update fails.
--->    
<cffunction name="setAnnotationMask" returntype="any" access="remote" returnformat="json">
	<cfargument name="annotation_id" type="string" required="yes">
	<cfargument name="mask_annotation_fg" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfif NOT (isdefined("session.roles") AND listfindnocase(session.roles,"manage_collection"))>
				<cfthrow message="The manage_collection role is required to set annotation visibility.">
			</cfif>
			<cfquery name="updateMask" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateMask_result">
				UPDATE annotations
				SET mask_annotation_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(mask_annotation_fg)#">
				WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#annotation_id#">
			</cfquery>
			<cfif updateMask_result.recordcount NEQ 1>
				<cfthrow message="Annotation to update not found.">
			</cfif>
			<cftransaction action="commit">
			<cfset row = StructNew()>
			<cfset row["status"] = "updated">
			<cfset data[1] = row>
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(data)>
</cffunction>


<!--- Retrieve child/reply annotations for a list of root annotation ids.
 @param rootAnnotationIds comma-delimited list of annotation.annotation_id values.
 @return query of child annotations keyed by parent_annotation_id.
--->
<cffunction name="getChildAnnotationsForRoots" returntype="query" access="public">
	<cfargument name="rootAnnotationIds" type="string" required="yes">
	<cfset var childAnnotations = QueryNew("")>
	<cfif len(arguments.rootAnnotationIds) EQ 0>
		<cfreturn childAnnotations>
	</cfif>
	<cfquery name="childAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			annotations.annotation_id,
			NVL(atb.body_value, annotations.annotation) annotation_display,
			annotations.cf_username,
			cf_user_data.email,
			annotations.annotate_date,
			annotations.motivation,
			annotations.reviewed_fg,
			preferred_agent_name.agent_name reviewer,
			annotations.reviewer_comment,
			annotations.mask_annotation_fg,
			annotations.target_primary_key parent_annotation_id
		FROM
			annotations
			LEFT OUTER JOIN cf_users ON annotations.cf_username = cf_users.username
			LEFT OUTER JOIN cf_user_data ON cf_users.user_id = cf_user_data.user_id
			LEFT OUTER JOIN preferred_agent_name ON annotations.reviewer_agent_id = preferred_agent_name.agent_id
			LEFT OUTER JOIN (
				SELECT annotation_id, body_value,
					ROW_NUMBER() OVER (PARTITION BY annotation_id ORDER BY created_date) rn
				FROM annotation_textualbody
			) atb ON annotations.annotation_id = atb.annotation_id AND atb.rn = 1
		WHERE
			upper(annotations.target_table) = 'ANNOTATIONS'
			AND annotations.target_primary_key IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.rootAnnotationIds#" list="yes">)
		ORDER BY
			annotations.target_primary_key,
			annotations.annotate_date
	</cfquery>
	<cfreturn childAnnotations>
</cffunction>


<!--- Render conversation section with existing child annotations indented with a left border.
 @param rootAnnotationId annotation.annotation_id for the root annotation.
 @param childAnnotations query from getChildAnnotationsForRoots().
 @return html snippet for conversation section.
--->
<cffunction name="renderAnnotationConversationSection" returntype="string" access="public">
	<cfargument name="rootAnnotationId" type="numeric" required="yes">
	<cfargument name="childAnnotations" type="query" required="yes">
	<cfset var sectionHtml = "">
	<cfset var rootChildren = QueryNew("annotation_id,annotation_display,cf_username,email,annotate_date,motivation,reviewed_fg,reviewer,reviewer_comment,mask_annotation_fg")>
	<cfset var childRowHTML = "">
	<cfif arguments.childAnnotations.recordcount GT 0>
		<cfset var childAnnoQuery = arguments.childAnnotations>
		<cfquery name="rootChildren" dbtype="query">
			SELECT
				annotation_id, annotation_display, cf_username, email,
				annotate_date, motivation, reviewed_fg, reviewer,
				reviewer_comment, mask_annotation_fg
			FROM childAnnoQuery
			WHERE parent_annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.rootAnnotationId#">
		</cfquery>
	</cfif>
	<cfsavecontent variable="sectionHtml">
		<cfoutput>
		<cfif rootChildren.recordcount GT 0>
			<div class="ml-4 pl-0 border-left border-dark" data-reply-parent-id="#arguments.rootAnnotationId#">
				<cfloop query="rootChildren">
					<cfset childRowHTML = renderAnnotationReviewRow(
						annotation_id=rootChildren.annotation_id,
						annotation_display=rootChildren.annotation_display,
						cf_username=rootChildren.cf_username,
						email=rootChildren.email,
						annotate_date=rootChildren.annotate_date,
						motivation=rootChildren.motivation,
						reviewed_fg=rootChildren.reviewed_fg,
						reviewer=rootChildren.reviewer,
						reviewer_comment=rootChildren.reviewer_comment,
						mask_annotation_fg=rootChildren.mask_annotation_fg,
						is_response=true,
						root_annotation_id=arguments.rootAnnotationId,
						show_reply_action=false
					)>
					#childRowHTML#
				</cfloop>
			</div>
		</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn trim(sectionHtml)>
</cffunction>


<!--- Render HTML for a single annotation row card.
 Returns a card-body div with annotation details, controls, and action buttons.
 @param annotation_id       numeric annotation primary key
 @param annotation_display  annotation body text (may contain trusted HTML from annotation_textualbody)
 @param cf_username         annotator login username
 @param email               annotator e-mail address
 @param annotate_date       date the annotation was created
 @param motivation          annotation motivation string
 @param reviewed_fg         0 or 1 indicating whether the annotation has been reviewed
 @param reviewer            preferred name of the last reviewer, or empty string
 @param reviewer_comment    retained for backwards compatibility.
 @param mask_annotation_fg  0 or 1 annotation visibility flag
 @param is_response         if true, render as a response annotation (no reviewed control).
 @param root_annotation_id  root annotation id for response/reply action targeting.
 @param show_reply_action   if true, show a Reply action.
 @return html string for one annotation review card row
--->
<cffunction name="renderAnnotationReviewRow" returntype="string" access="public">
	<cfargument name="annotation_id"      type="string" required="yes">
	<cfargument name="annotation_display" type="string" required="yes">
	<cfargument name="cf_username"        type="string" required="yes">
	<cfargument name="email"              type="string" required="no" default="">
	<cfargument name="annotate_date"      type="string" required="yes">
	<cfargument name="motivation"         type="string" required="no" default="">
	<cfargument name="reviewed_fg"        type="string" required="yes">
	<cfargument name="reviewer"           type="string" required="no" default="">
	<cfargument name="reviewer_comment"   type="string" required="no" default="">
	<cfargument name="mask_annotation_fg" type="string" required="no" default="0">
	<cfargument name="is_response"        type="boolean" required="no" default="false">
	<cfargument name="root_annotation_id" type="string" required="no" default="">
	<cfargument name="show_reply_action"  type="boolean" required="no" default="false">

	<cfset showVisibility = isDefined("session.roles") AND listfindnocase(session.roles, "manage_collection")>
	<cfset showMaskedBody = (val(arguments.mask_annotation_fg) EQ 1) AND NOT (isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user"))>
	<cfif len(arguments.root_annotation_id) EQ 0>
		<cfset rootAnnotationId = arguments.annotation_id>
	<cfelse>
		<cfset rootAnnotationId = arguments.root_annotation_id>
	</cfif>

	<cfsavecontent variable="rowHTML">
		<cfoutput>
		<div class="card-body bg-light border-bottom py-2">
			<div class="form-row mx-0 col-12 px-0">
				<div class="col-12 col-md-4 pt-2 px-1">
					<span class="data-entry-label font-weight-bold small">
						<cfif arguments.is_response>
							Response
						</cfif>
						Annotation:
						<span class="text-muted small">(#variables.annotation_id#)</span>
					</span>
					<cfif showMaskedBody>
						<div class="px-1 small font-italic text-muted">[Masked]</div>
					<cfelse>
						<!--- annotation_display is trusted text from annotation_textualbody.body_value or annotations.annotation. --->
						<div class="px-1 small">#arguments.annotation_display#</div>
					</cfif>
				</div>
				<div class="col-12 col-md-3 pt-2 px-1">
					<span class="data-entry-label font-weight-bold small">Annotator:</span>
					<div class="px-1 small">
						<strong>#encodeForHTML(arguments.cf_username)#</strong>
						(#encodeForHTML(arguments.email)#)
						on #dateformat(arguments.annotate_date, "yyyy-mm-dd")#
					</div>
				</div>
				<div class="col-12 col-md-1 pt-2 px-1">
					<span class="data-entry-label font-weight-bold small">Motivation:</span>
					<div class="px-1 small">#encodeForHTML(arguments.motivation)#</div>
				</div>
				<cfif NOT arguments.is_response>
					<div class="col-12 col-md-1 pt-2 px-1">
						<span class="data-entry-label font-weight-bold small d-block">Reviewed?</span>
						<span class="px-1 small"><cfif val(arguments.reviewed_fg) EQ 1>Yes<cfelse>No</cfif></span>
					</div>
				</cfif>
				<cfif showVisibility>
					<div class="col-12 col-md-1 pt-2 px-1">
						<label for="mask_annotation_fg_#arguments.annotation_id#" class="data-entry-label font-weight-bold small mb-0">Visibility:</label>
						<select id="mask_annotation_fg_#arguments.annotation_id#" class="data-entry-select col-12">
							<cfif val(arguments.mask_annotation_fg) EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="0" #selected#>Public</option>
							<cfif val(arguments.mask_annotation_fg) EQ 1><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="1" #selected#>Hidden</option>
						</select>
						<output id="mask_result_#arguments.annotation_id#" aria-live="polite" class="small d-block"></output>
					</div>
				</cfif>
				<div class="col-12 col-md-2 pt-2 px-1">
					<cfif NOT arguments.is_response AND arguments.show_reply_action>
						<button type="button" class="btn btn-xs btn-primary mb-1 open-reply-annotation-dialog" data-root-annotation-id="#encodeForHTMLAttribute(rootAnnotationId)#">Reply</button>
					</cfif>
					<button type="button" class="btn btn-xs btn-secondary mb-1 open-edit-annotation-dialog" data-edit-annotation-id="#encodeForHTMLAttribute(arguments.annotation_id)#">Edit</button>
					<cfif NOT arguments.is_response>
						<a href="/annotations/showAnnotation.cfm?annotation_id=#encodeForHTMLAttribute(arguments.annotation_id)#" class="btn btn-xs btn-outline-secondary mb-1" title="View full conversation">View</a>
					</cfif>
				</div>
			</div>
			<cfif showVisibility>
				<script>
					$(document).ready(function() {
						$("##mask_annotation_fg_#arguments.annotation_id#").off("change.annotationmask").on("change.annotationmask", function() {
							setAnnotationMask(#arguments.annotation_id#, this.value, "mask_result_#arguments.annotation_id#");
						});
					});
				</script>
			</cfif>
		</div>
		</cfoutput>
	</cfsavecontent>

	<cfreturn trim(rowHTML)>
</cffunction>

<!--- Return HTML for a dialog to edit an existing annotation.
 Provides a pre-filled edit form, optional root-annotation controls for response annotations,
 a context view of the root annotation and its responses, and a collapsible add-annotation form.
 @param annotation_id the numeric primary key of the annotation to edit.
 @param dialogId the html id value for the dialog container; used to scope form field ids.
 @return HTML string for the edit annotation dialog.
--->
<cffunction name="getEditAnnotationDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="annotation_id" type="numeric" required="yes">
	<cfargument name="dialogId" type="string" required="yes">

	<cfsavecontent variable="editDialogHtml">
		<cftry>
			<cfoutput>
				<cfset canManage = isdefined("session.roles") AND listfindnocase(session.roles, "manage_collection")>
				<cfset canAnnotate = false>
				<cfif isDefined("session.username") AND len(session.username) GT 0>
					<cfquery name="hasEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
						SELECT email FROM cf_user_data, cf_users
						WHERE cf_user_data.user_id = cf_users.user_id
						AND cf_users.username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<cfif hasEmail.recordcount GT 0 AND len(hasEmail.email) GT 0>
						<cfset canAnnotate = true>
					</cfif>
				</cfif>
				<cfset dq = rereplace(dialogId, "[^A-Za-z0-9_]", "", "all")>
				<cfset editAnnFieldId       = "edit_annotation_"       & dq>
				<cfset editAnnLengthId      = "length_edit_annotation_" & dq>
				<cfset editMotivationFieldId = "edit_motivation_"       & dq>
				<cfset editMaskFieldId      = "edit_mask_fg_"           & dq>
				<cfset editRootReviewedFieldId = "edit_root_reviewed_fg_" & dq>
				<cfset editRootMaskFieldId  = "edit_root_mask_fg_"      & dq>
				<cfset editResultDivId      = "editAnnotationResultDiv_" & dq>
				<cfset addFormDivId         = "addAnnotationFormDiv_"   & dq>
				<cfset addAnnFieldId        = "add_annotation_"         & dq>
				<cfset addAnnLengthId       = "length_add_annotation_"  & dq>
				<cfset addMotivationFieldId = "add_motivation_"         & dq>
				<cfset addMaskFieldId       = "add_mask_fg_"            & dq>
				<cfset addResultDivId       = "addAnnotationResultDiv_" & dq>

				<!--- Look up the annotation to edit --->
				<cfquery name="editAnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
					SELECT
						a.annotation_id,
						a.cf_username,
						a.annotate_date,
						a.motivation,
						a.reviewed_fg,
						a.mask_annotation_fg,
						a.target_table,
						a.target_primary_key,
						atb.body_value,
						annotator.first_name annotator_first_name,
						annotator.last_name annotator_last_name,
						annotator.email annotator_email
					FROM annotations a
					LEFT OUTER JOIN (
						SELECT annotation_id, body_value,
							row_number() over (partition by annotation_id order by created_date) rn
						FROM annotation_textualbody
					) atb ON a.annotation_id = atb.annotation_id AND atb.rn = 1
					LEFT OUTER JOIN cf_users ON a.cf_username = cf_users.username
					LEFT OUTER JOIN cf_user_data annotator ON cf_users.user_id = annotator.user_id
					WHERE a.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#annotation_id#">
				</cfquery>
				<cfif editAnn.recordcount EQ 0>
					<p class="text-danger px-2">Annotation not found.</p>
					<cfabort>
				</cfif>

				<!--- Determine if this is a response annotation and find the root --->
				<cfset isResponseAnnotation = (len(editAnn.target_table) GT 0 AND UCASE(editAnn.target_table) EQ "ANNOTATIONS")>
				<cfset rootAnnotationId = annotation_id>
				<cfset rootAnnotationBody = "">
				<cfif isResponseAnnotation>
					<cfquery name="annRoot" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT annotation_id FROM (
							SELECT annotation_id, LEVEL hierarchy_level
							FROM annotations
							START WITH annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#annotation_id#">
							CONNECT BY PRIOR target_primary_key = annotation_id AND PRIOR target_table = 'ANNOTATIONS'
							ORDER BY LEVEL DESC
						) WHERE ROWNUM = 1
					</cfquery>
					<cfif annRoot.recordcount EQ 1>
						<cfset rootAnnotationId = annRoot.annotation_id>
					<cfelse>
						<cfset rootAnnotationId = editAnn.target_primary_key>
					</cfif>
					<cfquery name="rootAnnQ" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT atb.body_value
						FROM annotations a
						LEFT OUTER JOIN (
							SELECT annotation_id, body_value,
								row_number() over (partition by annotation_id order by created_date) rn
							FROM annotation_textualbody
						) atb ON a.annotation_id = atb.annotation_id AND atb.rn = 1
						WHERE a.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rootAnnotationId#">
					</cfquery>
					<cfif rootAnnQ.recordcount EQ 1 AND len(rootAnnQ.body_value) GT 0>
						<cfset rootAnnotationBody = rootAnnQ.body_value>
					</cfif>
				</cfif>

				<!--- Load context annotations: root and its children --->
				<cfquery name="contextAnns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					SELECT annotations.ANNOTATION_ID,
						annotations.ANNOTATE_DATE,
						annotations.CF_USERNAME,
						annotations.ANNOTATION,
						annotations.REVIEWED_FG,
						annotations.REVIEWER_COMMENT,
						annotations.TARGET_TABLE,
						annotations.TARGET_PRIMARY_KEY,
						annotations.motivation,
						revname.agent_name reviewer_name,
						annotator.first_name annotator_first_name,
						annotator.last_name annotator_last_name,
						annotator.email annotator_email,
						annotations.MASK_ANNOTATION_FG,
						atb.body_value
					FROM annotations
					LEFT OUTER JOIN agent rev ON annotations.reviewer_agent_id = rev.agent_id
					LEFT OUTER JOIN agent_name revname ON rev.PREFERRED_AGENT_NAME_ID = revname.agent_name_id
					LEFT OUTER JOIN cf_users ON annotations.cf_username = cf_users.username
					LEFT OUTER JOIN cf_user_data annotator ON cf_users.user_id = annotator.user_id
					LEFT OUTER JOIN (
						SELECT annotation_id, body_value,
							row_number() over (partition by annotation_id order by created_date) rn
						FROM annotation_textualbody
					) atb ON annotations.annotation_id = atb.annotation_id AND atb.rn = 1
					WHERE annotations.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rootAnnotationId#">
					OR (
						UPPER(target_table) IN ('ANNOTATION','ANNOTATIONS')
						AND target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rootAnnotationId#">
					)
					ORDER BY annotations.annotate_date
				</cfquery>

				<cfif canAnnotate OR canManage>
					<cfquery name="ctmotivation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
						SELECT motivation, description FROM ctmotivation ORDER BY motivation
					</cfquery>
				</cfif>

				<!--- Look up the target context of the root annotation for display in the context section --->
				<cfset rootTargetSummary = "">
				<cfquery name="rootAnnTarget" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
					SELECT target_table, target_primary_key
					FROM annotations
					WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rootAnnotationId#">
				</cfquery>
				<cfif rootAnnTarget.recordcount GT 0 AND len(trim(rootAnnTarget.target_table)) GT 0
						AND UCASE(trim(rootAnnTarget.target_table)) NEQ 'ANNOTATION'
						AND UCASE(trim(rootAnnTarget.target_table)) NEQ 'ANNOTATIONS'>
					<cfset rtTable = UCASE(trim(rootAnnTarget.target_table))>
					<cfset rtKey = rootAnnTarget.target_primary_key>
					<cfif rtTable EQ "COLLECTION_OBJECT">
						<cfquery name="rtData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
							SELECT collection.collection, collection.collection_cde, cat_num,
								mczbase.get_scientific_name_auths(cataloged_item.collection_object_id) display_name
							FROM cataloged_item
							JOIN collection ON cataloged_item.collection_id = collection.collection_id
							WHERE cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rtKey#">
						</cfquery>
						<cfif rtData.recordcount GT 0>
							<cfset rootTargetSummary = "Cataloged Item <strong><a href='/guid/MCZ:#rtData.collection_cde#:#rtData.cat_num#' target='_blank'>MCZ:#rtData.collection_cde#:#rtData.cat_num#</a></strong> #rtData.display_name#">
						</cfif>
					<cfelseif rtTable EQ "TAXON_NAME">
						<cfquery name="rtData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
							SELECT display_name, author_text FROM taxonomy
							WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rtKey#">
						</cfquery>
						<cfif rtData.recordcount GT 0>
							<cfset rootTargetSummary = "Taxon <strong>#rtData.display_name# <span class='sm-caps'>#rtData.author_text#</span></strong>">
						</cfif>
					<cfelseif rtTable EQ "PROJECT">
						<cfquery name="rtData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
							SELECT project_name FROM project
							WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rtKey#">
						</cfquery>
						<cfif rtData.recordcount GT 0>
							<cfset rootTargetSummary = "Project <strong>#rtData.project_name#</strong>">
						</cfif>
					<cfelseif rtTable EQ "PUBLICATION">
						<cfquery name="rtData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
							SELECT formatted_publication FROM formatted_publication
							WHERE format_style = 'long'
							AND publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rtKey#">
						</cfquery>
						<cfif rtData.recordcount GT 0>
							<cfset rootTargetSummary = "Publication <strong>#rtData.formatted_publication#</strong>">
						</cfif>
					</cfif>
				</cfif>

				<cfset annotationBodyText = editAnn.body_value>
				<cfset rootBodyPreviewLength = 100>

				<section class="container-fluid">
					<div class="row">
						<div class="col-12 px-0 px-md-3">
							<h2 class="h3 my-1 px-1" tabindex="0">
								Edit Annotation <strong>#annotation_id#</strong>
								<cfif isResponseAnnotation>
									<span class="small d-block mt-1">
										Reply to root annotation <strong>#rootAnnotationId#</strong>
										<cfif len(rootAnnotationBody) GT 0>
											: #encodeForHTML(left(rootAnnotationBody, rootBodyPreviewLength))#
											<cfif len(rootAnnotationBody) GT rootBodyPreviewLength>&##8230;</cfif>
										</cfif>
									</span>
								</cfif>
							</h2>
							<cfif canManage>
							<div class="col-12 px-0 add-form">
								<div class="add-form-header px-2 pb-1">
									<h3 class="h4 my-0 px-1 py-1" tabindex="0">Edit Annotation</h3>
								</div>
								<div class="row col-12 mx-0 mt-1 d-block">
									<form name="editAnnotationForm_#dq#" onSubmit="return false;" class="form-row">
										<div class="col-12 pb-1">
											<label for="#editAnnFieldId#" class="data-entry-label">Annotation Text (<span id="#editAnnLengthId#"></span>)</label>
											<textarea rows="2" id="#editAnnFieldId#"
													onkeyup="countCharsLeft('#editAnnFieldId#', 4000, '#editAnnLengthId#');"
													class="autogrow reqdClr form-control data-entry-textarea" required>#encodeForHTML(annotationBodyText)#</textarea>
											<script>
												$(document).ready(function() {
													$("###editAnnFieldId#").keyup(autogrow);
													$("###editAnnFieldId#").keyup();
												});
											</script>
										</div>
										<div class="col-12 col-md-4 pb-1">
											<label for="#editMotivationFieldId#" class="data-entry-label">Motivation</label>
											<select id="#editMotivationFieldId#" class="data-entry-select">
												<cfloop query="ctmotivation">
													<cfif motivation EQ editAnn.motivation><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
													<option value="#motivation#"#selected#>#motivation# (#description#)</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-3 pb-1">
											<label for="#editMaskFieldId#" class="data-entry-label">Visibility</label>
											<select id="#editMaskFieldId#" class="data-entry-select">
												<cfif val(editAnn.mask_annotation_fg) EQ 0><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
												<option value="0"#selected#>Public</option>
												<cfif val(editAnn.mask_annotation_fg) EQ 1><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
												<option value="1"#selected#>Hidden</option>
											</select>
										</div>
										<cfif isResponseAnnotation>
										<div class="col-12 col-md-3 pb-1">
											<label for="#editRootReviewedFieldId#" class="data-entry-label">Mark Root Reviewed?</label>
											<select id="#editRootReviewedFieldId#" class="data-entry-select">
												<option value="" selected="selected">No Change</option>
												<option value="0">No</option>
												<option value="1">Yes</option>
											</select>
										</div>
										<div class="col-12 col-md-3 pb-1">
											<label for="#editRootMaskFieldId#" class="data-entry-label">Root Visibility</label>
											<select id="#editRootMaskFieldId#" class="data-entry-select">
												<option value="" selected="selected">No Change</option>
												<option value="0">Public</option>
												<option value="1">Hidden</option>
											</select>
										</div>
										</cfif>
										<div class="col-12 pt-1">
											<input type="button"
												class="btn btn-xs btn-primary mt-1"
												value="Save Changes"
												onclick="saveAnnotationEdit(#annotation_id#, <cfif isResponseAnnotation>#rootAnnotationId#<cfelse>''</cfif>, '_#dq#', '#encodeForJavaScript(dialogId)#')">
											<output id="#editResultDivId#" class="ml-2" aria-live="polite"></output>
										</div>
									</form>
								</div>
							</div>
							</cfif>
							<div class="col-12 mx-0 px-0 mt-2">
								<div class="d-flex justify-content-between align-items-center mt-1 px-1">
									<h3 class="h4 mb-0">Annotation in Context</h3>
									<cfif canAnnotate>
										<button type="button" class="btn btn-xs btn-outline-secondary"
											onclick="var d=document.getElementById('#addFormDivId#'); d.style.display=(d.style.display==='none'?'block':'none'); this.textContent=(d.style.display==='none'?'Add New Annotation':'Hide Form');">
											Add New Annotation
										</button>
									</cfif>
								</div>
								<cfif len(rootTargetSummary) GT 0>
									<p class="px-1 mb-1 small">Target: #rootTargetSummary#</p>
								</cfif>
								<cfif canAnnotate>
								<div id="#addFormDivId#" style="display:none;" class="mt-1">
									<form name="addAnnotationForm_#dq#" onSubmit="return false;" class="form-row px-1">
										<input type="hidden" id="idtype_add_#dq#" value="annotation">
										<input type="hidden" id="idvalue_add_#dq#" value="#rootAnnotationId#">
										<div class="col-12 pb-1">
											<label for="#addAnnFieldId#" class="data-entry-label">Add Response (<span id="#addAnnLengthId#"></span>)</label>
											<textarea rows="2" id="#addAnnFieldId#"
													onkeyup="countCharsLeft('#addAnnFieldId#', 4000, '#addAnnLengthId#');"
													class="autogrow form-control data-entry-textarea"></textarea>
											<script>
												$(document).ready(function() {
													$("###addAnnFieldId#").keyup(autogrow);
												});
											</script>
										</div>
										<div class="col-12 col-md-4 pb-1">
											<label for="#addMotivationFieldId#" class="data-entry-label">Motivation</label>
											<select id="#addMotivationFieldId#" class="data-entry-select">
												<cfloop query="ctmotivation">
													<cfif motivation EQ "replying"><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
													<option value="#motivation#"#selected#>#motivation# (#description#)</option>
												</cfloop>
											</select>
										</div>
										<cfif isdefined("session.roles") AND listfindnocase(session.roles, "manage_collection")>
										<div class="col-12 col-md-3 pb-1">
											<label for="#addMaskFieldId#" class="data-entry-label">Response Visibility</label>
											<select id="#addMaskFieldId#" class="data-entry-select">
												<option value="0" selected="selected">Public</option>
												<option value="1">Hidden</option>
											</select>
										</div>
										</cfif>
										<div class="col-12 pt-1">
											<input type="button"
												class="btn btn-xs btn-primary mt-1"
												value="Save Response"
												onclick="saveReplyAnnotationFromEditDialog('idtype_add_#dq#', 'idvalue_add_#dq#', '#addAnnFieldId#', '#addMotivationFieldId#', '#addMaskFieldId#', '#addResultDivId#', function(){ closeAnnotationDialogById('#encodeForJavaScript(dialogId)#'); })">
											<output id="#addResultDivId#" class="ml-2" aria-live="polite"></output>
										</div>
									</form>
								</div>
								</cfif>
								<!--- Context: root annotation + its responses --->
								<cfset ctxChildAnno = getChildAnnotationsForRoots(rootAnnotationId)>
								<cfquery name="ctxRoot" dbtype="query">
									SELECT
										ANNOTATION_ID, ANNOTATE_DATE, CF_USERNAME, ANNOTATION,
										REVIEWED_FG, REVIEWER_COMMENT, TARGET_TABLE,
										motivation, reviewer_name, annotator_email,
										MASK_ANNOTATION_FG, body_value
									FROM contextAnns
									WHERE TARGET_TABLE IS NULL OR UPPER(TARGET_TABLE) NOT IN ('ANNOTATION','ANNOTATIONS')
									ORDER BY ANNOTATE_DATE
								</cfquery>
								<cfif ctxRoot.recordcount GT 0>
									<div class="card border-0 mt-1">
										<cfloop query="ctxRoot">
											<cfif len(ctxRoot.body_value) GT 0>
												<cfset ctxDisplay = ctxRoot.body_value>
											<cfelse>
												<cfset ctxDisplay = ctxRoot.ANNOTATION>
											</cfif>
											<cfset ctxRowHtml = renderAnnotationReviewRow(
												annotation_id=ctxRoot.annotation_id,
												annotation_display=ctxDisplay,
												cf_username=ctxRoot.CF_USERNAME,
												email=ctxRoot.annotator_email,
												annotate_date=ctxRoot.ANNOTATE_DATE,
												motivation=ctxRoot.motivation,
												reviewed_fg=ctxRoot.reviewed_fg,
												reviewer=ctxRoot.reviewer_name,
												reviewer_comment=ctxRoot.reviewer_comment,
												mask_annotation_fg=ctxRoot.mask_annotation_fg,
												is_response=false,
												root_annotation_id=ctxRoot.annotation_id,
												show_reply_action=false)>
											#ctxRowHtml#
											#renderAnnotationConversationSection(rootAnnotationId=ctxRoot.annotation_id, childAnnotations=ctxChildAnno)#
										</cfloop>
									</div>
								</cfif>
							</div>
						</div>
					</div>
				</section>
			</cfoutput>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError")><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)>
			<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">Feedback/Report Errors</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfsavecontent>
	<cfreturn editDialogHtml>
</cffunction>


<!--- Update the text body and motivation of an existing annotation.
 Requires manage_collection role.
 Optionally updates visibility of the annotation and reviewed/visibility of the root annotation (for response annotations).
 @param annotation_id the numeric primary key of the annotation to update.
 @param annotation the updated annotation body text.
 @param motivation the updated annotation motivation.
 @param mask_annotation_fg optional; 0 for public, 1 for hidden.
 @param root_annotation_id optional; root annotation id for a response annotation.
 @param root_reviewed_fg optional; 0 or 1 to set reviewed status on the root annotation.
 @param root_mask_annotation_fg optional; 0 or 1 to set visibility on the root annotation.
 @return json with status=updated or an http 500 error if the update fails.
--->
<cffunction name="updateAnnotationText" returntype="any" access="remote" returnformat="json">
	<cfargument name="annotation_id"      type="string" required="yes">
	<cfargument name="annotation"         type="string" required="yes">
	<cfargument name="motivation"         type="string" required="no" default="">
	<cfargument name="mask_annotation_fg" type="string" required="no" default="">
	<cfargument name="root_annotation_id" type="string" required="no" default="">
	<cfargument name="root_reviewed_fg"   type="string" required="no" default="">
	<cfargument name="root_mask_annotation_fg" type="string" required="no" default="">

	<cfif NOT (isdefined("session.roles") AND listfindnocase(session.roles, "manage_collection"))>
		<cfheader statusCode="403" statusText="The manage_collection role is required to edit annotations.">
		<cfabort>
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- Update annotation_textualbody body_value (first/earliest row) --->
			<cfquery name="updBody" datasource="uam_god">
				UPDATE annotation_textualbody
				SET body_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#urldecode(arguments.annotation)#">
				WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.annotation_id#">
				AND created_date = (
					SELECT MIN(created_date) FROM annotation_textualbody
					WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.annotation_id#">
				)
			</cfquery>
			<!--- Update motivation if provided --->
			<cfif len(trim(arguments.motivation)) GT 0>
				<cfset cleanMotivation = rereplace(arguments.motivation, "[^a-zA-Z]", "", "all")>
				<cfquery name="updMotivation" datasource="uam_god">
					UPDATE annotations
					SET motivation = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cleanMotivation#">
					WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.annotation_id#">
				</cfquery>
			</cfif>
			<!--- Update this annotation's visibility if provided --->
			<cfif len(trim(arguments.mask_annotation_fg)) GT 0 AND REFind("^[01]$", trim(arguments.mask_annotation_fg)) GT 0>
				<cfquery name="updMask" datasource="uam_god">
					UPDATE annotations
					SET mask_annotation_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(arguments.mask_annotation_fg)#">
					WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.annotation_id#">
				</cfquery>
			</cfif>
			<!--- Update root annotation if response --->
			<cfif len(trim(arguments.root_annotation_id)) GT 0 AND val(arguments.root_annotation_id) GT 0>
				<cfif len(trim(arguments.root_reviewed_fg)) GT 0 AND REFind("^[01]$", trim(arguments.root_reviewed_fg)) GT 0>
					<cfquery name="updRootReviewed" datasource="uam_god">
						UPDATE annotations
						SET reviewed_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(arguments.root_reviewed_fg)#">,
							reviewer_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">
						WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.root_annotation_id#">
					</cfquery>
				</cfif>
				<cfif len(trim(arguments.root_mask_annotation_fg)) GT 0 AND REFind("^[01]$", trim(arguments.root_mask_annotation_fg)) GT 0>
					<cfquery name="updRootMask" datasource="uam_god">
						UPDATE annotations
						SET mask_annotation_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(arguments.root_mask_annotation_fg)#">
						WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.root_annotation_id#">
					</cfquery>
				</cfif>
			</cfif>
			<cftransaction action="commit">
			<cfset row = StructNew()>
			<cfset row["status"] = "updated">
			<cfset data[1] = row>
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(data)>
</cffunction>


</cfcomponent>
