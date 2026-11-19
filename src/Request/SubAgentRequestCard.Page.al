namespace SubscriptionQuoteAgent;

using Microsoft.Sales.Document;
using Microsoft.SubscriptionBilling;

page 50110 "Sub. Agent Request Card"
{
    Caption = 'Subscription Agent Request';
    PageType = Card;
    SourceTable = "Sub. Agent Request";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Request)
            {
                Caption = 'Request';
                field("Request Text"; Rec."Request Text")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how far the request has been processed.';
                }
                field("Last Error"; Rec."Last Error")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last error when processing the request.';
                    Style = Unfavorable;
                }
            }
            group(Inputs)
            {
                Caption = 'Quote and Contract';
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer''s name.';
                }
                field("Contract Start Date"; Rec."Contract Start Date") { ApplicationArea = All; }
                field("Contract Type"; Rec."Contract Type") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Your Reference"; Rec."Your Reference") { ApplicationArea = All; }
                field("Line Discount %"; Rec."Line Discount %") { ApplicationArea = All; }
                field("Create Contract Immediately"; Rec."Create Contract Immediately") { ApplicationArea = All; }
            }
            part(Lines; "Sub. Agent Request Subform")
            {
                ApplicationArea = All;
                Caption = 'Licenses';
                SubPageLink = "Request Entry No." = field("Entry No.");
            }
            group(Result)
            {
                Caption = 'Result';
                field("Quote No."; Rec."Quote No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sales quote created for the request.';

                    trigger OnDrillDown()
                    var
                        SalesHeader: Record "Sales Header";
                    begin
                        if SalesHeader.Get(SalesHeader."Document Type"::Quote, Rec."Quote No.") then
                            Page.Run(Page::"Sales Quote", SalesHeader);
                    end;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer subscription contract created for the request.';

                    trigger OnDrillDown()
                    var
                        CustomerContract: Record "Customer Subscription Contract";
                    begin
                        if CustomerContract.Get(Rec."Contract No.") then
                            Page.Run(0, CustomerContract);
                    end;
                }
                field("Requested By"; Rec."Requested By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who created the request. The contract is assigned to this user.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SendToAgent)
            {
                ApplicationArea = All;
                Caption = 'Send to Agent';
                Image = SendTo;
                ToolTip = 'Let the Subscription Quote Agent complete the request and create the quote (and contract).';

                trigger OnAction()
                var
                    Processor: Codeunit "Sub. Agent Request Processor";
                begin
                    CurrPage.SaveRecord();
                    Processor.SendToAgent(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CreateQuote)
            {
                ApplicationArea = All;
                Caption = 'Create Quote';
                Image = NewSalesQuote;
                ToolTip = 'Create a sales quote for the customer, priced on the contract start date.';

                trigger OnAction()
                var
                    Processor: Codeunit "Sub. Agent Request Processor";
                begin
                    CurrPage.SaveRecord();
                    Processor.CreateQuote(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CreateContract)
            {
                ApplicationArea = All;
                Caption = 'Create Contract';
                Image = MakeAgreement;
                ToolTip = 'Turn the quote into an order, ship the licenses and create the customer subscription contract.';

                trigger OnAction()
                var
                    Processor: Codeunit "Sub. Agent Request Processor";
                begin
                    CurrPage.SaveRecord();
                    Processor.CreateContract(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(SendToAgent_Promoted; SendToAgent) { }
            actionref(CreateQuote_Promoted; CreateQuote) { }
            actionref(CreateContract_Promoted; CreateContract) { }
        }
    }
}
