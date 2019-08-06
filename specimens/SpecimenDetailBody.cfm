<cfif not isdefined("toProperCase")>
</cfif>

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
<cfif oneOfUs is 0 and cgi.CF_TEMPLATE_PATH contains "/redesign/specimen-details-body-datatables.cfm">
	<!---<cfheader statuscode="301" statustext="Moved permanently">
	<cfheader name="Location" value="/redesign/specimen_detail.cfm?collection_object_id=#collection_object_id#">--->
</cfif>
</cfoutput>
<cfset detSelect = "SELECT
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
				concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' and
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
				concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' and
					locality.spec_locality is not null
				then 'Masked'
		else
		locality.spec_locality
		end spec_locality,
		case when
			#oneOfUs# != 1 and
				concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' and
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
				concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' and
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
				concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' and
					locality.locality_remarks is not null
				then 'Masked'
		else
				locality.locality_remarks
		end locality_remarks,
		case when
			#oneOfUs# != 1 and
				concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' and
					verbatim_locality is not null
				then 'Masked'
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
	cataloged_item.collection_object_id = #collection_object_id#
	">
<!---<cfset checkSql(detSelect)>--->
<cfquery name="one" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	#preservesinglequotes(detSelect)#
</cfquery>
<cfif one.concatenatedEncumbrances contains "mask record" and oneOfUs neq 1>
	Record masked.
	<cfabort>
</cfif>
<cfquery name="colls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT
		collector.coll_order,
		case when
			#oneOfUs# != 1 and concatencumbrances(collector.collection_object_id) like '%mask collector%' then 'Anonymous'
		else
			preferred_agent_name.agent_name
		end collectors
	FROM
		collector,
		preferred_agent_name
	WHERE
		collector.collector_role='c' and
		collector.agent_id=preferred_agent_name.agent_id and
		collector.collection_object_id = #collection_object_id#
	ORDER BY
		coll_order
</cfquery>
<cfquery name="preps" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT
		collector.coll_order,
		case when
			#oneOfUs# != 1 and concatencumbrances(collector.collection_object_id) like '%mask preparator%' then 'Anonymous'
		else
			preferred_agent_name.agent_name
		end preparators
	FROM
		collector,
		preferred_agent_name
	WHERE
		collector.collector_role='p' and
		collector.agent_id=preferred_agent_name.agent_id and
		collector.collection_object_id = #collection_object_id#
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
		attributes.collection_object_id = #collection_object_id#
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
	WHERE rel.collection_object_id=#collection_object_id#
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
	WHERE irel.related_coll_object_id=#collection_object_id#
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
		citation.collection_object_id = #collection_object_id#
	order by
		substr(formatted_publication, - 4)
</cfquery>
<cfoutput query="one">
<cfif oneOfUs is 1>
	<form name="editStuffLinks" method="post" action="/redesign/specimen-details2.cfm">
	<input type="hidden" name="collection_object_id" value="#one.collection_object_id#">
	<input type="hidden" name="suppressHeader" value="true">
	<input type="hidden" name="action" value="nothing">
	<input type="hidden" name="Srch" value="Part">
	<input type="hidden" name="collecting_event_id" value="#one.collecting_event_id#">
