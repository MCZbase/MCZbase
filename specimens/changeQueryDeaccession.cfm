<cfset pageTitle = "Deaccession cataloged items in Search Result">
<cfinclude template="/shared/_header.cfm">

<cfif findNoCase('master',Session.gitBranch) GT 0>
	<cfthrow message="Not ready for production use.">
</cfif>

<cfif not isDefined("result_id") OR len(result_id) EQ 0>
	<cfthrow message = "No result_id provided for result set to deaccession.">
</cfif>
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="entryPoint">
</cfif>

<cfquery name="ctcoll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select collection, collection_id from collection order by collection
</cfquery>

<!--------------------------------------------------------------------------------->
<cfswitch expression="#action#">
	<cfcase value="entryPoint">
		<cfquery name="getItemCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				count(cataloged_item.collection_object_id) ct
			FROM
				user_search_table 
				JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
			WHERE
				result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>
		<cfquery name="getDeaccessions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				count(cataloged_item.collection_object_id) ct,
				deaccession.deacc_number,
				trans_coll.collection,
				nvl(to_char(trans.trans_date,'YYYY'),'[no date]')  year
			FROM
				user_search_table 
				JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id 
				JOIN specimen_part on cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
				JOIN deacc_item on specimen_part.collection_object_id = deacc_item.collection_object_id
				JOIN deaccession on deacc_item.transaction_id = deaccession.transaction_id
				JOIN trans on deaccession.transaction_id = trans.transaction_id 
				JOIN collection trans_coll on trans.collection_id=trans_coll.collection_id
			WHERE
				result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			GROUP BY deacc_number, trans_coll.collection, nvl(to_char(trans.trans_date,'YYYY'),'[no date]')
			ORDER BY deacc_number
		</cfquery>
		<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				cataloged_item.collection_object_id,
				cataloged_item.collection_cde,
				cataloged_item.cat_num,
				accn.accn_number,
				nvl(to_char(accn.received_date,'YYYY-MM-DD'),'[no date]') received_date,
				accn.accn_type,
				MCZBASE.GET_COLLECTORSTYPEDNAME(cataloged_item.collection_object_id) collectors,
				geog_auth_rec.higher_geog,
				locality.spec_locality,
				collecting_event.verbatim_date,
				MCZBASE.GET_SCIENTIFIC_NAME_AUTHS(cataloged_item.collection_object_id) scientific_name,
				collection.institution_acronym,
				trans.institution_acronym transInst,
				trans.transaction_id,
				collection.collection,
				accn_coll.collection accnColln,
				MCZBASE.GET_SHORT_PARTS_LIST_CONCAT(cataloged_item.collection_object_id) parts
			FROM
				user_search_table 
				JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id 
				JOIN accn on cataloged_item.accn_id = accn.transaction_id
				JOIN trans on accn.transaction_id = trans.transaction_id 
				JOIN collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
				JOIN locality on collecting_event.locality_id = locality.locality_id
				JOIN geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
				JOIN collection on cataloged_item.collection_id = collection.collection_id
				JOIN collection accn_coll on trans.collection_id=accn_coll.collection_id
			WHERE
				result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				and rownum < 1001
			ORDER BY cataloged_item.collection_cde, cataloged_item.cat_num
		</cfquery>
		<cfquery name="getCollections" dbtype="query">
			SELECT distinct collection from getItems
		</cfquery>
		<cfoutput>
			<main class="container-xl" id="content">
				<section class="row" aria-labelledby="formheading">
					<div class="col-12 pt-4">
						<h1 class="h3 px-1" id="formheading" >
							<cfif getItemCount.ct GT getItems.recordcount>
								Deaccession all parts from all (#getItemCount.ct#) cataloged items in this result (first #getItems.recordcount# are listed below):
							<cfelse>
								Deaccession all parts of all the cataloged items listed below (#getItems.recordcount#):
							</cfif>
						</h1>
						<form name="addItems" method="post" action="/specimens/changeQueryDeaccession.cfm">
							<input type="hidden" name="Action" value="deaccessionItems">
							<input type="hidden" name="result_id" value="#result_id#">
							<div class="form-row mb-2">
								<div class="col-12 col-md-3 pb-2">
									<label for="collection_id" class="data-entry-label">Collection</label>
									<select name="collection_id" id="collection_id" size="1" class="data-entry-select reqdClr" required>
										<cfloop query="ctcoll">
											<cfif getCollections.recordcount EQ 1 AND getCollections.collection EQ ctcoll.collection>
												<cfset selected = "selected">
											<cfelse>
												<cfset selected = "">
											</cfif>
											<option value="#ctcoll.collection_id#" #selected#>#ctcoll.collection#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-3">
									<label for="deacc_number" class="data-entry-label mt-2 mt-md-0">Deaccession</label>
									<input type="text" name="deacc_number" id="deacc_number" class="data-entry-input reqdClr" required>
									<input type="hidden" name="trans_id" id="trans_id">
									<script>
										jQuery(document).ready(function() {
											// makeAccessionAutocompleteLimitedMeta("deacc_number", "trans_id","collection_id");
											makeDeaccessionAutocompleteMeta("deacc_number","trans_id");
										});
									</script>
								</div>
								<div class="col-12 col-md-3">
									<label for="deacc_item_remarks" class="data-entry-label mt-2 mt-md-0">Remarks to add to each item</label>
									<input type="text" name="deacc_item_remarks" id="deacc_item_remarks" class="data-entry-input" maxlength="255">
								</div>
								<div class="col-12 col-md-3 col-lg-4 mb-2 mb-md-0">
									<div class="data-entry-label">&nbsp;</div>
									<input type="submit" id="s_btn" value="Deaccession" class="btn btn-xs btn-warning">
								</div>
							</div>
						</form>
					</div>
				</section>
				<section class="row"> 
					<div class="col-12 pb-4">
						<table class="table table-responsive table-striped d-xl-table">
							<thead class="thead-light">
								<tr>
									<th>Cat Num</th>
									<th>Scientific Name</th>
									<th>Accession</th>
									<th>Parts</th>
									<th>Geog</th>
									<th>Spec Loc</th>
									<th>Collectors</th>
									<th>Date Coll</th>
								</tr>
							</thead>
							<tbody>
								<cfloop query="getItems" group="collection_object_id">
									<tr>
										<td>#getItems.collection# <a href="/guid/MCZ:#collection_cde#:#cat_num#" target="_blank">MCZ:#collection_cde#:#cat_num#</a></td>
										<td style="width: 200px;">#scientific_name#</td>
										<td>
											<a href="/Specimens.cfm?execute=true&action=fixedSearch&accn_trans_id=#transaction_id#" target="_top">#accnColln# #Accn_number#</a>
											#accn_type# #received_date#
										</td>
										<td>#getItems.parts#</td>
										<td>#getItems.collectors#</td>
										<td>#higher_geog#</td>
										<td>#spec_locality#</td>
										<td style="width:100px;">#verbatim_date#</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</div>
				</section>
			</main>
		
		</cfoutput>
	</cfcase>
			
	<!--------------------------------------------------------------------------------->
	<cfcase value="deaccessionItems">
		<cfif not isDefined("trans_id") or len(trans_id) EQ 0>
			<cfthrow message="No transaction_id specified,  Can't update specimens">
		</cfif>
		<cftransaction>
			<cftry>
				<cfquery name="countCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(distinct collection_object_id) ct
					FROM user_search_table
					WHERE
						result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				</cfquery>
				<cfif countCheck.ct EQ 0>
					<cfthrow message="No records to update identified by result_id=#encodeForHtml(result_id)#">
				</cfif>
				<cfquery name="getDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT deaccession.TRANSACTION_ID
					FROM deaccession
						LEFT JOIN trans on deaccession.TRANSACTION_ID=trans.TRANSACTION_ID
					WHERE
						deaccession.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_id#">
						and collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
				</cfquery>
				<cfif getDeacc.recordcount is 1>
					<cfset targetDeaccession = getDeacc.transaction_id>
					<cfquery name="getParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT specimen_part.collection_object_id 
						FROM user_search_table
							join specimen_part on user_search_table.collection_object_id = specimen_part.derived_from_cat_item
						WHERE
							result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
							AND
							specimen_part.collection_object_id NOT IN (
								SELECT collection_object_id 
								FROM deacc_item
							)
							-- TODO conditions for deaccessioning
					</cfquery>
					<cfset insertCounter = 0>
					<cfloop query="getParts">
						<cfquery name="addToDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addToDeacc_result">
							INSERT INTO deacc_item (
								transaction_id
								,collection_object_id
								<cfif isDefined("deacc_item_remarks") and len(deacc_item_remarks) GT 0>
									,deacc_item_remarks
								</cfif>
							) values ( 
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#targetDeaccession#">
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getParts.collection_object_id#">
								<cfif isDefined("deacc_item_remarks") and len(deacc_item_remarks) GT 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_item_remarks#">
								</cfif>
							)
						</cfquery>
						<cfset insertCounter = insertCounter + addToDeaccResult.recordcount>
					</cfloop>
					<cfif countCheck.ct LT insertCounter>
					<cfthrow message="Error: Query would update more rows (#insertCounter#) than there are in the result (#countCheck.ct#).">
					<cftransaction action="commit">
				</cfif>
			<cfelse>
				<cfthrow message="Deaccession [transaction id=#encodeForHtml(trans_id)#] in collection #encodeForHtml(collection_id)# was not found!">
			</cfif>
			<cfcatch>
				<cftransaction action="rollback">
				<cfdump var="#cfcatch#">
			</cfcatch>
			</cftry>
		</cftransaction>
		<cflocation url="/specimens/changeQueryAccession.cfm?result_id=#encodeForURL(result_id)#" addtoken="false">
	</cfcase>
</cfswitch>

<cfinclude template="/shared/_footer.cfm">
