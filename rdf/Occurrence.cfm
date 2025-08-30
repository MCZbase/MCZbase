<!--- rdf/Occurrence.cfm

Copyright 2019-2025 President and Fellows of Harvard College

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
<!--- RDF delivery of dwc:Occurrence records (both cataloged items and specimen parts with identification histories) from MCZbase --->
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
<!--- support direct request for page without paramters for testing, returns as if lookup=guid, guid=MCZ:IP:100000 --->
<cfif NOT isDefined("lookup")>
	<cfset lookup = "guid">
</cfif>
<cfset lookupDetermination = false>
<cfif lookup EQ "guid">
	<cfif NOT isdefined("guid")>
   	<cfset guid="MCZ:IP:100000">
	</cfif>
<cfelseif lookup EQ "uuid">
	<cfif NOT isDefined("uuid")>
		<cfset uuid = "">
	</cfif>
	<cfquery name="lookupUUID" datasource="cf_dbuser" timeout="#Application.short_timeout#">
		SELECT target_table, guid_our_thing_id, co_collection_object_id,  guid_is_a, disposition, assembled_resolvable
		FROM guid_our_thing
		WHERE local_identifier = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#uuid#">
			AND scheme = 'urn' 
			AND type = 'uuid'
	</cfquery>
	<!--- if target table is coll_object and guid_is_a is occurrenceID then lookup institution code, collection code, cat num and redirect to /guid/ --->
	<cfif lookupUUID.recordcount EQ 0>
		<cfthrow message="UUID not found" detail="No record found in guid_our_thing table for UUID #uuid#">
	<cfelseif lookupUUID.recordcount GT 0>
		<cfif lookupUUID.disposition IS "exists" AND lookupUUID.target_table IS "COLL_OBJECT" AND lookupUUID.guid_is_a IS "occurrenceID">
			<!--- lookup the cataloged item for the occurrence and redirect to it with /guid/{institution_code}:{collection_code}:{catalog_number} --->
			<!--- type of coll_object should be "SP", check this and lookup from parent cataloged item --->
			<cfquery name="getCatItem" datasource="uam_god" timeout="#Application.short_timeout#" result="getCatItem.result">
				SELECT coll_object.coll_object_type, 
					coll.institution_acronym || ':' || coll.collection_cde || ':' || ci.cat_num guid
				FROM coll_object 
				left join specimen_part on coll_object.collection_object_id = specimen_part.collection_object_id
				left join cataloged_item ci on specimen_part.derived_from_cat_item = ci.collection_object_id
				LEFT JOIN collection coll ON ci.collection_id = coll.collection_id
				WHERE coll_object.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupUUID.co_collection_object_id#">
			</cfquery>
			<cfset guid = getCatItem.guid>
			<cfset lookupDetermination = true>
		<cfelseif lookupUUID.disposition IS "exists" AND lookupUUID.target_table IS "SPECIMEN_PART" AND lookupUUID.guid_is_a IS "materialSampleID">
			<!--- use materialSampleID RDF handler --->
			<cfinclude template="/rdf/MaterialSample.cfm">
			<cfabort>
		<cfelse>
			<cfthrow message = "unsupported dispostion or other condition">
		</cfif>
	</cfif>
<cfelse>
	<cfthrow message="Unknown Lookup Type"> 
</cfif>
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

<cfheader name="Content-type" value=#deliver# >

