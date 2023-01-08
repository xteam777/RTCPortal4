unit MainGateClientForm2;

interface

{$include rtcDefs.inc}

{ This Chat Client example works with the "RTCSimpleGateway" example Project and demonstrates
  the use of "TRtcGateAccountManager", "TRtcHttpGateClient" and "TRtcGateClientLink" components.

  Check the "GateAddr" and "GatePort" properties on the "GateCli:TRtcHttpGateClient"
  component to configure this "ChatClient" to work with a RTC Gateway running on a remote machine.
  Default setting are GateAddr="localhost" and GatePort="80" are used for local testing.

  For ONLINE/OFFLINE notifications about other CHAT users, this Chat Client uses
  the "AccMan:TRtcGateAccountManager" component to register and activate a Public Account
  with the Display Name "Lobby". Public Accounts are used for global notifications.
  Because all Chat Clients will be registering and activating the same Public Account,
  they will all be notified about each other during login/logout.

  Please note that ChatClients will NOT see their own ID in the "ONLINE" List after Login.
  You need at least 2 ChatClients running to see how ONLINE/OFFLINE notification works. 

  This Chat implementation allows free creation of Rooms.
  Any user inside a Chat Room can invite any other user by using
  the "INVITE" button and entering the ID of that user. }

{ To compile the project with StreamSec Tools 2.1+ components, declare
  the StreamSecII compiler directive below or in the "rtcDeploy.inc" file. }

{.$DEFINE StreamSecII}

uses
  Windows, Messages, SysUtils, Variants,
  Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,

  ExtCtrls, Buttons,

  rtcSystem, rtcInfo, rtcLog, rtcConn,

{$IF Defined(StreamSecII)}
  rtcSSecTest,
{$IFEND}

  rtcGateConst,
  rtcGateCli,
  rtcDataCli,

  rtcSrcList,
  rtcCrypt,

  ChatHostForm,
  ChatCIDs;

type
  TMsgType=(msg_Input,msg_Output,msg_Speed,msg_Error,msg_Status,msg_Group);

type
  TGateClientForm = class(TForm)
    StatusUpdate: TTimer;
    InfoPanel: TPanel;
    l_Status1: TLabel;
    l_Status2: TLabel;
    eYourID: TEdit;
    GateCli: TRtcHttpGateClient;
    Label1: TLabel;
    eMyGroup: TListBox;
    Label2: TLabel;
    Label3: TLabel;
    eInGroup: TListBox;
    btnCLR: TLabel;
    l_Groups: TLabel;
    l_Status3: TLabel;
    Bevel1: TBevel;
    btnHostChat: TButton;
    Bevel2: TBevel;
    ChatLink: TRtcGateClientLink;
    eChatUsers: TListBox;
    Label7: TLabel;
    Label4: TLabel;
    eOnlineUsers: TListBox;
    Bevel3: TBevel;
    AccMan: TRtcGateAccountManager;
    Panel1: TPanel;
    shInput: TShape;
    lblRecvBufferSize: TLabel;
    lblSendBuffSize: TLabel;
    shOutput: TShape;
    btnReset: TSpeedButton;
    procedure btnCLRClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure StatusUpdateTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure eMyGroupDblClick(Sender: TObject);
    procedure eInGroupDblClick(Sender: TObject);
    procedure btnHostChatClick(Sender: TObject);
    procedure eChatUsersDblClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure eOnlineUsersDblClick(Sender: TObject);
    procedure eOnlineUsersClick(Sender: TObject);
    procedure GateCliAfterLoggedInGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
    procedure GateCliAfterLoginFailGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
    procedure GateCliAfterLogOutGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
    procedure GateCliBeforeLogInGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
    procedure GateCliDataFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: Boolean);
    procedure GateCliInfoFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: Boolean);
    procedure GateCliReadyToSend(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo; var WantGUI, WantBackThread: Boolean);
    procedure GateCliStreamResetGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
    procedure ChatLinkDataFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: Boolean);
    procedure ChatLinkDataReceivedGUI(Client: TRtcHttpGateClient; Data: TRtcGateClientData);
    procedure GateCliInfoReceived(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var WantGUI, WantBackThread: Boolean);
    procedure GateCliInfoReceivedGUI(Client: TRtcHttpGateClient; Data: TRtcGateClientData);

  public
    FCS:TRtcCritSec;
    sStatus1,
    sStatus2,
    sStatus3,
    sGroups:String;

    LobbyAccount:RtcString;

    FLoginStart:TAppRunTime;
    CntReset:integer;

    InGroupCnt,OutGroupCnt:integer;
    InGroupMe,OutGroupMe:boolean;

    FChatUsers,
    FScreenUsers,
    FFileUsers:TStrList;

    NeedProviderChange:boolean;

    procedure PrintMsg(const s:String; t:TMsgType);
  end;

var
  GateClientForm: TGateClientForm;

implementation

{$R *.dfm}

