<cfset usealternatehead="image" />
<cfinclude template="/includes/_header.cfm">
<cfif isDefined("media_id")>
<cfset PVWIDTH=500>

<!--- Check to see if height/width are known for this imageset --->
<cfquery name="checkmedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    select get_medialabel(media_id,'height') height, get_medialabel(media_id,'width') width,
		   MCZBASE.GET_MAXHEIGHTMEDIASET(media_id) maxheightinset,
		   media.media_type
    from MEDIA where media_id=#media_id#
</cfquery>
<cfloop query="checkmedia" endrow="1">
    <cfif not checkmedia.media_type eq "image">
		<!--- Redirect --->
	</cfif>
	<cfif not len(checkmedia.height) >
			<!--- >or #IsNull(checkmedia.width)# or #IsNull(checkmedia.maxheightinset)# --->
		<!---  If height and width aren't known, find and store them --->
		<cfquery name="mediatocheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		  select findm.media_id, findm.media_uri
            from media_relations startm
            left join media_relations mr on startm.related_primary_key = mr.related_primary_key
			left join media findm on mr.media_id = findm.media_id
          where mr.media_relationship = 'shows cataloged_item'
		    and startm.media_id = #media_id#
		</cfquery>
		<cfloop query="mediatocheck" >
			<cfimage action="INFO" source="#mediatocheck.media_uri#" structname="img">
		   <cfoutput><p>Finding h,w #img.height#,#img.width# for #mediatocheck.media_uri#</p></cfoutput>
		   <cftry>
		   <cfquery name="addh" datasource="uam_god" timeout="2">
			   insert into media_labels (media_id, media_label, label_value, assigned_by_agent_id) values (#mediatocheck.media_id#, 'height', #img.height#, 0)
			</cfquery>
			<cfcatch></cfcatch></cftry>
		   <cftry>
		   <cfquery name="addw" datasource="uam_god" timeout="2">
			   insert into media_labels (media_id, media_label, label_value, assigned_by_agent_id) values (#mediatocheck.media_id#, 'width', #img.width#, 0)
			</cfquery>
			<cfcatch></cfcatch></cftry>
        </cfloop>
	</cfif>
</cfloop>

<!--- Find the requested media object --->
<cfquery name="m" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    select media_uri, mime_type, media_type, media_id,
           get_medialabel(media_id,'height') height, get_medialabel(media_id,'width') width,
		   MCZBASE.GET_MAXHEIGHTMEDIASET(media_id) maxheightinset,
		   MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows cataloged_item') mrstr
    from MEDIA where media_id=#media_id#
</cfquery>
<cfloop query="m" endrow="1">
    <!---  Determine scaling information for the set of images from the selected image --->
    <cfset im_hw='style=" width:#PVWIDTH#px; "'>
    <cfset mdstop=#m.maxheightinset#>
    <cfset scaledheight=#PVWIDTH#>
	<cfset scalefactor = 0.5>
    <cfif len(trim(m.height)) && len(trim(m.width)) >
	   <cfset scalefactor = PVWIDTH/#m.width#>
	   <cfif scalefactor GT 1 >
		  <!--- Some images (e.g. label crops) are smaller than PVWidth, and this works poorly with
		        other large images in the same set, so force the maximum scale factor to 1. --->
	      <cfset scalefactor = 1>
	   </cfif>
       <cfset scaledheight = Round(#m.height# * #scalefactor#)  >
       <cfset mdstop = 10 + Round(#m.maxheightinset# * #scalefactor#)>
       <cfset im_hw = ' style=" height:#scaledheight#px; width:#PVWIDTH#px;" '>
    </cfif>
    <cfoutput>
            <!--
			<p>height:#m.height# scaled to #scaledheight#</p>
			<p>width:#m.width# scaled to #PVWIDTH#</p>
			<p>scalefactor: #scalefactor#</p>
			<p>maxheightinset: #m.maxheightinset#</p>
			<p>mdstop: #mdstop# (table cell height)</p>
            -->
            <h3>Images related to #mrstr#</h3>
            <p>Mouse over image to see zoom window, scroll wheel zooms in and out.  Select other images of same specimen below.</p>
	    <table><tr>
		      <td style="height:#mdstop#px; width:#PVWIDTH#px; background: rgb(240,240,240); ">
               <div class="targetarea">
                  <img id="multizoom1" border="0" src='#m.media_uri#' #im_hw#>
               </div>
              </td>
			  <td>
                 <div id="multizoomdescription"><a href="#m.media_uri#">Full Image</a></div>
			  </td>
		    </tr>
			<tr><td colspan="2">
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
            <tr><td  colspan="2">
        #ff.specimendetailurl#<br/>
        #ff.scientific_name# #ff.author_text# #identifiedby# #made_date#<br/>
	 	#ff.higher_geog# #ff.spec_locality#<br/>
     	</cfoutput>
	<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select media.media_id, preview_uri, media.media_uri,
               get_medialabel(media.media_id,'height') height, get_medialabel(media.media_id,'width') width,
			   media.mime_type, media.media_type,
			   ctmedia_license.display as license, ctmedia_license.uri as license_uri
        from media_relations
             left join media on media_relations.media_id = media.media_id
			 left join ctmedia_license on media.media_license_id = ctmedia_license.media_license_id
        where media_relationship = 'shows cataloged_item'
		      and related_primary_key = #ff.collection_object_id#
        order by (case media.media_id when #m.media_id# then 0 else 1 end) , to_number(get_medialabel(media.media_id,'height')) desc
  	</cfquery>
        <cfoutput>
            <div class="multizoom1 thumbs" style='width:600px;' >
        </cfoutput>
	<cfloop query="relm">
                <cfset scaledheight = Round(#relm.height# * #scalefactor#) >
                <cfset scaledwidth = Round(#relm.width# * #scalefactor#) >
				<!--- Obtain list of attributes and add to data-title of anchor to display metadata for each image as it is selected.  --->
				<cfset labellist="<ul>">
				<cfset labellist = "#labellist#<li>media: #media_type# (#mime_type#)</li>">
				<cfset labellist = "#labellist#<li>license: <a href='#license_uri#'>#license#</a></li>">
                <cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                    select media_label, label_value
                    from media_labels
					where media_label != 'description' and media_id=#relm.media_id#
                </cfquery>
				<cfloop query="labels">
					<cfset labellist = "#labellist#<li>#media_label#: #label_value#</li>">
				</cfloop>
                <cfquery name="relations"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                    select media_relationship as mr_label, MCZBASE.MEDIA_RELATION_SUMMARY(media_relations_id) as mr_value
                    from media_relations
					where media_id=#relm.media_id#
                </cfquery>
				<cfloop query="relations">
					<cfset labellist = "#labellist#<li>#mr_label#: #mr_value#</li>">
				</cfloop>
                <cfquery name="keywords"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                    select keywords
                    from media_keywords
					where media_id=#relm.media_id#
                </cfquery>
				<cfset kwlist="">
				<cfloop query="keywords">
					<cfset kwlist = "#kwlist# #keywords#">
				</cfloop>
				<cfif len(trim(kwlist)) >
					<cfset labellist = "#labellist#<li>keywords: #kwlist#</li>">
				</cfif>
				<cfset labellist="#labellist#</ul>">
		<cfoutput>
			<a href="#relm.media_uri#" data-dims="#scaledwidth#, #scaledheight#" data-large="#relm.media_uri#" data-title="<a href='#relm.media_uri#'>Full Image</a>#labellist#" ><img src="#relm.preview_uri#"></a>
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