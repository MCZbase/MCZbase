<!---
specimens/component/public.cfc

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
<!--- publicly available functions to support /specimens/Specimen.cfm --->
<cfcomponent>
<cf_rolecheck>
<cfinclude template = "/shared/functionLib.cfm" runOnce="true">

<!--- getIdentificationsHTML obtain a block of html listing identifications for a cataloged item
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the identifications.
 @return html for viewing identifications for the specified cataloged item. 
--->
<cffunction name="getIdentificationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getIdentificationsThread">
		<cfoutput>
			<cftry>
				<cfquery name="identification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						identification.scientific_name,
						identification.collection_object_id,
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
						identification.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
					ORDER BY accepted_id_fg DESC,sort_order, made_date DESC
				</cfquery>
				<cfloop query="identification">
					<cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT distinct
							taxonomy.taxon_name_id,
							display_name,
							scientific_name,
							author_text,
							full_taxon_name 
						FROM 
							identification_taxonomy,
							taxonomy
						WHERE 
							identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id 
							AND identification_id = <cfqueryparam value="#identification_id#" cfsqltype="CF_SQL_DECIMAL">
					</cfquery>
					<cfif accepted_id_fg is 1>
						<ul class="list-group border-green rounded p-2 h4 font-weight-normal">
							<div class="d-inline-block mb-2 h4 text-success">Current Identification</div>
							<cfif getTaxa.recordcount is 1 and taxa_formula is 'a'>
								<div class="font-italic h4 mb-1 font-weight-lessbold d-inline-block"> <a href="/name/#getTaxa.scientific_name#" target="_blank">#getTaxa.display_name# </a>
								<cfif len(getTaxa.author_text) gt 0>
									<span class="sm-caps font-weight-lessbold">#getTaxa.author_text#</span>
								</cfif>
								</div>
								<cfelse>
								<cfset link="">
								<cfset i=1>
								<cfset thisSciName="#scientific_name#">
								<cfloop query="getTaxa">
									<span class="font-italic h4 font-weight-lessbold d-inline-block">
									<cfset thisLink='<a href="/name/#scientific_name#" class="d-inline" target="_blank">#display_name#</a>'>
									<cfset thisSciName=#replace(thisSciName,scientific_name,thisLink)#>
									<cfset i=#i#+1>
									<a href="##">#thisSciName#</a> <span class="sm-caps font-weight-lessbold">#getTaxa.author_text#</span> </span>
								</cfloop>
							</cfif>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<cfif stored_as_fg is 1>
									<span class="bg-gray float-right rounded p-1">STORED AS</span>
								</cfif>
							</cfif>
							<cfif not isdefined("metaDesc")>
								<cfset metaDesc="">
							</cfif>
							<cfloop query="getTaxa">
								<div class="h5 mb-1 text-dark font-italic"> #full_taxon_name# </div>
								<cfset metaDesc=metaDesc & '; ' & full_taxon_name>
								<cfquery name="cName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										common_name 
									FROM 
										common_name
									WHERE 
										taxon_name_id= <cfqueryparam value="#taxon_name_id#" cfsqltype="CF_SQL_DECIMAL"> 
										and common_name is not null
									GROUP BY 
										common_name order by common_name
								</cfquery>
								<cfif len(cName.common_name) gt 0><div class="h5 mb-1 text-muted font-weight-normal pl-3">Common Name(s): #valuelist(cName.common_name,"; ")# </div></cfif>
								<cfset metaDesc=metaDesc & '; ' & valuelist(cName.common_name,"; ")><!---  common name for current id--->
							</cfloop>
							<div class="form-row mx-0">
								<div class="small mr-2"><span class="h5">Determiner:</span> #agent_name#
									<cfif len(made_date) gt 0>
										<span class="h5">on Date:</span> #dateformat(made_date,"yyyy-mm-dd")#
									</cfif>
								</div>
							</div>
							<div class="small mr-2"><span class="h5">Nature of ID:</span> #nature_of_id# </div>
							<cfif len(identification_remarks) gt 0>
								<div class="small"><span class="h5">Remarks:</span> #identification_remarks#</div>
							</cfif>
						</ul>	
						<cfelse><!---Start of former Identifications--->
							<cfif getTaxa.recordcount gt 0>		
								<div class="h4 pl-4 mt-1 mb-0 text-success">Former Identifications</div>
							</cfif><!---Add Title for former identifications--->
						<ul class="list-group py-1 px-3 ml-2 text-dark bg-light">
						<li class="px-0">
						<cfif getTaxa.recordcount is 1 and taxa_formula is 'a'>
							<span class="font-italic h4 font-weight-normal"><a href="/name/#getTaxa.scientific_name#" target="_blank">#getTaxa.display_name#</a></span><!---identification  for former names when there is no author--->
							<cfif len(getTaxa.author_text) gt 0>
								<span class="color-black sm-caps">#getTaxa.author_text#</span><!---author text for former names--->
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
							#thisSciName# <!---identification for former names when there is an author--it put the sci name with the author--->
						</cfif>
						<cfif listcontainsnocase(session.roles,"manage_specimens")>
							<cfif stored_as_fg is 1>
								<span style="float-right rounded p-1 bg-light">STORED AS</span>
							</cfif>
						</cfif>
						<cfif not isdefined("metaDesc")>
							<cfset metaDesc="">
						</cfif>
						<cfloop query="getTaxa">
							<!--- TODO: We loop through getTaxa results three times, and query for common names twice?????  Construction here needs review.  --->
							<p class="small text-muted mb-0"> #full_taxon_name#</p><!--- full taxon name for former id--->
							<cfset metaDesc=metaDesc & '; ' & full_taxon_name>
							<cfquery name="cName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										common_name 
									FROM 
										common_name
									WHERE 
										taxon_name_id= <cfqueryparam value="#taxon_name_id#" cfsqltype="CF_SQL_DECIMAL"> 
										and common_name is not null
									GROUP BY 
										common_name order by common_name
							</cfquery>
							<cfif len(cName.common_name) gt 0><div class="small text-muted pl-3">Common Name(s): #valuelist(cName.common_name,"; ")#</div>
							<cfset metaDesc=metaDesc & '; ' & valuelist(cName.common_name,"; ")></cfif><!---  common name for former id--->
						</cfloop>
						<cfif len(formatted_publication) gt 0>
							sensu <a href="/publication/#publication_id#" target="_mainFrame"> #formatted_publication# </a><!---  Don't think this is used--->
						</cfif>
						<span class="small">Determination: #agent_name#
							<cfif len(made_date) gt 0>
								on #dateformat(made_date,"yyyy-mm-dd")#
							</cfif>
							<span class="d-block">Nature of ID: #nature_of_id#</span> 
						<cfif len(identification_remarks) gt 0>
							<span class="d-block">Remarks: #identification_remarks#</span>
						</cfif>
					</cfif>
					</li>
					</ul>
				</cfloop>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>

	<cfthread action="join" name="getIdentificationsThread" />
	<cfreturn getIdentificationsThread.output>
