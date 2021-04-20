<!--
transactions/reviewLoanItems.cfm

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
<cfset pageTitle="Review Loan Items">
<cfinclude template="/shared/_header.cfm">

<script type='text/javascript' src='/transactions/js/reviewLoanItems.js'></script>

<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select coll_obj_disposition from ctcoll_obj_disp
</cfquery>

<cfif not isdefined("transaction_id")>
	<cfthrow message="No transaction specified.">
</cfif>
<cfif not isdefined("action")><cfset action="nothing"></cfif>

<!-------------------------------------------------------------------------------->
<cfif #Action# is "delete">
	<cfoutput>
	<cfif isdefined("coll_obj_disposition") AND coll_obj_disposition is "on loan">
		<!--- see if it's a subsample --->
		<cfquery name="isSSP" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select SAMPLED_FROM_OBJ_ID from specimen_part where collection_object_id = #partID#
		</cfquery>
		<cfif #isSSP.SAMPLED_FROM_OBJ_ID# gt 0>
					You cannot remove this item from a loan while it's disposition is "on loan." 
			<br />Use the form below if you'd like to change the disposition and remove the item 
			from the loan, or to delete the item from the database completely.
			
			<form name="cC" method="post" action="a_loanItemReview.cfm">
				<input type="hidden" name="action" />
				<input type="hidden" name="transaction_id" value="#transaction_id#" />
				<input type="hidden" name="item_instructions" value="#item_instructions#" />
				<input type="hidden" name="loan_item_remarks" value="#loan_item_remarks#" />
				<input type="hidden" name="partID" value="#partID#" />
				<input type="hidden" name="spRedirAction" value="delete" />
				Change disposition to: <select name="coll_obj_disposition" size="1">
					<cfloop query="ctDisp">
						<option value="#coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
					</cfloop>				
				</select>
				<p />
				<input type="button" 
					class="delBtn"
					onmouseover="this.className='delBtn btnhov'"
					onmouseout="this.className='delBtn'"
					value="Remove Item from Loan" 
					onclick="cC.action.value='saveDisp'; submit();" />
				
				<p /><input type="button" 
					class="delBtn"
					onmouseover="this.className='delBtn btnhov'"
					onmouseout="this.className='delBtn'"
					value="Delete Subsample From Database" 
					onclick="cC.action.value='killSS'; submit();"/>
					<p /><input type="button" 
					class="qutBtn"
					onmouseover="this.className='qutBtn btnhov'"
					onmouseout="this.className='qutBtn'"
					value="Discard Changes" 
					onclick="cC.action.value='nothing'; submit();"/>
			</form>
			<cfabort>
			<cfabort>
		<cfelse>
			You cannot remove this item from a loan while it's disposition is "on loan." 
			<br />Use the form below if you'd like to change the disposition and remove the item 
			from the loan.
			
			<form name="cC" method="post" action="a_loanItemReview.cfm">
				<input type="hidden" name="action" />
				<input type="hidden" name="transaction_id" value="#transaction_id#" />
				<input type="hidden" name="item_instructions" value="#item_instructions#" />
				<input type="hidden" name="loan_item_remarks" value="#loan_item_remarks#" />
				<input type="hidden" name="partID" id="partID" value="#partID#" />
				<input type="hidden" name="spRedirAction" value="delete" />
				<br />Change disposition to: <select name="coll_obj_disposition" size="1">
					<cfloop query="ctDisp">
						<option value="#coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
					</cfloop>				
				</select>
				<br /><input type="button" 
					class="delBtn"
					onmouseover="this.className='delBtn btnhov'"
					onmouseout="this.className='delBtn'"
					value="Remove Item from Loan" 
					onclick="cC.action.value='saveDisp'; submit();" />
				<br /><input type="button" 
					class="qutBtn"
					onmouseover="this.className='qutBtn btnhov'"
					onmouseout="this.className='qutBtn'"
					value="Discard Changes" 
					onclick="cC.action.value='nothing'; submit();"/>
			</form>
			<cfabort>
		</cfif>
	</cfif>
	<cfquery name="deleLoanItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM loan_item where collection_object_id = #partID#
		and transaction_id = #transaction_id#
	</cfquery>
		<cflocation url="a_loanItemReview.cfm?transaction_id=#transaction_id#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "killSS">
	<cfoutput>
