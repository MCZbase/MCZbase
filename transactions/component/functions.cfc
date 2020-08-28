<!---
/transactions/component/functions.cfc

Copyright 2020 President and Fellows of Harvard College

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
<cfcomponent>

<cfinclude template = "/shared/functionLib.cfm">

<cffunction name="checkAgentFlag" access="remote">
	<cfargument name="agent_id" type="numeric" required="yes">
	<cfquery name="checkAgentQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select MCZBASE.get_worstagentrank(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">) as agentrank from dual
	</cfquery>
	<cfreturn checkAgentQuery>
</cffunction>
<!-------------------------------------------->
<!--- obtain counts of loan items --->
<cffunction name="getLoanItemCounts" access="remote">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfif listcontainsnocase(session.roles,"admin_transactions")>
		<cfquery name="rankCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				1 as status,
				count(distinct cataloged_item.collection_object_id) catItemCount,
				count(distinct collection.collection_cde) as collectionCount,
				count(distinct preserve_method) as preserveCount,
				count(distinct specimen_part.collection_object_id) as partCount
			FROM
				loan_item,
				loan,
				specimen_part,
				coll_object,
				cataloged_item,
				coll_object_encumbrance,
				encumbrance,
				agent_name,
				identification,
				collection
			WHERE
				loan_item.collection_object_id = specimen_part.collection_object_id AND
				loan.transaction_id = loan_item.transaction_id AND
				specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
				specimen_part.collection_object_id = coll_object.collection_object_id AND
				coll_object.collection_object_id = coll_object_encumbrance.collection_object_id (+) and
				coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id (+) AND
				encumbrance.encumbering_agent_id = agent_name.agent_id (+) AND
				cataloged_item.collection_object_id = identification.collection_object_id AND
				identification.accepted_id_fg = 1 AND
				cataloged_item.collection_id=collection.collection_id AND
				loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
	<cfelse>
		<cfset rankCount=queryNew("status, message")>
		<cfset t = queryaddrow(rankCount,1)>
		<cfset t = QuerySetCell(rankCount, "status", "-1", 1)>
		<cfset t = QuerySetCell(rankCount, "message", "Not Authorized", 1)>
	</cfif>
	<cfreturn rankCount>
</cffunction>


<!-------------------------------------------->
<!--- obtain an html block listing the media for a transaction  --->
<cffunction name="getMediaForTransHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="transaction_type" type="string" required="yes">
	<cfset relword="documents">
	<cfset result="">
	<cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct
			media.media_id as media_id,
			preview_uri,
			media.media_uri,
			media.mime_type,
			media.media_type as media_type,
			MCZBASE.is_media_encumbered(media.media_id) as hideMedia,
			nvl(MCZBASE.get_medialabel(media.media_id,'description'),'[No Description]') as label_value
		from
			media_relations left join media on media_relations.media_id = media.media_id
		where
			media_relationship like <cfqueryparam value="% #transaction_type#" cfsqltype="CF_SQL_VARCHAR">
			and media_relations.related_primary_key = <cfqueryparam value="#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
	</cfquery>
	<cfif query.recordcount gt 0>
		<cfset result=result & "<ul>">
		<cfloop query="query">
			<cfset puri=getMediaPreview(preview_uri,media_type) >
			<cfset result = result & "<li><a href='#media_uri#' target='_blank' rel='noopener noreferrer'><img src='#puri#' height='15'></a> #mime_type# #media_type# #label_value# <a href='/media/#media_id#' target='_blank'>Media Details</a>  <a class='btn btn-xs btn-warning' onClick='  confirmDialog(""Remove this media from this transaction?"", ""Confirm Unlink Media"", function() { removeMediaFromTrans(#media_id#,#transaction_id#,""#relWord# #transaction_type#""); } ); '>Remove</a> </li>" >
		</cfloop>
		<cfset result= result & "</ul>">
	<cfelse>
		<cfset result=result & "<ul><li>None</li></ul>">
	</cfif>
	<cfreturn result>
</cffunction>

