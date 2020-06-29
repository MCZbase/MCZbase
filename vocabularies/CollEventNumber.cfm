<!---
CollEventNumber.cfm

For managing collecting event number series.

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

--->
<cfif not isdefined("action")>
	<cfset action="findAll">
</cfif>
<cfswitch expression="#action#">
	<cfcase value="findAll">
		<cfset pageTitle = "Search Collecting Event Number Series">
	</cfcase>
	<cfcase value="new">
		<cfset pageTitle = "Add New Collecting Event Number Series">
	</cfcase>
	<cfcase value="edit">
		<cfset pageTitle = "Edit a Collecting Event Number Series">
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Collecting Event Number Series">
	</cfdefaultcase>
</cfswitch>
<!---------------------------------------------------------------------------------->
<cfinclude template = "/shared/_header.cfm">
<!---------------------------------------------------------------------------------->
<!---------------------------------------------------------------------------------->
<cfswitch expression="#action#">
	<cfcase value="findAll">
		<!--- Search Form --->
		<cfoutput>
			<div class="container">
				<div class="row">
					<div class="col-12">
						<div role="region" aria-labelledby="formheading">
							<h2 id="formheading">Find Collecting Event Number Series</h2>
							<form name="searchForm"> 
								<input type="hidden" name="method" value="getCollEventNumberSeries" class="keeponclear">
								<div class="form-row mb-2">
									<div class="col-md-12">
										<label for="number_series" id="number_series_label">Name for the Collector Number Series</label>
										<input type="text" id="number_series" name="number_series" class="reqdClr form-control-sm" required value="" aria-labelledby="number_series_label" >					
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-md-12">
										<label for="number" id="number_label">A number in the Series</label>
										<input type="text" id="number" name="number" class="reqdClr form-control-sm" required value="" aria-labelledby="number_label" >					
									</div>
								</div>
								<div class="form-row my-2 mx-0">
									<div class="col-12 text-left">
										<button class="btn-xs btn-primary px-2" id="loanSearchButton" type="submit" aria-label="Search loans">Search<span class="fa fa-search pl-1"></span></button>
										<button type="reset" class="btn-xs btn-warning" aria-label="Reset search form to inital values" onclick="setDispositionValues();">Reset</button>
										<button type="button" class="btn-xs btn-warning" aria-label="Start a new loan search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/Transactions.cfm?action=findLoans';" >New Search</button>
									</div>
								</div>
							</form>
						</div>
					</div>
				</div>
			</div>
		</cfoutput>

		<!--- Results table as a jqxGrid. --->
		<div class="container-fluid">
			<div class="row">
				<div class="text-left col-md-12">
					<main role="main">
						<div class="pl-2 mb-5"> 
							
							<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
								<h4>Results: </h4>
								<span class="d-block px-3 p-2" id="resultCount"></span> <span id="resultLink" class="d-block p-2"></span>
								<div id="columnPickDialog">
									<div id="columnPick" class="px-1"></div>
								</div>
								<div id="columnPickDialogButton"></div>
								<div id="resultDownloadButtonContainer"></div>
							</div>
							<div class="row mt-0">
								<!--- Grid Related code is below along with search handlers --->
								<div id="searchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
								<div id="enableselection"></div>
							</div>
						</div>
					</main>
				</div>
			</div>
		</div>
	
		<script>
		/* Setup jqxgrid for Transactions Search */
		$('##searchForm').bind('submit', function(evt){
			evt.preventDefault();
	
			$("##overlay").show();
	
			$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
			$('##resultCount').html('');
			$('##resultLink').html('');
	
			var search =
			{
				datatype: "json",
				datafields:
				[
					{ name: 'number_series', type: 'string' },
					{ name: 'coll_event_num_series_id', type: 'string' },
					{ name: 'pattern', type: 'string' },
					{ name: 'remarks', type: 'string' },
					{ name: 'agentname', type: 'string' },
					{ name: 'collector_agent_id', type: 'string' },
					{ name: 'number_count', type: 'string' },
					{ name: 'id_link', type: 'string' }
				],
				updaterow: function (rowid, rowdata, commit) {
					commit(true);
				},
				root: 'numberSeriesRecord',
				id: 'coll_event_num_series_id',
				url: '/vocabularies/component/search.cfc?' + $('##searchForm').serialize(),
				timeout: 30000,  // units not specified, miliseconds? 
				loadError: function(jqXHR, status, error) { 
					$("##overlay").hide();
	            var message = "";      
					if (error == 'timeout') { 
	               message = ' Server took too long to respond.';
	            } else { 
	               message = jqXHR.responseText;
	            }
	            messageDialog('Error:' + message ,'Error: ' + error);
				},
				async: true
			};
	
			var dataAdapter = new $.jqx.dataAdapter(search);
			var initRowDetails = function (index, parentElement, gridElement, datarecord) {
				// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
				var details = $($(parentElement).children()[0]);
				details.html("<div id='rowDetailsTarget" + index + "'></div>");
	
				createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index);
				// Workaround, expansion sits below row in zindex.
				var maxZIndex = getMaxZIndex();
				$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
			}
	
			$("##searchResultsGrid").jqxGrid({
				width: '100%',
				autoheight: 'true',
				source: dataAdapter,
				filterable: true,
				sortable: true,
				pageable: true,
				editable: false,
				pagesize: '50',
				pagesizeoptions: ['50','100'],
				showaggregates: true,
				columnsresize: true,
				autoshowfiltericon: true,
				autoshowcolumnsmenubutton: false,
				autoshowloadelement: false,  // overlay acts as load element for form+results
				columnsreorder: true,
				groupable: true,
				selectionmode: 'none',
				altrows: true,
				showtoolbar: false,
				columns: [
					{text: 'Number Series', datafield: 'number_series', width:100, hideable: true, hidden: false },
					{text: 'Transaction', datafield: 'id_link', width: 100},
					{text: 'Pattern', datafield: 'pattern', width:110, hideable: true, hidden: false },
					{text: 'Collector', datafield: 'agentname', width:110, hideable: true, hidden: false },
					{text: 'AgentID', datafield: 'collector_agent_id', width:110, hideable: true, hidden: true },
					{text: 'Number Count', datafield: 'number_count', width:110, hideable: true, hidden: false },
					{text: 'Remarks', datafield: 'remarks', width:110, hideable: true, hidden: false },
				],
				rowdetails: true,
				rowdetailstemplate: {
					rowdetails: "<div style='margin: 10px;'>Row Details</div>",
					rowdetailsheight:  1 // row details will be placed in popup dialog
				},
				initrowdetails: initRowDetails
			});
			$("##searchResultsGrid").on("bindingcomplete", function(event) {
				// add a link out to this search, serializing the form as http get parameters
				$('##resultLink').html('<a href="/vocabularies/CollEventNumber.cfm?action=findAll&execute=true&' + $('##searchForm').serialize() + '">Link to this search</a>');
				gridLoaded('searchResultsGrid','transaction');
			});
			$('##searchResultsGrid').on('rowexpand', function (event) {
				//  Create a content div, add it to the detail row, and make it into a dialog.
				var args = event.args;
				var rowIndex = args.rowindex;
				var datarecord = args.owner.source.records[rowIndex];
				createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
			});
			$('##searchResultsGrid').on('rowcollapse', function (event) {
				// remove the dialog holding the row details
				var args = event.args;
				var rowIndex = args.rowindex;
				$("##searchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
			});
		});
		/* End Setup jqxgrid for number series Search ******************************/
		</script>

	</cfcase>
	<cfcase value="new">
		<!---  Add a new collecting event number series, link to agent --->
		<cfoutput>
			<div class="container">
				<div class="row">
					<div class="col-12">
						<div role="region" aria-labelledby="formheading">
							<h2 id="formheading">New Collecting Event Number Series</h2>
							<form name="newNumSeries" id="newNumSeries" action="/vocabularies/CollEventNumber.cfm" method="post"> 
								<input type="hidden" id="action" name="action" value="saveNew" >
								<div class="form-row mb-2">
									<div class="col-md-12">
										<label for="number_series" id="number_series_label">Name for the Collector Number Series</label>
										<input type="text" id="number_series" name="number_series" class="reqdClr form-control-sm" required value="" aria-labelledby="number_series_label" >					
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-md-12">
										<label for="pattern" id="pattern_label">Pattern for numbers in this series</label>
										<input type="text" id="pattern" name="pattern" class="form-control-sm" value="" aria-labelledby="pattern_label" >
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-md-12">
										<label for="remarks" id="remarks_label">Remarks</label>
										<input type="text" id="remarks" name="remarks" class="form-control-sm" value="" aria-labelledby="remarks_label" >
									</div>
								</div>
								<div class="form-row mb-5">
									<div class="col-12 col-md-6">
										<span>
											<label for="collector_agent_name">Numbers in this series assigned by Agent</label>
											<span id="collector_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
										</span>
										<input name="collector_agent_name" id="collector_agent_name" class="form-control-sm" value="" aria-label="This is a number series of collector: " >
										<input type="hidden" name="collector_agent_id" id="collector_agent_id" value=""  >
										<script>
											$(document).ready(function() {
												$(makeAgentPicker('collector_agent_name','collector_agent_id'));
											});
										</script>
									</div>
									<div class="col-12 col-md-6 px-2 my-3 px-sm-2 my-4">   								
											<input type="button" 
												value="Create" title="Create" aria-label="Create"
												class="btn btn-xs btn-primary"
												onClick="if (checkFormValidity($('##newNumSeries')[0])) { submit();  } " 
												>
									</div>
								</div>
							</form>
						</div><!--- region --->
					</div><!--- col --->
				</div><!--- row --->
			</div><!--- container --->
		</cfoutput>
	</cfcase>
	<cfcase value="saveNew">
		<cftry>
			<cfif not isdefined("number_series") OR len(trim(#number_series#)) EQ 0 >
				<cfthrow type="Application" message="Error: No value provided for required value number_series">
			</cfif>
			<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insertResult">
				insert into coll_event_num_series (
					number_series
					<cfif isdefined("pattern")>
						,pattern
					</cfif>
					<cfif isdefined("remarks")>
						,remarks
					</cfif>
					<cfif isdefined("collector_agent_id")>
						,collector_agent_id
					</cfif>
				) values (
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#number_series#">
					<cfif isdefined("pattern")>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pattern#">
					</cfif>
					<cfif isdefined("remarks")>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
					</cfif>
					<cfif isdefined("collector_agent_id")>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collector_agent_id#">
					</cfif>
				)
			</cfquery>
			<cfquery name="savePK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="pkResult">
				select coll_event_num_series_id from coll_event_num_series 
				where ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#insertResult.GENERATEDKEY#">
			</cfquery>
			<cflocation url="/vocabularies/CollEventNumber.cfm?action=edit&coll_event_num_series_id=#savePK.coll_event_num_series_id#" addtoken="false">
		<cfcatch>
			<cfthrow type="Application" message="Error Saving new Collecting Event Number Series: #cfcatch.Message# #cfcatch.Detail#">
		</cfcatch>
		</cftry>
	</cfcase>
	<cfcase value="edit">
		<cfif not isDefined("coll_event_num_series_id")>
			<cfthrow type="Application" message="Error: No value provided for coll_event_num_series_id">
		<cfelse>
			<cfquery name="numSeries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select coll_event_num_series_id, number_series, pattern, remarks, collector_agent_id,
					MCZBASE.get_agentnameoftype(collector_agent_id, 'preferred') as agentname
				from coll_event_num_series 
				where coll_event_num_series_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#coll_event_num_series_id#">
			</cfquery>
			<cfoutput query="numSeries">
				<div class="container">
					<div class="row">
						<div class="col-12">
							<div role="region" aria-labelledby="formheading">
								<h2 id="formheading">Edit Collecting Event Number Series</h2>
								<form name="editNumSeries" id="editNumSeries"> 
									<input type="hidden" id="coll_event_num_series_id" name="coll_event_num_series_id" value="#coll_event_num_series_id#" >
									<input type="hidden" id="method" name="method" value="saveNumSeries" >
									<div class="form-row mb-2">
										<div class="col-md-12">
											<label for="number_series" id="number_series_label">Name for the Collector Number Series</label>
											<input type="text" id="number_series" name="number_series" class="reqdClr form-control-sm" required value="#number_series#" aria-labelledby="number_series_label">	
										</div>
									</div>
									<div class="form-row mb-2">
										<div class="col-md-12">
											<label for="pattern" id="pattern_label">Pattern for numbers in this series</label>
											<input type="text" id="pattern" name="pattern" class="form-control-sm" value="#pattern#" aria-labelledby="pattern_label" >
										</div>
									</div>
									<div class="form-row mb-2">
										<div class="col-md-12">
											<label for="remarks" id="remarks_label">Remarks</label>
											<input type="text" id="remarks" name="remarks" class="form-control-sm" value="#remarks#" aria-labelledby="remarks_label" >		
										</div>
									</div>
									<div class="form-row mb-5">
										<div class="col-12 col-md-6"> 
											<span>
												<label for="collector_agent_name" id="collector_agent_name_label">Numbers in this series assigned by Agent</label>
												<span id="collector_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
											</span>
											<input name="collector_agent_name" id="collector_agent_name" class="form-control-sm" value="#agentname#" aria-labelledby="collector_agent_name_label" >
											<input type="hidden" name="collector_agent_id" id="collector_agent_id" value="#collector_agent_id#"  >
											<script>
												function changed(){
													$('##saveResultDiv').html('Unsaved changes.');
												};
												$(document).ready(function() {
													$(makeAgentPicker('collector_agent_name','collector_agent_id'));
													$('##editNumSeries input[type=text]').on("change",changed);
												});
												function saveChanges(){ 
													var agenttext = $('##collector_agent_name').val();
													var agentid = $('##collector_agent_id').val();
													if (agenttext.length == 0 || (agentid.length>0 && agenttext.length>0)) { 
														$('##saveResultDiv').html('Saving....');
														jQuery.ajax({
															url : "/vocabularies/component/functions.cfc",
															type : "post",
															dataType : "json",
															data :  $('##editNumSeries').serialize(),
															success : function (data) {
																$('##saveResultDiv').html('Saved.');
															},
															error: function(jqXHR,textStatus,error){
																$('##saveResultDiv').html('Error.');
																var message = "";
																if (error == 'timeout') {
																	message = ' Server took too long to respond.';
																} else {
																	message = jqXHR.responseText;
																}
																messageDialog('Error saving collecting event number series: '+message, 'Error: '+error);
															}
														});
													} else { 
														messageDialog('Error saving collecting event number series: If an entry is made in the agent field an agent must be selected from the picklist.', 'Error: Agent not selected');
														$('##saveResultDiv').html('Fix error in Agent field.');
													}
												};
											</script>
										</div>
										<div class="col-12 col-md-6"> 
											<div id="saveResultDiv">&nbsp;</div>
											<input type="button" 
												value="Save" title="Save" aria-label="Save"
												class="btn btn-xs btn-primary"
												onClick="if (checkFormValidity($('##editNumSeries')[0])) { saveChanges();  } " 
												>
										</div>
									</div>
								</form>
							</div><!--- region --->
						</div><!--- col --->
					</div><!--- row --->
				</div><!--- container --->
			</cfoutput>
		</cfif>
	</cfcase>
	<cfdefaultcase>
		<cfthrow type="Application" message="Unknown action.">
	</cfdefaultcase>
</cfswitch>
<!---------------------------------------------------------------------->
<cfinclude template = "/shared/_footer.cfm">
