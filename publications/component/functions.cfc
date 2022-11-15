<!--- /publications/component/functions.cfc

Backing methods to support editing publication records.

Copyright 2022 President and Fellows of Harvard College

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
<cf_rolecheck>

<cffunction name="savePublication" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_id" type="string" required="yes">
	<cfargument name="published_year" type="string" required="no">
	<cfargument name="publication_type" type="string" required="yes">
	<cfargument name="publication_title" type="string" required="yes">
	<cfargument name="publication_remarks" type="string" required="yes">
	<cfargument name="is_peer_reviewed_fg" type="string" required="yes">
	<cfargument name="doi" type="string" required="yes">
	<cfargument name="publication_loc" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
  			<cfif len(doi) gt 0>
				<cfinvoke component="/component/functions" method="checkDOI" returnVariable="isok">
					<cfinvokeargument name="doi" value="#doi#">
				</cfinvoke>
				<cfif isok is not "true">
					<cfthrow message = "DOI #doi# failed validation with StatusCode #isok#">
				</cfif>
			</cfif>
			<cfquery name="pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE publication 
				SET
					published_year=
						<cfif isDefined("published_year") AND len(published_year) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_" value="#published_year#">,
						<cfelse>
							NULL,
						</cfif>
					publication_type=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_type#">,
					publication_loc=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_loc#">,
					publication_title=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_title#">,
					publication_remarks=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_remarks#">,
					is_peer_reviewed_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#is_peer_reviewed_fg#">,
					doi = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#doi#">
				WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#publication_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- lookup potential DOI matches in crossref ---> 
<cffunction name="crossRefLookup" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_id" type="string" required="yes">
	
	<cfset data = ArrayNew(1)>
	<!--- find email for current user to include in crossref as pid --->
	<cfquery name="getEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select email from cf_user_data,cf_users
		where cf_user_data.user_id = cf_users.user_id and
		cf_users.username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>

	<!--- obtain data on publication to put into url for crossref --->
	<cfquery name="getPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT
			publication_title,
			published_year as year,
			get_publication_attribute(publication_id,'begin page') as spage,
			get_publication_attribute(publication_id,'journal name') as jtitle,
			get_publication_attribute(publication_id,'volume') as volume,
			get_publication_attribute(publication_id,'issue') as issue
		FROM
			publication
		WHERE
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	<cfquery name="getAuthor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT person.last_name as aulast
		FROM
			publication_author_name p
			join agent_name an on p.agent_name_id = an.agent_name_id
			join person on an.agent_id = person.person_id
		WHERE
			p.author_role = 'author' and p.author_position = 1 and
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	
	<!--- make request to crossref --->
	<!--- crossref metadata lookup resources: https://www.crossref.org/services/metadata-retrieval/#00356 --->

	<!--- crossref OpenURL documentation: https://www.crossref.org/documentation/retrieve-metadata/openurl/ --->
	<!--- example:
		https://www.crossref.org/openurl?pid=bdim@oeb.harvard.edu&title=Journal%20of%20Paleontology&aulast=Hodnett&date=2018&spage=1&redirect=false&multihit=true
	--->

	<cfset query = "">
	<cfif getPub.recordcount GT 0>
		<cfif len(getPub.jtitle) GT 0>
			<cfset query="&title=#getPub.jtitle#">
		<cfelse>
			<cfif len(getPub.publication_title) GT 0>
				<cfset query="&stitle=#getPub.publication_title#">
			</cfif>
		</cfif>
		<cfif len(getPub.spage) GT 0 >
			<cfset query="#query#&spage=#getPub.spage#">
		</cfif>
		<cfif len(getPub.year) GT 0 >
			<cfset query="#query#&date=#getPub.year#">
		</cfif>
		<cfif len(getPub.volume) GT 0 >
			<cfset query="#query#&volume=#getPub.volume#">
		</cfif>
		<cfif len(getPub.issue) GT 0 >
			<cfset query="#query#&issue=#getPub.issue#">
		</cfif>
	</cfif>
	<cfif getAuthor.recordcount GT 0>
		<cfif len(getAuthor.aulast) GT 0 >
			<cfset query="#query#&aulast=#getAuthor.aulast#">
		</cfif>
	</cfif>

	<cfif len(query) GT 0>
		<cfset lookupURI="https://www.crossref.org/openurl?pid=#getEmail.email#&#query#&redirect=false&multihit=true">
	<cfelse>
		<cfthrow message="nothing found to look up.">
	</cfif>

	<cfhttp url="#lookupURI#"></cfhttp>
	<!--- parse returned xml --->
	<cfset xmlReturn = cfhttp.filecontent>
	<!--- return results --->
	<cfset return = xmlParse(xmlReturn)>
	<cfset body = return.crossref_result.query_result.body >
	<cfif arrayLen(body) EQ 1>
		<cftry>
			<cfset doi = return.crossref_result.query_result.body.query.doi.XmlText>
			<cfset row = StructNew()>
			<cfset row["match"] = "1">
			<cfset row["doi"] = "#doi#">
			<cfset data[1] = row>
		<cfcatch>
   		<cfset status = return.crossref_result.query_result.body.query.XMLAttributes.status >
			<cfif status EQ "unresolved">
				<cfthrow message = "No matches found">
			</cfif>
			<cfdump var="#return#">
		</cfcatch>
		</cftry>
	<cfelseif arrayLen(body) GT 1>
		<!--- TODO: Handle multiple possible matches --->
		<cfdump var="#return#">
	<cfelse>
		<cfset row = StructNew()>
		<cfset row["match"] = "0">
		<cfset row["doi"] = "">
		<cfset data[1] = row>
	</cfif>

	<cfreturn #serializeJSON(data)#>
