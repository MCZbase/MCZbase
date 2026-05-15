<!---
annotations/showAnnotation.cfm

Detail view for one annotation conversation (root annotation and all replies).
Accepts url.annotation_id and optional url.format (html, rdf, json-ld, turtle).
For html (default), renders with standard MCZbase page header and footer.
For rdf, json-ld, or turtle, returns the annotation in W3C Web Annotation format.

Copyright 2024-2026 President and Fellows of Harvard College

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
<cfif isDefined("url.annotation_id")><cfset variables.annotation_id = url.annotation_id><cfelse><cfset variables.annotation_id = ""></cfif>
<cfif isDefined("url.format")><cfset variables.format = lcase(trim(url.format))><cfelse><cfset variables.format = "html"></cfif>
<cfif variables.format EQ "json" OR variables.format EQ "json-ld" OR variables.format EQ "application/ld+json"><cfset variables.format = "json-ld"></cfif>
<cfif variables.format EQ "rdf" OR variables.format EQ "application/rdf+xml" OR variables.format EQ "rdf+xml"><cfset variables.format = "rdf"></cfif>
<cfif variables.format EQ "turtle" OR variables.format EQ "text/turtle"><cfset variables.format = "turtle"></cfif>
<cfif NOT listFindNoCase("html,rdf,json-ld,turtle", variables.format)><cfset variables.format = "html"></cfif>

<cfif NOT (isDefined("variables.annotation_id") AND len(variables.annotation_id) GT 0 AND isNumeric(variables.annotation_id))>
	<cfif variables.format EQ "html">
		<cfset pageTitle = "Annotation Not Found">
		<cfinclude template="/shared/_header.cfm">
		<main class="container py-3">
			<div class="alert alert-warning"><p>An annotation_id is required to view an annotation conversation.</p><a href="/annotations/Annotations.cfm">List Annotations</a></div>
		</main>
		<cfinclude template="/shared/_footer.cfm">
	<cfelse>
		<cfheader statusCode="400" statusText="annotation_id is required">
	</cfif>
	<cfabort>
</cfif>

<cftry>

<!--- Look up the requested annotation --->
<cfquery name="requestedAnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
	SELECT a.annotation_id, a.target_table, a.target_primary_key, a.mask_annotation_fg,
		atb.body_value
	FROM annotations a
	LEFT OUTER JOIN (
		SELECT annotation_id, body_value,
			row_number() over (partition by annotation_id order by created_date) rn
		FROM annotation_textualbody
	) atb ON a.annotation_id = atb.annotation_id AND atb.rn = 1
	WHERE a.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.annotation_id#">
</cfquery>

<cfif requestedAnn.recordcount EQ 0>
	<cfif variables.format EQ "html">
		<cfset pageTitle = "Annotation Not Found">
		<cfinclude template="/shared/_header.cfm">
		<main class="container py-3">
			<cfoutput><div class="alert alert-warning"><p>Annotation #encodeForHTML(variables.annotation_id)# was not found.</p><a href="/annotations/Annotations.cfm">List Annotations</a></div></cfoutput>
		</main>
		<cfinclude template="/shared/_footer.cfm">
	<cfelse>
		<cfheader statusCode="404" statusText="Annotation not found">
	</cfif>
	<cfabort>
</cfif>

<!--- Navigate to the root annotation in the conversation chain --->
<cfset variables.rootAnnotationId = requestedAnn.annotation_id>
<cfif len(requestedAnn.target_table) GT 0 AND UCASE(requestedAnn.target_table) EQ "ANNOTATIONS">
	<cfquery name="findRoot" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT annotation_id FROM (
			SELECT annotation_id, LEVEL hierarchy_level
			FROM annotations
			START WITH annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#requestedAnn.annotation_id#">
			CONNECT BY PRIOR target_primary_key = annotation_id AND PRIOR target_table = 'ANNOTATIONS'
			ORDER BY LEVEL DESC
		) WHERE ROWNUM = 1
	</cfquery>
	<cfif findRoot.recordcount EQ 1>
		<cfset variables.rootAnnotationId = findRoot.annotation_id>
	</cfif>
