table 60004 "Clear Trans line"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Transaction Type"; Enum "Clear Transaction type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Transaction type';
            TableRelation = "Clear Trans Hdr"."Transaction Type";
        }
        field(2; "Document Type"; Enum "Clear Document Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Document type';
            TableRelation = "Clear Trans Hdr"."Document Type";
        }
        field(3; "Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Document No.';
            TableRelation = "Clear Trans Hdr"."Document No.";
        }
        field(4; "Line num"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Line num';
        }
        field(5; "Item no"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Item no';
        }
        field(6; "Item description"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Item description';
        }
        field(7; "Item category"; Enum "Clear Item Category")
        {
            DataClassification = ToBeClassified;
            Caption = 'Item Category';
        }
        field(8; "HSNSAC Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'HSNSAC code';
        }
        field(9; "Item quantity"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Item quantity';
        }
        field(10; "UOM"; Text[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Unit of measure';
        }
        field(11; "Unit Price"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Unit Price';
        }
        field(12; "Discount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Discount';
        }
        field(13; "Zero tax category"; Enum "Clear Zero Tax Category")
        {
            DataClassification = ToBeClassified;
            Caption = 'Zero tax Category';
        }
        field(14; "CGST rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'CGST rate';
        }
        field(15; "CGST amt"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'CGST amt';
        }
        field(16; "SGST rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'SGST rate';
        }
        field(17; "SGST amt"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'SGST amt';
        }
        field(18; "IGST rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'IGST rate';
        }
        field(19; "IGST amt"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'IGST amt';
        }
        field(20; "Cess rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Cess rate';
        }
        field(21; "Cess amt"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Cess amt';
        }
        field(22; "Taxable amount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Taxable amount';
        }
        field(29; "ITC claim type"; Enum "Clear ITC Claim type")
        {
            DataClassification = ToBeClassified;
            Caption = 'ITC Claim type';
        }
        field(30; "ITC CGST amt"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'ITC CGST amt';
        }
        field(31; "ITC SGST amt"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'ITC SGST amt';
        }
        field(32; "ITC IGST amt"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'ITC IGST amt';
        }
        field(33; "ITC CESS amt"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'ITC CESS amt';
        }

    }

    keys
    {
        key(Key1; "Transaction Type", "Document Type", "Document No.", "Line num")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}