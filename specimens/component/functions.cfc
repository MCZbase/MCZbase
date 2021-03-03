<cfcomponent>
<cfinclude template = "/shared/functionLib.cfm">

<cffunction name="getExternalStatus" access="remote">
	<cfargument name="uri" type="string" required="yes">
	<cfhttp url="#uri#" method="head"></cfhttp>
	<cfreturn left(cfhttp.statuscode,3)>
</cffunction>
		

<!------EXISTING----------------------------------------------------------------------------------------------------------->
<cffunction name="loadIdentification" returntype="query" access="remote">
	<cfargument name="identification_id" type="string" required="yes">
	<cftry>
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		   select 1 as status, identification_id, collection_object_id, nature_of_id, accepted_id_fg,identification_remarks, taxa_formula, scientific_name, publication_id, sort_order, stored_as_fg
             from identification
             where identification_id  =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
		</cfquery>
		<cfif theResult.recordcount eq 0>
	  	  <cfset theResult=queryNew("status, message")>
		  <cfset t = queryaddrow(theResult,1)>
		  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
		  <cfset t = QuerySetCell(theResult, "message", "No Identifications found.", 1)>
		</cfif>
	  <cfcatch>
	   	<cfset theResult=queryNew("status, message")>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# hi #cfcatch.message# #cfcatch.detail#", 1)>
	  </cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>	
			
<!----------------------------------------------------------------------------------------------------------------->

