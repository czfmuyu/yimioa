<%@ page contentType="text/html;charset=utf-8" %>
<%@ page import="java.util.*" %>
<%@ page import="com.redmoon.oa.pvg.*" %>
<%@ page import="cn.js.fan.util.*" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="org.jdom.*" %>
<%@ page import="com.redmoon.oa.ui.*" %>
<%@ page import="cn.js.fan.web.SkinUtil" %>
<%@ page import="com.redmoon.dingding.*" %>
<%@ page import="org.json.JSONObject" %>
<%@ taglib uri="/WEB-INF/tlds/LabelTag.tld" prefix="lt" %>
<jsp:useBean id="fchar" scope="page" class="cn.js.fan.util.StrUtil"/>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>钉钉配置</title>
    <link type="text/css" rel="stylesheet" href="<%=SkinMgr.getSkinPath(request)%>/css.css"/>
    <script type="text/javascript" src="../inc/common.js"></script>
    <script src="../js/jquery.js"></script>
    <script src="../js/jquery-alerts/jquery.alerts.js" type="text/javascript"></script>
    <script src="../js/jquery-alerts/cws.alerts.js" type="text/javascript"></script>
    <link href="../js/jquery-alerts/jquery.alerts.css" rel="stylesheet" type="text/css" media="screen"/>

    <link href="../js/jquery-showLoading/showLoading.css" rel="stylesheet" media="screen" />
    <script type="text/javascript" src="../js/jquery-showLoading/jquery.showLoading.js"></script>
<body>
<jsp:useBean id="cfgparser" scope="page" class="cn.js.fan.util.CFGParser"/>
<jsp:useBean id="privilege" scope="page" class="com.redmoon.oa.pvg.Privilege"/>
<%
    if (!privilege.isUserPrivValid(request, PrivDb.PRIV_ADMIN)) {
        out.print(cn.js.fan.web.SkinUtil.makeErrMsg(request, cn.js.fan.web.SkinUtil.LoadString(request, "pvg_invalid")));
        return;
    }

    Config.reload();
    Config myconfig = Config.getInstance();
%>
<TABLE cellSpacing=0 cellPadding=0 width="100%">
    <TBODY>
    <TR>
        <TD class="tdStyle_1">钉钉配置</TD>
    </TR>
    </TBODY>
</TABLE>
<br>
<%
    Element root = myconfig.getRoot();

    String name = "", value = "";
    name = request.getParameter("name");
    if (name != null && !name.equals("")) {
        value = ParamUtil.get(request, "value");
        myconfig.setProperty(name, value);

        myconfig.reload();
        out.println(fchar.jAlert_Redirect(SkinUtil.LoadString(request, "info_op_success"), "提示", "config_dingding.jsp"));
        return;
    }
%>
<table width="100%" class="tabStyle_1 percent80" border="0" align="center" cellpadding="0" cellspacing="0">
    <tr>
        <td colspan="3" class="tabStyle_1_title">配置管理</td>
    </tr>
    <%
        int k = 0;
        Iterator ir = root.getChildren().iterator();
        String desc = "";
        while (ir.hasNext()) {
            Element e = (Element) ir.next();
            name = e.getName();
            if (name.equals("agentMenu"))
                continue;

            String isDisplay = StrUtil.getNullStr(e.getAttributeValue("isDisplay"));
            // System.out.println(getClass() + " name=" + name + " isDisplay=" + isDisplay);
            if (isDisplay.equals("false")) {
                continue;
            }

            value = e.getValue();
            desc = (String) e.getAttributeValue("desc");
    %>
    <form method="post" id="form<%=k%>" name="form<%=k%>" action='config_dingding.jsp'>
        <tr>
            <td width='52%'><input type="hidden" name="name" value="<%=name%>"/>
                &nbsp;<%=desc%>
            </td>
            <td width='34%'>
                <%if (!"isSyncDingDingToOA".equals(name) && (value.equals("true") || value.equals("false"))) {%>
                <select id="attr<%=k%>" name="value">
                    <option value="true">
                        <lt:Label key="yes"/>
                    </option>
                    <option value="false">
                        <lt:Label key="no"/>
                    </option>
                </select>
                <script>
                    $('#attr<%=k%>').val("<%=value%>");
                </script>
                <%
                }
                else {
                    String opts = StrUtil.getNullStr(e.getAttributeValue("options"));
                    if ("".equals(opts)) {
                %>
                <input type=text value="<%=value%>" name="value" size=30>
                <%
                } else {
                %>
                <select id="attr<%=k%>" name="value">
                    <%
                        String[] ary = StrUtil.split(opts, ",");
                        for (String item : ary) {
                            String[] aryOpts = StrUtil.split(item, "\\|");
                            if (aryOpts != null && aryOpts.length == 2) {
                    %>
                    <option value="<%=aryOpts[0]%>"><%=aryOpts[1]%>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
                <script>
                    $(function () {
                        $('#attr<%=k%>').val('<%=value%>');
                    })
                </script>
                <%
                        }
                    }
                %></td>
            <td width="14%" align="center"><input class="btn" type="submit" name='edit'
                                                  value='<lt:Label key="op_modify"/>'/>
            </td>
        </tr>
    </form>
    <%
            k++;
        }
    %>
        <tr>
          <td>从钉钉仅同步帐户至系统，只需在初始化时同步一次</td>
          <td colspan="2">
          <input id="btnSyn" type="button" value="同步" onclick="sync()" />
          </td>
        </tr>    
</table>
</body>
<script>
    function sync() {
        jConfirm('您确定要同步么？', '提示', function(r) {
            if (r) {
                $.ajax({
                    type: "post",
                    url: "sync_all_do.jsp",
                    contentType:"application/x-www-form-urlencoded; charset=iso8859-1",
                    data: {
                        op: "syncDing"
                    },
                    dataType: "html",
                    beforeSend: function(XMLHttpRequest){
                        $('body').showLoading();
                    },
                    success: function(data, status){
                        data = $.parseJSON(data);
                        jAlert(data.msg, "提示");
                    },
                    complete: function(XMLHttpRequest, status){
                        $('body').hideLoading();
                    },
                    error: function(XMLHttpRequest, textStatus){
                        // 请求出错处理
                        alert(XMLHttpRequest.responseText);
                    }
                });
            }
        });
    }
</script>
</html>