<cfset pageTitle = "affiliates">
<!-- 
Affiliates.cfm

Copyright 2019 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<cfinclude template = "/shared/_header.cfm">
<cfoutput>
	<div class="container">
		<div class="row">
			<h3 class="mx-auto" style="margin-top: 4em;">Delivering Data to the Natural Sciences Community &amp; Beyond</h3>
			<div class="flex-column mt-5" style="margin-bottom: 20em;">
				<a href="http://www.gbif.org/" class="px-5">
					<img src="/images/gbiflogo.png" alt="GBIF" class="gbif_logo">
				</a>
				<a href="http://www.idigbio.org/" class="px-4">
					<img src="/images/idigbio.png" alt="herpnet" class="idigbio_logo">
				</a>
				<a href="http://eol.org" class="px-5">
					<img src="/images/eol.png" alt="eol" class="eol_logo">
				</a>
				<a href="http://vertnet.org" class="px-4">
					<img src="/images/vertnet_logo_small.png" alt="Vertnet" class="vertnet_logo">
				</a>
				<a href="https://arctosdb.org/" class="px-5">
					<img src="/images/arctos-logo.png" class="arctos_logo" ALT="[ Link to home page. ]">
				</a>
			</div>
		</div>
	</div>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