function FillZero(const s:RtcString;len:integer):RtcString;
  begin
  Result:=s;
  while length(Result)<len do
    Result:='0'+Result;
  end;

function Time2Str(v:TDateTime):RtcString;
  var
    hh,mm,ss,ms:word;
  begin
  DecodeTime(v, hh,mm,ss,ms);
  Result:=FillZero(Int2Str(hh),2)+':'+FillZero(Int2Str(mm),2)+':'+FillZero(Int2Str(ss),2);
  end;

function Get_ComputerName: RtcString;
var
  buf: array [0 .. 256] of AnsiChar;
  len: DWord;
begin
  len := sizeof(buf);
  GetComputerNameA(@buf, len);
  Result := RtcString(PAnsiChar(@buf));
end;

function Get_UserName: RtcString;
var
  buf: array [0 .. 256] of AnsiChar;
  len: DWord;
begin
  len := sizeof(buf);
  GetUserNameA(@buf, len);
  Result := RtcString(PAnsiChar(@buf));
end;

procedure TGateClientForm.FormCreate(Sender: TObject);
  var
    MyAcc,MyLink:RtcString;
    MyData,RndSig,MySign,MyRes:RtcByteArray;
  {$IFDEF RTC_RSA}
    Rnd:TRtcISAAC;
    i:integer;
  {$ENDIF}
  begin
  StartLog;

  NeedProviderChange:=False;

  FCS:=TRtcCritSec.Create;
  sStatus1:='';
  sStatus2:='';
  sStatus3:='';
  sGroups:='';

  FChatUsers:=tStrList.Create(16);
  FScreenUsers:=tStrList.Create(16);
  FFileUsers:=tStrList.Create(16);

  SetLength(MyData,0);
  SetLength(RndSig,0);
  SetLength(MyRes,0);
  SetLength(MySign,0);
  MyAcc:='';
  // Load Accounts data from a file if it exists (for testing)
  if File_Exists('accounts.txt') then
    begin
    AccMan.RegisterFromCode(Read_FileEx('accounts.txt'),True,True);
    // Find Public "Lobby" Account
    LobbyAccount := AccMan.FindPublic('Lobby');
    end
  else
    begin
    // Register and activate Public "Lobby" Account
    LobbyAccount := AccMan.RegisterPublic('Lobby',True);

    // Register and activate Public "Hallway" Account
    AccMan.RegisterPublic('Hallway',True);

    // Testing Private and Linked Accounts ...
    // Generate and activate Private account "Me"
    MyAcc := AccMan.GeneratePrivate('Me',True);

    // Prepare a Link to our Private account
    MyData := AccMan.PrepareLink(MyAcc);
    // Normally, CheckAccount and RegisterAccount would be
    // used by a remote Client to establish a link to this Private account
    AccMan.CheckAccount(MyData);
    MyLink := AccMan.RegisterAccount(MyData,True,True);

    // Store Account data to a local file (for testing)
    Write_FileEx('accounts.txt',AccMan.SaveToCode);

    { Testing Private Signature, linked signature Verification,
      Private and Public Encryption and Decryprion routines ... }

  {$IFDEF RTC_RSA}
    // Generate a random array of bytes
    Rnd:=TRtcISAAC.Create(True);
    RndSig:=Rnd.RND(1024);
    Rnd.Free;

    // Make Private Account Signature (used for remote verification)
    MySign:=AccMan.MakeSignature(MyAcc,RndSig);
    // Verify Private Account Signature using the Linked account
    if not AccMan.VerifySignature(MyLink,RndSig,MySign) then
      raise Exception.Create('Signature verification failed!');

    // Encrypt Random Bytes using Public key from a linked Private account
    MySign:=AccMan.PrivateEncrypt(MyLink,RndSig);
    // Decrypt bytes using Private key from our Private account
    MyRes:=AccMan.PrivateDecrypt(MyAcc,MySign);
    // Check if original content matches decrypted content
    if length(MyRes)<>length(RndSig) then
      raise Exception.Create('Private Encrypt/Decrypt failed! Size missmatch');
    for i:=0 to length(MyRes)-1 do
      if MyRes[i]<>RndSig[i] then
        raise Exception.Create('Private Encrypt/Decrypt error at Byte '+IntToStr(i)+'!');

    // Encrypt Random Bytes using our temporary Public key
    MySign:=AccMan.PublicEncrypt(AccMan.PublicKey, RndSig);
    // Decrypt bytes using our temporary Private key
    MyRes:=AccMan.PublicDecrypt(MySign);
    // Check if original content matches decrypted content
    if length(MyRes)<>length(RndSig) then
      raise Exception.Create('Public Encrypt/Decrypt failed! Size missmatch');
    for i:=0 to length(MyRes)-1 do
      if MyRes[i]<>RndSig[i] then
        raise Exception.Create('Public Encrypt/Decrypt error at Byte '+IntToStr(i)+'!');
  {$ENDIF}
    end;

