namespace SubscriptionQuoteAgent;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

/// <summary>
/// Slim role center for the agent: it only needs the requests, quotes and customers.
/// </summary>
page 50125 "SQA Agent Role Center"
{
    PageType = RoleCenter;
    Caption = 'Subscription Quote Agent';

    actions
    {
        area(Embedding)
        {
            action(Requests)
            {
                ApplicationArea = All;
                Caption = 'Subscription Agent Requests';
                RunObject = page "Sub. Agent Requests";
                ToolTip = 'Open the subscription agent requests.';
            }
            action(SalesQuotes)
            {
                ApplicationArea = All;
                Caption = 'Sales Quotes';
                RunObject = page "Sales Quotes";
                ToolTip = 'Open the sales quotes.';
            }
            action(Customers)
            {
                ApplicationArea = All;
                Caption = 'Customers';
                RunObject = page "Customer List";
                ToolTip = 'Open the customer list.';
            }
        }
    }
}