</cfif>
	<div class="card-columns"> 

		<!----------------------------- identifications ---------------------------------->
	<div class="card">
		<div class="card-header">
			<h3 class="h4"> Identifications</h3>
			<button type="button" class="popperbtn detail-edit-cell float-right py-0 px-2 fs-14 border-dk-gray rounded" onClick="$('##dialog-form').dialog('open'); setupNewLocality(#locality_id#);">Edit</button>
		</div>
		<div class="card-body">
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
					identification.collection_object_id = #collection_object_id#
				ORDER BY accepted_id_fg DESC,sort_order, made_date DESC
			</cfquery>
			<cfloop query="identification">
				<cfquery name="getTaxa_r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
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
						identification_id=#identification_id#
				</cfquery>
				<cfquery name="getTaxa" dbtype="query">
					SELECT
						taxon_name_id,
						display_name,
						scientific_name,
						author_text,
						full_taxon_name 
					FROM 
						getTaxa_r 
					GROUP BY 
						taxon_name_id,
						display_name,
						scientific_name,
						author_text,
						full_taxon_name
				</cfquery>
				<cfif accepted_id_fg is 1>
					<ul class="list-group border-green rounded p-3 h4 font-weight-normal">
						<span class="d-inline-block mb-1 h5 text-success"> Current Identification</span>
						<cfif getTaxa.recordcount is 1 and taxa_formula is 'a'>
								<span class="font-italic h3 font-weight-normal d-inline-block"> 
									<a href="/name/#getTaxa.scientific_name#" target="_blank">#getTaxa.display_name# </a> 
								<cfif len(getTaxa.author_text) gt 0>
									#getTaxa.author_text# 
								</cfif>
								</span>
							<cfelse>
							<cfset link="">
							<cfset i=1>
							<cfset thisSciName="#scientific_name#">
							<cfloop query="getTaxa">
								<span class="font-italic h3 font-weight-normal d-inline-block"> 
									<cfset thisLink='<a href="/name/#scientific_name#" class="d-inline" target="_blank">#display_name#</a>'>
									<cfset thisSciName=#replace(thisSciName,scientific_name,thisLink)#>
										<cfset i=#i#+1><a href="##">#thisSciName#</a> #getTaxa.author_text# 
								</span>
							</cfloop>
						</cfif>
						<cfif oneOfUs is 1 and stored_as_fg is 1>
							<span class="bg-gray float-right rounded p-1">STORED AS</span>
						</cfif>
						<cfif not isdefined("metaDesc")>
							<cfset metaDesc="">
						</cfif>
						<cfloop query="getTaxa">
							<p class="h5 text-muted"> #full_taxon_name# </p>
							<cfset metaDesc=metaDesc & '; ' & full_taxon_name>
							<cfquery name="cName" dbtype="query">
								SELECT 
									common_name 
								FROM 
									getTaxa_r 
								WHERE 
									taxon_name_id=#taxon_name_id# and 
									common_name is not null
								GROUP BY 
									common_name order by common_name
							</cfquery>
							<div class="h5 text-muted pl-3">#valuelist(cName.common_name,"; ")# </div>
							<cfset metaDesc=metaDesc & '; ' & valuelist(cName.common_name,"; ")>
						</cfloop>
						<cfif len(formatted_publication) gt 0>
							sensu <a href="/publication/#publication_id#" target="_mainFrame"> #formatted_publication# </a>
						</cfif>
						<p class="h5"> #agent_name#
							<cfif len(made_date) gt 0>
								on #dateformat(made_date,"yyyy-mm-dd")#
							</cfif>
							<span>, #nature_of_id#</span> </p>
						<cfif len(identification_remarks) gt 0>
							<p class="h5">Remarks: #identification_remarks#</p>
						</cfif>
					</ul>
				<cfelse>
					<ul class="list-group pt-2 pb-0 px-3 text-dark">
						<li class="pid">
						<cfif getTaxa.recordcount is 1 and taxa_formula is 'a'>
							<p>
							<span class="font-weight-light font-italic fs-17 font-weight-bolder"><a href="/name/#getTaxa.scientific_name#" target="_blank">#getTaxa.display_name#</a></span>
							<cfif len(getTaxa.author_text) gt 0>
								#getTaxa.author_text#
								</p>
							</cfif>
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
					<cfif oneOfUs is 1 and stored_as_fg is 1>
						<span style="background-color: ##cccccc; float: right;border-radius: 2px; padding: 2px;">STORED AS</span>
					</cfif>
					<cfif not isdefined("metaDesc")>
						<cfset metaDesc="">
					</cfif>
					<cfloop query="getTaxa">
						<p style="font-size:.8em;color:gray;"> #full_taxon_name# </p>
						<cfset metaDesc=metaDesc & '; ' & full_taxon_name>
						<cfquery name="cName" dbtype="query">
							select common_name from getTaxa_r where taxon_name_id=#taxon_name_id#
							and common_name is not null
							group by common_name order by common_name
						</cfquery>
						<div style="font-size:.8em;color:gray;padding-left:1em;">#valuelist(cName.common_name,"; ")# </div>
						<cfset metaDesc=metaDesc & '; ' & valuelist(cName.common_name,"; ")>
					</cfloop>
					<cfif len(formatted_publication) gt 0>
						sensu <a href="/publication/#publication_id#" target="_mainFrame"> #formatted_publication# </a>
					</cfif>
					<p style="font-size: .9em;"> #agent_name#
						<cfif len(made_date) gt 0>
							on #dateformat(made_date,"yyyy-mm-dd")#
						</cfif>
						<span >, #nature_of_id#</span> </p>
					<cfif len(identification_remarks) gt 0>
						<p style="font-size: .9em;">Remarks: #identification_remarks#</p>
					</cfif>
				</cfif>
						</li>
					</ul>
			</cfloop>
		</div>
	</div>
