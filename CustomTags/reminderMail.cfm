<!---
CustomTags/reminderMail.cfm

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
<!--- Used in place of cfmail by the reminder jobs in /ScheduledTasks/, with the same attributes (to, cc,
	bcc, from, replyto, subject, type).  Sends the email only where isLiveEmailServer() allows (production
	with master checked out); anywhere else it shows what would have been sent.  The body must be inside
	a cfoutput, as cfmail's body would be. --->
<cfif thisTag.executionMode EQ "end">
	<cfif NOT isDefined("isLiveEmailServer")>
		<cfinclude template="/shared/component/scheduledTasks.cfc" runOnce="true">
	</cfif>
	<cfset variables.messageBody = thisTag.generatedContent>
	<cfset thisTag.generatedContent = "">
	<cfif isLiveEmailServer()>
		<cfmail attributeCollection="#attributes#">#variables.messageBody#</cfmail>
	<cfelse>
		<cfoutput>
			<div class="border rounded p-2 my-2">
				<strong>Not sent (not production with master checked out).</strong> Would send:
				<ul class="mb-1">
					<cfloop list="from,to,cc,bcc,replyto,subject" index="variables.field">
						<cfif structKeyExists(attributes, variables.field) AND len(attributes[variables.field]) GT 0>
							<li>#variables.field#: #encodeForHtml(attributes[variables.field])#</li>
						</cfif>
					</cfloop>
				</ul>
				<cfif structKeyExists(attributes, "type") AND attributes.type EQ "html">
					<div class="border p-2">#variables.messageBody#</div>
				<cfelse>
					<pre class="border p-2">#encodeForHtml(variables.messageBody)#</pre>
				</cfif>
			</div>
		</cfoutput>
	</cfif>
</cfif>