<cftransaction>
	<cfquery name="deleLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM loan_item WHERE collection_object_id = #partID#
		and transaction_id=#transaction_id#
	</cfquery>
	<cfquery name="delePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM specimen_part WHERE collection_object_id = #partID#
	</cfquery>
	<cfquery name="delePartCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM coll_object WHERE collection_object_id = #partID#
	</cfquery>
	<cfquery name="delePartRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM coll_object_remark WHERE collection_object_id = #partID#
	</cfquery>
	<cfquery name="getContID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select container_id from coll_obj_cont_hist where
		collection_object_id = #partID#
	</cfquery>
	
	<cfquery name="deleCollCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM coll_obj_cont_hist WHERE collection_object_id = #partID#
	</cfquery>
	<cfquery name="deleCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM container_history WHERE container_id = #getContID.container_id#
	</cfquery>
	<cfquery name="deleCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM container WHERE container_id = #getContID.container_id#
	</cfquery>
</cftransaction>
	<cflocation url="a_loanItemReview.cfm?transaction_id=#transaction_id#">
	</cfoutput>

</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "BulkUpdateDisp">
	<cfoutput>
		<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select collection_object_id FROM loan_item where transaction_id=#transaction_id#
		</cfquery>
		<cfloop query="getCollObjId">
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE coll_object SET coll_obj_disposition = '#coll_obj_disposition#'
			where collection_object_id = #collection_object_id#
			</cfquery>
		</cfloop>
	<cflocation url="a_loanItemReview.cfm?transaction_id=#transaction_id#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "BulkUpdatePres">
	<cfoutput>
		<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select collection_object_id FROM loan_item where transaction_id=#transaction_id#
		</cfquery>
		<cfloop query="getCollObjId">
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE specimen_part SET preserve_method  = '#part_preserve_method#'
			where collection_object_id = #collection_object_id#
			</cfquery>
		</cfloop>
	<cflocation url="a_loanItemReview.cfm?transaction_id=#transaction_id#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "saveDisp">
	<cfoutput>
	<cftransaction>
		<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE coll_object SET coll_obj_disposition = '#coll_obj_disposition#'
			where collection_object_id = #partID#
		</cfquery>
		<cfquery name="upItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE loan_item SET
				 transaction_id=#transaction_id#
				<cfif len(#item_instructions#) gt 0>
					,item_instructions = '#item_instructions#'
				<cfelse>
					,item_instructions = null
				</cfif>
				<cfif len(#loan_item_remarks#) gt 0>
					,loan_item_remarks = '#loan_item_remarks#'
				<cfelse>
					,loan_item_remarks = null
				</cfif>
			WHERE
				collection_object_id = #partID# AND
				transaction_id=#transaction_id#
		</cfquery>
	</cftransaction>
	<cfif isdefined("spRedirAction") and len(#spRedirAction#) gt 0>
		<cfset action=#spRedirAction#>
	<cfelse>
		<cfset action="nothing">
	</cfif>
	<cflocation url="a_loanItemReview.cfm?transaction_id=#transaction_id#&item_instructions=#item_instructions#&partID=#partID#&loan_item_remarks=#loan_item_remarks#&action=#action#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #action# is "nothing">
	<cfquery name="getPartLoanRequests" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select 
			cat_num, 
			cataloged_item.collection_object_id,
			collection,
			collection.collection_cde,
			part_name,
			preserve_method,
			condition,
			sampled_from_obj_id,
			item_descr,
			item_instructions,
			loan_item_remarks,
			coll_obj_disposition,
			scientific_name,
			Encumbrance,
			agent_name,
			loan_number,
			specimen_part.collection_object_id as partID,
			concatSingleOtherId(cataloged_item.collection_object_id,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#">) AS CustomID		 			 
		from 
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
			loan_item.transaction_id = <cfqueryparam cfsqltype="cf_sql_number" value="#transaction_id#" >
		ORDER BY cat_num
	</cfquery>
	<cfquery name="ctSovereignNation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT count(*) as ct, sovereign_nation
		FROM loan_item 
			left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
			left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
			left join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
			left join locality on collecting_event.locality_id = locality.locality_id
		WHERE 
			loan_item.transaction_id = <cfqueryparam cfsqltype="cf_sql_number" value="#transaction_id#" >
		GROUP BY sovereign_nation
	</cfquery>
	<!--- Obtain list of preserve_method values for the collection that this loan is from --->
	<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select ct.preserve_method, c.collection_cde 
		from ctspecimen_preserv_method ct 
			left join collection c on ct.collection_cde = c.collection_cde
			left join trans t on c.collection_id = t.collection_id 
		where t.transaction_id = <cfqueryparam cfsqltype="cf_sql_number" value="#transaction_id#" >
	</cfquery>
	<!--- handle legacy loans with cataloged items as the item --->
	<main class="container" id="content">
		<cfoutput>
			<cfquery name="aboutLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select l.loan_number, c.collection_cde, c.collection
				from collection c 
					left join trans t on c.collection_id = t.collection_id 
					left join loan l on t.transaction_id = l.transaction_id
				where t.transaction_id = <cfqueryparam cfsqltype="cf_sql_number" value="#transaction_id#" >
			</cfquery>
			<cfif isdefined("Ijustwannadownload") and #Ijustwannadownload# is "yep">
				<cfset fileName = "/download/ArctosLoanData_#getPartLoanRequests.loan_number#.csv">
				<cfset ac=getPartLoanRequests.columnlist>
				<cfset header=#trim(ac)#>
				<cffile action="write" file="#Application.webDirectory##fileName#" addnewline="yes" output="#header#">
				<cfloop query="getPartLoanRequests">
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

			<!--- count cataloged items and parts in the loan --->
			<cfquery name="catCnt" dbtype="query">
				select count(distinct(collection_object_id)) c 
				from getPartLoanRequests
			</cfquery>
			<cfif catCnt.c eq ''>
				<cfset catCount = 'no'>
			<cfelse>
				<cfset catCount = catCnt.c>
			</cfif>
			<cfquery name="prtItemCnt" dbtype="query">
				select count(distinct(partID)) c 
				from getPartLoanRequests
			</cfquery>
			<cfif prtItemCnt.c eq ''>
				<cfset partCount = 'no'>
			<cfelse>
				<cfset partCount = prtItemCnt.c>
			</cfif>
			<section class="row">
				<h2 class="h3">
					Review items in loan
					<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#aboutLoan.loan_number#</a>.
				</h2>
				<div class="row">
					<div class="col-12 col-xl-6">
						<p>There are #partCount# items from #catCount# specimens in this loan.</p>
					</div>
					<div class="col-12 col-xl-6">
						<h3 class="h4">Countries of Origin</h3>
						<cfset sep="">
						<cfloop query=ctSovereignNation>
							<cfif len(sovereign_nation) eq 0><cfset sovereign_nation = '[no value set]'></cfif>
							<span>#sep##sovereign_nation#&nbsp;(#ct#)</span>
							<cfset sep="; ">
						</cfloop>
					</div>
				</div>
				<div class="row">
					<div class="col-12 col-xl-6">
						<a href="a_loanItemReview.cfm?action=nothing&transaction_id=#transaction_id#&Ijustwannadownload=yep">Download (csv)</a>
					</div>
					<div class="col-12 col-xl-6">
						<form name="BulkUpdateDisp" method="post" action="a_loanItemReview.cfm">
						<br>Change disposition of all these items to:
						<input type="hidden" name="Action" value="BulkUpdateDisp">
							<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
							<select name="coll_obj_disposition" size="1">
								<cfloop query="ctDisp">
									<option value="#coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
								</cfloop>				
							</select>
							<input type="submit" value="Update Disposition" class="savBtn"
							   onmouseover="this.className='savBtn btnhov'" onmouseout="this.className='savBtn'">	
						</form>
					</div>
				</div>
			   <cfif aboutLoan.collection EQ 'Cryogenic'>
					<div class="row">
						<div class="col-12">
							<form name="BulkUpdatePres" method="post" action="a_loanItemReview.cfm">
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
						</div>
					<div>
			   </cfif>
				<div class="row">
					<div class="col-12 col-xl-6">
						View 
						<a href="/findContainer.cfm?loan_trans_id=#transaction_id#">Part Locations</a>
							or <a href="loanFreezerLocn.cfm?transaction_id=#transaction_id#">Print Freezer Locations</a>
					</div>
				</div>

				<table border id="t" class="sortable">
					<tr>
						<th>
							CN
						</th>
						<th>
							#session.CustomOtherIdentifier#
						</th>
						<th>
							Scientific Name
						</th>
						<th>
							Item
						</th>
						<th>
							Condition
						</th>
						<th>
							Subsample?
						</th>
						
						<th>
							Item Instructions
						</th>
						<th>
							Item Remarks
						</th>
						<cfif aboutLoan.collection EQ 'Cryogenic'>
							<th>
								Preserve Method
							</th>
						</cfif>
						<th>
							Disposition
						</th>
						
						<th>
							Encumbrance
						</th>
						<th>&nbsp;
							
						</th>
					</tr>
				
					<cfset i=1>
					<cfloop query="getPartLoanRequests">
						<tr id="rowNum#partID#">
							<td>
								<a href="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#">#collection# #cat_num#</a>
							</td>
							<td>
								#CustomID#&nbsp;
							</td>	
							<td>
								<em>#scientific_name#</em>&nbsp;
							</td>
							<td>
								<a href="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#">#part_name# (#preserve_method#)</a>
							</td>
							<td>
								<textarea name="condition#partID#" 
									rows="2" cols="20"
									id="condition#partID#"
									onchange="this.className='red';updateCondition('#partID#')">#condition#</textarea>
									<span class="infoLink" onClick="chgCondition('#partID#')">History</span>
							</td>
							<td>
								<cfif len(#sampled_from_obj_id#) gt 0>
									yes
								<cfelse>
									no
								</cfif>
								<input type="hidden" name="isSubsample#partID#" id="isSubsample#partID#" value="#sampled_from_obj_id#" />
							</td>	
							<td valign="top">
								<textarea name="item_instructions#partID#" id="item_instructions#partID#" rows="2" cols="20" onchange="this.className='red';updateInstructions('#partID#')">#Item_Instructions#</textarea>
							</td>
							<td valign="top">
								<textarea name="loan_Item_Remarks#partID#" id="loan_Item_Remarks#partID#" rows="2" cols="20"
									onchange="this.className='red';updateLoanItemRemarks('#partID#')">#loan_Item_Remarks#</textarea>
							</td>
							<cfif aboutLoan.collection EQ 'Cryogenic'>
								<td>
									#preserve_method#
								</td>
							</cfif>
							<td>
								<cfset thisDisp = #coll_obj_disposition#>
								<select name="coll_obj_disposition#partID#" id="coll_obj_disposition#partID#" size="1" onchange="this.className='red';updateDispn('#partID#')">
									<cfloop query="ctDisp">
										<option 
											<cfif #ctDisp.coll_obj_disposition# is "#thisDisp#"> selected </cfif>
											value="#coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
									</cfloop>				
								</select>
							</td>
							<td>
								#Encumbrance# <cfif len(#agent_name#) gt 0> by #agent_name#</cfif>&nbsp;
							</td>
							<td>
								<img src="/images/del.gif" class="likeLink" onclick="remPartFromLoan(#partID#);" />
							</td>
						</tr>
						<cfset i=#i#+1>
					</cfloop>
				</table>
			<br><a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">Back to Edit Loan</a>
		</cfoutput>
	</main>
</cfif>

<cfinclude template="/shared/_footer.cfm">
