<cfinclude template="/includes/_header.cfm">
<cfif isDefined("media_id")>

<cfquery name="m" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select media_uri, mime_type, media_type, media_id from MEDIA where media_id=#media_id#
</cfquery>
<cfloop query="m" endrow="1">
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
        #ff.specimendetailurl#<br/>
        #ff.scientific_name# #ff.author_text# #identifiedby# #made_date#<br/>
	 	#ff.higher_geog# #ff.spec_locality#<br/>
     	</cfoutput>
	<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select media.media_id, preview_uri from media_relations
        left join media on media_relations.media_id = media.media_id
         where media_relationship = 'shows cataloged_item'
		   and related_primary_key = #ff.collection_object_id#
		   and media.media_id <> #m.media_id#
  	</cfquery>
	<cfloop query="relm">
		<cfoutput>
			<a href="MediaDetail.cfm?media_id=#relm.media_id#"><img src="#relm.preview_uri#"></a>
		</cfoutput>
	</cfloop>
	</cfloop>
    <cfoutput>
	   <br/>
       <img src='#m.media_uri#'><br/>
    </cfoutput>
</cfloop>
<cfelse>
<cfoutput>
	<h2>No Media Object Specified</h2>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">