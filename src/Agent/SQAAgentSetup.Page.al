namespace SubscriptionQuoteAgent;

using System.Agents;

page 50120 "SQA Agent Setup"
{
    PageType = ConfigurationDialog;
    Caption = 'Set up Subscription Quote Agent';
    SourceTable = "SQA Agent Setup";
    SourceTableTemporary = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            part(AgentSetupPart; "Agent Setup Part")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
            }
            group(AdditionalConfiguration)
            {
                Caption = 'Subscription Billing';

                field("Default Contract Type"; Rec."Default Contract Type")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        IsUpdated := true;
                    end;
                }
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(OK)
            {
                Caption = 'Update';
                Enabled = IsUpdated;
                ToolTip = 'Apply the changes to the agent setup.';
            }
            systemaction(Cancel)
            {
                Caption = 'Cancel';
                ToolTip = 'Discards the changes and closes the setup page.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        InitializePage();
    end;

    trigger OnAfterGetRecord()
    begin
        InitializePage();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        SQAAgentSetupMgt: Codeunit "SQA Agent Setup Mgt.";
    begin
        if CloseAction = CloseAction::Cancel then
            exit(true);
        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(AgentSetupBuffer);
        SQAAgentSetupMgt.SaveSetupRecord(Rec, AgentSetupBuffer);
        exit(true);
    end;

    local procedure InitializePage()
    var
        SQAAgentSetupMgt: Codeunit "SQA Agent Setup Mgt.";
    begin
        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(AgentSetupBuffer);
        SQAAgentSetupMgt.InitializeSetupRecord(Rec, AgentSetupBuffer);
        CurrPage.AgentSetupPart.Page.SetAgentSetupBuffer(AgentSetupBuffer);
        IsUpdated := IsUpdated or CurrPage.AgentSetupPart.Page.GetChangesMade();
    end;

    var
        AgentSetupBuffer: Record "Agent Setup Buffer";
        IsUpdated: Boolean;
}
