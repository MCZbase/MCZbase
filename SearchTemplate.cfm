<cfset pageTitle = "Search Specimens">
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
<cfoutput>
<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT count(collection_object_id) as cnt FROM cataloged_item
</cfquery>
	<div id="search-form-div" class="search-form-div pb-4 px-3">
		<div class="container-fluid">
			<div class="row">
				<div class="col-md-11 col-sm-12 col-lg-11">
					<h1 class="h3 smallcaps mt-4 pl-1">Search Specimen Records <span class="mt-2 font-italic pb-4 color-green fs-15 mx-0">(access to #getCount.cnt# records)</span> 
					</h1>
					<div class="tab-card-main mt-1 tab-card">
						<div class="card-header tab-card-header pb-0 w-100">
							<ul class="nav nav-tabs card-header-tabs pt-1" id="myTab" role="tablist">
								<li class="nav-item col-sm-12 col-md-2 px-1"> <a class="nav-link active" id="one-tab" data-toggle="tab" href="##one" role="tab" aria-controls="One" aria-selected="true" >Keyword</a> </li>
							</ul>
						</div>
						<div class="tab-content pb-0" id="myTabContent">
							<!---Keyword Search--->
							<div class="tab-pane fade show active py-3 mx-sm-3 mb-3" id="one" role="tabpanel" aria-labelledby="one-tab">
								<h2 class="h3 card-title ml-2">Keyword Search</h2>
								<form id="searchForm">
									<div class="col-xs-12 col-sm-12 col-md-12 col-lg-8 col-xs-offset-2">
										<div class="input-group">
											<div class="input-group-btn">
												<select class="dropdown-menu col-multi-select" id="col-multi-select" role="menu" multiple="multiple">
													<cfloop query="collSearch">
														<option value="#collSearch.collection#"> #collSearch.collection# (#collSearch.guid_prefix#)</option>
													</cfloop>
												</select>
											</div>
											<script>
											//// script for multiselect dropdown for collections
											//// on keyword
											$("##col-multi-select").multiselect({
												header: !0,
												height: 175,
												minWidth: "200px",
												classes: "float-sm-left float-md-right mx-0",
												checkAllText: "Check all",
												uncheckAllText: "Uncheck all",
												noneSelectedText: "All Collections ",
												selectedText: "## selected",
												fontFamily: "Arial",
												selectedList: 0,
												show: null,
												hide: null,
												autoOpen: !1,
												multiple: !0,
												position: {}
											});
											</script>
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
					</div>
				</div>
			</div>
		</div>
	</div>
	<!--Grid Related code below along with search handler for keyword search-->
	<div class="container-fluid">
		<div class="row">
			<div class="text-left col-md-12">
				<main role="main">
					<div id="jqxWidget">
						<div class="pl-2 mb-5" style="padding-right: 1px;">
		
							<div class="row mt-4">
	
								<div id="jqxgrid" class="jqxGrid"></div>
								<div class="mt-005" id="enableselection"></div>
								<div style="margin-top: 30px;">
									<div id="cellbegineditevent"></div>
									<div style="margin-top: 10px;" id="cellendeditevent"></div>
								</div>
								<div id="popupWindow" style="display:none;">
									<div style="padding:.25em;">Edit</div>
									<div style="overflow: hidden;">
										<table width="100%" style="padding: 5px;border: none;">
											<tr>
												<td align="right" class="fs-13" style="width:130px;">Image:</td>
												<td colspan="4" align="left" class="py-2 px-1">
													<input id="imageurl" class="fs-13 mx-1 px-1 border-0"  style="width: 99%;" />
												</td>
											</tr>
											<tr>
												<td align="right" class="fs-13" style="width:130px;">Collection:</td>
												<td align="left" class="py-2 px-1"><input id="collection" class="mx-1 px-1 border-0" style="width: 98%;" />
												</td>
												<td align="right" class="fs-13" style="width:130px;">Catalog Number:</td>
												<td align="left" class="py-2 px-1">
													<input id="cat_num" class="mx-1 px-1 border-0" style="width: 98%;" />
												</td>
											</tr>
											<tr>
												<td align="right" class="fs-13" style="width:130px;">Began Date:</td>
												<td align="left" class="py-2 px-1">
													<input id="began_date" class="mx-1"  style="width: 99%;" />
												</td>
													<td align="right" class="fs-13" style="width:130px;">Ended Date:</td>
												<td align="left" class="py-2 px-1">
													<input id="ended_date" class="mx-1"  style="width: 99%;" />
												</td>
											</tr>
											<tr>
												<td align="right" class="fs-13" style="width:130px;">Scientific Name:</td>
												<td colspan="4" align="left" class="py-2 px-1">
													<input id="scientific_name" class="mx-1 px-1 border-0"  style="width: 99%;" />
												</td>
											</tr>
											<tr>
												<td align="right" class="fs-13" style="width:130px;">Higher Geography:</td>
												<td colspan="4" align="left" class="py-2 px-1">
													<input id="higher_geog" class="mx-1 px-1 border-0"  style="width: 99%;" />
												</td>
											</tr>
											<tr>
												<td align="right" class="fs-13" style="width:130px;">Specific Locality:</td>
												<td colspan="4" align="left" class="py-2 px-1">
													<input id="spec_locality" class="mx-1 px-1 border-0"  style="width: 99%;" />
												</td>
											</tr>
												<tr>
												<td align="right" class="fs-13" style="width:130px;">Collectors:</td>
												<td align="left" class="py-2 px-1">
													<input id="collectors" class="mx-1 border-0"  style="width: 99%;" />
												</td>
													<td align="right" class="fs-13" style="width:130px;">Verbatim Date:</td>
												<td align="left" class="py-2 px-1">
													<input id="verbatim_date" class="mx-1 border-0"  style="width: 99%;" />
												</td>
											</tr>
											<tr>
												<td align="right" class="fs-13" style="width:130px;">Disposition: </td>
												<td align="left" class="py-2 px-1">
													<input id="coll_obj_disposition" class="mx-1 border-0" style="width: 99%;"/>
												</td>
												<td align="right" class="fs-13" style="width:130px;">Other Cat Nums:</td>
												<td align="left" class="py-2 px-1"><input id="othercatalognumbers" class="mx-1 border-0" style="width: 99%;"/>
												</td>
											</tr>
											<tr>
												<td align="right" style="width:130px;"></td>
												<td colspan="3" class="pt-2 pr-2 pb-2" align="right">
													<input class="mr-1" type="button" id="Save" value="Save" />
													<input id="Cancel" type="button" value="Cancel" />
												</td>
											</tr>
										</table>
									</div>
								</div>
							</div>
						</div>
					</div>
				</main>
			</div>
		</div>
	</div>




<script>
///   JQXGRID -- for Keyword Search /////
$(document).ready(function() {

	$('##searchForm').bind('submit', function(evt){
	var searchParam = $('##searchText').val();
	var element = document.getElementById("showRightPush");
	element.classList.remove("hiddenclass");
	var element = document.getElementById("showLeftPush");
	element.classList.remove("hiddenclass");
	$('##searchText').jqxGrid('showloadelement');
	$("##jqxgrid").jqxGrid('clearfilters');

		var datafieldlist = [ ];//add synchronous call to cf component

	var search =
		{
			datatype: "json",
			datafields: datafieldlist,
			updaterow: function (rowid, rowdata, commit) {
			// synchronize with the server - send update command
			// call commit with parameter true if the synchronization with the server is successful
			// and with parameter false if the synchronization failder.
			commit(true);
			},
			root: 'specimenRecord',
			id: 'collection_object_id',
			url: '/specimens/component/records_search.cfc?method=getDataTable&searchText=' + searchParam,
			async: false
			};

		var imagerenderer = function (row, datafield, value) {
			return '<img style="margin-left: 5px;" height="60" width="50" src="' + value + '"/></a>';
		}

		var dataAdapter = new $.jqx.dataAdapter(search);

		evt.preventDefault();


		$(document).ready(function () {
			$(".jqxdatetimeinput").jqxDateTimeInput({ width: '250px', height: '25px', theme: 'summer' });
		});

		var editrow = -1;
		// grid rendering starts below

		$("##jqxgrid").jqxGrid({
			width: '100%',
			autoheight: 'true',
			source: dataAdapter,
			filterable: true,
			//showfilterrow: true,
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
			rendertoolbar: function (toolbar) {
				var me = this;
				var container = $("<div style='margin: .25em 1em .25em .5em;'></div>");
				toolbar.append(container);
				container.append('<h2 class="h3 float-left mt-0 pt-1 mr-4">Results</h2>');
				container.append('<input id="deleterowbutton" class="btn btn-sm ml-2 fs-13 py-1 px-2" type="button" value="Delete Selected Row(s)"/>');
				container.append('<input id="csvExport" class="btn btn-sm ml-3 fs-13 py-1 px-2" type="button" value="Download Full Record(s)"/>');
				container.append('<input id="csvExportDisplayed" class="btn btn-sm ml-3 fs-13 py-1 px-2" type="button" value="Download Displayed Columns"/>');
				container.append('<input id="clearfilter1" class="btn btn-sm ml-3 fs-13 py-1 px-2" type="button" value="Clear Filters"/>');

			//$("##csvExport").jqxButton();
			$("##csvExportDisplayed").jqxButton();
			//delete row.
			$("##deleterowbutton").jqxButton();

			$("##deleterowbutton").click(function () {
				var rowIndexes = $('##jqxgrid').jqxGrid('getselectedrowindexes');
				var rowIds = new Array();
				for (var i = 0; i < rowIndexes.length; i++) {
					var currentId = $('##jqxgrid').jqxGrid('getrowid', rowIndexes[i]);
					rowIds.push(currentId);
				};
				$('##jqxgrid').jqxGrid('deleterow', rowIds);
				$('##jqxgrid').jqxGrid('clearselection');
			});
			},
			// This part needs to be dynamic.
			columns: [
			{ text: 'Edit',
				datafield: 'Edit',
				columntype: 'button',
				cellsrenderer: function () {
				return "Edit";
				},

				buttonclick: function (row) {
					editrow = row;

					var offset = $("##jqxgrid").offset();
					$("##popupWindow").jqxWindow({ position: { x: ($(window).width() - $("##popupWindow").jqxWindow('width')) / 2 + $(window).scrollLeft(), y: ($(window).height() - $("##popupWindow").jqxWindow('height')) / 2 + $(window).scrollTop() } });
					//var rowID = $('##jqxgrid').jqxGrid('getrowid', editrow);
							 // get the clicked row's data and initialize the input fields.
							 var dataRecord = $("##jqxgrid").jqxGrid('getrowdata', editrow);
							 $("##imageurl").val(dataRecord.imageurl);
							 $("##collection").val(dataRecord.collection);
							 $("##cat_num").val(dataRecord.cat_num);
							 $("##began_date").val(dataRecord.began_date);
							 $("##ended_date").val(dataRecord.ended_date);
							 $("##scientific_name").val(dataRecord.scientific_name);
							 $("##spec_locality").val(dataRecord.spec_locality);
							 $("##locality_id").val(dataRecord.locality_id);
							 $("##higher_geog").val(dataRecord.higher_geog);
							 $("##collectors").val(dataRecord.collectors);
							 $("##verbatim_date").val(dataRecord.verbatim_date);
							 $("##coll_obj_disposition").val(dataRecord.coll_obj_disposition);
							 $("##othercatalognumbers").val(dataRecord.othercatalognumbers);
							// show the popup window.
							 $("##popupWindow").jqxWindow('show');
						 }
					},
					{text: 'Image URLs', datafield: 'imageurl', width: 50, cellsrenderer: imagerenderer},

					{text: 'Link', datafield: 'collection_object_id', width: 100,
						createwidget: function  (row, column, value, htmlElement) {
							var datarecord = value;
							var linkurl = '/specimens/SpecimenDetail.cfm?collection_object_id=' + value;
							var link = '<div class="justify-content-center p-1 pl-2 mt-1"><a href="' + linkurl + '">';
							var button = $(link + "<span>View Record</span></a></div>");
						$(htmlElement).append(button);
						},
						initwidget: function (row, column, value, htmlElement) {  }
					},
					{text: 'Collection', datafield: 'collection', width: 150},
					{text: 'Catalog Number', datafield: 'cat_num', width: 130},
					{text: 'Began Date', datafield: 'began_date', width: 180, cellsformat: 'yyyy-mm-dd', filtertype: 'date'},
					{text: 'Ended Date', datafield: 'ended_date',filtertype: 'date', cellsformat: 'yyyy-mm-dd',width: 180},
					{text: 'Scientific Name', datafield: 'scientific_name', width: 250},
					{text: 'Specific Locality', datafield: 'spec_locality', width: 250},
					{text: 'Locality by ID', datafield: 'locality_id', width: 100},
					{text: 'Higher Geography', datafield: 'higher_geog', width: 280},
					{text: 'Collectors', datafield: 'collectors', width: 180},
					{text: 'Verbatim Date', datafield: 'verbatim_date', width: 190},
					{text: 'Disposition', datafield: 'coll_obj_disposition', width: 120},
					{text: 'Other IDs', datafield: 'othercatalognumbers', width: 280}
			]
		});
			// initialize the popup window and buttons.
			$("##popupWindow").jqxWindow({
				width: 850, resizable: false, isModal: true, autoOpen: false, cancelButton: $("##Cancel"), modalOpacity: 0.5
			});

			$("##popupWindow").on('open', function () {
				$("##imageurl").jqxInput('selectAll');
			});

			$("##Cancel").jqxButton({ theme: theme });
			$("##Save").jqxButton({ theme: theme });

			// update the edited row when the user clicks the 'Save' button.
			$("##Save").click(function () {
				if (editrow >= 0) {
					var row = {
						imageurl: $("##imageurl").val(),
						collection: $("##collection").val(),
						began_date: $("##began_date").val(),
						ended_date: $("##ended_date").val(),
						scientific_name: $("##scientific_name").val(),
						spec_locality: $("##spec_locality").val(),
						locality_id: $("##locality_id").val(),
						higher_geog: $("##higher_geog").val(),
						collectors: $("##collectors").val(),
						verbatim_date: $("##verbatim_date").val(),
						coll_obj_disposition: $("##coll_obj_disposition").val(),
						othercatalognumbers: $("##othercatalognumbers").val()
				};
				var rowID = $('##jqxgrid').jqxGrid('getrowid', editrow);
				$('##jqxgrid').jqxGrid('updaterow', rowID, row);
				$("##popupWindow").jqxWindow('hide');
			}
		});
		// You can drag and drop the columns into a new order.  The event log reminds you what you just did --but it only shows the last move.
		$("##jqxgrid").on('columnreordered', function (event) {
			var column = event.args.columntext;
			var newindex = event.args.newindex
			var oldindex = event.args.oldindex;
			$("##eventlog").text("Column: " + column + ", " + "New Index: " + newindex + ", Old Index: " + oldindex);
		});
		//button to download records and delete selected rows
		$("##csvExport").jqxButton();
			$("##csvExport").click(function () {
			$("##jqxgrid").jqxGrid('exportdata', 'csv', 'jqxGrid');
		});
	
		//This code starts the filters on the refine results tray (right of page)

				$("##clearfilter1").jqxButton({theme: 'Classic'});

				$("##clearfilter1").click(function (datafield) {
				//we added datafield to pass to the function
				$("##jqxgrid").jqxGrid('clearfilters');
				$("##filterbox").jqxListBox('uncheckAll');
				//we added this line to the code
				});

		$("##applyfilter").jqxButton({theme: 'Classic'});
	$("##clearfilter").jqxButton({theme: 'Classic'});
	$("##filterbox").jqxListBox({ checkboxes: true, width: 257, height: 240 });
	$("##columnchooser").jqxDropDownList({ autoDropDownHeight: true, selectedIndex: 0, width: 257, height: 25,
		source: [
			{label: 'Collectors', value: 'collectors'},
			{label: 'Collection Object ID', value: 'collection_object_id'},
			{label: 'Collection', value: 'collection'},
			{label: 'Cat Num', value: 'cat_num'},
			{label: 'Scientific Name', value: 'scientific_name'},
			{label: 'Locality', value: 'spec_locality'},
			{label: 'Higher Geography', value: 'higher_geog'},
			{label: 'Verbatim Date',value: 'verbatim_date'},
			{label: 'Disposition', value: 'coll_obj_disposition'},
			{label: 'Other IDs', value: 'othercatalognumbers'}
			]
		});
	var updateFilterBox = function (datafield) {
	var filterBoxAdapter = new $.jqx.dataAdapter(search,
	{
		uniqueDataFields: [datafield],
		autoBind: true
	});
	var uniqueRecords = filterBoxAdapter.records;
	uniqueRecords.splice(0, 0, '(All or None)');
	$("##filterbox").jqxListBox({ source: uniqueRecords, displayMember: datafield });
	$("##filterbox").jqxListBox('checkAll');
	}
	updateFilterBox('collectors');
	var handleCheckChange = true;
	$("##filterbox").on('checkChange', function (event) {
		if (!handleCheckChange)
			return;
		if (event.args.label != '(All or None)') {
			handleCheckChange = false;
			$("##filterbox").jqxListBox('checkIndex', 0);
			var checkedItems = $("##filterbox").jqxListBox('getCheckedItems');
			var items = $("##filterbox").jqxListBox('getItems');
			if (checkedItems.length == 1) {
				$("##filterbox").jqxListBox('uncheckIndex', 0);
			}
			else if (items.length != checkedItems.length) {
				$("##filterbox").jqxListBox('indeterminateIndex', 0);
			}
			handleCheckChange = true;
		}
		else {
			handleCheckChange = false;
			if (event.args.checked) {
				$("##filterbox").jqxListBox('checkAll');
			}
			else {
				$("##filterbox").jqxListBox('uncheckAll');
			}
			handleCheckChange = true;
		}
	});
		// handle columns selection.
	$("##columnchooser").on('select', function (event) {
	//	console.log(event);
		updateFilterBox(event.args.item.value);
	});
			// builds and applies the filter.
			var applyFilter = function (datafield) {
			//	console.log(datafield);
			$("##jqxgrid").jqxGrid('clearfilters');
			var filtertype = 'stringfilter';
			if (datafield == 'collection_object_id' || datafield == 'locality_id') filtertype = 'numericfilter';

			var filtergroup = new $.jqx.filter();
			var checkedItems = $("##filterbox").jqxListBox('getCheckedItems');
			if (checkedItems.length == 0) {
				var filter_or_operator = 1;
				var filtervalue = "Empty";
				var filtercondition = 'equal';
				var filter = filtergroup.createfilter(filtertype, filtervalue, filtercondition);
				filtergroup.addfilter(filter_or_operator, filter);
			}
			else {
				for (var i = 0; i < checkedItems.length; i++) {
					var filter_or_operator = 1;
					var filtervalue = checkedItems[i].label;
					var filtercondition = 'equal';
					var filter = filtergroup.createfilter(filtertype, filtervalue, filtercondition);
					filtergroup.addfilter(filter_or_operator, filter);
				}
			}
			$("##jqxgrid").jqxGrid('addfilter', datafield, filtergroup);
			$("##jqxgrid").jqxGrid('applyfilters');
			}
			$("##clearfilter").click(function (datafield) {
			//we added datafield to pass to the function
			$("##jqxgrid").jqxGrid('clearfilters');
			$("##filterbox").jqxListBox('uncheckAll');
			//we added this line to the code
			});
			$("##applyfilter").click(function () {
			var dataField = $("##columnchooser").jqxDropDownList('getSelectedItem').value;
			applyFilter(dataField);
		});
			var listSource = [
				{ label: 'Image URL', value: 'imageurl' },
				{ label: 'Collection Object ID', value: 'collection_object_id' },
				{ label: 'Collection', value: 'collection' },
				{ label: 'Cat Num', value: 'cat_num' },
				{ label: 'Scientific Name', value: 'scientific_name'},
				{ label: 'Locality', value: 'spec_locality' },
				{ label: 'Locality ID', value: 'locality_id' },
				{ label: 'Higher Geography', value: 'higher_geog' },
				{ label: 'Collectors', value: 'collectors' },
				{ label: 'Verbatim Date',value: 'verbatim_date'},
				{ label: 'Disposition', value: 'coll_obj_disposition' },
				{ label: 'Other IDs', value: 'originalcatalognumbers'}
			];
		// jqxlistbox2 is the show/hide column filter
			$("##jqxlistbox2").jqxListBox({ source: listSource, width: 198, height: 300, theme: theme, checkboxes: true });
			$("##jqxlistbox2").jqxListBox('checkAll');
			$("##jqxlistbox2").on('checkChange', function (event) {
			$("##jqxgrid").jqxGrid('beginupdate');
			if (event.args.checked) {
				$("##jqxgrid").jqxGrid('showcolumn', event.args.value);
			}
				else {
				$("##jqxgrid").jqxGrid('hidecolumn', event.args.value);
			}
				$("##jqxgrid").jqxGrid('endupdate');
			});
		$("##clearselectionbutton").jqxButton({ theme: theme });
		$("##enableselection").jqxDropDownList({
			autoDropDownHeight: true, dropDownWidth: 230, width: 120, height: 25, selectedIndex: 1, source: ['none', 'single row', 'multiple rows',
			'multiple rows extended', 'multiple rows advanced']
		});
		$("##enablehover").jqxCheckBox({  checked: true });
		// clears the selection.
		$("##clearselectionbutton").click(function () {
			$("##jqxgrid").jqxGrid('clearselection');
		});
		// enable or disable the selection.  Used for Delete selected row button.
		$("##enableselection").on('select', function (event) {
			var index = event.args.index;
			console.log(event.args.index);
			$("##selectrowbutton").jqxButton({ disabled: false });
			switch (index) {
				case 0:
					$("##jqxgrid").jqxGrid('selectionmode', 'none');
					$("##selectrowbutton").jqxButton({ disabled: true });
					break;
				case 1:
					$("##jqxgrid").jqxGrid('selectionmode', 'singlerow');
					break;
				case 2:
					$("##jqxgrid").jqxGrid('selectionmode', 'multiplerows');
					break;
				case 3:
					$("##jqxgrid").jqxGrid('selectionmode', 'multiplerowsextended');
					break;
				case 4:
					$("##jqxgrid").jqxGrid('selectionmode', 'multiplerowsadvanced');
					break;
			}
		});
		// enable or disable the hover state.
		$("##enablehover").on('change', function (event) {
			$("##jqxgrid").jqxGrid('enablehover', event.args.checked);
		});
		// display selected row index.
		$("##jqxgrid").on('rowselect', function (event) {
			$("##selectrowindex").text(event.args.rowindex);
		});
		// display unselected row index.
		$("##jqxgrid").on('rowunselect', function (event) {
			$("##unselectrowindex").text(event.args.rowindex);
		});
	});



});
</script>

<script>
	//this is the search builder main dropdown for all the columns found in flat
$(document).ready(function(){
	$(".addCF").click(function(){
		$("##customFields").append('<tr class="rounded ml-0"><td class="mx-1 pr-1 border-0"><select title="Join Operator" name="JoinOperator" id="joinOperator" class="custom-select border mx-0 d-flex"><option value="">Join with...</option><option value="and">and</option><option value="or">or</option><option value="not">not</option></select></td><td class="mx-1 pr-1 border-0"><select title="Select Type" name="SelectType" class="custom-select border d-flex"><option>Select Type...</option><optgroup label="Identifiers"><option>MCZ Catalog (Collection)</option><option>Catalog Number</option><option>Number plus other identifiers?</option><option>Other Identifier Type</option><option>Accession</option><option>Accession Agency</option></optgroup><optgroup label="Taxonomy"><option>Any Taxonomic Element</option><option>Scientific Name</option><option>Genus</option><option>Subgenus</option><option>Species</option><option>Subspecies</option><option>Author Text</option><option>Infraspecific Author Text</option><option>Class</option><option>Superclass</option><option>Subclass</option><option>Order</option><option>Superorder</option><option>Suborder</option><option>Infraorder</option><option>Family</option><option>Superfamily</option><option>Subfamily</option><option>Tribe</option><option>Authority</option><option>Taxon Status</option><option>Nomenclatural Code</option><option>Common Name</option></optgroup><optgroup label="Locality"><option>Any Geographic Element</option><option>Continent/Ocean</option><option>Ocean Region</option><option>Ocean Subregion</option><option>Country</option><option>State/Province</option><option>County</option><option>Island Group</option><option>Island</option><option>Land Feature</option><option>Water Feature</option><option>Specific Locality</option><option>Elevation</option><option>Depth</option><option>Verification Status</option><option>Maximum Uncertainty</option><option>Quad</option><option>Geology Attribute</option><option>Geog Auth Rec ID</option><option>Locality Remarks</option></optgroup><optgroup label="Collecting Event"><option>Verbatim Locality</option><option>Began Date</option><option>Ended Date</option><option>Verbatim Date</option><option>Verbatim Coordinates</option><option>Collecting Method</option><option>Collecting Event Remarks</option><option>Verbatim Coordinate System</option><option>Habitat</option><option>Collecting Source</option><option>Verbatim SRS (Datum)</option><option>Collecting Event ID</option></optgroup><optgroup label="Media"><option>Any Media Type</option><option>Image</option><option>Audible</option><option>Video</option><option>Spectrometer Data</option><option>Media URI</option><option>Any Media Relationship</option><option>Created By Agent</option><option>Document for Permit</option><option>Document for Loan</option><option>Shows Accession</option><option>Shows Borrows</option><option>Shows Cataloged Items</option><option>Shows Collecting Event</option><option>Shows Deaccession</option><option>Shows Locality</option><option>Shows Permit</option><option>Shows Project</option><option>Shows Publication</option><option>Any Media Label</option><option>Aspect</option><option>Credit</option><option>Description</option><option>Height</option><option>Internal Remarks</option><option>Light Source</option><option>Made Date</option><option>md5hash</option><option>Original Filename</option><option>Owner</option><option>Remarks</option><option>Spectrometer</option><option>Spectrometer Reading Location</option><option>Subject</option><option>Width</option></optgroup><optgroup label="Publications"><option>Any Publication</option><option>Title</option><option>Participant/Agent</option><option>Year</option><option>Publication Type</option><option>Journal Name</option><option>Cites Collection</option><option>Cites Specimens</option><option>Accepted Scientific Name</option><option>Peer Reviewed Only?</option></optgroup></td><td class="mx-1 pr-1 border-0"><select title="Comparator" name="comparator" id="comparator" class="custom-select d-flex border"><option value="">Compare with...</option><option value="like">contains</option><option value="eq">is</option></select></td>><td class="mx-1 pr-1 border-0"><input type="text" class="form-control d-flex enter-search mx-0" name="customFieldValue[]" id="srchTxt" placeholder="Enter Value"/></td><td class="border-0 mx-1 pr-1 py-2"><a href="javascript:void(0);" class="remCF px-2">Remove</a></td></tr>');
		});
	$("##customFields").on('click','.remCF',function(){
		$(this).parent().parent().remove();
		});
	});
</script>
<script>
//// script for DatePicker
$(function() {
	$("##began_date").datepicker({
		dateFormat: "yy-mm-dd",
		changeMonth: true,
		changeYear: true
	}).val()
	$("##ended_date").datepicker({
		dateFormat: "yy-mm-dd",
		changeMonth: true,
		changeYear: true
	}).val()
});

function saveSearch(returnURL){
	var sName=prompt("Name this search", "my search");
	if (sName!==null){
		var sn=encodeURIComponent(sName);
		var ru=encodeURI(returnURL);
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "saveSearch",
				returnURL : ru,
				srchName : sn,
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				if(r!='success'){
					alert(r);
				}
			}
		);
	}
}

</script>


</cfoutput>
<cfinclude template="/includes/_footer.cfm">
