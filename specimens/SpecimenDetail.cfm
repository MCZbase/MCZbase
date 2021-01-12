<!---
SpecimenDetail.cfm

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

--->

<!---  Set page title to reflect failure condition, if queries succeed it will be changed to reflect specimen record found  --->
<cfset pageTitle = "MCZbase Specimen not found.">
<cfif isdefined("collection_object_id")>
	<cfoutput>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select GUID 
			from #session.flatTableName# 
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

	<!---  Redirect from explicit SpecimenDetail page to  to /guid/ --->
	<cfif cgi.script_name contains "/specimens/SpecimenDetail.cfm">
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfheader name="Location" value="/guid/#guid#">
		<cfabort>
	</cfif>
	
	<!---  GUID is expected to be in the form MCZ:collectioncode:catalognumber --->
	<cfif guid contains ":">
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="cresult">
			select collection_object_id from
				#session.flatTableName#
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
				cataloged_item,
				collection
			WHERE
				cataloged_item.collection_id = collection.collection_id 
				AND cat_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cn#"> 
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

<!--- Successfully found a specimen, set the pageTitle and call the header to reflect this, then show the details ---> 
<cfset pageTitle = "MCZbase Specimen Details #guid#">
<cfinclude template="/shared/_header.cfm">

<cfquery name="detail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT DISTINCT
		#session.flatTableName#.collection,
		#session.flatTableName#.collection_id,
		web_link,
		web_link_text,
		#session.flatTableName#.cat_num,
		#session.flatTableName#.collection_object_id as collection_object_id,
		#session.flatTableName#.scientific_name,
		#session.flatTableName#.collecting_event_id,
		#session.flatTableName#.higher_geog,
		#session.flatTableName#.collectors,
		#session.flatTableName#.spec_locality,
		#session.flatTableName#.author_text,
		#session.flatTableName#.verbatim_date,
		#session.flatTableName#.BEGAN_DATE,
		#session.flatTableName#.ended_date,
		#session.flatTableName#.cited_as,
		#session.flatTableName#.typestatuswords,
		MCZBASE.concattypestatus_plain_s(#session.flatTableName#.collection_object_id,1,1,0) as typestatusplain,
		#session.flatTableName#.toptypestatuskind,
		concatparts_ct(#session.flatTableName#.collection_object_id) as partString,
		concatEncumbrances(#session.flatTableName#.collection_object_id) as encumbrance_action,
		#session.flatTableName#.dec_lat,
		#session.flatTableName#.dec_long
<!---		<cfif len(#session.CustomOtherIdentifier#) gt 0>
			,concatSingleOtherId(#session.flatTableName#.collection_object_id,'#session.CustomOtherIdentifier#') as CustomID
		</cfif>--->
	FROM
		#session.flatTableName#,
		collection
	WHERE
		#session.flatTableName#.collection_id = collection.collection_id AND
		#session.flatTableName#.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
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
	<cfif toptypestatuskind eq 'Primary' > 
		<cfset twotypes = '#replace(typestatusplain,"|","<br>","all")#'>
		<cfset typeName = '<span class="font-weight-bold bg-white pt-0 px-2 pb-1 text-center ml-xl-1">#twotypes# </span>'>
	<cfelseif toptypestatuskind eq 'Secondary' >
		<cfset  twotypes= '#replace(typestatusplain,"|","<br>","all")#'>
		<cfset typeName = '<span class="font-weight-bold bg-white pt-0 px-2 pb-1 text-center ml-xl-1">#twotypes#  </span>'>
	<cfelse>
		<cfset  twotypes= '#replace(typestatusplain,"|","<br>","all")#'>
		<cfset typeName = '<span class="font-weight-bold bg-white pt-0 pb-1 px-2 text-center ml-xl-1"> </span>'>
	</cfif>

	<!--- TODO: Cleanup indendation from here on ---> 
<div class="container-fluid mb-2">
	<cfif isDefined("cited_as") and len(cited_as) gt 0>
		<cfif toptypestatuskind eq 'Primary' >
			<section class="row mb-2 primaryType" >
		</cfif>
		<cfif toptypestatuskind eq 'Secondary' >
			<section class="row mb-2 secondaryType">
		</cfif>
	<cfelse>
		<section class="row mb-2 defaultType">
	</cfif>
	<div class="col-12">
			<cfif isDefined("cited_as") and len(cited_as) gt 0>
				<cfif toptypestatuskind eq 'Primary' >
					<div class="card box-shadow border-0 bg-transparent">
				</cfif>
				<cfif toptypestatuskind eq 'Secondary' >
					<div class="card box-shadow no-card bg-transparent">
				 </cfif>
			<cfelse>
					<div class="card box-shadow no-card bg-transparent">
			</cfif>
		<div class="row">
			<h1 class="col-12 col-md-6 mb-0 h4"> #collection#&nbsp;#cat_num#</h1>
		</div>
		<div class="row">
				<div class="col-12 col-md-6">
				<h2 class="mt-0 px-0"><a class="font-italic text-dark font-weight-bold" href="##">#scientific_name#</a>&nbsp;<span class="sm-caps h3">#author_text#</span></h2>
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
				<!--- No special color background for non-type specimens -- default background is gray --->
				</cfif>	
			</div>
			</div>
		</div>
	</div>

			
</section>
			</div>

<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
        <form name="incPg" method="post" action="/specimens/SpecimenDetail.cfm">
            <input type="hidden" name="collection_object_id" value="#collection_object_id#">
            <input type="hidden" name="suppressHeader" value="true">
            <input type="hidden" name="action" value="nothing">
            <input type="hidden" name="Srch" value="Part">
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
</cfoutput>
<cfinclude template="/specimens/SpecimenDetailBody.cfm">
<cfinclude template="/shared/_footer.cfm">
