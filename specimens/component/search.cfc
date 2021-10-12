<!---
specimens/component/search.cfc

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
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- functions to assist in parsing catalog number ranges --->
<cfscript>
/**
* Converts a list of numbers with prefixes to a list of JSON clauses suitable for 
* passing to BUILD_QUERY_DBMS_SQL
*
* @param listOfNumbers  A string containing a list of one or more numbers or ranges
*	 of numbers in one of the forms "1" or "1,3" or "1-3" or "1,4-9"
*	 or with prefixes in the form "A-1" or "A-2,B-3" or "A-1-3" or "A-1-3,5"
*	 or "A-1-3,B-4" or other variants of commma separated atoms in the forms:
*	 "1" (exact match, no prefix), "A-1" (single, with prefix), "A-1-2"
*	 (range with prefix), or "%-1" (any prefix), "1-3" (exact match on range).
*	 Prefix is separated and searched separately from the numeric range.
* @param integerFieldname  The name of the number field on which the listOfNumbers is a condition.
* @param prefixFieldname   The name of the string field on which the listOfNumbers is a condition.
* @param embeddedSeparator true if the separator is stored embedded within the prefix field, false
*		if prefix field only contains the prefix data, not the field separator, if true, then a 
*		dash separator will be added at the end of the prefix if one is not present in the provided
*		listOfNumbers, that is A1-2 will be turned into prefixFieldName="A-" if false, then "A" alone
*		is used.
*
* @return A string containing conditions to append to a SQL where clause.  See unit tests:
*		 testScriptPrefixedNumberListToSQLWherePrefix and testScriptPrefixedNumberListToSQLWherePrefixLists
*/
function ScriptPrefixedNumberListToJSON(listOfNumbers, integerFieldname, prefixFieldname, embeddedSeparator, nestDepth, leadingJoin ) {
	var result = "";
	var orBit = "";
	var wherePart = "";

	// Prepare list for parsing
	listOfNumbers = trim(listOfNumbers);
	// Change ", " to "," and then " " to "," to allow space and comma separators
	listOfNumbers = REReplace(listOfNumbers, ", ", ",","all");	// comma space to comma
	listOfNumbers = REReplace(listOfNumbers, " ", ",","all");	// space to comma
	listOfNumbers = REReplace(listOfNumbers, "\*", "%","all");	// dos to sql wildcard
	// strip out any other characters
	listOfNumbers = REReplace(listOfNumbers, "[^0-9A-Za-z%,\-]","","all");
	// reduce repeating commas to a single comma
	listOfNumbers = REReplace(listOfNumbers, ",,+",",","all");
	// strip out leading/trailing commas
	listOfNumbers = REReplace(listOfNumbers, "^,","");
	listOfNumbers = REReplace(listOfNumbers, ",$","");

	// split list into atoms.

	// check to see if listofnumbers contains no delimiter.
	if (find(",",listOfNumbers) EQ 0) {
		lparts = ArrayNew(1);
		lparts[1] = listOfNumbers;
	} else {
		// split listOfNumbers on ","
		lparts = ListToArray(listOfNumbers,",",false);
	}

	// find prefixes in atoms

	prefix = "";
	numericClause = "";
	wherebit = "";
	comma = "";
	leadingJoin = "and";
	comma = "";
	for (i=1; i LTE ArrayLen(lparts); i=i+1) {
		// Prefix is at least one letter optionally followed by a dash separator.
		// Need to use [A-Z]+ here to prevent match on dash inside bare numeric range.
		prefixSt = REFind("^[A-Za-z]+\-{0,1}",lparts[i],0,true);
		if (prefixSt.pos[1] EQ 0 ) {
			prefix = "";
		} else {
			prefix = Mid(lparts[i],prefixSt.pos[1],prefixSt.len[1]);
		}
		numericSt = REFind("[0-9]+\-*[0-9]*",lparts[i],0,true);
		if (numericSt.pos[1] EQ 0 ) {
			numeric = "";
		} else {
			numeric = Mid(lparts[i],numericSt.pos[1],numericSt.len[1]);
		}
		if (embeddedSeparator EQ true) {
			// If the prefix isn't blank and doesn't end with the separator, add it.
			if ((prefix NEQ "") AND (Find("-",prefix) EQ 0)) {
				prefix = prefix & "-";
			}
		} else {
			//remove any trailing dash
			prefix = REReplace(prefix,"\-$","");
		}

		if (numeric NEQ "") {
			numericClause = ScriptNumberListToJSON(numeric, integerFieldname, nestDepth, leadingJoin);
			wherebit = wherebit & comma & numericClause;
			comma = ",";
			leadingJoin = "or";
		}
		if (prefix NEQ "") {
			wherebit = wherebit & comma & '{"nest":"#nestDepth#","join":"and","field": "' & prefixFieldname &'","comparator": "=","value": "#prefix#"}';
			comma = ",";
			leadingJoin = "or";
		}
	}
	result = wherebit;
	return result;
}
</cfscript>

