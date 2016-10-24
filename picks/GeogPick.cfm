<cfinclude template="/includes/_pickHeader.cfm">
<cfset title = "Pick Higher Geog">
<cfoutput>
    <div style="width: 800px; margin: 3em auto 1em auto;">
<h3 class="wikilink">Find Geography:</h3>
  <table>
    <form name="getHG" method="post" action="GeogPick.cfm">
      <input type="hidden" name="Action" value="findGeog">
      <input type="hidden" name="geogIdFld" value="#geogIdFld#">
      <input type="hidden" name="highGeogFld" value="#highGeogFld#">
      <input type="hidden" name="formName" value="#formName#">
      <cfinclude template="/includes/frmFindLocation_guts.cfm">
    </form>
           </div>
</cfoutput>
<!-------------------------------------------------------------------->
<cfif #Action# is "findGeog">
<cf_findLocality>
<cfquery name="localityResults" dbtype="query">
	select distinct geog_auth_rec_id,higher_geog
	from localityResults
	order by higher_geog
</cfquery>
<cfoutput query="localityResults">
<div style="width: 800px; margin-left: 2em;"><a href="##" onClick="javascript: opener.document.#formName#.#geogIdFld#.value='#geog_auth_rec_id#';opener.document.#formName#.#highGeogFld#.value='#replace(higher_geog,"'","\'","all")#';self.close();">#higher_geog#</a>
    </div>
 
</cfoutput>
</cfif>
<cfinclude template="/includes/_pickFooter.cfm">