<!------------------------------------ locality -------------------------------------------> 
	<div class="card">
		<div class="card-header">
			<h3 class="h4">Locality</h3>
			<button type="button" id="edit-locality" class="popperbtn detail-edit-cell float-right py-0 px-2 fs-14 border-dk-gray rounded" onClick="$('##dialog-form').dialog('open'); setupNewLocality(#locality_id#);">Edit</button>
		</div>
		<cfquery name="getLoc"	 datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select  spec_locality, geog_auth_rec_id from locality
			where locality_id=#locality_id#
		</cfquery>
		<cfquery name="getGeo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select higher_geog from geog_auth_rec where
			geog_auth_rec_id=#getLoc.geog_auth_rec_id#
		</cfquery>

		
		<cfquery name="localityMedia"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						media_id 
					FROM 
						media_relations 
					WHERE 
						RELATED_PRIMARY_KEY=#one.locality_id# and
						MEDIA_RELATIONSHIP like '% locality'
		</cfquery>
		<cfif len(one.spec_locality) gt 0>
		<cfif localityMedia.recordcount gt 0>
			<a class="infoLink" target="_blank" href="/MediaSearch.cfm?action=search&media_id=#valuelist(localityMedia.media_id)#">Media</a>
		</cfif>
		</cfif>
		<div class="card-body">
			<ul class="list-unstyled row px-3 py-1 mb-0">
				<cfif len(one.continent_ocean) gt 0>
					<li class="list-group-item col-6"><em>Continent Ocean:</em></li>
					<li class="list-group-item col-6">#one.continent_ocean#</li>
				</cfif>
				<cfif len(one.sea) gt 0>
					<li class="list-group-item col-6"><em>Sea:</em></li>
					<li class="list-group-item col-6">#one.sea#</li>
				</cfif>
				<cfif len(one.country) gt 0>
					<li class="list-group-item col-6"><em>Country:</em></li>
					<li class="list-group-item col-6">#one.country#</li>
				</cfif>
				<cfif len(one.state_prov) gt 0>
					<li class="list-group-item col-6"><em>State:</em></li>
					<li class="list-group-item col-6">#one.state_prov#</li>
				</cfif>
				<cfif len(one.feature) gt 0>
					<li class="list-group-item col-6"><em>Feature:</em></li>
					<li class="list-group-item col-6">#one.feature#</li>
				</cfif>
				<cfif len(one.county) gt 0>
					<li class="list-group-item col-6"><em>County:</em></li>
					<li class="list-group-item col-6">#one.county#</li>
				</cfif>
				<cfif len(one.island_group) gt 0>
					<li class="list-group-item col-6"><em>Island Group:</em></li>
					<li class="list-group-item col-6">#one.island_group#</li>
				</cfif>
				<cfif len(one.island) gt 0>
					<li class="list-group-item col-6"><em>Island:</em></li>
					<li class="list-group-item col-6">#one.island#</li>
				</cfif>
				<cfif len(one.quad) gt 0>
					<li class="list-group-item col-6"><em>Quad:</em></li>
					<li class="list-group-item col-6">#one.quad#</li>
				</cfif>
				<cfif len(one.spec_locality) gt 0>
					<li class="list-group-item col-6"><em>Specific Locality:</em></li>
					<li class="list-group-item col-6 last">#one.spec_locality#</li>
				</cfif>
			</ul>
		</div>
	</div>
<!------------------------------------ collecting event ----------------------------------->
	<div class="card">
		<div class="card-header">
			<h3 class="h4">Collecting Event</h3>
			<button type="button" class="popperbtn detail-edit-cell float-right py-0 px-2 fs-14 border-dk-gray rounded" onClick="$('##dialog-form').dialog('open'); setupNewLocality(#locality_id#);">Edit</button>
			
		</div>
		<div class="card-body">
			<ul class="list-unstyled row px-3 py-1 mb-0">
				<cfif len(one.sea) gt 0>
					<li class="list-group-item col-6"><em>Collectors:</em></li>
					<li class="list-group-item col-6">John Smith</li>
				</cfif>
				<cfif len(one.verbatim_locality) gt 0>
					<li class="list-group-item col-6"><em>Verbatim Locality:</em></li>
					<li class="list-group-item col-6">#one.verbatim_locality#</li>
				</cfif>
				<cfif len(one.collecting_source) gt 0>
					<li class="list-group-item col-6"><em>Collecting Source:</em></li>
					<li class="list-group-item col-6">#one.collecting_source#</li>
				</cfif>
				<cfif len(one.began_date) gt 0>
					<li class="list-group-item col-6"><em>Began Date:</em></li>
					<li class="list-group-item col-6">#one.began_date#</li>
				</cfif>
				<cfif len(one.ended_date) gt 0>
					<li class="list-group-item col-6"><em>Ended Date:</em></li>
					<li class="list-group-item col-6">#one.ended_date#</li>
				</cfif>
				<cfif len(one.verbatim_date) gt 0>
					<li class="list-group-item col-6"><em>Verbatim Date:</em></li>
					<li class="list-group-item col-6">#one.verbatim_date#</li>
				</cfif>
				<cfif len(one.verbatimcoordinates) gt 0>
					<li class="list-group-item col-6"><em>Verbatim Coordinates:</em></li>
					<li class="list-group-item col-6">#one.verbatimcoordinatesp#</li>
				</cfif>
				<cfif len(one.collecting_method) gt 0>
					<li class="list-group-item col-6"><em>Collecting Method:</em></li>
					<li class="list-group-item col-6">#one.collecting_method#</li>
				</cfif>
				<cfif len(one.coll_event_remarks) gt 0>
					<li class="list-group-item col-6"><em>Collecting Event Remarks:</em></li>
					<li class="list-group-item col-6">#one.coll_event_remarks#</li>
				</cfif>
				<cfif len(one.habitat_desc) gt 0>
					<li class="list-group-item col-6"><em>Habitat Description:</em></li>
					<li class="list-group-item col-6">#one.habitat_desc#</li>
				</cfif>
				<cfif len(one.collecting_event_id) gt 0>
				<!---<li class="list-group-item col-6"><em>Collecting Event ID:</em></li>
				<li class="list-group-item col-6">#one.collecting_event_id#</li>--->
				</cfif>
				<cfif len(one.habitat) gt 0>
					<li class="list-group-item col-6"><em>Microhabitat:</em></li>
					<li class="list-group-item col-6">#one.habitat#</li>
				</cfif>
			</ul>
		</div>
	</div>
