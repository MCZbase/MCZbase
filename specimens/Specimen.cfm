<!---
Specimen.cfm

Copyright 2019-2021 President and Fellows of Harvard College

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
<!--- this page checks that a provided guid or collection_object_id matches a visible record, then displays the 
 top portion of the specimen details page, header, summary information/type bar, an include of the bulk of the body of the
 specimen details page, then the footer 
 @see /specimens/SpecimenDetailBody.cfm 
--->

<!--- (1) Check the provided guid or collection object id --->
<!--- Set page title to reflect failure condition, if queries succeed it will be changed to reflect specimen record found --->
<cfset pageTitle = "MCZbase Specimen not found.">
<cfif not isdefined("session.sdmapclass") or len(session.sdmapclass) is 0>
	<cfset session.sdmapclass='tinymap'>
</cfif>
<cfoutput>
	<cfhtmlhead text='<script src="#Application.protocol#://maps.googleapis.com/maps/api/js?key=#application.gmap_api_key#&libraries=geometry" type="text/javascript"></script>'>
</cfoutput>

<cfif isdefined("collection_object_id")>
	<cfoutput>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select GUID 
			from <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
			where collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
		</cfquery>
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfset guid = c.GUID>
		<cfheader name="Location" value="/guid/#guid#">
		<cfabort>
	</cfoutput>
</cfif>
<cfif isdefined("guid")>
	<cfset pageTitle = "MCZbase Specimen not found: #guid#">
	<!---  Lookup the GUID, handling several possible variations --->

	<!---  Redirect from explicit Specimen Detail page to  to /guid/ --->
	<cfif cgi.script_name contains "/specimens/Specimen.cfm">
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfheader name="Location" value="/guid/#guid#">
		<cfabort>
	</cfif>
	
	<!---  GUID is expected to be in the form MCZ:collectioncode:catalognumber --->
	<cfif guid contains ":">
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="cresult">
			select collection_object_id 
			from <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
			WHERE
				upper(guid) = <cfqueryparam value='#ucase(guid)#' cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
	<cfelseif guid contains " ">
		<!--- TODO: Do we want to continue supporting guid={collection catalognumber}? --->
		<!--- TODO: NOTE: Existing MCZbase code is broken without trim on cn. --->
		<cfset spos=find(" ",reverse(guid))>
		<cfset cc=left(guid,len(guid)-spos)>
		<cfset cn=trim(right(guid,spos))>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="cfesult">
			select collection_object_id 
			from
				cataloged_item 
				left join collection on cataloged_item.collection_id = collection.collection_id 
			WHERE
				cat_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cn#"> 
				AND lower(collection.collection) = <cfqueryparam value='#lcase(cc)#' cfsqltype="CF_SQL_VARCHAR" >
		</cfquery>
	</cfif>
	<cfif cresult.recordcount EQ 0>
		<!--- Record for this GUID was not found ---> 
		<cfinclude template="/errors/404.cfm">
		<cfabort>
	<cfelse>
		<!--- Record for this GUID was found, make the collection_object_id available to obtain specimen record details. ---> 
		<cfoutput query="c">
			<cfset collection_object_id=c.collection_object_id>
		</cfoutput>
	</cfif>
<cfelse>
	<cfinclude template="/errors/404.cfm">
	<cfabort>
</cfif>

<!--- (2) Display the page header ---> 
<!--- Successfully found a specimen, set the pageTitle and call the header to reflect this, then show the details ---> 
<cfset pageTitle = "MCZbase Specimen Details #guid#">
<cfinclude template="/shared/_header.cfm">
<cfif findNoCase('redesign',Session.gitBranch) EQ 0>
	<cfthrow message="Not for production use yet.">
</cfif>

