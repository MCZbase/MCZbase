</div><!---end content_box--->
</div><!---end pg_container--->

  <!---   <div id="footerContentBox" class="content_box_footer clearfix">
      <cfif cgi.HTTP_HOST contains "harvard.edu" >
        <div class="footer clearfix">
            <a href="/Collections/index.cfm">Data Providers</a>
            <a href="/info/bugs.cfm">Feedback&#8202;/&#8202;Report Errors</a>
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
    </div>--->
<footer class="footer">
    <div class="fixed-bottom bg-inverse">
    <cfif cgi.HTTP_HOST contains "harvard.edu" >
    
		<div class="row helplinks bg-light border-top">
        	<div class="col-sm-12 col-md-4 col-lg-4 text-center">
        		<a HREF="mailto:bhaley@oeb.harvard.edu" aria-label="email_to_system_admin">System Administrator</a>
			</div>
       		<div class="col-sm-12 col-md-4 col-lg-4 text-center">
        		<a href="/info/bugs.cfm" aria-label="bug_report_link">Feedback&#8202;/&#8202;Report Errors</a>
			</div>
        	<div class="col-sm-12 col-md-4 col-lg-4 text-center">
        		<a href="/Collections/index.cfm" aria-label="data_providers">Data Providers</a> 
        	</div>
		</div>

        <div class="row copyright_background">
            <div class="col-12 col-sm-9 col-md-6 col-xl-3 mx-auto"> <img alt="Harvard Museum of Comparative Zoology Logo" class="media-element file-default file-os-files-medium col-12" src="/shared/images/harvard_museum.png">
				<div class="agreements" style="font-size: smaller;"><a href="/Affiliates.cfm" class="policy_link" aria-label="affiliates_link">Affiliates</a> <a>|</a> <a href="https://mcz.harvard.edu/privacy-policy" class="policy_link" aria-label="privacy_policy_link">Privacy</a> <a>|</a> <a href="https://mcz.harvard.edu/user-agreement" class="policy_link" aria-label="user_agreement_link">User Agreement</a> 
				</div>
            </div>
        </div>
        </div>
        <div class="branding-container">
				<cfoutput>
            <div class="copyright-bottom text-center"><small> Copyright &##x24B8; #Year(now())# The President and Fellows of Harvard College.&nbsp; <a href="http://accessibility.harvard.edu/" class="text-white" aria-label="accessibility_link">Accessibility</a> | <a href="http://www.harvard.edu/reporting-copyright-infringements" class="text-white" aria-label="report_copyright_infringement_link">Report Copyright Infringement</a></small> </div>
				</cfoutput>
        </div>
    </cfif>
    </div>



</footer>
<!---end footer2--->
</div><!---end content_box_footer--->

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

</body></html>
