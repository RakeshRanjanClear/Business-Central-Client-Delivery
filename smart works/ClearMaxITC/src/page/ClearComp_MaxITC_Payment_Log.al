page 60117 "ClearComp MaxITC Payment Log"
{
    // version MaxITC

    PageType = List;
    SourceTable = "ClearComp MaxITC Payment Log";
    Caption = 'Clear MAXITC payment log';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = all;
                }
                field(DocumentID; Rec.DocumentID)
                {
                    ApplicationArea = all;
                }
                field("Document reference No"; Rec."Document reference No")
                {
                    ApplicationArea = all;
                }
                field("Payment Action"; Rec."Payment Action")
                {
                    ApplicationArea = all;
                }
                field("G/L Entry No."; Rec."G/L Entry No.")
                {
                    ApplicationArea = all;
                }
                field("Creation DateTime"; Rec."Creation DateTime")
                {
                    ApplicationArea = all;
                }
            }
        }
    }

    actions
    {
    }
}

