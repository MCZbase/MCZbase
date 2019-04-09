<cfset deliver = 'application/rdf+xml'>
<cfset accept = GetHttpRequestData().Headers['HTTP_ACCEPT'] >
<cfif accept IS 'text/turtle'>
   <cfset deliver = 'text/turtle'>
<cfelseif cgi.HTTP_ACCEPT IS 'application/rdf+xml'>
   <cfset deliver = 'application/rdf+xml'>
<cfelse>
   <cfset deliver = 'application/rdf+xml'>
</cfif>

<cfheader name="Content-type" value=deliver >
<cfquery name="occur" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
   select cat_num, collection_cde, guid, 
          country, state_prov, county, spec_locality,
          scientific_name, author_text,
          collectors,
          last_edit_date
    from #session.flatTableName#
    where guid = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#guid#"
</cfquery>

<cfif deliver IS 'application/rdf+xml'>
<cfoutput>
<rdf:RDF
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
  xmlns:dwc="http://rs.tdwg.org/dwc/terms/"
  xmlns:dwciri="http://rs.tdwg.org/dwc/iri/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  >
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
<dcterms:references rdf:resource="https://mczbase.mcz.harvard.edu/guid/#guid#">
</rdf:RDF>
</cfoutput>
</cfif><!--- RDF/XML --->
<cfif deliver IS 'application/rdf+xml'>
</cfif><!--- Turtle --->
