table 50107 "Clear GST Setup"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Primary; Code[1])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Base URL"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Base URL';
        }
        field(3; "Sales URL"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Sales URL';
        }
        field(4; "Purchase URL"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Purchase URL';
        }
        field(5; "Auth token"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Auth token';
        }
        field(6; "Sales template ID"; Text[150])
        {
            DataClassification = ToBeClassified;
            Caption = 'Sales template ID';
        }
        field(7; "Purchase template ID"; Text[150])
        {
            DataClassification = ToBeClassified;
            Caption = 'Purchase template ID';
        }
        field(8; "Ignore HSN validation"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Ignore HSN validation';
        }
        field(9; "Use Test GSTIN"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Use test GSTIN';
        }
        field(10; "GSTIN1"; Text[15])
        {
            DataClassification = ToBeClassified;
            Caption = 'GSTIN 1';
        }
        field(11; "GSTIN2"; Text[15])
        {
            DataClassification = ToBeClassified;
            Caption = 'GSTIN 2';
        }
        field(12; GSTIN3; Text[15])
        {
            DataClassification = ToBeClassified;
            Caption = 'GSTIN 3';
        }
    }

    keys
    {
        key(Key1; Primary)
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