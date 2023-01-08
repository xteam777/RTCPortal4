unit ServiceMgr;

interface
  uses Windows, Messages, SysUtils, Winsvc, Dialogs, CommonData;

  function ServiceInstalled(AMachine, AService: PChar): Boolean;
  function StartServices(Const  SvrName:String):Boolean;
  function StopServices(Const  SvrName:String):Boolean;
  function QueryService_Status(Const SvrName: String):Integer;
  function CreateServices(Const SvrName, DisplayName, FilePath:String):Boolean;
  function DeleteServices(Const SvrName: String):Boolean;
  function IsServiceExisted(Const SvrName: String):Boolean;
  function IsServiceStarting(const ServiceName:String): Boolean;
  function IsServiceStarted(const ServiceName:String): Boolean;
  function IsServiceDisabled(const ServiceName:String): Boolean;
  function IsDesktopMode(const ServiceName: String): Boolean;
  function UninstallService(aServiceName: String; aTimeOut: Cardinal): Boolean;

implementation

function ServiceInstalled(AMachine, AService: PChar): Boolean;
var
  hManager, hSvc: SC_Handle;
begin
  Result := False;
  hManager := OpenSCManager(AMachine, nil, SC_MANAGER_CONNECT);
  if hManager > 0 then
  begin
    hSvc := OpenService(hManager, AService, SERVICE_QUERY_STATUS);
    if hSvc > 0 then
      Result := True;
    CloseServiceHandle(hManager);
    CloseServiceHandle(hSvc)
  end;
end;

function StartServices(Const SvrName: String): Boolean;
var
  sMgr, sHandle:SC_HANDLE;
  c:PChar;
begin
  Result:=False;

  sMgr := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if sMgr <=0 then Exit;

  sHandle := OpenService(sMgr, PChar(SvrName), SERVICE_ALL_ACCESS);
  if sHandle <=0 then Exit;

  try
    Result:=StartService(sHandle, 0, c);
    CloseServiceHandle(sHandle);
    CloseServiceHandle(sMgr);
  except
    CloseServiceHandle(sHandle);
    CloseServiceHandle(sMgr);
  end;
end;

function StopServices(Const SvrName: String): Boolean;
var
  sMgr, sHandle: SC_HANDLE;
  d: TServiceStatus;
begin
  Result := False;

  sMgr := OpenSCManager(nil,nil,SC_MANAGER_ALL_ACCESS);
  if sMgr <=0 then Exit;
  sHandle := OpenService(sMgr,PChar(SvrName),SERVICE_ALL_ACCESS);
  if sHandle <=0 then Exit;
  try
    Result:=ControlService(sHandle, SERVICE_CONTROL_STOP,d);
    CloseServiceHandle(sMgr);
    CloseServiceHandle(sHandle);
  except
    CloseServiceHandle(sMgr);
    CloseServiceHandle(sHandle);
  end;
end;

function QueryService_Status(Const SvrName: String): Integer;
var
  sMgr, sHandle: SC_HANDLE;
  d: TServiceStatus;
begin
  Result := 0;

  sMgr := OpenSCManager(nil,nil,SC_MANAGER_ALL_ACCESS);
  if sMgr <=0 then Exit;
  sHandle := OpenService(sMgr,PChar(SvrName),SERVICE_ALL_ACCESS);

  if sHandle <= 0 then Exit;
  try
    QueryServiceStatus(sHandle, d);
//    if d.dwCurrentState  = SERVICE_RUNNING then
//      Result := 'Run'   //Run
//    else if d.dwCurrentState   = SERVICE_RUNNING then
//      Result := 'Runing'   //Runing
//    else if d.dwCurrentState   = SERVICE_START_PENDING then
//      Result := 'Pause'   //Pause
//    else if d.dwCurrentState   = SERVICE_STOP_PENDING   then
//      Result := 'Pause'   //Pause
//    else if d.dwCurrentState   = SERVICE_PAUSED then
//      Result := 'Pause'   //Pause
//    else if d.dwCurrentState   = SERVICE_STOPPED then
//      Result := 'Stop'   //Stop
//    else if d.dwCurrentState   = SERVICE_CONTINUE_PENDING   then
//      Result := 'Wait'   //Pause
//    else if d.dwCurrentState   = SERVICE_PAUSE_PENDING then
//      Result := 'Wait';   //Pause

    Result := d.dwCurrentState;

    CloseServiceHandle(sMgr);
    CloseServiceHandle(sHandle);
  except
    CloseServiceHandle(sMgr);
    CloseServiceHandle(sHandle);
  end;
