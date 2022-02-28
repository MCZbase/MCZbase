<cfset pageTitle="Media">
<!--- WARNING: Major work needed.  This is not a redesigned document yet.  See todo notes below --->

<!--- TODO: The old MediaSearch.cfm provides both search results (which should be handled by the media search), and individual media records.  This does not fit the design intent for /media/showMedia.cfm which following redesign conventions would show one and only one media record.  This file needs to be restarted from scratch with a redesign template to show only single media records.  (it should be pretty simple, just header, relevant management links for the user's permission level,  an invocation of getMediaBlockHtml for the single record, and the footer). --->

<!--- TODO: Any api call for more than one image needs to be redirected to either the media search, to show the list of matching images there, or to a new redesigned media gallery which would allow the display of multiple images in larger than thumbnail size along with their metadata --->
<cfinclude template="/shared/_header.cfm">
<script type='text/javascript' src='/shared/js/media.js'></script>
<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfoutput>
<main class="container" id="content">
	<div class="row">
		<div class="col-12 mt-4 ">
			<h1 class="h2 mt-4 pb-1 mb-3 border-bottom">Media Record</h1>
			<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select distinct 
					media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri, 
					MCZBASE.is_media_encumbered(media.media_id) hideMedia,
					MCZBASE.get_media_credit(media.media_id) as credit, 
					mczbase.get_media_descriptor(media_id) as alttag,
					nvl(MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows cataloged_item') ||
						MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows publication') ||
						MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows collecting_event') ||
						MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows agent') ||
						MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows locality')
						, 'Unrelated image') mrstr
				From
					media
				WHERE 
					media.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#media_id#" list="yes">
					AND MCZBASE.is_media_encumbered(media_id)  < 1 
			</cfquery>
			<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					media_label,
					label_value,
					agent_name,
					media_label_id 
				FROM
					media_labels
					left join preferred_agent_name on media_labels.assigned_by_agent_id=preferred_agent_name.agent_id
				WHERE
					media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			</cfquery>
			<cfquery name="keywords"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					media_id,
					keywords
				FROM
					media_keywords
				WHERE
					media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
			</cfquery>
			<cfquery name="mediaRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT source_media.media_id source_media_id, 
					source_media.auto_filename source_filename,
					source_media.media_uri source_media_uri,
					media_relations.media_relationship,
					MCZBASE.get_media_descriptor(source_media.media_id) source_alt
				FROM
					media_relations
					left join media source_media on media_relations.media_id = source_media.media_id
				WHERE
					related_primary_key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
					and media_relationship like '%media'
			</cfquery>

			<cfloop query="media">
				<cfquery name="mcrguid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" >
					select distinct 'MCZ:'||collection_cde||':'||cat_num as relatedGuid, scientific_name 
					from media_relations
						left join cataloged_item on related_primary_key = collection_object_id
						left join identification on identification.collection_object_id = cataloged_item.collection_object_id
					where media_relations_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and media_relationship = 'shows cataloged_item'
				</cfquery>
				<cfif len(media.media_id) gt 0>
					<cfset mediablock= getMediaBlockHtml(media_id="#media.media_id#",size="400",captionAs="textLinks")>
					<div class="float-left" id="mediaBlock#media.media_id#">
						#mediablock#
						<span class="text-center d-block py-2">#mcrguid.relatedGuid#, #mcrguid.scientific_name#</span>
					</div>
				</cfif>
				<div class="float-left col-6">
					<h2 class="h3 px-2">Media ID = #media.media_id#</h2>
					<h3 class="text-decoration-underline px-2">Metadata</h3>
					<ul class="list-group">
						<cfloop query="labels">
						<li class="list-group-item">#labels.media_label#: #labels.label_value#</li>
						</cfloop>
						<li class="list-group-item">Keywords: #keywords.keywords#</li>
						<li class="list-group-item">Alt Text: #media.alttag#</li>
					</ul>
				</div>
			</cfloop>
		</div>
	</div>
</main>
 <cfquery name="ff" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	 select * from (
	   select distinct collection_object_id as pk, guid,
            typestatus, SCIENTIFIC_NAME name,
decode(continent_ocean, null,'',' '|| continent_ocean) || decode(country, null,'',': '|| country) || decode(state_prov, null, '',': '|| state_prov) || decode(county, null, '',': '|| county)||decode(spec_locality, null,'',': '|| spec_locality) as geography,
			trim(MCZBASE.GET_CHRONOSTRATIGRAPHY(locality_id) || ' ' || MCZBASE.GET_LITHOSTRATIGRAPHY(locality_id)) as geology,
            trim( decode(collectors, null, '',''|| collectors) || decode(field_num, null, '',' &nbsp;&nbsp;&nbsp;&nbsp; '|| field_num) || decode(verbatim_date, null, '',' &nbsp;&nbsp;&nbsp;&nbsp; '|| verbatim_date))as coll,
        	specimendetailurl,
			media_relationship,
			1 as sortorder
       from media_relations
	       left join  <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> on related_primary_key = collection_object_id
	   where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#"> 
			and ( media_relationship = 'shows cataloged_item')
	   union
	   select distinct agent.agent_id as pk, '' as guid,
	        '' as typestatus, agent_name as name,
	        agent_remarks as geography,
	        '' as geology,
	        '' as coll,
	        agent_name as specimendetailurl,
	        media_relationship,
	        2 as sortorder
	   from media_relations
	      left join agent on related_primary_key = agent.agent_id
	      left join agent_name on agent.preferred_agent_name_id = agent_name.agent_name_id
	   where  media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
			and ( media_relationship = 'shows agent')
	   ) ffquery order by sortorder
	</cfquery>

    <cfloop query='ff'>
        <div class ="media_id">
         <h3><i>#ff.name#</i></h3>
   			<p>#ff.geography# #geology#</p>
        	<p>#ff.coll# </p>
        	<cfif len(trim(#ff.typestatus#))>
          <p class="tclass"><span class="type">#ff.typestatus#</span></p>
        </cfif>
        </div>

</cfoutput>
<cfinclude template="/shared/_footer.cfm">
