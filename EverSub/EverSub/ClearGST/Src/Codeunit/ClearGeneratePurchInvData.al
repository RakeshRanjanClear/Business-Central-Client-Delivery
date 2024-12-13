codeunit 50108 "clear Generate Purch Inv data"
{
    var
        TransHdr: Record "Clear Trans Hdr";
        GeneralFunctions: Codeunit "Clear General functions";

    procedure ReadDetails(PurchInvHdrP: Record "Purch. Inv. Header")
    begin
        Clear(TransHdr);
        if not GeneralFunctions.IsGSTApplicable(PurchInvHdrP."No.", Database::"Purch. Inv. Header") then
            exit;
        ReadHeaderDetails(PurchInvHdrP);
        ReadSupplierDetails(PurchInvHdrP);
        ReadReceiverDetails(PurchInvHdrP);
        ReadLineDetails(PurchInvHdrP);
        TransHdr.Modify();
    end;

    local procedure ReadHeaderDetails(PurchInvHdrP: Record "Purch. Inv. Header")
    var
        vendor: Record Vendor;
    begin
        TransHdr."Transaction Type" := Enum::"Clear Transaction type"::Purchase;
        if PurchInvHdrP."Prepayment Order No." > '' then
            TransHdr."Document Type" := Enum::"Clear Document Type"::Advance
        else
            TransHdr."Document Type" := Enum::"Clear Document Type"::Invoice;
        TransHdr."Document No." := PurchInvHdrP."No.";
        TransHdr."Vendor Invoice number" := GeneralFunctions.getExternalDocumentNumber(PurchInvHdrP."No.");
        if not TransHdr.Insert() then;
        TransHdr."Posting date" := PurchInvHdrP."Posting Date";
        if PurchInvHdrP."Invoice Type" in [PurchInvHdrP."Invoice Type"::"Non-GST"] then
            TransHdr."Is bill of supply" := true;
        TransHdr."Is reverse charge applicable" := GeneralFunctions.IsReverseChargeApplicable(PurchInvHdrP."No.", Enum::"GST Document Type"::Invoice);
        TransHdr."Place of Supply" := getPlaceofSupply(PurchInvHdrP);
    end;

    local procedure ReadSupplierDetails(PurchInvHdrP: Record "Purch. Inv. Header")
    var
        OrderAddress: Record "Order Address";
        Vendor: Record Vendor;
        State: Record State;
        Location: Record Location;
    begin
        if Vendor.Get(PurchInvHdrP."Buy-from Vendor No.") then;
        if Vendor."GST Vendor Type" = Vendor."GST Vendor Type"::Composite then
            TransHdr."Is supplier Composition dealer" := true;
        if (PurchInvHdrP."Order Address Code" > '') and (OrderAddress.GET(PurchInvHdrP."Buy-from Vendor No.", PurchInvHdrP."Order Address Code")) then begin
            TransHdr."Supplier Name" := OrderAddress.Name;
            TransHdr."Supplier GSTIN" := OrderAddress."GST Registration No.";
            TransHdr."Supplier Address" := OrderAddress.Address;
            if State.GET(OrderAddress.State) then
                TransHdr."Supplier State" := State."State Code (GST Reg. No.)";
        end else begin
            TransHdr."Supplier Name" := PurchInvHdrP."Buy-from Vendor Name";

            TransHdr."Supplier Address" := PurchInvHdrP."Buy-from Address";

            if state.Get(PurchInvHdrP."GST Order Address State") then
                TransHdr."Supplier State" := State."State Code (GST Reg. No.)"
            else
                if State.Get(Vendor."State Code") THEN
                    TransHdr."Supplier State" := State."State Code (GST Reg. No.)";
        end;
        if PurchInvHdrP."Vendor GST Reg. No." <> '' then
            TransHdr."Supplier GSTIN" := PurchInvHdrP."Vendor GST Reg. No."
        else
            if (TransHdr."Supplier GSTIN" = '') then
                TransHdr."Supplier GSTIN" := Vendor."GST Registration No.";

    end;

    local procedure ReadReceiverDetails(PurchInvHdrP: Record "Purch. Inv. Header")
    var
        State: Record State;
        Location: Record Location;
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        TransHdr."Receiver Name" := CompanyInformation.Name;
        if Location.Get(PurchInvHdrP."Location Code") then begin
            TransHdr."Receiver GSTIN" := Location."GST Registration No.";
            TransHdr."Receiver address" := Location.Address;
            if State.Get(Location."State Code") then
                TransHdr."Receiver State" := State."State Code (GST Reg. No.)";
        end;
    end;

    local procedure ReadLineDetails(PurchInvHdrP: Record "Purch. Inv. Header")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        TransLine: Record "Clear Trans line";
        HSNSAC: Record "HSN/SAC";
        TDSEntry: Record "TDS Entry";
        UQCValues: Record "Unit of Measure";
    begin
        TransLine.SetRange("Transaction Type", TransLine."Transaction Type"::PURCHASE);
        TransLine.SetRange("Document Type", TransHdr."Document Type");
        TransLine.SetRange("Document No.", TransHdr."Document No.");
        if TransLine.FindSet() then
            TransLine.DeleteAll();
        PurchInvLine.SetRange("Document No.", TransHdr."Document No.");
        PurchInvLine.SetFilter("No.", '<>%1', '');
        PurchInvLine.SetFilter(Quantity, '<>%1', 0);
        PurchInvLine.SetRange("System-Created Entry", false);
        if PurchInvLine.FindSet() then
            repeat
                Clear(TransLine);
                TransLine."Transaction Type" := TransHdr."Transaction Type";
                TransLine."Document Type" := TransHdr."Document Type";
                TransLine."Document No." := TransHdr."Document No.";
                TransLine."Line num" := PurchInvLine."Line No.";
                TransLine."Item no" := PurchInvLine."No.";
                TransLine."Item description" := PurchInvLine.Description;
                TransLine."Item quantity" := PurchInvLine.Quantity;
                TransLine."Unit Price" := PurchInvLine."Unit Price (LCY)";
                TransLine.Discount := PurchInvLine."Line Discount Amount";
                if UQCValues.Get(PurchInvLine."Unit of Measure Code") then
                    TransLine.UOM := UQCValues."Clear UQC values"
                else
                    TransLine.UOM := PurchInvLine."Unit of Measure Code";



                TDSEntry.SetRange("Document No.", TransHdr."Document No.");
                if TDSEntry.FindFirst() then
                    if TDSEntry."Total TDS Including SHE CESS" > 0 then
                        TransHdr."Is TDS deducted" := true;

                TransLine."HSNSAC Code" := PurchInvLine."HSN/SAC Code";
                if HSNSAC.Get(PurchInvLine."GST Group Code", PurchInvLine."HSN/SAC Code") then
                    if HSNSAC.Type = HSNSAC.Type::HSN then
                        TransLine."Item category" := TransLine."Item category"::G
                    else
                        TransLine."Item category" := TransLine."Item category"::S;

                if not TransHdr."Is Bill of Supply" then
                    GeneralFunctions.GetGSTCompRate(TransLine);
                if PurchInvLine.Exempted then
                    TransLine."Zero tax category" := Enum::"Clear Zero Tax Category"::EXEMPTED
                else
                    if PurchInvLine."Non-GST Line" then
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
            until PurchInvLine.Next() = 0;
        if PurchInvHdrP."GST Vendor Type" = PurchInvHdrP."GST Vendor Type"::Import then begin
            if PurchInvLine."GST Group Type" = PurchInvLine."GST Group Type"::Goods then
                TransHdr."Import type" := TransHdr."Import type"::GOODS
            else
                TransHdr."Import type" := TransHdr."Import type"::SERVICE;
        end else
            if PurchInvHdrP."GST Vendor Type" = PurchInvHdrP."GST Vendor Type"::SEZ then begin
                if PurchInvLine."GST Group Type" = PurchInvLine."GST Group Type"::Goods then
                    TransHdr."Import type" := TransHdr."Import type"::"GOODS FROM SEZ"
                else
                    TransHdr."Import type" := TransHdr."Import type"::"SERVICE FROM SEZ";
            end;
    end;

    //++++++++++++++++++++++++++++++++++++++++ Returns place of supply ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    local procedure getPlaceofSupply(PurchInvHdrP: Record "Purch. Inv. Header"): Text
    var
        state: Record State;
        location: Record Location;
    begin
        if Location.Get(PurchInvHdrP."Location Code") then
            if State.Get(Location."State Code") and (State."State Code (GST Reg. No.)" > '') then
                exit(State."State Code (GST Reg. No.)");
    end;

    //-------------------------------------------end of function -------------------------------------------------------------------
}