{$IFDEF StreamSecII}
  { This is a simple DEMO, so we do not care
    if the Server is using an expired certificate: }
  AllowExpiredCertificates(True);

  if not File_Exists('root.cer') then
    begin
    { This is a simple DEMO, so we do not care about security.
      If we do not have a root certificate on the client,
      we will use a HACK to allow the client to work with ANY Server: }
    BeGullableAndTrustAnythingSentToYou(True);
    { This is a simple DEMO, so we will accept any certificate: }
    AddCertificateNameMap('*','*');
    end
  else
    begin
    // We have a root certificate, let's load it ...
    AddClientRootCertFile('root.cer');
    AddClientPFXFile('client.pfx','abc');
    { This is a simple DEMO, so we will accept our "locahost" certificate,
      even if our test Server is running on a remote PC and not locally: }
    AddCertificateNameMap('*','localhost');
    end;

  GateCli.UseCryptPlugin:=GetClientCryptPlugin;
  GateCli.GatePort:='443';
{$ELSE}
  GateCli.GatePort:='80';
{$ENDIF}

  GateCli.GateUserInfo:=Get_UserName+'/'+Get_ComputerName;
  GateCli.AutoLogin:=True;
  end;

procedure TGateClientForm.FormDestroy(Sender: TObject);
  begin
  FreeAndNil(FChatUsers);
  FreeAndNil(FScreenUsers);
  FreeAndNil(FFileUsers);

  FreeAndNil(FCS);
  end;

procedure TGateClientForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  begin
  StatusUpdate.Enabled:=False;
  GateCli.AutoLogin:=False;
  CanClose:=True;
  end;

procedure TGateClientForm.btnCLRClick(Sender: TObject);
  begin
  CntReset:=0;
  btnCLR.Color:=clWhite;
  btnCLR.Font.Color:=clNavy;
  btnCLR.Caption:='CLR';
  end;

function KSeparate(const s:String):String;
  var
    i,len:integer;
  begin
  Result:='';
  i:=0;len:=length(s);
  while i<len do
    begin
    Result:=s[len-i]+Result;
    Inc(i);
    if (i mod 3=0) and (i<len) then Result:='.'+Result;
    end;
  end;

procedure TGateClientForm.StatusUpdateTimer(Sender: TObject);
  begin
  case GateCli.State.InputState of
    ins_Connecting: shInput.Brush.Color:=clYellow;
    ins_Closed:     shInput.Brush.Color:=clRed;
    ins_Prepare:    shInput.Brush.Color:=clBlue;
    ins_Start:      shInput.Brush.Color:=clGreen;
    ins_Recv:       shInput.Brush.Color:=clLime;
    ins_Idle:       shInput.Brush.Color:=clGreen;
    ins_Done:       shInput.Brush.Color:=clNavy;
    end;
  if GateCli.State.InputState=ins_Closed then
    shInput.Pen.Color:=shInput.Brush.Color
  else
    case GateCli.State.PingInCnt of
      0:shInput.Pen.Color:=clWhite;
      1:shInput.Pen.Color:=clGreen;
      2:shInput.Pen.Color:=clLime;
      3:shInput.Pen.Color:=clBlack;
      end;

  case GateCli.State.OutputState of
    outs_Connecting:  shOutput.Brush.Color:=clYellow;
    outs_Closed:      shOutput.Brush.Color:=clRed;
    outs_Prepare:     shOutput.Brush.Color:=clBlue;
    outs_Start:       shOutput.Brush.Color:=clGreen;
    outs_Send:        shOutput.Brush.Color:=clLime;
    outs_Idle:        shOutput.Brush.Color:=clGreen;
    outs_Done:        shOutput.Brush.Color:=clNavy;
    end;
  if GateCli.State.OutputState=outs_Closed then
    shOutput.Pen.Color:=shOutput.Brush.Color
  else
    case GateCli.State.PingOutCnt of
      0:shOutput.Pen.Color:=clWhite;
      1:shOutput.Pen.Color:=clGreen;
      2:shOutput.Pen.Color:=clLime;
      3:shOutput.Pen.Color:=clBlack;
      end;
  lblSendBuffSize.Caption:=KSeparate(Int2Str(GateCli.State.TotalSent div 1024))+'K';
  lblRecvBufferSize.Caption:=KSeparate(Int2Str(GateCli.State.TotalReceived div 1024))+'K';

  FCS.Acquire;
  try
    l_Status1.Caption:=sStatus1;
    l_Status2.Caption:=sStatus2;
    l_Status3.Caption:=sStatus3;
    l_Groups.Caption:=sGroups;
  finally
    FCS.Release;
    end;
  end;

