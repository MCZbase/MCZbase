<!--
media/Media.cfm

media record editor

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2022 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->

<cfinclude template="/media/component/functions.cfc" runOnce="true"><!--- for autocompletes --->
<cfinclude template="/media/component/public.cfc" runOnce="true"><!--- for media widget --->

<cfif NOT isdefined("action")>
	<cfset action="new">
	<cfset pageTitle = "New Shared Drive Media">
</cfif>
<cfif isdefined("action") AND action EQ 'new'>
	<cfset pageTitle = "New Shared Drive Media">
</cfif>
<cfif isdefined("action") AND action EQ 'newMedia'>
	<cfset pageTitle = "New Shared Drive Media Metadata">
</cfif>
<cfif isdefined("action") AND action EQ 'edit'>
	<cfset action="edit">
	<cfset pageTitle = "Edit Media">
</cfif>
	

<cfinclude template = "/shared/_header.cfm">
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select COLLECTION_CDE, COLLECTION from collection order by collection
</cfquery>
<cfquery name="ctmedia_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select media_relationship from ctmedia_relationship order by media_relationship
</cfquery>
<cfquery name="ctmedia_label" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select media_label from ctmedia_label order by media_label
</cfquery>
<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select media_type from ctmedia_type order by media_type
</cfquery>
<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select mime_type from ctmime_type order by mime_type
</cfquery>
<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select sq_media_id.nextval nv from dual
</cfquery>
<!---<cfquery name="ctmedia_license" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select media_license_id,display media_license from ctmedia_license order by media_license_id
</cfquery>--->
<!--- Note, jqxcombobox doesn't properly handle options that vary only in trailing whitespace, so using trim() here --->
<cfquery name="distinctExtensions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select trim(auto_extension) as extension, count(*) as ct
	from media
	where auto_extension is not null
	group by trim(auto_extension)
	order by upper(trim(auto_extension))
</cfquery>
	<cfif not isdefined("mask_media_fg")> 
		<cfset mask_media_fg="">
	</cfif>
	<cfif not isdefined("media_uri")> 
		<cfset media_uri="">
	</cfif>
	<cfif not isdefined("preview_uri")> 
		<cfset preview_uri="">
	</cfif>
	<cfif not isdefined("mime_type")> 
		<cfset mime_type="">
	</cfif>
	<cfset in_mime_type=mime_type>
	<cfif not isdefined("media_type")> 
		<cfset media_type="">
	</cfif>
	<cfset in_media_type=media_type>
	<cfif not isdefined("media_id")> 
		<cfset media_id="">
	</cfif>
	<cfif not isdefined("keywords")> 
		<cfset keywords="">
	</cfif>
	<cfif not isdefined("description")> 
		<cfset description="">
	</cfif>
	<cfif not isdefined("protocol")> 
		<cfset protocol="">
	</cfif>
	<cfif not isdefined("protocol2")> 
		<cfset protocol2="">
	</cfif>
	<cfif not isdefined("hostname2")> 
		<cfset hostname2="">
	</cfif>
	<cfif not isdefined("hostname")> 
		<cfset hostname="">
	</cfif>
	<cfif not isdefined("path2")> 
		<cfset path2="">
	</cfif>
	<cfif not isdefined("path")> 
		<cfset path="">
	</cfif>
	<cfif not isdefined("filename2")> 
		<cfset filename2="">
	</cfif>
	<cfif not isdefined("filename")> 
		<cfset filename="">
	</cfif>
	<cfif not isdefined("extension")> 
		<cfset extension="">
	</cfif>
	<cfset in_extension=extension>
	<cfif not isdefined("created_by_agent_name")>
		<cfset created_by_agent_name="">
	</cfif>
	<cfif not isdefined("created_by_agent_id")>
		<cfset created_by_agent_id="">
	</cfif>
	<cfif not isdefined("text_made_date")>
		<cfset text_made_date="">
	</cfif>
	<cfif not isdefined("to_made_date")>
		<cfset to_made_date="">
	</cfif>
	<cfif not isdefined("dcterms_identifier")>
		<cfset dcterms_identifier="">
	</cfif>
	<cfif not isdefined("related_cataloged_item")>
		<cfset related_cataloged_item="">
	</cfif>
	<cfif not isdefined("collection_object_id")>
		<cfset collection_object_id="">
	</cfif>
	<cfif not isdefined("unlinked")>
		<cfset unlinked="">
	</cfif>
	<cfif not isdefined("multilink")>
		<cfset multilink="">
	</cfif>
	<cfif not isdefined("multitypelink")>
		<cfset multitypelink="">
	</cfif>
	<cfif not isdefined("collection")>
		<cfset collection="">
	</cfif>
	<cfif not isdefined("folder")>
		<cfset folder="">
	</cfif>
	<cfif not isdefined("media_label_type")>
		<cfset media_label_type="">
	</cfif>
	<cfif not isdefined("media_label_value")>
		<cfset media_label_value="">
	</cfif>
	<cfif not isdefined("media_relationship_type")>
		<cfset media_relationship_type="">
	</cfif>
	<cfif not isdefined("media_relationship_value")>
		<cfset media_relationship_value="">
	</cfif>
	<cfif not isdefined("media_relationship_id")>
		<cfset media_relationship_id="">
	</cfif>
	<cfif not isdefined("media_relationship_type_1")>
		<cfset media_relationship_type_1="">
	</cfif>
	<cfif not isdefined("media_relationship_value_1")>
		<cfset media_relationship_value_1="">
	</cfif>
	<cfif not isdefined("media_relationship_id_1")>
		<cfset media_relationship_id_1="">
	</cfif>
