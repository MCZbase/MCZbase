<cfset pageTitle = "Search Transactions">
<!--
Specimens.cfm

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

<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT count(collection_object_id) as cnt FROM cataloged_item
</cfquery>

<cfoutput>

<!--- Search form --->
<div id="search-form-div" class="search-form-div pb-4 px-3">
	<div class="container-fluid">
		<div class="row">
			<div class="col-md-11 col-sm-12 col-lg-11">
				<h1 class="h3 smallcaps mt-4 pl-1">Search Specimen Records <span class="mt-2 font-italic pb-4 color-green fs-15 mx-0">(access to #getCount.cnt# records)</span></h1>
				<div class="tab-card-main mt-1 tab-card">

					<!--- Keyword Search, tab header div then tab contents div --->
					<div class="card-header tab-card-header pb-0 w-100">
						<ul class="nav nav-tabs card-header-tabs pt-1" id="myTab" role="tablist">
							<li class="nav-item col-sm-12 col-md-2 px-1"> <a class="nav-link active" id="one-tab" data-toggle="tab" href="##one" role="tab" aria-controls="One" aria-selected="true" >Keyword</a> </li>
						</ul>
					</div>
					<div class="tab-content pb-0" id="myTabContent">
						<div class="tab-pane fade show active py-3 mx-sm-3 mb-3" id="one" role="tabpanel" aria-labelledby="one-tab">
							<h2 class="h3 card-title ml-2">Keyword Search</h2>
							<form id="searchForm">
								<div class="col-xs-12 col-sm-12 col-md-12 col-lg-8 col-xs-offset-2">
									<div class="input-group">
										<input id="searchText" type="text" class="has-clear form-control w-50 form-control-borderless rounded" name="searchText" placeholder="Search term">
										<span class="input-group-btn">
											<button class="btn button px-3 border-0" id="keySearch" type="submit">
												Search <i class="fa fa-search text-body"></i>
											</button>
										</span>
									</div>
								</div>
							</form>
						</div>
					</div>

					<!--- Additional tabs with tab header then tab contents go here --->

				</div>
			</div>
		</div>
	</div>
</div>

<!--- Results table as a jqxGrid. --->
<div class="container-fluid">
	<div class="row">
		<div class="text-left col-md-12">
			<main role="main">
				<div id="jqxWidget">
					<div class="pl-2 mb-5">
						<div class="row mt-4">
								<!--Grid Related code is below along with search handler for keyword search-->
								<div id="searchResultsGrid" class="jqxGrid"></div>
							<div class="mt-005" id="enableselection"></div>
						</div>
					</div>
				</div>
			</main>
		</div>
	</div>
</div>

<script>

$(document).ready(function () {
	$(".jqxdatetimeinput").jqxDateTimeInput({ width: '250px', height: '25px', theme: 'summer' });
});

///   JQXGRID -- for Keyword Search /////
$(document).ready(function() {

	$('##searchForm').bind('submit', function(evt){
		evt.preventDefault();

		var searchParam = $('##searchText').val();
		$('##searchText').jqxGrid('showloadelement');
		$("##searchResultsGrid").jqxGrid('clearfilters');
		var search =
		{
			datatype: "json",
			datafields:
			[
				{ name: 'collection_object_id', type: 'string' },
				{ name: 'collection', type: 'string' },
				{ name: 'cat_num', type: 'string' },
				{ name: 'scientific_name', type: 'string' },
				{ name: 'spec_locality', type: 'string' },
				{ name: 'higher_geog', type: 'string' },
				{ name: 'collectors', type: 'string' }
			],
			updaterow: function (rowid, rowdata, commit) {
				commit(true);
			},
			root: 'transRecord',
			id: 'collection_object_id',
			url: '/specimens/component/records_search.cfc?method=getDataTable&searchText=' + searchParam,
			async: false
		};

		var dataAdapter = new $.jqx.dataAdapter(search);

		var editrow = -1;
		// grid rendering starts below

		$("##searchResultsGrid").jqxGrid({
			width: '100%',
			autoheight: 'true',
			source: dataAdapter,
			filterable: true,
			sortable: true,
			pageable: true,
			autoheight: true,
			editable: true,
			pagesize: '10',
			showaggregates: true,
			columnsresize: true,
			autoshowfiltericon: false,
			autoshowcolumnsmenubutton: false,
			selectionmode: 'multiplecellsextended',
			columnsreorder: true,
			groupable: true,
			selectionmode: 'checkbox',
			altrows: true,
			showtoolbar: true,
			
			// This part needs to be dynamic.
			columns: [
				{text: 'Collection Object ID', datafield: 'collection_object_id', width: 190},
				{text: 'Collection', datafield: 'collection', width: 150},
				{text: 'Catalog Number', datafield: 'cat_num', width: 130},
				{text: 'Scientific Name', datafield: 'scientific_name', width: 250},
				{text: 'Specific Locality', datafield: 'spec_locality', width: 250},
				{text: 'Higher Geography', datafield: 'higher_geog', width: 280},
				{text: 'Collectors', datafield: 'collectors', width: 180},
			]
		});

	});
});
</script>

</cfoutput>
<cfinclude template="/includes/_footer.cfm">
