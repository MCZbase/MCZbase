<cfoutput>
<cfset pageTitle = "MCZbase Controlled Vocabularies">
<cfinclude template="/shared/_header.cfm">
<cfif not isdefined("table") OR len(table) EQ 0>
	<div class="container my-3">
	   <h2>MCZbase controlled vocabulary tables</h2>
   	<cfquery name="getCTName" datasource="uam_god">
      	select
         	distinct(table_name) table_name
	      from
   	      sys.user_tables
      	where
	         table_name like 'CT%'
   	    order by table_name
	   </cfquery>
		<ul>
			<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
				<li><a href="/vocabularies/CollEventNumberSeries.cfm">Collecting Event Number Series</a></li>
			</cfif>
		   <cfloop query="getCTName">
   			<cfquery name="getCTRows" datasource="uam_god">
					select count(*) as ct from #getCtName.table_name#
				</cfquery>
				<cfif getCTRows.ct GT 0>
					<cfset name = REReplace(getCtName.table_name,"^CT","") ><!--- strip CT from names in list for better readability --->
   	   		<li><a href="/vocabularies/ControlledVocabulary.cfm?table=#getCTName.table_name#">#name#</a> (#getCTRows.ct# values)</li>
				</cfif>
		   </cfloop>
		</ul>
	</div>
<cfelse>
	<cfif refind('^CT[A-Z_]+$',ucase(table)) EQ 0>
   	<cfthrow message="This page can only be used for viewing the controled vocabularies in code tables.">
	</cfif>

	<cfset tableName = right(table,len(table)-2)>
	
	<cfif not isdefined("field")>
		<!--- controlled vocabualry value to highlight --->
		<cfset field="">
	</cfif>
	
	<cfquery name="docs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from #table#
	</cfquery>
	
	<div class="container my-3">
		<h3>Documentation for code table <strong>#tableName#</strong>:</h3>

		<cfif table is "ctmedia_license">
			<table border="1">
				<tr>
					<td>
						<strong>License</strong>
					</td>
					<td><strong>Description</strong></td>
					<td>
						<strong>URI</strong>
					</td>
				</tr>
				<cfloop query="docs">
					<tr>
						<td>#display#</td>
						<td>#description#</td>
						<td><a href="#uri#" target="_blank" class="external">#uri#</a></td>
					</tr>
				</cfloop>
			</table>
		<cfelseif table is "ctguid_type">
			<table border="1">
				<tr>
					<td>
						<strong>GUID Type</strong>
					</td>
					<td>
						<strong>Applies To</strong>
					</td>
					<td>
						<strong>Description</strong>
					</td>
					<td>
						<strong>Placeholder</strong>
					</td>
					<td>
						<strong>Search URI</strong>
					</td>
				</tr>
				<cfloop query="docs">
					<tr>
						<td>#guid_type#</td>
						<td>#applies_to#</td>
						<td>#description#</td>
						<td>#placeholder#</td>
						<td>#search_uri#</td>
					</tr>
				</cfloop>
			</table>
		<cfelseif table is "ctspecific_permit_type">
			<table border="1">
				<tr>
					<td>
						<strong>Specific Type</strong>
					</td>
					<td>
						<strong>Permit Type</strong>
					</td>
					<td>
						<strong>Inherit to Shipments</strong>
					</td>
				</tr>
				<cfloop query="docs">
					<tr>
						<td>#specific_type#</td>
						<td>#permit_type#</td>
						<td>#accn_show_on_shipment#</td>
					</tr>
				</cfloop>
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
				<cfset columnList = listDeleteAt(columList,listFind(columnList,ucase(theColummName)))>
				<cfset columnList = listPrepend(columnList,ucase(thecolumnName))>
			</cfif>
			<cfset columnArr = ListToArray(columnList)>

			<table border="1">
				<tr>
					<cfloop array="#columnARr#" index="colName">
						<td>
							<strong>#colName#</strong>
						</td>
					</cfloop>
					<cfif NOT #columnList# contains "collection_cde">
						<td>
							<strong>Collection</strong>
						</td>
					</cfif>
				</tr>
				<cfset i=1>
				<cfloop query="orderedDocs">
					<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
						<cfloop array="#columnArr#" index="colName">
							<cfif orderedDocs[colName][currentrow] EQ field>
								<td nowrap><span aria-label="highlighted value you searched for"><strong>#orderedDocs[colName][currentrow]#</strong></span></td>
							<cfelse>
								<td nowrap>#orderedDocs[colName][currentrow]#</td>
							</cfif>
						</cfloop>
						<cfif NOT #columnList# contains "collection_cde">
							<td>All</td>
						</cfif>
					</tr>
				</cfloop>
			</table>
		</cfif>
	</div>
	
</cfif>
<cfinclude template="/shared/_footer.cfm">
</cfoutput>
