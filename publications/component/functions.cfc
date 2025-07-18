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
<cfinclude template="/media/component/public.cfc" runOnce="true"> <!--- getMediaBlockHtml --->
<cf_rolecheck>

<!--- getCitationForPubHtml get the long or short form of the citation for a publication record.
  @param publication_id the publication for which to obtain the citaiton.
  @param form optional 'long', 'plain' or 'short', default 'long' for the form of the citation to return.
  @return html containing the citation in the requested form with html markup.
--->
<cffunction name="getCitationForPubHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfargument name="form" type="string" required="no">
	<cfif NOT isDefined("form") OR len(form) EQ 0>
		<cfset form="long">
	</cfif>

	<cftry>
		<cfoutput>
			<cfquery name="getCitation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getCitation_result">
				SELECT
					<cfif form EQ "short">
						mczbase.getshortcitation(publication_id) as citation
					<cfelseif form EQ "plain">
						mczbase.get_citation(publication_id,'long',1) as citation
					<cfelse>
						mczbase.get_citation(publication_id,'long',0) as citation
					</cfif>
				FROM publication
				WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
			<cfif getCitation.recordcount EQ 0>
				<cfthrow message="No matching records in the formatted publication table.">
			</cfif>
			<cfloop query="getCitation">
				#getCitation.citation#
			</cfloop>
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
</cffunction>

<!--- savePublication update a publication record --->
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
			<cfquery name="pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE publication 
				SET
					published_year=
						<cfif isDefined("published_year") AND len(published_year) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#published_year#">,
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

