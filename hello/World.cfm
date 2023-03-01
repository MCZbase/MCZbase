<!--

* /hello/World.cfm

Copyright 2022 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

* Demonstration of ajax patterns in MCZbase.

-->
<cfset pageTitle="Ajax Demonstration">
<cfinclude template="/shared/_header.cfm">

<!--- Script includes are normally in shared/_header.cfm, but in one-off non-reused, can be in the page --->
<script type="text/javascript" src="/hello/js/hello.js"></script>

<!--- Put the getCounterHtml function in scope, so that it can be invoked directly in this page --->
<cfinclude template="/hello/component/functions.cfc">

<cfset param = "param in page">
<cfset id_for_counter = "counterElement">
<cfset id_for_dialog = "textDialogDiv">

<cfoutput>
	<main id="content" class="container-fluid">
		<div class="row">
			<div class="col-12">
				<cfset counterBlockContent= getCounterHtml(parameter="#param#",other_parameter="param in call from page",id_for_counter="#id_for_counter#",id_for_dialog="#id_for_dialog#")>
				<div id="counterBlock">
					#counterBlockContent#
				</div>
				<div id="#id_for_dialog#"></div>
			</div>
		</div>
		<div class="row">
			<div class="col-12">
				<!---  invoke the loadHello function to just do a ajax replace of the counterBlock --->
				<button class="btn btn-primary btn-xs" onClick="loadHello('counterBlock','#param#','param in reload button','#id_for_counter#','#id_for_dialog#');">Reload counterBlock</button> 

				<!--- invoke the increment counter function with the doReload function as a callback --->
				<button class="btn btn-primary btn-xs" onClick="incrementCounters(doReload);">Increment Counter and Reload</button> 

				<!--- invoke the increment counter function to replace the html of an element with the id of the counter element (also provided as a parameter to getCounterHtml()) --->
				<button class="btn btn-primary btn-xs" onClick="incrementCountersUpdate('#id_for_counter#');">Increment Counter</button> 
			</div>
		</div>
		<script>
			function doReload() { 
				console.log("doReload() invoked");
				loadHello('counterBlock','#param#','param in doReload','#id_for_counter#',"#id_for_dialog#");
			}
		</script> 
	</main>
</cfoutput>
<style>
.card-body {
	border: 1px solid black;
	width: 800px;
	height: 800px;
	z-index: 2;
	margin-left: 2rem;
	position: relative;
}
img.zoom {
	transition-timing-function: ease-in-out;
	height: 76px;
	width: 76px;
	margin: 0;
	position: relative;
	background-image: none;
}
.zoom:hover {
	-ms-transform: scale(4);
	-webkit-transform: scale(4);
	transform: scale(4); 
	transform-origin: 0 0;
	position: relative;
	z-index: 5;
}
</style>
</head>
<body>

