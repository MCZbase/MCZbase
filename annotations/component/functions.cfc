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

<!--- Determine whether current user can perform review/response workflow actions.
 @return boolean true when session user has manage_collection role.
--->
<cffunction name="userCanRespondToAnnotations" returntype="boolean" access="public">
	<cfset var canRespond = false>
	<cfif isDefined("session.roles") AND listfindnocase(session.roles, "manage_collection")>
		<cfset canRespond = true>
	</cfif>
	<cfreturn canRespond>
</cffunction>

<!--- Get an agent_id for a login username from agent_name(login).
 @param login_name the login username to resolve to an agent_id.
 @return numeric agent_id or 0 when no mapping exists.
--->
<cffunction name="getAgentIdForLoginName" returntype="numeric" access="public">
	<cfargument name="login_name" type="string" required="yes">
	<cfset var resolvedAgentId = 0>
	<cfset var agentLookup = QueryNew("")>
	<cfquery name="agentLookup" datasource="uam_god">
		SELECT MIN(an.agent_id) AS agent_id
		FROM agent_name an
		WHERE an.agent_name_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="login">
			AND an.agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.login_name)#">
	</cfquery>
	<cfif agentLookup.recordcount GT 0 AND val(agentLookup.agent_id) GT 0>
		<cfset resolvedAgentId = val(agentLookup.agent_id)>
	</cfif>
	<cfreturn resolvedAgentId>
</cffunction>

<!--- Require current user login to resolve to an agent_id for annotation edit/update actions.
 @return numeric non-zero agent_id for the current session user.
--->
<cffunction name="requireCurrentUserAnnotationEditorAgentId" returntype="numeric" access="public">
	<cfset var editorAgentId = 0>
	<cfif NOT isDefined("session.username") OR len(trim(session.username)) EQ 0>
		<cfheader statusCode="403" statusText="Editing annotations requires a logged-in user.">
		<cfabort>
	</cfif>
	<cfset editorAgentId = getAgentIdForLoginName(session.username)>
	<cfif editorAgentId LTE 0>
		<cfheader statusCode="403" statusText="Editing annotations requires your login name to be associated with an agent record.">
		<cfabort>
	</cfif>
	<cfreturn editorAgentId>
</cffunction>

<!--- Load controlled values for annotation workflow state.
 @return query of allowed state values from ctstate.
--->
<cffunction name="getAnnotationCtState" returntype="query" access="public">
	<cfset var ctstate = QueryNew("")>
	<cfquery name="ctstate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
		SELECT state
		FROM ctstate
		ORDER BY state
	</cfquery>
	<cfreturn ctstate>
</cffunction>

<!--- Load controlled values for annotation workflow resolution.
 @return query of allowed resolution values from ctresolution.
--->
<cffunction name="getAnnotationCtResolution" returntype="query" access="public">
	<cfset var ctresolution = QueryNew("")>
	<cfquery name="ctresolution" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
		SELECT resolution
		FROM ctresolution
		ORDER BY resolution
	</cfquery>
	<cfreturn ctresolution>
</cffunction>

<!--- Configured likely resolution suggestions by root annotation motivation.
 @return struct mapping motivation (lowercase) to array of likely resolution values.
--->
<cffunction name="getRootResolutionGuidanceConfig" returntype="struct" access="public">
	<cfset var guidanceConfig = StructNew("ordered")>
	<cfset guidanceConfig["commenting"] = ["NOTABUG"]>
	<cfset guidanceConfig["replying"] = ["NOTABUG"]>
	<cfset guidanceConfig["editing"] = ["FIXED","OBSOLETE","WONTFIX"]>
	<cfreturn guidanceConfig>
</cffunction>

<!--- Build guidance text for likely resolution values for a specific root motivation.
 @param rootMotivation motivation value on the root annotation.
 @return text such as "For motivations of commenting, NOTABUG is often appropriate." or empty string.
--->
<cffunction name="getRootResolutionGuidanceText" returntype="string" access="public">
	<cfargument name="rootMotivation" type="string" required="yes">
	<cfset var guidanceText = "">
	<cfset var normalizedMotivation = lcase(trim(arguments.rootMotivation))>
	<cfset var guidanceConfig = getRootResolutionGuidanceConfig()>
	<cfset var likelyResolutions = []>
	<cfset var likelyResolutionText = "">
	<cfset var i = 0>
	<cfif len(normalizedMotivation) EQ 0>
		<cfreturn guidanceText>
	</cfif>
	<cfif NOT structKeyExists(guidanceConfig, normalizedMotivation)>
		<cfreturn guidanceText>
	</cfif>
	<cfset likelyResolutions = guidanceConfig[normalizedMotivation]>
	<cfif arrayLen(likelyResolutions) EQ 1>
		<cfset likelyResolutionText = likelyResolutions[1]>
	<cfelseif arrayLen(likelyResolutions) GT 1>
		<cfloop from="1" to="#arrayLen(likelyResolutions)#" index="i">
			<cfif i EQ 1>
				<cfset likelyResolutionText = likelyResolutions[i]>
			<cfelseif i EQ arrayLen(likelyResolutions)>
				<cfset likelyResolutionText = likelyResolutionText & " or " & likelyResolutions[i]>
			<cfelse>
				<cfset likelyResolutionText = likelyResolutionText & ", " & likelyResolutions[i]>
			</cfif>
		</cfloop>
	</cfif>
	<cfif len(likelyResolutionText) GT 0>
		<cfset guidanceText = "For motivations of " & normalizedMotivation & ", " & likelyResolutionText & " is often appropriate.">
	</cfif>
	<cfreturn guidanceText>
</cffunction>

<!--- Given an entity and id to annotate, return the HTML for a dialog to view existing annotations and add a new annotation for the specified record. The dialog HTML is returned as a string to be placed into a jQuery UI dialog by the calling function.
  * @param target_type the entity to be annotated (e.g. collection_object, taxonomy, publication, permit, annotation)
  * @param target_id the surrogate numeric primary key value for the row in the table specified by target_type to be annotated.
  * @param dialogId the html id value for the dialog to contain the returned HTML; used to set the id attribute of the form within the dialog and for callback functions to close the dialog after saving an annotation.
  * @return HTML string for a dialog to view existing annotations and add a new annotation for the specified record.