<!--- (3) Look up summary and type information on the specimen and display the summary/type bar for the record --->
<cfquery name="detail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT DISTINCT
		flattable.collection,
		flattable.collection_id,
		web_link,
		web_link_text,
		flattable.cat_num,
		flattable.collection_object_id as collection_object_id,
		flattable.scientific_name,
		flattable.collecting_event_id,
		flattable.higher_geog,
		flattable.collectors,
		flattable.spec_locality,
		flattable.author_text,
		flattable.verbatim_date,
		flattable.BEGAN_DATE,
		flattable.ended_date,
		flattable.cited_as,
		flattable.typestatuswords,
		MCZBASE.concattypestatus_plain_s(flattable.collection_object_id,1,1,0) as typestatusplain,
		flattable.toptypestatuskind,
		concatparts_ct(flattable.collection_object_id) as partString,
		concatEncumbrances(flattable.collection_object_id) as encumbrance_action,
		flattable.dec_lat,
		flattable.dec_long
<!---	<cfif len(#session.CustomOtherIdentifier#) gt 0>
		,concatSingleOtherId(#session.flatTableName#.collection_object_id,'#session.CustomOtherIdentifier#') as CustomID
		</cfif>--->
	FROM
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> flattable
		left join collection on flattable.collection_id = collection.collection_id
	WHERE
		flattable.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
	ORDER BY
		cat_num
</cfquery>
<cfoutput>
	<cfif detail.recordcount lt 1>
		<!--- It shouldn't be possible to reach here, the logic above should catch this condition. --->
		<cfinclude template="/errors/404.cfm">
		<cfabort>
	</cfif>
	<cfset title="#detail.collection# #detail.cat_num#: #detail.scientific_name#">
	<cfset metaDesc="#detail.collection# #detail.cat_num# (#guid#); #detail.scientific_name#; #detail.higher_geog#; #detail.spec_locality#">
</cfoutput> 
<cfoutput query="detail" group="cat_num">
	<cfset typeName = typestatuswords>
	<!--- handle the edge cases of a specimen having more than one type status --->
	<cfif toptypestatuskind eq 'Primary' > 
		<cfset twotypes = '#replace(typestatusplain,"|","<br>","all")#'>
		<cfset typeName = '<span class="font-weight-bold bg-white pt-0 px-2 pb-1 text-center ml-xl-1">#twotypes# </span>'>
	<cfelseif toptypestatuskind eq 'Secondary' >
		<cfset twotypes= '#replace(typestatusplain,"|","<br>","all")#'>
		<cfset typeName = '<span class="font-weight-bold bg-white pt-0 px-2 pb-1 text-center ml-xl-1">#twotypes# </span>'>
	<cfelse>
		<cfset twotypes= '#replace(typestatusplain,"|","<br>","all")#'>
		<cfset typeName = '<span class="font-weight-bold bg-white pt-0 pb-1 px-2 text-center ml-xl-1"> </span>'>
	</cfif>
	<div class="container-fluid" id="content">
		<cfif isDefined("cited_as") and len(cited_as) gt 0>
			<cfif toptypestatuskind eq 'Primary' >
				<cfset sectionclass="primaryType">
			<cfelseif toptypestatuskind eq 'Secondary' >
				<cfset sectionclass="secondaryType">
			</cfif>
		<cfelse>
			<cfset sectionclass="defaultType">
		</cfif>
		<section class="row #sectionclass#">
			<div class="col-12">
				<cfif isDefined("cited_as") and len(cited_as) gt 0>
					<cfif toptypestatuskind eq 'Primary' >
						<cfset divclass="border-0">
					<cfelseif toptypestatuskind eq 'Secondary' >
						<cfset divclass="no-card">
					</cfif>
				<cfelse>
					<cfset divclass="no-card">
				</cfif>
				<div class="card box-shadow #divclass# bg-transparent">
					<div class="row mx-0">
						<h1 class="col-12 col-md-6 mb-0 h4"> #collection#&nbsp;#cat_num#</h1>
						<div class="float-right col-12 ml-auto col-md-6 my-2 w-auto">
							occurrenceId: <a class="h5" href="https://mczbase.mcz.harvard.edu/guid/#GUID#">https://mczbase.mcz.harvard.edu/guid/#GUID#</a>
						</div>
					</div>
					<div class="row mx-0">
						<div class="col-12 col-md-6">
							<h2 class="mt-0 px-0">
								<a class="font-italic text-dark font-weight-bold" href="##">#scientific_name#</a>&nbsp;<span class="sm-caps h3">#author_text#</span>
							</h2>
						</div>
						<div class="col-12 col-md-6 mt-0 mb-2">
							<cfif isDefined("cited_as") and len(cited_as) gt 0>
								<cfif toptypestatuskind eq 'Primary' >
									<h2 class="h4 mt-0">#typeName#</h2>
								</cfif>
								<cfif toptypestatuskind eq 'Secondary'>
									<h2 class="h4 mt-0">#typeName#</h2>
								</cfif>
							<cfelse>
								<!--- No type name to display for non-type specimens --->
							</cfif>	
						</div>
					</div>
				</div>
			</div>
		</section>
	</div>
	<div class="container-fluid">
		<section class="row" id="resultSetNavigationSection">
			<div class="col-12 px-2">
				<!--- TODO: Cleanup indendation from here on ---> 
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<!--- TODO: This handles navigation through a result set and will need to be refactored with redesign of specimen search/results handling --->
					<form name="incPg" method="post" action="/specimens/Specimen.cfm">
						<input type="hidden" name="collection_object_id" value="#collection_object_id#">
						<input type="hidden" name="suppressHeader" value="true">
						<input type="hidden" name="action" value="nothing">
						<input type="hidden" name="collecting_event_id" value="#detail.collecting_event_id#">
						<cfif isdefined("session.collObjIdList") and len(session.collObjIdList) gt 0>
							<cfset isPrev = "no">
							<cfset isNext = "no">
							<cfset currPos = 0>
							<cfset lenOfIdList = 0>
							<cfset firstID = collection_object_id>
							<cfset nextID = collection_object_id>
							<cfset prevID = collection_object_id>
							<cfset lastID = collection_object_id>
							<cfset currPos = listfind(session.collObjIdList,collection_object_id)>
							<cfset lenOfIdList = listlen(session.collObjIdList)>
							<cfset firstID = listGetAt(session.collObjIdList,1)>
							<cfif currPos lt lenOfIdList>
								<cfset nextID = listGetAt(session.collObjIdList,currPos + 1)>
							</cfif>
							<cfif currPos gt 1>
								<cfset prevID = listGetAt(session.collObjIdList,currPos - 1)>
							</cfif>
							<cfset lastID = listGetAt(session.collObjIdList,lenOfIdList)>
							<cfif lenOfIdList gt 1>
								<cfif currPos gt 1>
									<cfset isPrev = "yes">
								</cfif>
								<cfif currPos lt lenOfIdList>
									<cfset isNext = "yes">
								</cfif>
							</cfif>
						<cfelse>
							<cfset isNext="">
							<cfset isPrev="">
						</cfif>
					</form>
				</cfif>
			</div>					
		</section><!-- end resultSetNavivationSection --->
	</div>
</cfoutput>
<!--- (4) Bulk of the specimen page is provided on SpecimenDetailBody.cfm --->
<cfinclude template="/specimens/SpecimenDetailBody.cfm">
<!--- (4a) QC section, which might better go into SpecimenDetailBody.cfm --->
<cfoutput>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"collops")>
		<div class="container-fluid">
			<section class="row" id="QCSection">
				<div class="col-12 px-2">
					<!---  Include the TDWG BDQ TG2 test integration --->
					<script type='text/javascript' language="javascript" src='/dataquality/js/bdq_quality_control.js'></script>
					<script>
						function runTests() {
							loadNameQC(#collection_object_id#, "", "NameDQDiv");
							loadSpaceQC(#collection_object_id#, "", "SpatialDQDiv");
							loadEventQC(#collection_object_id#, "", "EventDQDiv");
						}
					</script>
					<input type="button" value="QC" class="btn btn-secondary btn-xs" onClick=" runTests(); ">
					<!---  Scientific Name tests --->
					<div id="NameDQDiv"></div>
					<!---  Spatial tests --->
					<div id="SpatialDQDiv"></div>
					<!---  Temporal tests --->
					<div id="EventDQDiv"></div>
				</div>					
				</div>					
			</section><!-- end QCSection --->
		</div>
	</cfif>
</cfoutput>
<!--- (5) Finish up with the page footer --->
<cfinclude template="/shared/_footer.cfm">
