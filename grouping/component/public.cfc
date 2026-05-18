<!---
grouping/component/public.cfc

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
<cfcomponent>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- resolveNamedGroupExportFormat determine supported named-group export format.
 @param format explicit requested format (jsonld|ttl|rdfxml).
 @param acceptHeader optional HTTP Accept header fallback when format is blank.
 @return normalized format token (jsonld|ttl|rdfxml) or blank.
--->
<cffunction name="resolveNamedGroupExportFormat" access="public" returntype="string" output="false">
	<cfargument name="format" type="string" required="no" default="">
	<cfargument name="acceptHeader" type="string" required="no" default="">

	<cfset local.formatToken = lcase(trim(arguments.format))>
	<cfset local.acceptToken = lcase(arguments.acceptHeader)>

	<cfif local.formatToken EQ "jsonld" OR local.formatToken EQ "json-ld" OR local.formatToken EQ "ldjson">
		<cfreturn "jsonld">
	<cfelseif local.formatToken EQ "ttl" OR local.formatToken EQ "turtle">
		<cfreturn "ttl">
	<cfelseif local.formatToken EQ "rdfxml" OR local.formatToken EQ "rdf-xml" OR local.formatToken EQ "rdf">
		<cfreturn "rdfxml">
	</cfif>

	<!--- low-risk fallback for requests with no explicit format ---> 
	<cfif len(trim(arguments.format)) EQ 0>
		<cfif findNoCase("application/ld+json", local.acceptToken) GT 0>
			<cfreturn "jsonld">
		<cfelseif findNoCase("text/turtle", local.acceptToken) GT 0>
			<cfreturn "ttl">
		<cfelseif findNoCase("application/rdf+xml", local.acceptToken) GT 0>
			<cfreturn "rdfxml">
		</cfif>
	</cfif>

	<cfreturn "">
</cffunction>

<!--- getNamedGroupLatimerCoreExport build and serialize phase-1 named-group Latimer Core export.
 @param underscore_collection_id primary key for underscore_collection.
 @param oneOfUs 1 if authenticated internal user, otherwise 0.
 @param format normalized format token (jsonld|ttl|rdfxml).
 @return structure with contentType and body.
--->
<cffunction name="getNamedGroupLatimerCoreExport" access="public" returntype="struct" output="false">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="oneOfUs" type="numeric" required="no" default="0">
	<cfargument name="format" type="string" required="yes">

	<cfset local.result = StructNew()>
	<cfset local.model = buildNamedGroupLatimerCoreModel(underscore_collection_id=arguments.underscore_collection_id, oneOfUs=arguments.oneOfUs)>

	<cfif arguments.format EQ "jsonld">
		<cfset local.result.contentType = "application/ld+json; charset=UTF-8">
		<cfset local.result.body = serializeNamedGroupLatimerCoreJSONLD(model=local.model)>
	<cfelseif arguments.format EQ "ttl">
		<cfset local.result.contentType = "text/turtle; charset=UTF-8">
		<cfset local.result.body = serializeNamedGroupLatimerCoreTTL(model=local.model)>
	<cfelse>
		<cfset local.result.contentType = "application/rdf+xml; charset=UTF-8">
		<cfset local.result.body = serializeNamedGroupLatimerCoreRDFXML(model=local.model)>
	</cfif>

	<cfreturn local.result>
</cffunction>

<!--- buildNamedGroupLatimerCoreModel create common phase-1 model for named-group RDF serializers.
 @param underscore_collection_id primary key for underscore_collection.
 @param oneOfUs 1 if authenticated internal user, otherwise 0.
 @return structure with phase-1 named-group summary model.
