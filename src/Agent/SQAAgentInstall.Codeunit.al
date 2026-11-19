namespace SubscriptionQuoteAgent;

using System.AI;

codeunit 50123 "SQA Agent Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerDatabase()
    begin
        RegisterCapability();
    end;

    procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        LearnMoreUrlTxt: Label 'https://learn.microsoft.com/dynamics365/business-central/srb/welcome', Locked = true;
    begin
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Subscription Quote Agent") then
            CopilotCapability.RegisterCapability(
                Enum::"Copilot Capability"::"Subscription Quote Agent",
                Enum::"Copilot Availability"::Preview,
                "Copilot Billing Type"::"Microsoft Billed",
                LearnMoreUrlTxt);
    end;
}