</cfif>

<!--- Load root annotation and all replies in conversation order --->
<cfquery name="conversationAnns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
	SELECT
		annotations.ANNOTATION_ID,
		annotations.ANNOTATE_DATE,
		annotations.CF_USERNAME,
		annotations.ANNOTATION,
		annotations.REVIEWED_FG,
		annotations.REVIEWER_COMMENT,
		annotations.TARGET_TABLE,
		annotations.TARGET_PRIMARY_KEY,
		annotations.STATE,
		annotations.RESOLUTION,
		annotations.motivation,
		annotations.MASK_ANNOTATION_FG,
		revname.agent_name reviewer_name,
		annotator.first_name annotator_first_name,
		annotator.last_name annotator_last_name,
		annotator.email annotator_email,
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
	WHERE annotations.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.rootAnnotationId#">
	OR (
		UPPER(annotations.target_table) IN ('ANNOTATION','ANNOTATIONS')
		AND annotations.target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.rootAnnotationId#">
	)
	ORDER BY annotations.annotate_date
</cfquery>

<cfquery name="rootAnn" dbtype="query">
	SELECT * FROM conversationAnns
	WHERE ANNOTATION_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.rootAnnotationId#">
</cfquery>

<cfquery name="replyAnns" dbtype="query">
	SELECT * FROM conversationAnns WHERE UPPER(TARGET_TABLE) IN ('ANNOTATION','ANNOTATIONS') ORDER BY ANNOTATE_DATE
</cfquery>

<cfif rootAnn.recordcount EQ 0>
	<cfif variables.format EQ "html">
		<cfset pageTitle = "Annotation Not Found">
		<cfinclude template="/shared/_header.cfm">
		<main class="container py-3">
			<cfoutput><div class="alert alert-warning"><p>Root annotation not found for annotation #encodeForHTML(variables.annotation_id)#.</p><a href="/annotations/Annotations.cfm">List Annotations</a></div></cfoutput>
		</main>
		<cfinclude template="/shared/_footer.cfm">
	<cfelse>
		<cfheader statusCode="404" statusText="Root annotation not found">
	</cfif>
	<cfabort>
</cfif>

<!--- Determine annotation target context from root annotation target_table --->
<cfset variables.targetSummary = "">
<cfset variables.targetIRI = "">
<cfset variables.targetType = UCASE(rootAnn.target_table)>
<cfset variables.targetId = rootAnn.target_primary_key>
<cfswitch expression="#variables.targetType#">
	<cfcase value="COLLECTION_OBJECT">
		<cfquery name="targetRecord" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
			SELECT collection.institution_acronym, collection.collection_cde, cataloged_item.cat_num,
				mczbase.get_scientific_name_auths(cataloged_item.collection_object_id) display_name
			FROM cataloged_item
			LEFT JOIN collection ON cataloged_item.collection_id = collection.collection_id
			WHERE cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.targetId#">
		</cfquery>
		<cfif targetRecord.recordcount EQ 1>
			<cfset variables.targetIRI = Application.ServerRootUrl & "/guid/" & targetRecord.institution_acronym & ":" & targetRecord.collection_cde & ":" & targetRecord.cat_num>
			<cfset variables.targetSummary = "Cataloged Item " & targetRecord.institution_acronym & ":" & targetRecord.collection_cde & ":" & targetRecord.cat_num & " " & targetRecord.display_name>
		</cfif>
	</cfcase>
	<cfcase value="TAXON_NAME">
		<cfquery name="targetRecord" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
			SELECT display_name, scientific_name FROM taxonomy
			WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.targetId#">
		</cfquery>
		<cfif targetRecord.recordcount EQ 1>
			<cfset variables.targetIRI = Application.ServerRootUrl & "/name/" & encodeForURL(targetRecord.scientific_name)>
			<cfset variables.targetSummary = "Taxon " & targetRecord.display_name>
		</cfif>
	</cfcase>
	<cfcase value="PUBLICATION">
		<cfquery name="targetRecord" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
			SELECT formatted_publication FROM formatted_publication WHERE publication_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#variables.targetId#'> AND format_style = 'short'
		</cfquery>
		<cfif targetRecord.recordcount EQ 1>
			<cfset variables.targetIRI = Application.ServerRootUrl & "/publications/showPublication.cfm?publication_id=" & variables.targetId>
			<cfset variables.targetSummary = "Publication " & targetRecord.formatted_publication>
		</cfif>
	</cfcase>
	<cfcase value="PROJECT">
		<cfquery name="targetRecord" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
			SELECT project_name FROM project WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.targetId#">
		</cfquery>
		<cfif targetRecord.recordcount EQ 1>
			<cfset variables.targetIRI = Application.ServerRootUrl & "/projects/Project.cfm?project_id=" & variables.targetId>
			<cfset variables.targetSummary = "Project " & targetRecord.project_name>
		</cfif>
	</cfcase>
	<cfdefaultcase>
		<cfset variables.targetSummary = variables.targetType & " " & variables.targetId>
	</cfdefaultcase>
