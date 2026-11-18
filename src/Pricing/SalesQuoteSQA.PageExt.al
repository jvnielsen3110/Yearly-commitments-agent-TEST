namespace SubscriptionQuoteAgent;

using Microsoft.Sales.Document;

pageextension 50100 "Sales Quote SQA" extends "Sales Quote"
{
    layout
    {
        addafter("Order Date")
        {
            field("SQA Contract Start Date"; Rec."SQA Contract Start Date")
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    SubQuotePricingMgt: Codeunit "Sub. Quote Pricing Mgt.";
                begin
                    CurrPage.SaveRecord();
                    SubQuotePricingMgt.ApplyContractStartDatePricing(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(SQAApplyStartDatePricing)
            {
                ApplicationArea = All;
                Caption = 'Apply Contract Start Date Pricing';
                Image = Price;
                ToolTip = 'Re-price all lines with the price lists valid on the contract start date and set the subscription start date.';

                trigger OnAction()
                var
                    SubQuotePricingMgt: Codeunit "Sub. Quote Pricing Mgt.";
                begin
                    CurrPage.SaveRecord();
                    SubQuotePricingMgt.ApplyContractStartDatePricing(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(SQACreateContract)
            {
                ApplicationArea = All;
                Caption = 'Create Subscription Contract';
                Image = MakeAgreement;
                ToolTip = 'Turn the quote into an order, ship the licenses and create the customer subscription contract.';

                trigger OnAction()
                var
                    SubContractFromQuote: Codeunit "Sub. Contract From Quote";
                    ContractNo: Code[20];
                    ContractCreatedMsg: Label 'Customer subscription contract %1 was created.', Comment = '%1 = contract no.';
                begin
                    CurrPage.SaveRecord();
                    ContractNo := SubContractFromQuote.CreateContractFromQuote(Rec, '', '', CopyStr(UserId(), 1, 50));
                    Message(ContractCreatedMsg, ContractNo);
                end;
            }
        }
    }
}
