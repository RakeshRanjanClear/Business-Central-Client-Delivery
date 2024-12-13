table 60119 "ClearComp MaxITC Setup"
{
    Caption = 'Clear MAXITC setup';
    fields
    {
        field(1; "Primary Code"; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Base URL"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(21; "configuration URL"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(22; "Pre-Signed URL"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(23; "Org Unit"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(24; "Auth Token"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(25; "Trigger URL"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(26; "Check status URL"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(30; "Payment blocking Account type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ","G/L Account";

            trigger OnValidate()
            begin
                IF "Payment blocking Account type" <> xRec."Payment blocking Account type" THEN
                    CLEAR("Payment blocking Account No.");
            end;
        }
        field(31; "Payment blocking Account No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = IF ("Payment blocking Account type" = CONST("G/L Account")) "G/L Account"."No.";
        }
        field(50; "Created By"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(51; "Created At"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(52; "Updated By"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(53; "Updated At"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(54; "User Email"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(55; "User External ID"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(56; "Custom Template ID"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(57; "Recon Type"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(58; "Section Names"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(59; "Storage Proxy enabled"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(60; Active; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(61; "Pull return period start"; Text[10])
        {
            DataClassification = ToBeClassified;
        }
        field(62; "Pull return period end"; Text[10])
        {
            DataClassification = ToBeClassified;
        }
        field(63; "Recon return period start"; Text[10])
        {
            DataClassification = ToBeClassified;
        }
        field(64; "Recon return period end"; Text[10])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; "Primary Code")
        {
        }
    }

    fieldgroups
    {
    }
}

