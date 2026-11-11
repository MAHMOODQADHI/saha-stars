// Injected into the game page only inside the Android app.
// Android's WebView has no working speechSynthesis, so this routes it to the phone's own
// text-to-speech through the AndroidTTS bridge, and turns off browser fullscreen (the app is already fullscreen).
(function(){
  var A=window.AndroidTTS;if(!A)return;
  try{Element.prototype.requestFullscreen=undefined;Element.prototype.webkitRequestFullscreen=undefined;}catch(e){}
  function U(t){this.text=String(t||'');this.lang='ar-SA';this.rate=1;this.pitch=1;this.volume=1;this.voice=null;}
  function voices(){var l=[];try{l=String(A.langs()).split(',').filter(Boolean);}catch(e){}
    return l.map(function(x){return {lang:x,name:'Android '+x,voiceURI:'android-'+x,localService:true,'default':false};});}
  var ss={
    speak:function(u){try{A.speak(String(u.text),u.voice?u.voice.lang:(u.lang||'ar-SA'),+u.rate||1,+u.pitch||1);}catch(e){}},
    cancel:function(){try{A.stop();}catch(e){}},
    getVoices:voices,pause:function(){},resume:function(){},onvoiceschanged:null,
    addEventListener:function(){},removeEventListener:function(){}
  };
  Object.defineProperty(ss,'speaking',{get:function(){try{return !!A.speaking();}catch(e){return false;}}});
  Object.defineProperty(ss,'pending',{get:function(){return false;}});
  try{Object.defineProperty(window,'SpeechSynthesisUtterance',{value:U,configurable:true,writable:true});}catch(e){window.SpeechSynthesisUtterance=U;}
  try{Object.defineProperty(window,'speechSynthesis',{value:ss,configurable:true,writable:true});}catch(e){window.speechSynthesis=ss;}
  // the phone's voice engine starts a moment after the page; tell the game when its languages are known
  var tries=0;(function poll(){var ok=false;try{ok=!!A.ready();}catch(e){}
    if(ok){if(typeof ss.onvoiceschanged==='function')try{ss.onvoiceschanged();}catch(e){}}
    else if(++tries<40)setTimeout(poll,250);})();
})();
