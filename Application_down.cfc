<!---
Application_down.cfc

Switch this file out with Application.cfc and restart coldfusion to deliver the server down for maintenance message.
Switch back and restart coldfusion to deliver MCZbase.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2019 President and Fellows of Harvard College

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
	<cfset This.name = "MCZbase" />
	<cfset This.SessionManagement="True">
	<cfset This.ClientManagement="true">
	<cfset This.ClientStorage="Cookie">
	<cffunction
     name="OnRequestStart"
     access="public"
     returntype="boolean"
     output="true">
     <cfargument
     name="TargetPage"
     type="string"
     required="true"/>
      
	     <!--- Define the local scope. --->
	     <cfset var LOCAL = StructNew() />
	      
	      
	     <!--- Set header code. --->
	     <cfheader
	     statuscode="503"
	     statustext="Service Temporarily Unavailable"
	     />
	      
	     <!--- Set retry time. --->
	     <cfheader
	     name="retry-after"
	     value="3600"
	     />
	      
	      
	     <h1>
	     Down For Maintenance
	     </h1>
	      
	     <p>
	     MCZbase is currently down for maintenance and will
	     be back up shortly. Sorry for the inconvenience.
	     </p>
	      
	      
	     <!---
	     By returning false, the rest of the page
	     rendering will halt.
	     --->
	     <cfreturn false />
     </cffunction>
</cfcomponent>