<!------------------------------------ citations ------------------------------------------>
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
			c.collection_object_id = #collection_object_id# 
		ORDER by substr(formatted_publication, -4)
	</cfquery>
	<cfif len(citations.cited_name) gt 0>
		<div class="card" style="column-fill:auto">
			<div class="card-header">
				<h3 class="h4">Citations</h3>
				<button type="button" class="popperbtn detail-edit-cell float-right py-0 px-2 fs-14 border-dk-gray rounded" onClick="$('##dialog-form').dialog('open'); setupNewLocality(#locality_id#);">Edit</button>
			</div>
			<ul class="list-group">
				<cfloop query="citations">
					<li class="list-group-item"> <a href="/SpecimenUsage.cfm?action=search&publication_id=#publication_id#"
								target="_mainFrame"> #formatted_publication#</a>,
						<cfif len(occurs_page_number) gt 0>
							Page
							<cfif len(citation_page_uri) gt 0>
								<a href ="#citation_page_uri#" target="_blank">#occurs_page_number#</a>,
								<cfelse>
								#occurs_page_number#,
							</cfif>
						</cfif>
						#type_status# of <a href="/TaxonomyDetails.cfm?taxon_name_id=#cited_name_id#" target="_mainFrame"><i>#replace(cited_name," ","&nbsp;","all")#</i></a>
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
						#CITATION_REMARKS# </li>
				</cfloop>
				<cfif publicationMedia.recordcount gt 0>
					<cfloop query="publicationMedia">
						<li class="list-group-item"> 

							<!---<cfset puri=getMediaPreview(preview_uri,media_type)>--->
							<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select
											media_label,
											label_value
									from
											media_labels
									where
											media_id=#media_id#
						</cfquery>
							<cfquery name="desc" dbtype="query">
							select label_value from labels where media_label='description'
						</cfquery>
							<cfset alt="Media Preview Image">
							<cfif desc.recordcount is 1>
								<cfset alt=desc.label_value>
							</cfif>
							<img src="http://www.archive.org/download/proceedingsofnew04newe/page/n22_w392" width="70" height="100" style="float: left;margin: 0 8px 8px 0"> 
							<!--- <a href="#media_uri#" target="_blank"><img src="#getMediaPreview(preview_uri,media_type)#" alt="#alt#" class="theThumbSmall"></a>---> 
							<span style="font-size: .9em;line-height: .95em;">#media_type# (#mime_type#) <a href="/media/#media_id#" target="_blank">Media Details</a> #alt# </span> </li>
					</cfloop>
				</cfif>
			</ul>
		</div>
	</cfif>
<!------------------------------------ other identifiers ---------------------------------->
	<cfquery name="oid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT
			case when #oneOfUs# != 1 and
				concatencumbrances(coll_obj_other_id_num.collection_object_id) like '%mask original field number%' and
				coll_obj_other_id_num.other_id_type = 'original identifier'
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
		<div class="card">
			<div class="card-header">
				<h3 class="h4">Other IDs</h4>
				<button type="button" class="popperbtn detail-edit-cell float-right py-0 px-2 fs-14 border-dk-gray rounded" onClick="$('##dialog-form').dialog('open'); setupNewLocality(#locality_id#);">Edit</button>
			</div>
			<div class="card-body">
				<ul class="list-group">
					<cfloop query="oid">
						<li class="list-group-item">#other_id_type#:
							<cfif len(link) gt 0>
								<a class="external" href="#link#" target="_blank">#display_value#</a>
								<cfelse>
								#display_value#
							</cfif>
						</li>
					</cfloop>
				</ul>
			</div>
		</div>
	</cfif>