<!--- saveJournalName update a publication record --->
<cffunction name="saveJournalName" access="remote" returntype="any" returnformat="json">
	<cfargument name="old_journal_name" type="string" required="yes">
	<cfargument name="journal_name" type="string" required="no">
	<cfargument name="short_name" type="string" required="yes">
	<cfargument name="issn" type="string" required="yes">
	<cfargument name="remarks" type="string" required="yes">
	<cfargument name="start_year" type="string" required="yes">
	<cfargument name="end_year" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="doUpdate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="doUpdate_result">
				UPDATE ctjournal_name
				SET
					start_year=
						<cfif isDefined("start_year") AND len(start_year) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#start_year#">,
						<cfelse>
							NULL,
						</cfif>
					end_year=
						<cfif isDefined("end_year") AND len(end_year) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#end_year#">,
						<cfelse>
							NULL,
						</cfif>
					issn=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#issn#">,
					short_name=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#short_name#">,
					<cfif isDefined("journal_name") AND len(journal_name) GT 0>
						journal_name=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#journal_name#">,
					</cfif>
					remarks=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
				WHERE journal_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#old_journal_name#">
			</cfquery>
			<cfif doUpdate_result.recordcount NEQ 1>
				<cfthrow message="Did not update exactly one ctjournal_name record with the specified journal_name [#encodeForHtml(old_journal_name)#].">
			</cfif>
			<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="check_result">
				SELECT journal_name 
				FROM
					ctjournal_name
				WHERE
					<cfif isDefined("journal_name") AND len(journal_name) GT 0>
						journal_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#journal_name#">
					<cfelse>
						journal_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#old_journal_name#">
					</cfif>
			</cfquery>
			<cfif check.recordcount NEQ 1>
				<cfthrow message="Check did not match a record with the expected journal_name value.">
			</cfif>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#encodeForHtml(check.journal_name)#">
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
	<cfquery name="getEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select email from cf_user_data,cf_users
		where cf_user_data.user_id = cf_users.user_id and
		cf_users.username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>

	<!--- obtain data on publication to put into url for crossref --->
	<cfquery name="getPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
	<cfquery name="getAuthor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
			<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select sq_media_id.nextval nv from dual
			</cfquery>
			<cfset media_id=mid.nv>
			<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				insert into media 
					(media_id,media_uri,mime_type,media_type,preview_uri)
	            values 
					(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_uri#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#preview_uri#">)
			</cfquery>
			<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
			<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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


<!--- getAuthorsForPubHtml obtain a block of html for editing the authors and editors
   of a publication 
 @param publication_id the publication for which to obtain authors/editors
 @return html listing authors and editors for the specified publication in a form for editing
---->
<cffunction name="getAuthorsForPubHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfthread name="getAuthorsForPubThread">

		<cftry>
			<cfquery name="getAuthorsEditors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAuthorsEditors_result">
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
				<div class="col-12 col-md-6">
					<h2 class="h3" >Authors</h2> 
					<button class="btn btn-xs btn-primary" onclick=" openAddAuthorEditorDialog('addAuthorEditorDialogDiv', '#publication_id#', 'authors', reloadAuthors); ">Add Authors</button>
					<ol class="mt-2">
						<cfloop query="getAuthors">
							<li value="#author_position#" class="my-1">
								<a href="/agents/Agent.cfm?agent_id=#agent_id#" target="_blank">#agent_name#</a> 
								<!--- TODO: Edit --->
								<!--- TODO: move --->
								<button type="button" 
									onClick="  confirmDialog('Remove Author #agent_name#?','Remove?', function() {removeAuthor('#publication_author_name_id#',reloadAuthors);} );"
									arial-label='remove this author from this publication' 
									class='btn btn-xs btn-warning' >Remove</button>
							</li>
						</cfloop>
					</ul>
				</div>
				<div class="col-12 col-md-6 border-left border-top">
					<h2 class="h3" >Editors</h2> 
					<button class="btn btn-xs btn-primary" onclick=" openAddAuthorEditorDialog('addAuthorEditorDialogDiv', '#publication_id#', 'editors', reloadAuthors); ">Add Editors</button>
					<ol>
						<cfloop query="getEditors">
							<li value="#author_position#">
								<a href="/agents/Agent.cfm?agent_id=#agent_id#" target="_blank">#agent_name#</a> 
								<!--- TODO: Edit --->
								<!--- TODO: move --->
								<button type="button" 
									onClick="  confirmDialog('Remove Editor #agent_name#?','Remove?', function() {removeAuthor('#publication_author_name_id#',reloadAuthors);} );"
									arial-label='remove this editor from this publication' 
									class='btn btn-xs btn-warning' >Remove</button>
							</li>
						</cfloop>
					</ul>
				</div>
				<div id="addAuthorEditorDialogDiv"></div>
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

<!--- addAuthorEditorHtml obtain a block of html to populate a dialog for adding an author or editor to a publication
 @param publication_id the publication for which to obtain authors/editors.
 @param role the role in which to add new agents, allowed values authors or editors.
 @return html form for a dialog to add authors/editors to a publication.
---->
<cffunction name="addAuthorEditorHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfargument name="role" type="string" required="yes">
	<cfset variables.publication_id = arguments.publication_id>
	<cfset variables.role = arguments.role>

	<cfthread name="getAuthorEditorHtmlThread">
		<cftry>
			<cfif role EQ "authors">
				<cfset targetRole = "author">
				<cfset roleLabel = "Author">
			<cfelseif role EQ "editors">
				<cfset targetRole = "editor">
				<cfset roleLabel = "Editor">
			<cfelse>
				<cfthrow message="Add Author or Editor Dialog must be created with role='authors' or role='editors'. [#encodeForHtml(role)#] is not an acceptable value.">
			</cfif>
			<!--- ordinal position is a single counter, applied to both editors and authors --->
			<cfquery name="getMaxPosition" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getMaxPosition_result">
				SELECT
					max(author_position) max_position
				FROM publication_author_name
				WHERE
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
			<cfquery name="getAuthorsEditors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAuthorsEditors_result">
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
					<cfif role EQ "authors">
						and author_role = 'author'
					<cfelseif role EQ "editors">
						and author_role = 'editor'
					</cfif>
				ORDER BY author_position asc
			</cfquery>
			<cfset minpositionfortype = 0>
			<cfloop query="getAuthorsEditors">
				<cfif minpositionfortype EQ 0>
					<cfset minpositionfortype=author_position>
				</cfif>
			</cfloop>
			<cfset maxposition = 0>
			<cfloop query="getMaxPosition">
				<cfset maxposition=max_position>
				<cfif len(maxposition)EQ 0 ><cfset maxposition=0></cfif>
			</cfloop>
			<cfset isFirst = false>
			<cfif role EQ "authors">
				<cfquery name="authorCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="authorCount_result">
					SELECT count(*) ct
					FROM publication_author_name
					WHERE 
						publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
						AND 
						author_role = 'author'
				</cfquery>
				<cfif authorCount.ct EQ 0>
					<cfset isFirst = true>
				</cfif>
			<cfelseif role EQ "editors">
				<cfquery name="editorCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="editorCount_result">
					SELECT count(*) ct
					FROM publication_author_name
					WHERE 
						publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
						AND 
						author_role = 'editor'
				</cfquery>
				<cfif editorCount.ct EQ 0>
					<cfset isFirst = true>
				</cfif>
			</cfif>
			<cfif role EQ "authors">
				<cfif isFirst>
					<!--- there is no first author if we are adding authors, use first author form of name --->
					<cfset newpos=1>
					<cfset nameform="author">
				<cfelse>
					<!--- there is at least a first author if we are adding authors. --->
					<cfset newpos=2>
					<cfset nameform="second author">
				</cfif>
			<cfelse>
				<!--- all editors use the second author form of the author name --->
				<cfset newpos=2>
				<cfset nameform="second author">
			</cfif>
			<cfoutput>
				<div class="form-row">
					<div class="col-12">
						<h3 class="h4" >Add #roleLabel#</h3>
						<div class="form-row">
							<div class="col-12 col-md-5">
								<label for="agent_name" class="data-entry-label">Pick an agent to add as an #roleLabel#</label>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="agent_name" id="agent_name" class="form-control rounded-right data-entry-input form-control-sm reqdClr" aria-label="Agent Name" aria-describedby="agent_name_label" value="" required>
									<input type="hidden" name="agent_id" id="agent_id" value="">
								</div>
							</div>
							<div class="col-12 col-md-3">
								<label for="agent_view" class="data-entry-label">Selected Agent</label>
								<div id="agent_view"></div>
							</div>
							<div class="col-12 col-md-2">
								<label for="agent_name_control" class="data-entry-label">#roleLabel#</label>
								<div id="author_name_control"></div>
								<input type="hidden" name="author_name_id" id="author_name_id" value="">
								<input type="hidden" name="next_author_position" id="next_author_position" value="#maxposition+1#">
								<input type="hidden" name="is_first_position" id="is_first_position" value="#newpos#">
							</div>
							<div class="col-12 col-md-2">
								<a href="/agents/editAgent.cfm?action=new" aria-label="add a new agent" class="btn btn-xs btn-secondary" target="_blank" >New Agent</a>
							</div>
						</div>
						<div class="form-row">
							<div class="col-12 col-md-3">
								<button class="btn btn-xs btn-primary disabled" id="addButton" onclick="addAuthor($('##author_name_id').val(),'#publication_id#',$('##next_author_position').val(),'#role#',reloadAuthors);" disabled >Add as #roleLabel# [<span class="small" id="position_to_add_span">#maxposition+1#</span>]</button>
							</div>
							<div class="col-12 col-md-9" id="missingNameDiv">
								Missing the <span id="form_to_add_span">#nameform#</span> form of the author name for this agent.
								<button class="btn btn-xs btn-primary disabled" id="addNameButton" onclick="showAddAuthorNameDialog();" disabled >Add</button>
							</div>
							<script>
								$(document).ready(function() {
									$('##missingNameDiv').hide();
									$('##agent_name').focus();
								});
								function showAddAuthorNameDialog() {
									console.log($('##agent_id').val());
									console.log($('##next_author_position').val()); 
									openAddAgentNameOfTypeDialog('addNameTypeDialogDiv', $('##agent_id').val(), $('##form_to_add_span').html());
								};
							</script>
							<div id="addNameTypeDialogDiv"></div>
							<script>
								$(document).ready(function() {
									makeRichAuthorPicker('agent_name', 'agent_id', 'agent_name_icon', 'agent_view', null, 'author_name_control','author_name_id',$('##is_first_position').val(),"#targetRole#");
								});
							</script>
						</div>
						<div class="col-12" id="listOfAuthorsDiv">
							<ol id="authorListOnDialog" class="mt-2">
								<cfloop query="getAuthorsEditors">
									<li class="my-1">#getAuthorsEditors.agent_name#</li>
								</cfloop>
							</ol>
						</div>
					</div>
					<!--- TODO: Save and continue button, handling switch from first author to second author if first was added --->
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
	<cfthread action="join" name="getAuthorEditorHtmlThread" />
	<cfreturn getAuthorEditorHtmlThread.output>
</cffunction>


<!--- addAuthorEditorNewHtml obtain a block of html to populate a dialog for adding an author or editor
 to a new publication form, where a publication record does not yet exist.
 @param position the position of the author/editor to identify the controls to which to add values,
  similar role, but not identical to publication_author_name.author_position, which is a single counter.
 @param role the role in which to add new agents, allowed values authors or editors.
 @return html form for a dialog to add authors/editors to populate controls on a new publication form.
---->
<cffunction name="addAuthorEditorNewHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="position" type="string" required="yes">
	<cfargument name="role" type="string" required="yes">
	<cfset variables.position = arguments.position>
	<cfset variables.role = arguments.role>

	<cfthread name="getAuthorEditorHtmlThread">
		<cftry>
			<cfif role EQ "authors">
				<cfset roleLabel = "Author">
				<cfset targetRole = "author">
			<cfelseif role EQ "editors">
				<cfset roleLabel = "Editor">
				<cfset targetRole = "editor">
			<cfelse>
				<cfthrow message="Add Author or Editor Dialog must be created with role='authors' or role='editors'. [#encodeForHtml(role)#] is not an acceptable value.">
			</cfif>
			<cfif position EQ 1 AND targetRole EQ "author">
				<!--- there is no first author if we are adding authors --->
				<cfset newpos=1>
				<cfset nameform="author">
			<cfelse>
				<!--- there is at least a first author if we are adding authors or we are adding editors --->
				<cfset newpos=2>
				<cfset nameform="second author">
			</cfif>
			<cfoutput>
				<div class="form-row">
					<div class="col-12">
						<h3 class="h4" >Add #roleLabel#</h3>
						<div class="form-row">
							<div class="col-12 col-md-5">
								<label for="agent_name" class="data-entry-label">Pick an agent to add as an #roleLabel#</label>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="agent_name" id="agent_name" class="form-control rounded-right data-entry-input form-control-sm reqdClr" aria-label="Agent Name" aria-describedby="agent_name_label" value="" required>
									<input type="hidden" name="agent_id" id="agent_id" value="">
								</div>
							</div>
							<div class="col-12 col-md-3">
								<label for="agent_view" class="data-entry-label">Selected Agent</label>
								<div id="agent_view"></div>
							</div>
							<div class="col-12 col-md-2">
								<label for="agent_name_control" class="data-entry-label">#roleLabel#</label>
								<div id="author_name_control"></div>
								<input type="hidden" name="author_name_id" id="author_name_id" value="">
								<input type="hidden" name="next_author_position" id="next_author_position" value="#position#">
							</div>
							<div class="col-12 col-md-2">
								<a href="/agents/editAgent.cfm?action=new" aria-label="add a new agent" class="btn btn-xs btn-secondary" target="_blank" >New Agent</a>
							</div>
						</div>
						<div class="form-row">
							<div class="col-12 col-md-3">
								<button class="btn btn-xs btn-primary disabled" id="addButton" onclick="setAuthorValues();" disabled >Add as #roleLabel# <span id="position_to_add_span">#position#</span></button>
							</div>
							<div class="col-12 col-md-9" id="missingNameDiv">
								Missing the <span id="form_to_add_span">#nameform#</span> form of the author name for this agent.
								<button class="btn btn-xs btn-primary disabled" id="addNameButton" onclick="showAddAuthorNameDialog();" disabled >Add</button>
							</div>
							<script>
								$(document).ready(function() {
									$('##missingNameDiv').hide();
									$('##agent_name').focus();
								});
								function showAddAuthorNameDialog() {
									console.log($('##agent_id').val());
									console.log($('##next_author_position').val()); 
									openAddAgentNameOfTypeDialog('addNameTypeDialogDiv', $('##agent_id').val(), $('##form_to_add_span').html());
								};
								function setAuthorValues() { 
									var idcontrol = "#targetRole#_name_id_#position#";
									var namecontrol = "#targetRole#_name_#position#";
									$('##'+idcontrol).val($('##author_name_id').val());
									$('##'+namecontrol).val($('##author_name_control').html());
									$('##addAuthorEditorDialogDiv').dialog('close');
									$('##'+namecontrol).attr("disabled","disabled");
								};
							</script>
							<div id="addNameTypeDialogDiv"></div>
							<script>
								$(document).ready(function() {
									makeRichAuthorPicker('agent_name', 'agent_id', 'agent_name_icon', 'agent_view', null, 'author_name_control','author_name_id',$('##next_author_position').val(),"#targetRole#");
								});
							</script>
						</div>
						<div class="col-12" id="listOfAuthorsDiv">
							<ol id="authorListOnDialog">
							</ol>
						</div>
					</div>
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
	<cfthread action="join" name="getAuthorEditorHtmlThread" />
	<cfreturn getAuthorEditorHtmlThread.output>
</cffunction>

<!--- addAgentNameOfTypeHtml return html to populate a dialog for adding agent
  names of type author and type second author to an agent, integrated into the 
  add authors/editors to a publication workflow.
 @param agent_id the agent to which to add an agent name.
 @param agent_name_type the type of name to add to the agent, selects from list
  in picklist and other types can be added.
 @return html form for a dialog to add names to an agent.
---->
<cffunction name="addAgentNameOfTypeHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="agent_name_type" type="string" required="yes">
	<cfset variables.agent_id = arguments.agent_id>
	<cfset variables.agent_name_type = arguments.agent_name_type>
	<cfthread name="addAgentNameOfTypeHtmlThread">
		<cftry>
			<cfquery name="ctNameType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					agent_name_type name_type
				FROM ctagent_name_type 
				WHERE agent_name_type != 'preferred' order by agent_name_type
			</cfquery>
			<cfquery name="getAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAgent_result">
				SELECT 
					MCZBASE.get_agentnameoftype(agent_id) name,
					agent_id,
					decode(edited,1,'*',null) as vetted
				FROM agent
				WHERE
					agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			</cfquery>
			<cfquery name="getNames" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getNames_result">
				SELECT 
					agent_name, agent_name_type
				FROM agent_name
				WHERE
					agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			</cfquery>
			<cfoutput>
				<div class="form-row">
					<div class="col-12">
						<h3 class="h4" >Add Name to Agent #getAgent.name##getAgent.vetted#</h3>
						<div class="h5">Add author (first author) names in the form Last, Initials e.g. "Smith, A.B.".</div>
						<div class="h5">Add second author names in the form Initials Last e.g. "A.B. Smith".</div>
						<div class="h5">The "author" and "second author" names are used for both authors and editors of publications.</div>
						<div class="form-row">
							<div class="col-12 col-md-6">
								<label for="agent_name_type_addNameDlg" class="data-entry-label">Type of Name</label>
								<select name="agent_name_type" id="agent_name_type_addNameDlg" size="1" class="data-entry-select reqdClr" required>
									<cfloop query="ctNameType">
										<cfif variables.agent_name_type IS ctNameType.name_type>
											<cfset selected = "selected='selected'">
										<cfelse>
											<cfset selected = "">
										</cfif>
										<option value="#ctNameType.name_type#" #selected#>#ctNameType.name_type#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-6">
								<label for="agent_name_addNameDlg" class="data-entry-label">Name</label>
								<input name="agent_name" id="agent_name_addNameDlg" value="" class="data-entry-input reqdClr" required>
							</div>
							<div class="col-12 col-md-6">
								<button type="button" onclick="addNameAction();" class="btn btn-xs btn-primary">Add</button>
								<script>
									function addNameAction() { 
										addAuthorName('#getAgent.agent_id#',$('##agent_name_type_addNameDlg').val(),$('##agent_name_addNameDlg').val(),'agent_name_id','addAgentNameFeedback');
									};
								</script>
								<input type="hidden" id="added_agent_name_id" value="">
								<output id="addAgentNameFeedback"></output>
							</div>
							<div class="col-12 col-md-6">
								<h4 class="h5" >Existing Names for this Agent</h4>
								<ul>
									<cfloop query="getNames">
										<li>#getNames.agent_name_type#: #getNames.agent_name#</li>
									</cfloop>
								</ul>
							</div>
						</div>
					</div>
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
	<cfthread action="join" name="addAgentNameOfTypeHtmlThread" />
	<cfreturn addAgentNameOfTypeHtmlThread.output>
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
		<cfif lcase(author_role) EQ "authors">
			<cfset author_role = "author">
		<cfelseif lcase(author_role) EQ "editors">
			<cfset author_role = "editor">
		</cfif>
		<cftry>
			<cfquery name="insertAuthor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insertAuthor_result">
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
			<cfquery name="getId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getId_result">
				SELECT
					publication_author_name_id as id
				FROM 
					publication_author_name
				WHERE
					ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#rowid#">
			</cfquery>
			<cfquery name="report" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="report_result">
				SELECT
					publication_author_name_id as id,
					agent_name.agent_id,
 					agent_name.agent_name
				FROM 
					publication_author_name
					join agent_name on publication_author_name.agent_name_id = agent_name.agent_name_id
				WHERE
					publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getId.id#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "added">
			<cfset row["id"] = "#report.id#">
			<cfset row["agent_name"] = "#report.agent_name#">
			<cfset row["agent_id"] = "#report.agent_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
			<cfquery name="triggerFormatted" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="triggerFormatted_result">
				update publication set last_update_date = CURRENT_TIMESTAMP 
			  where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
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
			<cfquery name="lookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="lookup_result">
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
			<cfquery name="deleteAuthor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteAuthor_result">
				delete from publication_author_name 
				where
					publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_author_name_id#">
			</cfquery>
			<cfif deleteAuthor_result.recordcount NEQ 1>
				<cfthrow message = "error deleting publication_author_name record [#encodeForHtml(publication_author_name_id)#]">
			</cfif>
			<!--- update the ordinal positon of the rest of the list.  --->
			<cfquery name="reorder" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="reorder_result">
				update publication_author_name 
				set author_position=author_position-1 
				where
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.publication_id#">
					and author_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lookup.author_role#">
					and author_position > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.author_position#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">
			<cfset row["updates"] = "#reorder_result.recordcount#">
			<cfset data[1] = row>
			<cftransaction action="commit">
			<cfquery name="triggerFormatted" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="triggerFormatted_result">
				update publication set last_update_date = CURRENT_TIMESTAMP 
				where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.publication_id#">
			</cfquery>
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
			<cfquery name="lookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="lookup_result">
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
				<cfquery name="lookupAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="lookupAgent_result">
					SELECT
						agent.agent_id,
						fan.agent_name_id first_author_agent_name_id,
						san.agent_name_id second_author_agent_name_id
					FROM
						agent_name author_agent_name
						join agent on author_agent_name.agent_id = agent.agent_id
						left join agent_name fan on agent.agent_id = fan.agent_id and fan.agent_name_type = 'author'
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
					<cfquery name="up" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="up_result">
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
						<cfquery name="mv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="mv_result">
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
						<cfquery name="mv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="mv_result">
							UPDATE
								publication_author_name
							SET
								author_position = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target#">
							WHERE
								publication_author_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_author_name_id#">
						</cfquery>
					</cfif>
					<!--- move everyone above author_position down by 1 --->
					<cfquery name="dn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="dn_result">
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
			<cfquery name="triggerFormatted" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="triggerFormatted_result">
				update publication set last_update_date = CURRENT_TIMESTAMP 
				where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.publication_id#">
			</cfquery>
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
	<cfargument name="publication_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="updateAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateAuthor_result">
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
			<cfquery name="triggerFormatted" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="triggerFormatted_result">
				update publication set last_update_date = CURRENT_TIMESTAMP 
				where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
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

<cffunction name="getAnnotationsForPubHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfthread name="getAnnotationsForPubThread">
		<cftry>
			<cfoutput>
				<h2 class="h3">Annotations:</h2>
				<cfquery name="existingAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select count(*) cnt from annotations
					where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				</cfquery>
				<cfif #existingAnnotations.cnt# GT 0>
					<button type="button" aria-label="Annotate" id="annotationDialogLauncher"
						class="btn btn-xs btn-info" value="Annotate this record and view existing annotations"
						onClick=" openAnnotationsDialog('annotationDialog','publication',#publication_id#,reloadPublicationAnnotations);">Annotate/View Annotations</button>
				<cfelse>
					<button type="button" aria-label="Annotate" id="annotationDialogLauncher"
						class="btn btn-xs btn-info" value="Annotate this record"
						onClick=" openAnnotationsDialog('annotationDialog','publication',#publication_id#,reloadPublicationAnnotations);">Annotate</button>
				</cfif>
				<div id="annotationDialog"></div>
				<cfif #existingAnnotations.cnt# gt 0>
					<cfif #existingAnnotations.cnt# EQ 1>
						<cfset are = "is">
						<cfset s = "">
					<cfelse>
						<cfset are = "are">
						<cfset s = "s">
					</cfif>
					<p>There #are# #existingAnnotations.cnt# annotation#s# on this publications record</p>
					<cfquery name="AnnotationStates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select count(*) statecount, state from annotations
						where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
						group by state
					</cfquery>
					<ul>
						<cfloop query="AnnotationStates">
							<li>#state#: #statecount#</li>
						</cfloop>
					</ul>
				<cfelse>
					<p class="my-2">There are no annotations on this publication record</p>
				</cfif>
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
	<cfthread action="join" name="getAnnotationsForPubThread" />
	<cfreturn getAnnotationsForPubThread.output>
</cffunction>


<cffunction name="getAttributeAddDialogHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfargument name="attribute" type="string" required="no">
	<cfset variables.publication_id = arguments.publication_id>
	<cfif isdefined("attribute")>
		<cfset variables.attribute = arguments.attribute>
	<cfelse>
		<cfset variables.attribute = "">
	</cfif>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getAttributesAddDialogThread#tn#">
		<cftry>
			<cfquery name="available_pub_att" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT ctpublication_attribute.publication_attribute, 
					description
				FROM ctpublication_attribute 
				WHERE
					ctpublication_attribute.publication_attribute NOT IN (
						SELECT distinct publication_attribute 
						FROM publication_attributes
						WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.publication_id#">
					)
				ORDER BY ctpublication_attribute.publication_attribute
			</cfquery>
			<cfoutput>
				<h3 class="h4" >Add Publication Attribute</h3>
				<div class="form-row">
					<div class="col-12">
						<cfset id="#variables.publication_id#_#RandRange(1,10000)#" >
						<label for="attr_#id#" class="data-entry-label">Attribute</a>
						<select name="publication_attribute" id="attr_#id#" 
							class="data-entry-select w-100 reqdClr" required
							onChange='loadPubAttributeControl($("##attr_#id#").val(),"","pub_att_value","attr_value_#id#","input_block_#id#");'
						>
							<cfif len(variables.attribute) EQ 0>
								<option></option>
							</cfif>
							<cfloop query="available_pub_att">
								<cfif len(variables.attribute) GT 0 AND variables.attribute EQ available_pub_att.publication_attribute>
									<cfset selected="selected">
								<cfelse>
									<cfset selected="">
								</cfif>
								<cfif len(available_pub_att.description) GT 0>
									<cfset descr = " (#available_pub_att.description#)">
								<cfelse>
									<cfset descr = "">
								</cfif>
								<option value="#available_pub_att.publication_attribute#" #selected#>#available_pub_att.publication_attribute##descr#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12">
						<label for="attr_value_#id#" class="data-entry-label">Value</a>
						<cfif len(variables.attribute) GT 0>
							<cfset inputBlockContent = getPubAttributeControl(attribute="#variables.attribute#",value="",name="pub_att_value",id="attr_value_#id#",required_field="true")>
							<div id="input_block_#id#">#inputBlockContent#</div>
						<cfelse>
							<div id="input_block_#id#">
								<input id="attr_value_#id#" name="pub_att_value" class="data-entry-input disabled" value="" disabled>
							</div>
						</cfif>
					</div>
					<div class="col-12">
						<button class="btn btn-xs btn-primary" onclick="saveNewAttribute('#variables.publication_id#',$('##attr_#id#').val(),$('##attr_value_#id#').val(),'saveAttributeFeedback',reloadAttributes);">Save</button>
						<output id="saveAttributeFeedback"></output>
					</div>
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
	<cfthread action="join" name="getAttributesAddDialogThread#tn#" />
	<cfreturn cfthread["getAttributesAddDialogThread#tn#"].output>
</cffunction>

<!--- obtain html for a set of input controls for the attributes relevant to a 
  given publication based on the type of publication 
  @param publication_id the primary key value for the publication for which to return inputs
  @return html with a set of inputs or an http 500 error
--->
<cffunction name="getPubAttControls" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getPubAttControlsThread#tn#">
		<cftry>
			<cfquery name="getType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getType_result">
				SELECT 
					publication_type,
					get_publication_attribute(publication_id,'journal name') as jtitle
				FROM publication
				WHERE 
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
			<cfset isMCZPub = false>
			<cfif len(getType.jtitle) GT 0>
				<cfquery name="MCZpub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="MCZpub_result">
					SELECT
						publication
					FROM
						ctmczp_publication
					WHERE
						publication = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getType.jtitle#">
				</cfquery>
				<cfif MCZpub.recordcount EQ 1>
					<cfset isMCZpub = true>
				<cfelse>
					<cfset isMCZpub = false>
				</cfif>
			</cfif>
			<cfif NOT isMCZpub>
				<!--- check if the publication has an MCZ Publication attribute (as in books published by the MCZ) --->
				<cfquery name="getMCZ" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getMCZ_result">
					SELECT count(*) ct
					FROM publication_attributes
					WHERE 
						publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
						AND
						publication_attribute = 'MCZ publication'
				</cfquery>
				<cfif getMCZ.ct GT 0>
					<cfset isMCZpub = true>
				</cfif>
			</cfif>
			<cfquery name="getAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAttributes_result">
				SELECT publication_attribute
				FROM cf_pub_type_attribute
				WHERE
					publication_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getType.publication_type#">
				ORDER BY ordinal ASC
			</cfquery>
			<cfoutput>
				<h2 class="h3">Attributes <output id="attributeControlsFeedbackDiv" class="small"></output></h2>
				<div class="form-row mb-2">
					<cfloop query="getAttributes">
						<cfquery name="getDescription" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getDescription_result">
							SELECT description
							FROM ctpublication_attribute 
							WHERE 
								publication_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getAttributes.publication_attribute#">
						</cfquery>
						<cfquery name="getAttValue" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAttValue_result">
							SELECT
								publication_attribute_id, 
								pub_att_value
							FROM publication_attributes
							WHERE 
								publication_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getAttributes.publication_attribute#">
								and
								publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
						</cfquery>
		
						<cfif getAttValue.recordcount EQ 1>
							<cfset value = getAttValue.pub_att_value>
						<cfelse>
							<cfset value = "">
						</cfif>
	
						<div class="col-12 col-md-4 pb-2">
							<cfset id = "input_#REReplace(CreateUUID(), "[-]", "", "all")#" >
							<label class="data-entry-label" style="font-weight:520;" for="#id#">
								#getAttributes.publication_attribute# <span class="small font-weight-normal">#getDescription.description#</span>
							</label>
							<cfset control = getPubAttributeControl(attribute = "#getAttributes.publication_attribute#",value="#value#",name="#getAttributes.publication_attribute#",id="#id#")>
							#control#
							<input type="hidden" id="id_#id#" value="#getAttValue.publication_attribute_id#">
							<script>	
								$('###id#').change(function(event){ 
									console.log($('###id#').val()); 
									$('##attributeControlsFeedbackDiv').html("Saving...");
									$('##attributeControlsFeedbackDiv').addClass('text-warning');
									$('##attributeControlsFeedbackDiv').removeClass('text-success');
									$('##attributeControlsFeedbackDiv').removeClass('text-danger');
									if ($("##id_#id#").val()=="") {  
										saveNewAttribute("#publication_id#", "#getAttributes.publication_attribute#", $("###id#").val(), "attributeControlsFeedbackDiv", reloadAttributes,"id_#id#"); 
									} else {
										if ($("###id#").val() == "") { 
											deleteAttribute($("##id_#id#").val(),"#getAttributes.publication_attribute#", reloadAttributes, "attributeControlsFeedbackDiv","id_#id#");
										} else {  
											saveAttribute($("##id_#id#").val(), "#publication_id#", "#getAttributes.publication_attribute#", $("###id#").val(), "attributeControlsFeedbackDiv", reloadAttributes, null); 
										}
									}
								});
							</script>
						</div>
					</cfloop>
				</div>

				<cfif isMCZpub>
					<cfquery name="getMCZAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getMCZAttributes_result">
						SELECT publication_attribute,
							description
						FROM ctpublication_attribute 
						WHERE
							mcz_publication_fg = 1
							OR
							publication_attribute = 'issue'
					</cfquery>
					<div class="form-row mb-2">
						<cfloop query="getMCZAttributes">
							<cfquery name="getAttValue" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAttValue_result">
								SELECT
									publication_attribute_id, 
									pub_att_value
								FROM publication_attributes
								WHERE 
									publication_attributes.publication_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMCZAttributes.publication_attribute#">
									and
									publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
							</cfquery>
			
							<cfif getAttValue.recordcount EQ 1>
								<cfset value = getAttValue.pub_att_value>
							<cfelse>
								<cfset value = "">
							</cfif>
		
							<div class="col-12 col-md-4">
								<label class="data-entry-label">#getMCZAttributes.publication_attribute# <span class="small">#getMCZAttributes.description#</span></label>
								<cfset id = "input_#REReplace(CreateUUID(), "[-]", "", "all")#" >
								<cfset control = getPubAttributeControl(attribute = "#getMCZAttributes.publication_attribute#",value="#value#",name="#getMCZAttributes.publication_attribute#",id="#id#")>
								#control#
								<input type="hidden" id="id_#id#" value="#getAttValue.publication_attribute_id#">
								<script>	
									$('###id#').change(function(event){ 
										console.log($('###id#').val()); 
										$('##attributeControlsFeedbackDiv').html("saving...");
										if ($("##id_#id#").val() == "") {  
											saveNewAttribute("#publication_id#", "#getMCZAttributes.publication_attribute#", $("###id#").val(), "attributeControlsFeedbackDiv", reloadAttributes, "id_#id#"); 
										} else {
											if ($("###id#").val() == "") { 
												deleteAttribute($("##id_#id#").val(),"#getMCZAttributes.publication_attribute#", reloadAttributes, "attributeControlsFeedbackDiv","id_#id#");
											} else {  
												saveAttribute($("##id_#id#").val(), "#publication_id#", "#getMCZAttributes.publication_attribute#", $("###id#").val(), "attributeControlsFeedbackDiv", reloadAttributes, null); 
											}
										}
									});
								</script>
							</div>
						</cfloop>
					</div>
				</cfif>
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
	<cfthread action="join" name="getPubAttControlsThread#tn#" />
	<cfreturn cfthread["getPubAttControlsThread#tn#"].output>
</cffunction>

<!--- obtain html for a set of input controls for the attributes relevant to a 
  given type of publication for the creation of a new publication record.
  these controls expect to be embedded in the new publication form and do not auto save.
  @param publication_type the type of publication for which to return inputs.
  @return html with a set of inputs or an http 500 error
--->
<cffunction name="getNewPubAttControls" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_type" type="string" required="yes">

	<cfset variables.publication_type = arguments.publication_type>

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getNewPubAttThread#tn#">
		<cftry>
			<cfset isMCZPub = false>
			<cfquery name="getAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAttributes_result">
				SELECT publication_attribute,
					regexp_replace(publication_attribute,'[^A-Za-z]','_') as attribute_name
				FROM cf_pub_type_attribute
				WHERE
					publication_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.publication_type#">
				ORDER BY ordinal ASC
			</cfquery>
			<cfoutput>
				<h2 class="h3">Attributes <output id="attributeControlsFeedbackDiv"></output></h2>
				<div class="form-row mb-2">
					<cfset i = 0>
					<cfloop query="getAttributes">
						<cfset i = i+1>
						<cfquery name="getDescription" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getDescription_result">
							SELECT description
							FROM ctpublication_attribute 
							WHERE 
								publication_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getAttributes.publication_attribute#">
						</cfquery>
						<div class="col-12 col-md-4">
							<cfset id = "input_#REReplace(CreateUUID(), "[-]", "", "all")#" >
							<label class="data-entry-label" for="#id#">#getAttributes.publication_attribute# <span class="small">#getDescription.description#</span></label>
							<cfset control = getPubAttributeControl(attribute = "#getAttributes.publication_attribute#",value="",name="#getAttributes.attribute_name#",id="#id#")>
							#control#
						</div>
					</cfloop>
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
	<cfthread action="join" name="getNewPubAttThread#tn#" />
	<cfreturn cfthread["getNewPubAttThread#tn#"].output>
</cffunction>

<!--- obtain html for an input control for a publication attribute 
	@param attribute the attribute for which to return an input
	@param value the value to set for the attribute in the input
	@param name the name for the input used when submitting the input in a form
	@param id the id in the DOM for the input, without a leading # selector
	@param required if true then set the input as required with a required color background.
	@return html for a text input, a select input, or a text input bound to an autocomplete, depending
		on the value of ctpublication_attribute.control for the specified attribute.
--->
<cffunction name="getPubAttributeControl" access="remote" returntype="string" returnformat="plain">
	<cfargument name="attribute" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="id" type="string" required="yes">
	<cfargument name="required_field" type="string" required="no">

	<cfif isdefined("required_field") AND required_field EQ "true">
		<cfset reqdClr = "reqdClr">
		<cfset req = "required">
	<cfelse>
		<cfset reqdClr = "">
		<cfset req = "">
	</cfif>
	<!--- base response is a text input --->
	<cfset retval = "<input type='text' name='#encodeForHtml(name)#' id='#encodeForHtml(id)#' class='data-entry-input #reqdClr#' #req# value='#encodeForHtml(value)#'>" > <!--- " --->
	<cftry>
		<cfquery name="getAttControl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAttControl_result">
			SELECT control
			FROM ctpublication_attribute
			WHERE publication_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute#">
		</cfquery>
		<!--- is there is a code table specified controlling values for this attribute --->
		<cfif len(getAttControl.control) gt 0>
			<!--- handle special cases of autocompletes ---->
			<cfif getAttControl.control EQ 'CTJOURNAL_NAME.JOURNAL_NAME'>
				<!--- bind journal autocomplete to input --->
				<cfset retval = "#retval#<script>$(document).ready(function() { makeJournalAutocomplete('#encodeForHtml(id)#'); });</script>"><!--- " --->
			<cfelse>
				<!--- return a select input with picklist from controlled vocabulary instead --->
				<cfset controlBits = listToArray(getAttControl.control,'.')>
				<cfif ArrayLen(controlBits) EQ 2>
					<!--- support TABLE.FIELD structure for control as well as TABLE --->
					<cfquery name="getVocabulary" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getVocabulary_result">
						SELECT #controlBits[2]# 
						FROM #controlBits[1]#
					</cfquery>
				<cfelse>
					<cfquery name="getVocabulary" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getVocabulary_result">
						SELECT * 
						FROM #getAttControl.control#
					</cfquery>
				</cfif>
				<!--- exclude the standard code table columns description and collection_cde from the vocabulary if request was just for TABLE and query selected * --->
				<cfset columnList = getVocabulary.columnlist>
				<cfif listcontainsnocase(columnList,"description")>
					<cfset columnList=listdeleteat(columnList,listfindnocase(columnList,"description"))>
				</cfif>
				<cfif listcontainsnocase(columnList,"collection_cde")>
					<cfset columnList=listdeleteat(columnList,listfindnocase(columnList,"collection_cde"))>
				</cfif>
				<cfif listlen(columnList) is 1>
					<!--- there is one column to use, we know what to do --->
					<cfset retval = "<select name='#encodeForHtml(name)#' id='#encodeForHtml(id)#' class='data-entry-select #reqdClr#' #req#>" > <!--- " --->
					<cfif req NEQ "required">
						<cfset retval =  "#retval#<option value=''></option>"> <!--- allow blank option for non-required fields --->
					</cfif>
					<cfloop query="getVocabulary">
						<cfset ctValue = getVocabulary[columnList]>
						<cfif value EQ ctValue>
							<cfset selected = "selected">
						<cfelse>
							<cfset selected = "">
						</cfif>
						<cfset retval = "#retval#<option value='#ctValue#' #selected#>#ctValue#</option>"> <!--- " --->
					</cfloop>
					<cfset retval = "#retval#</select>"> <!--- " --->
				<cfelse>
					<!--- extra columns in this code table, needs to be specified as TABLE.FIELD not TABLE in ctpublication_attribute.control --->
					<!--- we'll failover to the text input without a control ---->
				</cfif>
			</cfif>
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfset retval="<div>Error in #function_called#: #error_message#</div>"> <!--- " --->
	</cfcatch>
	</cftry>
	<cfreturn retval>
</cffunction>

<cffunction name="getAttributeEditDialogHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_attribute_id" type="string" required="yes">
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getAttributesEditDialogThread#tn#">
		<cftry>
			<cfquery name="getAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAttribute_result">
				SELECT
					publication_attribute_id,
					publication_id,
					publication_attribute,
					pub_att_value
				FROM publication_attributes 
				WHERE publication_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_attribute_id#">
			</cfquery>
			<cfif getAttribute.recordcount NEQ 1>
				<cfthrow message="No publication_attribute record found for specified key [#encodeForHtml(publication_attribtue_id)#]">
			</cfif>
			<cfquery name="getType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getType_result">
				SELECT publication_type
				FROM publication
				WHERE 
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAttribute.publication_id#">
			</cfquery>
			<cfloop query="getAttribute">
				<cfquery name="available_pub_att" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT ctpublication_attribute.publication_attribute, 
						description
					FROM ctpublication_attribute 
					WHERE
						(
							ctpublication_attribute.publication_attribute NOT IN (
								SELECT distinct publication_attribute 
								FROM publication_attributes
								WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAttribute.publication_id#">
							)
							OR
							ctpublication_attribute.publication_attribute NOT IN (
								SELECT publication_attribute
								FROM cf_pub_type_attribute
								WHERE
									publication_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getType.publication_type#">
							)
						) AND 
						mcz_publication_fg = 0
					ORDER BY ctpublication_attribute.publication_attribute
				</cfquery>
				<cfoutput>
					<h3 class="h4" >Edit Publication Attribute</h3>
					<div class="form-row">
						<div class="col-12">
							<cfset id=publication_attribute_id>
							<label for="attr_#id#" class="data-entry-label">Attribute</a>
							<select name="publication_attribute" id="attr_#id#" 
								class="data-entry-select w-100 reqdClr" required 
								onChange='loadPubAttributeControl($("##attr_#id#").val(),"#pub_att_value#","pub_att_value","attr_value_#id#","input_block_#id#");'
							>
								<option value="#getAttribute.publication_attribute#" selected>#getAttribute.publication_attribute#</option>
								<cfloop query="available_pub_att">
									<cfif len(available_pub_att.description) GT 0>
										<cfset descr = " (#available_pub_att.description#)">
									<cfelse>
										<cfset descr = "">
									</cfif>
									<option value="#available_pub_att.publication_attribute#">#available_pub_att.publication_attribute##descr#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12">
							<label for="attr_value_#id#" class="data-entry-label">Value</a>
							<cfset inputBlockContent = getPubAttributeControl(attribute="#getAttribute.publication_attribute#",value="#pub_att_value#",name="pub_att_value",id="attr_value_#id#",required_field="true")>
							<div id="input_block_#id#">#inputBlockContent#</div>
						</div>
						<div class="col-12">
							<script>
								function closeDialog#id#() { 
									$('##attEditDialog_#publication_attribute_id#').dialog('close');
								}
							</script>
							<button class="btn btn-xs btn-primary" onclick="saveAttribute(
									'#publication_attribute_id#',
									'#getAttribute.publication_id#',
									$('##attr_#id#').val(),
									$('##attr_value_#id#').val(),
									'saveFeedback_#id#',
									reloadAttributes,closeDialog#id#); 
								">Save</button>
							<output id="saveFeedback_#id#"></output>
						</div>
					</div>
				</cfoutput>
			</cfloop>
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
	<cfthread action="join" name="getAttributesEditDialogThread#tn#" />
	<cfreturn cfthread["getAttributesEditDialogThread#tn#"].output>
