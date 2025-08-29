<!--- rdf/Taxon.cfm

Copyright 2025 President and Fellows of Harvard College

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
<!--- RDF delivery of dwc:Taxon (taxon_name) records from MCZbase --->

<cfif NOT isDefined("deliver")>
	<cfset deliver = 'application/rdf+xml'>
	<cftry>
   	<cfset accept = GetHttpRequestData().Headers['accept'] >
	<cfcatch>
   	<cfset accept = "application/rdf+xml">
	</cfcatch>
	</cftry>
<cfelse>
	<cfset accept = deliver>
	<cfif accept IS "json" OR accept IS "json-ld">
   	<cfset accept = "application/ld+json">
	<cfelseif accept IS "turtle">
   	<cfset accept = "text/turtle">
	</cfif>
</cfif>
<cfif lookup EQ "uuid">
	<cfif NOT isDefined("uuid")>
		<cfset uuid = "">
	</cfif>
	<cfquery name="lookupUUID" datasource="cf_dbuser" timeout="#Application.short_timeout#">
		SELECT target_table, guid_our_thing_id, taxon_name_id,  guid_is_a, disposition, assembled_resolvable
		FROM guid_our_thing
		WHERE local_identifier = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#uuid#">
			AND scheme = 'urn' 
			AND type = 'uuid'
	</cfquery>
	<cfif lookupUUID.recordCount EQ 0>
		<cfthrow message="UUID not found">
	<cfelse>
		<cfif lookupUUID.guid_is_a NEQ 'materialSampleID'>
			<cfthrow message="UUID does not refer to a material sample">
		<cfelse>
			<cfif lookupUUID.disposition EQ 'deleted'>
				<cfthrow message="Record has been deleted">
			<cfelse>
				<cfquery name="getTaxon" datasource="cf_dbuser" timeout="#Application.short_timeout#">
					SELECT TAXON_NAME_ID,
						PHYLCLASS,
						PHYLORDER,
						SUBORDER,
						FAMILY,
						SUBFAMILY,
						GENUS,
						SUBGENUS,
						SPECIES,
						SUBSPECIES,
						VALID_CATALOG_TERM_FG,
						SOURCE_AUTHORITY,
						FULL_TAXON_NAME,
						SCIENTIFIC_NAME,
						AUTHOR_TEXT,
						TRIBE,
						INFRASPECIFIC_RANK,
						TAXON_REMARKS,
						PHYLUM,
						SUPERFAMILY,
						SUBPHYLUM,
						SUBCLASS,
						KINGDOM,
						NOMENCLATURAL_CODE,
						INFRASPECIFIC_AUTHOR,
						INFRAORDER,
						SUPERORDER,
						DIVISION,
						SUBDIVISION,
						SUPERCLASS,
						DISPLAY_NAME,
						TAXON_STATUS,
						GUID,
						INFRACLASS,
						SUBSECTION,
						TAXONID_GUID_TYPE,
						TAXONID,
						SCIENTIFICNAMEID_GUID_TYPE,
						SCIENTIFICNAMEID,
						YEAR_OF_PUBLICATION,
						ZOOLOGICAL_CHANGED_COMBINATION  
					FROM taxonomy
					WHERE TAXON_NAME_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupUUID.taxon_name_id#">
				</cfquery>
				<cfif getTaxon.recordCount EQ 0>
					<cfthrow message="Taxon record not found">
				</cfif>
			</cfif>
		</cfif>
	</cfif>
<cfelse>
	<cfthrow type="InvalidParameter" message="Invalid lookup type">
</cfif>
<!--- identifiy reqested format --->
<cfset done = false>
<cfloop list='#accept#' delimiters=',' index='a'>
   <cfif NOT done>
       <cfif a IS 'text/turtle' OR a IS 'application/rdf+xml' OR a IS 'application/ld+json'>
          <cfset deliver = a>
          <cfset done = true>
       </cfif>
   </cfif>
</cfloop>
<cfif left(accept,11) IS 'text/turtle'>
   <cfset deliver = "text/turtle">
<cfelseif left(accept,19) IS 'application/rdf+xml'>
   <cfset deliver = "application/rdf+xml">
<cfelseif left(accept,19) IS 'application/ld+json'>
   <cfset deliver = "application/ld+json">
<cfelseif findNoCase("text/turtle", accept) >
   <cfset deliver = "text/turtle">
<cfelseif findNoCase("application/ld+json", accept) >
   <cfset deliver = "application/ld+json">
<cfelse>
   <cfset deliver = 'application/rdf+xml'>
</cfif>
<!--- return RDF in requested format --->
<cfheader name="Content-type" value=#deliver# >
<cfif not isDefined("getTaxon")>
	<cfthrow message="Error: No material sample record found">
</cfif>
<cfloop query="getTaxon">
<cfif deliver IS 'application/rdf+xml'>
<cfoutput><rdf:RDF
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns##"
  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema##"
  xmlns:dwc="http://rs.tdwg.org/dwc/terms/"
  xmlns:dwciri="http://rs.tdwg.org/dwc/iri/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  >
<dwc:Taxon rdf:about="#lookupUUID.assembled_resolvable#">
   <dwc:scientificName>#scientific_name#</dwc:scientificName>
   <dwc:scientificNameAuthorship>#author_text#</dwc:scientificNameAuthorship>
</dwc:Taxon>
</rdf:RDF> </cfoutput>
</cfif><!--- end RDF/XML --->
<cfif deliver IS 'text/turtle'>
<cfoutput>@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns##>.  
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema##>.  
@prefix dwc: <http://rs.tdwg.org/dwc/terms/>.
@prefix dwciri: <http://rs.tdwg.org/dwc/iri/>.
@prefix dcterms: <http://purl.org/dc/terms/>. 
<#lookupUUID.assembled_resolvable#>
   a dwc:Taxon;
   dwc:scientificName "#scientific_name#";
</cfoutput>
</cfif><!--- end Turtle --->
<cfif deliver IS 'application/ld+json'>
<cfoutput>{
  "@context": { 
     "dwc": "http://rs.tdwg.org/dwc/terms/",
     "dwciri": "http://rs.tdwg.org/dwc/iri/",
     "dcterms": "http://purl.org/dc/terms/"
  },
  "@id": "#lookupUUID.assembled_resolvable#",
  "@type":"dwc:Taxon",
  "dwc:scientificName":"#scientific_name#"
}
</cfoutput>
</cfif><!--- end JSON-LD --->
</cfloop>
