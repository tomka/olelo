(function(){
var _1=this,_2,_3=_1.jQuery,_4=_1.$,_5=_1.jQuery=_1.$=function(_6,_7){
return new _5.fn.init(_6,_7);
},_8=/^[^<]*(<(.|\s)+>)[^>]*$|^#([\w-]+)$/,_9=/^.[^:#\[\.,]*$/;
_5.fn=_5.prototype={init:function(_a,_b){
_a=_a||document;
if(_a.nodeType){
this[0]=_a;
this.length=1;
this.context=_a;
return this;
}
if(typeof _a==="string"){
var _c=_8.exec(_a);
if(_c&&(_c[1]||!_b)){
if(_c[1]){
_a=_5.clean([_c[1]],_b);
}else{
var _d=document.getElementById(_c[3]);
if(_d&&_d.id!=_c[3]){
return _5().find(_a);
}
var _e=_5(_d||[]);
_e.context=document;
_e.selector=_a;
return _e;
}
}else{
return _5(_b).find(_a);
}
}else{
if(_5.isFunction(_a)){
return _5(document).ready(_a);
}
}
if(_a.selector&&_a.context){
this.selector=_a.selector;
this.context=_a.context;
}
return this.setArray(_5.isArray(_a)?_a:_5.makeArray(_a));
},selector:"",jquery:"1.3.2",size:function(){
return this.length;
},get:function(_f){
return _f===_2?Array.prototype.slice.call(this):this[_f];
},pushStack:function(_10,_11,_12){
var ret=_5(_10);
ret.prevObject=this;
ret.context=this.context;
if(_11==="find"){
ret.selector=this.selector+(this.selector?" ":"")+_12;
}else{
if(_11){
ret.selector=this.selector+"."+_11+"("+_12+")";
}
}
return ret;
},setArray:function(_13){
this.length=0;
Array.prototype.push.apply(this,_13);
return this;
},each:function(_14,_15){
return _5.each(this,_14,_15);
},index:function(_16){
return _5.inArray(_16&&_16.jquery?_16[0]:_16,this);
},attr:function(_17,_18,_19){
var _1a=_17;
if(typeof _17==="string"){
if(_18===_2){
return this[0]&&_5[_19||"attr"](this[0],_17);
}else{
_1a={};
_1a[_17]=_18;
}
}
return this.each(function(i){
for(_17 in _1a){
_5.attr(_19?this.style:this,_17,_5.prop(this,_1a[_17],_19,i,_17));
}
});
},css:function(key,_1b){
if((key=="width"||key=="height")&&parseFloat(_1b)<0){
_1b=_2;
}
return this.attr(key,_1b,"curCSS");
},text:function(_1c){
if(typeof _1c!=="object"&&_1c!=null){
return this.empty().append((this[0]&&this[0].ownerDocument||document).createTextNode(_1c));
}
var ret="";
_5.each(_1c||this,function(){
_5.each(this.childNodes,function(){
if(this.nodeType!=8){
ret+=this.nodeType!=1?this.nodeValue:_5.fn.text([this]);
}
});
});
return ret;
},wrapAll:function(_1d){
if(this[0]){
var _1e=_5(_1d,this[0].ownerDocument).clone();
if(this[0].parentNode){
_1e.insertBefore(this[0]);
}
_1e.map(function(){
var _1f=this;
while(_1f.firstChild){
_1f=_1f.firstChild;
}
return _1f;
}).append(this);
}
return this;
},wrapInner:function(_20){
return this.each(function(){
_5(this).contents().wrapAll(_20);
});
},wrap:function(_21){
return this.each(function(){
_5(this).wrapAll(_21);
});
},append:function(){
return this.domManip(arguments,true,function(_22){
if(this.nodeType==1){
this.appendChild(_22);
}
});
},prepend:function(){
return this.domManip(arguments,true,function(_23){
if(this.nodeType==1){
this.insertBefore(_23,this.firstChild);
}
});
},before:function(){
return this.domManip(arguments,false,function(_24){
this.parentNode.insertBefore(_24,this);
});
},after:function(){
return this.domManip(arguments,false,function(_25){
this.parentNode.insertBefore(_25,this.nextSibling);
});
},end:function(){
return this.prevObject||_5([]);
},push:[].push,sort:[].sort,splice:[].splice,find:function(_26){
if(this.length===1){
var ret=this.pushStack([],"find",_26);
ret.length=0;
_5.find(_26,this[0],ret);
return ret;
}else{
return this.pushStack(_5.unique(_5.map(this,function(_27){
return _5.find(_26,_27);
})),"find",_26);
}
},clone:function(_28){
var ret=this.map(function(){
if(!_5.support.noCloneEvent&&!_5.isXMLDoc(this)){
var _29=this.outerHTML;
if(!_29){
var div=this.ownerDocument.createElement("div");
div.appendChild(this.cloneNode(true));
_29=div.innerHTML;
}
return _5.clean([_29.replace(/ jQuery\d+="(?:\d+|null)"/g,"").replace(/^\s*/,"")])[0];
}else{
return this.cloneNode(true);
}
});
if(_28===true){
var _2a=this.find("*").andSelf(),i=0;
ret.find("*").andSelf().each(function(){
if(this.nodeName!==_2a[i].nodeName){
return;
}
var _2b=_5.data(_2a[i],"events");
for(var _2c in _2b){
for(var _2d in _2b[_2c]){
_5.event.add(this,_2c,_2b[_2c][_2d],_2b[_2c][_2d].data);
}
}
i++;
});
}
return ret;
},filter:function(_2e){
return this.pushStack(_5.isFunction(_2e)&&_5.grep(this,function(_2f,i){
return _2e.call(_2f,i);
})||_5.multiFilter(_2e,_5.grep(this,function(_30){
return _30.nodeType===1;
})),"filter",_2e);
},closest:function(_31){
var pos=_5.expr.match.POS.test(_31)?_5(_31):null,_32=0;
return this.map(function(){
var cur=this;
while(cur&&cur.ownerDocument){
if(pos?pos.index(cur)>-1:_5(cur).is(_31)){
_5.data(cur,"closest",_32);
return cur;
}
cur=cur.parentNode;
_32++;
}
});
},not:function(_33){
if(typeof _33==="string"){
if(_9.test(_33)){
return this.pushStack(_5.multiFilter(_33,this,true),"not",_33);
}else{
_33=_5.multiFilter(_33,this);
}
}
var _34=_33.length&&_33[_33.length-1]!==_2&&!_33.nodeType;
return this.filter(function(){
return _34?_5.inArray(this,_33)<0:this!=_33;
});
},add:function(_35){
return this.pushStack(_5.unique(_5.merge(this.get(),typeof _35==="string"?_5(_35):_5.makeArray(_35))));
},is:function(_36){
return !!_36&&_5.multiFilter(_36,this).length>0;
},hasClass:function(_37){
return !!_37&&this.is("."+_37);
},val:function(_38){
if(_38===_2){
var _39=this[0];
if(_39){
if(_5.nodeName(_39,"option")){
return (_39.attributes.value||{}).specified?_39.value:_39.text;
}
if(_5.nodeName(_39,"select")){
var _3a=_39.selectedIndex,_3b=[],_3c=_39.options,one=_39.type=="select-one";
if(_3a<0){
return null;
}
for(var i=one?_3a:0,max=one?_3a+1:_3c.length;i<max;i++){
var _3d=_3c[i];
if(_3d.selected){
_38=_5(_3d).val();
if(one){
return _38;
}
_3b.push(_38);
}
}
return _3b;
}
return (_39.value||"").replace(/\r/g,"");
}
return _2;
}
if(typeof _38==="number"){
_38+="";
}
return this.each(function(){
if(this.nodeType!=1){
return;
}
if(_5.isArray(_38)&&/radio|checkbox/.test(this.type)){
this.checked=(_5.inArray(this.value,_38)>=0||_5.inArray(this.name,_38)>=0);
}else{
if(_5.nodeName(this,"select")){
var _3e=_5.makeArray(_38);
_5("option",this).each(function(){
this.selected=(_5.inArray(this.value,_3e)>=0||_5.inArray(this.text,_3e)>=0);
});
if(!_3e.length){
this.selectedIndex=-1;
}
}else{
this.value=_38;
}
}
});
},html:function(_3f){
return _3f===_2?(this[0]?this[0].innerHTML.replace(/ jQuery\d+="(?:\d+|null)"/g,""):null):this.empty().append(_3f);
},replaceWith:function(_40){
return this.after(_40).remove();
},eq:function(i){
return this.slice(i,+i+1);
},slice:function(){
return this.pushStack(Array.prototype.slice.apply(this,arguments),"slice",Array.prototype.slice.call(arguments).join(","));
},map:function(_41){
return this.pushStack(_5.map(this,function(_42,i){
return _41.call(_42,i,_42);
}));
},andSelf:function(){
return this.add(this.prevObject);
},domManip:function(_43,_44,_45){
if(this[0]){
var _46=(this[0].ownerDocument||this[0]).createDocumentFragment(),_47=_5.clean(_43,(this[0].ownerDocument||this[0]),_46),_48=_46.firstChild;
if(_48){
for(var i=0,l=this.length;i<l;i++){
_45.call(_49(this[i],_48),this.length>1||i>0?_46.cloneNode(true):_46);
}
}
if(_47){
_5.each(_47,_4a);
}
}
return this;
function _49(_4b,cur){
return _44&&_5.nodeName(_4b,"table")&&_5.nodeName(cur,"tr")?(_4b.getElementsByTagName("tbody")[0]||_4b.appendChild(_4b.ownerDocument.createElement("tbody"))):_4b;
};
}};
_5.fn.init.prototype=_5.fn;
function _4a(i,_4c){
if(_4c.src){
_5.ajax({url:_4c.src,async:false,dataType:"script"});
}else{
_5.globalEval(_4c.text||_4c.textContent||_4c.innerHTML||"");
}
if(_4c.parentNode){
_4c.parentNode.removeChild(_4c);
}
};
function now(){
return +new Date;
};
_5.extend=_5.fn.extend=function(){
var _4d=arguments[0]||{},i=1,_4e=arguments.length,_4f=false,_50;
if(typeof _4d==="boolean"){
_4f=_4d;
_4d=arguments[1]||{};
i=2;
}
if(typeof _4d!=="object"&&!_5.isFunction(_4d)){
_4d={};
}
if(_4e==i){
_4d=this;
--i;
}
for(;i<_4e;i++){
if((_50=arguments[i])!=null){
for(var _51 in _50){
var src=_4d[_51],_52=_50[_51];
if(_4d===_52){
continue;
}
if(_4f&&_52&&typeof _52==="object"&&!_52.nodeType){
_4d[_51]=_5.extend(_4f,src||(_52.length!=null?[]:{}),_52);
}else{
if(_52!==_2){
_4d[_51]=_52;
}
}
}
}
}
return _4d;
};
var _53=/z-?index|font-?weight|opacity|zoom|line-?height/i,_54=document.defaultView||{},_55=Object.prototype.toString;
_5.extend({noConflict:function(_56){
_1.$=_4;
if(_56){
_1.jQuery=_3;
}
return _5;
},isFunction:function(obj){
return _55.call(obj)==="[object Function]";
},isArray:function(obj){
return _55.call(obj)==="[object Array]";
},isXMLDoc:function(_57){
return _57.nodeType===9&&_57.documentElement.nodeName!=="HTML"||!!_57.ownerDocument&&_5.isXMLDoc(_57.ownerDocument);
},globalEval:function(_58){
if(_58&&/\S/.test(_58)){
var _59=document.getElementsByTagName("head")[0]||document.documentElement,_5a=document.createElement("script");
_5a.type="text/javascript";
if(_5.support.scriptEval){
_5a.appendChild(document.createTextNode(_58));
}else{
_5a.text=_58;
}
_59.insertBefore(_5a,_59.firstChild);
_59.removeChild(_5a);
}
},nodeName:function(_5b,_5c){
return _5b.nodeName&&_5b.nodeName.toUpperCase()==_5c.toUpperCase();
},each:function(_5d,_5e,_5f){
var _60,i=0,_61=_5d.length;
if(_5f){
if(_61===_2){
for(_60 in _5d){
if(_5e.apply(_5d[_60],_5f)===false){
break;
}
}
}else{
for(;i<_61;){
if(_5e.apply(_5d[i++],_5f)===false){
break;
}
}
}
}else{
if(_61===_2){
for(_60 in _5d){
if(_5e.call(_5d[_60],_60,_5d[_60])===false){
break;
}
}
}else{
for(var _62=_5d[0];i<_61&&_5e.call(_62,i,_62)!==false;_62=_5d[++i]){
}
}
}
return _5d;
},prop:function(_63,_64,_65,i,_66){
if(_5.isFunction(_64)){
_64=_64.call(_63,i);
}
return typeof _64==="number"&&_65=="curCSS"&&!_53.test(_66)?_64+"px":_64;
},className:{add:function(_67,_68){
_5.each((_68||"").split(/\s+/),function(i,_69){
if(_67.nodeType==1&&!_5.className.has(_67.className,_69)){
_67.className+=(_67.className?" ":"")+_69;
}
});
},remove:function(_6a,_6b){
if(_6a.nodeType==1){
_6a.className=_6b!==_2?_5.grep(_6a.className.split(/\s+/),function(_6c){
return !_5.className.has(_6b,_6c);
}).join(" "):"";
}
},has:function(_6d,_6e){
return _6d&&_5.inArray(_6e,(_6d.className||_6d).toString().split(/\s+/))>-1;
}},swap:function(_6f,_70,_71){
var old={};
for(var _72 in _70){
old[_72]=_6f.style[_72];
_6f.style[_72]=_70[_72];
}
_71.call(_6f);
for(var _72 in _70){
_6f.style[_72]=old[_72];
}
},css:function(_73,_74,_75,_76){
if(_74=="width"||_74=="height"){
var val,_77={position:"absolute",visibility:"hidden",display:"block"},_78=_74=="width"?["Left","Right"]:["Top","Bottom"];
function _79(){
val=_74=="width"?_73.offsetWidth:_73.offsetHeight;
if(_76==="border"){
return;
}
_5.each(_78,function(){
if(!_76){
val-=parseFloat(_5.curCSS(_73,"padding"+this,true))||0;
}
if(_76==="margin"){
val+=parseFloat(_5.curCSS(_73,"margin"+this,true))||0;
}else{
val-=parseFloat(_5.curCSS(_73,"border"+this+"Width",true))||0;
}
});
};
if(_73.offsetWidth!==0){
_79();
}else{
_5.swap(_73,_77,_79);
}
return Math.max(0,Math.round(val));
}
return _5.curCSS(_73,_74,_75);
},curCSS:function(_7a,_7b,_7c){
var ret,_7d=_7a.style;
if(_7b=="opacity"&&!_5.support.opacity){
ret=_5.attr(_7d,"opacity");
return ret==""?"1":ret;
}
if(_7b.match(/float/i)){
_7b=_7e;
}
if(!_7c&&_7d&&_7d[_7b]){
ret=_7d[_7b];
}else{
if(_54.getComputedStyle){
if(_7b.match(/float/i)){
_7b="float";
}
_7b=_7b.replace(/([A-Z])/g,"-$1").toLowerCase();
var _7f=_54.getComputedStyle(_7a,null);
if(_7f){
ret=_7f.getPropertyValue(_7b);
}
if(_7b=="opacity"&&ret==""){
ret="1";
}
}else{
if(_7a.currentStyle){
var _80=_7b.replace(/\-(\w)/g,function(all,_81){
return _81.toUpperCase();
});
ret=_7a.currentStyle[_7b]||_7a.currentStyle[_80];
if(!/^\d+(px)?$/i.test(ret)&&/^\d/.test(ret)){
var _82=_7d.left,_83=_7a.runtimeStyle.left;
_7a.runtimeStyle.left=_7a.currentStyle.left;
_7d.left=ret||0;
ret=_7d.pixelLeft+"px";
_7d.left=_82;
_7a.runtimeStyle.left=_83;
}
}
}
}
return ret;
},clean:function(_84,_85,_86){
_85=_85||document;
if(typeof _85.createElement==="undefined"){
_85=_85.ownerDocument||_85[0]&&_85[0].ownerDocument||document;
}
if(!_86&&_84.length===1&&typeof _84[0]==="string"){
var _87=/^<(\w+)\s*\/?>$/.exec(_84[0]);
if(_87){
return [_85.createElement(_87[1])];
}
}
var ret=[],_88=[],div=_85.createElement("div");
_5.each(_84,function(i,_89){
if(typeof _89==="number"){
_89+="";
}
if(!_89){
return;
}
if(typeof _89==="string"){
_89=_89.replace(/(<(\w+)[^>]*?)\/>/g,function(all,_8a,tag){
return tag.match(/^(abbr|br|col|img|input|link|meta|param|hr|area|embed)$/i)?all:_8a+"></"+tag+">";
});
var _8b=_89.replace(/^\s+/,"").substring(0,10).toLowerCase();
var _8c=!_8b.indexOf("<opt")&&[1,"<select multiple='multiple'>","</select>"]||!_8b.indexOf("<leg")&&[1,"<fieldset>","</fieldset>"]||_8b.match(/^<(thead|tbody|tfoot|colg|cap)/)&&[1,"<table>","</table>"]||!_8b.indexOf("<tr")&&[2,"<table><tbody>","</tbody></table>"]||(!_8b.indexOf("<td")||!_8b.indexOf("<th"))&&[3,"<table><tbody><tr>","</tr></tbody></table>"]||!_8b.indexOf("<col")&&[2,"<table><tbody></tbody><colgroup>","</colgroup></table>"]||!_5.support.htmlSerialize&&[1,"div<div>","</div>"]||[0,"",""];
div.innerHTML=_8c[1]+_89+_8c[2];
while(_8c[0]--){
div=div.lastChild;
}
if(!_5.support.tbody){
var _8d=/<tbody/i.test(_89),_8e=!_8b.indexOf("<table")&&!_8d?div.firstChild&&div.firstChild.childNodes:_8c[1]=="<table>"&&!_8d?div.childNodes:[];
for(var j=_8e.length-1;j>=0;--j){
if(_5.nodeName(_8e[j],"tbody")&&!_8e[j].childNodes.length){
_8e[j].parentNode.removeChild(_8e[j]);
}
}
}
if(!_5.support.leadingWhitespace&&/^\s/.test(_89)){
div.insertBefore(_85.createTextNode(_89.match(/^\s*/)[0]),div.firstChild);
}
_89=_5.makeArray(div.childNodes);
}
if(_89.nodeType){
ret.push(_89);
}else{
ret=_5.merge(ret,_89);
}
});
if(_86){
for(var i=0;ret[i];i++){
if(_5.nodeName(ret[i],"script")&&(!ret[i].type||ret[i].type.toLowerCase()==="text/javascript")){
_88.push(ret[i].parentNode?ret[i].parentNode.removeChild(ret[i]):ret[i]);
}else{
if(ret[i].nodeType===1){
ret.splice.apply(ret,[i+1,0].concat(_5.makeArray(ret[i].getElementsByTagName("script"))));
}
_86.appendChild(ret[i]);
}
}
return _88;
}
return ret;
},attr:function(_8f,_90,_91){
if(!_8f||_8f.nodeType==3||_8f.nodeType==8){
return _2;
}
var _92=!_5.isXMLDoc(_8f),set=_91!==_2;
_90=_92&&_5.props[_90]||_90;
if(_8f.tagName){
var _93=/href|src|style/.test(_90);
if(_90=="selected"&&_8f.parentNode){
_8f.parentNode.selectedIndex;
}
if(_90 in _8f&&_92&&!_93){
if(set){
if(_90=="type"&&_5.nodeName(_8f,"input")&&_8f.parentNode){
throw "type property can't be changed";
}
_8f[_90]=_91;
}
if(_5.nodeName(_8f,"form")&&_8f.getAttributeNode(_90)){
return _8f.getAttributeNode(_90).nodeValue;
}
if(_90=="tabIndex"){
var _94=_8f.getAttributeNode("tabIndex");
return _94&&_94.specified?_94.value:_8f.nodeName.match(/(button|input|object|select|textarea)/i)?0:_8f.nodeName.match(/^(a|area)$/i)&&_8f.href?0:_2;
}
return _8f[_90];
}
if(!_5.support.style&&_92&&_90=="style"){
return _5.attr(_8f.style,"cssText",_91);
}
if(set){
_8f.setAttribute(_90,""+_91);
}
var _95=!_5.support.hrefNormalized&&_92&&_93?_8f.getAttribute(_90,2):_8f.getAttribute(_90);
return _95===null?_2:_95;
}
if(!_5.support.opacity&&_90=="opacity"){
if(set){
_8f.zoom=1;
_8f.filter=(_8f.filter||"").replace(/alpha\([^)]*\)/,"")+(parseInt(_91)+""=="NaN"?"":"alpha(opacity="+_91*100+")");
}
return _8f.filter&&_8f.filter.indexOf("opacity=")>=0?(parseFloat(_8f.filter.match(/opacity=([^)]*)/)[1])/100)+"":"";
}
_90=_90.replace(/-([a-z])/ig,function(all,_96){
return _96.toUpperCase();
});
if(set){
_8f[_90]=_91;
}
return _8f[_90];
},trim:function(_97){
return (_97||"").replace(/^\s+|\s+$/g,"");
},makeArray:function(_98){
var ret=[];
if(_98!=null){
var i=_98.length;
if(i==null||typeof _98==="string"||_5.isFunction(_98)||_98.setInterval){
ret[0]=_98;
}else{
while(i){
ret[--i]=_98[i];
}
}
}
return ret;
},inArray:function(_99,_9a){
for(var i=0,_9b=_9a.length;i<_9b;i++){
if(_9a[i]===_99){
return i;
}
}
return -1;
},merge:function(_9c,_9d){
var i=0,_9e,pos=_9c.length;
if(!_5.support.getAll){
while((_9e=_9d[i++])!=null){
if(_9e.nodeType!=8){
_9c[pos++]=_9e;
}
}
}else{
while((_9e=_9d[i++])!=null){
_9c[pos++]=_9e;
}
}
return _9c;
},unique:function(_9f){
var ret=[],_a0={};
try{
for(var i=0,_a1=_9f.length;i<_a1;i++){
var id=_5.data(_9f[i]);
if(!_a0[id]){
_a0[id]=true;
ret.push(_9f[i]);
}
}
}
catch(e){
ret=_9f;
}
return ret;
},grep:function(_a2,_a3,inv){
var ret=[];
for(var i=0,_a4=_a2.length;i<_a4;i++){
if(!inv!=!_a3(_a2[i],i)){
ret.push(_a2[i]);
}
}
return ret;
},map:function(_a5,_a6){
var ret=[];
for(var i=0,_a7=_a5.length;i<_a7;i++){
var _a8=_a6(_a5[i],i);
if(_a8!=null){
ret[ret.length]=_a8;
}
}
return ret.concat.apply([],ret);
}});
var _a9=navigator.userAgent.toLowerCase();
_5.browser={version:(_a9.match(/.+(?:rv|it|ra|ie)[\/: ]([\d.]+)/)||[0,"0"])[1],safari:/webkit/.test(_a9),opera:/opera/.test(_a9),msie:/msie/.test(_a9)&&!/opera/.test(_a9),mozilla:/mozilla/.test(_a9)&&!/(compatible|webkit)/.test(_a9)};
_5.each({parent:function(_aa){
return _aa.parentNode;
},parents:function(_ab){
return _5.dir(_ab,"parentNode");
},next:function(_ac){
return _5.nth(_ac,2,"nextSibling");
},prev:function(_ad){
return _5.nth(_ad,2,"previousSibling");
},nextAll:function(_ae){
return _5.dir(_ae,"nextSibling");
},prevAll:function(_af){
return _5.dir(_af,"previousSibling");
},siblings:function(_b0){
return _5.sibling(_b0.parentNode.firstChild,_b0);
},children:function(_b1){
return _5.sibling(_b1.firstChild);
},contents:function(_b2){
return _5.nodeName(_b2,"iframe")?_b2.contentDocument||_b2.contentWindow.document:_5.makeArray(_b2.childNodes);
}},function(_b3,fn){
_5.fn[_b3]=function(_b4){
var ret=_5.map(this,fn);
if(_b4&&typeof _b4=="string"){
ret=_5.multiFilter(_b4,ret);
}
return this.pushStack(_5.unique(ret),_b3,_b4);
};
});
_5.each({appendTo:"append",prependTo:"prepend",insertBefore:"before",insertAfter:"after",replaceAll:"replaceWith"},function(_b5,_b6){
_5.fn[_b5]=function(_b7){
var ret=[],_b8=_5(_b7);
for(var i=0,l=_b8.length;i<l;i++){
var _b9=(i>0?this.clone(true):this).get();
_5.fn[_b6].apply(_5(_b8[i]),_b9);
ret=ret.concat(_b9);
}
return this.pushStack(ret,_b5,_b7);
};
});
_5.each({removeAttr:function(_ba){
_5.attr(this,_ba,"");
if(this.nodeType==1){
this.removeAttribute(_ba);
}
},addClass:function(_bb){
_5.className.add(this,_bb);
},removeClass:function(_bc){
_5.className.remove(this,_bc);
},toggleClass:function(_bd,_be){
if(typeof _be!=="boolean"){
_be=!_5.className.has(this,_bd);
}
_5.className[_be?"add":"remove"](this,_bd);
},remove:function(_bf){
if(!_bf||_5.filter(_bf,[this]).length){
_5("*",this).add([this]).each(function(){
_5.event.remove(this);
_5.removeData(this);
});
if(this.parentNode){
this.parentNode.removeChild(this);
}
}
},empty:function(){
_5(this).children().remove();
while(this.firstChild){
this.removeChild(this.firstChild);
}
}},function(_c0,fn){
_5.fn[_c0]=function(){
return this.each(fn,arguments);
};
});
function num(_c1,_c2){
return _c1[0]&&parseInt(_5.curCSS(_c1[0],_c2,true),10)||0;
};
var _c3="jQuery"+now(),_c4=0,_c5={};
_5.extend({cache:{},data:function(_c6,_c7,_c8){
_c6=_c6==_1?_c5:_c6;
var id=_c6[_c3];
if(!id){
id=_c6[_c3]=++_c4;
}
if(_c7&&!_5.cache[id]){
_5.cache[id]={};
}
if(_c8!==_2){
_5.cache[id][_c7]=_c8;
}
return _c7?_5.cache[id][_c7]:id;
},removeData:function(_c9,_ca){
_c9=_c9==_1?_c5:_c9;
var id=_c9[_c3];
if(_ca){
if(_5.cache[id]){
delete _5.cache[id][_ca];
_ca="";
for(_ca in _5.cache[id]){
break;
}
if(!_ca){
_5.removeData(_c9);
}
}
}else{
try{
delete _c9[_c3];
}
catch(e){
if(_c9.removeAttribute){
_c9.removeAttribute(_c3);
}
}
delete _5.cache[id];
}
},queue:function(_cb,_cc,_cd){
if(_cb){
_cc=(_cc||"fx")+"queue";
var q=_5.data(_cb,_cc);
if(!q||_5.isArray(_cd)){
q=_5.data(_cb,_cc,_5.makeArray(_cd));
}else{
if(_cd){
q.push(_cd);
}
}
}
return q;
},dequeue:function(_ce,_cf){
var _d0=_5.queue(_ce,_cf),fn=_d0.shift();
if(!_cf||_cf==="fx"){
fn=_d0[0];
}
if(fn!==_2){
fn.call(_ce);
}
}});
_5.fn.extend({data:function(key,_d1){
var _d2=key.split(".");
_d2[1]=_d2[1]?"."+_d2[1]:"";
if(_d1===_2){
var _d3=this.triggerHandler("getData"+_d2[1]+"!",[_d2[0]]);
if(_d3===_2&&this.length){
_d3=_5.data(this[0],key);
}
return _d3===_2&&_d2[1]?this.data(_d2[0]):_d3;
}else{
return this.trigger("setData"+_d2[1]+"!",[_d2[0],_d1]).each(function(){
_5.data(this,key,_d1);
});
}
},removeData:function(key){
return this.each(function(){
_5.removeData(this,key);
});
},queue:function(_d4,_d5){
if(typeof _d4!=="string"){
_d5=_d4;
_d4="fx";
}
if(_d5===_2){
return _5.queue(this[0],_d4);
}
return this.each(function(){
var _d6=_5.queue(this,_d4,_d5);
if(_d4=="fx"&&_d6.length==1){
_d6[0].call(this);
}
});
},dequeue:function(_d7){
return this.each(function(){
_5.dequeue(this,_d7);
});
}});
(function(){
var _d8=/((?:\((?:\([^()]+\)|[^()]+)+\)|\[(?:\[[^[\]]*\]|['"][^'"]*['"]|[^[\]'"]+)+\]|\\.|[^ >+~,(\[\\]+)+|[>+~])(\s*,\s*)?/g,_d9=0,_55=Object.prototype.toString;
var _da=function(_db,_dc,_dd,_de){
_dd=_dd||[];
_dc=_dc||document;
if(_dc.nodeType!==1&&_dc.nodeType!==9){
return [];
}
if(!_db||typeof _db!=="string"){
return _dd;
}
var _df=[],m,set,_e0,_e1,_e2,_e3,_e4=true;
_d8.lastIndex=0;
while((m=_d8.exec(_db))!==null){
_df.push(m[1]);
if(m[2]){
_e3=RegExp.rightContext;
break;
}
}
if(_df.length>1&&_e5.exec(_db)){
if(_df.length===2&&_e6.relative[_df[0]]){
set=_e7(_df[0]+_df[1],_dc);
}else{
set=_e6.relative[_df[0]]?[_dc]:_da(_df.shift(),_dc);
while(_df.length){
_db=_df.shift();
if(_e6.relative[_db]){
_db+=_df.shift();
}
set=_e7(_db,set);
}
}
}else{
var ret=_de?{expr:_df.pop(),set:_e8(_de)}:_da.find(_df.pop(),_df.length===1&&_dc.parentNode?_dc.parentNode:_dc,_e9(_dc));
set=_da.filter(ret.expr,ret.set);
if(_df.length>0){
_e0=_e8(set);
}else{
_e4=false;
}
while(_df.length){
var cur=_df.pop(),pop=cur;
if(!_e6.relative[cur]){
cur="";
}else{
pop=_df.pop();
}
if(pop==null){
pop=_dc;
}
_e6.relative[cur](_e0,pop,_e9(_dc));
}
}
if(!_e0){
_e0=set;
}
if(!_e0){
throw "Syntax error, unrecognized expression: "+(cur||_db);
}
if(_55.call(_e0)==="[object Array]"){
if(!_e4){
_dd.push.apply(_dd,_e0);
}else{
if(_dc.nodeType===1){
for(var i=0;_e0[i]!=null;i++){
if(_e0[i]&&(_e0[i]===true||_e0[i].nodeType===1&&_ea(_dc,_e0[i]))){
_dd.push(set[i]);
}
}
}else{
for(var i=0;_e0[i]!=null;i++){
if(_e0[i]&&_e0[i].nodeType===1){
_dd.push(set[i]);
}
}
}
}
}else{
_e8(_e0,_dd);
}
if(_e3){
_da(_e3,_dc,_dd,_de);
if(_eb){
hasDuplicate=false;
_dd.sort(_eb);
if(hasDuplicate){
for(var i=1;i<_dd.length;i++){
if(_dd[i]===_dd[i-1]){
_dd.splice(i--,1);
}
}
}
}
}
return _dd;
};
_da.matches=function(_ec,set){
return _da(_ec,null,null,set);
};
_da.find=function(_ed,_ee,_ef){
var set,_f0;
if(!_ed){
return [];
}
for(var i=0,l=_e6.order.length;i<l;i++){
var _f1=_e6.order[i],_f0;
if((_f0=_e6.match[_f1].exec(_ed))){
var _f2=RegExp.leftContext;
if(_f2.substr(_f2.length-1)!=="\\"){
_f0[1]=(_f0[1]||"").replace(/\\/g,"");
set=_e6.find[_f1](_f0,_ee,_ef);
if(set!=null){
_ed=_ed.replace(_e6.match[_f1],"");
break;
}
}
}
}
if(!set){
set=_ee.getElementsByTagName("*");
}
return {set:set,expr:_ed};
};
_da.filter=function(_f3,set,_f4,not){
var old=_f3,_f5=[],_f6=set,_f7,_f8,_f9=set&&set[0]&&_e9(set[0]);
while(_f3&&set.length){
for(var _fa in _e6.filter){
if((_f7=_e6.match[_fa].exec(_f3))!=null){
var _fb=_e6.filter[_fa],_fc,_fd;
_f8=false;
if(_f6==_f5){
_f5=[];
}
if(_e6.preFilter[_fa]){
_f7=_e6.preFilter[_fa](_f7,_f6,_f4,_f5,not,_f9);
if(!_f7){
_f8=_fc=true;
}else{
if(_f7===true){
continue;
}
}
}
if(_f7){
for(var i=0;(_fd=_f6[i])!=null;i++){
if(_fd){
_fc=_fb(_fd,_f7,i,_f6);
var _fe=not^!!_fc;
if(_f4&&_fc!=null){
if(_fe){
_f8=true;
}else{
_f6[i]=false;
}
}else{
if(_fe){
_f5.push(_fd);
_f8=true;
}
}
}
}
}
if(_fc!==_2){
if(!_f4){
_f6=_f5;
}
_f3=_f3.replace(_e6.match[_fa],"");
if(!_f8){
return [];
}
break;
}
}
}
if(_f3==old){
if(_f8==null){
throw "Syntax error, unrecognized expression: "+_f3;
}else{
break;
}
}
old=_f3;
}
return _f6;
};
var _e6=_da.selectors={order:["ID","NAME","TAG"],match:{ID:/#((?:[\w\u00c0-\uFFFF_-]|\\.)+)/,CLASS:/\.((?:[\w\u00c0-\uFFFF_-]|\\.)+)/,NAME:/\[name=['"]*((?:[\w\u00c0-\uFFFF_-]|\\.)+)['"]*\]/,ATTR:/\[\s*((?:[\w\u00c0-\uFFFF_-]|\\.)+)\s*(?:(\S?=)\s*(['"]*)(.*?)\3|)\s*\]/,TAG:/^((?:[\w\u00c0-\uFFFF\*_-]|\\.)+)/,CHILD:/:(only|nth|last|first)-child(?:\((even|odd|[\dn+-]*)\))?/,POS:/:(nth|eq|gt|lt|first|last|even|odd)(?:\((\d*)\))?(?=[^-]|$)/,PSEUDO:/:((?:[\w\u00c0-\uFFFF_-]|\\.)+)(?:\((['"]*)((?:\([^\)]+\)|[^\2\(\)]*)+)\2\))?/},attrMap:{"class":"className","for":"htmlFor"},attrHandle:{href:function(_ff){
return _ff.getAttribute("href");
}},relative:{"+":function(_100,part,_101){
var _102=typeof part==="string",_103=_102&&!/\W/.test(part),_104=_102&&!_103;
if(_103&&!_101){
part=part.toUpperCase();
}
for(var i=0,l=_100.length,elem;i<l;i++){
if((elem=_100[i])){
while((elem=elem.previousSibling)&&elem.nodeType!==1){
}
_100[i]=_104||elem&&elem.nodeName===part?elem||false:elem===part;
}
}
if(_104){
_da.filter(part,_100,true);
}
},">":function(_105,part,_106){
var _107=typeof part==="string";
if(_107&&!/\W/.test(part)){
part=_106?part:part.toUpperCase();
for(var i=0,l=_105.length;i<l;i++){
var elem=_105[i];
if(elem){
var _108=elem.parentNode;
_105[i]=_108.nodeName===part?_108:false;
}
}
}else{
for(var i=0,l=_105.length;i<l;i++){
var elem=_105[i];
if(elem){
_105[i]=_107?elem.parentNode:elem.parentNode===part;
}
}
if(_107){
_da.filter(part,_105,true);
}
}
},"":function(_109,part,_10a){
var _10b=_d9++,_10c=_10d;
if(!part.match(/\W/)){
var _10e=part=_10a?part:part.toUpperCase();
_10c=_10f;
}
_10c("parentNode",part,_10b,_109,_10e,_10a);
},"~":function(_110,part,_111){
var _112=_d9++,_113=_10d;
if(typeof part==="string"&&!part.match(/\W/)){
var _114=part=_111?part:part.toUpperCase();
_113=_10f;
}
_113("previousSibling",part,_112,_110,_114,_111);
}},find:{ID:function(_115,_116,_117){
if(typeof _116.getElementById!=="undefined"&&!_117){
var m=_116.getElementById(_115[1]);
return m?[m]:[];
}
},NAME:function(_118,_119,_11a){
if(typeof _119.getElementsByName!=="undefined"){
var ret=[],_11b=_119.getElementsByName(_118[1]);
for(var i=0,l=_11b.length;i<l;i++){
if(_11b[i].getAttribute("name")===_118[1]){
ret.push(_11b[i]);
}
}
return ret.length===0?null:ret;
}
},TAG:function(_11c,_11d){
return _11d.getElementsByTagName(_11c[1]);
}},preFilter:{CLASS:function(_11e,_11f,_120,_121,not,_122){
_11e=" "+_11e[1].replace(/\\/g,"")+" ";
if(_122){
return _11e;
}
for(var i=0,elem;(elem=_11f[i])!=null;i++){
if(elem){
if(not^(elem.className&&(" "+elem.className+" ").indexOf(_11e)>=0)){
if(!_120){
_121.push(elem);
}
}else{
if(_120){
_11f[i]=false;
}
}
}
}
return false;
},ID:function(_123){
return _123[1].replace(/\\/g,"");
},TAG:function(_124,_125){
for(var i=0;_125[i]===false;i++){
}
return _125[i]&&_e9(_125[i])?_124[1]:_124[1].toUpperCase();
},CHILD:function(_126){
if(_126[1]=="nth"){
var test=/(-?)(\d*)n((?:\+|-)?\d*)/.exec(_126[2]=="even"&&"2n"||_126[2]=="odd"&&"2n+1"||!/\D/.test(_126[2])&&"0n+"+_126[2]||_126[2]);
_126[2]=(test[1]+(test[2]||1))-0;
_126[3]=test[3]-0;
}
_126[0]=_d9++;
return _126;
},ATTR:function(_127,_128,_129,_12a,not,_12b){
var name=_127[1].replace(/\\/g,"");
if(!_12b&&_e6.attrMap[name]){
_127[1]=_e6.attrMap[name];
}
if(_127[2]==="~="){
_127[4]=" "+_127[4]+" ";
}
return _127;
},PSEUDO:function(_12c,_12d,_12e,_12f,not){
if(_12c[1]==="not"){
if(_12c[3].match(_d8).length>1||/^\w/.test(_12c[3])){
_12c[3]=_da(_12c[3],null,null,_12d);
}else{
var ret=_da.filter(_12c[3],_12d,_12e,true^not);
if(!_12e){
_12f.push.apply(_12f,ret);
}
return false;
}
}else{
if(_e6.match.POS.test(_12c[0])||_e6.match.CHILD.test(_12c[0])){
return true;
}
}
return _12c;
},POS:function(_130){
_130.unshift(true);
return _130;
}},filters:{enabled:function(elem){
return elem.disabled===false&&elem.type!=="hidden";
},disabled:function(elem){
return elem.disabled===true;
},checked:function(elem){
return elem.checked===true;
},selected:function(elem){
elem.parentNode.selectedIndex;
return elem.selected===true;
},parent:function(elem){
return !!elem.firstChild;
},empty:function(elem){
return !elem.firstChild;
},has:function(elem,i,_131){
return !!_da(_131[3],elem).length;
},header:function(elem){
return /h\d/i.test(elem.nodeName);
},text:function(elem){
return "text"===elem.type;
},radio:function(elem){
return "radio"===elem.type;
},checkbox:function(elem){
return "checkbox"===elem.type;
},file:function(elem){
return "file"===elem.type;
},password:function(elem){
return "password"===elem.type;
},submit:function(elem){
return "submit"===elem.type;
},image:function(elem){
return "image"===elem.type;
},reset:function(elem){
return "reset"===elem.type;
},button:function(elem){
return "button"===elem.type||elem.nodeName.toUpperCase()==="BUTTON";
},input:function(elem){
return /input|select|textarea|button/i.test(elem.nodeName);
}},setFilters:{first:function(elem,i){
return i===0;
},last:function(elem,i,_132,_133){
return i===_133.length-1;
},even:function(elem,i){
return i%2===0;
},odd:function(elem,i){
return i%2===1;
},lt:function(elem,i,_134){
return i<_134[3]-0;
},gt:function(elem,i,_135){
return i>_135[3]-0;
},nth:function(elem,i,_136){
return _136[3]-0==i;
},eq:function(elem,i,_137){
return _137[3]-0==i;
}},filter:{PSEUDO:function(elem,_138,i,_139){
var name=_138[1],_13a=_e6.filters[name];
if(_13a){
return _13a(elem,i,_138,_139);
}else{
if(name==="contains"){
return (elem.textContent||elem.innerText||"").indexOf(_138[3])>=0;
}else{
if(name==="not"){
var not=_138[3];
for(var i=0,l=not.length;i<l;i++){
if(not[i]===elem){
return false;
}
}
return true;
}
}
}
},CHILD:function(elem,_13b){
var type=_13b[1],node=elem;
switch(type){
case "only":
case "first":
while(node=node.previousSibling){
if(node.nodeType===1){
return false;
}
}
if(type=="first"){
return true;
}
node=elem;
case "last":
while(node=node.nextSibling){
if(node.nodeType===1){
return false;
}
}
return true;
case "nth":
var _13c=_13b[2],last=_13b[3];
if(_13c==1&&last==0){
return true;
}
var _13d=_13b[0],_13e=elem.parentNode;
if(_13e&&(_13e.sizcache!==_13d||!elem.nodeIndex)){
var _13f=0;
for(node=_13e.firstChild;node;node=node.nextSibling){
if(node.nodeType===1){
node.nodeIndex=++_13f;
}
}
_13e.sizcache=_13d;
}
var diff=elem.nodeIndex-last;
if(_13c==0){
return diff==0;
}else{
return (diff%_13c==0&&diff/_13c>=0);
}
}
},ID:function(elem,_140){
return elem.nodeType===1&&elem.getAttribute("id")===_140;
},TAG:function(elem,_141){
return (_141==="*"&&elem.nodeType===1)||elem.nodeName===_141;
},CLASS:function(elem,_142){
return (" "+(elem.className||elem.getAttribute("class"))+" ").indexOf(_142)>-1;
},ATTR:function(elem,_143){
var name=_143[1],_144=_e6.attrHandle[name]?_e6.attrHandle[name](elem):elem[name]!=null?elem[name]:elem.getAttribute(name),_145=_144+"",type=_143[2],_146=_143[4];
return _144==null?type==="!=":type==="="?_145===_146:type==="*="?_145.indexOf(_146)>=0:type==="~="?(" "+_145+" ").indexOf(_146)>=0:!_146?_145&&_144!==false:type==="!="?_145!=_146:type==="^="?_145.indexOf(_146)===0:type==="$="?_145.substr(_145.length-_146.length)===_146:type==="|="?_145===_146||_145.substr(0,_146.length+1)===_146+"-":false;
},POS:function(elem,_147,i,_148){
var name=_147[2],_149=_e6.setFilters[name];
if(_149){
return _149(elem,i,_147,_148);
}
}}};
var _e5=_e6.match.POS;
for(var type in _e6.match){
_e6.match[type]=RegExp(_e6.match[type].source+/(?![^\[]*\])(?![^\(]*\))/.source);
}
var _e8=function(_14a,_14b){
_14a=Array.prototype.slice.call(_14a);
if(_14b){
_14b.push.apply(_14b,_14a);
return _14b;
}
return _14a;
};
try{
Array.prototype.slice.call(document.documentElement.childNodes);
}
catch(e){
_e8=function(_14c,_14d){
var ret=_14d||[];
if(_55.call(_14c)==="[object Array]"){
Array.prototype.push.apply(ret,_14c);
}else{
if(typeof _14c.length==="number"){
for(var i=0,l=_14c.length;i<l;i++){
ret.push(_14c[i]);
}
}else{
for(var i=0;_14c[i];i++){
ret.push(_14c[i]);
}
}
}
return ret;
};
}
var _eb;
if(document.documentElement.compareDocumentPosition){
_eb=function(a,b){
var ret=a.compareDocumentPosition(b)&4?-1:a===b?0:1;
if(ret===0){
hasDuplicate=true;
}
return ret;
};
}else{
if("sourceIndex" in document.documentElement){
_eb=function(a,b){
var ret=a.sourceIndex-b.sourceIndex;
if(ret===0){
hasDuplicate=true;
}
return ret;
};
}else{
if(document.createRange){
_eb=function(a,b){
var _14e=a.ownerDocument.createRange(),_14f=b.ownerDocument.createRange();
_14e.selectNode(a);
_14e.collapse(true);
_14f.selectNode(b);
_14f.collapse(true);
var ret=_14e.compareBoundaryPoints(Range.START_TO_END,_14f);
if(ret===0){
hasDuplicate=true;
}
return ret;
};
}
}
}
(function(){
var form=document.createElement("form"),id="script"+(new Date).getTime();
form.innerHTML="<input name='"+id+"'/>";
var root=document.documentElement;
root.insertBefore(form,root.firstChild);
if(!!document.getElementById(id)){
_e6.find.ID=function(_150,_151,_152){
if(typeof _151.getElementById!=="undefined"&&!_152){
var m=_151.getElementById(_150[1]);
return m?m.id===_150[1]||typeof m.getAttributeNode!=="undefined"&&m.getAttributeNode("id").nodeValue===_150[1]?[m]:_2:[];
}
};
_e6.filter.ID=function(elem,_153){
var node=typeof elem.getAttributeNode!=="undefined"&&elem.getAttributeNode("id");
return elem.nodeType===1&&node&&node.nodeValue===_153;
};
}
root.removeChild(form);
})();
(function(){
var div=document.createElement("div");
div.appendChild(document.createComment(""));
if(div.getElementsByTagName("*").length>0){
_e6.find.TAG=function(_154,_155){
var _156=_155.getElementsByTagName(_154[1]);
if(_154[1]==="*"){
var tmp=[];
for(var i=0;_156[i];i++){
if(_156[i].nodeType===1){
tmp.push(_156[i]);
}
}
_156=tmp;
}
return _156;
};
}
div.innerHTML="<a href='#'></a>";
if(div.firstChild&&typeof div.firstChild.getAttribute!=="undefined"&&div.firstChild.getAttribute("href")!=="#"){
_e6.attrHandle.href=function(elem){
return elem.getAttribute("href",2);
};
}
})();
if(document.querySelectorAll){
(function(){
var _157=_da,div=document.createElement("div");
div.innerHTML="<p class='TEST'></p>";
if(div.querySelectorAll&&div.querySelectorAll(".TEST").length===0){
return;
}
_da=function(_158,_159,_15a,seed){
_159=_159||document;
if(!seed&&_159.nodeType===9&&!_e9(_159)){
try{
return _e8(_159.querySelectorAll(_158),_15a);
}
catch(e){
}
}
return _157(_158,_159,_15a,seed);
};
_da.find=_157.find;
_da.filter=_157.filter;
_da.selectors=_157.selectors;
_da.matches=_157.matches;
})();
}
if(document.getElementsByClassName&&document.documentElement.getElementsByClassName){
(function(){
var div=document.createElement("div");
div.innerHTML="<div class='test e'></div><div class='test'></div>";
if(div.getElementsByClassName("e").length===0){
return;
}
div.lastChild.className="e";
if(div.getElementsByClassName("e").length===1){
return;
}
_e6.order.splice(1,0,"CLASS");
_e6.find.CLASS=function(_15b,_15c,_15d){
if(typeof _15c.getElementsByClassName!=="undefined"&&!_15d){
return _15c.getElementsByClassName(_15b[1]);
}
};
})();
}
function _10f(dir,cur,_15e,_15f,_160,_161){
var _162=dir=="previousSibling"&&!_161;
for(var i=0,l=_15f.length;i<l;i++){
var elem=_15f[i];
if(elem){
if(_162&&elem.nodeType===1){
elem.sizcache=_15e;
elem.sizset=i;
}
elem=elem[dir];
var _163=false;
while(elem){
if(elem.sizcache===_15e){
_163=_15f[elem.sizset];
break;
}
if(elem.nodeType===1&&!_161){
elem.sizcache=_15e;
elem.sizset=i;
}
if(elem.nodeName===cur){
_163=elem;
break;
}
elem=elem[dir];
}
_15f[i]=_163;
}
}
};
function _10d(dir,cur,_164,_165,_166,_167){
var _168=dir=="previousSibling"&&!_167;
for(var i=0,l=_165.length;i<l;i++){
var elem=_165[i];
if(elem){
if(_168&&elem.nodeType===1){
elem.sizcache=_164;
elem.sizset=i;
}
elem=elem[dir];
var _169=false;
while(elem){
if(elem.sizcache===_164){
_169=_165[elem.sizset];
break;
}
if(elem.nodeType===1){
if(!_167){
elem.sizcache=_164;
elem.sizset=i;
}
if(typeof cur!=="string"){
if(elem===cur){
_169=true;
break;
}
}else{
if(_da.filter(cur,[elem]).length>0){
_169=elem;
break;
}
}
}
elem=elem[dir];
}
_165[i]=_169;
}
}
};
var _ea=document.compareDocumentPosition?function(a,b){
return a.compareDocumentPosition(b)&16;
}:function(a,b){
return a!==b&&(a.contains?a.contains(b):true);
};
var _e9=function(elem){
return elem.nodeType===9&&elem.documentElement.nodeName!=="HTML"||!!elem.ownerDocument&&_e9(elem.ownerDocument);
};
var _e7=function(_16a,_16b){
var _16c=[],_16d="",_16e,root=_16b.nodeType?[_16b]:_16b;
while((_16e=_e6.match.PSEUDO.exec(_16a))){
_16d+=_16e[0];
_16a=_16a.replace(_e6.match.PSEUDO,"");
}
_16a=_e6.relative[_16a]?_16a+"*":_16a;
for(var i=0,l=root.length;i<l;i++){
_da(_16a,root[i],_16c);
}
return _da.filter(_16d,_16c);
};
_5.find=_da;
_5.filter=_da.filter;
_5.expr=_da.selectors;
_5.expr[":"]=_5.expr.filters;
_da.selectors.filters.hidden=function(elem){
return elem.offsetWidth===0||elem.offsetHeight===0;
};
_da.selectors.filters.visible=function(elem){
return elem.offsetWidth>0||elem.offsetHeight>0;
};
_da.selectors.filters.animated=function(elem){
return _5.grep(_5.timers,function(fn){
return elem===fn.elem;
}).length;
};
_5.multiFilter=function(expr,_16f,not){
if(not){
expr=":not("+expr+")";
}
return _da.matches(expr,_16f);
};
_5.dir=function(elem,dir){
var _170=[],cur=elem[dir];
while(cur&&cur!=document){
if(cur.nodeType==1){
_170.push(cur);
}
cur=cur[dir];
}
return _170;
};
_5.nth=function(cur,_171,dir,elem){
_171=_171||1;
var num=0;
for(;cur;cur=cur[dir]){
if(cur.nodeType==1&&++num==_171){
break;
}
}
return cur;
};
_5.sibling=function(n,elem){
var r=[];
for(;n;n=n.nextSibling){
if(n.nodeType==1&&n!=elem){
r.push(n);
}
}
return r;
};
return;
_1.Sizzle=_da;
})();
_5.event={add:function(elem,_172,_173,data){
if(elem.nodeType==3||elem.nodeType==8){
return;
}
if(elem.setInterval&&elem!=_1){
elem=_1;
}
if(!_173.guid){
_173.guid=this.guid++;
}
if(data!==_2){
var fn=_173;
_173=this.proxy(fn);
_173.data=data;
}
var _174=_5.data(elem,"events")||_5.data(elem,"events",{}),_175=_5.data(elem,"handle")||_5.data(elem,"handle",function(){
return typeof _5!=="undefined"&&!_5.event.triggered?_5.event.handle.apply(arguments.callee.elem,arguments):_2;
});
_175.elem=elem;
_5.each(_172.split(/\s+/),function(_176,type){
var _177=type.split(".");
type=_177.shift();
_173.type=_177.slice().sort().join(".");
var _178=_174[type];
if(_5.event.specialAll[type]){
_5.event.specialAll[type].setup.call(elem,data,_177);
}
if(!_178){
_178=_174[type]={};
if(!_5.event.special[type]||_5.event.special[type].setup.call(elem,data,_177)===false){
if(elem.addEventListener){
elem.addEventListener(type,_175,false);
}else{
if(elem.attachEvent){
elem.attachEvent("on"+type,_175);
}
}
}
}
_178[_173.guid]=_173;
_5.event.global[type]=true;
});
elem=null;
},guid:1,global:{},remove:function(elem,_179,_17a){
if(elem.nodeType==3||elem.nodeType==8){
return;
}
var _17b=_5.data(elem,"events"),ret,_17c;
if(_17b){
if(_179===_2||(typeof _179==="string"&&_179.charAt(0)==".")){
for(var type in _17b){
this.remove(elem,type+(_179||""));
}
}else{
if(_179.type){
_17a=_179.handler;
_179=_179.type;
}
_5.each(_179.split(/\s+/),function(_17d,type){
var _17e=type.split(".");
type=_17e.shift();
var _17f=RegExp("(^|\\.)"+_17e.slice().sort().join(".*\\.")+"(\\.|$)");
if(_17b[type]){
if(_17a){
delete _17b[type][_17a.guid];
}else{
for(var _180 in _17b[type]){
if(_17f.test(_17b[type][_180].type)){
delete _17b[type][_180];
}
}
}
if(_5.event.specialAll[type]){
_5.event.specialAll[type].teardown.call(elem,_17e);
}
for(ret in _17b[type]){
break;
}
if(!ret){
if(!_5.event.special[type]||_5.event.special[type].teardown.call(elem,_17e)===false){
if(elem.removeEventListener){
elem.removeEventListener(type,_5.data(elem,"handle"),false);
}else{
if(elem.detachEvent){
elem.detachEvent("on"+type,_5.data(elem,"handle"));
}
}
}
ret=null;
delete _17b[type];
}
}
});
}
for(ret in _17b){
break;
}
if(!ret){
var _181=_5.data(elem,"handle");
if(_181){
_181.elem=null;
}
_5.removeData(elem,"events");
_5.removeData(elem,"handle");
}
}
},trigger:function(_182,data,elem,_183){
var type=_182.type||_182;
if(!_183){
_182=typeof _182==="object"?_182[_c3]?_182:_5.extend(_5.Event(type),_182):_5.Event(type);
if(type.indexOf("!")>=0){
_182.type=type=type.slice(0,-1);
_182.exclusive=true;
}
if(!elem){
_182.stopPropagation();
if(this.global[type]){
_5.each(_5.cache,function(){
if(this.events&&this.events[type]){
_5.event.trigger(_182,data,this.handle.elem);
}
});
}
}
if(!elem||elem.nodeType==3||elem.nodeType==8){
return _2;
}
_182.result=_2;
_182.target=elem;
data=_5.makeArray(data);
data.unshift(_182);
}
_182.currentTarget=elem;
var _184=_5.data(elem,"handle");
if(_184){
_184.apply(elem,data);
}
if((!elem[type]||(_5.nodeName(elem,"a")&&type=="click"))&&elem["on"+type]&&elem["on"+type].apply(elem,data)===false){
_182.result=false;
}
if(!_183&&elem[type]&&!_182.isDefaultPrevented()&&!(_5.nodeName(elem,"a")&&type=="click")){
this.triggered=true;
try{
elem[type]();
}
catch(e){
}
}
this.triggered=false;
if(!_182.isPropagationStopped()){
var _185=elem.parentNode||elem.ownerDocument;
if(_185){
_5.event.trigger(_182,data,_185,true);
}
}
},handle:function(_186){
var all,_187;
_186=arguments[0]=_5.event.fix(_186||_1.event);
_186.currentTarget=this;
var _188=_186.type.split(".");
_186.type=_188.shift();
all=!_188.length&&!_186.exclusive;
var _189=RegExp("(^|\\.)"+_188.slice().sort().join(".*\\.")+"(\\.|$)");
_187=(_5.data(this,"events")||{})[_186.type];
for(var j in _187){
var _18a=_187[j];
if(all||_189.test(_18a.type)){
_186.handler=_18a;
_186.data=_18a.data;
var ret=_18a.apply(this,arguments);
if(ret!==_2){
_186.result=ret;
if(ret===false){
_186.preventDefault();
_186.stopPropagation();
}
}
if(_186.isImmediatePropagationStopped()){
break;
}
}
}
},props:"altKey attrChange attrName bubbles button cancelable charCode clientX clientY ctrlKey currentTarget data detail eventPhase fromElement handler keyCode metaKey newValue originalTarget pageX pageY prevValue relatedNode relatedTarget screenX screenY shiftKey srcElement target toElement view wheelDelta which".split(" "),fix:function(_18b){
if(_18b[_c3]){
return _18b;
}
var _18c=_18b;
_18b=_5.Event(_18c);
for(var i=this.props.length,prop;i;){
prop=this.props[--i];
_18b[prop]=_18c[prop];
}
if(!_18b.target){
_18b.target=_18b.srcElement||document;
}
if(_18b.target.nodeType==3){
_18b.target=_18b.target.parentNode;
}
if(!_18b.relatedTarget&&_18b.fromElement){
_18b.relatedTarget=_18b.fromElement==_18b.target?_18b.toElement:_18b.fromElement;
}
if(_18b.pageX==null&&_18b.clientX!=null){
var doc=document.documentElement,body=document.body;
_18b.pageX=_18b.clientX+(doc&&doc.scrollLeft||body&&body.scrollLeft||0)-(doc.clientLeft||0);
_18b.pageY=_18b.clientY+(doc&&doc.scrollTop||body&&body.scrollTop||0)-(doc.clientTop||0);
}
if(!_18b.which&&((_18b.charCode||_18b.charCode===0)?_18b.charCode:_18b.keyCode)){
_18b.which=_18b.charCode||_18b.keyCode;
}
if(!_18b.metaKey&&_18b.ctrlKey){
_18b.metaKey=_18b.ctrlKey;
}
if(!_18b.which&&_18b.button){
_18b.which=(_18b.button&1?1:(_18b.button&2?3:(_18b.button&4?2:0)));
}
return _18b;
},proxy:function(fn,_18d){
_18d=_18d||function(){
return fn.apply(this,arguments);
};
_18d.guid=fn.guid=fn.guid||_18d.guid||this.guid++;
return _18d;
},special:{ready:{setup:_18e,teardown:function(){
}}},specialAll:{live:{setup:function(_18f,_190){
_5.event.add(this,_190[0],_191);
},teardown:function(_192){
if(_192.length){
var _193=0,name=RegExp("(^|\\.)"+_192[0]+"(\\.|$)");
_5.each((_5.data(this,"events").live||{}),function(){
if(name.test(this.type)){
_193++;
}
});
if(_193<1){
_5.event.remove(this,_192[0],_191);
}
}
}}}};
_5.Event=function(src){
if(!this.preventDefault){
return new _5.Event(src);
}
if(src&&src.type){
this.originalEvent=src;
this.type=src.type;
}else{
this.type=src;
}
this.timeStamp=now();
this[_c3]=true;
};
function _194(){
return false;
};
function _195(){
return true;
};
_5.Event.prototype={preventDefault:function(){
this.isDefaultPrevented=_195;
var e=this.originalEvent;
if(!e){
return;
}
if(e.preventDefault){
e.preventDefault();
}
e.returnValue=false;
},stopPropagation:function(){
this.isPropagationStopped=_195;
var e=this.originalEvent;
if(!e){
return;
}
if(e.stopPropagation){
e.stopPropagation();
}
e.cancelBubble=true;
},stopImmediatePropagation:function(){
this.isImmediatePropagationStopped=_195;
this.stopPropagation();
},isDefaultPrevented:_194,isPropagationStopped:_194,isImmediatePropagationStopped:_194};
var _196=function(_197){
var _198=_197.relatedTarget;
while(_198&&_198!=this){
try{
_198=_198.parentNode;
}
catch(e){
_198=this;
}
}
if(_198!=this){
_197.type=_197.data;
_5.event.handle.apply(this,arguments);
}
};
_5.each({mouseover:"mouseenter",mouseout:"mouseleave"},function(orig,fix){
_5.event.special[fix]={setup:function(){
_5.event.add(this,orig,_196,fix);
},teardown:function(){
_5.event.remove(this,orig,_196);
}};
});
_5.fn.extend({bind:function(type,data,fn){
return type=="unload"?this.one(type,data,fn):this.each(function(){
_5.event.add(this,type,fn||data,fn&&data);
});
},one:function(type,data,fn){
var one=_5.event.proxy(fn||data,function(_199){
_5(this).unbind(_199,one);
return (fn||data).apply(this,arguments);
});
return this.each(function(){
_5.event.add(this,type,one,fn&&data);
});
},unbind:function(type,fn){
return this.each(function(){
_5.event.remove(this,type,fn);
});
},trigger:function(type,data){
return this.each(function(){
_5.event.trigger(type,data,this);
});
},triggerHandler:function(type,data){
if(this[0]){
var _19a=_5.Event(type);
_19a.preventDefault();
_19a.stopPropagation();
_5.event.trigger(_19a,data,this[0]);
return _19a.result;
}
},toggle:function(fn){
var args=arguments,i=1;
while(i<args.length){
_5.event.proxy(fn,args[i++]);
}
return this.click(_5.event.proxy(fn,function(_19b){
this.lastToggle=(this.lastToggle||0)%i;
_19b.preventDefault();
return args[this.lastToggle++].apply(this,arguments)||false;
}));
},hover:function(_19c,_19d){
return this.mouseenter(_19c).mouseleave(_19d);
},ready:function(fn){
_18e();
if(_5.isReady){
fn.call(document,_5);
}else{
_5.readyList.push(fn);
}
return this;
},live:function(type,fn){
var _19e=_5.event.proxy(fn);
_19e.guid+=this.selector+type;
_5(document).bind(_19f(type,this.selector),this.selector,_19e);
return this;
},die:function(type,fn){
_5(document).unbind(_19f(type,this.selector),fn?{guid:fn.guid+this.selector+type}:null);
return this;
}});
function _191(_1a0){
var _1a1=RegExp("(^|\\.)"+_1a0.type+"(\\.|$)"),stop=true,_1a2=[];
_5.each(_5.data(this,"events").live||[],function(i,fn){
if(_1a1.test(fn.type)){
var elem=_5(_1a0.target).closest(fn.data)[0];
if(elem){
_1a2.push({elem:elem,fn:fn});
}
}
});
_1a2.sort(function(a,b){
return _5.data(a.elem,"closest")-_5.data(b.elem,"closest");
});
_5.each(_1a2,function(){
if(this.fn.call(this.elem,_1a0,this.fn.data)===false){
return (stop=false);
}
});
return stop;
};
function _19f(type,_1a3){
return ["live",type,_1a3.replace(/\./g,"`").replace(/ /g,"|")].join(".");
};
_5.extend({isReady:false,readyList:[],ready:function(){
if(!_5.isReady){
_5.isReady=true;
if(_5.readyList){
_5.each(_5.readyList,function(){
this.call(document,_5);
});
_5.readyList=null;
}
_5(document).triggerHandler("ready");
}
}});
var _1a4=false;
function _18e(){
if(_1a4){
return;
}
_1a4=true;
if(document.addEventListener){
document.addEventListener("DOMContentLoaded",function(){
document.removeEventListener("DOMContentLoaded",arguments.callee,false);
_5.ready();
},false);
}else{
if(document.attachEvent){
document.attachEvent("onreadystatechange",function(){
if(document.readyState==="complete"){
document.detachEvent("onreadystatechange",arguments.callee);
_5.ready();
}
});
if(document.documentElement.doScroll&&_1==_1.top){
(function(){
if(_5.isReady){
return;
}
try{
document.documentElement.doScroll("left");
}
catch(error){
setTimeout(arguments.callee,0);
return;
}
_5.ready();
})();
}
}
}
_5.event.add(_1,"load",_5.ready);
};
_5.each(("blur,focus,load,resize,scroll,unload,click,dblclick,"+"mousedown,mouseup,mousemove,mouseover,mouseout,mouseenter,mouseleave,"+"change,select,submit,keydown,keypress,keyup,error").split(","),function(i,name){
_5.fn[name]=function(fn){
return fn?this.bind(name,fn):this.trigger(name);
};
});
_5(_1).bind("unload",function(){
for(var id in _5.cache){
if(id!=1&&_5.cache[id].handle){
_5.event.remove(_5.cache[id].handle.elem);
}
}
});
(function(){
_5.support={};
var root=document.documentElement,_1a5=document.createElement("script"),div=document.createElement("div"),id="script"+(new Date).getTime();
div.style.display="none";
div.innerHTML="   <link/><table></table><a href=\"/a\" style=\"color:red;float:left;opacity:.5;\">a</a><select><option>text</option></select><object><param/></object>";
var all=div.getElementsByTagName("*"),a=div.getElementsByTagName("a")[0];
if(!all||!all.length||!a){
return;
}
_5.support={leadingWhitespace:div.firstChild.nodeType==3,tbody:!div.getElementsByTagName("tbody").length,objectAll:!!div.getElementsByTagName("object")[0].getElementsByTagName("*").length,htmlSerialize:!!div.getElementsByTagName("link").length,style:/red/.test(a.getAttribute("style")),hrefNormalized:a.getAttribute("href")==="/a",opacity:a.style.opacity==="0.5",cssFloat:!!a.style.cssFloat,scriptEval:false,noCloneEvent:true,boxModel:null};
_1a5.type="text/javascript";
try{
_1a5.appendChild(document.createTextNode("window."+id+"=1;"));
}
catch(e){
}
root.insertBefore(_1a5,root.firstChild);
if(_1[id]){
_5.support.scriptEval=true;
delete _1[id];
}
root.removeChild(_1a5);
if(div.attachEvent&&div.fireEvent){
div.attachEvent("onclick",function(){
_5.support.noCloneEvent=false;
div.detachEvent("onclick",arguments.callee);
});
div.cloneNode(true).fireEvent("onclick");
}
_5(function(){
var div=document.createElement("div");
div.style.width=div.style.paddingLeft="1px";
document.body.appendChild(div);
_5.boxModel=_5.support.boxModel=div.offsetWidth===2;
document.body.removeChild(div).style.display="none";
});
})();
var _7e=_5.support.cssFloat?"cssFloat":"styleFloat";
_5.props={"for":"htmlFor","class":"className","float":_7e,cssFloat:_7e,styleFloat:_7e,readonly:"readOnly",maxlength:"maxLength",cellspacing:"cellSpacing",rowspan:"rowSpan",tabindex:"tabIndex"};
_5.fn.extend({_load:_5.fn.load,load:function(url,_1a6,_1a7){
if(typeof url!=="string"){
return this._load(url);
}
var off=url.indexOf(" ");
if(off>=0){
var _1a8=url.slice(off,url.length);
url=url.slice(0,off);
}
var type="GET";
if(_1a6){
if(_5.isFunction(_1a6)){
_1a7=_1a6;
_1a6=null;
}else{
if(typeof _1a6==="object"){
_1a6=_5.param(_1a6);
type="POST";
}
}
}
var self=this;
_5.ajax({url:url,type:type,dataType:"html",data:_1a6,complete:function(res,_1a9){
if(_1a9=="success"||_1a9=="notmodified"){
self.html(_1a8?_5("<div/>").append(res.responseText.replace(/<script(.|\s)*?\/script>/g,"")).find(_1a8):res.responseText);
}
if(_1a7){
self.each(_1a7,[res.responseText,_1a9,res]);
}
}});
return this;
},serialize:function(){
return _5.param(this.serializeArray());
},serializeArray:function(){
return this.map(function(){
return this.elements?_5.makeArray(this.elements):this;
}).filter(function(){
return this.name&&!this.disabled&&(this.checked||/select|textarea/i.test(this.nodeName)||/text|hidden|password|search/i.test(this.type));
}).map(function(i,elem){
var val=_5(this).val();
return val==null?null:_5.isArray(val)?_5.map(val,function(val,i){
return {name:elem.name,value:val};
}):{name:elem.name,value:val};
}).get();
}});
_5.each("ajaxStart,ajaxStop,ajaxComplete,ajaxError,ajaxSuccess,ajaxSend".split(","),function(i,o){
_5.fn[o]=function(f){
return this.bind(o,f);
};
});
var jsc=now();
_5.extend({get:function(url,data,_1aa,type){
if(_5.isFunction(data)){
_1aa=data;
data=null;
}
return _5.ajax({type:"GET",url:url,data:data,success:_1aa,dataType:type});
},getScript:function(url,_1ab){
return _5.get(url,null,_1ab,"script");
},getJSON:function(url,data,_1ac){
return _5.get(url,data,_1ac,"json");
},post:function(url,data,_1ad,type){
if(_5.isFunction(data)){
_1ad=data;
data={};
}
return _5.ajax({type:"POST",url:url,data:data,success:_1ad,dataType:type});
},ajaxSetup:function(_1ae){
_5.extend(_5.ajaxSettings,_1ae);
},ajaxSettings:{url:location.href,global:true,type:"GET",contentType:"application/x-www-form-urlencoded",processData:true,async:true,xhr:function(){
return _1.ActiveXObject?new ActiveXObject("Microsoft.XMLHTTP"):new XMLHttpRequest();
},accepts:{xml:"application/xml, text/xml",html:"text/html",script:"text/javascript, application/javascript",json:"application/json, text/javascript",text:"text/plain",_default:"*/*"}},lastModified:{},ajax:function(s){
s=_5.extend(true,s,_5.extend(true,{},_5.ajaxSettings,s));
var _1af,jsre=/=\?(&|$)/g,_1b0,data,type=s.type.toUpperCase();
if(s.data&&s.processData&&typeof s.data!=="string"){
s.data=_5.param(s.data);
}
if(s.dataType=="jsonp"){
if(type=="GET"){
if(!s.url.match(jsre)){
s.url+=(s.url.match(/\?/)?"&":"?")+(s.jsonp||"callback")+"=?";
}
}else{
if(!s.data||!s.data.match(jsre)){
s.data=(s.data?s.data+"&":"")+(s.jsonp||"callback")+"=?";
}
}
s.dataType="json";
}
if(s.dataType=="json"&&(s.data&&s.data.match(jsre)||s.url.match(jsre))){
_1af="jsonp"+jsc++;
if(s.data){
s.data=(s.data+"").replace(jsre,"="+_1af+"$1");
}
s.url=s.url.replace(jsre,"="+_1af+"$1");
s.dataType="script";
_1[_1af]=function(tmp){
data=tmp;
_1b1();
_1b2();
_1[_1af]=_2;
try{
delete _1[_1af];
}
catch(e){
}
if(head){
head.removeChild(_1b3);
}
};
}
if(s.dataType=="script"&&s.cache==null){
s.cache=false;
}
if(s.cache===false&&type=="GET"){
var ts=now();
var ret=s.url.replace(/(\?|&)_=.*?(&|$)/,"$1_="+ts+"$2");
s.url=ret+((ret==s.url)?(s.url.match(/\?/)?"&":"?")+"_="+ts:"");
}
if(s.data&&type=="GET"){
s.url+=(s.url.match(/\?/)?"&":"?")+s.data;
s.data=null;
}
if(s.global&&!_5.active++){
_5.event.trigger("ajaxStart");
}
var _1b4=/^(\w+:)?\/\/([^\/?#]+)/.exec(s.url);
if(s.dataType=="script"&&type=="GET"&&_1b4&&(_1b4[1]&&_1b4[1]!=location.protocol||_1b4[2]!=location.host)){
var head=document.getElementsByTagName("head")[0];
var _1b3=document.createElement("script");
_1b3.src=s.url;
if(s.scriptCharset){
_1b3.charset=s.scriptCharset;
}
if(!_1af){
var done=false;
_1b3.onload=_1b3.onreadystatechange=function(){
if(!done&&(!this.readyState||this.readyState=="loaded"||this.readyState=="complete")){
done=true;
_1b1();
_1b2();
_1b3.onload=_1b3.onreadystatechange=null;
head.removeChild(_1b3);
}
};
}
head.appendChild(_1b3);
return _2;
}
var _1b5=false;
var xhr=s.xhr();
if(s.username){
xhr.open(type,s.url,s.async,s.username,s.password);
}else{
xhr.open(type,s.url,s.async);
}
try{
if(s.data){
xhr.setRequestHeader("Content-Type",s.contentType);
}
if(s.ifModified){
xhr.setRequestHeader("If-Modified-Since",_5.lastModified[s.url]||"Thu, 01 Jan 1970 00:00:00 GMT");
}
xhr.setRequestHeader("X-Requested-With","XMLHttpRequest");
xhr.setRequestHeader("Accept",s.dataType&&s.accepts[s.dataType]?s.accepts[s.dataType]+", */*":s.accepts._default);
}
catch(e){
}
if(s.beforeSend&&s.beforeSend(xhr,s)===false){
if(s.global&&!--_5.active){
_5.event.trigger("ajaxStop");
}
xhr.abort();
return false;
}
if(s.global){
_5.event.trigger("ajaxSend",[xhr,s]);
}
var _1b6=function(_1b7){
if(xhr.readyState==0){
if(ival){
clearInterval(ival);
ival=null;
if(s.global&&!--_5.active){
_5.event.trigger("ajaxStop");
}
}
}else{
if(!_1b5&&xhr&&(xhr.readyState==4||_1b7=="timeout")){
_1b5=true;
if(ival){
clearInterval(ival);
ival=null;
}
_1b0=_1b7=="timeout"?"timeout":!_5.httpSuccess(xhr)?"error":s.ifModified&&_5.httpNotModified(xhr,s.url)?"notmodified":"success";
if(_1b0=="success"){
try{
data=_5.httpData(xhr,s.dataType,s);
}
catch(e){
_1b0="parsererror";
}
}
if(_1b0=="success"){
var _1b8;
try{
_1b8=xhr.getResponseHeader("Last-Modified");
}
catch(e){
}
if(s.ifModified&&_1b8){
_5.lastModified[s.url]=_1b8;
}
if(!_1af){
_1b1();
}
}else{
_5.handleError(s,xhr,_1b0);
}
_1b2();
if(_1b7){
xhr.abort();
}
if(s.async){
xhr=null;
}
}
}
};
if(s.async){
var ival=setInterval(_1b6,13);
if(s.timeout>0){
setTimeout(function(){
if(xhr&&!_1b5){
_1b6("timeout");
}
},s.timeout);
}
}
try{
xhr.send(s.data);
}
catch(e){
_5.handleError(s,xhr,null,e);
}
if(!s.async){
_1b6();
}
function _1b1(){
if(s.success){
s.success(data,_1b0);
}
if(s.global){
_5.event.trigger("ajaxSuccess",[xhr,s]);
}
};
function _1b2(){
if(s.complete){
s.complete(xhr,_1b0);
}
if(s.global){
_5.event.trigger("ajaxComplete",[xhr,s]);
}
if(s.global&&!--_5.active){
_5.event.trigger("ajaxStop");
}
};
return xhr;
},handleError:function(s,xhr,_1b9,e){
if(s.error){
s.error(xhr,_1b9,e);
}
if(s.global){
_5.event.trigger("ajaxError",[xhr,s,e]);
}
},active:0,httpSuccess:function(xhr){
try{
return !xhr.status&&location.protocol=="file:"||(xhr.status>=200&&xhr.status<300)||xhr.status==304||xhr.status==1223;
}
catch(e){
}
return false;
},httpNotModified:function(xhr,url){
try{
var _1ba=xhr.getResponseHeader("Last-Modified");
return xhr.status==304||_1ba==_5.lastModified[url];
}
catch(e){
}
return false;
},httpData:function(xhr,type,s){
var ct=xhr.getResponseHeader("content-type"),xml=type=="xml"||!type&&ct&&ct.indexOf("xml")>=0,data=xml?xhr.responseXML:xhr.responseText;
if(xml&&data.documentElement.tagName=="parsererror"){
throw "parsererror";
}
if(s&&s.dataFilter){
data=s.dataFilter(data,type);
}
if(typeof data==="string"){
if(type=="script"){
_5.globalEval(data);
}
if(type=="json"){
data=_1["eval"]("("+data+")");
}
}
return data;
},param:function(a){
var s=[];
function add(key,_1bb){
s[s.length]=encodeURIComponent(key)+"="+encodeURIComponent(_1bb);
};
if(_5.isArray(a)||a.jquery){
_5.each(a,function(){
add(this.name,this.value);
});
}else{
for(var j in a){
if(_5.isArray(a[j])){
_5.each(a[j],function(){
add(j,this);
});
}else{
add(j,_5.isFunction(a[j])?a[j]():a[j]);
}
}
}
return s.join("&").replace(/%20/g,"+");
}});
var _1bc={},_1bd,_1be=[["height","marginTop","marginBottom","paddingTop","paddingBottom"],["width","marginLeft","marginRight","paddingLeft","paddingRight"],["opacity"]];
function _1bf(type,num){
var obj={};
_5.each(_1be.concat.apply([],_1be.slice(0,num)),function(){
obj[this]=type;
});
return obj;
};
_5.fn.extend({show:function(_1c0,_1c1){
if(_1c0){
return this.animate(_1bf("show",3),_1c0,_1c1);
}else{
for(var i=0,l=this.length;i<l;i++){
var old=_5.data(this[i],"olddisplay");
this[i].style.display=old||"";
if(_5.css(this[i],"display")==="none"){
var _1c2=this[i].tagName,_1c3;
if(_1bc[_1c2]){
_1c3=_1bc[_1c2];
}else{
var elem=_5("<"+_1c2+" />").appendTo("body");
_1c3=elem.css("display");
if(_1c3==="none"){
_1c3="block";
}
elem.remove();
_1bc[_1c2]=_1c3;
}
_5.data(this[i],"olddisplay",_1c3);
}
}
for(var i=0,l=this.length;i<l;i++){
this[i].style.display=_5.data(this[i],"olddisplay")||"";
}
return this;
}
},hide:function(_1c4,_1c5){
if(_1c4){
return this.animate(_1bf("hide",3),_1c4,_1c5);
}else{
for(var i=0,l=this.length;i<l;i++){
var old=_5.data(this[i],"olddisplay");
if(!old&&old!=="none"){
_5.data(this[i],"olddisplay",_5.css(this[i],"display"));
}
}
for(var i=0,l=this.length;i<l;i++){
this[i].style.display="none";
}
return this;
}
},_toggle:_5.fn.toggle,toggle:function(fn,fn2){
var bool=typeof fn==="boolean";
return _5.isFunction(fn)&&_5.isFunction(fn2)?this._toggle.apply(this,arguments):fn==null||bool?this.each(function(){
var _1c6=bool?fn:_5(this).is(":hidden");
_5(this)[_1c6?"show":"hide"]();
}):this.animate(_1bf("toggle",3),fn,fn2);
},fadeTo:function(_1c7,to,_1c8){
return this.animate({opacity:to},_1c7,_1c8);
},animate:function(prop,_1c9,_1ca,_1cb){
var _1cc=_5.speed(_1c9,_1ca,_1cb);
return this[_1cc.queue===false?"each":"queue"](function(){
var opt=_5.extend({},_1cc),p,_1cd=this.nodeType==1&&_5(this).is(":hidden"),self=this;
for(p in prop){
if(prop[p]=="hide"&&_1cd||prop[p]=="show"&&!_1cd){
return opt.complete.call(this);
}
if((p=="height"||p=="width")&&this.style){
opt.display=_5.css(this,"display");
opt.overflow=this.style.overflow;
}
}
if(opt.overflow!=null){
this.style.overflow="hidden";
}
opt.curAnim=_5.extend({},prop);
_5.each(prop,function(name,val){
var e=new _5.fx(self,opt,name);
if(/toggle|show|hide/.test(val)){
e[val=="toggle"?_1cd?"show":"hide":val](prop);
}else{
var _1ce=val.toString().match(/^([+-]=)?([\d+-.]+)(.*)$/),_1cf=e.cur(true)||0;
if(_1ce){
var end=parseFloat(_1ce[2]),unit=_1ce[3]||"px";
if(unit!="px"){
self.style[name]=(end||1)+unit;
_1cf=((end||1)/e.cur(true))*_1cf;
self.style[name]=_1cf+unit;
}
if(_1ce[1]){
end=((_1ce[1]=="-="?-1:1)*end)+_1cf;
}
e.custom(_1cf,end,unit);
}else{
e.custom(_1cf,val,"");
}
}
});
return true;
});
},stop:function(_1d0,_1d1){
var _1d2=_5.timers;
if(_1d0){
this.queue([]);
}
this.each(function(){
for(var i=_1d2.length-1;i>=0;i--){
if(_1d2[i].elem==this){
if(_1d1){
_1d2[i](true);
}
_1d2.splice(i,1);
}
}
});
if(!_1d1){
this.dequeue();
}
return this;
}});
_5.each({slideDown:_1bf("show",1),slideUp:_1bf("hide",1),slideToggle:_1bf("toggle",1),fadeIn:{opacity:"show"},fadeOut:{opacity:"hide"}},function(name,_1d3){
_5.fn[name]=function(_1d4,_1d5){
return this.animate(_1d3,_1d4,_1d5);
};
});
_5.extend({speed:function(_1d6,_1d7,fn){
var opt=typeof _1d6==="object"?_1d6:{complete:fn||!fn&&_1d7||_5.isFunction(_1d6)&&_1d6,duration:_1d6,easing:fn&&_1d7||_1d7&&!_5.isFunction(_1d7)&&_1d7};
opt.duration=_5.fx.off?0:typeof opt.duration==="number"?opt.duration:_5.fx.speeds[opt.duration]||_5.fx.speeds._default;
opt.old=opt.complete;
opt.complete=function(){
if(opt.queue!==false){
_5(this).dequeue();
}
if(_5.isFunction(opt.old)){
opt.old.call(this);
}
};
return opt;
},easing:{linear:function(p,n,_1d8,diff){
return _1d8+diff*p;
},swing:function(p,n,_1d9,diff){
return ((-Math.cos(p*Math.PI)/2)+0.5)*diff+_1d9;
}},timers:[],fx:function(elem,_1da,prop){
this.options=_1da;
this.elem=elem;
this.prop=prop;
if(!_1da.orig){
_1da.orig={};
}
}});
_5.fx.prototype={update:function(){
if(this.options.step){
this.options.step.call(this.elem,this.now,this);
}
(_5.fx.step[this.prop]||_5.fx.step._default)(this);
if((this.prop=="height"||this.prop=="width")&&this.elem.style){
this.elem.style.display="block";
}
},cur:function(_1db){
if(this.elem[this.prop]!=null&&(!this.elem.style||this.elem.style[this.prop]==null)){
return this.elem[this.prop];
}
var r=parseFloat(_5.css(this.elem,this.prop,_1db));
return r&&r>-10000?r:parseFloat(_5.curCSS(this.elem,this.prop))||0;
},custom:function(from,to,unit){
this.startTime=now();
this.start=from;
this.end=to;
this.unit=unit||this.unit||"px";
this.now=this.start;
this.pos=this.state=0;
var self=this;
function t(_1dc){
return self.step(_1dc);
};
t.elem=this.elem;
if(t()&&_5.timers.push(t)&&!_1bd){
_1bd=setInterval(function(){
var _1dd=_5.timers;
for(var i=0;i<_1dd.length;i++){
if(!_1dd[i]()){
_1dd.splice(i--,1);
}
}
if(!_1dd.length){
clearInterval(_1bd);
_1bd=_2;
}
},13);
}
},show:function(){
this.options.orig[this.prop]=_5.attr(this.elem.style,this.prop);
this.options.show=true;
this.custom(this.prop=="width"||this.prop=="height"?1:0,this.cur());
_5(this.elem).show();
},hide:function(){
this.options.orig[this.prop]=_5.attr(this.elem.style,this.prop);
this.options.hide=true;
this.custom(this.cur(),0);
},step:function(_1de){
var t=now();
if(_1de||t>=this.options.duration+this.startTime){
this.now=this.end;
this.pos=this.state=1;
this.update();
this.options.curAnim[this.prop]=true;
var done=true;
for(var i in this.options.curAnim){
if(this.options.curAnim[i]!==true){
done=false;
}
}
if(done){
if(this.options.display!=null){
this.elem.style.overflow=this.options.overflow;
this.elem.style.display=this.options.display;
if(_5.css(this.elem,"display")=="none"){
this.elem.style.display="block";
}
}
if(this.options.hide){
_5(this.elem).hide();
}
if(this.options.hide||this.options.show){
for(var p in this.options.curAnim){
_5.attr(this.elem.style,p,this.options.orig[p]);
}
}
this.options.complete.call(this.elem);
}
return false;
}else{
var n=t-this.startTime;
this.state=n/this.options.duration;
this.pos=_5.easing[this.options.easing||(_5.easing.swing?"swing":"linear")](this.state,n,0,1,this.options.duration);
this.now=this.start+((this.end-this.start)*this.pos);
this.update();
}
return true;
}};
_5.extend(_5.fx,{speeds:{slow:600,fast:200,_default:400},step:{opacity:function(fx){
_5.attr(fx.elem.style,"opacity",fx.now);
},_default:function(fx){
if(fx.elem.style&&fx.elem.style[fx.prop]!=null){
fx.elem.style[fx.prop]=fx.now+fx.unit;
}else{
fx.elem[fx.prop]=fx.now;
}
}}});
if(document.documentElement["getBoundingClientRect"]){
_5.fn.offset=function(){
if(!this[0]){
return {top:0,left:0};
}
if(this[0]===this[0].ownerDocument.body){
return _5.offset.bodyOffset(this[0]);
}
var box=this[0].getBoundingClientRect(),doc=this[0].ownerDocument,body=doc.body,_1df=doc.documentElement,_1e0=_1df.clientTop||body.clientTop||0,_1e1=_1df.clientLeft||body.clientLeft||0,top=box.top+(self.pageYOffset||_5.boxModel&&_1df.scrollTop||body.scrollTop)-_1e0,left=box.left+(self.pageXOffset||_5.boxModel&&_1df.scrollLeft||body.scrollLeft)-_1e1;
return {top:top,left:left};
};
}else{
_5.fn.offset=function(){
if(!this[0]){
return {top:0,left:0};
}
if(this[0]===this[0].ownerDocument.body){
return _5.offset.bodyOffset(this[0]);
}
_5.offset.initialized||_5.offset.initialize();
var elem=this[0],_1e2=elem.offsetParent,_1e3=elem,doc=elem.ownerDocument,_1e4,_1e5=doc.documentElement,body=doc.body,_54=doc.defaultView,_1e6=_54.getComputedStyle(elem,null),top=elem.offsetTop,left=elem.offsetLeft;
while((elem=elem.parentNode)&&elem!==body&&elem!==_1e5){
_1e4=_54.getComputedStyle(elem,null);
top-=elem.scrollTop,left-=elem.scrollLeft;
if(elem===_1e2){
top+=elem.offsetTop,left+=elem.offsetLeft;
if(_5.offset.doesNotAddBorder&&!(_5.offset.doesAddBorderForTableAndCells&&/^t(able|d|h)$/i.test(elem.tagName))){
top+=parseInt(_1e4.borderTopWidth,10)||0,left+=parseInt(_1e4.borderLeftWidth,10)||0;
}
_1e3=_1e2,_1e2=elem.offsetParent;
}
if(_5.offset.subtractsBorderForOverflowNotVisible&&_1e4.overflow!=="visible"){
top+=parseInt(_1e4.borderTopWidth,10)||0,left+=parseInt(_1e4.borderLeftWidth,10)||0;
}
_1e6=_1e4;
}
if(_1e6.position==="relative"||_1e6.position==="static"){
top+=body.offsetTop,left+=body.offsetLeft;
}
if(_1e6.position==="fixed"){
top+=Math.max(_1e5.scrollTop,body.scrollTop),left+=Math.max(_1e5.scrollLeft,body.scrollLeft);
}
return {top:top,left:left};
};
}
_5.offset={initialize:function(){
if(this.initialized){
return;
}
var body=document.body,_1e7=document.createElement("div"),_1e8,_1e9,_1ea,td,_1eb,prop,_1ec=body.style.marginTop,html="<div style=\"position:absolute;top:0;left:0;margin:0;border:5px solid #000;padding:0;width:1px;height:1px;\"><div></div></div><table style=\"position:absolute;top:0;left:0;margin:0;border:5px solid #000;padding:0;width:1px;height:1px;\" cellpadding=\"0\" cellspacing=\"0\"><tr><td></td></tr></table>";
_1eb={position:"absolute",top:0,left:0,margin:0,border:0,width:"1px",height:"1px",visibility:"hidden"};
for(prop in _1eb){
_1e7.style[prop]=_1eb[prop];
}
_1e7.innerHTML=html;
body.insertBefore(_1e7,body.firstChild);
_1e8=_1e7.firstChild,_1e9=_1e8.firstChild,td=_1e8.nextSibling.firstChild.firstChild;
this.doesNotAddBorder=(_1e9.offsetTop!==5);
this.doesAddBorderForTableAndCells=(td.offsetTop===5);
_1e8.style.overflow="hidden",_1e8.style.position="relative";
this.subtractsBorderForOverflowNotVisible=(_1e9.offsetTop===-5);
body.style.marginTop="1px";
this.doesNotIncludeMarginInBodyOffset=(body.offsetTop===0);
body.style.marginTop=_1ec;
body.removeChild(_1e7);
this.initialized=true;
},bodyOffset:function(body){
_5.offset.initialized||_5.offset.initialize();
var top=body.offsetTop,left=body.offsetLeft;
if(_5.offset.doesNotIncludeMarginInBodyOffset){
top+=parseInt(_5.curCSS(body,"marginTop",true),10)||0,left+=parseInt(_5.curCSS(body,"marginLeft",true),10)||0;
}
return {top:top,left:left};
}};
_5.fn.extend({position:function(){
var left=0,top=0,_1ed;
if(this[0]){
var _1ee=this.offsetParent(),_1ef=this.offset(),_1f0=/^body|html$/i.test(_1ee[0].tagName)?{top:0,left:0}:_1ee.offset();
_1ef.top-=num(this,"marginTop");
_1ef.left-=num(this,"marginLeft");
_1f0.top+=num(_1ee,"borderTopWidth");
_1f0.left+=num(_1ee,"borderLeftWidth");
_1ed={top:_1ef.top-_1f0.top,left:_1ef.left-_1f0.left};
}
return _1ed;
},offsetParent:function(){
var _1f1=this[0].offsetParent||document.body;
while(_1f1&&(!/^body|html$/i.test(_1f1.tagName)&&_5.css(_1f1,"position")=="static")){
_1f1=_1f1.offsetParent;
}
return _5(_1f1);
}});
_5.each(["Left","Top"],function(i,name){
var _1f2="scroll"+name;
_5.fn[_1f2]=function(val){
if(!this[0]){
return null;
}
return val!==_2?this.each(function(){
this==_1||this==document?_1.scrollTo(!i?val:_5(_1).scrollLeft(),i?val:_5(_1).scrollTop()):this[_1f2]=val;
}):this[0]==_1||this[0]==document?self[i?"pageYOffset":"pageXOffset"]||_5.boxModel&&document.documentElement[_1f2]||document.body[_1f2]:this[0][_1f2];
};
});
_5.each(["Height","Width"],function(i,name){
var tl=i?"Left":"Top",br=i?"Right":"Bottom",_1f3=name.toLowerCase();
_5.fn["inner"+name]=function(){
return this[0]?_5.css(this[0],_1f3,false,"padding"):null;
};
_5.fn["outer"+name]=function(_1f4){
return this[0]?_5.css(this[0],_1f3,false,_1f4?"margin":"border"):null;
};
var type=name.toLowerCase();
_5.fn[type]=function(size){
return this[0]==_1?document.compatMode=="CSS1Compat"&&document.documentElement["client"+name]||document.body["client"+name]:this[0]==document?Math.max(document.documentElement["client"+name],document.body["scroll"+name],document.documentElement["scroll"+name],document.body["offset"+name],document.documentElement["offset"+name]):size===_2?(this.length?_5.css(this[0],type):null):this.css(type,typeof size==="string"?size:size+"px");
};
});
})();
(function($){
$.extend({tablesorter:new function(){
var _1=[],_2=[];
this.defaults={cssHeader:"header",cssAsc:"headerSortUp",cssDesc:"headerSortDown",sortInitialOrder:"asc",sortMultiSortKey:"shiftKey",sortForce:null,sortAppend:null,textExtraction:"simple",parsers:{},widgets:[],widgetZebra:{css:["even","odd"]},headers:{},widthFixed:false,cancelSelection:true,sortList:[],headerList:[],dateFormat:"us",decimal:".",debug:false};
function _3(s,d){
_4(s+","+(new Date().getTime()-d.getTime())+"ms");
};
this.benchmark=_3;
function _4(s){
if(typeof console!="undefined"&&typeof console.debug!="undefined"){
console.log(s);
}else{
alert(s);
}
};
function _5(_6,_7){
if(_6.config.debug){
var _8="";
}
var _9=_6.tBodies[0].rows;
if(_6.tBodies[0].rows[0]){
var _a=[],_b=_9[0].cells,l=_b.length;
for(var i=0;i<l;i++){
var p=false;
if($.metadata&&($(_7[i]).metadata()&&$(_7[i]).metadata().sorter)){
p=_c($(_7[i]).metadata().sorter);
}else{
if((_6.config.headers[i]&&_6.config.headers[i].sorter)){
p=_c(_6.config.headers[i].sorter);
}
}
if(!p){
p=_d(_6,_b[i]);
}
if(_6.config.debug){
_8+="column:"+i+" parser:"+p.id+"\n";
}
_a.push(p);
}
}
if(_6.config.debug){
_4(_8);
}
return _a;
};
function _d(_e,_f){
var l=_1.length;
for(var i=1;i<l;i++){
if(_1[i].is($.trim(_10(_e.config,_f)),_e,_f)){
return _1[i];
}
}
return _1[0];
};
function _c(_11){
var l=_1.length;
for(var i=0;i<l;i++){
if(_1[i].id.toLowerCase()==_11.toLowerCase()){
return _1[i];
}
}
return false;
};
function _12(_13){
if(_13.config.debug){
var _14=new Date();
}
var _15=(_13.tBodies[0]&&_13.tBodies[0].rows.length)||0,_16=(_13.tBodies[0].rows[0]&&_13.tBodies[0].rows[0].cells.length)||0,_1=_13.config.parsers,_17={row:[],normalized:[]};
for(var i=0;i<_15;++i){
var c=_13.tBodies[0].rows[i],_18=[];
_17.row.push($(c));
for(var j=0;j<_16;++j){
_18.push(_1[j].format(_10(_13.config,c.cells[j]),_13,c.cells[j]));
}
_18.push(i);
_17.normalized.push(_18);
_18=null;
}
if(_13.config.debug){
_3("Building cache for "+_15+" rows:",_14);
}
return _17;
};
function _10(_19,_1a){
if(!_1a){
return "";
}
var t="";
if(_19.textExtraction=="simple"){
if(_1a.childNodes[0]&&_1a.childNodes[0].hasChildNodes()){
t=_1a.childNodes[0].innerHTML;
}else{
t=_1a.innerHTML;
}
}else{
if(typeof (_19.textExtraction)=="function"){
t=_19.textExtraction(_1a);
}else{
t=$(_1a).text();
}
}
return t;
};
function _1b(_1c,_1d){
if(_1c.config.debug){
var _1e=new Date();
}
var c=_1d,r=c.row,n=c.normalized,_1f=n.length,_20=(n[0].length-1),_21=$(_1c.tBodies[0]),_22=[];
for(var i=0;i<_1f;i++){
_22.push(r[n[i][_20]]);
if(!_1c.config.appender){
var o=r[n[i][_20]];
var l=o.length;
for(var j=0;j<l;j++){
_21[0].appendChild(o[j]);
}
}
}
if(_1c.config.appender){
_1c.config.appender(_1c,_22);
}
_22=null;
if(_1c.config.debug){
_3("Rebuilt table:",_1e);
}
_23(_1c);
setTimeout(function(){
$(_1c).trigger("sortEnd");
},0);
};
function _24(_25){
if(_25.config.debug){
var _26=new Date();
}
var _27=($.metadata)?true:false,_28=[];
for(var i=0;i<_25.tHead.rows.length;i++){
_28[i]=0;
}
$tableHeaders=$("thead th",_25);
$tableHeaders.each(function(_29){
this.count=0;
this.column=_29;
this.order=_2a(_25.config.sortInitialOrder);
if(_2b(this)||_2c(_25,_29)){
this.sortDisabled=true;
}
if(!this.sortDisabled){
$(this).addClass(_25.config.cssHeader);
}
_25.config.headerList[_29]=this;
});
if(_25.config.debug){
_3("Built headers:",_26);
_4($tableHeaders);
}
return $tableHeaders;
};
function _2d(_2e,_2f,row){
var arr=[],r=_2e.tHead.rows,c=r[row].cells;
for(var i=0;i<c.length;i++){
var _30=c[i];
if(_30.colSpan>1){
arr=arr.concat(_2d(_2e,headerArr,row++));
}else{
if(_2e.tHead.length==1||(_30.rowSpan>1||!r[row+1])){
arr.push(_30);
}
}
}
return arr;
};
function _2b(_31){
if(($.metadata)&&($(_31).metadata().sorter===false)){
return true;
}
return false;
};
function _2c(_32,i){
if((_32.config.headers[i])&&(_32.config.headers[i].sorter===false)){
return true;
}
return false;
};
function _23(_33){
var c=_33.config.widgets;
var l=c.length;
for(var i=0;i<l;i++){
_34(c[i]).format(_33);
}
};
function _34(_35){
var l=_2.length;
for(var i=0;i<l;i++){
if(_2[i].id.toLowerCase()==_35.toLowerCase()){
return _2[i];
}
}
};
function _2a(v){
if(typeof (v)!="Number"){
i=(v.toLowerCase()=="desc")?1:0;
}else{
i=(v==(0||1))?v:0;
}
return i;
};
function _36(v,a){
var l=a.length;
for(var i=0;i<l;i++){
if(a[i][0]==v){
return true;
}
}
return false;
};
function _37(_38,_39,_3a,css){
_39.removeClass(css[0]).removeClass(css[1]);
var h=[];
_39.each(function(_3b){
if(!this.sortDisabled){
h[this.column]=$(this);
}
});
var l=_3a.length;
for(var i=0;i<l;i++){
h[_3a[i][0]].addClass(css[_3a[i][1]]);
}
};
function _3c(_3d,_3e){
var c=_3d.config;
if(c.widthFixed){
var _3f=$("<colgroup>");
$("tr:first td",_3d.tBodies[0]).each(function(){
_3f.append($("<col>").css("width",$(this).width()));
});
$(_3d).prepend(_3f);
}
};
function _40(_41,_42){
var c=_41.config,l=_42.length;
for(var i=0;i<l;i++){
var s=_42[i],o=c.headerList[s[0]];
o.count=s[1];
o.count++;
}
};
function _43(_44,_45,_46){
if(_44.config.debug){
var _47=new Date();
}
var _48="var sortWrapper = function(a,b) {",l=_45.length;
for(var i=0;i<l;i++){
var c=_45[i][0];
var _49=_45[i][1];
var s=(_4a(_44.config.parsers,c)=="text")?((_49==0)?"sortText":"sortTextDesc"):((_49==0)?"sortNumeric":"sortNumericDesc");
var e="e"+i;
_48+="var "+e+" = "+s+"(a["+c+"],b["+c+"]); ";
_48+="if("+e+") { return "+e+"; } ";
_48+="else { ";
}
var _4b=_46.normalized[0].length-1;
_48+="return a["+_4b+"]-b["+_4b+"];";
for(var i=0;i<l;i++){
_48+="}; ";
}
_48+="return 0; ";
_48+="}; ";
eval(_48);
_46.normalized.sort(sortWrapper);
if(_44.config.debug){
_3("Sorting on "+_45.toString()+" and dir "+_49+" time:",_47);
}
return _46;
};
function _4c(a,b){
return ((a<b)?-1:((a>b)?1:0));
};
function _4d(a,b){
return ((b<a)?-1:((b>a)?1:0));
};
function _4e(a,b){
return a-b;
};
function _4f(a,b){
return b-a;
};
function _4a(_50,i){
return _50[i].type;
};
this.construct=function(_51){
return this.each(function(){
if(!this.tHead||!this.tBodies){
return;
}
var _52,_53,_54,_55,_56,_57=0,_58;
this.config={};
_56=$.extend(this.config,$.tablesorter.defaults,_51);
_52=$(this);
_54=_24(this);
this.config.parsers=_5(this,_54);
_55=_12(this);
var _59=[_56.cssDesc,_56.cssAsc];
_3c(this);
_54.click(function(e){
_52.trigger("sortStart");
var _5a=(_52[0].tBodies[0]&&_52[0].tBodies[0].rows.length)||0;
if(!this.sortDisabled&&_5a>0){
var _5b=$(this);
var i=this.column;
this.order=this.count++%2;
if(!e[_56.sortMultiSortKey]){
_56.sortList=[];
if(_56.sortForce!=null){
var a=_56.sortForce;
for(var j=0;j<a.length;j++){
if(a[j][0]!=i){
_56.sortList.push(a[j]);
}
}
}
_56.sortList.push([i,this.order]);
}else{
if(_36(i,_56.sortList)){
for(var j=0;j<_56.sortList.length;j++){
var s=_56.sortList[j],o=_56.headerList[s[0]];
if(s[0]==i){
o.count=s[1];
o.count++;
s[1]=o.count%2;
}
}
}else{
_56.sortList.push([i,this.order]);
}
}
setTimeout(function(){
_37(_52[0],_54,_56.sortList,_59);
_1b(_52[0],_43(_52[0],_56.sortList,_55));
},1);
return false;
}
}).mousedown(function(){
if(_56.cancelSelection){
this.onselectstart=function(){
return false;
};
return false;
}
});
_52.bind("update",function(){
this.config.parsers=_5(this,_54);
_55=_12(this);
}).bind("sorton",function(e,_5c){
$(this).trigger("sortStart");
_56.sortList=_5c;
var _5d=_56.sortList;
_40(this,_5d);
_37(this,_54,_5d,_59);
_1b(this,_43(this,_5d,_55));
}).bind("appendCache",function(){
_1b(this,_55);
}).bind("applyWidgetId",function(e,id){
_34(id).format(this);
}).bind("applyWidgets",function(){
_23(this);
});
if($.metadata&&($(this).metadata()&&$(this).metadata().sortlist)){
_56.sortList=$(this).metadata().sortlist;
}
if(_56.sortList.length>0){
_52.trigger("sorton",[_56.sortList]);
}
_23(this);
});
};
this.addParser=function(_5e){
var l=_1.length,a=true;
for(var i=0;i<l;i++){
if(_1[i].id.toLowerCase()==_5e.id.toLowerCase()){
a=false;
}
}
if(a){
_1.push(_5e);
}
};
this.addWidget=function(_5f){
_2.push(_5f);
};
this.formatFloat=function(s){
var i=parseFloat(s);
return (isNaN(i))?0:i;
};
this.formatInt=function(s){
var i=parseInt(s);
return (isNaN(i))?0:i;
};
this.isDigit=function(s,_60){
var _61="\\"+_60.decimal;
var exp="/(^[+]?0("+_61+"0+)?$)|(^([-+]?[1-9][0-9]*)$)|(^([-+]?((0?|[1-9][0-9]*)"+_61+"(0*[1-9][0-9]*)))$)|(^[-+]?[1-9]+[0-9]*"+_61+"0+$)/";
return RegExp(exp).test($.trim(s));
};
this.clearTableBody=function(_62){
if($.browser.msie){
function _63(){
while(this.firstChild){
this.removeChild(this.firstChild);
}
};
_63.apply(_62.tBodies[0]);
}else{
_62.tBodies[0].innerHTML="";
}
};
}});
$.fn.extend({tablesorter:$.tablesorter.construct});
var ts=$.tablesorter;
ts.addParser({id:"text",is:function(s){
return true;
},format:function(s){
return $.trim(s.toLowerCase());
},type:"text"});
ts.addParser({id:"digit",is:function(s,_64){
var c=_64.config;
return $.tablesorter.isDigit(s,c);
},format:function(s){
return $.tablesorter.formatFloat(s);
},type:"numeric"});
ts.addParser({id:"currency",is:function(s){
return /^[£$€?.]/.test(s);
},format:function(s){
return $.tablesorter.formatFloat(s.replace(new RegExp(/[^0-9.]/g),""));
},type:"numeric"});
ts.addParser({id:"ipAddress",is:function(s){
return /^\d{2,3}[\.]\d{2,3}[\.]\d{2,3}[\.]\d{2,3}$/.test(s);
},format:function(s){
var a=s.split("."),r="",l=a.length;
for(var i=0;i<l;i++){
var _65=a[i];
if(_65.length==2){
r+="0"+_65;
}else{
r+=_65;
}
}
return $.tablesorter.formatFloat(r);
},type:"numeric"});
ts.addParser({id:"url",is:function(s){
return /^(https?|ftp|file):\/\/$/.test(s);
},format:function(s){
return jQuery.trim(s.replace(new RegExp(/(https?|ftp|file):\/\//),""));
},type:"text"});
ts.addParser({id:"isoDate",is:function(s){
return /^\d{4}[\/-]\d{1,2}[\/-]\d{1,2}$/.test(s);
},format:function(s){
return $.tablesorter.formatFloat((s!="")?new Date(s.replace(new RegExp(/-/g),"/")).getTime():"0");
},type:"numeric"});
ts.addParser({id:"percent",is:function(s){
return /\%$/.test($.trim(s));
},format:function(s){
return $.tablesorter.formatFloat(s.replace(new RegExp(/%/g),""));
},type:"numeric"});
ts.addParser({id:"usLongDate",is:function(s){
return s.match(new RegExp(/^[A-Za-z]{3,10}\.? [0-9]{1,2}, ([0-9]{4}|'?[0-9]{2}) (([0-2]?[0-9]:[0-5][0-9])|([0-1]?[0-9]:[0-5][0-9]\s(AM|PM)))$/));
},format:function(s){
return $.tablesorter.formatFloat(new Date(s).getTime());
},type:"numeric"});
ts.addParser({id:"shortDate",is:function(s){
return /\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}/.test(s);
},format:function(s,_66){
var c=_66.config;
s=s.replace(/\-/g,"/");
if(c.dateFormat=="us"){
s=s.replace(/(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})/,"$3/$1/$2");
}else{
if(c.dateFormat=="uk"){
s=s.replace(/(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})/,"$3/$2/$1");
}else{
if(c.dateFormat=="dd/mm/yy"||c.dateFormat=="dd-mm-yy"){
s=s.replace(/(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2})/,"$1/$2/$3");
}
}
}
return $.tablesorter.formatFloat(new Date(s).getTime());
},type:"numeric"});
ts.addParser({id:"time",is:function(s){
return /^(([0-2]?[0-9]:[0-5][0-9])|([0-1]?[0-9]:[0-5][0-9]\s(am|pm)))$/.test(s);
},format:function(s){
return $.tablesorter.formatFloat(new Date("2000/01/01 "+s).getTime());
},type:"numeric"});
ts.addParser({id:"metadata",is:function(s){
return false;
},format:function(s,_67,_68){
var c=_67.config,p=(!c.parserMetadataName)?"sortValue":c.parserMetadataName;
return $(_68).metadata()[p];
},type:"numeric"});
ts.addWidget({id:"zebra",format:function(_69){
if(_69.config.debug){
var _6a=new Date();
}
$("tr:visible",_69.tBodies[0]).filter(":even").removeClass(_69.config.widgetZebra.css[1]).addClass(_69.config.widgetZebra.css[0]).end().filter(":odd").removeClass(_69.config.widgetZebra.css[0]).addClass(_69.config.widgetZebra.css[1]);
if(_69.config.debug){
$.tablesorter.benchmark("Applying Zebra widget",_6a);
}
}});
})(jQuery);
jQuery.ui||(function($){
var _1=$.fn.remove,_2=$.browser.mozilla&&(parseFloat($.browser.version)<1.9);
$.ui={version:"1.7.2",plugin:{add:function(_3,_4,_5){
var _6=$.ui[_3].prototype;
for(var i in _5){
_6.plugins[i]=_6.plugins[i]||[];
_6.plugins[i].push([_4,_5[i]]);
}
},call:function(_7,_8,_9){
var _a=_7.plugins[_8];
if(!_a||!_7.element[0].parentNode){
return;
}
for(var i=0;i<_a.length;i++){
if(_7.options[_a[i][0]]){
_a[i][1].apply(_7.element,_9);
}
}
}},contains:function(a,b){
return document.compareDocumentPosition?a.compareDocumentPosition(b)&16:a!==b&&a.contains(b);
},hasScroll:function(el,a){
if($(el).css("overflow")=="hidden"){
return false;
}
var _b=(a&&a=="left")?"scrollLeft":"scrollTop",_c=false;
if(el[_b]>0){
return true;
}
el[_b]=1;
_c=(el[_b]>0);
el[_b]=0;
return _c;
},isOverAxis:function(x,_d,_e){
return (x>_d)&&(x<(_d+_e));
},isOver:function(y,x,_f,_10,_11,_12){
return $.ui.isOverAxis(y,_f,_11)&&$.ui.isOverAxis(x,_10,_12);
},keyCode:{BACKSPACE:8,CAPS_LOCK:20,COMMA:188,CONTROL:17,DELETE:46,DOWN:40,END:35,ENTER:13,ESCAPE:27,HOME:36,INSERT:45,LEFT:37,NUMPAD_ADD:107,NUMPAD_DECIMAL:110,NUMPAD_DIVIDE:111,NUMPAD_ENTER:108,NUMPAD_MULTIPLY:106,NUMPAD_SUBTRACT:109,PAGE_DOWN:34,PAGE_UP:33,PERIOD:190,RIGHT:39,SHIFT:16,SPACE:32,TAB:9,UP:38}};
if(_2){
var _13=$.attr,_14=$.fn.removeAttr,_15="http://www.w3.org/2005/07/aaa",_16=/^aria-/,_17=/^wairole:/;
$.attr=function(_18,_19,_1a){
var set=_1a!==undefined;
return (_19=="role"?(set?_13.call(this,_18,_19,"wairole:"+_1a):(_13.apply(this,arguments)||"").replace(_17,"")):(_16.test(_19)?(set?_18.setAttributeNS(_15,_19.replace(_16,"aaa:"),_1a):_13.call(this,_18,_19.replace(_16,"aaa:"))):_13.apply(this,arguments)));
};
$.fn.removeAttr=function(_1b){
return (_16.test(_1b)?this.each(function(){
this.removeAttributeNS(_15,_1b.replace(_16,""));
}):_14.call(this,_1b));
};
}
$.fn.extend({remove:function(){
$("*",this).add(this).each(function(){
$(this).triggerHandler("remove");
});
return _1.apply(this,arguments);
},enableSelection:function(){
return this.attr("unselectable","off").css("MozUserSelect","").unbind("selectstart.ui");
},disableSelection:function(){
return this.attr("unselectable","on").css("MozUserSelect","none").bind("selectstart.ui",function(){
return false;
});
},scrollParent:function(){
var _1c;
if(($.browser.msie&&(/(static|relative)/).test(this.css("position")))||(/absolute/).test(this.css("position"))){
_1c=this.parents().filter(function(){
return (/(relative|absolute|fixed)/).test($.curCSS(this,"position",1))&&(/(auto|scroll)/).test($.curCSS(this,"overflow",1)+$.curCSS(this,"overflow-y",1)+$.curCSS(this,"overflow-x",1));
}).eq(0);
}else{
_1c=this.parents().filter(function(){
return (/(auto|scroll)/).test($.curCSS(this,"overflow",1)+$.curCSS(this,"overflow-y",1)+$.curCSS(this,"overflow-x",1));
}).eq(0);
}
return (/fixed/).test(this.css("position"))||!_1c.length?$(document):_1c;
}});
$.extend($.expr[":"],{data:function(_1d,i,_1e){
return !!$.data(_1d,_1e[3]);
},focusable:function(_1f){
var _20=_1f.nodeName.toLowerCase(),_21=$.attr(_1f,"tabindex");
return (/input|select|textarea|button|object/.test(_20)?!_1f.disabled:"a"==_20||"area"==_20?_1f.href||!isNaN(_21):!isNaN(_21))&&!$(_1f)["area"==_20?"parents":"closest"](":hidden").length;
},tabbable:function(_22){
var _23=$.attr(_22,"tabindex");
return (isNaN(_23)||_23>=0)&&$(_22).is(":focusable");
}});
function _24(_25,_26,_27,_28){
function _29(_2a){
var _2b=$[_25][_26][_2a]||[];
return (typeof _2b=="string"?_2b.split(/,?\s+/):_2b);
};
var _2c=_29("getter");
if(_28.length==1&&typeof _28[0]=="string"){
_2c=_2c.concat(_29("getterSetter"));
}
return ($.inArray(_27,_2c)!=-1);
};
$.widget=function(_2d,_2e){
var _2f=_2d.split(".")[0];
_2d=_2d.split(".")[1];
$.fn[_2d]=function(_30){
var _31=(typeof _30=="string"),_32=Array.prototype.slice.call(arguments,1);
if(_31&&_30.substring(0,1)=="_"){
return this;
}
if(_31&&_24(_2f,_2d,_30,_32)){
var _33=$.data(this[0],_2d);
return (_33?_33[_30].apply(_33,_32):undefined);
}
return this.each(function(){
var _34=$.data(this,_2d);
(!_34&&!_31&&$.data(this,_2d,new $[_2f][_2d](this,_30))._init());
(_34&&_31&&$.isFunction(_34[_30])&&_34[_30].apply(_34,_32));
});
};
$[_2f]=$[_2f]||{};
$[_2f][_2d]=function(_35,_36){
var _37=this;
this.namespace=_2f;
this.widgetName=_2d;
this.widgetEventPrefix=$[_2f][_2d].eventPrefix||_2d;
this.widgetBaseClass=_2f+"-"+_2d;
this.options=$.extend({},$.widget.defaults,$[_2f][_2d].defaults,$.metadata&&$.metadata.get(_35)[_2d],_36);
this.element=$(_35).bind("setData."+_2d,function(_38,key,_39){
if(_38.target==_35){
return _37._setData(key,_39);
}
}).bind("getData."+_2d,function(_3a,key){
if(_3a.target==_35){
return _37._getData(key);
}
}).bind("remove",function(){
return _37.destroy();
});
};
$[_2f][_2d].prototype=$.extend({},$.widget.prototype,_2e);
$[_2f][_2d].getterSetter="option";
};
$.widget.prototype={_init:function(){
},destroy:function(){
this.element.removeData(this.widgetName).removeClass(this.widgetBaseClass+"-disabled"+" "+this.namespace+"-state-disabled").removeAttr("aria-disabled");
},option:function(key,_3b){
var _3c=key,_3d=this;
if(typeof key=="string"){
if(_3b===undefined){
return this._getData(key);
}
_3c={};
_3c[key]=_3b;
}
$.each(_3c,function(key,_3e){
_3d._setData(key,_3e);
});
},_getData:function(key){
return this.options[key];
},_setData:function(key,_3f){
this.options[key]=_3f;
if(key=="disabled"){
this.element[_3f?"addClass":"removeClass"](this.widgetBaseClass+"-disabled"+" "+this.namespace+"-state-disabled").attr("aria-disabled",_3f);
}
},enable:function(){
this._setData("disabled",false);
},disable:function(){
this._setData("disabled",true);
},_trigger:function(_40,_41,_42){
var _43=this.options[_40],_44=(_40==this.widgetEventPrefix?_40:this.widgetEventPrefix+_40);
_41=$.Event(_41);
_41.type=_44;
if(_41.originalEvent){
for(var i=$.event.props.length,_45;i;){
_45=$.event.props[--i];
_41[_45]=_41.originalEvent[_45];
}
}
this.element.trigger(_41,_42);
return !($.isFunction(_43)&&_43.call(this.element[0],_41,_42)===false||_41.isDefaultPrevented());
}};
$.widget.defaults={disabled:false};
$.ui.mouse={_mouseInit:function(){
var _46=this;
this.element.bind("mousedown."+this.widgetName,function(_47){
return _46._mouseDown(_47);
}).bind("click."+this.widgetName,function(_48){
if(_46._preventClickEvent){
_46._preventClickEvent=false;
_48.stopImmediatePropagation();
return false;
}
});
if($.browser.msie){
this._mouseUnselectable=this.element.attr("unselectable");
this.element.attr("unselectable","on");
}
this.started=false;
},_mouseDestroy:function(){
this.element.unbind("."+this.widgetName);
($.browser.msie&&this.element.attr("unselectable",this._mouseUnselectable));
},_mouseDown:function(_49){
_49.originalEvent=_49.originalEvent||{};
if(_49.originalEvent.mouseHandled){
return;
}
(this._mouseStarted&&this._mouseUp(_49));
this._mouseDownEvent=_49;
var _4a=this,_4b=(_49.which==1),_4c=(typeof this.options.cancel=="string"?$(_49.target).parents().add(_49.target).filter(this.options.cancel).length:false);
if(!_4b||_4c||!this._mouseCapture(_49)){
return true;
}
this.mouseDelayMet=!this.options.delay;
if(!this.mouseDelayMet){
this._mouseDelayTimer=setTimeout(function(){
_4a.mouseDelayMet=true;
},this.options.delay);
}
if(this._mouseDistanceMet(_49)&&this._mouseDelayMet(_49)){
this._mouseStarted=(this._mouseStart(_49)!==false);
if(!this._mouseStarted){
_49.preventDefault();
return true;
}
}
this._mouseMoveDelegate=function(_4d){
return _4a._mouseMove(_4d);
};
this._mouseUpDelegate=function(_4e){
return _4a._mouseUp(_4e);
};
$(document).bind("mousemove."+this.widgetName,this._mouseMoveDelegate).bind("mouseup."+this.widgetName,this._mouseUpDelegate);
($.browser.safari||_49.preventDefault());
_49.originalEvent.mouseHandled=true;
return true;
},_mouseMove:function(_4f){
if($.browser.msie&&!_4f.button){
return this._mouseUp(_4f);
}
if(this._mouseStarted){
this._mouseDrag(_4f);
return _4f.preventDefault();
}
if(this._mouseDistanceMet(_4f)&&this._mouseDelayMet(_4f)){
this._mouseStarted=(this._mouseStart(this._mouseDownEvent,_4f)!==false);
(this._mouseStarted?this._mouseDrag(_4f):this._mouseUp(_4f));
}
return !this._mouseStarted;
},_mouseUp:function(_50){
$(document).unbind("mousemove."+this.widgetName,this._mouseMoveDelegate).unbind("mouseup."+this.widgetName,this._mouseUpDelegate);
if(this._mouseStarted){
this._mouseStarted=false;
this._preventClickEvent=(_50.target==this._mouseDownEvent.target);
this._mouseStop(_50);
}
return false;
},_mouseDistanceMet:function(_51){
return (Math.max(Math.abs(this._mouseDownEvent.pageX-_51.pageX),Math.abs(this._mouseDownEvent.pageY-_51.pageY))>=this.options.distance);
},_mouseDelayMet:function(_52){
return this.mouseDelayMet;
},_mouseStart:function(_53){
},_mouseDrag:function(_54){
},_mouseStop:function(_55){
},_mouseCapture:function(_56){
return true;
}};
$.ui.mouse.defaults={cancel:null,distance:1,delay:0};
})(jQuery);
(function($){
$.widget("ui.draggable",$.extend({},$.ui.mouse,{_init:function(){
if(this.options.helper=="original"&&!(/^(?:r|a|f)/).test(this.element.css("position"))){
this.element[0].style.position="relative";
}
(this.options.addClasses&&this.element.addClass("ui-draggable"));
(this.options.disabled&&this.element.addClass("ui-draggable-disabled"));
this._mouseInit();
},destroy:function(){
if(!this.element.data("draggable")){
return;
}
this.element.removeData("draggable").unbind(".draggable").removeClass("ui-draggable"+" ui-draggable-dragging"+" ui-draggable-disabled");
this._mouseDestroy();
},_mouseCapture:function(_1){
var o=this.options;
if(this.helper||o.disabled||$(_1.target).is(".ui-resizable-handle")){
return false;
}
this.handle=this._getHandle(_1);
if(!this.handle){
return false;
}
return true;
},_mouseStart:function(_2){
var o=this.options;
this.helper=this._createHelper(_2);
this._cacheHelperProportions();
if($.ui.ddmanager){
$.ui.ddmanager.current=this;
}
this._cacheMargins();
this.cssPosition=this.helper.css("position");
this.scrollParent=this.helper.scrollParent();
this.offset=this.element.offset();
this.offset={top:this.offset.top-this.margins.top,left:this.offset.left-this.margins.left};
$.extend(this.offset,{click:{left:_2.pageX-this.offset.left,top:_2.pageY-this.offset.top},parent:this._getParentOffset(),relative:this._getRelativeOffset()});
this.originalPosition=this._generatePosition(_2);
this.originalPageX=_2.pageX;
this.originalPageY=_2.pageY;
if(o.cursorAt){
this._adjustOffsetFromHelper(o.cursorAt);
}
if(o.containment){
this._setContainment();
}
this._trigger("start",_2);
this._cacheHelperProportions();
if($.ui.ddmanager&&!o.dropBehaviour){
$.ui.ddmanager.prepareOffsets(this,_2);
}
this.helper.addClass("ui-draggable-dragging");
this._mouseDrag(_2,true);
return true;
},_mouseDrag:function(_3,_4){
this.position=this._generatePosition(_3);
this.positionAbs=this._convertPositionTo("absolute");
if(!_4){
var ui=this._uiHash();
this._trigger("drag",_3,ui);
this.position=ui.position;
}
if(!this.options.axis||this.options.axis!="y"){
this.helper[0].style.left=this.position.left+"px";
}
if(!this.options.axis||this.options.axis!="x"){
this.helper[0].style.top=this.position.top+"px";
}
if($.ui.ddmanager){
$.ui.ddmanager.drag(this,_3);
}
return false;
},_mouseStop:function(_5){
var _6=false;
if($.ui.ddmanager&&!this.options.dropBehaviour){
_6=$.ui.ddmanager.drop(this,_5);
}
if(this.dropped){
_6=this.dropped;
this.dropped=false;
}
if((this.options.revert=="invalid"&&!_6)||(this.options.revert=="valid"&&_6)||this.options.revert===true||($.isFunction(this.options.revert)&&this.options.revert.call(this.element,_6))){
var _7=this;
$(this.helper).animate(this.originalPosition,parseInt(this.options.revertDuration,10),function(){
_7._trigger("stop",_5);
_7._clear();
});
}else{
this._trigger("stop",_5);
this._clear();
}
return false;
},_getHandle:function(_8){
var _9=!this.options.handle||!$(this.options.handle,this.element).length?true:false;
$(this.options.handle,this.element).find("*").andSelf().each(function(){
if(this==_8.target){
_9=true;
}
});
return _9;
},_createHelper:function(_a){
var o=this.options;
var _b=$.isFunction(o.helper)?$(o.helper.apply(this.element[0],[_a])):(o.helper=="clone"?this.element.clone():this.element);
if(!_b.parents("body").length){
_b.appendTo((o.appendTo=="parent"?this.element[0].parentNode:o.appendTo));
}
if(_b[0]!=this.element[0]&&!(/(fixed|absolute)/).test(_b.css("position"))){
_b.css("position","absolute");
}
return _b;
},_adjustOffsetFromHelper:function(_c){
if(_c.left!=undefined){
this.offset.click.left=_c.left+this.margins.left;
}
if(_c.right!=undefined){
this.offset.click.left=this.helperProportions.width-_c.right+this.margins.left;
}
if(_c.top!=undefined){
this.offset.click.top=_c.top+this.margins.top;
}
if(_c.bottom!=undefined){
this.offset.click.top=this.helperProportions.height-_c.bottom+this.margins.top;
}
},_getParentOffset:function(){
this.offsetParent=this.helper.offsetParent();
var po=this.offsetParent.offset();
if(this.cssPosition=="absolute"&&this.scrollParent[0]!=document&&$.ui.contains(this.scrollParent[0],this.offsetParent[0])){
po.left+=this.scrollParent.scrollLeft();
po.top+=this.scrollParent.scrollTop();
}
if((this.offsetParent[0]==document.body)||(this.offsetParent[0].tagName&&this.offsetParent[0].tagName.toLowerCase()=="html"&&$.browser.msie)){
po={top:0,left:0};
}
return {top:po.top+(parseInt(this.offsetParent.css("borderTopWidth"),10)||0),left:po.left+(parseInt(this.offsetParent.css("borderLeftWidth"),10)||0)};
},_getRelativeOffset:function(){
if(this.cssPosition=="relative"){
var p=this.element.position();
return {top:p.top-(parseInt(this.helper.css("top"),10)||0)+this.scrollParent.scrollTop(),left:p.left-(parseInt(this.helper.css("left"),10)||0)+this.scrollParent.scrollLeft()};
}else{
return {top:0,left:0};
}
},_cacheMargins:function(){
this.margins={left:(parseInt(this.element.css("marginLeft"),10)||0),top:(parseInt(this.element.css("marginTop"),10)||0)};
},_cacheHelperProportions:function(){
this.helperProportions={width:this.helper.outerWidth(),height:this.helper.outerHeight()};
},_setContainment:function(){
var o=this.options;
if(o.containment=="parent"){
o.containment=this.helper[0].parentNode;
}
if(o.containment=="document"||o.containment=="window"){
this.containment=[0-this.offset.relative.left-this.offset.parent.left,0-this.offset.relative.top-this.offset.parent.top,$(o.containment=="document"?document:window).width()-this.helperProportions.width-this.margins.left,($(o.containment=="document"?document:window).height()||document.body.parentNode.scrollHeight)-this.helperProportions.height-this.margins.top];
}
if(!(/^(document|window|parent)$/).test(o.containment)&&o.containment.constructor!=Array){
var ce=$(o.containment)[0];
if(!ce){
return;
}
var co=$(o.containment).offset();
var _d=($(ce).css("overflow")!="hidden");
this.containment=[co.left+(parseInt($(ce).css("borderLeftWidth"),10)||0)+(parseInt($(ce).css("paddingLeft"),10)||0)-this.margins.left,co.top+(parseInt($(ce).css("borderTopWidth"),10)||0)+(parseInt($(ce).css("paddingTop"),10)||0)-this.margins.top,co.left+(_d?Math.max(ce.scrollWidth,ce.offsetWidth):ce.offsetWidth)-(parseInt($(ce).css("borderLeftWidth"),10)||0)-(parseInt($(ce).css("paddingRight"),10)||0)-this.helperProportions.width-this.margins.left,co.top+(_d?Math.max(ce.scrollHeight,ce.offsetHeight):ce.offsetHeight)-(parseInt($(ce).css("borderTopWidth"),10)||0)-(parseInt($(ce).css("paddingBottom"),10)||0)-this.helperProportions.height-this.margins.top];
}else{
if(o.containment.constructor==Array){
this.containment=o.containment;
}
}
},_convertPositionTo:function(d,_e){
if(!_e){
_e=this.position;
}
var _f=d=="absolute"?1:-1;
var o=this.options,_10=this.cssPosition=="absolute"&&!(this.scrollParent[0]!=document&&$.ui.contains(this.scrollParent[0],this.offsetParent[0]))?this.offsetParent:this.scrollParent,_11=(/(html|body)/i).test(_10[0].tagName);
return {top:(_e.top+this.offset.relative.top*_f+this.offset.parent.top*_f-($.browser.safari&&this.cssPosition=="fixed"?0:(this.cssPosition=="fixed"?-this.scrollParent.scrollTop():(_11?0:_10.scrollTop()))*_f)),left:(_e.left+this.offset.relative.left*_f+this.offset.parent.left*_f-($.browser.safari&&this.cssPosition=="fixed"?0:(this.cssPosition=="fixed"?-this.scrollParent.scrollLeft():_11?0:_10.scrollLeft())*_f))};
},_generatePosition:function(_12){
var o=this.options,_13=this.cssPosition=="absolute"&&!(this.scrollParent[0]!=document&&$.ui.contains(this.scrollParent[0],this.offsetParent[0]))?this.offsetParent:this.scrollParent,_14=(/(html|body)/i).test(_13[0].tagName);
if(this.cssPosition=="relative"&&!(this.scrollParent[0]!=document&&this.scrollParent[0]!=this.offsetParent[0])){
this.offset.relative=this._getRelativeOffset();
}
var _15=_12.pageX;
var _16=_12.pageY;
if(this.originalPosition){
if(this.containment){
if(_12.pageX-this.offset.click.left<this.containment[0]){
_15=this.containment[0]+this.offset.click.left;
}
if(_12.pageY-this.offset.click.top<this.containment[1]){
_16=this.containment[1]+this.offset.click.top;
}
if(_12.pageX-this.offset.click.left>this.containment[2]){
_15=this.containment[2]+this.offset.click.left;
}
if(_12.pageY-this.offset.click.top>this.containment[3]){
_16=this.containment[3]+this.offset.click.top;
}
}
if(o.grid){
var top=this.originalPageY+Math.round((_16-this.originalPageY)/o.grid[1])*o.grid[1];
_16=this.containment?(!(top-this.offset.click.top<this.containment[1]||top-this.offset.click.top>this.containment[3])?top:(!(top-this.offset.click.top<this.containment[1])?top-o.grid[1]:top+o.grid[1])):top;
var _17=this.originalPageX+Math.round((_15-this.originalPageX)/o.grid[0])*o.grid[0];
_15=this.containment?(!(_17-this.offset.click.left<this.containment[0]||_17-this.offset.click.left>this.containment[2])?_17:(!(_17-this.offset.click.left<this.containment[0])?_17-o.grid[0]:_17+o.grid[0])):_17;
}
}
return {top:(_16-this.offset.click.top-this.offset.relative.top-this.offset.parent.top+($.browser.safari&&this.cssPosition=="fixed"?0:(this.cssPosition=="fixed"?-this.scrollParent.scrollTop():(_14?0:_13.scrollTop())))),left:(_15-this.offset.click.left-this.offset.relative.left-this.offset.parent.left+($.browser.safari&&this.cssPosition=="fixed"?0:(this.cssPosition=="fixed"?-this.scrollParent.scrollLeft():_14?0:_13.scrollLeft())))};
},_clear:function(){
this.helper.removeClass("ui-draggable-dragging");
if(this.helper[0]!=this.element[0]&&!this.cancelHelperRemoval){
this.helper.remove();
}
this.helper=null;
this.cancelHelperRemoval=false;
},_trigger:function(_18,_19,ui){
ui=ui||this._uiHash();
$.ui.plugin.call(this,_18,[_19,ui]);
if(_18=="drag"){
this.positionAbs=this._convertPositionTo("absolute");
}
return $.widget.prototype._trigger.call(this,_18,_19,ui);
},plugins:{},_uiHash:function(_1a){
return {helper:this.helper,position:this.position,absolutePosition:this.positionAbs,offset:this.positionAbs};
}}));
$.extend($.ui.draggable,{version:"1.7.2",eventPrefix:"drag",defaults:{addClasses:true,appendTo:"parent",axis:false,cancel:":input,option",connectToSortable:false,containment:false,cursor:"auto",cursorAt:false,delay:0,distance:1,grid:false,handle:false,helper:"original",iframeFix:false,opacity:false,refreshPositions:false,revert:false,revertDuration:500,scope:"default",scroll:true,scrollSensitivity:20,scrollSpeed:20,snap:false,snapMode:"both",snapTolerance:20,stack:false,zIndex:false}});
$.ui.plugin.add("draggable","connectToSortable",{start:function(_1b,ui){
var _1c=$(this).data("draggable"),o=_1c.options,_1d=$.extend({},ui,{item:_1c.element});
_1c.sortables=[];
$(o.connectToSortable).each(function(){
var _1e=$.data(this,"sortable");
if(_1e&&!_1e.options.disabled){
_1c.sortables.push({instance:_1e,shouldRevert:_1e.options.revert});
_1e._refreshItems();
_1e._trigger("activate",_1b,_1d);
}
});
},stop:function(_1f,ui){
var _20=$(this).data("draggable"),_21=$.extend({},ui,{item:_20.element});
$.each(_20.sortables,function(){
if(this.instance.isOver){
this.instance.isOver=0;
_20.cancelHelperRemoval=true;
this.instance.cancelHelperRemoval=false;
if(this.shouldRevert){
this.instance.options.revert=true;
}
this.instance._mouseStop(_1f);
this.instance.options.helper=this.instance.options._helper;
if(_20.options.helper=="original"){
this.instance.currentItem.css({top:"auto",left:"auto"});
}
}else{
this.instance.cancelHelperRemoval=false;
this.instance._trigger("deactivate",_1f,_21);
}
});
},drag:function(_22,ui){
var _23=$(this).data("draggable"),_24=this;
var _25=function(o){
var _26=this.offset.click.top,_27=this.offset.click.left;
var _28=this.positionAbs.top,_29=this.positionAbs.left;
var _2a=o.height,_2b=o.width;
var _2c=o.top,_2d=o.left;
return $.ui.isOver(_28+_26,_29+_27,_2c,_2d,_2a,_2b);
};
$.each(_23.sortables,function(i){
this.instance.positionAbs=_23.positionAbs;
this.instance.helperProportions=_23.helperProportions;
this.instance.offset.click=_23.offset.click;
if(this.instance._intersectsWith(this.instance.containerCache)){
if(!this.instance.isOver){
this.instance.isOver=1;
this.instance.currentItem=$(_24).clone().appendTo(this.instance.element).data("sortable-item",true);
this.instance.options._helper=this.instance.options.helper;
this.instance.options.helper=function(){
return ui.helper[0];
};
_22.target=this.instance.currentItem[0];
this.instance._mouseCapture(_22,true);
this.instance._mouseStart(_22,true,true);
this.instance.offset.click.top=_23.offset.click.top;
this.instance.offset.click.left=_23.offset.click.left;
this.instance.offset.parent.left-=_23.offset.parent.left-this.instance.offset.parent.left;
this.instance.offset.parent.top-=_23.offset.parent.top-this.instance.offset.parent.top;
_23._trigger("toSortable",_22);
_23.dropped=this.instance.element;
_23.currentItem=_23.element;
this.instance.fromOutside=_23;
}
if(this.instance.currentItem){
this.instance._mouseDrag(_22);
}
}else{
if(this.instance.isOver){
this.instance.isOver=0;
this.instance.cancelHelperRemoval=true;
this.instance.options.revert=false;
this.instance._trigger("out",_22,this.instance._uiHash(this.instance));
this.instance._mouseStop(_22,true);
this.instance.options.helper=this.instance.options._helper;
this.instance.currentItem.remove();
if(this.instance.placeholder){
this.instance.placeholder.remove();
}
_23._trigger("fromSortable",_22);
_23.dropped=false;
}
}
});
}});
$.ui.plugin.add("draggable","cursor",{start:function(_2e,ui){
var t=$("body"),o=$(this).data("draggable").options;
if(t.css("cursor")){
o._cursor=t.css("cursor");
}
t.css("cursor",o.cursor);
},stop:function(_2f,ui){
var o=$(this).data("draggable").options;
if(o._cursor){
$("body").css("cursor",o._cursor);
}
}});
$.ui.plugin.add("draggable","iframeFix",{start:function(_30,ui){
var o=$(this).data("draggable").options;
$(o.iframeFix===true?"iframe":o.iframeFix).each(function(){
$("<div class=\"ui-draggable-iframeFix\" style=\"background: #fff;\"></div>").css({width:this.offsetWidth+"px",height:this.offsetHeight+"px",position:"absolute",opacity:"0.001",zIndex:1000}).css($(this).offset()).appendTo("body");
});
},stop:function(_31,ui){
$("div.ui-draggable-iframeFix").each(function(){
this.parentNode.removeChild(this);
});
}});
$.ui.plugin.add("draggable","opacity",{start:function(_32,ui){
var t=$(ui.helper),o=$(this).data("draggable").options;
if(t.css("opacity")){
o._opacity=t.css("opacity");
}
t.css("opacity",o.opacity);
},stop:function(_33,ui){
var o=$(this).data("draggable").options;
if(o._opacity){
$(ui.helper).css("opacity",o._opacity);
}
}});
$.ui.plugin.add("draggable","scroll",{start:function(_34,ui){
var i=$(this).data("draggable");
if(i.scrollParent[0]!=document&&i.scrollParent[0].tagName!="HTML"){
i.overflowOffset=i.scrollParent.offset();
}
},drag:function(_35,ui){
var i=$(this).data("draggable"),o=i.options,_36=false;
if(i.scrollParent[0]!=document&&i.scrollParent[0].tagName!="HTML"){
if(!o.axis||o.axis!="x"){
if((i.overflowOffset.top+i.scrollParent[0].offsetHeight)-_35.pageY<o.scrollSensitivity){
i.scrollParent[0].scrollTop=_36=i.scrollParent[0].scrollTop+o.scrollSpeed;
}else{
if(_35.pageY-i.overflowOffset.top<o.scrollSensitivity){
i.scrollParent[0].scrollTop=_36=i.scrollParent[0].scrollTop-o.scrollSpeed;
}
}
}
if(!o.axis||o.axis!="y"){
if((i.overflowOffset.left+i.scrollParent[0].offsetWidth)-_35.pageX<o.scrollSensitivity){
i.scrollParent[0].scrollLeft=_36=i.scrollParent[0].scrollLeft+o.scrollSpeed;
}else{
if(_35.pageX-i.overflowOffset.left<o.scrollSensitivity){
i.scrollParent[0].scrollLeft=_36=i.scrollParent[0].scrollLeft-o.scrollSpeed;
}
}
}
}else{
if(!o.axis||o.axis!="x"){
if(_35.pageY-$(document).scrollTop()<o.scrollSensitivity){
_36=$(document).scrollTop($(document).scrollTop()-o.scrollSpeed);
}else{
if($(window).height()-(_35.pageY-$(document).scrollTop())<o.scrollSensitivity){
_36=$(document).scrollTop($(document).scrollTop()+o.scrollSpeed);
}
}
}
if(!o.axis||o.axis!="y"){
if(_35.pageX-$(document).scrollLeft()<o.scrollSensitivity){
_36=$(document).scrollLeft($(document).scrollLeft()-o.scrollSpeed);
}else{
if($(window).width()-(_35.pageX-$(document).scrollLeft())<o.scrollSensitivity){
_36=$(document).scrollLeft($(document).scrollLeft()+o.scrollSpeed);
}
}
}
}
if(_36!==false&&$.ui.ddmanager&&!o.dropBehaviour){
$.ui.ddmanager.prepareOffsets(i,_35);
}
}});
$.ui.plugin.add("draggable","snap",{start:function(_37,ui){
var i=$(this).data("draggable"),o=i.options;
i.snapElements=[];
$(o.snap.constructor!=String?(o.snap.items||":data(draggable)"):o.snap).each(function(){
var $t=$(this);
var $o=$t.offset();
if(this!=i.element[0]){
i.snapElements.push({item:this,width:$t.outerWidth(),height:$t.outerHeight(),top:$o.top,left:$o.left});
}
});
},drag:function(_38,ui){
var _39=$(this).data("draggable"),o=_39.options;
var d=o.snapTolerance;
var x1=ui.offset.left,x2=x1+_39.helperProportions.width,y1=ui.offset.top,y2=y1+_39.helperProportions.height;
for(var i=_39.snapElements.length-1;i>=0;i--){
var l=_39.snapElements[i].left,r=l+_39.snapElements[i].width,t=_39.snapElements[i].top,b=t+_39.snapElements[i].height;
if(!((l-d<x1&&x1<r+d&&t-d<y1&&y1<b+d)||(l-d<x1&&x1<r+d&&t-d<y2&&y2<b+d)||(l-d<x2&&x2<r+d&&t-d<y1&&y1<b+d)||(l-d<x2&&x2<r+d&&t-d<y2&&y2<b+d))){
if(_39.snapElements[i].snapping){
(_39.options.snap.release&&_39.options.snap.release.call(_39.element,_38,$.extend(_39._uiHash(),{snapItem:_39.snapElements[i].item})));
}
_39.snapElements[i].snapping=false;
continue;
}
if(o.snapMode!="inner"){
var ts=Math.abs(t-y2)<=d;
var bs=Math.abs(b-y1)<=d;
var ls=Math.abs(l-x2)<=d;
var rs=Math.abs(r-x1)<=d;
if(ts){
ui.position.top=_39._convertPositionTo("relative",{top:t-_39.helperProportions.height,left:0}).top-_39.margins.top;
}
if(bs){
ui.position.top=_39._convertPositionTo("relative",{top:b,left:0}).top-_39.margins.top;
}
if(ls){
ui.position.left=_39._convertPositionTo("relative",{top:0,left:l-_39.helperProportions.width}).left-_39.margins.left;
}
if(rs){
ui.position.left=_39._convertPositionTo("relative",{top:0,left:r}).left-_39.margins.left;
}
}
var _3a=(ts||bs||ls||rs);
if(o.snapMode!="outer"){
var ts=Math.abs(t-y1)<=d;
var bs=Math.abs(b-y2)<=d;
var ls=Math.abs(l-x1)<=d;
var rs=Math.abs(r-x2)<=d;
if(ts){
ui.position.top=_39._convertPositionTo("relative",{top:t,left:0}).top-_39.margins.top;
}
if(bs){
ui.position.top=_39._convertPositionTo("relative",{top:b-_39.helperProportions.height,left:0}).top-_39.margins.top;
}
if(ls){
ui.position.left=_39._convertPositionTo("relative",{top:0,left:l}).left-_39.margins.left;
}
if(rs){
ui.position.left=_39._convertPositionTo("relative",{top:0,left:r-_39.helperProportions.width}).left-_39.margins.left;
}
}
if(!_39.snapElements[i].snapping&&(ts||bs||ls||rs||_3a)){
(_39.options.snap.snap&&_39.options.snap.snap.call(_39.element,_38,$.extend(_39._uiHash(),{snapItem:_39.snapElements[i].item})));
}
_39.snapElements[i].snapping=(ts||bs||ls||rs||_3a);
}
}});
$.ui.plugin.add("draggable","stack",{start:function(_3b,ui){
var o=$(this).data("draggable").options;
var _3c=$.makeArray($(o.stack.group)).sort(function(a,b){
return (parseInt($(a).css("zIndex"),10)||o.stack.min)-(parseInt($(b).css("zIndex"),10)||o.stack.min);
});
$(_3c).each(function(i){
this.style.zIndex=o.stack.min+i;
});
this[0].style.zIndex=o.stack.min+_3c.length;
}});
$.ui.plugin.add("draggable","zIndex",{start:function(_3d,ui){
var t=$(ui.helper),o=$(this).data("draggable").options;
if(t.css("zIndex")){
o._zIndex=t.css("zIndex");
}
t.css("zIndex",o.zIndex);
},stop:function(_3e,ui){
var o=$(this).data("draggable").options;
if(o._zIndex){
$(ui.helper).css("zIndex",o._zIndex);
}
}});
})(jQuery);
(function($){
$.widget("ui.droppable",{_init:function(){
var o=this.options,_1=o.accept;
this.isover=0;
this.isout=1;
this.options.accept=this.options.accept&&$.isFunction(this.options.accept)?this.options.accept:function(d){
return d.is(_1);
};
this.proportions={width:this.element[0].offsetWidth,height:this.element[0].offsetHeight};
$.ui.ddmanager.droppables[this.options.scope]=$.ui.ddmanager.droppables[this.options.scope]||[];
$.ui.ddmanager.droppables[this.options.scope].push(this);
(this.options.addClasses&&this.element.addClass("ui-droppable"));
},destroy:function(){
var _2=$.ui.ddmanager.droppables[this.options.scope];
for(var i=0;i<_2.length;i++){
if(_2[i]==this){
_2.splice(i,1);
}
}
this.element.removeClass("ui-droppable ui-droppable-disabled").removeData("droppable").unbind(".droppable");
},_setData:function(_3,_4){
if(_3=="accept"){
this.options.accept=_4&&$.isFunction(_4)?_4:function(d){
return d.is(_4);
};
}else{
$.widget.prototype._setData.apply(this,arguments);
}
},_activate:function(_5){
var _6=$.ui.ddmanager.current;
if(this.options.activeClass){
this.element.addClass(this.options.activeClass);
}
(_6&&this._trigger("activate",_5,this.ui(_6)));
},_deactivate:function(_7){
var _8=$.ui.ddmanager.current;
if(this.options.activeClass){
this.element.removeClass(this.options.activeClass);
}
(_8&&this._trigger("deactivate",_7,this.ui(_8)));
},_over:function(_9){
var _a=$.ui.ddmanager.current;
if(!_a||(_a.currentItem||_a.element)[0]==this.element[0]){
return;
}
if(this.options.accept.call(this.element[0],(_a.currentItem||_a.element))){
if(this.options.hoverClass){
this.element.addClass(this.options.hoverClass);
}
this._trigger("over",_9,this.ui(_a));
}
},_out:function(_b){
var _c=$.ui.ddmanager.current;
if(!_c||(_c.currentItem||_c.element)[0]==this.element[0]){
return;
}
if(this.options.accept.call(this.element[0],(_c.currentItem||_c.element))){
if(this.options.hoverClass){
this.element.removeClass(this.options.hoverClass);
}
this._trigger("out",_b,this.ui(_c));
}
},_drop:function(_d,_e){
var _f=_e||$.ui.ddmanager.current;
if(!_f||(_f.currentItem||_f.element)[0]==this.element[0]){
return false;
}
var _10=false;
this.element.find(":data(droppable)").not(".ui-draggable-dragging").each(function(){
var _11=$.data(this,"droppable");
if(_11.options.greedy&&$.ui.intersect(_f,$.extend(_11,{offset:_11.element.offset()}),_11.options.tolerance)){
_10=true;
return false;
}
});
if(_10){
return false;
}
if(this.options.accept.call(this.element[0],(_f.currentItem||_f.element))){
if(this.options.activeClass){
this.element.removeClass(this.options.activeClass);
}
if(this.options.hoverClass){
this.element.removeClass(this.options.hoverClass);
}
this._trigger("drop",_d,this.ui(_f));
return this.element;
}
return false;
},ui:function(c){
return {draggable:(c.currentItem||c.element),helper:c.helper,position:c.position,absolutePosition:c.positionAbs,offset:c.positionAbs};
}});
$.extend($.ui.droppable,{version:"1.7.2",eventPrefix:"drop",defaults:{accept:"*",activeClass:false,addClasses:true,greedy:false,hoverClass:false,scope:"default",tolerance:"intersect"}});
$.ui.intersect=function(_12,_13,_14){
if(!_13.offset){
return false;
}
var x1=(_12.positionAbs||_12.position.absolute).left,x2=x1+_12.helperProportions.width,y1=(_12.positionAbs||_12.position.absolute).top,y2=y1+_12.helperProportions.height;
var l=_13.offset.left,r=l+_13.proportions.width,t=_13.offset.top,b=t+_13.proportions.height;
switch(_14){
case "fit":
return (l<x1&&x2<r&&t<y1&&y2<b);
break;
case "intersect":
return (l<x1+(_12.helperProportions.width/2)&&x2-(_12.helperProportions.width/2)<r&&t<y1+(_12.helperProportions.height/2)&&y2-(_12.helperProportions.height/2)<b);
break;
case "pointer":
var _15=((_12.positionAbs||_12.position.absolute).left+(_12.clickOffset||_12.offset.click).left),_16=((_12.positionAbs||_12.position.absolute).top+(_12.clickOffset||_12.offset.click).top),_17=$.ui.isOver(_16,_15,t,l,_13.proportions.height,_13.proportions.width);
return _17;
break;
case "touch":
return ((y1>=t&&y1<=b)||(y2>=t&&y2<=b)||(y1<t&&y2>b))&&((x1>=l&&x1<=r)||(x2>=l&&x2<=r)||(x1<l&&x2>r));
break;
default:
return false;
break;
}
};
$.ui.ddmanager={current:null,droppables:{"default":[]},prepareOffsets:function(t,_18){
var m=$.ui.ddmanager.droppables[t.options.scope];
var _19=_18?_18.type:null;
var _1a=(t.currentItem||t.element).find(":data(droppable)").andSelf();
droppablesLoop:
for(var i=0;i<m.length;i++){
if(m[i].options.disabled||(t&&!m[i].options.accept.call(m[i].element[0],(t.currentItem||t.element)))){
continue;
}
for(var j=0;j<_1a.length;j++){
if(_1a[j]==m[i].element[0]){
m[i].proportions.height=0;
continue droppablesLoop;
}
}
m[i].visible=m[i].element.css("display")!="none";
if(!m[i].visible){
continue;
}
m[i].offset=m[i].element.offset();
m[i].proportions={width:m[i].element[0].offsetWidth,height:m[i].element[0].offsetHeight};
if(_19=="mousedown"){
m[i]._activate.call(m[i],_18);
}
}
},drop:function(_1b,_1c){
var _1d=false;
$.each($.ui.ddmanager.droppables[_1b.options.scope],function(){
if(!this.options){
return;
}
if(!this.options.disabled&&this.visible&&$.ui.intersect(_1b,this,this.options.tolerance)){
_1d=this._drop.call(this,_1c);
}
if(!this.options.disabled&&this.visible&&this.options.accept.call(this.element[0],(_1b.currentItem||_1b.element))){
this.isout=1;
this.isover=0;
this._deactivate.call(this,_1c);
}
});
return _1d;
},drag:function(_1e,_1f){
if(_1e.options.refreshPositions){
$.ui.ddmanager.prepareOffsets(_1e,_1f);
}
$.each($.ui.ddmanager.droppables[_1e.options.scope],function(){
if(this.options.disabled||this.greedyChild||!this.visible){
return;
}
var _20=$.ui.intersect(_1e,this,this.options.tolerance);
var c=!_20&&this.isover==1?"isout":(_20&&this.isover==0?"isover":null);
if(!c){
return;
}
var _21;
if(this.options.greedy){
var _22=this.element.parents(":data(droppable):eq(0)");
if(_22.length){
_21=$.data(_22[0],"droppable");
_21.greedyChild=(c=="isover"?1:0);
}
}
if(_21&&c=="isover"){
_21["isover"]=0;
_21["isout"]=1;
_21._out.call(_21,_1f);
}
this[c]=1;
this[c=="isout"?"isover":"isout"]=0;
this[c=="isover"?"_over":"_out"].call(this,_1f);
if(_21&&c=="isout"){
_21["isout"]=0;
_21["isover"]=1;
_21._over.call(_21,_1f);
}
});
}};
})(jQuery);
(function($){
$.extend($.fn,{tabs:function(){
links=$("ul:first > li > a",this);
links.each(function(){
hash=this.href.match(/(#.*)$/);
this.tab=$(hash[1]);
this.tabLinks=links;
if($(this).parent("li.tabs-selected").length==0){
this.tab.hide();
}
});
links.click(function(){
this.tabLinks.each(function(){
this.tab.hide();
});
this.tabLinks.parent("li").removeClass("tabs-selected");
this.tab.show();
$(this).parent("li").addClass("tabs-selected");
return false;
});
},underlineAccessKey:function(){
this.each(function(){
key=$(this).attr("accesskey");
if(key){
$(this).contents().each(function(){
if($(this).children().get().length==0){
text=$(this).text();
i=text.toLowerCase().indexOf(key.toLowerCase());
if(i>=0){
$(this).replaceWith(text.substr(0,i)+"<span style=\"text-decoration: underline\">"+text.substr(i,1)+"</span>"+text.substr(i+1));
}
}
});
}
});
},dateToggler:function(){
function _1(to,_2){
n=Math.floor((to-_2)/60000);
if(n==0){
return "less than a minute";
}
if(n==1){
return "a minute";
}
if(n<45){
return n+" minutes";
}
if(n<90){
return " about 1 hour";
}
if(n<1440){
return "about "+Math.round(n/60)+" hours";
}
if(n<2880){
return "1 day";
}
if(n<43200){
return Math.round(n/1440)+" days";
}
if(n<86400){
return "about 1 month";
}
if(n<525960){
return Math.round(n/43200)+" months";
}
if(n<1051920){
return "about 1 year";
}
return "over "+Math.round(n/525960)+" years";
};
function _3(_4){
return _1(new Date().getTime(),new Date(_4*1000))+" ago";
};
function _5(){
elem=$(this);
match=elem.attr("class").match(/seconds_(\d+)/);
elem.children(".ago").text(_3(match[1]));
elem.children(".full, .ago").toggle();
};
this.each(function(){
elem=$(this);
elem.html("<span class=\"full\">"+elem.text()+"</span><span class=\"ago\"></span>");
elem.children(".ago").hide();
_5.apply(this);
elem.click(_5);
});
}});
})(jQuery);
$(document).ready(function(){
$(".tabs").tabs();
$("table.sortable").tablesorter({widgets:["zebra"]});
$("table.history").tablesorter({widgets:["zebra"],headers:{0:{sorter:false},1:{sorter:false},2:{sorter:"text"},3:{sorter:"text"},4:{sorter:"text"},5:{sorter:"text"},6:{sorter:false}}});
$("table.history").disableSelection();
$("table.history td *").css({cursor:"move"});
$("table.history tbody tr").draggable({helper:function(){
table=$("<table class=\"history-draggable\"><tbody>"+$(this).html()+"</tbody></table>");
a=$.makeArray(table.find("td"));
b=$.makeArray($(this).find("td"));
for(i=0;i<a.length;++i){
$(a[i]).css({width:$(b[i]).width()+"px"});
}
return table;
}}).droppable({hoverClass:"history-droppable-hover",drop:function(_6,ui){
to=this.id;
from=ui.draggable.attr("id");
if(to!=from){
location.href="/diff?from="+from+"&to="+to;
}
}});
$(".zebra tr:even").addClass("even");
$(".zebra tr:odd").addClass("odd");
$("input.clear").focus(function(){
if(this.value==this.defaultValue){
this.value="";
}
}).blur(function(){
if(this.value==""){
this.value=this.defaultValue;
}
});
$(".date").dateToggler();
$("label, #menu, .tabs > ul").disableSelection();
$("#upload-file").change(function(){
elem=$("#upload-path");
if(elem.size()==1){
val=elem.val();
if(val==""){
elem.val(this.value);
}else{
if(val.match(/^(.*\/)?new page$/)){
val=val.replace(/new page$/,"")+this.value;
elem.val(val);
}
}
}
});
$("*[accesskey]").underlineAccessKey();
});

