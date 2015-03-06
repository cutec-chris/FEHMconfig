unit uAddDevice;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, IpHtml, Ipfilebroker, Forms, Controls, Graphics,
  Dialogs, ComCtrls, StdCtrls, ButtonPanel;

type

  { TFillThread }

  TFillThread = class(TThread)
  private
    actName: String;
    actSecName: String;
    FAdd: TNotifyEvent;
    procedure AddItem;
  public
    constructor Create(CreateSuspended: Boolean; const StackSize: SizeUInt=
  DefaultStackSize);
    procedure Execute; override;
    procedure ParseCommandRef;
    property OnAddDevice : TNotifyEvent read FAdd write FAdd;
  end;

  TModule = class
  public
    Name : string;
    Typ : string;

    Description : string;
    Define : string;
    GetContent : string;
    SetContent : string;
    Attributes : string;
  end;

  { TfAddDevice }

  TfAddDevice = class(TForm)
    ButtonPanel1: TButtonPanel;
    eSearch: TEdit;
    eDefine: TEdit;
    ipHTML: TIpHtmlPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    cbName: TRadioButton;
    cbAll: TRadioButton;
    Label4: TLabel;
    tvMain: TTreeView;
    procedure aThreadAddDevice(Sender: TObject);
    procedure cbAllClick(Sender: TObject);
    procedure eSearchChange(Sender: TObject);
    procedure eSearchEnter(Sender: TObject);
    procedure eSearchExit(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure TSimpleIpHtmlGetImageX(Sender: TIpHtmlNode; const URL: string;
      var Picture: TPicture);
    procedure tvMainSelectionChanged(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    Modules: TList;
    function Execute : Boolean;
  end;

  { TSimpleIpHtml }

  TSimpleIpHtml = class(TIpHtml)
  public
    property OnGetImageX;
    constructor Create;
  end;

var
  fAddDevice: TfAddDevice;

implementation

uses uMain,RegExpr,Utils;

{$R *.lfm}

{ TSimpleIpHtml }

constructor TSimpleIpHtml.Create;
begin
  inherited;
end;

{ TFillThread }

procedure TFillThread.AddItem;
var
  aMod: TModule;
begin
  aMod := TModule.Create;
  aMod.Name:=actName;
  aMod.Typ:=actSecName;
  fAddDevice.Modules.Add(aMod);
  if Assigned(FAdd) then
    FAdd(aMod);
end;

constructor TFillThread.Create(CreateSuspended: Boolean;
  const StackSize: SizeUInt);
begin
  inherited;
  FreeOnTerminate:=True;
end;

procedure TFillThread.Execute;
var
  FCommandRef: String;
  FCommandRefDE: String;
begin
  ParseCommandRef;
end;

procedure TFillThread.ParseCommandRef;
var
  tmp: String;
  tmpEN : string;
  aSec: String;
  tmp1: String;
  i: Integer;
  tmp2: String;
  aSecTp: String;

  procedure FillSection;
  begin
    while (pos('<a href',aSec)>0) do
      begin
        aSec := copy(aSec,pos('<a href',aSec)+8,length(aSec));
        aSec := copy(aSec,pos('>',aSec)+1,length(aSec));
        actName := copy(aSec,0,pos('<',aSec)-1);
        Synchronize(@AddItem);
        aSec := copy(aSec,pos('</a>',aSec)+4,length(aSec));
      end;

  end;

begin
  tmp := fMain.LoadHTML('/docs/commandref_DE.html');
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  aSec := copy(tmp,0,pos('<b>',tmp)-1);
  actSecName := copy(aSec,0,pos('</b>',aSec)-1);
  //FillSection;
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  aSec := copy(tmp,0,pos('<b>',tmp)-1);
  actSecName := HTMLDecode(copy(aSec,0,pos('</b>',aSec)-1));
  FillSection;
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  aSec := copy(tmp,0,pos('<b>',tmp)-1);
  actSecName := HTMLDecode(copy(aSec,0,pos('</b>',aSec)-1));
  FillSection;
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  //now we have all Module names
  for i := 0 to fAddDevice.Modules.Count-1 do
    with TModule(fAddDevice.Modules[i]) do
      begin
        aSecTp := 'desc';
        tmp1 := '<a name="'+Name+'">';
        aSec := copy(tmp,pos(tmp1,tmp)+9,length(tmp));
        aSec := copy(aSec,pos('</a>',aSec)+4,length(aSec));
        while pos('<a name="',aSec)>0 do
          begin
            tmp1 := copy(aSec,0,pos('<a name="',aSec)-1);
            aSec := copy(aSec,pos('<a name="',aSec)+9,length(aSec));
            tmp2 := copy(aSec,0,pos('"',aSec)-1);
            case aSecTp of
            'desc':
              begin
                if pos('Leider keine deutsche',tmp1)>0 then
                  begin
                    tmp1 := '';
                    aSec := fMain.ExecCommand('help '+Name,fMain.eServer.Text);
                    if pos('<b>',aSec)=0 then
                      begin
                        if tmpEN='' then
                          tmpEN := fMain.LoadHTML('/docs/commandref.html');
                        tmp1 := '<a name="'+Name+'">';
                        aSec := copy(tmpEN,pos(tmp1,tmpEN)+9,length(tmpEN));
                        aSec := copy(aSec,pos('</a>',aSec)+4,length(aSec));
                      end;
                    tmp1 := copy(aSec,0,pos('<a name="',aSec)-1);
                    aSec := copy(aSec,pos('<a name="',aSec)+9,length(aSec));
                    tmp2 := copy(aSec,0,pos('"',aSec)-1);
                  end;
                Description:=tmp1;
              end;
            'define':Define:=copy(tmp1,pos('>',tmp1)+1,length(tmp1));
            'set':SetContent:=copy(tmp1,pos('>',tmp1)+1,length(tmp1));
            'get':GetContent:=copy(tmp1,pos('>',tmp1)+1,length(tmp1));
            'attr':Attributes:=copy(tmp1,pos('>',tmp1)+1,length(tmp1));
            end;
            if tmp2=Name+'define' then
              begin
                aSecTp := 'define';
              end
            else if tmp2=Name+'set' then
              begin
                aSecTp := 'set';
              end
            else if tmp2=Name+'get' then
              begin
                aSecTp := 'get';
              end
            else if tmp2=Name+'attr' then
              begin
                aSecTp := 'attr';
              end
            else
              begin
                break;
              end;
          end;
      end;
end;

{ TfAddDevice }

procedure TfAddDevice.FormCreate(Sender: TObject);
begin
  Modules := TList.Create;
end;

procedure TfAddDevice.aThreadAddDevice(Sender: TObject);
var
  aNode : TTreeNode = nil;
  TypNode: TTreeNode = nil;
begin
  if tvMain.Items.Count>0 then aNode := tvMain.Items[0];
  with TModule(Sender) do
    begin
      while Assigned(aNode) do
        begin
          if aNode.Text=Typ then
            TypNode := aNode;
          aNode := aNode.GetNextSibling;
        end;
      if not Assigned(TypNode) then
        TypNode := tvMain.Items.Add(nil,Typ);
      aNode := tvMain.Items.AddChild(TypNode,Name);
      aNode.Data := Sender;
    end;
end;

procedure TfAddDevice.cbAllClick(Sender: TObject);
begin
  tvMainSelectionChanged(tvMain);
end;

procedure TfAddDevice.eSearchChange(Sender: TObject);
var
  aNode: TTreeNode;
begin
  if tvMain.Items.Count=0 then exit;
  aNode := tvMain.Items[0];
  while assigned(aNode) do
    begin
      if Assigned(aNode.Data) then
        begin
          aNode.Visible := (Assigned(aNode.Data) and (pos(lowercase(eSearch.Text),lowercase(aNode.Text))>0)) or ((trim(eSearch.Text)='') or (eSearch.Text=strSearch) or (aNode.HasChildren));
          if (aNode.Visible and Assigned(aNode.Parent)) and (not ((trim(eSearch.Text)='') or (eSearch.Text=strSearch) or (aNode.HasChildren))) then aNode.Parent.Expanded:=True;
        end;
      aNode := aNode.GetNext;
    end;
end;

procedure TfAddDevice.eSearchEnter(Sender: TObject);
begin
  if (trim(eSearch.Text)='') or (eSearch.Text=strSearch) then
    eSearch.Clear;
  eSearch.Font.Color:=clDefault;
end;

procedure TfAddDevice.eSearchExit(Sender: TObject);
begin
  if (trim(eSearch.Text)='') or (eSearch.Text=strSearch) then
    begin
      eSearch.Text:=strSearch;
      eSearch.Font.Color:=clSilver;
    end;
end;

procedure TfAddDevice.FormDeactivate(Sender: TObject);
begin
  Modules.Free;
end;

procedure TfAddDevice.TSimpleIpHtmlGetImageX(Sender: TIpHtmlNode;
  const URL: string; var Picture: TPicture);
begin
  Picture:=nil;
end;

procedure TfAddDevice.tvMainSelectionChanged(Sender: TObject);
var
  aHTML: TSimpleIpHtml;
  ss: TStringStream;
  aMod: TModule;
  tmp: String;
begin
  if not Assigned(tvMain.Selected) then exit;
  if not Assigned(tvMain.Selected.Data) then exit;
  aHTML := TSimpleIpHtml.Create;
  aMod := TModule(tvMain.Selected.Data);
  if cbAll.Checked then
    ss := TStringStream.Create('<html><body>'+aMod.Description+aMod.Define+aMod.Attributes+aMod.SetContent+aMod.GetContent+'</body></html>')
  else
    ss := TStringStream.Create('<html><body>'+aMod.Description+'</body></html>');
  aHTML.OnGetImageX:=@TSimpleIpHtmlGetImageX;
  aHTML.LoadFromStream(ss);
  ss.Free;
  ipHTML.SetHtml(aHTML);
  tmp := StripHTML(aMod.Define);
  tmp := copy(tmp,pos('define ',tmp)-1,length(tmp));
  tmp := copy(tmp,0,pos(#10,tmp)-1);
  eDefine.Text:=trim(tmp);
  if eDefine.Text<>'' then
    begin
      eDefine.SetFocus;
      eDefine.SelStart:=pos('<name>',lowercase(eDefine.Text))-1;
      eDefine.SelLength:=6;
    end;
end;

function TfAddDevice.Execute: Boolean;
var
  aThread: TFillThread;
begin
  if not Assigned(Self) then
    begin
      Application.CreateForm(TfAddDevice,fAddDevice);
      Self := fAddDevice;
      aThread := TFillThread.Create(False);
      aThread.OnAddDevice:=@aThreadAddDevice;
    end;
  Result := Showmodal = mrOK;
end;

end.
