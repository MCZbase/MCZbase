<cfset title="Media">
<cfset metaDesc="Locate Media, including audio (sound recordings), video (movies), and images (pictures) of specimens, collecting sites, habitat, collectors, and more.">
<cfinclude template="/includes/_header.cfm">
<cfif isdefined("url.collection_object_id")>
     <!---
    	<cflocation url="MediaSearch.cfm?action=search&relationship__1=cataloged_item&related_primary_key__1=#url.collection_object_id#&specID=#url.collection_object_id#" addtoken="false" statusCode="303" >
     --->
     <cfset action="search">
     <cfset relationship__1="cataloged_item">
     <cfset url.relationship__1="cataloged_item">
     <cfset related_primary_key__1="#url.collection_object_id#">
     <cfset url.related_primary_key__1="#url.collection_object_id#">
     <cfset specID="#url.collection_object_id#">
</cfif>

<div class="basic_search_box" style="padding-bottom:5em;">
<script type='text/javascript' src='/includes/media.js'></script>
<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>

	<cfif isdefined("specID") and len(specID) gt 0>
         <cfset createSpecimenMediaShown="true">
		<cfoutput>
			<a class="toplinks" href="/media.cfm?action=newMedia&collection_object_id=#specID#">[ Create Specimen media ]</a>
		</cfoutput>
	<cfelse>
		<cfoutput>
    		<a class="toplinks" href="/media.cfm?action=newMedia">[ Create Media ]</a>
		</cfoutput>
	</cfif>
</cfif>

<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
	<cfset isClicky = "likeLink">
<cfelse>
	<cfset oneOfUs = 0>
	<cfset isClicky = "">
</cfif>

<!----------------------------------------------------------------------------------------->
<cfif #action# is "nothing">
	<cfoutput>
    <cfquery name="ctmedia_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select media_relationship from ctmedia_relationship 
		<cfif oneOfUs EQ 0>
			where media_relationship not like 'document%' and media_relationship not like '%permit'
		</cfif>
		order by media_relationship
	</cfquery>
	<cfquery name="ctmedia_label" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select media_label from ctmedia_label 
		<cfif oneOfUs EQ 0>
			where media_label <> 'internal remarks'
		</cfif> 
		order by media_label
	</cfquery>
	<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select media_type from ctmedia_type order by media_type
	</cfquery>
	<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select mime_type from ctmime_type order by mime_type
	</cfquery>

    <br>
    <h2 class="wikilink">Search Media
      <cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
        <img class="infoLink" src="images/info_i_2.gif" onClick="getMCZDocs('Search Media')" alt="[ help ]" style="vertical-align:top;">
      </cfif>
    </h2>

