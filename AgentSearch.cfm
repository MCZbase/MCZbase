<cfinclude template="includes/_frameHeader.cfm">
<script type='text/javascript' src='/includes/internalAjax.js'></script>
<link rel="stylesheet" type="text/css" href="/includes/css/mcz_style.css" title="mcz_style">
<cfquery name="prefix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct(prefix) as prefix from person where prefix is not null
</cfquery>
<cfquery name="suffix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct(suffix) as suffix from person where suffix is not null
</cfquery>
<!---
 <a href="javascript:void(0);"
 	onClick="getDocs('agent'); return false;"
	onMouseOver="self.status='Click for help.';return true;"
	onmouseout="self.status='';return true;"><img src="/images/what.gif" border="0">
</a>
--->
<!---<span class="infoLink pageHelp" onclick="getDocs('agent');">Page Help</span>--->
<td>

</td>
<h3 class="wikilink">Search for an agent <img src="/images/info_i_2.gif" onClick="getMCZDocs('Agent_Search')" class="likeLink" alt="[ help ]"></h3>
<br>
<cfoutput>
<form name="agntSearch" action="AgentGrid.cfm" method="post" target="_pick">
	<input type="hidden" name="Action" value="search">
<table>	
	<tr>
		<td>
			<label for="prefix">Prefix</label>
			<select name="prefix" size="1" id="prefix">
				<option selected value="">none</option>
      	    	<cfloop query="prefix"> 
        			<option value="#prefix.prefix#">#prefix.prefix#</option>
      				</cfloop> 
   			 </select>
		</td>
		<td>
			<label for="first_name">First Name</label>
			<input type="text" name="first_name">
		</td>
	</tr>
    <tr>
       <td>
			<label for="suffix">
				Suffix
			</label>
			<select name="suffix" size="1" id="suffix">
				<option selected value="">none</option>
	      	   	<cfloop query="suffix"> 
	        		<option value="#suffix.suffix#">#suffix.suffix#</option>
	      		</cfloop> 
	   		 </select>
		</td>
		<td>
			<label for="middle_name">
				Middle Name
			</label>
			<input type="text" name="middle_name" id="middle_name">
		</td>
    </tr>
    <tr>
        <td>
			<label for="birthOper">
				Birth Date
			</label>
			<select name="birthOper" size="1" id="birthOper">
				<option value="<=">Before</option>
				<option selected value="=" >Is</option>
				<option value=">=">After</option>
			</select>
			<input type="text" size="10" name="birth_date" id="birth_date">
		</td>
		<td>
			<label for="last_name">
			Last Name
			</label>
			<input type="text" name="last_name" id="last_name">
		</td>
	<tr>
	<tr>
		<td>
			<label for="deathOper">
				Death Date
			</label>
			<select name="deathOper" size="1" id="deathOper">
				<option value="<=">Before</option>
				<option selected value="=" >Is</option>
				<option value=">=">After</option>
			</select>
			<input type="text" size="10" name="death_date" id="death_date">
		</td>
		<td>
			<label for="agent_id">
				Agent ID
			</label>
			<input type="text" name="agent_id" size="10" id="agent_id">
		</td>
	</tr>

	<tr>
		<td>
			<label for="address">
			Address
			</label>
			<input type="text" name="address" id="address" size="20">
		</td>
		<td>
			<label for="anyName">
				Any part of any name
			</label>
			<input type="text" name="anyName" id="anyName" size="20">
		</td>
	</tr>
   
	<tr>
		<td colspan="2" align="center" style="padding-top: 1em;font-size: 15px;">
		      <input type="button" 
					value="New Other Agent" 
					class="insBtn"
                     style="padding: 2px 6px;"
					onmouseover="this.className='insBtn btnhov'"
					onmouseout="this.className='insBtn'"
					onClick="window.open('/agents/editAgent.cfm?action=new&agent_type=other%20agent','_blank');">
            <input type="button" 
					value="New Person" 
					class="insBtn"
                   style="padding: 2px 6px;"
					onmouseover="this.className='insBtn btnhov'"
					onmouseout="this.className='insBtn'"
					onClick="window.open('/agents/editAgent.cfm?action=new&agent_type=person','_blank');">
            <input type="reset" 
				value="Clear Form" 
				class="clrBtn"
                   style="padding: 2px 6px;"
				onmouseover="this.className='clrBtn btnhov'"
				onmouseout="this.className='clrBtn'">	
            <input type="submit" 
				value="Search" 
				class="schBtn"
                   style="padding: 2px 20px;"
				onmouseover="this.className='schBtn btnhov'"
				onmouseout="this.className='schBtn'">
		</td>
	</tr>
</table>
</form>
</cfoutput>	
<cfinclude template="includes/_pickFooter.cfm">
