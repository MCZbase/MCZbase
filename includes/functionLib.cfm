<!---  
functionLib.cfm 

This file is to hold only globaly reused coldfusion functions.

Copyright 2019 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

  @author Paul J. Morris

--->

<!----------------------------------------------------------->

<!---  function initSession to initialize a new login session.
	@param pwd a login password for username
	@param username the user to attempt to login wiht pwd
	@return true on successful login, otherwise false
---> 
<cffunction name="initSession" returntype = boolean output="true">
        <cfargument name="pwd" type="string" required="false">
        <cfargument name="username" type="string" required="false">
        <!--- Clear any current session and log any current session user out --->
        <cfset StructClear(Session)>
        <cflogout>

	<cfreturn false>
</cffunction>