</cfswitch>

<!--- Permission checks --->
<cfset variables.canManage = isDefined("session.roles") AND listFindNoCase(session.roles, "manage_collection")>
<cfset variables.canAnnotate = false>
<cfif isDefined("session.username") AND len(session.username) GT 0>
	<cfquery name="hasEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
		SELECT email FROM cf_user_data, cf_users
		WHERE cf_user_data.user_id = cf_users.user_id
		AND cf_users.username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfif hasEmail.recordcount GT 0 AND len(hasEmail.email) GT 0>
		<cfset variables.canAnnotate = true>
	</cfif>
</cfif>

<cfset variables.thisAnnotationIRI = Application.ServerRootUrl & "/annotations/showAnnotation.cfm?annotation_id=" & variables.rootAnnotationId>

<!--- Hide masked annotations from users without manage_collection role --->
<cfif val(rootAnn.mask_annotation_fg) EQ 1 AND NOT variables.canManage>
	<cfif variables.format EQ "html">
		<cfset pageTitle = "Annotation Not Available">
		<cfinclude template="/shared/_header.cfm">
		<main class="container py-3">
			<div class="alert alert-info">This annotation is not publicly available.</div>
		</main>
		<cfinclude template="/shared/_footer.cfm">
	<cfelse>
		<cfheader statusCode="403" statusText="Annotation not publicly available">
	</cfif>
	<cfabort>
</cfif>

<cfif variables.format EQ "json-ld">
	<!--- W3C Web Annotation Data Model: JSON-LD output.
	     Language is consistently defaulted to "en" across all structured data formats
	     because annotations do not store a language attribute in the current schema. --->
	<cfcontent type="application/ld+json; charset=UTF-8">
	<cfoutput>
		{
			"@context": "http://www.w3.org/ns/anno.jsonld",
			"id": "#JSStringFormat(variables.thisAnnotationIRI)#",
			"type": "Annotation",
			"body": {"type": "TextualBody", "value": "#JSStringFormat(rootAnn.body_value)#", "language": "en"},
			"target": "#JSStringFormat(variables.targetIRI)#",
			"motivation": "#JSStringFormat(rootAnn.motivation)#",
			"created": "#dateformat(rootAnn.annotate_date,'yyyy-mm-dd')#",
			"creator": {"id": "#JSStringFormat(rootAnn.cf_username)#"},
			"reviewed": <cfif val(rootAnn.reviewed_fg) EQ 1>true<cfelse>false</cfif>,
			"visibility": "<cfif val(rootAnn.mask_annotation_fg) EQ 1>hidden<cfelse>public</cfif>"
			<cfif replyAnns.recordcount GT 0>
				,"replies": [
					<cfset variables.firstReply = true>
					<cfloop query="replyAnns">
						<cfif val(replyAnns.mask_annotation_fg) EQ 0 OR variables.canManage>
							<cfif NOT variables.firstReply>,</cfif>
							{
								"id": "#JSStringFormat(variables.thisAnnotationIRI)#&reply=#replyAnns.annotation_id#",
								"type": "Annotation",
								"body": {"type": "TextualBody", "value": "#JSStringFormat(replyAnns.body_value)#"},
								"target": "#JSStringFormat(variables.thisAnnotationIRI)#",
								"motivation": "replying",
								"created": "#dateformat(replyAnns.annotate_date,'yyyy-mm-dd')#",
								"creator": {"id": "#JSStringFormat(replyAnns.cf_username)#"}
							}
							<cfset variables.firstReply = false>
						</cfif>
					</cfloop>
				]
			</cfif>
		}
	</cfoutput>
