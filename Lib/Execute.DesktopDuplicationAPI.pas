unit Execute.DesktopDuplicationAPI;
{
  Desktop Duplication (c)2017 Execute SARL
  http://www.execute.fr
}
{$INLINE AUTO}
interface

uses
  Winapi.Windows,
  DX12.D3D11,
  DX12.D3DCommon,
  DX12.DXGI,
  DX12.DXGI1_2,
  Vcl.Graphics,
  Math;
//  , rtcLog, SysUtils;

type
{$POINTERMATH ON} // Pointer[x]
  TDesktopDuplicationWrapper = class
  private
    FError: HRESULT;
  // D3D11
    FDevice: ID3D11Device;
    FContext: ID3D11DeviceContext;
    FFeatureLevel: TD3D_FEATURE_LEVEL;
  // DGI
    FOutput: TDXGI_OUTPUT_DESC;
    FDuplicate: IDXGIOutputDuplication;
    FTexture: ID3D11Texture2D;
  // update information
    FMetaData: array of Byte;
    FMoveRects: PDXGI_OUTDUPL_MOVE_RECT; // array of
    FMoveCount: Integer;
    FDirtyRects: PRECT; // array of
    FDirtyCount: Integer;

    BytesInRow : integer;
    BitmapP1, BitmapP2 : PByte;
    FirstDraw : boolean;
    FLastChangedX1, FLastChangedY1, FLastChangedX2, FLastChangedY2: Integer;
    procedure DrawArea(X1, Y1, X2, Y2 : Integer; aPixelFormat: TPixelFormat); //inline;

  public
    Bitmap: TBitmap;
    OptimDrawAlg : integer; // 0 - default, 1 - draw algorithm #1, 2 - draw algorithm #2
    constructor Create(var fCreated: Boolean);
    destructor Destroy; override;
    function GetFrame(var fNeedRecreate: Boolean): Boolean;
    function DrawFrame(var Bitmap: TBitmap; aPixelFormat: TPixelFormat = pf32bit): Boolean;
//    function DrawFrameToDib(pBits: PByte): Boolean;
//    procedure FreeDIB(BitmapInfo: PBitmapInfo;
//      InfoSize: DWORD;
//      Bits: pointer;
//      BitsSize: DWORD);
//    procedure BitmapToDIB(Bitmap: TBitmap;
//      var BitmapInfo: PBitmapInfo;
//      var InfoHeaderSize: DWORD;
//      var Bits: pointer;
//      var ImageSize: DWORD);
    property Error: HRESULT read FError;
    property MoveCount: Integer read FMoveCount;
    property MoveRects: PDXGI_OUTDUPL_MOVE_RECT read FMoveRects;
    property DirtyCount: Integer read FDirtyCount;
    property DirtyRects: PRect read FDirtyRects;
    property LastChangedX1: Integer read FLastChangedX1;
    property LastChangedY1: Integer read FLastChangedY1;
    property LastChangedX2: Integer read FLastChangedX2;
    property LastChangedY2: Integer read FLastChangedY2;
  end;

implementation

{ TDesktopDuplicationWrapper }

function GetBitsPerPixel(aBitsPerPixel: TPixelFormat): Word;
begin
  case aBitsPerPixel of
    pf1bit: Result := 1;
    pf4bit: Result := 4;
    pf8bit: Result := 8;
    pf15bit: Result := 15;
    pf16bit: Result := 16;
    pf24bit: Result := 24;
    pf32bit: Result := 32;
    else Result := 32;
  end;
end;

constructor TDesktopDuplicationWrapper.Create(var fCreated: Boolean);
var
  GI: IDXGIDevice;
  GA: IDXGIAdapter;
  GO: IDXGIOutput;
  O1: IDXGIOutput1;
begin
  fCreated := False;

  OptimDrawAlg := 3;

  FirstDraw := True;

//  Sleep(10000);
  FError := D3D11CreateDevice(
    nil, // Default adapter
    D3D_DRIVER_TYPE_HARDWARE, // A hardware driver, which implements Direct3D features in hardware.
    0,
    Ord(D3D11_CREATE_DEVICE_SINGLETHREADED),
    nil, 0, // default feature
    D3D11_SDK_VERSION,
    FDevice,
    FFeatureLevel,
    FContext
  );
  if Failed(FError) then
  begin
    fCreated := False;
//    xLog('D3D11CreateDevice Error: ' + SysErrorMessage(FError));
    Exit;
  end;

  FError := FDevice.QueryInterface(IID_IDXGIDevice, GI);
  if Failed(FError) then
  begin
    fCreated := False;
