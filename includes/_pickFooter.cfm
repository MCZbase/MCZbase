


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

