// The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); 
// you may not use this file except in compliance with the License. You may obtain a copy of the 
// License at http://www.mozilla.org/MPL/ 
// 
// Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF 
// ANY KIND, either express or implied. See the License for the specificlanguage governing rights and 
// limitations under the License.

// $Id: IniFiles.pas 76 2006-03-27 01:20:58Z msgclb $

// History:
//
// 2005-06-04   :   Lloyd Kinsella    : Modifications to support newer TDateTime implementation
// 2006-03-21   :   Corwin Burgess  : Fixed index outofbounds in TMemIniFile.SetStrings
// 2006-03-26   :   Corwin Burgess  : Corrected transposed code in TMemIniFile.ReadSections

namespace ShineOn.RTL;

// TODO: 
// * implement all NotImplemented

interface
type
  EIniFileException = public class(Exception);

  TCustomIniFile = public abstract class(TObject)
  protected
    FFileName: String;
  public
    constructor Create(aFileName: String);
    function SectionExists(Section: String): Boolean;
    function ReadString(Section, Name, Default: String): String; virtual; abstract;
    procedure WriteString(Section, Name, Value: String); virtual; abstract;
    function ReadInteger(Section, Name: String; Default: LongInt): LongInt; virtual;
    procedure WriteInteger(Section, Name: String; Value: LongInt); virtual;
    function ReadBool(Section, Name: String; Default: Boolean): Boolean; virtual;
    procedure WriteBool(Section, Name: String; Value: Boolean); virtual;
    function ReadBinaryStream(Section, Name: String; Value: TStream): Integer; virtual;
    function ReadDate(Section, Name: String; Default: TDateTime): TDateTime; virtual;
    function ReadDateTime(Section, Name: String; Default: TDateTime): TDateTime; virtual;
    function ReadFloat(Section, Name: String; Default: Double): Double; virtual;
    function ReadTime(Section, Name: String; Default: TDateTime): TDateTime; virtual;
    procedure WriteBinaryStream(Section, Name: String; Value: TStream); virtual;
    procedure WriteDate(Section, Name: String; Value: TDateTime); virtual;
    procedure WriteDateTime(Section, Name: String; Value: TDateTime); virtual;
    procedure WriteFloat(Section, Name: String; Value: Double); virtual;
    procedure WriteTime(Section, Name: String; Value: TDateTime); virtual;
    procedure ReadSection(Section: String; Strings: TStrings); virtual; abstract;
    procedure ReadSections(Strings: TStrings); virtual; abstract;
    procedure ReadSectionValues(Section: String; Strings: TStrings); virtual; abstract;
    procedure EraseSection(Section: String); virtual; abstract;
    procedure DeleteKey(Section, Name: String); virtual; abstract;
    procedure UpdateFile; virtual; abstract;
    function ValueExists(Section, Name: String): Boolean;
    property FileName: String read FFileName;
  end;
  
  { TMemIniFile - loads an entire INI file into memory and allows all
    operations to be performed on the memory image.  The image can then
    be written out to the disk file }

  TMemIniFile = public class(TCustomIniFile)
  private
    FSections: TStringList;
    function AddSection(Section: String): TStrings;
    procedure LoadValues;
  public
    constructor Create(FileName: String);
    procedure Destroy;override;
    procedure Clear;
    procedure DeleteKey(Section, Name: String); override;
    procedure EraseSection(Section: String); override;
    procedure GetStrings(List: TStrings);
    procedure ReadSection(Section: String; Strings: TStrings); override;
    procedure ReadSections(Strings: TStrings); override;
    procedure ReadSectionValues(Section: String; Strings: TStrings); override;
    function ReadString(Section, Name, Default: String): String; override;
    procedure Rename(FileName: String; Reload: Boolean);
    procedure SetStrings(List: TStrings);
    procedure UpdateFile; override;
    procedure WriteString(Section, Name, Value: String); override;
  end;
  
  TIniFile = public class(TMemIniFile);


implementation

{ TCustomIniFile }
constructor TCustomIniFile.Create(aFileName: String); 
begin
  inherited Create;
  FFileName := aFileName;
end;

