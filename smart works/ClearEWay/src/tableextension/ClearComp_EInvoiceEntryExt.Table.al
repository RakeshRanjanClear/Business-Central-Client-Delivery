
tableextension 60030 "ClearComp e-Invoice Entry Ext." extends "ClearComp e-Invoice Entry"

{

    fields
    {

        field(60048; "E-Way Canceled"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way Canceled';
        }
        field(60049; "E-Way URL"; Text[200])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way URL';
        }
        field(60050; "E-WAY Response Text"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-WAY Response Text';
        }
        field(60051; "E-Way Canceled Date"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way Canceled Date';
        }
        field(60052; "From Place"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'From Place City';
        }
        field(60053; "From State"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'From State';
        }
        field(60054; "To State"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'To State';
        }
        field(60055; "To Place"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'To Place City';
        }
        field(60056; "Multi Vehicle Enable"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Multi Vehicle Enable';
        }
        field(60057; "Total Quantity Sales Invoice"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Sales Invoice Line".Quantity where("Document No." = field("Document No."), Type = filter(Item)));

        }
        field(60058; "Total Quantity Transfer Ship"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Transfer Shipment Line".Quantity where("Document No." = field("Document No.")));

        }
        field(60059; "Total Quantity Service Ship"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Service Shipment Line".Quantity where("Document No." = field("Document No."), Type = filter(Item)));

        }
        field(60060; "Total Quantity Purchase Ret"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Purch. Cr. Memo Line".Quantity where("Document No." = field("Document No."), Type = filter(Item)));

        }
        field(60001; "Total Qty On Multi veh. page"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CT- E-way Multi Vehicle".Quantity where("Document No." = field("Document No."), "API Type" = field("API Type"), "Document Type" = field("Document Type")));

        }

        field(60190; "Total Quantity Sales Ship"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Sales Shipment Line".Quantity where("Document No." = field("Document No."), Type = filter(Item)));

        }

        field(60002; "Multi Vehicle Reason Code"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Multi Vehicle Reason Code';
            OptionMembers = " ",FIRST_TIME,OTHERS;
        }
        field(60003; "Multi Vehicle Remark"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Multi Vehicle Remark';

        }
        field(60004; "Extend E-way Reason Code"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Extend E-way Reason Code';
            OptionMembers = " ",NATURAL_CALAMITY,TRANSSHIPMENT,OTHERS,ACCIDENT,LAW_ORDER_SITUATION;
            trigger OnValidate()
            begin

            end;
        }
        field(60005; "Extend E-way  Remark"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Extend E-way  Remark';

        }
        field(60006; "Remaining Distnce"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Remaining Distance';

        }

        field(60007; "Total Quantity Sales Cr Memo"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Sales Cr.Memo Line".Quantity where("Document No." = field("Document No.")));

        }

        field(60008; "Total Quantity Purchase Inv"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Purch. Inv. Line".Quantity where("Document No." = field("Document No."), Type = filter(Item)));

        }
        field(60009; "Multi vehicle Generated"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(60010; "Eway Bill Transaction Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",Regular,"Bill to-ship to","Bill from-dispatch from",Combination;
        }
        field(60011; "SupplyType"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",Inward,Outward;

        }
        field(60012; "Supply Sub Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers =
            " ",Supply,Import,Export,JOB_WORK,OWN_USE,JOB_WORK_RETURNS,SALES_RETURN,OTH,SKD_CKD_LOTS,LINES_SALES,RECIPIENT_NOT_KNOWN,EXHIBITION_OR_FAIRS;


        }
        field(60013; "Sub Supply Type Desc"; text[50])
        {
            DataClassification = ToBeClassified;
        }

        field(60014; "E-way Document Type"; option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",INV,BOS,BOE,CHL,OTH;
        }

        field(60044; "E-Way Bill No."; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way Bill No.';
        }
        field(60045; "E-Way Bill Date"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way Bill Date';
        }
        field(60046; "E-Way Bill Validity"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way Bill Validity';
        }
        field(60047; "E-Way Generated"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way Generated';
        }

    }
}