procedure TGateClientForm.PrintMsg(const s: String; t:TMsgType);
  begin
  FCS.Acquire;
  try
    case t of
      msg_Input:
        sStatus1:=Time2Str(Now)+' '+s;
      msg_Output:
        sStatus2:=Time2Str(Now)+' '+s;
      msg_Group:
        sStatus1:=Time2Str(Now)+' '+s;
      msg_Speed:
        sStatus3:=s;
      msg_Status:
        begin
        sStatus1:=Time2Str(Now)+' '+s;
        sStatus2:='';
        sStatus3:='';
        end;
      msg_Error:
        sStatus2:=Time2Str(Now)+' '+s;
      end;
  finally
    FCS.Release;
    end;

  case t of
    msg_Input:
      Log(s,IntToStr(GateCli.MyUID)+'_DATA');
    msg_Output:
      Log(s,IntToStr(GateCli.MyUID)+'_DATA');
    msg_Group:
      Log(s,IntToStr(GateCli.MyUID)+'_DATA');
    msg_Speed:
      Log(s,IntToStr(GateCli.MyUID)+'_CONN');
    msg_Status:
      if GateCli.MyUID>0 then
        Log(s,IntToStr(GateCli.MyUID)+'_CONN');
    msg_Error:
      if GateCli.MyUID>0 then
        Log(s,IntToStr(GateCli.MyUID)+'_CONN');
    end;
  end;

procedure TGateClientForm.eMyGroupDblClick(Sender: TObject);
  var
    UID,GID:String;
    i:integer;
  begin
  if GateCli.Active then
    begin
    if (eMyGroup.Items.Count>0) and (eMyGroup.ItemIndex>=0) then
      begin
      UID:=Trim(eMyGroup.Items.Strings[eMyGroup.ItemIndex]);
      i:=Pos('/',UID);
      GID:=Copy(UID,i+1,length(UID));
      UID:=Copy(UID,1,i-1);
      if MessageDlg('Remove User '+UID+' from My Group '+GID+'?',mtConfirmation,[mbYes,mbNo],0)=mrYes then
        GateCli.RemUserFromGroup(GateCli.MyUID,StrToInt(GID),StrToInt(UID));
      end;
    end;
  end;

procedure TGateClientForm.eInGroupDblClick(Sender: TObject);
  var
    UID,GID:String;
    i:integer;
  begin
  if GateCli.Active then
    begin
    if (eInGroup.Items.Count>0) and (eInGroup.ItemIndex>=0) then
      begin
      UID:=Trim(eInGroup.Items.Strings[eInGroup.ItemIndex]);
      i:=Pos('/',UID);
      GID:=Copy(UID,i+1,length(UID));
      UID:=Copy(UID,1,i-1);
      if MessageDlg('Leave Group '+GID+' Hosted by User '+UID+' ?',mtConfirmation,[mbYes,mbNo],0)=mrYes then
        GateCli.RemUserFromGroup(StrToInt(UID),StrToInt(GID),GateCli.MyUID);
      end;
    end;
  end;

procedure TGateClientForm.btnHostChatClick(Sender: TObject);
  begin
  if GateCli.Ready then
    NewChatHostForm(GateCli);
  end;

procedure TGateClientForm.eChatUsersDblClick(Sender: TObject);
  var
    UID,Key:String;
    UserID,GroupID:TGateUID;
    i:integer;
    Frm:TChatHostFrm;
  begin
  if GateCli.Ready then
    begin
    if (eChatUsers.Items.Count>0) and (eChatUsers.ItemIndex>=0) then
      begin
      UID:=Trim(eChatUsers.Items.Strings[eChatUsers.ItemIndex]);
      eChatUsers.Items.Delete(eChatUsers.ItemIndex);

      // lblInvites.Visible:=eChatUsers.Count > 0;

      Key:=FChatUsers.search(UID);
      if Key<>'' then
        begin
        FChatUsers.remove(UID);
        i:=Pos('/',UID);
        UserID:=StrToInt(Copy(UID,1,i-1));
        GroupID:=StrToInt(Copy(UID,i+1,length(UID)-i));

        // Open a new Chat Room
        Frm:=NewChatHostForm(GateCli);

        if (GateCli.MyUID<>UserID) or (Frm.MyGroupID<>GroupID) then
          begin
          Frm.UserIsPassive(UserID,0);
          // Add user to "passive" list
          Frm.Link.Groups.SetStatus(UserID,0,1);
          // Add user as Friend, so the User can add us to his User Group
          GateCli.AddFriend(UserID);
          // Send invitation Key back with our Key
          GateCli.SendBytes(UserID,GroupID,cid_ChatAccept,RtcStringToBytes(Key + RtcBytesToString(Frm.InviteKey)));
          end;
        end;
      end;
    end;
  end;

procedure TGateClientForm.btnResetClick(Sender: TObject);
  begin
  NeedProviderChange:=True;
  GateCli.ResetStreams;
  end;

procedure TGateClientForm.eOnlineUsersDblClick(Sender: TObject);
  var
    UID:String;
  begin
  if GateCli.Active then
    if (eOnlineUsers.Items.Count>0) and (eOnlineUsers.ItemIndex>=0) then
      begin
      UID:=Trim(eOnlineUsers.Items.Strings[eOnlineUsers.ItemIndex]);
      if GateCli.Ready then
        NewChatHostForm(GateCli).InviteUserToChat(StrToInt(UID),0,True);
      end;
  end;

