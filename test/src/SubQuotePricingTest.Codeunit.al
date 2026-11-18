namespace SubscriptionQuoteAgent.Test;

using Microsoft.Inventory.Item;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Asset;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using SubscriptionQuoteAgent;

codeunit 50150 "Sub. Quote Pricing Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";

    [Test]
    procedure QuoteUsesPriceValidOnContractStartDate()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SubQuotePricingMgt: Codeunit "Sub. Quote Pricing Mgt.";
        StartDate: Date;
    begin
        // [GIVEN] An item with price 100 until the day before the start date, and 120 from the start date
        StartDate := CalcDate('<+2M-CM>', WorkDate());
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        CreateAllCustomersPrice(Item."No.", 0D, StartDate - 1, 100);
        CreateAllCustomersPrice(Item."No.", StartDate, 0D, 120);

        // [WHEN] A quote is created today with the contract start date set before the line is added
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        SubQuotePricingMgt.SetContractStartDate(SalesHeader, StartDate);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] The line is priced with the price valid on the start date
        Assert.AreEqual(120, SalesLine."Unit Price", 'Unit price must come from the price list line valid on the contract start date.');
    end;

    [Test]
    procedure SettingStartDateRepricesExistingLines()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SubQuotePricingMgt: Codeunit "Sub. Quote Pricing Mgt.";
        StartDate: Date;
    begin
        // [GIVEN] A quote line priced today at 100, and a price of 120 from the start date
        StartDate := CalcDate('<+2M-CM>', WorkDate());
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        CreateAllCustomersPrice(Item."No.", 0D, StartDate - 1, 100);
        CreateAllCustomersPrice(Item."No.", StartDate, 0D, 120);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        Assert.AreEqual(100, SalesLine."Unit Price", 'Precondition: today''s price.');

        // [WHEN] The contract start date is set afterwards
        SubQuotePricingMgt.SetContractStartDate(SalesHeader, StartDate);

        // [THEN] The existing line is re-priced
        SalesLine.Find();
        Assert.AreEqual(120, SalesLine."Unit Price", 'Existing lines must be re-priced on the contract start date.');
    end;

    local procedure CreateAllCustomersPrice(ItemNo: Code[20]; StartingDate: Date; EndingDate: Date; UnitPrice: Decimal)
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // VERIFY: Library - Price Calculation helper signatures on 29.0.
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreatePriceListLine(PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, ItemNo);
        PriceListLine.Validate("Starting Date", StartingDate);
        PriceListLine.Validate("Ending Date", EndingDate);
        PriceListLine.Validate("Unit Price", UnitPrice);
        PriceListLine.Validate(Status, PriceListLine.Status::Active);
        PriceListLine.Modify(true);
        PriceListHeader.Validate(Status, PriceListHeader.Status::Active);
        PriceListHeader.Modify(true);
    end;
}