<!---  Obtain the list of shipments and their permits for a transaction formatted in html for display on a transaction page --->
<!---  @param transaction_id  the transaction for which to obtain a list of shipments and their permits.  --->
<!---  @return html list of shipments and permits, including editing controls for adding/editing/removing shipments and permits. --->
<cffunction name="getShipmentsByTransHtml" returntype="string" access="remote" returnformat="plain">
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
				<div id='shipments' class='shipments'>
				<cfloop query="theResult">
					<cfif print_flag eq "1">
						<cfset printedOnInvoice = "&##9745; Printed on invoice">
					<cfelse>
						<cfset printedOnInvoice = "<span class='infoLink' onClick=' setShipmentToPrint(#shipment_id#,#transaction_id#); ' >&##9744; Not Printed</span>">
					</cfif>
					<cfquery name="shippermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
								permit_shipment.shipment_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
					</cfquery>
					<script>function reloadShipments() { loadShipments(#transaction_id#); } </script>
						
					<div class='shipment my-2'>
						<table class='table table-sm'>
						<thead class='thead-light'><th>Ship Date:</th><th>Method:</th><th>Packages:</th><th>Tracking Number:</th></thead>
						<tbody><tr>
						<td>#dateformat(shipped_date,'yyyy-mm-dd')#&nbsp;</td>
						<td>#shipped_carrier_method#&nbsp;</td>
						<td>#no_of_packages#&nbsp;</td>
						<td>#carriers_tracking_number#</td>
						</tr></tbody></table>
						<table class='table table-sm'><thead class='thead-light'><tr><th>Shipped To:</th><th>Shipped From:</th></tr></thead>
						<tbody><tr><td>(#printedOnInvoice#) #tofaddr#</td>
						<td>#fromfaddr#</td>
						</tr></tbody></table>
						<div class='form-row'>
						<div class='col-5'><input type='button' value='Edit this Shipment' class='btn btn-xs btn-secondary' onClick="$('##dialog-shipment').dialog('open'); loadShipment(#shipment_id#,'shipmentForm');"></div>
						<div id='addPermit_#shipment_id#' class='col-6'><input type='button' value='Add Permit to this Shipment' class='btn btn-xs btn-secondary' onClick=" openlinkpermitshipdialog('addPermitDlg_#shipment_id#','#shipment_id#','Shipment: #carriers_tracking_number#',reloadShipments); " ></div>
						<div id='addPermitDlg_#shipment_id#'></div>
						</div>
						<div class='shippermitstyle'><h4 class='font-weight-bold mb-0'>Permits:</h4>
						<div class='permitship pb-2'><span id='permits_ship_#shipment_id#'>
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
								<cfset mediaLink = "<a href='#media_uri#' target='_blank' rel='noopener noreferrer' ><img src='#puri#' height='15' alt='#altText#'></a>" >
							</cfloop>
							<ul class='permitshipul'><li><span>#mediaLink# #permit_type# #permit_Num#</span></li><li>Issued: #dateformat(issued_Date,'yyyy-mm-dd')#</li><li style='width:300px;'> #IssuedByAgent#</li></ul>
							<ul class='permitshipul2'>
								<li><input type='button' class='savBtn btn btn-xs btn-secondary' onClick=' window.open("Permit.cfm?Action=editPermit&permit_id=#permit_id#")' target='_blank' value='Edit'></li>
								<li><input type='button' class='delBtn btn btn-xs btn-secondary mr-1' onClick='confirmDialog("Remove this permit from this shipment (#permit_type# #permit_Num#)?", "Confirm Remove Permit", function() { deletePermitFromShipment(#theResult.shipment_id#,#permit_id#,#transaction_id#); } ); ' value='Remove Permit'></li>
								<li>
									<input type='button' onClick=' opendialog("picks/PermitPick.cfm?Action=movePermit&permit_id=#permit_id#&transaction_id=#transaction_id#&current_shipment_id=#theResult.shipment_id#","##movePermitDlg_#theResult.shipment_id##permit_id#","Move Permit to another Shipment");' class='lnkBtn btn btn-xs btn-secondary' value='Move'>
									<span id='movePermitDlg_#theResult.shipment_id##permit_id#'></span>
								</li>
							</ul>
						</cfloop>
						<cfif shippermit.recordcount eq 0>
							<span>None</span>
						</cfif>
						</span></div></div> <!--- span#permit_ships_, div.permitship div.shippermitsstyle --->
						<cfif shippermit.recordcount eq 0>
							 <div class='deletestyle mb-1' id='removeShipment_#shipment_id#'>
								<input type='button' value='Delete this Shipment' class='delBtn btn btn-xs btn-warning' onClick=" confirmDialog('Delete this shipment (#theResult.shipped_carrier_method# #theResult.carriers_tracking_number#)?', 'Confirm Delete Shipment', function() { deleteShipment(#shipment_id#,#transaction_id#); }  ); " >
							</div>
						<cfelse>
							 <div class='deletestyle pb-1'><input type='button' class='disBtn btn btn-xs btn-secondary' value='Delete this Shipment'></div>
						</cfif>
							</div> <!--- shipment div --->
				</cfloop> <!--- theResult --->
							
				<cfif theResult.recordcount eq 0>
					 <span>No shipments found for this transaction.</span>
				</cfif>
					</div><!--- shipments div --->
			<cfcatch>
				 <span>Error: #cfcatch.type# #cfcatch.message# #cfcatch.detail#</span>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getSBTHtmlThread" />
	<cfreturn getSBTHtmlThread.output>
</cffunction>

<!---
  ** method getShipments returns a details of shipments matching a provided list of shipmentIDs,
  * this method is used to populate the shipment dialog for transactions to edit a shipment, where
  * it is provided with a single shipment_id in shipmentIdList 
  * 
  * @param a comma separated list of one or more shipment_id values for which to look up the shipment details.
  * @return a serialization of a query object
--->
<cffunction name="getShipments" returntype="query" access="remote">
	<cfargument name="shipmentidList" type="string" required="yes">
	<cftry>
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 1 as status, shipment_id, transaction_id,
				packed_by_agent_id, 
				mczbase.get_agentnameoftype(packed_by_agent_id,'preferred') packed_by_agent, 
				carriers_tracking_number,
				shipped_carrier_method, to_char(shipped_date, 'yyyy-mm-dd') as shipped_date, 
				package_weight, no_of_packages,
				hazmat_fg, insured_for_insured_value, shipment_remarks, contents, foreign_shipment_fg, shipped_to_addr_id,
				shipped_from_addr_id, 
				fromaddr.formatted_addr as shipped_from_address, 
				toaddr.formatted_addr as shipped_to_address,
				shipment.print_flag
			from shipment
				left join addr fromaddr on shipment.shipped_from_addr_id = fromaddr.addr_id
				left join addr toaddr on shipment.shipped_to_addr_id = toaddr.addr_id
			where 
				shipment_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipmentIdList#" list="yes">)
		</cfquery>
		<cfif theResult.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No shipments found.", 1)>
		</cfif>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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
	<cfreturn theResult>
</cffunction>


<!--- 
 ** method removePermitFromShipment deletes a relationship between a permit and a shipment.
 *  @param permit_id the permissions and rights document the shipment is linked to.
 *  @param shipment_id the id of the shipment to from which to unlink the permit_id.
--->
<cffunction name="removePermitFromShipment" returntype="query" access="remote">
	<cfargument name="permit_id" type="string" required="yes">
	<cfargument name="shipment_id" type="string" required="yes">
	
	<cfset theResult=queryNew("status, message")>
	<cftry>
		<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResultRes">
			delete from permit_shipment
			where permit_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
			and shipment_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
		</cfquery>
		<cfif deleteResultRes.recordcount eq 0>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No records deleted. #permit_id# #shipment_id# #deleteResult.sql#", 1)>
		</cfif>
		<cfif deleteResultRes.recordcount eq 1>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
		</cfif>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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
	<cfreturn theResult>
</cffunction>

<!--- 
 ** method removeShipment deletes a shipment record.
 *  @param transaction_id the id of the transaction thie shipment is part of.
 *  @param shipment_id the id of the shipment to delete.
--->
<cffunction name="removeShipment" returntype="query" access="remote">
	<cfargument name="shipment_id" type="string" required="yes">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfset r=1>
	<cftransaction>
		<cftry>
			<cfquery name="countPermits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="countPermits_result">
				select count(*) as ct 
				from permit_shipment
			 	where shipment_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
			</cfquery>
			<cfif countPermits.ct EQ 0 >
				<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="delete_result">
					delete from shipment
					where transaction_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
					and shipment_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
				</cfquery>
				<cfif delete_result.recordcount eq 0>
					<cfset theResult=queryNew("status, message")>
					<cfset t = queryaddrow(theResult,1)>
					<cfset t = QuerySetCell(theResult, "status", "0", 1)>
					<cfset t = QuerySetCell(theResult, "message", "No records deleted. #shipment_id# #delete_result.sql#", 1)>
				</cfif>
				<cfif delete_result.recordcount eq 1>
					<cfset theResult=queryNew("status, message")>
					<cfset t = queryaddrow(theResult,1)>
					<cfset t = QuerySetCell(theResult, "status", "1", 1)>
					<cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
				</cfif>
			<cfelse>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "0", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Can't delete shipment with attached permits.", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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
	</cftransaction>
	<cfreturn theResult>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->

<cffunction name="getPermitsForTransHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfset resulthtml="">
	<cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct permit_num, permit_type, issued_date, permit.permit_id,
			issuedBy.agent_name as IssuedByAgent
		from permit left join permit_trans on permit.permit_id = permit_trans.permit_id
			left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
		where permit_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#transaction_id#>
		order by permit_type, issued_date
	</cfquery>

	<cfset resulthtml = resulthtml & "<div class='permittrans'><span id='permits_tr_#transaction_id#'>">
	<cfloop query="query">
		<cfquery name="mediaQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select media.media_id, media_uri, preview_uri, media_type
			from media_relations left join media on media_relations.media_id = media.media_id
			where media_relations.media_relationship = 'shows permit'
				and media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#permit_id#>
		</cfquery>
		<cfset mediaLink = "&##8855;">
		<cfset getMediaPreview = ''>
			<cfloop query="mediaQuery">
			<cfset puri=getMediaPreview(preview_uri,media_type) >
			<cfif puri EQ "/images/noThumb.jpg">
				<cfset altText = "Red X in a red square, with text, no preview image available">
			<cfelse>
				<cfset altText = mediaQuery.media_descriptor>
			</cfif>
		<cfset mediaLink = "<a href='#media_uri#'target='_blank' rel='noopener noreferrer'><img src='#puri#' height='15' alt='#altText#'></a>" >
	</cfloop>
		<cfset resulthtml = resulthtml & "<ul class='permitshipul'><li><span>#mediaLink# #permit_type# #permit_Num#</span></li><li>Issued: #dateformat(issued_Date,'yyyy-mm-dd')#</li><li style='width:300px;'>#IssuedByAgent#</li></ul>">


		<cfset resulthtml = resulthtml & "<ul class='permitshipul2'>">
		<cfset resulthtml = resulthtml & "<li><input type='button' class='savBtn btn btn-xs btn-secondary pr-1' onClick=' window.open(""Permit.cfm?Action=editPermit&permit_id=#permit_id#"")' target='_blank' value='Edit'></li> ">
		<cfset resulthtml = resulthtml & "<li><input type='button' class='delBtn btn btn-xs btn-secondary pr-1' onClick='confirmDialog(""Remove this permit from this Transaction (#permit_type# #permit_Num#)?"", ""Confirm Remove Permit"", function() { deletePermitFromTransaction(#permit_id#,#transaction_id#); } ); ' value='Remove Permit'></li>">
		<cfset resulthtml = resulthtml & "</ul>">
	</cfloop>
	<cfif query.recordcount eq 0>
		 <cfset resulthtml = resulthtml & "None">
	</cfif>
	<cfset resulthtml = resulthtml & "</span></div>"> <!--- span#permit_tr_, div.permittrans --->

	<cfreturn resulthtml>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getPermitsForShipment" returntype="string" access="remote" returnformat="plain">
	<cfargument name="shipment_id" type="string" required="yes">
	<cfset result="">
	<cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct permit_num, permit_type, issued_date, permit.permit_id,
			issuedBy.agent_name as IssuedByAgent
		from permit_shipment left join permit on permit_shipment.permit_id = permit.permit_id
			left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
		where permit_shipment.shipment_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#shipment_id#>
		order by permit_type, issued_date
	</cfquery>
	<cfif query.recordcount gt 0>
		<cfset result="<ul>">
		<cfloop query="query">
			<cfquery name="mediaQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select media.media_id, media_uri, preview_uri, media_type
				from media_relations left join media on media_relations.media_id = media.media_id
				where media_relations.media_relationship = 'shows permit'
					and media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#query.permit_id#>
			</cfquery>
		 	<cfset mediaLink = "&##8855;">
			<cfloop query="mediaQuery">
				<cfset mediaLink = "<a href='#media_uri#' target='_blank' rel='noopener noreferrer'><img src='#getMediaPreview(preview_uri,media_type)#' height='15'></a>" >
			</cfloop>
			<cfset result = result & "<li><span>#mediaLink# #permit_type# #permit_num# Issued:#dateformat(issued_date,'yyyy-mm-dd')# #IssuedByAgent#</span></li>">
		</cfloop>
		<cfset result= result & "</ul>">
	</cfif>
	<cfreturn result>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!--- backing for a permit autocomplete control --->
<cffunction name="getPermitAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select distinct permit_num, permit_type, specific_type, permit_title, to_char(issued_date,'YYYY-MM-DD') as issued_date, permit.permit_id,
				issuedBy.agent_name as IssuedByAgent
			from permit_shipment left join permit on permit_shipment.permit_id = permit.permit_id
				left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
			where upper(permit_num) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(term)#%">
					OR upper(permit_title) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(term)#%">
			order by permit_num, specific_type, issued_date
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.permit_id#">
			<cfif len(search.issued_date) gt 0><cfset i_date= ", " & search.issued_date><cfelse><cfset i_date=""></cfif>
			<cfset row["value"] = "#search.permit_num# #search.permit_title# (#search.specific_type##i_date#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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

<!--- backing for a loan autocomplete control --->
<cffunction name="getLoanAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select distinct
				trans.transaction_id,
				to_char(trans_date,'YYYY-MM-DD') trans_date,
				loan_number,
				loan_status,
				concattransagent(trans.transaction_id,'received by') rec_agent
			from 
				loan left join trans on loan.transaction_id = trans.transaction_id
			where upper(loan_number) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(term)#%">
			order by loan_number
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.transaction_id#">
			<cfset row["value"] = "#search.loan_number#" >
			<cfset row["meta"] = "#search.loan_number# (#search.loan_status# #loan.trans_date# #loan.rec_agent#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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

<!--- obtain an html block for picking permits for a permit text control and permit_id control  --->
<cffunction name="queryPermitPickerHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="valuecontrol" type="string" required="yes">
	<cfargument name="idcontrol" type="string" required="yes">
	<cfargument name="dialog" type="string" required="yes">
	<cfset result="">
	<cftry>
		<cfquery name="ctPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select ct.permit_type, count(p.permit_id) uses from ctpermit_type ct left join permit p on ct.permit_type = p.permit_type
				group by ct.permit_type
				order by ct.permit_type
		</cfquery>
		<cfquery name="ctSpecificPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select ct.specific_type, count(p.permit_id) uses from ctspecific_permit_type ct left join permit p on ct.specific_type = p.specific_type
				group by ct.specific_type
				order by ct.specific_type
		</cfquery>
		<cfset result = '
				<h3>Search for permits.</h3>
   			<form id="findPermitSearchForm" name="findPermit">
					<input type="hidden" name="method" value="getPermitsJSON" class="keeponclear">
					<div class="form-row mb-2">
						<div class="col-12 col-md-6">
							<label for="issuedByAgent" class="data-entry-label mb-0">Issued By</label>
							<input type="text" name="issuedByAgent" id="issuedByAgent" class="data-entry-input">
						</div>
						<div class="col-12 col-md-6">
							<label for="issuedToAgent"class="data-entry-label mb-0">Issued To</label>
							<input type="text" name="issuedToAgent" id="issuedToAgent" class="data-entry-input">
						</div>
					</div>
					<div class="form-row mb-2">
						<div class="col-12 col-md-6">
							<label for="issued_date" class="data-entry-label mb-0">Issued Date</label>
							<input type="text" name="issued_date" id="issued_date" class="data-entry-input">
						</div>
						<div class="col-12 col-md-6">
							<label for="renewed_date" class="data-entry-label mb-0">Renewed Date</label>
							<input type="text" name="renewed_date" id="renewed_date" class="data-entry-input">
						</div>
					</div>
					<div class="form-row mb-2">
						<div class="col-12 col-md-6">
							<label for="exp_date" class="data-entry-label mb-0">Expiration Date</label>
							<input type="text" name="exp_date" id="exp_date" class="data-entry-input">
						</div>
						<div class="col-12 col-md-6">
							<label for="permit_num_search" class="data-entry-label">Permit Number</label>
							<input type="text" name="permit_num" id="permit_num_search" class="data-entry-input">
						</div>
					</div>
					<div class="form-row mb-2">
						<div class="col-12 col-md-6">
							<label for="permit_type" class="data-entry-label mb-0">Permit Type</label>
							<select name="permit_Type" id="permit_type" class="data-entry-select w-75">
								<option value=""></option>
		'>
								<cfloop query="ctPermitType">
									<cfset result = result & '<option value = "#ctPermitType.permit_type#">#ctPermitType.permit_type# (#ctPermitType.uses#)</option>' >
								</cfloop>
		<cfset result = result & '
							</select>
						</div>
						<div class="col-12 col-md-6">
							<label for="permit_remarks" class="data-entry-label mb-0">Remarks</label>
							<input type="text" name="permit_remarks" class="data-entry-input">
						</div>
					</div>
					<div class="form-row mb-2">
						<div class="col-12 col-md-6">
							<label for="specific_type" class="data-entry-label mb-0">Specific Type</label>
							<select name="specific_type" class="data-entry-select w-75">
								<option value=""></option>
		'>
								<cfloop query="ctSpecificPermitType">
									<cfset result = result & '<option value = "#ctSpecificPermitType.specific_type#">#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.uses#)</option>' >
								</cfloop>
		<cfset result = result & '
							</select>
						</div>
						<div class="col-12 col-md-6">
							<label for="permit_title" class="data-entry-label mb-0">Permit Title</label>
							<input type="text" name="permit_title" class="data-entry-input">
						</div>
					</div>
					<div class="form-row mb-2">
						<div class="col-12 col-md-6">
							<button type="submit" aria-label="Search for Permits" class="btn-xs btn-primary">Search<span class="fa fa-search pl-1"></span></button>
						</div>
					</div>
				</form>

				<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
					<h4>Results: </h4>
					<span class="d-block px-3 p-2" id="permitPickResultCount"></span> <span id="permitPickResultLink" class="d-block p-2"></span>
				</div>
				<div class="row mt-0">
					<div id="permitPickSearchText"></div>
					<div id="permitPickResultsGrid" class="jqxGrid"></div>
					<div id="enableselection"></div>
				</div>
				<script>
   				$("##findPermitSearchForm").bind("submit", function(evt){
      				evt.preventDefault();
						$("##permitPickResultsGrid").replaceWith(''<div id="permitPickResultsGrid" class="jqxGrid"></div>'');
						$("##permitPickResultCount").html("");
						$("##permitPickResultLink").html("");
						$("##permitPickSearchText").jqxGrid("showloadelement");

					   var permitSearch = {
							datatype: "json",
							datafields: [
								{ name: "permit_id", type: "string" },
                        { name: "permit_num", type: "string" }, 
                        { name: "permit_type", type: "string" }, 
                        { name: "specific_type", type: "string" }, 
                        { name: "permit_title", type: "string" }, 
                        { name: "issued_date", type: "string" }, 
                        { name: "renewed_date", type: "string" },
                        { name: "exp_date", type: "string" },
                        { name: "permit_remarks", type: "string" },
                        { name: "IssuedByAgent", type: "string" },
                        { name: "IssuedToAgent", type: "string" }
							],
							root: "permitRecord",
							id: "permit_id",
							url: "/transactions/component/functions.cfc?" + $("##findPermitSearchForm").serialize()
						};

						var dataAdapter = new $.jqx.dataAdapter(permitSearch);

						var linkcellrenderer = function (index, datafield, value, defaultvalue, column, rowdata) { 
							var pvalue =  rowdata.permit_num + " " + rowdata.permit_title + " (" + $.trim(rowdata.specific_type + " " + rowdata.issued_date) + ")";
							var result = "<button class=\"btn btn-primary\" onclick=\" $(''###idcontrol#'').val( ''" +  value + "''); $(''###valuecontrol#'').val(''" + pvalue + "''); $(''###dialog#'').dialog(''close''); \">Select</button>";
							return result;
						};

						$("##permitPickResultsGrid").jqxGrid({
							width: "100%",
							autoheight: "true",
							source: dataAdapter,
							filterable: true,
							sortable: true,
							pageable: true,
							editable: false,
							pagesize: "50",
							pagesizeoptions: ["50","100"],
							showaggregates: false,
							columnsresize: true,
							autoshowfiltericon: true,
							autoshowcolumnsmenubutton: false,
							columnsreorder: true,
							groupable: false,
							selectionmode: "none",
							altrows: true,
							showtoolbar: false,
							columns: [
								{text: "Select", datafield: "permit_id", width: 100, hideable: false, hidden: false, cellsrenderer: linkcellrenderer }, 
								{text: "permit_num", datafield: "permit_num", width: 100, hideable: true, hidden: false }, 
								{text: "permit_type", datafield: "permit_type", width: 100, hideable: true, hidden: false }, 
								{text: "specific_type", datafield: "specific_type", width: 100, hideable: true, hidden: false }, 
								{text: "permit_title", datafield: "permit_title", width: 100, hideable: true, hidden: false }, 
								{text: "issued_date", datafield: "issued_date", width: 100, hideable: true, hidden: false }, 
								{text: "renewed_date", datafield: "renewed_date", width: 100, hideable: true, hidden: false },
								{text: "exp_date", datafield: "exp_date", width: 100, hideable: true, hidden: false },
								{text: "permit_remarks", datafield: "permit_remarks", width: 100, hideable: true, hidden: false }, 
								{text: "IssuedByAgent", datafield: "IssuedByAgent", width: 100, hideable: true, hidden: false },
								{text: "IssuedToAgent", datafield: "IssuedToAgent", width: 100, hideable: true, hidden: false }
         				]
						});
					});
				</script>
		'>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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

	<cfreturn result>
</cffunction>

<!---  Given a shipment_id, return a block of html code for a permit picking dialog to pick permits for the given
       shipment.
       @param shipment_id the transaction to which selected permits are to be related.
       @return html content for a permit picker dialog for transaction permits or an error message if an exception was raised.

       @see setShipmentForPermit 
       @see findPermitShipSearchResults  
--->
<cffunction name="shipmentPermitPickerHtml" returntype="string" access="remote">
	<cfargument name="shipment_id" type="string" required="yes">
	<cfargument name="shipment_label" type="string" required="yes">
   
	<cfthread name="getSPPHtmlThread">
 	<cftry>
		<cfquery name="ctPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select ct.permit_type, count(p.permit_id) uses 
			from ctpermit_type ct left join permit p on ct.permit_type = p.permit_type 
			group by ct.permit_type
			order by ct.permit_type
		</cfquery>
		<cfquery name="ctSpecificPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select ct.specific_type, count(p.permit_id) uses 
			from ctspecific_permit_type ct left join permit p on ct.specific_type = p.specific_type
			group by ct.specific_type
			order by ct.specific_type
		</cfquery>
		<cfoutput>
			<h3>Search for Permissions &amp; Rights documents. Any part of dates and names accepted, case isn't important.</h3>
			<form id='findPermitForm' onsubmit='searchforpermits(event);' class="container">
				<input type='hidden' name='method' value='findPermitShipSearchResults'>
				<input type='hidden' name='returnformat' value='plain'>
				<input type='hidden' name='shipment_id' value='#shipment_id#'>
				<input type='hidden' name='shipment_label' value='#shipment_label#'>
				<div class="row">
					<div class="col-12 col-md-3">
						<label for="pf_issuedByAgent">Issued By</label>
						<input type='text' name='IssuedByAgent' id="pf_issuedByAgent">
					</div>
					<div class="col-12 col-md-3">
						<label for="pf_issuedToAgent">Issued To<label>
						<input type='text' name='IssuedToAgent' id="pf_issuedToAgent">
					</div>
					<div class="col-12 col-md-3">
						<label for="pf_issued_date">Issued Date</label>
						<input type='text' name='issued_Date' id="pf_issued_date">
					</div>
					<div class="col-12 col-md-3">
						<label for="pf_renewed_date">Renewed Date</label>
						<input type='text' name='renewed_Date' id="pf_renewed_date">
					</div>
				</div>
				<div class="row">
					<div class="col-12 col-md-6">
						<label>Expiration Date</label>
						<input type='text' name='exp_Date'>
					</div>
					<div class="col-12 col-md-3">
						<label>Permit Number</label>
						<input type='text' name='permit_Num' id='permit_Num'>
					</div>
					<div class="col-12 col-md-3">
						<label>Permit Type</label>
						<select name='permit_Type' size='1' style='width: 15em;'>
							<option value=''></option>
							<cfloop query='ctPermitType'>
								<option value = '#ctPermitType.permit_type#'>#ctPermitType.permit_type# (#ctPermitType.uses#)</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-3">
						<label>Remarks</label>
						<input type='text' name='permit_remarks'>
					</div>
				</div>
				<div class="row">
					<div class="col-12 col-md-6">
						<label>Specific Type</label>
						<select name='specific_type' size='1' style='width: 15em;'>
							<option value=''></option>
							<cfloop query='ctSpecificPermitType'>
								<option value = '#ctSpecificPermitType.specific_type#'>#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.uses#)</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-6">
						<label>Permit Title</label>
						<input type='text' name='permit_title'>
					</div>
				</div>
				<div class="row">
					<div class="col-12 col-md-6">
						<input type='submit' value='Search' class='schBtn'>	
						<script>
							function createPermitDialogDone () { 
								$('##permit_Num').val($('##permit_number_passon').val()); 
							};
						</script>
						<input type='reset' value='Clear' class='clrBtn'>
					</div>
					<div class="col-12 col-md-6">
						<span id='createPermit_#shipment_id#_span'><input type='button' style='margin-left: 30px;' value='New Permit' class='lnkBtn' onClick='opencreatepermitdialog("createPermitDlg_#shipment_id#","#shipment_label#", #shipment_id#, "shipment", createPermitDialogDone);' ></span>
						<div id='createPermitDlg_#shipment_id#'></div>
					</div>
				</div>
			</form>
			<script language='javascript' type='text/javascript'>
				function searchforpermits(event) { 
					event.preventDefault();
					// to debug ajax call on component getting entire page redirected to blank page uncomment to create submission
					// console.log($('##findPermitForm').serialize());
					jQuery.ajax({
						url: '/transactions/component/functions.cfc',
						type: 'post',
						data: $('##findPermitForm').serialize(),
						success: function (data) {
							$('##permitSearchResults').html(data);
						},
						fail: function (jqXHR, textStatus, error) {
							handleFail(jqXHR,textStatus,error,'removing project from transaction record');
							$('##permitSearchResults').html('Error:' + textStatus);
						}
					});
					return false; 
				};
			</script>
			<div id='permitSearchResults'></div>
		</cfoutput>
	<cfcatch>
		<cfoutput>
			<h2>Error: #cfcatch.Message# #cfcatch.Detail#</h2>
		</cfoutput>
	</cfcatch>
	</cftry>
	</cfthread>
	<cfthread action="join" name="getSPPHtmlThread" />
	<cfreturn getSPPHtmlThread.output>
</cffunction>

<!--- backing for a permit lookup method returning json for permit table --->
<cffunction name="getPermitsJSON" access="remote" returntype="any" returnformat="json">
	<cfargument name="issuedByAgent" type="string" required="no">
	<cfargument name="issuedToAgent" type="string" required="no">
	<cfargument name="issued_date" type="string" required="no">
	<cfargument name="renewed_date" type="string" required="no">
	<cfargument name="exp_date" type="string" required="no">
	<cfargument name="permit_num" type="string" required="no">
	<cfargument name="permit_type" type="string" required="no">
	<cfargument name="specific_type" type="string" required="no">
	<cfargument name="permit_title" type="string" required="no">
	<cfargument name="permit_remarks" type="string" required="no">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select distinct 
				permit.permit_id,
				permit_num, 
				permit_type, 
				specific_type, 
				permit_title, 
				to_char(issued_date,'YYYY-MM-DD') as issued_date, 
				to_char(renewed_date,'YYYY-MM-DD') as renewed_date,
				to_char(exp_date,'YYYY-MM-DD') as exp_date,
   			permit_remarks,
				issuedBy.agent_name as IssuedByAgent,
				issuedTo.agent_name as IssuedToAgent
			from permit left join permit_shipment on permit.permit_id = permit_shipment.permit_id
				left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
				left join preferred_agent_name issuedTo on permit.issued_to_agent_id = issuedTo.agent_id
			where permit.permit_id is not null
				<cfif isdefined("issuedByAgent") AND len(#issuedByAgent#) gt 0>
					AND upper(issuedBy.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(issuedByAgent)#%">
				</cfif>
				<cfif isdefined("issuedToAgent") AND len(#issuedToAgent#) gt 0>
					AND upper(issuedTo.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(issuedToAgent)#%">
				</cfif>
				<cfif isdefined("issued_date") AND len(#issued_date#) gt 0>
					AND upper(issued_date) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(issued_date)#%">
				</cfif>
				<cfif isdefined("renewed_date") AND len(#renewed_date#) gt 0>
					AND upper(renewed_date) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(renewed_date)#%">
				</cfif>
				<cfif isdefined("exp_date") AND len(#exp_date#) gt 0>
					AND upper(exp_date) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(exp_date)#%">
				</cfif>
				<cfif isdefined("permit_num") AND len(#permit_num#) gt 0>
					AND upper(permit_num) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(permit_num)#%">
				</cfif>
				<cfif isdefined("specific_type") AND len(#specific_type#) gt 0>
					AND upper(specific_type) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(specific_type)#%">
				</cfif>
				<cfif isdefined("permit_type") AND len(#permit_type#) gt 0>
					AND upper(permit_type) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(permit_type)#%">
				</cfif>
				<cfif isdefined("permit_title") AND len(#permit_title#) gt 0>
					AND upper(permit_title) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(permit_title)#%">
				</cfif>
				<cfif isdefined("permit_remarks") AND len(#permit_remarks#) gt 0>
					AND upper(permit_remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(permit_remarks)#%">
				</cfif>
			order by permit_num, specific_type, issued_date
		</cfquery>

		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.permit_id#">
			<cfset row["permit_id"] = "#search.permit_id#">
			<cfset row["permit_num"] = "#search.permit_num#">
			<cfset row["permit_type"] = "#search.permit_type#">
			<cfset row["specific_type"] = "#search.specific_type#">
			<cfset row["permit_title"] = "#search.permit_title#">
			<cfset row["permit_remarks"] = "#search.permit_remarks#">
			<cfset row["issued_date"] = "#search.issued_date#">
			<cfset row["renewed_date"] = "#search.renewed_date#">
			<cfset row["exp_date"] = "#search.exp_date#">
			<cfset row["issuedByAgent"] = "#search.issuedByAgent#">
			<cfset row["issuedToAgent"] = "#search.issuedToAgent#">
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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

<!------------------------------------------------------->
<cffunction name="getTrans_agent_role" access="remote">
	<!---  obtain the list of transaction agent roles, used to populate agent role picklist for new agent rows in edit transaction forms --->
	<!---  TODO: Add ability to restrict roles by transaction type --->
	<cfargument name="transaction_type" type="string" required="no">
	<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select trans_agent_role from cttrans_agent_role where trans_agent_role != 'entered by' order by trans_agent_role
	</cfquery>
	<cfreturn k>
</cffunction>


<!------------------------------------------------------->
<cffunction name="saveLoan" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="loan_number" type="string" required="yes">
	<cfargument name="loan_type" type="string" required="yes">
	<cfargument name="loan_status" type="string" required="yes">
	<cfargument name="collection_id" type="string" required="yes">
	<cfargument name="initiating_date" type="string" required="yes">
	<cfargument name="nature_of_material" type="string" required="yes">
	<!--- return_due_date is required, but not for exhibition subloans --->
	<cfargument name="return_due_date" type="string" required="no">
	<cfargument name="trans_remarks" type="string" required="no">
	<cfargument name="loan_description" type="string" required="no">
	<cfargument name="loan_instructions" type="string" required="no">
	<cfargument name="insurance_value" type="string" required="no">
	<cfargument name="insurance_maintained_by" type="string" required="no">
	<cfargument name="numagents" type="string" required="no">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="upTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE trans SET
					collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">,
					TRANS_DATE = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(initiating_date,"yyyy-mm-dd")#">,
					NATURE_OF_MATERIAL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NATURE_OF_MATERIAL#">,
					trans_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_remarks#">
				where
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif not isdefined("return_due_date") or len(return_due_date) eq 0 >
				<!--- If there is no value set for return_due_date, don't overwrite an existing value.  ---> 
				<!--- This prevents edits to exhibition-subloans from wiping out an existing date value --->
				<cfquery name="upLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE loan SET
						LOAN_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOAN_TYPE#">,
						LOAN_NUMBER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_number#">,
						loan_status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_status#">,
						loan_description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_description#">,
						LOAN_INSTRUCTIONS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOAN_INSTRUCTIONS#">,
						insurance_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#INSURANCE_VALUE#">,
						insurance_maintained_by = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#INSURANCE_MAINTAINED_BY#">
					where 
						transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				</cfquery>
			<cfelse>
				<cfquery name="upLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE loan SET
						return_due_date = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(return_due_date,"yyyy-mm-dd")#">,
						LOAN_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOAN_TYPE#">,
						LOAN_NUMBER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_number#">,
						loan_status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_status#">,
						loan_description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_description#">,
						LOAN_INSTRUCTIONS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOAN_INSTRUCTIONS#">,
						insurance_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#INSURANCE_VALUE#">,
						insurance_maintained_by = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#INSURANCE_MAINTAINED_BY#">
					where 
						transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				</cfquery>
			</cfif>
			<cfif isdefined("loan_type") and loan_type EQ 'exhibition-master' >
				<!--- Propagate due date to child exhibition-subloans --->
				<cfset formatted_due_date = dateformat(return_due_date,"yyyy-mm-dd")>
				<cfquery name="upChildLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE loan SET
						return_due_date = <cfqueryparam value = "#formatted_due_date#" CFSQLType="CF_SQL_TIMESTAMP">
					WHERE 
						loan_type = 'exhibition-subloan' AND
 						transaction_id in (select lr.related_transaction_id from loan_relations lr where
						lr.relation_type = 'Subloan' AND
						lr.transaction_id = <cfqueryparam value = "#TRANSACTION_ID#" CFSQLType="CF_SQL_DECIMAL">)
				</cfquery>
			</cfif>
			<cfloop from="1" to="#numAgents#" index="n">
				<cfif IsDefined("trans_agent_id_" & n) >
					<cfset trans_agent_id_ = evaluate("trans_agent_id_" & n)>
					<cfset agent_id_ = evaluate("agent_id_" & n)>
					<cfset trans_agent_role_ = evaluate("trans_agent_role_" & n)>
					<cftry>
						<cfset del_agnt_=evaluate("del_agnt_" & n)>
					<cfcatch>
						<cfset del_agnt_=0>
					</cfcatch>
					</cftry>
					<cfif del_agnt_ is "1" and isnumeric(trans_agent_id_) and trans_agent_id_ gt 0>
						<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							delete from trans_agent 
							where trans_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_id_#">
						</cfquery>
					<cfelse>
						<cfif len(agent_id_) GT 0>
							<!--- don't try to add/update a blank row --->
							<cfif trans_agent_id_ is "new" and del_agnt_ is 0>
								<cfquery name="newTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									insert into trans_agent (
										transaction_id,
										agent_id,
										trans_agent_role
									) values (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_#">
									)
								</cfquery>
							<cfelseif del_agnt_ is 0>
								<cfquery name="upTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									update trans_agent set
										agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
										trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_#">
									where
										trans_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_id_#">
								</cfquery>
							</cfif>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#transaction_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<cffunction name="okToPrintLoan" returntype="any" access="remote" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="transAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select agent_id, trans_agent_role
			from trans_agent
			where
				trans_agent.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfquery name="inhouse" dbtype="query">
			select count(distinct(agent_id)) c from transAgents where trans_agent_role='in-house contact'
		</cfquery>
		<cfquery name="outside" dbtype="query">
			select count(distinct(agent_id)) c from transAgents where trans_agent_role='received by'
		</cfquery>
		<cfquery name="authorized" dbtype="query">
			select count(distinct(agent_id)) c from transAgents where trans_agent_role='authorized by'
		</cfquery>
		<cfquery name="recipientinstitution" dbtype="query">
			select count(distinct(agent_id)) c from transAgents where trans_agent_role='recipient institution'
		</cfquery>
		<cfif inhouse.c is 1 and outside.c is 1 and authorized.c GT 0 and recipientinstitution.c GT 0 >
			<cfset okToPrint = true>
			<cfset okToPrintMessage = "">
		<cfelse>
			<cfset okToPrint = false>
			<cfset okToPrintMessage = 'One "authorized by", one "in-house contact", one "received by", and one "recipient institution" are required to print loan forms. '>
		</cfif>
		<cfset row = StructNew()>
		<cfset row["okToPrint"] = "#okToPrint#">
		<cfset row["message"] = "#okToPrintMessage#">
		<cfset row["id"] = "#transaction_id#">
		<cfset data[1] = row>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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

<!--- obtain an html block to populate a print list dialog for a loan --->
<cffunction name="getLoanPrintListDialogContent" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getLoanPrintHtmlThread">
		<cftry>
			<cfquery name="loanDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select loan_type 
				from loan
				where
					loan.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfquery name="transAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select agent_id, trans_agent_role
				from trans_agent
				where
					trans_agent.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfquery name="inhouse" dbtype="query">
				select count(distinct(agent_id)) c from transAgents where trans_agent_role='in-house contact'
			</cfquery>
			<cfquery name="outside" dbtype="query">
				select count(distinct(agent_id)) c from transAgents where trans_agent_role='received by'
			</cfquery>
			<cfquery name="authorized" dbtype="query">
				select count(distinct(agent_id)) c from transAgents where trans_agent_role='authorized by'
			</cfquery>
			<cfquery name="recipientinstitution" dbtype="query">
				select count(distinct(agent_id)) c from transAgents where trans_agent_role='recipient institution'
			</cfquery>
			<cfif inhouse.c is 1 and outside.c is 1 and authorized.c GT 0 and recipientinstitution.c GT 0 >
				<cfset okToprint = true>
			<cfelse>
				<cfset okToprint = false>
			</cfif>
	
			<cfoutput>
				<h2 class="h2">Print Loan Paperwork</h2> 
				<ul>
					<!--- report_printer.cfm takes parameters transaction_id, report, and sort, where
					sort={a field name that is in the select portion of the query specified in the custom tag}, or
					sort={cat_num_pre_int}, which is interpreted as order by cat_num_prefix, cat_num_integer.
					--->
					<cfif okToPrint  >
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_header" target="_blank">MCZ Invoice Header</a></li>
					</cfif>
					<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_files_loan_header" target="_blank">Header Copy for MCZ Files</a></li>
					<cfif inhouse.c is 1 and outside.c is 1 and loanDetails.loan_type eq 'exhibition-master' and recipientinstitution.c GT 0 >
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_exhibition_loan_header" target="_blank">MCZ Exhibition Loan Header</a></li>
					</cfif>
					<cfif inhouse.c is 1 and outside.c is 1 and loanDetails.loan_type eq 'exhibition-master' and recipientinstitution.c GT 0 >
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_exhib_loan_header_five_plus" target="_blank">MCZ Exhibition Loan Header Long</a></li>
					</cfif>
					<cfif inhouse.c is 1 and outside.c is 1 >
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_legacy" target="_blank">MCZ Legacy Invoice Header</a></li>
					</cfif>
					<cfif okToPrint >
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items&sort=cat_num" target="_blank">MCZ Item Invoice</a></li>
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items&sort=cat_num_pre_int" target="_blank">MCZ Item Invoice (cat num sort)</a></li>
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items&sort=scientific_name" target="_blank">MCZ Item Invoice (taxon sort)</a></li>
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items_parts&sort=cat_num" target="_blank">MCZ Item Parts Grouped Invoice</a></li>
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items_parts&sort=cat_num_pre_int" target="_blank">MCZ Item Parts Grouped Invoice (cat num sort)</a></li>
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items_parts&sort=scientific_name" target="_blank">MCZ Item Parts Grouped Invoice (taxon sort)</a></li>
					</cfif>
					<cfif inhouse.c is 1 and outside.c is 1 >
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_summary" target="_blank">MCZ Loan Summary Report</a></li>
					</cfif>
					<li><a href="/Reports/MVZLoanInvoice.cfm?transaction_id=#transaction_id#&Action=itemLabels&format=Malacology" target="_blank">MCZ Drawer Tags</a></li>
					<li><a href="/edecView.cfm?transaction_id=#transaction_id#" target="_blank">USFWS eDec</a></li>
				</ul>
			</cfoutput>
		<cfcatch>
			<cfoutput>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getLoanPrintHtmlThread" />
	<cfreturn getLoanPrintHtmlThread.output>
</cffunction>

<!--- obtain an html block for agents for a transaction  --->
<cffunction name="agentTableHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getAgentHtmlThread">
		<cftry>
			<cfquery name="transType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select transaction_type
				from trans
				where
					transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfset transaction = transType.transaction_type>
			<cfquery name="transAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					trans_agent_id,
					trans_agent.agent_id,
					agent_name,
					trans_agent_role,
					MCZBASE.get_worstagentrank(trans_agent.agent_id) worstagentrank
				from
					trans_agent,
					preferred_agent_name
				where
					trans_agent.agent_id = preferred_agent_name.agent_id and
					trans_agent_role != 'entered by' and
					trans_agent.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				order by
					trans_agent_role,
					agent_name
			</cfquery>
			<cfswitch expression="#transaction#">
				<cfcase value="loan">
					<!--- Obtain list of transaction agent roles, excluding those not relevant to loan editing --->
					<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct(trans_agent_role) from cttrans_agent_role  where trans_agent_role != 'entered by' and trans_agent_role != 'stewarship from agency' and trans_agent_role != 'received from' and trans_agent_role != 'borrow overseen by' order by trans_agent_role
					</cfquery>
					<!--- Obtain picklist values for loan agents controls.  --->
					<cfquery name="inhouse" dbtype="query">
						select count(distinct(agent_id)) c from transAgents where trans_agent_role='in-house contact'
					</cfquery>
					<cfquery name="outside" dbtype="query">
						select count(distinct(agent_id)) c from transAgents where trans_agent_role='received by'
					</cfquery>
					<cfquery name="authorized" dbtype="query">
						select count(distinct(agent_id)) c from transAgents where trans_agent_role='authorized by'
					</cfquery>
					<cfquery name="recipientinstitution" dbtype="query">
						select count(distinct(agent_id)) c from transAgents where trans_agent_role='recipient institution'
					</cfquery>
					<cfif inhouse.c is 1 and outside.c is 1 and authorized.c GT 0 and recipientinstitution.c GT 0 >
						<cfset okToPrint = true>
						<cfset okToPrintMessage = "">
					<cfelse>
						<cfset okToPrint = false>
						<cfset okToPrintMessage = 'One "authorized by", one "in-house contact", one "received by", and one "recipient institution" are required to print loan forms. '>
					</cfif>
				</cfcase>
				<cfdefaultcase>
					<!--- Obtain list of transaction agent roles --->
					<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct(trans_agent_role) from cttrans_agent_role  where trans_agent_role != 'entered by'
					</cfquery>
					<cfset okToPrint = false>
					<cfset okToPrintMessage = 'Print Check Not yet Implemented for #transaction#'>
				</cfdefaultcase>
			</cfswitch>
			<!--- TODO: Implement ok to print checks for other transaction types --->
			<cfoutput>
				<div class="form-row my-1">
					<div class="col-12 table-responsive mt-1">
						<table id="transactionAgentsTable" class="table table-sm mb-0">
							<thead class="thead-light">
								<tr>
									<th colspan="2"> 
										<span>
											Agent&nbsp;Name&nbsp;
											<button type="button" class="ui-button btn-primary btn-xs ui-widget ui-corner-all" id="button_add_trans_agent" onclick=" addTransAgentToForm('','','','editLoanForm'); handleChange();"> Add Row </button>
										</span>
									</th>
									<th>Role</th>
									<th>Delete?</th>
									<th>Clone As</th>
								</tr>
							</thead>
							<tbody>
								<tr>
									<td colspan="5">
										<cfif okToPrint >
											<span id="printStatus" class="text-success small px-1">OK to print</span>
										<cfelse>
											<span class="text-danger small px-1">#okToPrintMessage#</span>
										</cfif>
									</td>
								</tr>
								<cfset i=1>
								<cfloop query="transAgents">
									<tr>
										<td>
											<!--- trans_agent_id_{i} identifies the row in trans_agent table holding this agent for this transaction in this role --->
											<!--- trans_agent_id_{i} is not touched by makeRichTransAgentPicker or selection of an agent. --->
											<input type="hidden" name="trans_agent_id_#i#" id="trans_agent_id_#i#" value="#trans_agent_id#">
											<div class="input-group">
												<div class="input-group-prepend">
													<span class="input-group-text" id="agent_icon_#i#"><i class="fa fa-user" aria-hidden="true"></i></span> 
												</div>
												<!--- trans_agent_{i} is the human readable agent --->
												<input type="text" name="trans_agent_#i#" id="trans_agent_#i#" required class="goodPick form-control form-control-sm data-entry-input" value="#agent_name#">
											</div>
											<!--- agent_id_{i} is the link to the agent record, the agent to save in this role for this transaction, and the agent to link out to --->
											<input type="hidden" name="agent_id_#i#" id="agent_id_#i#" value="#agent_id#"
												onchange=" updateAgentLink($('##agent_id_#i#').val(),'agentViewLink_#i#'); ">
											<script>
												$(document).ready(function() {
													$(makeRichTransAgentPicker('trans_agent_#i#','agent_id_#i#','agent_icon_#i#','agentViewLink_#i#',#agent_id#)); 
												});
											</script>
										</td>
										<td style=" min-width: 3.5em; ">
											<span id="agentViewLink_#i#" class="px-2"><a href="/agents.cfm?agent_id=#agent_id#" target="_blank">View</a>
												<cfif transAgents.worstagentrank EQ 'A'>
													&nbsp;
												<cfelseif transAgents.worstagentrank EQ 'F'>
													<img src='/shared/images/flag-red.svg.png' width='16' alt="flag-red">
												<cfelse>
													<img src='/shared/images/flag-yellow.svg.png' width='16' alt="flag-yellow">
												</cfif>
											</span>
										</td>
										<td>
											<select name="trans_agent_role_#i#" id="trans_agent_role_#i#" class="data-entry-select">
												<cfloop query="cttrans_agent_role">
													<cfif cttrans_agent_role.trans_agent_role is transAgents.trans_agent_role>
														<cfset sel = 'selected="selected"'>
													<cfelse>
														<cfset sel = ''>
													</cfif>
													<option #sel# value="#trans_agent_role#">#trans_agent_role#</option>
												</cfloop>
											</select>
										</td>
										<td class="text-center">
											<input type="checkbox" name="del_agnt_#i#" id="del_agnt_#i#" value="1" class="checkbox-inline">
											<!--- uses i and the trans_agent_id to delete a row from trans_agent --->
										</td>
										<td>
											<select id="cloneTransAgent_#i#" onchange="cloneTransAgent(#i#);" class="data-entry-select">
												<option value=""></option>
												<cfloop query="cttrans_agent_role">
													<option value="#trans_agent_role#">#trans_agent_role#</option>
												</cfloop>
											</select>
										</td>
									</tr>
									<cfset i=i+1>
								</cfloop>
								<cfset na=i-1>
								<input type="hidden" id="numAgents" name="numAgents" value="#na#">
							</tbody>
						</table>
						<!-- end agents table ---> 
					</div>
				</div>
			</cfoutput>
		<cfcatch>
			<cfoutput>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAgentHtmlThread" />
	<cfreturn getAgentHtmlThread.output>
</cffunction>

<!------------------------------------->
<!--- 
  * method addSubLoanToLoan given two transaction ids add one transaction as the subloan of another. 
  * @param transaction_id the parent transaction
  * @param subloan_transaction_id the child transaction
--->
<cffunction name="addSubLoanToLoan" access="remote">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="subloan_transaction_id" type="string" required="yes">

	<cftry>
		<cfquery name="addChildLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into loan_relations 
				(transaction_id, related_transaction_id, relation_type)
			values (
				<cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL">,
				<cfqueryparam value = "#subloan_transaction_id#" CFSQLType="CF_SQL_DECIMAL">,
				'Subloan'
			)
		</cfquery>
		<cfquery name="childLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select l.loan_number, l.transaction_id 
			from loan_relations lr left join loan l on lr.related_transaction_id = l.transaction_id
			where lr.transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
			order by l.loan_number
		</cfquery>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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
	<cfreturn childLoans>
</cffunction>
<!------------------------------------->

<!--- 
  * method removeSubLoan given two transaction ids remove one as the child of the other
  * @param transaction_id the parent transaction
  * @param subloan_transaction_id the child transaction to unlink from the parent
--->
<cffunction name="removeSubLoan" access="remote">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="subloan_transaction_id" type="string" required="yes">

	<cfquery name="removeChildLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		delete from loan_relations
		where transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL"> and
		related_transaction_id = <cfqueryparam value = "#subloan_transaction_id#" CFSQLType="CF_SQL_DECIMAL"> and
		relation_type = 'Subloan'
	</cfquery>
	<cfquery name="childLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select l.loan_number, l.transaction_id from loan_relations lr left join loan l on lr.related_transaction_id = l.transaction_id
		where lr.transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
		order by l.loan_number
	</cfquery>
	<cfreturn childLoans>
</cffunction>

<!--- 
 ** method getProjectListHtml obtains an html block listing the projects related to a transaction 
 * 
 * @param transaction_id the id of the transaction for which to look up projects.
 * @return html to replace the html content of a div.
--->
<cffunction name="getProjectListHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getProjectListThread">
		<cftry>
			<cfquery name="projs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select project_name, project.project_id, 
					project_trans_remarks,
					to_char(start_date,'YYYY-MM-DD') as start_date,
					to_char(end_date,'YYYY-MM-DD') as end_date
				from project_trans left join project on project_trans.project_id =  project.project_id
				where
					transaction_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfoutput>
				<ul class="list-group">
					<cfif projs.recordcount gt 0>
						<cfloop query="projs">
							<li class="list-group-item">
								<a href="/Project.cfm?Action=editProject&project_id=#project_id#" target="_blank"><strong>#project_name#</strong></a> 
								(#start_date#/#end_date#) #project_trans_remarks#
								<a class='btn btn-xs btn-warning' onClick='  confirmDialog("Remove this project from this transaction?", "Confirm Unlink Project", function() { removeProjectFromTrans(#project_id#,#transaction_id#); } ); '>Remove</a>
							</li>
						</cfloop>
					<cfelse>
						<li class="list-group-item">None</li>
					</cfif>
				</ul>
			</cfoutput>
		<cfcatch>
			<cfoutput>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getProjectListThread" />
	<cfreturn getProjectListThread.output>
</cffunction>

<!--- 
 ** method getlinkProjectDialogHtml obtains the html content for a dialog to pick a project to add to a transaction.
 * 
 * @param transaction_id the id of the transaction to which to add selected projects
 * @return html to populate a dialog
--->
<cffunction name="getLinkProjectDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="linkProjectDialogThread">
		<cftry>
			<cfquery name="lookupTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select transaction_type, specific_number
				from transaction_view
				where
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfoutput>
				<form id="project_picker_form">
					<label for="pick_project_name">Pick a Project to associate with #lookupTrans.transaction_type# #lookupTrans.specific_number# (%% lists all projects)</label>
					<input type="hidden" name="pick_project_id" id="pick_project_id" value="">
					<input type="text" name="pick_project_name" id="pick_project_name" class="form-control-sm reqdClr" >
					<label for="project_trans_remarks">Project-Transaction Remarks</label>
					<input type="text" name="project_trans_remarks" id="project_trans_remarks" class="form-control-sm" >
					<script>
						$(document).ready( makeProjectPicker('pick_project_name','pick_project_id') );
						function saveProjectLink() {
							var id = $('##pick_project_id').val();
							var remarks = $('##project_trans_remarks').val();
							if (id) { 
								jQuery.getJSON("/transactions/component/functions.cfc",
									{
										method : "linkProjectToTransaction",
										project_id : id,
										transaction_id : #transaction_id#,
										project_trans_remarks: remarks,
										returnformat : "json",
										queryformat : 'column'
									},
									function (result) {
										if (result.DATA.STATUS[0]=='1') { 
											$('##project_picker_form').html('Relationship to project saved.');
										} else {
											messageDialog('Error linking project to transaction record: '+result.DATA.MESSAGE[0], 'Error saving project-transaction relation.');
										}
									}
								).fail(function(jqXHR,textStatus,error){
									var message = "";
									if (error == 'timeout') {
										message = ' Server took too long to respond.';
									} else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
										message = ' Backing method did not return JSON.';
									} else {
										message = jqXHR.responseText;
									}
									if (!error) { error = ""; } 
									messageDialog('Error linking project to transaction record: '+message, 'Error: '+error.substring(0,50));
								});
							} else { 
								messageDialog('You must pick a project from the picklist)','Error: No project picked to link');
							}
						};
					</script>
					<button type="button" class="btn btn-primary" onClick="saveProjectLink();">Save</button>
				</form>
			</cfoutput>
		<cfcatch>
			<cfoutput>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="linkProjectDialogThread" />
	<cfreturn linkProjectDialogThread.output>
</cffunction>


<!--- 
 ** method getlinkProjectDialogHtml obtains the html content for a dialog to create a project to add to a transaction.
 * 
 * @param transaction_id the id of the transaction to which to add the new project
 * @return html to populate a dialog 
--->
<cffunction name="getAddProjectDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getProjectDialogThread">
		<cftry>
			<cfquery name="lookupTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select transaction_type, specific_number, trans_date, trans_remarks
				from transaction_view
				where
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfoutput>
				<label for="create_project">Create a New Project linked to #lookupTrans.transaction_type# #lookupTrans.specific_number#</label>
				<form id="create_project" class="row col-12" >
					<input type="hidden" name="transaction_id" value="#transaction_id#">
					<input type="hidden" name="method" value="createProjectLinkToTrans">
					<input type="hidden" name="returnformat" value="json">
					<input type="hidden" name="queryformat" value="column">
					<div class="row col-12">
						<div class="col-12 col-md-6">
							<span class="my-1 data-entry-label">
								<label for="newAgent_name">Project Agent Name</label>
								<span id="newAgentViewLink" class="px-2">&nbsp;</span>
							</span>
							<div class="input-group">
								<div class="input-group-prepend">
									<span class="input-group-text" id="project_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
								</div>
								<input type="text" name="newAgent_name" id="newAgent_name" required class="form-control form-control-sm data-entry-input reqdClr" value="">
							</div>
							<input type="hidden" name="newAgent_name_id" id="newAgent_name_id" value=""
								onchange=" updateAgentLink($('##newAgent_name_id').val(),'newAgentViewLink'); ">
							<script>
								$(document).ready(function() {
									$(makeRichTransAgentPicker('newAgent_name','newAgent_name_id','project_agent_icon','newAgentViewLink',null)); 
								});
							</script>
						</div>
						<div class="col-12 col-md-6">
							<cfquery name="ctProjAgRole" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select project_agent_role from ctproject_agent_role order by project_agent_role
							</cfquery>
							<label for="project_agent_role" class="data-entry-label">Project Agent Role</label>
							<select name="project_agent_role" id="project_agent_role" size="1" class="reqdClr form-control-sm" required>
								<option value=""></option>
								<cfloop query="ctProjAgRole">
								<option value="#ctProjAgRole.project_agent_role#">#ctProjAgRole.project_agent_role#</option>
								</cfloop>
							</select>
						</div>
					</div>
					<div class="row col-12">
						<div class="col-12 col-md-6">
							<label for="start_date" class="data-entry-label">Project Start Date</label>
							<input type="text" name="start_date" id="start_date" value="#dateformat(lookupTrans.trans_date,"yyyy-mm-dd")#" class="form-control-sm">
						</div>
						<div class="col-12 col-md-6">
							<label for="end_date" class="data-entry-label">Project End Date</label>
							<input type="text" name="end_date" id="end_date" class="form-control-sm">
						</div>
					</div>
					<div class="row col-12">
						<div class="col-12">
							<label for="project_name" class="data-entry-label">Project Title</label>
							<textarea name="project_name" id="project_name" cols="50" rows="2" class="reqdClr form-control autogrow" required></textarea>
						</div>
					</div>
					<div class="row col-12">
						<div class="col-12">
							<label for="project_description" class="data-entry-label">Project Description</label>
							<textarea name="project_description" id="project_description" class="form-control autogrow"
								id="project_description" cols="50" rows="2"></textarea>
						</div>
					</div>
					<div class="row col-12">
						<div class="col-12">
							<label for="project_remarks" class="data-entry-label">Project Remarks</label>
							<textarea name="project_remarks" id="project_remarks" cols="50" rows="2" class="form-control autogrow">#lookupTrans.trans_remarks#</textarea>
						</div>
					</div>
					<div class="row col-12">
						<div class="col-12">
							<label for="project_trans_remarks" class="data-entry-label">Project-Transaction Remarks</label>
							<textarea name="project_trans_remarks" id="project_trans_remarks" cols="50" rows="2" class="form-control autogrow"></textarea>
						</div>
					</div>
					<div class="row col-12">
						<div class="form-group col-12">
							<input type="button" value="Create Project" aria-label="Create Project" class="btn btn-sm btn-primary"
								onClick="if (checkFormValidity($('##create_project')[0])) { createProject();  } ">
						</div>
					</div>
					<script>
						$(document).ready(function() { 
							$("textarea.autogrow").keyup(autogrow);  
							$('textarea.autogrow').keyup();
						});
						function createProject(){
							$.ajax({
								url : "/transactions/component/functions.cfc",
								type : "post",
								dataType : "json",
								data: $("##create_project").serialize(),
								success: function (result) {
									if (result.DATA.STATUS[0]=='1') { 
										$('##create_project').html('New project saved. ['+result.DATA.ID[0]+']');
									} else {
										messageDialog('Error creating project to link to transaction record: '+result.DATA.MESSAGE[0], 'Error saving project-transaction relation.');
									}
								},
								error: function(jqXHR,textStatus,error){
									handleFail(jqXHR,textStatus,error,"creating project to link to transaction record");
								}
							});
						};
					</script>
				</form>
			</cfoutput>
		<cfcatch>
			<cfoutput>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getProjectDialogThread" />
	<cfreturn getProjectDialogThread.output>
</cffunction>

<!--- 
 ** method removeMediaFromTransaction unlink a media record from a transaction.
 *
 * @param transaction_id the transaction id that is the related_primary_key of the media_relations record to delate.
 * @parem media_id the media id of the media_relations record to delete
 * @param media_relationship the media relationship of the media_relations record to delete.
--->
<cffunction name="removeMediaFromTransaction" returntype="any" access="remote" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="media_relationship" type="string" required="yes">
	<cfset r=1>
	<cftry>
		<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResult">
			delete from media_relations
			where related_primary_key =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				and media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				and media_relationship=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_relationship#">
		</cfquery>
		<cfif deleteResult.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No records deleted. #media_id# #media_relationship# #transaction_id# #deleteResult.sql#", 1)>
		</cfif>
		<cfif deleteResult.recordcount eq 1>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
		</cfif>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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
	<cfif isDefined("asTable") AND asTable eq "true">
		<cfreturn resulthtml>
	<cfelse>
		<cfreturn theResult>
	</cfif>
</cffunction>

<!--- 
 ** method linkProjectToTransaction unlink a media record from a transaction.
 *
 * @param transaction_id the transaction id that is the related_primary_key of the media_relations record to delate.
 * @parem media_id the media id of the media_relations record to delete
 * @param media_relationship the media relationship of the media_relations record to delete.
--->
<cffunction name="linkProjectToTransaction" returntype="any" access="remote" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="project_id" type="string" required="yes">
	<cfargument name="project_trans_remarks" type="string" required="no">
	<cfset r=1>
	<cftry>
		<cfquery name="add" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="add_result">
			insert into project_trans (
				transaction_id
				,project_id
				<cfif isDefined("project_trans_remarks") AND len(project_trans_remarks) GT 0>
					,project_trans_remarks
				</cfif>
			) values (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			 	,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
				<cfif isDefined("project_trans_remarks") AND len(project_trans_remarks) GT 0>
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#project_trans_remarks#">
				</cfif>
			)
		</cfquery>
		<cfif add_result.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No record added. #transaction_id# #project_id# #add.sql#", 1)>
		</cfif>
		<cfif add_result.recordcount eq 1>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record Added.", 1)>
		</cfif>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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
	<cfreturn theResult>
</cffunction>


<cffunction name="createProjectLinkToTrans" returntype="any" access="remote" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="project_name" type="string" required="yes">
	<cfargument name="start_date" type="string" required="no">
	<cfargument name="end_date" type="string" required="no">
	<cfargument name="project_description" type="string" required="no">
	<cfargument name="project_remarks" type="string" required="no">
	<cfargument name="newAgent_name_id" type="string" required="yes">
	<cfargument name="project_agent_role" type="string" required="yes">
	<cfargument name="project_trans_remarks" type="string" required="no">
	<cfset r=1>
	<cftransaction>
		<cftry>
			<cfquery name="newProjSeq" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_project_id.nextval as id from dual
			</cfquery>
			<cfset project_id_new = newProjSeq.id>
			<cfquery name="newProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO project (
					PROJECT_ID
					,PROJECT_NAME
					<cfif len(#START_DATE#) gt 0>
						,START_DATE
					</cfif>
					<cfif len(#END_DATE#) gt 0>
						,END_DATE
					</cfif>
					<cfif len(#PROJECT_DESCRIPTION#) gt 0>
						,PROJECT_DESCRIPTION
					</cfif>
					<cfif len(#PROJECT_REMARKS#) gt 0>
						,PROJECT_REMARKS
					</cfif>
				)
				VALUES 
				(
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id_new#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PROJECT_NAME#">
					<cfif len(#START_DATE#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(START_DATE,"yyyy-mm-dd")#">
					</cfif>
					<cfif len(#END_DATE#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(END_DATE,"yyyy-mm-dd")#">
					</cfif>
					<cfif len(#PROJECT_DESCRIPTION#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PROJECT_DESCRIPTION#">
					</cfif>
					<cfif len(#PROJECT_REMARKS#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PROJECT_REMARKS#">
					</cfif>
				)
			</cfquery>
			<cfquery name="newProjAgnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO project_agent (
					PROJECT_ID,
					AGENT_NAME_ID,
					PROJECT_AGENT_ROLE,
					AGENT_POSITION )
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id_new#">
					,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newAgent_name_id#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#project_agent_role#">
					,1 )
			</cfquery>
			<cfquery name="newTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO project_trans (
					project_id
					, transaction_id
					<cfif isDefined("project_trans_remarks") AND len(project_trans_remarks) GT 0>
						,project_trans_remarks
					</cfif>
				) 
				values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id_new#">
					,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
					<cfif isDefined("project_trans_remarks") AND len(project_trans_remarks) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#project_trans_remarks#">
					</cfif>
				)
			</cfquery>
			<cfset data=queryNew("status, message, id")>
			<cfset t = queryaddrow(data,1)>
			<cfset t = QuerySetCell(data, "status", "1", 1)>
			<cfset t = QuerySetCell(data, "message", "Record Added.", 1)>
			<cfset t = QuerySetCell(data, "id", "#project_id_new#", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cftry>
				<cfif isDefined("cfcatch.TagContext") ><cfset line="Line: #cfcatch.TagContext[1].line#"><cfelse><cfset line = ''></cfif>
			<cfcatch>
				<cfset line = ''>
			</cfcatch>
			</cftry>
			<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & line & " " & queryError) >
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
	</cftransaction>
	<cfreturn #data#>
</cffunction>

<!--- 
 ** method removeProjectFromTransaction unlink a project record from a transaction (weak entity, 
 *  primary key comprised of foreign keys transaction_id and project_id.
 *
 * @param transaction_id the transaction id of the project_trans record to delate.
 * @parem project_id the project id of the project_trans record to delete
--->
<cffunction name="removeProjectFromTransaction" returntype="any" access="remote" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="project_id" type="string" required="yes">
	<cfset r=1>
	<cftry>
		<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResult">
			delete from project_trans
			where transaction_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				and project_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
		</cfquery>
		<cfif deleteResult.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No records deleted. #project_id# #transaction_id# #deleteResult.sql#", 1)>
		</cfif>
		<cfif deleteResult.recordcount eq 1>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
		</cfif>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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
	<cfif isDefined("asTable") AND asTable eq "true">
		<cfreturn resulthtml>
	<cfelse>
		<cfreturn theResult>
	</cfif>
</cffunction>



<!--- 
  ** obtain an html block for picking addresses for a shipment using an address text control and address_id control 
  *  with a specified dialog.
  *
 --->
<cffunction name="getAddressPickerHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="valuecontrol" type="string" required="yes">
	<cfargument name="idcontrol" type="string" required="yes">
	<cfargument name="dialog" type="string" required="yes">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getAddressPickerThread">

	<cftry>
		<cfquery name="lookupTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select transaction_type, specific_number, trans_date, trans_remarks
			from transaction_view
			where
				transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfif lookupTrans.transaction_type EQ "accn"> 
			<!--- Temporary addresses for agents can be created for accessions, where an agent working at the MCZ is shipping from a temporary address on an expedition --->
			<cfset includeTemporary = "true">
		<cfelse>
			<cfset includeTemporary = "">
		</cfif>
		<cfoutput>
			<h3>Search for Addresses.</h3>
   		<form id="findAddressSearchForm" name="findAddress">
				<input type="hidden" name="method" value="getAddressesJSON" class="keeponclear">
				<input type="hidden" name="include_temporary" value="#includeTemporary#" class="keeponclear">

				<cfif includeTemporary EQ "true">
					<h2>TODO: Implement temporary address creation.</h2>
				</cfif>

				<div class="row col-12">
					<div class="col-12 col-md-6">
						<span class="my-1 data-entry-label">
							<label for="shipment_agent_name">Agent Name</label>
							<span id="shipment_agent_view_link" class="px-2">&nbsp;</span>
						</span>
						<div class="input-group">
							<div class="input-group-prepend">
								<span class="input-group-text" id="shipment_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
							</div>
							<input type="text" name="shipment_agent_name" id="shipment_agent_name" class="form-control form-control-sm data-entry-input" value="">
						</div>
						<input type="hidden" name="shipment_agent_id" id="shipment_agent_id" value=""
							onchange=" updateAgentLink($('##shipment_agent_id').val(),'shipment_agent_view_link'); ">
						<script>
							$(document).ready(function() {
								$(makeRichTransAgentPicker('shipment_agent_name','shipment_agent_id','shipment_agent_icon','shipment_agent_view_link',null)); 
							});
						</script>
					</div>
					<div class="col-12 col-md-6">
						<label for="start_date" class="data-entry-label">Address</label>
						<input type="text" name="formatted_address" id="formatted_address" value="" class="form-control-sm">
					</div>
				</div>
				<div class="row col-12">
					<div class="col-12">
						<button class="btn-xs btn-primary px-3" id="searchButton"
							type="submit" aria-label="Search for addresses">Search<span class="fa fa-search pl-1"></span></button>
					</div>
				</div>
			</form>

			<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
				<h4>Results: </h4>
				<span class="d-block px-3 p-2" id="addressPickResultCount"></span> <span id="addressPickResultLink" class="d-block p-2"></span>
			</div>
			<div class="row mt-0">
				<div id="addressPickSearchText"></div>
				<div id="addressPickResultsGrid" class="jqxGrid"></div>
				<div id="enableselection"></div>
			</div>
			<script>
				$("##findAddressSearchForm").bind("submit", function(evt){
					evt.preventDefault();
					$("##addressPickResultsGrid").replaceWith('<div id="addressPickResultsGrid" class="jqxGrid"></div>');
					$("##addressPickResultCount").html("");
					$("##addressPickResultLink").html("");
					$("##addressPickSearchText").jqxGrid("showloadelement");

					var addressSearch = {
						datatype: "json",
						datafields: [
							{ name: "addr_id", type: "string" },
							{ name: "agent_name", type: "string" },
							{ name: "agent_id", type: "string" },
							{ name: "formatted_addr", type: "string" },
							{ name: "valid_addr_fg", type: "string" },
							{ name: "addr_type", type: "string" }
						],
						root: "addressRecord",
						id: "address_id",
						url: "/transactions/component/functions.cfc?" + $("##findAddressSearchForm").serialize()
					};

					var dataAdapter = new $.jqx.dataAdapter(addressSearch);

					// TODO: Implement agentcellrenderer, bind to agent id to create view link for agent

					var linkcellrenderer = function (index, datafield, value, defaultvalue, column, rowdata) { 
						var pvalue = rowdata.formatted_addr;
						var result = "<button class=\"btn btn-primary\" onclick=\" $('###idcontrol#').val( '" + value + "'); $('###valuecontrol#').val('" + pvalue + "'); $('###dialog#').dialog('close'); \">Select</button>";
						return result;
					};

					$("##addressPickResultsGrid").jqxGrid({
						width: "100%",
						autoheight: "true",
						source: dataAdapter,
						filterable: true,
						sortable: true,
						pageable: true,
						editable: false,
						pagesize: "50",
						pagesizeoptions: ["50","100"],
						showaggregates: false,
						columnsresize: true,
						autoshowfiltericon: true,
						autoshowcolumnsmenubutton: false,
						columnsreorder: true,
						groupable: false,
						selectionmode: "none",
						altrows: true,
						showtoolbar: false,
						columns: [
							{text: "Select", datafield: "addr_id", width: 100, hideable: false, hidden: false, cellsrenderer: linkcellrenderer }, 
							{text: "Agent", datafield: "agent_name", width: 150, hideable: true, hidden: false }, 
							{text: "agent_id", datafield: "agent_id", width: 50, hideable: true, hidden: true }, 
							{text: "Valid", datafield: "valid_addr_fg", width: 80, hideable: true, hidden: false },
							{text: "Type", datafield: "addr_type", width: 150, hideable: true, hidden: false },
							{text: "Address", datafield: "formatted_addr", hideable: true, hidden: false }
						]
					});
				});
			</script>
		</cfoutput>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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

	</cfthread>
	<cfthread action="join" name="getAddressPickerThread" />
	<cfreturn getAddressPickerThread.output>
</cffunction>

<cffunction name="getAddressesJSON" access="remote" returntype="any" returnformat="json">
	<cfargument name="shipment_agent_id" type="string" required="no">
	<cfargument name="formatted_address" type="string" required="no">
	<cfargument name="include_temporary" type="string" required="no">
	<cfif isdefined("include_temporary") and #include_temporary# IS "true">
		<cfset showTemp = TRUE>
	<cfelse>
		<cfset showTemp = FALSE>
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT agent_name, preferred_agent_name.agent_id, formatted_addr, addr_id,VALID_ADDR_FG, addr_type
			FROM preferred_agent_name left join addr on preferred_agent_name.agent_id = addr.agent_id
			WHERE
				formatted_addr is not null
			<cfif showTemp EQ FALSE >
				AND addr_type <> 'temporary'
			</cfif >
			<cfif isdefined("shipment_agent_id") AND len(shipment_agent_id) gt 0>
				AND addr.agent_id = <cfqueryparam value="#shipment_agent_id#" cfsqltype="CF_SQL_DECIMAL">
			<cfelseif isdefined("formatted_address") AND len(formatted_address) gt 0>
				AND upper(formatted_addr) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(formatted_address)#%" >
			</cfif>
			ORDER BY valid_addr_fg desc, agent_name asc
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["agent_name"] = "#search.agent_name#">
			<cfset row["agent_id"] = "#search.agent_id#">
			<cfset row["formatted_addr"] = "#JSStringFormat(search.formatted_addr)#">
			<cfset row["addr_id"] = "#search.addr_id#">
			<cfset row["valid_addr_fg"] = "#search.valid_addr_fg#">
			<cfset row["addr_type"] = "#search.addr_type#">
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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

<!---
   Function to create or save a shipment from a ajax post
   @param shipment_id the shipment_id of the shipment to save, if null, then create a new shipment.
   @param transaction_id the transaction with which this shipment is associated.
   @return json query structure with STATUS = 0|1 and MESSAGE, status = 0 on a failure.
 --->
<cffunction name="saveShipment" returntype="query" access="remote">
   <cfargument name="shipment_id" required="no">
   <cfargument name="transaction_id" type="numeric" required="yes">
   <cfargument name="packed_by_agent_id" type="numeric" required="no">
   <cfargument name="shipped_carrier_method" type="string" required="no">
   <cfargument name="carriers_tracking_number" type="string" required="no">
   <cfargument name="shipped_date" type="string" required="no">
   <cfargument name="package_weight" type="string" required="no">
   <cfargument name="no_of_packages" type="string" required="no">
   <cfargument name="hazmat_fg" type="numeric" required="no">
   <cfargument name="insured_for_insured_value" type="string" required="no">
   <cfargument name="shipment_remarks" type="string" required="no">
   <cfargument name="contents" type="string" required="no">
   <cfargument name="foreign_shipment_fg" type="numeric" required="no">
   <cfargument name="shipped_to_addr_id" type="string" required="no">
   <cfargument name="shipped_from_addr_id" type="string" required="no">
   <cfset theResult=queryNew("status, message")>
   <cftry>
      <cfset debug = shipment_id >
      <!---  Try to obtain a numeric value for no_of_packages, if this fails, set no_of_packages to empty string to not include --->
      <cfset noofpackages = val(#no_of_packages#) >
      <cfif noofpackages EQ 0>
          <cfset no_of_packages = "">
      </cfif>
      <cfif NOT IsDefined("shipment_id") OR shipment_id EQ "">
         <!---  Determine how many shipments there are in this transaction, if none, set the print_flag on the new shipment --->
         <cfquery name="countShipments" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
             select count(*) ct from shipment
                where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
         </cfquery>
         <cfif countShipments.ct EQ 0>
             <cfset printFlag = 1>
         <cfelse>
             <cfset printFlag = 0>
         </cfif>
         <cfset debug = shipment_id & "Insert" >
         <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
             insert into shipment (
                transaction_id, packed_by_agent_id, shipped_carrier_method, carriers_tracking_number, shipped_date, package_weight,
                <cfif isdefined("no_of_packages") and len(#no_of_packages#) gt 0>
                  no_of_packages,
                </cfif>
                <cfif isdefined("insured_for_insured_value") and len(#insured_for_insured_value#) gt 0>
                  insured_for_insured_value,
                </cfif>
                hazmat_fg, shipment_remarks, contents, foreign_shipment_fg,
                shipped_to_addr_id, shipped_from_addr_id,
                print_flag
             )
             values (
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#packed_by_agent_id#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shipped_carrier_method#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#carriers_tracking_number#">,
                <cfqueryparam cfsqltype="CF_SQL_DATE" value="#shipped_date#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#package_weight#">,
                <cfif isdefined("no_of_packages") and len(#no_of_packages#) gt 0>
                   <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#noofpackages#">,
                </cfif>
                <cfif isdefined("insured_for_insured_value") and len(#insured_for_insured_value#) gt 0>
                   <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#insured_for_insured_value#" null="yes">,
                </cfif>
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#hazmat_fg#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shipment_remarks#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#contents#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#foreign_shipment_fg#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipped_to_addr_id#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipped_from_addr_id#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#printFlag#">
             )
         </cfquery>
      <cfelse>
         <cfset debug = shipment_id & "Update" >
         <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
             update shipment set
                packed_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#packed_by_agent_id#">,
                shipped_carrier_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shipped_carrier_method#">,
                carriers_tracking_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#carriers_tracking_number#">,
                shipped_date = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#shipped_date#">,
                package_weight = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#package_weight#">,
                <cfif isdefined("no_of_packages") and len(#no_of_packages#) gt 0>
                   no_of_packages = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#noofpackages#" >,
                <cfelse>
                   no_of_packages = <cfqueryparam cfsqltype="CF_SQL_NULL" null="yes" value="" >,
                </cfif>
                <cfif isdefined("insured_for_insured_value") and len(#insured_for_insured_value#) gt 0>
                   insured_for_insured_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#insured_for_insured_value#">,
                </cfif>
                hazmat_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#hazmat_fg#">,
                shipment_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shipment_remarks#">,
                contents = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#contents#">,
                foreign_shipment_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#foreign_shipment_fg#">,
                shipped_to_addr_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipped_to_addr_id#">,
                shipped_from_addr_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipped_from_addr_id#">
             where
                shipment_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#"> and
                transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
          </cfquery>
      </cfif>
      <cfset t = queryaddrow(theResult,1)>
      <cfset t = QuerySetCell(theResult, "status", "1", 1)>
      <cfset t = QuerySetCell(theResult, "message", "Saved.", 1)>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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
	<cfreturn theResult>
</cffunction>


</cfcomponent>
