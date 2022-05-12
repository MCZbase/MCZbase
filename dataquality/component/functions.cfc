<!---
/dataquality/component/functions.cfc

Copyright 2022 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Invocations of TDWG Biodiversity Data Quality Task Group 2 CORE
test implementations in the event_date_qc, sci_name_qc, and geo_ref_qc
libraries found in github.com/filteredpush/ repositories.

--->
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- obtain QC report concerning Geospatial terms on a record from flat or from locality 
  @param target_id the collection_object_id or locality_id for which to run tests
  @param target FLAT or LOCALITY to specify whether target_id is for a collection object or a locality.
  @return a json serialization of a structure containing preamendment, amendment, and postamendment
    phase structures containing lists of test results identified by test guid and containing 
    label, type, status, comment, value terms.
--->
<cffunction name="getSpaceQCReport" access="remote">
	<cfargument name="target_id" type="string" required="yes">
	<cfargument name="target" type="string" required="yes">

	<cfset result=structNew()> <!--- overall result to return --->
	<cfset r=structNew()><!--- temporary result for an individual test, create new after each test --->
	<cfset preamendment=structNew()><!--- pre-amendment phase measures and validations --->
	<cfset amendment=structNew()><!--- amendment phase --->
	<cfset postamendment=structNew()><!--- post-amendment phase measures and validations --->
	<cftry>
		<cfswitch expression="#ucase(target)#">
			<cfcase value="FLAT">
				<cfquery name="queryrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT guid as item_label, 
						basisofrecord,
						highergeographyid,
						continent, country, countrycode,
						spec_locality as locality,
						dec_lat as decimal_latitude, dec_long as decimal_longitude, datum as geodeticDatum,
						verbatimlatitude, verbatimlongitude, verbatimelevation, verbatimlocality, 
						max_depth_in_m, min_depth_in_m, max_elev_in_m, min_elev_in_m,
						waterbody, island_group, island
					FROM DIGIR_QUERY.digir_filtered_flat
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfcase value="LOCALITY">
				<cfquery name="queryrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT distinct locality_id as item_label, 
						'' as basisofrecord,
						highergeographyid,
						continent, country, countrycode,
						spec_locality as locality,
						dec_lat as decimal_latitude, dec_long as decimal_longitude, datum as geodeticDatum,
						verbatimlatitude, verbatimlongitude, verbatimelevation, verbatimlocality, 
						max_depth_in_m, min_depth_in_m, max_elev_in_m, min_elev_in_m,
						waterbody, island_group, island
					FROM DIGIR_QUERY.digir_filtered_flat
					WHERE locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
						and rownum < 2
				</cfquery>
			</cfcase>
			<cfdefaultcase>
				<cfthrow message="Unknown target type for geospatial report. Should be FLAT or LOCALITY">
			</cfdefaultcase>
		</cfswitch>
		<cfif queryrow.recordcount is 1>
			<cfset result.status="success">
			<cfset result.target_id=target_id >
			<cfset result.guid=queryrow.item_label>
			<cfset result.error="">

			<!--- store local copies of query results to use in pre-amendment phase and overwrite in ammendment phase  --->
			<cfset country = queryrow.country>
			<cfset countrycode = queryrow.countrycode>

			<cfobject type="Java" class="org.filteredpush.qc.georeference.DwCGeoRefDQ" name="dwcGeoRefDQ">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Mechanism" name="Mechanism">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Provides" name="Provides">
			<!--- Obtain mechanism from annotation on class --->
			<cfset result.mechanism = dwcGeoRefDQ.getClass().getAnnotation(Mechanism.getClass()).label() >

			<!--- pre-amendment phase --->
			<!--- TODO: Provide metadata from annotations --->

			<!--- @Provides("6ce2b2b4-6afe-4d13-82a0-390d31ade01c") --->
			<cfset dqResponse = dwcGeoRefDQ.validationCountryEmpty(country) >
			<cfset r.label = "dwc:country contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["6ce2b2b4-6afe-4d13-82a0-390d31ade01c"] = r >
			<cfset r=structNew()>

			<!--- @Provides("853b79a2-b314-44a2-ae46-34a1e7ed85e4") --->
			<cfset dqResponse = dwcGeoRefDQ.validationCountrycodeEmpty(countrycode) >
			<cfset r.label = "dwc:countryCode contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["853b79a2-b314-44a2-ae46-34a1e7ed85e4"] = r >
			<cfset r=structNew()>

			<!--- @Provides("0493bcfb-652e-4d17-815b-b0cce0742fbe") --->
			<cfset dqResponse = dwcGeoRefDQ.validationCountrycodeNotstandard(countrycode) >
			<cfset r.label = "dwc:countryCode is a standard value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["0493bcfb-652e-4d17-815b-b0cce0742fbe"] = r >
			<cfset r=structNew()>


			<!--- amendment phase --->


			<!--- post-amendment phase --->

			<!--- @Provides("6ce2b2b4-6afe-4d13-82a0-390d31ade01c") --->
			<cfset dqResponse = dwcGeoRefDQ.validationCountryEmpty(country) >
			<cfset r.label = "dwc:country contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["6ce2b2b4-6afe-4d13-82a0-390d31ade01c"] = r >
			<cfset r=structNew()>

			<!--- @Provides("853b79a2-b314-44a2-ae46-34a1e7ed85e4") --->
			<cfset dqResponse = dwcGeoRefDQ.validationCountrycodeEmpty(countrycode) >
			<cfset r.label = "dwc:countryCode contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["853b79a2-b314-44a2-ae46-34a1e7ed85e4"] = r >
			<cfset r=structNew()>

			<!--- @Provides("0493bcfb-652e-4d17-815b-b0cce0742fbe") --->
			<cfset dqResponse = dwcGeoRefDQ.validationCountrycodeNotstandard(countrycode) >
			<cfset r.label = "dwc:countryCode is a standard value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["0493bcfb-652e-4d17-815b-b0cce0742fbe"] = r >
			<cfset r=structNew()>

			<!--- Add results from phases to result to return --->

			<cfset result["preamendment"] = preamendment >

			<cfset result["amendment"] = amendment >

			<cfset result["postamendment"] = postamendment >

		<cfelse>
			<cfset result.status="fail">
			<cfset result.target_id=target_id>
			<cfset result.error="record not found">
		</cfif>
   <cfcatch>
		<cfset result.status="fail">
		<cfset result.target_id=target_id>
		<cfset line = cfcatch.tagcontext[1].line>
		<cfset result.error=cfcatch.message & '; ' & cfcatch.detail & ' [line:' & line & ']' >
   </cfcatch>
	</cftry>
   <cfreturn serializeJSON(result) >
