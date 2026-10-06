try { (function(){
  var out=Services.env.get("SP_OUT"); if(!out) return;
  var Ci=Components.interfaces, Cc=Components.classes, timers=[];
  function later(ms,fn){ var t=Cc["@mozilla.org/timer;1"].createInstance(Ci.nsITimer); t.initWithCallback({notify:function(){ try{fn();}catch(e){} }},ms,0); timers.push(t); }
  var started=false;
  Services.obs.addObserver({observe:function(w){ if(started) return; started=true;
    later(parseInt(Services.env.get("SP_MS")||"20000",10),function(){
      ChromeUtils.requestProcInfo().then(function(pi){
        var o={parentCpuMs:Math.round(pi.cpuTime/1e6),children:pi.children.map(function(c){ return [c.type,Math.round(c.cpuTime/1e6),Math.round(c.memory/1048576)]; })};
        try{ var si=Services.startup.getStartupInfo(), p=si.process.getTime(); o.startup={}; for(var k in si){ try{ o.startup[k]=si[k].getTime()-p; }catch(e){} } }catch(e){}
        Services.profiler.Pause();
        Services.profiler.dumpProfileToFileAsync(out).then(function(){ o.profile="ok"; var f=Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile); f.initWithPath(out+".info"); var os=Cc["@mozilla.org/network/file-output-stream;1"].createInstance(Ci.nsIFileOutputStream); os.init(f,0x02|0x08|0x20,420,0); var s=JSON.stringify(o); os.write(s,s.length); os.close(); later(300,function(){ Services.startup.quit(Ci.nsIAppStartup.eForceQuit); }); });
      });
    });
  }},"browser-delayed-startup-finished");
})(); } catch(e) {}
