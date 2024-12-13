page 60037 "CT-E-way Multibill Subform"
{

    Caption = 'CT-E-way Multibill Subform';
    PageType = ListPart;
    SourceTable = "CT- E-way Multi Vehicle";
    AutoSplitKey = true;
    UsageCategory = Administration;
    ApplicationArea = All;


    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Vehicle No."; Rec."Vehicle No.")
                {
                    ToolTip = 'Specifies the value of the Vehicle No. field.';
                    ApplicationArea = all;
                    Editable = editMultiVehicle;
                }
                field("LR/RR Date"; Rec."LR/RR Date")
                {
                    ToolTip = 'Specifies the value of the LR/RR Date field.';
                    ApplicationArea = all;
                    Editable = editMultiVehicle;
                }
                field("LR/RR No."; Rec."LR/RR No.")
                {
                    ToolTip = 'Specifies the value of the LR/RR No. field.';
                    ApplicationArea = all;
                    Editable = editMultiVehicle;
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies the value of the Quantity field.';
                    ApplicationArea = all;
                    Editable = editMultiVehicle;
                }

            }
        }
    }

    trigger OnOpenPage()
    begin
        editMultiVehicle := false;
        if EwayEinvoiceEntry.get(Rec."Document No.", Rec."API Type", Rec."Document Type") then begin
            editMultiVehicle := EwayEinvoiceEntry."Multi Vehicle Enable";
        end;
        editMultiVehicle := true;
    end;

    trigger OnAfterGetRecord()
    begin
        editMultiVehicle := false;
        if EwayEinvoiceEntry.get(Rec."Document No.", Rec."API Type", Rec."Document Type") then begin
            editMultiVehicle := EwayEinvoiceEntry."Multi Vehicle Enable";
        end;
        editMultiVehicle := true;
    end;

    var
        [InDataSet]
        editMultiVehicle: Boolean;

        EwayEinvoiceEntry: record "ClearComp e-Invoice Entry";

}
