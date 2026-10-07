// ---- VIDEO PROBE (test rig only): which codec YouTube plays here, and what it costs ----
try { (function(){
  var D=Services.env.get("YT_DIR"), url=Services.env.get("YT_URL"); if(!D||!url) return;
  var Ci=Components.interfaces, Cc=Components.classes, timers=[], log=[];
  function later(ms,fn){ var t=Cc["@mozilla.org/timer;1"].createInstance(Ci.nsITimer); t.initWithCallback({notify:function(){ try{fn();}catch(e){ log.push("ERR "+e); write("result",{err:""+e,log:log}); } }},ms,0); timers.push(t); }
  function write(n,o){ var f=Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile); f.initWithPath(D+"/"+n+".json"); var os=Cc["@mozilla.org/network/file-output-stream;1"].createInstance(Ci.nsIFileOutputStream); os.init(f,0x02|0x08|0x20,420,0); var s=JSON.stringify(o); os.write(s,s.length); os.close(); }
  function snap(cb){ ChromeUtils.requestProcInfo().then(function(pi){ var o={}; o["parent"]={cpu:pi.cpuTime,mem:pi.memory}; pi.children.forEach(function(c){ var k=c.type+(c.origin?":"+c.origin.replace(/^https?:\/\//,""):""); o[k]={cpu:c.cpuTime,mem:c.memory}; }); cb(o); },function(e){ cb({err:""+e}); }); }
  function pv(n){ try{ var t=Services.prefs.getPrefType(n); if(t==32) return Services.prefs.getStringPref(n); if(t==64) return Services.prefs.getIntPref(n); if(t==128) return Services.prefs.getBoolPref(n); }catch(e){} return null; }
  var PIN=Services.env.get("YT_PIN")||"hd720"; var FS='data:,'+encodeURIComponent(('(function(){ var W={pauses:[],firstFrame:0,started:Date.now()}; content.setInterval(function(){ try{ var v=content.document.querySelector("video"); if(!v) return; if(!W.firstFrame && v.currentTime>0 && !v.paused){ W.firstFrame=Date.now(); try{ var mp=content.document.getElementById("movie_player"); if(mp&&mp.wrappedJSObject&&mp.wrappedJSObject.setPlaybackQualityRange){ if("__PIN__"!=="0"){ mp.wrappedJSObject.setPlaybackQualityRange("__PIN__","__PIN__"); W.pinned="__PIN__"; } else { W.pinned="auto"; } } }catch(e){ W.pinned="ERR "+e; } } if(W.last===undefined) W.last=v.paused; if(v.paused!==W.last){ W.last=v.paused; W.pauses.push({t:Date.now(),paused:v.paused}); } }catch(e){} },50); addMessageListener("yt:ask",function(){ try{ var d=content.document, v=d.querySelector("video"), r={watch:W}; if(v){ var q=v.getVideoPlaybackQuality(); r.video={w:v.videoWidth,h:v.videoHeight,t:v.currentTime,paused:v.paused,readyState:v.readyState,dropped:q.droppedVideoFrames,total:q.totalVideoFrames}; } r.streams=[]; var seen={}; content.performance.getEntriesByType("resource").forEach(function(e){ var n=e.name; if(n.indexOf("googlevideo.com")<0) return; var m=/[?&]mime=([^&]*)/.exec(n)||/\\/mime\\/([^\\/]+)/.exec(n), it=/[?&]itag=(\\d+)/.exec(n)||/\\/itag\\/(\\d+)/.exec(n); var k=(m?decodeURIComponent(m[1]):"?")+" itag="+(it?it[1]:"?"); if(!seen[k]){ seen[k]=0; } seen[k]++; }); for(var k in seen) r.streams.push(k+" x"+seen[k]); var fin=function(){ sendAsyncMessage("yt:answer",r); }; if(v&&v.mozRequestDebugInfo){ v.mozRequestDebugInfo().then(function(i){ try{ var rd=i&&i.decoder&&i.decoder.reader; r.decoder={video:rd&&rd.videoDecoderName,hw:rd&&rd.videoHardwareAccelerated,audio:rd&&rd.audioDecoderName}; }catch(e){ r.decoder={err:""+e}; } fin(); },function(e){ r.decoder={err:""+e}; fin(); }); } else fin(); }catch(e){ sendAsyncMessage("yt:answer",{err:""+e}); } }); })();').split("__PIN__").join(PIN));
  var started=false;
  Services.obs.addObserver({observe:function(w){ if(started) return; started=true;
    later(3000,function(){
      var b=w.gBrowser.selectedBrowser;
      b.fixupAndLoadURIString(url,{triggeringPrincipal:Services.scriptSecurityManager.getSystemPrincipal()});
      later(6000,function(){ try{ Services.mm.loadFrameScript(FS,true); }catch(e){ log.push("fs-early: "+e); } });   // GLOBAL + delayed: survives the response-time process switch of a slow first load (a per-browser load was lost on the MacBook)
      later(parseInt(Services.env.get("YT_WARM")||"20000",10),function(){
        try{ var thr=(Services.env.get("YT_THREADS")||"GeckoMain,Renderer,Compositor,WRRenderBackend,Media,ImageBridge,Socket,DOM Worker,Timer,Style,JS Helper,IPC").split(","); Services.profiler.StartProfiler(30000000, parseInt(Services.env.get("YT_INTERVAL")||"2",10), ["js","cpu","processcpu"], thr); }catch(e){ log.push("profiler: "+e); }
        try{ w.focus(); b.focus(); }catch(e){ log.push("focus: "+e); }   // keyboard to the page, not the address bar (a new window starts with the urlbar focused)
        snap(function(s0){ var t0=Date.now(); try{ var mf=Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile); mf.initWithPath(D+"/window-start"); var mo=Cc["@mozilla.org/network/file-output-stream;1"].createInstance(Ci.nsIFileOutputStream); mo.init(mf,0x02|0x08|0x20,420,0); var ms=String(t0); mo.write(ms,ms.length); mo.close(); }catch(e){ log.push("marker: "+e); }
          later(20000,function(){
            snap(function(s1){
              var mm=b.messageManager;
              var got=false; mm.addMessageListener("yt:answer",function(m){ if(got) return; got=true;
                var res={window:Math.round((Date.now()-t0)/1000)+"s", content:m.data, procs0:s0, procs1:s1, gfx:w.windowUtils.layerManagerType,
                  prefs:{preferHw:pv("golem.seam.preferHwCodecs"),blockVp9:pv("golem.seam.codecBlock.vp9"),blockAv1:pv("golem.seam.codecBlock.av1"),vaapi:pv("media.ffmpeg.vaapi.enabled"),hwdec:pv("media.hardware-video-decoding.enabled"),forceHw:pv("media.hardware-video-decoding.force-enabled")},
                  codecs:(function(){ try{ return Cc["@mozilla.org/gfx/info;1"].getService(Ci.nsIGfxInfo).CodecSupportInfo; }catch(e){ return "ERR "+e; } })(),
                  features:(function(){ try{ var gi=Cc["@mozilla.org/gfx/info;1"].getService(Ci.nsIGfxInfo), G=Ci.nsIGfxInfo, o={}; ["FEATURE_DMABUF","FEATURE_DMABUF_SURFACE_EXPORT","FEATURE_HARDWARE_VIDEO_DECODING","FEATURE_WEBRENDER","FEATURE_WEBRENDER_COMPOSITOR","FEATURE_VIDEO_OVERLAY","FEATURE_HW_DECODED_VIDEO_ZERO_COPY","FEATURE_VP8_HW_DECODE","FEATURE_VP9_HW_DECODE","FEATURE_H264_HW_DECODE"].forEach(function(n){ if(G[n]!==undefined){ var f={}; o[n]=gi.getFeatureStatus(G[n],f)+(f.value?" "+f.value:""); } }); o.all=gi.getFeatures(); return o; }catch(e){ return "ERR "+e; } })(),
                  dmabufPrefs:{force:pv("widget.dmabuf.force-enabled"),zeroCopy:pv("media.ffmpeg.vaapi.force-surface-zero-copy"),wrCompositor:pv("gfx.webrender.compositor"),overlay:pv("gfx.webrender.compositor.force-enabled")},
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
