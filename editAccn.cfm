<cfset jquery11=true>
<cfinclude template="includes/_header.cfm">
<script type='text/javascript' src='/includes/internalAjax.js'></script>
<script type='text/javascript' src='/includes/transAjax.js'></script>
<cfoutput>
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		$("##ent_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "images/cal_icon.png",
			buttonImageOnly: true });
		$("##rec_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "images/cal_icon.png",
			buttonImageOnly: true });
		$("##rec_until_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "images/cal_icon.png",
			buttonImageOnly: true });
		$("##issued_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "images/cal_icon.png",
			buttonImageOnly: true });
		$("##renewed_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "images/cal_icon.png",
			buttonImageOnly: true });
		$("##exp_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "images/cal_icon.png",
			buttonImageOnly: true });
	});
	function addAccnContainer(transaction_id,barcode){
		$('##newbarcode').addClass('red');
		$.getJSON("/component/functions.cfc",
		{
			method : "addAccnContainer",
			transaction_id : transaction_id,
			barcode : barcode,
			returnformat : "json",
			queryformat : 'column'
		},
		function(r) {
			if (r.STATUS == 'success') {
				$('##newbarcode').removeClass('red').val('').focus();
				var d='<div id="tc_' + r.BARCODE + '">' + r.BARCODE + '&nbsp;<span class="infoLink" onclick="removeAccnContainer(' + r.TRANSACTION_ID + ',\'' + r.BARCODE + '\')">Remove</span></div>';
				$('##existingAccnContainers').append(d);
			} else {
				alert('An error occured! \n ' + r.ERROR);
				$('##newbarcode').focus();
			}
		}
	);
	}
	function removeAccnContainer(transaction_id,barcode){
		$('##newbarcode').addClass('red');
		$.getJSON("/component/functions.cfc",
		{
			method : "removeAccnContainer",
			transaction_id : transaction_id,
			barcode : barcode,
			returnformat : "json",
			queryformat : 'column'
		},
		function(r) {
			if (r.STATUS == 'success') {
				$('##tc_' + r.BARCODE).remove();
				$('##newbarcode').focus();
			} else {
				alert('An error occured! \n ' + r.ERROR);
				$('##newbarcode').focus();
			}
		}
	);
	}
</script>
<!---
	function removeMediaDiv() {
		if(document.getElementById('bgDiv')){
			jQuery('##bgDiv').remove();
		}
		if (document.getElementById('mediaDiv')) {
			jQuery('##mediaDiv').remove();
		}
	}
--->
</cfoutput>
<cfset title="Edit Accession">
<cfif not isdefined("project_id")>
	<cfset project_id = -1>