</cffunction>

<!--- getOtherIdsHTML obtain a block of html listing other id numbers for a cataloged item
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the other id numbers
 @return html for viewing identifications for the specified cataloged item. 
--->
<cffunction name="getOtherIDsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getOtherIDsThread">
		<cfoutput>
			<cftry>
			<cfquery name="oid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						case when concatencumbrances(coll_obj_other_id_num.collection_object_id) like '%mask original field number%' and
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
						coll_obj_other_id_num 
						left join ctcoll_other_id_type on coll_obj_other_id_num.other_id_type=ctcoll_other_id_type.other_id_type
					where
						collection_object_id= <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
					ORDER BY
						other_id_type,
						display_value
				</cfquery>
		<cfif len(oid.other_id_type) gt 0>

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
				
				</cfif>
							<cfcatch>
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>

	<cfthread action="join" name="getOtherIDsThread" />
	<cfreturn getOtherIDsThread.output>
</cffunction>

<cffunction name="getCitationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getCitationsThread">
		<cfoutput>
			<cftry>
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
                      <cfset i = 1>
                        <cfloop query="citations" group="formatted_publication">
                            <div class="d-block py-1 px-2 w-100 float-left"><span class="d-inline"> </span><a href="/SpecimenUsage.cfm?action=search&publication_id=#publication_id#"
                            target="_mainFrame">#formatted_publication#</a>,
                                <cfif len(occurs_page_number) gt 0>
                                    Page
                                    <cfif len(citation_page_uri) gt 0>
                                        <a href ="#citation_page_uri#" target="_blank">#occurs_page_number#</a>,
                                        <cfelse>
                                        #occurs_page_number#,
                                    </cfif>
                                </cfif>
                                    <span class="font-weight-lessbold">#type_status#</span> of <a href="/TaxonomyDetails.cfm?taxon_name_id=#cited_name_id#" target="_mainFrame"><i>#replace(cited_name," ","&nbsp;","all")#</i></a>
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
                                    <span class="small font-italic"> <cfif len(citation_remarks) gt 0>-</cfif> #CITATION_REMARKS#</span>
                            </div>
                            <cfset i = i + 1>
                        </cfloop>
                        <cfif publicationMedia.recordcount gt 0>
                            <cfloop query="publicationMedia">
                                <cfset puri=getMediaPreview(preview_uri,mime_type)>	
                                <cfquery name="citationPub"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                                            select
                                                    media_label,
                                                    label_value
                                            from
                                                    media_labels
                                            where
                                                    media_id = <cfqueryparam value="#media_id#" cfsqltype="CF_SQL_DECIMAL">
                                </cfquery>
                                <cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                                            select
                                                    media_label,
                                                    label_value
                                            from
                                                    media_labels
                                            where
                                                    media_id = <cfqueryparam value="#media_id#" cfsqltype="CF_SQL_DECIMAL">
                                </cfquery>
                                <cfquery name="desc" dbtype="query">
                                    select 
                                        label_value 
                                    from 
                                        labels 
                                    where 
                                        media_label='description'
                                </cfquery>
                                <cfset alt="Media Preview Image">
                                <cfif desc.recordcount is 1>
                                    <cfset alt=desc.label_value>
                                </cfif>
                                <div class="col-2 m-2 float-left d-inline"> 
                                    <cfset mt = #mime_type#>
                                    <cfset muri = #media_uri#>
                                    <a href="#media_uri#" target="_blank">
                                        <img src="#getMediaPreview(preview_uri,mime_type)#" alt="#alt#" class="mx-auto w-100">
                                    </a>
                                    <span class="d-block smaller text-center" style="line-height:.7rem;">
                                        <a class="d-block" href="/media/#media_id#" target="_blank">Media Record</a>
                                    </span> 
                                </div>
                            </cfloop>		
                        </cfif>
                <cfcatch>
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>

	<cfthread action="join" name="getCitationsThread" />
	<cfreturn getCitationsThread.output>