--->
<cffunction name="buildNamedGroupLatimerCoreModel" access="public" returntype="struct" output="false">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="oneOfUs" type="numeric" required="no" default="0">

	<cfset local.model = StructNew()>
	<cfset local.model.agents = ArrayNew(1)>
	<cfset local.model.taxonomicContexts = ArrayNew(1)>
	<cfset local.model.geographicContexts = ArrayNew(1)>
	<cfset local.model.citations = ArrayNew(1)>

	<cfquery name="local.namedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
		SELECT underscore_collection_id, collection_name, description, html_description, underscore_collection_type
		FROM underscore_collection
		WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.underscore_collection_id#">
		<cfif arguments.oneOfUs EQ 0>
			AND mask_fg = 0
		</cfif>
	</cfquery>
	<cfif local.namedGroup.recordcount NEQ 1>
		<cfthrow message="Named group not recognized.">
	</cfif>

	<cfset local.model.uri = "#Application.serverRootUrl#/namedGroup/#encodeForURL(local.namedGroup.underscore_collection_id)#">
	<cfset local.model.identifier = local.namedGroup.underscore_collection_id>
	<cfset local.model.collectionName = local.namedGroup.collection_name>
	<cfset local.model.description = local.namedGroup.description>
	<cfset local.model.typeMapping = mapNamedGroupTypeToLatimer(groupType=local.namedGroup.underscore_collection_type)>
	<!--- html_description intentionally omitted from phase 1 RDF to avoid exposing raw untrusted HTML markup. --->

	<cfquery name="local.objectCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
		SELECT count(distinct collection_object_id) as ct
		FROM underscore_relation
		WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.underscore_collection_id#">
	</cfquery>
	<cfset local.model.objectCount = val(local.objectCount.ct)>

	<cfquery name="local.agentQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
		SELECT underscore_collection_agent.agent_id,
			MCZBASE.get_agentnameoftype(underscore_collection_agent.agent_id, 'preferred') as agent_name,
			nvl(ctunderscore_coll_agent_role.label, underscore_collection_agent.role) as role_label,
			underscore_collection_agent.remarks,
			ctunderscore_coll_agent_role.ordinal
		FROM underscore_collection_agent
			LEFT JOIN ctunderscore_coll_agent_role ON underscore_collection_agent.role = ctunderscore_coll_agent_role.role
		WHERE underscore_collection_agent.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.underscore_collection_id#">
		ORDER BY ctunderscore_coll_agent_role.ordinal ASC, MCZBASE.get_agentnameoftype(underscore_collection_agent.agent_id, 'preferred') ASC
	</cfquery>
	<cfloop query="local.agentQuery">
		<cfset local.agent = StructNew()>
		<cfset local.agent.uri = "#Application.serverRootUrl#/agents/Agent.cfm?agent_id=#encodeForURL(local.agentQuery.agent_id)#">
		<cfset local.agent.agentName = local.agentQuery.agent_name>
		<cfset local.agent.roleLabel = local.agentQuery.role_label>
		<cfset local.agent.remarks = local.agentQuery.remarks>
		<cfset ArrayAppend(local.model.agents, local.agent)>
	</cfloop>

	<cfquery name="local.totalTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
		SELECT count(distinct flat.phylclass) as ct
		FROM underscore_relation
			JOIN <cfif ucase(session.flatTableName) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat ON underscore_relation.collection_object_id = flat.collection_object_id
		WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.underscore_collection_id#">
			AND flat.phylclass IS NOT NULL
	</cfquery>
	<cfset local.model.totalTaxonClasses = val(local.totalTaxa.ct)>

	<cfquery name="local.taxonCoverageQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT * FROM (
			SELECT flat.phylclass as label, count(distinct flat.collection_object_id) as ct
			FROM underscore_relation
				JOIN <cfif ucase(session.flatTableName) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat ON underscore_relation.collection_object_id = flat.collection_object_id
			WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.underscore_collection_id#">
				AND flat.phylclass IS NOT NULL
			GROUP BY flat.phylclass
			ORDER BY count(distinct flat.collection_object_id) DESC, flat.phylclass ASC
		) WHERE rownum <= 25
	</cfquery>
	<cfloop query="local.taxonCoverageQuery">
		<cfset local.context = StructNew()>
		<cfset local.context.className = local.taxonCoverageQuery.label>
		<cfset local.context.objectCount = val(local.taxonCoverageQuery.ct)>
		<cfset ArrayAppend(local.model.taxonomicContexts, local.context)>
	</cfloop>

	<cfquery name="local.totalCountries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
		SELECT count(distinct flat.country) as ct
		FROM underscore_relation
			JOIN <cfif ucase(session.flatTableName) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat ON underscore_relation.collection_object_id = flat.collection_object_id
		WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.underscore_collection_id#">
			AND flat.country IS NOT NULL
	</cfquery>
	<cfset local.model.totalCountries = val(local.totalCountries.ct)>

	<cfquery name="local.geogCoverageQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT * FROM (
			SELECT flat.country as label, count(distinct flat.collection_object_id) as ct
			FROM underscore_relation
				JOIN <cfif ucase(session.flatTableName) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat ON underscore_relation.collection_object_id = flat.collection_object_id
			WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.underscore_collection_id#">
				AND flat.country IS NOT NULL
			GROUP BY flat.country
			ORDER BY count(distinct flat.collection_object_id) DESC, flat.country ASC
		) WHERE rownum <= 25
	</cfquery>
	<cfloop query="local.geogCoverageQuery">
		<cfset local.context = StructNew()>
		<cfset local.context.country = local.geogCoverageQuery.label>
		<cfset local.context.objectCount = val(local.geogCoverageQuery.ct)>
		<cfset ArrayAppend(local.model.geographicContexts, local.context)>
	</cfloop>

	<cfquery name="local.stateProvCoverageQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
		SELECT * FROM (
			SELECT flat.country, flat.state_prov, count(distinct flat.collection_object_id) as ct
			FROM underscore_relation
				JOIN <cfif ucase(session.flatTableName) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat ON underscore_relation.collection_object_id = flat.collection_object_id
			WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.underscore_collection_id#">
				AND flat.country IS NOT NULL
				AND flat.state_prov IS NOT NULL
			GROUP BY flat.country, flat.state_prov
			ORDER BY count(distinct flat.collection_object_id) DESC, flat.country ASC, flat.state_prov ASC
		) WHERE rownum <= 25
	</cfquery>
	<cfloop query="local.stateProvCoverageQuery">
		<cfset local.context = StructNew()>
		<cfset local.context.country = local.stateProvCoverageQuery.country>
		<cfset local.context.stateProvince = local.stateProvCoverageQuery.state_prov>
		<cfset local.context.objectCount = val(local.stateProvCoverageQuery.ct)>
		<cfset ArrayAppend(local.model.geographicContexts, local.context)>
	</cfloop>

	<cfquery name="local.continentOceanCoverageQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
		SELECT * FROM (
			SELECT flat.continent_ocean as label, count(distinct flat.collection_object_id) as ct
			FROM underscore_relation
				JOIN <cfif ucase(session.flatTableName) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat ON underscore_relation.collection_object_id = flat.collection_object_id
			WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.underscore_collection_id#">
				AND flat.continent_ocean LIKE '%Ocean%'
				AND flat.continent_ocean NOT LIKE '%Oceania%'
			GROUP BY flat.continent_ocean
			ORDER BY count(distinct flat.collection_object_id) DESC, flat.continent_ocean ASC
		) WHERE rownum <= 25
	</cfquery>
	<cfloop query="local.continentOceanCoverageQuery">
		<cfset local.context = StructNew()>
		<cfset local.context.waterBody = local.continentOceanCoverageQuery.label>
		<cfset local.context.objectCount = val(local.continentOceanCoverageQuery.ct)>
		<cfset ArrayAppend(local.model.geographicContexts, local.context)>
	</cfloop>

	<cfquery name="local.directCitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT * FROM (
			SELECT publication_id, MCZBASE.getshortcitation(publication_id) as short_citation, type, remarks
			FROM underscore_collection_citation
			WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.underscore_collection_id#">
			ORDER BY type, MCZBASE.getshortcitation(publication_id)
		) WHERE rownum <= 25
	</cfquery>
	<cfloop query="local.directCitations">
		<cfset local.citation = StructNew()>
		<cfset local.citation.uri = "#Application.serverRootUrl#/publications/showPublication.cfm?publication_id=#encodeForURL(local.directCitations.publication_id)#">
		<cfset local.citation.shortCitation = local.directCitations.short_citation>
		<cfset local.citation.citationType = local.directCitations.type>
		<cfset local.citation.remarks = local.directCitations.remarks>
		<cfset ArrayAppend(local.model.citations, local.citation)>
	</cfloop>

	<cfset local.model.citationScopeNote = "Phase 1 export includes direct named-group citations only. Member-by-member citation expansion is omitted for performance.">
	<cfreturn local.model>
