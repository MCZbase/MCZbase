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
				<div class="col-sm-12 col-md-6 text-center">
					<a href="https://mcz.harvard.edu/acknowledgment-harmful-content" class="policy_link" aria-label="acknowledgment of harmful content">Acknowledgment of Harmful Content</a>
				</div>
				<div class="col-sm-12 col-md-6 text-center">
					<a href="/info/bugs.cfm" aria-label="feedback/report errors" target="_blank">Feedback&#8202;/&#8202;Report Errors</a>
				</div>
			</div>
			<div class="row copyright_background">
				<div class="col-8 col-md-5 col-lg-4 col-xl-3 pl-4 pr-0 mx-auto">
					<img alt="Harvard Museum of Comparative Zoology Logo" class="media-element file-default file-os-files-medium col-12 pl-4 pr-0" src="/shared/images/harvard_museum.png">
					<div class="agreements text-center small mt-0">
						<a href="https://mcz.harvard.edu/privacy-policy" class="policy_link d-inline-block px-2" aria-label="privacy">Privacy</a> 
						<a href="https://mcz.harvard.edu/user-agreement" class="policy_link d-inline-block px-2" aria-label="user agreement">User Agreement</a> 
					
					</div>
				</div>
			</div>
			<div class="branding-container">
				<div class="copyright-bottom text-center">
					<small>
						<cfoutput>
							Copyright &##x24B8; #Year(now())# The President and Fellows of Harvard College.&nbsp; 
						</cfoutput>
						<a href="http://accessibility.harvard.edu/" class="text-white" aria-label="accessibility">Accessibility</a> | <a href="http://www.harvard.edu/reporting-copyright-infringements" class="text-white" aria-label="report copyright infringement">Report Copyright Infringement</a>
					</small> 
				</div>
			</div>
		</cfif>
	</div>
</footer>
<a id="back2Top" title="Back to top" href="#">&#10148;</a>
</body>
</html>
