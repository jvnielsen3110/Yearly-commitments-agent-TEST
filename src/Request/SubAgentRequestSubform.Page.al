namespace SubscriptionQuoteAgent;

page 50112 "Sub. Agent Request Subform"
{
    Caption = 'Licenses';
    PageType = ListPart;
    SourceTable = "Sub. Agent Request Line";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item description.';
                }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
            }
        }
    }
}
