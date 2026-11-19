namespace SubscriptionQuoteAgent;

enum 50110 "Sub. Agent Request Status"
{
    Extensible = true;

    value(0; Open) { Caption = 'Open'; }
    value(1; "Sent to Agent") { Caption = 'Sent to Agent'; }
    value(2; "Quote Created") { Caption = 'Quote Created'; }
    value(3; "Contract Created") { Caption = 'Contract Created'; }
    value(4; Error) { Caption = 'Error'; }
}
