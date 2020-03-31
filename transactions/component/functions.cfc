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
			select distinct permit_num, permit_type, specific_type, permit_title, issued_date, permit.permit_id,
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
			<cfif len(search.issued_date) gt 0><cfset i_date= ", " || search.issued_date><cfelse><cfset i_date=""></cfif>
			<cfset row["value"] = "#search.permit_num# #search.permit_title# (#search.specific_type##i_date#)" >
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

</cfcomponent>
