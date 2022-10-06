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
@param id_for_dialog the id to use for the html element into which the edit text dialog 
  can be loaded, must be unique on the page.

@return block of html text with data from cf_helloworld.
--->
<cffunction name="getCounterHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="parameter" type="string" required="yes">
	<cfargument name="other_parameter" type="string" required="yes">
	<cfargument name="id_for_counter" type="string" required="yes">
	<cfargument name="id_for_dialog" type="string" required="yes">

	<!---
	NOTE: When using threads, cfarguments are out of scope for the thread, place copies of them
	   into the variables scope.    See: https://gist.github.com/bennadel/9760037 for more examples of
   	scope issues related to cfthread 
	--->
	<cfset variables.parameter = arguments.parameter>
	<cfset variables.other_parameter = arguments.other_parameter>
	<cfset variables.id_for_counter = arguments.id_for_counter>
	<cfset variables.id_for_dialog = arguments.id_for_dialog>

	<!--- 

	NOTE: If this cffunction is invoked more than once in a request (e.g. when called directly as a function
		within a loop in coldfusion in a coldfusion page) then the thread name must be unique for each invocation,
		so generate a highly likely to be unique thread name as follows:	

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="getCounterThread#tn#" threadName="mediaWidgetThread#tn#">

	Likewise, include #tn# in the names of the thread in all the other cfthread tags within this cffunction 
	To obtain the output of the thread, use: 
	<cfreturn cfthread["mediaWidgetThread#tn#"].output>

	If the cffunction is called only once in a request (e.g. only from a javascript ajax handler, then the thread name
		does not need to be unique.

	--->
	<cfthread name="getCounterThread">
		<cftry>
			<cfoutput>
				<cfquery name="getCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						text, counter, helloworld_id
					FROM
						MCZBASE.cf_helloworld
					WHERE rownum < 2
				</cfquery>
				<cfif getCounter.recordcount GT 0>
					<h3 class="h3">#getCounter.text#</h3>
					<!--- id_for_counter allows the calling code to specify, and thus know a value to pass to other functions, the id for the counter element in the dom --->
					<!--- see the use of this in the invocation of the javascript updateCounterElement() function --->
					<ul><li id="#encodeForHtml(variables.id_for_counter)#">#getCounter.counter#</li></ul>
					<ul><li><button onClick=" incrementCounterUpdate('#variables.id_for_counter#','#getCounter.helloworld_id#')" class="btn btn-xs btn-secondary" >Increment</button></li></ul>
					<ul><li>#encodeForHtml(variables.parameter)#</li></ul>
					<ul><li>#encodeForHtml(variables.other_parameter)#</li></ul>
					<!--- id_for_dialog allows the calling code to specify the div for the dialog, 
							and thus the potential reuse of this function in different contexts and the 
                     elimination of a hardcoded value for the id of this div in more than one place.
					 --->
					 <ul><li><button onClick=" openUpdateTextDialog('#getCounter.helloworld_id#','#variables.id_for_dialog#');" class="btn btn-xs btn-primary">Edit</button></li></ul>
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
<cffunction name="incrementAllCounters" access="remote" returntype="any" returnformat="json">
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
			<!--- For functions that return structured data, use reportError to produce an error dialog --->
			<!--- the calling jquery.ajax function should include: 
				error: function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"incrementing hello world counter (1)");
				}
			--->
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


<!--- incrementCounter, update the hello world counter for a specified cf_helloworld record.
  @param helloworld_id the primary key value of the row to update.
  @return json containing status(=saved), counter, and text.
  @throws returns error using reportError() and rollsback transaction
--->
<cffunction name="incrementCounter" access="remote" returntype="any" returnformat="json">
	<cfargument name="helloworld_id" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="setCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE 
					MCZBASE.cf_helloworld
				SET
					counter = counter + 1 
				WHERE
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
			</cfquery>
			<cfquery name="getCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					text, counter 
				FROM
					MCZBASE.cf_helloworld
				WHERE
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
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

<!--- updateText, update the hello world text field for a specified cf_helloworld record,
  without updating the cunter.
  @param helloworld_id the primary key value of the row to update.
  @param text the new value for cf_helloworld.text
  @return json containing status(=saved), counter, and text.
  @throws returns error using reportError() and rollsback transaction
--->
<cffunction name="updateText" access="remote" returntype="any" returnformat="json">
	<cfargument name="helloworld_id" type="string" required="yes">
	<cfargument name="text" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="setText" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE 
					MCZBASE.cf_helloworld
				SET
					text = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#text#">
				WHERE
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
			</cfquery>
			<cfquery name="getCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					text, counter 
				FROM
					MCZBASE.cf_helloworld
				WHERE
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
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

<!--- 
 ** method gettextDialogHtml obtains the html content for a dialog to update the value of cf_helloworld.text
 * 
 * @param helloworld_id the id of the row for which to update the text
 * @return html to populate a dialog
--->
<cffunction name="getTextDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="helloworld_id" type="string" required="yes">

	<cfthread name="textDialogThread">
		<cftry>
			<cfquery name="lookupRow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupRow_result">
				select helloworld_id, text, counter
				from MCZBASE.cf_helloworld
				where
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
			</cfquery>
			<cfif lookupRow.recordcount NEQ 1>
				<cfthrow message="Error looking up cf_helloworld row with helloworld_id=#encodeForHtml(helloworld_id)# Query:[#lookupRow_result.SQL#]">
			</cfif>
			<cfoutput query="lookupRow">
				<div class="container-fluid">
					<div class="row">
						<div class="col-12">
							<form id="text_form">
								<input type="hidden" name="helloworld_id" id="helloworld_id" value="#helloworld_id#">
								<label for="text_control" class="data-entry-label">Hello World Text</label>
								<input type="text" name="text" id="text_control" class="data-entry-input mb-2" value="#lookupRow.text#" >
								<script>
									function saveText() {
										var id = $('##helloworld_id').val();
										var text = $('##text_control').val();
										jQuery.getJSON("/hello/component/functions.cfc", { 
											method : "updateText",
											helloworld_id : id,
											text: text
										},
										function (result) {
											console.log(result);
											console.log(result[0].status);
											$("##helloworldtextdialogfeedback").html(result[0].status);
											var responseStatus = result[0].status;
											if (responseStatus == "saved") { 
												$('##helloworldtextdialogfeedback').removeClass('text-danger');
												$('##helloworldtextdialogfeedback').addClass('text-success');
												$('##helloworldtextdialogfeedback').removeClass('text-warning');
											};
											console.log(result[0].counter);
											console.log(result[0].text);
										}
										).fail(function(jqXHR,textStatus,error){ handleFail(jqXHR,textStatus,error,"incrementing hello world counter (1)"); });
									};
									function changed(){
										$('##helloworldtextdialogfeedback').html('Unsaved changes.');
										$('##helloworldtextdialogfeedback').addClass('text-danger');
										$('##helloworldtextdialogfeedback').removeClass('text-success');
										$('##helloworldtextdialogfeedback').removeClass('text-warning');
									};
									$(document).ready(function() {
										console.log("document.ready in returned dialog html");
										$('##text_form [type=text]').on("change",changed);
									});
								</script>
								<button type="button" class="btn btn-xs btn-primary" onClick="saveText();">Save</button>
								<output id="helloworldtextdialogfeedback"><output>
							</form>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="textDialogThread" />
	<cfreturn textDialogThread.output>
</cffunction>

</cfcomponent>
