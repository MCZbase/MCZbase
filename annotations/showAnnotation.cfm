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
<cfinclude template="/annotations/component/functions.cfc" runOnce="true"><!--- for renderAnnotationReviewRow, getAnnotationConversationForRoot, renderAnnotationConversationReplies --->
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
	
	<!--- Load full conversation tree from root annotation in hierarchy order --->
	<cfquery name="conversationAnns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT
			annotations.ANNOTATION_ID,
			CASE WHEN LEVEL = 1 THEN NULL ELSE annotations.target_primary_key END AS parent_annotation_id,
			LEVEL - 1 AS depth,
			annotations.ANNOTATE_DATE,
			annotations.CF_USERNAME,
			annotations.ANNOTATOR_AGENT_ID,
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
			pan.agent_name annotator_agent_name,
			ag.agentguid annotator_agentguid,
			ag.agentguid_guid_type annotator_agentguid_guid_type,
			annotator.first_name annotator_first_name,
			annotator.last_name annotator_last_name,
			annotator.email annotator_email,
			atb.body_value
		FROM annotations
		LEFT OUTER JOIN agent rev ON annotations.reviewer_agent_id = rev.agent_id
		LEFT OUTER JOIN agent_name revname ON rev.PREFERRED_AGENT_NAME_ID = revname.agent_name_id
		LEFT OUTER JOIN cf_users ON annotations.cf_username = cf_users.username
		LEFT OUTER JOIN cf_user_data annotator ON cf_users.user_id = annotator.user_id
		LEFT OUTER JOIN agent ag ON annotations.annotator_agent_id = ag.agent_id
		LEFT OUTER JOIN agent_name pan ON ag.PREFERRED_AGENT_NAME_ID = pan.agent_name_id
		LEFT OUTER JOIN (
			SELECT annotation_id, body_value,
				row_number() over (partition by annotation_id order by created_date) rn
			FROM annotation_textualbody
		) atb ON annotations.annotation_id = atb.annotation_id AND atb.rn = 1
		START WITH annotations.annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.rootAnnotationId#">
		CONNECT BY PRIOR annotations.annotation_id = annotations.target_primary_key
			AND UPPER(annotations.target_table) IN ('ANNOTATION','ANNOTATIONS')
		ORDER SIBLINGS BY annotations.annotate_date
	</cfquery>
	
	<!--- Prepare creator identity and display name for RDF serialization without exposing username identifiers --->
	<cfset QueryAddColumn(conversationAnns, "creator_uri", ArrayNew(1))>
	<cfset QueryAddColumn(conversationAnns, "creator_name", ArrayNew(1))>
	<cfloop query="conversationAnns">
		<cfset variables.creatorUri = "">
		<cfset variables.creatorName = trim(conversationAnns.annotator_first_name & " " & conversationAnns.annotator_last_name)>
		<cfif val(conversationAnns.annotator_agent_id) GT 0>
			<cfif ucase(trim(conversationAnns.annotator_agentguid_guid_type)) EQ "ORCID" AND len(trim(conversationAnns.annotator_agentguid)) GT 0>
				<cfset variables.orcidCandidate = trim(conversationAnns.annotator_agentguid)>
				<cfif REFindNoCase("^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$", variables.orcidCandidate)>
					<cfset variables.orcidCandidate = "https://orcid.org/" & variables.orcidCandidate>
				</cfif>
				<cfif REFindNoCase("^https?://orcid.org/[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$", variables.orcidCandidate)>
					<cfset variables.creatorUri = variables.orcidCandidate>
				</cfif>
			</cfif>
			<cfif len(variables.creatorUri) EQ 0>
				<cfset variables.creatorUri = Application.ServerRootUrl & "/agents/Agent.cfm?agent_id=" & conversationAnns.annotator_agent_id>
			</cfif>
			<cfif len(trim(conversationAnns.annotator_agent_name)) GT 0>
				<cfset variables.creatorName = trim(conversationAnns.annotator_agent_name)>
			</cfif>
		</cfif>
		<cfif len(variables.creatorName) EQ 0>
			<cfset variables.creatorName = "Unknown creator">
		</cfif>
		<cfset QuerySetCell(conversationAnns, "creator_uri", variables.creatorUri, conversationAnns.currentrow)>
		<cfset QuerySetCell(conversationAnns, "creator_name", variables.creatorName, conversationAnns.currentrow)>
	</cfloop>

	<cfquery name="rootAnn" dbtype="query">
		SELECT * FROM conversationAnns
		WHERE ANNOTATION_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.rootAnnotationId#">
	</cfquery>
	
	<cfquery name="ancestorPath" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT annotation_id
		FROM annotations
		START WITH annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.annotation_id#">
		CONNECT BY PRIOR target_primary_key = annotation_id
			AND UPPER(PRIOR target_table) IN ('ANNOTATION','ANNOTATIONS')
	</cfquery>
	
	<cfquery name="requestedSubtree" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT annotation_id
		FROM annotations
		START WITH annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.annotation_id#">
		CONNECT BY PRIOR annotation_id = target_primary_key
			AND UPPER(target_table) IN ('ANNOTATION','ANNOTATIONS')
	</cfquery>
	
	<cfset variables.includedAnnotationIdSet = {}>
	<cfset variables.includedAnnotationIds = "">
	<cfloop query="ancestorPath">
		<cfset variables.includedAnnotationIdSet[ancestorPath.annotation_id] = ancestorPath.annotation_id>
	</cfloop>
	<cfloop query="requestedSubtree">
		<cfset variables.includedAnnotationIdSet[requestedSubtree.annotation_id] = requestedSubtree.annotation_id>
	</cfloop>
	<cfset variables.includedAnnotationIds = arrayToList(structValueArray(variables.includedAnnotationIdSet))>
	<cfif len(trim(variables.includedAnnotationIds)) EQ 0>
		<cfset variables.includedAnnotationIds = variables.annotation_id>
	</cfif>
	
	<cfquery name="includedConversationAnns" dbtype="query">
		SELECT *
		FROM conversationAnns
		WHERE annotation_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.includedAnnotationIds#" list="yes">)
		ORDER BY annotate_date
	</cfquery>
	<cfquery name="requestedAnnRow" dbtype="query">
		SELECT *
		FROM includedConversationAnns
		WHERE annotation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.annotation_id#">
	</cfquery>
	
	<cfif rootAnn.recordcount EQ 0>
		<cfif variables.format EQ "html">
			<cfset pageTitle = "Annotation Not Found">
			<cfinclude template="/shared/_header.cfm">
			<main class="container py-3">
				<cfoutput>
					<div class="alert alert-warning">
						<p>Root annotation not found for annotation #encodeForHTML(variables.annotation_id)#.</p>
						<a href="/annotations/Annotations.cfm">List Annotations</a>
					</div>
				</cfoutput>
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
		<cfcase value="TAXONOMY">
			<cfquery name="targetRecord" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
				SELECT display_name, scientific_name 
				FROM taxonomy
				WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.targetId#">
			</cfquery>
			<cfif targetRecord.recordcount EQ 1>
				<cfset variables.targetIRI = Application.ServerRootUrl & "/name/" & encodeForURL(targetRecord.scientific_name)>
				<cfset variables.targetSummary = "Taxon " & targetRecord.display_name>
			</cfif>
		</cfcase>
		<cfcase value="PUBLICATION">
			<cfquery name="targetRecord" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
				SELECT formatted_publication 
				FROM formatted_publication 
				WHERE publication_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#variables.targetId#'> 
					AND format_style = 'short'
			</cfquery>
			<cfif targetRecord.recordcount EQ 1>
				<cfset variables.targetIRI = Application.ServerRootUrl & "/publications/showPublication.cfm?publication_id=" & variables.targetId>
				<cfset variables.targetSummary = "Publication " & targetRecord.formatted_publication>
			</cfif>
		</cfcase>
		<cfcase value="PROJECT">
			<cfquery name="targetRecord" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
				SELECT project_name 
				FROM project 
				WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.targetId#">
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
			SELECT email 
			FROM cf_user_data, cf_users
			WHERE cf_user_data.user_id = cf_users.user_id
				AND cf_users.username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<cfif hasEmail.recordcount GT 0 AND len(hasEmail.email) GT 0>
			<cfset variables.canAnnotate = true>
		</cfif>
	</cfif>
	
	<cfset variables.thisAnnotationIRI = Application.ServerRootUrl & "/annotations/showAnnotation.cfm?annotation_id=" & variables.annotation_id>
	
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
	<cfif requestedAnnRow.recordcount EQ 0>
		<cfheader statusCode="404" statusText="Requested annotation not found in conversation">
		<cfabort>
	</cfif>
	<cfif val(requestedAnnRow.mask_annotation_fg) EQ 1 AND NOT variables.canManage>
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
	
	<cfswitch expression="#variables.format#">
		<cfcase value="json-ld">
			<!--- W3C Web Annotation Data Model: JSON-LD output.
			     Language is consistently defaulted to "en" across all structured data formats
			     because annotations do not store a language attribute in the current schema. --->
			<cfcontent type="application/ld+json; charset=UTF-8">
			<cfoutput>
				<cfif val(requestedAnnRow.depth) EQ 0>
					<cfset variables.requestedTarget = variables.targetIRI>
				<cfelse>
					<cfset variables.requestedTarget = Application.ServerRootUrl & "/annotations/showAnnotation.cfm?annotation_id=" & requestedAnnRow.parent_annotation_id>
				</cfif>
				{
					"@context": "http://www.w3.org/ns/anno.jsonld",
					"id": "#JSStringFormat(variables.thisAnnotationIRI)#",
					"type": "Annotation",
					"body": {"type": "TextualBody", "value": "#JSStringFormat(requestedAnnRow.body_value)#", "language": "en"},
					<cfif len(variables.requestedTarget) GT 0>"target": "#JSStringFormat(variables.requestedTarget)#",</cfif>
					<cfif len(requestedAnnRow.motivation) GT 0>"motivation": "#JSStringFormat(requestedAnnRow.motivation)#",</cfif>
					"created": "#dateformat(requestedAnnRow.annotate_date,'yyyy-mm-dd')#",
					"creator": {
						<cfif len(requestedAnnRow.creator_uri) GT 0>"id": "#JSStringFormat(requestedAnnRow.creator_uri)#",</cfif>
						"name": "#JSStringFormat(requestedAnnRow.creator_name)#"
					},
					"reviewed": <cfif val(requestedAnnRow.reviewed_fg) EQ 1>true<cfelse>false</cfif>,
					"visibility": "<cfif val(requestedAnnRow.mask_annotation_fg) EQ 1>hidden<cfelse>public</cfif>",
					"replies": [
						<cfset variables.firstAnnotation = true>
						<cfloop query="includedConversationAnns">
							<cfif val(includedConversationAnns.mask_annotation_fg) EQ 0 OR variables.canManage>
								<!--- Top-level object already represents the requested annotation. --->
								<cfif val(includedConversationAnns.annotation_id) EQ val(variables.annotation_id)><cfcontinue></cfif>
								<cfset variables.annotationIRI = Application.ServerRootUrl & "/annotations/showAnnotation.cfm?annotation_id=" & includedConversationAnns.annotation_id>
								<cfif val(includedConversationAnns.depth) EQ 0>
									<cfset variables.annotationTarget = variables.targetIRI>
								<cfelse>
									<cfset variables.annotationTarget = Application.ServerRootUrl & "/annotations/showAnnotation.cfm?annotation_id=" & includedConversationAnns.parent_annotation_id>
								</cfif>
								<cfif NOT variables.firstAnnotation>,</cfif>
								{
									"id": "#JSStringFormat(variables.annotationIRI)#",
									"type": "Annotation",
									"body": {"type": "TextualBody", "value": "#JSStringFormat(includedConversationAnns.body_value)#", "language": "en"},
									<cfif len(variables.annotationTarget) GT 0>"target": "#JSStringFormat(variables.annotationTarget)#",</cfif>
									<cfif len(includedConversationAnns.motivation) GT 0>"motivation": "#JSStringFormat(includedConversationAnns.motivation)#",</cfif>
									"created": "#dateformat(includedConversationAnns.annotate_date,'yyyy-mm-dd')#",
									"creator": {
										<cfif len(includedConversationAnns.creator_uri) GT 0>"id": "#JSStringFormat(includedConversationAnns.creator_uri)#",</cfif>
										"name": "#JSStringFormat(includedConversationAnns.creator_name)#"
									},
									"reviewed": <cfif val(includedConversationAnns.reviewed_fg) EQ 1>true<cfelse>false</cfif>,
									"visibility": "<cfif val(includedConversationAnns.mask_annotation_fg) EQ 1>hidden<cfelse>public</cfif>"
								}
								<cfset variables.firstAnnotation = false>
							</cfif>
						</cfloop>
					]
				}
			</cfoutput>
		</cfcase>
		<cfcase value="rdf">
			<!--- W3C Web Annotation Data Model: RDF/XML output --->
			<cfcontent type="application/rdf+xml; charset=UTF-8">
			<cfoutput><?xml version="1.0" encoding="UTF-8"?>
			<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns##"
				xmlns:oa="http://www.w3.org/ns/oa##"
				xmlns:dcterms="http://purl.org/dc/terms/"
				xmlns:foaf="http://xmlns.com/foaf/0.1/"
				xmlns:xsd="http://www.w3.org/2001/XMLSchema##">
				<cfloop query="includedConversationAnns">
					<cfif val(includedConversationAnns.mask_annotation_fg) EQ 0 OR variables.canManage>
						<cfset variables.annotationIRI = Application.ServerRootUrl & "/annotations/showAnnotation.cfm?annotation_id=" & includedConversationAnns.annotation_id>
						<cfset variables.motivationIRI = "">
						<cfif len(includedConversationAnns.motivation) GT 0>
							<cfset variables.motivationIRI = "http://www.w3.org/ns/oa#" & includedConversationAnns.motivation>
						</cfif>
						<cfif val(includedConversationAnns.depth) EQ 0>
							<cfset variables.annotationTarget = variables.targetIRI>
						<cfelse>
							<cfset variables.annotationTarget = Application.ServerRootUrl & "/annotations/showAnnotation.cfm?annotation_id=" & includedConversationAnns.parent_annotation_id>
						</cfif>
						<oa:Annotation rdf:about="#XMLFormat(variables.annotationIRI)#">
							<cfif len(variables.motivationIRI) GT 0><oa:motivatedBy rdf:resource="#XMLFormat(variables.motivationIRI)#"/></cfif>
							<oa:hasBody>
								<oa:TextualBody>
									<rdf:value>#XMLFormat(includedConversationAnns.body_value)#</rdf:value>
									<dcterms:language>en</dcterms:language>
								</oa:TextualBody>
							</oa:hasBody>
							<cfif len(variables.annotationTarget) GT 0><oa:hasTarget rdf:resource="#XMLFormat(variables.annotationTarget)#"/></cfif>
							<dcterms:created rdf:datatype="http://www.w3.org/2001/XMLSchema##date">#dateformat(includedConversationAnns.annotate_date,'yyyy-mm-dd')#</dcterms:created>
							<dcterms:creator>
								<foaf:Agent<cfif len(includedConversationAnns.creator_uri) GT 0> rdf:about="#XMLFormat(includedConversationAnns.creator_uri)#"</cfif>>
									<foaf:name>#XMLFormat(includedConversationAnns.creator_name)#</foaf:name>
								</foaf:Agent>
							</dcterms:creator>
						</oa:Annotation>
					</cfif>
				</cfloop>
			</rdf:RDF></cfoutput>
		</cfcase>
		<cfcase value="turtle">
			<!--- W3C Web Annotation Data Model: Turtle output --->
			<cfcontent type="text/turtle; charset=UTF-8">
			<cfoutput>@prefix oa: <http://www.w3.org/ns/oa##> .
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns##> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema##> .
		
