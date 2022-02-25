<cfset pageTitle="Media">
<!--- WARNING: Major work needed.  This is not a redesigned document yet.  See todo notes below --->

<!--- TODO: The old MediaSearch.cfm provides both search results (which should be handled by the media search), and individual media records.  This does not fit the design intent for /media/showMedia.cfm which following redesign conventions would show one and only one media record.  This file needs to be restarted from scratch with a redesign template to show only single media records.  (it should be pretty simple, just header, relevant management links for the user's permission level,  an invocation of getMediaBlockHtml for the single record, and the footer). --->

<!--- TODO: Any api call for more than one image needs to be redirected to either the media search, to show the list of matching images there, or to a new redesigned media gallery which would allow the display of multiple images in larger than thumbnail size along with their metadata --->
<cfinclude template="/shared/_header.cfm">
<script type='text/javascript' src='/shared/js/media.js'></script>
<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfoutput>
<!---<main class="container" id="content">
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
					select distinct 'MCZ:'||collection_cde||':'||cat_num as relatedGuid 
					from media_relations
						left join cataloged_item on related_primary_key = collection_object_id
					where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and media_relationship = 'shows cataloged_item'
				</cfquery>
				<cfif len(media.media_id) gt 0>
					<cfset mediablock= getMediaBlockHtml(media_id="#media.media_id#",size="400",captionAs="textLinks")>
					<div class="float-left" id="mediaBlock#media.media_id#">
						#mediablock#
						<span class="text-center d-block py-2">#mcrguid.relatedGuid# name, aspect etc.</span>
					</div>
				</cfif>
				<div class="float-left col-6">
					<h2 class="h3 px-2">Media ID = #media.media_id#</h2>
					<h3 class="border-bottom px-2">Metadata</h3>
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
</main>--->
<section>
 <cfquery name="m" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select media_uri, mime_type, media_type, media_id,
		get_medialabel(media_id,'height') height, get_medialabel(media_id,'width') width,
		nvl(MCZBASE.GET_MAXHEIGHTMEDIASET(media_id), get_medialabel(media_id,'height')) maxheightinset,
		nvl(
		MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows cataloged_item') ||
		MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows publication') ||
		MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows collecting_event') ||
		MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows agent') ||
		MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows locality')
		, 'Unrelated image') mrstr
	from MEDIA
	where media_id= <cfqueryparam value=#media_id# CFSQLType="CF_SQL_DECIMAL" >
		AND MCZBASE.is_media_encumbered(media.media_id)  < 1
</cfquery>
  <cfloop query="m" endrow="1">
	<cfquery name="alt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select mczbase.get_media_descriptor(media_id) media_descriptor 
		from media 
		where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL"value="#media_id#"> 
	</cfquery> 
	<cfset altText = alt.media_descriptor>
	<cfquery name="mcrguid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" >
		select distinct 'MCZ:'||collection_cde||':'||cat_num as relatedGuid 
		from media_relations
			left join cataloged_item on related_primary_key = collection_object_id
		where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			and media_relationship = 'shows cataloged_item'
	</cfquery>
    <cfset relatedItemA="">
    <cfset guidOfRelatedSpecimen="">
    <cfset relatedItemEndA="">
    <cfloop query="mcrguid" endrow="1">
      <!--- Get the guid and formulated it as a hyperlink for the first related cataloged_item.   --->
      <!--- If the media object shows no cataloged_item, then the link isn't added  --->
      <!--- If the media object shows more than one cataloged item, then the link here is only to the first one.  --->
      <cfset relatedItemA="<a href='/guid/#relatedGuid#'>">
      <cfset guidOfRelatedSpecimen="#relatedGuid#">
      <cfset relatedItemEndA="</a>">
    </cfloop>

    <!---  Determine scaling information for the set of images from the selected image --->
    <cfset im_hw='style="width:#PVWIDTH#px; "'>
    <cfset mdstop=#m.maxheightinset# * 0.5>
    <cfset scaledwidth=#PVWIDTH#>
    <cfset scalefactor = 0.5>
    <cfif len(trim(m.height)) && len(trim(m.width)) >
      <cfset scalefactor = PVWIDTH/#m.width#>
      <cfif scalefactor GT 1 >
        <!--- Some images (e.g. label crops) are smaller than PVWidth, and this works poorly with
		        other large images in the same set, so force the maximum scale factor to 1. --->
        <cfset scalefactor = 1>
      </cfif>
      <cfset scaledheight = Round(#m.height# * #scalefactor#)  >
      <cfset scaledwidth = Round(#m.width# * #scalefactor#) >
      <cfset mdstop =  Round(#m.maxheightinset# * #scalefactor#)>
      <cfset origheight = Round(#m.maxheightinset#)>


      <cfset im_hw = 'style=" height:#scaledheight#px; width:#PVWIDTH#px;"'>
    </cfif>
    <cfif len(guidOfRelatedSpecimen)>
      <cfset relatedItem="#guidOfRelatedSpecimen#">
      <cfelse>
      <cfset relatedItem="#mrstr#">
    </cfif>

    <cfoutput>
      <div id="mediacontain">
      <div class="media_head">
        <h3>Selected image related to #relatedItemA##relatedItem##relatedItemEndA#</h3>
      </div>
      <div class="layoutbox">
       <cfif (#maxheightinset# - #scaledheight#) GT (#maxheightinset#/2)>
            <div class="media_image targetarea" style="height:#mdstop#;min-height: 470px;width:#PVWIDTH#px;">
      			<img id="multizoom1" src='#m.media_uri#' width="#PVWIDTH#px" alt="#altText#">
      		</div>
       <cfelse>
        <div class="targetarea media_image" style="height:#mdstop#px; width:#PVWIDTH#px;">
            <img id="multizoom1" border="0" src='#m.media_uri#' #im_hw# alt="#altText#">
        </div>
    </cfif>
    <div class="image_box">
        <p class="tipbox instruction1">Mouse over image to see zoom window, scroll wheel zooms in and out. <a href="##otherimages">Select other images of same specimen below</a>.</p>
        <div id="multizoomdescription" class="media_meta"> <a href="/media/#m.media_id#">Media Record</a> </div>
    </div>
      <cfoutput> </cfoutput> </cfoutput>
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
	   where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#m.media_id#"> 
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
	   where  media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#m.media_id#">
			and ( media_relationship = 'shows agent')
	   ) ffquery order by sortorder
	</cfquery>
    <cfif ff.recordcount EQ 0>
      <cfoutput>
        <div class ="media_id">
        <div class="backlink"><div>
            <h3>Image is not associated with specimens.</h3>
         <br/><br/>
        </div>
        </div>
      </cfoutput>
    </cfif>
    <cfloop query='ff'>
      <cfif ff.media_relationship eq "shows agent" and  listcontainsnocase(session.roles,"coldfusion_user")>
        <cfset backlink="<a href='/agents/Agent.cfm?agent_id=#ff.pk#'>#ff.name#</a> &mdash; agent record data">
      <cfelse>
           <cfif ff.media_relationship eq "shows cataloged_item">
              <cfset backlink="#ff.specimendetailurl# &mdash; specimen record data:">
           <cfelseif ff.media_relationship eq "shows agent">
              <cfset backlink="#ff.specimendetailurl# &mdash; agent record data:">
           <cfelse>
              <cfset backlink="#ff.specimendetailurl#">
           </cfif>
      </cfif>
      <cfoutput>
        <div class ="media_id">
        <div class="backlink">#backlink#</div>
         <h3><i>#ff.name#</i></h3>
   			<p>#ff.geography# #geology#</p>
        	<p>#ff.coll# </p>
        	<cfif len(trim(#ff.typestatus#))>
          <p class="tclass"><span class="type">#ff.typestatus#</span></p>
        </cfif>
        </div>
      </cfoutput>
      <cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct media.media_id, preview_uri, media.media_uri,
               get_medialabel(media.media_id,'height') height, get_medialabel(media.media_id,'width') width,
			   media.mime_type, media.media_type,
			   CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as license,
                           ctmedia_license.uri as license_uri,
                           mczbase.get_media_credit(media.media_id) as credit,
            		   MCZBASE.is_media_encumbered(media.media_id) as hideMedia
        from media_relations
             left join media on media_relations.media_id = media.media_id
			 left join ctmedia_license on media.media_license_id = ctmedia_license.media_license_id
        where (media_relationship = 'shows cataloged_item' or media_relationship = 'shows agent')
		   AND related_primary_key = <cfqueryparam value=#ff.pk# CFSQLType="CF_SQL_DECIMAL" >
                   AND MCZBASE.is_media_encumbered(media.media_id)  < 1
        order by (
				case media.media_id when <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#m.media_id#"> then 0 else 1 end) ,
				to_number(get_medialabel(media.media_id,'height')
				) desc
   	    </cfquery>
      <cfoutput>
        <a name="otherimages"></a>
        <div class="media_thumbs">
    		<h4>Other images related to #relatedItemA##relatedItem##relatedItemEndA#</h4>
			<div class="multizoom1 thumbs">
      </cfoutput>
      <cfset counter=0>
      <cfloop query="relm">
        <cfif len(trim(relm.height)) && len(trim(relm.width)) >
           <cfset counter++ >
           <cfset scalefactor = PVWIDTH/#relm.width#>
           <cfif scalefactor GT 1 >
             <cfset scalefactor = 1>
           </cfif>
           <cfset scaledheight = 0 + Round(#relm.height# * #scalefactor#) >
           <cfset scaledwidth = Round(#relm.width# * #scalefactor#) >

           <!--- Obtain list of attributes and add to data-title of anchor to display metadata for each image as it is selected.  --->
           <cfset labellist="<ul>">
           <cfset labellist = "#labellist#<li>media: #media_type# (#mime_type#)</li>">
           <!---<cfset labellist = "#labellist#<li>license: <a href='#license_uri#'>#license#</a></li>">--->
           <cfset labellist = "#labellist#<li>credit: #credit#</li>" >
           <cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select media_label, label_value
					from media_labels
					where media_label in ('aspect', 'spectrometer', 'spectrometer reading location', 'light source', 'height', 'width')
						and media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#relm.media_id#">
           </cfquery>
           <cfloop query="labels">
             <cfset labellist = "#labellist#<li>#media_label#: #label_value#</li>">
           </cfloop>
           <cfquery name="relations"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select media_relationship as mr_label, MCZBASE.MEDIA_RELATION_SUMMARY(media_relations_id) as mr_value
					from media_relations
					where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#relm.media_id#">
					and media_relationship in ('created by agent', 'shows cataloged_item')
           </cfquery>
           <cfloop query="relations">
             <cfif not (not listcontainsnocase(session.roles,"coldfusion_user") and #mr_label# eq "created by agent")>
               <cfset labellist = "#labellist#<li>#mr_label#: #mr_value#</li>">
             </cfif>
           </cfloop>
           <cfquery name="keywords"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select keywords
					from media_keywords
					where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#relm.media_id#">
           </cfquery>
           <cfset kwlist="">
           <cfloop query="keywords">
             <cfset kwlist = "#kwlist# #keywords#">
           </cfloop>
           <cfif len(trim(kwlist)) >
             <cfset labellist = "#labellist#<li>keywords: #kwlist#</li>">
           </cfif>
           <cfset labellist="#labellist#</ul>">
           <!--- Define the metadata block that gets changed when an image is selected from the set --->
           <cfset datatitle="
   			<h4><a href='media/#relm.media_id#'>Media Record (metadata)</a> <span> <!---(metadata for image #counter# of #relm.recordcount#)---></a></h4>">
           <cfset data_content= "#labellist#">
           <!--- one height doesn't work yet --->
           <cfset datalinks="<h3 class='img_ct'>Image #counter# of #relm.recordcount#</h3><div class='full'><a href='#relm.media_uri#'>Full Image </a></div><div class='full'><a href='#license_uri#' class='full'>#license#</a></div>">
           <cfoutput><a href="#relm.media_uri#" data-dims="#scaledwidth#, #scaledheight#" data-large="#relm.media_uri#"
		     data-title="#datalinks# #datatitle# #data_content#"><img src="#relm.preview_uri#" alt="#altText#">#counter#</a></cfoutput>
        </cfif> <!--- end are relm.height and relm.width non null --->
      </cfloop> <!--- end loop through relm to show any images for media relations of current related cataloged_item --->
      <!--- if any related images, show their thumbnails --->
      <cfif relm.recordcount gt 1>
        <cfoutput>
          </div>

          <!-- end multizooom thumbs -->
          <p class="tipbox instruction2">Click to select from the #relm.RecordCount# images of this specimen.</p>
          </div>
          <!-- end media_thumbs -->
        </cfoutput>
        <cfelse>
        <cfoutput>
          </div>

          <!-- end multizooom thumbs -->
          <p class="tipbox instruction2">There is only one image of this specimen.</p>
          </div>

          </div>
          </div>
</section>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
