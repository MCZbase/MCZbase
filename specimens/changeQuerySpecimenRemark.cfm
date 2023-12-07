<cfset pageTitle = "Append specimen remarks for Search Result">
<cfinclude template="/shared/_header.cfm">

<cfif not isDefined("result_id") OR len(result_id) EQ 0>
	<cfthrow message = "No result_id provided for result set on which to add remarks.">
</cfif>
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="entryPoint">
</cfif>

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
		<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				cataloged_item.collection_object_id,
				cataloged_item.collection_cde,
				cataloged_item.cat_num,
				MCZBASE.GET_COLLECTORSTYPEDNAME(cataloged_item.collection_object_id) collectors,
				geog_auth_rec.higher_geog,
				locality.spec_locality,
				collecting_event.verbatim_date,
				MCZBASE.GET_SCIENTIFIC_NAME_AUTHS(cataloged_item.collection_object_id) scientific_name,
				collection.institution_acronym,
				collection.collection
			FROM
				user_search_table 
				JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id 
				JOIN collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
				JOIN locality on collecting_event.locality_id = locality.locality_id
				JOIN geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
				JOIN collection on cataloged_item.collection_id = collection.collection_id
			WHERE
				result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				and rownum < 1001
			ORDER BY cataloged_item.collection_cde, cataloged_item.cat_num
		</cfquery>
		<cfoutput>
			<main class="container-fluid" id="content">
				<section class="row mx-0" aria-labelledby="formheading">
					<div class="col-12 pt-4">
						<h1 class="h3 px-1" id="formheading" >
							Append a specimen remark to the (#getItems.recordcount#) cataloged items listed below:
						</h1>
						<form name="addRemark" method="post" action="/specimens/changeQuerySpecimenRemark.cfm">
							<input type="hidden" name="Action" value="addRemark">
							<input type="hidden" name="result_id" value="#result_id#">
							<div class="form-row mb-2">
								<div class="col-12 pb-2">
									<label for="remark" class="data-entry-label">Text to append to remarks.  (<span id="length_remark">0 characters, 4000 left</span>) </label>
									<textarea name="remark" id="remark" 
										onkeyup="countCharsLeft('remark', 4000, 'length_remark');"
										class="form-control form-control-sm w-100 autogrow mb-1 reqdClr" rows="2"></textarea>
									<script>
										$(document).ready(function() { 
											$("##remark").keyup(autogrow);  
										});
									</script>
								</div>
								<div class="col-12 col-md-4 col-lg-4 mb-2 mb-md-0">
									<div class="data-entry-label">&nbsp;</div>
									<input type="submit" id="s_btn" value="Append Remark" class="btn btn-xs btn-warning">
								</div>
							</div>
						</form>
					</div>
				</section>
				<section class="row mx-0"> 
					<div class="col-12 pb-4">
						<table class="table table-responsive table-striped d-xl-table">
							<thead class="thead-light">
								<tr>
									<th>Cat Num</th>
									<th>Scientific Name</th>
									<th class="redbox">Remarks</th>
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
										<cfset remarks = "">
										<cfquery name="object_rem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											SELECT
												coll_object_remark.coll_object_remarks
											FROM
												cataloged_item
												left join coll_object_remark on cataloged_item.collection_object_id = coll_object_remark.collection_object_id
											WHERE
												cataloged_item.collection_object_id = <cfqueryparam value="#getItems.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
												and coll_object_remarks is not null
										</cfquery>
										<cfif object_rem.recordcount GT 0>
											<cfset remarks = "<ul>"><!--- " --->
											<cfloop query="object_rem">
												<cfset remarks="#remarks#<li>#object_rem.coll_object_remarks#">
											</cfloop>
											<cfset remarks="#remarks#</ul>"><!--- " --->
										</cfif>
										<td>#remarks#</td>
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
	<cfcase value="addRemark">
		<cfif not isDefined("remark") or len(remark) EQ 0>
			<cfthrow message="No Remark specified, no update to make to specimens">
		</cfif>
		<!---
		   @param multiplicity, if one, use one coll_object_remarks to one coll_object, current required default
         to support old edit cataloged item page, appending remarks to the current text of 
			coll_object_remark.coll_object_remarks.
			If many, then support one to many coll_object_remarks to one collection_object
         and write the remark into a new coll_object_remarks record.
		--->
		<cfif not isDefined("multiplicity") or len(multiplicity) EQ 0>
			<cfset multiplicity = "one">
		</cfif>
		<cftransaction>
			<cfquery name="getRecords" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getRecords_result">
				SELECT user_search_table.collection_object_id, guid 
				FROM user_search_table
					left join FLAT on user_search_table.collection_object_id = flat.collection_object_id
				WHERE
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			</cfquery>
			<cfloop query="getRecords">
				<cfif multiplicity EQ "many">
					<cfquery name="countDuplicates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT
							count(*) ct
						FROM
							coll_object_remark 
						WHERE
							collection_object_id = <cfqueryparam value="#getRecords.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
							and coll_object_remarks = <cfqueryparam value="#remark#" cfsqltype="CF_SQL_VARCHAR">
					</cfquery>
					<cfif countDuplicates.ct EQ 0> 
						<cfquery name="addRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addRemark_result">
							INSERT INTO coll_object_remark
							(
								coll_object_remarks,
								collection_object_id 
							) values (
								<cfqueryparam value="#remark#" cfsqltype="CF_SQL_VARCHAR">,
								<cfqueryparam value="#getRecords.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
							)
						</cfquery>
					</cfif>
				<cfelse>
					<cfquery name="countDuplicates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT
							count(*) ct
						FROM
							coll_object_remark 
						WHERE
							collection_object_id = <cfqueryparam value="#getRecords.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
							and coll_object_remarks like <cfqueryparam value="%#remark#%" cfsqltype="CF_SQL_VARCHAR">
					</cfquery>
					<cfif countDuplicates.ct EQ 0> 
						<cfquery name="remarksExist" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT count(*) ct
							FROM coll_object_remark 
							WHERE
								collection_object_id = <cfqueryparam value="#getRecords.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						</cfquery>
						<cfif remarksExist.ct EQ 0>
							<!--- no coll_object_remark record, insert one. --->
							<cfquery name="addRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addRemark_result">
								INSERT INTO coll_object_remark
								(
									coll_object_remarks,
									collection_object_id 
								) values (
									<cfqueryparam value="#remark#" cfsqltype="CF_SQL_VARCHAR">,
									<cfqueryparam value="#getRecords.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								)
							</cfquery>
						<cfelseif remarksExist.ct EQ 1>
							<!--- one coll_object_remark record exists, append remark text  --->
							<cfquery name="checkLength" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT coll_object_remarks
								FROM coll_object_remark 
								WHERE
									collection_object_id = <cfqueryparam value="#getRecords.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
							</cfquery>
							<cfif len(checkLength.coll_object_remarks) + len(remark) GT 4000>
								<cfthrow message="Unable to append, length of collection object remarks would exceed 4000 for #guid# collection_object_id=[#getRecords.collection_object_id#]">
							</cfif>
							<cfif len(checkLength.coll_object_remarks) EQ 0>
								<cfquery name="doUpdate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									UPDATE
										coll_object_remark 
									SET 
										coll_object_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remark#">
									WHERE
										collection_object_id = <cfqueryparam value="#getRecords.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								</cfquery>
							<cfelse>
								<cfquery name="doUpdate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									UPDATE
										coll_object_remark 
									SET 
										coll_object_remarks = coll_object_remarks || ' | ' || <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remark#">
									WHERE
										collection_object_id = <cfqueryparam value="#getRecords.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								</cfquery>
							</cfif>
						<cfelse>
							<cfthrow message="Error: More than one coll_object_remark record exists for #guid# collection_object_id=[#getRecords.collection_object_id#] contact a database administrator. ">
						</cfif>
					</cfif>					
				</cfif>
			</cfloop>
			<cftransaction action="commit">
		</cftransaction>
		
		<cflocation url="/specimens/changeQuerySpecimenRemark.cfm?result_id=#encodeForURL(result_id)#" addtoken="false">
	</cfcase>

</cfswitch>

<cfinclude template="/shared/_footer.cfm">
