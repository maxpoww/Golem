// ---- gfx-info timing probe v2: at profile-after-change (where telemetry asks), time the first accesses ----
try { (function(){
  var out=Services.env.get("NT_OUT"); if(!out) return;
  var Ci=Components.interfaces, Cc=Components.classes, o={order:[]};
  function write(){ var f=Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile); f.initWithPath(out); var os=Cc["@mozilla.org/network/file-output-stream;1"].createInstance(Ci.nsIFileOutputStream); os.init(f,0x02|0x08|0x20,420,0); var s=JSON.stringify(o); os.write(s,s.length); os.close(); }
  function T(label,fn){ var t=Date.now(); var r; try{ r=fn(); }catch(e){ r="ERR "+e; } var d=Date.now()-t; o.order.push([label,d,(""+r).slice(0,70)]); return r; }
  function run(where){
    o.where=where; var gi=Cc["@mozilla.org/gfx/info;1"].getService(Ci.nsIGfxInfo);
    T("ContentBackend",function(){ return gi.ContentBackend; });
    T("isHeadless",function(){ return gi.isHeadless; });
    T("TargetFrameRate",function(){ return gi.TargetFrameRate; });
    T("textScaleFactor",function(){ return gi.textScaleFactor; });
    T("adapterDescription",function(){ return gi.adapterDescription; });
    T("adapterDriverVersion",function(){ return gi.adapterDriverVersion; });
    T("getFeatureStatus(WEBRENDER)",function(){ return gi.getFeatureStatus(Ci.nsIGfxInfo.FEATURE_WEBRENDER,{}); });
    T("getFeatureStatus(HW_VIDEO_DECODING)",function(){ return gi.getFeatureStatus(Ci.nsIGfxInfo.FEATURE_HARDWARE_VIDEO_DECODING,{}); });
    T("getFeatures()",function(){ return JSON.stringify(gi.getFeatures()).length; });
    T("getInfo()",function(){ return JSON.stringify(gi.getInfo()).length; });
    T("getMonitors()",function(){ return gi.getMonitors().length; });
    T("CodecSupportInfo",function(){ return gi.CodecSupportInfo.replace(/\n/g,"|"); });
    T("Services.sysinfo (cpu/mem props)",function(){ var s=Services.sysinfo; return ["memsize","cpucount","cpucores","cpuvendor","cpufamily","cpuspeedMHz","hasWindowsTouchInterface"].map(function(k){ try{ return s.getProperty(k); }catch(e){ return "-"; } }).join(","); });
    T("Services.sysinfo.processInfo",function(){ return JSON.stringify(Services.sysinfo.processInfo).length; });
    T("TelemetryEnvironment.currentEnvironment",function(){ var TE=ChromeUtils.importESModule("resource://gre/modules/TelemetryEnvironment.sys.mjs").TelemetryEnvironment; return JSON.stringify(TE.currentEnvironment).length; });
    T("adapterDescription again",function(){ return gi.adapterDescription; });
    write();
  }
  var done=false;
  Services.obs.addObserver({observe:function(){ if(done) return; done=true; try{ run("profile-after-change"); }catch(e){ o.err=""+e; write(); } }},"profile-after-change");
  var started=false;
  Services.obs.addObserver({observe:function(w){ if(started) return; started=true; if(!done){ done=true; try{ run("delayed-startup"); }catch(e){ o.err=""+e; write(); } } var t=Cc["@mozilla.org/timer;1"].createInstance(Ci.nsITimer); t.initWithCallback({notify:function(){ Services.startup.quit(Ci.nsIAppStartup.eForceQuit); }},2500,0); o.t=t; }},"browser-delayed-startup-finished");
})(); } catch(e) {}
