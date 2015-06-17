namespace ShineOn.Rtl;

interface

type
  COMObj = Public Class
  public
    class function CreateClassID: string;
    
  end;

function CreateClassID: string;

implementation

function CreateClassID: string;
begin
  result := ShineOn.RTL.COMObj.CreateClassID;
end;

{ COMObj }

class function COMOBj.CreateClassID: string;
begin
  result := Guid.NewGuid().ToString('B').ToUpper();
end;

end.
