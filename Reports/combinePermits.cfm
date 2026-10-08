<!---
Reports/combinePermits.cfm

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
<!--- Combines the PDF permit documents for the material in a loan, and for its shipments, into one
	PDF for printing.  Uses cfhttp and cfpdf rather than PDFBox and HttpClient, which had to be added
	to the server by hand and were lost in a ColdFusion update. --->
<cfinclude template="/shared/component/fileUtilities.cfc" runOnce="true">
<cfparam name="url.transaction_id" default="">

<cfset variables.permitFiles = ArrayNew(1)>
<cfif isValid("integer", url.transaction_id)>
	<cfquery name="getPermitMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getPermitMedia_result">
		select distinct media_id, uri, permit_type, permit_num
		from (
			select media.media_id, media.media_uri as uri, p.permit_type, p.permit_num
			from loan_item li
				left join specimen_part sp on li.collection_object_id = sp.collection_object_id
				left join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
				left join accn on ci.accn_id = accn.transaction_id
				left join permit_trans on accn.transaction_id = permit_trans.transaction_id
				left join permit p on permit_trans.permit_id = p.permit_id
				left join ctspecific_permit_type on p.specific_type = ctspecific_permit_type.specific_type
				left join media_relations on p.permit_id = media_relations.related_primary_key
				left join media on media_relations.media_id = media.media_id
			where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#url.transaction_id#">
				and (
					media_relations.related_primary_key is null
					or (media_relations.media_relationship = 'shows permit' and mime_type = 'application/pdf')
				)
				and media.media_id is not null
				and ctspecific_permit_type.accn_show_on_shipment = 1
			union
			select media.media_id, media.media_uri as uri, p.permit_type, p.permit_num
			from shipment s
				left join permit_shipment ps on s.shipment_id = ps.shipment_id
				left join permit p on ps.permit_id = p.permit_id
				left join media_relations on p.permit_id = media_relations.related_primary_key
				left join media on media_relations.media_id = media.media_id
			where s.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#url.transaction_id#">
				and (
					media_relations.related_primary_key is null
					or (media_relations.media_relationship = 'shows permit' and mime_type = 'application/pdf')
				)
		)
		where permit_type is not null
			and media_id is not null
	</cfquery>
	<cfset variables.downloadFile = "permits_#session.DownloadFileID#.pdf">
	<cfset variables.downloadTarget = "#Application.DownloadPath##variables.downloadFile#">
	<cftry>
		<cfloop query="getPermitMedia">
			<cfset variables.tempFile = "#Application.DownloadPath#temp#getPermitMedia.currentRow#_#variables.downloadFile#">
			<!--- redirect follows the 302s from the media server to the stored file --->
			<cfhttp url="#getPermitMedia.uri#" method="get" redirect="yes" timeout="60" getasbinary="yes"
				path="#getDirectoryFromPath(variables.tempFile)#" file="#getFileFromPath(variables.tempFile)#" result="permitResponse">
			<cfif left(permitResponse.statusCode, 3) EQ "200" AND fileExists(variables.tempFile) AND isPDFFile(variables.tempFile)>
				<cfset arrayAppend(variables.permitFiles, variables.tempFile)>
			<cfelse>
				<cflog file="MCZbase" text="combinePermits: media_id #getPermitMedia.media_id# was not retrieved as a PDF (#permitResponse.statusCode#)">
			</cfif>
		</cfloop>
		<cfif arrayLen(variables.permitFiles) GT 0>
			<cfpdf action="merge" destination="#variables.downloadTarget#" overwrite="yes">
				<cfloop from="1" to="#arrayLen(variables.permitFiles)#" index="i">
					<cfpdfparam source="#variables.permitFiles[i]#">
				</cfloop>
			</cfpdf>
		</cfif>
	<cffinally>
		<cfloop query="getPermitMedia">
			<cfset variables.tempFile = "#Application.DownloadPath#temp#getPermitMedia.currentRow#_#variables.downloadFile#">
			<cfif fileExists(variables.tempFile)>
				<cfset fileDelete(variables.tempFile)>
			</cfif>
		</cfloop>
	</cffinally>
	</cftry>
</cfif>

<cfif arrayLen(variables.permitFiles) GT 0>
	<cfheader name="Content-Disposition" value="#attachmentDisposition(variables.downloadFile)#">
	<cfcontent file="#variables.downloadTarget#" type="application/pdf" deleteFile="yes">
<cfelse>
	<cfset pageTitle = "Permit Documents">
	<cfinclude template="/shared/_header.cfm">
	<main class="container py-3" id="content">
		<section class="row mb-4">
			<div class="col-12">
				<h1 class="h2">Permit Documents</h1>
				<p>No PDF permit documents could be retrieved for this transaction.</p>
			</div>
		</section>
	</main>
	<cfinclude template="/shared/_footer.cfm">
</cfif>
