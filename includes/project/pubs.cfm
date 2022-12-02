<cfoutput>
	<cfquery name="pubs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT 
			formatted_publication.publication_id,
			formatted_publication, 
			count(citation.collection_object_id) numCit
		FROM 
			project_publication,
			formatted_publication,
			citation
		WHERE 
			project_publication.publication_id = formatted_publication.publication_id AND
			formatted_publication.publication_id=citation.publication_id (+) and
			format_style = 'long' and
			project_publication.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
		group by
			formatted_publication.publication_id,
			formatted_publication 
		order by
			formatted_publication
	</cfquery>
	<cfquery name="pub" dbtype="query">
		select
			formatted_publication,
			publication_id,
			numCit
		from
			pubs
		group by 
			formatted_publication,
			publication_id,
			numCit
		order by
			formatted_publication
	</cfquery>
	<cfif pub.recordcount gt 0>
		<h2>Publications</h2>
		This project produced #pub.recordcount# publications.
		<cfset i=1>
		<cfloop query="pub">
			<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
				<p class="indent">
					#formatted_publication#
				</p>
				<ul>
					<li>
						<cfif numCit gt 0>
							<a href="/SpecimenResults.cfm?publication_id=#publication_id#">#numCit# Cited Specimens</a>				
						<cfelse>
							No Citations
						</cfif>
					</li>
					<li><a href="/publications/showPublication.cfm?publication_id=#publication_id#">Details</a></li>
				</ul>
			</div>
			<cfset i=i+1>
		</cfloop>
	</cfif>
	</cfoutput>
