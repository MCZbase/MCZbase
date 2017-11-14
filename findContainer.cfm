<cfinclude template="/includes/_header.cfm">
<cfset title='Find Containers'>
<script type='text/javascript' src='/includes/dhtmlxtree.js'><!-- --></script>
<script type="text/javascript" src="/includes/dhtmlxcommon.js"></script>
<link rel="STYLESHEET" type="text/css" href="/includes/dhtmlxtree.css">
<script src="/includes/jquery/jquery-autocomplete/jquery.autocomplete.pack.js" language="javascript" type="text/javascript"></script>

<cfoutput>
<script>
	jQuery(document).ready(function() {
		jQuery("##part_name").autocomplete("/ajax/part_name.cfm", {
			width: 320,
			max: 20,
			autofill: true,
			highlight: false,
			multiple: false,
			scroll: true,
			scrollHeight: 300
		});
	});
</script>
<style >
	.cTreePane {
		height:400px;
overflow-y:scroll;
overflow-x:auto;
padding: 1em 1em 0 1em;
	}
	.ajaxWorking{
		top: 15%;
		color: green;
		text-align: center;
		margin: auto;
		position:absolute;
		max-width: 50%;
		right:55%;
		background-color:white;
		padding:1em;
		border:1px solid;
		overflow:hidden;
		z-index:1;
		/*overflow-y:scroll;*/
		}
	.ajaxDone {display:none}
	.ajaxMessage {color:green;}
	.ajaxError {color:red;}
</style>

<script type='text/javascript' src='/includes/_treeAjax.js'></script>

<cfquery name="contType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select container_type from ctContainer_Type order by container_type
</cfquery>
<cfquery name="collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select collection_id, institution_acronym || ' ' || collection_cde coll from collection
</cfquery>
<cfquery name="ctcoll_other_id_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select OTHER_ID_TYPE from
	ctcoll_other_id_type
	group by OTHER_ID_TYPE
	order by OTHER_ID_TYPE
