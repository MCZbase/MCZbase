<!---
Reports/MCZDrawerTags.cfm

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
<!--- Drawer tags, slips and freezer sheets for the parts in a loan, reached from MCZ Drawer Tags on the
	loan page.  The page (action itemLabels) offers the formats and points out parts the chosen format
	cannot place; action pdf streams the PDF.  Originally by Peter DeVore, extended by Paul J. Morris. --->

<!--- The formats, in the order offered; Malacology is the general MCZ drawer tag. --->
<cfset FORMAT_LIST = "Malacology,Malacology2,Mammalogy,Bird/Mammal,Herp,Storage,Cryo-Sheet,Cryo-Sheet-R">
<cfset DEFAULT_FORMAT = "Malacology">
<cfset FORMAT_LABELS = {
	"Malacology" = "MCZ 1""x2"" drawer tag",
	"Malacology2" = "Malacology 1""x2"" drawer tag with container",
	"Mammalogy" = "Mammalogy 3""x2"" drawer tag",
	"Bird/Mammal" = "Bird/Mammal slips",
	"Herp" = "Herp slips",
	"Storage" = "Storage locations",
	"Cryo-Sheet" = "Cryogenic spreadsheet",
	"Cryo-Sheet-R" = "Cryogenic spreadsheet with remarks"
}>
<cfset FORMAT_DESCRIPTIONS = {
	"Malacology" = "Tags to cut out and place in the trays of loaned specimens: catalog number, higher taxa, name, type status, loan number and date. 14 to a page.",
	"Malacology2" = "As the MCZ drawer tag, with the part's container, preparation and lot count, and the borrower. 14 to a page.",
	"Mammalogy" = "Drawer tags with the collection, loan number and date, catalog number, name, part and borrower. 12 to a page.",
	"Bird/Mammal" = "One line slips: catalog number, name, loan number, date and recipient. 30 to a landscape page.",
	"Herp" = "Smaller one line slips with the same fields. 60 to a landscape page.",
	"Storage" = "For each part, its storage location, with the loan number and recipient. 18 to a page.",
	"Cryo-Sheet" = "A table of the cryovials in the loan by freezer rack, slot, box and position, for pulling them. 25 to a landscape page.",
	"Cryo-Sheet-R" = "The cryogenic spreadsheet with the part's remarks and those of the part it was sampled from. 12 to a landscape page."
}>
<!--- Collection names for the Mammalogy tag, by the collection code at the end of the loan number (yyyy-n-Coll). --->
<cfset LOAN_COLLECTION_NAMES = {
	"Herp" = "Herpetology Collection",
	"Mamm" = "Mammalogy Collection",
	"IZ" = "Invertebrate Zoology Collection",
	"Mala" = "Malacology Collection",
	"VP" = "Vertebrate Paleontology Collection",
	"SC" = "Special Collections",
	"MCZ" = "MCZ Collections",
	"IP" = "Invertebrate Paleontology Collection",
	"Ich" = "Ichthyology Collection",
	"Orn" = "Ornithology Collection",
	"Cryo" = "Cryogenic Collection",
	"Ent" = "Entomology Collection"
}>
<!--- Marks, in the cryogenic sheets, a loaned part that is the vial itself rather than a subsample of it. --->
<cfset NOT_SUBSAMPLE = "The Vial, Not A Subsample">

<cfparam name="url.action" default="">
<cfparam name="url.transaction_id" default="">
<cfparam name="url.format" default="">
<cfset variables.action = "itemLabels">
<cfif url.action EQ "pdf">
	<cfset variables.action = "pdf">
</cfif>
<cfset variables.transaction_id = trim(url.transaction_id)>
<cfset variables.format = DEFAULT_FORMAT>
<cfif listFind(FORMAT_LIST, url.format) GT 0>
	<cfset variables.format = url.format>
</cfif>
<cfset variables.isCryoSheet = (variables.format EQ "Cryo-Sheet" OR variables.format EQ "Cryo-Sheet-R")>

<!---
	getLoanForTags the loan whose parts are tagged.

	@param transaction_id the loan's transaction_id.
	@return a query with loan_number, trans_date and recipients (the received by agents), empty if
		there is no such loan.
--->
<cffunction name="getLoanForTags" returntype="query" output="false">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfset var getLoan = "">
	<cfquery name="getLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getLoan_result">
		SELECT
			loan.loan_number,
			trans.trans_date,
			(
				SELECT listagg(preferred_agent_name.agent_name, '; ') WITHIN GROUP (ORDER BY preferred_agent_name.agent_name)
				FROM trans_agent
					JOIN preferred_agent_name ON trans_agent.agent_id = preferred_agent_name.agent_id
				WHERE
					trans_agent.transaction_id = loan.transaction_id
					AND trans_agent.trans_agent_role = 'received by'
			) AS recipients
		FROM loan
			JOIN trans ON loan.transaction_id = trans.transaction_id
		WHERE
			loan.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.transaction_id#">
	</cfquery>
	<cfreturn getLoan>
