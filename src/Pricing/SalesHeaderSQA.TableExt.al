namespace SubscriptionQuoteAgent;

using Microsoft.Sales.Document;

tableextension 50100 "Sales Header SQA" extends "Sales Header"
{
    fields
    {
        field(50100; "SQA Contract Start Date"; Date)
        {
            Caption = 'Contract Start Date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the start date of the customer subscription contract. Prices are taken from the price lists valid on this date, and subscriptions start on this date.';

            // Re-pricing is done by "Sub. Quote Pricing Mgt." after the header is saved,
            // because the price calculation reads the header from the database.
        }
        field(50101; "SQA Request No."; Integer)
        {
            Caption = 'Agent Request No.';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the subscription agent request that created this document.';
        }
    }
}
