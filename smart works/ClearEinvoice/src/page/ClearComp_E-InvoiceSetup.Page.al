page 60013 "ClearComp E-Invoice Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "ClearComp e-Invocie Setup";
    Caption = 'E-Invoice Setup';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Integration Enabled"; Rec."Integration Enabled")
                {
                    ApplicationArea = All;
                }
                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = All;
                }
                field("Auth Token"; Rec."Auth Token")
                {
                    ApplicationArea = All;
                }
                field("URL IRN Generation"; Rec."URL IRN Generation")
                {
                    ApplicationArea = All;
                }
                field("URL IRN Cancellation"; Rec."URL IRN Cancellation")
                {
                    ApplicationArea = All;
                }
                field("Show Payload"; Rec."Show Payload")
                {
                    ApplicationArea = All;
                }
                field("Integration Mode"; Rec."Integration Mode")
                {
                    ApplicationArea = All;
                }
                field("URL QR generation"; rec."URL QR generation")
                {
                    ApplicationArea = all;
                }
                field("DSC URL Links"; Rec."DSC URL Links")
                {
                    ApplicationArea = all;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {
                ApplicationArea = All;
                Caption = 'e-Invoice Logs';
                Image = Log;

                trigger OnAction()
                var
                    EInvoiceLogs: Page "ClearComp E-Invoice Logs";
                begin
                    EInvoiceLogs.Run();
                end;
            }
            action("Message Logs")
            {
                ApplicationArea = All;
                Image = InteractionLog;
                Caption = 'API message Logs';

                trigger OnAction()
                var
                    InterfMessageLog: Page "ClearComp Interface Msg Log";
                begin
                    InterfMessageLog.Run();
                end;
            }

            action("PDF Sign")
            {
                ApplicationArea = All;
                Image = InteractionLog;
                Caption = 'PDF Sign';


                trigger OnAction()
                var
                    FromFilter: Text;
                    NVInStream: InStream;
                    base64: Codeunit "Base64 Convert";
                    base64String: text;
                    jsonObject: JsonObject;
                    HttpSendMessage: Codeunit "Clear Http Send Message";
                    ResponseText: text;
                    ErrorText: Text;
                    EinvoiceSetup: Record "ClearComp e-Invocie Setup";
                    GSTIN: Record "GST Registration Nos.";
                    TempBlob: Codeunit "Temp Blob";
                    OutstreamL: OutStream;
                    ResponseStream: InStream;
                    RequestStream: InStream;
                    FileManagementL: Codeunit "File Management";
                begin
                    EinvoiceSetup.get;
                    GSTIN.FindFirst();
                    FromFilter := 'All Pdf Files (*.Pdf)|*.Pdf';
                    UploadIntoStream(FromFilter, NVInStream);
                    base64String := base64.ToBase64(NVInStream);
                    jsonObject.Add('base64String', base64String);
                    jsonObject.WriteTo(base64String);
                    Clear(HttpSendMessage);
                    Clear(ResponseText);
                    Clear(ErrorText);

                    HttpSendMessage.SetHttpHeader('X-ClearTax-AUTH-TOKEN', EinvoiceSetup."Auth Token");
                    HttpSendMessage.SetMethod('POST');
                    HttpSendMessage.SetContentType('application/json');

                    HttpSendMessage.SetHttpHeader('gstin', GSTIN.Code);

                    HttpSendMessage.SetHttpHeader('x-cleartax-product', 'Einvoice');
                    HttpSendMessage.AddUrl(EinvoiceSetup."DSC URL Links");
                    if (base64String > '') then begin
                        TempBlob.CreateOutStream(OutstreamL);
                        OutstreamL.WriteText(base64String);
                        TempBlob.CreateInStream(RequestStream);
                        HttpSendMessage.AddBody(RequestStream);
                    end;

                    HttpSendMessage.SendRequest(ResponseStream);
                    if HttpSendMessage.IsSuccess() then begin
                        //  if ForPDF then begin
                        Clear(TempBlob);

                        TempBlob.CreateOutStream(OutstreamL);
                        CopyStream(OutstreamL, ResponseStream);
                        FileManagementL.BLOBExport(TempBlob, Format(Random(100)) + '.pdf', true);

                    end else begin
                        ErrorText := HttpSendMessage.Reason();
                        if ErrorText > '' then begin
                            Commit();
                            Message('DSC report generation Failed with following error:' + ErrorText);
                        end;
                    end;

                end;
            }
        }
    }
}