<cfscript>
/**
* Converts a list of numbers to a list of JSON clauses suitable for 
* passing to BUILD_QUERY_DBMS_SQL
*
* @param listOfNumbers  A string containing a list of one or more numbers or ranges
*	 of numbers in one of the forms "1" or "1,3" or "1-3" or "1,4-9".
* @param fieldname  The name of the fieldname on which the listOfNumbers is a condition.
* @param nestDepth (not yet implemented, the expression nesting depth)
* @param leadingJoin the value to use in the first join:"" in constructed JSON (not yet implemented, uses and)
* @return A string containing conditions specified in JSON.
* @see unit test testScriptNumberListToJSON
*/
function ScriptNumberListToJSON(listOfNumbers, fieldname, nestDepth, leadingJoin) {
	var result = "";
	var orBit = "";
	var wherePart = "";
	// <!--- '{"join":"and","field": "cat_num","comparator": "IN","value": "#encodeForJavaScript(value)#"}'  --->

	// Prepare list for parsing
	listOfNumbers = trim(listOfNumbers);
	// Change ", " to "," and then " " to  "," to allow space and comma separators
	listOfNumbers = REReplace(listOfNumbers, ", ", ",","all");   // comma space to comma
	listOfNumbers = REReplace(listOfNumbers, " ", ",","all");	// space to comma
	// strip out any other characters
	listOfNumbers = REReplace(listOfNumbers, "[A-Za-z]","","all");
	listOfNumbers = REReplace(listOfNumbers, "[^0-9,\-]","","all");
	// reduce repeating commas to a single comma
	listOfNumbers = REReplace(listOfNumbers, ",,+",",","all");
	// strip out leading/trailing commas
	listOfNumbers = REReplace(listOfNumbers, "^,","");
	listOfNumbers = REReplace(listOfNumbers, ",$","");

	if (ArrayLen(REMatch("^[0-9]+$",listOfNumbers))>0) {
		//  Just a single number, exact match.
		result = '{"nest":"#nestDepth#","join":"' & leadingJoin & '","field": "' & fieldname &'","comparator": "=","value": "#encodeForJavaScript(listOfNumbers)#"}';
	} else {
		if (ArrayLen(REMatch("^[0-9]+\-[0-9]+$",listOfNumbers))>0) {
			// Just a single range, two clauses, between start and end of range.
			parts = ListToArray(listOfNumbers,"-");
			lowPart = parts[1];
			highPart = parts[2];
			if (lowPart>highPart) {
				lowPart = parts[2];
				highPart = parts[1];
			}
			if (ucase(fieldname) IS "CAT_NUM") { 
				fieldname = "CAT_NUM_INTEGER";
			}
			result = '{"nest":"#nestDepth#.1","join":"' & leadingJoin & '","field": "' & fieldname &'","comparator": ">=","value": "#encodeForJavaScript(lowPart)#"';
			result = result & '},{"nest":"#nestDepth#.2","join":"and","field": "' & fieldname &'","comparator": "<=","value": "#encodeForJavaScript(highPart)#"}';
		} else if (ArrayLen(REMatch("^[0-9,]+$",listOfNumbers))>0) {
			// Just a list of numbers without ranges, translates directly to IN
			if (listOfNumbers!=",") {
				result = '{"nest":"#nestDepth#","join":"and","field": "' & fieldname &'","comparator": "IN","value": "#encodeForJavaScript(listOfNumbers)#"}';
			} else {
				// just a comma with no numbers, return empty string
				result = "";
			}
		} else {
			// Error or list of numbers some of which are ranges, split and treat each separately.
			if (ArrayLen(REMatch(",",listOfNumbers))>0) {
				// split listOfNumbers on ","
				lparts = ListToArray(listOfNumbers,",",false);
				for(i=1; i LTE ArrayLen(lparts); i=i+1) {
					// for each part, check to see if part is a range
					// if part is a range, return "OR (fieldname >= minimum AND fieldname <= maximum)"
					// if part is a single number, return "OR fieldname IN ( number )"
					wherePart = ScriptNumberListPartToJSON(lparts[i], fieldname, nestDepth, "or");
					// allow for the case of two or more sequential commas.
					comma = "";
					if (result NEQ "") { 
						comma = ",";
					}
					if (wherePart NEQ "") {
						result = result & comma & wherePart;
					}
				}
			} else {
				// Error state.  Not a single number, list, or range.
			}
		}
	}
	return "#result#";
}
</cfscript>
<cfscript>
/**
*
* Supporting function for ScriptNumberListToSQLWhere(), converts a number or a range into
* a portion of a SQL where clause as a condition on a specified field.  
*
* @param atom a number or a range of two numbers separated by a dash "4-6", should not contain any commas.
* @param fieldname the name of the field on which atom is a condition.
* @param nestDepth (not yet implemented, the expression nesting depth)
* @param leadingJoin the value to use in the first join:"" in constructed JSON (not yet implemented, uses and)
* @return a string contaning "( fieldname IN (list))"  or "( fieldname >= num AND fieldname <=num)" or ""
*/
function ScriptNumberListPartToJSON (atom, fieldname, nestDepth, leadingJoin) {
	var result = "";
	// check to see if atom is just one number,
	// if so return "AND fieldname IN ( number )"
	if (ArrayLen(REMatch("^[0-9]+$",atom))>0) {
		//  Just a single number, exact match.
		result = '{"join":"' & leadingJoin & '","field": "' & fieldname &'","comparator": "=","value": "#encodeForJavaScript(atom)#"}';
	} else {
		if (ArrayLen(REMatch("^[0-9]+\-[0-9]+$",atom))>0) {
			// Just a single range, two clauses, between start and end of range.
			parts = ListToArray(atom,"-");
			lowPart = parts[1];
			highPart = parts[2];
			if (lowPart>highPart) {
				lowPart = parts[2];
				highPart = parts[1];
			}
			if (ucase(fieldname) IS "CAT_NUM") { 
				fieldname = "CAT_NUM_INTEGER";
			}
			result = '{"join":"' & leadingJoin & '","field": "' & fieldname &'","comparator": ">=","value": "#encodeForJavaScript(lowPart)#"';
			result = result & '},{"join":"and","field": "' & fieldname &'","comparator": "<=","value": "#encodeForJavaScript(highPart)#"}';
		} else {
			// Error state.  Not a single number, list, or range.
			// Likely to result from two sequential commas, so return an empty string.
		}
	}
	return "#result#";
}
</cfscript>

<!---   Function executeKeywordSearch backing method for specimen search 
	@param result_id a uuid which identifies this search.
	@param searchText search string using the CONTEXT grammar, but with ! for not, $ for soundex, and # for wordroot.
	@param collection_cde a list of zero or more collection_cde values to limit the search
	@returns json for a jqxgrid or an http 500 status with an error message
