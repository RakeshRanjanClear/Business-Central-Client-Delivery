table 60120 "ClearComp MaxITC Trans. Header"
{
    Caption = 'Clear MAXITC trans. header';
    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            DataClassification = ToBeClassified;
            OptionCaption = ' ,Invoice,Credit Memo';
            OptionMembers = " ",Invoice,"Credit Memo";
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = ToBeClassified;
        }
        field(3; "Posting date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Supplier Name"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(21; "Supplier GSTIN"; Text[15])
        {
            DataClassification = ToBeClassified;
        }
        field(22; "Supplier Address"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(23; "Supplier Zip Code"; Text[20])
        {
            DataClassification = ToBeClassified;
        }
        field(24; "Supplier City"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(25; "Supplier State"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(26; "Supplier Country"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(27; "Supplier Phone No."; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(40; "Credit/Debit Note No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(41; "Credit/Debit Note date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(42; "Credit/Debit Note Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = ' ,CREDIT,DEBIT';
            OptionMembers = " ",CREDIT,DEBIT;
        }
        field(43; "Reason for Issuing CDN"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(60; "Is Bill of Supply"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(61; "Invoice Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = ' ,Nil Rated,Exempted,Non-GST';
            OptionMembers = " ","Nil Rated",Exempted,"Non-GST";
        }
        field(62; "RCM applicable"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(63; "Is Advance"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(70; "Type of Import"; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = ' ,Goods,Service,SEZ';
            OptionMembers = " ",Goods,Services,SEZ;
        }
        field(71; "Bill of Entry No."; Text[20])
        {
            DataClassification = ToBeClassified;
        }
        field(72; "Bill of Entry Port Code"; Text[20])
        {
            DataClassification = ToBeClassified;
        }
        field(73; "Bill of Entry Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(80; "Is document Cancelled"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(81; "Is Supplier a Comp. dealer"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90; "Return filing Month"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(91; "Return filing quarter"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(95; "My GSTIN"; Text[15])
        {
            DataClassification = ToBeClassified;
        }
        field(96; "Place of supply"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(105; "Advance payment no."; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(106; "Advance payment date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(107; "Advance payment amount"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(120; "Goods receipt No."; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(121; "Goods receipt date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(122; "Goods receipt quantity"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(123; "Goods receipt amount"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(124; "Payment due date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(125; "Vendor Code"; Code[30])
        {
            DataClassification = ToBeClassified;
        }
        field(130; TCS; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(131; "Total Transaction Value"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(150; Delete; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(151; "Voucher Number"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(152; "Voucher Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(160; Selected; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(180; Uploaded; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(181; WorkFlowID; Text[250])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(key1; "Document Type", "Document No.")
        {
        }
    }
    trigger OnDelete()
    var
        TransLine: Record "ClearComp MaxITC Trans. Line";
    begin
        TransLine.SetRange("Document Type", Rec."Document Type");
        TransLine.SetRange("Document No.", Rec."Document No.");
        if TransLine.FindFirst() then
            TransLine.DeleteAll();
    end;
}