<!--- TODO: lookup the guid from the guid_our_thing table --->
<!--- TODO: Fix: If given the /guid/ of a specimen with multiple occurrences, return only the material samples belonging to that occurrence --->
<!--- TODO: Fix: If given the /uuid/ of an additional occurrance in a mixed collection, return the correct occurrence including identification and material sample --->
<cfquery name="occur" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT distinct 
		flat.collection_object_id,
		flat.cat_num, 
		flat.collection_cde, 
		<cfif lookup EQ "guid">
			'https://mczbase.mcz.harvard.edu/guid/' || flat.guid resolvable_guid, 
		<cfelse>
			'#lookupUUID.assembled_resolvable#' as resolvable_guid,
		</cfif>
		flat.basisofrecord,	
		flat.country, 
		flat.state_prov, 
		flat.county, 
		flat.spec_locality,
		flat.highergeographyid,
		trim(flat.scientific_name || ' ' || flat.author_text) as scientific_name,
		flat.taxonid,
		flat.scientificnameid,
		flat.identifiedby,
		flat.identifiedbyid,
		REPLACE(REPLACE(flat.typestatusplain,'<i>'),'</i>') AS typestatus,
		flat.author_text,
		flat.collectors,
		flat.recordedbyid,
    	(case when began_date > '1700-01-01' then began_date else '' end) as began_date,
    	(case when began_date > '1700-01-01' then ended_date else '' end) as ended_date,
		(case when began_date > '1700-01-01' then regexp_substr(began_date, '([0-9]{4})',1,1,'i',1) else '' end) as year,
		(case when began_date > '1700-01-01' then regexp_substr(began_date, '([0-9]{4})-([0-9]{2})',1,1,'i',2) else'' end) as month,
		(case when began_date > '1700-01-01' then regexp_substr(began_date, '([0-9]{4})-([0-9]{2})-([0-9]{2})',1,1,'i',3) else '' end) as day,
		flat.geol_group,
		flat.formation,
		flat.member,
		flat.bed,
		flat.EARLIESTERAORLOWESTERATHEM,
		flat.LATESTERAORHIGHESTERATHEM,
		flat.EARLIESTPERIODORLOWESTSYSTEM,
		flat.LATESTPERIODORHIGHESTSYSTEM,
		flat.EARLIESTEPOCHORLOWESTSERIES,
		flat.LATESTEPOCHORHIGHESTSERIES,
		flat.EARLIESTAGEORLOWESTSTAGE,
		flat.LATESTAGEORHIGHESTSTAGE,
		flat.LITHOSTRATIGRAPHICTERMS,
		flat.dec_lat,
		flat.dec_long,
		flat.datum as geodeticdatum,
		flat.coordinateuncertaintyinmeters,
		flat.georeferencedbyid,
		flat.last_edit_date
	FROM coll_object 
		left join specimen_part on coll_object.collection_object_id = specimen_part.collection_object_id
		left join cataloged_item ci on specimen_part.derived_from_cat_item = ci.collection_object_id
		left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on ci.collection_object_id = flat.collection_object_id
	WHERE
		<cfif lookup EQ 'guid'>
			flat.guid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guid#"> 
		<cfelse> 
			coll_object.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupUUID.co_collection_object_id#">
		</cfif>
		and rownum < 2
</cfquery>

<cfif occur.began_date EQ occur.ended_date OR len(occur.ended_date) EQ 0>
	<cfset eventDate = occur.began_date>
<cfelse>
	<cfset eventDate = "#occur.began_date/occur.ended_date#">
</cfif>

<cfloop query=occur>
<cfquery name="colls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT 
		agentguid
	FROM
		collector
		left join agent on collector.agent_id = agent.agent_id
	WHERE
		collector.collection_object_id = <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#occur.collection_object_id#">
		and collector.collector_role = 'c'
		and agentguid is not null
	ORDER BY 
		collector.coll_order
</cfquery>
<cfquery name="parts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT 
		part_name, preserve_method, 
		assembled_resolvable materialSampleID
	FROM
		specimen_part
		join guid_our_thing on specimen_part.collection_object_id = guid_our_thing.sp_collection_object_id
	WHERE
		derived_from_cat_item = <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#occur.collection_object_id#">
</cfquery>
<cfif deliver IS 'application/rdf+xml'>
<cfoutput><rdf:RDF
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns##"
  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema##"
  xmlns:dwc="http://rs.tdwg.org/dwc/terms/"
  xmlns:dwciri="http://rs.tdwg.org/dwc/iri/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  >
