<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfset pageTitle = "Media Record">
<cfinclude template = "/shared/_header.cfm">
<cfset media_id = 1333>
<cfquery name="findMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
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

<main id="content" class="container mt-5">
	<section class="row">
		<div class="col-6">
			<h1>Media<button class="btn btn-xs btn-primary ml-auto">Media Viewer</button></h1>
			
		</div>
		<div class="col-12 col-md-6">
			<cfif len(findMedia.media_id) gt 0>
				<cfset mediablock= getMediaBlockHtml(media_id="#findMedia.media_id#",displayAs="full",captionAs="textFull")>
				<div class="float-left" id="mediaBlock#findMedia.media_id#">
					#mediablock#
				</div>
			</cfif>
		</div>
		<div class="col-12 col-md-6">
		metadata
		</div>
	</section>

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
</main>
	
	
<cfinclude template = "/shared/_footer.cfm">