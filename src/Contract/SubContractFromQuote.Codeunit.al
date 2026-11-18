namespace SubscriptionQuoteAgent;

using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.SubscriptionBilling;

/// <summary>
/// Turns an accepted, start-date priced quote for software licenses into an active
/// Customer Subscription Contract, using the standard Subscription Billing flow:
/// quote -> order -> post shipment (creates subscriptions) -> contract -> assign lines.
/// </summary>
codeunit 50101 "Sub. Contract From Quote"
{
    Access = Public;

    var
        NoStartDateErr: Label 'Sales quote %1 has no Contract Start Date.', Comment = '%1 = quote no.';
        NoLinesErr: Label 'Sales quote %1 has no item lines.', Comment = '%1 = quote no.';
        NoSubscriptionLinesErr: Label 'Line %1 (item %2) on sales quote %3 has no customer subscription line invoiced via contract. Check the item''s subscription package.', Comment = '%1 = line no., %2 = item no., %3 = quote no.';
        ZeroPriceErr: Label 'Line %1 (item %2) on sales quote %3 has no unit price on %4. Check the sales price list.', Comment = '%1 = line no., %2 = item no., %3 = quote no., %4 = start date';
        NoSubscriptionsCreatedErr: Label 'Posting the shipment of sales order %1 did not create any subscriptions.', Comment = '%1 = order no.';

    /// <summary>
    /// Creates the contract from the quote and returns the new contract no.
    /// </summary>
    procedure CreateContractFromQuote(var SalesQuoteHeader: Record "Sales Header"; ContractType: Code[10]; ContractDescription: Text[100]; AssignedUserId: Code[50]) ContractNo: Code[20]
    var
        SalesOrderHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        CheckQuote(SalesQuoteHeader);
        CustomerNo := SalesQuoteHeader."Sell-to Customer No.";

        MakeOrder(SalesQuoteHeader, SalesOrderHeader);
        ShipOrder(SalesOrderHeader);
        ContractNo := CreateContractForOrder(SalesOrderHeader."No.", CustomerNo, ContractType, ContractDescription, AssignedUserId);
    end;

    /// <summary>
    /// Validates that the quote can become a contract.
    /// </summary>
    procedure CheckQuote(SalesQuoteHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        SalesSubscriptionLine: Record "Sales Subscription Line";
    begin
        SalesQuoteHeader.TestField("Document Type", SalesQuoteHeader."Document Type"::Quote);
        SalesQuoteHeader.TestField("Sell-to Customer No.");
        if SalesQuoteHeader."SQA Contract Start Date" = 0D then
            Error(NoStartDateErr, SalesQuoteHeader."No.");

        SalesLine.SetRange("Document Type", SalesQuoteHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesQuoteHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("No.", '<>%1', '');
        if not SalesLine.FindSet() then
            Error(NoLinesErr, SalesQuoteHeader."No.");
        repeat
            if SalesLine."Unit Price" <= 0 then
                Error(ZeroPriceErr, SalesLine."Line No.", SalesLine."No.", SalesQuoteHeader."No.", SalesQuoteHeader."SQA Contract Start Date");

            SalesSubscriptionLine.Reset();
            SalesSubscriptionLine.SetRange("Document Type", SalesLine."Document Type");
            SalesSubscriptionLine.SetRange("Document No.", SalesLine."Document No.");
            SalesSubscriptionLine.SetRange("Document Line No.", SalesLine."Line No.");
            SalesSubscriptionLine.SetRange(Partner, SalesSubscriptionLine.Partner::Customer);
            SalesSubscriptionLine.SetRange("Invoicing via", SalesSubscriptionLine."Invoicing via"::Contract);
            if SalesSubscriptionLine.IsEmpty() then
                Error(NoSubscriptionLinesErr, SalesLine."Line No.", SalesLine."No.", SalesQuoteHeader."No.");
        until SalesLine.Next() = 0;
    end;

    local procedure MakeOrder(var SalesQuoteHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header")
    var
        SalesQuoteToOrder: Codeunit "Sales-Quote to Order";
        SubQuotePricingMgt: Codeunit "Sub. Quote Pricing Mgt.";
    begin
        SalesQuoteToOrder.Run(SalesQuoteHeader);
        SalesQuoteToOrder.GetSalesOrderHeader(SalesOrderHeader);
        // Table extension fields have the same IDs on quote and order, so the start date
        // is carried over. Make sure the agreed start dates are on the order lines too.
        SubQuotePricingMgt.SetAgreedStartDates(SalesOrderHeader);
    end;

    local procedure ShipOrder(var SalesOrderHeader: Record "Sales Header")
    begin
        // Subscription Items are non-inventory: shipping creates the subscriptions,
        // sets the line to invoiced and posts zero-value entries. No sales invoice is made;
        // billing happens later through the contract.
        SalesOrderHeader.Ship := true;
        SalesOrderHeader.Invoice := false;
        Codeunit.Run(Codeunit::"Sales-Post", SalesOrderHeader);
    end;

    local procedure CreateContractForOrder(SalesOrderNo: Code[20]; CustomerNo: Code[20]; ContractType: Code[10]; ContractDescription: Text[100]; AssignedUserId: Code[50]): Code[20]
    var
        CustomerContract: Record "Customer Subscription Contract";
        SubscriptionHeader: Record "Subscription Header";
        SubscriptionLine: Record "Subscription Line";
        TempSubscriptionLine: Record "Subscription Line" temporary;
    begin
        SubscriptionHeader.SetRange("Sales Order No.", SalesOrderNo);
        SubscriptionHeader.SetRange("End-User Customer No.", CustomerNo);
        if not SubscriptionHeader.FindSet() then
            Error(NoSubscriptionsCreatedErr, SalesOrderNo);
        repeat
            SubscriptionLine.SetRange("Subscription Header No.", SubscriptionHeader."No.");
            SubscriptionLine.SetRange(Partner, SubscriptionLine.Partner::Customer);
            SubscriptionLine.SetRange("Subscription Contract No.", '');
            if SubscriptionLine.FindSet() then
                repeat
                    TempSubscriptionLine := SubscriptionLine;
                    TempSubscriptionLine.Insert();
                until SubscriptionLine.Next() = 0;
        until SubscriptionHeader.Next() = 0;

        CustomerContract.Init();
        CustomerContract.Insert(true);
        CustomerContract.SetHideValidationDialog(true);
        CustomerContract.Validate("Sell-to Customer No.", CustomerNo);
        if ContractType <> '' then
            CustomerContract.Validate("Contract Type", ContractType);
        if ContractDescription <> '' then
            CustomerContract.Validate(Description, ContractDescription); // VERIFY field name on 29.0
        if AssignedUserId <> '' then
            CustomerContract.Validate("Assigned User ID", AssignedUserId);
        CustomerContract.Modify(true);

        CustomerContract.CreateCustomerContractLinesFromServiceCommitments(TempSubscriptionLine);
        exit(CustomerContract."No.");
    end;
}
