codeunit 50113 "Clear Json Creation"
{
    procedure CreatePayload(TransHdrP: Record "Clear Trans Hdr"): Text
    var
        JObject: JsonObject;
        JTempObject: JsonObject;
        JSettings: JsonObject;
        JMainObject: JsonObject;
        Jarray: JsonArray;
        ClearGSTSetup: Record "Clear GST Setup";
        TransLine: Record "Clear Trans line";
        Payload: Text;
    begin
        ClearGSTSetup.Get();
        JTempObject.Add('ignoreHsnValidation', ClearGSTSetup."Ignore HSN validation");
        if (TransHdrP."Transaction Type" = Enum::"Clear Transaction type"::sale) then
            JObject.Add('templateId', ClearGSTSetup."Sales template ID")
        else
            JObject.Add('templateId', ClearGSTSetup."Purchase template ID");
        JObject.Add('settings', JTempObject);
        JMainObject.Add('userInputArgs', JObject);
        TransLine.SetRange("Transaction Type", TransHdrP."Transaction Type");
        TransLine.SetRange("Document Type", TransHdrP."Document Type");
        TransLine.SetRange("Document No.", TransHdrP."Document No.");
        if TransLine.FindSet() then
            repeat
                Clear(JTempObject);
                JTempObject.Add('documentType', format(TransLine."Document Type"));
                JTempObject.Add('documentDate', Format(TransHdrP."Posting Date", 10, '<Year4>-<Month,2>-<Day,2>'));

                if TransHdrP."Vendor Invoice number" <> '' then begin
                    JTempObject.Add('documentNumber', TransHdrP."Vendor Invoice number");
                    JTempObject.Add('voucherNumber', TransHdrP."Document No.");
                end else begin
                    JTempObject.Add('documentNumber', TransHdrP."Document No.");
                end;
                if TransHdrP."Is bill of supply" then
                    JTempObject.Add('isBillOfSupply', TransHdrP."Is bill of supply");
                if TransHdrP."Is reverse charge applicable" then
                    JTempObject.Add('isReverseCharge', TransHdrP."Is reverse charge applicable");
                JTempObject.Add('supplierName', TransHdrP."Supplier Name");
                JTempObject.Add('supplierAddress', TransHdrP."Supplier Address");
                JTempObject.Add('customerName', TransHdrP."Receiver Name");
                JTempObject.Add('customerAddress', TransHdrP."Receiver address");
                if (ClearGSTSetup."Use Test GSTIN") then begin
                    if (TransLine."Transaction Type" = TransLine."Transaction Type"::sale) then begin
                        JTempObject.Add('supplierGstin', ClearGSTSetup.GSTIN1);
                        JTempObject.Add('supplierState', CopyStr(ClearGSTSetup.GSTIN1, 1, 2));
                        JTempObject.Add('customerGstin', ClearGSTSetup.GSTIN2);
                        JTempObject.Add('customerState', CopyStr(ClearGSTSetup.GSTIN2, 1, 2));
                        JTempObject.Add('placeOfSupply', CopyStr(ClearGSTSetup.GSTIN2, 1, 2))
                    end;
                    if (TransLine."Transaction Type" = TransLine."Transaction Type"::Purchase) then begin
                        JTempObject.Add('customerGstin', ClearGSTSetup.GSTIN1);
                        JTempObject.Add('customerState', CopyStr(ClearGSTSetup.GSTIN1, 1, 2));
                        JTempObject.Add('placeOfSupply', CopyStr(ClearGSTSetup.GSTIN1, 1, 2));
                        JTempObject.Add('supplierGstin', ClearGSTSetup.GSTIN2);
                        JTempObject.Add('supplierState', CopyStr(ClearGSTSetup.GSTIN2, 1, 2));

                    end;
                end else begin
                    JTempObject.Add('supplierGstin', TransHdrP."Supplier GSTIN");
                    JTempObject.Add('supplierState', TransHdrP."Supplier State");
                    JTempObject.Add('customerGstin', TransHdrP."Receiver GSTIN");
                    JTempObject.Add('customerState', TransHdrP."Receiver State");
                    JTempObject.Add('placeOfSupply', TransHdrP."Place of Supply");
                end;

                if TransHdrP."Is TDS deducted" then
                    JTempObject.Add('isTdsDeducted', TransHdrP."Is TDS deducted");
                if TransHdrP."Linked invoice no." <> '' then begin
                    JTempObject.Add('linkedInvoiceNumber', TransHdrP."Linked invoice no.");
                    JTempObject.Add('linkedInvoiceDate', TransHdrP."Linked invoice date");
                end;
                if TransHdrP."Ecommerce GSTIN" <> '' then
                    JTempObject.Add('ecommerceGstin', TransHdrP."Ecommerce GSTIN");
                if TransHdrP."Customer TaxpayerType" <> TransHdrP."Customer TaxpayerType"::None then
                    JTempObject.Add('customerTaxpayerType', Format(TransHdrP."Customer TaxpayerType"));
                if TransLine."Zero tax category" <> TransLine."Zero tax category"::None then
                    JTempObject.Add('zeroTaxCategory', Format(TransLine."Zero tax category"));
                if (TransHdrP."Export type" <> TransHdrP."Export type"::None) and (TransHdrP."Export bill no." <> '') then begin
                    JTempObject.Add('exportType', Format(TransHdrP."Export type"));
                    JTempObject.Add('exportBillNumber', TransHdrP."Export bill no.");
                    JTempObject.Add('exportBillDate', Format(TransHdrP."Export bill date", 10, '<Year4>-<Month,2>-<Day,2>'));
                    JTempObject.Add('exportPortCode', TransHdrP."Export Port Code");
                end;
                if (TransHdrP."Import type" <> TransHdrP."Import type"::NONE) and (TransHdrP."Import bill no" <> 0) then begin
                    JTempObject.Add('importType', Format(TransHdrP."Import type"));
                    JTempObject.Add('importBillNumber', TransHdrP."Import bill no");
                    if (TransHdrP."Import bill date" <> 0D) then
                        JTempObject.Add('importBillDate', Format(TransHdrP."Import bill date", 10, '<Year4>-<Month,2>-<Day,2>'));
                    if (TransHdrP."Import port code" <> '') then
                        JTempObject.Add('importPortCode', TransHdrP."Import port code");
                end;

                if (TransLine."ITC claim type" <> TransLine."ITC claim type"::NONE) then begin
                    JTempObject.Add('itcClaimType', Format(TransLine."ITC claim type"));
                    if TransLine."ITC CGST amt" <> 0 then begin
                        JTempObject.Add('itcClaimCgstAmount', TransLine."ITC CGST amt");
                        JTempObject.Add('itcClaimSgstAmount', TransLine."ITC SGST amt");
                    end;
                    if TransLine."ITC IGST amt" <> 0 then
                        JTempObject.Add('itcClaimIgstAmount', TransLine."ITC IGST amt");
                    if TransLine."ITC CESS amt" <> 0 then
                        JTempObject.Add('itcClaimCessAmount', TransLine."ITC CESS amt");
                end;
                if (TransHdrP."Is supplier Composition dealer") then begin
                    JTempObject.Add('isSupplierCompositionDealer', 'Y');
                end;
                JTempObject.Add('itemDescription', TransLine."Item description");
                if TransLine."Item category" <> TransLine."Item category"::None then
                    JTempObject.Add('itemCategory', Format(TransLine."Item category"));
                JTempObject.Add('hsnSacCode', TransLine."HSNSAC Code");
                JTempObject.Add('itemQuantity', TransLine."Item quantity");
                JTempObject.Add('itemUnitCode', TransLine.UOM);
                JTempObject.Add('itemUnitPrice', TransLine."Unit Price");
                JTempObject.Add('itemDiscount', TransLine.Discount);
                JTempObject.Add('cgstRate', TransLine."CGST rate");
                JTempObject.Add('cgstAmount', TransLine."CGST amt");
                JTempObject.Add('sgstRate', TransLine."SGST rate");
                JTempObject.Add('sgstAmount', TransLine."SGST amt");
                JTempObject.Add('igstRate', TransLine."IGST rate");
                JTempObject.Add('igstAmount', TransLine."IGST amt");
                JTempObject.Add('cessRate', TransLine."Cess rate");
                JTempObject.Add('cessAmount', TransLine."Cess amt");
                JTempObject.Add('itemTaxableAmount', abs(TransLine."Taxable amount"));
                Jarray.Add(JTempObject);
            until TransLine.Next() = 0;
        JMainObject.Add('jsonRecords', Jarray);
        JMainObject.WriteTo(Payload);
        exit(Payload);
    end;
}