</div><!---end content_box--->
</div><!---end pg_container--->

     <div id="footerContentBox" class="content_box_footer clearfix">
      <cfif cgi.HTTP_HOST contains "harvard.edu" >
        <div class="footer clearfix">
            <a href="/Collections/index.cfm">Data Providers</a>
            <a href="/info/bugs.cfm" target="_blank">Feedback&#8202;/&#8202;Report Errors</a>
            <a HREF="mailto:bhaley@oeb.harvard.edu">System Administrator</a>
         </div>
         <div class="footer2 clearfix">
	<div class="copyright">
		<img src="/images/harvard_logo_sm.png" alt="Harvard Shield (logo)" class="harvard_logo">
		<cfoutput>
		<p>Database content: <br> (c) Copyright #Year(now())# President and Fellows of Harvard College <br>
		</cfoutput>
		<a href="https://mcz.harvard.edu/privacy-policy">Privacy Statement</a>
		<span>|</span>
		<a href="https://mcz.harvard.edu/user-agreement">User Agreement</a>
		<span>|</span>
		<a href="http://accessibility.harvard.edu/">Accessibility</a>
		</p>
	</div>


         <div class="databases">
              <a href="http://www.gbif.org/">
                  <img src="/images/gbiflogo.png" alt="GBIF" class="gbif_logo">
              </a>
     		<a href="http://www.idigbio.org/">
                  <img src="/images/idigbio.png" alt="herpnet" class="idigbio_logo">
              </a>
                <a href="http://eol.org">
                  <img src="/images/eol.png" alt="eol" class="eol_logo">
               </a>
                <a href="http://vertnet.org">
                  <img src="/images/vertnet_logo_small.png" alt="Vertnet" class="vertnet_logo">
              </a>
              <a href="https://arctosdb.org/">
               <img src="/images/arctos-logo.png" class="arctos_logo" ALT="[ Link to home page. ]">
             </a>
			<p class="tagline">Delivering Data to the Natural Sciences Community &amp; Beyond</p>
          </div>
    </cfif>
    </div><!---end footer2--->
</div><!---end content_box_footer--->


<!---script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
try {
var pageTracker = _gat._getTracker("<cfoutput>#Application.Google_uacct#</cfoutput>");
pageTracker._trackPageview();
} catch(err) {}</script--->
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

</body></html>