</cffunction>

<!--- serializeNamedGroupLatimerCoreJSONLD serialize phase-1 model as JSON-LD.
 @param model structure from buildNamedGroupLatimerCoreModel.
 @return JSON-LD document string.
--->
<cffunction name="serializeNamedGroupLatimerCoreJSONLD" access="private" returntype="string" output="false">
	<cfargument name="model" type="struct" required="yes">

	<cfset local.doc = StructNew()>
	<cfset local.context = StructNew()>
	<cfset local.context["ltc"] = "https://ltc.tdwg.org/terms/">
	<cfset local.context["dcterms"] = "http://purl.org/dc/terms/">
	<cfset local.context["prov"] = "http://www.w3.org/ns/prov##">
	<cfset local.context["schema"] = "https://schema.org/">
	<cfset local.context["skos"] = "http://www.w3.org/2004/02/skos/core##">
	<cfset local.context["rdfs"] = "http://www.w3.org/2000/01/rdf-schema##">
	<cfset local.context["xsd"] = "http://www.w3.org/2001/XMLSchema##">
	<cfset local.context["mcz"] = "#Application.serverRootUrl#/vocab/">
	<cfset local.doc["@context"] = local.context>
	<cfset local.doc["@id"] = arguments.model.uri>
	<cfset local.doc["@type"] = "ltc:ObjectGroup">
	<cfset local.doc["dcterms:identifier"] = arguments.model.identifier>
	<cfset local.doc["dcterms:title"] = arguments.model.collectionName>
	<cfif len(arguments.model.description) GT 0>
		<cfset local.doc["dcterms:description"] = arguments.model.description>
	</cfif>
	<cfset local.doc["dcterms:type"] = arguments.model.typeMapping.typeLabel>
	<cfset local.doc["schema:count"] = arguments.model.objectCount>
	<cfset local.doc["schema:additionalProperty"] = ArrayNew(1)>
	<cfset local.totalTaxonClassesProp = StructNew()>
	<cfset local.totalTaxonClassesProp["@type"] = "schema:PropertyValue">
	<cfset local.totalTaxonClassesProp["schema:propertyID"] = "totalTaxonClasses">
	<cfset local.totalTaxonClassesProp["schema:value"] = arguments.model.totalTaxonClasses>
	<cfset ArrayAppend(local.doc["schema:additionalProperty"], local.totalTaxonClassesProp)>
	<cfset local.totalCountriesProp = StructNew()>
	<cfset local.totalCountriesProp["@type"] = "schema:PropertyValue">
	<cfset local.totalCountriesProp["schema:propertyID"] = "totalCountries">
	<cfset local.totalCountriesProp["schema:value"] = arguments.model.totalCountries>
	<cfset ArrayAppend(local.doc["schema:additionalProperty"], local.totalCountriesProp)>
	<cfset local.doc["skos:scopeNote"] = arguments.model.citationScopeNote>

	<cfset local.doc["mcz:associatedAgent"] = ArrayNew(1)>
	<cfloop array="#arguments.model.agents#" index="local.agent">
		<cfset local.agentStruct = StructNew()>
		<cfset local.agentStruct["@id"] = local.agent.uri>
		<cfset local.agentStruct["schema:name"] = local.agent.agentName>
		<cfset local.agentStruct["schema:roleName"] = local.agent.roleLabel>
		<cfset local.agentStruct["dcterms:description"] = local.agent.remarks>
		<cfset ArrayAppend(local.doc["mcz:associatedAgent"], local.agentStruct)>
	</cfloop>

	<cfset local.doc["ltc:taxonomicCoverage"] = ArrayNew(1)>
	<cfloop array="#arguments.model.taxonomicContexts#" index="local.context">
		<cfset local.contextStruct = StructNew()>
		<cfset local.contextStruct["@type"] = "ltc:TaxonomicContext">
		<cfset local.contextStruct["ltc:class"] = local.context.className>
		<cfset local.contextStruct["schema:count"] = local.context.objectCount>
		<cfset ArrayAppend(local.doc["ltc:taxonomicCoverage"], local.contextStruct)>
	</cfloop>

	<cfset local.doc["ltc:geographicCoverage"] = ArrayNew(1)>
	<cfloop array="#arguments.model.geographicContexts#" index="local.context">
		<cfset local.contextStruct = StructNew()>
		<cfset local.contextStruct["@type"] = "ltc:GeographicContext">
		<cfif structKeyExists(local.context, "country") AND len(local.context.country) GT 0>
			<cfset local.contextStruct["ltc:country"] = local.context.country>
		</cfif>
		<cfif structKeyExists(local.context, "stateProvince") AND len(local.context.stateProvince) GT 0>
			<cfset local.contextStruct["ltc:stateProvince"] = local.context.stateProvince>
		</cfif>
		<cfif structKeyExists(local.context, "waterBody") AND len(local.context.waterBody) GT 0>
			<cfset local.contextStruct["ltc:waterBody"] = local.context.waterBody>
		</cfif>
		<cfset local.contextStruct["schema:count"] = local.context.objectCount>
		<cfset ArrayAppend(local.doc["ltc:geographicCoverage"], local.contextStruct)>
	</cfloop>

	<cfset local.doc["dcterms:bibliographicCitation"] = ArrayNew(1)>
	<cfloop array="#arguments.model.citations#" index="local.citation">
		<cfset local.citationStruct = StructNew()>
		<cfset local.citationStruct["@id"] = local.citation.uri>
		<cfset local.citationStruct["rdfs:label"] = local.citation.shortCitation>
		<cfset local.citationStruct["schema:additionalType"] = local.citation.citationType>
		<cfset local.citationStruct["dcterms:description"] = local.citation.remarks>
		<cfset ArrayAppend(local.doc["dcterms:bibliographicCitation"], local.citationStruct)>
	</cfloop>

	<cfreturn serializeJSON(local.doc)>