<cfelseif variables.format EQ "rdf">
	<!--- W3C Web Annotation Data Model: RDF/XML output --->
	<cfcontent type="application/rdf+xml; charset=UTF-8">
	<cfoutput><?xml version="1.0" encoding="UTF-8"?>
	<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns##"
		xmlns:oa="http://www.w3.org/ns/oa##"
		xmlns:dcterms="http://purl.org/dc/terms/"
		xmlns:xsd="http://www.w3.org/2001/XMLSchema##">
		<oa:Annotation rdf:about="#XMLFormat(variables.thisAnnotationIRI)#">
			<cfif len(rootAnn.motivation) GT 0><oa:motivatedBy rdf:resource="http://www.w3.org/ns/oa###XMLFormat(rootAnn.motivation)#"/></cfif>
			<oa:hasBody>
				<oa:TextualBody>
					<rdf:value>#XMLFormat(rootAnn.body_value)#</rdf:value>
					<dcterms:language>en</dcterms:language>
				</oa:TextualBody>
			</oa:hasBody>
			<cfif len(variables.targetIRI) GT 0><oa:hasTarget rdf:resource="#XMLFormat(variables.targetIRI)#"/></cfif>
			<dcterms:created rdf:datatype="http://www.w3.org/2001/XMLSchema##date">#dateformat(rootAnn.annotate_date,'yyyy-mm-dd')#</dcterms:created>
			<dcterms:creator rdf:resource="urn:mczbase:user:#XMLFormat(rootAnn.cf_username)#"/>
		</oa:Annotation>
		<cfloop query="replyAnns">
			<cfif val(replyAnns.mask_annotation_fg) EQ 0 OR variables.canManage>
				<oa:Annotation rdf:about="#XMLFormat(variables.thisAnnotationIRI)#&amp;reply=#replyAnns.annotation_id#">
					<oa:motivatedBy rdf:resource="http://www.w3.org/ns/oa##replying"/>
					<oa:hasBody>
						<oa:TextualBody><rdf:value>#XMLFormat(replyAnns.body_value)#</rdf:value></oa:TextualBody>
					</oa:hasBody>
					<oa:hasTarget rdf:resource="#XMLFormat(variables.thisAnnotationIRI)#"/>
					<dcterms:created rdf:datatype="http://www.w3.org/2001/XMLSchema##date">#dateformat(replyAnns.annotate_date,'yyyy-mm-dd')#</dcterms:created>
					<dcterms:creator rdf:resource="urn:mczbase:user:#XMLFormat(replyAnns.cf_username)#"/>
				</oa:Annotation>
			</cfif>
		</cfloop>
	</rdf:RDF></cfoutput>