</cffunction>

<!--- obtain a block of html listing attributes for a publication and allowing for editing of those atrributes 
@param publication_id the publication for which to list attribtues.
@param show_all if provided with any value, shows all attributes with a value, not excluding those expected 
  for the publication type.
@return html suitable for the edit publication page.
--->
<cffunction name="getAttributesForPubHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfargument name="show_all" type="string" required="no">

	<cfif isDefined("show_all") and len(show_all) GT 0>
		<cfset variables.show_all = true>
	<cfelse>
		<cfset variables.show_all = false>
	</cfif>
	<cfthread name="getAttributesForPubThread">
		<cftry>
			<cfquery name="getType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getType_result">
				SELECT publication_type
				FROM publication
				WHERE 
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
			<cfquery name="ctpublication_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select publication_attribute from ctpublication_attribute order by publication_attribute
			</cfquery>
			<cfquery name="atts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="atts_result">
				SELECT
					publication_attribute_id,
					publication_id,
					publication_attribute,
					pub_att_value
				FROM publication_attributes 
				WHERE 
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
					<cfif NOT variables.show_all>
						AND
						publication_attribute NOT IN (
							SELECT publication_attribute
							FROM cf_pub_type_attribute
							WHERE
								publication_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getType.publication_type#">
						)
					</cfif>
			</cfquery>
			<cfoutput>
				<h2 class="h3">Additional Attributes</h2>
				<button class="btn btn-xs btn-primary" onclick="openAddAttributeDialog('attAddDialogDiv','#publication_id#','',reloadAttributes);">Add</button>
				<div id="attAddDialogDiv"></div>
				<ul>
					<cfloop query="atts">
						<li>
							#atts.publication_attribute#: #atts.pub_att_value#
							<input type="hidden" id="id_#atts.publication_attribute#" value="#atts.publication_attribute_id#">
							<button class="btn btn-xs btn-secondary" onclick="openEditAttributeDialog('attEditDialog_#atts.publication_attribute_id#','#atts.publication_attribute_id#','#atts.publication_attribute#',reloadAttributes);">Edit</button>
							<button class="btn btn-xs btn-warning" onclick="deleteAttribute(#atts.publication_attribute_id#,'#atts.publication_attribute#',reloadAllAttributes,null,'id_#atts.publication_attribute#');">Delete</button>
						</li>
						<div id="attEditDialog_#atts.publication_attribute_id#"></div>
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

