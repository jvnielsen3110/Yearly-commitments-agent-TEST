namespace SubscriptionQuoteAgent;

using Microsoft.Inventory.Item;

table 50111 "Sub. Agent Request Line"
{
    Caption = 'Subscription Agent Request Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Request Entry No."; Integer)
        {
            Caption = 'Request Entry No.';
            TableRelation = "Sub. Agent Request";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
            ToolTip = 'Specifies the license item.';

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if Item.Get("Item No.") then
                    Description := Item.Description
                else
                    Description := '';
            end;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(12; Quantity; Decimal)
        {
            Caption = 'Quantity';
            MinValue = 0;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the number of licenses.';
        }
    }

    keys
    {
        key(PK; "Request Entry No.", "Line No.") { Clustered = true; }
    }
}
