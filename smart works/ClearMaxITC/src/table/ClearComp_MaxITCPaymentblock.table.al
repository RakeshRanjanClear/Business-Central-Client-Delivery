table 60116 "ClearComp MaxITC Payment block"
{
    Caption = 'Clear MaxITC payment block';
    fields
    {
        field(1; DocumentID; Text[100])
        {
            Caption = 'Document ID';
            DataClassification = ToBeClassified;
        }
        field(10; DocumentReferenceNo; Text[100])
        {
            Caption = 'Document Reference No.';
            DataClassification = ToBeClassified;
        }
        field(11; "Created Date time"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(20; PaymentAction; Text[30])
        {
            Caption = 'Payment Action';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; DocumentID)
        {
        }
    }

    fieldgroups
    {
    }
}