//    xLog('QueryInterface IID_IDXGIDevice Error: ' + SysErrorMessage(FError));
    Exit;
  end;

  FError := GI.GetParent(IID_IDXGIAdapter, Pointer(GA));
  if Failed(FError) then
  begin
    fCreated := False;
//    xLog('GI.GetParent Error: ' + SysErrorMessage(FError));
    Exit;
  end;

  FError := GA.EnumOutputs(0, GO);
  if Failed(FError) then
  begin
    fCreated := False;
//    xLog('EnumOutputs Error: ' + SysErrorMessage(FError));
    Exit;
  end;

  FError := GO.GetDesc(FOutput);
  if Failed(FError) then
  begin
    fCreated := False;
//    xLog('GetDesc Error: ' + SysErrorMessage(FError));
    Exit;
  end;

  FError := GO.QueryInterface(IID_IDXGIOutput1, O1);
  if Failed(FError) then
  begin
    fCreated := False;
//    xLog('QueryInterface IID_IDXGIOutput1 Error: ' + SysErrorMessage(FError));
    Exit;
  end;

  FError := O1.DuplicateOutput(FDevice, FDuplicate);
  if Failed(FError) then
  begin
    fCreated := False;
//    xLog('DuplicateOutput Error: ' + SysErrorMessage(FError));
    Exit;
  end;

  fCreated := True;
end;

destructor TDesktopDuplicationWrapper.Destroy;
begin
  inherited;

  if FTexture <> nil then
    FTexture := nil;

  if Bitmap <> nil then
    Bitmap.Free;
end;

function TDesktopDuplicationWrapper.GetFrame(var fNeedRecreate: Boolean): Boolean;
var
  FrameInfo: TDXGI_OUTDUPL_FRAME_INFO;
  DesktopResource: IDXGIResource;
  BufLen : Integer;
  BufSize: Uint;
begin
  Result := False;
  fNeedRecreate := False;

  if FDuplicate = nil then
  begin
    fNeedRecreate := True;
    Exit;
  end
  else
    FDuplicate.ReleaseFrame;

  Sleep(1);

  DesktopResource := nil;

  FError := FDuplicate.AcquireNextFrame(500, FrameInfo, DesktopResource);
  if Failed(FError) then
  begin
//    xLog('AcquireNextFrame Error: ' + SysErrorMessage(FError));
//    if FError = DXGI_ERROR_ACCESS_LOST then
      fNeedRecreate := True;

    Exit;
  end;

  if FTexture <> nil then
    FTexture := nil;

  FError := DesktopResource.QueryInterface(IID_ID3D11Texture2D, FTexture);
  DesktopResource := nil;
  if Failed(FError) then
  begin
//    xLog('QueryInterface.IID_ID3D11Texture2D Error: ' + SysErrorMessage(FError));
    Exit;
  end;

  if FrameInfo.TotalMetadataBufferSize > 0 then
  begin
    BufLen := FrameInfo.TotalMetadataBufferSize;
    if Length(FMetaData) < BufLen then
      SetLength(FMetaData, BufLen);

    FMoveRects := Pointer(FMetaData);

    FError := FDuplicate.GetFrameMoveRects(BufLen, FMoveRects, BufSize);
    if Failed(FError) then
      Exit;
    FMoveCount := BufSize div sizeof(TDXGI_OUTDUPL_MOVE_RECT);

    FDirtyRects := @FMetaData[BufSize];
    Dec(BufLen, BufSize);

    FError := FDuplicate.GetFrameDirtyRects(BufLen, FDirtyRects, BufSize);
    if Failed(FError) then
     Exit;
    FDirtyCount := BufSize div SizeOf(TRECT);

    Result := True;
  end
  else
    FDuplicate.ReleaseFrame;
end;

procedure TDesktopDuplicationWrapper.DrawArea(X1, Y1, X2, Y2 : Integer; aPixelFormat: TPixelFormat); //inline;
var
  i, BytesToCopy : integer;
  P1Cur, P2Cur : PByte;
begin
  P1Cur := BitmapP1 + (X1 shl 2) + Y1 * BytesInRow;
  P2Cur := BitmapP2 + (X1 shl 2) - Y1 * BytesInRow;
  BytesToCopy := (X2 - X1) * GetBitsPerPixel(aPixelFormat) shr 3;
  if (((X2 - X1) * GetBitsPerPixel(aPixelFormat) mod 8) <> 0) then
    Inc(BytesToCopy);

  for i := Y1 to Y2 - 1 do
  begin
    Move(P1Cur^, P2Cur^, BytesToCopy);
    Inc(P1Cur, BytesInRow);
    Dec(P2Cur, BytesInRow);
  end;
