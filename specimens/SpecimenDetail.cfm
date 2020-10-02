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
		concatparts(#session.flatTableName#.collection_object_id) as partString,
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
		<cfset typeName = '<span class="font-weight-bold bg-white pb-1 py-1 px-2 text-center mt-0 mt-md-3 w-100 d-block float-right">#twotypes# </span>'>
	<cfelseif toptypestatuskind eq 'Secondary' >
		<cfset  twotypes= '#replace(typestatusplain,"|","<br>","all")#'>
		<cfset typeName = '<span class="font-weight-bold bg-white pb-1 py-1 px-2 text-center mt-0 mt-md-3 w-100 d-block float-right">#twotypes#  </span>'>
	<cfelse>
		<cfset  twotypes= '#replace(typestatusplain,"|","<br>","all")#'>
		<cfset typeName = '<span class="font-weight-bold bg-white pb-1 py-1 px-2 text-center mt-0 mt-md-3 w-100 d-block float-right"> </span>'>
	</cfif>

	<!--- TODO: Cleanup indendation from here on ---> 
<section role="region" class="container-fluid">
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

	<div class="col-12 col-md-6">
			<cfif isDefined("cited_as") and len(cited_as) gt 0>
				<cfif toptypestatuskind eq 'Primary' >
					<div class="card flex-md-row box-shadow h-md-250 border-0 bg-transparent">
				</cfif>
				<cfif toptypestatuskind eq 'Secondary' >
					<div class="card flex-md-row  box-shadow h-md-250 no-card bg-transparent">
				 </cfif>
			<cfelse>
					<div class="card flex-md-row box-shadow h-md-250 no-card bg-transparent">
			</cfif>
	<div class="card-body mt-1 d-flex flex-column align-items-start">
			<div class="small">
<!---				<cfif len(session.CustomOtherIdentifier) gt 0>
					<span class="d-inline-block"> #session.CustomOtherIdentifier#: #CustomID#</span>
				</cfif>--->
			</div>
			<h2 class="d-inline-block mb-1 mt-0 h4 text-secondary font-weight-bold">#collection#&nbsp;#cat_num#</h2>
				<div class="mb-0 font-weight-normal"> 
					<a class="text-dark font-italic font-weight-bolder h3" href="##">#scientific_name#</a>&nbsp; #author_text#
				</div>
			<div class="mb-1 text-muted small w-75">#partString#</div>
			<div class="mb-1 mt-1 small">#collectors#</div>
	</div>
			<cfif isDefined("cited_as") and len(cited_as) gt 0>
				<cfif toptypestatuskind eq 'Primary' >
						<p class="card-text mb-auto">#typeName#</p>
				</cfif>
				<cfif toptypestatuskind eq 'Secondary' >
						<p class="card-text mb-auto">#typeName#</p>
				</cfif>
			<cfelse>

			</cfif>
			 </div>
				</div>
	
	<div class="col-12 col-md-6">
	<cfif isDefined("cited_as") and len(cited_as) gt 0>
		<cfif toptypestatuskind eq 'Primary' >
			 <div class="card flex-md-row box-shadow no-card">
		</cfif>
		<cfif toptypestatuskind eq 'Secondary' >
			 <div class="card flex-md-row box-shadow no-card">
		</cfif>
	<cfelse>
			<div class="card flex-md-row box-shadow no-card">
	</cfif>
		<div class="card-body mt-3 d-flex flex-column align-items-start">
			<h5 class="mb-0 h4">#spec_locality#</h5>
			<cfif len(verbatim_date) gt 0>
				<div class="mb-2 text-muted small mt-2"><span class="h6">Verbatim Date:</span> #verbatim_date#</div>  
			<cfelse>
				<div class="mb-2 text-muted mt-2"><span class="h6">Collection Date:</span> #began_date# - #ended_date#</div>
			</cfif>
				<p class="my-1 small"><span class="h6">Higher Geography</span> #higher_geog#</p>
			<a href="##" class="mt-0 d-block h5">Berkeley Mapper</a> 
		</div>
 
	</div>
	</section>
</section>

<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
<script language="javascript" type="text/javascript">
		//	function closeEditApp() {
//				$('##bgDiv').remove();
//				$('##bgDiv', window.parent.document).remove();
//				$('##popDiv').remove();
//				$('##popDiv', window.parent.document).remove();
//
//				$('##cDiv').remove();
//				$('##cDiv', window.parent.document).remove();
//
//				$('##theFrame').remove();
//				$('##theFrame', window.parent.document).remove();
//				$("span[id^='BTN_']").each(function(){
//					$("##" + this.id).removeClass('activeButton');
//					$('##' + this.id, window.parent.document).removeClass('activeButton');
//				});
//			}
//			function loadEditApp(q) {
//				closeEditApp();
//				var bgDiv = document.createElement('div');
//				bgDiv.id = 'bgDiv';
//				bgDiv.className = 'bgDiv';
//				bgDiv.setAttribute('onclick','closeEditApp()');
//				document.body.appendChild(bgDiv);
//
//				var popDiv=document.createElement('div');
//				popDiv.id = 'popDiv';
//				popDiv.className = 'editAppBox';
//				document.body.appendChild(popDiv);
//				var links='<ul id="navbar">';
//				links+='<li><span onclick="loadEditApp(\'editIdentification\')" class="likeLink" id="BTN_editIdentification">Taxa</span></li>';
//				links+='<li><span onclick="loadEditApp(\'addAccn\')" class="likeLink" id="BTN_addAccn">Accn</span></li>';
//				links+='<li><span onclick="loadEditApp(\'changeCollEvent\')" class="likeLink" id="BTN_changeCollEvent">PickEvent</span></li>';
//				links+='<li><span onclick="loadEditApp(\'specLocality\')" class="likeLink" id="BTN_specLocality">Locality</span></li>';
//				links+='<li><span onclick="loadEditApp(\'editColls\')" class="likeLink" id="BTN_editColls">Agents</span></li>';
//				links+='<li><span onclick="loadEditApp(\'editRelationship\')" class="likeLink" id="BTN_editRelationship">Relations</span></li>';
//				links+='<li><span onclick="loadEditApp(\'editParts\')" class="likeLink" id="BTN_editParts">Parts</span></li>';
//				links+='<li><span onclick="loadEditApp(\'findContainer\')" class="likeLink" id="BTN_findContainer">PartLocn</span></li>';
//				links+='<li><span onclick="loadEditApp(\'editBiolIndiv\')" class="likeLink" id="BTN_editBiolIndiv">Attributes</span></li>';
//				links+='<li><span onclick="loadEditApp(\'editIdentifiers\')" class="likeLink" id="BTN_editIdentifiers">OtherID</span></li>';
//				links+='<li><span onclick="loadEditApp(\'MediaSearch\')" class="likeLink" id="BTN_MediaSearch">Media</span></li>';
//				links+='<li><span onclick="loadEditApp(\'Encumbrances\')" class="likeLink" id="BTN_Encumbrances">Encumbrance</span></li>';
//				links+='<li><span onclick="loadEditApp(\'catalog\')" class="likeLink" id="BTN_catalog">Catalog</span></li>';
//				links+="</ul>";
//
//				$("##popDiv").append(links);
//				var cDiv=document.createElement('div');
//				cDiv.className = 'fancybox-close';
//				cDiv.id='cDiv';
//				cDiv.setAttribute('onclick','closeEditApp()');
//				$("##popDiv").append(cDiv);
//				$("##popDiv").append('<img src="/images/loadingAnimation.gif" class="centeredImage">');
//				var theFrame = document.createElement('iFrame');
//				theFrame.id='theFrame';
//				theFrame.className = 'editFrame';
//				var ptl="/" + q + ".cfm?collection_object_id=" + '#collection_object_id#';
//				theFrame.src=ptl;
//				//document.body.appendChild(theFrame);
//				$("##popDiv").append(theFrame);
//				$("span[id^='BTN_']").each(function(){
//					$("##" + this.id).removeClass('activeButton');
//					$('##' + this.id, window.parent.document).removeClass('activeButton');
//				});
//
//				$("##BTN_" + q).addClass('activeButton');
//				$('##BTN_' + q, window.parent.document).addClass('activeButton');
//			}
		</script>
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
