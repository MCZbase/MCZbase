<cfinclude template = "includes/_header.cfm">
<cfif action is "nothing">
	<cfif isdefined("publication_id") and len(publication_id) gt 0>
		<cflocation url="SpecimenUsage.cfm?action=search&publication_id=#publication_id#" addtoken="false">
	</cfif>
	<cfset title = "Search for Projects">
   <div class="content_box_pub">
     <h2 class="wikilink">Project Search&nbsp;<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")><img src="/images/info_i_2.gif" onClick="getMCZDocs('Publication or Project Search')" class="likeLink" alt="[ help ]" style="vertical-align:top;"></cfif></h2>
	<form action="SpecimenUsage.cfm" method="post">
		<input name="action" type="hidden" value="search">
		<cfif not isdefined("toproject_id")><cfset toproject_id=""></cfif>
		<cfoutput>
			<input name="toproject_id" type="hidden" value="#toproject_id#">
		</cfoutput>

		<table style="width: 100%;">

				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
              <tr>
					 <td>
						<a  style="padding: .5em 0;display: block;" href="/Project.cfm?action=makeNew">[ New Project ]</a>
		    		 </td>
              </tr>
				</cfif>
              <tr>

				<td>
					<h4>Search for Projects</h4>
					<label for="p_title"><span id="project_publication_title">Title</span></label>
					<input name="p_title" id="p_title" type="text">
					<label for="author"><span id="project_publication_agent">Participant</span></label>
					<input name="author" id="author" type="text">
					<label for="year"><span id="project_publication_year">Year</span></label>
					<input name="year" id="year" type="text">
					<input type="hidden" name="search_type" id="searchPubs" value="projects">

					<h4 style="padding-top: 1em;">Project Details</h4>
					<label for="sponsor"><span id="project_sponsor">Sponsor</span></label>
					<input name="sponsor" id="sponsor" type="text">
					<label for="project_type"><span id="project_type">Type</span></label>
					<select name="project_type" id="project_type">
						<option value=""></option>
						<option value="loan">Uses Specimens</option>
						<option value="loan_no_pub">Uses Specimens, no publication</option>
						<option value="accn">Contributes Specimens</option>
						<option value="both">Uses and Contributes</option>
						<option value="neither">Neither Uses nor Contributes</option>
					</select>
					<label for="descr_len"> Description Min. Length</label>
					<input name="descr_len" id="descr_len" type="text" value="100">
				</td>

			</tr>
			<tr>
				<td colspan="2" align="center" style="padding-top: 2em;">
					<input type="submit" value="Search" class="schBtn">&nbsp;&nbsp;

                    <input type="reset"	value="Clear Form"	class="clrBtn">
				</td>
			</tr>
		</table>
	</form>
