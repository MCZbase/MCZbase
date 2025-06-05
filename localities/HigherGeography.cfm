<!---
localities/HigherGeography.cfm

Create and edit locality records.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2023 President and Fellows of Harvard College

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

<cfif not isdefined("action")>
	<cfif not isdefined("geog_auth_rec_id")>
		<cfset action="new">
	<cfelse>
		<cfset action="edit">
	</cfif>
</cfif>
<cfswitch expression="#action#">
	<cfcase value="edit">
		<cfset pageTitle="Edit Higher Geography">
	</cfcase>
	<cfcase value="new">
		<cfset pageTitle="New Higher Geography">
	</cfcase>
	<cfcase value="clone">
		<cfset pageTitle="Clone Higher Geography">
	</cfcase>
	<cfcase value="makenewHigherGeography">
		<cfset pageTitle="Creating New Higher Geography">
	</cfcase>
	<cfcase value="delete">
		<cfset pageTitle="Deleting Higher Geography">
	</cfcase>
	<cfdefaultcase>
		<cfthrow message="Error: Unknown Action">
	</cfdefaultcase>
</cfswitch>
<cfset pageHasTabs="true">
<cfinclude template = "/shared/_header.cfm">

<cfswitch expression="#action#">
	<cfcase value="edit">
		<cfinclude template="/localities/component/highergeog.cfc" runOnce="true">
		<cfinclude template="/localities/component/public.cfc" runOnce="true">
		<cfquery name="countUses" datasource="uam_god">
			SELECT 
				sum(ct) total_uses
			FROM (
				SELECT
					count(*) ct
				FROM 
					locality
				WHERE
					geog_auth_rec_id=  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
				UNION
				SELECT
					count(*) ct
				FROM
					media_relations
				WHERE
					related_primary_key =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
					AND
					media_relationship like '%geog_auth_rec'
			)
		</cfquery>
		<cfif not isDefined("geog_auth_rec_id") OR len(geog_auth_rec_id) EQ 0>
			<cfthrow message="Error: unable to edit higher geography, no geog_auth_rec_id specified.">
		</cfif>
		<cfoutput>
			<main class="container-fluid mt-3 mb-5 pb-5" id="content">
				<div class="row mx-0">
					<section class="col-12 col-md-8 px-md-0">
						<div class="col-12 px-0 pl-md-0 pr-md-3">
							<h1 class="h2 mt-3 mb-0 px-3">Edit Higher Geography 
								<a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#encodeForUrl(geog_auth_rec_id)#" target="_blank">[#encodeForHtml(geog_auth_rec_id)#]</a>
							</h1>
							<div class="border-top border-right border-left border-bottom border-success rounded px-2 my-2 py-2" id="usesContainingDiv">
								<cfset blockRelated = getGeographyUsesHtml(geog_auth_rec_id = "#geog_auth_rec_id#", containingDiv="usesContainingDiv")>
								<div id="relatedTo">#blockRelated#</div>
							</div>
							<div class="border rounded px-2 mt-xl-3 mb-xl-2 my-2 py-2">
								<cfset summary = getGeographySummary(geog_auth_rec_id="#geog_auth_rec_id#")>
								<h2 class="sr-only">Summary</h2>
								<div id="summary" class="h1 mb-0 px-2">#summary#</div>
							</div>
							<div class="border rounded px-2 py-2" arial-labeledby="formheading">
								<cfset formId = "editHigherGeographyForm">
								<cfset outputDiv="saveResultsDiv">
								<h2 class="sr-only">Higher Geography Form</h2>
								<form name="editHigherGeography" id="#formId#">
									<input type="hidden" name="method" value="updateHigherGeography">
									<cfset blockEditForm = getHigherGeographyFormHtml(mode="edit", geog_auth_rec_id = "#geog_auth_rec_id#", formId="#formId#", outputDiv="#outputDiv#", saveButtonFunction="saveEdits")>
									#blockEditForm#
								</form>
								<script>
									function reloadHigherGeographyBlocks() { 
										updateHigherGeographySummary('#geog_auth_rec_id#','summary');	
									}
									function reloadMap()  {
										loadHigherGeographyMapHTML('#geog_auth_rec_id#','mapDiv');
									}
									function saveEdits(){ 
										saveEditsFromFormCallback("#formId#","/localities/component/highergeog.cfc","#outputDiv#","saving higher geography record",reloadHigherGeographyBlocks);
									};
								</script>
							</div>
							<div class="border rounded px-2 py-2 my-2">
								<a href="/localities/HigherGeography.cfm?action=clone&clone_from_geog_auth_rec_id=#encodeForUrl(geog_auth_rec_id)#" class="btn btn-xs btn-secondary">Clone into new Higher Geography</a>
								<cfif countUses.total_uses EQ "0">
									<button type="button" 
										onClick="confirmDialog('Delete this Higher Geography?', 'Confirm Delete Higher Geography', function() { location.assign('/localities/HigherGeography.cfm?action=delete&geog_auth_rec_id=#encodeForUrl(geog_auth_rec_id)#'); } );" 
										class="btn btn-xs btn-danger" >
											Delete Higher Geography
									</button>
								</cfif>
							</div>
						</div>
					</section>
					<section class="mt-2 mt-md-5 col-12 px-md-0 col-md-4">
						<div class="col-12 px-2 bg-light pt-2 pb-1 mt-0 mb-2 border rounded">
						<!--- map --->
							<cfset map = getHigherGeographyMapHtml(geog_auth_rec_id="#geog_auth_rec_id#")>
							<div id="mapDiv">#map#</div>
						</div>
					</section>
				</div>
			</main>
		</cfoutput>
	</cfcase>
	<cfcase value="new">
		<cfinclude template="/localities/component/highergeog.cfc" runOnce="true">
		<cfoutput>

			<a href="##" id="show-wiki" class="btn btn-info">Show Wiki Content</a>
