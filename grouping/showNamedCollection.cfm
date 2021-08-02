<!---
grouping/showNamedCollection.cfm

For read only public view of arbitrary groupings of collection objects and
added value html describing them.

Copyright 2021 President and Fellows of Harvard College

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
<cfset pageTitle = "Named Group">
<cfif isDefined("underscore_collection_id") AND len(underscore_collection_id) GT 0>
	<cfquery name="getTitle" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getNamedGroup_result">
		SELECT collection_name
		FROM underscore_collection
		WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
		<cfif NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0>
			AND mask_fg = 0
		</cfif>
	</cfquery>
	<cfif getTitle.recordcount EQ 1>
		<cfset pageTitle = getTitle.collection_name>
	</cfif>
</cfif>
<cfinclude template="/shared/_header.cfm">
<cfoutput>
<style>
.carousel-wrapperX {
	overflow: hidden;
	width: 100%;
	margin: 0;
	position: relative;
	height: auto;
}
.carousel-wrapperX * {
	box-sizing: border-box;
}
.carouselX {
	-webkit-transform-style: preserve-3d;
	-moz-transform-style: preserve-3d;
	transform-style: preserve-3d;
}
.carouselImageX {
	opacity: 0;
	position: absolute;
	top: 0;
	width: 100%;
	margin: auto;
	padding: 0rem;
	z-index: 100;
	transition: transform .5s, opacity .5s, z-index .5s;
}
.carouselImageX.initial, .carouselImageX.active {
	opacity: 1;
	position: relative;
	z-index: 900;
}
.carouselImageX.prev, .carouselImageX.next {
	z-index: 800;
}
.carouselImageX.prev {
	transform: translateX(-100%); /* go to previous item */
}
.carouselImageX.next {
	transform: translateX(100%); /* go to next item */
}
.carousel__buttonX--prev, .carousel__buttonX--next {
	position: absolute;
	top: 48%;
	width: 3.5rem;
	height: 100%;
	background-color: transparent;
	transform: translateY(-50%);
	border-radius: 8%;
	cursor: pointer;
	z-index: 1001; /* sit on top of everything */
	border: none;
}
.carousel__buttonX--prev {
	left: 0;
}
.carousel__buttonX--next {
	right: 0;
}
.carousel__buttonX--prev::after, 
.carousel__buttonX--next::after {
	content: " ";
	position: absolute;
	width: 15px;
	height: 15px;
	top: 50%;
	left: 80%;
	border-right: 3px solid ##007bff;
	border-bottom: 3px solid ##007bff;
	transform: translate(-50%, -50%) rotate(135deg);
}
.carousel__buttonX--next::after {
	left: 20%;
	transform: translate(-50%, -50%) rotate(-45deg);
}
</style>
	<cfif not isDefined("underscore_collection_id") OR len(underscore_collection_id) EQ 0>
		<cfthrow message="No named group specified to show.">
	</cfif>
	<cfquery name="getNamedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getNamedGroup_result">
		SELECT underscore_collection_id, collection_name, description, underscore_agent_id, html_description,
			case 
				when underscore_agent_id is null then '[No Agent]'
			else 
				MCZBASE.get_agentnameoftype(underscore_agent_id, 'preferred')
			end
			as agent_name,
			mask_fg
		FROM underscore_collection
		WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
	</cfquery>
	<cfloop query="getNamedGroup">
		<cfif getNamedGroup.mask_fg EQ 1 AND (NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0)>
			<!--- mask_fg = 1 = Hidden --->
			<cflocation url="/errors/forbidden.cfm" addtoken="false">
		</cfif> 
		<main class="container-fluid py-3">
			<div class="row mx-0">
				<article class="w-100">
					<div class="col-12">
						<div class="row mx-0">
							<div class="col-12 border-dark mt-4">
								<h1 class="pb-2 w-100 border-bottom-black">#getNamedGroup.collection_name# 
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
										<div class="d-inline-block float-right">
											<a target="_blank" class="px-2 btn-xs btn-primary text-decoration-none" href="/grouping/NamedCollection.cfm?action=edit&underscore_collection_id=#underscore_collection_id#">Edit</a>
										</div>
									</cfif>
								</h1>
							</div>
						</div>
						<div class="row mx-0">
							<div class="col-12 px-3 mt-0">
								<!--- arbitrary html clob, could be empty, could be tens of thousands of characters plus rich media content --->
								<!--- WARNING: This section MUST go at the top, and must be allowed the full width of the page --->
								<cfif len(html_description)gt 0>
									<div class="pb-0">#getNamedGroup.html_description# </div>
								</cfif>
							</div>
						</div>	
						<div class="row mx-0">
							<cfquery name="specimens" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT DISTINCT flat.guid, flat.scientific_name
								FROM
									underscore_relation 
									left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
										on underscore_relation.collection_object_id = flat.collection_object_id
								WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
									and flat.guid is not null
								ORDER BY flat.guid asc
							</cfquery>
							<cfquery name="specimenImgs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT DISTINCT media.media_uri
								FROM
									underscore_collection
									left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
									left join cataloged_item
										on underscore_relation.collection_object_id = cataloged_item.collection_object_id
									left join media_relations
										on media_relations.related_primary_key = underscore_relation.collection_object_id
									left join media on media_relations.media_id = media.media_id
								WHERE underscore_collection.underscore_collection_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
									AND media_relations.media_relationship = 'shows cataloged_item'
									AND media.media_type = 'image'
									AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
							</cfquery>
							<script type="text/javascript">
								var cellsrenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
									if (value > 1) {
										return '<a href="/guid/'+value+'"><span style="margin: 4px; float: ' + columnproperties.cellsalign + '; color: ##0000ff;">' + value + '</span></a>';
									}
									else {
										return '<a href="/guid/'+value+'"><span style="margin: 4px; float: ' + columnproperties.cellsalign + '; color: ##007bff;">' + value + '</span></a>';
									}
								}
								$(document).ready(function () {
									var source =
									{
										datatype: "json",
										datafields:
										[
											{ name: 'guid', type: 'string' },
											{ name: 'scientific_name', type: 'string' },
											{ name: 'verbatim_date', type: 'string' },
											{ name: 'higher_geog', type: 'string' },
											{ name: 'spec_locality', type: 'string' },
											{ name: 'othercatalognumbers', type: 'string' },
											{ name: 'full_taxon_name', type: 'string' }
										],
										url: '/grouping/component/search.cfc?method=getSpecimensInGroup&smallerfieldlist=true&underscore_collection_id=#underscore_collection_id#',
										timeout: 30000,  // units not specified, miliseconds? 
										loadError: function(jqXHR, textStatus, error) { 
											handleFail(jqXHR,textStatus,error,"retrieving cataloged items in named group");
										}
									};

									var dataAdapter = new $.jqx.dataAdapter(source);
									// initialize jqxGrid
									$("##jqxgrid").jqxGrid(
									{
										width: '100%',
										autoheight: 'true',
										source: dataAdapter,
										filterable: true,
										showfilterrow: true,
										sortable: true,
										pageable: true,
										editable: false,
										pagesize: '5',
										pagesizeoptions: ['5','50','100'],
										columnsresize: false,
										autoshowfiltericon: false,
										autoshowcolumnsmenubutton: false,
										altrows: true,
										showtoolbar: false,
										enabletooltips: true,
										pageable: true,
										columns: [
											{ text: 'GUID', datafield: 'guid', width:'180',cellsalign: 'left',cellsrenderer: cellsrenderer },
											{ text: 'Scientific Name', datafield: 'scientific_name', width:'250' },
											{ text: 'Date Collected', datafield: 'verbatim_date', width:'150'},
											{ text: 'Higher Geography', datafield: 'higher_geog', width:'350'},
											{ text: 'Locality', datafield: 'spec_locality',width:'350' },
											{ text: 'Other Catalog Numbers', datafield: 'othercatalognumbers',width:'350' },
											{ text: 'Taxonomy', datafield: 'full_taxon_name', width:'350'}
										]
									});
								});
							</script>
							<div class="col-12 mt-2">
								<h2 class="">Specimen Records <a href="/SpecimenResults.cfm?underscore_coll_id=#encodeForURL(underscore_collection_id)#" target="_blank">(#specimens.recordcount#)</a></h2>
								<div id="jqxgrid"></div>
							</div>
						</div>
						<!---end specimen grid--->						
					</div>		
								
					<div class="row mx-3">	
						<div class="col-12 col-md-6 float-left">
						<!--- obtain a random set of specimen images, limited to a small number --->
						<cfif specimenImgs.media_uri gt 0>
							<cfquery name="specimenImagesForCarousel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="specimenImagesForCarousel_result">                                    		
								SELECT * FROM (
								SELECT DISTINCT media.media_uri, MCZBASE.get_media_descriptor(media.media_id) as alt
								FROM
									underscore_collection
									left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
									left join cataloged_item
										on underscore_relation.collection_object_id = cataloged_item.collection_object_id
									left join media_relations
										on media_relations.related_primary_key = underscore_relation.collection_object_id
									left join media on media_relations.media_id = media.media_id
								WHERE underscore_collection.underscore_collection_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
									AND media_relations.media_relationship = 'shows cataloged_item'
									AND media.media_type = 'image'
									AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
									ORDER BY DBMS_RANDOM.RANDOM
								) 
								WHERE   Rownum  <= 15
							</cfquery>
							<cfquery name="agentImagesForCarousel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="agentImagesForCarousel_result">  
								SELECT * FROM (
									SELECT DISTINCT media_uri, preview_uri,media_type, media.media_id,
										MCZBASE.get_media_descriptor(media.media_id) as alt,
										MCZBASE.get_medialabel(media.media_id,'width') as width,
										MCZBASE.get_media_credit(media.media_id) as credit
									FROM
										underscore_collection
										left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
										left join collector on underscore_relation.collection_object_id = collector.collection_object_id
										left join media_relations on collector.agent_id = media_relations.related_primary_key
										left join media on media_relations.media_id = media.media_id
									WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										AND flat.guid IS NOT NULL
										AND collector.collector_role = 'c'
										AND media_relations.media_relationship = 'shows agent'
										AND media.media_type = 'image'
										AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
										AND media.media_uri LIKE '%mczbase.mcz.harvard.edu%'
									ORDER BY DBMS_RANDOM.RANDOM
								) 
								WHERE Rownum <= 30
							</cfquery>
							<!---The encumbrance line was slowing it down too much--->
							<h2 class="mt-3">#specimenImgs.recordcount# Images of Cataloged Items (shows 15)</h2>
							<p class="small">Refresh page to show a different 15 images.</p>
							<div class="carousel-wrapperX">
								<cfoutput>
									<div class="carouselX">
										<div class="carouselImageX initial"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][1]#"/><p>#specimenImagesforCarousel['alt'][1]#</p></div>									
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][2]#"/><p>#specimenImagesforCarousel['alt'][2]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][3]#"/><p>#specimenImagesforCarousel['alt'][3]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][4]#"/><p>#specimenImagesforCarousel['alt'][4]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][5]#"/><p>#specimenImagesforCarousel['alt'][5]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][6]#"/><p>#specimenImagesforCarousel['alt'][6]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][7]#"/><p>#specimenImagesforCarousel['alt'][7]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][8]#"/><p>#specimenImagesforCarousel['alt'][8]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][9]#"/><p>#specimenImagesforCarousel['alt'][9]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][10]#"/><p>#specimenImagesforCarousel['alt'][10]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][11]#"/><p>#specimenImagesforCarousel['alt'][11]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][12]#"/><p>#specimenImagesforCarousel['alt'][12]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][13]#"/><p>#specimenImagesforCarousel['alt'][13]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][14]#"/><p>#specimenImagesforCarousel['alt'][14]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][15]#"/><p>#specimenImagesforCarousel['alt'][15]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][16]#"/><p>#agentImagesforCarousel['alt'][16]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][17]#"/><p>#agentImagesforCarousel['alt'][17]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][18]#"/><p>#agentImagesforCarousel['alt'][18]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][19]#"/><p>#agentImagesforCarousel['alt'][19]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][20]#"/><p>#agentImagesforCarousel['alt'][20]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][21]#"/><p>#agentImagesforCarousel['alt'][21]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][22]#"/><p>#agentImagesforCarousel['alt'][22]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][23]#"/><p>#agentImagesforCarousel['alt'][23]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][24]#"/><p>#agentImagesforCarousel['alt'][24]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][25]#"/><p>#agentImagesforCarousel['alt'][25]#</p></div>
									</div>
									<div class="carousel__buttonX--next"></div>
									<div class="carousel__buttonX--prev"></div>
								</cfoutput>
							</div>
							</cfif>
							<!--- obtain a random set of agent images, limited to a small number --->
	<!---						
							<h2 class="mt-3"> Images from Agents (shows 15)</h2>
							<p class="small">Refresh page to show a different 15 images.</p>
							<div class="carousel-wrapperX">
								<cfoutput>
									<div class="carouselX">
										<div class="carouselImageX initial"><img class="w-100" src="#agentImagesforCarousel['media_uri'][17]#"/><p>#agentImagesforCarousel['alt'][17]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][18]#"/><p>#agentImagesforCarousel['alt'][18]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][19]#"/><p>#agentImagesforCarousel['alt'][19]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][20]#"/><p>#agentImagesforCarousel['alt'][20]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][21]#"/><p>#agentImagesforCarousel['alt'][21]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][22]#"/><p>#agentImagesforCarousel['alt'][22]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][23]#"/><p>#agentImagesforCarousel['alt'][23]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][24]#"/><p>#agentImagesforCarousel['alt'][24]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][25]#"/><p>#agentImagesforCarousel['alt'][25]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][26]#"/><p>#agentImagesforCarousel['alt'][26]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][27]#"/><p>#agentImagesforCarousel['alt'][27]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][28]#"/><p>#agentImagesforCarousel['alt'][28]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][29]#"/><p>#agentImagesforCarousel['alt'][29]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][30]#"/><p>#agentImagesforCarousel['alt'][30]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][16]#"/><p>#agentImagesforCarousel['alt'][16]#</p></div>
									</div>
									<div class="carousel__buttonX--next"></div>
									<div class="carousel__buttonX--prev"></div>
								</cfoutput>
							</div>--->
					
						</div>

						<div class="col mt-0 float-left">
							<!--- This is either a full width or half width col, depending on presence/absence of has any kind of image col --->
							<div class="my-2 py-3 border-bottom-black">
								<cfif len(getNamedGroup.description) GT 0 >
									<h2 class="mt-3">Overview</h2>
									<p>#getNamedGroup.description#</p>
								</cfif>
							</div>
							<div class="row pb-4">
								<cfif len(underscore_agent_id) GT 0 >
									<cfif getNamedGroup.agent_name NEQ "[No Agent]" >
										<div class="col-12 pt-3">
											<h3>Associated Agent</h2>
											<p class="rounded-0 border-top border-dark">
												<a class="h4 px-2 pt-3 d-block" href="/agents/Agent.cfm?agent_id=#underscore_agent_id#">#getNamedGroup.agent_name#</a>
											</p>
										</div>
									</cfif>
								</cfif>
								<cfquery name="taxonQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="taxonQuery_result">
									SELECT DISTINCT flat.phylclass as taxon, flat.phylclass as taxonlink, 'phylclass' as rank
									FROM
										underscore_relation 
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
									WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										and flat.PHYLCLASS is not null
									ORDER BY flat.phylclass asc
								</cfquery>
								<cfif taxonQuery.recordcount GT 0 AND taxonQuery.recordcount LT 5 >
									<!--- try expanding to orders instead if very few classes --->
									<cfquery name="taxonQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="taxonQuery_result">
										SELECT DISTINCT flat.phylclass || ': ' || flat.phylorder as taxon, flat.phylorder as taxonlink, 'phylorder' as rank,
											flat.phylclass, flat.phylorder
										FROM
											underscore_relation 
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
										WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											and flat.PHYLCLASS is not null and flat.phylorder is not null
										ORDER BY flat.phylclass asc, flat.phylorder asc
									</cfquery>
								</cfif>
								<cfif taxonQuery.recordcount GT 0 AND taxonQuery.recordcount LT 5 >
									<!--- try expanding to families instead if very few orders --->
									<cfquery name="taxonQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="taxonQuery_result">
										SELECT DISTINCT flat.phylorder || ': ' || flat.family as taxon, flat.family as taxonlink, 'family' as rank,
											flat.phylorder, flat.family
										FROM
											underscore_relation 
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
										WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											and flat.PHYLCLASS is not null and flat.family is not null
										ORDER BY flat.phylorder asc, flat.family asc
									</cfquery>
								</cfif>
								<cfif taxonQuery.recordcount GT 0>
									<div class="col-12">
										<h3>Taxa</h3>
										<ul class="list-group py-3 list-group-horizontal flex-wrap rounded-0 border-top border-dark">
											<cfloop query="taxonQuery">
												<li class="list-group-item col-12 col-md-3 float-left">
													<a class="h4" href="/SpecimenResults.cfm?#encodeForUrl(taxonQuery.rank)#=#encodeForUrl(taxonQuery.taxonlink)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#taxonQuery.taxon#</a>
												</li>
											</cfloop>
										</ul>
									</div>
								</cfif>
								<cfquery name="marine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="marine_result">
									SELECT DISTINCT flat.continent_ocean as ocean
									FROM
										underscore_relation 
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
									WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										and flat.continent_ocean like '%Ocean%'
									ORDER BY flat.continent_ocean asc
								</cfquery>
								<cfif marine.recordcount GT 0>
									<div class="col-12">
										<h3 class="px-2">Oceans</h3>
										<ul class="list-group py-3 list-group-horizontal flex-wrap border-top rounded-0 border-dark">
											<cfloop query="marine">
												<li class="list-group-item col-12 col-md-3 float-left">
													<a class="h4" href="/SpecimenResults.cfm?continent_ocean=#encodeForURL(marine.ocean)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#marine.ocean#</a>
												</li>
											</cfloop>
										</ul>
									</div>
								</cfif>
								<cfquery name="geogQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="geogQuery_result">
									SELECT DISTINCT flat.country as geog, flat.country as geoglink, 'Country' as rank
									FROM
										underscore_relation 
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
									WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										and flat.country is not null
									ORDER BY flat.country asc
								</cfquery>
								<cfif geogQuery.recordcount GT 0 AND geogQuery.recordcount LT 5 >
									<!--- try expanding to families instead if very few orders --->
									<cfquery name="geogQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="geogQuery_result">
										SELECT DISTINCT flat.country || ': ' || flat.state_prov as geog, flat.state_prov as geoglink, 'state_prov' as rank,
											flat.country, flat.state_prov
										FROM
											underscore_relation 
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
										WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											and flat.state_prov is not null
										ORDER BY flat.country asc, flat.state_prov asc
									</cfquery>
								</cfif>
								<cfif geogQuery.recordcount GT 0>
									<div class="col-12">
										<h3>Geography</h3>
										<ul class="list-group py-3 border-top list-group-horizontal flex-wrap rounded-0 border-dark">
											<cfloop query="geogQuery">
												<li class="list-group-item col-12 col-md-3 float-left">
													<a class="h4" href="/SpecimenResults.cfm?#encodeForUrl(geogQuery.rank)#=#encodeForUrl(geogQuery.geoglink)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#geogQuery.geog#</a>
												</li>
											</cfloop>
										</ul>
									</div>
								</cfif>

								<cfquery name="islandsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="islandsQuery_result">
									SELECT DISTINCT flat.continent_ocean, flat.island as island
									FROM
										underscore_relation 
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
									WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										and flat.island is not null
									ORDER BY flat.continent_ocean, flat.island asc
								</cfquery>
								<cfif islandsQuery.recordcount GT 0>
									<div class="col-12">
										<h3>Islands</h3>
										<ul class="list-group py-3 border-top list-group-horizontal flex-wrap rounded-0 border-dark">
											<cfloop query="islandsQuery">
												<li class="list-group-item col-12 col-md-3 float-left">
													<a class="h4" href="/SpecimenResults.cfm?island=#encodeForUrl(islandsQuery.island)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">
														#continent_ocean#:
														#islandsQuery.island#
													</a>
												</li>
											</cfloop>
										</ul>
									</div>
								</cfif>

								<cfquery name="collectors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collectors_result">
									SELECT DISTINCT preferred_agent_name.agent_name, collector.agent_id, person.last_name
									FROM
										underscore_relation 
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
										left join collector on underscore_relation.collection_object_id = collector.collection_object_id
										left join preferred_agent_name on collector.agent_id = preferred_agent_name.agent_id
										left join person on preferred_agent_name.agent_id = person.person_id
									WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										and flat.collectors is not null
										and collector.collector_role = 'c'
									ORDER BY person.last_name, preferred_agent_name.agent_name asc
								</cfquery>
								<cfif collectors.recordcount GT 0>
									<div class="col-12">
										<h3>Collectors</h3>
										<ul class="list-group py-3 border-top list-group-horizontal flex-wrap rounded-0 border-dark">
											<cfloop query="collectors">
												<li class="list-group-item col-12 col-md-3 float-left">
													<a class="h4" href="/agents/Agent.cfm?agent_id=#collectors.agent_id#" target="_blank">#collectors.agent_name#</a>
												</li>
											</cfloop>
										</ul>
									</div>
								</cfif>
							</div>
						</div>
					</div><!--- end rowEverythihngElse--->
				</article>
			</div>
		</main>
	</cfloop>
