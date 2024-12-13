table 60115 "ClearComp MaxITC Logs"
{
    // version MaxITC
    Caption = 'Clear MaxITC logs';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = ToBeClassified;
        }
        field(3; "Request Type"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(4; Request; BLOB)
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Response Code"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(6; Response; BLOB)
        {
            DataClassification = ToBeClassified;
        }
        field(7; "User ID"; Code[50])
        {
            DataClassification = ToBeClassified;
        }
        field(8; DateTime; DateTime)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
        }
    }

    fieldgroups
    {
    }
}