</cffunction>

<cffunction name="lookupName" access="remote">
	<cfargument name="taxon_name_id" type="string" required="yes">

	<cfset result=structNew()> <!--- overall result to return --->

	<cftry>
		<cfquery name="queryrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT scientific_name as item_label, 
				kingdom, phylum, phylclass, phylorder, family, genus,
				scientific_name, author_text,
				taxonid,
				scientificnameid,
				taxon_name_id
			FROM taxonomy
			WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
		</cfquery>
	
		<cfif queryrow.recordcount EQ 1>
			<cfloop query="queryrow">

				<cfobject type="Java" class="org.filteredpush.qc.sciname.services.Validator" name="validator">
				<cfobject type="Java" class="org.filteredpush.qc.sciname.services.WoRMSService" name="wormsService">
				<cfobject type="Java" class="org.filteredpush.qc.sciname.services.GBIFService" name="gbifService">
				<cfobject type="Java" class="edu.harvard.mcz.nametools.NameUsage" name="nameUsage">
				<cfobject type="Java" class="edu.harvard.mcz.nametools.ICZNAuthorNameComparator" name="icznComparator">

				<cfset comparator = icznComparator.init(.75,.5)>
				<cfset lookupName = nameUsage.init()>
				<cfset lookupName.setInputDbPK(val(queryrow.taxon_name_id))>
				<cfset lookupName.setScientificName(queryrow.scientific_name)>
				<cfset lookupName.setAuthorship(queryrow.author_text)>
				<cfset lookupName.setAuthorComparator(comparator)>
				<cfif len(queryrow.family) GT 0>
					<cfset lookupName.setFamily(queryrow.family)>
				</cfif>
				<cfif len(queryrow.kingdom) GT 0>
					<cfset lookupName.setFamily(queryrow.kingdom)>
				</cfif>
				
				<!--- lookup in WoRMS --->
				<cfset wormsAuthority = wormsService.init(false)>
				<cfset returnName = wormsAuthority.validate(lookupName)>
				<cfset r=structNew()>
				<cfif isDefined("returnName")>
					<cfset r.matchDescription = returnName.getMatchDescription()>
					<cfset r.scientificName = returnName.getScientificName()>
					<cfset r.authorship = returnName.getAuthorship()>
					<cfset r.guid = returnName.getGuid()>
					<cfset r.authorStringDistance = returnName.getAuthorshipStringEditDistance()>
					<cfset r.habitatFlags = "">
				</cfif>
				<cfset result["WoRMS"] = r>

				<!--- lookup in GBIF Backbone --->
				<cfset gbifAuthority = gbifService.init()>
				<cfset returnName = gbifAuthority.validate(lookupName)>
				<cfset r=structNew()>
				<cfif isDefined("returnName")>
					<cfset r.matchDescription = returnName.getMatchDescription()>
					<cfset r.scientificName = returnName.getScientificName()>
					<cfset r.authorship = returnName.getAuthorship()>
					<cfset r.guid = returnName.getGuid()>
					<cfset r.authorStringDistance = returnName.getAuthorshipStringEditDistance()>
					<cfset r.habitatFlags = "">
				</cfif>
				<cfset result["GBIF Backbone"] = r>

				<!--- lookup in GBIF copy of paleobiology db --->
				<cfset gbifAuthority = gbifService.init(gbifService.KEY_PALEIOBIOLOGY_DATABASE)>
				<cfset returnName = gbifAuthority.validate(lookupName)>
				<cfset r=structNew()>
				<cfif isDefined("returnName")>
					<cfset r.matchDescription = returnName.getMatchDescription()>
					<cfset r.scientificName = returnName.getScientificName()>
					<cfset r.authorship = returnName.getAuthorship()>
					<cfset r.guid = returnName.getGuid()>
					<cfset r.authorStringDistance = returnName.getAuthorshipStringEditDistance()>
					<cfset r.habitatFlags = "">
				</cfif>
				<cfset result["Paleobiology DB in GBIF"] = r>
			</cfloop>
		</cfif>
   <cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
   </cfcatch>
	</cftry>
   <cfreturn serializeJSON(result) >
