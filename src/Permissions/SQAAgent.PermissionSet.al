namespace SubscriptionQuoteAgent;

/// <summary>
/// Permissions for the agent user. Add the Subscription Billing app's own permission set
/// for editing contracts (check its name under Permission Sets in your environment) to
/// IncludedPermissionSets.
/// </summary>
permissionset 50100 "SQA AGENT"
{
    Caption = 'Subscription Quote Agent (agent user)';
    Assignable = true;
    IncludedPermissionSets = "SQA USER",
                             "D365 BASIC",
                             "D365 SALES DOC, EDIT",
                             "D365 SALES DOC, POST";
}
