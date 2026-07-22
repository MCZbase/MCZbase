<!---
annotations/component/public.cfc

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
--->
<!--- Publicly callable functions for rendering annotation UI blocks. --->
<cfcomponent>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cfinclude template="/annotations/component/functions.cfc" runOnce="true">
<cf_rolecheck>

<!--- Get the card-body HTML for in-context agent annotation display.
  Renders root-level annotations on the given agent as a list-group with conversation replies, or a
  "no annotations" message when none exist.  Respects session visibility: coldfusion_user role sees
  all annotations; other users see only unmasked annotations or their own.
  Returns only the div.card-body HTML; callers are responsible for the card heading (with count and
  Annotate/Edit Annotations button).  access="remote" allows callers to reload the card body via AJAX
  after annotations are created or updated.
  @param agent_id the agent.agent_id whose annotations are to be rendered.
  @return string div.card-body HTML ready for output.
--->
<cffunction name="getAgentAnnotationCardBodyHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="agent_id" type="numeric" required="yes">

	<!--- TODO: Generalize to all agent types as targets  --->
	<cfset target_table = "AGENT">
	<cfset target_label = "agent">

	<cfset var annQuery = QueryNew("")>
	<cfset var conversations = QueryNew("")>
	<cfset var cardBodyHtml = "">
	<cftry>
		<cfquery name="annQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
			SELECT
				annotations.annotation_id,
				NVL(atb.body_value, annotations.annotation) annotation_display,
				annotations.cf_username,
				to_char(annotations.annotate_date, 'yyyy-mm-dd') annotate_date,
				annotations.motivation,
				annotations.reviewed_fg,
				preferred_agent_name.agent_name reviewer,
				annotations.reviewer_comment,
				annotations.mask_annotation_fg
			FROM
				annotations
				LEFT OUTER JOIN preferred_agent_name ON annotations.reviewer_agent_id = preferred_agent_name.agent_id
				LEFT OUTER JOIN (
					SELECT annotation_id, body_value,
						ROW_NUMBER() OVER (PARTITION BY annotation_id ORDER BY created_date) rn
					FROM annotation_textualbody
				) atb ON annotations.annotation_id = atb.annotation_id AND atb.rn = 1
			WHERE
				<cfif target_table EQ "AGENT">
					annotations.target_table = 'AGENT'
					AND annotations.target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.agent_id#">
				</cfif>
				<cfif NOT listcontainsnocase(session.roles, "coldfusion_user")>
					AND (annotations.mask_annotation_fg = 0 OR annotations.cf_username = <cfqueryparam value="#session.username#" cfsqltype="CF_SQL_VARCHAR">)
				</cfif>
			ORDER BY annotations.annotate_date
		</cfquery>
		<cfif annQuery.recordcount GT 0>
			<cfset conversations = getAnnotationConversationsForRoots(valueList(annQuery.annotation_id))>
		</cfif>
		<cfsavecontent variable="cardBodyHtml">
			<cfoutput>
			<div class="card-body py-2">
				<cfif annQuery.recordcount GT 0>
					<ul class="list-group">
						<cfloop query="annQuery">
							<li class="list-group-item py-1">
								<span class="small font-weight-bold">Annotation: </span>
								<cfif mask_annotation_fg EQ "1">
									<span class="small font-weight-bold">[Hidden] </span>
								</cfif>
								#annotation_display#
								<span class="d-block small mb-0 pb-0">#motivation# (#annotate_date#) &mdash; #renderAnnotatorHtml(annotation_id=val(annotation_id))#</span>
								<cfif reviewed_fg EQ "1" AND len(trim(reviewer)) GT 0>
									<span class="d-block small mb-0 pb-0">Reviewed by #encodeForHTML(reviewer)#<cfif len(trim(reviewer_comment)) GT 0>: #encodeForHTML(reviewer_comment)#</cfif></span>
								</cfif>
								#renderAnnotationConversationReplies(rootAnnotationId=val(annotation_id), conversationAnnotations=conversations, root_mask_annotation_fg=mask_annotation_fg, read_only=true)#
							</li>
						</cfloop>
					</ul>
				<cfelse>
					<p class="my-2 text-muted small">There are no annotations on this #target_label# record.</p>
				</cfif>
			</div>
			</cfoutput>
		</cfsavecontent>
	<cfcatch>
		<cfset cfcatchToErrorMessage(cfcatch)>
		<cfset reportError(functionName="getAgentAnnotationCardBodyHtml", note="agent_id=#arguments.agent_id#")>
		<cfheader statuscode="500" statustext="Internal Server Error">
		<cfset cardBodyHtml = '<div class="card-body py-2"><p class="my-2 text-danger small">Error loading annotations.</p></div>'><!--- ' --->
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn trim(cardBodyHtml)>
</cffunction>

