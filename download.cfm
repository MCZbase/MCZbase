<!---
download.cfm

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
<!--- Sends a file another page has written to /download/ as an attachment, so the browser saves
	it rather than displaying it.  Only a file directly in /download/ may be served. --->
<cfinclude template="/shared/fileFunctions.cfm">
<cfparam name="url.file" default="">
<cfset DOWNLOAD_DIRECTORY = "#Application.webDirectory#/download">
<cfset MIME_TYPES = { csv="text/csv", txt="text/plain", xml="application/xml", zip="application/zip" }>

<cfset variables.downloadFile = resolveFileInDirectory(DOWNLOAD_DIRECTORY, url.file, structKeyList(MIME_TYPES))>
<cfif len(variables.downloadFile) EQ 0>
	<cfheader statuscode="404" statustext="Not Found">
	File not found.
	<cfabort>
</cfif>
<cfheader name="Content-Disposition" value="#attachmentDisposition(url.file)#">
<cfcontent type="#MIME_TYPES[lcase(listLast(url.file, '.'))]#" file="#variables.downloadFile#">
