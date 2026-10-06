// ---- VIDEO PROBE (test rig only): which codec YouTube plays here, and what it costs ----
try { (function(){
  var D=Services.env.get("YT_DIR"), url=Services.env.get("YT_URL"); if(!D||!url) return;
  var Ci=Components.interfaces, Cc=Components.classes, timers=[], log=[];
  function later(ms,fn){ var t=Cc["@mozilla.org/timer;1"].createInstance(Ci.nsITimer); t.initWithCallback({notify:function(){ try{fn();}catch(e){ log.push("ERR "+e); write("result",{err:""+e,log:log}); } }},ms,0); timers.push(t); }
  function write(n,o){ var f=Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile); f.initWithPath(D+"/"+n+".json"); var os=Cc["@mozilla.org/network/file-output-stream;1"].createInstance(Ci.nsIFileOutputStream); os.init(f,0x02|0x08|0x20,420,0); var s=JSON.stringify(o); os.write(s,s.length); os.close(); }
  function snap(cb){ ChromeUtils.requestProcInfo().then(function(pi){ var o={}; o["parent"]={cpu:pi.cpuTime,mem:pi.memory}; pi.children.forEach(function(c){ var k=c.type+(c.origin?":"+c.origin.replace(/^https?:\/\//,""):""); o[k]={cpu:c.cpuTime,mem:c.memory}; }); cb(o); },function(e){ cb({err:""+e}); }); }
  function pv(n){ try{ var t=Services.prefs.getPrefType(n); if(t==32) return Services.prefs.getStringPref(n); if(t==64) return Services.prefs.getIntPref(n); if(t==128) return Services.prefs.getBoolPref(n); }catch(e){} return null; }
  var FS='data:,'+encodeURIComponent('(function(){ addMessageListener("yt:ask",function(){ try{ var d=content.document, v=d.querySelector("video"), r={}; if(v){ var q=v.getVideoPlaybackQuality(); r.video={w:v.videoWidth,h:v.videoHeight,t:v.currentTime,paused:v.paused,readyState:v.readyState,dropped:q.droppedVideoFrames,total:q.totalVideoFrames}; } r.streams=[]; var seen={}; content.performance.getEntriesByType("resource").forEach(function(e){ var n=e.name; if(n.indexOf("googlevideo.com")<0) return; var m=/[?&]mime=([^&]*)/.exec(n)||/\\/mime\\/([^\\/]+)/.exec(n), it=/[?&]itag=(\\d+)/.exec(n)||/\\/itag\\/(\\d+)/.exec(n); var k=(m?decodeURIComponent(m[1]):"?")+" itag="+(it?it[1]:"?"); if(!seen[k]){ seen[k]=0; } seen[k]++; }); for(var k in seen) r.streams.push(k+" x"+seen[k]); sendAsyncMessage("yt:answer",r); }catch(e){ sendAsyncMessage("yt:answer",{err:""+e}); } }); })();');
  var started=false;
  Services.obs.addObserver({observe:function(w){ if(started) return; started=true;
    later(3000,function(){
      var b=w.gBrowser.selectedBrowser;
      b.fixupAndLoadURIString(url,{triggeringPrincipal:Services.scriptSecurityManager.getSystemPrincipal()});
      later(20000,function(){
        try{ Services.profiler.StartProfiler(30000000, 2, ["js","cpu","processcpu"], ["GeckoMain","Renderer","Compositor","WRRenderBackend","Media","ImageBridge","Socket","DOM Worker","Timer","Style","JS Helper","IPC"]); }catch(e){ log.push("profiler: "+e); }
        snap(function(s0){ var t0=Date.now();
          later(20000,function(){
            snap(function(s1){
              var mm=b.messageManager; mm.loadFrameScript(FS,false);
              var got=false; mm.addMessageListener("yt:answer",function(m){ if(got) return; got=true;
                var res={window:Math.round((Date.now()-t0)/1000)+"s", content:m.data, procs0:s0, procs1:s1, gfx:w.windowUtils.layerManagerType,
                  prefs:{preferHw:pv("golem.seam.preferHwCodecs"),blockVp9:pv("golem.seam.codecBlock.vp9"),blockAv1:pv("golem.seam.codecBlock.av1"),vaapi:pv("media.ffmpeg.vaapi.enabled"),hwdec:pv("media.hardware-video-decoding.enabled"),forceHw:pv("media.hardware-video-decoding.force-enabled")},
                  codecs:(function(){ try{ return Cc["@mozilla.org/gfx/info;1"].getService(Ci.nsIGfxInfo).CodecSupportInfo; }catch(e){ return "ERR "+e; } })(),
                  env:{LIBVA:Services.env.get("LIBVA_DRIVER_NAME")}, log:log };
                try{ Services.profiler.Pause(); }catch(e){}
                Services.profiler.dumpProfileToFileAsync(D+"/profile.json").then(function(){ res.profile="written"; write("result",res); later(400,function(){ Services.startup.quit(Ci.nsIAppStartup.eForceQuit); }); },function(e){ res.profile="ERR "+e; write("result",res); later(400,function(){ Services.startup.quit(Ci.nsIAppStartup.eForceQuit); }); }); });
              mm.sendAsyncMessage("yt:ask"); later(8000,function(){ if(!got){ got=true; write("result",{err:"no answer from content",procs0:s0,procs1:s1,log:log}); later(300,function(){ Services.startup.quit(Ci.nsIAppStartup.eForceQuit); }); } });
            });
          });
        });
      });
    });
  }},"browser-delayed-startup-finished");
})(); } catch(e) {}
