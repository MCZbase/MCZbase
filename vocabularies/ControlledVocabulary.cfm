<cfoutput>
<cfset pageTitle = "MCZbase Controlled Vocabularies">
<cfinclude template="/shared/_header.cfm">
<cfif not isdefined("table") OR len(table) EQ 0>
	<div class="container my-3">
		<div class="row">
			<div class="col-12">
				<h2>MCZbase controlled vocabulary tables</h2>
					<cfquery name="getCTName" datasource="uam_god">
						SELECT
							distinct(table_name) table_name
						FROM
							sys.dba_tables
						WHERE
							table_name like 'CT%'
							and owner = 'MCZBASE'
						UNION 
							select 'CTGEOLOGY_ATTRIBUTE_HIERARCHY' table_name from dual
						UNION
							select 'ORIG_LAT_LONG_UNITS' table_name from dual
						ORDER BY table_name
					</cfquery>
				<ul>
			<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
				<li><a href="/vocabularies/CollEventNumberSeries.cfm">Collecting Event Number Series</a></li>
			</cfif>
			<cfloop query="getCTName">
				<cfquery name="getCTRows" datasource="uam_god">
					select count(*) as ct 
					FROM 
						<cfif getCtName.table_name EQ "CTGEOLOGY_ATTRIBUTE_HIERARCHY">
							GEOLOGY_ATTRIBUTE_HIERARCHY
						<cfelseif getCtName.table_name EQ "ORIG_LAT_LONG_UNITS">
							(select ORIG_LAT_LONG_UNITS from ctlat_long_units)
						<cfelse>
							#getCtName.table_name#
						</cfif>
				</cfquery>
				<cfif getCTRows.ct GT 0>
					<cfset name = REReplace(getCtName.table_name,"^CT","") ><!--- strip CT from names in list for better readability --->
					<li><a href="/vocabularies/ControlledVocabulary.cfm?table=#getCTName.table_name#">#name#</a> (#getCTRows.ct# values)</li>
				</cfif>
				
			</cfloop>
		</ul>
			</div>
		</div>
	</div>