--->
<cffunction name="getAnnotationDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="target_type" type="string" required="yes">
	<cfargument name="target_id" type="numeric" required="yes">
	<cfargument name="dialogId" type="string" required="yes">
	
	<cfset variables.target_type = ucase(arguments.target_type)>
	<cfsavecontent variable="dialogHtml">
		<cftry>
			<cfoutput>
				<cfquery name="hasEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
					SELECT email 
					FROM cf_user_data,cf_users
					WHERE cf_user_data.user_id = cf_users.user_id and
						cf_users.username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfif hasEmail.recordcount GT 0 AND len(hasEmail.email) GT 0>
					<cfset canAnnotate = true>
				<cfelse>
					<cfset canAnnotate = false>
				</cfif>
				<cfset manageIRI = "">
				<cfset canRespond = userCanRespondToAnnotations()>
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
				<cfset rootStateFieldId = "root_state" & dialogFieldQualifier>
				<cfset rootResolutionFieldId = "root_resolution" & dialogFieldQualifier>
				<cfset annotationResultDivId = "annotationResultDiv" & dialogFieldQualifier>
				<cfset rootAnnotationMotivation = "">
				<cfset rootResolutionGuidanceText = "">
				<cfset targetAnnotationId = "">
				<cfif canAnnotate>
					<cfquery name="ctmotivation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
						SELECT motivation, description
						FROM ctmotivation
						ORDER by motivation
					</cfquery>
				</cfif>
				<cfif canRespond>
					<cfset ctstate = getAnnotationCtState()>
					<cfset ctresolution = getAnnotationCtResolution()>
				</cfif>
				<cfswitch expression="#variables.target_type#">
					<cfcase value="COLLECTION_OBJECT">
						<cfset collection_object_id = target_id>
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
							SELECT 
								collection.collection,
								collection.collection_cde,
								cat_num,
								mczbase.get_scientific_name_auths(collection_object_id) display_name
							FROM 
								cataloged_item
								left join collection on cataloged_item.collection_id = collection.collection_id
							WHERE 
								cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						</cfquery>
						<cfloop query="d">
							<cfset summary="Cataloged Item <strong><a href='/guid/MCZ:#collection_cde#:#cat_num#' target='_blank'>MCZ:#collection#:#cat_num#</a></strong> #display_name#" ><!--- " --->
							<cfset manageIRI = "/annotations/Annotations.cfm?action=show&type=collection_object_id&collection=#d.collection#&collection_object_id=#collection_object_id#">
						</cfloop>
					</cfcase>
					<cfcase value="TAXONOMY">
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
							<cfset summary="Taxon <strong>#display_name# <span class='sm-caps'>#author_text#</span></strong>"><!--- " --->
						</cfloop>
						<cfset manageIRI = "/annotations/Annotations.cfm?action=show&type=taxon_name_id&taxon_name_id=#taxon_name_id#">
					</cfcase>
					<cfcase value="PROJECT">
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
							<cfset summary="Project <strong>#project_name#</strong>"><!--- " --->
						</cfloop>
						<cfset manageIRI = "/annotations/Annotations.cfm?action=show&type=project_id&project_id=#project_id#">
					</cfcase>
					<cfcase value="PUBLICATION">
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
							<!--- title may contain html markup, remove for this use --->
							<cfset cleaned_formatted_publication = reReplace(d.formatted_publication, "<[^>]+>", "", "all")><!--- " --->
							<cfset summary="Publication <strong>#cleaned_formatted_publication#</strong>"><!--- " --->
						</cfloop>
						<cfset manageIRI = "/annotations/Annotations.cfm?action=show&type=publication_id&publication_id=#publication_id#">
					</cfcase>
					<cfcase value="AGENT">
						<cfset agent_id = target_id>
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
							SELECT agent_name
							FROM agent_name
							WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
								AND agent_name_type = 'preferred'
						</cfquery>
						<cfif d.recordcount GT 0>
							<cfset summary = "Agent <strong><a href='/agents/Agent.cfm?agent_id=#agent_id#' target='_blank'>#encodeForHTML(d.agent_name)#</a></strong>"><!--- " --->
						<cfelse>
							<cfset summary = "Agent <strong>#agent_id#</strong>"><!--- " --->
						</cfif>
						<cfset manageIRI = "/annotations/Annotations.cfm?action=show&type=agent_id&agent_id=#agent_id#">
					</cfcase>
					<cfcase value="ANNOTATIONS">
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
						<cfset var targetBodyPreview = "">
						<cfif len(targetAnnotationBody) GT 0>
							<cfset targetBodyPreview = left(targetAnnotationBody, 60)>
							<cfif len(targetAnnotationBody) GT 60><cfset targetBodyPreview = targetBodyPreview & "..."></cfif>
						</cfif>
						<cfif len(targetBodyPreview) GT 0>
							<cfset summary = "Annotation: " & encodeForHTML(targetBodyPreview) & " (" & targetAnnotationId & ")">
						<cfelse>
							<cfset summary = "Annotation (" & targetAnnotationId & ")">
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
						<cfelse>
							<cfset responseRootAnnotationId = targetAnnotationId>
						</cfif>
						<cfset dialogTargetId = targetAnnotationId>
						<cfquery name="rootAnnotationMotivationForDialog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
							SELECT motivation
							FROM annotations
							WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#responseRootAnnotationId#">
						</cfquery>
						<cfif rootAnnotationMotivationForDialog.recordcount EQ 1>
							<cfset rootAnnotationMotivation = rootAnnotationMotivationForDialog.motivation>
						</cfif>
						<cfif responseRootAnnotationId NEQ targetAnnotationId>
							<cfif len(targetBodyPreview) GT 0>
								<cfset summary = "Response Annotation: " & encodeForHTML(targetBodyPreview) & " (" & targetAnnotationId & ")">
							<cfelse>
								<cfset summary = "Response Annotation (" & targetAnnotationId & ")">
							</cfif>
							<!--- Get full ancestor chain from target up to root for context display --->
							<cfquery name="ancestorChainForDialog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
								SELECT a.annotation_id,
									CASE
										WHEN LENGTH(NVL(atb.body_value, a.annotation)) <= 60
										THEN NVL(atb.body_value, a.annotation)
										ELSE SUBSTR(NVL(atb.body_value, a.annotation), 1, 60) || '...'
									END AS display_summary,
									LEVEL AS depth_from_target
								FROM annotations a
								LEFT OUTER JOIN (
									SELECT annotation_id, body_value,
										ROW_NUMBER() OVER (PARTITION BY annotation_id ORDER BY created_date) rn
									FROM annotation_textualbody
								) atb ON a.annotation_id = atb.annotation_id AND atb.rn = 1
								START WITH a.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#targetAnnotationId#">
								CONNECT BY a.annotation_id = PRIOR a.target_primary_key AND PRIOR a.target_table = 'ANNOTATIONS'
								ORDER BY depth_from_target DESC
							</cfquery>
							<cfset var chainHtml = "">
							<cfset var chainAnnId = "">
							<cfset var chainSummary = "">
							<cfset var chainLabel = "">
							<cfloop query="ancestorChainForDialog">
								<cfset chainAnnId = ancestorChainForDialog.annotation_id>
								<cfset chainSummary = ancestorChainForDialog.display_summary>
								<cfif val(chainAnnId) EQ val(responseRootAnnotationId)>
									<cfset chainLabel = "Root annotation">
								<cfelseif val(chainAnnId) EQ val(targetAnnotationId)>
									<!--- immediate parent is already shown as the primary summary heading --->
									<cfset chainLabel = "">
								<cfelse>
									<cfset chainLabel = "↳ Reply">
								</cfif>
								<cfif len(chainLabel) GT 0>
									<cfset chainHtml = chainHtml & '<span class="small d-block mt-1">#encodeForHTML(chainLabel)#: #encodeForHTML(chainSummary)# (#chainAnnId#)</span>'><!--- ' --->
								</cfif>
							</cfloop>
							<cfif len(chainHtml) GT 0>
								<cfset summary = summary & chainHtml>
							</cfif>
							<cfset summary = summary & '<span class="small d-block mt-1">&##8627; Replying to this annotation <strong>#targetAnnotationId#</strong></span>'><!--- ' --->
						</cfif>
					</cfcase>
					<cfdefaultcase>
						<!--- TODO: Support annotations on at least agents, media (with ROI), and other annotations --->
						<cfthrow message="Annotation on an unsupported target type.">
					</cfdefaultcase>
				</cfswitch>
				<cfif variables.target_type EQ "ANNOTATIONS">
					<cfset rootResolutionGuidanceText = getRootResolutionGuidanceText(rootAnnotationMotivation)>
				</cfif>
				<!--- Single shared query for all target types; WHERE clause varies by target_type using cfif, not by SQL variable. --->
				<cfquery name="prevAnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					SELECT annotations.ANNOTATION_ID ANNOTATION_ID,
						annotations.ANNOTATE_DATE ANNOTATE_DATE,
						annotations.CF_USERNAME CF_USERNAME,
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
					FROM annotations
						left outer join agent rev on annotations.reviewer_agent_id = rev.agent_id
						left outer join agent_name revname on rev.PREFERRED_AGENT_NAME_ID = revname.agent_NAME_ID
						left outer join cf_users on annotations.cf_username = cf_users.username
						left outer join cf_user_data annotator on cf_users.user_id = annotator.user_id
						left outer join (
							select annotation_id, body_value,
								row_number() over (partition by annotation_id order by created_date) rn
							from annotation_textualbody
						) atb on annotations.annotation_id = atb.annotation_id and atb.rn = 1
					WHERE
					<cfif variables.target_type EQ "COLLECTION_OBJECT">
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					<cfelseif variables.target_type EQ "TAXONOMY">
						taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
					<cfelseif variables.target_type EQ "PROJECT">
						project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
					<cfelseif variables.target_type EQ "PUBLICATION">
						publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
					<cfelseif variables.target_type EQ "AGENT">
						target_table = 'AGENT'
						AND target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
					<cfelseif variables.target_type EQ "ANNOTATIONS">
						annotations.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#responseRootAnnotationId#">
						OR (
							target_table = 'ANNOTATIONS'
							and target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#responseRootAnnotationId#">
						)
					<cfelse>
						1=0
					</cfif>
					ORDER BY annotations.STATE, annotate_date
				</cfquery>
				<section class="container-fluid">
					<div class="row">
						<div class="col-12 px-0 px-md-3">
							<h2 class="h3 my-1 px-1" tabindex="0">Annotations for #summary#</h2>
							<cfif canAnnotate AND (variables.target_type NEQ "ANNOTATIONS" OR canRespond)>
								<div class="col-12 px-0 add-form">
									<div class="add-form-header px-2 pb-1">
										<h3 class="h4 my-0 px-1 py-1" tabindex="0"><cfif variables.target_type EQ "ANNOTATIONS">Add Reply Annotation<cfelse>Add New Annotation</cfif></h3>
									</div>
									<div class="row col-12 mx-0 mt-1 d-block">
										<form name="annotate" onSubmit="return false;" class="form-row">
											<input type="hidden" name="action" value="insert">
											<input type="hidden" name="idtype" id="#idtypeFieldId#" value="#variables.target_type#">
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
														<cfif variables.target_type EQ "ANNOTATIONS">
															<cfif motivation EQ "replying"><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
														<cfelse>
															<cfif motivation EQ "commenting"><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
														</cfif>
														<option value="#motivation#"#selected#>#motivation# (#description#)</option>
													</cfloop>
												</select>
											</div>
											<cfif variables.target_type EQ "ANNOTATIONS">
												<div class="col-12 col-md-3 pb-1">
													<label for="#rootReviewedFieldId#" class="data-entry-label">Mark Root Reviewed?</label>
													<select id="#rootReviewedFieldId#" name="root_reviewed_fg" class="data-entry-select">
														<option value="" selected="selected">No Change</option>
														<option value="0">No</option>
														<option value="1">Yes</option>
													</select>
												</div>
												<cfif canRespond>
													<div class="col-12 col-md-3 pb-1">
														<label for="#rootStateFieldId#" class="data-entry-label">Root State</label>
														<select id="#rootStateFieldId#" name="root_state" class="data-entry-select">
															<option value="" selected="selected">No Change</option>
															<cfloop query="ctstate">
																<option value="#encodeForHTMLAttribute(state)#">#encodeForHTML(state)#</option>
															</cfloop>
														</select>
													</div>
													<div class="col-12 col-md-3 pb-1">
														<label for="#rootResolutionFieldId#" class="data-entry-label">Root Resolution</label>
														<select id="#rootResolutionFieldId#" name="root_resolution" class="data-entry-select">
															<option value="" selected="selected">No Change</option>
															<cfloop query="ctresolution">
																<option value="#encodeForHTMLAttribute(resolution)#">#encodeForHTML(resolution)#</option>
															</cfloop>
														</select>
														<cfif len(rootResolutionGuidanceText) GT 0>
															<span class="small text-muted d-block">#encodeForHTML(rootResolutionGuidanceText)#</span>
														</cfif>
													</div>
													<cfif len(rootResolutionGuidanceText) GT 0>
														<script>
															$(document).ready(function() {
																applyCommentingResolutionGuidance('#motivationFieldId#', '#rootResolutionFieldId#');
															});
														</script>
													</cfif>
												</cfif>
											</cfif>
											<cfif isdefined("session.roles") AND listfindnocase(session.roles,"manage_collection")>
												<cfif variables.target_type EQ "ANNOTATIONS"><cfset colvar="col-md-3"><cfelse><cfset colvar="col-md-6"></cfif>
												<div class="col-12 #colvar# pb-1">
													<label for="#maskFieldId#" class="data-entry-label">
														<cfif variables.target_type EQ "ANNOTATIONS">
															Response Visibility:
														<cfelse>
															Visibility:
														</cfif>
													</label>
													<select id="#maskFieldId#" name="mask_annotation_fg" class="data-entry-select">
														<option value="0" selected="selected">Public</option>
														<option value="1">Hidden</option>
													</select>
												</div>
												<cfif variables.target_type EQ "ANNOTATIONS">
													<div class="col-12 col-md-3 pb-1">
														<label for="#rootMaskFieldId#" class="data-entry-label">Root Visibility:</label>
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
								<cfif variables.target_type EQ "ANNOTATIONS">
									<p class="px-1 py-1 text-muted small">The manage_collection role is required to reply to annotations.</p>
								<cfelse>
									<p class="px-1 py-1 text-muted small">To add an annotation, you must be logged in with a registered email address.</p>
								</cfif>
							</cfif>
							<div id="annotations_on_record_#dialogFieldQualifier#" class="col-12 mx-0 px-0 mt-2" data-dialog-id="#encodeForHTMLAttribute(arguments.dialogId)#" data-target-type="#encodeForHTMLAttribute(variables.target_type)#" data-target-id="#encodeForHTMLAttribute(arguments.target_id)#">
								<cfif prevAnn.recordcount gt 0>
									<div class="d-flex justify-content-between align-items-center mt-1 px-1">
										<h2 class="h4 mb-0"><cfif variables.target_type EQ "ANNOTATIONS">Annotation in Context<cfelse>Annotations on this Record</cfif></h2>
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
										<cfset var dialogConversation = getAnnotationConversationsForRoots(valueList(rootDialogAnnotations.annotation_id))>
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
													state=state,
													resolution=resolution,
													reviewer=reviewer_name,
													reviewer_comment=reviewer_comment,
													mask_annotation_fg=mask_annotation_fg,
													is_response=false,
													root_annotation_id=annotation_id,
													show_reply_action=true,
													highlight_as_replying_to=(variables.target_type EQ "ANNOTATIONS" AND len(targetAnnotationId) GT 0 AND val(annotation_id) EQ val(targetAnnotationId)))>
												#dialogRootRowHtml#
												#renderAnnotationConversationReplies(rootAnnotationId=rootDialogAnnotations.annotation_id, conversationAnnotations=dialogConversation, root_mask_annotation_fg=mask_annotation_fg, replying_to_annotation_id=(variables.target_type EQ "ANNOTATIONS" ? targetAnnotationId : ""))#
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


