<cfset pageTitle = "Media Licenses">
<!---
/Admin/ctmedia_license.cfm

Manage the ctmedia_license controlled vocabulary table. Provides insert, update,
and delete for media license records (display name, description, URI).

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
<cfinclude template="/shared/_header.cfm">

<cfset variables.action = "entryPoint">
<cfif isDefined("form.action") AND len(trim(form.action)) GT 0>
<cfset variables.action = trim(form.action)>
<cfelseif isDefined("url.action") AND len(trim(url.action)) GT 0>
<cfset variables.action = trim(url.action)>
</cfif>

<cfif variables.action IS "delete">
<cfif isDefined("form.media_license_id") AND isNumeric(form.media_license_id)>
 name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
FROM ctmedia_license
media_license_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.media_license_id#">
>
</cfif>
<cflocation url="/Admin/ctmedia_license.cfm" addtoken="false">
</cfif>

<cfif variables.action IS "save">
<cfif isDefined("form.media_license_id") AND isNumeric(form.media_license_id)
D isDefined("form.display") AND isDefined("form.description") AND isDefined("form.uri")>
 name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
ctmedia_license SET
     = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.display)#">,
 = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.description)#">,
        = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.uri)#">
media_license_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.media_license_id#">
>
</cfif>
<cflocation url="/Admin/ctmedia_license.cfm" addtoken="false">
</cfif>

<cfif variables.action IS "insert">
<cfif isDefined("form.display") AND len(trim(form.display)) GT 0
D isDefined("form.description") AND isDefined("form.uri")>
 name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
SERT INTO ctmedia_license (display, description, uri)
(
param cfsqltype="CF_SQL_VARCHAR" value="#trim(form.display)#">,
param cfsqltype="CF_SQL_VARCHAR" value="#trim(form.description)#">,
param cfsqltype="CF_SQL_VARCHAR" value="#trim(form.uri)#">
>
</cfif>
<cflocation url="/Admin/ctmedia_license.cfm" addtoken="false">
</cfif>

<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
SELECT media_license_id, display, description, uri
FROM ctmedia_license
ORDER BY display
</cfquery>

<cfoutput>
<main id="content" aria-labelledby="pageHeading">
<div class="container-fluid">
class="row">
class="col-12">
id="pageHeading" class="h3 mt-3 mb-2">Media Licenses</h1>
class="text-muted small mb-3">Manage the list of media licenses available for attachment to media records. Each license has a display name, description, and URI.</p>

 aria-labelledby="addLicenseHeading">
id="addLicenseHeading" class="h5 mt-3 mb-2 text-success">Add Media License</h2>
class="row border rounded my-2 mx-1 p-2 bg-light">
method="post" action="/Admin/ctmedia_license.cfm">
put type="hidden" name="action" value="insert">
class="form-row mb-2 flex-nowrap align-items-end">
class="col">
class="form-label" for="new_display">Display Name</label>
put id="new_display" class="data-entry-input reqdClr w-100" type="text" name="display" required>
class="col">
class="form-label" for="new_description">Description</label>
id="new_description" class="data-entry-textarea reqdClr w-100" name="description" rows="2" required></textarea>
class="col">
class="form-label" for="new_uri">URI</label>
put id="new_uri" class="data-entry-input reqdClr w-100" type="text" name="uri">
class="col-auto">
put type="submit" value="Insert" class="btn btn-xs btn-secondary mt-4">
>

 aria-labelledby="editLicensesHeading">
id="editLicensesHeading" class="h5 mt-3 mb-2">Edit Media Licenses</h2>
q.recordCount EQ 0>
class="text-muted">No media licenses have been defined yet.</p>
class="row border rounded my-2 mx-1 p-2">
class="d-table w-100">
class="d-table-row bg-light border-bottom">
class="d-table-cell fw-bold small text-muted pb-1 pr-3">Display Name</div>
class="d-table-cell fw-bold small text-muted pb-1 pr-3">Description</div>
class="d-table-cell fw-bold small text-muted pb-1 pr-3">URI</div>
class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
query="q">
variables.fid = "lic" & q.media_license_id>
class="d-table-row" name="#variables.fid#" id="#variables.fid#" method="post" action="/Admin/ctmedia_license.cfm">
put type="hidden" name="action" value="">
put type="hidden" name="media_license_id" value="#q.media_license_id#">
class="d-table-cell py-1 pr-3 align-middle" style="min-width:8rem">
class="sr-only" for="display_#q.media_license_id#">Display Name</label>
put id="display_#q.media_license_id#" class="data-entry-input reqdClr w-100" type="text" name="display" value="#HTMLEditFormat(q.display)#" required>
class="d-table-cell py-1 pr-3 align-middle" style="min-width:12rem">
class="sr-only" for="desc_#q.media_license_id#">Description</label>
id="desc_#q.media_license_id#" class="data-entry-textarea w-100" name="description" rows="2">#HTMLEditFormat(q.description)#</textarea>
class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
class="sr-only" for="uri_#q.media_license_id#">URI</label>
put id="uri_#q.media_license_id#" class="data-entry-input w-100" type="text" name="uri" value="#HTMLEditFormat(q.uri)#">
class="d-table-cell py-1 align-middle text-nowrap">
put type="button"
 btn-xs btn-primary"
click="#variables.fid#.action.value='save';#variables.fid#.submit();">
put type="button"
 btn-xs btn-danger"
click="if(confirm('Delete this license?')){#variables.fid#.action.value='delete';#variables.fid#.submit();}">
>

>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
