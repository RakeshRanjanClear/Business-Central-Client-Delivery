permissionset 50100 EInvoicePermission
{
    Assignable = true;
    Permissions = tabledata "ClearComp e-Invocie Setup" = RIMD,
        tabledata "ClearComp e-Invoice Entry" = RIMD,
        tabledata "ClearComp Interface Msg Log" = RIMD,
        table "ClearComp e-Invocie Setup" = X,
        table "ClearComp e-Invoice Entry" = X,
        table "ClearComp Interface Msg Log" = X,
        report "ClearComp Generate IRN" = X,
        codeunit "ClearComp E-Invoice Management" = X,
        page "ClearComp E-Invoice Logs" = X,
        page "ClearComp E-Invoice Setup" = X,
        page "ClearComp Interface Msg Log" = X;
}