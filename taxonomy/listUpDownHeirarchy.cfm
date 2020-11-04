<cfoutput>
		<cfquery name="t" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			select TAXON_NAME_ID, PHYLCLASS, PHYLORDER, SUBORDER, FAMILY, SUBFAMILY, GENUS, SUBGENUS, SPECIES,
				SUBSPECIES, VALID_CATALOG_TERM_FG, SOURCE_AUTHORITY, FULL_TAXON_NAME, SCIENTIFIC_NAME, AUTHOR_TEXT, TRIBE,
				INFRASPECIFIC_RANK, TAXON_REMARKS, PHYLUM, SUPERFAMILY, SUBPHYLUM, SUBCLASS, KINGDOM, NOMENCLATURAL_CODE,
				INFRASPECIFIC_AUTHOR, INFRAORDER, SUPERORDER, DIVISION, SUBDIVISION, SUPERCLASS, DISPLAY_NAME, TAXON_STATUS,
				GUID, INFRACLASS, SUBSECTION, TAXONID_GUID_TYPE, TAXONID, SCIENTIFICNAMEID_GUID_TYPE, SCIENTIFICNAMEID 
			from taxonomy 
			where taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
		</cfquery>
		<cfif len(t.species) gt 0 and len(t.genus) gt 0>
			<cfif len(t.subspecies) gt 0>
				<cfquery name="ssp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
					select scientific_name,display_name from taxonomy where genus='#t.genus#' and species='#t.species#' and subspecies is null
				</cfquery>
				<cfif len(ssp.scientific_name) gt 0>
					<p>Parent Species: <a href="/name/#ssp.scientific_name#">#ssp.display_name#</a></p>
				</cfif>
			</cfif>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				select 
					scientific_name,
					display_name 
				from 
					taxonomy 
				where
					 genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.genus#"> and 
					 species = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.species#"> and 
					 subspecies is not null and
					 scientific_name != <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.scientific_name#">
				order by
					scientific_name
			</cfquery>
			<cfif d.recordcount gt 0>
				<br><cfif len(t.subspecies) gt 0>Related </cfif>Subspecies:
			</cfif>
			<ul>
				<cfloop query="d">
					<li><a href="/name/#scientific_name#">#display_name#</a></li>
				</cfloop>
			</ul>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				select 
					scientific_name,
					display_name 
				from 
					taxonomy 
				where
					 genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.genus#"> and 
					 species != <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.species#"> and
					 subspecies is null
				order by
					scientific_name
			</cfquery>
			<cfif d.recordcount gt 0>
				<br>Related Species:
			</cfif>
			<ul>
				<cfloop query="d">
					<li><a href="/name/#scientific_name#">#display_name#</a></li>
				</cfloop>
			</ul>
		<cfelseif len(t.genus) gt 0 and len(t.species) is 0>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				select 
					scientific_name,
					display_name 
				from 
					taxonomy 
				where
					 genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#t.genus#"> and
					 species is not null and
					 subspecies is null
				order by
					scientific_name
			</cfquery>
			<cfif d.recordcount gt 0>
				<br>Species:
			</cfif>
			<ul>
				<cfloop query="d">
					<li><a href="/name/#scientific_name#">#display_name#</a></li>
				</cfloop>
			</ul>
		</cfif>
</cfoutput>
