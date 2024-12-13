codeunit 60007 "Clear Generate Sales XL"
{
    var
        ExcelBuffer: Record "Excel Buffer" temporary;
        Generalfun: Codeunit "Clear General functions";

    procedure CreateandOpenXL(var TransHdr: Record "Clear Trans Hdr")
    var
        TransLine: Record "Clear Trans line";
    begin
        CreateExcelTemplate();
        if TransHdr.FindSet(true) then
            repeat
                TransLine.SetRange("Transaction Type", TransHdr."Transaction Type");
                TransLine.SetRange("Document Type", TransHdr."Document Type");
                TransLine.SetRange("Document No.", TransHdr."Document No.");
                if TransLine.FindSet() then
                    repeat

                    until TransLine.Next() = 0;
            until TransHdr.Next() = 0;
    end;

    local procedure CreateExcelTemplate()
    begin

    end;
}