<!--- function addAnnotation Given an entity and id to annotate and the text of an annotation, 
 * save the annotation of the data record.
 * @param target_type the entity to be annotated (e.g. COLLECTION_OBJECT, TAXONOMY, PUBLICATION, PERMIT, ANNOTATIONS)
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
	<cfset variables.target_type = ucase(arguments.target_type)>
	<!--- Normalize "ANNOTATION" (singular) to "ANNOTATIONS" for backwards compatibility --->
	<cfif variables.target_type EQ "ANNOTATION">
		<cfset variables.target_type = "ANNOTATIONS">
	</cfif>
	<cfset targetTableName = variables.target_type>

	<cfset annotatable = false>
	<cfset mailTo = "">
	<cfset rootAnnotationId = target_id>
	<cfset canRespond = userCanRespondToAnnotations()>
	<cfset cleanRootState = "">
	<cfset cleanRootResolution = "">
	<cfset setRootResolutionNull = false>
	<cftry>
		<cfswitch expression="#variables.target_type#">
			<cfcase value="COLLECTION_OBJECT">
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
			<cfcase value="TAXONOMY">
				<cfset annotatable = true>
				<cfquery name="annotated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 'Taxon:' || scientific_name || ' ' || author_text as annorecord
					FROM taxonomy
					WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfcase value="PUBLICATION">
				<cfset annotatable = true>
				<cfquery name="annotated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 'Publication:' || MCZBASE.getshortcitation(publication_id) as annorecord
					FROM publication
					WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfcase value="PROJECT">
				<cfset annotatable = true>
				<cfquery name="annotated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 'Project:' || project_name as annorecord
					FROM project
					WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfcase value="ANNOTATIONS">
				<cfif NOT userCanRespondToAnnotations()>
					<cfthrow message="Replying to annotations requires the manage_collection role.">
				</cfif>
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
			<cfcase value="AGENT">
				<cfset annotatable = true>
				<cfquery name="annotated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 'Agent:' || agent_name AS annorecord
					FROM agent_name
					WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
						AND agent_name_type = 'preferred'
				</cfquery>
				<cfif annotated.recordcount EQ 0>
					<cfthrow message="Agent to annotate not found.">
				</cfif>
			</cfcase>
			<cfdefaultcase>
				<cfthrow message="Only annotation of collection objects, projects, publications, taxa, agents, and annotations are supported at this time">
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
	<cfif variables.target_type EQ "ANNOTATIONS">
		<cfif len(trim(root_state)) GT 0 OR len(trim(root_resolution)) GT 0>
			<cfif NOT canRespond>
				<cfheader statusCode="403" statusText="Only users with response workflow permissions may set root annotation state or resolution.">
				<cfabort>
			</cfif>
		</cfif>
		<cfif len(trim(root_state)) GT 0>
			<cfquery name="validRootState" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
				SELECT state
				FROM ctstate
				WHERE UPPER(state) = UPPER(<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#trim(root_state)#'>)
			</cfquery>
			<cfif validRootState.recordcount EQ 1>
				<cfset cleanRootState = validRootState.state>
			</cfif>
		</cfif>
		<cfif trim(root_resolution) EQ "__NULL__">
			<cfset setRootResolutionNull = true>
		<cfelseif len(trim(root_resolution)) GT 0>
			<cfquery name="validRootResolution" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
				SELECT resolution
				FROM ctresolution
				WHERE UPPER(resolution) = UPPER(<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#trim(root_resolution)#'>)
			</cfquery>
			<cfif validRootResolution.recordcount EQ 1>
				<cfset cleanRootResolution = validRootResolution.resolution>
			</cfif>
		</cfif>
	</cfif>
	<cfif annotatable>
		<cftransaction>
			<cftry>
				<cfset annotatorAgentId = getAgentIdForLoginName(session.username)>
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
						motivation,
						annotator_agent_id,
						last_updated_by_agent_id
						<cfif setMaskFg>,mask_annotation_fg</cfif>
					) VALUES (
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#session.username#' >,
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='For #annotated.annorecord# #annotator.first_name# #annotator.last_name# #annotator.affiliation# #annotator.email# reported: #urldecode(annotation)#' >,
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#variables.target_type#' >,
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#target_id#' >,
						'New',
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#motivation#' >,
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#annotatorAgentId#' null="#NOT (val(annotatorAgentId) GT 0)#">,
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#annotatorAgentId#' null="#NOT (val(annotatorAgentId) GT 0)#">
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
						created_date,
						last_updated_by_agent_id
					) VALUES (
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#getAnnotationID.annotation_id#'>,
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#urldecode(annotation)#'>,
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='text/plain'>,
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' null="yes">,
						SYSDATE,
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#annotatorAgentId#' null="#NOT (val(annotatorAgentId) GT 0)#">
					)
				</cfquery>
				<cfif target_type EQ "ANNOTATIONS" AND (len(cleanRootState) GT 0 OR len(cleanRootResolution) GT 0 OR setRootResolutionNull)>
					<cfquery name="updRootAnnStateResolution" datasource="uam_god">
						UPDATE annotations
						SET
							<cfif len(cleanRootState) GT 0 AND len(cleanRootResolution) GT 0>
								state = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#cleanRootState#'>,
								resolution = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#cleanRootResolution#'>
							<cfelseif len(cleanRootState) GT 0 AND setRootResolutionNull>
								state = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#cleanRootState#'>,
								resolution = NULL
							<cfelseif len(cleanRootState) GT 0>
								state = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#cleanRootState#'>
							<cfelseif setRootResolutionNull>
								resolution = NULL
							<cfelse>
								resolution = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#cleanRootResolution#'>
							</cfif>,
							last_updated_by_agent_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#annotatorAgentId#' null="#NOT (val(annotatorAgentId) GT 0)#">
						WHERE annotation_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#rootAnnotationId#'>
					</cfquery>
				</cfif>
				<cfif target_type EQ "ANNOTATIONS" AND len(trim(root_reviewed_fg)) GT 0 AND REFind("^[01]$", trim(root_reviewed_fg)) GT 0>
					<cfquery name="updRootAnnReviewed" datasource="uam_god">
						UPDATE annotations
						SET
							reviewed_fg = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#trim(root_reviewed_fg)#'>,
							reviewer_agent_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#annotatorAgentId#' null="#NOT (val(annotatorAgentId) GT 0)#">,
							last_updated_by_agent_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#annotatorAgentId#' null="#NOT (val(annotatorAgentId) GT 0)#">
						WHERE annotation_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#rootAnnotationId#'>
					</cfquery>
				</cfif>
				<cfif target_type EQ "ANNOTATIONS"
					AND isdefined("session.roles")
					AND listfindnocase(session.roles,"manage_collection")
					AND len(trim(root_mask_annotation_fg)) GT 0
					AND REFind("^[01]$", trim(root_mask_annotation_fg)) GT 0>
					<cfquery name="updRootAnnMask" datasource="uam_god">
						UPDATE annotations
						SET
							mask_annotation_fg = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#trim(root_mask_annotation_fg)#'>,
							last_updated_by_agent_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#annotatorAgentId#' null="#NOT (val(annotatorAgentId) GT 0)#">
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
    			<a href="#Application.ServerRootUrl#/annotations/Annotations.cfm?action=show&type=#variables.target_type#&id=#target_id#">
    			#Application.ServerRootUrl#/annotations/Annotations.cfm?action=show&type=#variables.target_type#&id=#target_id#
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
		target_type = "COLLECTION_OBJECT",
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
	<cfset reviewerAgentId = requireCurrentUserAnnotationEditorAgentId()>
	<cftransaction>
		<cftry>
			<cfquery name="updateAnnotation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateAnnotation_result">
				UPDATE annotations
				SET
					reviewer_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#reviewerAgentId#">,
					reviewed_fg=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#reviewed_fg#">,
					reviewer_comment=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#reviewer_comment#">,
					last_updated_by_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#reviewerAgentId#">
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
			<cfset editorAgentId = requireCurrentUserAnnotationEditorAgentId()>
			<cfquery name="updateMask" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateMask_result">
				UPDATE annotations
				SET mask_annotation_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(mask_annotation_fg)#">,
					last_updated_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#editorAgentId#">
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


<!--- Render a short HTML block describing the annotator of a given annotation.
 Determines what information to show based on the current viewer's permissions:
 coldfusion_user role members and the annotator themselves see all available info;
 other identifiable logged-in users see agent name/link (or username only when no agent);
 unauthenticated or unidentifiable viewers receive [masked].
 @param annotation_id numeric annotation primary key.
 @return HTML string describing the annotator.
--->
<cffunction name="renderAnnotatorHtml" returntype="string" access="public">
	<cfargument name="annotation_id" type="numeric" required="yes">

	<cfset var annotatorHtml = "">
	<cfset var isLoggedIn = isDefined("session.username") AND len(trim(session.username)) GT 0>

	<!--- Not logged in: always mask --->
	<cfif NOT isLoggedIn>
		<cfreturn "<span class=""text-muted small"">[masked]</span>">
	</cfif>

	<cfset var oneOfUs = isDefined("session.roles") AND listfindnocase(session.roles, "coldfusion_user")>

	<!--- Look up annotation and annotator details in a single query --->
	<cfquery name="annAnnotator" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
		SELECT
			a.cf_username,
			a.annotator_agent_id,
			ud.first_name,
			ud.last_name,
			ud.email,
			pan.agent_name preferred_name,
			ag.agentguid,
			ag.agentguid_guid_type
		FROM annotations a
			LEFT OUTER JOIN cf_users cu ON a.cf_username = cu.username
			LEFT OUTER JOIN cf_user_data ud ON cu.user_id = ud.user_id
			LEFT OUTER JOIN agent ag ON a.annotator_agent_id = ag.agent_id
			LEFT OUTER JOIN agent_name pan ON ag.preferred_agent_name_id = pan.agent_name_id
		WHERE a.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.annotation_id#">
	</cfquery>

	<cfif annAnnotator.recordcount EQ 0>
		<cfreturn "<span class=""text-muted small"">[unknown]</span>">
	</cfif>

	<cfset var annotatorUsername = annAnnotator.cf_username>
	<cfset var annotatorAgentId = annAnnotator.annotator_agent_id>
	<cfset var isAnnotatorSelf = (annotatorUsername EQ session.username)>
	<cfset var showAll = (oneOfUs OR isAnnotatorSelf)>

	<!--- If not oneOfUs and not self, check that viewer is identifiable --->
	<cfif NOT showAll>
		<!--- Viewer is identifiable if they have a linked agent or both email and name --->
		<cfset var viewerIdentifiable = (isDefined("session.myAgentId") AND val(session.myAgentId) GT 0)>
		<cfif NOT viewerIdentifiable>
			<cfquery name="viewerProfile" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
				SELECT ud.email, ud.first_name, ud.last_name
				FROM cf_users cu
					LEFT OUTER JOIN cf_user_data ud ON cu.user_id = ud.user_id
				WHERE cu.username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfif viewerProfile.recordcount GT 0 AND len(trim(viewerProfile.email)) GT 0
					AND (len(trim(viewerProfile.first_name)) GT 0 OR len(trim(viewerProfile.last_name)) GT 0)>
				<cfset viewerIdentifiable = true>
			</cfif>
		</cfif>
		<cfif NOT viewerIdentifiable>
			<cfreturn "<span class=""text-muted small"">[masked]</span>">
		</cfif>
	</cfif>

	<!--- Build the annotator display HTML --->
	<cfsavecontent variable="annotatorHtml">
		<cfoutput>
		<cfif val(annotatorAgentId) GT 0>
			<!--- Annotator has an agent record: show preferred name with link to agent page --->
			<a href="/agents/Agent.cfm?agent_id=#encodeForHTMLAttribute(annotatorAgentId)#" target="_blank" title="#encodeForHTMLAttribute(annAnnotator.preferred_name)# (opens in new tab)">#encodeForHTML(annAnnotator.preferred_name)#</a>
			<cfif len(trim(annAnnotator.agentguid)) GT 0>
				<!--- Resolve guid to a link and show with icon if type is known --->
				<cfquery name="ctGuidType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
					SELECT resolver_regex, resolver_replacement
					FROM ctguid_type
					WHERE applies_to LIKE '%agent.agentguid%'
						AND guid_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#annAnnotator.agentguid_guid_type#">
				</cfquery>
				<cfif ctGuidType.recordcount GT 0 AND len(trim(ctGuidType.resolver_regex)) GT 0>
					<cfset guidLink = REReplace(annAnnotator.agentguid, ctGuidType.resolver_regex, ctGuidType.resolver_replacement)>
				<cfelse>
					<cfset guidLink = annAnnotator.agentguid>
				</cfif>
				<cfset guidIcon = "">
				<cfif annAnnotator.agentguid_guid_type EQ "ORCiD">
					<cfset guidIcon = "<img src=""/shared/images/ORCIDiD_icon.svg"" height=""15"" width=""15"" class=""mr-1 align-middle"" alt=""ORCID iD icon"">" ><!--- " --->
				<cfelse>
					<cfset guidIcon = "<img src=""/shared/images/linked_data.png"" height=""15"" width=""15"" class=""mr-1 align-middle"" alt=""Linked data icon"">" ><!--- " --->
				</cfif>
				<a href="#guidLink#" target="_blank" title="#encodeForHTMLAttribute(annAnnotator.agentguid_guid_type)# identifier (opens in new tab)">#guidIcon#</a>
			</cfif>
		<cfelse>
			<!--- Annotator has no linked agent record --->
			<cfif showAll>
				<strong>#encodeForHTML(annotatorUsername)#</strong>
				<cfif len(trim(annAnnotator.first_name)) GT 0 OR len(trim(annAnnotator.last_name)) GT 0>
					#encodeForHTML(trim(annAnnotator.first_name & " " & annAnnotator.last_name))#
				</cfif>
				<cfif len(trim(annAnnotator.email)) GT 0>
					#encodeForHTML(annAnnotator.email)#
				</cfif>
			<cfelse>
				#encodeForHTML(annotatorUsername)#
			</cfif>
		</cfif>
		</cfoutput>
	</cfsavecontent>

	<cfreturn trim(annotatorHtml)>
</cffunction>


<!--- getAnnotationHistoryDialogHtml - return HTML for dialog display of one annotation's change history.
 @param annotation_id numeric annotation primary key.
 @return HTML string containing ordered history rows from ANNOTATION_HISTORY for one annotation.
--->
<cffunction name="getAnnotationHistoryDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="annotation_id" type="numeric" required="yes">
	<cfset var historyDialogHtml = "">
	<cfset var annotationExists = QueryNew("")>
	<cfset var annotationHistory = QueryNew("")>
	<cfset var changedByDisplay = "">
	<cfset var changedByAgentId = 0>
	<cfset var queryError = "">
	<cfset var message = "">

	<cfsavecontent variable="historyDialogHtml">
		<cftry>
			<cfoutput>
				<cfquery name="annotationExists" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
					SELECT annotation_id
					FROM annotations
					WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.annotation_id#">
				</cfquery>
				<cfif annotationExists.recordcount EQ 0>
					<div class="alert alert-warning mb-2">
						Annotation #encodeForHTML(arguments.annotation_id)# was not found.
					</div>
					<cfabort>
				</cfif>

				<cfquery name="annotationHistory" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					SELECT
						TO_CHAR(h.changed_date, 'YYYY-MM-DD HH24:MI:SS') AS changed_date,
						h.changed_by_agent_id AS changed_by_agent_id,
						h.changed_by_username AS changed_by_username,
						pan.agent_name AS changed_by_agent_name,
						h.event_type AS event_type,
						h.changed_field AS changed_field,
						h.old_value AS old_value,
						h.new_value AS new_value
					FROM annotation_history h
						LEFT OUTER JOIN preferred_agent_name pan ON h.changed_by_agent_id = pan.agent_id
					WHERE h.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.annotation_id#">
					ORDER BY h.changed_date DESC, h.annotation_history_id DESC
				</cfquery>

				<div class="container-fluid px-0">
					<h2 class="h5 mb-2">History for Annotation #encodeForHTML(arguments.annotation_id)#</h2>
					<cfif annotationHistory.recordcount EQ 0>
						<p class="text-muted mb-0">No history records were found for this annotation.</p>
					<cfelse>
						<div class="table-responsive">
							<table class="table table-sm table-striped table-bordered mb-1" aria-label="Annotation history for annotation #encodeForHTMLAttribute(arguments.annotation_id)#">
								<thead class="thead-light">
									<tr>
										<th scope="col">Changed Date</th>
										<th scope="col">Changed By</th>
										<th scope="col">Event Type</th>
										<th scope="col">Changed Field</th>
										<th scope="col">Old Value</th>
										<th scope="col">New Value</th>
									</tr>
								</thead>
								<tbody>
									<cfloop query="annotationHistory">
										<cfset changedByAgentId = val(annotationHistory.changed_by_agent_id)>
										<cfset changedByDisplay = "">
										<cfif changedByAgentId GT 0>
											<cfif len(trim(annotationHistory.changed_by_agent_name)) GT 0>
												<cfset changedByDisplay = trim(annotationHistory.changed_by_agent_name)>
											<cfelse>
												<cfset changedByDisplay = "[agent #changedByAgentId#]">
											</cfif>
										<cfelseif len(trim(annotationHistory.changed_by_username)) GT 0>
											<cfset changedByDisplay = trim(annotationHistory.changed_by_username)>
										</cfif>
										<cfif len(changedByDisplay) EQ 0><cfset changedByDisplay = "[unknown]"></cfif>
										<tr>
											<td><cfif len(trim(annotationHistory.changed_date)) GT 0>#encodeForHTML(annotationHistory.changed_date)#<cfelse><span class="text-muted">[unknown]</span></cfif></td>
											<td>#encodeForHTML(changedByDisplay)#</td>
											<td><cfif len(trim(annotationHistory.event_type)) GT 0>#encodeForHTML(annotationHistory.event_type)#<cfelse><span class="text-muted">[unspecified]</span></cfif></td>
											<td><cfif len(trim(annotationHistory.changed_field)) GT 0>#encodeForHTML(annotationHistory.changed_field)#<cfelse><span class="text-muted">[unspecified]</span></cfif></td>
											<td><cfif len(trim(annotationHistory.old_value)) GT 0><span class="small">#encodeForHTML(annotationHistory.old_value)#</span><cfelse><span class="text-muted">[empty]</span></cfif></td>
											<td><cfif len(trim(annotationHistory.new_value)) GT 0><span class="small">#encodeForHTML(annotationHistory.new_value)#</span><cfelse><span class="text-muted">[empty]</span></cfif></td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
					</cfif>
				</div>
			</cfoutput>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError")><cfset queryError = cfcatch.queryError><cfelse><cfset queryError = ""></cfif>
			<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)>
			<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container-fluid px-0">
					<div class="alert alert-danger mb-0" role="alert">
						<p class="mb-1"><strong>Unable to load annotation history.</strong></p>
						<p class="mb-0">#message#</p>
					</div>
				</div>
			</cfoutput>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfsavecontent>

	<cfreturn trim(historyDialogHtml)>
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
			LEFT OUTER JOIN annotations root_annotation ON annotations.target_primary_key = root_annotation.annotation_id
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
			<cfif NOT listcontainsnocase(session.roles, "coldfusion_user")>
				AND (
					(annotations.mask_annotation_fg = 0 AND NVL(root_annotation.mask_annotation_fg, 0) = 0)
					OR annotations.cf_username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				)
			</cfif>
		ORDER BY
			annotations.target_primary_key,
			annotations.annotate_date
	</cfquery>
	<cfreturn childAnnotations>
