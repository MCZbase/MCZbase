<!---
Reports/permit.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2026 President and Fellows of Harvard College

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
<!---
PDF report of the cataloged items accessioned or loaned under a permit, reached with a permit_id
(or a permit_num) from the permit pages.  The user picks the specimens to include, the order, and
notes to print against some or all of them.
--->
<cfparam name="url.permit_id" default="">
<cfparam name="url.permit_num" default="">
<cfparam name="form.action" default="">
<cfparam name="form.permit_id" default="">
<cfparam name="form.collection_object_id" default="">
<cfparam name="form.data_order_by" default="cat_num">

<cfset ORDERINGS = [
	{ value = "cat_num", label = "Catalog Number" },
	{ value = "scientific_name", label = "Scientific Name" },
	{ value = "location", label = "Location" }
]>
<cfset ROWSPERPAGE = 10>

<cfset pageTitle = "Permit Use Report PDF">
<cfinclude template = "/shared/_header.cfm">

<!---
	parseCatalogNumber split a catalog number into the text before its last run of digits, that
	number, and the text after it, e.g. A-12b into A-, 12 and b.

	@param catalogNum the catalog number.
	@return a structure of prefix, number and suffix, or an empty structure if it holds no digits.
--->
<cffunction name="parseCatalogNumber" returntype="struct" output="false">
	<cfargument name="catalogNum" type="string" required="yes">

	<cfset var text = trim(arguments.catalogNum)>
	<cfset var parts = REFind("^(.*?)([0-9]+)([^0-9]*)$", text, 1, true)>
	<cfset var result = structNew()>

	<cfif parts.pos[1] GT 0>
		<!--- an empty prefix or suffix may come back at position 0, which mid() refuses --->
		<cfset result.prefix = "">
		<cfif parts.len[2] GT 0>
			<cfset result.prefix = mid(text, parts.pos[2], parts.len[2])>
		</cfif>
		<cfset result.number = val(mid(text, parts.pos[3], parts.len[3]))>
		<cfset result.suffix = "">
		<cfif parts.len[4] GT 0>
			<cfset result.suffix = mid(text, parts.pos[4], parts.len[4])>
		</cfif>
	</cfif>
	<cfreturn result>
</cffunction>

<!---
	withinScope test whether a report note applies to a catalog number.

	@param catalogNum the catalog number.
	@param scope blank or "all" for every catalog number, otherwise a comma separated list of
		catalog numbers and ranges written low-high, e.g. 12, A-7, 100-150, A-100-A-150 or A-100-150.
		Catalog numbers can hold hyphens, so an item is first matched as a whole catalog number, then
		as a range split at each hyphen in turn; a range covers the numbers between its ends that share
		the low end's prefix (taken for the high end too when it has none).
	@return true if the catalog number is in the scope.
--->
<cffunction name="withinScope" returntype="boolean" output="false">
	<cfargument name="catalogNum" type="string" required="yes">
	<cfargument name="scope" type="string" required="yes">

	<cfset var scopeItem = "">
	<cfset var hyphenPos = 0>
	<cfset var lowEnd = "">
	<cfset var highEnd = "">
	<cfset var target = parseCatalogNumber(arguments.catalogNum)>

	<cfif len(trim(arguments.scope)) EQ 0 OR trim(arguments.scope) EQ "all">
		<cfreturn true>
	</cfif>
	<cfloop list="#arguments.scope#" index="scopeItem">
		<cfset scopeItem = trim(scopeItem)>
		<cfif compareNoCase(scopeItem, trim(arguments.catalogNum)) EQ 0>
			<cfreturn true>
		</cfif>
		<cfif NOT structIsEmpty(target)>
			<cfset hyphenPos = find("-", scopeItem, 2)>
			<cfloop condition="hyphenPos GT 0 AND hyphenPos LT len(scopeItem)">
				<cfset lowEnd = parseCatalogNumber(left(scopeItem, hyphenPos - 1))>
				<cfset highEnd = parseCatalogNumber(mid(scopeItem, hyphenPos + 1, len(scopeItem)))>
				<cfif NOT structIsEmpty(lowEnd) AND NOT structIsEmpty(highEnd) AND len(trim(lowEnd.suffix)) EQ 0>
					<cfif len(trim(highEnd.prefix)) EQ 0>
						<cfset highEnd.prefix = lowEnd.prefix>
					</cfif>
					<cfif compareNoCase(trim(lowEnd.prefix), trim(highEnd.prefix)) EQ 0
							AND compareNoCase(trim(target.prefix), trim(lowEnd.prefix)) EQ 0
							AND target.number GTE lowEnd.number AND target.number LTE highEnd.number>
						<cfreturn true>
					</cfif>
				</cfif>
				<cfset hyphenPos = find("-", scopeItem, hyphenPos + 1)>
			</cfloop>
		</cfif>
	</cfloop>
	<cfreturn false>