<cfloop query="includedConversationAnns">

<cfif val(includedConversationAnns.mask_annotation_fg) EQ 0 OR variables.canManage>
<cfset variables.annotationIRI = Application.ServerRootUrl & "/annotations/showAnnotation.cfm?annotation_id=" & includedConversationAnns.annotation_id>
<cfset variables.motivationIRI = "">
<cfif len(includedConversationAnns.motivation) GT 0>
	<cfset variables.motivationIRI = "http://www.w3.org/ns/oa#" & includedConversationAnns.motivation>
</cfif>
<cfif val(includedConversationAnns.depth) EQ 0>
	<cfset variables.annotationTarget = variables.targetIRI>
<cfelse>
	<cfset variables.annotationTarget = Application.ServerRootUrl & "/annotations/showAnnotation.cfm?annotation_id=" & includedConversationAnns.parent_annotation_id>
</cfif>
<#variables.annotationIRI#>
    a oa:Annotation ;
    <cfif len(variables.motivationIRI) GT 0>oa:motivatedBy <#variables.motivationIRI#> ;</cfif>
    oa:hasBody [
        a oa:TextualBody ;
        rdf:value "#JSStringFormat(includedConversationAnns.body_value)#" ;
        dcterms:language "en"
    ] ;
    <cfif len(variables.annotationTarget) GT 0>oa:hasTarget <#variables.annotationTarget#> ;</cfif>
    dcterms:created "#dateformat(includedConversationAnns.annotate_date,'yyyy-mm-dd')#"^^xsd:date ;
    dcterms:creator <cfif len(includedConversationAnns.creator_uri) GT 0><#includedConversationAnns.creator_uri#><cfelse>[ a foaf:Agent ; foaf:name "#JSStringFormat(includedConversationAnns.creator_name)#" ]</cfif> .