end;

function TDesktopDuplicationWrapper.DrawFrame(var Bitmap: TBitmap; aPixelFormat: TPixelFormat = pf32bit): Boolean;
var
  Desc: TD3D11_TEXTURE2D_DESC;
  Temp: ID3D11Texture2D;
  Resource: TD3D11_MAPPED_SUBRESOURCE;
  i, RId: Integer;
  p : pbyte;
begin
  Result := False;

  FLastChangedX1 := 0;
  FLastChangedY1 := 0;
  FLastChangedX2 := 0;
  FLastChangedY2 := 0;

  FTexture.GetDesc(Desc);

  if Bitmap = nil then
    Bitmap := TBitmap.Create;

  Bitmap.PixelFormat := pf32bit;
//  Bitmap.PixelFormat := aPixelFormat;
  Bitmap.SetSize(Desc.Width, Desc.Height);

  Desc.BindFlags := 0;
  Desc.CPUAccessFlags := Ord(D3D11_CPU_ACCESS_READ) or Ord(D3D11_CPU_ACCESS_WRITE);
  Desc.Usage := D3D11_USAGE_STAGING;
  Desc.MiscFlags := 0;

  //  READ/WRITE texture
  FError := FDevice.CreateTexture2D(@Desc, nil, Temp);
  if Failed(FError) then
  begin
//    xLog('CreateTexture2D Error: ' + SysErrorMessage(FError));
    FTexture := nil;
    FDuplicate.ReleaseFrame;

    Exit;
  end;

  // copy original to the RW texture
  FContext.CopyResource(Temp, FTexture);

  // get texture bits
  FContext.Map(Temp, 0, D3D11_MAP_READ_WRITE, 0, Resource);

  //BytesInRow := Desc.Width shl 2;
  //BytesInRow := Desc.Width * GetBitsPerPixel(aPixelFormat) div 8;
  BytesInRow := Desc.Width * GetBitsPerPixel(aPixelFormat) shr 3;
  if ((Desc.Width * GetBitsPerPixel(aPixelFormat) mod 8) <> 0) then
    Inc(BytesInRow);
  BitmapP1 := Resource.pData;
  BitmapP2 := Bitmap.ScanLine[0];

{  if FirstDraw
    or ((MoveCount + DirtyCount = 0)) then
  begin
    FirstDraw := false;

    FLastChangedX1 := 0;
    FLastChangedY1 := 0;
    FLastChangedX2 := Desc.Width;
    FLastChangedY2 := Desc.Height;

    DrawArea(0, 0, Desc.Width, Desc.Height, aPixelFormat);
  end else
    case OptimDrawAlg of
    0 : begin // default algorithm
          FLastChangedX1 := 0;
          FLastChangedY1 := 0;
          FLastChangedX2 := Desc.Width;
          FLastChangedY2 := Desc.Height;

          DrawArea(0, 0, Desc.Width, Desc.Height, aPixelFormat);
        end;
    1 : begin // objects almost do not cross with each other

          // Painting MoveRects
          for RId := 0 to MoveCount - 1 do
            DrawArea(Min(MoveRects[RId].SourcePoint.X, MoveRects[RId].DestinationRect.Left),
              Min(MoveRects[RId].SourcePoint.Y, MoveRects[RId].DestinationRect.Top),
              Max(MoveRects[RId].SourcePoint.X + MoveRects[RId].DestinationRect.Right - MoveRects[RId].DestinationRect.Left, MoveRects[RId].DestinationRect.Right),
              Max(MoveRects[RId].SourcePoint.Y + MoveRects[RId].DestinationRect.Bottom - MoveRects[RId].DestinationRect.Top, MoveRects[RId].DestinationRect.Bottom), aPixelFormat);

        FLastChangedX1 := 0;
        FLastChangedY1 := 0;
        FLastChangedX2 := Desc.Width;
        FLastChangedY2 := Desc.Height;

          // Painting DirtyRects
          for RId := 0 to DirtyCount - 1 do
            DrawArea(DirtyRects[RId].Left, DirtyRects[RId].Top,
                     DirtyRects[RId].Right, DirtyRects[RId].Bottom, aPixelFormat);

        end;
    2 : begin // objects crosses with each other much
          // Ischem koordinati priamougolnika, kotorii vkluchaet
          // vse priamougolniki MoveRects i DrityRects
          FLastChangedX1 := 1 shl 30;
          FLastChangedY1 := 1 shl 30;
          FLastChangedX2 := 0;
          FLastChangedY2 := 0;

          for RId := 0 to MoveCount - 1 do
          begin
            FLastChangedX1 := Min(FLastChangedX1, Min(MoveRects[RId].SourcePoint.X, MoveRects[RId].DestinationRect.Left));
            FLastChangedY1 := Min(FLastChangedY1, Min(MoveRects[RId].SourcePoint.Y, MoveRects[RId].DestinationRect.Top));
            FLastChangedX2 := Max(FLastChangedX2, Max(MoveRects[RId].SourcePoint.X + MoveRects[RId].DestinationRect.Right - MoveRects[RId].DestinationRect.Left, MoveRects[RId].DestinationRect.Right));
            FLastChangedY2 := Max(FLastChangedY2, Max(MoveRects[RId].SourcePoint.Y + MoveRects[RId].DestinationRect.Bottom - MoveRects[RId].DestinationRect.Top, MoveRects[RId].DestinationRect.Bottom));
          end;

          for RId := 0 to DirtyCount - 1 do
          begin
            FLastChangedX1 := Min(FLastChangedX1, DirtyRects[RId].Left);
            FLastChangedY1 := Min(FLastChangedY1, DirtyRects[RId].Top);
            FLastChangedX2 := Max(FLastChangedX2, DirtyRects[RId].Right);
            FLastChangedY2 := Max(FLastChangedY2, DirtyRects[RId].Bottom);
          end;

          DrawArea(FLastChangedX1, FLastChangedY1, FLastChangedX2, FLastChangedY2, aPixelFormat);
        end;
    3:  begin}
          // copy pixels - we assume a 32bits bitmap !
         for i := 0 to Desc.Height - 1 do
          begin
            Move(BitmapP1^, Bitmap.ScanLine[i]^, 4 * Desc.Width);
            Inc(BitmapP1, 4 * Desc.Width);
          end;