<!---------------------------------------------------------------------------------------------------->
<!---
1)  


--->

<cfif action is 'new'>
	<cfoutput>
		<section class="jumbotron pb-3 bg-white text-center">
			<div class="container">
				<h1 class="jumbotron-heading">Shared Drive</h1>
				<p class="lead text-muted">
					Save the largest size of the media available to the shared drive. A thumbnail will be created for you. 
					<br>The Shared Drive is MCZ media storage managed by Collections Operations and Research Computing (RC). Account questions can go into a RC ticket with a cc to Brendan Haley. 
				</p>
			</div>
		</section>
		<div class="album pb-5 bg-light">
			<form name="newMedia" id="newMedia" action="/media/SharedDrive.cfm" method="post" required>
				<div class="container">
					<div class="row">
						<div class="col-12 pt-4 pb-1">
							<div class="col-12 col-md-2 float-left">
								<div class="form-group mb-2">
									<label for="keywords" class="data-entry-label mb-0" id="keywords_label">Protocol<span></span></label>
									<select id="protocol" name="protocol" class="data-entry-select">
										<option>https://</option>
										<cfif protocol EQ "http://"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
										<option value="http://" #sel#>http://</option>
										<cfif protocol EQ "https://"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
										<option value="https://" #sel#>https://</option>
										<cfif protocol EQ "httphttps"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
										<option value="httphttps" #sel#>http or https</option>
										<cfif protocol EQ "NULL"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
										<option value="NULL" #sel#>NULL</option>
									</select>
								</div>
							</div>
							<div class="col-12 col-md-2 float-left">
								<div class="form-group mb-2"><!---will it ever change? hard coded value --could remove autofill maybe--->
									<label for="hostname" class="data-entry-label mb-0" id="hostname_label">Host<span></span></label>
									<input type="text" id="hostname" name="hostname" class="data-entry-input" value="mczbase.mcz.harvard.edu" aria-labelledby="hostname_label" >
								</div>
								<script>
									$(document).ready(function() {
										makeMediaURIPartAutocomplete("hostname","hostname");
									});
								</script>
							</div>
							<div class="col-12 col-md-4 float-left">
								<div class="form-group mb-2">
									<label for="path" class="data-entry-label mb-0">Path<span class="text-italic"> (e.g., "/specimen_images/herpetology/large/")</span></label>
									<input type="text" id="path" name="path" placeholder="/specimen_images/+collection+/+folder+/" class="data-entry-input" value="#encodeForHtml(path)#">
								</div>
								<script>
									$(document).ready(function() {
										makeMediaURIPartAutocomplete("path","path");
									});
								</script>
							</div>
							<div class="col-12 col-md-4 float-left">
								<div class="form-group mb-2">
									<label for="filename" class="data-entry-label mb-0">Filename (e.g., A139491_Bufo_fustiger_d_4.jpg ) <span></span></label>
								<input type="text" id="filename" name="filename" placeholder="name of file on the shared drive" class="data-entry-input" value="#encodeForHtml(filename)#">
								</div>
								<script>
									$(document).ready(function() {
										makeMediaURIPartAutocomplete("filename","filename");
									});
								</script>
							</div>
							<div class=" float-left d-none">
								<div class="form-group mb-2">
									<label for="extension" class="data-entry-label mb-0">Extension<span></span></label>
									<cfset selectedextensionlist = "">
									<select id="extension" name="extension" class="data-entry-select" multiple="true">
										<option></option>
										<cfloop query="distinctExtensions">
											<cfif listFind(in_extension, distinctExtensions.extension) GT 0>
												<cfset selected="">
												<cfset selectedextensionlist = listAppend(selectedextensionlist,'#distinctExtensions.extension#') >
											<cfelse>
												<cfset selected="">
											</cfif>
											<option value="#distinctExtensions.extension#" #selected#>#distinctExtensions.extension# (#distinctExtensions.ct#)</option>
										</cfloop>
										<option value="Select All">Select All</option>
										<option value="NULL">NULL</option>
										<option value="NOT NULL">NOT NULL</option>
									</select>
									<script>
										$(document).ready(function () {
											$("##extension").jqxComboBox({  multiSelect: false, width: '100%', enableBrowserBoundsDetection: true });  
											<cfloop list="#selectedextensionlist#" index="ext">
												$("##extension").jqxComboBox('selectItem', '#ext#');
											</cfloop>
											$("##extension").jqxComboBox().on('select', function (event) {
												var args = event.args;
												if (args) {
													var item = args.item;
													if (item.label == 'Select All') { 
														for (i=0;i<args.index;i++) { 
															$("##extension").jqxComboBox('selectIndex', i);
														}
														$("##extension").jqxComboBox('unselectIndex', args.index);
													}
												}
											});
										});
									</script>
								</div>
							</div>
						</div>
					</div>
					<div class="row">
						<div class="col-2 mx-auto">
						<input id="Preview" type="button" class="btn btn-xs mr-2 btn-primary d-inline-block" value="Preview Image(s)" onclick="getImg();getTable();"/>
							<input type="button" class="btn btn-xs ml-2 btn-warning ml-2 d-inline-block" onClick="clearInput();" value="Reset Form"/>
						</div>
					</div>

					<div class="row">

						<div class="col-3 mt-2 float-left">
							<div id="images" class="d-inline"></div>
						</div>
						<div class="col-3 mt-2 float-left">
							<div id="commonData" class="d-inline">
					
							</div>
						</div>
						
					</div>
				</div>
			</form>
		</div>	
		
		<script>
			function clearInput() {
				document.getElementById("newMedia").reset();
			}
		</script>
		<script>
			function getImg(){
				var url=document.getElementById('protocol').value;
				url+=document.getElementById('hostname').value;
				url+=document.getElementById('path').value;
				url+=document.getElementById('filename').value;
				var div=document.createElement('div');
				div.className="imagewrapper text-center my-3";
				document.getElementById('images').appendChild(div);
				var span=document.createElement('span');
				span.className="close";
				span.innerHTML="&times;";
				document.getElementById('images').appendChild(span);
				var img=document.createElement('img');
				img.classList.add('imageFeatures');
				img.src=url;
				div.appendChild(span);
				div.appendChild(img);
				var p=document.createElement('p');
				p.className="text-dark text-center";
				p.innerHTML=document.getElementById('filename').value;
				div.appendChild(p);
				var button=document.createElement('button');
				button.id="btn_link";
				button.className="btn btn-xs btn-secondary";
				button.type="submit";
				button.onclick = function(){
					window.location='/media/SharedDrive.cfm?action=newMedia&media_id=#mid.nv#';
					return false;
				};
				button.innerHTML="Create Media Records";
				div.appendChild(button);
				span.addEventListener('click', () => {
					//alert('Oh, you clicked me!');
					let childDivs = document.querySelectorAll("div##images > .imagewrapper");
					for(var i = 0; i < childDivs.length; i++){
						childDivs[i].remove();
					}
				});

				return false;
			}
			

			function getTable() {
				// creates a <table> element and a <tbody> element
				const tbl = document.createElement("table");
				
				const tblHead = document.createElement("thead");
				for (let i = 0; i < 1; i++) {
					// creates a table row
					const row = document.createElement("tr");
						const thcell = document.createElement("th");
						const cellLabel = document.createTextNode('Label');
						thcell.appendChild(cellLabel);
						row.appendChild(thcell);
						const thcell2 = document.createElement("th");
						const cellLabel2 = document.createTextNode('Value');
						thcell2.appendChild(cellLabel2);
						row.appendChild(thcell2);

					// add the row to the end of the table body
					tblHead.appendChild(row);
				}
				// put the <tbody> in the <table>
				tbl.appendChild(tblHead);
				
				
				const tblBody = document.createElement("tbody");

				// creating all cells
				for (let i = 0; i < 2; i++) {
					// creates a table row
					const row = document.createElement("tr");

					for (let j = 0; j < 2; j++) {
					// Create a <td> element and a text node, make the text
					// node the contents of the <td>, and put the <td> at
					// the end of the table row
						const cell = document.createElement("td");
						const cellText = document.createTextNode(`cell in row ${i}, column ${j}`);
						cell.appendChild(cellText);
						row.appendChild(cell);
					}

					// add the row to the end of the table body
					tblBody.appendChild(row);
				}

				// put the <tbody> in the <table>
				tbl.appendChild(tblBody);
				// appends <table> into <body>
				document.body.appendChild(tbl);
				// sets the border attribute of tbl to '2'
				tbl.setAttribute("border", "2");
				document.getElementById('commonData').appendChild(tbl);
			}
		</script>
	</cfoutput>
