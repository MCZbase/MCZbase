<cfset pageTitle="Minimal Specimen Search">
<cfset addedMetaDescription="Minimal search for museum specimens and observations by taxonomy, identifications, specimen attributes, and usage history, works without javascript.">
<cfinclude template="/shared/_header.cfm">
<cfoutput>
<cfquery name="getSpecimenCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT count(collection_object_id) as cnt 
	FROM cataloged_item
</cfquery>
<cfquery name="ctInst" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT institution_acronym, collection, collection_id FROM collection order by collection
</cfquery>
<main id="content">
	<section class="container-fluid" role="search" >
		<h1 class="h3 smallcaps pl-1">
			Minimal Search for Specimen Records 
			<span class="count font-italic color-green mx-0"><small> #getSpecimenCount.cnt# records</small><small class="sr-only">Tab into search form</small></span>
		</h1>
		<noscript>
			<div>You are searching MCZbase with the non-JavaScript form. Please consider turning JavaScript on and using the <a href="/Specimens.cfm">standard search form</a>.</div>
		</noscript>
		<form class="container-flex" method="get" action="/specimens/SpecimenResultsHTML.cfm" name="specimenSearchForm" id="specimenSearchForm">
			<div class="form-row mb-2">
				<div class="col-12 col-md-4">
					<label for="collection" class="data-entry-label">Collection</label>
					<cfif isdefined("collection_id") and len(#collection_id#) gt 0>
						<cfquery name="lookupColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT collection
							FROM collection
							WHERE collection_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_id#">
						</cfquery>
						<cfif lookupColl.recordcount EQ 1>
							<cfset collection = lookupColl.collection>
						</cfif>
					<cfelseif isdefined("collection") and len(#collection#) gt 0>
						<cfquery name="lookupCollId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT collection_id 
							FROM collection
							WHERE collection = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection#">
						</cfquery>
						<cfif lookupCollId.recordcount EQ 1>
							<cfset collection_id = lookupCollId.collection_id>
						</cfif>
					</cfif>
					<cfif isdefined("collection_id") and len(#collection_id#) gt 0>
						<cfset thisCollId = #collection_id#>
					<cfelse>
						<cfset thisCollId = "">
					</cfif>
					<select name="collection_id" id="collection_id" size="1" class="data-entry-select">
						<option value="">All</option>
						<cfloop query="ctInst">
							<option <cfif #thisCollId# is #ctInst.collection_id#>	selected </cfif>
								value="#ctInst.collection_id#">#ctInst.collection#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-4">
					<cfif not isdefined("cat_num")><cfset cat_num=""></cfif>
					<label for="catalogNum" class="data-entry-label">Catalog Number</label>
					<input id="catalogNum" type="text" name="cat_num" class="data-entry-input" placeholder="1,1-4,A-1,R1-4" value="#encodeForHtml(cat_num)#">
				</div>
				<div class="col-12 col-md-4">
					<cfif not isdefined("type_status")><cfset type_status=""></cfif>
					<cfquery name="ctTypeStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select type_status type_status_val from ctcitation_type_status
					</cfquery>
					<label for="type_status" class="data-entry-label">Basis of Citation</label>
					<select id="type_status" name="type_status" class="data-entry-select" size="1">
						<option value=""></option>
						<option value="any">Any</option>
						<option value="any primary">Any Primary Type</option>
						<option value="any type">Any Type</option>
						<cfloop query="ctTypeStatus">
							<cfif type_status EQ ctTypeStatus.type_status_val><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="#ctTypeStatus.type_status_val#" #selected#>#ctTypeStatus.type_status_val#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-3">
					<cfif not isdefined("any_taxa_term")><cfset any_taxa_term=""></cfif>
					<label for="any_taxa_term" class="data-entry-label">Any Taxonomic Element</label>
					<input id="any_taxa_term" type="text" name="any_taxa_term" class="data-entry-input" value="#encodeForHtml(any_taxa_term)#">
				</div>
				<div class="col-12 col-md-3">
					<cfif not isdefined("phylum")><cfset phylum=""></cfif>
					<label for="phylum" class="data-entry-label">Phylum</label>
					<input id="phylum" type="text" name="phylum" class="data-entry-input" value="#encodeForHtml(phylum)#">
				</div>
				<div class="col-12 col-md-3">
					<cfif not isdefined("family")><cfset family=""></cfif>
					<label for="family" class="data-entry-label">Family</label>
					<input id="family" type="text" name="family" class="data-entry-input" value="#encodeForHtml(family)#">
				</div>
				<div class="col-12 col-md-4">
					<cfif not isdefined("any_geography")><cfset any_geography=""></cfif>
					<label for="any_geography" class="data-entry-label">Any Geographic Element</label>
					<input id="any_geography" type="text" name="any_geography" class="data-entry-input" value="#encodeForHtml(any_geography)#">
				</div>
				<div class="col-12 col-md-4">
					<cfif not isdefined("country")><cfset country=""></cfif>
					<label for="country" class="data-entry-label">Country</label>
					<input id="country" type="text" name="country" class="data-entry-input" value="#encodeForHtml(country)#">
				</div>
				<div class="col-12 col-md-4">
					<cfif not isdefined("spec_locality")><cfset spec_locality=""></cfif>
					<label for="spec_locality" class="data-entry-label">Specific Locality</label>
					<input id="spec_locality" type="text" name="spec_locality" class="data-entry-input" value="#encodeForHtml(spec_locality)#">
				</div>
				<div class="col-12 col-md-4">
					<cfif not isdefined("date_collected")><cfset date_collected=""></cfif>
					<label for="date_collected" class="data-entry-label">Date Collected</label>
					<input id="date_collected" type="text" name="date_collected" class="data-entry-input" value="#encodeForHtml(date_collected)#" placeholder="yyyy-mm-dd/yyyy-mm-dd">
				</div>
				<div class="col-12 col-md-4">
					<cfif not isdefined("part_name")><cfset part_name=""></cfif>
					<label for="part_name" class="data-entry-label">Part Name</label>
					<input id="part_name" type="text" name="part_name" class="data-entry-input" value="#encodeForHtml(part_name)#">
				</div>
			</div>
			<div class="form-row mb-2">
				<div class="col-12 col-md-4">
					<button type="submit" class="btn btn-xs btn-primary col-12 col-md-auto px-md-5 mx-0 my-1 mr-md-5" aria-label="run the minimal search" id="submitButton">Search <i class="fa fa-search"></i></button>
					<button type="button" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mx-0 my-1" aria-label="Start a new specimen search with a clear page" onclick="window.location.href='#Application.serverRootUrl#/SpecimensHTML.cfm';">New Search</button>
				</div>
			</div>
		</form>
	</section>
</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
