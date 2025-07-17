<cfset pageTitle = "Check Media Files">
<cfinclude template="/shared/_header.cfm">

<cfset targetDirectory = "specimen_images">

<cffunction name="makeRecord" output="true" returntype="void">
	<cfargument name="path" type="string" required="true">
	<cfargument name="name" type="string" required="true">

	<cfquery name="checkMedia" datasource="uam_god">
		SELECT count(*) AS ct
		FROM media
		WHERE media_uri = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Application.serverRootUrl#/#path#/#name#">
	</cfquery>
	<cfquery name="checkPreview" datasource="uam_god">
		SELECT count(*) AS ct
		FROM media
		WHERE preview_uri = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Application.serverRootUrl#/#path#/#name#">
	</cfquery>

	<cfquery name="isUsed" datasource="uam_god">
		INSERT INTO media_check (
			path,
			in_media_uri,
			in_preview_uri,
			last_check
		) VALUES (
			<cfqueryparam value="#path#/#name#" cfsqltype="CF_SQL_VARCHAR">,
			<cfqueryparam value="#checkMedia.ct#" cfsqltype="CF_SQL_DECIMAL">,
			<cfqueryparam value="#checkPreview.ct#" cfsqltype="CF_SQL_DECIMAL">,
			sysdate
		)
	</cfquery>
	<cfif checkMedia.ct is 0 and checkPreview.ct is 0>
		<li class="text-danger">#Application.serverRootUrl#/#path#/#name# is not in media table.</li>
	<cfelse>
		<li>
			(media_uri:#checkMedia.ct#, preview_uri:#checkPreview.ct#)
			application.serverRootUrl#/#path#/#name# 
		</li>
	</cfif>
</cffunction>

<cffunction name="processDirectoryRecursive" output="true" returntype="void">
	<cfargument name="uriBasePath" type="string" required="true">
	<cfargument name="currentSubPath" type="string" required="false" default="">
	<cfargument name="level" type="numeric" required="false" default="0">
	
	<cfset var fullFilesystemPath = Application.webDirectory>
	<cfset var fullUriPath = uriBasePath>
	
	<cfif len(currentSubPath)>
		<cfset fullFilesystemPath = fullFilesystemPath & "/" & currentSubPath>
		<cfset fullUriPath = uriBasePath & "/" & currentSubPath>
	</cfif>
	
	<cftry>
		<cfdirectory action="list" directory="#fullFilesystemPath#" name="dirContents">
	   
		<ul>
		<cfloop query="dirContents">
			<cfif dirContents.type is "File">
				<!--- makeRecord expects (path, name) where path is the URI path without the filename --->
				<cfset makeRecord(fullUriPath, dirContents.name)>
			<cfelse>
					<li>#dirContents.name# (Directory)</li>
				<cfset var newSubPath = "">
				<cfif len(currentSubPath)>
					<cfset newSubPath = currentSubPath & "/" & dirContents.name>
				<cfelse>
					<cfset newSubPath = dirContents.name>
				</cfif>
				<cfset processDirectoryRecursive(filesystemBasePath, uriBasePath, newSubPath, level + 1)>
			</cfif>
		</cfloop>
		</ul>
		
		<cfcatch type="any">
				<!--- consume error --->
		</cfcatch>
	</cftry>
</cffunction>

<main id="content">
	<section class="container-fluid mb-3">
		<div class="row mx-0 mb-3">
			<h1>#pageTitle#</h1>
			<p>Checking media files in <code>#targetDirectory#</code> directory.</p>
			<cfthread  name="checkMediaThread">
				<cfoutput>
					<cfset processDirectoryRecursive("#Application.webDirectory#/#targetDirectory#", targetDirectory,0)>
				</cfoutput>
			</cfthread>
			<cfthread action="join" name="checkMediaThread">
			#checkMediaThread.output#
		</div>
	</section>
</main>

<cfinclude template="/shared/_footer.cfm">
