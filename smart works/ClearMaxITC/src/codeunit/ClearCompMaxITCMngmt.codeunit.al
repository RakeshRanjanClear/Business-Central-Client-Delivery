codeunit 60117 "ClearComp MaxITC Management"
{
    trigger OnRun()
    var
        PreviewList: Page "ClearComp MaxITC Trans. List";
    begin
        MaxITCSetup.GET;
        PurchInvHdr.SETRANGE("Posting Date", FromDate, ToDate);
        IF PurchInvHdr.FINDSET THEN
            REPEAT
                if not TransHeader.Get(TransHeader."Document Type"::Invoice, PurchInvHdr."No.") then begin
                    ReadHeaderDetailsPurchaseInvoice;
                    ReadLineDetailsPurchaseInvoice;
                    ReadSupplierDetailsPurchaseInvoice;
                    IF NOT TransHeader."Is Bill of Supply" THEN
                        ReadImportDetailsPurchaseInvoice;
                end;
            UNTIL PurchInvHdr.NEXT = 0;

        PurchCrMemoHdr.SETRANGE("Posting Date", FromDate, ToDate);
        IF PurchCrMemoHdr.FINDSET THEN
            REPEAT
                if not TransHeader.Get(TransHeader."Document Type"::"Credit Memo", PurchCrMemoHdr."No.") then begin
                    ReadHeaderDetailsPurchaseCreditMemo;
                    ReadLineDetailsPurchaseCreditMemo;
                    ReadSupplierDetailsPurchaseCreditMemo;
                end;
            UNTIL PurchCrMemoHdr.NEXT = 0;
        /*
        BankAccountLedgerEntry.SETRANGE("Posting Date",FromDate,ToDate);
        BankAccountLedgerEntry.SETRANGE("Bal. Account Type",BankAccountLedgerEntry."Bal. Account Type"::Vendor);
        // filter to be added to specify if it's advance.
        IF BankAccountLedgerEntry.FINDSET THEN REPEAT
          IF NOT TransHeader.GET(TransHeader."Document Type"::Advance,BankAccountLedgerEntry."Document No.") THEN BEGIN
            ReadHeaderDetailsAdvance;
            ReadLineDetailsAdvance;
            ReadSupplierDetailsAdvance;
          END;
        UNTIL BankAccountLedgerEntry.NEXT = 0;
        */
        //TransHeader.SETRANGE(Selected,TRUE);
        TransHeader.SETRANGE("Posting date", FromDate, ToDate);
        TransHeader.SETRANGE(WorkFlowID, '');
        IF TransHeader.FINDSET THEN BEGIN
            TransHeader.MODIFYALL(Selected, TRUE);
            COMMIT;
            PreviewList.SetActionVisibility;
            PreviewList.SETTABLEVIEW(TransHeader);
            PreviewList.LOOKUPMODE(TRUE);
            PreviewList.RUNMODAL;
        END;

    end;

    var
        TempBlob: Codeunit "Temp Blob";
        TransHeader: Record "ClearComp MaxITC Trans. Header";
        PurchInvHdr: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        XLTxt1: Label '*Invoice details(Linked Invoice Number and date in case of Credit/Debit Notes)';
        XLTxt2: Label '*Provide these details for HSN summary under GST Return flow';
        XLTxt3: Label '*Tax details (Invoice should have either CGST & SGST or IGST value based of Place of Supply)';
        XLTxt4: Label 'Required for Rule 42, 43 ITC Reversals';
        XLTxt5: Label '*Mandatory incase of claim ITC under GSTR-2 flow      Please mark ''ITC Claim'' as ''None'' in case you do not want to claim ITC on the invoice. If you leave the filed blank, it will be automatically considered it as ''Input''.';
        XLTxt6: Label '*Credit/Debit Note details';
        XLTxt7: Label '*Mandatory incase of Import of Goods';
        XLTxt8: Label 'Mandatory, in case this invoice is filed as a part of previous return period.';
        XLTxt9: Label '*This is destination of the product, typically your state.';
        XLTxt10: Label '*Mandatory incase of Amendment of Invoice';
        XLTxt11: Label '*Mandatory if advance receipts are adjusted against invoices raised.';
        XLTxt12: Label 'For tracking vendor payments.';
        XLTxt13: Label '*Enter total invoice value here. If you have more than one line in the invoice, repeat the same value for every line.';
        XLTxt14: Label 'Optional Custom fields';
        XLTxt15: Label 'for Income tax only';
        MaxITCSetup: Record "ClearComp MaxITC Setup";
        ResponseText: BigText;
        ErrorText: Text;
        ServerFileName: Text;
        FromDate: Date;
        ToDate: Date;
        XLNotFound: Label 'Excel not created.';
        InStreamG: InStream;

    //+++++++++++++++++++++++++++++++++++++++++++++Purchase invoice functions +++++++++++++++++++++++++++++++++//

    local procedure ReadHeaderDetailsPurchaseInvoice()
    var
        RecRef: RecordRef;
        CompanyInformation: Record "Company Information";
    begin
        CLEAR(TransHeader);
        RecRef.GETTABLE(PurchInvHdr);
        CompanyInformation.GET;
        TransHeader."Document Type" := TransHeader."Document Type"::Invoice;
        TransHeader."Document No." := PurchInvHdr."No.";
        TransHeader."Posting date" := PurchInvHdr."Posting Date";
        TransHeader."Place of supply" := GetPlaceofSupply(RecRef);
        TransHeader."RCM applicable" := GetReverseChargeApplicable();
        TransHeader."My GSTIN" := CompanyInformation."GST Registration No.";
        IF PurchInvHdr."Prepayment Order No." <> '' THEN BEGIN
            TransHeader."Is Advance" := TRUE;
            TransHeader."Advance payment amount" := PurchInvHdr.Amount;
            TransHeader."Advance payment date" := PurchInvHdr."Posting Date";
            TransHeader."Advance payment no." := PurchInvHdr."No.";
        END;
        IF PurchInvHdr."Invoice Type" IN [PurchInvHdr."Invoice Type"::"Non-GST"] THEN
            TransHeader."Is Bill of Supply" := TRUE;
        TransHeader.Selected := TRUE;
        if not TransHeader.INSERT then
            TransHeader.Modify();
    end;

    local procedure ReadLineDetailsPurchaseInvoice()
    var
        PurchInvLineL: Record "Purch. Inv. Line";
        TransLineL: Record "ClearComp MaxITC Trans. Line";
        CurrencyExchangeRateL: Record "Currency Exchange Rate";
        HSNSACL: Record "HSN/SAC";
    begin
        PurchInvLineL.SETRANGE("Document No.", PurchInvHdr."No.");
        PurchInvLineL.SETFILTER("No.", '<>%1', '');
        PurchInvLineL.SETFILTER(Quantity, '<>%1', 0);
        IF PurchInvLineL.FINDSET THEN
            REPEAT
                Clear(TransLineL);
                TransLineL."Document Type" := TransHeader."Document Type";
                TransLineL."Document No." := TransHeader."Document No.";
                TransLineL."Line No." := PurchInvLineL."Line No."; //This line no. is used for filtering in function GetGSTCompRate
                TransLineL.Description := PurchInvLineL.Description;
                IF PurchInvLineL."Description 2" <> '' THEN
                    TransLineL.Description += ' ' + PurchInvLineL."Description 2";
                TransLineL.Quantity := PurchInvLineL.Quantity;

                TransLineL."Unit Price" := PurchInvLineL."Unit Price (LCY)";
                TransLineL.UOM := COPYSTR(PurchInvLineL."Unit of Measure Code", 1, 3);

                TransLineL."Taxable Value" := ROUND(CurrencyExchangeRateL.ExchangeAmtFCYToLCY(WORKDATE, PurchInvHdr."Currency Code",
                                                     PurchInvLineL.Amount, PurchInvHdr."Currency Factor"), 0.01, '=');

                IF NOT TransHeader."Is Bill of Supply" THEN // Need to add code for this condition
                    GetGSTCompRate(TransLineL);

                TransLineL."HSN/SAC code" := PurchInvLineL."HSN/SAC Code";
                IF HSNSACL.GET(PurchInvLineL."GST Group Code", PurchInvLineL."HSN/SAC Code") THEN BEGIN
                    IF HSNSACL.Type = HSNSACL.Type::HSN THEN
                        TransLineL."Item Type" := TransLineL."Item Type"::G
                    ELSE
                        TransLineL."Item Type" := TransLineL."Item Type"::S;
                END;

                TransLineL.Discount := ROUND(CurrencyExchangeRateL.ExchangeAmtFCYToLCY(WORKDATE, PurchInvHdr."Currency Code",
                                              PurchInvLineL."Line Discount Amount", PurchInvHdr."Currency Factor"), 0.01, '=');

                TransLineL."Line No." := TransLineL.GetNextFreeLine(TransLineL."Document Type", TransLineL."Document No.");
                TransLineL.INSERT;
            UNTIL PurchInvLineL.NEXT = 0;
    end;

    local procedure ReadSupplierDetailsPurchaseInvoice()
    var
        OrderAddressL: Record "Order Address";
        VendorL: Record Vendor;
        StateL: Record State;
        LocationL: Record Location;
    begin

        IF (PurchInvHdr."Order Address Code" <> '') AND
           (OrderAddressL.GET(PurchInvHdr."Buy-from Vendor No.", PurchInvHdr."Order Address Code")) THEN BEGIN
            TransHeader."Supplier Name" := OrderAddressL.Name;
            IF OrderAddressL."Name 2" <> '' THEN
                TransHeader."Supplier Name" += ' ' + OrderAddressL."Name 2";
            TransHeader."Supplier GSTIN" := OrderAddressL."GST Registration No.";
            TransHeader."Supplier Address" := OrderAddressL.Address;
            IF OrderAddressL."Address 2" <> '' THEN
                TransHeader."Supplier Address" += ' ' + OrderAddressL."Address 2";
            TransHeader."Supplier City" := OrderAddressL.City;
            IF StateL.GET(OrderAddressL.State) THEN
                TransHeader."Supplier State" := StateL."State Code (GST Reg. No.)";
            TransHeader."Supplier Zip Code" := OrderAddressL."Post Code";
            TransHeader."Supplier Phone No." := OrderAddressL."Phone No.";
        END ELSE BEGIN
            IF VendorL.GET(PurchInvHdr."Buy-from Vendor No.") THEN;
            TransHeader."Supplier Name" := PurchInvHdr."Buy-from Vendor Name";
            IF PurchInvHdr."Buy-from Vendor Name 2" <> '' THEN
                TransHeader."Supplier Name" += ' ' + PurchInvHdr."Buy-from Vendor Name 2";
            TransHeader."Supplier GSTIN" := VendorL."GST Registration No.";
            TransHeader."Supplier Address" := PurchInvHdr."Buy-from Address";
            IF PurchInvHdr."Buy-from Address 2" <> '' THEN
                TransHeader."Supplier Address" += ' ' + PurchInvHdr."Buy-from Address 2";
            TransHeader."Supplier City" := PurchInvHdr."Pay-to City";
            TransHeader."Supplier Zip Code" := PurchInvHdr."Buy-from Post Code";
            IF StateL.GET(PurchInvHdr."GST Order Address State") THEN
                TransHeader."Supplier State" := StateL."State Code (GST Reg. No.)"
            ELSE
                IF StateL.GET(VendorL."State Code") THEN
                    TransHeader."Supplier State" := StateL."State Code (GST Reg. No.)";
            TransHeader."Supplier Phone No." := VendorL."Phone No.";
        END;
        TransHeader.MODIFY;
    end;

    local procedure ReadImportDetailsPurchaseInvoice()
    var
        TransLineL: Record "ClearComp MaxITC Trans. Line";
    begin

        TransHeader."Bill of Entry No." := PurchInvHdr."Bill of Entry No.";
        TransHeader."Bill of Entry Date" := PurchInvHdr."Bill of Entry Date";
        TransLineL.SETRANGE("Document Type", TransHeader."Document Type");
        TransLineL.SETRANGE("Document No.", TransHeader."Document No.");
        if TransLineL.FINDLAST then begin
            IF PurchInvHdr."GST Vendor Type" = PurchInvHdr."GST Vendor Type"::Import THEN
                IF TransLineL."Item Type" = TransLineL."Item Type"::G THEN
                    TransHeader."Type of Import" := TransHeader."Type of Import"::Goods
                ELSE
                    TransHeader."Type of Import" := TransHeader."Type of Import"::Services
            ELSE
                IF PurchInvHdr."GST Vendor Type" = PurchInvHdr."GST Vendor Type"::SEZ THEN
                    TransHeader."Type of Import" := TransHeader."Type of Import"::SEZ;
            TransHeader."Bill of Entry Port Code" := PurchInvHdr."Entry Point";
        end;
        TransHeader.MODIFY;
    end;

    //+++++++++++++++++++++++++++++purchase credit memo functions++++++++++++++++++++++++++++++++//

    local procedure ReadHeaderDetailsPurchaseCreditMemo()
    var
        CompanyInformation: Record "Company Information";
        PurchInvHeaderL: Record "Purch. Inv. Header";
        VendorL: Record Vendor;
        RecRef: RecordRef;
    begin
        RecRef.GETTABLE(PurchCrMemoHdr);
        CLEAR(TransHeader);
        CompanyInformation.GET;
        TransHeader."Credit/Debit Note Type" := TransHeader."Credit/Debit Note Type"::DEBIT;
        TransHeader."Document Type" := TransHeader."Document Type"::"Credit Memo";
        TransHeader."Credit/Debit Note No." := PurchCrMemoHdr."No.";
        TransHeader."Place of supply" := GetPlaceofSupply(RecRef);
        TransHeader."RCM applicable" := GetReverseChargeApplicable();
        TransHeader."Credit/Debit Note date" := PurchCrMemoHdr."Posting Date";
        TransHeader."Reason for Issuing CDN" := PurchCrMemoHdr."Reason Code";
        TransHeader."My GSTIN" := CompanyInformation."GST Registration No.";
        IF PurchInvHeaderL.GET(PurchCrMemoHdr."Reference Invoice No.") THEN BEGIN
            TransHeader."Document No." := PurchInvHeaderL."No.";
            TransHeader."Posting date" := PurchInvHeaderL."Posting Date";
        END;
        if TransHeader."Posting date" = 0D then
            TransHeader."Posting date" := PurchCrMemoHdr."Posting Date";
        IF PurchCrMemoHdr."Prepayment Order No." <> '' THEN BEGIN
            TransHeader."Advance payment no." := PurchCrMemoHdr."Prepayment Order No.";
            TransHeader."Advance payment amount" := PurchCrMemoHdr.Amount;
            TransHeader."Advance payment date" := PurchCrMemoHdr."Posting Date";
        END;
        IF PurchCrMemoHdr."Invoice Type" IN [PurchCrMemoHdr."Invoice Type"::"Non-GST"] THEN
            TransHeader."Is Bill of Supply" := TRUE;
        TransHeader.Selected := TRUE;
        if not TransHeader.INSERT then
            TransHeader.Modify();
    end;

    local procedure ReadLineDetailsPurchaseCreditMemo()
    var
        PurchCrMemoLineL: Record "Purch. Cr. Memo Line";
        TransLineL: Record "ClearComp MaxITC Trans. Line";
        CurrencyExchangeRateL: Record "Currency Exchange Rate";
        HSNSACL: Record "HSN/SAC";
    begin
        PurchCrMemoLineL.SETRANGE("Document No.", PurchCrMemoHdr."No.");
        PurchCrMemoLineL.SETFILTER(Type, '<>%1', PurchCrMemoLineL.Type::" ");
        IF PurchCrMemoLineL.FINDSET THEN
            REPEAT
                Clear(TransLineL);
                TransLineL."Document Type" := TransHeader."Document Type";
                TransLineL."Document No." := TransHeader."Document No.";
                TransLineL."Line No." := PurchCrMemoLineL."Line No.";
                TransLineL.Description := PurchCrMemoLineL.Description;
                IF PurchCrMemoLineL."Description 2" <> '' THEN
                    TransLineL.Description += ' ' + PurchCrMemoLineL."Description 2";
                TransLineL.Quantity := PurchCrMemoLineL.Quantity;
                TransLineL."Unit Price" := ROUND(CurrencyExchangeRateL.ExchangeAmtFCYToLCY(WORKDATE, PurchCrMemoHdr."Currency Code",
                                                  PurchCrMemoLineL."Unit Price (LCY)", PurchCrMemoHdr."Currency Factor"), 0.01, '=');

                TransLineL.UOM := COPYSTR(PurchCrMemoLineL."Unit of Measure Code", 1, 3);

                TransLineL."Taxable Value" := ROUND(CurrencyExchangeRateL.ExchangeAmtFCYToLCY(WORKDATE, PurchCrMemoHdr."Currency Code",
                                                     PurchCrMemoLineL.Amount, PurchCrMemoHdr."Currency Factor"), 0.01, '=');
                GetGSTCompRate(TransLineL);

                TransLineL."HSN/SAC code" := PurchCrMemoLineL."HSN/SAC Code";
                IF HSNSACL.GET(PurchCrMemoLineL."GST Group Code", PurchCrMemoLineL."HSN/SAC Code") THEN BEGIN
                    IF HSNSACL.Type = HSNSACL.Type::HSN THEN
                        TransLineL."Item Type" := TransLineL."Item Type"::G
                    ELSE
                        TransLineL."Item Type" := TransLineL."Item Type"::S;
                END;

                TransLineL.Discount := ROUND(CurrencyExchangeRateL.ExchangeAmtFCYToLCY(WORKDATE, PurchCrMemoHdr."Currency Code",
                                              PurchCrMemoLineL."Line Discount Amount", PurchCrMemoHdr."Currency Factor"), 0.01, '=');

                TransLineL."Line No." := TransLineL.GetNextFreeLine(TransLineL."Document Type", TransLineL."Document No.");
                TransLineL.INSERT;
            UNTIL PurchCrMemoLineL.NEXT = 0;
    end;

    local procedure ReadSupplierDetailsPurchaseCreditMemo()
    var
        OrderAddressL: Record "Order Address";
        StateL: Record State;
        VendorL: Record Vendor;
    begin

        IF (PurchCrMemoHdr."Order Address Code" <> '') AND
           (OrderAddressL.GET(PurchCrMemoHdr."Buy-from Vendor No.", PurchCrMemoHdr."Order Address Code")) THEN BEGIN
            TransHeader."Supplier Name" := OrderAddressL.Name;
            IF OrderAddressL."Name 2" <> '' THEN
                TransHeader."Supplier Name" := OrderAddressL."Name 2";
            TransHeader."Supplier GSTIN" := OrderAddressL."GST Registration No.";
            TransHeader."Supplier Address" := OrderAddressL.Address;
            IF OrderAddressL."Address 2" <> '' THEN
                TransHeader."Supplier Address" += OrderAddressL."Address 2";
            TransHeader."Supplier City" := OrderAddressL.City;
            IF StateL.GET(OrderAddressL.State) THEN
                TransHeader."Supplier State" := StateL."State Code (GST Reg. No.)";
            TransHeader."Supplier Zip Code" := OrderAddressL."Post Code";
            TransHeader."Supplier Phone No." := OrderAddressL."Phone No.";
        END ELSE BEGIN
            IF VendorL.GET(PurchCrMemoHdr."Buy-from Vendor No.") THEN;
            TransHeader."Supplier Name" := PurchCrMemoHdr."Buy-from Vendor Name";
            IF PurchCrMemoHdr."Buy-from Vendor Name 2" <> '' THEN
                TransHeader."Supplier Name" += ' ' + PurchCrMemoHdr."Buy-from Vendor Name 2";
            TransHeader."Supplier GSTIN" := VendorL."GST Registration No.";
            TransHeader."Supplier Address" := PurchCrMemoHdr."Buy-from Address";
            IF PurchCrMemoHdr."Buy-from Address 2" <> '' THEN
                TransHeader."Supplier Address" += ' ' + PurchCrMemoHdr."Buy-from Address 2";
            TransHeader."Supplier City" := PurchCrMemoHdr."Buy-from City";
            TransHeader."Supplier Zip Code" := PurchCrMemoHdr."Buy-from Post Code";
            IF StateL.GET(PurchCrMemoHdr."GST Order Address State") THEN
                TransHeader."Supplier State" := StateL."State Code (GST Reg. No.)"
            ELSE
                IF StateL.GET(VendorL."State Code") THEN
                    TransHeader."Supplier State" := StateL."State Code (GST Reg. No.)";
            TransHeader."Supplier Phone No." := VendorL."Phone No.";
        END;
        TransHeader.MODIFY;
        //Country not added.
    end;

    //+++++++++++++++++++++++++++++++++++Advance functions +++++++++++++++++++++++++++++++++++//

    local procedure ReadHeaderDetailsAdvance()
    var
        RecRef: RecordRef;
    begin
        RecRef.GETTABLE(BankAccountLedgerEntry);
        CLEAR(TransHeader);
        TransHeader."Is Advance" := TRUE;
        TransHeader."Document No." := BankAccountLedgerEntry."Bank Account No.";
        TransHeader."Posting date" := BankAccountLedgerEntry."Document Date";
        TransHeader."RCM applicable" := GetReverseChargeApplicable();
        TransHeader."Place of supply" := GetPlaceofSupply(RecRef);
        TransHeader."Advance payment amount" := BankAccountLedgerEntry.Amount;
        TransHeader."Advance payment date" := BankAccountLedgerEntry."Posting Date";
        TransHeader."Advance payment no." := BankAccountLedgerEntry."Document No.";
        TransHeader.INSERT;
    end;

    local procedure ReadLineDetailsAdvance()
    var
        TransLineL: Record "ClearComp MaxITC Trans. Line";
    begin
        TransLineL."Document Type" := TransHeader."Document Type";
        TransLineL."Document No." := TransHeader."Document No.";
        TransLineL."Line No." := TransLineL.GetNextFreeLine(TransLineL."Document Type", TransLineL."Document No.");
        TransLineL.Description := BankAccountLedgerEntry.Description;
        TransLineL.Quantity := 1;
        TransLineL.UOM := 'OTH';
        GetGSTCompRate(TransLineL);
        TransLineL."Unit Price" := TransLineL."Taxable Value";
        TransLineL.INSERT;
    end;

    local procedure ReadSupplierDetailsAdvance()
    var
        LocationL: Record Location;
        StateL: Record State;
        VendorL: Record Vendor;
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        IF BankAccountLedgerEntry."Bal. Account Type" = BankAccountLedgerEntry."Bal. Account Type"::Vendor THEN BEGIN
            DetailedGSTLedgerEntry.SetRange("Document No.", Format(BankAccountLedgerEntry."Entry No."));
            DetailedGSTLedgerEntry.SetFilter("GST Component Code", '%1|%2|%3', 'CGST', 'SGST', 'IGST');
            if DetailedGSTLedgerEntry.FindFirst() then
                if LocationL.Get(DetailedGSTLedgerEntry."Location Code") then;
            IF StateL.GET(LocationL."State Code") THEN;
            IF VendorL.GET(BankAccountLedgerEntry."Bal. Account No.") THEN BEGIN
                TransHeader."Supplier Name" := VendorL.Name;
                IF VendorL."Name 2" <> '' THEN
                    TransHeader."Supplier Name" += ' ' + VendorL."Name 2";
                TransHeader."Supplier Address" := VendorL.Address;
                IF VendorL."Address 2" <> '' THEN
                    TransHeader."Supplier Address" += ' ' + VendorL."Address 2";
                TransHeader."Supplier City" := VendorL.City;
                TransHeader."Supplier Phone No." := VendorL."Phone No.";
                IF (VendorL."State Code" = 'FOR') OR (LocationL."State Code" = 'SEZ-GJ') THEN BEGIN
                    TransHeader."Supplier GSTIN" := 'URP';
                    TransHeader."Supplier Zip Code" := '999999';
                    TransHeader."Supplier State" := 'OTHERTERRITORY';
                END ELSE BEGIN
                    IF VendorL."GST Vendor Type" = VendorL."GST Vendor Type"::Unregistered THEN
                        TransHeader."Supplier GSTIN" := 'URP'
                    ELSE
                        TransHeader."Supplier GSTIN" := VendorL."GST Registration No.";
                    IF StateL.GET(VendorL."State Code") THEN
                        TransHeader."Supplier State" := StateL.Description;
                    TransHeader."Supplier Zip Code" := VendorL."Post Code";
                END;
            END;
        END;
        TransHeader.MODIFY;
    end;

    //+++++++++++++++++++++++++++ General functions+++++++++++++++++++++++++++++++++++++++++++++//

    local procedure GetGSTCompRate(var TransLineP: Record "ClearComp MaxITC Trans. Line")
    var
        DetailedGSTLedgerEntryL: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntryL.SetRange("Entry Type", DetailedGSTLedgerEntryL."Entry Type"::"Initial Entry");
        if TransLineP."Document Type" = TransLineP."Document Type"::Invoice then
            DetailedGSTLedgerEntryL.SetRange("Document Type", DetailedGSTLedgerEntryL."Document Type"::Invoice)
        else
            if TransLineP."Document Type" in [TransLineP."Document Type"::"Credit Memo"] then
                DetailedGSTLedgerEntryL.SetRange("Document Type", DetailedGSTLedgerEntryL."Document Type"::"Credit Memo");
        DetailedGSTLedgerEntryL.SETRANGE("Document No.", TransHeader."Document No.");
        IF NOT TransHeader."Is Advance" THEN
            DetailedGSTLedgerEntryL.SETRANGE("Document Line No.", TransLineP."Line No.");

        DetailedGSTLedgerEntryL.SETRANGE("GST Component Code", 'CGST');
        IF DetailedGSTLedgerEntryL.FindSet() then begin
            UpadateITCClaim(TransLineP, DetailedGSTLedgerEntryL);
            TransLineP."CGST Rate" := DetailedGSTLedgerEntryL."GST %";
            repeat
                TransLineP."CGST Value" += ABS(DetailedGSTLedgerEntryL."GST Amount");
                IF TransHeader."Is Advance" THEN
                    TransLineP."Taxable Value" += ABS(DetailedGSTLedgerEntryL."GST Base Amount");
            until DetailedGSTLedgerEntryL.Next() = 0;
            if not (TransLineP."ITC claim type" in [TransLineP."ITC claim type"::" ", translineP."ITC Claim Type"::Blank, TransLineP."ITC claim type"::INELIGIBLE]) then
                TransLineP."CGST ITC Claim amt." := TransLineP."CGST Value";
        END;

        DetailedGSTLedgerEntryL.SETRANGE("GST Component Code", 'SGST');
        IF DetailedGSTLedgerEntryL.FindSet() then begin
            UpadateITCClaim(TransLineP, DetailedGSTLedgerEntryL);
            TransLineP."SGST Rate" := DetailedGSTLedgerEntryL."GST %";
            repeat
                TransLineP."SGST Value" += ABS(DetailedGSTLedgerEntryL."GST Amount");
            until DetailedGSTLedgerEntryL.Next() = 0;
            if not (TransLineP."ITC claim type" in [TransLineP."ITC claim type"::" ", translineP."ITC Claim Type"::Blank, TransLineP."ITC claim type"::INELIGIBLE]) then
                TransLineP."SGST ITC claim amt." := TransLineP."SGST Value";
        END;

        DetailedGSTLedgerEntryL.SETRANGE("GST Component Code", 'IGST');
        IF DetailedGSTLedgerEntryL.FindSet() then begin
            UpadateITCClaim(TransLineP, DetailedGSTLedgerEntryL);
            TransLineP."IGST Rate" := DetailedGSTLedgerEntryL."GST %";
            repeat
                TransLineP."IGST Value" += ABS(DetailedGSTLedgerEntryL."GST Amount");
                IF TransHeader."Is Advance" THEN
                    TransLineP."Taxable Value" += ABS(DetailedGSTLedgerEntryL."GST Base Amount");
            until DetailedGSTLedgerEntryL.Next() = 0;
            if not (TransLineP."ITC claim type" in [TransLineP."ITC claim type"::" ", translineP."ITC Claim Type"::Blank, TransLineP."ITC claim type"::INELIGIBLE]) then
                TransLineP."IGST ITC claim amt." := TransLineP."IGST Value";
        END;

        DetailedGSTLedgerEntryL.SETRANGE("GST Component Code", 'CESS');
        IF DetailedGSTLedgerEntryL.FindSet() then begin
            UpadateITCClaim(TransLineP, DetailedGSTLedgerEntryL);
            repeat
                IF DetailedGSTLedgerEntryL."GST %" > 0 THEN BEGIN
                    TransLineP."CESS Rate" := DetailedGSTLedgerEntryL."GST %";
                    TransLineP."CESS Value" += ABS(DetailedGSTLedgerEntryL."GST Amount");
                END;
            until DetailedGSTLedgerEntryL.Next() = 0;
            if not (TransLineP."ITC claim type" in [TransLineP."ITC claim type"::" ", translineP."ITC Claim Type"::Blank, TransLineP."ITC claim type"::INELIGIBLE]) then
                TransLineP."CESS ITC claim amt." := TransLineP."CESS Value";
        end;
    end;

    local procedure UpadateITCClaim(var TransLine: Record "ClearComp MaxITC Trans. Line"; DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry")
    begin
        case DetailedGSTLedgerEntry."Eligibility for ITC" of
            DetailedGSTLedgerEntry."Eligibility for ITC"::Inputs:
                TransLine."ITC claim type" := TransLine."ITC claim type"::INPUT;
            DetailedGSTLedgerEntry."Eligibility for ITC"::"Input Services":
                TransLine."ITC claim type" := TransLine."ITC claim type"::"Input Service";
            DetailedGSTLedgerEntry."Eligibility for ITC"::"Capital goods":
                TransLine."ITC claim type" := TransLine."ITC claim type"::"Capital Good";
            DetailedGSTLedgerEntry."Eligibility for ITC"::Ineligible:
                TransLine."ITC claim type" := TransLine."ITC claim type"::INELIGIBLE;
        end;
    end;

    local procedure GetPlaceofSupply(RecRef: RecordRef): Text
    var
        PurchInvHdrL: Record "Purch. Inv. Header";
        PurchCrMemoHeaderL: Record "Purch. Cr. Memo Hdr.";
        BankAccountLedgerEntryL: Record "Bank Account Ledger Entry";
        DetailedGSTLedgerEntryL: Record "Detailed GST Ledger Entry";
        StateL: Record State;
        LocationL: Record Location;
    begin
        CASE RecRef.NUMBER OF
            DATABASE::"Purch. Inv. Header":
                BEGIN
                    RecRef.SETTABLE(PurchInvHdrL);
                    IF LocationL.GET(PurchInvHdrL."Location Code") THEN
                        IF StateL.GET(LocationL."State Code") THEN
                            IF StateL."State Code (GST Reg. No.)" <> '' THEN
                                EXIT(StateL."State Code (GST Reg. No.)")
                END;
            DATABASE::"Purch. Cr. Memo Hdr.":
                BEGIN
                    RecRef.SETTABLE(PurchCrMemoHeaderL);
                    IF LocationL.GET(PurchCrMemoHeaderL."Location Code") THEN
                        IF StateL.GET(LocationL."State Code") THEN
                            EXIT(StateL."State Code (GST Reg. No.)");
                END;
            DATABASE::"Bank Account Ledger Entry":
                BEGIN
                    RecRef.SetTable(BankAccountLedgerEntry);
                    if BankAccountLedgerEntry."Bal. Account Type" in [BankAccountLedgerEntry."Bal. Account Type"::Customer, BankAccountLedgerEntry."Bal. Account Type"::Vendor] then begin
                        DetailedGSTLedgerEntryL.SetRange("Document No.", Format(BankAccountLedgerEntry."Entry No."));
                        DetailedGSTLedgerEntryL.SetFilter("GST Component Code", '%1|%2|%3', 'CGST', 'SGST', 'IGST');
                        if DetailedGSTLedgerEntryL.FindFirst() then
                            if LocationL.Get(DetailedGSTLedgerEntryL."Location Code") then
                                if StateL.Get(LocationL."State Code") and (StateL."State Code (GST Reg. No.)" > '') then
                                    exit(StateL."State Code (GST Reg. No.)");
                    END;
                END;
        END;
        EXIT('');
    end;

    local procedure GetReverseChargeApplicable(): Boolean
    var
        DetailedGSTLedgerEntryL: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntryL.SETRANGE("Document No.", TransHeader."Document No.");
        DetailedGSTLedgerEntryL.SETFILTER("GST Component Code", '%1|%2|%3', 'CGST', 'SGST', 'IGST');
        DetailedGSTLedgerEntryL.SetRange("Reverse Charge", true);
        IF DetailedGSTLedgerEntryL.FINDFIRST THEN
            EXIT(TRUE);
    end;

    local procedure CreateExcelBuffer(var ExcelBuffer: Record "Excel Buffer"; RowNo: Integer; RowLabel: Text; ColumnNo: Integer; ColumnLabel: Text; CellValue: Text)
    begin
        ExcelBuffer.INIT;
        ExcelBuffer."Row No." := RowNo;
        ExcelBuffer.xlRowID := RowLabel;
        ExcelBuffer."Column No." := ColumnNo;
        ExcelBuffer.xlColID := ColumnLabel;
        ExcelBuffer."Cell Value as Text" := CellValue;
        ExcelBuffer.INSERT
    end;

    local procedure ReadDataToExcelPurchaseorBillofSupply()
    var
        TransLineL: Record "ClearComp MaxITC Trans. Line";
        ExcelBuffer: Record "Excel Buffer" temporary;
        "Count": Integer;
        outstreamL: OutStream;
        ColumnLabel: Option A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,AA,AB,AC,AD,AE,AF,AG,AH,AI,AJ,AK,AL,AM,AN,AO,AP,AQ,AR,AS
                             ,AT,AU,AV,AW,AX,AY,AZ,BA,BB,BC,BD,BE,BF,BG,BH,BI,BJ,BK,BL,BM,BN,BO,BP;

        HeaderFields: Option "Invoice Date *","Invoice Number *","Supplier Name","Supplier GSTIN","Supplier State","Is the item a GOOD (G) or SERVICE (S)","Item Description","HSN or SAC code","Item Quantity","Item Unit of Measurement","Item Rate","Total Item Discount Amount","Item Taxable Value *","CGST Rate","CGST Amount","SGST Rate","SGST Amount","IGST Rate","IGST Amount","CESS Rate","CESS Amount","Input Type","ITC Claim Type","CGST ITC Claim Amount","SGST ITC Claim Amount","IGST ITC Claim Amount","CESS ITC Claim Amount","Credit/Debit Note Date *","Credit/Debit Note Number *","Credit(C)/ Debit(D) Note Type *","Reason for issuing CDN","Is this a Bill of Supply","Is this a Nil Rated/Exempt/NonGST item?","Is Reverse Charge Applicable?","Type of Import (Goods/Services/SEZ)","Bill of Entry Port Code","Bill of Entry Number","Bill of Entry Date","Is this document cancelled?","Is the supplier a Composition dealer?","Return Filing Month","Return Filing Quarter","My GSTIN","State Place of Supply *","Supplier Address","Supplier City","Original Invoice Date (In case of amendment)","Original Invoice Number (In case of amendment)","Original Supplier GSTIN (In case of amendment)","Date of Linked Advance Payment","Voucher Number of Linked Advance Payment","Adjustment Amount of Linked Advance Payment","Goods Receipt Note Number","Goods Receipt Note Date","Goods Receipt Quantity","Goods Receipt Amount","Payment Due date","Vendor Code",TCS,"Total Transaction Value",Delete,"Voucher Number","Voucher Date";
    begin
        Clear(TempBlob);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 1, 'A', XLTxt1);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 5, 'E', XLTxt2);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 14, 'N', XLTxt3);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 22, 'V', XLTxt4);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 23, 'W', XLTxt5);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 28, 'AB', XLTxt6);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 35, 'AI', XLTxt7);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 41, 'AO', XLTxt8);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 44, 'AR', XLTxt9);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 47, 'AU', XLTxt10);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 50, 'AX', XLTxt11);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 53, 'BA', XLTxt12);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 59, 'BG', XLTxt15);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 60, 'BH', XLTxt13);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 62, 'BJ', XLTxt14);
        FOR Count := 0 TO HeaderFields::"Voucher Date" DO BEGIN
            HeaderFields := Count;
            ColumnLabel := Count;
            CreateExcelBuffer(ExcelBuffer, 3, '3', Count + 1, FORMAT(ColumnLabel), FORMAT(HeaderFields));
        END;
        Count := 4;
        IF TransHeader.FINDSET THEN
            REPEAT
                TransLineL.SETRANGE("Document Type", TransHeader."Document Type");
                TransLineL.SETRANGE("Document No.", TransHeader."Document No.");
                IF TransLineL.FINDSET THEN
                    REPEAT
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 1, 'A', FORMAT(TransHeader."Posting date"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 2, 'B', FORMAT(TransHeader."Document No."));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 3, 'C', FORMAT(TransHeader."Supplier Name"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 4, 'D', FORMAT(TransHeader."Supplier GSTIN"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 5, 'E', FORMAT(TransHeader."Supplier State"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 6, 'F', FORMAT(TransLineL."Item Type"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 7, 'G', FORMAT(TransLineL.Description));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 8, 'H', FORMAT(TransLineL."HSN/SAC code"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 9, 'I', FORMAT(TransLineL.Quantity));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 10, 'J', FORMAT(TransLineL.UOM));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 11, 'K', FORMAT(TransLineL."Unit Price"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 12, 'L', FORMAT(TransLineL.Discount));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 13, 'M', FORMAT(TransLineL."Taxable Value"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 14, 'N', FORMAT(TransLineL."CGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 15, 'O', FORMAT(TransLineL."CGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 16, 'P', FORMAT(TransLineL."SGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 17, 'Q', FORMAT(TransLineL."SGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 18, 'R', FORMAT(TransLineL."IGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 19, 'S', FORMAT(TransLineL."IGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 20, 'T', FORMAT(TransLineL."CESS Rate"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 21, 'U', FORMAT(TransLineL."CESS Value"));
                        // CreateExcelBuffer(ExcelBuffer,Count,FORMAT(Count),22,'V',FORMAT(TransLineL."Input Type"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 23, 'W', FORMAT(TransLineL."ITC Claim Type"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 24, 'X', FORMAT(TransLineL."CGST ITC Claim amt."));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 25, 'Y', FORMAT(TransLineL."SGST ITC claim amt."));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 26, 'Z', FORMAT(TransLineL."IGST ITC claim amt."));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 27, 'AA', FORMAT(TransLineL."CESS ITC claim amt."));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 28, 'AB', FORMAT(TransHeader."Credit/Debit Note date"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 29, 'AC', FORMAT(TransHeader."Credit/Debit Note No."));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 30, 'AD', FORMAT(TransHeader."Credit/Debit Note Type"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 31, 'AE', FORMAT(TransHeader."Reason for Issuing CDN"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 32, 'AF', FORMAT(TransHeader."Is Bill of Supply"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 33, 'AG', FORMAT(TransHeader."Invoice Type"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 34, 'AH', FORMAT(TransHeader."RCM applicable"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 35, 'AI', FORMAT(TransHeader."Type of Import"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 36, 'AJ', FORMAT(TransHeader."Bill of Entry Port Code"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 37, 'AK', FORMAT(TransHeader."Bill of Entry No."));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 38, 'AL', FORMAT(TransHeader."Bill of Entry Date"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 39, 'AM', FORMAT(TransHeader."Is document Cancelled"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 40, 'AN', FORMAT(TransHeader."Is Supplier a Comp. dealer"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 41, 'AO', FORMAT(TransHeader."Return filing Month"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 42, 'AP', FORMAT(TransHeader."Return filing quarter"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 43, 'AQ', FORMAT(TransHeader."My GSTIN"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 44, 'AR', FORMAT(TransHeader."Place of supply"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 45, 'AS', FORMAT(TransHeader."Supplier Address"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 46, 'AT', FORMAT(TransHeader."Supplier City"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 50, 'AX', FORMAT(TransHeader."Advance payment date"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 51, 'AY', FORMAT(TransHeader."Advance payment no."));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 52, 'AZ', FORMAT(TransHeader."Advance payment amount"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 53, 'BA', FORMAT(TransHeader."Goods receipt No."));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 54, 'BB', FORMAT(TransHeader."Goods receipt date"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 55, 'BC', FORMAT(TransHeader."Goods receipt quantity"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 56, 'BD', FORMAT(TransHeader."Goods receipt amount"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 57, 'BE', FORMAT(TransHeader."Payment due date"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 58, 'BF', FORMAT(TransHeader."Vendor Code"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 59, 'BG', FORMAT(TransHeader.TCS));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 60, 'BH', FORMAT(TransHeader."Total Transaction Value"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 61, 'BI', FORMAT(TransHeader.Delete));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 62, 'BJ', FORMAT(TransHeader."Voucher Number"));
                        CreateExcelBuffer(ExcelBuffer, Count, FORMAT(Count), 63, 'BK', FORMAT(TransHeader."Voucher Date"));
                        Count += 1;
                    UNTIL TransLineL.NEXT = 0;
            UNTIL TransHeader.NEXT = 0;
        ExcelBuffer.CreateNewBook('GSTR2 Invoice');
        ExcelBuffer.WriteSheet('', '', UserId);
        // ExcelBuffer.OpenExcel();
        tempblob.CreateOutStream(outstreamL);
        ExcelBuffer.SaveToStream(outstreamL, true);
        //ExcelBuffer.CreateBook(ServerFileName,'GSTR2 Invoice');
        //ExcelBuffer.CreateBookAndOpenExcel(ServerFileName, 'GSTR2 Invoice', '', '', USERID);

    end;

    procedure SetPostingdateFilter(FromDateP: Date; ToDateP: Date)
    begin
        FromDate := FromDateP;
        ToDate := ToDateP;
    end;

    local procedure SendRequest(MethodP: Text; URLP: Text; RequestBodyP: Text; RequestType: Integer): Boolean
    var
        HttpSendMessage: Codeunit "Http Send Message";
        URL: Text;
        Success: Boolean;
        StatusCode: Text;
        RequestStream: InStream;
        OutstreamL: OutStream;
    begin
        CLEAR(ResponseText);
        URL := MaxITCSetup."Base URL" + URLP;
        HttpSendMessage.SetMethod(MethodP);
        IF RequestType = 3 THEN BEGIN
            HttpSendMessage.SetReturnType('application/x-gzip');
        END ELSE
            IF RequestType = 2 THEN BEGIN
                HttpSendMessage.SetContentType('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
                TempBlob.CreateInStream(RequestStream);
                HttpSendMessage.AddBody(RequestStream);
            END ELSE
                IF RequestType = 1 THEN BEGIN
                    HttpSendMessage.SetHttpHeader('fileContentType', 'XLSX');
                    HttpSendMessage.SetHttpHeader('x-cleartax-orgunit', MaxITCSetup."Org Unit");
                    HttpSendMessage.SetHttpHeader('x-cleartax-user', 'CT_SAP');
                    HttpSendMessage.SetReturnType('application/json');
                END ELSE BEGIN
                    HttpSendMessage.SetReturnType('application/json');
                    HttpSendMessage.SetContentType('application/json');
                END;
        IF RequestBodyP <> '' THEN begin
            Clear(TempBlob);
            TempBlob.CreateOutStream(OutstreamL);
            OutstreamL.WriteText(RequestBodyP);
            TempBlob.CreateInStream(RequestStream);
            HttpSendMessage.AddBody(RequestStream);
        end;

        IF RequestType <> 3 THEN
            HttpSendMessage.SetRequestHttpHeader('x-cleartax-auth-token', MaxITCSetup."Auth Token");
        IF RequestType IN [2, 3] THEN
            HttpSendMessage.AddUrl(URLP)
        ELSE
            HttpSendMessage.AddUrl(URL);
        CLEAR(InStreamG);
        HttpSendMessage.SendRequest(InStreamG);

        if HttpSendMessage.IsSuccess() then begin
            Success := TRUE;
            IF RequestType <> 3 THEN begin
                if ResponseText.Read(InStreamG) then;
            end ELSE
                ResponseText.AddText('Recon file request');
        end else
            ResponseText.AddText(HttpSendMessage.Reason());
        StatusCode := Format(HttpSendMessage.StatusCode());
        IF RequestType = 2 THEN
            CreateMessageLogs(MethodP + '-' + URLP, RequestBodyP, StatusCode)
        ELSE
            CreateMessageLogs(MethodP + '-' + URL, RequestBodyP, StatusCode);
        EXIT(Success);
    end;

    local procedure CreateMessageLogs(URLP: Text; RequestBodyP: Text; StatusCodeP: Text)
    var
        MessageLogs: Record "ClearComp MaxITC Logs";
        OutStreamL: OutStream;
        JObject: JsonObject;
    begin
        MessageLogs.INIT;
        MessageLogs."Request Type" := COPYSTR(URLP, 1, 250);
        MessageLogs.Request.CREATEOUTSTREAM(OutStreamL);
        OutStreamL.WRITETEXT(RequestBodyP);
        MessageLogs."Response Code" := StatusCodeP;
        MessageLogs.Response.CREATEOUTSTREAM(OutStreamL);
        IF CheckifJsonObject(JObject) THEN
            OutStreamL.WRITETEXT(format(JObject))
        ELSE
            ResponseText.Write(OutStreamL);
        MessageLogs."User ID" := USERID;
        MessageLogs.DateTime := CURRENTDATETIME;
        MessageLogs.INSERT;
        COMMIT;
    end;

    [TryFunction]
    local procedure CheckifJsonObject(var JObjectP: JsonObject)
    begin
        JObjectP.ReadFrom(format(ResponseText));
    end;

    //+++++++++++++++++++++++++++++++Process Functions +++++++++++++++++++++++++++++++++++++++++++++++

    procedure GetConfiguration()
    var
        JObject: JsonObject;
        DummyText: Text;
        httpsendmessage: Codeunit "Http Send Message";
    begin
        Clear(TempBlob);
        MaxITCSetup.GET;
        IF SendRequest('GET', MaxITCSetup."configuration URL", '', 0) THEN BEGIN
            IF CheckifJsonObject(JObject) THEN BEGIN
                IF GetValueFromJsonObject(JObject, 'createdBy') <> '' THEN
                    MaxITCSetup."Created By" := GetValueFromJsonObject(JObject, 'createdBy');
                IF GetValueFromJsonObject(JObject, 'updatedAt') <> '' THEN
                    MaxITCSetup."Updated At" := GetValueFromJsonObject(JObject, 'updatedAt');
                IF GetValueFromJsonObject(JObject, 'updatedBy') <> '' THEN
                    MaxITCSetup."Updated By" := GetValueFromJsonObject(JObject, 'updatedBy');
                IF GetValueFromJsonObject(JObject, 'userEmail') <> '' THEN
                    MaxITCSetup."User Email" := GetValueFromJsonObject(JObject, 'userEmail');
                IF GetValueFromJsonObject(JObject, 'userExternalId') <> '' THEN
                    MaxITCSetup."User External ID" := GetValueFromJsonObject(JObject, 'userExternalId');
                IF GetValueFromJsonObject(JObject, 'customTemplateId') <> '' THEN
                    MaxITCSetup."Custom Template ID" := GetValueFromJsonObject(JObject, 'customTemplateId');
                IF GetValueFromJsonObject(JObject, 'reconType') <> '' THEN
                    MaxITCSetup."Recon Type" := GetValueFromJsonObject(JObject, 'reconType');
                IF GetValueFromJsonObject(JObject, 'sectionNames') <> '' THEN
                    MaxITCSetup."Section Names" := GetValueFromJsonObject(JObject, 'sectionNames');

                IF GetValueFromJsonObject(JObject, 'pullReturnPeriodStart') <> '' THEN BEGIN
                    DummyText := GetValueFromJsonObject(JObject, 'pullReturnPeriodStart');
                    DummyText := INSSTR(DummyText, '/', 3);
                    MaxITCSetup."Pull return period start" := DummyText;
                END;
                IF GetValueFromJsonObject(JObject, 'reconReturnPeriodStart') <> '' THEN BEGIN
                    DummyText := GetValueFromJsonObject(JObject, 'reconReturnPeriodStart');
                    DummyText := INSSTR(DummyText, '/', 3);
                    MaxITCSetup."Recon return period start" := DummyText;
                END;
                IF GetValueFromJsonObject(JObject, 'pullReturnPeriodEnd') <> '' THEN BEGIN
                    DummyText := GetValueFromJsonObject(JObject, 'pullReturnPeriodEnd');
                    DummyText := INSSTR(DummyText, '/', 3);
                    MaxITCSetup."Pull return period end" := DummyText;
                END;
                IF GetValueFromJsonObject(JObject, 'reconReturnPeriodEnd') <> '' THEN BEGIN
                    DummyText := GetValueFromJsonObject(JObject, 'reconReturnPeriodEnd');
                    DummyText := INSSTR(DummyText, '/', 3);
                    MaxITCSetup."Recon return period end" := DummyText;
                END;
                IF GetValueFromJsonObject(JObject, 'storageProxyEnabled') <> '' THEN
                    IF uppercase(GetValueFromJsonObject(JObject, 'storageProxyEnabled')) = 'TRUE' THEN
                        MaxITCSetup."Storage Proxy enabled" := TRUE
                    ELSE
                        MaxITCSetup."Storage Proxy enabled" := FALSE;
                IF GetValueFromJsonObject(JObject, 'active') <> '' THEN
                    IF uppercase(GetValueFromJsonObject(JObject, 'active')) = 'TRUE' THEN
                        MaxITCSetup.Active := TRUE
                    ELSE
                        MaxITCSetup.Active := FALSE;
                MaxITCSetup.MODIFY;
            END;

        END ELSE
            MESSAGE(format(ResponseText) + '\\' + ErrorText);
    end;

    procedure SendDataAndTriggerMaxITC(var TransHeaderP: Record "ClearComp MaxITC Trans. Header")
    var
        JObject: JsonObject;
        PreSignedURL: BigText;
        RequestBody: Text;
        WorkFlowIDL: Text;
        FileName: Text;
    begin
        CLEAR(ServerFileName);
        MaxITCSetup.GET;
        TransHeader.COPY(TransHeaderP);
        TransHeader.SETRANGE(Selected, TRUE);
        TransHeader.SETRANGE(WorkFlowID, '');
        IF TransHeader.FINDSET THEN BEGIN

            ReadDataToExcelPurchaseorBillofSupply();

            if not TempBlob.HasValue() then
                ERROR(XLNotFound);

            //Get pre-signed url
            FileName := DELCHR(FORMAT(TODAY), '=', DELCHR(FORMAT(TODAY), '=', '1234567890')) + '.xlsx';
            IF SendRequest('GET', MaxITCSetup."Pre-Signed URL" + FileName, '', 1) THEN BEGIN
                IF CheckifJsonObject(JObject) THEN
                    IF GetValueFromJsonObject(JObject, 'status') <> '' THEN
                        IF GetValueFromJsonObject(JObject, 'status') = 'CREATED' THEN
                            PreSignedURL.ADDTEXT(GetValueFromJsonObject(JObject, 'preSignedS3Url'));
            END ELSE
                ERROR(format(ResponseText) + '\\' + ErrorText);

            IF FORMAT(PreSignedURL) = '' THEN
                EXIT;

            //upload file to pre-signed url
            IF NOT SendRequest('PUT', FORMAT(PreSignedURL), '', 2) THEN
                ERROR(format(ResponseText) + '\\' + ErrorText);
            TransHeader.MODIFYALL(Uploaded, TRUE);
            //trigger maxitc
            RequestBody := ReadTriggerMaxITCJson(PreSignedURL, FileName);
            IF SendRequest('POST', MaxITCSetup."Trigger URL", RequestBody, 0) THEN BEGIN
                IF CheckifJsonObject(JObject) THEN
                    IF NOT (UPPERCASE((GetValueFromJsonObject(JObject, 'status'))) = 'WORKFLOW_FAILED') THEN
                        IF GetValueFromJsonObject(JObject, 'workflowId') <> '' THEN BEGIN
                            WorkFlowIDL := GetValueFromJsonObject(JObject, 'workflowId');
                            TransHeader.MODIFYALL(WorkFlowID, WorkFlowIDL);
                        END;

            END ELSE
                ERROR(format(ResponseText) + '\\' + ErrorText);
        END;
        COMMIT;
        //IF WorkFlowIDL = '' THEN  //for manual check status process
        //WorkFlowIDL := TransHeader.WorkFlowID;

        //CheckStatus
        IF WorkFlowIDL <> '' THEN
            //CheckStatus(WorkFlowIDL);
            CreateJobQueueToCheckStatus(WorkFlowIDL);
    end;

    local procedure ReadTriggerMaxITCJson(PresignedURL: BigText; FileName: Text): Text
    var
        JObject: JsonObject;
        JArray: JsonArray;
        JSubObject: JsonObject;
        CompanyInformation: Record "Company Information";
        Pos: Integer;
    begin
        JSubObject.Add('userFileName', FileName);
        JSubObject.Add('userFileName', FileName);
        Pos := STRPOS(FORMAT(PresignedURL), '?');
        JSubObject.Add('s3FileUrl', COPYSTR(FORMAT(PresignedURL), 1, Pos - 1));
        JArray.Add(JSubObject);
        JObject.Add('fileList', JArray);
        CLEAR(JSubObject);
        CLEAR(JArray);
        JSubObject.Add('gstins', JArray);
        // Need to check how pan should be added.
        CompanyInformation.GET;
        //JSubObject.Add( 'pan',CompanyInformation."P.A.N. No.")); //this line to be added instead of below hardcoded line.
        JSubObject.Add('pan', 'AAFCD5862R');
        JSubObject.Add('pullReturnPeriodEnd', DELCHR(MaxITCSetup."Pull return period end", '=', '/'));
        JSubObject.Add('pullReturnPeriodStart', DELCHR(MaxITCSetup."Pull return period start", '=', '/'));
        JSubObject.Add('reconReturnPeriodEnd', DELCHR(MaxITCSetup."Recon return period end", '=', '/'));
        JSubObject.Add('reconReturnPeriodStart', DELCHR(MaxITCSetup."Recon return period start", '=', '/'));
        JSubObject.Add('reconType', MaxITCSetup."Recon Type");
        JSubObject.Add('templateId', MaxITCSetup."Custom Template ID");
        JObject.Add('userInputArgs', JSubObject);
        EXIT(Format(JObject));
    end;

    local procedure CreateJobQueueToCheckStatus(WorkflowID: Text)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SETRANGE("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SETRANGE("Object ID to Run", CODEUNIT::"ClearComp MaxITC Job Queue");
        JobQueueEntry.SETRANGE("Parameter String", WorkflowID);
        IF NOT JobQueueEntry.FINDFIRST THEN BEGIN
            JobQueueEntry.InitRecurringJob(2);
            JobQueueEntry.ID := CREATEGUID;
            JobQueueEntry.VALIDATE("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
            JobQueueEntry.VALIDATE("Object ID to Run", CODEUNIT::"ClearComp MaxITC Job Queue");
            JobQueueEntry."Earliest Start Date/Time" := CURRENTDATETIME + (1 * 60 * 1000);
            JobQueueEntry.VALIDATE(Status, JobQueueEntry.Status::Ready);
            JobQueueEntry."User ID" := USERID;
            JobQueueEntry."Parameter String" := WorkflowID;
            JobQueueEntry.INSERT();
        END;
    end;

    procedure CheckStatus(WorkflowIDP: Text): Boolean
    var
        ReconFileURL: BigText;
        ReconVendorFileURL: BigText;
        ErrorFileURL: BigText;
        ReconFile: BigText;
        Success: Boolean;
        OutStreamL: OutStream;
        InstreamL: InStream;
        FileL: File;
        JToken: JsonToken;
        JObject: JsonObject;
        JArray: JsonArray;
        TextBuilderL: TextBuilder;
        ReconResults: Record "ClearComp ReconResults Blobs";
    begin
        MaxITCSetup.GET;
        IF SendRequest('GET', MaxITCSetup."Check status URL" + WorkflowIDP, '', 0) THEN BEGIN
            IF NOT CheckifJsonObject(JObject) THEN
                ERROR(format(ResponseText) + '\\' + ErrorText);
            IF NOT (UPPERCASE(GetValueFromJsonObject(JObject, 'status')) = 'WORKFLOW_COMPLETED') THEN
                ErrorText := GetValueFromJsonObject(JObject, 'status');
            IF NOT (UPPERCASE(GetValueFromJsonObject(JObject, 'reconStatus.status')) = 'SUCCESS') THEN
                ErrorText := GetValueFromJsonObject(JObject, 'reconStatus.status');
            IF GetValueFromJsonObject(JObject, 'reconStatus.reconResultsFileUrl') <> '' THEN BEGIN
                ReconFileURL.ADDTEXT(GetValueFromJsonObject(JObject, 'reconStatus.reconResultsFileUrl'));
                ReconVendorFileURL.ADDTEXT(GetValueFromJsonObject(JObject, 'reconStatus.reconResultsVendorFileUrl'));
            END;
            IF GetValueFromJsonObject(JObject, 'fileErrors') <> '' THEN BEGIN
                JArray.ReadFrom(GetValueFromJsonObject(JObject, 'fileErrors'));
                FOREACH JToken IN JArray DO BEGIN
                    JObject := JToken.AsObject();
                    IF GetValueFromJsonObject(JObject, 'status') <> '' THEN
                        ErrorText := GetValueFromJsonObject(JObject, 'status');
                    ErrorFileURL.ADDTEXT(GetValueFromJsonObject(JObject, 'errorFileUrl'));
                END;
            END;

            TransHeader.SETRANGE(WorkFlowID, WorkflowIDP);
            if not ReconResults.Get(TransHeader."Document Type", TransHeader."Document No.") then begin
                ReconResults."Document Type" := TransHeader."Document Type";
                ReconResults."Document No." := TransHeader."Document No.";
                ReconResults.Insert();
            end;
            IF FORMAT(ReconFileURL) <> '' THEN
                IF SendRequest('GET', FORMAT(ReconFileURL), '', 3) THEN BEGIN
                    DeCompressGZip(ReconFile);
                    ReconFile.READ(InstreamL);
                    TextBuilderL.Append(format(ReconFile));
                    TextBuilderL.Replace('}}', '}},');
                    TextBuilderL.Insert(1, '[');
                    TextBuilderL.Insert(TextBuilderL.Length + 1, ']');
                    JArray.ReadFrom(TextBuilderL.ToText());

                    if Format(JArray) <> '' then begin
                        ReconResults.ReconResults.CreateOutStream(OutStreamL);
                        OutStreamL.WRITETEXT(FORMAT(JArray));
                        if not ReconResults.Insert() then
                            ReconResults.Modify();
                    end;
                END;
            IF FORMAT(ReconVendorFileURL) <> '' THEN
                IF SendRequest('GET', FORMAT(ReconVendorFileURL), '', 3) THEN BEGIN
                    ReconResults.ReconResultsVendor.CreateOutStream(OutStreamL);
                    COPYSTREAM(OutStreamL, InStreamG);
                    ReconResults.Modify();
                END;
            IF FORMAT(ErrorFileURL) <> '' THEN
                IF SendRequest('GET', FORMAT(ErrorFileURL), '', 3) THEN BEGIN
                    ReconResults.ErrorFile.CreateOutStream(OutStreamL);
                    COPYSTREAM(OutStreamL, InStreamG);
                    ReconResults.Modify();
                END;
            COMMIT;
            IF ErrorText <> '' THEN
                ERROR(ErrorText);
        END ELSE
            ERROR(ErrorText);
        EXIT(Success);
    end;

    procedure ShowUploadedTransactions()
    var
        TransactionList: Page "ClearComp MaxITC Trans. List";
    begin
        TransHeader.SETCURRENTKEY("Document Type", "Document No.", WorkFlowID);
        TransHeader.SETFILTER(WorkFlowID, '<>%1', '');
        IF TransHeader.FINDFIRST THEN BEGIN
            TransactionList.SetFieldVisibility;
            TransactionList.SETTABLEVIEW(TransHeader);
            TransactionList.CAPTION('Uploaded Transactions');
            TransactionList.EDITABLE(FALSE);
            TransactionList.RUNMODAL;
        END;
    end;

    procedure DownloadReconFile(ReconResults: Record "ClearComp ReconResults Blobs")
    var
        FileManagment: Codeunit "File Management";
    begin
        ServerFileName := FileManagment.Magicpath() + '.txt';
        ReconResults.ReconResults.CreateInStream(InstreamG);
        DownloadFromStream(InstreamG, '', '', '', ServerFileName);

    end;

    procedure DownloadErrorFile(TransHeaderP: Record "ClearComp MaxITC Trans. Header")
    var
        ReconResults: Record "ClearComp ReconResults Blobs";
        FileManagment: Codeunit "File Management";
        OutStreamL: OutStream;
    begin
        if ReconResults.Get(TransHeaderP."Document Type", TransHeaderP."Document No.") then
            if ReconResults.ErrorFile.HasValue then begin
                ServerFileName := FileManagment.Magicpath() + '.txt';
                ReconResults.ErrorFile.CreateInStream(InStreamG);
                DownloadFromStream(InstreamG, '', '', '', ServerFileName);
            end;
    end;

    local procedure DeCompressGZip(var ReconFile: BigText)
    var
        DeCompress: Codeunit "Data Compression";
        outstreamL: OutStream;
        InstreamL: InStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(outstreamL);
        DeCompress.GZipDecompress(InStreamG, outstreamL);
        TempBlob.CreateInStream(InstreamL);
        ReconFile.Read(InstreamL);
    end;

    local procedure GetValueFromJsonObject(JObjectP: JsonObject; PropertyNameP: Text): Text;
    var
        JTokenL: JsonToken;
        ValueL: Text;
    begin
        JObjectP.Get(PropertyNameP, JTokenL);
        if JTokenL.IsValue() then begin
            if not JTokenL.AsValue().IsNull then
                exit(JTokenL.AsValue().AsText());
        end else
            if JTokenL.IsArray then
                JTokenL.WriteTo(ValueL);
        exit(ValueL);
    end;
}

