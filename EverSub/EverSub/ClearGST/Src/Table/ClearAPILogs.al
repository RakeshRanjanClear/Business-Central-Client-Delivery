table 50106 "Clear API Logs"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Transaction type"; Enum "clear Transaction type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Transaction type';

        }
        field(2; "Document type"; Enum "clear Document Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Document type';
        }
        field(3; "Document No"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Document No.';
        }
        field(5; URL; Code[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL';
        }
        field(6; Status; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Status';
        }
        field(7; Request; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'Request';
        }
        field(8; Response; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'Response';
        }
    }

    keys
    {
        key(Key1; "Transaction type", "Document type", "Document No")
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