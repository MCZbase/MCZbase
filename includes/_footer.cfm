<cfif cgi.HTTP_HOST contains "database.museum">
  <table id="_footerTable">
	<tr>
		<td align="left" valign="middle">
		 <a href="/home.cfm">
		    <img SRC="/images/arctos.gif" BORDER=0 ALT="[ Link to home page. ]">
			</a>
		 </td>
		<td>
			<ul>
				<li>
					<a href="/Collections/index.cfm"><font size="-1">Data Providers</font></a>
				</li>
				<li>
					<a HREF="/contact.cfm"><font size="-1">Report a bug or request support</font></a>
				</li>
			</ul>
		</td>
	</tr>
</table>
<cfelseif cgi.HTTP_HOST contains "harvard.edu" >
	<br>
<table width="95%" style="margin-top: 1em;margin-left: 5%" id="_footerTable">
	  	<tr>
	    	<td align="center" nowrap><a href="/Collections/index.cfm"><FONT size="-1">Data Providers</FONT></a></td>
	    	<td align="center" nowrap><a href="/info/bugs.cfm"><FONT size="-1">Feedback&#8202;/&#8202;Report Errors</FONT></a></td>
	    	<td align="center" nowrap><a HREF="mailto:bhaley@oeb.harvard.edu"><FONT size="-1">System Administrator</FONT></a></td>
	  	</tr>
	</table>
   <table width="100%" style="border-top: 3px solid #d3d3d3;margin-top: 2em;">
		<tr>
		  <td rowspan="3" align="right" valign="bottom"><a href="/home.cfm"><img src="/images/arctos.gif" width="49" height="53" border="0" ALT="[ Link to home page. ]"></a></td>
		  <td >&nbsp;</td>
		  <td >&nbsp;</td>
		  <td >&nbsp;</td>
		  <td nowrap align="center" >&nbsp;</td>
		  <td align="center" >&nbsp;</td>
		  <td align="center" nowrap style="padding-top: 1em;"><FONT size="-1">Distributed Databases: </FONT></td>
		</tr>
		<tr>
		  <td>&nbsp;</td>
		  <td>&nbsp;</td>
		  <td nowrap >&nbsp;</td>
		  <td nowrap align="center" >&nbsp;</td>
		  <td align="center">&nbsp;</td>
		  <td align="center"><a href="http://www.herpnet.org/"><img src="/images/HerpNET_superbaby_logo.jpg" alt="herpnet" width="47" height="20" border="0"></a> &nbsp; <a href="http://ornisnet.org">
		<img src="/images/ornislogo_superbaby.jpg" width="47" height="20" border="0" alt="ornis"></a></td>
		</tr>
		<tr>
		  <td nowrap valign="bottom">&nbsp;</td>
		  <td nowrap valign="bottom"> <FONT size="-1"> A collaboration with multiple natural history collections</FONT></td>
		  <td nowrap>&nbsp;</td>
		  <td nowrap align="center" >&nbsp;</td>
		  <td align="center">&nbsp;</td>
		  <td align="center"><a href="http://manisnet.org">
		<img src="/images/manis_banner_superbaby.jpg" alt="manis" width="145" height="20" border="0"></a></td>
		</tr>
    </table>
<br>
<ul style="font-size: smaller">
	<li>Database content &copy; Copyright 2016 President and Fellows of Harvard College</li>
	<li><a href="http://www.mcz.harvard.edu/privacy/index.html">Privacy Statement</a></li>
	<li><a href="http://www.mcz.harvard.edu/privacy/user.html">User Agreement</a></li>
</ul>
    <P>&nbsp;</P>
<cfelse>
	<br>
	 <table width="95%" style="margin-left:5%;">
	  	<tr>
	    	<td align="center" nowrap><a href="/Collections/index.cfm"><FONT size="-1">Data Providers</FONT></a></td>
	    	<td align="center" nowrap><a href="/info/bugs.cfm"><FONT size="-1">Feedback&#8202;/&#8202;Report Errors</FONT></a></td>
	    	<td align="center" nowrap>
		    	<cfoutput><a HREF="/contact.cfm"><FONT size="-1">Contact Us</FONT></a></cfoutput>
			</td>
	  	</tr>
	</table>
</cfif>
<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
try {
var pageTracker = _gat._getTracker("<cfoutput>#Application.Google_uacct#</cfoutput>");
pageTracker._trackPageview();
} catch(err) {}</script>
<cfif not isdefined("title")>
	<cfset title = "Database Access">
</cfif>
<cfif not isdefined("metaDesc") and isdefined("session.meta_description")>
	<cfif isdefined("session.meta_description")>
		<cfset metaDesc = session.meta_description>
	<cfelse>
		<cfset metadesc="">
	</cfif>
</cfif>
<cftry>
	<cfhtmlhead text='<title>#title#</title>
	<meta name="description" content="#metaDesc#">
	'>
	<cfcatch type="template">
	</cfcatch>
</cftry>
</body>
</html>
