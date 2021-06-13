<!---
_footer.cfm

Copyright 2021 President and Fellows of Harvard College

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
<footer class="footer">
    <div class="fixed-bottom bg-inverse">
    <cfif cgi.HTTP_HOST contains "harvard.edu" >
    
		<div class="row helplinks bg-light border-top">
        	<div class="col-sm-12 col-md-4 col-lg-4 text-center">
        		<a HREF="mailto:bhaley@oeb.harvard.edu" aria-label="email_to_system_admin">System Administrator</a>
			</div>
       		<div class="col-sm-12 col-md-4 col-lg-4 text-center">
        		<a href="/info/bugs.cfm" aria-label="bug_report_link" target="_blank">Feedback&#8202;/&#8202;Report Errors</a>
			</div>
        	<div class="col-sm-12 col-md-4 col-lg-4 text-center">
        		<a href="/Collections/index.cfm" aria-label="data_providers">Data Providers</a> 
        	</div>
		</div>

        <div class="row copyright_background">
            <div class="col-12 col-md-6 col-xl-3 mx-auto"> <img alt="Harvard Museum of Comparative Zoology Logo" class="media-element file-default file-os-files-medium col-12" src="/shared/images/harvard_museum.png">
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
</body></html>
