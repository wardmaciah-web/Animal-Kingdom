local function signal()
 local listeners={}
 return {
  Connect=function(_,callback)
   local connection={Connected=true}
   function connection:Disconnect() self.Connected=false end
   table.insert(listeners,{Connection=connection,Callback=callback});return connection
  end,
  Fire=function(_,...)
   for _,entry in ipairs(listeners) do if entry.Connection.Connected then entry.Callback(...) end end
  end,
 }
end
local function copy(value)
 if type(value)~="table" then return value end
 local result={};for key,item in pairs(value) do result[key]=copy(item) end;return result
end
local function harness(online)
 local state={Now=0,Online=online,RejectPosts=false,HealthChecks=0,Requests={},Warnings={},Close={},Tasks={}}
 local log=signal()
 local replicated={Children={}}
 function replicated:FindFirstChild(name)
  for _,child in ipairs(self.Children) do if child.Name==name then return child end end
 end
 replicated.WaitForChild=replicated.FindFirstChild
 local http={}
 function http:GetAsync(url)
  if url=="http://localhost:1" then error("HttpError: ConnectFail") end
  state.HealthChecks+=1
  if state.DuringHealth then local callback=state.DuringHealth;state.DuringHealth=nil;callback() end
  if not state.Online then error("HttpError: ConnectFail") end
  return "OK"
 end
 function http:JSONEncode(body) return copy(body) end
 function http:PostAsync(url,body)
  local request={Url=url,Body=copy(body),At=state.Now,Accepted=false}
  table.insert(state.Requests,request)
  if not state.Online or state.RejectPosts then error("HttpError: ConnectFail") end
  request.Accepted=true
  return "OK"
 end
 local function remote(class)
  return setmetatable({Name=class,OnServerEvent=signal(),OnClientEvent=signal(),Sent={}}, {
   __newindex=function(self,key,value)
    if key=="Parent" then table.insert(value.Children,self) end
    rawset(self,key,value)
   end,
   __index={FireServer=function(self,value) table.insert(self.Sent,value) end},
  })
 end
 local function resume(entry)
  local ok,delay=coroutine.resume(entry.Thread)
  assert(ok,delay)
  entry.Wake=state.Now+(delay or 1)
 end
 local clock=table.clone(os);clock.clock=function() return state.Now end
 local services={
  HttpService=http,ReplicatedStorage=replicated,LogService={MessageOut=log},
  ServerStorage={FindFirstChild=function() return nil end},RunService={IsStudio=function() return true end},
  Players={GetPlayers=function() return {} end},TweenService={},
 }
 local game={GetService=function(_,name) return assert(services[name],name) end,
  BindToClose=function(_,callback) table.insert(state.Close,callback) end}
 local modules={
  WebSocketClient={new=function() return {setMessageHandler=function() end,connect=function() return true end,disconnect=function() end} end},
  CodeExecutor={},ClientQueryRouter={new=function() return {} end},ClientCodeExecutor={},
 }
 local env=setmetatable({
  game=game,Instance={new=remote},os=clock,tick=function() return state.Now end,
  DateTime={now=function() return {UnixTimestampMillis=state.Now*1000} end},
  Enum={HttpContentType={ApplicationJson=1},MessageType={MessageError="error",MessageWarning="warning",MessageInfo="info",MessageOutput="output"}},
  script={WebSocketClient="WebSocketClient",CodeExecutor="CodeExecutor",ClientQueryRouter="ClientQueryRouter",ClientCodeExecutor="ClientCodeExecutor"},
  require=function(name) return assert(modules[name],name) end,
  task={wait=function(seconds) return coroutine.yield(seconds) end,spawn=function(callback)
   local entry={Thread=coroutine.create(callback)};table.insert(state.Tasks,entry);resume(entry)
  end},
  print=function(...) local items={...};for i,v in ipairs(items) do items[i]=tostring(v) end;log:Fire(table.concat(items," "),"output") end,
  warn=function(...) local items={...};for i,v in ipairs(items) do items[i]=tostring(v) end;local message=table.concat(items," ");table.insert(state.Warnings,message);log:Fire(message,"warning") end,
 },{__index=getfenv()})
 function state:Load(name)
  local fn=assert(loadstring(sources[name],name));setfenv(fn,env);fn()
 end
 function state:Advance(seconds)
  for _=1,seconds do
   self.Now+=1
   for _,entry in ipairs(self.Tasks) do
    if coroutine.status(entry.Thread)~="dead" and entry.Wake<=self.Now then resume(entry) end
   end
  end
 end
 function state:Log(message) log:Fire(message,"output") end
 function state:Shutdown() for _,callback in ipairs(self.Close) do callback() end end
 state.Replicated=replicated
 return state
