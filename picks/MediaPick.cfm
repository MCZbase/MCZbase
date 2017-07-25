<cfinclude template="../includes/_pickHeader.cfm">
<cfset title = "Media Pick">

<cfquery name="ctmedia_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    select media_relationship from ctmedia_relationship order by media_relationship
</cfquery>
<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    select media_type from ctmedia_type order by media_type
</cfquery>
<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    select mime_type from ctmime_type order by mime_type
</cfquery>

<!--- Set some defaults for search --->
<cfif not isdefined(mime_type) >
   <cfset mime_type = "application/pdf">
</cfif>
<cfif not isdefined(media_type) >
   <cfset media_type = "text">
</cfif>

<cfoutput>

<!---  To create a media relation, the target, the relation type, and the media must be specified, this page picks
       media with a search, so it must be given a target and a relation type --->
<cfset error=FALSE>
<cfif not isdefined(target_id) >
    Error: This page must be given a target_id to link to.
    <cfset error=TRUE>
</cfif>
<cfif not isdefined(target_relation) >
    Error: This page must be given a target_relation to create a link.
    <cfset error=TRUE>
</cfif>

<cfif error EQ FALSE>

    Search for media. Any part of media uri accepted.<br>
    <cfform name="findMedia" action="MediaPick.cfm" method="post">

        <input type="hidden" name="Action" value="search">
        <input type="hidden" name="target_id" value="#target_id#">
        <input type="hidden" name="target_relation" value="#target_relation#">
        <table>
    
          <tr>
          <td colspan="2">
             <label for="media_uri">Media URI (<a href="#media.media_uri#" target="_blank">open</a>)</label>
             <input type="text" name="media_uri" id="media_uri" size="90" value="#media.media_uri#">
          </td>
          </tr>
    
          <tr>
          <td>
             <label for="mime_type">MIME Type</label>
             <select name="mime_type" id="mime_type">
               <cfloop query="ctmime_type">
                 <option <cfif #mime_type# is #ctmime_type.mime_type#> selected="selected"</cfif> value="#ctmime_type.mime_type#">#ctmime_type.mime_type#</option>
               </cfloop>
             </select>
          </td>
          <td>
             <label for="media_type">Media Type</label>
             <select name="media_type" id="media_type">
               <cfloop query="ctmedia_type">
                 <option <cfif #media_type# is #ctmedia_type.media_type#> selected="selected"</cfif> value="#ctmedia_type.media_type#">#ctmedia_type.media_type#</option>
               </cfloop>
             </select>
          </td>
          </tr>
            <tr>
            <td>
                <input type="submit" value="Search" class="schBtn">    
            </td>
            <td>
                <input type="reset" value="Clear" class="clrBtn">
            </td>
            </tr>
        </table>
    </cfform>
    </cfoutput>

    <cfif Action is "search">
    
    <cfquery name="matchMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select media_id, media_uri, preview_uri, mime_type, media_type
        from media
        where 
          <cfif isdefined(media_type) len(#media_type#) gt 0>
            media_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_type#">
          </cfif>
          <cfif isdefined(mime_type) len(#mime_type#) gt 0>
            mime_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#">
          </cfif>
          <cfif isdefined(media_uri) len(#media_uri#) gt 0>
            media_uri like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#media_uri#%">
          </cfif>
    </cfquery>

    <cfset i=1>
    <cfoutput query="matchMedia" group="media_id">
    <div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#    >
        <form action="MediaPick.cfm" method="post" name="save">
            <input type="hidden" value="#target_relation#" name="target_relation">
            <input type="hidden" name="target_id" value="#target_id#">
            <input type="hidden" name="Action" value="addThisOne">
            <a href='#media_uri#'>#media_uri#</a> #mime_type# #media_type# <a href='/media/#media_id#' target='_blank'>Media Details</a>
            <br><input type="submit" value="Add this media">
        </form>
    </div>
    <cfset i=i+1>
    </cfoutput>
    
    </cfif><!--- action is search ---> 


    <cfif #Action# is "AddThisOne">
        <cfoutput>
            <cfif not (len(#target_id#) gt 0 and len(#media_id#) gt 0 and len(#target_relation#) gt 0) >
                Error, to create a media relationship, media id (#media_id#), related primary key (#target_id#), and relationship (#target_relation#) are required. <cfabort>
            </cfif>
            <cfquery name="addMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addMediaResult">
                INSERT INTO media_relations (media_id, related_primary_key, relationship) VALUES (#media_id#, #target_id#,#target_relation#)
            </cfquery>
            
            Added media #media_id# in relationship #target_relation# to #target_id#. 
            <br>Search to add another media object as #target_relation# or click OK to close this window.
        </cfoutput>    
    </cfif> <!--- action is addthisone --->

</cfif> <!--- end if Error is false --->

<cfinclude template="../includes/_pickFooter.cfm">
