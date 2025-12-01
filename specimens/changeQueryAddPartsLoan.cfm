<!--- 
  specimens/changeQueryAddPartsLoan.cfm add parts to loans.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2025 President and Fellows of Harvard College

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
<cfset pageTitle="Bulk Modify Parts">
<cfset pageHasTabs="true">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<cfif isDefined("url.action") and len(url.action) GT 0>
	<cfset action = url.action>
<cfelseif isDefined("form.action") and len(form.action) GT 0>
	<cfset action = form.action>
<cfelse>
	<cfset action="entryPoint">
</cfif>
<cfif isDefined("url.result_id") and len(url.result_id) GT 0>
	<cfset result_id = url.result_id>
<cfelseif isDefined("form.result_id") and len(form.result_id) GT 0>
	<cfset result_id = form.result_id>
</cfif>
<cfif isDefined("url.transaction_id") and len(url.transaction_id) GT 0>
	<cfset transaction_id = url.transaction_id>
<cfelseif isDefined("form.transaction_id") and len(form.transaction_id) GT 0>
	<cfset transaction_id = form.transaction_id>
</cfif>

<!--- get list of collection codes in result set --->
<cfquery name="colcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT distinct(collection_cde) 
	FROM 
		user_search_table
		JOIN cataloged_item ON user_search_table.collection_object_id = cataloged_item.collection_object_id
	WHERE
	user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
</cfquery>
<cfset colcdes = valuelist(colcde.collection_cde)>