--->
<cffunction name="executeKeywordSearch" access="remote" returntype="any" returnformat="json">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="searchText" type="string" required="yes">
	<cfargument name="collection_cde" type="string" required="no">

	<cfset search_json = "[">
	<cfset separator = "">
	<cfset join = ''>

	<cfset nest = 1>
	
	<cfif isDefined("collection_cde") AND len(collection_cde) GT 0>
		<cfset field = '"field": "collection_cde"'>
		<cfset comparator = '"comparator": "IN"'>
		<cfset value = encodeForJavaScript(collection_cde)>
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("searchText") AND len(searchText) GT 0>
		<cfset field = '"field": "kewyordSearchText"'>
		<cfset comparator = '"comparator": ""'>
		<!--- convert operator characters from conventions used elsewhere in MCZbase to oracle CONTAINS operators --->
		<!--- 
		User enters >  converted to:  meaning
			! ->  ~   NOT
			$ ->  !   SOUNDEX
			# ->  $   STEM
			~ ->  ~   NOT  (no change made, but we don't document that ~ is allowed)
		NOTE: order of replacements matters.
		--->
		<cfset searchValue = searchText>
		<cfset searchValue = replace(searchValue,"!","~","all")>
		<cfset searchValue = replace(searchValue,"$","!","all")>
		<cfset searchValue = replace(searchValue,"##","$","all")>

		<!--- escape quotes for json construction --->
		<cfset searchValueForJSON = searchValue>
		<cfset searchValueForJSON = replace(searchValueForJSON,"\","\\","all")>
		<cfset searchValueForJSON = replace(searchValueForJSON,'"','\"',"all")>
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"searchValue": "#searchValueForJSON#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	
	<cfset search_json = "#search_json#]">
	<cfif isdefined("debug") AND len(debug) GT 0>
		<cfdump var="#search_json#">
		<cfdump var="#session.dbuser#">
		<cfabort>
	</cfif>

	<cftry>
		<cfif NOT IsJSON(search_json)>
			<cfthrow message="unable to construct valid json for query">
		</cfif>

		<cfif isDefined("searchValue") and len(searchValue) gt 0>
			<cfquery name="getFieldMetadata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getFieldMetadata_result">
				SELECT upper(column_name) as column_name, sql_element, data_type, category, label, disp_order
				FROM cf_spec_res_cols_r
				WHERE access_role = 'PUBLIC'
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
						OR access_role = 'COLDFUSION_USER'
					</cfif>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
						OR access_role = 'MANAGE_TRANSACTIONS'
					</cfif>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"DATA_ENTRY")>
						OR access_role = 'DATA_ENTRY'
					</cfif>
				ORDER by category, disp_order
			</cfquery>

			<!--- 
			<cfstoredproc procedure="build_query_dbms_sql" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="prepareSearch_result">
				<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
				<cfprocparam cfsqltype="CF_SQL_CLOB" value="#search_json#">
				<cfprocresult name="search">
			</cfstoredproc>
			<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
				SELECT 
					<cfset comma = "">
					<cfloop query="getFieldMetadata">
						<cfif len(sql_element) GT 0> 
							#comma##replace(sql_element,"''","'","all")# #column_name#
							<cfset comma = ",">
						</cfif>
					</cfloop>
				FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
					left join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
				WHERE
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			</cfquery>
			--->

			<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
				SELECT
					<cfset comma = "">
					<cfloop query="getFieldMetadata">
						<cfif len(sql_element) GT 0> 
							#comma##replace(sql_element,"''","'","all")# #column_name#
							<cfset comma = ",">
						</cfif>
					</cfloop>
				FROM <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> flatTableName
					join FLAT_TEXT FT ON flatTableName.COLLECTION_OBJECT_ID = FT.COLLECTION_OBJECT_ID
				WHERE contains(ft.cat_num, <cfqueryparam value="#searchValue#" CFSQLType="CF_SQL_VARCHAR">, 1) > 0
					<cfif isDefined("collection_cde") and len(collection_cde) gt 0>
						and flatTableName.collection_cde in (<cfqueryparam value="#collection_cde#" cfsqltype="CF_SQL_VARCHAR" list="true">)
					</cfif>
					and rownum < 2001
			</cfquery>
		<cfelse>
			<cfthrow message="No search terms provided.">
		</cfif>

		<cfset rows = 0>
		<cfset data = ArrayNew(1)>

		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#ucase(col)#"] = replace(search[col][currentRow],'""','&quot;','all')>
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<cffunction name="constructJsonForField">
	<cfargument name="join" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="separator" type="string" required="yes">
	<cfargument name="nestDepth" type="string" required="yes">

	<cfset search_json = "">
		<cfif left(value,2) is "=<">
			<cfset value="#ucase(right(value,len(value)-2))#">
			<cfset comparator = '"comparator": "<="'>
		<cfelseif left(value,2) is "=>">
			<cfset value="#ucase(right(value,len(value)-2))#">
			<cfset comparator = '"comparator": ">="'>
		<cfelseif left(value,1) is "=">
			<cfset value="#ucase(right(value,len(value)-1))#">
			<cfset comparator = '"comparator": "="'>
		<cfelseif left(value,1) is "~">
			<cfset value="#ucase(right(value,len(value)-1))#">
			<cfset comparator = '"comparator": "JARO_WINKLER"'>
		<cfelseif left(value,2) is ">=">
			<cfset value="#ucase(right(value,len(value)-2))#">
			<cfset comparator = '"comparator": ">="'>
		<cfelseif left(value,2) is "<=">
			<cfset value="#ucase(right(value,len(value)-2))#">
			<cfset comparator = '"comparator": "<="'>
		<cfelseif left(value,2) is "!~">
			<cfset value="#ucase(right(value,len(value)-2))#">
			<cfset comparator = '"comparator": "NOT JARO_WINKLER"'>
		<cfelseif left(value,1) is "$">
			<cfset value="#ucase(right(value,len(value)-1))#">
			<cfset comparator = '"comparator": "SOUNDEX"'>
		<cfelseif left(value,2) is "!$">
			<cfset value="#ucase(right(value,len(value)-2))#">
			<cfset comparator = '"comparator": "NOT SOUNDEX"'>
		<cfelseif left(value,1) IS "!">
			<cfset value="#ucase(right(value,len(value)-1))#">
			<cfset comparator = '"comparator": "not like"'>
		<cfelse>
			<cfset comparator = '"comparator": "like"'>
			<cfset value = encodeForJavaScript(value)>
			<cfset value = replace(value,"\x20"," ","all")>
			<cfset value = replace(value,"\x5B","[","all")>
			<cfset value = replace(value,"\x5D","]","all")>
		</cfif>
		<cfset search_json = '#search_json##separator#{"nest":"#nestDepth#",#join##field#,#comparator#,"value": "#value#"}'>
	<cfreturn #search_json#>
</cffunction>

<!--- Function executeBuilderSearch backing method for specimen search via the search builder
	@param result_id a uuid which identifies this search.
	@param debug if given a value, dump the json that would be sent to build_query instead of
	  running the query and returning a result.
--->
<cffunction name="executeBuilderSearch" access="remote" returntype="any" returnformat="json">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="builderMaxRows" type="string" required="yes">

	<cfset search_json = "[">
	<cfset separator = "">
	<cfset join = ''>
	<cfif isNumeric(builderMaxRows) EQ 0>
		<cfthrow message="Value provided for builderMaxRows is not a number">
	</cfif>

	<cfquery name="searchFields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="searchFields_result">
		SELECT search_category, table_name, column_name, column_alias, data_type
		FROM cf_spec_search_cols
		ORDER BY
		search_category, table_name, label
	</cfquery>

	<cfloop index="i" from="1" to="#int(builderMaxRows)#">
		<cfset hasEntry = true>
		<cftry>
			<cfset fieldProvided = Evaluate("field"&i)>
			<cfset searchText = Evaluate("searchText"&i)>
			<cfif len(fieldProvided) EQ 0><cfthrow message="no field"></cfif>
			<cfif len(searchText) EQ 0><cfthrow message="no text"></cfif>
		<cfcatch>
			<cfset hasEntry = false>
		</cfcatch>
		</cftry>
		<cfif hasEntry>
			<cfset searchId = Evaluate("searchId"&i)>
			<cfset joinWith = Evaluate("joinOperator"&i)>
			<cfif joinWith EQ "AND">
				<cfset join='"join":"and",'>
			<cfelseif joinWith EQ "OR">
				<cfset join='"join":"or",'>
			<cfelse>
				<cfset join=''>
			</cfif>
			<cfset matched = false>
			<cfset nest = 1>
			<cfif isDefined("searchId") AND len(searchId) GT 0>
				<!--- if a searchId{n} value was provided, use it instead of searchText{n} to support autocomplete field pairs --->
				<cfset searchText = searchId>
			</cfif>
			<cfloop query="searchFields">
				<cfset tableField = "#searchFields.table_name#:#searchFields.column_name#">
				<cfif fieldProvided EQ tableField AND len(searchText) GT 0>
					<cfset matched = true>
					<cfset field = '"field": "#searchFields.column_alias#"'>
					<!--- Warning: only searchText may be passed directly from the user here, join and field must be known good values ---> 
					<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#searchText#",separator="#separator#",nestDepth="#nest#")>
					<cfset separator = ",">
					<cfset nest = nest + 1>
				</cfif>
			</cfloop>
			<cfif not matched>
				<cfthrow message="Unknown search field [#encodeForHtml(fieldProvided)#].">
			</cfif>
		</cfif>
   </cfloop>

	<cfset search_json = "#search_json#]">

	<cfif isdefined("debug") AND len(debug) GT 0>
		<cfdump var="#search_json#">
		<cfdump var="#session.dbuser#">
		<cfabort>
	</cfif>
	<cfif NOT IsJSON(search_json)>
		<cfthrow message="unable to construct valid json for query">
	</cfif>

	<cftry>
		<cfset username = session.dbuser>
		<cfstoredproc procedure="build_query_dbms_sql" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="prepareSearch_result">
			<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
			<cfprocparam cfsqltype="CF_SQL_CLOB" value="#search_json#">
			<cfprocresult name="search">
		</cfstoredproc>
		<cfquery name="getFieldMetadata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getFieldMetadata_result">
			SELECT upper(column_name) as column_name, sql_element, data_type, category, label, disp_order
			FROM cf_spec_res_cols_r
			WHERE access_role = 'PUBLIC'
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					OR access_role = 'COLDFUSION_USER'
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
					OR access_role = 'MANAGE_TRANSACTIONS'
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"DATA_ENTRY")>
					OR access_role = 'DATA_ENTRY'
				</cfif>
			ORDER by category, disp_order
		</cfquery>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				<cfset comma = "">
				<cfloop query="getFieldMetadata">
					<cfif len(sql_element) GT 0> 
						#comma##replace(sql_element,"''","'","all")# #column_name#
						<cfset comma = ",">
					</cfif>
				</cfloop>
			FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
				join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
			WHERE
				user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>

		<cfset rows = 0>
		<cfset data = ArrayNew(1)>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#ucase(col)#"] = replace(search[col][currentRow],'""','&quot;','all')>
			</cfloop>
			<cfset data[i] = row>
			<cfset i = i + 1>
		</cfloop>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- Function executeFixedSearch backing method for specimen search
	@param result_id a uuid which identifies this search.
	@param debug if given a value, dump the json that would be sent to build_query instead of
	  running the query and returning a result.