</cffunction>

<cffunction name="addMedia" access="remote" returntype="any" returnformat="json">
<!---------------------------------------------------------------------------------------------------------->
		<cfif len(media_uri) gt 0>
			<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_media_id.nextval nv from dual
			</cfquery>
			<cfset media_id=mid.nv>
			<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into media 
					(media_id,media_uri,mime_type,media_type,preview_uri)
	            values 
					(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_uri#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#preview_uri#">)
			</cfquery>
			<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into media_relations (
					media_id,
					media_relationship,
					related_primary_key
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
					'shows publication',
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				)
			</cfquery>
			<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into media_labels (
					media_id,
					media_label,
					label_value)
				values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
					'description',
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_desc#">)
			</cfquery>
		</cfif>
</cffunction>


<cffunction name="getAuthorsForPubHtml" access="remote" returntype="string">
	<cfargument name="publication_id" type="string" required="yes">
	<cfthread name="getAuthorsForPubThread">

		<cftry>
			<cfquery name="getAuthorsEditors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getAuthorsEditors_result">
				SELECT
					publication_author_name.PUBLICATION_AUTHOR_NAME_ID PUBLICATION_AUTHOR_NAME_ID,
					publication_author_name.AGENT_NAME_ID AGENT_NAME_ID,
					publication_author_name.AUTHOR_POSITION AUTHOR_POSITION,
					publication_author_name.AUTHOR_ROLE AUTHOR_ROLE,
					agent_name.AGENT_ID AGENT_ID,
					agent_name.AGENT_NAME_TYPE AGENT_NAME_TYPE,
					agent_name.AGENT_NAME AGENT_NAME
				FROM publication_author_name
					join agent_name on publication_author_name.agent_name_id=agent_name.agent_name_id 
				WHERE
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				ORDER BY author_role, author_position
			</cfquery>
			<cfquery name="getAuthors" dbtype="query">
				SELECT *
				FROM getAuthorsEditors
				WHERE 
					author_role = 'author'
			</cfquery>
			<cfquery name="getEditors" dbtype="query">
				SELECT *
				FROM getAuthorsEditors
				WHERE 
					author_role = 'editor'
			</cfquery>
			<cfoutput>
				<div class="col-12">
					<h3 class="h4" >Authors</h3> 
					<button class="btn btn-xs btn-primary" onclick="addAgent()">Add Author</button>
					<!--- TODO: Add author/editor dialog --->
					<ul>
						<cfloop query="getAuthors">
							<li>
								<a href="agents/Agent.cfm?agent_id=#agent_id#" target="_blank">#agent_name#</a> 
								#author_position#
								<!--- TODO: Edit --->
								<!--- TODO: move --->
								<!--- TODO: remove --->
							</li>
						</cfloop>
					</ul>
				</div>
				<div class="col-12">
					<h3 class="h4" >Editors</h3> 
					<button class="btn btn-xs btn-primary" onclick="addAgent()">Add Editor</button>
					<!--- TODO: Add author/editor dialog --->
					<ul>
						<cfloop query="getEditors">
							<li>
								<a href="agents/Agent.cfm?agent_id=#agent_id#" target="_blank">#agent_name#</a> 
								#author_position#
								<!--- TODO: Edit --->
								<!--- TODO: move --->
								<!--- TODO: remove --->
							</li>
						</cfloop>
					</ul>
				</div>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAuthorsForPubThread" />
	<cfreturn getAuthorsForPubThread.output>
</cffunction>

<!--- addAuthor add a publication_author_name record linking a publication to an
  agent in the role of author or editor.
  @param publication_id the publication to which to add the author/editor.
  @param agent_name_id the agent name of the agent to add as the author/editor
  @param author_position the ordinal position of the author/editor in the list 
   of authors or of editors.
  @param author_role role of the agent either author or editor.
  @return a structure with status=added, id=publication_author_name_id
    or if an exception was raised, an http response with http statuscode of 500.
--->
<cffunction name="addAuthor" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_id" type="string" required="yes">
	<cfargument name="agent_name_id" type="string" required="yes">
	<cfargument name="author_position" type="string" required="yes">
	<cfargument name="author_role" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="insertAuthor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insertAuthor_result">
				INSERT INTO publication_author_name (
					publication_id,
					agent_name_id,
					author_position,
					author_role
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_name_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#author_position#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#author_role#">
				)
			</cfquery>
			<cfif insertAuthor_result.recordcount eq 0>
				<cfthrow message="Failed to properly insert new publication_author_name record">
			</cfif>
			<cfset rowid = insertAuthor_result.generatedkey>
			<cftransaction action="commit">
			<cfquery name="report" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="report_result">
				SELECT
					publication_author_name_id as id
				FROM 
					publication_author_name
				WHERE
					ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#rowid#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "added">
			<cfset row["id"] = "#report.id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- removeAuthor delete a publication_author_name record linking a publication to an
  agent in the role of author or editor, updates author_position of remining records
  for the same publication.
  @param publication_author_name_id the primary key value of the row to delete.
  @return a structure with status=deleted, updates=number of publication_author_name 
    records updated as a result of promoting their author_position to fill the gap.
    or if an exception was raised, an http response with http statuscode of 500.
--->
<cffunction name="removeAuthor" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_author_name_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- find the current oridinal position and type of the author in the list of authors/editors. --->
			<cfquery name="lookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookup_result">
				SELECT
					publication_id,
					author_position,
					author_role
				FROM
					publication_author_name
				WHERE
					publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_author_name_id#">
			</cfquery>
			<cfif lookup.recordcount NEQ 1>
				<cfthrow message = "error finding publication_author_name record to delete">
			</cfif>
			<!--- delete the target author/editor --->
			<cfquery name="deleteAuthor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteAuthor_result">
				delete from publication_author_name 
				where
				publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				and publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisRowId#">
			</cfquery>
			<cfif deleteAuthor_result.recordcount NEQ 1>
				<cfthrow message = "error deleting publication_author_name record [#encodeForHtml(publication_author_name_id)#]">
			</cfif>
			<!--- update the ordinal positon of the rest of the list.  --->
			<cfquery name="reorder" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="reorder_result">
				update publication_author_name 
				set author_position=author_position-1 
				where
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.publication_id#">
					and author_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lookup.author_role#">
					and author_position > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.author_position#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "added">
			<cfset row["updates"] = "#reorder_result.recordcount#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>


<!--- moveAuthor move an author or editor to a specified position in the list. 

--->
<cffunction name="moveAuthor" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_author_name_id" type="string" required="yes">
	<cfargument name="to_position" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="lookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookup_result">
				SELECT
					publication_id,
					author_position,
					author_role
				FROM
					publication_author_name
				WHERE
					publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_author_name_id#">
			</cfquery>
			<cfif lookup.recordcount NEQ 1>
				<cfthrow message = "error finding publication_author_name record to move">
			</cfif>
			<cfif author_position EQ to_position>
				<!--- no action --->
				<cfthrow message = "no change, old position and new position are the same.">
			</cfif>
			<cfif author_position EQ 1 OR to_position EQ 1>
				<!--- lookup agent and first/second author name forms --->
				<cfquery name="lookupAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupAgent_result">
					SELECT
						agent.agent_id,
						fan.agent_name_id first_author_agent_name_id,
						san.agent_name_id second_author_agent_name_id
					FROM
						agent_name author_agent_name
						join agent on author_agent_name.agent_id = agent.agent_id
						left join agent_name fan on agent.agent_id = fan.agent_id and fan.agent_name_type = 'first author'
						left join agent_name san on agent.agent_id = san.agent_id and san.agent_name_type = 'second author'
				</cfquery>
			</cfif>
			<cfif author_position EQ 1>
				<!--- does a second author form of name exist for the agent --->
				<cfthrow message = "Move from first author not implemented yet.">
			<cfelse>
				<cfif to_position EQ 1>
					<!--- does a first author form of name exist for the agent --->
					<cfthrow message = "Move to first author not implemented yet.">
				<cfelse>
					<!--- increment everyone from to_position up by 1 --->
					<cfquery name="up" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="up_result">
						UPDATE
							publication_author_name
						SET
							author_position = author_position + 1
						WHERE
							publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.publication_id#">
							and author_role = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.author_role#">
							and author_position >= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#to_position#">
					</cfquery>
					<cfif author_position GT to_position>
						<!--- move to to_position --->
						<cfquery name="mv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="mv_result">
							UPDATE
								publication_author_name
							SET
								author_position = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#to_position#">
							WHERE
								publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_author_name_id#">
						</cfquery>
					<cfelse>	
						<!--- author_position LT to_position --->
						<!--- move to to_position+1 --->
						<cfset target = to_position + 1>
						<cfquery name="mv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="mv_result">
							UPDATE
								publication_author_name
							SET
								author_position = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target#">
							WHERE
								publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_author_name_id#">
						</cfquery>
					</cfif>
					<!--- move everyone above author_position down by 1 --->
					<cfquery name="dn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="dn_result">
						UPDATE
							publication_author_name
						SET
							author_position = author_position - 1
						WHERE
							publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.publication_id#">
							and author_role = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.author_role#">
							and author_position >= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.author_position#">
					</cfquery>
				</cfif>
			</cfif>

			<cfset row = StructNew()>
			<cfset row["status"] = "moved">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>



<!--- updateAuthor update a publication_author_name record without changing ordinal position. 
--->
<cffunction name="updateAuthor" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_author_name_id" type="string" required="yes">
	<cfargument name="agent_name_id" type="string" required="yes">
	<cfargument name="author_role" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="updateAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateAuthor_result">
				UPDATE
					publication_author_name
				SET
					agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAgentNameId#">,
					author_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAuthorRole#">
				WHERE
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
					and publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisRowId#">
			</cfquery>
			<cfif	updateAuthor_result.recordcount NEQ 1>
				<cfthrow message = "Error updating publication_author_name record.">
			</cfif>
			<cfset row = StructNew()>
			<cfset row["status"] = "updated">
			<cfset row["id"] = "#publication_author_name_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<cffunction name="getAttributesForPubHtml" access="remote" returntype="string">
	<cfargument name="publication_id" type="string" required="yes">
	<cfthread name="getAttributesForPubThread">
		<cftry>
			<cfquery name="ctpublication_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select publication_attribute from ctpublication_attribute order by publication_attribute
			</cfquery>
			<cfquery name="atts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="atts_result">
				SELECT
					publication_attribute_id,
					publication_id,
					publication_attribute,
					pub_att_value
				FROM publication_attributes 
				WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
			<cfquery name="available_pub_att" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT ctpublication_attribute.publication_attribute 
				FROM ctpublication_attribute 
				WHERE
					ctpublication_attribute.publication_attribute NOT IN (
						SELECT distinct publication_attribute 
						FROM publication_attributes
						WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
					)
				ORDER BY ctpublication_attribute.publication_attribute
			</cfquery>
			<cfoutput>
				<h2 class="h3">Attributes</h2>
				<label for="new_attr" class="data-entry-label">Add</a>
				<script>
					<!--- TODO: Implement addAttribute, ? move to dialog --->
				</script>
				<select name="new_attr" id="new_attr" onchange="addAttribute(this.value)">
					<option value=""></option>
					<cfloop query="available_pub_att">
						<option value="#available_pub_att.publication_attribute#">#available_pub_att.publication_attribute#</option>
					</cfloop>
				</select>
				<ul>
					<cfloop query="atts">
						<!--- TODO: Edit --->
						<!--- TODO: Delete --->
						<li>#atts.publication_attribute#: #atts.pub_att_value#</li>
					</cfloop>
				</ul>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAttributesForPubThread" />
	<cfreturn getAttributesForPubThread.output>
</cffunction>

<!---------------------------------------------------------------------------------------------------------->
<!---
		<cfloop from="1" to="#numberAttributes#" index="n">
			<cfif isdefined("attribute_type#n#")>
				<cfset thisAttribute = #evaluate("attribute_type" & n)#>
			<cfelse>
				<cfset thisAttribute = "">
			</cfif>
			<cfset thisAttVal = #evaluate("attribute" & n)#>
			<cfif isdefined("publication_attribute_id#n#")>
				<cfset thisAttId = #evaluate("publication_attribute_id" & n)#>
			<cfelse>
				<cfset thisAttId = "">
			</cfif>
			<cfif thisAttVal is "deleted">
				<cfquery name="delAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					delete from publication_attributes 
					where publication_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAttId#">
				</cfquery>
			<cfelseif thisAttId gt 0>
				<cfquery name="upAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update
						publication_attributes
					set
						publication_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttribute#">,
						pub_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttVal#">
					where 
						publication_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAttId#">
				</cfquery>
			<cfelseif len(thisAttId) is 0 and len(thisAttVal) gt 0>
				<cfquery name="ctpublication_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into publication_attributes (
						publication_id,
						publication_attribute,
						pub_att_value
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttribute#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAttVal#">
					)
				</cfquery>
			</cfif>
		</cfloop>
