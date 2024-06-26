<cfinclude template="/includes/alwaysInclude.cfm">
<script language="javascript" type="text/javascript">

	jQuery(document).ready(function() {
		jQuery("input[id^='determined_date_']").each(function(){
			$("#" + this.id).datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "images/cal_icon.png",
			buttonImageOnly: true });
		});

		$("#mammgrid_determined_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "images/cal_icon.png",
			buttonImageOnly: true });
		$("input[id^='attribute_id_']").each(function(){
			populateAttribute($("#" + this.id).val());
		});
        $("#determined_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
			buttonImage: "images/cal_icon.png",
			buttonImageOnly: true });
            $(".ui-datepicker-trigger").css("margin-left","1px");
	});

	function deleteAttribute(id){
		var d='<input type="hidden" id="deleted_attribute_type_' + id + '" name="deleted_attribute_type_' + id + '">';
		$("#atttype_" + id).append(d);
		$("#deleted_attribute_type_" + id).val($("#attribute_type_" + id).val());
		$("#attribute_type_" + id).val('pending delete');
		var d='<input type="button" id="rec_' + id + '"	value="undelete" class="savBtn" onclick="undeleteAttribute(' + id + ');">';
		$("#attdel_" + id).append(d);
		$("#del_" + id).remove();

		$("#attribute_value_" + id).toggle();
		$("#attribute_units_" + id).toggle();
		$("#attribute_remark_" + id).toggle();
		$("#determined_date_" + id).toggle();
		$("#determination_method_" + id).toggle();
		$("#agent_name_" + id).toggle();
	}




	function undeleteAttribute(id){
		$("#attribute_type_" + id).val($("#deleted_attribute_type_" + id).val());
		$("#deleted_attribute_type_" + id).remove();
		var d='<input type="button" id="del_' + id + '"	value="Delete" class="delBtn" onclick="deleteAttribute(\'' + id + '\');">';
		$("#attdel_" + id).append(d);
		$("#rec_" + id).remove();

		$("#attribute_value_" + id).toggle();
		$("#attribute_units_" + id).toggle();
		$("#attribute_remark_" + id).toggle();
		$("#determined_date_" + id).toggle();
		$("#determination_method_" + id).toggle();
		$("#agent_name_" + id).toggle();
	}
	function populateAttribute(aid) {
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "getAttCodeTbl",
				attribute : $("#attribute_type_" + aid).val(),
				collection_cde : $("#collection_cde").val(),
				element : aid,
				returnformat : "json",
				queryformat : 'column'
			},
			success_populateAttribute
		);
	}
	function success_populateAttribute (r) {
		var result=r.DATA;
		var resType=result.V[0];
		var aid=result.V[1];
		aid='_' + aid;
		$("#attribute_value" + aid).remove();
		$("#attribute_units" + aid).remove();
		if (resType == 'value') {
			var d = '<select name="attribute_value' + aid + '" id="attribute_value' + aid + '">';
			d+='<option value=""></option>';
			for (i=2;i<result.V.length;i++) {
				d+='<option value="' + result.V[i] + '">' + result.V[i] + '</option>';
			}
			d+='</select>';
			$("#_attribute_value" + aid).append(d);
			$("#attribute_value" + aid).val($("#val" + aid).val());
		} else if (resType == 'units') {
			var d = '<select name="attribute_units' + aid + '" id="attribute_units' + aid + '">';
			d+='<option value=""></option>';
			for (i=2;i<result.V.length;i++) {
				d+='<option value="' + result.V[i] + '">' + result.V[i] + '</option>';
			}
			d+='</select>';
			$("#_attribute_units" + aid).append(d);
			$("#attribute_units" + aid).val($("#unit" + aid).val());
			var t='<input type="text" name="attribute_value' + aid + '" id="attribute_value' + aid + '">';
			$("#_attribute_value" + aid).append(t);
			$("#attribute_value" + aid).val($("#val" + aid).val());
		} else {
			var t='<input type="text" name="attribute_value' + aid + '" id="attribute_value' + aid + '">';
			$("#_attribute_value" + aid).append(t);
			$("#attribute_value" + aid).val($("#val" + aid).val());
		}
	}
