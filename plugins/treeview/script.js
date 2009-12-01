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
$.ajax({url:_1.url,data:{dir:_4},dataType:"json",type:"GET",success:function(_5){
var _6="<ul>";
$.each(_5,function(i,_7){
_6+="<li><div class=\""+(_7[0]?"hitarea collapsed":"placeholder")+"\"><div class=\"arrow\"/><div class=\""+_7[1]+"\"/></div><a href=\""+_7[2]+"\">"+_7[3]+"</a></li>";
});
_6+="</ul>";
if(_4==_1.root){
_3.empty();
}
_3.removeClass("wait").append(_6);
_8(_3);
}});
};
function _9(){
var _a=$.cookie(_1.cookie);
return _a?_a.split(","):[];
};
function _b(_c){
return _1.cookie&&$.inArray(_c,_9())>=0;
};
function _d(_e,_f){
if(_1.cookie){
var _10=_9();
if(!_f){
_10=$.grep(_10,function(n,i){
return n!=_e;
});
}else{
if($.inArray(_e,_10)<0){
_10.push(_e);
}
}
$.cookie(_1.cookie,_10.join(","),{expires:365*100,path:"/"});
}
};
function _8(_11){
_11.find("li > .hitarea").click(function(){
var _12=$(this);
var _13=_12.parent();
var _14=_13.children("a").attr("href");
if(_12.hasClass("collapsed")){
_2(_13,_14);
_12.removeClass("collapsed").addClass("expanded");
}else{
_13.children("ul").hide();
_12.removeClass("expanded").addClass("collapsed");
}
_d(_14,_12.hasClass("expanded"));
return false;
}).each(function(){
var _15=$(this);
var _16=_15.parent();
var _17=_16.children("a").attr("href");
if(_b(_17)){
_2(_16,_17);
_15.removeClass("collapsed").addClass("expanded");
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
$("#treeview-tabs").tabs({cookie:"treeview-tabs"});
$("#treeview").treeView({cookie:"treeview"});
}
});