</cffunction>


<!--- getAnnotationConversationsForRoots Retrieve full annotation conversations for one or more root annotations, including all descendants at any depth.
 Uses Oracle hierarchical CONNECT BY to walk from each root down through all reply annotations.
 Masked annotations and their descendants are excluded for users without the coldfusion_user role,
 except root nodes at LEVEL=1 which are always included so callers can handle root visibility.
 @param rootAnnotationIds comma-delimited list of annotation_id values for root annotations (target_table != 'ANNOTATIONS').
 @return query with columns: annotation_id, parent_annotation_id (NULL for roots), root_annotation_id, depth, display_summary, annotation_display, cf_username, email, annotate_date, motivation, reviewed_fg, state, resolution, reviewer, reviewer_comment, mask_annotation_fg.
--->
<cffunction name="getAnnotationConversationsForRoots" returntype="query" access="public">
	<cfargument name="rootAnnotationIds" type="string" required="yes">
	<cfset var conversationAnnotations = QueryNew("")>
	<cfif len(trim(arguments.rootAnnotationIds)) EQ 0>
		<cfreturn conversationAnnotations>
	</cfif>
	<cfquery name="conversationAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT
			a.annotation_id,
			CASE WHEN LEVEL = 1 THEN NULL ELSE a.target_primary_key END AS parent_annotation_id,
			CONNECT_BY_ROOT a.annotation_id AS root_annotation_id,
			LEVEL - 1 AS depth,
			NVL(atb.body_value, a.annotation) AS annotation_display,
			CASE
				WHEN LENGTH(NVL(atb.body_value, a.annotation)) <= 60
					THEN NVL(atb.body_value, a.annotation)
				ELSE SUBSTR(NVL(atb.body_value, a.annotation), 1, 60) || '...'
			END AS display_summary,
			a.cf_username,
			cud.email,
			a.annotate_date,
			a.motivation,
			a.reviewed_fg,
			a.state,
			a.resolution,
			pan.agent_name AS reviewer,
			a.reviewer_comment,
			a.mask_annotation_fg
		FROM annotations a
			LEFT JOIN cf_users cu ON a.cf_username = cu.username
			LEFT JOIN cf_user_data cud ON cu.user_id = cud.user_id
			LEFT JOIN preferred_agent_name pan ON a.reviewer_agent_id = pan.agent_id
			LEFT JOIN (
				SELECT annotation_id, body_value,
					ROW_NUMBER() OVER (PARTITION BY annotation_id ORDER BY created_date) rn
				FROM annotation_textualbody
			) atb ON a.annotation_id = atb.annotation_id AND atb.rn = 1
		<cfif NOT listcontainsnocase(session.roles, "coldfusion_user")>
			WHERE LEVEL = 1 OR a.mask_annotation_fg = 0 OR a.cf_username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfif>
		START WITH a.annotation_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.rootAnnotationIds#" list="yes">)
		CONNECT BY PRIOR a.annotation_id = a.target_primary_key
			AND a.target_table = 'ANNOTATIONS'
			<cfif NOT listcontainsnocase(session.roles, "coldfusion_user")>
				AND PRIOR a.mask_annotation_fg = 0
			</cfif>
		ORDER SIBLINGS BY a.annotate_date
	</cfquery>
	<cfreturn conversationAnnotations>
</cffunction>


<!--- getAnnotationConversationForRoot Retrieve the full annotation conversation for a single root annotation.
 Wraps getAnnotationConversationsForRoots for single-root use.
 @param rootAnnotationId annotation_id of the root annotation.
 @return query with conversation columns from getAnnotationConversationsForRoots.
--->
<cffunction name="getAnnotationConversationForRoot" returntype="query" access="public">
	<cfargument name="rootAnnotationId" type="numeric" required="yes">
	<cfreturn getAnnotationConversationsForRoots(arguments.rootAnnotationId)>
</cffunction>

<!--- getRootAnnotationsForAnnotationIds Return root annotation ids for one or more annotations.
 Uses hierarchical traversal from each provided annotation to the top-most ancestor in its conversation.
 @param annotationIds comma-delimited list of annotation_id values.
 @return query with columns annotation_id and root_annotation_id.
--->
<cffunction name="getRootAnnotationsForAnnotationIds" returntype="query" access="public">
	<cfargument name="annotationIds" type="string" required="yes">
	<cfset var rootAnnotations = QueryNew("annotation_id,root_annotation_id")>
	<cfif len(trim(arguments.annotationIds)) EQ 0>
		<cfreturn rootAnnotations>
	</cfif>
	<cfquery name="rootAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT annotation_id, root_annotation_id
		FROM (
			SELECT
				CONNECT_BY_ROOT a.annotation_id AS annotation_id,
				a.annotation_id AS root_annotation_id,
				ROW_NUMBER() OVER (
					PARTITION BY CONNECT_BY_ROOT a.annotation_id
					ORDER BY LEVEL DESC
				) AS rn
			FROM annotations a
			START WITH a.annotation_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.annotationIds#" list="yes">)
			CONNECT BY PRIOR a.target_primary_key = a.annotation_id
				AND PRIOR a.target_table = 'ANNOTATIONS'
		)
		WHERE rn = 1
	</cfquery>
	<cfreturn rootAnnotations>
</cffunction>


<!--- getDescendantCountsForRoots Return total descendant counts for a list of root annotation ids.
 Counts all descendants at any depth visible to the current user, not only direct children.
 @param rootAnnotationIds comma-delimited list of annotation_id values for root annotations.
 @return query with columns root_annotation_id and descendant_count.
--->
<cffunction name="getDescendantCountsForRoots" returntype="query" access="public">
	<cfargument name="rootAnnotationIds" type="string" required="yes">
	<cfset var descendantCounts = QueryNew("root_annotation_id,descendant_count")>
	<cfif len(trim(arguments.rootAnnotationIds)) EQ 0>
		<cfreturn descendantCounts>
	</cfif>
	<cfquery name="descendantCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT
			CONNECT_BY_ROOT annotation_id AS root_annotation_id,
			COUNT(*) - 1 AS descendant_count
		FROM annotations
		<cfif NOT listcontainsnocase(session.roles, "coldfusion_user")>
			WHERE LEVEL = 1
				OR (mask_annotation_fg = 0)
				OR cf_username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfif>
		START WITH annotation_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.rootAnnotationIds#" list="yes">)
		CONNECT BY PRIOR annotation_id = target_primary_key
			AND target_table = 'ANNOTATIONS'
			<cfif NOT listcontainsnocase(session.roles, "coldfusion_user")>
				AND PRIOR mask_annotation_fg = 0
			</cfif>
		GROUP BY CONNECT_BY_ROOT annotation_id
	</cfquery>
	<cfreturn descendantCounts>
</cffunction>


<!--- Render conversation section with existing child annotations indented with a left border.
 @param rootAnnotationId annotation.annotation_id for the root annotation.
 @param childAnnotations query from getChildAnnotationsForRoots().
 @param editing_annotation_id optional; annotation_id currently being edited; highlights that row.
 @param root_mask_annotation_fg optional; mask_annotation_fg value (0 or 1) of the root annotation.
        When 1, child edit controls are disabled because visibility is inherited from the hidden root.
 @return html snippet for conversation section.
