<cfset pageTitle = "Change Collectors in Search Result">
<cfinclude template="/shared/_header.cfm">

<cfif not isDefined("result_id") OR len(result_id) EQ 0>
	<cfthrow message = "No result_id provided for result set on which to change collectors.">
</cfif>
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="entryPoint">
</cfif>
<cfswitch expression="#action#">
	<cfcase value="entryPoint">
		<cfoutput> 
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
				 	cataloged_item.collection_object_id as collection_object_id, 
					cataloged_item.collection_cde,
					cataloged_item.cat_num,
					concatSingleOtherId(cataloged_item.collection_object_id,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#">) AS CustomID,
					MCZBASE.GET_SCIENTIFIC_NAME_AUTHS(cataloged_item.collection_object_id) scientific_name,
					geog_auth_rec.country,
					geog_auth_rec.state_prov,
					geog_auth_rec.county,
					geog_auth_rec.quad,
					CONCATPREP(cataloged_item.collection_object_id) preps,
					concatColl(cataloged_item.collection_object_id) colls
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
				ORDER BY 
					cataloged_item.collection_object_id
			</cfquery>
			<cfquery name="getCollectors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					count(user_search_table.collection_object_id) ct,
					collector.agent_id,
					MCZBASE.GET_AGENTNAMEOFTYPE(collector.agent_id) collector
				FROM	
					user_search_table 
					JOIN collector on user_search_table.collection_object_id = collector.collection_object_id
				WHERE 
					result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					AND collector.collector_role = 'c'
				GROUP BY
					collector.agent_id
				ORDER BY 
					MCZBASE.GET_AGENTNAMEOFTYPE(collector.agent_id)
			</cfquery>
			<cfquery name="getPreparators" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					count(user_search_table.collection_object_id) ct,
					collector.agent_id,
					MCZBASE.GET_AGENTNAMEOFTYPE(collector.agent_id) preparator
				FROM	
					user_search_table 
					JOIN collector on user_search_table.collection_object_id = collector.collection_object_id
				WHERE 
					result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					AND collector.collector_role = 'p'
				GROUP BY
					collector.agent_id
				ORDER BY 
					MCZBASE.GET_AGENTNAMEOFTYPE(collector.agent_id)
			</cfquery>
			<main class="container-fluid" id="content">
				<section class="row mx-0" aria-labelledby="formheading">
					<div class="col-12 pt-3">
						<h1 class="h3 px-1" id="formheading" >
							<cfif getItemCount.ct GT getItems.recordcount>
								Add/Remove collectors for all (#getItemCount.ct#) cataloged items in this result (first #getItems.recordcount# are listed below)
							<cfelse>
								Add/Remove collectors for all (#getItems.recordcount#) cataloged items listed below
							</cfif>
						</h1>
						<div class="px-1">
							Pick an agent, a role, and an order (ignored for delete) to insert or delete an agent for all records listed below. 
						</div>
						<div class="py-2">
				  			<form name="tweakColls" method="post" action="/specimens/changeQueryCollectors.cfm">
								<input type="hidden" name="result_id" value="#result_id#">
								<input type="hidden" name="action" value="">
								<div class="form-row mb-2">
									<div class="col-12 col-md-4 col-lg-3">
										<span class="d-block" style="margin-top:-2px;">
											<label for="name" class="data-entry-label w-auto d-inline">Agent Name</label>
											<span id="agent_view" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</span>
										</span>
										<div class="input-group">
											<div class="input-group-prepend">
												<span class="input-group-text smaller" id="agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
											</div>
											<input name="name" id="name" class="reqdClr form-control form-control-sm data-entry-input rounded-right" value="" aria-label="Agent to use as the collector or preparator." required >
											<input type="hidden" name="agent_id" id="agent_id" value="" >
										</div>
										<script>
											$(document).ready(function() {
												$(makeRichAgentPicker('name', 'agent_id', 'agent_name_icon', 'agent_view', ''));
											});
										</script>
									</div>
									<div class="col-12 col-md-4 col-lg-3">
										<label for="collector_role" class="data-entry-label mt-2 mt-md-0">Role</label>		
										<select name="collector_role" id="collector_role" size="1"  class="reqdClr data-entry-select" required>
											<option value="c">collector</option>
											<option value="p">preparator</option>
										</select>
									</div>
									<div class="col-12 col-md-4 col-lg-3">
										<label for="coll_order" class="data-entry-label mt-2 mt-md-0">Order</label>
										<select name="coll_order" id="coll_order" size="1" class="data-entry-select">
											<option value="first" selected >First</option>
											<option value="last">Last</option>
										</select>
									</div>
									<div class="col-12 col-md-4 col-lg-3 mt-md-0 mt-3">
										<label for="insert_button" class="data-entry-label">Apply to all records in result.</label>		
										<input type="button" id="insert_button"
											value="Insert Agent" 
											class="btn btn-xs btn-primary"
		   								onclick="tweakColls.action.value='insertColl';submit();">
										<input type="button" 
											value="Remove Agent" 
											class="btn btn-xs btn-warning"
		   								onclick="tweakColls.action.value='deleteColl';submit();">
									</div>
								</div>
							</form>
						</div>
					</div>
				</section>
				<section class="row mx-0"> 
					<div class="col-12 pb-4">
						<div class="rounded redbox">
							<div class="card bg-light border-secondary mb-3 pb-1">
								<cfif getCollectors.recordcount EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
								<div class="card-header h4">Current collector#plural#:</div>
								<div class="card-body">
									<ul class="list-group list-group-horizontal d-flex flex-wrap">
										<cfloop query="getCollectors">
											<li class="list-group-item"><a href="/agents/Agent.cfm?agent_id=#getCollectors.agent_id#" target="_blank">#getCollectors.collector#</a> (#getCollectors.ct#);</li>
										</cfloop>
									</ul>
								</div>
							</div>
							<div class="card bg-light border-secondary mb-0 pb-1">
								<cfif getPreparators.recordcount EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
								<div class="card-header h4">Current preparator#plural#:</div>
								<div class="card-body">
									<ul class="list-group list-group-horizontal d-flex flex-wrap">
										<cfloop query="getPreparators">
											<li class="list-group-item"><a href="/agents/Agent.cfm?agent_id=#getPreparators.agent_id#" target="_blank">#getPreparators.preparator#</a> (#getPreparators.ct#);</li>
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
									<th>Catalog Number</th>
									<cfif len(session.CustomOtherIdentifier)gt 0><th>#session.CustomOtherIdentifier#</th></cfif>
									<th>Accepted Scientific Name</th>
									<th class="redbox py-1">Collectors</th>
									<th class="redbox py-1">Preparators</th>
									<th>Country</th>
									<th>State</th>
									<th>County</th>
									<th>Quad</th>
								</tr>
							</thead>
							<tbody>
							<cfloop query="getItems">
								<tr>
									<td><a href="/guid/MCZ:#collection_cde#:#cat_num#" target="_blank">MCZ:#collection_cde#:#cat_num#</a></td>
									<cfif len(session.CustomOtherIdentifier)gt 0><td>#CustomID#&nbsp;</td></cfif>
									<td><i>#Scientific_Name#</i></td>
									<td>#colls#</td>
									<td>#preps#</td>
									<td>#Country#&nbsp;</td>
									<td>#State_Prov#&nbsp;</td>
									<td>#county#&nbsp;</td>
									<td>#quad#&nbsp;</td>
								</tr>
							</cfloop>
							</tbody>
						</table>
					</div>
				</section>
			</main>
		</cfoutput>
	</cfcase>
	<!----------------------------------------------------------------------------------->
	<cfcase value="insertColl">
		<cfif NOT isDefined("agent_id") OR len(agent_id) EQ 0>
			<cfthrow message = "No agent_id provided for collector/preparator to change.  Agent was not selected.">
		</cfif>
		<cfoutput>
			<cftransaction>
				<cfquery name="getObjects" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT collection_object_id FROM user_search_table
					WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				</cfquery>
				<cfif coll_order is "first" and collector_role is 'c'>
					<!--- increment existing collector order by 1 --->
					<cfquery name="bumpAll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update 
							collector 
						set 
							coll_order=coll_order + 1 
						where
							collector_role='c' and
							collection_object_id IN (
								SELECT collection_object_id FROM user_search_table
								WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
							)
					</cfquery>
					<!--- insert collectors at position 1 --->
					<cfloop query="getObjects">
						<cfquery name="insOne" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into collector (
								collection_object_id,
								agent_id,
								collector_role,
								coll_order
							) values (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getObjects.collection_object_id#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">,
								'c',
								1
							)
						</cfquery>				
					</cfloop>
				<cfelseif coll_order is "last" and collector_role is 'c'>
					<cfloop query="getObjects">
						<!--- find highest numbered collector for this cataloged item--->
						<cfquery name="max" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT max(coll_order) +1 m 
							FROM collector 
							WHERE
								collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getObjects.collection_object_id#">
								and collector_role='c'
						</cfquery>
						<cfif max.recordcount EQ 0 or max.m EQ ''>
							<cfset newM = 1>
						<cfelse>
							<cfset newM = max.m>
						</cfif>
						<!--- insert collector in next position --->
						<cfquery name="insOne" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into collector (
								collection_object_id,
								agent_id,
								collector_role,
								coll_order
							) values (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getObjects.collection_object_id#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">,
								'c',
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newM#">
							)
						</cfquery>
					</cfloop>
				<cfelseif coll_order is "first" and collector_role is 'p'>
					<!--- increment existing preparator order by 1 --->
					<cfquery name="bumpAll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update 
							collector 
						set 
							coll_order=coll_order + 1 
						where
							collector_role='p' and
							collection_object_id IN (
								SELECT collection_object_id FROM user_search_table
								WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
							)
					</cfquery>			
					<cfloop query="getObjects">
						<cfquery name="max" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT max(coll_order) +1 m 
							FROM collector 
							WHERE
								collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getObjects.collection_object_id#">
								and collector_role='p'
						</cfquery>
						<cfif max.recordcount EQ 0 or max.m EQ ''>
							<cfset newM = 1>
						<cfelse>
							<cfset newM = max.m>
						</cfif>
						<cfquery name="insOne" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into collector (
								collection_object_id,
								agent_id,
								collector_role,
								coll_order
							) values (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getObjects.collection_object_id#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">,
								'p',
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newM#">
							)
						</cfquery>
					</cfloop>
				<cfelseif coll_order is "last" and collector_role is 'p'>
					<cfloop query="getObjects">
						<cfquery name="max" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT max(coll_order) +1 m 
							FROM collector
							WHERE 
								collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getObjects.collection_object_id#">
						</cfquery>
						<cfquery name="insOne" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into collector (
								collection_object_id,
								agent_id,
								collector_role,
								coll_order
							) values (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getObjects.collection_object_id#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">,
								'p',
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#max.m#">
							)
						</cfquery>
					</cfloop>				
				</cfif>
			</cftransaction>
			<cflocation url="/specimens/changeQueryCollectors.cfm?result_id=#result_id#">
		</cfoutput>
	</cfcase>
	<!----------------------------------------------------------------------------------->
	<cfcase value="deleteColl">
		<cfif NOT isDefined("agent_id") OR len(agent_id) EQ 0>
			<cfthrow message = "No agent_id provided for collector/preparator to remove.   Agent was not selected.">
		</cfif>
		<cfoutput>
			<cftransaction>
				<cfquery name="getObjects" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT collection_object_id FROM user_search_table
					WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				</cfquery>
				<cfloop query="getObjects">
					<!--- find the coll_order position for the collector/preparator to be removed, positions above this will be decremented --->
					<cfquery name="max" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select 
							collection_object_id,
							coll_order 
						from 
							collector 
						where 
							collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getObjects.collection_object_id#"> and
							agent_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#"> and
							collector_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collector_role#">
					</cfquery>
					<cfif max.collection_object_id gt 0>
						<!--- remove the collector/preparator --->
						<cfquery name="remove" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							delete from 
								collector 
							where
								collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getObjects.collection_object_id#"> and
								agent_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#"> and
								collector_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collector_role#">
						</cfquery>
						<!--- decrement the coll_order for collectors above the removed collector in order --->
						<cfquery name="decrement" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update 
								collector 
							set
								coll_order=coll_order -1
							where	 
								collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getObjects.collection_object_id#"> and
								coll_order > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#max.coll_order#">
						</cfquery>
					</cfif>
				</cfloop>
			</cftransaction>
			<cflocation url="/specimens/changeQueryCollectors.cfm?result_id=#result_id#">
		</cfoutput>
	</cfcase>
</cfswitch>
<!----------------------------------------------------------------------------------->
<cfinclude template="/shared/_footer.cfm">
