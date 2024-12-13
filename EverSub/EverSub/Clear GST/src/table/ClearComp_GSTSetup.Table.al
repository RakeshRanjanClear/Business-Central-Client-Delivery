table 50110 "ClearComp GST Setup"
{
    Caption = 'ClearComp GST Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Code[10])
        {
            Caption = 'Entry No.';
            DataClassification = ToBeClassified;
        }
        field(21; "GST Base Url"; Text[150])
        {
            Caption = 'GST Base Url';
            DataClassification = ToBeClassified;
        }
        field(22; "Auth. Token"; Text[250])
        {
            Caption = 'Auth. Token';
            DataClassification = ToBeClassified;
        }
        field(23; "Sync Invoices"; Option)
        {
            Caption = 'Sync Invoices';
            DataClassification = ToBeClassified;
            OptionMembers = Manual,"While Posting","Job Queue";

            trigger OnValidate()
            var
                GSTMgmtUnit: Codeunit "ClearComp GST Management Unit";
            begin
                if "Sync Invoices" = "Sync Invoices"::"Job Queue" then
                    GSTMgmtUnit.CreateJobQueueEntry()
                else
                    GSTMgmtUnit.DeleteJobQueueEntry();
            end;
        }
        field(24; "Job Queue From Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(30; "Sync. Doc. with IRN"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}