//          for i := 0 to Desc.Height - 1 do
//          begin
//            Move(BitmapP1^, Bitmap.ScanLine[i]^, BytesInRow);
//            Inc(BitmapP1, BytesInRow);
//          end;

          FLastChangedX1 := 0;
          FLastChangedY1 := 0;
          FLastChangedX2 := Desc.Width;
          FLastChangedY2 := Desc.Height;
      {end;
    end; }

  FContext.Unmap(FTexture, 0); //Это нужно?
  FTexture := nil;
  FDuplicate.ReleaseFrame;

  Result := True;
end;

//procedure TDesktopDuplicationWrapper.FreeDIB(BitmapInfo: PBitmapInfo;
//  InfoSize: DWORD;
//  Bits: pointer;
//  BitsSize: DWORD);
//begin
//  if BitmapInfo <> nil then
//    FreeMem(BitmapInfo, InfoSize);
////  if Bits <> nil then
////    GlobalFreePtr(Bits);
//end;
//
//procedure TDesktopDuplicationWrapper.BitmapToDIB(Bitmap: TBitmap;
//  var BitmapInfo: PBitmapInfo;
//  var InfoHeaderSize: DWORD;
//  var Bits: pointer;
//  var ImageSize: DWORD);
//begin
//  BitmapInfo := nil;
//  InfoHeaderSize := 0;
////  Bits := nil;
//  ImageSize := 0;
//  if not Bitmap.Empty then
//  try
//    GetDIBSizes(Bitmap.Handle, InfoHeaderSize, ImageSize);
//    GetMem(BitmapInfo, InfoHeaderSize);
////    Bits := GlobalAllocPtr(GMEM_MOVEABLE, ImageSize);
////    if Bits = nil then
////      raise
////        EOutOfMemory.Create('Не хватает памяти для пикселей изображения');
////      Exit;
//    if not GetDIB(Bitmap.Handle, Bitmap.Palette, BitmapInfo^, Bits^) then
//      //raise Exception.Create('Не могу создать DIB');
//      Exit;
//  finally
//    if BitmapInfo <> nil then
//      FreeMem(BitmapInfo, InfoHeaderSize);
////    if Bits <> nil then
////      GlobalFreePtr(Bits);
//    BitmapInfo := nil;
////    Bits := nil;
//  end;
//end;

