<%@ page contentType="text/html;charset=utf-8"%>
<%@ page import="java.util.*"%>
<%@ page import="cn.js.fan.util.*"%>
<%@ page import="com.redmoon.oa.fileark.*"%>
<%@ page import="org.json.*"%>
<%@ page import="cn.js.fan.web.*"%>
<%@ page import="com.cloudwebsoft.framework.db.*"%>
<%@ page import="com.redmoon.oa.pvg.*"%>
<%@ page import="com.redmoon.oa.person.*"%>
<%@ page import="com.redmoon.oa.ui.*"%>
<%@ page import="com.redmoon.oa.flow.*"%>
<%@ page import="com.redmoon.oa.visual.*"%>
<%@ page import="com.redmoon.oa.flow.macroctl.*"%>
<%@ page import="org.json.JSONObject"%>
<%@ page import="org.json.JSONArray"%>
<%
String code = ParamUtil.get(request, "code"); // 模块编码
// String formCode = ParamUtil.get(request, "formCode");
String resource = ParamUtil.get(request, "resource");//来源

ModuleSetupDb vsd = new ModuleSetupDb();
vsd = vsd.getModuleSetupDbOrInit(code);
String formCode = vsd.getString("form_code");

FormMgr fm = new FormMgr();
FormDb fd = fm.getFormDb(formCode);
if (!fd.isLoaded()) {
	//out.print(StrUtil.Alert_Back("该表单不存在！"));
	return;
}

