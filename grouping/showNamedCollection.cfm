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
		a:focus {box-shadow: none;}
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
									underscore_collection
									left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
									left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
										on underscore_relation.collection_object_id = flat.collection_object_id
								WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
									and flat.guid is not null
								ORDER BY flat.guid asc
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
										url: '/grouping/component/search.cfc?method=getSpecimensInGroup&underscore_collection_id=#underscore_collection_id#',
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

						<div class="row mx-0 clearfix" id="everythingElseRow">
							<!--- This row holds everything else --->

							<cfset leftHandColumnOn = false>
			
							<!--- count images of different types to decide if there will be a left hand image column or not --->
							<!--- obtain a random set of images, limited to a small number, use only displayable images (jpegs and pngs) --->
							<cfquery name="specimenImageQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="specimenImageQuery_result">
								SELECT * FROM (
									SELECT DISTINCT media_uri, preview_uri,media_type,
										MCZBASE.get_media_descriptor(media.media_id) as alt,
										MCZBASE.get_media_credit(media.media_id) as credit,
										flat.guid
									FROM
										underscore_collection
										left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
										left join media_relations on flat.collection_object_id = media_relations.related_primary_key
										left join media on media_relations.media_id = media.media_id
									WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										AND flat.guid IS NOT NULL
										AND media_relations.media_relationship = 'shows cataloged_item'
										AND media.media_type = 'image'
										AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
										AND MCZBASE.is_media_encumbered(media.media_id) < 1
									ORDER BY DBMS_RANDOM.RANDOM
								) 
								WHERE rownum < 16
							</cfquery>
							<!--- obtain a random set of locality images, limited to a small number --->
							<cfquery name="locImageQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="locImageQuery_result">
								SELECT * FROM (
									SELECT DISTINCT media_uri, preview_uri,media_type,
										MCZBASE.get_media_descriptor(media.media_id) as alt,
										MCZBASE.get_media_credit(media.media_id) as credit
									FROM
										underscore_collection
										left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
										left join media_relations on flat.locality_id = media_relations.related_primary_key
										left join media on media_relations.media_id = media.media_id
									WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										AND flat.guid IS NOT NULL
										AND media_relations.media_relationship = 'shows locality'
										AND media.media_type = 'image'
										AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
										AND MCZBASE.is_media_encumbered(media.media_id) < 1
									ORDER BY DBMS_RANDOM.RANDOM
								) 
								WHERE rownum < 16
							</cfquery>
							<!--- obtain a random set of collecting event images, limited to a small number --->
							<cfquery name="collEventImageQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="locImageQuery_result">
								SELECT * FROM (
									SELECT DISTINCT media_uri, preview_uri,media_type,
										MCZBASE.get_media_descriptor(media.media_id) as alt,
										MCZBASE.get_media_credit(media.media_id) as credit
									FROM
										underscore_collection
										left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
										left join media_relations on flat.collecting_event_id = media_relations.related_primary_key
										left join media on media_relations.media_id = media.media_id
									WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										AND flat.guid IS NOT NULL
										AND media_relations.media_relationship = 'shows collecting_event'
										AND media.media_type = 'image'
										AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
										AND MCZBASE.is_media_encumbered(media.media_id) < 1
									ORDER BY DBMS_RANDOM.RANDOM
								) 
								WHERE rownum < 16
							</cfquery>
							<!--- obtain a random set of collector images, limited to a small number --->
							<cfquery name="collectorImageQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collectorImageQuery_result">
								SELECT * FROM (
									SELECT DISTINCT media_uri, preview_uri,media_type,
										MCZBASE.get_media_descriptor(media.media_id) as alt,
										MCZBASE.get_media_credit(media.media_id) as credit
									FROM
										underscore_collection
										left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
										left join collector on flat.collection_object_id = collector.collection_object_id
										left join media_relations on collector.agent_id = media_relations.related_primary_key
										left join media on media_relations.media_id = media.media_id
									WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										AND flat.guid IS NOT NULL
										AND collector.collector_role = 'c'
										AND media_relations.media_relationship = 'shows agent'
										AND media.media_type = 'image'
										AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
										AND MCZBASE.is_media_encumbered(media.media_id) < 1
									ORDER BY DBMS_RANDOM.RANDOM
								) 
								WHERE rownum < 16
							</cfquery>
							<cfif specimenImageQuery.recordcount GT 0 OR locImageQuery.recordcount GT 0 OR collectorImageQuery.recordcount GT 0 OR collEventImageQuery.recordcount GT 0>
								<!--- display images in left hand column --->
								<div class="col-12 col-md-6 mb-4 float-left mt-0">
									<cfset leftHandColumnOn = true>
									<div class="row">

										<cfif specimenImageQuery.recordcount gt 0>
											<div class="col-12">
												<!--- find out how many specimen images there are in total --->
												<cfquery name="specImageCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
													SELECT count(distinct media.media_id) as ct
													FROM
														underscore_collection
														left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
														left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
															on underscore_relation.collection_object_id = flat.collection_object_id
														left join media_relations on flat.collection_object_id = media_relations.related_primary_key
														left join media on media_relations.media_id = media.media_id
													WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
														AND flat.guid IS NOT NULL
														AND media_relations.media_relationship = 'shows cataloged_item'
														AND media.media_type = 'image'
														AND MCZBASE.is_media_encumbered(media.media_id) < 1
												</cfquery>
												<cfset specimenImagesShown = specimenImageQuery.recordcount>
												<cfif specimenImagesShown EQ 0>
													<cfif specimenImageQuery.recordcount GT 0>
														<!--- TODO: Add a list or link to other media records. This is a placeholder, unreachable code --->
														<h2 class="mt-2 pt-3">Specimen Images</h2>
														<p>#specImageCt.ct# Specimen Images (#specimenImageQuery.recordcount#)</p>
														<div>None are directly visible as images</div>
													</cfif>
												<cfelse>
													<cfif specimenImageQuery.recordcount LT specImageCt.ct>
														<cfset shown = " (#specimenImagesShown# shown)">
													<cfelse>
														<cfset shown = "">
													</cfif>
													<h2 class="mt-2 pt-3">Specimen Images</h2>
													<p>#specImageCt.ct# Specimen Images#shown#</p>
													<div id="specimen_image-carousel" class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" > 
														<ol class="carousel-indicators">
															<cfset active = 'class="active"' >
															<cfloop index="i" from="0" to="#specimenImagesShown#">
																<li data-target="##specimen_image-carousel" data-slide-to="#i#" #active#></li>
																<cfset active = '' >
															</cfloop>
														</ol>
														<div class="carousel-inner" role="listbox">
															<cfset active = "active" >
															<cfloop query="specimenImageQuery">
																<div class="carousel-item #active#">
																	<div class="view">
																		<img class="d-block w-100" src="#specimenImageQuery.media_uri#" alt="#specimenImageQuery.alt#"/>
																		<div class="mask rgba-black-strong"></div>
																	</div>
																	<div class="carousel-caption">
																		<h3 class="h3-responsive">#specimenImageQuery.alt#</h3>
																		<p>#specimenImageQuery.credit#</p>
																	</div>
																</div>
																<cfset active = "" >
															</cfloop>
														</div>
														<a class="carousel-control-prev" href="##specimen_image-carousel" role="button" data-slide="prev" style="top:-5%;"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##specimen_image-carousel" role="button" data-slide="next" style="top:-5%;"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
													</div>
												</cfif>
											</div>
										</cfif><!--- end specimen images block --->

										<cfif locImageQuery.recordcount GT 0>
											<div class="col-12">
												<!--- find out how many locality images there are in total --->
												<cfquery name="locImageCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
													SELECT count(distinct media.media_id) as ct
													FROM
														underscore_collection
														left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
														left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
															on underscore_relation.collection_object_id = flat.collection_object_id
														left join media_relations on flat.locality_id = media_relations.related_primary_key
														left join media on media_relations.media_id = media.media_id
													WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
														AND flat.guid IS NOT NULL
														AND media_relations.media_relationship = 'shows locality' 
														AND media.media_type = 'image'
														AND MCZBASE.is_media_encumbered(media.media_id) < 1
												</cfquery>
												<cfset locImagesShown = locImageQuery.recordcount>
												<cfif locImagesShown GT 0>
													<cfif locImageQuery.recordcount LT locImageCt.ct>
														<cfset shown = " (#locImagesShown# shown)">
													<cfelse>
														<cfset shown = "">
													</cfif>
													<h2 class="mt-2 pt-3">Locality Images</h2>
													<p>#locImageCt.ct# Locality Images#shown#</p>
													<div id="carousel-example-3" class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" > 
														<ol class="carousel-indicators">
															<cfset active = 'class="active"' >
															<cfloop index="i" from="0" to="#locImagesShown#">
																<li data-target="##carousel-example-3" data-slide-to="#i#" #active#></li>
																<cfset active = '' >
															</cfloop>
														</ol>
														<div class="carousel-inner" role="listbox">
															<cfset active = "active" >
															<cfloop query="locImageQuery">
																<div class="carousel-item #active#">
																	<div class="view">
																		<img class="d-block w-100" src="#locImageQuery.media_uri#" alt="#locImageQuery.alt#"/>
																		<div class="mask rgba-black-strong"></div>
																	</div>
																	<div class="carousel-caption">
																		<h3 class="h3-responsive">#locImageQuery.alt#</h3>
																		<p>#locImageQuery.credit#</p>
																	</div>
																</div>
																<cfset active = "" >
															</cfloop>
														</div>
														<a class="carousel-control-prev" href="##carousel-example-3" role="button" data-slide="prev" style="top:-5%;"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carousel-example-3" role="button" data-slide="next" style="top:-5%;"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
													</div>
												</cfif>
											</div>
										</cfif><!--- end locality images block --->
			
										<cfif collEventImageQuery.recordcount GT 0>
											<div class="col-12">
												<!--- find out how many collecting event images there are in total --->
												<cfquery name="collEventImageCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
													SELECT count(distinct media.media_id) as ct
													FROM
														underscore_collection
														left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
														left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
															on underscore_relation.collection_object_id = flat.collection_object_id
														left join media_relations on flat.collecting_event_id = media_relations.related_primary_key
														left join media on media_relations.media_id = media.media_id
													WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
														AND flat.guid IS NOT NULL
														AND media_relations.media_relationship = 'shows collecting_event' 
														AND media.media_type = 'image'
														AND MCZBASE.is_media_encumbered(media.media_id) < 1
												</cfquery>
												<cfset collEventImagesShown = collEventImageQuery.recordcount>
												<cfif collEventImagesShown GT 0>
													<cfif collEventImageQuery.recordcount LT collEventImageCt.ct>
														<cfset shown = " (#collEventImagesShown# shown)">
													<cfelse>
														<cfset shown = "">
													</cfif>
													<h2 class="mt-2 pt-3">Locality Images</h2>
													<p>#collEventImageCt.ct# Collecting Event Images#shown#</p>
													<div id="carousel-example-3" class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" > 
														<ol class="carousel-indicators">
															<cfset active = 'class="active"' >
															<cfloop index="i" from="0" to="#collEventImagesShown#">
																<li data-target="##carousel-example-3" data-slide-to="#i#" #active#></li>
																<cfset active = '' >
															</cfloop>
														</ol>
														<div class="carousel-inner" role="listbox">
															<cfset active = "active" >
															<cfloop query="collEventImageQuery">
																<div class="carousel-item #active#">
																	<div class="view">
																		<img class="d-block w-100" src="#collEventImageQuery.media_uri#" alt="#collEventImageQuery.alt#"/>
																		<div class="mask rgba-black-strong"></div>
																	</div>
																	<div class="carousel-caption">
																		<h3 class="h3-responsive">#collEventImageQuery.alt#</h3>
																		<p>#collEventImageQuery.credit#</p>
																	</div>
																</div>
																<cfset active = "" >
															</cfloop>
														</div>
														<a class="carousel-control-prev" href="##carousel-example-3" role="button" data-slide="prev" style="top:-5%;"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carousel-example-3" role="button" data-slide="next" style="top:-5%;"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
													</div>
												</cfif>
											</div>
										</cfif><!--- end collecting event images block --->

										<cfif collectorImageQuery.recordcount GT 0>
											<div class="col-12">
												<!--- find out how many collector images there are in total --->
												<cfquery name="collectorImageCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
													SELECT count(distinct media.media_id) as ct
													FROM
														underscore_relation
														left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
															on underscore_relation.collection_object_id = flat.collection_object_id
														left join collector on flat.collection_object_id = collector.collection_object_id
														left join media_relations on collector.agent_id = media_relations.related_primary_key
														left join media on media_relations.media_id = media.media_id
													WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
														AND flat.guid IS NOT NULL
														AND collector.collector_role = 'c'
														AND media_relations.media_relationship = 'shows agent' 
														AND media.media_type = 'image'
														AND MCZBASE.is_media_encumbered(media.media_id) < 1 
												</cfquery>
												<cfset collectorImagesShown = collectorImageQuery.recordcount >
												<cfif collectorImagesShown GT 0>
													<cfif collectorImageQuery.recordcount LT collectorImageCt.ct >
														<cfset shown = " (#collectorImagesShown# shown)" >
													<cfelse>
														<cfset shown = "">
													</cfif>
													<h2 class="mt-2 pt-3">Images of Collectors</h2>
													<p>#collectorImageCt.ct# Collector Images#shown#</p>
													<div id="carousel-example-4" class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" > 
														<ol class="carousel-indicators">
															<cfset active = 'class="active"' >
															<cfloop index="i" from="0" to="#collectorImagesShown#">
																<li data-target="##carousel-example-4" data-slide-to="#i#" #active#></li>
																<cfset active = "">
															</cfloop>
														</ol>
														<div class="carousel-inner" role="listbox">
															<cfset active = "active" >
															<cfloop query="collectorImageQuery">
																<div class="carousel-item #active#">
																	<div class="view">
																		<img class="d-block w-100" src="#collectorImageQuery.media_uri#" alt="#collectorImageQuery.alt#"/>
																		<div class="mask rgba-black-strong"></div>
																	</div>
																	<div class="carousel-caption">
																		<h3 class="h3-responsive">#collectorImageQuery.alt#</h3>
																		<p>#collectorImageQuery.credit#</p>
																	</div>
																</div>
																<cfset active = "" >
															</cfloop>
														</div>
														<a class="carousel-control-prev" href="##carousel-example-4" role="button" data-slide="prev" style="top:-5%;"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carousel-example-4" role="button" data-slide="next" style="top:-5%;"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
													</div>
												</cfif>
											</div>
										</cfif><!--- end has collector images --->

									</div><!--- end row for image blocks --->
								</div><!--- end col-md-6 for images --->
							</cfif><!--- end has any kind of images --->
		
							<cfif leftHandColumnOn >
								<cfset hasleftcolumnclass = "mt-md-5">
							<cfelse>
								<cfset hasleftcolumnclass = "" >
							</cfif>
							<div class="col mt-0 #hasleftcolumnclass# float-left">
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
											underscore_collection
											left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
										WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											and flat.PHYLCLASS is not null
										ORDER BY flat.phylclass asc
									</cfquery>
									<cfif taxonQuery.recordcount GT 0 AND taxonQuery.recordcount LT 5 >
										<!--- try expanding to orders instead if very few classes --->
										<cfquery name="taxonQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="taxonQuery_result">
											SELECT DISTINCT flat.phylclass || ': ' || flat.phylorder as taxon, flat.phylorder as taxonlink, 'phylorder' as rank,
												flat.phylclass, flat.phylorder
											FROM
												underscore_collection
												left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
												left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
													on underscore_relation.collection_object_id = flat.collection_object_id
											WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
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
												underscore_collection
												left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
												left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
													on underscore_relation.collection_object_id = flat.collection_object_id
											WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
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
											underscore_collection
											left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
										WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											and flat.country is null
											and flat.continent_ocean is not null
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
											underscore_collection
											left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
										WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											and flat.country is not null
										ORDER BY flat.country asc
									</cfquery>
									<cfif geogQuery.recordcount GT 0 AND geogQuery.recordcount LT 5 >
										<!--- try expanding to families instead if very few orders --->
										<cfquery name="geogQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="geogQuery_result">
											SELECT DISTINCT flat.country || ': ' || flat.state_prov as geog, flat.state_prov as geoglink, 'state_prov' as rank,
												flat.country, flat.state_prov
											FROM
												underscore_collection
												left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
												left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
													on underscore_relation.collection_object_id = flat.collection_object_id
											WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
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
											underscore_collection
											left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
										WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											and flat.island is not null
										ORDER BY flat.continent_ocean, flat.island asc
									</cfquery>
									<cfif islandsQuery.recordcount GT 0>
										<div class="col-12">
											<h3>Islands</h3>
											<ul class="list-group py-3 list-group-horizontal flex-wrap border-top border-bottom rounded-0 border-dark">
												<cfloop query="islandsQuery">
													<li class="list-group-item col-12 col-md-3 float-left">
														#continent_ocean#:
														<a class="h4" href="/SpecimenResults.cfm?island=#encodeForUrl(islandsQuery.island)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">
															#islandsQuery.island#
														</a>
													</li>
												</cfloop>
											</ul>
										</div>
									</cfif>
	
									<cfquery name="agents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="agents_result">
										SELECT DISTINCT preferred_agent_name.agent_name, collector.agent_id, person.last_name
										FROM
											underscore_collection
											left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
											left join collector on flat.collection_object_id = collector.collection_object_id
											left join preferred_agent_name on collector.agent_id = preferred_agent_name.agent_id
											left join person on preferred_agent_name.agent_id = person.person_id
										WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											and flat.collectors is not null
											and collector.collector_role = 'c'
										ORDER BY person.last_name, preferred_agent_name.agent_name asc
									</cfquery>
									<cfif agents.recordcount GT 0>
										<div class="col-12">
											<h3>Collectors</h3>
											<ul class="list-group d-inline-block py-3 border-top rounded-0 border-dark w-100">
												<cfloop query="agents">
													<li class="list-group-item list-group-horizontal col-3 flex-wrap float-left d-inline mr-2">
														<a class="h4" href="/agents/Agent.cfm?agent_id=#agents.agent_id#" target="_blank">#agents.agent_name#</a>
													</li>
												</cfloop>
											</ul>
										</div>
									</cfif>

								</div>
							</div>
						</div><!--- end rowEverythihngElse--->

					</div><!--- end col-12 --->
				</article>
			</div>
		</main>
	</cfloop>
</cfoutput> 
<!--- class="container" --->

<cfinclude template = "/shared/_footer.cfm">
