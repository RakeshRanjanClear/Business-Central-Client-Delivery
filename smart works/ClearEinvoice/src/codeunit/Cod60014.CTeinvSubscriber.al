codeunit 60014 "CT einv Subscriber"
{

    [EventSubscriber(ObjectType::Page, Page::"Posted Sales Inv. - Update", 'OnAfterRecordChanged', '', false, false)]

    local procedure OnAfterRecordChanged(var SalesInvoiceHeader: Record "Sales Invoice Header"; xSalesInvoiceHeader: Record "Sales Invoice Header"; var IsChanged: Boolean)
    begin
        IsChanged := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Inv. Header - Edit", 'OnOnRunOnBeforeTestFieldNo', '', false, false)]

    local procedure OnOnRunOnBeforeTestFieldNo(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceHeaderRec: Record "Sales Invoice Header")
    begin

        SalesInvoiceHeader."Exit Point" := SalesInvoiceHeaderRec."Exit Point";
        SalesInvoiceHeader."Transport Method" := SalesInvoiceHeaderRec."Transport Method";
        if SalesInvoiceHeaderRec."Distance (Km)" > 0 then
            SalesInvoiceHeader."Distance (Km)" := SalesInvoiceHeaderRec."Distance (Km)";

        SalesInvoiceHeader."IRN Disable" := SalesInvoiceHeaderRec."IRN Disable";
    end;
}