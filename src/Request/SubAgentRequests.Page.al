namespace SubscriptionQuoteAgent;

page 50111 "Sub. Agent Requests"
{
    Caption = 'Subscription Agent Requests';
    PageType = List;
    SourceTable = "Sub. Agent Request";
    CardPageId = "Sub. Agent Request Card";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.") { ToolTip = 'Specifies the request number.'; }
                field(Status; Rec.Status) { ToolTip = 'Specifies how far the request has been processed.'; }
                field("Customer No."; Rec."Customer No.") { }
                field("Customer Name"; Rec."Customer Name") { ToolTip = 'Specifies the customer''s name.'; }
                field("Contract Start Date"; Rec."Contract Start Date") { }
                field("Quote No."; Rec."Quote No.") { ToolTip = 'Specifies the sales quote created for the request.'; }
                field("Contract No."; Rec."Contract No.") { ToolTip = 'Specifies the contract created for the request.'; }
                field("Requested By"; Rec."Requested By") { ToolTip = 'Specifies who created the request.'; }
            }
        }
    }
}
