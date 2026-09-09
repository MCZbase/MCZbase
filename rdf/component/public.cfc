<!---
public.cfc

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
<!--- Escaping for the values MCZbase writes into its linked data serializations.  Shared by
	rdf/Occurrence.cfm, rdf/Taxon.cfm, rdf/MaterialSample.cfm and annotations/showAnnotation.cfm,
	each of which emits the same record values as JSON-LD, Turtle and RDF/XML.

	Instantiate rather than include:

		<cfset variables.rdfEscape = createObject("component","rdf.component.public")>

	The rdf/ templates set their content type with cfheader, which does not reset the output
	buffer, so whitespace from an include would land in a document that has to parse.
	createObject emits nothing.  includes/functionLib.cfm is not an available home for these
	because it includes /shared/loginFunctions.cfm in turn, which starts a session, and these
	pages answer anonymous requests routed through errors/missing.cfm.

	Deviation from the convention for a component of this name, stated deliberately: these
	methods are access="public", where every other {concept}/component/public.cfc is remote
	throughout.  Those hold AJAX endpoints for a public search page; these are escaping utilities
	with no caller outside ColdFusion, and publishing them as remote would add three HTTP
	endpoints to the anonymous surface for no purpose.

	There is no escapeForXml: xmlFormat() is built in and is what the RDF/XML branches use.
--->
<cfcomponent>

	<!--- Escape text for a JSON string literal, per RFC 8259: the reverse solidus and the
		quotation mark, then the control characters, which a JSON string may not carry raw.  The
		surrounding quotes are left to the caller, so a value stays a JSON string rather than being
		retyped as a number, which is what serializeJSON does to one that happens to look numeric.
		@param inStr the text to escape.
		@return the text with backslash, quote and control characters escaped. --->
	<cffunction name="escapeForJson" returntype="string" access="public" output="false">
		<cfargument name="inStr" type="string" required="yes">
		<cfset var outStr = arguments.inStr>
		<cfset outStr = replace(outStr,"\","\\","all")>
		<cfset outStr = replace(outStr,'"','\"',"all")>
		<cfset outStr = replace(outStr,chr(8),"\b","all")>
		<cfset outStr = replace(outStr,chr(9),"\t","all")>
		<cfset outStr = replace(outStr,chr(10),"\n","all")>
		<cfset outStr = replace(outStr,chr(12),"\f","all")>
		<cfset outStr = replace(outStr,chr(13),"\r","all")>
		<cfset outStr = rereplace(outStr,"[[:cntrl:]]","","all")>
		<cfreturn outStr>
	</cffunction>

	<!--- Escape text for a Turtle quoted literal.  Turtle's STRING_LITERAL_QUOTE permits exactly
		the escapes JSON does for these characters, \\ \" \b \t \n \f \r, and forbids a raw control
		character just as JSON does, so the two escape sets coincide here and this defers rather
		than restating them.  Named separately so each call site says which syntax it is writing.
		@param inStr the text to escape.
		@return the text escaped for a double quoted Turtle literal.
		@see escapeForJson --->
	<cffunction name="escapeForTurtle" returntype="string" access="public" output="false">
		<cfargument name="inStr" type="string" required="yes">
		<cfreturn escapeForJson(arguments.inStr)>
	</cffunction>

	<!--- Percent encode the characters an IRI reference may not contain, for a value written
		between angle brackets in Turtle or into an rdf:about.  Turtle's IRIREF excludes the space,
		the angle brackets, the quotation mark, brace, bracket, pipe, caret, backtick and
		backslash, and any control character.  Everything else is left alone, so a colon or a
		solidus still delimits the IRI as it should, which is why this is not encodeForURL.
		@param inStr the IRI to escape.
		@return the IRI with the excluded characters percent encoded. --->
	<cffunction name="escapeForIri" returntype="string" access="public" output="false">
		<cfargument name="inStr" type="string" required="yes">
		<cfset var outStr = arguments.inStr>
		<cfset outStr = rereplace(outStr,"[[:cntrl:]]","","all")>
		<cfset outStr = replace(outStr,"%","%25","all")>
		<cfset outStr = replace(outStr,"\","%5C","all")>
		<cfset outStr = replace(outStr," ","%20","all")>
		<cfset outStr = replace(outStr,"<","%3C","all")>
		<cfset outStr = replace(outStr,">","%3E","all")>
		<cfset outStr = replace(outStr,'"',"%22","all")>
		<cfset outStr = replace(outStr,"{","%7B","all")>
		<cfset outStr = replace(outStr,"}","%7D","all")>
		<cfset outStr = replace(outStr,"|","%7C","all")>
		<cfset outStr = replace(outStr,"^","%5E","all")>
		<cfset outStr = replace(outStr,chr(96),"%60","all")>
		<cfreturn outStr>
	</cffunction>

</cfcomponent>