function TCustomIniFile.SectionExists(Section: String): Boolean; 
var S:TStringList;
begin
  S := TStringList.Create;
  ReadSections(S);
  Result := S.IndexOf(Section) >= 0;
end;

function TCustomIniFile.ReadInteger(Section, Name: String; Default: LongInt): LongInt; 
var S:String;
begin
  S := ReadString(Section, Name, '');
  // StrToInt already handles $ hex specifier
//  if S.StartsWith('$') then
//    S := '0x' + S.Substring(1);
  Result := StrToIntDef(S, Default);
end;

procedure TCustomIniFile.WriteInteger(Section, Name: String; Value: LongInt); 
begin
  WriteString(Section, Name, Value.ToString);
end;

function TCustomIniFile.ReadBool(Section, Name: String; Default: Boolean): Boolean; 
begin
  Result := ReadInteger(Section, Name, Ord(Default)) <> 0;
end;

procedure TCustomIniFile.WriteBool(Section, Name: String; Value: Boolean); 
begin
  WriteInteger(Section, Name, Ord(Value));
end;

function TCustomIniFile.ReadBinaryStream(Section, Name: String; Value: TStream): Integer; 
begin
  NotImplemented;
end;

function TCustomIniFile.ReadDate(Section, Name: String; Default: TDateTime): TDateTime; 
begin
  Result := ReadDateTime(Section, Name, Default);
end;

function TCustomIniFile.ReadDateTime(Section, Name: String; Default: TDateTime): TDateTime; 
begin
  Result := StrToDateTimeDef(ReadString(Section, Name, ''), Default);
end;

function TCustomIniFile.ReadFloat(Section, Name: String; Default: Double): Double; 
var S:String;
begin
  S := ReadString(Section, Name, '');
  if S <> '' then
    try
      Result := Double.Parse(S);
    except
      on E:FormatException do
        Result := Default;
    end
  else
    Result := Default;
end;

function TCustomIniFile.ReadTime(Section, Name: String; Default: TDateTime): TDateTime; 
begin
  Result := StrToDateTimeDef(ReadString(Section, Name, ''), Default);
end;

procedure TCustomIniFile.WriteBinaryStream(Section, Name: String; Value: TStream); 
begin
  NotImplemented;
end;

procedure TCustomIniFile.WriteDate(Section, Name: String; Value: TDateTime); 
begin
  
  WriteDateTime(Section, Name, TDateTime.Trunc(Value));
end;

procedure TCustomIniFile.WriteDateTime(Section, Name: String; Value: TDateTime); 
begin
  WriteString(Section, Name, Value.ToString);
end;

procedure TCustomIniFile.WriteFloat(Section, Name: String; Value: Double); 
begin
  WriteString(Section, Name, Value.ToString);
end;

procedure TCustomIniFile.WriteTime(Section, Name: String; Value: TDateTime); 
begin
  WriteDateTime(Section, Name, TDateTime.Frac(Value));
end;

function TCustomIniFile.ValueExists(Section, Name: String): Boolean; 
var
  S: TStringList;
begin
  S := TStringList.Create;
  ReadSection(Section, S);
  Result := S.IndexOf(Name) > -1;
end;

{ TMemIniFile }

function TMemIniFile.AddSection(Section: String): TStrings; 
var i:Int32;
begin
  i := FSections.IndexOf(Section); 
  if i >= 0 then
    Result := TStrings(FSections.Objects[i])
  else
  begin
    Result := new TStringList;
    FSections.AddObject(Section, Result);
  end;
end;

procedure TMemIniFile.LoadValues; 
begin
  if FileExists(FileName) then
    with S:TStringList := new TStringList do
    begin
      S.LoadFromFile(FileName);
      SetStrings(S);
    end;
end;

constructor TMemIniFile.Create(FileName: String); 
begin
  inherited Create(FileName);
  FSections := TStringList.Create;
  LoadValues;
end;

procedure TMemIniFile.Destroy; 
begin
  UpdateFile; // flush to disk
  inherited Destroy;
end;

procedure TMemIniFile.Clear; 
begin
  FSections.Clear;
end;

