<cfset pageTitle = "Media Gallery">
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/media/component/search.cfc" runOnce="true">



	<div class="container-fluid">
		<div class="row my-3">
<cfoutput>
	
	<p class="col-12">[getMediaResponsiveBlockHtml] Images that are redefined with height and width attributes =100%</p>
		<cfset media_id = "1333">
			<cfset mediablock= getMediaResponsiveBlockHtml(media_id="#media_id#",displayAs="full",size="2000")>
			<div class="col-9">
				<div id="mediaResponsiveBlockHtml">
					#mediablock#
				</div>
			</div>

</cfoutput>

<cfoutput>	
	<p class="col-12 mt-4">[getMediaBlockHtml] Images that height and width are redefined with a class.</p> 
		<cfset media_id = "90914">
			<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",displayAs="thumb",size="200")>

			<div class="col-1 p-0">
				<div id="mediaBlockHtml">
					#mediablock#
				</div>
			</div>	
</cfoutput>
		</div>
	</div>



<cfinclude template = "/shared/_footer.cfm">
