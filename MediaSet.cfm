<cfset usealternatehead="image" />
<cfinclude template="/includes/_header.cfm">
<!---  Displays an image and other images in a set related by the relationship shows cataloged_item --->

<cfif NOT isDefined("media_id")>
  <cfoutput>
    <h2>No Media Object Specified</h2>
  </cfoutput>
  <cfelse>
	<cfset checkSql(media_id)>
  <cfset PVWIDTH=500>
  <!--- Fixed width for the scaled display of the media object on this page. --->

  <!--- Fixed width for the scaled display of the media object on this page. --->
  <cfset metaLeftOffset = PVWIDTH +20 >
  <!--- Check to see if height/width are known for this imageset --->
  <cfquery name="checkmedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    select get_medialabel(media_id,'height') height, get_medialabel(media_id,'width') width,
		   MCZBASE.GET_MAXHEIGHTMEDIASET(media_id) maxheightinset,
		   media.media_type
    from MEDIA where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
</cfquery>
  <cfloop query="checkmedia" endrow="1">
    <cfif not checkmedia.media_type eq "image">
      <!--- Redirect --->
      <cflocation url='/media/#media_id#' addToken="no">
    </cfif>
    <cfif not len(checkmedia.height) >
      <!--- >or #IsNull(checkmedia.width)# or #IsNull(checkmedia.maxheightinset)# --->
      <!---  If height and width aren't known, find and store them --->
      <cfquery name="mediatocheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		  select findm.media_id, findm.media_uri
            from media_relations startm
            left join media_relations mr on startm.related_primary_key = mr.related_primary_key
			left join media findm on mr.media_id = findm.media_id
          where (mr.media_relationship = 'shows cataloged_item' or mr.media_relationship = 'shows agent' or mr.media_relationship = 'shows locality')
		    and startm.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		    and findm.media_type = 'image'
      </cfquery>
      <cfset checkcounter = 0>
      <cfloop query="mediatocheck" >
        <cfset checkcounter = checkcounter + 1>
        <cfif checkcounter eq 1>
           <cfoutput>You are the first to view one or more images on this page.  The application is checking the images so there may be a brief delay before they are displayed.</cfoutput>
        </cfif>
        <cftry>
	  <cfif left(mediatocheck.media_uri,14) EQ 'http://mczbase' AND Application.protocol EQ 'https'>
               <cfset checkmediauri = Replace(mediatocheck.media_uri,'http:','https:',"one")>
          <cfelse>
               <cfset checkmediauri = mediatocheck.media_uri>
          </cfif>
          <cfimage action="INFO" source="#checkmediauri#" structname="img">
          <cfcatch>
 		<cfoutput>Error checking image #mediatocheck.media_uri# #cfcatch.message# #cfcatch.detail#</cfoutput>
          </cfcatch>
        </cftry>
        <cfif isDefined("debug")>
           <cfoutput>
             <p>Finding h,w #img.height#,#img.width# for #mediatocheck.media_uri#</p>
           </cfoutput>
        </cfif>
        <cftry>
          <cfquery name="addh" datasource="uam_god" timeout="2">
			   insert into media_labels 
					(media_id, 
					media_label, 
					label_value, 
					assigned_by_agent_id
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mediatocheck.media_id#">, 
					'height', 
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#img.height#">, 
					0
				)
			</cfquery>
          <cfcatch>
          </cfcatch>
        </cftry>
        <cftry>
          <cfquery name="addw" datasource="uam_god" timeout="2">
			   insert into media_labels 
					(media_id, 
					media_label, 
					label_value, 
					assigned_by_agent_id
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mediatocheck.media_id#">,
					'width', 
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#img.width#">,
					 0
				)
			</cfquery>
          <cfcatch>
          </cfcatch>
        </cftry>
        <cftry>
            <cfhttp url="#mediatocheck.media_uri#" method="get" getAsBinary="yes" result="filetohash">
            <cfset md5hash=Hash(filetohash.filecontent,"MD5")>
            <cfquery name="makeMD5hash" datasource="uam_god" >
					insert into media_labels 
						(media_id, 
						MEDIA_LABEL, 
						ASSIGNED_BY_AGENT_ID,
						 LABEL_VALUE
					) values ( 
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mediatocheck.media_id#">,
						'md5hash',
						0, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#md5Hash#">
					)
            </cfquery>
          <cfcatch>
          </cfcatch>
        </cftry>
      </cfloop>
    </cfif>
  </cfloop>

  <!--- Find the requested media object --->
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
		select 'MCZ:'||collection_cde||':'||cat_num as relatedGuid 
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

      <!--	<p>height:#m.height# scaled to #scaledheight#</p>
			<p>width:#m.width# scaled to #PVWIDTH#</p>
			<p>scalefactor: #scalefactor#</p>
			<p>maxheightinset: #m.maxheightinset#</p>
			<p>mdstop: #mdstop# (cell height reserved for the tallest image in the set)</p>
            <p>scaled height #scaledheight#</p>
            <p>scaledwidth #scaledwidth#</p>  -->

