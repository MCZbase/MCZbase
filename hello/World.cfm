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
* {
  box-sizing: border-box;
}
#container {
border: 1px solid black;
width: 500px;
height:500px;
margin: 0 auto;
}
.zoom {
background-color: green;
transition: transform .5s;
transition-timing-function: ease-in-out;
height: 76px;
width: 76px;
}
.zoom a {display:none;}
.zoom:hover {
  -ms-transform: scale(8); /* IE 9 */
  -webkit-transform: scale(8); /* Safari 3-8 */
  transform: scale(8); 
transform-origin: 0 0;
 background-image: url(https://iiif.mcz.harvard.edu/iiif/3/herpetology%2Flarge%2FA15810_O_floresiana_P_v.jpg/full/^1000,/0/default.jpg);
      }
}
</style>
</head>
<body>

<h1>Zoom on Hover</h1>
<p>Hover over the div element.</p>
<div id="container">  
<div ><img class="zoom" src="https://iiif.mcz.harvard.edu/iiif/3/herpetology%2Flarge%2FA15810_O_floresiana_P_v.jpg/full/^1000,/0/default.jpg"></div>
</div>

<cfinclude template="/shared/_footer.cfm">
