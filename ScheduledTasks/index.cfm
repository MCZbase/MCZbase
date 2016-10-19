<cfinclude template="/includes/_header.cfm">
    <div style="width: 32em; margin:0 auto;padding: 2em 0 4em 0;">
        <h2 class="wikilink">Scheduled Tasks</h2>
         <div style="width: 32em; margin:2em auto 4em auto;padding: .5em 2em .5em 2em;border: 1px solid gray;background-color: #f8f8f8">
        
<cfdirectory action="list" directory="#Application.webDirectory#/ScheduledTasks" name="d" sort="name ASC">
<cfoutput>
	<cfloop query="d">
        <p><a href="#name#">#name#</a></p>
	</cfloop>
</cfoutput>
    </div>
    </div>
<cfinclude template="/includes/_footer.cfm">