<!--- Get the card-body HTML for in-context taxonomy annotation display.
  Renders root-level annotations on the given taxon record as a list-group with conversation replies,
  or a "no annotations" message when none exist.  Respects session visibility: coldfusion_user role
  sees all annotations; other users see only unmasked annotations or their own.
  Returns only the div.card-body HTML; callers are responsible for the card heading (with count and
  Annotate/Edit Annotations button).  access="remote" allows callers to reload the card body via AJAX
  after annotations are created or updated.
  @param taxon_name_id the taxonomy.taxon_name_id whose annotations are to be rendered.
  @return string div.card-body HTML ready for output.
--->
<cffunction name="getTaxonomyAnnotationCardBodyHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="taxon_name_id" type="numeric" required="yes">

	<cfset var annQuery = QueryNew("")>
	<cfset var conversations = QueryNew("")>
	<cfset var cardBodyHtml = "">
	<cftry>
		<cfquery name="annQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
			SELECT
				annotations.annotation_id,
				NVL(atb.body_value, annotations.annotation) annotation_display,
				annotations.cf_username,
				to_char(annotations.annotate_date, 'yyyy-mm-dd') annotate_date,
				annotations.motivation,
				annotations.reviewed_fg,
				preferred_agent_name.agent_name reviewer,
				annotations.reviewer_comment,
				annotations.mask_annotation_fg
			FROM
				annotations
				LEFT OUTER JOIN preferred_agent_name ON annotations.reviewer_agent_id = preferred_agent_name.agent_id
				LEFT OUTER JOIN (
					SELECT annotation_id, body_value,
						ROW_NUMBER() OVER (PARTITION BY annotation_id ORDER BY created_date) rn
					FROM annotation_textualbody
				) atb ON annotations.annotation_id = atb.annotation_id AND atb.rn = 1
			WHERE
				annotations.target_table = 'TAXONOMY'
				AND annotations.target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.taxon_name_id#">
				<cfif NOT listcontainsnocase(session.roles, "coldfusion_user")>
					AND (annotations.mask_annotation_fg = 0 OR annotations.cf_username = <cfqueryparam value="#session.username#" cfsqltype="CF_SQL_VARCHAR">)
				</cfif>
			ORDER BY annotations.annotate_date
		</cfquery>
		<cfif annQuery.recordcount GT 0>
			<cfset conversations = getAnnotationConversationsForRoots(valueList(annQuery.annotation_id))>
		</cfif>
		<cfsavecontent variable="cardBodyHtml">
			<cfoutput>
			<div class="card-body py-2">
				<cfif annQuery.recordcount GT 0>
					<ul class="list-group">
						<cfloop query="annQuery">
							<li class="list-group-item py-1">
								<span class="small font-weight-bold">Annotation: </span>
								<cfif mask_annotation_fg EQ "1">
									<span class="small font-weight-bold">[Hidden] </span>
								</cfif>
								#annotation_display#
								<span class="d-block small mb-0 pb-0">#motivation# (#annotate_date#) &mdash; #renderAnnotatorHtml(annotation_id=val(annotation_id))#</span>
								<cfif reviewed_fg EQ "1" AND len(trim(reviewer)) GT 0>
									<span class="d-block small mb-0 pb-0">Reviewed by #encodeForHTML(reviewer)#<cfif len(trim(reviewer_comment)) GT 0>: #encodeForHTML(reviewer_comment)#</cfif></span>
								</cfif>
								#renderAnnotationConversationReplies(rootAnnotationId=val(annotation_id), conversationAnnotations=conversations, root_mask_annotation_fg=mask_annotation_fg, read_only=true)#
							</li>
						</cfloop>
					</ul>
				<cfelse>
					<p class="my-2 text-muted small">There are no annotations on this taxon record.</p>
				</cfif>
			</div>
			</cfoutput>
		</cfsavecontent>
	<cfcatch>
		<cfset cfcatchToErrorMessage(cfcatch)>
		<cfset reportError(functionName="getTaxonomyAnnotationCardBodyHtml", note="taxon_name_id=#arguments.taxon_name_id#")>
		<cfheader statuscode="500" statustext="Internal Server Error">
		<cfset cardBodyHtml = '<div class="card-body py-2"><p class="my-2 text-danger small">Error loading annotations.</p></div>'><!--- ' --->
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn trim(cardBodyHtml)>
</cffunction>

</cfcomponent>
