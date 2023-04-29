unit ScalingUtils;

interface

uses
  {$IFDEF FPC}
  Forms
  {$ELSE}
  Vcl.Forms
  {$ENDIF};

type
  TDzFormScaling = class
  private
    Form: TCustomForm;
  public
    Scaled: Boolean;
    DesignerPPI, MonitorPPI: Integer;

    constructor Create(Form: TCustomForm);
    procedure Update;
    function Calc(Value: Integer): Integer;
  end;

implementation

uses
  {$IFDEF FPC}
  SysUtils, Windows
  {$ELSE}
  System.SysUtils, Winapi.Windows, Winapi.MultiMon
  {$ENDIF};

type
  TMonitorDpiType = (
    MDT_EFFECTIVE_DPI = 0,
    MDT_ANGULAR_DPI = 1,
    MDT_RAW_DPI = 2,
    MDT_DEFAULT = MDT_EFFECTIVE_DPI
  );

{$WARN SYMBOL_PLATFORM OFF}
function GetDpiForMonitor(
  hmonitor: HMONITOR;
  dpiType: TMonitorDpiType;
  out dpiX: UINT;
  out dpiY: UINT
  ): HRESULT; stdcall; external 'Shcore.dll' {$IFDEF DCC}delayed{$ENDIF};
{$WARN SYMBOL_PLATFORM ON}

function GetMonitorPPI(FHandle: HMONITOR): Integer;
var
  Ydpi: Cardinal;
  Xdpi: Cardinal;
  DC: HDC;
begin
  if CheckWin32Version(6,3) then
  begin
    if GetDpiForMonitor(FHandle, TMonitorDpiType.MDT_EFFECTIVE_DPI, Ydpi, Xdpi) = S_OK then
      Result := Ydpi
    else
      Result := 0;
  end
  else
  begin
    DC := GetDC(0);
    Result := GetDeviceCaps(DC, LOGPIXELSY);
    ReleaseDC(0, DC);
  end;
end;

//

const DEFAULT_PPI = 96;

type
  TFormScaleHack = class(TCustomForm);

function GetDesignerPPI(F: TCustomForm): Integer;
begin
  Result :=
    {$IFDEF FPC}
    F.PixelsPerInch
    {$ELSE}
      {$IF CompilerVersion >= 31} //D10.1 Berlin
      TFormScaleHack(F).GetDesignDpi
      {$ELSE}
      TFormScaleHack(F).PixelsPerInch
      {$ENDIF}
    {$ENDIF};
end;

constructor TDzFormScaling.Create(Form: TCustomForm);
begin
  Self.Form := Form;
end;

procedure TDzFormScaling.Update;
begin
  if Form<>nil then
  begin
    Scaled := TFormScaleHack(Form).Scaled;
    DesignerPPI := GetDesignerPPI(Form);
    MonitorPPI := GetMonitorPPI(Form.Monitor.Handle);
  end else
  begin
    Scaled := False;
    DesignerPPI := DEFAULT_PPI;
    MonitorPPI := DEFAULT_PPI;
  end;
end;

function TDzFormScaling.Calc(Value: Integer): Integer;
begin
  if Scaled then
    Result := MulDiv(Value, MonitorPPI, DesignerPPI) //{$IFDEF FPC}ScaleDesignToForm(Value){$ELSE}ScaleValue(Value){$ENDIF} - only supported in Delphi 10.4 (Monitor.PixelsPerInch supported too)
  else
    Result := Value;
end;

end.