<script>
!(function (d){
// Variables to target our base class,  get carousel items, count how many carousel items there are, set the slide to 0 (which is the number that tells us the frame we're on), and set motion to true which disables interactivity.
var itemClassName = "carouselImageX";
	items = d.getElementsByClassName(itemClassName),
	totalItems = items.length,
	slide = 0,
	moving = true; 

// To initialise the carousel we'll want to update the DOM with our own classes
function setInitialClasses() {

	// Target the last, initial, and next items and give them the relevant class.
	// This assumes there are three or more items.
	items[totalItems - 1].classList.add("prev");
	items[0].classList.add("active");
	items[1].classList.add("next");
}

// Set click events to navigation buttons

function setEventListeners() {
	var next = d.getElementsByClassName('carousel__buttonX--next')[0],
		prev = d.getElementsByClassName('carousel__buttonX--prev')[0];

	next.addEventListener('click', moveNext);
	prev.addEventListener('click', movePrev);
}

// Disable interaction by setting 'moving' to true for the same duration as our transition (0.5s = 500ms)
function disableInteraction() {
	moving = true;

	setTimeout(function(){
		moving = false
	}, 500);
}

function moveCarouselTo(slide) {

	// Check if carousel is moving, if not, allow interaction
	if(!moving) {

	// temporarily disable interactivity
	disableInteraction();

	// Preemptively set variables for the current next and previous slide, as well as the potential next or previous slide.
	var newPrevious = slide - 1,
		newNext = slide + 1,
		oldPrevious = slide - 2,
		oldNext = slide + 2;

	// Test if carousel has more than three items
	if ((totalItems - 1) > 3) {

		// Checks if the new potential slide is out of bounds and sets slide numbers
		if (newPrevious <= 0) {
			oldPrevious = (totalItems - 1);
		} else if (newNext >= (totalItems - 1)){
			oldNext = 0;
		}

		// Check if current slide is at the beginning or end and sets slide numbers
		if (slide === 0) {
			newPrevious = (totalItems - 1);
			oldPrevious = (totalItems - 2);
			oldNext = (slide + 1);
		} else if (slide === (totalItems -1)) {
			newPrevious = (slide - 1);
			newNext = 0;
			oldNext = 1;
		}

		// Now we've worked out where we are and where we're going, by adding and removing classes, we'll be triggering the carousel's transitions.

		// Based on the current slide, reset to default classes.
		items[oldPrevious].className = itemClassName;
		items[oldNext].className = itemClassName;

		// Add the new classes
		items[newPrevious].className = itemClassName + " prev";
		items[slide].className = itemClassName + " active";
		items[newNext].className = itemClassName + " next";
		}
	}
}

// Next navigation handler
function moveNext() {

	// Check if moving
	if (!moving) {

	// If it's the last slide, reset to 0, else +1
	if (slide === (totalItems - 1)) {
		slide = 0;
	} else {
		slide++;
	}

	// Move carousel to updated slide
		moveCarouselTo(slide);
	}
}

// Previous navigation handler
function movePrev() {

	// Check if moving
	if (!moving) {

	// If it's the first slide, set as the last slide, else -1
	if (slide === 0) {
		slide = (totalItems - 1);
	} else {
		slide--;
	}

	// Move carousel to updated slide
		moveCarouselTo(slide);
	}
}

// Initialise carousel
function initCarousel() {
	setInitialClasses();
	setEventListeners();

	// Set moving to false now that the carousel is ready
	moving = false;
}

// make it rain
	initCarousel();

}(document));

</script>
</cfoutput> 

<cfinclude template = "/shared/_footer.cfm">