</cffunction>

<!--- serializeNamedGroupLatimerCoreTTL serialize phase-1 model as Turtle.
 @param model structure from buildNamedGroupLatimerCoreModel.
 @return Turtle document string.
--->
<cffunction name="serializeNamedGroupLatimerCoreTTL" access="private" returntype="string" output="false">
	<cfargument name="model" type="struct" required="yes">

	<cfset local.lines = ArrayNew(1)>
	<cfset local.preds = ArrayNew(1)>

	<cfset ArrayAppend(local.lines, "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns##> .")>
	<cfset ArrayAppend(local.lines, "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema##> .")>
	<cfset ArrayAppend(local.lines, "@prefix dcterms: <http://purl.org/dc/terms/> .")>
	<cfset ArrayAppend(local.lines, "@prefix prov: <http://www.w3.org/ns/prov##> .")>
	<cfset ArrayAppend(local.lines, "@prefix schema: <https://schema.org/> .")>
	<cfset ArrayAppend(local.lines, "@prefix skos: <http://www.w3.org/2004/02/skos/core##> .")>
	<cfset ArrayAppend(local.lines, "@prefix xsd: <http://www.w3.org/2001/XMLSchema##> .")>
	<cfset ArrayAppend(local.lines, "@prefix ltc: <https://ltc.tdwg.org/terms/> .")>
	<cfset ArrayAppend(local.lines, "@prefix mcz: <#Application.serverRootUrl#/vocab/> .")>
	<cfset ArrayAppend(local.lines, "")>

	<cfset ArrayAppend(local.preds, "a ltc:ObjectGroup")>
	<cfset ArrayAppend(local.preds, 'dcterms:identifier "' & escapeForTurtleLiteral(arguments.model.identifier) & '"')>
	<cfset ArrayAppend(local.preds, 'dcterms:title "' & escapeForTurtleLiteral(arguments.model.collectionName) & '"')>
	<cfif len(arguments.model.description) GT 0>
		<cfset ArrayAppend(local.preds, 'dcterms:description "' & escapeForTurtleLiteral(arguments.model.description) & '"')>
	</cfif>
	<cfset ArrayAppend(local.preds, 'dcterms:type "' & escapeForTurtleLiteral(arguments.model.typeMapping.typeLabel) & '"')>
	<cfset ArrayAppend(local.preds, 'schema:count "' & arguments.model.objectCount & '"^^xsd:integer')>
	<cfset ArrayAppend(local.preds, 'schema:additionalProperty [ a schema:PropertyValue ; schema:propertyID "totalTaxonClasses" ; schema:value "' & arguments.model.totalTaxonClasses & '"^^xsd:integer ]')>
	<cfset ArrayAppend(local.preds, 'schema:additionalProperty [ a schema:PropertyValue ; schema:propertyID "totalCountries" ; schema:value "' & arguments.model.totalCountries & '"^^xsd:integer ]')>
	<cfset ArrayAppend(local.preds, 'skos:scopeNote "' & escapeForTurtleLiteral(arguments.model.citationScopeNote) & '"')>

	<cfloop array="#arguments.model.agents#" index="local.agent">
		<cfset local.node = '[ a prov:Association ; prov:agent <' & local.agent.uri & '> ; schema:name "' & escapeForTurtleLiteral(local.agent.agentName) & '" ; schema:roleName "' & escapeForTurtleLiteral(local.agent.roleLabel) & '"' >
		<cfif len(local.agent.remarks) GT 0>
			<cfset local.node = local.node & ' ; dcterms:description "' & escapeForTurtleLiteral(local.agent.remarks) & '"' >
		</cfif>
		<cfset local.node = local.node & " ]">
		<cfset ArrayAppend(local.preds, "mcz:associatedAgent " & local.node)>
	</cfloop>

	<cfloop array="#arguments.model.taxonomicContexts#" index="local.context">
		<cfset local.node = '[ a ltc:TaxonomicContext ; ltc:class "' & escapeForTurtleLiteral(local.context.className) & '" ; schema:count "' & local.context.objectCount & '"^^xsd:integer ]'>
		<cfset ArrayAppend(local.preds, "ltc:taxonomicCoverage " & local.node)>
	</cfloop>
	<cfloop array="#arguments.model.geographicContexts#" index="local.context">
		<cfset local.contextPredicates = ArrayNew(1)>
		<cfset ArrayAppend(local.contextPredicates, "a ltc:GeographicContext")>
		<cfif structKeyExists(local.context, "country") AND len(local.context.country) GT 0>
			<cfset ArrayAppend(local.contextPredicates, 'ltc:country "' & escapeForTurtleLiteral(local.context.country) & '"')>
		</cfif>
		<cfif structKeyExists(local.context, "stateProvince") AND len(local.context.stateProvince) GT 0>
			<cfset ArrayAppend(local.contextPredicates, 'ltc:stateProvince "' & escapeForTurtleLiteral(local.context.stateProvince) & '"')>
		</cfif>
		<cfif structKeyExists(local.context, "waterBody") AND len(local.context.waterBody) GT 0>
			<cfset ArrayAppend(local.contextPredicates, 'ltc:waterBody "' & escapeForTurtleLiteral(local.context.waterBody) & '"')>
		</cfif>
		<cfset ArrayAppend(local.contextPredicates, 'schema:count "' & local.context.objectCount & '"^^xsd:integer')>
		<cfset local.node = "[ " & ArrayToList(local.contextPredicates, " ; ") & " ]">
		<cfset ArrayAppend(local.preds, "ltc:geographicCoverage " & local.node)>
	</cfloop>
	<cfloop array="#arguments.model.citations#" index="local.citation">
		<cfset local.node = '[ rdf:value "' & escapeForTurtleLiteral(local.citation.shortCitation) & '" ; schema:additionalType "' & escapeForTurtleLiteral(local.citation.citationType) & '" ; dcterms:identifier <' & local.citation.uri & '>'>
		<cfif len(local.citation.remarks) GT 0>
			<cfset local.node = local.node & ' ; dcterms:description "' & escapeForTurtleLiteral(local.citation.remarks) & '"' >
		</cfif>
		<cfset local.node = local.node & " ]">
		<cfset ArrayAppend(local.preds, "dcterms:bibliographicCitation " & local.node)>
	</cfloop>

	<cfset ArrayAppend(local.lines, "<" & arguments.model.uri & ">")>
	<cfset local.i = 1>
	<cfloop array="#local.preds#" index="local.predicateLine">
		<cfif local.i LT ArrayLen(local.preds)>
			<cfset ArrayAppend(local.lines, chr(9) & local.predicateLine & " ;")>
		<cfelse>
			<cfset ArrayAppend(local.lines, chr(9) & local.predicateLine & " .")>
		</cfif>
		<cfset local.i = local.i + 1>
	</cfloop>

	<cfreturn ArrayToList(local.lines, chr(10))>
