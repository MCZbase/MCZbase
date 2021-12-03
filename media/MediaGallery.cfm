<cfset pageTitle = "Media Gallery">
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/media/component/search.cfc" runOnce="true">



	<div class="container-fluid">
		<div class="row my-3">
<cfoutput>
		<cfset media_id = "90914">
			<cfset mediablock= getMediaResponsiveBlockHtml(media_id="#media_id#")>
			<div class="col-5">
				<div id="mediaResponsiveBlockHtml">
					#mediablock#
				</div>
			</div>
			
			<div class="col-3">
				<div id="mediaResponsiveBlockHtml">
					#mediablock#
				</div>
			</div>
			
			<div class="col-2">
				<div id="mediaResponseiveBlockHtml">
					#mediablock#
				</div>
			</div>
				
			<div class="col-1 p-0">
				<div id="mediaResponsiveBlockHtml">
					#mediablock#
				</div>
			</div>
</output>
	
<cfoutput>
		<cfset media_id = "1333">
			<cfset mediablock= getMediaBlockHtml(media_id="#media_id#")>
			<div class="col-5">
				<div id="mediaBlockHtml">
					<script>
					img.onload = function() {
  var img_width = img.width;
  var img_height = img.height;

  console.log("Original width: " + img_width + "px")
  console.log("Original height: " + img_height + "px")
  img.width = "100%""
  img.height = "100%"
  document.body.appendChild(img);
}
					</script>
					#mediablock#
				</div>
			</div>
			
			<div class="col-3">
				<div id="mediaBlockHtml">
					#mediablock#
				</div>
			</div>
			
			<div class="col-2">
				<div id="mediaBlockHtml">
					#mediablock#
				</div>
			</div>
				
			<div class="col-1 p-0">
				<div id="mediaBlockHtml">
					#mediablock#
				</div>
			</div>	
</cfoutput>
		</div>
	</div>

</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
