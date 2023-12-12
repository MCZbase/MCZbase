<cfoutput>
<cfset transaction_id=caller.transaction_id>
<!---  Custom Tags for named queries used in reports for transactions --->
<!---  getLoanMCZ - information for loan invoice headers.   --->
<cfquery name="caller.getLoanMCZ" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
      SELECT * from (
      SELECT distinct
		replace(to_char(trans_date, 'dd-Month-yyyy'),' ','') as trans_date,
			    concattransagent(trans.transaction_id, 'in-house authorized by') authAgentName,
			    concattransagent(trans.transaction_id, 'received by')   recAgentName,
			    concattransagent(trans.transaction_id, 'for use by')   foruse_by_name,
			    concattransagent(trans.transaction_id, 'in-house contact')   internalContactName,
			    concattransagent(trans.transaction_id, 'additional outside contact')   additionalContactNames,
			    concattransagent(trans.transaction_id, 'additional in-house contact')   addInHouseContactNames,
			    concattransagent(trans.transaction_id, 'recipient institution')  recipientInstitutionName,
			    outside_contact.agent_name outside_contact_name,
			    inside_contact.agent_name inside_contact_name,
				outside_addr.job_title  outside_contact_title,
				inside_addr.job_title  inside_contact_title,
				get_address(inside_trans_agent.agent_id) inside_address,
				get_address(outside_trans_agent.agent_id) outside_address,
				inside_email.address inside_email_address,
				outside_email.address outside_email_address,
				inside_phone.address inside_phone_number,
				outside_phone.address outside_phone_number,
				MCZBASE.get_eaddresses(trans.transaction_id,'additional in-house contact') addInHouseContactPhEmail,
               	replace(to_char(return_due_date,'dd-Month-yyyy'),' ','') as return_due_date,
                replace(nature_of_material,'&','&amp;') nature_of_material,
                replace(replace(loan_instructions,'&','&amp;'), chr(32)||chr(28) ,'"') loan_instructions,
                replace(loan_description,'&','&amp;') loan_description,
                loan_type,
                loan_number,
                loan_status,
                insurance_value,
                insurance_maintained_by,
				replace(to_char(shipped_date,'dd-Month-yyyy'),' ','') as shipped_date,
				shipped_carrier_method,
				shipment.no_of_packages as no_of_packages,
				ship_to_addr.formatted_addr  shipped_to_address   ,
				ship_from_addr.formatted_addr  shipped_from_address  ,
				processed_by.agent_name processed_by_name,
				sponsor_name.agent_name project_sponsor_name,
				acknowledgement,
				Decode(substr(loan_number, instr(loan_number, '-',1, 2)+1),
				'Herp', 'Herpetology Collection',
				'Mamm', 'Mammalogy Collection',
				'IZ', 'Invertebrate Zoology',
				'Mala', 'Malacology Collection',
				'VP','Vertebrate Paleontology Collection',
				'SC','Special Collections',
				'MCZ','MCZ Collections',
				'IP','Invertebrate Paleontology Collection',
				'Ich','Ichthyology Collection',
				'Orn','Ornithology Collection',
				'Cryo','Cryogenic Collection',
				'Ent','Entomology Collection',
				'[Unable to identify collection from loan number]' || substr(loan_number, instr(loan_number, '-',1, 2)+1)
				) as collection,
				num_specimens, num_lots,
                shipment.shipment_id,
                shipment.print_flag,
                shipment.carriers_tracking_number
        FROM
                loan,
				trans,
				loan_counts,
				trans_agent inside_trans_agent,
				trans_agent outside_trans_agent,
				preferred_agent_name outside_contact,
				preferred_agent_name inside_contact,
				(select * from electronic_address where address_type ='email') inside_email,
				(select * from electronic_address where address_type ='email') outside_email,
				(select * from electronic_address where address_type ='work phone number') inside_phone,
				(select * from electronic_address where address_type ='work phone number') outside_phone,
				(select * from addr where addr_type='Correspondence') outside_addr,
				(select * from addr where addr_type='Correspondence') inside_addr,
				shipment,
				addr ship_to_addr,
				addr ship_from_addr,
				preferred_agent_name processed_by,
				project_trans,
				project_sponsor,
				agent_name sponsor_name
        WHERE
                loan.transaction_id = trans.transaction_id and
				loan.transaction_id = loan_counts.transaction_id (+) and
				trans.transaction_id = inside_trans_agent.transaction_id and
				inside_trans_agent.agent_id = inside_contact.agent_id and
				inside_trans_agent.trans_agent_role='in-house contact' and
				inside_trans_agent.agent_id = inside_email.agent_id (+) and
				inside_trans_agent.agent_id = inside_addr.agent_id (+) and
				inside_trans_agent.agent_id = inside_phone.agent_id (+) and
				trans.transaction_id = outside_trans_agent.transaction_id and
				outside_trans_agent.agent_id = outside_contact.agent_id (+) and
				outside_trans_agent.trans_agent_role='received by' and
				outside_trans_agent.agent_id = outside_email.agent_id (+) and
				outside_trans_agent.agent_id = outside_phone.agent_id (+) and
				outside_trans_agent.agent_id = outside_addr.agent_id (+) and
				loan.transaction_id = shipment.transaction_id (+) and
				shipment.SHIPPED_TO_ADDR_ID	= ship_to_addr.addr_id (+) and
				shipment.SHIPPED_FROM_ADDR_ID	= ship_from_addr.addr_id (+) and
				shipment.PACKED_BY_AGENT_ID = 	processed_by.agent_id (+) and
				trans.transaction_id = 	project_trans.transaction_id (+) and
				project_trans.project_id =	project_sponsor.project_id (+) and
				project_sponsor.agent_name_id = sponsor_name.agent_name_id (+) and
				loan.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
        --- use the shipment with the print flag set, failover to print first entered shipment.
        order by shipment.print_flag desc, shipment.shipment_id asc
        ) where rownum < 2
