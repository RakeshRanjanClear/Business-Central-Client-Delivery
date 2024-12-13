codeunit 60031 "CT Eway Subscriber"


{

    [EventSubscriber(ObjectType::Page, Page::"Posted Sales Inv. - Update", 'OnAfterRecordChanged', '', false, false)]

    local procedure OnAfterRecordChanged(var SalesInvoiceHeader: Record "Sales Invoice Header"; xSalesInvoiceHeader: Record "Sales Invoice Header"; var IsChanged: Boolean)
    begin
        IsChanged := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Inv. Header - Edit", 'OnOnRunOnBeforeTestFieldNo', '', false, false)]

    local procedure OnOnRunOnBeforeTestFieldNo(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceHeaderRec: Record "Sales Invoice Header")
    begin

        SalesInvoiceHeader."Shipment Method Code" := SalesInvoiceHeaderRec."Shipment Method Code";
        SalesInvoiceHeader."Shipping Agent Code" := SalesInvoiceHeaderRec."Shipping Agent Code";
        SalesInvoiceHeader."LR/RR No." := SalesInvoiceHeaderRec."LR/RR No.";
        SalesInvoiceHeader."LR/RR Date" := SalesInvoiceHeaderRec."LR/RR Date";
        SalesInvoiceHeader."Vehicle No." := SalesInvoiceHeaderRec."Vehicle No.";
        SalesInvoiceHeader."Vehicle Type" := SalesInvoiceHeaderRec."Vehicle Type";
        SalesInvoiceHeader."Mode of Transport" := SalesInvoiceHeaderRec."Mode of Transport";

    end;
}

