table 60012 "ClearComp Interface Msg Log"
{
    DataClassification = ToBeClassified;
    Caption = 'ClearComp Interface Message Log';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(21; "Request Type"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Request Type';
        }
        field(22; "Request"; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'Request';
        }
        field(23; "Response Code"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Response Code';
        }
        field(24; Response; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'Response';
        }
        field(25; "User ID"; Code[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'User ID';
        }
        field(26; "Creation DateTime"; DateTime)
        {
            DataClassification = ToBeClassified;
            Caption = 'Creation DateTime';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        "User ID" := UserId();
        "Creation DateTime" := CurrentDateTime();
    end;
}