namespace SubscriptionQuoteAgent;

using System.Agents;

codeunit 50124 "SQA Agent Setup Mgt."
{
    Access = Internal;

    var
        AgentNameTxt: Label 'SUBQUOTEAGENT', Locked = true;
        AgentDisplayNameTxt: Label 'Subscription Quote Agent';
        AgentSummaryTxt: Label 'Prepares sales quotes priced on the contract start date and creates customer subscription contracts for software licenses.';
        InstructionsFileTxt: Label 'Instructions.txt', Locked = true;

    procedure InitializeSetupRecord(var TempSetup: Record "SQA Agent Setup" temporary; var AgentSetupBuffer: Record "Agent Setup Buffer")
    var
        SetupRecord: Record "SQA Agent Setup";
        AgentSetup: Codeunit "Agent Setup";
    begin
        if not IsNullGuid(TempSetup."User Security ID") then
            if SetupRecord.Get(TempSetup."User Security ID") then
                TempSetup.TransferFields(SetupRecord, false);

        if TempSetup.IsEmpty() then
            TempSetup.Insert();

        if AgentSetupBuffer.IsEmpty() then
            AgentSetup.GetSetupRecord(
                AgentSetupBuffer,
                TempSetup."User Security ID",
                Enum::"Agent Metadata Provider"::"Subscription Quote Agent",
                AgentNameTxt + ' - ' + CompanyName(),
                AgentDisplayNameTxt,
                AgentSummaryTxt);
    end;

    procedure SaveSetupRecord(var TempSetup: Record "SQA Agent Setup" temporary; var AgentSetupBuffer: Record "Agent Setup Buffer")
    var
        SetupRecord: Record "SQA Agent Setup";
        AgentSetup: Codeunit "Agent Setup";
        Agent: Codeunit Agent;
        IsNewAgent: Boolean;
    begin
        IsNewAgent := IsNullGuid(AgentSetupBuffer."User Security ID");
        if AgentSetup.GetChangesMade(AgentSetupBuffer) then begin
            TempSetup."User Security ID" := AgentSetup.SaveChanges(AgentSetupBuffer);
            if IsNewAgent then
                Agent.SetInstructions(TempSetup."User Security ID", GetInstructions());
        end;

        if IsNullGuid(TempSetup."User Security ID") then
            exit;
        if not SetupRecord.Get(TempSetup."User Security ID") then begin
            SetupRecord.Init();
            SetupRecord."User Security ID" := TempSetup."User Security ID";
            SetupRecord.Insert();
        end;
        SetupRecord."Default Contract Type" := TempSetup."Default Contract Type";
        SetupRecord.Modify();
    end;

    /// <summary>
    /// Re-applies the instructions from the app resource (run after upgrading the app).
    /// </summary>
    procedure RefreshInstructions(AgentUserSecurityId: Guid)
    var
        Agent: Codeunit Agent;
    begin
        Agent.SetInstructions(AgentUserSecurityId, GetInstructions());
    end;

    procedure GetInstructions(): SecretText
    begin
        exit(NavApp.GetResourceAsText(InstructionsFileTxt));
    end;
}