String from = ParamUtil.get(request, "from");
%>
<script src="<%=request.getContextPath()%>/js/powerFloat/jquery-powerFloat.js"></script>
<link type="text/css" rel="stylesheet" href="<%=request.getContextPath()%>/js/powerFloat/powerFloat.css" />
<link type="text/css" rel="stylesheet" href="<%=request.getContextPath()%>/skin/common.css" />
<style>
.target_box{width:780px; position:relative; top:100px; left:300px; padding:10px; border:1px solid #aaa; background-color:#fff;}
.target_list{padding:4px; border-bottom:1px dotted #ddd; overflow:hidden; _zoom:1;}
.target_list span{width:150px; line-height:20px; margin-right:5px; padding:1px; color:#333; font-size:12px; text-align:left; text-decoration:none; float:left;}
.custom_container{position:absolute; background-color:rgba(0, 0, 0, .5); background-color:#999\9;}
.custom_container img{padding:0; position:relative; top:-5px; left:-5px;}
.shadow{-moz-box-shadow:1px 1px 3px rgba(0,0,0,.4); -webkit-box-shadow:1px 1px 3px rgba(0,0,0,.4); box-shadow:1px 1px 3px rgba(0,0,0,.4);}
</style>

<div id="customContainer" class="custom_container"></div>
<div class="" style="margin:0 auto;">
预览列表（拖动可以调整列宽和位置）
<input type="button" id="trigger" src="targetBox" name="selBtn" title="选择列" class="grey_btn_55" value="选择列"></input>

</div>

<div id="targetBox" class="shadow target_box" style="display:none">
	<div class="target_list">
<%
String listField = StrUtil.getNullStr(vsd.getString("list_field"));
String[] fields = StrUtil.split(listField, ",");
String listFieldWidth = StrUtil.getNullStr(vsd.getString("list_field_width"));
String[] fieldsWidth = StrUtil.split(listFieldWidth, ",");
String listFieldOrder = StrUtil.getNullStr(vsd.getString("list_field_order"));
String[] fieldOrder = StrUtil.split(listFieldOrder, ",");
String listFieldLink = StrUtil.getNullStr(vsd.getString("list_field_link"));
String[] fieldsLink = StrUtil.split(listFieldLink, ",");

int len = 0;
if (fields!=null)
	len = fields.length;
int i;
Vector v3 = fd.getFields();
Iterator ir3 = v3.iterator();
List<String> list = null;
if (len == 0){
	list = new ArrayList<String>();
	String checked = "checked";
	// 如果列中字段为空，则默认初始化为前6个字段
	if (v3.size() >= 6){
		int j = 0;
		while (ir3.hasNext()) {
			FormField ff = (FormField) ir3.next();
			if (j>=6){
				%>
				<span><input type="checkbox" id="<%=ff.getName()%>" name="<%=ff.getName()%>" title="<%=ff.getTitle()%>" /><%=ff.getTitle()%></span>
				<%
			}else{
				list.add(ff.getName());
		%>
				<span><input type="checkbox" id="<%=ff.getName()%>" name="<%=ff.getName()%>" title="<%=ff.getTitle()%>" checked="<%=checked%>" /><%=ff.getTitle()%></span>
		<%	
			}
			j++;
		}
	}else{
		while (ir3.hasNext()) {
			FormField ff = (FormField) ir3.next();
			list.add(ff.getName());
        %>
        <span><input type="checkbox" id="<%=ff.getName()%>" name="<%=ff.getName()%>" title="<%=ff.getTitle()%>" checked="<%=checked%>" /><%=ff.getTitle()%></span>
        <%  
        }
	}
	
}else{
	while (ir3.hasNext()) {
		FormField ff = (FormField) ir3.next();
	
		String checked = "";
		for (i=0; i<len; i++) {
			String fieldName = fields[i];
			if (fieldName.equals(ff.getName())) {
				checked = "checked";
				break;
			}
		}
		%>
		<span><input type="checkbox" id="<%=ff.getName()%>" name="<%=ff.getName()%>" title="<%=ff.getTitle()%>" <%=checked%> />&nbsp;<%=ff.getTitle()%></span>
		<%
    }
}
%>
	<span><input type="button" class="btn" value="确定" onclick="checkFields()" />&nbsp;&nbsp;&nbsp;&nbsp;<input type="button" class="btn" value="取消" onclick="cancel()" /></span>
    </div>
</div>

<div id="viewBox" class="" style="margin:0 auto;">
	<div class="view grid expGrid"></div>
</div>

<script type="text/javascript">
var Msg = {}; //declare this or modify line 1 of core.js
var gd;
var moduleCols;

$("#trigger").powerFloat({
	eventType: "click",
	targetMode: null,
	targetAttr: "src",
	// position: "1-4", // 显示于下方，默认上方
	container: $("#customContainer")
});

function checkField(obj) {
	if (obj.checked) {
		var isFound = false;
		// 检查是否已有含有此列，如果没有则添加
		$.each(gd.config.cols, function(n, c){
			if(c.name == obj.name) {
				isFound = true;
				return;
			}
		});
		if (!isFound) {
			gd.remove();
			$('#viewBox').html('');
			$('#viewBox').append('<div class="view grid expGrid"></div>');

			var a = JSON.parse("{\"field\":\"" + obj.name + "\", \"title\":\"" + obj.getAttribute("title") + "\", \"width\":150, \"name\":\"" + obj.getAttribute("name") + "\", \"link\":\"#\"}");
			moduleCols.push(a);
			
			macGrid('grid', moduleCols);

			setCols();
		}
	}
	else {
		// 检查是否已有含有此列，如果有则删除
		var k = -1;
		$.each(gd.config.cols, function(n, c){
			if(c.name == obj.name) {		
				k = n;
				return;
			}
		});
		
		if (k==-1)
			return;
		
		gd.remove();
		$('#viewBox').html('');
		$('#viewBox').append('<div class="view grid expGrid"></div>');
		
		moduleCols.splice(k, 1); //删除指定子对象，参数：开始位置,删除个数

		macGrid('grid', moduleCols);
		
		setCols();		
	}
}

function checkFields() {
	$("#targetBox").find("input").each(function(){
		var obj = $(this);
		if (obj.attr("checked")=="checked") {
			var isFound = false;
			// 检查是否已有含有此列，如果没有则添加
			$.each(gd.config.cols, function(n, c){
				if(c.name == obj.attr("name")) {
					isFound = true;
					return;
				}
			});
			if (!isFound) {
				gd.remove();
				$('#viewBox').html('');
				$('#viewBox').append('<div class="view grid expGrid"></div>');
	
				var a = JSON.parse("{\"field\":\"" + obj.attr("name") + "\", \"title\":\"" + obj.attr("title") + "\", \"width\":150, \"name\":\"" + obj.attr("name") + "\", \"link\":\"#\"}");
				moduleCols.push(a);
				
				macGrid('grid', moduleCols);
	
				//setCols();
			}
		}
		else {
			// 检查是否已有含有此列，如果有则删除
			var k = -1;
			$.each(gd.config.cols, function(n, c){
				if(c.name == obj.attr("name")) {		
					k = n;
					return;
				}
			});
			
			if (k==-1)
				return;
			
			gd.remove();
			$('#viewBox').html('');
			$('#viewBox').append('<div class="view grid expGrid"></div>');
			
			moduleCols.splice(k, 1); //删除指定子对象，参数：开始位置,删除个数
	
			macGrid('grid', moduleCols);
			
			//setCols();		
		}
	});
	setCols();
}
 
</script>
<%
JSONArray jsonAry = new JSONArray();
for (i=0; i<len; i++) {
	String fieldName = fields[i];
	String fieldNameRaw = fieldName;
	String title = "";
	if (fieldName.equals("cws_creator")) {
		title = "创建者";
	}
	else if (fieldName.equals("ID")) {
		title = "ID";
	}
	else if (fieldName.equals("cws_progress")) {
		title = "进度";
	}
	else if (fieldName.equals("flowId")) {
		title = "流程ID";
	}
	else if (fieldName.equals("cws_status")) {
		title = "状态";
	}
	else if (fieldName.equals("cws_flag")) {
		title = "冲抵状态";
	}
	else if (fieldName.equals("colOperate")) {
		title = "操作";
	}
	else {
		if (fieldName.startsWith("main:")) {
			String[] ary = StrUtil.split(fieldName, ":");
			if (ary.length > 1) {
				FormDb mainFormDb = fm.getFormDb(ary[1]);
				title = mainFormDb.getName() + "：" + mainFormDb.getFieldTitle(ary[2]);
			}
		}
		else if (fieldName.startsWith("other:")) {
			String[] ary = StrUtil.split(fieldName, ":");
			if (ary.length<5) {
				title = "<font color='red'>格式非法</font>";
			}
			else {
				FormDb otherFormDb = fm.getFormDb(ary[2]);
				if (ary.length>=5)
					title = otherFormDb.getName() + "：" + otherFormDb.getFieldTitle(ary[4]);
				
				if (ary.length>=8) {
					FormDb oFormDb = fm.getFormDb(ary[5]);
					title += "：" + oFormDb.getFieldTitle(ary[7]);
				}
			}
		}		
		else {
			title = fd.getFieldTitle(fieldName);
		}
	}

	// field: 'subject', title : 'Subject', width: 140
	JSONObject json = new JSONObject();
	// 因为:在jquery选择器中被使用，所以需换成#，当在setCols时，再替换回来
	fieldName = fieldName.replaceAll(":", "#");
	json.put("field", fieldName);
	json.put("title", title);
	json.put("width", StrUtil.toInt(fieldsWidth[i].equals("#")?"":fieldsWidth[i], 150));
	if (fieldsLink != null){
		   json.put("link", (fieldsLink[i]!=null && fieldsLink[i].equals(""))?"#":fieldsLink[i]);
	}else{
		json.put("link", "#");
	}
    jsonAry.put(json);
}
%>
<link href="../js/mac/css/default.css" type="text/css" rel="stylesheet" />
<script src="../js/mac/core.js"></script>
<script src="../js/mac/mousewheel.js"></script>
<script src="../js/mac/pager.js"></script>
<script src="../js/mac/grid.js"></script>
<script src="../js/json2.js"></script>
<script type="text/javascript">
moduleCols = <%=jsonAry%>;
$(function(){
	macGrid('grid', moduleCols);
	<%
	if (list != null){
		for(String name : list){
	%>
			checkField($('#<%=name%>')[0]);
	<%
	 	}
	}
	%>
});

function macGrid(gridName, moduleCols) {
	gd = $('.view');
	gd.mac('grid', {
		cols : moduleCols,
		loader: {
			url: '/javascript/grid/data.jsp',
			params: { pageNo: 1, pageSize: 50 },
			autoLoad: false
		},
		onMoveEnd: moveEnd,
		onResizeEnd: resizeEnd,
		pagerLength: 10
	});
}

function moveEnd(col1, col2) {
	// col2 被拖动的列, col2被拖动后替换的列
	setCols();
}

function resizeEnd(col) {
	setCols();
}

function setCols() {
	// alert(JSON.stringify(gd.config.cols));	
	$.ajax({
		type: "post",
		url: "<%=request.getContextPath()%>/visual/module_field_list.jsp",
		data: {
			op: "setCols",
			code: "<%=code%>",
			formCode: "<%=formCode%>",
			cols: JSON.stringify(gd.config.cols)
		},
		dataType: "html",
		beforeSend: function(XMLHttpRequest){
			//ShowLoading();
		},
		success: function(data, status){
			var re = $.parseJSON(data);
			if (re==null)
				re = data;
			if (re.ret=="1") {
				// alert(re.msg);
				// $.toaster({priority : 'info', message : re.msg });
               <%
               if(resource != null && resource.equals("nest")){
            	   
               }else{
               %>
				// window.location.reload();
				
				<%
               }
				%>
				$.powerFloat.hide();
			}		
			else {
				alert(re.msg);
			}
		},
		complete: function(XMLHttpRequest, status){
			//HideLoading();
		},
		error: function(){
			//请求出错处理
		}
	});	
}

function cancel() {
	$.powerFloat.hide();
}
</script>