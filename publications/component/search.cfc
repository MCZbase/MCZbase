<!---
publications/component/search.cfc

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
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!---
Function getPublications.  Search for publications by fields
 returning json suitable for a dataadaptor.

@param any_part any part of formatted publication string to search for.
@return a json structure containing matching publications with ids, years, long format of publication, etc.
--->
<cffunction name="getPublications" access="remote" returntype="any" returnformat="json">
	<cfargument name="text" type="string" required="yes">
	<cfargument name="publication_type" type="string" required="yes">
	<cfargument name="publication_title" type="string" required="yes">
	<cfargument name="publication_remarks" type="string" required="yes">
	<cfargument name="journal" type="string" required="yes">
	<cfargument name="volume" type="string" required="yes">
	<cfargument name="issue" type="string" required="yes">
	<cfargument name="published_year" type="string" required="yes">
	<cfargument name="to_published_year" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				publication.publication_id, 
				publication_type, 
				published_year, 
				publication_title,
				publication_remarks,
				formatted_publication,
				MCZbase.get_publication_authors(publication.publication_id) as authors,
				MCZbase.get_publication_editors(publication.publication_id) as editors
			FROM 
				publication
				left join formatted_publication on publication.publication_id = formatted_publication.publication_id
			WHERE
				format_style = 'long'
				<cfif isDefined("text") AND len(text) GT 0>
					and formatted_publication like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#text#%">
				</cfif>
				<cfif isDefined("publication_title") AND len(publication_title) GT 0>
					and publication_title like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#publication_title#%">
				</cfif>
				<cfif isDefined("publication_remarks") AND len(publication_remarks) GT 0>
					and publication_remarks like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#publication_remarks#%">
				</cfif>
				<cfif isDefined("publication_type") AND len(publication_type) GT 0>
					and publication_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_type#">
				</cfif>
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>


<!---
Function getPublicationList.  Search for publications by name with a substring match on text, returning json suitable for a dataadaptor.

@param text in formatted_publication to search for.
@return a json structure containing matching publications with ids, years, long format of publication, etc.
--->
<cffunction name="getPublicationList" access="remote" returntype="any" returnformat="json">
	<cfargument name="text" type="string" required="yes">
	<!--- perform wildcard search anywhere in formatted_publication.formatted_publication --->
	<cfset text = "%#text#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				publication_type, published_year, publication_title,
				publication_remarks,
				publication.publication_id, formatted_publication,
				MCZbase.get_publication_authors(publication.publication_id) as authors,
				MCZbase.get_publication_editors(publication.publication_id) as editors
			FROM 
				publication
				left join formatted_publication on publication.publication_id = formatted_publication.publication_id
			WHERE
				formatted_publication like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#text#">
				and format_style = 'long'
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["publication_id"] = "#search.publication_id#">
			<cfset row["formatted_publication"] = "#search.formatted_publication#">
			<cfset row["authors"] = "#search.authors#">
			<cfset row["published_year"] = "#search.published_year#">
			<cfset row["publication_title"] = "#search.publication_title#">
			<cfset row["editors"] = "#search.editors#">
			<cfset row["publication_type"] = "#search.publication_type#">
			<cfset row["publication_remarks"] = "#search.publication_remarks#">
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getPublicationAutocomplete.  Search for publications by name with a substring match on any name, returning json suitable for jquery-ui autocomplete.

@param term publication name to search for.
@return a json structure containing id and value, with matching publications with matched name in value and publication_id in id.
--->
<cffunction name="getPublicationAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in publication_name.publication_name --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				publication_id, formatted_publication
			FROM 
				formatted_publication
			WHERE
				upper(formatted_publication) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.publication_id#">
			<cfset row["value"] = "#reReplace(Canonicalize(search.formatted_publication,false,true),'<(i|/i)>','','all')#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getPublicationAutocompleteMeta.  Search for publications by name with a substring match on any name, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and just the publication name as the selected value.

@param term publication name to search for.
@return a json structure containing id and value, with matching publications with matched name in value and publication_id in id, and matched name 
  with * and preferred name in meta.
--->
<cffunction name="getPublicationAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in publication_name.publication_name --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
      <cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				publication_id, formatted_publication
			FROM 
				formatted_publication
			WHERE
				upper(formatted_publication) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.publication_id#">
			<cfset row["value"] = "#search.formatted_publication#" >
			<cfset row["meta"] = "#search.formatted_publication#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getTypeStatusSearchAutocomplete.  Search for type status values, returning json suitable for jquery-ui autocomplete.

@param term type status to search for.
@return a json structure containing id and value, with matching publications with type_status in name and in id.
--->
<cffunction name="getTypeStatusSearchAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
      <cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
			   type_status, category	
			FROM 
				ctcitation_type_status
			WHERE
				upper(type_status) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfset row = StructNew()>
		<cfset row["id"] = "any">
		<cfset row["value"] = "Any" >
		<cfset data[i]  = row>
		<cfset i = i + 1>
		<cfset row = StructNew()>
		<cfset row["id"] = "any type">
		<cfset row["value"] = "Any Type" >
		<cfset data[i]  = row>
		<cfset i = i + 1>
		<cfset row = StructNew()>
		<cfset row["id"] = "any primary">
		<cfset row["value"] = "Any Primary Type" >
		<cfset data[i]  = row>
		<cfset i = i + 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.type_status#">
			<cfset row["value"] = "#search.type_status#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