</cffunction>

<!---
	getTagItems the loaned parts for a tag or slip format, one row per part.  A part with no current
	container is still listed, with no container.

	@param transaction_id the loan's transaction_id.
	@return a query of the parts, by catalog number.
--->
<cffunction name="getTagItems" returntype="query" output="false">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfset var getItems = "">
	<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getItems_result">
		SELECT DISTINCT
			cataloged_item.collection_cde,
			cataloged_item.cat_num,
			cataloged_item.collection_object_id,
			specimen_part.collection_object_id AS part_id,
			identification.scientific_name,
			MCZBASE.get_top_typestatus(cataloged_item.collection_object_id) AS typestatus,
			specimen_part.part_name,
			MCZBASE.get_part_prep(specimen_part.collection_object_id) AS part_prep,
			MCZBASE.get_parentcontainerlabel(specimen_part.collection_object_id) AS parentcontainer,
			MCZBASE.get_part_count_mod_for_part(specimen_part.collection_object_id) AS lot_count_mod,
			MCZBASE.get_storage_parentage(coll_obj_cont_hist.container_id) AS container,
			get_taxonomy(cataloged_item.collection_object_id, 'family') AS family,
			get_taxonomy(cataloged_item.collection_object_id, 'phylum') AS phylum
		FROM loan_item
			JOIN specimen_part ON loan_item.collection_object_id = specimen_part.collection_object_id
			JOIN cataloged_item ON specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
			JOIN identification ON cataloged_item.collection_object_id = identification.collection_object_id
				AND identification.accepted_id_fg = 1
			LEFT JOIN coll_obj_cont_hist ON loan_item.collection_object_id = coll_obj_cont_hist.collection_object_id
				AND coll_obj_cont_hist.current_container_fg = 1
		WHERE
			loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.transaction_id#">
		ORDER BY cataloged_item.cat_num
	</cfquery>
	<cfreturn getItems>
</cffunction>

<!---
	getCryoItems the loaned parts for the cryogenic sheets, with the freezer rack, rack slot, freezer
	box, position and cryovial each is in.  A subsample is placed by the vial it was sampled from;
	a loaned vial by itself.

	@param transaction_id the loan's transaction_id.
	@return a query of the parts, by rack, slot, box, position (numerically where it is a number),
		vial and catalog number.
--->
<cffunction name="getCryoItems" returntype="query" output="false">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfset var getItems = "">
	<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getItems_result">
		SELECT *
		FROM (
			SELECT
				cataloged_item.collection_cde,
				cataloged_item.cat_num,
				cataloged_item.collection_object_id,
				MCZBASE.concatotherid(cataloged_item.collection_object_id) AS otherids,
				c5.barcode AS rack,
				c4.barcode AS slot,
				c3.barcode AS box,
				c2.label AS position,
				c1.barcode AS vial,
				corem.coll_object_remarks AS part_remarks,
				pcorem.coll_object_remarks AS sampled_from_part_remarks
			FROM loan_item
				LEFT JOIN specimen_part ON loan_item.collection_object_id = specimen_part.collection_object_id
				LEFT JOIN coll_object_remark corem ON loan_item.collection_object_id = corem.collection_object_id
				LEFT JOIN coll_object_remark pcorem ON specimen_part.sampled_from_obj_id = pcorem.collection_object_id
				LEFT JOIN coll_obj_cont_hist ON specimen_part.sampled_from_obj_id = coll_obj_cont_hist.collection_object_id
				LEFT JOIN cataloged_item ON specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
				LEFT JOIN identification ON cataloged_item.collection_object_id = identification.collection_object_id
				LEFT JOIN MCZBASE.container c ON coll_obj_cont_hist.container_id = c.container_id
				LEFT JOIN MCZBASE.container c1 ON c.parent_container_id = c1.container_id
				LEFT JOIN MCZBASE.container c2 ON c1.parent_container_id = c2.container_id
				LEFT JOIN MCZBASE.container c3 ON c2.parent_container_id = c3.container_id
				LEFT JOIN MCZBASE.container c4 ON c3.parent_container_id = c4.container_id
				LEFT JOIN MCZBASE.container c5 ON c4.parent_container_id = c5.container_id
			WHERE
				identification.accepted_id_fg = 1
				AND coll_obj_cont_hist.current_container_fg = 1
				AND specimen_part.sampled_from_obj_id IS NOT NULL
				AND loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.transaction_id#">
			UNION
			SELECT
				cataloged_item.collection_cde,
				cataloged_item.cat_num,
				cataloged_item.collection_object_id,
				MCZBASE.concatotherid(cataloged_item.collection_object_id) AS otherids,
				c5.barcode AS rack,
				c4.barcode AS slot,
				c3.barcode AS box,
				c2.label AS position,
				c1.barcode AS vial,
				corem.coll_object_remarks AS part_remarks,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NOT_SUBSAMPLE#"> AS sampled_from_part_remarks
			FROM loan_item
				LEFT JOIN specimen_part ON loan_item.collection_object_id = specimen_part.collection_object_id
				LEFT JOIN coll_object_remark corem ON loan_item.collection_object_id = corem.collection_object_id
				LEFT JOIN coll_obj_cont_hist ON specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id
				LEFT JOIN cataloged_item ON specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
				LEFT JOIN identification ON cataloged_item.collection_object_id = identification.collection_object_id
				LEFT JOIN MCZBASE.container c ON coll_obj_cont_hist.container_id = c.container_id
				LEFT JOIN MCZBASE.container c1 ON c.parent_container_id = c1.container_id
				LEFT JOIN MCZBASE.container c2 ON c1.parent_container_id = c2.container_id
				LEFT JOIN MCZBASE.container c3 ON c2.parent_container_id = c3.container_id
				LEFT JOIN MCZBASE.container c4 ON c3.parent_container_id = c4.container_id
				LEFT JOIN MCZBASE.container c5 ON c4.parent_container_id = c5.container_id
			WHERE
				identification.accepted_id_fg = 1
				AND coll_obj_cont_hist.current_container_fg = 1
				AND specimen_part.sampled_from_obj_id IS NULL
				AND loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.transaction_id#">
		)
		<!--- A position that is not a number sorts after the numbered ones, rather than failing the sort. --->
		ORDER BY
			rack, slot, box,
			CASE WHEN regexp_like(position, '^[0-9]+$') THEN to_number(position) END,
			position, vial, cat_num
	</cfquery>
	<cfreturn getItems>
