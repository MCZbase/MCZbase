<cfinclude template="/includes/_header.cfm">
      <div style="width: 56em;margin: 0 auto; padding: 1em 0 3em 0;">
<cfset title="Bulkload Citations">
<!---- make the table

drop table cf_temp_oids;
drop public synonym cf_temp_oids;

create table cf_temp_oids (
	key number,
	collection_object_id number,
	collection_cde varchar2(4),
	institution_acronym varchar2(6),
	existing_other_id_type varchar2(60),
	existing_other_id_number varchar2(60),
	new_other_id_type varchar2(60),
	new_other_id_number varchar2(60)
	);

	create public synonym cf_temp_oids for cf_temp_oids;
	grant select,insert,update,delete on cf_temp_oids to uam_query,uam_update;

	 CREATE OR REPLACE TRIGGER cf_temp_oids_key
 before insert  ON cf_temp_oids
 for each row
    begin
    	if :NEW.key is null then
    		select somerandomsequence.nextval into :new.key from dual;
    	end if;
    end;
show error------>
<cfif #action# is "nothing">
    <h3 class="wikilink">Bulkload Citations</h3>
<p>Upload a comma-delimited text file (csv).
    Include column headings, spelled exactly as below.</p>
    <p style="margin: 1em 0;"><span class="likeLink" onclick="document.getElementById('template').style.display='block';">view template</span></p>
	<div id="template" style="display:none; margin: 1em 0;">
		<label for="t">Copy the following code and save as a .csv file</label>
		<textarea rows="2" cols="80" id="t">INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PUBLICATION_TITLE,CITED_SCIENTIFIC_NAME,OCCURS_PAGE_NUMBER,CITATION_PAGE_URI,TYPE_STATUS,CITATION_REMARKS</textarea>
	</div>

<ul class="geol_hier">
	<li style="color:red">INSTITUTION_ACRONYM</li>
	<li style="color:red">COLLECTION_CDE</li>
	<li style="color:red">OTHER_ID_TYPE ("catalog number" is OK)</li>
	<li style="color:red">OTHER_ID_NUMBER</li>
	<li>PUBLICATION_TITLE (You must include either a Publication Title OR a Publication ID)</li>
	<li>PUBLICATION_ID</li>
	<li style="color:red">CITED_SCIENTIFIC_NAME</li>
	<li>OCCURS_PAGE_NUMBER</li>
	<li>CITATION_PAGE_URI</li>
	<li style="color:red">TYPE_STATUS</li>
	<li style="color:red">CITATION_REMARKS</li>
</ul>
<cfform name="oids" method="post" enctype="multipart/form-data">
			<input type="hidden" name="Action" value="getFile">
			  <input type="file"
		   name="FiletoUpload"
		   size="45">
			  <input type="submit" value="Upload this file" #saveClr#>
			  	  <br><br>
	Character Set: <select name="cSet" id="cSet">
		<option value="windows-1252" selected>windows-1252</option>
		<option value="MacRoman">MacRoman</option>
		<option value="utf-8">utf-8</option>
		<option value="utf-16">utf-16</option>
		<option value="unicode">unicode</option>
	</input>
  </cfform>

</cfif>

<!------------------------------------------------------->
<!------------------------------------------------------->

