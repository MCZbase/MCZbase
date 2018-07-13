<cfinclude template="/includes/_header.cfm">
<cfset title='Find Containers'>
<script type='text/javascript' src='/includes/dhtmlxtree.js'><!-- --></script>
<script type="text/javascript" src="/includes/dhtmlxcommon.js"></script>
<link rel="STYLESHEET" type="text/css" href="/includes/SearchContainer.css">
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
							<label>Container Type</label>
									<select name="container_type" id="container_type" size="1">
											<option value=""></option>
											<option value="campus">campus</option>
											<option value="building">building</option>
											<option value="floor">floor</option>
											<option value="room">room</option>
											<option value="grouping">grouping</option>
											<option value="fixture">fixture</option>
											<option value="compartment">compartment</option>
											<option value="collection object">collection object</option>
												<option value="cryovat">-----------</option>
											<option value="cryovat">cryovat</option>
											<option value="cryovial">cryovial</option>
											<option value="envelope">envelope</option>
											<option value="freezer">freezer</option>
											<option value="freezer box">freezer box</option>
											<option value="freezer rack">freezer rack</option>
											<option value="pin">pin</option>
											<option value="position">position</option>
											<option value="rack slot">rack slot</option>
											<option value="set">set</option>
											<option value="tank">tank</option>
									</select>
						</li>
					<li>
					   <cfif not isdefined("container_label")><cfset container_label=""></cfif>
								<label>Name (% for wildcard)</label>
                <input type="text" name="container_label" id="container_label" size="20" /></li>
			    <li>
								<input type="hidden" name="transaction_id" id="transaction_id">
								<label>Unique Identifier (exact match)</label>
                <input type="text" name="barcode" id="barcode" size="20" /></li>
		  		<li>
					  <input type="submit" value="Search" class="schBtn" style="">
								<input class="clrBtn" type="reset" value="Clear" style=""/>

          </li>
		</ul>
				<div style="display: none;"> <span class="likeLink" onclick="downloadTree()">Flatten Part Locations</span>
            <span class="likeLink" onclick="showTreeOnly()">Drag/Print</span> <br>
            <span class="likeLink" onclick="printLabels()">Print Labels</span> </div>
        </div>
	</div>
	<a class="seeTipsLink" onclick="seetips()">Search Tips and Examples</a>
	<div class="tipPane" id="hiddentips" style="display:none;">
	<div class="lefttips">
	<ul>
		<h5>Search Tips</h5>
		<li>Use % for unknown letters/characters (a.k.a. wildcard).</li>
		<li>Double click on a container name in the search results (under heading "Container Hierarchy") to see the containers within it.</li>
		<li>Unique Identifier value must match exactly (wildcards are not allowed).</li>
		<li>If search is not narrow enough (i.e., returns more than 1000 links), it will timeout.</li>
		<li>Start with the container name known (e.g., room container name: MCZ-G048) and double click into the hierarchy until the container is found.</li>
	</ul>
	<p>This page is important for two types of searches:</p>
	<ol>
	<li>A check to see if the container was entered, especially if no specimens have been attached yet (to prevent duplicate entries).
	</li>
	<li>A search for a specific container without knowing what is in that container.</li>
	</ol>
	</div>
	<div class="rightexamples">
		<h5>Search examples:</h5>
	<ul>
	<li>Container Type + part of Name (e.g., fixture + Mamm_cabinet% returns all the fixtures that start with "Mamm_cabinet" in the name and shows where they are).</li>
	<li>Enter Unique Identifier to see if a barcode has been entered.</li>
	<li>Enter a freezer name to see where it is and what temperature is listed (e.g., Name = "IZ-Fr-7").
	Double-click on IZ-Fr-7 and see all the specimens inside it.
	From container details (click check box and go to right side of page "See all collection objects..."), you can get a separate page of everything that is in that container, which is easier to print.
	</ul>
	<p>Find containers of <b>cataloged items</b> by searching the <b>specimen search page
	 &rarr; manage results &rarr; part report (locations)</b>. </p>
</div>
</div>
<script>
function seetips() {
    var x = document.getElementById("hiddentips");

    if (x.style.display === "none") {
        x.style.display = "block";
    } else {
        x.style.display = "none";
    }
}
</script>
	<div class="fullPane">
					<div id="treePane" class="cTreePane"></div>
					<div id="detailPane"></div>
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
<cfelseif isdefined("url.loan_trans_id") and len(url.loan_trans_id) gt 0 and not isdefined("url.showControl")>

		<script language="javascript" type="text/javascript">

			try {
				parent.dyniframesize();
			} catch(err) {
				// not where we think we are, maybe....
			}
			showSpecTreeOnlyforLoan('#url.loan_trans_id#');
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