<!--- deleteAttribute delete a publication_attribute record.
  @param publication_attribute_id the primary key value of the row to delete.
  @return a structure with status=deleted
    or if an exception was raised, an http response with http statuscode of 500.
--->
<cffunction name="deleteAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_attribute_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfif len(publication_attribute_id) EQ 0>
				<cfthrow message="Attempt to delete a publication attribute with an empty publication_attribute_id">
			</cfif>
			<cfquery name="lookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="lookup_result">
				SELECT publication_id
				FROM publication_attributes
				WHERE
					publication_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_attribute_id#">
			</cfquery>
			<cfset publication_id = lookup.publication_id>
			<!--- delete the target attribute --->
			<cfquery name="deleteAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteAttribute_result">
				delete from publication_attributes
				where
				publication_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_attribute_id#">
			</cfquery>
			<cfif deleteAttribute_result.recordcount NEQ 1>
				<cfthrow message = "error deleting publication_attribute record [#encodeForHtml(publication_attribute_id)#]">
			</cfif>
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">
			<cfset data[1] = row>
			<cftransaction action="commit">
			<cfquery name="triggerFormatted" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="triggerFormatted_result">
				update publication set last_update_date = CURRENT_TIMESTAMP 
				where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookup.publication_id#">
			</cfquery>
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