</cfquery>
<!---  getLoanItemsMCZ - information for loan item invoices.   --->
<cfquery name="caller.getLoanItemsMCZ" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select
		cat_num, cataloged_item.collection_cde, collection.institution_acronym,
                MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id) as type_status,

	        decode(
	           MCZBASE.GET_TYPESTATUSNAME(cataloged_item.collection_object_id,
	               MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id)),
	           MCZBASE.GET_SCIENTIFIC_NAME(cataloged_item.collection_object_id),
	           '',
	           decode(MCZBASE.GET_TYPESTATUSNAME(cataloged_item.collection_object_id,
	                     MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id)),'','',
	                ' of ' || MCZBASE.GET_TYPESTATUSNAME(cataloged_item.collection_object_id,
	                            MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id))
	           )
	        ) as typestatusname,

		cataloged_item.cat_num_prefix,
		/*   catalog_number,*/
                cat_num_integer,
		cataloged_item.collection_object_id,
		collection.collection,
		concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
		concatattributevalue(cataloged_item.collection_object_id,'sex') as sex,
		decode (sampled_from_obj_id,
			null,part_name,
			part_name || ' sample') part_name,
		 part_modifier,
		 preserve_method,
		 lot_count,
		 condition,
		 item_instructions,
		to_char(reconciled_date,'yyyy-mm-dd') reconciled_date,
		 HTF.escape_sc(loan_item_remarks) loan_item_remarks,
		 coll_obj_disposition,
		 scientific_name,
		 Encumbrance,
		 agent_name,
		 loan_number,
         concattransagent(loan.transaction_id, 'received by')  recAgentName,
		 HTF.escape_sc(spec_locality) spec_locality,
		 higher_geog,
                 GET_CHRONOSTRATIGRAPHY(locality.locality_id) chronostrat,
                 GET_LITHOSTRATIGRAPHY(locality.locality_id) lithostrat,
		 orig_lat_long_units,
		 lat_deg,
		 lat_min,
		 lat_sec,
		 long_deg,
		 long_min,
		 long_sec,
		 dec_lat_min,
		 dec_long_min,
		 lat_dir,
		 long_dir,
		 dec_lat,
		 dec_long,
		 max_error_distance,
		 max_error_units,
		 decode(orig_lat_long_units,
				'decimal degrees',to_char(dec_lat) || '&deg; ',
				'deg. min. sec.', to_char(lat_deg) || '&deg; ' || to_char(lat_min) || '&acute; ' || to_char(lat_sec) || '&acute;&acute; ' || lat_dir,
				'degrees dec. minutes', to_char(lat_deg) || '&deg; ' || to_char(dec_lat_min) || '&acute; ' || lat_dir
			)  VerbatimLatitude,
			decode(orig_lat_long_units,
				'decimal degrees',to_char(dec_long) || '&deg;',
				'deg. min. sec.', to_char(long_deg) || '&deg; ' || to_char(long_min) || '&acute; ' || to_char(long_sec) || '&acute;&acute; ' || long_dir,
				'degrees dec. minutes', to_char(long_deg) || '&deg; ' || to_char(dec_long_min) || '&acute; ' || long_dir
			)  VerbatimLongitude,
		HTF.escape_sc(concatColl(cataloged_item.collection_object_id)) as collectors
	 from
		loan_item,
		loan,
		specimen_part,
		coll_object,
		cataloged_item,
		coll_object_encumbrance,
		encumbrance,
		agent_name,
		identification,
		collecting_event,
		locality,
		geog_auth_rec,
		accepted_lat_long,
		collection
	WHERE
		loan_item.collection_object_id = specimen_part.collection_object_id AND
		loan.transaction_id = loan_item.transaction_id AND
		specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
		specimen_part.collection_object_id = coll_object.collection_object_id AND
		coll_object.collection_object_id = coll_object_encumbrance.collection_object_id (+) and
		coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id (+) AND
		encumbrance.encumbering_agent_id = agent_name.agent_id (+) AND
		cataloged_item.collection_object_id = identification.collection_object_id AND
		identification.accepted_id_fg = 1 AND
		cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
		collecting_event.locality_id = locality.locality_id AND
		locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id AND
		locality.locality_id = accepted_lat_long.locality_id (+) AND
		cataloged_item.collection_id = collection.collection_id AND
		loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
