<!---
containers/component/public.cfc

Copyright 2023-2025 President and Fellows of Harvard College

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
<cfcomponent>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- getContainerHistory obtain json listing the container history for a given container_id.
@param container_id the container_id to get history for.
@return a json array of objects with container_id, install_date, container_type, label, description, and barcode.
--->
<cffunction name="getContainerHistory" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT
				container_history.container_id,
				install_date,
				container_type,
				label,
				description,
				barcode
			 FROM 
				container_history
				join container on container_history.parent_container_id = container.container_id
			 WHERE 
				container_history.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#container_id#">
			 GROUP BY
				install_date,
				container_type,
				label,
				description,
				barcode
			ORDER BY install_date DESC
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["container_id"] = "#search.container_id#">
			<cfset row["install_date"] = "#search.install_date#">
			<cfset row["container_type"] = "#search.container_type#">
			<cfset row["label"] = "#search.label#">
			<cfset row["description"] = "#search.description#">
			<cfset row["barcode"] = "#search.barcode#">
			<cfset data[i] = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<cffunction name="getContainerHistoryHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="container_id" type="string" required="yes">

	<cfthread name="getContainerHistoryThread" container_id="#arguments.container_id#">
		<cfoutput>
			<cftry>
				<cfquery name="getContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						container.label,
						container.barcode,
						container.description,
						container.container_type,
						container.container_id,
						container.container_remarks,
						parent.label AS parent_label,
						parent.description AS parent_description,
						parent.container_type AS parent_container_type,
						parent.container_id AS parent_container_id,
						parent.barcode AS parent_barcode,
						parent.container_remarks AS parent_container_remarks
					FROM container 
						left join container parent on container.parent_container_id = parent.container_id
					WHERE container.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#container_id#">
				</cfquery>
				<cfif getContainer.recordcount eq 0>
					<cfthrow message="Container ID #encodeForHtml(container_id)# not found.">
				</cfif>
				<cfquery name="getHistory" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						install_date,
						container_type,
						label,
						description,
						barcode
					 FROM container_history
							join container on container_history.parent_container_id = container.container_id
					 WHERE 
						  container_history.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#container_id#">
					 GROUP BY
						install_date,
						container_type,
						label,
						description,
						barcode
					ORDER BY install_date DESC NULLS LAST
				</cfquery>
				<h2 class="h3"> 
					#getContainer.label# 
					<cfif getContainer.barcode is not getContainer.label>
						(#getContainer.barcode#)
					</cfif>
				</h2>
				<div>
					<h3 class="h4">
						#getContainer.container_type#
					</h3>
					<ul>
					<cfif len(#getContainer.description#) gt 0>
						<li><strong>Description:</strong>#getContainer.description#</li>
					</cfif>
					<cfif len(getContainer.container_remarks) gt 0>
						<li><strong>Remarks:</strong> #getContainer.container_remarks#</li>
					</cfif>
					<cfif #getHistory.recordcount# gt 0>
						Has been in the following container(s):
					<cfelse>
						Has no placement history.
					</cfif>
				</div>
				<table class="table table-striped border mt-2">
					<tr>
						<th>Placement Date</th>
						<th>Name</th>
						<th>Type</th>
						<th>Description</th>
						<th>Unique Identifier</th>
					</tr>
					<tr>
						<td>Current</td>
						<td>
							#getContainer.parent_label#
							<cfif getContainer.parent_barcode is not getContainer.parent_label>
								(#getContainer.parent_barcode#)
							</cfif>
						</td>
						<td>#getContainer.parent_container_type#</td>
						<td>#getContainer.parent_description#</td>
						<td>#getContainer.parent_barcode#</td>
					</tr>
					<cfloop query="getHistory">
						<tr>
							<td>
								<cfif len(trim(install_date)) eq 0>
									Unknown
								</cfif>
								#dateformat(install_date,"yyyy-mm-dd")#
								#timeformat(install_date,"HH:mm:ss")#
							</td>
							<td>
								#label#
								<cfif barcode is not label>
									(#barcode#)
								</cfif>
							</td>
							<td>#container_type#</td>
							<td>#description#</td>
							<td>#barcode#</td>
						</tr>
					</cfloop>
				</table>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getContainerHistoryThread" />
	<cfreturn getContainerHistoryThread.output>
</cffunction>
			

</cfcomponent>
