codeunit 50111 "Clear Generate Sales Inv data"
{
    var
        GeneralFunctions: Codeunit "Clear General functions";
        TransHdr: Record "Clear Trans Hdr";


    procedure ReadDetails(SalesInvHdrP: Record "Sales Invoice Header")
    begin
        Clear(TransHdr);
        if not GeneralFunctions.IsGSTApplicable(SalesInvHdrP."No.", Database::"Sales Invoice Header") then
            exit;

        ReadHeaderDetails(SalesInvHdrP);
        ReadSupplierDetails(SalesInvHdrP);
        ReadReceiverDetails(SalesInvHdrP);
        ReadLineDetails();
        ReadExportDetails(SalesInvHdrP);
        TransHdr.Modify();
    end;

    local procedure ReadHeaderDetails(salesInvHdrP: Record "Sales Invoice Header")
    var
        customer: Record Customer;
    begin
        TransHdr."Transaction Type" := Enum::"Clear Transaction type"::sale;
        if salesInvHdrP."Prepayment Order No." > '' then
            TransHdr."Document Type" := Enum::"Clear Document Type"::Advance
        else
            TransHdr."Document Type" := Enum::"Clear Document Type"::Invoice;
        TransHdr."Document No." := SalesInvHdrP."No.";
        if not TransHdr.Insert() then;
        TransHdr."Posting date" := salesInvHdrP."Posting Date";
        if salesInvHdrP."Invoice Type" in [salesInvHdrP."Invoice Type"::"Bill of Supply", salesInvHdrP."Invoice Type"::"Non-GST"] then
            TransHdr."Is bill of supply" := true;
        TransHdr."Is reverse charge applicable" := GeneralFunctions.IsReverseChargeApplicable(salesInvHdrP."No.", Enum::"GST Document Type"::Invoice);
        TransHdr."Place of Supply" := getPlaceofSupply(salesInvHdrP);
        if customer.get(salesInvHdrP."E-Commerce Customer") then
            TransHdr."Ecommerce GSTIN" := customer."GST Registration No.";

    end;

    local procedure ReadSupplierDetails(SalesInvHdrP: Record "Sales Invoice Header")
    var
        companyInformation: Record "Company Information";
        state: Record State;
        location: Record Location;
    begin
        companyInformation.get();
        TransHdr."Supplier Name" := companyInformation.Name;
        TransHdr."Supplier GSTIN" := SalesInvHdrP."Location GST Reg. No.";
        if location.Get(SalesInvHdrP."Location Code") then begin
            TransHdr."Supplier Address" := location.Address;
            if state.Get(location."State Code") then
                TransHdr."Supplier State" := state.Code;
        end;

    end;

    local procedure ReadReceiverDetails(SalesInvHdrP: Record "Sales Invoice Header")
    var
        ShipToAddress: Record "Ship-to Address";
        Customer: Record customer;
        SalesInvoiceLine: Record "Sales Invoice Line";
        State: Record State;
    begin
        TransHdr."Receiver Name" := SalesInvHdrP."Bill-to Name";
        if SalesInvHdrP."Customer GST Reg. No." <> '' then begin
            TransHdr."Receiver GSTIN" := SalesInvHdrP."Customer GST Reg. No.";
        end else begin
            if ShipToAddress.Get(SalesInvHdrP."Bill-to Customer No.", SalesInvHdrP."Ship-to Code") and (ShipToAddress."GST Registration No." > '') then
                TransHdr."Receiver GSTIN" := ShipToAddress."GST Registration No."
            else
                if Customer.Get(SalesInvHdrP."Bill-to Customer No.") then
                    TransHdr."Receiver GSTIN" := Customer."GST Registration No.";
        end;
        TransHdr."Receiver address" := SalesInvHdrP."Bill-to Address";
        SalesInvoiceLine.SetRange("Document No.", SalesInvHdrP."No.");
        SalesInvoiceLine.SetFilter("No.", '<>%1', '');
        SalesInvoiceLine.SetFilter(Quantity, '<>%1', 0);
        if SalesInvoiceLine.FindFirst() then
            if SalesInvoiceLine."GST Place of Supply" in [SalesInvoiceLine."GST Place of Supply"::"Bill-to Address",
                SalesInvoiceLine."GST Place of Supply"::"Location Address"]
            then begin
                if not (SalesInvHdrP."GST Customer Type" = SalesInvHdrP."GST Customer Type"::Export) then
                    if state.Get(SalesInvHdrP."GST Bill-to State Code") then
                        TransHdr."Receiver State" := state."State Code (GST Reg. No.)";
            end else
                if SalesInvoiceLine."GST Place of Supply" = SalesInvoiceLine."GST Place of Supply"::"Ship-to Address" then begin
                    if not (SalesInvHdrP."GST Customer Type" = SalesInvHdrP."GST Customer Type"::Export) then
                        if state.Get(SalesInvHdrP."GST Ship-to State Code") then
                            TransHdr."Receiver State" := state."State Code (GST Reg. No.)";
                end;
        if TransHdr."Receiver State" = '' then
            TransHdr."Receiver State" := '96';
        TransHdr."Customer TaxpayerType" := GeneralFunctions.GetCustomertype(salesInvHdrP."Sell-to Customer No.");
    end;

    local procedure ReadExportDetails(SalesInvHdrP: Record "Sales Invoice Header")
        TransLine: Record "Clear Trans line";
    begin
        if SalesInvHdrP."Invoice Type" = SalesInvHdrP."Invoice Type"::Export then begin
            case SalesInvHdrP."Ship-to GST Customer Type" of
                SalesInvHdrP."Ship-to GST Customer Type"::Export:
                    TransHdr."Export Type" := TransHdr."Export Type"::EXPWP;
                SalesInvHdrP."Ship-to GST Customer Type"::"Deemed Export":
                    TransHdr."Export Type" := TransHdr."Export Type"::DEXP
            end;
            if SalesInvHdrP."Ship-to GST Customer Type" in [SalesInvHdrP."Ship-to GST Customer Type"::"SEZ Unit",
                SalesInvHdrP."Ship-to GST Customer Type"::"SEZ Development"]
            then begin
                TransLine.SetRange("Transaction Type", TransHdr."Transaction Type");
                TransLine.SetRange("Document Type", TransHdr."Document Type");
                TransLine.SetRange("Document No.", TransHdr."Document No.");
                TransLine.SetRange("IGST Rate", 0);
                if TransLine.FindFirst() then
                    TransHdr."Export Type" := TransHdr."Export Type"::SEZWOP
                else
                    TransHdr."Export Type" := TransHdr."Export Type"::SEZWP
            end;
            if SalesInvHdrP."Bill Of Export No." > '' then
                TransHdr."Export bill no." := SalesInvHdrP."Bill Of Export No.";
            if SalesInvHdrP."Bill Of Export Date" <> 0D then
                TransHdr."Export bill date" := SalesInvHdrP."Bill Of Export Date";
            if SalesInvHdrP."Exit Point" > '' then
                TransHdr."Export Port Code" := SalesInvHdrP."Exit Point";
        end;
    end;

    local procedure ReadLineDetails()
    var
        TransLine: Record "Clear Trans line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CustomerPostingGroup: Record "Customer Posting Group";
        HSNSAC: Record "HSN/SAC";
        UQCValues: Record "Unit of Measure";
    begin
        TransLine.SetRange("Transaction Type", TransHdr."Transaction Type");
        TransLine.SetRange("Document Type", TransHdr."Document Type");
        TransLine.SetRange("Document No.", TransHdr."Document No.");
        if TransLine.FindFirst() then
            TransLine.DeleteAll();
        SalesInvoiceLine.SetRange("Document No.", TransHdr."Document No.");
        SalesInvoiceLine.SetFilter("No.", '<>%1', '');
        SalesInvoiceLine.SetFilter(Quantity, '<>%1', 0);
        SalesInvoiceLine.SetRange("System-Created Entry", false);
        if SalesInvoiceLine.FindSet() then
            repeat
                Clear(TransLine);
                TransLine."Transaction Type" := TransHdr."Transaction Type";
                TransLine."Document Type" := TransHdr."Document Type";
                TransLine."Document No." := TransHdr."Document No.";
                TransLine."Line num" := SalesInvoiceLine."Line No.";
                TransLine."Item no" := SalesInvoiceLine."No.";
                TransLine."Item description" := SalesInvoiceLine.Description;
                TransLine."Item quantity" := SalesInvoiceLine.Quantity;
                TransLine."Unit Price" := SalesInvoiceLine."Unit Price";
                if UQCValues.Get(SalesInvoiceLine."Unit of Measure Code") then
                    TransLine.UOM := UQCValues."Clear UQC values"
                else
                    TransLine.UOM := SalesInvoiceLine."Unit of Measure Code";
                TransLine.Discount := SalesInvoiceLine."Line Discount Amount";
                if not TransHdr."Is bill of supply" then
                    GeneralFunctions.GetGSTCompRate(TransLine);
                TransLine."HSNSAC Code" := SalesInvoiceLine."HSN/SAC Code";
                if HSNSAC.Get(SalesInvoiceLine."GST Group Code", TransLine."HSNSAC Code") then begin
                    if HSNSAC.Type = HSNSAC.Type::HSN then
                        TransLine."Item category" := Enum::"Clear Item Category"::G
                    else
                        TransLine."Item category" := Enum::"Clear Item Category"::S;
                end;
                if SalesInvoiceLine.Exempted then
                    TransLine."Zero tax category" := Enum::"Clear Zero Tax Category"::EXEMPTED
                else
                    if SalesInvoiceLine."Non-GST Line" then
                        TransLine."Zero tax category" := Enum::"Clear Zero Tax Category"::NON_GST_SUPPLY;
                if ((TransLine."CGST amt" <= 0) and (TransLine."SGST amt" <= 0) and (TransLine."IGST amt" <= 0) and (TransLine."Zero tax category" = TransLine."Zero tax category"::None)) then begin
                    TransLine."Zero tax category" := Enum::"Clear Zero Tax Category"::NIL_RATED;
                end;
                if TransLine."Zero tax category" <> TransLine."Zero tax category"::None then begin
                    Clear(TransLine."CGST rate");
                    Clear(TransLine."SGST rate");
                    Clear(TransLine."Cess rate");
                    Clear(TransLine."IGST rate");
                    Clear(TransLine."CGST amt");
                    Clear(TransLine."SGST amt");
                    Clear(TransLine."Cess amt");
                    Clear(TransLine."IGST amt");
                end;
                TransLine."Line num" := GeneralFunctions.GetTransLineNo(TransLine."Transaction Type", TransLine."Document Type", TransLine."Document No.");
                TransLine.Insert();
            until SalesInvoiceLine.Next() = 0;

    end;

    //++++++++++++++++++++++++++++++++++++++++ Returns place of supply ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    local procedure getPlaceofSupply(SalesInvHdrP: Record "Sales Invoice Header"): Text
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        state: Record State;
        Customer: Record Customer;
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvHdrP."No.");
        SalesInvoiceLine.SetFilter("GST Place of Supply", '<>%1', SalesInvoiceLine."GST Place of Supply"::" ");
        if SalesInvoiceLine.FindFirst() then begin
            case SalesInvoiceLine."GST Place of Supply" of
                SalesInvoiceLine."GST Place of Supply"::"Ship-to Address":
                    if State.Get(SalesInvHdrP."GST Ship-to State Code") then
                        ;
                SalesInvoiceLine."GST Place of Supply"::"Location Address":
                    if State.Get(SalesInvHdrP."Location State Code") then
                        ;
                SalesInvoiceLine."GST Place of Supply"::"Bill-to Address":
                    if State.Get(SalesInvHdrP."GST Bill-to State Code") then
                        ;
            end;
            if State."State Code (GST Reg. No.)" <> '' then
                exit(State."State Code (GST Reg. No.)");
        end;
        if Customer.get(SalesInvHdrP."Bill-to Customer No.") then
            if State.Get(Customer."State Code") and (State."State Code (GST Reg. No.)" > '') then // Change in Nav16
                exit(State."State Code (GST Reg. No.)");
    end;

    //-------------------------------------------end of function -------------------------------------------------------------------
}