--->
<cffunction name="renderAnnotationConversationSection" returntype="string" access="public">
	<cfargument name="rootAnnotationId" type="numeric" required="yes">
	<cfargument name="childAnnotations" type="query" required="yes">
	<cfargument name="editing_annotation_id" type="string" required="no" default="">
	<cfargument name="root_mask_annotation_fg" type="string" required="no" default="0">
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
						show_reply_action=false,
						highlight_as_editing=(len(arguments.editing_annotation_id) GT 0 AND val(rootChildren.annotation_id) EQ val(arguments.editing_annotation_id)),
						parent_mask_annotation_fg=arguments.root_mask_annotation_fg
					)>
					#childRowHTML#
				</cfloop>
			</div>
		</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn trim(sectionHtml)>
</cffunction>


<!--- renderAnnotationConversationReplies Render the full annotation conversation replies below a root annotation.
 Renders depth-1 replies with one level of indentation, depth-2 replies with two levels of indentation,
 and depth-3 or deeper replies in a flat chronological section with parent context labels.
 Reply and edit actions are available on all annotations for users with the manage_collection role.
 History is available on all annotations.
 @param rootAnnotationId annotation.annotation_id of the root annotation.
 @param conversationAnnotations query from getAnnotationConversationsForRoots or getAnnotationConversationForRoot.
 @param editing_annotation_id optional; annotation_id currently being edited; highlights that row.
 @param root_mask_annotation_fg optional; mask_annotation_fg value of the root annotation.
 @return html snippet for the full conversation replies below the root.
--->
<cffunction name="renderAnnotationConversationReplies" returntype="string" access="public">
	<cfargument name="rootAnnotationId" type="numeric" required="yes">
	<cfargument name="conversationAnnotations" type="query" required="yes">
	<cfargument name="editing_annotation_id" type="string" required="no" default="">
	<cfargument name="replying_to_annotation_id" type="string" required="no" default="">
	<cfargument name="highlight_annotation_ids" type="string" required="no" default="">
	<cfargument name="highlight_label" type="string" required="no" default="Highlighted">
	<cfargument name="root_mask_annotation_fg" type="string" required="no" default="0">
	<cfargument name="read_only" type="boolean" required="no" default="false">
	<cfset var sectionHtml = "">
	<cfset var canManage = (NOT arguments.read_only) AND isDefined("session.roles") AND listfindnocase(session.roles, "manage_collection")>
	<cfset var localConversation = arguments.conversationAnnotations>
	<cfset var allDescendants = QueryNew("")>
	<cfset var depth1Nodes = QueryNew("")>
	<cfset var depth2Children = QueryNew("")>
	<cfset var deepNodes = QueryNew("")>
	<cfset var descendantCount = 0>
	<cfset var rowHtml = "">
	<cfset var parentSummary = "">
	<cfset var currentParentId = 0>
	<cfset var depth1MaskFg = 0>
	<cfset var parentOf = {}>
	<cfset var nodeDepth = {}>
	<cfset var deepByDepth2 = {}>
	<cfset var walkId = 0>
	<cfset var walkLimit = 0>
	<cfset var d2key = "">
	<cfset var deepItem = {}>
	<cfset var parentSummaryOf = {}>
	<cfset var maskOf = {}>
	<cfset var precomputedParentMask = 0>
	<cfif arguments.conversationAnnotations.recordcount EQ 0>
		<cfreturn "">
	</cfif>
	<cfquery name="allDescendants" dbtype="query">
		SELECT annotation_id, parent_annotation_id, root_annotation_id, depth, display_summary,
			annotation_display, cf_username, email, annotate_date, motivation, reviewed_fg,
			reviewer, reviewer_comment, mask_annotation_fg
		FROM localConversation
		WHERE root_annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.rootAnnotationId#">
			AND depth > 0
		ORDER BY annotate_date
	</cfquery>
	<cfset descendantCount = allDescendants.recordcount>
	<cfif descendantCount EQ 0>
		<cfreturn "">
	</cfif>
	<cfquery name="depth1Nodes" dbtype="query">
		SELECT annotation_id, parent_annotation_id, depth, display_summary,
			annotation_display, cf_username, email, annotate_date, motivation, reviewed_fg,
			reviewer, reviewer_comment, mask_annotation_fg
		FROM allDescendants
		WHERE depth = 1
		ORDER BY annotate_date
	</cfquery>
	<cfquery name="deepNodes" dbtype="query">
		SELECT annotation_id, parent_annotation_id, depth, display_summary,
			annotation_display, cf_username, email, annotate_date, motivation, reviewed_fg,
			reviewer, reviewer_comment, mask_annotation_fg
		FROM allDescendants
		WHERE depth >= 3
		ORDER BY annotate_date
	</cfquery>
	<!--- Build parent/depth lookup maps for walking ancestor chains.
	      Also build a display-summary lookup to avoid N+1 queries when rendering deep replies. --->
	<cfloop query="allDescendants">
		<cfset parentOf[allDescendants.annotation_id] = allDescendants.parent_annotation_id>
		<cfset nodeDepth[allDescendants.annotation_id] = allDescendants.depth>
		<cfset maskOf[allDescendants.annotation_id] = allDescendants.mask_annotation_fg>
		<cfset parentSummaryOf[allDescendants.annotation_id] = encodeForHTML(allDescendants.display_summary) & " (" & allDescendants.annotation_id & ")">
	</cfloop>
	<!--- Group each deepNode under its nearest depth-2 ancestor so the deep replies
	      can be rendered directly below that depth-2 annotation.
	      walkLimit caps the ancestor walk at 20 levels, well beyond realistic conversation depth. --->
	<cfloop query="deepNodes">
		<cfset walkId = deepNodes.parent_annotation_id>
		<cfset walkLimit = 20>
		<cfloop condition="walkLimit GT 0 AND structKeyExists(nodeDepth, walkId) AND nodeDepth[walkId] GT 2">
			<cfif structKeyExists(parentOf, walkId)>
				<cfset walkId = parentOf[walkId]>
			<cfelse>
				<cfbreak>
			</cfif>
			<cfset walkLimit = walkLimit - 1>
		</cfloop>
		<cfset d2key = "d2_" & walkId>
		<cfif NOT structKeyExists(deepByDepth2, d2key)>
			<cfset deepByDepth2[d2key] = []>
		</cfif>
		<cfset precomputedParentMask = 0>
		<cfif isNumeric(deepNodes.parent_annotation_id) AND val(deepNodes.parent_annotation_id) GT 0
			AND structKeyExists(maskOf, deepNodes.parent_annotation_id)>
			<cfset precomputedParentMask = maskOf[deepNodes.parent_annotation_id]>
		</cfif>
		<cfset arrayAppend(deepByDepth2[d2key], {
			annotation_id = deepNodes.annotation_id,
			parent_annotation_id = deepNodes.parent_annotation_id,
			annotation_display = deepNodes.annotation_display,
			cf_username = deepNodes.cf_username,
			email = deepNodes.email,
			annotate_date = deepNodes.annotate_date,
			motivation = deepNodes.motivation,
			reviewed_fg = deepNodes.reviewed_fg,
			reviewer = deepNodes.reviewer,
			reviewer_comment = deepNodes.reviewer_comment,
			mask_annotation_fg = deepNodes.mask_annotation_fg,
			parent_mask_annotation_fg = precomputedParentMask,
			display_summary = deepNodes.display_summary
		})>
	</cfloop>
	<cfsavecontent variable="sectionHtml">
		<cfoutput>
		<cfif depth1Nodes.recordcount GT 0>
			<div class="ml-4 pl-0 border-left border-dark" data-reply-parent-id="#arguments.rootAnnotationId#">
				<cfloop query="depth1Nodes">
					<cfset rowHtml = renderAnnotationReviewRow(
						annotation_id=depth1Nodes.annotation_id,
						annotation_display=depth1Nodes.annotation_display,
						annotation_summary=depth1Nodes.display_summary,
						cf_username=depth1Nodes.cf_username,
						email=depth1Nodes.email,
						annotate_date=depth1Nodes.annotate_date,
						motivation=depth1Nodes.motivation,
						reviewed_fg=depth1Nodes.reviewed_fg,
						reviewer=depth1Nodes.reviewer,
						reviewer_comment=depth1Nodes.reviewer_comment,
						mask_annotation_fg=depth1Nodes.mask_annotation_fg,
						is_response=true,
						root_annotation_id=arguments.rootAnnotationId,
						show_reply_action=canManage,
						highlight_as_editing=(len(arguments.editing_annotation_id) GT 0 AND val(depth1Nodes.annotation_id) EQ val(arguments.editing_annotation_id)),
						highlight_as_replying_to=(len(arguments.replying_to_annotation_id) GT 0 AND val(depth1Nodes.annotation_id) EQ val(arguments.replying_to_annotation_id)),
						highlight_as_target=(len(arguments.highlight_annotation_ids) GT 0 AND listFind(arguments.highlight_annotation_ids, depth1Nodes.annotation_id)),
						highlight_label=arguments.highlight_label,
						parent_mask_annotation_fg=arguments.root_mask_annotation_fg,
						read_only=arguments.read_only
					)>
					#rowHtml#
					<cfset currentParentId = depth1Nodes.annotation_id>
					<cfset depth1MaskFg = depth1Nodes.mask_annotation_fg>
					<cfquery name="depth2Children" dbtype="query">
						SELECT annotation_id, parent_annotation_id, depth, display_summary,
							annotation_display, cf_username, email, annotate_date, motivation, reviewed_fg,
							reviewer, reviewer_comment, mask_annotation_fg
						FROM allDescendants
						WHERE depth = 2 AND parent_annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#currentParentId#">
						ORDER BY annotate_date
					</cfquery>
					<cfif depth2Children.recordcount GT 0>
						<div class="ml-4 pl-0 border-left border-secondary" data-reply-parent-id="#depth1Nodes.annotation_id#">
							<cfloop query="depth2Children">
								<cfset rowHtml = renderAnnotationReviewRow(
									annotation_id=depth2Children.annotation_id,
									annotation_display=depth2Children.annotation_display,
									annotation_summary=depth2Children.display_summary,
									cf_username=depth2Children.cf_username,
									email=depth2Children.email,
									annotate_date=depth2Children.annotate_date,
									motivation=depth2Children.motivation,
									reviewed_fg=depth2Children.reviewed_fg,
									reviewer=depth2Children.reviewer,
									reviewer_comment=depth2Children.reviewer_comment,
									mask_annotation_fg=depth2Children.mask_annotation_fg,
									is_response=true,
									root_annotation_id=arguments.rootAnnotationId,
									show_reply_action=canManage,
									highlight_as_editing=(len(arguments.editing_annotation_id) GT 0 AND val(depth2Children.annotation_id) EQ val(arguments.editing_annotation_id)),
									highlight_as_replying_to=(len(arguments.replying_to_annotation_id) GT 0 AND val(depth2Children.annotation_id) EQ val(arguments.replying_to_annotation_id)),
									highlight_as_target=(len(arguments.highlight_annotation_ids) GT 0 AND listFind(arguments.highlight_annotation_ids, depth2Children.annotation_id)),
									highlight_label=arguments.highlight_label,
									parent_mask_annotation_fg=depth1MaskFg,
									read_only=arguments.read_only
								)>
								#rowHtml#
								<cfset d2key = "d2_" & depth2Children.annotation_id>
								<cfif structKeyExists(deepByDepth2, d2key) AND arrayLen(deepByDepth2[d2key]) GT 0>
									<div class="ml-4 pl-0 border-left border-secondary" data-thread-deep="true">
										<cfloop array="#deepByDepth2[d2key]#" index="deepItem">
											<cfset parentSummary = "">
											<cfif isNumeric(deepItem.parent_annotation_id) AND val(deepItem.parent_annotation_id) GT 0
												AND structKeyExists(parentSummaryOf, deepItem.parent_annotation_id)>
												<cfset parentSummary = parentSummaryOf[deepItem.parent_annotation_id]>
											</cfif>
											<cfif len(parentSummary) GT 0>
												<div class="px-2 pt-1 pb-0 text-muted small" aria-label="Replying to annotation">
													&##8627; Replying to: #parentSummary#
												</div>
											</cfif>
											<cfset rowHtml = renderAnnotationReviewRow(
												annotation_id=deepItem.annotation_id,
												annotation_display=deepItem.annotation_display,
												annotation_summary=deepItem.display_summary,
												cf_username=deepItem.cf_username,
												email=deepItem.email,
												annotate_date=deepItem.annotate_date,
												motivation=deepItem.motivation,
												reviewed_fg=deepItem.reviewed_fg,
												reviewer=deepItem.reviewer,
												reviewer_comment=deepItem.reviewer_comment,
												mask_annotation_fg=deepItem.mask_annotation_fg,
												is_response=true,
												root_annotation_id=arguments.rootAnnotationId,
												show_reply_action=canManage,
												highlight_as_editing=(len(arguments.editing_annotation_id) GT 0 AND val(deepItem.annotation_id) EQ val(arguments.editing_annotation_id)),
												highlight_as_replying_to=(len(arguments.replying_to_annotation_id) GT 0 AND val(deepItem.annotation_id) EQ val(arguments.replying_to_annotation_id)),
												highlight_as_target=(len(arguments.highlight_annotation_ids) GT 0 AND listFind(arguments.highlight_annotation_ids, deepItem.annotation_id)),
												highlight_label=arguments.highlight_label,
												parent_mask_annotation_fg=deepItem.parent_mask_annotation_fg,
												read_only=arguments.read_only
											)>
											#rowHtml#
										</cfloop>
									</div>
								</cfif>
							</cfloop>
						</div>
					</cfif>
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
 @param state               optional workflow state value for root annotations.
 @param resolution          optional workflow resolution value for root annotations.
 @param reviewer            preferred name of the last reviewer, or empty string
 @param reviewer_comment    retained for backwards compatibility.
 @param mask_annotation_fg  0 or 1 annotation visibility flag
 @param is_response         if true, render as a response annotation (no reviewed control).
 @param root_annotation_id  root annotation id for response/reply action targeting.
 @param show_reply_action   if true, show a Reply action.
 @param highlight_as_editing if true, visually mark this row as the annotation currently being edited.
 @param parent_mask_annotation_fg optional; mask_annotation_fg of the parent (root) annotation.
        When 1 for a response annotation, edit controls are disabled because visibility is inherited from the hidden root.
 @return html string for one annotation review card row