</cffunction>

<cfoutput>
<main class="container-fluid py-3" id="content">
	<section class="row mx-0">
		<div class="col-12">
			<h1 class="h2">Permit Use Report PDF</h1>

			<!--- Find the permit. --->
			<cfset variables.permit_id = "">
			<cfif form.action EQ "generatePdf">
				<cfset variables.permit_id = form.permit_id>
			<cfelseif len(url.permit_id) GT 0>
				<cfset variables.permit_id = url.permit_id>
			<cfelseif len(url.permit_num) GT 0>
				<cfquery name="getPermitID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getPermitID_result">
					SELECT permit_id, permit_num, permit_type, permit_title
					FROM permit
					WHERE
						permit_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#url.permit_num#">
					ORDER BY permit_id
				</cfquery>
				<cfif getPermitID.recordcount EQ 1>
					<cfset variables.permit_id = getPermitID.permit_id>
				<cfelseif getPermitID.recordcount GT 1>
					<p>More than one permissions and rights document has the number #encodeForHtml(url.permit_num)#. Pick one:</p>
					<ul>
						<cfloop query="getPermitID">
							<li><a href="/Reports/permit.cfm?permit_id=#encodeForUrl(getPermitID.permit_id)#">#encodeForHtml(getPermitID.permit_type)# #encodeForHtml(getPermitID.permit_num)# #encodeForHtml(getPermitID.permit_title)#</a></li>
						</cfloop>
					</ul>
					</div></section></main>
					<cfinclude template="/shared/_footer.cfm">
					<cfabort>
				<cfelse>
					<p>No permissions and rights document has the number #encodeForHtml(url.permit_num)#.</p>
					</div></section></main>
					<cfinclude template="/shared/_footer.cfm">
					<cfabort>
				</cfif>
			</cfif>
			<cfif NOT isValid("integer", variables.permit_id)>
				<p>A permissions and rights document is needed to make this report. Open it from the document's page.</p>
				</div></section></main>
				<cfinclude template="/shared/_footer.cfm">
				<cfabort>
			</cfif>

			<cfquery name="permitInfo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="permitInfo_result">
				SELECT
					permit.permit_id,
					permit.permit_num,
					permit.permit_type,
					permit.specific_type,
					permit.permit_title,
					to_char(permit.issued_date, 'YYYY-MM-DD') AS issued_date,
					to_char(permit.exp_date, 'YYYY-MM-DD') AS exp_date,
					issuedBy.agent_name AS issued_by_agent,
					issuedTo.agent_name AS issued_to_agent
				FROM
					permit
					LEFT JOIN preferred_agent_name issuedBy ON permit.issued_by_agent_id = issuedBy.agent_id
					LEFT JOIN preferred_agent_name issuedTo ON permit.issued_to_agent_id = issuedTo.agent_id
				WHERE
					permit.permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.permit_id#">
			</cfquery>
			<cfif permitInfo.recordcount EQ 0>
				<p>No permissions and rights document was found for this report.</p>
				</div></section></main>
				<cfinclude template="/shared/_footer.cfm">
				<cfabort>
			</cfif>

			<!--- Cataloged items accessioned under the permit, or with parts loaned on a shipment under it. --->
			<cfquery name="specimens" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="specimens_result">
				SELECT
					collection_object_id, collection_cde, cat_num, cat_num_prefix, cat_num_integer, cat_num_suffix,
					scientific_name, country, state_prov, county, island, verbatim_date, began_date
				FROM (
					SELECT
						cataloged_item.collection_object_id, cataloged_item.collection_cde, cataloged_item.cat_num,
						cataloged_item.cat_num_prefix, cataloged_item.cat_num_integer, cataloged_item.cat_num_suffix,
						identification.scientific_name,
						geog_auth_rec.country, geog_auth_rec.state_prov, geog_auth_rec.county, geog_auth_rec.island,
						collecting_event.verbatim_date, collecting_event.began_date
					FROM
						permit_trans
						JOIN cataloged_item ON permit_trans.transaction_id = cataloged_item.accn_id
						JOIN collecting_event ON cataloged_item.collecting_event_id = collecting_event.collecting_event_id
						JOIN locality ON collecting_event.locality_id = locality.locality_id
						JOIN geog_auth_rec ON locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
						JOIN identification ON cataloged_item.collection_object_id = identification.collection_object_id
					WHERE
						permit_trans.permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.permit_id#">
						AND identification.accepted_id_fg = 1
					UNION
					SELECT
						cataloged_item.collection_object_id, cataloged_item.collection_cde, cataloged_item.cat_num,
						cataloged_item.cat_num_prefix, cataloged_item.cat_num_integer, cataloged_item.cat_num_suffix,
						identification.scientific_name,
						geog_auth_rec.country, geog_auth_rec.state_prov, geog_auth_rec.county, geog_auth_rec.island,
						collecting_event.verbatim_date, collecting_event.began_date
					FROM
						permit_shipment
						JOIN shipment ON permit_shipment.shipment_id = shipment.shipment_id
						JOIN loan_item ON shipment.transaction_id = loan_item.transaction_id
						JOIN specimen_part ON loan_item.collection_object_id = specimen_part.collection_object_id
						JOIN cataloged_item ON specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
						JOIN collecting_event ON cataloged_item.collecting_event_id = collecting_event.collecting_event_id
						JOIN locality ON collecting_event.locality_id = locality.locality_id
						JOIN geog_auth_rec ON locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
						JOIN identification ON cataloged_item.collection_object_id = identification.collection_object_id
					WHERE
						permit_shipment.permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.permit_id#">
						AND identification.accepted_id_fg = 1
				)
				ORDER BY collection_cde, cat_num_prefix, cat_num_integer, cat_num_suffix
			</cfquery>

			<!--- Specimens to include: all of them on arrival, those posted (and on this permit) after a PDF is made. --->
			<cfset variables.includedIds = structNew()>
			<cfif form.action EQ "generatePdf">
				<cfif REFind("^[0-9]+(,[0-9]+)*$", form.collection_object_id) GT 0>
					<cfloop list="#form.collection_object_id#" index="variables.postedId">
						<cfset variables.includedIds[variables.postedId] = true>
					</cfloop>
				</cfif>
			<cfelse>
				<cfloop query="specimens">
					<cfset variables.includedIds[specimens.collection_object_id] = true>
				</cfloop>
			</cfif>
			<cfset variables.selectedIds = "">
			<cfloop query="specimens">
				<cfif structKeyExists(variables.includedIds, specimens.collection_object_id)>
					<cfset variables.selectedIds = listAppend(variables.selectedIds, specimens.collection_object_id)>
				</cfif>
			</cfloop>

			<cfset variables.dataOrderBy = "cat_num">
			<cfloop array="#ORDERINGS#" index="variables.ordering">
				<cfif form.data_order_by EQ variables.ordering.value>
					<cfset variables.dataOrderBy = variables.ordering.value>
				</cfif>
			</cfloop>

			<!--- Report notes are posted as reportNoteText{n} and reportNoteScope{n}, numbered in the order they were added. --->
			<cfset variables.reportNoteNumbers = []>
			<cfif form.action EQ "generatePdf">
				<cfloop collection="#form#" item="variables.fieldName">
					<cfif REFindNoCase("^reportNoteText[0-9]{1,4}$", variables.fieldName) GT 0>
						<cfset arrayAppend(variables.reportNoteNumbers, int(mid(variables.fieldName, 15, 4)))>
					</cfif>
				</cfloop>
				<cfset arraySort(variables.reportNoteNumbers, "numeric")>
			</cfif>
			<cfset variables.reportNotes = []>
			<cfloop array="#variables.reportNoteNumbers#" index="variables.reportNoteNumber">
				<cfset variables.reportNoteScope = "">
				<cfif structKeyExists(form, "reportNoteScope#variables.reportNoteNumber#")>
					<cfset variables.reportNoteScope = form["reportNoteScope#variables.reportNoteNumber#"]>
				</cfif>
				<cfset arrayAppend(variables.reportNotes, { text = form["reportNoteText#variables.reportNoteNumber#"], scope = variables.reportNoteScope })>
			</cfloop>

			<!--- Write the PDF. --->
			<cfset variables.pdfMade = false>
			<cfset variables.pdfProblem = "">
			<cfif form.action EQ "generatePdf">
				<cfif len(variables.selectedIds) EQ 0>
					<cfset variables.pdfProblem = "No specimens were included, so no PDF was made.">
				<cfelse>
					<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="data_result">
						SELECT DISTINCT
							cataloged_item.collection_object_id,
							cataloged_item.collection_cde,
							cataloged_item.cat_num,
							cataloged_item.cat_num_prefix,
							cataloged_item.cat_num_integer,
							cataloged_item.cat_num_suffix,
							identification.scientific_name,
							geog_auth_rec.state_prov,
							geog_auth_rec.country,
							geog_auth_rec.county,
							geog_auth_rec.island,
							locality.spec_locality,
							CASE accepted_lat_long.orig_lat_long_units
								WHEN 'decimal degrees' THEN accepted_lat_long.dec_lat || 'd'
								WHEN 'deg. min. sec.' THEN accepted_lat_long.lat_deg || 'd ' || accepted_lat_long.lat_min || 'm ' || accepted_lat_long.lat_sec || 's ' || accepted_lat_long.lat_dir
								WHEN 'degrees dec. minutes' THEN accepted_lat_long.lat_deg || 'd ' || accepted_lat_long.dec_lat_min || 'm ' || accepted_lat_long.lat_dir
							END AS verbatim_latitude,
							CASE accepted_lat_long.orig_lat_long_units
								WHEN 'decimal degrees' THEN accepted_lat_long.dec_long || 'd'
								WHEN 'deg. min. sec.' THEN accepted_lat_long.long_deg || 'd ' || accepted_lat_long.long_min || 'm ' || accepted_lat_long.long_sec || 's ' || accepted_lat_long.long_dir
								WHEN 'degrees dec. minutes' THEN accepted_lat_long.long_deg || 'd ' || accepted_lat_long.dec_long_min || 'm ' || accepted_lat_long.long_dir
							END AS verbatim_longitude,
							accepted_lat_long.datum,
							concatColl(cataloged_item.collection_object_id) AS collectors,
							(
								SELECT LISTAGG(coll_obj_other_id_num.display_value, '-') WITHIN GROUP (ORDER BY coll_obj_other_id_num.display_value)
								FROM coll_obj_other_id_num
								WHERE
									coll_obj_other_id_num.collection_object_id = cataloged_item.collection_object_id
									AND coll_obj_other_id_num.other_id_type = 'collector number'
							) AS collector_number,
							concatAttributeValue(cataloged_item.collection_object_id, 'sex') AS sex,
							concatAttributeValue(cataloged_item.collection_object_id, 'age') AS age,
							concatOtherId(cataloged_item.collection_object_id) AS other_id_list,
							concatParts(cataloged_item.collection_object_id) AS parts,
							collecting_event.verbatim_date,
							locality.orig_elev_units,
							locality.maximum_elevation,
							locality.minimum_elevation,
							coll_object_remark.coll_object_remarks
						FROM
							cataloged_item
							JOIN identification ON cataloged_item.collection_object_id = identification.collection_object_id
							JOIN collecting_event ON cataloged_item.collecting_event_id = collecting_event.collecting_event_id
							JOIN locality ON collecting_event.locality_id = locality.locality_id
							JOIN geog_auth_rec ON locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
							LEFT JOIN accepted_lat_long ON locality.locality_id = accepted_lat_long.locality_id
							LEFT JOIN coll_object_remark ON cataloged_item.collection_object_id = coll_object_remark.collection_object_id
						WHERE
							identification.accepted_id_fg = 1
							AND cataloged_item.collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.selectedIds#" list="yes">)
						<cfif variables.dataOrderBy EQ "scientific_name">
							ORDER BY identification.scientific_name, cataloged_item.collection_cde, cataloged_item.cat_num_prefix, cataloged_item.cat_num_integer, cataloged_item.cat_num_suffix
						<cfelseif variables.dataOrderBy EQ "location">
							ORDER BY geog_auth_rec.country, geog_auth_rec.state_prov, geog_auth_rec.county, geog_auth_rec.island, locality.spec_locality
						<cfelse>
							ORDER BY cataloged_item.collection_cde, cataloged_item.cat_num_prefix, cataloged_item.cat_num_integer, cataloged_item.cat_num_suffix
						</cfif>
					</cfquery>

					<cfset variables.headerText = "Permit Report:">
					<cfif len(permitInfo.issued_by_agent) GT 0>
						<cfset variables.headerText = "#variables.headerText# #permitInfo.issued_by_agent#">
					</cfif>
					<cfif len(permitInfo.permit_num) GT 0>
						<cfset variables.headerText = "#variables.headerText# No. #permitInfo.permit_num#">
					</cfif>
					<cfif len(permitInfo.issued_to_agent) GT 0>
						<cfset variables.headerText = "#variables.headerText# to #permitInfo.issued_to_agent#">
					</cfif>
					<cfif variables.headerText EQ "Permit Report:">
						<cfset variables.headerText = "Permit Report">
					</cfif>
					<cfset variables.maxPage = (data.recordcount - 1) \ ROWSPERPAGE + 1>
					<cfset variables.headerTextStyle = "font-family: 'Times New Roman', sans-serif; font-weight: 600; font-size: 8pt;">
					<cfset variables.textStyle = "font-family: 'Times New Roman', sans-serif; font-size: 5pt;">

					<!--- cfdocument applies a style only to a div around the text itself, not to a table, row or cell. --->
					<cfdocument format="pdf" pagetype="letter" fontembed="yes" margintop=".35" marginbottom="0" marginleft=".25" marginright=".25" unit="in" orientation="landscape" filename="#Application.webDirectory#/temp/permit_#session.DownloadFileID#.pdf" overwrite="true">
						<cfset variables.pageNum = 1>
						<cfset variables.curRow = 0>
						<cfloop query="data">
							<cfset variables.coordinates = "">
							<cfif len(data.verbatim_latitude) GT 0 AND len(data.verbatim_longitude) GT 0>
								<cfset variables.coordinates = encodeForHtml("#data.verbatim_latitude# / #data.verbatim_longitude#")>
								<cfset variables.coordinates = replace(variables.coordinates, "d", "&##176;", "all")>
								<cfset variables.coordinates = replace(variables.coordinates, "m", "'", "all")>
								<cfset variables.coordinates = replace(variables.coordinates, "s", "''", "all")>
							</cfif>
							<cfset variables.higherGeography = "">
							<cfloop list="country,state_prov,county,island" index="variables.geogField">
								<cfif len(data[variables.geogField][data.currentRow]) GT 0>
									<cfset variables.higherGeography = listAppend(variables.higherGeography, data[variables.geogField][data.currentRow], ";")>
								</cfif>
							</cfloop>
							<cfset variables.higherGeography = replace(variables.higherGeography, ";", "; ", "all")>
							<cfset variables.reportNote = "">
							<cfloop array="#variables.reportNotes#" index="variables.reportNoteItem">
								<cfif len(trim(variables.reportNoteItem.text)) GT 0 AND withinScope(data.cat_num, variables.reportNoteItem.scope)>
									<cfset variables.reportNote = "#variables.reportNote# #variables.reportNoteItem.text#">
								</cfif>
							</cfloop>
							<cfset variables.curRow = variables.curRow + 1>
							<cfif variables.curRow EQ 1>
								<table cellpadding="0" cellspacing="0" border="0" rules="rows">
									<colgroup span="4">
										<col width="250">
										<col width="250">
										<col width="370">
										<col width="130">
									</colgroup>
									<tr><td colspan="4"><hr></td></tr>
									<tr>
										<td colspan="3"><div style="#variables.headerTextStyle#">#encodeForHtml(variables.headerText)#</div></td>
										<td><div style="#variables.headerTextStyle#">Page #variables.pageNum# of #variables.maxPage#</div></td>
									</tr>
									<tr><td colspan="4"><hr></td></tr>
							</cfif>
									<tr>
										<td>
											<div style="#variables.textStyle#">
												<strong>#encodeForHtml(data.cat_num)#</strong><br>
												<strong>Parts:</strong> #encodeForHtml(data.parts)#<br>
												<strong>Sex:</strong> #encodeForHtml(data.sex)#
												<cfif data.collection_cde EQ "Bird" AND len(data.age) GT 0>
													<strong>Age:</strong> #encodeForHtml(data.age)#
												</cfif>
											</div>
										</td>
										<td>
											<div style="#variables.textStyle#">
												<strong><i>#encodeForHtml(data.scientific_name)#</i></strong><br>
												<cfif data.collectors EQ "not recorded">Collector:</cfif>
												#encodeForHtml(data.collectors)#
												<cfif len(data.collector_number) GT 0>(#encodeForHtml(data.collector_number)#)</cfif>
												<cfloop list="#data.other_id_list#" delimiters=";" index="variables.otherId">
													<cfif find("=", variables.otherId) GT 1 AND trim(listFirst(variables.otherId, "=")) NEQ "collector number">
														<br>#encodeForHtml(trim(listFirst(variables.otherId, "=")))#: #encodeForHtml(trim(listRest(variables.otherId, "=")))#
													</cfif>
												</cfloop>
											</div>
										</td>
										<td>
											<div style="#variables.textStyle#">
												#encodeForHtml(variables.higherGeography)#<br>
												#encodeForHtml(data.spec_locality)#;
												<cfif len(data.maximum_elevation) GT 0 AND len(data.minimum_elevation) GT 0 AND len(data.orig_elev_units) GT 0>
													<cfif data.maximum_elevation EQ data.minimum_elevation>
														#encodeForHtml(data.minimum_elevation)#
													<cfelse>
														#encodeForHtml(data.minimum_elevation)#-#encodeForHtml(data.maximum_elevation)#
													</cfif>
													#encodeForHtml(data.orig_elev_units)#.
												</cfif><br>
												#variables.coordinates#
												<cfif len(data.datum) GT 0>(#encodeForHtml(data.datum)#)</cfif>
												<cfif len(data.coll_object_remarks) GT 0>
													<br>Remarks: #encodeForHtml(data.coll_object_remarks)#
												</cfif>
											</div>
										</td>
										<td>
											<!--- the breaks keep each row at least the height the printed layout expects --->
											<div style="#variables.textStyle#"><br><br>#encodeForHtml(data.verbatim_date)#<br>&nbsp;</div>
										</td>
									</tr>
									<tr>
										<td colspan="4">
											<div style="#variables.textStyle#">
												<cfif len(variables.reportNote) GT 0>Note: #encodeForHtml(trim(variables.reportNote))#<cfelse>&nbsp;</cfif>
											</div>
										</td>
									</tr>
									<tr><td colspan="4"><hr></td></tr>
							<cfif variables.curRow EQ ROWSPERPAGE OR data.currentRow EQ data.recordcount>
								</table>
								<cfif data.currentRow LT data.recordcount>
									<cfdocumentitem type="pagebreak"></cfdocumentitem>
								</cfif>
								<cfset variables.curRow = 0>
								<cfset variables.pageNum = variables.pageNum + 1>
							</cfif>
						</cfloop>
					</cfdocument>
					<cfset variables.pdfMade = true>
				</cfif>
			</cfif>

			<h2 class="h3">
				#encodeForHtml(permitInfo.permit_type)#
				<cfif len(permitInfo.specific_type) GT 0>(#encodeForHtml(permitInfo.specific_type)#)</cfif>
				#encodeForHtml(permitInfo.permit_num)#
				#encodeForHtml(permitInfo.permit_title)#
			</h2>
			<p class="mb-2">
				Issued by: #encodeForHtml(permitInfo.issued_by_agent)#
				| Issued to: #encodeForHtml(permitInfo.issued_to_agent)#
				| Issued: #encodeForHtml(permitInfo.issued_date)#
				| Expires: #encodeForHtml(permitInfo.exp_date)#
				<a class="btn btn-xs btn-info ml-2" href="/transactions/Permit.cfm?action=view&permit_id=#encodeForUrl(permitInfo.permit_id)#">View Permissions &amp; Rights Document</a>
			</p>

			<cfif variables.pdfMade>
				<div class="alert alert-success" role="status">
					The PDF of #data.recordcount# specimens is ready.
					<a class="btn btn-xs btn-info ml-2" href="/temp/permit_#encodeForUrl(session.DownloadFileID)#.pdf?v=#getTickCount()#" target="_blank">Download the PDF</a>
				</div>
			<cfelseif len(variables.pdfProblem) GT 0>
				<div class="alert alert-warning" role="alert">#encodeForHtml(variables.pdfProblem)#</div>
			</cfif>

			<cfif specimens.recordcount EQ 0>
				<p>No cataloged items are associated with this permissions and rights document, through an accession or a loan shipment.</p>
			<cfelse>
				<form action="/Reports/permit.cfm" method="post" id="permitReportForm">
					<input type="hidden" name="action" value="generatePdf">
					<input type="hidden" name="permit_id" value="#encodeForHtml(permitInfo.permit_id)#">

					<section class="border rounded p-2 mb-2" aria-labelledby="pdfOptionsHeading">
						<h2 class="h3" id="pdfOptionsHeading">PDF</h2>
						<div class="form-row align-items-end">
							<div class="col-12 col-md-4 col-xl-3">
								<label for="data_order_by" class="data-entry-label">Order specimens in the PDF by</label>
								<select name="data_order_by" id="data_order_by" class="data-entry-select">
									<cfloop array="#ORDERINGS#" index="variables.ordering">
										<cfset variables.selected = "">
										<cfif variables.ordering.value EQ variables.dataOrderBy>
											<cfset variables.selected = "selected">
										</cfif>
										<option value="#variables.ordering.value#" #variables.selected#>#variables.ordering.label#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-8 col-xl-9 mt-2">
								<button type="submit" class="btn btn-xs btn-primary" id="generatePdfButton">Generate the PDF</button>
								<output id="includedCount" class="ml-2"></output>
							</div>
						</div>
					</section>

					<section class="border rounded p-2 mb-2" aria-labelledby="reportNotesHeading">
						<h2 class="h3" id="reportNotesHeading">Report Notes</h2>
						<p class="small mb-1">Notes are printed only in the PDF, under each specimen they apply to. They are not saved to the permit or the specimen records, and are kept only while you stay on this page to make the PDF again. List catalog numbers separated by commas, with ranges written low-high (e.g. A-1, 100-150, A-100-150), or leave them blank for every specimen.</p>
						<div id="reportNoteList" data-next-number="1"></div>
						<button type="button" class="btn btn-xs btn-secondary" onclick="addReportNote('reportNoteList');">Add Note</button>
					</section>

					<section class="border rounded p-2 mb-4" aria-labelledby="specimensHeading">
						<h2 class="h3" id="specimensHeading">Filter Specimens (#specimens.recordcount#)</h2>
						<!--- distinct values for including or leaving out every specimen sharing one --->
						<cfset variables.valueChoices = [
							{ key = "scientificName", attribute = "data-scientific-name", label = "Scientific name", values = structNew() },
							{ key = "higherGeography", attribute = "data-higher-geography", label = "Higher geography", values = structNew() },
							{ key = "verbatimDate", attribute = "data-verbatim-date", label = "Date", values = structNew() }
						]>
						<cfset variables.rowValues = []>
						<cfloop query="specimens">
							<cfset variables.higherGeography = "">
							<cfloop list="country,state_prov,county,island" index="variables.geogField">
								<cfif len(specimens[variables.geogField][specimens.currentRow]) GT 0>
									<cfset variables.higherGeography = listAppend(variables.higherGeography, specimens[variables.geogField][specimens.currentRow], ";")>
								</cfif>
							</cfloop>
							<cfset variables.higherGeography = replace(variables.higherGeography, ";", "; ", "all")>
							<cfset arrayAppend(variables.rowValues, { scientificName = specimens.scientific_name, higherGeography = variables.higherGeography, verbatimDate = specimens.verbatim_date })>
							<cfloop array="#variables.valueChoices#" index="variables.choice">
								<cfif len(variables.rowValues[specimens.currentRow][variables.choice.key]) GT 0>
									<cfset variables.choice.values[variables.rowValues[specimens.currentRow][variables.choice.key]] = true>
								</cfif>
							</cfloop>
						</cfloop>
						<div class="form-row mb-2">
							<div class="col-12 mb-1">
								<button type="button" class="btn btn-xs btn-secondary" onclick="setAllIncluded('specimenTable', true, 'includedCount');">Include All</button>
								<button type="button" class="btn btn-xs btn-warning" onclick="setAllIncluded('specimenTable', false, 'includedCount');">Include None</button>
							</div>
							<cfloop array="#variables.valueChoices#" index="variables.choice">
								<cfset variables.choiceValues = structKeyArray(variables.choice.values)>
								<cfset arraySort(variables.choiceValues, "textnocase")>
								<div class="col-12 col-md-6 col-xl-4 mb-1">
									<label for="#variables.choice.key#Choice" class="data-entry-label">#variables.choice.label#</label>
									<select id="#variables.choice.key#Choice" class="data-entry-select">
										<cfloop array="#variables.choiceValues#" index="variables.choiceValue">
											<option value="#encodeForHtmlAttribute(variables.choiceValue)#">#encodeForHtml(variables.choiceValue)#</option>
										</cfloop>
									</select>
									<button type="button" class="btn btn-xs btn-secondary mt-1" onclick="setIncludedByValue('specimenTable', '#variables.choice.attribute#', '#variables.choice.key#Choice', true, 'includedCount');">Include these</button>
									<button type="button" class="btn btn-xs btn-warning mt-1" onclick="setIncludedByValue('specimenTable', '#variables.choice.attribute#', '#variables.choice.key#Choice', false, 'includedCount');">Leave these out</button>
								</div>
							</cfloop>
						</div>
						<table class="table table-responsive d-xl-table table-sm permit-specimen-table" id="specimenTable" aria-labelledby="specimensHeading">
							<thead>
								<tr>
									<th scope="col">Include</th>
									<th scope="col" aria-sort="ascending"><button type="button" class="btn btn-link p-0 font-weight-bold" onclick="sortReportTable('specimenTable', this, 'data-sort-catalog');">Catalog Number</button></th>
									<th scope="col"><button type="button" class="btn btn-link p-0 font-weight-bold" onclick="sortReportTable('specimenTable', this, 'data-scientific-name');">Scientific Name</button></th>
									<th scope="col"><button type="button" class="btn btn-link p-0 font-weight-bold" onclick="sortReportTable('specimenTable', this, 'data-higher-geography');">Higher Geography</button></th>
									<th scope="col"><button type="button" class="btn btn-link p-0 font-weight-bold" onclick="sortReportTable('specimenTable', this, 'data-sort-date');">Date</button></th>
								</tr>
							</thead>
							<tbody>
								<cfloop query="specimens">
									<cfset variables.checked = "">
									<cfif listFind(variables.selectedIds, specimens.collection_object_id) GT 0>
										<cfset variables.checked = "checked">
									</cfif>
									<cfset variables.sortCatalog = "#specimens.collection_cde#|#specimens.cat_num_prefix#|#numberFormat(specimens.cat_num_integer, '000000000000')#|#specimens.cat_num_suffix#">
									<tr data-sort-catalog="#encodeForHtmlAttribute(variables.sortCatalog)#"
										data-scientific-name="#encodeForHtmlAttribute(variables.rowValues[specimens.currentRow].scientificName)#"
										data-higher-geography="#encodeForHtmlAttribute(variables.rowValues[specimens.currentRow].higherGeography)#"
										data-verbatim-date="#encodeForHtmlAttribute(variables.rowValues[specimens.currentRow].verbatimDate)#"
										data-sort-date="#encodeForHtmlAttribute(specimens.began_date)#">
										<td>
											<input type="checkbox" name="collection_object_id" value="#specimens.collection_object_id#" id="include_#specimens.collection_object_id#" #variables.checked# onchange="updateIncludedCount('specimenTable', 'includedCount');">
											<label for="include_#specimens.collection_object_id#" class="sr-only">Include #encodeForHtml(specimens.collection_cde)# #encodeForHtml(specimens.cat_num)#</label>
										</td>
										<td><a href="/specimens/Specimen.cfm?collection_object_id=#specimens.collection_object_id#" target="_blank">#encodeForHtml(specimens.collection_cde)# #encodeForHtml(specimens.cat_num)#</a></td>
										<td><i>#encodeForHtml(specimens.scientific_name)#</i></td>
										<td>#encodeForHtml(variables.rowValues[specimens.currentRow].higherGeography)#</td>
										<td>#encodeForHtml(specimens.verbatim_date)#</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</section>
				</form>
				<script>
					$(document).ready(function() {
						<cfloop array="#variables.reportNotes#" index="variables.reportNoteItem">
							addReportNote('reportNoteList', '#encodeForJavaScript(variables.reportNoteItem.text)#', '#encodeForJavaScript(variables.reportNoteItem.scope)#');
						</cfloop>
						updateIncludedCount('specimenTable', 'includedCount');
					});
				</script>
			</cfif>
		</div>
	</section>
</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
