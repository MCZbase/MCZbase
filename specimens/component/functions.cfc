<cfcomponent>
<cf_rolecheck>
<cfinclude template = "/shared/functionLib.cfm">

<cffunction name="getExternalStatus" access="remote">
	<cfargument name="uri" type="string" required="yes">

	<cfhttp url="#uri#" method="head"></cfhttp>
	<cfreturn left(cfhttp.statuscode,3)>
</cffunction>

<!--- updateCondition update the condition on a part identified by the part's collection object id 
 @param part_id the collection_object_id for the part to update
 @param condition the new condition to update the part to 
 @return a json structure containing the part_id and a message, with "success" as the value of the message on a successful update.
--->
<cffunction name="updateCondition" access="remote" returntype="query">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="condition" type="string" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update coll_object 
				set
					condition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#condition#">
				where
					COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<cffunction name="getIdentifications" returntype="query" access="remote">
	<cfargument name="identification_id" type="string" required="yes">
	<cftry>
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 1 as status, identification_id, collection_object_id, nature_of_id, accepted_id_fg,
				identification_remarks, taxa_formula, scientific_name, publication_id, sort_order, stored_as_fg
			from identification
			where identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
		</cfquery>
		<cfif theResult.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No identifications found.", 1)>
		</cfif>
	<cfcatch>
		<cfset theResult=queryNew("status, message")>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!--- function getIdentificationHtml obtain an html block to popluate an edit dialog for an identification 
 @param identification-id the identification.identification_id to edit.
 @return html for editing the identification 
--->
<cffunction name="getIdentificationHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="identification_id" type="string" required="yes">

	<cfset r=1>
	<cfthread name="getIdentificationThread">
		<cftry>
			<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 1 as status, identification.identification_id, identification.collection_object_id, 
					identification.scientific_name, identification.made_date, identification.nature_of_id, 
					identification.stored_as_fg, identification.identification_remarks, identification.accepted_id_fg, 
					identification.taxa_formula, identification.sort_order, taxonomy.full_taxon_name, taxonomy.author_text, 
					identification_agent.agent_id, concatidagent(identification.identification_id) agent_name
				FROM 
					identification
					left join identification_taxonomy on identification.identification_id=identification_taxonomy.identification_id 
					left join taxonomy on identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id and 
					left join identification_agent on identification_agent.identification_id = identification.identification_id and
				WHERE 	
					identification.identification_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
				ORDER BY 
					made_date
			</cfquery>
			<cfoutput>
				<div id="identificationHTML">
					<cfloop query="theResult">
						<div class="identifcationExistingForm">
							<form>
								<div class="container pl-1">
									<div class="col-md-6 col-sm-12 float-left">
										<div class="form-group">
											<label for="scientific_name">Scientific Name:</label>
											<input type="text" name="taxona" id="taxona" class="reqdClr form-control form-control-sm" value="#scientific_name#" size="1" 
												onChange="taxaPick('taxona_id','taxona','newID',this.value); return false;"
												onKeyPress="return noenter(event);">
											<input type="hidden" name="taxona_id" id=taxona_id" class="reqdClr">
										</div>
										<div class="form-group w-25 mb-3 float-left">
											<label for="taxa_formula">Formula:</label>
											<select class="border custom-select form-control input-sm" id="select">
												<option value="" disabled="" selected="">#taxa_formula#</option>
												<!--- TODO: Shouldn't this be from a code table? --->
												<option value="A">A</option>
												<option value="B">B</option>
												<option value="sp.">sp.</option>
											</select>
										</div>
										<div class="form-group w-50 mb-3 ml-3 float-left">
											<label for="made_date">Made Date:</label>
											<input type="text" class="form-control ml-0 input-sm" id="made_date" value="#dateformat(made_date,'yyyy-mm-dd')#&nbsp;">
										</div>
									</div>
									<div class="col-md-6 col-sm-12 float-left">
										<div class="form-group">
											<!--- TODO: Fix this, should be an agent picker --->
											<label for="determinedby">Determined By:</label>
											<input type="text" class="form-control-sm" id="determinedby" value="#agent_name#">
										</div>
										<div class="form-group">
											<label for="nature_of_id">Nature of ID:</label>
											<select name="nature_of_id" id="nature_of_id" size="1" class="reqdClr custom-select form-control">
												<option value="#nature_of_id#">#nature_of_id#</option>
												<!--- TODO: Wrong query name, should reference a code table query. --->
												<cfloop query="theResult">
													<option value="theResult.nature_of_id">#nature_of_id#</option>
												</cfloop>
											</select>
										</div>
									</div>
									<div class="col-md-12 col-sm-12 float-left">
										<div class="form-group">
											<label for="full_taxon_name">Full Taxon Name:</label>
											<input type="text" class="form-control-sm" id="full_taxon_name" value="#full_taxon_name#">
										</div>
										<div class="form-group">
											<label for="identification_remarks">Identification Remarks:</label>
											<textarea type="text" class="form-control" id="identification_remarks" value="#identification_remarks#"></textarea>
										</div>
										<div class="form-check">
											<input type="checkbox" class="form-check-input" id="materialUnchecked">
											<label class="mt-2 form-check-label" for="materialUnchecked">Stored as #scientific_name#</label>
										</div>
										<div class="form-group float-right">
											<button type="button" value="Create New Identification" class="btn btn-primary ml-2"
												 onClick="$('.dialog').dialog('open'); loadNewIdentificationForm(identification_id,'newIdentificationForm');">Create New Identification</button>
										</div>
									</div>
								</div>
							</form>
						</div>
			 		</cfloop> <!--- theResult --->
				</div>
			</cfoutput>
		<cfcatch>
			<cfoutput>
				<p class="mt-2 text-danger">Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#</p>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>

	<cfthread action="join" name="getIdentificationThread" />
	<cfreturn getIdentificationThread.output>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getIdentificationTable" returntype="query" access="remote">
	<cfargument name="identification_id" type="string" required="yes">
	<cfset r=1>
	<cftry>
	    <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
   			select 1 as status, identifications_id, collection_object_id, made_date, nature_of_id, accepted_id_fg,identification_remarks, taxa_formula, scientific_name, publication_id, sort_order, stored_as_fg
            from identification
            where identification_id  =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
		</cfquery>
		<cfif theResult.recordcount eq 0>
	  	  <cfset theResult=queryNew("status, message")>
		  <cfset t = queryaddrow(theResult,1)>
		  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
		  <cfset t = QuerySetCell(theResult, "message", "No shipments found.", 1)>
		</cfif>
	<cfcatch>
	  <cfset theResult=queryNew("status, message")>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
	  </cfcatch>
	</cftry>
    <cfif isDefined("asTable") AND asTable eq "true">
	    <cfreturn resulthtml>
    <cfelse>
   	    <cfreturn theResult>
    </cfif>
