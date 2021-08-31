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
			wherebit = wherebit & comma & '{"join":"and","field": "' & prefixFieldname &'","comparator": "=","value": "#prefix#"}';
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
		result = '{"join":"' & leadingJoin & '","field": "' & fieldname &'","comparator": "=","value": "#encodeForJavaScript(listOfNumbers)#"}';
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
			// TODO: Implement nesting one level deeper
			result = '{"join":"' & leadingJoin & '","field": "' & fieldname &'","comparator": ">=","value": "#encodeForJavaScript(lowPart)#"';
			result = result & '},{"join":"and","field": "' & fieldname &'","comparator": "<=","value": "#encodeForJavaScript(highPart)#"}';
		} else if (ArrayLen(REMatch("^[0-9,]+$",listOfNumbers))>0) {
			// Just a list of numbers without ranges, translates directly to IN
			if (listOfNumbers!=",") {
				result = '{"join":"and","field": "' & fieldname &'","comparator": "IN","value": "#encodeForJavaScript(listOfNumbers)#"}';
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

<!---   Function getSpecimens backing method for specimen search --->
<cffunction name="getSpecimens" access="remote" returntype="any" returnformat="json">
	<cfargument name="searchText" type="string" required="no">
	<cfargument name="collmultiselect" type="string" required="no">

	<cftry>
		<!---change this to create a table of collection_object_ids, then a query to get preferred columns for user using the coll object table--->

		<cfif isDefined("searchText") and len(searchText) gt 0>
			<cfquery name="attrFields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="attrFields_result">
				SELECT column_name, sql_element 
				FROM cf_spec_res_cols
				WHERE category = 'attribute'
			</cfquery>
			<cfquery name="flatFields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="flatFields_result">
				SELECT column_name, data_type 
				FROM all_tab_columns
				WHERE table_name = <cfif ucase(#session.flatTableName#) EQ 'FLAT'>'FLAT'<cfelse>'FILTERED_FLAT'</cfif>
					and upper(column_name) not in (
						SELECT column_name 
						FROM cf_spec_res_cols
						WHERE category = 'attribute'
					)
			</cfquery>
			<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
				SELECT
					<cfset comma = "">
					<cfloop query="flatFields">
						#comma#flatTableName.#column_name#
						<cfset comma = ",">
					</cfloop>
					<cfloop query="attrFields">
						,#sql_element# as #column_name#
					</cfloop>
				FROM <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> F
					left join FLAT_TEXT FT ON f.COLLECTION_OBJECT_ID = FT.COLLECTION_OBJECT_ID
				WHERE contains(ft.cat_num, <cfqueryparam value="#searchText#" CFSQLType="CF_SQL_VARCHAR">, 1) > 0
					<cfif isDefined("collmultiselect") and len(collmultiselect) gt 0>
						and f.collection_id in (<cfqueryparam value="#collmultiselect#" cfsqltype="cf_sql_integer" list="true">)
					</cfif>
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
		</cfif>
		<cfset search_json = '#search_json##separator#{#join##field#,#comparator#,"value": "#value#"}'>
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

	<cfquery name="fields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="fields_result">
		SELECT search_category, table_name, column_name, column_alias, data_type, label
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
			<cfloop query="fields">
				<cfset tableField = "#fields.table_name#:#fields.column_name#">
				<cfif fieldProvided EQ tableField AND len(searchText) GT 0>
					<cfset matched = true>
					<cfset field = '"field": "#fields.column_alias#"'>
					<!--- Warning: only searchText may be passed directly from the user here, join and field must be known good values ---> 
					<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#searchText#",separator="#separator#")>
					<cfset separator = ",">
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
		<cfquery name="attrFields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="attrFields_result">
			SELECT column_name, sql_element 
			FROM cf_spec_res_cols
			WHERE category = 'attribute'
		</cfquery>
		<cfquery name="flatFields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="flatFields_result">
			SELECT column_name, data_type 
			FROM all_tab_columns
			WHERE table_name = <cfif ucase(#session.flatTableName#) EQ 'FLAT'>'FLAT'<cfelse>'FILTERED_FLAT'</cfif>
				and upper(column_name) not in (
					SELECT column_name 
					FROM cf_spec_res_cols
					WHERE category = 'attribute'
				)
		</cfquery>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				<cfset comma = "">
				<cfloop query="flatFields">
					#comma#flatTableName.#column_name#
					<cfset comma = ",">
				</cfloop>
				<cfloop query="attrFields">
					,#replace(sql_element,"''","'","all")# #column_name#
				</cfloop>
			FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
				left join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
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
	<cfargument name="other_id_number" type="string" required="no">
	<cfargument name="full_taxon_name" type="string" required="no">
	<cfargument name="genus" type="string" required="no">
	<cfargument name="family" type="string" required="no">
	<cfargument name="phylorder" type="string" required="no">
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
	<cfargument name="loan_number" type="string" required="no">
	<cfargument name="accession_number" type="string" required="no">
	<cfargument name="deaccession_number" type="string" required="no">
	<cfargument name="debug" type="string" required="no">

	<cfset search_json = "[">
	<cfset separator = "">
	<cfset join = ''>

	<cfif isDefined("collection") AND len(collection) GT 0>
		<cfset field = '"field": "collection_cde"'>
		<cfset comparator = '"comparator": "IN"'>
		<cfset value = encodeForJavaScript(collection)>
		<cfset search_json = '#search_json##separator#{#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
	</cfif>
	<cfif isDefined("cat_num") AND len(cat_num) GT 0>
		<cfset nestDepth = "">
		<cfset clause = ScriptPrefixedNumberListToJSON(cat_num, "CAT_NUM_INTEGER", "CAT_NUM_PREFIX", true, nestDepth, "and")>
		<!--- cfset clause = ScriptNumberListToJSON(cat_num, "cat_num", "", "and") --->
		<cfset search_json = "#search_json##separator##clause#">
		<cfset separator = ",">
		<cfset join='"join":"and",'>
	</cfif>
	<cfif isDefined("other_id_number") AND len(other_id_number) GT 0>
		<cfif left(value,1) is "=" OR left(value,1) is "!">
			<cfset field = '"field": "other_id_number"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#other_id_number#",separator="#separator#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
		<cfelse>
			<cfset nestDepth = "">
			<cfset clause = ScriptPrefixedNumberListToJSON(other_id_number, "OTHER_ID_NUMBER", "OTHER_ID_PREFIX", false, nestDepth, "and")>
			<cfset search_json = "#search_json##separator##clause#">
			<cfset separator = ",">
			<cfset join='"join":"and",'>
		</cfif>
	</cfif>
	<cfif isDefined("other_id_type") AND len(other_id_type) GT 0>
		<cfset field = '"field": "other_id_type"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#other_id_type#",separator="#separator#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
	</cfif>
	<cfif isDefined("taxon_name_id") AND len(taxon_name_id) GT 0>
		<cfset field = '"field": "taxon_name_id"'>
		<cfset comparator = '"comparator": "="'>
		<cfset value = encodeForJavaScript(taxon_name_id)>
		<cfset search_json = '#search_json##separator#{#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
	<cfelse>
		<cfif isDefined("scientific_name") AND len(scientific_name) GT 0>
			<cfset field = '"field": "scientific_name"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#scientific_name#",separator="#separator#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
		</cfif>
		<cfif isDefined("full_taxon_name") AND len(full_taxon_name) GT 0>
			<cfset field = '"field": "full_taxon_name"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#full_taxon_name#",separator="#separator#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
		</cfif>
		<cfif isDefined("author_text") AND len(author_text) GT 0>
			<cfset field = '"field": "author_text"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#author_text#",separator="#separator#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
		</cfif>
		<cfif isDefined("genus") AND len(genus) GT 0>
			<cfset field = '"field": "genus"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#genus#",separator="#separator#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
		</cfif>
		<cfif isDefined("family") AND len(family) GT 0>
			<cfset field = '"field": "family"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#family#",separator="#separator#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
		</cfif>
		<cfif isDefined("phylorder") AND len(phylorder) GT 0>
			<cfset field = '"field": "phylorder"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#phylorder#",separator="#separator#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
		</cfif>
	</cfif>
	
	<cfif isDefined("higher_geog") AND len(higher_geog) GT 0>
		<cfset field = '"field": "higher_geog"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#higher_geog#",separator="#separator#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
	</cfif>
	<cfif isDefined("country") AND len(country) GT 0>
		<cfset field = '"field": "country"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#country#",separator="#separator#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
	</cfif>
	<cfif isDefined("state_prov") AND len(state_prov) GT 0>
		<cfset field = '"field": "state_prov"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#state_prov#",separator="#separator#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
	</cfif>
	<cfif isDefined("county") AND len(county) GT 0>
		<cfset field = '"field": "county"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#county#",separator="#separator#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
	</cfif>
	<cfif isDefined("island_group") AND len(island) GT 0>
		<cfset field = '"field": "island_group"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#island_group#",separator="#separator#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
	</cfif>
	<cfif isDefined("island") AND len(island) GT 0>
		<cfset field = '"field": "island"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#island#",separator="#separator#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
	</cfif>
	<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
		<cfif isDefined("loan_number") AND len(loan_number) GT 0>
			<cfset field = '"field": "loan_number"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#loan_number#",separator="#separator#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
		</cfif>
		<cfif isDefined("accn_number") AND len(accn_number) GT 0>
			<cfset field = '"field": "accn_number"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#accn_number#",separator="#separator#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
		</cfif>
		<cfif isDefined("deaccession_number") AND len(deaccession_number) GT 0>
			<cfset field = '"field": "deaccession_number"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#deaccession_number#",separator="#separator#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
		</cfif>
	</cfif>

	<cfif isDefined("collector_agent_id") AND len(collector_agent_id) GT 0>
		<cfset field = '"field": "collector_agent_id"'>
		<cfset comparator = '"comparator": "="'>
		<cfset value = encodeForJavaScript(collector_agent_id)>
		<cfset search_json = '#search_json##separator#{#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
	<cfelse>
		<cfif isDefined("collector") AND len(collector) GT 0>
			<cfset field = '"field": "collector"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#collector#",separator="#separator#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
		</cfif>
	</cfif>

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
		<!--- errors are handled by build_query_dbms_sql throwing exceptions --->
		<cfstoredproc procedure="build_query_dbms_sql" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="prepareSearch_result">
			<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
			<cfprocparam cfsqltype="CF_SQL_CLOB" value="#search_json#">
			<cfprocresult name="search">
		</cfstoredproc>
		<cfquery name="attrFields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="attrFields_result">
			SELECT column_name, sql_element 
			FROM cf_spec_res_cols
			WHERE category = 'attribute'
		</cfquery>
		<cfquery name="flatFields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="flatFields_result">
			SELECT column_name, data_type 
			FROM all_tab_columns
			WHERE table_name = <cfif ucase(#session.flatTableName#) EQ 'FLAT'>'FLAT'<cfelse>'FILTERED_FLAT'</cfif>
				and upper(column_name) not in (
					SELECT column_name 
					FROM cf_spec_res_cols
					WHERE category = 'attribute'
				)
		</cfquery>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				<cfset comma = "">
				<cfloop query="flatFields">
					#comma#flatTableName.#column_name#
					<cfset comma = ",">
				</cfloop>
				<cfloop query="attrFields">
					,#replace(sql_element,"''","'","all")# #column_name#
				</cfloop>
			FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
				left join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
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
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">â€œFeedback/Report Errorsâ€�</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
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
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">â€œFeedback/Report Errorsâ€�</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
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
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">â€œFeedback/Report Errorsâ€�</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
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

</cfcomponent>