<form name="newMedia" method="post" action="">
  <div class="greenbox">
    <a name="kwFrm"></a>
  <p style="font-size: 14px;padding-bottom: 1em;">
      This form may not find very recent changes. You can use the also use the <a href="##relFrm">relational search form</a> below.
      </p>
      <input type="hidden" name="action" value="search">
      <input type="hidden" name="srchType" value="key">
      <label for="keyword">Keyword</label>
      <input type="text" name="keyword" id="keyword" size="40">
      <span class="rdoCtl">Match Any
      <input type="radio" name="kwType" value="any">
      </span> <span class="rdoCtl">Match All
      <input type="radio" name="kwType" value="all" checked="checked">
      </span> <span class="rdoCtl">Match Phrase
      <input type="radio" name="kwType" value="phrase">
      </span>

     <div style="margin: .5em 0 .5em 0;">
      <label for="media_uri">Media URI</label>
     <input type="text" name="media_uri" id="media_uri" size="90">
     </div>
      <div style="width: 100px;margin: .5em 0;">
        <label for="tag">Require TAG?</label>
        <input type="checkbox" id="tag" name="tag" value="1">
      </div>

      <div style="width: 420px;margin-top:.5em;">
        <div style="display: inline; width: 200px; float:left;">
          <label for="mime_type">MIME Type</label>
          <select name="mime_type" id="mime_type" multiple="multiple" size="5">
            <option value="" selected="selected">Anything</option>
            <cfloop query="ctmime_type">
              <option value="#mime_type#">#mime_type#</option>
            </cfloop>
          </select>
        </div>
        <div style="display: inline; width: 200px;margin-bottom: 1em;">
          <label for="media_type">Media Type</label>
          <select name="media_type" id="media_type" multiple="multiple" size="5" >
            <option value="" selected="selected">Anything</option>
            <cfloop query="ctmedia_type">
              <option value="#media_type#">#media_type#</option>
            </cfloop>
          </select>
        </div>
      </div>
    </div>

      <div style="clear: both;">
        <input type="submit" value="Search" class="schBtn">&nbsp;&nbsp;
        <input type="reset" value="Reset Form" class="clrBtn">
      </div>
    </form>
 <br>

    <form name="newMedia" method="post" action="">
          <div class="greenbox">
    <a name="relFrm"></a>
    <div> <p style="font-size: 14px;padding-bottom: 1em;">You can use the also use the <a href="##kwFrm">keyword search form</a> above.</p> </div>
      <input type="hidden" name="action" value="search">
      <input type="hidden" name="srchType" value="full">
      <input type="hidden" id="number_of_relations" name="number_of_relations" value="1">
      <input type="hidden" id="number_of_labels" name="number_of_labels" value="1">
       <div style="float:left;width: 750px;margin-bottom: .25em;">
      <label for="media_uri">Media URI</label>
      <input type="text" name="media_uri" id="media_uri" size="90">
      </div>
      <div style="float:left;width: 250px;padding-top:.25em;">
      <label for="mime_type">MIME Type</label>
      <select name="mime_type" id="mime_type">
        <option value=""></option>
        <cfloop query="ctmime_type">
          <option value="#mime_type#">#mime_type#</option>
        </cfloop>
      </select>
      </div>
       <div style="float:left;width: 200px;">
      <label for="media_type">Media Type</label>
      <select name="media_type" id="media_type">
        <option value=""></option>
        <cfloop query="ctmedia_type">
          <option value="#media_type#">#media_type#</option>
        </cfloop>
      </select>
      </div>
     	<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
          <div style="float:left;width: 150px;">
           <span>
               <label for "unlinked">Limit to Media not yet linked to any record.</label>
               <input type="checkbox" name="unlinked" id="unlinked" value="true">
           </span>
           </div>
        </cfif>
      <div style="clear: both;padding-top: .5em;">
      <label for="relationships">Media Relationships</label>
      <div id="relationships" class="relationship_dd">
        <select name="relationship__1" id="relationship__1" size="1" style="width: 200px;">
          <option value=""></option>
          <cfloop query="ctmedia_relationship">
            <option value="#media_relationship#">#media_relationship#</option>
          </cfloop>
        </select>: &nbsp;<input type="text" name="related_value__1" id="related_value__1" size="70">
        <input type="hidden" name="related_id__1" id="related_id__1">
        <br>
        <span class="infoLink" id="addRelationship" onclick="addRelation(2)">Add Relationship</span> </div>
        </div>
      <label for="labels" style="margin-top: .5em">Media Labels</label>
      <div id="labels" class="relationship_dd">
        <div id="labelsDiv__1">
          <select name="label__1" id="label__1" size="1" style="width: 200px;">
            <option value=""></option>
            <cfloop query="ctmedia_label">
              <option value="#media_label#">#media_label#</option>
            </cfloop>
          </select>:&nbsp;
          <input type="text" name="label_value__1" id="label_value__1" size="70">
        </div>
        <span class="infoLink" id="addLabel" onclick="addLabel(2)">Add Label</span> </div>
         </div>
      <input type="submit"
				value="Search"
				class="schBtn">&nbsp;&nbsp;
      <input type="reset"
				value="Reset Form"
				class="clrBtn">

       </form>


  </cfoutput>