<!--- updateAttribute update a publication_attribute record.
  @param publication_attribute_id the primary key value of the row to update.
  @param publication_id the publication to which the attribute applies (optional,
   as the likely case is an update of attribute value for a record, rather than changing
   the publication to which an attribute is applied).
  @param publication_attribute the attribute to update.
  @param pub_att_value the value of the attribute to update.
  @return a structure with status=updated and id=publication_attribute_id
    or if an exception was raised, an http response with http statuscode of 500.
--->
<cffunction name="updateAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_attribute_id" type="string" required="yes">
	<cfargument name="publication_id" type="string" required="no">
	<cfargument name="publication_attribute" type="string" required="yes">
	<cfargument name="pub_att_value" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- update the target attribute --->
			<cfquery name="updateAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateAttribute_result">
				UPDATE publication_attributes
				SET
					<cfif isDefined("publication_id") AND len(publication_id) GT 0 >
						publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">,
					</cfif>
					publication_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_attribute#">,
					pub_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pub_att_value#">
				WHERE
					publication_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_attribute_id#">
			</cfquery>
			<cfif updateAttribute_result.recordcount NEQ 1>
				<cfthrow message = "error updating publication_attribute record [#encodeForHtml(publication_attribute_id)#]">
			</cfif>
			<cfset row = StructNew()>
			<cfset row["status"] = "updated">
			<cfset row["id"] = "#publication_attribute_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
			<cfquery name="triggerFormatted" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="triggerFormatted_result">
				update publication set last_update_date = CURRENT_TIMESTAMP 
				where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
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

