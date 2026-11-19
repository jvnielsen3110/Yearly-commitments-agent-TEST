namespace SubscriptionQuoteAgent;

using Microsoft.Sales.Document;
using System.Agents;

/// <summary>
/// Deterministic steps behind the request page actions. The agent fills the request and
/// runs these actions; users can run them by hand too.
/// </summary>
codeunit 50110 "Sub. Agent Request Processor"
{
    Access = Public;

    var
        MissingCustomerErr: Label 'Request %1 has no customer.', Comment = '%1 = request entry no.';
        MissingStartDateErr: Label 'Request %1 has no contract start date.', Comment = '%1 = request entry no.';
        MissingLinesErr: Label 'Request %1 has no lines with an item and a quantity.', Comment = '%1 = request entry no.';
        QuoteExistsErr: Label 'Request %1 already has quote %2.', Comment = '%1 = request entry no., %2 = quote no.';
        NoQuoteErr: Label 'Request %1 has no quote yet. Create the quote first.', Comment = '%1 = request entry no.';
        ContractExistsErr: Label 'Request %1 already has contract %2.', Comment = '%1 = request entry no., %2 = contract no.';
        NothingToSendErr: Label 'Enter a request text, or a customer, start date and lines, before sending the request to the agent.';
        NoAgentErr: Label 'No Subscription Quote Agent is set up and active. Set it up on the Agents page first.';
        TaskTitleTxt: Label 'Subscription request %1', Comment = '%1 = request entry no.';
        TaskMessageTxt: Label 'SQA-REQUEST: %1\Process subscription agent request %1. Open it on the Subscription Agent Request card, complete the fields from the request text, then run Create Quote%2.\\Request text:\%3', Comment = '%1 = entry no., %2 = contract instruction, %3 = request text';
        AndContractTxt: Label ' and then Create Contract';

    /// <summary>
    /// Creates a sales quote for the request, priced on the contract start date.
    /// </summary>
    procedure CreateQuote(var Request: Record "Sub. Agent Request")
    var
        SalesHeader: Record "Sales Header";
        RequestLine: Record "Sub. Agent Request Line";
        SubQuotePricingMgt: Codeunit "Sub. Quote Pricing Mgt.";
        LineNo: Integer;
    begin
        if Request."Quote No." <> '' then
            Error(QuoteExistsErr, Request."Entry No.", Request."Quote No.");
        CheckInputs(Request);

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.Insert(true);
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Sell-to Customer No.", Request."Customer No.");
        if Request."Your Reference" <> '' then
            SalesHeader.Validate("Your Reference", Request."Your Reference");
        SalesHeader."SQA Request No." := Request."Entry No.";
        SalesHeader.Modify(true);
        // Store the start date before adding lines so that every line is priced on it.
        SubQuotePricingMgt.SetContractStartDate(SalesHeader, Request."Contract Start Date");

        RequestLine.SetRange("Request Entry No.", Request."Entry No.");
        RequestLine.SetFilter("Item No.", '<>%1', '');
        RequestLine.SetFilter(Quantity, '>0');
        if RequestLine.FindSet() then
            repeat
                LineNo += 10000;
                AddQuoteLine(SalesHeader, LineNo, RequestLine, Request."Line Discount %");
            until RequestLine.Next() = 0;

        // Subscription lines are created as lines are added; set their agreed start date.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SubQuotePricingMgt.SetAgreedStartDates(SalesHeader);

        Request."Quote No." := SalesHeader."No.";
        Request.Status := Request.Status::"Quote Created";
        Request."Last Error" := '';
        Request.Modify(true);

        if Request."Create Contract Immediately" then
            CreateContract(Request);
    end;

    /// <summary>
    /// Turns the request's quote into an active customer subscription contract.
    /// </summary>
    procedure CreateContract(var Request: Record "Sub. Agent Request")
    var
        SalesHeader: Record "Sales Header";
        SubContractFromQuote: Codeunit "Sub. Contract From Quote";
    begin
        if Request."Contract No." <> '' then
            Error(ContractExistsErr, Request."Entry No.", Request."Contract No.");
        if Request."Quote No." = '' then
            Error(NoQuoteErr, Request."Entry No.");

        SalesHeader.Get(SalesHeader."Document Type"::Quote, Request."Quote No.");
        Request."Contract No." := SubContractFromQuote.CreateContractFromQuote(SalesHeader, Request."Contract Type", Request.Description, Request."Requested By");
        Request.Status := Request.Status::"Contract Created";
        Request."Last Error" := '';
        Request.Modify(true);
    end;

    /// <summary>
    /// Creates an agent task for the request. Messages created here come from inside
    /// Business Central, so they skip the approval step.
    /// </summary>
    procedure SendToAgent(var Request: Record "Sub. Agent Request")
    var
        AgentSetup: Record "SQA Agent Setup";
        AgentTask: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        ContractInstruction: Text;
    begin
        if (Request."Request Text" = '') and not HasStructuredInputs(Request) then
            Error(NothingToSendErr);
        if not AgentSetup.FindActiveAgent() then
            Error(NoAgentErr);

        if Request."Create Contract Immediately" then
            ContractInstruction := AndContractTxt;

        AgentTaskMessageBuilder
            .Initialize(CopyStr(Request."Requested By", 1, 250), StrSubstNo(TaskMessageTxt, Request."Entry No.", ContractInstruction, Request."Request Text"))
            .SetRequiresReview(false);

        AgentTask := AgentTaskBuilder
            .Initialize(AgentSetup."User Security ID", CopyStr(StrSubstNo(TaskTitleTxt, Request."Entry No."), 1, 150))
            .SetExternalId(StrSubstNo('SQA-%1', Request."Entry No."))
            .AddTaskMessage(AgentTaskMessageBuilder)
            .Create();

        Request."Agent Task ID" := AgentTask.ID;
        Request.Status := Request.Status::"Sent to Agent";
        Request.Modify(true);
    end;

    procedure CheckInputs(Request: Record "Sub. Agent Request")
    var
        RequestLine: Record "Sub. Agent Request Line";
    begin
        if Request."Customer No." = '' then
            Error(MissingCustomerErr, Request."Entry No.");
        if Request."Contract Start Date" = 0D then
            Error(MissingStartDateErr, Request."Entry No.");
        RequestLine.SetRange("Request Entry No.", Request."Entry No.");
        RequestLine.SetFilter("Item No.", '<>%1', '');
        RequestLine.SetFilter(Quantity, '>0');
        if RequestLine.IsEmpty() then
            Error(MissingLinesErr, Request."Entry No.");
    end;

    procedure HasStructuredInputs(Request: Record "Sub. Agent Request"): Boolean
    var
        RequestLine: Record "Sub. Agent Request Line";
    begin
        if (Request."Customer No." = '') or (Request."Contract Start Date" = 0D) then
            exit(false);
        RequestLine.SetRange("Request Entry No.", Request."Entry No.");
        RequestLine.SetFilter("Item No.", '<>%1', '');
        RequestLine.SetFilter(Quantity, '>0');
        exit(not RequestLine.IsEmpty());
    end;

    local procedure AddQuoteLine(SalesHeader: Record "Sales Header"; LineNo: Integer; RequestLine: Record "Sub. Agent Request Line"; LineDiscountPct: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        // Same order as entering the line on the page: validate, then insert. Subscription
        // Billing adds the standard subscription packages to the line.
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", RequestLine."Item No.");
        SalesLine.Validate(Quantity, RequestLine.Quantity);
        if LineDiscountPct <> 0 then
            SalesLine.Validate("Line Discount %", LineDiscountPct);
        SalesLine.Insert(true);
    end;
}