</cfif>
<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct(trans_agent_role)  from cttrans_agent_role  where trans_agent_role not in ('borrow overseen by', 'lending institution', 'recipient institution', 'entered by') order by trans_agent_role
</cfquery>
<cfquery name="ctcoll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select collection,collection_id from collection order by collection
</cfquery>
<cfquery name="ctStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select accn_status from ctaccn_status order by accn_status
</cfquery>
<cfquery name="ctType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select accn_type from ctaccn_type order by accn_type
</cfquery>
<cfquery name="ctPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select * from ctpermit_type order by permit_type
</cfquery>
<!-------------------------------------------------------------------->
<cfif action is "edit">
    <div style="width: 75em; margin: 0 auto;padding: 2em 0 4em 0;">
	<cfoutput>
	<cftry>
		<script>
			jQuery(document).ready(function() {
				getMedia('accn','#transaction_id#','accnMediaDiv','6','1');
			});
    function addMediaHere(targetid,title,relationLabel,transaction_id,relationship){
           console.log(targetid);
           var url = '/media.cfm?action=newMedia&relationship='+relationship+'&related_value='+relationLabel+'&related_id='+transaction_id ;
           var amddialog = $('##'+targetid)
           .html('<iframe style="border: 0px; " src="'+url+'" width="100%" height="100%" id="mediaIframe"></iframe>')
           .dialog({
                 title: title,
                 autoOpen: false,
                 dialogClass: 'dialog_fixed,ui-widget-header',
                 modal: true,
                 height: 900,
                 width: 1100,
                 minWidth: 400,
                 minHeight: 400,
                 draggable:true,
                 buttons: {
                     "Close": function () { 
                        loadTransactionFormMedia(#transaction_id#,'accn'); 
                        $(this).dialog("close"); 
                     } 
                 }
           });
           amddialog.dialog('open');          
           console.log('dialog open called');
           console.log(transaction_id);
           console.log(relationship);
     };

		</script>

		<cfset title="Edit Accession">
		<cfquery name="accnData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				trans.transaction_id,
				trans.transaction_type,
				accn_number,
			 	accn_status,
				accn_type,
				received_date,
				nature_of_material,
				received_agent_id,
				trans_remarks,
				trans_date,
				collection,
				trans.collection_id,
				concattransagent(trans.transaction_id,'entered by') enteredby,
				estimated_count
			FROM
				trans,
				accn,
				collection
			WHERE
				trans.transaction_id = accn.transaction_id AND
				trans.collection_id=collection.collection_id and
				trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfif accnData.RecordCount EQ 0 > 
			<cfthrow message = "No such Accession.">
		</cfif>
		<cfif accnData.RecordCount GT 0 AND accnData.transaction_type NEQ 'accn'> 
			<cfthrow message = "Request to edit an Accession, but the provided transaction_id was for a different transaction type.">
		</cfif>
		<cfquery name="transAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				trans_agent_id,
				trans_agent.agent_id,
				agent_name,
				trans_agent_role,
	                        MCZBASE.get_worstagentrank(trans_agent.agent_id) worstagentrank
			from
				trans_agent,
				preferred_agent_name
			where
				trans_agent.agent_id = preferred_agent_name.agent_id and
				trans_agent_role != 'entered by' and
				trans_agent.transaction_id=#transaction_id#
			order by
				trans_agent_role,
				agent_name
		</cfquery>
		<h2 class="wikilink"><strong>Edit Accession</strong></h2>
		<cfform action="editAccn.cfm" method="post" name="editAccn">
		<table><tr><td valign="top">
				<input type="hidden" name="Action" value="saveChanges">
				<input type="hidden" name="transaction_id" value="#accnData.transaction_id#">
				<cfset tIA=accnData.collection_id>
				<table border>
					<tr>
						<td>
							<label for="collection_id">Collection</label>
							<select name="collection_id" size="1"  class="reqdClr" id="collection_id">
								<cfloop query="ctcoll">
									<option <cfif #ctcoll.collection_id# is #tIA#> selected </cfif>
									value="#ctcoll.collection_id#">#ctcoll.collection#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="accn_number">Accn Number</label>
							<input type="text" name="accn_number" value="#accnData.accn_number#"  id="accn_number" class="reqdClr">
						</td>
						<td>
							<label for="accn_type">Accession Type</label>
							<select name="accn_type" size="1"  class="reqdClr" id="accn_type">
								<cfloop query="cttype">
									<option <cfif #cttype.accn_type# is "#accnData.accn_type#"> selected </cfif>
									value="#cttype.accn_type#">#cttype.accn_type#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="accn_status">Status</label>
							<select name="accn_status" size="1"  class="reqdClr" id="accn_status">
								<cfloop query="ctStatus">
									<option <cfif #ctStatus.accn_status# is "#accnData.accn_status#">selected </cfif>
									value="#ctStatus.accn_status#">#ctStatus.accn_status#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="rec_date">Received Date</label>
							<cfinput type="text"
								name="rec_date"
								value="#DateFormat(accnData.received_date, 'yyyy-mm-dd')#"
								size="10"
								id="rec_date">
						</td>
						<td>
							<label for="estimated_count">
                                   <!---onClick="getDocs('accession','estimated_count')" class="likeLink">--->
								Est. Cnt.
							</label>
							<cfinput type="text" validate="integer"
								message="##Specimens must be a number" name="estimated_count"
								value="#accnData.estimated_count#" size="10" id="estimated_count">
						</td>
					</tr>
					<tr>
						<td colspan="6">
							<label for="nature_of_material">Nature of Material:</label>
							<textarea name="nature_of_material" rows="5" cols="90"  class="reqdClr"
								id="nature_of_material">#accnData.nature_of_material#</textarea>
						</td>
					</tr>
					<tr>
						<td colspan="6">
							<table border>
								<tr>
									<th>Agent Name</th>
									<th></th>
									<th>Role</th>
									<th>Delete?</th>
								</tr>
								<cfset i=0>
								<cfloop query="transAgents">
								        <cfset i++>
									<tr>
										<td>
											<input type="text" name="trans_agent_#trans_agent_id#" class="reqdClr" size="50" value="#agent_name#"
							  					onchange="getAgent('trans_agent_id_#trans_agent_id#','trans_agent_#trans_agent_id#','editAccn',this.value); return false;"
							  					onKeyPress="return noenter(event);">
							  				<input type="hidden" name="trans_agent_id_#trans_agent_id#" value="#agent_id#"
												 onchange=" updateAgentLink($('##agent_id_#i#').val(),'agentViewLink_#i#');" >
										</td>
										<td style=" min-width: 3.5em; ">
										    <span id="agentViewLink_#i#"><a href="/agents/Agent.cfm?agent_id=#agent_id#" target="_blank">View</a><cfif transAgents.worstagentrank EQ 'A'> &nbsp;<cfelseif transAgents.worstagentrank EQ 'F'><img src='/images/flag-red.svg.png' width='16'><cfelse><img src='/images/flag-yellow.svg.png' width='16'></cfif>
					                                            </span>
										</td>
										<td>
											<cfset thisRole = #trans_agent_role#>
											<select name="trans_agent_role_#trans_agent_id#">
												<cfloop query="cttrans_agent_role">
													<option
														<cfif #trans_agent_role# is #thisRole#> selected="selected"</cfif>
														value="#trans_agent_role#">#trans_agent_role#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<input type="checkbox" name="del_agnt_#trans_agent_id#">
										</td>
									</tr>
								</cfloop>
								<tr class="newRec">
									<td>
										<label for="new_trans_agent">Add Agent:</label>
										<input type="text" name="new_trans_agent" id="new_trans_agent" class="reqdClr" size="50"
						  					onchange="getAgent('new_trans_agent_id','new_trans_agent','editAccn',this.value); return false;"
						  					onKeyPress="return noenter(event);">
						  				<input type="hidden" name="new_trans_agent_id">
									</td>
									<td>&nbsp;</td>
									<td>
										<label for="new_trans_agent_role">&nbsp;</label>
										<select name="new_trans_agent_role" id="new_trans_agent_role">
											<cfloop query="cttrans_agent_role">
												<option value="#trans_agent_role#">#trans_agent_role#</option>
											</cfloop>
										</select>
									</td>
								</tr>
							</table>
						</td>
					</tr>
					<tr>
						<td colspan="6">
							<label for="remarks">Remarks:</label>
							<textarea name="remarks" rows="5" cols="90" id="remarks">#accnData.trans_remarks#</textarea>
						</td>
					</tr>
					<tr>
						<td colspan="6">
							<em>Entered by</em>
							<strong>#accnData.enteredby#</strong> <em>on</em> <strong>#dateformat(accnData.trans_date,'yyyy-mm-dd')#</strong>
						</td>

					</tr>
					<tr>
						<td colspan="6" align="center">
						<input type="submit" value="Save Changes" class="savBtn">
				 		<input type="button" value="Quit without saving" class="qutBtn"
							onclick = "document.location = 'editAccn.cfm'">
						<input type="button" value="Specimen List" class="lnkBtn"
						 	onclick = "window.open('SpecimenResults.cfm?accn_trans_id=#transaction_id#');">
				       	<input type="button" value="BerkeleyMapper" class="lnkBtn"
							onclick = "window.open('/bnhmMaps/bnhmMapData.cfm?accn_number=#accnData.accn_number#','_blank');">
						</td>
					</tr>
				</table>
		</div>
		</td><td valign="top">
			<cfquery name="accncontainers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select barcode from container, trans_container where
				container.container_id=trans_container.container_id and
				transaction_id=#transaction_id#
			</cfquery>
			<table border="1">
				<tr>
					<td>
						<strong>Accn&nbsp;Containers</strong>
						<br><a target="_blank" href="/findContainer.cfm?transaction_id=#transaction_id#&autosubmit=true">Show Locations</a>
					</td>
				</tr>
				<tr>
					<td>
						<label for="">Scan New Barcode</label>
						<input type="text" id="newbarcode" name="newbarcode" size="15" onchange="addAccnContainer(#transaction_id#,this.value)">
					</td>
				</tr>
				<tr>
					<td id="existingAccnContainers">
						<cfloop query="accncontainers">
							<div id="tc_#barcode#">
								#barcode# <span class="infoLink" onclick="removeAccnContainer(#transaction_id#,'#barcode#')">Remove</span>
							</div>
						</cfloop>
					</td>
				</tr>

			</table>
		</td><td valign="middle">
		</td></tr></table>

<div class="shippingBlock"> 
   		<label for="redir">Print...</label>
		<select name="redir" id="redir" size="1" onchange="if(this.value.length>0){window.open(this.value,'_blank')};">
   			<option value=""></option>
			<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_files_accn_header">Header Copy for MCZ Files</option>
        </select>
</div>


<div class="shippingBlock"> 

			<h3>Projects associated with this Accession:</h3>
			<ul style="list-style:none;">
				<cfquery name="projs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select project_name, project.project_id from project,
					project_trans where
					project_trans.project_id =  project.project_id
					and transaction_id=#transaction_id#
				</cfquery>
				<cfif #projs.recordcount# gt 0>
					<cfloop query="projs">
						<li>
							<a href="/Project.cfm?Action=editProject&project_id=#project_id#"><strong>#project_name#</strong></a><br>
						</li>
					</cfloop>
				<cfelse>
					<li>None</li>
				</cfif>
			</ul>
			<table class="newRec" width="280px">
				<tr>
					<td>
						<label for="project_name">New Project</label>
						<input type="hidden" name="project_id">
						<input type="text"
							size="35"
							name="project_name"
							id="project_name"
							class="reqdClr"
							onchange="getProject('project_id','project_name','editAccn',this.value); return false;"
							onKeyPress="return noenter(event);">
					</td>
				</tr>
			</table>

</div>

</cfform>

<div class="shippingBlock"> 
			<h3>Media associated with this Accession:</h3>
            <p style="margin:0px;">Include copies of correspondence and other documents (e.g. data files, scans of maps, inventory lists) which are not permissions or rights documents documents here.</p>
			<br><span>
		                <cfset relation="documents accn">
				<input type='button' onClick="opencreatemediadialog('newMediaDlg_#transaction_id#','Accession: #accnData.collection# #accndata.accn_number#','#transaction_id#','#relation#',reloadTransMedia);" value='Create Media' class='lnkBtn' >&nbsp;
      				<span id='addMedia_#transaction_id#'>
				<input type='button' style='margin-left: 30px;' onClick="openlinkmediadialog('newMediaDlg_#transaction_id#','Accession: #accnData.collection# #accndata.accn_number#','#transaction_id#','#relation#',reloadTransMedia);" value='Link Media' class='lnkBtn' >&nbsp;
				</span>
			</span>
			<div id='addMediaDlg_#transaction_id#'></div>
			<div id='newMediaDlg_#transaction_id#'></div>
			<div id="transactionFormMedia"><img src='images/indicator.gif'> Loading Media....</div>
<script>

// callback for ajax methods to reload from dialog
function reloadTransMedia() { 
    loadTransactionFormMedia(#transaction_id#,"accn");
    if ($("##addMediaDlg_#transaction_id#").hasClass('ui-dialog-content')) {
        $('##addMediaDlg_#transaction_id#').html('').dialog('destroy');
    }
};

$( document ).ready(loadTransactionFormMedia(#transaction_id#,"accn"));

</script>
</div>
<div class="shippingBlock"> 
    <h3>Permissions and Rights documents (e.g. Permits):</h3>
    <p style="margin:0px;">List here all permissions and rights related documents associated with this accession including the deed of gift, collecting permits, CITES Permits, material transfer agreements, access benefit sharing agreements and other compliance or permit-like documents.  Permits (but not deeds of gift and some other document types) listed here are linked to all subsequent shipments of material from this accession.  <strong>If you aren't sure of whether a permit or permit-like document should be listed with a particular shipment for the accession or here under the accession, list it at least here.</strong></p>

                <div style="float:left;width:95%; margin-top:0px;" id="transactionFormPermits" class="shippermitstyle">Loading permits...</div>

                <div class='shipbuttons' id='addPermit_#transaction_id#'>
				   <input type='button' 
                          style='margin-left: 30px;' 
                          onClick="openlinkpermitdialog('addPermitDlg_#transaction_id#','#transaction_id#','Accession: #accnData.collection# #accndata.accn_number#',reloadTransPermits);" 
                          value='Add Permit to this Accession' class='lnkBtn'>
                </div><div id='addPermitDlg_#transaction_id#'></div>
</div>

<script>

// callback for ajax methods to reload from dialog
function reloadTransPermits() { 
    loadTransactionFormPermits(#transaction_id#);
    if ($("##addPermitDlg_#transaction_id#").hasClass('ui-dialog-content')) {
        $('##addPermitDlg_#transaction_id#').html('').dialog('destroy');
    }
};

$( document ).ready(loadTransactionFormPermits(#transaction_id#));

</script>

<div class="shippingBlock">
    <h3>Shipment Information:</h3>
    <p style="margin:0px;">Include Permits such as USFWS Form 3-177 which are only involved in an incoming shipment of the accession, and are not inherited by future shipments of this material under the relevant shipment here.</p>
<script>

function opendialog(page,id,title) {
  var content = '<iframe style="border: 0px; " src="' + page + '" width="100%" height="100%"></iframe>'
  var adialog = $(id)
  .html(content)
  .dialog({
    title: title,
    autoOpen: false,
    dialogClass: 'dialog_fixed,ui-widget-header',
    modal: true,
    height: 900,
    width: 1100,
    minWidth: 400,
    minHeight: 450,
    draggable:true,
    resizable:true,
    buttons: { "Ok": function () { loadShipments(#transaction_id#); $(this).dialog("destroy"); $(id).html(''); } },
    close: function() { loadShipments(#transaction_id#);  $(this).dialog("destroy"); $(id).html(''); }
  });
  adialog.dialog('open');
};

</script>

	<cfquery name="ctShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select shipped_carrier_method from ctshipped_carrier_method order by shipped_carrier_method
	</cfquery>
	<cfquery name="ship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                 select sh.*, toaddr.country_cde tocountry, toaddr.institution toinst, fromaddr.country_cde fromcountry, fromaddr.institution frominst
                 from shipment sh
                    left join addr toaddr on sh.shipped_to_addr_id  = toaddr.addr_id
                    left join addr fromaddr on sh.shipped_from_addr_id = fromaddr.addr_id
		where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnData.transaction_id#">
	</cfquery>
    <div id="shipmentTable">Loading shipments...</div> <!--- shippmentTable for ajax replace --->

<script>

$( document ).ready(loadShipments(#transaction_id#));

    $(function() {
      $("##dialog-shipment").dialog({
        autoOpen: false,
        modal: true,
        width: 650,
        buttons: {
          "Save": function() {  saveShipment(#transaction_id#); } ,
          Cancel: function() {
            $(this).dialog( "close" );
          }
        },
        close: function() {
            $(this).dialog( "close" );
        }
      });
    });
</script>
    <div class="addstyle">
    <input type="button" class="lnkBtn" value="Add Shipment" onClick="$('##dialog-shipment').dialog('open'); setupNewShipment(#transaction_id#);"><div class="shipmentnote">Note: please check the <a href="https://code.mcz.harvard.edu/wiki/index.php/Country_Alerts">Country Alerts</a> page for special instructions or restrictions associated with specific countries</div></div><!---moved this to inside of the shipping block--one div up--->
</div> <!--- end shipping block ---> 




<div id="dialog-shipment" title="Create new Shipment">
  <form name="shipmentForm" id="shipmentForm" >
    <fieldset>
	<input type="hidden" name="transaction_id" value="#transaction_id#" id="shipmentForm_transaction_id" >
	<input type="hidden" name="shipment_id" value="" id="shipment_id">
	<input type="hidden" name="returnFormat" value="json" id="returnFormat">
           <table>
             <tr>
              <td>
		<label for="shipped_carrier_method">Shipping Method</label>
		<select name="shipped_carrier_method" id="shipped_carrier_method" size="1" class="reqdClr">
			<option value=""></option>
			<cfloop query="ctShip">
				<option value="#ctShip.shipped_carrier_method#">#ctShip.shipped_carrier_method#</option>
			</cfloop>
		</select>
              </td>
              <td colspan="2">
		<label for="carriers_tracking_number">Tracking Number</label>
		<input type="text" value="" name="carriers_tracking_number" id="carriers_tracking_number" size="30" >
              </td>
            </tr><tr>
              <td>
		<label for="no_of_packages">Number of Packages</label>
		<input type="text" value="1" name="no_of_packages" id="no_of_packages">
              </td>
              <td>
		<label for="shipped_date">Ship Date</label>
		<input type="text" value="#dateformat(Now(),'yyyy-mm-dd')#" name="shipped_date" id="shipped_date">
              </td>
              <td>
		<label for="foreign_shipment_fg">Foreign shipment?</label>
		<select name="foreign_shipment_fg" id="foreign_shipment_fg" size="1">
			<option selected value="0">no</option>
			<option value="1">yes</option>
		</select>
              </td>
            </tr><tr>
              <td>
		<label for="package_weight">Package Weight (TEXT, include units)</label>
		<input type="text" value="" name="package_weight" id="package_weight">
              </td>
              <td>
		<label for="insured_for_insured_value">Insured Value (NUMBER, US$)</label>
		<input type="text" validate="float" label="Numeric value required."
			 value="" name="insured_for_insured_value" id="insured_for_insured_value">
              </td>
              <td>
		<label for="hazmat_fg">HAZMAT?</label>
		<select name="hazmat_fg" id="hazmat_fg" size="1">
			<option selected value="0">no</option>
			<option value="1">yes</option>
		</select>
              </td>
            </tr>
           </table>

		<label for="packed_by_agent">Packed By Agent</label>
		<input type="text" name="packed_by_agent" class="reqdClr" size="50" value="" id="packed_by_agent"
			  onchange="getAgent('packed_by_agent_id','packed_by_agent','shipmentForm',this.value); return false;"
			  onKeyPress="return noenter(event);">
		<input type="hidden" name="packed_by_agent_id" value="" id="packed_by_agent_id" >

		<label for="shipped_to_addr">Shipped To Address</label>
        	<span>
            		<input type="button" value="Pick Address" class="picBtn"
                	onClick="addrPickWithTemp('shipped_to_addr_id','shipped_to_addr','shipmentForm');  $('##tempShipToAddrButton').removeAttr('disabled').removeClass('ui-state-disabled'); return false;">
            		<input type="button" value="Temporary Address" class="picBtn ui-state-disabled"  disabled="true" id="tempShipToAddrButton"
                		onClick="addTemporaryAddress('shipped_to_addr_id','shipped_to_addr',#transaction_id#); $('##tempShipToAddrButton').attr('disabled','true').addClass('ui-state-disabled'); return false;">
        	</span>
		<textarea name="shipped_to_addr" id="shipped_to_addr" cols="60" rows="5"
			readonly="yes" class="reqdClr"></textarea>
		<input type="hidden" name="shipped_to_addr_id" id="shipped_to_addr_id" value="">

		<label for="shipped_from_addr">Shipped From Address</label>
        	<span>
           		<input type="button" value="Pick Address" class="picBtn"
                		onClick="addrPickWithTemp('shipped_from_addr_id','shipped_from_addr','shipmentForm');  $('##tempShipFromAddrButton').removeAttr('disabled').removeClass('ui-state-disabled'); return false;">
            		<input type="button" value="Temporary Address" class="picBtn ui-state-disabled"  disabled="true" id="tempShipFromAddrButton"
                		onClick="addTemporaryAddress('shipped_from_addr_id','shipped_from_addr',#transaction_id#); $('##tempShipFromAddrButton').attr('disabled','true').addClass('ui-state-disabled'); return false;">
        	</span>
		<textarea name="shipped_from_addr" id="shipped_from_addr" cols="60" rows="5"
			readonly="yes" class="reqdClr"></textarea>
		<input type="hidden" name="shipped_from_addr_id" id="shipped_from_addr_id" value="">

		<label for="shipment_remarks">Remarks</label>
		<input type="text" value="" name="shipment_remarks" id="shipment_remarks" size="60">
		<label for="contents">Contents</label>
		<input type="text" value="" name="contents" id="contents" size="60">

    </fieldset>
  </form>
  <div id="shipmentFormPermits"></div>
  <div id="shipmentFormStatus"></div>
</div>
<div id="tempAddressDialog"></div>

<div class="shippingBlock"> 
	<h3>Dispositions of cataloged items:</h3>
	<input type="button" value="Specimen List" class="lnkBtn"
		onclick = "window.open('SpecimenResults.cfm?accn_trans_id=#accnData.transaction_id#');">
	<cfquery name="dispositions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select count(cataloged_item.collection_object_id) cicount,
		     count(coll_object.collection_object_id) pcount,
		     coll_obj_disposition, deacc_number, deaccession.transaction_id
		from accn
		   left join cataloged_item on accn.transaction_id = cataloged_item.accn_id
		   left join specimen_part on cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
		   left join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
		   left join deacc_item on specimen_part.collection_object_id = deacc_item.collection_object_id
		   left join deaccession on deacc_item.transaction_id = deaccession.transaction_id
		where accn.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accnData.transaction_id#">
		group by deacc_number, coll_obj_disposition, deaccession.transaction_id
		order by deacc_number, coll_obj_disposition
	</cfquery>
        <table>
	   <tr> <th>Parts</th> <th>Disposition</th> <th>Deaccession</th> </tr>
	<cfloop query="dispositions">
	   <tr> <td>#pcount#</td> <td>#coll_obj_disposition#</td> <td><a href="Deaccession.cfm?action=listDeacc&deacc_number=#deacc_number#">#deacc_number#</a></td> </tr>
        </cfloop>
	</table>
</div>
	<cfcatch>
		<h2>Error: #cfcatch.message#</h2>
		<cfif cfcatch.detail NEQ ''>#cfcatch.detail#</cfif>
	</cfcatch>
	</cftry>
	</cfoutput>
</div>
</cfif>
<!-------------------------------------------------------------------->
<cfif action is "nothing">
	<cfset title = "Find Accession">
		<cfoutput>
            <div style="width: 48em;margin:0 auto;padding: 1em 0 3em 0;">
		<h2 class="wikilink" style="margin-left:0;">Find Accession <img class="infoLink" src="/images/info_i_2.gif" alt="[help]" onClick="getMCZDocs('Find Accession')"/></h2>
			<cfif #project_id# gt 0>to add to project ## #project_id#</cfif>

		<form action="editAccn.cfm" method="post" name="SpecData" preservedata="yes">
			<input type="hidden" name="Action" value="findAccessions">
			<input type="hidden" <cfif project_id gt 0> value = "#project_id#" </cfif> name="project_id">
			<table style="border:1px solid gray; padding: 1.25em; padding-top: .75em;background-color: ##f8f8f8;">
				<tr>
					<td>
						<label  for="accn_number">Accn Number</label>
						<input type="text" name="accn_number" id="accn_number">
						<span class="smaller">&nbsp;Exact Match?</span> <input type="checkbox" name="exactAccnNumMatch" value="1">
					</td>
					<td align="right">
						<label  for="collection_id">Collection</label>
						<select name="collection_id" size="1" id="collection_id">
							<option value=""></option>
								<cfloop query="ctcoll">
									<option value="#ctcoll.collection_id#">#ctcoll.collection#</option>
								</cfloop>
						</select>
					</td>
					<td>
						<label  for="accn_status">Status</label>
						<select name="accn_status" id="accn_status" size="1">
							<option value=""></option>
								<cfloop query="ctStatus">
									<option value="#ctStatus.accn_status#">#ctStatus.accn_status#</option>
								</cfloop>
						</select>
					</td>
				</tr>
				<tr>
					<td align="right">
						Agent:<select name="trans_agent_role_1">
							<option value=""></option>
							<cfloop query="cttrans_agent_role">
								<option value="#trans_agent_role#">#trans_agent_role#</option>
							</cfloop>
							<option value="entered by">entered by</option>
						</select>
					</td>
					<td colspan="2">
						<input type="text" name="agent_1"  size="50">
					 </td>
				</tr>
				<tr>
					<td align="right">
						Agent:<select name="trans_agent_role_2">
							<option value=""></option>
							<cfloop query="cttrans_agent_role">
								<option value="#trans_agent_role#">#trans_agent_role#</option>
							</cfloop>
							<option value="entered by">entered by</option>
						</select>
					</td>
					<td colspan="2">
						<input type="text" name="agent_2"  size="50">
					 </td>
				</tr>
				<tr>
					<td align="right">
						Agent:<select name="trans_agent_role_3">
							<option value=""></option>
							<cfloop query="cttrans_agent_role">
								<option value="#trans_agent_role#">#trans_agent_role#</option>
							</cfloop>
							<option value="entered by">entered by</option>
						</select>
					</td>
					<td colspan="2">
						<input type="text" name="agent_3"  size="50">
					</td>
				</tr>
				<tr>
					<td colspan="3">
						<label  for="nature_of_material">Nature of Material</label>
						<input <cfif isdefined("nature_of_material")>value="#nature_of_material#"</cfif>
							type="text" name="nature_of_material" id="nature_of_material" size="90">
					</td>
				</tr>
				<tr>
					<td>
						<label  for="accn_type">Accession Type</label>
						<select name="accn_type" id="accn_type" size="1">
							<option value=""></option>
							<cfloop query="cttype">
								<option value="#cttype.accn_type#">#cttype.accn_type#</option>
							</cfloop>
						</select>
					</td>
				</tr>
				<tr>
					<td colspan="3">
						<label  for="remarks">Remarks</label>
						<input <cfif isdefined("remarks")>value="#remarks#"</cfif>
							type="text" name="remarks" id="remarks" size="90">
					</td>
				</tr>
				<tr>
					<td>
						<label for="ent_Date">Entry Date</label>
						<select name="entDateOper" id="entDateOper" size="1">
							<option value="<=">Before</option>
							<option selected value="=" >Is</option>
							<option value=">=">After</option>
						</select>
						<input type="text" name="ent_date" id="ent_date">
					</td>
					<td colspan=2 nowrap>
						<table cellspacing='0' cellpadding='0'>
							<td>
								<label  for="rec_date">Received Date:</label>
								<input type="text" name="rec_date" id="rec_date">&nbsp;&nbsp;
							</td>
							<td>
								<label for="rec_until_date">Until: (leave blank otherwise)</label>
								<input type='text' name='rec_until_date' id='rec_until_date'>
							</td>
						</table>
					</td>
				</tr>
				<tr>

					<td style="padding-top: 1.25em;"><strong>Permits:</strong></td>
				</tr>
				<tr>
					<td>
						<label  for="IssuedByAgent">Issued By</label>
						<input type="text" name="IssuedByAgent" id="IssuedByAgent">
					</td>
					<td>
						<label  for="IssuedByAgent">Issued To</label>
						<input type="text" name="IssuedToAgent" id="IssuedToAgent">
					</td>
			 	</tr>
				<tr>
					<td>
						<label  for="IssuedByAgent">Issued Date</label>
						<input type="text" name="issued_date" id="issued_date">
					</td>
					<td>
						<label  for="IssuedByAgent">Renewed Date</label>
						<input type="text" name="renewed_date" id="renewed_date">
					</td>
				</tr>
				<tr>
					<td>
						<label  for="IssuedByAgent">Expiration Date</label>
						<input type="text" name="exp_date" id="exp_date">
					</td>
					<td>
						<label  for="IssuedByAgent">Permit Number</label>
						<input type="text" name="permit_num" id="permit_num">
						<span class="infoLink" onclick="getHelp('get_permit_number');">Pick</span>
					</td>
				</tr>
				<tr>
					<td>
						<label  for="permit_Type">Permit Type</label>
						<select name="permit_Type" size="1" id="permit_Type">
							<option value=""></option>
							<cfloop query="ctPermitType">
								<option value = "#ctPermitType.permit_type#">#ctPermitType.permit_type#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<label  for="permit_remarks">Remarks</label>
						<input type="text" name="permit_remarks" id="permit_remarks">
					</td>
				<tr>
					<td colspan="4" align="center"  style="padding-top: 1em;">
				 		<input type="submit" value="Find Accession" class="schBtn">&nbsp;
						<input type="button" value="Create a new accession" class="insBtn"
							onClick="document.location = '/transactions/Accession.cfm?action=new';">	&nbsp;
						<input type="button" value="Clear Form" class="clrBtn" onClick="document.location='editAccn.cfm';">	&nbsp;
						<input type="button" value="Add Specimens to an Accn" class="lnkBtn"
						   onclick = "window.open('SpecimenSearch.cfm?Action=addAccn');">
					</td>
				</tr>
			</table>
		</form>
</div>
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "findAccessions">
    <div style="width: 60em; margin: 0 auto; padding: 2em 0 4em 0;">
<cfset title = "Accession Search Results">
	<cfoutput>
		<cfset sel = "SELECT
			trans.transaction_id,
			accn_number,
			nature_of_material,
			received_date,
			accn_status,
			trans_remarks,
			issuedTo.agent_name as issuedTo,
			issuedBy.agent_name as issuedBy,
			collection,
			project_name,
			project.project_id pid,
			estimated_count,
			concattransagent(trans.transaction_id,'entered by') ENTAGENT,
			concattransagent(trans.transaction_id,'received from') RECFROMAGENT">
		<cfset frm=" from
		 	accn,
			trans,
			permit_trans,
			permit,
			preferred_agent_name issuedBy,
			preferred_agent_name issuedTo,
			collection,
			project_trans,
			project">
		<cfset sql = " where accn.transaction_id = trans.transaction_id and
			trans.transaction_id = permit_trans.transaction_id (+) and
			permit_trans.permit_id = permit.permit_id (+) and
			permit.issued_by_agent_id = issuedBy.agent_id (+) and
			permit.issued_to_agent_id = issuedTo.agent_id (+) and
			trans.transaction_id = project_trans.transaction_id (+) and
			project_trans.project_id = project.project_id (+) AND
			trans.collection_id=collection.collection_id ">
		<cfif isdefined("trans_agent_role_1") AND len(#trans_agent_role_1#) gt 0>
			<cfset frm="#frm#,trans_agent trans_agent_1">
			<cfset sql="#sql# and trans.transaction_id = trans_agent_1.transaction_id">
			<cfset sql = "#sql# AND trans_agent_1.trans_agent_role = '#stripQuotes(trans_agent_role_1)#'">
		</cfif>
		<cfif isdefined("agent_1") AND len(#agent_1#) gt 0>
			<cfif #sql# does not contain "trans_agent_1">
				<cfset frm="#frm#,trans_agent trans_agent_1">
				<cfset sql="#sql# and trans.transaction_id = trans_agent_1.transaction_id">
			</cfif>
			<cfset frm="#frm#,preferred_agent_name trans_agent_name_1">
			<cfset sql="#sql# and trans_agent_1.agent_id = trans_agent_name_1.agent_id">
			<cfset sql = "#sql# AND upper(trans_agent_name_1.agent_name) like '%#escapeQuotes(ucase(agent_1))#%'">
		</cfif>
		<cfif isdefined("trans_agent_role_2") AND len(#trans_agent_role_2#) gt 0>
			<cfset frm="#frm#,trans_agent trans_agent_2">
			<cfset sql="#sql# and trans.transaction_id = trans_agent_2.transaction_id">
			<cfset sql = "#sql# AND trans_agent_2.trans_agent_role = '#stripQuotes(trans_agent_role_2)#'">
		</cfif>
		<cfif isdefined("agent_2") AND len(#agent_2#) gt 0>
			<cfif #sql# does not contain "trans_agent_2">
				<cfset frm="#frm#,trans_agent trans_agent_2">
				<cfset sql="#sql# and trans.transaction_id = trans_agent_2.transaction_id">
			</cfif>
			<cfset frm="#frm#,preferred_agent_name trans_agent_name_2">
			<cfset sql="#sql# and trans_agent_2.agent_id = trans_agent_name_2.agent_id">
			<cfset sql = "#sql# AND upper(trans_agent_name_2.agent_name) like '%#escapeQuotes(ucase(agent_2))#%'">
		</cfif>
		<cfif isdefined("trans_agent_role_3") AND len(#trans_agent_role_3#) gt 0>
			<cfset frm="#frm#,trans_agent trans_agent_3">
			<cfset sql="#sql# and trans.transaction_id = trans_agent_3.transaction_id">
			<cfset sql = "#sql# AND trans_agent_3.trans_agent_role = '#stripQuotes(trans_agent_role_3)#'">
		</cfif>
		<cfif isdefined("agent_3") AND len(#agent_3#) gt 0>
			<cfif #sql# does not contain "trans_agent_3">
				<cfset frm="#frm#,trans_agent trans_agent_3">
				<cfset sql="#sql# and trans.transaction_id = trans_agent_3.transaction_id">
			</cfif>
			<cfset frm="#frm#,preferred_agent_name trans_agent_name_3">
			<cfset sql="#sql# and trans_agent_3.agent_id = trans_agent_name_3.agent_id">
			<cfset sql = "#sql# AND upper(trans_agent_name_3.agent_name) like '%#escapeQuotes(ucase(agent_3))#%'">
		</cfif>
		<cfif isdefined("collection_id") and len(#collection_id#) gt 0>
			<cfset sql = "#sql# AND trans.collection_id = #collection_id#">
		</cfif>
		<cfif  isdefined("accn_number") and len(#accn_number#) gt 0>
			<cfif isdefined("exactAccnNumMatch") and #exactAccnNumMatch# is 1>
				<cfset sql = "#sql# AND accn_number = '#accn_number#'">
			<cfelse>
				<cfset sql = "#sql# AND upper(accn_number) LIKE '%#stripQuotes(ucase(accn_number))#%'">
			</cfif>
		</cfif>
		<cfif  isdefined("accn_status") and len(#accn_status#) gt 0>
			<cfset sql = "#sql# AND accn_status = '#stripQuotes(accn_status)#'">
		</cfif>
		<cfif  isdefined("rec_date") and len(#rec_date#) gt 0>
			<cfif isdefined("rec_until_date") and len(#rec_until_date#) gt 0>
				<cfset sql = "#sql# AND upper(received_date) between to_date('#stripQuotes(rec_date)#', 'yyyy-mm-dd')
					and to_date('#stripQuotes(rec_until_date)#', 'yyyy-mm-dd')">
			<cfelse>
				<cfset sql = "#sql# AND upper(received_date) like to_date('#stripQuotes(rec_date)#', 'yyyy-mm-dd')">
			</cfif>
		</cfif>
		<cfif  isdefined("NATURE_OF_MATERIAL") and len(#NATURE_OF_MATERIAL#) gt 0>
			<cfset sql = "#sql# AND upper(NATURE_OF_MATERIAL) like '%#escapeQuotes(ucase(NATURE_OF_MATERIAL))#%'">
		</cfif>
		<cfif  isdefined("rec_agent") and len(#rec_agent#) gt 0>
			<cfset frm = "#frm#,agent_name">
			<cfset sql = "#sql# AND upper(agent_name.agent_name) like '%#escapeQuotes(ucase(rec_agent))#%'
				AND trans.received_agent_id = agent_name.agent_id">
		</cfif>
		<cfif  isdefined("trans_agency") and len(#trans_agency#) gt 0>
			<cfset sql = "#sql# AND upper(transAgent.agent_name) LIKE  '%#escapeQuotes(ucase(trans_agency))#%'">
		</cfif>
		<cfif  isdefined("accn_type") and len(#accn_type#) gt 0>
			<cfset sql = "#sql# AND accn_type = '#stripQuotes(accn_type)#'">
		</cfif>
		<cfif isdefined("remarks") and  len(#remarks#) gt 0>
			<cfset sql = "#sql# AND upper(trans_remarks) like '%#escapeQuotes(ucase(remarks))#%'">
		</cfif>
		<cfif  isdefined("ent_date") and len(ent_date) gt 0>
			<cfset sql = "#sql# AND TRANS_DATE #entDateOper# '#ucase(dateformat(stripQuotes(ent_date),"yyyy-mm-dd"))#'">
		</cfif>
		<cfif isdefined("IssuedByAgent") and len(#IssuedByAgent#) gt 0>
			<cfset sql = "#sql# AND upper(issuedBy.agent_name) like '%#escapeQuotes(ucase(IssuedByAgent))#%'">
		</cfif>
		<cfif isdefined("IssuedToAgent") and len(#IssuedToAgent#) gt 0>
			<cfset sql = "#sql# AND upper(issuedTo.agent_name) like '%#escapeQuotes(ucase(IssuedToAgent))#%'">
		</cfif>
		<cfif  isdefined("issued_date") and len(#issued_date#) gt 0>
			<cfset sql = "#sql# AND upper(issued_date) like '%#stripQuotes(ucase(issued_date))#%'">
		</cfif>
		<cfif  isdefined("renewed_date") and len(#renewed_date#) gt 0>
			<cfset sql = "#sql# AND upper(renewed_date) like '%#stripQuotes(ucase(renewed_date))#%'">
		</cfif>
		<cfif isdefined("exp_date") and  len(#exp_date#) gt 0>
			<cfset sql = "#sql# AND upper(exp_date) like '%#stripQuotes(ucase(exp_date))#%'">
		</cfif>
		<cfif isdefined("permit_id") and len(#permit_id#) gt 0>
			<cfset sql = "#sql# AND permit.permit_id = '#stripQuotes(permit_id)#'">
		</cfif>
		<cfif isdefined("permit_Num") and len(#permit_Num#) gt 0>
			<cfset sql = "#sql# AND permit_Num = '#escapeQuotes(permit_Num)#'">
		</cfif>
		<cfif  isdefined("permit_Type") and len(#permit_Type#) gt 0>
			<cfset sql = "#sql# AND permit_Type = '#escapeQuotes(permit_type)#'">
		</cfif>
		<cfif  isdefined("permit_remarks") and len(#permit_remarks#) gt 0>
			<cfset sql = "#sql# AND upper(permit_remarks) like '%#escapeQuotes(ucase(permit_remarks))#%'">
		</cfif>
		<cfset thisSQL  = "#sel# #frm# #sql# ORDER BY accn_number, trans.transaction_id ">
		<cfquery name="getAccns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			#preservesinglequotes(thisSQL)#
		</cfquery>
		<cfif getAccns.recordcount is 0>
			Nothing matched your search criteria.
			<cfabort>
		<cfelse>
			<cfquery name="c" dbtype="query">
				select count(distinct(transaction_id)) c from getAccns
			</cfquery>
			<cfquery name="specs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select count(*) c from cataloged_item where accn_id in (#valuelist(getAccns.transaction_id)#)
			</cfquery>
            <h2>
			<a href="/SpecimenResults.cfm?accn_trans_id=#valuelist(getAccns.transaction_id)#">
                View #specs.c# items in these #c.c# Accessions</a></h2>
		</cfif>

		<cfset i=1>
		<cfif #project_id# gt 0>
			<cfquery name="sfproj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select project_name from project where project_id=#project_id#
			</cfquery>
		</cfif>
	</cfoutput>

	<cfoutput query="getAccns" group="transaction_id">
		<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
			<cfif #project_id# gt 0>
				<a href="Project.cfm?Action=addTrans&project_id=#project_id#&transaction_id=#transaction_id#">
					Add Accn #accn_number#
				</a>
				 to Project <strong>#sfproj.project_name#</strong>
			<cfelse>
				<a href="/transactions/Accession.cfm?action=edit&transaction_id=#transaction_id#"><strong>#collection# #accn_number#</strong></a>
				<span style="font-size:smaller">(#accn_status#)</span>
			</cfif>
			<div style="padding-left:2em;">
				Received from: <strong>#recFromAgent#</strong>
				<br>Received date: <strong>#DateFormat(received_date, "yyyy-mm-dd")#</strong>
				<br>Nature of Material: <strong>#nature_of_material#</strong>
				<cfif len(#trans_remarks#) gt 0>
					<br>Remarks: <strong>#trans_remarks#</strong>
				</cfif>
				<cfif len(#estimated_count#) gt 0>
					<br>Estimated Count: <strong>#estimated_count#</strong>
				</cfif>
				<br>Entered by: <strong>#entAgent#</strong>
				<cfquery name="p" dbtype="query">
					select project_name,pid from getAccns where project_name is not null and
					 transaction_id=#transaction_id#
					group by project_name,pid
				</cfquery>
				<CFIF #P.RECORDCOUNT# gt 0>
					<br>Project(s):
					<div style="padding-left:2em">
						<cfloop query="p">
							<a href="/Project.cfm?Action=editProject&project_id=#p.pid#"><strong>#P.project_name#</strong></a><BR>
						</cfloop>
					</div>
				</CFIF>
			</div>
		</div>
		<cfset i=#i#+1>
	</cfoutput>
 </div>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "unlinkPermit">
	<cfoutput>
		<cfquery name="killPerm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			DELETE FROM permit_trans WHERE transaction_id = #transaction_id# and
			permit_id=#permit_id#
		</cfquery>
		<cflocation url="editAccn.cfm?Action=edit&transaction_id=#transaction_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "saveChanges">
	<cfoutput>
		<cftransaction>
			<!--- see if they're adding project --->
			<cfif isdefined("project_id") and project_id gt 0>
				<cfquery name="newProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO project_trans (
						project_id, transaction_id)
					VALUES (
						#project_id#,#transaction_id#)
				</cfquery>
			</cfif>
			<cfquery name="updateAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE accn SET
					ACCN_TYPE = '#accn_type#',
					ACCN_NUMber = '#ACCN_NUMber#',
					RECEIVED_DATE=to_date('#dateformat(rec_date,"yyyy-mm-dd")#'),
					ACCN_STATUS = '#accn_status#'
					<cfif len(estimated_count) gt 0>
						,estimated_count=#estimated_count#
					</cfif>
					WHERE transaction_id = #transaction_id#
			</cfquery>
			<cfquery name="updateTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE trans SET
			 		transaction_id = #transaction_id#
					,TRANSACTION_TYPE = 'accn',
					collection_id=#collection_id#
					<cfif len(#NATURE_OF_MATERIAL#) gt 0>
						,NATURE_OF_MATERIAL = '#NATURE_OF_MATERIAL#'
					</cfif>
					<cfif len(#REMARKS#) gt 0>
						,TRANS_REMARKS = '#REMARKS#'
					<cfelse>
						,TRANS_REMARKS = NULL
					</cfif>
				WHERE transaction_id = #transaction_id#
			</cfquery>
			<cfquery name="wutsThere" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select * from trans_agent where transaction_id=#transaction_id#
				and trans_agent_role !='entered by'
			</cfquery>
			<cfloop query="wutsThere">
				<!--- first, see if the deleted - if so, nothing else matters --->
				<cfif isdefined("del_agnt_#trans_agent_id#")>
					<cfquery name="wutsThere" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						delete from trans_agent where trans_agent_id=#trans_agent_id#
					</cfquery>
				<cfelse>
					<!--- update, just in case --->
					<cfset thisAgentId = evaluate("trans_agent_id_" & trans_agent_id)>
					<cfset thisRole = evaluate("trans_agent_role_" & trans_agent_id)>
					<cfquery name="wutsThere" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update trans_agent set
							agent_id = #thisAgentId#,
							trans_agent_role = '#thisRole#'
						where
							trans_agent_id=#trans_agent_id#
					</cfquery>
				</cfif>
			</cfloop>
			<cfif isdefined("new_trans_agent_id") and len(#new_trans_agent_id#) gt 0>
				<cfquery name="newAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into trans_agent (
						transaction_id,
						agent_id,
						trans_agent_role
					) values (
						#transaction_id#,
						#new_trans_agent_id#,
						'#new_trans_agent_role#'
					)
				</cfquery>
			</cfif>
		</cftransaction>
	<cflocation url="editAccn.cfm?Action=edit&transaction_id=#transaction_id#" addtoken="false">
  </cfoutput>
</cfif>
<cfinclude template="includes/_footer.cfm">
