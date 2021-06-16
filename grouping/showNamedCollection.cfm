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
							<div class="col-12 border-dark mt-4">
								<h1 class="pb-2" style="border-bottom: 8px solid ##000">#getNamedGroup.collection_name#</h1>
							</div>
						</div>
						<div class="row mx-0">
							<div class="col-12 col-md-6 float-left mt-0">
								<div class="mb-4 pb-3" style="border-bottom: 8px solid ##000">
									<h2 class="">Collection Overview</h2>
									<p class="">#getNamedGroup.description#</p>
								</div>
								<!--- arbitrary html clob, could be empty, could be tens of thousands of characters --->
								<cfif len(html_description)gt 0>
									<div class="pb-2" style="border-bottom: 8px solid ##000">#getNamedGroup.html_description# </div>
								</cfif>

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
											and rownum <= 20
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
								
								<cfif getNamedGroup.agent_name NEQ '[No Agent]'>
									<h2 class="mt-2 pt-2">Associated Agent</h2>
									<p class="">#getNamedGroup.agent_name#</p>
								</cfif>
								<cfset specimenImagesShown = specimenImageQuery.recordcount>
								<cfif specimenImagesShown GT 0>
									<cfif specimenImageQuery.recordcount LT specImageCt.ct>
										<cfset shown = " (#specimenImagesShown# shown)">
									<cfelse>
										<cfset shown = "">
									</cfif>
									<h2 class="mt-4 pt-3" style="border-top: 8px solid ##000">Specimen Images</h2>
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
								<h2 class="mt-4 pt-3" style="border-top: 8px solid ##000">Other Media</h2>
								<hr>
								<cfquery name="localityImageQuery"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="localityImageQuery_result">
									SELECT DISTINCT media_uri, preview_uri,media_type,
										MCZBASE.get_media_descriptor(media.media_id) as alt,
										MCZBASE.get_media_credit(media.media_id) as credit
									FROM
										underscore_collection
										left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
										left join media_relations on media_relations.related_primary_key = underscore_relation.underscore_collection_id
										left join media on media_relations.media_id = media.media_id
									WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										AND media_relations.media_relationship = 'shows locality'
										AND media.media_type = 'image'
										AND MCZBASE.is_media_encumbered(media.media_id)  < 1
								</cfquery>
								<div class="row">
									<div class="col-12 col-md-4">
										<h3>Locality Images</h3>
										<p>Maps and Collecting Event</p> 
										<cfset localityImageCount = localityImageQuery.recordcount>
										<cfif localityImageCount GT 0>
											<p>#localityImageCount# Locality Images</p>
											<!--Carousel Wrapper-->
											<div id="carousel-example-4" class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" > 
												<!--Indicators-->
												<ol class="carousel-indicators">
													<cfset active = 'class="active"' >
													<cfloop index="i" from="0" to="#localityImageCount#">
														<li data-target="##carousel-example-4" data-slide-to="#i#" #active#></li>
														<cfset active = '' >
													</cfloop>
												</ol>
												<!--/.Indicators---> 
												<!--Slides-->
												<div class="carousel-inner" role="listbox">
													<cfset active = "active" >
													<cfloop query="localityImageQuery">
														<div class="carousel-item #active#">
															<div class="view">
																<img class="d-block w-100" src="#localityImageQuery.media_uri#" alt="#localityImageQuery.alt#"/>
															   <div class="mask rgba-black-strong"></div>
															</div>
															<div class="carousel-caption">
																<h3 class="h3-responsive">#localityImageQuery.alt#</h3>
																<p>#localityImageQuery.credit#</p>
															</div>
														</div>
														<cfset active = "" >
													</cfloop>
												</div>
												<!--/.Slides--> 
												<!--Controls--> 
												<a class="carousel-control-prev" href="##carousel-example-4" role="button" data-slide="prev" style="top:-5%;"> 
													<span class="carousel-control-prev-icon" aria-hidden="true"></span> 
													<span class="sr-only">Previous</span> 
												</a> 
												<a class="carousel-control-next" href="##carousel-example-4" role="button" data-slide="next" style="top:-5%;"> 
													<span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> 
												</a> 
												<!--/.Controls--> 
											</div>
										<!--/.Carousel Wrapper-->
										</cfif><!--- end specimen image loop --->

									</div>
									<div class="col-12 col-md-4">
										<h3>Journals, Notes, Ledgers</h3>
										<p>Library scans of written material</p>
										<div id="carouselExampleControls3" class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" >
											<div class="carousel-inner">
												<div class="carousel-item active"> 
													<img class="d-block w-100" src="/images/ledger.PNG" alt="First slide">
													<div class="carousel-caption" style="position: relative;color: black;padding-top:20px;left:0;">
														<h3 class="h3-responsive">Ledger Scan</h3>
														<p>MCZ/Ernst Mayr Library</p>
													</div> 
												</div>
												<div class="carousel-item"> 
													<img class="d-block w-100" src="/images/Hassler_expedition_route.png" alt="Second slide">
													<div class="carousel-caption" style="position: relative;color: black;padding-top:20px;left:0;">
														<h3 class="h3-responsive">Annotation of Map/ Collecting route</h3>
														<p>MCZ note example</p>
													</div> 
												</div>
												<div class="carousel-item"> 
													<img class="d-block w-100" src="/images/IP_semliki_notes.PNG" alt="Third slide">
													<div class="carousel-caption" style="position: relative;color: black;padding-top:20px;left:0;">
														<h3 class="h3-responsive">Semliki Notes</h3>
														<p>MCZ IP dept.</p>
													</div> 
												</div>
											</div>
											<a class="carousel-control-prev" href="##carouselExampleControls3" role="button" data-slide="prev" style="top:-46%;"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls3" role="button" data-slide="next" style="top:-46%;"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
										</div>
									</div>
									<div class="col-12 col-md-4 ">
										<h3>Collectors and other agents</h3>
										<p>Collector, vessel, institution, and related group images. </p>
										<div id="carouselExampleControls2"  class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" >
											<div class="carousel-inner">
												<div class="carousel-item active"> 
													<img class="d-block w-100" src="/images/student_images.png" alt="">
													<div class="carousel-caption" style="position: relative;color: black;padding-top:20px;left:0;">
														<h3 class="h3-responsive">Collector Images</h3>
														<p>MCZ historical images (placeholder)</p>
													</div>
												</div> 
											</div>
										</div>
										<a class="carousel-control-prev" href="##carouselExampleControls2" role="button" data-slide="prev" style="top:-5%;"> 
											<span class="carousel-control-prev-icon" aria-hidden="true"></span> 
											<span class="sr-only">Previous</span> 
										</a> 
										<a class="carousel-control-next" href="##carouselExampleControls2" role="button" data-slide="next" style="top:-5%;">
											<span class="carousel-control-next-icon" aria-hidden="true"></span> 
											<span class="sr-only">Next</span> 
										</a> 
									</div>
								</div>
							</div>
							<div class="col-12 col-md-6 mt-1 float-left">
								<div class="row">
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
											<ul class="list-group py-3 border-top list-group-horizontal flex-wrap border-bottom rounded-0 border-dark">
												<cfloop query="taxonQuery">
													<li class="list-group-item col-3 float-left">
														<a class="h4" href="/Taxa.cfm?execute=true&method=getTaxa&action=search&#taxonQuery.rank#=%3D#taxonQuery.taxonlink#">#taxonQuery.taxon#</a>
													</li>
												</cfloop>
											</ul>
										</div>
									</cfif>
									<cfquery name="country"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="country_result">
										SELECT DISTINCT flat.country as country
										FROM
											underscore_collection
											left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
										WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											and flat.country is not null
										ORDER BY flat.country asc
									</cfquery>
									<cfif country.recordcount GT 0>
										<div class="col-12">
											<h3>Countries</h3>
											<ul class="list-group py-3 list-group-horizontal flex-wrap border-top border-bottom rounded-0 border-dark">
												<cfloop query="country">
													<li class="list-group-item col-3 float-left"><a class="h4" href="##">#country.country#</a></li>
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
											<ul class="list-group d-inline-block py-3 border-top border-bottom rounded-0 border-dark w-100">
												<cfloop query="agents">
													<li class="list-group-item list-group-horizontal col-3 flex-wrap float-left d-inline mr-2">
														<a class="h4" href="/agents/Agent.cfm?agent_id=#agents.agent_id#" target="_blank">#agents.agent_name#</a>
													</li>
												</cfloop>
											</ul>
										</div>
									</cfif>