</script>
<cfif action is "nothing">
    <div class="basic_wide_box">
	<h3 style="margin-top: 2em;">Edit Individual Attributes
        <span class="infoLInk" onClick="windowOpener('/info/attributeHelpPick.cfm','','width=600,height=600, resizable,scrollbars');">Help</span></h3>
	<cfoutput>
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				COLL_OBJECT_REMARKS,
				habitat,
				associated_species,
				flags,
				cat_num,
				collection.collection_cde,
				institution_acronym,
				cataloged_item.collection_object_id collection_object_id,
				ATTRIBUTE_ID,
				agent_name,
				determined_by_agent_id,
				ATTRIBUTE_TYPE,
				ATTRIBUTE_VALUE,
				attribute_units,
				ATTRIBUTE_REMARK,
				DETERMINED_DATE,
				DETERMINATION_METHOD
			FROM
				cataloged_item,
				collection,
				attributes,
				preferred_agent_name,
				coll_object,
				coll_object_remark
			WHERE
				cataloged_item.collection_id = collection.collection_id AND
				cataloged_item.collection_object_id = attributes.collection_object_id (+) AND
				attributes.determined_by_agent_id = preferred_agent_name.agent_id (+) AND
				cataloged_item.collection_object_id = coll_object.collection_object_id AND
				cataloged_item.collection_object_id = coll_object_remark.collection_object_id (+) AND
				cataloged_item.collection_object_id = #collection_object_id#
		</cfquery>

		<cfquery name="ctflags" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT flags from ctflags
		</cfquery>
		<cfquery name="indiv" dbtype="query">
			select
				CAT_NUM,
				collection_cde,
				COLL_OBJECT_REMARKS,
				habitat,
				associated_species,
				flags
			FROM
				raw
			group by
				CAT_NUM,
				collection_cde,
				COLL_OBJECT_REMARKS,
				habitat,
				associated_species,
				flags
		</cfquery>
		<cfquery name="ctattribute_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT attribute_type FROM ctattribute_type where
			collection_cde='#indiv.collection_cde#'
		</cfquery>
		<cfquery name="atts" dbtype="query">
			select
				collection_object_id,
				ATTRIBUTE_ID,
				agent_name,
				determined_by_agent_id,
				ATTRIBUTE_TYPE,
				ATTRIBUTE_VALUE,
				attribute_units,
				ATTRIBUTE_REMARK,
				DETERMINED_DATE,
				DETERMINATION_METHOD
			from
				raw
			where
				ATTRIBUTE_TYPE is not null
			group by
				collection_object_id,
				ATTRIBUTE_ID,
				agent_name,
				determined_by_agent_id,
				ATTRIBUTE_TYPE,
				ATTRIBUTE_VALUE,
				attribute_units,
				ATTRIBUTE_REMARK,
				DETERMINED_DATE,
				DETERMINATION_METHOD
		</cfquery>
		<cfquery name="ctdisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select coll_obj_disposition from ctcoll_obj_disp
		</cfquery>
		<cfquery name="ctcoll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select collection_cde from ctcollection_cde
		</cfquery>
		<form name="details" method="post" action="editBiolIndiv.cfm">
			<input type="hidden" value="save" name="action">
			<input type="hidden" value="#collection_object_id#" name="collection_object_id">
			<input type="hidden" value="#indiv.collection_cde#" name="collection_cde" id="collection_cde">
    		<table>
      			<tr>
					<td>
						<label for="flags">Missing</label>
						<select name="flags" id="flags" size="1">
							<option value=""></option>
							<cfloop query="ctflags">
								<option <cfif indiv.flags is ctflags.flags> selected="selected" </cfif>value="#flags#">#flags#</option>
							</cfloop>
						</select>
					</td>
				</tr>
			</table>
			<label for="coll_object_remarks">Specimen Remarks</label>
			<textarea name="coll_object_remarks" id="coll_object_remarks" cols="80" rows="2">#indiv.coll_object_remarks#</textarea>
			<label for="habitat">Microhabitat</label>
			<textarea name="habitat" id="habitat" cols="80" rows="2">#indiv.habitat#</textarea>
			<label for="habitat">Associated Species</label>
			<textarea name="associated_species" id="associated_species" cols="80" rows="2">#indiv.associated_species#</textarea>
			<cfset i=1>
			<table border cellpadding="2">
				<tr>
					<td>Attribute</td>
					<td>Value</td>
					<td>Units</td>
					<td>Remarks</td>
					<td>Det. Date</td>
					<td>Det. Meth</td>
					<td>Determiner</td>
					<td>&nbsp;</td>
				</tr>
				<input type="hidden" name="number_of_attributes" id="number_of_attributes" value="#atts.recordcount#">
				<cfloop query="atts">
					<input type="hidden" name="attribute_id_#i#" id="attribute_id_#i#" value="#attribute_id#">
					<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
						<td id="atttype_#attribute_id#">
							<input type="text" name="attribute_type_#attribute_id#" id="attribute_type_#attribute_id#" value="#attribute_type#" readonly="yes" class="readClr">
						</td>
						<td id="_attribute_value_#attribute_id#">
							<input type="hidden" name="val_#attribute_id#" id="val_#attribute_id#" value="#stripQuotes(attribute_value)#">
						</td>
						<td id="_attribute_units_#attribute_id#">
							<input type="hidden" name="unit_#attribute_id#" id="unit_#attribute_id#" value="#attribute_units#">
						</td>
						<td id="_remarks_#attribute_id#">
							<input type="text" name="attribute_remark_#attribute_id#" id="attribute_remark_#attribute_id#" value="#stripQuotes(attribute_remark)#">
						</td>
						<td id="_determined_date_#attribute_id#">
							<input type="text" name="determined_date_#attribute_id#" id="determined_date_#attribute_id#"
								value="#dateformat(determined_date,'yyyy-mm-dd')#" size="12">
						</td>
						<td id="_determination_method_#attribute_id#">
							<input type="text" name="determination_method_#attribute_id#" id="determination_method_#attribute_id#" value="#determination_method#">
						</td>
						<td id="_agent_name_#attribute_id#">
							<input type="hidden" name="determined_by_agent_id_#attribute_id#" id="determined_by_agent_id_#attribute_id#"
								value="#determined_by_agent_id#">
							<input type="text" name="agent_name_#attribute_id#" id="agent_name_#attribute_id#" class="reqdClr" value="#agent_name#"
		 						onchange="getAgent('determined_by_agent_id_#attribute_id#',this.id,'details',this.value); return false;"
		  						onKeyPress="return noenter(event);">
						</td>
						<td id="attdel_#attribute_id#">
							<input type="button" id="del_#attribute_id#" value="Delete" class="delBtn"
								onclick="deleteAttribute('#attribute_id#');">
						</td>
					</tr>
					<cfset i=i+1>
				</cfloop>
				<tr class="newRec">
					<td>
						<select name="attribute_type_new" id="attribute_type_new" size="1" onChange="populateAttribute('new');">
							<option value="">Create New Attribute</option>
							<cfloop query="ctattribute_type">
								<option value="#ctattribute_type.attribute_type#">#ctattribute_type.attribute_type#</option>
							</cfloop>
						</select>
					</td>
					<td id="_attribute_value_new">
					<td id="_attribute_units_new">
					<td id="remarks_new">
						<input type="text" name="attribute_remark" id="attribute_remark">
					</td>
					<td id="determined_date_new">
						<input type="text" name="determined_date" id="determined_date" size="12">
					</td>
					<td id="determination_method_new">
						<input type="text" name="determination_method" id="determination_method">
					</td>
					<td id="agent_name_new">
						<input type="hidden" name="determined_by_agent_id" id="determined_by_agent_id">
						<input type="text" name="agent_name" id="agent_name" class="reqdClr"
	 						onchange="getAgent('determined_by_agent_id',this.id,'details',this.value); return false;"
	  						onKeyPress="return noenter(event);">
					</td>
					<td>

					</td>
				</tr>
			</table>
			<cfif indiv.collection_cde is "Mamm">
				<cfquery name="ctlength_units" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select length_units from ctlength_units order by length_units
				</cfquery>
				<cfquery name="ctweight_units" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select weight_units from ctweight_units order by weight_units
				</cfquery>
				<label for="mammatttab">Existing values will NOT show up in this grid; add mammal attributes only.</label>
				<table id="mammatttab" class="newRec">
					<tr>
						<td>
							<label for="total_length">Total</label>
							<input type="text" name="total_length" size="4">
							<select name="total_length_units" size="1">
								<cfloop query="ctlength_units">
									<option <cfif length_units is "mm"> selected="selected" </cfif>
										value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="tail_length">Tail</label>
							<input type="text" name="tail_length" size="4">
							<select name="tail_length_units" size="1">
								<cfloop query="ctlength_units">
									<option <cfif length_units is "mm"> selected="selected" </cfif>
										value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="hind_foot_with_claw">HF(c)</label>
							<input type="text" name="hind_foot_with_claw" size="4">
							<select name="hind_foot_with_claw_units" size="1">
								<cfloop query="ctlength_units">
									<option <cfif length_units is "mm"> selected="selected" </cfif>
										value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="ear_from_notch">EFN</label>
							<input type="text" name="ear_from_notch" size="4">
							<select name="ear_from_notch_units" size="1">
								<cfloop query="ctlength_units">
									<option <cfif length_units is "mm"> selected="selected" </cfif>
										value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="weight">WT</label>
							<input type="text" name="weight" size="4">
							<select name="weight_units" size="1">
								<cfloop query="ctweight_units">
									<option <cfif weight_units is "g"> selected="selected" </cfif>
										value="#ctweight_units.weight_units#">#ctweight_units.weight_units#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="determined_date">Date</label>
							<input type="text" name="determined_date" id="mammgrid_determined_date" size="10">
						</td>
						<td>
							<label for="mammgrid_detagentid">Determiner</label>
							<input type="hidden" name="mammgrid_detagentid">
							<input type="text" name="mammgrid_determiner" class="reqdClr"
								onchange="getAgent('mammgrid_detagentid',this.name,'details',this.value); return false;">
						</td>
					</tr>
				</table>
			</cfif>
			<br>
			<div align="center">
				<input type="submit" value="save all" class="savBtn">
			</div>
		</form>
	</cfoutput>