</cfif>
<!--</div>-->
<!-------------------------------------------------------------------------------------->
<cfif action is "search">
<cfoutput>
	<cfset title = "Usage Search Results">
	<cfset emptyPubQueryMessage = "">
	<cfset emptyProjQueryMessage = "">

	<cfif not isdefined("search_type")>
		<cfset search_type = "projects">
	</cfif>
	<cfif search_type EQ "projects" OR search_type EQ "both">
	<cfset go="no"><!--- allows addition of a where 1=2 clause if no search term is set, forcing query to have parameters --->
	<cfquery name="projects" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT distinct
					project.project_id,
					project.project_name,
					project.start_date,
					project.end_date,
					agent_name.agent_name,
					project_agent_role,
					agent_position,
					ACKNOWLEDGEMENT,
					s_name.agent_name sponsor_name
				FROM
					project
					left join project_agent on project.project_id = project_agent.project_id
					left join agent_name on project_agent.agent_name_id = agent_name.agent_name_id
					left join project_sponsor on project.project_id = project_sponsor.project_id
					left join agent_name s_name on project_sponsor.agent_name_id = s_name.agent_name_id
				WHERE
					project.project_id is not null
					<cfif isdefined("p_title") AND len(p_title) gt 0>
						<cfset title = "#p_title#">
						<cfset go="yes">
						AND upper(regexp_replace(project.project_name,'<[^>]*>')) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(escapeQuotes(p_title))#%">
					</cfif>
					<cfif isdefined("descr_len") AND len(descr_len) gt 0>
						<cfset go="yes">
						AND project.project_description is not null and length(project.project_description) >= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#descr_len#">
					</cfif>
					<cfif isdefined("author") AND len(author) gt 0>
						<cfset go="yes">
						AND project.project_id IN
							( select project_id FROM project_agent
								WHERE agent_name_id IN
								( select agent_name_id FROM agent_name WHERE
								upper(agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#escapeQuotes(ucase(author))#%"> ))
					</cfif>
					<cfif isdefined("project_type") AND len(project_type) gt 0>
						<cfset go="yes">
						<cfif project_type is "loan">
							AND project.project_id in (
							select project_id from project_trans,loan_item
							where project_trans.transaction_id=loan_item.transaction_id)
						<cfelseif project_type is "accn">
							AND project.project_id in (
								select project_id from project_trans,cataloged_item
								where project_trans.transaction_id=cataloged_item.accn_id)
						<cfelseif project_type is "both">
							AND project.project_id in (
								select project_id from project_trans,loan_item
								where project_trans.transaction_id=loan_item.transaction_id)
							AND project.project_id in (
								select project_id from project_trans,cataloged_item
								where project_trans.transaction_id=cataloged_item.accn_id)
						<cfelseif project_type is "neither">
							AND project.project_id not in (
								select project_id from project_trans,loan_item
								where project_trans.transaction_id=loan_item.transaction_id)
							AND project.project_id not in (
								select project_id from project_trans,cataloged_item
								where project_trans.transaction_id=cataloged_item.accn_id)
						<cfelseif project_type is "loan_no_pub">
							AND project.project_id in (
								select project_id from project_trans,loan_item
								where project_trans.transaction_id=loan_item.transaction_id)
							AND project.project_id not in (
								select project_id from project_publication)
						</cfif>
					</cfif>
					<cfif isdefined("sponsor") AND len(#sponsor#) gt 0>
						<cfset go="yes">
						AND project.project_id IN
						( select project_id FROM project_sponsor
							WHERE agent_name_id IN
							( select agent_name_id FROM agent_name WHERE
							upper(agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(sponsor)#%"> ))
					</cfif>
					<cfif isdefined("year") AND isnumeric(#year#)>
						<cfset go="yes">
							AND (
							 <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#year#"> between to_number(to_char(start_date,'YYYY')) AND to_number(to_char(end_date,'YYYY'))
							)
					</cfif>
					<cfif isdefined("publication_id") AND len(#publication_id#) gt 0>
						<cfset go="yes">
						AND project.project_id in
							(select project_id from project_publication where publication_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">)
					</cfif>
					<cfif isdefined("project_id") AND len(#project_id#) gt 0>
						<cfset go="yes">
						AND project.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
					</cfif>
					<cfif go is "no">
						AND 1=2
					</cfif>
				ORDER BY project_name
		</cfquery>
		<cfif go EQ "no">
			<cfset emptyProjQueryMessage = "You did not specify any search terms to find projects.">
		</cfif>
		<cfquery name="projNames" dbtype="query">
			SELECT distinct
				project_id,
				project_name,
				start_date,
				end_date
			FROM
				projects
			GROUP BY
				project_id,
				project_name,
				start_date,
				end_date
			ORDER BY
				project_name
		</cfquery>
	</cfif>
	<cfif search_type EQ "publications" OR search_type EQ "both">
		<cfset i=1>
		<cfset go="no">
		<cfquery name="publication" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				publication.publication_title,
				publication.publication_id,
				publication.publication_type,
				publication.doi,
				formatted_publication.formatted_publication,
				count(distinct(citation.collection_object_id)) numCits
			FROM
				publication
				left join publication_author_name on publication.publication_id = publication_author_name.publication_id
				left join project_publication on publication.publication_id = project_publication.publication_id
				left join agent_name pubAuth on publication_author_name.agent_name_id = pubAuth.agent_name_id
				left join agent_name searchAuth on pubAuth.agent_id = searchAuth.agent_id
				left join formatted_publication on formatted_publication.publication_id = publication.publication_id
				left join citation on publication.publication_id = citation.publication_id
				<cfif isdefined("collection_id") AND len(#collection_id#) gt 0>
					left join cataloged_item on citation.collection_object_id = cataloged_item.collection_object_id
				</cfif>
				<cfif isdefined("current_Sci_Name") AND len(#current_Sci_Name#) gt 0>
					left join citation CURRENT_NAME_CITATION on publication.publication_id = CURRENT_NAME_CITATION.publication_id
					left join cataloged_item ci_current on CURRENT_NAME_CITATION.collection_object_id = ci_current.collection_object_id
					left join identification catItemTaxa on ci_current.collection_object_id = catItemTaxa.collection_object_id
				</cfif>
				<cfif isdefined("cited_Sci_Name") AND len(#cited_Sci_Name#) gt 0>
					left join citation CITED_NAME_CITATION on publication.publication_id = CITED_NAME_CITATION.publication_id
					left join taxonomy CitTaxa on CITED_NAME_CITATION.cited_taxon_name_id = CitTaxa.taxon_name_id
				</cfif>
				<cfif isdefined("journal") AND len(journal) gt 0>
					left join publication_attributes jname on publication.publication_id=jname.publication_id
				</cfif>
		WHERE
				publication.publication_id is not null
				AND formatted_publication.format_style = 'long'
		<cfif isdefined("p_title") AND len(#p_title#) gt 0>
			<cfset go="yes">
				AND UPPER(regexp_replace(publication.publication_title,'<[^>]*>')) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(escapeQuotes(p_title))#%">
		</cfif>
		<cfif isdefined("publication_type") AND len(#publication_type#) gt 0>
			<cfset go="yes">
				AND publication.publication_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_type#">
		</cfif>
		<cfif isdefined("publication_id") AND len(#publication_id#) gt 0>
			<cfset go="yes">
				AND publication.publication_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		</cfif>
		<cfif isdefined("collection_id") AND len(#collection_id#) gt 0>
			<cfset go="yes">
				AND cataloged_item.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
		</cfif>
		<cfif isdefined("author") AND len(#author#) gt 0>
			<cfset go="yes">
				AND UPPER(searchAuth.agent_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(author)#%">
		</cfif>
		<cfif isdefined("year") AND isnumeric(year)>
			<cfset go="yes">
				AND publication.PUBLISHED_YEAR = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#year#">
		</cfif>
		<cfif isdefined("journal") AND len(journal) gt 0>
			<cfset go="yes">
				AND (jname.publication_attribute='journal name' or jname.publication_attribute = 'alternate journal name')
				AND upper(jname.pub_att_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(escapeQuotes(journal))#%">
		</cfif>
		<cfif isdefined("onlyCitePubs") AND len(onlyCitePubs) gt 0>
			<cfset go="yes">
			<cfif onlyCitePubs is "0">
				AND citation.collection_object_id is null
			<cfelse>
				AND citation.publication_id is not null
			</cfif>
		</cfif>
		<cfif isdefined("is_peer_reviewed_fg") AND is_peer_reviewed_fg is 1>
			<cfset go="yes">
				AND publication.is_peer_reviewed_fg=1
		</cfif>
		<cfif isdefined("current_Sci_Name") AND len(#current_Sci_Name#) gt 0>
			<cfset go="yes">
				AND catItemTaxa.accepted_id_fg = 1
				AND upper(catItemTaxa.scientific_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(current_Sci_Name)#%">
		</cfif>
		<cfif isdefined("cited_Sci_Name") AND len(#cited_Sci_Name#) gt 0>
			<cfset go="yes">
				AND upper(CitTaxa.scientific_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(cited_Sci_Name)#%">
		</cfif>
			<cfif go is "no">
				AND 1=2
			</cfif>
			GROUP BY
				publication.publication_title,
				publication.publication_id,
				publication.publication_type,
				publication.doi,
				formatted_publication.formatted_publication
			ORDER BY
				formatted_publication.formatted_publication,
				publication.publication_id
		</cfquery>
		<cfif go EQ "no">
			<cfset emptyPubQueryMessage = "You did not specify any search terms to find publications.">
		</cfif>
	</cfif>
<div class="projPubSearchResults">
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		<cfset pr ="project_id=">
		<cfset pb ="publication_id=">
		<cfif search_type EQ "projects" OR search_type EQ "both">
			<cfset pr = "project_id=#valuelist(projects.project_id)#">
		</cfif>
		<cfif search_type EQ "publications" OR search_type EQ "both">
			<cfset pb = "publication_id=#valuelist(publication.publication_id)#">
		</cfif>
		<a href="/Reports/SpecUsageReport.cfm?#pr#&#pb#">Create Report Data</a>
	</cfif>
	<cfset i=1>
	<table>
    <tr>
		<cfif search_type EQ "projects" OR search_type EQ "both">
      <td class="main">
		<h3>
			Projects
			<cfif projNames.recordcount is 0>
				<div class="notFound">
					No projects matched your criteria.  #emptyProjQueryMessage#
				</div>
			<cfelse>
				(#projNames.recordcount# result(s))

			</cfif>
		</h3>
		<cfset i=1>
		<cfloop query="projNames">
			<cfquery name="thisAuth" dbtype="query">
				SELECT
					agent_name,
					project_agent_role
				FROM
					projects
				WHERE
					project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
				GROUP BY
					agent_name,
					project_agent_role
				ORDER BY
					agent_position
			</cfquery>
			<cfquery name="thisSponsor" dbtype="query">
				SELECT
					ACKNOWLEDGEMENT,
					sponsor_name
				FROM
					projects
				WHERE
					project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
					AND sponsor_name is not null
				GROUP BY
					ACKNOWLEDGEMENT,
					sponsor_name
				ORDER BY
					sponsor_name
			</cfquery>
			<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))# style="font-size: 14px;">
				<a href="/ProjectDetail.cfm?project_id=#project_id#">
					<div class="indent">
					#project_name#
					</div>
				</a>
				<cfloop query="thisSponsor">
					Sponsored by #sponsor_name# <cfif len(ACKNOWLEDGEMENT) gt 0>: #ACKNOWLEDGEMENT#</cfif><br>
				</cfloop>
				<cfloop query="thisAuth">
					#agent_name# (#project_agent_role#)<br>
				</cfloop>
				#dateformat(start_date,"yyyy-mm-dd")# - #dateformat(end_date,"yyyy-mm-dd")#
				<br><a href="javascript: openAnnotation('project_id=#project_id#')">Annotate</a>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<br><a href="/Project.cfm?Action=editProject&project_id=#project_id#">Edit</a>
				</cfif>
			</div>
			<cfset i=i+1>
		</cfloop>
	</td>
		</cfif>
		<cfif search_type EQ "publications" OR search_type EQ "both">
    <td class="main">
	<h2 class="wikilink">
		Publications
          <cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")><img src="/images/info_i_2.gif" onClick="getMCZDocs('Edit Publication')" class="likeLink" alt="[ help ]"></cfif>
		<cfif publication.recordcount is 0>
			<div class="notFound">
				No publications matched your criteria.  #emptyPubQueryMessage#
			</div>
		<cfelseif publication.recordcount is 1>
            <span class="pr_count">(#publication.recordcount# result)</span>
			<cfset title = "#publication.publication_title#">
		<cfelse>
			(#publication.recordcount# results)
		</cfif>

	</h2>
	<cfquery name="undCollCitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getNamedGroup_result">
		SELECT distinct 
			collection_name, 
			underscore_collection.underscore_collection_id
		FROM
			underscore_collection_citation
			join underscore_collection on underscore_collection_citation.underscore_collection_id = underscore_collection.underscore_collection_id
		WHERE
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication.publication_id#">
	</cfquery>
	<cfif undCollCitations.recordcount GT 0>
		<cfset namedGroup = "<li>Named Groups: " >
		<cfset separator = "">
		<cfloop query="undCollCitations">
			<cfset namedGroup = "#namedGroup##separator#<a href='/grouping/showNamedCollection.cfm?underscore_collection_id=#underscore_collection_id#'>#collection_name#</a>" >
			<cfset separator = "; ">
		</cfloop>
		<cfset namedGroup = "#namedGroup#</li>" >
	<cfelse>
		<cfset namedGroup = "">
	</cfif>
	<cfquery name="pubs" dbtype="query">
		SELECT
			publication_id,
			publication_type,
			formatted_publication,
			doi,
			numCits
		FROM
			publication
		GROUP BY
			publication_id,
			publication_type,
			doi,
			formatted_publication,
			numCits
		ORDER BY
			formatted_publication
	</cfquery>
	<cfloop query="pubs">
		<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
            <cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")><p style="margin: .25em 0;padding-bottom: 0;">Publication ID: #publication_id#</p></cfif>
            <p class="indent" style="margin-top: .5em;">
				#replace(pubs.formatted_publication, pubs.doi, "<a target=""_blank"" href=""https://doi.org/" & pubs.doi & """>" & pubs.doi &"</a>")#
			</p>
			<ul>
				<li><a href="javascript: openAnnotation('publication_id=#publication_id#')">Annotate</a></li>
				<li>
					<cfif numCits gt 0>
						<a href="/SpecimenResults.cfm?publication_id=#publication_id#">#numCits# Cited Specimens</a>
					<cfelse>
						No Citations
					</cfif>
				</li>
				#namedGroup#
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
					<li><a href="/publications/Publication.cfm?publication_id=#publication_id#">Edit</a></li>
					<li><a href="/Citation.cfm?publication_id=#publication_id#">Manage Citations</a></li>
					<cfif isdefined("toproject_id") and len(toproject_id) gt 0>
						<li><a href="/Project.cfm?action=addPub&publication_id=#publication_id#&project_id=#toproject_id#">Add to Project</a></li>
					</cfif>
				</cfif>
				<cfquery name="pubmedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select
						media.media_id,
						media_type,
						mime_type,
						media_uri,
						preview_uri
					from
						media,
						media_relations
					where
						media.media_id=media_relations.media_id and
						media_relationship like '% publication' and
						related_primary_key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
				</cfquery>
				<cfif len(pubmedia.media_id) gt 0>
					<div class="thumbs">

						<div class="thumb_spcr">&nbsp;</div>
							<cfloop query="pubmedia">
								<cfset puri=getMediaPreview(preview_uri,media_type)>
				            	<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select
										media_label,
										label_value
									from
										media_labels
									where
										media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
								</cfquery>
								<cfquery name="desc" dbtype="query">
									select label_value from labels where media_label='description'
								</cfquery>
								<cfset alt="Media Preview Image">
								<cfif desc.recordcount is 1>
									<cfset alt=desc.label_value>
								</cfif>
				               <div class="one_thumb">
					               <a href="#media_uri#" target="_blank"><img src="#getMediaPreview(preview_uri,media_type)#" alt="#alt#" class="theThumb"></a>
				                   	<p>
										#media_type# (#mime_type#)
					                   	<br><a href="/media/#media_id#" target="_blank">Media Details</a>
										<br>#alt#
									</p>
								</div>
							</cfloop>
							<div class="thumb_spcr">&nbsp;</div>
						</div>
			<!---

					<li><a href="/MediaSearch.cfm?action=search&media_id=#valuelist(pubmedia.media_id)#" target="_blank">Media</a></li>

					--->
				</cfif>
			</ul>
		</div>
		<cfset i=#i#+1>
	</cfloop>
</td>
		</cfif>
</tr></table>
</div>
</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------->
<cfinclude template = "/includes/_footer.cfm">