</cffunction>

<!---
	nameNearMiddleBreak a scientific name for a two line slip, broken at the space nearest its middle,
	with its other spaces kept from breaking.

	@param name the scientific name.
	@return the name as html, encoded.
--->
<cffunction name="nameNearMiddleBreak" returntype="string" output="false">
	<cfargument name="name" type="string" required="yes">
	<cfset var words = listToArray(arguments.name, " ")>
	<cfset var bestSplit = 0>
	<cfset var bestDistance = len(arguments.name)>
	<cfset var firstLength = 0>
	<cfset var i = 0>
	<cfset var firstPart = []>
	<cfset var secondPart = []>
	<cfif arrayLen(words) LT 2>
		<cfreturn encodeForHtml(arguments.name)>
	</cfif>
	<cfloop from="1" to="#arrayLen(words) - 1#" index="i">
		<cfset firstLength = firstLength + len(words[i]) + 1>
		<cfif abs(firstLength - len(arguments.name) / 2) LT bestDistance>
			<cfset bestDistance = abs(firstLength - len(arguments.name) / 2)>
			<cfset bestSplit = i>
		</cfif>
	</cfloop>
	<cfloop from="1" to="#arrayLen(words)#" index="i">
		<cfif i LTE bestSplit>
			<cfset arrayAppend(firstPart, encodeForHtml(words[i]))>
		<cfelse>
			<cfset arrayAppend(secondPart, encodeForHtml(words[i]))>
		</cfif>
	</cfloop>
	<cfreturn arrayToList(firstPart, "&nbsp;") & "<br>" & arrayToList(secondPart, "&nbsp;")>
</cffunction>

<!---
	unbroken a value as html that does not break at its spaces.

	@param value the text.
	@return the text encoded, its spaces non-breaking.
--->
<cffunction name="unbroken" returntype="string" output="false">
	<cfargument name="value" type="string" required="yes">
	<cfreturn replace(encodeForHtml(arguments.value), " ", "&nbsp;", "all")>
</cffunction>

