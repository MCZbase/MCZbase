<!---
SpecimenDetailBody.cfm

Copyright 2019 President and Fellows of Harvard College

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

<!---  TODO: Header hasn't been shown, handle approprately, probably with a redirect to SpecimenDetails.cfm --->
<!---<cfif not isdefined("HEADER_DELIVERED")>
</cfif>--->
<cfoutput>
	<cfif not isdefined("collection_object_id") or not isnumeric(collection_object_id)>
		<div class="error"> Improper call. Aborting..... </div>
		<cfabort>
	</cfif>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		<cfset oneOfUs = 1>
		<cfset isClicky = "likeLink">
		<cfelse>
		<cfset oneOfUs = 0>
		<cfset isClicky = "">
	</cfif>
	<cfif oneOfUs is 0 and cgi.CF_TEMPLATE_PATH contains "/specimens/SpecimenDetailBody.cfm">
		<!--- TODO: Fix this redirect, this is probably the header delivered block above.  ----> 
		<!---<cfheader statuscode="301" statustext="Moved permanently">
	<cfheader name="Location" value="/Specimens.cfm?collection_object_id=#collection_object_id#">--->
	</cfif>
</cfoutput> 
<!--- Include the template that contains functions used to load portions of this page --->
<cfinclude template="/specimens/component/public.cfc">

<!--- Lookup the specimen details --->
<cfquery name="one" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT
		cataloged_item.collection_object_id as collection_object_id,
		cataloged_item.cat_num,
		collection.collection_cde,
		cataloged_item.accn_id,
		collection.collection,
		identification.scientific_name,
		identification.identification_remarks,
		identification.identification_id,
		identification.made_date,
		identification.nature_of_id,
		collecting_event.collecting_event_id,
		case when
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
			and concatencumbrances(cataloged_item.collection_object_id) like '%mask year collected%' 
		then
				replace(began_date,substr(began_date,1,4),'8888')
		else
			collecting_event.began_date
		end began_date,
		case when
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
			and concatencumbrances(cataloged_item.collection_object_id) like '%mask year collected%' 
		then
				replace(ended_date,substr(ended_date,1,4),'8888')
		else
			collecting_event.ended_date
		end ended_date,
		case when
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
			and concatencumbrances(cataloged_item.collection_object_id) like '%mask year collected%' 
		then
				'Masked'
		else
			collecting_event.verbatim_date
		end verbatim_date,
		collecting_event.startDayOfYear,
		collecting_event.endDayOfYear,
		collecting_event.habitat_desc,
		case when
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
			and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' 
			and collecting_event.coll_event_remarks is not null
		then 
			'Masked'
		else
			collecting_event.coll_event_remarks
		end COLL_EVENT_REMARKS,
		locality.locality_id,
		locality.minimum_elevation,
		locality.maximum_elevation,
		locality.orig_elev_units,
		case when
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1
			and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' 
			and locality.spec_locality is not null
		then 
			'Masked'
		else
			locality.spec_locality
		end spec_locality,
		case when
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1
			and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%'
			and accepted_lat_long.orig_lat_long_units is not null
		then 
			'Masked'
		else
			decode(accepted_lat_long.orig_lat_long_units,
				'decimal degrees',to_char(accepted_lat_long.dec_lat) || '&deg; ',
				'deg. min. sec.', to_char(accepted_lat_long.lat_deg) || '&deg; ' ||
					to_char(accepted_lat_long.lat_min) || '&acute; ' ||
					decode(accepted_lat_long.lat_sec, null,  '', to_char(accepted_lat_long.lat_sec) || '&acute;&acute; ') || accepted_lat_long.lat_dir,
				'degrees dec. minutes', to_char(accepted_lat_long.lat_deg) || '&deg; ' ||
					to_char(accepted_lat_long.dec_lat_min) || '&acute; ' || accepted_lat_long.lat_dir
			)
		end VerbatimLatitude,
		case when
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
			and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' 
			and accepted_lat_long.orig_lat_long_units is not null
		then 
			'Masked'
		else
			decode(accepted_lat_long.orig_lat_long_units,
				'decimal degrees',to_char(accepted_lat_long.dec_long) || '&deg;',
				'deg. min. sec.', to_char(accepted_lat_long.long_deg) || '&deg; ' ||
					to_char(accepted_lat_long.long_min) || '&acute; ' ||
					decode(accepted_lat_long.long_sec, null, '', to_char(accepted_lat_long.long_sec) || '&acute;&acute; ') || accepted_lat_long.long_dir,
				'degrees dec. minutes', to_char(accepted_lat_long.long_deg) || '&deg; ' ||
					to_char(accepted_lat_long.dec_long_min) || '&acute; ' || accepted_lat_long.long_dir
			)
		end VerbatimLongitude,
		locality.sovereign_nation,
		collecting_event.verbatimcoordinates,
		collecting_event.verbatimlatitude verblat,
		collecting_event.verbatimlongitude verblong,
		collecting_event.verbatimcoordinatesystem,
		collecting_event.verbatimSRS,
		accepted_lat_long.dec_lat,
		accepted_lat_long.dec_long,
		accepted_lat_long.max_error_distance,
		accepted_lat_long.max_error_units,
		accepted_lat_long.determined_date latLongDeterminedDate,
		accepted_lat_long.lat_long_ref_source,
		accepted_lat_long.lat_long_remarks,
		accepted_lat_long.datum,
		latLongAgnt.agent_name latLongDeterminer,
		geog_auth_rec.geog_auth_rec_id,
		geog_auth_rec.continent_ocean,
		geog_auth_rec.country,
		geog_auth_rec.state_prov,
		geog_auth_rec.quad,
		geog_auth_rec.county,
		geog_auth_rec.island,
		geog_auth_rec.island_group,
		geog_auth_rec.sea,
		geog_auth_rec.feature,
		coll_object.coll_object_entered_date,
		coll_object.last_edit_date,
		coll_object.flags,
		coll_object_remark.coll_object_remarks,
		coll_object_remark.disposition_remarks,
		coll_object_remark.associated_species,
		coll_object_remark.habitat,
		enteredPerson.agent_name EnteredBy,
		editedPerson.agent_name EditedBy,
		accn_number accession,
		concatencumbrances(cataloged_item.collection_object_id) concatenatedEncumbrances,
		concatEncumbranceDetails(cataloged_item.collection_object_id) encumbranceDetail,
		case when
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
			and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%'
			and locality.locality_remarks is not null
		then 
			'Masked'
		else
				locality.locality_remarks
		end locality_remarks,
		case when
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1
			and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' 
			and verbatim_locality is not null
		then 
			'Masked'
		else
			verbatim_locality
		end verbatim_locality,
		collecting_time,
		fish_field_number,
		min_depth,
		max_depth,
		depth_units,
		collecting_method,
		collecting_source,
		decode(trans.transaction_id, null, 0, 1) vpdaccn
	FROM
		cataloged_item,
		collection,
		identification,
		collecting_event,
		locality,
		accepted_lat_long,
		preferred_agent_name latLongAgnt,
		geog_auth_rec,
		coll_object,
		coll_object_remark,
		preferred_agent_name enteredPerson,
		preferred_agent_name editedPerson,
		accn,
		trans
	WHERE
		cataloged_item.collection_id = collection.collection_id AND
		cataloged_item.collection_object_id = identification.collection_object_id AND
		identification.accepted_id_fg = 1 AND
		cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
		collecting_event.locality_id = locality.locality_id  AND
		locality.locality_id = accepted_lat_long.locality_id (+) AND
		accepted_lat_long.determined_by_agent_id = latLongAgnt.agent_id (+) AND
		locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id AND
		cataloged_item.collection_object_id = coll_object.collection_object_id AND
		coll_object.collection_object_id = coll_object_remark.collection_object_id (+) AND
		coll_object.entered_person_id = enteredPerson.agent_id AND
		coll_object.last_edited_person_id = editedPerson.agent_id (+) AND
		cataloged_item.accn_id =  accn.transaction_id  AND
		accn.transaction_id = trans.transaction_id(+) AND
		cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