</cfquery>
<div id="ajaxMsg"></div>
<table border width="100%">
	<tr>
		 <td valign="top" style="padding: 1em;"><!--------------------------- search pane ----------------------------->

        <h4>Find Container:</h4>
        <div id="searchPane">
          <div style="border: 1px solid green; padding:.5em; width: 24em;">
          <form onSubmit="loadTree();return false;">
            <table>
              <tr>
                <cfif not isdefined("container_label")><cfset container_label=""></cfif>
                <td style="padding-right: 1em;"><label for="container_label">Name (% for wildcard)</label>
                  <input type="text" name="container_label" id="container_label" value="#container_label#" size="16" /></td>
                <td><input type="hidden" name="transaction_id" id="transaction_id">
                  <label for="barcode">Unique Identifier (comma-list OK)</label>
                  <input type="text" name="barcode" id="barcode" size="17" /></td>
              </tr>
              <tr>
                <cfif not isdefined("parent_label")><cfset parent_label=""></cfif>
                <td style="padding-right: 1em;"><label for="parent_label">Parent Name</label>
                  <input type="text" name="parent_label" id="parent_label" value="#parent_label#" size="16" /></td>
                <td>
                  <label for="barcode">Parent Unique Identifier</label>
                  <input type="text" name="parent_barcode" id="_parent_barcode" size="17" />
                </td>
              </tr>
              <tr>
                <td><label for="container_type">Container Type</label>
                  <select name="container_type" id="container_type" size="1" style="width: 170px;">
                    <option value=""></option>
                    <cfloop query="contType">
                      <option value="#contType.container_type#">#contType.container_type#</option>
                    </cfloop>
                  </select></td>
                <td><label for="description">Description (% for wildcard)</label>
                  <input type="text" name="description" id="description" size="17"  /></td>
              </tr>
              <tr>
                <td><label for="in_container_type">Contained By Container Type</label>
                  <select name="in_container_type" id="in_container_type" size="1" style="width: 170px;">
                    <option value=""></option>
                    <cfloop query="contType">
                      <option value="#contType.container_type#">#contType.container_type#</option>
                    </cfloop>
                  </select></td>
                <td style="vertical-align:bottom"><input type="submit" value="Search" class="schBtn" style="width: 114px;padding-left: 33px;">
                  &nbsp;
                  <input class="clrBtn" type="reset" value="Clear"/></td>
              </tr>
            </table>
            </div>
            <h5 style="margin-top: 2.5em;">Find container by the collection object it contains:</h5>
            <div style="border: 1px solid green; padding: .5em;width: 24em;">
              <table>
                <tr>
                  <td style="padding-right: 1em;"><label for="collection_id">Collection</label>
                    <select name="collection_id" id="collection_id" size="1" style="width: 170px;">
                      <option value=""></option>
                      <cfloop query="collections">
                        <option value="#collection_id#">#coll#</option>
                      </cfloop>
                    </select></td>
                  <td><label for="cat_num">Cat Num (comma-list OK)</label>
                    <input type="text" name="cat_num" id="cat_num"  size="17" /></td>
                </tr>
                <tr>
                  <td><label for="other_id_type">Other ID Type</label>
                    <select name="other_id_type" id="other_id_type" size="1" style="width:170px;">
                      <option value=""></option>
                      <cfloop query="ctcoll_other_id_type">
                        <option value="#ctcoll_other_id_type.other_id_type#">#ctcoll_other_id_type.other_id_type#</option>
                      </cfloop>
                    </select></td>
                  <td><label for="other_id_value">Other ID Value (% for wildcard)</label>
                    <input type="text" name="other_id_value" id="other_id_value" size="17" />
                    <input type="hidden" name="collection_object_id" id="collection_object_id" /></td>
                </tr>
                <tr>
                  <td><label for="part_name">Part</label>
                    <input type="text" id="part_name" name="part_name" size="16">
                    <input type="hidden" name="loan_trans_id" id="loan_trans_id" />
                    <input type="hidden" name="table_name" id="table_name" /></td>
                  <td style="vertical-align:bottom"><input type="submit" value="Search" class="schBtn" style="width: 114px;padding-left: 33px;">
                    &nbsp;
                    <input class="clrBtn" type="reset" value="Clear"/></td>
                </tr>
              </table>
            </div>
            <br>
          </form>
          <div style="display: none;"> <span class="likeLink" onclick="downloadTree()">Flatten Part Locations</span> <br>
            <span class="likeLink" onclick="showTreeOnly()">Drag/Print</span> <br>
            <span class="likeLink" onclick="printLabels()">Print Labels</span> </div>
        </div></td>
      <!--------------------------------- end search pane ------------------------------------->
		<td valign="top"><!------------------------------------- tree pane --------------------------------------------->
			<div id="treePane" class="cTreePane"></div>
		</td><!------------------------------------- end tree pane --------------------------------------------->

		<td valign="top">
			<div id="detailPane"></div>
		</td>
	</tr>
</table>

<div id="thisfooter">
	<cfinclude template="/includes/_footer.cfm">
</div>

<cfif isdefined("url.collection_object_id") and len(url.collection_object_id) gt 0 and not isdefined("url.showControl")>
	<script language="javascript" type="text/javascript">
		try {
			parent.dyniframesize();
		} catch(err) {
			// not where we think we are, maybe....
		}
		showSpecTreeOnly('#url.collection_object_id#');
	</script>
<cfelse>
	<cfset autoSubmit=false>
	<cfloop list="#StructKeyList(url)#" index="key">
		<cfif len(#url[key]#) gt 0>
			<cfset autoSubmit=true>
			<script language="javascript" type="text/javascript">
				if (document.getElementById('#lcase(key)#')) {
					document.getElementById('#lcase(key)#').value='#url[key]#';
				}
			</script>
		</cfif>
	</cfloop>
	<cfif autoSubmit is true>
	<script language="javascript" type="text/javascript">
		loadTree();
	</script>
	</cfif>
</cfif>
</cfoutput>
