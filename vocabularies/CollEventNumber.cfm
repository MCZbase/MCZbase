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
		<cfquery name="numSeriesList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select number_series, coll_event_num_series_id,
				MCZBASE.get_agentnameoftype(collector_agent_id, 'preferred') as agentname
			from coll_event_num_series
		</cfquery>
		<!--- Search Form --->
		
		<!--- Results table --->

		<!--- TODO: Make search/results form/jqxgrid --->
		<cfoutput>
			<h2>Number Series (#numSeriesList.RecordCount#)</h2>
			<ul>
			<cfloop query="numSeriesList">
				<li><a href="/vocabularies/CollEventNumber.cfm?action=edit&coll_event_num_series=#coll_event_num_series_id#">#number_series#</a>(#agentname#)</li>
			</cfloop>
			</ul>
		</cfoutput>	

	</cfcase>
	<cfcase value="new">
		<!---  Add a new collecting event number series, link to agent --->
		<cfoutput>
			<div class="container-fluid form-div">
				<div class="container">
					<h2>New Collecting Event Number Series</h2>
					<form name="newNumSeries" id="newNumSeries" action="/vocabularies/CollEventNumber.cfm" method="post"> 
						<input type="hidden" id="method" name="method" value="saveNew" >
						<div class="form-row mb-2">
							<div class="col-md-12">
								<label for="number_series">Name for the Collector Number Series</label>
								<input type="text" id="number_series" name="number_series" class="reqdClr form-control-sm" required value="" >					
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-md-12">
								<label for="pattern">Pattern for numbers in this series</label>
								<input type="text" id="pattern" name="pattern" class="form-control-sm" value="" >
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-md-12">
								<label for="remarks">Remarks</label>
								<input type="text" id="remarks" name="remarks" class="form-control-sm" value="" >
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-6 ui-widget">
								<span>
									<label for="collector_agent_name">This is a number series of</label>
									<span id="collector_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
								</span>
								<input name="collector_agent_name" id="collector_agent_name" class="form-control-sm" value="" >
								<input type="hidden" name="collector_agent_id" id="collector_agent_id" value=""  >
								<script>
									$(document).ready(function() {
										$(makeAgentPicker('collector_agent_name','collector_agent_id'));
									});
								</script>
							</div>
							<div class="col-12 col-md-6 ui-widget">
								<div class="col-12 col-md-6"> 
									<input type="button" value="Create" class="insBtn" onClick="if (checkFormValidity($('##newNumSeries')[0])) { submit();  } ">
								</div>
							</div>
						</div>
					</form>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<cfcase value="saveNew">
		<cftry>
			<cfif not isdefined("number_series") OR len(trim(#number_series#)) EQ 0 >
				<cfthrow type="Application" message="Error: No value provided for required value number_series">
			</cfif>
			<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pattern#">
					</cfif>
					<cfif isdefined("remarks")>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
					</cfif>
					<cfif isdefined("collector_agent_id")>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collector_agent_id#">
					</cfif>
				)
			</cfquery>
			<cflocation url="Loan.cfm?Action=editLoan&transaction_id=#nextTransId.nextTransactionId#" addtoken="false">
		<cfcatch>
			<cfthrow type="Application" message="Error Saving new Collecting Event Number Series: #cfcatch.details#">
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
				<div class="container-fluid form-div">
					<div class="container">
						<h2>Edit Collecting Event Number Series</h2>
						<form name="editNumSeries" id="editNumSeries" action="/vocabularies/component/functions.cfc" method="post"> 
							<input type="hidden" id="coll_event_num_series_id" name="coll_event_num_series_id" value="#coll_event_num_series_id#" >
							<input type="hidden" id="method" name="method" value="saveNumSeries" >
							<div class="form-row mb-2">
								<div class="col-md-12">
									<label for="number_series">Name for the Collector Number Series</label>
									<input type="text" id="number_series" name="number_series" class="reqdClr form-control-sm" required value="#number_series#" >					
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-md-12">
									<label for="pattern">Pattern for numbers in this series</label>
									<input type="text" id="pattern" name="pattern" class="form-control-sm" value="#pattern#" >
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-md-12">
									<label for="remarks">Remarks</label>
									<input type="text" id="remarks" name="remarks" class="form-control-sm" value="#remarks#" >		
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12 col-md-6 ui-widget"> 
									<span>
										<label for="collector_agent_name">This is a number series of</label>
										<span id="collector_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</span>
									<input name="collector_agent_name" id="collector_agent_name" class="form-control-sm" value="#agentname#" >
									<input type="hidden" name="collector_agent_id" id="collector_agent_id" value="#collector_agent_id#"  >
									<script>
										$(document).ready(function() {
											$(makeAgentPicker('collector_agent_name','collector_agent_id'));
										});
										function saveChanges(){ 
											// TODO: Submit form, report save.
										};
									</script>
								</div>
								<div class="col-12 col-md-6"> 
									<input type="button" value="Create" class="insBtn" onClick="if (checkFormValidity($('##editNumSeries')[0])) { submit();  } ">
								</div>
							</div>
						</form>
					</div>
				</div>
			</cfoutput>
		</cfif>
	</cfcase>
	<cfdefaultcase>
		<cfthrow type="Application" message="Unknown action.">
	</cfdefaultcase>
</cfswitch>

<!---------------------------------------------------------------------->
<cfinclude template = "/shared/_footer.cfm">