</cfquery>
<!--- Sort order is now configurable and handled by sort parameter of Reports/report_printer.cfm.  --->
<!--- /*ORDER BY catalog_number_prefix, catalog_number*/ --->
</cfoutput>
<!---  getDeaccMCZ - information for deaccession invoice headers.   --->
<cfquery name="caller.getDeaccMCZ" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
      SELECT * from (
      SELECT distinct
		replace(to_char(trans_date, 'dd-Month-yyyy'),' ','') as trans_date,
			    concattransagent(trans.transaction_id, 'in-house authorized by') authAgentName,
			    concattransagent(trans.transaction_id, 'received by')   recAgentName,
			    concattransagent(trans.transaction_id, 'for use by')   foruse_by_name,
			    concattransagent(trans.transaction_id, 'in-house contact')   internalContactName,
			    concattransagent(trans.transaction_id, 'additional outside contact')   additionalContactNames,
			    concattransagent(trans.transaction_id, 'additional in-house contact')   addInHouseContactNames,
			    concattransagent(trans.transaction_id, 'recipient institution')  recipientInstitutionName,
			    outside_contact.agent_name outside_contact_name,
			    inside_contact.agent_name inside_contact_name,
				outside_addr.job_title  outside_contact_title,
				inside_addr.job_title  inside_contact_title,
				get_address(inside_trans_agent.agent_id) inside_address,
				get_address(outside_trans_agent.agent_id) outside_address,
				inside_email.address inside_email_address,
				outside_email.address outside_email_address,
				inside_phone.address inside_phone_number,
				outside_phone.address outside_phone_number,
				MCZBASE.get_eaddresses(trans.transaction_id,'additional in-house contact') addInHouseContactPhEmail,
                replace(nature_of_material,'&','&amp;') nature_of_material,
                replace(replace(deacc_reason,'&','&amp;'), chr(32)||chr(28) ,'"') deacc_reason,
                replace(deacc_description,'&','&amp;') deacc_description,
                deacc_type,
            	decode(deacc_type,'gift','specimens','transfer','objects','material') object_specimen,
                deacc_number,
                deacc_status,
				value,
				replace(to_char(shipped_date,'dd-Month-yyyy'),' ','') as shipped_date,
				shipped_carrier_method,
				shipment.no_of_packages as no_of_packages,
				ship_to_addr.formatted_addr  shipped_to_address   ,
				ship_from_addr.formatted_addr  shipped_from_address  ,
				processed_by.agent_name processed_by_name,
				sponsor_name.agent_name project_sponsor_name,
				acknowledgement,
				collection.collection,
                shipment.shipment_id,
                shipment.print_flag,
                shipment.carriers_tracking_number
        FROM
                deaccession,
				trans,
				trans_agent inside_trans_agent,
				trans_agent outside_trans_agent,
				preferred_agent_name outside_contact,
				preferred_agent_name inside_contact,
				(select * from electronic_address where address_type ='email') inside_email,
				(select * from electronic_address where address_type ='email') outside_email,
				(select * from electronic_address where address_type ='work phone number') inside_phone,
				(select * from electronic_address where address_type ='work phone number') outside_phone,
				(select * from addr where addr_type='Correspondence') outside_addr,
				(select * from addr where addr_type='Correspondence') inside_addr,
				shipment,
				addr ship_to_addr,
				addr ship_from_addr,
				preferred_agent_name processed_by,
				project_trans,
				project_sponsor,
				agent_name sponsor_name,
				collection
        WHERE
                deaccession.transaction_id = trans.transaction_id and
				trans.transaction_id = inside_trans_agent.transaction_id and
				inside_trans_agent.agent_id = inside_contact.agent_id and
				inside_trans_agent.trans_agent_role='in-house contact' and
				inside_trans_agent.agent_id = inside_email.agent_id (+) and
				inside_trans_agent.agent_id = inside_addr.agent_id (+) and
				inside_trans_agent.agent_id = inside_phone.agent_id (+) and
				trans.transaction_id = outside_trans_agent.transaction_id and
				outside_trans_agent.agent_id = outside_contact.agent_id (+) and
				outside_trans_agent.trans_agent_role='received by' and
				outside_trans_agent.agent_id = outside_email.agent_id (+) and
				outside_trans_agent.agent_id = outside_phone.agent_id (+) and
				outside_trans_agent.agent_id = outside_addr.agent_id (+) and
				deaccession.transaction_id = shipment.transaction_id (+) and
				shipment.SHIPPED_TO_ADDR_ID	= ship_to_addr.addr_id (+) and
				shipment.SHIPPED_FROM_ADDR_ID	= ship_from_addr.addr_id (+) and
				shipment.PACKED_BY_AGENT_ID = 	processed_by.agent_id (+) and
				trans.transaction_id = 	project_trans.transaction_id (+) and
				project_trans.project_id =	project_sponsor.project_id (+) and
				project_sponsor.agent_name_id = sponsor_name.agent_name_id (+) and
				trans.collection_id = collection.collection_id AND
				deaccession.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
        ---  get the shipment with the print flag set, failover to the first entered shipment
        ---    (by shipment_id, assuming that is sequential) is the outgoing shipment
        order by shipment.print_flag desc, shipment.shipment_id asc
        ) where rownum < 2