<!--- addAttribute insert a new publication_attribute record.
  @param publication_id the publication to which the attribute applies.
  @param publication_attribute the attribute to add.
  @param pub_att_value the value of the attribute to add.
  @return a structure with status=inserted and id=publication_attribute_id
    or if an exception was raised, an http response with http statuscode of 500.
--->
<cffunction name="addAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_id" type="string" required="yes">
	<cfargument name="publication_attribute" type="string" required="yes">
	<cfargument name="pub_att_value" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- insert  attribute --->
			<cfquery name="insertAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insertAttribute_result">
				insert into publication_attributes (
					publication_id,
					publication_attribute,
					pub_att_value
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_attribute#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pub_att_value#">
				)
			</cfquery>
			<cfif insertAttribute_result.recordcount NEQ 1>
				<cfthrow message = "error inserting publication_attribute record [#encodeForHtml(publication_attribute)#]">
			</cfif>
			<cfset rowid = insertAttribute_result.generatedkey>
			<cftransaction action="commit">
			<cfquery name="getId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getId_result">
				SELECT
					publication_attribute_id as id
				FROM 
					publication_attributes
				WHERE
					ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#rowid#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "inserted">
			<cfset row["id"] = "#getId.id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
			<cfquery name="triggerFormatted" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="triggerFormatted_result">
				update publication set last_update_date = CURRENT_TIMESTAMP 
				where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
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

