namespace SubscriptionQuoteAgent;

permissionset 50101 "SQA USER"
{
    Caption = 'Subscription Quote Agent (users)';
    Assignable = true;
    Permissions =
        tabledata "Sub. Agent Request" = RIMD,
        tabledata "Sub. Agent Request Line" = RIMD,
        tabledata "SQA Agent Setup" = R,
        tabledata "MOB TFSubsc.Price" = R,
        table "Sub. Agent Request" = X,
        table "Sub. Agent Request Line" = X,
        table "SQA Agent Setup" = X,
        codeunit "Sub. Quote Pricing Mgt." = X,
        codeunit "Sub. Contract From Quote" = X,
        codeunit "SQA TF Price Lookup" = X,
        codeunit "Sub. Agent Request Processor" = X,
        page "Sub. Agent Request Card" = X,
        page "Sub. Agent Requests" = X,
        page "Sub. Agent Request Subform" = X;
}
