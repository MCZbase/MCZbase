<cfset pageTitle = "Named Group">
<cfinclude template="/shared/_header.cfm">

<cfoutput>
	<style>
		a:focus {box-shadow: none;}
	</style>
	<cfif not isDefined("underscore_collection_id") OR len(underscore_collection_id) EQ 0>
		<!--- TODO: Remove temporary hard coded default collection, replace with redirect to search if not provided an underscore collection id. --->
		<cfset underscore_collection_id = "161">
	</cfif>
	<cfquery name="getNamedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getNamedGroup_result">
		select underscore_collection_id, collection_name, description, underscore_agent_id, html_description, agent_name,
			case 
				when underscore_agent_id is null then '[No Agent]'
			else 
				MCZBASE.get_agentnameoftype(underscore_agent_id, 'preferred')
			end
			as agentname,
			mask_fg
		FROM underscore_collection
			LEFT JOIN agent_name on underscore_collection.underscore_agent_id = agent_name.agent_id
		WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
	</cfquery>
	<cfloop query="getNamedGroup">
		<cfif getNamedGroup.mask_fg EQ 0 AND (NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0)>
			 <cflocation url="/errors/forbidden.cfm" addtoken="false">
		</cfif> 
		<main class="container-fluid py-3">
			<div class="row mx-0">
				<article class="w-100">
					<div class="col-12">
						<div class="row mx-0">
							<div class="col-12 border-dark mt-5">
								<h1 class="pb-2 w-100 border-bottom-black">#getNamedGroup.collection_name# 
									<div class="d-inline-block float-right"><a target="_blank" class="px-2 btn-xs btn-primary text-decoration-none" href="/grouping/NamedCollection.cfm">Search Named Groups</a></span></div>
								</h1>
							</div>
						</div>
						<div class="row">
							<div class="col-12 px-4 mt-0">
								<!--- arbitrary html clob, could be empty, could be tens of thousands of characters plus rich media content --->
								<!--- WARNING: This section MUST go at the top, and must be allowed the full width of the page --->
								<cfif len(html_description)gt 0>
									<div class="pb-2">#getNamedGroup.html_description# </div>
								</cfif>
							</div>
						</div>	
						<div class="row mx-0">
							<cfquery name="specimens"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
											{ name: 'GUID', type: 'string' },
											{ name: 'SCIENTIFIC_NAME', type: 'string' },
											{ name: 'VERBATIM_DATE', type: 'string' },
											{ name: 'HIGHER_GEOG', type: 'string' },
											{ name: 'SPEC_LOCALITY', type: 'string' },
											{ name: 'OTHERCATALOGNUMBERS', type: 'string' },
											{ name: 'FULL_TAXON_NAME', type: 'string' }
											
										],
										url: '/grouping/component/functions.cfc?method=getSpecimens&underscore_collection_id=#underscore_collection_id#'
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
											{ text: 'GUID', datafield: 'GUID', width:'150',cellsalign: 'left',cellsrenderer: cellsrenderer },
											{ text: 'Scientific Name', datafield: 'SCIENTIFIC_NAME', width:'250' },
											{ text: 'Date Collected', datafield: 'VERBATIM_DATE', width:'150'},
											{ text: 'Higher Geography', datafield: 'HIGHER_GEOG', width:'350'},
											{ text: 'Locality', datafield: 'SPEC_LOCALITY',width:'350' },
											{ text: 'Other Catalog Numbers', datafield: 'OTHERCATALOGNUMBERS',width:'350' },
											{ text: 'Taxonomy', datafield: 'FULL_TAXON_NAME', width:'350'}
											
										]
									});
								});
							</script>
							<div class="col-12 mt-3">
								<h2 class="">Specimen Records <a href="/SpecimenResults.cfm?underscore_collection_id=#encodeForURL(underscore_collection_id)#" target="_blank">(#specimens.recordcount#)</a></h2>
								<div id="jqxgrid"></div>
							</div>
						</div>
						<div class="row mx-0 clearfix">
							<div class="col-12 col-md-6 mb-4 float-left mt-0">
								<!--- obtain a random set of images, limited to a small number --->
								<cfquery name="specimenImageQuery"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="specimenImageQuery_result">
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
											AND MCZBASE.is_media_encumbered(media.media_id)  < 1
										ORDER BY DBMS_RANDOM.RANDOM
									) 
									WHERE rownum < 16
								</cfquery>
								<!--- find out how many images there are in total --->
								<cfquery name="specImageCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT count(media.media_id) as ct
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
										AND MCZBASE.is_media_encumbered(media.media_id)  < 1
								</cfquery>
								<cfset specimenImagesShown = specimenImageQuery.recordcount>
								<cfif specimenImagesShown GT 0>
									<cfif specimenImageQuery.recordcount LT specImageCt.ct>
										<cfset shown = " (#specimenImagesShown# shown)">
									<cfelse>
										<cfset shown = "">
									</cfif>
									<h2 class="mt-2 pt-3">Specimen Images</h2>
									<p>#specImageCt.ct# Specimen Images#shown#</p>
									<!--Carousel Wrapper-->
									<div id="carousel-example-2" class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" > 
										<!--Indicators-->
										<ol class="carousel-indicators">
											<cfset active = 'class="active"' >
											<cfloop index="i" from="0" to="#specimenImagesShown#">
												<li data-target="##carousel-example-2" data-slide-to="#i#" #active#></li>
												<cfset active = '' >
											</cfloop>
										</ol>
											
										<!--/.Indicators---> 
										<!--Slides-->
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
										<!--/.Slides--> 
										<!--Controls--> 
										<a class="carousel-control-prev" href="##carousel-example-2" role="button" data-slide="prev" style="top:-5%;"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carousel-example-2" role="button" data-slide="next" style="top:-5%;"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
										<!--/.Controls--> 
									</div>
									<!--/.Carousel Wrapper-->
								</cfif><!--- end specimen image loop --->
			
								<div class="row">
									<div class="col-12 col-md-4">
									<!--- obtain a random set of images, limited to a small number --->
									<cfquery name="locImageQuery"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="locImageQuery_result">
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
												AND  media_relations.media_relationship = 'shows locality'
												AND media.media_type = 'image'
												AND MCZBASE.is_media_encumbered(media.media_id)  < 1
											ORDER BY DBMS_RANDOM.RANDOM
										) 
										WHERE rownum < 16
									</cfquery>
									<!--- find out how many images there are in total --->
									<cfquery name="locImageCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										SELECT count(media.media_id) as ct
										FROM
											underscore_collection
											left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
											left join media_relations on flat.collection_object_id = media_relations.related_primary_key
											left join media on media_relations.media_id = media.media_id
										WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											AND flat.guid IS NOT NULL
											AND media_relations.media_relationship = 'shows locality' 
											AND media.media_type = 'image'
											AND MCZBASE.is_media_encumbered(media.media_id)  < 1
									</cfquery>
									<cfset locImagesShown = locImageQuery.recordcount>
									<cfif locImagesShown GT 0>
										<cfif locImageQuery.recordcount LT locImageCt.ct>
											<cfset shown = " (#locImagesShown# shown)">
										<cfelse>
											<cfset shown = "">
										</cfif>
										<h2 class="mt-2 pt-3">Place/Event Images</h2>
										<p>#locImageCt.ct# Place/Event Images#shown#</p>
										<!--Carousel Wrapper-->
										<div id="carousel-example-3" class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" > 
											<!--Indicators-->
											<ol class="carousel-indicators">
												<cfset active = 'class="active"' >
												<cfloop index="i" from="0" to="#locImagesShown#">
													<li data-target="##carousel-example-3" data-slide-to="#i#" #active#></li>
													<cfset active = '' >
												</cfloop>
											</ol>

											<!--/.Indicators---> 
											<!--Slides-->
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
											<!--/.Slides--> 
											<!--Controls--> 
											<a class="carousel-control-prev" href="##carousel-example-3" role="button" data-slide="prev" style="top:-5%;"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carousel-example-3" role="button" data-slide="next" style="top:-5%;"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
											<!--/.Controls--> 
										</div>
										<!--/.Carousel Wrapper-->
									</cfif><!--- end loc image loop --->

									</div>
									<div class="col-12 col-md-4">
									<!--- obtain a random set of collector images, limited to a small number --->
									<cfquery name="collImageQuery"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collImageQuery_result">
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
												AND  media_relations.media_relationship = 'shows agent'
												AND media.media_type = 'image'
												AND MCZBASE.is_media_encumbered(media.media_id)  < 1
											ORDER BY DBMS_RANDOM.RANDOM
										) 
										WHERE rownum < 16
									</cfquery>
									<!--- find out how many images there are in total --->
									<cfquery name="collImageCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										SELECT count(media.media_id) as ct
										FROM
											underscore_collection
											left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
											left join media_relations on flat.collection_object_id = media_relations.related_primary_key
											left join media on media_relations.media_id = media.media_id
										WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											AND flat.guid IS NOT NULL
											AND media_relations.media_relationship = 'shows agent' 
											AND media.media_type = 'image'
											AND MCZBASE.is_media_encumbered(media.media_id)  < 1
									</cfquery>
									<cfset collImagesShown = collImageQuery.recordcount>
									<cfif collImagesShown GT 0>
										<cfif collImageQuery.recordcount LT collImageCt.ct>
											<cfset shown = " (#collImagesShown# shown)">
										<cfelse>
											<cfset shown = "">
										</cfif>
										<h2 class="mt-2 pt-3">Agent Images</h2>
										<p>#collImageCt.ct# Agent Images#shown#</p>
										<!--Carousel Wrapper-->
										<div id="carousel-example-4" class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" > 
											<!--Indicators-->
											<ol class="carousel-indicators">
												<cfset active = 'class="active"' >
												<cfloop index="i" from="0" to="#collImagesShown#">
													<li data-target="##carousel-example-4" data-slide-to="#i#" #active#></li>
													<cfset active = '' >
												</cfloop>
											</ol>

											<!--/.Indicators---> 
											<!--Slides-->
											<div class="carousel-inner" role="listbox">
												<cfset active = "active" >
												<cfloop query="collImageQuery">
													<div class="carousel-item #active#">
														<div class="view">
															<img class="d-block w-100" src="#collImageQuery.media_uri#" alt="#collImageQuery.alt#"/>
															<div class="mask rgba-black-strong"></div>
														</div>
														<div class="carousel-caption">
															<h3 class="h3-responsive">#collImageQuery.alt#</h3>
															<p>#collImageQuery.credit#</p>
														</div>
													</div>
													<cfset active = "" >
												</cfloop>
											</div>
											<!--/.Slides--> 
											<!--Controls--> 
											<a class="carousel-control-prev" href="##carousel-example-4" role="button" data-slide="prev" style="top:-5%;"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carousel-example-4" role="button" data-slide="next" style="top:-5%;"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
											<!--/.Controls--> 
										</div>
										<!--/.Carousel Wrapper-->
									</cfif><!--- end agent image loop --->
									</div>
									<div class="col-12 col-md-4">
									<!--- obtain a random set of audio/video images, limited to a small number --->
									<cfquery name="AVmediaImageQuery"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="AVmediaImageQuery_result">
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
												AND media.media_type = 'video'
												AND MCZBASE.is_media_encumbered(media.media_id)  < 1
											ORDER BY DBMS_RANDOM.RANDOM
										) 
										WHERE rownum < 16
									</cfquery>
									<!--- find out how many images there are in total --->
									<cfquery name="AVmediaImageCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										SELECT count(media.media_id) as ct
										FROM
											underscore_collection
											left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
											left join media_relations on flat.collection_object_id = media_relations.related_primary_key
											left join media on media_relations.media_id = media.media_id
										WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											AND flat.guid IS NOT NULL
											AND media.media_type = 'video'
											AND MCZBASE.is_media_encumbered(media.media_id)  < 1
									</cfquery>
									<cfset AVmediaImagesShown = AVmediaImageQuery.recordcount>
									<cfif AVmediaImagesShown GT 0>
										<cfif AVmediaImageQuery.recordcount LT AVmediaImageCt.ct>
											<cfset shown = " (#AVmediaImagesShown# shown)">
										<cfelse>
											<cfset shown = "">
										</cfif>
										<h2 class="mt-2 pt-3">Agent Images</h2>
										<p>#AVmediaImageCt.ct# Agent Images#shown#</p>
										<!--Carousel Wrapper-->
										<div id="carousel-example-5" class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" > 
											<!--Indicators-->
											<ol class="carousel-indicators">
												<cfset active = 'class="active"' >
												<cfloop index="i" from="0" to="#AVmediaImagesShown#">
													<li data-target="##carousel-example-5" data-slide-to="#i#" #active#></li>
													<cfset active = '' >
												</cfloop>
											</ol>

											<!--/.Indicators---> 
											<!--Slides-->
											<div class="carousel-inner" role="listbox">
												<cfset active = "active" >
												<cfloop query="AVmediaImageQuery">
													<div class="carousel-item #active#">
														<div class="view">
															<img class="d-block w-100" src="#AVmediaImageQuery.media_uri#" alt="#AVmediaImageQuery.alt#"/>
															<div class="mask rgba-black-strong"></div>
														</div>
														<div class="carousel-caption">
															<h3 class="h3-responsive">#AVmediaImageQuery.alt#</h3>
															<p>#AVmediaImageQuery.credit#</p>
														</div>
													</div>
													<cfset active = "" >
												</cfloop>
											</div>
											<!--/.Slides--> 
											<!--Controls--> 
											<a class="carousel-control-prev" href="##carousel-example-5" role="button" data-slide="prev" style="top:-5%;"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carousel-example-5" role="button" data-slide="next" style="top:-5%;"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
											<!--/.Controls--> 
										</div>
										<!--/.Carousel Wrapper-->
									</cfif><!--- end audio video image loop --->
									</div>
			
								</div>
							</div>
							<div class="col-12 col-md-6 mt-0 mt-md-5 float-left">
								<div class="my-2 py-3 border-bottom-black">
									<h2 class="h2">Overview</h2>
									<p class="">#getNamedGroup.description#</p>
								</div>
								<cfif getNamedGroup.agent_name NEQ '[No Agent]'>
									<div class="mt-2 py-3">
										<h3 class="mt-2 pt-2">Associated Agent</h2>
										<p class="rounded-0 border-top border-dark">
											<a class="h4 px-2 d-block mt-3" href="/agents/Agent.cfm?agent_id=#underscore_agent_id#">#getNamedGroup.agent_name#</a>
										</p>
									</div>
								</cfif>
								<div class="row pb-3">
									<cfquery name="taxonQuery"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="taxonQuery_result">
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
										<cfquery name="taxonQuery"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="taxonQuery_result">
											SELECT DISTINCT flat.phylclass || ': ' || flat.phylorder  as taxon, flat.phylorder as taxonlink, 'phylorder' as rank,
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
										<cfquery name="taxonQuery"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="taxonQuery_result">
											SELECT DISTINCT flat.phylorder || ': ' || flat.family  as taxon, flat.family as taxonlink, 'family' as rank,
												flat.phylorder, flat.family
											FROM
												underscore_collection
												left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
												left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
													on underscore_relation.collection_object_id = flat.collection_object_id
											WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
												and flat.PHYLCLASS is not null  and flat.family is not null
											ORDER BY flat.phylorder asc, flat.family asc
										</cfquery>
									</cfif>
									<cfif taxonQuery.recordcount GT 0>
										<div class="col-12">
											<h3>Taxa</h3>
											<ul class="list-group py-3 list-group-horizontal flex-wrap rounded-0 border-top border-dark">
												<cfloop query="taxonQuery">
													<li class="list-group-item col-12 col-md-3 float-left">
														<a class="h4" href="/Taxa.cfm?execute=true&method=getTaxa&action=search&#taxonQuery.rank#=%3D#taxonQuery.taxonlink#">#taxonQuery.taxon#</a>
													</li>
												</cfloop>
											</ul>
										</div>
									</cfif>
									<cfquery name="marine"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="marine_result">
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
											<h3>Oceans</h3>
											<ul class="list-group py-3 list-group-horizontal flex-wrap border-top rounded-0 border-dark">
												<cfloop query="marine">
													<li class="list-group-item col-12 col-md-3 float-left">
														<a class="h4" href="/SpecimenResults.cfm?continent_ocean=#encodeForURL(marine.ocean)#&underscore_collection_id=#getNamedGroup.underscore_collection_id#">#marine.ocean#</a>
													</li>
												</cfloop>
											</ul>
										</div>
									</cfif>
									<cfquery name="geogQuery"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="geogQuery_result">
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
										<cfquery name="geogQuery"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="geogQuery_result">
											SELECT DISTINCT flat.country || ': ' || flat.state_prov  as geog, flat.state_prov as geoglink, 'state_prov' as rank,
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
														<a class="h4" href="/SpecimenResults.cfm?#encodeForUrl(geogQuery.rank)#=#encodeForUrl(geogQuery.geoglink)#&underscore_collection_id=#getNamedGroup.underscore_collection_id#">#geogQuery.geog#</a>
													</li>
												</cfloop>
											</ul>
										</div>
									</cfif>
									<cfquery name="islandsQuery"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="islandsQuery_result">
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
														<a class="h4" href="/SpecimenResults.cfm?island=#encodeForUrl(islandsQuery.island)#&underscore_collection_id=#getNamedGroup.underscore_collection_id#">
															#islandsQuery.island#
														</a>
													</li>
												</cfloop>
											</ul>
										</div>
									</cfif>
									<cfquery name="agents"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="agents_result">
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
						</div>
					</div>
				</article>
			</div>
		</main>
	</cfloop>
</cfoutput> 
<!--- class="container" --->

<cfinclude template = "/shared/_footer.cfm">