procedure TGateClientForm.eOnlineUsersClick(Sender: TObject);
  var
    UID:String;
  begin
  if GateCli.Active then
    if (eOnlineUsers.Items.Count>0) and (eOnlineUsers.ItemIndex>=0) then
      begin
      UID:=Trim(eOnlineUsers.Items.Strings[eOnlineUsers.ItemIndex]);
      // Testing requests for manual User Account verifications ..
      if GateCli.RequestUserVerifications(Str2Int(UID)) then
        MessageBeep(1);
      end;
  end;

procedure TGateClientForm.GateCliAfterLoggedInGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
  begin
  PrintMsg('Logged IN ('+FloatToStr((GetAppRunTime-FLoginStart)/RUN_TIMER_PRECISION)+' s).',msg_Status);

  eYourID.Text:=LWord2Str(State.MyUID);

  StatusUpdateTimer(nil);

  // Testing manual Subscribe calls ...
  GateCli.Subscribe(rtcMakePublicKey('Test'),90);
  end;

procedure TGateClientForm.GateCliAfterLoginFailGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
  begin
  if Client.UseWinHTTP then // WinHTTP -> async WinSock
    begin
    btnReset.Caption:='AS';
    Client.UseBlocking:=False;
    Client.UseProxy:=False;
    Client.UseWinHTTP:=False;
    end
  else if Client.UseProxy then // WinInet -> WinHTTP
    begin
    btnReset.Caption:='HT';
    Client.UseWinHTTP:=True;
    end
  else if Client.UseBlocking then // blocking WinSock -> WinInet
    begin
    btnReset.Caption:='IE';
    Client.UseProxy:=True;
    end
  else // async WinSock -> blocking WinSock
    begin
    btnReset.Caption:='BS';
    Client.UseBlocking:=True;
    end;

  StatusUpdate.Enabled:=False;
  StatusUpdateTimer(nil);

  PrintMsg('Login attempt FAILED.',msg_Status);
  if State.LastError<>'' then
    PrintMsg(State.LastError, msg_Error);

  FCS.Acquire;
  try
    sGroups:='0/0';
  finally
    FCS.Release;
    end;
  InGroupCnt:=0;
  OutGroupCnt:=0;
  InGroupMe:=False;
  OutGroupMe:=False;

  eMyGroup.Clear;
  eInGroup.Clear;
  eOnlineUsers.Clear;
  eChatUsers.Clear;

  //lblGroups.Visible:=False;
  //lblInvites.Visible:=False;
  //lblOnline.Visible:=False;

  btnCLR.Color:=clRed;
  btnCLR.Font.Color:=clYellow;
  end;

procedure TGateClientForm.GateCliAfterLogOutGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
  begin
  PrintMsg('Logged OUT.',msg_Status);
  if State.LastError<>'' then
    PrintMsg(State.LastError,msg_Error);

  StatusUpdate.Enabled:=False;

  FCS.Acquire;
  try
    sGroups:='0/0';
  finally
    FCS.Release;
    end;
  InGroupCnt:=0;
  OutGroupCnt:=0;
  InGroupMe:=False;
  OutGroupMe:=False;

  eMyGroup.Clear;
  eInGroup.Clear;
  eOnlineUsers.Clear;
  eChatUsers.Clear;

  //lblGroups.Visible:=False;
  //lblInvites.Visible:=False;
  //lblOnline.Visible:=False;

  if btnCLR.Caption<>'CLR' then
    begin
    btnCLR.Color:=clRed;
    btnCLR.Font.Color:=clYellow;
    end;

  StatusUpdateTimer(nil);
  end;

procedure TGateClientForm.GateCliBeforeLogInGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
  begin
  FLoginStart:=GetAppRunTime;

  CntReset:=0;
  btnCLR.Color:=clWhite;
  btnCLR.Font.Color:=clNavy;
  btnCLR.Caption:='CLR';

  shInput.Brush.Color:=clYellow;
  shInput.Pen.Color:=clWhite;
  shOutput.Brush.Color:=clYellow;
  shOutput.Pen.Color:=clWhite;
  PrintMsg('Logging in ...',msg_Status);

  FCS.Acquire;
  try
    sGroups:='0/0';
  finally
    FCS.Release;
    end;
  InGroupCnt:=0;
  OutGroupCnt:=0;
  InGroupMe:=False;
  OutGroupMe:=False;

  eMyGroup.Clear;
  eInGroup.Clear;
  eOnlineUsers.Clear;
  eChatUsers.Clear;

  //lblGroups.Visible:=False;
  //lblInvites.Visible:=False;
  //lblOnline.Visible:=False;

  StatusUpdate.Enabled:=True;
  end;

