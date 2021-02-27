<cfset pageTitle = "Named Group">
<cfinclude template="/shared/_header.cfm">
	<cfoutput>
	<cfset underscore_collection_id = "1">
	<cfset underscore_agent_id = "117103">
	<cfquery name="getNamedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select collection_name, underscore_collection.description, underscore_agent_id, html_description, underscore_collection.mask_fg from underscore_collection where underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
	</cfquery>

	<main class="container py-3">
		<div class="row">
			<article class="w-100">
		
				<div class="col-12">
				
					<div class="row">
						<div class="col-12 col-md-6 px-0 float-left mt-4">
							<h1>#getNamedGroup.collection_name#</h1>
							<hr>
							<p>#getNamedGroup.description#</p>
							<p>#getNamedGroup.html_description#</p>
							<hr>
							<h2 class="h1 mt-5 pt-3" style="border-top: 8px solid ##000">Featured Information</h2>
							<hr>
							<div class="row">
								<div class="col-12 col-md-4">
								<cfquery name="getLocalityMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select distinct media_id from underscore_relation left outer join filtered_flat on underscore_relation.collection_object_id = filtered_flat.collection_object_id
									left outer join media_relations on filtered_flat.locality_id = media_relations.related_primary_key
									where
									media_relationship like 'shows locality' and underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
								</cfquery>	
								<cfquery name="mediaLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select distinct
									media.media_id,
									media.media_uri,
									media.mime_type,
									media.media_type,
									media.preview_uri,
									media_relations.media_relationship,
									mczbase.get_media_descriptor(media.media_id) as media_descriptor
								from
									media,
									media_relations,
									media_labels
								where
									media.media_id=media_relations.media_id and
									media.media_id=media_labels.media_id (+) and
									media_relations.media_relationship like '%cataloged_item' and
									media_relations.media_id = '#getLocalityMedia.media_id#'
									AND MCZBASE.is_media_encumbered(media.media_id) < 1
								order by media.media_type
								</cfquery>
									<h3>Localities</h3>
									<p>Maps and location images</p>
									<div id="carouselExampleControls4" class="carousel slide" data-keyboard="true">
										<div class="carousel-inner">
											<cfloop query="mediaLocality" STARTROW="1" ENDROW="3">
											<div class="carousel-item active"> <img class="d-block w-100" src="#mediaLocality.media_uri#" alt="First slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="#mediaLocality.media_uri#" alt="Second slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="#mediaLocality.media_uri#" alt="Third slide"> </div>
											</cfloop>
										</div>
										<a class="carousel-control-prev" href="##carouselExampleControls4" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
									</div>
								</div>
								<div class="col-12 col-md-4 px-3">
							<cfquery name="getCollEventMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select distinct media_id
								from underscore_relation
								left outer join filtered_flat on underscore_relation.collection_object_id = filtered_flat.collection_object_id
								left outer join media_relations on filtered_flat.collecting_event_id = media_relations.related_primary_key
								where
								media_relationship like 'shows collecting_event' and underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getNamedGroup.underscore_collection_id#">
							</cfquery>
								#getCollEventMedia.media_id#
								<cfquery name="mediaCollEvent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select distinct
									media.media_id,
									media.media_uri,
									media.mime_type,
									media.media_type,
									media.preview_uri,
									media_relations.media_relationship,
									mczbase.get_media_descriptor(media.media_id) as media_descriptor
								from
									media,
									media_relations,
									media_labels
								where
									media.media_id=media_relations.media_id and
									media.media_id=media_labels.media_id (+) and
									media_relations.media_relationship like '%cataloged_item' and
									media_relations.media_id = #getCollEventMedia.media_id#
									AND MCZBASE.is_media_encumbered(media.media_id) < 1
								order by media.media_type
								</cfquery>
									<h3>Journals, Notes, Ledgers</h3>
									<p>Library scans of written material</p>
									<div id="carouselExampleControls3" class="carousel slide" data-keyboard="true">
										<div class="carousel-inner">
											<cfloop query="mediaCollEvent"  STARTROW="1" ENDROW="3">
											<div class="carousel-item active"> <img class="d-block w-100" src="#mediaCollEvent.media_uri#" alt="First slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="#mediaCollEvent.media_uri#" alt="Second slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="#mediaCollEvent.media_uri#" alt="Third slide"> </div>	
											</cfloop>
										</div>
										<a class="carousel-control-prev" href="##carouselExampleControls3" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
									</div>
								</div>
								<div class="col-12 col-md-4 "> 
								<cfquery name="getAgentMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select distinct media_id from (select media_id from media_relations	where media_relationship like 'shows agent' and related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getNamedGroup.underscore_agent_id#"> union select media_id from group_member left join media_relations on group_member.member_agent_id = media_relations.related_primary_key
									where media_relationship like 'shows agent' and group_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_agent_id#">)
								</cfquery>
								<cfquery name="mediaAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select distinct
									media.media_id,
									media.media_uri,
									media.mime_type,
									media.media_type,
									media.preview_uri,
									media_relations.media_relationship,
									mczbase.get_media_descriptor(media.media_id) as media_descriptor
								from
									media,
									media_relations,
									media_labels
								where
									media.media_id=media_relations.media_id and
									media.media_id=media_labels.media_id (+) and
									media_relations.media_relationship like '%cataloged_item' and
									media_relations.media_id = #getAgentMedia.media_id#
									AND MCZBASE.is_media_encumbered(media.media_id) < 1
								order by media.media_type
								</cfquery>
									<h3>Collectors and other agents</h3>
									<p>James Henry Blake, Louis Agassiz, Franz Steindachner, LF dePourtales</p>
									<div id="carouselExampleControls2" class="carousel slide" data-keyboard="true">
										<div class="carousel-inner">
										<cfloop query="mediaAgent" STARTROW="1" ENDROW="3">
										<div class="carousel-item"> <img class="d-block w-100" src="#mediaAgent.media_uri#" alt=""> </div>
										<div class="carousel-item"> <img class="d-block w-100" src="#mediaAgent.media_uri#" alt=""> </div>
										<div class="carousel-item"> <img class="d-block w-100" src="#mediaAgent.media_uri#" alt=""> </div>
										</cfloop>
										</div>
										<a class="carousel-control-prev" href="##carouselExampleControls2" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
									</div>
								</div>
							</div>
						</div>
						<div class="col-12 col-md-6 px-5 mt-4 float-left">
									<div class="col-12">	
									<ul class="list-group py-2 border-top border-bottom border-light">
										<li class="list-group-item float-left" style="width:100px"><a href="##">Aves</a></li>
										<li class="list-group-item float-left" style="width:100px"><a href="##">Amphibia</a></li>
										<li class="list-group-item float-left" style="width:100px"><a href="##">Reptilia</a></li>
										<li class="list-group-item float-left" style="width:100px"><a href="##">Cephalopoda</a></li>
					</ul></div>
						<cfquery name="spec_media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select distinct media_id
							from underscore_relation
							left outer join media_relations on underscore_relation.collection_object_id = media_relations.related_primary_key
							where
							media_relationship like 'shows cataloged_item' and underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
						</cfquery>
								<h3>Featured Specimen Images</h3>
						<p>Specimen Images linked to the Hassler Expedition</p>
							<div id="carouselExampleControls1" class="carousel slide" data-keyboard="true">
								<div class="carousel-inner">
									<div class="carousel-item active"> <img class="d-block w-100" src="/images/carousel_example.png" alt="First slide"> </div>
									<div class="carousel-item"> <img class="d-block w-100" src="/images/specimens_from_MA.png" alt="Second slide"> </div>
									<div class="carousel-item"> <img class="d-block w-100" src="/images/carousel_example.png" alt="Third slide"> </div>
								</div>
								<a class="carousel-control-prev" href="##carouselExampleControls1" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> </div>
					
						</div>
					</div>
				</div>
			</article>
		</div>
	</main>
	<!--- class="container" ---> 
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