</cffunction>

<!--- serializeNamedGroupLatimerCoreRDFXML serialize phase-1 model as RDF/XML.
 @param model structure from buildNamedGroupLatimerCoreModel.
 @return RDF/XML document string.
--->
<cffunction name="serializeNamedGroupLatimerCoreRDFXML" access="private" returntype="string" output="false">
	<cfargument name="model" type="struct" required="yes">

	<cfsavecontent variable="local.rdfxml"><cfoutput><?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns##"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema##"
	xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:prov="http://www.w3.org/ns/prov##"
	xmlns:schema="https://schema.org/"
	xmlns:skos="http://www.w3.org/2004/02/skos/core##"
	xmlns:ltc="https://ltc.tdwg.org/terms/"
	xmlns:mcz="#xmlFormat(Application.serverRootUrl)#/vocab/"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema##">
	<ltc:ObjectGroup rdf:about="#xmlFormat(arguments.model.uri)#">
		<dcterms:identifier>#xmlFormat(arguments.model.identifier)#</dcterms:identifier>
		<dcterms:title>#xmlFormat(arguments.model.collectionName)#</dcterms:title>
<cfif len(arguments.model.description) GT 0>
		<dcterms:description>#xmlFormat(arguments.model.description)#</dcterms:description>
</cfif>
		<dcterms:type>#xmlFormat(arguments.model.typeMapping.typeLabel)#</dcterms:type>
		<schema:count rdf:datatype="xsd:integer">#arguments.model.objectCount#</schema:count>
		<schema:additionalProperty>
			<schema:PropertyValue>
				<schema:propertyID>totalTaxonClasses</schema:propertyID>
				<schema:value rdf:datatype="xsd:integer">#arguments.model.totalTaxonClasses#</schema:value>
			</schema:PropertyValue>
		</schema:additionalProperty>
		<schema:additionalProperty>
			<schema:PropertyValue>
				<schema:propertyID>totalCountries</schema:propertyID>
				<schema:value rdf:datatype="xsd:integer">#arguments.model.totalCountries#</schema:value>
			</schema:PropertyValue>
		</schema:additionalProperty>
		<skos:scopeNote>#xmlFormat(arguments.model.citationScopeNote)#</skos:scopeNote>