procedure TGateClientForm.GateCliDataFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: Boolean);
  begin
  if Data.Footer or not Data.ToBuffer then
    PrintMsg('<'+IntToStr(Length(Data.Content) div 1024)+'K id '+IntToStr(Data.UserID), msg_Input)
  end;

procedure TGateClientForm.GateCliReadyToSend(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo; var WantGUI, WantBackThread: Boolean);
  begin
  PrintMsg('Ready ('+FloatToStr((GetAppRunTime-FLoginStart)/RUN_TIMER_PRECISION)+' s).',msg_Output);
  FLoginStart:=GetAppRunTime;
  end;

procedure TGateClientForm.GateCliStreamResetGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
  begin
  if NeedProviderChange then
    begin
    NeedProviderChange:=False;
    if Client.UseWinHTTP then // WinHTTP -> async WinSock
      begin
      btnReset.Caption:='AS';
      Client.UseBlocking:=False;
      Client.UseProxy:=False;
      Client.UseWinHTTP:=False;
      end
    else if Client.UseProxy then // WinInet -> WinHTTP
      begin
      btnReset.Caption:='HT';
      Client.UseWinHTTP:=True;
      end
    else if Client.UseBlocking then // blocking WinSock -> WinInet
      begin
      btnReset.Caption:='IE';
      Client.UseProxy:=True;
      end
    else // async WinSock -> blocking WinSock
      begin
      btnReset.Caption:='BS';
      Client.UseBlocking:=True;
      end;
    end;

  FLoginStart:=GetAppRunTime;

  Inc(CntReset);
  btnCLR.Color:=clYellow;
  btnCLR.Font.Color:=clRed;
  btnCLR.Caption:=IntToStr(CntReset);

  if Client.Active then
    PrintMsg('#LOST ('+FloatToStr(State.InputResetTime/RUN_TIMER_PRECISION)+'s / '+FloatToStr(State.OutputResetTime/RUN_TIMER_PRECISION)+'s)',msg_Status)
  else
    PrintMsg('#FAIL ('+FloatToStr(State.InputResetTime/RUN_TIMER_PRECISION)+'s / '+FloatToStr(State.OutputResetTime/RUN_TIMER_PRECISION)+'s)',msg_Status);
  if State.LastError<>'' then
    PrintMsg(State.LastError, msg_Error);
  FCS.Acquire;
  try
    InGroupMe:=False; OutGroupMe:=False;
    InGroupCnt:=0; OutGroupCnt:=0;
    sGroups:='0/0';
  finally
    FCS.Release;
    end;
  eMyGroup.Clear;
  eInGroup.Clear;
  eOnlineUsers.Clear;
  eChatUsers.Clear;

  //lblGroups.Visible:=False;
  //lblInvites.Visible:=False;
  //lblOnline.Visible:=False;
  end;

procedure TGateClientForm.ChatLinkDataFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: Boolean);
  begin
  if (Data.CallID=cid_ChatInvite) and (Data.ToGroupID>0) then
    begin
    if Data.Footer then
      Wanted:=True
    else if Data.Header then
      Data.ToBuffer:=True;
    end
  else if (Data.CallID=cid_ChatLeft) and (Data.GroupID>0) then
    begin
    if Data.Footer then
      Wanted:=True
    else if Data.Header then
      Data.ToBuffer:=True;
    end;
  end;

procedure TGateClientForm.ChatLinkDataReceivedGUI(Client: TRtcHttpGateClient; Data: TRtcGateClientData);
  var
    UID:RtcString;
    i:integer;
  begin
  if (Data.CallID=cid_ChatInvite) and (Data.ToGroupID>0) then
    begin
    UID:=Int2Str(Data.UserID)+'/'+Int2Str(Data.ToGroupID);
    if FChatUsers.search(UID)='' then
      begin
      // Add UserID+GroupID to Chat Users invitation list
      eChatUsers.Items.Add(UID);
      // Store Invitation Key for Chat with UserID+GroupID
      FChatUsers.insert(UID,RtcBytesToString(Data.Content));

      if GetActiveWindow<>Handle then MessageBeep(0);
      //lblInvites.Visible:=True;
      end;
    end
  else if (Data.CallID=cid_ChatLeft) and (Data.GroupID>0) then
    begin
    UID:=Int2Str(Data.UserID)+'/'+Int2Str(Data.GroupID);
    if FChatUsers.search(UID)<>'' then
      begin
      i:=eChatUsers.Items.IndexOf(UID);
      eChatUsers.Items.Delete(i);
      FChatUsers.remove(UID);
      //lblInvites.Visible:=eChatUsers.Count > 0;
      end;
    end;
  end;

procedure TGateClientForm.GateCliInfoFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: Boolean);
  begin
  case Data.Command of
    gc_UserOnline,
    gc_UserOffline,
    gc_SubscribeLogIn,
    gc_SubscribeLogOut,
    gc_AccountLogIn,
    gc_AccountLogOut,
    gc_AccountVerified,
    gc_AccountBadVerify,
    gc_UserJoined,
    gc_UserLeft,
    gc_JoinedUser,
    gc_LeftUser,
    gc_Error:       Wanted:=True;
    end;
  end;

