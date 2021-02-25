<cfset pageTitle = "Named Group">
<cfinclude template="/shared/_header.cfm">
<cfset collection_object_id = "5243961">
	<cfoutput>
<cfquery name="namedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select underscore_collection.collection_name, underscore_relation.collection_object_id
from underscore_collection, underscore_relation 
where underscore_relation.UNDERSCORE_collection_ID = underscore_collection.UNDERSCORE_COLLECTION_ID
and underscore_relation.collection_object_id = 5243961
</cfquery>

<main class="container py-3">

	
	<div class="row">
	 	<div class="col-12">
			<h1>#namedGroup.collection_name#</h1>
			<div class="col-5 border float-left">
				<div class="card-body">
							<!------------------------------------ media ----------------------------------------------> 
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
			</div>
			<div class="col-7 border float-left">Description</div>
		</div>
	</div>
</main><!--- class="container" --->
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
