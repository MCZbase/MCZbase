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
<cfinclude template="/shared/component/functions.cfc" runOnce="true">

<cfset DOWNLOAD_THRESHOLD = 1001>

<!---
 ** Given a string that may be a search term for a date or a date range, reformat it to 
 *  fit the expectations of a date search, e.g. change "2020" to "2020-01-01/2020-12-31"
 *  handles yyyy-mm-dd, yyyy-mm, yyyy, yyyy, yyyy-mm-dd/yyyy-mm-dd, yyyy/yyyy, yyyy-mm-dd/yyyy
 *    yyyy/yyyy-mm-dd, yyyy-mm/yyyy-mm, yyyy-mm/yyyy-mm, yyyy-mm-dd/yyyy-mm, yyyy-mm/yyyy-mm-dd
 * 
 * @param searchText the string to convert, if possible
 * @return searchText, expanded if possible, or any empty string if an exception occurs.
 *
--->
<cffunction name="reformatDateSearchTerm" access="remote" returntype="any" returnformat="json">
	<cfargument name="searchText" type="string" required="yes">

	<cfset result = "">
	<cfif len(trim(searchText)) GT 0>
		<cftry>
			<cfif refind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",searchText) EQ 1>
				<!--- yyyy-mm-dd --->
				<cfset searchText = "=#searchText#" >
			<cfelseif refind("^>[0-9]{4}-[0-9]{2}-[0-9]{2}$",searchText) EQ 1>
				<cfif 1 EQ 0><!--- fix syntax highlighting ---></cfif>
				<!--- LT yyyy-mm-dd --->
				<cfset searchText = "=#searchText#" >
			<cfelseif refind("^<[0-9]{4}-[0-9]{2}-[0-9]{2}$",searchText) EQ 1>
				<!--- GT yyyy-mm-dd --->
				<cfset searchText = "=#searchText#" >
			<cfelseif refind("^[0-9]{4}-[0-9]{2}-[0-9]{2}/[0-9]{4}-[0-9]{2}-[0-9]{2}$",searchText) EQ 1>
				<!--- yyyy-mm-dd/yyyy-mm-dd --->
				<cfset searchText = "=#searchText#" >
			<cfelseif refind("^[0-9]{4}$",searchText) EQ 1>
				<!--- yyyy --->
				<cfset searchText = "=#searchText#-01-01/#searchText#-12-31" >
			<cfelseif refind("^[0-9]{4}/[0-9]{4}$",searchText) EQ 1>
				<!--- yyyy/yyyy --->
				<cfset yearbits = ListToArray(searchText,'/')>
				<cfset searchText = "=#yearbits[1]#-01-01/#yearbits[2]#-12-31" >
			<cfelseif refind("^[0-9]{4}-[0-9]{2}-0-9{2}/[0-9]{4}$",searchText) EQ 1>
				<!--- yyyy-mm-dd/yyyy --->
				<cfset yearbits = ListToArray(searchText,'/')>
				<cfset searchText = "=#yearbits[1]#/#yearbits[2]#-12-31" >
			<cfelseif refind("^[0-9]{4}/[0-9]{4}-[0-9]{2}-[0-9]{2}$",searchText) EQ 1>
				<!--- yyyy/yyyy-mm-dd --->
				<cfset yearbits = ListToArray(searchText,'/')>
				<cfset searchText = "=#yearbits[1]#-01-01/#yearbits[2]#" >
			<cfelseif refind("^[0-9]{4}-[0-9]{2}/[0-9]{4}-[0-9]{2}-[0-9]{2}$",searchText) EQ 1>
				<!--- yyyy-mm/yyyy-mm-dd --->
				<cfset datebits = ListToArray(searchText,'/')>
				<cfset searchText = "=#datebits[1]#-01/#datebits[2]#" >
			<cfelse>
				<!--- cases where we need to know last day of month to expand --->
				<cfset isoformatter = createObject("java","java.text.SimpleDateFormat")>
				<cfset isoformatter.init("yyyy-MM-dd")>

				<cfif refind("^[0-9]{4}-[0-9]{2}$",searchText) EQ 1>
					<!--- yyyy-mm --->
					<cfset endDay = DaysInMonth(isoformatter.parse("#searchText#-01"))>
					<cfset searchText = "=#searchText#-01/#searchText#-#endDay#" >
				<cfelseif refind("^[0-9]{4}-[0-9]{2}/[0-9]{4}-[0-9]{2}$",searchText) EQ 1>
					<!--- yyyy-mm/yyyy-mm --->
					<cfset datebits = ListToArray(searchText,'/')>
					<cfset endDay2 = DaysInMonth(isoformatter.parse("#datebits[2]#-01"))>
					<cfset searchText = "=#datebits[1]#-01/#datebits[2]#-#endDay2#" >
				<cfelseif refind("^[0-9]{4}-[0-9]{2}-[0-9]{2}/[0-9]{4}-[0-9]{2}$",searchText) EQ 1>
					<!--- yyyy-mm-dd/yyyy-mm --->
					<cfset datebits = ListToArray(searchText,'/')>
					<cfset endDay2 = DaysInMonth(isoformatter.parse("#datebits[2]#-01"))>
					<cfset searchText = "=#datebits[1]#/#datebits[2]#-#endDay2#" >
				</cfif>
			</cfif>
			<cfset result = searchText>
		<cfcatch>
			<!--- consume the exception --->
		</cfcatch>
		</cftry>
	</cfif>
	<cfreturn result>