<cfif len(includedConversationAnns.creator_uri) GT 0>
<#includedConversationAnns.creator_uri#> foaf:name "#JSStringFormat(includedConversationAnns.creator_name)#" .
</cfif>
</cfif>
</cfloop></cfoutput>
		</cfcase>
		<cfdefaultcase>
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
									<a href="showAnnotation.cfm?annotation_id=#variables.annotation_id#&format=json-ld" class="btn btn-sm btn-outline-secondary">JSON-LD</a>
									<a href="showAnnotation.cfm?annotation_id=#variables.annotation_id#&format=rdf" class="btn btn-sm btn-outline-secondary">RDF/XML</a>
									<a href="showAnnotation.cfm?annotation_id=#variables.annotation_id#&format=turtle" class="btn btn-sm btn-outline-secondary">Turtle</a>
								</div>
							</div>
						</div>
						<!--- Root annotation card with replies --->
						<div class="card border-bottom-0 mb-3">
							<div class="card-header bg-box-header-gray py-1">
								<h2 class="h5 mb-0">
									Root Annotation 
									<span class="text-muted small">(#variables.rootAnnotationId#)</span>
									on #targetSummary#
								</h2>
							</div>
							<cfif len(rootAnn.body_value) GT 0>
								<cfset variables.rootDisplayText = rootAnn.body_value>
							<cfelse>
								<cfset variables.rootDisplayText = rootAnn.annotation>
							</cfif>
							<cfset rootRowHtml = renderAnnotationReviewRow(
								annotation_id=rootAnn.annotation_id,
								annotation_display=variables.rootDisplayText,
								cf_username=rootAnn.cf_username,
								email=rootAnn.annotator_email,
								annotate_date=rootAnn.annotate_date,
								motivation=rootAnn.motivation,
								reviewed_fg=rootAnn.reviewed_fg,
								state=rootAnn.state,
								resolution=rootAnn.resolution,
								reviewer=rootAnn.reviewer_name,
								reviewer_comment=rootAnn.reviewer_comment,
								mask_annotation_fg=rootAnn.mask_annotation_fg,
								is_response=false,
								root_annotation_id=rootAnn.annotation_id,
								show_reply_action=variables.canManage,
								highlight_as_target=(val(rootAnn.annotation_id) EQ val(variables.annotation_id)),
								highlight_label="Selected Annotation")>
							#rootRowHtml#
							<cfset variables.fullConversation = getAnnotationConversationForRoot(rootAnnotationId=variables.rootAnnotationId)>
							<cfset variables.conversationSectionHtml = renderAnnotationConversationReplies(
								rootAnnotationId=variables.rootAnnotationId,
								conversationAnnotations=variables.fullConversation,
								root_mask_annotation_fg=rootAnn.mask_annotation_fg,
								highlight_annotation_ids=variables.annotation_id,
								highlight_label="Selected Annotation")>
							<cfif len(trim(variables.conversationSectionHtml)) GT 0>
								#variables.conversationSectionHtml#
							<cfelse>
								<div class="card-body py-1 text-muted small"><em>No replies yet.</em></div>
							</cfif>
						</div>
					</div>
				</div>
			</main>
			</cfoutput>
			<cfinclude template="/shared/_footer.cfm">
		</cfdefaultcase>
	</cfswitch>

<cfcatch>
	<cfif variables.format EQ "html">
		<!--- rethrow the error --->
		<cfthrow type="annotationLoadError" message="Error loading annotation conversation: #cfcatch.message#" detail="#cfcatch.detail#" errorcode="#cfcatch.errorcode#">
		<cfabort>
	<cfelse>
		<cfheader statusCode="500" statusText="Internal Server Error">
		<cfoutput>#encodeForHTML(cfcatch.message)#</cfoutput>
	</cfif>
</cfcatch>
</cftry>