procedure TGateClientForm.GateCliInfoReceived(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var WantGUI, WantBackThread: Boolean);
  var
    s:String;
  begin
  case Data.Command of
    gc_UserOnline:  PrintMsg(IntToStr(Data.UserID)+' ON-Line',msg_Group);
    gc_UserOffline: PrintMsg(IntToStr(Data.UserID)+' OFF-Line',msg_Group);

    gc_SubscribeLogIn:   PrintMsg(IntToStr(Data.UserID)+' "'+Data.UserInfo+'" ON-Channel ('+IntToStr(Data.GroupID)+')',msg_Group);
    gc_SubscribeLogOut:  PrintMsg(IntToStr(Data.UserID)+' OFF-Channel ('+IntToStr(Data.GroupID)+')',msg_Group);

    gc_AccountLogIn:  begin
                      S:=Data.AccountID;
                      if S=LobbyAccount then
                        WantGUI:=True;
                      case AccMan.isType[S] of
                        gat_Public: PrintMsg(IntToStr(Data.UserID)+' "'+Data.UserInfo+'" ON-Public "'+AccMan.DisplayName[S]+'"',msg_Group);
                        gat_Private:PrintMsg(IntToStr(Data.UserID)+' "'+Data.UserInfo+'" ON-Private "'+AccMan.DisplayName[S]+'"',msg_Group);
                        gat_Linked: PrintMsg(IntToStr(Data.UserID)+' "'+Data.UserInfo+'" ON-Linked "'+AccMan.DisplayName[S]+'"',msg_Group);
                        end;
                      if Client.VerifiedAccount[Data.UserID,S] then
                        PrintMsg(IntToStr(Data.UserID)+' "'+Data.UserInfo+'" Verified-ON "'+AccMan.DisplayName[S]+'"',msg_Group)
                      else if Client.UserAccount[Data.UserID,S] then
                        PrintMsg(IntToStr(Data.UserID)+' "'+Data.UserInfo+'" Normal-ON "'+AccMan.DisplayName[S]+'"',msg_Group)
                      else if Client.UnVerifiedAccount[Data.UserID,S] then
                        PrintMsg(IntToStr(Data.UserID)+' "'+Data.UserInfo+'" UnVerified-ON "'+AccMan.DisplayName[S]+'"',msg_Group);
                      end;
    gc_AccountLogOut: begin
                      S:=Data.AccountID;
                      if S=LobbyAccount then
                        WantGUI:=True;
                      case AccMan.isType[S] of
                        gat_Public: PrintMsg(IntToStr(Data.UserID)+' OFF-Public "'+AccMan.DisplayName[S]+'"',msg_Group);
                        gat_Private:PrintMsg(IntToStr(Data.UserID)+' OFF-Private "'+AccMan.DisplayName[S]+'"',msg_Group);
                        gat_Linked: PrintMsg(IntToStr(Data.UserID)+' OFF-Linked "'+AccMan.DisplayName[S]+'"',msg_Group);
                        end;
                      if Client.VerifiedAccount[Data.UserID,S] then
                        PrintMsg(IntToStr(Data.UserID)+' Verified-OFF "'+AccMan.DisplayName[S]+'"',msg_Group)
                      else if Client.UserAccount[Data.UserID,S] then
                        PrintMsg(IntToStr(Data.UserID)+' Normal-OFF "'+AccMan.DisplayName[S]+'"',msg_Group)
                      else if Client.UnVerifiedAccount[Data.UserID,S] then
                        PrintMsg(IntToStr(Data.UserID)+' UnVerified-OFF "'+AccMan.DisplayName[S]+'"',msg_Group);
                      end;
    gc_AccountVerified:
                      begin
                      S:=Data.AccountID;
                      case AccMan.isType[S] of
                        gat_Public: PrintMsg(IntToStr(Data.UserID)+' OK-Public "'+AccMan.DisplayName[S]+'"',msg_Group);
                        gat_Private:PrintMsg(IntToStr(Data.UserID)+' OK-Private "'+AccMan.DisplayName[S]+'"',msg_Group);
                        gat_Linked: PrintMsg(IntToStr(Data.UserID)+' OK-Linked "'+AccMan.DisplayName[S]+'"',msg_Group);
                        end;
                      if Client.VerifiedAccount[Data.UserID,S] then
                        PrintMsg(IntToStr(Data.UserID)+' NOW Verified "'+AccMan.DisplayName[S]+'"',msg_Group)
                      else if Client.UserAccount[Data.UserID,S] then
                        PrintMsg(IntToStr(Data.UserID)+' NOW Normal "'+AccMan.DisplayName[S]+'"',msg_Group)
                      else if Client.UnVerifiedAccount[Data.UserID,S] then
                        PrintMsg(IntToStr(Data.UserID)+' NOW UnVerified "'+AccMan.DisplayName[S]+'"',msg_Group);
                      end;
    gc_AccountBadVerify:
                      begin
                      S:=Data.AccountID;
                      case AccMan.isType[S] of
                        gat_Public: PrintMsg(IntToStr(Data.UserID)+' BAD-Public "'+AccMan.DisplayName[S]+'"',msg_Group);
                        gat_Private:PrintMsg(IntToStr(Data.UserID)+' BAD-Private "'+AccMan.DisplayName[S]+'"',msg_Group);
                        gat_Linked: PrintMsg(IntToStr(Data.UserID)+' BAD-Linked "'+AccMan.DisplayName[S]+'"',msg_Group);
                        end;
                      end;

    gc_Error:       PrintMsg('ERR #'+IntToStr(Data.ErrCode)+' from User '+IntToStr(Data.UserID),msg_Group);

    gc_UserJoined,
    gc_UserLeft,
    gc_JoinedUser,
    gc_LeftUser:    WantGUI:=True;
    end;
  end;