</cfquery>
<!---  getDeaccItemsMCZ - information for deaccession item invoices.   --->
<cfquery name="caller.getDeaccItemsMCZ" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
       SELECT
		cat_num, cataloged_item.collection_cde, collection.institution_acronym,
                MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id) as type_status,

	        decode(
	           MCZBASE.GET_TYPESTATUSNAME(cataloged_item.collection_object_id,
	               MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id)),
	           MCZBASE.GET_SCIENTIFIC_NAME(cataloged_item.collection_object_id),
	           '',
	           decode(MCZBASE.GET_TYPESTATUSNAME(cataloged_item.collection_object_id,
	                     MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id)),'','',
	                ' of ' || MCZBASE.GET_TYPESTATUSNAME(cataloged_item.collection_object_id,
	                            MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id))
	           )
	        ) as typestatusname,
		concattransagent(deaccession.transaction_id, 'recipient institution')  recipientInstitutionName,
		cataloged_item.collection_object_id,
        collection.collection,
		concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
		concatattributevalue(cataloged_item.collection_object_id,'sex') as sex,
		decode (sampled_from_obj_id,
			null,part_name,
			part_name || ' sample') part_name,
		 MCZBASE.CONCATPARTSINDEACC(cataloged_item.collection_object_id,deaccession.transaction_id) parts,
		 part_modifier,
		 preserve_method,
		 lot_count,
		condition,
		 item_instructions,
		 HTF.escape_sc(deacc_item_remarks) deacc_item_remarks,
		 coll_obj_disposition,
		 scientific_name,
		 Encumbrance,
		 agent_name,
		 deacc_number,
		 deacc_type,
                 concattransagent(deaccession.transaction_id, 'received by')  recAgentName,
		 HTF.escape_sc(spec_locality) spec_locality,
		 higher_geog,
                 GET_CHRONOSTRATIGRAPHY(locality.locality_id) chronostrat,
                 GET_LITHOSTRATIGRAPHY(locality.locality_id) lithostrat,
		 orig_lat_long_units,
		 lat_deg,
		 lat_min,
		 lat_sec,
		 long_deg,
		 long_min,
		 long_sec,
		 dec_lat_min,
		 dec_long_min,
		 lat_dir,
		 long_dir,
		 dec_lat,
		 dec_long,
		 max_error_distance,
		 max_error_units,
		 decode(orig_lat_long_units,
				'decimal degrees',to_char(dec_lat) || '&deg; ',
				'deg. min. sec.', to_char(lat_deg) || '&deg; ' || to_char(lat_min) || '&acute; ' || to_char(lat_sec) || '&acute;&acute; ' || lat_dir,
				'degrees dec. minutes', to_char(lat_deg) || '&deg; ' || to_char(dec_lat_min) || '&acute; ' || lat_dir
			)  VerbatimLatitude,
			decode(orig_lat_long_units,
				'decimal degrees',to_char(dec_long) || '&deg;',
				'deg. min. sec.', to_char(long_deg) || '&deg; ' || to_char(long_min) || '&acute; ' || to_char(long_sec) || '&acute;&acute; ' || long_dir,
				'degrees dec. minutes', to_char(long_deg) || '&deg; ' || to_char(dec_long_min) || '&acute; ' || long_dir
			)  VerbatimLongitude,
		HTF.escape_sc(concatColl(cataloged_item.collection_object_id)) as collectors
	 from
		deacc_item,
		deaccession,
		specimen_part,
		coll_object,
		cataloged_item,
		coll_object_encumbrance,
		encumbrance,
		agent_name,
		identification,
		collecting_event,
		locality,
		geog_auth_rec,
		accepted_lat_long,
		collection
	WHERE
		deacc_item.collection_object_id = specimen_part.collection_object_id AND
		deaccession.transaction_id = deacc_item.transaction_id AND
		specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
		specimen_part.collection_object_id = coll_object.collection_object_id AND
		coll_object.collection_object_id = coll_object_encumbrance.collection_object_id (+) and
		coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id (+) AND
		encumbrance.encumbering_agent_id = agent_name.agent_id (+) AND
		cataloged_item.collection_object_id = identification.collection_object_id AND
		identification.accepted_id_fg = 1 AND
		cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
		collecting_event.locality_id = locality.locality_id AND
		locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id AND
		locality.locality_id = accepted_lat_long.locality_id (+) AND
		cataloged_item.collection_id = collection.collection_id AND
		deacc_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
	  ORDER BY cat_num