<!------------------------------------------------------->
<cfif #action# is "getFile">
<cfoutput>
	<!--- put this in a temp table --->
	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		delete from cf_temp_citation
	</cfquery>

	<cffile action="READ" file="#FiletoUpload#" variable="fileContent" charset="#cSet#">

	<cfset fileContent=replace(fileContent,"'","''","all")>
	<cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />
	<cfset colNames="">
	<cfloop from="1" to ="#ArrayLen(arrResult)#" index="o">
		<cfset colVals="">
			<cfloop from="1"  to ="#ArrayLen(arrResult[o])#" index="i">
				<cfset thisBit=arrResult[o][i]>
				<cfif #o# is 1>
					<cfset colNames="#colNames#,#thisBit#">
				<cfelse>
					<cfset colVals="#colVals#,'#thisBit#'">
				</cfif>
			</cfloop>
		<cfif #o# is 1>
			<cfset colNames=replace(colNames,",","","first")>
		</cfif>
		<cfif len(#colVals#) gt 1>
			<cfset colVals=replace(colVals,",","","first")>
			<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into cf_temp_citation (#colNames#) values (#preservesinglequotes(colVals)#)
			</cfquery>
		</cfif>
	</cfloop>
	<cflocation url="BulkloadCitations.cfm?action=validate" addtoken="false">
</cfoutput>
</cfif>
<!------------------------------------------------------->
<cfif #action# is "validate">
<cfoutput>
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_citation set status='missing data'
		where
		other_id_type is null or
		other_id_number is null or
		collection_cde is null or
		institution_acronym is null or
		(PUBLICATION_TITLE is null and PUBLICATION_ID is null) or
		CITED_SCIENTIFIC_NAME is null or
		<!---OCCURS_PAGE_NUMBER is null or--->
		TYPE_STATUS is null
	</cfquery>
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_citation where status is null
	</cfquery>
	<cfloop query="data">
		<cfset problem="">
		<cfif #other_id_type# is not "catalog number">
			<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						coll_obj_other_id_num.collection_object_id
					FROM
						coll_obj_other_id_num,
						cataloged_item,
						collection
					WHERE
						coll_obj_other_id_num.collection_object_id = cataloged_item.collection_object_id and
						cataloged_item.collection_id = collection.collection_id and
						collection.collection_cde = '#collection_cde#' and
						collection.institution_acronym = '#institution_acronym#' and
						other_id_type = '#trim(other_id_type)#' and
						display_value = '#trim(other_id_number)#'
				</cfquery>
			<cfelse>
				<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						collection_object_id
					FROM
						cataloged_item,
						collection
					WHERE
						cataloged_item.collection_id = collection.collection_id and
						collection.collection_cde = '#collection_cde#' and
						collection.institution_acronym = '#institution_acronym#' and
						cat_num='#other_id_number#'
				</cfquery>
			</cfif>
			<cfif #collObj.recordcount# is not 1>
				<cfif len(#problem#) is 0>
					<cfset problem = "#data.other_id_number# #data.other_id_type# #data.collection_cde# #data.institution_acronym# could not be found">
				<cfelse>
					<cfset problem = "#problem#; #data.other_id_number# #data.other_id_type# #data.collection_cde# #data.institution_acronym# could not be found">
				</cfif>
			<cfelse>
				<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_citation SET collection_object_id = #collObj.collection_object_id# where
					key = #key#
				</cfquery>
			</cfif>
			<cfset noHTMLpubstr = REreplace(#publication_title#,"(<[/]{0,1}[i|b|sup|sub]>)", "", "ALL")>
				<cfif len(publication_id) is 0>
				<cfquery name="isPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select publication_id from publication where regexp_replace(publication_title, '(<[/]{0,1}[i|b|sup|sub]>)', '') = '#noHTMLpubstr#'
					group by publication_id
				</cfquery>
				<cfelse>
				<cfquery name="isPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select publication_id from publication where publication_id = #data.publication_id#
					group by publication_id
				</cfquery>
			</cfif>
			<cfif #isPub.recordcount# is not 1>
				<cfif len(#problem#) is 0>
					<cfset problem = "publication not found; check markup">
				<cfelse>
					<cfset problem = "#problem#; publication not found; check markup">
				</cfif>
			<cfelse>
				<cfif len(publication_id) is 0>
				<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_citation SET publication_id = #isPub.publication_id# where
					key = #key#
				</cfquery>
				</cfif>
			</cfif>
			<cfquery name="isTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select taxon_name_id from taxonomy where scientific_name = '#cited_scientific_name#'
				group by taxon_name_id
			</cfquery>
			<cfif #isTaxa.recordcount# is not 1>
				<cfif len(#problem#) is 0>
					<cfset problem = "taxonomy not found">
				<cfelse>
					<cfset problem = "#problem#; taxonomy not found">
				</cfif>
			<cfelse>
				<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_citation SET CITED_TAXON_NAME_ID = #isTaxa.taxon_name_id# where
					key = #key#
				</cfquery>
			</cfif>
			<cfif len(#problem#) gt 0>
				<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_citation SET status = '#problem#' where
					key = #key#
				</cfquery>
			</cfif>
		</cfloop>
		<cfquery name="valData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_citation set status='duplicate' where key in (
				select distinct k from cf_temp_citation a,
				 (select min(key) k, collection_object_id,publication_id
				from cf_temp_citation having count(*) >  1 group by
				collection_object_id,publication_id) b
				where a.collection_object_id = b.collection_object_id and
				a.publication_id = b.publication_id
			)
		</cfquery>
		<cfquery name="valData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select * from cf_temp_citation order by status,
			other_id_type,
			other_id_number,
			publication_title
		</cfquery>
		<cfquery name="isProb" dbtype="query">
			select count(*) c from valData where status is not null
		</cfquery>
		 #isProb.c#
		<cfif #isProb.c# is 0 or len(isprob.c) is 0>
			Data validated. Double-check below. If everything looks OK, <a href="BulkloadCitations.cfm?action=loadData">proceed to load</a>
		<cfelse>
			The data you loaded do not validate. See STATUS column below.
		</cfif>
		<cfdump var=#valData#>
		<!---
	<cflocation url="BulkloadCitations.cfm?action=loadData">
	---->
</cfoutput>
</cfif>
<!------------------------------------------------------->
<cfif #action# is "loadData">

<cfoutput>
<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_citation
	</cfquery>

	<cftransaction>
	<cfloop query="getTempData">
		<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into citation (
				PUBLICATION_ID,
				COLLECTION_OBJECT_ID,
				CITED_TAXON_NAME_ID,
				CIT_CURRENT_FG
				<cfif len(#OCCURS_PAGE_NUMBER#) gt 0>
					,OCCURS_PAGE_NUMBER
				</cfif>
				<cfif len(#CITATION_PAGE_URI#) gt 0>
					,CITATION_PAGE_URI
				</cfif>
				<cfif len(#TYPE_STATUS#) gt 0>
					,TYPE_STATUS
				</cfif>
				<cfif len(#CITATION_REMARKS#) gt 0>
					,CITATION_REMARKS
				</cfif>
			) values (
				#PUBLICATION_ID#,
				#COLLECTION_OBJECT_ID#,
				#CITED_TAXON_NAME_ID#,
				1
				<cfif len(#OCCURS_PAGE_NUMBER#) gt 0>
					,#OCCURS_PAGE_NUMBER#
				</cfif>
				<cfif len(#CITATION_PAGE_URI#) gt 0>
					,'#CITATION_PAGE_URI#'
				</cfif>
				<cfif len(#TYPE_STATUS#) gt 0>
					,'#TYPE_STATUS#'
				</cfif>
				<cfif len(#CITATION_REMARKS#) gt 0>
					,'#CITATION_REMARKS#'
				</cfif>
			)
		</cfquery>
		<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_citation set status='loaded' where key=#key#
		</cfquery>
	</cfloop>
	</cftransaction>
<cflocation url="BulkloadCitations.cfm?action=allDone">
</cfoutput>
</cfif>
<!-------------------------------------------------------------------------->
<cfif #action# is "allDone">
	<cfoutput>
		<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select publication_id,publication_title,status from cf_temp_citation group by publication_id,publication_title,status
		</cfquery>
		<cfif #getTempData.recordcount# is 0>
			something very strange happened. Contact a sysadmin.
		</cfif>
		<cfloop query="getTempData">
			<cfif #status# is not "loaded">
				Something bad happened with #publication_title#. Contact your friendly local sysadmin.
			<cfelse>
				Everything seems to have worked! View citations for <a href="/Citation.cfm?publication_id=#publication_id#">
					<cfif len(#publication_title#) gt 0>
						#publication_title#
					<cfelse>
						Publication ID #publication_id#
					</cfif>
					<br>
					</a>
			</cfif>
		</cfloop>
	</cfoutput>
</cfif>

</div><!---end inside inline box--->

<cfinclude template="/includes/_footer.cfm">