<cffunction name="getIdentificationHTML" returntype="string" access="remote" returnformat="plain">
   <cfargument name="identification_id" type="string" required="yes">
   <cfset r=1>
   <cfthread name="getIdentificationThread">
   <cftry>
	
      <cfset resulthtml = "<div id='identificationHTML'> ">

      <cfloop query="theResult">
		<cfset resulthtml = resulthtml & "<cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">">
		<cfset resulthtml = resulthtml & "SELECT distinct taxonomy.taxon_name_id,display_name,scientific_name,author_text,full_taxon_name FROM identification_taxonomy,taxonomy WHERE identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id AND identification_id = <cfqueryparam value='#identification_id#' cfsqltype='CF_SQL_DECIMAL'></cfquery>">
		<cfset resulthtml = resulthtml & "<cfif accepted_id_fg is 1>">
		<cfset resulthtml = resulthtml & "<ul class='list-group border-green rounded p-2 h4 font-weight-normal'>">
		<cfset resulthtml = resulthtml & "<div class='d-inline-block mb-2 h4 text-success'>Current Identification</div>">
		<cfset resulthtml = resulthtml & "<cfif getTaxa.recordcount is 1 and taxa_formula is 'a'>">
		<cfset resulthtml = resulthtml & "<div class='font-italic h4 mb-1 font-weight-lessbold d-inline-block'> <a href='/name/#getTaxa.scientific_name#' target='_blank'>#getTaxa.display_name# </a>">
		<cfset resulthtml = resulthtml & "<cfif len(getTaxa.author_text) gt 0>">
		<cfset resulthtml = resulthtml & "<span class='sm-caps font-weight-lessbold'>#getTaxa.author_text#</span>">
		<cfset resulthtml = resulthtml & "</cfif>">
		<cfset resulthtml = resulthtml & "</div>">
		<cfset resulthtml = resulthtml & "<cfelse>">
		<cfset resulthtml = resulthtml & "<cfset link=''>">
		<cfset resulthtml = resulthtml & "<cfset i=1>">
		<cfset resulthtml = resulthtml & "<cfset thisSciName='#scientific_name#'>">
		<cfset resulthtml = resulthtml & "<cfloop query='getTaxa'>">
		<cfset resulthtml = resulthtml & "<span class='font-italic h4 font-weight-lessbold d-inline-block'>">
		<cfset resulthtml = resulthtml & "<cfset thisLink='<a href=""/name/#scientific_name#"" class=""d-inline"" target=""_blank"">#display_name#</a>'>">
		<cfset resulthtml = resulthtml & "<cfset thisSciName=#replace(thisSciName,scientific_name,thisLink)#>">
		<cfset resulthtml = resulthtml & "<cfset i=#i#+1>">
		<cfset resulthtml = resulthtml & "<a href='##'>#thisSciName#</a> <span class='sm-caps font-weight-lessbold'>#getTaxa.author_text#</span></span>">
		<cfset resulthtml = resulthtml & "</cfloop>">
		<cfset resulthtml = resulthtml & "</cfif>">
		<cfset resulthtml = resulthtml & "<cfif oneOfUs is 1 and stored_as_fg is 1>">
		<cfset resulthtml = resulthtml & "<span class='bg-gray float-right rounded p-1'>STORED AS</span>">
		<cfset resulthtml = resulthtml & "</cfif>">
		<cfset resulthtml = resulthtml & "<cfif not isdefined('metaDesc')>">
		<cfset resulthtml = resulthtml & "<cfset metaDesc=''>">
		<cfset resulthtml = resulthtml & "</cfif>">
		<cfset resulthtml = resulthtml & "<cfloop query='getTaxa'>">
		<cfset resulthtml = resulthtml & "<div class='h5 mb-1 text-dark font-italic'> #full_taxon_name# </div>">
		<cfset resulthtml = resulthtml & "<cfset metaDesc=metaDesc & '; ' & full_taxon_name>">
		<cfset resulthtml = resulthtml & "<cfquery name='cName' datasource='user_login' username='#session.dbuser#' password='#decrypt(session.epw,cfid)#'>
		SELECT common_name FROM common_name	WHERE taxon_name_id= <cfqueryparam value='#taxon_name_id#' cfsqltype='CF_SQL_DECIMAL'> and common_name is not null
		GROUP BY common_name order by common_name</cfquery>">
		<cfset resulthtml = resulthtml & "<cfif len(cName.common_name) gt 0>">
		<cfset resulthtml = resulthtml & "<div class='h5 mb-1 text-muted font-weight-normal pl-3'>Common Name(s): '#valuelist(cName.common_name,'; ')#">
		<cfset resulthtml = resulthtml & "</div>">	
		<cfset resulthtml = resulthtml & "</cfif>">
		<cfset resulthtml = resulthtml & "<cfset metaDesc=metaDesc & '; ' & valuelist(cName.common_name,"; ")>">
		</cfloop>
		<cfset resulthtml = resulthtml & "<div class='form-row mx-0'>">
		<cfset resulthtml = resulthtml & "<div class='small mr-2'><span class='h5'>Determiner:</span> #agent_name#'">
		<cfset resulthtml = resulthtml & "<cfif len(made_date) gt 0>">
		<cfset resulthtml = resulthtml & "<span class='h5'>on Date:</span> #dateformat(made_date,'yyyy-mm-dd')#">
		<cfset resulthtml = resulthtml & "</cfif></div>	</div>">
		<cfset resulthtml = resulthtml & "<div class='small mr-2'><span class='h5'>Nature of ID:</span> #nature_of_id# </div>">
		<cfset resulthtml = resulthtml & "<cfif len(identification_remarks) gt 0>">
		<cfset resulthtml = resulthtml & "<div class='small'><span class='h5'>Remarks:</span> #identification_remarks#</div>">
		<cfset resulthtml = resulthtml & "</cfif>">
		<cfset resulthtml = resulthtml & "</ul>	">
		<cfelse>
		<cfset resulthtml = resulthtml & "<cfif getTaxa.recordcount gt 0>">		
		<cfset resulthtml = resulthtml & "<div class='h4 pl-4 mt-1 mb-0 text-success'>Former Identifications</div>">
		<cfset resulthtml = resulthtml & "</cfif>">
		<cfset resulthtml = resulthtml & "<ul class='list-group py-1 px-3 ml-2 text-dark bg-light'>">
		<cfset resulthtml = resulthtml & "	<li class="px-0">">
		<cfset resulthtml = resulthtml & "<cfif getTaxa.recordcount is 1 and taxa_formula is 'a'>">
		<cfset resulthtml = resulthtml & "<span class='font-italic h4 font-weight-normal'>">
		<cfset resulthtml = resulthtml & "<a href='/name/#getTaxa.scientific_name#' target='_blank'>#getTaxa.display_name#</a></span>">
		<cfset resulthtml = resulthtml & "<cfif len(getTaxa.author_text) gt 0>">
		<cfset resulthtml = resulthtml & "<span class="color-black sm-caps">#getTaxa.author_text#</span>">
		<cfset resulthtml = resulthtml & "</cfif>">
		<cfset resulthtml = resulthtml & "<cfelse>">
		<cfset resulthtml = resulthtml & "<cfset link=''>">
		<cfset resulthtml = resulthtml & "<cfset i=1>">
		<cfset resulthtml = resulthtml & "<cfset thisSciName='#scientific_name#'>">
		<cfset resulthtml = resulthtml & "<cfloop query='getTaxa'>">
		<cfset resulthtml = resulthtml & "<cfset thisLink='<a href=''/name/#scientific_name#'' target=''_blank''>#display_name#</a>'>">
		<cfset resulthtml = resulthtml & "<cfset thisSciName=#replace(thisSciName,scientific_name,thisLink)#>">
		<cfset resulthtml = resulthtml & "<cfset i=#i#+1>">
		<cfset resulthtml = resulthtml & "</cfloop>">
		<cfset resulthtml = resulthtml & "#thisSciName# ">
		<cfset resulthtml = resulthtml & "</cfif>">
		<cfset resulthtml = resulthtml & "<cfif oneOfUs is 1 and stored_as_fg is 1>">
		<cfset resulthtml = resulthtml & "<span style='float-right rounded p-1 bg-light'>STORED AS</span>">
		<cfset resulthtml = resulthtml & "</cfif>">
		<cfset resulthtml = resulthtml & "<cfif not isdefined('metaDesc')>">
		<cfset resulthtml = resulthtml & "<cfset metaDesc=''>">
		<cfset resulthtml = resulthtml & "</cfif>">
		<cfset resulthtml = resulthtml & "<cfloop query='getTaxa'>">
		<cfset resulthtml = resulthtml & "<p class='small text-muted mb-0'> #full_taxon_name#</p>">
		<cfset resulthtml = resulthtml & "<cfset metaDesc=metaDesc & '; ' & full_taxon_name>">
		<cfset resulthtml = resulthtml & "<cfquery name='cName' datasource='user_login' username='#session.dbuser#' password='#decrypt(session.epw,cfid)#'>">
		<cfset resulthtml = resulthtml & "SELECT common_name FROM common_name WHERE taxon_name_id= <cfqueryparam value="#taxon_name_id#" cfsqltype="CF_SQL_DECIMAL"> and common_name is not null GROUP BY common_name order by common_name</cfquery>">
		<cfset resulthtml = resulthtml & "<cfif len(cName.common_name) gt 0><div class='small text-muted pl-3'>">
		<cfset resulthtml = resulthtml & "Common Name(s): #valuelist(cName.common_name,'; ')#">
		<cfset resulthtml = resulthtml & "</div>">
		<cfset resulthtml = resulthtml & "<cfset metaDesc=metaDesc & '; ' & valuelist(cName.common_name,'; ')></cfif>">
		<cfset resulthtml = resulthtml & "</cfloop>">
		<cfset resulthtml = resulthtml & "<cfif len(formatted_publication) gt 0>">
		<cfset resulthtml = resulthtml & "sensu <a href='/publication/#publication_id#' target='_mainFrame'> #formatted_publication# </a>">
		<cfset resulthtml = resulthtml & "</cfif>">
		<cfset resulthtml = resulthtml & "<span class='small'>Determination: #agent_name#">
		<cfset resulthtml = resulthtml & "<cfif len(made_date) gt 0>">
		<cfset resulthtml = resulthtml & "on #dateformat(made_date,'yyyy-mm-dd')#">
		<cfset resulthtml = resulthtml & "</cfif>">
		<cfset resulthtml = resulthtml & "<span class="d-block">Nature of ID: #nature_of_id#</span> ">
		<cfset resulthtml = resulthtml & "<cfif len(identification_remarks) gt 0>">
		<cfset resulthtml = resulthtml & "<span class="d-block">Remarks: #identification_remarks#</span>">
		<cfset resulthtml = resulthtml & "</cfif></cfif></li></ul>">
	</cfloop>
   <cfcatch>
       <cfset resulthtml = resulthtml & "Error:" & "#cfcatch.type# #cfcatch.message# #cfcatch.detail#">
   </cfcatch>
   </cftry>
     <cfoutput>#resulthtml#</cfoutput>
   </cfthread>
    <cfthread action="join" name="getIdentificationThread" />
    <cfreturn getIdentificationThread.output>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!------EXISTING----------------------------------------------------------------------------------------------------------->
