codeunit 50100 "ClearComp E-Invoice Management"
{
    Permissions = tabledata "Sales Invoice Header" = rimd,
                  tabledata "Sales Cr.Memo Header" = rimd;
    TableNo = "Job Queue Entry";


    trigger OnRun()
    var
        SalesInvHdr: Record "Sales Invoice Header";
        SalesCrHdr: Record "Sales Cr.Memo Header";
        FromDate: Date;
        eInvoiceMgmt: Codeunit "e-Invoice Management";
    begin
        if SalesInvHdr.FindSet() then
            repeat
                if eInvoiceMgmt.IsGSTApplicable(SalesInvHdr."No.", Database::"Sales Invoice Header") then begin
                    clear(jobject1);
                    clear(IRNG);
                    Clear(JObject);
                    Clear(GSTIN);
                    GenerateIRNSalesInvoice(SalesInvHdr);
                end;
            until SalesInvHdr.Next() = 0;
        if SalesCrHdr.FindSet() then
            repeat
                if eInvoiceMgmt.IsGSTApplicable(SalesCrHdr."No.", Database::"Sales Cr.Memo Header") then begin
                    clear(jobject1);
                    clear(IRNG);
                    Clear(JObject);
                    Clear(GSTIN);
                    GenerateIRNSalesCreditmemo(SalesCrHdr);
                end;
            until SalesCrHdr.Next() = 0;
    end;

    var
        EInvoiceErr: Label 'E-Invoicing is not applicable for Non-GST Transactions.';
        IRNErr: Label 'Invoice Reference Number is already generated.';
        UnRegisteredErr: Label 'E-Invoicing is not applicable for Un-Registered Customer.';
        IRNSuccMsg: Label 'IRN Cancelled Successfully';
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        EInvoiceSetup: Record "ClearComp e-Invocie Setup";
        JObject: JsonObject;
        SalesLinesErr: Label 'E-Invoice allowes only 100 lines per Invoice. Curent transaction is having %1 lines.', Comment = '%1 = Sales Lines count';
        IsInvoice: Boolean;
        JArray: JsonArray;
        Successful: Label 'IRN generated successfully';
        QRErr: Label 'Dynamic QR Code generation is only allowed for gst transactions.';
        GenerateQRCodeErr: Label 'Dynamic QR Code generation is allowed for Un-Registered Customers only.';
        VoucherAcErr: Label 'For UPI Payments must have a value. It cannot be empty or zero.';
        IRNG: Text;
        GSTIN: Text;
        JObject1: JsonObject;

    procedure GenerateIRNSalesInvoice(var SalesInvHeaderP: Record "Sales Invoice Header"): Boolean
    var
        //GSTManagementL: Codeunit "16401";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        LocationL: Record Location;
        ReqText: Text;
    begin
        Clear(JArray);
        Clear(ReqText);
        Clear(JObject);
        Clear(JObject1);
        Clear(IRNG);
        Clear(GSTIN);
        EInvoiceSetup.Get();
        IsInvoice := True;
        SalesInvHeader.COPY(SalesInvHeaderP);
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-Invoice");
        EInvoiceEntryL.SetRange("Document Type", EInvoiceEntryL."Document Type"::Invoice);
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        if EInvoiceEntryL.FindFirst() then
            if EInvoiceEntryL.IRN <> '' then
                exit;
        LocationL.Get(SalesInvHeader."Location Code");
        if SalesInvHeader."GST Customer Type" in [SalesInvHeader."GST Customer Type"::Unregistered, SalesInvHeader."GST Customer Type"::" "] then
            exit;
        ReadTransactionDetails();
        ReadDocumentDetails(SalesInvHeader."No.", SalesInvHeader."Posting Date");
        ReadSellerDetails(SalesInvHeader."Location Code", SalesInvHeader."Location GST Reg. No.");
        ReadBuyerDetailsSalesInvoice();
        ReadShipDetails(SalesInvHeader."Ship-to Code", SalesInvHeader."Sell-to Customer No.", SalesInvHeader."GST Customer Type",
           SalesInvHeader."Sell-to Customer Name", SalesInvHeader."Sell-to Address", SalesInvHeader."Sell-to Address 2",
           SalesInvHeader."Sell-to City", SalesInvHeader."Sell-to Post Code", SalesInvHeader."GST Ship-to State Code");
        ReadItemDetailsSalesInvoice();
        GetGSTVal(SalesInvHeader."No.", SalesInvHeader."Posting Date", IsInvoice);
        ReadExportDetails(SalesInvHeader."GST Customer Type", SalesInvHeader."Bill Of Export No.",
            SalesInvHeader."Bill Of Export Date", SalesInvHeader."exit Point", SalesInvHeader."Currency Code", SalesInvHeader."Bill-to Country/Region Code");
        JObject.Add('transaction', JObject1);
        JArray.Add(JObject);
        JArray.WriteTo(ReqText);
        if EInvoiceSetup."Integration Mode" <> EInvoiceSetup."Integration Mode"::ClearTaxDemo then
            GSTIN := LocationL."GST Registration No.";

        SendRequest('PUT', (EInvoiceSetup."Base URL" + EInvoiceSetup."URL IRN Generation"), LocationL."ClearTAX Owner ID", GSTIN, ReqText, FALSE, FALSE, SalesInvHeader."No.");
    end;

    local procedure ReadBuyerDetailsSalesInvoice()
    var
        customerL: Record Customer;
        JSubObject: JsonObject;
        StateL: Record State;
        ShiptoAddressL: Record "Ship-to Address";
        ContactL: Record Contact;
        SalesInvoiceLineL: Record "Sales Invoice Line";
    begin
        //   if EInvoiceSetup."Integration Mode" = EInvoiceSetup."Integration Mode"::ClearTaxDemo then begin
        //     JSubObject.Add('Gstin', '29AAFCD5862R1ZR');
        //end else
        if customerL.get(SalesInvHeader."Bill-to Customer No.") then;
        if (customerL."Post Code" = '') then
            if customerL.get(SalesInvHeader."Sell-to Customer No.") then;


        if SalesInvHeader."GST Customer Type" = SalesInvHeader."GST Customer Type"::Export then
            JSubObject.Add('Gstin', 'URP')
        else
            JSubObject.Add('Gstin', SalesInvHeader."Customer GST Reg. No.");

        JSubObject.Add('LglNm', SalesInvHeader."Sell-to Customer Name");
        JSubObject.Add('TrdNm', SalesInvHeader."Bill-to Name");
        JSubObject.Add('Addr1', SalesInvHeader."Bill-to Address");
        JSubObject.Add('Addr2', SalesInvHeader."Bill-to Address 2");
        JSubObject.Add('Loc', SalesInvHeader."Bill-to City");
        //    if EInvoiceSetup."Integration Mode" = EInvoiceSetup."Integration Mode"::ClearTaxDemo then begin
        //       JSubObject.Add('Stcd', '29');
        //      JSubObject.Add('Pin', '560016');
        //     JSubObject.Add('Pos', '29');
        // end else begin
        if SalesInvHeader."GST Customer Type" <> SalesInvHeader."GST Customer Type"::Export then begin
            if customerL."Post Code" <> '' then
                JSubObject.Add('Pin', CopyStr(customerL."Post Code", 1, 6))
            else
                JSubObject.Add('Pin', CopyStr(SalesInvHeader."Bill-to Post Code", 1, 6));
        end;
        SalesInvoiceLineL.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvoiceLineL.SetFilter("GST Place of Supply", '<>%1', SalesInvoiceLineL."GST Place of Supply"::" ");
        if SalesInvoiceLineL.FindFirst() then
            if SalesInvoiceLineL."GST Place of Supply" = SalesInvoiceLineL."GST Place of Supply"::"Bill-to Address" then begin
                if SalesInvHeader."GST Customer Type" = SalesInvHeader."GST Customer Type"::Export then begin
                    JSubObject.Add('Pos', '96');
                    JSubObject.Add('Stcd', '96');
                    JSubObject.Add('Pin', '999999');
                end else begin
                    StateL.Get(SalesInvHeader."GST Bill-to State Code");
                    JSubObject.Add('Pos', StateL."State Code (GST Reg. No.)");
                    JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                end;
                if ContactL.Get(SalesInvHeader."Bill-to Contact No.") then begin
                    JSubObject.Add('Ph', CopyStr(ContactL."Phone No.", 1, 12));
                    JSubObject.Add('Em', CopyStr(ContactL."E-Mail", 1, 100));
                end;
            end else
                if SalesInvoiceLineL."GST Place of Supply" = SalesInvoiceLineL."GST Place of Supply"::"Ship-to Address" then begin
                    if SalesInvHeader."GST Customer Type" = SalesInvHeader."GST Customer Type"::Export then begin
                        JSubObject.Add('Pos', '96');
                        JSubObject.Add('Stcd', '96');
                        JSubObject.Add('Pin', '999999');
                    end else begin
                        StateL.GET(SalesInvHeader."GST Ship-to State Code");
                        JSubObject.Add('Pos', StateL."State Code (GST Reg. No.)");
                        JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                    end;
                    if ShiptoAddressL.GET(SalesInvHeader."Sell-to Customer No.", SalesInvHeader."Ship-to Code") then begin
                        JSubObject.Add('Ph', CopyStr(ShiptoAddressL."Phone No.", 1, 12));
                        JSubObject.Add('Em', CopyStr(ShiptoAddressL."E-Mail", 1, 100));
                    end;
                end Else begin
                    StateL.get(SalesInvHeader."GST Bill-to State Code");
                    JSubObject.Add('Pos', StateL."State Code (GST Reg. No.)");

                end;
        //end;
        JObject1.Add('BuyerDtls', JSubObject);
    end;

    local procedure ReadItemDetailsSalesInvoice()
    var
        JSubObject: JsonObject;
        JSubObject1: JsonObject;
        JArrayL: JsonArray;
        UOML: Record "Unit of Measure";
        SalesInvoiceLineL: Record "Sales Invoice Line";
        TCSEntry: Record "TCS Entry";
        CurrencyExchRateL: Integer;
        ValueEntryRelationL: Record "Value Entry Relation";
        ItemLedgerEntryL: Record "Item Ledger Entry";
        ValueEntryL: Record "Value Entry";
        GSTLedgerEntryL: Record "GST Ledger Entry";
        ItemTrackingManagementL: Codeunit "Item Tracing Mgt.";
        itemL: Record Item;
        GSTGroup: Record "GST Group";
        CountL: Integer;
        InvoiceRowID: Text[250];
        xLotID: Code[20];
        TotalGSTAmtL: Decimal;
        AmtIncludingTax: Decimal;
        TotAmtItemVal: Decimal;
    begin
        CountL := 0;
        SalesInvoiceLineL.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvoiceLineL.SetFilter(Type, '<>%1', SalesInvoiceLineL.Type::" ");
        SalesInvoiceLineL.SetFilter(Quantity, '<>0');
        SalesInvoiceLineL.SetRange("System-Created Entry", FALSE);
        if SalesInvoiceLineL.FindSet() then begin
            if SalesInvoiceLineL.COUNT > 1000 then
                Error(SalesLinesErr, SalesInvoiceLineL.COUNT);
            if SalesInvHeader."Currency Factor" <> 0 then
                CurrencyExchRateL := 1 / SalesInvHeader."Currency Factor"
            else
                CurrencyExchRateL := 1;
            repeat
                Clear(JSubObject);
                Clear(TotAmtItemVal);
                CountL += 1;
                JSubObject.Add('SlNo', CountL);
                JSubObject.Add('PrdDesc', SalesInvoiceLineL.Description + ' ' + SalesInvoiceLineL."Description 2");
                if itemL.Get(SalesInvoiceLineL."No.") then;

                if GSTGroup.Get(itemL."GST Group Code") then begin

                    if GSTGroup."GST Group Type" = GSTGroup."GST Group Type"::Service then
                        JSubObject.Add('IsServc', 'Y')
                    else
                        JSubObject.Add('IsServc', 'N');
                end else begin
                    if SalesInvoiceLineL."GST Group Type" = SalesInvoiceLineL."GST Group Type"::Service then
                        JSubObject.Add('IsServc', 'Y')
                    else
                        JSubObject.Add('IsServc', 'N');
                end;


                JSubObject.Add('HsnCd', SalesInvoiceLineL."HSN/SAC Code");
                //JSubObject.Add('Barcde',''));
                JSubObject.Add('Qty', SalesInvoiceLineL.Quantity);
                JSubObject.Add('FreeQty', SalesInvoiceLineL.Quantity);
                if SalesInvoiceLineL."Unit of Measure" > '' then begin
                    UOML.GET(SalesInvoiceLineL."Unit of Measure Code");
                    // if UOML."GST Reporting UQC" > '' then
                    //     JSubObject.Add('Unit', UOML."GST Reporting UQC")
                    // else
                    JSubObject.Add('Unit', UOML."GST UQC Values");
                end else
                    JSubObject.Add('Unit', 'OTH');
                JSubObject.Add('UnitPrice', Round(SalesInvoiceLineL."Unit Price" * CurrencyExchRateL, 0.01));
                JSubObject.Add('TotAmt', Round(SalesInvoiceLineL."Line Amount" * CurrencyExchRateL, 0.01));
                JSubObject.Add('Discount', Round(SalesInvoiceLineL."Line Discount Amount" * CurrencyExchRateL, 0.01));
                //JSubObject.Add('PreTaxVal',''));
                //if SalesInvoiceLineL."GST Base Amount" = 0 then
                if SalesInvoiceLineL."GST Assessable Value (LCY)" <> 0 then
                    TotAmtItemVal := Round(SalesInvoiceLineL."GST Assessable Value (LCY)" * CurrencyExchRateL, 0.01)
                else
                    TotAmtItemVal := Round(SalesInvoiceLineL.Amount * CurrencyExchRateL, 0.01);
                JSubObject.Add('AssAmt', TotAmtItemVal);
                GetGSTCompRate(SalesInvoiceLineL."Document No.", SalesInvoiceLineL."Line No.", JSubObject, TotAmtItemVal);

                TCSEntry.SetRange("Document No.", SalesInvoiceLineL."Document No.");
                if TCSEntry.FindFirst() then
                    ;

                GSTLedgerEntryL.SetRange("Document No.", SalesInvoiceLineL."Document No.");
                GSTLedgerEntryL.SetFilter("GST Component Code", '%1|%2|%3|%4|%5', 'CGST', 'SGST', 'IGST', 'CESS', 'INTERCESS');
                if GSTLedgerEntryL.FindSet() then
                    repeat
                        TotalGSTAmtL += ABS(GSTLedgerEntryL."GST Amount");
                    until GSTLedgerEntryL.Next() = 0;



                AmtIncludingTax := Round(SalesInvoiceLineL."Line Amount" * CurrencyExchRateL, 0.01);
                JSubObject.Add('OthChrg', /*SalesInvoiceLineL."Charges To Customer" +*/ TCSEntry."Total TCS Including SHE CESS");
                JSubObject.Add('TotItemVal', TotAmtItemVal);
                //JSubObject.Add('OrdLineRef',''));
                //JSubObject.Add('OrgCntry',''));
                //JSubObject.Add('PrdSlNo',''));
                // InvoiceRowID := ItemTrackingManagementL.ComposeRowID(DATABASE::"Sales Invoice Line", 0, SalesInvoiceLineL."Document No.", '', 0, SalesInvoiceLineL."Line No.");
                // ValueEntryRelationL.SetCurrentKey("Source RowId");
                // ValueEntryRelationL.SetRange("Source RowId", InvoiceRowID);
                // if ValueEntryRelationL.FindFirst() then begin
                //     xLotID := '';
                //     ValueEntryL.GET(ValueEntryRelationL."Value Entry No.");
                //     ItemLedgerEntryL.SETCURRENTKEY("Item No.", Open, "Variant Code", Positive, "Lot No.", "Serial No.");
                //     ItemLedgerEntryL.GET(ValueEntryL."Item Ledger Entry No.");
                //     if xLotID <> ItemLedgerEntryL."Lot No." then begin
                //         JSubObject1.Add('Nm', CopyStr(ItemLedgerEntryL."Lot No.", 1, 20));
                //         JSubObject1.Add('ExpDt', Format(ItemLedgerEntryL."Expiration Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                //         JSubObject1.Add('WrDt', Format(ItemLedgerEntryL."Warranty Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                //         xLotID := CopyStr(ItemLedgerEntryL."Lot No.", 1, 20);
                //         JSubObject.Add('BchDtls', JSubObject1);
                //     end;
                // end;
                JArrayL.Add(JSubObject);
            until SalesInvoiceLineL.NEXT = 0;
        end;
        JObject1.Add('ItemList', JArrayL);
    end;

    procedure GenerateIRNSalesCreditmemo(var SalesCrMemoHeaderP: Record "Sales Cr.Memo Header")
    var
        //GSTManagementL: Codeunit "16401";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        LocationL: Record Location;
        ReqText: Text;
    begin
        Clear(JArray);
        Clear(ReqText);
        Clear(JObject);
        Clear(JObject1);
        Clear(IRNG);
        Clear(GSTIN);
        Clear(IsInvoice);
        EInvoiceSetup.Get();
        SalesCrMemoHdr.COPY(SalesCrMemoHeaderP);
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-Invoice");
        EInvoiceEntryL.SetRange("Document Type", EInvoiceEntryL."Document Type"::CrMemo);
        EInvoiceEntryL.SetRange("Document No.", SalesCrMemoHdr."No.");
        if EInvoiceEntryL.FindFirst() then
            if EInvoiceEntryL.IRN > '' then
                exit;
        LocationL.GET(SalesCrMemoHdr."Location Code");
        if SalesCrMemoHdr."GST Customer Type" in [SalesCrMemoHdr."GST Customer Type"::Unregistered, SalesCrMemoHdr."GST Customer Type"::" "] then
            exit;
        ReadTransactionDetails();
        ReadDocumentDetails(SalesCrMemoHdr."No.", SalesCrMemoHdr."Posting Date");
        ReadSellerDetails(SalesCrMemoHdr."Location Code", SalesCrMemoHdr."Location GST Reg. No.");
        ReadBuyerDetailsSalesCrMemo();
        ReadShipDetails(SalesCrMemoHdr."Ship-to Code", SalesCrMemoHdr."Sell-to Customer No.", SalesCrMemoHdr."GST Customer Type",
           SalesCrMemoHdr."Sell-to Customer Name", SalesCrMemoHdr."Sell-to Address", SalesCrMemoHdr."Sell-to Address 2",
           SalesCrMemoHdr."Sell-to City", SalesCrMemoHdr."Sell-to Post Code", SalesCrMemoHdr."GST Ship-to State Code");
        ReadItemDetailsSalesCrMemo();
        GetGSTVal(SalesCrMemoHdr."No.", SalesCrMemoHdr."Posting Date", IsInvoice);
        ReadExportDetails(SalesCrMemoHdr."GST Customer Type", SalesCrMemoHdr."Bill Of Export No.",
            SalesCrMemoHdr."Bill Of Export Date", SalesCrMemoHdr."exit Point", SalesCrMemoHdr."Currency Code", SalesCrMemoHdr."Bill-to Country/Region Code");
        JObject.Add('transaction', JObject1);
        JArray.Add(JObject);
        // ReqText.AddText(Format(JArray));
        JArray.WriteTo(ReqText);
        if EInvoiceSetup."Integration Mode" <> EInvoiceSetup."Integration Mode"::ClearTaxDemo then
            GSTIN := LocationL."GST Registration No.";
        SendRequest('PUT', (EInvoiceSetup."Base URL" + EInvoiceSetup."URL IRN Generation"), LocationL."ClearTAX Owner ID", GSTIN, ReqText, FALSE, FALSE, SalesCrMemoHdr."No.")


    end;

    local procedure ReadBuyerDetailsSalesCrMemo()
    var
        customerL: Record Customer;
        JSubObject: JsonObject;
        StateL: Record State;
        ShiptoAddressL: Record "Ship-to Address";
        ContactL: Record Contact;
        SalesCrMemoLineL: Record "Sales Cr.Memo Line";
    begin
        //  if EInvoiceSetup."Integration Mode" = EInvoiceSetup."Integration Mode"::ClearTaxDemo then begin
        //     JSubObject.Add('Gstin', '29AAFCD5862R1ZR');
        //end else
        if customerL.get(SalesCrMemoHdr."Bill-to Customer No.") then;
        if (customerL."Post Code" = '') then
            if customerL.get(SalesCrMemoHdr."Sell-to Customer No.") then;

        if SalesCrMemoHdr."GST Customer Type" = SalesCrMemoHdr."GST Customer Type"::Export then
            JSubObject.Add('Gstin', 'URP')
        else
            JSubObject.Add('Gstin', SalesCrMemoHdr."Customer GST Reg. No.");
        JSubObject.Add('LglNm', SalesCrMemoHdr."Sell-to Customer Name");
        JSubObject.Add('TrdNm', SalesCrMemoHdr."Bill-to Name");
        JSubObject.Add('Addr1', SalesCrMemoHdr."Bill-to Address");
        JSubObject.Add('Addr2', SalesCrMemoHdr."Bill-to Address 2");
        JSubObject.Add('Loc', SalesCrMemoHdr."Bill-to City");
        //if EInvoiceSetup."Integration Mode" = EInvoiceSetup."Integration Mode"::ClearTaxDemo then begin
        //   JSubObject.Add('Stcd', '29');
        //  JSubObject.Add('Pin', '560037');
        // JSubObject.Add('Pos', '29');
        //end else begin
        if SalesCrMemoHdr."GST Customer Type" <> SalesCrMemoHdr."GST Customer Type"::Export then begin
            if (customerL."Post Code" <> '') then
                JSubObject.Add('Pin', CopyStr(customerL."Post Code", 1, 6))
            else
                JSubObject.Add('Pin', CopyStr(SalesCrMemoHdr."Bill-to Post Code", 1, 6));

        end;


        SalesCrMemoLineL.SetRange("Document No.", SalesCrMemoHdr."No.");
        SalesCrMemoLineL.SetFilter("GST Place of Supply", '<>%1', SalesCrMemoLineL."GST Place of Supply"::" ");
        if SalesCrMemoLineL.FindFirst() then
            if SalesCrMemoLineL."GST Place of Supply" = SalesCrMemoLineL."GST Place of Supply"::"Bill-to Address" then begin
                if SalesCrMemoHdr."GST Customer Type" = SalesCrMemoHdr."GST Customer Type"::Export then begin
                    JSubObject.Add('Pos', '96');
                    JSubObject.Add('stcd', '96');
                    JSubObject.Add('Pin', '999999');
                end else begin
                    StateL.GET(SalesCrMemoHdr."GST Bill-to State Code");
                    JSubObject.Add('Pos', StateL."State Code (GST Reg. No.)");
                    JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                end;
                if ContactL.GET(SalesCrMemoHdr."Bill-to Contact No.") then begin
                    JSubObject.Add('Ph', CopyStr(ContactL."Phone No.", 1, 12));
                    JSubObject.Add('Em', CopyStr(ContactL."E-Mail", 1, 100));
                end;
            end else
                if SalesCrMemoLineL."GST Place of Supply" = SalesCrMemoLineL."GST Place of Supply"::"Ship-to Address" then begin
                    if SalesCrMemoHdr."GST Customer Type" = SalesCrMemoHdr."GST Customer Type"::Export then begin
                        JSubObject.Add('Pos', '96');
                        JSubObject.Add('stcd', '96');
                        JSubObject.Add('Pin', '999999');
                    end else begin
                        StateL.GET(SalesCrMemoHdr."GST Ship-to State Code");
                        JSubObject.Add('Pos', StateL."State Code (GST Reg. No.)");
                        JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                    end;
                    if ShiptoAddressL.GET(SalesCrMemoHdr."Sell-to Customer No.", SalesCrMemoHdr."Ship-to Code") then begin
                        JSubObject.Add('Ph', CopyStr(ShiptoAddressL."Phone No.", 1, 12));
                        JSubObject.Add('Em', CopyStr(ShiptoAddressL."E-Mail", 1, 100));
                    end;
                end;
        //end;
        JObject1.Add('BuyerDtls', JSubObject);
    end;

    local procedure ReadItemDetailsSalesCrMemo()
    var
        JSubObject: JsonObject;
        JSubObject1: JsonObject;
        JArrayL: JsonArray;
        UOML: Record "Unit of Measure";
        SalesCrMemoLineL: Record "Sales Cr.Memo Line";
        CurrencyExchRateL: Integer;
        ValueEntryRelationL: Record "Value Entry Relation";
        ItemLedgerEntryL: Record "Item Ledger Entry";
        ValueEntryL: Record "Value Entry";
        ItemL: Record Item;
        GstGroup: Record "GST Group";
        ItemTrackingManagementL: Codeunit "Item Tracing Mgt.";
        CountL: Integer;
        InvoiceRowID: Text[250];
        xLotID: Code[20];
        TCSEntry: Record "TCS Entry";
        AmtIncludingTax: Decimal;
        GSTLedgerEntryL: Record "GST Ledger Entry";
        TotalGSTAmtL: Decimal;
        TotalAmtItemVal: Decimal;
    begin
        CountL := 0;
        SalesCrMemoLineL.SetRange("Document No.", SalesCrMemoHdr."No.");
        SalesCrMemoLineL.SetFilter(Type, '<>%1', SalesCrMemoLineL.Type::" ");
        SalesCrMemoLineL.SetFilter(Quantity, '<>0');
        SalesCrMemoLineL.SetRange("System-Created Entry", FALSE);
        if SalesCrMemoLineL.FindSet() then begin
            if SalesCrMemoLineL.COUNT > 1000 then
                Error(SalesLinesErr, SalesCrMemoLineL.COUNT);
            if SalesCrMemoHdr."Currency Factor" <> 0 then
                CurrencyExchRateL := 1 / SalesCrMemoHdr."Currency Factor"
            else
                CurrencyExchRateL := 1;
            repeat
                Clear(TotalAmtItemVal);
                Clear(JSubObject);
                CountL += 1;
                JSubObject.Add('SlNo', CountL);
                JSubObject.Add('PrdDesc', SalesCrMemoLineL.Description + ' ' + SalesCrMemoLineL."Description 2");
                if itemL.Get(SalesCrMemoLineL."No.") then;

                if GSTGroup.Get(itemL."GST Group Code") then begin

                    if GSTGroup."GST Group Type" = GSTGroup."GST Group Type"::Service then
                        JSubObject.Add('IsServc', 'Y')
                    else
                        JSubObject.Add('IsServc', 'N');
                end else begin
                    if SalesCrMemoLineL."GST Group Type" = SalesCrMemoLineL."GST Group Type"::Service then
                        JSubObject.Add('IsServc', 'Y')
                    else
                        JSubObject.Add('IsServc', 'N');
                end;
                JSubObject.Add('HsnCd', SalesCrMemoLineL."HSN/SAC Code");
                //JSubObject.Add('Barcde',''));
                JSubObject.Add('Qty', SalesCrMemoLineL.Quantity);
                // if SalesCrMemoLineL."Free Supply" then
                JSubObject.Add('FreeQty', SalesCrMemoLineL.Quantity);
                // else
                //     JSubObject.Add('FreeQty', 0);
                if SalesCrMemoLineL."Unit of Measure" > '' then begin
                    UOML.GET(SalesCrMemoLineL."Unit of Measure Code");
                    // if UOML."GST Reporting UQC" > '' then
                    //     JSubObject.Add('Unit', UOML."GST Reporting UQC")
                    // else
                    JSubObject.Add('Unit', UOML."GST UQC Values");
                end else
                    JSubObject.Add('Unit', 'OTH');
                JSubObject.Add('UnitPrice', Round(SalesCrMemoLineL."Unit Price" * CurrencyExchRateL, 0.01));
                JSubObject.Add('TotAmt', Round(SalesCrMemoLineL."Line Amount" * CurrencyExchRateL, 0.01));
                JSubObject.Add('Discount', Round(SalesCrMemoLineL."Line Discount Amount" * CurrencyExchRateL, 0.01));
                //JSubObject.Add('PreTaxVal',''));
                // if SalesCrMemoLineL."GST Base Amount" = 0 then
                if SalesCrMemoLineL."GST Assessable Value (LCY)" <> 0 then
                    TotalAmtItemVal := Round(SalesCrMemoLineL."GST Assessable Value (LCY)" * CurrencyExchRateL, 0.01)
                else
                    TotalAmtItemVal := Round(SalesCrMemoLineL.Amount * CurrencyExchRateL, 0.01);
                JSubObject.Add('AssAmt', TotalAmtItemVal);
                // else
                //     JSubObject.Add('AssAmt', Round(SalesCrMemoLineL."GST Base Amount" * CurrencyExchRateL, 0.01));
                GetGSTCompRate(SalesCrMemoLineL."Document No.", SalesCrMemoLineL."Line No.", JSubObject, TotalAmtItemVal);

                TCSEntry.SetRange("Document No.", SalesCrMemoLineL."Document No.");
                if TCSEntry.FindFirst() then
                    ;
                /*
                                GSTLedgerEntryL.SetRange("Document No.", SalesCrMemoLineL."Document No.");
                                GSTLedgerEntryL.SetFilter("GST Component Code", '%1|%2|%3|%4|%5', 'CGST', 'SGST', 'IGST', 'CESS', 'INTERCESS');
                                if GSTLedgerEntryL.FindSet() then
                                    repeat
                                        TotalGSTAmtL += ABS(GSTLedgerEntryL."GST Amount");
                                    until GSTLedgerEntryL.Next() = 0;
                */
                AmtIncludingTax := Round(SalesCrMemoLineL."Line Amount" * CurrencyExchRateL, 0.01);

                JSubObject.Add('OthChrg', /*SalesCrMemoLineL."Charges To Customer" +*/ TCSEntry."Total TCS Including SHE CESS");
                JSubObject.Add('TotItemVal', TotalAmtItemVal);
                //JSubObject.Add('OrdLineRef',''));
                //JSubObject.Add('OrgCntry',''));
                //JSubObject.Add('PrdSlNo',''));
                // InvoiceRowID := ItemTrackingManagementL.ComposeRowID(DATABASE::"Sales Cr.Memo Line", 0, SalesCrMemoLineL."Document No.", '', 0, SalesCrMemoLineL."Line No.");
                // ValueEntryRelationL.SETCURRENTKEY("Source RowId");
                // ValueEntryRelationL.SetRange("Source RowId", InvoiceRowID);
                // if ValueEntryRelationL.FindFirst() then begin
                //     xLotID := '';
                //     ValueEntryL.GET(ValueEntryRelationL."Value Entry No.");
                //     ItemLedgerEntryL.SETCURRENTKEY("Item No.", Open, "Variant Code", Positive, "Lot No.", "Serial No.");
                //     ItemLedgerEntryL.GET(ValueEntryL."Item Ledger Entry No.");
                //     if xLotID <> ItemLedgerEntryL."Lot No." then begin
                //         JSubObject1.Add('Nm', CopyStr(ItemLedgerEntryL."Lot No.", 1, 20));
                //         JSubObject1.Add('ExpDt', Format(ItemLedgerEntryL."Expiration Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                //         JSubObject1.Add('WrDt', Format(ItemLedgerEntryL."Warranty Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                //         xLotID := CopyStr(ItemLedgerEntryL."Lot No.", 1, 20);
                //         JSubObject.Add('BchDtls', JSubObject1);
                //     end;
                // end;
                JArrayL.Add(JSubObject);
            until SalesCrMemoLineL.NEXT = 0;
        end;
        JObject1.Add('ItemList', JArrayL);
    end;

    local procedure ReadTransactionDetails()
    var
        JSubObject: JsonObject;
        RecRef: RecordRef;
    begin
        if IsInvoice then
            RecRef.GETTABLE(SalesInvHeader)
        else
            RecRef.GETTABLE(SalesCrMemoHdr);
        JObject1.Add('Version', '1.1');
        JSubObject.Add('TaxSch', 'GST');
        JSubObject.Add('SupTyp', GetCustomerType(RecRef));
        JSubObject.Add('RegRev', 'N');
        //JSubObject1.Add('EcmGstin',));
        //JSubObject1.Add('IgstOnIntra'));
        JObject1.Add('TranDtls', JSubObject);
    end;

    local procedure ReadDocumentDetails(DocNo: Code[20]; PostingDate: Date)
    var
        JSubObject: JsonObject;
    begin
        JSubObject.Add('Typ', GetDocumentType);
        JSubObject.Add('No', DocNo);
        JSubObject.Add('Dt', Format(PostingDate, 0, '<Day,2>/<Month,2>/<Year4>'));
        // JSubObject.Add('Dt', '08/08/2022');
        JObject1.Add('DocDtls', JSubObject);
    end;

    local procedure ReadSellerDetails(LocationCodeP: Code[10]; GSTNo: Code[15])
    var
        JSubObject: JsonObject;
        CompanyInformationL: Record "Company Information";
        StateL: Record State;
        LocationL: Record Location;
    begin
        CompanyInformationL.Get();
        if EInvoiceSetup."Integration Mode" = EInvoiceSetup."Integration Mode"::ClearTaxDemo then begin
            LocationL.Get(LocationCodeP);
            StateL.Get(LocationL."State Code");
            case StateL.Code of
                'KA':
                    begin
                        GSTIN := '29AAFCD5862R000';
                        JSubObject.Add('Gstin', GSTIN);
                        JSubObject.Add('Stcd', '29');
                        JSubObject.Add('Pin', '560037');
                    end;
                'ND':
                    begin
                        GSTIN := '07AAFCD5862R007';
                        JSubObject.Add('Gstin', GSTIN);
                        JSubObject.Add('Stcd', '07');
                        JSubObject.Add('Pin', '110001');
                    end;
                'HR':
                    begin
                        GSTIN := '06AAFCD5862R017';
                        JSubObject.Add('Gstin', GSTIN);
                        JSubObject.Add('Stcd', '06');
                        JSubObject.Add('Pin', '121001');
                    end;
                'MH':
                    begin
                        GSTIN := '27AAFCD5862R013';
                        JSubObject.Add('Gstin', GSTIN);
                        JSubObject.Add('Stcd', '27');
                        JSubObject.Add('Pin', '431520');
                    end;
            end;

        end else begin
            JSubObject.Add('Gstin', GSTNo);
        end;
        LocationL.GET(LocationCodeP);
        StateL.GET(LocationL."State Code");
        if EInvoiceSetup."Integration Mode" <> EInvoiceSetup."Integration Mode"::ClearTaxDemo then begin
            JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
            JSubObject.Add('Pin', CopyStr(LocationL."Post Code", 1, 6));
        end;
        JSubObject.Add('LglNm', LocationL.Name);
        JSubObject.Add('TrdNm', CompanyInformationL.Name);
        JSubObject.Add('Addr1', LocationL.Address);
        JSubObject.Add('Addr2', LocationL."Address 2");
        JSubObject.Add('Loc', LocationL.City);


        JSubObject.Add('Ph', DELCHR(CopyStr(LocationL."Phone No.", 1, 12), '=', ' ,/-<>  !@#$%^&*()_+{}'));
        JSubObject.Add('Em', CopyStr(LocationL."E-Mail", 1, 100));
        JObject1.Add('SellerDtls', JSubObject);
    end;

    local procedure ReadShipDetails(ShipToCodeP: Code[10]; SellToCustNoP: Code[20]; CustTypeP: Option; NameP: Text; AddrP: Text; Addr2P: Text; CityP: Text; PostCodeP: Text; GSTState: Code[10])
    var
        JSubObject: JsonObject;
        ShipToAddressL: Record "Ship-to Address";
        StateL: Record State;
        GSTCustomerType: Option " ",Registered,Unregistered,Export,"Deemed Export",Exempted,"SEZ Development","SEZ Unit";
    begin
        if ShipToCodeP <> '' then begin
            ShipToAddressL.GET(SellToCustNoP, ShipToCodeP);
            if CustTypeP = GSTCustomerType::Export then
                JSubObject.Add('Gstin', 'URP')
            else
                JSubObject.Add('Gstin', ShipToAddressL."GST Registration No.");

            JSubObject.Add('LglNm', NameP);
            //JSubObject.Add('TrdNm',''));
            JSubObject.Add('Addr1', AddrP);
            JSubObject.Add('Addr2', Addr2P);
            JSubObject.Add('Loc', CityP);
            JSubObject.Add('Pin', CopyStr(PostCodeP, 1, 6));
            StateL.GET(GSTState);
            JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
        end;
        JObject1.Add('ShipDtls', JSubObject);
    end;

    local procedure ReadExportDetails(CustomerTypeP: Option; ExportNoP: Text; ExportDateP: Date; ExitPointP: Text; Curr: Text; Region: Text)
    var
        JSubObject: JsonObject;
        GSTCustomerType: Option " ",Registered,Unregistered,Export,"Deemed Export",Exempted,"SEZ Development","SEZ Unit";
    begin
        if CustomerTypeP IN [GSTCustomerType::Export, GSTCustomerType::"Deemed Export", GSTCustomerType::"SEZ Development",
          GSTCustomerType::"SEZ Unit"]
        then begin
            JSubObject.Add('ShipBNo', CopyStr(ExportNoP, 1, 20));
            JSubObject.Add('ShipBDt', Format(ExportDateP, 0, '<Day,2>/<Month,2>/<Year4>'));
            JSubObject.Add('Port', ExitPointP);
            JSubObject.Add('RefClm', 'N');
            JSubObject.Add('ForCur', CopyStr(Curr, 1, 16));
            JSubObject.Add('CntCode', CopyStr(Region, 1, 2));
            JObject1.Add('ExpDtls', JSubObject);
        end;
    end;

    procedure GenerateQRCodeB2C(var SalesInvHeaderP: Record "Sales Invoice Header")
    var
        //GstManagementL: Codeunit "16401";
        BankCode: Code[20];
        UPIID: Text[50];
        BankAcNumber: Text[30];
        IFSCCode: Text[20];
        InvoiceAmount: Decimal;
        TotalGSTAmount: Decimal;
        CGSTVal: Decimal;
        SGSTVal: Decimal;
        IGSTVal: Decimal;
        CESSVal: Decimal;
        QRCodeInput: Text;
        ReccordRef: RecordRef;
    begin
        SalesInvHeader.COPY(SalesInvHeaderP);
        // if NOT GstManagementL.IsGSTApplicable(SalesInvHeader.Structure) then
        //     Error(QRErr);
        // if (SalesInvHeader."Nature of Supply" <> SalesInvHeader."Nature of Supply"::B2C) AND
        //     (SalesInvHeader."GST Customer Type" <> SalesInvHeader."GST Customer Type"::Unregistered) then
        //     Error(GenerateQRCodeErr);
        if SalesInvHeader."Location Code" > '' then
            BankCode := GetCompanyBankDetails()
        else
            BankCode := GetLocationBankDetails(SalesInvHeader."Location Code");
        GetBankAcUPIDetails(BankCode, UPIID, BankAcNumber, IFSCCode);
        SalesInvHeader.CalcFields(Amount);
        if SalesInvHeader."Currency Factor" <> 0 then
            InvoiceAmount := SalesInvHeader.Amount / SalesInvHeader."Currency Factor"
        else
            InvoiceAmount := SalesInvHeader.Amount;
        GetQRGSTValues(CGSTVal, SGSTVal, IGSTVal, CESSVal);
        TotalGSTAmount := CGSTVal + SGSTVal + IGSTVal + CESSVal;
        QRCodeInput :=
           'upi://pay?pa=' + UPIID + // Payee address or business virtual payment address (VPA).
           '&pn=' + CompanyName + // Payee name or business name.
           '&SellerGstin=' + SalesInvHeader."Location GST Reg. No." +
           '&BankAcNo=' + BankAcNumber +
           '&IFSCCode=' + IFSCCode +
           '&billno=' + SalesInvHeader."No." +
           '&billDate=' + Format(SalesInvHeader."Document Date") +
           '&am=' + Format(InvoiceAmount, 0, '<Precision,2:2><Standard Format,2>') + // Transaction amount
           '&GSTAmount=' + Format(TotalGSTAmount, 0, '<Precision,2:2><Standard Format,2>') +
           '&CGST=' + Format(CGSTVal, 0, '<Precision,2:2><Standard Format,2>') +
           '&SGST=' + Format(SGSTVal, 0, '<Precision,2:2><Standard Format,2>') +
           '&IGST=' + Format(IGSTVal, 0, '<Precision,2:2><Standard Format,2>') +
           '&CESS=' + Format(CESSVal, 0, '<Precision,2:2><Standard Format,2>');
        ReccordRef.GetTable(SalesInvHeader);
        GenerateQRCode(QRCodeInput, ReccordRef);
    end;

    local procedure GetLocationBankDetails(LocCode: Code[20]) BankCode: Code[20]
    var
        VoucherAccount: Record "Voucher Posting Debit Account";
    begin
        VoucherAccount.Reset();
        //VoucherAccount.SETCURRENTKEY("Location code", "Sub Type", "Account Type", "Account No.");
        VoucherAccount.SETCURRENTKEY("Location code", "Account Type", "Account No.");
        VoucherAccount.SetRange("Location code", LocCode);
        //VoucherAccount.SetRange("Sub Type", VoucherAccount."Sub Type"::"Bank Receipt Voucher");
        VoucherAccount.SetRange("Account Type", VoucherAccount."Account Type"::"Bank Account");
        VoucherAccount.SetRange("For UPI Payments", True);
        if VoucherAccount.FindFirst() then
            BankCode := VoucherAccount."Account No."
        else
            BankCode := GetCompanyBankDetails;

        exit(BankCode);
    end;

    local procedure GetCompanyBankDetails() BankCode: Code[20]
    var
        VoucherPostingDebitAccount: Record "Voucher Posting Debit Account";
    begin
        VoucherPostingDebitAccount.Reset();
        //VoucherPostingDebitAccount.SetCurrentKey("Location code", "Sub Type", "Account Type", "Account No.");
        VoucherPostingDebitAccount.SetCurrentKey("Location code", "Account Type", "Account No.");
        VoucherPostingDebitAccount.SetRange("Location code", '');
        //VoucherPostingDebitAccount.SetRange("Sub Type", VoucherPostingDebitAccount."Sub Type"::"Bank Receipt Voucher");
        VoucherPostingDebitAccount.SetRange("Account Type", VoucherPostingDebitAccount."Account Type"::"Bank Account");
        VoucherPostingDebitAccount.SetRange("For UPI Payments", True);
        if VoucherPostingDebitAccount.FindFirst() then
            BankCode := VoucherPostingDebitAccount."Account No."
        else
            Error(VoucherAcErr);
        exit(BankCode);
    end;

    local procedure GetBankAcUPIDetails(BankAc: Code[20]; var UPIID: Text[50]; var BankAcNumber: Text[30]; var IFSCCode: Text[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.GET(BankAc);
        BankAccount.TESTFIELD("UPI ID");
        UPIID := BankAccount."UPI ID";
        BankAcNumber := BankAccount."Bank Account No.";
        IFSCCode := BankAccount."IFSC Code";
    end;

    local procedure GetQRGSTValues(var CGSTVal: Decimal; var SGSTVal: Decimal; var IGSTVal: Decimal; var CESSVal: Decimal)
    var
        GSTLedgerEntry: Record "GST Ledger Entry";
    begin
        Clear(CGSTVal);
        Clear(SGSTVal);
        Clear(IGSTVal);
        Clear(CESSVal);
        GSTLedgerEntry.Reset;
        GSTLedgerEntry.SetRange("Document No.", SalesInvHeader."No.");
        GSTLedgerEntry.SetRange("Transaction Type", GSTLedgerEntry."Transaction Type"::Sales);
        GSTLedgerEntry.SetRange("Posting Date", SalesInvHeader."Posting Date");
        GSTLedgerEntry.SetRange("Document Type", GSTLedgerEntry."Document Type"::Invoice);
        GSTLedgerEntry.SetRange("GST Component Code", 'CGST');
        GSTLedgerEntry.SetRange("Entry Type", GSTLedgerEntry."Entry Type"::"Initial Entry");
        if GSTLedgerEntry.FindSet() then
            repeat
                CGSTVal += ABS(GSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.NEXT = 0;

        GSTLedgerEntry.SetRange("GST Component Code", 'SGST');
        if GSTLedgerEntry.FindSet() then
            repeat
                SGSTVal += ABS(GSTLedgerEntry."GST Amount")
            until GSTLedgerEntry.NEXT = 0;

        GSTLedgerEntry.SetRange("GST Component Code", 'IGST');
        if GSTLedgerEntry.FindSet() then
            repeat
                IGSTVal += ABS(GSTLedgerEntry."GST Amount")
            until GSTLedgerEntry.NEXT = 0;

        GSTLedgerEntry.SetFilter("GST Component Code", '%1|%2', 'CESS', 'INTERCESS');
        if GSTLedgerEntry.FindSet() then
            repeat
                CESSVal += ABS(GSTLedgerEntry."GST Amount")
            until GSTLedgerEntry.NEXT = 0;
    end;

    local procedure GenerateQRCode(QRCodeTxt: Text; var RecRef: RecordRef)
    var
        TempBlob: Codeunit "Temp Blob";
        FieldRef: FieldRef;
        QRCodeInput: Text;
        QRCodeFileName: Text;
        EInvoice: Codeunit "e-Invoice Management";
        FileManagement: Codeunit "File Management";
        QRGenerator: Codeunit "QR Generator";
    begin
        // Save a QR code image into a file in a temporary folder.
        QRCodeInput := QRCodeTxt;
        QRGenerator.GenerateQRCodeImage(QRCodeInput, TempBlob);
        //QRCodeFileName := GetQRCode(QRCodeInput);
        //QRCodeFileName := TemporaryPath(); //EInvoice.MoveToMagicPath(QRCodeFileName); // To avoid confirmation dialogue on RTC.

        // Load the image from file into the BLOB field.
        //Clear(TempBlob);
        //TempBlob.CALCFIELDS(Blob);
        //FileManagement.BLOBImport(TempBlob, QRCodeFileName);

        //FieldRef := RecRef.FIELD(16629);
        //FieldRef.VALUE := TempBlob.Blob;
        //TempBlob.ToFieldRef(FieldRef);
        TempBlob.ToRecordRef(RecRef, 16629);
        RecRef.Modify();

        // Erase the temporary file.
        // if NOT ISSERVICETIER then
        //     if EXISTS(QRCodeFileName) then
        //         erase(QRCodeFileName);
    end;

    // local procedure GetQRCode(QRCodeInput: Text; EInvoiceLog: Record "ClearComp e-Invoice Entry")
    // var
    //     // [RunOnClient]
    //     // IBarCodeProvider: DotNet IBarcodeProvider;
    //     QRGenerator: Codeunit "QR Generator";
    //     //EInvoice: Codeunit "e-Invoice Management";
    //     TempBlob: Codeunit "Temp Blob";
    //     OutstreamL: OutStream;
    //     RecRef: RecordRef;
    // begin
    //     //EInvoice.GetBarCodeProvider(IBarCodeProvider);
    //     //QRCodeFileName := IBarCodeProvider.GetBarcode(QRCodeInput);
    //     // QRGenerator.GenerateQRCodeImage(QRCodeInput, TempBlob);
    //     // if EInvoiceLog."Document Type" = EInvoiceLog."Document Type"::Invoice then begin
    //     //     SalesInvHeader.GET(EInvoiceLog."Document No.");
    //     //     SalesInvHeader."Acknowledgement Date" := EInvoiceLog."Acknowledgment Date";
    //     //     SalesInvHeader."Acknowledgement No." := EInvoiceLog."Acknowledgment No.";
    //     //     SalesInvHeader."IRN Hash" := EInvoiceLog.IRN;
    //     //     RecRef.SetTable(SalesInvHeader);
    //     //     TempBlob.ToRecordRef(RecRef, SalesInvHeader.FieldNo("QR Code"));
    //     //     SalesInvHeader.Modify();
    //     // end else
    //     //     if EInvoiceLog."Document Type" = EInvoiceLog."Document Type"::CrMemo then begin
    //     //         SalesCrMemoHdr.GET(EInvoiceLog."Document No.");
    //     //         SalesCrMemoHdr."Acknowledgement Date" := EInvoiceLog."Acknowledgment Date";
    //     //         SalesCrMemoHdr."Acknowledgement No." := EInvoiceLog."Acknowledgment No.";
    //     //         SalesCrMemoHdr."IRN Hash" := EInvoiceLog.IRN;
    //     //         RecRef.SetTable(SalesCrMemoHdr);
    //     //         TempBlob.ToRecordRef(RecRef, SalesCrMemoHdr.FieldNo("QR Code"));
    //     //         SalesCrMemoHdr.Modify();
    //     //     end;
    //     // Message(Successful);
    // end;

    procedure GetInvoicePDF(GSTNoP: Text; LocationCodeP: Text; IRN: Text; No: Code[20])
    var
        LocationL: Record Location;
        URL: Text;
    begin
        if SalesInvHeader.get(No) then
            IsInvoice := true
        else
            if SalesCrMemoHdr.get(No) then;
        EInvoiceSetup.Get();
        LocationL.Get(LocationCodeP);
        URL := '?' + 'template=6f376678-3cc0-4bea-a9e0-ff92a60a7b00' + '&' + 'irns=' + IRN;
        SendRequest('GET', EInvoiceSetup."Base URL" + EInvoiceSetup."URL E-Invoice PDF" + URL, LocationL."ClearTAX Owner ID", GSTNoP, '', FALSE, True, No);
    end;

    procedure CancelIRN(SetIRN: Text; OwnerID: Text; GSTNo: Text)
    var
        ReqText: Text;
    begin
        EInvoiceSetup.Get();
        IRNG := SetIRN;
        WriteCancelPayload();
        JArray.Add(JObject);
        // ReqText.AddText(Format(JArray));
        JArray.WriteTo(ReqText);
        SendRequest('PUT', (EInvoiceSetup."Base URL" + EInvoiceSetup."URL IRN Cancellation"), OwnerID, GSTNo, ReqText, True, FALSE, '');
    end;

    local procedure WriteCancelPayload()
    begin
        JObject.Add('irn', IRNG);
        JObject.Add('CnlRsn', 1);
        JObject.Add('CnlRem', 'Wrong');
    end;

    local procedure ProcessCancelIRNResponse(RequestText: text; ResponseText: Text; ErrorText: Text)
    var
        CancelDateText: Text;
        IRNStatus: Text;
        SuccessText: Code[1];
        EInvoiceLog: Record "ClearComp e-Invoice Entry";
        salesInvHdr: Record "Sales Invoice Header";
        salesCrMemoHdr: Record "Sales Cr.Memo Header";
        JToken: JsonToken;
        JToken1L: JsonToken;
        JSubObjectL: JsonObject;
        JArray: JsonArray;
        JArray1: JsonArray;
        I: Integer;
        J: Integer;
        outstreamL: OutStream;


    begin
        if JArray.ReadFrom(ResponseText) then begin
            for I := 0 to JArray.Count - 1 do begin
                JArray.get(I, JToken);
                JObject := JToken.AsObject();
                if JObject.Contains('govt_response') and JObject.Get('govt_response', JToken1L) then
                    JSubObjectL := JToken1L.AsObject();
                if GetValueFromJsonObject(JSubObjectL, 'Success').AsText() = 'Y' then begin
                    SuccessText := 'Y';
                    CancelDateText := GetValueFromJsonObject(JSubObjectL, 'CancelDate').AsText();
                    if CancelDateText > '' then
                        IRNStatus := 'CNL';
                    if IRNStatus = '' then
                        IRNStatus := GetValueFromJsonObject(JSubObjectL, 'document_status').AsText();
                end else begin
                    SuccessText := 'N';
                    if JSubObjectL.Contains('ErrorDetails') and JSubObjectL.Get('ErrorDetails', JToken1L) then
                        JArray1 := JToken1L.AsArray();
                    for J := 0 to JArray1.Count - 1 do begin
                        JArray1.Get(J, JToken1L);
                        JSubObjectL := JToken1L.AsObject();
                        if ErrorText > '' then
                            ErrorText += '|' + GetValueFromJsonObject(JSubObjectL, 'error_message').AsText()
                        else
                            ErrorText := GetValueFromJsonObject(JSubObjectL, 'error_message').AsText();
                    end;
                end;
            end;
        end else
            SuccessText := 'N';

        EInvoiceLog.Reset();
        EInvoiceLog.SetRange(IRN, IRNG);
        if EInvoiceLog.FindFirst() then begin
            if UPPERCASE(SuccessText) = 'Y' then begin
                EInvoiceLog."IRN Status" := IRNStatus;
                EInvoiceLog."Cancel Date" := CancelDateText;
                EInvoiceLog."Cancelled By" := UserId;
                EInvoiceLog.Status := EInvoiceLog.Status::Cancelled;
                Clear(EInvoiceLog.IRN);
                Clear(EInvoiceLog."IRN Generated Date");

                if salesInvHdr.get(EInvoiceLog."Document No.") then begin
                    if evaluate(salesInvHdr."E-Inv. Cancelled Date", CancelDateText) then;
                    Clear(salesInvHdr."Acknowledgement No.");
                    Clear(salesInvHdr."Acknowledgement Date");
                    Clear(salesInvHdr."IRN Hash");
                    Clear(salesInvHdr."QR Code");
                    salesInvHdr.Modify();
                end;
                if salesCrMemoHdr.get(EInvoiceLog."Document No.") then begin
                    if Evaluate(salesCrMemoHdr."E-Inv. Cancelled Date", CancelDateText) then;
                    Clear(salesCrMemoHdr."Acknowledgement No.");
                    Clear(salesCrMemoHdr."Acknowledgement Date");
                    Clear(salesCrMemoHdr."IRN Hash");
                    Clear(salesCrMemoHdr."QR Code");
                    salesCrMemoHdr.Modify();
                end;
                EInvoiceLog."Request JSON".CreateOutStream(outstreamL);
                outstreamL.WriteText(RequestText);
                Clear(outstreamL);
                EInvoiceLog."Response JSON".CreateOutStream(outstreamL);
                outstreamL.WriteText(ResponseText);

                EInvoiceLog.Modify();
                Message(IRNSuccMsg);
            end else begin
                EInvoiceLog."Cancellation Error Message" := CopyStr(ErrorText, 1, 250);
                EInvoiceLog.Modify();
            end;
        end;
    end;

    local procedure GetGSTCompRate(DocNoP: Code[20]; DocLineNoP: Integer; var JSubObjectP: JsonObject; var TotAmt: decimal)
    var
        DetailedGSTLedgerEntryL: Record "Detailed GST Ledger Entry";
        GSTComponentL: Record "GST Component Distribution";
        Rate: Decimal;
        Amt: Decimal;
        Amt1: Decimal;
    begin
        DetailedGSTLedgerEntryL.SetRange("Entry Type", DetailedGSTLedgerEntryL."Entry Type"::"Initial Entry");
        DetailedGSTLedgerEntryL.SetRange("Document No.", DocNoP);
        DetailedGSTLedgerEntryL.SetRange("Document Line No.", DocLineNoP);
        DetailedGSTLedgerEntryL.SetRange("GST Component Code", 'CGST');
        if DetailedGSTLedgerEntryL.FindSet() then begin
            Rate := DetailedGSTLedgerEntryL."GST %";
            repeat

                Amt += ABS(DetailedGSTLedgerEntryL."GST Amount");
            until DetailedGSTLedgerEntryL.NEXT = 0;
        end;
        TotAmt += Amt;
        JSubObjectP.Add('CgstAmt', Amt);
        Clear(Amt);
        DetailedGSTLedgerEntryL.SetRange("GST Component Code", 'SGST');
        if DetailedGSTLedgerEntryL.FindSet() then begin
            Rate += DetailedGSTLedgerEntryL."GST %";
            repeat
                Amt += ABS(DetailedGSTLedgerEntryL."GST Amount");
            until DetailedGSTLedgerEntryL.NEXT = 0;
        end;
        TotAmt += Amt;
        JSubObjectP.Add('SgstAmt', Amt);
        Clear(Amt);
        DetailedGSTLedgerEntryL.SetRange("GST Component Code", 'IGST');

        if DetailedGSTLedgerEntryL.FindSet() then begin
            Rate += DetailedGSTLedgerEntryL."GST %";
            repeat
                Amt += ABS(DetailedGSTLedgerEntryL."GST Amount");
            until DetailedGSTLedgerEntryL.NEXT = 0;
        end;
        TotAmt += Amt;
        JSubObjectP.Add('IgstAmt', Amt);
        JSubObjectP.Add('GstRt', Rate);
        Clear(Amt);
        Clear(Rate);
        DetailedGSTLedgerEntryL.SetFilter("GST Component Code", '%1|%2', 'CESS', 'INTERCESS');
        if DetailedGSTLedgerEntryL.FindSet() then begin
            repeat
                Rate := DetailedGSTLedgerEntryL."GST %";
                if DetailedGSTLedgerEntryL."GST %" <> 0 then
                    Amt += ABS(DetailedGSTLedgerEntryL."GST Amount")
                else
                    Amt1 += ABS(DetailedGSTLedgerEntryL."GST Amount");
            until DetailedGSTLedgerEntryL.NEXT = 0;
        end;
        JSubObjectP.Add('CesRt', Rate);
        JSubObjectP.Add('CesAmt', Amt);
        JSubObjectP.Add('CesNonAdvlAmt', Amt1);
        Clear(Rate);
        Clear(Amt);
        Clear(Amt1);
        DetailedGSTLedgerEntryL.SetRange("GST Component Code");
        if DetailedGSTLedgerEntryL.FindSet() then
            repeat
                if NOT (DetailedGSTLedgerEntryL."GST Component Code" IN ['CGST', 'SGST', 'IGST', 'CESS', 'INTERCESS']) then
                    if GSTComponentL.GET(DetailedGSTLedgerEntryL."GST Component Code") then
                        if DetailedGSTLedgerEntryL."GST %" <> 0 then begin
                            Rate := DetailedGSTLedgerEntryL."GST %";
                            Amt += ABS(DetailedGSTLedgerEntryL."GST Amount");
                        end else
                            Amt1 += ABS(DetailedGSTLedgerEntryL."GST Amount");
            until DetailedGSTLedgerEntryL.NEXT = 0;
        JSubObjectP.Add('StateCesRt', Rate);
        JSubObjectP.Add('StateCesAmt', Amt);
        JSubObjectP.Add('StateCesNonAdvlAmt', Amt1);
    end;

    local procedure GetGSTVal(DocNoP: Code[20]; PostingDateP: Date; DoctypeP: Boolean)
    var
        GSTLedgerEntryL: Record "GST Ledger Entry";
        GSTComponentL: Record "GST Component Distribution";
        SalesInvoiceLineL: Record "Sales Invoice Line";
        SalesCrMemoLineL: Record "Sales Cr.Memo Line";
        CurrencyExchangeRateL: Record "Currency Exchange Rate";
        JSubObject: JsonObject;
        Amt: Decimal;
        AssVal: Decimal;
        Rate: Decimal;
        TotGSTAmt: Decimal;
        Disc: Decimal;
        Othchrg: Decimal;
        RndOffAmt: Decimal;
        TotalInvValFc: Decimal;
        CGSTAmt: Decimal;
        SGSTAmt: Decimal;
        IGSTAmt: Decimal;
        InterCessAmt: Decimal;
        STCESAmt: Decimal;
        TCSEntry: Record "TCS Entry";
    begin
        GSTLedgerEntryL.SetRange("Document No.", DocNoP);
        GSTLedgerEntryL.SetRange("Transaction Type", GSTLedgerEntryL."Transaction Type"::Sales);
        GSTLedgerEntryL.SetRange("Posting Date", PostingDateP);
        if DoctypeP then
            GSTLedgerEntryL.SetRange("Document Type", GSTLedgerEntryL."Document Type"::Invoice)
        else
            GSTLedgerEntryL.SetRange("Document Type", GSTLedgerEntryL."Document Type"::"Credit Memo");

        GSTLedgerEntryL.SetRange("GST Component Code", 'CGST');
        if GSTLedgerEntryL.FindSet() then begin
            repeat
                Amt += ABS(GSTLedgerEntryL."GST Amount");
            until GSTLedgerEntryL.NEXT = 0;
        end else
            Amt := 0;
        CGSTAmt := Amt;
        JSubObject.Add('CgstVal', Amt);
        Clear(Amt);
        GSTLedgerEntryL.SetRange("GST Component Code", 'SGST');
        if GSTLedgerEntryL.FindSet() then begin
            repeat
                Amt += ABS(GSTLedgerEntryL."GST Amount");
            until GSTLedgerEntryL.NEXT = 0;
        end else
            Amt := 0;
        SGSTAmt := Amt;
        JSubObject.Add('SgstVal', Amt);
        Clear(Amt);
        GSTLedgerEntryL.SetRange("GST Component Code", 'IGST');
        if GSTLedgerEntryL.FindSet() then begin
            repeat
                Amt += ABS(GSTLedgerEntryL."GST Amount")
            until GSTLedgerEntryL.NEXT = 0;
        end else
            Amt := 0;
        IGSTAmt := Amt;
        JSubObject.Add('IgstVal', Amt);
        Clear(Amt);
        GSTLedgerEntryL.SetFilter("GST Component Code", '%1|%2', 'CESS', 'INTERCESS');
        if GSTLedgerEntryL.FindSet() then
            repeat
                Amt += ABS(GSTLedgerEntryL."GST Amount")
            until GSTLedgerEntryL.NEXT = 0;
        InterCessAmt := Amt;
        JSubObject.Add('CesVal', Amt);
        Clear(Amt);
        GSTLedgerEntryL.SetFilter("GST Component Code", '<>CGST&<>SGST&<>IGST&<>CESS&<>INTERCESS');
        if GSTLedgerEntryL.FindSet() then begin
            repeat
                if GSTComponentL.GET(GSTLedgerEntryL."GST Component Code") then
                    Amt += ABS(GSTLedgerEntryL."GST Amount");
            until GSTLedgerEntryL.NEXT = 0;
        end;
        STCESAmt := Amt;
        JSubObject.Add('StCesVal', Amt);
        Clear(Amt);
        Clear(AssVal);
        Clear(Disc);
        if DoctypeP then begin
            SalesInvoiceLineL.SetRange("Document No.", DocNoP);
            SalesInvoiceLineL.SetFilter(Quantity, '<>0');
            SalesInvoiceLineL.SetRange("System-Created Entry", FALSE);
            if SalesInvoiceLineL.FindSet() then begin
                repeat
                    Amt += SalesInvoiceLineL."Line Amount";
                    AssVal += SalesInvoiceLineL.Amount;
                    Disc += SalesInvoiceLineL."Inv. Discount Amount";
                until SalesInvoiceLineL.NEXT = 0;
            end;

            TotGSTAmt := CGSTAmt + SGSTAmt + IGSTAmt + InterCessAmt + STCESAmt;

            TCSEntry.SetRange("Document No.", DocNoP);
            if TCSEntry.FindFirst() then
                Othchrg := TCSEntry."Total TCS Including SHE CESS";

            SalesInvoiceLineL.SetRange(Type, SalesInvoiceLineL.Type::"G/L Account");
            SalesInvoiceLineL.SetRange("System-Created Entry", True);
            if SalesInvoiceLineL.FindFirst() then
                repeat
                    RndOffAmt += SalesInvoiceLineL."Line Amount";
                until SalesInvoiceLineL.NEXT = 0;
            TotalInvValFc := Amt + TotGSTAmt + Othchrg + RndOffAmt - Disc;
            AssVal := Round(
                CurrencyExchangeRateL.ExchangeAmtFCYToLCY(SalesInvHeader."Posting Date",
                  SalesInvHeader."Currency Code", AssVal, SalesInvHeader."Currency Factor"), 0.01, '=');
            JSubObject.Add('AssVal', AssVal);

            Disc := Round(
                CurrencyExchangeRateL.ExchangeAmtFCYToLCY(SalesInvHeader."Posting Date",
                  SalesInvHeader."Currency Code", Disc, SalesInvHeader."Currency Factor"), 0.01, '=');
            JSubObject.Add('Discount', Disc);

            Othchrg := Round(
                CurrencyExchangeRateL.ExchangeAmtFCYToLCY(SalesInvHeader."Posting Date",
                  SalesInvHeader."Currency Code", Othchrg, SalesInvHeader."Currency Factor"), 0.01, '=');
            JSubObject.Add('OthChrg', Othchrg);

            Amt := Amt + TotGSTAmt + Othchrg + RndOffAmt - Disc;

            JSubObject.Add('RndOffAmt', RndOffAmt);

            JSubObject.Add('TotInvVal', Amt);

            JSubObject.Add('TotInvValFc', TotalInvValFc);

        end else begin
            // Above same things need to be done for Sales Cr. Memo
            SalesCrMemoLineL.SetRange("Document No.", DocNoP);
            SalesCrMemoLineL.SetFilter(Quantity, '<>0');
            SalesCrMemoLineL.SetRange("System-Created Entry", FALSE);
            if SalesCrMemoLineL.FindSet() then begin
                repeat
                    Amt += SalesCrMemoLineL."Line Amount";
                    AssVal += SalesCrMemoLineL.Amount;
                    Disc += SalesCrMemoLineL."Inv. Discount Amount";
                until SalesCrMemoLineL.NEXT = 0;
            end;

            TotGSTAmt := CGSTAmt + SGSTAmt + IGSTAmt + InterCessAmt + STCESAmt;

            TCSEntry.SetRange("Document No.", DocNoP);
            if TCSEntry.FindFirst() then
                Othchrg := TCSEntry."Total TCS Including SHE CESS";

            SalesCrMemoLineL.SetRange(Type, SalesInvoiceLineL.Type::"G/L Account");
            SalesCrMemoLineL.SetRange("System-Created Entry", True);
            if SalesCrMemoLineL.FindFirst() then
                repeat
                    RndOffAmt += SalesCrMemoLineL."Line Amount";
                until SalesCrMemoLineL.NEXT = 0;
            TotalInvValFc := Amt + TotGSTAmt + Othchrg + RndOffAmt - Disc;
            AssVal := Round(
                CurrencyExchangeRateL.ExchangeAmtFCYToLCY(SalesCrMemoHdr."Posting Date",
                  SalesCrMemoHdr."Currency Code", AssVal, SalesCrMemoHdr."Currency Factor"), 0.01, '=');
            JSubObject.Add('AssVal', AssVal);

            Disc := Round(
                CurrencyExchangeRateL.ExchangeAmtFCYToLCY(SalesCrMemoHdr."Posting Date",
                  SalesCrMemoHdr."Currency Code", Disc, SalesCrMemoHdr."Currency Factor"), 0.01, '=');
            JSubObject.Add('Discount', Disc);

            Othchrg := Round(
                CurrencyExchangeRateL.ExchangeAmtFCYToLCY(SalesCrMemoHdr."Posting Date",
                  SalesCrMemoHdr."Currency Code", Othchrg, SalesCrMemoHdr."Currency Factor"), 0.01, '=');
            JSubObject.Add('OthChrg', Othchrg);

            Amt := Amt + TotGSTAmt + Othchrg + RndOffAmt - Disc;

            JSubObject.Add('RndOffAmt', RndOffAmt);

            JSubObject.Add('TotInvVal', Amt);

            JSubObject.Add('TotInvValFc', TotalInvValFc);
        end;
        JObject1.Add('ValDtls', JSubObject);
    end;

    local procedure GetCustomerType(RecordRefP: RecordRef): Text
    begin
        CASE RecordRefP.NUMBER OF
            DATABASE::"Sales Invoice Header":
                begin
                    if SalesInvHeader."GST Customer Type" IN [SalesInvHeader."GST Customer Type"::Registered, SalesInvHeader."GST Customer Type"::Exempted] then
                        exit('B2B');
                    if SalesInvHeader."GST Customer Type" = SalesInvHeader."GST Customer Type"::Export then
                        if SalesInvHeader."GST Without Payment of Duty" then
                            exit('EXPWOP')
                        else
                            exit('EXPWP');
                    if SalesInvHeader."GST Customer Type" = SalesInvHeader."GST Customer Type"::"Deemed Export" then
                        exit('DEXP');
                    if SalesInvHeader."GST Customer Type" IN [SalesInvHeader."GST Customer Type"::"SEZ Development", SalesInvHeader."GST Customer Type"::"SEZ Unit"] then
                        if SalesInvHeader."GST Without Payment of Duty" then
                            exit('SEZWOP')
                        else
                            exit('SEZWP');
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    if SalesCrMemoHdr."GST Customer Type" IN [SalesCrMemoHdr."GST Customer Type"::Registered, SalesCrMemoHdr."GST Customer Type"::Exempted] then
                        exit('B2B');
                    if SalesCrMemoHdr."GST Customer Type" = SalesCrMemoHdr."GST Customer Type"::Export then
                        if SalesCrMemoHdr."GST Without Payment of Duty" then
                            exit('EXPWOP')
                        else
                            exit('EXPWP');
                    if SalesCrMemoHdr."GST Customer Type" = SalesCrMemoHdr."GST Customer Type"::"Deemed Export" then
                        exit('DEXP');
                    if SalesCrMemoHdr."GST Customer Type" IN [SalesCrMemoHdr."GST Customer Type"::"SEZ Development", SalesCrMemoHdr."GST Customer Type"::"SEZ Unit"] then
                        if SalesCrMemoHdr."GST Without Payment of Duty" then
                            exit('SEZWOP')
                        else
                            exit('SEZWP');
                end;
        end;
    end;

    local procedure GetDocumentType(): Text
    begin
        if IsInvoice then begin
            if SalesInvHeader."Invoice Type" IN [SalesInvHeader."Invoice Type"::"Debit Note", SalesInvHeader."Invoice Type"::Supplementary] then
                exit('DBN')
            else
                exit('INV');
        end else
            exit('CRN');
    end;

    local procedure SendRequest(Method: Text; URL: Text; OwnerId: Text; GSTNo: Code[15]; RequestTextP: Text; IsCancel: Boolean; ForPDF: Boolean; docNo: text)
    var
        HttpSendMessage: Codeunit "ClearComp Http Send Message";
        TempBlob: Codeunit "Temp Blob";
        ErrorText: Text;
        ResponseText: Text;
        RequestStream: InStream;
        ResponseStream: InStream;
        JObjectResponse: JsonObject;
        SuccessText: Code[1];
        ServerFileName: Text;
        FileManagementL: Codeunit "File Management";
        OutstreamL: OutStream;
        FileName: Text;
        FileL: File;
    begin
        EInvoiceSetup.Get();
        Clear(HttpSendMessage);
        Clear(ResponseText);
        Clear(ErrorText);

        HttpSendMessage.SetHttpHeader('X-ClearTax-AUTH-TOKEN', EInvoiceSetup."Auth Token");
        HttpSendMessage.SetMethod(Method);
        if ForPDF then begin
            // HttpSendMessage.SetReturnType('application/pdf');
            HttpSendMessage.SetContentType('application/pdf');
        end else begin
            HttpSendMessage.SetContentType('application/json');
            HttpSendMessage.SetReturnType('application/json');
        end;
        // if (EInvoiceSetup."Integration Mode" <> EInvoiceSetup."Integration Mode"::ClearTaxDemo) then begin
        HttpSendMessage.SetHttpHeader('gstin', GSTNo);
        if OwnerId <> '' then
            HttpSendMessage.SetHttpHeader('owner_id', OwnerId);
        //   end
        //else begin
        //   HttpSendMessage.SetHttpHeader('gstin', '29AAFCD5862R000');
        //  HttpSendMessage.SetHttpHeader('owner_id', OwnerId);
        //end;
        if not ForPDF then
            HttpSendMessage.SetHttpHeader('x-cleartax-product', 'Einvoice');
        HttpSendMessage.AddUrl(URL);
        if (RequestTextP > '') then begin
            TempBlob.CreateOutStream(OutstreamL);
            OutstreamL.WriteText(RequestTextP);
            TempBlob.CreateInStream(RequestStream);
            HttpSendMessage.AddBody(RequestStream);
        end;

        HttpSendMessage.SendRequest(ResponseStream);
        if (EInvoiceSetup."Show Payload") AND (format(RequestTextP) > '') then
            Message(Format(RequestTextP));
        if HttpSendMessage.IsSuccess() then begin
            if ForPDF then begin
                Clear(TempBlob);
                TempBlob.CreateOutStream(OutstreamL);
                CopyStream(OutstreamL, ResponseStream);
                FileManagementL.BLOBExport(TempBlob, '.pdf', true);
                /*
                                ServerFileName := FileManagementL.ServerTempFileName('.pdf');
                                FileL.Create(ServerFileName);
                                FileL.CreateOutStream(OutStreamL);
                                CopyStream(OutStreamL, ResponseStream);
                                FileL.Close();
                                Hyperlink(FileManagementL.DownloadTempFile(ServerFileName));
                                */
            end else begin
                ResponseStream.ReadText(ResponseText);
                if EInvoiceSetup."Show Payload" then
                    Message(ResponseText);
            end;
        end else begin
            ErrorText := HttpSendMessage.Reason();
        end;
        CreateMessageLog(Method, RequestTextP, Format(HttpSendMessage.StatusCode()), URL + docNo, ResponseText + ErrorText);
        if IsCancel then
            ProcessCancelIRNResponse(RequestTextP, ResponseText, ErrorText)
        else
            if not ForPDF then
                CreateLogEntry(OwnerId, RequestTextP, ResponseText, ErrorText, Format(HttpSendMessage.StatusCode()));
    end;

    local procedure CreateMessageLog(MethodP: Text; MessageTextP: Text; StatusCodeP: Text; UrlP: Text; responseText: text)
    var
        InterfMessageLog: Record "ClearComp Interface Msg Log";
        OutstreamRes: OutStream;
        OutStreamReq: OutStream;
    begin
        InterfMessageLog."Entry No." := GetLastEntryNo();
        InterfMessageLog."Request Type" := MethodP + '-' + UrlP;
        InterfMessageLog.Request.CREATEOUTSTREAM(OutStreamReq);
        OutStreamReq.WRITETEXT(MessageTextP);
        InterfMessageLog."Response Code" := StatusCodeP;
        InterfMessageLog.Response.CREATEOUTSTREAM(OutstreamRes);
        OutstreamRes.WRITETEXT(ResponseText);
        InterfMessageLog.INSERT(TRUE);
        Commit();
    end;

    local procedure GetLastEntryNo(): Integer
    var
        InterfMessageLog: Record "ClearComp Interface Msg Log";
    begin
        if InterfMessageLog.FindLast() then
            exit(InterfMessageLog."Entry No." + 1)
        else
            exit(1);
    end;

    local procedure CreateLogEntry(OwnerIDP: Text; RequestTxtP: Text; ResponseTxtP: Text; ErrorTextP: Text; StatusCodeP: Code[10])
    var
        EInvoiceLog: Record "ClearComp e-Invoice Entry";
        OutstreamL: OutStream;
        InStreamL: InStream;
        JObjectL: JsonObject;
        JToken1L: JsonToken;
        JSubObjectL: JsonObject;
        JArrayL: JsonArray;
        sysarray: JsonArray;
        FileNameL: Text;
        QRCodeL: Text;
        QRCodeInTextL: Text;
        EInvoiceL: Codeunit "e-Invoice Management";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        I: Integer;
        JTokenL: JsonToken;
        QRGenerator: Codeunit "QR Generator";
        RecRef: RecordRef;
        FieldRefL: FieldRef;
        JSubArray: JsonArray;
        ErrorDetails: Text;
    begin
        Clear(ErrorDetails);
        EInvoiceLog.Init();
        if IsInvoice then begin
            EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::Invoice;
            EInvoiceLog."Document No." := SalesInvHeader."No.";
        end else begin
            EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::CrMemo;
            EInvoiceLog."Document No." := SalesCrMemoHdr."No.";
        end;
        if not EInvoiceLog.Insert() then
            EInvoiceLog.Modify();
        EInvoiceLog."Owner ID" := OwnerIDP;
        EInvoiceLog."GST No." := GSTIN;
        EInvoiceLog."Resp. Status Code" := StatusCodeP;
        EInvoiceLog."Request JSON".CreateOutStream(OutstreamL);
        OutstreamL.WriteText(RequestTxtP);
        if ErrorTextP <> '' then
            EInvoiceLog."Status Text" := ErrorTextP;
        EInvoiceLog.Modify();
        Clear(OutstreamL);

        if JArrayL.ReadFrom(ResponseTxtP) then begin
            for I := 0 to JArrayL.Count - 1 do begin
                JArrayL.Get(I, JTokenL);
                JObjectL := JTokenL.AsObject();
                if JObjectL.Contains('govt_response') then begin
                    JObjectL.Get('govt_response', JToken1L);
                    JSubObjectL := JToken1L.AsObject();
                end;
                if JSubObjectL.Contains('ErrorDetails') then begin
                    JSubObjectL.Get('ErrorDetails', JToken1L);
                    JSubArray := JToken1L.AsArray();
                    ErrorDetails := format(JSubArray);
                end;

                if ErrorDetails <> '' then begin
                    EInvoiceLog."Response JSON".CreateOutStream(OutstreamL);
                    OutstreamL.WriteText(ErrorDetails);
                    EInvoiceLog.Modify();

                end;

                if GetValueFromJsonObject(JSubObjectL, 'Success').AsText() = 'Y' then begin
                    EInvoiceLog."Acknowledgment No." := GetValueFromJsonObject(JSubObjectL, 'AckNo').AsText();
                    EInvoiceLog."Acknowledgment Date" := GetDateTimeFromText(GetValueFromJsonObject(JSubObjectL, 'AckDt').AsText());
                    EInvoiceLog.IRN := GetValueFromJsonObject(JSubObjectL, 'Irn').AsText();
                    EInvoiceLog."Signed Invoice".CREATEOUTSTREAM(OutstreamL);
                    OutstreamL.WRITETEXT(GetValueFromJsonObject(JSubObjectL, 'SignedInvoice').AsText());
                    QRCodeL := GetValueFromJsonObject(JSubObjectL, 'SignedQRCode').AsText();

                    EInvoiceLog."Signed QR Code".CREATEOUTSTREAM(OutstreamL);
                    OutstreamL.WRITETEXT(QRCodeL);

                    EInvoiceLog."IRN Status" := GetValueFromJsonObject(JSubObjectL, 'Status').AsText();
                    EInvoiceLog.Status := EInvoiceLog.Status::Generated;
                    EInvoiceLog.Modify();
                    QRGenerator.GenerateQRCodeImage(QRCodeL, TempBlob);

                    if EInvoiceLog."Document Type" = EInvoiceLog."Document Type"::Invoice then begin
                        SalesInvHeader.Get(EInvoiceLog."Document No.");
                        RecRef.GetTable(SalesInvHeader);
                        FieldRefL := RecRef.Field(SalesInvHeader.FieldNo("irn hash"));
                        fieldrefL.Value := EInvoiceLog.IRN;
                        FieldRefL := RecRef.Field(SalesInvHeader.FieldNo("Acknowledgement No."));
                        fieldrefL.Value := EInvoiceLog."Acknowledgment No.";
                        FieldRefL := RecRef.Field(SalesInvHeader.FieldNo("Acknowledgement date"));
                        fieldrefL.Value := EInvoiceLog."Acknowledgment Date";

                        TempBlob.ToRecordRef(RecRef, SalesInvHeader.FieldNo("QR Code"));
                        RecRef.Modify();
                        Commit();
                    end else
                        if EInvoiceLog."Document Type" = EInvoiceLog."Document Type"::CrMemo then begin
                            SalesCrMemoHdr.GET(EInvoiceLog."Document No.");
                            RecRef.GetTable(SalesCrMemoHdr);
                            FieldRefL := RecRef.Field(SalesCrMemoHdr.FieldNo("irn hash"));
                            fieldrefL.Value := EInvoiceLog.IRN;
                            FieldRefL := RecRef.Field(SalesCrMemoHdr.FieldNo("Acknowledgement No."));
                            fieldrefL.Value := EInvoiceLog."Acknowledgment No.";
                            FieldRefL := RecRef.Field(SalesCrMemoHdr.FieldNo("Acknowledgement date"));
                            fieldrefL.Value := EInvoiceLog."Acknowledgment Date";

                            TempBlob.ToRecordRef(RecRef, SalesCrMemoHdr.FieldNo("QR Code"));
                            RecRef.Modify();
                            Commit();
                        end;
                end else begin
                    EInvoiceLog.Status := EInvoiceLog.Status::Fail;
                    //if ErrorTextP > '' then
                    //   Message(ErrorTextP);
                end;
            end;
        end else begin
            EInvoiceLog.Status := EInvoiceLog.Status::Fail;
            //  if ErrorTextP > '' then
            //    Message(ErrorTextP);
        end;

        if ErrorDetails = '' then begin
            Clear(OutstreamL);
            EInvoiceLog."Response JSON".CreateOutStream(OutstreamL);
            OutstreamL.WriteText(ResponseTxtP);
        end;

        EInvoiceLog."Created By" := UserId();
        EInvoiceLog."Created Date Time" := CurrentDateTime();
        EInvoiceLog.Modify();
    end;

    local procedure GetDateTimeFromText(DateTimeValue: Text[30]): DateTime
    var
        YYYYText: Text[4];
        MMText: Text[2];
        DDText: Text[2];
        YYYY: Integer;
        MM: Integer;
        DD: Integer;
        TimeText: Text[15];
        TimeValue: Time;
    begin
        if DateTimeValue = '' then
            exit(0DT);

        YYYYText := CopyStr(DateTimeValue, 1, 4);
        MMText := CopyStr(DateTimeValue, 6, 2);
        DDText := CopyStr(DateTimeValue, 9, 2);
        if STRLEN(DateTimeValue) > 10 then
            TimeText := CopyStr(DateTimeValue, 12, 8);

        if NOT EVALUATE(YYYY, YYYYText) then
            exit(0DT);

        if NOT EVALUATE(MM, MMText) then
            exit(0DT);

        if NOT EVALUATE(DD, DDText) then
            exit(0DT);

        if NOT EVALUATE(TimeValue, TimeText) then
            TimeValue := 0T;

        exit(CREATEDATETIME(DMY2DATE(DD, MM, YYYY), TimeValue));
    end;

    local procedure GetValueFromJsonObject(JObjectP: JsonObject; PropertyNameP: Text) JValueR: JsonValue
    var
        JTokenL: JsonToken;
    begin
        JObjectP.Get(PropertyNameP, JTokenL);
        JValueR := JTokenL.AsValue();
        if not JValueR.IsNull then
            exit(JValueR)
        else
            JValueR.SetValue('');
    end;
}

