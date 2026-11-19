namespace SubscriptionQuoteAgent;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Document;

/// <summary>
/// Looks up subscription prices in the company's own price table "MOB TFSubsc.Price" (50025)
/// and puts them on sales quote and order lines.
///
/// A price line matches when:
///   - the item matches,
///   - the currency matches (blank on the document = local currency; both blank and the
///     LCY code from General Ledger Setup are tried),
///   - the price date lies within Start Date..End Date (blank = open),
///   - the line quantity is at least the price line's Quantity (quantity tier).
/// The price used is "Monthly Price", so the subscription package lines must use
/// Billing Base Period = 1M with Calculation Base Type = Document Price.
/// If several lines match, the one with the highest minimum quantity wins, then the latest
/// starting date.
///
/// Price date = "SQA Contract Start Date" on the document, otherwise its Order Date.
/// If no line matches, the standard BC price stays on the line.
/// </summary>
codeunit 50102 "SQA TF Price Lookup"
{
    Access = Public;

    procedure FindPrice(ItemNo: Code[20]; CurrencyCode: Code[10]; PriceDate: Date; Quantity: Decimal; var UnitPrice: Decimal): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if (ItemNo = '') or (PriceDate = 0D) then
            exit(false);
        if FindPriceForCurrency(ItemNo, CurrencyCode, PriceDate, Quantity, UnitPrice) then
            exit(true);
        if CurrencyCode = '' then begin
            GeneralLedgerSetup.Get();
            if GeneralLedgerSetup."LCY Code" <> '' then
                exit(FindPriceForCurrency(ItemNo, GeneralLedgerSetup."LCY Code", PriceDate, Quantity, UnitPrice));
        end;
        exit(false);
    end;

    procedure GetPriceDate(SalesHeader: Record "Sales Header"): Date
    begin
        if SalesHeader."SQA Contract Start Date" <> 0D then
            exit(SalesHeader."SQA Contract Start Date");
        exit(SalesHeader."Order Date");
    end;

    /// <summary>
    /// Sets the unit price on the line from the TF price table. Returns false (and leaves
    /// the line untouched) when no TF price exists.
    /// </summary>
    procedure ApplyToSalesLine(var SalesLine: Record "Sales Line"): Boolean
    var
        SalesHeader: Record "Sales Header";
        UnitPrice: Decimal;
    begin
        if SalesLine.Type <> SalesLine.Type::Item then
            exit(false);
        if not (SalesLine."Document Type" in [SalesLine."Document Type"::Quote, SalesLine."Document Type"::Order]) then
            exit(false);
        if not SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
            exit(false);
        if not FindPrice(SalesLine."No.", SalesHeader."Currency Code", GetPriceDate(SalesHeader), SalesLine.Quantity, UnitPrice) then
            exit(false);
        if SalesLine."Unit Price" <> UnitPrice then
            SalesLine.Validate("Unit Price", UnitPrice);
        exit(true);
    end;

    local procedure FindPriceForCurrency(ItemNo: Code[20]; CurrencyCode: Code[10]; PriceDate: Date; Quantity: Decimal; var UnitPrice: Decimal): Boolean
    var
        TFPrice: Record "MOB TFSubsc.Price";
        BestMinQty: Decimal;
        BestStartDate: Date;
        Found: Boolean;
    begin
        // Table 50025 "MOB TFSubsc.Price" (Tasklet Internal): key Item No., Quantity, Currency, Start Date.
        // Quantity is treated as the minimum quantity of a price tier.
        TFPrice.SetRange("Item No.", ItemNo);
        TFPrice.SetRange(Currency, CurrencyCode);
        TFPrice.SetFilter("Start Date", '%1|<=%2', 0D, PriceDate);
        TFPrice.SetFilter("End Date", '%1|>=%2', 0D, PriceDate);
        TFPrice.SetFilter(Quantity, '<=%1', Quantity);
        if not TFPrice.FindSet() then
            exit(false);
        repeat
            if (not Found) or
               (TFPrice.Quantity > BestMinQty) or
               ((TFPrice.Quantity = BestMinQty) and (TFPrice."Start Date" > BestStartDate))
            then begin
                Found := true;
                BestMinQty := TFPrice.Quantity;
                BestStartDate := TFPrice."Start Date";
                UnitPrice := TFPrice."Monthly Price";
            end;
        until TFPrice.Next() = 0;
        exit(Found);
    end;

    /// <summary>
    /// Runs after BC has calculated the standard price (on item no., quantity, dates, etc.)
    /// and replaces it with the TF price when one exists.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterUpdateUnitPrice', '', false, false)]
    local procedure ApplyTFPriceAfterUpdateUnitPrice(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer)
    begin
        ApplyToSalesLine(SalesLine);
    end;
}
