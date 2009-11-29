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
html="<ul>";
$.each(_5,function(i,_6){
html+="<li><div class=\""+(_6[0]?"hitarea collapsed":"placeholder")+"\"><div class=\"arrow\"/><div class=\""+_6[1]+"\"/></div><a href=\""+_6[2]+"\">"+_6[3]+"</a></li>";
});
html+="</ul>";
if(_4==_1.root){
_3.empty();
}
_3.removeClass("wait").append(html);
_7(_3);
}});
};
function _7(_8){
_8.find("li > .hitarea").click(function(){
hitarea=$(this);
parent=hitarea.parent();
link=parent.children("a");
if(hitarea.hasClass("collapsed")){
_2(parent,link.attr("href"));
hitarea.removeClass("collapsed").addClass("expanded");
}else{
parent.children("ul").hide();
hitarea.removeClass("expanded").addClass("collapsed");
}
return false;
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
$("#treeview-tabs").tabs();
$("#treeview").treeView();
}
});

