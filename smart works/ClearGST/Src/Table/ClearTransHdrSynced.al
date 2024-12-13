table 60003 "Clear Trans Hdr Synced"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Transaction Type"; Enum "Clear Transaction type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Transaction type';
        }
        field(2; "Document Type"; Enum "Clear Document Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Document type';
        }
        field(3; "Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Document No.';
        }
        field(4; "Sync Status"; Enum "Clear Sync status")
        {
            DataClassification = ToBeClassified;
            Caption = 'Sync Status';
        }
        field(5; "Posting date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Posting date';
        }
        field(6; "Supplier GSTIN"; Code[15])
        {
            DataClassification = ToBeClassified;
            Caption = 'Supplier GSTIN';
        }
        field(7; "Supplier Name"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Supplier Name';
        }
        field(8; "Supplier Address"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Supplier Address';
        }
        field(9; "Supplier State"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Supplier State';
        }
        field(10; "Receiver GSTIN"; Code[15])
        {
            DataClassification = ToBeClassified;
            Caption = 'Receiver GSTIN';
        }
        field(11; "Receiver Name"; Text[150])
        {
            DataClassification = ToBeClassified;
            Caption = 'Receiver Name';
        }
        field(12; "Receiver address"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Receiver address';
        }
        field(13; "Receiver State"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Receiver State';
        }
        field(14; "Place of Supply"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Place of Supply';
        }
        field(15; "Is bill of supply"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is bill of supply';
        }
        field(16; "Is document cancelled"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is document cancelled';
        }
        field(17; "Is TDS deducted"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is TDS deducted';
        }
        field(18; "Linked advance document no."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Linked advance document no.';
        }
        field(19; "Linked advance document date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Linked advance document no.';
        }
        field(20; "Linked invoice no."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Linked invoice no.';
        }
        field(21; "Linked invoice date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Linked invoice date';
        }
        field(22; "Export type"; Enum "Clear Export type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Export type';
        }
        field(23; "Export bill no."; text[7])
        {
            DataClassification = ToBeClassified;
            Caption = 'Export bill no.';
        }
        field(24; "Export bill date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Export bill date';
        }
        field(25; "Export Port Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Export port code';
        }
        field(26; "Ecommerce GSTIN"; Code[15])
        {
            DataClassification = ToBeClassified;
            Caption = 'Ecommerce GSTIN';
        }
        field(27; "Is reverse charge applicable"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is reverse charge applicable';
        }
        field(28; "Customer TaxpayerType"; Enum "Clear Customer TaxPayer Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Customer TaxPayer type';
        }
        field(34; "Import type"; enum "Clear Import Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Import type';
        }
        field(35; "Import bill no"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Import bill no';
        }
        field(36; "Import bill date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Import bill date';
        }
        field(37; "Import port code"; Code[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Import port code';
        }
        field(38; "Is supplier Composition dealer"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Supplier Composition dealer';
        }
        field(40; "Vendor Invoice number"; Code[35])
        {
            DataClassification = ToBeClassified;
            Caption = 'Vendor Invoice number';
        }
    }

    keys
    {
        key(Key1; "Transaction Type", "Document Type", "Document No.")
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