<!---------------------------------------------------------------------------------------------------------->

<!--- getMediaForPubHtml obtain a block of html for editing media related to a publication.
 @param publication_id the publication for which to obtain media
 @return html listing media for the specified publication in a form for editing
---->
<cffunction name="getMediaForPubHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="publication_id" type="string" required="yes">
	<cfthread name="getMediaForPubThread">

		<cftry>
			<cfoutput>
				<cfquery name="getMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getMedia_result">
					SELECT distinct
						media.media_id, media_relations_id
					FROM
						media 
						join media_relations on media.media_id=media_relations.media_id
					WHERE
						media_relations.media_relationship like '%publication' and
						media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				</cfquery>
				<cfif getMedia.recordcount gt 0>
					<h2 class="h3">Media</h2>
					<div class="col-12 row">
						<cfloop query="getMedia">
							<div class="col-12 col-sm-6 col-md-4 col-xl-3 bg-light border rounded">
								<div id="mediaBlock#media_id#">
									<cfset mediablock= getMediaBlockHtmlUnthreaded(media_id="#media_id#",size="400",captionAs="textMid")>
									<input type='button' 
										value="Remove" aria-label="unlink this media record from this publication"
										class="btn btn-xs btn-warning"
										onClick="confirmDialog('Remove Relationship to this Media record?','Remove?', function() { deleteMediaRelation('#getMedia.media_relations_id#',reloadPublicationMedia); } );">
								</div>
							</div>
						</cfloop>
					</div>
				<cfelse>
					<p>There are no media records related to this publication</p>
				</cfif>

				<div class="col-12 row">
					<div class="col-12 row">
					<input type='button' 
						value="Create Media" 
						class="btn btn-xs btn-secondary"
						onClick="opencreatemediadialog('addMediaDialog',$('##fullCitationPlain').val(),'#publication_id#','shows publication',reloadPublicationMedia);" >
					<input type='button' 
						value='Link Media' 
						class='btn btn-xs btn-secondary mx-2' 
						onClick="openlinkmediadialog('linkMediaDialog','Link media to '+$('##fullCitationPlain').val() ,'#publication_id#','shows publication',reloadPublicationMedia); " >
				</div>
				<div id='addMediaDialog'></div>
				<div id='linkMediaDialog'></div>

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
	<cfthread action="join" name="getMediaForPubThread" />
	<cfreturn getMediaForPubThread.output>
