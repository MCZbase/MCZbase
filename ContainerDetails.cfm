<cfif not isdefined("container_id")>
	<cfabort><!--- need an ID to do anything --->
</cfif>
<cfinclude template="/media/component/public.cfc" runOnce="true"><!--- for getMediaBlockHtml --->
<cfquery name="Detail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		cataloged_item.collection_object_id,
		container.container_id,
		container_type,
		label,
		description,
		container_remarks,
		container.barcode,
		part_name,
		cat_num,
		scientific_name,
		concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
		parent_install_date,
		WIDTH,
		HEIGHT,
		length,
		NUMBER_POSITIONS
	FROM
		container,
		cataloged_item,
		specimen_part,
		coll_obj_cont_hist,
		(select * from identification where accepted_id_fg=1) identification
	WHERE container.container_id = coll_obj_cont_hist.container_id (+) AND
		coll_obj_cont_hist.collection_object_id = specimen_part.collection_object_id (+) AND
		specimen_part.derived_from_cat_item = cataloged_item.collection_object_id   (+) AND
		cataloged_item.collection_object_id = identification.collection_object_id (+) AND
		container.container_id = <cfqueryparam type="CF_SQL_DECIMAL" value="#container_id#">
</cfquery>
<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT media.media_id,
		mczbase.get_media_descriptor(media.media_id) as alt,
		mczbase.get_medialabel(media.media_id,'subject') as subject,
		media.media_uri,
		media.preview_uri,
		media.media_type,
		MCZBASE.get_media_dctermsrights(media.media_id) as license_uri, 
		MCZBASE.get_media_dcrights(media.media_id) as license_display, 
		MCZBASE.get_media_credit(media.media_id) as credit 
	FROM media_relations 
		left join media on media_relations.media_id = media.media_id
		left join ctmedia_license on media.media_license_id=ctmedia_license.media_license_id
	WHERE 
		media_relationship like '% container' 
		and related_primary_key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#container_id#">
		and mczbase.is_media_encumbered(media.media_id) < 1
</cfquery>
<div style="padding-left: 1em;padding-top: 1em;z-index: 0;">
	<h4>Container Details</h4>
	<cfoutput query="Detail">
		<table border="1" style="padding: .5em;">
			<tr>
		   	<td class="lbl2">Container Type:</td>
				<td class="lblval">#container_type#</td>
			</tr>
			<tr>
				<td class="lbl2">Name:</td>
				<td class="lblval"> #label#</td>
			</tr>
			<cfif len(#description#) gt 0>
				<tr>
					<td class="lbl2"> Description:</td>
					<td class="lblval"> #description#</td>
			 	</tr>
			</cfif>
			<cfif len(#container_remarks#) gt 0>
				<tr>
					<td class="lbl2">Container Remarks:</td>
					<td class="lblval">#container_remarks#</td>
				</tr>
			</cfif>
			<cfif len(#barcode#) gt 0>
				<tr>
					<td class="lbl2">Unique Identifier:</td>
					<td class="lblval">#barcode#</td>
				</tr>
			</cfif>
			<cfif len(#parent_install_date#) gt 0>
				<tr>
					<td class="lbl2">Install Date:</td>
					<td class="lblval">
						#dateformat(parent_install_date,"yyyy-mm-dd")#
						&nbsp;
						#timeformat(parent_install_date,"hh:mm:ss")#
					</td>
				</tr>
			</cfif>
			<cfif len(#part_name#) gt 0>
				<tr>
					<td class="lbl2">Part Name:</td>
					<td class="lblval">#part_name#</td>
				</tr>
				<tr>
					<td class="lbl2">Catalog Number:</td>
					<td class="lblval">#cat_num# </td>
				</tr>
		  		<cfif len(#CustomID#) gt 0>
					<tr>
						<td class="lbl2">#session.CustomOtherIdentifier#:</td>
						<td class="lblval">#CustomID#</td>
					</tr>
		  		</cfif>
				<tr>
					<td class="lbl2">Scientific Name: </td>
					<td class="lblval"><em>#scientific_name#</em></td>
				</tr>
			</cfif>
			<cfif len(#WIDTH#) gt 0 OR len(#HEIGHT#) gt 0 OR len(#length#) gt 0>
				<tr>
					<td class="lbl2">Dimensions (W x H x D): </td>
					<td class="lblval"> #WIDTH# x #HEIGHT# x #length# CM</td>
				</tr>
			</cfif>
			<cfif len(#NUMBER_POSITIONS#) gt 0>
				<tr>
					<td class="lbl2">Number of Positions: </td>
					<td class="lblval"> #NUMBER_POSITIONS#</td>
				</tr>
			</cfif>
			<cfif len(#collection_object_id#) gt 0>
				<tr>
					<td colspan="2" class="lblval">
						<a href="/specimens/Specimen.cfm?collection_object_id=#collection_object_id#"
							target="_blank">Specimen</a> <span style="font-size: small"> (new window)</span>
					</td>
				</tr>
			<cfelse>
				<tr>
					<td colspan="2" class="lblval lblextra">
						<a href="editContainer.cfm?container_id=#container_id#" target="_blank">Edit this container</a> <span style="font-size: small"> (new window)</span>
					</td>
				</tr>
			</cfif>
			<tr>
				<td colspan="2" class="lblval lblextra">
					<a href="/containers/allContainerLeafNodes.cfm?container_id=#container_id#" target="_blank">
							See all collection objects in this container</a>
				</td>
			</tr>
         <cfif container_type NEQ 'collection object'>
				<tr>
					<td colspan="2" class="lblval lblextra">
      		                          <a href="editContainer.cfm?action=newContainer&parent_container_id=#container_id#" class="newContBtn" target="blank">Create a Child of this Container</a>
					</td>
				</tr>
         </cfif>
			<tr>
				<td colspan="2" class="lblval lblextra">
					<a href="/containerPositions.cfm?container_id=#container_id#"
						target="_blank">Positions</a> <span style="font-size: small;"> (new window)</span>
				</td>
			</tr>
			<tr>
				<td colspan="2" class="lblval lblextra">
					<a href="javascript:void(0)" onClick="getHistory('#container_id#'); return false;">History</a>
				</td>
			</tr>
			<cfif media.recordcount GT 0>
				<tr>
					<td colspan="2" class="lblval lblextra">
						<cfloop query="media">
							<div id='mediaBlock#media.media_id#'>
								<cfset mediaBlock = getMediaBlockHtmlUnthreaded(media_id="#media.media_id#",size="350",captionAs="textCaption")>
							</div>
						</cfloop>
					</td>
				</tr>
			</cfif>
		</table>
	</cfoutput>
</div>
