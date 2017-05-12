<cfinclude template="/includes/_header.cfm">
<style>
.purpleBox {
	background-color: #8393ca;
	padding: 5px;
	z-index: 1;
	float: left;
	display: inline;
}
.greenBox:nth-child(odd) {
	background-color: #deecde;
	float: left;
	display: inline;
	z-index: 2;
	margin: 3px 2px;
	border: 1px solid black;
}
.greenBox:nth-child(even) {
	background-color: #c2ccc3;
	float: left;
	display: inline;
	z-index: 2;
	margin: 3px 2px;
	border: 1px solid black;
}
.whiteBox {
	background-color: #ffffff;
	float: left;
	display: inline;
	z-index: 3;
	width: 100%;
}
ul.locLabel {
	margin: 5px;
	float: left;
	padding: 0 5px;
}
ul.locLabel li {
	list-style: none;
	float: left;
	display: inline;
	width: 130px;
}
ul.locLabel li.wide {
	width: 480px;
}
ul.locLabel li.notSoWide {
	width: 400px;
}
ul.fontLoc {
	font-weight: bold;
	font-size: 14px;
}
li.fontLocHG{
	font-weight: 100;
	font-size: 14px;
}
.collsLoc li {
	float: left;
	display: inline;
	z-index: 3;
	list-style: none;
	padding: 5px;
	margin: 0px;
}
.collsLoc li a {
	font-weight: bold;
}
.fontColls {
	font-size: 13px;
	padding-left: 5px;
}
</style>
<cfif not isdefined("filterTimeFrame")>
  <cfset filterTimeFrame=7>
</cfif>
<cfif not isdefined("sortOrder")>
  <cfset sortOrder="ASC">
</cfif>

<div style="width: 100%;overflow: hidden;height: auto;padding-bottom: 5em;">
  <div style="width: 75em;margin:0 auto;padding: 1em 0 5em 0;"> <cfoutput>
      <cfset title="Recently Georeferenced Localities">
      <h2>Recently Georeferenced Localities (past #filterTimeFrame# days)</h2>
      <cfquery name="newgeorefs" datasource="uam_god">
		select l.locality_id, l.spec_locality, g.higher_geog, f.collection_cde, f.collection_id, to_char(l.GEOREF_UPDATED_DATE, 'YYYY-MM-DD') as GEOREF_UPDATED_DATE, count(*) as cnt
		from locality l, flat f, COLL_OBJECT co, geog_auth_rec g
		where l.locality_id = f.locality_id
		and f.collection_object_id = co.collection_object_id
		and l.geog_auth_rec_id = g.geog_auth_rec_id
		and GEOREF_UPDATED_DATE is not null and GEOREF_UPDATED_DATE > sysdate - #filterTimeFrame#
		and GEOREF_UPDATED_DATE - CO.COLL_OBJECT_ENTERED_DATE > 1
		<cfif isdefined("filterCollections") and len(#filterCollections#) GT 0>
			and l.locality_id in
			(select locality_id from flat where collection_cde = '#filterCollections#')
		</cfif>
		group by l.locality_id, l.spec_locality, g.higher_geog, f.collection_cde,f.collection_id,l.GEOREF_UPDATED_DATE
	</cfquery>
      <cfquery name="localities" dbtype="query">
		select distinct locality_id, spec_locality, higher_geog, GEOREF_UPDATED_DATE from newgeorefs order by GEOREF_UPDATED_DATE #sortOrder#
	</cfquery>
      <cfquery name="colls" datasource="uam_god">
		select * from ctcollection_cde where collection_cde <> 'SC'
	</cfquery>
      <table width = 100%>
          <form name="filterResults" method="post">

        <input type="hidden" name="action" value="nothing" id="action">
          <tr>

          <td width="33%">
        Collection:
          <select name="filterCollections" style="width:100px" onChange='document.getElementById("action").value="nothing";document.forms["filterResults"].submit();'>

        <option></option>
        <cfloop query="colls">
          <option <cfif isdefined("filterCollections") and #collection_cde# EQ #filterCollections#>selected</cfif>>#collection_cde#</option>
        </cfloop>
          </td>

          <td width="33%" align = "center">
          Timeframe (days):

          <select name="filterTimeFrame" style="width:50px" onChange='document.getElementById("action").value="nothing";document.forms["filterResults"].submit();'>

        <option <cfif #filterTimeFrame# EQ 7>selected</cfif>>7</option>
        <option <cfif #filterTimeFrame# EQ 14>selected</cfif>>14</option>
        <option <cfif #filterTimeFrame# EQ 21>selected</cfif>>21</option>
        <option <cfif #filterTimeFrame# EQ 28>selected</cfif>>28</option>
          </td>

          <td width="33%" align="right">
          Sort by Date:

          <select name="sortOrder" style="width:100px" onChange='document.getElementById("action").value="nothing";document.forms["filterResults"].submit();'>

        <option value="ASC"<cfif #sortOrder# EQ "ASC">selected</cfif>>Oldest first</option>
        <option value="DESC"<cfif #sortOrder# EQ "DESC">selected</cfif>>Newest first</option>
          </td>

          </tr>

      </table>
      </form>
      <div class="purpleBox">
      <cfif localities.RecordCount EQ 0>
        <br>
        <br>
        <h3>No Records Found</h3>
        <cfelse>
        <cfloop query="localities">
          <div class="greenBox">
            <ul class="locLabel fontColls">
              <li>Locality ID: </li>
              <li>Georef. Date</li>
              <li class="wide">Specific Locality</li>
              <li class="notSoWide">Higher Geography</li>
            </ul>
            <div class="whiteBox">
              <ul class="locLabel fontLoc">
                <li> <a href="../editLocality.cfm?locality_id=#locality_id#" target="_blank">#locality_id#</a> </li>
                <li>#GEOREF_UPDATED_DATE#</li>
                <li class="wide"><cfif len(spec_locality) is 0>&nbsp;<cfelse>#spec_locality#</cfif></li>
                <li class="notSoWide fontLocHG">#higher_geog#</li>
              </ul>
            </div>
            <cfquery name="colls" dbtype="query">
				select * from newgeorefs where locality_id = #localities.locality_id#
			</cfquery>
            <ul class="collsLoc fontColls">
              <li>Specimens in Collection(s):&nbsp;</li>
              <cfloop query="colls">
                <li>#collection_cde#: <a href="../SpecimenResults.cfm?locality_id=#locality_id#&collection_id=#collection_id#" target="_blank">#cnt# &nbsp;</a></li>
              </cfloop>
            </ul>
          </div>
        </cfloop>
        </div>
      </cfif>
    </cfoutput> </div>
</div>
<cfinclude template="/includes/_footer.cfm">