</cfif>
<!----------------------------------------------------------------------------------------->
<cfif action is "search">
<cfoutput>


<cfscript>
    function highlight(findIn,replaceThis) {
    	foundAt=FindNoCase(replaceThis,findIn);
    	endAt=FindNoCase(replaceThis,findIn)+len(replaceThis);
    	if(foundAt gt 0) {
    		findIn=Insert('</span>', findIn, endAt-1);
    		findIn=Insert('<span style="background-color:yellow">', findIn, foundAt-1);
    	}
    	return findIn;
    }
</cfscript>
	<cfif isdefined("srchType") and srchType is "key">
		<cfquery name="findIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			select distinct 
				media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri, 
				CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.uri ELSE MCZBASE.get_media_dctermsrights(media.media_id) END as uri, 
				CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as display, 
				MCZBASE.is_media_encumbered(media.media_id) hideMedia,
				MCZBASE.get_media_credit(media.media_id) as credit 
				<cfif isdefined("keyword") and len(keyword) gt 0>
					,media_keywords.keywords
				</cfif>
			FROM media
				left join ctmedia_license on media.media_license_id=ctmedia_license.media_license_id
				<cfif isdefined("keyword") and len(keyword) gt 0>
					left join media_keywords on media.media_id = media_keywords.media_id
				</cfif>
			WHERE
				media.media_id > 0
				AND MCZBASE.is_media_encumbered(media.media_id) < 1
				<cfif isdefined("keyword") and len(keyword) gt 0>
					<cfif not isdefined("kwType") >
						<cfset kwType="all">
					</cfif>
					<cfif kwType EQ "phrase">
						AND upper(keywords) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(keyword)#%">
					<cfelse>
						<cfset orSep = "">
						AND (
						<cfloop list="#keyword#" index="i" delimiters=",;: ">
							<cfswitch expression="#orSep#">
								<cfcase value="OR">OR</cfcase>
								<cfcase value="AND">AND</cfcase>
								<cfdefaultcase></cfdefaultcase>
							</cfswitch>
							upper(keywords) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(i))#%">
							<cfif kwType is "any">
								<cfset orSep = "OR">
							<cfelse>
								<cfset orSep = "AND">
							</cfif>
						</cfloop>
						)
					</cfif>
				</cfif>
				<cfif isdefined("media_uri") and len(media_uri) gt 0>
					AND upper(media_uri) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(media_uri)#%">
				</cfif>
				<cfif isdefined("tag") and len(tag) gt 0>
					-- tags are not, as would be expected text, but regions of interest on images, implementation appears incomplete.
					AND media.media_id in (select media_id from tag)
				</cfif>
				<cfif isdefined("media_type") and len(media_type) gt 0>
					AND media_type in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_type#" list="yes">)
				</cfif>
				<cfif isdefined("media_id") and len(#media_id#) gt 0>
					AND media.media_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#" list="yes">)
				</cfif>
				<cfif isdefined("mime_type") and len(#mime_type#) gt 0>
					AND mime_type in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#" list="yes">)
				</cfif>
				AND rownum <=500
		</cfquery>
	<cfelse>
		<cfif not isdefined("number_of_relations")>
			<cfif (isdefined("relationship") and len(relationship) gt 0) or (isdefined("related_to") and len(related_to) gt 0)>
				<cfset number_of_relations=1>
				<cfif isdefined("relationship") and len(relationship) gt 0>
					<cfset relationship__1=relationship>
				</cfif>
				<cfif isdefined("related_to") and len(related_to) gt 0>
					<cfset related_value__1=related_to>
				</cfif>
			<cfelse>
				<cfset number_of_relations=1>
			</cfif>
		</cfif>
	   <cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
			<cfif isdefined("unlinked") and unlinked EQ "true">
				<cfset number_of_relations = 0 >
      	</cfif>
      </cfif>
		<cfif not isdefined("number_of_labels")>
			<cfif (isdefined("label") and len(label) gt 0) or (isdefined("label__1") and len(label__1) gt 0)>
				<cfset number_of_labels=1>
				<cfif isdefined("label") and len(label) gt 0>
					<cfset label__1=label>
				</cfif>
				<cfif isdefined("label_value") and len(label_value) gt 0>
					<cfset label_value__1=label_value>
				</cfif>
			<cfelse>
				<cfset number_of_labels=0>
			</cfif>
		</cfif>
		<cfquery name="findIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT distinct 
				media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri, 
				CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.uri ELSE MCZBASE.get_media_dctermsrights(media.media_id) END as uri, 
				CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as display, 
				MCZBASE.is_media_encumbered(media.media_id) hideMedia, 
				MCZBASE.get_media_credit(media.media_id) as credit 
			FROM media
				left join ctmedia_license on media.media_license_id=ctmedia_license.media_license_id
				<cfif number_of_relations EQ 0>
				   left join media_relations media_relations0 on media.media_id=media_relations0.media_id
				<cfelseif number_of_relations GT 0>
					<cfloop from="1" to="#number_of_relations#" index="n">
		    			left join media_relations media_relations#n# on media.media_id=media_relations#n#.media_id 
					</cfloop>
				</cfif>
				<cfloop from="1" to="#number_of_labels#" index="n">
					left join media_labels media_labels#n# on media.media_id=media_labels#n#.media_id
				</cfloop>
			WHERE
				 media.media_id > 0
				 AND MCZBASE.is_media_encumbered(media.media_id)  < 1 
				<cfif isdefined("media_uri") and len(media_uri) gt 0>
					AND upper(media_uri) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(media_uri)#%">
				</cfif>
				<cfif isdefined("media_type") and len(media_type) gt 0>
					AND upper(media_type) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(media_type)#%">
				</cfif>
				<cfif isdefined("mime_type") and len(#mime_type#) gt 0>
					AND mime_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#">
				</cfif>
				<cfif isdefined("tag") and len(tag) gt 0>
					AND media.media_id in (select media_id from tag)
				</cfif>
				<cfif isdefined("media_id") and len(media_id) gt 0>
					AND media.media_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#" list="yes">)
				</cfif>
				<cfif number_of_relations EQ 0>
           		<cfset n = 0>
					AND media_relations0.media_id is null
				<cfelseif number_of_relations GT 0>
					<cfloop from="1" to="#number_of_relations#" index="n">
						<cftry>
				        <cfset thisRelationship = #evaluate("relationship__" & n)#>
						   <cfcatch><cfset thisRelationship = ""></cfcatch>
		   			</cftry>
		    			<cftry>
		        			<cfset thisRelatedItem = #evaluate("related_value__" & n)#>
			    			<cfcatch><cfset thisRelatedItem = ""></cfcatch>
		    			</cftry>
		    			<cftry>
		         		<cfset thisRelatedKey = #evaluate("related_primary_key__" & n)#>
			   	 		<cfcatch><cfset thisRelatedKey = ""></cfcatch>
		    			</cftry>
						<cfif len(#thisRelationship#) gt 0>
							AND media_relations#n#.media_relationship like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#thisRelationship#%">
						</cfif>
						<cfif len(#thisRelatedItem#) gt 0>
							AND upper(media_relation_summary(media_relations#n#.media_relations_id)) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(thisRelatedItem)#%">
						</cfif>
			    		<cfif len(#thisRelatedKey#) gt 0>
							AND media_relations#n#.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisRelatedKey#">
						</cfif>
					</cfloop>
				</cfif>
				<cfloop from="1" to="#number_of_labels#" index="n">
					<cftry>
		   	   	<cfset thisLabel = #evaluate("label__" & n)#>
			   		<cfcatch><cfset thisLabel = ""></cfcatch>
	        		</cftry>
	        		<cftry>
		        		<cfset thisLabelValue = #evaluate("label_value__" & n)#>
			    		<cfcatch><cfset thisLabelValue = ""></cfcatch>
					</cftry>
	        		<cfif len(#thisLabel#) gt 0>
						AND media_labels#n#.media_label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisLabel#">
					</cfif>
					<cfif len(#thisLabelValue#) gt 0>
						AND upper(media_labels#n#.label_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(thisLabelValue)#%">
					</cfif>
					<cfif oneOfUs EQ 0>
						AND media_labels#n#.media_label <> 'internal remarks'
					</cfif>
				</cfloop>
			AND rownum <=500
		</cfquery>
	</cfif><!--- end srchType --->
	<cfif findIDs.recordcount is 0>
		<div class="error">Nothing found.</div>
		<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
			Not seeing something you just loaded? Come back in an hour when the cache has refreshed.
		</cfif>

		<cfabort>
	<cfelseif findIDs.recordcount is 1 and not listfindnocase(cgi.REDIRECT_URL,'media',"/") and not  isdefined("specID") >
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfheader name="Location" value="/media/#findIDs.media_id#">
		<cfabort>
	<cfelse>
		<cfset title="Media Results: #findIDs.recordcount# records found">
		<cfset metaDesc="Results of Media search: #findIDs.recordcount# records found.">
		<cfif findIDs.recordcount is 500>
			<div style="border:2px solid red;text-align:center;margin:0 10em;">
				Note: This form will return a maximum of 500 records.
			</div>
		</cfif>
		<a href="/MediaSearch.cfm">[ Media Search ]</a>
	</cfif>
	<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
		<cfset h="/media.cfm?action=newMedia">
		<cfif isdefined("url.relationship__1") and isdefined("url.related_primary_key__1")>
			<cfif url.relationship__1 is "cataloged_item">
				<cfset h=h & '&collection_object_id=#url.related_primary_key__1#'>
				( find Media and pick an item to link to existing Media )
				<br>
			</cfif>
		</cfif>
	<!---   	<cfif not isdefined("createSpecimenMediaShown")>
			<a href="#h#">[ Create media ]</a>
		</cfif>--->
	</cfif>
	<cfset q="">
	<cfloop list="#StructKeyList(form)#" index="key">
		<cfif len(form[key]) gt 0 and key is not "FIELDNAMES" and key is not "offset">
			<cfset q=listappend(q,"#key#=#form[key]#","&")>
		 </cfif>
	</cfloop>
	<cfloop list="#StructKeyList(url)#" index="key">
		 <cfif len(url[key]) gt 0 and key is not "FIELDNAMES" and key is not "offset">
			<cfset q=listappend(q,"#key#=#url[key]#","&")>
		 </cfif>
	</cfloop>
        <br><br>
         <h3>Media Search Results</h3>
	<cfsavecontent variable="pager">
		<cfset Result_Per_Page=10>
		<cfset Total_Records=findIDs.recordcount>
		<cfparam name="URL.offset" default="0">
		<cfparam name="limit" default="1">
		<cfset limit=URL.offset+Result_Per_Page>
		<cfset start_result=URL.offset+1>

		<cfif findIDs.recordcount gt 1>

			Showing results #start_result# -
			<cfif limit GT Total_Records> #Total_Records# <cfelse> #limit# </cfif> of #Total_Records#

			<cfset URL.offset=URL.offset+1>
			<cfif Total_Records GT Result_Per_Page>
				<br>
				<cfif URL.offset GT Result_Per_Page>
					<cfset prev_link=URL.offset-Result_Per_Page-1>
					<a href="#cgi.script_name#?offset=#prev_link#&#q#">PREV</a>
				</cfif>
				<cfset Total_Pages=ceiling(Total_Records/Result_Per_Page)>
				<cfloop index="i" from="1" to="#Total_Pages#">
					<cfset j=i-1>
					<cfset offset_value=j*Result_Per_Page>
					<cfif offset_value EQ URL.offset-1 >
						#i#
					<cfelse>
						<a href="#cgi.script_name#?offset=#offset_value#&#q#">#i#</a>
					</cfif>
				</cfloop>
				<cfif limit LT Total_Records>
					<cfset next_link=URL.offset+Result_Per_Page-1>
					<a href="#cgi.script_name#?offset=#next_link#&#q#">NEXT</a>
				</cfif>
			</cfif>

		</cfif>
	</cfsavecontent>
     <div class="mediaPager">
	#pager#
   </div>
	<cfset rownum=1>
	<cfif url.offset is 0><cfset url.offset=1></cfif>



<table width="100%;" class="mediaTableRes">

<cfloop query="findIDs" startrow="#URL.offset#" endrow="#limit#">
	<cfquery name="labels_raw"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select
			media_label,
			label_value,
			agent_name
		from
			media_labels
			left join preferred_agent_name on media_labels.assigned_by_agent_id=preferred_agent_name.agent_id
		where
			media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
         and media_label <> 'credit'  -- obtained in the findIDs query.
		   <cfif oneOfUs EQ 0>
		    	and media_label <> 'internal remarks'
		   </cfif>
	</cfquery>
	<cfquery name="labels" dbtype="query">
		select media_label,label_value 
		from labels_raw 
		where media_label != 'description'
	</cfquery>
	<cfquery name="desc" dbtype="query">
		select label_value 
		from labels_raw 
		where media_label='description'
	</cfquery>
	<cfif isdefined("findIDs.keywords")>
		<cfquery name="kw" dbtype="query">
			select keywords 
			from findIDs 
			where media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		</cfquery>
	</cfif>
	<cfset alt="#media_uri#">
	<cfquery name="alt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select mczbase.get_media_descriptor(media_id) media_descriptor from media 
		where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL"value="#media_id#"> 
	</cfquery> 
	<cfset altText = alt.media_descriptor>
	<cfif desc.recordcount is 1>
		<cfif findIDs.recordcount is 1>
			<cfset title = desc.label_value>
			<cfset metaDesc = "#desc.label_value# for #media_type# (#mime_type#)">
		</cfif>
		<cfset alt=desc.label_value>
	</cfif>
	<tr #iif(rownum MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
		<td>
			<cfset mp=getMediaPreview(preview_uri,media_type)>
            <table>
				<tr>
					<td align="middle" style="padding-right:20px;width:300px;">
						<a href="#media_uri#" target="_blank"><img src="#mp#" alt="#altText#" style="max-width:250px;max-height:250px;"></a>
						<br><span style='font-size:small'>#media_type#&nbsp;(#mime_type#)</span>
						<cfif len(display) gt 0>
							<br><span style='font-size:small'>License: <a href="#uri#" target="_blank" class="external">#display#</a></span>
						<cfelse>
							<br><span style='font-size:small'>unlicensed</span>
						</cfif>
						<cfif #media_type# eq "image">
							<br><span style='font-size:small'><a href="/MediaSet.cfm?media_id=#media_id#">Related images</a></span>
						</cfif>
						<cfif #media_type# eq "audio">
							<!--- check for a transcript, link if present --->
							<cfquery name="checkForTranscript" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT
									transcript.media_uri as transcript_uri
									transcript.media_id as trainscript_media_id
								FROM
									media_relations
									left join media transcript on media_relations.related_primary_key = transcript.media_id
								WHERE
									media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL"value="#media_id#"> 
									and media_relationship = 'transcript of audio media'
							</cfquery>
							<br><span style='font-size:small'><a href="#transcript_uri#">View Transcript</a></span>
						</cfif>
					</td>
					<td>
						<cfif len(desc.label_value) gt 0>
							<ul><li>#desc.label_value#</li></ul>
						</cfif>
						<cfif labels.recordcount gt 0>
							<ul>
								<cfloop query="labels">
									<li>
										#media_label#: #label_value#
									</li>
								</cfloop>
								<cfif len(credit) gt 0>
								    <li>credit: #credit#</li>
								</cfif>
							</ul>
						</cfif>
						<cfset mrel=getMediaRelations(#media_id#)>
						<cfif mrel.recordcount gt 0>
							<ul>
							<cfloop query="mrel">
								<li>#media_relationship#
				                    <cfif len(#link#) gt 0>
				                        <a href="#link#" target="_blank">#summary#</a>
				                    <cfelse>
										#summary#
									</cfif>
				             </li>
							</cfloop>
							</ul>
						</cfif>
						<cfif isdefined("kw.keywords") and len(kw.keywords) gt 0>
							<cfif isdefined("keyword") and len(keyword) gt 0>
								<cfset kwds=kw.keywords>
								<cfloop list="#keyword#" index="k" delimiters=",;: ">
									<cfset kwds=highlight(kwds,k)>
								</cfloop>
							<cfelse>
								<cfset kwds=kw.keywords>
							</cfif>
							<div style="font-size:small;max-width:55em;margin-left:0em;margin-top:1em;border:1px solid black;padding:4px;">
								<strong>Keywords:</strong> #kwds#
							</div>
						</cfif>
					</td>
				</tr>
			</table>
			<cfquery name="tag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select count(*) n 
				from tag 
				where media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			</cfquery>
			<br>
			<cfif media_type is "multi-page document">
				<a href="/document.cfm?media_id=#media_id#">[ view as document ]</a>
			</cfif>
			<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
		        <div class="mediaEdit"><a href="/media.cfm?action=edit&media_id=#media_id#">[ edit ]</a>
                    <a href="/TAG.cfm?media_id=#media_id#">[ add or edit TAGs ]</a></div>
		    </cfif>
		    <cfif tag.n gt 0>
                <div class="mediaEdit"><a href="/showTAG.cfm?media_id=#media_id#">[ View #tag.n# TAGs ]</a></div>
			</cfif>
			<cfquery name="relM" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					media.media_id,
					media.media_type,
					media.mime_type,
					media.preview_uri,
					media.media_uri
				from
					media,
					media_relations
				where
					media.media_id=media_relations.related_primary_key and
					media_relationship like '% media'
					and media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
					and media.media_id != <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				UNION
				select media.media_id, media.media_type,
					media.mime_type, media.preview_uri, media.media_uri
				from media, media_relations
				where
					media.media_id=media_relations.media_id and
					media_relationship like '% media' and
					media_relations.related_primary_key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
					 and media.media_id != <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			</cfquery>
			<cfif relM.recordcount gt 0>
				<br>Related Media
				<div class="thumbs">
					<div class="thumb_spcr">&nbsp;</div>
					<cfloop query="relM">
						<cfset puri=getMediaPreview(preview_uri,media_type)>
		            	<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select
									media_label,
									label_value
								from
									media_labels
								where
									media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
							</cfquery>
						<cfquery name="desc" dbtype="query">
							select label_value from labels where media_label='description'
						</cfquery>
						<cfset alt="Media Preview Image">
						<cfif desc.recordcount is 1>
							<cfset alt=desc.label_value>
						</cfif>
		               <div class="one_thumb">
			               <a href="#media_uri#" target="_blank"><img src="#getMediaPreview(preview_uri,media_type)#" alt="#altText#" class="theThumb"></a>
		                   	<p>
								#media_type# (#mime_type#)
			                   	<br><a href="/media/#media_id#">Media Details</a>
								<br>#alt#
							</p>
						</div>
					</cfloop>
					<div class="thumb_spcr">&nbsp;</div>
				</div>
			</cfif>
		</td>
	</tr>
	<cfset rownum=rownum+1>
</cfloop>
</table>


     <div class="mediaPager">
#pager#
 </div>
</cfoutput>

</cfif>
                        </div>
<cfinclude template="/includes/_footer.cfm">