//function TDesktopDuplicationWrapper.DrawFrameToDib(pBits: PByte): Boolean;
//var
//  Desc: TD3D11_TEXTURE2D_DESC;
//  Temp: ID3D11Texture2D;
//  Resource: TD3D11_MAPPED_SUBRESOURCE;
//  i: Integer;
//  p: PByte;
////  pDest: PByte;
////  Bitmap: TBitmap;
//  InfoHeaderSize: DWORD;
//  ImageSize: DWORD ;
//  BitmapInfo: PBitmapInfo;
//begin
//  Result := True;
//
//  FTexture.GetDesc(Desc);
//
//  if Bitmap = nil then
//    Bitmap := TBitmap.Create;
//
//  Bitmap.PixelFormat := pf32Bit;
//  Bitmap.SetSize(Desc.Width, Desc.Height);
//
//  Desc.BindFlags := 0;
//  Desc.CPUAccessFlags := Ord(D3D11_CPU_ACCESS_READ) or Ord(D3D11_CPU_ACCESS_WRITE);
//  Desc.Usage := D3D11_USAGE_STAGING;
//  Desc.MiscFlags := 0;
//
//  //  READ/WRITE texture
//  FError := FDevice.CreateTexture2D(@Desc, nil, Temp);
//  if Failed(FError) then
//  begin
//    FTexture := nil;
//    FDuplicate.ReleaseFrame;
//
//    Result := False;
//    Exit;
//  end;
//
//  // copy original to the RW texture
//  FContext.CopyResource(Temp, FTexture);
//
//  // get texture bits
//  FContext.Map(Temp, 0, D3D11_MAP_READ_WRITE, 0, Resource);
//  p := Resource.pData;
//
////  CopyMemory(pBits, p, 4 * Desc.Width * Desc.Height);
////  Move(p^, pBits^, 4 * Desc.Width * Desc.Height);
//
//  // copy pixels - we assume a 32bits bitmap !
//  for i := 0 to Desc.Height - 1 do
//  begin
//    Move(p^, Bitmap.ScanLine[i]^, 4 * Desc.Width);
//    Inc(p, 4 * Desc.Width);
//  end;
//
////  pDest := pBits;
////  for i := 0 to Desc.Height - 1 do
////  begin
////    Move(p^, pDest^, 4 * Desc.Width);
////    Inc(p, 4 * Desc.Width);
////    Inc(pDest, 4 * Desc.Width);
////  end;
//
////  Bitmap.SaveToFile('C:\Rufus\dda.bmp');
//
////  BitmapToDIB(Bitmap,
////    BitmapInfo,
////    InfoHeaderSize,
////    pBits,
////    ImageSize);
//
////  FreeDIB(BitmapInfo, InfoHeaderSize, pBits, ImageSize);
//
//  FTexture := nil;
//  FDuplicate.ReleaseFrame;
//end;

//function TDesktopDuplicationWrapper.GetFrame(var fNeedRecreate: Boolean): Boolean;  //Original
//var
//  FrameInfo: TDXGI_OUTDUPL_FRAME_INFO;
//  Resource: IDXGIResource;
//  BufLen : Integer;
//  BufSize: Uint;
//begin
//  Result := False;
//
//  if FTexture <> nil then
//  begin
//    FTexture := nil;
//    FDuplicate.ReleaseFrame;
//  end;
//
//  FError := FDuplicate.AcquireNextFrame(0, FrameInfo, Resource);
//  if Failed(FError) then
//  begin
////    if FError = DXGI_ERROR_ACCESS_LOST then
////      fNeedRecreate := True;
//
//    Exit;
//  end;
//
//  if FrameInfo.TotalMetadataBufferSize > 0 then
//  begin
//    FError := Resource.QueryInterface(IID_ID3D11Texture2D, FTexture);
//    if failed(FError) then
//      Exit;
//
//    Resource := nil;
//
//    BufLen := FrameInfo.TotalMetadataBufferSize;
//    if Length(FMetaData) < BufLen then
//      SetLength(FMetaData, BufLen);
//
//    FMoveRects := Pointer(FMetaData);
//
//    FError := FDuplicate.GetFrameMoveRects(BufLen, FMoveRects, BufSize);
//    if Failed(FError) then
//      Exit;
//    FMoveCount := BufSize div sizeof(TDXGI_OUTDUPL_MOVE_RECT);
//
//    FDirtyRects := @FMetaData[BufSize];
//    Dec(BufLen, BufSize);
//
//    FError := FDuplicate.GetFrameDirtyRects(BufLen, FDirtyRects, BufSize);
//    if Failed(FError) then
//      Exit;
//    FDirtyCount := BufSize div sizeof(TRECT);
//
//    Result := True;
//  end else begin
//    FDuplicate.ReleaseFrame;
//  end;
//end;

end.
