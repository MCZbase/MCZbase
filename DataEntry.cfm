<cfset usealternatehead="DataEntry">
<cfinclude template="/includes/_header.cfm">
<div id="msg"></div>
<!--- Set MAXTEMPLATE to the largest value of a collection_id that is used as bulkloader.collection_object_id as a template --->
<!--- --->

<cfset MAXTEMPLATE="14">
<cfset title="Data Entry">
<!---<link rel="stylesheet" type="text/css" href="/includes/_DEstyle.css">--->
<!---
<script type='text/javascript' src='/includes/jquery/suggest.js'></script>
<script type='text/javascript' src='/includes/jquery/jquery-autocomplete/jquery.autocomplete.pack.js'></script>
--->
<script type='text/javascript' src='/includes/DEAjax.js'></script>
<script type='text/javascript' language="javascript" src='/includes/internalAjax.js'></script>

<!--cfinclude template="/includes/functionLib.cfm"-->
<!---
Group Setup:

Two groups are required to complete data entry using this form:

	x Data Entry Group, and
	x Data Admin Group

x can be any string. There must be a space between x and "Data." Acceptable entries:

UAM Mammals Data.....
UAM Data .....
Some Totally Random String Data .....


--->
<cf_setDataEntryGroups>

<cfif not isdefined("ImAGod") or len(#ImAGod#) is 0>
	<cfset ImAGod = "no">
</cfif>
<cfif isdefined("CFGRIDKEY") and not isdefined("collection_object_id")>
	<cfset collection_object_id = CFGRIDKEY>
</cfif>
<cfset collid = 1>
<cfif not isdefined("pMode") or len(pMode) is 0>
	<!--- pModes are "enter" for new records, and "edit" for existing records --->
	<!--- There are three expected states affecting actions that can be taken on a record:
	      pMode=enter, unfixedRequiredElement=false
	      pMode=edit, unfixedRequiredElement=false (validation tests passed)
	      pMode=enter, unfixedRequiredElement=true (validation tests failed)
	--->
	<cfset pMode = "enter">
	<cfset unfixedRequiredElement = "false"><!--- Flag indicating a problem with a required element of this record. --->
</cfif>
<!--- TODO:  Refactor all of the dateformat statements to use a single configuration constant specific to the installation rather than a hardcoded date format "yyyy-mm-dd" for Arctos and  "dd mm yyyy" for MCZbase.  --->
<!--cfset thisDate = #dateformat(now(),"dd mmm yyyy")#-->
<cfset thisDate = #dateformat(now(),"yyyy-mm-dd")#>
<!--------------------------------   default page    ---------------------------------------------------->
<cfif action is "nothing">
       <div class="basic_search_box">
        <div class="welcomeback" style="padding-top: 2em;">
    <div class="welcome">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select * from cf_dataentry_settings where username='#session.username#'
		</cfquery>
		<cfif d.recordcount is not 1>
			<cfquery name="seed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into cf_dataentry_settings (
					username
				) values (
					'#session.username#'
				)
			</cfquery>
		</cfif>
		<!--- If a collection isn't showing up, check collection for a row, bulkloader for a template row, and set MAXTEMPLATE above. --->
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select * from collection where collection_id <= #MAXTEMPLATE#  ORDER BY COLLECTION
		</cfquery>
		<cfloop query="c">
			<cfquery  name="isBL" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select * from bulkloader where collection_object_id = #collection_id#
			</cfquery>
			<cfif isBl.recordcount is 0>
                <!--- use this to set up DEFAULTS and "prime" the bulkloader ---->
				<cfquery name="prime" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into bulkloader (
						collection_object_id,
						institution_acronym,
						collection_cde,
						loaded) VALUES (
						#collection_id#,
						'#institution_acronym#',
						'#collection_cde#',
						'#ucase(institution_acronym)# #ucase(collection_cde)# TEMPLATE')
				</cfquery>
			<cfelseif isBL.loaded is not "#ucase(institution_acronym)# #ucase(collection_cde)# TEMPLATE">
			    <!--- it is not our template --->
			    <!--- move the barged-in record and create template --->
				<cfquery name="move" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update bulkloader set collection_object_id = bulkloader_PKEY.nextval
					where collection_object_id = #collection_id#
				</cfquery>
				<cfquery name="prime" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into bulkloader (
						collection_object_id,
						institution_acronym,
						collection_cde,
						loaded) VALUES (
						#collection_id#,
						'#institution_acronym#',
						'#collection_cde#',
						'#ucase(institution_acronym)# #ucase(collection_cde)# TEMPLATE')
				</cfquery>
			</cfif>
		</cfloop>
              
     
		<h3>Welcome to the data entry (and edit) application, #session.username#</h3>
            <br/>
		<ul>
			<li><span style="color:##bed88f">Green Screen</span>: You are entering data to a new record.</li>
			<li><span style="color:##00CCCC">Teal Screen</span>: you are editing an unloaded record that you've previously entered.</li>
			<!---  TODO: Validate that the css sets this screen to red, not yellow --->
            <li><span style="color:##b58aa5">Mauve Screen</span>: A record has been saved but has errors that must be corrected. Fix and save to continue.</li>
		</ul>
            If you have data to enter in bulk, use the <a href="/Bulkloader/">bulkload</a> feature.
            </div>
    	<p><a href="/Bulkloader/cloneWithBarcodes.cfm">Clone records by Barcode</a></p>
		<cfquery name="theirLast" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				max(collection_object_id) theId,
				collection_cde collnCde,
				institution_acronym instAc
			from bulkloader where enteredby = '#session.username#'
			GROUP BY
				collection_cde,
				institution_acronym
		</cfquery>
		<p>Begin at....</p>
		<form name="begin" method="post" action="DataEntry.cfm">
			<input type="hidden" name="action" value="editEnterData" />
			<select name="collection_object_id" size="1">
				<cfif #theirLast.recordcount# gt 0>
					<cfloop query="theirLast">
						<cfquery name="temp" dbtype="query">
							select collection from c where institution_acronym='#instAc#' and collection_cde='#collnCde#'
						</cfquery>
						<option value="#theId#">Your Last #temp.collection#</option>
					</cfloop>
				</cfif>
				<cfloop query="c">
					<option value="#collection_id#">Enter a new  #institution_acronym# #collection# Record</option>
				</cfloop>
			</select>
			<input class="lnkBtn" type="submit" onmouseover="this.className='lnkBtn btnhov'"
							onmouseout="this.className='lnkBtn'"
							value="Enter Data"/>
		</form>
         
	</cfoutput>
        </div>
            </div>
  
</cfif>
<cfif action is "saveCust">
	<cfdump var=#form#>
</cfif>
<!------------ editEnterData --------------------------------------------------------------------------------------------->
<cfif action is "editEnterData">
    <cf_showMenuOnly>
         <div style="clear:both;width:100%;left:0;position:absolute;top:32px;">
	<cfoutput>
		<!---#collection_object_id#--->
		<cfif not isdefined("collection_object_id") or len(collection_object_id) is 0>
			you don't have an ID. <cfabort>
		</cfif>
		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select * from bulkloader where collection_object_id=#collection_object_id#
		</cfquery>
		<!---  Was hard coded magic number, value of 50 in v3.9 then 30 in v2.5.1  --->
		<cfif collection_object_id GT #MAXTEMPLATE#>
			<cfquery name="chk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select bulk_check_one(#collection_object_id#) rslt from dual
			</cfquery>
			<cfset loadedMsg=chk.rslt>
		<cfelse>
			<cfset loadedMsg = "">
		</cfif>