--->
<cffunction name="executeFixedSearch" access="remote" returntype="any" returnformat="json">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="collection" type="string" required="no">
	<cfargument name="cat_num" type="string" required="no">
	<cfargument name="other_id_type" type="string" required="no">
	<cfargument name="part_name" type="string" required="no">
	<cfargument name="preserve_method" type="string" required="no">
	<cfargument name="other_id_number" type="string" required="no">
	<cfargument name="type_status" type="string" required="no">
	<cfargument name="full_taxon_name" type="string" required="no">
	<cfargument name="genus" type="string" required="no">
	<cfargument name="family" type="string" required="no">
	<cfargument name="phylorder" type="string" required="no">
	<cfargument name="phylclass" type="string" required="no">
	<cfargument name="phylum" type="string" required="no">
	<cfargument name="kingdom" type="string" required="no">
	<cfargument name="author_text" type="string" required="no">
	<cfargument name="scientific_name" type="string" required="no">
	<cfargument name="taxon_name_id" type="string" required="no">
	<cfargument name="higher_geog" type="string" required="no">
	<cfargument name="country" type="string" required="no">
	<cfargument name="state_prov" type="string" required="no">
	<cfargument name="county" type="string" required="no">
	<cfargument name="island" type="string" required="no">
	<cfargument name="island_group" type="string" required="no">
	<cfargument name="collector" type="string" required="no">
	<cfargument name="collector_agent_id" type="string" required="no">
	<cfargument name="verbatim_date" type="string" required="no">
	<cfargument name="loan_number" type="string" required="no">
	<cfargument name="accession_number" type="string" required="no">
	<cfargument name="deaccession_number" type="string" required="no">
	<cfargument name="publication_id" type="string" required="no">
	<cfargument name="citation" type="string" required="no">
	<cfargument name="nature_of_id" type="string" required="no">
	<cfargument name="determiner" type="string" required="no">
	<cfargument name="determiner_id" type="string" required="no">
	<cfargument name="debug" type="string" required="no">

	<cfset search_json = "[">
	<cfset separator = "">
	<cfset join = ''>

	<cfset nest = 1>

	<cfif isDefined("collection") AND len(collection) GT 0>
		<cfset field = '"field": "collection_cde"'>
		<cfset comparator = '"comparator": "IN"'>
		<cfset value = encodeForJavaScript(collection)>
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("cat_num") AND len(cat_num) GT 0>
		<cfset clause = ScriptPrefixedNumberListToJSON(cat_num, "CAT_NUM_INTEGER", "CAT_NUM_PREFIX", true, nest, "and")>
		<cfset search_json = "#search_json##separator##clause#">
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("other_id_number") AND len(other_id_number) GT 0>
		<cfif left(other_id_number,1) is "=" OR left(other_id_number,1) is "!">
			<cfset field = '"field": "display_value"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#other_id_number#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
		 	<cfset nest = nest + 1>
		<cfelse>
			<cfset clause = ScriptPrefixedNumberListToJSON(other_id_number, "OTHER_ID_NUMBER", "OTHER_ID_PREFIX", false, nest, "and")>
			<cfset search_json = "#search_json##separator##clause#">
			<cfset separator = ",">
			<cfset join='"join":"and",'>
		 	<cfset nest = nest + 1>
		</cfif>
	</cfif>
	<cfif isDefined("other_id_type") AND len(other_id_type) GT 0>
		<cfset field = '"field": "other_id_type"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#other_id_type#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("part_name") AND len(part_name) GT 0>
		<cfset field = '"field": "part_name"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#part_name#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("verbatim_date") AND len(verbatim_date) GT 0>
		<cfset field = '"field": "verbatim_date"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#verbatim_date#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("preserve_method") AND len(preserve_method) GT 0>
		<cfset field = '"field": "preserve_method"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#preserve_method#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("taxon_name_id") AND len(taxon_name_id) GT 0>
		<cfset field = '"field": "IDENTIFICATIONS_TAXON_NAME_ID"'>
		<cfset comparator = '"comparator": "="'>
		<cfset value = encodeForJavaScript(taxon_name_id)>
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	<cfelse>
		<cfif isDefined("scientific_name") AND len(scientific_name) GT 0>
			<cfset field = '"field": "IDENTIFICATIONS_SCIENTIFIC_NAME"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#scientific_name#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("full_taxon_name") AND len(full_taxon_name) GT 0>
			<cfset field = '"field": "full_taxon_name"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#full_taxon_name#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("author_text") AND len(author_text) GT 0>
			<cfset field = '"field": "author_text"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#author_text#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("genus") AND len(genus) GT 0>
			<cfset field = '"field": "genus"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#genus#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("family") AND len(family) GT 0>
			<cfset field = '"field": "family"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#family#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("phylorder") AND len(phylorder) GT 0>
			<cfset field = '"field": "phylorder"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#phylorder#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("phylclass") AND len(phylclass) GT 0>
			<cfset field = '"field": "phylclass"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#phylclass#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("phylum") AND len(phylum) GT 0>
			<cfset field = '"field": "phylum"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#phylum#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("kingdom") AND len(kingdom) GT 0>
			<cfset field = '"field": "kingdom"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#kingdom#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
	</cfif>
	<cfif isDefined("type_status") AND len(type_status) GT 0>
		<cfset field = '"field": "citations_type_status"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#type_status#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	
	<cfif isDefined("higher_geog") AND len(higher_geog) GT 0>
		<cfset field = '"field": "higher_geog"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#higher_geog#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("country") AND len(country) GT 0>
		<cfset field = '"field": "country"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#country#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("state_prov") AND len(state_prov) GT 0>
		<cfset field = '"field": "state_prov"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#state_prov#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("county") AND len(county) GT 0>
		<cfset field = '"field": "county"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#county#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("island_group") AND len(island) GT 0>
		<cfset field = '"field": "island_group"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#island_group#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("island") AND len(island) GT 0>
		<cfset field = '"field": "island"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#island#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
		<cfif isDefined("loan_number") AND len(loan_number) GT 0>
			<cfset field = '"field": "loan_number"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#loan_number#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("accn_number") AND len(accn_number) GT 0>
			<cfset field = '"field": "accn_number"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#accn_number#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("deaccession_number") AND len(deaccession_number) GT 0>
			<cfset field = '"field": "deaccession_number"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#deaccession_number#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
	</cfif>

	<cfif isDefined("collector_agent_id") AND len(collector_agent_id) GT 0>
		<cfset field = '"field": "COLLECTORS_AGENT_ID"'>
		<cfset comparator = '"comparator": "="'>
		<cfset value = encodeForJavaScript(collector_agent_id)>
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	<cfelse>
		<cfif isDefined("collector") AND len(collector) GT 0>
			<cfset field = '"field": "COLLECTORS_AGENT_NAME"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#collector#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
	</cfif>

	<cfif isDefined("publication_id") AND len(publication_id) GT 0>
		<cfset field = '"field": "CITATIONS_PUBLICATION_ID"'>
		<cfset comparator = '"comparator": "="'>
		<cfset value = encodeForJavaScript(publication_id)>
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
		<!--- TODO: Support textual search on publication from citation variable --->
	</cfif>


	<cfif isDefined("determiner_id") AND len(determiner_id) GT 0>
		<cfset field = '"field": "IDENTIFICATION_AGENT_ID"'>
		<cfset comparator = '"comparator": "="'>
		<cfset value = encodeForJavaScript(determiner_id)>
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	<cfelse>
		<cfif isDefined("determiner") AND len(collector) GT 0>
			<cfset field = '"field": "IDENTIFICATIONS_AGENT_NAME"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#collector#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
	</cfif>

	<cfif isDefined("nature_of_id") AND len(nature_of_id) GT 0>
		<cfset field = '"field": "NATURE_OF_ID"'>
		<cfset comparator = '"comparator": "="'>
		<cfset value = encodeForJavaScript(nature_of_id)>
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>

	<cfset search_json = "#search_json#]">
	<cfif isdefined("debug") AND len(debug) GT 0>
		<cfdump var="#search_json#">
		<cfdump var="#session.dbuser#">
		<cfabort>
	</cfif>
	<cfif NOT IsJSON(search_json)>
		<cfthrow message="Unable to construct valid json for query.">
	</cfif>
	<cfif search_json IS "[]">
		<cfthrow message="You must enter some search criteria.">
	</cfif>

	<cftry>
		<cfset username = session.dbuser>
		<!--- errors are handled by build_query_dbms_sql throwing exceptions --->
		<cfstoredproc procedure="build_query_dbms_sql" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="prepareSearch_result">
			<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
			<cfprocparam cfsqltype="CF_SQL_CLOB" value="#search_json#">
			<cfprocresult name="search">
		</cfstoredproc>
		<cfquery name="getFieldMetadata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="attrFields_result">
			SELECT upper(column_name) as column_name, sql_element, data_type, category, label, disp_order
			FROM cf_spec_res_cols_r
			WHERE access_role = 'PUBLIC'
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					OR access_role = 'COLDFUSION_USER'
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
					OR access_role = 'MANAGE_TRANSACTIONS'
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"DATA_ENTRY")>
					OR access_role = 'DATA_ENTRY'
				</cfif>
			ORDER by category, disp_order
		</cfquery>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				<cfset comma = "">
				<cfloop query="getFieldMetadata">
					<cfif len(sql_element) GT 0> 
						#comma##replace(sql_element,"''","'","all")# #column_name#
						<cfset comma = ",">
					</cfif>
				</cfloop>
			FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
				join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
			WHERE
				user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>

		<cfset rows = 0>
		<cfset data = ArrayNew(1)>

		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#ucase(col)#"] = replace(search[col][currentRow],'""','&quot;','all')>
			</cfloop>
			<cfset data[i] = row>
			<cfset i = i + 1>
		</cfloop>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getCatalogedItemAutocompleteMeta.  Search for specimens with a substring match on guid, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and just the guid as the selected value.

