/** Scripts specific to transactions pages. **/

/** Check an agent to see if the agent has a flag on the agent, if so alert a message
  * @param agent_id the agent_id of the agent to check for rank flags.  
  **/
function checkAgent(agent_id) {
    jQuery.getJSON(
        "/transactions/component/functions.cfc",
        {
            method : "checkAgentFlag",
            agent_id : agent_id,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
           var rank = result.DATA.AGENTRANK[0];
           if (rank=='A') {
              // no message needed 
           } else {
              if (rank=='F') {
                messageDialog('Please speak to Collections Ops about this loan agent before proceeding.','Agent with an F Rank');
              } else {
                messageDialog("Please check this agent's rankings before proceeding",'Problematic Agent');
              }
           }
        }
      );
};

/** Check to see if an agent is ranked, and update the provided targetLinkDiv accordingly with a View link
  * or a View link with a flag.
  * @param agent_id the agent_id to lookup.
  * @param targetLinkDiv the id (without a leading # for the div the contents of which to replace with the View link.
  */
function updateAgentLink(agent_id,targetLinkDiv) {
    jQuery.getJSON(
        "/transactions/component/functions.cfc",
        {
            method : "checkAgentFlag",
            agent_id : agent_id,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
           var rank = result.DATA.AGENTRANK[0];
           if (rank=='A') {
                $('#'+targetLinkDiv).html("<a href='/agents.cfm?agent_id=" + agent_id + "' target='_blank'>View</a>");
           } else {
              if (rank=='F') {
                $('#'+targetLinkDiv).html("<a href='/agents.cfm?agent_id=" + agent_id + "' target='_blank'>View</a><img src='/images/flag-red.svg.png' width='16'>");
                messageDialog('Please speak to Collections Ops about this loan agent before proceeding.','Agent with an F Rank');
              } else {
                $('#'+targetLinkDiv).html("<a href='/agents.cfm?agent_id=" + agent_id + "' target='_blank'>View</a><img src='/images/flag-yellow.svg.png' width='16'>");
                messageDialog("Please check this agent's rankings before proceeding",'Problematic Agent');
              }
           }
        }
      );
};

