codeunit 60033 "ClearComp E-Way Management"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm,
                  TableData "Transfer Shipment Header" = rm,
                  TableData "purch. inv. Header" = rm,
                  tabledata "Sales Shipment Header" = rm,
                  tabledata "Service Shipment HEader" = rm,
                  tabledata "Service invoice header" = rm;

    trigger OnRun()
    begin
    end;

    var

        HSNSACCode: code[20];
        //    item: record item;
        fixAsset: Record "Fixed Asset";

        EntryExit: Record "Entry/Exit Point";
        GSTRegistrationo: Record "GST Registration Nos.";
        DistanceKM: Decimal;

        JSubObjectL: JsonObject;
        JSubArray: JsonArray;
        JToken1L: JsonToken;
        JTokenL: JsonToken;
        ErrorDetails: text;
        j: Integer;
        JObjectL: JsonObject;
        docNo: code[20];
        EInvoiceSetup: Record "ClearComp e-Invocie Setup";
        JObject: JsonObject;
        JArray: JsonArray;
        EWayGeneratedErr: Label 'E-Way Bill already generated for document no. %1';
        DocType: Option " ",Invoice,CrMemo,TransferShpt,"Service Invoice","Service Credit Memo","Purch Cr. Memo Hdr","Sales Shipment","Service Shipment","Purch. Inv. Hdr";
        EWayGenerated: Label 'E-Way Bill Generated successfully for document no. %1.';
        EWayFailed: Label 'E-Way Bill Generation failed for document no. %1.';
        VehicleUpdated: Label 'Vehicle No. / Part B Updated Successfully for document no. %1.';

        MultiVehicleUpdated: Label ' Multi Vehicle No. Updated Successfully for document no. %1.';
        EWayCancelled: Label 'E-Way Bill Cancelled for document no. %1.';

    procedure DeleteMultivehicleData(EinvoiceEntry: Record "ClearComp e-Invoice Entry")
    var
        MultivehicleEway: record "CT- E-way Multi Vehicle";
    begin
        MultivehicleEway.setrange("API Type", MultivehicleEway."API Type"::"E-Way");
        MultivehicleEway.setrange("E-way Bill No.", EinvoiceEntry."E-way Bill No.");
        if MultivehicleEway.findset then
            MultivehicleEway.deleteall;

    end;

    procedure CreateJsonServiceShipment(SalesShipmentHeaderP: Record "Service Shipment Header")
    var
        TransactionTypeL: text;
        SalesShipmentHeader: Record "Service Shipment Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        ShippingAgentL: Record "Shipping Agent";
        TransportMethodL: Record "Shipment Method";
        CompanyInformationL: Record "Company Information";
        CustomerL: Record Customer;
        PostCodeL: Record "Post Code";
        StateL: Record State;
        "Entry/ExitPointL": Record "Entry/Exit Point";
        SalesShipmentLineL: Record "Service Shipment Line";
        ShipToAddressL: Record "Ship-to Address";
        ItemCategoryL: Record "Item Category";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TCSEntry: Record "TCS Entry";
        JSubObject: JsonObject;
        JArrayL: JsonArray;
        JToken1L: JsonToken;
        JToken1: JsonToken;
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
        DistanceRemark: text;
        Jarrtext: text;
        i: Integer;
        //   EInvoicemgmt: Codeunit "e-Invoice Management";
        GSTRate: record "Tax Rate";
        Ewaycard: page "CT Eway Card";

    begin

        SalesShipmentHeader.Copy(SalesShipmentHeaderP);
        LocationL.Get(SalesShipmentHeader."Location Code");
        EInvoiceSetupL.Get;
        CheckEwayBillStatus(SalesShipmentHeader."No.", DocType::"Service Shipment");
        CreateLogEntry(SalesShipmentHeader."No.", DocType::"Service Shipment", SalesShipmentHeader."Posting Date", RequestText, ResponseText,
                                 EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);

        ewaycard.SetTableView(EInvoiceEntryL);
        commit;
        ewaycard.LookupMode := true;
        if ewaycard.RunModal = Action::LookupOK then begin
            EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
            EInvoiceEntryL.SetRange("Document Type", DocType::"Service Shipment");
            EInvoiceEntryL.SetRange("Document No.", SalesShipmentHeader."No.");
            EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
            EInvoiceEntryL.FindFirst();

            LocationL.TestField("Post Code");
            CompanyInformationL.Get();
            JObject.Add('DocumentNumber', SalesShipmentHeader."No.");
            JObject.Add('DocumentType', format(EInvoiceEntryL."e-way Document Type"));
            JObject.Add('DocumentDate', Format(SalesShipmentHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));
            JObject.Add('SupplyType', format(EInvoiceEntryL.SupplyType));
            JObject.Add('SubSupplyType', Format(EInvoiceEntryL."supply sub type"));
            JObject.Add('SubSupplyTypeDesc', Format(EInvoiceEntryL."Sub Supply Type Desc"));
            JObject.Add('TransactionType', format(EInvoiceEntryL."Eway Bill Transaction Type"));
            CustomerL.get(SalesShipmentHeader."Customer No.");
            if CustomerL."GST Registration No." <> '' then
                JSubObject.Add('Gstin', CustomerL."GST Registration No.")
            else
                JSubObject.Add('Gstin', 'URP');
            JSubObject.Add('LglNm', SalesShipmentHeader."Bill-to Name");
            JSubObject.Add('TrdNm', SalesShipmentHeader."Bill-to Name 2");
            JSubObject.Add('Addr1', SalesShipmentHeader."Bill-to Address");
            JSubObject.Add('Addr2', SalesShipmentHeader."Bill-to Address 2");
            JSubObject.Add('Loc', SalesShipmentHeader."Bill-to City");
            if SalesShipmentHeader."GST Customer Type" = SalesShipmentHeader."GST Customer Type"::Export then begin

                JSubObject.Add('Stcd', '96');
                JSubObject.Add('Pin', '999999');
            end else begin



                if StateL.Get(SalesShipmentHeader."GST Bill-to State Code") then begin
                    JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                    JSubObject.Add('Pin', copystr(SalesShipmentHeader."Ship-to Post Code", 1, 6)); // added additionaly due to missing data.
                end else
                    Error('State Code is missing in sales Invoice Header')
            end;


            JObject.Add('BuyerDtls', JSubObject);
            Clear(JSubObject);
            if (SalesShipmentHeader."Ship-to Code" <> '') and (SalesShipmentHeader."GST Customer Type" = SalesShipmentHeader."GST Customer Type"::Export) then begin
                JSubObject.Add('LglNm', SalesShipmentHeader."Ship-to Name");
                JSubObject.Add('TrdNm', SalesShipmentHeader."Ship-to Name 2");
                JSubObject.Add('Addr1', SalesShipmentHeader."Ship-to Address");
                JSubObject.Add('Addr2', SalesShipmentHeader."Ship-to Address 2");
                JSubObject.Add('Loc', SalesShipmentHeader."Ship-to City");
                if SalesShipmentHeader."Ship-to Code" = '' then begin
                    if SalesShipmentHeader."GST Customer Type" = SalesShipmentHeader."GST Customer Type"::Export then begin
                        "Entry/ExitPointL".Get(SalesShipmentHeader."Exit Point");
                        "Entry/ExitPointL".testfield("State Code");
                        StateL.Get("Entry/ExitPointL"."State Code");
                        if StateL.Get("Entry/ExitPointL"."State Code") then begin
                            JSubObject.Add('Stcd', Format(StateL."State Code (GST Reg. No.)"));
                            JSubObject.Add('Pin', Format("Entry/ExitPointL"."Post Code"));
                        end else begin


                            JSubObject.Add('Stcd', '96');
                            JSubObject.Add('Pin', '999999');
                        end;
                    end else begin
                        if StateL.Get(ShipToAddressL.state) then
                            JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                        JSubObject.Add('Pin', ShipToAddressL."post code");


                    end;
                    JObject.Add('ExpShipDtls', JSubObject);

                end;
                Clear(JSubObject);
                // if (SalesShipmentHeader."Dispatch-to Code" <> '') and (SalesShipmentHeader."GST Customer Type" <> SalesShipmentHeader."GST Customer Type"::Export) then begin
                //     JSubObject.Add('LglNm', SalesShipmentHeader."Dispatch-to Name");
                //     JSubObject.Add('TrdNm', SalesShipmentHeader."Dispatch-to Name 2");
                //     JSubObject.Add('Addr1', SalesShipmentHeader."Dispatch-to Address");
                //     JSubObject.Add('Addr2', SalesShipmentHeader."Dispatch-to Address 2");
                //     JSubObject.Add('Loc', SalesShipmentHeader."Dispatch-to City");
                //     if StateL.Get(SalesShipmentHeader."Dispatch-to State") then
                //         JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                //     JSubObject.Add('Pin', SalesShipmentHeader."Dispatch-to Post Code");


                //     JObject.Add('DispDtls', JSubObject);

                // end;

                Clear(JSubObject);
                JSubObject.Add('LglNm', LocationL.Name);
                JSubObject.Add('TrdNm', LocationL."Name 2");
                JSubObject.Add('Addr1', LocationL.Address);
                JSubObject.Add('Addr2', LocationL."Address 2");
                JSubObject.Add('Loc', LocationL.City);
                if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                    GSTRegistrationo.get(LocationL."GST Registration No.");
                    JSubObject.Add('Gstin', GSTRegistrationo."Einv Demo GST REgistration No.");

                end else begin
                    if LocationL."GST Registration No." <> '' then
                        JSubObject.Add('Gstin', LocationL."GST Registration No.")
                    else
                        JSubObject.Add('Gstin', CompanyInformationL."GST Registration No.");

                end;
                JSubObject.Add('Pin', Format(CopyStr(LocationL."Post Code", 1, 6)));
                if StateL.Get(LocationL."State Code") then;
                JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                JObject.Add('SellerDtls', JSubObject);
                Clear(JSubObject);
                if SalesShipmentHeader."Currency Factor" <> 0 then
                    LCYCurrency := 1 / SalesShipmentHeader."Currency Factor"
                else
                    LCYCurrency := 1;
                JObject.Add('TotalInvoiceAmount', Round((GetTaxableAmountServiceShip(SalesShipmentHeader."No.") +
                    TCSEntry."Total TCS Including SHE CESS" + GetGSTAmountServiceShipment(SalesShipmentHeader."No.", 'CGST') + GetGSTAmountServiceShipment(SalesShipmentHeader."No.", 'SGST') +
                    GetGSTAmountServiceShipment(SalesShipmentHeader."No.", 'IGST') + GetGSTAmountServiceShipment(SalesShipmentHeader."No.", 'CESS')) * LCYCurrency, 0.01, '='));
                JObject.Add('TotalAssessableAmount', Round(GetTaxableAmountServiceShip(SalesShipmentHeader."No.") * LCYCurrency, 0.01, '='));
                JObject.Add('TotalCgstAmount', GetGSTAmountServiceShipment(SalesShipmentHeader."No.", 'CGST'));
                JObject.Add('TotalSgstAmount', GetGSTAmountServiceShipment(SalesShipmentHeader."No.", 'SGST'));
                JObject.Add('TotalIgstAmount', GetGSTAmountServiceShipment(SalesShipmentHeader."No.", 'IGST'));
                JObject.Add('TotalCessAmount', GetGSTAmountServiceShipment(SalesShipmentHeader."No.", 'CESS'));
                ShippingAgentL.Get(SalesShipmentHeader."Shipping Agent Code");
                if ShippingAgentL."GST Registration No." > '' then
                    JObject.Add('TransId', ShippingAgentL."GST Registration No.");
                JObject.Add('TransName', ShippingAgentL.Name);
                JObject.Add('Distance', 0);
                if SalesShipmentHeader."LR/RR No." <> '' then begin
                    TransportMethodL.Get(SalesShipmentHeader."Shipment Method code");
                    SalesShipmentHeader.TestField("Shipment Method code");
                    // SalesInvHeader.TestField("Mode of Transport");
                    SalesShipmentHeader.TestField("Vehicle No.");
                    SalesShipmentHeader.TestField("LR/RR No.");
                    SalesShipmentHeader.TestField("LR/RR Date");
                    JObject.Add('VehNo', DelChr(SalesShipmentHeader."Vehicle No.", '=', ' ,/-<>  !@#$%^&*()_+{}'));
                    JObject.Add('TransMode', Format(TransportMethodL.code));
                end;
                JObject.Add('VehType', 'REGULAR');

                if SalesShipmentHeader."LR/RR No." <> '' then
                    JObject.Add('TransDocNo', Format(SalesShipmentHeader."LR/RR No."));
                if SalesShipmentHeader."LR/RR Date" <> 0D then
                    JObject.Add('TransDocDt', Format(SalesShipmentHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));


                GetRoundingGLSales(CustomerL."Customer Posting Group", InvRoundingGL, PITRoungGL);
                SalesShipmentLineL.setrange("Document No.", SalesShipmentHeaderP."no.");
                SalesShipmentLineL.SetFilter("HSN/SAC Code", '<>%1', '');
                if SalesShipmentLineL.FindSet() then
                    repeat
                        JSubObject.Add('ProdName', SalesShipmentLineL.Description);
                        if SalesShipmentLineL.Type = SalesShipmentLineL.Type::Item then begin
                            JSubObject.Add('ProdDesc', Format(SalesShipmentLineL.Description));
                        end else
                            JSubObject.Add('ProdDesc', Format(SalesShipmentLineL.Description));
                        JSubObject.Add('HsnCd', Format(SalesShipmentLineL."HSN/SAC Code"));
                        JSubObject.Add('Qty', Format(SalesShipmentLineL.Quantity));
                        if SalesShipmentLineL."GST Group Type" = SalesShipmentLineL."GST Group Type"::Goods then
                            JSubObject.Add('Unit', GetUOM(SalesShipmentLineL."Unit of Measure Code"))
                        else
                            JSubObject.Add('Unit', 'OTH');
                        JSubObject.Add('CgstRt', GetGSTRateServiceShip(SalesShipmentHeader."No.", 'CGST', SalesShipmentLineL."Line No."));
                        JSubObject.Add('SgstRt', GetGSTRateServiceShip(SalesShipmentHeader."No.", 'SGST', SalesShipmentLineL."Line No."));
                        JSubObject.Add('IgstRt', GetGSTRateServiceShip(SalesShipmentHeader."No.", 'IGST', SalesShipmentLineL."Line No."));
                        JSubObject.Add('CesRt', GetGSTRateServiceShip(SalesShipmentHeader."No.", 'CESS', SalesShipmentLineL."Line No."));
                        JSubObject.Add('CesNonAdvAmt', 0);
                        JSubObject.Add('AssAmt', GetGSTRateServiceShipLineAmount(SalesShipmentHeader."No.", '', SalesShipmentLineL."Line No."));
                        JArrayL.Add(JSubObject);
                        clear(JSubObject);
                    until SalesShipmentLineL.Next() = 0;
                JObject.Add('ItemList', JArrayL);
                JObject.WriteTo(RequestText);
                docNo := SalesShipmentLineL."Document No.";
                SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Creation", '', LocationL."GST Registration No.", false);

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
                        DistanceRemark := GetValueFromJsonObject(JSubObject, 'Alert').AsText();



                        CreateLogEntry(SalesShipmentHeader."No.", DocType::"Service Shipment", SalesShipmentHeader."Posting Date", RequestText, ResponseText,
                            EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                        EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                        EInvoiceEntryL."E-Way Generated" := true;
                        EInvoiceEntryL."E-Way Canceled" := false;
                        EInvoiceEntryL."Distance Remark" := DistanceRemark;
                        if DistanceRemark > '' then
                            evaluate(EInvoiceEntryL."Transportation Distance", DelChr(DelChr(DistanceRemark, '=', ', Distance between these two pincodes is '), '=', ', '));

                        EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                        EInvoiceEntryL."LR/RR Date" := SalesShipmentHeader."LR/RR Date";
                        EInvoiceEntryL."LR/RR No." := SalesShipmentHeader."LR/RR No.";
                        EInvoiceEntryL."Transport Method" := SalesShipmentHeader."Shipment Method code";
                        EInvoiceEntryL."Shipping Agent Code" := SalesShipmentHeader."Shipping Agent Code";
                        // SalesShipmentHeader."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                        // SalesShipmentHeader."Vehicle Type" := SalesShipmentHeader."Vehicle Type"::Regular;
                        // if SalesShipmentHeader."Distance (Km)" = 0 then
                        //     SalesShipmentHeader."Distance (Km)" := EInvoiceEntryL."Transportation Distance";
                        // if SalesShipmentHeader."Distance (Km)" = 0 then begin
                        //     if DistanceKM > 0 then
                        //         SalesShipmentHeader."Distance (Km)" := DistanceKM;
                        // end;
                        SalesShipmentHeader.Modify();
                        Message(EWayGenerated, SalesShipmentHeader."No.");
                    end else begin
                        CreateLogEntry(SalesShipmentHeader."No.", DocType::"Service Shipment", SalesShipmentHeader."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                        EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;

                        EInvoiceEntryL."E-Way Generated" := false;
                        EInvoiceEntryL."E-Way Canceled" := false;
                        if JSubObject.Contains('ErrorDetails') then begin
                            JSubObject.Get('ErrorDetails', JToken1L);
                            JSubArray := JToken1L.AsArray();
                            ErrorDetails := format(JSubArray);
                            for j := 0 to JSubArray.Count - 1 do begin
                                JSubArray.Get(j, JTokenL);
                                if j = 0 then begin

                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                if j = 1 then begin
                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description 1" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                if j = 2 then begin
                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description 2" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                if j = 3 then begin
                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description 3" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                EInvoiceEntryL.Modify();
                            end;
                        end;
                        Message(StrSubstNo(EWayFailed, SalesShipmentHeader."No.") + '  Error As follow : ' + EInvoiceEntryL."Error Description" + ' ' + EInvoiceEntryL."Error Description 2");
                    end;
                    EInvoiceEntryL.Modify();
                end else
                    Error(ResponseText);
            end;


        end;
    end;

    procedure CreateJsonSalesShipment(SalesShipmentHeaderP: Record "Sales Shipment Header")
    var
        shipToAddress: Record "Ship-to Address";
        TransactionTypeL: text;
        SalesShipmentHeader: Record "Sales Shipment Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        ShippingAgentL: Record "Shipping Agent";
        TransportMethodL: Record "Shipment Method";
        CompanyInformationL: Record "Company Information";
        CustomerL: Record Customer;
        PostCodeL: Record "Post Code";
        StateL: Record State;
        "Entry/ExitPointL": Record "Entry/Exit Point";
        SalesShipmentLineL: Record "Sales Shipment Line";
        ShipToAddressL: Record "Ship-to Address";
        ItemCategoryL: Record "Item Category";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TCSEntry: Record "TCS Entry";
        JSubObject: JsonObject;
        JArrayL: JsonArray;
        JToken1L: JsonToken;
        JToken1: JsonToken;
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
        DistanceRemark: text;
        Jarrtext: text;
        i: Integer;
        EInvoicemgmt: Codeunit "e-Invoice Management";
        GSTRate: record "Tax Rate";
        Ewaycard: page "CT Eway Card";

    begin


        SalesShipmentHeader.Copy(SalesShipmentHeaderP);
        LocationL.Get(SalesShipmentHeader."Location Code");
        EInvoiceSetupL.Get;

        CheckEwayBillStatus(SalesShipmentHeader."No.", DocType::"Sales Shipment");
        CreateLogEntry(SalesShipmentHeader."No.", DocType::"Sales Shipment", SalesShipmentHeader."Posting Date", RequestText, ResponseText,
                                 EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);


        ewaycard.SetTableView(EInvoiceEntryL);
        commit;
        ewaycard.LookupMode := true;
        if ewaycard.RunModal = Action::LookupOK then begin
            EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
            EInvoiceEntryL.SetRange("Document Type", DocType::"Sales Shipment");
            EInvoiceEntryL.SetRange("Document No.", SalesShipmentHeader."No.");
            EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
            EInvoiceEntryL.FindFirst();
            LocationL.TestField("Post Code");
            CompanyInformationL.Get();
            JObject.Add('DocumentNumber', SalesShipmentHeader."No.");
            JObject.Add('DocumentType', format(EInvoiceEntryL."e-way Document Type"));
            JObject.Add('DocumentDate', Format(SalesShipmentHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));
            JObject.Add('SupplyType', format(EInvoiceEntryL.SupplyType));
            JObject.Add('SubSupplyType', Format(EInvoiceEntryL."supply sub type"));
            JObject.Add('SubSupplyTypeDesc', Format(EInvoiceEntryL."Sub Supply Type Desc"));
            JObject.Add('TransactionType', format(EInvoiceEntryL."Eway Bill Transaction Type"));
            if CustomerL.get(SalesShipmentHeader."Ship-to Customer") then;
            if CustomerL."GST Registration No." <> '' then
                JSubObject.Add('Gstin', CustomerL."GST Registration No.")
            else
                JSubObject.Add('Gstin', 'URP');
            JSubObject.Add('LglNm', SalesShipmentHeader."Ship-to Name");
            JSubObject.Add('TrdNm', SalesShipmentHeader."Ship-to Name 2");
            JSubObject.Add('Addr1', SalesShipmentHeader."Ship-to Address");
            JSubObject.Add('Addr2', SalesShipmentHeader."Ship-to Address 2");
            JSubObject.Add('Loc', SalesShipmentHeader."Ship-to City");
            if SalesShipmentHeader."GST Customer Type" = SalesShipmentHeader."GST Customer Type"::Export then begin

                JSubObject.Add('Stcd', '96');
                JSubObject.Add('Pin', '999999');
            end else begin
                if StateL.Get(SalesShipmentHeader.state) then begin
                    JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                    JSubObject.Add('Pin', copystr(SalesShipmentHeader."Ship-to Post Code", 1, 6)); // added additionaly due to missing data.
                end else
                    Error('State Code is missing in sales Shipment Header')
            end;
            JObject.Add('BuyerDtls', JSubObject);
            Clear(JSubObject);
            // if (SalesShipmentHeader."Ship-To Address Code" <> '') then begin
            //     ShipToAddressL.get(SalesShipmentHeader."Ship-To Address Code", SalesShipmentHeader."Ship-To Address Name");
            //     JSubObject.Add('LglNm', ShipToAddressL.Name);
            //     JSubObject.Add('TrdNm', ShipToAddressL."Name 2");
            //     JSubObject.Add('Addr1', ShipToAddressL.address);
            //     JSubObject.Add('Addr2', ShipToAddressL."address 2");
            //     JSubObject.Add('Loc', ShipToAddressL."City");

            //     if SalesShipmentHeader."GST Customer Type" = SalesShipmentHeader."GST Customer Type"::Export then begin

            //         "Entry/ExitPointL".Get(SalesShipmentHeader."Exit Point");
            //         "Entry/ExitPointL".testfield("State Code");
            //         StateL.Get("Entry/ExitPointL"."State Code");
            //         if StateL.Get("Entry/ExitPointL"."State Code") then begin
            //             JSubObject.Add('Stcd', Format(StateL."State Code (GST Reg. No.)"));
            //             JSubObject.Add('Pin', Format("Entry/ExitPointL"."Post Code"));
            //         end else begin


            //             JSubObject.Add('Stcd', '96');
            //             JSubObject.Add('Pin', '999999');
            //         end;
            //     end else begin
            //         if StateL.Get(ShipToAddressL.state) then
            //             JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
            //         JSubObject.Add('Pin', ShipToAddressL."post code");


            //     end;
            //     JObject.Add('ExpShipDtls', JSubObject);

            // end;

            clear(JSubObject);
            // if (SalesShipmentHeader."Dispatch-from Code" <> '') then begin
            //     JSubObject.Add('LglNm', SalesShipmentHeader."Dispatch-from Name");
            //     JSubObject.Add('TrdNm', SalesShipmentHeader."Dispatch-from Name 2");
            //     JSubObject.Add('Addr1', SalesShipmentHeader."Dispatch-from Address");
            //     JSubObject.Add('Addr2', SalesShipmentHeader."Dispatch-from Address 2");
            //     JSubObject.Add('Loc', SalesShipmentHeader."Dispatch-from City");
            //     if StateL.Get(SalesShipmentHeader."Dispatch-from State") then
            //         JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
            //     JSubObject.Add('Pin', SalesShipmentHeader."Dispatch-from Post Code");


            //     JObject.Add('DispDtls', JSubObject);

            // end;

            Clear(JSubObject);
            JSubObject.Add('LglNm', LocationL.Name);
            JSubObject.Add('TrdNm', LocationL."Name 2");
            JSubObject.Add('Addr1', LocationL.Address);
            JSubObject.Add('Addr2', LocationL."Address 2");
            JSubObject.Add('Loc', LocationL.City);
            if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                GSTRegistrationo.get(LocationL."GST Registration No.");
                JSubObject.Add('Gstin', GSTRegistrationo."Einv Demo GST REgistration No.");

            end else begin
                if LocationL."GST Registration No." <> '' then
                    JSubObject.Add('Gstin', LocationL."GST Registration No.")
                else
                    JSubObject.Add('Gstin', CompanyInformationL."GST Registration No.");

            end;
            JSubObject.Add('Pin', Format(CopyStr(LocationL."Post Code", 1, 6)));
            if StateL.Get(LocationL."State Code") then;
            JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
            JObject.Add('SellerDtls', JSubObject);
            Clear(JSubObject);
            if SalesShipmentHeader."Currency Factor" <> 0 then
                LCYCurrency := 1 / SalesShipmentHeader."Currency Factor"
            else
                LCYCurrency := 1;
            JObject.Add('TotalInvoiceAmount', Round((GetTaxableAmountSalesShip(SalesShipmentHeader."No.") +
                TCSEntry."Total TCS Including SHE CESS" + GetGSTAmountSalesShipment(SalesShipmentHeader."No.", 'CGST') + GetGSTAmountSalesShipment(SalesShipmentHeader."No.", 'SGST') +
                GetGSTAmountSalesShipment(SalesShipmentHeader."No.", 'IGST') + GetGSTAmountSalesShipment(SalesShipmentHeader."No.", 'CESS')) * LCYCurrency, 0.01, '='));
            JObject.Add('TotalAssessableAmount', Round(GetTaxableAmountSalesShip(SalesShipmentHeader."No.") * LCYCurrency, 0.01, '='));
            JObject.Add('TotalCgstAmount', GetGSTAmountSalesShipment(SalesShipmentHeader."No.", 'CGST'));
            JObject.Add('TotalSgstAmount', GetGSTAmountSalesShipment(SalesShipmentHeader."No.", 'SGST'));
            JObject.Add('TotalIgstAmount', GetGSTAmountSalesShipment(SalesShipmentHeader."No.", 'IGST'));
            JObject.Add('TotalCessAmount', GetGSTAmountSalesShipment(SalesShipmentHeader."No.", 'CESS'));
            ShippingAgentL.Get(SalesShipmentHeader."Shipping Agent Code");
            if ShippingAgentL."GST Registration No." > '' then
                JObject.Add('TransId', ShippingAgentL."GST Registration No.");
            JObject.Add('TransName', ShippingAgentL.Name);
            JObject.Add('Distance', 0);
            if SalesShipmentHeader."LR/RR No." <> '' then begin
                TransportMethodL.Get(SalesShipmentHeader."Shipment Method code");
                SalesShipmentHeader.TestField("Shipment Method code");
                // SalesInvHeader.TestField("Mode of Transport");
                SalesShipmentHeader.TestField("Vehicle No.");
                SalesShipmentHeader.TestField("LR/RR No.");
                SalesShipmentHeader.TestField("LR/RR Date");
                JObject.Add('VehNo', DelChr(SalesShipmentHeader."Vehicle No.", '=', ' ,/-<>  !@#$%^&*()_+{}'));
                JObject.Add('TransMode', Format(TransportMethodL.code));
            end;
            //JObject.Add('VehType', 'REGULAR');

            if SalesShipmentHeader."Vehicle Type" = SalesShipmentHeader."Vehicle Type"::Regular then
                JObject.Add('VehType', 'REGULAR')
            else
                if SalesShipmentHeader."Vehicle Type" = SalesShipmentHeader."Vehicle Type"::ODC then
                    JObject.Add('VehType', 'ODC')
                else
                    JObject.Add('VehType', 'REGULAR');

            if SalesShipmentHeader."LR/RR No." <> '' then
                JObject.Add('TransDocNo', Format(SalesShipmentHeader."LR/RR No."));
            if SalesShipmentHeader."LR/RR Date" <> 0D then
                JObject.Add('TransDocDt', Format(SalesShipmentHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));


            GetRoundingGLSales(CustomerL."Customer Posting Group", InvRoundingGL, PITRoungGL);
            SalesShipmentLineL.setrange("Document No.", SalesShipmentHeaderP."no.");
            SalesShipmentLineL.SetFilter("HSN/SAC Code", '<>%1', '');
            //       SalesInvoiceLineL.SetFilter("No.", '<>%1&<>%2', InvRoundingGL, PITRoungGL);
            //    SalesInvoiceLineL.SetFilter(Type, '<>%1', SalesInvoiceLineL.Type::"G/L Account"); // To be removed add it to skip gl rounding line as above filter not working due to data issue.
            if SalesShipmentLineL.FindSet() then
                repeat
                    JSubObject.Add('ProdName', SalesShipmentLineL.Description);
                    if SalesShipmentLineL.Type = SalesShipmentLineL.Type::Item then begin
                        // if ItemCategoryL.Get(SalesShipmentLineL."Item Category Code") and (ItemCategoryL.Description <> '') then
                        //     JSubObject.Add('ProdDesc', Format(ItemCategoryL.Description))
                        // else
                        JSubObject.Add('ProdDesc', Format(SalesShipmentLineL.Description));
                    end else
                        JSubObject.Add('ProdDesc', Format(SalesShipmentLineL.Description));
                    JSubObject.Add('HsnCd', Format(SalesShipmentLineL."HSN/SAC Code"));
                    JSubObject.Add('Qty', Format(SalesShipmentLineL.Quantity));
                    JSubObject.Add('Unit', GetUOM(SalesShipmentLineL."Unit of Measure Code"));
                    JSubObject.Add('CgstRt', GetGSTRateSalesShip(SalesShipmentHeader."No.", 'CGST', SalesShipmentLineL."Line No."));
                    JSubObject.Add('SgstRt', GetGSTRateSalesShip(SalesShipmentHeader."No.", 'SGST', SalesShipmentLineL."Line No."));
                    JSubObject.Add('IgstRt', GetGSTRateSalesShip(SalesShipmentHeader."No.", 'IGST', SalesShipmentLineL."Line No."));
                    JSubObject.Add('CesRt', GetGSTRateSalesShip(SalesShipmentHeader."No.", 'CESS', SalesShipmentLineL."Line No."));
                    JSubObject.Add('CesNonAdvAmt', 0);
                    JSubObject.Add('AssAmt', GetGSTRateSalesShipAmount(SalesShipmentHeader."No.", '', SalesShipmentLineL."Line No."));
                    JArrayL.Add(JSubObject);
                    clear(JSubObject);
                until SalesShipmentLineL.Next() = 0;
            JObject.Add('ItemList', JArrayL);
            JObject.WriteTo(RequestText);
            docNo := SalesShipmentLineL."Document No.";
            SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Creation", '', LocationL."GST Registration No.", false);

            if JObject.ReadFrom(ResponseText) then begin
                if JObject.Contains('ewb_status') and (GetValueFromJsonObject(JObject, 'ewb_status').AsText() > '') then
                    StatusText := GetValueFromJsonObject(JObject, 'ewb_status').AsText();
                if JObject.Contains('govt_response') then begin
                    JObject.Get('govt_response', JToken1L);
                    JSubObject := JToken1L.AsObject();
                end;
                if JSubObject.Contains('EwbNo') then begin
                    if JSubObject.Contains('EwbNo') then
                        EWayBillNo := GetValueFromJsonObject(JSubObject, 'EwbNo').AsText();
                    if JSubObject.Contains('EwbDt') then
                        EWayBillDateTime := GetValueFromJsonObject(JSubObject, 'EwbDt').AsText();
                    if JSubObject.Contains('EwbValidTill') then
                        EWayExpirationDT := GetValueFromJsonObject(JSubObject, 'EwbValidTill').AsText();
                    DistanceRemark := GetValueFromJsonObject(JSubObject, 'Alert').AsText();



                    CreateLogEntry(SalesShipmentHeader."No.", DocType::"Sales Shipment", SalesShipmentHeader."Posting Date", RequestText, ResponseText,
                        EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                    EInvoiceEntryL."E-Way Generated" := true;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    EInvoiceEntryL."Distance Remark" := DistanceRemark;
                    if DistanceRemark > '' then
                        evaluate(EInvoiceEntryL."Transportation Distance", DelChr(DelChr(DistanceRemark, '=', ', Distance between these two pincodes is '), '=', ', '));

                    EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                    EInvoiceEntryL."LR/RR Date" := SalesShipmentHeader."LR/RR Date";
                    EInvoiceEntryL."LR/RR No." := SalesShipmentHeader."LR/RR No.";
                    EInvoiceEntryL."Transport Method" := SalesShipmentHeader."Shipment Method code";
                    EInvoiceEntryL."Shipping Agent Code" := SalesShipmentHeader."Shipping Agent Code";
                    SalesShipmentHeader."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                    SalesShipmentHeader."Vehicle Type" := SalesShipmentHeader."Vehicle Type"::Regular;
                    if SalesShipmentHeader."Distance (Km)" = 0 then
                        SalesShipmentHeader."Distance (Km)" := EInvoiceEntryL."Transportation Distance";
                    if SalesShipmentHeader."Distance (Km)" = 0 then begin
                        if DistanceKM > 0 then
                            SalesShipmentHeader."Distance (Km)" := DistanceKM;
                    end;
                    SalesShipmentHeader.Modify();
                    Message(EWayGenerated, SalesShipmentHeader."No.");
                end else begin
                    CreateLogEntry(SalesShipmentHeader."No.", DocType::"sales shipment", SalesShipmentHeader."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;

                    EInvoiceEntryL."E-Way Generated" := false;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    //  Message(EWayFailed, SalesShipmentHeader."No.");
                    if JSubObject.Contains('ErrorDetails') then begin
                        JSubObject.Get('ErrorDetails', JToken1L);
                        JSubArray := JToken1L.AsArray();
                        ErrorDetails := format(JSubArray);

                        //
                        for j := 0 to JSubArray.Count - 1 do begin
                            JSubArray.Get(j, JTokenL);
                            if j = 0 then begin

                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 1 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 1" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 2 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 2" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 3 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 3" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            EInvoiceEntryL.Modify();
                        end;
                    end;
                    Message(StrSubstNo(EWayFailed, SalesShipmentHeader."No.") + '  Error As follow : ' + EInvoiceEntryL."Error Description" + ' ' + EInvoiceEntryL."Error Description 2");
                end;
                EInvoiceEntryL.Modify();
            end else
                Error(ResponseText);
        end;
    end;

    procedure CreateJsonServiceInvoice(ServiceInvoiceHeaderP: Record "Service Invoice Header")
    var
        ServiceInvHeader: Record "Service Invoice Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        ShippingAgentL: Record "Shipping Agent";
        TransportMethodL: Record "Shipment Method";
        CompanyInformationL: Record "Company Information";
        CustomerL: Record Customer;
        PostCodeL: Record "Post Code";
        StateL: Record State;
        "Entry/ExitPointL": Record "Entry/Exit Point";
        SalesInvoiceLineL: Record "Service Invoice Line";
        ShipToAddressL: Record "Ship-to Address";
        ItemCategoryL: Record "Item Category";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TCSEntry: Record "TCS Entry";
        JSubObject: JsonObject;
        JArrayL: JsonArray;
        JToken1L: JsonToken;
        JToken1: JsonToken;
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
        DistanceRemark: text;
        Jarrtext: text;
        i: Integer;
        TransactionTypeL: text;
        EInvoicemgmt: Codeunit "e-Invoice Management";
        ewaycard: page "ct eway card";
    begin
        if EInvoicemgmt.IsGSTApplicable(ServiceInvoiceHeaderP."No.", Database::"Service Invoice Header") then
            if ServiceInvoiceHeaderP."IRN Hash" = '' then
                Error('This document is applicable for e-invoice, Kindly generate e-invoice first and try create e-way Bill');


        if ServiceInvoiceHeaderP."IRN Hash" > '' then
            CreateJsonserviceInvoiceforIRN(ServiceInvoiceHeaderP)
        else begin
            EInvoiceSetupL.Get;
            CheckEwayBillStatus(ServiceInvoiceHeaderP."No.", DocType::"Service Invoice");
            CreateLogEntry(ServiceInvoiceHeaderP."No.", DocType::"Service Invoice", ServiceInvoiceHeaderP."Posting Date", RequestText, ResponseText,
                                     EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);

            ewaycard.SetTableView(EInvoiceEntryL);
            commit;
            ewaycard.LookupMode := true;
            if ewaycard.RunModal = Action::LookupOK then begin
                EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
                EInvoiceEntryL.SetRange("Document Type", DocType::"Service Shipment");
                EInvoiceEntryL.SetRange("Document No.", ServiceInvoiceHeaderP."No.");
                EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
                EInvoiceEntryL.FindFirst();

                ServiceInvHeader.Copy(ServiceInvoiceHeaderP);
                LocationL.Get(ServiceInvHeader."Location Code");
                EInvoiceSetupL.Get;
                ServiceInvHeader.TestField("Shipment Method code");
                // SalesInvHeader.TestField("Mode of Transport");
                ServiceInvHeader.TestField("Vehicle No.");
                ServiceInvHeader.TestField("LR/RR No.");
                ServiceInvHeader.TestField("LR/RR Date");
                TransportMethodL.Get(ServiceInvHeader."Shipment Method code");
                LocationL.TestField("Post Code");
                CompanyInformationL.Get();
                JObject.Add('DocumentNumber', ServiceInvHeader."No.");
                JObject.Add('DocumentType', format(EInvoiceEntryL."E-way Document Type"));
                JObject.Add('DocumentDate', Format(ServiceInvHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                JObject.Add('SupplyType', format(EInvoiceEntryL.SupplyType));
                JObject.Add('SubSupplyType', format(EInvoiceEntryL."Supply Sub Type"));
                JObject.Add('SubSupplyTypeDesc', format(EInvoiceEntryL."Sub Supply Type Desc"));



                JObject.Add('TransactionType', format(EInvoiceEntryL."Eway Bill Transaction Type"));
                if CustomerL."GST Registration No." <> '' then
                    JSubObject.Add('Gstin', CustomerL."GST Registration No.")
                else
                    JSubObject.Add('Gstin', 'URP');
                JSubObject.Add('LglNm', ServiceInvHeader."Ship-to Name");
                JSubObject.Add('TrdNm', ServiceInvHeader."Ship-to Name 2");
                JSubObject.Add('Addr1', ServiceInvHeader."Ship-to Address");
                JSubObject.Add('Addr2', ServiceInvHeader."Ship-to Address 2");
                JSubObject.Add('Loc', ServiceInvHeader."Ship-to City");
                if ServiceInvHeader."Ship-to Code" = '' then begin
                    if ServiceInvHeader."GST Customer Type" = ServiceInvHeader."GST Customer Type"::Export then begin
                        if "Entry/ExitPointL".Get(ServiceInvHeader."Exit Point") then begin
                            if StateL.Get("Entry/ExitPointL"."State Code") then;
                            JSubObject.Add('Stcd', Format(StateL."State Code (GST Reg. No.)"));
                            JSubObject.Add('Pin', Format("Entry/ExitPointL"."Post Code"));
                        end else begin
                            JSubObject.Add('Stcd', '96');
                            JSubObject.Add('Pin', '999999');
                        end;
                    end else begin

                        PostCodeL.SetRange(Code, ServiceInvHeader."Bill-to Post Code");
                        if PostCodeL.FindFirst() then;
                        if StateL.Get(ServiceInvHeader.State) then
                            JSubObject.Add('Stcd', Format(StateL."State Code (GST Reg. No.)"))
                        else
                            JSubObject.Add('Stcd', '');
                        JSubObject.Add('Pin', Format(copystr(PostCodeL.Code, 1, 6)));

                    end;
                end else begin
                    //    if ShipToAddressL.get(ServiceInvHeader."Ship-To Address Code", ServiceInvHeader."Ship-To Address Name") then begin
                    if ShipToAddressL.Get(ServiceInvHeader."Bill-to Customer No.", ServiceInvHeader."Ship-to Code") then begin
                        if ServiceInvHeader."GST Customer Type" = ServiceInvHeader."GST Customer Type"::Export then begin
                            JSubObject.Add('Stcd', '96');
                            JSubObject.Add('Pin', '999999');
                        end else begin
                            ShipToAddressL.TestField(State);
                            if StateL.Get(ShipToAddressL.State) then begin
                                JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                                JSubObject.Add('Pin', ShipToAddressL."Post Code"); // added additionaly due to missing data.
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
                    GSTRegistrationo.get(LocationL."GST Registration No.");
                    JSubObject.Add('Gstin', GSTRegistrationo."Einv Demo GST REgistration No.");

                end else begin
                    if LocationL."GST Registration No." <> '' then
                        JSubObject.Add('Gstin', LocationL."GST Registration No.")
                    else
                        JSubObject.Add('Gstin', CompanyInformationL."GST Registration No.");
                end;
                PostCodeL.SetRange(Code, LocationL."Post Code");
                if PostCodeL.FindFirst() then;
                JSubObject.Add('Pin', Format(copystr(PostCodeL.Code, 1, 6)));
                if StateL.Get(LocationL."State Code") then;
                JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");

                JObject.Add('SellerDtls', JSubObject);
                Clear(JSubObject);
                SalesInvoiceLineL.SetRange("Document No.", ServiceInvHeader."No.");
                SalesInvoiceLineL.SetFilter(Quantity, '<>%1', 0);
                //SalesInvoiceLineL.CalcSums("TDS/TCS Amount");
                TCSEntry.SetRange("Document No.", SalesInvoiceLineL."Document No.");
                if TCSEntry.FindFirst() then
                    ;
                //if SalesInvoiceLineL."TDS/TCS Amount" <> 0 then
                JObject.Add('OtherAmount', TCSEntry."Total TCS Including SHE CESS");
                if ServiceInvHeader."Currency Factor" <> 0 then
                    LCYCurrency := 1 / ServiceInvHeader."Currency Factor"
                else
                    LCYCurrency := 1;
                JObject.Add('TotalInvoiceAmount', Round((GetTaxableAmountSalesInvoice(ServiceInvHeader."No.") +
                    TCSEntry."Total TCS Including SHE CESS" + GetGSTAmount(ServiceInvHeader."No.", 'CGST') + GetGSTAmount(ServiceInvHeader."No.", 'SGST') +
                    GetGSTAmount(ServiceInvHeader."No.", 'IGST') + GetGSTAmount(ServiceInvHeader."No.", 'CESS')) * LCYCurrency, 0.01, '='));
                JObject.Add('TotalAssessableAmount', Round(GetTaxableAmountSalesInvoice(ServiceInvHeader."No.") * LCYCurrency, 0.01, '='));
                JObject.Add('TotalCgstAmount', GetGSTAmount(ServiceInvHeader."No.", 'CGST'));
                JObject.Add('TotalSgstAmount', GetGSTAmount(ServiceInvHeader."No.", 'SGST'));
                JObject.Add('TotalIgstAmount', GetGSTAmount(ServiceInvHeader."No.", 'IGST'));
                JObject.Add('TotalCessAmount', GetGSTAmount(ServiceInvHeader."No.", 'CESS'));
                ShippingAgentL.Get(ServiceInvHeader."Shipping Agent Code");
                JObject.Add('TransId', ShippingAgentL."GST Registration No.");
                JObject.Add('TransName', ShippingAgentL.Name);
                JObject.Add('Distance', 0);
                if ServiceInvHeader."LR/RR No." <> '' then begin
                    JObject.Add('VehNo', DelChr(ServiceInvHeader."Vehicle No.", '=', ' ,/-<>  !@#$%^&*()_+{}'));
                    JObject.Add('TransMode', Format(TransportMethodL.code));
                    //JObject.Add('VehType', 'REGULAR');
                end;
                if ServiceInvHeader."LR/RR No." <> '' then
                    JObject.Add('TransDocNo', Format(ServiceInvHeader."LR/RR No."));
                if ServiceInvHeader."LR/RR Date" <> 0D then
                    JObject.Add('TransDocDt', Format(ServiceInvHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));


                GetRoundingGLSales(CustomerL."Customer Posting Group", InvRoundingGL, PITRoungGL);
                SalesInvoiceLineL.SetFilter("HSN/SAC Code", '<>%1', '');
                //       SalesInvoiceLineL.SetFilter("No.", '<>%1&<>%2', InvRoundingGL, PITRoungGL);
                //    SalesInvoiceLineL.SetFilter(Type, '<>%1', SalesInvoiceLineL.Type::"G/L Account"); // To be removed add it to skip gl rounding line as above filter not working due to data issue.
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
                        JSubObject.Add('CgstRt', GetGSTRate(ServiceInvHeader."No.", 'CGST', SalesInvoiceLineL."Line No."));
                        JSubObject.Add('SgstRt', GetGSTRate(ServiceInvHeader."No.", 'SGST', SalesInvoiceLineL."Line No."));
                        JSubObject.Add('IgstRt', GetGSTRate(ServiceInvHeader."No.", 'IGST', SalesInvoiceLineL."Line No."));
                        JSubObject.Add('CesRt', GetGSTRate(ServiceInvHeader."No.", 'CESS', SalesInvoiceLineL."Line No."));
                        JSubObject.Add('CesNonAdvAmt', 0);
                        JSubObject.Add('AssAmt', Round((SalesInvoiceLineL."Line Amount" - SalesInvoiceLineL."Line Discount Amount") * LCYCurrency, 0.01, '='));
                        JArrayL.Add(JSubObject);
                        clear(JSubObject);
                    until SalesInvoiceLineL.Next() = 0;
                JObject.Add('ItemList', JArrayL);
                JObject.WriteTo(RequestText);
                docNo := SalesInvoiceLineL."Document No.";
                SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Creation", '', LocationL."GST Registration No.", false);

                if JObject.ReadFrom(ResponseText) then begin
                    if JObject.Contains('ewb_status') and (GetValueFromJsonObject(JObject, 'ewb_status').AsText() > '') then
                        StatusText := GetValueFromJsonObject(JObject, 'ewb_status').AsText();
                    if JObject.Contains('govt_response') then begin
                        JObject.Get('govt_response', JToken1L);
                        JSubObject := JToken1L.AsObject();
                    end;
                    if GetValueFromJsonObject(JSubObject, 'Success').AsText() = 'Y' then begin
                        if JSubObject.Contains('EwbNo') then
                            EWayBillNo := format(GetValueFromJsonObject(JSubObject, 'EwbNo'));
                        if JSubObject.Contains('EwbDt') then
                            EWayBillDateTime := GetValueFromJsonObject(JSubObject, 'EwbDt').AsText();
                        if JSubObject.Contains('EwbValidTill') then
                            EWayExpirationDT := GetValueFromJsonObject(JSubObject, 'EwbValidTill').AsText();
                        DistanceRemark := GetValueFromJsonObject(JSubObject, 'Alert').AsText();
                        // if JSubObject.Contains('Alert') then begin
                        //     JSubObject.Get('Alert', JToken1);
                        //     JToken1.WriteTo(Jarrtext);
                        //     if JArray.ReadFrom(Jarrtext) then begin

                        //         for I := 0 to JArray.Count - 1 do begin
                        //             JArray.Get(I, JToken);
                        //             JObject := JToken.AsObject();
                        //             DistanceRemark := GetValueFromJsonObject(JObject, 'Desc').AsText();

                        //         end;
                        //     end;
                        // end;


                        CreateLogEntry(ServiceInvHeader."No.", DocType::"Service Invoice", ServiceInvHeader."Posting Date", RequestText, ResponseText,
                            EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                        EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                        EInvoiceEntryL."E-Way Generated" := true;
                        EInvoiceEntryL."E-Way Canceled" := false;
                        EInvoiceEntryL."Distance Remark" := DistanceRemark;
                        if DistanceRemark > '' then
                            evaluate(EInvoiceEntryL."Transportation Distance", DelChr(DelChr(DistanceRemark, '=', ', Distance between these two pincodes is '), '=', ', '));

                        EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                        EInvoiceEntryL."LR/RR Date" := ServiceInvHeader."LR/RR Date";
                        EInvoiceEntryL."LR/RR No." := ServiceInvHeader."LR/RR No.";
                        EInvoiceEntryL."Transport Method" := ServiceInvHeader."Transport Method";
                        EInvoiceEntryL."Shipping Agent Code" := ServiceInvHeader."Shipping Agent Code";
                        // ServiceInvHeader."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                        // ServiceInvHeader."Vehicle Type" := ServiceInvHeader."Vehicle Type"::Regular;
                        // if ServiceInvHeader."Distance (Km)" = 0 then
                        //     ServiceInvHeader."Distance (Km)" := EInvoiceEntryL."Transportation Distance";
                        // if ServiceInvHeader."Distance (Km)" = 0 then begin
                        //     if DistanceKM > 0 then
                        //         ServiceInvHeader."Distance (Km)" := DistanceKM;
                        // end;
                        ServiceInvHeader.Modify();
                        Message(EWayGenerated, ServiceInvHeader."No.");
                    end else begin
                        CreateLogEntry(ServiceInvHeader."No.", DocType::"Service Invoice", ServiceInvHeader."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                        EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;

                        EInvoiceEntryL."E-Way Generated" := false;
                        EInvoiceEntryL."E-Way Canceled" := false;

                        if JSubObject.Contains('ErrorDetails') then begin
                            JSubObject.Get('ErrorDetails', JToken1L);
                            JSubArray := JToken1L.AsArray();
                            ErrorDetails := format(JSubArray);

                            //
                            for j := 0 to JSubArray.Count - 1 do begin
                                JSubArray.Get(j, JTokenL);
                                if j = 0 then begin

                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                if j = 1 then begin
                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description 1" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                if j = 2 then begin
                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description 2" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                if j = 3 then begin
                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description 3" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                EInvoiceEntryL.Modify();
                            end;
                        end;
                        Message(StrSubstNo(EWayFailed, ServiceInvHeader."No.") + 'Error As follow \n' + EInvoiceEntryL."Error Description" + '\n' + EInvoiceEntryL."Error Description 2");
                    end;
                    EInvoiceEntryL.Modify();
                end else
                    Error(ResponseText);
            end;
        end;
    end;

    procedure CreateJsonSalesInvoice(SalesInvHeaderP: Record "Sales Invoice Header")
    var
        ewaycard: page "CT Eway Card";
        TransactionTypeL: text;
        SalesInvHeader: Record "Sales Invoice Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        ShippingAgentL: Record "Shipping Agent";
        TransportMethodL: Record "Shipment Method";
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
        JToken1: JsonToken;
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
        DistanceRemark: text;
        Jarrtext: text;
        i: Integer;
        EInvoicemgmt: Codeunit "e-Invoice Management";
        QTYTxt: text;
    begin
        // if EInvoicemgmt.IsGSTApplicable(SalesInvHeaderP."No.", Database::"Sales Invoice Header") and
        // (SalesInvHeaderP."Nature of Supply" <> SalesInvHeaderP."Nature of Supply"::B2C) then
        //     if SalesInvHeaderP."IRN Hash" = '' then
        //         Error('This document is applicable for e-invoice, Kindly generate e-invoice first and try create e-way Bill');



        if SalesInvHeaderP."IRN Hash" > '' then
            CreateJsonSalesInvoiceforIRN(SalesInvHeaderP)
        else begin
            EInvoiceSetupL.Get;

            CheckEwayBillStatus(SalesInvHeaderP."No.", DocType::invoice);
            CreateLogEntry(SalesInvHeaderP."No.", DocType::invoice, SalesInvHeaderP."Posting Date", RequestText, ResponseText,
                                     EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);

            ewaycard.SetTableView(EInvoiceEntryL);
            commit;
            ewaycard.LookupMode := true;
            if ewaycard.RunModal = Action::LookupOK then begin
                EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
                EInvoiceEntryL.SetRange("Document Type", DocType::invoice);
                EInvoiceEntryL.SetRange("Document No.", SalesInvHeaderP."No.");
                EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
                EInvoiceEntryL.FindFirst();

                SalesInvHeader.Copy(SalesInvHeaderP);
                LocationL.Get(SalesInvHeader."Location Code");
                EInvoiceSetupL.Get;

                ShippingAgentL.get(SalesInvHeader."Shipping Agent Code");
                LocationL.TestField("Post Code");
                CompanyInformationL.Get();
                JObject.Add('DocumentNumber', SalesInvHeader."No.");
                JObject.Add('DocumentType', format(EInvoiceEntryL."E-way Document Type"));
                JObject.Add('DocumentDate', Format(SalesInvHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                JObject.Add('SupplyType', format(EInvoiceEntryL.SupplyType));

                JObject.Add('SubSupplyType', format(EInvoiceEntryL."Supply Sub Type"));

                JObject.Add('SubSupplyTypeDesc', format(EInvoiceEntryL."sub supply Type Desc"));




                JObject.Add('TransactionType', format(einvoiceentryL."Eway Bill Transaction Type"));
                if CustomerL."GST Registration No." <> '' then
                    JSubObject.Add('Gstin', CustomerL."GST Registration No.")
                else
                    JSubObject.Add('Gstin', 'URP');
                JSubObject.Add('LglNm', SalesInvHeader."Sell-to Customer Name");
                JSubObject.Add('TrdNm', SalesInvHeader."Sell-to Customer Name 2");
                JSubObject.Add('Addr1', SalesInvHeader."Sell-to Address");
                JSubObject.Add('Addr2', SalesInvHeader."Sell-to Address 2");
                JSubObject.Add('Loc', SalesInvHeader."Sell-to City");
                // if SalesInvHeader."Ship-to Code" = '' then begin
                if SalesInvHeader."GST Customer Type" = SalesInvHeader."GST Customer Type"::Export then begin

                    JSubObject.Add('Stcd', '96');
                    JSubObject.Add('Pin', '999999');
                end else begin



                    if StateL.Get(SalesInvHeader."GST Bill-to State Code") then begin
                        JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                        //   if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then
                        JSubObject.Add('Pin', SalesInvHeader."Sell-to Post Code"); // added additionaly due to missing data.
                    end else
                        Error('State Code is missing in sales Invoice Header')
                end;


                JObject.Add('BuyerDtls', JSubObject);
                Clear(JSubObject);
                if (SalesInvHeader."Ship-to Code" <> '') and (SalesInvHeader."GST Customer Type" = SalesInvHeader."GST Customer Type"::Export) then begin
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

                            JObject.Add('ExpShipDtls', JSubObject);
                        end;
                    end
                end;
                Clear(JSubObject);
                if (SalesInvHeader."Ship-to Code" <> '') and (SalesInvHeader."GST Customer Type" <> SalesInvHeader."GST Customer Type"::Export) then begin
                    JSubObject.Add('LglNm', SalesInvHeader."Ship-to Name");
                    JSubObject.Add('TrdNm', SalesInvHeader."Ship-to Name 2");
                    JSubObject.Add('Addr1', SalesInvHeader."Ship-to Address");
                    JSubObject.Add('Addr2', SalesInvHeader."Ship-to Address 2");
                    JSubObject.Add('Loc', SalesInvHeader."Ship-to City");
                    if StateL.Get(SalesInvHeader."GST Ship-to State Code") then
                        JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)")
                    else
                        if StateL.Get(SalesInvHeader.State) then
                            JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                    JSubObject.Add('Pin', SalesInvHeader."Ship-to post code");


                    JObject.Add('ExpShipDtls', JSubObject);

                end;
                Clear(JSubObject);
                // if (SalesInvHeader."Dispatch-from Code" <> '') and (SalesInvHeader."GST Customer Type" <> SalesInvHeader."GST Customer Type"::Export) then begin
                //     JSubObject.Add('LglNm', SalesInvHeader."Dispatch-from Name");
                //     JSubObject.Add('TrdNm', SalesInvHeader."Dispatch-from Name 2");
                //     JSubObject.Add('Addr1', SalesInvHeader."Dispatch-from Address");
                //     JSubObject.Add('Addr2', SalesInvHeader."Dispatch-from Address 2");
                //     JSubObject.Add('Loc', SalesInvHeader."Dispatch-from City");
                //     if StateL.Get(SalesInvHeader."Dispatch-from State") then
                //         JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                //     JSubObject.Add('Pin', SalesInvHeader."Dispatch-from Post Code");


                //     JObject.Add('DispDtls', JSubObject);

                // end;

                Clear(JSubObject);
                JSubObject.Add('LglNm', LocationL.Name);
                JSubObject.Add('TrdNm', LocationL."Name 2");
                JSubObject.Add('Addr1', LocationL.Address);
                JSubObject.Add('Addr2', LocationL."Address 2");
                JSubObject.Add('Loc', LocationL.City);
                if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                    GSTRegistrationo.get(LocationL."GST Registration No.");
                    JSubObject.Add('Gstin', GSTRegistrationo."Einv Demo GST REgistration No.");

                end else begin
                    if LocationL."GST Registration No." <> '' then
                        JSubObject.Add('Gstin', LocationL."GST Registration No.")
                    else
                        JSubObject.Add('Gstin', CompanyInformationL."GST Registration No.");

                end;
                //    PostCodeL.SetRange(Code, LocationL."Post Code");
                //  if PostCodeL.FindFirst() then;
                JSubObject.Add('Pin', Format(copystr(LocationL."Post Code", 1, 6)));
                if StateL.Get(LocationL."State Code") then;
                JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                JObject.Add('SellerDtls', JSubObject);
                Clear(JSubObject);
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
                if ShippingAgentL."GST Registration No." <> '' then
                    JObject.Add('TransId', ShippingAgentL."GST Registration No.");
                JObject.Add('TransName', ShippingAgentL.Name);
                if salesinvheader."Distance (Km)" > 0 then
                    JObject.Add('Distance', salesinvheader."Distance (Km)")
                else
                    JObject.Add('Distance', 0);

                if SalesInvHeader."LR/RR No." <> '' then begin


                    SalesInvHeader.TestField("Shipment Method code");

                    SalesInvHeader.TestField("Vehicle No.");
                    SalesInvHeader.TestField("LR/RR No.");
                    SalesInvHeader.TestField("LR/RR Date");
                    TransportMethodL.Get(SalesInvHeader."Shipment Method code");

                    if SalesInvHeader."Vehicle Type" = SalesInvHeader."Vehicle Type"::Regular then
                        JObject.Add('VehType', 'REGULAR')
                    else
                        if SalesInvHeader."Vehicle Type" = SalesInvHeader."Vehicle Type"::ODC then
                            JObject.Add('VehType', 'ODC')
                        else
                            JObject.Add('VehType', 'REGULAR');
                    //JObject.Add('VehType', 'REGULAR');

                    JObject.Add('VehNo', DelChr(SalesInvHeader."Vehicle No.", '=', ' ,/-<>  !@#$%^&*()_+{}'));
                    JObject.Add('TransMode', Format(TransportMethodL.code));
                end;
                if SalesInvHeader."LR/RR No." <> '' then
                    JObject.Add('TransDocNo', Format(SalesInvHeader."LR/RR No."));
                if SalesInvHeader."LR/RR Date" <> 0D then
                    JObject.Add('TransDocDt', Format(SalesInvHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));


                GetRoundingGLSales(CustomerL."Customer Posting Group", InvRoundingGL, PITRoungGL);
                //  SalesInvoiceLineL.SetFilter("HSN/SAC Code", '<>%1', '');
                //       SalesInvoiceLineL.SetFilter("No.", '<>%1&<>%2', InvRoundingGL, PITRoungGL);
                //    SalesInvoiceLineL.SetFilter(Type, '<>%1', SalesInvoiceLineL.Type::"G/L Account"); // To be removed add it to skip gl rounding line as above filter not working due to data issue.
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
                        HSNSACCode := SalesInvoiceLineL."HSN/SAC Code";
                        if SalesInvoiceLineL."HSN/SAC Code" = '' then begin
                            if SalesInvoiceLineL.Type = SalesInvoiceLineL.type::Item then begin
                                item.get(salesinvoicelInel."No.");
                                HSNSACCode := item."HSN/SAC Code";

                            end;
                            if SalesInvoiceLineL.Type = SalesInvoiceLineL.type::"Fixed Asset" then begin
                                fixAsset.get(salesinvoicelInel."No.");
                                HSNSACCode := fixAsset."HSN/SAC Code";

                            end
                        end;
                        if HSNSACCode = '' then
                            HSNSACCode := '94013900';
                        JSubObject.Add('HsnCd', Format(HSNSACCode));

                        QTYTxt := format(SalesInvoiceLineL.Quantity);
                        QTYTxt := delchr(QTYTxt, '=', ',');
                        JSubObject.Add('Qty', QTYTxt);
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
                        clear(JSubObject);
                    until SalesInvoiceLineL.Next() = 0;
                JObject.Add('ItemList', JArrayL);
                JObject.WriteTo(RequestText);
                docNo := SalesInvoiceLineL."Document No.";
                SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Creation", '', LocationL."GST Registration No.", false);

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

                        if JSubObject.Contains('Alert') then
                            DistanceRemark := GetValueFromJsonObject(JSubObject, 'Alert').AsText();



                        CreateLogEntry(SalesInvHeader."No.", DocType::Invoice, SalesInvHeader."Posting Date", RequestText, ResponseText,
                            EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                        EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                        EInvoiceEntryL."E-Way Generated" := true;
                        EInvoiceEntryL."E-Way Canceled" := false;
                        EInvoiceEntryL."Distance Remark" := DistanceRemark;
                        if DistanceRemark > '' then
                            evaluate(EInvoiceEntryL."Transportation Distance", DelChr(DelChr(DistanceRemark, '=', ', Distance between these two pincodes is '), '=', ', '));

                        EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                        EInvoiceEntryL."LR/RR Date" := SalesInvHeader."LR/RR Date";
                        EInvoiceEntryL."LR/RR No." := SalesInvHeader."LR/RR No.";
                        EInvoiceEntryL."Transport Method" := SalesInvHeader."Shipment Method code";
                        EInvoiceEntryL."Shipping Agent Code" := SalesInvHeader."Shipping Agent Code";
                        SalesInvHeader."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                        SalesInvHeader."Vehicle Type" := SalesInvHeader."Vehicle Type"::Regular;
                        if SalesInvHeader."Distance (Km)" = 0 then
                            SalesInvHeader."Distance (Km)" := EInvoiceEntryL."Transportation Distance";
                        if SalesInvHeader."Distance (Km)" = 0 then begin
                            if DistanceKM > 0 then
                                SalesInvHeader."Distance (Km)" := DistanceKM;
                        end;
                        SalesInvHeader.Modify();
                        Message(EWayGenerated, SalesInvHeader."No.");
                    end else begin
                        CreateLogEntry(SalesInvHeader."No.", DocType::Invoice, SalesInvHeader."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                        EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;

                        EInvoiceEntryL."E-Way Generated" := false;
                        EInvoiceEntryL."E-Way Canceled" := false;

                        if JSubObject.Contains('ErrorDetails') then begin
                            JSubObject.Get('ErrorDetails', JToken1L);
                            JSubArray := JToken1L.AsArray();
                            ErrorDetails := format(JSubArray);

                            //
                            for j := 0 to JSubArray.Count - 1 do begin
                                JSubArray.Get(j, JTokenL);
                                if j = 0 then begin

                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                if j = 1 then begin
                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description 1" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                if j = 2 then begin
                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description 2" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                if j = 3 then begin
                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description 3" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                EInvoiceEntryL.Modify();
                            end;
                            Message(StrSubstNo(EWayFailed, SalesInvHeader."No.") + '  Error As follow : ' + EInvoiceEntryL."Error Description" + ' ' + EInvoiceEntryL."Error Description 2");
                        end;

                    end;
                    EInvoiceEntryL.Modify();
                end else
                    Error(ResponseText);
            end;
        end;
    end;

    procedure CreateJsonPurchaseInv(var PurchCrMemoHdr: Record "Purch. Inv. Header")
    var
        JSubObject: JsonObject;
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        TransportMethodL: Record "Shipment Method";
        ShippingAgentL: Record "Shipping Agent";
        CompanyInformationL: Record "Company Information";
        PostCodeL: Record "Post Code";
        VendorL: Record Vendor;
        StateL: Record State;
        PurchCrMemoLine: Record "Purch. inv. Line";
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
        LCYCurrency: Decimal;
        ewaycard: Page "CT Eway Card";
    begin
        if PurchCrMemoHdr."Currency Factor" <> 0 then
            LCYCurrency := 1 / PurchCrMemoHdr."Currency Factor"
        else
            LCYCurrency := 1;


        EInvoiceSetupL.Get;

        CheckEwayBillStatus(PurchCrMemoHdr."No.", DocType::"Purch. Inv. Hdr");
        CreateLogEntry(PurchCrMemoHdr."No.", DocType::"Purch. Inv. Hdr", PurchCrMemoHdr."Posting Date", RequestText, ResponseText,
                                 EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);

        ewaycard.SetTableView(EInvoiceEntryL);
        commit;
        ewaycard.LookupMode := true;
        if ewaycard.RunModal = Action::LookupOK then begin
            EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
            EInvoiceEntryL.SetRange("Document Type", DocType::"Purch. Inv. Hdr");
            EInvoiceEntryL.SetRange("Document No.", PurchCrMemoHdr."No.");
            EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
            EInvoiceEntryL.FindFirst();

            LocationL.Get(PurchCrMemoHdr."Location Code");
            EInvoiceSetupL.Get;

            CheckEwayBillStatus(PurchCrMemoHdr."No.", DocType::"Purch. Inv. Hdr");
            ShippingAgentL.Get(PurchCrMemoHdr."Shipping Agent Code");
            CompanyInformationL.Get();
            if PurchCrMemoHdr."vendor Invoice No." > '' then
                JObject.Add('DocumentNumber', COPYSTR(DELCHR(PurchCrMemoHdr."vendor Invoice No.", '=', ' ,/'), 1, 20))
            else
                JObject.Add('DocumentNumber', COPYSTR(DELCHR(PurchCrMemoHdr."No.", '=', ' ,/'), 1, 20));

            JObject.Add('DocumentDate', Format(PurchCrMemoHdr."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));
            if VendorL.Get(PurchCrMemoHdr."Pay-to Vendor No.") then
                if vendorL."Country/Region Code" <> 'IN' Then begin
                    PurchCrMemoHdr.TestField("Entry Point");
                    JObject.Add('SupplyType', format(einvoiceentryL.Supplytype));
                    JObject.Add('SubSupplyType', format(einvoiceentryL."Supply Sub Type"));
                    JObject.Add('DocumentType', format(einvoiceentryL."E-way Document Type"));
                end else begin
                    JObject.Add('SupplyType', format(einvoiceentryL.Supplytype));
                    JObject.Add('SubSupplyType', format(einvoiceentryL."Supply Sub Type"));
                    JObject.Add('DocumentType', format(einvoiceentryL."E-way Document Type"));

                end;


            JObject.Add('TransactionType', format(einvoiceentryL."Eway Bill Transaction Type"));

            JObject.Add('SubSupplyTypeDesc', format(einvoiceentryL."Sub Supply Type Desc"));

            JSubObject.Add('LglNm', LocationL.Name);
            JSubObject.Add('TrdNm', LocationL.Name);
            JSubObject.Add('Addr1', LocationL.Address);
            JSubObject.Add('Addr2', LocationL."Address 2");
            JSubObject.Add('Loc', LocationL.City);
            PostCodeL.SetRange(Code, LocationL."Post Code");
            if PostCodeL.FindFirst() then;
            JSubObject.Add('Pin', Format(copystr(LocationL."Post Code", 1, 6)));
            if (EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo) then begin
                GSTRegistrationo.get(LocationL."GST Registration No.");
                JSubObject.Add('Gstin', GSTRegistrationo."Einv Demo GST REgistration No.");
            end else
                if LocationL."GST Registration No." <> '' then
                    JSubObject.Add('Gstin', LocationL."GST Registration No.")
                else
                    JSubObject.Add('Gstin', CompanyInformationL."GST Registration No.");
            if StateL.Get(LocationL."State Code") then
                if StateL."State Code (GST Reg. No.)" <> '' then
                    JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)")
                else begin

                    JSubObject.Add('Stcd', '');
                end;

            JObject.Add('BuyerDtls', JSubObject);
            Clear(JSubObject);

            clear(JSubObject);
            if PurchCrMemoHdr."Entry Point" <> '' then begin
                EntryExitPoint.get(PurchCrMemoHdr."Entry Point");
                JSubObject.Add('LglNm', EntryExitPoint.Description);
                JSubObject.Add('TrdNm', EntryExitPoint.Description);
                JSubObject.Add('Addr1', EntryExitPoint.Address);
                JSubObject.Add('Addr2', EntryExitPoint."Address 2");
                JSubObject.Add('Loc', EntryExitPoint.City);
                if StateL.Get(EntryExitPoint."State Code") then
                    JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                JSubObject.Add('Pin', EntryExitPoint."Post Code");
                JObject.Add('DispDtls', JSubObject);
            end;
            Clear(JSubObject);
            JSubObject.Add('LglNm', PurchCrMemoHdr."Buy-from Vendor Name" + ' ' + PurchCrMemoHdr."Buy-from Vendor Name 2");
            JSubObject.Add('TrdNm', PurchCrMemoHdr."Buy-from Vendor Name" + ' ' + PurchCrMemoHdr."Buy-from Vendor Name 2");
            JSubObject.Add('Addr1', PurchCrMemoHdr."Buy-from Address");
            JSubObject.Add('Addr2', PurchCrMemoHdr."Buy-from Address 2");
            JSubObject.Add('Loc', PurchCrMemoHdr."Buy-from City");
            if VendorL.Get(PurchCrMemoHdr."Pay-to Vendor No.") then
                if VendorL."GST Registration No." <> '' then
                    JSubObject.Add('Gstin', VendorL."GST Registration No.")
                else
                    JSubObject.Add('Gstin', 'URP');
            if StateL.Get(VendorL."State Code") then begin
                if StateL."State Code (GST Reg. No.)" > '' then begin
                    JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                    JSubObject.Add('Pin', Format(copystr(PurchCrMemoHdr."Buy-from Post Code", 1, 6)));
                end;
            end else begin
                if vendorL."Country/Region Code" <> 'IN' Then begin
                    JSubObject.Add('Stcd', '96');
                    JSubObject.Add('Pin', '999999');
                end;
            end;
            //PostCodeL.SetRange(Code, PurchCrMemoHdr."Buy-from Post Code");
            //if PostCodeL.FindFirst() then

            JObject.Add('SellerDtls', JSubObject);

            JObject.Add('TotalInvoiceAmount', Round((GetTaxableAmountPInv(PurchCrMemoHdr."No.") * LCYCurrency), 0.01, '=') +
              GetGSTAmount(PurchCrMemoHdr."No.", 'CGST') + GetGSTAmount(PurchCrMemoHdr."No.", 'SGST') + GetGSTAmount(PurchCrMemoHdr."No.", 'IGST') +
              GetGSTAmount(PurchCrMemoHdr."No.", 'CESS'));
            JObject.Add('TotalAssessableAmount', Round(GetTaxableAmountPInv(PurchCrMemoHdr."No.") * LCYCurrency, 0.01, '='));
            JObject.Add('TotalCgstAmount', Round(GetGSTAmount(PurchCrMemoHdr."No.", 'CGST'), 0.01, '='));
            JObject.Add('TotalSgstAmount', Round(GetGSTAmount(PurchCrMemoHdr."No.", 'SGST'), 0.01, '='));
            JObject.Add('TotalIgstAmount', Round(GetGSTAmount(PurchCrMemoHdr."No.", 'IGST'), 0.01, '='));
            JObject.Add('TotalCessAmount', Round(GetGSTAmount(PurchCrMemoHdr."No.", 'CESS'), 0.01, '='));
            if ShippingAgentL."GST Registration No." > '' then
                JObject.Add('TransId', ShippingAgentL."GST Registration No.");
            JObject.Add('TransName', ShippingAgentL.Name);
            if PurchCrMemoHdr."Vehicle No." <> '' then begin
                TransportMethodL.Get(PurchCrMemoHdr."Shipment Method code");
                PurchCrMemoHdr.TestField("Vehicle No.");
                PurchCrMemoHdr.TestField("Shipping Agent Code");
                PurchCrMemoHdr.TestField("Shipment Method code");
                PurchCrMemoHdr.TestField("LR/RR No.");
                PurchCrMemoHdr.TestField("LR/RR Date");
                JObject.Add('transactionType', einvoiceentryL."Eway Bill Transaction Type");
                JObject.Add('TransDocNo', PurchCrMemoHdr."LR/RR No.");
                JObject.Add('TransMode', Format(TransportMethodL.code));
                JObject.Add('Distance', PurchCrMemoHdr."Distance (Km)");
                JObject.Add('TransDocDt', Format(PurchCrMemoHdr."LR/RR Date"));
                JObject.Add('VehNo', DELCHR(PurchCrMemoHdr."Vehicle No.", '=', ' ,/-<>  !@#$%^&*()_+{}'));
                if PurchCrMemoHdr."Vehicle Type" = PurchCrMemoHdr."Vehicle Type"::Regular then
                    JObject.Add('VehType', 'R')
                else
                    if PurchCrMemoHdr."Vehicle Type" = PurchCrMemoHdr."Vehicle Type"::ODC then
                        JObject.Add('VehType', 'O')
                    else
                        JObject.Add('VehType', 'R');
            end;

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
                    JSubObject.Add('AssAmt', Round((PurchCrMemoLine."Line Amount" - PurchCrMemoLine."Line Discount Amount") * LCYCurrency, 0.01, '='));
                    JArray.Add(JSubObject);
                until PurchCrMemoLine.Next() = 0;
            JObject.Add('ItemList', JArray);
            JObject.WriteTo(RequestText);
            docNo := PurchCrMemoLine."Document No.";
            SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Creation", '', LocationL."GST Registration No.", false);

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
                    CreateLogEntry(PurchCrMemoHdr."No.", DocType::"Purch. Inv. Hdr", PurchCrMemoHdr."Posting Date", RequestText, ResponseText,
                      EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                    EInvoiceEntryL."E-Way Generated" := true;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                    EInvoiceEntryL."LR/RR Date" := PurchCrMemoHdr."LR/RR Date";
                    EInvoiceEntryL."LR/RR No." := PurchCrMemoHdr."LR/RR No.";
                    EInvoiceEntryL."Transport Method" := PurchCrMemoHdr."Shipment Method code";
                    EInvoiceEntryL."Shipping Agent Code" := PurchCrMemoHdr."Shipping Agent Code";
                    PurchCrMemoHdr."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                    PurchCrMemoHdr."Vehicle Type" := PurchCrMemoHdr."Vehicle Type"::Regular;
                    PurchCrMemoHdr.Modify();
                    Message(EWayGenerated, PurchCrMemoHdr."No.");
                end else begin
                    CreateLogEntry(PurchCrMemoHdr."No.", DocType::"Purch. Inv. Hdr", PurchCrMemoHdr."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;
                    EInvoiceEntryL."E-Way Generated" := false;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    //  Message(EWayFailed, PurchCrMemoHdr."No.");
                    if JSubObject.Contains('ErrorDetails') then begin
                        JSubObject.Get('ErrorDetails', JToken1L);
                        JSubArray := JToken1L.AsArray();
                        ErrorDetails := format(JSubArray);

                        //
                        for j := 0 to JSubArray.Count - 1 do begin
                            JSubArray.Get(j, JTokenL);
                            if j = 0 then begin

                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 1 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 1" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 2 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 2" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 3 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 3" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            EInvoiceEntryL.Modify();
                        end;
                    end;
                    Message(StrSubstNo(EWayFailed, PurchCrMemoHdr."No.") + '  Error As follow : ' + EInvoiceEntryL."Error Description" + ' ' + EInvoiceEntryL."Error Description 2");
                end;
                EInvoiceEntryL.Modify();
            end else
                Error(ResponseText);
        end;
    end;


    procedure CreateJsonPurchaseReturn(var PurchCrMemoHdr: Record "Purch. cr. Memo Hdr.")
    var
        JSubObject: JsonObject;
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        TransportMethodL: Record "Shipment Method";
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
        ewaycard: Page "CT Eway Card";
    begin


        LocationL.Get(PurchCrMemoHdr."Location Code");
        EInvoiceSetupL.Get;

        CheckEwayBillStatus(PurchCrMemoHdr."No.", DocType::"Purch Cr. Memo Hdr");

        CreateLogEntry(PurchCrMemoHdr."No.", DocType::"Purch Cr. Memo Hdr", PurchCrMemoHdr."Posting Date", RequestText, ResponseText,
                                 EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);

        ewaycard.SetTableView(EInvoiceEntryL);
        commit;
        ewaycard.LookupMode := true;
        if ewaycard.RunModal = Action::LookupOK then begin
            EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
            EInvoiceEntryL.SetRange("Document Type", DocType::"Purch Cr. Memo Hdr");
            EInvoiceEntryL.SetRange("Document No.", PurchCrMemoHdr."No.");
            EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
            EInvoiceEntryL.FindFirst();


            ShippingAgentL.Get(PurchCrMemoHdr."Shipping Agent Code");
            CompanyInformationL.Get();
            JObject.Add('DocumentNumber', COPYSTR(DELCHR(PurchCrMemoHdr."No.", '=', '/'), 1, 9));

            JObject.Add('DocumentDate', Format(PurchCrMemoHdr."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));
            JObject.Add('SupplyType', format(einvoiceentryL.Supplytype));
            JObject.Add('SubSupplyType', format(einvoiceentryL."Supply Sub Type"));
            JObject.Add('DocumentType', format(einvoiceentryL."E-way Document Type"));
            JObject.Add('SubSupplyTypeDesc', einvoiceentryL."Sub Supply Type Desc");
            JObject.Add('transactionType', einvoiceentryL."Eway Bill Transaction Type");



            JSubObject.Add('LglNm', LocationL.Name);
            JSubObject.Add('TrdNm', LocationL.Name);
            JSubObject.Add('Addr1', LocationL.Address);
            JSubObject.Add('Addr2', LocationL."Address 2");
            JSubObject.Add('Loc', LocationL.City);
            PostCodeL.SetRange(Code, LocationL."Post Code");
            if PostCodeL.FindFirst() then;
            JSubObject.Add('Pin', Format(LocationL."Post Code"));
            if (EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo) then begin
                GSTRegistrationo.get(LocationL."GST Registration No.");
                JSubObject.Add('Gstin', GSTRegistrationo."Einv Demo GST REgistration No.");
            end else
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
            JSubObject.Add('LglNm', PurchCrMemoHdr."Buy-from Vendor Name" + ' ' + PurchCrMemoHdr."Buy-from Vendor Name 2");
            JSubObject.Add('TrdNm', PurchCrMemoHdr."Buy-from Vendor Name" + ' ' + PurchCrMemoHdr."Buy-from Vendor Name 2");
            JSubObject.Add('Addr1', PurchCrMemoHdr."Buy-from Address");
            JSubObject.Add('Addr2', PurchCrMemoHdr."Buy-from Address 2");
            JSubObject.Add('Loc', PurchCrMemoHdr."Buy-from City");
            if VendorL.Get(PurchCrMemoHdr."Pay-to Vendor No.") then
                if VendorL."GST Registration No." <> '' then
                    JSubObject.Add('Gstin', VendorL."GST Registration No.")
                else
                    JSubObject.Add('Gstin', 'URP');
            if PurchCrMemoHdr."Pay-to Country/Region Code" <> 'IN' then begin
                JSubObject.Add('Stcd', '96');
                JSubObject.Add('Pin', '999999');
            end else begin
                if StateL.Get(VendorL."State Code") then
                    if StateL."State Code (GST Reg. No.)" > '' then
                        JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)")
                    else
                        JSubObject.Add('stcd', '');
                //PostCodeL.SetRange(Code, PurchCrMemoHdr."Buy-from Post Code");
                //if PostCodeL.FindFirst() then
                JSubObject.Add('Pin', Format(PurchCrMemoHdr."Buy-from Post Code"));
            end;
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
            if PurchCrMemoHdr."Vehicle No." <> '' then begin
                TransportMethodL.Get(PurchCrMemoHdr."Shipment Method code");
                PurchCrMemoHdr.TestField("Vehicle No.");
                PurchCrMemoHdr.TestField("Shipping Agent Code");
                PurchCrMemoHdr.TestField("Shipment Method code");
                PurchCrMemoHdr.TestField("LR/RR No.");
                PurchCrMemoHdr.TestField("LR/RR Date");

                JObject.Add('TransDocNo', PurchCrMemoHdr."LR/RR No.");
                JObject.Add('TransMode', Format(TransportMethodL.code));
                JObject.Add('Distance', PurchCrMemoHdr."Distance (Km)");
                JObject.Add('TransDocDt', Format(PurchCrMemoHdr."LR/RR Date"));
                JObject.Add('VehNo', DELCHR(PurchCrMemoHdr."Vehicle No.", '=', ' ,/-<>  !@#$%^&*()_+{}'));
                if PurchCrMemoHdr."Vehicle Type" = PurchCrMemoHdr."Vehicle Type"::Regular then
                    JObject.Add('VehType', 'R')
                else
                    if PurchCrMemoHdr."Vehicle Type" = PurchCrMemoHdr."Vehicle Type"::ODC then
                        JObject.Add('VehType', 'O')
                    else
                        JObject.Add('VehType', 'R');
            end;

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
            docNo := PurchCrMemoLine."Document No.";
            SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Creation", '', LocationL."GST Registration No.", false);

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
                    CreateLogEntry(PurchCrMemoHdr."No.", DocType::"Purch Cr. Memo Hdr", PurchCrMemoHdr."Posting Date", RequestText, ResponseText,
                      EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                    EInvoiceEntryL."E-Way Generated" := true;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                    EInvoiceEntryL."LR/RR Date" := PurchCrMemoHdr."LR/RR Date";
                    EInvoiceEntryL."LR/RR No." := PurchCrMemoHdr."LR/RR No.";
                    EInvoiceEntryL."Transport Method" := PurchCrMemoHdr."Shipment Method code";
                    EInvoiceEntryL."Shipping Agent Code" := PurchCrMemoHdr."Shipping Agent Code";
                    PurchCrMemoHdr."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                    PurchCrMemoHdr."Vehicle Type" := PurchCrMemoHdr."Vehicle Type"::Regular;
                    PurchCrMemoHdr.Modify();
                    Message(EWayGenerated, PurchCrMemoHdr."No.");
                end else begin
                    CreateLogEntry(PurchCrMemoHdr."No.", DocType::"Purch Cr. Memo Hdr", PurchCrMemoHdr."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;
                    EInvoiceEntryL."E-Way Generated" := false;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    //     Message(EWayFailed, PurchCrMemoHdr."No.");
                    if JSubObject.Contains('ErrorDetails') then begin
                        JSubObject.Get('ErrorDetails', JToken1L);
                        JSubArray := JToken1L.AsArray();
                        ErrorDetails := format(JSubArray);

                        //
                        for j := 0 to JSubArray.Count - 1 do begin
                            JSubArray.Get(j, JTokenL);
                            if j = 0 then begin

                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 1 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 1" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 2 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 2" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 3 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 3" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            EInvoiceEntryL.Modify();
                        end;
                    end;
                    Message(StrSubstNo(EWayFailed, PurchCrMemoHdr."No.") + '  Error As follow : ' + EInvoiceEntryL."Error Description" + ' ' + EInvoiceEntryL."Error Description 2");
                end;
                EInvoiceEntryL.Modify();
            end else
                Error(ResponseText);
        end;
    end;

    procedure CreateJsonTranferShipment(var TransShipHdr: Record "Transfer Shipment Header")
    var
        JSubObject: JsonObject;
        JArrayL: JsonArray;
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        TransportMethodL: Record "Shipment Method";
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
        TransactionTypeL: text;
        EInvoicemgmt: Codeunit "e-Invoice Management";
        gstSetup: Record "GST setup";
        ewaycard: page "CT Eway Card";
    begin

        GSTSetup.Get();


        if CheckTransferInvoiceLine(TransShipHdr."No.", GSTSetup."GST Tax Type") then
            if TransShipHdr."IRN Hash" = '' then
                Error('This document is applicable for e-invoice, Kindly generate e-invoice first and try create e-way Bill');



        if TransShipHdr."IRN Hash" > '' then
            CreateJsonTransShipmentforIRN(TransShipHdr)
        else begin
            CheckEwayBillStatus(TransShipHdr."No.", DocType::TransferShpt);
            CreateLogEntry(TransShipHdr."No.", DocType::TransferShpt, TransShipHdr."Posting Date", RequestText, ResponseText,
                                     EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
            ewaycard.SetTableView(EInvoiceEntryL);
            commit;
            ewaycard.LookupMode := true;
            if ewaycard.RunModal = Action::LookupOK then begin
                EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
                EInvoiceEntryL.SetRange("Document Type", DocType::TransferShpt);
                EInvoiceEntryL.SetRange("Document No.", TransShipHdr."No.");
                EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
                EInvoiceEntryL.FindFirst();

                LocationL.get(TransShipHdr."Transfer-from Code");
                // TransShipHdr.TestField("Vehicle No.");
                TransShipHdr.TestField("Shipping Agent Code");
                //TransShipHdr.TestField("Shipment Method code");
                //   TransShipHdr.TestField("LR/RR No.");
                // TransShipHdr.TestField("LR/RR Date");

                //if TransShipHdr."IRN hash" > '' then
                LocationL.Get(TransShipHdr."Transfer-from Code");
                EInvoiceSetupL.Get;
                if Status = Status::"PartA/B" then begin
                    TransShipHdr.TestField("Vehicle No.");
                end;
                CompanyInformationL.Get;


                JObject.Add('SupplyType', format(EInvoiceEntryL.SupplyType));

                JObject.Add('DocumentType', Format(EInvoiceEntryL."E-way Document Type"));

                //  JObject.Add('SubSupplyTypeDesc', EInvoiceEntryL."Supply Sub Type Desc");

                JObject.Add('DocumentNumber', TransShipHdr."No.");
                JObject.Add('DocumentDate', Format(TransShipHdr."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                TransactionTypeL := '';
                // if (TransShipHdr."Ship-to Code" <> '') and (ServiceInvHeader."Dispatch-from Code" <> '') Then
                //     TransactionTypeL := 'Combination';




                JObject.Add('TransactionType', format(EInvoiceEntryL."Eway Bill Transaction Type"));
                //  JObject.Add('TransactionType', 'Regular'); // hard code


                //  if LocationL."Country/Region Code" = 'IN' then begin
                JObject.Add('SubSupplyType', format(EInvoiceEntryL."Supply Sub Type"));
                JObject.Add('SubSupplyTypeDesc', EInvoiceEntryL."Sub Supply Type Desc");
                // end else begin
                //     JObject.Add('SubSupplyType', );
                //     JObject.Add('SubSupplyTypeDesc', 'Export');
                // end;

                JSubObject.Add('LglNm', LocationL.Name);
                JSubObject.Add('TrdNm', LocationL.Name);
                JSubObject.Add('Addr1', LocationL.Address);
                JSubObject.Add('Addr2', LocationL."Address 2");
                JSubObject.Add('Loc', LocationL.City);
                // PostCodeL.SetRange(Code, TransShipHdr."Transfer-from Post Code");
                //   if PostCodeL.FindFirst() then
                JSubObject.Add('Pin', Format(copystr(LocationL."Post Code", 1, 6)));
                if (EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo) then begin
                    GSTRegistrationo.get(LocationL."GST Registration No.");
                    JSubObject.Add('Gstin', GSTRegistrationo."Einv Demo GST REgistration No.");
                end else
                    if LocationL.Get(TransShipHdr."Transfer-from Code") then
                        if LocationL."GST Registration No." <> '' then
                            JSubObject.Add('Gstin', LocationL."GST Registration No.")
                        else
                            JSubObject.Add('Gstin', CompanyInformationL."GST Registration No.");
                if StateL.Get(LocationL."State Code") then
                    JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                JObject.Add('SellerDtls', JSubObject);
                clear(JSubObject);
                LocationL.Get(TransShipHdr."Transfer-to Code");
                JSubObject.Add('LglNm', LocationL.Name);
                JSubObject.Add('TrdNm', LocationL.Name);
                JSubObject.Add('Addr1', LocationL.Address);
                JSubObject.Add('Addr2', LocationL."Address 2");
                JSubObject.Add('Loc', LocationL.City);
                //  JSubObject.Add('Gstin', LocationL."GST Registration No.");
                if (EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo) then begin
                    GSTRegistrationo.get(LocationL."GST Registration No.");
                    JSubObject.Add('Gstin', GSTRegistrationo."Einv Demo GST REgistration No.");
                end else
                    if LocationL.Get(TransShipHdr."Transfer-To Code") then
                        if LocationL."GST Registration No." <> '' then
                            JSubObject.Add('Gstin', LocationL."GST Registration No.");


                // PostCodeL.SetRange(Code, TransShipHdr."Transfer-from Post Code");
                //   if PostCodeL.FindFirst() then
                JSubObject.Add('Pin', Format(copystr(LocationL."Post Code", 1, 6)));

                if StateL.Get(LocationL."State Code") then
                    JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                JObject.Add('BuyerDtls', JSubObject);
                clear(JSubObject);

                // JSubObject.Add('LglNm', LocationL.Name);
                // JSubObject.Add('TrdNm', LocationL."Name 2");
                // JSubObject.Add('Addr1', LocationL."Address");
                // JSubObject.Add('Addr2', LocationL.address);
                // JSubObject.Add('Loc', LocationL."City");
                // if LocationL.Get(TransShipHdr."Dispatch-from Code") then
                //     JSubObject.Add('Gstin', LocationL."GST Registration No.");
                // if StateL.Get(TransShipHdr."Dispatch-from State") then
                //     JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                // JSubObject.Add('Pin', TransShipHdr."Dispatch-from Post Code");
                // JObject.Add('DispDtls', JSubObject);
                clear(JSubObject);

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

                if TransShipHdr."Vehicle No." <> '' then begin
                    JObject.Add('transDistance', '');
                    // TransShipHdr
                    // JObject.Add('transactionType', 'Regular');
                    // TransactionTypeL := '';
                    // // if (TransShipHdr."Ship-to Code" <> '') and (SalesInvHeader."Dispatch-from Code" <> '') Then
                    // //     TransactionTypeL := 'Combination';
                    // if (TransShipHdr."Dispatch-from Code" <> '') Then
                    //     TransactionTypeL := 'Bill from-dispatch from';
                    // if TransactionTypeL = '' then
                    //     TransactionTypeL := 'Regular';


                    TransportMethodL.Get(TransShipHdr."Shipment Method code");
                    //     JObject.Add('TransactionType', TransactionTypeL);
                    JObject.Add('TransDocNo', TransShipHdr."LR/RR No.");
                    JObject.Add('TransMode', Format(TransportMethodL.code));
                    JObject.Add('TransDocDt', Format(TransShipHdr."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                    JObject.Add('VehNo', DELCHR(TransShipHdr."Vehicle No.", '=', ' ,/-<>  !@#$%^&*()_+{}'));
                    if TransShipHdr."Vehicle Type" = TransShipHdr."Vehicle Type"::Regular then
                        JObject.Add('VehType', 'R')
                    else
                        if TransShipHdr."Vehicle Type" = TransShipHdr."Vehicle Type"::ODC then
                            JObject.Add('VehType', 'O')
                        else
                            JObject.Add('VehType', 'R');
                end;


                TransferShipmentLine.RESET;
                TransferShipmentLine.SetRange("Document No.", TransShipHdr."No.");
                TransferShipmentLine.SetFilter(Quantity, '<>%1', 0);
                if TransferShipmentLine.FindSet() then
                    repeat
                        JSubObject.Add('ProdName', TransferShipmentLine.Description);
                        JSubObject.Add('ProdDesc', TransferShipmentLine.Description);
                        if TransferShipmentLine."HSN/SAC Code" > '' then
                            JSubObject.Add('HsnCd', Format(TransferShipmentLine."HSN/SAC Code"))
                        else begin
                            item.get(TransferShipmentLine."Item No.");
                            JSubObject.Add('HsnCd', Format(item."HSN/SAC Code"));
                        end;


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
                docNo := TransShipHdr."No.";
                LocationL.get(TransShipHdr."Transfer-from Code");
                SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Creation", '', LocationL."GST Registration No.", false);

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
                        CreateLogEntry(TransShipHdr."No.", DocType::TransferShpt, TransShipHdr."Posting Date", RequestText, ResponseText,
                          EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                        EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                        EInvoiceEntryL."E-Way Generated" := true;
                        EInvoiceEntryL."E-Way Canceled" := false;
                        EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                        EInvoiceEntryL."LR/RR Date" := TransShipHdr."LR/RR Date";
                        EInvoiceEntryL."LR/RR No." := TransShipHdr."LR/RR No.";
                        EInvoiceEntryL."Transport Method" := TransShipHdr."Shipment Method code";
                        EInvoiceEntryL."Shipping Agent Code" := TransShipHdr."Shipping Agent Code";
                        TransShipHdr."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                        TransShipHdr."Vehicle Type" := TransShipHdr."Vehicle Type"::Regular;
                        TransShipHdr.Modify();
                        Message(EWayGenerated, TransShipHdr."No.");
                    end else begin
                        CreateLogEntry(TransShipHdr."No.", DocType::TransferShpt, TransShipHdr."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                        EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;
                        EInvoiceEntryL."E-Way Generated" := false;
                        EInvoiceEntryL."E-Way Canceled" := false;
                        // Message(EWayFailed, TransShipHdr."No.");
                        if JSubObject.Contains('ErrorDetails') then begin
                            JSubObject.Get('ErrorDetails', JToken1L);
                            JSubArray := JToken1L.AsArray();
                            ErrorDetails := format(JSubArray);

                            //
                            for j := 0 to JSubArray.Count - 1 do begin
                                JSubArray.Get(j, JTokenL);
                                if j = 0 then begin

                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                if j = 1 then begin
                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description 1" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                if j = 2 then begin
                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description 2" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                if j = 3 then begin
                                    JObjectL := JTokenL.AsObject();
                                    EInvoiceEntryL."Error Description 3" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                                end;
                                EInvoiceEntryL.Modify();
                            end;

                        end;
                        Message(StrSubstNo(EWayFailed, TransShipHdr."No.") + '  Error As follow : ' + EInvoiceEntryL."Error Description" + ' ' + EInvoiceEntryL."Error Description 2");
                    end;
                    EInvoiceEntryL.Modify();
                end else
                    Error(ResponseText);
            end;
        end;
    end;


    procedure CreateJsonSalesCrMemo(SalesCrMemoHdrP: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        ShippingAgentL: Record "Shipping Agent";
        TransportMethodL: Record "Shipment Method";
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
        EInvoicemgmt: Codeunit "e-Invoice Management";
        TransactionTypeL: text;
        ewaycard: page "CT eway card";

    begin
        //rram

        // if EInvoicemgmt.IsGSTApplicable(SalesCrMemoHdrP."No.", Database::"sales Cr.Memo Header") then
        //     if SalesCrMemoHdrP."IRN Hash" > '' then
        //         CreateJsonSalesCrMemoforIRN(SalesCrMemoHdrP)
        //     else
        //         error('This Document is appliable for sales credit Memo');


        SalesCrMemoHdr.copy(SalesCrMemoHdrP);

        CheckEwayBillStatus(SalesCrMemoHdr."No.", DocType::CrMemo);
        CreateLogEntry(SalesCrMemoHdr."No.", DocType::CrMemo, SalesCrMemoHdr."Posting Date", RequestText, ResponseText,
                                 EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::crmemo);
        EInvoiceEntryL.SetRange("Document No.", SalesCrMemoHdr."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        //           EInvoiceEntryL.FindFirst();

        ewaycard.SetTableView(EInvoiceEntryL);
        commit;

        ewaycard.LookupMode := true;
        if ewaycard.RunModal = Action::LookupOK then begin
            EInvoiceEntryL.SetRange("Document Type", DocType::crmemo);
            EInvoiceEntryL.SetRange("Document No.", SalesCrMemoHdr."No.");
            EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
            EInvoiceEntryL.FindFirst();
            SalesCrMemoHdr.Copy(SalesCrMemoHdrP);
            LocationL.Get(SalesCrMemoHdr."Location Code");
            EInvoiceSetupL.Get;
            LocationL.TestField("Post Code");
            CompanyInformationL.Get();
            JObject.Add('DocumentNumber', SalesCrMemoHdr."No.");
            JObject.Add('DocumentType', format(EInvoiceEntryL."E-way Document Type"));
            JObject.Add('DocumentDate', Format(SalesCrMemoHdr."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));
            JObject.Add('SupplyType', Format(einvoiceEntryL.SupplyType));
            JObject.Add('SubSupplyType', Format(einvoiceEntryL."Supply Sub Type"));

            if (SalesCrMemoHdr."Ship-to Code" <> '') Then
                TransactionTypeL := 'Bill to-ship to';

            if TransactionTypeL = '' then
                TransactionTypeL := 'Regular';

            JObject.Add('TransactionType', Format(einvoiceEntryL."Eway Bill Transaction Type"));

            ReadCrMemoBuyerDetails(SalesCrMemoHdr);
            Clear(JSubObject);
            if (SalesCrMemoHdr."Ship-to Code" <> '') and (SalesCrMemoHdr."GST Customer Type" = SalesCrMemoHdr."GST Customer Type"::Export) then begin
                JSubObject.Add('LglNm', SalesCrMemoHdr."Ship-to Name");
                JSubObject.Add('TrdNm', SalesCrMemoHdr."Ship-to Name 2");
                JSubObject.Add('Addr1', SalesCrMemoHdr."Ship-to Address");
                JSubObject.Add('Addr2', SalesCrMemoHdr."Ship-to Address 2");
                JSubObject.Add('Loc', SalesCrMemoHdr."Ship-to City");
                if SalesCrMemoHdr."Ship-to Code" = '' then begin
                    if SalesCrMemoHdr."GST Customer Type" = SalesCrMemoHdr."GST Customer Type"::Export then begin
                        if "Entry/ExitPointL".Get(SalesCrMemoHdr."Exit Point") then begin
                            if StateL.Get("Entry/ExitPointL"."State Code") then;
                            JSubObject.Add('Stcd', Format(StateL."State Code (GST Reg. No.)"));
                            JSubObject.Add('Pin', Format("Entry/ExitPointL"."Post Code"));
                        end else begin
                            JSubObject.Add('Stcd', '96');
                            JSubObject.Add('Pin', '999999');
                        end;

                        JObject.Add('ExpShipDtls', JSubObject);
                    end;
                end
            end;
            Clear(JSubObject);
            if (SalesCrMemoHdr."Ship-to Code" <> '') and (SalesCrMemoHdr."GST Customer Type" <> SalesCrMemoHdr."GST Customer Type"::Export) then begin
                JSubObject.Add('LglNm', SalesCrMemoHdr."Ship-to Name");
                JSubObject.Add('TrdNm', SalesCrMemoHdr."Ship-to Name 2");
                JSubObject.Add('Addr1', SalesCrMemoHdr."Ship-to Address");
                JSubObject.Add('Addr2', SalesCrMemoHdr."Ship-to Address 2");
                JSubObject.Add('Loc', SalesCrMemoHdr."Ship-to City");
                if StateL.Get(SalesCrMemoHdr."GST Ship-to State Code") then
                    JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)")
                else
                    if StateL.Get(SalesCrMemoHdr.State) then
                        JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                JSubObject.Add('Pin', SalesCrMemoHdr."Ship-to post code");
                JObject.Add('ExpShipDtls', JSubObject);

            end;
            Clear(JSubObject);

            if SalesCrMemoHdr."GST Customer Type" = SalesCrMemoHdr."GST Customer Type"::Export then begin

                if "Entry/ExitPointL".Get(SalesCrMemoHdr."Exit Point") then begin
                    JSubObject.Add('LglNm', SalesCrMemoHdr."Bill-to Name");
                    JSubObject.Add('TrdNm', SalesCrMemoHdr."Bill-to Name");
                    JSubObject.Add('Addr1', "Entry/ExitPointL".Address);
                    JSubObject.Add('Addr2', "Entry/ExitPointL"."Address 2");
                    JSubObject.Add('Loc', "Entry/ExitPointL".City);
                    if StateL.Get("Entry/ExitPointL"."State Code") then
                        JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
                    JSubObject.Add('Pin', "Entry/ExitPointL"."Post Code");


                    JObject.Add('DispDtls', JSubObject);
                end;
            end;

            Clear(JSubObject);
            JSubObject.Add('LglNm', LocationL.Name);
            JSubObject.Add('TrdNm', LocationL."Name 2");
            JSubObject.Add('Addr1', LocationL.Address);
            JSubObject.Add('Addr2', LocationL."Address 2");
            JSubObject.Add('Loc', LocationL.City);
            if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                GSTRegistrationo.get(LocationL."GST Registration No.");
                JSubObject.Add('Gstin', GSTRegistrationo."Einv Demo GST REgistration No.");
            end else begin
                if LocationL."GST Registration No." <> '' then
                    JSubObject.Add('Gstin', LocationL."GST Registration No.")
                else
                    JSubObject.Add('Gstin', CompanyInformationL."GST Registration No.");
            end;
            //    PostCodeL.SetRange(Code, LocationL."Post Code");
            //  if PostCodeL.FindFirst() then;
            JSubObject.Add('Pin', Format(copystr(LocationL."Post Code", 1, 6)));
            if StateL.Get(LocationL."State Code") then;
            JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");

            JObject.Add('BuyerDtls', JSubObject);
            Clear(JSubObject);
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
            JObject.Add('TotalInvoiceAmount', Round((GetTaxableAmountSalesCr(SalesCrMemoHdr."No.") +
                TCSEntry."Total TCS Including SHE CESS" + GetGSTAmount(SalesCrMemoHdr."No.", 'CGST') + GetGSTAmount(SalesCrMemoHdr."No.", 'SGST') +
                GetGSTAmount(SalesCrMemoHdr."No.", 'IGST') + GetGSTAmount(SalesCrMemoHdr."No.", 'CESS')) * LCYCurrency, 0.01, '='));
            JObject.Add('TotalAssessableAmount', Round(GetTaxableAmountSalesCr(SalesCrMemoHdr."No.") * LCYCurrency, 0.01, '='));
            JObject.Add('TotalCgstAmount', GetGSTAmount(SalesCrMemoHdr."No.", 'CGST'));
            JObject.Add('TotalSgstAmount', GetGSTAmount(SalesCrMemoHdr."No.", 'SGST'));
            JObject.Add('TotalIgstAmount', GetGSTAmount(SalesCrMemoHdr."No.", 'IGST'));
            JObject.Add('TotalCessAmount', GetGSTAmount(SalesCrMemoHdr."No.", 'CESS'));
            ShippingAgentL.Get(SalesCrMemoHdr."Shipping Agent Code");
            if ShippingAgentL."GST Registration No." > '' then
                JObject.Add('TransId', ShippingAgentL."GST Registration No.");
            JObject.Add('TransName', ShippingAgentL.Name);
            if SalesCrMemoHdr."Vehicle No." <> '' then begin
                SalesCrMemoHdr.TestField("Shipment Method code");
                SalesCrMemoHdr.TestField("Vehicle No.");
                SalesCrMemoHdr.TestField("LR/RR No.");
                SalesCrMemoHdr.TestField("LR/RR Date");
                TransportMethodL.Get(SalesCrMemoHdr."Shipment Method code");

                JObject.Add('Distance', 0);
                JObject.Add('TransDocNo', Format(SalesCrMemoHdr."LR/RR No."));
                JObject.Add('TransMode', Format(TransportMethodL.code));
                JObject.Add('TransDocDt', Format(SalesCrMemoHdr."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                JObject.Add('VehNo', DELCHR(SalesCrMemoHdr."Vehicle No.", '=', ' ,/-<>  !@#$%^&*()_+{}'));
                if SalesCrMemoHdr."Vehicle Type" = SalesCrMemoHdr."Vehicle Type"::Regular then
                    JObject.Add('VehType', 'R')
                else
                    if SalesCrMemoHdr."Vehicle Type" = SalesCrMemoHdr."Vehicle Type"::ODC then
                        JObject.Add('VehType', 'O')
                    else
                        JObject.Add('VehType', 'R');
            end;
            GetRoundingGLSales(CustomerL."Customer Posting Group", InvRoundingGL, PITRoungGL);
            SalesCrMemoLineL.setrange("document No.", SalesCrMemoHdr."No.");
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
                    JSubObject.Add('AssAmt', Round((SalesCrMemoLineL."Line Amount" - SalesCrMemoLineL."Line Discount Amount"), 0.01, '='));
                    JArrayL.Add(JSubObject);
                    clear(JSubObject);
                until SalesCrMemoLineL.Next() = 0;
            JObject.Add('ItemList', JArrayL);
            JObject.WriteTo(RequestText);
            docNo := SalesCrMemoHdr."No.";
            SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Creation", '', LocationL."GST Registration No.", false);

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
                    CreateLogEntry(SalesCrMemoHdr."No.", DocType::crMemo, SalesCrMemoHdr."Posting Date", RequestText, ResponseText,
                      EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                    EInvoiceEntryL."E-Way Generated" := true;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                    EInvoiceEntryL."LR/RR Date" := SalesCrMemoHdr."LR/RR Date";
                    EInvoiceEntryL."LR/RR No." := SalesCrMemoHdr."LR/RR No.";
                    EInvoiceEntryL."Transport Method" := SalesCrMemoHdr."Shipment Method code";
                    EInvoiceEntryL."Shipping Agent Code" := SalesCrMemoHdr."Shipping Agent Code";
                    SalesCrMemoHdr."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                    SalesCrMemoHdr."Vehicle Type" := SalesCrMemoHdr."Vehicle Type"::Regular;
                    SalesCrMemoHdr.Modify();
                    Message(EWayGenerated, SalesCrMemoHdr."No.");
                end else begin
                    CreateLogEntry(SalesCrMemoHdr."No.", DocType::crMemo, SalesCrMemoHdr."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;
                    EInvoiceEntryL."E-Way Generated" := false;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    //     Message(EWayFailed, SalesCrMemoHdr."No.");

                    if JSubObject.Contains('ErrorDetails') then begin
                        JSubObject.Get('ErrorDetails', JToken1L);
                        JSubArray := JToken1L.AsArray();
                        ErrorDetails := format(JSubArray);

                        //
                        for j := 0 to JSubArray.Count - 1 do begin
                            JSubArray.Get(j, JTokenL);
                            if j = 0 then begin

                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 1 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 1" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 2 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 2" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 3 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 3" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            EInvoiceEntryL.Modify();
                        end;
                    end;
                    Message(StrSubstNo(EWayFailed, SalesCrMemoHdr."No.") + '  Error As follow : ' + EInvoiceEntryL."Error Description" + ' ' + EInvoiceEntryL."Error Description 2");
                end;
                EInvoiceEntryL.Modify();
            end else
                Error(ResponseText);
        end;
    end;


    local procedure CreateJsonServiceInvoiceforIRN(ServiceInvHeaderP: Record "Service Invoice Header")
    var
        ServiceInvHeader: Record "Sales Invoice Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        TransportMethodL: Record "Shipment Method";
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
        DistanceRemark: text;
        Jarrtext: text;
        JSubObjectL: JsonObject;
        JToken1L: JsonToken;
        JSubArray: JsonArray;
        ErrorDetails: TEXT;
        J: Integer;
        JTokenL: JsonToken;
        JObjectL: JsonObject;
        PostCode: Record "Post Code";
    begin
        ServiceInvHeader.Copy(ServiceInvHeaderP);
        if LocationL.Get(ServiceInvHeader."Location Code") then;
        EInvoiceSetupL.Get();

        CheckEwayBillStatus(ServiceInvHeader."No.", DocType::"Service Invoice");
        if ShippingAgentL.Get(ServiceInvHeader."Shipping Agent Code") then;
        // LocationL.TestField("Post Code");
        CompanyInformationL.Get();
        JObject.Add('Irn', ServiceInvHeader."IRN Hash");

        if ServiceInvHeader."Distance (Km)" <> 0 then
            JObject.Add('Distance', ServiceInvHeader."Distance (Km)")
        else begin
            PostCode.reset;
            if ServiceInvHeader."Ship-to Code" <> '' then
                PostCode.SetRange(code, ServiceInvHeader."Ship-to Post Code")
            else
                PostCode.SetRange(code, ServiceInvHeader."Bill-to Post Code");
            //   PostCode.SetFilter("Distance (Km) From Location", '>%1', 0);

            // if PostCode.FindFirst() then begin
            //     JObject.Add('Distance', PostCode."Distance (Km) From Location");
            //     DistanceKM := PostCode."Distance (Km) From Location";

            // end
        end;
        JObject.Add('TransMode', Format(TransportMethodL.Code));
        if ShippingAgentL."GST Registration No." > '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");
        if ShippingAgentL.Name > '' then
            JObject.Add('TransName', ShippingAgentL.Name);
        if ServiceInvHeader."LR/RR Date" <> 0D then
            JObject.Add('TransDocDt', Format(ServiceInvHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        if ServiceInvHeader."LR/RR No." <> '' then
            JObject.Add('TransDocNo', ServiceInvHeader."LR/RR No.");
        if ServiceInvHeader."Vehicle No." <> '' then begin
            JObject.Add('VehNo', ServiceInvHeader."Vehicle No.");
        end;
        if ServiceInvHeader."Vehicle Type" = ServiceInvHeader."Vehicle Type"::Regular then
            JObject.Add('VehType', 'R')
        else
            if ServiceInvHeader."Vehicle Type" = ServiceInvHeader."Vehicle Type"::ODC then
                JObject.Add('VehType', 'O')
            else
                JObject.Add('VehType', 'R');




        if ServiceInvHeader."GST Customer Type" = ServiceInvHeader."GST Customer Type"::Export then begin
            JSubObject.Add('Addr1', ServiceInvHeader."Ship-to Address");
            JSubObject.Add('Addr2', ServiceInvHeader."Ship-to Address 2");
            JSubObject.Add('Loc', ServiceInvHeader."Ship-to City");
            JSubObject.Add('Pin', '999999');
            if ShiptoAddressL.Get(ServiceInvHeader."Sell-to Customer No.", ServiceInvHeader."Ship-to Code") then
                //   if ShipToAddressL.get(ServiceInvHeader."Bill-to Customer No.", ServiceInvHeader) then
                StateL.Get(ShiptoAddressL.State)
            else
                if NOT StateL.Get(ServiceInvHeader."GST Ship-to State Code") then
                    if not StateL.Get(ServiceInvHeader.State) then
                        JSubObject.Add('Stcd', '96')
                    else
                        JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");

            JObject.Add('ExpShipDtls', JSubObject);
        end;
        //Clear(JSubObject);
        // JSubObject.Add('Nm', LocationL.Name);
        // JSubObject.Add('Addr1', LocationL.Address);
        // JSubObject.Add('Addr2', LocationL."Address 2");
        //JSubObject.Add('Loc', LocationL.City);
        //JSubObject.Add('Pin', Format(LocationL."Post Code"));
        //StateL.Get(LocationL."State Code");
        //JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
        //JObject.Add('DispDtls', JSubObject);
        JArray.Add(JObject);
        JArray.WriteTo(RequestText);
        docNo := ServiceInvHeader."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL Eway By IRN", '', LocationL."GST Registration No.", false);

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

                    if JSubObject.Contains('info') then begin
                        JSubObject.Get('info', JToken1);
                        JToken1.WriteTo(Jarrtext);
                        if JArray.ReadFrom(Jarrtext) then begin

                            for I := 0 to JArray.Count - 1 do begin
                                JArray.Get(I, JToken);
                                JObject := JToken.AsObject();
                                DistanceRemark := GetValueFromJsonObject(JObject, 'Desc').AsText();

                            end;
                        end;
                    end;

                    CreateLogEntry(ServiceInvHeader."No.", DocType::"Service Invoice", ServiceInvHeader."Posting Date", RequestText, ResponseText,
                      EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                    EInvoiceEntryL."E-Way Generated" := true;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                    EInvoiceEntryL."LR/RR Date" := ServiceInvHeader."LR/RR Date";
                    EInvoiceEntryL."LR/RR No." := ServiceInvHeader."LR/RR No.";
                    EInvoiceEntryL."Transport Method" := ServiceInvHeader."Shipment Method code";
                    EInvoiceEntryL."Shipping Agent Code" := ServiceInvHeader."Shipping Agent Code";
                    EInvoiceEntryL."Distance Remark" := DistanceRemark;
                    if DistanceRemark > '' then
                        evaluate(EInvoiceEntryL."Transportation Distance", DelChr(DelChr(DistanceRemark, '=', 'Pin-Pin calc distance: '), '=', 'KM'));
                    ServiceInvHeader."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                    if ServiceInvHeader."Distance (Km)" = 0 then
                        ServiceInvHeader."Distance (Km)" := EInvoiceEntryL."Transportation Distance";

                    if (DistanceKM > 0) and (ServiceInvHeader."Distance (Km)" = 0) Then
                        ServiceInvHeader."Distance (Km)" := DistanceKM;

                    ServiceInvHeader.Modify();
                    Message(EWayGenerated, ServiceInvHeader."No.");

                end else begin
                    CreateLogEntry(ServiceInvHeader."No.", DocType::"Service Invoice", ServiceInvHeader."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;
                    EInvoiceEntryL."E-Way Generated" := false;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    //    Message(EWayFailed, ServiceInvHeader."No.");
                    if JSubObject.Contains('ErrorDetails') then begin
                        JSubObject.Get('ErrorDetails', JToken1L);
                        JSubArray := JToken1L.AsArray();
                        ErrorDetails := format(JSubArray);

                        //
                        for j := 0 to JSubArray.Count - 1 do begin
                            JSubArray.Get(j, JTokenL);
                            if j = 0 then begin

                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 1 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 1" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 2 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 2" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 3 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 3" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            EInvoiceEntryL.Modify();
                        end;
                    end;
                    Message(StrSubstNo(EWayFailed, ServiceInvHeader."No.") + '  Error As follow : ' + EInvoiceEntryL."Error Description" + ' ' + EInvoiceEntryL."Error Description 2");
                END;
                EInvoiceEntryL.Modify();
            end;
        end else
            Error(ResponseText);
    end;


    local procedure CreateJsonSalesInvoiceforIRN(SalesInvHeaderP: Record "Sales Invoice Header")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        TransportMethodL: Record "Shipment Method";
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
        DistanceRemark: text;
        Jarrtext: text;
        JSubObjectL: JsonObject;
        JToken1L: JsonToken;
        JSubArray: JsonArray;
        ErrorDetails: TEXT;
        J: Integer;
        JTokenL: JsonToken;
        JObjectL: JsonObject;
        PostCode: Record "Post Code";
    begin
        SalesInvHeader.Copy(SalesInvHeaderP);
        if LocationL.Get(SalesInvHeader."Location Code") then;
        EInvoiceSetupL.Get();
        // SalesInvHeader.TestField("Shipment Method code");
        // SalesInvHeader.TestField("Vehicle No.");
        // SalesInvHeader.TestField("LR/RR No.");
        // SalesInvHeader.TestField("LR/RR Date");
        //    if TransportMethodL.Get(SalesInvHeader."Shipment Method code") then;
        CheckEwayBillStatus(SalesInvHeader."No.", DocType::Invoice);
        ShippingAgentL.Get(SalesInvHeader."Shipping Agent Code");
        // LocationL.TestField("Post Code");
        CompanyInformationL.Get();
        JObject.Add('Irn', SalesInvHeader."IRN Hash");

        if SalesInvHeader."Distance (Km)" <> 0 then
            JObject.Add('Distance', SalesInvHeader."Distance (Km)")
        else begin
            PostCode.reset;
            if SalesInvHeader."Ship-to Code" <> '' then
                PostCode.SetRange(code, SalesInvHeader."Ship-to Post Code")
            else
                PostCode.SetRange(code, SalesInvHeader."Bill-to Post Code");
            // PostCode.SetFilter("Distance (Km) From Location", '>%1', 0);

            // if PostCode.FindFirst() then begin
            //     JObject.Add('Distance', PostCode."Distance (Km) From Location");
            //     DistanceKM := PostCode."Distance (Km) From Location";

            // end
        end;
        if TransportMethodL.get(SalesInvHeader."Shipment Method Code") then
            JObject.Add('TransMode', Format(TransportMethodL.code));
        if ShippingAgentL."GST Registration No." > '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");
        if ShippingAgentL.Name > '' then
            JObject.Add('TransName', ShippingAgentL.Name);
        if SalesInvHeader."LR/RR Date" <> 0D then
            JObject.Add('TransDocDt', Format(SalesInvHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        if SalesInvHeader."LR/RR No." <> '' then
            JObject.Add('TransDocNo', SalesInvHeader."LR/RR No.");
        if SalesInvHeader."Vehicle No." <> '' then begin
            JObject.Add('VehNo', SalesInvHeader."Vehicle No.");
            if SalesInvHeader."Vehicle Type" = SalesInvHeader."Vehicle Type"::Regular then
                JObject.Add('VehType', 'R')
            else
                if SalesInvHeader."Vehicle Type" = SalesInvHeader."Vehicle Type"::ODC then
                    JObject.Add('VehType', 'O')
                else
                    JObject.Add('VehType', 'R')
        end;



        if SalesInvHeader."GST Customer Type" = SalesInvHeader."GST Customer Type"::Export then begin

            EntryExit.Get(SalesInvHeader."Exit Point");
            JSubObject.Add('Addr1', EntryExit.Address);
            JSubObject.Add('Addr2', EntryExit."Address 2");
            JSubObject.Add('Loc', EntryExit.City);
            JSubObject.Add('Pin', EntryExit."Post Code");
            if StateL.Get(EntryExit."State Code") then;
            JSubObject.Add('Stcd', Format(StateL."State Code (GST Reg. No.)"));
            //JSubObject.Add('Pin', Format(EntryExit."Post Code"));




            JObject.Add('ExpShipDtls', JSubObject);
        end;
        JArray.Add(JObject);
        JArray.WriteTo(RequestText);
        docNo := SalesInvHeader."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL Eway By IRN", '', LocationL."GST Registration No.", false);

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

                    if JSubObject.Contains('info') then begin
                        JSubObject.Get('info', JToken1);
                        JToken1.WriteTo(Jarrtext);
                        if JArray.ReadFrom(Jarrtext) then begin

                            for I := 0 to JArray.Count - 1 do begin
                                JArray.Get(I, JToken);
                                JObject := JToken.AsObject();
                                DistanceRemark := GetValueFromJsonObject(JObject, 'Desc').AsText();

                            end;
                        end;
                    end;

                    CreateLogEntry(SalesInvHeader."No.", DocType::Invoice, SalesInvHeader."Posting Date", RequestText, ResponseText,
                      EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                    EInvoiceEntryL."E-Way Generated" := true;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                    EInvoiceEntryL."LR/RR Date" := SalesInvHeader."LR/RR Date";
                    EInvoiceEntryL."LR/RR No." := SalesInvHeader."LR/RR No.";
                    EInvoiceEntryL."Transport Method" := SalesInvHeader."Shipment Method code";
                    EInvoiceEntryL."Shipping Agent Code" := SalesInvHeader."Shipping Agent Code";
                    EInvoiceEntryL."Distance Remark" := DistanceRemark;
                    if DistanceRemark > '' then
                        evaluate(EInvoiceEntryL."Transportation Distance", DelChr(DelChr(DistanceRemark, '=', 'Pin-Pin calc distance: '), '=', 'KM'));
                    SalesInvHeader."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                    if SalesInvHeader."Distance (Km)" = 0 then
                        SalesInvHeader."Distance (Km)" := EInvoiceEntryL."Transportation Distance";

                    if (DistanceKM > 0) and (SalesInvHeader."Distance (Km)" = 0) Then
                        SalesInvHeader."Distance (Km)" := DistanceKM;

                    SalesInvHeader.Modify();
                    Message(EWayGenerated, SalesInvHeader."No.");

                end else begin
                    CreateLogEntry(SalesInvHeader."No.", DocType::invoice, SalesInvHeader."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;
                    EInvoiceEntryL."E-Way Generated" := false;
                    EInvoiceEntryL."E-Way Canceled" := false;

                    if JSubObject.Contains('ErrorDetails') then begin
                        JSubObject.Get('ErrorDetails', JToken1L);
                        JSubArray := JToken1L.AsArray();
                        ErrorDetails := format(JSubArray);

                        //
                        for j := 0 to JSubArray.Count - 1 do begin
                            JSubArray.Get(j, JTokenL);
                            if j = 0 then begin

                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 1 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 1" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 2 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 2" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 3 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 3" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            EInvoiceEntryL.Modify();
                        end;
                    end;
                    Message(StrSubstNo(EWayFailed, SalesInvHeader."No.") + ' \n Error As follow : \n' + EInvoiceEntryL."Error Description" + '\n' + EInvoiceEntryL."Error Description 2");

                END;
                EInvoiceEntryL.Modify();
            end;
        end else
            Error(ResponseText);
    end;



    local procedure CreateJsonSalesCrMemoforIRN(SalesCrMemoHdrP: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        TransportMethodL: Record "Shipment Method";
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
        if LocationL.Get(SalesCrMemoHdr."Location Code") then;
        EInvoiceSetupL.Get();

        if TransportMethodL.Get(SalesCrMemoHdr."Shipment Method code") then;
        CheckEwayBillStatus(SalesCrMemoHdr."No.", DocType::CrMemo);
        ShippingAgentL.Get(SalesCrMemoHdr."Shipping Agent Code");
        //LocationL.TestField("Post Code");
        CompanyInformationL.Get;
        JObject.Add('Irn', SalesCrMemoHdr."IRN Hash");
        if ShippingAgentL."GST Registration No." <> '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");
        if ShippingAgentL.Name <> '' then
            JObject.Add('TransName', ShippingAgentL.Name);
        if SalesCrMemoHdr."Vehicle No." <> '' then begin
            SalesCrMemoHdr.TestField("Shipment Method code");
            SalesCrMemoHdr.TestField("Vehicle No.");
            SalesCrMemoHdr.TestField("LR/RR No.");
            SalesCrMemoHdr.TestField("LR/RR Date");
            JObject.Add('TransMode', Format(TransportMethodL.code));
            JObject.Add('TransDocDt', Format(SalesCrMemoHdr."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
            JObject.Add('TransDocNo', SalesCrMemoHdr."LR/RR No.");
            JObject.Add('VehNo', SalesCrMemoHdr."Vehicle No.");
            if SalesCrMemoHdr."Vehicle Type" = SalesCrMemoHdr."Vehicle Type"::Regular then
                JObject.Add('VehType', 'R')
            else
                if SalesCrMemoHdr."Vehicle Type" = SalesCrMemoHdr."Vehicle Type"::ODC then
                    JObject.Add('VehType', 'O')
                else
                    JObject.Add('VehType', 'R');
            if SalesCrMemoHdr."Distance (Km)" <> 0 then
                JObject.Add('Distance', SalesCrMemoHdr."Distance (Km)");
        end;

        if SalesCrMemoHdr."GST Customer Type" = SalesCrMemoHdr."GST Customer Type"::Export then begin
            JSubObject.Add('Addr1', SalesCrMemoHdr."Ship-to Address");
            JSubObject.Add('Addr2', SalesCrMemoHdr."Ship-to Address 2");
            JSubObject.Add('Loc', SalesCrMemoHdr."Ship-to City");
            JSubObject.Add('Pin', Format(SalesCrMemoHdr."Ship-to Post Code"));
            if ShiptoAddressL.Get(SalesCrMemoHdr."Sell-to Customer No.", SalesCrMemoHdr."Ship-to Code") then
                // if ShipToAddressL.get(SalesCrMemoHdr."Ship-To Address Code", SalesCrMemoHdr."Ship-To Address Name") then
                StateL.Get(ShiptoAddressL.State)
            else
                if NOT StateL.Get(SalesCrMemoHdr."GST Ship-to State Code") then
                    StateL.Get(SalesCrMemoHdr.State);
            JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
            JObject.Add('ExpShipDtls', JSubObject);
        end;
        // Clear(JSubObject);
        // JSubObject.Add('Nm', LocationL.Name);
        // JSubObject.Add('Addr1', LocationL.Address);
        // JSubObject.Add('Addr2', LocationL."Address 2");
        // JSubObject.Add('Loc', LocationL.City);
        // JSubObject.Add('Pin', Format(LocationL."Post Code"));
        // StateL.Get(LocationL."State Code");
        // JSubObject.Add('Stcd', StateL."State Code (GST Reg. No.)");
        // JObject.Add('DispDtls', JSubObject);
        JArray.Add(JObject);
        JArray.WriteTo(RequestText);
        docNo := SalesCrMemoHdr."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL Eway By IRN", '', LocationL."GST Registration No.", false);

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
                    CreateLogEntry(SalesCrMemoHdr."No.", DocType::crMemo, SalesCrMemoHdr."Posting Date", RequestText, ResponseText,
                      EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                    EInvoiceEntryL."E-Way Generated" := true;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                    EInvoiceEntryL."LR/RR Date" := SalesCrMemoHdr."LR/RR Date";
                    EInvoiceEntryL."LR/RR No." := SalesCrMemoHdr."LR/RR No.";
                    EInvoiceEntryL."Transport Method" := SalesCrMemoHdr."Shipment Method code";
                    EInvoiceEntryL."Shipping Agent Code" := SalesCrMemoHdr."Shipping Agent Code";
                    SalesCrMemoHdr."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                    SalesCrMemoHdr.Modify();
                    Message(EWayGenerated, SalesCrMemoHdr."No.");
                end else begin
                    CreateLogEntry(SalesCrMemoHdr."No.", DocType::crMemo, SalesCrMemoHdr."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;
                    EInvoiceEntryL."E-Way Generated" := false;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    //   Message(EWayFailed, SalesCrMemoHdr."No.");
                    if JSubObject.Contains('ErrorDetails') then begin
                        JSubObject.Get('ErrorDetails', JToken1L);
                        JSubArray := JToken1L.AsArray();
                        ErrorDetails := format(JSubArray);

                        //
                        for j := 0 to JSubArray.Count - 1 do begin
                            JSubArray.Get(j, JTokenL);
                            if j = 0 then begin

                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 1 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 1" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 2 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 2" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 3 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 3" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            EInvoiceEntryL.Modify();
                        end;
                    end;
                    Message(StrSubstNo(EWayFailed, SalesCrMemoHdr."No.") + '  Error As follow : ' + EInvoiceEntryL."Error Description" + ' ' + EInvoiceEntryL."Error Description 2");
                end;
                EInvoiceEntryL.Modify();
            end;
        end else
            Error(ResponseText);
    end;




    local procedure UpdateVehicleNoPurchaseInv(var EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        PurchCrMemoHdr: Record "Purch. Inv. Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TransportMethodL: Record "Shipment Method";
        StateL: Record State;
        ShippingAgentL: Record "Shipping Agent";
        ResponseText: Text;
        RequestText: Text;
    begin
        PurchCrMemoHdr.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(PurchCrMemoHdr."Location Code");
        EInvoiceSetupL.Get;

        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", doctype::"Purch. Inv. Hdr");
        EInvoiceEntryL.SetRange("Document No.", PurchCrMemoHdr."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("New Vehicle No.");
        EInvoiceEntryL.TestField("Vehicle No. Update Remark");
        PurchCrMemoHdr.TestField("Shipping Agent Code");
        EInvoiceEntryL.TestField("LR/RR No.");
        EInvoiceEntryL.TestField("LR/RR Date");

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("New Vehicle No.");
        EInvoiceEntryL.TestField("Vehicle No. Update Remark");
        TransportMethodL.Get(PurchCrMemoHdr."Shipment Method code");
        JObject.Add('EwbNumber', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('VehNo', DELCHR(EInvoiceEntryL."New Vehicle No.", '=', ' /\.<>-!@#$%^&*()_+'));
        JObject.Add('VehicleType', 'REGULAR');
        JObject.Add('FromPlace', LocationL.City);
        if StateL.Get(LocationL."State Code") then
            JObject.Add('FromState', StateL."State Code (GST Reg. No.)");
        if EInvoiceEntryL."New Pin Code From" > '' then
            JObject.Add('FromPincode', EInvoiceEntryL."New Pin Code From");

        if EInvoiceEntryL."Vehicle No. Update Remark" IN
          [EInvoiceEntryL."Vehicle No. Update Remark"::OTHERS] then
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
        JObject.Add('TransMode', Format(TransportMethodL.code));
        JObject.Add('DocumentNumber', EInvoiceEntryL."Document No.");
        JObject.Add('DocumentType', 'INV');
        JObject.Add('DocumentDate', Format(EInvoiceEntryL."Document Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.WriteTo(RequestText);
        docNo := PurchCrMemoHdr."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Update", '', LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin
                if JObject.Contains('ValidUpto') then
                    EInvoiceEntryP."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                EInvoiceEntryP.Modify();
                PurchCrMemoHdr."Vehicle No." := EInvoiceEntryL."New Vehicle No.";
                PurchCrMemoHdr."Vehicle Type" := PurchCrMemoHdr."Vehicle Type"::Regular;
                PurchCrMemoHdr."Shipment Method code" := EInvoiceEntryL."Transport Method";
                PurchCrMemoHdr."Shipping Agent Code" := EInvoiceEntryL."Shipping Agent Code";
                PurchCrMemoHdr."LR/RR Date" := EInvoiceEntryL."LR/RR Date";
                PurchCrMemoHdr."LR/RR No." := EInvoiceEntryL."LR/RR No.";
                PurchCrMemoHdr.Modify();
                Message(VehicleUpdated, PurchCrMemoHdr."No.");
            end else
                Error(ResponseText);
    end;

    local procedure UpdateVehicleNoPurchaseCrMemo(var EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TransportMethodL: Record "Shipment Method";
        StateL: Record State;
        ShippingAgentL: Record "Shipping Agent";
        ResponseText: Text;
        RequestText: Text;
    begin
        PurchCrMemoHdr.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(PurchCrMemoHdr."Location Code");
        EInvoiceSetupL.Get;

        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", doctype::"Purch Cr. Memo Hdr");
        EInvoiceEntryL.SetRange("Document No.", PurchCrMemoHdr."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("New Vehicle No.");
        EInvoiceEntryL.TestField("Vehicle No. Update Remark");
        PurchCrMemoHdr.TestField("Shipping Agent Code");
        EInvoiceEntryL.TestField("LR/RR No.");
        EInvoiceEntryL.TestField("LR/RR Date");

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("New Vehicle No.");
        EInvoiceEntryL.TestField("Vehicle No. Update Remark");
        TransportMethodL.Get(PurchCrMemoHdr."Shipment Method code");
        JObject.Add('EwbNumber', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('VehNo', DELCHR(EInvoiceEntryL."New Vehicle No.", '=', ' /\.<>-!@#$%^&*()_+'));
        JObject.Add('VehicleType', 'REGULAR');
        JObject.Add('FromPlace', LocationL.City);
        if StateL.Get(LocationL."State Code") then
            JObject.Add('FromState', StateL."State Code (GST Reg. No.)");
        if EInvoiceEntryL."New Pin Code From" > '' then
            JObject.Add('FromPincode', EInvoiceEntryL."New Pin Code From");

        if EInvoiceEntryL."Vehicle No. Update Remark" IN
          [EInvoiceEntryL."Vehicle No. Update Remark"::OTHERS] then
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
        JObject.Add('TransMode', Format(TransportMethodL.code));
        JObject.Add('DocumentNumber', EInvoiceEntryL."Document No.");
        JObject.Add('DocumentType', 'INV');
        JObject.Add('DocumentDate', Format(EInvoiceEntryL."Document Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.WriteTo(RequestText);
        docNo := PurchCrMemoHdr."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Update", '', LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin
                if JObject.Contains('ValidUpto') then
                    EInvoiceEntryP."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                EInvoiceEntryP.Modify();
                PurchCrMemoHdr."Vehicle No." := EInvoiceEntryL."New Vehicle No.";
                PurchCrMemoHdr."Vehicle Type" := PurchCrMemoHdr."Vehicle Type"::Regular;
                PurchCrMemoHdr."Shipment Method code" := EInvoiceEntryL."Transport Method";
                PurchCrMemoHdr."Shipping Agent Code" := EInvoiceEntryL."Shipping Agent Code";
                PurchCrMemoHdr."LR/RR Date" := EInvoiceEntryL."LR/RR Date";
                PurchCrMemoHdr."LR/RR No." := EInvoiceEntryL."LR/RR No.";
                PurchCrMemoHdr.Modify();
                Message(VehicleUpdated, PurchCrMemoHdr."No.");
            end else
                Error(ResponseText);
    end;


    local procedure UpdateVehicleNoSalesCrMemo(var EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        SalesCrMemo: Record "Sales Cr.Memo Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TransportMethodL: Record "Shipment Method";
        StateL: Record State;
        ShippingAgentL: Record "Shipping Agent";
        ResponseText: Text;
        RequestText: Text;
    begin
        SalesCrMemo.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(SalesCrMemo."Location Code");
        EInvoiceSetupL.Get;

        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::CrMemo);
        EInvoiceEntryL.SetRange("Document No.", SalesCrMemo."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("New Vehicle No.");
        EInvoiceEntryL.TestField("Vehicle No. Update Remark");
        SalesCrMemo.TestField("Shipping Agent Code");
        EInvoiceEntryL.TestField("LR/RR No.");
        EInvoiceEntryL.TestField("LR/RR Date");

        if TransportMethodL.Get(EInvoiceEntryL."Transport Method") then;
        JObject.Add('EwbNumber', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('VehNo', DELCHR(EInvoiceEntryL."New Vehicle No.", '=', ' /\.<>-!@#$%^&*()_+'));
        if SalesCrMemo."Vehicle Type" = SalesCrMemo."Vehicle Type"::Regular then
            JObject.Add('VehType', 'R')
        else
            if SalesCrMemo."Vehicle Type" = SalesCrMemo."Vehicle Type"::ODC then
                JObject.Add('VehType', 'O')
            else
                JObject.Add('VehType', 'R');

        JObject.Add('FromPlace', LocationL.City);
        if StateL.Get(LocationL."State Code") then
            JObject.Add('FromState', StateL."State Code (GST Reg. No.)");
        if EInvoiceEntryL."New Pin Code From" <> '' then
            JObject.Add('FromPincode', EInvoiceEntryL."New Pin Code From");

        if EInvoiceEntryL."Vehicle No. Update Remark" IN
          [EInvoiceEntryL."Vehicle No. Update Remark"::OTHERS] then
            JObject.Add('ReasonCode', 'OTHERS')
        else
            JObject.Add('ReasonCode', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        JObject.Add('ReasonRemark', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        ShippingAgentL.Get(SalesCrMemo."Shipping Agent Code");
        if ShippingAgentL."GST Registration No." <> '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");



        //ShippingAgentL.Name);
        JObject.Add('TransName', ShippingAgentL.Name);
        JObject.Add('TransDocNo', EInvoiceEntryL."LR/RR No.");
        JObject.Add('TransDocDt', Format(EInvoiceEntryL."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.Add('TransMode', Format(TransportMethodL.code));
        JObject.WriteTo(RequestText);
        docNo := SalesCrMemo."No.";

        //RRA
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Update", '', LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin
                if JObject.Contains('ValidUpto') then
                    EInvoiceEntryP."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                EInvoiceEntryP.Modify();
                SalesCrMemo."Vehicle No." := EInvoiceEntryL."New Vehicle No.";
                //  SalesCrMemo."Vehicle Type" := SalesCrMemo."Vehicle Type"::Regular;
                SalesCrMemo."Shipment Method code" := EInvoiceEntryL."Transport Method";
                SalesCrMemo."Shipping Agent Code" := EInvoiceEntryL."Shipping Agent Code";
                //SalesCrMemo."e-Invoice LR/RR Date" := EInvoiceEntryL."LR/RR Date";
                //SalesCrMemo."e-Invoice LR/RR No." := EInvoiceEntryL."LR/RR No.";
                SalesCrMemo.Modify();
                Message(VehicleUpdated, SalesCrMemo."No.");
            end else
                Error(ResponseText);
    end;


    local procedure UpdateVehicleNoServiceInvoice(var EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        SalesInvHeader: Record "Service Invoice Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TransportMethodL: Record "Shipment Method";
        StateL: Record State;
        ShippingAgentL: Record "Shipping Agent";
        ResponseText: Text;
        RequestText: Text;
    begin
        SalesInvHeader.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(SalesInvHeader."Location Code");
        EInvoiceSetupL.Get;

        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Service Invoice");
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("New Vehicle No.");
        EInvoiceEntryL.TestField("Vehicle No. Update Remark");
        SalesInvHeader.TestField("Shipping Agent Code");
        EInvoiceEntryL.TestField("LR/RR No.");
        EInvoiceEntryL.TestField("LR/RR Date");

        if not TransportMethodL.Get(EInvoiceEntryL."Transport Method") then begin
            // TransportMethodL.Get(SalesInvHeader.);
            // einvoiceEntryL."Transport Method" := SalesInvHeader."Shipment Method";

        end;
        JObject.Add('EwbNumber', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('VehNo', DELCHR(EInvoiceEntryL."New Vehicle No.", '=', ' /\.<>-!@#$%^&*()_+'));
        // if SalesInvHeader."Vehicle Type" = SalesInvHeader."Vehicle Type"::Regular then
        //     JObject.Add('VehType', 'R')
        // else
        //     if SalesInvHeader."Vehicle Type" = SalesInvHeader."Vehicle Type"::ODC then
        //         JObject.Add('VehType', 'O')
        //     else
        //         JObject.Add('VehType', 'R');

        JObject.Add('FromPlace', LocationL.City);
        if StateL.Get(LocationL."State Code") then
            JObject.Add('FromState', StateL."State Code (GST Reg. No.)");
        if EInvoiceEntryL."New Pin Code From" <> '' then
            JObject.Add('FromPincode', EInvoiceEntryL."New Pin Code From");

        if EInvoiceEntryL."Vehicle No. Update Remark" IN
          [EInvoiceEntryL."Vehicle No. Update Remark"::OTHERS] then
            JObject.Add('ReasonCode', 'OTHERS')
        else
            JObject.Add('ReasonCode', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        JObject.Add('ReasonRemark', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        ShippingAgentL.Get(SalesInvHeader."Shipping Agent Code");
        if ShippingAgentL."GST Registration No." <> '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");



        //ShippingAgentL.Name);
        JObject.Add('TransName', ShippingAgentL.Name);
        JObject.Add('TransDocNo', EInvoiceEntryL."LR/RR No.");
        JObject.Add('TransDocDt', Format(EInvoiceEntryL."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.Add('TransMode', Format(TransportMethodL.code));
        JObject.WriteTo(RequestText);
        docNo := SalesInvHeader."No.";

        //RRA
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Update", '', LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin
                if JObject.Contains('ValidUpto') then
                    EInvoiceEntryP."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                EInvoiceEntryP.Modify();
                SalesInvHeader."Vehicle No." := EInvoiceEntryL."New Vehicle No.";
                //SalesInvHeader."Vehicle Type" := SalesInvHeader."Vehicle Type"::Regular;
                SalesInvHeader."Shipment Method code" := EInvoiceEntryL."Transport Method";
                SalesInvHeader."Shipping Agent Code" := EInvoiceEntryL."Shipping Agent Code";
                //SalesInvHeader."e-Invoice LR/RR Date" := EInvoiceEntryL."LR/RR Date";
                //SalesInvHeader."e-Invoice LR/RR No." := EInvoiceEntryL."LR/RR No.";
                SalesInvHeader.Modify();
                Message(VehicleUpdated, SalesInvHeader."No.");
            end else
                Error(ResponseText);
    end;

    local procedure UpdateVehicleNoSalesInvoice(var EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TransportMethodL: Record "Shipment Method";
        StateL: Record State;
        ShippingAgentL: Record "Shipping Agent";
        ResponseText: Text;
        RequestText: Text;
    begin
        SalesInvHeader.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(SalesInvHeader."Location Code");
        EInvoiceSetupL.Get;

        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::Invoice);
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("New Vehicle No.");
        EInvoiceEntryL.TestField("Vehicle No. Update Remark");
        SalesInvHeader.TestField("Shipping Agent Code");
        EInvoiceEntryL.TestField("LR/RR No.");
        EInvoiceEntryL.TestField("LR/RR Date");

        if not TransportMethodL.Get(EInvoiceEntryL."Transport Method") then begin
            TransportMethodL.Get(SalesInvHeader."Shipment Method Code");
            EInvoiceEntryL."Transport Method" := SalesInvHeader."Shipment Method Code";
        end;
        JObject.Add('EwbNumber', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('VehNo', DELCHR(EInvoiceEntryL."New Vehicle No.", '=', ' /\.<>-!@#$%^&*()_+'));
        if SalesInvHeader."Vehicle Type" = SalesInvHeader."Vehicle Type"::Regular then
            JObject.Add('VehType', 'R')
        else
            if SalesInvHeader."Vehicle Type" = SalesInvHeader."Vehicle Type"::ODC then
                JObject.Add('VehType', 'O')
            else
                JObject.Add('VehType', 'R');

        JObject.Add('FromPlace', LocationL.City);
        if StateL.Get(LocationL."State Code") then
            JObject.Add('FromState', StateL."State Code (GST Reg. No.)");
        if EInvoiceEntryL."New Pin Code From" <> '' then
            JObject.Add('FromPincode', EInvoiceEntryL."New Pin Code From");

        if EInvoiceEntryL."Vehicle No. Update Remark" IN
          [EInvoiceEntryL."Vehicle No. Update Remark"::OTHERS] then
            JObject.Add('ReasonCode', 'OTHERS')
        else
            JObject.Add('ReasonCode', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        JObject.Add('ReasonRemark', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        ShippingAgentL.Get(SalesInvHeader."Shipping Agent Code");
        if ShippingAgentL."GST Registration No." <> '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");



        //ShippingAgentL.Name);
        JObject.Add('TransName', ShippingAgentL.Name);
        JObject.Add('TransDocNo', EInvoiceEntryL."LR/RR No.");
        JObject.Add('TransDocDt', Format(EInvoiceEntryL."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.Add('TransMode', Format(TransportMethodL.code));
        JObject.WriteTo(RequestText);
        docNo := SalesInvHeader."No.";

        //RRA
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Update", '', LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin


                if JObject.Contains('ValidUpto') then
                    EInvoiceEntryP."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                EInvoiceEntryP.Modify();

                SalesInvHeader."Vehicle No." := EInvoiceEntryL."New Vehicle No.";
                SalesInvHeader."Vehicle Type" := SalesInvHeader."Vehicle Type"::Regular;
                SalesInvHeader."Shipment Method code" := EInvoiceEntryL."Transport Method";
                SalesInvHeader."Shipping Agent Code" := EInvoiceEntryL."Shipping Agent Code";
                //SalesInvHeader."e-Invoice LR/RR Date" := EInvoiceEntryL."LR/RR Date";
                //SalesInvHeader."e-Invoice LR/RR No." := EInvoiceEntryL."LR/RR No.";
                SalesInvHeader.Modify();
                Message(VehicleUpdated, SalesInvHeader."No.");
            end else
                Error(ResponseText);
    end;

    local procedure UpdateVehicleNoSalesShipment(var EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        SalesInvHeader: Record "Sales Shipment Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TransportMethodL: Record "Shipment Method";
        StateL: Record State;
        ShippingAgentL: Record "Shipping Agent";
        ResponseText: Text;
        RequestText: Text;
    begin
        SalesInvHeader.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(SalesInvHeader."Location Code");
        EInvoiceSetupL.Get;

        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Sales Shipment");
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("New Vehicle No.");
        EInvoiceEntryL.TestField("Vehicle No. Update Remark");
        SalesInvHeader.TestField("Shipping Agent Code");
        EInvoiceEntryL.TestField("LR/RR No.");
        EInvoiceEntryL.TestField("LR/RR Date");

        TransportMethodL.Get(EInvoiceEntryL."Transport Method");
        JObject.Add('EwbNumber', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('VehNo', DELCHR(EInvoiceEntryL."New Vehicle No.", '=', ' /\.<>-!@#$%^&*()_+'));
        if SalesInvHeader."Vehicle Type" = SalesInvHeader."Vehicle Type"::Regular then
            JObject.Add('VehType', 'R')
        else
            if SalesInvHeader."Vehicle Type" = SalesInvHeader."Vehicle Type"::ODC then
                JObject.Add('VehType', 'O')
            else
                JObject.Add('VehType', 'R');

        JObject.Add('FromPlace', LocationL.City);
        if StateL.Get(LocationL."State Code") then
            JObject.Add('FromState', StateL."State Code (GST Reg. No.)");
        if EInvoiceEntryL."New Pin Code From" <> '' then
            JObject.Add('FromPincode', EInvoiceEntryL."New Pin Code From");

        if EInvoiceEntryL."Vehicle No. Update Remark" IN
          [EInvoiceEntryL."Vehicle No. Update Remark"::OTHERS] then
            JObject.Add('ReasonCode', 'OTHERS')
        else
            JObject.Add('ReasonCode', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        JObject.Add('ReasonRemark', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        ShippingAgentL.Get(SalesInvHeader."Shipping Agent Code");
        if ShippingAgentL."GST Registration No." <> '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");



        //ShippingAgentL.Name);
        JObject.Add('TransName', ShippingAgentL.Name);
        JObject.Add('TransDocNo', EInvoiceEntryL."LR/RR No.");
        JObject.Add('TransDocDt', Format(EInvoiceEntryL."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.Add('TransMode', Format(TransportMethodL.code));
        JObject.WriteTo(RequestText);
        docNo := SalesInvHeader."No.";

        //RRA
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Update", '', LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin
                EInvoiceEntryL.findfirst;
                if JObject.Contains('ValidUpto') then
                    EInvoiceEntryP."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                EInvoiceEntryP.Modify();
                SalesInvHeader."Vehicle No." := EInvoiceEntryL."New Vehicle No.";
                SalesInvHeader."Vehicle Type" := SalesInvHeader."Vehicle Type"::Regular;
                SalesInvHeader."Shipment Method code" := EInvoiceEntryL."Transport Method";
                SalesInvHeader."Shipping Agent Code" := EInvoiceEntryL."Shipping Agent Code";
                //SalesInvHeader."e-Invoice LR/RR Date" := EInvoiceEntryL."LR/RR Date";
                //SalesInvHeader."e-Invoice LR/RR No." := EInvoiceEntryL."LR/RR No.";
                SalesInvHeader.Modify();
                Message(VehicleUpdated, SalesInvHeader."No.");
            end else
                Error(ResponseText);
    end;



    local procedure UpdateVehicleNoServiceShipment(var EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        SalesInvHeader: Record "Service Shipment Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TransportMethodL: Record "Shipment Method";
        StateL: Record State;
        ShippingAgentL: Record "Shipping Agent";
        ResponseText: Text;
        RequestText: Text;
    begin
        SalesInvHeader.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(SalesInvHeader."Location Code");
        EInvoiceSetupL.Get;

        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Service Shipment");
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("New Vehicle No.");
        EInvoiceEntryL.TestField("Vehicle No. Update Remark");
        SalesInvHeader.TestField("Shipping Agent Code");
        EInvoiceEntryL.TestField("LR/RR No.");
        EInvoiceEntryL.TestField("LR/RR Date");

        TransportMethodL.Get(EInvoiceEntryL."Transport Method");
        JObject.Add('EwbNumber', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('VehNo', DELCHR(EInvoiceEntryL."New Vehicle No.", '=', ' /\.<>-!@#$%^&*()_+'));
        // if SalesInvHeader."Vehicle Type" = SalesInvHeader."Vehicle Type"::Regular then
        //     JObject.Add('VehType', 'R')
        // else
        //     if SalesInvHeader."Vehicle Type" = SalesInvHeader."Vehicle Type"::ODC then
        //         JObject.Add('VehType', 'O')
        //     else
        //         JObject.Add('VehType', 'R');

        JObject.Add('FromPlace', LocationL.City);
        if StateL.Get(LocationL."State Code") then
            JObject.Add('FromState', StateL."State Code (GST Reg. No.)");
        if EInvoiceEntryL."New Pin Code From" <> '' then
            JObject.Add('FromPincode', EInvoiceEntryL."New Pin Code From");

        if EInvoiceEntryL."Vehicle No. Update Remark" IN
          [EInvoiceEntryL."Vehicle No. Update Remark"::OTHERS] then
            JObject.Add('ReasonCode', 'OTHERS')
        else
            JObject.Add('ReasonCode', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        JObject.Add('ReasonRemark', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        ShippingAgentL.Get(SalesInvHeader."Shipping Agent Code");
        if ShippingAgentL."GST Registration No." <> '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");



        //ShippingAgentL.Name);
        JObject.Add('TransName', ShippingAgentL.Name);
        JObject.Add('TransDocNo', EInvoiceEntryL."LR/RR No.");
        JObject.Add('TransDocDt', Format(EInvoiceEntryL."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.Add('TransMode', Format(TransportMethodL.code));
        JObject.WriteTo(RequestText);
        docNo := SalesInvHeader."No.";

        //RRA
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Update", '', LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin
                if JObject.Contains('ValidUpto') then
                    EInvoiceEntryP."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                EInvoiceEntryP.Modify();
                SalesInvHeader."Vehicle No." := EInvoiceEntryL."New Vehicle No.";
                //  SalesInvHeader."Vehicle Type" := SalesInvHeader."Vehicle Type"::Regular;
                SalesInvHeader."Shipment Method code" := EInvoiceEntryL."Transport Method";
                SalesInvHeader."Shipping Agent Code" := EInvoiceEntryL."Shipping Agent Code";
                //SalesInvHeader."e-Invoice LR/RR Date" := EInvoiceEntryL."LR/RR Date";
                //SalesInvHeader."e-Invoice LR/RR No." := EInvoiceEntryL."LR/RR No.";
                SalesInvHeader.Modify();
                Message(VehicleUpdated, SalesInvHeader."No.");
            end else
                Error(ResponseText);
    end;

    local procedure UpdateVehicleNoServInvoice(var EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        ServiceInvHeader: Record "Service Invoice Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TransportMethodL: Record "Shipment Method";
        StateL: Record State;
        ShippingAgentL: Record "Shipping Agent";
        ResponseText: Text;
        RequestText: Text;
    begin
        ServiceInvHeader.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(ServiceInvHeader."Location Code");
        EInvoiceSetupL.Get;

        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Service Invoice");
        EInvoiceEntryL.SetRange("Document No.", ServiceInvHeader."No.");
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
          [EInvoiceEntryL."Vehicle No. Update Remark"::OTHERS] then
            JObject.Add('ReasonCode', 'OTHERS')
        else
            JObject.Add('ReasonCode', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        JObject.Add('ReasonRemark', Format(EInvoiceEntryL."Vehicle No. Update Remark"));
        ShippingAgentL.Get(ServiceInvHeader."Shipping Agent Code");
        if ShippingAgentL."GST Registration No." <> '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");
        JObject.Add('TransName', ShippingAgentL.Name);
        JObject.Add('TransDocNo', EInvoiceEntryL."LR/RR No.");
        JObject.Add('TransDocDt', Format(EInvoiceEntryL."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.Add('TransMode', Format(TransportMethodL.code));
        JObject.WriteTo(RequestText);
        docNo := ServiceInvHeader."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Update", '', LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin
                if JObject.Contains('ValidUpto') then
                    EInvoiceEntryP."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                EInvoiceEntryP.Modify();
                ServiceInvHeader."Vehicle No." := EInvoiceEntryL."New Vehicle No.";
                //    ServiceInvHeader."Vehicle Type" := ServiceInvHeader."Vehicle Type"::Regular;
                ServiceInvHeader."Shipment Method code" := EInvoiceEntryL."Transport Method";
                ServiceInvHeader."Shipping Agent Code" := EInvoiceEntryL."Shipping Agent Code";
                ServiceInvHeader."LR/RR Date" := EInvoiceEntryL."LR/RR Date";
                ServiceInvHeader."LR/RR No." := EInvoiceEntryL."LR/RR No.";
                ServiceInvHeader.Modify();
                Message(VehicleUpdated, ServiceInvHeader."No.");
            end else
                Error(ResponseText);
    end;

    local procedure UpdateVehicleNoTransferShipment(var EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        TransShipHdr: Record "Transfer Shipment Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        TransportMethodL: Record "Shipment Method";
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
        TransShipHdr.TestField("Shipping Agent Code");
        EInvoiceEntryL.TestField("LR/RR No.");
        EInvoiceEntryL.TestField("LR/RR Date");

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("New Vehicle No.");
        EInvoiceEntryL.TestField("Vehicle No. Update Remark");
        TransportMethodL.Get(TransShipHdr."Shipment Method code");
        JObject.Add('EwbNumber', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('VehNo', DELCHR(EInvoiceEntryL."New Vehicle No.", '=', ' /\.<>-!@#$%^&*()_+'));
        JObject.Add('VehicleType', 'REGULAR');
        JObject.Add('FromPlace', LocationL.City);
        if StateL.Get(LocationL."State Code") then begin


            JObject.Add('FromState', StateL."State Code (GST Reg. No.)");
        end;

        if EInvoiceEntryL."New Pin Code From" <> '' then
            JObject.Add('FromPincode', EInvoiceEntryL."New Pin Code From");

        if EInvoiceEntryL."Vehicle No. Update Remark" IN
          [EInvoiceEntryL."Vehicle No. Update Remark"::OTHERS] then
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
        JObject.Add('TransMode', Format(TransportMethodL.code));
        JObject.Add('DocumentNumber', EInvoiceEntryL."Document No.");
        JObject.Add('DocumentType', 'INV');
        JObject.Add('DocumentDate', Format(EInvoiceEntryL."Document Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.WriteTo(RequestText);
        docNo := TransShipHdr."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Update", '', LocationL."GST Registration No.", false);

        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin
                if JObject.Contains('ValidUpto') then
                    EInvoiceEntryP."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                EInvoiceEntryP.Modify();
                TransShipHdr."Vehicle No." := EInvoiceEntryL."New Vehicle No.";
                TransShipHdr."Vehicle Type" := TransShipHdr."Vehicle Type"::Regular;
                TransShipHdr."Shipment Method code" := EInvoiceEntryL."Transport Method";
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
        docNo := TransShipmentHdr."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Cancelation", '', LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'ewbStatus').AsText() = 'CANCELLED') then begin
                Clear(EInvoiceEntryL."E-Way Bill No.");
                Clear(EInvoiceEntryL."E-Way Bill Date");
                Clear(EInvoiceEntryL."E-Way Bill Validity");
                Clear(EInvoiceEntryL."E-Way Generated");
                Clear(EInvoiceEntryL."New Vehicle No.");
                EInvoiceEntryL."E-Way Canceled" := true;
                EInvoiceEntryL."Vehicle No. Update Remark" := EInvoiceEntryL."Vehicle No. Update Remark"::" ";
                EInvoiceEntryL."E-Way Canceled Date" := Format(CURRENTDATETIME);
                EInvoiceEntryL."Cancelled By" := UserId;

                DeleteMultivehicleData(EInvoiceEntryL);
                EInvoiceEntryL.Modify();
                Message(EWayCancelled, TransShipmentHdr."No.");
            end else
                Error(ResponseText);
    end;


    local procedure CancelEWayServiceInvoice(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        ServiceInvHeader: Record "Service Invoice Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        EWayBillNo: Text;
        RequestText: Text;
    begin
        ServiceInvHeader.Get(EInvoiceEntryP."Document No.");
        LocationL.Get(ServiceInvHeader."Location Code");
        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Service Invoice");
        EInvoiceEntryL.SetRange("Document No.", ServiceInvHeader."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("Reason of Cancel");
        JObject.Add('ewbNo', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('cancelRsnCode', Format(EInvoiceEntryL."Reason of Cancel"));
        JObject.Add('cancelRmrk', 'Cancelled the order');
        JObject.WriteTo(RequestText);
        docNo := ServiceInvHeader."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Cancelation", '', LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'ewbStatus').AsText() = 'CANCELLED') then begin
                Clear(EInvoiceEntryL."E-Way Bill No.");
                Clear(EInvoiceEntryL."E-Way Bill Date");
                Clear(EInvoiceEntryL."E-Way Bill Validity");
                Clear(EInvoiceEntryL."E-Way Generated");
                Clear(EInvoiceEntryL."New Vehicle No.");
                EInvoiceEntryL."E-Way Canceled" := true;
                EInvoiceEntryL."Vehicle No. Update Remark" := EInvoiceEntryL."Vehicle No. Update Remark"::" ";
                EInvoiceEntryL."E-Way Canceled Date" := Format(CURRENTDATETIME);
                EInvoiceEntryL."Cancelled By" := UserId;

                DeleteMultivehicleData(EInvoiceEntryL);
                EInvoiceEntryL.Modify();
                Message(EWayCancelled, ServiceInvHeader."No.");
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
        EInvoiceEntryL.SetRange("Document Type", DocType::Invoice);
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("Reason of Cancel");
        JObject.Add('ewbNo', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('cancelRsnCode', Format(EInvoiceEntryL."Reason of Cancel"));
        JObject.Add('cancelRmrk', 'Cancelled the order');
        JObject.WriteTo(RequestText);
        docNo := SalesInvHeader."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Cancelation", '', LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'ewbStatus').AsText() = 'CANCELLED') then begin
                Clear(EInvoiceEntryL."E-Way Bill No.");
                Clear(EInvoiceEntryL."E-Way Bill Date");
                Clear(EInvoiceEntryL."E-Way Bill Validity");
                Clear(EInvoiceEntryL."E-Way Generated");
                Clear(EInvoiceEntryL."New Vehicle No.");
                EInvoiceEntryL."E-Way Canceled" := true;
                EInvoiceEntryL."Vehicle No. Update Remark" := EInvoiceEntryL."Vehicle No. Update Remark"::" ";
                EInvoiceEntryL."E-Way Canceled Date" := Format(CURRENTDATETIME);
                EInvoiceEntryL."Cancelled By" := UserId;

                DeleteMultivehicleData(EInvoiceEntryL);
                EInvoiceEntryL.Modify();
                Message(EWayCancelled, SalesInvHeader."No.");
            end else
                Error(ResponseText);
    end;

    local procedure CancelEWaySalesCrMemo(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        SalesInvHeader: Record "Sales Cr.Memo Header";
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
        EInvoiceEntryL.SetRange("Document Type", DocType::CrMemo);
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("Reason of Cancel");
        JObject.Add('ewbNo', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('cancelRsnCode', Format(EInvoiceEntryL."Reason of Cancel"));
        JObject.Add('cancelRmrk', 'Cancelled the order');
        JObject.WriteTo(RequestText);
        docNo := SalesInvHeader."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Cancelation", '', LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'ewbStatus').AsText() = 'CANCELLED') then begin
                Clear(EInvoiceEntryL."E-Way Bill No.");
                Clear(EInvoiceEntryL."E-Way Bill Date");
                Clear(EInvoiceEntryL."E-Way Bill Validity");
                Clear(EInvoiceEntryL."E-Way Generated");
                Clear(EInvoiceEntryL."New Vehicle No.");
                EInvoiceEntryL."E-Way Canceled" := true;
                EInvoiceEntryL."Vehicle No. Update Remark" := EInvoiceEntryL."Vehicle No. Update Remark"::" ";
                EInvoiceEntryL."E-Way Canceled Date" := Format(CURRENTDATETIME);
                EInvoiceEntryL."Cancelled By" := UserId;
                DeleteMultivehicleData(EInvoiceEntryL);
                EInvoiceEntryL.Modify();
                Message(EWayCancelled, SalesInvHeader."No.");
            end else
                Error(ResponseText);
    end;



    local procedure CancelEWayServiceShip(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        SalesInvHeader: Record "service shipment Header";
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
        EInvoiceEntryL.SetRange("Document Type", DocType::CrMemo);
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("Reason of Cancel");
        JObject.Add('ewbNo', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('cancelRsnCode', Format(EInvoiceEntryL."Reason of Cancel"));
        JObject.Add('cancelRmrk', 'Cancelled the order');
        JObject.WriteTo(RequestText);
        docNo := SalesInvHeader."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Cancelation", '', LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'ewbStatus').AsText() = 'CANCELLED') then begin
                Clear(EInvoiceEntryL."E-Way Bill No.");
                Clear(EInvoiceEntryL."E-Way Bill Date");
                Clear(EInvoiceEntryL."E-Way Bill Validity");
                Clear(EInvoiceEntryL."E-Way Generated");
                Clear(EInvoiceEntryL."New Vehicle No.");
                EInvoiceEntryL."E-Way Canceled" := true;
                EInvoiceEntryL."Vehicle No. Update Remark" := EInvoiceEntryL."Vehicle No. Update Remark"::" ";
                EInvoiceEntryL."E-Way Canceled Date" := Format(CURRENTDATETIME);
                EInvoiceEntryL."Cancelled By" := UserId;
                DeleteMultivehicleData(EInvoiceEntryL);
                EInvoiceEntryL.Modify();
                Message(EWayCancelled, SalesInvHeader."No.");
            end else
                Error(ResponseText);
    end;


    local procedure CancelEWaySalesshipment(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        SalesInvHeader: Record "Sales Shipment Header";
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
        EInvoiceEntryL.SetRange("Document Type", DocType::"Sales Shipment");
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("Reason of Cancel");
        JObject.Add('ewbNo', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('cancelRsnCode', Format(EInvoiceEntryL."Reason of Cancel"));
        JObject.Add('cancelRmrk', 'Cancelled the order');
        JObject.WriteTo(RequestText);
        docNo := SalesInvHeader."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Cancelation", '', LocationL."GST Registration No.", false);
        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'ewbStatus').AsText() = 'CANCELLED') then begin
                Clear(EInvoiceEntryL."E-Way Bill No.");
                Clear(EInvoiceEntryL."E-Way Bill Date");
                Clear(EInvoiceEntryL."E-Way Bill Validity");
                Clear(EInvoiceEntryL."E-Way Generated");
                Clear(EInvoiceEntryL."New Vehicle No.");
                EInvoiceEntryL."E-Way Canceled" := true;
                EInvoiceEntryL."Vehicle No. Update Remark" := EInvoiceEntryL."Vehicle No. Update Remark"::" ";
                EInvoiceEntryL."E-Way Canceled Date" := Format(CURRENTDATETIME);
                EInvoiceEntryL."Cancelled By" := UserId;
                DeleteMultivehicleData(EInvoiceEntryL);
                EInvoiceEntryL.Modify();
                Message(EWayCancelled, SalesInvHeader."No.");
            end else
                Error(ResponseText);
    end;


    local procedure CancelEWayPurchaseInv(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    var
        PurchCrMemoHdr: Record "Purch. inv. Header";
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
        EInvoiceEntryL.SetRange("Document Type", DocType::"Purch. Inv. Hdr");
        EInvoiceEntryL.SetRange("Document No.", PurchCrMemoHdr."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("Reason of Cancel");
        JObject.Add('ewbNo', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('cancelRsnCode', Format(EInvoiceEntryL."Reason of Cancel"));
        JObject.Add('cancelRmrk', 'Cancelled the order');
        JObject.WriteTo(RequestText);
        docNo := PurchCrMemoHdr."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Cancelation", '', LocationL."GST Registration No.", false);

        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'ewbStatus').AsText() = 'CANCELLED') then begin
                Clear(EInvoiceEntryL."E-Way Bill No.");
                Clear(EInvoiceEntryL."E-Way Bill Date");
                Clear(EInvoiceEntryL."E-Way Bill Validity");
                Clear(EInvoiceEntryL."E-Way Generated");
                Clear(EInvoiceEntryL."New Vehicle No.");
                EInvoiceEntryL."E-Way Canceled" := true;
                EInvoiceEntryL."Vehicle No. Update Remark" := EInvoiceEntryL."Vehicle No. Update Remark"::" ";
                EInvoiceEntryL."E-Way Canceled Date" := Format(CURRENTDATETIME);
                EInvoiceEntryL."Cancelled By" := UserId;

                DeleteMultivehicleData(EInvoiceEntryL);
                EInvoiceEntryL.Modify();
                Message(EWayCancelled, PurchCrMemoHdr."No.");
            end else
                Error(ResponseText);
    end;

    local procedure CancelEWayPurchaseCRMemo(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
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
        EInvoiceEntryL.SetRange("Document Type", DocType::"Purch. Inv. Hdr");
        EInvoiceEntryL.SetRange("Document No.", PurchCrMemoHdr."No.");
        EInvoiceEntryL.SetRange("E-Way Generated", true);
        if EInvoiceEntryL.FindFirst() then;

        EInvoiceEntryL.TestField("E-Way Bill No.");
        EInvoiceEntryL.TestField("Reason of Cancel");
        JObject.Add('ewbNo', EInvoiceEntryL."E-Way Bill No.");
        JObject.Add('cancelRsnCode', Format(EInvoiceEntryL."Reason of Cancel"));
        JObject.Add('cancelRmrk', 'Cancelled the order');
        JObject.WriteTo(RequestText);
        docNo := PurchCrMemoHdr."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL E-Way Cancelation", '', LocationL."GST Registration No.", false);

        if JObject.ReadFrom(ResponseText) then
            if (GetValueFromJsonObject(JObject, 'ewbStatus').AsText() = 'CANCELLED') then begin
                Clear(EInvoiceEntryL."E-Way Bill No.");
                Clear(EInvoiceEntryL."E-Way Bill Date");
                Clear(EInvoiceEntryL."E-Way Bill Validity");
                Clear(EInvoiceEntryL."E-Way Generated");
                Clear(EInvoiceEntryL."New Vehicle No.");
                EInvoiceEntryL."E-Way Canceled" := true;
                EInvoiceEntryL."Vehicle No. Update Remark" := EInvoiceEntryL."Vehicle No. Update Remark"::" ";
                EInvoiceEntryL."E-Way Canceled Date" := Format(CURRENTDATETIME);
                EInvoiceEntryL."Cancelled By" := UserId;

                DeleteMultivehicleData(EInvoiceEntryL);
                EInvoiceEntryL.Modify();
                Message(EWayCancelled, PurchCrMemoHdr."No.");
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
        EInvoiceEntryL.SetRange("Document Type", DocType::Invoice);
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(SalesInvHeader."Location Code");

            // JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            // JObject.Add('print_type', 'DETAILED');
            // JArray.Add(JObject);
            // JArray.WriteTo(RequestText);

            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "DETAILED"}';
            docNo := SalesInvHeader."No.";
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;

    procedure GetEWaySalesInvoiceForPrintCons(SalesInvHeader: Record "Sales Invoice Header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin

        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::Invoice);
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(SalesInvHeader."Location Code");
            //JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            // JObject.Add('print_type', 'BASIC');
            // JArray.Add(JObject);
            // JArray.WriteTo(RequestText);
            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "BASIC"}';

            docNo := SalesInvHeader."No.";
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;

    procedure GetEWayServiceInvoiceForPrint(ServiceInvHeader: Record "Service Invoice Header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin

        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Service Invoice");
        EInvoiceEntryL.SetRange("Document No.", ServiceInvHeader."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(ServiceInvHeader."Location Code");

            // JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            // JObject.Add('print_type', 'DETAILED');
            // JArray.Add(JObject);
            // JArray.WriteTo(RequestText);

            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "DETAILED"}';
            docNo := ServiceInvHeader."No.";
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;

    procedure GetEWayServiceInvoiceForPrintCons(ServiceInvHeader: Record "Service Shipment Header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin

        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Service Invoice");
        EInvoiceEntryL.SetRange("Document No.", ServiceInvHeader."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(ServiceInvHeader."Location Code");
            //JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            // JObject.Add('print_type', 'BASIC');
            // JArray.Add(JObject);
            // JArray.WriteTo(RequestText);
            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "BASIC"}';

            docNo := ServiceInvHeader."No.";
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;

    procedure GetEWayPurchCrDetailForPrint(PurchCrMemo: Record "Purch. Cr. Memo Hdr.")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin

        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Purch Cr. Memo Hdr");
        EInvoiceEntryL.SetRange("Document No.", PurchCrMemo."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(PurchCrMemo."Location Code");

            // JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            // JObject.Add('print_type', 'DETAILED');
            // JArray.Add(JObject);
            // JArray.WriteTo(RequestText);

            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "DETAILED"}';
            docNo := PurchCrMemo."No.";
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;


    procedure GetEWayPurchaseCreForPrintCons(PurchCrMemo: Record "Purch. Cr. Memo Hdr.")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin

        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Purch Cr. Memo Hdr");
        EInvoiceEntryL.SetRange("Document No.", PurchCrMemo."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(PurchCrMemo."Location Code");
            //JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            // JObject.Add('print_type', 'BASIC');
            // JArray.Add(JObject);
            // JArray.WriteTo(RequestText);
            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "BASIC"}';

            docNo := PurchCrMemo."No.";
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;

    local procedure GetTaxableAmountSalesInvoice(DocNo: Code[20]): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    // SalesInvoiceLine: Record "Sales Cr.Memo Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocNo);
        SalesInvoiceLine.SetFilter(Quantity, '<>%1', 0);
        //SalesInvoiceLine.CalcSums("GST Base Amount");
        //if SalesInvoiceLine."GST Base Amount" <> 0 then
        //EXIT(SalesInvoiceLine."GST Base Amount");

        SalesInvoiceLine.CalcSums("Line Amount");
        EXIT(SalesInvoiceLine."Line Amount");
    end;


    local procedure GetTaxableAmountSalesShip(DocNo: Code[20]): Decimal
    var
        SalesShipmentLine: Record "Sales shipment Line";
        SalesLine: Record "sales Line";
        TaxTransactionValue: record "tax transaction value";
        LineAmount: decimal;
        PerQtyLineAmount: decimal;
    // SalesInvoiceLine: Record "Sales Cr.Memo Line";
    begin
        SalesShipmentLine.SetRange("Document No.", DocNo);
        SalesShipmentLine.SetFilter(Quantity, '<>%1', 0);
        SalesShipmentLine.setfilter("Quantity Invoiced", '>%1', 0);
        if SalesShipmentLine.findfirst then
            error('Invoice already generated , Kindly used Posted invoice screen to generate e-way Bill');

        SalesShipmentLine.SetRange("Document No.", DocNo);
        SalesShipmentLine.SetFilter(Quantity, '<>%1', 0);
        SalesShipmentLine.setrange("Quantity Invoiced", 0);

        SalesShipmentLine.FindSet();
        repeat
            SalesLine.setrange("document type", salesline."document Type"::order);
            salesline.SetRange("document No.", SalesShipmentLine."order no.");
            salesline.SetRange("line no.", SalesShipmentLine."order line no.");
            if salesLine.findfirst then begin

                PerQtyLineAmount := salesline."Line Amount" / SalesLine.Quantity;
                LineAmount := LineAmount + (PerQtyLineAmount * SalesShipmentLine.quantity);

            end;
        until salesshipmentline.next = 0;

        EXIT(LineAmount);
    end;

    local procedure GetTaxableAmountSalesCr(DocNo: Code[20]): Decimal
    var
        //  SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrLine.SetRange("Document No.", DocNo);
        SalesCrLine.SetFilter(Quantity, '<>%1', 0);
        //SalesInvoiceLine.CalcSums("GST Base Amount");
        //if SalesInvoiceLine."GST Base Amount" <> 0 then
        //EXIT(SalesInvoiceLine."GST Base Amount");

        SalesCrLine.CalcSums("Line Amount");
        EXIT(SalesCrLine."Line Amount");
    end;




    local procedure GetTaxableAmountServiceShip(DocNo: Code[20]): Decimal
    var
        SalesShipmentLine: Record "Service shipment Line";
        SalesLine: Record "Service Line";
        TaxTransactionValue: record "tax transaction value";
        LineAmount: decimal;
        PerQtyLineAmount: decimal;
    // SalesInvoiceLine: Record "Sales Cr.Memo Line";
    begin
        SalesShipmentLine.SetRange("Document No.", DocNo);
        SalesShipmentLine.SetFilter(Quantity, '<>%1', 0);
        SalesShipmentLine.setfilter("Quantity Invoiced", '>%1', 0);
        if SalesShipmentLine.findfirst then
            error('Invoice already generated , Kindly used Posted invoice screen to generate e-way Bill');

        SalesShipmentLine.setrange("Quantity Invoiced", 0);
        //SalesInvoiceLine.CalcSums("GST Base Amount");
        //if SalesInvoiceLine."GST Base Amount" <> 0 then
        //EXIT(SalesShipmentLine."GST Base Amount");
        SalesShipmentLine.FindSet();
        repeat
            SalesLine.setrange("document type", salesline."document Type"::order);
            salesline.SetRange("document No.", SalesShipmentLine."order no.");
            salesline.SetRange("line no.", SalesShipmentLine."order line no.");
            if salesLine.findfirst then begin

                PerQtyLineAmount := salesline."Line Amount" / SalesLine.Quantity;
                LineAmount := LineAmount + (PerQtyLineAmount * SalesShipmentLine.quantity);

            end;
        until salesshipmentline.next = 0;

        EXIT(LineAmount);
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
    // Service Invoice 


    local procedure GetTaxableAmountServiceInvoice(DocNo: Code[20]): Decimal
    var
        SalesInvoiceLine: Record "Service Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocNo);
        SalesInvoiceLine.SetFilter(Quantity, '<>%1', 0);
        //SalesInvoiceLine.CalcSums("GST Base Amount");
        //if SalesInvoiceLine."GST Base Amount" <> 0 then
        //EXIT(SalesInvoiceLine."GST Base Amount");

        SalesInvoiceLine.CalcSums("Line Amount");
        EXIT(SalesInvoiceLine."Line Amount");
    end;

    local procedure GetRoundingGLService(CustPostingGrp: Code[10]; var InvRoundingGL: Code[20]; var PITRoundingGL: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin

        if CustomerPostingGroup.Get(CustPostingGrp) then begin
            InvRoundingGL := CustomerPostingGroup."Invoice Rounding Account";
            //PITRoundingGL := CustomerPostingGroup."PIT Difference Acc.";
        end;
    end;

    // Service Invoice 

    procedure GetEWayPurchInvDetailForPrint(PurchCrMemo: Record "Purch. Inv. Header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin

        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Purch. Inv. Hdr");
        EInvoiceEntryL.SetRange("Document No.", PurchCrMemo."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(PurchCrMemo."Location Code");

            // JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            // JObject.Add('print_type', 'DETAILED');
            // JArray.Add(JObject);
            // JArray.WriteTo(RequestText);

            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "DETAILED"}';
            docNo := PurchCrMemo."No.";
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;


    procedure GetEWayPurchaseInvForPrintCons(PurchCrMemo: Record "Purch. inv. header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin

        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Purch. Inv. Hdr");
        EInvoiceEntryL.SetRange("Document No.", PurchCrMemo."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(PurchCrMemo."Location Code");
            //JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            // JObject.Add('print_type', 'BASIC');
            // JArray.Add(JObject);
            // JArray.WriteTo(RequestText);
            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "BASIC"}';

            docNo := PurchCrMemo."No.";
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;

    //::??




    procedure GetEWaySalesShipDetailForPrint(SalesShip: Record "Sales Shipment Header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin

        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Sales Shipment");
        EInvoiceEntryL.SetRange("Document No.", SalesShip."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(SalesShip."Location Code");

            // JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            // JObject.Add('print_type', 'DETAILED');
            // JArray.Add(JObject);
            // JArray.WriteTo(RequestText);

            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "DETAILED"}';
            docNo := SalesShip."No.";
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;


    procedure GetEWaySalesShipForPrintCons(SalesShip: Record "Sales Shipment header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin

        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Sales Shipment");
        EInvoiceEntryL.SetRange("Document No.", SalesShip."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(SalesShip."Location Code");
            //JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            // JObject.Add('print_type', 'BASIC');
            // JArray.Add(JObject);
            // JArray.WriteTo(RequestText);
            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "BASIC"}';

            docNo := SalesShip."No.";
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;

    //::??



    local procedure GetTaxableAmountPCrMemo(DocNo: Code[20]): Decimal
    var
        PurchCrMemoLine: Record "Purch. cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", DocNo);
        PurchCrMemoLine.SetFilter(Quantity, '<>%1', 0);
        //PurchCrMemoLine.CalcSums("GST Base Amount");
        //if PurchCrMemoLine."GST Base Amount" <> 0 then
        //EXIT(PurchCrMemoLine."GST Base Amount");
        PurchCrMemoLine.CalcSums("Line Amount");
        EXIT(PurchCrMemoLine."Line Amount");
    end;

    local procedure GetTaxableAmountPInv(DocNo: Code[20]): Decimal
    var
        PurchCrMemoLine: Record "Purch. inv. Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", DocNo);
        PurchCrMemoLine.SetFilter(Quantity, '<>%1', 0);
        //PurchCrMemoLine.CalcSums("GST Base Amount");
        //if PurchCrMemoLine."GST Base Amount" <> 0 then
        //EXIT(PurchCrMemoLine."GST Base Amount");
        PurchCrMemoLine.CalcSums("Line Amount");
        EXIT(PurchCrMemoLine."Line Amount");
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
        EInvoiceEntryL.SetRange("Document Type", DocType::"Purch. Inv. Hdr");
        EInvoiceEntryL.SetRange("Document No.", PurchCrMemoHdr."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(PurchCrMemoHdr."Location Code");
            JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            JObject.Add('ewb_numbers', JArray);
            JObject.Add('print_type', 'DETAILED');
            docNo := PurchCrMemoHdr."No.";
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL", '', LocationL."GST Registration No.", true);
        end;
    end;


    procedure GetEWayPurchaseInvforPrint(PurchCrMemoHdr: Record "Purch. Inv. Header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin
        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Purch. Inv. Hdr");
        EInvoiceEntryL.SetRange("Document No.", PurchCrMemoHdr."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(PurchCrMemoHdr."Location Code");
            JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            JObject.Add('ewb_numbers', JArray);
            JObject.Add('print_type', 'DETAILED');
            docNo := PurchCrMemoHdr."No.";
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL", '', LocationL."GST Registration No.", true);
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



    local procedure CheckTransferInvoiceLine(DocumentNo: Code[20]; TaxType: Code[20]): Boolean
    var
        TransferShipmentLine: Record "Transfer shipment Line";
        Found: Boolean;
    begin
        TransferShipmentLine.SetRange("Document No.", DocumentNo);
        TransferShipmentLine.SetFilter("Item No.", '<>%1', '');
        if TransferShipmentLine.FindSet() then
            repeat
                Found := TransactionValueExist(TransferShipmentLine.RecordId, TaxType);
            until (TransferShipmentLine.Next() = 0) or Found;

        exit(Found);
    end;

    local procedure TransactionValueExist(RecID: RecordID; TaxType: Code[20]): Boolean
    var
        TaxTransactionValue: Record "Tax Transaction Value";
    begin
        TaxTransactionValue.SetRange("Tax Type", TaxType);
        TaxTransactionValue.SetRange("Tax Record ID", RecId);
        Exit(not TaxTransactionValue.IsEmpty());
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
        EInvoiceEntryL.SetRange("Document Type", 3);
        EInvoiceEntryL.SetRange("Document No.", TransShipHeader."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(TransShipHeader."Transfer-from Code");
            JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            JObject.Add('ewb_numbers', JArray);
            JObject.Add('print_type', 'DETAILED');
            JObject.WriteTo(RequestText);
            docNo := TransShipHeader."No.";
            //   SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL", '', LocationL."GST Registration No.", true);
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;

    procedure GetEWayTransferShipmentforPrintBasic(TransShipHeader: Record "Transfer Shipment Header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin
        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", 3);
        EInvoiceEntryL.SetRange("Document No.", TransShipHeader."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(TransShipHeader."Transfer-from Code");
            // JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', JArray);
            // JObject.Add('print_type', 'Basic');
            // JObject.WriteTo(RequestText);
            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "BASIC"}';

            docNo := TransShipHeader."No.";
            //  SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL", '', LocationL."GST Registration No.", true);
            SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;

    procedure GenerateMultiVehicle(Rec: Record "ClearComp e-Invoice Entry")
    var
        saleshipLine: REcord "sales shipment Line";
        purchinvhdr: Record "purch. inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        TransferShip: Record "transfer shipment Header";
        SalesInvoice: Record "Sales Invoice Header";
        SalesCrMemo: Record "Sales Cr.memo Header";
        SalesShip: Record "Sales Shipment Header";
        JobjectL: JsonObject;
        StateL: Record State;
        MultiVehicle: Record "CT- E-way Multi Vehicle";
        jsonSubobject: JsonObject;
        JsonArrayL: JsonArray;
        RequestText: text;
        ResponseText: Text;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        LocationL: record location;
        gstregistrationNoRec: record "GST Registration Nos.";
    begin

        //rra
        if rec."Multi vehicle Generated" then
            error('Multivehicle Already generated');
        Rec.testfield("Multi Vehicle Reason Code");
        Rec.testfield("Multi Vehicle Remark");
        case rec."Document Type" of
            rec."Document Type"::Invoice:
                begin
                    SalesInvoice.get(rec."Document No.");
                    LocationL.get(SalesInvoice."Location Code");
                    JobjectL.add('EwbNumber', rec."E-Way Bill No.");
                    JobjectL.add('FromPlace', rec."From Place");
                    StateL.get(rec."From State");
                    JobjectL.add('FromState', StateL."State Code (GST Reg. No.)");
                    JobjectL.add('ToPlace', rec."From Place");
                    StateL.get(rec."To State");
                    JobjectL.add('ToState', StateL."State Code (GST Reg. No.)");
                    JobjectL.add('ReasonCode', format(rec."Multi Vehicle Reason Code"));
                    JobjectL.add('ReasonRemark', rec."Multi Vehicle Remark");
                    JobjectL.add('TransMode', SalesInvoice."Shipment Method Code");
                    JobjectL.add('TotalQuantity', rec."Total Qty On Multi veh. page");
                    jobjectL.add('UnitOfMeasurement', 'OTH');
                    jobjectL.add('GroupNumber', 0);

                    MultiVehicle.SetRange("Document Type", rec."Document Type");
                    MultiVehicle.setrange("Document No.", rec."Document No.");
                    MultiVehicle.setrange("API Type", rec."API Type");
                    MultiVehicle.FindFirst();
                    repeat
                        clear(jsonSubobject);
                        jsonSubobject.add('VehicleNo', MultiVehicle."Vehicle No.");
                        jsonSubobject.add('DocumentNumber', MultiVehicle."LR/RR No.");

                        jsonSubobject.add('DocumentDate', Format(MultiVehicle."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                        jsonSubobject.add('Quantity', MultiVehicle.Quantity);
                        JsonArrayL.Add(jsonSubobject);
                    until MultiVehicle.next = 0;
                    jobjectL.add('VehicleListDetails', JsonArrayL);

                    docNo := rec."Document No.";
                    JObjectL.WriteTo(RequestText);
                    EInvoiceSetupL.get;
                    // if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                    //     gstregistrationNoRec.get(locationl."GST Registration No.");
                    //     GSTNO := gstregistrationNoRec."Einv Demo GST REgistration No.";

                    // end else
                    GSTNO := LocationL."GST Registration No.";

                    SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL Multi Vehicle Eway", '', GSTNO, false);

                    if JObject.ReadFrom(ResponseText) then
                        if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin
                            rec."Multi vehicle Generated" := true;
                            rec.modify;
                            Message(MultiVehicleUpdated, docNo);
                        end else
                            Error(ResponseText);


                end;
            rec."Document Type"::CrMemo:
                begin
                    SalesCrMemo.get(rec."Document No.");
                    LocationL.get(SalesCrMemo."Location Code");
                    JobjectL.add('EwbNumber', rec."E-Way Bill No.");
                    JobjectL.add('FromPlace', rec."From Place");
                    StateL.get(rec."From State");
                    JobjectL.add('FromState', StateL."State Code (GST Reg. No.)");
                    JobjectL.add('ToPlace', rec."From Place");
                    StateL.get(rec."To State");
                    JobjectL.add('ToState', StateL."State Code (GST Reg. No.)");
                    JobjectL.add('ReasonCode', format(rec."Multi Vehicle Reason Code"));
                    JobjectL.add('ReasonRemark', rec."Multi Vehicle Remark");
                    JobjectL.add('TransMode', SalesCrMemo."Shipment Method Code");
                    JobjectL.add('TotalQuantity', rec."Total Qty On Multi veh. page");
                    jobjectL.add('UnitOfMeasurement', 'OTH');
                    jobjectL.add('GroupNumber', 0);

                    MultiVehicle.SetRange("Document Type", rec."Document Type");
                    MultiVehicle.setrange("Document No.", rec."Document No.");
                    MultiVehicle.setrange("API Type", rec."API Type");
                    MultiVehicle.FindFirst();
                    repeat
                        clear(jsonSubobject);
                        jsonSubobject.add('VehicleNo', MultiVehicle."Vehicle No.");
                        jsonSubobject.add('DocumentNumber', MultiVehicle."LR/RR No.");

                        jsonSubobject.add('DocumentDate', Format(MultiVehicle."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                        jsonSubobject.add('Quantity', MultiVehicle.Quantity);
                        JsonArrayL.Add(jsonSubobject);
                    until MultiVehicle.next = 0;
                    jobjectL.add('VehicleListDetails', JsonArrayL);

                    docNo := rec."Document No.";
                    JObjectL.WriteTo(RequestText);
                    EInvoiceSetupL.get;
                    // if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                    //     gstregistrationNoRec.get(locationl."GST Registration No.");
                    //     GSTNO := gstregistrationNoRec."Einv Demo GST REgistration No.";

                    // end else
                    GSTNO := LocationL."GST Registration No.";

                    SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL Multi Vehicle Eway", '', GSTNO, false);

                    if JObject.ReadFrom(ResponseText) then
                        if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin
                            rec."Multi vehicle Generated" := true;
                            rec.modify;
                            Message(MultiVehicleUpdated, docNo);
                        end else
                            Error(ResponseText);


                end;

            rec."Document Type"::TransferShpt:
                begin
                    TransferShip.get(rec."Document No.");
                    LocationL.get(TransferShip."Transfer-from Code");
                    JobjectL.add('EwbNumber', rec."E-Way Bill No.");
                    JobjectL.add('FromPlace', rec."From Place");
                    StateL.get(rec."From State");
                    JobjectL.add('FromState', StateL."State Code (GST Reg. No.)");
                    JobjectL.add('ToPlace', rec."From Place");
                    StateL.get(rec."To State");
                    JobjectL.add('ToState', StateL."State Code (GST Reg. No.)");
                    JobjectL.add('ReasonCode', format(rec."Multi Vehicle Reason Code"));
                    JobjectL.add('ReasonRemark', rec."Multi Vehicle Remark");
                    JobjectL.add('TransMode', TransferShip."Shipment Method Code");
                    JobjectL.add('TotalQuantity', rec."Total Qty On Multi veh. page");
                    jobjectL.add('UnitOfMeasurement', 'OTH');
                    jobjectL.add('GroupNumber', 0);

                    MultiVehicle.SetRange("Document Type", rec."Document Type");
                    MultiVehicle.setrange("Document No.", rec."Document No.");
                    MultiVehicle.setrange("API Type", rec."API Type");
                    MultiVehicle.FindFirst();
                    repeat
                        clear(jsonSubobject);
                        jsonSubobject.add('VehicleNo', MultiVehicle."Vehicle No.");
                        jsonSubobject.add('DocumentNumber', MultiVehicle."LR/RR No.");

                        jsonSubobject.add('DocumentDate', Format(MultiVehicle."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                        jsonSubobject.add('Quantity', MultiVehicle.Quantity);
                        JsonArrayL.Add(jsonSubobject);
                    until MultiVehicle.next = 0;
                    jobjectL.add('VehicleListDetails', JsonArrayL);

                    docNo := rec."Document No.";
                    JObjectL.WriteTo(RequestText);
                    EInvoiceSetupL.get;
                    // if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                    //     gstregistrationNoRec.get(locationl."GST Registration No.");
                    //     GSTNO := gstregistrationNoRec."Einv Demo GST REgistration No.";

                    // end else
                    GSTNO := LocationL."GST Registration No.";

                    SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL Multi Vehicle Eway", '', GSTNO, false);

                    if JObject.ReadFrom(ResponseText) then
                        if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin
                            rec."Multi vehicle Generated" := true;
                            rec.modify;
                            Message(MultiVehicleUpdated, docNo);
                        end else
                            Error(ResponseText);


                end;
            rec."Document Type"::"Purch Cr. Memo Hdr":
                begin
                    PurchCrMemoHdr.get(rec."Document No.");
                    LocationL.get(PurchCrMemoHdr."Location Code");
                    JobjectL.add('EwbNumber', rec."E-Way Bill No.");
                    JobjectL.add('FromPlace', rec."From Place");
                    StateL.get(rec."From State");
                    JobjectL.add('FromState', StateL."State Code (GST Reg. No.)");
                    JobjectL.add('ToPlace', rec."From Place");
                    StateL.get(rec."To State");
                    JobjectL.add('ToState', StateL."State Code (GST Reg. No.)");
                    JobjectL.add('ReasonCode', format(rec."Multi Vehicle Reason Code"));
                    JobjectL.add('ReasonRemark', rec."Multi Vehicle Remark");
                    JobjectL.add('TransMode', PurchCrMemoHdr."Shipment Method Code");
                    JobjectL.add('TotalQuantity', rec."Total Qty On Multi veh. page");
                    jobjectL.add('UnitOfMeasurement', 'OTH');
                    jobjectL.add('GroupNumber', 0);

                    MultiVehicle.SetRange("Document Type", rec."Document Type");
                    MultiVehicle.setrange("Document No.", rec."Document No.");
                    MultiVehicle.setrange("API Type", rec."API Type");
                    MultiVehicle.FindFirst();
                    repeat
                        clear(jsonSubobject);
                        jsonSubobject.add('VehicleNo', MultiVehicle."Vehicle No.");
                        jsonSubobject.add('DocumentNumber', MultiVehicle."LR/RR No.");

                        jsonSubobject.add('DocumentDate', Format(MultiVehicle."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                        jsonSubobject.add('Quantity', MultiVehicle.Quantity);
                        JsonArrayL.Add(jsonSubobject);
                    until MultiVehicle.next = 0;
                    jobjectL.add('VehicleListDetails', JsonArrayL);

                    docNo := rec."Document No.";
                    JObjectL.WriteTo(RequestText);
                    EInvoiceSetupL.get;
                    // if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                    //     gstregistrationNoRec.get(locationl."GST Registration No.");
                    //     GSTNO := gstregistrationNoRec."Einv Demo GST REgistration No.";

                    // end else
                    GSTNO := LocationL."GST Registration No.";

                    SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL Multi Vehicle Eway", '', GSTNO, false);

                    if JObject.ReadFrom(ResponseText) then
                        if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin
                            rec."Multi vehicle Generated" := true;
                            rec.modify;
                            Message(MultiVehicleUpdated, docNo);
                        end else
                            Error(ResponseText);


                end;
            rec."Document Type"::"Purch. Inv. Hdr":
                begin
                    purchinvhdr.get(rec."Document No.");
                    LocationL.get(purchinvhdr."Location Code");
                    JobjectL.add('EwbNumber', rec."E-Way Bill No.");
                    JobjectL.add('FromPlace', rec."From Place");
                    StateL.get(rec."From State");
                    JobjectL.add('FromState', StateL."State Code (GST Reg. No.)");
                    JobjectL.add('ToPlace', rec."From Place");
                    StateL.get(rec."To State");
                    JobjectL.add('ToState', StateL."State Code (GST Reg. No.)");
                    JobjectL.add('ReasonCode', format(rec."Multi Vehicle Reason Code"));
                    JobjectL.add('ReasonRemark', rec."Multi Vehicle Remark");
                    JobjectL.add('TransMode', purchinvhdr."Shipment Method Code");
                    JobjectL.add('TotalQuantity', rec."Total Qty On Multi veh. page");
                    jobjectL.add('UnitOfMeasurement', 'OTH');
                    jobjectL.add('GroupNumber', 0);

                    MultiVehicle.SetRange("Document Type", rec."Document Type");
                    MultiVehicle.setrange("Document No.", rec."Document No.");
                    MultiVehicle.setrange("API Type", rec."API Type");
                    MultiVehicle.FindFirst();
                    repeat
                        clear(jsonSubobject);
                        jsonSubobject.add('VehicleNo', MultiVehicle."Vehicle No.");
                        jsonSubobject.add('DocumentNumber', MultiVehicle."LR/RR No.");

                        jsonSubobject.add('DocumentDate', Format(MultiVehicle."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                        jsonSubobject.add('Quantity', MultiVehicle.Quantity);
                        JsonArrayL.Add(jsonSubobject);
                    until MultiVehicle.next = 0;
                    jobjectL.add('VehicleListDetails', JsonArrayL);

                    docNo := rec."Document No.";
                    JObjectL.WriteTo(RequestText);
                    EInvoiceSetupL.get;
                    // if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                    //     gstregistrationNoRec.get(locationl."GST Registration No.");
                    //     GSTNO := gstregistrationNoRec."Einv Demo GST REgistration No.";

                    // end else
                    GSTNO := LocationL."GST Registration No.";

                    SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL Multi Vehicle Eway", '', GSTNO, false);

                    if JObject.ReadFrom(ResponseText) then
                        if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin
                            rec."Multi vehicle Generated" := true;
                            rec.modify;
                            Message(MultiVehicleUpdated, docNo);
                        end else
                            Error(ResponseText);


                end;

            rec."Document Type"::"Sales Shipment":
                begin
                    SalesShip.get(rec."Document No.");
                    saleshipLine.setrange("Document No.", rec."Document No.");
                    saleshipLine.setrange(Type, saleshipLine.type::Item);
                    saleshipLine.findfirst;
                    LocationL.get(SalesShip."Location Code");
                    JobjectL.add('EwbNumber', rec."E-Way Bill No.");
                    JobjectL.add('FromPlace', rec."From Place");
                    StateL.get(rec."From State");
                    JobjectL.add('FromState', StateL."State Code (GST Reg. No.)");
                    JobjectL.add('ToPlace', rec."From Place");
                    StateL.get(rec."To State");
                    JobjectL.add('ToState', StateL."State Code (GST Reg. No.)");
                    JobjectL.add('ReasonCode', format(rec."Multi Vehicle Reason Code"));
                    JobjectL.add('ReasonRemark', rec."Multi Vehicle Remark");
                    JobjectL.add('TransMode', SalesShip."Shipment Method Code");
                    JobjectL.add('TotalQuantity', rec."Total Qty On Multi veh. page");
                    jobjectL.add('UnitOfMeasurement', saleshipLine."Unit of Measure Code");
                    jobjectL.add('GroupNumber', 0);

                    MultiVehicle.SetRange("Document Type", rec."Document Type");
                    MultiVehicle.setrange("Document No.", rec."Document No.");
                    MultiVehicle.setrange("API Type", rec."API Type");
                    MultiVehicle.FindFirst();
                    repeat
                        clear(jsonSubobject);
                        jsonSubobject.add('VehicleNo', MultiVehicle."Vehicle No.");
                        jsonSubobject.add('DocumentNumber', MultiVehicle."LR/RR No.");

                        jsonSubobject.add('DocumentDate', Format(MultiVehicle."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                        jsonSubobject.add('Quantity', MultiVehicle.Quantity);
                        JsonArrayL.Add(jsonSubobject);
                    until MultiVehicle.next = 0;
                    jobjectL.add('VehicleListDetails', JsonArrayL);

                    docNo := rec."Document No.";
                    JObjectL.WriteTo(RequestText);
                    EInvoiceSetupL.get;
                    // if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                    //     gstregistrationNoRec.get(locationl."GST Registration No.");
                    //     GSTNO := gstregistrationNoRec."Einv Demo GST REgistration No.";

                    // end else
                    GSTNO := LocationL."GST Registration No.";

                    SendRequest('PUT', RequestText, ResponseText, EInvoiceSetupL."URL Multi Vehicle Eway", '', GSTNO, false);

                    if JObject.ReadFrom(ResponseText) then
                        if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin
                            rec."Multi vehicle Generated" := true;
                            rec.modify;
                            Message(MultiVehicleUpdated, docNo);
                        end else
                            Error(ResponseText);


                end;


        end;
    end;

    procedure ExtendEwayBill(Rec: Record "ClearComp e-Invoice Entry")
    var
        vendorL: Record Vendor;
        EntryPoint: record "Entry/Exit Point";
        PurchInvHeader: record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        TransferShip: Record "transfer shipment Header";
        SalesInvoice: Record "Sales Invoice Header";
        SalesCrMemo: Record "Sales Cr.Memo Header";
        SalesShipment: Record "Sales Shipment Header";
        JobjectL: JsonObject;
        StateL: Record State;
        MultiVehicle: Record "CT- E-way Multi Vehicle";
        jsonSubobject: JsonObject;
        JsonArrayL: JsonArray;
        RequestText: text;
        ResponseText: Text;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        LocationL: record location;
        gstregistrationNoRec: record "GST Registration Nos.";
    begin
        Rec.testfield("Extend E-way Reason Code");
        Rec.testfield("Extend E-way  Remark");
        case Rec."Document Type" of
            Rec."Document Type"::Invoice:
                begin


                    SalesInvoice.get(rec."Document No.");
                    LocationL.get(SalesInvoice."Location Code");
                    JobjectL.add('EwbNumber', rec."E-Way Bill No.");
                    JobjectL.add('FromPlace', rec."From Place");
                    JobjectL.add('FromPincode', LocationL."Post Code");
                    StateL.get(rec."From State");
                    JobjectL.add('FromState', StateL."State Code (GST Reg. No.)");

                    JobjectL.add('ReasonCode', format(rec."Extend E-way Reason Code"));
                    Rec.testfield("Extend E-way Reason Code");
                    Rec.testfield("Extend E-way  Remark");
                    JobjectL.add('ReasonRemark', rec."Extend E-way  Remark");
                    JobjectL.add('TransMode', SalesInvoice."Shipment Method Code");
                    JobjectL.add('TransDocDt', Format(SalesInvoice."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                    JobjectL.add('TransDocNo', SalesInvoice."LR/RR No.");
                    JobjectL.add('DocumentNumber', rec."Document No.");
                    JobjectL.add('DocumentType', 'INV');
                    JobjectL.add('DocumentDate', Format(SalesInvoice."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));

                    if SalesInvoice."Vehicle Type" = SalesInvoice."Vehicle Type"::Regular then
                        JObject.Add('VehicleType', 'R')
                    else
                        if SalesInvoice."Vehicle Type" = SalesInvoice."Vehicle Type"::ODC then
                            JObject.Add('VehicleType', 'O')
                        else
                            JObject.Add('VehicleType', 'R');
                    //   JobjectL.add('VehicleType', format(SalesInvoice."Vehicle Type"));
                    //  if SalesInvoice."Vehicle No." <> '' then 
                    //    rec.TestField();
                    if Rec."New Vehicle No." > '' then
                        JobjectL.add('VehNo', Rec."New Vehicle No.")
                    else begin
                        salesInvoice.Testfield("Vehicle No.");
                        JobjectL.add('VehNo', SalesInvoice."Vehicle no.")
                    end;



                    JobjectL.add('ConsignmentStatus', 'MOVEMENT');
                    rec.TestField("Remaining Distnce");
                    JobjectL.add('RemainingDistance', rec."Remaining Distnce");







                    docNo := rec."Document No.";
                    JObjectL.WriteTo(RequestText);
                    EInvoiceSetupL.get;
                    // if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                    //     gstregistrationNoRec.get(locationl."GST Registration No.");
                    //     GSTNO := gstregistrationNoRec."Einv Demo GST REgistration No.";

                    // end else
                    GSTNO := LocationL."GST Registration No.";

                    SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL Extend E-way Bill Validity", '', LocationL."GST Registration No.", false);
                    if JObject.ReadFrom(ResponseText) then
                        if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin

                            if JObject.Contains('ValidUpto') then
                                Rec."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                            Rec.Modify();
                            Message(VehicleUpdated, SalesInvoice."No.");
                        end else
                            Error(ResponseText);


                end;

            rec."document Type"::"sales shipment":
                begin



                    SalesShipment.get(rec."Document No.");
                    LocationL.get(SalesShipment."Location Code");
                    JobjectL.add('EwbNumber', rec."E-Way Bill No.");
                    JobjectL.add('FromPlace', rec."From Place");
                    JobjectL.add('FromPincode', LocationL."Post Code");
                    StateL.get(rec."From State");
                    JobjectL.add('FromState', StateL."State Code (GST Reg. No.)");

                    JobjectL.add('ReasonCode', format(rec."Extend E-way Reason Code"));
                    Rec.testfield("Extend E-way Reason Code");
                    Rec.testfield("Extend E-way  Remark");
                    JobjectL.add('ReasonRemark', rec."Extend E-way  Remark");
                    JobjectL.add('TransMode', SalesShipment."Shipment Method Code");
                    JobjectL.add('TransDocDt', Format(SalesShipment."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                    JobjectL.add('TransDocNo', SalesShipment."LR/RR No.");
                    JobjectL.add('DocumentNumber', rec."Document No.");
                    JobjectL.add('DocumentType', 'INV');
                    JobjectL.add('DocumentDate', Format(SalesShipment."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));

                    if SalesShipment."Vehicle Type" = SalesShipment."Vehicle Type"::Regular then
                        JObject.Add('VehicleType', 'R')
                    else
                        if SalesShipment."Vehicle Type" = SalesShipment."Vehicle Type"::ODC then
                            JObject.Add('VehicleType', 'O')
                        else
                            JObject.Add('VehicleType', 'R');
                    //   JobjectL.add('VehicleType', format(SalesInvoice."Vehicle Type"));
                    //  if SalesInvoice."Vehicle No." <> '' then 
                    //    rec.TestField();
                    if Rec."New Vehicle No." > '' then
                        JobjectL.add('VehNo', Rec."New Vehicle No.")
                    else begin
                        SalesShipment.Testfield("Vehicle No.");
                        JobjectL.add('VehNo', SalesShipment."Vehicle no.")
                    end;



                    JobjectL.add('ConsignmentStatus', 'MOVEMENT');
                    rec.TestField("Remaining Distnce");
                    JobjectL.add('RemainingDistance', rec."Remaining Distnce");







                    docNo := rec."Document No.";
                    JObjectL.WriteTo(RequestText);
                    EInvoiceSetupL.get;
                    // if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                    //     gstregistrationNoRec.get(locationl."GST Registration No.");
                    //     GSTNO := gstregistrationNoRec."Einv Demo GST REgistration No.";

                    // end else
                    GSTNO := LocationL."GST Registration No.";

                    SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL Extend E-way Bill Validity", '', LocationL."GST Registration No.", false);
                    if JObject.ReadFrom(ResponseText) then
                        if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin

                            if JObject.Contains('ValidUpto') then
                                Rec."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                            Rec.Modify();
                            Message(VehicleUpdated, SalesShipment."No.");
                        end else
                            Error(ResponseText);




                end;

            rec."Document Type"::CrMemo:
                begin



                    SalesCrMemo.get(rec."Document No.");
                    LocationL.get(SalesCrMemo."Location Code");
                    JobjectL.add('EwbNumber', rec."E-Way Bill No.");
                    JobjectL.add('FromPlace', rec."From Place");
                    JobjectL.add('FromPincode', LocationL."Post Code");
                    StateL.get(rec."From State");
                    JobjectL.add('FromState', StateL."State Code (GST Reg. No.)");

                    JobjectL.add('ReasonCode', format(rec."Extend E-way Reason Code"));
                    Rec.testfield("Extend E-way Reason Code");
                    Rec.testfield("Extend E-way  Remark");
                    JobjectL.add('ReasonRemark', rec."Extend E-way  Remark");
                    JobjectL.add('TransMode', SalesCrMemo."Shipment Method Code");
                    JobjectL.add('TransDocDt', Format(SalesCrMemo."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                    JobjectL.add('TransDocNo', SalesCrMemo."LR/RR No.");
                    JobjectL.add('DocumentNumber', rec."Document No.");
                    JobjectL.add('DocumentType', 'INV');
                    JobjectL.add('DocumentDate', Format(SalesCrMemo."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));

                    if SalesCrMemo."Vehicle Type" = SalesCrMemo."Vehicle Type"::Regular then
                        JObject.Add('VehicleType', 'R')
                    else
                        if SalesCrMemo."Vehicle Type" = SalesCrMemo."Vehicle Type"::ODC then
                            JObject.Add('VehicleType', 'O')
                        else
                            JObject.Add('VehicleType', 'R');
                    //   JobjectL.add('VehicleType', format(SalesInvoice."Vehicle Type"));
                    JobjectL.add('VehNo', SalesCrMemo."Vehicle No.");

                    JobjectL.add('ConsignmentStatus', 'MOVEMENT');
                    rec.TestField("Remaining Distnce");
                    JobjectL.add('RemainingDistance', rec."Remaining Distnce");







                    docNo := rec."Document No.";
                    JObjectL.WriteTo(RequestText);
                    EInvoiceSetupL.get;
                    // if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                    //     gstregistrationNoRec.get(locationl."GST Registration No.");
                    //     GSTNO := gstregistrationNoRec."Einv Demo GST REgistration No.";

                    // end else
                    GSTNO := LocationL."GST Registration No.";

                    SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL Extend E-way Bill Validity", '', LocationL."GST Registration No.", false);
                    if JObject.ReadFrom(ResponseText) then
                        if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin

                            if JObject.Contains('ValidUpto') then
                                Rec."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                            Rec.Modify();
                            Message(VehicleUpdated, SalesCrMemo."No.");
                        end else
                            Error(ResponseText);



                end;
            rec."Document Type"::TransferShpt:
                begin



                    TransferShip.get(rec."Document No.");
                    LocationL.get(TransferShip."Transfer-from Code");
                    JobjectL.add('EwbNumber', rec."E-Way Bill No.");
                    JobjectL.add('FromPlace', rec."From Place");
                    JobjectL.add('FromPincode', LocationL."Post Code");
                    StateL.get(rec."From State");
                    JobjectL.add('FromState', StateL."State Code (GST Reg. No.)");

                    JobjectL.add('ReasonCode', format(rec."Extend E-way Reason Code"));
                    Rec.testfield("Extend E-way Reason Code");
                    Rec.testfield("Extend E-way  Remark");
                    JobjectL.add('ReasonRemark', rec."Extend E-way  Remark");
                    JobjectL.add('TransMode', TransferShip."Shipment Method Code");
                    JobjectL.add('TransDocDt', Format(TransferShip."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                    JobjectL.add('TransDocNo', TransferShip."LR/RR No.");
                    JobjectL.add('DocumentNumber', rec."Document No.");
                    JobjectL.add('DocumentType', 'INV');
                    JobjectL.add('DocumentDate', Format(TransferShip."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));

                    if TransferShip."Vehicle Type" = TransferShip."Vehicle Type"::Regular then
                        JObject.Add('VehicleType', 'R')
                    else
                        if TransferShip."Vehicle Type" = TransferShip."Vehicle Type"::ODC then
                            JObject.Add('VehicleType', 'O')
                        else
                            JObject.Add('VehicleType', 'R');
                    //   JobjectL.add('VehicleType', format(SalesInvoice."Vehicle Type"));
                    JobjectL.add('VehNo', TransferShip."Vehicle No.");

                    JobjectL.add('ConsignmentStatus', 'MOVEMENT');
                    rec.TestField("Remaining Distnce");
                    JobjectL.add('RemainingDistance', rec."Remaining Distnce");



                    docNo := rec."Document No.";
                    JObjectL.WriteTo(RequestText);
                    EInvoiceSetupL.get;
                    // if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                    //     gstregistrationNoRec.get(locationl."GST Registration No.");
                    //     GSTNO := gstregistrationNoRec."Einv Demo GST REgistration No.";

                    // end else
                    GSTNO := LocationL."GST Registration No.";

                    SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL Extend E-way Bill Validity", '', LocationL."GST Registration No.", false);
                    if JObject.ReadFrom(ResponseText) then
                        if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin

                            if JObject.Contains('ValidUpto') then
                                Rec."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                            Rec.Modify();
                            Message(VehicleUpdated, TransferShip."No.");
                        end else
                            Error(ResponseText);


                end;
            rec."Document Type"::"Purch Cr. Memo Hdr":
                begin

                    PurchCrMemoHdr.get(rec."Document No.");
                    LocationL.get(PurchCrMemoHdr."Location Code");
                    JobjectL.add('EwbNumber', rec."E-Way Bill No.");
                    JobjectL.add('FromPlace', PurchCrMemoHdr."Buy-from City");
                    JobjectL.add('FromPincode', PurchCrMemoHdr."Buy-from Post Code");
                    StateL.get(rec."From State");
                    JobjectL.add('FromState', StateL."State Code (GST Reg. No.)");

                    JobjectL.add('ReasonCode', format(rec."Extend E-way Reason Code"));
                    Rec.testfield("Extend E-way Reason Code");
                    Rec.testfield("Extend E-way  Remark");
                    JobjectL.add('ReasonRemark', rec."Extend E-way  Remark");
                    JobjectL.add('TransMode', PurchCrMemoHdr."Shipment Method Code");
                    JobjectL.add('TransDocDt', Format(PurchCrMemoHdr."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                    JobjectL.add('TransDocNo', PurchCrMemoHdr."LR/RR No.");
                    JobjectL.add('DocumentNumber', rec."Document No.");
                    JobjectL.add('DocumentType', 'INV');
                    JobjectL.add('DocumentDate', Format(PurchCrMemoHdr."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));

                    if PurchCrMemoHdr."Vehicle Type" = PurchCrMemoHdr."Vehicle Type"::Regular then
                        JObject.Add('VehicleType', 'R')
                    else
                        if PurchCrMemoHdr."Vehicle Type" = PurchCrMemoHdr."Vehicle Type"::ODC then
                            JObject.Add('VehicleType', 'O')
                        else
                            JObject.Add('VehicleType', 'R');
                    //   JobjectL.add('VehicleType', format(SalesInvoice."Vehicle Type"));
                    JobjectL.add('VehNo', PurchCrMemoHdr."Vehicle No.");


                    JobjectL.add('ConsignmentStatus', 'MOVEMENT');
                    rec.TestField("Remaining Distnce");
                    JobjectL.add('RemainingDistance', rec."Remaining Distnce");


                    docNo := rec."Document No.";
                    JObjectL.WriteTo(RequestText);
                    EInvoiceSetupL.get;
                    // if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                    //     gstregistrationNoRec.get(locationl."GST Registration No.");
                    //     GSTNO := gstregistrationNoRec."Einv Demo GST REgistration No.";

                    // end else
                    GSTNO := LocationL."GST Registration No.";

                    SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL Extend E-way Bill Validity", '', LocationL."GST Registration No.", false);
                    if JObject.ReadFrom(ResponseText) then
                        if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin

                            if JObject.Contains('ValidUpto') then
                                Rec."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                            Rec.Modify();
                            Message(VehicleUpdated, SalesInvoice."No.");
                        end else
                            Error(ResponseText);


                end;


            rec."Document Type"::"Purch. Inv. Hdr":
                begin

                    PurchInvHeader.get(rec."Document No.");
                    LocationL.get(PurchInvHeader."Location Code");
                    JobjectL.add('EwbNumber', rec."E-Way Bill No.");

                    if PurchInvHeader."Buy-from Country/Region Code" <> 'IN' then begin

                        EntryPoint.get(PurchInvHeader."Entry Point");
                        JobjectL.add('FromPincode', EntryPoint."Post Code");
                        JobjectL.add('FromPlace', EntryPoint.City);
                        StateL.get(EntryPoint."State Code");
                        JobjectL.add('FromState', StateL."State Code (GST Reg. No.)");
                    end else begin
                        vendorL.get(PurchInvHeader."Buy-from Vendor No.");
                        JobjectL.add('FromPincode', PurchInvHeader."Buy-from Post Code");
                        JobjectL.add('FromPlace', EntryPoint.City);
                        StateL.get(vendorL."State Code");
                        JobjectL.add('FromState', StateL."State Code (GST Reg. No.)");
                    end;





                    JobjectL.add('ReasonCode', format(rec."Extend E-way Reason Code"));
                    Rec.testfield("Extend E-way Reason Code");
                    Rec.testfield("Extend E-way  Remark");
                    JobjectL.add('ReasonRemark', rec."Extend E-way  Remark");
                    JobjectL.add('TransMode', PurchInvHeader."Shipment Method Code");
                    JobjectL.add('TransDocDt', Format(PurchInvHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                    JobjectL.add('TransDocNo', PurchInvHeader."LR/RR No.");
                    JobjectL.add('DocumentNumber', rec."Document No.");
                    JobjectL.add('DocumentType', 'INV');
                    JobjectL.add('DocumentDate', Format(PurchInvHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));

                    if PurchInvHeader."Vehicle Type" = PurchInvHeader."Vehicle Type"::Regular then
                        JObject.Add('VehicleType', 'R')
                    else
                        if PurchInvHeader."Vehicle Type" = PurchInvHeader."Vehicle Type"::ODC then
                            JObject.Add('VehicleType', 'O')
                        else
                            JObject.Add('VehicleType', 'R');
                    //   JobjectL.add('VehicleType', format(SalesInvoice."Vehicle Type"));
                    JobjectL.add('VehNo', PurchInvHeader."Vehicle No.");


                    JobjectL.add('ConsignmentStatus', 'MOVEMENT');
                    rec.TestField("Remaining Distnce");
                    JobjectL.add('RemainingDistance', rec."Remaining Distnce");


                    docNo := rec."Document No.";
                    JObjectL.WriteTo(RequestText);
                    EInvoiceSetupL.get;
                    // if EInvoiceSetupL."Integration Mode" = EInvoiceSetupL."Integration Mode"::ClearTaxDemo then begin
                    //     gstregistrationNoRec.get(locationl."GST Registration No.");
                    //     GSTNO := gstregistrationNoRec."Einv Demo GST REgistration No.";

                    // end else
                    GSTNO := LocationL."GST Registration No.";

                    SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL Extend E-way Bill Validity", '', LocationL."GST Registration No.", false);
                    if JObject.ReadFrom(ResponseText) then
                        if (GetValueFromJsonObject(JObject, 'UpdatedDate').AsText() > '') then begin

                            if JObject.Contains('ValidUpto') then
                                Rec."E-Way Bill Validity" := GetValueFromJsonObject(JObject, 'ValidUpto').AsText();

                            Rec.Modify();
                            Message(VehicleUpdated, SalesInvoice."No.");
                        end else
                            Error(ResponseText);


                end;

        end;
    end;

    local procedure GetTaxableAmountTransfer(DocNo: Code[20]):
                                Decimal
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

    procedure SendRequest(Method: Text; RequestTextP: Text; var ResponseText: Text; URL: Text; OwnerID: Text; GSTNo: Text; ForPDF: Boolean)
    var
        HttpSendMessage: Codeunit "ClearComp Http Send Message";
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        ErrorText: Text;
        ResponseTextL: Text;
        RequestStream: InStream;
        ResponseStream: InStream;
        JObjectResponse: JsonObject;
        SuccessText: Code[1];
        ServerFileName: Text;
        FileManagementL: Codeunit "File Management";
        OutstreamL: OutStream;
        Outstream2L: OutStream;
        FileName: Text;
        FileL: File;
        TempBlobUnit: Codeunit "Temp Blob";
        base64byte: Codeunit "Base64 Convert";
        Base64Text: text;
        GSTRegistration: Record "GST Registration Nos.";
    begin
        EInvoiceSetup.Get();
        Clear(HttpSendMessage);
        Clear(ResponseText);
        Clear(ErrorText);

        HttpSendMessage.SetHttpHeader('X-ClearTax-AUTH-TOKEN', EInvoiceSetup."Auth Token");
        HttpSendMessage.SetMethod(Method);
        if ForPDF then begin
            HttpSendMessage.SetContentType('application/json');
            HttpSendMessage.SetReturnType('application/pdf');
        end else begin
            HttpSendMessage.SetContentType('application/json');
            HttpSendMessage.SetReturnType('application/json');
        end;
        if EInvoiceSetup."Integration Mode" = EInvoiceSetup."Integration Mode"::ClearTaxDemo then begin
            GSTRegistration.get(GSTNo);
            HttpSendMessage.SetHttpHeader('gstin', GSTRegistration."Einv Demo GST REgistration No.");
            //HttpSendMessage.SetHttpHeader('owner_id', OwnerID);
        end else
            HttpSendMessage.SetHttpHeader('gstin', GSTNo);
        // if GSTNo <> '' then
        //     HttpSendMessage.SetHttpHeader('gstin', GSTNo);
        // if not ForPDF then
        //     HttpSendMessage.SetHttpHeader('x-cleartax-product', 'Einvoice');

        HttpSendMessage.AddUrl(url);
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

                clear(TempBlobUnit);
                //RRAm
                docNo := DELCHR(docNo, '=', ' ,/-<>  !@#$%^&*()_+{}');
                ServerFileName := docNo + '.pdf';
                TempBlobUnit.CreateOutStream(OutStreamL);
                CopyStream(OutStreamL, ResponseStream);
                FileManagementL.BLOBExport(TempBlobUnit, ServerFileName, true);

            end else begin
                ResponseStream.ReadText(ResponseText);
                if EInvoiceSetup."Show Payload" then
                    Message(ResponseText);
            end;
        end else begin
            ErrorText := HttpSendMessage.Reason();
            if ErrorText > '' then begin

                Message('Einvoice/ Eway generation Failed with following error:' + ErrorText);
            end;

        end;

        CreateMessageLog(Method, RequestTextP, Format(HttpSendMessage.StatusCode()), URL + docNo, ResponseText + ErrorText, docNo);
        Commit();
    end;

    local procedure CreateMessageLog(MethodP: Text; MessageTextP: Text; StatusCodeP: Text; UrlP: Text; responseText: text; DocumentNo: code[20])
    var
        InterfMessageLog: Record "ClearComp Interface Msg Log";
        OutstreamRes: OutStream;
        OutStreamReq: OutStream;
        einvSetup: Record "ClearComp e-Invocie Setup";
    begin
        einvSetup.Get();
        if einvSetup."Create Message Log" then begin
            //  InterfMessageLog."Entry No." := GetLastEntryNo();
            InterfMessageLog."Request Type" := MethodP + '-' + UrlP;
            InterfMessageLog.Request.CREATEOUTSTREAM(OutStreamReq);
            OutStreamReq.WRITETEXT(MessageTextP);
            InterfMessageLog."Response Code" := StatusCodeP;
            InterfMessageLog.Response.CREATEOUTSTREAM(OutstreamRes);
            OutstreamRes.WRITETEXT(ResponseText);
            InterfMessageLog."Document No." := DocumentNo;
            InterfMessageLog.INSERT(TRUE);
        end;
        Commit();

    end;

    local procedure ReadCrMemoBuyerDetails(SalesCrMemoHeader: record "sales cr.Memo Header")
    var
        Contact: Record Contact;
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ShiptoAddress: Record "Ship-to Address";
        StateBuff: Record State;
        GSTRegistrationNumber: Text[20];
        CompanyName: Text[100];
        Address: Text[100];
        Address2: Text[100];
        Floor: Text[60];
        AddressLocation: Text[60];
        City: Text[60];
        PostCode: Text[6];
        StateCode: Text[10];
        PhoneNumber: Text[10];
        Email: Text[50];
    begin
        GSTRegistrationNumber := SalesCrMemoHeader."Customer GST Reg. No.";
        CompanyName := SalesCrMemoHeader."Bill-to Name";
        Address := SalesCrMemoHeader."Bill-to Address";
        Address2 := SalesCrMemoHeader."Bill-to Address 2";

        Floor := '';
        AddressLocation := SalesCrMemoHeader."Bill-to City";
        City := SalesCrMemoHeader."Bill-to City";
        PostCode := CopyStr(SalesCrMemoHeader."Bill-to Post Code", 1, 6);
        StateCode := '';
        PhoneNumber := '';
        Email := '';

        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.FindFirst() then
            case SalesCrMemoLine."GST Place of Supply" of

                SalesCrMemoLine."GST Place of Supply"::"Bill-to Address":
                    begin
                        if not (SalesCrMemoHeader."GST Customer Type" = SalesCrMemoHeader."GST Customer Type"::Export) then begin
                            StateBuff.Get(SalesCrMemoHeader."GST Bill-to State Code");
                            StateCode := StateBuff."State Code (GST Reg. No.)";
                        end;

                        if Contact.Get(SalesCrMemoHeader."Bill-to Contact No.") then begin
                            PhoneNumber := CopyStr(Contact."Phone No.", 1, 10);
                            Email := CopyStr(Contact."E-Mail", 1, 50);
                        end;
                    end;

                SalesCrMemoLine."GST Place of Supply"::"Ship-to Address":
                    begin
                        if not (SalesCrMemoHeader."GST Customer Type" = SalesCrMemoHeader."GST Customer Type"::Export) then begin
                            StateBuff.Get(SalesCrMemoHeader."GST Ship-to State Code");
                            StateCode := StateBuff."State Code (GST Reg. No.)";
                        end;

                        if ShiptoAddress.Get(SalesCrMemoHeader."Sell-to Customer No.", SalesCrMemoHeader."Ship-to Code") then begin
                            PhoneNumber := CopyStr(ShiptoAddress."Phone No.", 1, 10);
                            Email := CopyStr(ShiptoAddress."E-Mail", 1, 50);
                        end;
                    end;
            end;
        if SalesCrMemoHeader."Bill-to Country/Region Code" <> 'IN' then begin
            StateCode := '96';
            PostCode := '999999';
        end;
        if SalesCrMemoHeader."GST Customer Type" = SalesCrMemoHeader."GST Customer Type"::Export then begin

            StateCode := '96';
            PostCode := '999999';
            GSTRegistrationNumber := 'URP';
        end;

        if StateCode = '' then begin
            StateBuff.Get(SalesCrMemoHeader."GST Bill-to State Code");
            StateCode := StateBuff."State Code (GST Reg. No.)";
        end;
        //::RRAk
        if Address2 = '' Then
            Address2 := Address;
        WriteBuyerDetails(GSTRegistrationNumber, CompanyName, Address, Address2, Floor, AddressLocation, City, PostCode, StateCode, PhoneNumber, Email);
    end;

    local procedure WriteBuyerDetails(
        GSTRegistrationNumber: Text[20];
        CompanyName: Text[100];
        Address: Text[100];
        Address2: Text[100];
        Floor: Text[60];
        AddressLocation: Text[60];
        City: Text[60];
        PostCode: Text[6];
        StateCode: Text[10];
        PhoneNumber: Text[10];
        EmailID: Text[50])
    var
        JBuyerDetails: JsonObject;
        PinInt: Integer;
    begin
        JBuyerDetails.Add('Gstin', GSTRegistrationNumber);
        JBuyerDetails.Add('LglNm', CompanyName);
        JBuyerDetails.Add('TrdNm', CompanyName);
        JBuyerDetails.Add('Addr1', Address);
        JBuyerDetails.Add('Addr2', Address2);
        JBuyerDetails.Add('Flno', Floor);
        JBuyerDetails.Add('Loc', AddressLocation);
        JBuyerDetails.Add('Dst', City);
        evaluate(PinInt, PostCode);
        JBuyerDetails.Add('Pin', PinInt);
        //  JBuyerDetails.Add('Pin', PostCode);
        JBuyerDetails.Add('Stcd', StateCode);
        JBuyerDetails.Add('Pos', StateCode);

        if strlen(DELCHR(PhoneNumber, '=', ' ,/-<>  !@#$%^&*()_+{}')) > 6 then
            JBuyerDetails.Add('Ph', DELCHR(PhoneNumber, '=', ' ,/-<>  !@#$%^&*()_+{}'));
        if EmailID > '' then
            JBuyerDetails.Add('Em', EmailID);

        //  JsonArrayData.Add(JBuyerDetails);
        JObject.Add('SellerDtls', JBuyerDetails);
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

    local procedure CreateLogEntry(DocNo: Text;
     DocType: Option " ",Invoice,CrMemo,TransferShpt,"Service Invoice","Service Credit Memo","Purch Cr. Memo Hdr";
      DocDate: Date;
      RequestText: Text;
      ResponseText: Text;
       EWayBillNo: Text; EWayBillDT: Text;
        EWayBillExpirationDT: Text;
        StatusText: Text;
        var EInvoiceLogEntry: Record "ClearComp e-Invoice Entry")
    var
        OutstreamL: OutStream;
        Outstream2L: OutStream;
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
        EInvoiceLogEntry."Response JSON".CREATEOUTSTREAM(Outstream2L);
        JObject.WriteTo(TextVar);
        Outstream2L.WRITETEXT(TextVar);
        EInvoiceLogEntry."User Id" := USERID;
        EInvoiceLogEntry."Status Text" := StatusText;
        EInvoiceLogEntry."E-Way Bill No." := EWayBillNo;
        EInvoiceLogEntry."E-Way Bill Date" := EWayBillDT;
        EInvoiceLogEntry."E-Way Bill Validity" := EWayBillExpirationDT;
        EInvoiceLogEntry."Created Date Time" := CurrentDateTime();
        EInvoiceLogEntry."Created By" := UserId;
        if UserId = 'APMDCBC' then
            EInvoiceLogEntry."Created Date Time Text" := Format(CurrentDateTime + (1800000 + 18000000))
        else
            EInvoiceLogEntry."Created Date Time Text" := Format(CurrentDateTime);
        // EInvoiceLogEntry."Created Date Time Text" := Format(CurrentDateTime + (1800000 + 18000000));

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
        //rra
        //    if EInvoiceLogEntryL.FindFirst() then
        //      Error(EWayGeneratedErr, DocNoP);
    end;

    local procedure GetUOM(UOMCode: Code[10]): Text
    var
        UnitofMeasure: Record "Unit of Measure";
    begin
        //if ((UnitofMeasure.Get(UOMCode)) and (UnitofMeasure."GST Reporting UQC" > '')) then
        //EXIT(UnitofMeasure."GST Reporting UQC")
        //else
        EXIT(UOMCode);
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

    local procedure GetGSTAmountSalesShipment(DocNo: Code[20]; CompCode: Code[10]): Decimal
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        GSTAmt: Decimal;
        SalesShipmentLine: record "Sales Shipment Line";
        SalesLine: record "Sales Line";
        Rec_TaxTrans: record "Tax Transaction Value";
        ComponentAmount: Decimal;
        TaxRate: Decimal;
        PerQtyLineAmount: decimal;
    begin

        SalesShipmentLine.SetRange("Document No.", DocNo);
        SalesShipmentLine.SetFilter(Quantity, '<>%1', 0);
        SalesShipmentLine.setfilter("Quantity Invoiced", '>%1', 0);
        if SalesShipmentLine.findfirst then
            error('Invoice already generated , Kindly used Posted invoice screen to generate e-way Bill');

        SalesShipmentLine.setrange("Quantity Invoiced", 0);
        //SalesInvoiceLine.CalcSums("GST Base Amount");
        //if SalesInvoiceLine."GST Base Amount" <> 0 then
        //EXIT(SalesShipmentLine."GST Base Amount");
        SalesShipmentLine.FindSet();
        repeat
            SalesLine.setrange("document type", salesline."document Type"::order);
            salesline.SetRange("document No.", SalesShipmentLine."order no.");
            salesline.SetRange("line no.", SalesShipmentLine."order line no.");
            if salesLine.findfirst then begin

                Rec_TaxTrans.Reset();
                Rec_TaxTrans.SetRange("Tax Record ID", salesLine.RecordId);
                Rec_TaxTrans.SetRange("Tax Type", 'GST');
                Rec_TaxTrans.SetRange("Value Type", Rec_TaxTrans."Value Type"::COMPONENT);
                Rec_TaxTrans.SetFilter(Percent, '<>%1', 0);
                if CompCode = 'CGST' then
                    Rec_TaxTrans.setrange("Value ID", 2);

                if CompCode = 'SGST' then
                    Rec_TaxTrans.setrange("Value ID", 6);
                if CompCode = 'IGST' then
                    Rec_TaxTrans.setrange("Value ID", 3);
                if CompCode = 'CESS' then
                    Rec_TaxTrans.setrange("Value ID", 300);


                if Rec_TaxTrans.FindFirst() then begin
                    repeat

                        TaxRate := Rec_TaxTrans.Percent;
                        ComponentAmount += Rec_TaxTrans.Amount;


                    until Rec_TaxTrans.Next() = 0;
                end;

                PerQtyLineAmount := ComponentAmount / SalesLine.Quantity;
                GSTAmt := (PerQtyLineAmount * SalesShipmentLine.quantity);

            end;
        until salesshipmentline.next = 0;

        EXIT(GSTAmt);


    end;


    local procedure GetGSTRateSalesShipAmount(DocNo: Code[20]; CompCode: Code[10]; LineNo: Integer): Decimal
    var
        GSTAmt: Decimal;
        SalesShipmentLine: record "Sales Shipment Line";
        SalesLine: record "Sales Line";
        Rec_TaxTrans: record "Tax Transaction Value";
        ComponentAmount: Decimal;
        TaxRate: Decimal;
        PerQtyLineAmount: decimal;
    begin

        SalesShipmentLine.SetRange("Document No.", DocNo);
        SalesShipmentLine.SetFilter(Quantity, '<>%1', 0);
        SalesShipmentLine.setfilter("Quantity Invoiced", '>%1', 0);
        SalesShipmentLine.SetRange("Line No.", LineNo);
        if SalesShipmentLine.findfirst then
            error('Invoice already generated , Kindly used Posted invoice screen to generate e-way Bill');

        SalesShipmentLine.setrange("Quantity Invoiced", 0);
        //SalesInvoiceLine.CalcSums("GST Base Amount");
        //if SalesInvoiceLine."GST Base Amount" <> 0 then
        //EXIT(SalesShipmentLine."GST Base Amount");
        SalesShipmentLine.FindSet();
        repeat
            SalesLine.setrange("document type", salesline."document Type"::order);
            salesline.SetRange("document No.", SalesShipmentLine."Order No.");
            salesline.SetRange("line no.", SalesShipmentLine."order line no.");
            if salesLine.findfirst then begin

                // Rec_TaxTrans.Reset();
                // Rec_TaxTrans.SetRange("Tax Record ID", salesLine.RecordId);
                // Rec_TaxTrans.SetRange("Tax Type", 'GST');
                // Rec_TaxTrans.SetRange("Value Type", Rec_TaxTrans."Value Type"::COMPONENT);
                // Rec_TaxTrans.SetFilter(Percent, '<>%1', 0);
                // if CompCode = 'CGST' then
                //     Rec_TaxTrans.setrange("Value ID", 2);

                // if CompCode = 'SGST' then
                //     Rec_TaxTrans.setrange("Value ID", 6);
                // if CompCode = 'IGST' then
                //     Rec_TaxTrans.setrange("Value ID", 3);


                // if Rec_TaxTrans.FindFirst() then begin
                //     repeat

                //         TaxRate := Rec_TaxTrans.Percent;
                //         ComponentAmount += Rec_TaxTrans.Amount;


                //     until Rec_TaxTrans.Next() = 0;
                // end;

                PerQtyLineAmount := SalesLine."Line Amount" / SalesLine.Quantity;
                GSTAmt := GSTAmt + (PerQtyLineAmount * SalesShipmentLine.quantity);

            end;
        until salesshipmentline.next = 0;

        EXIT(GSTAmt);



    end;

    local procedure GetGSTRateSalesShip(DocNo: Code[20]; CompCode: Code[10]; LineNo: Integer): Decimal
    var
        GSTAmt: Decimal;
        SalesShipmentLine: record "Sales Shipment Line";
        SalesLine: record "Sales Line";
        Rec_TaxTrans: record "Tax Transaction Value";
        ComponentAmount: Decimal;
        TaxRate: Decimal;
        PerQtyLineAmount: decimal;
    begin

        SalesShipmentLine.SetRange("Document No.", DocNo);
        SalesShipmentLine.SetFilter(Quantity, '<>%1', 0);
        SalesShipmentLine.setfilter("Quantity Invoiced", '>%1', 0);
        SalesShipmentLine.SetRange("Line No.", LineNo);
        if SalesShipmentLine.findfirst then
            error('Invoice already generated , Kindly used Posted invoice screen to generate e-way Bill');

        SalesShipmentLine.setrange("Quantity Invoiced", 0);
        //SalesInvoiceLine.CalcSums("GST Base Amount");
        //if SalesInvoiceLine."GST Base Amount" <> 0 then
        //EXIT(SalesShipmentLine."GST Base Amount");
        SalesShipmentLine.FindSet();
        repeat
            SalesLine.setrange("document type", salesline."document Type"::order);
            salesline.SetRange("document No.", SalesShipmentLine."Order No.");
            salesline.SetRange("line no.", SalesShipmentLine."order line no.");
            if salesLine.findfirst then begin

                Rec_TaxTrans.Reset();
                Rec_TaxTrans.SetRange("Tax Record ID", salesLine.RecordId);
                Rec_TaxTrans.SetRange("Tax Type", 'GST');
                Rec_TaxTrans.SetRange("Value Type", Rec_TaxTrans."Value Type"::COMPONENT);
                Rec_TaxTrans.SetFilter(Percent, '<>%1', 0);
                if CompCode = 'CGST' then
                    Rec_TaxTrans.setrange("Value ID", 2);

                if CompCode = 'SGST' then
                    Rec_TaxTrans.setrange("Value ID", 6);
                if CompCode = 'IGST' then
                    Rec_TaxTrans.setrange("Value ID", 3);

                if CompCode = 'CESS' then
                    Rec_TaxTrans.setrange("Value ID", 300);


                if Rec_TaxTrans.FindFirst() then begin
                    repeat

                        TaxRate := Rec_TaxTrans.Percent;
                        ComponentAmount += Rec_TaxTrans.Amount;


                    until Rec_TaxTrans.Next() = 0;
                end;

                //    PerQtyLineAmount := ComponentAmount / SalesLine.Quantity;
                //  GSTAmt := GSTAmt + (PerQtyLineAmount * SalesShipmentLine.quantity);

            end;
        until salesshipmentline.next = 0;

        EXIT(TaxRate);



    end;



    //???


    local procedure GetGSTAmountServiceShipment(DocNo: Code[20]; CompCode: Code[10]): Decimal
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        GSTAmt: Decimal;
        SalesShipmentLine: record "Service Shipment Line";
        SalesLine: record "Service Line";
        Rec_TaxTrans: record "Tax Transaction Value";
        ComponentAmount: Decimal;
        TaxRate: Decimal;
        PerQtyLineAmount: decimal;
    begin

        SalesShipmentLine.SetRange("Document No.", DocNo);
        SalesShipmentLine.SetFilter(Quantity, '<>%1', 0);
        SalesShipmentLine.setfilter("Quantity Invoiced", '>%1', 0);
        if SalesShipmentLine.findfirst then
            error('Invoice already generated , Kindly used Posted invoice screen to generate e-way Bill');

        SalesShipmentLine.setrange("Quantity Invoiced", 0);
        //SalesInvoiceLine.CalcSums("GST Base Amount");
        //if SalesInvoiceLine."GST Base Amount" <> 0 then
        //EXIT(SalesShipmentLine."GST Base Amount");
        SalesShipmentLine.FindSet();
        repeat
            SalesLine.setrange("document type", salesline."document Type"::order);
            salesline.SetRange("document No.", SalesShipmentLine."order no.");
            salesline.SetRange("line no.", SalesShipmentLine."order line no.");
            if salesLine.findfirst then begin

                Rec_TaxTrans.Reset();
                Rec_TaxTrans.SetRange("Tax Record ID", salesLine.RecordId);
                Rec_TaxTrans.SetRange("Tax Type", 'GST');
                Rec_TaxTrans.SetRange("Value Type", Rec_TaxTrans."Value Type"::COMPONENT);
                Rec_TaxTrans.SetFilter(Percent, '<>%1', 0);
                if CompCode = 'CGST' then
                    Rec_TaxTrans.setrange("Value ID", 2);

                if CompCode = 'SGST' then
                    Rec_TaxTrans.setrange("Value ID", 6);
                if CompCode = 'IGST' then
                    Rec_TaxTrans.setrange("Value ID", 3);
                if CompCode = 'CESS' then
                    Rec_TaxTrans.setrange("Value ID", 300);


                if Rec_TaxTrans.FindFirst() then begin
                    repeat

                        TaxRate := Rec_TaxTrans.Percent;
                        ComponentAmount += Rec_TaxTrans.Amount;


                    until Rec_TaxTrans.Next() = 0;
                end;

                PerQtyLineAmount := ComponentAmount / SalesLine.Quantity;
                GSTAmt := (PerQtyLineAmount * SalesShipmentLine.quantity);

            end;
        until salesshipmentline.next = 0;

        EXIT(GSTAmt);


    end;


    local procedure GetGSTRateServiceShipLineAmount(DocNo: Code[20]; CompCode: Code[10]; LineNo: Integer): Decimal
    var
        GSTAmt: Decimal;
        SalesShipmentLine: record "Service Shipment Line";
        SalesLine: record "Service Line";
        Rec_TaxTrans: record "Tax Transaction Value";
        ComponentAmount: Decimal;
        TaxRate: Decimal;
        PerQtyLineAmount: decimal;
    begin

        SalesShipmentLine.SetRange("Document No.", DocNo);
        SalesShipmentLine.SetFilter(Quantity, '<>%1', 0);
        SalesShipmentLine.setfilter("Quantity Invoiced", '>%1', 0);
        SalesShipmentLine.SetRange("Line No.", LineNo);
        if SalesShipmentLine.findfirst then
            error('Invoice already generated , Kindly used Posted invoice screen to generate e-way Bill');

        SalesShipmentLine.setrange("Quantity Invoiced", 0);
        //SalesInvoiceLine.CalcSums("GST Base Amount");
        //if SalesInvoiceLine."GST Base Amount" <> 0 then
        //EXIT(SalesShipmentLine."GST Base Amount");
        SalesShipmentLine.FindSet();
        repeat
            SalesLine.setrange("document type", salesline."document Type"::order);
            salesline.SetRange("document No.", SalesShipmentLine."Order No.");
            salesline.SetRange("line no.", SalesShipmentLine."order line no.");
            if salesLine.findfirst then begin

                // Rec_TaxTrans.Reset();
                // Rec_TaxTrans.SetRange("Tax Record ID", salesLine.RecordId);
                // Rec_TaxTrans.SetRange("Tax Type", 'GST');
                // Rec_TaxTrans.SetRange("Value Type", Rec_TaxTrans."Value Type"::COMPONENT);
                // Rec_TaxTrans.SetFilter(Percent, '<>%1', 0);
                // if CompCode = 'CGST' then
                //     Rec_TaxTrans.setrange("Value ID", 2);

                // if CompCode = 'SGST' then
                //     Rec_TaxTrans.setrange("Value ID", 6);
                // if CompCode = 'IGST' then
                //     Rec_TaxTrans.setrange("Value ID", 3);


                // if Rec_TaxTrans.FindFirst() then begin
                //     repeat

                //         TaxRate := Rec_TaxTrans.Percent;
                //         ComponentAmount += Rec_TaxTrans.Amount;


                //     until Rec_TaxTrans.Next() = 0;
                // end;

                PerQtyLineAmount := SalesLine."Line Amount" / SalesLine.Quantity;
                GSTAmt := GSTAmt + (PerQtyLineAmount * SalesShipmentLine.quantity);

            end;
        until salesshipmentline.next = 0;

        EXIT(GSTAmt);



    end;

    local procedure GetGSTRateServiceShip(DocNo: Code[20]; CompCode: Code[10]; LineNo: Integer): Decimal
    var
        GSTAmt: Decimal;
        SalesShipmentLine: record "Service Shipment Line";
        SalesLine: record "Service Line";
        Rec_TaxTrans: record "Tax Transaction Value";
        ComponentAmount: Decimal;
        TaxRate: Decimal;
        PerQtyLineAmount: decimal;
    begin

        SalesShipmentLine.SetRange("Document No.", DocNo);
        SalesShipmentLine.SetFilter(Quantity, '<>%1', 0);
        SalesShipmentLine.setfilter("Quantity Invoiced", '>%1', 0);
        SalesShipmentLine.SetRange("Line No.", LineNo);
        if SalesShipmentLine.findfirst then
            error('Invoice already generated , Kindly used Posted invoice screen to generate e-way Bill');

        SalesShipmentLine.setrange("Quantity Invoiced", 0);
        //SalesInvoiceLine.CalcSums("GST Base Amount");
        //if SalesInvoiceLine."GST Base Amount" <> 0 then
        //EXIT(SalesShipmentLine."GST Base Amount");
        SalesShipmentLine.FindSet();
        repeat
            SalesLine.setrange("document type", salesline."document Type"::order);
            salesline.SetRange("document No.", SalesShipmentLine."Order No.");
            salesline.SetRange("line no.", SalesShipmentLine."order line no.");
            if salesLine.findfirst then begin

                Rec_TaxTrans.Reset();
                Rec_TaxTrans.SetRange("Tax Record ID", salesLine.RecordId);
                Rec_TaxTrans.SetRange("Tax Type", 'GST');
                Rec_TaxTrans.SetRange("Value Type", Rec_TaxTrans."Value Type"::COMPONENT);
                Rec_TaxTrans.SetFilter(Percent, '<>%1', 0);
                if CompCode = 'CGST' then
                    Rec_TaxTrans.setrange("Value ID", 2);

                if CompCode = 'SGST' then
                    Rec_TaxTrans.setrange("Value ID", 6);
                if CompCode = 'IGST' then
                    Rec_TaxTrans.setrange("Value ID", 3);

                if CompCode = 'CESS' then
                    Rec_TaxTrans.setrange("Value ID", 300);


                if Rec_TaxTrans.FindFirst() then begin
                    repeat

                        TaxRate := Rec_TaxTrans.Percent;
                        ComponentAmount += Rec_TaxTrans.Amount;


                    until Rec_TaxTrans.Next() = 0;
                end;

                //    PerQtyLineAmount := ComponentAmount / SalesLine.Quantity;
                //  GSTAmt := GSTAmt + (PerQtyLineAmount * SalesShipmentLine.quantity);

            end;
        until salesshipmentline.next = 0;

        EXIT(TaxRate);



    end;


    //????

    local procedure GetGSTRate(DocNo: Code[20]; CompCode: Code[10]; LineNo: Integer): Decimal
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntry.SetCurrentKey("Document No.", "Document Line No.", "GST Component Code");
        DetailedGSTLedgerEntry.SetRange("Document No.", DocNo);
        DetailedGSTLedgerEntry.SetRange("Document Line No.", LineNo);
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CompCode);
        if DetailedGSTLedgerEntry.FindFirst() then
            if DetailedGSTLedgerEntry."GST Amount" > 0 then
                EXIT(Round(DetailedGSTLedgerEntry."GST %", 0.01));
        EXIT(0);
    end;

    procedure UpdateVehicleNo(var EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    begin
        case
                EInvoiceEntryP."Document Type" of
            EInvoiceEntryP."Document Type"::Invoice:
                UpdateVehicleNoSalesInvoice(EInvoiceEntryP);
            EInvoiceEntryP."Document Type"::"Purch Cr. Memo Hdr":
                UpdateVehicleNoPurchaseCrMemo(EInvoiceEntryP);
            EInvoiceEntryP."Document Type"::CrMemo:
                UpdateVehicleNoSalesCrMemo(EInvoiceEntryP);
            EInvoiceEntryP."Document Type"::TransferShpt:
                UpdateVehicleNoTransferShipment(EInvoiceEntryP);
            EInvoiceEntryP."Document Type"::"Sales Shipment":
                UpdateVehicleNoSalesshipment(EInvoiceEntryP);
            EInvoiceEntryP."Document Type"::"Service Shipment":
                UpdateVehicleNoServiceShipment(EInvoiceEntryP);
            EInvoiceEntryP."Document Type"::"Service Invoice":
                UpdateVehicleNoServiceInvoice(EInvoiceEntryP);
            EInvoiceEntryP."Document Type"::"purch. Inv. Hdr":
                UpdateVehicleNoPurchaseInv(EInvoiceEntryP);
        end;

    end;

    procedure CancelEWay(EInvoiceEntryP: Record "ClearComp e-Invoice Entry")
    begin

        case
            EInvoiceEntryP."Document Type" of
            EInvoiceEntryP."Document Type"::Invoice:
                CancelEWaySalesInvoice(EInvoiceEntryP);
            EInvoiceEntryP."Document Type"::"Purch Cr. Memo Hdr":
                CancelEWayPurchaseCrMemo(EInvoiceEntryP);
            EInvoiceEntryP."Document Type"::CrMemo:
                CancelEWaySalesCrMemo(EInvoiceEntryP);
            EInvoiceEntryP."Document Type"::TransferShpt:
                CancelEWayTransferShipment(EInvoiceEntryP);
            EInvoiceEntryP."Document Type"::"Sales Shipment":
                CancelEWaySalesshipment(EInvoiceEntryP);
            EInvoiceEntryP."Document Type"::"Service Shipment":
                CancelEWayServiceShip(EInvoiceEntryP);
            EInvoiceEntryP."Document Type"::"Service Invoice":
                CancelEWayServiceInvoice(EInvoiceEntryP);

            EInvoiceEntryP."Document Type"::"Purch. Inv. Hdr":
                CancelEWayPurchaseInv(EInvoiceEntryP);


        end;
    end;


    [TryFunction]
    local procedure getJobject(JObjectP: JsonObject; PropertyNameP: Text; var JTokenL: JsonToken)
    begin
        JObjectP.Get(PropertyNameP, JTokenL);
    end;

    local procedure GetValueFromJsonObject(JObjectP: JsonObject; PropertyNameP: Text) JValueR: JsonValue
    var
        JTokenL: JsonToken;
    begin
        if JObjectP.Contains(PropertyNameP) then begin
            getJobject(JObjectP, PropertyNameP, JTokenL);
            JValueR := JTokenL.AsValue();
            if not JValueR.IsNull then
                exit(JValueR)
            else
                JValueR.SetValue('');
        end else
            JValueR.SetValue('');
    end;



    procedure CreateJsonTransShipmentforIRN(var TransshipHeaderP: Record "Transfer Shipment Header")
    var
        TransshipHeader: Record "Transfer Shipment Header";
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        TransportMethodL: Record "Shipment Method";
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
        DistanceRemark: text;
        Jarrtext: text;
        JSubObjectL: JsonObject;
        JToken1L: JsonToken;
        JSubArray: JsonArray;
        ErrorDetails: TEXT;
        J: Integer;
        JTokenL: JsonToken;
        JObjectL: JsonObject;
        PostCode: Record "Post Code";
    begin
        TransshipHeader.Copy(TransshipHeaderP);
        if LocationL.Get(TransshipHeader."Transfer-from Code") then;
        EInvoiceSetupL.Get();

        CheckEwayBillStatus(TransshipHeaderP."No.", DocType::TransferShpt);
        if ShippingAgentL.Get(TransshipHeader."Shipping Agent Code") then;
        // LocationL.TestField("Post Code");
        CompanyInformationL.Get();
        JObject.Add('Irn', TransshipHeader."IRN Hash");

        if TransshipHeader."Distance (Km)" <> 0 then
            JObject.Add('Distance', TransshipHeader."Distance (Km)")
        else begin
            PostCode.reset;

        end;

        if ShippingAgentL."GST Registration No." > '' then
            JObject.Add('TransId', ShippingAgentL."GST Registration No.");
        if ShippingAgentL.Name > '' then
            JObject.Add('TransName', ShippingAgentL.Name);
        if TransshipHeader."LR/RR Date" <> 0D then
            JObject.Add('TransDocDt', Format(TransshipHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        if TransshipHeader."LR/RR No." <> '' then
            JObject.Add('TransDocNo', TransshipHeader."LR/RR No.");



        if TransshipHeader."Vehicle No." <> '' then begin

            TransshipHeader.TestField("Shipment Method code");
            TransshipHeader.TestField("Vehicle No.");
            TransshipHeader.TestField("LR/RR No.");
            TransshipHeader.TestField("LR/RR Date");
            JObject.Add('VehNo', TransshipHeader."Vehicle No.");

            TransportMethodL.get(TransshipHeader."Shipment Method Code");
            JObject.Add('TransMode', Format(TransportMethodL.code));
            if TransshipHeader."Vehicle Type" = TransshipHeader."Vehicle Type"::Regular then
                JObject.Add('VehType', 'R')
            else
                if TransshipHeader."Vehicle Type" = TransshipHeader."Vehicle Type"::ODC then
                    JObject.Add('VehType', 'O')
                else
                    JObject.Add('VehType', 'R')
        end;



        JArray.Add(JObject);
        JArray.WriteTo(RequestText);
        docNo := TransshipHeader."No.";
        SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."URL Eway By IRN", '', LocationL."GST Registration No.", false);

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

                    if JSubObject.Contains('info') then begin
                        JSubObject.Get('info', JToken1);
                        JToken1.WriteTo(Jarrtext);
                        if JArray.ReadFrom(Jarrtext) then begin

                            for I := 0 to JArray.Count - 1 do begin
                                JArray.Get(I, JToken);
                                JObject := JToken.AsObject();
                                DistanceRemark := GetValueFromJsonObject(JObject, 'Desc').AsText();

                            end;
                        end;
                    end;

                    CreateLogEntry(TransshipHeader."No.", DocType::TransferShpt, TransshipHeader."Posting Date", RequestText, ResponseText,
                      EWayBillNo, EWayBillDateTime, EWayExpirationDT, StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Generated;
                    EInvoiceEntryL."E-Way Generated" := true;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    EInvoiceEntryL."Reason of Cancel" := EInvoiceEntryL."Reason of Cancel"::" ";
                    EInvoiceEntryL."LR/RR Date" := TransshipHeader."LR/RR Date";
                    EInvoiceEntryL."LR/RR No." := TransshipHeader."LR/RR No.";
                    EInvoiceEntryL."Transport Method" := TransshipHeader."Shipment Method code";
                    EInvoiceEntryL."Shipping Agent Code" := TransshipHeader."Shipping Agent Code";
                    EInvoiceEntryL."Distance Remark" := DistanceRemark;
                    if DistanceRemark > '' then
                        evaluate(EInvoiceEntryL."Transportation Distance", DelChr(DelChr(DistanceRemark, '=', 'Pin-Pin calc distance: '), '=', 'KM'));
                    TransshipHeader."E-Way Bill No." := EInvoiceEntryL."E-Way Bill No.";
                    if TransshipHeader."Distance (Km)" = 0 then
                        TransshipHeader."Distance (Km)" := EInvoiceEntryL."Transportation Distance";

                    if (DistanceKM > 0) and (TransshipHeader."Distance (Km)" = 0) Then
                        TransshipHeader."Distance (Km)" := DistanceKM;

                    TransshipHeader.Modify();
                    Message(EWayGenerated, TransshipHeader."No.");

                end else begin
                    CreateLogEntry(TransshipHeader."No.", DocType::TransferShpt, TransshipHeader."Posting Date", RequestText, ResponseText, '', '', '', StatusText, EInvoiceEntryL);
                    EInvoiceEntryL.Status := EInvoiceEntryL.Status::Fail;
                    EInvoiceEntryL."E-Way Generated" := false;
                    EInvoiceEntryL."E-Way Canceled" := false;
                    //  Message(EWayFailed, TransshipHeader."No.");
                    if JSubObject.Contains('ErrorDetails') then begin
                        JSubObject.Get('ErrorDetails', JToken1L);
                        JSubArray := JToken1L.AsArray();
                        ErrorDetails := format(JSubArray);

                        //
                        for j := 0 to JSubArray.Count - 1 do begin
                            JSubArray.Get(j, JTokenL);
                            if j = 0 then begin

                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 1 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 1" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 2 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 2" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            if j = 3 then begin
                                JObjectL := JTokenL.AsObject();
                                EInvoiceEntryL."Error Description 3" := GetValueFromJsonObject(JObjectL, 'error_message').AsText();
                            end;
                            EInvoiceEntryL.Modify();
                        end;
                    end;
                    Message(StrSubstNo(EWayFailed, TransshipHeader."No.") + '  Error As follow : ' + EInvoiceEntryL."Error Description" + ' ' + EInvoiceEntryL."Error Description 2");
                END;
                EInvoiceEntryL.Modify();
            end;
        end else
            Error(ResponseText);
    end;

    procedure setDocNo(DocP: Code[20])
    begin
        docNo := DocP;
    end;

    var
        GSTNO: code[20];
        EntryExitPoint: Record "Entry/Exit Point";
        item: record item;

}