@param term information to search for.
@return a json structure containing id and value, with guid in value and collection_object_id in id, and guid with more data in meta.
--->
<cffunction name="getCatalogedItemAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT distinct
				f.collection_object_id, f.guid,
				f.scientific_name, f.spec_locality
			FROM
				#session.flatTableName# f
			WHERE
				f.guid like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
				OR
				f.scientific_name like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
				OR
				f.spec_locality like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.collection_object_id#">
			<cfset row["value"] = "#search.guid#" >
			<cfset row["meta"] = "#search.guid# (#search.scientific_name# #search.spec_locality#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getLocalityAutocompleteMeta.  Search for localities with a substring match on specific locality, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and just spec_locality and locality id as the selected value.

@param term information to search for.
@return a json structure containing id and value, with spec_locality and locality_id in value and locality_id in id, and more data in meta.
--->
<cffunction name="getLocalityAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT distinct
				f.locality_id,
				f.spec_locality,
				f.higher_geog
			FROM
				#session.flatTableName# f
			WHERE
				f.spec_locality like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.locality_id#">
			<cfset row["value"] = "#search.spec_locality# (#search.locality_id#)" >
			<cfset row["meta"] = "#search.spec_locality# #search.higher_geog# (#search.locality_id#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getCollectingEventAutocompleteMeta.  Search for collecting events, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and minimal details for the selected value.

