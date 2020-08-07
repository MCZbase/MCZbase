<!---
specimens/component/functions.cfc

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
			media_relationship like '% #transaction_type#'
			and media_relations.related_primary_key = <cfqueryparam value="#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
	</cfquery>
	<cfif query.recordcount gt 0>
		<cfset result=result & "<ul>">
		<cfloop query="query">
			<cfset puri=getMediaPreview(preview_uri,media_type) >
			<cfset result = result & "<li><a href='#media_uri#' target='_blank' rel='noopener noreferrer'><img src='#puri#' height='15'></a> #mime_type# #media_type# #label_value# <a href='/media/#media_id#' target='_blank'>Media Details</a>  <a onClick='  confirmAction(""Remove this media from this transaction?"", ""Confirm Unlink Media"", function() { deleteMediaFromTrans(#media_id#,#transaction_id#,""#relWord# #transaction_type#""); } ); '>Remove</a> </li>" >
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
		<cfset resulthtml = "<div id='shipments'> ">

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
			<cfset resulthtml = resulthtml & "<script>function reloadShipments() { loadShipments(#transaction_id#); } </script>" >
			<cfset resulthtml = resulthtml & "<div class='shipment'>" >
				<cfset resulthtml = resulthtml & "<ul class='shipheaders'><li>Ship Date:</li><li>Method:</li><li>Packages:</li><li>Tracking Number:</li></ul>">
				<cfset resulthtml = resulthtml & " <ul class='shipdata'>" >
					 <cfset resulthtml = resulthtml & "<li>#dateformat(shipped_date,'yyyy-mm-dd')#&nbsp;</li> " >
					 <cfset resulthtml = resulthtml & " <li>#shipped_carrier_method#&nbsp;</li> " >
					 <cfset resulthtml = resulthtml & " <li>#no_of_packages#&nbsp;</li> " >
					 <cfset resulthtml = resulthtml & " <li>#carriers_tracking_number#</li>">
				<cfset resulthtml = resulthtml & "</ul>">
				<cfset resulthtml = resulthtml & "<ul class='shipaddresseshead'><li>Shipped To:</li><li>Shipped From:</li></ul>">
				<cfset resulthtml = resulthtml & " <ul class='shipaddressesdata'>">
					 <cfset resulthtml = resulthtml & "<li>(#printedOnInvoice#) #tofaddr#</li> ">
					 <cfset resulthtml = resulthtml & " <li>#fromfaddr#</li>">
				<cfset resulthtml = resulthtml & "</ul>">
				<cfset resulthtml = resulthtml & "<div class='changeship'><div class='shipbuttons'><input type='button' value='Edit this Shipment' class='lnkBtn' onClick=""$('##dialog-shipment').dialog('open'); loadShipment(#shipment_id#,'shipmentForm');""></div><div class='shipbuttons' id='addPermit_#shipment_id#'><input type='button' value='Add Permit to this Shipment' class='lnkBtn' onClick="" openlinkpermitshipdialog('addPermitDlg_#shipment_id#','#shipment_id#','Shipment: #carriers_tracking_number#',reloadShipments); "" ></div><div id='addPermitDlg_#shipment_id#'></div></div> ">
				<cfset resulthtml = resulthtml & "<div class='shippermitstyle'><h4>Permits:</h4>">
					<cfset resulthtml = resulthtml & "<div class='permitship'><span id='permits_ship_#shipment_id#'>">
					<cfloop query="shippermit">
					<cfquery name="mediaQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				 select media.media_id, media_uri, preview_uri, media_type
					from media_relations left join media on media_relations.media_id = media.media_id
					where media_relations.media_relationship = 'shows permit'
					and media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#shippermit.permit_id#>
				</cfquery>
				<cfset mediaLink = "&##8855;">
				<cfloop query="mediaQuery">
					<cfset mediaLink = "<a href='#media_uri#' target='_blank' rel='noopener noreferrer' ><img src='#getMediaPreview(preview_uri,media_type)#' height='15'></a>" >
				</cfloop>
					<cfset resulthtml = resulthtml & "<ul class='permitshipul'><li><span>#mediaLink# #permit_type# #permit_Num#</span></li><li>Issued: #dateformat(issued_Date,'yyyy-mm-dd')#</li><li style='width:300px;'> #IssuedByAgent#</li></ul>">
					<cfset resulthtml = resulthtml & "<ul class='permitshipul2'>">
					<cfset resulthtml = resulthtml & "<li><input type='button' class='savBtn' style='padding:1px 6px;' onClick=' window.open(""Permit.cfm?Action=editPermit&permit_id=#permit_id#"")' target='_blank' value='Edit'></li> ">
					<cfset resulthtml = resulthtml & "<li><input type='button' class='delBtn' style='padding:1px 6px;' onClick='confirmAction(""Remove this permit from this shipment (#permit_type# #permit_Num#)?"", ""Confirm Remove Permit"", function() { deletePermitFromShipment(#theResult.shipment_id#,#permit_id#,#transaction_id#); } ); ' value='Remove Permit'></li>">
					<cfset resulthtml = resulthtml & "<li>">
					<cfset resulthtml = resulthtml & "<input type='button' onClick=' opendialog(""picks/PermitPick.cfm?Action=movePermit&permit_id=#permit_id#&transaction_id=#transaction_id#&current_shipment_id=#theResult.shipment_id#"",""##movePermitDlg_#theResult.shipment_id##permit_id#"",""Move Permit to another Shipment"");' class='lnkBtn' style='padding:1px 6px;' value='Move'>">
					<cfset resulthtml = resulthtml & "<span id='movePermitDlg_#theResult.shipment_id##permit_id#'></span></li>">
				</cfloop>
				<cfif shippermit.recordcount eq 0>
					<cfset resulthtml = resulthtml & "None">
				</cfif>
				<cfset resulthtml = resulthtml & "</span></div></div>"> <!--- span#permit_ships_, div.permitship div.shippermitsstyle --->
				<cfif shippermit.recordcount eq 0>
					 <cfset resulthtml = resulthtml & "<div class='deletestyle' id='removeShipment_#shipment_id#'><input type='button' value='Delete this Shipment' class='delBtn' onClick="" confirmAction('Delete this shipment (#theResult.shipped_carrier_method# #theResult.carriers_tracking_number#)?', 'Confirm Delete Shipment', function() { deleteShipment(#shipment_id#,#transaction_id#); }  ); "" ></div>">
				<cfelse>
					 <cfset resulthtml = resulthtml & "<div class='deletestyle'><input type='button' class='disBtn' value='Delete this Shipment'></div>">
				</cfif>
				<cfset resulthtml = resulthtml & "</div>" > <!--- shipment div --->
		</cfloop> <!--- theResult --->
		<cfset resulthtml = resulthtml & "</div>"><!--- shipments div --->
		<cfif theResult.recordcount eq 0>
			 <cfset resulthtml = resulthtml & "No shipments found for this transaction.">
		</cfif>
	<cfcatch>
		 <cfset resulthtml = resulthtml & "Error:" & "#cfcatch.type# #cfcatch.message# #cfcatch.detail#">
	</cfcatch>
	</cftry>
	<cfoutput>#resulthtml#</cfoutput>
	</cfthread>
	 <cfthread action="join" name="getSBTHtmlThread" />
	 <cfreturn getSBTHtmlThread.output>
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
		<cfloop query="mediaQuery">
			<cfset mediaLink = "<a href='#media_uri#'target='_blank' rel='noopener noreferrer'><img src='#getMediaPreview(preview_uri,media_type)#' height='15'></a>" >
		</cfloop>
		<cfset resulthtml = resulthtml & "<ul class='permitshipul'><li><span>#mediaLink# #permit_type# #permit_Num#</span></li><li>Issued: #dateformat(issued_Date,'yyyy-mm-dd')#</li><li style='width:300px;'>#IssuedByAgent#</li></ul>">


		<cfset resulthtml = resulthtml & "<ul class='permitshipul2'>">
		<cfset resulthtml = resulthtml & "<li><input type='button' class='savBtn' style='padding:1px 6px;' onClick=' window.open(""Permit.cfm?Action=editPermit&permit_id=#permit_id#"")' target='_blank' value='Edit'></li> ">
		<cfset resulthtml = resulthtml & "<li><input type='button' class='delBtn' style='padding:1px 6px;' onClick='confirmAction(""Remove this permit from this Transaction (#permit_type# #permit_Num#)?"", ""Confirm Remove Permit"", function() { deletePermitFromTransaction(#permit_id#,#transaction_id#); } ); ' value='Remove Permit'></li>">
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
		<cfset message = trim("Error processing getPermitAutocomplete: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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
			<cfset row["meta"] = "#search.loan_number# (#search.loan_status# #search.trans_date# #search.rec_agent#)" >
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
							<select name="permit_Type" id="permit_type" size="1" style="width: 15em;" class="data-entry-select">
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
							<select name="specific_type" size="1" style="width: 15em;" class="data-entry-select">
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
							<button type="submit" aria-label="Search for Permits" class="btn btn-primary">Search<span class="fa fa-search pl-1"></span></button>
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
		<cfset message = trim("Error processing queryPermitPickerHtml: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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
		<cfset message = trim("Error processing getPermitsJSON: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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
</cfcomponent>