</cfquery>
<!---  getAccMCZ - information for accession invoice headers.   --->
<cfquery name="caller.getAccMCZ" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT distinct
		replace(to_char(trans_date, 'dd-Month-yyyy'),' ','') as trans_date,
		replace(to_char(received_date, 'dd-Month-yyyy'),' ','') as received_date,

		-- inside
		concattransagent(trans.transaction_id, 'in-house authorized by') authAgentName,
		concattransagent(trans.transaction_id, 'in-house contact')   internalContactName,
		concattransagent(trans.transaction_id, 'additional in-house contact')   addInHouseContactNames,
		concattransagent(trans.transaction_id, 'for use by')   foruse_by_name,
		concattransagent(trans.transaction_id, 'entered by')   enteredByName,
		concattransagent(trans.transaction_id, 'received by')   recAgentName,
		MCZBASE.get_eaddresses(trans.transaction_id,'in-house contact') inHouseContactPhEmail,
		MCZBASE.get_eaddresses(trans.transaction_id,'additional in-house contact') addInHouseContactPhEmail,
		
		-- outside
		concattransagent(trans.transaction_id, 'received from')   recFromAgentName,
		concattransagent(trans.transaction_id, 'outside authorized by') outsideAuthAgentName,
		concattransagent(trans.transaction_id, 'outside contact')   outsideContactName,
		concattransagent(trans.transaction_id, 'additional outside contact')   additionalContactNames,
		MCZBASE.get_eaddresses(trans.transaction_id,'outside contact') outsideContactPhEmail,
		get_address(outside_trans_agent.agent_id) outside_address,
		'' as outside_contact_title,		

		-- Stewardship
		concattransagent(trans.transaction_id, 'stewardship from agency')   agencyName,
		
		replace(nature_of_material,'&','&amp;') nature_of_material,
		replace(trans_remarks,'&','&amp;') trans_remarks,
		accn_type,
		'specimens' as  object_specimen,
		accn_number,
		accn_status,
		estimated_count,
		'' as value,

		-- shipments (note, one row per shipment)
		MCZBASE.count_shipments_for_trans(trans.transaction_id) as shipment_count,
		shipment.shipment_id,
		replace(to_char(shipped_date,'dd-Month-yyyy'),' ','') as shipped_date,
		shipped_carrier_method,
		shipment.no_of_packages as no_of_packages,
		ship_to_addr.formatted_addr  shipped_to_address   ,
		ship_from_addr.formatted_addr  shipped_from_address  ,
		replace(MCZBASE.get_agentnameoftype(shipment.PACKED_BY_AGENT_ID, 'preferred'),'[Error]','') as processed_by_name,
		sponsor_name.agent_name project_sponsor_name,
		acknowledgement,
		collection.collection,
		shipment.print_flag,
		shipment.carriers_tracking_number, 
		replace(replace(MCZBASE.get_permits_for_shipment(shipment.shipment_id),'|','<BR>'),'&','&amp;') as shipping_permits,

		-- media and permits on the accession
		replace(MCZBASE.get_media_for_trans(trans.transaction_id,'documents accn'),'&','&amp;') as media,
		replace(MCZBASE.get_permits_for_trans(trans.transaction_id),'&','&amp;') as permits
	FROM
		accn 
		left join trans on accn.transaction_id = trans.transaction_id
		left join trans_agent outside_trans_agent on trans.transaction_id = outside_trans_agent.transaction_id
		left join shipment on accn.transaction_id = shipment.transaction_id
		left join collection on trans.collection_id = collection.collection_id
		left join addr ship_to_addr on shipment.SHIPPED_TO_ADDR_ID = ship_to_addr.addr_id
		left join addr ship_from_addr on shipment.SHIPPED_FROM_ADDR_ID	= ship_from_addr.addr_id
		left join project_trans on trans.transaction_id = project_trans.transaction_id
		left join project_sponsor on project_trans.project_id = project_sponsor.project_id
		left join agent_name sponsor_name on project_sponsor.agent_name_id = sponsor_name.agent_name_id
	WHERE
		outside_trans_agent.trans_agent_role='received from' and
		accn.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
	ORDER BY 
		shipment.print_flag desc, shipment.shipment_id asc
</cfquery>
