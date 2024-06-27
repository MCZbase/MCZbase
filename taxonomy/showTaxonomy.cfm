<cfset pageTitle = "Taxon Details">
<cfinclude template = "/shared/_header.cfm">

<main class="container py-3">
	
	<cftry>
		<!--- if given a scientific name, (as in redirect from /name/Aus+bus in /errors/missing.cfm), try to look up the record --->
		<cfif isdefined("scientific_name") and len(scientific_name) gt 0>
			<cfset scientific_name = URLDecode(scientific_name) >
			<cfquery name="getTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT taxon_name_id, scientific_name, author_text, full_taxon_name, year_of_publication
				FROM taxonomy 
				WHERE upper(scientific_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(scientific_name)#">
			</cfquery>
			<cfif getTID.recordcount is 1>
				<!---  taxon record is unique match on scientific name. --->
				<cfset tnid=getTID.taxon_name_id>
			<cfelseif getTID.recordcount GT 1>
				<!---  Handle Homonyms, scientific name has more than one match --->
				<cfoutput>
					<div class="row mx-0 alert alert-danger border px-4">
						<h1 class="h2">More than one taxonomy record in MCZbase matches the provided name string [#encodeForHTML(scientific_name)#]</h1>
						<div class="col-12"><p>These may be homonyms or duplicate taxon records.</p></div>
						<div class="col-12">
							<ul>
								<cfset tnid = -1>
								<cfloop query="getTID">
									<cfif tnid EQ -1>
										<cfset below = "(details shown below)">
										<cfset tnid=getTID.taxon_name_id>
									<cfelse>
										<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_taxonomy")>
											<cfset below='<a class="btn btn-xs btn-primary" href="/taxonomy/Taxonomy.cfm?action=edit&taxon_name_id=#getTID.taxon_name_id#">Edit</a>' >
										<cfelse>
											<cfset below = "">
										</cfif>
									</cfif>
									<cfset placement = ListDeleteAt(getTID.full_taxon_name,ListLen(getTID.full_taxon_name," ")," ") >
									<li>
										<a href='/taxonomy/showTaxonomy.cfm?taxon_name_id=#getTID.taxon_name_id#'><em>#getTID.scientific_name#</em> <span class="sm-caps">#getTID.author_text#</span></a>
										placed in #placement# #below#
									 </li>
								</cfloop>
							</ul>
						</div>
					</div>
				</cfoutput>
			<cfelseif listlen(scientific_name," ") gt 1 and (listlast(scientific_name," ") is "sp." or listlast(scientific_name," ") is "ssp.")>
				<!---  No match on the string, look for a match on the parent of a Aus sp. or Aus bus ssp. name string (that is on Aus or Aus bus). --->
				<cfset s=listdeleteat(scientific_name,listlen(scientific_name," ")," ")>
				<cfset checkSql(s)>
				<cfquery name="getTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT taxon_name_id 
					FROM taxonomy 
					WHERE upper(scientific_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(s)#">
				</cfquery>
				<cfif getTID.recordcount is 1>
					<!--- redirect, not entirely appropriately, to the parent. --->
					<cfheader statuscode="301" statustext="Moved permanently">
					<cfheader name="Location" value="/name/#EncodeForURL(s)#">
					<cfabort>
				</cfif>
			<cfelseif listlen(scientific_name," ") is 3>
				<!--- Name string didn't match, but desired record might contain an infraspecific rank (match Aus bus sus to Aus bus var. sus) --->
				<cfset checkSql(scientific_name)>
				<cfquery name="getTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						scientific_name
					FROM
						taxonomy
					WHERE
						upper(genus) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(listgetat(scientific_name,1," "))#"> and
						upper(species) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(listgetat(scientific_name,2," "))#"> and
						upper(subspecies) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(listgetat(scientific_name,3," "))#">
				</cfquery>
				<cfif getTID.recordcount is 1>
					<cfheader statuscode="301" statustext="Moved permanently">
					<cfheader name="Location" value="/name/#EncodeForURL(getTID.scientific_name)#">
					<cfabort>
				</cfif>
			<cfelseif listlen(scientific_name," ") is 4>
				<cfset checkSql(scientific_name)>
				<cfquery name="getTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						scientific_name
					FROM
						taxonomy
					WHERE
						upper(genus) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(listgetat(scientific_name,1," "))#"> and
						upper(species) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(listgetat(scientific_name,2," "))#"> and
						upper(subspecies) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(listgetat(scientific_name,4," "))#">
				</cfquery>
				<cfif getTID.recordcount is 1>
					<cfheader statuscode="301" statustext="Moved permanently">
					<cfheader name="Location" value="/name/#EncodeForURL(getTID.scientific_name)#">
					<cfabort>
				<cfelseif getTID.recordcount is 0>
					<!--- block above matchs provided Aus bus var. sus against Aus bus sus record, but 4 part name may be subgenus e.g. Aus (Aus) bus sus. --->
					<cfset subgenusCandidate = listgetat(scientific_name,2," ")>
					<cfset subgenusCandidate = mid(subgenusCandidate,2,len(subgenusCandidate)-1)>
					<cfquery name="getTIDsg" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							scientific_name
						FROM
							taxonomy
						WHERE
							upper(genus) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(listgetat(scientific_name,1," "))#"> and
							upper(subgenus) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(subgenusCandidate)#"> and
							upper(species) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(listgetat(scientific_name,3," "))#"> and
							upper(subspecies) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(listgetat(scientific_name,4," "))#">
					</cfquery>
					<cfif getTIDsg.recordcount is 1>
						<cfheader statuscode="301" statustext="Moved permanently">
						<cfheader name="Location" value="/name/#EncodeForURL(getTID.scientific_name)#">
						<cfabort>
					</cfif>
				</cfif>
			</cfif>
		</cfif>
		<!--- if given a taxon_name_id, try to look up the record, and if scientific_name is unique, provide redirect to /name/Aus+bus --->
		<cfif isdefined("taxon_name_id")>
			<cfquery name="lookupNameFromID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select scientific_name 
				from taxonomy 
				where taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
			</cfquery>
			<cfquery name="checkForHomonyms" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select count(*) as nameCount
				from taxonomy 
				where scientific_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lookupNameFromID.scientific_name#">
			</cfquery>
			<cfif checkForHomonyms.nameCount EQ 1>
				<cfif len(lookupNameFromID.scientific_name) gt 0>
					<cfheader statuscode="301" statustext="Moved permanently">
					<cfheader name="Location" value="/name/#EncodeForURL(lookupNameFromID.scientific_name)#">
					<cfabort>
				</cfif>
			<cfelseif checkForHomonyms.nameCount GT 1>
				<!--- don't redirect, as the redirect isn't to a unique entry --->
				<cfset tnid = taxon_name_id>
				<cfquery name="getHomonyms" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT taxon_name_id, scientific_name, author_text, full_taxon_name, year_of_publication
					FROM taxonomy 
					WHERE upper(scientific_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(lookupNameFromID.scientific_name)#">
				</cfquery>
				<cfoutput>
					<div class="row mx-0 alert alert-danger border px-4">
						<h1 class="h3">More than one taxonomy record in MCZbase matches the name string of the requested taxon.</h1>
						<div class="col-12"><p>These may be homonyms or duplicate taxon records.</p></div>
						<div class="col-12">
							<ul>
								<cfloop query="getHomonyms">
									<cfif getHomonyms.taxon_name_id EQ tnid>
										<cfset below = "(details shown below)">
									<cfelse>
										<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_taxonomy")>
											<cfset below='<a class="btn btn-xs btn-primary" href="/taxonomy/Taxonomy.cfm?action=edit&taxon_name_id=#getHomonyms.taxon_name_id#">Edit</a>' >
										<cfelse>
											<cfset below = "">
										</cfif>
									</cfif>
									<cfset placement = ListDeleteAt(getHomonyms.full_taxon_name,ListLen(getHomonyms.full_taxon_name," ")," ") >
									<li>
										<a href='/taxonomy/showTaxonomy.cfm?taxon_name_id=#getHomonyms.taxon_name_id#'><em>#getHomonyms.scientific_name#</em> <span class="sm-caps">#encodeForHTML(getHomonyms.author_text)#</span></a>
										placed in #placement# #below#
									 </li>
								</cfloop>
							</ul>
						</div>
					</div>
				</cfoutput>
			<cfelse>
				<!--- no such taxon_name_id --->
				<div class="error">Provided taxon_name_id Not Found</div>
			</cfif>
		</cfif>
		<cfcatch>
		<cfoutput>
			<h1 class="h2 mt-3">Error looking up taxonomy record.</h1>
			<p>#cfcatch.Message#</p>
			<p>#cfcatch.Detail#</p>
		</cfoutput>
		<cfinclude template = "/shared/_footer.cfm">
		<cfabort>
	</cfcatch>
	</cftry>
	
	<cfif not isdefined("tnid") or not tnid gt 0>
		<cfheader statuscode="404" statustext="Not found">
		<div class="error">Not Found</div>
		</div><!---class="container" --->
		<cfabort>
	</cfif>
	
	<!--- Note: uppercase PHYL is used here to allow removal to produce labels as well as database field names from this list --->
	<cfset taxaRanksList="Kingdom,Phylum,PHYLClass,Subclass,PHYLOrder,Suborder,Superfamily,Family,Subfamily,Genus,Subgenus,Species,Subspecies,Nomenclatural_Code,Taxon_Status">

	<cfquery name="getDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			taxonomy.TAXON_NAME_ID,
			taxonomy.VALID_CATALOG_TERM_FG,
			taxonomy.SOURCE_AUTHORITY,
			taxonomy.taxon_status,
			taxonomy.taxon_remarks,
			taxonomy.FULL_TAXON_NAME,
			<cfloop list="#taxaRanksList#" index="i">
				taxonomy.#i#,
			</cfloop>
			taxonomy.SCIENTIFIC_NAME,
			taxonomy.display_name,
			taxonomy.AUTHOR_TEXT,
			taxonomy.year_of_publication,
			taxonomy.INFRASPECIFIC_AUTHOR,
			taxonomy.INFRASPECIFIC_RANK,
			taxonomy.taxonid_guid_type,
			taxonomy.taxonid,
			taxonomy.scientificnameid_guid_type,
			taxonomy.scientificnameid,
			common_name,
			taxon_relations.RELATED_TAXON_NAME_ID,
			taxon_relations.TAXON_RELATIONSHIP,
			taxon_relations.RELATION_AUTHORITY,
			related_taxa.SCIENTIFIC_NAME as related_name,
			related_taxa.display_name as related_display_name,
			related_taxa.author_text as related_author_text,
			imp_related_taxa.SCIENTIFIC_NAME imp_related_name,
			imp_related_taxa.display_name imp_related_display_name,
			imp_related_taxa.author_text imp_related_author_text,
			imp_taxon_relations.taxon_name_id imp_RELATED_TAXON_NAME_ID,
			imp_taxon_relations.TAXON_RELATIONSHIP imp_TAXON_RELATIONSHIP,
			imp_taxon_relations.RELATION_AUTHORITY imp_RELATION_AUTHORITY
		 from
		 	taxonomy,
			common_name,
			taxon_relations,
			taxonomy related_taxa,
			taxon_relations imp_taxon_relations,
			taxonomy imp_related_taxa
		 WHERE
			taxonomy.taxon_name_id = common_name.taxon_name_id (+) AND
			taxonomy.taxon_name_id = taxon_relations.taxon_name_id (+) AND
			taxon_relations.related_taxon_name_id = related_taxa.taxon_name_id (+) AND
			taxonomy.taxon_name_id = imp_taxon_relations.related_taxon_name_id (+) AND
			imp_taxon_relations.taxon_name_id = imp_related_taxa.taxon_name_id (+) and
			taxonomy.taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#tnid#">
			ORDER BY scientific_name, common_name, related_taxon_name_id
	</cfquery>
	<cfquery name="common_name" dbtype="query">
		select
			common_name
		from
			getDetails
		where
			common_name is not null
		group by
			common_name
	</cfquery>
	<cfquery name="one" dbtype="query">
		select
			TAXON_NAME_ID,
			VALID_CATALOG_TERM_FG,
			SOURCE_AUTHORITY,
			taxon_remarks,
			FULL_TAXON_NAME,
			SCIENTIFIC_NAME,
			display_name,
			AUTHOR_TEXT,
			INFRASPECIFIC_RANK,
			<cfloop list="#taxaRanksList#" index="i">
				#i#,
			</cfloop>
			INFRASPECIFIC_AUTHOR,
			taxonid_guid_type,
			taxonid,
			scientificnameid_guid_type,
			scientificnameid
		from
			getDetails
		group by
			TAXON_NAME_ID,
			VALID_CATALOG_TERM_FG,
			SOURCE_AUTHORITY,
			taxon_remarks,
			FULL_TAXON_NAME,
			SCIENTIFIC_NAME,
			display_name,
			AUTHOR_TEXT,
			INFRASPECIFIC_RANK,
			<cfloop list="#taxaRanksList#" index="i">
				#i#,
			</cfloop>
			INFRASPECIFIC_AUTHOR,
			taxonid_guid_type,
			taxonid,
			scientificnameid_guid_type,
			scientificnameid
	</cfquery>
	<cfquery name="related" dbtype="query">
		select
			RELATED_TAXON_NAME_ID,
			TAXON_RELATIONSHIP,
			RELATION_AUTHORITY,
			related_name,
			related_display_name,
			related_author_text
		from
			getDetails
		where
			RELATED_TAXON_NAME_ID is not null
		group by
			RELATED_TAXON_NAME_ID,
			TAXON_RELATIONSHIP,
			RELATION_AUTHORITY,
			related_name,
			related_display_name,
			related_author_text
	</cfquery>
	<cfquery name="imp_related" dbtype="query">
		select
			imp_related_name,
			imp_RELATED_TAXON_NAME_ID,
			imp_TAXON_RELATIONSHIP,
			imp_RELATION_AUTHORITY,
			imp_related_display_name,
			imp_related_author_text
		from
			getDetails
		where
			imp_RELATED_TAXON_NAME_ID is not null
		group by
			imp_related_name,
			imp_RELATED_TAXON_NAME_ID,
			imp_TAXON_RELATIONSHIP,
			imp_RELATION_AUTHORITY,
			imp_related_display_name,
			imp_related_author_text
	</cfquery>
	<cfquery name="tax_pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select
			taxonomy_publication_id,
			formatted_publication,
			taxonomy_publication.publication_id
		from
			taxonomy_publication,
			formatted_publication
		where
			format_style='short' and
			taxonomy_publication.publication_id=formatted_publication.publication_id and
			taxonomy_publication.taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#tnid#">
	</cfquery>
	<cfquery name="citedSpecimens" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="citedSpecimens_result">
		SELECT distinct
			citation.type_status, 
			citation.occurs_page_number, 
			citation.citation_remarks,
			citation.citation_text,
			citation.citation_page_uri, 
			citation.publication_id, 
			publication.published_year,
			formatted_publication.formatted_publication as short_citation, 
			ctcitation_type_status.ordinal,
			'MCZ:' || cataloged_item.collection_cde || ':' || cataloged_item.cat_num as guid 
		FROM citation 
			LEFT JOIN cataloged_item on CITATION.COLLECTION_OBJECT_ID = CATALOGED_ITEM.COLLECTION_OBJECT_ID
			LEFT JOIN ctcitation_type_status on citation.type_status = ctcitation_type_status.type_status
			LEFT JOIN publication on citation.publication_id = publication.publication_id
			LEFT JOIN formatted_publication on citation.publication_id = formatted_publication.publication_id
				AND formatted_publication.format_style = 'short'
		WHERE 
			citation.cited_taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#tnid#">
		ORDER BY
			publication.published_year, 
			formatted_publication.formatted_publication, 
			citation.occurs_page_number, 
			ctcitation_type_status.ordinal, 
			'MCZ:' || cataloged_item.collection_cde || ':' || cataloged_item.cat_num
	</cfquery>
	<cfquery name="ctguid_type_taxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
		from ctguid_type 
		where guid_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#one.taxonid_guid_type#">
	</cfquery>
	<cfquery name="habitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="habitat_result">
		SELECT taxon_habitat 
		FROM taxon_habitat
		WHERE
			taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#tnid#">
	</cfquery>

	<!--- obtain information to create resolvable guid links if present --->	
	<cfset taxonidlink = "">
	<cfif len(one.taxonid) GT 0 AND ctguid_type_taxon.recordcount GT 0 >
		<cfset taxonidlink = REReplace(one.taxonid,ctguid_type_taxon.resolver_regex,ctguid_type_taxon.resolver_replacement)>
	</cfif>
	<cfquery name="ctguid_type_scientificname" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
		from ctguid_type 
		where guid_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#one.scientificnameid_guid_type#">
	</cfquery>
	<cfset scientificnameidlink = "">
	<cfif len(one.scientificnameid) GT 0 AND ctguid_type_taxon.recordcount GT 0 >
		<cfset scientificnameidlink = REReplace(one.scientificnameid,ctguid_type_taxon.resolver_regex,ctguid_type_taxon.resolver_replacement)>
	</cfif>
	
	<section class="row">
		<div class="col-12 mb-5"> 
			<cfoutput> 

				<cfset title="#one.scientific_name#">
				<cfset metaDesc="Taxon Detail for #one.scientific_name#">
				<cfset thisSearch = "%22#one.scientific_name#%22">
				<cfloop query="common_name">
					<cfset thisSearch = "#thisSearch# OR %22#common_name#%22">
				</cfloop>
				
				<div class="pb-2">
					<cfif one.VALID_CATALOG_TERM_FG is 1>
						<h1 class="h2 mt-3">#one.display_name# <span class="sm-caps font-weight-normal small90">#one.AUTHOR_TEXT#</span> <span class="font-weight-normal small">#one.taxon_status#</span></h1>
						<cfif len(one.AUTHOR_TEXT) gt 0>
							<span class="sm-caps font-weight-normal small90"><cfset metaDesc=metaDesc & "; Author: #one.AUTHOR_TEXT#"></span>
						</cfif>
					<cfelseif #one.VALID_CATALOG_TERM_FG# is 0>
						<h1 class="h2 mt-3">#one.display_name# <span class="sm-caps font-weight-normal small90">#one.AUTHOR_TEXT#</span> <span class="font-weight-normal small90">#one.taxon_status#</span></h1>
						<span class="text-danger h3">This name is not allowed for current identifications/data entry in MCZbase. </span>
					</cfif>
				</div>
			
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_taxonomy")>
					<p> <a class="btn btn-xs btn-primary" href="/taxonomy/Taxonomy.cfm?action=edit&taxon_name_id=#one.taxon_name_id#">Edit Taxonomy</a></p>
				</cfif>
				
				<table class="table table-responsive">
					<tr>
						<cfloop list="#taxaRanksList#" index="rank">
							<cfif len(evaluate("one." & rank)) gt 0>
								<cfset lbl=replace(rank,"PHYL",'')>
								<cfif lbl is "subspecies" and len(one.infraspecific_rank) gt 0>
									<cfset lbl=one.infraspecific_rank>
								</cfif>
								<th>#lbl#</th>
							</cfif>
						</cfloop>
					</tr>
					<tr>
						<cfloop list="#taxaRanksList#" index="rank">
							<cfif len(evaluate("one." & rank)) gt 0>
								<cfif rank EQ "Family">
									<cfset fam = evaluate("one." & rank)>
									<td><a href="/Taxa.cfm?execute=true&family=#encodeForURL(fam)#">#encodeForHTML(fam)#</a></td>
								<cfelseif rank EQ "Genus">
									<cfset highertaxon = evaluate("one." & rank)>
									<td><a href="/Taxa.cfm?execute=true&genus=#encodeForURL(highertaxon)#">#encodeForHTML(highertaxon)#</a></td>
								<cfelseif rank EQ "Superfamily">
									<cfset highertaxon = evaluate("one." & rank)>
									<td><a href="/Taxa.cfm?execute=true&superfamily=#encodeForURL(highertaxon)#">#encodeForHTML(highertaxon)#</a></td>
								<cfelseif rank EQ "Suborder">
									<cfset highertaxon = evaluate("one." & rank)>
									<td><a href="/Taxa.cfm?execute=true&suborder=#encodeForURL(highertaxon)#">#encodeForHTML(highertaxon)#</a></td>
								<cfelse>
									<td>#evaluate("one." & rank)#</td>
								</cfif>
								<cfset metaDesc=metaDesc & "; #replace(rank,'PHYL','')#: #evaluate('one.' & rank)#">
							</cfif>
						</cfloop>
					</tr>
				</table>

				<h2 class="h4">Name Authority: <b>#encodeForHTML(one.source_Authority)#</b></h2>
				<cfif len(taxonidlink) GT 0>
					<p>dwc:taxonID: <a href="#taxonidlink#" target="_blank">#one.taxonid#</a></p>
				</cfif>
				<cfif len(scientificnameidlink) GT 0>
					<p>dwc:scientificNameID: <a href="#scientificnameidlink#" target="_blank">#one.scientificnameid#</a></p>
				</cfif>
				<cfif len(one.year_of_publication) GT 0>
					<p>Published In: #one.year_of_publication#</p>
				</cfif>
				<cfif len(one.taxon_remarks) GT 0>
					<p>Remarks: #one.taxon_remarks#</p>
				</cfif>
				<cfif habitat.recordcount GT 0>
					<cfset sep = "">
					<h2 class="h4">
						Occurs in 
						<cfloop query="habitat">
							#sep# #taxon_habitat#
							<cfset sep = ",">
						</cfloop>
						habitats.
					</h2>
					
				</cfif>
				<h2 class="h4">Common Name(s):</h2>
				<ul>
					<cfif len(common_name.common_name) is 0>
						<li><b>No common names recorded.</b></li>
					<cfelse>
						<cfset metaDesc=metaDesc & "; Common Names: #valuelist(common_name.common_name)#">
						<cfloop query="common_name">
							<li><b>#common_name#</b></li>
						</cfloop>
						<cfset title = title & ' (#valuelist(common_name.common_name, "; ")#)'>
					</cfif>
				</ul>
				<h2 class="h4">Related Publications:</h2>
				<ul>
					<cfif tax_pub.recordcount is 0>
						<li><b>No related publications recorded.</b></li>
					<cfelse>
						<cfloop query="tax_pub">
							<li> <a href="/publications/showPublication.cfm?publication_id=#publication_id#"> #formatted_publication# </a> </li>
						</cfloop>
					</cfif>
				</ul>
				<h2 class="h4">Cited MCZ Specimens:</h2>
				<ul>
					<cfif citedSpecimens.recordcount is 0>
						<li><b>No cited MCZ specimens.</b></li>
					<cfelse>
						<cfloop query="citedSpecimens">
							<cfif len(citedSpecimens.occurs_page_number) GT 0>
								<cfif len(citedSpecimens.citation_page_uri) GT 0>
									<cfset page = "p. <a href=#citation_page_uri#>#occurs_page_number#</a>" >
								<cfelse>
									<cfset page = "p. #occurs_page_number#">
								</cfif>
							<cfelse>
									<cfset page = "">
							</cfif>
							<li> <a href="/guid/#guid#">#guid#</a> #type_status# #page# in <a href="/publications/showPublication.cfm?publication_id=#publication_id#">#short_citation#</a> </li>
						</cfloop>
					</cfif>
				</ul>
				<h2 class="h4">Synonyms and other Related Names:</h2>
				<ul>
					<cfif related.recordcount is 0 and imp_related.recordcount is 0>
						<li><b>No related names recorded.</b></li>
					<cfelse>
						<cfloop query="related">
							<li>
								#one.display_name# <span class="sm-caps font-weight-normal small90">#one.AUTHOR_TEXT#</span> #TAXON_RELATIONSHIP# <a href="/taxonomy/showTaxonomy.cfm?taxon_name_id=#RELATED_TAXON_NAME_ID#"><b><i>#related_name#</i> <span class="sm-caps">#related.related_author_text#<span></b></a>
								<cfif len(RELATION_AUTHORITY) gt 0>
									(According to: #encodeForHTML(RELATION_AUTHORITY)#)
								</cfif>
							</li>
						</cfloop>
						<cfquery name="inverse_relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="relations_result">
							SELECT
								scientific_name,
								author_text,
								taxon_relations.taxon_relationship,
								cttaxon_relation.inverse_relation,
								relation_authority,
								taxonomy.taxon_name_id
							FROM
								taxon_relations
								left join taxonomy on taxon_relations.taxon_name_id = taxonomy.taxon_name_id
								left join cttaxon_relation on taxon_relations.taxon_relationship = cttaxon_relation.taxon_relationship
							WHERE
								taxon_relations.related_taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#one.taxon_name_id#">
						</cfquery>
						<cfloop query="inverse_relations">
							<li> 
								#one.display_name# <span class="sm-caps font-weight-normal small90">#one.AUTHOR_TEXT#</span>
								#inverse_relations.inverse_relation#
								<a href="/taxonomy/showTaxonomy.cfm?taxon_name_id=#inverse_relations.taxon_name_id#"><b><i>#inverse_relations.scientific_name#</i> <span class="sm-caps">#inverse_relations.author_text#</span></b></a> 
								<cfif len(inverse_relations.RELATION_AUTHORITY) gt 0>
									(According to: #encodeForHTML(inverse_relations.RELATION_AUTHORITY)#)
								</cfif>
							</li>
						</cfloop>
					</cfif>
				</ul>
				
				<div class="row" id="taxRelatedNames">
					<div class="col-12">
						<h2 class="h4">Related Taxon Records:</h2>
						<cfset taxon_name_id = tnid>
						<cfinclude template="/taxonomy/listUpDownHeirarchy.cfm">
					<!--- lookup names up and down in taxonomic heirarchy, depending on rank of taxon --->
					</div>
				</div>

				<div id="specTaxMedia">
					<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT * from (
							SELECT DISTINCT * FROM (
								select
									flattable.guid,
									flattable.typestatus, 
									media_relationship,
									media_uri, preview_uri, media_type, mime_type,
									mczbase.get_media_descriptor(media.media_id) as media_descriptor 
								from media_relations
									left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>flat<cfelse>filtered_flat</cfif> flattable on related_primary_key = flattable.collection_object_id
									left join media on media_relations.media_id = media.media_id
									left join identification on flattable.collection_object_id = identification.collection_object_id
									left join identification_taxonomy on identification.identification_id = identification_taxonomy.identification_id
								where
									media_relationship = 'shows cataloged_item'
									AND identification_taxonomy.taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#tnid#">
								UNION
								select
									flattable.guid,
									flattable.typestatus, 
									media_relationship,
									media_uri, preview_uri, media_type, mime_type,
									mczbase.get_media_descriptor(media.media_id) as media_descriptor 
								from media_relations
									left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>flat<cfelse>filtered_flat</cfif> flattable on related_primary_key = flattable.collection_object_id
									left join media on media_relations.media_id = media.media_id
									left join citation on flattable.collection_object_id = citation.collection_object_id
								where
									media_relationship = 'shows cataloged_item'
									AND citation.cited_taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#tnid#">
							) order by typestatus
						) where rownum  < 20
					</cfquery>
					<div class="row" id="taxSpecimenMedia">
						<div class="col-12">
							<h2 class="h4">Media:</h2>
							<cfset hasSpecimenMedia = true>
							<cfif media.recordcount EQ 0>
								<p>No MCZbase specimens identified as this taxon have images</p>
								<cfset hasSpecimenMedia = false>
							</cfif>
							<cfloop query="media">
								<cfset altText = media.media_descriptor>
								<cfset puri=getMediaPreview(media.preview_uri,media.media_type)>
								<div class="float-left bg-light text-center p-1" style="width: 170px;">
									<a href="#media_uri#" target="_blank"><img src="#puri#" alt="#altText#" style="max-width: 120px; max-height: 120px;"></a>
									<div style="font-size: 86%" class="text-dark">
										#media.media_type# (#media.mime_type#)
										<br><a href="/guid/#media.guid#" target="_blank">#media.guid#</a>
									</div>
								</div>
							</cfloop>
						</div>
					</div>
				</div>
								
				<div class="row" id="internalExternalLinksLists">
					<div class="col-12">
						<h2 class="h4"> MCZbase Links:</h2>
						
						<ul>
							<cfquery name="usedInIndentifications" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select count(*) c 
								from identification_taxonomy where 
								taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#one.taxon_name_id#">
							</cfquery>
							<cfif usedInIndentifications.c GT 0>
								<li>
									<a href="/SpecimenResults.cfm?scientific_name=#one.scientific_name#"> Specimens currently identified as #one.display_name# </a> <a href="/SpecimenResults.cfm?anyTaxId=#one.taxon_name_id#"> [ include unaccepted IDs ] </a> <a href="/SpecimenResults.cfm?taxon_name_id=#one.taxon_name_id#"> [ exact matches only ] </a> 
									<cfif hasSpecimenMedia EQ true>
										<a href="/SpecimenResults.cfm?scientific_name=#one.scientific_name#&media_type=any"> [ with Media ] </a>
									</cfif>
								</li>
								<!--- maps.google.com no longer supports passing a kml file, would need to use the google map api instead --->
								<!--- 
								<li>
									<a href="/bnhmMaps/kml.cfm?method=gmap&action=newReq&next=colorBySpecies&scientific_name=#one.scientific_name#" class="external" target="_blank"> Google Map of MCZbase specimens </a>
								</li>
								--->
								<cfquery name="getClass" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									select phylclass,genus || ' ' || species scientific_name 
									from taxonomy 
									where scientific_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#one.scientific_name#">
			 						group by phylclass,genus || ' ' || species
								</cfquery>
								<cfif getClass.recordcount is not 1 or (
										getClass.phylclass is not 'Amphibia' and getClass.phylclass is not 'Mammalia' and getClass.phylclass is not 'Aves'
								)>
									<!--- link without range maps, as including them would result in an error --->
									<li>
										<a href="/bnhmMaps/bnhmMapData.cfm?showRangeMaps=false&scientific_name=#one.scientific_name#" class="external" target="_blank"> BerkeleyMapper </a>
									</li>
								<cfelse>
									<!--- link with range maps --->
									<li>
										<a href="/bnhmMaps/bnhmMapData.cfm?showRangeMaps=true&scientific_name=#one.scientific_name#" class="external" target="_blank"> BerkeleyMapper + RangeMaps </a>
									</li>
								</cfif>
							<cfelse>
								<li>No specimens use this name in Identifications.</li>
							</cfif>
							
							<cfquery name="usedInCitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select count(*) c 
								from citation 
								where cited_taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#one.taxon_name_id#">
							</cfquery>
							<cfif usedInCitations.c gt 0>
								<li>
									<a href="/SpecimenResults.cfm?cited_taxon_name_id=#one.taxon_name_id#"> Specimens cited as #one.display_name# </a>
								</li>
							<cfelse>
								<li>No specimens are cited using this name.</li>
							</cfif>
						</ul>
					</div>

					<div class="col-12">
						<h2 class="h4">External Links:</h2>
						<cfset srchName = EncodeForURL(one.scientific_name)>
					
						<ul>
							<li id="ispecies"> 
								<a class="external soft404" target="_blank" href="http://ispecies.org/?q=#srchName#">iSpecies</a> <span class="infoLink" onclick="alert('This site does not properly return page status. The link may or may not work.')";><i class="fas fa-question-circle"></i></span> 
							</li>
							<li id="wikipedia"> 
								<a class="external " target="_blank" href="http://wikipedia.org/wiki/#srchName#">Search Wikipedia for #one.scientific_name#</a> 
							</li>
							<cfif one.kingdom is not "Plantae">
								<li> 
									<a class="external soft404" target="_blank" href="http://animaldiversity.ummz.umich.edu/site/search?SearchableText=#srchName#"> Animal Diversity Web </a> <span class="infoLink" onclick="alert('This site does not properly return page status. The link may or may not work.')";><i class="fas fa-question-circle"></i></span> 
								</li>
							</cfif>
							<li id="ncbiLookup">
								 <a class="external soft404" target="_blank" href="http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?name=#srchName#"> NCBI </a> <span class="infoLink" onclick="alert('This site does not properly return page status. The link may or may not work.')";><i class="fas fa-question-circle"></i></span> 
							</li>
							<li id="googleImageLookup"> 
								<a class="external soft404" href="http://images.google.com/images?q=#thisSearch#" target="_blank"> Google Images </a> <span class="infoLink" onclick="alert('This site does not allow pre-fetching. The link may or may not work.')";><i class="fas fa-question-circle"></i></span>
							</li>
							<li id="eolLookup">
								 <a class="external soft404" target="_blank" href="http://www.eol.org/search/?q=#srchName#"> Encyclopedia of Life </a> <span class="infoLink" onclick="alert('This site does not properly return page status. The link may or may not work.')";><i class="fas fa-question-circle"></i></span> 
							</li>
							<li id="ubioLookup">
								<a class="external soft404" target="_blank" href="http://www.ubio.org/browser/search.php?search_all=#srchName#"> uBio </a> <span class="infoLink" onclick="alert('This site does not properly return page status. The link may or may not work.')";><i class="fas fa-question-circle"></i></span> 
							</li>
							<cfif one.kingdom is "Plantae" OR one.kingdom is 'Fungi'>
								<li id="fnaLookup"> 
									<a class="external soft404" target="_blank" href="http://www.efloras.org/browse.aspx?name_str=#srchName#">Flora of North America</a> 
									<span class="infoLink" onclick="alert('This site does not properly return page status. The link may or may not work.')";><i class="fas fa-question-circle"></i></span>
								</li>
								<li id="ipniLookup"> 
									<a class="external soft404" target="_blank" href="http://www.ipni.org/ipni/simplePlantNameSearch.do?find_wholeName=#srchName#"> The International Plant Names Index </a> <span class="infoLink" onclick="alert('This site does not properly return page status. The link may or may not work.')";><i class="fas fa-question-circle"></i></span> 
								</li>
								<li id="kewLookup"> 
									<a class="external soft404" target="_blank" href="http://epic.kew.org/searchepic/summaryquery.do?scientificName=#srchName#&searchAll=true&categories=names&categories=bibl&categories=colln&categories=taxon&categories=flora&categories=misc"> electronic plant information centre </a> <span class="infoLink" onclick="alert('This site does not properly return page status. The link may or may not work.')";><i class="fas fa-question-circle"></i></span> 
								</li>
							</cfif>
							<li id="itisLookup"> 
								<a class="external soft404" target="_blank" href="http://www.itis.gov/servlet/SingleRpt/SingleRpt?search_topic=Scientific_Name&search_value=#srchName#&search_kingdom=every&search_span=containing&categories=All&source=html&search_credRating=all"> ITIS </a> <span class="infoLink" onclick="alert('This site does not properly return page status. The link may or may not work.')";><i class="fas fa-question-circle"></i></span> 
							</li>
							<li id="colLookup">
								 <a class="external soft404" target="_blank" href="http://www.catalogueoflife.org/col/search/all/key/#srchName#/match/1"> Catalogue of Life </a> <span class="infoLink" onclick="alert('This site does not properly return page status. The link may or may not work.')";><i class="fas fa-question-circle"></i></span> 
							</li>
							<li id="citesLookupViaGoogle"> 
								<a class="external" target="_blank" href="http://www.google.com/custom?q=#srchName#&sa=Go!&cof=S:http://www.unep-wcmc.org;AH:left;LH:56;L:http://www.unep-wcmc.org/wdpa/I/unepwcmcsml.gif;LW:100;AWFID:681b57e6eabf5be6;&domains=unep-wcmc.org&sitesearch=unep-wcmc.org"> UNEP (CITES) </a> <span class="infoLink" onclick="alert('This site does not properly return page status. The link may or may not work.')";><i class="fas fa-question-circle"></i></span> 
							</li>
							<li id="wikispecies"> 
								<a class="external " target="_blank" href="http://species.wikimedia.org/wiki/#srchName#">Search WikiSpecies for #one.scientific_name#</a> 
							</li>
							<li id="bhlLookup"> 
								<a class="external soft404" target="_blank" href="http://www.biodiversitylibrary.org/name/#srchName#"> Biodiversity Heritage Library </a> <span class="infoLink" onclick="alert('This site does not properly return page status. The link may or may not work.')";><i class="fas fa-question-circle"></i></span> 
							</li>
						</ul>
					</div>
				</div>

				<cfif isdefined("session.username") and len(#session.username#) gt 0>
					<div class="row">
						<div class="col-12">
							<h2 class="h4">Annotations:</h2>
							<cfquery name="existingAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select count(*) cnt from annotations
								where taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#tnid#">
							</cfquery>
							<cfif #existingAnnotations.cnt# GT 0>
								<button type="button" aria-label="Annotate" id="annotationDialogLauncher"
									class="btn btn-xs btn-info" value="Annotate this record and view existing annotations"
									onClick=" openAnnotationsDialog('annotationDialog','taxon_name',#tnid#,null);">Annotate/View Annotations</button>
							<cfelse>
								<button type="button" aria-label="Annotate" id="annotationDialogLauncher"
									class="btn btn-xs btn-info" value="Annotate this record"
									onClick=" openAnnotationsDialog('annotationDialog','taxon_name',#tnid#,null);">Annotate</button>
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
								<p>There #are# #existingAnnotations.cnt# annotation#s# on this taxon record</p>
								<cfquery name="AnnotationStates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									select count(*) statecount, state from annotations
									where taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#tnid#">
									group by state
								</cfquery>
								<ul>
									<cfloop query="AnnotationStates">
										<li>#state#: #statecount#</li>
									</cfloop>
								</ul>
							<cfelse>
								<p class="my-2">There are no annotations on this taxon record</p>
							</cfif>
						</div>
					</div>
				</cfif>

		
			</cfoutput> 
		</div> <!--- col --->
	</section><!-- row --->
</main><!--- class="container" --->
<cfinclude template = "/shared/_footer.cfm">
