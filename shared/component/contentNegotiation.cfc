<!---
shared/component/contentNegotiation.cfc

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
<!--- Pages that set a linked data content type include this inside cfsilent, so that the
	include adds no whitespace ahead of a document that has to parse. --->
<cfcomponent>

<!---
	negotiateMediaType choose the media type to deliver from an HTTP Accept header, following
	RFC 9110 section 12.5.1: quality values, type/* and */* ranges, case-insensitive types, and
	parameters other than q ignored.  The highest quality wins; on a tie, a range naming the type
	beats a wildcard, then the client's earlier range, then the server's earlier offer.

	@param acceptHeader the value of the Accept header, may be empty.
	@param offeredTypes comma separated media types this page can deliver, in the server's order of
		preference.
	@param defaultType returned when the header is empty or accepts none of the offered types.
	@return one of offeredTypes, as given, or defaultType.
--->
<cffunction name="negotiateMediaType" access="public" returntype="string" output="false">
	<cfargument name="acceptHeader" type="string" required="yes">
	<cfargument name="offeredTypes" type="string" required="yes">
	<cfargument name="defaultType" type="string" required="yes">

	<cfset var ranges = []>
	<cfset var entry = "">
	<cfset var parts = []>
	<cfset var range = "">
	<cfset var quality = 1>
	<cfset var parameter = "">
	<cfset var i = 0>
	<cfset var j = 0>
	<cfset var offered = "">
	<cfset var offeredMain = "">
	<cfset var specificity = 0>
	<cfset var matchQuality = 0>
	<cfset var matchSpecificity = 0>
	<cfset var matchPosition = 0>
	<cfset var best = arguments.defaultType>
	<cfset var bestQuality = 0>
	<cfset var bestSpecificity = 0>
	<cfset var bestPosition = 0>

	<cfif len(trim(arguments.acceptHeader)) EQ 0>
		<cfreturn arguments.defaultType>
	</cfif>
	<cfloop list="#arguments.acceptHeader#" delimiters="," index="entry">
		<cfset parts = listToArray(entry, ";")>
		<cfif arrayLen(parts) EQ 0>
			<cfcontinue>
		</cfif>
		<cfset range = lcase(trim(parts[1]))>
		<cfif listLen(range, "/") NEQ 2>
			<cfcontinue>
		</cfif>
		<cfset quality = 1>
		<cfloop from="2" to="#arrayLen(parts)#" index="j">
			<cfset parameter = lcase(replace(parts[j], " ", "", "all"))>
			<cfif left(parameter, 2) EQ "q=">
				<cfset parameter = mid(parameter, 3, len(parameter))>
				<!--- A malformed weight is read as 0, so the range is skipped rather than preferred. --->
				<cfif isNumeric(parameter) AND parameter GTE 0 AND parameter LTE 1>
					<cfset quality = parameter>
				<cfelse>
					<cfset quality = 0>
				</cfif>
			</cfif>
		</cfloop>
		<cfset arrayAppend(ranges, { range = range, quality = quality })>
	</cfloop>

	<cfloop list="#arguments.offeredTypes#" delimiters="," index="offered">
		<cfset offeredMain = listFirst(lcase(trim(offered)), "/")>
		<cfset matchSpecificity = 0>
		<cfset matchQuality = 0>
		<cfset matchPosition = 0>
		<cfloop from="1" to="#arrayLen(ranges)#" index="i">
			<cfif ranges[i].range EQ lcase(trim(offered))>
				<cfset specificity = 3>
			<cfelseif ranges[i].range EQ offeredMain & "/*">
				<cfset specificity = 2>
			<cfelseif ranges[i].range EQ "*/*">
				<cfset specificity = 1>
			<cfelse>
				<cfset specificity = 0>
			</cfif>
			<!--- The most specific range that matches decides the type's weight, so text/turtle;q=0
				excludes Turtle even when */* is accepted. --->
			<cfif specificity GT matchSpecificity>
				<cfset matchSpecificity = specificity>
				<cfset matchQuality = ranges[i].quality>
				<cfset matchPosition = i>
			</cfif>
		</cfloop>
		<cfif matchSpecificity GT 0 AND matchQuality GT 0>
			<cfif matchQuality GT bestQuality
				OR (matchQuality EQ bestQuality AND matchSpecificity GT bestSpecificity)
				OR (matchQuality EQ bestQuality AND matchSpecificity EQ bestSpecificity AND matchPosition LT bestPosition)>
				<cfset best = trim(offered)>
				<cfset bestQuality = matchQuality>
				<cfset bestSpecificity = matchSpecificity>
				<cfset bestPosition = matchPosition>
			</cfif>
		</cfif>
	</cfloop>
	<cfreturn best>
</cffunction>

</cfcomponent>