<!--- TODO: Evaluate if hybrid handling is present in bulk_check_one.  --->
<!--- Code from v2.5.1 DataEntry.cfm line 175.  --->
        <!--- Handle hybrids as a special case. --->
        <!---  If the only problem is a taxon name that is a hybrid, treat as acceptable --->
        <!---
        <cfset hybridMatch = REMatch("taxon_name:: \(.+ x .+\) not found", #loadedMsg#)>
        <cfif ArrayLen(#hybridMatch#) gt 0>
           <cfset unfixedRequiredElement = "false">
           <cfset loadedMsg = replace(#loadedMsg#,"::taxon_name::","Probable Hybrid Taxon Name")>
           <cfset pageTitle = #loadedMsg#>
        --->
<!--- End code from v2.5.1 --->

	</cfoutput>
	<cfoutput query="data">
		<cfquery name="ctInst" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT institution_acronym || ' ' || collection_cde as instcoll, collection_id FROM collection
				<cfif len(#collection_cde#) gt 0>
					WHERE collection_cde='#collection_cde#'
				</cfif>
		</cfquery>
		<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			select collection_cde,institution_acronym,collection from collection order by collection
		</cfquery>
		<cfquery name="ctnature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			select nature_of_id from ctnature_of_id order by nature_of_id
		</cfquery>
		<cfquery name="ctunits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	       select ORIG_LAT_LONG_UNITS from ctLAT_LONG_UNITS order by orig_lat_long_units
	    </cfquery>
		<cfquery name="ctflags" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	       select flags from ctflags order by flags
	    </cfquery>
		<cfquery name="CTCOLL_OBJ_DISP" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	       select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP order by coll_obj_DISPOSITION
	    </cfquery>
		<cfquery name="cterror" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	    	select LAT_LONG_ERROR_UNITS from ctLAT_LONG_ERROR_UNITS order by lat_long_error_units
	    </cfquery>
		<cfquery name="ctdatum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			select datum from ctdatum order by datum
	    </cfquery>
		<cfquery name="ctgeorefmethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	       	select georefmethod from ctgeorefmethod order by georefmethod
	    </cfquery>
		<cfquery name="ctverificationstatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	       	select verificationstatus from ctverificationstatus order by verificationstatus
	    </cfquery>
		<cfquery name="ctcollecting_source" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	       	select collecting_source from ctcollecting_source order by collecting_source
	    </cfquery>
        <cfquery name="ctspecpart_attribute_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
               select attribute_type from ctspecpart_attribute_type order by attribute_type
        </cfquery>
	    <cfquery name="ctew" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	    	select e_or_w from ctew order by e_or_w
	    </cfquery>
	    <cfquery name="ctns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	       	select n_or_s from ctns order by n_or_s
	    </cfquery>
		<cfquery name="ctOtherIdType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT distinct(other_id_type) FROM ctColl_Other_id_type
			order by other_id_type
	    </cfquery>
		<cfquery name="ctSex_Cde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT distinct(sex_cde) as sex_cde FROM ctSex_Cde
			<cfif len(collection_cde) gt 0>
				WHERE collection_cde='#collection_cde#'
			</cfif>
			order by sex_cde
		</cfquery>
		<cfquery name="ctOrigElevUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	       	select orig_elev_units from ctorig_elev_units
	    </cfquery>
		<cfquery name="ctDepthUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
        	select depth_units from ctdepth_units
        </cfquery>
		<cfquery name="ctbiol_relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	      	select BIOL_INDIV_RELATIONSHIP from ctbiol_relations
			order by BIOL_INDIV_RELATIONSHIP
	    </cfquery>
	    <cfquery name="ctAge_class" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			select age_class from ctAge_class where collection_cde = '#collection_cde#' order by age_class
		</cfquery>
		<cfquery name="ctLength_Units" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			select length_units from ctLength_Units order by length_units
		</cfquery>
		<cfquery name="ctWeight_Units" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			select Weight_Units from ctWeight_Units order by weight_units
		</cfquery>
		<cfquery name="ctPartName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#"  cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT distinct(part_name) FROM ctSpecimen_part_name
				<cfif len(#collection_cde#) gt 0>
					WHERE collection_cde='#collection_cde#'
				</cfif>
				order by part_name
        </cfquery>
		<cfquery name="ctModifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select modifier from ctnumeric_modifiers order by modifier desc
		</cfquery>
		<cfquery name="ctPartModifier" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#"  cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT distinct(part_modifier) FROM ctSpecimen_part_modifier
			order by part_modifier
        </cfquery>
		<cfquery name="ctPresMeth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#"  cachedwithin="#createtimespan(0,0,60,0)#">
			select preserve_method from ctspecimen_preserv_method
				<cfif len(#collection_cde#) gt 0>
					WHERE collection_cde='#collection_cde#'
				</cfif>
				order by preserve_method
		</cfquery>
		<!-------->
		<cfquery name="ctAttributeType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#"  cachedwithin="#createtimespan(0,0,60,0)#">
			select distinct(attribute_type) from ctattribute_type
				<cfif len(#collection_cde#) gt 0>
					WHERE collection_cde='#collection_cde#'
				</cfif>
				order by attribute_type
		</cfquery>

		<cfquery name="ctAttributeType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT attribute_type FROM ctattribute_type
			<cfif len(#collection_cde#) gt 0>
				WHERE collection_cde='#collection_cde#'
			</cfif>
			order by attribute_type
		</cfquery>
		<cfquery name="ctgeology_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			select geology_attribute from ctgeology_attribute order by geology_attribute
		</cfquery>
		<cfquery name="ctCodes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				attribute_type,
				value_code_table,
				units_code_table
		 	from ctattribute_code_tables
		</cfquery>

		<!----------------- end dropdowns --------------------->

        <!--- Note: MAXTEMPLATE is the largest collection_id used for a template in bulkloader by using the collection_id as the value in bulkloader.collection_object_id --->
		
		<cfset sql = "select collection_object_id from bulkloader where collection_object_id > #MAXTEMPLATE#">
		<cfif ImAGod is "no">
			 <cfset sql = "#sql# AND enteredby = '#session.username#'">
		<cfelse>
		<cfif isdefined("accn2") and len(accn2) gt 0>
			<cfset sql = "#sql# AND accn IN (#accn2#)">
		</cfif>
		<cfif isdefined("colln2") and len(colln2) gt 0>
			<cfset sql = "#sql# AND institution_acronym || ':' || collection_cde IN (#colln2#)">
		</cfif>
        <cfif isdefined("enteredby2") and len(enteredby2) gt 0>
      		<!--- enteredby2 instead of enteredby as DataEntry.cfm overwrites enteredby --->
			<cfset sql = "#sql# AND enteredby IN (#enteredby2#)">
		</cfif></cfif>
		<cfset sql = "#sql# order by collection_object_id">
		<cfquery name="whatIds" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			#preservesinglequotes(sql)#
		</cfquery>
	
		<cfset idList=valuelist(whatIds.collection_object_id)>
		<cfset currentPos = listFind(idList,data.collection_object_id)>
		<cfif len(loadedMsg) gt 0>
			<cfset pageTitle = replace(loadedMsg,"::","","all")>
		<cfelse>
			<cfset pageTitle = "This record has passed all bulkloader checks!">
		</cfif>
		<cfif not isdefined("inEntryGroups") OR len(inEntryGroups) eq 0>
			You have group issues! You must be in a Data Entry group to use this form.
			<cfabort>
		</cfif>
            <div id="dataentry_form">
		<form name="dataEntry" method="post" action="DataEntry.cfm" onsubmit="return cleanup(); return noEnter();" id="dataEntry">
			<input type="hidden" name="action" value="" id="action">
			<input type="hidden" name="nothing" value="" id="nothing"/><!--- trashcan for picks - don't delete --->
			<input type="hidden" name="ImAGod" value="#ImAGod#" id="ImAGod"><!--- allow power users to browse other's records --->
			<input type="hidden" name="collection_cde" value="#collection_cde#" id="collection_cde">
			<input type="hidden" name="institution_acronym" value="#institution_acronym#" id="institution_acronym">
			<input type="hidden" name="collection_object_id" value="#collection_object_id#"  id="collection_object_id"/>
			<input type="hidden" name="loaded" value="waiting approval"  id="loaded"/>
            
            <table id="theTable" class="main">
                <!--- whole page table --->
				<tr>
					<td colspan="3" align="center" style="border: 1px solid gray;width: 99%;margin-left:-.5em;;">
                        <div id="loadedMsgDiv">#loadedMsg#</div>
                        	<div id="modeDisplayDiv"><cfif len(#loadedMsg#)gt 0>FIX<cfelse> #ucase(pMode)#</cfif></div>
					</td>
				</tr>
				<tr>
                    
                <td class="leftColumn" valign="top"><!--- left top of page --->
					<table>
                        <!--- cat item IDs --->
						<tr><h3 class="wikilink">MCZ Record Identifiers<img src="/images/info.gif" onClick="getMCZDocs('Other ID - Data Entry')" class="likeLink" alt="[ help ]"></h3>
							<td valign="top">
							
								<span style="font-size:12px;font-weight:bold;">#institution_acronym#:#collection_cde#
								
                                    <span id="catNumLbl" class="f11a">Cat##</span></span>
								<input type="text" name="cat_num" value="#cat_num#" title="CAT_NUM" size="12" id="cat_num">
								<cfif isdefined("session.CustomOtherIdentifier") and len(#session.CustomOtherIdentifier#) gt 0>
									<span id="d_other_id_num_type_5">
										<span class="f11a">#session.CustomOtherIdentifier#</span>
										<input type="hidden" name="other_id_num_type_5" value="#session.CustomOtherIdentifier#" id="other_id_num_type_5" />
										<input type="text" name="other_id_num_5" value="#other_id_num_5#" size="8" id="other_id_num_5">
										<!---<span id="rememberLastId">
											<cfif isdefined("session.rememberLastOtherId") and session.rememberLastOtherId is 1>
												<span class="infoLink" onclick="rememberLastOtherId(0)">Nevermind</span>
											<cfelse>
												<span class="infoLink" onclick="rememberLastOtherId(1)">Increment this</span>
											</cfif>
										</span>--->
									</span>
								</cfif>
								<span class="f11a">Accn</span>
								<input type="text" name="accn" title="ACCN" value="#accn#" size="10" class="reqdClr" id="accn" onchange="isGoodAccn();">
								<!---<span id="customizeForm" class="infoLink" onclick="customize()">[ customize form ]</span>--->
                            </td></tr>
                        <tr>
                            <td align="left"><input type="hidden" name="mask_record" value="0" />
                                <span class="f11a">
                                    <input type="checkbox" name="mask_record" value="1" <cfif #mask_record# EQ "1">checked</cfif>>mask record</input>
                                </span>
							</td>
						</tr>
					</table><!-----/ cat item IDs ---------->
                    <table>
					    <!------ other IDs ------------------->
						<tr>
						<h3 class="wikilink">Other Identifying Numbers
								<img src="/images/info.gif" border="0" onClick="getMCZDocs('Other ID - Data Entry')" class="likeLink" alt="[ help ]">
                            </h3>
						</tr>
						<cfloop from="1" to="4" index="i">
							<tr>
								<td id="d_other_id_num_#i#">
									<span class="f11a">OtherID #i#</span>
									<select name="other_id_num_type_#i#" title="OTHER_ID_NUM_TYPE_X" style="width:113px"
										id="other_id_num_type_#i#"
										onChange="this.className='reqdClr';dataEntry.other_id_num_#i#.className='reqdClr';dataEntry.other_id_num_#i#.focus();">
										<option value=""></option>
										<cfloop query="ctOtherIdType">
											<option <cfif evaluate("data.other_id_num_type_" & i) is ctOtherIdType.other_id_type> selected="selected" </cfif>
												value="#other_id_type#">#other_id_type#</option>
										</cfloop>
									</select>
									<input type="text" name="other_id_num_#i#" title="OTHER_ID_NUM_X" value="#evaluate("data.other_id_num_" & i)#" id="other_id_num_#i#">
								</td>
							</tr>
						</cfloop>
					</table><!---- /other IDs ---->
					<table>
					    <!----- identification ----->
						<tr><h3 class="wikilink">Identification of Specimen
							
								<img src="/images/info.gif" onClick="getMCZDocs('Identification')" class="likeLink" alt="[ help ]">
                            </h3>
							<td align="right">
								<span class="f11a">Scientific&nbsp;Name</span>
							</td>
							<td>
								<input type="text" title="TAXON_NAME" name="taxon_name" value="#taxon_name#" class="reqdClr" size="35"
									id="taxon_name"
									onchange="taxaPickOptional('nothing',this.id,'dataEntry',this.value)">
							</td>
						</tr>
						<tr>
							<td align="right"><span class="f11a">ID By</span></td>
							<td>
								<input type="text" name="id_made_by_agent" value="#id_made_by_agent#" class="reqdClr" size="20"
									id="id_made_by_agent" title="ID_MADE_BY_AGENT"
									onchange="getAgent('nothing',this.id,'dataEntry',this.value);"
									onkeypress="return noenter(event);">
								<span class="infoLink" onclick="copyAllAgents('id_made_by_agent');">Copy2All</span>
							</td>
						</tr>
						<tr>
							<td align="right"><span class="f11a">Nature of ID</span></td>
							<td>
								<select name="nature_of_id" class="reqdClr" style="width:120px;" id="NATURE_OF_ID" title="NATURE_OF_ID"
									<cfloop query="ctnature">
										<option <cfif data.nature_of_id is ctnature.nature_of_id> selected="selected" </cfif>
											value="#ctnature.nature_of_id#">#ctnature.nature_of_id#</option>
									</cfloop>
								</select>
							</td>
						</tr>
						<tr>
							<td align="right"><span class="f11a">Date</span></td>
							<td>
								<input type="text" name="made_date" value="#made_date#" id="made_date" title="MADE_DATE">
								<span class="infoLink" onclick="copyAllDates('made_date');">Copy2All</span>
							</td>
						</tr>
						<tr id="d_identification_remarks">
							<td align="right"><span class="f11a">ID Remark</span></td>
							<td><input type="text" name="identification_remarks" title="IDENTIFICATION_REMARKS" value="#identification_remarks#" size="35"
								id="identification_remarks">
							</td>
						</tr>
					</table><!------ /identification -------->
			        <table>
                        <!--- agents --->
						<tr>
						
                                <h3 class="wikilink">Collector/Preparator (agent)
								<img src="/images/info.gif" onClick="getMCZDocs('Agent-Data Entry')" class="likeLink" alt="[ help ]">
                                </h3>
                             
							<cfloop from="1" to="8" index="i">
<tr>
								<td id="d_collector_role_#i#" align="right">
									<select name="collector_role_#i#" title="COLLECTOR_ROLE_X" size="1" <cfif i is 1>class="reqdClr"</cfif> id="collector_role_#i#">
										<option <cfif evaluate("data.collector_role_" & i) is "c">selected="selected"</cfif> value="c">Collector&nbsp;&nbsp;&nbsp;</option>
										<cfif i gt 1>
											<option <cfif evaluate("data.collector_role_" & i) is "p">selected="selected"</cfif> value="p">Preparator</option>
										</cfif>
									</select>
								</td>
								<td  id="d_collector_agent_#i#" nowrap="nowrap">
									<span class="f11a">#i#</span>
									<input title="COLLECTOR_AGENT_X" type="text" name="collector_agent_#i#" value="#evaluate("data.collector_agent_" & i)#"
										<cfif i is 1>class="reqdClr"</cfif> id="collector_agent_#i#"
										onchange="getAgent('nothing',this.id,'dataEntry',this.value);"
										onkeypress="return noenter(event);">
									<span class="infoLink" onclick="copyAllAgents('collector_agent_#i#');">Copy2All</span>
								</td>
            </tr>
							</cfloop>
					</table><!---- / agents------------->
                    <table>
				    <!------- remarks  ------->
						<tr><h3 class="wikilink">Misc. Specimen Record Data<img src="/images/info.gif" onClick="getMCZDocs('Parts - Data Entry')" class="likeLink" alt="[ help ]"></h3>

						<td colspan="2"><span class="f11a">Entered by: </span>
						
							<cfif ImAGod is not "yes">
								<input type="hidden" name="enteredby" value="#session.username#" id="enteredby" class="readClr"/>
                                #session.username#
							<cfelseif ImAGod is "yes">
								<input type="text" name="enteredby" value="#enteredby#" id="enteredby"/>
							<cfelse>
								ERROR!!!
							</cfif>
						</td>
					</tr>
                             <tr id="d_coll_object_remarks">
						<td colspan="2">
							<span class="f11a">Spec Remark</span>
								<textarea name="coll_object_remarks" id="coll_object_remarks">#coll_object_remarks#</textarea>
						</td>
					</tr>
					<tr>
						<td id="d_flags">
							<span class="f11a">Missing....</span>
							<cfset thisflags = flags>
							<select name="flags" size="1" style="width:120px" id="flags">
								<option  value=""></option>
								<cfloop query="ctflags">
									<option <cfif flags is thisflags> selected </cfif>
										value="#flags#">#flags#</option>
								</cfloop>
							</select>
						</td>
						
					</tr>
				</table><!------- remarks --->
        <table> <!--- random admin stuff ---->
				     <tr id="d_relationship">
                         <h3 class="wikilink">Biological and Admin. Record Relationships<img src="/images/info.gif" onClick="getMCZDocs('Record Relationships - Data Entry')" class="likeLink" alt="[ help ]"></h3>
                         <td>Relationship</td>
                         <td>						
							<cfset thisRELATIONSHIP = RELATIONSHIP>
							<select name="relationship" size="1" id="relationship">
								<option value=""></option>
								<cfloop query="ctbiol_relations">
									<option
										<cfif thisRELATIONSHIP is BIOL_INDIV_RELATIONSHIP> selected="selected" </cfif>
									 value="#BIOL_INDIV_RELATIONSHIP#">#BIOL_INDIV_RELATIONSHIP#</option>
								</cfloop>
            </select></td>
            </tr>
            <tr>
                        <td>Related to:</td>
                        <td>
							<cfset thisRELATED_TO_NUM_TYPE = RELATED_TO_NUM_TYPE>
							<select name="related_to_num_type" size="1" id="related_to_num_type" >
								<option value=""></option>
								<option <cfif thisRELATED_TO_NUM_TYPE is "catalog number">selected="selected"</cfif> value="catalog number">catalog number (MCZ:Mamm:123 format)</option>
								<cfloop query="ctOtherIdType">
									<option
										<cfif thisRELATED_TO_NUM_TYPE is other_id_type> selected="selected" </cfif>
									 value="#other_id_type#">#other_id_type#</option>
								</cfloop>
                            </select>
                      
				<input type="text" value="#related_to_number#" name="related_to_number" id="related_to_number" size="15" />
						</td>
					</tr>
				</table><!------ random admin stuff ---------->
				</td> <!---- end leftColumn --->

	           <td valign="top" class="middleColumn">
				<!----- middle column ---->
                    <table><!--start collecting event-->
                        <tr>
                            <h3 class="wikilink">Collecting Event<img src="/images/info.gif" onClick="getMCZDocs('Collecting Event - Data Entry')" class="likeLink" alt="[ help ]"></h3>
							<td align="right"><span class="f11a">Verbatim Locality</span></td>
							<td colspan="2">
								<input type="text"  name="verbatim_locality"
									class="reqdClr"
									id="verbatim_locality" title="VERBATIM_LOCALITY" value="#stripQuotes(verbatim_locality)#" size="40">
								<!---<span class="infoLink" onclick="document.getElementById('verbatim_locality').value=document.getElementById('spec_locality').value;">
									&nbsp;Use&nbsp;Specific Locality
								</span>--->
							</td>
						</tr>
						<tr>
							<td align="right"><span class="f11a">Verbatim Date</span></td>
							<td>
								<input type="text" name="verbatim_date" title="VERBATIM_DATE" class="reqdClr" value="#verbatim_date#" id="verbatim_date" size="17">
								<span class="infoLink"
									onClick="copyVerbatim($('##verbatim_date').val());">&nbsp;>> Copy to Begin &amp; End Dates&nbsp;</span>
                            </td>
                        </tr>
                        <tr>
                            <td align="right">
                                <span class="f11a">Begin Date</span></td>
                            <td colspan="4">
								<input type="text" name="began_date" class="reqdClr" title="BEGAN_DATE" value="#began_date#" id="began_date" size="11">
								<span class="infoLink" onclick="copyAllDates('began_date');">Copy2All</span>
                            
								<span class="f11a">&nbsp;&nbsp;End Date</span>
								<input type="text" name="ended_date" title="ENDED_DATE" class="reqdClr" value="#ended_date#" id="ended_date" size="11">
								<span class="infoLink" onclick="copyAllDates('ended_date');">Copy2All</span>
							</td>
						</tr>
						<tr>
							<td colspan="2" id="dateConvertStatus"></td>
						</tr>
						<tr>
							<td align="right"><span class="f11a">Collection Method:</span></td>
                            <td colspan="3">
							<input type="text" name="collecting_method" value="#collecting_method#" title="COLLECTING_METHOD" id="collecting_method">
										
										<span class="f11a">&nbsp;&nbsp;Collection Source:</span>
										
											<cfif len(collecting_source) gt 0>
												<cfset thisCollSrc=collecting_source>
											<cfelse>
												<cfset thisCollSrc="wild caught">
											</cfif>
											<select name="collecting_source"
												size="1"
												id="collecting_source" title="COLLECTING_SOURCE"
												class="reqdClr">
												<option value=""></option>
												<cfloop query="ctcollecting_source">
													<option
														<cfif collecting_source is thisCollSrc> selected </cfif>
														value="#collecting_source#">#collecting_source#</option>
												</cfloop>
											</select>
							
							</td>
						</tr>
						<tr id="d_habitat_desc">
							<td align="right"><span class="f11a">Habitat</span></td>
							<td>
								<input type="text" name="habitat_desc" title="HABITAT_DESC" size="54" id="habitat_desc" value="#habitat_desc#">
							</td>
						</tr>
						<tr id="d_associated_species">
							<td align="right"><span class="f11a">Associated&nbsp;Species</span></td>
							<td>
								<input type="text" title="ASSOCIATED_SPECIES" name="associated_species" id="associated_species" value="#associated_species#">
							</td>
						</tr>
						<tr id="d_coll_object_habitat">
							<td align="right"><span class="f11a">Microhabitat</span></td>
							<td>
								<input type="text" title="COLL_OBJECT_HABITAT" name="coll_object_habitat" id="coll_object_habitat" value="#coll_object_habitat#" size="54">
							</td>
						</tr>
						<tr id="d_orig_elev_units">
							<td align="right"><span class="f11a">Elevation (min-max)</span><br>
                                <span class="f11a">&nbsp;between</span></td>
                            <td>
								<input type="text" title="MINIMUM_ELEVATION" name="minimum_elevation" size="14" value="#minimum_elevation#" id="minimum_elevation">
								<span class="infoLink" onclick="document.getElementById('maximum_elevation').value=document.getElementById('minimum_elevation').value";>&nbsp;>>&nbsp;</span>
                         <input type="text" title="MAXIMUM_ELEVATION" name="maximum_elevation" size="14" value="#maximum_elevation#" id="maximum_elevation">
								<select name="orig_elev_units" title="ORIG_ELEV_UNITS" id="orig_elev_units">
									<option value=""></option>
									<cfloop query="ctOrigElevUnits">
										<option
											<cfif data.orig_elev_units is ctOrigElevUnits.orig_elev_units> selected="selected" 
                                            </cfif>
											value="#orig_elev_units#">#orig_elev_units#</option>
									</cfloop>
								</select>
							</td>
						</tr>
						<!---  Hide depth from this form for some departments (it is still accessible if needed on the grid views) --->
						<cfif collection_cde is not "VP" and collection_cde is not "IP" and collection_cde is not "Orn" and collection_cde is not "Model">
						<tr id="d_orig_depth_units">
							<td align="right">
								<span class="f11a">Depth (shallowest-deepest)</span><br/>
                                <span class="f11a">&nbsp;between</span></td>
								<td><input type="text" name="min_depth" size="4" title="MIN_DEPTH" value="#min_depth#" id="min_depth">
								<span class="infoLink"
									onclick="document.getElementById('maximum_depth').value=document.getElementById('minimum_depth').value";>&nbsp;>>&nbsp;</span>
								<input type="text" name="max_depth" size="4" title="MAX_DEPTH" value="#max_depth#" id="max_depth">
								<select name="depth_units" title="DEPTH_UNITS" size="1" id="depth_units">
									<option value=""></option>
									<cfloop query="ctDepthUnits">
										<option
											<cfif data.depth_units is ctDepthUnits.depth_units> selected="selected" </cfif>
											value="#depth_units#">#depth_units#</option>
									</cfloop>
								</select>
							</td>
						</tr>
						</cfif>
						<tr id="d_coll_event_remarks">
							<td align="right"><span class="f11a">Collecting Event Remark</span></td>
							<td>
								<input type="text" title="COLL_EVENT_REMARKS" name="coll_event_remarks" size="54" value="#coll_event_remarks#" id="coll_event_remarks">
							</td>
                         </tr>
                        <tr>
                            <td colspan="2" id="d_collecting_event_id">OR
											<label for="collecting_event_id">Existing Event ID</label>
											<input title="EXISTING_EVENT_ID"type="text" name="collecting_event_id" id="collecting_event_id" value="#collecting_event_id#" readonly class="readClr" size="11">
											<input type="hidden" id="fetched_eventid">
											<span class="infoLink" id="eventPicker" onclick="findCollEvent('collecting_event_id','dataEntry','verbatim_locality'); return false;">
												Pick Event
											</span>
											<span class="infoLink" id="eventUnPicker" style="display:none;" onclick="unpickEvent()">
												Depick Event
											</span>
							</td>
                            
                       </tr>
				
					</table><!----- /collecting Event ---------->
    
    				<table><!----- locality ---------->
					 	<tr>
							<h3 class="wikilink">Locality
								<img src="/images/info.gif" border="0" onClick="getMCZDocs('Locality - Data Entry')" class="likeLink" alt="[ help ]">
                           </h3>
							<td><span class="f11a">Higher Geography</span></td>
							<td>
								<input type="text" name="higher_geog" title="HIGHER_GEOG" class="reqdClr" id="higher_geog" value="#higher_geog#" onchange="getGeog('nothing',this.id,'dataEntry',this.value)" size="54">
							</td>
						</tr>
						<tr>
							<td><span class="f11a">Specific&nbsp;Locality&nbsp;</span></td>
							<td nowrap="nowrap">
								<input type="text" name="spec_locality" title="SPEC_LOCALITY" class="reqdClr"
									id="spec_locality"	value="#stripQuotes(spec_locality)#" size="54">
							</td>
						</tr>
					
						<tr id="d_locality_remarks">
							<td><span class="f11a" onclick="checkPicked()">Locality Remark</span></td>
							<td>
								<input type="text" title="LOCALITY_REMARKS" name="locality_remarks" size="54" value="#locality_remarks#" id="locality_remarks">
							</td>
						</tr>
                        	<tr>
							
										<td colspan="2" id="d_locality_id">OR
											<label for="fetched_locid">Existing&nbsp;Locality&nbsp;ID</label>
											<input type="hidden" id="fetched_locid">
											<input type="text" name="locality_id" title="LOCALITY_ID" id="locality_id" value="#locality_id#" readonly class="readClr" size="12">
											<span class="infoLink" id="localityPicker"
												onclick="LocalityPick('locality_id','spec_locality','dataEntry','turnSaveOn'); return false;">
												Pick&nbsp;Locality
											</span>
											<span class="infoLink"
												id="localityUnPicker"
												style="display:none;"
												onclick="unpickLocality()">
												Depick&nbsp;Locality
											</span>
										</td>
                        </tr>	
							</td>
						</tr>
                </table><!----- /locality ---------->
                    <table id="d_orig_lat_long_units">
				    <!------- coordinates ------->
					<tr>
                        <h3 class="wikilink">Coodinates
						
                        <img src="/images/info.gif" onClick="getMCZDocs('Georeferencing - Data Entry')" class="likeLink" alt="[ help ]"></h2>
					
						<td>
							<table style="border:none;">
								<tr>
									<td colspan="3" align="left"><span class="f11a">Original&nbsp;lat/long&nbsp;Units</span>
										<cfset thisLLUnits=#ORIG_LAT_LONG_UNITS#>
										<select name="orig_lat_long_units" title="ORIG_LAT_LONG_UNITS" id="orig_lat_long_units"
											onChange="switchActive(this.value);dataEntry.max_error_distance.focus();">
											<option value=""></option>
											<cfloop query="ctunits">
											  <option <cfif data.orig_lat_long_units is ctunits.orig_lat_long_units> selected="selected" </cfif>
											  	value="#ctunits.ORIG_LAT_LONG_UNITS#">#ctunits.ORIG_LAT_LONG_UNITS#</option>
											</cfloop>
										</select>
								
                                       <span class="likeLink" onclick="geolocate()">&nbsp;&nbsp;GEOLOCATE</span><br>
                                  <span style="color: gray;">(use dropdown to change form below)</span>  </td>
                                  <td valign="top">
                                  <div id="geoLocateResults"></div>
                                     </td>
								</tr>
							</table>
						</td>
					</tr>
					<tr>
						<td>
							<div id="lat_long_meta" class="noShow">
								<table border="0" style="border: none;">
									<tr>
										<td align="right"><span class="f11a">Max Error</span></td>
										<td>
											<input type="text" title="MAX_ERROR_DISTANCE" name="max_error_distance" id="max_error_distance" value="#max_error_distance#" size="10">
											<select name="max_error_units" title="MAX_ERROR_UNITS" id="max_error_units">
												<option value=""></option>
												<cfloop query="cterror">
												  <option
												  <cfif cterror.LAT_LONG_ERROR_UNITS is data.max_error_units> selected="selected" </cfif>
												  	value="#cterror.LAT_LONG_ERROR_UNITS#">#cterror.LAT_LONG_ERROR_UNITS#</option>
												</cfloop>
											</select>
										</td>
										<td align="right"><span class="f11a">Extent</span></td>
										<td>
											<input type="text" title="EXTENT" name="extent" id="extent" value="#extent#" >
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">GPS Accuracy</span></td>
										<td>
											<input type="text" title="GPSACCURACY" name="gpsaccuracy" id="gpsaccuracy" value="#gpsaccuracy#" >
										</td>
										<td align="right"><span class="f11a">Datum</span></td>
										<td>
											<select name="datum" title="DATUM" class="reqdClr" id="datum" style="width: 140px;">
												<option value=""></option>
												<cfloop query="ctdatum">
													<option <cfif data.datum is ctdatum.datum> selected="selected" </cfif>
												 		value="#datum#">#datum#</option>
												</cfloop>
											</select>
										</td>
									</tr>
									<tr>
										<td>
											<span class="f11a">Determiner</span>
										</td>
										<td>
											<input type="text" name="determined_by_agent" value="#determined_by_agent#" class="reqdClr"
												id="determined_by_agent"
												onchange="getAgent('nothing',this.id,'dataEntry',this.value);"
												onkeypress="return noenter(event);">
										</td>
										<td align="right"><span class="f11a">Date</span></td>
										<td>
											<input type="text" title="DETERMINED_DATE" name="determined_date" class="reqdClr" value="#determined_date#" id="determined_date" size="10">
											<span class="infoLink" onclick="copyAllDates('determined_date');">Copy2All</span>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Reference</span></td>
										<td colspan="3" nowrap="nowrap">
											<input type="text" title="LAT_LONG_REF_SOURCE" name="lat_long_ref_source" id="lat_long_ref_source"  class="reqdClr"
												 value="#lat_long_ref_source#">
											<span class="infoLink" onclick="getHelp('lat_long_ref_source');">Pick</span>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Method</span></td>
										<td class="geometh">
											<select name="georefmethod" size="1" style="width: 180px;" title="GEOREFMETHOD" class="reqdClr" id="georefmethod">
												<cfloop query="ctgeorefmethod">
													<option <cfif data.georefmethod is ctgeorefmethod.georefmethod> selected="selected" </cfif>
														value="#ctgeorefmethod.georefmethod#">#ctgeorefmethod.georefmethod#</option>
												</cfloop>
											</select>
										</td>
										<td align="right" style="padding-left: .25em;">Verification</td>
										<td>
											<cfset thisverificationstatus = #verificationstatus#>
											<select title="VERIFICATIONSTATUS" name="verificationstatus" size="1" class="reqdClr" id="verificationstatus">
												<cfloop query="ctverificationstatus">
													<option <cfif data.verificationstatus is ctverificationstatus.verificationstatus> selected="selected" </cfif>
												  		value="#ctverificationstatus.verificationstatus#">#ctverificationstatus.verificationstatus#</option>
												</cfloop>
											</select>
										</td>
									</tr>
									<tr id="d_lat_long_remarks">
										<td align="right"><span class="f11a">Remark</span></td>
										<td colspan="3">
											<input type="text" name="lat_long_remarks" value="#lat_long_remarks#" id="lat_long_remarks" size="20">
										</td>
									</tr>
								</table>
							</div>
							<div id="dms" class="noShow">
								<table style="border: none;">
									<tr>
										<td align="right"><span class="f11a">Latitude Degrees</span></td>
										<td>
											<input type="text" title="LATDEG" name="latdeg" size="4" id="latdeg" class="reqdClr" value="#latdeg#">
										</td>
										<td align="right"><span class="f11a">Lat. Min.</span></td>
										<td>
											<input type="text"
												 name="LATMIN"
												size="4"
												id="latmin"
												class="reqdClr"
												value="#LATMIN#"
                                                title="LATMIN">
										</td>
										<td align="right"><span class="f11a">Lat. Sec.</span></td>
										<td>
											<input type="text"
												 name="latsec"
												size="6"
												id="latsec"
												class="reqdClr"
												value="#latsec#"
                                                title="LATSEC">
											</td>
										<td align="right"><span class="f11a">Lat. Dir.</span></td>
										<td>
											<select name="latdir" title="LATDIR" size="1" id="latdir" class="reqdClr">
												<option value=""></option>
												<option <cfif #LATDIR# is "N"> selected </cfif>value="N">N</option>
												<option <cfif #LATDIR# is "S"> selected </cfif>value="S">S</option>
											  </select>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Longitude Degrees</span></td>
										<td>
											<input type="text"
												name="longdeg"
												size="4"
												id="longdeg"
												class="reqdClr"
												value="#longdeg#"
                                                title="LONGDEG">
										</td>
										<td align="right"><span class="f11a">Long. Min.</span></td>
										<td>
											<input type="text"
												name="longmin"
												size="4"
												id="longmin"
												class="reqdClr"
												value="#longmin#"
                                                title="LONGMIN">
										</td>
										<td align="right"><span class="f11a">Long. Sec.</span></td>
										<td>
											<input type="text"
												 name="longsec"
												size="6"
												id="longsec"
												class="reqdClr"
												value="#longsec#"
                                                title="LONGSEC">
										</td>
										<td align="right"><span class="f11a">Long. Dir.</span></td>
										<td>
											<select name="longdir" size="1" title="LONGDIR" id="longdir" class="reqdClr">
												<option value=""></option>
												<option <cfif #LONGDIR# is "E"> selected </cfif>value="E">E</option>
												<option <cfif #LONGDIR# is "W"> selected </cfif>value="W">W</option>
											  </select>
										</td>
									</tr>
								</table>
							</div>
							<div id="ddm" class="noShow">
								<table style="border:none;">
									<tr>
										<td align="right"><span class="f11a">Latitude Degrees</span></td>
										<td>
											<input type="text"
												 name="decLAT_DEG"
												size="4"
												id="decLAT_DEG"
												class="reqdClr"
												value="#latdeg#"
                                                title="DEC_LAT_DEG"
												onchange="dataEntry.latdeg.value=this.value;">
										</td>
										<td align="right"><span class="f11a">Lat. Decimal Minutes</span></td>
										<td>
											<input type="text"
												name="dec_lat_min"
												 size="8"
												id="dec_lat_min"
                                                title="DEC_LAT_MIN"
												class="reqdClr"
												value="#dec_lat_min#">
										</td>
										<td align="right"><span class="f11a">Lat. Direction</span></td>
										<td>
											<select name="decLAT_DIR"
												size="1"
												id="decLAT_DIR"
												class="reqdClr"
                                                title="LATDIR"
												onchange="dataEntry.latdir.value=this.value;">
												<option value=""></option>
												<option <cfif #LATDIR# is "N"> selected </cfif>value="N">N</option>
												<option <cfif #LATDIR# is "S"> selected </cfif>value="S">S</option>
											</select>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Longitude Degrees</span></td>
										<td>
											<input type="text"
												name="decLONGDEG"
												size="4"
												id="decLONGDEG"
                                                title="LONGDEG"
												class="reqdClr"
												value="#longdeg#"
												onchange="dataEntry.longdeg.value=this.value;">
										</td>
										<td align="right"><span class="f11a">Long. Decimal Minutes</span></td>
										<td>
											<input type="text"
												name="DEC_LONG_MIN"
												size="8"
												id="dec_long_min"
												class="reqdClr"
												value="#DEC_LONG_MIN#">
										</td>
										<td align="right"><span class="f11a">Long. Direction</span></td>
										<td>
											<select name="decLONGDIR"
												 size="1"
												id="decLONGDIR"
												class="reqdClr"
                                                title="LONGDIR"
												onchange="dataEntry.longdir.value=this.value;">
												<option value=""></option>
												<option <cfif #LONGDIR# is "E"> selected </cfif>value="E">E</option>
												<option <cfif #LONGDIR# is "W"> selected </cfif>value="W">W</option>
											</select>
										</td>
									</tr>
								</table>
							</div>

							<div id="dd" class="noShow"><br>
								<span class="f11a">Decimal Latitude</span>
								<input type="text"
									 name="dec_lat"
									size="8"
									id="dec_lat"
                                    title="DEC_LAT"
									class="reqdClr"
									value="#dec_lat#">
								<span class="f11a">Decimal Longitude</span>
									<input type="text"
										 name="dec_long"
										size="8"
                                        title="DEC_LONG"
										id="dec_long"
										class="reqdClr"
										value="#dec_long#">
							</div>
							<div id="utm" class="noShow">
								<span class="f11a">UTM Zone</span>
								<input type="text"
									 name="utm_zone"
									size="8"
									id="utm_zone"
                                    title="UTM_ZONE"
									class="reqdClr"
									value="#utm_zone#">
								<span class="f11a">UTM E/W</span>
								<input type="text"
									 name="utm_ew"
                                     title="UTM_EW"
									size="8"
									id="utm_ew"
									class="reqdClr"
									value="#utm_ew#">
								<span class="f11a">UTM N/S</span>
								<input type="text"
									 name="utm_ns"
									size="8"
									id="utm_ns"
                                    title="UTM_NS"
									class="reqdClr"
									value="#utm_ns#">
							</div>
						</td>
					</tr>
				</table><!---- /coordinates ---->

				<cfif collection_cde is "ES" or collection_cde is "VP" or collection_cde is "IP">
				    <!---------- geology ---------->
					<div id="geolCell">
						<table>
							<tr>
                                <h3 class="wikilink">Geol. Attributes<img src="/images/info.gif" onClick="getMCZDocs('Geology Attributes - Data Entry')" class="likeLink" alt="[ help ]"></h3>

								<td>
								
									<table>
										<tr>
											<th><span class="f11a">Geol Att.</span></th>
											<th><span class="f11a">Geol Att. Value</span></th>
											<th><span class="f11a">Determiner</span></th>
											<th><span class="f11a">Date</span></th>
											<th><span class="f11a">Method</span></th>
											<th><span class="f11a">Remark</span></th>
										</tr>
										<cfloop from="1" to="6" index="i">
											<cfset thisAttribute= evaluate("data.geology_attribute_" & i)>
											<cfset thisVal= evaluate("data.geo_att_value_" & i)>
											<cfset thisDeterminer= evaluate("data.geo_att_determiner_" & i)>
											<cfset thisDate= evaluate("data.geo_att_determined_date_" & i)>
											<cfset thisMeth= evaluate("data.geo_att_determined_method_" & i)>
											<cfset thisRemark= evaluate("data.geo_att_remark_" & i)>
											<div id="#i#">
											<tr id="d_geology_attribute_#i#">
												<td>
													<select name="geology_attribute_#i#" id="geology_attribute_#i#" size="1" title="GEOLOGY_ATTRIBUTE_X" onchange="populateGeology(this.id);">
														<option value=""></option>
														<cfloop query="ctgeology_attribute">
															<option
																<cfif thisAttribute is geology_attribute> selected="selected" </cfif>
																	value="#geology_attribute#">#geology_attribute#</option>
														</cfloop>
													</select>
												</td>
												<td>
													<select title="GEO_ATT_VALUE_X" name="geo_att_value_#i#" id="geo_att_value_#i#">
														<option value="#thisVal#">#thisVal#</option>
													</select>
												</td>
												<td>
													<input type="text"
														name="geo_att_determiner_#i#"
														id="geo_att_determiner_#i#"
														value="#thisDeterminer#"
                                                        title="GEO_ATT_DETERMINER_X"
														onchange="getAgent('nothing',this.id,'dataEntry',this.value);"
														onkeypress="return noenter(event);">
												</td>
												<td>
													<input type="text"
                                                    title="GEO_ATT_DETERMINED_DATE_X"
														name="geo_att_determined_date_#i#"
														id="geo_att_determined_date_#i#"
														value="#thisDate#"
														>
												</td>
												<td>
													<input type="text"
														name="geo_att_determined_method_#i#"
                                                        title="GEO_ATT_DETERMINED_METHOD_X"
														id="geo_att_determined_method_#i#"
														value="#thisMeth#"
                                                       
														>
												</td>
												<td>
													<input type="text"
                                                    title="GEO_ATT_REMARK_X"
														name="geo_att_remark_#i#"
														id="geo_att_remark_#i#"
														value="#thisRemark#"
														>
												</td>
											</tr>
											</div>
										</cfloop>
									</table>
								</td>
							</tr>
						</table><!--- /geol attributes ---->
					</div>
				</cfif><!---- /geology ------->

			
         
		       </td><!--- end middle column --->
            <td class="rightColumn" valign="top" style="border: 1px grooved green;">
                         
                 <table class="attributes">
				    <!----- attributes ------->
					<tr>
                        <h3 class="wikilink">Attributes<img src="/images/info.gif" onClick="getMCZDocs('Attributes - Data Entry')" class="likeLink" alt="[ help ]">
                        </h3>
                       
						<td>
							<cfif collection_cde is not "Crus" and collection_cde is not "Herb"
								and collection_cde is not "ES" and collection_cde is not "Ich"
								and collection_cde is not "Para" and collection_cde is not "Art" and not
								(collection_cde is "Herp" and institution_acronym is "UAM") and not
								(collection_cde is "Herp" and institution_acronym is "MCZ") and not
								(collection_cde is "HerpOBS" and institution_acronym is "MCZ")>
								<table style="border: none;">
									<tr>
									
										<td nowrap="nowrap">
											<span class="f11a">Sex</span>
											 <input type="hidden" name="attribute_1" value="sex">
											 <select title="ATTRIBUTE_VALUE_1" name="attribute_value_1" onChange="changeSex(this.value)"
												id="attribute_value_1"
												<cfif #collection_cde# NEQ "IP" and #collection_cde# NEQ "VP" And #collection_cde# NEQ "IZ" And #collection_cde# NEQ "Mala" And #collection_cde# NEQ "Orn" And #collection_cde# NEQ "Herp" And #collection_cde# NEQ "HerpOBS" And #collection_cde# NEQ "Ich" And #collection_cde# NEQ "SC" And #collection_cde# NEQ "Cryo" And #collection_cde# NEQ "Ent">
													class="reqdClr d11a"
												<cfelse>
													class="d11a"
												</cfif>
												class="reqdClr"
												style="width: 60px">
												<option value=""></option>
												<cfloop query="ctSex_Cde">
													<option
														<cfif data.attribute_value_1 is #Sex_Cde#> selected </cfif>value="#Sex_Cde#">#Sex_Cde#</option>
												</cfloop>
											 </select>
											<span class="f11a">Date</span>
											<input type="text" style="width:66px;" title="ATTRIBUTE_DATE_X" name="attribute_date_1" value="#attribute_date_1#" id="attribute_date_1" size="17"
											<cfif #collection_cde# NEQ "IP" and #collection_cde# NEQ "VP" And #collection_cde# NEQ "IZ" And #collection_cde# NEQ "Mala" And #collection_cde# NEQ "Orn" And #collection_cde# NEQ "Herp" And #collection_cde# NEQ "HerpOBS" And #collection_cde# NEQ "Ich" And #collection_cde# NEQ "SC" And #collection_cde# NEQ "Cryo" And #collection_cde# NEQ "Ent">
														class="reqdClr"
											</cfif>
											>
											<span class="infoLink" onclick="copyAttributeDates('attribute_date_1');">Copy</span>&nbsp;&nbsp;
											<span class="f11a">Determiner</span>
											<input type="text"
                                            title="ATTRIBUTE_DETERMINER_X"
												name="attribute_determiner_1" size="16"
												value="#attribute_determiner_1#"
												<cfif #collection_cde# NEQ "IP" and #collection_cde# NEQ "VP" And #collection_cde# NEQ "IZ" And #collection_cde# NEQ "Mala" And #collection_cde# NEQ "Orn" And #collection_cde# NEQ "Herp" And #collection_cde# NEQ "HerpOBS" And #collection_cde# NEQ "Ich" And #collection_cde# NEQ "SC" And #collection_cde# NEQ "Cryo" And #collection_cde# NEQ "Ent">
													class="reqdClr"
												</cfif>
												onchange="getAgent('nothing',this.id,'dataEntry',this.value);"
												onkeypress="return noenter(event);"
												onblur="doAttributeDefaults();"
												id="attribute_determiner_1" />
											<span class="infoLink" onclick="copyAttributeDetr('attribute_determiner_1');">Copy</span>&nbsp;&nbsp;
											<span class="f11a">Method</span>
											<input title="ATTRIBUTE_DET_METH_1" size="16" type="text" name="attribute_det_meth_1"
												value="#attribute_det_meth_1#"
												id="attribute_det_meth_1">
										</td>
									</tr>
								</table><!--- some of the first customized atts by dept. --->
							<cfelse>
								<input type="hidden" name="attribute_1" id="attribute_1" value="">
								<input type="hidden" name="attribute_value_1"  id="attribute_value_1" value="">
								<input type="hidden" name="attribute_date_1"  id="attribute_date_1" value="">
								<input type="hidden" name="attribute_determiner_1"  id="attribute_determiner_1" value="">
								<input type="hidden" name="attribute_det_meth_1"  id="attribute_det_meth_1" value="">
							</cfif>
							<table noborder style="border: none;">
								<cfif collection_cde is "Mamm">
									<tr>
										<td><span class="f11a">len</span></td>
										<td><span class="f11a">tail</span></td>
										<td><span class="f11a">Hind Foot</span></td>
										<td><span class="f11a">Ear From Notch</span></td>
										<td><span class="f11a">Units</span></td>
										<td colspan="2" align="left"><span class="f11a">Weight</span></td>
										<td><span class="f11a">Date</span></td>
										<td><span class="f11a">Determiner</span></td>
									<tr>
										<td>
											<input type="hidden" name="attribute_2" value="total length" />
											<input type="text" title="ATTRIBUTE_VALUE_2" name="attribute_value_2" value="#attribute_value_2#" size="3" id="attribute_value_2">
										</td>
										<td>
											<input type="hidden" name="attribute_units_3" value="#attribute_units_3#" id="attribute_units_3" />
											<input type="hidden" name="attribute_date_3" value="#attribute_date_3#" id="attribute_date_3" />
											<input type="hidden" name="attribute_determiner_3" value="#attribute_determiner_3#" id="attribute_determiner_3" />
											<input type="hidden" name="attribute_3" value="tail length" />
											<input type="text" title="ATTRIBUTE_VALUE_3" name="attribute_value_3" value="#attribute_value_3#" size="3" id="attribute_value_3">
										</td>
										<td align='center'>
											<input type="hidden" name="attribute_units_4" value="#attribute_units_4#" id="attribute_units_4" />
											<input type="hidden" name="attribute_date_4" value="#attribute_date_4#" id="attribute_date_4" />
											<input type="hidden" name="attribute_determiner_4" value="#attribute_determiner_4#" id="attribute_determiner_4" />
											<input type="hidden" name="attribute_4" value="hind foot with claw" />
											<input type="text"  name="attribute_value_4" value="#attribute_value_4#" title="ATTRIBUTE_VALUE_4" size="3" id="attribute_value_4">
										</td>
										<td align='center'>
											<input type="hidden" name="attribute_units_5" value="#attribute_units_5#" id="attribute_units_5" />
											<input type="hidden" name="attribute_date_5" value="#attribute_date_5#" id="attribute_date_5" />
											<input type="hidden" name="attribute_determiner_5" value="#attribute_determiner_5#" id="attribute_determiner_5" />
											<input type="hidden" name="attribute_5" value="ear from notch" />
											<input type="text" title="ATTRIBUTE_VALUE_5" name="attribute_value_5" value="#attribute_value_5#" size="3" id="attribute_value_5">
										</td>
										<td>
											<select name="attribute_units_2" size="1" id="attribute_units_2">
												<option value=""></option>
												<cfloop query="ctLength_Units">
													<option <cfif #data.attribute_units_2# is #Length_Units#> selected </cfif>
													value="#Length_Units#">#Length_Units#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<input type="hidden" name="attribute_date_6" value="#attribute_date_6#" id="attribute_date_6" />
											<input type="hidden" name="attribute_determiner_6" value="#attribute_determiner_6#" id="attribute_determiner_6" />
											<input type="hidden" name="attribute_6" value="weight" size="12" />
											<input type="text" title="ATTRIBUTE_VALUE_6" name="attribute_value_6" value="#attribute_value_6#" size="3" id="attribute_value_6">
										</td>
										<td style="width: 35px;">
											<select name="attribute_units_6" title="ATTRIBUTE_UNITS_6" id="attribute_units_6" style="width:35px;">
												<option value=""></option>
												<cfloop query="ctWeight_Units">
													<option <cfif #data.attribute_units_6# is #Weight_Units#> selected </cfif>value="#Weight_Units#">#Weight_Units#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<input type="text" title="ATTRIBUTE_DATE_2" name="attribute_date_2" id="attribute_date_2" value="#attribute_date_2#" style="width: 60px;">
										</td>
										<td>
											<input type="text" title="ATTRIBUTE_DETERMINER_2" name="attribute_determiner_2" id="attribute_determiner_2"
												value="#attribute_determiner_2#"
                                                   size="1" style="width:100px"
                                                title="ATTRIBUTE_DETERMINER_2"
												onchange="getAgent('nothing',this.id,'dataEntry',this.value);"
												onkeypress="return noenter(event);">

										</td>
									</tr>
								<cfelseif collection_cde is "Orn">
									<tr>
										<td><span class="f11a">Age Class</span></td>
										<td><span class="f11a">Fat Deposition</span></td>
										<td><span class="f11a">Molt Condition</span></td>
										<td><span class="f11a">Ossification</span></td>
										<td colspan="2" align="left"><span class="f11a">Weight</span></td>
										<td><span class="f11a">Date</span></td>
										<td><span class="f11a">Determiner</span></td>
									<tr>
										<td>
											<input type="hidden" name="attribute_2" value="age class" />
											<select name="attribute_value_2" size="1" id="attribute_value_2" >
												<option></option>
												<cfloop query="ctAge_Class">
													<option <cfif #data.attribute_value_2# is #Age_Class#> selected </cfif>value="#Age_class#">#Age_class#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<input type="hidden" name="attribute_date_3" value="#attribute_date_3#" id="attribute_date_3" />
											<input type="hidden" name="attribute_determiner_3" value="#attribute_determiner_3#" id="attribute_determiner_3" />
											<input type="hidden" name="attribute_3" value="fat deposition" />
											<input type="text" name="attribute_value_3"
                                                   size="10" value="#attribute_value_3#" id="attribute_value_3">
										</td>
										<td>
											<input type="hidden" name="attribute_date_4" value="#attribute_date_4#" id="attribute_date_4" />
											<input type="hidden" name="attribute_determiner_4" value="#attribute_determiner_4#" id="attribute_determiner_4" />
											<input type="hidden" name="attribute_4" value="molt condition" />
											<input type="text" name="attribute_value_4" size="10" value="#attribute_value_4#" id="attribute_value_4">
										</td>
										<td>
											<input type="hidden" name="attribute_date_5" value="#attribute_date_5#" id="attribute_date_5" />
											<input type="hidden" name="attribute_determiner_5" value="#attribute_determiner_5#" id="attribute_determiner_5" />
											<input type="hidden" name="attribute_5" value="ossification" />
											<input type="text" name="attribute_value_5" size="11" value="#attribute_value_5#" id="attribute_value_5">
										</td>
										<td>
											<input type="hidden" name="attribute_date_6" value="#attribute_date_6#" id="attribute_date_6" />
											<input type="hidden" name="attribute_determiner_6" value="#attribute_determiner_6#" id="attribute_determiner_6" />
											<input type="hidden" name="attribute_6" value="weight" />
											<input type="text" name="attribute_value_6" size="9" value="#attribute_value_6#" id="attribute_value_6">
										</td>
										<td style="width: 30px;">
											<select name="attribute_units_6" size="1" id="attribute_units_6" >
												<cfloop query="ctWeight_Units">
													<option <cfif #data.attribute_units_6# is #Weight_Units#> selected </cfif>value="#Weight_Units#">#Weight_Units#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<input type="text" name="attribute_date_2" id="attribute_date_2" value="#attribute_date_2#" size="10">
										</td>
										<td>
											<input type="text"
												name="attribute_determiner_2"
												id="attribute_determiner_2"
												value="#attribute_determiner_2#"
												onchange="getAgent('nothing',this.id,'dataEntry',this.value);"
												onkeypress="return noenter(event);" size="12">
										</td>
									</tr>
								<cfelse>
                                    <!--- maintain attributes 2-6 as hiddens to not break the JS --->
									<cfloop from="2" to="6" index="i">
										<input type="hidden" name="attribute_#i#" id="attribute_#i#" value="">
										<input type="hidden" name="attribute_value_#i#"  id="attribute_value_#i#" value="">
										<input type="hidden" name="attribute_date_#i#"  id="attribute_date_#i#" value="">
										<input type="hidden" name="attribute_determiner_#i#"  id="attribute_determiner_#i#" value="">
										<input type="hidden" name="attribute_det_meth_#i#"  id="attribute_det_meth_#i#" value="" >
									</cfloop>
								</cfif>
							</table><!----/dept attributes---->
							<table noborder style="border: none;"><!----main attributes--->
								<tr>
									<th>Attribute</th>
									<th>Value</th>
									<th>Units</th>
									<th>Date</th>
									<th>Determiner</th>
									<th>Method</th>
								
								</tr>
								<cfloop from="7" to="10" index="i">
									<tr id="de_attribute_#i#">
											<td style="width:25%;">
											<select title="ATTRIBUTE_X" name="attribute_#i#" onChange="getAttributeStuff(this.value,this.id);"
												id="attribute_#i#">
												<option value="" >&nbsp;&nbsp;&nbsp;&nbsp;</option>
												<cfloop query="ctAttributeType">
													<option <cfif evaluate("data.attribute_" & i) is ctAttributeType.attribute_type> selected="selected" </cfif>
														value="#attribute_type#">#attribute_type#</option>
												</cfloop>
											</select>
										</td>
											<td>
											<div id="attribute_value_cell_#i#">
												<input type="text" title="ATTRIBUTE_VALUE_X" name="attribute_value_#i#" value="#evaluate("data.attribute_value_" & i)#"
													id="attribute_value_#i#" size="13">
											</div>
										</td>
										<td>
											<div id="attribute_units_cell_#i#">
											<input type="text" title="ATTRIBUTE_UNITS_X" size="10" name="attribute_units_#i#"  value="#evaluate("data.attribute_units_" & i)#"
												id="attribute_units_#i#">
											</div>
										</td>
											<td>
											<input type="text" title="ATTRIBUTE_DATE_X" size ="10" name="attribute_date_#i#" value="#evaluate("data.attribute_date_" & i)#"
												id="attribute_date_#i#">
										</td>
											<td>
											 <input type="text" name="attribute_determiner_#i#"
												id="attribute_determiner_#i#" 
                                                title="ATTRIBUTE_DETERMINER_X"
												value="#evaluate("data.attribute_determiner_" & i)#"
												onchange="getAgent('nothing',this.id,'dataEntry',this.value);"
												onkeypress="return noenter(event);" size="12">
										</td>
											<td>
											<input type="text" name="attribute_det_meth_#i#"
												title="ATTRIBUTE_DET_METH_X" id="attribute_det_meth_#i#" size="13" value="#evaluate("data.attribute_det_meth_" & i)#">
										</td>
                                    </tr>
                                    <tr>
										<td colspan="6">
                                            
											<input type="text" title="ATTRIBUTE_REMARKS_X" name="attribute_remarks_#i#"
                                                size="140"
												id="attribute_remarks_#i#"
												value="#evaluate("data.attribute_remarks_" & i)#" style="font-size: 10px;color: ##666;"
                                                   placeholder="&nbsp;remarks for attribute #i#">
										</td>
									</tr>
								</cfloop>
							</table><!----/main attritbutes---->
						</td>
					</tr>
				</table><!---- /attributes ----->
   



	<SCRIPT language="javascript">
		function addRow(tableID) {

			var table = document.getElementById(tableID);

			var rowCount = table.rows.length;
			var row = table.insertRow(rowCount);

			var cell1 = row.insertCell(0);
			var element1 = document.createElement("input");
			element1.type = "checkbox";
			element1.name="chkbox[]";
			cell1.appendChild(element1);

			var cell2 = row.insertCell(1);
			cell2.innerHTML = rowCount + 1;

			var cell3 = row.insertCell(2);
			var element3 = document.createElement("input");
			element3.type = "text";
            element3.id = "part_name_#i#";
			element3.name = "part_name_#i#";
            element3.size = "13";
			cell3.appendChild(element3);

            var cell4 = row.insertCell(3);
			var element4 = document.createElement("select");
			element4.type = "text";
            element4.id = "preserv_method_#i#";
			element4.name = "preserv_method_#i#";
            element4.style = "width: 65px;";
			cell4.appendChild(element4);
            
              var cell5 = row.insertCell(4);
			var element5 = document.createElement("input");
			element5.type = "text";
            element5.id = "part_condition_#i#";
			element5.name = "part_condition_#i#";
            element5.size= "15";
            
			cell5.appendChild(element5);
            
              var cell6 = row.insertCell(5);
			var element6 = document.createElement("select");
			element6.type = "text";
            element6.id = "part_disposition_#i#";
			element6.name = "part_disposition_#i#";
             element6.style = "width:89px;";
			cell6.appendChild(element6);
            
              var cell7 = row.insertCell(6);
			var element7 = document.createElement("select");
			element7.type = "text";
            element7.id = "part_lot_cnt_mod_#i#";
			element7.name = "part_lot_cnt_mod_#i#";
            element7.style = "width: 45px;";
			cell7.appendChild(element7);
            
              var cell8 = row.insertCell(7);
			var element8 = document.createElement("input");
			element8.type = "text";
            element8.id = "part_lot_count_#i#";
			element8.name = "part_lot_count_#i#";
            element8.size = "1";
			cell8.appendChild(element8);
            
              var cell9 = row.insertCell(8);
			var element9 = document.createElement("input");
			element9.type = "text";
            element9.id = "part_barcode_#i#";
			element9.name = "part_barcode_#i#";
            element9.size= "13";
			cell9.appendChild(element9);
            
              var cell10 = row.insertCell(9);
			var element10 = document.createElement("input");
			element10.type = "text";
            element10.id = "part_remark_#i#";
			element10.name = "part_remark_#i#";
            element10.size = "9";
			cell10.appendChild(element10);
            
             var cell11 = row.insertCell(10);
			var element11 = document.createElement("input");
			element11.type = "button";
            element11.id = "showDialog_#i#";
			element11.name = "showDialog_#i#";
            element11.size = "9";
			cell11.appendChild(element11);
		}

		function deleteRow(tableID) {
			try {
			var table = document.getElementById(tableID);
			var rowCount = table.rows.length;

			for(var i=0; i<rowCount; i++) {
				var row = table.rows[i];
				var chkbox = row.cells[0].childNodes[0];
				if(null != chkbox && true == chkbox.checked) {
					table.deleteRow(i);
					rowCount--;
					i--;
				}
			}
			}catch(e) {
				alert(e);
			}
		}

	</SCRIPT>
	<INPUT type="button" value="Add Row" onclick="addRow('dataTable')" />

	<INPUT type="button" value="Delete Row" onclick="deleteRow('dataTable')" />

	<TABLE id="dataTable" width="auto">
		<TR>
			<TD><INPUT type="checkbox" name="chk"/></TD>
			<TD> 1 </TD>
            <td><label>Part Name</label>
			<cfset tpn=evaluate("data.part_name_" & i)>
								<input type="text"  placeholder=" &nbsp;part #i#" name="part_name_#i#" id="part_name_#i#" size="13" <cfif i is 1>class="reqdClr"</cfif>
									value="#tpn#"
									onchange="findPart(this.id,this.value,'#collection_cde#');requirePartAtts('#i#',this.value);"
									onkeypress="return noenter(event);">
							</td>
            		<td><label>Preserve</label>
								<cfset tprm=evaluate("data.preserv_method_" & i)>
								<select id="preserv_method_#i#"  style="width: 65px;" name="preserv_method_#i#" <cfif i is 1>class="reqdClr"</cfif>>
									<option value=""></option>
									<cfloop query="ctPresMeth">
										<option
											<cfif evaluate("data.preserv_method_" & i) is ctPresMeth.PRESERVE_METHOD> selected="selected" </cfif>
										 	value="#PRESERVE_METHOD#">#PRESERVE_METHOD#</option>
									</cfloop>
								</select>
							</td>
                            <td>
                            <label>Condition</label>
                                    <input type="text" name="part_condition_#i#" id="part_condition_#i#" size="15"
									<cfif i is 1>class="reqdClr" </cfif>value="#evaluate("data.part_condition_" & i)#"></td>

                            <td><label>Disposition</label>
								<select id="part_disposition_#i#" name="part_disposition_#i#" style="width:89px;"<cfif i is 1>class="reqdClr"</cfif>>
									<option value=""></option>
									<cfloop query="CTCOLL_OBJ_DISP">
										<option
											<cfif evaluate("data.part_disposition_" & i) is CTCOLL_OBJ_DISP.COLL_OBJ_DISPOSITION> selected="selected" </cfif>
										 	value="#COLL_OBJ_DISPOSITION#">#COLL_OBJ_DISPOSITION#</option>
									</cfloop>
								</select>
							</td>
                            <td><label>##Mod.</label>
								<select id="part_lot_cnt_mod_#i#" name="part_lot_cnt_mod_#i#">
									<option value=""></option>
									<cfloop query="ctModifiers">
										<option
											<cfif evaluate("data.part_lot_cnt_mod_" & i) is ctModifiers.MODIFIER> selected="selected" </cfif>
										 	value="#MODIFIER#">#MODIFIER#</option>
									</cfloop>
								</select>
							</td>
                            <td><label>##</label>
								<input type="text" name="part_lot_count_#i#" id="part_lot_count_#i#" value="#evaluate("data.part_lot_count_" & i)#"
									<cfif i is 1>class="reqdClr" </cfif>size="1">
							</td>
							<td><label>Barcode</label>
								<input type="text" name="part_barcode_#i#" id="part_barcode_#i#"
                                       size="13" value="#evaluate("data.part_barcode_" & i)#"
								 onchange="part_container_label_#i#.className='reqdClr';setPartLabel(this.id);">
							</td>
                        <td><label>Remarks</label>
								<input type="text" name="part_remark_#i#" id="part_remark_#i#" size="9" placeholder=" &nbsp;remarks for part #i#"  
									value="#evaluate("data.part_remark_" & i)#">
							</td>
                           <td><label>att</label>
			                    <input type="button" class="part_att_btn" id="showDialog_#i#" value="+" style="padding: 5px;">
			                       <script type='text/javascript'>
			                         $(function() {
			                            $('##dialog_#i#').dialog({
			                                autoOpen: false,
			                                minWidth: 600,
			                                minHeight: 350,
			                                appendTo: "form##dataEntry",
			                                buttons: [
			                                   {
			                                      text: "Ok",
			                                      icons: {
			                                         primary: "ui-icon-heart"
			                                      },
			                                      click: function() {
			                                         $( this ).dialog( "close" );
			                                      }
			                                   }
			                                ]
			                             });
			                         });

			                         $("##showDialog_#i#").click(function(event) {
			                             event.preventDefault();
			                             $("##dialog_#i#_head").html("Part #i# " + $("##part_name_#i#").val() + $("##preserv_method_#i#").val() );
			                             $( "##dialog_#i#" ).dialog( "open" );
			                         });

			                       </script>
			                   <div id="dialog_#i#" title="Attributes for Part #i# #tpn# #tprm#">
			                   <div id="dialog_#i#_head">Part #i# #tpn# #tprm#</div>
			                   <cfloop from="1" to="8" index="j">
			                      <cfset pan=evaluate("data.part_" & i & "_att_name_" & j)>
			                        <div class="div1">
			                        <ul class="atts">
			                        <li><span>Attribute #j#</span>
			                        <input class="part_at" type="text" name="part_#i#_att_name_#j#" id="part_#i#_att_name_#j#" value="#pan#" size="25" onkeypress="return noenter(event);"><input type="hidden" name="step2" value="yes">
			                        </li>
			                         <cfset pav=evaluate("data.part_" & i & "_att_val_" & j)>
			                         <li>
			                         <span>Value #j#</span>
			                         <input class="part_at" type="text" name="part_#i#_att_val_#j#" id="part_#i#_att_val_#j#" value="#pav#" size="25" onkeypress="return noenter(event);">
			                         </li>
			                         <cfset pau=evaluate("data.part_" & i & "_att_units_" & j)>
			                         <li>
			                         <span>Units #j#</span>
			                         <input class="part_at" type="text" name="part_#i#_att_units_#j#" id="part_#i#_att_units_#j#" value="#pau#" size="25" onkeypress="return noenter(event);">
			                         </li>
			                         <cfset pad=evaluate("data.part_" & i & "_att_detby_" & j)>
			                         <li>
			                         <span>Det. By #j#</span>
			                         <input class="part_at" type="text" name="part_#i#_att_detby_#j#" id="part_#i#_att_detby_#j#" value="#pad#" size="25" onkeypress="return noenter(event);">
			                         </li>
			                         <cfset pam=evaluate("data.part_" & i & "_att_madedate_" & j)>
			                         <li>
			                         <span>Made Date #j#</span>
			                         <input class="part_at" type="text" name="part_#i#_att_madedate_#j#" id="part_#i#_att_madedate_#j#" value="#pam#" size="25" onkeypress="return noenter(event);">
			                         </li>
			                          <cfset par=evaluate("data.part_" & i & "_att_rem_" & j)>
			                          <li>
			                         <span>Remark #j#</span>
			                         <input class="part_at" type="text" name="part_#i#_att_rem_#j#" id="part_#i#_att_rem_#j#" value="#par#" size="25" onkeypress="return noenter(event);">
			                         </li>
			                         </ul>
			                         </div>
			                      </cfloop>
			                      </div><!--- Popup attribute Dialog --->

			                 </td>
                              
		</TR>
	</TABLE>

                <table class="parts">
                    	
					<tr>
                        <h3 class="wikilink">Parts<img src="/images/info.gif" onClick="getMCZDocs('Parts - Data Entry')" class="likeLink" alt="[ help ]"></h3>
						<th><span class="f11a">Part Name</span></th>
						<th><span class="f11a">Preserve Method</span></th>
						<th><span class="f11a">Condition</span></th>
						<th><span class="f11a">Disposition</span></th>
						<th><span class="f11a">##Mod.</span></th>
						<th><span class="f11a">##</span></th>
						<th><span class="f11a">Barcode</span></th>
						
					</tr>
					<cfloop from="1" to="12" index="i">
						<tr id="d_part_name_#i#">
							<td>
								<cfset tpn=evaluate("data.part_name_" & i)>
								<input type="text"  placeholder=" &nbsp;part #i#" style="font-size:11px;color: ##666;" name="part_name_#i#" id="part_name_#i#" size="18" <cfif i is 1>class="reqdClr"</cfif>
									value="#tpn#"
									onchange="findPart(this.id,this.value,'#collection_cde#');requirePartAtts('#i#',this.value);"
									onkeypress="return noenter(event);">
							</td>
							<td>
								<cfset tprm=evaluate("data.preserv_method_" & i)>
								<select id="preserv_method_#i#" name="preserv_method_#i#" <cfif i is 1>class="reqdClr"</cfif>>
									<option value=""></option>
									<cfloop query="ctPresMeth">
										<option
											<cfif evaluate("data.preserv_method_" & i) is ctPresMeth.PRESERVE_METHOD> selected="selected" </cfif>
										 	value="#PRESERVE_METHOD#">#PRESERVE_METHOD#</option>
									</cfloop>
								</select>
							</td>
							<td style="padding-right: 1px;">
								<input type="text" name="part_condition_#i#" id="part_condition_#i#" size="15"
									<cfif i is 1>class="reqdClr" </cfif>value="#evaluate("data.part_condition_" & i)#">
							</td>
							<td>
								<select id="part_disposition_#i#" name="part_disposition_#i#" style="width:89px;"<cfif i is 1>class="reqdClr"</cfif>>
									<option value=""></option>
									<cfloop query="CTCOLL_OBJ_DISP">
										<option
											<cfif evaluate("data.part_disposition_" & i) is CTCOLL_OBJ_DISP.COLL_OBJ_DISPOSITION> selected="selected" </cfif>
										 	value="#COLL_OBJ_DISPOSITION#">#COLL_OBJ_DISPOSITION#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<select id="part_lot_cnt_mod_#i#" name="part_lot_cnt_mod_#i#">
									<option value=""></option>
									<cfloop query="ctModifiers">
										<option
											<cfif evaluate("data.part_lot_cnt_mod_" & i) is ctModifiers.MODIFIER> selected="selected" </cfif>
										 	value="#MODIFIER#">#MODIFIER#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<input type="text" name="part_lot_count_#i#" id="part_lot_count_#i#" value="#evaluate("data.part_lot_count_" & i)#"
									<cfif i is 1>class="reqdClr" </cfif>size="1">
							</td>
							<td>
								<input type="text" name="part_barcode_#i#" id="part_barcode_#i#" value="#evaluate("data.part_barcode_" & i)#"
								 onchange="part_container_label_#i#.className='reqdClr';setPartLabel(this.id);">
							</td>
                        </tr>
                        <tr>
							<td colspan="6">
               <input type="text" name="part_remark_#i#" id="part_remark_#i#" size="93" placeholder=" &nbsp;remarks for part #i#"  
									value="#evaluate("data.part_remark_" & i)#" style="font-size: 10px; color: ##666;">
               

							</td>
		                    <!---START Part Attribute Stuff --->
			                <td>
			                    <a class="part_att_btn" id="showDialog_#i#"> Part #i# Attributes</a>
			                       <script type='text/javascript'>
			                         $(function() {
			                            $('##dialog_#i#').dialog({
			                                autoOpen: false,
			                                minWidth: 600,
			                                minHeight: 350,
			                                appendTo: "form##dataEntry",
			                                buttons: [
			                                   {
			                                      text: "Ok",
			                                      icons: {
			                                         primary: "ui-icon-heart"
			                                      },
			                                      click: function() {
			                                         $( this ).dialog( "close" );
			                                      }
			                                   }
			                                ]
			                             });
			                         });

			                         $("##showDialog_#i#").click(function(event) {
			                             event.preventDefault();
			                             $("##dialog_#i#_head").html("Part #i# " + $("##part_name_#i#").val() + $("##preserv_method_#i#").val() );
			                             $( "##dialog_#i#" ).dialog( "open" );
			                         });

			                       </script>
			                   <div id="dialog_#i#" title="Attributes for Part #i# #tpn# #tprm#">
			                   <div id="dialog_#i#_head">Part #i# #tpn# #tprm#</div>
			                   <cfloop from="1" to="8" index="j">
			                      <cfset pan=evaluate("data.part_" & i & "_att_name_" & j)>
			                        <div class="div1">
			                        <ul class="atts">
			                        <li><span>Attribute #j#</span>
			                        <input class="part_at" type="text" name="part_#i#_att_name_#j#" id="part_#i#_att_name_#j#" value="#pan#" size="25" onkeypress="return noenter(event);"><input type="hidden" name="step2" value="yes">
			                        </li>
			                         <cfset pav=evaluate("data.part_" & i & "_att_val_" & j)>
			                         <li>
			                         <span>Value #j#</span>
			                         <input class="part_at" type="text" name="part_#i#_att_val_#j#" id="part_#i#_att_val_#j#" value="#pav#" size="25" onkeypress="return noenter(event);">
			                         </li>
			                         <cfset pau=evaluate("data.part_" & i & "_att_units_" & j)>
			                         <li>
			                         <span>Units #j#</span>
			                         <input class="part_at" type="text" name="part_#i#_att_units_#j#" id="part_#i#_att_units_#j#" value="#pau#" size="25" onkeypress="return noenter(event);">
			                         </li>
			                         <cfset pad=evaluate("data.part_" & i & "_att_detby_" & j)>
			                         <li>
			                         <span>Det. By #j#</span>
			                         <input class="part_at" type="text" name="part_#i#_att_detby_#j#" id="part_#i#_att_detby_#j#" value="#pad#" size="25" onkeypress="return noenter(event);">
			                         </li>
			                         <cfset pam=evaluate("data.part_" & i & "_att_madedate_" & j)>
			                         <li>
			                         <span>Made Date #j#</span>
			                         <input class="part_at" type="text" name="part_#i#_att_madedate_#j#" id="part_#i#_att_madedate_#j#" value="#pam#" size="25" onkeypress="return noenter(event);">
			                         </li>
			                          <cfset par=evaluate("data.part_" & i & "_att_rem_" & j)>
			                          <li>
			                         <span>Remark #j#</span>
			                         <input class="part_at" type="text" name="part_#i#_att_rem_#j#" id="part_#i#_att_rem_#j#" value="#par#" size="25" onkeypress="return noenter(event);">
			                         </li>
			                         </ul>
			                         </div>
			                      </cfloop>
			                      </div><!--- Popup attribute Dialog --->

			                 </td>
                              
		                     <!---END Part Attribute stuff --->
						</tr>
					</cfloop>
				</table><!----/parts--->
                                   
         
                                   
            </td>
		</tr><!---- end top row of page --->
</table>


<table>
		<tr>
		<td colspan="3">
			<table class="bottom_band">
				<tr>
					<td>
						<span id="theNewButton" style="display:none;">
							<input type="button" value="Save This As A New Record" class="insBtn" style="font-size:14px; padding: 2px 4px;"
								onclick="saveNewRecord();"/>
						 </span>
					</td>
					<td>
						<span id="enterMode" style="display:none;">
							<input type="button" style="font-size: 14px;padding: 2px 4px;"
								value="Edit Last Record"
								class="lnkBtn"
								onclick="editThis();">
						</span>
						<span id="editMode" style="display:none">
								<input type="button"
									value="Clone This Record"
									class="lnkBtn"
									onclick="createClone();">
						</span>
					</td>
					<td>
						 <span id="theSaveButton" style="display:none;">
							<input type="button" value="Save Edits" class="savBtn" onclick="saveEditedRecord();" />
							<input type="button" value="Delete Record" class="delBtn" onclick="deleteThisRec();" />
						</span>
					</td>
					<td>
					
						<a style="font-size: 14px;" href="userBrowseBulkedGrid.cfm?action=ajaxGrid">[ AJAX table ]</a>
					</td>
					<td style="font-size: 14px;">
						<span id="recCount">#whatIds.recordcount#</span> records
						<span id="browseThingy">
							 - Jump to
							<!-- span class="infoLink" id="pBrowse" onclick="browseTo('previous')">[ previous ]</span -->
							<select name="browseRecs" size="1" id="selectbrowse" onchange="loadRecord(this.value);">
								<cfset recposn=1>
								<cfloop query="whatIds">
									<option
										<cfif data.collection_object_id is whatIds.collection_object_id> selected="selected" </cfif>
										value="#collection_object_id#">#collection_object_id#</option>
									<cfset idList = "#idList#,">
									<cfset recposn=recposn+1>
								</cfloop>
							</select>
							<!-- span id="nBrowse" class="infoLink" onclick="browseTo('next')">[ next ]</span -->
						</span>
					</td>
				</tr>
			</table>
            <table>
                <tr>
                    <td>
						<span class="f11a status2">Status:&nbsp;&nbsp;</span>
                        <span class="destatus">#loaded#</span>
				    </td>
                </tr>
            </table>
 
   		</td>
	</tr>
</table>
</form>
</div>
<!--- TODO: Evaluate if the logic in v2.5.1 line 3417 to 3536 has been refactored out to supporting functions or if it needs to be incorporated --->

<cfif len(loadedMsg) gt 0>
	<cfset pMode = 'edit'>
</cfif>

<cfset loadedMsg = replace(loadedMsg,"'","`","all")>
<script language="javascript" type="text/javascript">
	switchActive('#orig_lat_long_units#');
	highlightErrors('#trim(loadedMsg)#');
	changeMode('#pMode#');
	pickedLocality();
</script>
<cfif isdefined("session.rememberLastOtherId") and session.rememberLastOtherId is 1 and pMode is "enter">
	<cftry>
		<cfset cVal="">
		<cfif isnumeric(other_id_num_5)>
			<cfset cVal = other_id_num_5 + 1>
		<cfelseif isnumeric(right(other_id_num_5,len(other_id_num_5)-1))>
			<cfset temp = (right(other_id_num_5,len(other_id_num_5)-1)) + 1>
			<cfset cVal = left(other_id_num_5,1) & temp>
		</cfif>
		<script language="javascript" type="text/javascript">
			var cid = document.getElementById('other_id_num_5').value='#cVal#';
		</script>
	<cfcatch>
		<cfmail to="bhaley@oeb.harvard.edu" subject="data entry catch" from="wtf@#Application.fromEmail#" type="html">
			other_id_num_5: #other_id_num_5#
			<cfdump var=#cfcatch#>
		</cfmail>
	</cfcatch>
	</cftry>
</cfif>
</cfoutput>
</cfif>
</div>
<cfinclude template="/includes/_footer.cfm">
