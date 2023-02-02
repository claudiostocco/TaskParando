unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs;

type
  TsvcTaskParando = class(TService)
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceExecute(Sender: TService);
  private
    sPath: String;
    function ImplPVerifica: TProc;
    procedure Verifica;
    procedure RegLog(NomeLog, Msg: String);
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  svcTaskParando: TsvcTaskParando;

implementation

uses System.Threading;

{$R *.dfm}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  svcTaskParando.Controller(CtrlCode);
end;

function TsvcTaskParando.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

function TsvcTaskParando.ImplPVerifica: TProc;
begin
   Result := procedure
             var slT: TStringList;
             begin
                slT := TStringList.Create;
                slT.Add(FormatDateTime('dd/mm/yyyy hh:nn:ss.zzz', Now)+' -> Executando Task');
                slT.SaveToFile(sPath+'task.log');
                FreeAndNil(slT);
             end;
end;

procedure TsvcTaskParando.RegLog(NomeLog, Msg: String);
var sl: TStringList;
begin
   sl := TStringList.Create;
   try
      sl.LoadFromFile(sPath+NomeLog);
   except
   end;
   sl.Add(FormatDateTime('dd/mm/yyyy hh:nn:ss.zzz', Now)+' -> '+Msg);
   try
      sl.SaveToFile(sPath+NomeLog);
   except
   end;
end;

procedure TsvcTaskParando.ServiceExecute(Sender: TService);
var iTm: Cardinal;
    tskAux: ITask;
    i: Integer;
    thPool: TThreadPool;
begin
   RegLog('svc.log','Iniciando Execute');
   iTm := GetTickCount + 2000;
   while not Terminated do
   begin
      ServiceThread.ProcessRequests(False);
      if GetTickCount > iTm then
      begin
         RegLog('ServiceExecute.log','Verificando e criando thPool');
         if Assigned(thPool) and (tskAux <> nil) and Assigned(tskAux) and (tskAux.Id > 10) then
         begin
            FreeAndNil(thPool);
         end;
         if not Assigned(thPool) then thPool := TThreadPool.Create;
         RegLog('ServiceExecute.log','Criando Task: TTask.Run() -- thPool.MaxWorkerThreads: '+thPool.MaxWorkerThreads.ToString);
         tskAux := TTask.Run(Verifica,thPool);
         RegLog('ServiceExecute.log','Após criar Task, TaskId: '+tskAux.Id.ToString+' TaskStatus: '+Integer(TTaskStatus(tskAux.Status)).ToString);

         i := 0;
         if tskAux.Status = TTaskStatus.WaitingToRun then
         begin
            RegLog('ServiceExecute.log','          -------> TTaskStatus.WaitingToRun ..............');
            for i := 0 to 5000 do
            begin
               if tskAux.Status <> TTaskStatus.WaitingToRun then Break;
               Sleep(1);
            end;
         end;
         RegLog('ServiceExecute.log','Após '+i.toString+'ms -> TaskId: '+tskAux.Id.ToString+' TaskStatus: '+Integer(TTaskStatus(tskAux.Status)).ToString);
         iTm := GetTickCount + 20000;
      end;
      Sleep(1);
   end;
end;

procedure TsvcTaskParando.ServiceStart(Sender: TService; var Started: Boolean);
begin
   sPath := ExtractFilePath(ParamStr(0));
   RegLog('svc.log','Iniciando serviço');
   Started := True;
end;

procedure TsvcTaskParando.Verifica;
var slT: TStringList;
begin
   slT := TStringList.Create;
   slT.Add(FormatDateTime('dd/mm/yyyy hh:nn:ss.zzz', Now)+' -> Executando Task');
   slT.SaveToFile(sPath+'task.log');
   FreeAndNil(slT);
end;

end.