procedure TGateClientForm.GateCliInfoReceivedGUI(Client: TRtcHttpGateClient; Data: TRtcGateClientData);
  var
    s:String;
    i:integer;
  begin
  case Data.Command of
    gc_AccountLogIn:  begin
                      S:=Data.AccountID;
                      if S=LobbyAccount then
                        begin
                        S:=IntToStr(Data.UserID);
                        PrintMsg('CHAT +'+S+' ('+IntToStr(OutGroupCnt)+')',msg_Group);
                        if eOnlineUsers.Items.IndexOf(S)<0 then
                          eOnlineUsers.Items.Add(S);
                        //lblOnline.Visible:=eOnlineUsers.Count>0;
                        end;
                      end;
    gc_AccountLogOut: begin
                      S:=Data.AccountID;
                      if S=LobbyAccount then
                        begin
                        S:=IntToStr(Data.UserID);
                        PrintMsg('CHAT -'+S+' ('+IntToStr(OutGroupCnt)+')',msg_Group);
                        i:=eOnlineUsers.Items.IndexOf(S);
                        if i>=0 then eOnlineUsers.Items.Delete(i);
                        //lblOnline.Visible:=eOnlineUsers.Count>0;
                        end;
                      end;
    gc_UserJoined:  begin
                    if Data.UserID=Data.MyUID then
                      OutGroupMe:=True
                    else
                      Inc(OutGroupCnt);
                    S:=IntToStr(Data.UserID)+'/'+INtToStr(Data.GroupID);
                    PrintMsg('OUT +'+S+' ('+IntToStr(OutGroupCnt)+')',msg_Group);
                    if eMyGroup.Items.IndexOf(S)<0 then
                      eMyGroup.Items.Add(S);
                    //lblGroups.Visible:=eMyGroup.Count + eInGroup.Count > 0;
                    end;
    gc_UserLeft:    begin
                    if Data.UserID=Data.MyUID then
                      OutGroupMe:=False
                    else if OutGroupCnt>0 then
                      Dec(OutGroupCnt);
                    S:=IntToStr(Data.UserID)+'/'+IntToStr(Data.GroupID);
                    PrintMsg('OUT -'+S+' ('+IntToStr(OutGroupCnt)+')',msg_Group);
                    i:=eMyGroup.Items.IndexOf(S);
                    if i>=0 then eMyGroup.Items.Delete(i);
                    //lblGroups.Visible:=eMyGroup.Count + eInGroup.Count > 0;
                    end;
    gc_JoinedUser:  begin
                    if Data.UserID=Data.MyUID then
                      InGroupMe:=True
                    else
                      Inc(InGroupCnt);
                    S:=IntToStr(Data.UserID)+'/'+IntToStr(Data.GroupID);
                    PrintMsg('IN +'+S+' ('+IntToStr(InGroupCnt)+')',msg_Group);
                    if eInGroup.Items.IndexOf(S)<0 then
                      eInGroup.Items.Add(S);
                    end;
    gc_LeftUser:    begin
                    if Data.UserID=Data.MyUID then
                      InGroupMe:=False
                    else if InGroupCnt>0 then
                      Dec(InGroupCnt);
                    S:=IntToStr(Data.UserID)+'/'+IntToStr(Data.GroupID);
                    PrintMsg('IN -'+S+' ('+IntToStr(InGroupCnt)+')',msg_Group);
                    i:=eInGroup.Items.IndexOf(S);
                    if i>=0 then eInGroup.Items.Delete(i);
                    end;
    end;
  s:='';
  if InGroupMe then s:=s+'+';
  s:=s+IntToStr(InGroupCnt)+'/'+IntToStr(OutGroupCnt);
  if OutGroupMe then s:=s+'+';
  FCS.Acquire;
  try
    sGroups:=s;
  finally
    FCS.Release;
    end;
  end;

end.
