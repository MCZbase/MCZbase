<!---
vocabularies/component/functions.cfc

Copyright 2020 President and Fellows of Harvard College

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

<!--- function saveUndColl 
Update an existing arbitrary collection record (underscore_collection).

@param underscore_collection_id primary key of record to update
@param collection_name the brief uman readable description of the arbitrary collection, must not be blank.
@param description description of the collection
@param underscore_agent_id the agent associated with this arbitrary collection
@return json structure with status and id or http status 500
--->
<cffunction name="saveUndColl" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="collection_name" type="string" required="yes">
	<cfargument name="description" type="string" required="no">
	<cfargument name="html_description" type="string" required="no">
	<cfargument name="underscore_agent_id" type="string" required="no">
	<cfargument name="mask_fg" type="string" required="no">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfif len(trim(#collection_name#)) EQ 0>
			<cfthrow type="Application" message="Number Series must contain a value.">
		</cfif>
		<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update underscore_collection set
				collection_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_name#">
				<cfif isdefined("description")>
					,description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">
				</cfif>
				<cfif isdefined("underscore_agent_id") and len(underscore_agent_id) GT 0>
					,underscore_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_agent_id#">
				<cfelse>
					,underscore_agent_id = NULL
				</cfif>
				<cfif isdefined("mask_fg")>
					,mask_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mask_fg#">
				</cfif>
				<cfif isdefined("html_description")>
					,html_description = <cfqueryparam cfsqltype="CF_SQL_CLOB" value="#html_description#">
				</cfif>
			where 
				underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
		</cfquery>
		<cfset row = StructNew()>
		<cfset row["status"] = "saved">
		<cfset row["id"] = "#underscore_collection_id#">
		<cfset data[1] = row>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing saveUndColl: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfheader statusCode="500" statusText="#message#">
		<cfoutput>
			<div class="container">
				<div class="row">
					<div class="alert alert-danger" role="alert">
						<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
						<h2>Internal Server Error.</h2>
						<p>#message#</p>
						<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
					</div>
				</div>
			</div>
		</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getUndCollList.  Search for arbitrary collections returning json suitable for a dataadaptor.

@param collection_name name of the underscore collection (arbitrary grouping) to search for.
@return a json structure containing matching coll event number series.
--->
<cffunction name="getUndCollList" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_name" type="string" required="yes">
	<!--- perform wildcard search anywhere in coll_event_collection_name.collection_name --->
	<cfset collection_name = "%#collection_name#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				underscore_collection_id, 
				collection_name, 
				description,
				underscore_agent_id,
				case 
					when underscore_agent_id is null then '[No Agent]'
					else MCZBASE.get_agentnameoftype(underscore_agent_id, 'preferred')
					end
				as agentname,
				html_description
			FROM 
				underscore_collection
			WHERE
				collection_name like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_name#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["coll_event_num_series_id"] = "#search.coll_event_num_series_id#">
			<cfset row["collection_name"] = "#search.collection_name#">
			<cfset row["description"] = "#search.description#">
			<cfset row["agent_name"] = "#search.agent_name#">
			<cfset row["id_link"] = "<a href='/grouping/NamedCollection.cfm?method=edit&underscore_collection_id#search.underscore_collection_id#' target='_blank'>#search.collection_name#</a>">
			<cfset row["html_description"] = "#search.html_description#">
			<cfset data[i] = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getUndCollList: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ Error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- Given the primary key value for underscore_relations, remove that record of the relation
 between a collection object and an underscore collection.
 @param underscore_relation_id the primary key value of the row to remove.
 @return a structure with status deleted, count of rows deleted and the id of the deleted row, or an http 500
--->
<cffunction name="removeObjectFromUndColl" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_relation_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="deleteQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteQuery_result">
				delete from underscore_relation 
				where underscore_relation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_relation_id#" >
			</cfquery>
			<cfset rows = deleteQuery_result.recordcount>
			<cfif rows EQ 0>
				<cfthrow message="No matching underscore_relation found for underscore_relation_id=[#underscore_relation_id#].">
			<cfelseif rows GT 1>
				<cfthrow message="More than one match found for underscore_relation_id=[#underscore_relation_id#].">
				<cftransaction action="rollback">
			</cfif>
			<cfset row = StructNew()>
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">
			<cfset row["count"] = rows>
			<cfset row["id"] = "#underscore_relation_id#">
			<cfset data[1] = row>
		</cftransaction>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ Error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---- function addOIbjectToUndColl 
  Given an underscore_collection_id and a string delimited list of guids, look up the collection object id 
  values for the guids and insert the underscore_collection_id - collection_object_id relationships into
  underscore_relation.  
	@param underscore_collection_id the pk of the collection to add the collection objects to.
	@param guid_list a comma delimited list of guids in the form MCZ:Col:catnum
	@return a json structure containing added=nummber of added relations.
--->
<cffunction name="addObjectsToUndColl" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="guid_list" type="string" required="yes">
	<cfset guids = "">
	<cfif Find(',', guid_list) GT 0>
		<cfset guidArray = guid_list.Split(',')>
		<cfset separator ="">
		<cfloop array="#guidArray#" index=#idx#>
			<!--- skip any empty elements --->
			<cfif len(trim(idx)) GT 0>
				<!--- trim to prevent guid, guid from failing --->
				<cfset guids = guids & separator & trim(idx)>
				<cfset separator = ",">
			</cfif>
		</cfloop>
	<cfelse>
		<cfset guids = trim(guid_list)>
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cftransaction>
			<cfquery name="find" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="find_result">
				select distinct 
					collection_object_id 
				from <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
				where 
					guid in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guids#" list="yes" >)
					and collection_object_id is not null
			</cfquery>
			<cfif find_result.recordcount GT 0>
				<cfloop query=find>
					<cfquery name="add" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="add_result">
						insert into underscore_relation
						( 
							underscore_collection_id, 
							collection_object_id
						) values ( 
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#find.collection_object_id#">
						)
					</cfquery>
					<cfset rows = rows + add_result.recordcount>
				</cfloop>
			</cfif>
		</cftransaction>

		<cfset i = 1>
		<cfset row = StructNew()>
		<cfset row["status"] = "success">
		<cfset row["added"] = "#rows#">
		<cfset row["matches"] = "#find_result.recordcount#">
		<cfset row["findquery"] = "#rereplace(find_result.sql,'[\n\r\t]+',' ','ALL')#">
		<cfset data[i] = row>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ Error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
</cffunction>

<!--- Given an underscore_collection_id return an html rendering of the collection objects in that collection.  --->
<!--- TODO: Replace with json to populate grid. --->
<cffunction name="getUndCollObjectsHTML" access="remote" returntype="string" returnformat="plain">
	<cfargument name="underscore_collection_id" type="string" required="yes">

	<cfset result = "">
	<cfquery name="undCollUse" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="undCollUse_result">
		select guid, underscore_relation_id
			from #session.flatTableName#
				left join underscore_relation on underscore_relation.collection_object_id = flat.collection_object_id
			where underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
			order by guid
	</cfquery>
	<cfset result="<h2 id='existingvalues'>Collection objects in this named collection</h2><ul>" >
	<cfloop query="undCollUse">
		<cfset result =  result & "<li><a href='/guid/#undCollUse.guid#' target='_blank'>#undCollUse.guid#</a> " >
		<cfset result =  result & "<button class='btn-xs btn-secondary mx-1' onclick='removeUndRelation(#undCollUse.underscore_relation_id#);'>Remove</button>" >
		<cfset result =  result & "</li>" >
	</cfloop>
	<cfset result=result & '</ul>'>

	<cfreturn result>
</cffunction>

		
	<cffunction name="getSpecimens" access="remote" returntype="any" returnformat="json">
	
		<cfquery name="qrySpecimens"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" >
			SELECT DISTINCT flat.guid, flat.scientific_name,  flat.verbatim_date, flat.spec_locality
			FROM
				underscore_collection
				left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
				left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
					on underscore_relation.collection_object_id = flat.collection_object_id
			WHERE underscore_collection.underscore_collection_id = 22
				and flat.guid is not null
			ORDER BY flat.guid asc
		</cfquery>
		<cfset i = 1>
		<cfset data = ArrayNew(1)>
		<cfloop query="qrySpecimens">
			<cfset row = StructNew()>
			<cfset row["GUID"] = qrySpecimens.guid>
			<cfset row["SCIENTIFIC_NAME"] = qrySpecimens.scientific_name>
			<cfset row["VERBATIM_DATE"] = qrySpecimens.verbatim_date>
			<cfset row["LOCALITY"] = qrySpecimens.spec_locality>
			<cfset data[i] = row>
			<cfset i= i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
		</cffunction>
			

</cfcomponent>
