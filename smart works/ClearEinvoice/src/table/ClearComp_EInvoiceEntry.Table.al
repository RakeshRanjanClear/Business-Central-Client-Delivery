table 60013 "ClearComp e-Invoice Entry"
{
    DataClassification = ToBeClassified;
    Caption = 'ClearComp e-Invoice Entry';

    fields
    {
        field(1; "API Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = "E-Invoice","E-Way";
            Caption = 'API Type';
        }
        field(2; "Document Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",Invoice,CrMemo,TransferShpt,"Service Invoice","Service Credit Memo","Purch Cr. Memo Hdr","Sales Shipment","Service Shipment","Purch. Inv. Hdr";
            Caption = 'Document Type';
        }
        field(3; "Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Document No.';
        }
        field(21; "Transaction Identifier"; Text[150])
        {
            DataClassification = ToBeClassified;
            Caption = 'Transaction Identifier';
        }
        field(22; Status; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Status';
            OptionMembers = " ",Generated,Fail,Cancelled;
        }
        field(23; "Acknowledgment No."; Code[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Acknowledgment No.';
        }
        field(24; "Acknowledgment Date"; DateTime)
        {
            DataClassification = ToBeClassified;
            Caption = 'Acknowledgment Date';
        }
        field(25; IRN; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'IRN';
        }
        field(26; "Signed Invoice"; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'Signed Invoice';
        }
        field(27; "Signed QR Code"; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'Signed QR Code';
        }
        field(28; "IRN Generated Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'IRN Generated Date';
        }
        field(29; "Created By"; Code[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Created By';
        }
        field(30; "Created Date Time"; DateTime)
        {
            DataClassification = ToBeClassified;
            Caption = 'Created Date Time';
        }
        field(41; "Created Date Time Text"; text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Created Date Time Text';
        }
        field(31; "Response JSON"; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'Response JSON';

        }
        field(32; "Request JSON"; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'Request JSON';
        }
        field(33; "QR Code"; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'QR Code';
        }
        field(34; "QR Code Image"; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'QR Code Image';
        }
        field(35; "IRN Status"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'IRN Status';
        }
        field(36; "Cancel Date"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Cancel Date';
        }
        field(37; "Cancellation Error Message"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Cancellation Error Message';
        }
        field(38; "Cancelled By"; Code[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Cancelled By';
        }
        field(39; "Owner ID"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Owner ID';
        }
        field(40; "GST No."; Text[15])
        {
            DataClassification = ToBeClassified;
            Caption = 'GST No.';
        }
        field(54; "New Vehicle No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'New Vehicle No.';
        }
        field(55; "Vehicle No. Update Remark"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Vehicle No. Update Remark';
            OptionMembers = " ","BREAKDOWN","TRANSSHIPMENT","OTHERS","FIRST_TIME",NATURAL_CALAMITY,ACCIDENT;
            //   OptionCaption = ' ','BREAKDOWN,"TRANSSHIPMENT","OTHERS","FIRST_TIME",NATURAL_CALAMITY,ACCIDENT;
            trigger OnValidate()
            begin
                // if (rec."E-Way Bill Validity" > '') and (rec."Vehicle No. Update Remark" = Rec."Vehicle No. Update Remark"::FIRST_TIME) then begin
                //     error('you can ot use reason as First time when validity period exist.')
                // end;
            end;
        }
        field(57; "Reason of Cancel"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Reason of Cancel';
            OptionMembers = " ",DUPLICATE,DATA_ENTRY_MISTAKE,ORDER_CANCELLED,OTHERS;
        }
        field(58; "Transportation Distance"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Transportation Distance';
        }
        field(60; "User Id"; Code[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'User Id';
        }
        field(61; "Document Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Document Date';
        }
        field(62; "Transaction Type"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Transaction Type';
            OptionMembers = " ",Bill;
        }
        field(63; "Status Text"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Status Text';
        }
        field(66; "Transport Method"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(67; "Shipping Agent Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
        field(68; "LR/RR No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'LR/RR No.';
        }
        field(69; "LR/RR Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'LR/RR Date';
        }
        field(70; "Vehicle No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Vehicle No.';
        }
        field(71; "Mode of Transport"; Text[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Mode of Transport';
        }
        field(72; "New Pin Code From"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'New Pin Code From';
        }
        field(73; "Resp. Status Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Response Status Code';
        }
        field(74; "Distance Remark"; text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Distance Remark By Nic';
        }

        field(75; "Error Description"; Text[1024])
        {
            DataClassification = ToBeClassified;
            Caption = 'Error Description';
        }
        field(76; "Error Description 1"; Text[1024])
        {
            DataClassification = ToBeClassified;
            Caption = 'Error Description';
        }
        field(77; "Error Description 2"; Text[1024])
        {
            DataClassification = ToBeClassified;
            Caption = 'Error Description';
        }
        field(78; "Error Description 3"; Text[1024])
        {
            DataClassification = ToBeClassified;
            Caption = 'Error Description';
        }
        field(79; "Acknowledgment Date Text"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Acknowledgment Date Text';
        }




    }

    keys
    {
        key(Key1; "Document No.", "API Type", "Document Type")
        {
            Clustered = true;
        }
    }
}