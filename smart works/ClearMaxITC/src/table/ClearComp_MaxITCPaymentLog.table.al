table 60117 "ClearComp MaxITC Payment Log"
{
    Caption = 'Clear MaxITC payment log';
    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = ToBeClassified;
        }
        field(2; DocumentID; Text[100])
        {
            DataClassification = ToBeClassified;
            TableRelation = "ClearComp MaxITC Payment block".DocumentID;
        }
        field(10; "Document reference No"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(11; "Payment Action"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(12; "G/L Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(13; "Creation DateTime"; DateTime)
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

