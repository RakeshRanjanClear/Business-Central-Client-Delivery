table 50112 "ClearComp GST Trans. Line"
{
    Caption = 'ClearComp GST Trans. Line';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Transaction Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = SALE,PURCHASE;
            Caption = 'Transaction Type';
        }
        field(2; "Document Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = Invoice,"Credit Memo";
            Caption = 'Document Type';
        }
        field(3; "Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Document No.';
        }
        field(4; "Line No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Line No.';
        }
        field(21; "Zero Tax Category"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ","Nil Rated",Exempted,"Non GST Supply","Supply from Composition Dealer","UIN Holder";
            Caption = 'Zero Tax Category';
        }
        field(22; Description; Text[200])
        {
            DataClassification = ToBeClassified;
            Caption = 'Description';
        }
        field(23; Quantity; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quantity';
        }
        field(24; "Unit Price"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Unit Price';
        }
        field(25; UOM; Text[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'UOM';
        }
        field(26; "Total Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Total Value';
        }
        field(27; "Taxable Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Taxable Value';
        }
        field(28; "SGST Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'SGST Rate';
        }
        field(29; "SGST Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'SGST Value';
        }
        field(30; "Cess Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Cess Rate';
        }
        field(31; "Cess Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Cess Value';
        }
        field(32; "CGST Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'CGST Rate';
        }
        field(33; "CGST Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'CGST Value';
        }
        field(34; "IGST Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'IGST Rate';
        }
        field(35; "IGST Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'IGST Value';
        }
        field(36; "GST Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",GOODS,SERVICES;
            Caption = 'GST Type';
        }
        field(37; "GST Code"; Code[8])
        {
            DataClassification = ToBeClassified;
            Caption = 'GST Code';
        }
        field(38; Discount; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Discount';
        }
        field(39; "TCS_CGST Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'TCS_CGST Rate';
        }
        field(40; "TCS_CGST Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'TCS_CGST Value';
        }
        field(41; "TCS_IGST Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'TCS_IGST Rate';
        }
        field(42; "TCS_IGST Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'TCS_IGST Value';
        }
        field(43; "TCS_SGST Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'TCS_SGST Rate';
        }
        field(44; "TDS_CGST Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'TDS_CGST Rate';
        }
        field(45; "TDS_CGST Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'TDS_CGST Value';
        }
        field(46; "TDS_IGST Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'TDS_IGST Rate';
        }
        field(47; "TDS_IGST Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'TDS_IGST Value';
        }
        field(48; "TDS_SGST Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'TDS_SGST Rate';
        }
        field(49; "TDS_SGST Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'TDS_SGST Value';
        }
        field(50; "ITC Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ","Not Selected",Ineligible,input,"Capital Good","Input Service",Blank;
            Caption = 'ITC Type';
        }
        field(51; "ITC Claim Percentage"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'ITC Claim Percentage';
        }
        field(52; "CGST Total ITC"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'CGST Total ITC';
        }
        field(53; "SGST Total ITC"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'SGST Total ITC';
        }
        field(54; "IGST Total ITC"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'IGST Total ITC';
        }
        field(55; "CESS Total ITC"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'CESS Total ITC';
        }
        field(56; "CGST Claimed ITC"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'CGST Claimed ITC';
        }
        field(57; "SGST Claimed ITC"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'SGST Claimed ITC';
        }
        field(58; "IGST Claimed ITC"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'IGST Claimed ITC';
        }
        field(59; "CESS Claimed ITC"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'CESS Claimed ITC';
        }
        field(60; Selected; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Selected';
        }
        field(61; "TCS_SGST Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'TCS_SGST Value';
        }
    }

    keys
    {
        key(Key1; "Transaction Type", "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }
    procedure GetNextFreeLine(TransactionType: Option; DocumentType: Option; DocumentNo: Code[20]): Integer
    var
        TransactionLineL: Record "ClearComp GST Trans. Line";
    begin
        TransactionLineL.SetRange("Transaction Type", TransactionType);
        TransactionLineL.SetRange("Document Type", DocumentType);
        TransactionLineL.SetRange("Document No.", "Document No.");
        if TransactionLineL.FindLast() then
            exit(TransactionLineL."Line No." + 10000);
        exit(10000);
    end;
}