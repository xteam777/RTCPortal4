{ Copyright (c) Danijel Tkalcec,
  RealThinClient components - http://www.realthinclient.com }

unit rtcpDesktopHost;

interface

{$INCLUDE rtcDefs.inc}
{$INCLUDE rtcPortalDefs.inc}

uses
  Windows, Messages, Classes, SysUtils, Graphics, Controls, Forms, CommonData, BlackLayered, rtcBlankOutForm,
{$IFNDEF IDE_1}
  Variants,
{$ENDIF}
  rtcLog, SyncObjs, rtcpFileUtils,
  rtcInfo, rtcPortalMod, uProcess,

  // cromis units
  Cromis.Comm.Custom, Cromis.Comm.IPC, Cromis.Threading,

{$IFDEF DFMirage}
  dfmVideoDriver,
{$ENDIF}
  rtcZLib, rtcScrUtils,

{$IFDEF KMDriver}
  MouseAInf,
{$ENDIF}

  rtcCompress, rtcWinLogon, rtcSystem,

  uVircessTypes, NTPriveleges,

  rtcpFileTrans, //ImageCatcher,
  rtcpDesktopConst, ServiceMgr,
  Execute.DesktopDuplicationAPI;

var
  RTC_CAPTUREBLT: DWORD = $40000000;

type
  { captureEverything = captures the Desktop and all Windows.
    captureDesktopOnly =  only captures the Desktop background.
    captureWindowOnly = only captures the Window specified in "RtcCaptureWindowHdl" }
  TRtcCaptureMode=(captureEverything, captureDesktopOnly, captureWindowOnly);
  TRtcMouseControlMode=(eventMouseControl, messageMouseControl);

var
  RtcCaptureMode: TRtcCaptureMode = captureEverything;
  RtcCaptureWindowHdl:HWND=0;

  RtcMouseControlMode: TRtcMouseControlMode = eventMouseControl;

type
{  TCursorInfoThread = class(TThread)
  private
    ci: TCursorInfo;
    function GetCursorInfoWithAttach: TCursorInfo;
  protected
    procedure Execute; override;
  end;}

  TRtcScreenCapture = class;
  TRtcPDesktopHost = class;

  TRtcScreenEncoder = class
  private
    CS: TCriticalSection;
    FTmpImage, FTmpLastImage: TBitmap;

    FTmpStorage: RtcByteArray;

    FOldImage, FNewImage: TBitmap;

    FImgIndex, FNewBlockSize: integer;

    FAllBlockSize, FBlockSize, FLastBlockSize: integer;

    FBlockWidth, FBlockHeight, FLastBlockHeight: integer;

    FBytesPerPixel: byte;

    FBlockCount: integer;

    FCaptureWidth, FCaptureHeight, FCaptureLeft, FCaptureTop, FScreenWidth,
      FScreenHeight, FScreenLeft, FScreenTop, FScreenBPP: integer;

    FBPPWidth, FBPPLimit, FMaxTotalSize, FMaxBlockCount: integer;

    FImages: array of TBitmap;
    FMarked: array of boolean;

    FScreenData, FInitialScreenData: TRtcValue;

    FNewScreenPalette: boolean;
    FScreenPalette: RtcString;

    FMyScreenInfoChanged: boolean;
    FScreenInfoChanged: boolean;
    FScreenGrabBroken: boolean;
    FScreenGrabFrom: integer;
    FUseCaptureMarks: boolean;
    FFullScreen: boolean;
    FFixedRegion: TRect;
    FReduce16bit: longword;
    FReduce32bit: longword;
    FCaptureMask: DWORD;
    FMultiMon: boolean;

    fFirstScreen: Boolean;
    ScrCap: TRtcScreenCapture;

//    FImageCatcher: TImageCatcher;
    FDDACreated: Boolean;
    FDesktopDuplicator: TDesktopDuplicationWrapper;

    function CreateBitmap(index: integer): TBitmap;

  protected
    procedure PrepareStorage;
    procedure ReleaseStorage;

    procedure SetBlockIndex(index: integer);
    function CaptureBlock: boolean;
//    function GetDDAScreenshot: Boolean;

    function CompressBlock_Initial: RtcByteArray;
    function CompressBlock_Normal: RtcByteArray;
    function CompressBlock_Delta: RtcByteArray;

    procedure StoreBlock;

    function ScreenChanged: boolean;
    procedure CaptureScreenInfo;

    property BlockCount: integer read FBlockCount;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Setup(BPPLimit, MaxBlockCount, MaxTotalSize: integer);

    procedure MarkForCapture(x1, y1, x2, y2: integer); overload;
    procedure MarkForCapture; overload;

    function Capture(SleepTime: integer = 0; Initial: boolean = False): boolean;

    function GetInitialScreenData: TRtcValue;
    function GetScreenData: TRtcValue;

    function GetScreenFromHelperByMMF(OnlyGetScreenParams: Boolean = False; fFirstScreen: Boolean = False): Boolean;

    property CaptureMask: DWORD read FCaptureMask write FCaptureMask;
    property UseCaptureMarks: boolean read FUseCaptureMarks
      write FUseCaptureMarks;
    property FullScreen: boolean read FFullScreen write FFullScreen
      default True;
    property FixedRegion: TRect read FFixedRegion write FFixedRegion;

    property Reduce16bit: longword read FReduce16bit write FReduce16bit;
    property Reduce32bit: longword read FReduce32bit write FReduce32bit;

    property MultiMonitor: boolean read FMultiMon write FMultiMon;
  end;

  TRtcScreenCapture = class
  private
{$IFDEF DFMirage}
    vd: TVideoDriver;
    m_BackBm: TBitmap;
    m_Init: boolean;
    FMirage: boolean;
    dfm_ImgLine0: PAnsiChar;
    dfm_DstStride: integer;
    dfm_urgn: TGridUpdRegion;
    dfm_fixed: TRect;
    ScrDeltaRec: TRtcRecord;
{$ENDIF}
    ScrIn: TRtcScreenEncoder;

    FCaptureMask: DWORD;
    FBPPLimit, FMaxTotalSize, FScreen2Delay, FScreenBlockCount,
      FScreen2BlockCount: integer;

    FFullScreen: boolean;
    FFixedRegion: TRect;

    FShiftDown, FCtrlDown, FAltDown: boolean;

    FMouseX, FMouseY, FMouseHotX, FMouseHotY: integer;
    FMouseVisible: boolean;
    FMouseHandle: HICON;
    FMouseIcon: TBitmap;
    FMouseIconMask: TBitmap;
    FMouseShape: integer;

    FMouseChangedShape: boolean;
    FMouseMoved: boolean;
    FMouseLastVisible: boolean;
    FMouseInit: boolean;
    FMouseUser: String;

    FLastMouseUser: String;
    FLastMouseX, FLastMouseY: integer;

    FReduce32bit, FReduce16bit, FLowReduce32bit, FLowReduce16bit: DWORD;

    FLowReduceColors: boolean;
    FLowReduceType: integer;
    FLowReduceColorPercent: integer;

    FCaptureWidth, FCaptureHeight, FCaptureLeft, FCaptureTop, FScreenWidth,
      FScreenHeight, FScreenLeft, FScreenTop: longint;
    FMouseDriver: boolean;

    FMultiMon: boolean;

    FPDesktopHost: TRtcPDesktopHost;

    procedure Init;
    procedure InitSize;

{$IFDEF DFMirage}
    function ScreenChanged: boolean;
    function GrabImageFullscreen: TRtcRecord;
    function GrabImageIncremental: TRtcRecord;
    function GrabImageOldScreen: TRtcRecord;
{$ENDIF}
    function GetMirageDriver: boolean;
    procedure SetMirageDriver(const Value: boolean);

    function GetLayeredWindows: boolean;
    procedure SetLayeredWindows(const Value: boolean);

    function GetBPPLimit: integer;
    procedure SetBPPLimit(const Value: integer);

    function GetMaxTotalSize: integer;
    procedure SetMaxTotalSize(const Value: integer);

    function GetFixedRegion: TRect;
    function GetFullScreen: boolean;

    procedure SetFixedRegion(const Value: TRect);
    procedure SetFullScreen(const Value: boolean);

    function GetReduce16bit: longword;
    function GetReduce32bit: longword;
    procedure SetReduce16bit(const Value: longword);
    procedure SetReduce32bit(const Value: longword);

    procedure Post_MouseDown(Button: TMouseButton);
    procedure Post_MouseUp(Button: TMouseButton);
    procedure Post_MouseMove(X, Y: integer);
    procedure Post_MouseWheel(Wheel: integer);

    procedure keybdevent(key: word; Down: boolean = True; Extended: boolean=False);

    procedure SetKeys(capslock, lWithShift, lWithCtrl, lWithAlt: boolean);
    procedure ResetKeys(capslock, lWithShift, lWithCtrl, lWithAlt: boolean);

    procedure SetMouseDriver(const Value: boolean);
    procedure SetMultiMon(const Value: boolean);
    function GetLowReduce16bit: longword;
    function GetLowReduce32bit: longword;
    procedure SetLowReduce16bit(const Value: longword);
    procedure SetLowReduce32bit(const Value: longword);

    function GetLowReduceColors: boolean;
    procedure SetLowReduceColors(const Value: boolean);

    function GetLowReduceColorPercent: integer;
    procedure SetLowReduceColorPercent(const Value: integer);
    function GetScreenBlockCount: integer;
    procedure SetScreenBlockCount(const Value: integer);
    function GetScreen2BlockCount: integer;
    procedure SetScreen2BlockCount(const Value: integer);
    function GetScreen2Delay: integer;
    procedure SetScreen2Delay(const Value: integer);
    function GetLowReduceType: integer;
    procedure SetLowReduceType(const Value: integer);

    function GetHaveScreen: Boolean;
    procedure SetHaveScreen(const Value: Boolean);

  public
//    tCursorInfoThrd: TCursorInfoThread;
//++
//    fSASInit: Boolean;
//    procedure CheckSAS(value : Boolean; name : String);
//    function DoElevatedTask(const Host, AParameters: String): Cardinal;
//    function GetCursorInfoFromThread: TCursorInfo;

    constructor Create; virtual;
    destructor Destroy; override;

    procedure Clear;
    function GrabScreen: boolean;
    procedure GrabMouse;

    function GetScreen: RtcString;
    function GetScreenDelta: RtcString;

    function GetMouse: RtcString;
    function GetMouseDelta: RtcString;

    function MirageDriverInstalled(Init: boolean = False): boolean;

    // control events
    procedure MouseDown(const user: String; X, Y: integer;
      Button: TMouseButton);
    procedure MouseUp(const user: String; X, Y: integer; Button: TMouseButton);
    procedure MouseMove(const user: String; X, Y: integer);
    procedure MouseWheel(Wheel: integer);

    procedure KeyPressW(const AText: WideString; AKey: word);
//    procedure KeyPress(const AText: RtcString; AKey: word);
    procedure KeyDown(key: word; Shift: TShiftState);
    procedure KeyUp(key: word; Shift: TShiftState);

    procedure SpecialKey(const AKey: RtcString);
//    function Block_UserInput_Hook(fBlockInput: Boolean): Boolean;

    procedure LWinKey(key: word);
    procedure RWinKey(key: word);

    procedure ReleaseAllKeys;

    property MirageDriver: boolean read GetMirageDriver write SetMirageDriver
      default False;
    property LayeredWindows: boolean read GetLayeredWindows
      write SetLayeredWindows default False;
    property BPPLimit: integer read GetBPPLimit write SetBPPLimit default 4;
    property MaxTotalSize: integer read GetMaxTotalSize write SetMaxTotalSize
      default 0;
    property ScreenBlockCount: integer read GetScreenBlockCount
      write SetScreenBlockCount default 1;
    property Screen2BlockCount: integer read GetScreen2BlockCount
      write SetScreen2BlockCount default 1;
    property Screen2Delay: integer read GetScreen2Delay write SetScreen2Delay
      default 0;
    property FullScreen: boolean read GetFullScreen write SetFullScreen
      default True;
    property FixedRegion: TRect read GetFixedRegion write SetFixedRegion;

    property Reduce16bit: longword read GetReduce16bit write SetReduce16bit;
    property Reduce32bit: longword read GetReduce32bit write SetReduce32bit;
    property LowReduce16bit: longword read GetLowReduce16bit
      write SetLowReduce16bit;
    property LowReduce32bit: longword read GetLowReduce32bit
      write SetLowReduce32bit;
    property LowReducedColors: boolean read GetLowReduceColors
      write SetLowReduceColors;
    property LowReduceType: integer read GetLowReduceType
      write SetLowReduceType;
    property LowReduceColorPercent: integer read GetLowReduceColorPercent
      write SetLowReduceColorPercent;

    property ScreenWidth: longint read FScreenWidth;
    property ScreenHeight: longint read FScreenHeight;
    property ScreenLeft: longint read FScreenLeft;
    property ScreenTop: longint read FScreenTop;

    property MouseDriver: boolean read FMouseDriver write SetMouseDriver
      default False;
    property MultiMonitor: boolean read FMultiMon write SetMultiMon
      default False;

    property HaveScreen: Boolean read GetHaveScreen write SetHaveScreen default False;
  end;

  TRtcPFileTransUserEvent = procedure(Sender: TRtcPDesktopHost;
    const user: String) of object;
  TRtcPFileTransFolderEvent = procedure(Sender: TRtcPDesktopHost;
    const user: String; const FileName, path: String; const size: int64)
    of object;
  TRtcPFileTransCallEvent = procedure(Sender: TRtcPDesktopHost;
    const user: String; const Data: TRtcFunctionInfo) of object;
  TRtcPFileTransListEvent = procedure(Sender: TRtcPDesktopHost;
    const user: String; const FolderName: String; const Data: TRtcDataSet)
    of object;

  TRtcPDesktopHost = class(TRtcPModule)
  private
    CS2: TCriticalSection;
    Clipboards: TRtcRecord;
    FLastMouseUser: String;
    FDesktopActive: boolean;

    Scr: TRtcScreenCapture;
    LastGrab: longword;

    FramePause, FrameSleep: longword;

    RestartRequested: boolean;

    FShowFullScreen: boolean;
    FScreenRect: TRect;

    FUseMouseDriver: boolean;
    FUseMirrorDriver: boolean;
    FCaptureAllMonitors: boolean;
    FCaptureLayeredWindows: boolean;
    FScreenInBlocks: TrdScreenBlocks;
    FScreenRefineBlocks: TrdScreenBlocks;
    FScreenRefineDelay: integer;
    FScreenSizeLimit: TrdScreenLimit;

    FColorLimit: TrdColorLimit;
    FLowColorLimit: TrdLowColorLimit;
    FColorReducePercent: integer;
    FFrameRate: TrdFrameRate;

    FAllowControl: boolean;
    FAllowView: boolean;

    FAllowSuperControl: boolean;
    FAllowSuperView: boolean;

    loop_needtosend, loop_need_restart: boolean;
    loop_s1, loop_s2: RtcString;

    _desksub: TRtcArray;
    _sub_desk: TRtcRecord;

    FAccessControl: boolean;
    FGatewayParams: boolean;

    FFileTrans: TRtcPFileTransfer;

    //FileTrans+
    loop_tosendfile: boolean;
    loop_update: TRtcArray;

    WantToSendFiles, PrepareFiles, UpdateFiles: TRtcRecord;
    SendingFiles: TRtcArray;
    File_Sending: boolean;
    File_Senders: integer;

    FMaxSendBlock: longint;
    FMinSendBlock: longint;

    FOnFileReadStart: TRtcPFileTransFolderEvent;
    FOnFileRead: TRtcPFileTransFolderEvent;
    FOnFileReadUpdate: TRtcPFileTransFolderEvent;
    FOnFileReadStop: TRtcPFileTransFolderEvent;
    FOnFileReadCancel: TRtcPFileTransFolderEvent;

    FOnFileWriteStart: TRtcPFileTransFolderEvent;
    FOnFileWrite: TRtcPFileTransFolderEvent;
    FOnFileWriteStop: TRtcPFileTransFolderEvent;
    FOnFileWriteCancel: TRtcPFileTransFolderEvent;

    FOnCallReceived: TRtcPFileTransCallEvent;

    FHostMode: boolean;
    //FileTrans-

    //FileTrans+
    procedure InitData;

    function StartSendingFile(const UserName: String; const path: String;
      idx: integer): boolean;
    function CancelFileSending(Sender: TObject; const uname, FileName, folder: String): int64;
    procedure StopFileSending(Sender: TObject; const uname: String);

    procedure Event_FileReadStart(Sender: TObject; const user: String;
      const fname, fromfolder: String; size: int64);
    procedure Event_FileRead(Sender: TObject; const user: String;
      const fname, fromfolder: String; size: int64);
    procedure Event_FileReadUpdate(Sender: TObject; const user: String);
    procedure Event_FileReadStop(Sender: TObject; const user: String;
      const fname, fromfolder: String; size: int64);
    procedure Event_FileReadCancel(Sender: TObject; const user: String;
      const fname, fromfolder: String; size: int64);

    procedure Event_FileWriteStart(Sender: TObject; const user: String;
      const fname, tofolder: String; size: int64);
    procedure Event_FileWrite(Sender: TObject; const user: String;
      const fname, tofolder: String; size: int64);
    procedure Event_FileWriteStop(Sender: TObject; const user: String;
      const fname, tofolder: String; size: int64);
    procedure Event_FileWriteCancel(Sender: TObject; const user: String;
      const fname, tofolder: String; size: int64);

    procedure Event_CallReceived(Sender: TObject; const user: String;
      const Data: TRtcFunctionInfo);

    procedure CallFileEvent(Sender: TObject; Event: TRtcCustomDataEvent;
      const user: String; const FileName, folder: String; size: int64);
      overload;
    procedure CallFileEvent(Sender: TObject; Event: TRtcCustomDataEvent;
      const user: String); overload;
    procedure CallFileEvent(Sender: TObject; Event: TRtcCustomDataEvent;
      const user: String; const Data: TRtcFunctionInfo); overload;
    procedure CallFileEvent(Sender: TObject; Event: TRtcCustomDataEvent;
      const user: String; const FolderName: String;
      const Data: TRtcDataSet); overload;
    //FileTrans-

    procedure setClipboard(const username: String; const data: RtcString);

    procedure ScrStart;
    procedure ScrStop;

    function GetLastMouseUser: String;
    function GetColorLimit: TrdColorLimit;
    function GetLowColorLimit: TrdLowColorLimit;
    function GetFrameRate: TrdFrameRate;
    function GetShowFullScreen: boolean;
    function GetUseMirrorDriver: boolean;
    function GetUseMouseDriver: boolean;
    function GetCaptureLayeredWindows: boolean;

    procedure SetColorLimit(const Value: TrdColorLimit);
    procedure SetLowColorLimit(const Value: TrdLowColorLimit);
    procedure SetFrameRate(const Value: TrdFrameRate);
    procedure SetShowFullScreen(const Value: boolean);
    procedure SetUseMirrorDriver(const Value: boolean);
    procedure SetUseMouseDriver(const Value: boolean);
    procedure SetCaptureLayeredWindows(const Value: boolean);

    function setDeskSubscriber(const username: String; active: boolean)
      : boolean;

    function GetAllowControl: boolean;
    function GetAllowSuperControl: boolean;
    function GetAllowSuperView: boolean;
    function GetAllowView: boolean;
    procedure SetAllowControl(const Value: boolean);
    procedure SetAllowSuperControl(const Value: boolean);
    procedure SetAllowSuperView(const Value: boolean);
    procedure SetAllowView(const Value: boolean);

    function GetCaptureAllMonitors: boolean;
    procedure SetCaptureAllMonitors(const Value: boolean);

    function GetColorReducePercent: integer;
    procedure SetColorReducePercent(const Value: integer);

    function MayViewDesktop(const user: String): boolean;
    function MayControlDesktop(const user: String): boolean;

    procedure SetFileTrans(const Value: TRtcPFileTransfer);
    procedure MakeDesktopActive;

    function GetSendScreenInBlocks: TrdScreenBlocks;
    function GetSendScreenRefineBlocks: TrdScreenBlocks;
    function GetSendScreenRefineDelay: integer;
    function GetSendScreenSizeLimit: TrdScreenLimit;

    procedure SetSendScreenInBlocks(const Value: TrdScreenBlocks);
    procedure SetSendScreenRefineBlocks(const Value: TrdScreenBlocks);
    procedure SetSendScreenRefineDelay(const Value: integer);
    procedure SetSendScreenSizeLimit(const Value: TrdScreenLimit);

  protected
    // Implement if you are linking to any other TRtcPModule. Usage:
    // Check if you are refferencing the "Module" component and remove the refference
    procedure UnlinkModule(const Module: TRtcPModule); override;

    function SenderLoop_Check(Sender: TObject): boolean; override;
    procedure SenderLoop_Prepare(Sender: TObject); override;
    procedure SenderLoop_Execute(Sender: TObject); override;

    procedure Call_LogIn(Sender: TObject); override;
    procedure Call_LogOut(Sender: TObject); override;
    procedure Call_Error(Sender: TObject; data: TRtcValue); override;
    procedure Call_FatalError(Sender: TObject; data: TRtcValue); override;

    procedure Call_Start(Sender: TObject; data: TRtcValue); override;
    procedure Call_Params(Sender: TObject; data: TRtcValue); override;

    procedure Call_BeforeData(Sender: TObject); override;

    // procedure Call_UserLoggedIn(Sender: TObject; const uname: String; uinfo:TRtcRecord); override;
    // procedure Call_UserLoggedOut(Sender: TObject; const uname: String); override;

    procedure Call_UserJoinedMyGroup(Sender: TObject; const group: String;
      const uname: String; uinfo:TRtcRecord); override;
    procedure Call_UserLeftMyGroup(Sender: TObject; const group: String;
      const uname: String); override;

    // procedure Call_JoinedUsersGroup(Sender: TObject; const group: String; const uname: String; uinfo:TRtcRecord); override;
    // procedure Call_LeftUsersGroup(Sender: TObject; const group: String; const uname: String); override;

    procedure Call_DataFromUser(Sender: TObject; const uname: String;
      data: TRtcFunctionInfo); override;

    procedure Call_AfterData(Sender: TObject); override;

    procedure Init; override;

    //FileTrans+
    procedure xOnFileReadStart(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileRead(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileReadUpdate(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileReadStop(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileReadCancel(Sender, Obj: TObject; Data: TRtcValue);

    procedure xOnFileWriteStart(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileWrite(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileWriteStop(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileWriteCancel(Sender, Obj: TObject; Data: TRtcValue);

    procedure xOnCallReceived(Sender, Obj: TObject; Data: TRtcValue);
    //FileTrans-

  public
    FHaveScreen: Boolean;
    FOnHaveScreeenChanged: TNotifyEvent;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Restart;

    // Open Desktop session for user "uname"
    procedure Open(const uname: String; Sender: TObject = nil);

    // Close all Desktop sessions: all users viewing or controlling our Desktop will be disconnected.
    procedure CloseAll(Sender: TObject = nil);
    // Close Desktop sessions for user "uname"
    procedure Close(const uname: String; Sender: TObject = nil);

    property LastMouseUser: String read GetLastMouseUser;

    function MirrorDriverInstalled(Init: boolean = False): boolean;

    //FileTrans+
    { Send (upload) File or Folder "FileName" (specify full path) to folder "ToFolder" (will use INBOX folder if not specified) at user "UserName".
      If file transfer was not prepared by calling "OpenFiles", it will be after this call. }
    procedure Send(const UserName: String; const FileName: String;
      const tofolder: String = ''; Sender: TObject = nil);

    { Fetch (download) File or Folder "FileName" (specify full path) from user "username" to folder "ToFolder" (will use INBOX folder if not specified).
      If file transfer was not prepared by calling "OpenFiles", it will be after this call. }
    procedure Fetch(const UserName: String; const FileName: String;
      const tofolder: String = ''; Sender: TObject = nil);

    procedure Cancel_Send(const UserName: String; const FileName: string;
      const tofolder: String = ''; Sender: TObject = nil);
    procedure Cancel_Fetch(const UserName: String; const FileName: string;
      const tofolder: String = ''; Sender: TObject = nil);

    procedure Call(const UserName: String; const Data: TRtcFunctionInfo;
      Sender: TObject = nil);
    //FileTrans-

  published
    { Set to TRUE if you wish to store access right and screen parameters on the Gateway
      and load parameters from the Gateway after Activating the component.
      When gwStoreParams is FALSE, parameter changes will NOT be sent to the Gateway,
      nor will current parameters stored on the Gateway be loaded on start. }
    property GwStoreParams: boolean read FGatewayParams write FGatewayParams
      default False;

    { Set to FALSE if you want to ignore Access right settings and allow all actions,
      regardless of user lists and AllowView/Control parameters set by this user. }
    property AccessControl: boolean read FAccessControl write FAccessControl
      default True;

    { Allow users to View our Desktop?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowView: boolean read GetAllowView write SetAllowView
      default True;
    { Allow Super users to View our Desktop?
      If geStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowView_Super: boolean read GetAllowSuperView
      write SetAllowSuperView default True;

    { Allow users to Control our Desktop?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowControl: boolean read GetAllowControl write SetAllowControl
      default True;
    { Allow Super users to Control our Desktop?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowControl_Super: boolean read GetAllowSuperControl
      write SetAllowSuperControl default True;

    { This property defines in how many frames the Screen image will be split when processing the first image pass.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GSendScreenInBlocks: TrdScreenBlocks read GetSendScreenInBlocks
      write SetSendScreenInBlocks default rdBlocks1;
    { This property defines in how many steps the Screen image will be refined.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GSendScreenRefineBlocks: TrdScreenBlocks
      read GetSendScreenRefineBlocks write SetSendScreenRefineBlocks
      default rdBlocks1;
    { This property defines minimum delay (in seconds) before the Screen image can be refined.
      If the value is zero, a default delay of 500 ms (0.5 seconds) will be used.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GSendScreenRefineDelay: integer read GetSendScreenRefineDelay
      write SetSendScreenRefineDelay default 0;
    { This property defines how much data can be sent in a single screen frame.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GSendScreenSizeLimit: TrdScreenLimit read GetSendScreenSizeLimit
      write SetSendScreenSizeLimit default rdBlockAnySize;
    { Use Video Mirror Driver (if installed)?
      Using video mirror driver can greatly improve remote desktop performance.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GUseMirrorDriver: boolean read GetUseMirrorDriver
      write SetUseMirrorDriver default False;
    { Use Virtual Mouse Driver (if DLL and SYS files are available)?
      Using virtual mouse driver makes it possible to control the UAC screen on Vista,
      but requires the EXE to be compiled with the "rtcportaluac" manifest file,
      signed with a trusted certificate and placed in a trusted folder like "C:/Program Files". }
    property GUseMouseDriver: boolean read GetUseMouseDriver
      write SetUseMouseDriver default False;
    { Capture Layered Windows even if not using mirror driver (slows down screen capture)?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GCaptureLayeredWindows: boolean read GetCaptureLayeredWindows
      write SetCaptureLayeredWindows default False;
    { Capture Screen from All Monotirs when TRUE, or only from the Primary Display when FALSE.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GCaptureAllMonitors: boolean read GetCaptureAllMonitors
      write SetCaptureAllMonitors default False;

    { Limiting the number of colors can reduce bandwidth needs and improve performance.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GColorLimit: TrdColorLimit read GetColorLimit write SetColorLimit
      default rdColor8bit;
    { Setting LowColorLimit value lower than ColorLimit value will use dynamic color reduction to
      improve performance by sending the image in LowColorLimit first and then refining up to ColorLimit.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GColorLowLimit: TrdLowColorLimit read GetLowColorLimit
      write SetLowColorLimit default rd_ColorHigh;
    { ColorReducePercent defines the minimum percentage (0-100) by which the normal color
      image has to be reduced in size using low color limit in order to use the low color image.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GColorReducePercent: integer read GetColorReducePercent
      write SetColorReducePercent default 0;
    { Reducing Frame rate can reduce CPU usage and bandwidth needs.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GFrameRate: TrdFrameRate read GetFrameRate write SetFrameRate
      default rdFramesMax;

    { If FullScreen is TRUE, the whole Screen (Desktop region) is sent.
      If FullScreen is FALSE, only the part defined with "ScreenRect" is sent.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GFullScreen: boolean read GetShowFullScreen write SetShowFullScreen
      default True;

    { Rectangular Screen Region to be sent when FullScreen is FALSE.
      This parameter is NOT stored on the Gateway. }
    property ScreenRect: TRect read FScreenRect write FScreenRect;

    { FileTransfer component to be used when we need to send a file to a user. }
    property FileTransfer: TRtcPFileTransfer read FFileTrans write SetFileTrans;

    { User with username = "user" is asking for access to our Desktop.
      Note that ONLY users with granted access will trigger this event. If you have already limited
      access to this Host by using the AllowUsersList, users who are NOT on that list will be ignored
      and no events will be triggered for them. So ... you could leave this event empty (not implemented)
      if you want to allow access to all users with granted access rights, or you could implement this event
      to set the "Allow" parmeter (passed into the event as TRUE) saying if this user may access our Desktop.

      If you implement this event, make sure it will not take longer than 20 seconds to complete, because
      this code is executed from the context of a connection component responsible for receiving data from
      the Gateway and if this component does not return to the Gateway before time runs out, the client will
      be disconnected from the Gateway. If you implement this event by using a dialog for the user, that dialog
      will have to auto-close whithin no more than 20 seconds automatically, selecting what ever you find apropriate. }
    property OnQueryAccess;
    { We have a new Desktop Host user, username = "user".
      You can use this event to maintain a list of active Desktop Host users. }
    property OnUserJoined;
    { "User" no longer has our Desktop Host open.
      You can use this event to maintain a list of active Desktop Host users. }
    property OnUserLeft;

    property HaveScreen: Boolean read FHaveScreen;
    property OnHaveScreeenChanged: TNotifyEvent read FOnHaveScreeenChanged write FOnHaveScreeenChanged;

    //FileTrans+
    { FileTransfer has 2 sides. For two clients to be able to exchange files,
      at least one side has to have BeTheHost property set to True.
      You can NOT send files between two clients if they both have BeTheHost=False.
      On the other hand, if two clients have BeTheHost=True, the one to initiate
      file transfer will become the host for the duration of file transfer. }
    property BeTheHost: boolean read FHostMode write FHostMode default False;

    { Minimum chunk size (in bytes) worth sending in a loop, if we have already some data to send. }
    property MinSendChunkSize: longint read FMinSendBlock write FMinSendBlock
      default RTCP_DEFAULT_MINCHUNKSIZE;

    { Large files are split in smaller chunks. Maximum allowed chunk size is MaxSendChunkSize bytes.
      Any file larger than MaxSendChunkSize will be split in chunks of MaxSendChunkSize when sending.
      Using larger chunks may improve performance, but it can also increase the risk of a file
      never reaching it's destination if the connection is not good enough to hold for so long.
      By splitting files in smaller chunks, you allow the connection to close and be reopened
      between each file chunk, so the ammount of data that needs to be re-sent is lower. }
    property MaxSendChunkSize: longint read FMaxSendBlock write FMaxSendBlock
      default RTCP_DEFAULT_MAXCHUNKSIZE;

    property On_FileSendStart: TRtcPFileTransFolderEvent read FOnFileReadStart
      write FOnFileReadStart;
    property On_FileSend: TRtcPFileTransFolderEvent read FOnFileRead
      write FOnFileRead;
    property On_FileSendUpdate: TRtcPFileTransFolderEvent read FOnFileReadUpdate
      write FOnFileReadUpdate;
    property On_FileSendStop: TRtcPFileTransFolderEvent read FOnFileReadStop
      write FOnFileReadStop;
    property On_FileSendCancel: TRtcPFileTransFolderEvent read FOnFileReadCancel
      write FOnFileReadCancel;

    property On_FileRecvStart: TRtcPFileTransFolderEvent read FOnFileWriteStart
      write FOnFileWriteStart;
    property On_FileRecv: TRtcPFileTransFolderEvent read FOnFileWrite
      write FOnFileWrite;
    property On_FileRecvStop: TRtcPFileTransFolderEvent read FOnFileWriteStop
      write FOnFileWriteStop;
    property On_FileRecvCancel: TRtcPFileTransFolderEvent
      read FOnFileWriteCancel write FOnFileWriteCancel;

    property On_CallReceived: TRtcPFileTransCallEvent read FOnCallReceived
      write FOnCallReceived;
    //FileTrans-
  end;

//function CaptureFullScreen(MultiMon: boolean; PixelFormat: TPixelFormat = pf8bit): TBitmap;

//function GetCursorInfo2(var pci: PCursorInfo): BOOL; stdcall; external 'user32.dll' name 'GetCursorInfo';

  procedure SendIOToHelperByIPC(QueryType: Cardinal; IOType: DWORD; dwFlags: DWORD; dx, dy: Longint; mouseData: Integer; wVk, wScan: WORD; AText: WideString);
  function NeedSendIOToHelper: Boolean;

var
  FHelper_Width, FHelper_Height: Integer;
  FHelper_BitsPerPixel: Word;
  FHelper_mouseFlags: DWORD;
  FHelper_mouseCursor: HCURSOR;
  FHelper_mouseX, FHelper_mouseY: LongInt;

implementation

uses Math, Types;
{$IFDEF KMDriver}

const
  RMX_MAGIC_NUMBER = 777;

var
  FMouseAInit: Integer = 0;
  home_window_station: HWINSTA;
//  hCursorInfoEventWriteBegin, hCursorInfoEventWriteEnd: THandle;
//  ThreadHandle2: THandle = 0;
//  dwTId: DWORD;
//  m_Black_window_active: Boolean = False;

//  m_OldPowerOffTimeout: Integer;
{$ENDIF}

  (*
    type
    TMyWinList=class
    cnt:integer;
    list:array[1..1000] of HWnd;
    end;

    function _EnumWindowsProc(Wnd: HWnd; const obj:TMyWinList): Bool; export; stdcall;
    begin
    if (obj.cnt<1000) and IsWindowVisible(Wnd) then
    begin
    if (GetWindowLong(Wnd, GWL_EXSTYLE) and WS_EX_LAYERED) = WS_EX_LAYERED then
    begin
    Inc(obj.cnt);
    obj.list[obj.cnt]:=Wnd;
    end;
    EnumChildWindows(Wnd, @_EnumWindowsProc, longint(obj));
    end;
    Result:=True;
    end;

    function GetLayeredWindowsList:TMyWinList;
    begin
    Result:=TMyWinList.Create;
    Result.cnt:=0;
    EnumDesktopWindows(GetThreadDesktop(Windows.GetCurrentThreadId),@_EnumWindowsProc, Longint(Result));
    end;
  *)

{function IsKeyDown(const VK: integer): boolean;
begin
  IsKeyDown := GetKeyState(VK) and $8000 <> 0;
end;

function IsKeyOn(const VK: Integer): boolean;
begin
  IsKeyOn := GetKeyState(VK) and 1 = 1;
end;}

{procedure TCursorInfoThread.Execute;
begin
  while not Terminated do
  begin
    if (hCursorInfoEventWriteBegin = 0)
      or (hCursorInfoEventWriteEnd = 0) then
    begin
      Sleep(10);
      Continue;
    end;

    WaitForSingleObject(hCursorInfoEventWriteBegin, INFINITE);
    ci := GetCursorInfoWithAttach;
    ResetEvent(hCursorInfoEventWriteBegin);
    SetEvent(hCursorInfoEventWriteEnd);
  end;
end;}

function DoCreateEvent(AName: String): THandle;
var
  SD: TSecurityDescriptor;
  SA: TSecurityAttributes;
  pSA: PSecurityAttributes;
begin
  if not InitializeSecurityDescriptor(@SD, SECURITY_DESCRIPTOR_REVISION) then
    xLog(Format('Error InitializeSecurityDescriptor: %s', [SysErrorMessage(GetLastError)]));

  SA.nLength := SizeOf(TSecurityAttributes);
  SA.lpSecurityDescriptor := @SD;
  SA.bInheritHandle := False;

  if not SetSecurityDescriptorDacl(SA.lpSecurityDescriptor, True, nil, False) then
    xLog(Format('Error SetSecurityDescriptorDacl: %s', [SysErrorMessage(GetLastError)]));

  pSA := @SA;

  Result := CreateEvent(pSA, True, False, PChar(AName));

  if Result = 0 then
    xLog(Format('Error CreateEvent: %s', [SysErrorMessage(GetLastError)]));
end;

function DoCreateMutex(AName: String): THandle;
var
  SD: TSecurityDescriptor;
  SA: TSecurityAttributes;
  pSA: PSecurityAttributes;
begin
  if not InitializeSecurityDescriptor(@SD, SECURITY_DESCRIPTOR_REVISION) then
    xLog(Format('Error InitializeSecurityDescriptor: %s', [SysErrorMessage(GetLastError)]));

  SA.nLength := SizeOf(TSecurityAttributes);
  SA.lpSecurityDescriptor := @SD;
  SA.bInheritHandle := False;

  if not SetSecurityDescriptorDacl(SA.lpSecurityDescriptor, True, nil, False) then
    xLog(Format('Error SetSecurityDescriptorDacl: %s', [SysErrorMessage(GetLastError)]));

  pSA := @SA;

  Result := CreateMutex(pSA, False, PWideChar(WideString(AName)));

  if Result = 0 then
    xLog(Format('Error CreateMutex: %s', [SysErrorMessage(GetLastError)]));
end;

function ShiftStateToInt(const Value: TShiftState): Integer;
begin
  if Value = [ssShift] then
    Result := 0
  else
  if Value = [ssAlt] then
    Result := 1
  else
  if Value = [ssCtrl] then
    Result := 2
  else
  if Value = [ssLeft] then
    Result := 3
  else
  if Value = [ssRight] then
    Result := 4
  else
  if Value = [ssMiddle] then
    Result := 5
  else
  if Value = [ssDouble] then
    Result := 6
  else
  if Value = [ssTouch] then
    Result := 7
  else
  if Value = [ssPen] then
    Result := 8
  else
  if Value = [ssCommand] then
    Result := 9
  else
  if Value = [ssHorizontal] then
    Result := 10
  else
    Result := 11;
end;

function GetCaptureWindow:HWND;
var
  h1, h2:HWND;
  name: array[0..255] of Char;
  DesktopName: String;
  Count: DWORD;
begin
//  GetUserObjectInformation(GetThreadDesktop(GetCurrentThreadID), UOI_NAME, @name, 256, Count);
//  SetString(DesktopName, name, Pred(Count));
//
//  if Pos('Default', DesktopName) > 0 then
  if RtcCaptureMode=captureWindowOnly then
    Result:=RtcCaptureWindowHdl
  else
    h1 := GetDesktopWindow;
//  else
//    h1 := 0; //GetDesktopWindow;
//  if (h1<>0) and (RtcCaptureMode=captureDesktopOnly) then
//    begin
//    h2 := FindWindowEx (h1, 0, 'Progman', 'Program Manager');
//    if h2<>0 then h1:=h2;
//    end;
  Result:=h1;
end;

//function CaptureFullScreen(MultiMon: boolean;
//  PixelFormat: TPixelFormat = pf8bit): TBitmap;
//var
//  DW: HWND;
//  SDC: HDC;
//  X, Y: integer;
//begin
// SwitchToActiveDesktop; //Если под SYSTEM
////  SetWinSta0Desktop;
//
//  Result := TBitmap.Create;
//  Result.PixelFormat := PixelFormat;
//
//{$IFDEF MULTIMON}
//  if MultiMon then
//  begin
//    Result.Width := Screen.DesktopWidth;
//    Result.Height := Screen.DesktopHeight;
//    X := Screen.DesktopLeft;
//    Y := Screen.DesktopTop;
//  end
//  else
//{$ENDIF}
//  begin
//    Result.Width := Screen.Width;
//    Result.Height := Screen.Height;
//    X := 0;
//    Y := 0;
//  end;
//
//  Result.Canvas.Lock;
//  try
////    if ((Win32MajorVersion >= 6) and (Win32MinorVersion >= 2) {Windows 8})
////      or (Win32MajorVersion = 10) then
////    begin
//////      FDesktopDuplicator.
////    end
////    else
////    begin
//
//      if LowerCase(GetInputDesktopName) <> 'default' then
//        GetScreenFromHelperByMMF(Result)
//      else
//      begin
//        DW := GetCaptureWindow;
//        try
//          SDC := GetDC(DW);
//        except
//          SDC := 0;
//        end;
//        if (DW <> 0) and (SDC = 0) then
//        begin
//          DW := 0;
//          try
//            SDC := GetDC(DW);
//          except
//            SDC := 0;
//          end;
//          if SDC = 0 then
//            raise Exception.Create('Can not lock on to Desktop Canvas');
//  //      end;
//        try
//          if not BitBlt(Result.Canvas.Handle, 0, 0, Result.Width, Result.Height,
//            SDC, X, Y, SRCCOPY or RTC_CAPTUREBLT) then
//          begin
//            Result.Free;
//            raise Exception.Create('Error capturing screen contents');
//          end;
//        finally
//          ReleaseDC(DW, SDC);
//        end;
//    end;
//  finally
//    Result.Canvas.Unlock;
//  end;
//end;

procedure SetDefaultPalette(var Pal: TMaxLogPalette);
var
  i, r, g, b: integer;
  { havepal:boolean;
    Hdl:HWND;
    DC:HDC; }
  procedure SetPal(i, b, g, r: integer);
  begin
    with Pal.palPalEntry[i] do
    begin
      peRed := r;
      peGreen := g;
      peBlue := b;
    end;
  end;

begin
  if Pal.palNumEntries = 16 then
  begin
    { Ignore the disk image of the palette for 16 color bitmaps.
      Replace with the first and last 8 colors of the system palette }
    GetPaletteEntries(SystemPalette16, 0, 8, Pal.palPalEntry[0]);
    GetPaletteEntries(SystemPalette16, 8, 8,
      Pal.palPalEntry[Pal.palNumEntries - 8]);
  end
  else if Pal.palNumEntries = 256 then
  begin
    { Hdl := GetDesktopWindow;
      DC := GetDC(Hdl);
      try
      if (GetDeviceCaps (DC, RASTERCAPS) and RC_PALETTE = RC_PALETTE ) then
      havepal:=GetSystemPaletteEntries ( DC, 0, 256, Pal.palPalEntry )=256
      else
      havepal:=False;
      finally
      ReleaseDC(Hdl,DC);
      end; }

    // if not havepal then
    begin
      SetPal(0, $80, 0, 0);
      SetPal(1, 0, $80, 0);
      SetPal(2, 0, 0, $80);
      SetPal(3, $80, $80, 0);
      SetPal(4, 0, $80, $80);
      SetPal(5, $80, 0, $80);
      i := 6;
      for b := 0 to 4 do
        for r := 0 to 5 do
          for g := 0 to 6 do
          begin
            with Pal.palPalEntry[i] do
            begin
              peBlue := round(b * 255 / 4);
              peRed := round(r * 255 / 5);
              peGreen := round(g * 255 / 6);
            end;
            Inc(i);
          end;
      for r := 1 to 40 do
      begin
        with Pal.palPalEntry[i] do
        begin
          peRed := round(r * 255 / 41);
          peGreen := round(r * 255 / 41);
          peBlue := round(r * 255 / 41);
        end;
        Inc(i);
      end;
    end;
  end;
end;

(*
procedure ByteSwapColors(var Colors; Count: integer);
var // convert RGB to BGR and vice-versa.  TRGBQuad <-> TPaletteEntry
  SysInfo: TSystemInfo;
begin
  GetSystemInfo(SysInfo);
  asm
    MOV   EDX, Colors
    MOV   ECX, Count
    DEC   ECX
    JS    @@END
    LEA   EAX, SysInfo
    CMP   [EAX].TSystemInfo.wProcessorLevel, 3
    JE    @@386
  @@1:  MOV   EAX, [EDX+ECX*4]
    BSWAP EAX
    SHR   EAX,8
    MOV   [EDX+ECX*4],EAX
    DEC   ECX
    JNS   @@1
    JMP   @@END
  @@386:
    PUSH  EBX
  @@2:  XOR   EBX,EBX
    MOV   EAX, [EDX+ECX*4]
    MOV   BH, AL
    MOV   BL, AH
    SHR   EAX,16
    SHL   EBX,8
    MOV   BL, AL
    MOV   [EDX+ECX*4],EBX
    DEC   ECX
    JNS   @@2
    POP   EBX
  @@END:
  end;
end;
*)

function BitmapIsReverse(const Image: TBitmap): boolean;
begin
  With Image do
    if Height < 2 then
      Result := False
    else
      Result := Cardinal(ScanLine[0]) > Cardinal(ScanLine[1]);
end;

function BitmapDataPtr(const Image: TBitmap): pointer;
begin
  With Image do
  begin
    if Height < 2 then
      Result := ScanLine[0]
    else if Cardinal(ScanLine[0]) < Cardinal(ScanLine[1]) then
      Result := ScanLine[0]
    Else
      Result := ScanLine[Height - 1];
  End;
end;

function IsWinNT: boolean;
var
  OS: TOSVersionInfo;
begin
  ZeroMemory(@OS, SizeOf(OS));
  OS.dwOSVersionInfoSize := SizeOf(OS);
  GetVersionEx(OS);
  Result := OS.dwPlatformId = VER_PLATFORM_WIN32_NT;
end;

{ - TRtcScreenEncoder - }

constructor TRtcScreenEncoder.Create;
var
  fNeedRecreate, fRes: Boolean;
begin
  inherited;
  CS := TCriticalSection.Create;

  fFirstScreen := True;

  FMyScreenInfoChanged := False;
  FCaptureMask := SRCCOPY;

  FScreenData := TRtcValue.Create;
  FInitialScreenData := TRtcValue.Create;

  FTmpImage := nil;
  FTmpLastImage := nil;
  SetLength(FTmpStorage, 0);

  FFullScreen := True;
  FCaptureLeft := 0;
  FCaptureTop := 0;
  FCaptureWidth := 0;
  FCaptureHeight := 0;

  FReduce16bit := 0;
  FReduce32bit := 0;

  FScreenWidth := 0;
  FScreenHeight := 0;
  FScreenLeft := 0;
  FScreenTop := 0;
  FScreenBPP := 0;

  FBPPLimit := 4;
  FMaxTotalSize := 0;
  FMaxBlockCount := 1;
  FBPPWidth := 0;

  FOldImage := nil;
  FNewImage := nil;

  FUseCaptureMarks := False;

  SetLength(FImages, 0);
  SetLength(FMarked, 0);

//  FImageCatcher := TImageCatcher.Create;
  FDesktopDuplicator := TDesktopDuplicationWrapper.Create(FDDACreated);

//TRtcScreenEncoder.Create берет ScrCap.HaveScreen а ScrCap = nil. Белый экран вначале
//  while not ScrCap.HaveScreen do
//  begin
//    fRes := FDesktopDuplicator.GetFrame(fNeedRecreate);
//    while fNeedRecreate do
//    begin
//      FDesktopDuplicator.Free;
//      FDesktopDuplicator := TDesktopDuplicationWrapper.Create;
//      fRes := FDesktopDuplicator.GetFrame(fNeedRecreate);
//
//      Application.ProcessMessages;
//    end;
//    if fRes then
//    begin
//      if FDesktopDuplicator.DrawFrame(FNewImage) then
//        ScrCap.HaveScreen := True;
//    end
//    else
//    begin
//      //Memo1.Lines.Add('no frame ' + IntToHex(FDuplication.Error));
//    end;
//
////    Sleep(1);
//    Application.ProcessMessages;
//  end;
end;

destructor TRtcScreenEncoder.Destroy;
begin
  ReleaseStorage;

  FScreenData.Free;
  FInitialScreenData.Free;

  CS.Free;

//  FImageCatcher.Free;

  FDesktopDuplicator.Free;

  inherited;
end;

procedure TRtcScreenEncoder.Setup(BPPLimit, MaxBlockCount,
  MaxTotalSize: integer);
begin
  FBPPLimit := BPPLimit;
  FMaxTotalSize := MaxTotalSize;
  FMaxBlockCount := MaxBlockCount;

  FCaptureWidth := 0;
  FCaptureHeight := 0;
  FCaptureTop := 0;
  FCaptureLeft := 0;

  FScreenWidth := 0;
  FScreenHeight := 0;
  FScreenLeft := 0;
  FScreenTop := 0;
  FScreenBPP := 0;
end;

function TRtcScreenEncoder.Capture(SleepTime: integer = 0;
  Initial: boolean = False): boolean;
var
  Res: TRtcRecord;
  Data: TRtcArray;
  s: RtcByteArray;
  i, j, k: integer;
  rev: boolean;
  TotalSize: integer;
begin
  Result := False;

  FScreenData.isNull := True;
  FInitialScreenData.isNull := True;

  if Initial then
    CaptureScreenInfo
  else if not ScreenChanged then
    FScreenInfoChanged := False
  else
    CaptureScreenInfo;

  j := 0;
  Data := nil;
  try
    SetBlockIndex(0);
    rev := BitmapIsReverse(FNewImage);

    TotalSize := 0;

    if FScreenGrabBroken then
    begin
      FScreenGrabBroken := False;
      i := FScreenGrabFrom;
    end
    else
      i := -1;

    k := BlockCount;

    while k > 0 do
    begin
      Inc(i);
      if i >= BlockCount then
        i := 0;
      DEC(k);

      if FScreenInfoChanged or not FUseCaptureMarks or FMarked[i] then
      begin
        SetBlockIndex(i);
        if not CaptureBlock then
          Break;

        if FScreenInfoChanged then
          s := CompressBlock_Normal
        else
          s := CompressBlock_Delta;

        if length(s) > 0 then
        begin
          if not assigned(Data) then
            Data := TRtcArray.Create;
          with Data.newRecord(j) do
          begin
            if rev then
            begin
              if i = BlockCount - 1 then
                asInteger['at'] := 0
              else
                asInteger['at'] := FAllBlockSize - (i + 1) * FBlockHeight *
                  FBPPWidth;
            end
            else
              asInteger['at'] := i * FBlockHeight * FBPPWidth;

            asString['img'] := RtcBytesToString(s);
          end;
          Inc(j);
          TotalSize := TotalSize + length(s);
          SetLength(s, 0);
          StoreBlock;
          if FMaxTotalSize > 0 then
          begin
            if not FScreenInfoChanged and (k > 0) then
              if TotalSize > FMaxTotalSize then
              begin
                FScreenGrabBroken := True;
                FScreenGrabFrom := i;
                Break;
              end;
          end
          else
          begin
            FScreenGrabBroken := True;
            FScreenGrabFrom := i;
            Break;
          end;
        end;
        Sleep(SleepTime);
      end;
    end;
  finally
    if assigned(Data) then
    begin
      FScreenData.newRecord;
      Res := FScreenData.asRecord;
      if FScreenInfoChanged then
      begin
        Result := True;
        if FScreenPalette <> '' then
          Res.asString['pal'] := FScreenPalette;
        FNewScreenPalette := False;
        with Res.newRecord('res') do
        begin
          asInteger['Width'] := FCaptureWidth;
          asInteger['Height'] := FCaptureHeight;
          asInteger['Bits'] := FScreenBPP;
          asInteger['Bytes'] := FBytesPerPixel;
        end;
      end
      else if FNewScreenPalette then
      begin
        if FScreenPalette <> '' then
          Res.asString['pal'] := FScreenPalette;
        FNewScreenPalette := False;
      end;
      Res.asObject['scr'] := Data;
    end;
  end;
end;

function TRtcScreenEncoder.GetScreenData: TRtcValue;
begin
  Result := FScreenData;
end;

function TRtcScreenEncoder.GetInitialScreenData: TRtcValue;
var
  Res: TRtcRecord;
  Data: TRtcArray;
  s: RtcByteArray;
  i, j: integer;
  rev: boolean;
begin
  if FInitialScreenData.isNull then
  begin
    j := 0;
    Data := nil;
    try
      SetBlockIndex(0);
      rev := BitmapIsReverse(FOldImage);
      for i := 0 to BlockCount - 1 do
      begin
        SetBlockIndex(i);

        s := CompressBlock_Initial;

        if length(s) > 0 then
        begin
          if not assigned(Data) then
            Data := TRtcArray.Create;
          with Data.newRecord(j) do
          begin
            if rev then
            begin
              if i = BlockCount - 1 then
                asInteger['at'] := 0
              else
                asInteger['at'] := FAllBlockSize - (i + 1) * FBlockHeight *
                  FBPPWidth;
            end
            else
              asInteger['at'] := i * FBlockHeight * FBPPWidth;

            asString['img'] := RtcBytesToString(s);
          end;
          Inc(j);
          SetLength(s, 0);
        end;
      end;
    finally
      if assigned(Data) then
      begin
        FInitialScreenData.newRecord;

        Res := FInitialScreenData.asRecord;
        with Res.newRecord('res') do
        begin
          asInteger['Width'] := FCaptureWidth;
          asInteger['Height'] := FCaptureHeight;
          asInteger['Bits'] := FScreenBPP;
          asInteger['Bytes'] := FBytesPerPixel;
        end;
        if FScreenPalette <> '' then
          Res.asString['pal'] := FScreenPalette;
        Res.asObject['scr'] := Data;
      end;
    end;
  end;
  Result := FInitialScreenData;
end;

procedure TRtcScreenEncoder.PrepareStorage;
var
  i: integer;
begin
  SwitchToActiveDesktop;

  ReleaseStorage;

  CS.Acquire;
  try
    FScreenInfoChanged := True;
    FScreenGrabBroken := False;

    SetLength(FImages, FBlockCount);
    for i := 0 to FBlockCount - 1 do
      FImages[i] := CreateBitmap(i);

    SetLength(FMarked, FBlockCount);
    for i := 0 to FBlockCount - 1 do
      FMarked[i] := True;

    if FBlockCount > 1 then
      FTmpImage := CreateBitmap(0);

    FTmpLastImage := CreateBitmap(FBlockCount - 1);

    SetLength(FTmpStorage, FBlockSize * 2);
  finally
    CS.Release;
  end;
end;

procedure TRtcScreenEncoder.ReleaseStorage;
var
  i: integer;
begin
  CS.Acquire;
  try
    SetLength(FTmpStorage, 0);

    if assigned(FTmpImage) then
    begin
      FTmpImage.Free;
      FTmpImage := nil;
    end;
    if assigned(FTmpLastImage) then
    begin
      FTmpLastImage.Free;
      FTmpLastImage := nil;
    end;
    if assigned(FImages) then
    begin
      for i := 0 to length(FImages) - 1 do
      begin
        FImages[i].Free;
        FImages[i] := nil;
      end;
      SetLength(FImages, 0);
    end;
    if assigned(FMarked) then
      SetLength(FMarked, 0);
  finally
    CS.Release;
  end;
end;

function TRtcScreenEncoder.ScreenChanged: boolean;
Var
  _BitsPerPixel, _ScreenWidth, _ScreenHeight, _ScreenLeft, _ScreenTop: integer;

  r: TRect;
  DW: HWND;
  SDC: HDC;
begin
 SwitchToActiveDesktop;

  if IsService then
  begin
    _BitsPerPixel := FHelper_BitsPerPixel;
    _ScreenLeft := 0;
    _ScreenTop := 0;
    _ScreenWidth := FHelper_Width;
    _ScreenHeight := FHelper_Height;
  end
  else
  begin
    DW := GetCaptureWindow;
    try
      SDC := GetDC(DW);
    except
      SDC := 0;
    end;
    if (DW <> 0) and (SDC = 0) then
    begin
      DW := 0;
      try
        SDC := GetDC(DW);
      except
        SDC := 0;
      end;
      if SDC = 0 then
      begin
        Result := False;
        Exit;
      end;
    end;

  {$IFDEF MULTIMON}
    if MultiMonitor then
      r := Screen.DesktopRect
    else
  {$ENDIF}
      GetWindowRect(DW, r);

    try
      _BitsPerPixel := GetDeviceCaps(SDC, BITSPIXEL);
    finally
      ReleaseDC(DW, SDC);
    end;
    _ScreenLeft := r.Left;
    _ScreenTop := r.Top;
    _ScreenWidth := r.Right - r.Left;
    _ScreenHeight := r.Bottom - r.Top;
  end;

  Result := (FScreenBPP <> _BitsPerPixel) or (FScreenWidth <> _ScreenWidth) or
    (FScreenHeight <> _ScreenHeight) or (FScreenLeft <> _ScreenLeft) or
    (FScreenTop <> _ScreenTop);
end;

procedure TRtcScreenEncoder.CaptureScreenInfo;
Var
  BitsPerPixel: integer;
  MaxHeight: integer;
  r: TRect;
  DW: HWND;
  SDC: HDC;

begin
 SwitchToActiveDesktop; //Если под SYSTEM

  CS.Acquire;
  try
    if IsService then
    begin
      BitsPerPixel := FHelper_BitsPerPixel;
      FScreenBPP := FHelper_BitsPerPixel;
      FScreenWidth := FHelper_Width;
      FScreenHeight := FHelper_Height;
      FScreenLeft := 0;
      FScreenTop := 0;
    end
    else
    begin
      DW := GetCaptureWindow;
      try
        SDC := GetDC(DW);
      except
        SDC := 0;
      end;
      if (DW <> 0) and (SDC = 0) then
      begin
        DW := 0;
        try
          SDC := GetDC(DW);
        except
          SDC := 0;
        end;
        if SDC = 0 then
          Exit;
      end;

      try
        BitsPerPixel := GetDeviceCaps(SDC, BITSPIXEL);
      finally
        ReleaseDC(DW, SDC);
      end;

  {$IFDEF MULTIMON}
      if MultiMonitor then
        r := Screen.DesktopRect
      else
  {$ENDIF}
        GetWindowRect(DW, r);

      FScreenBPP := BitsPerPixel;
      FScreenWidth := r.Right - r.Left;
      FScreenHeight := r.Bottom - r.Top;
      FScreenLeft := r.Left;
      FScreenTop := r.Top;
    end;

    case BitsPerPixel of
      1 .. 4:
        FBytesPerPixel := 0;
      5 .. 8:
        FBytesPerPixel := 1;
      9 .. 16:
        FBytesPerPixel := 2;
      17 .. 24:
        FBytesPerPixel := 3;
      32:
        FBytesPerPixel := 4;
    Else
      FBytesPerPixel := 3;
    End;

    if FBytesPerPixel > FBPPLimit then
      FBytesPerPixel := FBPPLimit;

    if FBytesPerPixel = 3 then // 3 BPP images not supported
      FBytesPerPixel := 2;

    if FFullScreen then
    begin
      FCaptureLeft := FScreenLeft;
      FCaptureTop := FScreenTop;
      FCaptureWidth := FScreenWidth;
      FCaptureHeight := FScreenHeight;
    end
    else
    begin
      FCaptureLeft := FFixedRegion.Left;
      FCaptureTop := FFixedRegion.Top;
      if FCaptureLeft < FScreenLeft then
        FCaptureLeft := FScreenLeft;
      if FCaptureTop < FScreenTop then
        FCaptureTop := FScreenTop;

      FCaptureWidth := FFixedRegion.Right - FCaptureLeft;
      FCaptureHeight := FFixedRegion.Bottom - FCaptureTop;
      if FCaptureWidth > FScreenWidth - FCaptureLeft then
        FCaptureWidth := FScreenWidth - FCaptureLeft;
      if FCaptureHeight > FScreenHeight - FCaptureTop then
        FCaptureHeight := FScreenHeight - FCaptureTop;
    end;

    FBlockWidth := FCaptureWidth;
    FBlockHeight := FCaptureHeight;

    if FBytesPerPixel = 0 then
      FBPPWidth := FBlockWidth div 2
    else
      FBPPWidth := FBlockWidth * FBytesPerPixel;

    if FMaxBlockCount > 1 then
    begin
      MaxHeight := FBlockHeight div FMaxBlockCount;
      if MaxHeight < 2 then
        MaxHeight := 2;

      if FBlockHeight > MaxHeight then
        FBlockHeight := MaxHeight;
    end
    else if FMaxTotalSize > 0 then
    begin
      MaxHeight := FMaxTotalSize div FBPPWidth;
      if MaxHeight < 2 then
        MaxHeight := 2;

      if FBlockHeight > MaxHeight then
        FBlockHeight := MaxHeight;
    end;

    FBlockSize := FBlockHeight * FBPPWidth;
    FBlockCount := FCaptureHeight div FBlockHeight;
    FLastBlockHeight := FCaptureHeight - FBlockHeight * FBlockCount;

    if FLastBlockHeight = 0 then
      FLastBlockHeight := FBlockHeight
    else
      Inc(FBlockCount);

    FLastBlockSize := FLastBlockHeight * FBPPWidth;

    FAllBlockSize := FLastBlockSize + (FBlockCount - 1) * FBlockSize;

    FScreenPalette := '';
    FNewScreenPalette := False;
  finally
    CS.Release;
  end;

  PrepareStorage;
end;

function TRtcScreenEncoder.CreateBitmap(index: integer): TBitmap;
var
  Pal: TMaxLogPalette;
  tmp: RtcByteArray;
begin
  Result := TBitmap.Create;
  With Result do
  Begin
    case FBytesPerPixel of
      0:
        PixelFormat := pf4bit;
      1:
        PixelFormat := pf8bit;
      2:
        PixelFormat := pf16bit;
      3:
        PixelFormat := pf24bit;
      4:
        PixelFormat := pf32bit;
    End;
    Width := FBlockWidth;

    if index < FBlockCount - 1 then
      Height := FBlockHeight
    else
      Height := FLastBlockHeight;

    if FBytesPerPixel <= 1 then
    begin
      FillChar(Pal, SizeOf(Pal), #0);
      Pal.palVersion := $300;

      if FBytesPerPixel = 0 then
        Pal.palNumEntries := 16
      else
        Pal.palNumEntries := 256;

      SetDefaultPalette(Pal);

      if FScreenPalette = '' then
      begin
        FNewScreenPalette := True;
        SetLength(tmp, SizeOf(Pal));
        Move(Pal, tmp[0], length(tmp));
        FScreenPalette := RtcBytesToString(tmp);
      end;

      Palette := CreatePalette(TLogPalette(Addr(Pal)^));
    end;
  End;
end;

procedure TRtcScreenEncoder.SetBlockIndex(index: integer);
begin
  FImgIndex := index;

  FOldImage := FImages[index];
  if index < FBlockCount - 1 then
  begin
    FNewImage := FTmpImage;
    FNewBlockSize := FBlockSize;
  end
  else
  begin
    FNewImage := FTmpLastImage;
    FNewBlockSize := FLastBlockSize;
  end;
end;

procedure TRtcScreenEncoder.StoreBlock;
begin
  if FImgIndex < FBlockCount - 1 then
    FTmpImage := FOldImage
  else
    FTmpLastImage := FOldImage;
  FImages[FImgIndex] := FNewImage;
end;

{procedure TRtcScreenEncoder.GetScreenFromHelperByMMF;
var
  h, hMap: THandle;
  pMap: Pointer;
  hScrDC, hDestDC: HDC;
  hBmp: HBitmap;
  BitmapSize: Int64;
  bitmap_info: BITMAPINFO;
  sWidth, sHeight: Integer;
  SessionID: DWORD;
  PipeClient: TPipeClient;
begin
  if IsConsoleClient then
    SessionID := WTSGetActiveConsoleSessionId
  else
    SessionID := CurrentSessionID;

  try
    PipeClient := TPipeClient.Create(nil);
    PipeClient.ServerName := 'RMX_SCREEN_SESSION_' + IntToStr(SessionID);
    PipeClient.Connect(1000, True);

//    hMap := OpenFileMapping(FILE_MAP_READ, False, PWideChar(WideString('Global\RMX_SCREEN_SESSION_' + IntToStr(SessionID))));
    hMap := OpenFileMapping(FILE_MAP_READ, False, PWideChar(WideString('Session\' + IntToStr(SessionID) + '\RMX_SCREEN')));
    if hMap = 0 then
      Exit;

    pMap := MapViewOfFile(hMap,//дескриптор "проецируемого" объекта
                            FILE_MAP_READ,// разрешение чтения/записи
                            0,0,
                            SizeOf(pSize));//размер буфера
    if pMap = nil then
    begin
      CloseHandle(hMap);
      Exit;
    end;

    BitmapSize := 0;
    CopyMemory(@BitmapSize, pMap, SizeOf(BitmapSize));
    UnmapViewOfFile(pMap);

    pMap := MapViewOfFile(hMap,//дескриптор "проецируемого" объекта
                            FILE_MAP_READ,// разрешение чтения/записи
                            0, 0,
                            BitmapSize + SizeOf(BitmapSize));//размер буфера
    if pMap = nil then
    begin
      CloseHandle(hMap);
      Exit;
    end;

    sWidth := GetSystemMetrics(SM_CXSCREEN);
    sHeight := GetSystemMetrics(SM_CYSCREEN);

    h := GetDesktopWindow;
    hScrDC := GetDC(h);

    with bitmap_info.bmiHeader do
    begin
      biSize := 40;
      biWidth := sWidth;
      //Use negative height to scan top-down.
      biHeight := -sHeight;
      biPlanes := 1;
      biBitCount := GetDeviceCaps(hScrDC, BITSPIXEL);
      biCompression := BI_RGB;
    end;

    hDestDC := CreateCompatibleDC(FNewImage.Canvas.Handle);
    hBmp := CreateCompatibleBitmap(FNewImage.Canvas.Handle, sWidth, sHeight);
    SelectObject(hDestDC, hBmp);

    SetDIBits(hDestDC, hBmp, 0, sHeight, (PByte(pMap) + SizeOf(BitmapSize)), bitmap_info, DIB_RGB_COLORS);

    BitBlt(FNewImage.Canvas.Handle, 0, 0, sWidth, sHeight, hDestDC, 0, 0, SRCCOPY);

//    FNewImage.SaveToFile('C:\Screenshots\S_' + FormatDateTime('mm-dd-yyyy-hhnnss', Now()) + '.bmp');

    DeleteObject(hBmp);
    DeleteObject(hDestDC);
    ReleaseDC(h, hScrDC);
  finally

  end;
end;}

{function TRtcScreenEncoder.GetScreenFromHelperByMMF(OnlyGetScreenParams: Boolean = False): Boolean;
var
  h, hMap: THandle;
  pMap: Pointer;
  hScrDC, hDestDC, hMemDC: HDC;
  hBmp: HBitmap;
  BitmapSize: Cardinal;
  bitmap_info: BITMAPINFO;
  EventWriteBegin, EventWriteEnd, EventReadBegin, EventReadEnd: THandle;
  SessionID: DWORD;
  HeaderSize, CurOffset: Integer;
  NameSuffix: String;
  pBits, ipBase: Pointer;
  hOld: HGDIOBJ;
  hProc: THandle;
  PID: DWORD;
  numberRead : SIZE_T;
begin
  CS.Acquire;
  try
    Result := False;

    hBmp := 0;
    hDestDC := 0;

  //  if IsConsoleClient then
    if ServiceStarted then
    begin
      SessionID := GetActiveConsoleSessionId;
      NameSuffix := '_C';
    end
    else
    begin
      SessionID := CurrentSessionID;
      NameSuffix := '';
    end;

    EventWriteBegin := OpenEvent(EVENT_ALL_ACCESS, False, PWideChar(WideString('Global\RMX_SCREEN_WRITE_BEGIN_SESSION_' + IntToStr(SessionID) + NameSuffix)));
    if EventWriteBegin = 0 then
      Exit;
    EventWriteEnd := OpenEvent(EVENT_ALL_ACCESS, False, PWideChar(WideString('Global\RMX_SCREEN_WRITE_END_SESSION_' + IntToStr(SessionID) + NameSuffix)));
    if EventWriteEnd = 0 then
      Exit;
    EventReadBegin := OpenEvent(EVENT_ALL_ACCESS, False, PWideChar(WideString('Global\RMX_SCREEN_READ_BEGIN_SESSION_' + IntToStr(SessionID) + NameSuffix)));
    if EventReadBegin = 0 then
      Exit;
    EventReadEnd := OpenEvent(EVENT_ALL_ACCESS, False, PWideChar(WideString('Global\RMX_SCREEN_READ_END_SESSION_' + IntToStr(SessionID) + NameSuffix)));
    if EventReadEnd = 0 then
      Exit;

    try
  //    MutexRead := OpenMutex(MUTEX_ALL_ACCESS, False, PWideChar(WideString('Global\RMX_SCREEN_READ_SESSION_' + IntToStr(SessionID) + NameSuffix)));
  //    if MutexRead = 0 then
  //    if WaitForSingleObject(EventRead, 0) <> WAIT_OBJECT_0 then //Если идет чтение скрина в другом процессе, запись скрина не начинаем
  //    begin

        SetEvent(EventReadEnd);
        SetEvent(EventWriteBegin); //Если чтение не идет, то начинаем запись скрина

        ResetEvent(EventReadBegin);

        WaitForSingleObject(EventWriteEnd, 10000); //Добавить таймаут, ждем окончания записи скрина
        ResetEvent(EventWriteEnd);

  //    if EventRead > 0 then
  //    begin
  //      SetEvent(EventRead);
  //    end;

  //      MutexRead := DoCreateMutex(PWideChar(WideString('Global\RMX_SCREEN_READ_SESSION_' + IntToStr(SessionID))));
  //    end
  //    else
  //      CloseHandle(MutexRead);

      try
        hMap := OpenFileMapping(FILE_MAP_READ, False, PWideChar(WideString('Session\' + IntToStr(SessionID) + '\RMX_SCREEN' + NameSuffix)));
        if hMap = 0 then
          Exit;
        HeaderSize := sizeof(BitmapSize) + sizeof(Result) + sizeof(FHelper_Width) + sizeof(FHelper_Height) + sizeof(FHelper_BitsPerPixel) + sizeof(PID) + sizeof(ipBase) + sizeof(FHelper_mouseFlags) + sizeof(FHelper_mouseCursor);
        pMap := MapViewOfFile(hMap, //дескриптор "проецируемого" объекта
                                FILE_MAP_READ,  // разрешение чтения/записи
                                0,0,
                                HeaderSize);  //размер буфера
        if pMap = nil then
          Exit;

        BitmapSize := 0;
        FHelper_Width := 0;
        FHelper_Height := 0;
        FHelper_BitsPerPixel := 0;
        CurOffset := 0;
        CopyMemory(@BitmapSize, pMap, SizeOf(BitmapSize));
        CurOffset := CurOffset + SizeOf(BitmapSize);
        CopyMemory(@Result, PByte(pMap) + CurOffset, sizeof(Result));
        CurOffset := CurOffset + SizeOf(Result);
        CopyMemory(@FHelper_Width, PByte(pMap) + CurOffset, sizeof(FHelper_Width));
        CurOffset := CurOffset + SizeOf(FHelper_Width);
        CopyMemory(@FHelper_Height, PByte(pMap) + CurOffset, sizeof(FHelper_Height));
        CurOffset := CurOffset + SizeOf(FHelper_Height);
        CopyMemory(@FHelper_BitsPerPixel, PByte(pMap) + CurOffset, sizeof(FHelper_BitsPerPixel));
        CurOffset := CurOffset + SizeOf(FHelper_BitsPerPixel);
        CopyMemory(@PID, PByte(pMap) + CurOffset, sizeof(PID));
        CurOffset := CurOffset + SizeOf(PID);
        CopyMemory(@ipBase, PByte(pMap) + CurOffset, sizeof(ipBase));
        CurOffset := CurOffset + SizeOf(ipBase);
        CopyMemory(@FHelper_mouseFlags, PByte(pMap) + CurOffset, sizeof(FHelper_mouseFlags));
        CurOffset := CurOffset + SizeOf(FHelper_mouseFlags);
        CopyMemory(@FHelper_mouseCursor, PByte(pMap) + CurOffset, sizeof(FHelper_mouseCursor));
        CurOffset := CurOffset + SizeOf(FHelper_mouseCursor);
        CopyMemory(@FHelper_mouseX, PByte(pMap) + CurOffset, sizeof(FHelper_mouseX));
        CurOffset := CurOffset + SizeOf(FHelper_mouseX);
        CopyMemory(@FHelper_mouseY, PByte(pMap) + CurOffset, sizeof(FHelper_mouseY));
        CurOffset := CurOffset + SizeOf(FHelper_mouseY);
      finally
        if pMap <> nil then
          UnmapViewOfFile(pMap);
        if hMap <> 0 then
          CloseHandle(hMap);
      end;

      if OnlyGetScreenParams then
        Exit;

  //    sWidth := GetSystemMetrics(SM_CXSCREEN);
  //    sHeight := GetSystemMetrics(SM_CYSCREEN);

      with bitmap_info.bmiHeader do
      begin
        biSize := sizeof(BITMAPINFOHEADER);
        biWidth := FHelper_Width;
        //Use negative height to scan top-down.
        biHeight := -FHelper_Height;
        biPlanes := 1;
        biBitCount := FHelper_BitsPerPixel; //GetDeviceCaps(hScrDC, BITSPIXEL);
        biCompression := BI_RGB;
      end;
      pBits := nil;
      hBmp := CreateDIBSection(FNewImage.Canvas.Handle, bitmap_info, DIB_RGB_COLORS, pBits, 0, 0);
      hMemDC := CreateCompatibleDC(FNewImage.Canvas.Handle);
      hOld := SelectObject(hMemDC, hBmp);

//      hDestDC := CreateCompatibleDC(FNewImage.Canvas.Handle);
//      hBmp := CreateCompatibleBitmap(FNewImage.Canvas.Handle, FHelper_Width, FHelper_Height);
//      SelectObject(hDestDC, hBmp);

//      pMap := MapViewOfFile(hMap, //дескриптор "проецируемого" объекта
//                              FILE_MAP_READ,  //разрешение чтения/записи
//                              0, 0,
//                              BitmapSize + HeaderSize);  //размер буфера
//      if pMap = nil then
//        Exit;
//
//      CopyMemory(pBits, (PByte(pMap) + HeaderSize), BitmapSize);
//      SetDIBits(hDestDC, hBmp, 0, FHelper_Height, (PByte(pMap) + HeaderSize), bitmap_info, DIB_RGB_COLORS);

  //    Winapi.Windows.FillRect(Form2.Image1.Canvas.Handle, Rect(0, 0, sWidth, sHeight), Form2.Image1.Canvas.Brush.Handle);
//      CS.Acquire;
//      try

//      hProc := OpenProcess(PROCESS_VM_READ, False, PID); // подключаемся к процессу зная его ID
//      if hProc <> 0 then // условие проверки подключения к процессу
//      try
//        ReadProcessMemory(hProc, ipBase, pBits, BitmapSize, numberRead); // чтение из памяти строки
//      finally
//        CloseHandle(hProc); // отсоединяемся от процесса
//      end;

      BitBlt(FNewImage.Canvas.Handle, 0, 0, FHelper_Width, FHelper_Height, hMemDC, 0, 0, SRCCOPY);

//      SelectObject(hMemDC, hOld);
//      DeleteDC(hMemDC);
//      finally
//        CS.Release;
//      end;
  //    Form2.Image1.Repaint;
//     FNewImage.SaveToFile('C:\Screenshots\' + FormatDateTime('mm-dd-yyyy-hhnnss', Now()) + '.bmp');

      SetEvent(EventReadEnd);
    finally
      if hBmp <> 0 then
        DeleteObject(hBmp);
//      if hDestDC <> 0 then
//      begin
//        DeleteObject(hDestDC);
//        ReleaseDC(h, hScrDC);
//      end;
      SelectObject(hMemDC, hOld);
      if hMemDC <> 0 then
      begin
        DeleteDC(hMemDC);
      end;
//      if hScrDC <> 0 then
//        ReleaseDC(h, hScrDC);

//      if pMap <> nil then
//        UnmapViewOfFile(pMap);
//      if hMap <> 0 then
//        CloseHandle(hMap);
  //    if MutexRead <> 0 then
  //    begin
  //      ReleaseMutex(MutexRead);
  //      CloseHandle(MutexRead);
  //    end;
  //    if EventRead <> 0 then
  //    begin
  //      ResetEvent(EventRead);
  //      CloseHandle(EventRead);
  //      EventRead := 0;
  //    end;
      if EventWriteEnd <> 0 then
      begin
        CloseHandle(EventWriteEnd);
        EventWriteEnd := 0;
      end;
      if EventWriteBegin <> 0 then
      begin
        CloseHandle(EventWriteBegin);
        EventWriteBegin := 0;
      end;
      if EventReadBegin <> 0 then
      begin
        CloseHandle(EventReadBegin);
        EventReadBegin := 0;
      end;
      if EventReadEnd <> 0 then
      begin
        CloseHandle(EventReadEnd);
        EventReadEnd := 0;
      end;
    end;
  finally
    CS.Release;
  end;
end;}

function IsWindows8orLater: Boolean;
begin
  Result := False;

  if Win32MajorVersion > 6 then
    Result := True;
  if Win32MajorVersion = 6 then
    if Win32MinorVersion >= 2 then
      Result := True;
end;

function TRtcScreenEncoder.GetScreenFromHelperByMMF(OnlyGetScreenParams: Boolean = False; fFirstScreen: Boolean = False): Boolean;
var
  h, hMap: THandle;
  pMap: Pointer;
  hScrDC, hDestDC, hMemDC: HDC;
  hBmp: HBitmap;
  BitmapSize: Cardinal;
  bitmap_info: BITMAPINFO;
  EventWriteBegin, EventWriteEnd, EventReadBegin, EventReadEnd: THandle;
  SessionID: DWORD;
  HeaderSize, CurOffset: Integer;
  NameSuffix: String;
  pBits, ipBase: Pointer;
  hOld: HGDIOBJ;
  hProc: THandle;
  numberRead : SIZE_T;
  WaitTimeout: DWORD;
  SaveBitMap: TBitmap;
  i, j: LongInt;
  fScreenGrabbed: Boolean;
  FLastChangedX1, FLastChangedY1, FLastChangedX2, FLastChangedY2: Integer;
begin
  if not IsWindows8orLater then
    Exit;

  WaitTimeout := 1000;

  CS.Acquire;
  try
    Result := False;

    hBmp := 0;
    hDestDC := 0;

  //  if IsConsoleClient then
    if IsService then
    begin
      SessionID := ActiveConsoleSessionID;
      NameSuffix := '_C';
    end
    else
    begin
      SessionID := CurrentSessionID;
      NameSuffix := '';
    end;

//    NameSuffix := '_C';

    EventWriteBegin := OpenEvent(EVENT_ALL_ACCESS, False, PWideChar(WideString('Global\RMX_SCREEN_WRITE_BEGIN_SESSION_' + IntToStr(SessionID) + NameSuffix)));
    if EventWriteBegin = 0 then
      Exit;
    EventWriteEnd := OpenEvent(EVENT_ALL_ACCESS, False, PWideChar(WideString('Global\RMX_SCREEN_WRITE_END_SESSION_' + IntToStr(SessionID) + NameSuffix)));
    if EventWriteEnd = 0 then
      Exit;
    EventReadBegin := OpenEvent(EVENT_ALL_ACCESS, False, PWideChar(WideString('Global\RMX_SCREEN_READ_BEGIN_SESSION_' + IntToStr(SessionID) + NameSuffix)));
    if EventReadBegin = 0 then
      Exit;
    EventReadEnd := OpenEvent(EVENT_ALL_ACCESS, False, PWideChar(WideString('Global\RMX_SCREEN_READ_END_SESSION_' + IntToStr(SessionID) + NameSuffix)));
    if EventReadEnd = 0 then
      Exit;

    try
  //    MutexRead := OpenMutex(MUTEX_ALL_ACCESS, False, PWideChar(WideString('Global\RMX_SCREEN_READ_SESSION_' + IntToStr(SessionID) + NameSuffix)));
  //    if MutexRead = 0 then
  //    if WaitForSingleObject(EventRead, 0) <> WAIT_OBJECT_0 then //Если идет чтение скрина в другом процессе, запись скрина не начинаем
  //    begin

        ResetEvent(EventWriteEnd);
        ResetEvent(EventReadBegin);
        ResetEvent(EventReadEnd);

        SetEvent(EventWriteBegin); //Если чтение не идет, то начинаем запись скрина

//        ResetEvent(EventReadBegin);
//time := GetTickCount;
        WaitForSingleObject(EventWriteEnd, WaitTimeout); //Добавить таймаут, ждем окончания записи скрина
        ResetEvent(EventWriteEnd);
//time := GetTickCount - time;
//time := time;
  //    if EventRead > 0 then
  //    begin
  //      SetEvent(EventRead);
  //    end;

  //      MutexRead := DoCreateMutex(PWideChar(WideString('Global\RMX_SCREEN_READ_SESSION_' + IntToStr(SessionID))));
  //    end
  //    else
  //      CloseHandle(MutexRead);

      try
        hMap := OpenFileMapping(FILE_MAP_READ or FILE_MAP_WRITE, False, PWideChar(WideString('Session\' + IntToStr(SessionID) + '\RMX_SCREEN' + NameSuffix)));
        if hMap = 0 then
          Exit;
        HeaderSize := sizeof(BitmapSize) + sizeof(fScreenGrabbed) + sizeof(FHelper_Width) + sizeof(FHelper_Height) + sizeof(FHelper_BitsPerPixel) + sizeof(CurrentProcessId) + sizeof(ipBase) + sizeof(FHelper_mouseFlags) + sizeof(FHelper_mouseCursor);
        pMap := MapViewOfFile(hMap, //дескриптор "проецируемого" объекта
                                FILE_MAP_READ or FILE_MAP_WRITE,  // разрешение чтения/записи
                                0,0,
                                HeaderSize);  //размер буфера
        if pMap = nil then
          Exit;

        BitmapSize := 0;
        FHelper_Width := 0;
        FHelper_Height := 0;
        FHelper_BitsPerPixel := 0;
        CurOffset := 0;
        CopyMemory(@BitmapSize, pMap, SizeOf(BitmapSize));
        CurOffset := CurOffset + SizeOf(BitmapSize);
        CopyMemory(@fScreenGrabbed, PByte(pMap) + CurOffset, sizeof(fScreenGrabbed));
        CurOffset := CurOffset + SizeOf(fScreenGrabbed);
        CopyMemory(@FHelper_Width, PByte(pMap) + CurOffset, sizeof(FHelper_Width));
        CurOffset := CurOffset + SizeOf(FHelper_Width);
        CopyMemory(@FHelper_Height, PByte(pMap) + CurOffset, sizeof(FHelper_Height));
        CurOffset := CurOffset + SizeOf(FHelper_Height);
        CopyMemory(@FHelper_BitsPerPixel, PByte(pMap) + CurOffset, sizeof(FHelper_BitsPerPixel));
        CurOffset := CurOffset + SizeOf(FHelper_BitsPerPixel);
//        CopyMemory(@PID, PByte(pMap) + CurOffset, sizeof(PID));
        CurOffset := CurOffset + SizeOf(CurrentProcessId);
//        CopyMemory(@ipBase, PByte(pMap) + CurOffset, sizeof(ipBase));
        CurOffset := CurOffset + SizeOf(ipBase);
        CopyMemory(@FHelper_mouseFlags, PByte(pMap) + CurOffset, sizeof(FHelper_mouseFlags));
        CurOffset := CurOffset + SizeOf(FHelper_mouseFlags);
        CopyMemory(@FHelper_mouseCursor, PByte(pMap) + CurOffset, sizeof(FHelper_mouseCursor));
        CurOffset := CurOffset + SizeOf(FHelper_mouseCursor);
        CopyMemory(@FHelper_mouseX, PByte(pMap) + CurOffset, sizeof(FHelper_mouseX));
        CurOffset := CurOffset + SizeOf(FHelper_mouseX);
        CopyMemory(@FHelper_mouseY, PByte(pMap) + CurOffset, sizeof(FHelper_mouseY));
        CurOffset := CurOffset + SizeOf(FHelper_mouseY);
        CopyMemory(@FLastChangedX1, PByte(pMap) + CurOffset, sizeof(FLastChangedX1));
        CurOffset := CurOffset + SizeOf(FLastChangedX1);
        CopyMemory(@FLastChangedY1, PByte(pMap) + CurOffset, sizeof(FLastChangedY1));
        CurOffset := CurOffset + SizeOf(FLastChangedY1);
        CopyMemory(@FLastChangedX2, PByte(pMap) + CurOffset, sizeof(FLastChangedX2));
        CurOffset := CurOffset + SizeOf(FLastChangedX2);
        CopyMemory(@FLastChangedY2, PByte(pMap) + CurOffset, sizeof(FLastChangedY2));
        CurOffset := CurOffset + SizeOf(FLastChangedY2);

        if OnlyGetScreenParams then
          Exit;

    //    sWidth := GetSystemMetrics(SM_CXSCREEN);
    //    sHeight := GetSystemMetrics(SM_CYSCREEN);

        with bitmap_info.bmiHeader do
        begin
          biSize := sizeof(BITMAPINFOHEADER);
          biWidth := FHelper_Width;
          //Use negative height to scan top-down.
          biHeight := -FHelper_Height;
          biPlanes := 1;
          biBitCount := FHelper_BitsPerPixel; //GetDeviceCaps(hScrDC, BITSPIXEL);
          biCompression := BI_RGB;
        end;
        pBits := nil;
        hBmp := CreateDIBSection(FNewImage.Canvas.Handle, bitmap_info, DIB_RGB_COLORS, pBits, 0, 0);
        hMemDC := CreateCompatibleDC(FNewImage.Canvas.Handle);
        hOld := SelectObject(hMemDC, hBmp);

        CurOffset := 0;
  //      CopyMemory(@BitmapSize, pMap, SizeOf(BitmapSize));
        CurOffset := CurOffset + SizeOf(BitmapSize);
  //      CopyMemory(@fScreenGrabbed, PByte(pMap) + CurOffset, sizeof(fScreenGrabbed));
        CurOffset := CurOffset + SizeOf(fScreenGrabbed);
  //      CopyMemory(@FHelper_Width, PByte(pMap) + CurOffset, sizeof(FHelper_Width));
        CurOffset := CurOffset + SizeOf(FHelper_Width);
  //      CopyMemory(@FHelper_Height, PByte(pMap) + CurOffset, sizeof(FHelper_Height));
        CurOffset := CurOffset + SizeOf(FHelper_Height);
  //      CopyMemory(@FHelper_BitsPerPixel, PByte(pMap) + CurOffset, sizeof(FHelper_BitsPerPixel));
        CurOffset := CurOffset + SizeOf(FHelper_BitsPerPixel);
          CopyMemory(PByte(pMap) + CurOffset, @CurrentProcessId, sizeof(CurrentProcessId));
        CurOffset := CurOffset + SizeOf(CurrentProcessId);
          CopyMemory(PByte(pMap) + CurOffset, @pBits, sizeof(pBits));
        CurOffset := CurOffset + SizeOf(pBits);
      finally
        if pMap <> nil then
          UnmapViewOfFile(pMap);
        if hMap <> 0 then
          CloseHandle(hMap);
      end;

      SetEvent(EventReadBegin);
      if WaitForSingleObject(EventReadEnd, WaitTimeout) = WAIT_TIMEOUT then
        Exit;

//  SaveBitMap := TBitmap.Create;
//  SaveBitMap.Width := FHelper_Width;
//  SaveBitMap.Height := FHelper_Height;
//  BitBlt(SaveBitMap.Canvas.Handle, //куда
//  0,0,FHelper_Width,FHelper_Height,//координаты и размер
//  hMemDC, //откуда
//  0,0, //координаты
//  SRCCOPY); //режим копирования
//  SaveBitMap.SaveToFile('C:\Rufus\rmx_.bmp'); //+ StringReplace(DateTimeToStr(Now), ':', '_', [rfReplaceAll]) + '.bmp');
//  SaveBitMap.Free;

//      hDestDC := CreateCompatibleDC(FNewImage.Canvas.Handle);
//      hBmp := CreateCompatibleBitmap(FNewImage.Canvas.Handle, FHelper_Width, FHelper_Height);
//      SelectObject(hDestDC, hBmp);

//      pMap := MapViewOfFile(hMap, //дескриптор "проецируемого" объекта
//                              FILE_MAP_READ,  //разрешение чтения/записи
//                              0, 0,
//                              BitmapSize + HeaderSize);  //размер буфера
//      if pMap = nil then
//        Exit;
//
//      CopyMemory(pBits, (PByte(pMap) + HeaderSize), BitmapSize);
//      SetDIBits(hDestDC, hBmp, 0, FHelper_Height, (PByte(pMap) + HeaderSize), bitmap_info, DIB_RGB_COLORS);

  //    Winapi.Windows.FillRect(Form2.Image1.Canvas.Handle, Rect(0, 0, sWidth, sHeight), Form2.Image1.Canvas.Brush.Handle);
//      CS.Acquire;
//      try

//      hProc := OpenProcess(PROCESS_VM_READ, False, PID); // подключаемся к процессу зная его ID
//      if hProc <> 0 then // условие проверки подключения к процессу
//      try
//        ReadProcessMemory(hProc, ipBase, pBits, BitmapSize, numberRead); // чтение из памяти строки
//      finally
//        CloseHandle(hProc); // отсоединяемся от процесса
//      end;

      if fScreenGrabbed then
      begin
//        Result := BitBlt(FNewImage.Canvas.Handle, 0, 0, FHelper_Width, FHelper_Height, hMemDC, 0, 0, SRCCOPY);
        if ((FLastChangedX1 = 0)
          and (FLastChangedY1 = 0)
          and (FLastChangedX2 = FHelper_Width)
          and (FLastChangedY2 = FHelper_Height))
          or fFirstScreen then
          Result := BitBlt(FNewImage.Canvas.Handle, 0, 0, FHelper_Width, FHelper_Height, hMemDC, 0, 0, SRCCOPY)
        else
        if ((FLastChangedX2 - FLastChangedX1) > 0)
          or ((FLastChangedY2 - FLastChangedY1) > 0) then
          BitBlt(FNewImage.Canvas.Handle, FLastChangedX1, FDesktopDuplicator.LastChangedY1,
            FLastChangedX2 - FLastChangedX1,
            FLastChangedY2 - FLastChangedY1,
            hMemDC,
            FLastChangedX1, FLastChangedY1,
            SRCCOPY);
      end;
//      FNewImage.Invalidate;
//      SelectObject(hMemDC, hOld);
//      DeleteDC(hMemDC);
//      finally
//        CS.Release;
//      end;
  //    Form2.Image1.Repaint;
//     FNewImage.SaveToFile('C:\Screenshots\' + FormatDateTime('mm-dd-yyyy-hhnnss', Now()) + '.bmp');

//      SetEvent(EventReadEnd);
    finally
      ResetEvent(EventReadEnd);
      if hBmp <> 0 then
        DeleteObject(hBmp);
//      if hDestDC <> 0 then
//      begin
//        DeleteObject(hDestDC);
//        ReleaseDC(h, hScrDC);
//      end;
      SelectObject(hMemDC, hOld);
      if hMemDC <> 0 then
      begin
        DeleteDC(hMemDC);
      end;
//      if hScrDC <> 0 then
//        ReleaseDC(h, hScrDC);

//      if pMap <> nil then
//        UnmapViewOfFile(pMap);
//      if hMap <> 0 then
//        CloseHandle(hMap);
  //    if MutexRead <> 0 then
  //    begin
  //      ReleaseMutex(MutexRead);
  //      CloseHandle(MutexRead);
  //    end;
  //    if EventRead <> 0 then
  //    begin
  //      ResetEvent(EventRead);
  //      CloseHandle(EventRead);
  //      EventRead := 0;
  //    end;
      if EventWriteEnd <> 0 then
      begin
        CloseHandle(EventWriteEnd);
        EventWriteEnd := 0;
      end;
      if EventWriteBegin <> 0 then
      begin
        CloseHandle(EventWriteBegin);
        EventWriteBegin := 0;
      end;
      if EventReadBegin <> 0 then
      begin
        CloseHandle(EventReadBegin);
        EventReadBegin := 0;
      end;
      if EventReadEnd <> 0 then
      begin
        CloseHandle(EventReadEnd);
        EventReadEnd := 0;
      end;
    end;
  finally
    CS.Release;
  end;
end;

{procedure TRtcScreenEncoder.GetScreenFromHelperByMMF;
var
  SessionID: DWORD;
  IPCClient: TIPCClient;
  Request, Response: IMessageData;
  BmpStream: TMemoryStream;
begin
  if IsConsoleClient then
    SessionID := ActiveConsoleSessionID
  else
    SessionID := CurrentSessionID;

  IPCClient := TIPCClient.Create;
  try
    IPCClient.ComputerName := 'localhost';
    IPCClient.ServerName := 'Remox_IPC_Session_' + IntToStr(SessionID);
    IPCClient.ConnectClient(1000); //cDefaultTimeout
    try
      if IPCClient.IsConnected then
      begin
        Request := AcquireIPCData;
        Request.Data.WriteInteger('QueryType', QT_GETSCREEN);
        Response := IPCClient.ExecuteConnectedRequest(Request);

        if IPCClient.AnswerValid then
        begin
          BmpStream := TMemoryStream.Create;
          Response.Data.ReadStream('Screen', BmpStream);
          BmpStream.Position := 0;
          FNewImage.LoadFromStream(BmpStream);
          BmpStream.Free;
        end;

//          if IPCClient.LastError <> 0 then
//            ListBox1.Items.Add(Format('Error: Code %d', [IPCClient.LastError]));
      end;
    finally
      IPCClient.DisconnectClient;
    end;
  finally
    IPCClient.Free;
  end;
end;}

procedure SendIOToHelperByIPC(QueryType: Cardinal; IOType: DWORD; dwFlags: DWORD; dx, dy: Longint; mouseData: Integer; wVk, wScan: WORD; AText: WideString);
var
  SessionID: DWORD;
  Request, Response: IIPCData;
  IPCClient: TIPCClient;
  I, Len: Integer;
begin
//  if IsConsoleClient then
  if IsService then
    SessionID := ActiveConsoleSessionID
  else
    SessionID := CurrentSessionID;

  IPCClient := TIPCClient.Create;
  try
    IPCClient.ComputerName := 'localhost';
    IPCClient.ServerName := 'Remox_IPC_Session_' + IntToStr(SessionID);
    IPCClient.ConnectClient(1000); //cDefaultTimeout
    try
      if IPCClient.IsConnected then
      begin
        Request := AcquireIPCData;
        Request.Data.WriteInteger('QueryType', QueryType);
        Request.Data.WriteInteger('IOType', IOType);
        Request.Data.WriteInteger('dwFlags', dwFlags);
        Request.Data.WriteInteger('dx', dx);
        Request.Data.WriteInteger('dy', dy);
        Request.Data.WriteInteger('mouseData', mouseData);
        Request.Data.WriteInteger('wVk', wVk);
        Request.Data.WriteInteger('wScan', wScan);
        Response := IPCClient.ExecuteConnectedRequest(Request);

        if IPCClient.AnswerValid then
        begin

        end;

//          if IPCClient.LastError <> 0 then
//            ListBox1.Items.Add(Format('Error: Code %d', [IPCClient.LastError]));
      end;
    finally
      IPCClient.DisconnectClient;
    end;
  finally
    IPCClient.Free;
  end;
end;

//function TRtcScreenEncoder.GetDDAScreenshot: Boolean;
//var
//  fRes, fCreated, fNeedRecreate: Boolean;
//  FDesktopDuplicator: TDesktopDuplicationWrapper;
//begin
//  Result := False;
//
//  if not IsWindows8orLater then
//    Exit;
//
//  try
//    FDesktopDuplicator := TDesktopDuplicationWrapper.Create(fCreated);
//    if not fCreated then
//      Exit;
//    fRes := FDesktopDuplicator.GetFrame(fNeedRecreate);
//    if (not fRes)
//      or fNeedRecreate then
//    begin
//      Exit;
//
////      FDesktopDuplicator.Free;
////
////      FDesktopDuplicator := TDesktopDuplicationWrapper.Create(fCreated);
////      if not fCreated then
////        Exit;
////
////      fRes := FDesktopDuplicator.GetFrame(fNeedRecreate);
////      if not fRes then
////        Exit;
//    end;
//    if not FDesktopDuplicator.DrawFrame(FNewImage {FDesktopDuplicator.Bitmap}) then
//      Exit;
////    if FDesktopDuplicator.Bitmap = nil then
////      Exit;
//
////FDesktopDuplicator.Bitmap.SaveToFile('C:\Rufus\scr.bmp1');
//
////      Result := BitBlt(FNewImage.Canvas.Handle, 0, 0, FNewImage.Width,
////        FNewImage.Height, FDesktopDuplicator.Bitmap.Canvas.Handle, 0, 0,
////        FCaptureMask);
//
//    Result := True;
//  finally
//    FDesktopDuplicator.Free;
//  end;
//end;

function TRtcScreenEncoder.CaptureBlock: boolean;
var
  BlockTop: integer;
  DW: HWND;
  SDC: HDC;
  err: HRESULT;
  fNeedRecreate, fHaveScreen, fRes: Boolean;
  time: DWORD;

  function CaptureNow: boolean;
  var
    i, j: Integer;
  begin
    SwitchToActiveDesktop; //Если под SYSTEM
//  SetWinSta0Desktop;

    FNewImage.Canvas.Lock;
    try
      DW := GetCaptureWindow;
//      if ((Win32MajorVersion = 6) and (Win32MinorVersion >= 2) {Windows 8})
//        or (Win32MajorVersion = 10) then
//      begin
//        if FDesktopDuplicator.IsScreenshotReady then
//        begin
//          for i := 0 to 1000 do
//            if not FDesktopDuplicator.IsScreenshotReady then
//            Sleep(10);
//          Sleep(10);
//        end;
//
//        FDesktopDuplicator.GetScreenshot(FNewImage, TRect.Create(FCaptureLeft, FCaptureTop + BlockTop, FCaptureLeft + FNewImage.Width, FCaptureTop + BlockTop + FNewImage.Height));
//      end
//      else
      if (LowerCase(GetInputDesktopName) <> 'default') //Мы либо на экране блокировки / UAC
        or (IsService) then //Либо мы служба
//      if True then
      begin
//        CS.Acquire;
//time := GetTickCount;
        Result := GetScreenFromHelperByMMF(False, fFirstScreen);
        ScrCap.HaveScreen := Result;
        if Result then
          fFirstScreen := False;
//time := GetTickCount - time;
//time := i;
//        FNewImage.SaveToFile('C:\Screenshots\' + StringReplace(DateTimeToStr(Now), ':', '_', [rfReplaceAll]) + '.bmp');
{        try
          FNewImage.Assign(FScrCapture.FHelper.FHelperBitmap);
        except
          on E:Exception do
          begin
            xLog('Error '+ E.ClassName+': '+E.Message);
            Result := False;
            Exit;
          end;
        end;}
//        CS.Release;
      end
      else
      begin
//          Result := BitBlt(FNewImage.Canvas.Handle, 0, 0, FNewImage.Width,
//            FNewImage.Height, SDC, FCaptureLeft, FCaptureTop + BlockTop,
//            FCaptureMask);
//          ScrCap.HaveScreen := Result;

//         FImageCatcher.TargetHandle := DW;
//         FImageCatcher.CatchType := ctDirectX;
//         //ImageCatcher.ActivateTarget;
//         FImageCatcher.GetScreenShot(FNewImage, FNewImage.Width, FNewImage.Height, FCaptureLeft, FCaptureTop + BlockTop, FCaptureMask);
////         FNewImage.Assign(FImageCatcher.Bitmap);
//         ScrCap.HaveScreen := FImageCatcher.HaveScreen;

//          FDesktopDuplicator.GetScreenshot(FNewImage);
//          while not FDesktopDuplicator.IsScreenshotReady do
//          begin
//            Sleep(1);
//            Application.ProcessMessages;
//          end;
//          ScrCap.HaveScreen := FDesktopDuplicator.IsScreenshotReady;

//          fHaveScreen := GetDDAScreenshot;
//          ScrCap.HaveScreen := True; //fHaveScreen;

//time := GetTickCount;
            fHaveScreen := False;
            fRes := FDesktopDuplicator.GetFrame(fNeedRecreate);
            i := 0;
            while fNeedRecreate do
            begin
//              Sleep(1);
              //Application.ProcessMessages;
              FDesktopDuplicator.Free;
              FDesktopDuplicator := TDesktopDuplicationWrapper.Create(FDDACreated);
              if FDDACreated then
                fRes := FDesktopDuplicator.GetFrame(fNeedRecreate);

//              Application.ProcessMessages;

//              i := i + 1;
//              if i = 4 then
                Break;
            end;
            if fRes
              and (not fNeedRecreate) then
            begin
              fHaveScreen := FDesktopDuplicator.DrawFrame(FDesktopDuplicator.Bitmap);//, FNewImage.PixelFormat);
              fHaveScreen := fHaveScreen;
//            end
//            else
//            begin
              //Memo1.Lines.Add('no frame ' + IntToHex(FDuplication.Error));
            end;
//time := GetTickCount - time;
time := i;

//          if (FDesktopDuplicator.Bitmap <> nil) then
//            and (FDesktopDuplicator.Bitmap.PixelFormat = pf4bit) then
//            FDesktopDuplicator.Bitmap.SaveToFile('C:\Rufus\' + StringReplace(DateTimeToStr(Now), ':', '_', [rfReplaceAll]) + '.bmp');
{            try
                DW := GetCaptureWindow;
              //Get GDI screenshot
              //if not fHaveScreen then
              begin
                DW := GetCaptureWindow;
                try
                  SDC := GetDC(DW);
                except
                  SDC := 0;
                end;
                if (DW <> 0) and (SDC = 0) then
                begin
                  DW := 0;
                  try
                    SDC := GetDC(DW);
                  except
                    SDC := 0;
                  end;
                  if SDC = 0 then
                  begin
                    Result := False;
                    ScrCap.HaveScreen := False;
                    Exit;
                  end;
                end;

                Result := BitBlt(FNewImage.Canvas.Handle, 0, 0, FNewImage.Width,
                  FNewImage.Height, SDC, FCaptureLeft, FCaptureTop + BlockTop,
                  FCaptureMask);

                if not Result then
                begin
                  err := GetLastError;
                  xLog('BitBlt Error: ' + IntToStr(err) + ' ' + SysErrorMessage(err));
                end;

                fHaveScreen := Result;
                ScrCap.HaveScreen := fHaveScreen;
              end;
//
////              ScrCap.HaveScreen := True;
            finally
              ReleaseDC(DW, SDC);
            end;}

          if fHaveScreen then
          begin
            if (FDesktopDuplicator.LastChangedX1 = 0)
              and (FDesktopDuplicator.LastChangedY1 = 0)
              and (FDesktopDuplicator.LastChangedX2 = FDesktopDuplicator.Bitmap.Width)
              and (FDesktopDuplicator.LastChangedY2 = FDesktopDuplicator.Bitmap.Height)  then
//              FNewImage.Assign(FDesktopDuplicator.Bitmap)
              BitBlt(FNewImage.Canvas.Handle, 0, 0,
                FDesktopDuplicator.Bitmap.Width, FDesktopDuplicator.Bitmap.Height,
                FDesktopDuplicator.Bitmap.Canvas.Handle,
                0, 0,
                SRCCOPY)
            else
            if ((FDesktopDuplicator.LastChangedX2 - FDesktopDuplicator.LastChangedX1) > 0)
              or ((FDesktopDuplicator.LastChangedY2 - FDesktopDuplicator.LastChangedY1) > 0) then
              BitBlt(FNewImage.Canvas.Handle, FDesktopDuplicator.LastChangedX1, FDesktopDuplicator.LastChangedY1,
                FDesktopDuplicator.LastChangedX2 - FDesktopDuplicator.LastChangedX1,
                FDesktopDuplicator.LastChangedY2 - FDesktopDuplicator.LastChangedY1,
                FDesktopDuplicator.Bitmap.Canvas.Handle,
                FDesktopDuplicator.LastChangedX1, FDesktopDuplicator.LastChangedY1,
                SRCCOPY);
          end;
          fHaveScreen := True;
          ScrCap.HaveScreen := fHaveScreen;
          Result := fHaveScreen;
      end;

//      ScrCap.HaveScreen := not (LowerCase(GetInputDesktopName) <> 'default') //Мы либо на экране блокировки / UAC
//        and (not IsServiceStarted(RTC_HOSTSERVICE_NAME));
    finally
      FNewImage.Canvas.Unlock;
    end;
  end;

begin
  CS.Acquire;
  try
    FMarked[FImgIndex] := False;
  finally
    CS.Release;
  end;
  BlockTop := FBlockHeight * FImgIndex;

  Result := CaptureNow;

  if Result then
    case FBytesPerPixel of
      4:
        if FReduce32bit <> 0 then
          DWord_ReduceColors(BitmapDataPtr(FNewImage), FNewBlockSize,
            FReduce32bit);
      2:
        if FReduce16bit <> 0 then
          DWord_ReduceColors(BitmapDataPtr(FNewImage), FNewBlockSize,
            FReduce16bit);
    end;
end;

function TRtcScreenEncoder.CompressBlock_Delta: RtcByteArray;
var
  len: integer;
begin
  len := DWordCompress_Delta(BitmapDataPtr(FOldImage), BitmapDataPtr(FNewImage),
    Addr(FTmpStorage[0]), FNewBlockSize);
  if len = 0 then
    SetLength(Result, 0)
  else
  begin
    SetLength(Result, len);
    Move(FTmpStorage[0], Result[0], len);
  end;
end;

function TRtcScreenEncoder.CompressBlock_Normal: RtcByteArray;
var
  len: integer;
begin
  len := DWordCompress_Normal(BitmapDataPtr(FNewImage), Addr(FTmpStorage[0]),
    FNewBlockSize);
  if len = 0 then
    SetLength(Result, 0)
  else
  begin
    SetLength(Result, len);
    Move(FTmpStorage[0], Result[0], len);
  end;
end;

function TRtcScreenEncoder.CompressBlock_Initial: RtcByteArray;
var
  len: integer;
begin
  len := DWordCompress_Normal(BitmapDataPtr(FOldImage), Addr(FTmpStorage[0]),
    FNewBlockSize);
  if len = 0 then
    SetLength(Result, 0)
  else
  begin
    SetLength(Result, len);
    Move(FTmpStorage[0], Result[0], len);
  end;
end;

procedure TRtcScreenEncoder.MarkForCapture(x1, y1, x2, y2: integer);
var
  TopCord, BotCord, i: integer;
begin
  CS.Acquire;
  try
    TopCord := FCaptureTop;
    BotCord := TopCord + FBlockHeight - 1;
    if (FCaptureLeft <= x2) and (FCaptureWidth + FCaptureLeft - 1 >= x1) then
      for i := 0 to FBlockCount - 1 do
      begin
        if (BotCord >= y1) and (TopCord <= y2) then
          FMarked[i] := True;
        Inc(BotCord, FBlockHeight);
        Inc(TopCord, FBlockHeight);
      end;
  finally
    CS.Release;
  end;
end;

procedure TRtcScreenEncoder.MarkForCapture;
var
  i: integer;
begin
  CS.Acquire;
  try
    for i := 0 to FBlockCount - 1 do
      FMarked[i] := True;
  finally
    CS.Release;
  end;
end;

{ - RtcScreenCapture - }

//++
//procedure TRtcScreenCapture.CheckSAS(value : Boolean; name : String);
//var
//  s,
//  sErrValue : String;
//begin
//	if (not value) then
//  begin
//    case GetLastError() of
//			{ERROR_REQUEST_OUT_OF_SEQUENCE}776:
//            	sErrValue := 'You need to call SASLibEx_Init first!';
//
//			ERROR_PRIVILEGE_NOT_HELD:
//				sErrValue := 'The function needs a system privilege that is not available in the process.';
//
//			ERROR_FILE_NOT_FOUND:
//				sErrValue := 'The supplied session is not available.';
//
//
//			ERROR_CALL_NOT_IMPLEMENTED:
//				sErrValue := 'The called function is not available in this demo (license).';
//
//
//			ERROR_OLD_WIN_VERSION:
//				sErrValue := 'The called function does not support the Windows system.';
//
//    else
//			sErrValue := SysErrorMessage(GetLastError());
//		end;
//
//		s := Format('The function call %s failed. '#13#10'%s',
//			[name, sErrValue]);
//
//		//MessageDlg(s,
//		//	mtError, [mbOK], 0);
//    xLog(s);
//  end;
//end;

constructor TRtcScreenCapture.Create;
var
  err: LongInt;
  SessionID: DWORD;
  NameSuffix: String;
begin
  inherited;

  if IsService then
  begin
    SessionID := ActiveConsoleSessionID;
    NameSuffix := '_C';
  end
  else
  begin
    SessionID := CurrentSessionID;
    NameSuffix := '';
  end;

{  hCursorInfoEventWriteBegin := DoCreateEvent(PWideChar(WideString('Global\RMX_CURINFO_WRITE_BEGIN_SESSION_' + IntToStr(SessionID) + NameSuffix)));
  hCursorInfoEventWriteEnd := DoCreateEvent(PWideChar(WideString('Global\RMX_CURINFO_WRITE_END_SESSION_' + IntToStr(SessionID) + NameSuffix)));

  tCursorInfoThrd := TCursorInfoThread.Create(False);
  tCursorInfoThrd.FreeOnTerminate := True;}

//  SimulateKBM := TSimulateKBM.Create;

  FShiftDown := False;
  FCtrlDown := False;
  FAltDown := False;

  FReduce16bit := 0;
  FReduce32bit := 0;
  FLowReduce16bit := 0;
  FLowReduce32bit := 0;
  FLowReduceColors := False;
  FLowReduceType := 0;
  FLowReduceColorPercent := 0;

  FBPPLimit := 4;
  FMaxTotalSize := 0;
  FScreenBlockCount := 1;
  FScreen2BlockCount := 1;
  FScreen2Delay := 0;
  FFullScreen := True;
  FCaptureMask := SRCCOPY;

  FScreenWidth := 0;
  FScreenHeight := 0;
  FScreenLeft := 0;
  FScreenTop := 0;

  FCaptureLeft := 0;
  FCaptureTop := 0;
  FCaptureWidth := 0;
  FCaptureHeight := 0;

{$IFDEF DFMirage}
  ScrDeltaRec := nil;
  FMirage := False;
  vd := nil;
  m_BackBm := nil;
  dfm_urgn := nil;
{$ENDIF}
  ScrIn := nil;
  FMouseInit := True;
  FLastMouseUser := '';
  FLastMouseX := -1;
  FLastMouseY := -1;
  FMouseX := -1;
  FMouseY := -1;

//++
//  fSASInit := False;
//  try
//    fSASInit := SASLibEx.SASLibEx_InitLib;
//  finally
//  end;
//  err := GetLastError();
//  if (not fSASInit)
//    and (err <> 0) then
//    xLog(Format('The SAS Library could not be initialized:\r\n %s', [SysErrorMessage(err)]));

//  FInputThread := TInputThread.Create(True);
//  FInputThread.FreeOnTerminate := True;
//  FInputThread.Start;

//  SetInputThread(True);

 SwitchToActiveDesktop;

//Доделать
//  if ((Win32MajorVersion = 6) and (Win32MinorVersion >= 2) {Windows 8})
//    or (Win32MajorVersion = 10) then
//  begin
//    FDesktopDuplicator := TDesktopDuplicator.Create;
//    FDesktopDuplicator.InitWindow(-1);
//    FDesktopDuplicator.DrawType := ScreenDrawTypeDesktop;
//    FDesktopDuplicator.Start;
//  end;
end;

destructor TRtcScreenCapture.Destroy;
begin
  ReleaseAllKeys;

{  tCursorInfoThrd.Terminate;

  CloseHandle(hCursorInfoEventWriteBegin);
  CloseHandle(hCursorInfoEventWriteEnd);}

//  SetInputThread(False);
//  FInputThread.Terminate;
//  FInputThread.Free;

//  if Assigned(SimulateKBM) then
//    SimulateKBM.Free;

{$IFDEF DFMirage}
  if assigned(vd) then
  begin
    vd.Free;
    vd := nil;
    m_BackBm.Free;
    m_BackBm := nil;
  end;
{$ENDIF}
  if assigned(ScrIn) then
  begin
    ScrIn.Free;
    ScrIn := nil;
  end;

{$IFDEF DFMirage}
  if assigned(ScrDeltaRec) then
  begin
    ScrDeltaRec.Free;
    ScrDeltaRec := nil;
  end;
  if assigned(dfm_urgn) then
  begin
    dfm_urgn.Free;
    dfm_urgn := nil;
  end;
{$ENDIF}
  if FMouseDriver then
    SetMouseDriver(False);

//Доделать
//  if ((Win32MajorVersion = 6) and (Win32MinorVersion >= 2) {Windows 8})
//    or (Win32MajorVersion = 10) then
//  begin
//    FDesktopDuplicator.Stop;
//    FDesktopDuplicator.Free;
//  end;

  inherited;
end;

procedure TRtcScreenCapture.InitSize;
begin
  if IsService then //Если сервис нужно получать параметры экрана из хелпера
  begin
    FScreenWidth := FHelper_Width;
    FScreenHeight := FHelper_Height;
    FScreenLeft := 0;
    FScreenTop := 0;
  end
  else
  begin
  {$IFDEF MULTIMON}
    if MultiMonitor then
    begin
      FScreenWidth := Screen.DesktopWidth;
      FScreenHeight := Screen.DesktopHeight;
      FScreenLeft := Screen.DesktopLeft;
      FScreenTop := Screen.DesktopTop;
    end
    else
  {$ENDIF}
    begin
      FScreenWidth := Screen.Width;
      FScreenHeight := Screen.Height;
      FScreenLeft := 0;
      FScreenTop := 0;
    end;
  end;

  if FullScreen then
  begin
    FCaptureLeft := FScreenLeft;
    FCaptureTop := FScreenTop;
    FCaptureWidth := FScreenWidth;
    FCaptureHeight := FScreenHeight;
  end
  else
  begin
    FCaptureLeft := FFixedRegion.Left;
    FCaptureTop := FFixedRegion.Top;
    FCaptureWidth := FFixedRegion.Right - FCaptureLeft;
    FCaptureHeight := FFixedRegion.Bottom - FCaptureTop;
  end;
end;

procedure TRtcScreenCapture.Init;
begin
{$IFDEF DFMirage}
  if FMirage then
  begin
    if not assigned(vd) then
    begin
      InitSize;
      vd := TVideoDriver.Create;
    end;
  end
  else
{$ENDIF}
    if not assigned(ScrIn) then
    begin
      ScrIn := TRtcScreenEncoder.Create;
      if (LowerCase(GetInputDesktopName) <> 'default')
        or (IsService) then
        ScrIn.GetScreenFromHelperByMMF(True);
      InitSize;
      ScrIn.Setup(FBPPLimit, FScreenBlockCount, FMaxTotalSize);
      ScrIn.Reduce16bit := FReduce16bit;
      ScrIn.Reduce32bit := FReduce32bit;
      ScrIn.FullScreen := FFullScreen;
      ScrIn.FixedRegion := FFixedRegion;
      ScrIn.CaptureMask := FCaptureMask;
      ScrIn.MultiMonitor := FMultiMon;
      ScrIn.ScrCap := Self;
    end;
end;

function TRtcScreenCapture.GrabScreen: boolean;
begin
  Init;
{$IFDEF DFMirage}
  if FMirage then
  begin
    if assigned(ScrDeltaRec) then
    begin
      ScrDeltaRec.Free;
      ScrDeltaRec := nil;
    end;

    if ScreenChanged then
      m_Init := True;

    if m_Init then
    begin
      if FMirage then
      begin
        Result := True;
        m_Init := False;
        ScrDeltaRec := GrabImageFullscreen;
      end
      else
        Result := ScrIn.Capture;
    end
    else
    begin
      Result := False;
      ScrDeltaRec := GrabImageIncremental;
    end;
  end
  else
{$ENDIF}
    Result := ScrIn.Capture;
end;

function TRtcScreenCapture.GetScreenDelta: RtcString;
var
  rec: TRtcRecord;
begin
{$IFDEF DFMirage}
  if FMirage then
  begin
    if assigned(ScrDeltaRec) then
      Result := ScrDeltaRec.toCode
    else
      Result := '';
  end
  else
{$ENDIF}
    if ScrIn.GetScreenData.isType = rtc_Record then
    begin
      rec := ScrIn.GetScreenData.asRecord;
      if assigned(rec) then
        Result := rec.toCode
      else
        Result := '';
    end
    else
      Result := '';
end;

function TRtcScreenCapture.GetScreen: RtcString;
var
  rec: TRtcRecord;
begin
{$IFDEF DFMirage}
  if FMirage then
  begin
    rec := GrabImageOldScreen;
    if assigned(rec) then
      Result := rec.toCode
    else
      Result := '';
    rec.Free;
  end
  else
{$ENDIF}
    if ScrIn.GetInitialScreenData.isType = rtc_Record then
    begin
      rec := ScrIn.GetInitialScreenData.asRecord;
      if assigned(rec) then
        Result := rec.toCode
      else
        Result := '';
    end
    else
      Result := '';
end;

procedure TRtcScreenCapture.SetMaxTotalSize(const Value: integer);
begin
  if FMaxTotalSize <> Value then
  begin
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
{$IFDEF DFMirage}
    if assigned(vd) then
    begin
      vd.Free;
      vd := nil;
    end;
{$ENDIF}
    FMaxTotalSize := Value;
  end;
end;

procedure TRtcScreenCapture.SetBPPLimit(const Value: integer);
begin
  if FBPPLimit <> Value then
  begin
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
{$IFDEF DFMirage}
    if assigned(vd) then
    begin
      vd.Free;
      vd := nil;
    end;
{$ENDIF}
    FBPPLimit := Value;
  end;
end;

procedure TRtcScreenCapture.SetScreenBlockCount(const Value: integer);
begin
  if FScreenBlockCount <> Value then
  begin
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
{$IFDEF DFMirage}
    if assigned(vd) then
    begin
      vd.Free;
      vd := nil;
    end;
{$ENDIF}
    FScreenBlockCount := Value;
  end;
end;

procedure TRtcScreenCapture.SetScreen2BlockCount(const Value: integer);
begin
  if FScreen2BlockCount <> Value then
  begin
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
{$IFDEF DFMirage}
    if assigned(vd) then
    begin
      vd.Free;
      vd := nil;
    end;
{$ENDIF}
    FScreen2BlockCount := Value;
  end;
end;

procedure TRtcScreenCapture.SetScreen2Delay(const Value: integer);
begin
  if FScreen2Delay <> Value then
  begin
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
{$IFDEF DFMirage}
    if assigned(vd) then
    begin
      vd.Free;
      vd := nil;
    end;
{$ENDIF}
    FScreen2Delay := Value;
  end;
end;

procedure TRtcScreenCapture.SetFixedRegion(const Value: TRect);
var
  dif: integer;
begin
  if assigned(ScrIn) then
  begin
    ScrIn.Free;
    ScrIn := nil;
  end;
{$IFDEF DFMirage}
  if assigned(vd) then
  begin
    vd.Free;
    vd := nil;
  end;
{$ENDIF}
  FFullScreen := False;
  FFixedRegion := Value;
  if (FFixedRegion.Right - FFixedRegion.Left) mod 4 <> 0 then
  begin
    dif := 4 - ((FFixedRegion.Right - FFixedRegion.Left) mod 4);
    if FFixedRegion.Left - dif >= 0 then
      FFixedRegion.Left := FFixedRegion.Left - dif
    else
      FFixedRegion.Right := FFixedRegion.Right + dif;
  end;
end;

procedure TRtcScreenCapture.SetFullScreen(const Value: boolean);
begin
  if Value <> FFullScreen then
  begin
    FFullScreen := Value;
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
{$IFDEF DFMirage}
    if assigned(vd) then
    begin
      vd.Free;
      vd := nil;
    end;
{$ENDIF}
  end;
end;

procedure TRtcScreenCapture.SetMouseDriver(const Value: boolean);
begin
{$IFDEF KMDriver}
  if FMouseDriver <> Value then
  begin
    FMouseDriver := Value;
    if FMouseDriver then
    begin
      if FMouseAInit = 0 then
      begin
        if IsWinNT then
          if MouseAInf.MouseAInit then
            Inc(FMouseAInit);
      end
      else
        Inc(FMouseAInit);
    end
    else if (FMouseAInit > 0) then
    begin
      DEC(FMouseAInit);
      if FMouseAInit = 0 then
        MouseAInf.MouseAUnInit;
    end;
  end;
{$ENDIF}
end;

procedure TRtcScreenCapture.SetReduce16bit(const Value: longword);
begin
  if Value <> FReduce16bit then
  begin
    FReduce16bit := Value;
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
{$IFDEF DFMirage}
    if assigned(vd) then
    begin
      vd.Free;
      vd := nil;
    end;
{$ENDIF}
  end;
end;

procedure TRtcScreenCapture.SetReduce32bit(const Value: longword);
begin
  if Value <> FReduce32bit then
  begin
    FReduce32bit := Value;
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
{$IFDEF DFMirage}
    if assigned(vd) then
    begin
      vd.Free;
      vd := nil;
    end;
{$ENDIF}
  end;
end;

procedure TRtcScreenCapture.SetLowReduce16bit(const Value: longword);
begin
  if Value <> FLowReduce16bit then
  begin
    FLowReduce16bit := Value;
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
{$IFDEF DFMirage}
    if assigned(vd) then
    begin
      vd.Free;
      vd := nil;
    end;
{$ENDIF}
  end;
end;

procedure TRtcScreenCapture.SetLowReduce32bit(const Value: longword);
begin
  if Value <> FLowReduce32bit then
  begin
    FLowReduce32bit := Value;
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
{$IFDEF DFMirage}
    if assigned(vd) then
    begin
      vd.Free;
      vd := nil;
    end;
{$ENDIF}
  end;
end;

procedure TRtcScreenCapture.SetLowReduceColors(const Value: boolean);
begin
  if Value <> FLowReduceColors then
  begin
    FLowReduceColors := Value;
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
{$IFDEF DFMirage}
    if assigned(vd) then
    begin
      vd.Free;
      vd := nil;
    end;
{$ENDIF}
  end;
end;

procedure TRtcScreenCapture.SetLowReduceType(const Value: integer);
begin
  if Value <> FLowReduceType then
  begin
    FLowReduceType := Value;
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
{$IFDEF DFMirage}
    if assigned(vd) then
    begin
      vd.Free;
      vd := nil;
    end;
{$ENDIF}
  end;
end;

procedure TRtcScreenCapture.SetLowReduceColorPercent(const Value: integer);
begin
  if Value <> FLowReduceColorPercent then
  begin
    FLowReduceColorPercent := Value;
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
{$IFDEF DFMirage}
    if assigned(vd) then
    begin
      vd.Free;
      vd := nil;
    end;
{$ENDIF}
  end;
end;

function TRtcScreenCapture.GetFixedRegion: TRect;
begin
  Result := FixedRegion;
end;

function TRtcScreenCapture.GetFullScreen: boolean;
begin
  Result := FFullScreen;
end;

function TRtcScreenCapture.GetMaxTotalSize: integer;
begin
  Result := FMaxTotalSize;
end;

function TRtcScreenCapture.GetBPPLimit: integer;
begin
  Result := FBPPLimit;
end;

function TRtcScreenCapture.GetScreenBlockCount: integer;
begin
  Result := FScreenBlockCount;
end;

function TRtcScreenCapture.GetScreen2BlockCount: integer;
begin
  Result := FScreen2BlockCount;
end;

function TRtcScreenCapture.GetScreen2Delay: integer;
begin
  Result := FScreen2Delay;
end;

function TRtcScreenCapture.GetReduce16bit: longword;
begin
  Result := FReduce16bit;
end;

function TRtcScreenCapture.GetReduce32bit: longword;
begin
  Result := FReduce32bit;
end;

function TRtcScreenCapture.GetLowReduce16bit: longword;
begin
  Result := FLowReduce16bit;
end;

function TRtcScreenCapture.GetLowReduce32bit: longword;
begin
  Result := FLowReduce32bit;
end;

function TRtcScreenCapture.GetLowReduceColors: boolean;
begin
  Result := FLowReduceColors;
end;

function TRtcScreenCapture.GetLowReduceType: integer;
begin
  Result := FLowReduceType;
end;

function TRtcScreenCapture.GetLowReduceColorPercent: integer;
begin
  Result := FLowReduceColorPercent;
end;

procedure TRtcScreenCapture.Clear;
begin
{$IFDEF DFMirage}
  if FMirage then
    m_Init := True
  else
{$ENDIF}
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
  FMouseInit := True;
  ReleaseAllKeys;
end;

function TRtcScreenCapture.GetLayeredWindows: boolean;
begin
  Result := (FCaptureMask and RTC_CAPTUREBLT) = RTC_CAPTUREBLT;
end;

procedure TRtcScreenCapture.SetLayeredWindows(const Value: boolean);
begin
  if Value then
    FCaptureMask := FCaptureMask or RTC_CAPTUREBLT
  else
    FCaptureMask := FCaptureMask and not RTC_CAPTUREBLT;
end;

{$IFDEF DFMirage}
{ Mirage Video Capture }

function ScaleByPixformat(const v: integer; pf: TPixelFormat): integer;
begin
  case pf of
    pf1bit:
      Result := v div 8;
    pf4bit:
      Result := v div 2;
    pf8bit:
      Result := v;
    pf15bit, pf16bit:
      Result := v * 2;
    pf24bit:
      Result := v * 3;
  else
    Result := v * 4;
  end;
end;

function BPPToPixelFormat(a: byte): TPixelFormat;
begin
  case a of
    1:
      Result := pf1bit;
    4:
      Result := pf4bit;
    8:
      Result := pf8bit;
    15:
      Result := pf15bit;
    16:
      Result := pf16bit;
    24:
      Result := pf24bit;
    32:
      Result := pf32bit;
  else
    Result := pf32bit;
  end;
end;

function TRtcScreenCapture.GetMirageDriver: boolean;
begin
  Result := FMirage;
end;

procedure TRtcScreenCapture.SetMirageDriver(const Value: boolean);
var
  fixed: TRect;
begin
  if FMirage <> Value then
  begin
    FMirage := Value;
    if FMirage then
    begin
      if not assigned(m_BackBm) then
      begin
        Init;
        try
          vd.MultiMonitor := MultiMonitor;
          if not vd.ExistMirrorDriver then
            FMirage := False
          else if vd.IsMirrorDriverActive then
          begin
            vd.DeactivateMirrorDriver;
            Sleep(2000);
            if not vd.ActivateMirrorDriver then
              FMirage := False
            else
            begin
              Sleep(1000);
              vd.MapSharedBuffers;
              FMirage := vd.IsDriverActive;
              if not FMirage then
              begin
                vd.UnMapSharedBuffers;
                vd.DeactivateMirrorDriver;
              end;
            end;
          end
          else if not vd.ActivateMirrorDriver then
            FMirage := False
          else
          begin
            Sleep(1000);
            vd.MapSharedBuffers;
            FMirage := vd.IsDriverActive;
          end;
        except
          FMirage := False;
        end;

        if FMirage then
        begin
          m_Init := True;
          FMouseInit := True;
          m_BackBm := TBitmap.Create;
          m_BackBm.PixelFormat := BPPToPixelFormat(vd.BitsPerPixel);

          if FFullScreen then
          begin
{$IFDEF MULTIMON}
            if MultiMonitor then
            begin
              FFixedRegion.Left := Screen.DesktopRect.Left;
              FFixedRegion.Top := Screen.DesktopRect.Top;
              FFixedRegion.Right := Screen.DesktopRect.Right;
              FFixedRegion.Bottom := Screen.DesktopRect.Bottom;
            end
            else
{$ENDIF}
            begin
              FFixedRegion.Left := 0;
              FFixedRegion.Top := 0;
              FFixedRegion.Right := Screen.Width;
              FFixedRegion.Bottom := Screen.Height;
            end;
          end;

          vd.Reduce16bit := Reduce16bit;
          vd.Reduce32bit := Reduce32bit;
          vd.LowReduce16bit := LowReduce16bit;
          vd.LowReduce32bit := LowReduce32bit;
          vd.LowReduceColors := LowReducedColors;
          vd.LowReduceType := LowReduceType;
          vd.LowReduceColorPercent := LowReduceColorPercent;

          m_BackBm.Width := FFixedRegion.Right - FFixedRegion.Left;
          m_BackBm.Height := FFixedRegion.Bottom - FFixedRegion.Top;

{$IFDEF MULTIMON}
          if MultiMonitor then
          begin
            fixed.Left := FFixedRegion.Left - Screen.DesktopLeft;
            fixed.Top := FFixedRegion.Top - Screen.DesktopTop;
            fixed.Right := FFixedRegion.Right - Screen.DesktopLeft;
            fixed.Bottom := FFixedRegion.Bottom - Screen.DesktopTop;
          end
          else
{$ENDIF}
            fixed := FFixedRegion;

          vd.SetRegion(fixed);
        end
        else
        begin
          vd.Free;
          vd := nil;
        end;
      end;
    end
    else
    begin
      if assigned(m_BackBm) then
      begin
        vd.Free;
        vd := nil;
        m_BackBm.Free;
        m_BackBm := nil;
      end;
    end;
  end;
end;

function TRtcScreenCapture.ScreenChanged: boolean;
Var
  _ScreenWidth, _ScreenHeight, _ScreenLeft, _ScreenTop: integer;

  r: TRect;
  DW: HWND;
  SDC: HDC;

begin
 SwitchToActiveDesktop; //Если под SYSTEM

  if IsService then //Если сервис нужно получать параметры экрана из хелпера
  begin
//    GetScreenFromHelperByMMF;

    _ScreenLeft := 0;
    _ScreenTop := 0;
    _ScreenWidth := FHelper_Width;
    _ScreenHeight := FHelper_Height;
  end
  else
  begin
  {$IFDEF MULTIMON}
    if MultiMonitor then
      r := Screen.DesktopRect
    else
  {$ENDIF}
    begin
      DW := GetCaptureWindow;
      try
        SDC := GetDC(DW);
      except
        SDC := 0;
      end;
      if (DW <> 0) and (SDC = 0) then
      begin
        DW := 0;
        try
          SDC := GetDC(DW);
        except
          SDC := 0;
        end;
        if SDC = 0 then
        begin
          Result := False;
          Exit;
        end;
      end;
      GetWindowRect(DW, r);
      ReleaseDC(DW, SDC);
    end;
    _ScreenLeft := r.Left;
    _ScreenTop := r.Top;
    _ScreenWidth := r.Right - r.Left;
    _ScreenHeight := r.Bottom - r.Top;
  end;

  Result := (FScreenWidth <> _ScreenWidth) or (FScreenHeight <> _ScreenHeight)
    or (FScreenLeft <> _ScreenLeft) or (FScreenTop <> _ScreenTop);

  if Result then
  begin
    MirageDriver := False;
    Sleep(1000);
    MirageDriver := True;
    Init;
  end;
end;

function TRtcScreenCapture.GrabImageIncremental: TRtcRecord;
begin
  dfm_urgn.StartAdd;
  vd.UpdateIncremental(dfm_DstStride, dfm_urgn, dfm_ImgLine0);
  Result := dfm_urgn.CaptureRgnDelta(vd, dfm_DstStride, dfm_ImgLine0);
end;

function TRtcScreenCapture.GrabImageFullscreen: TRtcRecord;
begin
  dfm_ImgLine0 := PAnsiChar(m_BackBm.ScanLine[0]);
  dfm_DstStride := -ScaleByPixformat(m_BackBm.Width, m_BackBm.PixelFormat);

  dfm_fixed.Left := FFixedRegion.Left - FScreenLeft;
  dfm_fixed.Top := FFixedRegion.Top - FScreenTop;
  dfm_fixed.Right := FFixedRegion.Right - FScreenLeft;
  dfm_fixed.Bottom := FFixedRegion.Bottom - FScreenTop;

  if not assigned(dfm_urgn) then
  begin
    dfm_urgn := TGridUpdRegion.Create;
    dfm_urgn.SetScrRect(dfm_fixed);

    dfm_urgn.ScanStep := FScreenBlockCount;
    if dfm_urgn.ScanStep < 1 then
      dfm_urgn.ScanStep := 1
    else if dfm_urgn.ScanStep > 12 then
      dfm_urgn.ScanStep := 12;

    dfm_urgn.ScanStep2 := FScreen2BlockCount;
    if dfm_urgn.ScanStep2 < 1 then
      dfm_urgn.ScanStep2 := 1
    else if dfm_urgn.ScanStep2 > 12 then
      dfm_urgn.ScanStep2 := 12;

    dfm_urgn.Scan2Delay := FScreen2Delay;

    if FMaxTotalSize > 0 then
      dfm_urgn.MaxSize := FMaxTotalSize
    else
      dfm_urgn.MaxSize := 0;
  end;

  dfm_urgn.StartAdd;
  dfm_urgn.AddRect(dfm_fixed);
  vd.UpdateIncremental(dfm_DstStride, dfm_urgn, dfm_ImgLine0);

  Result := dfm_urgn.CaptureRgnNormal(vd, dfm_DstStride, dfm_ImgLine0);
  with Result.newRecord('res') do
  begin
    asInteger['Width'] := m_BackBm.Width;
    asInteger['Height'] := m_BackBm.Height;
    asInteger['Bits'] := vd.BitsPerPixel;
    asInteger['Bytes'] := vd.BytesPerPixel;
  end;
end;

function TRtcScreenCapture.GrabImageOldScreen: TRtcRecord;
var
  urgn: TGridUpdRegion;
begin
  urgn := TGridUpdRegion.Create;
  urgn.SetScrRect(dfm_fixed);
  urgn.StartAdd;
  urgn.AddRect(dfm_fixed);

  Result := urgn.CaptureRgnOld(vd, dfm_DstStride, dfm_ImgLine0);
  with Result.newRecord('res') do
  begin
    asInteger['Width'] := m_BackBm.Width;
    asInteger['Height'] := m_BackBm.Height;
    asInteger['Bits'] := vd.BitsPerPixel;
    asInteger['Bytes'] := vd.BytesPerPixel;
  end;

  urgn.Free;
end;

{$ELSE}

function TRtcScreenCapture.GetMirageDriver: boolean;
begin
  Result := False;
end;

procedure TRtcScreenCapture.SetMirageDriver(const Value: boolean);
begin
  // Mirage Driver not supported
end;

{$ENDIF}

{function TCursorInfoThread.GetCursorInfoWithAttach: TCursorInfo;
var
 hWindow: HWND;
 pt: TPoint;
 dwThreadID, dwCurrentThreadID: DWORD;
begin
 Result.hCursor := 0;
 ZeroMemory(@Result, SizeOf(Result));
 Result.cbSize := SizeOf(TCursorInfo);
 // Find out which window owns the cursor
 if GetCursorPos(pt) then
 begin
   Result.ptScreenPos := pt;
   hWindow := WindowFromPoint(pt);
   if IsWindow(hWindow) then
   begin
     // Get the thread ID for the cursor owner.
     dwThreadID := GetWindowThreadProcessId(hWindow, nil);

     // Get the thread ID for the current thread
     dwCurrentThreadID := GetCurrentThreadId;

     // If the cursor owner is not us then we must attach to
     // the other thread in so that we can use GetCursor() to
     // return the correct hCursor
     if (dwCurrentThreadID <> dwThreadID) then
     begin
       if AttachThreadInput(dwCurrentThreadID, dwThreadID, True) then
       begin
         // Get the handle to the cursor
         Result.hCursor := GetCursor;
         AttachThreadInput(dwCurrentThreadID, dwThreadID, False);
       end;
     end
     else
     begin
       Result.hCursor := GetCursor;
     end;
   end;
 end;
end;

function TRtcScreenCapture.GetCursorInfoFromThread: TCursorInfo;
begin
  ResetEvent(hCursorInfoEventWriteEnd);
  SetEvent(hCursorInfoEventWriteBegin);
  WaitForSingleObject(hCursorInfoEventWriteEnd, INFINITE);
  Result := tCursorInfoThrd.ci;
end;}

procedure TRtcScreenCapture.GrabMouse;
var
  ci: TCursorInfo;
//  pci: PCursorInfo;
  icinfo: TIconInfo;
  pt: TPoint;
  i: integer;
  r: LongBool;
begin
  if IsService then
  begin
    ci.flags := FHelper_mouseFlags;
    ci.hCursor := FHelper_mouseCursor;
    ci.ptScreenPos.X := FHelper_mouseX;
    ci.ptScreenPos.Y := FHelper_mouseY;
  end
  else
  begin
    ZeroMemory(@ci, SizeOf(TCursorInfo));
    ci.cbSize := SizeOf(TCursorInfo);
    ci.hCursor := 0;
    r := GetCursorInfo(ci);
  end;
//  i := GetLastError;

//  New(pci);
//  ZeroMemory(pci, SizeOf(TCursorInfo));
//  pci^.cbSize := SizeOf(TCursorInfo);
//  pci^.hCursor := 0;
//  r := GetCursorInfo2(pci);
//  ci.hCursor := GetCursor;

//    ci := GetCursorInfoFromThread;

//  New(ci);
//  ZeroMemory(ci, SizeOf(TCursorInfo));
//  ci^.cbSize := SizeOf(TCursorInfo);
//  r := GetCursorInfo2(ci);
//  if Get_CursorInfo(ci) then
//  ci^ := GetCursorInfoWithAttach;
//  i := GetLastError;
//  if r then
  begin
//    if ci.flags = CURSOR_SHOWING then
//    begin
      FMouseVisible := True;
      if FMouseInit or (ci.ptScreenPos.X <> FMouseX) or
        (ci.ptScreenPos.Y <> FMouseY) then
      begin
        FMouseMoved := True;
        FMouseX := ci.ptScreenPos.X;
        FMouseY := ci.ptScreenPos.Y;

        if (FLastMouseUser <> '') and (FMouseX = FLastMouseX) and
          (FMouseY = FLastMouseY) then
          FMouseUser := FLastMouseUser
        else
          FMouseUser := '';
      end;
      if FMouseInit or (ci.hCursor <> FMouseHandle) then
      begin
        FMouseChangedShape := True;
        FMouseHandle := ci.hCursor;
        if assigned(FMouseIcon) then
        begin
          FMouseIcon.Free;
          FMouseIcon := nil;
        end;
        if assigned(FMouseIconMask) then
        begin
          FMouseIconMask.Free;
          FMouseIconMask := nil;
        end;
        FMouseShape := 1;
        for i := crSizeAll to crDefault do
          if ci.hCursor = Screen.Cursors[i] then
          begin
            FMouseShape := i;
            Break;
          end;
        if FMouseShape = 1 then
        begin
          // send cursor image only for non-standard shapes
          if GetIconInfo(ci.hCursor, icinfo) then
          begin
            FMouseHotX := icinfo.xHotspot;
            FMouseHotY := icinfo.yHotspot;

            if icinfo.hbmMask <> INVALID_HANDLE_VALUE then
            begin
              FMouseIconMask := TBitmap.Create;
              FMouseIconMask.Handle := icinfo.hbmMask;
              FMouseIconMask.PixelFormat := pf4bit;
            end;

            if icinfo.hbmColor <> INVALID_HANDLE_VALUE then
            begin
              FMouseIcon := TBitmap.Create;
              FMouseIcon.Handle := icinfo.hbmColor;
              case FBPPLimit of
                0:
                  if FMouseIcon.PixelFormat > pf4bit then
                    FMouseIcon.PixelFormat := pf4bit;
                1:
                  if FMouseIcon.PixelFormat > pf8bit then
                    FMouseIcon.PixelFormat := pf8bit;
                2:
                  if FMouseIcon.PixelFormat > pf16bit then
                    FMouseIcon.PixelFormat := pf16bit;
              end;
            end;
          end;
        end;
      end;
      FMouseInit := False;
    end;
{    else
      FMouseVisible := False;
  end
  else if GetCursorPos(pt) then
  begin
    FMouseVisible := True;
    if FMouseInit or (pt.X <> FMouseX) or (pt.Y <> FMouseY) then
    begin
      FMouseMoved := True;
      FMouseX := pt.X;
      FMouseY := pt.Y;
      if (FLastMouseUser <> '') and (FMouseX = FLastMouseX) and
        (FMouseY = FLastMouseY) then
        FMouseUser := FLastMouseUser
      else
        FMouseUser := '';
    end;
    FMouseInit := False;
  end
  else
    FMouseVisible := False;}
//  Dispose(pci);
end;

function TRtcScreenCapture.GetMouseDelta: RtcString;
var
  rec: TRtcRecord;
begin
  if FMouseMoved or FMouseChangedShape or (FMouseLastVisible <> FMouseVisible)
  then
  begin
    rec := TRtcRecord.Create;
    try
      if FMouseLastVisible <> FMouseVisible then
        rec.asBoolean['V'] := FMouseVisible;
      if FMouseMoved then
      begin
        rec.asInteger['X'] := FMouseX - FCaptureLeft;
        rec.asInteger['Y'] := FMouseY - FCaptureTop;
        if FMouseUser <> '' then
          rec.asText['U'] := FMouseUser;
      end;
      if FMouseChangedShape then
      begin
        if FMouseShape <= 0 then
          rec.asInteger['C'] := -FMouseShape // 0 .. -22  ->>  0 .. 22
        else
        begin
          rec.asInteger['HX'] := FMouseHotX;
          rec.asInteger['HY'] := FMouseHotY;
          if FMouseIcon <> nil then
            FMouseIcon.SaveToStream(rec.newByteStream('I'));
          if FMouseIconMask <> nil then
            FMouseIconMask.SaveToStream(rec.newByteStream('M'));
        end;
      end;
      Result := rec.toCode;
    finally
      rec.Free;
    end;
    FMouseMoved := False;
    FMouseChangedShape := False;
    FMouseLastVisible := FMouseVisible;
  end;
end;

function TRtcScreenCapture.GetMouse: RtcString;
begin
  FMouseChangedShape := True;
  FMouseMoved := True;
  FMouseLastVisible := not FMouseVisible;
  Result := GetMouseDelta;
end;

function IsMyHandle(a: HWND): TForm;
var
  i, cnt: integer;
begin
  Result := nil;
  cnt := Screen.FormCount;
  for i := 0 to cnt - 1 do
    if Screen.Forms[i].Handle = a then
    begin
      Result := Screen.Forms[i];
      Break;
    end;
end;

{function GetWindowParent(h: HWND): HWND;
begin
  Result := h;
  while True do
  begin
    if GetParent(Result) <> 0 then
      Result := GetParent(Result)
    else
      Exit;
  end;
end;}

function okToClick(X, Y: integer): boolean;
var
  P: TPoint;
  W: HWND;
  hit: integer;
begin
  P.X := X;
  P.Y := Y;
//  W := GetWindowParent(WindowFromPoint(P));
  W := WindowFromPoint(P);
  if IsMyHandle(W) <> nil then
  begin
    hit := SendMessage(W, WM_NCHITTEST, 0, P.X + (P.Y shl 16));
    Result := not(hit in [HTCLOSE, HTMAXBUTTON, HTMINBUTTON]);

//    case hit of
//      HTCLOSE:
//        SendMessage(W, WM_SYSCOMMAND, SC_CLOSE, MakeLong(X, Y));
//      HTMAXBUTTON:
//        SendMessage(W, WM_SYSCOMMAND, SC_MAXIMIZE, MakeLong(X, Y));
//      HTMINBUTTON:
//        SendMessage(W, WM_SYSCOMMAND, SC_MINIMIZE, MakeLong(X, Y));
//    end;
  end
  else
    Result := True;
end;

function okToUnClick(X, Y: integer): boolean;
var
  P: TPoint;
  W: HWND;
  hit: integer;
  frm: TForm;
begin
  P.X := X;
  P.Y := Y;
//  W := GetWindowParent(WindowFromPoint(P));
  W := WindowFromPoint(P);
  frm := IsMyHandle(W);
  if assigned(frm) then
  begin
    hit := SendMessage(W, WM_NCHITTEST, 0, P.X + (P.Y shl 16));
    Result := not(hit in [HTCLOSE, HTMAXBUTTON, HTMINBUTTON]);
    if not Result then
    begin
      case hit of
        HTCLOSE:
          PostMessage(W, WM_SYSCOMMAND, SC_CLOSE, 0);
        HTMINBUTTON:
          PostMessage(W, WM_SYSCOMMAND, SC_MINIMIZE, 0);
        HTMAXBUTTON:
          if frm.WindowState = wsMaximized then
            PostMessage(W, WM_SYSCOMMAND, SC_RESTORE, 0)
          else
            PostMessage(W, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
      end;
    end;
  end
  else
    Result := True;
end;

{function GetChildWindowFromPoint(MouseX, MouseY: Integer): HWND;
var
  hdl, chdl: HWND;
  wpt, pt: TPoint;
  r: TRect;
begin
  pt.X := MouseX;
  pt.Y := MouseY;
  wpt := pt;
  if RtcMouseWindowHdl = 0 then
    hdl := WindowFromPoint(pt)
  else
  begin
    hdl := RtcMouseWindowHdl;
    if IsWindow(hdl) then
    begin
      GetWindowRect(hdl, r);
      repeat
        pt.X := wpt.X - r.Left;
        pt.Y := wpt.Y - r.Top;
        chdl := ChildWindowFromPointEx(hdl, pt, 1 + 4);
        if not IsWindow(chdl) then
          Break
        else if chdl = hdl then
          Break
        else
        begin
          GetWindowRect(chdl, r);
          if (wpt.x >= r.left) and (wpt.x <= r.right) and
             (wpt.y >= r.top) and (wpt.y <= r.bottom) then
            hdl := chdl
          else
            Break;
        end;
      until False;
    end;
  end;
  Result := hdl;
end;}

procedure TRtcScreenCapture.Post_MouseDown(Button: TMouseButton);
var
  inputs: array[0..0] of TInput;
  p: TPoint;
  dwFlags: DWORD;
begin
  SwitchToActiveDesktop;

//{$IFDEF KMDriver}
//  MessageBox(0, 'KMDriver defined', '', SW_SHOW);
//{$ENDIF}
{$IFDEF KMDriver}
  if FMouseDriver and (FMouseAInit > 0) then
  begin
    case Button of
      mbLeft:
        MouseAInf.MouseAImitationLButtonDown;
      mbRight:
        MouseAInf.MouseAImitationRButtonDown;
      mbMiddle:
      begin
        ZeroMemory(@inputs, SizeOf(TInput));
        inputs[0].Itype := INPUT_MOUSE;
        inputs[0].mi.dwFlags := MOUSEEVENTF_MIDDLEDOWN;
        inputs[0].mi.dx := FLastMouseX;
        inputs[0].mi.dy := FLastMouseY;
        inputs[0].mi.mouseData := 0;
        inputs[0].mi.dwExtraInfo := RMX_MAGIC_NUMBER;
        SendInput(1, inputs[0], SizeOf(inputs));
//        mouse_event(MOUSEEVENTF_MIDDLEDOWN, 0, 0, 0, 0);
      end;
    end;
  end
  else
{$ENDIF}
  begin
    case Button of
      mbLeft:
        dwFlags := MOUSEEVENTF_LEFTDOWN;
      mbRight:
        dwFlags := MOUSEEVENTF_RIGHTDOWN;
      mbMiddle:
        dwFlags := MOUSEEVENTF_MIDDLEDOWN;
    end;

    if not NeedSendIOToHelper then
    begin
  //        mouse_event(dwFlags, 0, 0, 0, 0);

        ZeroMemory(@inputs, SizeOf(TInput));
        inputs[0].Itype := INPUT_MOUSE;
        inputs[0].mi.dwFlags := dwFlags;
        inputs[0].mi.dx := FLastMouseX;
        inputs[0].mi.dy := FLastMouseY;
        inputs[0].mi.mouseData := 0;
        inputs[0].mi.dwExtraInfo := RMX_MAGIC_NUMBER;
        SendInput(1, inputs[0], SizeOf(inputs));
    end
    else
      SendIOToHelperByIPC(QT_SENDINPUT, INPUT_MOUSE, dwFlags, FLastMouseX, FLastMouseY, 0, 0, 0, '');
  end;

//    GetCursorPos(p);
//    case Button of
//      mbLeft: PostMessage(GetChildWindowFromPoint(p.X, p.Y), WM_LBUTTONDOWN, 0, MAKELPARAM(p.X, p.Y));
//      mbRight: PostMessage(GetChildWindowFromPoint(p.X, p.Y), WM_RBUTTONDOWN, 0, MAKELPARAM(p.X, p.Y));
//      mbMiddle: PostMessage(GetChildWindowFromPoint(p.X, p.Y), WM_MBUTTONDOWN, 0, MAKELPARAM(p.X, p.Y));
//    end;
//  end;
end;

function NeedSendIOToHelper: Boolean;
begin
  if IsService then
    Result := True
  else
  if IsServiceStarted(RTC_HOSTSERVICE_NAME) then
    Result := True
  else
    Result := (LowerCase(GetInputDesktopName) <> 'default')
end;

procedure TRtcScreenCapture.Post_MouseUp(Button: TMouseButton);
var
  inputs: array[0..0] of TInput;
  p: TPoint;
  dwFlags: DWORD;
begin
  SwitchToActiveDesktop;

{$IFDEF KMDriver}
  if FMouseDriver and (FMouseAInit > 0) then
  begin
    case Button of
      mbLeft:
        MouseAInf.MouseAImitationLButtonUp;
      mbRight:
        MouseAInf.MouseAImitationRButtonUp;
      mbMiddle:
      begin
        ZeroMemory(@inputs, SizeOf(TInput));
        inputs[0].Itype := INPUT_MOUSE;
        inputs[0].mi.dwFlags := MOUSEEVENTF_MIDDLEUP;
        inputs[0].mi.dx := 0;
        inputs[0].mi.dy := 0;
        inputs[0].mi.mouseData := 0;
        inputs[0].mi.dwExtraInfo := RMX_MAGIC_NUMBER;
        SendInput(1, inputs[0], SizeOf(inputs));

//        mouse_event(MOUSEEVENTF_MIDDLEUP, 0, 0, 0, 0);
      end;
    end;
  end
  else
{$ENDIF}
  begin
    case Button of
      mbLeft:
        dwFlags := MOUSEEVENTF_LEFTUP;
      mbRight:
        dwFlags := MOUSEEVENTF_RIGHTUP;
      mbMiddle:
        dwFlags := MOUSEEVENTF_MIDDLEUP;
    end;

    if not NeedSendIOToHelper then
    begin//  mouse_event(dwFlags, 0, 0, 0, 0);7

      ZeroMemory(@inputs, SizeOf(TInput));
      inputs[0].Itype := INPUT_MOUSE;
      inputs[0].mi.dwFlags := dwFlags;
      inputs[0].mi.dx := 0;
      inputs[0].mi.dy := 0;
      inputs[0].mi.mouseData := 0;
      inputs[0].mi.dwExtraInfo := RMX_MAGIC_NUMBER;
      SendInput(1, inputs[0], SizeOf(inputs));
    end
    else
      SendIOToHelperByIPC(QT_SENDINPUT, INPUT_MOUSE, dwFlags, 0, 0, 0, 0, 0, '');
  end;
//    GetCursorPos(p);
//    if Button in [mbLeft, mbRight] then
//      if GetSystemMetrics(SM_SWAPBUTTON) <> 0 then
//        case Button of
//          mbLeft:
//            Button := mbRight;
//          mbRight:
//            Button := mbLeft;
//        end;
//    case Button of
//      mbLeft: PostMessage(WindowFromPoint(p), WM_LBUTTONUP, 0, MAKELPARAM(p.X, p.Y));
//      mbRight: PostMessage(WindowFromPoint(p), WM_RBUTTONUP, 0, MAKELPARAM(p.X, p.Y));
//      mbMiddle: PostMessage(WindowFromPoint(p), WM_MBUTTONUP, 0, MAKELPARAM(p.X, p.Y));
//    end;
//  end;
end;

procedure TRtcScreenCapture.Post_MouseWheel(Wheel: integer);
var
  inputs: array[0..0] of TInput;
begin
  SwitchToActiveDesktop;

  if not NeedSendIOToHelper then
  begin
    ZeroMemory(@inputs, SizeOf(TInput));
    inputs[0].Itype := INPUT_MOUSE;
    inputs[0].mi.dwFlags := MOUSEEVENTF_WHEEL;
    inputs[0].mi.dx := 0;
    inputs[0].mi.dy := 0;
    inputs[0].mi.mouseData := DWORD(Wheel);
    inputs[0].mi.dwExtraInfo := RMX_MAGIC_NUMBER;
    SendInput(1, inputs[0], SizeOf(inputs));
//    mouse_event(MOUSEEVENTF_WHEEL, 0, 0, DWORD(Wheel), 0);
  end
  else
    SendIOToHelperByIPC(QT_SENDINPUT, INPUT_MOUSE, MOUSEEVENTF_WHEEL, 0, 0, Wheel, 0, 0, '');
end;

procedure TRtcScreenCapture.Post_MouseMove(X, Y: integer);
var
  inputs: array[0..0] of TInput;
begin
  SwitchToActiveDesktop;

{$IFDEF KMDriver}
  if FMouseDriver and (FMouseAInit > 0) then
  begin
    if (X > Screen.DesktopRect.Right) or (X < Screen.DesktopRect.Left) or
      (Y > Screen.DesktopRect.Bottom) or (Y < Screen.DesktopRect.Top) then
      Exit;

    if ScreenWidth > 0 then
    begin
      MouseAInf.MouseAImitationMove(mfMOUSE_MOVE_ABSOLUTE,
        MouseAInf.MouseXYToScreen(Point(X, Y)));
    end
    else
      SetCursorPos(X, Y);
  end
  else
{$ENDIF}
  begin
    if not NeedSendIOToHelper then
    begin
      if ScreenWidth > 0 then
      begin
        X := round(X / (Screen.Width - 1) * 65535);
        Y := round(Y / (Screen.Height - 1) * 65535);


        ZeroMemory(@inputs, SizeOf(TInput));
        inputs[0].Itype := INPUT_MOUSE;
        inputs[0].mi.dwFlags := MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE;
        inputs[0].mi.dx := X;
        inputs[0].mi.dy := Y;
        inputs[0].mi.mouseData := 0;
        inputs[0].mi.dwExtraInfo := RMX_MAGIC_NUMBER;
        SendInput(1, inputs[0], SizeOf(inputs));

        //mouse_event(MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE, X, Y, 0, 0);
      end
      else
      begin
        SetCursorPos(X, Y);

  //    if GetKeyState(VK_LBUTTON) < 0 then
  //      State := State + MK_LBUTTON;
  //    if GetKeyState(VK_MBUTTON) < 0 then
  //      State := State + MK_MBUTTON;
  //    if GetKeyState(VK_RBUTTON) < 0 then
  //      State := State + MK_RBUTTON;
  //  PostMouseMessage(WM_MOUSEMOVE, X, Y);
      end
    end
    else
      SendIOToHelperByIPC(QT_SENDINPUT, INPUT_MOUSE, MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE, X, Y, 0, 0, 0, '');
  end;
end;

{procedure PostMouseMessage(Msg:Cardinal; MouseX, MouseY: integer);
  var
    hdl,chdl:HWND;
    wpt,pt:TPoint;
    r:TRect;
  begin
  pt.X:=MouseX;
  pt.Y:=MouseY;
  wpt:=pt;
  if RtcMouseWindowHdl=0 then
    hdl:=WindowFromPoint(pt)
  else
    begin
    hdl:=RtcMouseWindowHdl;
    if IsWindow(hdl) then
      begin
      GetWindowRect(hdl,r);
      repeat
        pt.X:=wpt.X-r.Left;
        pt.Y:=wpt.Y-r.Top;
        chdl:=ChildWindowFromPointEx(hdl,pt,1+4);
        if not IsWindow(chdl) then
          Break
        else if chdl=hdl then
          Break
        else
          begin
          GetWindowRect(chdl,r);
          if (wpt.x>=r.left) and (wpt.x<=r.right) and
             (wpt.y>=r.top) and (wpt.y<=r.bottom) then
            hdl:=chdl
          else
            Break;
          end;
        until False;
      end;
    end;
  if IsWindow(hdl) then
    begin
    GetWindowRect(hdl,r);
    pt.x:=wpt.X-r.left;
    pt.y:=wpt.Y-r.Top;
    PostMessage(hdl,msg,0,MakeLong(pt.X,pt.Y));
    end;
  end;}

procedure TRtcScreenCapture.MouseDown(const user: string; X, Y: integer;
  Button: TMouseButton);
var
//  pt: TPoint;
  h: HWND;
begin
  FLastMouseUser := user;
  FLastMouseX := X + FCaptureLeft;
  FLastMouseY := Y + FCaptureTop;

  if Button in [mbLeft, mbRight] then
    if GetSystemMetrics(SM_SWAPBUTTON) <> 0 then
      case Button of
        mbLeft:
          Button := mbRight;
        mbRight:
          Button := mbLeft;
      end;

  if RtcMouseControlMode=eventMouseControl then
  begin
    Post_MouseMove(FLastMouseX, FLastMouseY);
    if Button <> mbLeft then
      Post_MouseDown(Button)
    else
    if okToClick(FLastMouseX, FLastMouseY) then
      Post_MouseDown(Button);
  end
  else
  begin
//    SimulateKBM.MoveMouse(Point(FLastMouseX, FLastMouseY));
//    SimulateKBM.MouseDownXY(FLastMouseX, FLastMouseY);
//    //h := GetChildWindowFromPoint(FLastMouseX, FLastMouseY);
//    h := WindowFromPoint(Point(FLastMouseX, FLastMouseY));
////    Post_MessageMouseMove(FLastMouseX, FLastMouseY);
////    if GetActiveWindow <> h then
////      SetActiveWindow(h);
////    PostMessage(WindowFromPoint(pt), WM_ACTIVATE, WA_CLICKACTIVE, GetActiveWindow);
////    case Button of
////      mbLeft: PostMouseMessage(WM_LBUTTONDOWN,FLastMouseX,FLastMouseY);
////      mbRight: PostMouseMessage(WM_RBUTTONDOWN,FLastMouseX,FLastMouseY);
////      mbMiddle: PostMouseMessage(WM_MBUTTONDOWN,FLastMouseX,FLastMouseY);
////    end;
//
//    if Button <> mbLeft then
//      case Button of
//        mbLeft: PostMessage(h, WM_LBUTTONDOWN, MK_LBUTTON, MAKELONG(FLastMouseX, FLastMouseY));
//        mbRight: PostMessage(h, WM_RBUTTONDOWN, MK_RBUTTON, MAKELONG(FLastMouseX, FLastMouseY));
//        mbMiddle: PostMessage(h, WM_MBUTTONDOWN, MK_MBUTTON, MAKELONG(FLastMouseX, FLastMouseY));
//      end
//    else if okToClick(FLastMouseX, FLastMouseY) then
//      case Button of
//        mbLeft: PostMessage(h, WM_LBUTTONDOWN, MK_LBUTTON, MAKELONG(FLastMouseX, FLastMouseY));
//        mbRight: PostMessage(h, WM_RBUTTONDOWN, MK_RBUTTON, MAKELONG(FLastMouseX, FLastMouseY));
//        mbMiddle: PostMessage(h, WM_MBUTTONDOWN, MK_MBUTTON, MAKELONG(FLastMouseX, FLastMouseY));
//      end
  end;
end;

procedure TRtcScreenCapture.MouseUp(const user: string; X, Y: integer;
  Button: TMouseButton);
var
  pt: TPoint;
  h: HWND;
begin
  FLastMouseUser := user;
  FLastMouseX := X + FCaptureLeft;
  FLastMouseY := Y + FCaptureTop;

  if Button in [mbLeft, mbRight] then
    if GetSystemMetrics(SM_SWAPBUTTON) <> 0 then
      case Button of
        mbLeft:
          Button := mbRight;
        mbRight:
          Button := mbLeft;
      end;

  if RtcMouseControlMode=eventMouseControl then
    begin
    Post_MouseMove(FLastMouseX, FLastMouseY);
    if Button <> mbLeft then
      Post_MouseUp(Button)
    else if okToUnClick(FLastMouseX, FLastMouseY) then
      Post_MouseUp(Button);
    end
  else
  begin
//    SimulateKBM.MoveMouse(Point(FLastMouseX, FLastMouseY));
//    SimulateKBM.MouseUpXY(FLastMouseX, FLastMouseY);
////    h := GetChildWindowFromPoint(FLastMouseX, FLastMouseY);
//    h := WindowFromPoint(Point(FLastMouseX, FLastMouseY));
////    Post_MessageMouseMove(FLastMouseX, FLastMouseY);
////    case Button of
////      mbLeft: PostMouseMessage(WM_LBUTTONUP,FLastMouseX,FLastMouseY);
////      mbRight: PostMouseMessage(WM_RBUTTONUP,FLastMouseX,FLastMouseY);
////      mbMiddle: PostMouseMessage(WM_MBUTTONUP,FLastMouseX,FLastMouseY);
////    end;
//    if Button <> mbLeft then
//      case Button of
//        mbLeft: PostMessage(h, WM_LBUTTONUP, 0, MAKELONG(FLastMouseX, FLastMouseY));
//        mbRight: PostMessage(h, WM_RBUTTONUP, 0, MAKELONG(FLastMouseX, FLastMouseY));
//        mbMiddle: PostMessage(h, WM_MBUTTONUP, 0, MAKELONG(FLastMouseX, FLastMouseY));
//      end
//    else if okToUnClick(FLastMouseX, FLastMouseY) then
//      case Button of
//        mbLeft: PostMessage(h, WM_LBUTTONUP, 0, MAKELONG(FLastMouseX, FLastMouseY));
//        mbRight: PostMessage(h, WM_RBUTTONUP, 0, MAKELONG(FLastMouseX, FLastMouseY));
//        mbMiddle: PostMessage(h, WM_MBUTTONUP, 0, MAKELONG(FLastMouseX, FLastMouseY));
//      end
  end;
end;

procedure TRtcScreenCapture.MouseMove(const user: String; X, Y: integer);
begin
  if RtcMouseControlMode=eventMouseControl then
  begin
    FLastMouseUser := user;
    FLastMouseX := X + FCaptureLeft;
    FLastMouseY := Y + FCaptureTop;

    Post_MouseMove(FLastMouseX, FLastMouseY);
  end
  else
  begin
    FLastMouseUser := user;
    FLastMouseX := X + FCaptureLeft;
    FLastMouseY := Y + FCaptureTop;

//    SimulateKBM.MoveMouse(Point(FLastMouseX, FLastMouseY));

    //Post_MessageMouseMove(FLastMouseX, FLastMouseY);
  end;
end;

procedure TRtcScreenCapture.MouseWheel(Wheel: integer);
begin
  if RtcMouseControlMode=eventMouseControl then
    Post_MouseWheel(Wheel);
end;

procedure TRtcScreenCapture.keybdevent(key: word; Down: boolean = True; Extended: boolean=False);
var
  vk: integer;
  inputs: array[0..0] of TInput;
  dwFlags: DWORD;
begin
  vk := MapVirtualKey(key, 0);
  dwFlags := 0;
  if not Down then dwFlags := dwFlags or KEYEVENTF_KEYUP;
  if Extended then dwFlags := dwFlags or KEYEVENTF_EXTENDEDKEY;
//  keybd_event(key, vk, dwFlags, 0);

  if not NeedSendIOToHelper then
  begin
    ZeroMemory(@inputs, SizeOf(TInput));
    inputs[0].Itype := INPUT_KEYBOARD;
    inputs[0].ki.dwFlags := dwFlags;
    inputs[0].ki.wVk := key;
    inputs[0].ki.wScan := vk;
    inputs[0].ki.dwExtraInfo := RMX_MAGIC_NUMBER;

    SendInput(1, inputs[0], SizeOf(inputs));
  end
  else
    SendIOToHelperByIPC(QT_SENDINPUT, INPUT_KEYBOARD, dwFlags, 0, 0, 0, key, vk, '');
end;

//procedure TRtcScreenCapture.keybdevent(key: word; Down: boolean = True);
//var
//  vk: integer;
//begin
//  vk := MapVirtualKey(key, 0);
//  if Down then
//    keybd_event(key, vk, 0, 0)
//  else
//    keybd_event(key, vk, KEYEVENTF_KEYUP, 0);
//end;

procedure TRtcScreenCapture.KeyDown(key: word; Shift: TShiftState);
var
  inputs: array[0..0] of TInput;
begin
  case key of
    VK_SHIFT:
      if FShiftDown then
        Exit
      else
        FShiftDown := True;
    VK_CONTROL:
      if FCtrlDown then
        Exit
      else
        FCtrlDown := True;
    VK_MENU:
      if FAltDown then
        Exit
      else
        FAltDown := True;
  end;

  keybdevent(key, True, (Key >= $21) and (Key <= $2E));
end;

procedure TRtcScreenCapture.KeyUp(key: word; Shift: TShiftState);
begin
  case key of
    VK_SHIFT:
      if not FShiftDown then
        Exit
      else
        FShiftDown := False;
    VK_CONTROL:
      if not FCtrlDown then
        Exit
      else
        FCtrlDown := False;
    VK_MENU:
      if not FAltDown then
        Exit
      else
        FAltDown := False;
  end;

  keybdevent(key, False, (key >= $21) and (key <= $2E));
end;

procedure TRtcScreenCapture.SetKeys(capslock, lWithShift, lWithCtrl,
  lWithAlt: boolean);
begin
  if capslock then
  begin
    // turn CAPS LOCK off
    keybdevent(VK_CAPITAL);
    keybdevent(VK_CAPITAL, False);
  end;

  if lWithShift <> FShiftDown then
    keybdevent(VK_SHIFT, lWithShift);

  if lWithCtrl <> FCtrlDown then
    keybdevent(VK_CONTROL, lWithCtrl);

  if lWithAlt <> FAltDown then
    keybdevent(VK_MENU, lWithAlt);
end;

procedure TRtcScreenCapture.ResetKeys(capslock, lWithShift, lWithCtrl,
  lWithAlt: boolean);
begin
  if lWithAlt <> FAltDown then
    keybdevent(VK_MENU, FAltDown);

  if lWithCtrl <> FCtrlDown then
    keybdevent(VK_CONTROL, FCtrlDown);

  if lWithShift <> FShiftDown then
    keybdevent(VK_SHIFT, FShiftDown);

  if capslock then
  begin
    // turn CAPS LOCK on
    keybdevent(VK_CAPITAL);
    keybdevent(VK_CAPITAL, False);
  end;
end;

{procedure TRtcScreenCapture.KeyPress(const AText: RtcString; AKey: word);
var
  a: integer;
  lScanCode: Smallint;
  lWithAlt, lWithCtrl, lWithShift: boolean;
  capslock: boolean;
begin
  for a := 1 to length(AText) do
  begin
{$IFDEF RTC_BYTESTRING}
{    lScanCode := VkKeyScanA(AText[a]);
{$ELSE}
{    lScanCode := VkKeyScanW(AText[a]);
{$ENDIF}
{    if lScanCode = -1 then
    begin
      if not (AKey in [VK_MENU, VK_SHIFT, VK_CONTROL, VK_CAPITAL, VK_NUMLOCK])
      then
      begin
        keybdevent(AKey);
        keybdevent(AKey, False);
      end;
    end
    else
    begin
      lWithShift := lScanCode and $100 <> 0;
      lWithCtrl := lScanCode and $200 <> 0;
      lWithAlt := lScanCode and $400 <> 0;

      lScanCode := lScanCode and $F8FF;
      // remove Shift, Ctrl and Alt from the scan code

      capslock := GetKeyState(VK_CAPITAL) > 0;

      SetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);

      keybdevent(lScanCode);
      keybdevent(lScanCode, False);

      ResetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);
    end;
  end;
end;}

procedure TRtcScreenCapture.KeyPressW(const AText: WideString; AKey: word);
var
  a: integer;
  lScanCode: Smallint;
  lWithAlt, lWithCtrl, lWithShift: boolean;
  capslock: boolean;
begin
  for a := 1 to length(AText) do
  begin
    lScanCode := VkKeyScanW(AText[a]);

    if lScanCode = -1 then
    begin
      if not (AKey in [VK_MENU, VK_SHIFT, VK_CONTROL, VK_CAPITAL, VK_NUMLOCK])
      then
      begin
        keybdevent(AKey);
        keybdevent(AKey, False);
      end;
    end
    else
    begin
      lWithShift := lScanCode and $100 <> 0;
      lWithCtrl := lScanCode and $200 <> 0;
      lWithAlt := lScanCode and $400 <> 0;

      lScanCode := lScanCode and $F8FF;
      // remove Shift, Ctrl and Alt from the scan code

      capslock := GetKeyState(VK_CAPITAL) > 0;

      SetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);

      keybdevent(lScanCode);
      keybdevent(lScanCode, False);

      ResetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);
    end;
  end;
end;

procedure TRtcScreenCapture.LWinKey(key: word);
begin
  SetKeys(False, False, False, False);
  keybdevent(VK_LWIN);
  keybdevent(key);
  keybdevent(key, False);
  keybdevent(VK_LWIN, False);
  ResetKeys(False, False, False, False);
end;

procedure TRtcScreenCapture.RWinKey(key: word);
begin
  SetKeys(False, False, False, False);
  keybdevent(VK_RWIN);
  keybdevent(key);
  keybdevent(key, False);
  keybdevent(VK_RWIN, False);
  ResetKeys(False, False, False, False);
end;

{function TRtcScreenCapture.DoElevatedTask(const Host, AParameters: String): Cardinal;
begin
  ShellExecute(0, 'open', PWideChar(Host), PWideChar(AParameters), nil, SW_MINIMIZE);

  Result := ERROR_SUCCESS;
end;}

procedure TRtcScreenCapture.SpecialKey(const AKey: RtcString);
var
  capslock: Boolean;
  err: Integer;
  res: Boolean;
  file_name1, file_name2, s: String;
begin
  capslock := GetKeyState(VK_CAPITAL) > 0;

  if AKey = 'CAD' then
  begin
    XLog('Simulate CAD');
//    ExecuteCtrlAltDel;
    SendIOToHelperByIPC(QT_SENDCAD, 0, 0, 0, 0, 0, 0, 0, '');
    // Ctrl+Alt+Del
{    if (Win32MajorVersion >= 6) then //vista\server 2k8
    begin
      if IsServiceStarted(RTC_HOSTSERVICE_NAME) then
        ExecuteCtrlAltDel
      else
      begin
        file_name1 := GetTempFile + '.exe'; //Доделать через SAS
        SaveResourceToFile('RUNASSYS', file_name1);

        file_name2 := GetTempFile + '.bat';
        s := file_name1 + ' "' + AppFileName + '" /CAD' + #13#10;
        s := s + 'DEL ' + file_name1 + #13#10;
        s := s + 'DEL ' + file_name2 + #13#10;
        s := s + 'PAUSE';
        Write_File(file_name2, s);
        ShellExecute(Application.Handle, 'open', PChar(file_name2), '', '', SW_HIDE);
      end;

//      EleavateSupport := TEleavateSupport.Create(DoElevatedTask);
//      SetLastError(EleavateSupport.RunElevated(file_name2, '', Application.Handle, Application.ProcessMessages));
//      err := GetLastError;
//      if err <> ERROR_SUCCESS then
//        XLog(SysErrorMessage(err));
    end
    else
      WinExec('taskmgr.exe', SW_SHOW);}

//    if UpperCase(Get_UserName) = 'SYSTEM' then
//    begin
//      XLog('Executing CtrlAltDel as SYSTEM user ...');
//      SetKeys(capslock, False, False, False);
//      if not Post_CtrlAltDel then
//        begin
//        XLog('CtrlAltDel execution failed as SYSTEM user');
//        if rtcGetProcessID(AppFileName) > 0 then
//          begin
//          XLog('Sending CtrlAltDel request to Host Service ...');
//          Write_File(ChangeFileExt(AppFileName, '.cad'), '');
//          end;
//        end
//      else
//        XLog('CtrlAltDel execution successful');
//      ResetKeys(capslock, False, False, False);
//    end
//    else
//    begin
//      if rtcGetProcessID(AppFileName) > 0 then
//        begin
//        XLog('Sending CtrlAltDel request to Host Service ...');
//        Write_File(ChangeFileExt(AppFileName, '.cad'), '');
//        end
//      else
//        begin
//        XLog('Emulating CtrlAltDel as "'+Get_UserName+'" user ...');
//        SetKeys(capslock, False, True, True);
//        keybdevent(VK_ESCAPE);
//        keybdevent(VK_ESCAPE, False);
//        ResetKeys(capslock, False, True, True);
//        end;
//    end;
  end
  else if AKey = 'COPY' then
  begin
    // Ctrl+C
    if IsService then
      SendIOToHelperByIPC(QT_SENDCOPY, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
      SetKeys(capslock, False, True, False);
      keybdevent(Ord('C'));
      keybdevent(Ord('C'), False);
      ResetKeys(capslock, False, True, False);
    end;
  end
  else if AKey = 'AT' then
  begin
    // Alt+Tab
    if IsService then
      SendIOToHelperByIPC(QT_SENDAT, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
      SetKeys(capslock, False, False, True);
      keybdevent(VK_TAB);
      keybdevent(VK_TAB, False);
      ResetKeys(capslock, False, False, True);
    end;
  end
  else if AKey = 'SAT' then
  begin
    // Shift+Alt+Tab
    if IsService then
      SendIOToHelperByIPC(QT_SENDSAT, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
      SetKeys(capslock, True, False, True);
      keybdevent(VK_TAB);
      keybdevent(VK_TAB, False);
      ResetKeys(capslock, True, False, True);
    end;
  end
  else if AKey = 'CAT' then
  begin
    // Ctrl+Alt+Tab
    if IsService then
      SendIOToHelperByIPC(QT_SENDCAT, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
      SetKeys(capslock, False, True, True);
      keybdevent(VK_TAB);
      keybdevent(VK_TAB, False);
      ResetKeys(capslock, False, True, True);
    end;
  end
  else if AKey = 'SCAT' then
  begin
    // Shift+Ctrl+Alt+Tab
    if IsService then
      SendIOToHelperByIPC(QT_SENDSCAT, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
      SetKeys(capslock, True, True, True);
      keybdevent(VK_TAB);
      keybdevent(VK_TAB, False);
      ResetKeys(capslock, True, True, True);
    end;
  end
  else if AKey = 'WIN' then
  begin
    // Windows
    if IsService then
      SendIOToHelperByIPC(QT_SENDWIN, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
      SetKeys(capslock, False, False, False);
      keybdevent(VK_LWIN);
      keybdevent(VK_LWIN, False);
      ResetKeys(capslock, False, False, False);
    end;
  end
  else if AKey = 'RWIN' then
  begin
    // Windows
    if IsService then
      SendIOToHelperByIPC(QT_SENDRWIN, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
      SetKeys(capslock, False, False, False);
      keybdevent(VK_RWIN);
      keybdevent(VK_RWIN, False);
      ResetKeys(capslock, False, False, False);
    end;
  end
  else if AKey = 'HDESK' then
  begin
    // Hide Wallpaper
    if IsService then
      SendIOToHelperByIPC(QT_SENDHDESK, 0, 0, 0, 0, 0, 0, 0, '')
    else
      Hide_Wallpaper;
  end
  else if AKey = 'SDESK' then
  begin
    // Show Wallpaper
    if IsService then
      SendIOToHelperByIPC(QT_SENDSDESK, 0, 0, 0, 0, 0, 0, 0, '')
    else
      Show_Wallpaper;
  end
  else if AKey = 'BKM' then
  begin
    // Block Keyboard and Mouse
    if IsService then
      SendIOToHelperByIPC(QT_SENDBKM, 0, 0, 0, 0, 0, 0, 0, '')
    else
      SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 0, 0);


//    file_name1 := GetTempFile + '.exe';
//    SaveResourceToFile('RUNASSYS', file_name1);
//
//    file_name2 := GetTempFile + '.bat';
//    s := file_name1 + ' "' + AppFileName + '" -DCAD' + #13#10;
//    s := s + 'DEL ' + file_name1 + #13#10;
//    s := s + 'DEL ' + file_name2 + #13#10;
//    s := s + 'PAUSE';
//    Write_File(file_name2, s);
//    ShellExecute(Application.Handle, 'open', PChar(file_name2), '', '', SW_HIDE);

    //Block_UserInput_Hook(True);

////    Block_UserInput(True);
//    EleavateSupport := TEleavateSupport.Create(DoElevatedTask);
//    SetLastError(EleavateSupport.RunElevated(AppFileName, '-BKM', Application.Handle, Application.ProcessMessages));
//    err := GetLastError;
//    if err <> ERROR_SUCCESS then
//      XLog(SysErrorMessage(err));
  end
  else if AKey = 'UBKM' then
  begin
    // UnBlock Keyboard and Mouse
    if IsService then
      SendIOToHelperByIPC(QT_SENDUBKM, 0, 0, 0, 0, 0, 0, 0, '')
    else
      SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 1, 0);

//    file_name1 := GetTempFile + '.exe';
//    SaveResourceToFile('RUNASSYS', file_name1);
//
//    file_name2 := GetTempFile + '.bat';
//    s := file_name1 + ' "' + AppFileName + '" -ECAD' + #13#10;
//    s := s + 'DEL ' + file_name1 + #13#10;
//    s := s + 'DEL ' + file_name2 + #13#10;
//    s := s + 'PAUSE';
//    Write_File(file_name2, s);
//    ShellExecute(Application.Handle, 'open', PChar(file_name2), '', '', SW_HIDE);

    //Block_UserInput_Hook(False);
////    Block_UserInput(False);
//    EleavateSupport := TEleavateSupport.Create(DoElevatedTask);
//    SetLastError(EleavateSupport.RunElevated(AppFileName, '-UBKM', Application.Handle, Application.ProcessMessages));
//    err := GetLastError;
//    if err <> ERROR_SUCCESS then
//      XLog(SysErrorMessage(err));
  end
  else if AKey = 'OFFMON' then
  begin
    // Power Off Monitor
    if IsService then
      SendIOToHelperByIPC(QT_SENDOFFMON, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
//    SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 0, 0);
//    SendMessage(MainFormHandle, WM_DRAG_FULL_WINDOWS_MESSAGE, 0, 0);
//    SetBlankMonitor(True);
      BlankOutScreen(True);
    end;


//    PostMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(2));
//    SendMessage(MainFormHandle, WM_ZORDER_MESSAGE, 0, 0);
//    Hide_Cursor;

//    ThreadHandle2 := CreateThread(nil, 0, @BlackWindow, nil, 0, &dwTId);
//    if ThreadHandle2 <> 0 then
//      CloseHandle(ThreadHandle2);
//    m_Black_window_active := True;

//    SetProcessShutdownParameters($100, 0);
//    res := SystemParametersInfo(SPI_GETPOWEROFFTIMEOUT, 0, @m_OldPowerOffTimeout, 0);
//    res := SystemParametersInfo(SPI_SETPOWEROFFTIMEOUT, 3600, nil, 0);
//    res := SystemParametersInfo(SPI_SETPOWEROFFACTIVE, 1, nil, 0);
//    SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(2));

//    Block_UserInput_Hook(True);
    //PowerOffMonitor;
  end
  else if AKey = 'ONMON' then
  begin
    // Power On Monitor
    if IsService then
      SendIOToHelperByIPC(QT_SENDONMON, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
//    SetBlankMonitor(False);
//    SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 1, 0);
//    SendMessage(MainFormHandle, WM_DRAG_FULL_WINDOWS_MESSAGE, 1, 0);
      RestoreScreen;
    end;


//    Show_Cursor;
//    SendMessage(MainFormHandle, WM_ZORDER_MESSAGE, 1, 0);
//    PostMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(-1));

//    if m_OldPowerOffTimeout <> 0 then
//      res := SystemParametersInfo(SPI_SETPOWEROFFTIMEOUT, m_OldPowerOffTimeout, nil, 0);
//    res := SystemParametersInfo(SPI_SETPOWEROFFACTIVE, 0, nil, 0);
//    m_OldPowerOffTimeout := 0;
//    SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(-1));

//    SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(-1));
//		//win8 require mouse move
//		mouse_event(MOUSEEVENTF_MOVE, 0, 1, 0, 0);
//		Sleep(40);
//		mouse_event(MOUSEEVENTF_MOVE, 0, DWORD(-1), 0, 0);
//
//    PostMessage(FindWindow(('blackscreen'), 0), WM_CLOSE, 0, 0);
//    m_Black_window_active := False;

//    Block_UserInput_Hook(False);
    //PowerOnMonitor;
  end
  else if AKey = 'OFFSYS' then
  begin
    // Power Off System
    PowerOffSystem;
  end
  else if AKey = 'LCKSYS' then
  begin
    // Lock System
    if IsService then
      SendIOToHelperByIPC(QT_SENDLCKSYS, 0, 0, 0, 0, 0, 0, 0, '')
    else
      LockSystem;
  end
  else if AKey = 'LOGOFF' then
  begin
    // Logoff
    if IsService then
      SendIOToHelperByIPC(QT_SENDLOGOFF, 0, 0, 0, 0, 0, 0, 0, '')
    else
      LogoffSystem;
  end
  else if AKey = 'RSTRT' then
  begin
    // Restart
    RestartSystem;
  end;
end;

//function BlockInputProc_Keyboard(CODE: DWORD; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
//var
//  ei : Integer;
//  KeyboardStruct: PKBDLLHOOKSTRUCT;
//begin
//  if CODE <> HC_ACTION then
//  begin
//    Result:= CallNextHookEx(BlockInputHook_Keyboard, CODE, wParam, LParam);
//    Exit;
//  end;
//
//  KeyboardStruct := Pointer(lParam);
//  if KeyboardStruct^.dwExtraInfo <> RMX_MAGIC_NUMBER then
//    Result := 1
//  else
//  Result := CallNextHookEx(BlockInputHook_Keyboard, CODE, wParam, LParam);
//end;
//
//function BlockInputProc_Mouse(CODE: DWORD; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
//var
//  ei : Integer;
//  MouseStruct: PMSLLHOOKSTRUCT;
//begin
//  if CODE <> HC_ACTION then
//  begin
//    Result:= CallNextHookEx(BlockInputHook_Mouse, CODE, wParam, LParam);
//    Exit;
//  end;
//
//  MouseStruct := Pointer(lParam);
//  if MouseStruct^.dwExtraInfo <> RMX_MAGIC_NUMBER then
//    Result := 1
//  else
//  Result := CallNextHookEx(BlockInputHook_Mouse, CODE, wParam, LParam);
//end;

//function TRtcScreenCapture.Block_UserInput_Hook(fBlockInput: Boolean): Boolean;
//var
//  err: LongInt;
//begin
//  if fBlockInput then
//  begin
//    BlockInputHook_Keyboard := SetWindowsHookEx(WH_KEYBOARD_LL, @BlockInputProc_Keyboard, hInstance, 0);
//    err := GetLastError;
//    if err <> 0 then
//      xLog(Format('Block_UserInput_Set_Keyboard. Error: %s', [SysErrorMessage(err)]));
//    Result := (BlockInputHook_Keyboard <> 0);
//
//    BlockInputHook_Mouse := SetWindowsHookEx(WH_MOUSE_LL, @BlockInputProc_Mouse, hInstance, 0);
//    err := GetLastError;
//    if err <> 0 then
//      xLog(Format('Block_UserInput_Set_Mouse. Error: %s', [SysErrorMessage(err)]));
//    Result := (BlockInputHook_Mouse <> 0);
//
//    SASLibEx_DisableCAD(DWORD(-1));
//    err := GetLastError;
//    if err <> 0 then
//      xLog(Format('Disable CAD. Error: %s', [SysErrorMessage(err)]));
//  end
//  else
//  begin
//    Result := UnhookWindowsHookEx(BlockInputHook_Keyboard);
//    err := GetLastError;
//    if err <> 0 then
//      xLog(Format('Block_UserInput_Unset_Keyboard. Error: %s', [SysErrorMessage(err)]));
//
//    Result := UnhookWindowsHookEx(BlockInputHook_Mouse);
//    err := GetLastError;
//    if err <> 0 then
//      xLog(Format('Block_UserInput_Unset_Mouse. Error: %s', [SysErrorMessage(err)]));
//
//    SASLibEx_EnableCAD(DWORD(-1));
//    err := GetLastError;
//    if err <> 0 then
//      xLog(Format('Enable CAD. Error: %s', [SysErrorMessage(err)]));
//  end;
//end;

procedure TRtcScreenCapture.ReleaseAllKeys;
begin
  if FShiftDown then
    KeyUp(VK_SHIFT, []);
  if FAltDown then
    KeyUp(VK_MENU, []);
  if FCtrlDown then
    KeyUp(VK_CONTROL, []);
end;

function TRtcScreenCapture.GetHaveScreen: Boolean;
begin
  Result := FPDesktopHost.FHaveScreen;
end;

procedure TRtcScreenCapture.SetHaveScreen(const Value: Boolean);
begin
  if FPDesktopHost.FHaveScreen <> Value then
  begin
    FPDesktopHost.FHaveScreen := Value;
    if Assigned(FPDesktopHost.FOnHaveScreeenChanged) then
      FPDesktopHost.FOnHaveScreeenChanged(Self);
  end;
end;

procedure TRtcScreenCapture.SetMultiMon(const Value: boolean);
begin
{$IFDEF MULTIMON}
  if FMultiMon <> Value then
  begin
    if assigned(ScrIn) then
    begin
      ScrIn.Free;
      ScrIn := nil;
    end;
{$IFDEF DFMirage}
    if assigned(vd) then
    begin
      vd.Free;
      vd := nil;
    end;
{$ENDIF}
    FMultiMon := Value;
  end;
{$ENDIF}
end;

function TRtcScreenCapture.MirageDriverInstalled(Init: boolean = False)
  : boolean;
{$IFDEF DFMirage}
var
  v: TVideoDriver;
begin
  if assigned(vd) then
    Result := vd.ExistMirrorDriver
  else
  begin
    v := TVideoDriver.Create;
    try
      Result := v.ExistMirrorDriver;
      if Result and Init then
      begin
        v.ActivateMirrorDriver;
        v.DeactivateMirrorDriver;
      end;
    finally
      v.Free;
    end;
  end;
{$ELSE}

begin
  Result := False;
{$ENDIF}
end;

{ TRtcPDesktopHost }

constructor TRtcPDesktopHost.Create(AOwner: TComponent);
begin
  inherited;
  CS2 := TCriticalSection.Create;
  Clipboards := TRtcRecord.Create;
  FLastMouseUser := '';
  FDesktopActive := False;
  _desksub := nil;
  _sub_desk := nil;

  FAccessControl := True;

  FAllowView := True;
  FAllowControl := True;

  FAllowSuperView := True;
  FAllowSuperControl := True;

  FShowFullScreen := True;
  FScreenInBlocks := rdBlocks1;
  FScreenRefineBlocks := rdBlocks1;
  FScreenRefineDelay := 0;
  FScreenSizeLimit := rdBlockAnySize;
  FUseMirrorDriver := False;
  FUseMouseDriver := False;
  FCaptureAllMonitors := False;
  FCaptureLayeredWindows := False;

  FColorLimit := rdColor8bit;
  FLowColorLimit := rd_ColorHigh;
  FColorReducePercent := 0;
  FFrameRate := rdFramesMax;

  //FileTrans+
  FHostMode := False;

  FMinSendBlock := RTCP_DEFAULT_MINCHUNKSIZE;
  FMaxSendBlock := RTCP_DEFAULT_MAXCHUNKSIZE;

  SendingFiles := TRtcArray.Create;
  UpdateFiles := TRtcRecord.Create;
  PrepareFiles := TRtcRecord.Create;
  WantToSendFiles := TRtcRecord.Create;
  File_Senders := 0;
  File_Sending := False;
  //FileTrans-
end;

destructor TRtcPDesktopHost.Destroy;
begin
   FileTransfer := nil;

  ScrStop;
  if assigned(_desksub) then
  begin
    _desksub.Free;
    _desksub := nil;
  end;
  if assigned(_sub_desk) then
  begin
    _sub_desk.Free;
    _sub_desk := nil;
  end;
  Clipboards.Free;
  CS2.Free;

  //FileTrans+
  WantToSendFiles.Free;
  PrepareFiles.Free;
  SendingFiles.Free;
  UpdateFiles.Free;
  //FileTrans-

  inherited;
end;

function TRtcPDesktopHost.MayControlDesktop(const user: String): boolean;
begin
  if FAccessControl and assigned(Client) then
    Result := (FAllowControl and Client.inUserList[user]) or
      (FAllowSuperControl and Client.isSuperUser[user])
  else
    Result := True;
end;

function TRtcPDesktopHost.MayViewDesktop(const user: String): boolean;
begin
  if FAccessControl and assigned(Client) then
    Result := (FAllowView and Client.inUserList[user]) or
      (FAllowSuperView and Client.isSuperUser[user])
  else
    Result := True;
end;

procedure TRtcPDesktopHost.Init;
begin
  ScrStop;
  inherited;
end;

procedure TRtcPDesktopHost.MakeDesktopActive;
begin
  if not FDesktopActive then
  begin
    FDesktopActive := True;
    SwitchToActiveDesktop;
  end;
end;

procedure TRtcPDesktopHost.Call_LogIn(Sender: TObject);
begin
end;

procedure TRtcPDesktopHost.Call_LogOut(Sender: TObject);
begin
end;

procedure TRtcPDesktopHost.Call_Params(Sender: TObject; data: TRtcValue);
begin
  CS2.Acquire;
  try
    RestartRequested := False;
    FLastMouseUser := '';
    Clipboards.Clear;
  finally
    CS2.Release;
  end;

  if FGatewayParams then
    if data.isType = rtc_Record then
      with data.asRecord do
      begin
        FAllowView := not asBoolean['NoViewDesktop'];
        FAllowControl := not asBoolean['NoControlDesktop'];

        FAllowSuperView := not asBoolean['NoSuperViewDesktop'];
        FAllowSuperControl := not asBoolean['NoSuperControlDesktop'];

        FShowFullScreen := not asBoolean['ScreenRegion'];
        FUseMirrorDriver := asBoolean['MirrorDriver'];
        FUseMouseDriver := asBoolean['MouseDriver'];
        FCaptureAllMonitors := asBoolean['AllMonitors'];
        FCaptureLayeredWindows := asBoolean['LayeredWindows'];

        FScreenInBlocks := TrdScreenBlocks(asInteger['ScreenBlocks']);
        FScreenRefineBlocks := TrdScreenBlocks(asInteger['ScreenBlocks2']);
        FScreenRefineDelay := asInteger['Screen2Delay'];
        FScreenSizeLimit := TrdScreenLimit(asInteger['ScreenLimit']);
        FColorLimit := TrdColorLimit(asInteger['ColorLimit']);
        FLowColorLimit := TrdLowColorLimit(asInteger['LowColorLimit']);
        FColorReducePercent := asInteger['ColorReducePercent'];
        FFrameRate := TrdFrameRate(asInteger['FrameRate']);
      end;
end;

procedure TRtcPDesktopHost.Call_Start(Sender: TObject; data: TRtcValue);
begin
  ScrStart;
  InitData;
end;

procedure TRtcPDesktopHost.Call_Error(Sender: TObject; data: TRtcValue);
begin
end;

procedure TRtcPDesktopHost.Call_FatalError(Sender: TObject; data: TRtcValue);
begin
end;

procedure TRtcPDesktopHost.Call_BeforeData(Sender: TObject);
begin
  if assigned(_desksub) then
  begin
    _desksub.Free;
    _desksub := nil;
  end;
  if assigned(_sub_desk) then
  begin
    _sub_desk.Free;
    _sub_desk := nil;
  end;
  FDesktopActive := False;
end;

procedure TRtcPDesktopHost.Call_UserJoinedMyGroup(Sender: TObject;
  const group, uname: String; uinfo:TRtcRecord);
begin
  inherited;

  if group = 'idesk' then
  begin
    if MayViewDesktop(uname) then
    begin
      // store to change temporary to full subscription
      if not assigned(_desksub) then
        _desksub := TRtcArray.Create;
      _desksub.asText[_desksub.Count] := uname;

      if not isSubscriber(uname) then
        Event_NewUser(Sender, uname, uinfo);
    end;
  end
  else if group = 'desk' then
  begin
    if MayViewDesktop(uname) then
    begin
      if setDeskSubscriber(uname, True) then
      begin
        // Event_NewUser(Sender, uname);
      end;
    end;
  end;
end;

procedure TRtcPDesktopHost.Call_UserLeftMyGroup(Sender: TObject;
  const group, uname: String);
begin
  if group = 'idesk' then
  begin
    if not isSubscriber(uname) then
      Event_OldUser(Sender, uname);
  end
  else if group = 'desk' then
  begin
    if setDeskSubscriber(uname, False) then
      Event_OldUser(Sender, uname);
  end;

  inherited;
end;

procedure TRtcPDesktopHost.Call_DataFromUser(Sender: TObject;
  const uname: String; data: TRtcFunctionInfo);
var
  s: RtcString;
  r: TRtcFunctionInfo;
  MyFiles: TRtcArray;
  k: integer;
  ScrChanged: boolean;

  //FileTrans+
  tofolder, tofile: String;
  loop: integer;
  WriteOK,ReadOK:boolean;

  function allZeroes:boolean;
    var
      a:integer;
    begin
    if length(s)=0 then
      Result:=False
    else
      begin
      Result:=True;
      for a:=1 to length(s) do
        if s[a]<>#0 then
          begin
          Result:=False;
          Break;
          end;
      end;
    end;
  procedure WriteNow(const tofile:String);
    begin
    loop:=0; ReadOK:=False;
    repeat
      Inc(loop);
      WriteOK:=Write_File(tofile, s, rtc_ShareDenyNone);
      if WriteOK then
        begin
        ReadOK:=Read_File(tofile)=s;
        if not ReadOK then
          begin
          Log('"'+tofile+'" - '+IntToStr(loop)+'. Read FAIL @'+Data.asString['at']+' ('+IntToStr(length(s))+')','FILES');
          Sleep(100);
          end;
        end
      else
        begin
        Log('"'+tofile+'" - '+IntToStr(loop)+'. Write FAIL @'+Data.asString['at']+' ('+IntToStr(length(s))+')','FILES');
        Sleep(100);
        end;
      until (WriteOK and ReadOK) or (loop>=10);
    end;
  procedure WriteNowAt(const tofile:String);
    begin
    loop:=0; ReadOK:=False;
    repeat
      Inc(loop);
      WriteOK:=Write_File(tofile, s, Data.asLargeInt['at'], rtc_ShareDenyNone);
      if WriteOK then
        begin
        ReadOK:=Read_File(tofile, Data.asLargeInt['at'], length(s))=s;
        if not ReadOK then
          begin
          Log('"'+tofile+'" - '+IntToStr(loop)+'. Read FAIL @'+Data.asString['at']+' ('+IntToStr(length(s))+')','FILES');
          Sleep(100);
          end;
        end
      else
        begin
        Log('"'+tofile+'" - '+IntToStr(loop)+'. Write FAIL @'+Data.asString['at']+' ('+IntToStr(length(s))+')','FILES');
        Sleep(100);
        end;
      until (WriteOK and ReadOK) or (loop>=10);
    end;
  //FileTrans-
begin
  //FileTrans+
  if Data.FunctionName = 'file' then // user is sending us a file
  begin
    if isSubscriber(uname) then
    begin
      s := Data.asString['data'];

      tofolder := Data.asText['to'];
      tofile := tofolder;
      if Copy(tofile, length(tofile), 1) <> '\' then
        tofile := tofile + '\';
      tofile := tofile + Data.asText['file'];

      if not DirectoryExists(ExtractFilePath(tofile)) then
        ForceDirectories(ExtractFilePath(tofile));

      if (length(s)>0) or // content received, or ...
         (Copy(tofile, length(tofile), 1) <> '\') then // NOT a folder
        begin
        if allZeroes then
          Log('"'+tofile+'" - ZERO DATA @'+Data.asString['at']+' ('+IntToStr(length(s))+')','FILES');
        // write file content
        if Data.asLargeInt['at'] = 0 then
          // overwrite old file on first write access
          begin
          WriteNow(tofile);
          if not (WriteOK and ReadOK) then
            WriteNow(tofile+'.{ACCESS_DENIED}');
          end
        else
          // append to the end later
          begin
          if (File_Size(tofile)<>Data.asLargeInt['at']) then
            begin
            if File_Size(tofile+'.{ACCESS_DENIED}')=Data.asLargeInt['at'] then
              WriteNowAt(tofile+'.{ACCESS_DENIED}')
            else if (File_Size(tofile)>Data.asLargeInt['at']) then
              Log('"'+tofile+'" - DOUBLE DATA @'+Data.asString['at']+' /'+IntToStr(File_Size(tofile))+' ('+IntToStr(length(s))+')','FILES')
            else
              Log('"'+tofile+'" - MISSING DATA @'+Data.asString['at']+' /'+IntToStr(File_Size(tofile))+' ('+IntToStr(length(s))+')','FILES');
            end
          else
            begin
            WriteNowAt(tofile);
            if not (WriteOK and ReadOK) then
              WriteNowAt(tofile+'.{ACCESS_DENIED}');
            end;
          end;
        end;

      // set file attributes
      if not Data.isNull['fattr'] then
        FileSetAttr(tofile, Data.asInteger['fattr']);

      // set file age
      if not Data.isNull['fage'] then
        FileSetDate(tofile, DateTimeToFileDate(Data.asDateTime['fage']));

      if Data.asBoolean['stop'] then
        Event_FileWriteStop(Sender, uname, Data.asText['path'], tofolder,
          length(s))
      else
        Event_FileWrite(Sender, uname, Data.asText['path'], tofolder,
          length(s));
    end;
  end
  else if Data.FunctionName = 'putfile' then // user wants to send us a file
  begin
    if isSubscriber(uname) then
    begin
      // tell user we are ready to accept his file
      r := TRtcFunctionInfo.Create;
      r.FunctionName := 'pfile';
      r.asInteger['id'] := Data.asInteger['id'];
      r.asText['path'] := Data.asText['path'];
      Client.SendToUser(Sender, uname, r);
      tofolder := Data.asText['to'];
      Event_FileWriteStart(Sender, uname, Data.asText['path'], tofolder,
        Data.asLargeInt['size']);
    end;
  end
  else if Data.FunctionName = 'pfile' then
  begin
    if isSubscriber(uname) then
    // user is letting us know that we may start sending the file
      StartSendingFile(uname, Data.asText['path'], Data.asInteger['id']);
  end
  else if Data.FunctionName = 'getfile' then
  begin
    if isSubscriber(uname) then
      Send(uname, Data.asText['file'], Data.asText['to'], Sender);
  end
  else
  //FileTrans-
  if data.FunctionName = 'mouse' then
  begin
    if MayControlDesktop(uname) and isSubscriber(uname) then
    begin
      MakeDesktopActive;
      if data.isType['d'] = rtc_Integer then
      begin
        CS2.Acquire;
        try
          FLastMouseUser := uname;
        finally
          CS2.Release;
        end;
        CS.Acquire;
        try
          if assigned(Scr) then
            case data.asInteger['d'] of
              1:
                Scr.MouseDown(uname, data.asInteger['x'],
                  data.asInteger['y'], mbLeft);
              2:
                Scr.MouseDown(uname, data.asInteger['x'],
                  data.asInteger['y'], mbRight);
              3:
                Scr.MouseDown(uname, data.asInteger['x'], data.asInteger['y'],
                  mbMiddle);
            end;
        finally
          CS.Release;
        end;
      end
      else if data.isType['u'] = rtc_Integer then
      begin
        CS2.Acquire;
        try
          FLastMouseUser := uname;
        finally
          CS2.Release;
        end;
        CS.Acquire;
        try
          if assigned(Scr) then
            case data.asInteger['u'] of
              1:
                Scr.MouseUp(uname, data.asInteger['x'],
                  data.asInteger['y'], mbLeft);
              2:
                Scr.MouseUp(uname, data.asInteger['x'],
                  data.asInteger['y'], mbRight);
              3:
                Scr.MouseUp(uname, data.asInteger['x'], data.asInteger['y'],
                  mbMiddle);
            end;
        finally
          CS.Release;
        end;
      end
      else if data.isType['w'] = rtc_Integer then
      begin
        CS.Acquire;
        try
          if assigned(Scr) then
            Scr.MouseWheel(data.asInteger['w']);
        finally
          CS.Release;
        end;
      end
      else
      begin
        CS.Acquire;
        try
          if assigned(Scr) then
            Scr.MouseMove(uname, data.asInteger['x'], data.asInteger['y']);
        finally
          CS.Release;
        end;
      end;
    end;
  end
  else if data.FunctionName = 'key' then
  begin
    if MayControlDesktop(uname) then
    begin
      if isSubscriber(uname) then
      begin
        MakeDesktopActive;
        CS.Acquire;
        try
          if assigned(Scr) then
          begin
            if data.isType['d'] = rtc_Integer then
              Scr.KeyDown(data.asInteger['d'], [])
            else if data.isType['u'] = rtc_Integer then
              Scr.KeyUp(data.asInteger['u'], [])
//Доделать. Убрано nonunicode тк в хелпере не реализовано
//            else if data.isType['p'] = rtc_String then
//              Scr.KeyPress(data.asString['p'], data.asInteger['k'])
            else if data.isType['p'] = rtc_WideString then
              Scr.KeyPressW(data.asWideString['p'], data.asInteger['k'])
            else if data.isType['lw'] = rtc_Integer then
              Scr.LWinKey(data.asInteger['lw'])
            else if data.isType['rw'] = rtc_Integer then
              Scr.RWinKey(data.asInteger['rw'])
            else if data.isType['s'] = rtc_String then
            begin
              Scr.SpecialKey(data.asString['s']);
              if data.asString['s'] = 'COPY' then
              begin
                if assigned(FileTransfer) then
                begin
                  // wait for Ctrl+C to be processed by the receiving app
                  Sleep(250);
                  // Clipboard has changed. Check if we have files in it and start sending them
                  MyFiles := Get_ClipboardFiles;
                  if assigned(MyFiles) then
                    try
                      for k := 0 to MyFiles.Count - 1 do
                        FileTransfer.Send(uname, MyFiles.asText[k]);
                    finally
                      MyFiles.Free;
                    end;
                end;
              end;
            end;
          end;
        finally
          CS.Release;
        end;
      end
      else
      begin
        MakeDesktopActive;
        CS.Acquire;
        try
          if data.isType['s'] = rtc_String then
            if data.asString['s'] = 'HDESK' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDHDESK, 0, 0, 0, 0, 0, 0, 0, '')
              else
                Hide_Wallpaper;
            end
            else
            if data.asString['s'] = 'SDESK' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDSDESK, 0, 0, 0, 0, 0, 0, 0, '')
              else
                Show_Wallpaper;
            end
            else
            if data.asString['s'] = 'BKM' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDBKM, 0, 0, 0, 0, 0, 0, 0, '')
              else
                SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 0, 0);
            end
            else
            if data.asString['s'] = 'UBKM' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDUBKM, 0, 0, 0, 0, 0, 0, 0, '')
              else
                SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 1, 0);
            end
            else
            if data.asString['s'] = 'OFFMON' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDOFFMON, 0, 0, 0, 0, 0, 0, 0, '')
              else
              begin
          //    SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 0, 0);
          //    SendMessage(MainFormHandle, WM_DRAG_FULL_WINDOWS_MESSAGE, 0, 0);
          //    SetBlankMonitor(True);
              end;
            end
            else
            if data.asString['s'] = 'ONMON' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDONMON, 0, 0, 0, 0, 0, 0, 0, '')
              else
              begin
          //    SetBlankMonitor(False);
          //    SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 1, 0);
          //    SendMessage(MainFormHandle, WM_DRAG_FULL_WINDOWS_MESSAGE, 1, 0);
              end;
            end
            else
            if data.asString['s'] = 'OFFSYS' then
              PowerOffSystem
            else
            if data.asString['s'] = 'LCKSYS' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDLCKSYS, 0, 0, 0, 0, 0, 0, 0, '')
              else
                LockSystem;
            end
            else
            if data.asString['s'] = 'LOGOFF' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDLOGOFF, 0, 0, 0, 0, 0, 0, 0, '')
              else
                LogoffSystem;
            end
            else
            if data.asString['s'] = 'RSTRT' then
              RestartSystem;
        finally
          CS.Release;
        end;
      end;
    end;
  end
  else if data.FunctionName = 'cbrd' then
  begin
    if MayControlDesktop(uname) and isSubscriber(uname) then
    begin
      MakeDesktopActive;
      // Clipboard data
      s := data.asString['s'];
      setClipboard(uname, s);
    end;
  end
  else if data.FunctionName = 'gcbrd' then
  begin
    if MayControlDesktop(uname) and isSubscriber(uname) then
    begin
      MakeDesktopActive;
      r := nil;
      // Clipboard request
      CS2.Acquire;
      try
        s := Get_Clipboard;
        if (Clipboards.isType[uname] = rtc_Null) or
          (s <> Clipboards.asString[uname]) then
        begin
          Put_Clipboard(s);
          s := Get_Clipboard;
          if (Clipboards.isType[uname] = rtc_Null) or
            (s <> Clipboards.asString[uname]) then
          begin
            if s = '' then
            begin
              Clipboards.asString[uname] := '';
              r := TRtcFunctionInfo.Create;
              r.FunctionName := 'cbrd';
              // r.asString['s']:='';
            end
            else
            begin
              Clipboards.asString[uname] := s;
              r := TRtcFunctionInfo.Create;
              r.FunctionName := 'cbrd';
              r.asString['s'] := s;
            end;
          end;
        end;
      finally
        CS2.Release;
      end;
      if assigned(r) then
        Client.SendToUser(Sender, uname, r);
    end;
  end
  else if (data.FunctionName = 'chgdesk') then
  begin
    if MayControlDesktop(uname) then
    begin
      ScrChanged := False;
      if (data.isType['color'] = rtc_Integer) and
        (GColorLimit <> TrdColorLimit(data.asInteger['color'])) then
      begin
        GColorLimit := TrdColorLimit(data.asInteger['color']);
        ScrChanged := True;
      end;
      if (data.isType['colorlow'] = rtc_Integer) and
        (GColorLowLimit <> TrdLowColorLimit(data.asInteger['colorlow'])) then
      begin
        GColorLowLimit := TrdLowColorLimit(data.asInteger['colorlow']);
        ScrChanged := True;
      end;
      if (data.isType['colorpercent'] = rtc_Integer) and
        (GColorReducePercent <> data.asInteger['colorpercent']) then
      begin
        GColorReducePercent := data.asInteger['colorpercent'];
        ScrChanged := True;
      end;
      if (data.isType['frame'] = rtc_Integer) and
        (GFrameRate <> TrdFrameRate(data.asInteger['frame'])) then
      begin
        GFrameRate := TrdFrameRate(data.asInteger['frame']);
        ScrChanged := True;
      end;
      if (data.isType['mirror'] = rtc_Boolean) and
        (GUseMirrorDriver <> data.asBoolean['mirror']) then
      begin
        GUseMirrorDriver := data.asBoolean['mirror'];
        ScrChanged := True;
      end;
      if (data.isType['mouse'] = rtc_Boolean) and
        (GUseMouseDriver <> data.asBoolean['mouse']) then
      begin
        GUseMouseDriver := data.asBoolean['mouse'];
        ScrChanged := True;
      end;
      if (data.isType['scrblocks'] = rtc_Integer) and
        (GSendScreenInBlocks <> TrdScreenBlocks(data.asInteger['scrblocks']))
      then
      begin
        GSendScreenInBlocks := TrdScreenBlocks(data.asInteger['scrblocks']);
        ScrChanged := True;
      end;
      if (data.isType['scrblocks2'] = rtc_Integer) and
        (GSendScreenRefineBlocks <> TrdScreenBlocks(data.asInteger
        ['scrblocks2'])) then
      begin
        GSendScreenRefineBlocks :=
          TrdScreenBlocks(data.asInteger['scrblocks2']);
        ScrChanged := True;
      end;
      if (data.isType['scr2delay'] = rtc_Integer) and
        (GSendScreenRefineDelay <> data.asInteger['scr2delay']) then
      begin
        GSendScreenRefineDelay := data.asInteger['scr2delay'];
        ScrChanged := True;
      end;
      if (data.isType['scrlimit'] = rtc_Integer) and
        (GSendScreenSizeLimit <> TrdScreenLimit(data.asInteger['scrlimit']))
      then
      begin
        GSendScreenSizeLimit := TrdScreenLimit(data.asInteger['scrlimit']);
        ScrChanged := True;
      end;
      if (data.isType['monitors'] = rtc_Boolean) and
        (GCaptureAllMonitors <> data.asBoolean['monitors']) then
      begin
        GCaptureAllMonitors := data.asBoolean['monitors'];
        ScrChanged := True;
      end;
      if (data.isType['layered'] = rtc_Boolean) and
        (GCaptureLayeredWindows <> data.asBoolean['layered']) then
      begin
        GCaptureLayeredWindows := data.asBoolean['layered'];
        ScrChanged := True;
      end;
      if ScrChanged then
        Restart;
    end;
  end
  // New "Desktop View" subscriber ...
  else if (data.FunctionName = 'desk') and (data.FieldCount = 0) then
  begin
    // allow subscriptions only if "CanViewDesktop" is enabled
    if MayViewDesktop(uname) then
      if Event_QueryAccess(Sender, uname) then
      begin
        if not assigned(_sub_desk) then
          _sub_desk := TRtcRecord.Create;
        _sub_desk.asBoolean[uname] := True;
      end;
  end;
end;

procedure TRtcPDesktopHost.Call_AfterData(Sender: TObject);
var
  a: integer;
  have_desktop: boolean;
  uname: String;

  procedure SendDesktop(full: boolean);
  var
    fn1, fn2: String;
    s1, s2: RtcString;
    fn: TRtcFunctionInfo;
  begin
    // New user for Desktop View
    fn := nil;

    CS.Acquire;
    try
      if assigned(Scr) and
        (full or ((getSubscriberCnt > 0) and Client.canSendNext)) then
      begin
        if not have_desktop then
        begin
          LastGrab := GetTickCount;
          Scr.GrabScreen;
          Scr.GrabMouse;
          have_desktop := True;
        end;

        if full then
        begin
          // Send Initial Full Screen to New subscribers
          s1 := Scr.GetScreen;
          s2 := Scr.GetMouse;
          fn1 := 'idesk';
          fn2 := 'init';
        end
        else
        begin
          // Send Screen Delta to already active subscribers
          s1 := Scr.GetScreenDelta;
          s2 := Scr.GetMouseDelta;
          fn1 := 'desk';
          fn2 := 'next';
        end;
      end;
    finally
      CS.Release;
    end;

    if s1 <> '' then
    begin
      fn := TRtcFunctionInfo.Create;
      fn.FunctionName := 'desk';
      fn.asString[fn2] := s1;
    end;
    if s2 <> '' then
    begin
      if not assigned(fn) then
      begin
        fn := TRtcFunctionInfo.Create;
        fn.FunctionName := 'desk';
      end;
      fn.asString['cur'] := s2;
    end;

    if assigned(fn) then
      Client.SendToMyGroup(Sender, fn1, fn);
  end;

begin
  have_desktop := False;
  try
    if assigned(_desksub) then
    begin
      MakeDesktopActive;

      // Send Delta screen
      SendDesktop(False);
      // Send initial screen
      SendDesktop(True);

      // Change temporary subscriptions to full subscriptions ...
      for a := 0 to _desksub.Count - 1 do
      begin
        uname := _desksub.asText[a];
        Client.AddUserToMyGroup(Sender, uname, 'desk');
        Client.RemoveUserFromMyGroup(Sender, uname, 'idesk');
      end;
    end;

    if assigned(_sub_desk) then
    begin
      for a := 0 to _sub_desk.Count - 1 do
      begin
        uname := _sub_desk.FieldName[a];
        Client.AddUserToMyGroup(Sender, uname, 'idesk');
      end;
    end;
  finally
    if assigned(_desksub) then
    begin
      _desksub.Free;
      _desksub := nil;
    end;
    if assigned(_sub_desk) then
    begin
      _sub_desk.Free;
      _sub_desk := nil;
    end;
  end;
end;

function TRtcPDesktopHost.SenderLoop_Check(Sender: TObject): boolean;
var
  a: integer;
  uname: String;
begin
  loop_needtosend := False;
  loop_need_restart := False;

  CS.Acquire;
  try
    Result := (getSubscriberCnt > 0) and assigned(Scr);
  finally
    CS.Release;
  end;

//FileTrans+
  CS.Acquire;
  try
    if File_Sending then
    begin
      if UpdateFiles.Count > 0 then
      begin
        loop_update := TRtcArray.Create;
        for a := 0 to UpdateFiles.Count - 1 do
        begin
          uname := UpdateFiles.FieldName[a];
          if UpdateFiles.asBoolean[uname] then
          begin
            UpdateFiles.asBoolean[uname] := False;
            loop_update.asText[loop_update.Count] := uname;
          end;
        end;
        UpdateFiles.Clear;
      end;

      if File_Senders > 0 then
        loop_tosendfile := True
      else
        File_Sending := False;
    end;
  finally
    CS.Release;
  end;
//FileTrans-
end;

procedure TRtcPDesktopHost.SenderLoop_Prepare(Sender: TObject);
var
  nowtime: longword;
  a: integer;
  uname: String;
begin
  CS.Acquire;
  try
    if (getSubscriberCnt > 0) and assigned(Scr) then
    begin
      SwitchToActiveDesktop;

      loop_needtosend := True;

      loop_s1 := '';
      loop_s2 := '';

      loop_need_restart := RestartRequested;
      RestartRequested := False;

      nowtime := GetTickCount;
      if LastGrab > 0 then
        if FrameSleep > 0 then
          Sleep(FrameSleep)
        else if (FramePause > 0) and (FramePause > nowtime - LastGrab) then
          Sleep(FramePause - (nowtime - LastGrab));

      LastGrab := GetTickCount;
      Scr.GrabScreen;
      loop_s1 := Scr.GetScreenDelta;

      Scr.GrabMouse;
      loop_s2 := Scr.GetMouseDelta;
    end;
  finally
    CS.Release;
  end;

//FileTrans+
  CS.Acquire;
  try
    if File_Sending then
    begin
      if UpdateFiles.Count > 0 then
      begin
        loop_update := TRtcArray.Create;
        for a := 0 to UpdateFiles.Count - 1 do
        begin
          uname := UpdateFiles.FieldName[a];
          if UpdateFiles.asBoolean[uname] then
          begin
            UpdateFiles.asBoolean[uname] := False;
            loop_update.asText[loop_update.Count] := uname;
          end;
        end;
        UpdateFiles.Clear;
      end;

      if File_Senders > 0 then
        loop_tosendfile := True
      else
        File_Sending := False;
    end;
  finally
    CS.Release;
  end;
//FileTrans-
end;

procedure TRtcPDesktopHost.SenderLoop_Execute(Sender: TObject);
var
  fn: TRtcFunctionInfo;
//FileTrans+
var
  sr: TRtcRecord;

  a: integer;

  maxRead, maxSend, sendNow: int64;

  myStop, myRead: boolean;

  s: RtcString;
  myUser: String;

  myPath, myFolder, myFile, myDest: String;

  myReadSize, mySize, myLoc: int64;

  dts: TRtcDataSet;

  function SendNextFile: boolean;
  var
    idx: integer;
    fstart: TRtcArray;
    frec: TRtcRecord;
  begin
    myStop := False;
    myRead := False;
    fn := nil;

    fstart := nil;
    try
      CS.Acquire;
      try
        for idx := 0 to SendingFiles.Count - 1 do
          if SendingFiles.isType[idx] = rtc_Record then
            with SendingFiles.asRecord[idx] do
              if not asBoolean['start'] then
              begin
                asBoolean['start'] := True;
                if not assigned(fstart) then
                  fstart := TRtcArray.Create;
                frec := fstart.newRecord(fstart.Count);
                frec.asText['user'] := asText['user'];
                frec.asText['path'] := asText['path'];
                frec.asText['folder'] := asText['folder'];
                frec.asText['to'] := asText['to'];
                frec.asLargeInt['size'] := asLargeInt['size'];
              end;
      finally
        CS.Release;
      end;
    except
      on E: Exception do
      begin
        Log('SEND.LOOP1', E);
        raise;
      end;
    end;

    if assigned(fstart) then
      try
        for idx := 0 to fstart.Count - 1 do
          with fstart.asRecord[idx] do
            Event_FileReadStart(Sender, asText['user'], asText['path'],
              asText['folder'], asLargeInt['size']);
      finally
        fstart.Free;
      end;

    CS.Acquire;
    try
      if SendingFiles.Count > 0 then
      begin
        idx := SendingFiles.Count - 1;
        while SendingFiles.isNull[idx] do
        begin
          Dec(idx);
          if idx < 0 then
            Break;
        end;
      end
      else
        idx := -1;

      if idx >= 0 then
      begin
        try
          sr := SendingFiles.asRecord[idx];

          myUser := sr.asText['user'];
          myFolder := sr.asText['folder'];
          myPath := sr.asText['path'];
          myDest := sr.asText['to'];

          UpdateFiles.asBoolean[myUser] := True;

          dts := sr.asDataSet['files'];
          dts.Last;

          myFile := dts.asText['name'];

          // re-calculate file size before sending it
          if dts.asLargeInt['sent'] = 0 then
            dts.asLargeInt['size'] := File_Size(myFolder + myFile);

          mySize := dts.asLargeInt['size'];
          myLoc := dts.asLargeInt['sent'];

          fn := TRtcFunctionInfo.Create;
          fn.FunctionName := 'file';
          fn.asText['file'] := myFile;
          fn.asText['path'] := myPath;
          if myDest <> '' then
            fn.asText['to'] := myDest;

        except
          on E: Exception do
          begin
            Log('SEND.READ1', E);
            raise;
          end;
        end;

        try
          if myLoc < mySize then
          begin
            sendNow := mySize - myLoc;
            if sendNow > maxRead then
              sendNow := maxRead;

            s := Read_File(myFolder + myFile, myLoc, sendNow);

            if length(s) > 0 then
            begin
              myRead := True;
              myReadSize := length(s);

              dts.asLargeInt['sent'] := myLoc + myReadSize;

              fn.asString['data'] := s;
              fn.asLargeInt['at'] := myLoc;

              maxRead := maxRead - myReadSize;
              maxSend := maxSend - length(fn.asString['data']);

              if dts.asLargeInt['sent'] = mySize then
              begin
                fn.asDateTime['fage'] := dts.asDateTime['age'];
                fn.asInteger['fattr'] := dts.asInteger['attr'];
                dts.Delete;
                if dts.RowCount = 0 then
                begin
                  myStop := True;
                  SendingFiles.isNull[idx] := True;
                  Dec(File_Senders);
                  fn.asBoolean['stop'] := True;
                end;
              end;
            end
            else
            begin
              fn.asDateTime['fage'] := dts.asDateTime['age'];
              fn.asInteger['fattr'] := dts.asInteger['attr'];
              dts.Delete;
              if dts.RowCount = 0 then
              begin
                myStop := True;
                SendingFiles.isNull[idx] := True;
                Dec(File_Senders);
                fn.asBoolean['stop'] := True;
              end;
            end;
          end
          else
          begin
            fn.asDateTime['fage'] := dts.asDateTime['age'];
            fn.asInteger['fattr'] := dts.asInteger['attr'];
            dts.Delete;
            if dts.RowCount = 0 then
            begin
              myStop := True;
              SendingFiles.isNull[idx] := True;
              Dec(File_Senders);
              fn.asBoolean['stop'] := True;
            end;
          end;

        except
          on E: Exception do
          begin
            Log('SEND.READ2', E);
            raise;
          end;
        end;

      end;
    finally
      CS.Release;
    end;

    if assigned(fn) then
    begin
      Client.SendToUser(Sender, myUser, fn);

      if myRead then
        Event_FileRead(Sender, myUser, myPath, myFolder, myReadSize);

      if myStop then
        Event_FileReadStop(Sender, myUser, myPath, myFolder, 0);

      Result := True;
    end
    else
      Result := False;
  end;
//FileTrans-
begin
  fn := nil;

  if loop_needtosend then
  begin
    if loop_s1 <> '' then
    begin
      fn := TRtcFunctionInfo.Create;
      fn.FunctionName := 'desk';
      fn.asString['next'] := loop_s1;
    end;
    if loop_s2 <> '' then
    begin
      if not assigned(fn) then
      begin
        fn := TRtcFunctionInfo.Create;
        fn.FunctionName := 'desk';
      end;
      fn.asString['cur'] := loop_s2;
    end;

    if assigned(fn) then
      Client.SendToMyGroup(Sender, 'desk', fn)
    else
      Client.SendPing(Sender);

    if loop_need_restart then
    begin
      ScrStop;
      ScrStart;
    end;
  end;

//FileTrans+
  if assigned(loop_update) then
    try
      for a := 0 to loop_update.Count - 1 do
        Event_FileReadUpdate(Sender, loop_update.asText[a]);
    finally
      loop_update.Free;
    end;

  if loop_tosendfile then
  begin
    maxRead := FMaxSendBlock; // read max 100 KB of data at once
    maxSend := FMaxSendBlock div 2; // send max 50 KB of compressed data at once
    repeat
      if not SendNextFile then
        Break;
    until (maxRead < FMinSendBlock) or (maxSend < FMinSendBlock);
  end;
//FileTrans-
end;

function TRtcPDesktopHost.GetLastMouseUser: String;
begin
  CS2.Acquire;
  try
    Result := FLastMouseUser;
  finally
    CS2.Release;
  end;
end;

function TRtcPDesktopHost.setDeskSubscriber(const username: String;
  active: boolean): boolean;
begin
  Result := setSubscriber(username, active);
  CS.Acquire;
  try
    if Result and assigned(Scr) and not active and (getSubscriberCnt = 0) then
      Scr.Clear;
  finally
    CS.Release;
  end;
end;

procedure TRtcPDesktopHost.setClipboard(const username: String;
  const data: RtcString);
begin
  CS2.Acquire;
  try
    Clipboards.asString[username] := data;
    Put_Clipboard(data);
  finally
    CS2.Release;
  end;
end;

procedure TRtcPDesktopHost.SetAllowView(const Value: boolean);
begin
  if Value <> FAllowView then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'NoViewDesktop', TRtcBooleanValue.Create(not Value));
    FAllowView := Value;
  end;
end;

function TRtcPDesktopHost.GetAllowView: boolean;
begin
  Result := FAllowView;
end;

procedure TRtcPDesktopHost.SetAllowControl(const Value: boolean);
begin
  if Value <> FAllowControl then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'NoControlDesktop',
        TRtcBooleanValue.Create(not Value));
    FAllowControl := Value;
  end;
end;

function TRtcPDesktopHost.GetAllowControl: boolean;
begin
  Result := FAllowControl;
end;

procedure TRtcPDesktopHost.SetAllowSuperView(const Value: boolean);
begin
  if Value <> FAllowSuperView then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'NoSuperViewDesktop',
        TRtcBooleanValue.Create(not Value));
    FAllowSuperView := Value;
  end;
end;

function TRtcPDesktopHost.GetAllowSuperView: boolean;
begin
  Result := FAllowSuperView;
end;

procedure TRtcPDesktopHost.SetAllowSuperControl(const Value: boolean);
begin
  if Value <> FAllowSuperControl then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'NoSuperControlDesktop',
        TRtcBooleanValue.Create(not Value));
    FAllowSuperControl := Value;
  end;
end;

function TRtcPDesktopHost.GetAllowSuperControl: boolean;
begin
  Result := FAllowSuperControl;
end;

procedure TRtcPDesktopHost.SetUseMirrorDriver(const Value: boolean);
begin
  if Value <> FUseMirrorDriver then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'MirrorDriver', TRtcBooleanValue.Create(Value));
    FUseMirrorDriver := Value;
  end;
end;

procedure TRtcPDesktopHost.SetUseMouseDriver(const Value: boolean);
begin
  if Value <> FUseMouseDriver then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'MouseDriver', TRtcBooleanValue.Create(Value));
    FUseMouseDriver := Value;
  end;
end;

procedure TRtcPDesktopHost.SetCaptureAllMonitors(const Value: boolean);
begin
  if Value <> FCaptureAllMonitors then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'AllMonitors', TRtcBooleanValue.Create(Value));
    FCaptureAllMonitors := Value;
  end;
end;

procedure TRtcPDesktopHost.SetCaptureLayeredWindows(const Value: boolean);
begin
  if Value <> FCaptureLayeredWindows then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'LayeredWindows', TRtcBooleanValue.Create(Value));
    FCaptureLayeredWindows := Value;
  end;
end;

function TRtcPDesktopHost.GetUseMirrorDriver: boolean;
begin
  Result := FUseMirrorDriver;
end;

function TRtcPDesktopHost.GetUseMouseDriver: boolean;
begin
  Result := FUseMouseDriver;
end;

function TRtcPDesktopHost.GetCaptureAllMonitors: boolean;
begin
  Result := FCaptureAllMonitors;
end;

function TRtcPDesktopHost.GetCaptureLayeredWindows: boolean;
begin
  Result := FCaptureLayeredWindows;
end;

procedure TRtcPDesktopHost.SetSendScreenInBlocks(const Value: TrdScreenBlocks);
begin
  if Value <> FScreenInBlocks then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'ScreenBlocks', TRtcIntegerValue.Create(Ord(Value)));
    FScreenInBlocks := Value;
  end;
end;

function TRtcPDesktopHost.GetSendScreenInBlocks: TrdScreenBlocks;
begin
  Result := FScreenInBlocks;
end;

procedure TRtcPDesktopHost.SetSendScreenRefineBlocks
  (const Value: TrdScreenBlocks);
begin
  if Value <> FScreenRefineBlocks then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'ScreenBlocks2',
        TRtcIntegerValue.Create(Ord(Value)));
    FScreenRefineBlocks := Value;
  end;
end;

function TRtcPDesktopHost.GetSendScreenRefineBlocks: TrdScreenBlocks;
begin
  Result := FScreenRefineBlocks;
end;

procedure TRtcPDesktopHost.SetSendScreenRefineDelay(const Value: integer);
begin
  if Value <> FScreenRefineDelay then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'Screen2Delay', TRtcIntegerValue.Create(Value));
    FScreenRefineDelay := Value;
  end;
end;

function TRtcPDesktopHost.GetSendScreenRefineDelay: integer;
begin
  Result := FScreenRefineDelay;
end;

procedure TRtcPDesktopHost.SetSendScreenSizeLimit(const Value: TrdScreenLimit);
begin
  if Value <> FScreenSizeLimit then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'ScreenLimit', TRtcIntegerValue.Create(Ord(Value)));
    FScreenSizeLimit := Value;
  end;
end;

function TRtcPDesktopHost.GetSendScreenSizeLimit: TrdScreenLimit;
begin
  Result := FScreenSizeLimit;
end;

procedure TRtcPDesktopHost.SetShowFullScreen(const Value: boolean);
begin
  if Value <> FShowFullScreen then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'ScreenRegion', TRtcBooleanValue.Create(not Value));
    FShowFullScreen := Value;
  end;
end;

function TRtcPDesktopHost.GetShowFullScreen: boolean;
begin
  Result := FShowFullScreen;
end;

procedure TRtcPDesktopHost.SetColorLimit(const Value: TrdColorLimit);
begin
  if Value <> FColorLimit then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'ColorLimit', TRtcIntegerValue.Create(Ord(Value)));
    FColorLimit := Value;
  end;
end;

function TRtcPDesktopHost.GetColorLimit: TrdColorLimit;
begin
  Result := FColorLimit;
end;

procedure TRtcPDesktopHost.SetColorReducePercent(const Value: integer);
begin
  if Value <> FColorReducePercent then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'ColorReducePercent',
        TRtcIntegerValue.Create(Ord(Value)));
    FColorReducePercent := Value;
  end;
end;

function TRtcPDesktopHost.GetColorReducePercent: integer;
begin
  Result := FColorReducePercent;
end;

procedure TRtcPDesktopHost.SetLowColorLimit(const Value: TrdLowColorLimit);
begin
  if Value <> FLowColorLimit then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'LowColorLimit',
        TRtcIntegerValue.Create(Ord(Value)));
    FLowColorLimit := Value;
  end;
end;

function TRtcPDesktopHost.GetLowColorLimit: TrdLowColorLimit;
begin
  Result := FLowColorLimit;
end;

procedure TRtcPDesktopHost.SetFrameRate(const Value: TrdFrameRate);
begin
  if Value <> FFrameRate then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'FrameRate', TRtcIntegerValue.Create(Ord(Value)));
    FFrameRate := Value;
  end;
end;

function TRtcPDesktopHost.GetFrameRate: TrdFrameRate;
begin
  Result := FFrameRate;
end;

procedure TRtcPDesktopHost.ScrStart;
begin
  CS.Acquire;
  try
    if not assigned(Scr) and (FAllowView or FAllowControl or FAllowSuperView or
      FAllowSuperControl) then
    begin
      LastGrab := 0;
      FrameSleep := 0;
      FramePause := 0;
      case FFrameRate of
        rdFrames50:
          FramePause := 1000 div 50;
        rdFrames40:
          FramePause := 1000 div 40;
        rdFrames25:
          FramePause := 1000 div 25;
        rdFrames20:
          FramePause := 1000 div 20;
        rdFrames10:
          FramePause := 1000 div 10;
        rdFrames8:
          FramePause := 1000 div 8;
        rdFrames5:
          FramePause := 1000 div 5;
        rdFrames4:
          FramePause := 1000 div 4;
        rdFrames2:
          FramePause := 1000 div 2;
        rdFrames1:
          FramePause := 1000 div 1;

        rdFrameSleep500:
          FrameSleep := 500;
        rdFrameSleep400:
          FrameSleep := 400;
        rdFrameSleep250:
          FrameSleep := 250;
        rdFrameSleep200:
          FrameSleep := 200;
        rdFrameSleep100:
          FrameSleep := 100;
        rdFrameSleep80:
          FrameSleep := 80;
        rdFrameSleep50:
          FrameSleep := 50;
        rdFrameSleep40:
          FrameSleep := 40;
        rdFrameSleep20:
          FrameSleep := 20;
        rdFrameSleep10:
          FrameSleep := 10;

      else
        FramePause := 16; // Max = 59 FPS
      end;

      Scr := TRtcScreenCapture.Create;
      case FColorLimit of
        rdColor4bit:
          begin
            Scr.BPPLimit := 0;
            Scr.Reduce16bit := $8E308E30; // 6bit
            Scr.Reduce32bit := $00C0C0C0; // 6bit
          end;
        rdColor6bit:
          begin
            Scr.Reduce16bit := $8E308E30; // 6bit
            Scr.Reduce32bit := $00C0C0C0; // 6bit
          end;
        rdColor8bit:
          begin
            Scr.BPPLimit := 1;
            Scr.Reduce16bit := $CF38CF38; // 9bit
            Scr.Reduce32bit := $00E0E0E0; // 9bit
          end;
        rdColor9bit:
          begin
            Scr.Reduce16bit := $CF38CF38; // 9bit
            Scr.Reduce32bit := $00E0E0E0; // 9bit
          end;
        rdColor12bit:
          begin
            Scr.Reduce16bit := $EFBCEFBC; // 12bit
            Scr.Reduce32bit := $00F0F0F0; // 12bit
          end;
        rdColor15bit:
          begin
            Scr.Reduce16bit := $FFF0FFF0; // 15bit
            Scr.Reduce32bit := $00F8F8F8; // 15bit
          end;
        rdColor16bit:
          begin
            Scr.BPPLimit := 2;
            Scr.Reduce32bit := $80F8F8F8; // 16bit
          end;
        rdColor18bit:
          begin
            Scr.Reduce32bit := $00FCFCFC; // 18bit
          end;
        rdColor21bit:
          begin
            Scr.Reduce32bit := $00FEFEFE; // 21bit
          end;
      end;

      case FLowColorLimit of
        rd_Color6bit, rd_ColorHigh6bit:
          begin
            Scr.LowReduce16bit := $8E308E30; // 6bit
            Scr.LowReduce32bit := $00C0C0C0; // 6bit
          end;
        rd_Color9bit, rd_ColorHigh9bit:
          begin
            Scr.LowReduce16bit := $CF38CF38; // 9bit
            Scr.LowReduce32bit := $00E0E0E0; // 9bit
          end;
        rd_Color12bit, rd_ColorHigh12bit:
          begin
            Scr.LowReduce16bit := $EFBCEFBC; // 12bit
            Scr.LowReduce32bit := $00F0F0F0; // 12bit
          end;
        rd_Color15bit, rd_ColorHigh15bit:
          begin
            Scr.LowReduce16bit := $FFF0FFF0; // 15bit
            Scr.LowReduce32bit := $00F8F8F8; // 15bit
          end;
        rd_Color18bit, rd_ColorHigh18bit:
          begin
            Scr.LowReduce32bit := $00FCFCFC; // 18bit
          end;
        rd_Color21bit, rd_ColorHigh21bit:
          begin
            Scr.LowReduce32bit := $00FEFEFE; // 21bit
          end;
      end;

      if FLowColorLimit < rd_ColorHigh6bit then
        Scr.LowReduceType := 0
      else
        Scr.LowReduceType := 1;

      if (Scr.Reduce32bit > 0) and (Scr.LowReduce32bit > 0) then
        Scr.LowReducedColors := Scr.LowReduce32bit < Scr.Reduce32bit
      else
        Scr.LowReducedColors := Scr.LowReduce32bit > 0;
      Scr.LowReduceColorPercent := GColorReducePercent;

      Scr.LayeredWindows := FCaptureLayeredWindows;

      case FScreenInBlocks of
        rdBlocks1:
          Scr.ScreenBlockCount := 1;
        rdBlocks2:
          Scr.ScreenBlockCount := 2;
        rdBlocks3:
          Scr.ScreenBlockCount := 3;
        rdBlocks4:
          Scr.ScreenBlockCount := 4;
        rdBlocks5:
          Scr.ScreenBlockCount := 5;
        rdBlocks6:
          Scr.ScreenBlockCount := 6;
        rdBlocks7:
          Scr.ScreenBlockCount := 7;
        rdBlocks8:
          Scr.ScreenBlockCount := 8;
        rdBlocks9:
          Scr.ScreenBlockCount := 9;
        rdBlocks10:
          Scr.ScreenBlockCount := 10;
        rdBlocks11:
          Scr.ScreenBlockCount := 11;
        rdBlocks12:
          Scr.ScreenBlockCount := 12;
      end;

      case FScreenRefineBlocks of
        rdBlocks1:
          begin
            Scr.Screen2BlockCount := Scr.ScreenBlockCount * 2;
            if Scr.Screen2BlockCount < 4 then
              Scr.Screen2BlockCount := 4
            else if Scr.Screen2BlockCount > 12 then
              Scr.Screen2BlockCount := 12;
          end;
        rdBlocks2:
          Scr.Screen2BlockCount := 2;
        rdBlocks3:
          Scr.Screen2BlockCount := 3;
        rdBlocks4:
          Scr.Screen2BlockCount := 4;
        rdBlocks5:
          Scr.Screen2BlockCount := 5;
        rdBlocks6:
          Scr.Screen2BlockCount := 6;
        rdBlocks7:
          Scr.Screen2BlockCount := 7;
        rdBlocks8:
          Scr.Screen2BlockCount := 8;
        rdBlocks9:
          Scr.Screen2BlockCount := 9;
        rdBlocks10:
          Scr.Screen2BlockCount := 10;
        rdBlocks11:
          Scr.Screen2BlockCount := 11;
        rdBlocks12:
          Scr.Screen2BlockCount := 12;
      end;

      case FScreenSizeLimit of
        rdBlock1KB:
          Scr.MaxTotalSize := 1024;
        rdBlock2KB:
          Scr.MaxTotalSize := 1024 * 2;
        rdBlock4KB:
          Scr.MaxTotalSize := 1024 * 4;
        rdBlock8KB:
          Scr.MaxTotalSize := 1024 * 8;
        rdBlock12KB:
          Scr.MaxTotalSize := 1024 * 12;
        rdBlock16KB:
          Scr.MaxTotalSize := 1024 * 16;
        rdBlock24KB:
          Scr.MaxTotalSize := 1024 * 24;
        rdBlock32KB:
          Scr.MaxTotalSize := 1024 * 32;
        rdBlock48KB:
          Scr.MaxTotalSize := 1024 * 48;
        rdBlock64KB:
          Scr.MaxTotalSize := 1024 * 64;
        rdBlock96KB:
          Scr.MaxTotalSize := 1024 * 96;
        rdBlock128KB:
          Scr.MaxTotalSize := 1024 * 128;
        rdBlock192KB:
          Scr.MaxTotalSize := 1024 * 192;
        rdBlock256KB:
          Scr.MaxTotalSize := 1024 * 256;
        rdBlock384KB:
          Scr.MaxTotalSize := 1024 * 384;
        rdBlock512KB:
          Scr.MaxTotalSize := 1024 * 512;
      end;

      if FScreenRefineDelay < 0 then
        Scr.Screen2Delay := 0
      else if FScreenRefineDelay = 0 then
        Scr.Screen2Delay := 500
      else
        Scr.Screen2Delay := FScreenRefineDelay * 1000;

      if FShowFullScreen then
        Scr.FullScreen := True
      else
        Scr.FixedRegion := FScreenRect;

      Scr.MouseDriver := FUseMouseDriver;
      Scr.MultiMonitor := FCaptureAllMonitors;

      // Always set the "MirageDriver" property at the end ...
      Scr.MirageDriver := FUseMirrorDriver;

      Scr.FPDesktopHost := Self;
    end;
  finally
    CS.Release;
  end;
end;

procedure TRtcPDesktopHost.ScrStop;
begin
  CS.Acquire;
  try
    if assigned(Scr) then
    begin
      Scr.Free;
      Scr := nil;
    end;
  finally
    CS.Release;
  end;
end;

procedure TRtcPDesktopHost.Restart;
begin
  CS.Acquire;
  try
    if getSubscriberCnt = 0 then
    begin
      ScrStop;
      ScrStart;
    end
    else
      RestartRequested := True;
  finally
    CS.Release;
  end;
  // if assigned(FOnStartHost) then FOnStartHost;
end;

procedure TRtcPDesktopHost.SetFileTrans(const Value: TRtcPFileTransfer);
begin
  if Value <> FFileTrans then
  begin
    if assigned(FFileTrans) then
      FFileTrans.RemModule(self);
    FFileTrans := Value;
    if assigned(FFileTrans) then
      FFileTrans.AddModule(self);
  end;
end;

procedure TRtcPDesktopHost.UnlinkModule(const Module: TRtcPModule);
begin
  if Module = FFileTrans then
    FileTransfer := nil;
  inherited;
end;

procedure TRtcPDesktopHost.CloseAll(Sender: TObject);
begin
  Client.DisbandMyGroup(Sender, 'desk');
end;

procedure TRtcPDesktopHost.Close(const uname: String; Sender: TObject);
begin
  Client.RemoveUserFromMyGroup(Sender, uname, 'desk');
end;

procedure TRtcPDesktopHost.Open(const uname: String; Sender: TObject);
begin
  Client.AddUserToMyGroup(Sender, uname, 'idesk');
end;

function TRtcPDesktopHost.MirrorDriverInstalled(Init: boolean = False): boolean;
var
  s: TRtcScreenCapture;
begin
  CS.Acquire;
  try
    if assigned(Scr) then
      Result := Scr.MirageDriverInstalled(Init)
    else
    begin
      s := TRtcScreenCapture.Create;
      try
        Result := s.MirageDriverInstalled(Init);
      finally
        s.Free;
      end;
    end;
  finally
    CS.Release;
  end;
end;

//FileTrans+
procedure TRtcPDesktopHost.xOnFileReadStart(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadStart(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileRead(Sender, Obj: TObject; Data: TRtcValue);
begin
  FOnFileRead(self, Data.asRecord.asText['user'], Data.asRecord.asText['path'],
    Data.asRecord.asText['folder'], Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileReadUpdate(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadUpdate(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileReadStop(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadStop(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileReadCancel(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadCancel(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileWriteStart(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileWriteStart(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileWrite(Sender, Obj: TObject; Data: TRtcValue);
begin
  FOnFileWrite(self, Data.asRecord.asText['user'], Data.asRecord.asText['path'],
    Data.asRecord.asText['folder'], Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileWriteStop(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileWriteStop(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileWriteCancel(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileWriteCancel(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnCallReceived(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnCallReceived(self, Data.asRecord.asText['user'],
    Data.asRecord.asFunction['data']);
end;

function TRtcPDesktopHost.StartSendingFile(const UserName: String;
  const path: String; idx: integer): boolean;
var
  k: integer;
begin
  CS.Acquire;
  try
    if (PrepareFiles.isType[UserName] = rtc_Array) and
      (PrepareFiles.asArray[UserName].isType[idx] = rtc_Record) and
      (PrepareFiles.asArray[UserName].asRecord[idx].asText['path'] = path) then
    begin
      Result := True;
      File_Sending := True;
      Inc(File_Senders);

      k := SendingFiles.Count;
      SendingFiles.asObject[k] := PrepareFiles.asArray[UserName].asObject[idx];
      PrepareFiles.asArray[UserName].asObject[idx] := nil;
    end
    else
      Result := False;
  finally
    CS.Release;
  end;
end;

function TRtcPDesktopHost.CancelFileSending(Sender:TObject; const uname, FileName,
  folder: String): int64;
var
  fsize: int64;
  idx: integer;

begin
  Result := 0;
  CS.Acquire;
  try
    if (PrepareFiles.Count > 0) then
    begin
      for idx := PrepareFiles.Count - 1 downto 0 do
        if (PrepareFiles.isType[uname] = rtc_Array) and
          (PrepareFiles.asArray[uname].isType[idx] = rtc_Record) and
          (PrepareFiles.asArray[uname].asRecord[idx].asText['path'] = FileName) and
          ( (PrepareFiles.asArray[uname].asRecord[idx].asText['folder'] = folder) or
            (folder = '') ) then
        begin
          // Result:=Result+PrepareFiles.asArray[uname].asRecord[idx].asLargeInt['size'];
          PrepareFiles.asArray[uname].isNull[idx] := True;
        end;
    end;
    if File_Senders > 0 then
    begin
      for idx := SendingFiles.Count - 1 downto 0 do
      begin
        if (SendingFiles.isType[idx] = rtc_Record) and
          (SendingFiles.asRecord[idx].asText['user'] = uname) and
          (SendingFiles.asRecord[idx].asText['path'] = FileName) and
          ( (SendingFiles.asRecord[idx].asText['folder'] = folder) or
            (folder = '') ) then
        begin
          fsize := SendingFiles.asRecord[idx].asLargeInt['size'] -
            SendingFiles.asRecord[idx].asLargeInt['sent'];
          Result := Result + fsize;
          SendingFiles.isNull[idx] := True;

          Dec(File_Senders);
          Event_FileReadCancel(Sender, uname, FileName, folder, fsize);

          if (File_Senders = 0) then
          begin
            SendingFiles.Clear;
            Exit;
          end;
        end;
      end;
    end;
  finally
    CS.Release;
  end;
end;

procedure TRtcPDesktopHost.StopFileSending(Sender: TObject;
  const uname: String);
var
  idx: integer;
begin
  CS.Acquire;
  try
    PrepareFiles.isNull[uname] := True;
    UpdateFiles.isNull[uname] := True;
    if File_Senders > 0 then
    begin
      for idx := SendingFiles.Count - 1 downto 0 do
      begin
        if SendingFiles.isType[idx] = rtc_Record then
        begin
          if SendingFiles.asRecord[idx].asText['user'] = uname then
          begin
            SendingFiles.isNull[idx] := True;
            Dec(File_Senders);
            if File_Senders = 0 then
            begin
              SendingFiles.Clear;
              Exit;
            end;
          end;
        end;
      end;
    end;
  finally
    CS.Release;
  end;
end;

procedure TRtcPDesktopHost.Event_FileReadStart(Sender: TObject;
  const user: String; const fname, fromfolder: String; size: int64);
begin
  if assigned(FOnFileReadStart) then
    CallFileEvent(Sender, xOnFileReadStart, user, fname, fromfolder, size);
end;

procedure TRtcPDesktopHost.Event_FileRead(Sender: TObject; const user: String;
  const fname, fromfolder: String; size: int64);
begin
  if assigned(FOnFileRead) then
    CallFileEvent(Sender, xOnFileRead, user, fname, fromfolder, size);
end;

procedure TRtcPDesktopHost.Event_FileReadUpdate(Sender: TObject;
  const user: String);
begin
  if assigned(FOnFileReadUpdate) then
    CallFileEvent(Sender, xOnFileReadUpdate, user);
end;

procedure TRtcPDesktopHost.Event_FileReadStop(Sender: TObject;
  const user: String; const fname, fromfolder: String; size: int64);
begin
  if assigned(FOnFileReadStop) then
    CallFileEvent(Sender, xOnFileReadStop, user, fname, fromfolder, size);
end;

procedure TRtcPDesktopHost.Event_FileReadCancel(Sender: TObject;
  const user, fname, fromfolder: String; size: int64);
begin
  if assigned(FOnFileReadCancel) then
    CallFileEvent(Sender, xOnFileReadCancel, user, fname, fromfolder, size);
end;

procedure TRtcPDesktopHost.Event_FileWriteStart(Sender: TObject;
  const user: String; const fname, tofolder: String; size: int64);
begin
  if assigned(FOnFileWriteStart) then
    CallFileEvent(Sender, xOnFileWriteStart, user, fname, tofolder, size);
end;

procedure TRtcPDesktopHost.Event_FileWrite(Sender: TObject; const user: String;
  const fname, tofolder: String; size: int64);
begin
  if assigned(FOnFileWrite) then
    CallFileEvent(Sender, xOnFileWrite, user, fname, tofolder, size);
end;

procedure TRtcPDesktopHost.Event_FileWriteStop(Sender: TObject;
  const user: String; const fname, tofolder: String; size: int64);
begin
  if assigned(FOnFileWriteStop) then
    CallFileEvent(Sender, xOnFileWriteStop, user, fname, tofolder, size);
end;

procedure TRtcPDesktopHost.Event_FileWriteCancel(Sender: TObject;
  const user, fname, tofolder: String; size: int64);
begin
  if assigned(FOnFileWriteCancel) then
    CallFileEvent(Sender, xOnFileWriteCancel, user, fname, tofolder, size);
end;

procedure TRtcPDesktopHost.Event_CallReceived(Sender: TObject;
  const user: String; const Data: TRtcFunctionInfo);
begin
  if assigned(FOnCallReceived) then
    CallFileEvent(Sender, xOnCallReceived, user, Data);
end;

procedure TRtcPDesktopHost.CallFileEvent(Sender: TObject;
  Event: TRtcCustomDataEvent; const user: String;
  const FileName, folder: String; size: int64);
var
  Msg: TRtcValue;
begin
  Msg := TRtcValue.Create;
  try
    with Msg.newRecord do
    begin
      asText['user'] := user;
      asText['path'] := FileName;
      asText['folder'] := folder;
      asLargeInt['size'] := size;
    end;
    CallEvent(Sender, Event, Msg);
  finally
    Msg.Free;
  end;
end;

procedure TRtcPDesktopHost.CallFileEvent(Sender: TObject;
  Event: TRtcCustomDataEvent; const user: String);
var
  Msg: TRtcValue;
begin
  Msg := TRtcValue.Create;
  try
    Msg.asText := user;
    CallEvent(Sender, Event, Msg);
  finally
    Msg.Free;
  end;
end;

procedure TRtcPDesktopHost.CallFileEvent(Sender: TObject;
  Event: TRtcCustomDataEvent; const user: String; const Data: TRtcFunctionInfo);
var
  Msg: TRtcValue;
begin
  Msg := TRtcValue.Create;
  try
    with Msg.newRecord do
    begin
      asText['user'] := user;
      asObject['data'] := Data; // temporary set pointer
    end;
    CallEvent(Sender, Event, Msg);
    Msg.asRecord.asObject['data'] := nil; // clear pointer
  finally
    Msg.Free;
  end;
end;

procedure TRtcPDesktopHost.CallFileEvent(Sender: TObject;
  Event: TRtcCustomDataEvent; const user, FolderName: String;
  const Data: TRtcDataSet);
var
  Msg: TRtcValue;
begin
  Msg := TRtcValue.Create;
  try
    with Msg.newRecord do
    begin
      asText['user'] := user;
      asText['folder'] := FolderName;
      asObject['data'] := Data; // temporary set pointer
    end;
    CallEvent(Sender, Event, Msg);
    Msg.asRecord.asObject['data'] := nil; // clear pointer
  finally
    Msg.Free;
  end;
end;

procedure TRtcPDesktopHost.Call(const UserName: String;
  const Data: TRtcFunctionInfo; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'filecmd';
  fn.asString['c'] := 'call';
  fn.asObject['i'] := Data;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopHost.Send(const UserName: String; const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
var
  fn: TRtcFunctionInfo;
  idx: integer;
  dts: TRtcRecord;
begin
  if not isSubscriber(UserName) then
  begin
    CS.Acquire;
    try
      if WantToSendFiles.isType[UserName] = rtc_Null then
        WantToSendFiles.newArray(UserName);

      idx := WantToSendFiles.asArray[UserName].Count;
      with WantToSendFiles.asArray[UserName].newRecord(idx) do
      begin
        asText['file'] := FileName;
        asText['to'] := tofolder;
      end;
    finally
      CS.Release;
    end;

    Open(UserName, Sender);
  end
  else
  begin
    dts := TRtcRecord.Create;
    try
      dts.asText['user'] := UserName;
      dts.asText['path'] := ExtractFileName(FileName);
      dts.asText['folder'] := ExtractFilePath(FileName);
      dts.asText['to'] := tofolder;
      dts.asLargeInt['size'] := File_Content(FileName, dts.newDataSet('files'));
    except
      dts.Free;
      raise;
    end;

    CS.Acquire;
    try
      if PrepareFiles.isType[UserName] = rtc_Null then
        PrepareFiles.newArray(UserName);

      idx := PrepareFiles.asArray[UserName].Count;
      PrepareFiles.asArray[UserName].asObject[idx] := dts;

      fn := TRtcFunctionInfo.Create;
      fn.FunctionName := 'putfile';
      fn.asInteger['id'] := idx;
      fn.asText['path'] := ExtractFileName(FileName);
      fn.asText['to'] := tofolder;
      fn.asLargeInt['size'] := dts.asLargeInt['size'];
    finally
      CS.Release;
    end;

    if assigned(fn) then
      Client.SendToUser(Sender, UserName, fn);
  end;
end;

procedure TRtcPDesktopHost.Fetch(const UserName: String;
  const FileName: String; const tofolder: String = ''; Sender: TObject = nil);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'getfile';
  fn.asText['file'] := FileName;
  fn.asText['to'] := tofolder;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopHost.Cancel_Send(const UserName, FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
var
  fname, ffolder: String;
  fn: TRtcFunctionInfo;
  fsize: int64;
begin
  fname := ExtractFileName(FileName);
  if fname=FileName then
    ffolder:=''
  else
    ffolder := ExtractFilePath(FileName);
  fsize := CancelFileSending(Sender, UserName, fname, ffolder);

  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'filecmd';
  fn.asString['c'] := 'abort';
  fn.asText['file'] := fname;
  fn.asText['to'] := tofolder;
  fn.asLargeInt['size'] := fsize;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopHost.Cancel_Fetch(const UserName, FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'filecmd';
  fn.asString['c'] := 'cancel';
  fn.asText['file'] := FileName;
  fn.asText['to'] := tofolder;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopHost.InitData;
begin
  CS.Acquire;
  try
    SendingFiles.Clear;
    UpdateFiles.Clear;
    PrepareFiles.Clear;
    WantToSendFiles.Clear;

    File_Senders := 0;
    File_Sending := False;
  finally
    CS.Release;
  end;
end;
//FileTrans-

initialization

if not IsWinNT then
  RTC_CAPTUREBLT := 0;

end.