<dwc:Occurrence rdf:about="#resolvable_guid#">
   <dwc:institutionCode>MCZ</dwc:institutionCode>
   <dwc:collectionCode>#collection_cde#</dwc:collectionCode>
   <dwc:catalogNumber>#cat_num#</dwc:catalogNumber>
   <dwc:basisOfRecord>#basisofrecord#</dwc:basisOfRecord>
   <dcterms:rightsHolder>President and Fellows of Harvard College</dcterms:rightsHolder>
   <dwc:scientificName>#scientific_name#</dwc:scientificName>
   <dwc:scientificNameAuthorship>#author_text#</dwc:scientificNameAuthorship>
   <dwc:taxonID>#taxonid#</dwc:taxonID>
   <dwc:scientificNameID>#scientificnameid#</dwc:scientificNameID>
   <dwc:identifiedBy>#identifiedby#</dwc:identifiedBy>
   <dwciri:identifiedBy>#identifiedbyid#</dwciri:identifiedBy>
<cfif len(typestatus) GT 0>   <dwc:typeStatus>#typestatus#</dwc:typeStatus>
</cfif>   <dwc:country>#country#</dwc:country>
   <dwc:stateProvince>#state_prov#</dwc:stateProvince>
   <dwc:locality>#spec_locality#</dwc:locality>
   <dwc:recordedBy>#collectors#</dwc:recordedBy><cfif colls.recordcount GT 0><cfloop query="colls">
   <dwciri:recordedBy>#colls.agentguid#</dwciri:recordedBy>
</cfloop></cfif>   <dwc:eventDate>#eventDate#</dwc:eventDate>
   <dwc:day>#day#</dwc:day>
   <dwc:month>#month#</dwc:month>
   <dwc:year>#year#</dwc:year>
   <dwc:decimalLatitude>#dec_lat#</dwc:decimalLatitude>
   <dwc:decimalLongitude>#dec_long#</dwc:decimalLongitude>
   <dwc:geodeticDatum>#geodeticdatum#</dwc:geodeticDatum>
   <dwc:coordinateUncertaintyInMeters>#coordinateuncertaintyinmeters#</dwc:coordinateUncertaintyInMeters>
   <dwciri:georeferencedBy>#georeferencedbyid#</dwciri:georeferencedBy>
<cfif basisofrecord IS "FossilSpecimen">   <dwc:group>#geol_group#</dwc:group>
   <dwc:formation>#formation#</dwc:formation>
   <dwc:member>#member#</dwc:member>
   <dwc:bed>#bed#</dwc:bed>
   <dwc:lithostratigraphicterms>#lithostratigraphicterms#</dwc:lithostratigraphicterms>
   <dwc:earliesteraorlowesterathem>#earliesteraorlowesterathem#</dwc:earliesteraorlowesterathem>
   <dwc:latesteraorhighesterathem>#latesteraorhighesterathem#</dwc:latesteraorhighesterathem>
   <dwc:earliestperiodorlowestsystem>#earliestperiodorlowestsystem#</dwc:earliestperiodorlowestsystem>
   <dwc:latestperiodorhighestsystem>#latestperiodorhighestsystem#</dwc:latestperiodorhighestsystem>
   <dwc:earliestepochorlowestseries>#earliestepochorlowestseries#</dwc:earliestepochorlowestseries>
   <dwc:latestepochorhighestseries>#latestepochorhighestseries#</dwc:latestepochorhighestseries>
   <dwc:earliestageorloweststage>#earliestageorloweststage#</dwc:earliestageorloweststage>
   <dwc:latestageorhigheststage>#latestageorhigheststage#</dwc:latestageorhigheststage>
</cfif>
<cfif parts.recordcount GT 0><cfloop query="parts">
	<dwciri:materialSampleID>#parts.materialSampleID#</dwciri:materialSampleID>
</cfloop></cfif>
   <dcterms:modified>#last_edit_date#</dcterms:modified>
</dwc:Occurrence>
<cfif parts.recordcount GT 0><cfloop query="parts">
<dwc:MaterialSample rdf:about="#parts.materialSampleID#">
	<dwc:preparations>#parts.part_name# (#parts.preserve_method#)</dwc:preparations>