--->
<cffunction name="renderAnnotationReviewRow" returntype="string" access="public">
	<cfargument name="annotation_id"       type="string" required="yes">
	<cfargument name="annotation_display"  type="string" required="yes">
	<cfargument name="annotation_summary"  type="string" required="no" default="">
	<cfargument name="cf_username"         type="string" required="yes">
	<cfargument name="email"               type="string" required="no" default="">
	<cfargument name="annotate_date"       type="string" required="yes">
	<cfargument name="motivation"          type="string" required="no" default="">
	<cfargument name="reviewed_fg"         type="string" required="yes">
	<cfargument name="state"               type="string" required="no" default="">
	<cfargument name="resolution"          type="string" required="no" default="">
	<cfargument name="reviewer"            type="string" required="no" default="">
	<cfargument name="reviewer_comment"    type="string" required="no" default="">
	<cfargument name="mask_annotation_fg"  type="string" required="no" default="0">
	<cfargument name="is_response"         type="boolean" required="no" default="false">
	<cfargument name="root_annotation_id"  type="string" required="no" default="">
	<cfargument name="show_reply_action"   type="boolean" required="no" default="false">
	<cfargument name="highlight_as_editing" type="boolean" required="no" default="false">
	<cfargument name="highlight_as_replying_to" type="boolean" required="no" default="false">
	<cfargument name="highlight_as_target" type="boolean" required="no" default="false">
	<cfargument name="highlight_label" type="string" required="no" default="Highlighted">
	<cfargument name="parent_mask_annotation_fg" type="string" required="no" default="0">
	<cfargument name="read_only"           type="boolean" required="no" default="false">

	<cfset var showVisibility = (NOT arguments.read_only) AND isDefined("session.roles") AND listfindnocase(session.roles, "manage_collection")>
	<cfset var showMaskedBody = (val(arguments.mask_annotation_fg) EQ 1) AND NOT (isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user"))>
	<cfset var parentMasked = arguments.is_response AND val(arguments.parent_mask_annotation_fg) EQ 1>
	<cfset var rootAnnotationId = "">
	<cfset var responseReadOnlyLayout = arguments.is_response AND arguments.read_only>
	<cfset var annotationBodyColClass = "col-12 col-md-4 pt-2 px-1">
	<cfset var annotatorColClass = "col-12 col-md-2 pt-2 px-1">
	<cfset var motivationColClass = "col-12 col-md-1 pt-2 px-1">
	<cfset var annotationLabelSummary = "">
	<cfset var summaryText = "">
	<cfset var maxSummaryLength = 60>
	<cfif responseReadOnlyLayout>
		<cfset annotationBodyColClass = "col-12 col-md-7 pt-2 px-1">
		<cfset annotatorColClass = "col-12 col-md-3 pt-2 px-1">
		<cfset motivationColClass = "col-12 col-md-2 pt-2 px-1">
	</cfif>
	<cfif arguments.is_response>
		<cfif len(trim(arguments.annotation_summary)) GT 0>
			<cfset summaryText = trim(arguments.annotation_summary)>
		<cfelse>
			<cfset summaryText = trim(arguments.annotation_display)>
		</cfif>
		<cfset summaryText = rereplace(summaryText, "\s+", " ", "all")>
		<cfif len(summaryText) GT maxSummaryLength>
			<cfset summaryText = left(summaryText, maxSummaryLength - 3) & "...">
		</cfif>
		<cfset annotationLabelSummary = encodeForHTML(summaryText)>
	</cfif>
	<cfif len(arguments.root_annotation_id) EQ 0>
		<cfset rootAnnotationId = arguments.annotation_id>
	<cfelse>
		<cfset rootAnnotationId = arguments.root_annotation_id>
	</cfif>

	<cfsavecontent variable="rowHTML">
		<cfoutput>
		<div class="card-body bg-light border-bottom py-2<cfif arguments.highlight_as_editing> border-left border-primary<cfelseif arguments.highlight_as_replying_to> border-left border-success</cfif>"><!--- " --->
			<cfif arguments.highlight_as_editing>
				<div class="badge badge-primary mb-1" style="font-size:0.8em;">&##9998; Editing</div>
			</cfif>
			<cfif arguments.highlight_as_replying_to>
				<div class="badge badge-success mb-1" style="font-size:0.8em;">&##8627; Replying to</div>
			</cfif>
			<div class="form-row mx-0 col-12 px-0">
				<div class="#annotationBodyColClass#">
					<span class="data-entry-label font-weight-bold small">
						<cfif arguments.is_response>
							Response Annotation:<cfif len(annotationLabelSummary) GT 0> #annotationLabelSummary#</cfif>
						<cfelse>
							Annotation:
						</cfif>
						<span class="text-muted small text-nowrap" style="display:inline;">(#encodeForHtml(arguments.annotation_id)#)</span>
						<cfif arguments.highlight_as_target>
							<span class="badge badge-light border text-muted ml-1 align-middle" style="font-size:0.7em;" aria-label="#encodeForHTMLAttribute(arguments.highlight_label)# annotation">#encodeForHTML(arguments.highlight_label)#</span>
						</cfif>
					</span>
					<cfif showMaskedBody>
						<div class="px-1 small font-italic text-muted">[Masked]</div>
					<cfelse>
						<!--- annotation_display is trusted text from annotation_textualbody.body_value or annotations.annotation. --->
						<div class="px-1 small">#arguments.annotation_display#</div>
					</cfif>
				</div>
				<div class="#annotatorColClass#">
					<span class="data-entry-label font-weight-bold small">Annotator:</span>
					<div class="px-1 small">
						#renderAnnotatorHtml(annotation_id=val(arguments.annotation_id))#
						on #dateformat(arguments.annotate_date, "yyyy-mm-dd")#
					</div>
				</div>
				<div class="#motivationColClass#">
					<span class="data-entry-label font-weight-bold small">Motivation:</span>
					<div class="px-1 small">#encodeForHTML(arguments.motivation)#</div>
				</div>
				<cfif NOT arguments.is_response>
					<div class="col-12 col-md-1 pt-2 px-1">
						<div class="px-1 small">
							<span class="font-weight-bold">State:</span>
							#encodeForHTML(arguments.state)#
						</div>
						<cfif len(trim(arguments.resolution)) GT 0>
							<div class="px-1 small">
								<span class="font-weight-bold">Resolution:</span>
								#encodeForHTML(arguments.resolution)#
							</div>
						</cfif>
					</div>
				</cfif>
				<cfif NOT arguments.is_response>
					<div class="col-12 col-md-1 pt-2 px-1">
						<span class="data-entry-label font-weight-bold small d-block">Reviewed?</span>
						<span class="px-1 small"><cfif val(arguments.reviewed_fg) EQ 1>Yes<cfelse>No</cfif></span>
					</div>
				</cfif>
				<cfif showVisibility>
					<div class="col-12 col-md-1 pt-2 px-1">
						<label for="mask_annotation_fg_#arguments.annotation_id#" class="data-entry-label font-weight-bold small mb-0">
							Visibility:
							<cfif parentMasked>
								<span id="inherited_note_#arguments.annotation_id#" class="small" aria-label="Visibility inherited from parent annotation">hidden</span>
							</cfif>
						</label>
						<cfif parentMasked>
							<select id="mask_annotation_fg_#arguments.annotation_id#" class="data-entry-select col-12" style="background-color: aliceblue;" disabled="disabled" aria-describedby="inherited_note_#arguments.annotation_id#">
						<cfelse>
							<select id="mask_annotation_fg_#arguments.annotation_id#" class="data-entry-select col-12">
						</cfif>
							<cfif val(arguments.mask_annotation_fg) EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="0" #selected#>Public</option>
							<cfif val(arguments.mask_annotation_fg) EQ 1><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="1" #selected#>Hidden</option>
						</select>
						<output id="mask_result_#arguments.annotation_id#" aria-live="polite" class="small d-block"></output>
					</div>
				</cfif>
				<cfif NOT arguments.read_only>
				<div class="col-12 col-md-2 pt-3 px-1">
					<cfif isdefined("session.username") AND len(#session.username#) GT 0>
						<cfif isDefined("session.roles") AND listfindnocase(session.roles, "manage_collection")>
							<cfif arguments.show_reply_action>
								<button type="button" class="btn btn-xs btn-primary mb-1 open-reply-annotation-dialog" data-target-annotation-id="#encodeForHTMLAttribute(arguments.annotation_id)#" data-root-annotation-id="#encodeForHTMLAttribute(rootAnnotationId)#">Reply</button>
							</cfif>
							<!--- TODO: Support users editing their own annotations even without manage_collection --->
							<cfif NOT arguments.highlight_as_editing>
								<button type="button" class="btn btn-xs btn-secondary mb-1 open-edit-annotation-dialog" data-edit-annotation-id="#encodeForHTMLAttribute(arguments.annotation_id)#" data-root-annotation-id="#encodeForHTMLAttribute(rootAnnotationId)#">Edit</button>
							</cfif>
						</cfif>
					</cfif>
					<button type="button" class="btn btn-xs btn-outline-secondary mb-1 open-annotation-history-dialog" data-history-annotation-id="#encodeForHTMLAttribute(arguments.annotation_id)#" aria-label="View history for annotation #encodeForHTMLAttribute(arguments.annotation_id)#">History</button>
					<cfif NOT arguments.is_response>
						<a href="/annotations/showAnnotation.cfm?annotation_id=#encodeForHTMLAttribute(arguments.annotation_id)#" class="btn btn-xs btn-outline-secondary mb-1" title="View full conversation" target="_blank">View</a>
					</cfif>
				</div>
				</cfif>
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

<!--- Render inner HTML for a root annotation block (root row + conversation section) for AJAX reload.
 Queries the root annotation by annotation_id and returns the combined row and conversation section HTML.
 This is intended to be called via AJAX to replace the contents of an annotation-block container after
 a dialog edit or add action so that changes are immediately visible on the calling page.
 @param root_annotation_id numeric annotation_id of the root annotation to render.
 @return html string combining renderAnnotationReviewRow and renderAnnotationConversationSection output.
--->
<cffunction name="renderAnnotationBlockHtml" access="remote" returntype="string">
	<cfargument name="root_annotation_id" type="numeric" required="yes">
	<cfset var blockHtml = "">
	<cftry>
		<cfquery name="rootAnno" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				annotations.annotation_id,
				NVL(atb.body_value, annotations.annotation) annotation_display,
				annotations.cf_username,
				cf_user_data.email,
				annotations.annotate_date,
				annotations.motivation,
				annotations.reviewed_fg,
				annotations.state,
				annotations.resolution,
				preferred_agent_name.agent_name reviewer,
				annotations.reviewer_comment,
				annotations.mask_annotation_fg
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
				annotations.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.root_annotation_id#">
				AND upper(annotations.target_table) != 'ANNOTATIONS'
		</cfquery>
		<cfif rootAnno.recordcount EQ 0>
			<cfreturn "">
		</cfif>
		<cfset var conversationAnnotations = getAnnotationConversationForRoot(arguments.root_annotation_id)>
		<cfset var rowHTML = renderAnnotationReviewRow(
			annotation_id=rootAnno.annotation_id,
			annotation_display=rootAnno.annotation_display,
			cf_username=rootAnno.cf_username,
			email=rootAnno.email,
			annotate_date=rootAnno.annotate_date,
			motivation=rootAnno.motivation,
			reviewed_fg=rootAnno.reviewed_fg,
			state=rootAnno.state,
			resolution=rootAnno.resolution,
			reviewer=rootAnno.reviewer,
			reviewer_comment=rootAnno.reviewer_comment,
			mask_annotation_fg=rootAnno.mask_annotation_fg,
			show_reply_action=true
		)>
		<cfset var convHTML = renderAnnotationConversationReplies(
			rootAnnotationId=rootAnno.annotation_id,
			conversationAnnotations=conversationAnnotations,
			root_mask_annotation_fg=rootAnno.mask_annotation_fg
		)>
		<cfsavecontent variable="blockHtml">
			<cfoutput>#rowHTML##convHTML#</cfoutput>
		</cfsavecontent>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError")><cfset var queryError = cfcatch.queryError><cfelse><cfset var queryError = ""></cfif>
			<cfset var message = trim("Error in renderAnnotationBlockHtml: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)>
			<cfheader statusCode="500" statusText="#message#">
			<cfreturn "">
		</cfcatch>
	</cftry>
	<cfreturn trim(blockHtml)>
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
				<cfset canRespond = userCanRespondToAnnotations()>
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
				<cfset editRootStateFieldId = "edit_root_state_"         & dq>
				<cfset editRootResolutionFieldId = "edit_root_resolution_" & dq>
				<cfset editResultDivId      = "editAnnotationResultDiv_" & dq>
				<cfset addFormDivId         = "addAnnotationFormDiv_"   & dq>
				<cfset addAnnFieldId        = "add_annotation_"         & dq>
				<cfset addAnnLengthId       = "length_add_annotation_"  & dq>
				<cfset addMotivationFieldId = "add_motivation_"         & dq>
				<cfset addMaskFieldId       = "add_mask_fg_"            & dq>
				<cfset addRootStateFieldId  = "add_root_state_"         & dq>
				<cfset addRootResolutionFieldId = "add_root_resolution_" & dq>
				<cfset addResultDivId       = "addAnnotationResultDiv_" & dq>
				<cfset rootResolutionGuidanceText = "">

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
				</cfif>
				<cfquery name="rootAnnQ" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT atb.body_value, a.state, a.resolution, a.motivation, a.mask_annotation_fg, a.reviewed_fg
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
				<cfif rootAnnQ.recordcount EQ 1>
					<cfset rootResolutionGuidanceText = getRootResolutionGuidanceText("" & rootAnnQ.motivation)>
				</cfif>

				<!--- For deep response annotations, get the ancestor chain to show context in the heading --->
				<cfset immediateParentId = "">
				<cfset immediateParentBody = "">
				<cfset ancestorChainHtml = "">
				<cfset var chainId = "">
				<cfset var chainDisplay = "">
				<cfif isResponseAnnotation>
					<cfset immediateParentId = editAnn.target_primary_key>
					<cfif val(immediateParentId) NEQ val(rootAnnotationId)>
						<!--- Depth >= 2: fetch full ancestor chain from annotation up to root --->
						<cfquery name="editAncestorChain" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
							SELECT a.annotation_id,
								CASE
									WHEN LENGTH(NVL(atb.body_value, a.annotation)) <= 80
									THEN NVL(atb.body_value, a.annotation)
									ELSE SUBSTR(NVL(atb.body_value, a.annotation), 1, 80) || '...'
								END AS display_summary,
								LEVEL AS depth_from_start
							FROM annotations a
								LEFT OUTER JOIN (
									SELECT annotation_id, body_value,
										ROW_NUMBER() OVER (PARTITION BY annotation_id ORDER BY created_date) rn
									FROM annotation_textualbody
								) atb ON a.annotation_id = atb.annotation_id AND atb.rn = 1
							START WITH a.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#annotation_id#">
							CONNECT BY a.annotation_id = PRIOR a.target_primary_key AND PRIOR a.target_table = 'ANNOTATIONS'
							ORDER BY depth_from_start DESC
						</cfquery>
						<cfloop query="editAncestorChain">
							<cfset chainId = editAncestorChain.annotation_id>
							<cfset chainDisplay = editAncestorChain.display_summary>
							<cfif val(chainId) NEQ val(annotation_id)>
								<!--- Include all ancestors except the annotation being edited (shown in dialog heading) --->
								<cfif val(chainId) EQ val(rootAnnotationId)>
									<cfset ancestorChainHtml = ancestorChainHtml & '<span class="small d-block mt-1">Root annotation <strong>#chainId#</strong>: #encodeForHTML(chainDisplay)#</span>'><!--- '--->	
								<cfelse>
									<cfset ancestorChainHtml = ancestorChainHtml & '<span class="small d-block mt-1">&##8627; Reply annotation <strong>#chainId#</strong>: #encodeForHTML(chainDisplay)#</span>'><!--- '--->
								</cfif>
								<cfif val(chainId) EQ val(immediateParentId)>
									<cfset immediateParentBody = editAncestorChain.display_summary>
								</cfif>
							</cfif>
						</cfloop>
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
						annotations.STATE,
						annotations.RESOLUTION,
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
						SELECT motivation, description 
						FROM ctmotivation 
						ORDER BY motivation
					</cfquery>
				</cfif>
				<cfif canRespond>
					<cfset ctstate = getAnnotationCtState()>
					<cfset ctresolution = getAnnotationCtResolution()>
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
							<cfset rootTargetSummary = "Cataloged Item <strong><a href='/guid/MCZ:#rtData.collection_cde#:#rtData.cat_num#' target='_blank'>MCZ:#rtData.collection_cde#:#rtData.cat_num#</a></strong> #rtData.display_name#"><!--- " --->
						</cfif>
					<cfelseif rtTable EQ "TAXONOMY">
						<cfquery name="rtData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
							SELECT display_name, author_text 
							FROM taxonomy
							WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rtKey#">
						</cfquery>
						<cfif rtData.recordcount GT 0>
							<cfset rootTargetSummary = "Taxon <strong>#rtData.display_name# <span class='sm-caps'>#rtData.author_text#</span></strong>"><!--- " --->
						</cfif>
					<cfelseif rtTable EQ "PROJECT">
						<cfquery name="rtData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
							SELECT project_name 
							FROM project
							WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rtKey#">
						</cfquery>
						<cfif rtData.recordcount GT 0>
							<cfset rootTargetSummary = "Project <strong>#rtData.project_name#</strong>"><!--- " --->
						</cfif>
					<cfelseif rtTable EQ "PUBLICATION">
						<cfquery name="rtData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
							SELECT formatted_publication 
							FROM formatted_publication
							WHERE format_style = 'long'
								AND publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rtKey#">
						</cfquery>
						<cfif rtData.recordcount GT 0>
							<!--- title may contain html markup, remove for this use  --->
							<cfset cleaned_formatted_publication = reReplace(rtData.formatted_publication, "<[^>]+>", "", "all")><!--- " --->
							<cfset rootTargetSummary = "Publication <strong>#cleaned_formatted_publication#</strong>"><!--- " --->
						</cfif>
					<cfelseif rtTable EQ "AGENT">
						<cfquery name="rtData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
							SELECT agent_name
							FROM agent_name
							WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rtKey#">
								AND agent_name_type = 'preferred'
						</cfquery>
						<cfif rtData.recordcount GT 0>
							<cfset rootTargetSummary = "Agent <strong><a href='/agents/Agent.cfm?agent_id=#rtKey#' target='_blank'>#encodeForHTML(rtData.agent_name)#</a></strong>"><!--- " --->
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
									<cfif len(ancestorChainHtml) GT 0>
										<!--- Depth >= 2: show full chain from root to immediate parent --->
										#ancestorChainHtml#
										<span class="small d-block mt-1">&##8627; Editing this annotation <strong>#annotation_id#</strong></span>
									<cfelse>
										<!--- Depth 1: direct reply to root annotation --->
										<span class="small d-block mt-1">
											Reply to root annotation <strong>#rootAnnotationId#</strong>
											<cfif len(rootAnnotationBody) GT 0>
												: #encodeForHTML(left(rootAnnotationBody, rootBodyPreviewLength))#
												<cfif len(rootAnnotationBody) GT rootBodyPreviewLength>&##8230;</cfif>
											</cfif>
										</span>
									</cfif>
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
										<div class="col-12 col-md-2 pb-1">
											<label for="#editMotivationFieldId#" class="data-entry-label">Motivation</label>
											<select id="#editMotivationFieldId#" class="data-entry-select">
												<cfloop query="ctmotivation">
													<cfif motivation EQ editAnn.motivation><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
													<option value="#motivation#"#selected#>#motivation# (#description#)</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-2 pb-1">
											<label for="#editMaskFieldId#" class="data-entry-label">Visibility</label>
											<select id="#editMaskFieldId#" class="data-entry-select">
												<cfif val(editAnn.mask_annotation_fg) EQ 0><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
												<option value="0"#selected#>Public</option>
												<cfif val(editAnn.mask_annotation_fg) EQ 1><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
												<option value="1"#selected#>Hidden</option>
											</select>
										</div>
										<cfif isResponseAnnotation>
											<div class="col-12 col-md-2 pb-1">
												<cfset currentRootReviewedLabel = "No">
												<cfif rootAnnQ.recordcount EQ 1 AND val(rootAnnQ.reviewed_fg) EQ 1>
													<cfset currentRootReviewedLabel = "Yes">
												</cfif>
												<label for="#editRootReviewedFieldId#" class="data-entry-label">Mark Root Reviewed? (#encodeForHTML(currentRootReviewedLabel)#)</label>
												<select id="#editRootReviewedFieldId#" class="data-entry-select">
													<option value="" selected="selected">No Change</option>
													<option value="0">No</option>
													<option value="1">Yes</option>
												</select>
											</div>
											<div class="col-12 col-md-2 pb-1">
												<cfset currentRootVisibilityLabel = "Public">
												<cfif rootAnnQ.recordcount EQ 1 AND val(rootAnnQ.mask_annotation_fg) EQ 1>
													<cfset currentRootVisibilityLabel = "Hidden">
												</cfif>
												<label for="#editRootMaskFieldId#" class="data-entry-label">Root Visibility (#encodeForHTML(currentRootVisibilityLabel)#)</label>
												<select id="#editRootMaskFieldId#" class="data-entry-select">
													<option value="" selected="selected">No Change</option>
													<option value="0">Public</option>
													<option value="1">Hidden</option>
												</select>
											</div>
										</cfif>
										<cfif canRespond>
											<cfset currentRootState = "">
											<cfset currentRootResolution = "">
											<cfset currentRootStateLabel = "New">
											<cfset currentRootResolutionLabel = "None">
											<cfif rootAnnQ.recordcount EQ 1>
												<cfset currentRootState = trim("" & rootAnnQ.state)>
												<cfset currentRootResolution = trim("" & rootAnnQ.resolution)>
												<cfif len(currentRootState) GT 0>
													<cfset currentRootStateLabel = currentRootState>
												</cfif>
												<cfif len(currentRootResolution) GT 0>
													<cfset currentRootResolutionLabel = currentRootResolution>
												</cfif>
											</cfif>
											<div class="col-12 col-md-2 pb-1">
												<label for="#editRootStateFieldId#" class="data-entry-label"><cfif isResponseAnnotation>Root State (#encodeForHTML(currentRootStateLabel)#)<cfelse>State</cfif></label>
												<select id="#editRootStateFieldId#" class="data-entry-select">
													<cfif isResponseAnnotation>
														<option value="" selected="selected">No Change</option>
													</cfif>
													<cfloop query="ctstate">
														<cfset selected = "">
														<cfif NOT isResponseAnnotation>
															<cfif state EQ currentRootState OR (len(currentRootState) EQ 0 AND state EQ "New")>
																<cfset selected = " selected ">
															</cfif>
														</cfif>
														<option value="#encodeForHTMLAttribute(state)#"#selected#>#encodeForHTML(state)#</option>
													</cfloop>
												</select>
											</div>
											<div class="col-12 col-md-2 pb-1">
												<label for="#editRootResolutionFieldId#" class="data-entry-label"><cfif isResponseAnnotation>Root Resolution (#encodeForHTML(currentRootResolutionLabel)#)<cfelse>Resolution</cfif></label>
												<select id="#editRootResolutionFieldId#" class="data-entry-select">
													<cfif isResponseAnnotation>
														<option value="" selected="selected">No Change</option>
													<cfelse>
														<option value="__NULL__"<cfif len(currentRootResolution) EQ 0> selected="selected"</cfif>></option>
													</cfif>
													<cfloop query="ctresolution">
														<cfset selected = "">
														<cfif NOT isResponseAnnotation AND resolution EQ currentRootResolution>
															<cfset selected = " selected ">
														</cfif>
														<option value="#encodeForHTMLAttribute(resolution)#"#selected#>#encodeForHTML(resolution)#</option>
													</cfloop>
												</select>
												<cfif len(rootResolutionGuidanceText) GT 0>
													<span class="small text-muted d-block">#encodeForHTML(rootResolutionGuidanceText)#</span>
												</cfif>
											</div>
											<cfif len(rootResolutionGuidanceText) GT 0>
												<script>
													$(document).ready(function() {
														applyCommentingResolutionGuidance('#editMotivationFieldId#', '#editRootResolutionFieldId#');
													});
												</script>
											</cfif>
										</cfif>
										<div class="col-12 pt-1">
											<input type="button"
												class="btn btn-xs btn-primary mt-1"
												value="Save Changes"
												onclick="saveAnnotationEdit(#annotation_id#, #rootAnnotationId#, '_#dq#', '#encodeForJavaScript(dialogId)#')">
											<output id="#editResultDivId#" class="ml-2" aria-live="polite"></output>
										</div>
									</form>
								</div>
							</div>
							</cfif>
							<!--- Context: root annotation + its responses in a card with target in the card header --->
							<cfset var ctxConversation = getAnnotationConversationForRoot(rootAnnotationId)>
							<cfquery name="ctxRoot" dbtype="query">
								SELECT
									ANNOTATION_ID, ANNOTATE_DATE, CF_USERNAME, ANNOTATION,
									REVIEWED_FG, REVIEWER_COMMENT, TARGET_TABLE,
									STATE, RESOLUTION,
									motivation, reviewer_name, annotator_email,
									MASK_ANNOTATION_FG, body_value
								FROM contextAnns
								WHERE TARGET_TABLE IS NULL 
									OR UPPER(TARGET_TABLE) NOT IN ('ANNOTATION','ANNOTATIONS')
								ORDER BY ANNOTATE_DATE
							</cfquery>
							<!--- Add form appears above heading (hidden, toggled by button in heading row) --->
							<cfif canRespond>
							<div id="#addFormDivId#" style="display:none;" class="col-12 mx-0 px-0 border p-1 mt-1">
								<form name="addAnnotationForm_#dq#" onSubmit="return false;" class="form-row px-1">
									<input type="hidden" id="idtype_add_#dq#" value="ANNOTATIONS">
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
									<div class="col-12 col-md-2 pb-1">
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
									<cfif canRespond>
										<div class="col-12 col-md-3 pb-1">
											<label for="#addRootStateFieldId#" class="data-entry-label">Root State</label>
											<select id="#addRootStateFieldId#" class="data-entry-select">
												<option value="" selected="selected">No Change</option>
												<cfloop query="ctstate">
													<option value="#encodeForHTMLAttribute(state)#">#encodeForHTML(state)#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-3 pb-1">
											<label for="#addRootResolutionFieldId#" class="data-entry-label">Root Resolution</label>
											<select id="#addRootResolutionFieldId#" class="data-entry-select">
												<option value="" selected="selected">No Change</option>
												<cfloop query="ctresolution">
													<option value="#encodeForHTMLAttribute(resolution)#">#encodeForHTML(resolution)#</option>
												</cfloop>
											</select>
											<cfif len(rootResolutionGuidanceText) GT 0>
												<span class="small text-muted d-block">#encodeForHTML(rootResolutionGuidanceText)#</span>
											</cfif>
										</div>
										<cfif len(rootResolutionGuidanceText) GT 0>
											<script>
												$(document).ready(function() {
													applyCommentingResolutionGuidance('#addMotivationFieldId#', '#addRootResolutionFieldId#');
												});
											</script>
										</cfif>
									</cfif>
									</cfif>
									<div class="col-12 pt-1">
										<input type="button"
											class="btn btn-xs btn-primary mt-1"
											value="Save Response"
											onclick="saveReplyAnnotationFromEditDialog('idtype_add_#dq#', 'idvalue_add_#dq#', '#addAnnFieldId#', '#addMotivationFieldId#', '#addMaskFieldId#', '#addRootStateFieldId#', '#addRootResolutionFieldId#', '#addResultDivId#', function(){ closeAnnotationDialogById('#encodeForJavaScript(dialogId)#'); })">
										<output id="#addResultDivId#" class="ml-2" aria-live="polite"></output>
									</div>
								</form>
							</div>
							</cfif>
							<!--- Annotation in Context heading with Add New Annotation button on same line --->
							<div class="col-12 mx-0 px-0 mt-2 d-flex align-items-center">
								<h3 class="h5 mb-0 flex-grow-1">Annotation in Context</h3>
								<cfif canRespond>
								<button type="button" id="toggleAddFormBtn_#dq#" class="btn btn-xs btn-outline-secondary">
									Add Reply Annotation
								</button>
								<script>
									function toggleAddAnnotationForm_#dq#() {
										var d = document.getElementById('#addFormDivId#');
										var btn = document.getElementById('toggleAddFormBtn_#dq#');
										if (d.style.display === 'none') {
											d.style.display = 'block';
											btn.textContent = 'Hide Form';
											$("###addAnnFieldId#").keyup();
										} else {
											d.style.display = 'none';
											btn.textContent = 'Add Reply Annotation';
										}
									}
									$(document).ready(function() {
										$("##toggleAddFormBtn_#dq#").on('click', toggleAddAnnotationForm_#dq#);
									});
								</script>
								</cfif>
							</div>
							<!--- Context card: target in card-header, annotation rows in card-body --->
							<div class="col-12 mx-0 px-0 mt-1">
								<div class="card border-bottom-0">
								<cfif len(rootTargetSummary) GT 0>
								<div class="card-header bg-box-header-gray py-1">
									<span class="small">#rootTargetSummary#</span>
								</div>
								</cfif>
								<cfif ctxRoot.recordcount GT 0>
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
											state=ctxRoot.state,
											resolution=ctxRoot.resolution,
											reviewer=ctxRoot.reviewer_name,
											reviewer_comment=ctxRoot.reviewer_comment,
											mask_annotation_fg=ctxRoot.mask_annotation_fg,
											is_response=false,
											root_annotation_id=ctxRoot.annotation_id,
											show_reply_action=false,
											highlight_as_editing=(val(ctxRoot.annotation_id) EQ val(arguments.annotation_id)))>
										#ctxRowHtml#
										#renderAnnotationConversationReplies(rootAnnotationId=ctxRoot.annotation_id, conversationAnnotations=ctxConversation, editing_annotation_id=arguments.annotation_id, root_mask_annotation_fg=ctxRoot.mask_annotation_fg)#
									</cfloop>
								<cfelse>
									<div class="card-body py-1 text-muted small"><em>No annotation context found.</em></div>
								</cfif>
								</div>
							</div>
						</div>
					</div>
				</section>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
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
 @param root_state optional; controlled vocabulary state value to set on root annotation.
 @param root_resolution optional; controlled vocabulary resolution value to set on root annotation, or __NULL__ to unset.
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
	<cfargument name="root_state"         type="string" required="no" default="">
	<cfargument name="root_resolution"    type="string" required="no" default="">
	<cfargument name="root_mask_annotation_fg" type="string" required="no" default="">

	<cfif NOT (isdefined("session.roles") AND listfindnocase(session.roles, "manage_collection"))>
		<cfheader statusCode="403" statusText="The manage_collection role is required to edit annotations.">
		<cfabort>
	</cfif>

	<cfset data = ArrayNew(1)>
	<cfset editorAgentId = requireCurrentUserAnnotationEditorAgentId()>
	<cftransaction>
		<cftry>
			<!--- Update annotation_textualbody body_value (first/earliest row) --->
			<cfquery name="updBody" datasource="uam_god">
				UPDATE annotation_textualbody
				SET body_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#urldecode(arguments.annotation)#">,
					last_updated_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#editorAgentId#">
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
					SET motivation = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cleanMotivation#">,
						last_updated_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#editorAgentId#">
					WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.annotation_id#">
				</cfquery>
			</cfif>
			<!--- Update this annotation's visibility if provided --->
			<cfif len(trim(arguments.mask_annotation_fg)) GT 0 AND REFind("^[01]$", trim(arguments.mask_annotation_fg)) GT 0>
				<cfquery name="updMask" datasource="uam_god">
					UPDATE annotations
					SET mask_annotation_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(arguments.mask_annotation_fg)#">,
						last_updated_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#editorAgentId#">
					WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.annotation_id#">
				</cfquery>
			</cfif>
			<!--- Update root annotation if response --->
			<cfif len(trim(arguments.root_annotation_id)) GT 0 AND val(arguments.root_annotation_id) GT 0>
				<cfset validRootState = "">
				<cfset validRootResolution = "">
				<cfset clearRootResolution = false>
				<cfif len(trim(arguments.root_state)) GT 0>
					<cfquery name="stateLookup" datasource="uam_god">
						SELECT state
						FROM ctstate
						WHERE UPPER(state) = UPPER(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.root_state)#">)
					</cfquery>
					<cfif stateLookup.recordcount EQ 1>
						<cfset validRootState = stateLookup.state>
					</cfif>
				</cfif>
				<cfif trim(arguments.root_resolution) EQ "__NULL__">
					<cfset clearRootResolution = true>
				<cfelseif len(trim(arguments.root_resolution)) GT 0>
					<cfquery name="resolutionLookup" datasource="uam_god">
						SELECT resolution
						FROM ctresolution
						WHERE UPPER(resolution) = UPPER(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.root_resolution)#">)
					</cfquery>
					<cfif resolutionLookup.recordcount EQ 1>
						<cfset validRootResolution = resolutionLookup.resolution>
					</cfif>
				</cfif>
				<cfif len(trim(arguments.root_reviewed_fg)) GT 0 AND REFind("^[01]$", trim(arguments.root_reviewed_fg)) GT 0>
					<cfquery name="updRootReviewed" datasource="uam_god">
						UPDATE annotations
						SET reviewed_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(arguments.root_reviewed_fg)#">,
							reviewer_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#editorAgentId#">,
							last_updated_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#editorAgentId#">
						WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.root_annotation_id#">
					</cfquery>
				</cfif>
				<cfif len(validRootState) GT 0 OR len(validRootResolution) GT 0 OR clearRootResolution>
					<cfquery name="updRootWorkflow" datasource="uam_god">
						UPDATE annotations
						SET
							<cfif len(validRootState) GT 0 AND len(validRootResolution) GT 0>
								state = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#validRootState#">,
								resolution = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#validRootResolution#">
							<cfelseif len(validRootState) GT 0 AND clearRootResolution>
								state = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#validRootState#">,
								resolution = NULL
							<cfelseif len(validRootState) GT 0>
								state = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#validRootState#">
							<cfelseif clearRootResolution>
								resolution = NULL
							<cfelse>
								resolution = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#validRootResolution#">
							</cfif>,
							last_updated_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#editorAgentId#">
						WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.root_annotation_id#">
					</cfquery>
				</cfif>
				<cfif len(trim(arguments.root_mask_annotation_fg)) GT 0 AND REFind("^[01]$", trim(arguments.root_mask_annotation_fg)) GT 0>
					<cfquery name="updRootMask" datasource="uam_god">
						UPDATE annotations
						SET mask_annotation_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(arguments.root_mask_annotation_fg)#">,
							last_updated_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#editorAgentId#">
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