</cffunction>

<!-------------------------------------------->
<!--- obtain QC report concerning Taxon Name terms on a record from flat or from taxonomy 
  @param target_id the collection_object_id or taxon_name_id for which to run tests
  @param target FLAT or TAXONOMY to specify whether target_id is for a collection object or a taxon.
  @return a json serialization of a structure containing preamendment, amendment, and postamendment
    phase structures containing lists of test results identified by test guid and containing 
    label, type, status, comment, value terms.
--->
<cffunction name="getNameQCReport" access="remote">
	<cfargument name="target_id" type="string" required="yes">
	<cfargument name="target" type="string" required="yes">

	<cfset result=structNew()> <!--- overall result to return --->
	<cfset r=structNew()><!--- temporary result for an individual test, create new after each test --->
	<cfset preamendment=structNew()><!--- pre-amendment phase measures and validations --->
	<cfset amendment=structNew()><!--- amendment phase --->
	<cfset postamendment=structNew()><!--- post-amendment phase measures and validations --->
	<cftry>
		<cfswitch expression="#ucase(target)#">
			<cfcase value="FLAT">
				<cfquery name="queryrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT guid as item_label, 
						basisofrecord,
						kingdom, phylum, phylclass, phylorder, family, genus,
						scientific_name, author_text,
						taxonid,
						scientificnameid
					FROM DIGIR_QUERY.digir_filtered_flat
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfcase value="TAXONOMY">
				<cfquery name="queryrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT scientific_name as item_label, 
						'' as basisofrecord,
						kingdom, phylum, phylclass, phylorder, family, genus,
						scientific_name, author_text,
						taxonid,
						scientificnameid
					FROM taxonomy
					WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfdefaultcase>
				<cfthrow message="Unknown target type for taxon report. Should be FLAT or TAXONOMY">
			</cfdefaultcase>
		</cfswitch>
		<cfif queryrow.recordcount is 1>
			<cfset result.status="success">
			<cfset result.target_id=target_id >
			<cfset result.guid=queryrow.item_label>
			<cfset result.error="">

			<!--- store local copies of query results to use in pre-amendment phase and overwrite in ammendment phase  --->
			<cfset kingdom = queryrow.kingdom>
			<cfset phylum = queryrow.phylum>
			<cfset phylclass = queryrow.phylclass>
			<cfset phylorder = queryrow.phylorder>
			<cfset family = queryrow.family>
			<cfset genus = queryrow.genus>
			<cfset scientific_name = queryrow.scientific_name>
			<cfset author_text = queryrow.author_text>
			<cfset taxonid = queryrow.taxonid>
			<cfset scientificnameid = queryrow.scientificnameid>

			<cfobject type="Java" class="org.filteredpush.qc.sciname.DwCSciNameDQ" name="dwcSciNameDQ">
			<cfobject type="Java" class="org.filteredpush.qc.sciname.SciNameSourceAuthority" name="sciNameSourceAuthority">
			<cfobject type="Java" class="org.filteredpush.qc.sciname.DwCSciNameDQ" name="dwcSciNameDQ">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Mechanism" name="Mechanism">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Provides" name="Provides">
			<!--- Obtain mechanism from annotation on class --->
			<cfset result.mechanism = dwcSciNameDQ.getClass().getAnnotation(Mechanism.getClass()).label() >

			<cfset wormsAuthority = sciNameSourceAuthority.init("WORMS")>

			<!--- pre-amendment phase --->
			<!--- TODO: Provide metadata from annotations --->

			<!--- @Provides("7c4b9498-a8d9-4ebb-85f1-9f200c788595") --->
			<cfset dqResponse = dwcSciNameDQ.validationScientificnameEmpty(scientific_name) >
			<cfset r.label = "dwc:scientificName contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["7c4b9498-a8d9-4ebb-85f1-9f200c788595"] = r >
			<cfset r=structNew()>

			<!--- @Provides("401bf207-9a55-4dff-88a5-abcd58ad97fa") --->
			<cfset dqResponse = dwcSciNameDQ.validationTaxonidEmpty(taxonid) >
			<cfset r.label = "dwc:taxonId contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["401bf207-9a55-4dff-88a5-abcd58ad97fa"] = r >
			<cfset r=structNew()>

			<!--- @Provides("f2ce7d55-5b1d-426a-b00e-6d4efe3058ec") --->
			<cfset dqResponse = dwcSciNameDQ.validationGenusNotfound(genus,wormsAuthority) >
			<cfset r.label = "dwc:genus is known to WoRMS" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["f2ce7d55-5b1d-426a-b00e-6d4efe3058ec"] = r >
			<cfset r=structNew()>

			<!--- @Provides("3667556d-d8f5-454c-922b-af8af38f613c") --->
			<cfset dqResponse = dwcSciNameDQ.validationFamilyNotfound(family,wormsAuthority) >
			<cfset r.label = "dwc:family is known to WoRMS" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["3667556d-d8f5-454c-922b-af8af38f613c"] = r >
			<cfset r=structNew()>

			<!--- @Provides("81cc974d-43cc-4c0f-a5e0-afa23b455aa3") --->
			<cfset dqResponse = dwcSciNameDQ.validationOrderNotfound(phylorder,wormsAuthority) >
			<cfset r.label = "dwc:order is known to WoRMS" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["81cc974d-43cc-4c0f-a5e0-afa23b455aa3"] = r >
			<cfset r=structNew()>

			<!--- @Provides("eaad41c5-1d46-4917-a08b-4fd1d7ff5c0f") --->
			<cfset dqResponse = dwcSciNameDQ.validationPhylumNotfound(phylum,wormsAuthority) >
			<cfset r.label = "dwc:phylum is known to WoRMS" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["eaad41c5-1d46-4917-a08b-4fd1d7ff5c0f"] = r >
			<cfset r=structNew()>

			<!--- amendment phase --->

			<cftry>
			<!--- TODO: Throwing null pointer exception from lookupTaxon(String taxon, String author, boolean marineOnly) in WoRMSService --->
			<!---  @Provides("431467d6-9b4b-48fa-a197-cd5379f5e889") --->
			<cfset dqResponse = dwcSciNameDQ.amendmentTaxonidFromTaxon( taxonid, kingdom, phylum, phylclass, phylorder, family, genus, "", scientific_name, author_text, "", "", "", "", "", "", scientificnameid, "", "",wormsAuthority) >
			<cfset r.label = "lookup taxonID for taxon" >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "CHANGED">
				<cfset taxonid = dqResponse.getValue().getObject().get("dwc:taxonID") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["431467d6-9b4b-48fa-a197-cd5379f5e889"] = r >
			<cfset r=structNew()>
			<cfcatch>
			<cfset r=structNew()>
			</cfcatch>
			</cftry>

			<!--- post-amendment phase --->

			<!--- @Provides("7c4b9498-a8d9-4ebb-85f1-9f200c788595") --->
			<cfset dqResponse = dwcSciNameDQ.validationScientificnameEmpty(scientific_name) >
			<cfset r.label = "dwc:scientificName contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["7c4b9498-a8d9-4ebb-85f1-9f200c788595"] = r >
			<cfset r=structNew()>

			<!--- @Provides("401bf207-9a55-4dff-88a5-abcd58ad97fa") --->
			<cfset dqResponse = dwcSciNameDQ.validationTaxonidEmpty(taxonid) >
			<cfset r.label = "dwc:taxonId contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["401bf207-9a55-4dff-88a5-abcd58ad97fa"] = r >
			<cfset r=structNew()>

			<!--- @Provides("f2ce7d55-5b1d-426a-b00e-6d4efe3058ec") --->
			<cfset dqResponse = dwcSciNameDQ.validationGenusNotfound(genus,wormsAuthority) >
			<cfset r.label = "dwc:genus is known to WoRMS" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["f2ce7d55-5b1d-426a-b00e-6d4efe3058ec"] = r >
			<cfset r=structNew()>

			<!--- @Provides("3667556d-d8f5-454c-922b-af8af38f613c") --->
			<cfset dqResponse = dwcSciNameDQ.validationFamilyNotfound(family,wormsAuthority) >
			<cfset r.label = "dwc:family is known to WoRMS" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["3667556d-d8f5-454c-922b-af8af38f613c"] = r >
			<cfset r=structNew()>
	
			<!--- @Provides("81cc974d-43cc-4c0f-a5e0-afa23b455aa3") --->
			<cfset dqResponse = dwcSciNameDQ.validationOrderNotfound(phylorder,wormsAuthority) >
			<cfset r.label = "dwc:order is known to WoRMS" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["81cc974d-43cc-4c0f-a5e0-afa23b455aa3"] = r >
			<cfset r=structNew()>

			<!--- @Provides("eaad41c5-1d46-4917-a08b-4fd1d7ff5c0f") --->
			<cfset dqResponse = dwcSciNameDQ.validationPhylumNotfound(phylum,wormsAuthority) >
			<cfset r.label = "dwc:phylum is known to WoRMS" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["eaad41c5-1d46-4917-a08b-4fd1d7ff5c0f"] = r >
			<cfset r=structNew()>

			<!--- Add results from phases to result to return --->

			<cfset result["preamendment"] = preamendment >

			<cfset result["amendment"] = amendment >

			<cfset result["postamendment"] = postamendment >

		<cfelse>
			<cfset result.status="fail">
			<cfset result.target_id=target_id>
			<cfset result.error="record not found">
		</cfif>
    <cfcatch>
			<cfset result.status="fail">
			<cfset result.target_id=target_id>
			<cfset line = cfcatch.tagcontext[1].line>
			<cfset result.error=cfcatch.message & '; ' & cfcatch.detail & ' [line:' & line & ']' >
    </cfcatch>
	</cftry>
    <cfreturn serializeJSON(result) >
