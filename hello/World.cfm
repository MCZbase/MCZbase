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
<cfset pageTitle="Ajax Demonstration & image testing">
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


</head>
<body>

<h1>Zoom on Hover - Image testing below</h1>
<p>Hover over the div element.</p>
<!---Image zoom with css and vanilla javascript below- zoom up to chosen zoom level and pan. -- it might be difficult to put background image as #variable# in css and have valid html.--->
<style>	
	#overlay9{
	border:1px solid black;
	width:350px;
	height:200px;
	display:inline-block;
	background-image:url('https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_holotype.jpg/full/max/0/default.jpg');
	background-repeat:no-repeat;
	
}
</style>
<div class="container">
	<h1>Test 1 - zoom to max image size and pan possible on hover; larger image in CSS; CSS and Vanilla JS</h1>
	<img id="imgZoom1" width="350px" height="200px" style="vertical-align: top;margin-bottom:4px;" onmousemove="zoomIn1(event)" onmouseout="zoomOut1()" src="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_holotype.jpg/full/^350,/0/default.jpg">
<div id="overlay9" onmousemove="zoomIn1(event)"></div>
</div>
<script>

	function zoomIn1(event) {
  	var element = document.getElementById("overlay9");
  	element.style.display = "inline-block";
  	var img = document.getElementById("imgZoom1");
  	var posX = event.offsetX ? (event.offsetX) : event.pageX - img.offsetLeft;
		var posY = event.offsetY ? (event.offsetY) : event.pageY - img.offsetTop;
		element.style.backgroundPosition=(-posX*2)+"px "+(-posY*4)+"px";
	}

function zoomOut1() {
  var element = document.getElementById("overlay9");
  element.style.display = "none";
}
</script>
	

