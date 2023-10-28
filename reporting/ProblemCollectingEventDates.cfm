<!---
/reporting/ProblemCollectingEventDates.cfm

Copyright 2023 President and Fellows of Harvard College

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
<!---
Report on collecting events with problematic values for began date or ended date.
--->
<cfset pageTitle = "Problem Collecting Event Dates Report">
<cfinclude template = "/shared/_header.cfm">

<cfoutput>
	<main class="container py-3">
		<section class="row">
			<div class="col-12">
				<h1 class="h2">Collecting Events with problematic dates</h1>
				<p>This report lists (and links out to the relevant Collecting Event) collecting events with problematic values for date collected.</p>
				<cfquery name="pre1700" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="pre1700_result">
					SELECT collecting_event_id, 
						verbatim_date, 
						to_char(date_Began_date,'yyyy-mm-dd') date_began_date, 
						began_date, 
						case when date_began_date < to_date('1582-10-15','yyyy-mm-dd') then 'pre-Gregorian' else '' end as start_pre_gregorian,
						to_char(date_ended_date,'yyyy-mm-dd') date_ended_date, 
						ended_date,
						case when date_ended_date < to_date('1582-10-15','yyyy-mm-dd') then 'pre-Gregorian' else '' end as end_pre_gregorian
					FROM collecting_event 
					WHERE date_began_date < to_date('1700-01-01','yyyy-mm-dd') or date_ended_date < to_date('1700-01-01','yyyy-mm-dd')
				</cfquery>
				<h2 class="h3">Date Collected prior to 1700</h2>
				<ul>
					<cfset accumulate_shared = 0>
					<cfif pre1700.recordcount EQ 0>
						<li class="py-1">None.  No collecting events have a date prior to 1700-01-01.</li>
					<cfelse>
						<cfloop query="pre1700">
							<li><a href="/localities/CollectingEvent.cfm?collecting_event_id=#collecting_event_id#">(#collecting_event_id#)</a> Verbatim: #verbatim_date# Start: #date_began_date# #start_pre_gregorian# End: #date_ended_date# #end_pre_gregorian#</li> 
						</cfloop>
					</cfif>
				</ul>
				<cfquery name="future" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="future_result">
					SELECT collecting_event_id, 
						verbatim_date, 
						to_char(date_Began_date,'yyyy-mm-dd') date_began_date, 
						began_date, 
						to_char(date_ended_date,'yyyy-mm-dd') date_ended_date, 
						ended_date
					FROM collecting_event 
					WHERE date_began_date > SYSDATE or date_ended_date > SYSDATE
				</cfquery>
				<h2 class="h3">Date Collected in the future</h2>
				<ul>
					<cfset accumulate_shared = 0>
					<cfif future.recordcount EQ 0>
						<li class="py-1">None.  No collecting events have a date after #date_format(now(),'yyyy-mm-dd')#.</li>
					<cfelse>
						<cfloop query="future">
							<li><a href="/localities/CollectingEvent.cfm?collecting_event_id=#collecting_event_id#">(#collecting_event_id#)</a> Verbatim: #verbatim_date# Start: #date_began_date# End: #date_ended_date#</li> 
						</cfloop>
					</cfif>
				</ul>
				<cfquery name="reversed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="reversed_result">
					SELECT collecting_event_id, 
						verbatim_date, 
						to_char(date_Began_date,'yyyy-mm-dd') date_began_date, 
						began_date, 
						case when date_began_date < to_date('1582-10-15','yyyy-mm-dd') then 'pre-Gregorian' else '' end as start_pre_gregorian,
						to_char(date_ended_date,'yyyy-mm-dd') date_ended_date, 
						ended_date,
						case when date_ended_date < to_date('1582-10-15','yyyy-mm-dd') then 'pre-Gregorian' else '' end as end_pre_gregorian
					FROM collecting_event 
					WHERE 
						date_ended_date is not null 
						and date_began_date > date_ended_date
						and began_date <> ended_date
				</cfquery>
				<h2 class="h3">Date Collected end is before start</h2>
				<ul>
					<cfset accumulate_shared = 0>
					<cfif reversed.recordcount EQ 0>
						<li class="py-1">None.  No collecting events have an end date before the start date.</li>
					<cfelse>
						<cfloop query="reversed">
							<li><a href="/localities/CollectingEvent.cfm?collecting_event_id=#collecting_event_id#">(#collecting_event_id#)</a> Verbatim: #verbatim_date# Start: #date_began_date# #start_pre_gregorian# End: #date_ended_date# #end_pre_gregorian#</li> 
						</cfloop>
					</cfif>
				</ul>
			</div>
			<!--- TODO: Date identified before date collected --->
		</section>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