</cfquery>
<cfif one.concatenatedEncumbrances contains "mask record" and oneOfUs neq 1>
	Record masked. 
	<!---- the correct the correct HTTP response is 403, forbiden ---->
	<cfheader statuscode="403" statustext="Forbidden: user does not have necessary permissions to access this resource">
	<cfabort>
</cfif>
<section class="container-fluid">
	<div class="form-row">
		<cfquery name="colls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				collector.coll_order,
				case when
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 and concatencumbrances(collector.collection_object_id) like '%mask collector%' then 'Anonymous'
				else
					preferred_agent_name.agent_name
				end collectors
			FROM
				collector,
				preferred_agent_name
			WHERE
				collector.collector_role='c' and
				collector.agent_id=preferred_agent_name.agent_id and
				collector.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			ORDER BY
				coll_order
		</cfquery>
		<cfquery name="preps" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				collector.coll_order,
				case when
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 and concatencumbrances(collector.collection_object_id) like '%mask preparator%' then 'Anonymous'
				else
					preferred_agent_name.agent_name
				end preparators
			FROM
				collector,
				preferred_agent_name
			WHERE
				collector.collector_role='p' and
				collector.agent_id=preferred_agent_name.agent_id and
				collector.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			ORDER BY
				coll_order
		</cfquery>
		<cfquery name="attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				attributes.attribute_type,
				attributes.attribute_value,
				attributes.attribute_units,
				attributes.attribute_remark,
				attributes.determination_method,
				attributes.determined_date,
				attribute_determiner.agent_name attributeDeterminer
			FROM
				attributes,
				preferred_agent_name attribute_determiner
			WHERE
				attributes.determined_by_agent_id = attribute_determiner.agent_id and
				attributes.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
		</cfquery>
		<cfquery name="relns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT 
				distinct biol_indiv_relationship, related_collection, related_coll_object_id, related_cat_num, biol_indiv_relation_remarks FROM (
			SELECT
				 rel.biol_indiv_relationship as biol_indiv_relationship,
				 collection as related_collection,
				 rel.related_coll_object_id as related_coll_object_id,
				 rcat.cat_num as related_cat_num,
				rel.biol_indiv_relation_remarks as biol_indiv_relation_remarks
			FROM
				 biol_indiv_relations rel
				 left join cataloged_item rcat
					 on rel.related_coll_object_id = rcat.collection_object_id
				 left join collection
					 on collection.collection_id = rcat.collection_id
				 left join ctbiol_relations ctrel
				  on rel.biol_indiv_relationship = ctrel.biol_indiv_relationship
			WHERE rel.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> 
				  and ctrel.rel_type <> 'functional'
			UNION
			SELECT
				 ctrel.inverse_relation as biol_indiv_relationship,
				 collection as related_collection,
				 irel.collection_object_id as related_coll_object_id,
				 rcat.cat_num as related_cat_num,
				irel.biol_indiv_relation_remarks as biol_indiv_relation_remarks
			FROM
				 biol_indiv_relations irel
				 left join ctbiol_relations ctrel
				  on irel.biol_indiv_relationship = ctrel.biol_indiv_relationship
				 left join cataloged_item rcat
				  on irel.collection_object_id = rcat.collection_object_id
				 left join collection
				 on collection.collection_id = rcat.collection_id
			WHERE irel.related_coll_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				 and ctrel.rel_type <> 'functional'
			)
		</cfquery>
		<cfquery name="citations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				citation.type_status,
				citation.occurs_page_number,
				citation.citation_page_uri,
				citation.CITATION_REMARKS,
				cited_taxa.scientific_name as cited_name,
				cited_taxa.taxon_name_id as cited_name_id,
				formatted_publication.formatted_publication,
				formatted_publication.publication_id,
				cited_taxa.taxon_status as cited_name_status
			FROM
				citation,
				taxonomy cited_taxa,
				formatted_publication
			WHERE
				citation.cited_taxon_name_id = cited_taxa.taxon_name_id  AND
				citation.publication_id = formatted_publication.publication_id AND
				format_style='short' and
				citation.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			ORDER BY
				substr(formatted_publication, - 4)
		</cfquery>
		<cfquery name="publicationMedia"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						mr.media_id, m.media_uri, m.preview_uri, ml.label_value descr, m.media_type, m.mime_type
					FROM
						media_relations mr, media_labels ml, media m, citation c, formatted_publication fp
					WHERE
						mr.media_id = ml.media_id and
						mr.media_id = m.media_id and
						ml.media_label = 'description' and
						MEDIA_RELATIONSHIP like '% publication' and
						RELATED_PRIMARY_KEY = c.publication_id and
						c.publication_id = fp.publication_id and
						fp.format_style='short' and
						c.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
					ORDER by substr(formatted_publication, -4)
				</cfquery>
		<cfoutput query="one">
			<cfset guid = "MCZ:#one.collection_cde#:#one.cat_num#">
			<cfquery name="mediaS2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select distinct
					media.media_id,
					media.media_uri,
					media.mime_type,
					media.media_type,
					media.preview_uri,
					media_relations.media_relationship
				 from
					 media,
					 media_relations,
					 media_labels
				 where
					 media.media_id=media_relations.media_id and
					 media.media_id=media_labels.media_id (+) and
					 media_relations.media_relationship like '%cataloged_item' and
					 media_relations.related_primary_key = <cfqueryparam value=#collection_object_id# CFSQLType="CF_SQL_DECIMAL" >
					 AND MCZBASE.is_media_encumbered(media.media_id) < 1
				order by media.media_type
			</cfquery>
			<cfquery name="ctmedia" dbtype="query">
                select count(*) as ct from mediaS2 group by media_relationship order by media_id
            </cfquery>
			<cfquery name="rparts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select
									specimen_part.collection_object_id part_id,
									Case
										when #oneOfus#= 1
										then pc.label
										else null
									End label,
									nvl2(preserve_method, part_name || ' (' || preserve_method || ')',part_name) part_name,
									sampled_from_obj_id,
									coll_object.COLL_OBJ_DISPOSITION part_disposition,
									coll_object.CONDITION part_condition,
									nvl2(lot_count_modifier, lot_count_modifier || lot_count, lot_count) lot_count,
									coll_object_remarks part_remarks,
									attribute_type,
									attribute_value,
									attribute_units,
									determined_date,
									attribute_remark,
									agent_name
								from
									specimen_part,
									coll_object,
									coll_object_remark,
									coll_obj_cont_hist,
									container oc,
									container pc,
									specimen_part_attribute,
									preferred_agent_name
								where
									specimen_part.collection_object_id=specimen_part_attribute.collection_object_id (+) and
									specimen_part_attribute.determined_by_agent_id=preferred_agent_name.agent_id (+) and
									specimen_part.collection_object_id=coll_object.collection_object_id and
									coll_object.collection_object_id=coll_obj_cont_hist.collection_object_id and
									coll_object.collection_object_id=coll_object_remark.collection_object_id (+) and
									coll_obj_cont_hist.container_id=oc.container_id and
									oc.parent_container_id=pc.container_id (+) and
									specimen_part.derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#one.collection_object_id#">
							</cfquery>
			<cfquery name="parts" dbtype="query">
					select  
							part_id,
							label,
							part_name,
							sampled_from_obj_id,
							part_disposition,
							part_condition,
							lot_count,
							part_remarks
					from
							rparts
					group by
							part_id,
							label,
							part_name,
							sampled_from_obj_id,
							part_disposition,
							part_condition,
							lot_count,
							part_remarks
					order by
							part_name
			</cfquery>
			<cfquery name="mPart" dbtype="query">
				select * from parts where sampled_from_obj_id is null order by part_name
			</cfquery>
			<cfset ctPart.ct=''>
			<cfquery name="ctPart" dbtype="query">
				select count(*) as ct from parts group by lot_count order by part_name
			</cfquery>
		<cfif mediaS2.recordcount gt 1>
			<div class="col-12 col-sm-12 col-md-3 col-lg-3 col-xl-2 px-1 mb-2 float-left">
				<div class="accordion" id="accordionMedia">
					<div class="card bg-light">
						<div class="card-header mb-2" id="headingMedia">
							<h3 class="h4 my-0 float-left collapsed MediaAccordionShow btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##collapseMedia">Media</a>
							</h3>
							<h3 class="h4 my-0 float-left MediaAccordionHide">Media
								<span class="text-success small ml-4">(count: #ctmedia.ct# media records)</span>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs py-0 small float-right" onclick="$('.dialog').dialog('open'); loadMedia();">Edit</button>
							</cfif>
						</div>
						<div id="collapseMedia" class="collapse show" aria-labelledby="headingMedia" data-parent="##accordionMedia">
							<div class="card-body">
							<!------------------------------------ media ----------------------------------------------> 
							<!---START Code from MEDIA SET code---> 
								<a href="/media/#mediaS2.media_id#" class="btn-link">Media Record</a>
								<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
									media_relations.related_primary_key = <cfqueryparam value=#collection_object_id# CFSQLType="CF_SQL_DECIMAL" >
								AND 
									MCZBASE.is_media_encumbered(media.media_id) < 1
								order by media.media_type
							</cfquery>
								<cfif media.recordcount gt 0>
								<div class="mt-2">
												<cfquery name="wrlCount" dbtype="query">
													select * from media where mime_type = 'model/vrml'
												</cfquery>
												<cfif wrlCount.recordcount gt 0>
													<span class="innerDetailLabel">Note: CT scans with mime type "model/vrml" require an external plugin such as <a href="http://cic.nist.gov/vrml/cosmoplayer.html">Cosmo3d</a> or <a href="http://mediamachines.wordpress.com/flux-player-and-flux-studio/">Flux Player</a>. For Mac users, a standalone player such as <a href="http://meshlab.sourceforge.net/">MeshLab</a> will be required.</span>
												</cfif>
												<cfquery name="pdfCount" dbtype="query">
													select * from media where mime_type = 'application/pdf'
												</cfquery>
												<cfif pdfCount.recordcount gt 0>
													<span class="small">For best results, open PDF files in the most recent version of Adobe Reader.</span>
												</cfif>
												<cfif oneOfUs is 1>
													<cfquery name="hasConfirmedImageAttr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
														SELECT 
															count(*) c
														FROM
															ctattribute_type
														WHERE 
															attribute_type='image confirmed' and
															collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#one.collection_cde#">
													</cfquery>
													<!---	<span class="detailEditCell" onclick="window.parent.loadEditApp('MediaSearch');">Edit</span>--->
													<cfquery name="isConf"  dbtype="query">
														SELECT 
															count(*) c
														FROM
															attribute
														WHERE 
															attribute_type='image confirmed'
													 </cfquery>
													<CFIF isConf.c is "" and hasConfirmedImageAttr.c gt 0>
														<span class="infoLink" id="ala_image_confirm" onclick='windowOpener("/ALA_Imaging/confirmImage.cfm?collection_object_id=#collection_object_id#","alaWin","width=700,height=400, resizable,scrollbars,location,toolbar");'> Confirm Image IDs </span>
													</CFIF>
												</cfif>
											</div>
								<div>
									<span class="form-row col-12 px-0 mx-0"> 
										<!---div class="feature image using media_uri"--->
										<!--- to-do: Create checkbox for featured media on create media page--->
										<cfif #mediaS2.media_uri# contains "specimen_images">
												<cfset aForThisHref = "/MediaSet.cfm?media_id=#mediaS2.media_id#" >
												<a href="#aForThisHref#" target="_blank" class="w-100">
												<img src="#mediaS2.media_uri#" class="w-100 mb-2">
												</a>
											<cfelse>

											</cfif>
										<cfloop query="media">
											<!---div class="thumbs"--->
											<cfset mt=media.mime_type>
											<cfset altText = media.media_descriptor>
											<cfset puri=getMediaPreview(preview_uri,mime_type)>
											<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												SELECT
													media_label,
													label_value
												FROM
													media_labels
												WHERE
													media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
											</cfquery>
											<cfquery name="desc" dbtype="query">
												select label_value from labels where media_label='description'
											</cfquery>
											<cfset description="Media Preview Image">
											<cfif desc.recordcount is 1>
												<cfset description=desc.label_value>
											</cfif>
											<cfif media_type eq "image" and media.media_relationship eq "shows cataloged_item" and mime_type NEQ "text/html">
												<!---for media images -- remove absolute url after demo / test db issue?--->
												<cfset one_thumb = "<div class='imgsize'>">
												<cfset aForImHref = "/MediaSet.cfm?media_id=#media_id#" >
												<cfset aForDetHref = "/MediaSet.cfm?media_id=#media_id#" >
												<cfelse>
												<!---for DRS from library--->
												<cfset one_thumb = "<div class='imgsize'>">
												<cfset aForImHref = media_uri>
												<cfset aForDetHref = "/media/#media_id#">
											</cfif>
											#one_thumb# <a href="#aForImHref#" target="_blank"> 
											<img src="#getMediaPreview(preview_uri,mime_type)#" alt="#altText#" class="" width="98%"> </a>
											<p class="smaller">
												<a href="#aForDetHref#" target="_blank">Media Details</a> <br>
												<span class="">#description#</span>
											</p>
											</div>
										</cfloop>
										<!--/div---> 
									</span>
								</div>
								<cfquery name="barcode"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select p.barcode from
									container c,
									container p,
									coll_obj_cont_hist,
									specimen_part,
									cataloged_item
									where
									cataloged_item.collection_object_id=specimen_part.derived_from_cat_item and
									specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id and
									coll_obj_cont_hist.container_id=c.container_id and
									c.parent_container_id=p.container_id and
									cataloged_item.collection_object_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
								</cfquery>
								</div>
							</cfif>
							</div>
						</div>
					</div>
				</div>
			</div>
		</cfif>
<!----------------------------- two right columns ---------------------------------->
		<div class="col-12 col-sm-12 px-0 <cfif mediaS2.recordcount gt 1>col-md-9 col-lg-9 col-xl-10<cfelse>col-md-12 col-lg-12 col-xl-12</cfif> float-left">
			<div class="col-12 col-md-6 px-1 float-left"> 

<!----------------------------- identifications ----------------------------------> 
				<div class="accordion" id="accordionB">
					<div class="card mb-2 bg-light">
						<div id="identificationsDialog"></div>
						<script>
							function reloadIdentifications() { 
								// invoke specimen/component/public.cfc function getIdentificationHTML via ajax and repopulate the identification block.
								loadIdentifications(#collection_object_id#,'identificationsCardBody');
							}
						</script>
						<div class="card-header" id="heading1">
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##identificationsPane">Identifications</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditIdentificationsDialog(#collection_object_id#,'identificationsDialog','#guid#',reloadIdentifications)">Edit</button>
							</cfif>
						</div>
						<div id="identificationsPane" class="collapse show" aria-labelledby="heading1" data-parent="##accordionB">
							<div class="card-body mb-2 float-left" id="identificationsCardBody">
								<cfset block = getIdentificationsHTML(collection_object_id = "#collection_object_id#")>
								#block#
							</div>
						</div>
					</div>
				</div>

<!----------------------------- Citatons new ----------------------------------> 
		
				<div class="accordion" id="accordionCitations">
					<div class="card mb-2 bg-light">
						<div id="citationsDialog"></div>
						<script>
							function reloadCitations() { 
								// invoke specimen/component/public.cfc function getIdentificationHTML via ajax and repopulate the identification block.
								loadCitations(#collection_object_id#,'citationsCardBody');
							}
						</script>
						<div class="card-header" id="headingCitations">
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##citationsPane">Citations</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditCitationsDialog(#collection_object_id#,'citationsDialog','#guid#',reloadCitations)">Edit</button>
							</cfif>
						</div>
						<div id="citationsPane" class="collapse show" aria-labelledby="headingCitations" data-parent="##accordionCitations">
							<div class="card-body mb-2 float-left" id="citationsCardBody">
								<cfset block = getCitationsHTML(collection_object_id = "#collection_object_id#")>
								#block#
							</div>
						</div>
					</div>
				</div>
<!------------------------------------ other identifiers ---------------------------------->
				<div class="accordion" id="accordionOtherID">
					<div class="card mb-2 bg-light">
						<div id="otherIDsDialog"></div>
						<script>
							function reloadOtherIDs() { 
								// invoke specimen/component/public.cfc function getOtherIDsHTML via ajax and repopulate the Other ID block.
								loadOtherIDs(#collection_object_id#,'otherIDsCardBody');
							}
						</script>
						<div class="card-header" id="headingOtherID">
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##OtherIDsPane">OtherIDs</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog','#guid#',reloadOtherIDs)">Edit</button>
							</cfif>
						</div>
						<div id="OtherIDsPane" class="collapse show" aria-labelledby="headingOtherID" data-parent="##accordionOtherID">
							<div class="card-body mb-2 float-left" id="otherIDsCardBody">
								<cfset block = getOtherIDsHTML(collection_object_id = "#collection_object_id#")>
								#block#
							</div>
						</div>
					</div>
				</div>

<!------------------------------------ parts new ---------------------------------->
 
				<div class="accordion" id="accordionParts">
					<div class="card mb-2 bg-light">
						<div id="partsDialog"></div>
						<script>
							function reloadParts() { 
								// invoke specimen/component/public.cfc function getOtherIDsHTML via ajax and repopulate the Other ID block.
								loadParts(#collection_object_id#,'partsCardBody');
							}
						</script>
						<div class="card-header" id="headingParts">
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##PartsPane">Parts</a>
                                <span class="text-success small ml-4">(count: #ctPart.ct# parts)</span>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditPartsDialog(#collection_object_id#,'partsDialog','#guid#',reloadParts)">Edit</button>
							</cfif>
						</div>
                        <div id="PartsPane" <cfif #ctPart.ct# gt 5>style="height:300px;"</cfif> class="collapse show" aria-labelledby="headingParts" data-parent="##accordionParts">
							<div class="card-body w-100 mb-2 float-left" id="partsCardBody">
								<cfset block = getPartsHTML(collection_object_id = "#collection_object_id#")>
								#block#
							</div>
						</div>
					</div>
				</div>
						
<!------------------------------------ attributes ----------------------------------------->
				<div class="accordion" id="accordionAttributes">
					<div class="card mb-2 bg-light">
						<div id="AttributesDialog"></div>
						<script>
							function reloadAttributes() { 
								// invoke specimen/component/public.cfc function getAttributesHTML via ajax and repopulate the Other ID block.
								loadAttributes(#collection_object_id#,'attributesCardBody');
							}
						</script>
						<div class="card-header" id="headingAttributes">
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##AttributesPane">Attributes</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditAttributesDialog(#collection_object_id#,'attributesDialog','#guid#',reloadAttributes)">Edit</button>
							</cfif>
						</div>
						<div id="AttributesPane" class="collapse show" aria-labelledby="headingAttributes" data-parent="##accordionAttributes">
							<div class="card-body mb-2 float-left" id="attributesCardBody">
								<cfset block = getAttributesHTML(collection_object_id = "#collection_object_id#")>
								#block#
							</div>
						</div>
					</div>
				</div>
				
<!------------------------------------ relationships  ------------------------------------->

				<div class="accordion" id="accordionRelations">
					<div class="card mb-2 bg-light">
						<div id="RelationsDialog"></div>
						<script>
							function reloadRelations() { 
								// invoke specimen/component/public.cfc function getRelationsHTML via ajax and repopulate the Other ID block.
								loadRelations(#collection_object_id#,'RelationsCardBody');
							}
						</script>
						<div class="card-header" id="headingRelations">
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##RelationsPane">Relationships</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditRelationsDialog(#collection_object_id#,'relationsDialog','#guid#',reloadRelations)">Edit</button>
							</cfif>
						</div>
						<div id="RelationsPane" class="collapse show" aria-labelledby="headingRelations" data-parent="##accordionRelations">
							<div class="card-body mb-2 float-left" id="relationsCardBody">
								<cfset block = getRelationsHTML(collection_object_id = "#collection_object_id#")>
								#block#
							</div>
						</div>
					</div>
				</div>
</div>
<!---  start of column three  --->
<div class="col-12 col-md-6 px-1 float-left"> 

				<!--- --------------------------------- locality and collecting event-------------------------------------- ---->
<!---            <div class="accordion" id="accordionLocality">
					<div class="card mb-2 bg-light">
						<div id="LocalityDialog"></div>
						<script>
							function reloadLocality() { 
					
								loadLocality(#collecting_event_id#,'localityCardBody');
							}
						</script>
						<div class="card-header" id="headingLocality">
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##LocalityPane">Location and Collecting Event</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs small py-0 float-right" onClick="openEditLocalityDialog(#collecting_event_id#,'localityDialog','#guid#',reloadLocality)">Edit</button>
							</cfif>
						</div>
						<div id="LocalityPane" class="collapse show" aria-labelledby="headingLocality" data-parent="##accordionLocality">
							<div class="card-body mb-2 float-left" id="localityCardBody">
								<cfset block = getLocalityHTML(collecting_event_id = "#collecting_event_id#")>
								#block#
							</div>
						</div>
					</div>
				</div> --->
				
				<!--- --------------------------------- Collectors and Preparators ----------------------------- --->
				<div class="accordion" id="accordionH">
					<div class="card mb-2 bg-light">
						<div class="card-header" id="heading7">
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##collapseCol">Collectors and Preparators</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs py-0 float-right small" onClick="$('##dialog-form').dialog('open'); setupNewLocality(#locality_id#);">Edit</button>
							</cfif>
						</div>
						<div id="collapseCol" class="collapse show" aria-labelledby="heading7" data-parent="##accordionH">
							<div class="card-body mb-1 float-left">
							<ul class="list-unstyled list-group form-row p-1 mb-0">
								<cfif colls.recordcount gt 0>
									<li class="list-group-item"><h5 class="my-0">Collector(s):&nbsp;</h5>
										<cfloop query="colls">
											#colls.collectors#<span>,</span>
										</cfloop>
									</li>
								</cfif>
								<cfif preps.recordcount gt 0>
									<li class="list-group-item"><h5 class="my-0">Preparator(s):&nbsp;</h5>
										<cfloop query="preps">
											#preps.preparators#<span>,</span>
										</cfloop>
									</li>
								</cfif>
							</ul>
						</div>
						</div>
					</div>
				</div>
				<!--- ---------------------------------- tranactions  ----------------------------------- --->
				<cfquery name="accnMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" >
					SELECT 
						media.media_id,
						media.media_uri,
						media.mime_type,
						media.media_type,
						media.preview_uri,
						label_value descr 
					FROM 
						media,
						media_relations,
						(select media_id,label_value from media_labels where media_label='description') media_labels 
					WHERE 
						media.media_id=media_relations.media_id and
						media.media_id=media_labels.media_id (+) and
						media_relations.media_relationship like '% accn' and
						media_relations.related_primary_key = <cfqueryparam value="#one.accn_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfquery>
				<cfif oneOfUs is 1 and vpdaccn is 1>
				<div class="accordion" id="accordionI">
					<div class="card mb-2 bg-light">
						<div class="card-header mb-0" id="heading8">
							<h3 class="h4 my-0 float-left collapsed btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##collapseTR">Transactions</a>
							</h3>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<button type="button" class="btn btn-xs py-0 float-right small" onClick="$('##dialog-form').dialog('open'); setupNewLocality(#locality_id#);">Edit</button>
							</cfif>
						</div>
						<div id="collapseTR" class="collapse show" aria-labelledby="heading8" data-parent="##accordionI">
							<div class="card-body mb-2 float-left">
							<ul class="list-group list-group-flush pl-0">
								<li class="list-group-item"><h5 class="mb-0 d-inline-block">Accession:</h5>
									<cfif oneOfUs is 1>
										<a href="/transactions/Accession.cfm?action=edit&transaction_id=#one.accn_id#" target="_blank">#accession#</a>
										<cfelse>
										#accession#
									</cfif>
									<cfif accnMedia.recordcount gt 0>
										<cfloop query="accnMedia">
											<div class="m-2 d-inline"> 
												<cfset mt = #media_type#>
												<a href="/media/#media_id#" target="_blank">
													<img src="#getMediaPreview('preview_uri','media_type')#" class="d-block border rounded" width="100" alt="#descr#">Media Details
												</a>
												<span class="small d-block">#media_type# (#mime_type#)</span>
												<span class="small d-block">#descr#</span> 
											</div>
										</cfloop>
									</cfif>
								</li>
								
								<!--------------------  Project / Usage ------------------------------------>
								
								<cfquery name="isProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										project_name, project.project_id project_id 
									FROM
										project left join project_trans on project.project_id = project_trans.project_id
									WHERE
										project_trans.transaction_id = <cfqueryparam value="#one.accn_id#" cfsqltype="CF_SQL_DECIMAL">
									GROUP BY project_name, project.project_id
								</cfquery>
								<cfquery name="isLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										project_name, project.project_id 
									FROM 
										loan_item,
										project,
										project_trans,
										specimen_part 
									WHERE 
										specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> AND
										loan_item.transaction_id=project_trans.transaction_id AND
										project_trans.project_id=project.project_id AND
										specimen_part.collection_object_id = loan_item.collection_object_id 
									GROUP BY 
										project_name, project.project_id
								</cfquery>
								<cfquery name="isLoanedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										loan_item.collection_object_id 
									FROM 
										loan_item,specimen_part 
									WHERE 
										loan_item.collection_object_id=specimen_part.collection_object_id AND
										specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								</cfquery>
								<cfquery name="loanList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										distinct loan_number, loan_type, loan_status, loan.transaction_id 
									FROM
										specimen_part left join loan_item on specimen_part.collection_object_id=loan_item.collection_object_id
										left join loan on loan_item.transaction_id = loan.transaction_id
									WHERE
										loan_number is not null AND
										specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								</cfquery>
								<cfquery name="isDeaccessionedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										deacc_item.collection_object_id 
									FROM
										specimen_part left join deacc_item on specimen_part.collection_object_id=deacc_item.collection_object_id
									WHERE
										specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								</cfquery>
								<cfquery name="deaccessionList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										distinct deacc_number, deacc_type, deaccession.transaction_id 
									FROM
										specimen_part left join deacc_item on specimen_part.collection_object_id=deacc_item.collection_object_id
										left join deaccession on deacc_item.transaction_id = deaccession.transaction_id
									where
										deacc_number is not null AND
										specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								</cfquery>
								<cfif isProj.recordcount gt 0 OR isLoan.recordcount gt 0 or (oneOfUs is 1 and isLoanedItem.collection_object_id gt 0) or (oneOfUs is 1 and isDeaccessionedItem.collection_object_id gt 0)>
									<cfloop query="isProj">
										<li class="list-group-item"><h5 class="mb-0 d-inline-block">Contributed By Project:</h5>
											<a href="/ProjectDetail.cfm?src=proj&project_id=#isProj.project_id#">#isProj.project_name#</a> </li>
									</cfloop>
									<cfloop query="isLoan">
										<li class="list-group-item"><h5 class="mb-0 d-inline-block">Used By Project:</h5> 
											<a href="/ProjectDetail.cfm?src=proj&project_id=#isLoan.project_id#" target="_mainFrame">#isLoan.project_name#</a> </li>
									</cfloop>
									<cfif isLoanedItem.collection_object_id gt 0 and oneOfUs is 1>
										<li class="list-group-item">
											<h5 class="mb-0 d-inline-block">Loan History:</h5>
											<a class="d-inline-block" href="/Loan.cfm?action=listLoans&collection_object_id=#valuelist(isLoanedItem.collection_object_id)#"
							target="_mainFrame">Loans that include this cataloged item (#loanList.recordcount#).</a>
											<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
												<cfloop query="loanList">
													<ul class="d-block">
														<li class="d-block">#loanList.loan_number# (#loanList.loan_type# #loanList.loan_status#)</li>
													</ul>
												</cfloop>
											</cfif>
										</li>
									</cfif>
									<cfif isDeaccessionedItem.collection_object_id gt 0 and oneOfUs is 1>
										<li class="list-group-item">
											<h5 class="mb-1 d-inline-block">Deaccessions: </h5>
											<a href="/Deaccession.cfm?action=listDeacc&collection_object_id=#valuelist(isDeaccessionedItem.collection_object_id)#"
							target="_mainFrame">Deaccessions that include this cataloged item (#deaccessionList.recordcount#).</a> &nbsp;
											<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
												<cfloop query="deaccessionList">
													<ul class="d-block">
														<li class="d-block"> <a href="/Deaccession.cfm?action=editDeacc&transaction_id=#deaccessionList.transaction_id#">#deaccessionList.deacc_number# (#deaccessionList.deacc_type#)</a></li>
													</ul>
												</cfloop>
											</cfif>
										</li>
									</cfif>
								</cfif>
							</ul>
						</div>
						</div>
					</div>
				</div>
				</cfif>
				<!--- --------------------------------- metadata -------------------------------------- ---->
				<cfif oneofus is 1 or not Findnocase("mask parts", one.encumbranceDetail)>
					<cfif oneOfUs is 1>
						<div class="card mb-2">
							<div class="card-header float-left w-100">
								<h3 class="h4 my-0 float-left">
								Metadata
								</h4>
							</div>
							<div class="card-body mb-2 float-left">
								<ul class="list-group pl-0 pt-1">
									<cfif len(#one.coll_object_remarks#) gt 0>
										<li class="list-group-item">Remarks: #one.coll_object_remarks# </li>
									</cfif>
									<li class="list-group-item"> Entered By: #one.EnteredBy# on #dateformat(one.coll_object_entered_date,"yyyy-mm-dd")# </li>
									<cfif #one.EditedBy# is not "unknown" OR len(#one.last_edit_date#) is not 0>
										<li class="list-group-item"> Last Edited By: #one.EditedBy# on #dateformat(one.last_edit_date,"yyyy-mm-dd")# </li>
									</cfif>
									<cfif len(#one.flags#) is not 0>
										<li class="list-group-item"> Missing (flags): #one.flags# </li>
									</cfif>
									<cfif len(#one.encumbranceDetail#) is not 0>
										<li class="list-group-item"> Encumbrances: #replace(one.encumbranceDetail,";","<br>","all")# </li>
									</cfif>
								</ul>
							</div>
						</div>
					</cfif>
				</cfif>
			</div>
			<!--- end of column 3 --->
			
			<cfif oneOfUs is 1>
				</form>
			</cfif>
		</div>
	</div>
	</cfoutput>
	</div>
</section>
