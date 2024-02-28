function orapwCheck(p,u) { 
	var regExp=/^[A-Za-z0-9!$%&_?(\-)<>=/:;*\.]$/;
	var minLen=8;
	var msg="";
	if(p.indexOf(u)>-1) { 
		msg="Password may not contain your username. ";
	}
	if(p.length<minLen||p.length>30){ 
		msg=msg+"Password must be between "+minLen+" and 30 characters. ";
	}
	if(!p.match(/[a-zA-Z]/)) {
		msg=msg+"Password must contain at least one letter. ";
	}
	if(!p.match(/\d+/)) {
		msg=msg+"Password must contain at least one number. ";
	} 
	if(!p.match(/[!,$,%,&,*,?,_,-,(,),<,>,=,/,:,;,.]/))
		{msg=msg+"Password must contain at least one of: !,$,%,&,*,?,_,-,(,),<,>,=,/,:,;.  "
	} 
	for(var i=0;i<p.length;i++){
		if(!p.charAt(i).match(regExp)){
			msg="Password may contain only A-Z, a-z, 0-9, and !,$,%,&,*,?,_,-,(,),<,>,=,/,:,;. "
		}
	}
	if (msg=="") { 
		// NOTE: This string is tested for by invocations of this function, do not edit.
		msg="Password is acceptable";
	}
	return msg;
}