@param term information to search for.
@return a json structure containing id and value, with guid in value and collection_object_id in id, and guid with more data in meta.
--->
<cffunction name="getCollectingEventAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT distinct
				f.collecting_event_id,
				f.began_date, f.ended_date,
				f.collecting_source, f.collecting_method,
				f.verbatimlocality,
				f.spec_locality
			FROM
				#session.flatTableName# f
			WHERE
				f.spec_locality like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
				OR
				f.collecting_source like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
				OR
				f.collecting_method like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
				OR
				f.began_date like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.collecting_event_id#">
			<cfset row["value"] = "#search.spec_locality# #search.began_date#/#search.ended_date# (#search.collecting_event_id#)" >
			<cfset row["meta"] = "#search.spec_locality# #search.began_date#/#search.ended_date# #search.collecting_source# #search.collecting_method# (#search.collecting_event_id#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- getTypes get type names and other information about type specimens by collection
 @param collection collection code for the collection for which to look up types
 @param kind jind of type status, Primary, Secondary, Voucher, Voucher Not of types to return
 @return json suitable for a jqx grid
--->
<cffunction name="getTypes" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection" type="string" required="yes">
	<cfargument name="kind" type="string" required="yes">
	<cfargument name="phylorder" type="string" required="no">
	<cfargument name="family" type="string" required="no">
	<cfargument name="showplaceholders" type="string" required="no">
	<cfargument name="author_text" type="string" required="no">
	
	<cfif not isdefined("showplaceholders")><cfset showplaceholders=""></cfif>

	<cftry>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT DISTINCT
				flat.guid, 
				flat.cat_num,
				toptypestatuskind, 
				mczbase.get_top_typestatus(flat.collection_object_id) as toptypestatus, 
				taxonomy.phylorder,
				taxonomy.family,
				taxonomy.genus as typegenus, 
				taxonomy.species as typespecies, 
				taxonomy.subspecies as typesubspecies, 
				decode(taxonomy.subspecies, null, taxonomy.species, taxonomy.subspecies) as typeepithet,
				typestatusplain, 
				flat.scientific_name as currentname, 
				flat.author_text as currentauthorship, 
				CONCATATTRIBUTEVALUE(flat.collection_object_id,'associated grant') as associatedgrant, 
				CONCATUNDERSCORECOLS(flat.collection_object_id) as namedgroups,
				flat.country,
				flat.spec_locality,
				mczbase.get_typestatusbits(flat.collection_object_id, mczbase.get_top_typestatus(flat.collection_object_id)) as bits
			FROM <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> flat
				, taxonomy 
			WHERE collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection#"> 
				and toptypestatuskind = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#kind#"> 
				and taxonomy.taxon_name_id = mczbase.GET_TYPESTATUSTAXON(flat.collection_object_id,mczbase.get_top_typestatus(flat.collection_object_id))
				<cfif isDefined("phylorder") AND len(phylorder) GT 0>
					<cfif left(phylorder,1) is "=">
						AND upper(flat.phylorder) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylorder,len(phylorder)-1))#">
					<cfelseif left(phylorder,1) is "$">
						AND soundex(flat.phylorder) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylorder,len(phylorder)-1))#">)
					<cfelseif left(phylorder,2) is "!$">
						AND soundex(flat.phylorder) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylorder,len(phylorder)-2))#">)
					<cfelseif left(phylorder,1) is "!">
						AND upper(flat.phylorder) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylorder,len(phylorder)-1))#">
					<cfelseif phylorder is "NULL">
						AND upper(flat.phylorder) is null
					<cfelseif phylorder is "NOT NULL">
						AND upper(flat.phylorder) is not null
					<cfelse>
						<cfif find(',',phylorder) GT 0>
							AND upper(flat.phylorder) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(phylorder)#" list="yes"> )
						<cfelse>
							AND upper(flat.phylorder) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(phylorder)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("family") AND len(family) GT 0>
					<cfif left(family,1) is "=">
						AND upper(flat.family) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(family,len(family)-1))#">
					<cfelseif left(family,1) is "$">
						AND soundex(flat.family) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(family,len(family)-1))#">)
					<cfelseif left(family,2) is "!$">
						AND soundex(flat.family) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(family,len(family)-2))#">)
					<cfelseif left(family,1) is "!">
						AND upper(flat.family) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(family,len(family)-1))#">
					<cfelseif family is "NULL">
						AND upper(flat.family) is null
					<cfelseif family is "NOT NULL">
						AND upper(flat.family) is not null
					<cfelse>
						<cfif find(',',family) GT 0>
							AND upper(flat.family) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(family)#" list="yes"> )
						<cfelse>
							AND upper(flat.family) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(family)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("author_text") AND len(author_text) GT 0>
					<cfif left(author_text,1) is "=">
						AND upper(flat.author_text) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(author_text,len(author_text)-1))#">
					<cfelseif left(author_text,1) is "$">
						AND soundex(flat.author_text) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(author_text,len(author_text)-1))#">)
					<cfelseif left(author_text,2) is "!$">
						AND soundex(flat.author_text) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(author_text,len(author_text)-2))#">)
					<cfelseif left(author_text,1) is "!">
						AND upper(flat.author_text) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(author_text,len(author_text)-1))#">
					<cfelseif author_text is "NULL">
						AND upper(flat.author_text) is null
					<cfelseif author_text is "NOT NULL">
						AND upper(flat.author_text) is not null
					<cfelse>
						<cfif find(',',author_text) GT 0>
							AND upper(flat.author_text) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(author_text)#" list="yes"> )
						<cfelse>
							AND upper(flat.author_text) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(author_text)#%">
						</cfif>
					</cfif>
				</cfif>
			ORDER BY
				taxonomy.family, taxonomy.genus, decode(taxonomy.subspecies, null, taxonomy.species, taxonomy.subspecies)
		</cfquery>

		<cfset rows = 0>
		<cfset data = ArrayNew(1)>

		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfif lcase(col) EQ 'bits'>
					<cfset bitsarr = ListToArray(search[col][currentRow],"|",true)>
					<cfset row["typename"] = "#bitsarr[1]#">
					<cfset row["typeauthorship"] = "#bitsarr[2]#">
					<cfif len(showplaceholders) EQ 0 AND trim(bitsarr[3]) EQ 'Author not listed'>
						<cfset row["pubauthorship"] = "">
					<cfelse>
						<cfset row["pubauthorship"] = "#bitsarr[3]#">
					</cfif>
					<cfif len(showplaceholders) EQ 0 AND find('Citations Placeholder',bitsarr[4]) GT 0> 
						<cfset row["citation"] = "">
					<cfelse>
						<cfset row["citation"] = "#canonicalize(bitsarr[4],false,false)#">
					</cfif>
					<cfset row["page_number"] = "#bitsarr[5]#">
					<cfset row["citation_page_uri"] = "#bitsarr[6]#">
					<cfset row["publication_id"] = "#bitsarr[7]#">
				<cfelse>
					<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
				</cfif>
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getPartNameAutocompleteMeta.  Search for specimen_part.part_name values, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and minimal details for the selected value.

