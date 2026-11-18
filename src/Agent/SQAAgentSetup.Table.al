namespace SubscriptionQuoteAgent;

using Microsoft.SubscriptionBilling;

table 50120 "SQA Agent Setup"
{
    Caption = 'Subscription Quote Agent Setup';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
        }
        field(10; "Default Contract Type"; Code[10])
        {
            Caption = 'Default Contract Type';
            TableRelation = "Subscription Contract Type";
            ToolTip = 'Specifies the contract type used when a request does not name one.';
        }
    }

    keys
    {
        key(PK; "User Security ID") { Clustered = true; }
    }

    /// <summary>
    /// Finds the agent instance to send requests to (one instance per company).
    /// </summary>
    procedure FindActiveAgent(): Boolean
    begin
        Reset();
        exit(FindFirst() and not IsNullGuid("User Security ID"));
    end;
}