<!--- proxyWiki.cfm --->
<cfset baseWikiUrl="https://code.mcz.harvard.edu/wiki/index.php">
<cfset articleTitle = url.page ?: "Higher_Geography">
<cfset articleUrl = "#baseWikiUrl#?title=#URLEncodedFormat(articleTitle)#&action=render">

<!--- User/pass for HTTP Basic Auth --->
<cfhttp url="#articleUrl#" 
        method="get" 
        username="shareduser"
        password="sharedpassword"
        result="wikiContent">
</cfhttp>

<!--- Output the HTML as the response --->
<cfcontent type="text/html" reset="true">
#wikiContent.fileContent#
			
<script>
	
// For Adobe ColdFusion (traditional query string style)
const pageName = "Higher_Geography";
const proxyUrl = `/shared/functions.cfc?method=getWikiArticle&page=${encodeURIComponent(pageName)}`;

// For Lucee/Railo with REST mapping, the URL might differ
// Example: /api/wikiProxy/getWikiArticle?page=Earth

fetch(proxyUrl)
  .then(resp => resp.text())
  .then(html => {
    document.getElementById('wiki-content').innerHTML = html;
  })
  .catch(error => {
    document.getElementById('wiki-content').innerHTML = '<div class="alert alert-danger">Error fetching wiki content.</div>';
  });

var modal = new bootstrap.Modal(document.getElementById('wikiModal'));
modal.show();
			
</script>			
			
