

<!---
<hr>
<center>
<a href="home.cfm">Home</a>&nbsp;|&nbsp;<a href="Specimensearch.cfm">Specimen&nbsp;Search</a>&nbsp|&nbsp<a href="PublicationSearch.cfm">Publication&nbsp;Search</a>&nbsp|&nbsp <a href="ProjectSearch.cfm">Project&nbsp;Search</a>&nbsp|&nbsp <a href="/Taxa.cfm">Taxonomy Search</a>
--->


<cfif not isdefined("title")>
	<cfset title = "MCZbase Data Pick">
</cfif>
<cftry>
<cfhtmlhead text="<title>#variables.title#</title>">
<cfcatch>
  <!--- exception thrown if headers no longer writable e.g. cfflush has been issued by page --->
</cfcatch>
</cftry>

</center></tr></td></table>
</body>
</html>