end

local absent=harness(false);absent:Load("Server")
for i=1,500 do absent:Log("Real gameplay event "..i) end
absent:Advance(360)
assert(#absent.Requests==0,"Absent backend still receives log/start POST attempts")
assert(absent.HealthChecks<=18,"Missing backend was probed without capped exponential backoff")
assert(#absent.Warnings==3,"Logger generated repeated network-failure warnings while offline")
absent.Online=true;absent:Advance(31)
local delivered=0;local lastSeen=false
for _,request in ipairs(absent.Requests) do
 for _,entry in ipairs(request.Body.logs or {}) do
  delivered+=1
  assert(not entry.message:find("[SuperbulletLogger]",1,true),"Logger's own diagnostic was recaptured")
  if entry.message=="Real gameplay event 500" then lastSeen=true end
 end
end
assert(delivered<=200 and lastSeen,"Offline buffer grew unbounded or lost newest gameplay diagnostics")
print("PASS Studio logger: absent backend skips POST, capped backoff, no diagnostic recursion, bounded recent log recovery")

-- A responding health endpoint with failing log writes must also back off.
absent.RejectPosts=true;absent:Log("Recover this failed batch")
local requestsBefore,warningsBefore=#absent.Requests,#absent.Warnings
absent:Advance(100)
assert(#absent.Requests-requestsBefore<=8,"Failing log endpoint bypassed backoff through successful health probes")
assert(#absent.Warnings-warningsBefore==1,"One outage generated repeated diagnostics")
absent.RejectPosts=false;absent:Advance(31)
local recovered=false
for i=requestsBefore+1,#absent.Requests do
 for _,entry in ipairs(absent.Requests[i].Body.logs or {}) do
  if absent.Requests[i].Accepted and entry.message=="Recover this failed batch" then recovered=true end
  assert(not entry.message:find("[SuperbulletLogger]",1,true),"Transport warning reentered payload")
 end
end
assert(recovered,"Failed gameplay batch was discarded instead of being retried")
print("PASS Studio logger: failed writes back off, emit one outage warning, retain gameplay logs, recover automatically")

absent.RejectPosts=true;absent:Log("Last queued event");absent:Advance(1)
local beforeClose=#absent.Requests
absent:Shutdown();absent:Log("After shutdown");absent:Advance(60)
assert(#absent.Requests==beforeClose,"Known-offline shutdown retried transport or left batch loop running")
local closing=harness(true);closing:Load("Server")
for i=1,200 do closing:Log("Shutdown event "..i) end
closing.RejectPosts=true
closing:Shutdown()
assert(#closing.Requests==1,"Shutdown did not stop after the first failed batch")
local healthy=harness(true);healthy:Load("Server")
for i=1,200 do healthy:Log("Healthy shutdown event "..i) end
healthy:Shutdown()
assert(#healthy.Requests<=3,"Shutdown exceeded two batches plus stop notification")
local inFlight=harness(false);inFlight:Load("Server");inFlight:Log("Queued before close")
inFlight.Online=true;inFlight.DuringHealth=function() inFlight:Shutdown() end
inFlight:Advance(3)
assert(#inFlight.Requests==0,"Health request completing after shutdown restarted HTTP logging")
print("PASS Studio logger: absent-backend shutdown does no HTTP, failed flush stops once, healthy flush is bounded")

local client=harness(false);client:Load("Server");client:Load("Client")
local remote=client.Replicated:FindFirstChild("SuperbulletClientLog")
client:Log("[SuperbulletLogger] Failed to send logs: HttpError ConnectFail")
assert(#remote.Sent==0,"Client forwarded logger's own diagnostics")
for i=1,20 do client:Log("Client gameplay "..i) end
assert(#remote.Sent==10,"Client log rate limit changed")
client:Advance(1)
client:Log(string.rep("x",9000))
assert(#remote.Sent==11 and #remote.Sent[11].message==4000,"Client payload limit or rate reset failed")
print("PASS Studio client logger: internal diagnostics excluded, gameplay logs retained, existing rate limit and bounded payload")