<!---									<cfquery name="specimens"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
									<cfif specimens.recordcount GT 0>
										<div class="col-12">
											<h3>Specimen Records</h3>
											<ul class="list-group d-inline-block py-3 border-top border-bottom rounded-0 border-dark">
												<cfloop query="specimens">
													<li class="list-group-item float-left d-inline mr-2" style="width:105px">
														<a href="/guid/#specimens.guid#" target="_blank">#specimens.guid#</a> #specimens.scientific_name#
													</li>
												</cfloop>
											</ul>
										</div>
									</cfif>--->
									<script type="text/javascript">
										var cellsrenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
											if (value < 1) {
												return '<a href="/guid/'+value+'"><span style="margin: 4px; float: ' + columnproperties.cellsalign + '; color: ##0000ff;">' + value + '</span></a>';
											}
											else {
												return '<a href="##"><span style="margin: 4px; float: ' + columnproperties.cellsalign + '; color: ##008000;">' + value + '</span></a>';
											}
										}
										$(document).ready(function () {
											//var theme = 'black';
											var source =
											{
												datatype: "json",
												datafields:
												[
													{ name: 'GUID', type: 'string' },
													{ name: 'SCIENTIFIC_NAME', type: 'string' },
													{ name: 'VERBATIM_DATE', type: 'string' },
													{ name: 'LOCALITY', type: 'string' },
													{ name: 'FULL_TAXON_NAME', type: 'string' }
												],
												url: '/grouping/component/functions.cfc?method=getSpecimens'
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
												pagesize: '50',
												pagesizeoptions: ['5','50','100'],
												columnsresize: false,
												autoshowfiltericon: false,
												autoshowcolumnsmenubutton: false,
												altrows: true,
												showtoolbar: false,
												enabletooltips: true,
												pageable: true,
												columns: [
													{ text: 'GUID', datafield: 'GUID', width:'130',cellsrenderer: cellsrenderer },
													{ text: 'Scientific Name', datafield: 'SCIENTIFIC_NAME', width:'250' },
													{ text: 'Date Collected', datafield: 'VERBATIM_DATE', width:'150'},
													{ text: 'Locality', datafield: 'SPEC_LOCALITY',width:'300' },
													{ text: 'Taxonomy', datafield: 'FULL_TAXON_NAME', width:'300'}
												]
											});
										});
									</script>

									<div id="jqxgrid"></div>
										
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
