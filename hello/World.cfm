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

<style>
.img-block {
	 display: flex;
	 justify-content: center;
	 align-items: center;
	 height: 100vh;
}
 .magnify-wrapper {
	 position: relative;
	 max-height: 50vh;
}
 .magnify-wrapper img {
	 max-height: inherit;
}
 .magnify-wrapper #large-img {
	 background: url("https://images.unsplash.com/photo-1542856204-00101eb6def4?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=975&q=80") no-repeat #fff;
	 width: 150px;
	 height: 150px;
	 box-shadow: 0 5px 10px -2px rgba(0, 0, 0, 0.3);
	 pointer-events: none;
	 position: absolute;
	 border: 4px solid #efefef;
	 z-index: 99;
	 border-radius: 100%;
	 display: block;
	 opacity: 0;
	 transition: opacity 0.2s;
}
 .magnify-wrapper:hover #large-img, .magnify-wrapper:active #large-img {
	 opacity: 1;
}
</style>


<div class="img-block">
  <div id="zoomer" class="magnify-wrapper">
	 <a href="https://images.unsplash.com/photo-1542856204-00101eb6def4?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=975&q=80" id="large-image">
    <img src="https://images.unsplash.com/photo-1542856204-00101eb6def4?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=975&q=80" id="main-img" /></a>
   <!--- <div id="large-img"></div>--->
  </div>
</div>

<script>
document.getElementById("zoomer").addEventListener(
  "mousemove",
  function (e) {
    let original = document.getElementById("main-img"),
      magnified = document.getElementById("large-img"),
      style = magnified.style,
      x = e.pageX - this.offsetLeft,
      y = e.pageY - this.offsetTop,
      imgWidth = original.width,
      imgHeight = original.height,
      xperc = (x / imgWidth) * 100,
      yperc = (y / imgHeight) * 100;
    // Add some margin for right edge
    if (x > 0.01 * imgWidth) {
      xperc += 0.15 * xperc;
    }
    // Add some margin for bottom edge
    if (y >= 0.01 * imgHeight) {
      yperc += 0.15 * yperc;
    }
    // Set the background of the magnified image horizontal
    style.backgroundPositionX = xperc - 9 + "%";
    // Set the background of the magnified image vertical
    style.backgroundPositionY = yperc - 9 + "%";

    // Move the magnifying glass with the mouse movement.
    style.left = x - 50 + "px";
    style.top = y - 50 + "px";
  },
  false
);
</script>

<cfinclude template="/shared/_footer.cfm">
