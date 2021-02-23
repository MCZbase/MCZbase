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

			
			
<!----------------------------------------------------------------------------------------------------------------->

<cffunction name="getIdentificationHTML" returntype="string" access="remote" returnformat="plain">
   <cfargument name="identification_id" type="string" required="yes">
   <cfset r=1>
   <cfthread name="getIdentificationThread">
   <cftry>
       <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
         select 1 as status, identification.identification_id, identification.collection_object_id, identification.scientific_name, identification.made_date, identification.nature_of_id, identification.stored_as_fg,identification.identification_remarks, identification.accepted_id_fg, identification.taxa_formula, identification.sort_order, taxonomy.full_taxon_name, taxonomy.author_text, identification_agent.agent_id, concatidagent(identification.identification_id) agent_name
             	FROM 
						identification, identification_taxonomy,
						taxonomy, identification_agent
          		WHERE 	
		   				identification.identification_id=identification_taxonomy.identification_id and
		   				identification_agent.identification_id = identification.identification_id and
		   				identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id and 
						identification.identification_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
           		ORDER BY 
		   				made_date
      </cfquery>
	
	
      <cfset resulthtml = "<div id='identificationHTML'> ">

      <cfloop query="theResult">
         <cfset resulthtml = resulthtml & "<div class='identifcationExistingForm'>">
            <cfset resulthtml = resulthtml & "<form><div class='container pl-1'>">
			<cfset resulthtml = resulthtml & "<div class='col-md-6 col-sm-12 float-left'>">
			<cfset resulthtml = resulthtml & "<div class='form-group'><label for='scientific_name'>Scientific Name:</label><input type='text' name='taxona' id='taxona' class='reqdClr form-control form-control-sm' value='#scientific_name#' size='1' onChange='taxaPick(''taxona_id'',''taxona'',''newID'',this.value); return false;'	onKeyPress=return noenter(event);'><input type='hidden' name='taxona_id' id=taxona_id' class='reqdClr'></div>">
			<cfset resulthtml = resulthtml & "<div class='form-group w-25 mb-3 float-left'><label for='taxa_formula'>Formula:</label><select class='border custom-select form-control input-sm id='select'><option value='' disabled='' selected=''>#taxa_formula#</option><option value='A'>A</option><option value='B'>B</option><option value='sp.'>sp.</option></select></div>">
			<cfset resulthtml = resulthtml & "<div class='form-group w-50 mb-3 ml-3 float-left'><label for='made_date'>Made Date:</label><input type='text' class='form-control ml-0 input-sm' id='made_date' value='#dateformat(made_date,'yyyy-mm-dd')#&nbsp;'></div></div>">
			<cfset resulthtml = resulthtml & "<div class='col-md-6 col-sm-12 float-left'>">
    		<cfset resulthtml = resulthtml & "<div class='form-group'><label for='nature_of_id'>Determined By:</label><input type='text' class='form-control-sm' id='nature_of_id' value='#agent_name#'></div>">
            <cfset resulthtml = resulthtml & "<div class='form-group'><label for='nature_of_id'>Nature of ID:</label><select name='nature_of_id' id='nature_of_id' size='1' class='reqdClr custom-select form-control'><cfloop query='theResult'><option value='theResult.nature_of_id'>#nature_of_id#</option></cfloop></select></cfloop></div>">
			<cfset resulthtml = resulthtml & "</div>">
			<cfset resulthtml = resulthtml & "<div class='col-md-12 col-sm-12 float-left'>">
         	<cfset resulthtml = resulthtml & "<div class='form-group'><label for='full_taxon_name'>Full Taxon Name:</label><input type='text' class='form-control-sm' id='full_taxon_name' value='#full_taxon_name#'></div> ">
			<cfset resulthtml = resulthtml & "<div class='form-group'><label for='identification_remarks'>Identification Remarks:</label><textarea type='text' class='form-control' id='identification_remarks' value='#identification_remarks#'></textarea></div>">
				
			<cfset resulthtml = resulthtml & "<div class='form-check'><input type='checkbox' class='form-check-input' id='materialUnchecked'><label class='mt-2 form-check-label' for='materialUnchecked'>Stored as #scientific_name#</label></div>">
			<cfset resulthtml = resulthtml & "<div class='form-group float-right'><button type='button' value='Create New Identification' class='btn btn-primary ml-2' onClick=""$('.dialog').dialog('open'); loadNewIdentificationForm(identification_id,'newIdentificationForm');"">Create New Identification</button></div> ">
		
			<cfset resulthtml = resulthtml & "</div></div></form>">
       
            <cfset resulthtml = resulthtml & "</div>"> 
      </cfloop> <!--- theResult --->

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
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		   select 1 as status, locality_id, geog_auth_rec_id, spec_locality
             from locality
             where locality_id  =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
		</cfquery>
		<cfif theResult.recordcount eq 0>
	  	  <cfset theResult=queryNew("status, message")>
		  <cfset t = queryaddrow(theResult,1)>
		  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
		  <cfset t = QuerySetCell(theResult, "message", "No localities found.", 1)>
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
			
			
<cffunction name="getLocalityHTML" returntype="string" access="remote" returnformat="plain">
   <cfargument name="locality_id" type="string" required="yes">
   <cfset r=1>
   <cfthread name="getLocalityThread">
   <cftry>
    <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select  spec_locality, geog_auth_rec_id from locality
		where locality_id = <cfqueryparam value="#locality_id#" cfsqltype="CF_SQL_DECIMAL">
	</cfquery>

      <cfset resulthtml = "<div id='localityHTML'> ">

      <cfloop query="theResult">
         <cfset resulthtml = resulthtml & "<div class='localityExistingForm'>">
            <cfset resulthtml = resulthtml & "<form><div class='container pl-1'>">
			<cfset resulthtml = resulthtml & "<div class='col-md-6 col-sm-12 float-left'>">
		
				<cfset resulthtml = resulthtml & "<input name='spec_locality' value='#spec_locality#'>">
		
			<cfset resulthtml = resulthtml & "</div></div></form>">
       
            <cfset resulthtml = resulthtml & "</div>"> 
      </cfloop> <!--- theResult --->

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