<cfelseif variables.format EQ "turtle">
	<!--- W3C Web Annotation Data Model: Turtle output --->
	<cfcontent type="text/turtle; charset=UTF-8">
	<cfoutput>@prefix oa: <http://www.w3.org/ns/oa##> .
	@prefix dcterms: <http://purl.org/dc/terms/> .
	@prefix xsd: <http://www.w3.org/2001/XMLSchema##> .

	<#variables.thisAnnotationIRI#>
		a oa:Annotation ;
		<cfif len(rootAnn.motivation) GT 0>oa:motivatedBy oa:#rootAnn.motivation# ;</cfif>
		oa:hasBody [
			a oa:TextualBody ;
			rdf:value "#JSStringFormat(rootAnn.body_value)#" ;
			dcterms:language "en"
		] ;
		<cfif len(variables.targetIRI) GT 0>oa:hasTarget <#variables.targetIRI#> ;</cfif>
		dcterms:created "#dateformat(rootAnn.annotate_date,'yyyy-mm-dd')#"^^xsd:date ;
		dcterms:creator <urn:mczbase:user:#encodeForURL(rootAnn.cf_username)#> .

	<cfloop query="replyAnns">
		<cfif val(replyAnns.mask_annotation_fg) EQ 0 OR variables.canManage>
		<#variables.thisAnnotationIRI#&reply=#replyAnns.annotation_id#>
			a oa:Annotation ;
			oa:motivatedBy oa:replying ;
			oa:hasBody [
				a oa:TextualBody ;
				rdf:value "#JSStringFormat(replyAnns.body_value)#" ;
				dcterms:language "en"
			] ;
			oa:hasTarget <#variables.thisAnnotationIRI#> ;
			dcterms:created "#dateformat(replyAnns.annotate_date,'yyyy-mm-dd')#"^^xsd:date ;
			dcterms:creator <urn:mczbase:user:#encodeForURL(replyAnns.cf_username)#> .
		</cfif>
	</cfloop></cfoutput>
