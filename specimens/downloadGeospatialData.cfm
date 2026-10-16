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
<!--- Map files of the georeferenced cataloged items in a specimen search result: KML, KMZ and a KML link
	file for Google Earth with the options of the legacy /bnhmMaps/kml.cfm, GeoJSON, GPX, and CSV with
	Darwin Core terms. --->
<cfparam name="url.result_id" default="">
<cfparam name="form.result_id" default="">
<cfparam name="form.action" default="">
<cfparam name="form.format" default="kml">
<cfparam name="form.colorBy" default="collection">
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
<cfset FORMATS = "kml,kmz,kmlLink,geojson,gpx,csv">
<cfset variables.format = "kml">
<cfif listFind(FORMATS, form.format) GT 0>
	<cfset variables.format = form.format>
</cfif>
<cfset variables.colorBy = "collection">
<cfif form.colorBy EQ "species">
	<cfset variables.colorBy = "species">
</cfif>
<!--- names only the downloaded file, so anything but a plain name is replaced --->
<cfset variables.fileName = REReplace(REReplaceNoCase(trim(form.fileName), "\.(kml|kmz|geojson|json|gpx|csv)$", ""), "[^A-Za-z0-9._-]", "_", "all")>
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

<cfif variables.action EQ "makeFile">
	<!--- the response is the file, so the role check the header would run is run here --->
	<cf_rolecheck>
	<cfinclude template="/specimens/component/manage.cfc" runOnce="true">
	<cfinclude template="/shared/component/fileUtilities.cfc" runOnce="true">
	<cfif len(variables.result_id) GT 0 AND getGeoreferenceCount(result_id = variables.result_id) GT 0>
		<cfswitch expression="#variables.format#">
			<cfcase value="geojson">
				<cfset variables.content = getResultGeoJson(
					result_id = variables.result_id,
					showErrors = variables.showErrors,
					mapByLocality = variables.mapByLocality,
					showUnaccepted = variables.showUnaccepted)>
				<cfset variables.contentType = "application/geo+json; charset=utf-8">
				<cfset variables.downloadName = "#variables.fileName#.geojson">
			</cfcase>
			<cfcase value="gpx">
				<cfset variables.content = getResultGpx(
					result_id = variables.result_id,
					mapByLocality = variables.mapByLocality,
					showUnaccepted = variables.showUnaccepted)>
				<cfset variables.contentType = "application/gpx+xml; charset=utf-8">
				<cfset variables.downloadName = "#variables.fileName#.gpx">
			</cfcase>
			<cfcase value="csv">
				<!--- with a byte order mark, so spreadsheets read it as UTF-8 --->
				<cfset variables.content = chr(65279) & getResultDarwinCoreCsv(
					result_id = variables.result_id,
					mapByLocality = variables.mapByLocality,
					showUnaccepted = variables.showUnaccepted)>
				<cfset variables.contentType = "text/csv; charset=utf-8">
				<cfset variables.downloadName = "#variables.fileName#.csv">
			</cfcase>
			<cfdefaultcase>
				<cfset variables.content = getResultKml(
					result_id = variables.result_id,
					colorBy = variables.colorBy,
					showErrors = variables.showErrors,
					mapByLocality = variables.mapByLocality,
					showUnaccepted = variables.showUnaccepted,
					includeTimeSpan = variables.includeTimeSpan)>
				<cfset variables.contentType = "application/vnd.google-earth.kml+xml; charset=utf-8">
				<cfset variables.downloadName = "#variables.fileName#.kml">
			</cfdefaultcase>
		</cfswitch>
		<cfif variables.format EQ "kmlLink">
			<!--- Google Earth fetches a linked file without a session, so it is written where Apache serves it,
				under a name that can't be guessed; CleanTempFiles removes it after 7 days. --->
			<cfset variables.storedName = "kml_#lcase(hash(generateSecretKey("AES", 256), "SHA-256"))#.kml">
			<cffile action="write" file="#Application.webDirectory#/bnhmMaps/tabfiles/#variables.storedName#" output="#variables.content#" charset="utf-8" nameconflict="overwrite">
			<cfset variables.content = '<?xml version="1.0" encoding="UTF-8"?>' & chr(10) &
				'<kml xmlns="http://www.opengis.net/kml/2.2">' & chr(10) &
				chr(9) & '<NetworkLink>' & chr(10) &
				chr(9) & chr(9) & '<name>MCZbase Localities</name>' & chr(10) &
				chr(9) & chr(9) & '<visibility>1</visibility>' & chr(10) &
				chr(9) & chr(9) & '<open>1</open>' & chr(10) &
				chr(9) & chr(9) & '<Link><href>#xmlFormat(Application.serverRootUrl)#/bnhmMaps/tabfiles/#variables.storedName#</href></Link>' & chr(10) &
				chr(9) & '</NetworkLink>' & chr(10) &
				'</kml>' & chr(10)>
			<cfset variables.downloadName = "link_#variables.fileName#.kml">
		<cfelseif variables.format EQ "kmz">
			<cfset variables.downloadName = "#variables.fileName#.kmz">
		</cfif>
		<cfheader name="Content-Disposition" value="#attachmentDisposition(variables.downloadName)#">
		<cfif variables.format EQ "kmz">
			<!--- a KMZ is a zip with the KML as doc.kml --->
			<cfset variables.zipBytes = createObject("java", "java.io.ByteArrayOutputStream").init()>
			<cfset variables.zipStream = createObject("java", "java.util.zip.ZipOutputStream").init(variables.zipBytes)>
			<cfset variables.zipStream.putNextEntry(createObject("java", "java.util.zip.ZipEntry").init("doc.kml"))>
			<cfset variables.zipStream.write(charsetDecode(variables.content, "utf-8"))>
			<cfset variables.zipStream.closeEntry()>
			<cfset variables.zipStream.close()>
			<cfcontent type="application/vnd.google-earth.kmz" variable="#variables.zipBytes.toByteArray()#" reset="true">
			<cfabort>
		</cfif>
		<cfcontent type="#variables.contentType#" reset="true"><cfoutput>#variables.content#</cfoutput><cfabort>
	</cfif>
	<cfset variables.action = "entryPoint">
	<cfset variables.noGeoreferences = true>
