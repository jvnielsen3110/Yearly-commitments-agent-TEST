namespace SubscriptionQuoteAgent;

using System.Agents;
using System.AI;
using System.Security.AccessControl;

codeunit 50120 "SQA Agent Factory" implements IAgentFactory
{
    Access = Internal;

    var
        ProfileIdTxt: Label 'SQA AGENT', Locked = true;
        PermissionSetTxt: Label 'SQA AGENT', Locked = true;

    procedure GetFirstTimeSetupPageId(): Integer
    begin
        exit(Page::"SQA Agent Setup");
    end;

    procedure ShowCanCreateAgent(): Boolean
    var
        SQAAgentSetup: Record "SQA Agent Setup";
        AgentSystemPermissions: Codeunit "Agent System Permissions";
    begin
        // One instance per company, created by an agent administrator.
        if not AgentSystemPermissions.CurrentUserHasCanManageAllAgentsPermission() then
            exit(false);
        exit(SQAAgentSetup.IsEmpty());
    end;

    procedure GetCopilotCapability(): Enum "Copilot Capability"
    begin
        // Remove if your version of IAgentFactory has no such member.
        exit(Enum::"Copilot Capability"::"Subscription Quote Agent");
    end;

    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    var
        CurrentModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModule);
        TempAllProfile.Scope := TempAllProfile.Scope::Tenant;
        TempAllProfile."App ID" := CurrentModule.Id;
        TempAllProfile."Profile ID" := ProfileIdTxt;
        TempAllProfile.Insert();
    end;

    procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        CurrentModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModule);
        TempAccessControlBuffer.Init();
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := CurrentModule.Id;
        TempAccessControlBuffer."Role ID" := PermissionSetTxt;
        TempAccessControlBuffer.Insert();
    end;
}