<cffunction name="loadLocality" returntype="query" access="remote">
	<cfargument name="locality_id" type="string" required="yes">
	<cftry>
		<cfquery name="theResults" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		   select 1 as status, locality_id, geog_auth_rec_id, spec_locality
             from locality
             where locality_id  =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
		</cfquery>
		<cfif theResults.recordcount eq 0>
	  	  <cfset theResults=queryNew("status, message")>
		  <cfset t = queryaddrow(theResults,1)>
		  <cfset t = QuerySetCell(theResults, "status", "0", 1)>
		  <cfset t = QuerySetCell(theResults, "message", "No localities found.", 1)>
		</cfif>
	  <cfcatch>
	   	<cfset theResults=queryNew("status, message")>
		<cfset t = queryaddrow(theResults,1)>
		<cfset t = QuerySetCell(theResults, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResults, "message", "#cfcatch.type# hi #cfcatch.message# #cfcatch.detail#", 1)>
	  </cfcatch>
	</cftry>
	<cfreturn theResults>
</cffunction>
		
			
			
<cffunction name="getLocalityHTML" returntype="string" access="remote" returnformat="plain">
   <cfargument name="locality_id" type="string" required="yes">
   <cfset r=1>
   <cfthread name="getLocalityThread">
   <cftry>
    <cfquery name="theResults" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select 1 as status, locality.spec_locality, locality.geog_auth_rec_id, collecting_event.collecting_event_id, collecting_event.verbatim_locality, collecting_event.began_date, collecting_event.ended_date, collecting_event.collecting_source 
		from locality, collecting_event, geog_auth_rec 
		where locality.geog_auth_rec_id= geog_auth_rec.geog_auth_rec_id
		and collecting_event.locality_id = locality.locality_id
		and locality.locality_id = <cfqueryparam value="#locality_id#" cfsqltype="CF_SQL_DECIMAL">
	</cfquery>

      <cfset resulthtml1 = "<div id='localityHTML'> ">

      <cfloop query="theResults">
         <cfset resulthtml1 = resulthtml1 & "<div class='localityExistingForm'>">
            <cfset resulthtml1 = resulthtml1 & "<form><div class='container pl-1'>">
			<cfset resulthtml1 = resulthtml1 & "<div class='col-md-6 col-sm-12 float-left'>">
			<cfset resulthtml1 = resulthtml1 & "<div class='form-group'><label for='spec_locality' class='data-entry-label mb-0'>Specific Locality</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='spec_locality' class='data-entry-input' value='#spec_locality#'></div>">
			<cfset resulthtml1 = resulthtml1 & "<div class='form-row form-group'><label for='verbatim_locality' class='data-entry-label mb-0'>Verbatim Locality</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='verbatim_locality' class='data-entry-input' value='#verbatim_locality#'></div></div>">
			<cfset resulthtml1 = resulthtml1 & "<div class='col-md-6 col-sm-12 float-left'><label for='collecting_source' class='data-entry-label mb-0'>Collecting Source</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='collecting_source' class='data-entry-input' value='#collecting_source#'>">
			<cfset resulthtml1 = resulthtml1 & "<label for='began_date' class='data-entry-label mb-0'>Began Date</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='began_date' class='data-entry-input' value='#began_date#'>">
			<cfset resulthtml1 = resulthtml1 & "<label for='ended_date' class='data-entry-label mb-0'>End Date</label>">
			<cfset resulthtml1 = resulthtml1 & "<input name='ended_date' class='data-entry-input' value='#ended_date#'></div>">
		
			<cfset resulthtml1 = resulthtml1 & "</div></div></form>">
       
				<cfset resulthtml1 = resulthtml1 & "</div></div>"> 
      </cfloop> <!--- theResult --->

   <cfcatch>
       <cfset resulthtml1 = resulthtml1 & "Error:" & "#cfcatch.type# #cfcatch.message# #cfcatch.detail#">
   </cfcatch>
   </cftry>
     <cfoutput>#resulthtml1#</cfoutput>
   </cfthread>
    <cfthread action="join" name="getLocalityThread" />
    <cfreturn getLocalityThread.output>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getPartName" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

   <cftry>
      <cfset rows = 0>
      <cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select a.part_name
			from (
				select part_name, partname
				from ctspecimen_part_name, ctspecimen_part_list_order
				where ctspecimen_part_name.part_name =  ctspecimen_part_list_order.partname (+)
					and upper(part_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(term)#%">
				) a
			group by a.part_name, a.partname
			order by a.partname asc, a.part_name
      </cfquery>
   <cfset rows = search_result.recordcount>
      <cfset i = 1>
      <cfloop query="search">
         <cfset row = StructNew()>
         <cfset row["id"] = "#search.part_name#">
         <cfset row["value"] = "#search.part_name#" >
         <cfset data[i]  = row>
         <cfset i = i + 1>
      </cfloop>
      <cfreturn #serializeJSON(data)#>
   <cfcatch>
      <cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
      <cfset message = trim("Error processing getAgentPartName: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
      <cfheader statusCode="500" statusText="#message#">
         <cfoutput>
            <div class="container">
               <div class="row">
                  <div class="alert alert-danger" role="alert">
                     <img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
                     <h2>Internal Server Error.</h2>
                     <p>#message#</p>
                     <p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
                  </div>
               </div>
            </div>
         </cfoutput>
      <cfabort>
   </cfcatch>
   </cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
		  
		  
		  	
<cffunction name="getMediaForPublication" returntype="string" access="remote" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfthread name="getMediaForCitPub">
		<cfquery name="query"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				mr.media_id, m.media_uri, m.preview_uri, ml.label_value descr, m.media_type, m.mime_type
			FROM
				media_relations mr, media_labels ml, media m, citation c, formatted_publication fp
			WHERE
				mr.media_id = ml.media_id and
				mr.media_id = m.media_id and
				ml.media_label = 'description' and
				MEDIA_RELATIONSHIP like '% publication' and
				RELATED_PRIMARY_KEY = c.publication_id and
				c.publication_id = fp.publication_id and
				fp.format_style='short' and
				c.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			ORDER by substr(formatted_publication, -4)
		</cfquery>
		<cfoutput>
		<div class='Media1'>
				<span class="pb-2">
					<cfloop query="query">
						<cfquery name="mediaQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select media.media_id, media_uri, preview_uri, media_type, mczbase.get_media_descriptor(media.media_id) as media_descriptor
							from media_relations left join media on media_relations.media_id = media.media_id
							where media_relations.media_relationship = '%publication'
								and media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#publication_id#>
						</cfquery>
						<cfset mediaLink = "&##8855;">
						<cfloop query="mediaQuery">
							<cfset puri=getMediaPreview(preview_uri,media_type) >
							<cfif puri EQ "/images/noThumb.jpg">
								<cfset altText = "Red X in a red square, with text, no preview image available">
							<cfelse>
								<cfset altText = mediaQuery.media_descriptor>
							</cfif>
							<cfset mediaLink = "<a href='#media_uri#'target='_blank' rel='noopener noreferrer'><img src='#puri#' height='15' alt='#altText#'></a>" >
						</cfloop>
						<ul class='list-style-disc pl-4 pr-0'>
							<li class="my-1">
								#formatted_publication# 
								
							</li>
						</ul>
					</cfloop>
					<cfif query.recordcount eq 0>
				 		None
					</cfif>
				</span>
			</div> <!---  --->
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getMediaForCitPub" />
	<cfreturn getMediaForCitPub.output>
</cffunction>
<!------------------------------------------------------------------------------------->
</cfcomponent>
