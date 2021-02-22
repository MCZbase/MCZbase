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
<!---
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
			
		<cfset resulthtml = resulthtml & "<div class='form-group float-right'><button type='button' value='Create New Identification' class='btn btn-primary ml-2' onClick=""$('.dialog-ID').dialog('open'); loadNewIdentificationForm(addIdentification_#collection_object_id#,'newIdentificationForm');"">Create New Identification</button></div> ">
			<cfset resulthtml = resulthtml & "</div></div></form>">
       
            <cfset resulthtml = resulthtml & "</div>"> 
      </cfloop> 

   <cfcatch>
       <cfset resulthtml = resulthtml & "Error:" & "#cfcatch.type# #cfcatch.message# #cfcatch.detail#">
   </cfcatch>
   </cftry>
     <cfoutput>#resulthtml#</cfoutput>
   </cfthread>
    <cfthread action="join" name="getIdentificationThread" />
    <cfreturn getIdentificationThread.output>
</cffunction>--->

	<!----------------------------------------------------------------------------------------------------------------->		
<cffunction name="getIdentificationByHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfset r=1>
	<cfthread name="getSBTHtmlThread">
		<cfoutput>
			<cftry>
				 <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select 1 as status, shipment_id, packed_by_agent_id, shipped_carrier_method, shipped_date, package_weight, no_of_packages,
								hazmat_fg, insured_for_insured_value, shipment_remarks, contents, foreign_shipment_fg, shipped_to_addr_id, carriers_tracking_number,
								shipped_from_addr_id, fromaddr.formatted_addr, toaddr.formatted_addr,
								toaddr.country_cde tocountry, toaddr.institution toinst, toaddr.formatted_addr tofaddr,
								fromaddr.country_cde fromcountry, fromaddr.institution frominst, fromaddr.formatted_addr fromfaddr,
								shipment.print_flag
						 from shipment
								left join addr fromaddr on shipment.shipped_from_addr_id = fromaddr.addr_id
								left join addr toaddr on shipment.shipped_to_addr_id = toaddr.addr_id
						 where shipment.transaction_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
						 order by shipped_date
				</cfquery>
				<div id='identificationHTML'>
				<cfloop query="theResult">
					<cfquery name="shippermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="shippermit_result">
							select permit.permit_id,
								issuedBy.agent_name as IssuedByAgent,
								issued_Date,
								renewed_Date,
								exp_Date,
								permit_Num,
								permit_Type
							from
								permit_shipment left join permit on permit_shipment.permit_id = permit.permit_id
								left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
							where
								permit_shipment.shipment_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#theResult.shipment_id#">
					</cfquery>
					<script>
						function reloadIdentification() { 
							console.log("reloadIdentification()"); 
							loadIdentification(#identification_id#); 
						} 
					</script>
						
<!---<div class='shipments bg-white border my-2'>
<table class='table table-responsive d-md-table mb-0'>
<thead class='thead-light'><th>Ship Date:</th><th>Method:</th><th>Packages:</th><th>Tracking Number:</th></thead>
<tbody>
	<tr>
		<td>#dateformat(shipped_date,'yyyy-mm-dd')#&nbsp;</td>
		<td>#shipped_carrier_method#&nbsp;</td>
		<td>#no_of_packages#&nbsp;</td>
		<td>#carriers_tracking_number#</td>
	</tr>
</tbody>
</table>
<table class='table table-responsive d-md-table'>
<thead class='thead-light'><tr><th>Shipped To:</th><th>Shipped From:</th></tr></thead>
<tbody>
	<tr>
		<td>(#printedOnInvoice#) #tofaddr#</td>
		<td>#fromfaddr#</td>
	</tr>
</tbody>
</table>
<div class='form-row'>
<div class='col-12 col-md-3 col-xl-2 mb-2'>
	<input type='button' value='Edit this Shipment' class='btn btn-xs btn-secondary' onClick="$('##dialog-shipment').dialog('open'); loadShipment(#shipment_id#,'shipmentForm');">
</div>
<div id='addPermit_#shipment_id#' class='col-12 mt-2 mt-md-0 col-md-9 col-xl-10'>
	<input type='button' value='Add Permit to this Shipment' class='btn btn-xs btn-secondary' onClick=" openlinkpermitshipdialog('addPermitDlg_#shipment_id#','#shipment_id#','Shipment #carriers_tracking_number#',reloadShipments); " >
</div>
<div id='addPermitDlg_#shipment_id#'></div>
</div>
<div class='shippermitstyle' tabindex="0">
<h4 class='font-weight-bold mb-0'>Permits:</h4>
<div class='permitship pb-2'>
	<ul id='permits_ship_#shipment_id#' tabindex="0" class="list-style-disc pl-4 pr-0">
		<cfloop query="shippermit">
			<cfquery name="mediaQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select media.media_id, media_uri, preview_uri, media_type,
					mczbase.get_media_descriptor(media.media_id) as media_descriptor
				from media_relations left join media on media_relations.media_id = media.media_id
				where media_relations.media_relationship = 'shows permit' 
					and media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#shippermit.permit_id#>
			</cfquery>
			<cfset mediaLink = "&##8855;">
			<cfloop query="mediaQuery">
				<cfset puri=getMediaPreview(preview_uri,media_type) >
				<cfif puri EQ "/images/noThumb.jpg">

					<cfset altText = "Red X in a red square, with text, no preview image available">
				<cfelse>

					<cfset altText = mediaQuery.media_descriptor>
				</cfif>
				<cfset mediaLink = "<a href='#media_uri#' target='_blank' rel='noopener noreferrer' ><img src='#puri#' height='20' alt='#altText#'></a>" >
			</cfloop>
				<li class="my-1">#mediaLink# #permit_type# #permit_Num# | Issued: #dateformat(issued_Date,'yyyy-mm-dd')# | By: #IssuedByAgent#
							<button type='button' class='btn btn-xs btn-secondary' onClick=' window.open("/transactions/Permit.cfm?Action=edit&permit_id=#permit_id#")' target='_blank' value='Edit'>Edit</button>
						<button type='button' 
							class='btn btn-xs btn-warning' 
							onClick='confirmDialog("Remove this permit from this shipment (#permit_type# #permit_Num#)?", "Confirm Remove Permit", function() { deletePermitFromShipment(#theResult.shipment_id#,#permit_id#,#transaction_id#); reloadShipments(#transaction_id#); } ); '
							value='Remove Permit'>Remove</button>
						<cfif theResult.recordcount GT 1>

							<button type='button' 
								onClick=' openMovePermitDialog(#transaction_id#,#theResult.shipment_id#,#permit_id#,"movePermitDlg_#theResult.shipment_id##permit_id#");' 
								class='btn btn-xs btn-warning' value='Move'>Move</button>
							<span id='movePermitDlg_#theResult.shipment_id##permit_id#'></span>
						</cfif>
				</li>
		</cfloop>
		</ul>
		<cfif shippermit.recordcount eq 0>
			<p class="mt-2">None</p>
		</cfif>
	</span>
</div>
</div>
<cfif shippermit.recordcount eq 0>
 <div class='deletestyle mb-1' id='removeShipment_#shipment_id#'>
	<input type='button' value='Delete this Shipment' class='delBtn btn btn-xs btn-danger' onClick=" confirmDialog('Delete this shipment (#theResult.shipped_carrier_method# #theResult.carriers_tracking_number#)?', 'Confirm Delete Shipment', function() { deleteShipment(#shipment_id#,#transaction_id#); }  ); " >
</div>
<cfelse>
<div class='deletestyle pb-1'>
	<input type='button' class='disBtn btn btn-xs btn-secondary' value='Delete this Shipment'>
</div>
</cfif>
</div>--->
						<form id="identificationForm">
							<div id="collapseID" class="collapse show" aria-labelledby="heading1" data-parent="##accordionB">
							<div class="card-body mb-2 float-left">
							<cfloop query="identification">
								<cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT distinct
										taxonomy.taxon_name_id,
										display_name,
										scientific_name,
										author_text,
										full_taxon_name 
									FROM 
										identification_taxonomy,
										taxonomy
									WHERE 
										identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id 
										AND identification_id = <cfqueryparam value="#identification_id#" cfsqltype="CF_SQL_DECIMAL">
								</cfquery>
								<cfif accepted_id_fg is 1>
									<ul class="list-group border-green rounded p-2 h4 font-weight-normal">
										<div class="d-inline-block mb-2 h4 text-success">Current Identification</div>
										<cfif getTaxa.recordcount is 1 and taxa_formula is 'a'>
											<div class="font-italic h4 mb-1 font-weight-lessbold d-inline-block"> <a href="/name/#getTaxa.scientific_name#" target="_blank">#getTaxa.display_name# </a>
											<cfif len(getTaxa.author_text) gt 0>
												<span class="sm-caps font-weight-lessbold">#getTaxa.author_text#</span>
											</cfif>
											</div>
											<cfelse>
											<cfset link="">
											<cfset i=1>
											<cfset thisSciName="#scientific_name#">
											<cfloop query="getTaxa">
												<span class="font-italic h4 font-weight-lessbold d-inline-block">
												<cfset thisLink='<a href="/name/#scientific_name#" class="d-inline" target="_blank">#display_name#</a>'>
												<cfset thisSciName=#replace(thisSciName,scientific_name,thisLink)#>
												<cfset i=#i#+1>
												<a href="##">#thisSciName#</a> <span class="sm-caps font-weight-lessbold">#getTaxa.author_text#</span> </span>
											</cfloop>
										</cfif>
										<cfif oneOfUs is 1 and stored_as_fg is 1>
											<span class="bg-gray float-right rounded p-1">STORED AS</span>
										</cfif>
										<cfif not isdefined("metaDesc")>
											<cfset metaDesc="">
										</cfif>
										<cfloop query="getTaxa">
											<div class="h5 mb-1 text-dark font-italic"> #full_taxon_name# </div>
											<cfset metaDesc=metaDesc & '; ' & full_taxon_name>
											<cfquery name="cName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												SELECT 
													common_name 
												FROM 
													common_name
												WHERE 
													taxon_name_id= <cfqueryparam value="#taxon_name_id#" cfsqltype="CF_SQL_DECIMAL"> 
													and common_name is not null
												GROUP BY 
													common_name order by common_name
											</cfquery>
											<cfif len(cName.common_name) gt 0><div class="h5 mb-1 text-muted font-weight-normal pl-3">Common Name(s): #valuelist(cName.common_name,"; ")# </div></cfif>
											<cfset metaDesc=metaDesc & '; ' & valuelist(cName.common_name,"; ")>
										</cfloop>
										<div class="form-row mx-0">
											<div class="small mr-2"><span class="h5">Determiner:</span> #agent_name#
												<cfif len(made_date) gt 0>
													<span class="h5">on Date:</span> #dateformat(made_date,"yyyy-mm-dd")#
												</cfif>
											</div>
										</div>
										<div class="small mr-2"><span class="h5">Nature of ID:</span> #nature_of_id# </div>
										<cfif len(identification_remarks) gt 0>
											<div class="small"><span class="h5">Remarks:</span> #identification_remarks#</div>
										</cfif>
									</ul>	
									<cfelse>
										<cfif getTaxa.recordcount gt 0>		
											<div class="h4 pl-4 mt-1 mb-0 text-success">Former Identifications</div>
										</cfif>
									<ul class="list-group py-1 px-3 ml-2 text-dark bg-light">
									<li class="px-0">
									<cfif getTaxa.recordcount is 1 and taxa_formula is 'a'>
										<span class="font-italic h4 font-weight-normal"><a href="/name/#getTaxa.scientific_name#" target="_blank">#getTaxa.display_name#</a></span>
										<cfif len(getTaxa.author_text) gt 0>
											<span class="color-black sm-caps">#getTaxa.author_text#</span>
										</cfif>
										<cfelse>
										<cfset link="">
										<cfset i=1>
										<cfset thisSciName="#scientific_name#">
										<cfloop query="getTaxa">
											<cfset thisLink='<a href="/name/#scientific_name#" target="_blank">#display_name#</a>'>
											<cfset thisSciName=#replace(thisSciName,scientific_name,thisLink)#>
											<cfset i=#i#+1>
										</cfloop>
										#thisSciName# 
									</cfif>
									<cfif oneOfUs is 1 and stored_as_fg is 1>
										<span style="float-right rounded p-1 bg-light">STORED AS</span>
									</cfif>
									<cfif not isdefined("metaDesc")>
										<cfset metaDesc="">
									</cfif>
									<cfloop query="getTaxa">
									
										<p class="small text-muted mb-0"> #full_taxon_name#</p>
										<cfset metaDesc=metaDesc & '; ' & full_taxon_name>
										<cfquery name="cName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												SELECT 
													common_name 
												FROM 
													common_name
												WHERE 
													taxon_name_id= <cfqueryparam value="#taxon_name_id#" cfsqltype="CF_SQL_DECIMAL"> 
													and common_name is not null
												GROUP BY 
													common_name order by common_name
										</cfquery>
										<cfif len(cName.common_name) gt 0><div class="small text-muted pl-3">Common Name(s): #valuelist(cName.common_name,"; ")#</div>
										<cfset metaDesc=metaDesc & '; ' & valuelist(cName.common_name,"; ")></cfif>
									</cfloop>
									<cfif len(formatted_publication) gt 0>
										sensu <a href="/publication/#publication_id#" target="_mainFrame"> #formatted_publication# </a>
									</cfif>
									<span class="small">Determination: #agent_name#
										<cfif len(made_date) gt 0>
											on #dateformat(made_date,"yyyy-mm-dd")#
										</cfif>
										<span class="d-block">Nature of ID: #nature_of_id#</span> 
									<cfif len(identification_remarks) gt 0>
										<span class="d-block">Remarks: #identification_remarks#</span>
									</cfif>
								</cfif>
								</li>
								</ul>
							</cfloop>
						</div>
							<div id="identificationHTML" class="dialog" title="Edit Identification (id: #identification_id#)"></div>
						</div>
						</form>
				</cfloop> <!--- theResult --->
							
				<cfif theResult.recordcount eq 0>
					<p class="mt-2">No Identifications found for this transaction.</p>
				</cfif>
					</div><!--- ID div --->
			<cfcatch>
				  <p class="mt-2 text-danger">Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#</p>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getSBTHtmlThread" />
	<cfreturn getSBTHtmlThread.output>
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
