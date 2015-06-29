<cfset usealternatehead="image" />
<cfinclude template="/includes/_header.cfm">
<cfif isDefined("media_id")>

<cfquery name="m" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    select media_uri, mime_type, media_type, media_id,
           get_medialabel(media_id,'height') height, get_medialabel(media_id,'width') width,
		   MCZBASE.GET_MAXHEIGHTMEDIASET(media_id) maxheightinset
    from MEDIA where media_id=#media_id#
</cfquery>
<cfloop query="m" endrow="1">
    <cfset im_hw='style=" width:500px; "'>
    <cfset mdstop=#m.maxheightinset#>
    <cfset scaledheight='500'>
    <cfif len(trim(m.height)) && len(trim(m.width)) >
	   <cfset scalefactor = 500/#m.width#>
       <cfset scaledheight = Round(#m.height# * #scalefactor#)  >
       <cfset mdstop = 2 + Round(#m.maxheightinset# * #scalefactor#)>
       <cfset im_hw = ' style=" height:#scaledheight#px; width:500px;" '>
    </cfif>
    <cfoutput>
            <h2>Media Details</h2>
            <p>Mouse over image to see zoom window, scroll wheel zooms in and out.  Select other images of same specimen below.</p>
	    <table><tr><td style="height:#mdstop#px;">
            <div class="targetarea">
                <img id="multizoom1" border="0" src='#m.media_uri#' #im_hw#>
            </div>
            </td></tr><tr><td>
            <div id="multizoomdescription"><a href="#m.media_uri#">Full Image</a></div>
    </cfoutput>
	<cfquery name="ff" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	   select collection_object_id, guid, institution_acronym, collection_cde, cat_num, othercatalognumbers,
              typestatusword,typestatus,
              scientific_name, author_text, identifiedby, made_date,
              higher_geog, spec_locality,
              earliestperiodorlowestsystem, latestperiodorhighestsystem, earliestepochorlowestseries, latestepochorhighestseries,
              earliestageorloweststage,latestageorhigheststage, geol_group, formation, member, bed,
              collectors, field_num, verbatim_date, began_date, ended_date,
              specimendetailurl
       from media_relations
	       left join filtered_flat on related_primary_key = collection_object_id
	   where media_id = #m.media_id# and media_relationship = 'shows cataloged_item'
	</cfquery>
	<cfloop query='ff'>
	    <cfoutput>
            </td></tr>
            <tr><td>
        #ff.specimendetailurl#<br/>
        #ff.scientific_name# #ff.author_text# #identifiedby# #made_date#<br/>
	 	#ff.higher_geog# #ff.spec_locality#<br/>
     	</cfoutput>
	<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select media.media_id, preview_uri, media.media_uri,
                       get_medialabel(media.media_id,'height') height, get_medialabel(media.media_id,'width') width
                from media_relations
                left join media on media_relations.media_id = media.media_id
                where media_relationship = 'shows cataloged_item'
		   and related_primary_key = #ff.collection_object_id#
                order by to_number(get_medialabel(media.media_id,'height')) desc
  	</cfquery>
        <cfoutput>
            <div class="multizoom1 thumbs" style='width:600px;' >
        </cfoutput>
	<cfloop query="relm">
                <cfif len(trim(relm.height)) && len(trim(relm.width)) >
                    <cfset scaledheight = Round(#relm.height# * (500 / #relm.width#))  >
                </cfif>
		<cfoutput>
			<a href="#relm.media_uri#" data-dims="500, #scaledheight#" data-large="#relm.media_uri#" data-title="<a href='#relm.media_uri#'>Full Image</a>" ><img src="#relm.preview_uri#"></a>
		</cfoutput>
	</cfloop>
        <cfoutput>
            </div>
			<p>Click to select from the #relm.RecordCount# images of this specimen.</p>
            </td></tr></table>
        </cfoutput>
	</cfloop>
</cfloop>
<cfelse>
<cfoutput>
	<h2>No Media Object Specified</h2>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">