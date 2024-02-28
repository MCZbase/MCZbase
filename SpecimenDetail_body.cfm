<cfif not isdefined("toProperCase")>
	<cfinclude template="/includes/_frameHeader.cfm">
</cfif>
<cfoutput>
	<cfif not isdefined("collection_object_id") or not isnumeric(collection_object_id)>
		<div class="error">
			Improper call. Aborting.....
		</div>
		<cfabort>
	</cfif>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		<cfset oneOfUs = 1>
		<cfset isClicky = "likeLink">
	<cfelse>
		<cfset oneOfUs = 0>
		<cfset isClicky = "">
	</cfif>
	<cfif oneOfUs is 0 and cgi.CF_TEMPLATE_PATH contains "/SpecimenDetail_body.cfm">
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfheader name="Location" value="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#">
	</cfif>
</cfoutput>
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
			#oneOfUs# != 1 and concatencumbrances(cataloged_item.collection_object_id) like '%mask year collected%' then
				replace(began_date,substr(began_date,1,4),'8888')
		else
			collecting_event.began_date
		end began_date,
		case when
			#oneOfUs# != 1 and concatencumbrances(cataloged_item.collection_object_id) like '%mask year collected%' then
				replace(ended_date,substr(ended_date,1,4),'8888')
		else
			collecting_event.ended_date
		end ended_date,
		case when
			#oneOfUs# != 1 and concatencumbrances(cataloged_item.collection_object_id) like '%mask year collected%' then
				'Masked'
		else
			collecting_event.verbatim_date
		end verbatim_date,
		collecting_event.startDayOfYear,
		collecting_event.endDayOfYear,
		collecting_event.habitat_desc,
		case when
			#oneOfUs# != 1 and
				(concatencumbrances(cataloged_item.collection_object_id) like '%mask locality%' OR concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%') and
					collecting_event.coll_event_remarks is not null
				then 'Masked'
		else
				collecting_event.coll_event_remarks
		end COLL_EVENT_REMARKS,
		locality.locality_id,
		locality.minimum_elevation,
		locality.maximum_elevation,
		locality.orig_elev_units,
		case when
			#oneOfUs# != 1 and
				(concatencumbrances(cataloged_item.collection_object_id) like '%mask locality%' OR concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%') and
					locality.spec_locality is not null
				then 'Masked'
		else
		locality.spec_locality
		end spec_locality,
		case when
			#oneOfUs# != 1 and
				(concatencumbrances(cataloged_item.collection_object_id) like '%mask locality%' OR concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%') and
					accepted_lat_long.orig_lat_long_units is not null
				then 'Masked'
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
			#oneOfUs# != 1 and
				(concatencumbrances(cataloged_item.collection_object_id) like '%mask locality%' OR concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%') and
					accepted_lat_long.orig_lat_long_units is not null
				then 'Masked'
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
		geog_auth_rec.ocean_region,
		geog_auth_rec.ocean_subregion,
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
			#oneOfUs# != 1 and
				(concatencumbrances(cataloged_item.collection_object_id) like '%mask locality%' OR concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%') and
					locality.locality_remarks is not null
				then 'Masked'
		else
				locality.locality_remarks
		end locality_remarks,
		case when
			#oneOfUs# != 1 and
				(concatencumbrances(cataloged_item.collection_object_id) like '%mask locality%' OR concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%') and
					verbatim_locality is not null
				then 'Masked'
		else
			verbatim_locality
		end verbatim_locality,
		case when
			#oneOfUs# != 1 and
				(concatencumbrances(cataloged_item.collection_object_id) like '%mask locality%' OR concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%') and
					verbatimdepth is not null
				then 'Masked'
		else
			verbatimdepth
		end verbatimdepth,
		case when
			#oneOfUs# != 1 and
				(concatencumbrances(cataloged_item.collection_object_id) like '%mask locality%' OR concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%') and
					verbatimelevation is not null
				then 'Masked'
		else
			verbatimelevation
		end verbatimelevation,
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
		cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
</cfquery>
<cfif one.concatenatedEncumbrances contains "mask record" and oneOfUs neq 1>
	Record masked.<cfabort>
</cfif>
<cfquery name="colls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select
		collector.coll_order,
		case when
			#oneOfUs# != 1 and concatencumbrances(collector.collection_object_id) like '%mask collector%' then 'Anonymous'
		else
			preferred_agent_name.agent_name
		end collectors,
		case when
			#oneOfUs# != 1 and concatencumbrances(collector.collection_object_id) like '%mask collector%' then NULL
		else
			preferred_agent_name.agent_id
		end collector_id
	from
		collector,
		preferred_agent_name
	where
		collector.collector_role='c' and
		collector.agent_id=preferred_agent_name.agent_id and
		collector.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
	ORDER BY
		coll_order
</cfquery>
<cfquery name="preps" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select
		collector.coll_order,
		case when
			#oneOfUs# != 1 and concatencumbrances(collector.collection_object_id) like '%mask preparator%' then 'Anonymous'
		else
			preferred_agent_name.agent_name
		end preparators,
		case when
			#oneOfUs# != 1 and concatencumbrances(collector.collection_object_id) like '%mask preparator%' then NULL
		else
			preferred_agent_name.agent_id
		end preparator_id
	from
		collector,
		preferred_agent_name
	where
		collector.collector_role='p' and
		collector.agent_id=preferred_agent_name.agent_id and
		collector.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
	ORDER BY
		coll_order
</cfquery>
<cfquery name="attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select
		attributes.attribute_type,
		attributes.attribute_value,
		attributes.attribute_units,
		attributes.attribute_remark,
		attributes.determination_method,
		attributes.determined_date,
		attribute_determiner.agent_name attributeDeterminer
	from
		attributes,
		preferred_agent_name attribute_determiner
	where
		attributes.determined_by_agent_id = attribute_determiner.agent_id and
		attributes.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
</cfquery>
<cfquery name="relns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
SELECT distinct biol_indiv_relationship, related_collection, related_coll_object_id, related_cat_num, biol_indiv_relation_remarks FROM (
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
WHERE rel.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
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
WHERE irel.related_coll_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
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
		publication.doi,
        cited_taxa.taxon_status as cited_name_status
	from
		citation,
		taxonomy cited_taxa,
		formatted_publication,
		publication
	where
		citation.cited_taxon_name_id = cited_taxa.taxon_name_id  AND
		citation.publication_id = formatted_publication.publication_id AND
		format_style='short' and
		citation.publication_id = publication.publication_id and
		citation.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
	order by
		substr(formatted_publication, - 4)
</cfquery>
<style>
	.acceptedIdDiv {
		border:1px dotted green;
	}
	.unAcceptedIdDiv{
		border:1px dotted gray;
		background-color:#F8F8F8;
		color:gray;
		font-size:.8em;
	}
	.taxDetDiv {
		padding-left:1em;
	}
</style>
<cfoutput query="one">
	<cfif oneOfUs is 1>
		<form name="editStuffLinks" method="post" action="SpecimenDetail.cfm">
			<input type="hidden" name="collection_object_id" value="#one.collection_object_id#">
			<input type="hidden" name="suppressHeader" value="true">
			<input type="hidden" name="action" value="nothing">
			<input type="hidden" name="Srch" value="Part">
			<input type="hidden" name="collecting_event_id" value="#one.collecting_event_id#">
	</cfif>
	<table width="100%" style="background-color: white;"><!---- full page table ---->
		<tr>
			<td valign="top" width="50%">
<!------------------------------------ Taxonomy ---------------------------------------------->
				<div class="detailCell">
					<div class="detailLabel">Identifications
						<cfif oneOfUs is 1>
							<span class="detailEditCell" onclick="window.parent.loadEditApp('editIdentification');">Edit</span>
						</cfif>
					</div>
					<div class="detailBlock" style="margin-left: 0;">
						<span class="detailData">
							<cfquery name="identification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT
									identification.scientific_name,
									concatidagent(identification.identification_id) agent_name,
									made_date,
									nature_of_id,
									identification_remarks,
									identification.identification_id,
									accepted_id_fg,
									taxa_formula,
									formatted_publication,
									identification.publication_id,
									stored_as_fg
								FROM
									identification,
									(select * from formatted_publication where format_style='short') formatted_publication
								WHERE
									identification.publication_id=formatted_publication.publication_id (+) and
									identification.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
								ORDER BY accepted_id_fg DESC,sort_order, made_date DESC
							</cfquery>
							<cfloop query="identification">
								<cfquery name="getTaxa_r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select
										taxonomy.taxon_name_id,
										display_name,
										scientific_name,
										author_text,
										common_name,
										full_taxon_name
									FROM
										identification_taxonomy,
										taxonomy,
										common_name
									WHERE
										identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id and
										taxonomy.taxon_name_id=common_name.taxon_name_id (+) and
										identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
								</cfquery>
								<cfquery name="getTaxa" dbtype="query">
									select
										taxon_name_id,
										display_name,
										scientific_name,
										author_text,
										full_taxon_name
									from
										getTaxa_r
									group by
										taxon_name_id,
										display_name,
										scientific_name,
										author_text,
										full_taxon_name
								</cfquery>
								<cfif accepted_id_fg is 1>
						        	<div class="acceptedIdDiv">
							    <cfelse>
						        	<div class="unAcceptedIdDiv">
						        </cfif>
						        <cfif getTaxa.recordcount is 1 and taxa_formula is 'a'>
									<a href="/name/#getTaxa.scientific_name#" target="_blank">#getTaxa.display_name#</a><cfif len(getTaxa.author_text) gt 0> #getTaxa.author_text#</cfif>
								<cfelse>
									<cfset link="">
									<cfset i=1>
									<cfset thisSciName="#scientific_name#">
									<cfloop query="getTaxa">
										<cfset thisLink='<a href="/name/#scientific_name#" target="_blank">#display_name#</a>'>
										<cfset thisSciName=#replace(thisSciName,scientific_name,thisLink)#>
										<cfset i=#i#+1>
									</cfloop>
									#thisSciName#
								</cfif>
								<cfif oneOfUs is 1 and stored_as_fg is 1><span style="background-color: ##cccccc; float: right;border-radius: 2px; padding: 2px;">STORED AS</span></cfif>
								<cfif not isdefined("metaDesc")>
									<cfset metaDesc="">
								</cfif>
								<div class="taxDetDiv">
									<cfloop query="getTaxa">
										<div style="font-size:.8em;color:gray;">
											#full_taxon_name#
										</div>
										<cfset metaDesc=metaDesc & '; ' & full_taxon_name>
										<cfquery name="cName" dbtype="query">
											select common_name from getTaxa_r where taxon_name_id=#taxon_name_id#
											and common_name is not null
											group by common_name order by common_name
										</cfquery>
										<div style="font-size:.8em;color:gray;padding-left:1em;">
											#valuelist(cName.common_name,"; ")#
										</div>
										<cfset metaDesc=metaDesc & '; ' & valuelist(cName.common_name,"; ")>
									</cfloop>
									<cfif len(formatted_publication) gt 0>
										sensu <a href="/publication/#publication_id#" target="_mainFrame">
												#formatted_publication#
											</a><br>
									</cfif>
									Identified by #agent_name#
									<cfif len(made_date) gt 0>
										<cfif len(made_date) gt 8> on <cfelse> in </cfif>#made_date#
									</cfif>
									<br>Nature of ID: #nature_of_id#
									<cfif len(identification_remarks) gt 0>
										<br>Remarks: #identification_remarks#
									</cfif>
								</div>
							</div>
						</cfloop>
					</span>
				</div>
			</div>
<!------------------------------------ citations ---------------------------------------------->
			<cfif len(citations.cited_name) gt 0>
				<div class="detailCell">
					<div class="detailLabel">Citations</div>
					<cfloop query="citations">
						<div class="detailBlock">
							<span class="detailData">
								<a href="/publications/showPublication.cfm?publication_id=#publication_id#"
									target="_mainFrame">
										#formatted_publication#</a>,
								<cfif len(occurs_page_number) gt 0>
									Page
										<cfif len(citation_page_uri) gt 0>
											<a href ="#citation_page_uri#" target="_blank">#occurs_page_number#</a>,
										<cfelse>
											#occurs_page_number#,
										</cfif>
								<cfelse>
									<cfif len(citation_page_uri) gt 0>
										<a href ="#citation_page_uri#" target="_blank">[link]</a>,
									</cfif>
								</cfif>
								#type_status# of
								<a href="/taxonomy/showTaxonomy.cfm?taxon_name_id=#cited_name_id#" target="_mainFrame"><i>#replace(cited_name," ","&nbsp;","all")#</i></a>
								<cfif find("(ms)", #type_status#) NEQ 0>
									<!--- Type status with (ms) is used to mark to be published types,
`										for which we aren't (yet) exposing the new name.  Append sp. nov or ssp. nov.
										as appropriate to the name of the parent taxon of the new name --->
									<cfif find(" ", #cited_name#) NEQ 0>
										&nbsp;ssp. nov.
									<cfelse>
										&nbsp;sp. nov.
									</cfif>
								</cfif>
								<div class="detailCellSmall">
									<cfif len(#DOI#) GT 0>
									doi: <a target="_blank" href='https://doi.org/#DOI#'>#DOI#</a><br>
									</cfif>
									<cfif len(#CITATION_REMARKS#) GT 0>
									#CITATION_REMARKS#<BR>
									</cfif>
								</div>
							</span>
						</div>


					</cfloop>
					<cfquery name="publicationMedia"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select
									mr.media_id, m.media_uri, m.preview_uri, ml.label_value descr, m.media_type, m.mime_type,
									mczbase.get_media_descriptor(m.media_id) as media_descriptor 
								from
									media_relations mr, 
									media_labels ml, 
									media m, 
									citation c, 
									formatted_publication fp
								where
									mr.media_id = ml.media_id and
									mr.media_id = m.media_id and
									ml.media_label = 'description' and
									MEDIA_RELATIONSHIP like '% publication' and
									RELATED_PRIMARY_KEY = c.publication_id and
									c.publication_id = fp.publication_id and
									fp.format_style='short' and
									c.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
								order by substr(formatted_publication, -4)
							</cfquery>
									<cfif publicationMedia.recordcount gt 0>
								            <span class="detailData">
													<div class="thumb_spcr">&nbsp;</div>
													<cfloop query="publicationMedia">
														<cfset altText = publicationMedia.media_descriptor>
														<cfset puri=getMediaPreview(preview_uri,media_type)>
										            	<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
															select
																media_label,
																label_value
															from
																media_labels
															where
																media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
														</cfquery>
														<cfquery name="desc" dbtype="query">
															select label_value from labels where media_label='description'
														</cfquery>
														<cfset mediadescription="Media Preview Image">
														<cfif desc.recordcount is 1>
															<cfset mediadescription=desc.label_value>
														</cfif>
										               <div class="one_thumb_small">
											               <a href="#media_uri#" target="_blank"><img src="#getMediaPreview(preview_uri,media_type)#" alt="#altText#" class="theThumbSmall"></a>
										                   	<div class="detailCellSmall">
																#media_type# (#mime_type#)
											                   	<br><a href="/media/#media_id#" target="_blank">Media Details</a>
																<br>#mediadescription#
															</div>
														</div>
													</cfloop>
													<div class="thumb_spcr">&nbsp;</div>
											</span>
									</cfif>
					</div>
			</cfif>
<!------------------------------------ locality ---------------------------------------------->
			<div class="detailCell">
				<div class="detailLabel">
					<cfif oneOfUs is 1>
						<cfif isdefined("session.roles") AND listcontainsnocase(session.roles,"manage_locality")>
							<a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#one.geog_auth_rec_id#">Geography</a>,
							<a href="/localities/viewLocality.cfm?locality_id=#one.locality_id#">Locality</a>
						<cfelse> 
							Locality
						</cfif>
 						and Collecting Event Details
						<span class="detailEditCell" onclick="window.parent.loadEditApp('specLocality');">Edit</span>
					<cfelse>
						Locality and Collecting Event Details
					</cfif>
				</div>
				<table id="SD">
					<cfif len(one.continent_ocean) gt 0>
						<tr class="detailData">
								<td id="SDCellLeft" class="innerDetailLabel">Continent/Ocean:</td>
								<td id="SDCellRight">#one.continent_ocean#</td>
						</tr>
					</cfif>
					<cfif len(one.ocean_region) gt 0>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">Ocean Region:</td>
							<td id="SDCellRight">#one.ocean_region# #one.ocean_subregion#</td>
						</tr>
					</cfif>
					<cfif len(one.sea) gt 0>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">Sea:</td>
							<td id="SDCellRight">#one.sea#</td>
						</tr>
					</cfif>
					<cfif len(one.country) gt 0>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">Country:</td>
							<td id="SDCellRight">#one.country#</td>
						</tr>
					</cfif>
					<cfif len(one.state_prov) gt 0>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">State/Province:</td>
							<td id="SDCellRight">#one.state_prov#</td>
						</tr>
					</cfif>
					<cfif len(one.feature) gt 0>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">Feature:</td>
							<td id="SDCellRight">#one.feature#</td>
						</tr>
					</cfif>
					<cfif len(one.county) gt 0>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">County:</td>
							<td id="SDCellRight">#one.county#</td>
						</tr>
					</cfif>
					<cfif len(one.island_group) gt 0>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">Island Group:</td>
							<td id="SDCellRight">#one.island_group#</td>
						</tr>
					</cfif>
					<cfif len(one.island) gt 0>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">Island:</td>
							<td id="SDCellRight">#one.island#</td>
						</tr>
					</cfif>
					<cfif len(one.quad) gt 0>
							<tr class="detailData">
								<td id="SDCellLeft" class="innerDetailLabel">USGS Quad:</td>
								<td id="SDCellRight">#one.quad#</td>
							</tr>
					</cfif>
					<cfquery name="localityMedia"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select
							media_id
						from
							media_relations
						where
							RELATED_PRIMARY_KEY= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#one.locality_id#"> and
							MEDIA_RELATIONSHIP like '% locality'
					</cfquery>
					<cfif len(one.spec_locality) gt 0>
							<tr class="detailData">
								<td id="SDCellLeft" class="innerDetailLabel">Specific Locality:</td>
								<td id="SDCellRight">
									#one.spec_locality#
									<cfif localityMedia.recordcount gt 0>
										<a class="infoLink" target="_blank" href="/MediaSearch.cfm?action=search&media_id=#valuelist(localityMedia.media_id)#">Media</a>
									</cfif>
								</td>
							</tr>
					</cfif>
					<cfquery name="collEventMedia"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select
							media_id
						from
							media_relations
						where
							RELATED_PRIMARY_KEY=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#one.collecting_event_id#"> and
							MEDIA_RELATIONSHIP like '% collecting_event'
					</cfquery>
					<cfif one.verbatim_locality is not one.spec_locality>
						<cfif len(one.verbatim_locality) gt 0>
							<tr class="detailData">
								<td id="SDCellLeft" class="innerDetailLabel">Verbatim Locality: </td>
								<td id="SDCellRight">#one.verbatim_locality#
									<cfif collEventMedia.recordcount gt 0>
										<a class="infoLink" target="_blank"	href="/MediaSearch.cfm?action=search&media_id=#valuelist(collEventMedia.media_id)#">Media</a>
									</cfif>
								</td>
							</tr>
						</cfif>
					</cfif>
					<cfif len(one.verbatimdepth) gt 0>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">Verbatim Depth:</td>
							<td id="SDCellRight">#one.verbatimdepth#</td>
						</tr>
					</cfif>
					<cfif len(one.verbatimelevation) gt 0>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">Verbatim Elevation:</td>
							<td id="SDCellRight">#one.verbatimelevation#</td>
						</tr>
					</cfif>
					<cfif len(one.locality_remarks) gt 0>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">Locality Remarks:</td>
							<td id="SDCellRight">#one.locality_remarks#</td>
						</tr>
					</cfif>
					<cfif len(one.habitat_desc) gt 0>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">General Habitat:</td>
							<td id="SDCellRight">#one.habitat_desc#</td>
						</tr>
					</cfif>
					<cfif len(one.associated_species) gt 0>
						<div class="detailBlock">
							<tr class="detailData">
								<td id="SDCellLeft" class="innerDetailLabel">Associated Species:</td>
								<td id="SDCellRight">#one.associated_species#</td>
							</tr>
						</div>
					</cfif>
					<cfif len(one.collecting_method) gt 0>
						<div class="detailBlock">
							<tr class="detailData">
								<td id="SDCellLeft" class="innerDetailLabel">Collecting&nbsp;Method:</td>
								<td id="SDCellRight">#one.collecting_method#</td>
							</tr>
						</div>
					</cfif>
					<div class="detailBlock">
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">Collecting&nbsp;Source:</td>
							<td id="SDCellRight">#one.collecting_source#</td>
						</tr>
					</div>
					<cfif len(one.minimum_elevation) gt 0>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">Elevation:</td>
							<td id="SDCellRight">#one.minimum_elevation# to #one.maximum_elevation# #one.orig_elev_units#</td>
						</tr>
					</cfif>
					<cfif len(one.depth_units) gt 0>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">Depth:</td>
							<td id="SDCellRight">#one.min_depth#
								<cfif one.min_depth neq one.max_depth>to #one.max_depth# </cfif> #one.depth_units#</td>
						</tr>
					</cfif>
					<cfif verbatimLatitude EQ 'Masked'>
						<tr class="detailData">
							<td id="SDCellLeft" class="innerDetailLabel">Coordinates:</td>
							<td id="SDCellRight">Masked</td>
						</tr>
					<cfelse>
						<cfif (len(verbatimLatitude) gt 0 and len(verbatimLongitude) gt 0)>
							<tr class="detailData">
								<td id="SDCellLeft" class="innerDetailLabel">Coordinates:</td>
								<td id="SDCellRight">#one.VerbatimLatitude# #one.verbatimLongitude#
									<cfif len(one.datum) gt 0>
										(Datum: #one.datum#)
									</cfif>
									<cfif len(one.max_error_distance) gt 0>
										, Error: #one.max_error_distance# #one.max_error_units#
									</cfif>
								</td>
							</tr>
							<cfif len(one.latLongDeterminer) gt 0>
								<cfset determination = one.latLongDeterminer>
								<cfif len(one.latLongDeterminedDate) gt 0>
									<cfset determination = '#determination#; #dateformat(one.latLongDeterminedDate, "yyyy-mm-dd")#'>
								</cfif>
								<cfif len(one.lat_long_ref_source) gt 0>
									<cfset determination = '#determination#; Source: #one.lat_long_ref_source#'>
								</cfif>
								<tr>
									<td></td>
									<td id="SDCellRight" class="detailCellSmall" style="padding-left: 1.75em;padding-top: 0;padding-bottom: .5em;">
										#determination#
									</td>
								</tr>
							</cfif>
							<cfif len(one.lat_long_remarks) gt 0>
								<tr class="detailCellSmall">
									<td></td>
									<td class="innerDetailLabel" style="padding-left: 1.75em;padding-top: 0;padding-bottom: .5em;">Coordinate Remarks:
										#encodeForHTML(one.lat_long_remarks)#
									</td>
								</tr>
							</cfif>
							<cfif len(one.verbatimcoordinates) gt 0>
								<tr class="detailData">
									<td id="SDCellLeft" class="innerDetailLabel">Verbatim Coordinates: </td>
									<td id="SDCellRight">#one.verbatimcoordinates#</td>
								</tr>
							</cfif>
							<!---<cfif len(one.verblat) gt 0 or len(one.verblong) gt 0>
								<tr class="detailData">
									<td id="SDCellLeft" class="innerDetailLabel">Verbatim Lat.: </td>
									<td id="SDCellRight">#one.verblat#</td>
                               </tr>
                               <tr>
									<td id="SDCellLeft" class="innerDetailLabel">Verbatim Long.:</td>
									<td id="SDCellRight">#one.verblat#</td>
								</tr>
							</cfif>--->
                            <cfif len(one.VerbatimCoordinateSystem) gt 0 or len(one.VerbatimSRS) gt 0 >
								<tr class="detailCellSmall">
                                <td></td>
									<td class="innerDetailLabel" style="padding-left: 1.75em;padding-top: 0;padding-bottom: .5em;">
										System: #one.verbatimCoordinateSystem#; Datum: #one.VerbatimSRS#
									</td>
								</tr>
							</cfif>
						</cfif>
					</cfif>
						<cfquery name="geology" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select * from
							geology_attributes,
							preferred_agent_name
							where
							geology_attributes.GEO_ATT_DETERMINER_ID=preferred_agent_name.agent_id (+) and
							 locality_id=#one.locality_id#
						</cfquery>
						<cfloop query="geology">
							 <td id="SDCellLeft" class="innerDetailLabel">#GEOLOGY_ATTRIBUTE#: </td>
							 <td id="SDCellRight">
								 #GEO_ATT_VALUE#
							</td>
							<tr>
								<td></td>
								<td id="SDCellRight" class="detailCellSmall">
									Determined by
									<cfif len(agent_name) gt 0>
										#agent_name#
									<cfelse>
										unknown
									</cfif>
									<cfif len(GEO_ATT_DETERMINED_DATE) gt 0>
										on #dateformat(GEO_ATT_DETERMINED_DATE,"yyyy-mm-dd")#
									</cfif>
									<cfif len(GEO_ATT_DETERMINED_METHOD) gt 0>
										Method: #GEO_ATT_DETERMINED_METHOD#
									</cfif>
									<cfif len(GEO_ATT_REMARK) gt 0>
										Remark: #GEO_ATT_REMARK#
									</cfif>
								</td>
							</tr>
						</cfloop>
					<cfif (one.verbatim_date is one.began_date) AND (one.verbatim_date is one.ended_date)>
						<cfset thisDate = #one.verbatim_date#>
					<cfelseif (
						(one.verbatim_date is not one.began_date) OR
			 			(one.verbatim_date is not one.ended_date)
						) AND one.began_date is one.ended_date>
						<cfset thisDate = "#one.verbatim_date# (#one.began_date#)">
					<cfelse>
						<cfset thisDate = "#one.verbatim_date# (#one.began_date# - #one.ended_date#)">
					</cfif>
					<tr class="detailData">
						<td id="SDCellLeft" class="innerDetailLabel">Collecting Date: </td>
						<td id="SDCellRight"> #thisDate#</td>
					</tr>
					<cfif len(one.startDayOfYear) gt 0>
					<tr class="detailData">
						<td id="SDCellLeft" class="innerDetailLabel">Day of Year (start-end): </td>
						<td id="SDCellRight"> #startDayOfYear#<cfif len(one.endDayOfYear) gt 0>-#endDayOfYear#</cfif></td>
					</tr>
					</cfif>
					<cfif len(one.collecting_time) gt 0>
					<tr class="detailData">
						<td id="SDCellLeft" class="innerDetailLabel">Collecting Time:</td>
						<td id="SDCellRight">#collecting_time#</td>
					</tr>
					</cfif>
					<cfif len(one.fish_field_number) gt 0>
					<tr class="detailData">
						<td id="SDCellLeft" class="innerDetailLabel">Ich. Field Number:</td>
						<td id="SDCellRight">#fish_field_number#</td>
					</tr>
					</cfif>
					<cfif len(one.coll_event_remarks) gt 0>
					<tr class="detailData">
						<td id="SDCellLeft" class="innerDetailLabel" nowrap>Collecting Event Remarks:</td>
						<td id="SDCellRight">#coll_event_remarks#</td>
					</tr>
					</cfif>
					<cfquery name="collEventNumbers"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select
							coll_event_number, number_series, 
							case 
								when collector_agent_id is null then '[No Agent]'
								else MCZBASE.get_agentnameoftype(collector_agent_id, 'preferred') 
							end
							as collector_agent_name
						from
							coll_event_number
							left join coll_event_num_series on coll_event_number.coll_event_num_series_id = coll_event_num_series.coll_event_num_series_id
						where
							collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#one.collecting_event_id#"> 
					</cfquery>
					<cfif collEventNumbers.recordcount gt 0>
					<tr class="detailData">
						<td id="SDCellLeft" class="innerDetailLabel" nowrap>Collecting Event/Field Number:</td>
						<td id="SDCellRight"><ul>
							<cfloop query="collEventNumbers">
								<li>#coll_event_number# (#number_series# of #collector_agent_name#)</li>
							</cfloop>
						</ul></td>
					</tr>
					</cfif>
				</table>
			</div>

<!------------------------------------ collectors ---------------------------------------------->
			<div class="detailCell">
				<div class="detailLabel">Collectors
					<cfif oneOfUs is 1>
						<span class="detailEditCell" onclick="window.parent.loadEditApp('editColls');">Edit</span>
					</cfif>
				</div>
				<cfloop query="colls">
					<cfset collectorLink ="">
					<cfset collectorLinkEnd ="">
					<cfif len(collector_id) GT 0>
						<cfset collectorLink = "<a href='/agents/Agent.cfm?agent_id=#collector_id#' target='_blank'>" >
						<cfset collectorLinkEnd ="</a>">
					</cfif>
					<div class="detailBlock">
						<span class="detailData">
							<span class="innerDetailLabel"></span>
							#collectorLink##collectors##collectorLinkEnd#
						</span>
					</div>
				</cfloop>
			</div>
<!------------------------------------ preparators ---------------------------------------------->
			<cfif len(preps.preparators) gt 0>
				<div class="detailCell">
					<div class="detailLabel">Preparators
						<cfif oneOfUs is 1>
							<span class="detailEditCell" onclick="window.parent.loadEditApp('editColls');">Edit</span>
						</cfif>
					</div>
					<cfloop query="preps">
						<cfset preparatorLink ="">
						<cfset preparatorLinkEnd ="">
						<cfif len(preparator_id) GT 0>
							<cfset preparatorLink = "<a href='/agents/Agent.cfm?agent_id=#preparator_id#' target='_blank'>" >
							<cfset preparatorLinkEnd ="</a>">
						</cfif>
						<div class="detailBlock">
							<span class="detailData">
								<span class="innerDetailLabel"></span>
								#preparatorLink##preparators##preparatorLinkEnd#
							</span>
						</div>
					</cfloop>
				</div>
			</cfif>
<!------------------------------------ collections ---------------------------------------------->
			<cfquery name="collectionsQuery"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collectionsQuery_result">
				select distinct collection_name, underscore_collection.underscore_collection_id, mask_fg
				from underscore_relation
					left join underscore_collection on underscore_relation.underscore_collection_id = underscore_collection.underscore_collection_id
				where
					underscore_relation.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#one.collection_object_id#">
					<cfif isdefined("session.roles") AND listcontainsnocase(session.roles,"manage_specimens")>
						-- all groups
					<cfelse>
						and mask_fg = 0
					</cfif>
			</cfquery>
			<cfif collectionsQuery.recordcount GT 0>
				<div class="detailCell">
					<div class="detailLabel">Included in these Collections
						<!---  TODO: Implement edit 
						<cfif isdefined("session.roles") AND listcontainsnocase(session.roles,"manage_specimens")>
							<span class="detailEditCell" onclick="window.parent.loadEditApp('editColls');">Edit</span>
						</cfif>
						--->
					</div>
					<div class="detailBlock">
						<ul>
							<cfloop query="collectionsQuery">
								<cfif collectionsQuery.mask_fg EQ 0 OR (isdefined("session.roles") AND listcontainsnocase(session.roles,"coldfusion_user"))>
									<li><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#underscore_collection_id#">#collection_name#</a></li>
								<cfelse>
									<li>#collection_name#</li>
								</cfif>
							</cfloop>
						</ul>
					</div>
				</div>
			</cfif>
<!------------------------------------ relationships ---------------------------------------------->
			<cfif len(relns.biol_indiv_relationship) gt 0 >
				<div class="detailCell">
					<div class="detailLabel" style="padding-bottom: .25em;">Relationships
						<cfif oneOfUs is 1>
							<span class="detailEditCell" onclick="window.parent.loadEditApp('editRelationship');">Edit</span>
						</cfif>
					</div>
					<cfloop query="relns">
						<div class="detailBlock" style="margin-top: .5em; padding-top: 0;margin-bottom: .5em; padding-bottom:0;">
							<span class="detailData">
								<span class="innerDetailLabel">#biol_indiv_relationship#</span>
								<a href="/SpecimenDetail.cfm?collection_object_id=#related_coll_object_id#" target="_top">
									#related_collection# #related_cat_num#
								</a>
                                <cfif len(relns.biol_indiv_relation_remarks) gt 0>
                                    <span> (Remark: #biol_indiv_relation_remarks#)</span>
                                </cfif>
							</span>
						</div>
					</cfloop>
					<cfif len(relns.biol_indiv_relationship) gt 0>
						<div class="detailBlock">
							<span class="detailData">
								<span class="innerDetailLabel"></span>
									&nbsp;&nbsp;&nbsp;<a href="/SpecimenResults.cfm?collection_object_id=#valuelist(relns.related_coll_object_id)#" target="_top">"Related To" Specimens List</a>
							</span>
						</div>
					</cfif>
				</div>
			</cfif>
			<cfquery name="isProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT project_name, project.project_id project_id FROM
				project, project_trans
				WHERE
				project_trans.project_id = project.project_id AND
				project_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#one.accn_id#">
				GROUP BY project_name, project.project_id
		  </cfquery>
		  <cfquery name="isLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT project_name, project.project_id FROM
					loan_item,
					project,
					project_trans,
					specimen_part
				 WHERE
				 	specimen_part.derived_from_cat_item = #one.collection_object_id# AND
					loan_item.transaction_id=project_trans.transaction_id AND
					project_trans.project_id=project.project_id AND
					specimen_part.collection_object_id = loan_item.collection_object_id
				GROUP BY
					project_name, project.project_id
		</cfquery>
		<cfquery name="isLoanedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT loan_item.collection_object_id FROM
			loan_item,specimen_part
			WHERE loan_item.collection_object_id=specimen_part.collection_object_id AND
			specimen_part.derived_from_cat_item=#one.collection_object_id#
		</cfquery>
		<cfquery name="loanList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT distinct loan_number, loan_type, loan_status, loan.transaction_id FROM
			specimen_part left join loan_item on specimen_part.collection_object_id=loan_item.collection_object_id
 			left join loan on loan_item.transaction_id = loan.transaction_id
			where
			loan_number is not null and
			specimen_part.derived_from_cat_item=#one.collection_object_id#
		</cfquery>
		<cfquery name="isDeaccessionedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT deacc_item.collection_object_id FROM
			specimen_part left join deacc_item on specimen_part.collection_object_id=deacc_item.collection_object_id
			where
			specimen_part.derived_from_cat_item=#one.collection_object_id#
		</cfquery>
		<cfquery name="deaccessionList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT distinct deacc_number, deacc_type, deaccession.transaction_id FROM
			specimen_part left join deacc_item on specimen_part.collection_object_id=deacc_item.collection_object_id
 			left join deaccession on deacc_item.transaction_id = deaccession.transaction_id
			where
			deacc_number is not null and
			specimen_part.derived_from_cat_item=#one.collection_object_id#
		</cfquery>
		</td>
		<td valign="top" width="50%">
	<!------------------------------------ identifiers ---------------------------------------------->
			<cfquery name="oid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					case when #oneOfUs# != 1 and
						concatencumbrances(coll_obj_other_id_num.collection_object_id) like '%mask original field number%' and
						ctcoll_other_id_type.encumber_as_field_num = 1
						then 'Masked'
					else
						coll_obj_other_id_num.display_value
					end display_value,
					coll_obj_other_id_num.other_id_type,
					case when base_url is not null then
						ctcoll_other_id_type.base_url || coll_obj_other_id_num.display_value
					else
						null
					end link
				FROM
					coll_obj_other_id_num,
					ctcoll_other_id_type
				where
					collection_object_id=#one.collection_object_id# and
					coll_obj_other_id_num.other_id_type=ctcoll_other_id_type.other_id_type (+)
				ORDER BY
					other_id_type,
					display_value
			</cfquery>
			<cfif len(oid.other_id_type) gt 0>
				<div class="detailCell">
					<div class="detailLabel">Identifiers
						<cfif oneOfUs is 1>
							<span class="detailEditCell" onclick="window.parent.loadEditApp('editIdentifiers');">Edit</span>
						</cfif>
					</div>
					<cfloop query="oid">
						<div class="detailBlock">
							<span class="innerDetailLabel">#other_id_type#:</span>
								<cfif len(link) gt 0>
									<a class="external" href="#link#" target="_blank">#display_value#</a>
								<cfelse>
									#display_value#
								</cfif>
							</span>
						</div>
					</cfloop>
				</div>
			</cfif>
<!------------------------------------ parts ---------------------------------------------->
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
		specimen_part.derived_from_cat_item=#one.collection_object_id#
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
                part_name, part_id
</cfquery>

<cfquery name="mPart" dbtype="query">
	select * from parts where sampled_from_obj_id is null order by part_name
</cfquery>
<cfif oneofus is 1 or not Findnocase("mask parts", one.encumbranceDetail)>
			<div class="detailCell">
				<div class="detailLabel">Part Details<!---Parts--->
					<cfif oneOfUs is 1>
						<span class="detailEditCell" onclick="window.parent.loadEditApp('editParts');">Edit</span>
				<!---	<cfelse>
						<span class="detailEditCell" onClick="getInfo('parts','#one.collection_object_id#');">Details</span>--->
					</cfif>
				</div>
			<div class="detailBlock" style="margin-left: 0px;">
						<table class="partname">
							<tr>
			<th class="inside"><span class="innerDetailLabel">Part Name</span></th>
								<th class="inside"><span class="innerDetailLabel">Condition</span></th>
								<th class="inside"><span class="innerDetailLabel">Disposition</span></th>
								<th class="inside"><span class="innerDetailLabel">##</span></th>
								<cfif oneOfus is "1">
									<th class="inside"><span class="innerDetailLabel">Container Name</span></th>
								</cfif>
								<th class="inside"><span class="innerDetailLabel">Remarks</span></th>
							</tr>
							<cfloop query="mPart">
								<tr>
									<td class="inside">#part_name#</td>
									<td class="inside">#part_condition#</td>
									<td class="inside">#part_disposition#
										<cfif loanList.recordcount GT 0 AND isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
											<!--- look up whether this part is in an open loan --->
											<cfquery name="partonloan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												select loan_number, loan_type, loan_status, loan.transaction_id, item_descr, loan_item_remarks
												from specimen_part left join loan_item on specimen_part.collection_object_id = loan_item.collection_object_id
													left join loan on loan_item.transaction_id = loan.transaction_id
												where specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mPart.part_id#">
													and loan_status <> 'closed'
											</cfquery>
											<cfloop query="partonloan">
												<cfif partonloan.loan_status EQ 'open' and mPart.part_disposition EQ 'on loan'>
													<!--- normal case --->
													<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#partonloan.transaction_id#">#partonloan.loan_number#</a>
												<cfelse>
													<!--- partial returns, in process, historical, in-house, or in open loan but part disposition in collection--->
													<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#partonloan.transaction_id#">#partonloan.loan_number# (#partonloan.loan_status#)</a>
												</cfif>
											</cfloop>
										</cfif>
									</td>
									<td class="inside">#lot_count#</td>
									<cfif oneOfus is 1>
										<td class="inside">#label#</td>
									</cfif>
									<td class="inside">#part_remarks#</td>
								</tr>
							<cfquery name="patt" dbtype="query">
									select
										attribute_type,
										attribute_value,
										attribute_units,
										determined_date,
										attribute_remark,
										agent_name
									from
										rparts
									where
										attribute_type is not null and
										part_id=#part_id#
									group by
										attribute_type,
										attribute_value,
										attribute_units,
										determined_date,
										attribute_remark,
										agent_name
								</cfquery>
								<cfif patt.recordcount gt 0>
									<tr>
										<td colspan="6" class="partnameatts">
											<cfloop query="patt">
												<div style="margin-left:1em;" class="detailCellSmall">
													<strong>#attribute_type#</strong>=<strong>#attribute_value#</strong>
													<cfif len(attribute_units) gt 0>
													 	<strong>#attribute_units#</strong>
													</cfif>
													<cfif len(determined_date) gt 0>
													 	determined date=<strong>#dateformat(determined_date,"yyyy-mm-dd")#</strong>
													</cfif>
													<cfif len(agent_name) gt 0>
													 	determined by=<strong>#agent_name#</strong>
													</cfif>
													<cfif len(attribute_remark) gt 0>
													 	remark=<strong>#attribute_remark#</strong>
													</cfif>

												</div>
											</cfloop>
										</td>
									</tr>									<!---/cfloop--->
								</cfif>
								<cfquery name="sPart" dbtype="query">
									select * from parts where sampled_from_obj_id=#part_id#
								</cfquery>
								<cfloop query="sPart">
									<tr>
										<td class="inside_sub" style="min-width:150px;"><span>#part_name# subsample</span></td>
										<td class="inside_sub">#part_condition#</td>
										<td class="inside_sub">#part_disposition#
											<cfif loanList.recordcount GT 0 AND isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
												<!--- look up whether this part is in an open loan --->
												<cfquery name="partonloan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
													select loan_number, loan_type, loan_status, loan.transaction_id, item_descr, loan_item_remarks
													from specimen_part left join loan_item on specimen_part.collection_object_id = loan_item.collection_object_id
														left join loan on loan_item.transaction_id = loan.transaction_id
													where specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#sPart.part_id#">
														and loan_status <> 'closed'
												</cfquery>
												<cfloop query="partonloan">
													<cfif partonloan.loan_status EQ 'open' and sPart.part_disposition EQ 'on loan'>
														<!--- normal case --->
														<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#partonloan.transaction_id#">#partonloan.loan_number#</a>
													<cfelse>
														<!--- partial returns, in process, historical, in-house, or in open loan but part disposition in collection--->
														<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#partonloan.transaction_id#">#partonloan.loan_number# (#partonloan.loan_status#)</a>
													</cfif>
												</cfloop>
											</cfif>
										</td>
										<td class="inside_sub">#lot_count#</td>
										<cfif oneOfus is 1>
											<td class="inside_sub">#label#</td>
										</cfif>
										<td class="inside_sub">#part_remarks#</td>
									</tr>
								</cfloop>
							</cfloop>
						</table>
				</div>
			</div>
</cfif>
<!------------------------------------ attributes ---------------------------------------------->
			<cfif len(attribute.attribute_type) gt 0>
				<div class="detailCell">
					<div class="detailLabel">Attributes
						<cfif oneOfUs is 1>
							<span class="detailEditCell" onclick="window.parent.loadEditApp('editBiolIndiv');">Edit</span>
						</cfif>
					</div>
					<cfquery name="sex" dbtype="query">
						select * from attribute where attribute_type = 'sex'
					</cfquery>
					<div class="detailBlock">
						<cfloop query="sex">
							<div class="detailBlock">
								<span class="detailData">
									<span class="innerDetailLabel">sex:</span>
									#attribute_value#
									<cfif len(attributeDeterminer) gt 0>
										<cfset determination = "#attributeDeterminer#">
										<cfif len(determined_date) gt 0>
											<cfset determination = '#determination#, #dateformat(determined_date,"yyyy-mm-dd")#'>
										</cfif>
										<cfif len(determination_method) gt 0>
											<cfset determination = '#determination#, #determination_method#'>
										</cfif>
										<div class="detailBlock">
											<span class="detailCellSmall">
												#determination#
											</span>
										</div>
									</cfif>
									<cfif len(attribute_remark) gt 0>
										<div class="detailBlock">
											<span class="detailCellSmall">
												<span class="innerDetailLabel">Remark:</span>
												#attribute_remark#
											</span>
										</div>
									</cfif>
								</span>
							</div>
						</cfloop>
					<cfif one.collection_cde is "Mamm">
						<cfquery name="total_length" dbtype="query">
							select * from attribute where attribute_type = 'total length'
						</cfquery>
						<cfquery name="tail_length" dbtype="query">
							select * from attribute where attribute_type = 'tail length'
						</cfquery>
						<cfquery name="hf" dbtype="query">
							select * from attribute where attribute_type = 'hind foot with claw'
						</cfquery>
						<cfquery name="efn" dbtype="query">
							select * from attribute where attribute_type = 'ear from notch'
						</cfquery>
						<cfquery name="weight" dbtype="query">
							select * from attribute where attribute_type = 'weight'
						</cfquery>
						<cfquery name="theRest" dbtype="query">
							select * from attribute where attribute_type NOT IN (
								'weight','sex','total length','tail length','hind foot with claw','ear from notch'
							)
						</cfquery>
						<cfif len(total_length.attribute_units) gt 0 OR
								len(tail_length.attribute_units) gt 0 OR
								len(hf.attribute_units) gt 0  OR
								len(efn.attribute_units) gt 0  OR
								len(weight.attribute_units) gt 0><!---semi-standard measurements --->
							<div class="detailBlock">
								<span class="detailData">
									<span class="innerDetailLabel">Std. Meas.</span>
									<table border width="100%">
										<tr>
											<td><font size="-1">total length</font></td>
											<td><font size="-1">tail length</font></td>
											<td><font size="-1">hind foot</font></td>
											<td><font size="-1">efn</font></td>
											<td><font size="-1">weight</font></td>
										</tr>
										<tr>
											<td>#total_length.attribute_value# #total_length.attribute_units#&nbsp;</td>
											<td>#tail_length.attribute_value# #tail_length.attribute_units#&nbsp;</td>
											<td>#hf.attribute_value# #hf.attribute_units#&nbsp;</td>
											<td>#efn.attribute_value# #efn.attribute_units#&nbsp;</td>
											<td>#weight.attribute_value# #weight.attribute_units#&nbsp;</td>
										</tr>
									</table>
									<cfif isdefined("attributeDeterminer") and len(#attributeDeterminer#) gt 0>
										<cfset determination = "#attributeDeterminer#">
										<cfif len(determined_date) gt 0>
											<cfset determination = '#determination#, #dateformat(determined_date,"yyyy-mm-dd")#'>
										</cfif>
										<cfif len(determination_method) gt 0>
											<cfset determination = '#determination#, #determination_method#'>
										</cfif>
										<div class="detailBlock">
											<span class="detailCellSmall">
												#determination#
											</span>
										</div>
									</cfif>
								</span>
							</div>
						</cfif>
					<cfelse>
						<cfquery name="theRest" dbtype="query">
							select * from attribute where attribute_type NOT IN ('sex')
						</cfquery>
					</cfif>
					<cfloop query="theRest">
						<div class="detailBlock">
							<span class="detailData">
								<span class="innerDetailLabel">#attribute_type#:</span>
								#attribute_value#
								<cfif len(attribute_units) gt 0>
									#attribute_units#
								</cfif>
								<cfif len(attributeDeterminer) gt 0>
									<cfset determination = "&nbsp;&nbsp;#attributeDeterminer#">
									<cfif len(determined_date) gt 0>
										<cfset determination = '#determination#, #dateformat(determined_date,"yyyy-mm-dd")#'>
									</cfif>
									<cfif len(determination_method) gt 0>
										<cfset determination = '#determination#, #determination_method#'>
									</cfif>
									<div class="detailBlock">
										<span class="detailCellSmall">
											#determination#
										</span>
									</div>
								</cfif>
								<cfif len(attribute_remark) gt 0>
									<div class="detailBlock">
										<span class="detailCellSmall">
											&nbsp;&nbsp;<span class="innerDetailLabel">Remark:</span>
											#attribute_remark#
										</span>
									</div>
								</cfif>
							</div>
						</span>
					</cfloop>
				</div>
			</div>
			</cfif>
<!------------------------------------ cataloged item ---------------------------------------------->
			<div class="detailCell">
				<div class="detailLabel">
					<cfif oneOfUs is 1>
						<span class="detailEditCell" onclick="window.parent.loadEditApp('editBiolIndiv');">Edit</span>
					</cfif>
                </div>
<cfif oneofus is 1 or not Findnocase("mask parts", one.encumbranceDetail)>
					<cfif len(one.coll_object_remarks) gt 0>
						<div class="detailBlock">
							<span class="detailData">
								<span class="innerDetailLabel">Remarks:</span>
								#one.coll_object_remarks#
							</span>
						</div>
					</cfif>
</cfif>
					<cfif len(one.habitat) gt 0>
						<div class="detailBlock">
							<span class="detailData">
								<span class="innerDetailLabel">Microhabitat:</span>
								#one.habitat#
							</span>
						</div>
					</cfif>
					<cfif oneOfUs is 1>
						<div class="detailBlock">

							<span class="detailData">
								<span class="innerDetailLabel">Entered By:</span>
								#one.EnteredBy# on #dateformat(one.coll_object_entered_date,"yyyy-mm-dd")#
							</span>
						</div>
						<cfif #one.EditedBy# is not "unknown" OR len(#one.last_edit_date#) is not 0>
							<div class="detailBlock">
								<span class="detailData">
									<span class="innerDetailLabel">Last Edited By:</span>
									#one.EditedBy# on #dateformat(one.last_edit_date,"yyyy-mm-dd")#
								</span>
							</div>
						</cfif>
						<cfif len(#one.flags#) is not 0>
							<div class="detailBlock">
								<span class="detailData">
									<span class="innerDetailLabel">Missing (flags):</span>
									#one.flags#
								</span>
							</div>
						</cfif>
						<cfif len(#one.encumbranceDetail#) is not 0>
							<div class="detailBlock">
								<span class="detailData">
									<span class="innerDetailLabel">Encumbrances:</span>
									#replace(one.encumbranceDetail,";","<br>","all")#
								</span>
							</div>
						</cfif>
					</cfif>
				</div>
			</div>
<!------------------------------------ accession ---------------------------------------------->
			<cfif oneOfUs is 1 and vpdaccn is 1>
				<cfquery name="accnLimitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select specific_type, restriction_summary 
					from  permit_trans 
						left join permit on permit_trans.permit_id = permit.permit_id
					where 
						permit_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#one.accn_id#">
						and permit.restriction_summary IS NOT NULL
				</cfquery>
				<cfquery name="accnCollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT collection_cde
					from trans 
						left join collection on trans.collection_id = collection.collection_id
					WHERE
						trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#one.accn_id#">
			  	</cfquery>
				<cfset accnDept = "">
				<cfif NOT one.collection_cde IS accnCollection.collection_cde>
					<cfset accnDept = "(#accnCollection.collection_cde#)">
				</cfif>
				<cfquery name="accnMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select
						media.media_id,
						media.media_uri,
						media.mime_type,
						media.media_type,
						media.preview_uri,
						label_value descr,
						mczbase.get_media_descriptor(media.media_id) as media_descriptor
					from
						media,
						media_relations,
						(select media_id,label_value from media_labels where media_label='description') media_labels
					where
						media.media_id=media_relations.media_id and
						media.media_id=media_labels.media_id (+) and
						media_relations.media_relationship like '% accn' and
						media_relations.related_primary_key= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#one.accn_id#">
				</cfquery>
				<div class="detailCell">
					<div class="detailLabel">Accession
						<cfif oneOfUs is 1>
							<span class="detailEditCell" onclick="window.parent.loadEditApp('addAccn');">Edit</span>
						</cfif>
					</div>
					<div class="detailBlock">
						<span class="detailData">
							<cfif oneOfUs is 1>
								<a href="/transactions/Accession.cfm?action=edit&transaction_id=#one.accn_id#" target="_blank">#accession#</a> #accnDept#
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
									<cfquery name="lookupAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										SELECT
											accn.accn_number,
											accn_type,
											accn_status,
											to_char(received_date,'yyyy-mm-dd') received_date,
											concattransagent(trans.transaction_id,'received from') received_from
										FROM
											cataloged_item
											left join accn on cataloged_item.accn_id =  accn.transaction_id
											left join trans on accn.transaction_id = trans.transaction_id
										WHERE
											cataloged_item.collection_object_id = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
									</cfquery>
									<cfif lookupAccn.recordcount EQ 1>
										Received from #lookupAccn.received_from# #lookupAccn.received_date# #lookupAccn.accn_type# #lookupAccn.accn_status#
									</cfif>
								</cfif>
								<cfif accnLimitations.recordcount GT 0>
									<h3 class="detailLabel">Restrictions on use</h3>
									<cfloop query=accnLimitations>
										<p>#accnLimitations.specific_type#: #accnLimitations.restriction_summary#</p>
									</cfloop>
								</cfif>
							<cfelse>
								#accession# #accnDept#
							</cfif>
							<cfif accnMedia.recordcount gt 0>
								<div class="thumbs">
									<div class="thumb_spcr">&nbsp;</div>
									<cfloop query="accnMedia">
										<cfset altText = accnMedia.media_descriptor>
										<div class="one_thumb">
											<a href="#media_uri#" target="_blank">
												<img src="#getMediaPreview(preview_uri,media_type)#" alt="#altText#" class="theThumb">
											</a>
											<p>
												#media_type# (#mime_type#)
												<br><a href="/media/#media_id#" target="_blank">Media Details</a>
												<br>#descr#
											</p>
										</div>
									</cfloop>
									<div class="thumb_spcr">&nbsp;</div>
								</div>
							</cfif>
						</span>
					</div>
				</div>
			</cfif>
<!------------------------------------ usage ---------------------------------------------->
		<cfif isProj.recordcount gt 0 OR isLoan.recordcount gt 0 or
                           (oneOfUs is 1 and isLoanedItem.collection_object_id gt 0) or
                           (oneOfUs is 1 and isDeaccessionedItem.collection_object_id gt 0)
                >
			<div class="detailCell">
				<div class="detailLabel">Usage</div>
					<cfloop query="isProj">
						<div class="detailBlock">
							<span class="detailData">
								<span class="innerDetailLabel">Contributed By Project:</span>
									<a href="/ProjectDetail.cfm?src=proj&project_id=#isProj.project_id#">#isProj.project_name#</a>
							</span>
						</div>
					</cfloop>
					<cfloop query="isLoan">
						<div class="detailBlock">
							<span class="detailData">
								<span class="innerDetailLabel">Used By Project:</span>
		 						<a href="/ProjectDetail.cfm?src=proj&project_id=#isLoan.project_id#" target="_mainFrame">#isLoan.project_name#</a>
							</span>
						</div>
					</cfloop>
					<cfif isLoanedItem.collection_object_id gt 0 and oneOfUs is 1>
						<div class="detailBlock">
							<span class="detailData">
								<span class="innerDetailLabel">Loan History:</span>
									<a href="/Transactions.cfm?action=findLoans&execute=true&collection_object_id=#valuelist(isLoanedItem.collection_object_id)#"
										target="_mainFrame">Loans that include this cataloged item (#loanList.recordcount#).</a>
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
							<cfloop query="loanList">
								#loanList.loan_number# (#loanList.loan_type# #loanList.loan_status#)&nbsp;
							</cfloop>
							</cfif>
							</span>
						</div>
					</cfif>
					<cfif isDeaccessionedItem.collection_object_id gt 0 and oneOfUs is 1>
						<div class="detailBlock">
							<span class="detailData">
								<span class="innerDetailLabel">Deaccessions:</span>
									<a href="/Transactions.cfm?action=findDeaccessions&execute=true&collection_object_id=#valuelist(isDeaccessionedItem.collection_object_id)#"
										target="_mainFrame">Deaccessions that include this cataloged item (#deaccessionList.recordcount#).</a> &nbsp;
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
							<cfloop query="deaccessionList">
								<a href="/transactions/Deaccession.cfm?action=edit&transaction_id=#deaccessionList.transaction_id#">#deaccessionList.deacc_number# (#deaccessionList.deacc_type#)</a>&nbsp;
							</cfloop>
							</cfif>
							</span>
						</div>
					</cfif>
				</div>
		</cfif>
<!------------------------------------ Media ---------------------------------------------->
<cfquery name="mediaTag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct
		media.media_id,
		media.media_uri,
		media.mime_type,
		media.media_type,
		media.preview_uri,
		mczbase.get_media_descriptor(media.media_id) as media_descriptor
	from
		media,
		tag
	where
		media.media_id=tag.media_id and
		tag.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
</cfquery>
<cfif mediaTag.recordcount gt 0>
	 <div class="detailCell">
		<div class="detailLabel">Tagged in Media
		</div>
		<div class="detailBlock">
         <cfset mediaStartTime = #Now()#> 
			<cfloop query="mediaTag">
				<cfset altText = mediaTag.media_descriptor>
         	<cfset mediaLoopTime = #Now()#> 
				<cfif DateDiff('s',mediaStartTime,mediaLoopTime) GT 10>
					<!--- Lookups of mediaPreview on slow remote server can exceed the timeout for cfoutput, if responses are slow, fallback to noThumb before timing out page --->
					<cfset puri='/images/noThumb.jpg'>
				<cfelse>
					<cfset puri=getMediaPreview(preview_uri,media_type)>
				</cfif>
				<span class="detailData">
					<a href="/showTAG.cfm?media_id=#media_id#" target="_blank"><img src="#puri#" alt="#altText#"></a>
				</span>
			</cfloop>
		</div>
	</div>
</cfif>
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
	<div class="detailCell">
		<div class="detailLabel">Media
		<cfquery name="wrlCount" dbtype="query">
			select * from media where mime_type = 'model/vrml'
		</cfquery>
		<cfif wrlCount.recordcount gt 0>
			<br><span class="innerDetailLabel">Note: CT scans with mime type "model/vrml" require an external plugin such as <a href="http://cic.nist.gov/vrml/cosmoplayer.html">Cosmo3d</a> or <a href="http://mediamachines.wordpress.com/flux-player-and-flux-studio/">Flux Player</a>. For Mac users, a standalone player such as <a href="http://meshlab.sourceforge.net/">MeshLab</a> will be required.</span>
		</cfif>
		<cfquery name="pdfCount" dbtype="query">
			select * from media where mime_type = 'application/pdf'
		</cfquery>
		<cfif pdfCount.recordcount gt 0>
			<br><span class="innerDetailLabel">For best results, open PDF files in the most recent version of Adobe Reader.</span>
		</cfif>
		 		<cfif oneOfUs is 1>
				 <cfquery name="hasConfirmedImageAttr"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(*) c
					FROM
						ctattribute_type
					where attribute_type='image confirmed' and
					collection_cde='#one.collection_cde#'
				</cfquery>
				<span class="detailEditCell" onclick="window.parent.loadEditApp('MediaSearch');">Edit</span>
				<cfquery name="isConf"  dbtype="query">
					SELECT count(*) c
					FROM
						attribute
					where attribute_type='image confirmed'
				</cfquery>
				<CFIF isConf.c is "" and hasConfirmedImageAttr.c gt 0>
					<span class="infoLink"
						id="ala_image_confirm" onclick='windowOpener("/ALA_Imaging/confirmImage.cfm?collection_object_id=#collection_object_id#","alaWin","width=700,height=400, resizable,scrollbars,location,toolbar");'>
						Confirm Image IDs
					</span>
				</CFIF>
			</cfif>
		</div>
		<div class="detailBlock">
            <span class="detailData">
				<!---div class="thumbs"--->
					<div class="thumb_spcr">&nbsp;</div>
					<cfloop query="media">
						<cfset altText = media.media_descriptor>
						<cfset puri=getMediaPreview(preview_uri,media_type)>
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
                        	<cfset one_thumb = "<div class='one_thumb_box'>">
							<cfset aForImHref = "/media/RelatedMedia.cfm?media_id=#media_id#" >
							<cfset aForDetHref = "/media/RelatedMedia.cfm?media_id=#media_id#" >
						<cfelse>
                        	<cfset one_thumb = "<div class='one_thumb'>">
						    <cfset aForImHref = media_uri>
						    <cfset aForDetHref = "/media/#media_id#">
						</cfif>
		              		#one_thumb#
			               <a href="#aForImHref#" target="_blank"><img src="#getMediaPreview(preview_uri,media_type)#" alt="#altText#" class="theThumb"></a>
		                   	<p>
								#media_type# (#mime_type#)
			                   	<br><a href="#aForDetHref#" target="_blank">Media Details</a>
								<br>#description#
								<cfif #media_type# eq "audio">
									<!--- check for a transcript, link if present --->
									<cfquery name="checkForTranscript" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										SELECT
											transcript.media_uri as transcript_uri,
											transcript.media_id as transcript_media_id
										FROM
											media_relations
											left join media transcript on media_relations.media_id = transcript.media_id
										WHERE
											media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL"value="#media_id#"> 
											and media_relationship = 'transcript for audio media'
											and MCZBASE.is_media_encumbered(transcript.media_id) < 1
									</cfquery>
									<cfif checkforTranscript.recordcount GT 0>
										<cfloop query="checkForTranscript">
											<br><span style='font-size:small'><a href="#transcript_uri#">View Transcript</a></span>
										</cfloop>
									</cfif>
								</cfif>
							</p>
						</div>
					</cfloop>
					<div class="thumb_spcr">&nbsp;</div>
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
			cataloged_item.collection_object_id=#collection_object_id#
		</cfquery>
		<!---cfloop query="barcode">
			<cfquery name="ocr" datasource="taccocr">
				select label from output where barcode = '#barcode#'
			</cfquery>
			<cfif ocr.recordcount is 1>
				<div class="detailLabel">
					OCR for #barcode#
				</div>
				<div class="detailBlock">
		            <span class="detailData">
						#replace(ocr.label,chr(10),'<br>','all')#
			        </span>
				</div>
			</cfif>
		</cfloop--->
	</div>
</cfif>
	</td><!--- end right half of table --->
</table>
<cfif oneOfUs is 1>
</form>
</cfif>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"collops")>
	<!---  For a small set of collections operations users, include the TDWG BDQ TG2 test integration --->
	<script type='text/javascript' language="javascript" src='/dataquality/js/bdq_quality_control.js'></script>
	<script>
		function runTests() {
			loadNameQC(#collection_object_id#, "", "NameDQDiv");
			loadSpaceQC(#collection_object_id#, "", "SpatialDQDiv");
			loadEventQC(#collection_object_id#, "", "EventDQDiv");
		}
	</script>
	<input type="button" value="QC" class="savBtn" onClick=" runTests(); ">
	<!---  Scientific Name tests --->
	<div id="NameDQDiv"></div>
	<!---  Spatial tests --->
	<div id="SpatialDQDiv"></div>
	<!---  Temporal tests --->
	<div id="EventDQDiv"></div>
</cfif>
</cfoutput>
<cf_customizeIFrame>
