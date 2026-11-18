namespace SubscriptionQuoteAgent;

using Microsoft.Sales.Customer;
using Microsoft.SubscriptionBilling;
using System.Security.AccessControl;

/// <summary>
/// The "few inputs" for one quote / contract. Filled by a user, or by the agent from the
/// free-text request (e.g. a pasted email).
/// </summary>
table 50110 "Sub. Agent Request"
{
    Caption = 'Subscription Agent Request';
    DataClassification = CustomerContent;
    LookupPageId = "Sub. Agent Requests";
    DrillDownPageId = "Sub. Agent Requests";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; Status; Enum "Sub. Agent Request Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(10; "Request Text"; Text[2048])
        {
            Caption = 'Request Text';
            ToolTip = 'Specifies the request in free text, for example a pasted email. The agent reads it and fills in the fields below.';
        }
        field(20; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
            ToolTip = 'Specifies the customer the quote and contract are for.';
        }
        field(21; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Customer.Name where("No." = field("Customer No.")));
            Editable = false;
        }
        field(30; "Contract Start Date"; Date)
        {
            Caption = 'Contract Start Date';
            ToolTip = 'Specifies when the customer subscription contract starts. Prices are taken from the price lists valid on this date.';
        }
        field(31; "Contract Type"; Code[10])
        {
            Caption = 'Contract Type';
            TableRelation = "Subscription Contract Type";
            ToolTip = 'Specifies the contract type for the new customer subscription contract.';
        }
        field(32; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for the contract.';
        }
        field(33; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            ToolTip = 'Specifies the customer''s reference, copied to the quote.';
        }
        field(34; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            MinValue = 0;
            MaxValue = 100;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies a discount for all lines. Leave at 0 unless the customer was promised a discount.';
        }
        field(35; "Create Contract Immediately"; Boolean)
        {
            Caption = 'Create Contract Immediately';
            ToolTip = 'Specifies whether the contract is created right after the quote, without waiting for the customer to accept.';
        }
        field(40; "Quote No."; Code[20])
        {
            Caption = 'Quote No.';
            Editable = false;
        }
        field(41; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            Editable = false;
            TableRelation = "Customer Subscription Contract";
        }
        field(50; "Requested By"; Code[50])
        {
            Caption = 'Requested By';
            Editable = false;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(51; "Last Error"; Text[250])
        {
            Caption = 'Last Error';
            Editable = false;
        }
        field(52; "Agent Task ID"; BigInteger)
        {
            Caption = 'Agent Task ID';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        SQAAgentSetup: Record "SQA Agent Setup";
    begin
        if "Requested By" = '' then
            "Requested By" := CopyStr(UserId(), 1, MaxStrLen("Requested By"));
        if "Contract Type" = '' then
            if SQAAgentSetup.FindActiveAgent() then
                "Contract Type" := SQAAgentSetup."Default Contract Type";
    end;

    trigger OnDelete()
    var
        RequestLine: Record "Sub. Agent Request Line";
    begin
        RequestLine.SetRange("Request Entry No.", "Entry No.");
        RequestLine.DeleteAll(true);
    end;
}
