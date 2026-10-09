<!---
Admin/AdminPanel.cfm

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
<!--- Status and activity widgets for global_admin users.  Each widget is a card whose body is loaded
	by loadAdminWidget (Admin/js/admin.js) from a get...Html method of Admin/component/functions.cfc;
	add a widget by adding a card and a method. --->
<cfset pageTitle = "Admin Panel">
<cfinclude template="/shared/_header.cfm">
<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
	<cflocation url="/errors/forbidden.cfm" addtoken="false">
</cfif>
<main class="container-fluid py-3" id="content">
	<h1 class="h2">Admin Panel</h1>
	<section class="row mb-4">
		<div class="col-12 col-xl-6 mb-3">
			<div class="card h-100">
				<div class="card-header d-flex align-items-center">
					<h2 class="h4 mb-0 mr-auto">Code Table Changes</h2>
					<label for="codeTableDays" class="sr-only">Period</label>
					<select id="codeTableDays" class="data-entry-select w-auto mr-2" onchange="loadAdminWidget('codeTableChangesWidget', 'getCodeTableChangesHtml', { days: this.value });">
						<option value="1">Last day</option>
						<option value="7" selected>Last 7 days</option>
						<option value="30">Last 30 days</option>
					</select>
					<button type="button" class="btn btn-xs btn-secondary" onclick="loadAdminWidget('codeTableChangesWidget', 'getCodeTableChangesHtml', { days: $('#codeTableDays').val() });">Refresh</button>
				</div>
				<div class="card-body" id="codeTableChangesWidget">
					<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>
				</div>
			</div>
		</div>
		<div class="col-12 col-xl-6 mb-3">
			<div class="card h-100">
				<div class="card-header d-flex align-items-center">
					<h2 class="h4 mb-0 mr-auto">Active Users</h2>
					<button type="button" class="btn btn-xs btn-secondary" onclick="loadAdminWidget('activeUsersWidget', 'getActiveUsersHtml');">Refresh</button>
				</div>
				<div class="card-body" id="activeUsersWidget">
					<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>
				</div>
			</div>
		</div>
	</section>
</main>
<script>
	$(document).ready(function() {
		loadAdminWidget('codeTableChangesWidget', 'getCodeTableChangesHtml', { days: 7 });
		loadAdminWidget('activeUsersWidget', 'getActiveUsersHtml');
	});
</script>
<cfinclude template="/shared/_footer.cfm">
