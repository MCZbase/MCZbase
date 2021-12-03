<cfset pageTitle = "Media Gallery">
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/media/component/search.cfc" runOnce="true">

<cfoutput>
	<div class="container-fluid my-3">

		<cfquery name="examples" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct media_id from (
				select max(media_id) media_id from media
				group by mime_type, media_type
				union
				select max(media_id) media_id from media_relations
				group by media_relationship
				union
				select max(media_id) media_id from media
				group by media.auto_host
				having count(*) > 50
				union
				select max(media_id) from media_labels
				where media_label = 'height'
				group by label_value
				having count(*) > 1000
			)
		</cfquery>
		<div class="row">
			<cfloop query="examples">
				<div class="col-12 col-sm-6 col-md-4 col-xl-3">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="400")>
					<div class="row">
						<div class="col-12">
							<div id="mediaBlock#media_id#">
							#mediablock#
							</div>
						</div>
					</div>
				</div>
			</cfloop>
		</div>

		<div class="row">
			<cfloop query="examples">
				<div class="col-12 col-sm-4 col-md-3 col-xl-2">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",displayAs="thumb")>
					<div class="row">
						<div class="col-12">
							<div id="mediaBlock#media_id#">
							#mediablock#
							</div>
						</div>
					</div>
				</div>
			</cfloop>
		</div>

		<div class="row">
			<cfloop query="examples">
				<div class="col-12 col-md-6 col-xl-4">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="600")>
					<div class="row">
						<div class="col-12">
							<div id="mediaBlock#media_id#">
							#mediablock#
							</div>
						</div>
					</div>
				</div>
			</cfloop>
		</div>
		
		<div class="row">
			<div class="col-10 float-left">
			<p class="col-12">[getMediaResponsiveBlockHtml] FULL Images that are redefined with height and width attributes =100%</p>
			<cfset media_id = "1333">
				<cfset mediablock= getMediaResponsiveBlockHtml(media_id="#media_id#",displayAs="full",size="2000")>
				<div class="col-12">
					<div id="mediaResponsiveBlockHtml">
						#mediablock#
					</div>
				</div>
			</div>
			<div class="col-1 px-0 float-left">
			<p class="col-12 mt-4">[getMediaBlockHtml] THUMBNAIL Images that height and width are redefined with a class.</p> 
			<cfset media_id = "90914">
				<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",displayAs="thumb",size="100")>
				<div class="col-12 p-0">
					<div id="mediaBlockHtml">
						#mediablock#
					</div>
				</div>	
			</div>
		</div>

	</div>
</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
