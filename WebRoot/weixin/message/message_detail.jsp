<%@ page language="java" import="java.util.*" pageEncoding="utf-8" %>
<%@page import="cn.js.fan.util.ParamUtil" %>
<%@page import="com.redmoon.weixin.mgr.WXUserMgr" %>
<%@page import="com.redmoon.weixin.mgr.WXMessageMgr" %>
<%
    String path = request.getContextPath();
    String basePath = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + path + "/";
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
    <title>消息</title>
    <meta http-equiv="pragma" content="no-cache">
    <meta http-equiv="cache-control" content="no-cache">
    <meta name="viewport" content="width=device-width, initial-scale=1,maximum-scale=1,user-scalable=no">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta content="telephone=no" name="format-detection"/>
    <meta name="apple-mobile-web-app-status-bar-style" content="black">
    <link rel="stylesheet" href="../css/mui.css">
    <link rel="stylesheet" href="../css/my_dialog.css"/>
    <style type="text/css">
        .mui-badge-success {
            color: #fff;
            background-color: #4cd964;
            display: inline-block;
            font-size: 12px;
            border-radius: 100px;
            padding: 0px 10px;
            margin-left: 5px;
        }

        h5 {
            color: #000;
            font-weight: bold;
        }

        .content_p {
            margin: 20px 10px;
        }

        .detail {
            color: #000;

        }

        .hide_li {
            display: none;
        }

    </style>
</head>
<body>
<div class="mui-content">
    <div class="mui-content-padded">
        <ul class="mui-table-view">
            <li class="mui-table-view-cell outbox_li">
                <span class="mui-h5">发件人:</span>
                <span class="mui-pull-right mui-h5 detail" type="0">详情</span>
            </li>
            <li class="mui-table-view-cell inbox_li hide_li">
                <span class="mui-h5">收件人:</span>
            </li>
            <li class="mui-table-view-cell link_li hide_li">
                <a class="mui-navigate-right action-bar">
                    <span class="mui-h5 action-type"></span>
                    <span class="mui-h5 action-name"></span>
                    <span class="mui-icon mui-icon-paperplane" style="font-size:20px"></span>
                </a>
            </li>
        </ul>
        <p class="content_p">
        </p>
    </div>
</div>
<script type="text/javascript" src="../js/jquery-1.9.1.min.js"></script>
<script type="text/javascript" src="../css/mui.css"></script>
<script type="text/javascript" src="../js/mui.min.js"></script>
<script type="text/javascript" src="../js/mui.pullToRefresh.js"></script>
<script type="text/javascript" src="../js/mui.pullToRefresh.material.js"></script>
<script src="../js/jq_mydialog.js"></script>
<%
    long id = ParamUtil.getInt(request, "id", 0);
    String skey = ParamUtil.get(request, "skey");