<!---      <cfif len(relatedItemA) gt 0>
        <div class="backlink">Go to specimen record #relatedItemA##relatedItem##relatedItemEndA# </div>#relatedItemA#<img src='images/linkOut.gif' alt='specimen link'/>#relatedItemEndA#
      </cfif>
      <cfif len(relatedItemA) eq 0>
        <div class='topDescriptor'>Internal Media</div>
      </cfif>--->
      <div class="media_head">
        <h3>Selected image related to #relatedItemA##relatedItem##relatedItemEndA#</h3>
      </div>
      <div class="layoutbox">
      <!--- div targetarea has space reserved for the tallest image in the set of images, it has a fixed width to which all images are rescaled.  --->
      <!--- div targetarea is the bit to hold the image that will be replaced by multizoom.js when a different image is picked --->

       <cfif (#maxheightinset# - #scaledheight#) GT (#maxheightinset#/2)>
            <div class="media_image targetarea" style="height:#mdstop#;min-height: 470px;width:#PVWIDTH#px;">
      			<img id="multizoom1" src='#m.media_uri#' width="#PVWIDTH#px" alt="#altText#">
      		</div>
       <cfelse>
        <div class="targetarea media_image" style="height:#mdstop#px; width:#PVWIDTH#px;">
            <img id="multizoom1" border="0" src='#m.media_uri#' #im_hw# alt="#altText#">
        </div>
    </cfif>
      <!---  Enclosing div reserves a place for metadata about the currently selected image --->
      <!---  div multizoomdescription is the bit to hold the medatadata that will be replaced by multizoom.js when a different image is picked --->

      <!--- tip  (added to each replaced multizoomdescription) --->
    <div class="image_box">
        <p class="tipbox instruction1">Mouse over image to see zoom window, scroll wheel zooms in and out. <a href="##otherimages">Select other images of same specimen below</a>.</p>
        <div id="multizoomdescription" class="media_meta"> <a href="/media/#m.media_id#">Media Record</a> </div>
    </div>
      <cfoutput> </cfoutput> </cfoutput>
    <cfquery name="ff" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	 select * from (
	   select collection_object_id as pk, guid,
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
	   select agent.agent_id as pk, '' as guid,
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
      <!--- Gracefully fail if not associated with a specimen --->
      <cfoutput>
        <div class ="media_id">
        <div class="backlink"><div>
            <h3>Image is not associated with specimens.</h3>
         <br/><br/>
          <!--- end media_id --->
        </div>
        <!--- end layoutbox --->
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
      <!--- Obtain the list of related media objects, construct a list of thumbnails, each with associated metadata that are switched out by mulitzoom --->
      <cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select media.media_id, preview_uri, media.media_uri,
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

          <!-- end media_thumbs -->
        </cfoutput>
      </cfif> <!--- end display of thumbnails of related images --->
    </cfloop><!--- end loop through ff for related cataloged items --->
    <cfoutput>
      </div>
      </div>
      <!-- end mediacontain -->
    </cfoutput>
  </cfloop>
  <!--- on m, loop to get single media record with given media_id  --->
</cfif>
<!--- media_id is defined --->
<cfinclude template="/includes/_footer.cfm">