<!---Test 1 Purely a css image zoom below - only one size and no pan--->	
<style>
.card-body {
	width: 400px;
	height: auto;
	margin-bottom: 2rem;
	z-index: 2;
	margin-left: 1.7rem;
	position: relative;
}
img.zoom  {
	transition-timing-function: ease-in-out;
	margin: 0;
	position: relative;
	background-image: none;
	z-index: 4;
}
img.left.zoom:hover {
	-ms-transform: scale(3);
	-webkit-transform: scale(3);
	transform: scale(3); 
	transform-origin: 0 0;
	position: relative;
	z-index: 6;
}
img.right.zoom:hover {
	-ms-transform: scale(3);
	-webkit-transform: scale(3);
	transform: scale(3); 
	transform-origin: top right;
	position: relative;
	z-index: 6;
}
* {
    -webkit-transition: all 0.25s ease-in;
    -moz-transition: all 0.25s ease-in;
    -ms-transition: all 0.25s ease-in;
    -o-transition: all 0.25s ease-in;
    transition: all 0.25s ease-in;
}
</style>
<div class="container">
	<h1 style="margin-top: 2rem;">Test 2 - zoom to chosen scale (no panning); CSS only</h1>
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
								<img id="MID292861" src="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_holotype.jpg/full/max/0/default.jpg" class="left zoom" alt="Media type: image;   Entomology PALE-1" height="auto" style="height: 76px;margin: 0 auto;width:auto;" title="Click for full image">
							</a>
							<div class="mt-0 col-12 pb-2 px-0">
								<p class="text-center px-1 pb-0 mb-0 small col-12">
									<span class="d-inline">(<a href="/media.cfm?action=edit&amp;media_id=292861">Edit</a>) </span>(<a class="" href="/media/292861">Media Record</a>) (<a class="" href="/media/RelatedMedia.cfm?media_id=292861">Related</a>) (<a class="" href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_holotype.jpg/full/max/0/default.jpg">Full</a>)
								</p>
								<div class="py-1">
									<p class="text-center col-12 my-0 p-0 small"> MCZ:Ent:PALE-1 Prodryas persephone  Holotype 
									</p>
								</div>
							</div>
						</div> 
					</div>
				</div>
				<div class="col-12 col-lg-6 px-1 mb-1 px-md-1 py-1 float-left">
					<div id="mediaBlock108503">
						<div class="media_widget img-magnifier-container p-1" style="min-height:100px;"><a href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_full.jpg/full/max/0/default.jpg" class="d-block mb-1 w-100 active text-center" title="click to access media">
							<img id="MID108503" src="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_full.jpg/full/max/0/default.jpg" class="right zoom" alt="Media type: image;   Entomology PALE-1 Aspect: full" height="auto" style="height: 76px;margin: 0 auto;width:auto;" title="Click for full image">
							</a>
							<div class="mt-0 col-12 pb-2 px-0">
								<p class="text-center px-1 pb-0 mb-0 small col-12"><span class="d-inline">(<a href="/media.cfm?action=edit&amp;media_id=108503">Edit</a>) </span>(<a class="" href="/media/108503">Media Record</a>) (<a class="" href="/media/RelatedMedia.cfm?media_id=108503">Related</a>) (<a class="" href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_full.jpg/full/max/0/default.jpg">Full</a>)</p>
								<div class="py-1"><p class="text-center col-12 my-0 p-0 small"> MCZ:Ent:PALE-1 Prodryas persephone  Holotype  <dfn>Aspect:</dfn> full </p>
								</div>
							</div>
						</div> 
					</div>
				</div>

				<div class="col-12 col-lg-6 px-1 mb-1 px-md-1 py-1 float-left">
					<div id="mediaBlock108500">
						<div class="media_widget img-magnifier-container p-1" style="min-height:100px;">
							<a href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail2.jpg/full/max/0/default.jpg" class="d-block mb-1 w-100 active text-center" title="click to access media">
							<img id="MID108500" src="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail2.jpg/full/max/0/default.jpg" class="left zoom" alt="Media type: image;   Entomology PALE-1 Aspect: detail" height="auto" style="height: 76px;margin: 0 auto;width:auto;" title="Click for full image">
							</a>
							<div class="mt-0 col-12 pb-2 px-0"><p class="text-center px-1 pb-0 mb-0 small col-12"><span class="d-inline">(<a href="/media.cfm?action=edit&amp;media_id=108500">Edit</a>) </span>(<a class="" href="/media/108500">Media Record</a>) (<a class="" href="/media/RelatedMedia.cfm?media_id=108500">Related</a>) (<a class="" href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail2.jpg/full/max/0/default.jpg">Full</a>)</p><div class="py-1"><p class="text-center col-12 my-0 p-0 small"> MCZ:Ent:PALE-1 Prodryas persephone  Holotype  <dfn>Aspect:</dfn> detail </p></div></div></div> 
					</div>
				</div>
				<div class="col-12 col-lg-6 px-1 mb-1 px-md-1 py-1 float-left">
					<div id="mediaBlock108502">
						<div class="media_widget img-magnifier-container p-1" style="min-height:100px;">
							<a href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail.jpg/full/max/0/default.jpg" class="d-block mb-1 w-100 active text-center" title="click to access media">
								<img id="MID108502" src="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail.jpg/full/max/0/default.jpg" class="right zoom" alt="Media type: image;   Entomology PALE-1 Aspect: detail" height="auto" style="height: 76px;margin: 0 auto;width:auto;" title="Click for full image">
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
						<div class="media_widget img-magnifier-container p-1" style="min-height:100px;"><a href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail3.jpg/full/max/0/default.jpg" class="d-block mb-1 w-100 active text-center" title="click to access media"><img id="MID108501" src="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail3.jpg/full/max/0/default.jpg" class="left zoom" alt="Media type: image;   Entomology PALE-1 Aspect: detail" height="auto" style="height: 76px;margin: 0 auto;width:auto;" title="Click for full image"></a><div class="mt-0 col-12 pb-2 px-0"><p class="text-center px-1 pb-0 mb-0 small col-12"><span class="d-inline">(<a href="/media.cfm?action=edit&amp;media_id=108501">Edit</a>) </span>(<a class="" href="/media/108501">Media Record</a>) (<a class="" href="/media/RelatedMedia.cfm?media_id=108501">Related</a>) (<a class="" href="https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_detail3.jpg/full/max/0/default.jpg">Full</a>)</p><div class="py-1"><p class="text-center col-12 my-0 p-0 small"> MCZ:Ent:PALE-1 Prodryas persephone  Holotype  <dfn>Aspect:</dfn> detail </p></div></div></div> 
					</div>
				</div>
			</div>
		</div>
	</div>
</div>
</div>

<!---Test 2  Image zoom with css and vanilla javascript below- zoom up to chosen zoom level and pan. -- it might be difficult to put background image as #variable# in css and have valid html.--->
<style>	
#zoomC {
  /* (A) DIMENSIONS */
  width: 600px;
  height: 338px;
 
  /* (B) BACKGROUND IMAGE */
  background: url("https://iiif.mcz.harvard.edu/iiif/3/entomology%2Fpaleo%2Flarge%2FPALE-1_Prodryas_persephone_holotype.jpg/full/max/0/default.jpg");
  background-position: center;
  background-size: cover;
}
</style>
<div class="container" style="margin-top: 2rem;">
	<h1>Test 3 - CSS & vanilla js : zoom and follow (background image in css)</h1>
	<!---image in the CSS as background//only html tag is the div with an ID--->
<div id="zoomC"></div>
</div>
<script>
// CREDITS : https://www.cssscript.com/image-zoom-pan-hover-detail-view/
var addZoom = target => {
  // (A) GET CONTAINER + IMAGE SOURCE
  let container = document.getElementById(target),
      imgsrc = container.currentStyle || window.getComputedStyle(container, false);
      imgsrc = imgsrc.backgroundImage.slice(4, -1).replace(/"/g, "");
 
  // (B) LOAD IMAGE + ATTACH ZOOM
  let img = new Image();
  img.src = imgsrc;
  img.onload = () => {
    // (B1) CALCULATE ZOOM RATIO
    let ratio = img.naturalHeight / img.naturalWidth,
        percentage = ratio * 100 + "%";
 
    // (B2) ATTACH ZOOM ON MOUSE MOVE
    container.onmousemove = e => {
      let rect = e.target.getBoundingClientRect(),
          xPos = e.clientX - rect.left,
          yPos = e.clientY - rect.top,
          xPercent = xPos / (container.clientWidth / 100) + "%",
          yPercent = yPos / ((container.clientWidth * ratio) / 100) + "%";
 
      Object.assign(container.style, {
        backgroundPosition: xPercent + " " + yPercent,
        backgroundSize: img.naturalWidth + "px"
      });
    };
 
    // (B3) RESET ZOOM ON MOUSE LEAVE
    container.onmouseleave = e => {
      Object.assign(container.style, {
        backgroundPosition: "center",
        backgroundSize: "cover"
      });
    };
  }
};
 
// (C) ATTACH FOLLOW ZOOM
window.onload = () => addZoom("zoomC");	
</script>

<style>
	
* {box-sizing: border-box;}

.img-zoom-container {
  position: relative;
}

.img-zoom-lens {
  position: absolute;
  border: 1px solid #d4d4d4;
  /*set the size of the lens:*/
  width: 40px;
  height: 40px;
}

.img-zoom-result {
  border: 1px solid #d4d4d4;
  /*set the size of the result div:*/
  width: 300px;
  height: 300px;
}
</style>
	
<script>
function imageZoom(imgID, resultID) {
  var img, lens, result, cx, cy;
  img = document.getElementById(imgID);
  result = document.getElementById(resultID);
  /* Create lens: */
  lens = document.createElement("DIV");
  lens.setAttribute("class", "img-zoom-lens");
  /* Insert lens: */
  img.parentElement.insertBefore(lens, img);
  /* Calculate the ratio between result DIV and lens: */
  cx = result.offsetWidth / lens.offsetWidth;
  cy = result.offsetHeight / lens.offsetHeight;
  /* Set background properties for the result DIV */
  result.style.backgroundImage = "url('" + img.src + "')";
  result.style.backgroundSize = (img.width * cx) + "px " + (img.height * cy) + "px";
  /* Execute a function when someone moves the cursor over the image, or the lens: */
  lens.addEventListener("mousemove", moveLens);
  img.addEventListener("mousemove", moveLens);
  /* And also for touch screens: */
  lens.addEventListener("touchmove", moveLens);
  img.addEventListener("touchmove", moveLens);
  function moveLens(e) {
    var pos, x, y;
    /* Prevent any other actions that may occur when moving over the image */
    e.preventDefault();
    /* Get the cursor's x and y positions: */
    pos = getCursorPos(e);
    /* Calculate the position of the lens: */
    x = pos.x - (lens.offsetWidth / 2);
    y = pos.y - (lens.offsetHeight / 2);
    /* Prevent the lens from being positioned outside the image: */
    if (x > img.width - lens.offsetWidth) {x = img.width - lens.offsetWidth;}
    if (x < 0) {x = 0;}
    if (y > img.height - lens.offsetHeight) {y = img.height - lens.offsetHeight;}
    if (y < 0) {y = 0;}
    /* Set the position of the lens: */
    lens.style.left = x + "px";
    lens.style.top = y + "px";
    /* Display what the lens "sees": */
    result.style.backgroundPosition = "-" + (x * cx) + "px -" + (y * cy) + "px";
  }
  function getCursorPos(e) {
    var a, x = 0, y = 0;
    e = e || window.event;
    /* Get the x and y positions of the image: */
    a = img.getBoundingClientRect();
    /* Calculate the cursor's x and y coordinates, relative to the image: */
    x = e.pageX - a.left;
    y = e.pageY - a.top;
    /* Consider any page scrolling: */
    x = x - window.pageXOffset;
    y = y - window.pageYOffset;
    return {x : x, y : y};
  }
}	
</script>
<div class="img-zoom-container">
  <img id="myimage" src="http://mczbase.mcz.harvard.edu/specimen_images/invertebrates/thumbnails/151054_Munidopsis_sp_microCT.jpg" width="300" height="240" alt="Girl">
  <div id="myresult" class="img-zoom-result"></div>
</div>
<script>
imageZoom("myimage", "myresult");
</script>


<cfinclude template="/shared/_footer.cfm">
