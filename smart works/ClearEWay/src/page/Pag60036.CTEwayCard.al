page 60036 "CT Eway Card"
{

    Caption = 'CT Eway Card';
    PageType = Card;
    SourceTable = "ClearComp e-Invoice Entry";
    SourceTableView = where("API Type" = filter("E-Way"));
    DeleteAllowed = false;
    ApplicationArea = all;
    UsageCategory = Documents;




    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                group("Document Details")
                {
                    Editable = false;
                    field("Document Type"; Rec."Document Type")
                    {
                        ToolTip = 'Specifies the value of the Document Type field.';
                        ApplicationArea = all;
                    }
                    field("Document No."; Rec."Document No.")
                    {
                        ToolTip = 'Specifies the value of the Document No. field.';
                        ApplicationArea = all;
                    }
                    field("Document Date"; Rec."Document Date")
                    {
                        ToolTip = 'Specifies the value of the Document Date field.';
                        ApplicationArea = all;
                    }
                    field("Created By"; Rec."Created By")
                    {
                        ToolTip = 'Specifies the value of the Created By field.';
                        ApplicationArea = all;
                    }
                }
                group("Transaction Type Detail")
                {
                    field("E-way Document Type"; Rec."E-way Document Type")
                    {
                        ApplicationArea = all;
                    }
                    field("Transaction Type"; Rec."Eway Bill Transaction Type")
                    {
                        ApplicationArea = all;
                    }
                    field(SupplyType; Rec.SupplyType)
                    {
                        ApplicationArea = all;

                    }
                    field("Supply Sub Type"; Rec."Supply Sub Type")
                    {
                        ApplicationArea = all;
                    }
                    field("Sub Supply Type Desc"; Rec."Sub Supply Type Desc")
                    {
                        ApplicationArea = all;
                    }
                }
                group("E-way Bill Status")
                {
                    Editable = false;
                    field("E-Way Bill No."; Rec."E-Way Bill No.")
                    {
                        ToolTip = 'Specifies the value of the E-Way Bill No. field.';
                        ApplicationArea = all;
                    }
                    field("E-Way Bill Date"; Rec."E-Way Bill Date")
                    {
                        ToolTip = 'Specifies the value of the E-Way Bill Date field.';
                        ApplicationArea = all;
                    }
                    field("E-Way Bill Validity"; Rec."E-Way Bill Validity")
                    {
                        ToolTip = 'Specifies the value of the E-Way Bill Validity field.';
                        ApplicationArea = all;
                    }
                    field("E-Way Canceled"; Rec."E-Way Canceled")
                    {
                        ToolTip = 'Specifies the value of the E-Way Canceled field.';
                        ApplicationArea = all;
                    }
                    field("Cancelled By"; rec."Cancelled By")
                    {
                        ApplicationArea = All;
                    }

                    field("E-Way Canceled Date"; Rec."E-Way Canceled Date")
                    {
                        ToolTip = 'Specifies the value of the E-Way Canceled Date field.';
                        ApplicationArea = all;
                    }
                    field("E-Way Generated"; Rec."E-Way Generated")
                    {
                        ToolTip = 'Specifies the value of the E-Way Generated field.';
                        ApplicationArea = all;
                    }
                }
                group("E-way Cancel Detail")
                {
                    field("Reason of Cancel"; Rec."Reason of Cancel")
                    {
                        ApplicationArea = All;
                    }

                }
                group("E-way Update details")
                {
                    field("New Pin Code From"; Rec."New Pin Code From")
                    {
                        ToolTip = 'Specifies the value of the New Pin Code From field.';
                        ApplicationArea = all;
                    }
                    field("New Vehicle No."; Rec."New Vehicle No.")
                    {
                        ToolTip = 'Specifies the value of the New Vehicle No. field.';
                        ApplicationArea = all;
                    }
                    field("Vehicle No. Update Remark"; Rec."Vehicle No. Update Remark")
                    {
                        ToolTip = 'Specifies the value of the Vehicle No. Update Remark field.';
                        ApplicationArea = all;
                        trigger OnValidate()
                        begin
                            if rec."E-Way Bill Validity" > '' then begin
                                if rec."Vehicle No. Update Remark" = rec."Vehicle No. Update Remark"::FIRST_TIME then
                                    error('First time cannot be selected after Part B generation');
                            end;
                        end;
                    }
                    group("Extend Validity")
                    {
                        field("Extend E-way Reason Code"; Rec."Extend E-way Reason Code")
                        {
                            ApplicationArea = All;
                        }
                        field("Extend E-way  Remark"; Rec."Extend E-way  Remark")
                        {
                            ApplicationArea = All;
                        }
                        field("Remaining Distnce"; Rec."Remaining Distnce")
                        {
                            ApplicationArea = all;
                        }


                    }

                    group("Multi Vehicle E-way")
                    {
                        field("Multi Vehicle Enable"; Rec."Multi Vehicle Enable")
                        {
                            ApplicationArea = all;
                            Editable = Rec."E-Way Bill No." <> '';
                            trigger OnValidate()

                            begin
                                if Rec."Multi Vehicle Enable" then begin
                                    CurrPage."CT-E-way Multibill Subform".Page.Editable := true

                                end else
                                    CurrPage."CT-E-way Multibill Subform".Page.Editable := false;

                            end;


                        }
                        field("Total Quantity"; DocumentQty)
                        {
                            ApplicationArea = All;
                            Editable = false;
                            // Visible = QtySalesInvVisible;
                        }
                        // field("Total Qty On Multi vehicle page"; Rec."Total Qty On Multi veh. page")
                        // {
                        //     ApplicationArea = All;
                        //     Editable = false;
                        // }

                        field("From Place"; Rec."From Place")
                        {
                            ApplicationArea = All;
                        }
                        field("From State"; Rec."From State")
                        {
                            ApplicationArea = All;
                        }
                        field("To Place"; Rec."To Place")
                        {
                            ApplicationArea = All;
                        }
                        field("To State"; Rec."To State")
                        {
                            ApplicationArea = All;
                        }




                        field("Multi Vehicle Reason Code"; Rec."Multi Vehicle Reason Code")
                        {
                            ApplicationArea = All;
                        }
                        field("Multi Vehicle Remark"; Rec."Multi Vehicle Remark")
                        {
                            ApplicationArea = All;
                        }






                    }
                }

            }
            part("CT-E-way Multibill Subform"; "CT-E-way Multibill Subform")
            {
                SubPageLink = "Document Type" = field("Document Type"), "API Type" = field("API Type"), "Document No." = field("Document No.");
            }
        }

    }
    actions
    {
        area(Processing)
        {
            action(Generate)
            {
                Caption = 'Generate E-Way Bill';
                Image = CreateDocument;
                ApplicationArea = All;
                Visible = false;

                trigger OnAction()
                var
                    EWayMngmtUnit: Codeunit "ClearComp E-Way Management";
                    salesInvoiceHdr: Record "Sales Invoice Header";
                begin
                    if salesInvoiceHdr.get(Rec."Document No.") then
                        EWayMngmtUnit.CreateJsonSalesInvoice(salesInvoiceHdr);
                end;
            }
            action(UpdateVehNo)
            {
                Caption = 'Update Vehicle No. / Part B';
                Image = UpdateXML;
                ApplicationArea = All;
                Visible = true;
                trigger OnAction()
                var
                    EWayMngmtUnit: Codeunit "ClearComp E-Way Management";
                begin
                    EWayMngmtUnit.UpdateVehicleNo(Rec);
                    rec."Vehicle No. Update Remark" := Rec."Vehicle No. Update Remark"::" ";
                    rec.Modify();
                end;
            }
            action(UpdateMultiVehicle)
            {
                Caption = 'Update Multi Vehicle to e-way Bill';
                Image = UpdateXML;
                ApplicationArea = All;
                Visible = true;
                trigger OnAction()
                var
                    EWayMngmtUnit: Codeunit "ClearComp E-Way Management";
                begin
                    Rec.TestField("E-Way Bill No.");
                    if rec."Total Qty On Multi veh. page" <> DocumentQty then
                        Error('Total Qty on Multivehicle is not equal to document total qty.');
                    EWayMngmtUnit.GenerateMultiVehicle(Rec);
                end;

            }

            action(UpdateExtendValidity)
            {
                Caption = 'Extend Validity';
                Image = UpdateXML;
                ApplicationArea = All;
                Visible = true;
                trigger OnAction()
                var
                    EWayMngmtUnit: Codeunit "ClearComp E-Way Management";
                begin
                    Rec.TestField("E-Way Bill No.");

                    EWayMngmtUnit.ExtendEwayBill(Rec);
                end;

            }
            action(Cancel)
            {
                Caption = 'Cancel E-Way';
                Image = Cancel;
                ApplicationArea = All;

                trigger OnAction()
                var
                    EWayMngmtUnit: Codeunit "ClearComp E-Way Management";
                begin
                    EWayMngmtUnit.CancelEWay(Rec);
                end;
            }
            action(DownlaodReq)
            {
                Caption = 'Download Request File';
                Image = Download;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    if Rec."Request JSON".HasValue() then
                        DownloadFile(true);
                end;
            }
            action(DownloadResp)
            {
                Caption = 'Download Response File';
                Image = Download;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    if Rec."Response JSON".HasValue() then
                        DownloadFile(false);
                end;
            }
        }
    }
    local procedure DownloadFile(Request: Boolean)
    var
        FileName: Text;
        FileMgmtUnit: Codeunit "File Management";
        InStrm: InStream;
        OutStrm: OutStream;
        TempBlobUnit: Codeunit "Temp Blob";
    begin
        FileName := Format(CreateGuid());
        FileName := CopyStr(FileName, 2, StrLen(FileName) - 2);
        Rec.CalcFields("Request JSON", "Response JSON");
        if Request then begin
            FileName := 'Request' + FileName + '.txt';
            TempBlobUnit.FromRecord(Rec, Rec.FieldNo("Request JSON"));
            TempBlobUnit.CreateOutStream(OutStrm);
        end else begin
            FileName := 'Response' + FileName + '.txt';
            TempBlobUnit.FromRecord(Rec, Rec.FieldNo("Response JSON"));
            Rec."Response JSON".CreateOutStream(OutStrm);
        end;
        FileMgmtUnit.BLOBExport(TempBlobUnit, FileName, true);
    end;


    trigger OnOpenPage()
    begin


    end;

    trigger OnAfterGetRecord()
    begin

        Rec.SetAutoCalcFields("Total Qty On Multi veh. page", "Total Quantity Purchase Ret", "Total Quantity Sales Invoice", "Total Quantity Service Ship", "Total Quantity Transfer Ship");
        Rec.CalcFields("Total Qty On Multi veh. page", "Total Quantity Purchase Ret", "Total Quantity Sales Invoice", "Total Quantity Service Ship", "Total Quantity Transfer Ship", "Total Quantity Sales Cr Memo", Rec."Total Quantity Purchase Inv");
        if Rec."Multi Vehicle Enable" then begin
            CurrPage."CT-E-way Multibill Subform".Page.Editable := true

        end else
            CurrPage."CT-E-way Multibill Subform".Page.Editable := false;

        QtySalesInvVisible := rec."Document Type" = rec."Document Type"::Invoice;

        QtyTRansferInvVisible := rec."Document Type" = rec."Document Type"::TransferShpt;
        QtyPurcInvVisible := rec."Document Type" = rec."Document Type"::"Purch Cr. Memo Hdr";

        DocumentQty := rec."Total Quantity Purchase Ret" + rec."Total Quantity Sales Invoice" + rec."Total Quantity Service Ship" + rec."Total Quantity Transfer Ship"
        + rec."Total Quantity Sales Cr Memo" + Rec."Total Quantity Purchase Inv" + rec."Total Quantity Sales Ship";
        CurrPage.Update(true);
    end;

    trigger OnAfterGetCurrRecord()
    var
        VendorL: REcord vendor;
        TransactionTypeL: Option " ",Regular,"Bill to-ship to","Bill from-dispatch from",Combination;
        locationl: record Location;
    begin
        Rec.SetAutoCalcFields("Total Qty On Multi veh. page", "Total Quantity Purchase Ret", "Total Quantity Sales Invoice", "Total Quantity Service Ship", "Total Quantity Transfer Ship");
        Rec.CalcFields("Total Qty On Multi veh. page", "Total Quantity Purchase Ret", "Total Quantity Sales Invoice", "Total Quantity Service Ship", "Total Quantity Transfer Ship",
        rec."Total Quantity Sales Cr Memo", Rec."Total Quantity Purchase Inv", "Total Quantity Sales Ship");
        if Rec."Multi Vehicle Enable" then begin
            CurrPage."CT-E-way Multibill Subform".Page.Editable := true

        end else
            CurrPage."CT-E-way Multibill Subform".Page.Editable := false;

        QtySalesInvVisible := rec."Document Type" = rec."Document Type"::Invoice;

        QtyTRansferInvVisible := rec."Document Type" = rec."Document Type"::TransferShpt;
        QtyPurcInvVisible := rec."Document Type" = rec."Document Type"::"Purch Cr. Memo Hdr";
        DocumentQty := rec."Total Quantity Purchase Ret" + rec."Total Quantity Sales Invoice" + rec."Total Quantity Service Ship" +
        rec."Total Quantity Transfer Ship" + rec."Total Quantity Sales Cr Memo" + Rec."Total Quantity Sales Ship"
        + Rec."Total Quantity Purchase Inv";
        case rec."Document Type" of
            rec."Document Type"::Invoice:
                begin
                    SalesInvoice.get(Rec."Document No.");
                    if Rec."From Place" = '' then begin
                        Location.get(SalesInvoice."Location Code");
                        rec."From Place" := Location.City;
                        rec."From State" := Location."State Code";

                    end;

                    if Rec."To Place" = '' then begin
                        //    Location.get(SalesInvoice."Location Code");
                        rec."To Place" := SalesInvoice."Sell-to City";
                        rec."To State" := SalesInvoice."GST Ship-to State Code";

                    end;
                    if rec."To State" = '' then
                        rec."To State" := SalesInvoice.State;
                    if rec."New Pin Code From" = '' then begin
                        //     rec."New Pin Code From" := SalesInvoice."Dispatch-from Post Code";
                        if rec."New Pin Code From" = '' then
                            rec."New Pin Code From" := Location."Post Code";
                    end;
                    if rec."Shipping Agent Code" = '' then
                        rec."Shipping Agent Code" := SalesInvoice."Shipping Agent Code";
                    if rec."Transport Method" = '' then
                        rec."Transport Method" := SalesInvoice."Transport Method";
                    if rec."Vehicle No." = '' then
                        rec."Vehicle No." := SalesInvoice."Vehicle No.";
                    if Rec."New Vehicle No." = '' then
                        rec."New Vehicle No." := SalesInvoice."Vehicle No.";
                    if rec."LR/RR No." = '' then
                        rec."LR/RR No." := SalesInvoice."LR/RR No.";
                    if rec."LR/RR Date" <> SalesInvoice."LR/RR Date" then
                        rec."LR/RR Date" := SalesInvoice."LR/RR Date";

                    if rec."Transport Method" = '' then begin
                        if SalesInvoice."Transport Method" <> '' then
                            rec."Transport Method" := SalesInvoice."Transport Method"
                        else begin
                            SalesInvoice.TestField("Shipment Method Code");
                            rec."Transport Method" := SalesInvoice."Shipment Method Code";
                        end;

                    end;

                    Rec.Modify();
                end;
            rec."Document Type"::"Purch Cr. Memo Hdr":
                begin
                    PurchCrMemoHdr.get(Rec."Document No.");
                    if Rec."From Place" = '' then begin
                        Location.get(PurchCrMemoHdr."Location Code");
                        rec."From Place" := Location.City;
                        rec."From State" := Location."State Code";

                    end;

                    if Rec."To Place" = '' then begin
                        VendorL.get(PurchCrMemoHdr."Buy-from Vendor No.");
                        //    Location.get(SalesInvoice."Location Code");
                        rec."To Place" := PurchCrMemoHdr."Buy-from City";
                        rec."To State" := VendorL."State Code";

                    end;

                    if rec."New Pin Code From" = '' then begin
                        rec."New Pin Code From" := PurchCrMemoHdr."Buy-from Post Code";
                        if rec."New Pin Code From" = '' then
                            rec."New Pin Code From" := Location."Post Code";
                    end;
                    if rec."Shipping Agent Code" = '' then
                        rec."Shipping Agent Code" := PurchCrMemoHdr."Shipping Agent Code";
                    if rec."Transport Method" = '' then
                        rec."Transport Method" := PurchCrMemoHdr."Transport Method";
                    if rec."Vehicle No." = '' then
                        rec."Vehicle No." := PurchCrMemoHdr."Vehicle No.";
                    if Rec."New Vehicle No." = '' then
                        rec."New Vehicle No." := PurchCrMemoHdr."Vehicle No.";
                    if rec."LR/RR No." = '' then
                        rec."LR/RR No." := PurchCrMemoHdr."LR/RR No.";
                    if rec."LR/RR Date" <> PurchCrMemoHdr."LR/RR Date" then
                        rec."LR/RR Date" := PurchCrMemoHdr."LR/RR Date";
                    if rec."Transport Method" = '' then begin
                        if PurchCrMemoHdr."Transport Method" <> '' then
                            rec."Transport Method" := PurchCrMemoHdr."Transport Method"
                        else begin
                            PurchCrMemoHdr.TestField("Shipment Method Code");
                            rec."Transport Method" := PurchCrMemoHdr."Shipment Method Code";
                        end;

                    end;
                    Rec.Modify();
                end;

            rec."Document Type"::"Purch. Inv. Hdr":
                begin
                    PurchInvHdr.get(Rec."Document No.");
                    if Rec."From Place" = '' then begin
                        if PurchInvHdr."Buy-from Country/Region Code" <> 'IN' then begin

                            EntryPoint.get(PurchInvHdr."Entry Point");
                            rec."From Place" := EntryPoint.City;

                            rec."From State" := EntryPoint."State Code";

                        end else begin
                            vendorL.get(PurchInvHdr."Buy-from Vendor No.");
                            rec."From Place" := VendorL.City;

                            rec."From State" := VendorL."State Code";

                        end;
                        if Rec."To Place" = '' then begin
                            Location.get(PurchInvHdr."Location Code");
                            rec."To Place" := Location.City;
                            rec."To State" := Location."State Code";

                        end;
                    end;

                    if Rec."From Place" = '' then begin
                        VendorL.get(PurchInvHdr."Buy-from Vendor No.");
                        //    Location.get(SalesInvoice."Location Code");
                        rec."From Place" := PurchInvHdr."Buy-from City";
                        rec."From State" := VendorL."State Code";

                    end;

                    if rec."New Pin Code From" = '' then begin
                        rec."New Pin Code From" := PurchInvHdr."Buy-from Post Code";

                    end;
                    if rec."Shipping Agent Code" = '' then
                        rec."Shipping Agent Code" := PurchInvHdr."Shipping Agent Code";
                    if rec."Transport Method" = '' then
                        rec."Transport Method" := PurchInvHdr."Transport Method";
                    if rec."Vehicle No." = '' then
                        rec."Vehicle No." := PurchInvHdr."Vehicle No.";
                    if Rec."New Vehicle No." = '' then
                        rec."New Vehicle No." := PurchInvHdr."Vehicle No.";
                    if rec."LR/RR No." = '' then
                        rec."LR/RR No." := PurchInvHdr."LR/RR No.";
                    if rec."LR/RR Date" <> PurchInvHdr."LR/RR Date" then
                        rec."LR/RR Date" := PurchInvHdr."LR/RR Date";

                    if rec."Transport Method" = '' then begin
                        if PurchInvHdr."Transport Method" <> '' then
                            rec."Transport Method" := PurchInvHdr."Transport Method"
                        else begin
                            PurchInvHdr.TestField("Shipment Method Code");
                            rec."Transport Method" := PurchInvHdr."Shipment Method Code";
                        end;

                    end;

                    Rec.Modify();
                end;

            rec."Document Type"::"Sales Shipment":
                begin
                    SalesShipHeader.get(Rec."Document No.");
                    locationl.get(SalesShipHeader."Location Code");

                    if rec."Eway Bill Transaction Type" <> rec."Eway Bill Transaction Type"::" " then begin


                        if TransactionTypeL = TransactionTypeL::" " then
                            TransactionTypeL := TransactionTypeL::Regular;
                        rec."Eway Bill Transaction Type" := TransactionTypeL;
                    end;
                    if Rec."From Place" = '' then begin
                        Location.get(SalesShipHeader."Location Code");
                        rec."From Place" := Location.City;
                        rec."From State" := Location."State Code";

                    end;

                    if Rec."To Place" = '' then begin
                        //    Location.get(SalesShipHeader."Location Code");
                        rec."To Place" := SalesShipHeader."Sell-to City";
                        rec."To State" := SalesShipHeader."GST Ship-to State Code";

                    end;
                    if rec."To State" = '' then
                        rec."To State" := SalesShipHeader.State;

                    if rec."Shipping Agent Code" = '' then
                        rec."Shipping Agent Code" := SalesShipHeader."Shipping Agent Code";
                    if rec."Transport Method" = '' then
                        rec."Transport Method" := SalesShipHeader."Transport Method";
                    if rec."Vehicle No." = '' then
                        rec."Vehicle No." := SalesShipHeader."Vehicle No.";
                    if Rec."New Vehicle No." = '' then
                        rec."New Vehicle No." := SalesShipHeader."Vehicle No.";
                    if rec."LR/RR No." = '' then
                        rec."LR/RR No." := SalesShipHeader."LR/RR No.";
                    if rec."LR/RR Date" <> SalesShipHeader."LR/RR Date" then
                        rec."LR/RR Date" := SalesShipHeader."LR/RR Date";
                    if rec."Transport Method" = '' then begin
                        if SalesShipHeader."Transport Method" <> '' then
                            rec."Transport Method" := SalesShipHeader."Transport Method"
                        else begin
                            SalesShipHeader.TestField("Shipment Method Code");
                            rec."Transport Method" := SalesShipHeader."Shipment Method Code";
                        end;

                    end;


                    Rec.Modify();
                end;

            Rec."Document Type"::"Service Invoice":
                begin
                    // ServiceInvoice.get(Rec."Document No.");
                    // if Rec."From Place" = '' then begin
                    //     Location.get(ServiceInvoice."Location Code");
                    //     rec."From Place" := Location.City;
                    //     rec."From State" := Location."State Code";

                    // end;
                    // if Rec."To Place" = '' then begin
                    //     //    Location.get(SalesInvoice."Location Code");
                    //     rec."To Place" := ServiceInvoice."Bill-to City";
                    //     rec."To State" := ServiceInvoice."GST Ship-to State Code";

                    // end;


                    ServiceInvoice.get(Rec."Document No.");
                    if Rec."From Place" = '' then begin
                        Location.get(ServiceInvoice."Location Code");
                        rec."From Place" := Location.City;
                        rec."From State" := Location."State Code";

                    end;

                    if Rec."To Place" = '' then begin
                        //    Location.get(SalesInvoice."Location Code");
                        rec."To Place" := ServiceInvoice."Bill-to City";
                        rec."To State" := ServiceInvoice."GST Bill-to State Code";

                    end;
                    if rec."To State" = '' then
                        rec."To State" := ServiceInvoice.State;

                    if rec."Shipping Agent Code" = '' then
                        rec."Shipping Agent Code" := ServiceInvoice."Shipping Agent Code";
                    if rec."Transport Method" = '' then
                        rec."Transport Method" := ServiceInvoice."Transport Method";
                    if rec."Vehicle No." = '' then
                        rec."Vehicle No." := ServiceInvoice."Vehicle No.";
                    if Rec."New Vehicle No." = '' then
                        rec."New Vehicle No." := ServiceInvoice."Vehicle No.";
                    if rec."LR/RR No." = '' then
                        rec."LR/RR No." := ServiceInvoice."LR/RR No.";
                    if rec."LR/RR Date" <> ServiceInvoice."LR/RR Date" then
                        rec."LR/RR Date" := ServiceInvoice."LR/RR Date";
                    if rec."Transport Method" = '' then begin
                        if ServiceInvoice."Transport Method" <> '' then
                            rec."Transport Method" := ServiceInvoice."Transport Method"
                        else begin
                            ServiceInvoice.TestField("Shipment Method Code");
                            rec."Transport Method" := ServiceInvoice."Shipment Method Code";
                        end;

                    end;


                end;

            Rec."Document Type"::"Service Shipment":
                begin
                    ServiceShipment.get(Rec."Document No.");
                    locationl.get(ServiceShipment."Location Code");

                    if rec."Eway Bill Transaction Type" <> rec."Eway Bill Transaction Type"::" " then begin




                        //if ServiceShipment."GST Bill-to State Code" = ServiceShipment."GST Ship-to State Code" then
                        if TransactionTypeL = TransactionTypeL::" " then
                            TransactionTypeL := TransactionTypeL::Regular;

                    end;
                    if Rec."From Place" = '' then begin
                        Location.get(ServiceShipment."Location Code");
                        rec."From Place" := Location.City;
                        rec."From State" := Location."State Code";

                    end;

                    if Rec."To Place" = '' then begin
                        //    Location.get(SalesInvoice."Location Code");
                        rec."To Place" := ServiceShipment."Bill-to City";
                        rec."To State" := ServiceShipment."GST Bill-to State Code";

                    end;
                    if rec."To State" = '' then
                        rec."To State" := ServiceShipment.State;
                    if rec."New Pin Code From" = '' then begin

                        rec."New Pin Code From" := Location."Post Code";
                    end;
                    if rec."Shipping Agent Code" = '' then
                        rec."Shipping Agent Code" := ServiceShipment."Shipping Agent Code";
                    if rec."Transport Method" = '' then
                        rec."Transport Method" := ServiceShipment."Transport Method";
                    if rec."Vehicle No." = '' then
                        rec."Vehicle No." := ServiceShipment."Vehicle No.";
                    if Rec."New Vehicle No." = '' then
                        rec."New Vehicle No." := ServiceShipment."Vehicle No.";
                    if rec."LR/RR No." = '' then
                        rec."LR/RR No." := ServiceShipment."LR/RR No.";
                    if rec."LR/RR Date" <> ServiceShipment."LR/RR Date" then
                        rec."LR/RR Date" := ServiceShipment."LR/RR Date";
                    if rec."Transport Method" = '' then begin
                        if ServiceShipment."Transport Method" <> '' then
                            rec."Transport Method" := ServiceShipment."Transport Method"
                        else begin
                            ServiceShipment.TestField("Shipment Method Code");
                            rec."Transport Method" := ServiceShipment."Shipment Method Code";
                        end;

                    end;
                    Rec.Modify();
                end;

            rec."Document Type"::TransferShpt:
                begin
                    TransferShip.get(Rec."Document No.");

                    if rec."Eway Bill Transaction Type" <> rec."Eway Bill Transaction Type"::" " then begin


                        if TransactionTypeL = TransactionTypeL::" " then
                            TransactionTypeL := TransactionTypeL::Regular;

                    end;
                    if rec."E-way Document Type" = rec."E-way Document Type"::" " then begin
                        Rec."E-way Document Type" := rec."E-way Document Type"::CHL;
                    end;
                    if Rec."From Place" = '' then begin
                        Location.get(TransferShip."Transfer-from Code");
                        rec."From Place" := Location.City;
                        rec."From State" := Location."State Code";

                    end;
                    if Rec."To Place" = '' then begin
                        Location.get(TransferShip."Transfer-to Code");
                        rec."To Place" := Location.City;
                        rec."To State" := Location."State Code";

                    end;

                    //  SalesInvoice.get(Rec."Document No.");
                    // if Rec."From Place" = '' then begin
                    //     Location.get(SalesInvoice."Location Code");
                    //     rec."From Place" := Location.City;
                    //     rec."From State" := Location."State Code";

                    // end;

                    if Rec."To Place" = '' then begin
                        //  Location.get(TransferShip."Transfer-from Code");
                        //    Location.get(SalesInvoice."Location Code");
                        rec."To Place" := Location.City;
                        rec."To State" := Location."State Code";

                    end;


                    if rec."Shipping Agent Code" = '' then
                        rec."Shipping Agent Code" := TransferShip."Shipping Agent Code";
                    if rec."Transport Method" = '' then
                        rec."Transport Method" := TransferShip."Transport Method";
                    if rec."Vehicle No." = '' then
                        rec."Vehicle No." := TransferShip."Vehicle No.";
                    if Rec."New Vehicle No." = '' then
                        rec."New Vehicle No." := TransferShip."Vehicle No.";
                    if rec."LR/RR No." = '' then
                        rec."LR/RR No." := TransferShip."LR/RR No.";
                    if rec."LR/RR Date" <> TransferShip."LR/RR Date" then
                        rec."LR/RR Date" := TransferShip."LR/RR Date";
                    if rec."Transport Method" = '' then begin
                        if TransferShip."Transport Method" <> '' then
                            rec."Transport Method" := TransferShip."Transport Method"
                        else begin
                            TransferShip.TestField("Shipment Method Code");
                            rec."Transport Method" := TransferShip."Shipment Method Code";
                        end;

                    end;

                    Rec.Modify();
                end;
            rec."Document Type"::CrMemo:
                begin
                    salecrMemo.get(Rec."Document No.");
                    if Rec."From Place" = '' then begin
                        Location.get(salecrMemo."Location Code");
                        rec."From Place" := Location.City;
                        rec."From State" := Location."State Code";

                    end;
                    // if salecrMemo."Dispatch-from Code" <> '' then begin
                    //     rec."From Place" := salecrMemo."Dispatch-from City";
                    //     rec."From State" := salecrMemo."Dispatch-from State";
                    // end;
                    if Rec."To Place" = '' then begin
                        //    Location.get(SalesInvoice."Location Code");
                        rec."To Place" := salecrMemo."Sell-to City";
                        rec."To State" := salecrMemo."GST Ship-to State Code";

                    end;
                    if rec."To State" = '' then
                        rec."To State" := salecrMemo.State;
                    if rec."New Pin Code From" = '' then begin
                        //      rec."New Pin Code From" := salecrMemo."Dispatch-from Post Code";
                        if rec."New Pin Code From" = '' then
                            rec."New Pin Code From" := Location."Post Code";
                    end;
                    if rec."Shipping Agent Code" = '' then
                        rec."Shipping Agent Code" := salecrMemo."Shipping Agent Code";
                    if rec."Transport Method" = '' then
                        rec."Transport Method" := salecrMemo."Shipment Method Code";
                    if rec."Vehicle No." = '' then
                        rec."Vehicle No." := salecrMemo."Vehicle No.";
                    if Rec."New Vehicle No." = '' then
                        rec."New Vehicle No." := salecrMemo."Vehicle No.";
                    if rec."LR/RR No." = '' then
                        rec."LR/RR No." := salecrMemo."LR/RR No.";
                    if rec."LR/RR Date" <> salecrMemo."LR/RR Date" then
                        rec."LR/RR Date" := salecrMemo."LR/RR Date";
                    if rec."Transport Method" = '' then begin
                        if salecrMemo."Transport Method" <> '' then
                            rec."Transport Method" := salecrMemo."Transport Method"
                        else begin
                            salecrMemo.TestField("Shipment Method Code");
                            rec."Transport Method" := salecrMemo."Shipment Method Code";
                        end;

                    end;

                    Rec.Modify();
                end;


        end;

        Rec."New Vehicle No." := '';
        if Rec.Modify() then;

        CurrPage.Update(true);
    end;



    var
        ServiceShipment: Record "Service Shipment Header";

        SalesShipHeader: record "Sales Shipment Header";
        EntryPoint: Record "Entry/Exit Point";
        PurchInvHdr: Record "Purch. Inv. Header";
        salecrMemo: Record "Sales Cr.Memo Header";
        ServiceInvoice: Record "Service Invoice Header";
        Location: Record Location;
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        TransferShip: Record "transfer shipment Header";
        SalesInvoice: Record "Sales Invoice Header";
        [InDataSet]
        QtySalesInvVisible: Boolean;
        [InDataSet]
        QtyTRansferInvVisible: Boolean;
        [InDataSet]
        QtyPurcInvVisible: Boolean;

        DocumentQty: Decimal;
}
