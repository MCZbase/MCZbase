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
@param id_for_counter the id to use for the html element that displays the current value 
  of the counter, must be unique on the page.

@return block of html text with data from cf_helloworld.
--->
<cffunction name="getCounterHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="parameter" type="string" required="yes">
	<cfargument name="other_parameter" type="string" required="yes">
	<cfargument name="id_for_counter" type="string" required="yes">

	<!---
	NOTE: When using threads, cfarguments are out of scope for the thread, place copies of them
	   into the variables scope.    See: https://gist.github.com/bennadel/9760037 for more examples of
   	scope issues related to cfthread 
	--->
	<cfset variables.parameter = arguments.parameter>
	<cfset variables.other_parameter = arguments.other_parameter>
	<cfset variables.id_for_counter = arguments.id_for_counter>

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
					<ul><li id="#encodeForHtml(variables.id_for_counter)#">#getCounter.counter#</li></ul>
					<ul><li>#encodeForHtml(variables.parameter)#</li></ul>
					<ul><li>#encodeForHtml(variables.other_parameter)#</li></ul>
				<cfelse>
					<h3 class="h3">No Entries</h3>
					<ul><li>#encodeForHtml(variables.parameter)#</li></ul>
					<ul><li>#encodeForHtml(variables.other_parameter)#</li></ul>
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

<!--- incrementCounter, increment the hello world counter (for all rows in cf_helloworld).
  @return json containing status(=saved), counter, and text.
  @throws returns error using reportError() and rollsback transaction
--->
<cffunction name="incrementCounter" access="remote" returntype="any" returnformat="json">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="setCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE 
					MCZBASE.cf_helloworld
				SET
					counter = counter + 1 
			</cfquery>
			<cfquery name="getCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					text, counter 
				FROM
					MCZBASE.cf_helloworld
				WHERE rownum < 2
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["counter"] = "#getCounter.counter#">
			<cfset row["text"] = "#getCounter.text#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
