<cfset pageTitle = "Named Group">
<cfinclude template="/shared/_header.cfm">
<cfset collection_object_id = "5243961">
<cfoutput>
<main class="container py-3">
<cfset oneofus = "1">
<cfquery name="namedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select underscore_collection.collection_name, underscore_relation.collection_object_id
from underscore_collection, underscore_relation 
where underscore_relation.UNDERSCORE_collection_ID = underscore_collection.UNDERSCORE_COLLECTION_ID
and underscore_relation.collection_object_id = 5243961
</cfquery>
	
	<div class="row">
	 	<div class="col-12">
			<h1>#namedGroup.collection_name#</h1>
<!--- TODO: Remove all creation of SQL statements as variables, replace all instances with cfquery statements using cfqueryparam parameters. --->
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
			from
				citation,
				taxonomy cited_taxa,
				formatted_publication
			where
				citation.cited_taxon_name_id = cited_taxa.taxon_name_id  AND
				citation.publication_id = formatted_publication.publication_id AND
				format_style='short' and
				citation.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			order by
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

		<cfif oneOfUs is 1>
			<form name="editStuffLinks" method="post" action="/specimens/SpecimenDetail.cfm">
			<input type="hidden" name="collection_object_id" value="#one.collection_object_id#">
			<input type="hidden" name="suppressHeader" value="true">
			<input type="hidden" name="action" value="nothing">
			<input type="hidden" name="Srch" value="Part">
			<input type="hidden" name="collecting_event_id" value="#one.collecting_event_id#">
		</cfif>
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
		<cfif mediaS2.recordcount gt 1>
			<div class="col-12 col-sm-12 col-md-3 col-lg-3 col-xl-2 px-1 mb-2 float-left">
				<div class="accordion" id="accordionE">
					<div class="card bg-light">
						<div class="card-header mb-2" id="headingTwo">
							<h3 class="h4 my-0 float-left collapsed MediaAccordionShow btn-link">
								<a href="##" role="button" data-toggle="collapse" data-target="##collapseIt">Media</a>
							</h3>
							<h3 class="h4 my-0 float-left MediaAccordionHide">Media</h3>
							<button type="button" class="btn btn-xs small float-right" onclick="$('.dialog').dialog('open'); loadMedia();">Edit</button>
						</div>
						<div id="collapseIt" class="collapse show" aria-labelledby="headingTwo" data-parent="##accordionE">
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
													AND MCZBASE.is_media_encumbered(media.media_id) < 1
										order by media.media_type
							</cfquery>
							<cfif media.recordcount gt 0>
								<div>
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
											<cfquery name="hasConfirmedImageAttr"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
													SELECT count(*) c
													FROM
													  ctattribute_type
													where attribute_type='image confirmed' and
													collection_cde='#one.collection_cde#'
											</cfquery>
											<!---	<span class="detailEditCell" onclick="window.parent.loadEditApp('MediaSearch');">Edit</span>--->
											<cfquery name="isConf"  dbtype="query">
													  SELECT count(*) c
													  FROM
													  attribute
													  where attribute_type='image confirmed'
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
										   select
											  media_label,
											  label_value
										   from
											  media_labels
										   where
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
											<span class="">#description#</span> </p>
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

			<div class="col-7 border float-left">Description</div>
		</div>
	</div>
</main><!--- class="container" --->
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
