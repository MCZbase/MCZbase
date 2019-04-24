<cfset deliver = 'application/rdf+xml'>
<cfif NOT isdefined("guid")>
   <cfset guid="MCZ:IP:100000">
</cfif>
<cftry>
   <cfset accept = GetHttpRequestData().Headers['accept'] >
<cfcatch>
   <cfset accept = "application/rdf+xml">
</cfcatch>
</cftry>
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

<cfquery name="occur" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
   select distinct 
          cat_num, collection_cde, guid, 
          country, state_prov, county, spec_locality,
          scientific_name, author_text,
          collectors,
          last_edit_date
    from #session.flatTableName#
    where guid = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#guid#">
          and rownum < 2
</cfquery>

<cfloop query=occur>
<cfif deliver IS 'application/rdf+xml'>
<cfoutput>
<rdf:RDF
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
   <dwc:scientificName>#scientific_name#</dwc:scientificName>
   <dwc:scientificNameAuthorship>#author_text#</dwc:scientificNameAuthorship>
   <dwc:country>#country#</dwc:country>
   <dwc:stateProvince>#state_prov#</dwc:stateProvince>
   <dwc:locality>#spec_locality#</dwc:locality>
   <dwc:recordedBy>#collectors#</dwc:recordedBy>
   <dcterms:modified>#last_edit_date#</dcterms:modified>
</dwc:Occurrence>
</rdf:RDF>
</cfoutput>
</cfif><!--- RDF/XML --->
<cfif deliver IS 'text/turtle'>
<cfoutput>
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns##>.  
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
   dcterms:modified "#last_edit_date#"^^xsd:date ;
   dwc:scientificName "#scientific_name#";
   dwc:scientificNameAuthorship "#author_text#";
   dwc:country "#country#";
   dwc:stateProvince "#state_prov#";
   dwc:locality "#spec_locality#";
   dwc:recordedBy "#collectors#".
</cfoutput>
</cfif><!--- Turtle --->
<cfif deliver IS 'application/ld+json'>
<cfoutput>
{
  "@context": { 
     "dwc": "http://rs.tdwg.org/dwc/terms/",
     "dcterms": "http://purl.org/dc/terms/"
  },
  "@id": "https://mczbase.mcz.harvard.edu/guid/#guid#",
  "@type":"dwc:Occurrence",
  "dwc:institutionCode":"MCZ",
  "dwc:collectionCode":"#collection_cde#",
  "dcterms:modified":"#last_edit_date#",
  "dwc:catalogNumber":"#cat_num#",
  "dwc:scientificName":"#scientific_name#",
  "dwc:scientificNameAuthorship":"#author_text#",
  "dwc:country":"#country#",
  "dwc:stateProvince":"#state_prov#",
  "dwc:locality":"#spec_locality#",
  "dwc:recordedBy":"#collectors#"
}
</cfoutput>
</cfif><!--- JSON-LD --->
</cfloop>
