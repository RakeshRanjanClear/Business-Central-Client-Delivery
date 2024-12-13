codeunit 50111 "ClearComp GST Management Unit"
{
    trigger OnRun()
    var
        PreviewTransList: Page "ClearComp Prev. Trans. List";
    begin
        GSTSetup.Get();
        if (GSTSetup."Sync Invoices" = GSTSetup."Sync Invoices"::"Job Queue") and (not Manual) then begin
            FromDate := GSTSetup."Job Queue From Date";
            ToDate := Today();
        end;
        // To add details of advance payment or receipt to transheader table.
        // if GSTSetup."Sync Invoices" <> GSTSetup."Sync Invoices"::"While Posting" then
        //     AddAdvanceDetails();
        if GSTSetup."Sync Invoices" <> GSTSetup."Sync Invoices"::"While Posting" then
            UpdatetransHeader();
        GSTTransHeader.SetCurrentKey("Transaction Type", "Document Type", "Posting Date");
        GSTTransHeader.SetRange("Return Filed", false);
        if (GSTSetup."Sync Invoices" = GSTSetup."Sync Invoices"::"While Posting") and (not Manual) then
            GSTTransHeader.SetRange("While Posting", true)
        else begin
            if (FromDate <> 0D) and (ToDate <> 0D) then
                GSTTransHeader.SetRange("Posting Date", FromDate, ToDate);
            if DocNoG <> '' then
                GSTTransHeader.SetRange("Document No.", DocNoG);
            if GSTTransHeader.IsEmpty() then
                Error(NoDataError, FromDate, ToDate);
        end;
        GSTTransHeader.SetFilter(Status, '<>%1', GSTTransHeader.Status::Synced);
        if GSTTransHeader.IsEmpty() then
            Error(SyncedError, FromDate, ToDate);
        // To avoid processing of data again if it was already updated. since posted document data will not change.
        //GSTTransHeader.SetRange(Updated, false);
        if GSTTransHeader.FindSet() then//change in nav16
            repeat
                case GSTTransHeader."Transaction Type" of
                    GSTTransHeader."Transaction Type"::SALE:
                        case GSTTransHeader."Document Type" of
                            GSTTransHeader."Document Type"::Invoice:
                                ProcessSalesInvoiceData();
                            GSTTransHeader."Document Type"::"Credit Memo":
                                ProcessSalesCreditMemoData();
                        // GSTTransHeader."Document Type"::Advance:
                        //     ProcessAdvanceData();
                        end;
                    GSTTransHeader."Transaction Type"::PURCHASE:
                        case GSTTransHeader."Document Type" of
                            GSTTransHeader."Document Type"::Invoice:
                                ProcessPurchaseInvoiceData();
                            GSTTransHeader."Document Type"::"Credit Memo":
                                ProcessPurchaseCreditMemoData();
                        // GSTTransHeader."Document Type"::Advance:
                        //     ProcessAdvanceData();
                        end;
                end;
                GSTTransHeader.Updated := true;
                GSTTransHeader.Modify();
            until GSTTransHeader.Next() = 0;
        // Filter removed as data was updated only on TransHeader table but not sent to ClearTax.
        GSTTransHeader.SetRange(Updated);
        GSTTransHeader.ModifyAll(Selected, true);

        if ((GSTSetup."Sync Invoices" in [GSTSetup."Sync Invoices"::"Job Queue", GSTSetup."Sync Invoices"::"While Posting"]) and (not Manual)) then
            SendData(GSTTransHeader)
        else
            if Manual then begin
                Commit();
                PreviewTransList.SetTableView(GSTTransHeader);
                PreviewTransList.LookupMode(true);
                PreviewTransList.SetSendDataVisible();
                PreviewTransList.Editable(true);
                if PreviewTransList.RunModal() = Action::LookupOK then
                    ;
                Commit();
            end;
    end;

    local procedure ProcessSalesInvoiceData()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if SalesInvoiceHeader.Get(GSTTransHeader."Document No.") then begin
            ReadHeaderDetailsSalesInvoice(SalesInvoiceHeader);
            ReadLineDetailsSalesInvoice(SalesInvoiceHeader);
            ReadSellerDetails(SalesInvoiceHeader."Location Code", SalesInvoiceHeader."Location GST Reg. No.");
            ReadBuyerDetailsSalesInvoice(SalesInvoiceHeader);
            if not GSTTransHeader."Is Bill of Supply" then begin
                ReadExportDetailsSalesInvoice(SalesInvoiceHeader);
                ReadECommerceDetailsSalesInvoice(SalesInvoiceHeader);
            end;
        end;
    end;

    local procedure ReadHeaderDetailsSalesInvoice(SalesInvoiceHeaderP: Record "Sales Invoice Header")
    var
        RecRef: RecordRef;
        Customer: Record Customer;
    begin
        RecRef.GetTable(SalesInvoiceHeaderP);
        if SalesInvoiceHeaderP."Invoice Type" in [SalesInvoiceHeaderP."Invoice Type"::"Bill of Supply", SalesInvoiceHeaderP."Invoice Type"::"Non-GST"] then
            GSTTransHeader."Is Bill of Supply" := true;
        GSTTransHeader."External Document no." := SalesInvoiceHeaderP."External Document No.";
        GSTTransHeader.IRN := SalesInvoiceHeaderP."IRN Hash";
        GSTTransHeader."Due Date" := SalesInvoiceHeaderP."Due Date";
        //++Seaways
        if SalesInvoiceHeaderP.State = 'OT' then
            GSTTransHeader."Place of Supply" := '97'
        else
            //--Seaways
            GSTTransHeader."Place of Supply" := GetPlaceofSupply(RecRef);
        GSTTransHeader."Reverse Charge Applicable" := GetReverseChargeApplicable();
        if Customer.GET(SalesInvoiceHeaderP."Sell-to Customer No.") then
            if Customer."GST Customer Type" = Customer."GST Customer Type"::Unregistered then
                GSTTransHeader."Customer Type" := GSTTransHeader."Customer Type"::UIN_REGISTERED;
        //Contition to be added for composition customer type 
        GSTTransHeader."Reference Doc No." := SalesInvoiceHeaderP."No.";
        GSTTransHeader."Original Inv. Classification" := GetInvoiceClassification(RecRef);
        GSTTransHeader.Modify();
    end;

    local procedure GetPlaceofSupply(RecRef: RecordRef): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        PurchCrMemoHeaderL: Record "Purch. Cr. Memo Hdr.";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        State: Record State;
        Location: Record Location;
        Customer: Record Customer;
    begin
        case RecRef.Number of
            Database::"Sales Invoice Header":
                begin
                    RecRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
                    SalesInvoiceLine.SetFilter("GST Place of Supply", '<>%1', SalesInvoiceLine."GST Place of Supply"::" ");
                    if SalesInvoiceLine.FindFirst() then begin
                        case SalesInvoiceLine."GST Place of Supply" of
                            SalesInvoiceLine."GST Place of Supply"::"Ship-to Address":
                                if State.Get(SalesInvoiceHeader."GST Ship-to State Code") then
                                    ;
                            SalesInvoiceLine."GST Place of Supply"::"Location Address":
                                if State.Get(SalesInvoiceHeader."Location State Code") then
                                    ;
                            SalesInvoiceLine."GST Place of Supply"::"Bill-to Address":
                                if State.Get(SalesInvoiceHeader."GST Bill-to State Code") then
                                    ;
                        end;
                        if State."State Code (GST Reg. No.)" <> '' then
                            exit(State."State Code (GST Reg. No.)");
                    end;
                    if Customer.get(SalesInvoiceHeader."Bill-to Customer No.") then
                        if State.Get(Customer."State Code") and (State."State Code (GST Reg. No.)" > '') then // Change in Nav16
                            exit(State."State Code (GST Reg. No.)");
                end;
            Database::"Purch. Inv. Header":
                begin
                    RecRef.SetTable(PurchInvHeader);
                    if Location.Get(PurchInvHeader."Location Code") then
                        if State.Get(Location."State Code") and (State."State Code (GST Reg. No.)" > '') then
                            exit(State."State Code (GST Reg. No.)");
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    RecRef.SetTable(SalesCrMemoHeader);
                    SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
                    SalesCrMemoLine.SetFilter("GST Place of Supply", '<>%1', SalesCrMemoLine."GST Place of Supply"::" ");
                    if SalesCrMemoLine.FindFirst() then begin
                        case SalesCrMemoLine."GST Place of Supply" of
                            SalesCrMemoLine."GST Place of Supply"::"Ship-to Address":
                                if State.Get(SalesCrMemoHeader."GST Ship-to State Code") then;
                            SalesInvoiceLine."GST Place of Supply"::"Location Address":
                                if State.Get(SalesCrMemoHeader."Location State Code") then;
                            SalesInvoiceLine."GST Place of Supply"::"Bill-to Address":
                                if State.Get(SalesCrMemoHeader."GST Bill-to State Code") then;
                        end;
                        if State."State Code (GST Reg. No.)" <> '' then
                            exit(State."State Code (GST Reg. No.)");
                    end;
                    if Customer.get(SalesCrMemoHeader."Bill-to Customer No.") then
                        if State.Get(Customer."State Code") and (State."State Code (GST Reg. No.)" > '') then // Change in Nav16
                            exit(State."State Code (GST Reg. No.)");
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    RecRef.SetTable(PurchCrMemoHeaderL);
                    if Location.Get(PurchCrMemoHeaderL."Location Code") then
                        if State.Get(Location."State Code") then
                            exit(State."State Code (GST Reg. No.)");
                end;
            Database::"Bank Account Ledger Entry":// Change in NAV16
                begin
                    RecRef.SetTable(BankAccountLedgerEntry);
                    if BankAccountLedgerEntry."Bal. Account Type" in [BankAccountLedgerEntry."Bal. Account Type"::Customer, BankAccountLedgerEntry."Bal. Account Type"::Vendor] then begin
                        DetailedGSTLedgerEntry.SetRange("Document No.", Format(BankAccountLedgerEntry."Entry No."));
                        DetailedGSTLedgerEntry.SetFilter("GST Component Code", '%1|%2|%3', 'CGST', 'SGST', 'IGST');
                        if DetailedGSTLedgerEntry.FindFirst() then
                            if Location.Get(DetailedGSTLedgerEntry."Location Code") then
                                if State.Get(Location."State Code") and (State."State Code (GST Reg. No.)" > '') then
                                    exit(State."State Code (GST Reg. No.)");
                    end;
                end;
        end;
    end;

    local procedure GetReverseChargeApplicable(): Boolean
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntry.SetRange("Document No.", GSTTransHeader."Document No.");
        DetailedGSTLedgerEntry.SetFilter("GST Component Code", '%1|%2|%3', 'CGST', 'SGST', 'IGST');
        DetailedGSTLedgerEntry.SetRange("Reverse Charge", true);
        if DetailedGSTLedgerEntry.FindFirst() then
            exit(true);
    end;

    local procedure GetInvoiceClassification(RecRefP: RecordRef): Integer
    var

        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchCrMemoHdr: record "Purch. Cr. Memo Hdr.";
    begin
        case RecRefP.Number of
            Database::"Sales Invoice Header":
                begin
                    RecRefP.SetTable(SalesInvoiceHeader);
                    if (SalesInvoiceHeader."Nature of Supply" = SalesInvoiceHeader."Nature of Supply"::B2B) or (SalesInvoiceHeader."GST Customer Type" in
                        [SalesInvoiceHeader."GST Customer Type"::Exempted, SalesInvoiceHeader."GST Customer Type"::Registered])
                    then
                        exit(GSTTransHeader."Original Inv. Classification"::B2B);

                    if (SalesInvoiceHeader."Nature of Supply" = SalesInvoiceHeader."Nature of Supply"::B2C) or (SalesInvoiceHeader."GST Customer Type" =
                        SalesInvoiceHeader."GST Customer Type"::Unregistered)
                    then
                        exit(GSTTransHeader."Original Inv. Classification"::B2C);

                    if SalesInvoiceHeader."GST Customer Type" in [SalesInvoiceHeader."GST Customer Type"::Export,
                        SalesInvoiceHeader."GST Customer Type"::"Deemed Export"]
                    then
                        exit(GSTTransHeader."Original Inv. Classification"::EXPORT);
                end;
            Database::"Purch. Inv. Header":
                begin
                    RecRefP.SetTable(PurchInvHeader);
                    if (PurchInvHeader."Nature of Supply" = PurchInvHeader."Nature of Supply"::B2B) or (PurchInvHeader."GST Vendor Type" in
                        [PurchInvHeader."GST Vendor Type"::Exempted, PurchInvHeader."GST Vendor Type"::Registered])
                    then
                        exit(GSTTransHeader."Original Inv. Classification"::B2B);

                    if (PurchInvHeader."Nature of Supply" = PurchInvHeader."Nature of Supply"::B2C) or (PurchInvHeader."GST Vendor Type" =
                        PurchInvHeader."GST Vendor Type"::Unregistered)
                    then
                        exit(GSTTransHeader."Original Inv. Classification"::B2C);

                    if PurchInvHeader."GST Vendor Type" = PurchInvHeader."GST Vendor Type"::Import then
                        exit(GSTTransHeader."Original Inv. Classification"::IMPORT);
                    if PurchInvHeader."GST Vendor Type" = PurchInvHeader."GST Vendor Type"::Composite then
                        exit(GSTTransHeader."Original Inv. Classification"::COMPOSITE);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    RecRefP.SetTable(SalesCrMemoHeader);
                    if (SalesCrMemoHeader."Nature of Supply" = SalesCrMemoHeader."Nature of Supply"::B2B) or (SalesCrMemoHeader."GST Customer Type" in
                        [SalesCrMemoHeader."GST Customer Type"::Exempted, SalesCrMemoHeader."GST Customer Type"::Registered])
                    then
                        exit(GSTTransHeader."Original Inv. Classification"::B2B);

                    if (SalesCrMemoHeader."Nature of Supply" = SalesCrMemoHeader."Nature of Supply"::B2C) or (SalesCrMemoHeader."GST Customer Type" =
                        SalesCrMemoHeader."GST Customer Type"::Unregistered)
                    then
                        exit(GSTTransHeader."Original Inv. Classification"::B2C);

                    if SalesCrMemoHeader."GST Customer Type" in [SalesCrMemoHeader."GST Customer Type"::Export, SalesCrMemoHeader."GST Customer Type"::"Deemed Export"] then
                        exit(GSTTransHeader."Original Inv. Classification"::EXPORT);
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    RecRefP.SetTable(PurchCrMemoHdr);
                    if (PurchCrMemoHdr."Nature of Supply" = PurchCrMemoHdr."Nature of Supply"::B2B) or (PurchCrMemoHdr."GST Vendor Type" in
                        [PurchCrMemoHdr."GST Vendor Type"::Exempted, PurchCrMemoHdr."GST Vendor Type"::Registered])
                    then
                        exit(GSTTransHeader."Original Inv. Classification"::B2B);

                    if (PurchCrMemoHdr."Nature of Supply" = PurchCrMemoHdr."Nature of Supply"::B2C) or (PurchCrMemoHdr."GST Vendor Type" =
                        PurchCrMemoHdr."GST Vendor Type"::Unregistered)
                    then
                        exit(GSTTransHeader."Original Inv. Classification"::B2C);

                    if PurchCrMemoHdr."GST Vendor Type" = PurchCrMemoHdr."GST Vendor Type"::Import then
                        exit(GSTTransHeader."Original Inv. Classification"::IMPORT);
                    if PurchCrMemoHdr."GST Vendor Type" = PurchCrMemoHdr."GST Vendor Type"::Composite then
                        exit(GSTTransHeader."Original Inv. Classification"::COMPOSITE);
                end;
        end;
    end;

    local procedure ReadLineDetailsSalesInvoice(SalesInvoiceHeaderP: Record "Sales Invoice Header")
    var
        GSTTransLine: Record "ClearComp GST Trans. Line";
        SalesInvoiceLineL: Record "Sales Invoice Line";
        CustomerPostingGroup: Record "Customer Posting Group";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        HSNSAC: Record "HSN/SAC";
        TotalGSTAmount: Decimal;
        TCSEntry: Record "TCS Entry";
    begin
        GSTTransLine.SetRange("Document Type", GSTTransHeader."Document Type");
        GSTTransLine.SetRange("Document No.", GSTTransHeader."Document No.");
        GSTTransLine.SetRange("Transaction Type", GSTTransLine."Transaction Type"::SALE);
        if GSTTransLine.FindSet() then
            GSTTransLine.DeleteAll();
        Clear(GSTTransLine);

        SalesInvoiceLineL.SetRange("Document No.", SalesInvoiceHeaderP."No.");
        SalesInvoiceLineL.SetFilter("No.", '<>%1', '');
        SalesInvoiceLineL.SetFilter(Quantity, '<>%1', 0);
        SalesInvoiceLineL.SetRange("System-Created Entry", false);
        if SalesInvoiceLineL.FindSet() then
            repeat
                Clear(GSTTransLine);
                GSTTransLine."Transaction Type" := GSTTransHeader."Transaction Type";
                GSTTransLine."Document Type" := GSTTransHeader."Document Type";
                GSTTransLine."Document No." := GSTTransHeader."Document No.";
                GSTTransLine."Line No." := SalesInvoiceLineL."Line No.";
                GSTTransLine.Description := SalesInvoiceLineL.Description;
                if SalesInvoiceLineL."Description 2" > '' then
                    GSTTransLine.Description += ' ' + SalesInvoiceLineL."Description 2";
                GSTTransLine.Quantity := SalesInvoiceLineL.Quantity;
                GSTTransLine."Unit Price" := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), SalesInvoiceHeaderP."Currency Code", SalesInvoiceLineL."Unit Price",
                                                SalesInvoiceHeaderP."Currency Factor"), 0.01, '=');

                GSTTransLine.UOM := CopyStr(SalesInvoiceLineL."Unit of Measure", 1, 3);

                GSTTransLine."Taxable Value" := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), SalesInvoiceHeaderP."Currency Code", SalesInvoiceLineL.Amount,
                                                SalesInvoiceHeaderP."Currency Factor"), 0.01, '=');

                if (SalesInvoiceHeaderP."Invoice Type" <> SalesInvoiceHeaderP."Invoice Type"::"Bill of Supply") then
                    GetGSTCompRate(GSTTransLine);

                TCSEntry.SetRange("Document No.", GSTTransHeader."Document No.");
                if TCSEntry.FindFirst() then
                    ;
                TotalGSTAmount := GSTTransLine."CGST Value" + GSTTransLine."SGST Value" + GSTTransLine."IGST Value";
                // SalesInvoiceLineL."Charges To Customer" is not included in the below calucation
                GSTTransLine."Total Value" := GSTTransLine."Taxable Value" + Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), SalesInvoiceHeaderP."Currency Code", TotalGSTAmount,
                                                                                SalesInvoiceHeaderP."Currency Factor"), 0.01, '=')
                                                                           + Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WORKDATE, SalesInvoiceHeaderP."Currency Code", TCSEntry."Total TCS Including SHE CESS",
                                                                                    SalesInvoiceHeaderP."Currency Factor"), 0.01, '=');

                GSTTransLine."GST Code" := SalesInvoiceLineL."HSN/SAC Code";
                if HSNSAC.Get(SalesInvoiceLineL."GST Group Code", SalesInvoiceLineL."HSN/SAC Code") then
                    if HSNSAC.Type = HSNSAC.Type::HSN then
                        GSTTransLine."GST Type" := GSTTransLine."GST Type"::GOODS
                    else
                        GSTTransLine."GST Type" := GSTTransLine."GST Type"::SERVICES;

                if SalesInvoiceHeaderP."Invoice Type" = SalesInvoiceHeaderP."Invoice Type"::"Non-GST" then
                    GSTTransLine."Zero Tax Category" := GSTTransLine."Zero Tax Category"::"Non GST Supply";
                if SalesInvoiceHeaderP."Invoice Type" = SalesInvoiceHeaderP."Invoice Type"::"Bill of Supply" then
                    GSTTransLine."Zero Tax Category" := GSTTransLine."Zero Tax Category"::"Nil Rated";
                if TCSEntry."Total TCS Including SHE CESS" > 0 then begin
                    GSTTransHeader."TDS Applicable" := true;
                    GSTTransHeader.Modify();
                end;
                GSTTransLine.Discount := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), SalesInvoiceHeaderP."Currency Code",
                                            SalesInvoiceLineL."Line Discount Amount", SalesInvoiceHeaderP."Currency Factor"), 0.01, '=');

                GSTTransLine."Line No." := GSTTransLine.GetNextFreeLine(GSTTransLine."Transaction Type", GSTTransLine."Document Type", GSTTransLine."Document No.");
                GSTTransLine.Insert();
            until SalesInvoiceLineL.Next() = 0
    end;

    local procedure ReadSellerDetails(LocationCodeP: Code[20]; GSTIN: code[15])
    var
        Location: Record Location;
        CompanyInformation: Record "Company Information";
        State: Record State;
    begin
        CompanyInformation.Get();
        GSTTransHeader."Seller Name" := CompanyInformation.Name;
        GSTTransHeader."Seller GSTIN" := GSTIN;
        if Location.Get(LocationCodeP) then begin
            // GSTTransHeader."Seller GSTIN" := Location."GST Registration No.";
            GSTTransHeader."Seller Address" := Location.Address;
            if Location."Address 2" > '' then
                GSTTransHeader."Seller Address" += ' ' + Location."Address 2";
            GSTTransHeader."Seller City" := Location.City;
            if State.Get(Location."State Code") then
                GSTTransHeader."Seller State" := State."State Code (GST Reg. No.)";
            GSTTransHeader."Seller Zip Code" := Location."Post Code";
            GSTTransHeader."Seller Country" := Location."Country/Region Code";
            GSTTransHeader."Seller Phone No." := Location."Phone No.";
            GSTTransHeader."Seller/Buyer Taxable entity" := Location."Taxable Entity";
        end;
        GSTTransHeader.Modify();
    end;

    local procedure ReadBuyerDetailsSalesInvoice(SalesInvoiceHeaderP: Record "Sales Invoice Header")
    var
        Customer: Record Customer;
        Contact: Record Contact;
        Location: Record Location;
        ShipToAddress: Record "Ship-to Address";
        state: Record State;
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        GSTTransHeader."Buyer Name" := SalesInvoiceHeaderP."Bill-to Name";
        if ShipToAddress.Get(SalesInvoiceHeaderP."Bill-to Customer No.", SalesInvoiceHeaderP."Ship-to Code") and (ShipToAddress."GST Registration No." > '') then
            GSTTransHeader."Buyer GSTIN" := ShipToAddress."GST Registration No."
        else
            if Customer.Get(SalesInvoiceHeaderP."Bill-to Customer No.") then
                GSTTransHeader."Buyer GSTIN" := Customer."GST Registration No.";

        GSTTransHeader."Buyer Address" := SalesInvoiceHeaderP."Bill-to Address";
        if SalesInvoiceHeaderP."Bill-to Address 2" > '' then
            GSTTransHeader."Buyer Address" += SalesInvoiceHeaderP."Bill-to Address 2";
        GSTTransHeader."Buyer City" := SalesInvoiceHeaderP."Bill-to City";

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeaderP."No.");
        SalesInvoiceLine.SetFilter("No.", '<>%1', '');
        SalesInvoiceLine.SetFilter(Quantity, '<>%1', 0);
        if SalesInvoiceLine.FindFirst() then
            if SalesInvoiceLine."GST Place of Supply" in [SalesInvoiceLine."GST Place of Supply"::"Bill-to Address",
                SalesInvoiceLine."GST Place of Supply"::"Location Address"]
            then begin
                if not (SalesInvoiceHeaderP."GST Customer Type" = SalesInvoiceHeaderP."GST Customer Type"::Export) then
                    if state.Get(SalesInvoiceHeaderP."GST Bill-to State Code") then
                        GSTTransHeader."Buyer State" := state."State Code (GST Reg. No.)";
                if Contact.Get(SalesInvoiceHeaderP."Bill-to Contact No.") then
                    GSTTransHeader."Buyer Phone No." := Contact."Phone No.";
            end else
                if SalesInvoiceLine."GST Place of Supply" = SalesInvoiceLine."GST Place of Supply"::"Ship-to Address" then begin
                    if not (SalesInvoiceHeaderP."GST Customer Type" = SalesInvoiceHeaderP."GST Customer Type"::Export) then
                        if state.Get(SalesInvoiceHeaderP."GST Ship-to State Code") then
                            GSTTransHeader."Buyer State" := state."State Code (GST Reg. No.)";
                    if ShipToAddress.Get(SalesInvoiceHeaderP."Sell-to Customer No.", SalesInvoiceHeaderP."Ship-to Code") then
                        GSTTransHeader."Buyer Phone No." := ShipToAddress."Phone No.";
                end;
        if GSTTransHeader."Buyer State" = '' then
            GSTTransHeader."Buyer State" := '96';
        GSTTransHeader."Buyer Zip Code" := SalesInvoiceHeaderP."Bill-to Post Code";
        if Location.Get(SalesInvoiceHeaderP."Location Code") then
            GSTTransHeader."Buyer Country" := Location."Country/Region Code";
        GSTTransHeader.Modify();
    end;

    local procedure ReadExportDetailsSalesInvoice(SalesInvoiceHeaderP: Record "Sales Invoice Header")
    var
        GSTTransLine: Record "ClearComp GST Trans. Line";
    begin
        if SalesInvoiceHeaderP."Invoice Type" = SalesInvoiceHeaderP."Invoice Type"::Export then begin
            case SalesInvoiceHeaderP."Ship-to GST Customer Type" of
                SalesInvoiceHeaderP."Ship-to GST Customer Type"::Export:
                    GSTTransHeader."Export Type" := GSTTransHeader."Export Type"::Regular;
                SalesInvoiceHeaderP."Ship-to GST Customer Type"::"Deemed Export":
                    GSTTransHeader."Export Type" := GSTTransHeader."Export Type"::Deemed;
            end;
            if SalesInvoiceHeaderP."Ship-to GST Customer Type" in [SalesInvoiceHeaderP."Ship-to GST Customer Type"::"SEZ Unit",
                SalesInvoiceHeaderP."Ship-to GST Customer Type"::"SEZ Development"]
            then begin
                GSTTransLine.SetRange("Transaction Type", GSTTransHeader."Transaction Type");
                GSTTransLine.SetRange("Document Type", GSTTransHeader."Document Type");
                GSTTransLine.SetRange("Document No.", GSTTransHeader."Document No.");
                GSTTransLine.SetRange("IGST Rate", 0);
                if GSTTransLine.FindFirst() then
                    GSTTransHeader."Export Type" := GSTTransHeader."Export Type"::"SEZ without IGST"
                else
                    GSTTransHeader."Export Type" := GSTTransHeader."Export Type"::"SEZ with IGST";
            end;
            if SalesInvoiceHeaderP."Bill Of Export No." > '' then
                GSTTransHeader."Shipping Bill No." := SalesInvoiceHeaderP."Bill Of Export No.";
            if SalesInvoiceHeaderP."Bill Of Export Date" <> 0D then
                GSTTransHeader."Shipping Bill Date" := SalesInvoiceHeaderP."Bill Of Export Date";
            if SalesInvoiceHeaderP."Exit Point" > '' then
                GSTTransHeader."Shipping Port Code" := SalesInvoiceHeaderP."Exit Point";
        end;
        GSTTransHeader.Modify();
    end;

    local procedure ReadECommerceDetailsSalesInvoice(SalesInvoiceHeaderP: Record "Sales Invoice Header")
    var
        Customer: Record Customer;
        State: Record State;
    begin
        if SalesInvoiceHeaderP."e-Commerce Customer" > '' then
            if Customer.Get(SalesInvoiceHeaderP."E-Commerce Customer") then begin
                GSTTransHeader."E-Commerce Name" := Customer.Name;
                GSTTransHeader."E-Commerce Address" := Customer.Address;
                GSTTransHeader."E-Commerce City" := Customer.City;
                GSTTransHeader."E-Commerce State" := Customer."State Code";
                GSTTransHeader."E-Commerce Country" := Customer."Country/Region Code";
                GSTTransHeader."E-Commerce Zip Code" := Customer."Post Code";
                GSTTransHeader."E-Commerce Phone No." := Customer."Phone No.";
                GSTTransHeader."E-Commerce GSTIN" := Customer."GST Registration No.";
            end;
        if SalesInvoiceHeaderP."E-Comm. Merchant Id" > '' then
            GSTTransHeader."E- Commerce Merchant ID" := SalesInvoiceHeaderP."E-Comm. Merchant Id";
        GSTTransHeader.Modify();
    end;

    local procedure GetGSTCompRate(var GSTTransLine: Record "ClearComp GST Trans. Line")
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::"Initial Entry");
        DetailedGSTLedgerEntry.SetRange("Document No.", GSTTransHeader."Document No.");
        if not GSTTransHeader."Is Advance" then
            DetailedGSTLedgerEntry.SetRange("Document Line No.", GSTTransLine."Line No.");

        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'CGST');
        if DetailedGSTLedgerEntry.FindSet() then begin
            GSTTransLine."CGST Rate" := DetailedGSTLedgerEntry."GST %";
            repeat
                GSTTransLine."CGST Value" += Abs(DetailedGSTLedgerEntry."GST Amount");
                if GSTTransHeader."Is Advance" then
                    GSTTransLine."Taxable Value" += Abs(DetailedGSTLedgerEntry."GST Base Amount");
            until DetailedGSTLedgerEntry.Next() = 0;
        end;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'SGST');
        if DetailedGSTLedgerEntry.FindSet() then begin
            GSTTransLine."SGST Rate" := DetailedGSTLedgerEntry."GST %";
            repeat
                GSTTransLine."SGST Value" += Abs(DetailedGSTLedgerEntry."GST Amount");
            until DetailedGSTLedgerEntry.Next() = 0;
        end;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'IGST');
        if DetailedGSTLedgerEntry.FindSet() then begin
            GSTTransLine."IGST Rate" := DetailedGSTLedgerEntry."GST %";
            repeat
                GSTTransLine."IGST Value" += Abs(DetailedGSTLedgerEntry."GST Amount");
                if GSTTransHeader."Is Advance" then
                    GSTTransLine."Taxable Value" += Abs(DetailedGSTLedgerEntry."GST Base Amount");
            until DetailedGSTLedgerEntry.Next() = 0;
        end;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'CESS');
        if DetailedGSTLedgerEntry.FindSet() then begin
            GSTTransLine."Cess Rate" := DetailedGSTLedgerEntry."GST %";
            repeat
                if (DetailedGSTLedgerEntry."GST %" > 0) then
                    GSTTransLine."Cess Value" += Abs(DetailedGSTLedgerEntry."GST Amount");
            until DetailedGSTLedgerEntry.Next() = 0;
        end;
    end;

    local procedure ProcessSalesCreditMemoData()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        RecRef: RecordRef;
    begin
        if SalesCrMemoHeader.Get(GSTTransHeader."Document No.") then begin
            ReadHeaderDetailsSalesCreditMemo(SalesCrMemoHeader);
            ReadLineDetailsSalesCreditMemo(SalesCrMemoHeader);
            ReadSellerDetails(SalesCrMemoHeader."Location Code", SalesCrMemoHeader."Location GST Reg. No.");
            ReadBuyerDetailsSalesCreditMemo(SalesCrMemoHeader);
        end;
    end;

    local procedure ReadHeaderDetailsSalesCreditMemo(SalesCrMemoHeaderP: Record "Sales Cr.Memo Header")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SalesCrMemoHeaderP);
        if SalesCrMemoHeaderP."Invoice Type" in [SalesCrMemoHeaderP."Invoice Type"::"Bill of Supply", SalesCrMemoHeaderP."Invoice Type"::"Non-GST"] then
            GSTTransHeader."Is Bill of Supply" := true;
        GSTTransHeader."External Document no." := SalesCrMemoHeaderP."External Document No.";
        GSTTransHeader.IRN := SalesCrMemoHeaderP."IRN Hash";
        GSTTransHeader."Due Date" := SalesCrMemoHeaderP."Due Date";
        //++Seaways
        if SalesCrMemoHeaderP.State = 'OT' then
            GSTTransHeader."Place of Supply" := '97'
        else
            //--Seaways
            GSTTransHeader."Place of Supply" := GetPlaceofSupply(RecRef);

        GSTTransHeader."Reverse Charge Applicable" := GetReverseChargeApplicable();
        GSTTransHeader."CDN Type" := GSTTransHeader."CDN Type"::CREDIT;
        GSTTransHeader."Original Invoice Type" := GSTTransHeader."Original Invoice Type"::SALE;
        GSTTransHeader."Note Num" := SalesCrMemoHeaderP."External Document No.";
        if Customer.Get(SalesCrMemoHeaderP."Sell-to Customer No.") then
            if Customer."GST Customer Type" = Customer."GST Customer Type"::Unregistered then
                GSTTransHeader."Customer Type" := GSTTransHeader."Customer Type"::UIN_REGISTERED;
        if SalesInvHeader.Get(SalesCrMemoHeaderP."Reference Invoice No.") then begin
            GSTTransHeader."Original Invoice No." := SalesInvHeader."No.";
            GSTTransHeader."Original Invoice Date" := SalesInvHeader."Posting Date";
        end;
        GSTTransHeader."Reference Doc No." := SalesCrMemoHeaderP."No.";
        GSTTransHeader."Original Inv. Classification" := GetInvoiceClassification(RecRef);
        GSTTransHeader.Modify();
    end;

    local procedure ReadLineDetailsSalesCreditMemo(SalesCrMemoHeaderP: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GSTTransLine: Record "ClearComp GST Trans. Line";
        HSNSAC: Record "HSN/SAC";
        TCSEntry: Record "TCS Entry";
        TotalGSTAmount: Decimal;
    begin
        GSTTransLine.SetRange("Document Type", GSTTransHeader."Document Type");
        GSTTransLine.SetRange("Document No.", GSTTransHeader."Document No.");
        GSTTransLine.SetRange("Transaction Type", GSTTransLine."Transaction Type"::SALE);
        if GSTTransLine.FindSet() then
            GSTTransLine.DeleteAll();
        Clear(GSTTransLine);
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeaderP."No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        SalesCrMemoLine.SetRange("System-Created Entry", false);
        if SalesCrMemoLine.FindSet() then
            repeat
                Clear(GSTTransLine);
                GSTTransLine."Transaction Type" := GSTTransHeader."Transaction Type";
                GSTTransLine."Document Type" := GSTTransHeader."Document Type";
                GSTTransLine."Document No." := GSTTransHeader."Document No.";
                GSTTransLine."Line No." := SalesCrMemoLine."Line No.";
                GSTTransLine.Description := SalesCrMemoLine.Description;
                if SalesCrMemoLine."Description 2" > '' then
                    GSTTransLine.Description += ' ' + SalesCrMemoLine."Description 2";
                GSTTransLine.Quantity := SalesCrMemoLine.Quantity;
                GSTTransLine."Unit Price" := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), SalesCrMemoHeaderP."Currency Code", SalesCrMemoLine."Unit Price",
                                                SalesCrMemoHeaderP."Currency Factor"), 0.01, '=');

                GSTTransLine.UOM := CopyStr(SalesCrMemoLine."Unit of Measure", 1, 3);

                GSTTransLine."Taxable Value" := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), SalesCrMemoHeaderP."Currency Code", SalesCrMemoLine.Amount,
                                                    SalesCrMemoHeaderP."Currency Factor"), 0.01, '=');

                GetGSTCompRate(GSTTransLine);

                TCSEntry.SetRange("Document No.", GSTTransHeader."Document No.");
                if TCSEntry.FindFirst() then
                    ;
                TotalGSTAmount := GSTTransLine."CGST Value" + GSTTransLine."SGST Value" + GSTTransLine."IGST Value";
                GSTTransLine."Total Value" := GSTTransLine."Taxable Value" +
                                              Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), SalesCrMemoHeaderP."Currency Code", TotalGSTAmount,
                                                    SalesCrMemoHeaderP."Currency Factor"), 0.01, '=') +
                                              Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), SalesCrMemoHeaderP."Currency Code",
                                                    TCSEntry."Total TCS Including SHE CESS", SalesCrMemoHeaderP."Currency Factor"), 0.01, '=');
                GSTTransLine."GST Code" := SalesCrMemoLine."HSN/SAC Code";
                if HSNSAC.Get(SalesCrMemoLine."GST Group Code", SalesCrMemoLine."HSN/SAC Code") then
                    if HSNSAC.Type = HSNSAC.Type::HSN then
                        GSTTransLine."GST Type" := GSTTransLine."GST Type"::GOODS
                    else
                        GSTTransLine."GST Type" := GSTTransLine."GST Type"::SERVICES;
                if SalesCrMemoLine."Invoice Type" = SalesCrMemoLine."Invoice Type"::"Non-GST" then
                    GSTTransLine."Zero Tax Category" := GSTTransLine."Zero Tax Category"::"Non GST Supply";
                if SalesCrMemoLine."Invoice Type" = SalesCrMemoLine."Invoice Type"::"Bill of Supply" then
                    GSTTransLine."Zero Tax Category" := GSTTransLine."Zero Tax Category"::Exempted;
                if (GSTTransLine."CGST Rate" = 0) and (GSTTransLine."SGST Rate" = 0) and (GSTTransLine."IGST Rate" = 0) then
                    GSTTransLine."Zero Tax Category" := GSTTransLine."Zero Tax Category"::"Nil Rated";

                if TCSEntry."Total TCS Including SHE CESS" > 0 then begin
                    GSTTransHeader."TCS Applicable" := true;
                    GSTTransHeader.Modify();
                end;
                GSTTransLine.Discount := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), SalesCrMemoHeaderP."Currency Code",
                                            SalesCrMemoLine."Line Discount Amount", SalesCrMemoHeaderP."Currency Factor"), 0.01, '=');
                GSTTransLine."Line No." := GSTTransLine.GetNextFreeLine(GSTTransLine."Transaction Type", GSTTransLine."Document Type", GSTTransLine."Document No.");
                GSTTransLine.Insert();
            until SalesCrMemoLine.Next() = 0;
        // Zero tax category - supply from composition dealer , UIN holder to be added.
    end;

    local procedure ReadBuyerDetailsSalesCreditMemo(SalesCrMemoHeaderP: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        Customer: Record Customer;
        Contact: Record Contact;
        State: Record State;
        ShipToAddress: Record "Ship-to Address";
    begin
        GSTTransHeader."Buyer Name" := SalesCrMemoHeaderP."Bill-to Name";
        if SalesCrMemoHeaderP."Bill-to Name 2" > '' then
            GSTTransHeader."Buyer Name" += ' ' + SalesCrMemoHeaderP."Bill-to Name 2";
        if SalesCrMemoHeaderP."Ship-to Code" > '' then
            if ShipToAddress.Get(SalesCrMemoHeaderP."Bill-to Customer No.", SalesCrMemoHeaderP."Ship-to Code") then
                GSTTransHeader."Buyer GSTIN" := ShipToAddress."GST Registration No.";
        if GSTTransHeader."Buyer GSTIN" = '' then
            if Customer.Get(SalesCrMemoHeaderP."Bill-to Customer No.") then
                GSTTransHeader."Buyer GSTIN" := Customer."GST Registration No.";
        GSTTransHeader."Buyer Address" := SalesCrMemoHeaderP."Bill-to Address";
        if SalesCrMemoHeaderP."Bill-to Address 2" > '' then
            GSTTransHeader."Buyer Address" += ' ' + SalesCrMemoHeaderP."Bill-to Address 2";
        GSTTransHeader."Buyer City" := SalesCrMemoHeaderP."Bill-to City";

        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeaderP."No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        if SalesCrMemoLine.FindFirst() then
            if SalesCrMemoLine."GST Place of Supply" = SalesCrMemoLine."GST Place of Supply"::"Bill-to Address" then begin
                if not (SalesCrMemoHeaderP."GST Customer Type" = SalesCrMemoHeaderP."GST Customer Type"::Export) then
                    if State.Get(SalesCrMemoHeaderP."GST Bill-to State Code") then
                        GSTTransHeader."Buyer State" := State."State Code (GST Reg. No.)";
                if Contact.Get(SalesCrMemoHeaderP."Bill-to Contact No.") then
                    GSTTransHeader."Buyer Phone No." := Contact."Phone No.";
            end else
                if SalesCrMemoLine."GST Place of Supply" = SalesCrMemoLine."GST Place of Supply"::"Ship-to Address" then begin
                    if not (SalesCrMemoHeaderP."GST Customer Type" = SalesCrMemoHeaderP."GST Customer Type"::Export) then
                        if State.Get(SalesCrMemoHeaderP."GST Ship-to State Code") then
                            GSTTransHeader."Buyer State" := State."State Code (GST Reg. No.)";
                    if ShipToAddress.GET(SalesCrMemoHeaderP."Sell-to Customer No.", SalesCrMemoHeaderP."Ship-to Code") then
                        GSTTransHeader."Buyer Phone No." := ShipToAddress."Phone No.";
                end else begin
                    if State.Get(SalesCrMemoHeaderP."Location Code") then
                        GSTTransHeader."Buyer State" := State."State Code (GST Reg. No.)";
                end;
        GSTTransHeader."Buyer Zip Code" := SalesCrMemoHeaderP."Bill-to Post Code";
        GSTTransHeader.Modify();
    end;

    local procedure ProcessAdvanceData()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if BankAccountLedgerEntry.Get(GSTTransHeader."Document No.") then begin
            ReadHeaderDetailsAdvance(BankAccountLedgerEntry);
            ReadLineDetailsAdvance(BankAccountLedgerEntry);
            ReadSellerDetailsAdvance(BankAccountLedgerEntry);
            ReadBuyerDetailsAdvance(BankAccountLedgerEntry);
        end;
    end;

    local procedure ReadHeaderDetailsAdvance(BankAccountLedgerP: Record "Bank Account Ledger Entry")
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(BankAccountLedgerP);
        GSTTransHeader."Reverse Charge Applicable" := GetReverseChargeApplicable();
        GSTTransHeader."Place of Supply" := GetPlaceofSupply(RecRef);
        GSTTransHeader.Modify();
    end;

    local procedure ReadLineDetailsAdvance(BankAccountLedgerP: Record "Bank Account Ledger Entry")
    var
        GSTTransLine: Record "ClearComp GST Trans. Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        GSTTransLine.SetRange("Transaction Type", GSTTransHeader."Transaction Type");
        GSTTransLine.SetRange("Document Type", GSTTransHeader."Document Type");
        GSTTransLine.SetRange("Document No.", GSTTransHeader."Document No.");
        if GSTTransLine.FindFirst() then
            GSTTransLine.DeleteAll();
        Clear(GSTTransLine);
        GSTTransLine."Transaction Type" := GSTTransHeader."Transaction Type";
        GSTTransLine."Document Type" := GSTTransHeader."Document Type";
        GSTTransLine."Document No." := GSTTransHeader."Document No.";
        GSTTransLine."Line No." := GSTTransLine.GetNextFreeLine(GSTTransLine."Transaction Type", GSTTransLine."Document Type", GSTTransLine."Document No.");
        GSTTransLine.Description := BankAccountLedgerP.Description;
        GSTTransLine.Quantity := 1;
        GSTTransLine."Total Value" := ABS(BankAccountLedgerP.Amount);
        GSTTransLine.UOM := 'OTH';
        GetGSTCompRate(GSTTransLine);
        GSTTransLine."Unit Price" := GSTTransLine."Taxable Value";
        GSTTransLine.Insert();
    end;

    local procedure ReadSellerDetailsAdvance(BankAccountLedgerP: Record "Bank Account Ledger Entry")
    var
        Location: Record Location;
        State: Record State;
        Vendor: Record Vendor;
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        case BankAccountLedgerP."Bal. Account Type" of
            BankAccountLedgerP."Bal. Account Type"::Customer:
                begin
                    DetailedGSTLedgerEntry.SetRange("Document No.", Format(BankAccountLedgerP."Entry No."));
                    DetailedGSTLedgerEntry.SetFilter("GST Component Code", '%1|%2|%3', 'CGST', 'SGST', 'IGST');
                    if DetailedGSTLedgerEntry.FindFirst() then
                        if Location.Get(DetailedGSTLedgerEntry."Location Code") then begin
                            GSTTransHeader."Seller Name" := Location.Name;
                            if Location."Name 2" > '' then
                                GSTTransHeader."Seller Name" += ' ' + Location."Name 2";
                            GSTTransHeader."Seller GSTIN" := Location."GST Registration No.";
                            GSTTransHeader."Seller Address" := Location.Address;
                            if Location."Address 2" > '' then
                                GSTTransHeader."Seller Address" += ' ' + Location."Address 2";
                            GSTTransHeader."Seller City" := Location.City;
                            if State.Get(Location."State Code") then
                                GSTTransHeader."Seller State" := State."State Code (GST Reg. No.)";
                            GSTTransHeader."Seller Zip Code" := Location."Post Code";
                            GSTTransHeader."Seller Phone No." := Location."Phone No.";
                            GSTTransHeader."Seller Country" := Location."Country/Region Code";
                        end;
                end;
            BankAccountLedgerP."Bal. Account Type"::Vendor:
                begin
                    DetailedGSTLedgerEntry.SetRange("Document No.", Format(BankAccountLedgerP."Entry No."));
                    DetailedGSTLedgerEntry.SetFilter("GST Component Code", '%1|%2|%3', 'CGST', 'SGST', 'IGST');
                    if DetailedGSTLedgerEntry.FindFirst() then
                        if Location.Get(DetailedGSTLedgerEntry."Location Code") then
                            ;
                    if State.Get(Location."State Code") then;
                    if Vendor.Get(BankAccountLedgerP."Bal. Account No.") then begin
                        GSTTransHeader."Seller Name" := Vendor.Name;
                        if Vendor."Name 2" > '' then
                            GSTTransHeader."Seller Name" += ' ' + Vendor."Name 2";
                        GSTTransHeader."Seller Address" := Vendor.Address;
                        if Vendor."Address 2" > '' then
                            GSTTransHeader."Seller Address" += ' ' + Vendor."Address 2";
                        GSTTransHeader."Seller City" := Vendor.City;
                        GSTTransHeader."Seller Phone No." := Vendor."Phone No.";
                        GSTTransHeader."Seller Country" := Vendor."Country/Region Code";
                        if (Vendor."State Code" = 'FOR') or (Vendor."State Code" = 'SEZ-GJ') then begin
                            GSTTransHeader."Seller GSTIN" := 'URP';
                            GSTTransHeader."Seller Zip Code" := '999999';
                            GSTTransHeader."Seller State" := 'OTHERTERRITOR';
                        end else begin
                            if Vendor."GST Vendor Type" = Vendor."GST Vendor Type"::Unregistered then
                                GSTTransHeader."Seller GSTIN" := 'URP'
                            else
                                GSTTransHeader."Seller GSTIN" := Vendor."GST Registration No.";
                            if State.Get(Vendor."State Code") then
                                GSTTransHeader."Seller State" := State."State Code (GST Reg. No.)";
                            GSTTransHeader."Seller Zip Code" := Vendor."Post Code"
                        end;
                    end;
                end;
        end;
        GSTTransHeader.Modify();
    end;

    local procedure ReadBuyerDetailsAdvance(BankAccountLedgerP: Record "Bank Account Ledger Entry")
    var
        Customer: Record Customer;
        Location: Record Location;
        State: Record State;
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        case BankAccountLedgerP."Bal. Account Type" of
            BankAccountLedgerP."Bal. Account Type"::Customer:
                begin
                    if Customer.Get(BankAccountLedgerP."Bal. Account No.") then begin
                        GSTTransHeader."Buyer Name" := Customer.Name;
                        if Customer."Name 2" > '' then
                            GSTTransHeader."Buyer Name" += ' ' + Customer."Name 2";
                        GSTTransHeader."Buyer GSTIN" := Customer."GST Registration No.";
                        GSTTransHeader."Buyer Address" := Customer.Address;
                        if Customer."Address 2" > '' then
                            GSTTransHeader."Buyer Address" += ' ' + Customer."Address 2";
                        GSTTransHeader."Buyer City" := Customer.City;
                        if State.Get(Customer."State Code") then
                            GSTTransHeader."Buyer State" := State."State Code (GST Reg. No.)";
                        GSTTransHeader."Buyer Zip Code" := Customer."Post Code";
                        GSTTransHeader."Buyer Phone No." := Customer."Phone No.";
                        GSTTransHeader."Buyer Country" := Customer."Country/Region Code";
                    end;
                end;
            BankAccountLedgerP."Bal. Account Type"::Vendor:
                begin
                    DetailedGSTLedgerEntry.SetRange("Document No.", Format(BankAccountLedgerP."Entry No."));
                    DetailedGSTLedgerEntry.SetFilter("GST Component Code", '%1|%2|%3', 'CGST', 'SGST', 'IGST');
                    if DetailedGSTLedgerEntry.FindFirst() then
                        if Location.Get(DetailedGSTLedgerEntry."Location Code") then begin
                            GSTTransHeader."Buyer Name" := Location.Name;
                            if Location."Name 2" > '' then
                                GSTTransHeader."Buyer Name" += ' ' + Location."Name 2";
                            GSTTransHeader."Buyer GSTIN" := Location."GST Registration No.";
                            GSTTransHeader."Buyer Address" := Location.Address;
                            if Location."Address 2" > '' then
                                GSTTransHeader."Buyer Address" += ' ' + Location."Address 2";
                            GSTTransHeader."Buyer City" := Location.City;
                            if State.get(Location."State Code") then
                                GSTTransHeader."Buyer State" := State."State Code (GST Reg. No.)";
                            GSTTransHeader."Buyer Zip Code" := Location."Post Code";
                            GSTTransHeader."Buyer Phone No." := Location."Phone No.";
                            GSTTransHeader."Buyer Country" := Location."Country/Region Code";
                        end
                end;
        end;
        GSTTransHeader.Modify();
    end;

    local procedure ProcessPurchaseInvoiceData()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if PurchInvHeader.Get(GSTTransHeader."Document No.") then begin
            ReadHeaderDetailsPurchaseInvoice(PurchInvHeader);
            ReadLineDetailsPurchaseInvoice(PurchInvHeader);
            ReadSellerDetailsPurchaseInvoice(PurchInvHeader);
            ReadBuyerDetailsPurchaseInvoice(PurchInvHeader);
            if not GSTTransHeader."Is Bill of Supply" then
                ReadImportDetailsPurchaseInvoice(PurchInvHeader);
        end;
    end;

    local procedure ReadHeaderDetailsPurchaseInvoice(PurchInvHeaderP: Record "Purch. Inv. Header")
    var
        Vendor: Record Vendor;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(PurchInvHeaderP);
        if PurchInvHeaderP."Invoice Type" in [PurchInvHeaderP."Invoice Type"::"Non-GST"] then
            GSTTransHeader."Is Bill of Supply" := true;
        GSTTransHeader."External Document no." := PurchInvHeaderP."Vendor Invoice No.";
        GSTTransHeader.IRN := 'No IRN';
        GSTTransHeader."Due Date" := PurchInvHeaderP."Due Date";
        GSTTransHeader."Place of Supply" := GetPlaceofSupply(RecRef);
        GSTTransHeader."Reverse Charge Applicable" := GetReverseChargeApplicable();
        if Vendor.Get(PurchInvHeaderP."Buy-from Vendor No.") then
            if Vendor."GST Vendor Type" = Vendor."GST Vendor Type"::Composite then
                GSTTransHeader."Supplier Type" := GSTTransHeader."Supplier Type"::COMPOSITION;
        GSTTransHeader."Reference Doc No." := PurchInvHeaderP."No.";
        GSTTransHeader."Date of Purchase" := PurchInvHeaderP."Order Date";
        GSTTransHeader."Original Inv. Classification" := GetInvoiceClassification(RecRef);
        if PurchInvHeaderP."Prepayment Order No." > '' then begin
            GSTTransHeader."Is Advance" := TRUE;
            GSTTransHeader."Original Invoice No." := PurchInvHeaderP."Prepayment Order No.";
            GSTTransHeader."Original Invoice Type" := GSTTransHeader."Original Invoice Type"::PURCHASE;
        end;
        GSTTransHeader.Modify();
    end;

    local procedure ReadLineDetailsPurchaseInvoice(PurchInvHeaderP: Record "Purch. Inv. Header")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        GSTTransLine: Record "ClearComp GST Trans. Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        HSNSAC: Record "HSN/SAC";
        TDSEntry: Record "TDS Entry";
        TotalGSTAmount: Decimal;
    begin
        GSTTransLine.SetRange("Document Type", GSTTransHeader."Document Type");
        GSTTransLine.SetRange("Document No.", GSTTransHeader."Document No.");
        GSTTransLine.SetRange("Transaction Type", GSTTransLine."Transaction Type"::PURCHASE);
        if GSTTransLine.FindSet() then
            GSTTransLine.DeleteAll();
        Clear(GSTTransLine);
        PurchInvLine.SetRange("Document No.", PurchInvHeaderP."No.");
        PurchInvLine.SetFilter("No.", '<>%1', '');
        PurchInvLine.SetFilter(Quantity, '<>%1', 0);
        PurchInvLine.SetRange("System-Created Entry", false);
        if PurchInvLine.FindSet() then
            repeat
                Clear(GSTTransLine);
                GSTTransLine."Transaction Type" := GSTTransHeader."Transaction Type";
                GSTTransLine."Document Type" := GSTTransHeader."Document Type";
                GSTTransLine."Document No." := GSTTransHeader."Document No.";
                GSTTransLine."Line No." := PurchInvLine."Line No.";
                GSTTransLine.Description := PurchInvLine.Description;
                IF PurchInvLine."Description 2" <> '' THEN
                    GSTTransLine.Description += ' ' + PurchInvLine."Description 2";
                GSTTransLine.Quantity := PurchInvLine.Quantity;
                GSTTransLine."Unit Price" := PurchInvLine."Unit Price (LCY)";
                GSTTransLine.UOM := CopyStr(PurchInvLine."Unit of Measure Code", 1, 3);

                GSTTransLine."Taxable Value" := ROUND(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WORKDATE, PurchInvHeaderP."Currency Code",
                                     PurchInvLine.Amount, PurchInvHeaderP."Currency Factor"), 0.01, '=');

                if not GSTTransHeader."Is Bill of Supply" then
                    GetGSTCompRate(GSTTransLine);

                TDSEntry.SetRange("Document No.", GSTTransHeader."Document No.");
                if TDSEntry.FindFirst() then;
                TotalGSTAmount := GSTTransLine."CGST Value" + GSTTransLine."SGST Value" + GSTTransLine."IGST Value";
                GSTTransLine."Total Value" := GSTTransLine."Taxable Value" +
                                              Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WORKDATE, PurchInvHeaderP."Currency Code", TotalGSTAmount,
                                                PurchInvHeaderP."Currency Factor"), 0.01, '=') +
                                              Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WORKDATE, PurchInvHeaderP."Currency Code",
                                                TDSEntry."Total TDS Including SHE CESS", PurchInvHeaderP."Currency Factor"), 0.01, '=');

                GSTTransLine."GST Code" := PurchInvLine."HSN/SAC Code";
                if HSNSAC.Get(PurchInvLine."GST Group Code", PurchInvLine."HSN/SAC Code") then
                    if HSNSAC.Type = HSNSAC.Type::HSN then
                        GSTTransLine."GST Type" := GSTTransLine."GST Type"::GOODS
                    else
                        GSTTransLine."GST Type" := GSTTransLine."GST Type"::SERVICES;

                if PurchInvHeaderP."Invoice Type" = PurchInvHeaderP."Invoice Type"::"Non-GST" then
                    GSTTransLine."Zero Tax Category" := GSTTransLine."Zero Tax Category"::"Non GST Supply";
                if (GSTTransLine."CGST Rate" = 0) AND (GSTTransLine."SGST Rate" = 0) AND (GSTTransLine."IGST Rate" = 0) then
                    GSTTransLine."Zero Tax Category" := GSTTransLine."Zero Tax Category"::"Nil Rated";

                if TDSEntry."Total TDS Including SHE CESS" > 0 then begin
                    GSTTransHeader."TDS Applicable" := TRUE;
                    GSTTransHeader.Modify();
                END;

                GSTTransLine.Discount := ROUND(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WORKDATE, PurchInvHeaderP."Currency Code",
                              PurchInvLine."Line Discount Amount", PurchInvHeaderP."Currency Factor"), 0.01, '=');

                GSTTransLine."Line No." := GSTTransLine.GetNextFreeLine(GSTTransLine."Transaction Type", GSTTransLine."Document Type", GSTTransLine."Document No.");
                GSTTransLine.Insert();
            until PurchInvLine.Next() = 0;
        // Zero tax category more option's to be included.
    end;

    local procedure ReadSellerDetailsPurchaseInvoice(PurchInvHeaderP: Record "Purch. Inv. Header")
    var
        OrderAddress: Record "Order Address";
        Vendor: Record Vendor;
        State: Record State;
        Location: Record Location;
    begin
        if (PurchInvHeaderP."Order Address Code" > '') and (OrderAddress.GET(PurchInvHeaderP."Buy-from Vendor No.", PurchInvHeaderP."Order Address Code")) then begin
            GSTTransHeader."Seller Name" := OrderAddress.Name;
            if OrderAddress."Name 2" > '' then
                GSTTransHeader."Seller Name" += ' ' + OrderAddress."Name 2";
            GSTTransHeader."Seller GSTIN" := OrderAddress."GST Registration No.";
            GSTTransHeader."Seller Address" := OrderAddress.Address;
            if OrderAddress."Address 2" > '' then
                GSTTransHeader."Seller Address" += ' ' + OrderAddress."Address 2";
            GSTTransHeader."Seller City" := OrderAddress.City;
            if State.GET(OrderAddress.State) then
                GSTTransHeader."Seller State" := State."State Code (GST Reg. No.)";
            GSTTransHeader."Seller Zip Code" := OrderAddress."Post Code";
            GSTTransHeader."Seller Phone No." := OrderAddress."Phone No.";
        end else begin
            if Vendor.Get(PurchInvHeaderP."Buy-from Vendor No.") then
                ;
            GSTTransHeader."Seller Name" := PurchInvHeaderP."Buy-from Vendor Name";
            if PurchInvHeaderP."Buy-from Vendor Name 2" > '' then
                GSTTransHeader."Seller Name" += ' ' + PurchInvHeaderP."Buy-from Vendor Name 2";
            if PurchInvHeaderP."Vendor GST Reg. No." <> '' then
                GSTTransHeader."Seller GSTIN" := PurchInvHeaderP."Vendor GST Reg. No."
            else
                GSTTransHeader."Seller GSTIN" := Vendor."GST Registration No.";
            GSTTransHeader."Seller Address" := PurchInvHeaderP."Buy-from Address";
            IF PurchInvHeaderP."Buy-from Address 2" <> '' THEN
                GSTTransHeader."Seller Address" += ' ' + PurchInvHeaderP."Buy-from Address 2";
            GSTTransHeader."Seller City" := PurchInvHeaderP."Pay-to City";
            GSTTransHeader."Seller Zip Code" := PurchInvHeaderP."Buy-from Post Code";
            if state.Get(PurchInvHeaderP."GST Order Address State") then
                GSTTransHeader."Seller State" := State."State Code (GST Reg. No.)"
            else
                if State.Get(Vendor."State Code") THEN
                    GSTTransHeader."Seller State" := State."State Code (GST Reg. No.)";
            GSTTransHeader."Seller Phone No." := Vendor."Phone No.";
        end;
        GSTTransHeader.Modify();
    end;

    local procedure ReadBuyerDetailsPurchaseInvoice(PurchInvHeaderP: Record "Purch. Inv. Header")
    var
        State: Record State;
        Location: Record Location;
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        GSTTransHeader."Buyer Name" := CompanyInformation.Name;
        if CompanyInformation."Name 2" > '' then
            GSTTransHeader."Buyer Name" += CompanyInformation."Name 2";
        if Location.Get(PurchInvHeaderP."Location Code") then begin
            GSTTransHeader."Buyer GSTIN" := Location."GST Registration No.";
            GSTTransHeader."Buyer Address" := Location.Address;
            if Location."Address 2" > '' then
                GSTTransHeader."Buyer Address" += Location."Address 2";
            GSTTransHeader."Buyer City" := Location.City;
            if State.Get(Location."State Code") then
                GSTTransHeader."Buyer State" := State."State Code (GST Reg. No.)";
            GSTTransHeader."Buyer Zip Code" := Location."Post Code";
            GSTTransHeader."Buyer Phone No." := Location."Phone No.";
            GSTTransHeader."Seller/Buyer Taxable entity" := Location."Taxable Entity";
        end;
        GSTTransHeader.Modify();
    end;

    local procedure ReadImportDetailsPurchaseInvoice(PurchInvHeaderP: Record "Purch. Inv. Header")
    var
        GSTTransLine: Record "ClearComp GST Trans. Line";
    begin
        GSTTransHeader."Bill of Entry" := PurchInvHeaderP."Bill of Entry No.";
        GSTTransHeader."Bill of Entry Value" := PurchInvHeaderP."Bill of Entry Value";
        GSTTransHeader."Bill of Entry Date" := PurchInvHeaderP."Bill of Entry Date";
        GSTTransLine.SETRANGE("Transaction Type", GSTTransHeader."Transaction Type");
        GSTTransLine.SETRANGE("Document Type", GSTTransHeader."Document Type");
        GSTTransLine.SETRANGE("Document No.", GSTTransHeader."Document No.");
        if GSTTransLine.FindLast() then begin
            case PurchInvHeaderP."GST Vendor Type" of
                PurchInvHeaderP."GST Vendor Type"::Import:
                    begin
                        if GSTTransLine."GST Type" = GSTTransLine."GST Type"::GOODS then
                            GSTTransHeader."Import Invoice Type" := GSTTransHeader."Import Invoice Type"::Goods
                        else
                            GSTTransHeader."Import Invoice Type" := GSTTransHeader."Import Invoice Type"::Services;
                    end;

                PurchInvHeaderP."GST Vendor Type"::SEZ:
                    begin
                        if GSTTransLine."GST Type" = GSTTransLine."GST Type"::GOODS then
                            GSTTransHeader."Import Invoice Type" := GSTTransHeader."Import Invoice Type"::"Goods from SEZ"
                        else
                            GSTTransHeader."Import Invoice Type" := GSTTransHeader."Import Invoice Type"::"Services From SEZ";
                    end;
            end;
            GSTTransHeader."Import Port Code" := PurchInvHeaderP."Entry Point";
            GSTTransHeader.Modify();
        end;
    end;

    local procedure ProcessPurchaseCreditMemoData()
    var
        RecRef: RecordRef;
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        if PurchCrMemoHeader.Get(GSTTransHeader."Document No.") then begin
            ReadHeaderDetailsPurchaseCreditMemo(PurchCrMemoHeader);
            ReadLineDetailsPurchaseCreditMemo(PurchCrMemoHeader);
            ReadSellerDetailsPurchaseCreditMemo(PurchCrMemoHeader);
            ReadBuyerDetailsPurchaseCreditMemo(PurchCrMemoHeader);
        end;
    end;

    local procedure ReadHeaderDetailsPurchaseCreditMemo(PurchCrMemoHeaderP: Record "Purch. Cr. Memo Hdr.")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        Vendor: Record Vendor;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(PurchCrMemoHeaderP);
        if PurchCrMemoHeaderP."Invoice Type" in [PurchCrMemoHeaderP."Invoice Type"::"Non-GST"] then
            GSTTransHeader."Is Bill of Supply" := true;
        GSTTransHeader."External Document no." := PurchCrMemoHeaderP."No.";
        GSTTransHeader.IRN := 'No IRN';
        GSTTransHeader."Due Date" := PurchCrMemoHeaderP."Due Date";
        GSTTransHeader."Place of Supply" := GetPlaceofSupply(RecRef);
        GSTTransHeader."Reverse Charge Applicable" := GetReverseChargeApplicable();
        GSTTransHeader."CDN Type" := GSTTransHeader."CDN Type"::DEBIT;
        GSTTransHeader."Note Num" := PurchCrMemoHeaderP."Vendor Cr. Memo No.";
        GSTTransHeader."Original Invoice Type" := GSTTransHeader."Original Invoice Type"::PURCHASE;
        if PurchCrMemoHeaderP."Prepayment Order No." > '' then begin
            GSTTransHeader."Original Invoice No." := PurchCrMemoHeaderP."Prepayment Order No.";
            GSTTransHeader."Is Advance" := TRUE;
        end else begin
            if PurchInvHeader.Get(PurchCrMemoHeaderP."Reference Invoice No.") then begin
                GSTTransHeader."Original Invoice No." := PurchInvHeader."Vendor Invoice No.";
                GSTTransHeader."Original Invoice Date" := PurchInvHeader."Posting Date";
            end;
            if Vendor.Get(PurchCrMemoHeaderP."Buy-from Vendor No.") then
                if Vendor."GST Vendor Type" = Vendor."GST Vendor Type"::Composite then
                    GSTTransHeader."Supplier Type" := GSTTransHeader."Supplier Type"::COMPOSITION;
        end;
        GSTTransHeader."Reference Doc No." := PurchCrMemoHeaderP."Vendor Cr. Memo No.";
        GSTTransHeader."Date of Purchase" := PurchInvHeader."Order Date";
        GSTTransHeader."Original Inv. Classification" := GetInvoiceClassification(RecRef);
        GSTTransHeader.Modify();
        // Original invoice gstin - not added.
    end;

    local procedure ReadLineDetailsPurchaseCreditMemo(PurchCrMemoHeaderP: Record "Purch. Cr. Memo Hdr.")
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        GSTTransLine: record "ClearComp GST Trans. Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        HSNSAC: Record "HSN/SAC";
        TotalGSTAmount: Decimal;
        TDSEntry: Record "TDS Entry";
    begin
        GSTTransLine.SetRange("Document Type", GSTTransHeader."Document Type");
        GSTTransLine.SetRange("Document No.", GSTTransHeader."Document No.");
        GSTTransLine.SetRange("Transaction Type", GSTTransLine."Transaction Type"::PURCHASE);
        if GSTTransLine.FindSet() then
            GSTTransLine.DeleteAll();
        Clear(GSTTransLine);

        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHeaderP."No.");
        PurchCrMemoLine.SetFilter(Type, '<>%1', PurchCrMemoLine.Type::" ");
        PurchCrMemoLine.SetRange("System-Created Entry", false);
        if PurchCrMemoLine.FindSet() then
            repeat
                Clear(GSTTransLine);
                GSTTransLine."Transaction Type" := GSTTransHeader."Transaction Type";
                GSTTransLine."Document Type" := GSTTransHeader."Document Type";
                GSTTransLine."Document No." := GSTTransHeader."Document No.";
                GSTTransLine."Line No." := PurchCrMemoLine."Line No.";
                GSTTransLine.Description := PurchCrMemoLine.Description;
                if PurchCrMemoLine."Description 2" > '' then
                    GSTTransLine.Description += ' ' + PurchCrMemoLine."Description 2";
                GSTTransLine.Quantity := PurchCrMemoLine.Quantity;

                GSTTransLine."Unit Price" := ROUND(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WORKDATE, PurchCrMemoHeaderP."Currency Code",
                                  PurchCrMemoLine."Unit Price (LCY)", PurchCrMemoHeaderP."Currency Factor"), 0.01, '=');

                GSTTransLine.UOM := COPYSTR(PurchCrMemoLine."Unit of Measure Code", 1, 3);

                GSTTransLine."Taxable Value" := ROUND(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WORKDATE, PurchCrMemoHeaderP."Currency Code",
                                                     PurchCrMemoLine.Amount, PurchCrMemoHeaderP."Currency Factor"), 0.01, '=');
                GetGSTCompRate(GSTTransLine);

                TotalGSTAmount := GSTTransLine."CGST Value" + GSTTransLine."SGST Value" + GSTTransLine."IGST Value";
                GSTTransLine."Total Value" := GSTTransLine."Taxable Value" +
                                              ROUND(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WORKDATE, PurchCrMemoHeaderP."Currency Code", TotalGSTAmount,
                                                    PurchCrMemoHeaderP."Currency Factor"), 0.01, '=');

                GSTTransLine."GST Code" := PurchCrMemoLine."HSN/SAC Code";
                if HSNSAC.Get(PurchCrMemoLine."GST Group Code", PurchCrMemoLine."HSN/SAC Code") then
                    if HSNSAC.Type = HSNSAC.Type::HSN then
                        GSTTransLine."GST Type" := GSTTransLine."GST Type"::GOODS
                    ELSE
                        GSTTransLine."GST Type" := GSTTransLine."GST Type"::SERVICES;
                if PurchCrMemoHeaderP."Invoice Type" = PurchCrMemoHeaderP."Invoice Type"::"Non-GST" then
                    GSTTransLine."Zero Tax Category" := GSTTransLine."Zero Tax Category"::"Non GST Supply";
                if (GSTTransLine."CGST Rate" = 0) AND (GSTTransLine."SGST Rate" = 0) AND (GSTTransLine."IGST Rate" = 0) then
                    GSTTransLine."Zero Tax Category" := GSTTransLine."Zero Tax Category"::"Nil Rated";

                TDSEntry.SetRange("Document No.", GSTTransHeader."Document No.");
                if TDSEntry.FindFirst() and (TDSEntry."Total TDS Including SHE CESS" > 0) then begin
                    GSTTransHeader."TDS Applicable" := TRUE;
                    GSTTransHeader.Modify();
                end;

                GSTTransLine.Discount := ROUND(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WORKDATE, PurchCrMemoHeaderP."Currency Code",
                              PurchCrMemoLine."Line Discount Amount", PurchCrMemoHeaderP."Currency Factor"), 0.01, '=');

                GSTTransLine."Line No." := GSTTransLine.GetNextFreeLine(GSTTransLine."Transaction Type", GSTTransLine."Document Type", GSTTransLine."Document No.");
                GSTTransLine.Insert();
            until PurchCrMemoLine.Next() = 0;
    end;

    local procedure ReadSellerDetailsPurchaseCreditMemo(PurchCrMemoHeaderP: Record "Purch. Cr. Memo Hdr.")
    var
        OrderAddress: Record "Order Address";
        State: Record State;
        Vendor: Record Vendor;
    begin
        if (PurchCrMemoHeaderP."Order Address Code" > '') and (OrderAddress.Get(PurchCrMemoHeaderP."Buy-from Vendor No.", PurchCrMemoHeaderP."Order Address Code")) then begin
            GSTTransHeader."Seller Name" := OrderAddress.Name;
            if OrderAddress."Name 2" > '' then
                GSTTransHeader."Seller Name" += ' ' + OrderAddress."Name 2"; // Change in NAV16
            GSTTransHeader."Seller GSTIN" := OrderAddress."GST Registration No.";
            GSTTransHeader."Seller Address" := OrderAddress.Address;
            if OrderAddress."Address 2" <> '' then
                GSTTransHeader."Seller Address" += OrderAddress."Address 2";
            GSTTransHeader."Seller City" := OrderAddress.City;
            if State.GET(OrderAddress.State) then
                GSTTransHeader."Seller State" := State."State Code (GST Reg. No.)";
            GSTTransHeader."Seller Zip Code" := OrderAddress."Post Code";
            GSTTransHeader."Seller Phone No." := OrderAddress."Phone No.";
        end else begin
            if Vendor.Get(PurchCrMemoHeaderP."Buy-from Vendor No.") then
                ;
            GSTTransHeader."Seller Name" := PurchCrMemoHeaderP."Buy-from Vendor Name";
            if PurchCrMemoHeaderP."Buy-from Vendor Name 2" > '' then
                GSTTransHeader."Seller Name" += ' ' + PurchCrMemoHeaderP."Buy-from Vendor Name 2";
            GSTTransHeader."Seller GSTIN" := Vendor."GST Registration No.";
            GSTTransHeader."Seller Address" := PurchCrMemoHeaderP."Buy-from Address";
            if PurchCrMemoHeaderP."Buy-from Address 2" > '' then
                GSTTransHeader."Seller Address" += ' ' + PurchCrMemoHeaderP."Buy-from Address 2";
            GSTTransHeader."Seller City" := PurchCrMemoHeaderP."Buy-from City";
            if state.Get(PurchCrMemoHeaderP."GST Order Address State") then
                GSTTransHeader."Seller State" := State."State Code (GST Reg. No.)"
            else
                if State.Get(Vendor."State Code") THEN
                    GSTTransHeader."Seller State" := State."State Code (GST Reg. No.)";
            GSTTransHeader."Seller Zip Code" := PurchCrMemoHeaderP."Buy-from Post Code";
            GSTTransHeader."Seller Phone No." := Vendor."Phone No.";
        end;
        GSTTransHeader.Modify();
    end;

    local procedure ReadBuyerDetailsPurchaseCreditMemo(PurchCrMemoHeaderP: Record "Purch. Cr. Memo Hdr.")
    var
        CompanyInformation: Record "Company Information";
        Location: Record Location;
        State: Record State;
    begin
        CompanyInformation.Get();
        GSTTransHeader."Buyer Name" := CompanyInformation.Name;
        if CompanyInformation."Name 2" > '' then
            GSTTransHeader."Buyer Name" += ' ' + CompanyInformation."Name 2";
        if Location.GET(PurchCrMemoHeaderP."Location Code") then begin
            GSTTransHeader."Buyer GSTIN" := Location."GST Registration No.";
            GSTTransHeader."Buyer Address" := Location.Address;
            if Location."Address 2" > '' then
                GSTTransHeader."Buyer Address" += ' ' + Location."Address 2";
            GSTTransHeader."Buyer City" := Location.City;
            State.GET(Location."State Code");
            GSTTransHeader."Buyer State" := State."State Code (GST Reg. No.)";
            GSTTransHeader."Buyer Zip Code" := Location."Post Code";
            GSTTransHeader."Buyer Phone No." := Location."Phone No.";
            GSTTransHeader."Seller/Buyer Taxable entity" := Location."Taxable Entity";
        END;
        GSTTransHeader.MODIFY;
        //Country not added
    end;

    local procedure AddAdvanceDetails()
    var
        BankAccLedgerEntry: Record "Bank Account Ledger Entry";
        GSTTransHeader: Record "ClearComp GST Trans. Header";
    begin
        BankAccLedgerEntry.SetRange("Posting Date", FromDate, ToDate);
        if BankAccLedgerEntry.FindSet() then
            repeat
                case BankAccLedgerEntry."Bal. Account Type" of
                    BankAccLedgerEntry."Bal. Account Type"::Customer:
                        GSTTransHeader."Transaction Type" := GSTTransHeader."Transaction Type"::SALE;
                    BankAccLedgerEntry."Bal. Account Type"::Vendor:
                        GSTTransHeader."Transaction Type" := GSTTransHeader."Transaction Type"::PURCHASE;
                end;
                GSTTransHeader."Document No." := Format(BankAccLedgerEntry."Entry No.");
                GSTTransHeader."Posting Date" := BankAccLedgerEntry."Posting Date";
                if GSTTransHeader.Insert() then
                    ;
            until BankAccLedgerEntry.Next() = 0;
    end;

    procedure SendData(var GSTTransHeaderP: Record "ClearComp GST Trans. Header")
    var
        MessageText: Text;
    begin
        GSTSetup.Get();
        GSTTransHeader.Copy(GSTTransHeaderP);
        GSTTransHeader.SetRange(Selected, true);
        if GSTSetup."Sync. Doc. with IRN" then
            GSTTransHeaderP.SetFilter(IRN, '<>%1', '');
        if GSTTransHeader.IsEmpty() then
            Error(NotSelectedErr);
        GSTTransHeader.SETRANGE("Document Type", GSTTransHeader."Document Type"::Invoice);
        GSTTransHeader.SETRANGE("Is Bill of Supply", FALSE);
        GSTTransHeader.SetRange("Is Advance", false);
        if GSTTransHeader.FindSet() then
            repeat
                MessageText := CreateJsonTemplate();
                PrepareSendMessage('PUT', MessageText, 'v0.1', GSTTransHeader."Seller/Buyer Taxable entity", 'invoices', GSTTransHeader."Document No.", false, false);
            until GSTTransHeader.Next() = 0;

        GSTTransHeader.SetRange("Is Bill of Supply", true);
        if GSTTransHeader.FindSet() then
            repeat
                Clear(MessageText);
                MessageText := CreateJsonTemplate();
                PrepareSendMessage('PUT', MessageText, 'v0.1', GSTTransHeader."Seller/Buyer Taxable entity", 'billofsupply', GSTTransHeader."Document No.", false, false);
            until GSTTransHeader.Next() = 0;

        GSTTransHeader.SetRange("Document Type", GSTTransHeader."Document Type"::"Credit Memo");
        GSTTransHeader.SetRange("Is Bill of Supply");
        if GSTTransHeader.FindSet() then
            repeat
                Clear(MessageText);
                MessageText := CreateJsonTemplate();
                PrepareSendMessage('PUT', MessageText, 'v0.1', GSTTransHeader."Seller/Buyer Taxable entity", 'cdns', GSTTransHeader."Document No.", false, false);
            until GSTTransHeader.Next() = 0;

        GSTTransHeader.SetRange("Document Type");
        GSTTransHeader.SetRange("Is Advance", true);
        if GSTTransHeader.FindSet() then
            repeat
                Clear(MessageText);
                MessageText := CreateJsonTemplate();
                PrepareSendMessage('PUT', MessageText, 'v0.1', GSTTransHeader."Seller/Buyer Taxable entity", 'advance_payments', GSTTransHeader."Document No.", false, false);
            until GSTTransHeader.Next() = 0;

        GSTTransHeader.SetRange("Is Advance");
        GSTTransHeader.SetRange(Selected);
        GSTTransHeader.ModifyAll(Selected, FALSE);
        if (GSTSetup."Sync Invoices" = GSTSetup."Sync Invoices"::"Job Queue") and (not Manual) then begin
            GSTSetup."Job Queue From Date" := Today();
            GSTSetup.Modify();
        end;
        if ErrorG > '' then
            Message(ErrorFound + ':' + ErrorG);
        Commit();
    end;

    local procedure CreateJsonTemplate(): Text
    var
        GSTTransLine: Record "ClearComp GST Trans. Line";
        DummyInt: Integer;
        Position: Integer;
        DummyText: Text;
        DocNo: Code[30];
        JsonInText: Text;
        JObjectHeader: JsonObject;
        JObjectLine: JsonObject;
        JobjectTCS: JsonObject;
        JobjectTDS: JsonObject;
        JobjectITC: JsonObject;
        JobjectSeller: JsonObject;
        JobjectBuyer: JsonObject;
        JobjectExport: JsonObject;
        JobjectImport: JsonObject;
        JObjectEcomm: JsonObject;
        JSubObjectEcomm: JsonObject;
        JArrayLine: JsonArray;
    begin
        JObjectHeader.Add('source', Format(GSTTransHeader.Source));
        if GSTTransHeader."Document No." > '' then begin
            Position := StrPos(GSTTransHeader."Document No.", '/');
            DummyText := GSTTransHeader."Document No.";
            DocNo := DummyText.Replace('/', '$2F');
            JObjectHeader.Add('id', DocNo);
            if GSTTransHeader."Is Advance" then
                JObjectHeader.Add('document_number', GSTTransHeader."Document No.")
        end;
        //++SeaWays
        /*
        if GSTTransHeader."External Document no." > '' then begin
            DummyText := DelChr(GSTTransHeader."External Document no.", '=', DelChr(GSTTransHeader."External Document no.", '=', AllowCharacters));
            if StrLen(DummyText) > 16 then
                JObjectHeader.Add('serial_number', CopyStr(DummyText, 1, 16))
            else
                JObjectHeader.Add('serial_number', DummyText);
        end else begin
            */

        DummyText := DelChr(GSTTransHeader."Document No.", '=', DelChr(GSTTransHeader."Document No.", '=', AllowCharacters));
        //--Seaways
        if StrLen(DummyText) > 16 then
            JObjectHeader.Add('serial_number', CopyStr(DummyText, 1, 16))
        else
            JObjectHeader.Add('serial_number', DummyText);
        // end;
        if GSTTransHeader."Is Bill of Supply" then
            if GSTTransHeader."Transaction Type" = GSTTransHeader."Transaction Type"::SALE then
                JObjectHeader.Add('supply_num', GSTTransHeader."Document No.")
            else
                JObjectHeader.Add('supply_num', GSTTransHeader."External Document no.");
        JObjectHeader.Add('type', Format(GSTTransHeader."Transaction Type"));
        //++Seaways
        //if GSTTransHeader."Due Date" <> 0D then
        //   JObjectHeader.Add('due_date', Format(GSTTransHeader."Due Date", 10, '<Year4>-<Month,2>-<Day,2>'));
        //--Seaways
        JObjectHeader.Add('transaction_date', Format(GSTTransHeader."Posting Date", 10, '<Year4>-<Month,2>-<Day,2>'));
        if GSTTransHeader."Place of Supply" > '' then
            JObjectHeader.Add('place_of_supply', GSTTransHeader."Place of Supply");
        JObjectHeader.Add('reverse_charge_applicable', GSTTransHeader."Reverse Charge Applicable");
        // Creating Lines
        GSTTransLine.SetRange("Transaction Type", GSTTransHeader."Transaction Type");
        GSTTransLine.SetRange("Document Type", GSTTransHeader."Document Type");
        GSTTransLine.SetRange("Document No.", GSTTransHeader."Document No.");
        if GSTTransLine.FindSet() then
            repeat
                Clear(JObjectLine);
                if Evaluate(DummyInt, GSTTransLine."Document No.") then
                    JObjectLine.Add('serial_number', DummyInt);
                if not (GSTTransLine."Zero Tax Category" = GSTTransLine."Zero Tax Category"::" ") then
                    JObjectLine.Add('zero_tax_category', Format(GSTTransLine."Zero Tax Category"));
                if GSTTransLine.Description > '' then
                    JObjectLine.Add('description', GSTTransLine.Description);
                if GSTTransLine.Quantity > 0 then
                    JObjectLine.Add('quantity', Round(GSTTransLine.Quantity, 0.01));
                if GSTTransLine."Unit Price" > 0 then
                    JObjectLine.Add('unit_price', Round(GSTTransLine."Unit Price", 0.01));
                if GSTTransLine.UOM > '' then
                    JObjectLine.Add('unit_of_measurement', GSTTransLine.UOM);
                if GSTTransLine."Taxable Value" > 0 then
                    JObjectLine.Add('taxable_val', Round(GSTTransLine."Taxable Value", 0.01));
                if GSTTransLine."CGST Rate" > 0 then
                    JObjectLine.Add('cgst_rate', Round(GSTTransLine."CGST Rate", 0.01));
                if GSTTransLine."CGST Value" > 0 then
                    JObjectLine.Add('cgst_val', Round(GSTTransLine."CGST Value", 0.01));
                if GSTTransLine."SGST Rate" > 0 then
                    JObjectLine.Add('sgst_rate', Round(GSTTransLine."SGST Rate", 0.01));
                if GSTTransLine."SGST Value" > 0 then
                    JObjectLine.Add('sgst_val', Round(GSTTransLine."SGST Value", 0.01));
                if GSTTransLine."IGST Rate" > 0 then
                    JObjectLine.Add('igst_rate', Round(GSTTransLine."IGST Rate", 0.01));
                if GSTTransLine."IGST Value" > 0 then
                    JObjectLine.Add('igst_val', Round(GSTTransLine."IGST Value", 0.01));
                if GSTTransLine."Cess Rate" > 0 then
                    JObjectLine.Add('cess_rate', Round(GSTTransLine."Cess Rate", 0.01));
                if GSTTransLine."Cess Value" > 0 then
                    JObjectLine.Add('cess_val', Round(GSTTransLine."Cess Value", 0.01));
                if GSTTransLine."Total Value" > 0 then
                    JObjectLine.Add('total_val', Round(GSTTransLine."Total Value", 0.01));
                if GSTTransLine."GST Code" > '' then
                    JObjectLine.Add('gst_code', GSTTransLine."GST Code");
                if not (GSTTransLine."GST Type" = GSTTransLine."GST Type"::" ") then
                    JObjectLine.Add('gst_type', Format(GSTTransLine."GST Type"));
                if GSTTransLine.Discount > 0 then
                    JObjectLine.Add('discount', GSTTransLine.Discount);
                // Creating TCS
                if GSTTransLine."TCS_CGST Rate" > 0 then
                    JobjectTCS.Add('cgst_rate', Round(GSTTransLine."TCS_CGST Rate", 0.01));
                if GSTTransLine."TCS_CGST Value" > 0 then
                    JobjectTCS.Add('cgst_val', Round(GSTTransLine."TCS_CGST Value", 0.01));
                if GSTTransLine."TCS_SGST Rate" > 0 then
                    JobjectTCS.Add('sgst_rate', Round(GSTTransLine."TCS_SGST Rate", 0.01));
                if GSTTransLine."TCS_SGST Value" > 0 then
                    JobjectTCS.Add('sgst_val', Round(GSTTransLine."TCS_SGST Value", 0.01));
                if GSTTransLine."TCS_IGST Rate" > 0 then
                    JobjectTCS.Add('igst_rate', Round(GSTTransLine."TCS_IGST Rate", 0.01));
                if GSTTransLine."TCS_IGST Value" > 0 then
                    JobjectTCS.Add('igst_val', Round(GSTTransLine."TCS_IGST Value", 0.01));
                JObjectLine.Add('tcs', JobjectTCS);

                // Creating TDS
                if GSTTransLine."TDS_CGST Rate" > 0 then
                    JobjectTDS.Add('cgst_rate', Round(GSTTransLine."TDS_CGST Rate", 0.01));
                if GSTTransLine."TDS_CGST Value" > 0 then
                    JobjectTDS.Add('cgst_val', Round(GSTTransLine."TDS_CGST Value", 0.01));
                if GSTTransLine."TDS_SGST Rate" > 0 then
                    JobjectTDS.Add('sgst_rate', Round(GSTTransLine."TDS_SGST Rate", 0.01));
                if GSTTransLine."TDS_SGST Value" > 0 then
                    JobjectTDS.Add('sgst_val', Round(GSTTransLine."TDS_SGST Value", 0.01));
                if GSTTransLine."TDS_IGST Rate" > 0 then
                    JobjectTDS.Add('igst_rate', Round(GSTTransLine."TDS_IGST Rate", 0.01));
                if GSTTransLine."TDS_IGST Value" > 0 then
                    JobjectTDS.Add('igst_val', Round(GSTTransLine."TDS_IGST Value", 0.01));
                JObjectLine.Add('tds', JobjectTDS);

                // Creating ITC
                if not (GSTTransLine."ITC Type" = GSTTransLine."ITC Type"::" ") then
                    JobjectITC.Add('itc_type', Format(GSTTransLine."ITC Type"));
                if GSTTransLine."ITC Claim Percentage" > 0 then
                    JobjectITC.Add('itc_claim_percentage', Round(GSTTransLine."ITC Claim Percentage", 0.01));
                if GSTTransLine."CGST Total ITC" > 0 then
                    JobjectITC.Add('cgst_total_itc', Round(GSTTransLine."CGST Total ITC", 0.01));
                if GSTTransLine."SGST Total ITC" > 0 then
                    JobjectITC.Add('sgst_total_itc', Round(GSTTransLine."SGST Total ITC", 0.01));
                if GSTTransLine."IGST Total ITC" > 0 then
                    JobjectITC.Add('igst_total_itc', Round(GSTTransLine."IGST Total ITC", 0.01));
                if GSTTransLine."CESS Total ITC" > 0 then
                    JobjectITC.Add('cess_total_itc', Round(GSTTransLine."CESS Total ITC", 0.01));
                if GSTTransLine."CGST Claimed ITC" > 0 then
                    JobjectITC.Add('cgst_claimed_itc', Round(GSTTransLine."CGST Claimed ITC", 0.01));
                if GSTTransLine."SGST Claimed ITC" > 0 then
                    JobjectITC.Add('sgst_claimed_itc', Round(GSTTransLine."SGST Claimed ITC", 0.01));
                if GSTTransLine."IGST Claimed ITC" > 0 then
                    JobjectITC.Add('igst_claimed_itc', Round(GSTTransLine."IGST Claimed ITC", 0.01));
                if GSTTransLine."CESS Claimed ITC" > 0 then
                    JobjectITC.Add('cess_claimed_itc', Round(GSTTransLine."CESS Claimed ITC", 0.01));
                JObjectLine.Add('itc_details', JobjectITC);
                JArrayLine.Add(JObjectLine);
            until GSTTransLine.Next() = 0;

        JObjectHeader.Add('line_items', JArrayLine);

        // Creating Seller details
        if GSTTransHeader."Seller Name" > '' then
            JobjectSeller.Add('name', GSTTransHeader."Seller Name");
        if GSTTransHeader."Seller GSTIN" > '' then
            JobjectSeller.Add('gstin', GSTTransHeader."Seller GSTIN");
        if GSTTransHeader."Seller Address" > '' then
            JobjectSeller.Add('address', GSTTransHeader."Seller Address");
        if GSTTransHeader."Seller City" > '' then
            JobjectSeller.Add('city', GSTTransHeader."Seller City");
        if GSTTransHeader."Seller State" > '' then
            JobjectSeller.Add('state', GSTTransHeader."Seller State");
        if GSTTransHeader."Seller Zip Code" > '' then
            JobjectSeller.Add('zip_code', GSTTransHeader."Seller Zip Code");
        if GSTTransHeader."Seller Country" > '' then
            JobjectSeller.Add('country', GSTTransHeader."Seller Country");
        DummyText := RemoveCharacters(GSTTransHeader."Seller Phone No.");
        if (DummyText > '') and (StrLen(DummyText) > 10) then
            JobjectSeller.Add('phone_number', CopyStr(DummyText, STRLEN(DummyText) - 9, 10));
        JObjectHeader.Add('seller', JobjectSeller);

        // Creating Buyer details
        Clear(DummyText);
        if GSTTransHeader."Buyer Name" > '' then
            JobjectBuyer.Add('name', GSTTransHeader."Buyer Name");
        if (GSTTransHeader."Buyer GSTIN" > '') and (GSTTransHeader."Buyer GSTIN" <> GSTTransHeader."Seller GSTIN") then
            JobjectBuyer.Add('gstin', GSTTransHeader."Buyer GSTIN");
        if GSTTransHeader."Buyer Address" > '' then
            JobjectBuyer.Add('address', GSTTransHeader."Buyer Address");
        if GSTTransHeader."Buyer City" > '' then
            JobjectBuyer.Add('city', GSTTransHeader."Buyer City");
        if GSTTransHeader."Buyer State" > '' then
            JobjectBuyer.Add('state', GSTTransHeader."Buyer State");
        if GSTTransHeader."Buyer Zip Code" > '' then
            JobjectBuyer.Add('zip_code', GSTTransHeader."Buyer Zip Code");
        if GSTTransHeader."Buyer Country" > '' then
            JobjectBuyer.Add('country', GSTTransHeader."Buyer Country");
        DummyText := RemoveCharacters(GSTTransHeader."Buyer Phone No.");
        if (DummyText > '') and (StrLen(DummyText) > 10) then
            JobjectBuyer.Add('phone_number', CopyStr(DummyText, STRLEN(DummyText) - 9, 10));
        JObjectHeader.Add('receiver', JobjectBuyer);

        // Creating Export details
        if not (GSTTransHeader."Export Type" = GSTTransHeader."Export Type"::" ") then
            JobjectExport.Add('export_type', FORMAT(GSTTransHeader."Export Type"));
        if GSTTransHeader."Shipping Bill No." > '' then
            JobjectExport.Add('shipping_bill_num', GSTTransHeader."Shipping Bill No.");
        if GSTTransHeader."Shipping Port Code" > '' then
            JobjectExport.Add('shipping_port_num', GSTTransHeader."Shipping Port Code");
        if GSTTransHeader."Shipping Bill Date" > 0D then
            JobjectExport.Add('shipping_bill_date', Format(GSTTransHeader."Shipping Bill Date", 10, '<Day,2>-<Month,2>-<Year4>'));
        JObjectHeader.Add('export', JobjectExport);

        // Creating Import details
        if GSTTransHeader."Bill of Entry" <> '' then
            JobjectImport.Add('bill_of_entry', GSTTransHeader."Bill of Entry");
        if GSTTransHeader."Bill of Entry Value" <> 0 then
            JobjectImport.Add('bill_of_entry_value', GSTTransHeader."Bill of Entry Value");
        if GSTTransHeader."Bill of Entry Date" <> 0D then
            JobjectImport.Add('bill_of_entry_date', FORMAT(GSTTransHeader."Bill of Entry Date", 10, '<Year4>-<Month,2>-<Day,2>'));
        if not (GSTTransHeader."Import Invoice Type" = GSTTransHeader."Import Invoice Type"::" ") then
            JobjectImport.Add('import_invoice_type', FORMAT(GSTTransHeader."Import Invoice Type"));
        if GSTTransHeader."Import Port Code" <> '' then
            JobjectImport.Add('port_code', GSTTransHeader."Import Port Code");
        JObjectHeader.Add('import', JobjectImport);

        // Creating E-commerce details
        if GSTTransHeader."E-Commerce Name" > '' then
            JSubObjectEcomm.Add('name', GSTTransHeader."E-Commerce Name");
        if GSTTransHeader."E-Commerce GSTIN" > '' then
            JSubObjectEcomm.Add('gstin', GSTTransHeader."E-Commerce GSTIN");
        if GSTTransHeader."E-Commerce Address" > '' then
            JSubObjectEcomm.Add('address', GSTTransHeader."E-Commerce Address");
        if GSTTransHeader."E-Commerce City" > '' then
            JSubObjectEcomm.Add('city', GSTTransHeader."E-Commerce City");
        if GSTTransHeader."E-Commerce State" > '' then
            JSubObjectEcomm.Add('state', GSTTransHeader."E-Commerce State");
        if GSTTransHeader."E-Commerce Zip Code" > '' then
            JSubObjectEcomm.Add('zip_code', GSTTransHeader."E-Commerce Zip Code");
        if GSTTransHeader."E-Commerce Country" > '' then
            JSubObjectEcomm.Add('country', GSTTransHeader."E-Commerce Country");
        if GSTTransHeader."E-Commerce Phone No." > '' then
            JSubObjectEcomm.Add('phone_number', GSTTransHeader."E-Commerce Phone No.");

        JObjectEcomm.Add('ecommerce_operator', JSubObjectEcomm);
        JObjectEcomm.Add('merchant_id', GSTTransHeader."E- Commerce Merchant ID");
        JObjectHeader.Add('ecommerce', JObjectEcomm);

        // Header details
        if not (GSTTransHeader."CDN Type" = GSTTransHeader."CDN Type"::" ") then
            JObjectHeader.Add('cdn_type', FORMAT(GSTTransHeader."CDN Type"));
        if GSTTransHeader."Original Invoice No." > '' then
            JObjectHeader.Add('original_invoice_serial_num', GSTTransHeader."Original Invoice No.");
        if GSTTransHeader."Original Invoice Date" > 0D then
            JObjectHeader.Add('original_invoice_date', FORMAT(GSTTransHeader."Original Invoice Date", 10, '<Day,2>-<Month,2>-<Year4>'));
        JObjectHeader.Add('original_invoice_type', FORMAT(GSTTransHeader."Original Invoice Type"));
        JObjectHeader.Add('original_invoice_classification', FORMAT(GSTTransHeader."Original Inv. Classification"));
        if GSTTransHeader."Original Invoice GSTIN" > '' then
            JObjectHeader.Add('original_invoice_gstin', GSTTransHeader."Original Invoice GSTIN");
        if GSTTransHeader."Reference Doc No." <> '' then
            JObjectHeader.Add('ref_doc_number', GSTTransHeader."Reference Doc No.");
        JObjectHeader.Add('note_num', GSTTransHeader."Note Num");
        //++Indra_Optionalfield
        //if GSTTransHeader."Date of Purchase" > 0D then  
        //  JObjectHeader.Add('date_of_purchase', FORMAT(GSTTransHeader."Date of Purchase", 10, '<Year4>-<Month,2>-<Day,2>'));
        //--Indra_OptionalField
        JObjectHeader.Add('tcs_applicable', GSTTransHeader."TCS Applicable");
        JObjectHeader.Add('tds_applicable', GSTTransHeader."TDS Applicable");
        if GSTTransHeader."Country of Supply" > '' then
            JObjectHeader.Add('country_of_supply', GSTTransHeader."Country of Supply");
        JObjectHeader.Add('is_canceled', GSTTransHeader."Is Cancelled");
        if not (GSTTransHeader."Customer Type" = GSTTransHeader."Customer Type"::" ") then
            JObjectHeader.Add('customer_type', FORMAT(GSTTransHeader."Customer Type"));
        if not (GSTTransHeader."Supplier Type" = GSTTransHeader."Supplier Type"::" ") then
            JObjectHeader.Add('supplier_type', FORMAT(GSTTransHeader."Supplier Type"));

        JObjectHeader.WriteTo(JsonInText);
        exit(JsonInText);
    end;

    local procedure RemoveCharacters(FromStringP: Text): Text
    begin
        exit(DelChr(FromStringP, '=', DelChr(FromStringP, '=', '1234567890')));
    end;

    procedure SetPostingDateFilter(FromDateP: Date; ToDateP: Date; DocNo: code[20])
    begin
        // Triggered from "Transfer Data to ClearTAX" report to set filters.
        DocNoG := DocNo;
        FromDate := FromDateP;
        ToDate := ToDateP;
        Manual := true;
    end;

    procedure SetManualProcess()
    begin
        Manual := true;
    end;

    procedure ImportDataFromExcel()
    var
        FileManagement: Codeunit "File Management";
        TempXLBuffer: Record "Excel Buffer" temporary;
        FromFile: Text;
        SheetName: Text;
        ServerFileName: Text;
        LastRowNo: Integer;
        I: Integer;
        DocumentNumberColumn: Integer;
        InStrm: InStream;
        GSTTransHeader: Record "ClearComp GST Trans. Header";
    begin
        if UploadIntoStream('Import Excel', '', '', ServerFileName, InStrm) then
            if ServerFileName > '' then
                SheetName := TempXLBuffer.SelectSheetsNameStream(InStrm)
            else
                Error('No Excel File Found');

        if SheetName > '' then begin
            TempXLBuffer.OpenBookStream(InStrm, SheetName);
            TempXLBuffer.ReadSheet();
            if TempXLBuffer.Insert() then
                ;
            if TempXLBuffer.FindLast() then
                LastRowNo := TempXLBuffer."Row No.";

            TempXLBuffer.SetRange("Row No.", 2);
            if TempXLBuffer.FindSet() THEN
                repeat
                    if (TempXLBuffer."Column No." = 8) and (TempXLBuffer."Cell Value as Text" = 'Document Number (Sales Book)') then
                        DocumentNumberColumn := 8;
                    if (TempXLBuffer."Column No." = 13) and (TempXLBuffer."Cell Value as Text" IN ['Document Number (2B)']) then
                        DocumentNumberColumn := 13;
                    if (TempXLBuffer."Column No." = 9) and (TempXLBuffer."Cell Value as Text" = 'Bill of Entry Number(2B)') then
                        DocumentNumberColumn := 9;
                until (TempXLBuffer.NEXT = 0) OR (DocumentNumberColumn > 0);

            for I := 3 to LastRowNo do begin
                TempXLBuffer.SetRange("Row No.", I);
                TempXLBuffer.SetRange("Column No.", DocumentNumberColumn);
                if TempXLBuffer.FindFirst() then begin
                    GSTTransHeader.SetRange(Status, GSTTransHeader.Status::Synced);
                    if DocumentNumberColumn = 9 then
                        GSTTransHeader.SetRange("Bill of Entry", TempXLBuffer."Cell Value as Text")
                    ELSE
                        GSTTransHeader.SetRange("Document No.", TempXLBuffer."Cell Value as Text");
                    if GSTTransHeader.FindFirst() then begin
                        GSTTransHeader."Matched Status" := GetCellValueExcel(TempXLBuffer, I, 1);

                        if DocumentNumberColumn = 8 then begin
                            GSTTransHeader."MisMatched Fields" := GetCellValueExcel(TempXLBuffer, I, 2);
                            GSTTransHeader."Match Status Description" := GetCellValueExcel(TempXLBuffer, I, 3);
                        end else
                            if DocumentNumberColumn in [9, 13] then begin
                                GSTTransHeader."Match Status Description" := GetCellValueExcel(TempXLBuffer, I, 2);
                                GSTTransHeader."Matching at PAN/GSTIN" := GetCellValueExcel(TempXLBuffer, I, 3);
                                GSTTransHeader."MisMatched Fields" := GetCellValueExcel(TempXLBuffer, I, 4);
                                if Evaluate(GSTTransHeader."MisMatched Fields count", GetCellValueExcel(TempXLBuffer, I, 5)) then
                                    ;
                            end;
                        GSTTransHeader.Modify();
                    end;
                end;
            end;
            //end;
            //until NameValueBufferOut.Next() = 0;
        end;
        // if Erase(ServerFileName) then
        //     ;
    end;

    local procedure GetCellValueExcel(var TempExcelBufferP: Record "Excel Buffer"; RowNoP: Integer; ColumnNoP: Integer): Text
    begin
        TempExcelBufferP.SetRange("Row No.", RowNoP);
        TempExcelBufferP.SetRange("Column No.", ColumnNoP);
        if TempExcelBufferP.FindFirst() then
            exit(TempExcelBufferP."Cell Value as Text");
    end;

    procedure ExportDataToExcel(var GSTTransHeaderP: Record "ClearComp GST Trans. Header")
    var
        MenuOptions: Text;
        MenuOptions1: Text;
        Choice: Integer;
        Choice1: Integer;
        Counter: Integer;
        Purchase: Boolean;
    begin
        Counter := 0;
        GSTTransHeader.Copy(GSTTransHeaderP);
        GSTTransHeader.SetRange("Transaction Type", GSTTransHeader."Transaction Type"::SALE);
        if GSTTransHeader.FindFirst() then begin
            CreateStringMenu(MenuOptions, Format(GSTTransHeader."Transaction Type"::SALE));
            Counter += 1;
        end;
        GSTTransHeader.SETRANGE("Transaction Type", GSTTransHeader."Transaction Type"::PURCHASE);
        if GSTTransHeader.FindFirst() then begin
            CreateStringMenu(MenuOptions, Format(GSTTransHeader."Transaction Type"::PURCHASE));
            Counter += 1;
        end;

        if Counter > 1 then
            Choice := StrMenu(MenuOptions);
        if Counter = 1 then
            Choice := 1;
        if (Choice = 0) then
            exit;

        if SelectStr(Choice, MenuOptions) = Format(GSTTransHeader."Transaction Type"::SALE) then begin
            GSTTransHeader.SetRange("Transaction Type", GSTTransHeader."Transaction Type"::SALE);
            MenuOptions1 := GenerateOptions(GSTTransHeader);
            Choice1 := StrMenu(MenuOptions1, 1, Format(GSTTransHeader."Transaction Type"::SALE));
        end else begin
            MenuOptions1 := GenerateOptions(GSTTransHeader);
            Choice1 := StrMenu(MenuOptions1, 1, Format(GSTTransHeader."Transaction Type"::PURCHASE));
        end;
        if Choice1 = 0 then
            exit;

        if SelectStr(Choice, MenuOptions) = Format(GSTTransHeader."Transaction Type"::SALE) then
            GSTTransHeader.SetRange("Transaction Type", GSTTransHeader."Transaction Type"::SALE)
        else
            if SelectStr(Choice, MenuOptions) = Format(GSTTransHeader."Transaction Type"::PURCHASE) then begin
                GSTTransHeader.SetRange("Transaction Type", GSTTransHeader."Transaction Type"::PURCHASE);
                Purchase := true;
            end;

        if SelectStr(Choice1, MenuOptions1) = Format(GSTTransHeader."Document Type"::Invoice) then begin
            GSTTransHeader.SetRange("Document Type", GSTTransHeader."Document Type"::Invoice);
            GSTTransHeader.SetRange("Is Bill of Supply", false);
            GSTTransHeader.SetRange("Is Advance", false);
            if Purchase then
                ReadDataToExcelPurchaseorBillofSupply()
            else
                ReadDataToExcelSalesorBillofSupply();
        end else
            if SelectStr(Choice1, MenuOptions1) = 'Bill of Supply' then begin
                GSTTransHeader.SetRange("Document Type", GSTTransHeader."Document Type"::Invoice);
                GSTTransHeader.SetRange("Is Bill of Supply", true);
                GSTTransHeader.SetRange("Is Advance", false);
                if Purchase then
                    ReadDataToExcelPurchaseorBillofSupply()
                else
                    ReadDataToExcelSalesorBillofSupply();
            end else
                if SelectStr(Choice1, MenuOptions1) = Format(GSTTransHeader."Document Type"::"Credit Memo") then begin
                    GSTTransHeader.SetRange("Document Type", GSTTransHeader."Document Type"::"Credit Memo");
                    GSTTransHeader.SetRange("Is Advance", false);
                    if Purchase then
                        ReadDataToExcelPurchCreditMemo()
                    else
                        ReadDataToExcelSalesCreditMemo();
                end else
                    if SelectStr(Choice1, MenuOptions1) = 'Advance' then begin
                        GSTTransHeader.SetRange("Document Type");
                        GSTTransHeader.SetRange("Is Advance", true);
                        GSTTransHeader.SetRange("Is Bill of Supply", false);
                        if Purchase then
                            ReadDataToExcelPurchAdvance()
                        else
                            ReadDataToExcelSalesAdvance();
                    end;
    end;

    local procedure ReadDataToExcelPurchaseorBillofSupply()
    var
        GSTTransLine: Record "ClearComp GST Trans. Line";
        ExcelBuffer: Record "Excel Buffer" temporary;
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        Counter: Integer;
        HeaderFields: Option "Invoice Date*","Invoice Number*","Supplier Name","Supplier GSTIN","Supplier State","Is the item a GOOD (G) or SERVICE (S)","Item Description","HSN or SAC code","Item Quantity","Item Unit of Measurement","Item Rate","Total Item Discount Amount","Item Taxable Value*","CGST Rate","CGST Amount","SGST Rate","SGST Amount","IGST Rate","IGST Amount","CESS Rate","CESS Amount","ITC Claim Type CGST","ITC Claim Amount SGST","ITC Claim Amount	IGST","ITC Claim Amount","CESS ITC Claim Amount","Is this a Bill of Supply","Is this a Nil Rated/Exempt/NonGST item?","Is Reverse Charge Applicable?","Type of Import (Goods;Services;SEZ)","Bill of Entry Port Code","Bill of Entry Number","Bill of Entry Date","Is this document cancelled?","Is the supplier a Composition dealer?","Return Filing Month","Return Filing Quarter","My GSTIN","State Place of Supply*","Supplier Address","Supplier City","Original Invoice Date (In case of amendment)","Original Invoice Number (In case of amendment)","Original Supplier GSTIN (In case of amendment)","Date of Linked Advance Payment","Voucher Number of Linked Advance Payment","Adjustment Amount of Linked Advance Payment","Goods Receipt Note Number","Goods Receipt Note Date","Goods Receipt Quantity","Goods Receipt Amount","Total Transaction Value";
        ColumnLabel: option A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,AA,AB,AC,AD,AE,AF,AG,AH,AI,AJ,AK,AL,AM,AN,AO,AP,AQ,AR,AS,AT,AU,AV,AW,AX,AY,AZ;
    begin
        CreateExcelBuffer(ExcelBuffer, 2, '2', 1, 'A', XLTxt1);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 5, 'E', XLTxt3);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 14, 'N', XLTxt4);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 22, 'V', XLTxt12);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 30, 'AD', XLTxt12);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 35, 'AJ', XLTxt6);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 39, 'AM', XLTxt14);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 42, 'AP', XLTxt7);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 45, 'AS', XLTxt8);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 52, 'AZ', XLTxt9);
        // sisCam custom fields
        CreateExcelBuffer(ExcelBuffer, 2, '2', 53, 'BA', XLTxt15);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 54, 'BB', XLTxt16);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 55, 'BC', XLTxt17);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 56, 'BD', XLTxt18);
        // siscam custom fields
        for Counter := 0 to HeaderFields::"Total Transaction Value" do begin
            HeaderFields := Counter;
            ColumnLabel := Counter;
            CreateExcelBuffer(ExcelBuffer, 3, '3', Counter + 1, Format(ColumnLabel), Format(HeaderFields));
        end;
        Counter := 4;
        if GSTTransHeader.FindSet() then
            repeat
                if PurchaseInvoiceHeader.Get(GSTTransHeader."Document No.") then
                    ;
                GSTTransLine.SetRange("Transaction Type", GSTTransHeader."Transaction Type");
                GSTTransLine.SetRange("Document Type", GSTTransHeader."Document Type");
                GSTTransLine.SetRange("Document No.", GSTTransHeader."Document No.");
                if GSTTransLine.FindSet() then
                    repeat
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 1, 'A', Format(GSTTransHeader."Posting Date"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 2, 'B', Format(PurchaseInvoiceHeader."Vendor Invoice No."));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 3, 'C', Format(GSTTransHeader."Seller Name"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 4, 'D', Format(GSTTransHeader."Seller GSTIN"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 5, 'E', Format(GSTTransHeader."Seller City"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 6, 'F', Format(GSTTransLine."GST Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 7, 'G', Format(GSTTransLine.Description));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 8, 'H', Format(GSTTransLine."GST Code"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 9, 'I', Format(GSTTransLine.Quantity));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 10, 'J', Format(GSTTransLine.UOM));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 11, 'K', Format(GSTTransLine."Unit Price"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 12, 'L', Format(GSTTransLine.Discount));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 13, 'M', Format(GSTTransLine."Taxable Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 14, 'N', Format(GSTTransLine."CGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 15, 'O', Format(GSTTransLine."CGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 16, 'P', Format(GSTTransLine."SGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 17, 'Q', Format(GSTTransLine."SGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 18, 'R', Format(GSTTransLine."IGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 19, 'S', Format(GSTTransLine."IGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 20, 'T', Format(GSTTransLine."Cess Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 21, 'U', Format(GSTTransLine."Cess Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 22, 'V', Format(GSTTransLine."ITC Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 23, 'W', Format(GSTTransLine."CGST Claimed ITC"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 24, 'X', Format(GSTTransLine."SGST Claimed ITC"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 25, 'Y', Format(GSTTransLine."IGST Claimed ITC"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 26, 'Z', Format(GSTTransLine."CESS Claimed ITC"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 27, 'AA', Format(GSTTransHeader."Is Bill of Supply"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 28, 'AB', Format(GSTTransLine."Zero Tax Category"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 29, 'AC', Format(GSTTransHeader."Reverse Charge Applicable"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 30, 'AD', Format(GSTTransHeader."Import Invoice Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 31, 'AE', Format(GSTTransHeader."Import Port Code"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 32, 'AF', Format(GSTTransHeader."Bill of Entry Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 33, 'AG', Format(GSTTransHeader."Bill of Entry Date"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 34, 'AH', Format(GSTTransHeader."Is Cancelled"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 35, 'AI', Format(GSTTransHeader."Customer Type"));
                        //Return filing month and quartar to be added.
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 38, 'AL', Format(GSTTransHeader."Buyer GSTIN"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 39, 'AM', Format(GSTTransHeader."Place of Supply"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 40, 'AN', Format(GSTTransHeader."Seller Address"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 41, 'AO', Format(GSTTransHeader."Seller City"));
                        // Siscam Custom fields
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 53, 'BA', Format(GSTTransHeader."Document No."));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 54, 'BB', Format(PurchaseInvoiceHeader."Buy-from Vendor No."));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 55, 'BC', Format(GSTTransHeader."Posting Date"));
                        // Siscam Custom fields
                        //Amendment details,goods receipt not added.
                        //Advance receipts and total value not added.
                        Counter += 1;
                    until GSTTransLine.Next() = 0;
            until GSTTransHeader.Next() = 0;
        ExcelBuffer.CreateNewBook('GSTR2 Invoice');
        ExcelBuffer.WriteSheet('', '', UserId());
        ExcelBuffer.CloseBook();
        ExcelBuffer.OpenExcel();
        //ExcelBuffer.CreateBookAndOpenExcel('', 'GSTR2 Invoice', '', '', UserId());
    end;

    local procedure ReadDataToExcelSalesorBillofSupply()
    var
        GSTTransLine: Record "ClearComp GST Trans. Line";
        ExcelBuffer: Record "Excel Buffer" temporary;
        HeaderFields: Option "Invoice Date*","Invoice Number*","Customer Billing Name","Customer Billing GSTIN","State Place of Supply*","Is the item a GOOD (G) or SERVICE (S)","Item Description","HSN or SAC code","Item Quantity","Item Unit of Measurement","Item Rate","Total Item Discount Amount","Item Taxable Value*","CGST Rate","CGST Amount","SGST Rate","SGST Amount","IGST Rate","IGST Amount","CESS Rate","CESS Amount","Is this a Bill of Supply?","Is this a Nil Rated/Exempt/NonGST item?","Is Reverse Charge Applicable?","Type of Export","Shipping Port Code - Export","Shipping Bill Number - Export","Shipping Bill Date - Export","Has GST/IDT TDS been deducted","My GSTIN","Customer Billing Address","Customer Billing City","Customer Billing State","Is this document cancelled?","Is the customer a Composition dealer or UIN registered?","Return Filing Month","Return Filing Quarter","Original Invoice Date (In case of amendment)","Original Invoice Number (In case of amendment)","Original Customer Billing GSTIN (In case of amendment)","GSTIN of Ecommerce Marketplace","Date of Linked Advance Receipt","Voucher Number of Linked Advance Receipt","Adjustment Amount of the Linked Advance Receipt","Total Transaction Value";
        ColumnLabel: Option A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,AA,AB,AC,AD,AE,AF,AG,AH,AI,AJ,AK,AL,AM,AN,AO,AP,AQ,AR,AS,AT,AU,AV,AW,AX,AY,AZ;
        Counter: Integer;
    begin
        CreateExcelBuffer(ExcelBuffer, 2, '2', 1, 'A', XLTxt1);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 5, 'E', XLTxt2);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 6, 'F', XLTxt3);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 14, 'N', XLTxt4);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 25, 'Y', XLTxt5);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 36, 'AJ', XLTxt6);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 38, 'AL', XLTxt7);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 42, 'AP', XLTxt8);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 45, 'AS', XLTxt9);
        for Counter := 0 to HeaderFields::"Total Transaction Value" do begin
            HeaderFields := Counter;
            ColumnLabel := Counter;
            CreateExcelBuffer(ExcelBuffer, 3, '3', Counter + 1, Format(ColumnLabel), Format(HeaderFields));
        end;
        Counter := 4;
        if GSTTransHeader.FindSet() then
            repeat
                GSTTransLine.SetRange("Transaction Type", GSTTransHeader."Transaction Type");
                GSTTransLine.SetRange("Document Type", GSTTransHeader."Document Type");
                GSTTransLine.SetRange("Document No.", GSTTransHeader."Document No.");
                if GSTTransLine.FindSet() then
                    repeat
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 1, 'A', Format(GSTTransHeader."Posting Date"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 2, 'B', Format(GSTTransHeader."Document No."));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 3, 'C', Format(GSTTransHeader."Buyer Name"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 4, 'D', Format(GSTTransHeader."Buyer GSTIN"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 5, 'E', Format(GSTTransHeader."Place of Supply"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 6, 'F', Format(GSTTransLine."GST Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 7, 'G', Format(GSTTransLine.Description));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 8, 'H', Format(GSTTransLine."GST Code"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 9, 'I', Format(GSTTransLine.Quantity));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 10, 'J', Format(GSTTransLine.UOM));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 11, 'K', Format(GSTTransLine."Unit Price"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 12, 'L', Format(GSTTransLine.Discount));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 13, 'M', Format(GSTTransLine."Taxable Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 14, 'N', Format(GSTTransLine."CGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 15, 'O', Format(GSTTransLine."CGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 16, 'P', Format(GSTTransLine."SGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 17, 'Q', Format(GSTTransLine."SGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 18, 'R', Format(GSTTransLine."IGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 19, 'S', Format(GSTTransLine."IGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 20, 'T', Format(GSTTransLine."Cess Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 21, 'U', Format(GSTTransLine."Cess Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 22, 'V', Format(GSTTransHeader."Is Bill of Supply"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 23, 'W', Format(GSTTransLine."Zero Tax Category"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 24, 'X', Format(GSTTransHeader."Reverse Charge Applicable"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 25, 'Y', Format(GSTTransHeader."Export Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 26, 'Z', Format(GSTTransHeader."Shipping Port Code"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 27, 'AA', Format(GSTTransHeader."Shipping Bill No."));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 28, 'AB', Format(GSTTransHeader."Shipping Bill Date"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 29, 'AC', Format(GSTTransHeader."TDS Applicable"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 30, 'AD', Format(GSTTransHeader."Seller GSTIN"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 31, 'AE', Format(GSTTransHeader."Buyer Address"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 32, 'AF', Format(GSTTransHeader."Buyer City"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 33, 'AG', Format(GSTTransHeader."Buyer State"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 34, 'AH', Format(GSTTransHeader."Is Cancelled"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 35, 'AI', Format(GSTTransHeader."Customer Type"));
                        //Return filing month and quartar to be added.
                        //Amendment details not added.
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 41, 'AO', Format(GSTTransHeader."E-Commerce GSTIN"));
                        //Advance receipts and total value not added.
                        Counter += 1;
                    until GSTTransLine.Next() = 0;
            until GSTTransHeader.Next() = 0;
        ExcelBuffer.CreateNewBook('GSTR1 Invoice');
        ExcelBuffer.WriteSheet('', '', UserId());
        ExcelBuffer.CloseBook();
        ExcelBuffer.OpenExcel();
        //ExcelBuffer.CreateBookAndOpenExcel('', 'GSTR1 Invoice', '', '', UserId());
    end;

    local procedure ReadDataToExcelPurchCreditMemo()
    var
        GSTTransLine: Record "ClearComp GST Trans. Line";
        ExcelBuffer: Record "Excel Buffer" temporary;
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Counter: Integer;
        HeaderFields: Option "Credit/Debit Note Date*","Credit/Debit Note Number","Credit(C)/ Debit(D) Note Type*","Linked Invoice Date","Linked Invoice Number","Supplier Name","Supplier GSTIN","Supplier State","Is the item a GOOD (G) or SERVICE (S)","Item Description","HSN or SAC code","Item Quantity","Item Unit of Measurement","Item Rate","Total Item Discount",Amount,"Item Taxable Value*","CGST Rate","CGST Amount","SGST Rate","SGST Amount","IGST Rate","IGST Amount","CESS Rate","CESS Amount","ITC Claim Type","CGST ITC Claim Amount","SGST ITC Claim Amount","IGST ITC Claim Amount","CESS ITC Claim Amount","Is this note for Bill of Supply?","Is this a Nil Rated/Exempt/NonGST item?","Is Reverse Charge Applicable?","Type of Import (Goods;Services;SEZ)","Bill of Entry Port Code","Bill of Entry Number","Bill of Entry Date","Is this document cancelled?","Is the supplier a Composition dealer?","Reason for issuing CDN","Is this note for a Pre-GST Invoice?","Which type of Invoice is this note linked to?","Return Filing Month","Return Filing Quarter","My GSTIN","State Place of Supply*","Supplier Address","Supplier City","Original Credit/Debit Note Date (In case of amendment)","Original Credit/Debit Note Number (In case of amendment)","Original Supplier GSTIN (In case of amendment)","Total Transaction Value";
        ColumnLabel: Option A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,AA,AB,AC,AD,AE,AF,AG,AH,AI,AJ,AK,AL,AM,AN,AO,AP,AQ,AR,AS,AT,AU,AV,AW,AX,AY,AZ;
    begin
        CreateExcelBuffer(ExcelBuffer, 2, '2', 1, 'A', XLTxt10);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 4, 'D', XLTxt1);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 8, 'H', XLTxt3);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 17, 'Q', XLTxt4);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 25, 'Y', XLTxt12);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 33, 'AG', XLTxt13);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 42, 'AP', XLTxt6);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 45, 'AS', XLTxt14);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 48, 'AV', XLTxt7);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 51, 'AY', XLTxt9);
        // Siscam custom fields
        CreateExcelBuffer(ExcelBuffer, 2, '2', 52, 'AZ', XLTxt15);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 53, 'BA', XLTxt16);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 54, 'BB', XLTxt17);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 55, 'BC', XLTxt18);
        // siscam custom fields
        for Counter := 0 to HeaderFields::"Total Transaction Value" do begin
            HeaderFields := Counter;
            ColumnLabel := Counter;
            CreateExcelBuffer(ExcelBuffer, 3, '3', Counter + 1, Format(ColumnLabel), Format(HeaderFields));
        end;
        Counter := 4;
        if GSTTransHeader.FindSet() then
            repeat
                IF PurchCrMemoHdr.Get(GSTTransHeader."Document No.") then
                    ;
                GSTTransLine.SetRange("Transaction Type", GSTTransHeader."Transaction Type");
                GSTTransLine.SetRange("Document Type", GSTTransHeader."Document Type");
                GSTTransLine.SetRange("Document No.", GSTTransHeader."Document No.");
                if GSTTransLine.FindSet() then
                    repeat
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 1, 'A', Format(GSTTransHeader."Posting Date"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 2, 'B', Format(PurchCrMemoHdr."Vendor Cr. Memo No."));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 3, 'C', Format(GSTTransHeader."Document Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 4, 'D', Format(GSTTransHeader."Original Invoice Date"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 5, 'E', Format(GSTTransHeader."Original Invoice No."));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 6, 'F', Format(GSTTransHeader."Seller Name"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 7, 'G', Format(GSTTransHeader."Seller GSTIN"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 8, 'H', Format(GSTTransHeader."Seller State"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 9, 'I', Format(GSTTransLine."GST Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 10, 'J', Format(GSTTransLine.Description));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 11, 'K', Format(GSTTransLine."GST Code"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 12, 'L', Format(GSTTransLine.Quantity));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 13, 'M', Format(GSTTransLine.UOM));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 14, 'N', Format(GSTTransLine."Unit Price"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 15, 'O', Format(GSTTransLine.Discount));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 16, 'P', Format(GSTTransLine."Total Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 17, 'Q', Format(GSTTransLine."Taxable Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 18, 'R', Format(GSTTransLine."CGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 19, 'S', Format(GSTTransLine."CGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 20, 'T', Format(GSTTransLine."IGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 21, 'U', Format(GSTTransLine."IGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 22, 'V', Format(GSTTransLine."IGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 23, 'W', Format(GSTTransLine."IGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 24, 'X', Format(GSTTransLine."Cess Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 25, 'Y', Format(GSTTransLine."Cess Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 26, 'Z', Format(GSTTransLine."ITC Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 27, 'AA', Format(GSTTransLine."CGST Claimed ITC"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 28, 'AB', Format(GSTTransLine."SGST Claimed ITC"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 29, 'AC', Format(GSTTransLine."IGST Claimed ITC"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 30, 'AD', Format(GSTTransLine."CESS Claimed ITC"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 31, 'AE', Format(GSTTransHeader."Is Bill of Supply"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 32, 'AF', Format(GSTTransLine."Zero Tax Category"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 33, 'AG', Format(GSTTransHeader."Reverse Charge Applicable"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 34, 'AH', Format(GSTTransHeader."Import Invoice Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 35, 'AI', Format(GSTTransHeader."Import Port Code"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 36, 'AJ', Format(GSTTransHeader."Bill of Entry"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 37, 'AK', Format(GSTTransHeader."Bill of Entry Date"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 38, 'AL', Format(GSTTransHeader."Is Cancelled"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 39, 'AM', Format(GSTTransHeader."Supplier Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 41, 'AP', Format(GSTTransHeader."Original Invoice Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 44, 'AS', Format(GSTTransHeader."Buyer GSTIN"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 45, 'AT', Format(GSTTransHeader."Place of Supply"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 46, 'AU', Format(GSTTransHeader."Seller Address"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 47, 'AV', Format(GSTTransHeader."Seller City"));
                        //++Siscam Custom fields
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 52, 'AZ', Format(GSTTransHeader."Document No."));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 53, 'BA', Format(PurchCrMemoHdr."Buy-from Vendor No."));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 54, 'BB', Format(GSTTransHeader."Posting Date"));
                        //-- Siscam Custom fields
                        //Return filing and amendment details not added.
                        //Total transaction value, applicable tax rate not added
                        Counter += 1;
                    until GSTTransLine.Next() = 0;
            until GSTTransHeader.Next() = 0;
        ExcelBuffer.CreateNewBook('GSTR2 Credit Debit Note');
        ExcelBuffer.WriteSheet('', '', UserId());
        ExcelBuffer.CloseBook();
        ExcelBuffer.OpenExcel();
        //ExcelBuffer.CreateBookAndOpenExcel('', 'GSTR2 Credit Debit Note', '', '', UserId());
    end;

    local procedure ReadDataToExcelSalesCreditMemo()
    var
        GSTTransLine: Record "ClearComp GST Trans. Line";
        ExcelBuffer: Record "Excel Buffer" temporary;
        Counter: Integer;
        HeaderFields: Option "Credit/Debit Note Date*","Credit/Debit Note Number*","Credit(C)/Debit(D) Note Type*","Invoice Date","Invoice Number","Customer Billing Name","Customer Billing GSTIN","State Place of Supply*","Is the item a GOOD (G) or SERVICE (S)","Item Description","HSN or SAC code","Item Quantity","Item Unit of Measurement","Item Rate","Total Item Discount Amount","Item Taxable Value*","CGST Rate","CGST Amount","SGST Rate","SGST Amount","IGST Rate","IGST Amount","CESS Rate","CESS Amount","Is Reverse Charge Applicable?","Is this note for Bill of Supply?","Is this a Nil Rated/Exempt/NonGST item?","Is this document cancelled?","Reason for issuing CDN","Is this note for a Pre-GST Invoice?","Which type of Invoice is this note linked to?","Is the customer a Composition dealer or UIN registered?","Return Filing Month","Return Filing Quarter","Original Credit/Debit Note Date (In case of amendment)","Original Credit/Debit Note Number (In case of amendment)","Original Customer Billing  GSTIN (In case of amendment)","My GSTIN","Customer Billing Address","Customer Billing City","Customer Billing State","Total Transaction Value","Applicable % of Tax Rate","GSTIN of Ecommerce Marketplace";
        ColumnLabel: Option A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,AA,AB,AC,AD,AE,AF,AG,AH,AI,AJ,AK,AL,AM,AN,AO,AP,AQ,AR,AS,AT,AU,AV,AW,AX,AY,AZ;
    begin
        CreateExcelBuffer(ExcelBuffer, 2, '2', 1, 'A', XLTxt10);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 4, 'D', XLTxt1);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 8, 'H', XLTxt2);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 9, 'I', XLTxt3);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 17, 'Q', XLTxt4);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 33, 'AG', XLTxt6);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 12, 'AL', XLTxt7);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 16, 'AP', XLTxt8);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 19, 'AS', XLTxt9);
        for Counter := 0 to HeaderFields::"GSTIN of Ecommerce Marketplace" do begin
            HeaderFields := Counter;
            ColumnLabel := Counter;
            CreateExcelBuffer(ExcelBuffer, 3, '3', Counter + 1, Format(ColumnLabel), Format(HeaderFields));
        end;
        Counter := 4;
        if GSTTransHeader.FindSet() then
            repeat
                GSTTransLine.SetRange("Transaction Type", GSTTransHeader."Transaction Type");
                GSTTransLine.SetRange("Document Type", GSTTransHeader."Document Type");
                GSTTransLine.SetRange("Document No.", GSTTransHeader."Document No.");
                if GSTTransLine.FindSet() then
                    repeat
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 1, 'A', Format(GSTTransHeader."Posting Date"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 2, 'B', Format(GSTTransHeader."Document No."));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 3, 'C', Format(GSTTransHeader."Document Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 4, 'D', Format(GSTTransHeader."Original Invoice Date"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 5, 'E', Format(GSTTransHeader."Original Invoice No."));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 6, 'F', Format(GSTTransHeader."Buyer Name"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 7, 'G', Format(GSTTransHeader."Buyer GSTIN"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 8, 'H', Format(GSTTransHeader."Place of Supply"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 9, 'I', Format(GSTTransLine."GST Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 10, 'J', Format(GSTTransLine.Description));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 11, 'K', Format(GSTTransLine."GST Code"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 12, 'L', Format(GSTTransLine.Quantity));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 13, 'M', Format(GSTTransLine.UOM));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 14, 'N', Format(GSTTransLine."Unit Price"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 15, 'O', Format(GSTTransLine.Discount));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 16, 'P', Format(GSTTransLine."Taxable Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 17, 'Q', Format(GSTTransLine."CGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 18, 'R', Format(GSTTransLine."CGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 19, 'S', Format(GSTTransLine."IGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 20, 'T', Format(GSTTransLine."IGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 21, 'U', Format(GSTTransLine."SGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 22, 'V', Format(GSTTransLine."SGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 23, 'W', Format(GSTTransLine."Cess Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 24, 'X', Format(GSTTransLine."Cess Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 25, 'Y', Format(GSTTransHeader."Reverse Charge Applicable"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 26, 'Z', Format(GSTTransHeader."Is Bill of Supply"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 27, 'AA', Format(GSTTransLine."Zero Tax Category"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 28, 'AB', Format(GSTTransHeader."Is Cancelled"));
                        //Reason for issuing CDN not added, pregst invoice not added.
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 31, 'AE', Format(GSTTransHeader."Original Invoice Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 32, 'AF', Format(GSTTransHeader."Customer Type"));
                        //Return filing and amendment details not added.
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 38, 'AL', Format(GSTTransHeader."Seller GSTIN"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 39, 'AM', Format(GSTTransHeader."Buyer Address"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 40, 'AN', Format(GSTTransHeader."Buyer City"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 41, 'AO', Format(GSTTransHeader."Buyer State"));
                        //Total transaction value, applicable tax rate not added
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 44, 'AR', Format(GSTTransHeader."E-Commerce GSTIN"));
                        Counter += 1;
                    until GSTTransLine.Next() = 0;
            until GSTTransHeader.Next() = 0;
        ExcelBuffer.CreateNewBook('GSTR1 Credit Debit Note');
        ExcelBuffer.WriteSheet('', '', UserId());
        ExcelBuffer.CloseBook();
        ExcelBuffer.OpenExcel();
        //ExcelBuffer.CreateBookAndOpenExcel('', 'GSTR1 Credit Debit Note', '', '', UserId());
    end;

    local procedure ReadDataToExcelPurchAdvance()
    var
        GSTTransLine: Record "ClearComp GST Trans. Line";
        ExcelBuffer: Record "Excel Buffer" temporary;
        Counter: Integer;
        HeaderFields: Option "Advance Payment Date*","Advance Payment Voucher Number*","Supplier Name","Supplier GSTIN","Supplier State","Is the item a GOOD (G) or SERVICE (S)","Item Description","HSN/SAC code","Item Quantity","Item Unit Of Measurement","Item Rate","Total Item Discount",Amount,"Item Taxable Value*","CGST Rate","CGST Amount","SGST Rate","SGST Amount","IGST Rate","IGST Amount","CESS Rate","CESS Amount","Is this Advance for a Bill of Supply?","Is Reverse Charge Applicable?","Is this document cancelled?","Is the supplier a Composition dealer?","Return Filing Month","Return Filing Quarter","MY GSTIN","State Place of Supply*","Supplier Address","Supplier City","Original Advance Payment Date (In case of amendment)","Original Advance Payment Voucher Number (In case of amendment)","Original Supplier GSTIN (In case of amendment)";
        ColumnLabel: Option A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,AA,AB,AC,AD,AE,AF,AG,AH,AI,AJ,AK,AL,AM,AN,AO,AP,AQ,AR,AS,AT,AU,AV,AW,AX,AY,AZ;
    begin
        CreateExcelBuffer(ExcelBuffer, 2, '2', 1, 'A', XLTxt11);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 5, 'E', XLTxt3);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 14, 'N', XLTxt4);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 26, 'Z', XLTxt6);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 29, 'AC', XLTxt14);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 32, 'AF', XLTxt7);
        for Counter := 0 to HeaderFields::"Original Supplier GSTIN (In case of amendment)" do begin
            HeaderFields := Counter;
            ColumnLabel := Counter;
            CreateExcelBuffer(ExcelBuffer, 3, '3', Counter + 1, Format(ColumnLabel), Format(HeaderFields));
        end;
        Counter := 4;
        if GSTTransHeader.FindSet() then
            repeat
                GSTTransLine.SetRange("Transaction Type", GSTTransHeader."Transaction Type");
                GSTTransLine.SetRange("Document Type", GSTTransHeader."Document Type");
                GSTTransLine.SetRange("Document No.", GSTTransHeader."Document No.");
                if GSTTransLine.FindSet() then
                    repeat
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 1, 'A', Format(GSTTransHeader."Posting Date"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 2, 'B', Format(GSTTransHeader."Document No."));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 3, 'C', Format(GSTTransHeader."Seller Name"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 4, 'D', Format(GSTTransHeader."Seller GSTIN"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 5, 'E', Format(GSTTransHeader."Seller State"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 6, 'F', Format(GSTTransLine."GST Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 7, 'G', Format(GSTTransLine.Description));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 8, 'H', Format(GSTTransLine."GST Code"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 9, 'I', Format(GSTTransLine.Quantity));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 10, 'J', Format(GSTTransLine.UOM));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 11, 'K', Format(GSTTransLine."Unit Price"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 12, 'L', Format(GSTTransLine.Discount));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 13, 'M', Format(GSTTransLine."Taxable Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 14, 'N', Format(GSTTransLine."CGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 15, 'O', Format(GSTTransLine."CGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 16, 'P', Format(GSTTransLine."SGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 17, 'Q', Format(GSTTransLine."SGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 18, 'R', Format(GSTTransLine."IGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 19, 'S', Format(GSTTransLine."IGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 20, 'T', Format(GSTTransLine."Cess Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 21, 'U', Format(GSTTransLine."Cess Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 22, 'V', Format(GSTTransHeader."Is Bill of Supply"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 23, 'W', Format(GSTTransHeader."Reverse Charge Applicable"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 24, 'X', Format(GSTTransHeader."Is Cancelled"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 25, 'Y', Format(GSTTransHeader."Supplier Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 28, 'AB', Format(GSTTransHeader."Buyer GSTIN"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 29, 'AC', Format(GSTTransHeader."Place of Supply"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 30, 'AD', Format(GSTTransHeader."Seller Address"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 31, 'AE', Format(GSTTransHeader."Seller City"));
                        //Return filing and amendment details not added.
                        //Total transaction value, applicable tax rate not added
                        Counter += 1;
                    until GSTTransLine.Next() = 0;
            until GSTTransHeader.Next() = 0;
        ExcelBuffer.CreateNewBook('GSTR2 Advance Payment');
        ExcelBuffer.WriteSheet('', '', UserId());
        ExcelBuffer.CloseBook();
        ExcelBuffer.OpenExcel();
        //ExcelBuffer.CreateBookAndOpenExcel('', 'GSTR2 Advance Payment', '', '', UserId());
    end;

    local procedure ReadDataToExcelSalesAdvance()
    var
        GSTTransLine: Record "ClearComp GST Trans. Line";
        ExcelBuffer: Record "Excel Buffer" temporary;
        Counter: Integer;
        HeaderFields: Option "Advance Receipt Voucher Date*","Advance Receipt Voucher Number*","Customer Billing Name","Customer Billing GSTIN","State Place of Supply*","Is the item a GOOD (G) or SERVICE (S)","Item Description","HSN or SAC code","Item Quantity","Item Unit Of Measurement","Item Rate","Total Item Discount Amount","Item Taxable Value*","CGST Rate","CGST Amount","SGST Rate","SGST Amount","IGST Rate","IGST Amount","CESS Rate","CESS Amount","Is this Advance for a Bill of Supply?","Is Reverse Charge Applicable?","Is this document cancelled?","Is the customer a Composition dealer or UIN registered?","Return Filing Month","Return Filing Quarter","Original Advance Receipt Date (In case of amendment)","Original Advance Receipt Voucher Number (In case of amendment)","Original Customer Billing GSTIN (In case of amendment)","My GSTIN","Customer Billing Address","Customer Billing City","Customer Billing State","Total Transaction Value";
        ColumnLabel: Option A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,AA,AB,AC,AD,AE,AF,AG,AH,AI,AJ,AK,AL,AM,AN,AO,AP,AQ,AR,AS,AT,AU,AV,AW,AX,AY,AZ;
    begin
        CreateExcelBuffer(ExcelBuffer, 2, '2', 1, 'A', XLTxt11);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 5, 'E', XLTxt2);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 6, 'F', XLTxt3);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 14, 'N', XLTxt4);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 26, 'Z', XLTxt6);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 28, 'AB', XLTxt7);
        CreateExcelBuffer(ExcelBuffer, 2, '2', 35, 'AI', XLTxt9);
        for Counter := 0 to HeaderFields::"Total Transaction Value" do begin
            HeaderFields := Counter;
            ColumnLabel := Counter;
            CreateExcelBuffer(ExcelBuffer, 3, '3', Counter + 1, Format(ColumnLabel), Format(HeaderFields));
        end;
        Counter := 4;
        if GSTTransHeader.FindSet() then
            repeat
                GSTTransLine.SetRange("Transaction Type", GSTTransHeader."Transaction Type");
                GSTTransLine.SetRange("Document Type", GSTTransHeader."Document Type");
                GSTTransLine.SetRange("Document No.", GSTTransHeader."Document No.");
                if GSTTransLine.FindSet() then
                    repeat
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 1, 'A', Format(GSTTransHeader."Posting Date"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 2, 'B', Format(GSTTransHeader."Document No."));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 3, 'C', Format(GSTTransHeader."Buyer Name"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 4, 'D', Format(GSTTransHeader."Buyer GSTIN"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 5, 'E', Format(GSTTransHeader."Place of Supply"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 6, 'F', Format(GSTTransLine."GST Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 7, 'G', Format(GSTTransLine.Description));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 8, 'H', Format(GSTTransLine."GST Code"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 9, 'I', Format(GSTTransLine.Quantity));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 10, 'J', Format(GSTTransLine.UOM));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 11, 'K', Format(GSTTransLine."Unit Price"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 12, 'L', Format(GSTTransLine.Discount));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 13, 'M', Format(GSTTransLine."Taxable Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 14, 'N', Format(GSTTransLine."CGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 15, 'O', Format(GSTTransLine."CGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 16, 'P', Format(GSTTransLine."SGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 17, 'Q', Format(GSTTransLine."SGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 18, 'R', Format(GSTTransLine."IGST Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 19, 'S', Format(GSTTransLine."IGST Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 20, 'T', Format(GSTTransLine."Cess Rate"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 21, 'U', Format(GSTTransLine."Cess Value"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 22, 'V', Format(GSTTransHeader."Is Bill of Supply"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 23, 'W', Format(GSTTransHeader."Reverse Charge Applicable"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 24, 'X', Format(GSTTransHeader."Is Cancelled"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 25, 'Y', Format(GSTTransHeader."Customer Type"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 28, 'AB', Format(GSTTransHeader."Is Cancelled"));
                        //Reason for issuing CDN not added, pregst invoice not added.
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 31, 'AE', Format(GSTTransHeader."Seller GSTIN"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 32, 'AF', Format(GSTTransHeader."Buyer Address"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 33, 'AG', Format(GSTTransHeader."Buyer City"));
                        CreateExcelBuffer(ExcelBuffer, Counter, Format(Counter), 34, 'AH', Format(GSTTransHeader."Buyer State"));
                        //Return filing and amendment details not added.
                        //Total transaction value, applicable tax rate not added
                        Counter += 1;
                    until GSTTransLine.Next() = 0;
            until GSTTransHeader.NEXT = 0;
        ExcelBuffer.CreateNewBook('GSTR1 Advance Receipt');
        ExcelBuffer.WriteSheet('', '', UserId());
        ExcelBuffer.CloseBook();
        ExcelBuffer.OpenExcel();
        //ExcelBuffer.CreateBookAndOpenExcel('', 'GSTR1 Advance Receipt', '', '', UserId());
    end;

    local procedure CreateExcelBuffer(var ExcelBufferP: Record "Excel Buffer"; RowNoP: Integer; RowLabelP: Text; ColumnNoP: Integer; ColumnLabelP: Text; CellValueP: Text)
    begin
        ExcelBufferP.INIT;
        ExcelBufferP."Row No." := RowNoP;
        ExcelBufferP.xlRowID := RowLabelP;
        ExcelBufferP."Column No." := ColumnNoP;
        ExcelBufferP.xlColID := ColumnLabelP;
        ExcelBufferP."Cell Value as Text" := CellValueP;
        ExcelBufferP.Insert();
    end;

    local procedure GenerateOptions(var GSTTransHeaderP: Record "ClearComp GST Trans. Header"): Text
    var
        ExportOptions: Text;
    begin
        GSTTransHeaderP.SetRange("Document Type", GSTTransHeaderP."Document Type"::Invoice);
        GSTTransHeaderP.SetRange("Is Bill of Supply", FALSE);
        GSTTransHeaderP.SetRange("Is Advance", false);
        if GSTTransHeaderP.FindFirst() then
            CreateStringMenu(ExportOptions, Format(GSTTransHeaderP."Document Type"::Invoice));
        GSTTransHeaderP.SetRange("Is Bill of Supply", TRUE);
        if GSTTransHeaderP.FindFirst() then
            CreateStringMenu(ExportOptions, 'Bill of Supply');
        GSTTransHeaderP.SetRange("Is Bill of Supply");
        GSTTransHeaderP.SetRange("Document Type", GSTTransHeaderP."Document Type"::"Credit Memo");
        if GSTTransHeaderP.FindFirst() then
            CreateStringMenu(ExportOptions, Format(GSTTransHeaderP."Document Type"::"Credit Memo"));
        GSTTransHeaderP.SetRange("Document Type");
        GSTTransHeaderP.SetRange("Is Advance", true);
        if GSTTransHeaderP.FindFirst() then
            CreateStringMenu(ExportOptions, 'Advance');
        GSTTransHeaderP.SetRange("Is Advance");
        exit(ExportOptions);
    end;

    procedure CreateJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"ClearComp GST Management Unit");
        if not JobQueueEntry.FindFirst() then begin
            JobQueueEntry.InitRecurringJob(30);
            JobQueueEntry.ID := CreateGuid();
            JobQueueEntry.Validate("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
            JobQueueEntry.Validate("Object ID to Run", CODEUNIT::"ClearComp GST Management Unit");
            JobQueueEntry."Earliest Start Date/Time" := CURRENTDATETIME + 5 * 60 * 1000;
            JobQueueEntry.Validate(Status, JobQueueEntry.Status::Ready);
            JobQueueEntry."User ID" := UserId();
            JobQueueEntry.Insert();
        END;
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"ClearComp GST JobQueue Unit");
        if not JobQueueEntry.FindFirst() then begin
            CLEAR(JobQueueEntry);
            JobQueueEntry.InitRecurringJob(30); // this job is used to run the above job queue if it goes into error status.
            JobQueueEntry.ID := CreateGuid();
            JobQueueEntry.Validate("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
            JobQueueEntry.Validate("Object ID to Run", CODEUNIT::"ClearComp GST JobQueue Unit");
            JobQueueEntry.Validate(Status, JobQueueEntry.Status::Ready);
            JobQueueEntry."Earliest Start Date/Time" := CURRENTDATETIME + 6 * 60 * 1000;
            JobQueueEntry."User ID" := UserId();
            JobQueueEntry.Insert();
        END;
    end;

    procedure DeleteJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetFilter("Object ID to Run", '%1|%2', CODEUNIT::"ClearComp GST Management Unit", CODEUNIT::"ClearComp GST JobQueue Unit");
        IF JobQueueEntry.FindSet() THEN
            JobQueueEntry.DeleteAll();
    end;

    procedure DeleteSelectedInvoices(NoP: code[20])
    var
        Position: Integer;
        DocNo: Text;
    begin
        GSTSetup.Get();
        GSTTransHeader.SetRange("Return Filed", FALSE);
        GSTTransHeader.SetRange("Document Type", GSTTransHeader."Document Type"::Invoice);
        GSTTransHeader.SetRange(Status, GSTTransHeader.Status::Synced);
        GSTTransHeader.SetRange("Is Bill of Supply", FALSE);
        GSTTransHeader.SetRange("Document No.", NoP);
        GSTTransHeader.SetRange(Selected, TRUE);
        if GSTTransHeader.FindFirst() then begin
            Position := StrPos(GSTTransHeader."Document No.", '/');
            DocNo := GSTTransHeader."Document No.";
            DocNo := DocNo.Replace('/', '$2F');
            PrepareSendMessage('Delete', '', 'v0.1', GSTTransHeader."Seller/Buyer Taxable entity", 'invoices', DocNo, true, false);
        end;
    end;

    local procedure CreateStringMenu(var MenuP: Text; OptionP: Text)
    begin
        if MenuP > '' then
            MenuP += ',' + OptionP
        else
            MenuP := OptionP;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', true, false)]
    local procedure CreateTransEntrySales(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20])
    var
        TransactionTypeL: Option Sales,Purchase;
        DocumentTypeL: Option Invoice,"Credit Memo";
        EInvMgmt: Codeunit "e-Invoice Management";
    begin
        if SalesInvHdrNo > '' then
            if EInvMgmt.IsGSTApplicable(SalesInvHdrNo, Database::"Sales Invoice Header") then
                InsertSyncEntry(TransactionTypeL::Sales, DocumentTypeL::Invoice, SalesInvHdrNo, SalesHeader."Posting Date");
        if SalesCrMemoHdrNo > '' then
            if EInvMgmt.IsGSTApplicable(SalesCrMemoHdrNo, Database::"Sales Cr.Memo Header") then
                InsertSyncEntry(TransactionTypeL::Sales, DocumentTypeL::"Credit Memo", SalesCrMemoHdrNo, SalesHeader."Posting Date");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', true, false)]
    local procedure CreateTransEntryPurchase(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20])
    var
        TransactionTypeL: Option Sales,Purchase;
        DocumentTypeL: Option Invoice,"Credit Memo";
        EInvMgmt: Codeunit "e-Invoice Management";
    begin
        if PurchInvHdrNo > '' then
            if EInvMgmt.IsGSTApplicable(PurchInvHdrNo, Database::"Purch. Inv. Header") then
                InsertSyncEntry(TransactionTypeL::Purchase, DocumentTypeL::Invoice, PurchInvHdrNo, PurchaseHeader."Posting Date");
        if PurchCrMemoHdrNo > '' then
            if EInvMgmt.IsGSTApplicable(PurchCrMemoHdrNo, Database::"Purch. Cr. Memo Hdr.") then
                InsertSyncEntry(TransactionTypeL::Purchase, DocumentTypeL::"Credit Memo", PurchCrMemoHdrNo, PurchaseHeader."Posting Date");
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterValidateEvent', 'GST Registration No.', true, false)]
    local procedure OnAfterValidateCustomerGSTNo(var Rec: Record Customer; VAR xRec: Record Customer; CurrFieldNo: Integer)
    var
        Location: Record Location;
        OutStrm: OutStream;
    begin
        if not GSTSetup.Get() then
            exit;
        if (GSTSetup."GST Base Url" = '') or (GSTSetup."Auth. Token" = '') then
            exit;
        if Rec."GST Registration No." > '' then begin
            Location.GET(Rec."Location Code");
            PrepareSendMessage('GET', '', 'v0.2', Location."Taxable Entity", 'gstin_verification?gstin=', Rec."GST Registration No.", false, true);
            Rec."GSTIN Details from ClearTax".CreateOutStream(OutStrm);
            OutStrm.WriteText(ResponseText);
            Rec.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterValidateEvent', 'GST Registration No.', true, false)]
    local procedure OnAfterValidateVendorGSTNo(var Rec: Record Vendor; var xRec: Record Vendor; CurrFieldNo: Integer)
    var
        Location: Record Location;
        OutStrm: OutStream;
    begin
        if not GSTSetup.Get() then
            exit;
        if (GSTSetup."GST Base Url" = '') or (GSTSetup."Auth. Token" = '') then
            exit;
        if Rec."GST Registration No." > '' then begin
            Location.Get(Rec."Location Code");
            PrepareSendMessage('GET', '', 'v0.2', Location."Taxable Entity", 'gstin_verification?gstin=', Rec."GST Registration No.", false, true);
            Rec."GSTIN Details from ClearTax".CreateOutStream(OutStrm);
            OutStrm.WriteText(ResponseText);
            Rec.Modify();
        end;
    end;

    local procedure InsertSyncEntry(TransactionTypeP: Option SALE,PURCHASE; DocumentTypeP: Option Invoice,"Credit Memo"; DocumentNoP: Code[20]; PostDateP: Date)
    var
        GSTTransHeader: Record "ClearComp GST Trans. Header";
        InvoiceTypeSales: Option ,"Bill of Supply",Export,Supplementary,"Debit Note","Non-GST",Taxable;
        InvoiceTypePurchase: Option ,"Self Invoice","Debit Note","Supplementary","Non-GST";
    begin
        GSTSetup.Get();
        GSTTransHeader.Init();
        GSTTransHeader."Transaction Type" := TransactionTypeP;
        GSTTransHeader."Document Type" := DocumentTypeP;
        GSTTransHeader."Document No." := DocumentNoP;
        GSTTransHeader."Posting Date" := PostDateP;
        if GSTTransHeader.Insert() then
            ;
        if GSTSetup."Sync Invoices" = GSTSetup."Sync Invoices"::"While Posting" then begin
            GSTTransHeader."While Posting" := true;
            GSTTransHeader.Modify();
            if not SyncInvoicesWhilePosting() then
                Message(GetLastErrorText());
            if GSTTransHeader.Get(GSTTransHeader."Transaction Type", GSTTransHeader."Document Type", GSTTransHeader."Document No.") then begin
                Clear(GSTTransHeader."While Posting");
                GSTTransHeader.Modify();
            end;
        end;
    end;

    local procedure SyncInvoicesWhilePosting(): Boolean
    var
        GSTManagementUnit: Codeunit "ClearComp GST Management Unit";
    begin
        Commit();
        if GSTManagementUnit.Run() then
            exit(true);
    end;

    local procedure PrepareSendMessage(MethodP: Text; MessageTextP: Text; VersionP: Text; TaxableEntityP: Text; TransactionTpeP: Text; DocNoP: Code[30]; IsDeleteInvoiceP: Boolean; IsGSTValidation: Boolean)
    var
        URL: Text;
        Position: Integer;
        DummyTxt: Text;
    begin
        GSTSetup.Get();
        case true of
            IsDeleteInvoiceP:
                URL := GSTSetup."GST Base Url" + 'api/' + VersionP + '/taxable_entities/' + TaxableEntityP + '/' + TransactionTpeP + '/' + DocNoP + '?source=USER&delete=true';
            IsGSTValidation:
                URL := GSTSetup."GST Base Url" + 'api/' + VersionP + '/taxable_entities/' + TaxableEntityP + '/' + TransactionTpeP + DocNoP;
            else begin
                Position := StrPos(DocNoP, '/');
                DummyTxt := DocNoP;
                DocNoP := DummyTxt.Replace('/', '$2F');
                URL := GSTSetup."GST Base Url" + 'api/' + VersionP + '/taxable_entities/' + TaxableEntityP + '/' + TransactionTpeP + '/' + DocNoP;
            end;
        end;
        SendMessage(URL, MessageTextP, GSTSetup."Auth. Token", MethodP);
    end;

    local procedure SendMessage(UrlP: Text; MessageTextP: Text; AccessTokenP: Text; MethodP: Text)
    var
        HttpSendMessage: Codeunit "ClearComp Http Send Message";
        HttpResponseJobject: JsonObject;
        HttpReqMessage: HttpRequestMessage;
        HttpResMessage: HttpResponseMessage;
        outstreamL: OutStream;
    begin
        clear(HttpSendMessage);
        Clear(ResponseText);
        HttpSendMessage.SetContentType('application/json');
        HttpSendMessage.SetHttpHeader('X-ClearTax-AUTH-TOKEN', AccessTokenP);

        HttpSendMessage.SetMethod(MethodP);
        ResponseText := HttpSendMessage.SendRequest(UrlP, MessageTextP);
        CreateMessageLog(MethodP, MessageTextP, Format(HttpSendMessage.StatusCode()), UrlP);
        GSTTransHeader.Request.CreateOutStream(outstreamL);
        outstreamL.WriteText(MessageTextP);
        Clear(outstreamL);
        GSTTransHeader.Response.CreateOutStream(outstreamL);
        if ResponseText <> '' then
            outstreamL.WriteText(ResponseText)
        else
            outstreamL.WriteText(format(HttpSendMessage.StatusCode()) + '-' + HttpSendMessage.Reason());
        GSTTransHeader.Modify();
        // if not HttpSendMessage.IsSuccess() then
        //     Error(ResponseText);
        CheckErrorResponse(MethodP);
    end;

    local procedure CreateMessageLog(MethodP: Text; MessageTextP: Text; StatusCodeP: Text; UrlP: Text)
    var
        InterfMessageLog: Record "ClearComp Interf. Message Log";
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

    local procedure CheckErrorResponse(MethodP: Text)
    var
        Jobject: JsonObject;
        JSubObject: JsonObject;
        JToken: JsonToken;
    begin
        if Jobject.ReadFrom(ResponseText) then begin
            // Display error msg if GSTIN validation fails
            if MethodP.ToLower() = 'get' then begin
                if Jobject.Contains('success') then
                    if GetValueFromJsonObject(Jobject, 'success').AsText().ToLower() = 'false' then
                        Message(GetValueFromJsonObject(Jobject, 'success').AsText());
            end;
            // Change Transaction header Status based on response received
            if Jobject.Contains('errors') then begin
                Jobject.Get('errors', JToken);
                Jobject := JToken.AsObject();
                if Jobject.Get('err_1', JToken) then
                    JSubObject := JToken.AsObject();
                if JSubObject.Contains('code') then
                    if GetValueFromJsonObject(JSubObject, 'code').IsNull then begin
                        if MethodP.ToLower() = 'delete' then begin
                            GSTTransHeader.Status := GSTTransHeader.Status::Deleted;
                            Clear(GSTTransHeader."Matched Status");
                            Clear(GSTTransHeader."Match Status Description");
                            Clear(GSTTransHeader."Matching at PAN/GSTIN");
                            Clear(GSTTransHeader."MisMatched Fields");
                            Clear(GSTTransHeader."MisMatched Fields count");
                        end;
                        Clear(GSTTransHeader.Selected);
                        GSTTransHeader.Modify();
                    end else begin
                        if MethodP.ToLower() <> 'delete' then begin
                            GSTTransHeader.Status := GSTTransHeader.Status::Error;
                            GSTTransHeader.Modify();
                        end;
                        if ErrorG > '' then
                            ErrorG += ',' + GSTTransHeader."Document No."
                        else
                            ErrorG += GSTTransHeader."Document No.";
                    end;
                if (MethodP.ToLower() = 'delete') and (ErrorG > '') then
                    Message(ErrorFound, ErrorG);
            end else begin
                GSTTransHeader.Status := GSTTransHeader.Status::Synced;
                Clear(GSTTransHeader.Selected);
                GSTTransHeader.Modify();
            end;
        end;
    end;


    local procedure GetLastEntryNo(): Integer
    var
        InterfMessageLog: Record "ClearComp Interf. Message Log";
    begin
        if InterfMessageLog.FindLast() then
            exit(InterfMessageLog."Entry No." + 10000)
        else
            exit(10000);
    end;

    procedure GetGSTINDetails(Var ArrP: array[5] of Text; var RecRefP: RecordRef; var ArrayVisibleP: Boolean)
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        GSTNoValidationMsg: Text;
        Instrm: InStream;
    begin
        case RecRefP.Number() of
            Database::Vendor:
                begin
                    RecRefP.SetTable(Vendor);
                    Vendor.CalcFields("GSTIN Details from ClearTax");
                    Vendor."GSTIN Details from ClearTax".CreateInStream(Instrm);
                    Instrm.ReadText(GSTNoValidationMsg);
                    ReadGSTINDetails(GSTNoValidationMsg, ArrP, ArrayVisibleP);
                end;
            Database::Customer:
                begin
                    RecRefP.SetTable(Customer);
                    Customer.CalcFields("GSTIN Details from ClearTax");
                    Customer."GSTIN Details from ClearTax".CreateInStream(Instrm);
                    Instrm.ReadText(GSTNoValidationMsg);
                    ReadGSTINDetails(GSTNoValidationMsg, ArrP, ArrayVisibleP);
                end;
        end;
    end;

    local procedure ReadGSTINDetails(GSTNoValidationMsgP: Text; Var ArrP: array[5] of Text; var ArrayVisibleP: Boolean)
    var
        JObject: JsonObject;
    begin
        if JObject.ReadFrom(GSTNoValidationMsgP) then begin
            Clear(GSTNoValidationMsgP);
            if JObject.Contains('success') then begin
                if GetValueFromJsonObject(JObject, 'success').AsText().ToLower() = 'false' then
                    if JObject.Contains('message') and (GetValueFromJsonObject(JObject, 'message').AsText() > '') then
                        ArrP[1] := GetValueFromJsonObject(JObject, 'message').AsText()
            end else begin
                if JObject.Contains('sts') then
                    ArrP[1] := GetValueFromJsonObject(JObject, 'sts').AsText();
                if JObject.Contains('lgnm') then
                    ArrP[2] := GetValueFromJsonObject(JObject, 'lgnm').AsText();
                if JObject.Contains('tradeNam') then
                    ArrP[3] := GetValueFromJsonObject(JObject, 'tradeNam').AsText();
                if JObject.Contains('pradr.addr.bnm') then
                    ArrP[4] := GetValueFromJsonObject(JObject, 'pradr.addr.bnm').AsText();
                if JObject.Contains('pradr.addr.st') then
                    ArrP[4] += ',' + GetValueFromJsonObject(JObject, 'pradr.addr.st').AsText();
                if JObject.Contains('pradr.addr.loc') then
                    ArrP[4] += ',' + GetValueFromJsonObject(JObject, 'pradr.addr.loc').AsText();
                if JObject.Contains('pradr.addr.bno') then
                    ArrP[4] += ',' + GetValueFromJsonObject(JObject, 'pradr.addr.bno').AsText();
                if JObject.Contains('pradr.addr.stcd') then
                    ArrP[4] += ',' + GetValueFromJsonObject(JObject, 'pradr.addr.stcd').AsText();
                if JObject.Contains('pradr.addr.dst') then
                    ArrP[4] += ',' + GetValueFromJsonObject(JObject, 'pradr.addr.dst').AsText();
                if JObject.Contains('pradr.addr.pncd') then
                    ArrP[4] += ',' + GetValueFromJsonObject(JObject, 'pradr.addr.pncd').AsText();
                ArrayVisibleP := true;
            end;
        end else
            ArrP[1] := GSTNoValidationMsgP;
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

    local procedure UpdatetransHeader()
    var
        SalesInvHeaderL: Record "Sales Invoice Header";
        SalesCrMemoHdrL: Record "Sales Cr.Memo Header";
        PurchInvHeaderL: Record "Purch. Inv. Header";
        PurchCrMemoHdrL: Record "Purch. Cr. Memo Hdr.";
        einvoiceMgmt: Codeunit "e-Invoice Management";
    begin
        if (FromDate <> 0D) and (ToDate <> 0D) then begin
            SalesInvHeaderL.SETRANGE("Posting Date", FromDate, ToDate);
            SalesCrMemoHdrL.SETRANGE("Posting Date", FromDate, ToDate);
            PurchInvHeaderL.SETRANGE("Posting Date", FromDate, ToDate);
            PurchCrMemoHdrL.SETRANGE("Posting Date", FromDate, ToDate);
        end;
        if DocNoG <> '' then begin
            SalesInvHeaderL.SetRange("No.", DocNoG);
            SalesCrMemoHdrL.SetRange("No.", DocNoG);
            PurchInvHeaderL.SetRange("No.", DocNoG);
            PurchCrMemoHdrL.SetRange("No.", DocNoG);
        end;
        IF SalesInvHeaderL.FINDSET THEN
            REPEAT
                if einvoiceMgmt.IsGSTApplicable(SalesInvHeaderL."No.", Database::"Sales Invoice Header") then
                    InsertTransEntry(GSTTransHeader."Transaction Type"::SALE, GSTTransHeader."Document Type"::Invoice, SalesInvHeaderL."No.", SalesInvHeaderL."Posting Date");
            UNTIL SalesInvHeaderL.NEXT = 0;

        IF SalesCrMemoHdrL.FINDSET THEN
            REPEAT
                if einvoiceMgmt.IsGSTApplicable(SalesCrMemoHdrL."No.", Database::"Sales Cr.Memo Header") then
                    InsertTransEntry(GSTTransHeader."Transaction Type"::SALE, GSTTransHeader."Document Type"::"Credit Memo", SalesCrMemoHdrL."No.", SalesCrMemoHdrL."Posting Date");
            UNTIL SalesCrMemoHdrL.NEXT = 0;

        IF PurchInvHeaderL.FINDSET THEN
            REPEAT
                if einvoiceMgmt.IsGSTApplicable(PurchInvHeaderL."No.", Database::"Purch. Inv. Header") then
                    InsertTransEntry(GSTTransHeader."Transaction Type"::PURCHASE, GSTTransHeader."Document Type"::Invoice, PurchInvHeaderL."No.", PurchInvHeaderL."Posting Date");
            UNTIL PurchInvHeaderL.NEXT = 0;

        IF PurchCrMemoHdrL.FINDSET THEN
            REPEAT
                if einvoiceMgmt.IsGSTApplicable(PurchCrMemoHdrL."No.", Database::"Purch. Cr. Memo Hdr.") then
                    InsertTransEntry(GSTTransHeader."Transaction Type"::PURCHASE, GSTTransHeader."Document Type"::"Credit Memo", PurchCrMemoHdrL."No.", PurchCrMemoHdrL."Posting Date");
            UNTIL PurchCrMemoHdrL.NEXT = 0;
    end;

    local procedure InsertTransEntry(TransactionTypeP: Option; DocumentTypeP: Option; DocNumberP: Code[20]; PostDateP: Date)
    var
        TransHeaderL: Record "ClearComp GST Trans. Header";
    begin
        TransHeaderL.Init();
        TransHeaderL."Transaction Type" := TransactionTypeP;
        TransHeaderL."Document Type" := DocumentTypeP;
        TransHeaderL."Document No." := DocNumberP;
        TransHeaderL."Posting Date" := PostDateP;
        if not TransHeaderL.Insert() then
            ;
    end;

    local procedure ValidateResponse(Var JObject: JsonObject)
    begin

    end;

    var
        DocNoG: Code[20];
        FromDate: Date;
        ToDate: Date;
        Manual: Boolean;
        ErrorG: Text;
        ResponseText: Text;
        GSTSetup: Record "ClearComp GST Setup";
        GSTTransHeader: Record "ClearComp GST Trans. Header";
        XLTxt1: Label '*Invoice details';
        XLTxt2: Label '*This is the destination of the product, typically the state of your customer';
        XLTxt3: Label '*Provide these details for HSN summary under GST Return flow';
        XLTxt4: Label '*Tax details (Invoice should have either CGST & SGST or IGST value based of Place of Supply)';
        XLTxt5: Label 'Mandatory incase of Exports of Goods';
        XLTxt6: Label 'Mandatory, in case this invoice is filed as a part of previous return period';
        XLTxt7: Label '*Mandatory incase of Amendment of Invoice';
        XLTxt8: Label '*Mandatory if advance receipts are adjusted against invoices raised';
        XLTxt9: Label '*Enter total invoice value, If you have more than one line in the invoice, repeat the same value for every line';
        XLTxt10: Label '*Credit/Debit Note details';
        XLTxt11: Label '*Advance Receipt details';
        XLTxt12: Label '*Mandatory incase of claim ITC under GSTR-2 flow  , Please mark "ITC Claim" as "None" in case you do not want to claim ITC  on the invoice.  If you leave the filed blank, it will be automatically considered it as "Input"';
        XLTxt13: Label '*Mandatory incase of Import of Goods';
        XLTxt14: Label '*This is destination of the product, typically your state';
        XLTxt15: Label 'Invoice Reference No.';
        XLTxt16: Label 'Vendor No.';
        XLTxt17: Label 'Posting Date';
        XLTxt18: Label 'Remarks 2';
        NoDataError: Label 'No transaction data found in the filter range %1 to %2';
        SyncedError: Label 'The transaction data within the filter range %1 to %2 is already synced';
        NotSelectedErr: Label 'No Selected transactional data found';
        ErrorFound: Label 'Errors found while Sending data to ClearTAX, Check the Message Log for further details';
        UploadXLMessage: Label 'Please choose the Excel File';

        AllowCharacters: Label 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890/\-';
}