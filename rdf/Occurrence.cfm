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
<cfif NOT isdefined("guid")>
   <cfset guid="MCZ:IP:100000">
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

<cfquery name="occur" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT distinct 
		collection_object_id,
		cat_num, collection_cde, guid, 
		basisofrecord,	
		country, state_prov, county, spec_locality,
		highergeographyid,
		trim(scientific_name || ' ' || author_text) as scientific_name,
		taxonid,
		scientificnameid,
		identifiedby,
		identifiedbyid,
		REPLACE(REPLACE(typestatusplain,'<i>'),'</i>') AS typestatus,
		author_text,
		collectors,
		recordedbyid,
    	(case when began_date > '1700-01-01' then began_date else '' end) as began_date,
    	(case when began_date > '1700-01-01' then ended_date else '' end) as ended_date,
		(case when began_date > '1700-01-01' then regexp_substr(began_date, '([0-9]{4})',1,1,'i',1) else '' end) as year,
		(case when began_date > '1700-01-01' then regexp_substr(began_date, '([0-9]{4})-([0-9]{2})',1,1,'i',2) else'' end) as month,
		(case when began_date > '1700-01-01' then regexp_substr(began_date, '([0-9]{4})-([0-9]{2})-([0-9]{2})',1,1,'i',3) else '' end) as day,
		geol_group,
		formation,
		member,
		bed,
		EARLIESTERAORLOWESTERATHEM,
		LATESTERAORHIGHESTERATHEM,
		EARLIESTPERIODORLOWESTSYSTEM,
		LATESTPERIODORHIGHESTSYSTEM,
		EARLIESTEPOCHORLOWESTSERIES,
		LATESTEPOCHORHIGHESTSERIES,
		EARLIESTAGEORLOWESTSTAGE,
		LATESTAGEORHIGHESTSTAGE,
		LITHOSTRATIGRAPHICTERMS,
		dec_lat,
		dec_long,
		datum as geodeticdatum,
		coordinateuncertaintyinmeters,
		georeferencedbyid,
		last_edit_date
	FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif>
	WHERE guid = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#guid#">
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
<cfif deliver IS 'application/rdf+xml'>
<cfoutput><rdf:RDF
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns##"
  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema##"
  xmlns:dwc="http://rs.tdwg.org/dwc/terms/"
  xmlns:dwciri="http://rs.tdwg.org/dwc/iri/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  >
<dwc:Occurrence rdf:about="https://mczbase.mcz.harvard.edu/guid/#guid#">
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
</cfif>   <dcterms:modified>#last_edit_date#</dcterms:modified>
</dwc:Occurrence>
</rdf:RDF> </cfoutput>
</cfif><!--- RDF/XML --->
<cfif deliver IS 'text/turtle'>
<cfoutput>@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns##>.  
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema##>.  
@prefix dwc: <http://rs.tdwg.org/dwc/terms/>.
@prefix dwciri: <http://rs.tdwg.org/dwc/iri/>.
@prefix dcterms: <http://purl.org/dc/terms/>. 
<https://mczbase.mcz.harvard.edu/guid/#guid#>
   a dwc:Occurrence;
   dwc:institutionCode "MCZ";
   dwc:collectionCode "#collection_cde#";
   dwc:collectionCode "#collection_cde#";
   dwc:catalogNumber "#cat_num#";
   dwc:basisOfRecord "#basisofrecord#";
   dcterms:rightsHolder "President and Fellows of Harvard College";
   dcterms:modified "#last_edit_date#"^^xsd:date ;
   dwc:scientificName "#scientific_name#";
   dwc:scientificNameAuthorship "#author_text#";
   dwc:taxonID "#taxonid#";
   dwc:scientificNameID "#scientificnameid#";
   dwc:identifiedBy "#identifiedby#";
   dwciri:identifiedBy "#identifiedbyid#";
<cfif len(typestatus) GT 0>   dwc:typeStatus "#typeStatus#";
</cfif>   dwc:country "#country#";
   dwc:stateProvince "#state_prov#";
   dwc:locality "#spec_locality#";
   dwc:recordedBy "#collectors#";<cfif colls.recordcount GT 0><cfloop query="colls">
   dwciri:recordedBy> "#colls.agentguid#";
</cfloop></cfif>   dwc:eventDate "#eventDate#";
   dwc:day "#day#";
   dwc:month "#month#";
   dwc:year "#year#";
   dwc:decimalLatitude "#dec_lat#";
   dwc:decimalLongitude "#dec_long#";
   dwc:geodeticDatum "#geodeticdatum#";
   dwc:coordinateUncertaintyInMeters "#coordinateuncertaintyinmeters#";
   dwciri:georeferencedBy "#georeferencedbyid#";
<cfif basisofrecord IS "FossilSpecimen">   dwc:group "#geol_group#";
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
</cfif>   dwc:recordedBy "#collectors#".
</cfoutput>
</cfif><!--- Turtle --->
<cfif deliver IS 'application/ld+json'>
<cfoutput>{
  "@context": { 
     "dwc": "http://rs.tdwg.org/dwc/terms/",
     "dwciri": "http://rs.tdwg.org/dwc/iri/",
     "dcterms": "http://purl.org/dc/terms/"
  },
  "@id": "https://mczbase.mcz.harvard.edu/guid/#guid#",
  "@type":"dwc:Occurrence",
  "dwc:institutionCode":"MCZ",
  "dwc:collectionCode":"#collection_cde#",
  "dwc:catalogNumber":"#cat_num#",
  "dwc:basisOfRecord":"#basisofrecord#",
  "dcterms:rightsHolder":"President and Fellows of Harvard College",
  "dcterms:modified":"#last_edit_date#",
  "dwc:scientificName":"#scientific_name#",
  "dwc:scientificNameAuthorship":"#author_text#",
  "dwc:taxonID":"#taxonid#",
  "dwc:scientificNameID":"#scientificnameid#",
  "dwc:identifiedBy":"#identifiedby#",
  "dwciri:identifiedBy":"#identifiedbyid#",
<cfif len(typestatus) GT 0>  "dwc:typeStatus":"#typestatus#",
</cfif> "dwc:country":"#country#",
  "dwc:stateProvince":"#state_prov#",
  "dwc:locality":"#spec_locality#",
  "dwc:recordedBy":"#collectors#",<cfif colls.recordcount GT 0><cfloop query="colls">
  "dwciri:recordedBy":"#colls.agentguid#",
</cfloop></cfif>  "dwc:eventDate":"#eventDate#",
  "dwc:day":"#day#",
  "dwc:month":"#month#",
  "dwc:year":"#year#",
  "dwc:decimalLatitude":"#dec_lat#",
  "dwc:decimalLongitude":"#dec_long#",
  "dwc:geodeticDatum":"#geodeticdatum#",
  "dwc:coordinateUncertaintyInMeters":"#coordinateuncertaintyinmeters#",
  "dwciri:georeferencedBy":"#georeferencedbyid#",
<cfif basisofrecord IS "FossilSpecimen">  "dwc:group":"#geol_group#",
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
</cfif>  "dwc:recordedBy":"#collectors#"
}
</cfoutput>
</cfif><!--- JSON-LD --->
</cfloop>
