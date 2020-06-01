<!---
specimens/component/functions.cfc

Copyright 2020 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<cfcomponent>

<!------------------------------------------------------------------------------------------------->		
<cfscript>
	function isYear(x){
       var d = "^[1-9][0-9]{3}$";
       return isValid("regex", x, d);
	}
</cfscript>
<cffunction name="jsescape">
	<cfargument name="in" required="yes">
	<cfset out=replace(in,"'","`","all")>
	<cfset out=replace(out,'"','``',"all")>
	<cfreturn out>
</cffunction>
<cffunction name="niceURL" returntype="Any">
	<cfargument name="s" type="string" required="yes">
	<cfscript>
		var r=trim(s);
		r=trim(rereplace(r,'<[^>]*>','',"all"));
		r=rereplace(r,'[^A-Za-z ]','',"all");
		r=rereplace(r,' ','-',"all");
		r=lcase(r);
		if (len(r) gt 150) {r=left(r,150);}
		if (right(r,1) is "-") {r=left(r,len(r)-1);}
		r=rereplace(r,'-+','-','all');
		return r;
	</cfscript>
</cffunction>
<cffunction name="SubsetEncodeForURL" returntype="Any">
	<!--- URL escape a small subset of characters that may be found in filenames (used for preview_uri) --->
	<!--- We don't want to escape the full set of reserved URI characters, as  media.preview_uri --->
	<!--- contains both filename paths and URIs. The characters :/&.=?, are all used in valid URIs there.  --->
	<cfargument name="s" type="string" required="yes">
	<cfscript>
	      var r=trim(s);
	      r = Replace(Replace(r,'[','%5B'),']','%5D');
	      r = Replace(Replace(r,'(','%28'),')','%29');
	      r = Replace(r,'!','%21');
	      r = Replace(r,',','%2C');
	      r = Replace(r,' ','%20');
	      return r;
	</cfscript>
</cffunction>
<cffunction name="getMediaPreview" access="public" output="true">
	<cfargument name="puri" required="true" type="string">
	<cfargument name="mt" required="false" type="string">
	<cfset r=0>
	<cfif len(puri) gt 0>
		<!--- Hack - media.preview_uri can contain filenames that aren't correctly URI encoded as well as valid IRIs --->
		<cfhttp method="head" url="#SubsetEncodeForURL(puri)#" timeout="5">
		<cfif isdefined("cfhttp.responseheader.status_code") and cfhttp.responseheader.status_code is 200>
			<cfset r=1>
		</cfif>
	</cfif>
	<cfif r is 0>
		<cfif mt is "image">
			<cfreturn "/shared/images/noThumb.jpg">
		<cfelseif mt is "audio">
			<cfreturn "/shared/images/audioNoThumb.png">
		<cfelseif mt is "text">
			<cfreturn "/shared/images/documentNoThumb.png">
		<cfelseif mt is "multi-page document">
			<cfreturn "/shared/images/documentNoThumb.png">
		<cfelse>
			<cfreturn "/shared/images/noThumb.jpg">
		</cfif>
	<cfelse>
		<cfreturn puri>
	</cfif>
</cffunction>


<!----------------------------------------------------------------------------------------------------------------->


</cfcomponent>