<main class="container-fluid px-4 py-3" id="content">
<cftry>
	<cfswitch expression="#action#">
	<!--------------------------------------------------------------------->
	<cfcase value="entryPoint">
		<cfoutput>
			<cfif isDefined("result_id") and len(result_id) GT 0>
				<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(*) ct
					FROM 
						user_search_table
					WHERE
						user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				</cfquery>
			<cfelse>
				<cfthrow message="Unable to identify parts to work on [required variable table_name or result_id not defined].">
			</cfif>
			<script>
				var bc = new BroadcastChannel('resultset_channel');
				bc.onmessage = function (message) { 
					console.log(message);
					if (message.data.result_id == "#result_id#") { 
						messageDialog("Warning: You have removed one or more records from this result set, you must reload this page to see the current list of records this page affects.", "Result Set Changed Warning");
						$(".makeChangeButton").prop("disabled",true);
						$(".makeChangeButton").addClass("disabled");
						$(".tabChangeButton").prop("disabled",true);
						$(".tabChangeButton").addClass("disabled");
					}  
				} 
			</script>
			<cfif isDefined("transaction_id") and len(transaction_id) GT 0>
				<!--- TODO: Move to backing method --->
				<!--- lookup loan number and information about loan --->
				<cfquery name="getLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT l.loan_number, 
						c.collection_cde, 
						c.collection,
						l.loan_type, 
						l.loan_status, 
						to_char(l.return_due_date,'yyyy-mm-dd') as return_due_date, 
						to_char(l.closed_date,'yyyy-mm-dd') as closed_date,
						l.loan_instructions,
						trans.nature_of_material,
						to_char(trans.trans_date,'yyyy-mm-dd') as loan_date,
						concattransagent(trans.transaction_id,'recipient institution') recipient_institution
					FROM 
						trans
						join collection c on trans.collection_id = c.collection_id
						join loan l on trans.transaction_id = l.transaction_id
					WHERE trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
				</cfquery>
				<cfif getLoan.recordcount NEQ 1>
					<cfthrow message="No loan found for transaction_id=[#encodeForHtml(transaction_id)#]">
				</cfif>
				<cfloop query="getLoan">
					<h2 class="h3">#getLoan.loan_number#</h2>
					<div>#loan_type# #loan_status# #loan_date# to #recipient_institution# due #return_due_date#</div>
					<div>#nature_of_material#
				</cfloop>

			</cfif>
			<div class="row mx-0">
				<div class="col-12">
					<h1 class="h2 px-2">Bulk Add Parts to Loan</h1>
					<p class="px-2 mb-1">Add Parts from #getCount.ct# cataloged items from specimen search result [#result_id#] to a Loan</p>
					<cfif getCount.ct gte 1000>
						<cfthrow message="You can only use this form on up to 1000 specimens at a time. Please <a href='/Specimens.cfm'>revise your search</a>."><!--- " --->
					</cfif>

					<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT coll_obj_disposition
						FROM ctcoll_obj_disp
					</cfquery>
					<cfquery name="ctNumericModifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT modifier 
						FROM ctnumeric_modifiers
					</cfquery>
					<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT preserve_method 
						FROM ctspecimen_preserv_method 
						WHERE collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#colcdes#">
					</cfquery>

					<!--- queries to populate pick lists for filtering --->
					<cfquery name="existParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							count(specimen_part.collection_object_id) partcount,
							specimen_part.part_name
						FROM
							specimen_part
							<cfif isDefined("result_id") and len(result_id) GT 0>
								JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
						WHERE
								user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
							<cfelse>
								JOIN #table_name# on specimen_part.derived_from_cat_item=#table_name#.collection_object_id
						</cfif>
						GROUP BY specimen_part.part_name
						ORDER BY specimen_part.part_name
					</cfquery>
					<cfquery name="existPreserve" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							count(specimen_part.collection_object_id) partcount,
							specimen_part.preserve_method
						FROM
							specimen_part
							<cfif isDefined("result_id") and len(result_id) GT 0>
								JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
						WHERE
								user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
							<cfelse>
								JOIN #table_name# on specimen_part.derived_from_cat_item=#table_name#.collection_object_id
							</cfif>
						GROUP BY specimen_part.preserve_method
						ORDER BY specimen_part.preserve_method
					</cfquery>
					<!--- TODO: Missing queries --->

					<h2 class="h3">Filter specimens for parts matching...</h2>
					<form name="filterByPart" method="post" action="/specimens/changeQueryParts.cfm">
						<input type="hidden" name="action" value="filterParts">
						<input type="hidden" name="result_id" value="#result_id#">
						<div class="form-row">
							<div class="col-12 col-md-4 pt-1">
								<label for="exist_part_name" class="data-entry-label">Part Name Matches</label>
								<select name="exist_part_name" id="exist_part_name" size="1" class="reqdClr data-entry-select" required>
									<option selected="selected" value=""></option>
									<cfloop query="existParts">
										<option value="#Part_Name#">#Part_Name# (#existParts.partCount# parts)</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 pt-1">
								<label for="exist_preserve_method" class="data-entry-label">Preserve Method Matches</label>
								<select name="exist_preserve_method" id="exist_preserve_method" size="1" class="data-entry-select">
									<option selected="selected" value=""></option>
									<cfloop query="existPreserve">
										<option value="#Preserve_method#">#Preserve_method# (#existPreserve.partCount# parts)</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 pt-1">
								<label for="existing_lot_count_modifier" class="data-entry-label">Lot Count Modifier Matches</label>
								<select name="existing_lot_count_modifier" id="existing_lot_count_modifier" size="1" class="data-entry-select">
									<option selected="selected" value=""></option>
									<cfloop query="existLotCountModifier">
										<option value="#lot_count_modifier#">#lot_count_modifier#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 pt-1">
								<label for="existing_lot_count" class="data-entry-label">Lot Count Matches</label>
								<select name="existing_lot_count" id="existing_lot_count" size="1" class="data-entry-select">
									<option selected="selected" value=""></option>
									<cfloop query="existLotCount">
										<option value="#lot_count#">#lot_count#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 pt-1">
								<label for="existing_coll_obj_disposition" class="data-entry-label">Disposition Matches</label>
								<select name="existing_coll_obj_disposition" id="existing_coll_obj_disposition" size="1" class="data-entry-select">
									<option selected="selected" value=""></option>
									<cfloop query="existDisp">
										<option value="#coll_obj_disposition#">#coll_obj_disposition#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 pt-1">
								<input type="submit" value="Filter" class="btn ml-2 mt-2 btn-xs btn-secondary">
							</div>
						</div>
					</form>



				</div>
			</div>
		</cfoutput>
	</cfcase>
	</cfswitch>
<cfcatch>
	<h2 class="h3 px-2 mt-1">Error</h2>
	<cfoutput>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<p class="px-2">#error_message#</p>
	</cfoutput>
</cfcatch>
</cftry>
</main>

<cfinclude template="/shared/_footer.cfm">
