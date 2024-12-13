table 60121 "ClearComp MaxITC Trans. Line"
{
    Caption = 'Clear MAXITC Trans. line';
    fields
    {
        field(1; "Document Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = ' ,Invoice,Credit Memo';
            OptionMembers = " ",Invoice,"Credit Memo";
        }
        field(2; "Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(3; "Line No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Item Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = ' ,G,S';
            OptionMembers = " ",G,S;
        }
        field(21; Description; Text[180])
        {
            DataClassification = ToBeClassified;
        }
        field(22; Quantity; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(23; UOM; Text[20])
        {
            DataClassification = ToBeClassified;
        }
        field(24; "Unit Price"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(25; Discount; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(26; "Taxable Value"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(27; "HSN/SAC code"; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(40; "CGST Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(41; "CGST Value"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(42; "SGST Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(43; "SGST Value"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(44; "IGST Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(45; "IGST Value"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(46; "CESS Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(47; "CESS Value"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(60; "ITC Claim Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = ' ,Not Selected,Ineligible,input,Capital Good,Input Service,Blank';
            OptionMembers = " ","Not Selected",Ineligible,input,"Capital Good","Input Service",Blank;
        }
        field(61; "CGST ITC Claim amt."; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(62; "SGST ITC claim amt."; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(63; "IGST ITC claim amt."; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(64; "CESS ITC claim amt."; Decimal)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Line No.")
        {
        }
    }

    procedure GetNextFreeLine(DocumentType: Option; DocumentNo: Code[20]): Integer
    var
        TransactionLineL: Record "ClearComp MaxITC Trans. Line";
    begin
        TransactionLineL.SETRANGE("Document Type", DocumentType);
        TransactionLineL.SETRANGE("Document No.", DocumentNo);
        IF TransactionLineL.FindLast() THEN
            EXIT(TransactionLineL."Line No." + 10000);
        EXIT(10000);
    end;
}

