<!---

* /hello/component/functions.cfc

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

* Demonstrating backing methods for ajax patterns in MCZbase.

--->
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">


<!--- 
getCounterHtml returns a block of html displaying information from the cf_helloworld table.

@param parameter some arbitrary value, displayed in the returned html.
@param other_parameter some arbitrary value, displayed in the returned html.

@return block of html text with data from cf_helloworld.
--->
<cffunction name="getCounterHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="parameter" type="string" required="yes">
	<cfargument name="other_parameter" type="string" required="yes">

	<!--- 

	NOTE: If this cffunction is invoked more than once in a request (e.g. when called directly as a function
		within a loop in coldfusion in a coldfusion page) then the thread name must be unique for each invocation,
		so generate a highly likely to be unique thread name as follows:	

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="getCounterThread#tn#" threadName="mediaWidgetThread#tn#">

	Likewise, include #tn# in the names of the thread in all the other cfthread tags within this cffunction 

	If the cffunction is called only once in a request (e.g. only from a javascript ajax handler, then the thread name
		does not need to be unique.

	--->
	<cfthread name="getCounterThread">
		<cftry>
			<cfoutput>
				<cfquery name="getCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						text, counter 
					FROM
						MCZBASE.cf_helloworld
					WHERE rownum < 2
				</cfquery>
				<cfif getCounter.recordcount GT 0>
					<h3 class="h3">#getCounter.text#</h3>
					<ul><li>#getCounter.counter#</li></ul>
					<ul><li>#encodeForHtml(parameter)#</li></ul>
					<ul><li>#encodeForHtml(other_parameter)#</li></ul>
				<cfelse>
					<h3 class="h3">No Entries</h3>
					<ul><li>#encodeForHtml(parameter)#</li></ul>
					<ul><li>#encodeForHtml(other_parameter)#</li></ul>
				</cfif>
			</cfoutput>
		<cfcatch>
			<!--- For functions that return html blocks to be embedded in a page, the error can be included in the output --->
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getCounterThread" />
	<cfreturn getCounterThread.output>
</cffunction>

</cfcomponent>