@param term information to search for.
@return a json structure containing id and value, with guid in value and collection_object_id in id, and guid with more data in meta.
--->
<cffunction name="getPartNameAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				count(f.collection_object_id) ct,
				specimen_part.part_name
			FROM
				#session.flatTableName# f
				left join specimen_part on f.collection_object_id = specimen_part.DERIVED_FROM_CAT_ITEM
			WHERE
				f.collection_object_id IS NOT NULL
				AND specimen_part.part_name like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
			GROUP BY
				specimen_part.part_name
			ORDER BY
				specimen_part.part_name
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.part_name#">
			<cfset row["value"] = "#search.part_name#" >
			<cfset row["meta"] = "#search.part_name# (#search.ct#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getPreserveMethodAutocompleteMeta.  Search for specimen_part.part_name values, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and minimal details for the selected value.

@param term information to search for.
@return a json structure containing id and value, with guid in value and collection_object_id in id, and guid with more data in meta.
--->
<cffunction name="getPreserveMethodAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				count(f.collection_object_id) ct,
				specimen_part.preserve_method
			FROM
				#session.flatTableName# f
				left join specimen_part on f.collection_object_id = specimen_part.DERIVED_FROM_CAT_ITEM
			WHERE
				f.collection_object_id IS NOT NULL
				AND specimen_part.preserve_method like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
			GROUP BY
				specimen_part.preserve_method
			ORDER BY
				specimen_part.preserve_method
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.preserve_method#">
			<cfset row["value"] = "#search.preserve_method#" >
			<cfset row["meta"] = "#search.preserve_method# (#search.ct#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getSpecResColsAutocomplete.  Search for distinct values of fields in cf_spec_res_cols_r with a 
  case insensitive substring match, returning json suitable for jquery-ui autocomplete.