%>
<script>
    function browser() {
        var u = navigator.userAgent;
        var isAndroid = u.indexOf('Android') > -1 || u.indexOf('Adr') > -1; //android终端
        var isiOS = !!u.match(/\(i[^;]+;( U;)? CPU.+Mac OS X/); //ios终端
        var ua = window.navigator.userAgent.toLowerCase();
        if (isAndroid) {
            return "android";
        } else if (isiOS) {
            return "ios";
        } else {
            return "pc";
        }
    }

    (function ($) {
        $.init({
            swipeBack: true //启用右滑关闭功能
        });
        var ajax_get = function (datas) {
            $.get("../../public/android/messages/getdetail", datas, function (data) {
                var content = data.content;
                var title = data.title;
                var createdate = data.createdate;
                var sender = data.sender;
                jQuery(".content_p").html(content);
                jQuery(".outbox_li").append('<span class="mui-badge-success">' + sender + '</span>');
                if ("notice" in data) {
                    var n = data.notice;
                    jQuery(".link_li .action-type").html("通知：");
                    jQuery(".link_li .action-name").html(n.name);
                    jQuery(".link_li").show();
                    // 调用prompt()，安卓打开新的activity，以便于后退
                    var url = "../notice/notice_detail.jsp?id=" + n.noticeId + "&skey=<%=skey%>";
                    if (browser() == "android") {
                        url = "weixin/notice/notice_detail.jsp?id=" + n.noticeId + "&skey=<%=skey%>";
                    }
                    jQuery(".link_li .action-bar").attr("url", url);
                } else if ("flow" in data) {
                    var f = data.flow;
                    jQuery(".link_li .action-type").html("流程：");
                    jQuery(".link_li .action-name").html(f.name);
                    jQuery(".link_li").show();
                    var url;
                    if ("myActionId" in f) {
                        url = "flow/flow_dispose.jsp?myActionId=" + f.myActionId + "&skey=<%=skey%>";
                    } else {
                        url = "flow/flow_attend_detail.jsp?flowId=" + f.flowId + "&skey=<%=skey%>";
                    }
                    if (browser() == "android") {
                        url = "weixin/" + url;
                    } else {
                        url = "../" + url;
                    }
                    jQuery(".link_li .action-bar").attr("url", url);
                }
                if ("receiver" in data) {
                    var receiver = data.receiver;
                    var receiver_arr = receiver.split(',');
                    $.each(receiver_arr, function (index, item) {
                        jQuery(".inbox_li").append('<span class="mui-badge-success">' + item + '</span>');
                    });
                }
                if (("cs" in data)) {
                    var cs = data.cs;
                    var cs_arr = cs.split(',');
                    var cs_li = ' <li class="mui-table-view-cell copy_to_li hide_li">'
                    cs_li += '<span class="mui-h5" >抄   &nbsp;&nbsp;送:</span>'
                    cs_li += '</li>';
                    jQuery("ul").append(cs_li);
                    $.each(cs_arr, function (index, item) {
                        jQuery(".copy_to_li").append('<span class="mui-badge-success">' + item + '</span>');
                    });
                }
                if (("ms" in data)) {
                    var ms = data.ms;
                    var ms_arr = ms.split(',');
                    var ms_li = ' <li class="mui-table-view-cell blind_copy_li hide_li">'
                    ms_li += '<span class="mui-h5" >密 &nbsp;&nbsp;送:</span>'
                    ms_li += '</li>';
                    jQuery("ul").append(ms_li);
                    $.each(ms_arr, function (index, item) {
                        jQuery(".blind_copy_li").append('<span class="mui-badge-success">' + item + '</span>');
                    });
                }
                if (("title" in data) && ("createdate" in data)) {
                    var $li_desc = ' <li class="mui-table-view-cell">';
                    $li_desc += '<h5 class="h_title">' + title + '</h5>';
                    $li_desc += '<h6 class="h_createdate">' + createdate + '</h6>';
                    $li_desc += '</li>';
                    jQuery("ul").append($li_desc);
                }
            }, "json");

        }
        $(".mui-table-view-cell").on("tap", '.detail', function () {
            var type = jQuery(this).attr("type");
            if (type == 0) {
                jQuery(".hide_li").hide();
                jQuery(this).attr("type", 1);
            } else {
                jQuery(".hide_li").show();
                jQuery(this).attr("type", 0);
            }
        });

        $(".mui-table-view-cell").on("tap", '.action-bar', function () {
            /*            if (browser() == "android") {
                            var result = prompt("js://webview?action=forward&param=" + jQuery(this).attr("url"));
                        }
                        else {
                            window.location.href = jQuery(this).attr("url");
                        }*/
            window.location.href = "<%=request.getContextPath()%>/" + jQuery(this).attr("url");
        });

        ajax_get({"skey": "<%=skey%>", "id":<%=id%>});
    })(mui);

    function callJS() {
        return {"btnBackShow": 1, "btnBackUrl": ""};
    }

    var iosCallJS = '{ "btnBackShow":1, "btnBackUrl":"" }';
</script>
<jsp:include page="../inc/navbar.jsp">
    <jsp:param name="skey" value="<%=skey%>"/>
    <jsp:param name="isBarBottomShow" value="false"/>
</jsp:include>
</body>
</html>
