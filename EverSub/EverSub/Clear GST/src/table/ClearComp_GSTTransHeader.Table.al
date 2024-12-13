table 50111 "ClearComp GST Trans. Header"
{
    Caption = 'ClearComp GST Trans. Header';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Transaction Type"; option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = SALE,PURCHASE;
            Caption = 'Transaction Type';
        }
        field(2; "Document Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = Invoice,"Credit Memo";
            Caption = 'Document Type';
        }
        field(3; "Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Document No.';
        }
        field(21; "External Document no."; code[35])
        {
            DataClassification = ToBeClassified;
            Caption = 'External Document no.';
        }
        field(22; "Posting Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Posting Date';
        }
        field(23; "Due Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Due Date';
        }
        field(24; "Status"; option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = Open,Synced,Error,Deleted;
            Caption = 'Status';
        }
        field(25; "Source"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = USER,GOVERNMENT;
            Caption = 'Source';
        }
        field(26; "Place of Supply"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Place of Supply';
        }
        field(27; "Reverse Charge Applicable"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Reverse Charge Applicable';
        }
        field(28; "Original Invoice No."; Text[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Original Invoice No.';
        }
        field(29; "Original Invoice Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Original Invoice Date';
        }
        field(30; "Original Invoice GSTIN"; Text[15])
        {
            DataClassification = ToBeClassified;
            Caption = 'Original Invoice GSTIN';
        }
        field(31; "Reference Doc No."; Code[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Reference Doc No.';
        }
        field(32; "Date of Purchase"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Date of Purchase';
        }
        field(33; "Country of Supply"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Country of Supply';
        }
        field(34; "Customer Type"; option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",COMPOSITION,UIN_REGISTERED;
            Caption = 'Customer Type';
        }
        field(35; "Supplier Type"; option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",COMPOSITION;
            Caption = 'Supplier Type';
        }
        field(36; "Seller Name"; Text[150])
        {
            DataClassification = ToBeClassified;
            Caption = 'Seller Name';
        }
        field(37; "Seller GSTIN"; Text[15])
        {
            DataClassification = ToBeClassified;
            Caption = 'Seller GSTIN';
        }
        field(38; "Seller Address"; Text[200])
        {
            DataClassification = ToBeClassified;
            Caption = 'Seller Address';
        }
        field(39; "Seller Zip Code"; Text[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Seller Zip Code';
        }
        field(40; "Seller City"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Seller City';
        }
        field(41; "Seller State"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Seller State';
        }
        field(42; "Seller Country"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Seller Country';
        }
        field(43; "Seller Phone No."; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Seller Phone No.';
        }
        field(44; "Buyer Name"; Text[150])
        {
            DataClassification = ToBeClassified;
            Caption = 'Buyer Name';
        }
        field(45; "Buyer GSTIN"; Text[15])
        {
            DataClassification = ToBeClassified;
            Caption = 'Buyer GSTIN';
        }
        field(46; "Buyer Address"; Text[200])
        {
            DataClassification = ToBeClassified;
            Caption = 'Buyer Address';
        }
        field(47; "Buyer Zip Code"; Text[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Buyer Zip Code';
        }
        field(48; "Buyer City"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Buyer City';
        }
        field(49; "Buyer State"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Buyer State';
        }
        field(50; "Buyer Country"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Buyer Country';
        }
        field(51; "Buyer Phone No."; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Buyer Phone No.';
        }
        field(52; "Seller/Buyer Taxable entity"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Seller/Buyer Taxable entity';
        }
        field(53; "Export Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",Deemed,"SEZ without IGST","SEZ with IGST","Export with IGST","Export Under Bond","Sale from bonded WH",Regular;
            Caption = 'Export Type';
        }
        field(54; "Shipping Bill No."; Code[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Shipping Bill No.';
        }
        field(55; "Shipping Port Code"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Shipping Port Code';
        }
        field(56; "Shipping Bill Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Shipping Bill Date';
        }
        field(57; "Bill of Entry"; Text[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Bill of Entry';
        }
        field(58; "Bill of Entry Value"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Bill of Entry Value';
        }
        field(59; "Bill of Entry Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Bill of Entry Date';
        }
        field(60; "Import Invoice Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",Goods,"Goods from SEZ",Services,"Services From SEZ";
            Caption = 'Import Invoice Type';
        }
        field(61; "Import Port Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Import Port Code';
        }
        field(62; "E-Commerce Name"; Text[150])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Commerce Name';
        }
        field(63; "E-Commerce GSTIN"; Text[15])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Commerce GSTIN';
        }
        field(64; "E-Commerce Address"; Text[200])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Commerce Address';
        }
        field(65; "E-Commerce Zip Code"; Text[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Commerce Zip Code';
        }
        field(66; "E-Commerce City"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Commerce City';
        }
        field(67; "E-Commerce State"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Commerce State';
        }
        field(68; "E-Commerce Country"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Commerce Country';
        }
        field(69; "E-Commerce Phone No."; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Commerce Phone No.';
        }
        field(70; "E- Commerce Merchant ID"; Text[50])
        {
            DataClassification = ToBeClassified;
            caption = 'E- Commerce Merchant ID';
        }
        field(71; "TCS Applicable"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'TCS Applicable';
        }
        field(72; "TDS Applicable"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'TDS Applicable';
        }
        field(73; "CDN Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",CREDIT,DEBIT;
            Caption = 'CDN Type';
        }
        field(74; "Original Invoice Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = ,SALE,PURCHASE;
            Caption = 'Original Invoice Type';
        }
        field(75; "Original Inv. Classification"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = ,B2B,B2BUR,B2BA,B2CL,B2CS,EXPORT,IMPORT,ISD,COMPOSITE,B2B_EXPORT,NIL_BOS,B2C;
            Caption = 'Original Invoice Classification';
        }
        field(76; "Note Num"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Note Num';
        }
        field(77; "Is Bill of Supply"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Bill of Supply';
        }
        field(78; "Is Cancelled"; Boolean)
        {
            DataClassification = ToBeClassified;
            caption = 'Is Cancelled';
        }
        field(79; "Updated"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Updated';
        }
        field(80; "Selected"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Selected';
        }
        field(81; "Matched Status"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Matched Status';
        }
        field(82; "Match Status Description"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Match Status Description';
        }
        field(83; "Matching at PAN/GSTIN"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Matching at PAN/GSTIN';
        }
        field(84; "MisMatched Fields"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'MisMatched Fields';
        }
        field(85; "MisMatched Fields count"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'MisMatched Fields count';
        }
        field(86; "Return Filed"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Return Filed';
        }
        field(87; "While Posting"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'While Posting';
        }
        field(88; "Is Advance"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Advance';
        }
        field(89; "IRN"; Text[200])
        {
            Caption = 'IRN';
            DataClassification = ToBeClassified;
        }
        field(90; "Request"; Blob)
        {
            DataClassification = ToBeClassified;
        }
        field(91; "Response"; Blob)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(key1; "Transaction Type", "Document Type", "Document No.")
        {
            Clustered = true;
        }
    }
}