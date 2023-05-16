
/** getLowestGeography
* find the lowest ranking geographic entity name on a geography form,
* note, does not include quad as one of the ranks
*
* @return the value of the lowest rank filled in on the form.
*/
function getLowestGeography() {
	var	result = "";
	if ($('##island').val()!="") {
		result = $('##island').val();
	} else if ($('##island_group').val()!="") {
		result = $('##island_group').val();
	} else if ($('##feature').val()!="") {
		result = $('##feature').val();
	} else if ($('##county').val()!="") {
		result = $('##county').val();
	} else if ($('##state_prov').val()!="") {
		result = $('##state_prov').val();
	} else if ($('##country').val()!="") {
		result = $('##country').val();
	} else if ($('##water_feature').val()!="") {
		result = $('##water_feature').val();
	} else if ($('##sea').val()!="") {
		result = $('##sea').val();
	} else if ($('##ocean_subregion').val()!="") {
		result = $('##ocean_subregion').val();
	} else if ($('##ocean_region').val()!="") {
		result = $('##ocean_region').val();
	} else if ($('##continent_ocean').val()!="") {
		result = $('##continent_ocean').val();
	}
	return	result;
}
