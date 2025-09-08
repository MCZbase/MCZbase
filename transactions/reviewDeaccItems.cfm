<!--
transactions/reviewDeaccItems.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2021 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<cfset pageTitle="Review Deaccession Items">
<cfinclude template="/shared/_header.cfm">

<script type='text/javascript' src='/transactions/js/reviewLoanItems.js'></script>

<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select coll_obj_disposition from ctcoll_obj_disp
</cfquery>
<cfquery name="ctdeacc_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select deacc_type from ctdeacc_type
</cfquery>

<cfif not isdefined("transaction_id")>
	<cfthrow message="No transaction specified.">
</cfif>
<cfif not isdefined("action")>
	<cfset action="nothing">
</cfif>
<!-------------------------------------------------------------------------------->
<cfif #Action# is "killSS">
	<cfoutput>
<cftransaction>
	<cfquery name="deleDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM deacc_item 
		WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
		and transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
	</cfquery>
	<cfquery name="delePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM specimen_part 
		WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
	</cfquery>
	<cfquery name="delePartCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM coll_object 
		WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
	</cfquery>
	<cfquery name="delePartRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM coll_object_remark 
		WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
	</cfquery>

	<cfquery name="getContID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select container_id 
		from coll_obj_cont_hist 
		where
		collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
	</cfquery>
	<cfquery name="deleCollCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM coll_obj_cont_hist 
		WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
	</cfquery>
	<cfquery name="deleCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM container_history 
		WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getContID.container_id#">
	</cfquery>
	<cfquery name="deleCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM container 
		WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getContID.container_id#">
	</cfquery>
</cftransaction>
	<cflocation url="a_deaccItemReview.cfm?transaction_id=#transaction_id#">
	</cfoutput>

