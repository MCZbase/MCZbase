<cfset pageTitle = "Change Collectors for Search Result">
<cfinclude template="/shared/_header.cfm">

<cfif not isDefined("result_id") OR len(result_id) EQ 0>
	<cfthrow message = "No result_id provided for result set on which to change collectors.">
</cfif>
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="entryPoint">
</cfif>
<cfif #Action# is "entryPoint">
<cfoutput> 
	<cfquery name="getColls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT 
		 	cataloged_item.collection_object_id as collection_object_id, 
			cataloged_item.cat_num,
			concatSingleOtherId(cataloged_item.collection_object_id,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#">) AS CustomID,
			identification.scientific_name,
			geog_auth_rec.country,
			geog_auth_rec.state_prov,
			geog_auth_rec.county,
			geog_auth_rec.quad,
			collection.collection_cde,
			CONCATPREP(cataloged_item.collection_object_id) preps,
			concatColl(cataloged_item.collection_object_id) colls
		FROM 
			user_search_table
			LEFT JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
			LEFT JOIN identification on cataloged_item.collection_object_id = identification.collection_object_id 
			LEFT JOIN collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id 
			LEFT JOIN locality on collecting_event.locality_id = locality.locality_id 
			LEFT JOIN geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id 
			LEFT JOIN collection on cataloged_item.collection_id = collection.collection_id
		WHERE 
			result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			and accepted_id_fg=1
		ORDER BY 
			cataloged_item.collection_object_id
	</cfquery>
	<main class="container" id="content">
		<section class="row" >
			<h2 class="h3">
				Add/Remove collectors for all specimens listed below
			</h2>
			<p>Pick an agent, a role, and an order to insert or delete an agent for all records listed below. </p>
			<p>Order is ignored for deletion.</p>
  			<form name="tweakColls" method="post" action="/specimens/changeQueryCollectors.cfm">
				<input type="hidden" name="result_id" value="#result_id#">
				<input type="hidden" name="action" value="">
				<label for="name">Name</label>
				<input type="text" name="name" class="reqdClr" 
					onchange="getAgent('agent_id','name','tweakColls',this.value); return false;"
				 	onKeyPress="return noenter(event);">
				<input type="hidden" name="agent_id">
				<label for="collector_role">Role</label>		
		      <select name="collector_role" size="1"  class="reqdClr">
					<option value="c">collector</option>
					<option value="p">preparator</option>
				</select>
				<label for="coll_order">Order</label>
				<select name="coll_order" size="1" class="reqdClr">
					<option value="first">First</option>
					<option value="last">Last</option>
				</select>
				<input type="button" 
					value="Insert Agent" 
					class="btn btn-xs btn-primary"
   				onclick="tweakColls.action.value='insertColl';submit();">
				<input type="button" 
					value="Remove Agent" 
					class="btn btn-xs btn-warning"
   				onclick="tweakColls.action.value='deleteColl';submit();">
			</form>
			<h3 class="h4">Specimens:</h3>
			<table border="1">
				<tr>
					<th>Catalog Number</th>
					<th>#session.CustomOtherIdentifier#</th>
					<th>Accepted Scientific Name</th>
					<th>Collectors</th>
					<th>Preparators</th>
					<th>Country</th>
					<th>State</th>
					<th>County</th>
					<th>Quad</th>
				</tr>
				<cfloop query="getColls">
    				<tr>
						<td>MCZ:#collection_cde#:#cat_num#</td>
						<td>#CustomID#&nbsp;</td>
						<td><i>#Scientific_Name#</i></td>
						<td>#colls#</td>
						<td>#preps#</td>
						<td>#Country#&nbsp;</td>
						<td>#State_Prov#&nbsp;</td>
						<td>#county#&nbsp;</td>
						<td>#quad#&nbsp;</td>
					</tr>
				</cfloop>
			</table>
		</section>
	</main>
</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfif action is "insertColl">
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
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#max.m#">
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
							collector_role='p'
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
</cfif>
<!----------------------------------------------------------------------------------->
<cfif #Action# is "deleteColl">
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
							coll_order > <cfqueryparam cfsqltype="CF_SQL_dECIMAL" value="#max.coll_order#">
					</cfquery>
				</cfif>
			</cfloop>
		</cftransaction>
		<cflocation url="/specimens/changeQueryCollectors.cfm?result_id=#result_id#">
	</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfinclude template="/shared/_footer.cfm">