</cffunction>

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

<!--- obtain an html rendering of the condition history of a specimen part suitable for display in a dialog 
 @param collection_object_id the collection_object_id of the part for which to obtain the condition history
 @return html block listing condition history for the specified part
--->
<cffunction name="getPartConditionHistoryHTML" returntype="string" access="remote" returnformat="plain">
   <cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getPartCondHist">
		<cfoutput>
			<cftry>
				<!---- lookup cataloged item for collection object or part we are getting the condition history of ---->
				<cfquery name="itemDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						'cataloged item' part_name,
						cat_num,
						collection.collection,
						MCZBASE.get_scientific_name_auths(cataloged_item.collection_object_id) as scientific_name
					FROM
						cataloged_item
						left join collection on cataloged_item.collection_id = collection.collection_id
					WHERE
						cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					UNION
					SELECT
						part_name,
						cat_num,
						collection.collection,
						MCZBASE.get_scientific_name_auths(cataloged_item.collection_object_id) as scientific_name
					FROM
						cataloged_item
						left join collection on cataloged_item.collection_id = collection.collection_id
						left join specimen_part on  cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
					WHERE
						specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				</cfquery>

				<div>
					<strong>Condition History of #itemDetails.collection# #itemDetails.cat_num#
						(<i>#itemDetails.scientific_name#</i>) #itemDetails.part_name#
					</strong>
				</div>

				<!--- lookup part history --->
				<cfquery name="cond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						object_condition_id,
						determined_agent_id,
						agent_name,
						determined_date,
						condition
					FROM
						object_condition,preferred_agent_name
					where 
						determined_agent_id = agent_id and
						collection_object_id = #collection_object_id#
					group by
						object_condition_id,
						determined_agent_id,
						agent_name,
						determined_date,
						condition
					order by 
						determined_date DESC
				</cfquery>

				<table class="table table-responsive border table-striped table-sm">
					<tr>
						<td><strong>Determined By</strong></td>
						<td><strong>Date</strong></td>
						<td><strong>Condition</strong></td>
					</tr>
					<cfloop query="cond">
						<tr>
							<td>#encodeForHtml(agent_name)#</td>
							<td>#dateformat(determined_date,"yyyy-mm-dd")#</td>
							<td>#condition#</td>
						</tr>
					</cfloop>
				</table>
   		<cfcatch>
       		Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#
		   </cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getPartCondHist" />
	<cfreturn getPartCondHist.output>
</cffunction>

</cfcomponent>