</div>
</cfif>
<!------------------------------------------------------------------------------>
<cfif action is "save">
	<cfoutput>
		<cftransaction>
			<cfloop from="1" to="#number_Of_Attributes#" index="n">
				<cfset thisAttributeId = evaluate("attribute_id_" & n)>
				<cfset thisAttributeType = evaluate("attribute_type_" & thisAttributeId)>
				<cftry>
					<cfset thisAttributeUnits = evaluate("attribute_units_" & thisAttributeId)>
					<cfcatch>
						<cfset thisAttributeUnits = ''>
					</cfcatch>
				</cftry>
				<cftry>
					<cfset thisAttributeValue = evaluate("attribute_value_" & thisAttributeId)>
					<cfcatch>
						<cfset thisAttributeValue = ''>
					</cfcatch>
				</cftry>
				<cfset thisAttributeRemark = evaluate("attribute_remark_" & thisAttributeId)>
				<cfset thisDeterminedDate = evaluate("determined_date_" & thisAttributeId)>
				<cfset thisDeterminationMethod = evaluate("determination_method_" & thisAttributeId)>
				<cfset thisDeterminedByAgentId = evaluate("determined_by_agent_id_" & thisAttributeId)>
				<cfif thisAttributeType is "pending delete">
					<cfquery name="killAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						delete from attributes where attribute_id=#thisAttributeId#
					</cfquery>
				<cfelse>
					<cfquery name="upAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE attributes SET
							attribute_type='#thisAttributeType#',
							DETERMINED_BY_AGENT_ID = #thisDeterminedByAgentId#,
							ATTRIBUTE_VALUE='#escapeQuotes(thisAttributeValue)#',
							ATTRIBUTE_UNITS='#thisAttributeUnits#',
							ATTRIBUTE_REMARK='#escapeQuotes(thisAttributeRemark)#',
							DETERMINED_DATE='#dateformat(thisDeterminedDate,"yyyy-mm-dd")#',
							DETERMINATION_METHOD='#thisDeterminationMethod#'
						WHERE
							attribute_id=#thisAttributeId#
					</cfquery>
				</cfif>
			</cfloop>
			<!---- mammal grid ----->
			<cfif isdefined("total_length")>
				<cfif len(total_length) gt 0>
					<cfquery name="total_length" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO attributes (
							ATTRIBUTE_ID
							,COLLECTION_OBJECT_ID
							,DETERMINED_BY_AGENT_ID
							,ATTRIBUTE_TYPE
							,ATTRIBUTE_VALUE
							,ATTRIBUTE_UNITS
							,DETERMINED_DATE
							 )
						VALUES (
							sq_attribute_id.nextval
							,#collection_object_id#
							,#mammgrid_detagentid#
							,'total length'
							,'#total_length#'
							,'#total_length_units#'
							,'#dateformat(DETERMINED_DATE,"yyyy-mm-dd")#')
					</cfquery>
				</cfif>
				<cfif len(tail_length) gt 0>
					<cfquery name="tail_length" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO attributes (
							ATTRIBUTE_ID
							,COLLECTION_OBJECT_ID
							,DETERMINED_BY_AGENT_ID
							,ATTRIBUTE_TYPE
							,ATTRIBUTE_VALUE
							,ATTRIBUTE_UNITS
							,DETERMINED_DATE
							 )
						VALUES (
							sq_attribute_id.nextval
							,#collection_object_id#
							,#mammgrid_detagentid#
							,'tail length'
							,'#tail_length#'
							,'#tail_length_units#'
							,'#dateformat(DETERMINED_DATE,"yyyy-mm-dd")#')
					</cfquery>
				</cfif>
				<cfif len(hind_foot_with_claw) gt 0>
					<cfquery name="hind_foot_with_claw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO attributes (
							ATTRIBUTE_ID
							,COLLECTION_OBJECT_ID
							,DETERMINED_BY_AGENT_ID
							,ATTRIBUTE_TYPE
							,ATTRIBUTE_VALUE
							,ATTRIBUTE_UNITS
							,DETERMINED_DATE
							 )
						VALUES (
							sq_attribute_id.nextval,
							#collection_object_id#
							,#mammgrid_detagentid#
							,'hind foot with claw'
							,'#hind_foot_with_claw#'
							,'#hind_foot_with_claw_units#'
							,'#dateformat(DETERMINED_DATE,"yyyy-mm-dd")#')
					</cfquery>
				</cfif>
				<cfif len(ear_from_notch) gt 0>
					<cfquery name="ear_from_notch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO attributes (
							ATTRIBUTE_ID
							,COLLECTION_OBJECT_ID
							,DETERMINED_BY_AGENT_ID
							,ATTRIBUTE_TYPE
							,ATTRIBUTE_VALUE
							,ATTRIBUTE_UNITS
							,DETERMINED_DATE
							 )
						VALUES (
							sq_attribute_id.nextval,
							#collection_object_id#
							,#mammgrid_detagentid#
							,'ear from notch'
							,'#ear_from_notch#'
							,'#ear_from_notch_units#'
							,'#dateformat(DETERMINED_DATE,"yyyy-mm-dd")#')
					</cfquery>
				</cfif>
				<cfif len(weight) gt 0>
					<cfquery name="weight" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO attributes (
							ATTRIBUTE_ID
							,COLLECTION_OBJECT_ID
							,DETERMINED_BY_AGENT_ID
							,ATTRIBUTE_TYPE
							,ATTRIBUTE_VALUE
							,ATTRIBUTE_UNITS
							,DETERMINED_DATE
							 )
						VALUES (
							sq_attribute_id.nextval
							,#collection_object_id#
							,#mammgrid_detagentid#
							,'weight'
							,'#weight#'
							,'#weight_units#'
							,'#dateformat(DETERMINED_DATE,"yyyy-mm-dd")#')
					</cfquery>
				</cfif>
			</cfif>
			<!--- new attribute --->
			<cfif len(attribute_type_new) gt 0>
				<cfif not isdefined("attribute_units_new")>
					<cfset attribute_units_new=''>
				</cfif>
				<cfquery name="newAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					INSERT INTO attributes (
						ATTRIBUTE_ID
						,COLLECTION_OBJECT_ID
						,DETERMINED_BY_AGENT_ID
						,ATTRIBUTE_TYPE
						,ATTRIBUTE_VALUE
						,ATTRIBUTE_UNITS
						,ATTRIBUTE_REMARK
						,DETERMINED_DATE
						,DETERMINATION_METHOD
					) VALUES (
						sq_attribute_id.nextval
						,#collection_object_id#
						,#determined_by_agent_id#
						,'#attribute_type_new#'
						,'#escapeQuotes(attribute_value_new)#'
						,'#attribute_units_new#'
						,'#escapeQuotes(ATTRIBUTE_REMARK)#'
						,'#dateformat(DETERMINED_DATE,"yyyy-mm-dd")#'
						,'#DETERMINATION_METHOD#'
					)
				</cfquery>
			</cfif>
			<cfquery name="upCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE coll_object SET
					last_edited_person_id = #session.myAgentId#
					,last_edit_date = sysdate
					,flags='#flags#'
				WHERE collection_object_id = #collection_object_id#
			</cfquery>
			<cfquery name="isCORem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select collection_object_id from coll_object_remark where
				collection_object_id = #collection_object_id#
			</cfquery>
			<cfif len(isCORem.collection_object_id) gt 0>
				<cfquery name="upCoRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE coll_object_remark SET
						collection_object_id = #collection_object_id#
						,coll_object_remarks = '#coll_object_remarks#'
						,habitat = '#habitat#'
						,associated_species = '#associated_species#'
					WHERE
						collection_object_id = #collection_object_id#
				</cfquery>
			<cfelse>
				<cfif len(coll_object_remarks) gt 0 OR len(habitat) gt 0 or len(associated_species) gt 0>
					<cfquery name="newBIRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO coll_object_remark (
							collection_object_id
							,coll_object_remarks
							,habitat
							,associated_species
						 ) VALUES (
							#collection_object_id#
							,'#escapeQuotes(coll_object_remarks)#'
							,'#escapeQuotes(habitat)#'
							,'#escapeQuotes(associated_species)#'
						)
					</cfquery>
				</cfif>
			</cfif>
		</cftransaction>
		<cflocation url="editBiolIndiv.cfm?collection_object_id=#collection_object_id#" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------>
<cf_customizeIFrame>
