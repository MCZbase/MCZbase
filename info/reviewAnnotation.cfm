<cfset pageTitle = "Review Annotations">
<cfinclude template="/shared/_header.cfm">
<cfif not isdefined("action")>
	<cfset action="">
</cfif>

<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select collection cln from collection order by collection
</cfquery>
<div class="container-fluid">
	<div class="row">
		<div class="col-12">
			<cfoutput>
				<h1 class="h2 mt-3">Annotation Review</h1>
				<div class="form-row">
					<div class="col-2">
						<h3 class="h4 text-right pr-3">Filter For: </h3>
					</div>
					<div class="col-12 col-md-3">
						<h3 class="h4">Specimens</h3>
						<form name="filter" method="get" action="reviewAnnotation.cfm">
							<input type="hidden" name="action" value="show">
							<input type="hidden" name="type" value="collection_object_id">
							<label for="collection">By Collection</label>
							<select name="collection" size="1" class="data-entry-select col-9">
								<option value=""></option>
								<cfloop query="c">
									<option value="#cln#">#cln#</option>
								</cfloop>
							</select>
							<input type="submit" class="btn btn-xs btn-secondary"	value="Filter">
							<input type="reset"  class="btn btn-xs btn-warning" value="Clear Filter">
						</form>
					</div>
					<div class="col-3">
						<h3 class="h4">The Rest</h3>
						<form name="filter" method="get" action="reviewAnnotation.cfm">
							<input type="hidden" name="action" value="show">
							<label for="type">By Type</label>
							<select name="type" size="1" class="col-9 data-entry-select">
								<option value=""></option>
								<option value="project_id">Project</option>
								<option value="publication_id">Publication</option>
								<option value="taxon_name_id">Taxonomy</option>
							</select>
							<input type="submit"  class="btn btn-xs btn-secondary" value="Filter">
							<input type="reset"  class="btn btn-xs btn-warning" value="Clear Filter">
						</form>
					</div>
				</div>
			</cfoutput>

