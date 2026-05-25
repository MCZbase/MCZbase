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

<!--- Get the card-body HTML for in-context agent annotation display, along with the annotation count.
  Renders root-level annotations on the given agent as a list-group with conversation replies, or a
  "no annotations" message when none exist.  Respects session visibility: coldfusion_user role sees
  all annotations; other users see only unmasked annotations or their own.
  @param agent_id the agent.agent_id whose annotations are to be rendered.
  @return struct with keys:
    ct   - integer count of visible root annotations for this agent.
    html - string card-body HTML (div.card-body) ready for output.
--->
<cffunction name="getAgentAnnotationCardBodyHtml" returntype="struct" access="public">
	<cfargument name="agent_id" type="numeric" required="yes">
	<cfset var result = StructNew()>
	<cfset var countQuery = QueryNew("")>
	<cfset var annQuery = QueryNew("")>
	<cfset var conversations = QueryNew("")>
	<cfset var cardBodyHtml = "">
	<cfquery name="countQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
		SELECT count(annotation_id) ct
		FROM annotations
		WHERE target_table = 'AGENT'
			AND target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.agent_id#">
			<cfif NOT listcontainsnocase(session.roles, "coldfusion_user")>
				AND (mask_annotation_fg = 0 OR cf_username = <cfqueryparam value="#session.username#" cfsqltype="CF_SQL_VARCHAR">)
			</cfif>
	</cfquery>
	<cfset result.ct = val(countQuery.ct)>
	<cfif result.ct GT 0>
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
				annotations.target_table = 'AGENT'
				AND annotations.target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.agent_id#">
				<cfif NOT listcontainsnocase(session.roles, "coldfusion_user")>
					AND (annotations.mask_annotation_fg = 0 OR annotations.cf_username = <cfqueryparam value="#session.username#" cfsqltype="CF_SQL_VARCHAR">)
				</cfif>
			ORDER BY annotations.annotate_date
		</cfquery>
		<cfset conversations = getAnnotationConversationsForRoots(valueList(annQuery.annotation_id))>
	</cfif>
	<cfsavecontent variable="cardBodyHtml">
		<cfoutput>
		<div class="card-body py-2">
			<cfif result.ct GT 0>
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
				<p class="my-2 text-muted small">There are no annotations on this agent record.</p>
			</cfif>
		</div>
		</cfoutput>
	</cfsavecontent>
	<cfset result.html = cardBodyHtml>
	<cfreturn result>
</cffunction>

</cfcomponent>
