/* specimens/identification.js
 
  functions for working with identification forms 

*/
function addNewIdBy(n) {
	$('.determiner_block_' + n).show();
	$('#newIdBy_' + n).addClass('reqdClr');
}
function clearNewIdBy (n) {
	$('.determiner_block_' + n).hide();
	$('#newIdBy_' + n).val('').removeClass('reqdClr');
}
function newIdFormula (f) {
			
	if (f && f.includes('B')) { 
		// enable B inputs
		$("#taxonb").addClass('reqdClr');
		$("#taxonb").prop('required',true);
		$("#taxonb").prop('disabled',false);
		$("#taxonb").val("");
		$("#taxonb_id").val("");
	} else {
		$("#taxonb").removeClass('reqdClr');
		$("#taxonb").prop('required',false);
		$("#taxonb").prop('disabled',true);
		$("#taxonb").val("");
		$("#taxonb_id").val("");
	}
	if(f=='A {string}') {
		// unused special case
		$('#userID').show();
		$('#user_identification').addClass('reqdClr');
		$('#user_identification').prop('required',true);
	} else {
		$('#userID').hide();
		$('#user_identification').removeClass('reqdClr');
		$('#user_identification').prop('required',false);
	}
}
function removeIdentifier ( identification_id,num  ) {
	var tabCellS = "IdTr_" + identification_id + "_" + num;
	var tabCell = document.getElementById(tabCellS);
	tabCell.style.display='none';
	var affElemS = "IdBy_" + identification_id + "_" + num;
	var affElem = document.getElementById(affElemS);
	var affElemIdS = "IdBy_" + identification_id + "_" + num + "_id";
	var affElemId = document.getElementById(affElemIdS);
	affElemId.value='DELETE'
	affElemId.className='';
	affElem.className='';
	affElem.value='';											
}
function addIdentifier(identification_id,num) {
	var tns = 'identifierTableBody_' + identification_id;
	var theTable = document.getElementById(tns);
	var counterS='number_of_identifiers_' + identification_id;
	var counter = document.getElementById(counterS);
	counter.value=parseInt(counter.value) + 1;
	var nn=parseInt(num)+1;
	var controlS="addIdentifier_" + identification_id;
	var control=document.getElementById(controlS);
	var cAtt="addIdentifier('" + identification_id + "','" +  nn + "')";
	control.setAttribute("onclick",cAtt);
	var nI = document.createElement('input');
	nI.setAttribute('type','text');
	idStr = 'IdBy_' + identification_id + "_" + num;
	nI.id = idStr;
	nI.setAttribute('name',idStr);
	nI.setAttribute('size','50');
	nI.className='reqdClr';
	
	//nI.setAttribute("onfocus", "attachAgentPick(this)");
	var nid = document.createElement('input');
	nid.setAttribute('type','hidden');
	nid.setAttribute('class','reqdClr');
	ididStr = 'IdBy_' + identification_id + "_" + num + '_id';
	nid.id = ididStr;
	nid.setAttribute('name',ididStr);
	r = document.createElement('tr');
	r.id="IdTr_" + identification_id + "_" + num;
	t1 = document.createElement('td');
	t2 = document.createElement('td');
	t3 = document.createTextNode("Identified By:");
	var d = document.createElement('img');
	d.src='/images/del.gif';
	d.className="likeLink";
	var cStrg = "removeIdentifier('" + identification_id + "','" + num + "')";
	d.setAttribute('onclick',cStrg);
	theTable.appendChild(r);
	r.appendChild(t1);
	r.appendChild(t2);
	t1.appendChild(t3);
	t2.appendChild(nI);
	t2.appendChild(nid);
	t2.appendChild(d);
}
