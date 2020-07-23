<cfoutput>
<cfinclude template="/includes/_frameHeader.cfm">
<cfif not isdefined("table")>
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
   <cfloop query="getCTName">
		<cfset name = REReplace(getCtName.table_name,"^CT","") ><!--- strip CT from names in list for better readability --->
      <li><a href="/info/ctDocumentation.cfm?table=#getCTName.table_name#">#name#</a></li>
   </cfloop>
	</ul>
	<cfabort>
</cfif>
<cfif refind('^CT[A-Z_]+$',ucase(table)) EQ 0>
   <h2>This page can only be used for viewing the controled vocabularies in code tables</h2>
	<cfabort>
</cfif>

<cfset tableName = right(table,len(table)-2)>
<cfif not isdefined("field")>
	<cfset field="">
</cfif>

<div style="margin: 1em;">
	<h3>Documentation for code table <strong>#tableName#</strong>:</h3>
	<cfif table is 'ctspecimen_part_name'>
		<p>If you need to search for two values, put a pipe in between them and no spaces (e.g., skin|skull)</p>
	</cfif>
	<cfquery name="docs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from #table#
	</cfquery>

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
		<!--- figure out the name of the field they want info about - already have the table name,
			passed in as a JS variable ---->
		<cfloop list="#docs.columnlist#" index="colName">
			<cfif #colName# is not "COLLECTION_CDE" and #colName# is not "DESCRIPTION">
				<cfset theColumnName = #colName#>
			</cfif>
		</cfloop>
		
		<!---- first, documentation for the field they selected ---->
		<cfquery name="chosenOne" dbtype="query">
			select * from docs where #theColumnName# = '#field#'
			<cfif #docs.columnlist# contains "collection_cde">
				order by collection_cde
			</cfif>
		</cfquery>
		
		<table border="1">
			<tr>
				<td>
					<strong>Data Value</strong>
				</td>
				<td><strong>Collection</strong></td>
				<td>
					<strong>Documentation</strong>
				</td>
			</tr>
			<cfif len(#field#) gt 0>
				<cfif #docs.columnList# contains "collection_cde">
					<cfloop query="chosenOne">
						<tr style="background-color:##339999 ">
							<td nowrap>#field#</td>
							<td>#collection_cde#</td>
							<td>
								<cfif isdefined("description")>
									#description#&nbsp;
								</cfif>
							</td>
						</tr>
					</cfloop>
				<cfelse>
						<tr style="">
							<td nowrap>#field#</td>
							<td>All</td>
							<td>
								<cfif isdefined("chosenOne.description")>
									#chosenOne.description#&nbsp;
								</cfif>
							</td>
						</tr>					
				</cfif>
			</cfif>
		<cfquery name="theRest" dbtype="query">
			select * from docs where #theColumnName# <> '#field#'
				order by #theColumnName#
			<cfif #docs.columnlist# contains "collection_cde">
				 ,collection_cde
			</cfif>
		</cfquery>
			<cfset i=1>
			<cfif #docs.columnList# contains "collection_cde">
					<cfloop query="theRest">
						 <tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
							<td nowrap>#evaluate(theColumnName)#</td>
							<td>#collection_cde#</td>
							<td>
								<cfif isdefined("description")>
									#description#&nbsp;
								</cfif>
							</td>
						</tr>
						<cfset i=#i#+1>
					</cfloop>
				<cfelse>
						<cfloop query="theRest">
						<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
							<td nowrap>#evaluate(theColumnName)#</td>
							<td>All</td>
							<td>
								<cfif isdefined("description")>
									#description#&nbsp;
								</cfif>
							</td>
							<cfset i=#i#+1>
						</tr>
					</cfloop>	
				</cfif>
		</table>
	</cfif>
	</div>
	
	
</cfoutput>