<cfloop array="#arguments.model.agents#" index="local.agent">
		<mcz:associatedAgent>
			<prov:Association>
				<prov:agent rdf:resource="#xmlFormat(local.agent.uri)#" />
				<schema:name>#xmlFormat(local.agent.agentName)#</schema:name>
				<schema:roleName>#xmlFormat(local.agent.roleLabel)#</schema:roleName>
<cfif len(local.agent.remarks) GT 0>
				<dcterms:description>#xmlFormat(local.agent.remarks)#</dcterms:description>
</cfif>
			</prov:Association>
		</mcz:associatedAgent>
</cfloop>
<cfloop array="#arguments.model.taxonomicContexts#" index="local.context">
		<ltc:taxonomicCoverage>
			<ltc:TaxonomicContext>
				<ltc:class>#xmlFormat(local.context.className)#</ltc:class>
				<schema:count rdf:datatype="xsd:integer">#local.context.objectCount#</schema:count>
			</ltc:TaxonomicContext>
		</ltc:taxonomicCoverage>
</cfloop>
<cfloop array="#arguments.model.geographicContexts#" index="local.context">
		<ltc:geographicCoverage>
			<ltc:GeographicContext>
<cfif structKeyExists(local.context, "country") AND len(local.context.country) GT 0>
					<ltc:country>#xmlFormat(local.context.country)#</ltc:country>