</cffunction>                
                    
<cffunction name="getPartsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getPartsThread">
		<cfoutput>
			<cftry>
<cfoutput>
					<cfif not Findnocase("mask parts", one.encumbranceDetail)>
						<cfquery name="rparts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select
									specimen_part.collection_object_id part_id,
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
										part_name,
										sampled_from_obj_id,
										part_disposition,
										part_condition,
										lot_count,
										part_remarks
								order by
										part_name
						</cfquery>
						<cfquery name="parts" dbtype="query">
                                select  
                                        part_id,
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
						<div class="accordion w-100" id="accordionForParts">
							<div class="card mb-2">
								<div class="card-header float-left w-100" id="headingPart">
									<h3 class="h4 my-0 float-left"><a class="btn-link" role="button" data-toggle="collapse" data-target="##collapseParts"> Parts </a> <span class="text-success small ml-4">(count: #ctPart.ct# parts)</span></h3>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<button type="button" class="btn btn-xs float-right small" onClick="$('##dialog-form').dialog('open'); setupNewLocality(#locality_id#);">Edit</button>
									</cfif>
								</div>
								<div class="card-body p-0">
									<div id="collapseParts" class="collapse show" aria-labelledby="headingPart" data-parent="##accordionForParts">
										<table class="table border-bottom mb-0">
											<thead>
												<tr class="bg-light">
													<th><span>Part Name</span></th>
													<th><span>Condition</span></th>
													<th><span>Disposition</span></th>
													<th><span>##</span></th>
													<th><cfif oneOfus is "1">
														<span>Container</span>
													</cfif>
													</th>
													
												</tr>
											</thead>
											<tbody>
												<cfset i=1>
												<cfloop query="mPart">
													<tr <cfif mPart.recordcount gt 1>class=""<cfelse></cfif>>
														<td><span class="">#part_name#</span></td>
														<td>#part_condition#</td>
														<td>#part_disposition#</td>
														<td>#lot_count#</td>
														<td><cfif oneOfus is 1>#label#</cfif></td>
													</tr>
													<cfif len(part_remarks) gt 0>
														<tr class="small">
															<td colspan="5"><span class="pl-3 d-block"><span class="font-italic">Remarks:</span> #part_remarks#</span></td>
														</tr>
													</cfif>
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
															part_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
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
															<td colspan="5">
																<cfloop query="patt">
																	<div class="small pl-3" style="line-height: .9rem;"> #attribute_type#=#attribute_value#
																		<cfif len(attribute_units) gt 0>
																			#attribute_units#
																		</cfif>
																		<cfif len(determined_date) gt 0>
																			determined date=<strong>#dateformat(determined_date,"yyyy-mm-dd")#
																		</cfif>
																		<cfif len(agent_name) gt 0>
																			determined by=#agent_name#
																		</cfif>
																		<cfif len(attribute_remark) gt 0>
																			remark=#attribute_remark#
																		</cfif>
																	</div>
																</cfloop>
															</td>
														</tr>
													</cfif>
													<!---/cfloop--->
													<cfquery name="sPart" dbtype="query">
														select * from parts 
														where sampled_from_obj_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
													</cfquery>
													<cfloop query="sPart">
														<tr>
															<td><span class="d-inline-block pl-3">#part_name# <span class="font-italic">subsample</span></span></td>
															<td>#part_condition#</td>
															<td>#part_disposition#</td>
															<td>#lot_count#</td>
															
															<td><cfif oneOfus is 1>#label#</cfif></td>
													
														
														</tr>
														<cfif len(part_remarks) gt 0>
														<tr class="small">
															<td colspan="5"><span class="pl-3 d-block"><span class="font-italic">Remarks:</span> #part_remarks#</span></td>
														</tr>
													</cfif>
													</cfloop>
												</cfloop>
											</tbody>
										</table>
									</div>
								</div>
							</div>
						</div>
					</cfif>
				</cfoutput> 

                <cfcatch>
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>

	<cfthread action="join" name="getPartsThread" />
	<cfreturn getPartsThread.output>
</cffunction>  
                    
                    
                    
</cfcomponent>