</dwc:MaterialSample>
</cfloop></cfif>
</rdf:RDF> </cfoutput>
</cfif><!--- RDF/XML --->
<cfif deliver IS 'text/turtle'>
<cfoutput>@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns##> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema##> .
@prefix dwc: <http://rs.tdwg.org/dwc/terms/> .
@prefix dwciri: <http://rs.tdwg.org/dwc/iri/> .
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema##> .
<#resolvable_guid#>
   a dwc:Occurrence;
   dwc:institutionCode "MCZ";
   dwc:collectionCode "#collection_cde#";
   dwc:catalogNumber "#cat_num#";
   dwc:basisOfRecord "#basisofrecord#";
   dcterms:rightsHolder "President and Fellows of Harvard College";
   dwc:scientificName "#scientific_name#";
   dwc:scientificNameAuthorship "#author_text#";
<cfif len(taxonid) GT 0>   dwc:taxonID "#taxonid#";
</cfif><cfif len(scientificnameid) GT 0>   dwc:scientificNameID "#scientificnameid#";
</cfif>   dwc:identifiedBy "#identifiedby#";
<cfif len(identifiedbyid) GT 0>   dwciri:identifiedBy "#identifiedbyid#";
</cfif><cfif len(typestatus) GT 0>   dwc:typeStatus "#typeStatus#";
</cfif>   dwc:country "#country#";
<cfif len(state_prov) GT 0>   dwc:stateProvince "#state_prov#";
</cfif>   dwc:locality "#spec_locality#";
   dwc:recordedBy "#collectors#";<cfif colls.recordcount GT 0><cfloop query="colls">
   dwciri:recordedBy> "#colls.agentguid#";
</cfloop>
</cfif>   dwc:eventDate "#eventDate#";
<cfif len(day) GT 0>   dwc:day "#day#";
</cfif><cfif len(month) GT 0>   dwc:month "#month#";
</cfif><cfif len(year) GT 0>   dwc:year "#year#";
</cfif>   dwc:decimalLatitude "#dec_lat#";
   dwc:decimalLongitude "#dec_long#";
   dwc:geodeticDatum "#geodeticdatum#";
   dwc:coordinateUncertaintyInMeters "#coordinateuncertaintyinmeters#";
<cfif len(georeferencedbyid) GT 0>   dwciri:georeferencedBy "#georeferencedbyid#";
</cfif><cfif basisofrecord IS "FossilSpecimen">   dwc:group "#geol_group#";
   dwc:formation "#formation#";
   dwc:member "#member#";
   dwc:bed "#bed#";
   dwc:lithostratigraphicterms "#lithostratigraphicterms#";
   dwc:earliesteraorlowesterathem "#earliesteraorlowesterathem#";
   dwc:latesteraorhighesterathem "#latesteraorhighesterathem#";
   dwc:earliestperiodorlowestsystem "#earliestperiodorlowestsystem#";
   dwc:latestperiodorhighestsystem "#latestperiodorhighestsystem#";
   dwc:earliestepochorlowestseries "#earliestepochorlowestseries#";
   dwc:latestepochorhighestseries "#latestepochorhighestseries#";
   dwc:earliestageorloweststage "#earliestageorloweststage#";
   dwc:latestageorhigheststage "#latestageorhigheststage#";
</cfif>
<cfif parts.recordcount GT 0>   dwciri:materialSampleID <cfloop query="parts">#chr(60)##parts.materialSampleID##chr(62)# <cfif parts.currentRow LT parts.recordcount>,
      </cfif></cfloop>;
</cfif>   dcterms:modified "#dateformat(last_edit_date, "yyyy-mm-dd")#T#timeformat(last_edit_date, "HH:mm:ss")#"^^xsd:dateTime .
<cfif parts.recordcount GT 0><cfloop query="parts">
<#parts.materialSampleID#>
   a dwc:MaterialSample;
   dwc:preparations "#parts.part_name# (#parts.preserve_method#)" .