</cfif>
<cfif structKeyExists(local.context, "stateProvince") AND len(local.context.stateProvince) GT 0>
					<ltc:stateProvince>#xmlFormat(local.context.stateProvince)#</ltc:stateProvince>
</cfif>
<cfif structKeyExists(local.context, "waterBody") AND len(local.context.waterBody) GT 0>
					<ltc:waterBody>#xmlFormat(local.context.waterBody)#</ltc:waterBody>
</cfif>
				<schema:count rdf:datatype="xsd:integer">#local.context.objectCount#</schema:count>
			</ltc:GeographicContext>
		</ltc:geographicCoverage>
</cfloop>
<cfloop array="#arguments.model.citations#" index="local.citation">
		<dcterms:bibliographicCitation>
			<rdf:Description>
				<rdf:value>#xmlFormat(local.citation.shortCitation)#</rdf:value>
				<schema:additionalType>#xmlFormat(local.citation.citationType)#</schema:additionalType>
				<dcterms:identifier rdf:resource="#xmlFormat(local.citation.uri)#" />
<cfif len(local.citation.remarks) GT 0>
				<dcterms:description>#xmlFormat(local.citation.remarks)#</dcterms:description>
</cfif>
			</rdf:Description>
		</dcterms:bibliographicCitation>
</cfloop>
	</ltc:ObjectGroup>
