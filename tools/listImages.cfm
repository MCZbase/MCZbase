<!---
/tools/listImages.cfm

Displays a list of all images in the /images and /shared/images directories, along with their file size, last modified date, and a preview thumbnail.

Copyright 2008-2017 Contributors to Arctos
Copyright 2020-2026 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<cfset pageTitle = "Image List">
<cfinclude template="/shared/_header.cfm">
<script src="/lib/misc/sorttable.js"></script>

<!--- obtain list of images from both /images and /shared/images and place them into a query object --->

<cfdirectory sort="name" directory="#Application.webDirectory#/images" name="imagesRoot">
<cfdirectory sort="name" directory="#Application.webDirectory#/shared/images" name="imagesShared">

<cfset imageFiles = queryNew("web_path,file_name,source_path,size,date_last_modified")>

<cfloop query="imagesRoot">
	<cfif type EQ "File">
		<cfset queryAddRow(imageFiles, 1)>
		<cfset querySetCell(imageFiles, "web_path", "/images/#name#")>
		<cfset querySetCell(imageFiles, "file_name", name)>
		<cfset querySetCell(imageFiles, "source_path", "/images")>
		<cfset querySetCell(imageFiles, "size", size)>
		<cfset querySetCell(imageFiles, "date_last_modified", dateLastModified)>
	</cfif>
</cfloop>

<cfloop query="imagesShared">
	<cfif type EQ "File">
		<cfset queryAddRow(imageFiles, 1)>
		<cfset querySetCell(imageFiles, "web_path", "/shared/images/#name#")>
		<cfset querySetCell(imageFiles, "file_name", name)>
		<cfset querySetCell(imageFiles, "source_path", "/shared/images")>
		<cfset querySetCell(imageFiles, "size", size)>
		<cfset querySetCell(imageFiles, "date_last_modified", dateLastModified)>
	</cfif>
</cfloop>

<main class="container-fluid py-3" id="content">
	<section class="row">
		<div class="col-12">
			<cfoutput>
				<h1 class="h2">Images (#encodeForHtml(imageFiles.recordCount)#)</h1>
			</cfoutput>
			<p class="text-muted">Images are shown from <code>/images</code> and <code>/shared/images</code>. Previews are capped to keep the page usable with very large image files.</p>
		</div>
	</section>
	<section class="row">
		<div class="col-12">
			<cfoutput>
			<table id="imageListTable" class="sortable table table-responsive d-xl-table table-striped">
				<thead class="thead-light">
					<tr>
						<th scope="col">Path</th>
						<th scope="col">File Name</th>
						<th scope="col">Size (bytes)</th>
						<th scope="col">Last Modified</th>
						<th scope="col">Preview</th>
					</tr>
				</thead>
				<tbody>
					<cfloop query="imageFiles">
						<tr>
							<td>#encodeForHtml(source_path)#</td>
							<td>#encodeForHtml(file_name)#</td>
							<td>#encodeForHtml(size)#</td>
							<td>#encodeForHtml(dateTimeFormat(date_last_modified, "yyyy-mm-dd HH:nn:ss"))#</td>
							<td>
								<img src="#encodeForHtmlAttribute(web_path)#" alt="#encodeForHtmlAttribute(file_name)#" class="img-fluid img-thumbnail" style="max-width: 320px; max-height: 220px;">
							</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
			</cfoutput>
		</div>
	</section>
</main>

<cfinclude template="/shared/_footer.cfm">