</cffunction>

<!-------------------------------------------->
<!--- obtain QC report concerning Event (temporal) terms on a record from flat
  @param target_id the collection_object_id or colecting_event_id for which to run tests
  @param target FLAT or COLLEVENT to specify whether target_id is for a collection object 
    or a collecting event.
  @return a json serialization of a structure containing preamendment, amendment, and postamendment
    phase structures containing lists of test results identified by test guid and containing 
    label, type, status, comment, value terms.
 --->
<cffunction name="getEventQCReportFlat" access="remote">
	<cfargument name="target_id" type="string" required="yes">
	<cfargument name="target" type="string" required="yes">

	<cfset result=structNew()> <!--- overall result to return --->
	<cfset r=structNew()><!--- temporary result for an individual test, create new after each test --->
	<cfset preamendment=structNew()><!--- pre-amendment phase measures and validations --->
	<cfset amendment=structNew()><!--- amendment phase --->
	<cfset postamendment=structNew()><!--- post-amendment phase measures and validations --->
	<cftry>
		<cfswitch expression="#ucase(target)#">
			<cfcase value="FLAT">
				<cfquery name="flatrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT guid as item_label,
						basisofrecord,
						began_date, ended_date, verbatim_date, day, month, year, 
						dayofyear, endDayOfYear,
						scientific_name, made_date
					FROM DIGIR_QUERY.digir_filtered_flat
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
				</cfquery>
			</cfcase>
			<cfcase value="COLLEVENT">
				<cfquery name="flatrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT collecting_event_id as item_label, 
						'' as basisofrecord,
						began_date, ended_date, verbatim_date, day, month, year, 
						dayofyear, endDayOfYear,
						scientific_name, made_date
					FROM DIGIR_QUERY.digir_filtered_flat
					WHERE collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">
						AND rownum < 2
				</cfquery>
			</cfcase>
			<cfdefaultcase>
				<cfthrow message="Unknown target type for taxon report. Should be FLAT or TAXONOMY">
			</cfdefaultcase>
		</cfswitch>

		<cfif flatrow.recordcount is 1>
			<cfset result.status="success">
			<cfset result.target_id=target_id>
			<cfset result.guid=flatrow.item_label>
			<cfset result.error="">

			<!--- store local copies of query results to use in pre-amendment phase  --->
			<cfif flatrow.began_date EQ flatrow.ended_date>
				<cfset eventDate = flatrow.began_date>
			<cfelse>
				<cfset eventDate = flatrow.began_date & "/" & flatrow.ended_date>
			</cfif>

			<cfset dateIdentified = flatrow.made_date>
			<cfset verbatimEventDate = flatrow.verbatim_date>
			<cfset startDayOfYear = ToString(flatrow.dayofyear) >
			<cfset endDayOfYear= flatrow.endDayOfYear >
			<cfset year=ToString(flatrow.year) >
			<cfset month=ToString(flatrow.month) >
			<cfset day=ToString(flatrow.day) >

			<cfobject type="Java" class="org.filteredpush.qc.date.DwCOtherDateDQ" name="dwcOtherDateQC">
			<cfobject type="Java" class="org.filteredpush.qc.date.DwCEventDQ" name="dwcEventDQ">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Mechanism" name="Mechanism">
			<cfobject type="Java" class="org.datakurator.ffdq.annotations.Provides" name="Provides">
			<!--- Obtain mechanism from annotation on class --->
			<cfset result.mechanism = dwcEventDQ.getClass().getAnnotation(Mechanism.getClass()).label() >

			<!--- pre-amendment phase --->

			<!--- @Provides("56b6c695-adf1-418e-95d2-da04cad7be53") --->
			<!--- TODO: Provide metadata from annotations --->
			<!---
			dwcEventDQ.getClass().getMethod('measureEventdatePrecisioninseconds',String.class).getAnnotation(Provides.getClass()).label();

			<cfset methodArray = dwcEventDQ.getClass().getMethods() >

			<cfloop from="0" to="#arraylen(methodArray)#" index="i">
				<cfset method = methodArray[i]>
				<cfset provides = method.getAnnotation(.getClass()).label() >

			</cfloop>

			--->

			<cfset dqResponse = dwcEventDQ.measureEventdatePrecisioninseconds(eventDate) >
			<cfset r.label = "dwc:eventDate precision in seconds" >
			<cfset r.type = "MEASURE" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT">
				<cfset r.value = dqResponse.getValue().getObject() >
				<cfset days = Round(r.value / 60 / 60 / 24)>
				<cfif days EQ 1><cfset s=""><cfelse><cfset s="s"></cfif>
				<cfset r.comment = dqResponse.getComment() & " (" & days & " day" & s &")" >
			<cfelse>
				<cfset r.value = "">
				<cfset r.comment = dqResponse.getComment()  >
			</cfif>
			<cfset preamendment["56b6c695-adf1-418e-95d2-da04cad7be53"] = r >
			<cfset r=structNew()>

			<!--- @Provides("66269bdd-9271-4e76-b25c-7ab81eebe1d8") --->
			<cfset dqResponse = dwcOtherDateQC.validationDateidentifiedNotstandard(dateIdentified) >
			<cfset r.label = "dwc:dateIdentified in standard format" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["66269bdd-9271-4e76-b25c-7ab81eebe1d8"] = r >
			<cfset r=structNew()>

			<!--- @Provides("dc8aae4b-134f-4d75-8a71-c4186239178e") --->
			<cfset dqResponse = dwcOtherDateQC.validationDateidentifiedOutofrange(dateIdentified, eventDate)>
			<cfset r.label = "dwc:dateIdentified in range" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["dc8aae4b-134f-4d75-8a71-c4186239178e"] = r >
			<cfset r=structNew()>

			<!---  @Provides("47ff73ba-0028-4f79-9ce1-ee7008d66498") --->
			<cfset dqResponse =  dwcEventDQ.validationDayNotstandard(day) >
			<cfset r.label = "dwc:day in standard format" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["47ff73ba-0028-4f79-9ce1-ee7008d66498"] = r >
			<cfset r=structNew()>

			<!--- @Provides("5618f083-d55a-4ac2-92b5-b9fb227b832f") --->
			<cfset dqResponse = dwcEventDQ.validationDayOutofrange(year, month, day) >
			<cfset r.label = "dwc:day in range for month and year" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["5618f083-d55a-4ac2-92b5-b9fb227b832f"] = r >
			<cfset r=structNew()>

			<!---  @Provides("9a39d88c-7eee-46df-b32a-c109f9f81fb8") --->
			<cfset dqResponse =dwcEventDQ.validationEnddayofyearOutofrange(endDayOfYear, eventDate) >
			<cfset r.label = "dwc:endDayOfYear in range for year" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["9a39d88c-7eee-46df-b32a-c109f9f81fb8"] = r >
			<cfset r=structNew()>

			<!---  @Provides("41267642-60ff-4116-90eb-499fee2cd83f") --->
			<cfset dqResponse = dwcEventDQ.validationEventTemporalEmpty(eventDate,verbatimEventDate,year,month,day,startDayOfYear,endDayOfYear) >
			<cfset r.label = "dwc:Event terms contain some value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["41267642-60ff-4116-90eb-499fee2cd83f"] = r >
			<cfset r=structNew()>

			<!--- @Provides("5618f083-d55a-4ac2-92b5-b9fb227b832f")  --->
			<cfset dqResponse = dwcEventDQ.validationEventInconsistent(eventDate,year,month,day,startDayOfYear,endDayOfYear) >
			<cfset r.label = "dwc:Event terms are consistent" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["5618f083-d55a-4ac2-92b5-b9fb227b832f"] = r >
			<cfset r=structNew()>

			<!--- @Provides("f51e15a6-a67d-4729-9c28-3766299d2985") --->
			<cfset dqResponse = dwcEventDQ.validationEventdateEmpty(eventDate) >
			<cfset r.label = "dwc:eventDate contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["f51e15a6-a67d-4729-9c28-3766299d2985"] = r >
			<cfset r=structNew()>

			<!---  @Provides("4f2bf8fd-fc5c-493f-a44c-e7b16153c803") --->
			<cfset dqResponse = dwcEventDQ.validationEventdateNotstandard(eventDate) >
			<cfset r.label = "dwc:eventDate is in standard form" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["4f2bf8fd-fc5c-493f-a44c-e7b16153c803"] = r >
			<cfset r=structNew()>

			<!--- @Provides("3cff4dc4-72e9-4abe-9bf3-8a30f1618432") --->
			<cfset dqResponse = dwcEventDQ.validationEventdateOutofrange(eventDate) >
			<cfset r.label = "dwc:eventDate is in range" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["3cff4dc4-72e9-4abe-9bf3-8a30f1618432"] = r >
			<cfset r=structNew()>

			<!--- @Provides("01c6dafa-0886-4b7e-9881-2c3018c98bdc") --->
			<cfset dqResponse = dwcEventDQ.validationMonthNotstandard(month) >
			<cfset r.label = "dwc:month is in standard form" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["01c6dafa-0886-4b7e-9881-2c3018c98bdc"] = r >
			<cfset r=structNew()>

			<!--- @Provides("85803c7e-2a5a-42e1-b8d3-299a44cafc46") --->
			<cfset dqResponse = dwcEventDQ.validationStartdayofyearOutofrange(startDayOfYear,eventDate) >
			<cfset r.label = "dwc:startDayOfYear is in range for year" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["85803c7e-2a5a-42e1-b8d3-299a44cafc46"] = r >
			<cfset r=structNew()>

			<!--- @Provides("c09ecbf9-34e3-4f3e-b74a-8796af15e59f") --->
			<cfset dqResponse = dwcEventDQ.validationYearEmpty(year) >
			<cfset r.label = "dwc:startDayOfYear is in range for year" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset preamendment["c09ecbf9-34e3-4f3e-b74a-8796af15e59f"] = r >
			<cfset r=structNew()>

			<!--- amendment phase --->

			<!---  @Provides("39bb2280-1215-447b-9221-fd13bc990641") --->
			<cfset dqResponse= dwcOtherDateQC.amendmentDateidentifiedStandardized(dateIdentified) >
			<cfset r.label = "standardize dwc:dateIdentified" >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "CHANGED">
				<cfset dateIdentified = dqResponse.getValue().getObject().get("dwc:dateIdentified") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["39bb2280-1215-447b-9221-fd13bc990641"] = r >
			<cfset r=structNew()>

			<!--- @Provides("b129fa4d-b25b-43f7-9645-5ed4d44b357b") --->
			<cfset dqResponse = dwcEventDQ.amendmentDayStandardized(day) >
			<cfset r.label = "standardize dwc:day" >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "CHANGED">
				<cfset day = dqResponse.getValue().getObject().get("dwc:day") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["b129fa4d-b25b-43f7-9645-5ed4d44b357b"] = r >
			<cfset r=structNew()>

			<!--- @Provides("2e371d57-1eb3-4fe3-8a61-dff43ced50cf") --->
			<cfset dqResponse = dwcEventDQ.amendmentMonthStandardized(month) >
			<cfset r.label = "standardize dwc:month" >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "CHANGED">
				<cfset month = dqResponse.getValue().getObject().get("dwc:month") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["2e371d57-1eb3-4fe3-8a61-dff43ced50cf"] = r >
			<cfset r=structNew()>

			<!--- @Provides("6d0a0c10-5e4a-4759-b448-88932f399812") --->
			<cfset dqResponse = dwcEventDQ.amendmentEventdateFromVerbatim(eventDate, verbatimEventDate) >
			<cfset r.label = "fill in dwc:eventDate from dwc:verbatimEventDate " >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status EQ "FILLED_IN">
				<cfset eventDate = dqResponse.getValue().getObject().get("dwc:eventDate") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["6d0a0c10-5e4a-4759-b448-88932f399812"] = r >
			<cfset r=structNew()>

			<!---  @Provides("eb0a44fa-241c-4d64-98df-ad4aa837307b") --->
			<cfset dqResponse = dwcEventDQ.amendmentEventdateFromYearstartdayofyearenddayofyear(eventDate, year, startDayOfYear, endDayOfYear) >
			<cfset r.label = "fill in dwc:eventDate from dwc:year, dwc:startDayOfYear and dwc:endDayOfYear" >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "CHANGED">
				<cfset eventDate = dqResponse.getValue().getObject().get("dwc:eventDate") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["eb0a44fa-241c-4d64-98df-ad4aa837307b"] = r >
			<cfset r=structNew()>

			<!--- @Provides("3892f432-ddd0-4a0a-b713-f2e2ecbd879d") --->
			<cfset dqResponse = dwcEventDQ.amendmentEventdateFromYearmonthday(eventDate, year, month, day) >
			<cfset r.label = "fill in dwc:eventDate from dwc:year, dwc:month, and dwc:day " >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status EQ "FILLED_IN">
				<cfset eventDate = dqResponse.getValue().getObject().get("dwc:eventDate") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["3892f432-ddd0-4a0a-b713-f2e2ecbd879d"] = r >
			<cfset r=structNew()>

			<!--- @Provides("718dfc3c-cb52-4fca-b8e2-0e722f375da7") --->
			<cfset dqResponse = dwcEventDQ.amendmentEventdateStandardized(eventDate) >
			<cfset r.label = "standardize dwc:eventDate " >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "CHANGED">
				<cfset eventDate = dqResponse.getValue().getObject().get("dwc:eventDate") >
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["718dfc3c-cb52-4fca-b8e2-0e722f375da7"] = r >
			<cfset r=structNew()>

			<!--- @Provides("710fe118-17e1-440f-b428-88ba3f547d6d") --->
			<cfset dqResponse = dwcEventDQ.amendmentEventFromEventdate(eventDate, year,month,day, startDayOfYear, endDayOfYear) >
			<cfset r.label = "fill in other Event terms from dwc:eventDate" >
			<cfset r.type = "AMENDMENT" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status EQ "FILLED_IN">
				<!--- conditionally change terms for which values are proposed --->
				<cfif dqResponse.getValue().getObject().get("dwc:month") NEQ '' ><cfset month = dqResponse.getValue().getObject().get("dwc:month") ></cfif>
				<cfif dqResponse.getValue().getObject().get("dwc:day") NEQ '' ><cfset day = dqResponse.getValue().getObject().get("dwc:day") ></cfif>
				<cfif dqResponse.getValue().getObject().get("dwc:year") NEQ '' ><cfset year = dqResponse.getValue().getObject().get("dwc:year") ></cfif>
				<cfif dqResponse.getValue().getObject().get("dwc:startDayOfYear") NEQ '' ><cfset startDayOfYear = dqResponse.getValue().getObject().get("dwc:startDayOfYear") ></cfif>
				<cfif dqResponse.getValue().getObject().get("dwc:endDayOfYear") NEQ '' ><cfset endDayOfYear = dqResponse.getValue().getObject().get("dwc:endDayOfYear") ></cfif>
				<cfset r.value = dqResponse.getValue().getObject().toString() >
			<cfelse>
				<cfset r.value = "">
			</cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset amendment["710fe118-17e1-440f-b428-88ba3f547d6d"] = r >
			<cfset r=structNew()>


			<!--- post-amendment phase --->

			<!--- @Provides("56b6c695-adf1-418e-95d2-da04cad7be53") --->
			<cfset dqResponse = dwcEventDQ.measureEventdatePrecisioninseconds(eventDate) >
			<cfset r.label = "dwc:eventDate precision in seconds" >
			<cfset r.type = "MEASURE" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT">
				<cfset r.value = dqResponse.getValue().getObject() >
				<cfset days = Round(r.value / 60 / 60 / 24)>
				<cfif days EQ 1><cfset s=""><cfelse><cfset s="s"></cfif>
				<cfset r.comment = dqResponse.getComment() & " (" & days & " day" & s &")" >
			<cfelse>
				<cfset r.value = "">
				<cfset r.comment = dqResponse.getComment()  >
			</cfif>
			<cfset postamendment["56b6c695-adf1-418e-95d2-da04cad7be53"] = r >
			<cfset r=structNew()>

			<!--- @Provides("66269bdd-9271-4e76-b25c-7ab81eebe1d8") --->
			<cfset dqResponse = dwcOtherDateQC.validationDateidentifiedNotstandard(dateIdentified) >
			<cfset r.label = "dwc:dateIdentified in standard format" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["66269bdd-9271-4e76-b25c-7ab81eebe1d8"] = r >
			<cfset r=structNew()>

			<!--- @Provides("dc8aae4b-134f-4d75-8a71-c4186239178e") --->
			<cfset dqResponse = dwcOtherDateQC.validationDateidentifiedOutofrange(dateIdentified, eventDate)>
			<cfset r.label = "dwc:dateIdentified in range" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["dc8aae4b-134f-4d75-8a71-c4186239178e"] = r >
			<cfset r=structNew()>

			<!---  @Provides("47ff73ba-0028-4f79-9ce1-ee7008d66498") --->
			<cfset dqResponse =  dwcEventDQ.validationDayNotstandard(day) >
			<cfset r.label = "dwc:day in standard format" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["47ff73ba-0028-4f79-9ce1-ee7008d66498"] = r >
			<cfset r=structNew()>

			<!--- @Provides("5618f083-d55a-4ac2-92b5-b9fb227b832f") --->
			<cfset dqResponse = dwcEventDQ.validationDayOutofrange(year, month, day) >
			<cfset r.label = "dwc:day in range for month and year" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["5618f083-d55a-4ac2-92b5-b9fb227b832f"] = r >
			<cfset r=structNew()>

			<!---  @Provides("9a39d88c-7eee-46df-b32a-c109f9f81fb8") --->
			<cfset dqResponse =dwcEventDQ.validationEnddayofyearOutofrange(endDayOfYear, eventDate) >
			<cfset r.label = "dwc:endDayOfYear in range for year" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["9a39d88c-7eee-46df-b32a-c109f9f81fb8"] = r >
			<cfset r=structNew()>

			<!---  @Provides("41267642-60ff-4116-90eb-499fee2cd83f") --->
			<cfset dqResponse = dwcEventDQ.validationEventTemporalEmpty(eventDate,verbatimEventDate,year,month,day,startDayOfYear, endDayOfYear) >
			<cfset r.label = "dwc:Event terms contain some value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["41267642-60ff-4116-90eb-499fee2cd83f"] = r >
			<cfset r=structNew()>

			<!--- @Provides("5618f083-d55a-4ac2-92b5-b9fb227b832f")  --->
			<cfset dqResponse = dwcEventDQ.validationEventInconsistent(eventDate,year,month,day,startDayOfYear, endDayOfYear) >
			<cfset r.label = "dwc:Event terms are consistent" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["5618f083-d55a-4ac2-92b5-b9fb227b832f"] = r >
			<cfset r=structNew()>

			<!--- @Provides("f51e15a6-a67d-4729-9c28-3766299d2985") --->
			<cfset dqResponse = dwcEventDQ.validationEventdateEmpty(eventDate) >
			<cfset r.label = "dwc:eventDate contains a value" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["f51e15a6-a67d-4729-9c28-3766299d2985"] = r >
			<cfset r=structNew()>

			<!---  @Provides("4f2bf8fd-fc5c-493f-a44c-e7b16153c803") --->
			<cfset dqResponse = dwcEventDQ.validationEventdateNotstandard(eventDate) >
			<cfset r.label = "dwc:eventDate is in standard form" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["4f2bf8fd-fc5c-493f-a44c-e7b16153c803"] = r >
			<cfset r=structNew()>

			<!--- @Provides("3cff4dc4-72e9-4abe-9bf3-8a30f1618432") --->
			<cfset dqResponse = dwcEventDQ.validationEventdateOutofrange(eventDate) >
			<cfset r.label = "dwc:eventDate is in range" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["3cff4dc4-72e9-4abe-9bf3-8a30f1618432"] = r >
			<cfset r=structNew()>

			<!--- @Provides("01c6dafa-0886-4b7e-9881-2c3018c98bdc") --->
			<cfset dqResponse = dwcEventDQ.validationMonthNotstandard(month) >
			<cfset r.label = "dwc:month is in standard form" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["01c6dafa-0886-4b7e-9881-2c3018c98bdc"] = r >
			<cfset r=structNew()>

			<!--- @Provides("85803c7e-2a5a-42e1-b8d3-299a44cafc46") --->
			<cfset dqResponse = dwcEventDQ.validationStartdayofyearOutofrange(startDayOfYear,eventDate) >
			<cfset r.label = "dwc:startDayOfYear is in range for year" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["85803c7e-2a5a-42e1-b8d3-299a44cafc46"] = r >
			<cfset r=structNew()>

			<!--- @Provides("c09ecbf9-34e3-4f3e-b74a-8796af15e59f") --->
			<cfset dqResponse = dwcEventDQ.validationYearEmpty(year) >
			<cfset r.label = "dwc:startDayOfYear is in range for year" >
			<cfset r.type = "VALIDATION" >
			<cfset r.status = dqResponse.getResultState().getLabel() >
			<cfif r.status eq "RUN_HAS_RESULT"><cfset r.value = dqResponse.getValue().getObject() ><cfelse><cfset r.value = ""></cfif>
			<cfset r.comment = dqResponse.getComment() >
			<cfset postamendment["c09ecbf9-34e3-4f3e-b74a-8796af15e59f"] = r >
			<cfset r=structNew()>

			<!--- Add results from phases to result to return --->

			<cfset result["preamendment"] = preamendment >

			<cfset result["amendment"] = amendment >

			<cfset result["postamendment"] = postamendment >

		<cfelse>
			<cfset result.status="fail">
			<cfset result.target_id=target_id>
			<cfset result.error="record not found">
		</cfif>
    <cfcatch>
			<cfset result.status="fail">
			<cfset result.target_id=target_id>
			<cfset line = cfcatch.tagcontext[1].line>
			<cfset result.error=cfcatch.message & '; ' & cfcatch.detail & ' [line:' & line & ']' >
    </cfcatch>
	</cftry>
    <cfreturn serializeJSON(result) >
</cffunction>

</cfcomponent>
