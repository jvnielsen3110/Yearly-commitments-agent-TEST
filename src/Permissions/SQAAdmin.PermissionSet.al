namespace SubscriptionQuoteAgent;

permissionset 50102 "SQA ADMIN"
{
    Caption = 'Subscription Quote Agent (admin)';
    Assignable = true;
    IncludedPermissionSets = "SQA USER";
    Permissions =
        tabledata "SQA Agent Setup" = RIMD,
        page "SQA Agent Setup" = X,
        codeunit "SQA Agent Setup Mgt." = X;
}
