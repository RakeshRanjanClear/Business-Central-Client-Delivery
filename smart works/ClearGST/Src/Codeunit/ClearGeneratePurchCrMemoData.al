codeunit 60001 "Clear Generate Purch Cr. memo"
{
    var
        TransHdr: Record "Clear Trans Hdr";
        GeneralFunctions: Codeunit "Clear General functions";

    procedure ReadDetails(PurchCrHdrP: Record "Purch. Cr. Memo Hdr.")
    begin
        TransHdr.SetRange("Transaction Type", Enum::"Clear Transaction type"::Purchase);
        TransHdr.SetFilter("Document Type", '%1|%2', Enum::"Clear Document Type"::Invoice, Enum::"Clear Document Type"::Advance);
        TransHdr.SetRange("Document No.", PurchCrHdrP."No.");
        if TransHdr.FindFirst() then
            if TransHdr."Process Manually" then
                exit;
        Clear(TransHdr);
        if not GeneralFunctions.IsGSTApplicable(PurchCrHdrP."No.", Database::"Purch. Cr. Memo Hdr.") then
            exit;
        ReadHeaderDetails(PurchCrHdrP);
        ReadSupplierDetails(PurchCrHdrP);
        ReadReceiverDetails(PurchCrHdrP);
        ReadLineDetails(PurchCrHdrP);
        TransHdr.Modify();
    end;

    local procedure ReadHeaderDetails(PurchCrHdrP: Record "Purch. Cr. Memo Hdr.")
    var
        vendor: Record Vendor;
        PurchInvHdr: Record "Purch. Inv. Header";
    begin
        TransHdr."Transaction Type" := Enum::"Clear Transaction type"::Purchase;
        if PurchCrHdrP."Prepayment Order No." > '' then
            TransHdr."Document Type" := Enum::"Clear Document Type"::Advance
        else
            TransHdr."Document Type" := Enum::"Clear Document Type"::Debit;
        TransHdr."Document No." := PurchCrHdrP."No.";
        if not TransHdr.Insert() then;
        TransHdr."Posting date" := PurchCrHdrP."Posting Date";
        if PurchCrHdrP."Invoice Type" in [PurchCrHdrP."Invoice Type"::"Non-GST"] then
            TransHdr."Is bill of supply" := true;
        TransHdr."Is reverse charge applicable" := GeneralFunctions.IsReverseChargeApplicable(PurchCrHdrP."No.", Enum::"GST Document Type"::"Credit Memo");
        TransHdr."Place of Supply" := getPlaceofSupply(PurchCrHdrP);
        if PurchInvHdr.Get(PurchCrHdrP."Reference Invoice No.") then begin
            TransHdr."Linked invoice no." := PurchInvHdr."No.";
            TransHdr."Linked invoice date" := PurchInvHdr."Posting Date";
        end;
    end;

    local procedure ReadSupplierDetails(PurchCrHdrP: Record "Purch. Cr. Memo Hdr.")
    var
        OrderAddress: Record "Order Address";
        State: Record State;
        Vendor: Record Vendor;
    begin
        if (PurchCrHdrP."Order Address Code" > '') and (OrderAddress.Get(PurchCrHdrP."Buy-from Vendor No.", PurchCrHdrP."Order Address Code")) then begin
            TransHdr."Supplier Name" := OrderAddress.Name;
            TransHdr."Supplier GSTIN" := OrderAddress."GST Registration No.";
            TransHdr."Supplier Address" := OrderAddress.Address;
            if State.GET(OrderAddress.State) then
                TransHdr."Supplier State" := State."State Code (GST Reg. No.)";
        end else begin
            if Vendor.Get(PurchCrHdrP."Buy-from Vendor No.") then;
            TransHdr."Supplier Name" := PurchCrHdrP."Buy-from Vendor Name";
            TransHdr."Supplier GSTIN" := Vendor."GST Registration No.";
            TransHdr."Supplier Address" := PurchCrHdrP."Buy-from Address";
            if state.Get(PurchCrHdrP."GST Order Address State") then
                TransHdr."Supplier State" := State."State Code (GST Reg. No.)"
            else
                if State.Get(Vendor."State Code") THEN
                    TransHdr."Supplier State" := State."State Code (GST Reg. No.)";
        end;
    end;

    local procedure ReadReceiverDetails(PurchCrHdrP: Record "Purch. Cr. Memo Hdr.")
    var
        CompanyInformation: Record "Company Information";
        Location: Record Location;
        State: Record State;
    begin
        CompanyInformation.Get();
        TransHdr."Receiver Name" := CompanyInformation.Name;
        if Location.GET(PurchCrHdrP."Location Code") then begin
            TransHdr."Receiver GSTIN" := Location."GST Registration No.";
            TransHdr."Receiver address" := Location.Address;
            if State.GET(Location."State Code") then
                TransHdr."Receiver State" := State."State Code (GST Reg. No.)";
        END;
    end;

    local procedure ReadLineDetails(PurchCrHdrP: Record "Purch. Cr. Memo Hdr.")
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TransLine: record "Clear Trans line";
        HSNSAC: Record "HSN/SAC";
        TDSEntry: Record "TDS Entry";
        UQCValues: Record "Unit of Measure";
    begin
        TransLine.SetRange("Document Type", TransHdr."Document Type");
        TransLine.SetRange("Document No.", TransHdr."Document No.");

        TransLine.SetRange("Transaction Type", TransLine."Transaction Type"::PURCHASE);
        if TransLine.FindFirst() then
            TransLine.DeleteAll();

        PurchCrMemoLine.SetRange("Document No.", TransHdr."Document No.");
        PurchCrMemoLine.SetFilter(Type, '<>%1', PurchCrMemoLine.Type::" ");
        PurchCrMemoLine.SetRange("System-Created Entry", false);
        if PurchCrMemoLine.FindSet() then
            repeat
                Clear(TransLine);
                TransLine."Transaction Type" := TransHdr."Transaction Type";
                TransLine."Document Type" := TransHdr."Document Type";
                TransLine."Document No." := TransHdr."Document No.";
                TransLine."Line num" := PurchCrMemoLine."Line No.";
                TransLine."Item no" := PurchCrMemoLine."No.";
                TransLine."Item description" := PurchCrMemoLine.Description;
                TransLine."Item quantity" := PurchCrMemoLine.Quantity;
                TransLine."Unit Price" := PurchCrMemoLine."Unit Cost (LCY)";
                TransLine.Discount := PurchCrMemoLine."Line Discount Amount";

                if UQCValues.Get(PurchCrMemoLine."Unit of Measure Code") then
                    TransLine.UOM := UQCValues."Clear UQC values"
                else
                    TransLine.UOM := PurchCrMemoLine."Unit of Measure Code";
                if not TransHdr."Is bill of supply" then
                    GeneralFunctions.GetGSTCompRate(TransLine);

                TransLine."HSNSAC Code" := PurchCrMemoLine."HSN/SAC Code";
                if HSNSAC.Get(PurchCrMemoLine."GST Group Code", PurchCrMemoLine."HSN/SAC Code") then
                    if HSNSAC.Type = HSNSAC.Type::HSN then
                        TransLine."Item category" := TransLine."Item category"::G
                    ELSE
                        TransLine."Item category" := TransLine."Item category"::S;
                TDSEntry.SetRange("Document No.", TransHdr."Document No.");
                if TDSEntry.FindFirst() and (TDSEntry."Total TDS Including SHE CESS" > 0) then
                    TransHdr."Is TDS deducted" := TRUE;

                if PurchCrMemoLine.Exempted then
                    TransLine."Zero tax category" := Enum::"Clear Zero Tax Category"::EXEMPTED
                else
                    if PurchCrMemoLine."Non-GST Line" then
                        TransLine."Zero tax category" := Enum::"Clear Zero Tax Category"::NON_GST_SUPPLY;
                if ((TransLine."CGST amt" <= 0) and (TransLine."SGST amt" <= 0) and (TransLine."IGST amt" <= 0) and (TransLine."Zero tax category" = TransLine."Zero tax category"::None)) then begin
                    TransLine."Zero tax category" := Enum::"Clear Zero Tax Category"::NIL_RATED;
                end;
                if TransLine."Zero tax category" <> TransLine."Zero tax category"::None then begin
                    Clear(TransLine."CGST rate");
                    Clear(TransLine."SGST rate");
                    Clear(TransLine."Cess rate");
                    Clear(TransLine."CGST amt");
                    Clear(TransLine."SGST amt");
                    Clear(TransLine."Cess amt");
                end;
                TransLine."Line num" := GeneralFunctions.GetTransLineNo(TransLine."Transaction Type", TransLine."Document Type", TransLine."Document No.");
                TransLine.Insert();
            until PurchCrMemoLine.Next() = 0;
        if PurchCrHdrP."GST Vendor Type" = PurchCrHdrP."GST Vendor Type"::Import then begin
            if PurchCrMemoLine."GST Group Type" = PurchCrMemoLine."GST Group Type"::Goods then
                TransHdr."Import type" := TransHdr."Import type"::GOODS
            else
                TransHdr."Import type" := TransHdr."Import type"::SERVICE;
        end else
            if PurchCrHdrP."GST Vendor Type" = PurchCrHdrP."GST Vendor Type"::SEZ then begin
                if PurchCrMemoLine."GST Group Type" = PurchCrMemoLine."GST Group Type"::Goods then
                    TransHdr."Import type" := TransHdr."Import type"::"GOODS FROM SEZ"
                else
                    TransHdr."Import type" := TransHdr."Import type"::"SERVICE FROM SEZ";
            end;

    end;

    //++++++++++++++++++++++++++++++++++++++++ Returns place of supply ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    local procedure getPlaceofSupply(PurchCrHdrP: Record "Purch. Cr. Memo Hdr."): Text
    var
        state: Record State;
        location: Record Location;
    begin
        if Location.Get(PurchCrHdrP."Location Code") then
            if State.Get(Location."State Code") and (State."State Code (GST Reg. No.)" > '') then
                exit(State."State Code (GST Reg. No.)");
    end;

    //-------------------------------------------end of function -------------------------------------------------------------------
}