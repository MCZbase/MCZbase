<!---
specimens/downloadGeospatialData.cfm

Copyright 2026 President and Fellows of Harvard College

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
<!--- KML of the georeferenced cataloged items in a specimen search result, for Google Earth, with the
	options of the legacy /bnhmMaps/kml.cfm. --->
<cfparam name="url.result_id" default="">
<cfparam name="form.result_id" default="">
<cfparam name="form.action" default="">
<cfparam name="form.colorBy" default="collection">
<cfparam name="form.method" default="download">
<cfparam name="form.fileName" default="MCZbaseLocalities">
<cfparam name="form.showErrors" default="">
<cfparam name="form.mapByLocality" default="">
<cfparam name="form.showUnaccepted" default="">
<cfparam name="form.includeTimeSpan" default="">
<cfset variables.result_id = url.result_id>
<cfif len(form.result_id) GT 0>
	<cfset variables.result_id = form.result_id>
</cfif>
<cfset variables.action = form.action>
<cfif len(variables.action) EQ 0>
	<cfset variables.action = "entryPoint">
</cfif>
<cfset variables.colorBy = "collection">
<cfif form.colorBy EQ "species">
	<cfset variables.colorBy = "species">
</cfif>
<cfset variables.method = "download">
<cfif form.method EQ "link">
	<cfset variables.method = "link">
</cfif>
<!--- names only the downloaded file, so anything but a plain name is replaced --->
<cfset variables.fileName = REReplace(REReplaceNoCase(trim(form.fileName), "\.kml$", ""), "[^A-Za-z0-9._-]", "_", "all")>
<cfif len(variables.fileName) EQ 0>
	<cfset variables.fileName = "MCZbaseLocalities">
</cfif>
<cfset variables.showErrors = false>
<cfif form.showErrors EQ "1">
	<cfset variables.showErrors = true>
</cfif>
<cfset variables.mapByLocality = false>
<cfif form.mapByLocality EQ "1">
	<cfset variables.mapByLocality = true>
</cfif>
<cfset variables.showUnaccepted = false>
<cfif form.showUnaccepted EQ "1">
	<cfset variables.showUnaccepted = true>
</cfif>
<cfset variables.includeTimeSpan = false>
<cfif form.includeTimeSpan EQ "1">
	<cfset variables.includeTimeSpan = true>
</cfif>

<cfif variables.action EQ "makeKml">
	<!--- the response is the file, so the role check the header would run is run here --->
	<cf_rolecheck>
	<cfinclude template="/specimens/component/manage.cfc" runOnce="true">
	<cfinclude template="/shared/component/fileUtilities.cfc" runOnce="true">
	<cfif len(variables.result_id) GT 0 AND getGeoreferenceCount(result_id = variables.result_id) GT 0>
		<cfset variables.kml = getResultKml(
			result_id = variables.result_id,
			colorBy = variables.colorBy,
			showErrors = variables.showErrors,
			mapByLocality = variables.mapByLocality,
			showUnaccepted = variables.showUnaccepted,
			includeTimeSpan = variables.includeTimeSpan)>
		<cfset variables.downloadName = "#variables.fileName#.kml">
		<cfif variables.method EQ "link">
			<!--- Google Earth fetches a linked file without a session, so it is written where Apache serves it,
				under a name that can't be guessed; CleanTempFiles removes it after 7 days. --->
			<cfset variables.storedName = "kml_#lcase(hash(generateSecretKey("AES", 256), "SHA-256"))#.kml">
			<cffile action="write" file="#Application.webDirectory#/bnhmMaps/tabfiles/#variables.storedName#" output="#variables.kml#" charset="utf-8" nameconflict="overwrite">
			<cfset variables.kml = '<?xml version="1.0" encoding="UTF-8"?>' & chr(10) &
				'<kml xmlns="http://www.opengis.net/kml/2.2">' & chr(10) &
				chr(9) & '<NetworkLink>' & chr(10) &
				chr(9) & chr(9) & '<name>MCZbase Localities</name>' & chr(10) &
				chr(9) & chr(9) & '<visibility>1</visibility>' & chr(10) &
				chr(9) & chr(9) & '<open>1</open>' & chr(10) &
				chr(9) & chr(9) & '<Link><href>#xmlFormat(Application.serverRootUrl)#/bnhmMaps/tabfiles/#variables.storedName#</href></Link>' & chr(10) &
				chr(9) & '</NetworkLink>' & chr(10) &
				'</kml>' & chr(10)>
			<cfset variables.downloadName = "link_#variables.fileName#.kml">
		</cfif>
		<cfheader name="Content-Disposition" value="#attachmentDisposition(variables.downloadName)#">
		<cfcontent type="application/vnd.google-earth.kml+xml; charset=utf-8" reset="true"><cfoutput>#variables.kml#</cfoutput><cfabort>
	</cfif>
	<cfset variables.action = "entryPoint">
	<cfset variables.noGeoreferences = true>
