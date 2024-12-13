/// <summary>
/// PageExtension Clearcomp Eway (ID 60031) extends Record ClearComp E-Invoice Setup.
/// </summary>
pageextension 60031 "Clearcomp Eway" extends "ClearComp E-Invoice Setup"
{
    layout
    {

        addafter(General)
        {
            group("E-Way")
            {
                field("URL E-Way Creation"; Rec."URL E-Way Creation")
                {
                    ApplicationArea = All;
                }
                field("URL E-Way Cancelation"; Rec."URL E-Way Cancelation")
                {
                    ApplicationArea = All;
                }
                field("URL E-Way Update"; Rec."URL E-Way Update")
                {
                    ApplicationArea = All;
                    Visible = true;
                }
                field("Download Eway Pdf URL"; Rec."Download Eway Pdf URL")
                {
                    ApplicationArea = All;
                    Visible = true;
                }

                field("URL Eway By IRN"; Rec."URL Eway By IRN")
                {
                    ApplicationArea = All;
                    Visible = true;
                }
                field("URL Multi Vehicle Eway"; rec."URL Multi Vehicle Eway")
                {
                    ApplicationArea = All;
                    Visible = true;
                }

                field("URL Extend E-way Bill Validity"; Rec."URL Extend E-way Bill Validity")
                {
                    ApplicationArea = All;
                }


            }
        }
    }
    actions
    {
        addlast(Navigation)
        {
            action(UpdateSetup)
            {
                Caption = 'Update e-Way Setup';
                Promoted = true;
                PromotedCategory = new;
                PromotedIsBig = true;
                PromotedOnly = true;
                ApplicationArea = all;
                trigger OnAction()
                begin
                    if Rec."Base URL" > '' then begin
                        Rec."URL Eway By IRN" := Rec."Base URL" + '/einv/v2/eInvoice/ewaybill';
                        Rec."URL E-Way Creation" := Rec."Base URL" + '/einv/v3/ewaybill/generate';
                        Rec."URL E-Way Cancelation" := Rec."Base URL" + '/einv/v2/eInvoice/ewaybill/cancel';
                        Rec."URL E-Way Update" := Rec."Base URL" + '/einv/v1/ewaybill/update?action=%1';
                        Rec."URL Multi Vehicle Eway" := Rec."Base URL" + '/einv/v1/ewaybill/multi-vehicle';
                        rec."Download Eway Pdf URL" := Rec."Base URL" + '/einv/v2/eInvoice/ewaybill/print';
                        rec."URL Eway By IRN" := Rec."Base URL" + '/einv/v2/eInvoice/ewaybill';
                        rec."URL Multi Vehicle Eway" := Rec."Base URL" + '/einv/v1/ewaybill/multi-vehicle';
                        rec."URL Extend E-way Bill Validity" := rec."Base URL" + '/einv/v1/ewaybill/update?action=EXTEND_VALIDITY';
                        rec.Modify()

                    end;
                end;
            }
        }
    }
}