<cfset pageName = url.page ?: "Higher_Geography">
<cfhttp url="https://code.mcz.harvard.edu/wiki/index.php?title=#URLEncodedFormat(pageName)#&action=render" method="get" result="wikiContent" />
<cfcontent type="text/html" reset="true">
#wikiContent.fileContent#
<div class="modal fade" id="wikiModal" tabindex="-1" aria-labelledby="wikiModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="wikiModalLabel">Wiki Article</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body" id="wiki-content">
        Loading...
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
document.getElementById('show-wiki').addEventListener('click', function(e) {
	e.preventDefault();
	// Update with your wiki page link:
	const pageName = "Higher_Geography"; // or set dynamically
	
	const proxyUrl = `https://code.mcz.harvard.edu/wiki/index.php?page=${encodeURIComponent(pageName)}`;

	const contentDiv = document.getElementById('wiki-content');
	contentDiv.innerHTML = 'Loading...';
	
	fetch(proxyUrl)
		.then(resp => resp.text())
		.then(html => {
			contentDiv.innerHTML = html;
		})
		.catch(error => {
			contentDiv.innerHTML = '<div class="alert alert-danger">Error fetching wiki content.</div>';
		});

	var modal = new bootstrap.Modal(document.getElementById('wikiModal'));
	modal.show();
});
</script>
			
			<cfset extra = "">
			<cfset blockform = getHigherGeographyFormHtml(mode="new")>
			<main class="container-fluid container-xl mt-3" id="content">
				<section class="row">
					<div class="col-12">
						<h1 class="h2 mt-3 pl-1 ml-2" id="formheading">Create New Higher Geography#extra#</h1>
						<div class="border rounded px-2 py-2" arial-labeledby="formheading">
							<form name="createHigherGeography" method="post" action="/localities/HigherGeography.cfm">
								<input type="hidden" name="Action" value="makenewHigherGeography">
								#blockform#
							</form>
						</div>
					</div>
				</section>
			</main>
		</cfoutput>
	</cfcase>
	<cfcase value="clone">
		<cfinclude template="/localities/component/highergeog.cfc" runOnce="true">
		<cfoutput>
			<cfquery name="getSource" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getSource_result">
				SELECT higher_geog
				FROM geog_auth_rec
				WHERE
					geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#clone_from_geog_auth_rec_id#">
			</cfquery>
			<cfset extra = ". Cloning from: #getSource.higher_geog#">
			<cfset blockform = getHigherGeographyFormHtml(mode="new",clone_from_geog_auth_rec_id="#clone_from_geog_auth_rec_id#" )>
			<main class="container-fluid container-xl mt-3" id="content">
				<section class="row">
					<div class="col-12">
						<h1 class="h2 mt-3 pl-1 ml-2" id="formheading">Create New HigherGeography#extra#</h1>
						<div class="border rounded px-2 py-2" arial-labeledby="formheading">
							<form name="createHigherGeography" method="post" action="/localities/HigherGeography.cfm">
								<input type="hidden" name="Action" value="makenewHigherGeography">
								#blockform#
							</form>
						</div>
					</div>
				</section>
			</main>
		</cfoutput>
	</cfcase>
	<cfcase value="makenewHigherGeography">
		<cfif NOT isdefined("cloneCoords") OR cloneCoords NEQ "yes">
			<cfset cloneCoords = "no">
		</cfif>
		<cftransaction>
			<cfquery name="nextLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select sq_geog_auth_rec_id.nextval nextLoc from dual
			</cfquery>
			<cfquery name="newHigherGeography" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO geog_auth_rec (
					GEOG_AUTH_REC_ID
					,valid_catalog_term_fg
					,source_authority
					,continent_ocean
					,ocean_region
					,ocean_subregion
					,sea
					,water_feature
					,country
					,state_prov
					,county
					,feature
					,quad
					,island_group
					,island
					,highergeographyid_guid_type
					,highergeographyid
					,wkt_polygon
					,curated_fg
					,management_remarks
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextLoc.nextLoc#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_catalog_term_fg#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#source_authority#">,
					<cfif len(#continent_ocean#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#continent_ocean#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#ocean_region#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ocean_region#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#ocean_subregion#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ocean_subregion#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#sea#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#sea#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#water_feature#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#water_feature#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#country#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#country#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#state_prov#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#state_prov#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#county#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#county#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#feature#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#feature#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#quad#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#quad#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#island_group#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#island_group#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#island#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#island#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#highergeographyid_guid_type#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#highergeographyid_guid_type#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#highergeographyid#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#highergeographyid#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#wkt_polygon#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_CLOB" value="#wkt_polygon#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#curated_fg#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#curated_fg#">,
					<cfelse>
						0,
					</cfif>
					<cfif len(#management_remarks#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#management_remarks#">
					<cfelse>
						NULL
					</cfif>
				)
			</cfquery>
		</cftransaction>
		<cfoutput>
			<cflocation addtoken="no" url="/localities/HigherGeography.cfm?geog_auth_rec_id=#nextLoc.nextLoc#">
		</cfoutput>
	</cfcase>
	<cfcase value="delete">  
		<cftransaction>
			<cftry>
				<cfquery name="countUses" datasource="uam_god">
					SELECT 
						sum(ct) total_uses
					FROM (
						SELECT
							count(*) ct
						FROM 
							locality
						WHERE
							geog_auth_rec_id=  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
						UNION
						SELECT
							count(*) ct
						FROM
							media_relations
						WHERE
							related_primary_key =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
							AND
							media_relationship like '%geog_auth_rec'
					)
				</cfquery>
				<cfif countUses.total_uses GT 0>
					<cfthrow message="Unable to delete. Higher Geography has collecting events or media.">
				</cfif>
				<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="delete_result">
						DELETE FROM geog_auth_rec
						WHERE
							geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
				</cfquery>
				<cfoutput>
					<h1 class="h2">Higher Geography successfully deleted.</h1>
					<ul>
						<li><a href="/localities/HigherGeographies.cfm">Search for Higher Geographies</a>.</li>
						<li><a href="/localities/HigherGeography.cfm?action=new">Create a new Higher Geography</a>.</li>
					</ul>
				</cfoutput>
			<cfcatch>
				<cfthrow type="Application" message="Error deleting Higher Geography (<a href='/localities/HigherGeography.cfm?geog_auth_rec_id=#encodeForUrl(geog_auth_rec_id)#'>#encodeForHtml(geog_auth_rec_id)#</a>): #cfcatch.Message# #cfcatch.Detail#"><!--- " --->
			</cfcatch>
			</cftry>
		<cftransaction>
	</cfcase>
</cfswitch>

<cfinclude template = "/shared/_footer.cfm">
