<%@ page contentType="text/html; charset=utf-8" language="java" import="java.sql.*" errorPage="" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.util.*" %>
<%@ page import="cn.js.fan.db.*" %>
<%@ page import="cn.js.fan.util.*" %>
<%@ page import="cn.js.fan.web.*" %>
<%@ page import="com.redmoon.forum.person.*" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title></title>
<LINK href="default.css" type=text/css rel=stylesheet>
<script>
function form1_onsubmit() {
	form1.type.value = form1.seltype.value;
	form1.root_code.value = window.parent.dirmainFrame.getRootCode();
}

function selTemplate(id)
{
	if (form1.templateId.value!=id) {
		form1.templateId.value = id;
	}
}

function enableSelType() {
	if (confirm("如果该项中已经含有内容，则更改以后会造成问题，您要强制更改吗？")) {
		form1.seltype.disabled = false;
	}
}
</script>
</head>
<body>
<jsp:useBean id="privilege" scope="page" class="com.redmoon.forum.Privilege"/>
<%
if (!privilege.isMasterLogin(request))
{
	out.println(StrUtil.makeErrMsg(SkinUtil.LoadString(request, "pvg_invalid")));
	return;
}
%>
<%
String parent_code = ParamUtil.get(request, "parent_code");
if (parent_code.equals(""))
	parent_code = "root";
String parent_name = ParamUtil.get(request, "parent_name");
String code = ParamUtil.get(request, "code");
String name = ParamUtil.get(request, "name");
String description = ParamUtil.get(request, "description");
String op = ParamUtil.get(request, "op");

com.redmoon.oa.pvg.Privilege pvg = new com.redmoon.oa.pvg.Privilege();	
try {
	com.redmoon.oa.security.SecurityUtil.antiXSS(request, pvg, "parent_name", parent_name, getClass().getName());
}
catch (ErrMsgException e) {
	out.print(cn.js.fan.web.SkinUtil.makeErrMsg(request, e.getMessage()));
	return;
}
try {
	com.redmoon.oa.security.SecurityUtil.antiXSS(request, pvg, "parent_code", parent_code, getClass().getName());
}
catch (ErrMsgException e) {
	out.print(cn.js.fan.web.SkinUtil.makeErrMsg(request, e.getMessage()));
	return;
}
try {
	com.redmoon.oa.security.SecurityUtil.antiXSS(request, pvg, "op", op, getClass().getName());
}
catch (ErrMsgException e) {
	out.print(cn.js.fan.web.SkinUtil.makeErrMsg(request, e.getMessage()));
	return;
}

boolean isHome = false;
int type = 0;
if (op.equals(""))
	op = "AddChild";

FactionDb leaf = null;
if (op.equals("modify")) {

	FactionMgr dir = new FactionMgr();
	leaf = dir.getFactionDb(code);
	name = leaf.getName();
	description = leaf.getDescription();
	type = leaf.getType();
	isHome = leaf.getIsHome();
}
%>
<TABLE style="BORDER-RIGHT: #a6a398 1px solid; BORDER-TOP: #a6a398 1px solid; BORDER-LEFT: #a6a398 1px solid; BORDER-BOTTOM: #a6a398 1px solid" 
cellSpacing=0 cellPadding=3 width="95%" align=center>
  <!-- Table Head Start-->
  <TBODY>
    <TR>
      <TD class=thead style="PADDING-LEFT: 10px" noWrap width="70%">目录增加或修改</TD>
    </TR>
    <TR class=row style="BACKGROUND-COLOR: #fafafa">
      <TD align="center" style="PADDING-LEFT: 10px"><table class="frame_gray" width="415" border="0" cellpadding="0" cellspacing="1">
        <tr>
          <td width="411" align="center"><table width="98%">
            <form name="form1" method="post" action="faction_top.jsp?op=<%=op%>" target="dirmainFrame" onClick="return form1_onsubmit()">
              <tr>
                <td width="78" rowspan="7" align="left" valign="top"><br>
                  当前结点：<br>
                    <font color=blue><%=parent_name.equals("")?"根结点":parent_name%></font>					</td>
                <td width="312" align="left"> 编码
                    <input name="code" value="<%=code%>" <%=op.equals("modify")?"readonly":""%>>                </td>
              </tr>
              <tr>
                <td align="left">名称
                    <input name="name" value="<%=name%>"></td>
              </tr>
              <tr>
                <td align="left">描述
                    <input name="description" value="<%=description%>">
                    <input type=hidden name=parent_code value="<%=parent_code%>">                    </td>
              </tr>
              <tr>
                <td align="left">
				  <input type=hidden name=seltype value="0">
				  <input type=hidden name=root_code value="">
				  <input type=hidden name="type" value="<%=type%>"></td>
              </tr>
              <tr>
                <td align="left"><span class="unnamed2">
                  <%if (op.equals("modify")) {%>
<%if (leaf.getCode().equals(FactionDb.CODE_ROOT)) {%>
	<input type="hidden" name="parentCode" value="-1">
<%}else{%>
&nbsp;父结点：<select name="parentCode">
<%
				FactionDb rootlf = leaf.getFactionDb("root");
				FactionView dv = new FactionView(rootlf);
				dv.ShowDirectoryAsOptionsWithCode(out, rootlf, rootlf.getLayer());
%>
</select>
<script>
form1.parentCode.value = "<%=leaf.getParentCode()%>";
</script>
<%}
}%>
                <input type="hidden" name="isHome" value="true">
				<input name="templateId" type="hidden" value="-1">
                </span></td>
              </tr>
              <tr>
                <td align="center"><input name="Submit" type="submit" class="singleboarder" value="提交">
                  &nbsp;&nbsp;&nbsp;
                  <input name="Submit" type="reset" class="singleboarder" value="重置"></td>
              </tr>
            </form>
          </table></td>
        </tr>
      </table>
      </TD>
    </TR>
    <!-- Table Body End -->
    <!-- Table Foot -->
    <TR>
      <TD class=tfoot align=right><DIV align=right> </DIV></TD>
    </TR>
    <!-- Table Foot -->
  </TBODY>
</TABLE>
</body>
</html>
