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
	
	<!--- find email for current user to include in crossref as pid --->

	<!--- obtain data on publication to put into url for crossref --->
	
	<!--- make request to crossref --->
	<!--- crossref metadata lookup resources: https://www.crossref.org/services/metadata-retrieval/#00356 --->

	<!--- crossref OpenURL documentation: https://www.crossref.org/documentation/retrieve-metadata/openurl/ --->

	<cfset lookupURI="https://www.crossref.org/openurl?pid=bdim@oeb.harvard.edu&title=Journal%20of%20Paleontology&aulast=Hodnett&date=2018&spage=1&redirect=false">

<!---
https://www.crossref.org/openurl?pid=bdim@oeb.harvard.edu&title=Journal%20of%20Paleontology&aulast=Hodnett&date=2018&spage=1&redirect=false
--->

	<cfhttp url="#lookupURI#"></cfhttp>
	<!--- parse returned xml --->
	<cfset xmlReturn = cfhttp.filecontent>
	<!--- return results --->
	<cfset return = xmlParse(xmlReturn)>
	<cfset body = return.crossref_result.query_result.body >
	<cfdump var="#body#">
	<cfoutput>
   	#arrayLen(body)#
	</cfoutput>

	<cfreturn ''>
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

<cffunction name="addAuthor" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_id" type="string" required="yes">
				<!--- inserting --->
				<cfquery name="insAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into publication_author_name (
						publication_id,
						agent_name_id,
						author_position,
						author_role
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAgentNameId#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAuthPosn#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAuthorRole#">
					)
				</cfquery>
</cffunction>
<cffunction name="removeAuthor" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_id" type="string" required="yes">
				<!--- deleting --->
				<cfquery name="delAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					delete from publication_author_name 
					where
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
					and publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisRowId#">
				</cfquery>
				<cfquery name="incAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update publication_author_name 
					set author_position=author_position-1 
					where
						publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
						and author_position > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAuthPosn#">
				</cfquery>
</cffunction>
<cffunction name="updateAuthor" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_id" type="string" required="yes">
				<!--- updating --->
				<cfquery name="upAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update
						publication_author_name
					set
						agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisAgentNameId#">,
						author_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisAuthorRole#">
					where
						publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
						and publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisRowId#">
				</cfquery>
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
