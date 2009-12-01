(function($){
$.extend($.fn,{treeView:function(_1){
if(!_1){
_1={};
}
if(!_1.root){
_1.root="/";
}
if(!_1.url){
_1.url="/sys/treeview.json";
}
function _2(_3,_4){
if(_3.children("ul").length!=0){
_3.children("ul").show();
return;
}
_3.addClass("wait");
function _5(_6){
var _7="<ul>";
$.each(_6,function(i,_8){
_7+="<li><div class=\""+(_8[0]?"hitarea collapsed":"placeholder")+"\"><div class=\"arrow\"/><div class=\""+_8[1]+"\"/></div><a href=\""+_8[2]+"\">"+_8[3]+"</a></li>";
});
_7+="</ul>";
if(_4==_1.root){
_3.empty();
}
_3.children("ul").remove();
_3.removeClass("wait").append(_7);
_9(_3);
};
$.ajax({url:_1.url,data:{dir:_4},dataType:"json",type:"GET",success:_5});
$.ajax({url:_1.url,data:{dir:_4},dataType:"json",type:"GET",success:_5,cache:false});
};
function _a(_b){
return _1.store&&$.inArray(_b,$.store.get(_1.store,[]))>=0;
};
function _c(_d,_e){
if(_1.store){
var _f=$.store.get(_1.store,[]);
if(!_e){
_f=$.grep(_f,function(n,i){
return n!=_d;
});
}else{
if($.inArray(_d,_f)<0){
_f.push(_d);
}
}
$.store.set(_1.store,_f);
}
};
function _9(_10){
_10.find("li > .hitarea").click(function(){
var _11=$(this);
var _12=_11.parent();
var _13=_12.children("a").attr("href");
if(_11.hasClass("collapsed")){
_2(_12,_13);
_11.removeClass("collapsed").addClass("expanded");
}else{
_12.children("ul").hide();
_11.removeClass("expanded").addClass("collapsed");
}
_c(_13,_11.hasClass("expanded"));
return false;
}).each(function(){
var _14=$(this);
var _15=_14.parent();
var _16=_15.children("a").attr("href");
if(_a(_16)){
_2(_15,_16);
_14.removeClass("collapsed").addClass("expanded");
}
});
};
this.each(function(){
_2($(this),_1.root);
});
}});
})(jQuery);
$(function(){
if($.browser.mozilla||$.browser.safari){
sidebar=$("#sidebar");
sidebar.html("<div id=\"treeview-tabs\"><ul><li class=\"tabs-selected\"><a href=\"#sidebar-menu\">Menu</a></li><li><a href=\"#sidebar-treeview\">Tree</a></li></ul></div>"+"<div id=\"sidebar-treeview\"><h1>Tree</h1><div id=\"treeview\"></div></div><div id=\"sidebar-menu\">"+sidebar.html()+"</div>");
$("#treeview-tabs").tabs({store:"treeview-tabs"});
$("#treeview").treeView({store:"treeview"});
}
});