--->
<!---------------------------------------------------------------------------------------------------------->
<!---
		<cfloop from="1" to="#numberLinks#" index="n">
			<cfif isdefined("link#n#")>
				<cfset thisLink = #evaluate("link" & n)#>
			<cfelse>
				<cfset thisLink = "">
			</cfif>
			<cfif isdefined("description#n#")>
				<cfset thisDesc = #evaluate("description" & n)#>
			<cfelse>
				<cfset thisDesc = "">
			</cfif>
			<cfif isdefined("publication_url_id#n#")>
				<cfset thisId = #evaluate("publication_url_id" & n)#>
			<cfelse>
				<cfset thisId = "">
			</cfif>
			<cfif thisLink is "deleted">
				<cfquery name="delAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					delete from publication_url where publication_url_id=#thisId#
				</cfquery>
			<cfelseif thisLink is not "deleted" and thisId gt 0>
				<cfquery name="upAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update
						publication_url
					set
						link = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisLink#">,
						description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisDesc#">
					where publication_url_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisId#">
				</cfquery>
			<cfelseif len(thisId) is 0 and len(thisLink) gt 0>
				<cfquery name="ctpublication_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into publication_url (
						publication_id,
						link,
						description
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisLink#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisDesc#">
					)
				</cfquery>
			</cfif>
		</cfloop>
	</cftransaction>
--->
<!---------------------------------------------------------------------------------------------------------->
<!--- now get the formatted publications --->
<!--- 
	<cfinvoke component="/component/publication" method="shortCitation" returnVariable="shortCitation">
		<cfinvokeargument name="publication_id" value="#publication_id#">
		<cfinvokeargument name="returnFormat" value="plain">
	</cfinvoke>
	<cfinvoke component="/component/publication" method="longCitation" returnVariable="longCitation">
		<cfinvokeargument name="publication_id" value="#publication_id#">
		<cfinvokeargument name="returnFormat" value="plain">
	</cfinvoke>

	<cfquery name="sfp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update formatted_publication 
		set formatted_publication = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shortCitation#">
		where
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			and format_style = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="short">
	</cfquery>
	<cfquery name="lfp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update formatted_publication 
		set formatted_publication = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#longCitation#">
		where
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			and format_style = 'long'
	</cfquery>
	<cflocation url="Publication.cfm?action=edit&publication_id=#publication_id#" addtoken="false">
--->

</cfcomponent>
