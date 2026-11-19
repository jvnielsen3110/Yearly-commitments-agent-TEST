namespace SubscriptionQuoteAgent;

using System.Agents;

enumextension 50120 "SQA Agent Metadata Provider" extends "Agent Metadata Provider"
{
    value(50120; "Subscription Quote Agent")
    {
        Caption = 'Subscription Quote Agent';
        Implementation = IAgentFactory = "SQA Agent Factory",
                         IAgentMetadata = "SQA Agent Metadata",
                         IAgentTaskExecution = "SQA Agent Task Execution";
    }
}
