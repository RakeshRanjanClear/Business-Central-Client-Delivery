codeunit 50112 "ClearComp Subscriber Unit"
{
    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Sales-Post (Yes/No)", 'OnBeforeOnRun', '', true, false)]
    local procedure OnBeforeOnRun(var SalesHeader: Record "Sales Header")
    var
        ErrorTxt: Text;
    begin
        Clear(ErrorTxt);
        if SalesHeader."External Document No." = '' then
            ErrorTxt := SalesHeader.FieldName("External Document No.");

        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then begin
            if SalesHeader."Reference Invoice No." = '' then
                ErrorTxt += ' ' + SalesHeader.FieldName("Reference Invoice No.");
            if not (SalesHeader."Nature of Supply" in [SalesHeader."Nature of Supply"::B2B, SalesHeader."Nature of Supply"::B2C]) then
                ErrorTxt += ' ' + SalesHeader.FieldName("Nature of Supply");
        end;

        if ErrorTxt > '' then
            Error(StrSubstNo('%1 is mandatory', ErrorTxt));
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Purch.-Post (Yes/No)", 'OnBeforeOnRun', '', true, false)]
    local procedure OnBeforeOnRunEvent(var PurchaseHeader: Record "Purchase Header")
    var
        ErrorTxt: Text;
    begin
        Clear(ErrorTxt);
        if PurchaseHeader."Posting Date" = 0D then
            ErrorTxt := PurchaseHeader.FieldName("Posting Date");

        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then begin
            if PurchaseHeader."Reference Invoice No." = '' then
                ErrorTxt += ' ' + PurchaseHeader.FieldName("Reference Invoice No.");
            if not (PurchaseHeader."Nature of Supply" in [PurchaseHeader."Nature of Supply"::B2B, PurchaseHeader."Nature of Supply"::B2C]) then
                ErrorTxt += ' ' + PurchaseHeader.FieldName("Nature of Supply");
        end;

        if ErrorTxt > '' then
            Error(StrSubstNo('%1 is mandatory', ErrorTxt));
    end;
}