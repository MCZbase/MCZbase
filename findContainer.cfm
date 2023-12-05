<cfset jquery11=true>
<cfinclude template="/includes/_header.cfm">
<cfset title='Find Containers'>
<script type='text/javascript' src='/includes/dhtmlxtree.js'><!-- --></script>
<script type="text/javascript" src="/includes/dhtmlxcommon.js"></script>
<script src="/includes/jquery/jquery-autocomplete/jquery.autocomplete.pack.js" language="javascript" type="text/javascript"></script>
<link rel="STYLESHEET" type="text/css" href="/includes/css/bootstrap.css">
<link rel="STYLESHEET" type="text/css" href="/includes/findContainer.css">

<script type='text/javascript' src='/includes/_treeAjax.js'></script>

<cfquery name="contType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT container_type 
	FROM ctContainer_Type 
	ORDER BY container_type
</cfquery>
<cfquery name="collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT collection_id, institution_acronym || ' ' || collection_cde coll 
	FROM collection
</cfquery>
<cfquery name="ctcoll_other_id_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT OTHER_ID_TYPE 
	FROM
		ctcoll_other_id_type
	GROUP BY OTHER_ID_TYPE
	ORDER BY OTHER_ID_TYPE
</cfquery>

<cfoutput>
	<div id="ajaxMsg"></div>
	<!--------------------------- search pane ----------------------------->
	<div id="searchContainer">
		<cfset autoSubmit=false>
		<cfif isdefined("container_id")>
			<cfquery name="labelbyid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT label 
				FROM container 
				WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#container_id#">
			</cfquery>
			<cfloop query="labelbyid">
				<cfset autoSubmit=true>
					<cfset container_label="#labelbyid.label#">
			</cfloop>
		<cfelse>
			<cfset container_id = "">
		</cfif>
		<h2>Find Container:</h2>
		<div class="btnTips">
			<input type="button" class="seeTipsLink" id="contBtn" onclick="seetips()" value="Show tips and examples">
		</div>
		<div class="tipPane" id="hiddentips" style="display:none;">
			<div class="tips">
				<ul class="cont-tips1">
					<li>Search to see if a container was entered, especially if no specimens have been attached yet or search for a container without knowing what is in
						that container.</li>
					<li>Find containers of <b>cataloged items</b> by searching the <b>specimen search page &rarr; manage results &rarr; part report (locations)</b>.</li>
					<li>Use % for unknown letters/characters (a.k.a. wildcard).</li>
					<li>If the search is not narrow enough (i.e., returns more than 1000 links), it will timeout.</li>
				</ul>
			 	<ul class="cont-tips2">
					<li>The Unique Identifier value must match exactly (wildcards are not allowed). For the exact match: Mamm_cabinet-1 and Mamm_cabinet_1 are different; however, in the Name field these are the same.</li>
					<li>Entry examples: a freezer name in the Name field = "IZ_freezer-1", barcode in Unique Identifier field = "1000PLACE2216", and container &amp; fixture together: Container Type = "fixture" + name = "Mamm_cabinet%". </li>
	
				</ul>
			</div>
		</div>
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
							<option value="tank">tank</option>
							<option value="envelope">envelope</option>
							<option value="pin">pin</option>
							<option value="collection object">collection object</option>
							<option value="cryovat">-----------</option>
							<option value="cryovat">cryovat</option>
							<option value="cryovial">cryovial</option>
							<option value="freezer">freezer</option>
							<option value="freezer box">freezer box</option>
							<option value="freezer rack">freezer rack</option>
							<option value="position">position</option>
							<option value="rack slot">rack slot</option>
						<option value="set">set</option>
					</select>
				</li>
				<li>
					<script type="text/javascript" language="javascript">
						jQuery(document).ready(function() {
							jQuery("##container_label").autocomplete("/ajax/container_label.cfm", {
								width: 320,
								max: 50,
								extraParams: {
								  container_type: function(){ return $("##container_type").val(); }
								},
								autofill: false,
								multiple: false,
								scroll: true,
								scrollHeight: 300,
								matchContains: true,
								minChars: 2,
								selectFirst:false
							});
						});
					</script>
					<cfif not isdefined("container_label")><cfset container_label=""></cfif>
					<label>Name </label>
					<input type="text" name="container_label" id="container_label" size="20" placeholder="(% for wildcard)" value="#container_label#"/>
				</li>
				<li>
					<input type="hidden" name="transaction_id" id="transaction_id">
					<label>Unique Identifier </label>
					<input type="text" name="barcode" id="barcode" size="20" placeholder=" (exact match)"/>
				</li>
				<li>
					<input type="submit" value="Search" class="schBtn" style="">
					<input class="clrBtn" type="reset" value="Clear" style=""/>
				</li>
				<li>
					<span><a href="ContainerBrowse.cfm">Browse Containers</a></span>
				</li>
			</ul>
			<div style="display: none;">
				<span class="likeLink" onclick="downloadTree()">Flatten Part Locations</span>
				<span class="likeLink" onclick="showTreeOnly()">Drag/Print</span> <br>
				<span class="likeLink" onclick="printLabels()">Print Labels</span> 
			</div>
		</div>
	</div>
	
	<script>
		function seetips() {
			var x = document.getElementById("hiddentips");
			var btn = document.getElementById("contBtn");
	
			if (x.style.display === "none") {
				x.style.display = "block";
				btn.value = 'Hide tips and examples';
			} else {
				x.style.display = "none";
				btn.value = 'Show tips and examples';
			}
		}
	</script>
	<div class="fullPane">
		<div id="treePane" class="cTreePane"></div>
		<div id="detailPane"></div>
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
	<cfelseif isdefined("url.result_id") and len(url.result_id) GT 0>
		<cfset collection_object_id = "">
		<cfquery name="getCollectionObjectIdList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT collection_object_id 
			FROM user_search_table
			WHERE
				user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				AND rownum < 1001
		</cfquery>
		<cfif getCollectionObjectIdList.recordcount GT 0>
			<cfset collection_object_id = ValueList(getCollectionObjectIdList.collection_object_id)> 
		</cfif>
		<script language="javascript" type="text/javascript">
			try {
				parent.dyniframesize();
			} catch(err) {
				// not where we think we are, maybe....
			}
			showSpecTreeOnly('#collection_object_id#');
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
