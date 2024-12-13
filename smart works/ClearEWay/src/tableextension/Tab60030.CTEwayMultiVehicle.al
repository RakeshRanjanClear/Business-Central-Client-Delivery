table 60030 "CT- E-way Multi Vehicle"
{
    Caption = 'CT- E-way Multi Vehicle';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "API Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = "E-Invoice","E-Way";
            Caption = 'API Type';
        }
        field(2; "Document Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",Invoice,CrMemo,TransferShpt,"Service Invoice","Service Credit Memo","Purch Cr. Memo Hdr","Sales Shipment","Service Shipment","Purch. Inv. Hdr";
            Caption = 'Document Type';
        }
        field(3; "Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Document No.';
        }
        field(4; "E-way Bill No."; Code[50])
        {
            Caption = 'E-way Bill No.';
        }
        field(5; "Vehicle No."; Code[20])
        {
            Caption = 'Vehicle No.';
        }
        field(6; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(7; "Group No."; Integer)
        {
            Caption = 'Group No.';
        }
        field(8; "LR/RR No."; code[20])
        {
            Caption = 'LR/RR No.';
        }
        field(9; "LR/RR Date"; Date)
        {
            Caption = 'LR/RR Date';
        }
        field(10; "Line No."; Integer)
        {

        }
    }
    keys
    {
        key(PK; "API Type", "Document Type", "Document No.", "E-way Bill No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
