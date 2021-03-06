package com.redmoon.oa.util;

import java.util.Hashtable;
import java.util.Iterator;
import java.util.Vector;

import cn.js.fan.util.StrUtil;

import com.redmoon.kit.util.FileUpload;
import com.redmoon.oa.base.IFormDAO;
import com.redmoon.oa.flow.FormField;
import com.redmoon.oa.flow.macroctl.MacroCtlMgr;
import com.redmoon.oa.flow.macroctl.MacroCtlUnit;

import bsh.EvalError;
import bsh.Interpreter;

public class BeanShellUtil {

	public static String escape(String str) {
		// 替换换行符
		str = str.replaceAll("\\r\\n", "\\\\r\\\\n");
		
		// ie10
		str = str.replaceAll("\\n", "\\\\n");
		
		// str = str.replaceAll("abstract=", "abstractC=");
		return str.replaceAll("\\r", "\\\\r");
	}
	
	/**
	 * 给FileUpload赋值，用于runValidateScript测试
	 * @Description: 
	 * @param fdao
	 * @param fu
	 */
	public static void setFieldsValue(IFormDAO fdao, FileUpload fu) {
		fu.setFields(new Hashtable());
		Iterator ir = fdao.getFields().iterator();
        // @task:fields中可能有重复的域
        while (ir.hasNext()) {
            FormField ff = (FormField) ir.next();            
            String val;
            if (!ff.getMacroType().equals(FormField.MACRO_NOT)) {
                MacroCtlMgr mm = new MacroCtlMgr();
                MacroCtlUnit mu = mm.getMacroCtlUnit(ff.getMacroType());
                if (mu == null)
                    throw new IllegalArgumentException("Macro ctl type=" +
                            ff.getMacroType() +
                            " is not exist.");
                String typeStr = mu.getFieldType();
                if (typeStr.equalsIgnoreCase("double") ||
                    typeStr.equalsIgnoreCase("float") ||
                    typeStr.equalsIgnoreCase("number") ||
                    typeStr.equalsIgnoreCase("bigint") ||
                    typeStr.equalsIgnoreCase("int")) {
                    val = fdao.getFieldValue(ff.getName());
                } else {
                	val = fdao.getFieldValue(ff.getName());
                	val = val.replaceAll("\"", "\\\\\"");
                }
            } else {
                int fType = ff.getFieldType();
                if (fType == FormField.FIELD_TYPE_INT) {
                    int v = StrUtil.toInt(fdao.getFieldValue(ff.getName()),
                                          -65536);
                    if (v == -65536) {
                        val = "-65536";
                    } else
                        val = fdao.getFieldValue(ff.getName());
                } else if (fType == FormField.FIELD_TYPE_DOUBLE ||
                           fType == FormField.FIELD_TYPE_FLOAT ||
                           fType == FormField.FIELD_TYPE_LONG ||
                           fType == FormField.FIELD_TYPE_PRICE) {
                    double v = StrUtil.toDouble(fdao.getFieldValue(ff.getName()),
                                                -65536);
                    if (v == -65536) {
                        // LogUtil.getLog(getClass()).info(ff.getName() + "=" + fdao.getFieldValue(ff.getName()) + " v=" + v);
                        val = "-65536";
                    } else
                        val = fdao.getFieldValue(ff.getName());
                } else {
                	val = fdao.getFieldValue(ff.getName());
                	val = val.replaceAll("\"", "\\\\\"");                	
                }
            }
            fu.setFieldValue(ff.getName(), val);
        }				
	}
	
	/**
	 * 给流程表单域赋值
	 * @param fields
	 * @param fdao
	 * @param sb
	 */
	public static void setFieldsValue(IFormDAO fdao, StringBuffer sb) {
		Iterator ir = fdao.getFields().iterator();
        // @task:fields中可能有重复的域
        while (ir.hasNext()) {
            FormField ff = (FormField) ir.next();
            if (!ff.getMacroType().equals(FormField.MACRO_NOT)) {
                MacroCtlMgr mm = new MacroCtlMgr();
                MacroCtlUnit mu = mm.getMacroCtlUnit(ff.getMacroType());
                if (mu == null) {
                    throw new IllegalArgumentException("Macro ctl " + ff.getTitle() + " type=" +
                            ff.getMacroType() +
                            " is not exist.");
                }
                String typeStr = mu.getFieldType();
                if (typeStr.equalsIgnoreCase("double") ||
                    typeStr.equalsIgnoreCase("float") ||
                    typeStr.equalsIgnoreCase("number") ||
                    typeStr.equalsIgnoreCase("bigint") ||
                    typeStr.equalsIgnoreCase("int")) {
                    sb.append("$" + ff.getName() + "=" +
                              fdao.getFieldValue(ff.getName()) +
                              ";");
                } else {
                	String val = fdao.getFieldValue(ff.getName());
                	val = val.replaceAll("\"", "\\\\\"");
                    sb.append("$" + ff.getName() + "=\"" +
                              val +
                              "\";");
                }
            } else {
                int fType = ff.getFieldType();
                if (fType == FormField.FIELD_TYPE_INT) {
                    int v = StrUtil.toInt(fdao.getFieldValue(ff.getName()),
                                          -65536);
                    if (v == -65536) {
                        sb.append("$" + ff.getName() + "=-65536;");
                    } else
                        sb.append("$" + ff.getName() + "=" +
                                  fdao.getFieldValue(ff.getName()) +
                                  ";");
                } else if (fType == FormField.FIELD_TYPE_DOUBLE ||
                           fType == FormField.FIELD_TYPE_FLOAT ||
                           fType == FormField.FIELD_TYPE_LONG ||
                           fType == FormField.FIELD_TYPE_PRICE) {
                    double v = StrUtil.toDouble(fdao.getFieldValue(ff.getName()),
                                                -65536);
                    if (v == -65536) {
                        // LogUtil.getLog(getClass()).info(ff.getName() + "=" + fdao.getFieldValue(ff.getName()) + " v=" + v);
                        sb.append("$" + ff.getName() + "=-65536;");
                    } else
                        sb.append("$" + ff.getName() + "=" +
                                  fdao.getFieldValue(ff.getName()) +
                                  ";");
                } else {
                	String val = fdao.getFieldValue(ff.getName());
                	val = val.replaceAll("\"", "\\\\\"");                	
                    sb.append("$" + ff.getName() + "=\"" +
                              val +
                              "\";");
                }
            }
        }		
	}
	
	public static void main(String[] args) {
		String str22 = "String str = \"it is\r\n goto\";";
		
		str22 += "System.out.println(str);";
		
		str22 = str22.replaceAll("\\r\\n", "\\\\r\\\\n");
		// System.out.println(str);
		str22 += "System.out.println(str);";
		
		str22 = "date=\"2014-01-10\";fkfs=\"\";sgdh=\"\";clxqb=\"\";hjryj=\"\";picker=\"admin\";ysbspyj=\"\";cgjlspyj=\"\";cwbfzrsp=\"\";add_button=\"\";contact_no=\"\";project_name=\"5\";provide_name=\"1\";contact_money=\"\";manager_comment=\"11          管理员   2014-01-10 13:47:48\";project_comment=\"\";flowId=6460;";

        Interpreter bsh = new Interpreter();
        try {
			bsh.eval(str22);
		} catch (EvalError e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}