</cfloop></cfif>
</cfoutput>
</cfif><!--- Turtle --->
<cfif deliver IS 'application/ld+json'>
<cfoutput>{
  "@context": { 
     "dwc": "http://rs.tdwg.org/dwc/terms/",
     "dwciri": "http://rs.tdwg.org/dwc/iri/",
     "dcterms": "http://purl.org/dc/terms/"
  },
  "@id": "#resolvable_guid#",
  "@type":"dwc:Occurrence",
  "dwc:institutionCode":"MCZ",
  "dwc:collectionCode":"#collection_cde#",
  "dwc:catalogNumber":"#cat_num#",
  "dwc:basisOfRecord":"#basisofrecord#",
  "dcterms:rightsHolder":"President and Fellows of Harvard College",
  "dcterms:modified":"#last_edit_date#",
  "dwc:scientificName":"#scientific_name#",
  "dwc:scientificNameAuthorship":"#author_text#",
<cfif len(taxonid) GT 0>  "dwc:taxonID":"#taxonid#",
</cfif><cfif len(scientificnameid) GT 0>  "dwc:scientificNameID":"#scientificnameid#",
</cfif>  "dwc:identifiedBy":"#identifiedby#",
  "dwciri:identifiedBy":"#identifiedbyid#",
<cfif len(typestatus) GT 0>  "dwc:typeStatus":"#typestatus#",
</cfif>  "dwc:country":"#country#",
<cfif len(state_prov) GT 0>  "dwc:stateProvince":"#state_prov#",
</cfif> "dwc:locality":"#spec_locality#",
  "dwc:recordedBy":"#collectors#",<cfif colls.recordcount GT 0><cfloop query="colls">
  "dwciri:recordedBy":"#colls.agentguid#",
</cfloop></cfif>  "dwc:eventDate":"#eventDate#",
<cfif len(day) GT 0>  "dwc:day":"#day#",
</cfif><cfif len(month) GT 0>  "dwc:month":"#month#",
</cfif><cfif len(year) GT 0>  "dwc:year":"#year#",
</cfif>  "dwc:decimalLatitude":"#dec_lat#",
  "dwc:decimalLongitude":"#dec_long#",
  "dwc:geodeticDatum":"#geodeticdatum#",
  "dwc:coordinateUncertaintyInMeters":"#coordinateuncertaintyinmeters#",
<cfif len(georeferencedbyid) GT 0>  "dwciri:georeferencedBy":"#georeferencedbyid#",
</cfif><cfif basisofrecord IS "FossilSpecimen">  "dwc:group":"#geol_group#",
  "dwc:formation":"#formation#",
  "dwc:member":"#member#",
  "dwc:bed":"#bed#",
  "dwc:lithostratigraphicterms":"#lithostratigraphicterms#",
  "dwc:earliesteraorlowesterathem":"#earliesteraorlowesterathem#",
  "dwc:latesteraorhighesterathem":"#latesteraorhighesterathem#",
  "dwc:earliestperiodorlowestsystem":"#earliestperiodorlowestsystem#",
  "dwc:latestperiodorhighestsystem":"#latestperiodorhighestsystem#",
  "dwc:earliestepochorlowestseries":"#earliestepochorlowestseries#",
  "dwc:latestepochorhighestseries":"#latestepochorhighestseries#",
  "dwc:earliestageorloweststage":"#earliestageorloweststage#",
  "dwc:latestageorhigheststage":"#latestageorhigheststage#",
</cfif><cfif parts.recordcount GT 0>
  "dwciri:materialSampleID": [ 
<cfset separator=""><cfloop query="parts">    #separator#{
    "@id": "#parts.materialSampleID#",
      "@type": "dwc:MaterialSample",
      "dwc:materialSampleID": "#parts.materialSampleID#",
      "dwc:preparations": "#parts.part_name# (#parts.preserve_method#)"
    }
<cfset separator=","></cfloop>  ]
</cfif>
}
</cfoutput>
</cfif><!--- JSON-LD --->
</cfloop>
