codeunit 50200 "ClearComp E-Way Management"
{
    Permissions = TableData "Sales Invoice Header" = rimd,
                  TableData "Sales Cr.Memo Header" = rimd,
                  TableData "Purch. Cr. Memo Hdr." = rimd,
                  TableData "Transfer Shipment Header" = rimd;

    trigger OnRun()
    begin
    end;

    var
        JObject: JsonObject;
        JArray: JsonArray;
        EWayGeneratedErr: Label 'E-Way Bill already generated for document no. %1';
        DocType: Option " ",Sales,Purchase,Transfer;
        EWayGenerated: Label 'E-Way Bill Generated successfully for document no. %1.';
        EWayFailed: Label 'E-Way Bill Generation failed for document no. %1.';
        VehicleUpdated: Label 'Vehicle No. Updated Successfully for document no. %1.';
        EWayCancelled: Label 'E-Way Bill Cancelled for document no. %1.';

    procedure CreateJsonSalesInvoice(SalesInvHeaderP: Record "Sales Invoice Header")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        ShippingAgentL: Record "Shipping Agent";
        TransportMethodL: Record "Transport Method";
        CompanyInformationL: Record "Company Information";
        CustomerL: Record Customer;
        PostCodeL: Record "Post Code";
        StateL: Record State;
        "Entry/ExitPointL": Record "Entry/Exit Point";
        SalesInvoiceLineL: Record "Sales Invoice Line";
        ShipToAddressL: Record "Ship-to Address";
        ItemCategoryL: Record "Item Category";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TCSEntry: Record "TCS Entry";
        JSubObject: JsonObject;
        JArrayL: JsonArray;
        JToken1L: JsonToken;
        LCYCurrency: Decimal;
        InvRoundingGL: Code[20];
        PITRoungGL: Code[20];
        ResponseText: Text;
        EWayBillNo: Text;
        EWayBillDateTime: Text;
        EWayExpirationDT: Text;
        StatusText: Text;
        RequestText: Text;
    begin
        if SalesInvHeaderP."IRN Hash" > '' then
            CreateJsonSalesInvoiceforIRN(SalesInvHeaderP)
        else begin
            SalesInvHeader.Copy(SalesInvHeaderP);
            LocationL.Get(SalesInvHeader."Location Code");
            EInvoiceSetupL.Get;
            SalesInvHeader.TestField("Transport Method");
            SalesInvHeader.TestField("Vehicle No.");
            SalesInvHeader.TestField("LR/RR No.");
            SalesInvHeader.TestField("LR/RR Date");
            TransportMethodL.Get(SalesInvHeader."Transport Method");
            LocationL.TestField("Post Code");
            CompanyInformationL.Get();
            JObject.Add('DocumentNumber', SalesInvHeader."No.");
            JObject.Add('DocumentType', 'INV');
            JObject.Add('DocumentDate', Format(SalesInvHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));
            JObject.Add('SupplyType', 'Outward');
            if CustomerL.Get(SalesInvHeader."Bill-to Customer No.") then begin
                if CustomerL."GST Registration No." > '' then
                    JObject.Add('SubSupplyType', 'Supply')
                else
                    if SalesInvHeader."GST Customer Type" = SalesInvHeader."GST Customer Type"::Export then
                        JObject.Add('SubSupplyType', 'Export')
                    else
                        JObject.Add('SubSupplyType', 'Supply');
            end;
            //JObject.Add('SubSupplyTypeDesc',''));
            JObject.Add('TransactionType', 'Regular');
            if CustomerL."GST Registration No." <> '' then
                JSubObject.Add('Gstin', CustomerL."GST Registration No.")
            else
                JSubObject.Add('Gstin', 'URP');
            JSubObject.Add('LglNm', SalesInvHeader."Ship-to Name");
            JSubObject.Add('TrdNm', SalesInvHeader."Ship-to Name 2");
            JSubObject.Add('Addr1', SalesInvHeader."Ship-to Address");
            JSubObject.Add('Addr2', SalesInvHeader."Ship-to Address 2");
            JSubObject.Add('Loc', SalesInvHeader."Ship-to City");
            if SalesInvHeader."Ship-to Code" = '' then begin
                if SalesInvHeader."GST Customer Type" = SalesInvHeader."GST Customer Type"::Export then begin
                    if "Entry/ExitPointL".Get(SalesInvHeader."Exit Point") then begin
                        if StateL.Get("Entry/ExitPointL"."State Code") then;
                        JSubObject.Add('Stcd', Format(StateL."State Code (GST Reg. No.)"));
                        JSubObject.Add('Pin', Format("Entry/ExitPointL"."Post Code"));
                    end else begin
                        JSubObject.Add('Stcd', '96');
                        JSubObject.Add('Pin', '999999');
                    end;
                end else begin
                    if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                        JSubObject.Add('Stcd', '29');
                        JSubObject.Add('Pin', '562160');
                    end else begin
                        PostCodeL.SetRange(Code, SalesInvHeader."Ship-to Post Code");
                        if PostCodeL.FindFirst() then;
                        if StateL.Get(SalesInvHeader.State) then
                            JSubObject.Add('Stcd', Format(StateL."State Code (GST Reg. No.)"))
                        else
                            JSubObject.Add('Stcd', '');
                        JSubObject.Add('Pin', Format(PostCodeL.Code));
                    end;
                end;
            end else begin
                if ShipToAddressL.Get(SalesInvHeader."Bill-to Customer No.", SalesInvHeader."Ship-to Code") then begin
                    if SalesInvHeader."GST Customer Type" = SalesInvHeader."GST Customer Type"::Export then begin
                        JSubObject.Add('Stcd', '96');
                        JSubObject.Add('Pin', '999999');
                    end else begin
                        ShipToAddressL.TestField(State);
                        if StateL.Get(ShipToAddressL.State) then begin
                            JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                            if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then
                                JSubObject.Add('Pin', '562160'); // added additionaly due to missing data.
                        end else
                            JSubObject.Add('Stcd', '');
                    end;
                end;
            end;
            JObject.Add('BuyerDtls', JSubObject);
            Clear(JSubObject);
            JSubObject.Add('LglNm', LocationL.Name);
            JSubObject.Add('TrdNm', LocationL."Name 2");
            JSubObject.Add('Addr1', LocationL.Address);
            JSubObject.Add('Addr2', LocationL."Address 2");
            JSubObject.Add('Loc', LocationL.City);
            if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                JSubObject.Add('Pin', '560027');
                JSubObject.Add('Gstin', '29AAFCD5862R000');
                JSubObject.Add('Stcd', '29');
            end else begin
                if LocationL."GST Registration No." <> '' then
                    JSubObject.Add('Gstin', LocationL."GST Registration No.")
                else
                    JSubObject.Add('Gstin', CompanyInformationL."GST Registration No.");
                PostCodeL.SetRange(Code, LocationL."Post Code");
                if PostCodeL.FindFirst() then;
                JSubObject.Add('Pin', Format(PostCodeL.Code));
                if StateL.Get(LocationL."State Code") then;
                JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
            end;
            JObject.Add('SellerDtls', JSubObject);
            SalesInvoiceLineL.SetRange("Document No.", SalesInvHeader."No.");
            SalesInvoiceLineL.SetFilter(Quantity, '<>%1', 0);
            //SalesInvoiceLineL.CalcSums("TDS/TCS Amount");
            TCSEntry.SetRange("Document No.", SalesInvoiceLineL."Document No.");
            if TCSEntry.FindFirst() then
                ;
            //if SalesInvoiceLineL."TDS/TCS Amount" <> 0 then
            JObject.Add('OtherAmount', TCSEntry."Total TCS Including SHE CESS");
            if SalesInvHeader."Currency Factor" <> 0 then
                LCYCurrency := 1 / SalesInvHeader."Currency Factor"
            else
                LCYCurrency := 1;
            JObject.Add('TotalInvoiceAmount', Round((GetTaxableAmountSalesInvoice(SalesInvHeader."No.") +
                TCSEntry."Total TCS Including SHE CESS" + GetGSTAmount(SalesInvHeader."No.", 'CGST') + GetGSTAmount(SalesInvHeader."No.", 'SGST') +
                GetGSTAmount(SalesInvHeader."No.", 'IGST') + GetGSTAmount(SalesInvHeader."No.", 'CESS')) * LCYCurrency, 0.01, '='));
            JObject.Add('TotalAssessableAmount', Round(GetTaxableAmountSalesInvoice(SalesInvHeader."No.") * LCYCurrency, 0.01, '='));
            JObject.Add('TotalCgstAmount', GetGSTAmount(SalesInvHeader."No.", 'CGST'));
            JObject.Add('TotalSgstAmount', GetGSTAmount(SalesInvHeader."No.", 'SGST'));
            JObject.Add('TotalIgstAmount', GetGSTAmount(SalesInvHeader."No.", 'IGST'));
            JObject.Add('TotalCessAmount', GetGSTAmount(SalesInvHeader."No.", 'CESS'));
            ShippingAgentL.Get(SalesInvHeader."Shipping Agent Code");
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");
            JObject.Add('TransName', ShippingAgentL.Name);
            JObject.Add('Distance', 0);
            JObject.Add('TransDocNo', Format(SalesInvHeader."LR/RR No."));
            JObject.Add('TransMode', Format(TransportMethodL."Transportation Mode"));
            JObject.Add('TransDocDt', Format(SalesInvHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
            JObject.Add('VehNo', DelChr(SalesInvHeader."Vehicle No.", '=', ' ,/-<>  !@#$%^&*()_+{}'));
            JObject.Add('VehType', 'REGULAR');
            GetRoundingGLSales(CustomerL."Customer Posting Group", InvRoundingGL, PITRoungGL);
            SalesInvoiceLineL.SetFilter("No.", '<>%1&<>%2', InvRoundingGL, PITRoungGL);
            SalesInvoiceLineL.SetFilter(Type, '<>%1', SalesInvoiceLineL.Type::"G/L Account"); // To be removed add it to skip gl rounding line as above filter not working due to data issue.
            if SalesInvoiceLineL.FindSet() then
                repeat
                    JSubObject.Add('ProdName', SalesInvoiceLineL.Description);
                    if SalesInvoiceLineL.Type = SalesInvoiceLineL.Type::Item then begin
                        if ItemCategoryL.Get(SalesInvoiceLineL."Item Category Code") and (ItemCategoryL.Description <> '') then
                            JSubObject.Add('ProdDesc', Format(ItemCategoryL.Description))
                        else
                            JSubObject.Add('ProdDesc', Format(ItemCategoryL.Code));
                    end else
                        JSubObject.Add('ProdDesc', Format(SalesInvoiceLineL.Description));
                    JSubObject.Add('HsnCd', Format(SalesInvoiceLineL."HSN/SAC Code"));
                    JSubObject.Add('Qty', Format(SalesInvoiceLineL.Quantity));
                    if SalesInvoiceLineL."GST Group Type" = SalesInvoiceLineL."GST Group Type"::Goods then
                        JSubObject.Add('Unit', GetUOM(SalesInvoiceLineL."Unit of Measure Code"))
                    else
                        JSubObject.Add('Unit', 'OTH');
                    JSubObject.Add('CgstRt', GetGSTRate(SalesInvHeader."No.", 'CGST', SalesInvoiceLineL."Line No."));
                    JSubObject.Add('SgstRt', GetGSTRate(SalesInvHeader."No.", 'SGST', SalesInvoiceLineL."Line No."));
                    JSubObject.Add('IgstRt', GetGSTRate(SalesInvHeader."No.", 'IGST', SalesInvoiceLineL."Line No."));
                    JSubObject.Add('CesRt', GetGSTRate(SalesInvHeader."No.", 'CESS', SalesInvoiceLineL."Line No."));
                    JSubObject.Add('CesNonAdvAmt', 0);
                    JSubObject.Add('AssAmt', Round((SalesInvoiceLineL."Line Amount" - SalesInvoiceLineL."Line Discount Amount") * LCYCurrency, 0.01, '='));
                    JArrayL.Add(JSubObject);
                until SalesInvoiceLineL.Next() = 0;
            JObject.Add('ItemList', JArrayL);
            JObject.WriteTo(RequestText);

            SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Creation", LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", false);

            if JObject.ReadFrom(ResponseText) then begin
                if JObject.Contains('ewb_status') and (GetValueFromJsonObject(JObject, 'ewb_status').AsText() > '') then
                    StatusText := GetValueFromJsonObject(JObject, 'ewb_status').AsText();
                if JObject.Contains('govt_response') then begin
                    JObject.Get('govt_response', JToken1L);
                    JSubObject := JToken1L.AsObject();
                end;
                if GetValueFromJsonObject(JSubObject, 'Success').AsText() = 'Y' then begin
                    if JSubObject.Contains('EwbNo') then
                        EWayBillNo := GetValueFromJsonObject(JSubObject, 'EwbNo').AsText();
                    if JSubObject.Contains('EwbDt') then
                        EWayBillDateTime := GetValueFromJsonObject(JSubObject, 'EwbDt').AsText();
                    if JSubObject.Contains('EwbValidTill') then
                        EWayExpirationDT := GetValueFromJsonObject(JSubObject, 'EwbValidTill').AsText();
                    CreateLogEntry(SalesInvHeader."No.", DocType::Sales, SalesInvHeader."Posting Date", RequestText, ResponseText,
                        EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                    EInvoiceEntryL."E-Way Generated" := true;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                    EInvoiceEntryL."LR/RR Date" := SalesInvHeader."LR/RR Date";
                    EInvoiceEntryL."LR/RR No." := SalesInvHeader."LR/RR No.";
                    EInvoiceEntryL."Transport Method" := SalesInvHeader."Transport Method";
                    EInvoiceEntryL."Shipping Agent Code" := SalesInvHeader."Shipping Agent Code";
                    SalesInvHeader."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                    SalesInvHeader."Vehicle Type" := SalesInvHeader."Vehicle Type"::Regular;
                    SalesInvHeader.Modify();
                    Message(EWayGenerated, SalesInvHeader."No.");
                end else begin
                    CreateLogEntry(SalesInvHeader."No.", DocType::Sales, SalesInvHeader."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;
                    EInvoiceEntryL."E-Way Generated" := false;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    Message(EWayFailed, SalesInvHeader."No.");
                end;
                EInvoiceEntryL.Modify();
            end else
                Error(ResponseText);
        end;
    end;

    local procedure CreateJsonSalesInvoiceforIRN(SalesInvHeaderP: Record "Sales Invoice Header")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        TransportMethodL: Record "Transport Method";
        ShippingAgentL: Record "Shipping Agent";
        ShiptoAddressL: Record "Ship-to Address";
        StateL: Record State;
        CompanyInformationL: Record "Company Information";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        JSubObject: JsonObject;
        JToken: JsonToken;
        JToken1: JsonToken;
        ResponseText: Text;
        EWayBillNo: Text;
        EWayBillDateTime: Text;
        EWayExpirationDT: Text;
        StatusText: Text;
        RequestText: Text;
        I: Integer;
    begin
        SalesInvHeader.Copy(SalesInvHeaderP);
        LocationL.Get(SalesInvHeader."Location Code");
        EInvoiceSetupL.Get();
        SalesInvHeader.TestField("Transport Method");
        SalesInvHeader.TestField("Vehicle No.");
        SalesInvHeader.TestField("LR/RR No.");
        SalesInvHeader.TestField("LR/RR Date");
        TransportMethodL.Get(SalesInvHeader."Transport Method");
        CheckEwayBillStatus(SalesInvHeader."No.", 1);
        ShippingAgentL.Get(SalesInvHeader."Shipping Agent Code");
        LocationL.TestField("Post Code");
        CompanyInformationL.Get();
        JObject.Add('Irn', SalesInvHeader."IRN Hash");
        if SalesInvHeader."Distance (Km)" <> 0 then
            JObject.Add('Distance', SalesInvHeader."Distance (Km)");
        JObject.Add('TransMode', Format(TransportMethodL."Transportation Mode"));
        if ShippingAgentL."GST Registration No." > '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");
        JObject.Add('TransName', ShippingAgentL.Name);
        JObject.Add('TransDocDt', '18/08/2022'/*Format(SalesInvHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>')*/);
        JObject.Add('TransDocNo', SalesInvHeader."LR/RR No.");
        JObject.Add('VehNo', SalesInvHeader."Vehicle No.");
        JObject.Add('VehType', 'R');
        if SalesInvHeader."GST Customer Type" = SalesInvHeader."GST Customer Type"::Export then begin
            JSubObject.Add('Addr1', SalesInvHeader."Ship-to Address");
            JSubObject.Add('Addr2', SalesInvHeader."Ship-to Address 2");
            JSubObject.Add('Loc', SalesInvHeader."Ship-to City");
            JSubObject.Add('Pin', Format(SalesInvHeader."Ship-to Post Code"));
            if ShiptoAddressL.Get(SalesInvHeader."Sell-to Customer No.", SalesInvHeader."Ship-to Code") then
                StateL.Get(ShiptoAddressL.State)
            else
                if NOT StateL.Get(SalesInvHeader."GST Ship-to State Code") then
                    StateL.Get(SalesInvHeader.State);
            JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
            JObject.Add('ExpShipDtls', JSubObject);
        end;
        Clear(JSubObject);
        JSubObject.Add('Nm', LocationL.Name);
        JSubObject.Add('Addr1', LocationL.Address);
        JSubObject.Add('Addr2', LocationL."Address 2");
        JSubObject.Add('Loc', LocationL.City);
        JSubObject.Add('Pin', Format(LocationL."Post Code"));
        StateL.Get(LocationL."State Code");
        JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
        JObject.Add('DispDtls', JSubObject);
        JArray.Add(JObject);
        JArray.WriteTo(RequestText);

        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL Eway By IRN", LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", false);

        if JArray.ReadFrom(ResponseText) then begin
            for I := 0 to JArray.Count - 1 do begin
                JArray.Get(I, JToken);
                JObject := JToken.AsObject();

                if JObject.Contains('ewb_status') then
                    if (GetValueFromJsonObject(JObject, 'ewb_status').AsText() > '') then
                        StatusText := GetValueFromJsonObject(JObject, 'ewb_status').AsText();
                if JObject.Contains('govt_response') then begin
                    JObject.Get('govt_response', JToken1);
                    JSubObject := JToken1.AsObject();
                end;
                if GetValueFromJsonObject(JSubObject, 'Success').AsText() = 'Y' then begin
                    if JSubObject.Contains('EwbNo') then
                        EWayBillNo := GetValueFromJsonObject(JSubObject, 'EwbNo').AsText();
                    if JSubObject.Contains('EwbDt') then
                        EWayBillDateTime := GetValueFromJsonObject(JSubObject, 'EwbDt').AsText();
                    if JSubObject.Contains('EwbValidTill') then
                        EWayExpirationDT := GetValueFromJsonObject(JSubObject, 'EwbValidTill').AsText();
                    CreateLogEntry(SalesInvHeader."No.", DocType::Sales, SalesInvHeader."Posting Date", RequestText, ResponseText,
                      EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                    EInvoiceEntryL."E-Way Generated" := true;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                    //EInvoiceEntryL."LR/RR Date" := SalesInvHeader."e-Invoice LR/RR Date";
                    //EInvoiceEntryL."LR/RR No." := SalesInvHeader."e-Invoice LR/RR No.";
                    EInvoiceEntryL."Transport Method" := SalesInvHeader."Transport Method";
                    EInvoiceEntryL."Shipping Agent Code" := SalesInvHeader."Shipping Agent Code";
                    SalesInvHeader."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                    SalesInvHeader.Modify();
                    Message(EWayGenerated, SalesInvHeader."No.");
                end else begin
                    CreateLogEntry(SalesInvHeader."No.", DocType::Sales, SalesInvHeader."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;
                    EInvoiceEntryL."E-Way Generated" := false;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    Message(EWayFailed, SalesInvHeader."No.");
                end;
                EInvoiceEntryL.Modify();
            end;
        end else
            Error(ResponseText);
    end;

    local procedure UpdateVehicleNoSalesInvoice(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TransportMethodL: Record "Transport Method";
        StateL: Record State;
        ShippingAgentL: Record "Shipping Agent";
        ResponseText: Text;
        RequestText: Text;
    begin
        SalesInvHeader.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(SalesInvHeader."Location Code");
        EInvoiceSetupL.Get;

        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", 1);
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("New Vehicle No.");
        EInvoiceEntryL.TestField("Vehicle No. Update Remark");
        TransportMethodL.Get(EInvoiceEntryL."Transport Method");
        JObject.Add('EwbNumber', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('VehNo', DELCHR(EInvoiceEntryL."New Vehicle No.", '=', ' /\.<>-!@#$%^&*()_+'));
        JObject.Add('VehicleType', 'REGULAR');
        JObject.Add('FromPlace', LocationL.City);
        if StateL.Get(LocationL."State Code") then
            JObject.Add('FromState', StateL."State Code (GST Reg. No.)");
        if EInvoiceEntryL."New Pin Code From" <> '' then
            JObject.Add('FromPincode', EInvoiceEntryL."New Pin Code From");

        if EInvoiceEntryL."Vehicle No. Update Remark" IN
          [EInvoiceEntryL."Vehicle No. Update Remark"::NATURAL_CALAMITY, EInvoiceEntryL."Vehicle No. Update Remark"::ACCIDENT] then
            JObject.Add('ReasonCode', 'OTHERS')
        else
            JObject.Add('ReasonCode', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        JObject.Add('ReasonRemark', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        ShippingAgentL.Get(SalesInvHeader."Shipping Agent Code");
        if ShippingAgentL."GST Registration No." <> '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");
        JObject.Add('TransName', ShippingAgentL.Name);
        JObject.Add('TransDocNo', EInvoiceEntryL."LR/RR No.");
        JObject.Add('TransDocDt', Format(EInvoiceEntryL."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.Add('TransMode', Format(TransportMethodL."Transportation Mode"));
        JObject.WriteTo(RequestText);
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Update", LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') and GetValueFromJsonObject(JObject, 'errors').IsNull then begin
                SalesInvHeader."Vehicle No." := EInvoiceEntryL."New Vehicle No.";
                SalesInvHeader."Vehicle Type" := SalesInvHeader."Vehicle Type"::Regular;
                SalesInvHeader."Transport Method" := EInvoiceEntryL."Transport Method";
                SalesInvHeader."Shipping Agent Code" := EInvoiceEntryL."Shipping Agent Code";
                //SalesInvHeader."e-Invoice LR/RR Date" := EInvoiceEntryL."LR/RR Date";
                //SalesInvHeader."e-Invoice LR/RR No." := EInvoiceEntryL."LR/RR No.";
                SalesInvHeader.Modify();
                Message(VehicleUpdated, SalesInvHeader."No.");
            end else
                Error(ResponseText);
    end;

    local procedure CancelEWaySalesInvoice(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        EWayBillNo: Text;
        RequestText: Text;
    begin
        SalesInvHeader.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(SalesInvHeader."Location Code");
        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", 1);
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("Reason of Cancel");
        JObject.Add('ewbNo', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('cancelRsnCode', Format(EInvoiceEntryL."Reason of Cancel"));
        JObject.Add('cancelRmrk', 'Cancelled the order');
        JObject.WriteTo(RequestText);
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Cancelation", LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'ewbStatus').AsText() = 'CANCELLED') and GetValueFromJsonObject(JObject, 'errors').IsNull then begin
                Clear(EInvoiceEntryL."E-Way Bill No.");
                Clear(EInvoiceEntryL."E-Way Bill Date");
                Clear(EInvoiceEntryL."E-Way Bill Validity");
                Clear(EInvoiceEntryL."E-Way Generated");
                Clear(EInvoiceEntryL."New Vehicle No.");
                EInvoiceEntryL."E-Way Canceled" := true;
                EInvoiceEntryL."Vehicle No. Update Remark" := EInvoiceEntryL."Vehicle No. Update Remark"::" ";
                EInvoiceEntryL."E-Way Canceled Date" := Format(CURRENTDATETIME);
                EInvoiceEntryL.Modify();
                Message(EWayCancelled, SalesInvHeader."No.");
            end else
                Error(ResponseText);
    end;

    procedure GetEWaySalesInvoiceForPrint(SalesInvHeader: Record "Sales Invoice Header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin

        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", 1);
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(SalesInvHeader."Location Code");
            //JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            JObject.Add('print_type', 'DETAILED');
            JArray.Add(JObject);
            JArray.WriteTo(RequestText);
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?Format=PDF', LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", true);
        end;
    end;

    local procedure GetTaxableAmountSalesInvoice(DocNo: Code[20]): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocNo);
        SalesInvoiceLine.SetFilter(Quantity, '<>%1', 0);
        //SalesInvoiceLine.CalcSums("GST Base Amount");
        //if SalesInvoiceLine."GST Base Amount" <> 0 then
        //EXIT(SalesInvoiceLine."GST Base Amount");

        SalesInvoiceLine.CalcSums("Line Amount");
        EXIT(SalesInvoiceLine."Line Amount");
    end;

    local procedure GetRoundingGLSales(CustPostingGrp: Code[10]; var InvRoundingGL: Code[20]; var PITRoundingGL: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin

        if CustomerPostingGroup.Get(CustPostingGrp) then begin
            InvRoundingGL := CustomerPostingGroup."Invoice Rounding Account";
            //PITRoundingGL := CustomerPostingGroup."PIT Difference Acc.";
        end;
    end;

    procedure CreateJsonSalesCrMemo(SalesCrMemoHdrP: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        ShippingAgentL: Record "Shipping Agent";
        TransportMethodL: Record "Transport Method";
        CompanyInformationL: Record "Company Information";
        CustomerL: Record Customer;
        PostCodeL: Record "Post Code";
        StateL: Record State;
        "Entry/ExitPointL": Record "Entry/Exit Point";
        SalesCrMemoLineL: Record "Sales Cr.Memo Line";
        ShipToAddressL: Record "Ship-to Address";
        ItemCategoryL: Record "Item Category";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TCSEntry: Record "TCS Entry";
        JSubObject: JsonObject;
        JArrayL: JsonArray;
        JToken: JsonToken;
        LCYCurrency: Decimal;
        InvRoundingGL: Code[20];
        PITRoungGL: Code[20];
        ResponseText: Text;
        EWayBillNo: Text;
        EWayBillDateTime: Text;
        EWayExpirationDT: Text;
        StatusText: Text;
        RequestText: Text;
    begin
        if SalesCrMemoHdrP."IRN Hash" > '' then
            CreateJsonSalesCrMemoforIRN(SalesCrMemoHdrP)
        else begin
            SalesCrMemoHdr.Copy(SalesCrMemoHdrP);
            LocationL.Get(SalesCrMemoHdr."Location Code");
            EInvoiceSetupL.Get;
            SalesCrMemoHdr.TestField("Transport Method");
            SalesCrMemoHdr.TestField("Vehicle No.");
            SalesCrMemoHdr.TestField("LR/RR No.");
            SalesCrMemoHdr.TestField("LR/RR Date");
            TransportMethodL.Get(SalesCrMemoHdr."Transport Method");
            LocationL.TestField("Post Code");
            CompanyInformationL.Get();
            JObject.Add('DocumentNumber', SalesCrMemoHdr."No.");
            JObject.Add('DocumentType', 'INV');
            JObject.Add('DocumentDate', Format(SalesCrMemoHdr."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));
            JObject.Add('SupplyType', 'Inward');
            if CustomerL.Get(SalesCrMemoHdr."Bill-to Customer No.") then begin
                if CustomerL."GST Registration No." <> '' then
                    JObject.Add('SubSupplyType', 'Supply')
                else
                    if SalesCrMemoHdr."GST Customer Type" = SalesCrMemoHdr."GST Customer Type"::Export then
                        JObject.Add('SubSupplyType', 'Export')
                    else
                        JObject.Add('SubSupplyType', 'Supply');
            end;
            //JObject.Add('SubSupplyTypeDesc',''));
            JObject.Add('TransactionType', 'Regular');
            if CustomerL."GST Registration No." > '' then
                JSubObject.Add('Gstin', CustomerL."GST Registration No.")
            else
                JSubObject.Add('Gstin', 'URP');
            JSubObject.Add('LglNm', SalesCrMemoHdr."Ship-to Name");
            JSubObject.Add('TrdNm', SalesCrMemoHdr."Ship-to Name 2");
            JSubObject.Add('Addr1', SalesCrMemoHdr."Ship-to Address");
            JSubObject.Add('Addr2', SalesCrMemoHdr."Ship-to Address 2");
            JSubObject.Add('Loc', SalesCrMemoHdr."Ship-to City");
            if SalesCrMemoHdr."Ship-to Code" = '' then begin
                if SalesCrMemoHdr."GST Customer Type" = SalesCrMemoHdr."GST Customer Type"::Export then begin
                    if "Entry/ExitPointL".Get(SalesCrMemoHdr."Exit Point") then begin
                        if StateL.Get("Entry/ExitPointL"."State Code") then;
                        JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                        JSubObject.Add('Pin', Format("Entry/ExitPointL"."Post Code"));
                    end else begin
                        JSubObject.Add('Stcd', '96');
                        JSubObject.Add('Pin', '999999');
                    end;
                end else begin
                    if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                        JSubObject.Add('Stcd', '29');
                        JSubObject.Add('Pin', '562160');
                    end else begin
                        PostCodeL.SetRange(Code, SalesCrMemoHdr."Ship-to Post Code");
                        if PostCodeL.FindFirst() then;
                        if StateL.Get(SalesCrMemoHdr.State) then
                            JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)")
                        else
                            JSubObject.Add('Stcd', '');
                        JSubObject.Add('Pin', Format(PostCodeL.Code));
                    end;
                end;
            end else begin
                if ShipToAddressL.Get(SalesCrMemoHdr."Bill-to Customer No.", SalesCrMemoHdr."Ship-to Code") then begin
                    if SalesCrMemoHdr."GST Customer Type" = SalesCrMemoHdr."GST Customer Type"::Export then begin
                        JSubObject.Add('Stcd', '96')
                    end else begin
                        ShipToAddressL.TestField(State);
                        if StateL.Get(ShipToAddressL.State) then
                            JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)")
                        else
                            JSubObject.Add('Stcd', '');
                    end;
                end;
            end;
            JObject.Add('BuyerDtls', JSubObject);
            JSubObject.Add('LglNm', LocationL.Name);
            JSubObject.Add('TrdNm', LocationL."Name 2");
            JSubObject.Add('Addr1', LocationL.Address);
            JSubObject.Add('Addr2', LocationL."Address 2");
            JSubObject.Add('Loc', LocationL.City);
            if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                JSubObject.Add('Pin', '560027');
                JSubObject.Add('Gstin', '29AAFCD5862R000');
                JSubObject.Add('Stcd', '29');
            end else begin
                if LocationL."GST Registration No." <> '' then
                    JSubObject.Add('Gstin', LocationL."GST Registration No.")
                else
                    JSubObject.Add('Gstin', CompanyInformationL."GST Registration No.");
                PostCodeL.SetRange(Code, LocationL."Post Code");
                if PostCodeL.FindFirst() then;
                JSubObject.Add('Pin', Format(PostCodeL.Code));
                if StateL.Get(LocationL."State Code") then;
                JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
            end;
            JObject.Add('SellerDtls', JSubObject);
            SalesCrMemoLineL.SetRange("Document No.", SalesCrMemoHdr."No.");
            SalesCrMemoLineL.SetFilter(Quantity, '<>%1', 0);
            TCSEntry.SetRange("Document No.", SalesCrMemoLineL."Document No.");
            if TCSEntry.FindFirst() then
                ;
            //SalesCrMemoLineL.CalcSums("TDS/TCS Amount");
            //if SalesCrMemoLineL."TDS/TCS Amount" <> 0 then
            JObject.Add('OtherAmount', TCSEntry."Total TCS Including SHE CESS");
            if SalesCrMemoHdr."Currency Factor" <> 0 then
                LCYCurrency := 1 / SalesCrMemoHdr."Currency Factor"
            else
                LCYCurrency := 1;
            JObject.Add('TotalInvoiceAmount', Round((GetTaxableAmountSalesInvoice(SalesCrMemoHdr."No.") +
                TCSEntry."Total TCS Including SHE CESS" + GetGSTAmount(SalesCrMemoHdr."No.", 'CGST') + GetGSTAmount(SalesCrMemoHdr."No.", 'SGST') +
                GetGSTAmount(SalesCrMemoHdr."No.", 'IGST') + GetGSTAmount(SalesCrMemoHdr."No.", 'CESS')) * LCYCurrency, 0.01, '='));
            JObject.Add('TotalAssessableAmount', Round(GetTaxableAmountSalesInvoice(SalesCrMemoHdr."No.") * LCYCurrency, 0.01, '='));
            JObject.Add('TotalCgstAmount', GetGSTAmount(SalesCrMemoHdr."No.", 'CGST'));
            JObject.Add('TotalSgstAmount', GetGSTAmount(SalesCrMemoHdr."No.", 'SGST'));
            JObject.Add('TotalIgstAmount', GetGSTAmount(SalesCrMemoHdr."No.", 'IGST'));
            JObject.Add('TotalCessAmount', GetGSTAmount(SalesCrMemoHdr."No.", 'CESS'));
            ShippingAgentL.Get(SalesCrMemoHdr."Shipping Agent Code");
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");
            JObject.Add('TransName', ShippingAgentL.Name);
            JObject.Add('Distance', 0);
            JObject.Add('TransDocNo', Format(SalesCrMemoHdr."LR/RR No."));
            JObject.Add('TransMode', Format(TransportMethodL."Transportation Mode"));
            JObject.Add('TransDocDt', Format(SalesCrMemoHdr."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
            JObject.Add('VehNo', DELCHR(SalesCrMemoHdr."Vehicle No.", '=', ' ,/-<>  !@#$%^&*()_+{}'));
            JObject.Add('VehType', 'REGULAR');
            GetRoundingGLSales(CustomerL."Customer Posting Group", InvRoundingGL, PITRoungGL);
            SalesCrMemoLineL.SetFilter(Type, '<>%1', SalesCrMemoLineL.Type::" ");
            SalesCrMemoLineL.SetFilter("No.", '<>%1', InvRoundingGL);
            if SalesCrMemoLineL.FindSet() then
                repeat
                    JSubObject.Add('ProdName', SalesCrMemoLineL.Description);
                    if SalesCrMemoLineL.Type = SalesCrMemoLineL.Type::Item then begin
                        if ItemCategoryL.Get(SalesCrMemoLineL."Item Category Code") and (ItemCategoryL.Description <> '') then
                            JSubObject.Add('ProdDesc', ItemCategoryL.Description)
                        else
                            JSubObject.Add('ProdDesc', ItemCategoryL.Code);
                    end else
                        JSubObject.Add('ProdDesc', SalesCrMemoLineL.Description);
                    JSubObject.Add('HsnCd', SalesCrMemoLineL."HSN/SAC Code");
                    JSubObject.Add('Qty', SalesCrMemoLineL.Quantity);
                    if SalesCrMemoLineL."GST Group Type" = SalesCrMemoLineL."GST Group Type"::Goods then
                        JSubObject.Add('Unit', GetUOM(SalesCrMemoLineL."Unit of Measure Code"))
                    else
                        JSubObject.Add('Unit', 'OTH');
                    JSubObject.Add('CgstRt', GetGSTRate(SalesCrMemoHdr."No.", 'CGST', SalesCrMemoLineL."Line No."));
                    JSubObject.Add('SgstRt', GetGSTRate(SalesCrMemoHdr."No.", 'SGST', SalesCrMemoLineL."Line No."));
                    JSubObject.Add('IgstRt', GetGSTRate(SalesCrMemoHdr."No.", 'IGST', SalesCrMemoLineL."Line No."));
                    JSubObject.Add('CesRt', GetGSTRate(SalesCrMemoHdr."No.", 'CESS', SalesCrMemoLineL."Line No."));
                    JSubObject.Add('CesNonAdvAmt', 0);
                    JSubObject.Add('AssAmt', Round((SalesCrMemoLineL."Line Amount" - SalesCrMemoLineL."Line Discount Amount") * LCYCurrency, 0.01, '='));
                    JArrayL.Add(JSubObject);
                until SalesCrMemoLineL.Next() = 0;
            JObject.Add('ItemList', JArrayL);
            JObject.WriteTo(RequestText);

            SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Creation", LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", false);

            if JObject.ReadFrom(ResponseText) then begin
                if JObject.Contains('ewb_status') and (GetValueFromJsonObject(JObject, 'ewb_status').AsText() > '') then
                    StatusText := GetValueFromJsonObject(JObject, 'ewb_status').AsText();

                if JObject.Contains('govt_response') then begin
                    JObject.Get('govt_response', JToken);
                    JSubObject := JToken.AsObject();
                end;

                if JSubObject.Contains('Success') and (GetValueFromJsonObject(JSubObject, 'Success').AsText() = 'Y') then begin
                    if JSubObject.Contains('EwbNo') then
                        EWayBillNo := GetValueFromJsonObject(JSubObject, 'EwbNo').AsText();
                    if JSubObject.Contains('EwbDt') then
                        EWayBillDateTime := GetValueFromJsonObject(JSubObject, 'EwbDt').AsText();
                    if JSubObject.Contains('') then
                        EWayExpirationDT := GetValueFromJsonObject(JSubObject, 'EwbValidTill').AsText();
                    CreateLogEntry(SalesCrMemoHdr."No.", DocType::Sales, SalesCrMemoHdr."Posting Date", RequestText, ResponseText,
                      EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                    EInvoiceEntryL."E-Way Generated" := true;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                    EInvoiceEntryL."LR/RR Date" := SalesCrMemoHdr."LR/RR Date";
                    EInvoiceEntryL."LR/RR No." := SalesCrMemoHdr."LR/RR No.";
                    EInvoiceEntryL."Transport Method" := SalesCrMemoHdr."Transport Method";
                    EInvoiceEntryL."Shipping Agent Code" := SalesCrMemoHdr."Shipping Agent Code";
                    SalesCrMemoHdr."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                    SalesCrMemoHdr."Vehicle Type" := SalesCrMemoHdr."Vehicle Type"::Regular;
                    SalesCrMemoHdr.Modify();
                    Message(EWayGenerated, SalesCrMemoHdr."No.");
                end else begin
                    CreateLogEntry(SalesCrMemoHdr."No.", DocType::Sales, SalesCrMemoHdr."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;
                    EInvoiceEntryL."E-Way Generated" := false;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    Message(EWayFailed, SalesCrMemoHdr."No.");
                end;
                EInvoiceEntryL.Modify();
            end else
                Error(ResponseText);
        end;
    end;

    local procedure CreateJsonSalesCrMemoforIRN(SalesCrMemoHdrP: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        TransportMethodL: Record "Transport Method";
        ShippingAgentL: Record "Shipping Agent";
        ShiptoAddressL: Record "Ship-to Address";
        StateL: Record State;
        CompanyInformationL: Record "Company Information";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        JSubObject: JsonObject;
        ResponseText: Text;
        EWayBillNo: Text;
        EWayBillDateTime: Text;
        EWayExpirationDT: Text;
        StatusText: Text;
        RequestText: Text;
        I: Integer;
        JToken: JsonToken;
        JToken1: JsonToken;
    begin
        SalesCrMemoHdr.Copy(SalesCrMemoHdrP);
        LocationL.Get(SalesCrMemoHdr."Location Code");
        EInvoiceSetupL.Get();
        SalesCrMemoHdr.TestField("Transport Method");
        SalesCrMemoHdr.TestField("Vehicle No.");
        SalesCrMemoHdr.TestField("LR/RR No.");
        SalesCrMemoHdr.TestField("LR/RR Date");
        TransportMethodL.Get(SalesCrMemoHdr."Transport Method");
        CheckEwayBillStatus(SalesCrMemoHdr."No.", 1);
        ShippingAgentL.Get(SalesCrMemoHdr."Shipping Agent Code");
        LocationL.TestField("Post Code");
        CompanyInformationL.Get;
        JObject.Add('Irn', SalesCrMemoHdr."IRN Hash");
        if SalesCrMemoHdr."Distance (Km)" <> 0 then
            JObject.Add('Distance', SalesCrMemoHdr."Distance (Km)");
        JObject.Add('TransMode', Format(TransportMethodL."Transportation Mode"));
        if ShippingAgentL."GST Registration No." <> '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");
        JObject.Add('TransName', ShippingAgentL.Name);
        JObject.Add('TransDocDt', Format(SalesCrMemoHdr."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.Add('TransDocNo', SalesCrMemoHdr."LR/RR No.");
        JObject.Add('VehNo', SalesCrMemoHdr."Vehicle No.");
        JObject.Add('VehType', 'R');
        if SalesCrMemoHdr."GST Customer Type" = SalesCrMemoHdr."GST Customer Type"::Export then begin
            JSubObject.Add('Addr1', SalesCrMemoHdr."Ship-to Address");
            JSubObject.Add('Addr2', SalesCrMemoHdr."Ship-to Address 2");
            JSubObject.Add('Loc', SalesCrMemoHdr."Ship-to City");
            JSubObject.Add('Pin', Format(SalesCrMemoHdr."Ship-to Post Code"));
            if ShiptoAddressL.Get(SalesCrMemoHdr."Sell-to Customer No.", SalesCrMemoHdr."Ship-to Code") then
                StateL.Get(ShiptoAddressL.State)
            else
                if NOT StateL.Get(SalesCrMemoHdr."GST Ship-to State Code") then
                    StateL.Get(SalesCrMemoHdr.State);
            JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
            JObject.Add('ExpShipDtls', JSubObject);
        end;
        Clear(JSubObject);
        JSubObject.Add('Nm', LocationL.Name);
        JSubObject.Add('Addr1', LocationL.Address);
        JSubObject.Add('Addr2', LocationL."Address 2");
        JSubObject.Add('Loc', LocationL.City);
        JSubObject.Add('Pin', Format(LocationL."Post Code"));
        StateL.Get(LocationL."State Code");
        JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
        JObject.Add('DispDtls', JSubObject);
        JArray.Add(JObject);
        JArray.WriteTo(RequestText);
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL Eway By IRN", LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", false);

        if JArray.ReadFrom(ResponseText) then begin
            for I := 0 to JArray.Count - 1 do begin
                JArray.Get(I, JToken);
                JObject := JToken.AsObject();
                if JObject.Contains('ewb_status') and (GetValueFromJsonObject(JObject, 'ewb_status').AsText() > '') then
                    StatusText := GetValueFromJsonObject(JObject, 'ewb_status').AsText();
                if JObject.Contains('govt_response') then begin
                    JObject.Get('govt_response', JToken1);
                    JSubObject := JToken1.AsObject();
                end;
                if GetValueFromJsonObject(JSubObject, 'Success').AsText() = 'Y' then begin
                    if JSubObject.Contains('EwbNo') then
                        EWayBillNo := GetValueFromJsonObject(JSubObject, 'EwbNo').AsText();
                    if JSubObject.Contains('EwbDt') then
                        EWayBillDateTime := GetValueFromJsonObject(JSubObject, 'EwbDt').AsText();
                    if JSubObject.Contains('EwbValidTill') then
                        EWayExpirationDT := GetValueFromJsonObject(JSubObject, 'EwbValidTill').AsText();
                    CreateLogEntry(SalesCrMemoHdr."No.", DocType::Sales, SalesCrMemoHdr."Posting Date", RequestText, ResponseText,
                      EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                    EInvoiceEntryL."E-Way Generated" := true;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                    EInvoiceEntryL."LR/RR Date" := SalesCrMemoHdr."LR/RR Date";
                    EInvoiceEntryL."LR/RR No." := SalesCrMemoHdr."LR/RR No.";
                    EInvoiceEntryL."Transport Method" := SalesCrMemoHdr."Transport Method";
                    EInvoiceEntryL."Shipping Agent Code" := SalesCrMemoHdr."Shipping Agent Code";
                    SalesCrMemoHdr."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                    SalesCrMemoHdr.Modify();
                    Message(EWayGenerated, SalesCrMemoHdr."No.");
                end else begin
                    CreateLogEntry(SalesCrMemoHdr."No.", DocType::Sales, SalesCrMemoHdr."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;
                    EInvoiceEntryL."E-Way Generated" := false;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    Message(EWayFailed, SalesCrMemoHdr."No.");
                end;
                EInvoiceEntryL.Modify();
            end;
        end else
            Error(ResponseText);
    end;

    procedure CreateJsonPurchaseReturn(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        JSubObject: JsonObject;
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        TransportMethodL: Record "Transport Method";
        ShippingAgentL: Record "Shipping Agent";
        CompanyInformationL: Record "Company Information";
        PostCodeL: Record "Post Code";
        VendorL: Record Vendor;
        StateL: Record State;
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        ItemCategoryL: Record "Item Category";
        InvRoundingGL: Code[20];
        ResponseText: Text;
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        EWayBillNo: Text;
        EWayBillDateTime: Text;
        EWayExpirationDT: Text;
        StatusText: Text;
        RequestText: Text;
        JToken: JsonToken;
    begin
        PurchCrMemoHdr.TestField("Vehicle No.");
        PurchCrMemoHdr.TestField("Shipping Agent Code");
        PurchCrMemoHdr.TestField("Transport Method");
        PurchCrMemoHdr.TestField("LR/RR No.");
        PurchCrMemoHdr.TestField("LR/RR Date");

        LocationL.Get(PurchCrMemoHdr."Location Code");
        EInvoiceSetupL.Get;
        TransportMethodL.Get(PurchCrMemoHdr."Transport Method");
        CheckEwayBillStatus(PurchCrMemoHdr."No.", 7);
        ShippingAgentL.Get(PurchCrMemoHdr."Shipping Agent Code");
        CompanyInformationL.Get();
        JObject.Add('DocumentNumber', COPYSTR(DELCHR(PurchCrMemoHdr."No.", '=', '/'), 1, 9));
        JObject.Add('DocumentType', 'OTH');
        JObject.Add('DocumentDate', '18/08/2022'/*Format(PurchCrMemoHdr."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>')*/);
        JObject.Add('SupplyType', 'Outward');
        JObject.Add('TransactionType', 'Regular');
        JObject.Add('SubSupplyType', '8');
        JObject.Add('SubSupplyTypeDesc', 'OTH');

        JSubObject.Add('LglNm', LocationL.Name);
        JSubObject.Add('TrdNm', LocationL.Name);
        JSubObject.Add('Addr1', LocationL.Address);
        JSubObject.Add('Addr2', LocationL."Address 2");
        JSubObject.Add('Loc', LocationL.City);
        PostCodeL.SetRange(Code, LocationL."Post Code");
        if PostCodeL.FindFirst() then;
        JSubObject.Add('Pin', Format(PostCodeL.Code));
        if (EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo) then
            JSubObject.Add('Gstin', '29AAFCD5862R000')
        else
            if LocationL."GST Registration No." <> '' then
                JSubObject.Add('Gstin', LocationL."GST Registration No.")
            else
                JSubObject.Add('Gstin', CompanyInformationL."GST Registration No.");
        if StateL.Get(LocationL."State Code") then
            if StateL."State Code (GST Reg. No.)" <> '' then
                JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)")
            else
                JSubObject.Add('Stcd', '');
        JObject.Add('SellerDtls', JSubObject);
        Clear(JSubObject);
        JSubObject.Add('LglNm', PurchCrMemoHdr."Ship-to Name");
        JSubObject.Add('TrdNm', PurchCrMemoHdr."Ship-to Name");
        JSubObject.Add('Addr1', PurchCrMemoHdr."Ship-to Address");
        JSubObject.Add('Addr2', PurchCrMemoHdr."Ship-to Address 2");
        JSubObject.Add('Loc', PurchCrMemoHdr."Ship-to City");
        if VendorL.Get(PurchCrMemoHdr."Pay-to Vendor No.") then
            if VendorL."GST Registration No." <> '' then
                JSubObject.Add('Gstin', VendorL."GST Registration No.")
            else
                JSubObject.Add('Gstin', 'URP');
        if StateL.Get(PurchCrMemoHdr."Location State Code") then
            if StateL."State Code (GST Reg. No.)" > '' then
                JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)")
            else
                JSubObject.Add('stcd', '');
        PostCodeL.SetRange(Code, PurchCrMemoHdr."Ship-to Post Code");
        if PostCodeL.FindFirst() then
            JSubObject.Add('Pin', Format(PostCodeL.Code));
        JObject.Add('BuyerDtls', JSubObject);

        JObject.Add('TotalInvoiceAmount', Round((GetTaxableAmountPCrMemo(PurchCrMemoHdr."No.") +
          GetGSTAmount(PurchCrMemoHdr."No.", 'CGST') + GetGSTAmount(PurchCrMemoHdr."No.", 'SGST') + GetGSTAmount(PurchCrMemoHdr."No.", 'IGST') +
          GetGSTAmount(PurchCrMemoHdr."No.", 'CESS')), 0.01, '='));
        JObject.Add('TotalAssessableAmount', GetTaxableAmountPCrMemo(PurchCrMemoHdr."No."));
        JObject.Add('TotalCgstAmount', GetGSTAmount(PurchCrMemoHdr."No.", 'CGST'));
        JObject.Add('TotalSgstAmount', GetGSTAmount(PurchCrMemoHdr."No.", 'SGST'));
        JObject.Add('TotalIgstAmount', GetGSTAmount(PurchCrMemoHdr."No.", 'IGST'));
        JObject.Add('TotalCessAmount', GetGSTAmount(PurchCrMemoHdr."No.", 'CESS'));
        if ShippingAgentL."GST Registration No." > '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");
        JObject.Add('TransName', ShippingAgentL.Name);
        JObject.Add('transactionType', 'Regular');
        JObject.Add('TransDocNo', PurchCrMemoHdr."LR/RR No.");
        JObject.Add('TransMode', Format(TransportMethodL."Transportation Mode"));
        JObject.Add('Distance', PurchCrMemoHdr."Distance (Km)");
        JObject.Add('TransDocDt', Format(PurchCrMemoHdr."LR/RR Date"));
        JObject.Add('VehNo', DELCHR(PurchCrMemoHdr."Vehicle No.", '=', ' ,/-<>  !@#$%^&*()_+{}'));
        JObject.Add('VehType', 'Regular');

        GetRoundingGLPurchase(VendorL."Vendor Posting Group", InvRoundingGL);
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");
        PurchCrMemoLine.SetFilter("No.", '<>%1', InvRoundingGL);
        PurchCrMemoLine.SetFilter(Quantity, '<>%1', 0);
        if PurchCrMemoLine.FindSet() then
            repeat
                Clear(JSubObject);
                JSubObject.Add('ProdName', PurchCrMemoLine."Item Category Code");
                if PurchCrMemoLine.Type = PurchCrMemoLine.Type::Item then begin
                    if (ItemCategoryL.Get(PurchCrMemoLine."Item Category Code")) and (ItemCategoryL.Description <> '') then
                        JSubObject.Add('ProdDesc', ItemCategoryL.Description)
                    else
                        JSubObject.Add('ProdDesc', ItemCategoryL.Code);
                end else
                    JSubObject.Add('ProdDesc', PurchCrMemoLine.Description);
                JSubObject.Add('HsnCd', PurchCrMemoLine."HSN/SAC Code");
                JSubObject.Add('Qty', PurchCrMemoLine.Quantity);
                if PurchCrMemoLine."GST Group Type" = PurchCrMemoLine."GST Group Type"::Goods then
                    JSubObject.Add('Unit', GetUOM(PurchCrMemoLine."Unit of Measure Code"))
                else
                    JSubObject.Add('Unit', 'OTH');
                JSubObject.Add('CgstRt', GetGSTRate(PurchCrMemoLine."Document No.", 'CGST', PurchCrMemoLine."Line No."));
                JSubObject.Add('SgstRt', GetGSTRate(PurchCrMemoLine."Document No.", 'SGST', PurchCrMemoLine."Line No."));
                JSubObject.Add('IgstRt', GetGSTRate(PurchCrMemoLine."Document No.", 'IGST', PurchCrMemoLine."Line No."));
                JSubObject.Add('CesRt', GetGSTRate(PurchCrMemoLine."Document No.", 'CESS', PurchCrMemoLine."Line No."));
                JSubObject.Add('CesNonAdvAmt', 0);
                JSubObject.Add('AssAmt', (PurchCrMemoLine."Line Amount" - PurchCrMemoLine."Line Discount Amount") /*PurchCrMemoLine."GST Base Amount"*/);
                JArray.Add(JSubObject);
            until PurchCrMemoLine.Next() = 0;
        JObject.Add('ItemList', JArray);
        JObject.WriteTo(RequestText);

        SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Creation", LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", false);

        if JObject.ReadFrom(ResponseText) then begin
            if JObject.Contains('ewb_status') then
                if GetValueFromJsonObject(JObject, 'ewb_status').AsText() > '' then
                    StatusText := GetValueFromJsonObject(JObject, 'ewb_status').AsText();

            if JObject.Contains('govt_response') then begin
                JObject.Get('govt_response', JToken);
                JSubObject := JToken.AsObject();
            end;

            if GetValueFromJsonObject(JSubObject, 'Success').AsText() = 'Y' then begin
                if JSubObject.Contains('EwbNo') then
                    EWayBillNo := GetValueFromJsonObject(JSubObject, 'EwbNo').AsText();
                if JSubObject.Contains('EwbDt') then
                    EWayBillDateTime := GetValueFromJsonObject(JSubObject, 'EwbDt').AsText();
                if JSubObject.Contains('EwbValidTill') then
                    EWayExpirationDT := GetValueFromJsonObject(JSubObject, 'EwbValidTill').AsText();
                CreateLogEntry(PurchCrMemoHdr."No.", DocType::Purchase, PurchCrMemoHdr."Posting Date", RequestText, ResponseText,
                  EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                EInvoiceEntryL."E-Way Generated" := true;
                EInvoiceEntryL."E-Way Canceled" := false;
                EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                EInvoiceEntryL."LR/RR Date" := PurchCrMemoHdr."LR/RR Date";
                EInvoiceEntryL."LR/RR No." := PurchCrMemoHdr."LR/RR No.";
                EInvoiceEntryL."Transport Method" := PurchCrMemoHdr."Transport Method";
                EInvoiceEntryL."Shipping Agent Code" := PurchCrMemoHdr."Shipping Agent Code";
                PurchCrMemoHdr."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                PurchCrMemoHdr."Vehicle Type" := PurchCrMemoHdr."Vehicle Type"::Regular;
                PurchCrMemoHdr.Modify();
                Message(EWayGenerated, PurchCrMemoHdr."No.");
            end else begin
                CreateLogEntry(PurchCrMemoHdr."No.", DocType::Purchase, PurchCrMemoHdr."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;
                EInvoiceEntryL."E-Way Generated" := false;
                EInvoiceEntryL."E-Way Canceled" := false;
                Message(EWayFailed, PurchCrMemoHdr."No.");
            end;
            EInvoiceEntryL.Modify();
        end else
            Error(ResponseText);
    end;

    local procedure GetTaxableAmountPCrMemo(DocNo: Code[20]): Decimal
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", DocNo);
        PurchCrMemoLine.SetFilter(Quantity, '<>%1', 0);
        //PurchCrMemoLine.CalcSums("GST Base Amount");
        //if PurchCrMemoLine."GST Base Amount" <> 0 then
        //EXIT(PurchCrMemoLine."GST Base Amount");
        PurchCrMemoLine.CalcSums("Line Amount");
        EXIT(PurchCrMemoLine."Line Amount");
    end;

    local procedure UpdateVehicleNoPurchaseCrMemo(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TransportMethodL: Record "Transport Method";
        StateL: Record State;
        ShippingAgentL: Record "Shipping Agent";
        ResponseText: Text;
        RequestText: Text;
    begin
        PurchCrMemoHdr.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(PurchCrMemoHdr."Location Code");
        EInvoiceSetupL.Get;

        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", 7);
        EInvoiceEntryL.SetRange("Document No.", PurchCrMemoHdr."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("New Vehicle No.");
        EInvoiceEntryL.TestField("Vehicle No. Update Remark");
        TransportMethodL.Get(PurchCrMemoHdr."Transport Method");
        JObject.Add('EwbNumber', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('VehNo', DELCHR(EInvoiceEntryL."New Vehicle No.", '=', ' /\.<>-!@#$%^&*()_+'));
        JObject.Add('VehicleType', 'REGULAR');
        JObject.Add('FromPlace', LocationL.City);
        if StateL.Get(LocationL."State Code") then
            JObject.Add('FromState', StateL.Code);
        if EInvoiceEntryL."New Pin Code From" > '' then
            JObject.Add('FromPincode', EInvoiceEntryL."New Pin Code From");

        if EInvoiceEntryL."Vehicle No. Update Remark" IN
          [EInvoiceEntryL."Vehicle No. Update Remark"::NATURAL_CALAMITY, EInvoiceEntryL."Vehicle No. Update Remark"::ACCIDENT] then
            JObject.Add('ReasonCode', 'OTHERS')
        else
            JObject.Add('ReasonCode', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        JObject.Add('ReasonRemark', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        ShippingAgentL.Get(PurchCrMemoHdr."Shipping Agent Code");
        if ShippingAgentL."GST Registration No." <> '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");
        JObject.Add('TransName', ShippingAgentL.Name);
        JObject.Add('TransDocNo', EInvoiceEntryL."LR/RR No.");
        JObject.Add('TransDocDt', Format(EInvoiceEntryL."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.Add('TransMode', Format(TransportMethodL."Transportation Mode"));
        JObject.Add('DocumentNumber', EInvoiceEntryL."Document No.");
        JObject.Add('DocumentType', 'INV');
        JObject.Add('DocumentDate', Format(EInvoiceEntryL."Document Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.WriteTo(RequestText);
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Update", LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') and GetValueFromJsonObject(JObject, 'errors').IsNull then begin
                PurchCrMemoHdr."Vehicle No." := EInvoiceEntryL."New Vehicle No.";
                PurchCrMemoHdr."Vehicle Type" := PurchCrMemoHdr."Vehicle Type"::Regular;
                PurchCrMemoHdr."Transport Method" := EInvoiceEntryL."Transport Method";
                PurchCrMemoHdr."Shipping Agent Code" := EInvoiceEntryL."Shipping Agent Code";
                PurchCrMemoHdr."LR/RR Date" := EInvoiceEntryL."LR/RR Date";
                PurchCrMemoHdr."LR/RR No." := EInvoiceEntryL."LR/RR No.";
                PurchCrMemoHdr.Modify();
                Message(VehicleUpdated, PurchCrMemoHdr."No.");
            end else
                Error(ResponseText);
    end;

    local procedure CancelEWayPurchaseCrMemo(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin
        PurchCrMemoHdr.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(PurchCrMemoHdr."Location Code");
        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", 2);
        EInvoiceEntryL.SetRange("Document No.", PurchCrMemoHdr."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("Reason of Cancel");
        JObject.Add('ewbNo', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('cancelRsnCode', Format(EInvoiceEntryL."Reason of Cancel"));
        JObject.Add('cancelRmrk', 'Cancelled the order');
        JObject.WriteTo(RequestText);

        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Cancelation", LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", false);

        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'ewbStatus').AsText() = 'CANCELLED') and GetValueFromJsonObject(JObject, 'errors').IsNull then begin
                Clear(EInvoiceEntryL."E-Way Bill No.");
                Clear(EInvoiceEntryL."E-Way Bill Date");
                Clear(EInvoiceEntryL."E-Way Bill Validity");
                Clear(EInvoiceEntryL."E-Way Generated");
                Clear(EInvoiceEntryL."New Vehicle No.");
                EInvoiceEntryL."E-Way Canceled" := true;
                EInvoiceEntryL."Vehicle No. Update Remark" := EInvoiceEntryL."Vehicle No. Update Remark"::" ";
                EInvoiceEntryL."E-Way Canceled Date" := Format(CURRENTDATETIME);
                EInvoiceEntryL.Modify();
                Message(EWayCancelled, PurchCrMemoHdr."No.");
            end else
                Error(ResponseText);
    end;

    procedure GetEWayPurchaseReturnforPrint(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin
        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", 2);
        EInvoiceEntryL.SetRange("Document No.", PurchCrMemoHdr."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(PurchCrMemoHdr."Location Code");
            JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            JObject.Add('ewb_numbers', JArray);
            JObject.Add('print_type', 'DETAILED');
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL", LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", true);
        end;
    end;

    local procedure GetRoundingGLPurchase(VendorPostingGrp: Code[10]; var InvRoundingGL: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin

        if VendorPostingGroup.Get(VendorPostingGrp) then begin
            InvRoundingGL := VendorPostingGroup."Invoice Rounding Account";
        end;
    end;

    procedure CreateJsonTranferShipment(var TransShipHdr: Record "Transfer Shipment Header")
    var
        JSubObject: JsonObject;
        JArrayL: JsonArray;
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        TransportMethodL: Record "Transport Method";
        ShippingAgentL: Record "Shipping Agent";
        CompanyInformationL: Record "Company Information";
        PostCodeL: Record "Post Code";
        StateL: Record State;
        ItemCategoryL: Record "Item Category";
        TransferShipmentLine: Record "Transfer Shipment Line";
        ResponseText: Text;
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        EWayBillNo: Text;
        EWayBillDateTime: Text;
        EWayExpirationDT: Text;
        StatusText: Text;
        Status: Option " ",PartA,"PartA/B";
        RequestText: Text;
        JToken: JsonToken;
    begin

        TransShipHdr.TestField("Vehicle No.");
        TransShipHdr.TestField("Shipping Agent Code");
        TransShipHdr.TestField("Transport Method");
        TransShipHdr.TestField("LR/RR No.");
        TransShipHdr.TestField("LR/RR Date");

        LocationL.Get(TransShipHdr."Transfer-from Code");
        EInvoiceSetupL.Get;
        if Status = Status::"PartA/B" then begin
            TransShipHdr.TestField("Vehicle No.");
        end;
        CompanyInformationL.Get;
        CheckEwayBillStatus(TransShipHdr."No.", 3);
        TransportMethodL.Get(TransShipHdr."Transport Method");
        JObject.Add('SupplyType', 'Outward');
        if TransShipHdr."Trsf.-from Country/Region Code" <> 'IN' then
            JObject.Add('DocumentType', 'OTH')
        else
            JObject.Add('DocumentType', 'CHL');

        JObject.Add('DocumentNumber', TransShipHdr."No.");
        JObject.Add('DocumentDate', Format(TransShipHdr."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.Add('TransactionType', 'Regular'); // hard code
        if TransShipHdr."Trsf.-from Country/Region Code" = 'IN' then begin
            JObject.Add('SubSupplyType', 'Others');
            JObject.Add('SubSupplyTypeDesc', 'Others');
        end else begin
            JObject.Add('SubSupplyType', 'Export');
            JObject.Add('SubSupplyTypeDesc', 'Export');
        end;

        JSubObject.Add('LglNm', LocationL.Name);
        JSubObject.Add('TrdNm', LocationL.Name);
        JSubObject.Add('Addr1', LocationL.Address);
        JSubObject.Add('Addr2', LocationL."Address 2");
        JSubObject.Add('Loc', LocationL.City);
        PostCodeL.SetRange(Code, TransShipHdr."Transfer-from Post Code");
        if PostCodeL.FindFirst() then
            JObject.Add('Pin', Format(PostCodeL.Code));
        if (EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo) then
            JSubObject.Add('Gstin', '29AAFCD5862R000')
        else
            if LocationL.Get(TransShipHdr."Transfer-from Code") then
                if LocationL."GST Registration No." <> '' then
                    JSubObject.Add('Gstin', LocationL."GST Registration No.")
                else
                    JSubObject.Add('Gstin', CompanyInformationL."GST Registration No.");
        if StateL.Get(LocationL."State Code") then
            JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
        JObject.Add('SellerDtls', JSubObject);

        JSubObject.Add('LglNm', TransShipHdr."Transfer-to Name");
        JSubObject.Add('TrdNm', TransShipHdr."Transfer-to Name");
        JSubObject.Add('Addr1', TransShipHdr."Transfer-to Address");
        JSubObject.Add('Addr2', TransShipHdr."Transfer-to Address 2");
        JSubObject.Add('Loc', TransShipHdr."Transfer-to City");
        if LocationL.Get(TransShipHdr."Transfer-to Code") then
            JSubObject.Add('Gstin', LocationL."GST Registration No.");
        if StateL.Get(LocationL."State Code") then
            JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
        JSubObject.Add('Pin', TransShipHdr."Transfer-to Post Code");
        JObject.Add('BuyerDtls', JSubObject);

        TransferShipmentLine.SetRange("Document No.", TransShipHdr."No.");
        TransferShipmentLine.SetFilter(Quantity, '<>%1', 0);
        //TransferShipmentLine.CalcSums("Total GST Amount");
        JObject.Add('TotalInvoiceAmount', GetTaxableAmountTransfer(TransShipHdr."No.") /*+  TransferShipmentLine."Total GST Amount"*/);
        JObject.Add('TotalAssessableAmount', GetTaxableAmountTransfer(TransShipHdr."No."));
        JObject.Add('TotalCgstAmount', GetGSTAmount(TransShipHdr."No.", 'CGST'));
        JObject.Add('TotalSgstAmoun', GetGSTAmount(TransShipHdr."No.", 'SGST'));
        JObject.Add('TotalIgstAmount', GetGSTAmount(TransShipHdr."No.", 'IGST'));
        JObject.Add('TotalCessAmount', GetGSTAmount(TransShipHdr."No.", 'CESS'));
        ShippingAgentL.Get(TransShipHdr."Shipping Agent Code");
        if ShippingAgentL."GST Registration No." > '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");
        JObject.Add('TransName', ShippingAgentL.Name);
        JObject.Add('TransName', ShippingAgentL.Name);
        JObject.Add('transDistance', '');
        JObject.Add('transactionType', 'Regular');
        JObject.Add('TransDocNo', TransShipHdr."LR/RR No.");
        JObject.Add('TransMode', Format(TransportMethodL."Transportation Mode"));
        JObject.Add('TransDocDt', Format(TransShipHdr."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.Add('VehNo', DELCHR(TransShipHdr."Vehicle No.", '=', ' ,/-<>  !@#$%^&*()_+{}'));
        JObject.Add('VehType', 'Regular');

        TransferShipmentLine.RESET;
        TransferShipmentLine.SetRange("Document No.", TransShipHdr."No.");
        TransferShipmentLine.SetFilter(Quantity, '<>%1', 0);
        if TransferShipmentLine.FindSet() then
            repeat
                JSubObject.Add('ProdName', TransferShipmentLine."Item Category Code");
                JSubObject.Add('ProdDesc', TransferShipmentLine."Item Category Code");
                JSubObject.Add('HsnCd', Format(TransferShipmentLine."HSN/SAC Code"));
                JSubObject.Add('Qty', TransferShipmentLine.Quantity);

                JSubObject.Add('Unit', GetUOM(TransferShipmentLine."Unit of Measure Code"));
                JSubObject.Add('CgstRt', GetGSTRate(TransferShipmentLine."Document No.", 'CGST', TransferShipmentLine."Line No."));
                JSubObject.Add('SgstRt', GetGSTRate(TransferShipmentLine."Document No.", 'SGST', TransferShipmentLine."Line No."));
                JSubObject.Add('IgstRt', GetGSTRate(TransferShipmentLine."Document No.", 'IGST', TransferShipmentLine."Line No."));
                JSubObject.Add('CesRt', GetGSTRate(TransferShipmentLine."Document No.", 'CESS', TransferShipmentLine."Line No."));
                JSubObject.Add('CesNonAdvAmt', 0);
                JSubObject.Add('AssAmt', (TransferShipmentLine.Amount));
                JArrayL.Add(JSubObject);
            until TransferShipmentLine.Next() = 0;
        JObject.Add('ItemList', JArrayL);
        JObject.WriteTo(RequestText);

        SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Creation", LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", false);

        if JObject.ReadFrom(ResponseText) then begin
            if JObject.Contains('ewb_status') and (GetValueFromJsonObject(JObject, 'ewb_status').AsText() > '') then
                StatusText := GetValueFromJsonObject(JObject, 'ewb_status').AsText();

            if JObject.Contains('govt_response') then begin
                JObject.Get('govt_response', JToken);
                JSubObject := JToken.AsObject();
            end;

            if GetValueFromJsonObject(JSubObject, 'Success').AsText() = 'Y' then begin
                if JSubObject.Contains('EwbNo') then
                    EWayBillNo := GetValueFromJsonObject(JSubObject, 'EwbNo').AsText();
                if JSubObject.Contains('EwbDt') then
                    EWayBillDateTime := GetValueFromJsonObject(JSubObject, 'EwbDt').AsText();
                if JSubObject.Contains('EwbValidTill') then
                    EWayExpirationDT := GetValueFromJsonObject(JSubObject, 'EwbValidTill').AsText();
                CreateLogEntry(TransShipHdr."No.", DocType::Transfer, TransShipHdr."Posting Date", RequestText, ResponseText,
                  EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                EInvoiceEntryL."E-Way Generated" := true;
                EInvoiceEntryL."E-Way Canceled" := false;
                EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                EInvoiceEntryL."LR/RR Date" := TransShipHdr."LR/RR Date";
                EInvoiceEntryL."LR/RR No." := TransShipHdr."LR/RR No.";
                EInvoiceEntryL."Transport Method" := TransShipHdr."Transport Method";
                EInvoiceEntryL."Shipping Agent Code" := TransShipHdr."Shipping Agent Code";
                TransShipHdr."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                TransShipHdr."Vehicle Type" := TransShipHdr."Vehicle Type"::Regular;
                TransShipHdr.Modify();
                Message(EWayGenerated, TransShipHdr."No.");
            end else begin
                CreateLogEntry(TransShipHdr."No.", DocType::Transfer, TransShipHdr."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;
                EInvoiceEntryL."E-Way Generated" := false;
                EInvoiceEntryL."E-Way Canceled" := false;
                Message(EWayFailed, TransShipHdr."No.");
            end;
            EInvoiceEntryL.Modify();
        end else
            Error(ResponseText);
    end;

    local procedure UpdateVehicleNoTransferShipment(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        TransShipHdr: Record "Transfer Shipment Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TransportMethodL: Record "Transport Method";
        StateL: Record State;
        ShippingAgentL: Record "Shipping Agent";
        ResponseText: Text;
        RequestText: Text;
    begin
        TransShipHdr.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(TransShipHdr."Transfer-from Code");
        EInvoiceSetupL.Get;

        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", 3);
        EInvoiceEntryL.SetRange("Document No.", TransShipHdr."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("New Vehicle No.");
        EInvoiceEntryL.TestField("Vehicle No. Update Remark");
        TransportMethodL.Get(TransShipHdr."Transport Method");
        JObject.Add('EwbNumber', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('VehNo', DELCHR(EInvoiceEntryL."New Vehicle No.", '=', ' /\.<>-!@#$%^&*()_+'));
        JObject.Add('VehicleType', 'REGULAR');
        JObject.Add('FromPlace', LocationL.City);
        if StateL.Get(LocationL."State Code") then
            JObject.Add('FromState', StateL.Code);
        if EInvoiceEntryL."New Pin Code From" <> '' then
            JObject.Add('FromPincode', EInvoiceEntryL."New Pin Code From");

        if EInvoiceEntryL."Vehicle No. Update Remark" IN
          [EInvoiceEntryL."Vehicle No. Update Remark"::NATURAL_CALAMITY, EInvoiceEntryL."Vehicle No. Update Remark"::ACCIDENT] then
            JObject.Add('ReasonCode', 'OTHERS')
        else
            JObject.Add('ReasonCode', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        JObject.Add('ReasonRemark', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        ShippingAgentL.Get(TransShipHdr."Shipping Agent Code");
        if ShippingAgentL."GST Registration No." > '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");
        JObject.Add('TransName', ShippingAgentL.Name);
        JObject.Add('TransDocNo', EInvoiceEntryL."LR/RR No.");
        JObject.Add('TransDocDt', Format(EInvoiceEntryL."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.Add('TransMode', Format(TransportMethodL."Transportation Mode"));
        JObject.Add('DocumentNumber', EInvoiceEntryL."Document No.");
        JObject.Add('DocumentType', 'INV');
        JObject.Add('DocumentDate', Format(EInvoiceEntryL."Document Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.WriteTo(RequestText);

        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Update", LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", false);

        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') and GetValueFromJsonObject(JObject, 'errors').IsNull then begin
                TransShipHdr."Vehicle No." := EInvoiceEntryL."New Vehicle No.";
                TransShipHdr."Vehicle Type" := TransShipHdr."Vehicle Type"::Regular;
                TransShipHdr."Transport Method" := EInvoiceEntryL."Transport Method";
                TransShipHdr."Shipping Agent Code" := EInvoiceEntryL."Shipping Agent Code";
                TransShipHdr."LR/RR Date" := EInvoiceEntryL."LR/RR Date";
                TransShipHdr."LR/RR No." := EInvoiceEntryL."LR/RR No.";
                TransShipHdr.Modify();
                Message(VehicleUpdated, TransShipHdr."No.");
            end else
                Error(ResponseText);
    end;

    local procedure CancelEWayTransferShipment(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        TransShipmentHdr: Record "Transfer Shipment Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin
        TransShipmentHdr.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(TransShipmentHdr."Transfer-from Code");
        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", 3);
        EInvoiceEntryL.SetRange("Document No.", TransShipmentHdr."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("Reason of Cancel");
        JObject.Add('ewbNo', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('cancelRsnCode', Format(EInvoiceEntryL."Reason of Cancel"));
        JObject.Add('cancelRmrk', 'Cancelled the order');
        JObject.WriteTo(RequestText);
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Cancelation", LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'ewbStatus').AsText() = 'CANCELLED') and GetValueFromJsonObject(JObject, 'errors').IsNull then begin
                Clear(EInvoiceEntryL."E-Way Bill No.");
                Clear(EInvoiceEntryL."E-Way Bill Date");
                Clear(EInvoiceEntryL."E-Way Bill Validity");
                Clear(EInvoiceEntryL."E-Way Generated");
                Clear(EInvoiceEntryL."New Vehicle No.");
                EInvoiceEntryL."E-Way Canceled" := true;
                EInvoiceEntryL."Vehicle No. Update Remark" := EInvoiceEntryL."Vehicle No. Update Remark"::" ";
                EInvoiceEntryL."E-Way Canceled Date" := Format(CURRENTDATETIME);
                EInvoiceEntryL.Modify();
                Message(EWayCancelled, TransShipmentHdr."No.");
            end else
                Error(ResponseText);
    end;

    procedure GetEWayTransferShipmentforPrint(TransShipHeader: Record "Transfer Shipment Header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin
        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", 2);
        EInvoiceEntryL.SetRange("Document No.", TransShipHeader."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(TransShipHeader."Transfer-from Code");
            JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            JObject.Add('ewb_numbers', JArray);
            JObject.Add('print_type', 'DETAILED');
            JObject.WriteTo(RequestText);
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL", LocationL."ClearTAX Owner ID", LocationL."GST Registration No.", true);
        end;
    end;

    local procedure GetTaxableAmountTransfer(DocNo: Code[20]): Decimal
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        TransferShipmentLine.SetRange("Document No.", DocNo);
        TransferShipmentLine.SetFilter(Quantity, '<>%1', 0);
        //TransferShipmentLine.CalcSums("GST Base Amount");
        //if TransferShipmentLine."GST Base Amount" <> 0 then
        //EXIT(TransferShipmentLine."GST Base Amount");

        TransferShipmentLine.CalcSums(Amount);
        EXIT(TransferShipmentLine.Amount);
    end;

    local procedure SendRequest(Method: Text; RequestText: Text; var ResponseText: Text; URL: Text; OwnerID: Text; GSTNo: Text; ForPDF: Boolean)
    var
        HttpSendMessage: Codeunit "e-Invoice Http Send Message";
        TempBlob: Codeunit "Temp Blob";
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        ErrorText: Text;
        InstreamL: InStream;
        FileManagementL: Codeunit "File Management";
        ServerFileName: Text;
        FileL: File;
        OutStreamL: OutStream;
        PayLoadText: Text;
    begin
        EInvoiceSetupL.Get();
        HttpSendMessage.SetMethod(Method);
        HttpSendMessage.SetHttpHeader('X-Cleartax-Auth-Token', EInvoiceSetupL."Auth Token");
        HttpSendMessage.SetContentType('application/json');
        if NOT ForPDF then
            HttpSendMessage.SetReturnType('application/json');

        if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
            HttpSendMessage.SetHttpHeader('gstin', '29AAFCD5862R000');
            HttpSendMessage.SetHttpHeader('owner_id', OwnerID);
        end else begin
            HttpSendMessage.SetHttpHeader('gstin', GSTNo);
            HttpSendMessage.SetHttpHeader('owner_id', OwnerID);
        end;
        HttpSendMessage.SetHttpHeader('x-cleartax-product', 'Einvoice');
        if EInvoiceSetupL."Show Payload" then
            Message(RequestText);
        Clear(TempBlob);
        TempBlob.CreateInStream(InstreamL);
        if (RequestText > '') or ForPDF then
            InstreamL := HttpSendMessage.SendRequest(EInvoiceSetupL."Base URL" + URL, RequestText, true, InstreamL);

        if not HttpSendMessage.IsSuccess() then
            Error(ErrorText);

        if ForPDF then begin
            ServerFileName := FileManagementL.ServerTempFileName('.pdf');
            FileL.Create(ServerFileName);
            FileL.CreateOutStream(OutStreamL);
            CopyStream(OutStreamL, InstreamL);
            FileL.Close();
            Hyperlink(FileManagementL.DownloadTempFile(ServerFileName));
        end else begin
            InstreamL.ReadText(ResponseText);
            if EInvoiceSetupL."Show Payload" then
                Message(ResponseText);
        end;
    end;

    local procedure CreateLogEntry(DocNo: Text; DocType: Option " ",Sales,Purchase,Transfer; DocDate: Date; RequestText: Text; ResponseText: Text; EWayBillNo: Text; EWayBillDT: Text; EWayBillExpirationDT: Text; StatusText: Text; var EInvoiceLogEntry: Record "ClearComp e-Invoice Entry")
    var
        OutstreamL: OutStream;
        TextVar: Text;
    begin
        EInvoiceLogEntry.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceLogEntry.SetRange("Document Type", DocType);
        EInvoiceLogEntry.SetRange("Document No.", DocNo);
        EInvoiceLogEntry.SetRange("API Type", EInvoiceLogEntry."API Type"::"E-way");
        if NOT EInvoiceLogEntry.FindFirst() then begin
            EInvoiceLogEntry.RESET;
            EInvoiceLogEntry."Document Type" := DocType;
            EInvoiceLogEntry."Document No." := DocNo;
            EInvoiceLogEntry."Document Date" := DocDate;
            EInvoiceLogEntry."API Type" := EInvoiceLogEntry."API Type"::"E-way";
        end;
        EInvoiceLogEntry."Request JSON".CREATEOUTSTREAM(OutstreamL);
        OutstreamL.WRITETEXT(RequestText);
        EInvoiceLogEntry."Response JSON".CREATEOUTSTREAM(OutstreamL);
        JObject.WriteTo(TextVar);
        OutstreamL.WRITETEXT(TextVar);
        EInvoiceLogEntry."User Id" := USERID;
        EInvoiceLogEntry."Status Text" := StatusText;
        EInvoiceLogEntry."E-Way Bill No." := EWayBillNo;
        EInvoiceLogEntry."E-Way Bill Date" := EWayBillDT;
        EInvoiceLogEntry."E-Way Bill Validity" := EWayBillExpirationDT;
        if NOT EInvoiceLogEntry.INSERT then
            EInvoiceLogEntry.Modify();
    end;

    local procedure CheckEwayBillStatus(DocNoP: Text; DocTypeP: Option)
    var
        EInvoiceLogEntryL: Record "ClearComp e-Invoice Entry";
    begin
        EInvoiceLogEntryL.SetCurrentKey("API Type", "Document No.", "Document Type", "E-Way Generated");
        EInvoiceLogEntryL.SetRange("Document Type", DocTypeP);
        EInvoiceLogEntryL.SetRange("Document No.", DocNoP);
        EInvoiceLogEntryL.SetRange("E-Way Generated", true);
        if EInvoiceLogEntryL.FindFirst() then
            Error(EWayGeneratedErr, DocNoP);
    end;

    local procedure GetUOM(UOMCode: Code[10]): Text
    var
        UnitofMeasure: Record "Unit of Measure";
    begin
        //if ((UnitofMeasure.Get(UOMCode)) and (UnitofMeasure."GST Reporting UQC" > '')) then
        //EXIT(UnitofMeasure."GST Reporting UQC")
        //else
        EXIT('OTH');
    end;

    local procedure GetGSTAmount(DocNo: Code[20]; CompCode: Code[10]): Decimal
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        GSTAmt: Decimal;
    begin
        DetailedGSTLedgerEntry.SetCurrentKey("Document No.", "Document Line No.", "GST Component Code");
        DetailedGSTLedgerEntry.SetRange("Document No.", DocNo);
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CompCode);
        DetailedGSTLedgerEntry.CalcSums("GST Amount");
        EXIT(ABS(DetailedGSTLedgerEntry."GST Amount"));
    end;

    local procedure GetGSTRate(DocNo: Code[20]; CompCode: Code[10]; LineNo: Integer): Decimal
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntry.SetCurrentKey("Document No.", "Document Line No.", "GST Component Code");
        DetailedGSTLedgerEntry.SetRange("Document No.", DocNo);
        DetailedGSTLedgerEntry.SetRange("Document Line No.", LineNo);
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CompCode);
        if DetailedGSTLedgerEntry.FindFirst() then
            EXIT(Round(DetailedGSTLedgerEntry."GST %", 0.01));
        EXIT(0);
    end;

    procedure UpdateVehicleNo(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    begin
        if EInvoiceEntryP."Document Type" = EInvoiceEntryP."Document Type"::Invoice then
            UpdateVehicleNoSalesInvoice(EInvoiceEntryP)
        else
            if EInvoiceEntryP."Document Type" = EInvoiceEntryP."Document Type"::CrMemo then
                UpdateVehicleNoPurchaseCrMemo(EInvoiceEntryP)
            else
                if EInvoiceEntryP."Document Type" = EInvoiceEntryP."Document Type"::TransferShpt then
                    UpdateVehicleNoTransferShipment(EInvoiceEntryP);
    end;

    procedure CancelEWay(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    begin
        if EInvoiceEntryP."Document Type" = EInvoiceEntryP."Document Type"::Invoice then
            CancelEWaySalesInvoice(EInvoiceEntryP)
        else
            if EInvoiceEntryP."Document Type" = EInvoiceEntryP."Document Type"::CrMemo then
                CancelEWayPurchaseCrMemo(EInvoiceEntryP)
            else
                if EInvoiceEntryP."Document Type" = EInvoiceEntryP."Document Type"::TransferShpt then
                    CancelEWayTransferShipment(EInvoiceEntryP);
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

