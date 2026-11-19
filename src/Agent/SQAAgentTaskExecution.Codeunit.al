namespace SubscriptionQuoteAgent;

using System.Agents;

/// <summary>
/// Only messages created by "Sub. Agent Request Processor" (which carry a valid
/// SQA-REQUEST marker) run without review. Anything else gets a Warning annotation,
/// which makes Business Central ask a person to approve the message first.
/// </summary>
codeunit 50122 "SQA Agent Task Execution" implements IAgentTaskExecution
{
    Access = Internal;

    var
        RequestMarkerTxt: Label 'SQA-REQUEST:', Locked = true;
        UnknownSourceMsg: Label 'This message was not created from a Subscription Agent Request.';
        UnknownSourceDetailsTxt: Label 'Review the message before the agent processes it. Messages created with Send to Agent on a Subscription Agent Request run automatically.';
        AlreadyDoneMsg: Label 'This request already has a contract.';
        AlreadyDoneDetailsTxt: Label 'Request %1 already has contract %2. Approve only if you want the agent to look at it again.', Comment = '%1 = request no., %2 = contract no.';

    procedure AnalyzeAgentTaskMessage(AgentTaskMessage: Record "Agent Task Message"; var Annotations: Record "Agent Annotation")
    var
        Request: Record "Sub. Agent Request";
        AgentMessage: Codeunit "Agent Message";
        RequestNo: Integer;
    begin
        if AgentTaskMessage.Type = AgentTaskMessage.Type::Output then
            exit;

        if not TryGetRequestNo(AgentMessage.GetText(AgentTaskMessage), RequestNo) or not Request.Get(RequestNo) then begin
            AddAnnotation(Annotations, 'SQA001', UnknownSourceMsg, UnknownSourceDetailsTxt);
            exit;
        end;

        if Request."Contract No." <> '' then
            AddAnnotation(Annotations, 'SQA002', AlreadyDoneMsg, StrSubstNo(AlreadyDoneDetailsTxt, Request."Entry No.", Request."Contract No."));
    end;

    procedure GetAgentTaskUserInterventionSuggestions(AgentTaskUserInterventionRequestDetails: Record "Agent User Int Request Details"; var Suggestions: Record "Agent Task User Int Suggestion")
    var
        MissingInputLbl: Label 'Provide the missing input';
        MissingInputDescriptionLbl: Label 'Use when the customer, the contract start date, or the license items and quantities cannot be determined from the request.', Locked = true;
        MissingInputInstructionsLbl: Label 'Fill in the missing fields on the Subscription Agent Request card, then let the agent continue.';
        PriceMissingLbl: Label 'Fix the missing price';
        PriceMissingDescriptionLbl: Label 'Use when a quote line has no unit price on the contract start date.', Locked = true;
        PriceMissingInstructionsLbl: Label 'Add a sales price list line valid on the contract start date for the item, then let the agent run Apply Contract Start Date Pricing again.';
    begin
        if AgentTaskUserInterventionRequestDetails.Type <> AgentTaskUserInterventionRequestDetails.Type::Assistance then
            exit;

        Suggestions.Summary := MissingInputLbl;
        Suggestions.Description := MissingInputDescriptionLbl;
        Suggestions.Instructions := MissingInputInstructionsLbl;
        Suggestions.Insert();

        Suggestions.Summary := PriceMissingLbl;
        Suggestions.Description := PriceMissingDescriptionLbl;
        Suggestions.Instructions := PriceMissingInstructionsLbl;
        Suggestions.Insert();
    end;

    local procedure TryGetRequestNo(MessageText: Text; var RequestNo: Integer): Boolean
    var
        Rest: Text;
        Digits: Text;
        Pos: Integer;
        i: Integer;
    begin
        Pos := StrPos(MessageText, RequestMarkerTxt);
        if Pos = 0 then
            exit(false);
        Rest := DelChr(CopyStr(MessageText, Pos + StrLen(RequestMarkerTxt)), '<', ' ');
        for i := 1 to StrLen(Rest) do
            if Rest[i] in ['0' .. '9'] then
                Digits += Rest[i]
            else
                break;
        if Digits = '' then
            exit(false);
        exit(Evaluate(RequestNo, Digits));
    end;

    local procedure AddAnnotation(var Annotations: Record "Agent Annotation"; Code: Code[20]; Message: Text; Details: Text)
    begin
        Annotations.Code := Code;
        Annotations.Severity := Annotations.Severity::Warning;
        Annotations.Message := CopyStr(Message, 1, MaxStrLen(Annotations.Message));
        Annotations.Details := CopyStr(Details, 1, MaxStrLen(Annotations.Details));
        Annotations.Insert();
    end;
}
