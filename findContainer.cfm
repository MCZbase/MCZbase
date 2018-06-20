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

        <!--------------------------- search pane ----------------------------->
<div id="searchContainer">
        <h3 style="margin: 1em 2em;">Find Container:</h3>
        <div id="searchPane">
          <form onSubmit="loadTree();return false;">
    <ul class="findContainer">
						<li>
								<label for="collection_id">Collection</label>
                    <select name="collection_id" id="collection_id" size="1">
                      <option value=""></option>
                      <cfloop query="collections">
                        <option value="1">Herpetology</option>
                        <option value="2">Mammology</option>
                        <option value="3">Malacology</option>
                        <option value="4">Ichthyology</option>
                        <option value="5">Ornithology</option>
                        <option value="6">Vertebrate Paleontology</option>
                        <option value="7">Invertebrate Paleontology</option>
                        <option value="8">Invertebrate Zoology</option>
                        <option value="9">Entomology</option>
                        <option value="10">Special Collections</option>
                        <option value="11">Cryogenic</option>
                        <option value="12">Herpetology Observations</option>
                      </cfloop>
                    </select>
								</li>
			<li>
						<label for="cat_num">Cat Num</label>
            <input type="text" name="cat_num" id="cat_num"  size="17" />
			</li>
					<li>
							<label>Container Type</label>
									<select name="container_type" id="container_type" size="1">
											<option value=""></option>
											<option value="-20 chest freezer">-20 chest freezer</option>
											<option value="-20 freezer">-20 freezer</option>
											<option value="-80 freezer">-80 freezer</option>
											<option value="building">building</option>
											<option value="cabinet">cabinet</option>
											<option value="campus">campus</option>
											<option value="case">case</option>
											<option value="collection object">collection object</option>
											<option value="compartment">compartment</option>
											<option value="cryovat">cryovat</option>
											<option value="cryovial">cryovial</option>
											<option value="envelope">envelope</option>
											<option value="fixture">fixture</option>
											<option value="floor">floor</option>
											<option value="freezer box">freezer box</option>
											<option value="freezer rack">freezer rack</option>
											<option value="grouping">grouping</option>
											<option value="pin">pin</option>
											<option value="position">position</option>
											<option value="rack slot">rack slot</option>
											<option value="room">room</option>
											<option value="set">set</option>
											<option value="tank">tank</option>
											<option value="tank rack">tank rack</option>
											<option value="tier">tier</option>
											<option value="tray">tray</option>
									</select>
						</li>
					<li>
					   <cfif not isdefined("container_label")><cfset container_label=""></cfif>
								<label>Name (% for wildcard)</label>
                <input type="text" name="container_label" id="container_label" size="20" /></li>
			    <li>
								<input type="hidden" name="transaction_id" id="transaction_id">
								<label>Unique Identifier</label>
                <input type="text" name="barcode" id="barcode" size="20" /></li>
		  		<li>
					  <input type="submit" value="Search" class="schBtn" style="">
								<input class="clrBtn" type="reset" value="Clear" style=""/>

          </li>
                              <input type="hidden" name="transaction_id" id="transaction_id"></li>
		</ul>
				<div style="display: none;"> <span class="likeLink" onclick="downloadTree()">Flatten Part Locations</span> <br>
            <span class="likeLink" onclick="showTreeOnly()">Drag/Print</span> <br>
            <span class="likeLink" onclick="printLabels()">Print Labels</span> </div>
        </div>
	</div>
	<div class="fullPane">
			<div valign="top" style="width: 50%;float: left;">
					<div id="treePane" class="cTreePane"></div>
			</div>
			<div valign="top" style="width: 50%; float: right;">
					<div id="detailPane"></div>

			</div>
	</div>
</div>
</div>
<div id="thisfooter">
	<cfinclude template="/includes/_footer.cfm">
</div>

<cfif isdefined("url.collection_object_id") and len(url.collection_object_id) gt 0 and isdefined("url.showControl")>
	<script language="javascript" type="text/javascript">
		try {
			parent.dyniframesize();
		} catch(err) {
			// not where we think we are, maybe....
		}
		showSpecTreeOnly('#url.collection_object_id#');
	</script>
<cfelseif isdefined("url.collection_object_id") and len(url.collection_object_id) gt 0 and not isdefined("url.showControl")>
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
