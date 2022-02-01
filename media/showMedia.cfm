<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfset pageTitle = "Media Record">
<cfinclude template = "/shared/_header.cfm">
<cfset title="Media">
<cfset metaDesc="Locate Media, including audio (sound recordings), video (movies), and images (pictures) of specimens, collecting sites, habitat, collectors, and more.">
<cfif isdefined("url.collection_object_id")>
<cfset action="search">
<cfset relationship__1="cataloged_item">
<cfset url.relationship__1="cataloged_item">
<cfset related_primary_key__1="#url.collection_object_id#">
<cfset url.related_primary_key__1="#url.collection_object_id#">
<cfset specID="#url.collection_object_id#">
</cfif>
<script type='text/javascript' src='/includes/media.js'></script>
<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
	<cfoutput>
		<a class="toplinks" href="/media.cfm?action=newMedia">[ Create Media ]</a>
	</cfoutput>
</cfif>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>

<!----------------------------------------------------------------------------------------->
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
		<a href="/MediaSearch.cfm" class="btn btn-xs btn-primary">Media Search</a>
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
<main id="content" class="container mt-5">
	<section class="row">
		<div class="col-12">
			<div class="col-3 float-left"><h1>Media</h1></div>
			<div class="col-9 float-left"><button class="btn btn-xs btn-primary ml-auto">Media Viewer</button></div>
		</div>
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
			and media_label <> 'credit'
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
		<div class="col-12 px-0">
			<div class="row">
				<div class="col-12 col-md-5">
					<cfif len(findIDs.media_id) gt 0>
						<cfset mediablock= getMediaBlockHtml(media_id="#findIDs.media_id#",displayAs="full",size="400",captionAs="textFull")>
							<div class="float-left" id="mediaBlock#findIDs.media_id#">
								#mediablock#
							</div>
					</cfif>
				</div>				
				<div class="col-12 col-md-7">
					<cfif #media_type# eq "image">
						<br><span style='font-size:small'><a href="/MediaSet.cfm?media_id=#media_id#"></a></span>
					</cfif>
					<cfif #media_type# eq "audio">
						<!--- check for a transcript, link if present --->
						<cfquery name="checkForTranscript" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT
								transcript.media_uri as transcript_uri,
								transcript.media_id as trainscript_media_id
							FROM
								media_relations
								left join media transcript on media_relations.related_primary_key = transcript.media_id
							WHERE
								media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL"value="#media_id#"> 
								and media_relationship = 'transcript for audio media'
								and MCZBASE.is_media_encumbered(transcript.media_id) < 1
						</cfquery>
						<cfif checkforTranscript.recordcount GT 0>
							<cfloop query="checkForTranscript">
								<br><span style='font-size:small'><a href="#transcript_uri#">View Transcript</a></span>
							</cfloop>
						</cfif>
					</cfif>
					<cfif len(desc.label_value) gt 0>
						<ul class="list-group"><li class="list-group-item">#desc.label_value#</li></ul>
					</cfif>
					<cfif labels.recordcount gt 0>
						<ul class="list-group">
							<cfloop query="labels">
								<li class="list-group-item">
									#media_label#: #label_value#
								</li>
							</cfloop>
							<cfif len(credit) gt 0>
							<li class="list-group-item">credit: #credit#</li>
							</cfif>
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
						<div style="">
							<strong>Keywords:</strong> #kwds#
						</div>
					</cfif>

					<cfif media_type is "multi-page document">
						<a href="/document.cfm?media_id=#media_id#">[ view as document ]</a>
					</cfif>
				</div>
			</div>
			<div class="row">
				<div class="col-12 px-0 related">
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
					Related Media
					<div class="thumbs">
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
								<a href="#media_uri#" target="_blank">
									<img src="#getMediaPreview(preview_uri,media_type)#" alt="#altText#" class="theThumb">
								</a>
								<p>
									#media_type# (#mime_type#)
									<a href="/media/#media_id#">Media Details</a>
									#alt#
								</p>
							</div>
						</cfloop>
					</div>
				</cfif>
				</div>
			</div>
		</div>
		<div class="mediaPager">
		#pager#
		</div>
	<cfset rownum=rownum+1>
</cfloop>

</cfoutput>
</cfif>
	</section>
</main>
<!---

		<div class="col-12 col-md-6">
			<cfloop query="findMedia">
				<cfquery name="images" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT media_id,related_primary_key, collection_object_id 
					FROM media_relations, flat 
					WHERE media_relationship = 'shows cataloged_item' 
					AND flat.collection_object_id = media_relations.RELATED_PRIMARY_KEY
					AND media_id = '#findMedia.media_id#'
				</cfquery>
				<cfif len(#findMedia.description#)gt 0>
					<div class="col-12 col-md-3 px-1 float-left my-1">
						<div class="border rounded bg-white p-2 col-12 float-left">
							<div class="row mx-0">
								<cfif len(images.media_id) gt 0>
									<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",displayAs="full",size="400",captionAs="textFull")>
										<div class="float-left" id="mediaBlock#images.media_id#">
											#mediablock#
										</div>
								</cfif>
							</div>
						</div>
					</div>
				</cfif>
			</cfloop>
		</div>
		</div>
		<div class="col-12 col-md-6">
		metadata
		</div>


	<section class="row">
		<div class="col-12">
			<h3 class="h4">In catalog records</h3>
			<div class="col-12 px-0">
				Grid search results (like showNamedCollection)
			</div>
		</div>
		<div class="col-12">
			<h3 class="h4">In transaction records</h3>
			<div class="col-12 px-0">
				Grid search results (like showNamedCollection)
			</div>
		</div>
	</section>
--->
	
	
<cfinclude template = "/shared/_footer.cfm">