<!---
shared/component/fileUtilities.cfc
Functions for code that reads files from a directory by a name or path taken from the request.

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
<!--- No method here is access="remote", so none can be invoked over http and no cf_rolecheck is needed. --->
<cfcomponent>
<!---
	resolveFileInDirectory resolve a file name taken from a request to a file directly inside one
	directory, for pages that serve files by name.  File names can't be limited to a character set,
	as some embed usernames, which may contain spaces, dots, @ and non-ASCII characters, so the
	check is structural: the result must be an existing file whose canonical parent is the
	directory, which also excludes symbolic links pointing elsewhere.

	@param directory the directory the file must be in.
	@param fileName the requested file name, which must not contain a path.
	@param allowedExtensions comma separated list of permitted file extensions, without dots.
	@return the canonical path of the file, or an empty string if the name is not acceptable or
		no such file exists.
--->
<cffunction name="resolveFileInDirectory" access="public" returntype="string" output="false">
	<cfargument name="directory" type="string" required="yes">
	<cfargument name="fileName" type="string" required="yes">
	<cfargument name="allowedExtensions" type="string" required="yes">

	<cfset var baseDirectory = createObject("java","java.io.File").init(arguments.directory)>
	<cfset var requestedFile = "">

	<cfif len(arguments.fileName) EQ 0 OR REFind("[/\\\x00-\x1F]", arguments.fileName) GT 0 OR find("..", arguments.fileName) GT 0>
		<cfreturn "">
	</cfif>
	<cfif listLen(arguments.fileName, ".") LT 2 OR NOT listFindNoCase(arguments.allowedExtensions, listLast(arguments.fileName, "."))>
		<cfreturn "">
	</cfif>
	<cfset requestedFile = createObject("java","java.io.File").init(baseDirectory, arguments.fileName).getCanonicalFile()>
	<cfif requestedFile.getParent() NEQ baseDirectory.getCanonicalPath() OR NOT requestedFile.isFile()>
		<cfreturn "">
	</cfif>
	<cfreturn requestedFile.getPath()>
</cffunction>

<!---
	resolveFileUnderDirectory resolve a path taken from a request to an existing file anywhere beneath
	a directory.  The path is normalized lexically, removing any . and .. segments without following
	symbolic links, so files in symbolically linked storage beneath the directory still resolve.
	Normalization is done in CFML: ColdFusion cannot call java.nio.file.Path methods on current
	Java versions, as it reflects on the inaccessible sun.nio.fs implementation class.

	@param directory the directory the file must be beneath.
	@param relativePath the requested path, relative to the directory.
	@return the path of the file, or an empty string if the path leaves the directory, contains a
		control character, or no such file exists.
--->
<cffunction name="resolveFileUnderDirectory" access="public" returntype="string" output="false">
	<cfargument name="directory" type="string" required="yes">
	<cfargument name="relativePath" type="string" required="yes">

	<cfset var normalizedPath = "">
	<cfset var segment = "">
	<cfset var fullPath = "">

	<cfif len(arguments.relativePath) EQ 0 OR REFind("[\x00-\x1F]", arguments.relativePath) GT 0>
		<cfreturn "">
	</cfif>
	<!--- list functions skip empty elements, so repeated slashes collapse --->
	<cfloop list="#arguments.relativePath#" delimiters="/" index="segment">
		<cfif segment EQ "..">
			<cfif listLen(normalizedPath, "/") EQ 0>
				<cfreturn "">
			</cfif>
			<cfset normalizedPath = listDeleteAt(normalizedPath, listLen(normalizedPath, "/"), "/")>
		<cfelseif segment NEQ ".">
			<cfset normalizedPath = listAppend(normalizedPath, segment, "/")>
		</cfif>
	</cfloop>
	<cfif len(normalizedPath) EQ 0>
		<cfreturn "">
	</cfif>
	<cfset fullPath = REReplace(arguments.directory, "/+$", "") & "/" & normalizedPath>
	<cfif NOT createObject("java","java.io.File").init(fullPath).isFile()>
		<cfreturn "">
	</cfif>
	<cfreturn fullPath>
</cffunction>

<!---
	attachmentDisposition build a Content-Disposition header value that makes the browser save a
	file under the given name, with quotes and control characters replaced in the plain filename
	and the full name, including any non-ASCII characters, in the RFC 5987 filename* parameter.

	@param fileName the name to offer for the saved file.
	@return the header value.
--->
<cffunction name="attachmentDisposition" access="public" returntype="string" output="false">
	<cfargument name="fileName" type="string" required="yes">

	<cfset var plainName = REReplace(REReplace(arguments.fileName, '[^\x20-\x7E]', "_", "all"), '["\\]', "_", "all")>
	<cfset var encodedName = replace(encodeForURL(arguments.fileName), "+", "%20", "all")>

	<cfreturn 'attachment; filename="#plainName#"; filename*=UTF-8''''#encodedName#'>
</cffunction>
</cfcomponent>