</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "BulkUpdateDisp">
	<cfoutput>
		<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select collection_object_id 
			FROM deacc_item 
			where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfloop query="getCollObjId">
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE coll_object 
				SET coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#coll_obj_disposition#">
				where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
			</cfquery>
		</cfloop>
	<cflocation url="a_deaccItemReview.cfm?transaction_id=#transaction_id#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "BulkUpdatePres">
	<cfoutput>
		<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select collection_object_id 
			FROM deacc_item 
			where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfloop query="getCollObjId">
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE specimen_part 
			SET preserve_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#part_preserve_method#">
			where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
			</cfquery>
		</cfloop>
	<cflocation url="a_deaccItemReview.cfm?transaction_id=#transaction_id#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "saveDisp">
	<cfoutput>
		<cftransaction>
			<cftry>
				<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE coll_object 
					SET coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#coll_obj_disposition#">
					where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
				</cfquery>
				<cfquery name="upItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE deacc_item SET
						transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
						<cfif len(#deacc_item_remarks#) gt 0>
							,deacc_item_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_item_remarks#">
						<cfelse>
							,deacc_item_remarks = null
						</cfif>
					WHERE
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
						AND
						transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				</cfquery>
				<cftransaction action="commit">
			<cfcatch>
				<cftransaction action="commit">
			</cfcatch>
			</cftry>
		</cftransaction>
		<cfif isdefined("spRedirAction") and len(#spRedirAction#) gt 0>
			<cfset action=#spRedirAction#>
		<cfelse>
			<cfset action="nothing">
		</cfif>
		<cflocation url="a_deaccItemReview.cfm?transaction_id=#transaction_id#&partID=#partID#&deacc_item_remarks=#deacc_item_remarks#&action=#action#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #action# is "nothing">
	<cfquery name="getPartDeaccRequests" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select 
			cat_num, 
			cataloged_item.collection_object_id,
			collection,
			collection.collection_cde,
			part_name,
			preserve_method,
			condition,
			lot_count,
			lot_count_modifier,
			sampled_from_obj_id,
			item_descr,
			deacc_item_remarks,
			item_instructions,
			deacc_type,
			deacc_reason,
			coll_obj_disposition,
			scientific_name,
			Encumbrance,
			decode(encumbering_agent_id,NULL,'',MCZBASE.get_agentnameoftype(encumbering_agent_id)) agent_name,
			deacc_number,
			specimen_part.collection_object_id as partID,
			concatSingleOtherId(cataloged_item.collection_object_id, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#">) AS CustomID,
			accn_number,
			accn_id
		 from 
			deacc_item, 
			deaccession,
			specimen_part, 
			coll_object,
			cataloged_item,
			coll_object_encumbrance,
			encumbrance,
			identification,
			collection,
			accn
		WHERE
			deacc_item.collection_object_id = specimen_part.collection_object_id AND
			deaccession.transaction_id = deacc_item.transaction_id AND
			specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
			specimen_part.collection_object_id = coll_object.collection_object_id AND
			cataloged_item.collection_object_id = coll_object_encumbrance.collection_object_id (+) and
			coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id (+) AND
			cataloged_item.collection_object_id = identification.collection_object_id AND
			identification.accepted_id_fg = 1 AND
			cataloged_item.collection_id=collection.collection_id AND
			cataloged_item.accn_id = accn.transaction_id AND
			deacc_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
		ORDER BY cat_num
	</cfquery>
	<!--- Obtain list of preserve_method values for the collection that this deaccession is from --->
	<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select ct.preserve_method, c.collection_cde 
		from ctspecimen_preserv_method ct 
			left join collection c on ct.collection_cde = c.collection_cde
			left join trans t on c.collection_id = t.collection_id 
		where t.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
	</cfquery>
	<cfquery name="aboutDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select d.deacc_number, c.collection_cde, c.collection
		from collection c 
			left join trans t on c.collection_id = t.collection_id 
			left join deaccession d on t.transaction_id = d.transaction_id
		where t.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
	</cfquery>
	<main class="container" id="content">
		<cfoutput>
			<cfif isdefined("Ijustwannadownload") and #Ijustwannadownload# is "yep">
				<cfset fileName = "/download/ArctosLoanData_#getPartDeaccRequests.deacc_number#.csv">
				<cfset ac=getPartDeaccRequests.columnlist>
				<cfset header=#trim(ac)#>
				<cffile action="write" file="#Application.webDirectory##fileName#" addnewline="yes" output="#header#">
				<cfloop query="getPartDeaccRequests">
					<cfset oneLine = "">
					<cfloop list="#ac#" index="c">
						<cfset thisData = evaluate(c)>
						<cfif len(oneLine) is 0>
							<cfset oneLine = '"#thisData#"'>
						<cfelse>
							<cfset oneLine = '#oneLine#,"#thisData#"'>
						</cfif>
					</cfloop>
					<cfset oneLine = trim(oneLine)>
					<cffile action="append" file="#Application.webDirectory##fileName#" addnewline="yes" output="#oneLine#">
				</cfloop>
				<section class="row">
					<h2 class="h3">Download items</h2>
					<a href="#Application.ServerRootUrl#/#fileName#">Right-click to save your download.</a>
				</section>
				<cfabort>
			</cfif>
		
			<cfquery name="catCnt" dbtype="query">
				select count(distinct(collection_object_id)) c from getPartDeaccRequests
			</cfquery>
			<cfif catCnt.c eq ''><cfset catCount = 'no'><cfelse><cfset catCount = catCnt.c></cfif>
			<cfquery name="prtItemCnt" dbtype="query">
				select count(distinct(partID)) c from getPartDeaccRequests
			</cfquery>
			<cfif prtItemCnt.c eq ''><cfset partCount = 'no'><cfelse><cfset partCount = prtItemCnt.c></cfif>
			<cfset otherIdOn = false>
			<cfif isdefined("showOtherId") and #showOtherID# is "true">
				<cfset otherIdOn = true>
			</cfif>
		
			<section class="row">
				<h2 class="h3">
					Review items in deaccession
					<a href="/transactions/Deaccession.cfm?action=edit&transaction_id=#transaction_id#">#aboutDeacc.deacc_number#</a>
				</h2>
				<br>There are #partCount# items from #catCount# specimens in this deaccession.
				<br>
				<a href="a_deaccItemReview.cfm?action=nothing&transaction_id=#transaction_id#&Ijustwannadownload=yep">Download (csv)</a>
				<form name="BulkUpdateDisp" method="post" action="a_deaccItemReview.cfm">
					<br>Change disposition of all these items to:
					<input type="hidden" name="Action" value="BulkUpdateDisp">
					<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
					<select name="coll_obj_disposition" size="1">
						<cfloop query="ctDisp">
							<option value="#coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
						</cfloop>				
					</select>
				<input type="submit" value="Update Dispositions" class="savBtn"
					onmouseover="this.className='savBtn btnhov'" onmouseout="this.className='savBtn'">	
			</form>
		 	<cfif aboutDeacc.collection EQ 'Cryogenic'>
				<form name="BulkUpdatePres" method="post" action="a_deaccItemReview.cfm">
					<br>Change preservation method of all these items to:
					<input type="hidden" name="Action" value="BulkUpdatePres">
						<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
						<select name="part_preserve_method" size="1">
							<cfloop query="ctPreserveMethod">
								<option value="#ctPreserveMethod.preserve_method#">#ctPreserveMethod.preserve_method#</option>
							</cfloop>				
						</select>
					<input type="submit" value="Update Preservation method" class="savBtn"
						onmouseover="this.className='savBtn btnhov'" onmouseout="this.className='savBtn'">	
				</form>
			</cfif>
			<p>Edit part counts (particularly for subsamples) in the cataloged item.</p>
		<table class="partname" id="t" class="sortable">
			<tr>
				<th class="inside">Cataloged Item</th>
				<cfif otherIdOn><th class="inside"> #session.CustomOtherIdentifier# </th></cfif>
				<th class="inside">Scientific Name</th>
				<th class="inside">Part Name & Count</th>
				<th class="inside">Condition</th>
				<th class="inside">Disposition Type</th>
				<th class="inside">Deaccession Item Remarks</th>
				<th class="inside">Deaccession Item Instructions</th>
				<th class="inside">Accession</th>
				<th class="inside">Encumbered</th>
				<th>Remove</th>
			</tr>
		
		<cfset i=1>
		<cfloop query="getPartDeaccRequests">
			<tr id="rowNum#partID#">
				<td class="inside">
					<a href="/specimens/Specimen.cfm?collection_object_id=#collection_object_id#">#collection# #cat_num#</a>
		
				</td>
				<cfif otherIdOn>
				   <td class="inside">
					#CustomID#&nbsp;
				   </td>
				</cfif>
				<td class="inside">
					<em>#scientific_name#</em>&nbsp;
				</td>
				<td class="inside">
					#getPartDeaccRequests.part_name# (#preserve_method#) #lot_count# #lot_count_modifier#
					<cfif len(#sampled_from_obj_id#) gt 0> <strong>Subsample</strong></cfif>
					<input type="hidden" name="isSubsample#partID#" id="isSubsample#partID#" value="#sampled_from_obj_id#" />
				</td>
				<td class="inside">
					<input type="text" name="condition#partID#"
						size="10" class="reqdClr"
						id="condition#partID#"
						onchange="this.className='red';updateCondition('#partID#')" 
		 				value="#condition#">
						<span class="infoLink" onClick="chgCondition('#partID#')">History</span>
				</td>
				<td class="inside">
					<cfset thisDisp = #coll_obj_disposition#>
					<select name="coll_obj_disposition#partID#"
						id="coll_obj_disposition#partID#"
						 size="1" onchange="this.className='red';updateDispn('#partID#')">
							<cfloop query="ctDisp">
								<option
									<cfif #ctDisp.coll_obj_disposition# is "#thisDisp#"> selected </cfif>
									value="#coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
							</cfloop>
					</select>
				</td>
				<td valign="top" class="inside">
					<textarea name="deacc_Item_Remarks#partID#" id="deacc_Item_Remarks#partID#" rows="2" cols="20"
					onchange="this.className='red';updateDeaccItemRemarks('#partID#')">#deacc_item_remarks#</textarea>
				</td>
				<td valign="top" class="inside">
					<textarea name="item_instructions#partID#" id="item_instructions#partID#" rows="2" cols="20"
					onchange="this.className='red';updateDeaccItemInstructions('#partID#')">#item_instructions#</textarea>
				</td>
				<td class="inside">
					<a href="/transactions/Accession.cfm?action=edit&transaction_id=#accn_id#">#accn_number#</a>
				</td>
				<td class="inside">
					#encumbrance# <cfif len(#agent_name#) gt 0> by #agent_name#</cfif>&nbsp;
				</td>
				<td class="inside">
					<img src="/images/del.gif" class="likeLink" onclick="remPartFromDeacc(#partID#,#collection_object_id#);" />
				</td>
			</tr>
		<cfset i=#i#+1>
		</cfloop>
		
		</cfoutput>
		</table>
		<cfoutput>
			<br><a href="/transactions/Deaccession.cfm?action=edit&transaction_id=#transaction_id#">Back to Edit Deaccession</a>
		</cfoutput>
	</main>
</cfif>

<cfinclude template="/shared/_footer.cfm">