</cfif>

<cfset pageTitle = "Download KML">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/specimens/component/manage.cfc" runOnce="true">
<cfif len(variables.result_id) EQ 0>
	<cfthrow message="No result_id provided for the KML.">
</cfif>
<cfset variables.itemCount = getCatalogedItemCount(result_id = variables.result_id)>
<cfset variables.georefCount = getGeoreferenceCount(result_id = variables.result_id)>
<cfset variables.speciesSelected = "">
<cfif variables.colorBy EQ "species">
	<cfset variables.speciesSelected = "selected">
</cfif>
<cfset variables.linkSelected = "">
<cfif variables.method EQ "link">
	<cfset variables.linkSelected = "selected">
</cfif>
<cfset variables.collectionOptionsDisabled = "">
<cfif variables.colorBy EQ "species">
	<cfset variables.collectionOptionsDisabled = "disabled">
</cfif>
<cfoutput>
	<main class="container py-3" id="content">
		<section class="row border rounded my-2 mb-4">
			<div class="col-12">
				<h1 class="h2 mt-2">Download KML for Google Earth</h1>
				<p>#encodeForHtml(variables.georefCount)# of the #encodeForHtml(variables.itemCount)# cataloged items in this search result are georeferenced.</p>
				<cfif isDefined("variables.noGeoreferences")>
					<div class="alert alert-warning" role="alert">This search result has no georeferenced cataloged items to put in a KML file.</div>
				</cfif>
				<p class="text-danger">The horizontal datum is not transformed: points with a datum other than WGS84 will be misplaced.</p>
				<form name="kmlForm" id="kmlForm" method="post" action="/specimens/downloadGeospatialData.cfm">
					<input type="hidden" name="action" value="makeKml">
					<input type="hidden" name="result_id" value="#encodeForHtml(variables.result_id)#">
					<div class="form-row mb-2">
						<div class="col-12 col-md-4">
							<label for="colorBy" class="data-entry-label">Color by</label>
							<select name="colorBy" id="colorBy" class="data-entry-select" onchange="$('##collectionOptions').prop('disabled', this.value == 'species');">
								<option value="collection">Collection</option>
								<option value="species" #variables.speciesSelected#>Species</option>
							</select>
						</div>
						<div class="col-12 col-md-4">
							<label for="method" class="data-entry-label">File</label>
							<select name="method" id="method" class="data-entry-select">
								<option value="download">KML file</option>
								<option value="link" #variables.linkSelected#>KML link file (Google Earth loads the data from MCZbase)</option>
							</select>
						</div>
						<div class="col-12 col-md-4">
							<label for="fileName" class="data-entry-label">File name</label>
							<input type="text" name="fileName" id="fileName" class="data-entry-input" value="#encodeForHtml(variables.fileName)#">
						</div>
					</div>
					<fieldset id="collectionOptions" class="border rounded px-2 mb-2" #variables.collectionOptionsDisabled#>
						<legend class="h6 w-auto px-1 mb-0">When coloring by collection</legend>
						<cfset variables.checked = "">
						<cfif variables.showErrors><cfset variables.checked = "checked"></cfif>
						<div class="form-check">
							<input type="checkbox" class="form-check-input" name="showErrors" id="showErrors" value="1" #variables.checked#>
							<label class="form-check-label" for="showErrors">Show error circles (makes large files)</label>
						</div>
						<cfset variables.checked = "">
						<cfif variables.mapByLocality><cfset variables.checked = "checked"></cfif>
						<div class="form-check">
							<input type="checkbox" class="form-check-input" name="mapByLocality" id="mapByLocality" value="1" #variables.checked#>
							<label class="form-check-label" for="mapByLocality">Show all cataloged items at each locality in the result</label>
						</div>
						<cfset variables.checked = "">
						<cfif variables.showUnaccepted><cfset variables.checked = "checked"></cfif>
						<div class="form-check mb-1">
							<input type="checkbox" class="form-check-input" name="showUnaccepted" id="showUnaccepted" value="1" #variables.checked#>
							<label class="form-check-label" for="showUnaccepted">Show unaccepted georeferences</label>
						</div>
					</fieldset>
					<cfset variables.checked = "">
					<cfif variables.includeTimeSpan><cfset variables.checked = "checked"></cfif>
					<div class="form-check mb-2">
						<input type="checkbox" class="form-check-input" name="includeTimeSpan" id="includeTimeSpan" value="1" #variables.checked#>
						<label class="form-check-label" for="includeTimeSpan">Include collecting dates as a time span</label>
					</div>
					<button type="submit" class="btn btn-xs btn-primary mb-3">Download</button>
				</form>
			</div>
		</section>
	</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