<!------------------------------------------------------------------------------------------>
<cfif variables.action EQ "pdf">
	<!--- The PDF streams before the shared header would run, so it needs its own role check. --->
	<cf_rolecheck>
	<cfif NOT isValid("integer", variables.transaction_id)>
		<cfthrow message="No loan was given to print drawer tags for.">
	</cfif>
	<cfset variables.loan = getLoanForTags(variables.transaction_id)>
	<cfif variables.loan.recordcount EQ 0>
		<cfthrow message="There is no loan with transaction_id #encodeForHtml(variables.transaction_id)#.">
	</cfif>
	<cfset variables.loanNumber = variables.loan.loan_number>
	<cfset variables.recipients = variables.loan.recipients>
	<cfset variables.collectionName = "[Unable to identify collection from loan number] #listLast(variables.loanNumber, '-')#">
	<cfif structKeyExists(LOAN_COLLECTION_NAMES, listLast(variables.loanNumber, "-"))>
		<cfset variables.collectionName = LOAN_COLLECTION_NAMES[listLast(variables.loanNumber, "-")]>
	</cfif>
	<cfset variables.fileName = "MCZ_Drawer_Tags_#reReplace(variables.loanNumber, '[^A-Za-z0-9_-]', '_', 'all')#.pdf">
	<cfif variables.isCryoSheet>
		<!--- A table of the cryovials, a fixed number of rows to a page, each page with its own header row. --->
		<cfset variables.items = getCryoItems(variables.transaction_id)>
		<cfset variables.rowsPerPage = 25>
		<cfset variables.withRemarks = false>
		<cfif variables.format EQ "Cryo-Sheet-R">
			<cfset variables.rowsPerPage = 12>
			<cfset variables.withRemarks = true>
		</cfif>
		<cfset variables.pageCount = max(1, ceiling(variables.items.recordcount / variables.rowsPerPage))>
		<cfset variables.cellStyle = "border: 1px solid gray;">
		<cfdocument format="pdf" pagetype="letter" margintop=".25" marginbottom=".25" marginleft=".25" marginright=".25" orientation="landscape" fontembed="yes" saveAsName="#variables.fileName#">
			<cfoutput>
				<link rel="stylesheet" type="text/css" href="/includes/_cfdocstyle.css">
				<cfloop from="1" to="#variables.pageCount#" index="variables.page">
					<div style="font-size: 10px; font-weight: 600;">Page #variables.page# of #variables.pageCount#</div>
					<table width="100%" cellspacing="0" cellpadding="4" style="border: 1px solid black; border-collapse: collapse;">
						<tr>
							<th style="#variables.cellStyle#"><span class="times12b">Catalog Number</span></th>
							<th style="#variables.cellStyle#"><span class="times12b">Other Numbers</span></th>
							<th style="#variables.cellStyle#"><span class="times12b">Freezer Rack</span></th>
							<th style="#variables.cellStyle#"><span class="times12b">Rack Slot</span></th>
							<th style="#variables.cellStyle#"><span class="times12b">Freezer Box</span></th>
							<th style="#variables.cellStyle#"><span class="times12b">Position</span></th>
							<th style="#variables.cellStyle#"><span class="times12b">Cryovial</span></th>
							<cfif variables.withRemarks>
								<th style="#variables.cellStyle#"><span class="times12b">Part Remarks</span></th>
								<th style="#variables.cellStyle#"><span class="times12b">Sampled From Part Remarks</span></th>
							</cfif>
						</tr>
						<cfset variables.firstRow = (variables.page - 1) * variables.rowsPerPage + 1>
						<cfloop query="variables.items" startrow="#variables.firstRow#" endrow="#variables.firstRow + variables.rowsPerPage - 1#">
							<tr>
								<td style="#variables.cellStyle#"><span class="times12">#encodeForHtml(variables.items.collection_cde)# #encodeForHtml(variables.items.cat_num)#</span></td>
								<td style="#variables.cellStyle#"><span class="times12">#encodeForHtml(variables.items.otherids)#</span></td>
								<td style="#variables.cellStyle#"><span class="times12"><strong>#encodeForHtml(variables.items.rack)#</strong></span></td>
								<td style="#variables.cellStyle#"><span class="times12"><strong>#encodeForHtml(variables.items.slot)#</strong></span></td>
								<td style="#variables.cellStyle#"><span class="times12">#encodeForHtml(variables.items.box)#</span></td>
								<td style="#variables.cellStyle#"><span class="times12"><strong>#encodeForHtml(variables.items.position)#</strong></span></td>
								<td style="#variables.cellStyle#">
									<span class="times12">
										#encodeForHtml(variables.items.vial)#
										<cfif variables.items.sampled_from_part_remarks EQ NOT_SUBSAMPLE>(Not a Subsample)</cfif>
									</span>
								</td>
								<cfif variables.withRemarks>
									<td style="#variables.cellStyle#"><span class="times12">#encodeForHtml(variables.items.part_remarks)#</span></td>
									<td style="#variables.cellStyle#"><span class="times12">#encodeForHtml(variables.items.sampled_from_part_remarks)#</span></td>
								</cfif>
							</tr>
						</cfloop>
					</table>
					<cfif variables.page LT variables.pageCount>
						<cfdocumentitem type="pagebreak"></cfdocumentitem>
					</cfif>
				</cfloop>
			</cfoutput>
		</cfdocument>
	<cfelse>
		<!--- Labels in two columns, filled down each column then across, a fixed number to a column. --->
		<cfset variables.items = getTagItems(variables.transaction_id)>
		<cfset variables.columns = 2>
		<cfset variables.showPageNumbers = true>
		<cfset variables.orientation = "landscape">
		<cfset variables.labelBorder = "border: 1px solid black;">
		<cfset variables.labelWidth = "width: 368px;">
		<cfswitch expression="#variables.format#">
			<cfcase value="Bird/Mammal">
				<cfset variables.rowsPerColumn = 15>
				<cfset variables.textClass = "times10">
				<cfset variables.labelHeight = "height: 32px;">
			</cfcase>
			<cfcase value="Herp">
				<cfset variables.rowsPerColumn = 30>
				<cfset variables.textClass = "times8">
				<cfset variables.labelHeight = "height: 17px;">
			</cfcase>
			<cfcase value="Storage">
				<cfset variables.rowsPerColumn = 9>
				<cfset variables.textClass = "times10">
				<cfset variables.labelHeight = "height: 17px;">
				<cfset variables.orientation = "portrait">
			</cfcase>
			<cfcase value="Malacology">
				<cfset variables.rowsPerColumn = 7>
				<cfset variables.textClass = "times10">
				<cfset variables.labelWidth = "width: 2.0in;">
				<cfset variables.labelHeight = "height: 1.0in;">
				<cfset variables.labelBorder = "border: 0px;">
				<cfset variables.orientation = "portrait">
				<cfset variables.showPageNumbers = false>
			</cfcase>
			<cfcase value="Malacology2">
				<cfset variables.rowsPerColumn = 7>
				<cfset variables.textClass = "times8">
				<cfset variables.labelWidth = "width: 2.1in;">
				<cfset variables.labelHeight = "height: 1.0in;">
				<cfset variables.labelBorder = "border: 0px;">
				<cfset variables.orientation = "portrait">
				<cfset variables.showPageNumbers = false>
			</cfcase>
			<cfcase value="Mammalogy">
				<cfset variables.rowsPerColumn = 6>
				<cfset variables.textClass = "times12">
				<cfset variables.labelWidth = "width: 3.3in;">
				<cfset variables.labelHeight = "height: 1.4in;">
				<cfset variables.labelBorder = "border: 0px;">
				<cfset variables.orientation = "portrait">
				<cfset variables.showPageNumbers = false>
			</cfcase>
		</cfswitch>
		<cfset variables.labelStyle = "#variables.labelHeight# #variables.labelWidth# #variables.labelBorder#">
		<cfset variables.perPage = variables.rowsPerColumn * variables.columns>
		<cfset variables.pageCount = max(1, ceiling(variables.items.recordcount / variables.perPage))>
		<cfset variables.loanDate = dateFormat(variables.loan.trans_date, "dd mmm yyyy")>
		<cfdocument format="pdf" pagetype="letter" margintop=".25" marginbottom=".25" marginleft=".25" marginright=".25" orientation="#variables.orientation#" fontembed="yes" saveAsName="#variables.fileName#">
			<cfoutput>
				<link rel="stylesheet" type="text/css" href="/includes/_cfdocstyle.css">
				<cfloop from="1" to="#variables.pageCount#" index="variables.page">
					<cfif variables.showPageNumbers>
						<div style="font-size: 10px; font-weight: 600;">Page #variables.page# of #variables.pageCount#</div>
					</cfif>
					<table width="100%" cellspacing="0" cellpadding="0" border="0">
						<tr>
							<cfloop from="1" to="#variables.columns#" index="variables.column">
								<cfset variables.firstRow = (variables.page - 1) * variables.perPage + (variables.column - 1) * variables.rowsPerColumn + 1>
								<cfif variables.firstRow LTE variables.items.recordcount>
									<td valign="top">
										<table width="100%" cellspacing="0" cellpadding="0" border="0">
											<cfloop query="variables.items" startrow="#variables.firstRow#" endrow="#variables.firstRow + variables.rowsPerColumn - 1#">
												<tr><td><div style="#variables.labelStyle#">
													<cfswitch expression="#variables.format#">
														<cfcase value="Storage">
															<table>
																<tr>
																	<td colspan="2" align="center"><span class="#variables.textClass#"><strong>Loan Number:</strong> #encodeForHtml(variables.loanNumber)# &nbsp; <strong>On Loan To:</strong> #encodeForHtml(variables.recipients)#</span></td>
																</tr>
																<tr>
																	<td><span class="#variables.textClass#"><i>#unbroken(variables.items.scientific_name)#</i> <strong>#encodeForHtml(variables.items.collection_cde)# #encodeForHtml(variables.items.cat_num)#</strong></span></td>
																</tr>
																<tr>
																	<td><span class="#variables.textClass#">#encodeForHtml(variables.items.container)#</span></td>
																</tr>
															</table>
														</cfcase>
														<cfcase value="Malacology,Malacology2">
															<!--- Higher taxa are cut short beside a long name. --->
															<cfset variables.higherTaxa = trim("#variables.items.phylum# #variables.items.family#")>
															<cfif len(variables.items.scientific_name) GT 22 AND len(variables.higherTaxa) GT 20>
																<cfset variables.higherTaxa = left(variables.higherTaxa, 20) & "...">
															</cfif>
															<cfif variables.format EQ "Malacology">
																<table>
																	<tr>
																		<td colspan="2"><span class="#variables.textClass#"><strong>#encodeForHtml(variables.items.collection_cde)# #encodeForHtml(variables.items.cat_num)#</strong></span>&nbsp;<span class="#variables.textClass#">#unbroken(variables.higherTaxa)#</span></td>
																	</tr>
																	<tr>
																		<td colspan="2"><div class="#variables.textClass#"><i>#unbroken(variables.items.scientific_name)#</i> <span style="float: right;"><strong>#encodeForHtml(variables.items.typestatus)#</strong></span></div></td>
																	</tr>
																	<tr>
																		<td><span class="#variables.textClass#"><strong>Loan Number:</strong> #encodeForHtml(variables.loanNumber)#</span></td>
																		<td><div class="#variables.textClass#">#variables.loanDate#</div></td>
																	</tr>
																	<tr>
																		<td colspan="2" align="center"><div class="#variables.textClass#"><strong>Museum of Comparative Zoology</strong></div></td>
																	</tr>
																</table>
															<cfelse>
																<!--- The museum itself as a part's container says nothing on a tag. --->
																<cfset variables.partContainer = variables.items.parentcontainer>
																<cfif variables.partContainer EQ "The Museum of Comparative Zoology">
																	<cfset variables.partContainer = "">
																</cfif>
																<table style="font-size: smaller; line-height: 85%; padding: 0px;">
																	<tr>
																		<td colspan="2"><span class="#variables.textClass#"><strong>#unbroken("#variables.items.collection_cde# #variables.items.cat_num#")#</strong></span>&nbsp;<span class="#variables.textClass#">#unbroken(variables.higherTaxa)#</span></td>
																	</tr>
																	<tr>
																		<td colspan="2"><div class="#variables.textClass#"><i>#unbroken(variables.items.scientific_name)#</i> <span style="float: right;"><strong>#encodeForHtml(variables.items.typestatus)#</strong></span></div></td>
																	</tr>
																	<tr>
																		<td colspan="2"><span class="#variables.textClass#">#encodeForHtml(variables.partContainer)# #encodeForHtml(variables.items.part_prep)# #encodeForHtml(variables.items.lot_count_mod)#</span></td>
																	</tr>
																	<tr>
																		<td colspan="2" align="center"><span class="#variables.textClass#"><strong>On Loan To:</strong> #encodeForHtml(variables.recipients)#</span></td>
																	</tr>
																	<tr>
																		<td><span class="#variables.textClass#"><strong>Loan Number:</strong> #encodeForHtml(variables.loanNumber)#</span></td>
																		<td><div class="#variables.textClass#">#unbroken(variables.loanDate)#</div></td>
																	</tr>
																	<tr>
																		<td colspan="2" align="center"><div class="#variables.textClass#"><strong>Museum of Comparative Zoology</strong></div></td>
																	</tr>
																</table>
															</cfif>
														</cfcase>
														<cfcase value="Mammalogy">
															<table width="100%" style="border: 1px solid black;">
																<tr>
																	<td colspan="2" align="center"><div class="#variables.textClass#"><strong>MCZ #encodeForHtml(variables.collectionName)#</strong></div></td>
																</tr>
																<tr>
																	<td><span class="#variables.textClass#"><strong>Loan No.:</strong> #encodeForHtml(variables.loanNumber)#</span></td>
																	<td><div class="#variables.textClass#"><strong>Date:</strong> #variables.loanDate#</div></td>
																</tr>
																<tr>
																	<td colspan="2"><span class="#variables.textClass#"><strong>MCZ #encodeForHtml(variables.items.collection_cde)# #encodeForHtml(variables.items.cat_num)#</strong></span></td>
																</tr>
																<tr>
																	<td colspan="2"><div class="#variables.textClass#"><i>#encodeForHtml(variables.items.scientific_name)#</i></div></td>
																</tr>
																<tr>
																	<td colspan="2"><span class="#variables.textClass#"><strong>Nature:</strong> #encodeForHtml(variables.items.part_name)#</span></td>
																</tr>
																<tr>
																	<td colspan="2"><span class="#variables.textClass#"><strong>Borrower:</strong> #encodeForHtml(variables.recipients)#</span></td>
																</tr>
															</table>
														</cfcase>
														<cfdefaultcase>
															<!--- Bird/Mammal and Herp slips: one line, the Bird/Mammal name and date over two. --->
															<cfif variables.format EQ "Bird/Mammal">
																<cfset variables.nameHtml = nameNearMiddleBreak(variables.items.scientific_name)>
																<cfset variables.dateHtml = "#dateFormat(variables.loan.trans_date, 'dd mmm')#<br>#dateFormat(variables.loan.trans_date, 'yyyy')#">
																<cfset variables.dateWidth = "width: 40px;">
															<cfelse>
																<cfset variables.nameHtml = unbroken(variables.items.scientific_name)>
																<cfset variables.dateHtml = variables.loanDate>
																<cfset variables.dateWidth = "width: 50px;">
															</cfif>
															<table>
																<tr>
																	<td><span class="#variables.textClass#">#encodeForHtml(variables.items.cat_num)#</span></td>
																	<td><div class="#variables.textClass#"><i>#variables.nameHtml#</i></div></td>
																	<td><span class="#variables.textClass#">#encodeForHtml(variables.loanNumber)#</span></td>
																	<td><div class="#variables.textClass#" style="#variables.dateWidth#">#variables.dateHtml#</div></td>
																	<td><span class="#variables.textClass#">#encodeForHtml(variables.recipients)#</span></td>
																</tr>
															</table>
														</cfdefaultcase>
													</cfswitch>
												</div></td></tr>
											</cfloop>
										</table>
									</td>
								</cfif>
							</cfloop>
						</tr>
					</table>
					<cfif variables.page LT variables.pageCount>
						<cfdocumentitem type="pagebreak"></cfdocumentitem>
					</cfif>
				</cfloop>
			</cfoutput>
		</cfdocument>
	</cfif>
	<cfabort>
