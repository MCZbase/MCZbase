<!---
localities/viewLocality.cfm

View locality records.

Copyright 2023 President and Fellows of Harvard College

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

<cfset pageTitle="Locality Details">
<cfinclude template = "/shared/_header.cfm">
<cfif findNoCase('master',Session.gitBranch) NEQ 0>
	<!--- not ready for production use, prevent access from production, redirect to locality search --->
	<cflocation url="/localities/Localities.cfm" addtoken="false">
</cfif>

<cfif not isDefined("locality_id") OR len(locality_id) EQ 0>
	<cfthrow message="Error: unable to view locality, no locality_id specified.">
</cfif>

<cfinclude template="/localities/component/public.cfc" runOnce="true"><!--- for getLocalityMap() --->
<cfinclude template="/localities/component/search.cfc" runOnce="true"><!--- for getLocalitySummary() --->

<cfoutput>
	<main class="container-fluid mt-3 pb-5 mb-5" id="content">
		<div class="row mx-0">
		<section class="col-12 col-md-9 px-md-0 col-xl-8 px-xl-0">
			<div class="col-12 px-0 pl-md-0 pr-md-3">
				<h1 class="h2 mt-3 mb-0 px-3">Locality [#encodeForHtml(locality_id)#]</h1>
				<!--- TODO: Edit button --->
				<div class="border-top border-right border-left border-bottom border-success rounded px-3 my-3 py-3">
					<cfset blockRelated = getLocalityUsesHtml(locality_id = "#locality_id#")>
					<div id="relatedTo">#blockRelated#</div>
					<h2 class="h4 mt-3 mb-0 px-2">Locality Summary</h2>
					<cfset summary = getLocalitySummary(locality_id="#locality_id#")>
					<div id="summary" class="small95 px-2 pb-2">#summary#</div>
				</div>
				
				<div class="border rounded px-3 my-2 pt-2 pb-3" arial-labeledby="formheading">
					<div class="row mx-0">
					<cfset blockDetails = getLocalityHtml(locality_id = "#locality_id#")>
					#blockDetails#
				</div>
			</div>	

			<div class="row mx-0">
				<div class="col-12 col-md-6 px-0 pl-md-0 pr-md-3">
					<div class="border rounded px-3 my-2 py-3">
						<cfset geology = getLocalityGeologyDetailsHtml(locality_id="#locality_id#")>
						<div id="geologyDiv">#geology#</div>
					</div>
				</div>
				<div class="col-12 px-0 pr-md-3 pl-md-0 col-md-6">
					<div class="border rounded px-3 my-2 py-3">
						<cfset georeferences = getLocalityGeoreferenceDetailsHtml(locality_id="#locality_id#")>
						<div id="georeferencesDiv">#georeferences#</div>
					</div>
				</div>
			</div>
			<div class="row mx-0">
				<div class="col-12 col-md-6 px-0 pl-md-0 pr-md-3">
					<cfset blockRelated = getLocalityUsesHtml(locality_id = "#locality_id#")>
					<div id="relatedTo">#blockRelated#</div>
				</div>
				<!--- TODO: list dates, collectors, collecting events, etc. --->
			</div>
			<div class="row mx-0">
				<div class="col-12 col-md-6 px-0 pl-md-0 pr-md-3">
					<cfquery name="localityMedia"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT
							media_id
						FROM
							media_relations
						WHERE
							media_relationship like '% locality'
							and
							related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#"> 
					</cfquery>
					<cfif localityMedia.recordcount gt 0>
						<cfloop query="localityMedia">
							<div class="col-6 px-1 col-sm-3 col-lg-3 col-xl-3 mb-1 px-md-2 pt-1 float-left"> 
								<div id='locMediaBlock#localityMedia.media_id#'>
									<cfset mediaBlock= getMediaBlockHtmlUnthreaded(media_id="#localityMedia.media_id#",size="350",captionAs="textShort")>
								</div>
							</div>
						</cfloop>
					</cfif>
				</div>
			</div>
		</section>
		<section class="mt-3 mt-md-5 col-12 px-md-0 col-md-3 col-xl-4">
				<!--- map --->
				<div class="col-12 px-0 bg-light pt-0 pb-1 mt-2 mb-2 border rounded">
					<cfset map = getLocalityMapHtml(locality_id="#locality_id#")>
					<div id="mapDiv">#map#</div>
				</div>
				<!--- verbatim values --->
				<div class="col-12 pt-2">
					<h2 class="h4">Verbatim localities (from associated collecting events)</h2>
					<cfset verbatim = getLocalityVerbatimHtml(locality_id="#locality_id#")>
					<div id="verbatimDiv">#verbatim#</div>
				</div>
		</section>
		</div>
	</main>
</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
