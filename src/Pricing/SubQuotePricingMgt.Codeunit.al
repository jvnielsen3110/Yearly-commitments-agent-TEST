namespace SubscriptionQuoteAgent;

using Microsoft.Pricing.Calculation;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;
using Microsoft.SubscriptionBilling;

/// <summary>
/// Makes sales quotes (and the orders made from them) use the price lists that are valid
/// on the contract start date instead of the document date, and makes the resulting
/// subscriptions start on that date.
/// </summary>
codeunit 50100 "Sub. Quote Pricing Mgt."
{
    Access = Public;

    /// <summary>
    /// Sets the contract start date on the header, saves it, and re-prices the document.
    /// </summary>
    procedure SetContractStartDate(var SalesHeader: Record "Sales Header"; NewStartDate: Date)
    begin
        SalesHeader.Validate("SQA Contract Start Date", NewStartDate);
        SalesHeader.Modify(true);
        ApplyContractStartDatePricing(SalesHeader);
    end;

    /// <summary>
    /// Re-prices every item line on the document as of "SQA Contract Start Date" and sets
    /// "Agreed Sub. Line Start Date" on all customer subscription lines.
    /// </summary>
    procedure ApplyContractStartDatePricing(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        if SalesHeader."SQA Contract Start Date" = 0D then
            exit;
        if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Order]) then
            exit;

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("No.", '<>%1', '');
        if SalesLine.FindSet(true) then
            repeat
                RepriceLine(SalesLine);
            until SalesLine.Next() = 0;

        SetAgreedStartDates(SalesHeader);
    end;

    /// <summary>
    /// Sets "Agreed Sub. Line Start Date" on all subscription lines of the document.
    /// </summary>
    procedure SetAgreedStartDates(SalesHeader: Record "Sales Header")
    var
        SalesSubscriptionLine: Record "Sales Subscription Line";
    begin
        if SalesHeader."SQA Contract Start Date" = 0D then
            exit;
        SalesSubscriptionLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesSubscriptionLine.SetRange("Document No.", SalesHeader."No.");
        if SalesSubscriptionLine.FindSet(true) then
            repeat
                if SalesSubscriptionLine."Agreed Sub. Line Start Date" <> SalesHeader."SQA Contract Start Date" then begin
                    SalesSubscriptionLine.Validate("Agreed Sub. Line Start Date", SalesHeader."SQA Contract Start Date");
                    SalesSubscriptionLine.Modify(true);
                end;
            until SalesSubscriptionLine.Next() = 0;
    end;

    local procedure RepriceLine(var SalesLine: Record "Sales Line")
    begin
        // Re-validating the quantity re-runs the price calculation (which picks up the
        // start date through OnAfterFillBuffer below). Subscription lines whose
        // Calculation Base Type is "Document Price" follow the new unit price.
        SalesLine.Validate(Quantity, SalesLine.Quantity);
        SalesLine.Modify(true);
    end;

    /// <summary>
    /// Price lookup date: when the document carries a contract start date, use it as the
    /// date for finding price list lines (Starting Date / Ending Date).
    /// VERIFY ON 29.0: field name "Document Date" on table "Price Calculation Buffer".
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Line - Price", 'OnAfterFillBuffer', '', false, false)]
    local procedure UseContractStartDateForPrice(var PriceCalculationBuffer: Record "Price Calculation Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
        if SalesHeader."SQA Contract Start Date" = 0D then
            exit;
        if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Order]) then
            exit;
        PriceCalculationBuffer."Document Date" := SalesHeader."SQA Contract Start Date";
    end;
}
