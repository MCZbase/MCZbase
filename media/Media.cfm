<!--
media/Media.cfm

media record editor

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2022 President and Fellows of Harvard College

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
<cfinclude template="/media/component/search.cfc" runOnce="true"><!--- for autocompletes --->
<cfinclude template="/media/component/public.cfc" runOnce="true"><!--- for media widget --->

<!---<cfif NOT isdefined("action")>
	<cfset action = "edit">
</cfif>--->
<cfset pageTitle = "Manage Media">
<!---<cfswitch expression="#action#">
	<cfcase value="new">
		<cfset pageTitle = "Create Media Record">
	</cfcase>
	<cfcase value="edit">
		<cfset pageTitle = "Edit Media Record">
		<cfif NOT isDefined("media_id") OR len(media_id) EQ 0>
			
			<cflocation url="/media/findMedia.cfm" addtoken="false">
		</cfif>
	</cfcase>
</cfswitch>--->

<cfinclude template = "/shared/_header.cfm">
<cfquery name="ctmedia_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select media_relationship from ctmedia_relationship order by media_relationship
</cfquery>
<cfquery name="ctmedia_label" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select media_label from ctmedia_label order by media_label
</cfquery>
<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select media_type from ctmedia_type order by media_type
</cfquery>
<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select mime_type from ctmime_type order by mime_type
</cfquery>
<cfquery name="ctmedia_license" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select media_license_id,display media_license from ctmedia_license order by media_license_id
</cfquery>
<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select auto_protocol, auto_host, auto_path,media_uri from media where media_id = any(3815012,287808,6520,8085,1336734,171526,229213,1360339,3804325)
</cfquery>
<!---------------------------------------------------------------------------------------------------->


		<cfoutput>

		
			
		<section class="jumbotron pb-3 bg-white text-center">
			<div class="container">
				<h1 class="jumbotron-heading">Create Media Records</h1>
				<p class="lead text-muted">
					Select the stored type of the media you want to add to MCZbase. Each storage type has a different pathway to create a media record.
				</p>
			</div>
		</section>
		<div class="album pb-5 bg-light">
			<div class="container">
				<div class="row">
					<div class="col-md-4 px-xl-5 pb-5">
						<h2 class="text-center pt-3">Shared Drive</h2>
						<div class="card mb-4 box-shadow bg-lt-gray border-lt-gray ">
							<div class="grider col-12 px-0">
								<div class="grid-item-2 col-6 px-0">
									<img src="	http://mczbase.mcz.harvard.edu/specimen_images/malacology/large/393717_Haliotis_ovina_03.JPG" class="w-100"/>
								</div>
								<div class="grid-item-2 col-6 px-0">
									<img src="https://mczbase.mcz.harvard.edu/specimen_images/specialcollections/large/SC10_P_griseum_book-2015_03.jpg" class="w-100"/>
								</div>
								<div class="grid-item-1 col-3 px-0 bg-black" style="clear:both;">
									<img src="https://mczbase.mcz.harvard.edu/specimen_images/fish/large/11399_Paralichthys_patagonius_blind_LT.jpg" class="w-100 pb-1"/>
									<img src="https://mczbase.mcz.harvard.edu/specimen_images/herpetology/large/OBS38_L_lunatus_lunatus_1of1.jpg" class="w-100"/>
								</div>
								<div class="grid-item-2 col-5 px-0">
									<img src="https://mczbase.mcz.harvard.edu/specimen_images/mammalogy/large/58012_Canis_familiaris_hl2.jpg" class="w-100 pr-1 pl-0"/>
								</div>
								<div class="grid-item-2 col-4 px-0">
									<img src="https://mczbase.mcz.harvard.edu/specimen_images/entomology/large/MCZ-ENT00000011_Cicindela_cyanella_hed.jpg" class="w-100 pr-md-1 pl-md-1 pl-xl-1 pr-xl-2 pl-1 pr-2"/>
								</div>
								<div class="grid-item-2 col-3 px-0" style="clear: both;">
									<img src="https://mczbase.mcz.harvard.edu/specimen_images/ornithology/large/MCZ3723_Pandion_haliaetus_4.jpg" class="w-100"/>
								</div>
								<div class="grid-item-2 col-3 px-0">
									<img src="https://mczbase.mcz.harvard.edu/specimen_images/vertpaleo/large/MCZ_VPF-5318_Lepidosteus_simplex_skel.jpg" class="w-100"/>
								</div>
								<div class="grid-item-2 col-3 px-0">
									<img src="https://iiif.mcz.harvard.edu/iiif/3/1360339/full/!2000,2000/0/default.jpg" class="w-100"/>
								</div>
								<div class="grid-item-2 col-3 px-0">
									<img src="https://mczbase.mcz.harvard.edu/specimen_images/invertebrates/large/AST-41_2_Archaster_Agassizii_ventral.jpeg" class="w-100"/>
								</div>
							</div>
							<div class="card-body bg-white p-4">
								<p class="card-text">The shared drive is where MCZ files are stored. It located in a facility managed by Harvard. Map to the drive or use Filezilla to transfer files to the shared drive.</p>
								<div class="d-flex justify-content-between align-items-center">
									<div class="btn-group">
										<button type="submit" class="btn btn-xs btn-primary px-5" onclick="window.location.href='/media/SharedDrive.cfm';" addtoken="false">Start</button>
									</div>
								</div>
							</div>
						</div>
					</div>
					<div class="col-md-4 px-xl-5 pb-5">
						<h2 class="text-center pt-3">External Link</h2>
						<div class="card mb-4 box-shadow bg-lt-gray border-lt-gray">
							<img class="card-img-top" data-src="https://mczbase.mcz.harvard.edu/specimen_images/specialcollections/large/mcz_newsletter_BHL.jpg" alt="external file placeholder image" style="width: 100%; display: block;" src="https://mczbase.mcz.harvard.edu/specimen_images/specialcollections/large/mcz_newsletter_BHL.jpg" data-holder-rendered="true">
							<div class="card-body bg-white p-4">
								<p class="card-text">External files could be stored anywhere outside of Harvard's facilities. Example:  Biodiversity Heritage Library. Permission must be on file before uploading.</p>
								<div class="d-flex justify-content-between align-items-center">
									<div class="btn-group">
										<button type="submit" class="btn btn-xs btn-primary px-5" onClick="" addtoken="false">Start</button>
									</div>
								</div>
							</div>
						</div>
					</div>
					<div class="col-md-4 px-xl-5 pb-5">
						<h2 class="text-center pt-3">Submit to DSpace</h2>
						<div class="card mb-4 box-shadow bg-lt-gray border-lt-gray">
							<img class="card-img-top" data-src="https://iiif.mcz.harvard.edu/iiif/3/3823370/full/max/0/default.jpg" alt="DSpace logo" style="width: 100%; display: block;background-color: gray;padding-bottom: 1px;" src="https://iiif.mcz.harvard.edu/iiif/3/3823370/full/max/0/default.jpg" data-holder-rendered="true">
							<div class="card-body bg-white p-4">
								<p class="card-text">DSpace is for larger files such as tif and/or for batch loading files. Metadata is submitted with the file and is kept in the media record and on DSpace.</p>
								<div class="d-flex justify-content-between align-items-center">
									<div class="btn-group">
										<button type="button" class="btn btn-xs btn-primary px-5">Start</button>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
			

		</cfoutput>


<cfinclude template="/shared/_footer.cfm">