</cffunction>

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
	if (prefixFieldName EQ "CAT_NUM_PREFIX") { 
		baseFieldName = "CAT_NUM";
		displayFieldName = "CAT_NUM";
		suffixFieldName = "CAT_NUM_SUFFIX";
 	} else { 
		suffixFieldName = "OTHER_ID_SUFFIX";
		baseFieldName = "OTHER_ID_NUMBER";
		displayFieldName = "DISPLAY_VALUE";
	}

	// Prepare list for parsing
	listOfNumbers = trim(listOfNumbers);
	// Change ", " to "," and then " " to "," to allow space and comma separators
	listOfNumbers = REReplace(listOfNumbers, ", ", ",","all");	// comma space to comma
	listOfNumbers = REReplace(listOfNumbers, " ", ",","all");	// space to comma
	listOfNumbers = REReplace(listOfNumbers, "\*", "%","all");	// dos to sql wildcard
	// strip out any other characters
	listOfNumbers = REReplace(listOfNumbers, '[^0-9A-Za-z%,:"\-<>]',"","all");
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

	// find prefixes and suffixes in atoms
	if (REFind("^[0-9,]+$",listOfNumbers)>0) {
		// list consists of only number or comma separated numbers, no ranges or prefixes, skip splitting into atoms
		numericClause = ScriptNumberListToJSON(listOfNumbers, integerFieldname, nestDepth, leadingJoin);
		wherebit = numericClause;
	} else { 
		numericClause = "";
		wherebit = "";
		comma = "";
		leadingJoin = "and";
		for (i=1; i LTE ArrayLen(lparts); i=i+1) {
			prefix = "";
			numeric= "";
			suffix = "";
			// "A96-5"// single number with prefix and multiple numeric parts
			// "A96-%"// single number with prefix and wildcard match
			// A      // just prefix
			// 1      // just number
			// 1-2    // numeric range 1 to 2
			// A-1    // prefix
			// 1-a    // suffix
			// A1-5   // prefix with range (A-1 to A-4)
			// A-1-5  // prefix with range (A-1 to A-4)
			// A-1-a  // prefix and suffix
			// 1-a-5  // suffix with range (1-a to 5-a)
			// A-1-A-5  // prefix with range alternative (A-1 to A-5)
			// 1-a-5-a  // suffix with range alternative (1-a to 5-a)
			// A-1-5-a // prefix and suffix with range alternative  (A-1-a to A-5-a)
			mayBeQuoted = lparts[i];
			// stricter tolerance for other characters than used in value clause below, do not include " and : when constructing atomParts
			partFromList = REReplace(lparts[i], '[^0-9A-Za-z%\-<>]',"","all");
			atomParts = ListToArray(partFromList,"-",false);
			partCount = ArrayLen(atomParts);
			if (REFind('^".+"$',mayBeQuoted) GT 0) { 
				// atom is quoted, search displayFieldName
				comparator = '"comparator": "="';
				value = right(mayBeQuoted,len(mayBeQuoted)-1);
				value = left(value,len(value)-1);
				if (left(value,1) IS "!") {
					value = ucase(right(value,len(value)-1));
					comparator = '"comparator": "not like"';
				} else if (value CONTAINS "%" OR value CONTAINS "_") { 
					comparator = '"comparator": "like"';
				}
				wherebit = wherebit & comma & '{"nest":"#nestDepth#","join":"' & leadingJoin & '","field": "' & displayFieldName &'",'& comparator & ',"value": "#value#"}';
				comma = ",";
			} else if (partCount EQ 1 and REFind("^[A-Za-z]+$",atomParts[1])) { 
				// just a prefix.
				prefix = atomParts[1];
			} else if (partCount EQ 1 and REFind("^[0-9]+$",atomParts[1])) { 
				// just a number
				numeric = atomParts[1];
			} else if (partCount EQ 1 and REFind("^>[0-9]+$",atomParts[1])) { 
				value = right(mayBeQuoted,len(mayBeQuoted)-1);
				comparator = '"comparator": ">"';
				wherebit = wherebit & comma & '{"nest":"#nestDepth#","join":"' & leadingJoin & '","field": "' & integerFieldName &'",'& comparator & ',"value": "#value#"}';
			} else if (partCount EQ 1 and REFind("^<[0-9]+$",atomParts[1])) { 
				value = right(mayBeQuoted,len(mayBeQuoted)-1);
				comparator = '"comparator": "<"';
				wherebit = wherebit & comma & '{"nest":"#nestDepth#","join":"' & leadingJoin & '","field": "' & integerFieldName &'",'& comparator & ',"value": "#value#"}';
			} else if (partCount EQ 1 and REFind("^[0-9]+[A-Za-z]+$",atomParts[1])) { 
				// number and suffix
				numeric = rereplace(atomParts[1],"[^0-9]]","","all");
				suffix = rereplace(atomParts[1],"[^A-Za-z]","","all");
			} else if (partCount EQ 1 OR partCount GT 4) { 
				// unexpected, and likely failure case, but try something
				wherebit = wherebit & comma & '{"nest":"#nestDepth#","join":"and","field": "' & displayFieldName &'","comparator": "=","value": "#partFromList#"}';
				comma = ",";
			} else if (partCount EQ 2) { 
				if (REFind("^[0-9]+$",atomParts[1]) AND REFind("^[0-9]+$",atomParts[2])) { 
					// 1-2 numeric range
					numeric = partFromList;
				} else if (REFind("^[A-Za-z]+[0-9]+$",atomParts[1]) AND REFind("^[0-9]+$",atomParts[2])) { 
					// A1-5   // prefix with range (A-1 to A-4)
					startNumBit = rereplace(atomParts[1],"[^0-9]]","","all");
					prefix = rereplace(atomParts[1],"[^A-Za-z]","","all");
					numeric = startNumBit & "-" & atomParts[2];
				} else if (REFind("^[0-9]+$",atomParts[1])) { 
					// 1-a    // suffix
					numeric = atomParts[1];
					suffix = atomParts[2];
				} else {
					// A-1    // prefix
					numeric = atomParts[2];
					prefix = atomParts[1];
				}
			} else if (partCount EQ 3) { 
				if (REFind("[A-Za-z]",atomParts[1]) AND REFind("^[0-9]+$",atomParts[2]) AND REFind("^[0-9]+$",atomParts[3])) { 
					// A-1-5  // prefix with range (A-1 to A-4)
					prefix = atomParts[1];
					numeric = atomParts[2] & "-" & atomParts[3];
				} else if (REFind("[A-Za-z-]",atomParts[1]) AND REFind("^[0-9]+$",atomParts[2]) AND REFind("[A-Za-z]",atomParts[3])) { 
					// A-1-a  // prefix and suffix
					prefix = atomParts[1];
					numeric = atomParts[2];
					suffix = atomParts[3];
				} else { 
					// 1-a-5  // suffix with range (1-a to 5-a)
					numeric = atomParts[1] & "-" & atomParts[3];
					suffix = atomParts[2];
				}
			} else if (partCount EQ 4) { 
				if (REFind("[A-Za-z]",atomparts[1]) AND REFind("^[0-9]+$",atomParts[2]) AND REFind("[A-Za-z]",atomParts[3]) AND REFind("^[0-9]+$",atomParts[4])) { 
					// A-1-A-5  // prefix with range alternative (A-1 to A-5)
					if (atomParts[1] EQ atomParts[3]) { 
						prefix = atomParts[1];
					} else { 
						prefix = atomParts[1] & "," & atomParts[3];
					}
					numeric = atomParts[2] & "-" & atomParts[4];
				} else if (REFind("^[0-9]+$",atomParts[1]) AND REFind("[A-Za-z]",atomParts[2]) AND REFind("^[0-9]+$",atomParts[3]) AND REFind("[A-Za-z]",atomParts[4])) { 
					// 1-a-5-a  // suffix with range alternative (1-a to 5-a)
					if (atomParts[2] EQ atomParts[4]) { 
						suffix = atomParts[2];
					} else { 
						suffix = atomParts[2] & "," & atomParts[4];
					}
					numeric = atomParts[1] & "-" & atomParts[3];
				} else { 
					// A-1-5-a // prefix and suffix with range alternative  (A-1-a to A-5-a)
					prefix = atomParts[1];
					numeric = atomParts[2] & "-" & atomParts[3];
					suffix = atomParts[4];
				}
			}
			if (Len(numeric) GT 0) { 
				wherebit = wherebit & comma & ScriptNumberListToJSON(numeric, integerFieldname, nestDepth, leadingJoin);
				comma = ",";
				leadingJoin = "and";
			}
			if (Len(prefix) GT 0) { 
				if (embeddedSeparator EQ true) {
					// If the prefix isn't blank and doesn't end with the separator, add it.
					if ((prefix NEQ "") AND (Find("-",prefix) EQ 0)) {
						prefix = prefix & "-";
					}
				} else {
					//remove any trailing dash
					prefix = REReplace(prefix,"\-$","");
				}
				wherebit = wherebit & comma & '{"nest":"#nestDepth#","join":"and","field": "' & prefixFieldName &'","comparator": "=","value": "#prefix#"}';
				comma = ",";
				leadingJoin = "and";
			}
			if (Len(suffix) GT 0) { 
				if (embeddedSeparator EQ true) {
					// If the suffix isn't blank and doesn't start with the separator, add it.
					if ((suffix NEQ "") AND (Find("-",suffix) EQ 0)) {
						suffix = "-" & suffix;
					}
				} else {
					//remove any trailing dash
					suffix = REReplace(suffix,"\-$","");
				}
				wherebit = wherebit & comma & '{"nest":"#nestDepth#","join":"and","field": "' & suffixFieldName &'","comparator": "=","value": "#suffix#"}';
				comma = ",";
				leadingJoin = "and";
			}
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
	// <!--- '{"join":"and","field": "cat_num","comparator": "IN","value": "#encodeForJSON(value)#"}'  --->

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
		result = '{"nest":"#nestDepth#","join":"' & leadingJoin & '","field": "' & fieldname &'","comparator": "=","value": "#encodeForJSON(listOfNumbers)#"}';
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
			result = '{"nest":"#nestDepth#.1","join":"' & leadingJoin & '","field": "' & fieldname &'","comparator": ">=","value": "#encodeForJSON(lowPart)#"';
			result = result & '},{"nest":"#nestDepth#.2","join":"and","field": "' & fieldname &'","comparator": "<=","value": "#encodeForJSON(highPart)#"}';
		} else if (ArrayLen(REMatch("^[0-9,]+$",listOfNumbers))>0) {
			// Just a list of numbers without ranges, translates directly to IN
			if (listOfNumbers!=",") {
				result = '{"nest":"#nestDepth#.1","join":"and","field": "' & fieldname &'","comparator": "IN","value": "#encodeForJSON(listOfNumbers)#"}';
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
					wherePart = ScriptNumberListPartToJSON(lparts[i], fieldname, nestDepth + "." + i, "or");
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
		result = '{"nest":"#nestDepth#.1","join":"' & leadingJoin & '","field": "' & fieldname &'","comparator": "=","value": "#encodeForJSON(atom)#"}';
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
			result = '{"nest":"#nestDepth#.1","join":"' & leadingJoin & '","field": "' & fieldname &'","comparator": ">=","value": "#encodeForJSON(lowPart)#"';
			result = result & '},{"nest":"#nestDepth#.2","join":"and","field": "' & fieldname &'","comparator": "<=","value": "#encodeForJSON(highPart)#"}';
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

	<cfargument name="debug" type="string" required="no">
	<cfargument name="recordstartindex" type="string" required="no">
	<cfargument name="recordendindex" type="string" required="no">
	<cfargument name="pagesize" type="string" required="no">
	<cfargument name="pagenum" type="string" required="no">
	<cfargument name="sortdatafield" type="string" required="no">
	<cfargument name="sortorder" type="string" required="no">
	<cfargument name="filterscount" type="string" required="no">
	<cfargument name="returnallrecords" type="string" required="no">

	<cfif NOT isdefined("pagesize")><cfset pagesize=0></cfif>
	<cfif NOT isdefined("sortdatafield")><cfset sortdatafield=""></cfif>
	<cfif NOT isdefined("sortorder")><cfset sortorder="asc"></cfif>
	<cfif NOT isdefined("returnallrecords")><cfset returnallrecords=""></cfif>
	<cfif returnallrecords EQ "true">
		<!--- turn off all server side filtering/paging --->
		<cfset pagesize=0>
		<cfset pagenum="">
		<cfset sortdatafield="">
		<cfset sortorder="asc">
		<cfset filterscount="0">
	</cfif>
	<cfif isDefined("recordstartindex")>
		<!--- the value of recordstartindex is off by one from the expectations of oracle where rownumber between recordstartindex and recordendindex, 
         which returns values between start and end inclusive.  --->
		<cfset recordstartindex = recordstartindex + 1>
	</cfif>

	<cfset search_json = "[">
	<cfset separator = "">
	<cfset join = ''>

	<cfset nest = 1>
	
	<cfif isDefined("collection_cde") AND len(collection_cde) GT 0>
		<cfset field = '"field": "collection_cde"'>
		<cfset comparator = '"comparator": "IN"'>
		<cfset value = encodeForJSON(collection_cde)>
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("searchText") AND len(searchText) GT 0>
		<cfset field = '"field": "keyword"'>
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
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#searchValueForJSON#"}'>
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
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
						OR access_role = 'MANAGE_SPECIMENS'
					</cfif>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"DATA_ENTRY")>
						OR access_role = 'DATA_ENTRY'
					</cfif>
				ORDER by category, disp_order
			</cfquery>
			<cfset sanitizedsortdatafield = "">
			<cfset sortdatafieldSQL = "">
			<cfif len(sortdatafield) GT 0>
				<cfloop query="getFieldMetadata">
					<cfif compareNoCase(getFieldMetadata.column_name,sortdatafield) EQ 0>
						<cfset sanitizedsortdatafield = "#getFieldMetadata.column_name#">
						<cfif len(getFieldMetadata.sql_element) EQ 0 >
							<cfset sortdatafieldSQL = "#getFieldMetadata.column_name#">
						<cfelse>
							<cfset sortdatafieldSQL = "#getFieldMetadata.sql_element#">
						</cfif>
					</cfif>
				</cfloop>
			</cfif>

			<cfquery name="result_id_count" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="result_id_count_result" timeout="#Application.short_timeout#">
				SELECT count(*) ct 
				FROM user_search_table 
				WHERE
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			</cfquery>
			<cfif result_id_count.ct EQ 0>
				<cfstoredproc procedure="build_query_dbms_sql" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="prepareSearch_result" timeout="#Application.query_timeout#">
					<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
					<cfprocparam cfsqltype="CF_SQL_CLOB" value="#search_json#">
					<cfprocresult name="buildsearch">
				</cfstoredproc>
			</cfif>
			<cfquery name="searchcount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="searchcount_result" timeout="#Application.short_timeout#">
				SELECT count(*) ct 
				FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
					join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
				WHERE
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			</cfquery>
			<cfset records = searchcount.ct>
			<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
				<cfif pagesize GT 0 >
					SELECT * FROM (
				</cfif>
					SELECT distinct 
						<cfset comma = "">
						<cfloop query="getFieldMetadata">
							<cfif len(sql_element) GT 0> 
								#comma##replace(sql_element,"''","'","all")# #column_name#
								<cfset comma = ",">
							</cfif>
						</cfloop>
						<cfif pagesize GT 0 >
							,
							row_number() OVER (
								<cfif lcase(sanitizedsortdatafield) EQ "guid">
									ORDER BY flatTableName.collection_cde <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
										to_number(regexp_substr(flatTableName.guid, '\d+')) <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
										flatTableName.guid <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
								<cfelseif len(sanitizedsortdatafield) GT 0>
									ORDER BY #sortdatafieldSQL# <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
								<cfelse>
									ORDER BY flatTableName.collection_cde asc, to_number(regexp_substr(flatTableName.guid, '\d+')) asc, flatTableName.guid asc
								</cfif>
							) rownumber
						</cfif>
					FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
						join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
					WHERE
						user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					<cfif lcase(sanitizedsortdatafield) EQ "guid">
						ORDER BY flatTableName.collection_cde <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
							to_number(regexp_substr(flatTableName.guid, '\d+')) <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
							flatTableName.guid <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
					<cfelseif len(sanitizedsortdatafield) GT 0>
						ORDER BY #sortdatafieldSQL# <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
					<cfelse>
						ORDER BY flatTableName.collection_cde asc, to_number(regexp_substr(flatTableName.guid, '\d+')) asc, flatTableName.guid asc
					</cfif>
				<cfif pagesize GT 0 >
					)
					WHERE rownumber between <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#recordstartindex#">
						and <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#recordendindex#">
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
			<cfset row["recordcount"] = "#records#">
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

<cffunction name="encodeForJSON">
	<cfargument name="value" type="string" required="yes">

	<cfset value = replace(value,'\','\\',"all")>
	<cfset value = replace(value,'"','\"',"all")>
	
	<cfreturn value>
</cffunction>

<cffunction name="constructJsonForField">
	<cfargument name="join" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="separator" type="string" required="yes">
	<cfargument name="nestDepth" type="string" required="yes">
	<cfargument name="dataType" type="string" required="no" default="not specified">

	<cfset search_json = "">
		<cfif left(value,2) is "=<">
			<cfset value="#ucase(right(value,len(value)-2))#">
			<cfset comparator = '"comparator": "<="'>
		<cfelseif left(value,2) is "=>"><!--- " --->
			<cfset value="#ucase(right(value,len(value)-2))#">
			<cfset comparator = '"comparator": ">="'><!--- " --->
		<cfelseif left(value,1) is "=">
			<cfset value="#ucase(right(value,len(value)-1))#">
			<cfset comparator = '"comparator": "="'>
		<cfelseif left(value,1) is "~">
			<cfset value="#ucase(right(value,len(value)-1))#">
			<cfset comparator = '"comparator": "JARO_WINKLER"'>
		<cfelseif left(value,2) is ">=">
			<cfset value="#ucase(right(value,len(value)-2))#">
			<cfset comparator = '"comparator": ">="'><!--- " --->
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
			<cfif REFind("([A-Za-z]+,[A-Za-z]+)+",value) GT 0>
				<cfset comparator = '"comparator": "IN"'>
			<cfelseif REFind("([0-9]+,[0-9]+)+",value) GT 0>
				<cfset comparator = '"comparator": "IN"'>
			<cfelse>
				<cfset comparator = '"comparator": "like"'>
			</cfif>
			<cfset value = replace(value,'\','\\',"all")>
			<cfset value = replace(value,'"','\"',"all")>
		</cfif>
		<!--- special case handling for keyword search, comparator must be empty --->
		<cfif CompareNoCase(dataType,"CTXKEYWORD") EQ 0 >
			<cfset comparator = '"comparator": ""'>
		</cfif>
		<cfset search_json = '#search_json##separator#{"nest":"#nestDepth#",#join##field#,#comparator#,"value": "#value#"}'>
	<cfreturn #search_json#>
</cffunction>

<!--- 
  ** given a value, return that value with " and \ escaped
  * as \" and \\ respectively suitable for inclusion in JSON
  * @param value the value to escape characters in 
  * @return value with " and \ characters escaped 
--->
<cffunction name="escapeQuotesForJSON">
	<cfargument name="value" type="string" required="yes">
	<!--- escape quotes for json construction --->
	<cfset replacement = value>
	<cfset replacement = replace(replacement,"\","\\","all")>
	<cfset replacement = replace(replacement,'"','\"',"all")>
	<cfreturn #replacement#>
</cffunction>

<!--- 
  ** given a comma separated list of strings return that list 
  * with the strings enclosed in single quotes.
--->
<cffunction name="valueToQuotedList">
	<cfargument name="value" type="string" required="yes">
	<cfset retval = []>
	<cfset itemArray = ListToArray(value,",") >
	<cfloop index="i" from="1" to="#ArrayLen(itemArray)#">
		<cfset arrayAppend(retval, "'" & escapeQuotesForJson(value="#itemArray[i]#") & "'")>
	</cfloop>	
	<cfreturn #ArrayToList(retval)#>
</cffunction>

<!--- Function executeBuilderSearch backing method for specimen search via the search builder
	@param result_id a uuid which identifies this search.
	@param debug if given a value, dump the json that would be sent to build_query instead of
	  running the query and returning a result.
--->
<cffunction name="executeBuilderSearch" access="remote" returntype="any" returnformat="json">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="builderMaxRows" type="string" required="yes">

	<cfargument name="debug" type="string" required="no">
	<cfargument name="recordstartindex" type="string" required="no">
	<cfargument name="recordendindex" type="string" required="no">
	<cfargument name="pagesize" type="string" required="no">
	<cfargument name="pagenum" type="string" required="no">
	<cfargument name="sortdatafield" type="string" required="no">
	<cfargument name="sortorder" type="string" required="no">
	<cfargument name="filterscount" type="string" required="no">
	<cfargument name="returnallrecords" type="string" required="no">

	<cfif NOT isdefined("pagesize")><cfset pagesize=0></cfif>
	<cfif NOT isdefined("sortdatafield")><cfset sortdatafield=""></cfif>
	<cfif NOT isdefined("sortorder")><cfset sortorder="asc"></cfif>
	<cfif NOT isdefined("returnallrecords")><cfset returnallrecords=""></cfif>
	<cfif returnallrecords EQ "true">
		<!--- turn off all server side filtering/paging --->
		<cfset pagesize=0>
		<cfset pagenum="">
		<cfset sortdatafield="">
		<cfset sortorder="asc">
		<cfset filterscount="0">
	</cfif>
	<cfif isDefined("recordstartindex")>
		<!--- the value of recordstartindex is off by one from the expectations of oracle where rownumber between recordstartindex and recordendindex, 
         which returns values between start and end inclusive.  --->
		<cfset recordstartindex = recordstartindex + 1>
	</cfif>

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
			<cfset nestdepth = Evaluate("nestdepth"&i)>
			<cfif joinWith EQ "AND">
				<cfset join='"join":"and",'>
			<cfelseif joinWith EQ "OR">
				<cfset join='"join":"or",'>
			<cfelse>
				<cfset join=''>
			</cfif>
			<cfset matched = false>
			<cfif len(nestdepth) GT 0>
				<cfset nest=nestdepth>
			<cfelse>
				<cfset nest = 1>
			</cfif>
			<!--- Handle the hidden searchId fields, if present --->
			<cfif isDefined("searchId") AND len(searchId) GT 0>
				<!--- if a searchId{n} value was provided, use it instead of searchText{n} to support autocomplete field pairs --->
				<cfif isDefined("searchText") AND left(searchText,1) EQ "!">
					<!--- carry forward of a ! operator in the text to cause comparator to be set to <> instead of LIKE --->
					<cfset searchText = "!#searchId#">
				<!---cfif isDefined("searchId") AND contains(searchId,",") GT 0>
					TODO: Add support for lists from multi-selects 
				--->
				<cfelse> 
					<!--- prepend an = to cause comparator to be set to = instead of LIKE for performance --->
					<cfset searchText = "=#searchId#">
				</cfif>
			</cfif>
			<cfloop query="searchFields">
				<cfset tableField = "#searchFields.table_name#:#searchFields.column_alias#">
				<cfif fieldProvided EQ tableField AND len(searchText) GT 0>
					<cfset matched = true>
					<cfset field = '"field": "#searchFields.column_alias#"'>
					<cfif searchFields.data_type IS 'DATE'>
						<cfset searchText = reformatDateSearchTerm(searchText="#searchText#") >
						<!---
						<cfset isoformatter = createObject("java","java.text.SimpleDateFormat")>
						<cfset isoformatter.init("yyyy-MM-dd")>
						<cfif refind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",searchText) EQ 1>
							<cfset searchText = "=#searchText#" >
						</cfif>
						<cfif refind("^>[0-9]{4}-[0-9]{2}-[0-9]{2}$",searchText) EQ 1>
							<cfset searchText = "=#searchText#" >
						</cfif>
						<cfif refind("^<[0-9]{4}-[0-9]{2}-[0-9]{2}$",searchText) EQ 1>
							<cfset searchText = "=#searchText#" >
						</cfif>
						<cfif refind("^[0-9]{4}-[0-9]{2}-[0-9]{2}/[0-9]{4}-[0-9]{2}-[0-9]{2}$",searchText) EQ 1>
							<cfset searchText = "=#searchText#" >
						</cfif>
						<cfif refind("^[0-9]{4}$",searchText) EQ 1>
							<cfset searchText = "=#searchText#" >
						</cfif>
						<cfif refind("^[0-9]{4}/[0-9]{4}$",searchText) EQ 1>
							<cfset yearbits = ListToArray(searchText,'/')>
							<cfset searchText = "=#yearbits[1]#-01-01/#yearbits[2]#-12-31" >
						</cfif>
						<cfif refind("^[0-9]{4}-[0-9]{2}$",searchText) EQ 1>
							<cfset endDay = DaysInMonth(isoformatter.parse("#searchText#-01"))>
							<cfset searchText = "=#searchText#-01/#searchText#-#endDay#" >
						</cfif>
						<cfif refind("^[0-9]{4}-[0-9]{2}/[0-9]{4}-[0-9]{2}$",searchText) EQ 1>
							<cfset datebits = ListToArray(searchText,'/')>
							<cfset endDay2 = DaysInMonth(isoformatter.parse("#datebits[2]#-01"))>
							<cfset searchText = "=#datebits[1]#-01/#datebits[2]#-#endDay2#" >
						</cfif>
						--->
					</cfif>
					<!--- Warning: only searchText may be passed directly from the user here, join and field must be known good values ---> 
					<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#searchText#",separator="#separator#",nestDepth="#nest#",dataType="#searchFields.data_type#")>
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
		<cfquery name="result_id_count" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="result_id_count_result">
			SELECT count(*) ct 
			FROM user_search_table 
			WHERE
				user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>
		<cfif result_id_count.ct EQ 0>
			<cfstoredproc procedure="build_query_dbms_sql" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="prepareSearch_result" timeout="#Application.query_timeout#">
				<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
				<cfprocparam cfsqltype="CF_SQL_CLOB" value="#search_json#">
				<cfprocresult name="buildsearch">
			</cfstoredproc>
		</cfif>
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
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
					OR access_role = 'MANAGE_SPECIMENS'
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"DATA_ENTRY")>
					OR access_role = 'DATA_ENTRY'
				</cfif>
			ORDER by category, disp_order
		</cfquery>
		<cfset sanitizedsortdatafield = "">
		<cfset sortdatafieldSQL = "">
		<cfif len(sortdatafield) GT 0>
			<cfloop query="getFieldMetadata">
				<cfif compareNoCase(getFieldMetadata.column_name,sortdatafield) EQ 0>
					<cfset sanitizedsortdatafield = "#getFieldMetadata.column_name#">
					<cfif len(getFieldMetadata.sql_element) EQ 0 >
						<cfset sortdatafieldSQL = "#getFieldMetadata.column_name#">
					<cfelse>
						<cfset sortdatafieldSQL = "#getFieldMetadata.sql_element#">
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
		<cfquery name="searchcount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="searchcount_result" timeout="#Application.short_timeout#">
			SELECT count(*) ct 
			FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
				join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
			WHERE
				user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>
		<cfset records = searchcount.ct>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			<cfif pagesize GT 0 >
				SELECT * FROM (
			</cfif>
			SELECT distinct
				<cfset comma = "">
				<cfloop query="getFieldMetadata">
					<cfif len(sql_element) GT 0> 
						#comma##replace(sql_element,"''","'","all")# #column_name#
						<cfset comma = ",">
					</cfif>
				</cfloop>
				<cfif pagesize GT 0 >
					,
					row_number() OVER (
						<cfif lcase(sanitizedsortdatafield) EQ "guid">
							ORDER BY flatTableName.collection_cde <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
								to_number(regexp_substr(flatTableName.guid, '\d+')) <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
								flatTableName.guid <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
						<cfelseif len(sanitizedsortdatafield) GT 0>
							ORDER BY #sortdatafieldSQL# <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
						<cfelse>
							ORDER BY flatTableName.collection_cde asc, to_number(regexp_substr(flatTableName.guid, '\d+')) asc, flatTableName.guid asc
						</cfif>
					) rownumber
				</cfif>
			FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
				join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
			WHERE
				user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			<cfif lcase(sanitizedsortdatafield) EQ "guid">
				ORDER BY flatTableName.collection_cde <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
					to_number(regexp_substr(flatTableName.guid, '\d+')) <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
					flatTableName.guid <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
			<cfelseif len(sanitizedsortdatafield) GT 0>
				ORDER BY #sortdatafieldSQL# <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
			<cfelse>
				ORDER BY flatTableName.collection_cde asc, to_number(regexp_substr(flatTableName.guid, '\d+')) asc, flatTableName.guid asc
			</cfif>
			<cfif pagesize GT 0 >
				)
				WHERE rownumber between <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#recordstartindex#">
					and <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#recordendindex#">
			</cfif>
		</cfquery>

		<cfset rows = 0>
		<cfset data = ArrayNew(1)>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["recordcount"] = "#records#">
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
	<cfargument name="coll_object_entered_date" type="string" required="no">
	<cfargument name="entered_by" type="string" required="no"><!--- Not supported yet --->
	<cfargument name="entered_by_agent_id" type="string" required="no">
	<cfargument name="last_edit_date" type="string" required="no">
	<cfargument name="media_type" type="string" required="no">
	<cfargument name="biol_indiv_relationship" type="string" required="no">
	<cfargument name="other_id_type" type="string" required="no">
	<cfargument name="part_name" type="string" required="no">
	<cfargument name="preserve_method" type="string" required="no">
	<cfargument name="other_id_number" type="string" required="no">
	<cfargument name="type_status" type="string" required="no">
	<cfargument name="full_taxon_name" type="string" required="no">
	<cfargument name="any_taxa_term" type="string" required="no">
	<cfargument name="current_id_only" type="string" required="no">
	<cfargument name="species" type="string" required="no">
	<cfargument name="genus" type="string" required="no">
	<cfargument name="family" type="string" required="no">
	<cfargument name="phylorder" type="string" required="no">
	<cfargument name="phylclass" type="string" required="no">
	<cfargument name="phylum" type="string" required="no">
	<cfargument name="kingdom" type="string" required="no">
	<cfargument name="author_text" type="string" required="no">
	<cfargument name="scientific_name" type="string" required="no">
	<cfargument name="taxon_name_id" type="string" required="no">
	<cfargument name="any_geography" type="string" required="no">
	<cfargument name="higher_geog" type="string" required="no">
	<cfargument name="continent_ocean" type="string" required="no">
	<cfargument name="ocean_region" type="string" required="no">
	<cfargument name="ocean_subregion" type="string" required="no">
	<cfargument name="sea" type="string" required="no">
	<cfargument name="country" type="string" required="no">
	<cfargument name="state_prov" type="string" required="no">
	<cfargument name="county" type="string" required="no">
	<cfargument name="island" type="string" required="no">
	<cfargument name="island_group" type="string" required="no">
	<cfargument name="spec_locality" type="string" required="no">
	<cfargument name="collector" type="string" required="no">
	<cfargument name="collector_agent_id" type="string" required="no">
	<cfargument name="verbatim_date" type="string" required="no">
	<cfargument name="date_began_date" type="string" required="no">
	<cfargument name="date_ended_date" type="string" required="no">
	<cfargument name="date_collected" type="string" required="no">
	<cfargument name="collecting_source" type="string" required="no">
	<cfargument name="collecting_method" type="string" required="no">
	<cfargument name="loan_number" type="string" required="no">
	<cfargument name="accession_number" type="string" required="no">
	<cfargument name="deaccession_number" type="string" required="no">
	<cfargument name="publication_id" type="string" required="no">
	<cfargument name="citation" type="string" required="no">
	<cfargument name="nature_of_id" type="string" required="no">
	<cfargument name="determiner" type="string" required="no">
	<cfargument name="determiner_id" type="string" required="no">
	<cfargument name="identification_remarks" type="string" required="no">
	<cfargument name="common_name" type="string" required="no">
	<cfargument name="keyword" type="string" required="no">
	<cfargument name="received_date" type="string" required="no">
	<cfargument name="underscore_collection_id" type="string" required="no">
	<cfargument name="underscore_collection" type="string" required="no">

	<cfargument name="debug" type="string" required="no">
	<cfargument name="recordstartindex" type="string" required="no">
	<cfargument name="recordendindex" type="string" required="no">
	<cfargument name="pagesize" type="string" required="no">
	<cfargument name="pagenum" type="string" required="no">
	<cfargument name="sortdatafield" type="string" required="no">
	<cfargument name="sortorder" type="string" required="no">
	<cfargument name="filterscount" type="string" required="no">
	<cfargument name="returnallrecords" type="string" required="no">

	<cfif NOT isdefined("pagesize")><cfset pagesize=0></cfif>
	<cfif NOT isdefined("sortdatafield")><cfset sortdatafield=""></cfif>
	<cfif NOT isdefined("sortorder")><cfset sortorder="asc"></cfif>
	<cfif NOT isdefined("returnallrecords")><cfset returnallrecords=""></cfif>
	<cfif returnallrecords EQ "true">
		<!--- turn off all server side filtering/paging --->
		<cfset pagesize=0>
		<cfset pagenum="">
		<cfset sortdatafield="">
		<cfset sortorder="asc">
		<cfset filterscount="0">
	</cfif>
	<cfif isDefined("recordstartindex")>
		<!--- the value of recordstartindex is off by one from the expectations of oracle where rownumber between recordstartindex and recordendindex, 
         which returns values between start and end inclusive.  --->
		<cfset recordstartindex = recordstartindex + 1>
	</cfif>

	<cfset search_json = "[">
	<cfset separator = "">
	<cfset join = ''>

	<cfset nest = 1>

	<cfif isDefined("collection") AND len(collection) GT 0>
		<cfset field = '"field": "collection_cde"'>
		<cfset comparator = '"comparator": "IN"'>
		<cfset value = encodeForJSON(collection)>
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
	<cfif isDefined("media_type") AND len(media_type) GT 0>
		<cfset field = '"field": "media_type"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#media_type#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfset has0 = false>
	<cfset has1 = false>
	<cfif isDefined("other_id_number") AND len(other_id_number) GT 0>
		<cfset has0 = true>
	</cfif>
	<cfif isDefined("other_id_type") AND len(other_id_type) GT 0>
		<cfset has0 = true>
	</cfif>
	<cfif isDefined("other_id_number_1") AND len(other_id_number_1) GT 0>
		<cfset has1 = true>
	</cfif>
	<cfif isDefined("other_id_type_1") AND len(other_id_type_1) GT 0>
		<cfset has1 = true>
	</cfif>
	<cfif has0 AND has1>
		<!--- create nested or clause has (other_id_number of type) or (has other_id_number_1 of type_1) --->
		<cfset innernest = 1>
		<cfif isDefined("other_id_type") AND len(other_id_type) GT 0>
			<cfset field = '"field": "other_id_type"'>
			<cfset comparator = '"comparator": "IN"'>
			<cfset value = escapeQuotesForJSON(value="#other_id_type#")>
			<cfset search_json = '#search_json##separator#{"nest":"#nest#.#innernest#",#join##field#,#comparator#,"value": "#value#"}'>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset innernest = innernest + 1>
		</cfif>
		<cfif isDefined("other_id_number") AND len(other_id_number) GT 0>
			<cfif left(other_id_number,1) is "=" OR left(other_id_number,1) is "!">
				<cfset field = '"field": "DISPLAY_VALUE"'>
				<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#other_id_number#",separator="#separator#",nestDepth="#nest#.#innernest#")>
				<cfset separator = ",">
				<cfset join='"join":"and",'>
			 	<cfset innernest = innernest + 1>
			<cfelse>
				<cfset clause = ScriptPrefixedNumberListToJSON(other_id_number, "OTHER_ID_NUMBER", "OTHER_ID_PREFIX", false, "#nest#.#innernest#", "and")>
				<cfset search_json = "#search_json##separator##clause#">
				<cfset separator = ",">
				<cfset join='"join":"and",'>
			 	<cfset innernest = innernest + 1>
			</cfif>
		</cfif>
		<cfset nest = nest + 1>
		<cfset innernest = 1>
		<cfif isDefined("other_id_type_1") AND len(other_id_type_1) GT 0>
			<cfset field = '"field": "other_id_type"'>
			<cfset comparator = '"comparator": "IN"'>
			<cfset value = escapeQuotesForJSON(value="#other_id_type_1#")>
			<cfset search_json = '#search_json##separator#{"nest":"#nest#.#innernest#",#join##field#,#comparator#,"value": "#value#"}'>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset innernest = innernest + 1>
		</cfif>
		<cfif isDefined("other_id_number_1") AND len(other_id_number_1) GT 0>
			<cfif left(other_id_number_1,1) is "=" OR left(other_id_number_1,1) is "!">
				<cfset field = '"field": "DISPLAY_VALUE"'>
				<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#other_id_number_1#",separator="#separator#",nestDepth="#nest#.#innernest#")>
				<cfset separator = ",">
				<cfset join='"join":"and",'>
			 	<cfset innernest = innernest + 1>
			<cfelse>
				<cfset clause = ScriptPrefixedNumberListToJSON(other_id_number_1, "OTHER_ID_NUMBER", "OTHER_ID_PREFIX", false, "#nest#.#innernest#", "and")>
				<cfset search_json = "#search_json##separator##clause#">
				<cfset separator = ",">
				<cfset join='"join":"and",'>
			 	<cfset innernest = innernest + 1>
			</cfif>
		</cfif>
		<cfset nest = nest + 1>
	<cfelse>
		<cfif isDefined("other_id_number") AND len(other_id_number) GT 0>
			<cfif left(other_id_number,1) is "=" OR left(other_id_number,1) is "!">
				<cfset field = '"field": "DISPLAY_VALUE"'>
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
			<cfset comparator = '"comparator": "IN"'>
			<cfset value = escapeQuotesForJSON(value="#other_id_type#")>
			<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("other_id_number_1") AND len(other_id_number_1) GT 0>
			<cfif left(other_id_number_1,1) is "=" OR left(other_id_number_1,1) is "!">
				<cfset field = '"field": "DISPLAY_VALUE"'>
				<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#other_id_number_1#",separator="#separator#",nestDepth="#nest#")>
				<cfset separator = ",">
				<cfset join='"join":"and",'>
			 	<cfset nest = nest + 1>
			<cfelse>
				<cfset clause = ScriptPrefixedNumberListToJSON(other_id_number_1, "OTHER_ID_NUMBER", "OTHER_ID_PREFIX", false, nest, "and")>
				<cfset search_json = "#search_json##separator##clause#">
				<cfset separator = ",">
				<cfset join='"join":"and",'>
			 	<cfset nest = nest + 1>
			</cfif>
		</cfif>
		<cfif isDefined("other_id_type_1") AND len(other_id_type_1) GT 0>
			<cfset field = '"field": "other_id_type"'>
			<cfset comparator = '"comparator": "IN"'>
			<cfset value = escapeQuotesForJSON(value="#other_id_type_1#")>
			<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
	</cfif>
	<cfif isDefined("coll_object_entered_date") AND len(coll_object_entered_date) GT 0>
		<cfset field = '"field": "coll_object_entered_date"'>
		<cfset searchText = reformatDateSearchTerm(searchText="#coll_object_entered_date#") >
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#searchText#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("entered_by_id") AND len(entered_by_id) GT 0>
		<cfset field = '"field": "ENTERED_PERSON_ID"'>
		<cfset comparator = '"comparator": "="'>
		<cfset value = encodeForJSON(entered_by_id)>
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("last_edit_date") AND len(last_edit_date) GT 0>
		<cfset field = '"field": "last_edit_date"'>
		<cfset searchText = reformatDateSearchTerm(searchText="#last_edit_date#") >
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#searchText#",separator="#separator#",nestDepth="#nest#")>
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
	<cfif isDefined("date_collected") AND len(date_collected) GT 0>
		<cfset field = '"field": "date_began_date"'>
		<cfset searchText = reformatDateSearchTerm(searchText="#date_collected#") >
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#searchText#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
		<cfset field = '"field": "date_ended_date"'>
		<cfset searchText = reformatDateSearchTerm(searchText="#date_collected#") >
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#searchText#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("date_began_date") AND len(date_began_date) GT 0>
		<cfset field = '"field": "date_began_date"'>
		<cfset searchText = reformatDateSearchTerm(searchText="#date_began_date#") >
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#searchText#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("date_ended_date") AND len(date_ended_date) GT 0>
		<cfset field = '"field": "date_ended_date"'>
		<cfset searchText = reformatDateSearchTerm(searchText="#date_ended_date#") >
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#searchText#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("collecting_source") AND len(collecting_source) GT 0>
		<cfset field = '"field": "collecting_source"'>
		<cfset searchText = reformatDateSearchTerm(searchText="#collecting_source#") >
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#searchText#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("collecting_method") AND len(collecting_method) GT 0>
		<cfset field = '"field": "collecting_method"'>
		<cfset searchText = reformatDateSearchTerm(searchText="#collecting_method#") >
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#searchText#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("biol_indiv_relationship") AND len(biol_indiv_relationship) GT 0>
		<cfset field = '"field": "biol_indiv_relationship"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#biol_indiv_relationship#",separator="#separator#",nestDepth="#nest#")>
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
		<cfset value = encodeForJSON(taxon_name_id)>
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
		<cfif isDefined("any_taxa_term") AND len(any_taxa_term) GT 0>
			<cfif isDefined("current_id_only") AND current_id_only EQ "current">
				<cfset field = '"field": "taxa_term"'>
			<cfelse>
				<cfset field = '"field": "taxa_term_all"'>
			</cfif>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#any_taxa_term#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("full_taxon_name") AND len(full_taxon_name) GT 0>
			<!--- not currently on form --->
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
		<cfif isDefined("species") AND len(species) GT 0>
			<cfset field = '"field": "species"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#species#",separator="#separator#",nestDepth="#nest#")>
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
		<!--- handle special case values, any, any type, any primary --->
		<cfset type_status_value = type_status>
		<cfif lcase(type_status) EQ "any">
			<cfset type_status_value = "NOT NULL">
		<cfelseif lcase(type_status) EQ "any type">
			<cfquery name="types" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="types_result">
				SELECT type_status 
				FROM ctcitation_type_status 
				WHERE category = 'Primary' OR category = 'Secondary'
			</cfquery>
			<cfset type_status_value = "">
			<cfset typeseparator = "">
			<cfloop query="types">
				<cfset type_status_value = "#type_status_value##typeseparator##types.type_status#">
				<cfset typeseparator = ",">
			</cfloop>
		<cfelseif lcase(type_status) EQ "any primary type">
			<cfquery name="types" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="types_result">
				SELECT type_status 
				FROM ctcitation_type_status 
				WHERE category = 'Primary'
			</cfquery>
			<cfset type_status_value = "">
			<cfset typeseparator = "">
			<cfloop query="types">
				<cfset type_status_value = "#type_status_value##typeseparator##types.type_status#">
				<cfset typeseparator = ",">
			</cfloop>
		</cfif>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#type_status_value#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("keyword") AND len(keyword) GT 0>
		<cfset field = '"field": "KEYWORD"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#keyword#",separator="#separator#",nestDepth="#nest#",dataType="CTXKEYWORD")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("any_geography") AND len(any_geography) GT 0>
		<cfset field = '"field": "any_geography"'>
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
		<cfset searchValue = any_geography>
		<cfset searchValue = replace(searchValue,"!","~","all")>
		<cfset searchValue = replace(searchValue,"$","!","all")>
		<cfset searchValue = replace(searchValue,"##","$","all")>

		<!--- escape quotes for json construction --->
		<cfset searchValueForJSON = searchValue>
		<cfset searchValueForJSON = replace(searchValueForJSON,"\","\\","all")>
		<cfset searchValueForJSON = replace(searchValueForJSON,'"','\"',"all")>
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#searchValueForJSON#"}'>
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
	<cfif isDefined("continent_ocean") AND len(continent_ocean) GT 0>
		<cfset field = '"field": "continent_ocean"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#continent_ocean#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("ocean_region") AND len(ocean_region) GT 0>
		<cfset field = '"field": "ocean_region"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#ocean_region#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("ocean_subregion") AND len(ocean_subregion) GT 0>
		<cfset field = '"field": "ocean_subregion"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#ocean_subregion#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("sea") AND len(sea) GT 0>
		<cfset field = '"field": "sea"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#sea#",separator="#separator#",nestDepth="#nest#")>
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
	<cfif isDefined("spec_locality") AND len(spec_locality) GT 0>
		<cfset field = '"field": "spec_locality"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#spec_locality#",separator="#separator#",nestDepth="#nest#")>
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
		<cfif isDefined("received_date") AND len(received_date) GT 0>
			<cfset field = '"field": "RECEIVED_DATE"'>
			<cfset searchText = reformatDateSearchTerm(searchText="#received_date#") >
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#searchText#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("accn_status") AND len(accn_status) GT 0>
			<cfset field = '"field": "accn_status"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#accn_status#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("accn_type") AND len(accn_type) GT 0>
			<cfset field = '"field": "accn_type"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#accn_type#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("deaccession_number") AND len(deaccession_number) GT 0>
			<cfset field = '"field": "deacc_number"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#deaccession_number#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
	</cfif>

	<cfif isDefined("collector_agent_id") AND len(collector_agent_id) GT 0>
		<cfset field = '"field": "COLLECTORS_AGENT_ID"'>
		<cfset comparator = '"comparator": "="'>
		<cfset value = encodeForJSON(collector_agent_id)>
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
	<cfif (isDefined("collector_agent_id") AND len(collector_agent_id) GT 0) OR (isDefined("collector") AND len(collector) GT 0) >
		<!--- limit collector searches to collectors --->
		<cfset field = '"field": "COLLECTOR_ROLE"'>
		<cfset comparator = '"comparator": "="'>
		<cfset value = "c">
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>

	<cfif isDefined("publication_id") AND len(publication_id) GT 0>
		<cfset field = '"field": "CITATIONS_PUBLICATION_ID"'>
		<cfset comparator = '"comparator": "="'>
		<cfset value = encodeForJSON(publication_id)>
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
		<!--- TODO: Support textual search on publication from citation variable --->
	</cfif>


	<cfif isDefined("determiner_id") AND len(determiner_id) GT 0>
		<cfset field = '"field": "IDENTIFICATIONS_AGENT_ID"'>
		<cfset comparator = '"comparator": "="'>
		<cfset value = encodeForJSON(determiner_id)>
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	<cfelse>
		<cfif isDefined("determiner") AND len(determiner) GT 0>
			<cfset field = '"field": "IDENTIFICATIONS_AGENT_NAME"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#determiner#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
	</cfif>

	<cfif isDefined("nature_of_id") AND len(nature_of_id) GT 0>
		<cfset field = '"field": "NATURE_OF_ID"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#nature_of_id#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("identification_remarks") AND len(identification_remarks) GT 0>
		<cfset field = '"field": "IDENTIFICATION_REMARKS"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#identification_remarks#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>
	<cfif isDefined("common_name") AND len(common_name) GT 0>
		<cfset field = '"field": "COMMON_NAME"'>
		<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#common_name#",separator="#separator#",nestDepth="#nest#")>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	</cfif>

	<cfif isDefined("underscore_collection_id") AND len(underscore_collection_id) GT 0>
		<cfset field = '"field": "UNDERSCORE_COLLECTION_ID_RAW"'>
		<cfset comparator = '"comparator": "="'>
		<cfset value = encodeForJSON(underscore_collection_id)>
		<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
		<cfset separator = ",">
		<cfset join='"join":"and",'>
		<cfset nest = nest + 1>
	<cfelse>
		<cfif isDefined("underscore_collection") AND len(underscore_collection) GT 0>
			<cfset field = '"field": "COLLECTION_NAME"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#underscore_collection#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
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
		<cfquery name="result_id_count" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="result_id_count_result">
			SELECT count(*) ct 
			FROM user_search_table 
			WHERE
				user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>
		<cfif result_id_count.ct EQ 0>
			<!--- errors are handled by build_query_dbms_sql throwing exceptions --->
			<cfstoredproc procedure="build_query_dbms_sql" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="prepareSearch_result" timeout="#Application.query_timeout*2#">
				<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
				<cfprocparam cfsqltype="CF_SQL_CLOB" value="#search_json#">
				<cfprocresult name="buildsearch">
			</cfstoredproc>
		</cfif>
		<cfquery name="getFieldMetadata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="attrFields_result" timeout="#Application.short_timeout#">
			SELECT upper(column_name) as column_name, sql_element, data_type, category, label, disp_order
			FROM cf_spec_res_cols_r
			WHERE access_role = 'PUBLIC'
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					OR access_role = 'COLDFUSION_USER'
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
					OR access_role = 'MANAGE_TRANSACTIONS'
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
					OR access_role = 'MANAGE_SPECIMENS'
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"DATA_ENTRY")>
					OR access_role = 'DATA_ENTRY'
				</cfif>
			ORDER by category, disp_order
		</cfquery>
		<cfset sanitizedsortdatafield = "">
		<cfset sortdatafieldSQL = "">
		<cfif len(sortdatafield) GT 0>
			<cfloop query="getFieldMetadata">
				<cfif compareNoCase(getFieldMetadata.column_name,sortdatafield) EQ 0>
					<cfset sanitizedsortdatafield = "#getFieldMetadata.column_name#">
					<cfif len(getFieldMetadata.sql_element) EQ 0 >
						<cfset sortdatafieldSQL = "#getFieldMetadata.column_name#">
					<cfelse>
						<cfset sortdatafieldSQL = "#getFieldMetadata.sql_element#">
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
		<cfquery name="searchcount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="searchcount_result" timeout="#Application.short_timeout#">
			SELECT count(*) ct 
			FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
				join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
			WHERE
				user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>
		<cfset records = searchcount.ct>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			<cfif pagesize GT 0 >
				SELECT * FROM (
			</cfif>
			SELECT distinct
				<cfset comma = "">
				<cfloop query="getFieldMetadata">
					<cfif len(sql_element) GT 0> 
						#comma##replace(sql_element,"''","'","all")# #column_name#
						<cfset comma = ",">
					</cfif>
				</cfloop>
				<cfif pagesize GT 0 >
					,
					row_number() OVER (
						<cfif lcase(sanitizedsortdatafield) EQ "guid">
							ORDER BY flatTableName.collection_cde <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
								to_number(regexp_substr(flatTableName.guid, '\d+')) <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
								flatTableName.guid <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
						<cfelseif len(sanitizedsortdatafield) GT 0>
							ORDER BY #sortdatafieldSQL# <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
						<cfelse>
							ORDER BY flatTableName.collection_cde asc, to_number(regexp_substr(flatTableName.guid, '\d+')) asc, flatTableName.guid asc
						</cfif>
					) rownumber
				</cfif>
			FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
				join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
			WHERE
				user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			<cfif lcase(sanitizedsortdatafield) EQ "guid">
				ORDER BY flatTableName.collection_cde <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
					to_number(regexp_substr(flatTableName.guid, '\d+')) <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
					flatTableName.guid <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
			<cfelseif len(sanitizedsortdatafield) GT 0>
				ORDER BY #sortdatafieldSQL# <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
			<cfelse>
				ORDER BY flatTableName.collection_cde asc, to_number(regexp_substr(flatTableName.guid, '\d+')) asc, flatTableName.guid asc
			</cfif>
			<cfif pagesize GT 0 >
				)
				WHERE rownumber between <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#recordstartindex#">
					and <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#recordendindex#">
			</cfif>
		</cfquery>

		<cfset rows = 0>
		<cfset data = ArrayNew(1)>

		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["recordcount"] = "#records#">
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#ucase(col)#"] = replace(search[col][currentRow],'""','&quot;','all')>
			</cfloop>
			<cfset data[i] = row>
			<cfset i = i + 1>
		</cfloop>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfif isDefined("cfcatch.SQL") ><cfset query=cfcatch.SQL><cfelse><cfset query = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError & " " & query) >
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
@limitType restriction describing a limitation to impose on the search, supported: has_accepted_georeference, has_footprint
@return a json structure containing id and value, with spec_locality and locality_id in value and locality_id in id, and more data in meta.
--->
<cffunction name="getLocalityAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="limitType" type="string" required="no" default="">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT distinct
				locality.locality_id,
				locality.spec_locality,
				locality.curated_fg,
				geog_auth_rec.higher_geog,
				nvl2(accepted_lat_long.coordinate_precision, round(accepted_lat_long.dec_lat,accepted_lat_long.coordinate_precision), round(accepted_lat_long.dec_lat,5)) dec_lat,
				nvl2(accepted_lat_long.coordinate_precision, round(accepted_lat_long.dec_long,accepted_lat_long.coordinate_precision), round(accepted_lat_long.dec_long,5)) dec_long
			FROM
				locality
				join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
				<cfif isdefined("limitType") AND limitType EQ "has_accepted_georeference" >
					join accepted_lat_long on locality.locality_id = accepted_lat_long.locality_id
				<cfelse>
					left join accepted_lat_long on locality.locality_id = accepted_lat_long.locality_id
				</cfif>
			WHERE 
				(
					locality.spec_locality like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
					<cfif REFind("^[0-9]+$",term) GT 0>
						OR
						locality.locality_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#term#">
					</cfif>
				)
				<cfif isdefined("limitType") AND limitType EQ "has_footprint" >
					and locality.locality_id in (select locality_id from lat_long where error_polygon IS NOT NULL and accepted_lat_long_fg = 1)
				</cfif>
				<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user") ) >
					and locality_id in (
						SELECT locality_id
						FROM <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
					)
				</cfif>
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.locality_id#">
			<cfif search.curated_fg EQ "1"><cfset vetted="*"><cfelse><cfset vetted=""></cfif>
			<cfif len(search.dec_lat) GT 0 ><cfset georef=" #search.dec_lat#,#search.dec_long# "><cfelse><cfset georef=" "></cfif>
			<cfset row["value"] = "#search.spec_locality# (#search.locality_id#)#vetted#" >
			<cfset row["meta"] = "#search.spec_locality##georef##search.higher_geog# (#search.locality_id#)#vetted#" >
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

<!--- 
  ** given a result_id return the data set for that result_id from the current user's 
  * user_search_table joined with session.flatTableName as a csv serialization.
  * @param result_id the uuid that identifies the search to return as csv
  * @return a csv serialization with a content type text/csv http header or a http error status.
  *
  * @deprecated 
  * @see getSpecimensAsCSVProfile
  ** --->
<cffunction name="getSpecimensAsCSV" access="remote" returntype="any" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">

	<cfset retval = "">
	<cftry>
		<cfset username = session.dbuser>
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
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
					OR access_role = 'MANAGE_SPECIMENS'
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
				and rownum < <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DOWNLOAD_THRESHOLD#">
		</cfquery>

		<cfset retval = queryToCSV(search)>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>

	<cfheader name="Content-Type" value="text/csv">
<cfoutput>#retval#</cfoutput>
</cffunction>


<!--- 
  ** given a result_id return the data set for that result_id from the current user's 
  * user_search_table joined with session.flatTableName as a csv serialization using the set
  * of fields specified in a download_profile.
  * @param result_id the uuid that identifies the search to return as csv
  * @param download_profile_id the id for the profile that specifies the columns in the download.
  * @param paging default no, if yes, and result size is larger than DOWNLOAD_THRESHOLD then 
  *  page results, otherwise stream results.
  * @return a csv serialization with a content type text/csv http header or a http error status.
  ** --->
<cffunction name="getSpecimensAsCSVProfile" access="remote" returntype="any" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="download_profile_id" type="string" required="yes">
	<cfargument name="token" type="string" required="no" default="">
	<cfargument name="paging" type="string" required="no" default="no">

	<cfif isDefined("token") AND len(token) GT 0>
		<cflog text="getSpecimensAsCSVProfile started token=#token#" file="MCZbase">
	<cfelse>
		<cflog text="getSpecimensAsCSVProfile started with no token" file="MCZbase">
		<cfset token = "">
	</cfif>

	<cfset variable.result_id = arguments.result_id>
	<cfset variable.download_profile_id = arguments.download_profile_id>
	<cfset variable.token = arguments.token>
	<cfset variable.paging = arguments.paging>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="downloadThread#tn#" action="run" result_id="#result_id#" download_profile_id="#download_profile_id#" token="#token#">

		<cfif NOT isDefined("paging")>
			<cfset paging = "no">
		</cfif>
		<cflog text="getSpecimensAsCSVProfile executing downloadThread#tn#" file="MCZbase">
		<cfset retval = "">
		<cfset stream = true>
		<cftry>
			<cfset username = session.dbuser>
			<cfquery name="getProfileFields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getProfileFields_result">
				SELECT COLUMN_LIST 
				FROM 
					download_profile
				WHERE
					download_profile_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#download_profile_id#">
					AND (
						upper(username) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(username)#">
						OR
						sharing = 'Everyone'
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
						OR
						sharing = 'MCZ'
						</cfif>
						)
			</cfquery>
			<cfif getProfileFields.recordcount NEQ 1>
				<cfthrow message = "Specified profile [#encodeForHtml(download_profile_id)#] does not exist or is not shared with you.">
			</cfif>
			<cfset requested_columns = getProfileFields.column_list>
			<cfset valid_columns = arrayNew(1)>
			<cfset counter = 0>
			<cfloop list="#requested_columns#" delimiters="," index="listindex">
				<cfquery name="getFieldMetadata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getFieldMetadata_result">
					SELECT upper(column_name) as column_name, sql_element, data_type, category, label, disp_order
					FROM cf_spec_res_cols_r
					WHERE
						upper(column_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(listindex)#">
						AND ( 
						access_role = 'PUBLIC'
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							OR access_role = 'COLDFUSION_USER'
						</cfif>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
							OR access_role = 'MANAGE_TRANSACTIONS'
						</cfif>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
							OR access_role = 'MANAGE_SPECIMENS'
						</cfif>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"DATA_ENTRY")>
							OR access_role = 'DATA_ENTRY'
						</cfif>
						)
				</cfquery>
				<cfif getFieldMetadata.recordcount EQ 1>
					<cfset counter = counter + 1>
					<cfset col = structNew()>
					<cfset col.column_name = getFieldMetadata.column_name>
					<cfset col.sql_element = getFieldMetadata.sql_element>
					<cfset valid_columns[counter] = col>
				</cfif>
			</cfloop>
			<cfquery name="count" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="count_result">
				SELECT count(*) ct 
				FROM
					user_search_table
				WHERE
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			</cfquery>
	
			<cfif count.ct LT DOWNLOAD_THRESHOLD OR paging EQ "no">
				<cflog text="Query for stream. paging=#paging# count.ct=#count.ct#" file="MCZbase">
				<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
					SELECT 
						<cfset comma = "">
						<cfloop array="#valid_columns#" index="idx">
							<cfif len(idx.sql_element) GT 0> 
								#comma##replace(idx.sql_element,"''","'","all")# #idx.column_name#
								<cfset comma = ",">
							</cfif>
						</cfloop>
					FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
						join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
					WHERE
						user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				</cfquery>
				<cfset retval = queryToCSV(search)>
				<cfset stream = true>
			<cfelse>
				<cftransaction isolation="serializable">
				<cflog text="checking token #token# in cf_download_file" file="MCZbase">
				<cfquery name="checkToken" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="preDownload_result">
					SELECT count(*) ct 
					FROM cf_download_file 
					WHERE token = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#token#">
				</cfquery>
				<cftransaction action="commit">
				</cftransaction>
				<cfif checkToken.ct EQ 0>
					<cflog text="adding token #token# to cf_download_file" file="MCZbase">
					<cftransaction isolation="serializable">
					<cfquery name="preDownload" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="preDownload_result">
						INSERT into cf_download_file (
							result_id,
							token,
							username,
							download_profile_id,
							status
						) values ( 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#token#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#download_profile_id#">,
							'started'
						)
					</cfquery>
					<cftransaction action="commit">
					</cftransaction>
					<cfset pagesize = 10000>
					<cfif count.ct LTE pagesize>
						<cflog text="before search query count.ct=[#count.ct#]" file="MCZbase">
						<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
							SELECT 
								rownum as foundrownum,
								<cfset comma = "">
								<cfloop array="#valid_columns#" index="idx">
									<cfif len(idx.sql_element) GT 0> 
										#comma##replace(idx.sql_element,"''","'","all")# #idx.column_name#
										<cfset comma = ",">
									</cfif>
								</cfloop>
							FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
								join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
							WHERE
								user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						</cfquery>
						<cflog text="after search query" file="MCZbase">
						<cfset retval = queryToCSVFile(queryToConvert=search)>
						<cflog text="after queryToCSVFile" file="MCZbase">
					<cfelse> 
						<cfset pagenumber = 0>
						<cfset totalpages = ceiling(count.ct/pagesize)>
						<cfloop index="currentpage" from="1" to="#totalpages#">
							<cfset pagenumber = pagenumber + 1 >
							<cflog text="before search query count.ct=[#count.ct#] pagenumber=[#pagenumber#]" file="MCZbase">
							<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
										SELECT 
											rownum as foundrownum,
											<cfset comma = "">
											<cfloop array="#valid_columns#" index="idx">
												<cfif len(idx.sql_element) GT 0> 
													#comma##replace(idx.sql_element,"''","'","all")# #idx.column_name#
													<cfset comma = ",">
												</cfif>
											</cfloop>
										FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
											join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
										WHERE
											user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
											and
											pagesort > = ((#pagenumber#-1) * #pagesize# + 1)
											and
											pagesort < ((#pagenumber# * #pagesize#) + 1)
							</cfquery>
							<cflog text="after search query" file="MCZbase">
							<cfif pagenumber EQ 1>
								<cflog text="beforeQueryToCSVFile" file="MCZbase">
								<cfset retval = queryToCSVFile(queryToConvert=search)>
								<cflog text="after QueryToCSVFile" file="MCZbase">
							<cfelse>
								<cflog text="beforeQueryToCSVFile(mode=append)" file="MCZbase">
								<cfset retval = queryToCSVFile(queryToConvert=search,mode="append",timestamp=retval.TIMESTAMP,written=retval.WRITTEN)>
								<cflog text="afterQueryToCSVFile(mode=append)" file="MCZbase">
							</cfif>
							<cfset QueryClear(search)>
							<cfquery name="partialDownload" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="partialDownload_result">
								UPDATE cf_download_file 
								SET 
									status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="processed #pagenumber*pagesize# rows">,
									filename = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#retval.FILENAME#">,
									message = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#retval.MESSAGE#">
								WHERE
									token = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#token#"> and
									result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#"> and
									username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#"> and
									download_profile_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#download_profile_id#">
							</cfquery>
						</cfloop>
					</cfif>
					<cfset stream = false>
					<cfquery name="postDownload" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="postDownload_result">
						UPDATE cf_download_file 
						SET 
							status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#retval.STATUS#">,
							filename = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#retval.FILENAME#">,
							message = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#retval.MESSAGE#">
						WHERE
							token = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#token#"> and
							result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#"> and
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#"> and
							download_profile_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#download_profile_id#">
					</cfquery>
				<cfelse>
					<cflog text="Token exists [#checkToken.ct#] matches in downloadThread#tn#" file="MCZbase">
					<cfthrow message="Problem creating download.  Token [#token#] exists, [#checkToken.ct#] matches found." errorCode="900">
				</cfif>
			</cfif>
			<cfif stream>
				<cfheader name="Content-Type" value="text/csv">
				<cfoutput>#retval#</cfoutput>
			<cfelse>
				<cftry>
					<cfif retval.STATUS EQ "Failed">
						<cfset st = retval.STATUS>
						<cfset msg = retval.MESSAGE>
						<cfoutput>#st#: #msg#</cfoutput>
					<cfelse>
						<cfset fn = retval.filename>
						<cfset msg = retval.MESSAGE>
						<cfoutput>[{'FILENAME':'mcz_specimen_result_download_#result_id#.csv','PATH':'#fn#','MESSAGE':'#msg#'}]</cfoutput>
					</cfif>
				<cfcatch>
					<cfoutput>
						<cfdump var="#cfcatch#">
					</cfoutput>
				</cfcatch>
				</cftry>
			</cfif>
			<cflog text="normal end of downloadThread#tn#" file="MCZbase">
		<cfcatch>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cflog text="Exception in downloadThread#tn# #error_message#" file="MCZbase">
			<cfif NOT isDefined("cfcatch.errorcode") OR cfcatch.errorcode NEQ "900">
				<cfquery name="failedDownload" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="postDownload_result">
					UPDATE cf_download_file 
					SET 
						status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="Failed">,
						filename = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="">,
						message = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cfcatch.message#">
					WHERE
						token = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#token#"> and
						result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#"> and
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#"> and
						download_profile_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#download_profile_id#">
				</cfquery>
			</cfif>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>Error in #function_called#: #error_message#</cfoutput>
		</cfcatch>
		</cftry>
	
	</cfthread>
	<cfthread action="join" name="downloadThread#tn#" />
	<cflog text="getSpecimensAsCSVProfile completed downloadThread#tn#" file="MCZbase">
	<cfreturn cfthread["downloadThread#tn#"].output>
</cffunction>

<cffunction name="setupSpecimenDownload" returntype="any" access="remote" returnformat="json">
	<cfargument name="result_id" type="string" required="yes">

	<cftry>
		<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getCount_result">
			SELECT count(*) as ct 
			FROM user_search_table
			WHERE
				result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>
		<cfset data = ArrayNew(1)>
		<cfif getCount.recordcount NEQ 1>
			<cfthrow message="Error looking up records to download.">
		</cfif>

		<cfset i = 1>
		<cfloop query="getCount">
			<cfif getCount.ct EQ 0>
				<cfthrow message="No records found to download.">
			</cfif>
			<cfset row = StructNew()>
			<cfset row["RECORDCOUNT"] = "#getCount.ct#">
			<cfif getCount.ct LT DOWNLOAD_THRESHOLD>
				<cfset row["MODE"] = "direct">
			<cfelse>
				<cfset token = CreateUUID()>
				<cfset row["MODE"] = "file">
				<cfset row["TOKEN"] = "#token#">
			</cfif>
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

<cffunction name="checkSpecimenDownload" returntype="any" access="remote" returnformat="json">
	<cfargument name="token" type="string" required="yes">

	<cftry>
		<cfquery name="getStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getCount_result">
			SELECT status, result_id, filename, message
			FROM cf_download_file 
			WHERE
				token = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#token#">
		</cfquery>
		<cfset data = ArrayNew(1)>
		<cfif getStatus.recordcount GT 1>
			<cfthrow message="Error looking up download status, duplicate token.">
		</cfif>

		<cfset i = 1>
		<cfif getStatus.recordcount EQ 0>
			<cfset row = StructNew()>
			<cfset row["STATUS"] = "Starting">
			<cfset data[i]  = row>
		<cfelse>
			<cfloop query="getStatus">
				<cfset row = StructNew()>
				<cfset row["STATUS"] = "#getStatus.status#">
				<cfset row["FILENAME"] = "mcz_specimen_result_download_#getStatus.result_id#">
				<cfset row["PATH"] = "#getStatus.filename#">
				<cfset row["MESSAGE"] = "#getStatus.message#">
				<cfset data[i]  = row>
				<cfset i = i + 1>
			</cfloop>
		</cfif>
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

<cffunction name="getDownloadRequestsHTML" returntype="string" access="remote" returnformat="plain">
	<cfthread name="getDownloadRequestsThread">
		<cfoutput>
			<cftry>
				<cfquery name="getDownloadStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getDownloadStatus_result">
					SELECT filename, status, to_char(time_created,'yyyy-mm-dd HH24:MI') time_created,
						name
					FROM cf_download_file
						left join download_profile on cf_download_file.download_profile_id = download_profile.download_profile_id
					WHERE cf_download_file.username=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND status <> 'Deleted'
						AND (status <> 'Failed' OR time_created > current_timestamp - interval '2' DAY)
					ORDER BY time_created desc
				</cfquery>
				<ul>
					<cfif getDownloadStatus.recordcount EQ 0>
						<li>None</li>
					<cfelse>
						<cfloop query="getDownloadStatus">
							<li class="small95">
								Requested: #getDownloadStatus.time_created#
									<span class="text-success">#getDownloadStatus.status# </span>
								<cfif getDownloadStatus.status EQ "Success" AND len(getDownloadStatus.filename) GT 0>
									<p><a href="#getDownloadStatus.filename#">Download</a> #getDownloadStatus.name#</p>
								</cfif>
							</li>
						</cfloop>
					</cfif>
				</ul>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
				<cfelse>
				   <cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
			   	<div class="container">
					  <div class="row">
						 <div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">"Feedback/Report Errors"</a></p>
						 </div>
					  </div>
				   </div>
			</cfcatch>
			</cftry>
	  </cfoutput>
   </cfthread>
   <cfthread action="join" name="getDownloadRequestsThread" />
   <cfreturn getDownloadRequestsThread.output>
</cffunction>


<cffunction name="getDownloadDialogHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="filename" type="string" required="yes">
	<cfthread name="getDownloadDialogThread">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<cfquery name="getProfiles" datasource="cf_dbuser">
					SELECT 
						username, name, download_profile_id, sharing, column_list
					FROM 
						download_profile
					WHERE
						target_search = 'Specimens'
						AND (
							upper(username) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(session.username)#">
							or sharing = 'Everyone'
							<cfif oneOfUs IS 1>
								or sharing = 'MCZ'
							</cfif>
						)
				</cfquery>
				<cfquery name="getUserDefaultProfile" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getUserDefaultProfile_result">
					SELECT specimens_download_profile 
					FROM cf_users
					WHERE
						upper(username) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(session.username)#">
						and specimens_download_profile IS NOT NULL
				</cfquery>
				<cfif getUserDefaultProfile.recordcount EQ 0>
					<!--- has no default profile, use first in getProfiles --->
					<cfset selected_profile_id = getProfiles.download_profile_id>
				<cfelse>
					<cfset selected_profile_id = getUserDefaultProfile.specimens_download_profile>
				</cfif>
				<h3>Download Profile</h3>
				<div class="form-row">
					<div class="col-12">
						<script>
							function handleInternalDownloadClick(result_id) {
								var profile = $("##profile_picker").val();
								$("##downloadFeedback").html("Download requested...");
								$("##downloadResult").html("");
								jQuery.ajax({
									url: "/specimens/component/search.cfc",
									type: "post",
									data: { 
										method: "setupSpecimenDownload",
										returnformat: "json",
										result_id : result_id
									},
									success: function (data) { 
										var retval = JSON.parse(data);
										var rows = retval[0].RECORDCOUNT;
										if (retval[0].MODE=="direct") { 
											// just stream the results to the user
											$("##downloadResult").html('<a id="specimencsvdownloadlink" aria-label="Export results to csv" href="/specimens/component/search.cfc?method=getSpecimensAsCSVProfile&result_id=#encodeForUrl(result_id)#&download_profile_id='+profile+'&paging=yes" download="#filename#" onclick="$(\'##specimencsvdownloadlink\').attr(\'style\',\'color: purple !important;\');" target="_blank" >Download ('+rows+' records)</a>');
										} else if (retval[0].MODE=="file") { 
											// request generation of file, and poll until it is created.
											var token = retval[0].TOKEN;
											$("##downloadFeedback").html("Preparing ("+rows+" records).");
											$("##downloadResult").html("Progress and download also available on your User Profile");
											// actually request that the file be generated
											callGetSpecimensAsCSVProfile(profile, result_id, token);
											checkStatus(token,rows);
										}
									}, 
									error: function (jqXHR, textStatus, error) {
										handleFail(jqXHR,textStatus,error,"setting up to download");
									}
								});
							}
							async function checkStatus(token,rows) { 
								var done = false;
								$("##downloadRetry").html("");
								while (!done) { 
									await new Promise(resolve => setTimeout(resolve, 2000));
									jQuery.ajax({
										url: "/specimens/component/search.cfc",
										type: "get",
										data: { 
											method: "checkSpecimenDownload",
											returnformat: "json",
											token : token
										},
										success: function(data) { 
											console.log(data);
											try { 
												var parsed = JSON.parse(data)[0];
												var status = parsed.STATUS;
												if (status=='Success') { 
													$("##downloadFeedback").html(parsed.STATUS);
													done = true;
													var filename = parsed.FILENAME;
													var path = parsed.PATH;
													var message = parsed.MESSAGE;
													var html = '<a id="specimencsvdownloadlink" arial-label="download results file" download="'+filename+'" target="_blank" href="'+path+'">'+message+'</a>';
													$("##downloadResult").html(html);
												} else { 
													$("##downloadFeedback").html("Preparing ("+rows+" records).... ("+JSON.parse(data)[0].STATUS+")");
													if (status=="Failed" || status=="Incomplete") { 
														done = true;
													}
												} 
											} catch (e) { 
												console.log(e.message);
											}
										},
										error: function (jqXHR, textStatus, error) {
											done = true;
											$("##downloadRetry").html('<button class="btn btn-xs btn-secondary" onClick="checkStatus(\''+token+'\',\''+rows+'\');">Recheck Status</button>');
											if (!error) { error=""; } 
											$("##downloadStatus").html("Preparing ("+rows+" records).... Error: " + error.toString().substring(0,50));
											handleFail(jqXHR,textStatus,error,"checking specimen download status");
										}
									});
									if ($("##downloadResult").html()=="Error") { 
										done = true; 
										$("##downloadRetry").html('<button class="btn btn-xs btn-secondary" onClick="checkStatus(\''+token+'\',\''+rows+'\');">Recheck Status</button>');
									}
								} 
							}
							async function callGetSpecimensAsCSVProfile(profile, result_id, token) { 
								console.log(token);
								jQuery.ajax({
									url: "/specimens/component/search.cfc",
									type: "get",
									data: { 
										method: "getSpecimensAsCSVProfile",
										returnformat: "json",
										download_profile_id : profile,
										result_id: result_id,
										paging: "yes",
										token : token
									},
									success: function(data) { 
										console.log(data);
										var parsed = JSON.parse(data.replaceAll('"','').trim().replaceAll("'",'"'))[0];
										var filename = parsed.FILENAME;
										var path = parsed.PATH;
										var message = parsed.MESSAGE;
										var html = '<a id="specimencsvdownloadlink" arial-label="download results file" download="'+filename+'" target="_blank" href="'+path+'">'+message+'</a>';
										$("##downloadResult").html(html);
									},
									error: function (jqXHR, textStatus, error) {
										handleFail(jqXHR,textStatus,error,"checking specimen download status");
										$("##downloadResult").html("Error");
									}
								});
							}
						</script>
						<label class="data-entry-label" for="profile_picker">Pick profile for which fields to include in the download</label>
						<select id="profile_picker" name="profile_picker" class="data-entry-select">
							<cfloop query="getProfiles">
								<cfset columnCount = ListLen(column_list)>
								<cfif download_profile_id EQ selected_profile_id>
									<cfset selected = "selected">
								<cfelse>
									<cfset selected="">
								</cfif>
								<option value="#download_profile_id#" #selected#>#name# (#columnCount# columns, available to: #sharing#)</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12">
						<button id="specimencsvdownloadbutton" class="btn btn-xs btn-secondary px-2 my-2 mx-1" aria-label="Export results to csv" onClick="handleInternalDownloadClick('#result_id#');" >Request Download as CSV</button>
						<output id="downloadFeedback"></output>
						<output id="downloadResult"></output>
						<output id="downloadRetry"></output>
					</div>
				</div>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
				<cfelse>
					<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
								<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h2>Internal Server Error.</h2>
								<p>#message#</p>
								<p><a href="/info/bugs.cfm">"Feedback/Report Errors"</a></p>
							</div>
						</div>
					</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getDownloadDialogThread" />
	<cfreturn getDownloadDialogThread.output>
</cffunction>


<cffunction name="getDownloadAgreeDialogHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="filename" type="string" required="yes">
	<cfthread name="getDownloadAgreeDialogThread">
		<cfoutput>
			<cftry>
				<cfquery name="getUserData" datasource="cf_dbuser">
					SELECT 
						cf_users.user_id,
						first_name,
						middle_name,
						last_name,
						affiliation,
						email
					FROM 
						cf_user_data left join cf_users on cf_user_data.user_id = cf_users.user_id 
					WHERE
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<h3>Download Agreement</h3>
				<form name="downloadForm" id="downloadForm">
					<input type="hidden" name="user_id" value="#getUserData.user_id#">
					<input type="hidden" name="result_id" value="#result_id#">
					<div class="form-row">
						<div class="col-12 p-1">
							You must fill out this form before you may download data. Fields with a <input type="text" size="6" class="reqdClr" value="yellow" disabled aria-label="yellow"> background color are required.
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-4">
							<label for="first_name" class="data-entry-label">First Name</label>
							<input type="text" name="first_name" id="first_name" value="#getUserData.first_name#" class="data-entry-input reqdClr" required>
						</div>
						<div class="col-12 col-md-4">
							<label for="middle_name" class="data-entry-label">Middle Name</label>
							<input type="text" name="middle_name" id="middle_name" value="#getUserData.middle_name#" class="data-entry-input">
						</div>
						<div class="col-12 col-md-4">
							<label for="last_name" class="data-entry-label">Last Name</label>
							<input type="text" name="last_name" id="last_name" value="#getUserData.last_name#" class="data-entry-input reqdClr" required>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-8">
							<label for="affiliation" class="data-entry-label">Affiliation</label>
							<input type="text" name="affiliation" id="affiliation" value="#getUserData.affiliation#" class="data-entry-input reqdClr" required>
						</div>
						<div class="col-12 col-md-4">
							<label for="download_purpose" class="data-entry-label">Purpose of Download</td>
							<cfquery name="ctPurpose" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select * from ctdownload_purpose
							</cfquery>
							<select name="download_purpose" id="download_purpose" size="1" class="reqdClr data-entry-select" required>
								<cfloop query="ctPurpose">
									<option value="#ctPurpose.download_purpose#">#ctPurpose.download_purpose#</option>
								</cfloop>
							</select>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12">
							<a rel="license" id="cc_by_nc" href="http://creativecommons.org/licenses/by-nc/4.0/legalcode" title="Creative Commons Attribution Non Commercial (CC-BY-NC) 4.0 License"><img src="/shared/images/cc-by-nc.svg" height="31" width="88"></a>
							<p property="dc:license">
								The publisher and rights holder of this work is The Museum of Comparative Zoology, Harvard University.
								Copyright © #year(now())# President and Fellows of Harvard College, Some Rights Reserved. This work is licensed under a <a href="http://creativecommons.org/licenses/by-nc/4.0/legalcode">Creative Commons Attribution Non Commercial (CC-BY-NC) 4.0 License</a>.
							</p>
						</div>
						<div class="col-12">
							These data are intended for use in education and research and may not be used for commercial purposes
							without prior written consent from the Museum. Those wishing to include these data in analyses or reports must acknowledge 
							the provenance of the original data and notify the appropriate curator prior to publication. These are secondary data, and
							their accuracy is not guaranteed. Citation of the data is no substitute for examination of specimens. The Museum and its staff 
		 					are not responsible for loss or damages due to use of these data.  The entire MCZbase dataset can be cited with the doi:10.15468/p5rupv
							researchers are encouraged to search for relevant <a href="https://www.gbif.org/occurrence/search?dataset_key=4bfac3ea-8763-4f4b-a71a-76a6f5f243d3">MCZ data in GBIF</a> and cite the DOI GBIF provides for a search result. 
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-8">
							<label for="email" class="data-entry-label">Email</td>
							<input type="text" name="email" id="email" value="#getUserData.email#" class="data-entry-input">
						</div>
						<div class="col-12 col-md-4">
							<label for="agree">I agree.</label>
							<input type="checkbox" name="agree" id="agree" value="yes" onclick="handleAgreeClick();" >
							<script>
								function handleAgreeClick() {
									var valid = false;
									if ($("##first_name").val()!="" && $("##last_name").val()!="" && $("##affiliation").val()!="" ) { 
										valid = true;
									}			
									if(valid && $("##agree").prop('checked')==true) {
										$("##specimencsvdownloadbutton").removeClass("disabled");
									} else { 
										$("##specimencsvdownloadbutton").addClass("disabled");
									}
								}
								function handleDownloadClick() {
									$("##downloadFeedback").html("Download requested...");
									jQuery.ajax({
										dataType: "json",
										url: "/specimens/component/search.cfc",
										data: { 
											method : "logExternalDownload",
											result_id :  "#result_id#",
											first_name :  $("##first_name").val(),
											middle_name : $("##middle_name").val(),
											last_name : $("##last_name").val(),
											affiliation : $("##affiliation").val(),
											download_purpose : $("##download_purpose").val(),
											email : $("##email").val(),
											agree : $("##agree").val()
										},
										error: function (jqXHR, status, message) {
											console.log("Error logging download [#result_id#]: " + status + " " + jqXHR.responseText);
										},
										success: function (result) {
											console.log("Logged download of #result_id# ");
										}
									});
									return true;
								}
							</script>
						</div>
					</div>
					<h3>Download Profile</h3>
					<cfquery name="getProfiles" datasource="cf_dbuser">
						SELECT 
							username, name, download_profile_id, sharing, column_list
						FROM 
							download_profile
						WHERE
							target_search = 'Specimens'
							AND (
							upper(username) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(session.username)#">
							or sharing = 'Everyone'
						)
						ORDER BY 
							length(column_list) asc
					</cfquery>
					<div class="form-row">
						<div class="col-12">
							Note: Downloads over #DOWNLOAD_THRESHOLD# records may fail.  We suggest querying <a href="https://www.gbif.org/occurrence/search?dataset_key=4bfac3ea-8763-4f4b-a71a-76a6f5f243d3" target="_blank">MCZ records on GBIF</a> for large donwloads, and any downloads used for publications (where we encourage you to cite the DOI for the downloaded data in your publication).
						</div>
						<div class="col-12">
							<!--- NOTE: functionality for saving to a temporary file and monitoring progress is not included on this dialog, so getSpecimensAsCSVProfile can
 								only operate here with paging=no.
							--->
							<script>
								function changeProfile() { 
									var profile = $("##profile_picker").val();
									$('##specimencsvdownloadbutton').attr("href", "/specimens/component/search.cfc?method=getSpecimensAsCSVProfile&result_id=#encodeForUrl(result_id)#&paging=no&download_profile_id="+profile);
								}
							</script>
							<label class="data-entry-label" for="profile_picker">Pick profile for which fields to include in the download</label>
							<select id="profile_picker" name="profile_picker" class="data-entry-select" onchange="changeProfile()">
								<cfset selected="selected">
								<cfloop query="getProfiles">
									<cfset columnCount = ListLen(column_list)>
									<cfif selected EQ "selected">
										<cfset profile_id = download_profile_id>
									</cfif>
									<option value="#download_profile_id#" #selected#>#name# #columnCount# columns (Available to: #sharing#)</option>
									<cfset selected="">
								</cfloop>
							</select>
						</div>
						<div class="col-12">
							<!--- See note above about streaming only from this dialog --->
							<!--- using target _blank to give user feedback on ongoing download.  Could monitor for a cookie, see for example https://www.bennadel.com/blog/2533-tracking-file-download-events-using-javascript-and-coldfusion.htm --->
							<a id="specimencsvdownloadbutton" class="btn btn-xs btn-secondary px-2 my-2 mx-1 disabled" aria-label="Export results to csv" href="/specimens/component/search.cfc?method=getSpecimensAsCSVProfile&download_profile_id=#profile_id#&result_id=#encodeForUrl(result_id)#" download="#filename#" target="_blank" onclick="handleDownloadClick();" >Download as CSV</a>
							<output id="downloadFeedback"></output>
							<output id="downloadResult"></output>
						</div>
					</div>
				</form>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
				<cfelse>
					<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
								<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h2>Internal Server Error.</h2>
								<p>#message#</p>
								<p><a href="/info/bugs.cfm">"Feedback/Report Errors"</a></p>
							</div>
						</div>
					</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getDownloadAgreeDialogThread" />
	<cfreturn getDownloadAgreeDialogThread.output>
</cffunction>

<cffunction name="logExternalDownload" returntype="string" access="remote" returnformat="plain">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="first_name" type="string" required="yes">
	<cfargument name="last_name" type="string" required="yes">
	<cfargument name="affiliation" type="string" required="yes">
	<cfargument name="middle_name" type="string" required="no">
	<cfargument name="email" type="string" required="no">
	<cfargument name="download_purpose" type="string" required="no">
	<cfargument name="agree" type="string" required="no">
	<cfthread name="logDownloadThread">
		<cftry>
			<cfquery name="getUserID" datasource="cf_dbuser">
				SELECT cf_users.user_id
				FROM cf_users
				WHERE
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset user_id = getUserID.user_id>
			<cfquery name="isUser" datasource="cf_dbuser">
				select * from cf_user_data where user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#user_id#">
			</cfquery>
			<cfif #isUser.recordcount# is 1>
				<!---- already have a user_data entry ---->
				<cfquery name="upUser" datasource="cf_dbuser">
					UPDATE cf_user_data SET
						first_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#first_name#">,
						last_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#last_name#">,
						affiliation = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#affiliation#">
						<cfif len(#middle_name#) gt 0>
							,middle_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#middle_name#">
						</cfif>
						<cfif len(#email#) gt 0>
							,email = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#email#">
						</cfif>
					WHERE
						user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#user_id#">
				</cfquery>
			<cfelse>
				<!---- registered, but haven't created a profile entry yet. ---->
				<cfquery name="newUser" datasource="cf_dbuser">
					INSERT INTO cf_user_data (
						user_id,
						first_name,
						last_name,
						affiliation
						<cfif len(#middle_name#) gt 0>
							,middle_name
						</cfif>
						<cfif len(#email#) gt 0>
							,email
						</cfif>
						)
					VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#user_id#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#first_name#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#last_name#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#affiliation#">
						<cfif len(#middle_name#) gt 0>
							,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#middle_name#">
						</cfif>
						<cfif len(#email#) gt 0>
							,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#email#">
						</cfif>
						)
				</cfquery>
			</cfif>
			<cfquery name="getData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT count(*) ct
				FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
					join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
				WHERE
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			</cfquery>
			<cfquery name="dl" datasource="cf_dbuser">
				INSERT INTO cf_download (
					user_id,
					download_purpose,
					download_date,
					num_records,
					agree_to_terms
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#user_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#download_purpose#">,
					sysdate,
					nvl(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getData.ct#">,0),
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agree#">
				)
			</cfquery>
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfset retval="">
	<cfreturn retval >
</cffunction>

		
<cffunction name="saveBasicSrchPref" access="remote">
	<cfargument name="id" type="string" required="yes">
	<cfargument name="onOff" type="numeric" required="yes">

	<cfset retval = "">
	<cfif isdefined("session.username") and len(#session.username#) gt 0>
	   <cfthread name="saveBasicSrchThread" >
			<cfoutput>
			<cftransaction>
			<cftry>
				<cfif listFind("IDDetail,TaxaDetail,GeogDetail,CollDetail",id) EQ 0 >
					<cfthrow message="unknown location search preference id.">
				</cfif>
				<cfquery name="getcurrentvalues" datasource="cf_dbuser">
					SELECT BASICSRCHPREFS
					FROM cf_users
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfset currentList=valuelist(getcurrentvalues.BASICSRCHPREFS)>
				<cfset nv = currentList>
				<cfif onOff is 1>
					<cfif not listfind(currentList,id)>
						<cfset nv=listappend(currentList,id)>
					</cfif>
				<cfelse>
					<cfif listfind(currentList,id)>
						<cfset nv=listdeleteat(currentList,listfind(currentList,id))>
					</cfif>
				</cfif>
				<cfquery name="update" datasource="cf_dbuser" result="update_result">
					update cf_users
					set BASICSRCHPREFS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nv#">
					where
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfset session.BASICSRCHPREFS=nv>
				<cftransaction action="commit">
			<cfcatch>
				<cftransaction action="rollback">
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
				<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
				<cfabort>
			</cfcatch>
			</cftry>
			</cftransaction>
			</cfoutput>
		</cfthread>
		<cfthread action="join" name="saveBasicSrchThread" />
		<cfset retval = session.BASICSRCHPREFS>
	</cfif>
	<cfreturn retval>
</cffunction>

<!--- remove a single record from the current user's user_search_table 
@param result_id the result from which to remove the row.
@param collection_object_id the collection object to remove from the result.
@return a json struct data with status:deleted, count:1 or an http 500
--->
<cffunction name="removeItemFromResult" access="remote" returntype="any" returnformat="json">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset variables.result_id = arguments.result_id>
	<cfset variables.collection_object_id = arguments.collection_object_id>

	<cfset data = ArrayNew(1)>
	<cfif isdefined("session.username") and len(#session.username#) gt 0>
		<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	   <cfthread name="removeItemFromResultThread_#tn#" >
			<cftransaction>
			<cftry>
				<cfquery name="getcurrentvalues" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getcurrentvalues_result" timeout="#Application.short_timeout#">
					SELECT pagesort
					FROM user_search_table
					WHERE 
						result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.result_id#">
						AND
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
				</cfquery>
				<cfif getcurrentvalues.recordcount NEQ 1>
					<cfthrow message="Matched other than one record in user search table.">
				</cfif>
				<cfquery name="remove" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="remove_result" timeout="#Application.short_timeout#">
					DELETE FROM
						user_search_table
					WHERE
						result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.result_id#">
						AND
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
				</cfquery>
				<cfif remove_result.recordcount NEQ 1>
					<cfthrow message="Tried to remove other than one record in user search table.">
				</cfif>
				<cfquery name="movepagedown" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="movepagedown_result" timeout="#Application.short_timeout#">
					UPDATE
						user_search_table
					SET
						pagesort = pagesort - 1
					WHERE
						result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.result_id#">
						AND
						pagesort > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getcurrentvalues.pagesort#">
				</cfquery>
				<cfset row = StructNew()>
				<cfset row["status"] = "deleted">
				<cfset row["id"] = "#result_id#">
				<cfset row["count"] = "1">
				<cfset data[1] = row>
				<cftransaction action="commit">
			<cfcatch>
				<cftransaction action="rollback">
				<cfoutput>
					<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
					<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
					<cfset function_called = "#GetFunctionCalledName()#">
					<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
				</cfoutput>
			</cfcatch>
			</cftry>
			</cftransaction>
		</cfthread>
		<cfthread action="join" name="removeItemFromResultThread_#tn#" />
	</cfif>
	<cfif ArrayIsEmpty(data)>
		<cfreturn cfthread["removeItemFromResultThread_#tn#"].output>
	<cfelse>
		<cfreturn #serializeJSON(data)#>
	</cfif>
</cffunction>


<!--- remove multiple records matching some grouping criterion from 
  the current user's user_search_table 
@param result_id the result from which to remove the row.
@param grouping_criterion the grouping criterion to identify collection objects to 
  remove from the result.
@param grouping_value the value of the grouping criterion to identify collection 
  objects to remove from the result.
@return a json struct data with status:deleted, count:{number removed} or an http 500
--->
<cffunction name="removeItemsFromResult" access="remote" returntype="any" returnformat="json">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="grouping_criterion" type="string" required="yes">
	<cfargument name="grouping_value" type="string" required="yes">

	<cfset variables.result_id = arguments.result_id>
	<cfset variables.grouping_criterion = arguments.grouping_criterion>
	<cfset variables.grouping_value = arguments.grouping_value>

	<cfset data = ArrayNew(1)>
	<cfif isdefined("session.username") and len(#session.username#) gt 0>
		<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	   <cfthread name="removeItemsFromResultThread_#tn#" >
			<cftransaction>
			<cftry>
				<cfquery name="getRemoveList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getRemoveList_result" timeout="#Application.short_timeout#">
					SELECT collection_object_id
					FROM user_search_table
					WHERE 
						result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.result_id#">
						AND
						<cfif variables.grouping_criterion EQ ("collection_cde")>
							collection_object_id IN (
								SELECT collection_object_id 
								FROM cataloged_item 
								WHERE collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.grouping_value#">
							)
						<cfelse>
							<cfthrow message="Unsupported grouping criterion.">
						</cfif>
				</cfquery>
				<cfif getRemoveList.recordcount EQ 0>
					<cfthrow message="No records identified to remove from search results.">
				</cfif>
				<cfset removedCounter = 0>
				<cfloop query="getRemoveList">
					<cfquery name="getcurrentvalues" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getcurrentvalues_result" timeout="#Application.short_timeout#">
						SELECT pagesort
						FROM user_search_table
						WHERE 
							result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.result_id#">
							AND
							collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getRemoveList.collection_object_id#">
					</cfquery>
					<cfif getcurrentvalues.recordcount NEQ 1>
						<cfthrow message="Matched other than one record in user search table by collection_object_id.">
					</cfif>
					<cfquery name="remove" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="remove_result" timeout="#Application.short_timeout#">
						DELETE FROM
							user_search_table
						WHERE
							result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.result_id#">
							AND
							collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getRemoveList.collection_object_id#">
					</cfquery>
					<cfif remove_result.recordcount NEQ 1>
						<cfthrow message="Tried to remove other than one record in user search table by collection_object_id.">
					<cfelse>
						<cfset removedCounter = removedCounter + remove_result.recordcount>
					</cfif>
					<cfquery name="movepagedown" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="movepagedown_result" timeout="#Application.short_timeout#">
						UPDATE
							user_search_table
						SET
							pagesort = pagesort - 1
						WHERE
							result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.result_id#">
							AND
							pagesort > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getcurrentvalues.pagesort#">
					</cfquery>
				</cfloop>
				<cfset row = StructNew()>
				<cfset row["status"] = "deleted">
				<cfset row["id"] = "#result_id#">
				<cfset row["count"] = "#removedCounter#">
				<cfset data[1] = row>
				<cftransaction action="commit">
			<cfcatch>
				<cftransaction action="rollback">
				<cfoutput>
					<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
					<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
					<cfset function_called = "#GetFunctionCalledName()#">
					<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
				</cfoutput>
			</cfcatch>
			</cftry>
			</cftransaction>
		</cfthread>
		<cfthread action="join" name="removeItemsFromResultThread_#tn#" />
	</cfif>
	<cfif ArrayIsEmpty(data)>
		<cfreturn cfthread["removeItemsFromResultThread_#tn#"].output>
	<cfelse>
		<cfreturn #serializeJSON(data)#>
	</cfif>
</cffunction>

</cfcomponent>