</cfif>

<cfset pageTitle = "Download Map File">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/specimens/component/manage.cfc" runOnce="true">
<cfif len(variables.result_id) EQ 0>
	<cfthrow message="No result_id provided for the map file.">
</cfif>
<cfset variables.itemCount = getCatalogedItemCount(result_id = variables.result_id)>
<cfset variables.georefCount = getGeoreferenceCount(result_id = variables.result_id)>
<cfset variables.formDisabled = "">
<cfif variables.georefCount EQ 0>
	<cfset variables.formDisabled = "disabled">
</cfif>
<cfset variables.speciesSelected = "">
<cfif variables.colorBy EQ "species">
	<cfset variables.speciesSelected = "selected">
</cfif>
<cfset variables.formatLabels = {
	kml = "KML, for Google Earth",
	kmz = "KMZ, zipped KML",
	kmlLink = "KML link file, Google Earth loads the data from MCZbase",
	geojson = "GeoJSON, for GIS and web maps",
	gpx = "GPX, for GPS units",
	csv = "CSV with Darwin Core terms"
}>
<cfoutput>
	<main class="container py-3" id="content">
		<section class="row border rounded my-2 mb-4">
			<div class="col-12">
				<h1 class="h2 mt-2">Download Map File</h1>
				<p>#encodeForHtml(variables.georefCount)# of the #encodeForHtml(variables.itemCount)# cataloged items in this search result are georeferenced.</p>
				<cfif variables.georefCount EQ 0 OR isDefined("variables.noGeoreferences")>
					<div class="alert alert-warning" role="alert">This search result has no georeferenced cataloged items to put in a map file.</div>
				</cfif>
				<p class="text-danger">The horizontal datum is not transformed: in KML, KMZ, GeoJSON and GPX, points with a datum other than WGS84 will be misplaced. The CSV gives each point's datum.</p>
				<form name="geospatialForm" id="geospatialForm" method="post" action="/specimens/downloadGeospatialData.cfm">
					<input type="hidden" name="action" value="makeFile">
					<input type="hidden" name="result_id" value="#encodeForHtml(variables.result_id)#">
					<fieldset #variables.formDisabled#>
						<legend class="sr-only">Map file options</legend>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
								<label for="format" class="data-entry-label">Format</label>
								<select name="format" id="format" class="data-entry-select" onchange="updateGeospatialOptions('format','colorBy');">
									<cfloop list="#FORMATS#" index="formatValue">
										<cfset variables.selected = "">
										<cfif formatValue EQ variables.format>
											<cfset variables.selected = "selected">
										</cfif>
										<option value="#formatValue#" #variables.selected#>#encodeForHtml(variables.formatLabels[formatValue])#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4">
								<label for="colorBy" class="data-entry-label">Color by (KML and KMZ)</label>
								<select name="colorBy" id="colorBy" class="data-entry-select" onchange="updateGeospatialOptions('format','colorBy');">
									<option value="collection">Collection</option>
									<option value="species" #variables.speciesSelected#>Species</option>
								</select>
							</div>
							<div class="col-12 col-md-4">
								<label for="fileName" class="data-entry-label">File name</label>
								<input type="text" name="fileName" id="fileName" class="data-entry-input" value="#encodeForHtml(variables.fileName)#">
							</div>
						</div>
						<cfset variables.checked = "">
						<cfif variables.showErrors><cfset variables.checked = "checked"></cfif>
						<div class="form-check">
							<input type="checkbox" class="form-check-input" name="showErrors" id="showErrors" value="1" #variables.checked#>
							<label class="form-check-label" for="showErrors">Show error circles (KML and KMZ by collection, and GeoJSON; makes large files; the CSV always has them as footprintWKT)</label>
						</div>
						<cfset variables.checked = "">
						<cfif variables.mapByLocality><cfset variables.checked = "checked"></cfif>
						<div class="form-check">
							<input type="checkbox" class="form-check-input" name="mapByLocality" id="mapByLocality" value="1" #variables.checked#>
							<label class="form-check-label" for="mapByLocality">Include all cataloged items at each locality in the result</label>
						</div>
						<cfset variables.checked = "">
						<cfif variables.showUnaccepted><cfset variables.checked = "checked"></cfif>
						<div class="form-check">
							<input type="checkbox" class="form-check-input" name="showUnaccepted" id="showUnaccepted" value="1" #variables.checked#>
							<label class="form-check-label" for="showUnaccepted">Include unaccepted georeferences</label>
						</div>
						<cfset variables.checked = "">
						<cfif variables.includeTimeSpan><cfset variables.checked = "checked"></cfif>
						<div class="form-check mb-2">
							<input type="checkbox" class="form-check-input" name="includeTimeSpan" id="includeTimeSpan" value="1" #variables.checked#>
							<label class="form-check-label" for="includeTimeSpan">Include collecting dates as a time span (KML and KMZ)</label>
						</div>
						<button type="submit" class="btn btn-xs btn-primary mb-3">Download</button>
					</fieldset>
				</form>
				<script>
					/** Enable only the options that apply to the chosen format and coloring.
					 *
					 * @param formatId the id of the format select.
					 * @param colorById the id of the color by select.
					 */
					function updateGeospatialOptions(formatId, colorById) {
						var format = $("##" + formatId).val();
						var isKml = (format == "kml" || format == "kmz" || format == "kmlLink");
						var bySpecies = isKml && $("##" + colorById).val() == "species";
						$("##" + colorById).prop("disabled", !isKml);
						$("##showErrors").prop("disabled", !((isKml && !bySpecies) || format == "geojson"));
						$("##mapByLocality").prop("disabled", bySpecies);
						$("##showUnaccepted").prop("disabled", bySpecies);
						$("##includeTimeSpan").prop("disabled", !isKml);
					}
					$(document).ready(function() {
						updateGeospatialOptions("format", "colorBy");
					});
				</script>
			</div>
		</section>
	</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