</cfif>

<!------------------------------------------------------------------------------------------>
<cfset pageTitle = "Loan Drawer Tags">
<cfinclude template="/shared/_header.cfm">
<cfoutput>
	<!--- Offered when no loan, or no such loan, is given; picking a loan opens its drawer tags in the format asked for. --->
	<cfsavecontent variable="variables.loanPicker">
		<form name="pickLoan" id="pickLoan" method="get" action="/Reports/MCZDrawerTags.cfm" class="col-12 px-0" onSubmit="return loanIsPicked('pickedTransactionId');">
			<input type="hidden" name="action" value="itemLabels">
			<input type="hidden" name="format" value="#encodeForHtmlAttribute(variables.format)#">
			<input type="hidden" name="transaction_id" id="pickedTransactionId" value="">
			<!--- The help is below the row, so the button lines up with the input rather than the help. --->
			<div class="form-row align-items-end">
				<div class="col-12 col-md-6">
					<label for="pickLoanNumber" class="data-entry-label">Loan Number</label>
					<input type="text" id="pickLoanNumber" class="data-entry-input" aria-describedby="pickLoanHelp" required onInput="$('##pickedTransactionId').val('');">
				</div>
				<div class="col-12 col-md-6 mt-1 mt-md-0">
					<button type="submit" class="btn btn-xs btn-primary">Show Drawer Tags</button>
				</div>
			</div>
			<small id="pickLoanHelp" class="d-block text-secondary mb-2">Type at least three characters of the loan number, then pick the loan.</small>
		</form>
		<script>
			$(document).ready(function() {
				makeLoanPicker('pickLoanNumber', 'pickedTransactionId', function() { $('##pickLoan').submit(); });
			});
			/** Whether a loan has been picked from the list; typing after a pick clears it, so it must be picked again.
			 * @param idControl the id of the hidden input for the picked transaction_id, without a leading ##.
			 * @return true if a loan is picked, otherwise false, after saying to pick one.
			 */
			function loanIsPicked(idControl) {
				if ($('##' + idControl).val() == '') {
					messageDialog('Pick a loan from the list that appears as you type its number.', 'Pick a Loan');
					return false;
				}
				return true;
			}
		</script>
	</cfsavecontent>
	<main class="container py-3" id="content">
		<cfif NOT isValid("integer", variables.transaction_id)>
			<section class="row mx-0">
				<h1 class="h2">Loan Drawer Tags</h1>
				<p class="col-12 px-0">Pick the loan to print drawer tags for, or open MCZ Drawer Tags from the print menu of a loan.</p>
				#variables.loanPicker#
			</section>
		<cfelse>
			<cfset variables.loan = getLoanForTags(variables.transaction_id)>
			<cfif variables.loan.recordcount EQ 0>
				<section class="row mx-0">
					<h1 class="h2">Loan Drawer Tags</h1>
					<p class="col-12 px-0">There is no loan with transaction_id #encodeForHtml(variables.transaction_id)#.  Pick the loan to print drawer tags for.</p>
					#variables.loanPicker#
				</section>
			<cfelse>
				<cfif variables.isCryoSheet>
					<cfset variables.items = getCryoItems(variables.transaction_id)>
				<cfelse>
					<cfset variables.items = getTagItems(variables.transaction_id)>
				</cfif>
				<section class="row mx-0 border rounded my-2 px-3 py-2" aria-labelledby="drawerTagsHeading">
					<h1 class="h2 col-12 px-0" id="drawerTagsHeading">
						Drawer Tags for Loan
						<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#encodeForUrl(variables.transaction_id)#">#encodeForHtml(variables.loan.loan_number)#</a>
					</h1>
					<p class="col-12 px-0 mb-2">
						Loaned #dateFormat(variables.loan.trans_date, "d mmmm yyyy")#<cfif len(variables.loan.recipients) GT 0>, received by #encodeForHtml(variables.loan.recipients)#</cfif>.
					</p>
					<!--- Changing the format reloads this page, to check the parts against it, rather than printing at once. --->
					<form name="drawerTagFormat" id="drawerTagFormat" method="get" action="/Reports/MCZDrawerTags.cfm" class="col-12 px-0">
						<input type="hidden" name="action" value="itemLabels">
						<input type="hidden" name="transaction_id" value="#encodeForHtmlAttribute(variables.transaction_id)#">
						<div class="form-row align-items-end">
							<div class="col-12 col-md-6 mb-2">
								<label for="format" class="data-entry-label">Format</label>
								<select name="format" id="format" class="data-entry-select" aria-describedby="formatDescription" onChange="this.form.submit();">
									<cfloop list="#FORMAT_LIST#" index="variables.formatOption">
										<cfset variables.selected = "">
										<cfif variables.formatOption EQ variables.format>
											<cfset variables.selected = "selected">
										</cfif>
										<option value="#encodeForHtmlAttribute(variables.formatOption)#" #variables.selected#>#encodeForHtml(FORMAT_LABELS[variables.formatOption])#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-6 mb-2">
								<noscript><button type="submit" class="btn btn-xs btn-secondary">Change Format</button></noscript>
							</div>
						</div>
						<p id="formatDescription" class="small text-secondary mb-2">#encodeForHtml(FORMAT_DESCRIPTIONS[variables.format])#</p>
					</form>
					<div class="col-12 px-0 mb-2">
						<cfif variables.items.recordcount EQ 0>
							<p>
								<cfif variables.isCryoSheet>
									No parts in this loan are in a cryovial in the freezers.
								<cfelse>
									This loan has no parts.
								</cfif>
							</p>
						<cfelse>
							<a href="/Reports/MCZDrawerTags.cfm?action=pdf&transaction_id=#encodeForUrl(variables.transaction_id)#&format=#encodeForUrl(variables.format)#" class="btn btn-xs btn-info" target="_blank">Print #variables.items.recordcount# #encodeForHtml(FORMAT_LABELS[variables.format])# (PDF)</a>
						</cfif>
					</div>
				</section>
				<cfif variables.isCryoSheet AND variables.items.recordcount GT 0>
					<!--- A vial out of place in the freezers prints with blanks, or after the others when its position is not a number. --->
					<cfset variables.misplaced = []>
					<cfset variables.unnumbered = []>
					<cfloop query="variables.items">
						<cfset variables.partName = "#variables.items.collection_cde# #variables.items.cat_num#">
						<cfif len(variables.items.rack) EQ 0 OR len(variables.items.slot) EQ 0 OR len(variables.items.box) EQ 0 OR len(variables.items.position) EQ 0 OR len(variables.items.vial) EQ 0>
							<cfset arrayAppend(variables.misplaced, "#variables.partName#: rack #variables.items.rack#, slot #variables.items.slot#, box #variables.items.box#, position #variables.items.position#, vial #variables.items.vial#")>
						<cfelseif NOT reFind("^[0-9]+$", variables.items.position)>
							<cfset arrayAppend(variables.unnumbered, "#variables.partName#: position #variables.items.position# is not a number")>
						</cfif>
					</cfloop>
					<cfif arrayLen(variables.misplaced) GT 0 OR arrayLen(variables.unnumbered) GT 0>
						<section class="row mx-0 mb-4" aria-labelledby="misplacedHeading">
							<div class="col-12 px-0">
								<div class="alert alert-warning">
									<h2 class="h4" id="misplacedHeading">Parts this sheet cannot place fully</h2>
									<p class="mb-1">
										The sheet expects each part to be a cryovial in a numbered position of a freezer box, in a rack slot of a freezer rack.
										These parts will print with blanks, or after the others; check their placement.
									</p>
									<ul class="mb-0">
										<cfloop array="#variables.misplaced#" index="variables.problem">
											<li>#encodeForHtml(variables.problem)#</li>
										</cfloop>
										<cfloop array="#variables.unnumbered#" index="variables.problem">
											<li>#encodeForHtml(variables.problem)#</li>
										</cfloop>
									</ul>
								</div>
							</div>
						</section>
					</cfif>
				</cfif>
			</cfif>
		</cfif>
	</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
