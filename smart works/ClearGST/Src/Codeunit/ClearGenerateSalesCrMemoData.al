codeunit 60005 "Clear Generate Sales Cr. memo"
{
    var
        GeneralFunctions: Codeunit "Clear General functions";
        TransHdr: Record "Clear Trans Hdr";

    procedure ReadDetails(SalesCrHdrP: Record "Sales Cr.Memo Header")
    begin
        TransHdr.SetRange("Transaction Type", Enum::"Clear Transaction type"::sale);
        TransHdr.SetFilter("Document Type", '%1|%2', Enum::"Clear Document Type"::Credit, Enum::"Clear Document Type"::Advance);
        TransHdr.SetRange("Document No.", SalesCrHdrP."No.");
        if TransHdr.FindFirst() then
            if TransHdr."Process Manually" then
                exit;
        Clear(TransHdr);
        if not GeneralFunctions.IsGSTApplicable(SalesCrHdrP."No.", Database::"Sales Cr.Memo Header") then
            exit;

        ReadHeaderDetails(SalesCrHdrP);
        ReadSupplierDetails(SalesCrHdrP);
        ReadReceiverDetails(SalesCrHdrP);
        ReadLineDetails();
        TransHdr.Modify();
    end;

    local procedure ReadHeaderDetails(SalesCrHdrP: Record "Sales Cr.Memo Header")
    var
        SalesInvHdr: Record "Sales Invoice Header";
        customer: Record Customer;
    begin
        TransHdr."Transaction Type" := Enum::"Clear Transaction type"::sale;
        if SalesCrHdrP."Prepayment Order No." > '' then
            TransHdr."Document Type" := Enum::"Clear Document Type"::Advance
        else
            TransHdr."Document Type" := Enum::"Clear Document Type"::Credit;
        TransHdr."Document No." := SalesCrHdrP."No.";
        if not TransHdr.Insert() then;
        TransHdr."Posting date" := SalesCrHdrP."Posting Date";
        if SalesCrHdrP."Invoice Type" in [SalesCrHdrP."Invoice Type"::"Bill of Supply", SalesCrHdrP."Invoice Type"::"Non-GST"] then
            TransHdr."Is bill of supply" := true;
        TransHdr."Is reverse charge applicable" := GeneralFunctions.IsReverseChargeApplicable(SalesCrHdrP."No.", Enum::"GST Document Type"::"Credit Memo");
        TransHdr."Place of Supply" := getPlaceofSupply(SalesCrHdrP);
        if customer.get(SalesCrHdrP."E-Commerce Customer") then
            TransHdr."Ecommerce GSTIN" := customer."GST Registration No.";
        if SalesInvHdr.get(SalesCrHdrP."Reference Invoice No.") then begin
            TransHdr."Linked invoice no." := SalesInvHdr."No.";
            TransHdr."Linked invoice date" := SalesInvHdr."Posting Date";
        end;

    end;

    local procedure ReadSupplierDetails(SalesCrHdrP: Record "Sales Cr.Memo Header")
    var
        companyInformation: Record "Company Information";
        state: Record State;
        location: Record Location;
    begin
        companyInformation.get();
        TransHdr."Supplier Name" := companyInformation.Name;
        TransHdr."Supplier GSTIN" := SalesCrHdrP."Location GST Reg. No.";
        if location.Get(SalesCrHdrP."Location Code") then begin
            TransHdr."Supplier Address" := location.Address;
            if state.Get(location."State Code") then
                TransHdr."Supplier State" := state.Code;
        end;
    end;

    local procedure ReadReceiverDetails(SalesCrHdrP: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        Customer: Record Customer;
        State: Record State;
        ShipToAddress: Record "Ship-to Address";
    begin
        TransHdr."Receiver Name" := SalesCrHdrP."Bill-to Name";

        if SalesCrHdrP."Ship-to Code" > '' then
            if ShipToAddress.Get(SalesCrHdrP."Bill-to Customer No.", SalesCrHdrP."Ship-to Code") then
                TransHdr."Receiver GSTIN" := ShipToAddress."GST Registration No.";
        if TransHdr."Receiver GSTIN" = '' then
            if Customer.Get(SalesCrHdrP."Bill-to Customer No.") then
                TransHdr."Receiver GSTIN" := Customer."GST Registration No.";
        TransHdr."Receiver address" := SalesCrHdrP."Bill-to Address";

        SalesCrMemoLine.SetRange("Document No.", SalesCrHdrP."No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        if SalesCrMemoLine.FindFirst() then
            if SalesCrMemoLine."GST Place of Supply" = SalesCrMemoLine."GST Place of Supply"::"Bill-to Address" then begin
                if not (SalesCrHdrP."GST Customer Type" = SalesCrHdrP."GST Customer Type"::Export) then
                    if State.Get(SalesCrHdrP."GST Bill-to State Code") then
                        TransHdr."Receiver State" := State."State Code (GST Reg. No.)";
            end else
                if SalesCrMemoLine."GST Place of Supply" = SalesCrMemoLine."GST Place of Supply"::"Ship-to Address" then begin
                    if not (SalesCrHdrP."GST Customer Type" = SalesCrHdrP."GST Customer Type"::Export) then
                        if State.Get(SalesCrHdrP."GST Ship-to State Code") then
                            TransHdr."Receiver State" := State."State Code (GST Reg. No.)";
                end else begin
                    if State.Get(SalesCrHdrP."Location Code") then
                        TransHdr."Receiver State" := State."State Code (GST Reg. No.)";
                end;
    end;

    local procedure ReadLineDetails()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TransLine: Record "Clear Trans line";
        HSNSAC: Record "HSN/SAC";
        UQCValues: Record "Unit of Measure";
    begin
        TransLine.SetRange("Transaction Type", TransHdr."Transaction Type");
        TransLine.SetRange("Document Type", TransHdr."Document Type");
        TransLine.SetRange("Document No.", TransHdr."Document No.");
        if TransLine.FindFirst() then
            TransLine.DeleteAll();

        SalesCrMemoLine.SetRange("Document No.", TransHdr."Document No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        SalesCrMemoLine.SetFilter(Quantity, '<>%1', 0);
        SalesCrMemoLine.SetRange("System-Created Entry", false);
        if SalesCrMemoLine.FindSet() then
            repeat
                Clear(TransLine);
                TransLine."Transaction Type" := TransHdr."Transaction Type";
                TransLine."Document Type" := TransHdr."Document Type";
                TransLine."Document No." := TransHdr."Document No.";
                TransLine."Line num" := SalesCrMemoLine."Line No.";
                TransLine."Item no" := SalesCrMemoLine."No.";
                TransLine."Item description" := SalesCrMemoLine.Description;
                TransLine."Item quantity" := SalesCrMemoLine.Quantity;
                TransLine."Unit Price" := SalesCrMemoLine."Unit Price";
                TransLine.Discount := SalesCrMemoLine."Line Discount Amount";
                if UQCValues.Get(SalesCrMemoLine."Unit of Measure Code") then
                    TransLine.UOM := UQCValues."Clear UQC values"
                else
                    TransLine.UOM := SalesCrMemoLine."Unit of Measure Code";
                TransLine."HSNSAC Code" := SalesCrMemoLine."HSN/SAC Code";
                if HSNSAC.Get(SalesCrMemoLine."GST Group Code", SalesCrMemoLine."HSN/SAC Code") then
                    if HSNSAC.Type = HSNSAC.Type::HSN then
                        TransLine."Item category" := TransLine."Item category"::G
                    else
                        TransLine."Item category" := TransLine."Item category"::S;
                if not TransHdr."Is bill of supply" then
                    GeneralFunctions.GetGSTCompRate(TransLine);

                if SalesCrMemoLine.Exempted then
                    TransLine."Zero tax category" := Enum::"Clear Zero Tax Category"::EXEMPTED
                else
                    if SalesCrMemoLine."Non-GST Line" then
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
            until SalesCrMemoLine.Next() = 0;
    end;

    local procedure getPlaceofSupply(SalesCrHdrP: Record "Sales Cr.Memo Header"): Text
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        state: Record State;
        Customer: Record Customer;
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrHdrP."No.");
        SalesCrMemoLine.SetFilter("GST Place of Supply", '<>%1', SalesCrMemoLine."GST Place of Supply"::" ");
        if SalesCrMemoLine.FindFirst() then begin
            case SalesCrMemoLine."GST Place of Supply" of
                SalesCrMemoLine."GST Place of Supply"::"Ship-to Address":
                    if State.Get(SalesCrHdrP."GST Ship-to State Code") then;
                SalesCrMemoLine."GST Place of Supply"::"Location Address":
                    if State.Get(SalesCrHdrP."Location State Code") then;
                SalesCrMemoLine."GST Place of Supply"::"Bill-to Address":
                    if State.Get(SalesCrHdrP."GST Bill-to State Code") then;
            end;
            if State."State Code (GST Reg. No.)" <> '' then
                exit(State."State Code (GST Reg. No.)");
        end;
        if Customer.get(SalesCrHdrP."Bill-to Customer No.") then
            if State.Get(Customer."State Code") and (State."State Code (GST Reg. No.)" > '') then // Change in Nav16
                exit(State."State Code (GST Reg. No.)");
    end;

    //-------------------------------------------end of function -------------------------------------------------------------------
}