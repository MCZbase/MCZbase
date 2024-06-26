<cfset pageTitle = "Change Accession for Search Result">
<cfinclude template="/shared/_header.cfm">

<cfif not isDefined("result_id") OR len(result_id) EQ 0>
	<cfthrow message = "No result_id provided for result set on which to change accession.">
</cfif>
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="entryPoint">
</cfif>

<cfquery name="ctcoll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select collection, collection_id from collection order by collection
</cfquery>

<!--------------------------------------------------------------------------------->
<cfswitch expression="#action#">
	<cfcase value="entryPoint">
		<cfquery name="getItemCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				count(cataloged_item.collection_object_id) ct
			FROM
				user_search_table 
				JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
			WHERE
				result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>
		<cfquery name="getAccns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				count(cataloged_item.collection_object_id) ct,
				accn.accn_number,
				accn_coll.collection,
				nvl(to_char(accn.received_date,'YYYY'),'[no date]')  year
			FROM
				user_search_table 
				JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id 
				JOIN accn on cataloged_item.accn_id = accn.transaction_id
				JOIN trans on accn.transaction_id = trans.transaction_id 
				JOIN collection accn_coll on trans.collection_id=accn_coll.collection_id
			WHERE
				result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			GROUP BY accn_number, accn_coll.collection, nvl(to_char(accn.received_date,'YYYY'),'[no date]')
			ORDER BY accn_number
		</cfquery>
		<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
				accn_coll.collection accnColln
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
			<script>
				var bc = new BroadcastChannel('resultset_channel');
				bc.onmessage = function (message) { 
					console.log(message);
					if (message.data.result_id == "#result_id#") { 
						messageDialog("Warning: You have removed one or more records from this result set, you must reload this page to see the current list of records this page affects.", "Result Set Changed Warning");
						$("##s_btn").prop("disabled",true);
						$("##s_btn").addClass("disabled");
					}  
				} 
			</script>
			<main class="container-fluid" id="content">
				<section class="row mx-0" aria-labelledby="formheading">
					<div class="col-12 pt-4">
						<h1 class="h3 px-1" id="formheading" >
							<cfif getItemCount.ct GT getItems.recordcount>
								Move all (#getItemCount.ct#) catloged items in this result (first #getItems.recordcount# are listed below) to accession:
							<cfelse>
								Move all the catloged items listed below (#getItems.recordcount#) to accession:
							</cfif>
						</h1>
						<form name="addItems" method="post" action="/specimens/changeQueryAccession.cfm">
							<input type="hidden" name="Action" value="addItems">
							<input type="hidden" name="result_id" value="#result_id#">
							<div class="form-row mb-2">
								<div class="col-12 col-md-4 col-lg-4 pb-2">
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
								<div class="col-12 col-md-4 col-lg-4">
									<label for="accn_number" class="data-entry-label mt-2 mt-md-0">Accession</label>
									<input type="text" name="accn_number" id="accn_number" class="data-entry-input reqdClr" required>
									<input type="hidden" name="trans_id" id="trans_id">
									<script>
										jQuery(document).ready(function() {
											makeAccessionAutocompleteLimitedMeta("accn_number", "trans_id","collection_id");
										});
									</script>
								</div>
								<div class="col-12 col-md-4 col-lg-4 mb-2 mb-md-0">
									<div class="data-entry-label">&nbsp;</div>
									<input type="submit" id="s_btn" value="Change Accession" class="btn btn-xs btn-warning">
								</div>
							</div>
						</form>
					</div>
				</section>
				<section class="row mx-0"> 
					<div class="col-12 pb-4">
						<div class="rounded redbox">
							<div class="card bg-light border-secondary mb-0 pb-1">
								<cfif getAccns.recordcount EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
								<div class="card-header h4">Currently in accession#plural#:</div>
								<div class="card-body">
									<ul class="list-group list-group-horizontal d-flex flex-wrap">
										<cfloop query="getAccns">
											<li class="list-group-item">#getAccns.collection# #getAccns.accn_number#&thinsp;:&thinsp;#getAccns.year# (#getAccns.ct#);</li>
										</cfloop>
									</ul>
								</div>
							</div>
						</div>
					</div>
				</section>
				<section class="row mx-0"> 
					<div class="col-12 pb-4">
						<table class="table table-responsive-md table-striped">
							<thead class="thead-light">
								<tr>
									<th>Cat Num</th>
									<th>Scientific Name</th>
									<th class="redbox">Accession</th>
									<th class="redbox">Date Received</th>
									<th>Collectors</th>
									<th>Geog</th>
									<th>Spec Loc</th>
									<th>Date Coll</th>
								</tr>
							</thead>
							<tbody>
								<cfloop query="getItems" group="collection_object_id">
									<tr>
										<td>#getItems.collection# <a href="/guid/MCZ:#collection_cde#:#cat_num#" target="_blank">MCZ:#collection_cde#:#cat_num#</a></td>
										<td style="width: 200px;">#scientific_name#</td>
										<td><a href="/SpecimenResults.cfm?Accn_trans_id=#transaction_id#" target="_top">#accnColln# #Accn_number#</a></td>
										<td>#accn_type# #received_date#</td>
										<td style="width: 200px;">#getItems.collectors#</td>
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
	<cfcase value="addItems">
		<cfif not isDefined("accn_number") or len(accn_number) EQ 0>
			<cfif not isDefined("trans_id") or len(trans_id) EQ 0>
				<cfthrow message="No Accession Number or transaction_id specified,  Can't update specimens">
			</cfif>
		</cfif>
		<cftransaction>
			<cfquery name="countCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT count(distinct collection_object_id) ct
				FROM user_search_table
				WHERE
					result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			</cfquery>
			<cfquery name="accn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT accn.TRANSACTION_ID
				FROM accn
					LEFT JOIN trans on accn.TRANSACTION_ID=trans.TRANSACTION_ID
				WHERE
					<cfif isDefined("trans_id") and len(trans_id) GT 0>
						accn.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_id#">
					<cfelse>
						accn_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#accn_number#">
					</cfif>
					and collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
			</cfquery>
			<cfif accn.recordcount is 1 and accn.transaction_id gt 0>
				<cfquery name="upAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upAccn_result">
					UPDATE cataloged_item 
					SET accn_id = #accn.transaction_id# 
					WHERE collection_object_id  in (
						SELECT collection_object_id 
						FROM user_search_table
						WHERE
							result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					)
				</cfquery>
				<cfif countCheck.ct GT upAccn_result.recordcount>
					<cfthrow message="Error: Query would update more rows (#upAccn_result.recordcount#) than there are in the result (#countCheck.ct#).">
				</cfif>
				<cftransaction action="commit">
			<cfelse>
				<cftransaction action="rollback">
				<cfthrow message="Accession [#encodeForHtml(accn_number)#] in collection #encodeForHtml(collection_id)# was not found!">
			</cfif>
		</cftransaction>
		
		<cflocation url="/specimens/changeQueryAccession.cfm?result_id=#encodeForURL(result_id)#" addtoken="false">
	</cfcase>

</cfswitch>

<cfinclude template="/shared/_footer.cfm">
