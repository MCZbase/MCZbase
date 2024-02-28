<cfoutput>
<cfinclude template="/includes/_header.cfm">
<cfdirectory directory="#application.webDirectory#" action="list" name="q" sort="name" recurse="false" type="dir">
<cfset variables.fileName="#Application.webDirectory#/robots.txt">
<cfset variables.encoding="US-ASCII">
<cfscript>
	variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
	variables.joFileWriter.writeLine('User-agent: *');
	variables.joFileWriter.writeLine('Disallow: /cfide/');
	variables.joFileWriter.writeLine('Disallow: /CFIDE/');
</cfscript>	
<cfset allowedDirectories="Collections">
<cfquery name="portals" datasource="cf_dbuser">
	select portal_name from cf_collection
</cfquery>
<cfset allowedDirectories=listappend(allowedDirectories,valuelist(portals.portal_name))>
<cfloop query="q">
	<cfif not listfindnocase(allowedDirectories,name)>
		<cfscript>
			a='Disallow: /' & name & '/';
			variables.joFileWriter.writeLine(a);
		</cfscript>		
	</cfif>
</cfloop>
<cfdirectory directory="#application.webDirectory#" action="list" name="q" sort="name" recurse="false" type="file">
<cfset allowedFileList="favicon.ico,robots.txt">
<cfloop query="q">
	<cfquery name="current" datasource="cf_dbuser">
		select max(c) as maxc
		from 
			( 
			select count(*) c from cf_form_permissions 
			where form_path = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="/#name#">
				 and role_name='public'
 			)
	</cfquery>
	<cfif current.maxc is 0 and right(name,7) is not ".xml.gz" and not listfindnocase(allowedFileList,name)>
		<cfscript>
			a='Disallow: /' & name;
			variables.joFileWriter.writeLine(a);
		</cfscript>		
	</cfif>
</cfloop>
<cfscript>
	variables.joFileWriter.writeLine('Disallow: /digir/');
	variables.joFileWriter.writeLine('Sitemap: ' & application.serverRootUrl & '/sitemapindex.xml.gz');
	variables.joFileWriter.close();
</cfscript>
</cfoutput>