</cffunction>

<!--- createCitation create a new citation record 
 @param publication_id the publication to which the citation applies
 @param collection_object_id the collection object to which the citation applies
 @param cited_taxon_name_id the taxon name cited in the citation
 @param occurs_page_number the page number on which the citation occurs in the publication
 @param type_status the type status of the citation, if any
 @param citation_remarks any remarks about the citation
 @param citation_page_uri the URI of the page in the publication where the citation occurs
 @return a structure with status=inserted and id=citation_id
	or if an exception was raised, an http response with http statuscode of 500.
--->
<cffunction name="createCitation" access="remote" returntype="any" returnformat="json">
	<cfargument name="publication_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="cited_taxon_name_id" type="string" required="yes">
	<cfargument name="occurs_page_number" type="string" required="no" default="">
	<cfargument name="type_status" type="string" required="no" default="">
	<cfargument name="citation_remarks" type="string" required="no" default="">
	<cfargument name="citation_page_uri" type="string" required="no" default="">

	<cfset data = ArrayNew(1)>

	<cftransaction>
		<cftry>
			<cfquery name="newCitation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newCitation_result">
				INSERT INTO citation (
					publication_id,
					collection_object_id,
					cit_current_fg,
					cited_taxon_name_id
					<cfif len(#occurs_page_number#) gt 0>
						,occurs_page_number
					</cfif>
					<cfif len(#type_status#) gt 0>
						,type_status
					</cfif>
					<cfif len(#citation_remarks#) gt 0>
						,citation_remarks
					</cfif>
					<cfif len(#citation_page_uri#) gt 0>
						,citation_page_uri
					</cfif>
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.publication_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">,
					1,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.cited_taxon_name_id#">
					<cfif len(#occurs_page_number#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.occurs_page_number#">
					</cfif>
					<cfif len(#type_status#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.type_status#">
					</cfif>
					<cfif len(#citation_remarks#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.citation_remarks#">
					</cfif>
					<cfif len(#citation_page_uri#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.citation_page_uri#">
					</cfif>
					)
				</cfquery>
				<cfif newCitation_result.recordcount NEQ 1>
					<cfthrow message = "error inserting citation record for publication [#encodeForHtml(arguments.publication_id)#]">
				</cfif>
				<cfset rowid = newCitation_result.generatedkey>
				<!--- TODO Add citation_id to make citation a strong entity --->
				<cfset id = rowid>
				<!---
				<cfquery name="getId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getId_result">
					SELECT
						citation_id as id
					FROM 
						citation
					WHERE
						ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#rowid#">
				</cfquery>	
				<cfset id = getId.id>
				--->
				<cfset row = StructNew()>
				<cfset row["status"] = "inserted">
				<cfset row["id"] = "#id#">
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

<!--- updateCitation update an existing citation record 
 TODO: Add citation_id
 @param publication_id the publication to which the citation applies
 @param collection_object_id the collection object to which the citation applies
 @param cited_taxon_name_id the taxon name cited in the citation
 @param occurs_page_number the page number on which the citation occurs in the publication
 @param type_status the type status of the citation, if any
 @param citation_remarks any remarks about the citation
 @param citation_page_uri the URI of the page in the publication where the citation occurs
 @return a structure with status=inserted and id=citation_id
	or if an exception was raised, an http response with http statuscode of 500.
--->
<cffunction name="updateCitation" access="remote" returntype="any" returnformat="json">
	<cfargument name="original_publication_id" type="string" required="yes">
	<cfargument name="original_collection_object_id" type="string" required="yes">
	<cfargument name="original_cited_taxon_name_id" type="string" required="yes">
	<cfargument name="publication_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="cited_taxon_name_id" type="string" required="yes">
	<cfargument name="type_status" type="string" required="yes">
	<cfargument name="occurs_page_number" type="string" required="no" default="">
	<cfargument name="citation_remarks" type="string" required="no" default="">
	<cfargument name="citation_page_uri" type="string" required="no" default="">

	<cfset data = ArrayNew(1)>

	<cftransaction>
		<cftry>
			<cfquery name="updateCitation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateCitation_result">
				UPDATE citation
				SET 
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.publication_id#">
					,collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
					,cited_taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.cited_taxon_name_id#">
					,type_status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.type_status#">
					<cfif len(#occurs_page_number#) gt 0>
						,occurs_page_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.occurs_page_number#">
					<cfelse>
						,occurs_page_number = NULL
					</cfif>
					<cfif len(#citation_remarks#) gt 0>
						,citation_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.citation_remarks#">
					<cfelse>
						,citation_remarks = NULL
					</cfif>
					<cfif len(#citation_page_uri#) gt 0>
						,citation_page_uri = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.citation_page_uri#">
					<cfelse>
						,citation_page_uri = NULL
					</cfif>
				WHERE 
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.original_publication_id#">
					AND collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.original_collection_object_id#">
					AND cited_taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.original_cited_taxon_name_id#">
			</cfquery>
			<cfif updateCitation_result.recordcount NEQ 1>
				<cfthrow message = "error updating citation record for publication [#encodeForHtml(arguments.publication_id)#]">
			</cfif>
			<cfset id="TODO">
			<cfset row = StructNew()>
			<cfset row["status"] = "updated">
			<cfset row["id"] = "#id#">
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

<!--- deleteCitation deletes a citation record from the database.
 @param cited_taxon_name_id the taxon name id of the cited taxon
 @param collection_object_id the collection object id of the cataloged item
 @param publication_id the publication id of the citation to delete
 @return a JSON object with status = deleted
--->
<cffunction name="deleteCitation" returntype="any" access="remote" returnformat="json">
	<cfargument name="cited_taxon_name_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="publication_id" type="string" required="yes">
	<!--- TODO: Implement citation_id --->

	<cfset data = ArrayNew(1)>
	<cfoutput>
		<cftransaction>
			<cftry>
				<cfquery name="deleteCitation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteCitation_result">
					DELETE FROM citation
					WHERE
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						and publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
						and cited_taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#cited_taxon_name_id#">
				</cfquery>
				<cfif deleteCitation_result.recordcount NEQ 1>
					<cfthrow message = "Error deleting citation record, delete would remove other than one citation record.">
				</cfif>
				<cfset row = StructNew()>
				<cfset row["status"] = "deleted">
				<cfset arrayAppend(data, row)>
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
	</cfoutput>
	<cfreturn serializeJson(data)>
</cffunction>

</cfcomponent>