<h1>Zoom on Hover</h1>
<p>Hover over the div element.</p>
<!---<div id="container">  
<div ><img class="zoom" src="https://iiif.mcz.harvard.edu/iiif/3/herpetology%2Flarge%2FA15810_O_floresiana_P_v.jpg/full/^1000,/0/default.jpg"></div>
</div>--->
<div class="accordion" id="accordionMedia">
						<div class="card mb-2 bg-light">
							<div id="mediaDialog"></div>
							<div class="card-header" id="headingMedia">
								<h3 class="h5 my-0 text-dark">
									<button type="button" class="headerLnk text-left h-100 w-100" aria-label="mediaPane" data-toggle="collapse" data-target="#mediaPane" aria-expanded="true" aria-controls="mediaPane" title="media">
										Media
										<span class="text-dark">(5)</span>
									</button>
									
										<a role="button" href="javascript:void(0)" class="btn btn-xs small py-0 anchorFocus" id="btn_pane" onclick="openEditMediaDialog(3255031,'mediaDialog','MCZ:Ent:PALE-1',reloadMedia)">Add/Remove</a>
									
								</h3>
							</div>
				<div id="mediaPane" class="collapse show" aria-labelledby="headingMedia" data-parent="#accordionMedia">
					<div class="card-body" id="specimenMediaCardBody">
						<div class="col-12 col-lg-6 px-1 mb-1 px-md-1 py-1 float-left">
							<div id="mediaBlock292861">
								<div class="media_widget img-magnifier-container p-1" style="min-height:100px;">
									<a href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_holotype.jpg/full/max/0/default.jpg" class="d-block mb-1 w-100 active text-center" title="click to access media">
										<img id="MID292861" src="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_holotype.jpg/full/^350,/0/default.jpg" class="zoom" alt="Media type: image;   Entomology PALE-1" height="auto" style="height: 76px;margin: 0 auto;width:auto;" title="Click for full image"></a><div class="mt-0 col-12 pb-2 px-0">
									<p class="text-center px-1 pb-0 mb-0 small col-12">
										<span class="d-inline">(<a href="/media.cfm?action=edit&amp;media_id=292861">Edit</a>) </span>(<a class="" href="/media/292861">Media Record</a>) (<a class="" href="/media/RelatedMedia.cfm?media_id=292861">Related</a>) (<a class="" href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_holotype.jpg/full/max/0/default.jpg">Full</a>)
									</p><div class="py-1"><p class="text-center col-12 my-0 p-0 small"> MCZ:Ent:PALE-1 Prodryas persephone  Holotype 
									</p>
								</div>
							</div>
						</div> 
					</div>
				</div>
					
						<div class="col-12 col-lg-6 px-1 mb-1 px-md-1 py-1 float-left">
							
							<div id="mediaBlock108503">
								<div class="media_widget img-magnifier-container p-1" style="min-height:100px;"><a href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_full.jpg/full/max/0/default.jpg" class="d-block mb-1 w-100 active text-center" title="click to access media">
									<img id="MID108503" src="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_full.jpg/full/^350,/0/default.jpg" class="zoom" alt="Media type: image;   Entomology PALE-1 Aspect: full" height="auto" style="height: 76px;margin: 0 auto;width:auto;" title="Click for full image"></a><div class="mt-0 col-12 pb-2 px-0"><p class="text-center px-1 pb-0 mb-0 small col-12"><span class="d-inline">(<a href="/media.cfm?action=edit&amp;media_id=108503">Edit</a>) </span>(<a class="" href="/media/108503">Media Record</a>) (<a class="" href="/media/RelatedMedia.cfm?media_id=108503">Related</a>) (<a class="" href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_full.jpg/full/max/0/default.jpg">Full</a>)</p><div class="py-1"><p class="text-center col-12 my-0 p-0 small"> MCZ:Ent:PALE-1 Prodryas persephone  Holotype  <dfn>Aspect:</dfn> full </p></div></div></div> 
							</div>
						</div>
					
						<div class="col-12 col-lg-6 px-1 mb-1 px-md-1 py-1 float-left">
							
							<div id="mediaBlock108500">
								<div class="media_widget img-magnifier-container p-1" style="min-height:100px;"><a href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail2.jpg/full/max/0/default.jpg" class="d-block mb-1 w-100 active text-center" title="click to access media">
									<img id="MID108500" src="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail2.jpg/full/^350,/0/default.jpg" class="zoom" alt="Media type: image;   Entomology PALE-1 Aspect: detail" height="auto" style="height: 76px;margin: 0 auto;width:auto;" title="Click for full image"></a><div class="mt-0 col-12 pb-2 px-0"><p class="text-center px-1 pb-0 mb-0 small col-12"><span class="d-inline">(<a href="/media.cfm?action=edit&amp;media_id=108500">Edit</a>) </span>(<a class="" href="/media/108500">Media Record</a>) (<a class="" href="/media/RelatedMedia.cfm?media_id=108500">Related</a>) (<a class="" href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail2.jpg/full/max/0/default.jpg">Full</a>)</p><div class="py-1"><p class="text-center col-12 my-0 p-0 small"> MCZ:Ent:PALE-1 Prodryas persephone  Holotype  <dfn>Aspect:</dfn> detail </p></div></div></div> 
							</div>
						</div>
					
						<div class="col-12 col-lg-6 px-1 mb-1 px-md-1 py-1 float-left">
							
							<div id="mediaBlock108502">
								<div class="media_widget img-magnifier-container p-1" style="min-height:100px;">
									<a href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail.jpg/full/max/0/default.jpg" class="d-block mb-1 w-100 active text-center" title="click to access media">
										<img id="MID108502" src="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail.jpg/full/^350,/0/default.jpg" class="zoom" alt="Media type: image;   Entomology PALE-1 Aspect: detail" height="auto" style="height: 76px;margin: 0 auto;width:auto;" title="Click for full image">
									</a>
									<div class="mt-0 col-12 pb-2 px-0"><p class="text-center px-1 pb-0 mb-0 small col-12">
									<span class="d-inline">(<a href="/media.cfm?action=edit&amp;media_id=108502">Edit</a>) </span>(<a class="" href="/media/108502">Media Record</a>) (<a class="" href="/media/RelatedMedia.cfm?media_id=108502">Related</a>) (<a class="" href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail.jpg/full/max/0/default.jpg">Full</a>)</p><div class="py-1"><p class="text-center col-12 my-0 p-0 small"> MCZ:Ent:PALE-1 Prodryas persephone  Holotype  <dfn>Aspect:</dfn> detail </p>
									</div>
									</div>
								</div> 
							</div>
						</div>
					
						<div class="col-12 col-lg-6 px-1 mb-1 px-md-1 py-1 float-left">
							
							<div id="mediaBlock108501">
								<div class="media_widget img-magnifier-container p-1" style="min-height:100px;"><a href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail3.jpg/full/max/0/default.jpg" class="d-block mb-1 w-100 active text-center" title="click to access media"><img id="MID108501" src="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail3.jpg/full/^350,/0/default.jpg" class="zoom" alt="Media type: image;   Entomology PALE-1 Aspect: detail" height="auto" style="height: 76px;margin: 0 auto;width:auto;" title="Click for full image"></a><div class="mt-0 col-12 pb-2 px-0"><p class="text-center px-1 pb-0 mb-0 small col-12"><span class="d-inline">(<a href="/media.cfm?action=edit&amp;media_id=108501">Edit</a>) </span>(<a class="" href="/media/108501">Media Record</a>) (<a class="" href="/media/RelatedMedia.cfm?media_id=108501">Related</a>) (<a class="" href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail3.jpg/full/max/0/default.jpg">Full</a>)</p><div class="py-1"><p class="text-center col-12 my-0 p-0 small"> MCZ:Ent:PALE-1 Prodryas persephone  Holotype  <dfn>Aspect:</dfn> detail </p></div></div></div> 
							</div>
						</div>
					
								</div>
							</div>
						</div>
					</div>
<cfinclude template="/shared/_footer.cfm">
