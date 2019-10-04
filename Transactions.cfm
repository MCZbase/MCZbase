<cfset pageTitle = "Search Transactions">
<!--
Transactions.cfm

Copyright 2019 President and Fellows of Harvard College

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
<cfinclude template = "/includes/_header.cfm">
<cfoutput>
<form id="searchForm">
	<div class="col-xs-12 col-sm-12 col-md-12 col-lg-8 col-xs-offset-2">
		<div class="input-group">
			<input id="transNumber" type="text" class="has-clear form-control w-50 form-control-borderless rounded" name="transNumber" placeholder="Transaction Number">
			<span class="input-group-btn">
				<button class="btn button px-3 border-0" id="keySearch" type="submit">Search<i class="fa fa-search text-body"></i></button>
			</span>
		</div>
	</div>
</form>
<div class="container-fluid">
	<div class="text-left col-md-12">
		<div id="jqxgrid" class="jqxGrid"></div>
	</div>
</div>

<script type="text/javascript">
$(document).ready(function() {
	$('##searchForm').bind('submit', function(evt){

	});
});
</script>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