<!------------------------------------ tranactions ---------------------------------------->
	<cfquery name="accnMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			media_relations.related_primary_key=#one.accn_id#
	</cfquery>
	<cfif oneOfUs is 1 and vpdaccn is 1>
			<div class="card">
				<div class="card-header">
					<h3 class="h4">Transactions</h3>
					<button type="button" class="popperbtn detail-edit-cell float-right py-0 px-2 fs-14 border-dk-gray rounded" onClick="$('##dialog-form').dialog('open'); setupNewLocality(#locality_id#);">Edit</button>
				</div>
				<ul class="list-group list-group-flush" style="padding-left: 5px;">
					<li class="list-group-item">Accession:
						<cfif oneOfUs is 1>
							<a href="/editAccn.cfm?Action=edit&transaction_id=#one.accn_id#" target="_blank">#accession#</a>
							<cfelse>
							#accession#
						</cfif>
						<cfif accnMedia.recordcount gt 0>
							<cfloop query="accnMedia">
								<p> #media_type# (#mime_type#) <br>
									<a href="/media/#media_id#" target="_blank">Media Details</a> <br>
									#descr# </p>
							</cfloop>
						</cfif>
					</li>

<!--------------------  Project / Usage ------------------------------------>

		<cfquery name="isProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT project_name, project.project_id project_id FROM
			project, project_trans
			WHERE
			project_trans.project_id = project.project_id AND
			project_trans.transaction_id=#one.accn_id#
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
				specimen_part.derived_from_cat_item = #one.collection_object_id# AND
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
		<cfif isProj.recordcount gt 0 OR isLoan.recordcount gt 0 or
			(oneOfUs is 1 and isLoanedItem.collection_object_id gt 0) or
			(oneOfUs is 1 and isDeaccessionedItem.collection_object_id gt 0)>
			<cfloop query="isProj">
				<li class="list-group-item"> Contributed By Project:<a href="/ProjectDetail.cfm?src=proj&project_id=#isProj.project_id#">#isProj.project_name#</a> </li>
			</cfloop>
			<cfloop query="isLoan">
				<li class="list-group-item"> Used By Project: <a href="/ProjectDetail.cfm?src=proj&project_id=#isLoan.project_id#" target="_mainFrame">#isLoan.project_name#</a> </li>
			</cfloop>
			<cfif isLoanedItem.collection_object_id gt 0 and oneOfUs is 1>
				<li class="list-group-item">
					<h6>Loan History:</h6>
					<a href="/Loan.cfm?action=listLoans&collection_object_id=#valuelist(isLoanedItem.collection_object_id)#"
							target="_mainFrame">Loans that include this cataloged item (#loanList.recordcount#).</a>
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
						<cfloop query="loanList">
							<ul>
								<li>#loanList.loan_number# (#loanList.loan_type# #loanList.loan_status#)</li>
							</ul>
						</cfloop>
					</cfif>
				</li>
			</cfif>
			<cfif isDeaccessionedItem.collection_object_id gt 0 and oneOfUs is 1>
				<li class="list-group-item">
					<h6>Deaccessions: </h6>
					<a href="/Deaccession.cfm?action=listDeacc&collection_object_id=#valuelist(isDeaccessionedItem.collection_object_id)#"
							target="_mainFrame">Deaccessions that include this cataloged item (#deaccessionList.recordcount#).</a> &nbsp;
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
						<cfloop query="deaccessionList">
							<ul>
								<li> <a href="/Deaccession.cfm?action=editDeacc&transaction_id=#deaccessionList.transaction_id#">#deaccessionList.deacc_number# (#deaccessionList.deacc_type#)</a></li>
							</ul>
						</cfloop>
					</cfif>
				</li>
			</cfif>
		</cfif>
	</ul>
</div>
</cfif>
<!------------------------------------ relationships  ------------------------------------->
	<cfif len(relns.biol_indiv_relationship) gt 0 >
		<div class="card">
			<div class="card-header">
				<h3 class="h4">Relationship</h3>
				<button type="button" class="popperbtn detail-edit-cell float-right py-0 px-2 fs-14 border-dk-gray rounded" onClick="$('##dialog-form').dialog('open'); setupNewLocality(#locality_id#);">Edit</button>
			</div>
			<ul class="list-group list-group-flush" style="padding-left: 5px;">
				<li class="list-group-item">
					<cfloop query="relns">
						#biol_indiv_relationship# <a href="/SpecimenDetail.cfm?collection_object_id=#related_coll_object_id#" target="_top"> #related_collection# #related_cat_num# </a>
						<cfif len(relns.biol_indiv_relation_remarks) gt 0>
							(Remark: #biol_indiv_relation_remarks#)
						</cfif>
					</cfloop>
					<cfif len(relns.biol_indiv_relationship) gt 0>
						<a href="/SpecimenResults.cfm?collection_object_id=#valuelist(relns.related_coll_object_id)#" target="_top">(Specimens List)</a>
					</cfif>
				</li>
			</ul>
		</div>
	</cfif>
<!------------------------------------ attributes ----------------------------------------->
	<cfif len(attribute.attribute_type) gt 0>
		<div class="card">
			<div class="card-header">
				<h3 class="h4">Attributes</h3>
				<button type="button" class="popperbtn detail-edit-cell float-right py-0 px-2 fs-14 border-dk-gray rounded" onClick="$('##dialog-form').dialog('open'); setupNewLocality(#locality_id#);">Edit</button>
			</div>
			<div class="card-body">
				<cfquery name="sex" dbtype="query">
					select * from attribute where attribute_type = 'sex'
			</cfquery>
				<ul class="list-group">
					<cfloop query="sex">
						<li class="list-group-item"> sex: #attribute_value#,
							<cfif len(attributeDeterminer) gt 0>
								<cfset determination = "#attributeDeterminer#">
								<cfif len(determined_date) gt 0>
									<cfset determination = '#determination#, #dateformat(determined_date,"yyyy-mm-dd")#'>
								</cfif>
								<cfif len(determination_method) gt 0>
									<cfset determination = '#determination#, #determination_method#'>
								</cfif>
								#determination#
							</cfif>
							<cfif len(attribute_remark) gt 0>
								, Remark: #attribute_remark#
							</cfif>
						</li>
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
							len(weight.attribute_units) gt 0>
							<!---semi-standard measurements --->
							<p style="margin-top: 1em;">Standard Measurements</p>
							<table class="table table-striped table-bordered table-hovered responsive">
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
								#determination#
							</cfif>
						</cfif>
						<cfelse>
						<cfquery name="theRest" dbtype="query">
						select * from attribute where attribute_type NOT IN ('sex')
				</cfquery>
					</cfif>
					<cfloop query="theRest">
						<li class="list-group-item">#attribute_type#: #attribute_value#
							<cfif len(attribute_units) gt 0>
								, #attribute_units#
							</cfif>
							<cfif len(attributeDeterminer) gt 0>
								<cfset determination = "&nbsp;&nbsp;#attributeDeterminer#">
								<cfif len(determined_date) gt 0>
									<cfset determination = '#determination#, #dateformat(determined_date,"yyyy-mm-dd")#'>
								</cfif>
								<cfif len(determination_method) gt 0>
									<cfset determination = '#determination#, #determination_method#'>
								</cfif>
								#determination#
							</cfif>
							<cfif len(attribute_remark) gt 0>
								, Remark: #attribute_remark#
							</cfif>
						</li>
					</cfloop>
				</ul>
			</div>
		</div>
	</cfif>
<!------------------------------------ parts ---------------------------------------------->
	<div class="card p-0">
		<div class="card-header pt-1 pl-4">
				<h3 class="h4">Parts</h3>
				<button type="button" class="popperbtn detail-edit-cell float-right py-0 px-2 fs-14 border-dk-gray rounded" onClick="$('##dialog-form').dialog('open'); setupNewLocality(#locality_id#);">Edit</button>
			</div>
			<div class="card-body p-0">
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
						part_name
			</cfquery>
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
			<cfquery name="mPart" dbtype="query">
				select * from parts where sampled_from_obj_id is null order by part_name
			</cfquery>
		<cfif oneofus is 1 or not Findnocase("mask parts", one.encumbranceDetail)>
			<cfif oneOfUs is 1>
				<!---  <span class="detailEditCell" onclick="window.parent.loadEditApp('editParts');">Edit</span>--->
			</cfif>
			<table class="table table-striped table-bordered table-hovered table-responsive-md table-responsive-sm mb-0">
				<tr>
					<th scope="col"><span class="innerDetailLabel">Part Name</span></th>
					<th scope="col"><span class="innerDetailLabel">Condition</span></th>
					<th scope="col"><span class="innerDetailLabel">Disposition</span></th>
					<th scope="col"><span class="innerDetailLabel">##</span></th>
					<cfif oneOfus is "1">
						<th scope="col"><span class="innerDetailLabel">Container Name</span></th>
					</cfif>
					<th scope="col"><span class="innerDetailLabel">Remarks</span></th>
				</tr>
				<cfloop query="mPart">
					<tr>
						<td class="inside">#part_name#</td>
						<td class="inside">#part_condition#</td>
						<td class="inside">#part_disposition#</td>
						<td class="inside">#lot_count#</td>
						<cfif oneOfus is 1>
							<td class="inside">#label#</td>
						</cfif>
						<td class="inside">#part_remarks#</td>
					</tr>
					<cfquery name="patt" dbtype="query">
						SELECT
							attribute_type,
							attribute_value,
							attribute_units,
							determined_date,
							attribute_remark,
							agent_name
						FROM
							rparts
						WHERE
							attribute_type is not null and
							part_id=#part_id#
						GROUP BY
							attribute_type,
							attribute_value,
							attribute_units,
							determined_date,
							attribute_remark,
							agent_name
					</cfquery>
					<cfif patt.recordcount gt 0>
						<tr>
							<td colspan="6"><cfloop query="patt">
									<div style="font-size: 12px;font-weight: 400;"> #attribute_type#=#attribute_value# &nbsp;&nbsp;&nbsp;&nbsp;
										<cfif len(attribute_units) gt 0>
											#attribute_units# &nbsp;&nbsp;&nbsp;&nbsp;
										</cfif>
										<cfif len(determined_date) gt 0>
											determined date=#dateformat(determined_date,"yyyy-mm-dd")# &nbsp;&nbsp;&nbsp;&nbsp;
										</cfif>
										<cfif len(agent_name) gt 0>
											determined by=#agent_name# &nbsp;&nbsp;&nbsp;&nbsp;
										</cfif>
										<cfif len(attribute_remark) gt 0>
											remark=#attribute_remark# &nbsp;&nbsp;&nbsp;&nbsp;
										</cfif>
									</div>
								</cfloop></td>
						</tr>
						<!---/cfloop--->
					</cfif>
					<cfquery name="sPart" dbtype="query">
								select * from parts where sampled_from_obj_id=#part_id#
							</cfquery>
					<cfloop query="sPart">
						<tr>
							<td><span>#part_name# subsample</span></td>
							<td>#part_condition#</td>
							<td>#part_disposition#</td>
							<td>#lot_count#</td>
							<cfif oneOfus is 1>
								<td>#label#</td>
							</cfif>
							<td>#part_remarks#</td>
						</tr>
					</cfloop>
				</cfloop>
			</table>
		</cfif>
		</div>
	</div>
<!------------------------------------ media ---------------------------------------------->
	<cfif len(citations.cited_name) gt 0>
		<cfquery name="mediaTag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT distinct
			media.media_id,
			media.media_uri,
			media.mime_type,
			media.media_type,
			media.preview_uri 
		FROM 
			media,
			tag 
		WHERE 
			media.media_id=tag.media_id and 
			tag.collection_object_id = #collection_object_id#
		</cfquery>
		<cfif mediaTag.recordcount gt 0>
			<div class="detailLabel">Tagged in Media </div>
			<cfloop query="mediaTag">
				<!---<cfset puri=getMediaPreview(preview_uri,media_type)>
			<span class="detailData">
				<a href="/showTAG.cfm?media_id=#media_id#" target="_blank"><img src="#puri#"></a>
			</span>--->
			</cfloop>
		</cfif>
		<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT distinct
				media.media_id,
				media.media_uri,
				media.mime_type,
				media.media_type,
				media.preview_uri,
				media_relations.media_relationship 
			FROM 
				media,
				media_relations,
				media_labels 
			WHERE 
				media.media_id=media_relations.media_id and 
				media.media_id=media_labels.media_id (+) and 
				media_relations.media_relationship like '%cataloged_item' and 
				media_relations.related_primary_key = <cfqueryparam value=#collection_object_id# CFSQLType="CF_SQL_DECIMAL" > 
				AND MCZBASE.is_media_encumbered(media.media_id) < 1
			ORDER BY media.media_type
		</cfquery>
		<cfif media.recordcount gt 0>
			<cfquery name="wrlCount" dbtype="query">
				SELECT * FROM media WHERE mime_type = 'model/vrml'
			</cfquery>
			<cfif wrlCount.recordcount gt 0>
				<br>
				<span class="innerDetailLabel">Note: CT scans with mime type "model/vrml" require an external plugin such as <a href="http://cic.nist.gov/vrml/cosmoplayer.html">Cosmo3d</a> or <a href="http://mediamachines.wordpress.com/flux-player-and-flux-studio/">Flux Player</a>. For Mac users, a standalone player such as <a href="http://meshlab.sourceforge.net/">MeshLab</a> will be required.</span>
			</cfif>
			<cfquery name="pdfCount" dbtype="query">
				SELECT * FROM media WHERE mime_type = 'application/pdf'
			</cfquery>
			<cfif pdfCount.recordcount gt 0>
				<br>
				<span class="innerDetailLabel">For best results, open PDF files in the most recent version of Adobe Reader.</span>
			</cfif>
			<cfif oneOfUs is 1>
			<cfquery name="hasConfirmedImageAttr"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					count(*) c 
				FROM 
					ctattribute_type 
				WHERE 
					attribute_type='image confirmed' and
					collection_cde='#one.collection_cde#'
			</cfquery>
				<!---   <span class="detailEditCell" onclick="window.parent.loadEditApp('MediaSearch');">Edit</span>--->
			<cfquery name="isConf"  dbtype="query">
				SELECT 
					count(*) c 
				FROM 
					attribute 
				WHERE 
					attribute_type='image confirmed'
			</cfquery>
				<CFIF isConf.c is "" and hasConfirmedImageAttr.c gt 0>
					<span class="infoLink"
					id="ala_image_confirm" onclick='windowOpener("/ALA_Imaging/confirmImage.cfm?collection_object_id=#collection_object_id#","alaWin","width=700,height=400, resizable,scrollbars,location,toolbar");'> Confirm Image IDs </span>
				</CFIF>
			</cfif>

			<!---"thumbs"--->
			<div class="card  card-primary bg-light text-left">
				<div class="card-header">
					<h3 class="h4">Media</h3>
					<button type="button" class="popperbtn detail-edit-cell float-right py-0 px-2 fs-14 border-dk-gray rounded" onClick="$('##dialog-form').dialog('open'); setupNewLocality(#locality_id#);">Edit</button>
				</div>
				<ul class="list-group" style="display: inline;">
					<cfloop query="media">
						<!---<cfset puri=getMediaPreview(preview_uri,media_type)>--->
						<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								media_label,
								label_value 
							FROM 
								media_labels 
							WHERE 
								media_id=#media_id#
						</cfquery>
						<cfquery name="desc" dbtype="query">
							SELECT label_value FROM labels WHERE media_label='description'
						</cfquery>
						<cfset alt="Media Preview Image">
						<cfif desc.recordcount is 1>
							<cfset alt=desc.label_value>
						</cfif>
						<cfif media_type eq "image" and media.media_relationship eq "shows cataloged_item" and mime_type NEQ "text/html">
							<cfset one_thumb = "<div class='one_thumb_box'>">
							<cfset aForImHref = "/MediaSet.cfm?media_id=#media_id#">
							<cfset aForDetHref = "/MediaSet.cfm?media_id=#media_id#" >
							<cfelse>
							<cfset one_thumb = "<div class='one_thumb'>">
							<cfset aForImHref = media_uri>
							<cfset aForDetHref = "/media/#media_id#">
						</cfif>
					<li class="list-group-item thethumbs"> <a href="#media.media_uri#"><img src="#media.preview_uri#" width="100" height="68" class="float-left ml-0"></a> #one_thumb#
							<p> #media_type# (#mime_type#)<br>
								<a href="#aForDetHref#" target="_blank">Media Details</a> <br>
								#alt# 
							</p>
						</li>
					</cfloop>
				</ul>
			</div>
		</cfif>
	</cfif>
<!------------------------------------ metadata ------------------------------------------->
	<cfif oneofus is 1 or not Findnocase("mask parts", one.encumbranceDetail)>
		<cfif oneOfUs is 1>
			<div class="card">
				<div class="card-header">
					<h3 class="h4">Metadata</h4>
				</div>
				<div class="card-body">
					<ul>
						<cfif len(#one.coll_object_remarks#) gt 0>
							<li>Remarks: #one.coll_object_remarks# </li>
						</cfif>
						<li> Entered By: #one.EnteredBy# on #dateformat(one.coll_object_entered_date,"yyyy-mm-dd")# </li>
						<cfif #one.EditedBy# is not "unknown" OR len(#one.last_edit_date#) is not 0>
							<li> Last Edited By: #one.EditedBy# on #dateformat(one.last_edit_date,"yyyy-mm-dd")# </li>
						</cfif>
						<cfif len(#one.flags#) is not 0>
							<li> Missing (flags): #one.flags# </li>
						</cfif>
						<cfif len(#one.encumbranceDetail#) is not 0>
							<li> Encumbrances: #replace(one.encumbranceDetail,";","<br>","all")# </li>
						</cfif>
					</ul>
				</div>
			</div>
		</cfif>
	</cfif>
	</div>
<cfif oneOfUs is 1>
</form>
</cfif>
</div>
</cfoutput>
<cf_customizeIFrame>