<cfelse>
	<!--- HTML view: standard MCZbase page with full conversation --->
	<cfset variables.rootBodyPreview = "">
	<cfif len(rootAnn.body_value) GT 0>
		<cfset variables.rootBodyPreview = left(rootAnn.body_value, 80)>
		<cfif len(rootAnn.body_value) GT 80><cfset variables.rootBodyPreview = variables.rootBodyPreview & "..."></cfif>
	</cfif>
	<cfset pageTitle = "Annotation Conversation">
	<cfif len(variables.rootBodyPreview) GT 0><cfset pageTitle = "Annotation: " & variables.rootBodyPreview></cfif>
	<cfinclude template="/shared/_header.cfm">
	<cfoutput>
	<main class="container-fluid" id="content">
		<div class="row mx-0 mt-2 mb-4">
			<div class="col-12">
				<div class="d-flex justify-content-between align-items-start mb-2">
					<div>
						<h1 class="h3 mb-0">Annotation Conversation</h1>
						<cfif len(variables.targetSummary) GT 0>
							<p class="mb-1 text-muted small">
								Target: 
								<cfif len(variables.targetIRI) GT 0>
									<a href="#variables.targetIRI#">
										#variables.targetSummary#
									</a>
								<cfelse>
									#variables.targetSummary#
								</cfif>
							</p>
						</cfif>
					</div>
					<div class="text-right">
						<div class="btn-group btn-group-sm" role="group" aria-label="Data formats">
							<span class="btn btn-sm btn-secondary disabled">HTML</span>
							<a href="showAnnotation.cfm?annotation_id=#variables.rootAnnotationId#&format=json-ld" class="btn btn-sm btn-outline-secondary">JSON-LD</a>
							<a href="showAnnotation.cfm?annotation_id=#variables.rootAnnotationId#&format=rdf" class="btn btn-sm btn-outline-secondary">RDF/XML</a>
							<a href="showAnnotation.cfm?annotation_id=#variables.rootAnnotationId#&format=turtle" class="btn btn-sm btn-outline-secondary">Turtle</a>
						</div>
					</div>
				</div>
				<!--- Root annotation card with replies --->
				<div class="card border-bottom-0 mb-3">
					<div class="card-header bg-box-header-gray py-1">
						<h2 class="h5 mb-0">Root Annotation <span class="text-muted small">(#variables.rootAnnotationId#)</span></h2>
					</div>
					<cfif len(rootAnn.body_value) GT 0>
						<cfset variables.rootDisplayText = rootAnn.body_value>
					<cfelse>
						<cfset variables.rootDisplayText = rootAnn.annotation>
					</cfif>
					<cfinvoke component="/annotations/component/functions" method="renderAnnotationReviewRow" returnvariable="rootRowHtml"
						annotation_id="#rootAnn.annotation_id#"
						annotation_display="#variables.rootDisplayText#"
						cf_username="#rootAnn.cf_username#"
						email="#rootAnn.annotator_email#"
						annotate_date="#rootAnn.annotate_date#"
						motivation="#rootAnn.motivation#"
						reviewed_fg="#rootAnn.reviewed_fg#"
						reviewer="#rootAnn.reviewer_name#"
						reviewer_comment="#rootAnn.reviewer_comment#"
						mask_annotation_fg="#rootAnn.mask_annotation_fg#"
						is_response="false"
						root_annotation_id="#rootAnn.annotation_id#"
						show_reply_action="#variables.canAnnotate OR variables.canManage#">
					#rootRowHtml#
					<cfif replyAnns.recordcount GT 0>
						<div class="ml-4 pl-0 border-left border-dark" data-reply-parent-id="#variables.rootAnnotationId#">
							<cfloop query="replyAnns">
								<cfif val(replyAnns.mask_annotation_fg) EQ 0 OR variables.canManage>
									<cfif len(replyAnns.body_value) GT 0><cfset variables.replyDisplayText = replyAnns.body_value><cfelse><cfset variables.replyDisplayText = replyAnns.annotation></cfif>
									<cfinvoke component="/annotations/component/functions" method="renderAnnotationReviewRow" returnvariable="replyRowHtml"
										annotation_id="#replyAnns.annotation_id#"
										annotation_display="#variables.replyDisplayText#"
										cf_username="#replyAnns.cf_username#"
										email="#replyAnns.annotator_email#"
										annotate_date="#replyAnns.annotate_date#"
										motivation="#replyAnns.motivation#"
										reviewed_fg="#replyAnns.reviewed_fg#"
										reviewer="#replyAnns.reviewer_name#"
										reviewer_comment="#replyAnns.reviewer_comment#"
										mask_annotation_fg="#replyAnns.mask_annotation_fg#"
										is_response="true"
										root_annotation_id="#variables.rootAnnotationId#"
										show_reply_action="false">
									#replyRowHtml#
								</cfif>
							</cfloop>
						</div>
					<cfelse>
						<div class="card-body py-1 text-muted small"><em>No replies yet.</em></div>
					</cfif>
				</div>
				<cfif variables.canAnnotate OR variables.canManage>
					<div class="mt-2 mb-3">
						<button type="button" class="btn btn-primary btn-sm open-reply-annotation-dialog" data-root-annotation-id="#variables.rootAnnotationId#">Reply to this Annotation</button>
					</div>
				</cfif>
			</div>
		</div>
	</main>
	</cfoutput>
	<cfinclude template="/shared/_footer.cfm">
</cfif>

<cfcatch>
	<cfif variables.format EQ "html">
		<cfset pageTitle = "Error">
		<cfinclude template="/shared/_header.cfm">
		<main class="container py-3">
			<cfoutput><div class="alert alert-danger"><h2>Error Loading Annotation</h2><p>#encodeForHTML(cfcatch.message)#</p><a href="/annotations/Annotations.cfm">List Annotations</a></div></cfoutput>
		</main>
		<cfinclude template="/shared/_footer.cfm">
	<cfelse>
		<cfheader statusCode="500" statusText="Internal Server Error">
		<cfoutput>#encodeForHTML(cfcatch.message)#</cfoutput>
	</cfif>
</cfcatch>
</cftry>