end;

function CreateServices(Const SvrName, DisplayName, FilePath: String): Boolean;
var
  sMgr, sHandle:SC_HANDLE;
begin
  Result:=False;
  if FilePath = '' then Exit;

  sMgr := OpenSCManager(nil,nil,SC_MANAGER_CREATE_SERVICE);

  if sMgr <= 0 then Exit;
  try
    sHandle := CreateService(sMgr, PChar(SvrName),
    PChar(DisplayName),
    SERVICE_ALL_ACCESS,
    SERVICE_INTERACTIVE_PROCESS or SERVICE_WIN32_OWN_PROCESS,
    SERVICE_AUTO_START,SERVICE_ERROR_NORMAL,
    PChar(FilePath),nil,nil,nil,nil,nil);
    if sHandle <= 0 then begin
      ShowMessage( SysErrorMessage(GetlastError));
      Exit;
    end;
    CloseServiceHandle(sMgr);
    CloseServiceHandle(sHandle);

    Result := True;
  except
    CloseServiceHandle(sMgr);
    CloseServiceHandle(sHandle);
    Exit;
  end;
end;

function DeleteServices(Const SvrName: String): Boolean;
var
  sMgr, sHandle:SC_HANDLE;
begin
  Result:=False;
  sMgr := OpenSCManager(nil,nil,SC_MANAGER_ALL_ACCESS);
  if sMgr <= 0 then  Exit;
  sHandle :=OpenService(sMgr,PChar(SvrName),STANDARD_RIGHTS_REQUIRED);
  if sHandle <= 0 then Exit;
  try
    Result := DeleteService(sHandle);

    if not Result then
      ShowMessage(SysErrorMessage(GetlastError));
    CloseServiceHandle(sHandle);
    CloseServiceHandle(sMgr);
  except
    CloseServiceHandle(sHandle);
    CloseServiceHandle(sMgr);
    Exit;
  end;
end;

function UninstallService(aServiceName: String; aTimeOut: Cardinal): Boolean;
var
    ComputerName: array[0..MAX_COMPUTERNAME_LENGTH + 1] of Char;
    ComputerNameLength, StartTickCount: Cardinal;
    SCM: SC_HANDLE;
    ServiceHandle: SC_HANDLE;
    ServiceStatus: TServiceStatus;

begin
    Result:= False;

    ComputerNameLength:= MAX_COMPUTERNAME_LENGTH + 1;
    if (Windows.GetComputerName(ComputerName, ComputerNameLength)) then
    begin
        SCM:= OpenSCManager(ComputerName, nil, SC_MANAGER_ALL_ACCESS);
        if (SCM <> 0) then
        begin
            try
                ServiceHandle:= OpenService(SCM, PChar(aServiceName), SERVICE_ALL_ACCESS);
                if (ServiceHandle <> 0) then
                begin

                    // make sure service is stopped
                    QueryServiceStatus(ServiceHandle, ServiceStatus);
                    if (not (ServiceStatus.dwCurrentState in [0, SERVICE_STOPPED])) then
                    begin
                        // Stop service
                        ControlService(ServiceHandle, SERVICE_CONTROL_STOP, ServiceStatus);
                    end;

                    // wait for service to be stopped
                    StartTickCount:= GetTickCount;
                    QueryServiceStatus(ServiceHandle, ServiceStatus);
                    if (ServiceStatus.dwCurrentState <> SERVICE_STOPPED) then
                    begin
                        repeat
                            Sleep(1000);
                            QueryServiceStatus(ServiceHandle, ServiceStatus);
                        until (ServiceStatus.dwCurrentState = SERVICE_STOPPED) or ((GetTickCount - StartTickCount) > aTimeout) or (aTimeout = 0)
                    end;

                    Result:= DeleteService(ServiceHandle);
                    CloseServiceHandle(ServiceHandle);
                end;
            finally
                CloseServiceHandle(SCM);
            end;
        end;
    end;
