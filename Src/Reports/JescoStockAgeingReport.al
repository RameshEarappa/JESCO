report 50115 "Jesco Stock Ageing"
{
    DefaultLayout = RDLC;
    RDLCLayout = '.\Layout Reports Rdls\JescoStockAgeing.rdl';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(Header; Integer)
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            column(TodayFormatted; Format(Today, 0, 4)) { }
            column(CompanyName; CompanyInfo.Name) { }
            column(ItemAgeCompositionQtyCaption; ItemAgeCompositionQtyCaptionLbl) { }
            column(PageNoCaption; PageNoCaptionLbl) { }
            column(HeaderText1; HeaderText[1]) { }
            column(HeaderText2; HeaderText[2]) { }
            column(HeaderText3; HeaderText[3]) { }
            column(HeaderText4; HeaderText[4]) { }
            column(HeaderText5; HeaderText[5]) { }
            column(HeaderText6; HeaderText[6]) { }
            column(HeaderText7; HeaderText[7]) { }
            column(InvtQty1_ItemLedgEntry; InvtQty[1]) { DecimalPlaces = 0 : 2; }
            column(InvtQty2_ItemLedgEntry; InvtQty[2]) { DecimalPlaces = 0 : 2; }
            column(InvtQty3_ItemLedgEntry; InvtQty[3]) { DecimalPlaces = 0 : 2; }
            column(InvtQty4_ItemLedgEntry; InvtQty[4]) { DecimalPlaces = 0 : 2; }
            column(InvtQty5_ItemLedgEntry; InvtQty[5]) { DecimalPlaces = 0 : 2; }
            column(InvtQty6_ItemLedgEntry; InvtQty[6]) { DecimalPlaces = 0 : 2; }
            column(InvtQty7_ItemLedgEntry; InvtQty[7]) { DecimalPlaces = 0 : 2; }
            column(InvtValue1_ItemLedgEntry; InvtValue[1]) { AutoFormatType = 1; }
            column(InvtValue2_ItemLedgEntry; InvtValue[2]) { AutoFormatType = 1; }
            column(InvtValue3_ItemLedgEntry; InvtValue[3]) { AutoFormatType = 1; }
            column(InvtValue4_ItemLedgEntry; InvtValue[4]) { AutoFormatType = 1; }
            column(InvtValue5_ItemLedgEntry; InvtValue[5]) { AutoFormatType = 1; }
            column(InvtValue6_ItemLedgEntry; InvtValue[6]) { AutoFormatType = 1; }
            column(InvtValue7_ItemLedgEntry; InvtValue[7]) { AutoFormatType = 1; }
            column(TotalInvtValue; TotalInvtValue) { }
            column(PrintLine; PrintLine) { }

            dataitem(Item; Item)
            {
                DataItemTableView = SORTING("No.") WHERE(Type = CONST(Inventory));
                RequestFilterFields = "No.", "Inventory Posting Group", "Statistics Group", "Location Filter";
                column(TblCptnItemFilter; TableCaption + ': ' + ItemFilter) { }
                column(ItemFilter; ItemFilter) { }
                column(ItemNo_; "No.") { }
                column(Description; Description) { }
                column(Inventory; Inventory) { }
                column(Unit_Cost; "Unit Cost") { }


                trigger OnAfterGetRecord()
                var
                    ItemLedgEntry: Record "Item Ledger Entry";
                    PeriodIndex: Integer;
                    RemaningQtyL: Integer;
                    CostAmtActualL: Decimal;
                begin
                    CalcFields(Inventory);
                    Clear(TotalInvtQty);
                    Clear(PrintLine);

                    if HeadingType = HeadingType::"Number of Days" then
                        PrintLine := true;

                    for i := 1 to ArrayLen(PeriodEndDate) do begin
                        Clear(RemaningQtyL);
                        //if PeriodStartDate[i] <> 0D then
                        ItemLedgEntry.SetFilter("Posting Date", '%1..%2', PeriodStartDate[i], PeriodEndDate[i]);
                        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Purchase);
                        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Purchase Receipt");
                        ItemLedgEntry.SetRange("Item No.", Item."No.");
                        if ItemLedgEntry.FindSet() then begin
                            repeat
                                //if ItemLedgEntry."Remaining Quantity" <> 0 then
                                if ItemLedgEntry.Quantity <> 0 then
                                    RemaningQtyL += ItemLedgEntry.Quantity; //ItemLedgEntry."Remaining Quantity";
                                if ItemLedgEntry."Cost Amount (Actual)" <> 0 then
                                    CostAmtActualL := ItemLedgEntry."Cost Amount (Actual)" / RemaningQtyL;
                            until ItemLedgEntry.Next() = 0;
                            if PeriodStartDate[i] < PeriodEndDate[i] then begin
                                InvtQty[i] := RemaningQtyL;
                                InvtValue[i] := CostAmtActualL;
                                TotalInvtQty += CostAmtActualL;
                            end;
                        end;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(InvtValue);
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AgedAsOf; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged As Of';
                        ToolTip = 'Specifies the date that you want the aging calculated for.';
                    }
                    field(Agingby; AgingBy)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aging by';
                        OptionCaption = 'Posting Date';
                        ToolTip = 'Specifies if the aging will be calculated from the due date, the posting date, or the document date.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }

                    field(HeadingType; HeadingType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Heading Type';
                        OptionCaption = 'Date Interval,Number of Days';
                        ToolTip = 'Specifies if the column heading for the three periods will indicate a date interval or the number of days overdue.';
                    }
                }
            }
        }
        trigger OnOpenPage()
        begin
            if EndingDate = 0D then
                EndingDate := WorkDate;
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
        end;
    }
    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        GLSetup.Get();
        CompanyInfo.Get();
        CalcDates;
        CreateHeadings;
        ItemFilter := Item.GetFilters;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ItemFilter: Text;
        EndingDate: Date;
        AgingBy: Option "Posting Date";
        PeriodLength: DateFormula;
        HeadingType: Option "Date Interval","Number of Days";
        PrintLine: Boolean;
        i: Integer;
        TotalInvtQty: Decimal;
        TotalItemLedgEntry: array[5] of Record "Item Ledger Entry";
        InvtQty: array[7] of Decimal;
        PeriodStartDate: array[7] of Date;
        PeriodEndDate: array[7] of Date;
        HeaderText: array[7] of Text[30];
        PageNoCaptionLbl: Label 'Page';
        Text001: Label 'Before';
        Text002: Label 'days';
        Text003: Label 'Above';
        Text010: Label 'The Date Formula %1 cannot be used. Try to restate it. E.g. 1M+CM instead of CM+1M.';
        Text032Txt: Label '-%1', Comment = 'Negating the period length: %1 is the period length';
        EnterDateFormulaErr: Label 'Enter a date formula in the Period Length field.';
        ItemAgeCompositionQtyCaptionLbl: Label 'Item Age Composition - Quantity';
        CompanyInfo: Record "Company Information";
        RemainingQty: Decimal;
        InvtValue: array[7] of Decimal;
        TotalInvtValue: Decimal;

    local procedure CalcDates()
    var
        i: Integer;
        PeriodLength2: DateFormula;
    begin
        if not Evaluate(PeriodLength2, StrSubstNo(Text032Txt, PeriodLength)) then
            Error(EnterDateFormulaErr);
        PeriodEndDate[1] := EndingDate;
        PeriodStartDate[1] := CalcDate(PeriodLength2, EndingDate + 1);
        for i := 2 to ArrayLen(PeriodEndDate) do begin
            PeriodEndDate[i] := PeriodStartDate[i - 1] - 1;
            if (i = 6) OR (i = 7) then
                PeriodStartDate[i] := CalcDate('-7M', PeriodEndDate[i] + 1)
            else
                PeriodStartDate[i] := CalcDate(PeriodLength2, PeriodEndDate[i] + 1);
        end;

        // for i := 6 to ArrayLen(PeriodEndDate) do
        //     PeriodStartDate[i] := 0D;

        // for i := 6 to ArrayLen(PeriodEndDate) do begin
        //     PeriodEndDate[i] := PeriodStartDate[i - 1] - 1;
        //     PeriodStartDate[i] := CalcDate('-7M', PeriodEndDate[i] + 1);
        // end;
        PeriodStartDate[i] := 0D;

        for i := 1 to ArrayLen(PeriodEndDate) do
            if PeriodEndDate[i] < PeriodStartDate[i] then
                Error(Text010, PeriodLength);
    end;

    local procedure CreateHeadings()
    var
        i: Integer;
    begin
        i := 1;
        while i < ArrayLen(PeriodEndDate) do begin
            if HeadingType = HeadingType::"Date Interval" then
                HeaderText[i] := StrSubstNo('%1\..%2', PeriodStartDate[i], PeriodEndDate[i])
            else
                HeaderText[i] :=
                  StrSubstNo('%1 - %2 %3', EndingDate - PeriodEndDate[i] + 1, EndingDate - PeriodStartDate[i] + 1, Text002);
            i := i + 1;
        end;
        if HeadingType = HeadingType::"Date Interval" then
            HeaderText[i] := StrSubstNo('%1 %2', Text001, PeriodStartDate[i - 1])
        else
            HeaderText[i] := StrSubstNo('%1 \%2 %3', Text003, EndingDate - PeriodStartDate[i - 1] + 1, Text002);
    end;

    procedure InitializeRequest(NewEndingDate: Date; NewAgingBy: Option; NewPeriodLength: DateFormula; NewHeadingType: Option)
    begin
        EndingDate := NewEndingDate;
        AgingBy := NewAgingBy;
        PeriodLength := NewPeriodLength;
        HeadingType := NewHeadingType;
    end;
}