</cfif>
<cfif action is 'newMedia'>
	<cfoutput>
		<div class="container">
			<div class="row">
				<div class="col-12 mt-4">
					<h1>Create Media Record</h1>
					<p>Metadata form with the media ID and URL in place.</p>
				</div>
				<div class="col-12 px-0 my-0">
					<table class="table table-responsive-sm mb-3 border-none small90">
						<thead class="thead-dark">
							<tr>
								<th scope="col" style="width: 150px;">Label</th>
								<th scope="col">Value</th>
							</tr>
						</thead>
						<tbody>
							<tr><th scope="row">Media Type:</th><td></td></tr>
							<tr><th scope="row">MIME Type:</th><td></td></tr>
							<tr><th scope="row">Credit:</th><td></td></tr>
							<tr><th scope="row">Copyright:</th><td></td></tr>
							<tr><th scope="row">License:</th><td> <a href="" target="_blank" class="external"> </a></td></tr>
							<tr><th scope="row">Keywords: </span></th><td> </td></tr>
							<tr class="border mt-2 p-2"><th scope="row">Media URI </th><td><a target="_blank" href=""></a></td></tr>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	</cfoutput>
</cfif>
<cfif action is 'edit'>
	<cfoutput>
		<div class="container">
			<div class="row">
				<div class="col-12 mt-4">
					<h1>Edit Media Record</h1>
					<p>Metadata form with the media ID and URL in place and any other data that was filled out previously.</p>
				</div>
			</div>
		</div>
	</cfoutput>
</cfif>



<cfinclude template="/shared/_footer.cfm">
