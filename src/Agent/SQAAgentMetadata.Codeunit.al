namespace SubscriptionQuoteAgent;

using System.Agents;

codeunit 50121 "SQA Agent Metadata" implements IAgentMetadata
{
    Access = Internal;

    procedure GetInitials(AgentUserId: Guid): Text[4]
    begin
        exit('SQ');
    end;

    procedure GetSetupPageId(AgentUserId: Guid): Integer
    begin
        exit(Page::"SQA Agent Setup");
    end;

    procedure GetSummaryPageId(AgentUserId: Guid): Integer
    begin
        exit(Page::"Sub. Agent Requests");
    end;

    procedure GetAgentTaskMessagePageId(AgentUserId: Guid; MessageId: Guid): Integer
    begin
        exit(Page::"Agent Task Message Card");
    end;

    procedure GetAgentAnnotations(AgentUserId: Guid; var Annotations: Record "Agent Annotation")
    begin
        Clear(Annotations);
    end;
}