procedure TMemIniFile.DeleteKey(Section, Name: String); 
var i, j:Int32;
begin
  i := FSections.IndexOf(Section);
  if i >= 0 then
  begin
    j := TStrings(FSections.Objects[i]).IndexOfName(Name);
    if j >= 0 then
      TStrings(FSections.Objects[i]).Delete(j);
    if TStrings(FSections.Objects[i]).Count = 0 then
      FSections.Delete(i);
  end;
end;

procedure TMemIniFile.EraseSection(Section: String); 
var i:Int32;
begin
  i := FSections.IndexOf(Section);
  if i >= 0 then
    FSections.Delete(i);
end;

procedure TMemIniFile.GetStrings(List: TStrings); 
begin
  for i:Int32 := 0 to FSections.Count -1 do
  begin
    List.Add('[' + FSections[i] + ']');
    for j:Int32 := 0 to TStrings(FSections.Objects[i]).Count - 1 do
      List.Add(TStrings(FSections.Objects[i])[j]);
    List.Add('');
  end;
end;

procedure TMemIniFile.ReadSection(Section: String; Strings: TStrings); 
var i:Int32;
begin
  Strings.Clear;
  i := FSections.IndexOf(Section);
  if i >= 0 then
    for j:Int32 := 0 to TStrings(FSections.Objects[i]).Count - 1 do
      Strings.Add(TStrings(FSections.Objects[i]).Names[j]);
end;

procedure TMemIniFile.ReadSections(Strings: TStrings); 
begin
  //FSections.Assign(Strings);
  Strings.Assign(FSections);
end;

procedure TMemIniFile.ReadSectionValues(Section: String; Strings: TStrings); 
var i:Int32;
begin
  Strings.Clear;
  i := FSections.IndexOf(Section);
  if i >= 0 then
      Strings.Assign(TStrings(FSections.Objects[i]));
end;

function TMemIniFile.ReadString(Section, Name, Default: String): String; 
var 
  i:Int32;
  S:TStrings;
begin
  Result := Default;
  i := FSections.IndexOf(Section);
  if i >= 0 then
  begin
    S := TStrings(FSections.Objects[i]);
    i := S.IndexOfName(Name);
    if i >= 0 then
      Result := Copy(S[i], S[i].IndexOf('=') + 1, S[i].Length);
  end;
end;

procedure TMemIniFile.Rename(FileName: String; Reload: Boolean); 
begin
  FFileName := FileName;
  if Reload then LoadValues;
end;

procedure TMemIniFile.SetStrings(List: TStrings); 
var 
  S:String;
  Str:TStrings;
  j:Int32;
begin
  FSections.Clear;
  Str := nil;
  for i:Int32 := 0 to List.Count - 1 do
  begin
    S := List[i];
    if (S <> '') and not S.StartsWith(';') then
    begin
      if S.StartsWith('[') and S.EndsWith(']') then
        Str := AddSection(S.Substring(1, S.Length - 2).Trim)
      else if Str <> nil then
      begin
        j := S.IndexOf('=');
        if j > -1 then
          // truncate and index outofbounds        
          //S := S.Substring(0, j - 1).Trim + '=' + S.Substring(j + 1, S.Length).Trim; // VCL trims spaces before and after the first "=" (if found), so we better do the same
          S := S.Substring(0, j).Trim + '=' + S.Substring(j + 1, S.Length - (j + 1)).Trim; // VCL trims spaces before and after the first "=" (if found), so we better do the same
        Str.Add(S);  
      end;
    end;
  end;
end;

procedure TMemIniFile.UpdateFile; 
begin
  if FileName <> '' then
    with S:TStringList := new TStringList do
    begin
      GetStrings(S);
      S.SaveToFile(FileName);
    end;    
end;

procedure TMemIniFile.WriteString(Section, Name, Value: String); 
var 
  S:TStrings;
  tmp:String;
  i:Int32;
begin
  tmp := Name + '=' + Value;
  S := AddSection(Section);
  i := S.IndexOfName(Name);
  if i >= 0 then
    S[i] := tmp
  else
    S.Add(tmp);
end;

end.
