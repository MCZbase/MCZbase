<!---
publications/showPublication.cfm

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
<cfset pageTitle = "Publication Details">
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/media/component/search.cfc" runOnce="true">

<main class="container py-3">
	
	<cftry>
		<cfif isdefined("publication_id") and len(publication_id) GT 0 >
			<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="check_result">
				select count(*) ct
				from publication 
				where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
			<cfif check.ct NEQ 1>
				<cfthrow message="No publication record found for provided publication_id [#encodeForHTML(publication_id)#]" >
			</cfif>
		<cfelse>
			<cfthrow message="No publication_id provided">
		</cfif>
	<cfcatch>
		<cfoutput>
			<h1 class="h2 mt-3">Error looking up publication record.</h1>
			<p>#cfcatch.Message#</p>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin") >
				<p>#cfcatch.Detail#</p>
			</cfif>
		</cfoutput>
		<cfinclude template = "/shared/_footer.cfm">
		<cfabort>
	</cfcatch>
	</cftry>
	
	<cfquery name="getDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getDetails_result">
		SELECT
			PUBLICATION_ID ,
			PUBLISHED_YEAR ,
			PUBLICATION_TYPE ,
			PUBLICATION_LOC ,
			PUBLICATION_TITLE ,
			PUBLICATION_REMARKS ,
			IS_PEER_REVIEWED_FG ,
			DOI,
			mczbase.getshortcitation(publication_id) as short_citation, 
			mczbase.getfullcitation(publication_id) as full_citation 
		FROM publication
		WHERE
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	<cfquery name="getAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getAttributes_result">
		SELECT
			PUBLICATION_ATTRIBUTE_ID ,
			PUBLICATION_ID ,
			PUBLICATION_ATTRIBUTE ,
			PUB_ATT_VALUE  
		FROM publication_attributes
		WHERE
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	<cfquery name="citedSpecimens" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="citedSpecimens_result">
		SELECT 
			type_status, 
			occurs_page_number, 
			citation_remarks, 
			citation_page_uri, 
			publication_id, 
			'MCZ:' || collection_cde || ':' || cat_num as guid,
			cited_taxon_name_id,
			display_name, 
			author_text
		FROM citation 
			JOIN cataloged_item on CITATION.COLLECTION_OBJECT_ID = CATALOGED_ITEM.COLLECTION_OBJECT_ID
		 	JOIN taxonomy on citation.cited_taxon_name_id = taxonomy.taxon_name_id
		WHERE 
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		ORDER BY
			occurs_page_number asc, scientific_name
	</cfquery>

	<section class="row">
		<div class="col-12 mb-5"> 
			<cfoutput query="getDetails"> 

				<div class="pb-2">
					<h1 class="h2 mt-3">#getDetails.full_citation#</h1>
				</div>
			
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
					<p> <a class="btn btn-xs btn-primary" href="/Publication.cfm?action=edit&publication_id=#getDetails.publication_id_id#">Edit Publication Record</a></p>
				</cfif>
				
				<ul>
					<li><strong>Short Citation: </strong> #getDetails.short_citation#</li>
					<li><strong>Year Published: </strong> #getDetails.published_year#</li>
					<li><strong>Title: </strong> #getDetails.publication_title#</li>
					<li><strong>Publication Type: </strong> #getDetails.publication_type#</li>
					<li><strong>DOI: </strong> #getDetails.doi#</li>
					<li><strong>Peer Reviewed: </strong> #getDetails.is_peer_reviewed_fg#</li>
					<li><strong>Remarks: </strong> #getDetails.publication_remarks#</li>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
						<li><strong>Location: </strong> #getDetails.publication_loc#</li>
					</cfif>
				</ul>

				<ul>
					<cfloop query="getAttributes">
						<li><strong>#getAttributes.publication_attribute#: </strong> #getAttributes.pub_att_value#</li>
					</cfloop>
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
							<li> <a href="/guid/#guid#">#guid#</a> #display_name# <span class="sm-caps">#author_text#</span> #type_status# #page# in <a href="/SpecimenUsage.cfm?publication_id=#publication_id#">#getDetails.short_citation#</a> </li>
						</cfloop>
					</cfif>
				</ul>
				
				<div id="pubMediaDiv">
					<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_result">
						SELECT
							media_id
						FROM media_relations
						WHERE
							media_relationship = 'shows publication'
							AND related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
					</cfquery>
					<div class="row" id="pubMediaRow">
						<div class="col-12">
							<h2 class="h4">Media:</h2>
							<cfif media.recordcount EQ 0>
								<p>No Media for this publication</p>
							<cfelse>
								<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
								<cfloop query="media">
									<li class="list-group-item col-12 col-sm-6 col-md-4 col-lg-3 float-left"> 
										<cfset mediablock= getMediaBlockHtml(media_id="#media.media_id#",displayAs="thumb",captionAs="textShort")>
										<div id="mediaBlock#media_id#" class="border rounded pt-2 px-2">
											#mediablock#
										</div>
									</li>
								</cfloop>
							</cfif>
						</div>
					</div>
				</div>
								
				<cfif isdefined("session.username") and len(#session.username#) gt 0>
					<div class="row">
						<div class="col-12">
							<h2 class="h4">Annotations:</h2>
							<cfquery name="existingAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select count(*) cnt from annotations
								where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#tnid#">
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
								<cfquery name="AnnotationStates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
								<p class="my-2">There are no annotations on this publication record</p>
							</cfif>
						</div>
					</div>
				</cfif>
		
			</cfoutput> 
		</div> <!--- col --->
	</section><!-- row --->
</main><!--- class="container" --->
<cfinclude template = "/shared/_footer.cfm">