</rdf:RDF></cfoutput></cfsavecontent>
	<cfreturn trim(local.rdfxml)>
</cffunction>

<!--- mapNamedGroupTypeToLatimer provide pragmatic local mapping for underscore_collection_type.
 @param groupType underscore_collection.underscore_collection_type value.
 @return structure with typeUri and typeLabel keys.
--->
<cffunction name="mapNamedGroupTypeToLatimer" access="private" returntype="struct" output="false">
	<cfargument name="groupType" type="string" required="yes">

	<cfset local.mapping = StructNew()>
	<cfset local.mapping.typeLabel = trim(arguments.groupType)>
	<cfif len(local.mapping.typeLabel) EQ 0>
		<cfset local.mapping.typeLabel = "unspecified">
	</cfif>
	<cfset local.mapping.typeUri = "#Application.serverRootUrl#/vocab/namedGroupType/#encodeForURL(local.mapping.typeLabel)#">
	<cfreturn local.mapping>
</cffunction>

<!--- escapeForTurtleLiteral escape literals for Turtle output.
 @param value text value to escape.
 @return escaped text safe for quoted Turtle literal.
--->
<cffunction name="escapeForTurtleLiteral" access="private" returntype="string" output="false">
	<cfargument name="value" type="string" required="yes">

	<cfset local.escaped = arguments.value>
	<cfset local.escaped = replace(local.escaped, "\", "\" & "\", "all")>
	<cfset local.escaped = replace(local.escaped, chr(34), "\" & chr(34), "all")>
	<cfset local.escaped = replace(local.escaped, chr(13) & chr(10), "\n", "all")>
	<cfset local.escaped = replace(local.escaped, chr(10), "\n", "all")>
	<cfset local.escaped = replace(local.escaped, chr(13), "\n", "all")>
	<cfreturn local.escaped>
</cffunction>

</cfcomponent>