<cfelse>
	<cfif table is "CTGEOLOGY_ATTRIBUTE_HIERARCHY"><!---------------------------------------------------->
		<cflocation url="/vocabularies/showGeologicalHierarchies.cfm" addtoken="false">		
	</cfif>
	<cfif refind('^CT[A-Z_]+$',ucase(table)) EQ 0>
		<cfthrow message="This page can only be used for viewing the controlled vocabularies in code tables.">
	</cfif>

	<cfset tableName = right(table,len(table)-2)>
	
	<cfif not isdefined("field")>
		<!--- controlled vocabualry value to highlight --->
		<cfset field="">
	</cfif>
	
	<cfquery name="confirm" datasource="uam_god">
		SELECT
			table_name found_table
		FROM
			sys.dba_tables
		WHERE
			table_name like 'CT%'
			and table_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#table#">
			and  owner = 'MCZBASE'
		UNION
			select 'ORIG_LAT_LONG_UNITS' table_name from dual
	</cfquery>
	<cfif getCtName.table_name EQ "ORIG_LAT_LONG_UNITS">
		<cfquery name="getLLUnits" datasource="uam_god">
			select orig_lat_long_units  from ctlat_long_units order by orig_lat_long_units desc
		</cfquery>
		<cfloop query="getLLUnits">
			<ul>
				<li>#getLLUnits.orig_lat_long_units# </li>
			</ul>
		</cfloop>
	</cfif>
	<cfif confirm.recordcount NEQ 1>
		<cfthrow message="Unknown controlled vocabulary table">
	</cfif>
	<cfquery name="docs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from #confirm.found_table#
	</cfquery>
	
	<div class="container my-3">
		<div class="row">
			<div class="col-12">
			<h3>Documentation for code table <strong>#tableName#</strong>:</h3>
			<cfif table is "ctmedia_license">
			<table class="table table-responsive table-striped d-lg-table">
				<thead class="thead-light">
				<tr>
					<th>
						media_license_id
					</th>
					<th>
						License
					</th>
					<th>Description</td>
					<th>
						URI
					</th>
				</tr>
				</thead>
				<tbody>
				<cfloop query="docs">
					<tr>
						<td>#media_license_id#</td>
						<td>#display#</td>
						<td>#description#</td>
						<td><a href="#uri#" target="_blank" class="external">#uri#</a></td>
					</tr>
				</cfloop>
				</tbody>
			</table>
		<cfelseif table is "ctguid_type">
			<table class="table table-responsive table-striped d-xl-table">
				<thead class="thead-light">
				<tr>
					<th>
						GUID Type
					</th>
					<th>
						Applies To
					</th>
					<th>
						Description
					</th>
					<th>
						Placeholder
					</th>
					<th>
						Search URI
					</th>
				</tr>
				</thead>
				<tbody>
				<cfloop query="docs">
					<tr>
						<td>#guid_type#</td>
						<td>#applies_to#</td>
						<td>#description#</td>
						<td>#placeholder#</td>
						<td>#search_uri#</td>
					</tr>
				</cfloop>
				</tbody>
			</table>
		<cfelseif table is "ctunderscore_coll_agent_role">
			<table class="table table-responsive table-striped d-xl-table">
				<thead class="thead-light">
				<tr>
					<th>
						Role
					</th>
					<th>
						Description
					</th>
					<th>
						Label (group label agent)
					</th>
					<th>
						Inverse Label (agent label group)
					</th>
					<th>
						Display order
					</th>
				</tr>
				</thead>
				<tbody>
				<cfloop query="docs">
					<tr>
						<td>#role#</td>
						<td>#description#</td>
						<td>#label#</td>
						<td>#inverse_label#</td>
						<td>#ordinal#</td>
					</tr>
				</cfloop>
				</tbody>
			</table>
		<cfelseif table is "ctspecific_permit_type">
			<table class="table table-responsive table-striped d-lg-table">
				<thead class="thead-light">
				<tr>
					<th>
						Specific Type
					</th>
					<th>
						Permit Type
					</th>
					<th>
						Inherit to Shipments
					</th>
				</tr>
				</thead>
				<tbody>
				<cfloop query="docs">
					<tr>
						<td>#specific_type#</td>
						<td>#permit_type#</td>
						<td>#accn_show_on_shipment#</td>
					</tr>
				</cfloop>
				</tbody>
			</table>
		<cfelseif table is "ctlat_long_units">
			<table class="table table-responsive table-striped d-lg-table">
				<thead class="thead-light">
				<tr>
					<th>
						Orig Lat Long Units
					</th>
				</tr>
				</thead>
				<tbody>
				<cfloop query="docs">
					<tr>
						<td>#orig_lat_long_units#</td>
					</tr>
				</cfloop>
				</tbody>
			</table>
		<cfelseif table is "cttrans_agent_role">
			<table class="table table-responsive table-striped d-lg-table">
				<thead class="thead-light">
				<tr>
					<th>
						TRANS_AGENT_ROLE
					</th>
					<th>
						Description
					</th>
					<th>
						Transactions
					</th>
				</tr>
				</thead>
				<tbody>
				<cfloop query="docs">
					<tr>
						<td>#trans_agent_role#</td>
						<td>#description#</td>
						<cfquery name="getallowed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT transaction_type, required_to_print 
							FROM trans_agent_role_allowed
							WHERE trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role#">
							ORDER BY transaction_type
						</cfquery>
						<cfset transactions="">
						<cfset separator = "">
						<cfloop query="getallowed">
							<cfset transactions="#transactions##separator##getallowed.transaction_type#">
							<cfif getallowed.required_to_print EQ 1>
								<cfset transactions="#transactions#(Required)">
							</cfif>
							<cfset separator = "; ">
						</cfloop>
						<td>#transactions#</td>
					</tr>
				</cfloop>
				</tbody>
			</table>
		<cfelse>

			<cfset theColumnName = "">
			<cfif ListContainsNoCase(docs.columnList,tableName)>
				<!--- expected form of code tables ct{name} has field {name}.  Applies in most cases --->
				<cfset theColumnName = tableName>
			<cfelse>
				<cfloop list="#docs.columnlist#" index="colName">
					<cfif #colName# is not "COLLECTION_CDE" and #colName# is not "DESCRIPTION">
						<cfif ucase(tableName) EQ ucase(colName)>
							<cfset theColumnName = #colName#>
						</cfif>
					</cfif>
				</cfloop>
			</cfif>
			<!--- Special case handling for reserved words --->
			<cfif ucase(tableName) EQ "CLASS"><cfset theColumnName = "phylclass"></cfif>
			
			<cfif len(field) GT 0>
				<!---- check if the value provided in field for theColumnName is valid ---->
				<cfquery name="chosenOne" dbtype="query">
					select * from docs where #theColumnName# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#field#">
					<cfif #docs.columnlist# contains "collection_cde">
						order by collection_cde
					</cfif>
				</cfquery>
		
				<cfif chosenOne.RecordCount EQ 0>
					<h3>Warning: #field# is not a valid value for tableName</h3>
				</cfif>
			</cfif>

			<cfquery name="orderedDocs" dbtype="query">
				select * from docs 
				<cfif #docs.columnlist# contains "collection_cde" AND #len(theColumnName)# EQ 0 >
					order by collection_cde
				<cfelseif #docs.columnlist# contains "collection_cde" AND #len(theColumnName)# GT 0 >
					order by collection_cde, #theColumnName#
				<cfelseif #len(theColumnName)# GT 0 >
					order by #theColumnName#
				</cfif>
			</cfquery>
			
			<!--- If table constains description column, place it last --->
			<cfif listFind(orderedDocs.columnlist,"DESCRIPTION") GT 0>
				<cfset columnList = listDeleteAt(orderedDocs.columnlist,listFind(orderedDocs.columnlist,"DESCRIPTION"))>
				<cfset columnList = listAppend(columnList,"Description")>
			<cfelse>
				<cfset columnList = orderedDocs.columnlist>
			</cfif>
			<!--- place the code value field first --->
			<cfif listFind(columnList,ucase(theColumnName)) GT 1>
				<cfset columnList = listDeleteAt(columnList,listFind(columnList,ucase(theColumnName)))>
				<cfset columnList = listPrepend(columnList,ucase(thecolumnName))>
			</cfif>
			<cfset columnArr = ListToArray(columnList)>

			<table class="table table-responsive table-striped d-lg-table">
				<thead class="thead-light">
				<tr>
					<cfloop array="#columnArr#" index="colName">
						<th>
							#colName#
						</th>
					</cfloop>
					<cfif NOT #columnList# contains "collection_cde">
						<th>
							Collection
						</th>
					</cfif>
				</tr>
				</thead>
				<tbody>
				<cfset i=1>
				<cfloop query="orderedDocs">
					<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
						<cfloop array="#columnArr#" index="colName">
							<cfif orderedDocs[colName][currentrow] EQ field>
								<td><span aria-label="highlighted value you searched for"><strong>#orderedDocs[colName][currentrow]#</strong></span></td>
							<cfelse>
								<td>#orderedDocs[colName][currentrow]#</td>
							</cfif>
						</cfloop>
						<cfif NOT #columnList# contains "collection_cde">
							<td>All</td>
						</cfif>
					</tr>
				</cfloop>
					</tbody>
			</table>
		</cfif>
			</div>
		</div>
	</div>
	
</cfif>
<cfinclude template="/shared/_footer.cfm">
</cfoutput>