<cfif action is "show">
	<cfoutput>
		<cfif type is "collection_object_id">
			<cfif isdefined("id") and len(id) gt 0>
				<cfset collection_object_id=id>
			</cfif>
			<cfquery name="ci" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					 annotations.ANNOTATION_ID,
					 annotations.ANNOTATE_DATE,
					 annotations.CF_USERNAME,
					 annotations.COLLECTION_OBJECT_ID,
					 annotations.annotation,	 
					 annotations.reviewer_agent_id,
					 preferred_agent_name.agent_name reviewer,
					 annotations.reviewed_fg,
					 annotations.reviewer_comment,
					 collection.collection,
					 cataloged_item.cat_num,
					 identification.scientific_name idAs,
					 geog_auth_rec.higher_geog,
					 locality.spec_locality,
					 cf_user_data.email
				FROM
					annotations,
					cataloged_item,
					collection,
					collecting_event,
					locality,
					geog_auth_rec,
					identification,
					cf_user_data,
					cf_users,
					preferred_agent_name
				WHERE
					annotations.COLLECTION_OBJECT_ID = cataloged_item.COLLECTION_OBJECT_ID AND
					annotations.reviewer_agent_id=preferred_agent_name.agent_id (+) and
					cataloged_item.collection_id = collection.collection_id AND
					cataloged_item.collection_object_id = identification.collection_object_id AND
					accepted_id_fg=1 AND
					cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
					collecting_event.locality_id = locality.locality_id AND
					locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id AND
					annotations.CF_USERNAME=cf_users.username (+) and
					cf_users.user_id = cf_user_data.user_id (+)
					<cfif isdefined("collection_object_id") and len(#collection_object_id#) gt 0>
						AND annotations.collection_object_id = #collection_object_id#
					</cfif>
					<cfif isdefined("collection") and len(#collection#) gt 0>
						AND collection.collection = '#collection#'
					</cfif>
			</cfquery>
			<cfquery name="catitem" dbtype="query">
				select
					COLLECTION_OBJECT_ID,
					collection,
					cat_num,
					idAs,
					higher_geog,
					spec_locality
				from 
					ci 
				group by
					COLLECTION_OBJECT_ID,
					collection,
					cat_num,
					idAs,
					higher_geog,
					spec_locality
			</cfquery>
			<h2 class="h3 mt-3 pl-1">Annotations</h2>
			<table class="table table-responsive">
				<cfset i=1>
				<cfloop query="catitem">
					<cfquery name="itemAnno" dbtype="query">
						select * from ci where collection_object_id = #collection_object_id#
					</cfquery>
					<tr>
						<td colspan="5">
							<h3 class="h5 mb-1 mt-2">
								<a href="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#">#collection# #cat_num#</a> 
								<span class="mr-3">ID: <em>#idAs#</em></span> 
								<span class="ml-1"> Locality: #higher_geog#: #spec_locality#</span>
							</h3>
						</td>
					</tr>
					<cfloop query="itemAnno">
						<tr><td><label class="data-entry-label">Annotation by</label><span class="small"> <strong>#CF_USERNAME#</strong> (#email#) on #dateformat(ANNOTATE_DATE,"yyyy-mm-dd")#</span></td>
							<td><span class="small">#annotation#</span></td>
							<form name="r" method="post" action="reviewAnnotation.cfm">
								<input type="hidden" name="action" value="saveReview">
								<input type="hidden" name="type" value="collection_object_id">
								<input type="hidden" name="id" value="#collection_object_id#">
								<input type="hidden" name="annotation_id" value="#annotation_id#">
								<td><label for="reviewed_fg" class="data-entry-label">Reviewed?</label>
									<select name="reviewed_fg" id="reviewed_fg" class="data-entry-select">
										<option value="0" <cfif reviewed_fg is 0>selected="selected"</cfif>>No</option>
										<option value="1" <cfif reviewed_fg is 1>selected="selected"</cfif>>Yes</option>
									</select>
									<cfif len(reviewer) gt 0>
										<span class="d-block small">
										Last review by #reviewer#</span>
									</cfif></td>
								<td><label for="reviewer_comment" class="data-entry-label">Review Comments</label>
									<textarea rows="3" class="" name="reviewer_comment" id="reviewer_comment">#reviewer_comment#</textarea></td>
								<td><input type="submit" value="save review" class="btn btn-xs btn-primary mt-3 mb-2"></td>
							</form>
						</tr>
					</cfloop>
					<cfset i=i+1>
				</cfloop>
			</table>
			<cfelseif type is "publication_id">
			<cfquery name="tax" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select 
					publication.publication_title,
					annotations.ANNOTATION_ID,
					annotations.ANNOTATE_DATE,
					annotations.CF_USERNAME,
					annotations.annotation,	 
					annotations.reviewer_agent_id,
					preferred_agent_name.agent_name reviewer,
					annotations.reviewed_fg,
					annotations.reviewer_comment,
					cf_user_data.email,
					annotations.publication_id
				FROM
					annotations,
					publication,
					cf_user_data,
					cf_users,
					preferred_agent_name
				WHERE
					annotations.publication_id = publication.publication_id AND
					annotations.reviewer_agent_id=preferred_agent_name.agent_id (+) and
					annotations.CF_USERNAME=cf_users.username (+) and
					cf_users.user_id = cf_user_data.user_id (+)
					<cfif isdefined("publication_id") and len(publication_id) gt 0>
						AND annotations.publication_id = #publication_id#
					</cfif>
			</cfquery>
			<cfquery name="t" dbtype="query">
				select
					publication_title,
					publication_id
				from 
					tax 
				group by
					publication_title,
					publication_id
			</cfquery>
			<h2 class="h3">Publication Annotations</h2>
			<table class="table table-responsive">
				<cfset i=1>
				<cfloop query="t">
					<tr>
						<td>
							<h5 class="my-1">
								<a href="/SpecimenUsage.cfm?publication_id=#publication_id#">#publication_title#</a>
							</h5>
							<cfquery name="itemAnno" dbtype="query">
								select * from tax where publication_id = #publication_id#
							</cfquery>
							<table class="table table-responsive">
								<tbody class="bg-light">
									<cfloop query="itemAnno">
										<tr>
											<td><label class="data-entry-label">Annotation by</label><span> <strong>#CF_USERNAME#</strong> (#email#) on #dateformat(ANNOTATE_DATE,"yyyy-mm-dd")#</span></td>
											<td><span>#annotation#</span></td>
											<form name="r" method="post" action="reviewAnnotation.cfm">
												<input type="hidden" name="action" value="saveReview">
												<input type="hidden" name="type" value="publication_id">
												<input type="hidden" name="id" value="#publication_id#">
												<input type="hidden" name="annotation_id" value="#annotation_id#" class="data-entry-input">
												<td>
													<label for="reviewed_fg" class="data-entry-label">Reviewed?</label>
													<select name="reviewed_fg" id="reviewed_fg" class="data-entry-select">
														<option value="0" <cfif reviewed_fg is 0>selected="selected"</cfif>>No</option>
														<option value="1" <cfif reviewed_fg is 1>selected="selected"</cfif>>Yes</option>
													</select>
													<cfif len(reviewer) gt 0>
														<span class="d-block">
														Last review by #reviewer#</span>
													</cfif>
												</td>
												<td>
													<label for="reviewer_comment" class="data-entry-label">Review Comments</label>
													<input type="text" name="reviewer_comment" id="reviewer_comment" value="#reviewer_comment#" class="data-entry-input">
												</td>
												<td>
													<input type="submit" value="save review" class="btn btn-xs mb-2 mt-3 btn-primary">
												</td>
											</form>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</td>
					</tr>
					<cfset i=#i#+1>
				</cfloop>
			</table>
			<cfelseif type is "taxon_name_id">
			<cfquery name="tax" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select 
					taxonomy.scientific_name, 
					taxonomy.display_name,
					annotations.ANNOTATION_ID,
					annotations.ANNOTATE_DATE,
					annotations.CF_USERNAME,
					annotations.annotation,	 
					annotations.reviewer_agent_id,
					preferred_agent_name.agent_name reviewer,
					annotations.reviewed_fg,
					annotations.reviewer_comment,
					cf_user_data.email,
					annotations.taxon_name_id
				FROM
					annotations,
					taxonomy,
					cf_user_data,
					cf_users,
					preferred_agent_name
				WHERE
					annotations.taxon_name_id = taxonomy.taxon_name_id AND
					annotations.reviewer_agent_id=preferred_agent_name.agent_id (+) and
					annotations.CF_USERNAME=cf_users.username (+) and
					cf_users.user_id = cf_user_data.user_id (+)
					<cfif isdefined("taxon_name_id") and len(taxon_name_id) gt 0>
						AND annotations.taxon_name_id = #taxon_name_id#
					</cfif>
			</cfquery>
			<cfquery name="t" dbtype="query">
				select
					scientific_name,
					display_name
				from 
					tax 
				group by
					scientific_name,
					display_name
			</cfquery>
			<h2 class="h3">Taxonomic Annotations</h2>
			<table class="table table-responsive">
				<cfset i=1>
				<cfloop query="t">
					<tr>
						<td>
							<h4 class="mt-1"><a href="/name/#scientific_name#">#display_name#</a></h4>
							<cfquery name="itemAnno" dbtype="query">
							select * from tax where scientific_name = '#scientific_name#'
							</cfquery>
							<table class="table table-responsive">
								<tbody class="bg-light">
									<cfloop query="itemAnno">
										<tr>
											<td><label class="data-entry-label px-0">Annotation by</label> <span><strong>#CF_USERNAME#</strong> (#email#) on #dateformat(ANNOTATE_DATE,"yyyy-mm-dd")#</span></td>
											<td><span>#annotation#</span></td>
											<form name="r" method="post" action="reviewAnnotation.cfm">
												<input type="hidden" name="action" value="saveReview">
												<input type="hidden" name="type" value="taxon_name_id">
												<input type="hidden" name="id" value="#taxon_name_id#">
												<input type="hidden" name="annotation_id" value="#annotation_id#">
												<td><label for="reviewed_fg" class="data-entry-label">Reviewed?</label>
													<select name="reviewed_fg" id="reviewed_fg" class="data-entry-select">
														<option value="0" <cfif reviewed_fg is 0>selected="selected"</cfif>>No</option>
														<option value="1" <cfif reviewed_fg is 1>selected="selected"</cfif>>Yes</option>
													</select>
													<cfif len(reviewer) gt 0>
														<span class="d-block">
														Last review by #reviewer#</span>
													</cfif></td>
												<td><label for="reviewer_comment" class="data-entry-label">Review Comments</label>
													<input type="text" name="reviewer_comment" id="reviewer_comment" value="#reviewer_comment#" class="data-entry-input"></td>
												<td><input type="submit" value="save review" class="btn mt-3 mb-2 btn-xs btn-primary"></td>
											</form>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</td>
					</tr>
					<cfset i=#i#+1>
				</cfloop>
			</table>
			<cfelseif type is "project_id">
			<cfquery name="tax" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 
				project.project_name,
				annotations.ANNOTATION_ID,
				annotations.ANNOTATE_DATE,
				annotations.CF_USERNAME,
				annotations.annotation,	 
				annotations.reviewer_agent_id,
				preferred_agent_name.agent_name reviewer,
				annotations.reviewed_fg,
				annotations.reviewer_comment,
				cf_user_data.email,
				annotations.project_id
			FROM
				annotations,
				project,
				cf_user_data,
				cf_users,
				preferred_agent_name
			WHERE
				annotations.project_id = project.project_id AND
				annotations.reviewer_agent_id=preferred_agent_name.agent_id (+) and
				annotations.CF_USERNAME=cf_users.username (+) and
				cf_users.user_id = cf_user_data.user_id (+)
				<cfif isdefined("project_id") and len(project_id) gt 0>
					AND annotations.project_id = #project_id#
				</cfif>
		</cfquery>
			<cfquery name="t" dbtype="query">
			select
				project_name,
				project_id
			from 
				tax 
			group by
				project_name,
				project_id
		</cfquery>
			<h2 class="h4">Project Annotations</h2>
			<table class="table border table-responsive table-striped">
				<cfset i=1>
				<cfloop query="t">
					<tr>
						<td><a href="/ProjectDetail?project_id=#project_id#">#project_name#</a>
							<cfquery name="itemAnno" dbtype="query">
							select * from tax where project_id = #project_id#
						</cfquery>
							<table class="table border table-responsive">
								<cfloop query="itemAnno">
									<tr>
										<td><label class="data-entry-label">Annotation by</label><span> <strong>#CF_USERNAME#</strong> (#email#) on #dateformat(ANNOTATE_DATE,"yyyy-mm-dd")#</span></td>
										<td class="col-4"><span>#annotation#</span></td>
										<form name="r" method="post" action="reviewAnnotation.cfm">
											<input type="hidden" name="action" value="saveReview">
											<input type="hidden" name="type" value="project_id">
											<input type="hidden" name="id" value="#project_id#">
											<input type="hidden" name="annotation_id" value="#annotation_id#">
											<td><label for="reviewed_fg" class="data-entry-label">Reviewed?</label>
												<select name="reviewed_fg" id="reviewed_fg" class="data-entry-select">
													<option value="0" <cfif reviewed_fg is 0>selected="selected"</cfif>>No</option>
													<option value="1" <cfif reviewed_fg is 1>selected="selected"</cfif>>Yes</option>
												</select>
												<cfif len(reviewer) gt 0>
													<span class="d-block">
													Last review by #reviewer#</span>
												</cfif></td>
											<td><label for="reviewer_comment" class="data-entry-label">Review Comments</label>
												<input type="text" name="reviewer_comment" id="reviewer_comment" value="#reviewer_comment#" class="data-entry-input"></td>
											<td><input type="submit" value="save review" class="btn mt-3 mb-2 btn-primary btn-xs"></td>
										</form>
									</tr>
								</cfloop>
							</table></td>
					</tr>
					<cfset i=#i#+1>
				</cfloop>
			</table>
			<cfelse>
			fail.
		</cfif>
		<!--- end collection_object_id ---> 
	</cfoutput>
</cfif>

<cfif action is "saveReview">
	<cfoutput>
		<cfquery name="annotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update annotations set
				REVIEWER_AGENT_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
				REVIEWED_FG=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#REVIEWED_FG#">,
				REVIEWER_COMMENT=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#(REVIEWER_COMMENT)#">
			where
				annotation_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#annotation_id#">
		</cfquery>
		<cflocation url="reviewAnnotation.cfm?action=show&type=#type#&id=#id#" addtoken="false">
	</cfoutput>
</cfif>

		</div>
	</div>
</div>
<cfinclude template="/shared/_footer.cfm">
