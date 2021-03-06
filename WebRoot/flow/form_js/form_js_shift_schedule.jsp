<%@ page contentType="text/html; charset=utf-8" language="java" errorPage="" %>
<%@ page import = "com.cloudwebsoft.framework.db.*"%>
<%@ page import = "cn.js.fan.db.*"%>
<%@ page import = "cn.js.fan.util.*"%>
<%@ page import = "org.json.*"%>
<%@ page import = "com.redmoon.oa.flow.FormDb"%>
<%@ page import = "com.redmoon.oa.visual.*"%>
<%@ page import = "com.redmoon.oa.pvg.*"%>
<%@ page import = "com.redmoon.oa.kaoqin.*"%>
<%@ page import = "com.redmoon.oa.person.*"%>
<%
/*
- 功能描述：排班表
- 访问规则：
- 过程描述：
- 注意事项：
- 创建者：fgf
- 创建时间：2017-09-22
==================
- 修改者：
- 修改时间：
- 修改原因:
- 修改点:
*/
%>
$(function() {
<%
int id = ParamUtil.getInt(request, "id", -1);
if (id!=-1) {
	FormDb fd = new FormDb();
	fd = fd.getFormDb("shift_schedule");
	FormDAO fdao = new FormDAO();
	fdao = fdao.getFormDAO(id, fd);
	String repType = fdao.getFieldValue("repeat_type");
	if ("周".equals(repType)) {
	%>
		$('#tableMonth').hide();
	<%
	}
	else {
	%>
		$('#tableWeek').hide();
	<%
	}
}
%>

	if (o("repeat_type")==null) {
		return;
	}
	if (o("repeat_type").value=="周") {
		$('#tableMonth').hide();
		$('#tableWeek').show();
	}
	else {
		$('#tableWeek').hide();
		$('#tableMonth').show();		
	}
	
	$("select[name='repeat_type']").change(function() {
		if ($(this).val()=="周") {
			$('#tableWeek').show();
			$('#tableMonth').hide();
	    }
	    else {
			$('#tableWeek').hide();
			$('#tableMonth').show();
	    }
	});	
});