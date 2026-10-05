/** orapwCheck check a proposed password against the rules of the database's password verify
 * function (SYS.VERIFY_FUNCTION_MCZ), which decides for accounts with a database login.  Double
 * quotes are refused as well, as passwords are placed in quoted DDL.
 * @param p the proposed password.
 * @param u the username, which the password may not contain.
 * @return "Password is acceptable", or messages describing what is wrong.
 */
function orapwCheck(p,u) {
	var minLen=8;
	var msg="";
	if(u && p.toLowerCase().indexOf(u.toLowerCase())>-1) {
		msg="Password may not contain your username. ";
	}
	if(p.length<minLen||p.length>30){
		msg=msg+"Password must be between "+minLen+" and 30 characters. ";
	}
	if(!p.match(/[a-zA-Z]/)) {
		msg=msg+"Password must contain at least one letter. ";
	}
	if(!p.match(/[0-9]/)) {
		msg=msg+"Password must contain at least one number. ";
	}
	// The punctuation the database's verify function counts, less the double quote.
	if(!p.match(/[!#$%&()`*+,\-\/:;<=>?_]/)) {
		msg=msg+"Password must contain at least one of: ! # $ % & ( ) ` * + , - / : ; < = > ? _  ";
	}
	// Printable ASCII other than space and double quote.
	if(!p.match(/^[!#-~]*$/)) {
		msg="Password may contain letters, digits and punctuation, but not spaces, double quotes or accented characters. ";
	}
	if (msg=="") {
		// NOTE: This string is tested for by invocations of this function, do not edit.
		msg="Password is acceptable";
	}
	return msg;
}
