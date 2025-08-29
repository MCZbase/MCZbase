<!--- rdf/MaterialSample.cfm

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
<!--- RDF delivery of dwc:MaterialSample (specimen part) records from MCZbase --->
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
		SELECT target_table, guid_our_thing_id, sp_collection_object_id,  guid_is_a, disposition, local_identifier
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
				<!--- TODO: Assumes cataloged item is the occurrence, not true for all material samples, need support for occurrence for  --->
				<cfquery name="getMaterialSample" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
					SELECT specimen_part.COLLECTION_OBJECT_ID COLLECTION_OBJECT_ID,
						specimen_part.PART_NAME PART_NAME,
						specimen_part.PART_MODIFIER PART_MODIFIER,
						specimen_part.SAMPLED_FROM_OBJ_ID SAMPLED_FROM_OBJ_ID,
						specimen_part.PRESERVE_METHOD PRESERVE_METHOD,
						specimen_part.IS_TISSUE IS_TISSUE,
						coll_object.COLL_OBJECT_TYPE COLL_OBJECT_TYPE,
						coll_object.ENTERED_PERSON_ID ENTERED_PERSON_ID,
						coll_object.COLL_OBJECT_ENTERED_DATE COLL_OBJECT_ENTERED_DATE,
						coll_object.LAST_EDITED_PERSON_ID LAST_EDITED_PERSON_ID,
						coll_object.LAST_EDIT_DATE LAST_EDIT_DATE,
						coll_object.COLL_OBJ_DISPOSITION COLL_OBJ_DISPOSITION,
						coll_object.LOT_COUNT LOT_COUNT,
						coll_object.CONDITION CONDITION,
						coll_object.LOT_COUNT_MODIFIER LOT_COUNT_MODIFIER,
						coll_object.CONDITION_REMARKS CONDITION_REMARKS,
						cataloged_item.CAT_NUM CAT_NUM,
						cataloged_item.ACCN_ID ACCN_ID,
						cataloged_item.COLLECTING_EVENT_ID COLLECTING_EVENT_ID,
						cataloged_item.COLLECTION_CDE COLLECTION_CDE,
						cataloged_item.CATALOGED_ITEM_TYPE CATALOGED_ITEM_TYPE,
						collection.institution_acronym institution_acronym,
						flat.guid,
						flat.country,
						flat.state_prov state_province,
						flat.county,
						flat.spec_locality
					FROM specimen_part 
						join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
						join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
						join collection on cataloged_item.collection_id = collection.collection_id
						join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on cataloged_item.collection_object_id = flat.collection_object_id
					WHERE specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupUUID.sp_collection_object_id#">
				</cfquery>
				<cfif getMaterialSample.recordCount EQ 0>
					<cfthrow message="Material sample record not found">
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
<cfif not isDefined("getMaterialSample")>
	<cfthrow message="Error: No material sample record found">
</cfif>
<cfloop query="getMaterialSample">
<cfif deliver IS 'application/rdf+xml'>
<cfoutput><rdf:RDF
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns##"
  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema##"
  xmlns:dwc="http://rs.tdwg.org/dwc/terms/"
  xmlns:dwciri="http://rs.tdwg.org/dwc/iri/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  >
<dwc:MaterialSample rdf:about="https://mczbase.mcz.harvard.edu/uuid/#uuid#">
	<dwc:materialSampleID>#uuid#</dwc:materialSampleID>
	<dwc:preparations>#PART_NAME# (#preserve_method#)</dwc:preparations>
	<dwc:institutionCode>#institution_acronym#</dwc:institutionCode>
	<dwc:collectionCode>#COLLECTION_CDE#</dwc:collectionCode>
	<dwc:catalogNumber>#CAT_NUM#</dwc:catalogNumber>
   <dcterms:rightsHolder>President and Fellows of Harvard College</dcterms:rightsHolder>
	<dwc:locality>#spec_locality#</dwc:locality>
<cfif len(country) GT 0>	<dwc:country>#country#</dwc:country>
</cfif><cfif len(state_province) GT 0>	<dwc:stateProvince>#state_province#</dwc:stateProvince>
</cfif><cfif len(county) GT 0>	<dwc:county>#county#</dwc:county>
</cfif></dwc:MaterialSample>
</rdf:RDF> </cfoutput>
</cfif><!--- end RDF/XML --->
<cfif deliver IS 'text/turtle'>
<cfoutput>@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns##> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema##> .
@prefix dwc: <http://rs.tdwg.org/dwc/terms/> .
@prefix dwciri: <http://rs.tdwg.org/dwc/iri/> .
@prefix dcterms: <http://purl.org/dc/terms/> .
<https://mczbase.mcz.harvard.edu/uuid/#uuid#>
   a dwc:MaterialSample;
	dwc:materialSampleID "#uuid#";
	dwc:preparations "#PART_NAME# (#preserve_method#)";
	dwc:institutionCode "#institution_acronym#";
	dwc:collectionCode "#COLLECTION_CDE#";
	dwc:catalogNumber "#CAT_NUM#";
	dwc:locality "#spec_locality#";
<cfif len(country) GT 0>	dwc:country "#country#";
</cfif><cfif len(state_province) GT 0>	dwc:stateProvince "#state_province#";
</cfif><cfif len(county) GT 0>	dwc:county "#county#";
</cfif>	dcterms:rightsHolder "President and Fellows of Harvard College".
</cfoutput>
</cfif><!--- end Turtle --->
<cfif deliver IS 'application/ld+json'>
<cfoutput>{
  "@context": { 
     "dwc": "http://rs.tdwg.org/dwc/terms/",
     "dwciri": "http://rs.tdwg.org/dwc/iri/",
     "dcterms": "http://purl.org/dc/terms/"
  },
  "@id": "https://mczbase.mcz.harvard.edu/uuid/#uuid#",
  "@type":"dwc:MaterialSample",
  "dwc:materialSampleID": "#uuid#",
  "dwc:preparations": "#PART_NAME# (#preserve_method#)",
  "dwc:institutionCode": "#institution_acronym#",
  "dwc:collectionCode": "#COLLECTION_CDE#",
  "dwc:catalogNumber": "#CAT_NUM#",
  "dwc:locality": "#spec_locality#",
<cfif len(country) GT 0>  "dwc:country": "#country#",
</cfif><cfif len(state_province) GT 0>  "dwc:stateProvince": "#state_province#",
</cfif><cfif len(county) GT 0>  "dwc:county": "#county#",
</cfif>  "dcterms:rightsHolder": "President and Fellows of Harvard College"
}
</cfoutput>
</cfif><!--- end JSON-LD --->
</cfloop>