@param term the field value to search for.
@param field the field in which to search for the value.
@return a json structure containing id and value, with matched term in value and id and count in meta.
--->
<cffunction name="getSpecResColsAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<!--- perform wildcard search anywhere in provided search term --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				count(*) as ct,
				<cfif field EQ "category">
					category as fld
				<cfelseif field EQ "sql_element">
					sql_element as fld
				<cfelseif field EQ "label">
					label as fld
				<cfelseif field EQ "column_name">
					column_name as fld
				<cfelseif field EQ "data_type">
					data_type as fld
				<cfelseif field EQ "hidden">
					hidden as fld
				<cfelseif field EQ "access_role">
					access_role as fld
				</cfif>
			FROM 
				cf_spec_res_cols_r
			WHERE
				<cfif field EQ "category">
					upper(category)
				<cfelseif field EQ "sql_element">
					upper(sql_element)
				<cfelseif field EQ "label">
					upper(label)
				<cfelseif field EQ "column_name">
					upper(column_name)
				<cfelseif field EQ "data_type">
					upper(data_type)
				<cfelseif field EQ "hidden">
					upper(hidden)
				<cfelseif field EQ "access_role">
					upper(access_role)
				</cfif>
				like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
			GROUP BY
				<cfif field EQ "category">
					category
				<cfelseif field EQ "sql_element">
					sql_element 
				<cfelseif field EQ "label">
					label
				<cfelseif field EQ "column_name">
					column_name
				<cfelseif field EQ "data_type">
					data_type
				<cfelseif field EQ "hidden">
					hidden
				<cfelseif field EQ "access_role">
					access_role
				</cfif>
			ORDER BY 
				<cfif field EQ "category">
					category
				<cfelseif field EQ "sql_element">
					sql_element 
				<cfelseif field EQ "label">
					label
				<cfelseif field EQ "column_name">
					column_name
				<cfelseif field EQ "data_type">
					data_type
				<cfelseif field EQ "hidden">
					hidden
				<cfelseif field EQ "access_role">
					access_role
				</cfif>
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.fld#">
			<cfset row["value"] = "#search.fld#" >
			<cfset row["meta"] = "#search.ct#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>
<!---
Function getSpecSearchColsAutocomplete.  Search for distinct values of fields in cf_spec_search_cols with a 
  case insensitive substring match, returning json suitable for jquery-ui autocomplete.

@param term the field value to search for.
@param field the field in which to search for the value.
@return a json structure containing id and value, with matched term in value and id and count in meta.
--->
<cffunction name="getSpecSearchColsAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<!--- perform wildcard search anywhere in provided search term --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				count(*) as ct,
				<cfif field EQ "search_category">
					search_category as fld
				<cfelseif field EQ "table_name">
					table_name as fld
				<cfelseif field EQ "table_alias">
					table_alias as fld
				<cfelseif field EQ "label">
					label as fld
				<cfelseif field EQ "column_name">
					column_name as fld
				<cfelseif field EQ "column_alias">
					column_alias as fld
				<cfelseif field EQ "data_type">
					data_type as fld
				<cfelseif field EQ "access_role">
					access_role as fld
				<cfelseif field EQ "label">
					label as fld
				<cfelseif field EQ "ui_function">
					ui_function as fld
				</cfif>
			FROM 
				cf_spec_search_cols
			WHERE
				<cfif field EQ "search_category">
					upper(search_category)
				<cfelseif field EQ "table_name">
					upper(table_name)
				<cfelseif field EQ "table_alias">
					upper(table_alias)
				<cfelseif field EQ "label">
					upper(label)
				<cfelseif field EQ "column_name">
					upper(column_name)
				<cfelseif field EQ "column_alias">
					upper(column_alias)
				<cfelseif field EQ "data_type">
					upper(data_type)
				<cfelseif field EQ "access_role">
					upper(access_role)
				<cfelseif field EQ "label">
					upper(label)
				<cfelseif field EQ "ui_function">
					upper(ui_function)
				</cfif>
				like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
			GROUP BY
				<cfif field EQ "search_category">
					search_category
				<cfelseif field EQ "table_name">
					table_name 
				<cfelseif field EQ "table_alias">
					table_alias 
				<cfelseif field EQ "label">
					label
				<cfelseif field EQ "column_name">
					column_name
				<cfelseif field EQ "column_alias">
					column_alias
				<cfelseif field EQ "data_type">
					data_type
				<cfelseif field EQ "access_role">
					access_role
				<cfelseif field EQ "label">
					label 
				<cfelseif field EQ "ui_function">
					ui_function 
				</cfif>
			ORDER BY 
				<cfif field EQ "search_category">
					search_category
				<cfelseif field EQ "table_name">
					table_name 
				<cfelseif field EQ "table_alias">
					table_alias 
				<cfelseif field EQ "label">
					label
				<cfelseif field EQ "column_name">
					column_name
				<cfelseif field EQ "column_alias">
					column_alias
				<cfelseif field EQ "data_type">
					data_type
				<cfelseif field EQ "access_role">
					access_role
				<cfelseif field EQ "label">
					label 
				<cfelseif field EQ "ui_function">
					ui_function 
				</cfif>
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.fld#">
			<cfset row["value"] = "#search.fld#" >
			<cfset row["meta"] = "#search.ct#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
