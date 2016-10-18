<cfinclude template="/includes/_header.cfm">
<script type='text/javascript' src='/includes/ajax.js'></script>
<style>
	.messageDiv {
		background-color:lightgray;
		text-align:center;
		font-size:.8em;
		margin:0em .5em 0em .5em;
	}
	.successDiv {
		color:green;
		border:1px solid;
		padding:.5em;
		margin:.5em;
		text-align:center;
	}		
</style>
<!------------------------------------------------------------------->
<cfif #action# is "nothing">
    <div style="width: 80em;margin:0 auto; padding: 2em 0 4em 0;">
	<cfoutput>
	<cfquery name="ctCollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select collection, collection_id FROM collection order by collection
	</cfquery>
	<cfquery name="ctOtherIdType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct(other_id_type) FROM ctcoll_other_id_type order by other_id_type
	</cfquery>	
	<cfquery name="ctContType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select container_type from ctcontainer_type
		order by container_type
	</cfquery>
	<h2 class="wikilink">Parts to Containers</h2>
	<div>
		This application puts collection objects into containers.
		Parts are listed in three ways:
		<ul class="labels">
			<li><strong>Part Name</strong> = just a part</li>
			<li><strong>Part Name SAMPLE</strong> = a subsample of another part</li>
			<li><strong>Part Name [barcode]</strong> = a part which is in a barcoded container</li>
		</ul>
        
        <p>Things occasionally get stuck - click Refresh to unstick them.</p>
				
	</div>
	<p style="clear:both;margin-top: 1em;">
		<span style="border:1px solid blue; padding:5px;margin:5px;">
			Submit form with Parent Barcode change? <input type="checkbox" name="submitOnChange" id="submitOnChange">
		</span>
		<span style="border:1px solid blue; padding:5px;margin:5px;">
			Filter for un-barcoded parts? <input type="checkbox" name="noBarcode" id="noBarcode"  onchange="getParts()">
		</span>
		<span style="border:1px solid blue; padding:5px;margin:5px;">
			Exclude subsamples? <input type="checkbox" name="noSubsample" id="noSubsample"  onchange="getParts()">
		</span>
		<span style="border:1px solid blue; padding:5px;margin:5px;">
			<span class="likeLink"  onclick="getParts()">Refresh Parts List</span>
		</span>
	</p>
        <br>
        
	<table border id="pTable" style="font-size: .7em;clear:both;margin-top:.5em;">
	<form name="scans" method="post" id="scans">
		<input type="hidden" name="action" value="validate">
		<input type="hidden" name="collection_object_id" id="collection_object_id">
		<tr>
			<td>
				<label for="collection_id">Collection</label>
				<select name="collection_id" id="collection_id" size="1" onchange="getParts()" style="width: 148px;">
					<cfloop query="ctCollection">
						<option value="#collection_id#">#collection#</option>
					</cfloop>
				</select>
			</td>
			<td>
				<label for="other_id_type">ID Type</label>
				<select name="other_id_type" id="other_id_type" size="1" style="width:140px;" onchange="getParts()">
					<option value="catalog_number">Catalog Number</option>
					<cfloop query="ctOtherIdType">
						<option value="#other_id_type#">#other_id_type#</option>
					</cfloop>
				</select>
			</td>
			<td>
				<label for="oidnum">ID Number</label>
				<input type="text" name="oidnum" class="reqdClr" id="oidnum" onchange="getParts()">
			</td>
			<td>
				<label for="part_name">Part Name</label>
				<select name="part_name" id="part_name" size="1" style="width:120px;">
				</select>
			</td>
			<td>
				<label for="part_name_2">Part Name 2</label>
				<select name="part_name_2" id="part_name_2" size="1" style="width:120px;">
					<option value=""></option>
				</select>
			</td>
			<td>
				<label for="new_container_type">Parent Cont Type</label>
				<select name = "new_container_type" id="new_container_type" size="1" class="reqdClr">
					<cfloop query="ctContType">
						<option value="#container_type#">#container_type#</option>
					</cfloop>
				</select>
			</td>
			<td>
				<label for="parent_barcode">Parent Barcode</label>
				<input type="text" name="parent_barcode" id="parent_barcode" onchange="checkSubmit()">
			</td>
	  		<td>
				<input type="button" value="Move it" class="savBtn" onclick="addPartToContainer()">
			</td>
			<td>
				<input type="button" value="New Part" class="insBtn" onclick="clonePart()">
			</td>
		</tr>
	</table>
	</form>
	<div id="thisSpecimen" style="border:1px solid green;font-size:smaller;padding:.35em 2px"></div>
	<div id="msgs"></div>
	<div id="msgs_hist" class="messageDiv"></div>
	<script>
		document.getElementById('oidnum').focus();
		document.getElementById('oidnum').select();
	</script>
</cfoutput>
</cfif>
    </div>
<cfinclude template="/includes/_footer.cfm"/>