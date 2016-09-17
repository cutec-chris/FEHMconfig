unit fat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, Buttons, uFhemFrame,
  ZVDateTimePicker, Dialogs, ExtCtrls, Spin;

type

  { TfrAt }

  TfrAt = class(TFHEMFrame)
    bSave: TSpeedButton;
    bTestCondition: TButton;
    dtAll: TZVDateTimePicker;
    Label5: TLabel;
    Label6: TLabel;
    mEvent: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    lStatus: TLabel;
    mCommand: TMemo;
    rbAt: TRadioButton;
    rbAll: TRadioButton;
    rbSunOn: TRadioButton;
    rbSunOff: TRadioButton;
    rbUserdefined: TRadioButton;
    seCount: TSpinEdit;
    Timer1: TTimer;
    dtAt: TZVDateTimePicker;
    procedure bSaveClick(Sender: TObject);
    procedure bTestConditionClick(Sender: TObject);
    procedure rbAtChange(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  protected
    function GetDeviceType: string; override;
  public
    { public declarations }
    procedure ProcessList(aList: TStrings); override;
  end;

implementation

uses Utils;

{$R *.lfm}

{ TfrAt }

procedure TfrAt.bTestConditionClick(Sender: TObject);
var
  Res: String;
begin
  Res := ExecCommand(mCommand.Text);
  if Res<>'' then Showmessage(Res);
end;

procedure TfrAt.rbAtChange(Sender: TObject);
var
  tmp: string = '';
begin
  dtAt.Enabled := rbAt.Checked;
  dtAll.Enabled:=rbAll.Checked;
  mEvent.Enabled:=rbUserdefined.Checked;

  if rbAll.Checked then
    tmp += '+';
  tmp += '*';
  if seCount.Value>0 then
    tmp += '{'+IntToStr(seCount.Value)+'}';
  if rbAt.Checked then
    tmp+=FormatDateTime('HH:MM:SS',dtAt.Time)
  else if rbAll.Checked then
    tmp+=FormatDateTime('HH:MM:SS',dtAll.Time)
  else if rbSunOn.Checked then
    tmp+='{sunrise_rel()}'
  else if rbSunOff.Checked then
    tmp+='{sunrise_rel()}';
  if not rbUserdefined.Checked then
    mEvent.Text:=tmp;
end;

procedure TfrAt.Timer1Timer(Sender: TObject);
begin
  lStatus.Caption:=Device.Status;
end;

procedure TfrAt.bSaveClick(Sender: TObject);
var
  aRes: String;
  aDef: String;
begin
  aDef := mEvent.Text+' '+mCommand.Text;
  if copy(aDef,length(aDef),1)=#10 then
    aDef:=copy(aDef,1,length(aDef)-1);
  aRes := ChangeValue('detail='+FName+'&val.modify'+FName+'='+HTTPEncode(aDef)+'&cmd.modify'+FName+'=modify+'+FName);
  if aRes <> '' then
    Showmessage(aRes)
  else Change;
end;

function TfrAt.GetDeviceType: string;
begin
  Result := 'AT';
end;

procedure TfrAt.ProcessList(aList: TStrings);
var
  tmp: String;
  i: Integer;
  aTime: TDateTime;
begin
  //eName.Text:=FName;
  for i := 0 to aList.Count-1 do
    if copy(trim(aList[i]),0,3)='DEF' then tmp := trim(copy(trim(aList[i]),4,length(aList[i])));
  if Copy(tmp,0,1)='(' then
    begin
      mEvent.Text:=copy(tmp,2,pos(') ',tmp)-2);
      tmp := copy(tmp,pos(') ',tmp)+2,length(tmp));
    end
  else
    begin
      mEvent.Text:=copy(tmp,1,pos(' ',tmp)-1);
      tmp := copy(tmp,pos(' ',tmp)+1,length(tmp));
    end;
  mCommand.Text:=trim(tmp);
  if copy(mCommand.Text,0,1)='(' then
    mCommand.Text := copy(mCommand.Text,2,length(mCommand.Text)-2);

  tmp := mEvent.Text;
  seCount.Value:=0;
  if copy(tmp,0,1)='+' then
    begin
      rbAll.Checked:=True;
      tmp := copy(tmp,2,length(tmp));
    end;
  if copy(tmp,0,1)='*' then
    tmp := copy(tmp,2,length(tmp));
  if copy(tmp,0,1)='{' then
    begin
      tmp := copy(tmp,2,length(tmp));
      seCount.Value:=StrToIntDef(copy(tmp,0,pos('}',tmp)-1),0);
      tmp := copy(tmp,pos('}',tmp)+1,length(tmp));
    end;
  rbUserdefined.Checked:=not TryStrToTime(copy(tmp,0,8),aTime,':');
  if rbUserdefined.Checked then
    begin
      if lowercase(trim(tmp))='{sunset_rel()}' then
        rbSunOff.Checked:=True;
      if lowercase(trim(tmp))='{sunrise_rel()}' then
        rbSunOn.Checked:=True;
    end
  else
    begin
      dtAll.Time:=aTime;
      dtAt.Time:=aTime;
    end;
end;

initialization
  RegisterFrame(TfrAt);
end.