end;

function IsServiceExisted(Const SvrName: String):Boolean;
var
  sMgr, sHandle: SC_HANDLE;
begin
  Result := False;
  sMgr := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if sMgr <= 0 then
    Exit;
  sHandle := OpenService(sMgr, PChar(SvrName), STANDARD_RIGHTS_REQUIRED);
  if sHandle > 0 then
    Result := True;
end;

function IsServiceStarting(const ServiceName:String): Boolean;
var
  Svc: Integer;
  SvcMgr: Integer;
  ServSt: TServiceStatus;
begin
  Result := False;
  SvcMgr := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if SvcMgr = 0 then Exit;
  try
    Svc := OpenService(SvcMgr, PChar(ServiceName), SERVICE_QUERY_STATUS);
    if Svc = 0 then
      Exit;
    try
      if not QueryServiceStatus(Svc, ServSt) then
        Exit;
      Result := (ServSt.dwCurrentState = SERVICE_START_PENDING);
    finally
      CloseServiceHandle(Svc);
    end;
  finally
    CloseServiceHandle(SvcMgr);
  end;
end;

function IsServiceStarted(const ServiceName:String): Boolean;
var
  Svc: Integer;
  SvcMgr: Integer;
  ServSt: TServiceStatus;
begin
  Result := False;
  SvcMgr := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if SvcMgr = 0 then Exit;
  try
    Svc := OpenService(SvcMgr, PChar(ServiceName), SERVICE_QUERY_STATUS);
    if Svc = 0 then
      Exit;
    try
      if not QueryServiceStatus(Svc, ServSt) then
        Exit;
      Result := (ServSt.dwCurrentState = SERVICE_RUNNING);
    finally
      CloseServiceHandle(Svc);
    end;
  finally
    CloseServiceHandle(SvcMgr);
  end;
end;

function IsServiceDisabled(const ServiceName:String): Boolean;
var
  Svc: Integer;
  SvcMgr: Integer;
  Buffer: PQueryServiceConfig;
  BytesNeeded: DWORD;
  err: Integer;
begin
  Result := False;
  SvcMgr := OpenSCManager(nil, nil, SC_MANAGER_CONNECT or SC_MANAGER_ENUMERATE_SERVICE);
  if SvcMgr = 0 then Exit;
  try
    Svc := OpenService(SvcMgr, PChar(ServiceName), SERVICE_QUERY_CONFIG);
    if Svc = 0 then
      Exit;
    try
      Buffer := nil;
      Assert(QueryServiceConfig(Svc, nil, 0, BytesNeeded) = False);
      err := GetLastError;
      if err <> ERROR_INSUFFICIENT_BUFFER then
        Exit;
      GetMem(Buffer, BytesNeeded);

      QueryServiceConfig(Svc, Buffer, BytesNeeded, BytesNeeded);
      err := GetLastError;
      if err <> ERROR_INSUFFICIENT_BUFFER then
        Exit;
      Result := (Buffer.dwStartType = SERVICE_DISABLED);
    finally
      FreeMem(Buffer);
      CloseServiceHandle(Svc);
    end;
  finally
    CloseServiceHandle(SvcMgr);
  end;
end;

function IsDesktopMode(const ServiceName: String): Boolean;
begin
  if (Win32Platform <> VER_PLATFORM_WIN32_NT) then
    Result := True
  else
    Result := (CurrentSessionId <> 0);
//    Result := (not FindCmdLineSwitch('INSTALL', ['-', '/'], True) and
//                not FindCmdLineSwitch('UNINSTALL', ['-', '/'], True) and
//                not IsServiceStarting(ServiceName) and
//                not IsServiceStarted(ServiceName))
//                or FindCmdLineSwitch('SILENT', ['-', '/'], True);
end;

end.
