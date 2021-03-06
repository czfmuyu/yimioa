<%@ page contentType="text/html; charset=utf-8"%>
<%@ page import="java.io.*"%>
<%@ page import="cn.js.fan.db.*"%>
<%@ page import="java.util.*"%>
<%@ page import="cn.js.fan.web.*"%>
<%@ page import="cn.js.fan.util.*"%>
<%@ page import="cn.js.fan.security.*"%>
<%@ page import="com.redmoon.oa.*"%>
<%@ page import="com.redmoon.oa.person.*"%>
<%@ page import="com.redmoon.oa.visual.*"%>
<%@ page import="com.redmoon.oa.flow.FormDb"%>
<%@ page import="com.redmoon.oa.flow.FormField"%>
<%@ page import="com.redmoon.oa.flow.macroctl.*"%>
<%@ page import="jxl.*"%>
<%@ page import="jxl.write.*"%>
<%@ page import="org.json.*"%>
<%@ page import="com.cloudwebsoft.framework.db.JdbcTemplate"%>
<%@ page import="jxl.format.UnderlineStyle"%>
<%@ page import="jxl.biff.DisplayFormat"%>
<%@ page import="java.awt.Color"%>
<%@ page import="com.redmoon.oa.util.RequestUtil" %>
<jsp:useBean id="privilege" scope="page" class="com.redmoon.oa.pvg.Privilege"/><%
	// 未使用模板导出，即默认导出时，将合并嵌套表的单元格
	String priv="read";
	if (!privilege.isUserPrivValid(request,priv)){
		out.println(cn.js.fan.web.SkinUtil.makeErrMsg(request, cn.js.fan.web.SkinUtil.LoadString(request, "pvg_invalid")));
		return;
	}

	String code = ParamUtil.get(request, "code");
	if ("".equals(code)) {
		code = ParamUtil.get(request, "formCode");
	}
	ModuleSetupDb msd = new ModuleSetupDb();
	msd = msd.getModuleSetupDb(code);
	if (msd==null) {
		out.print(cn.js.fan.web.SkinUtil.makeErrMsg(request, "模块不存在！"));
		return;
	}

	long templateId = ParamUtil.getLong(request, "templateId", -1);

	request.setAttribute(ModuleUtil.MODULE_SETUP, msd);

	String formCode = msd.getString("form_code");

	FormDb fd = new FormDb();
	fd = fd.getFormDb(formCode);
	if (!fd.isLoaded()) {
		out.println(cn.js.fan.web.SkinUtil.makeErrMsg(request, "表单不存在！"));
		return;
	}
	String op = ParamUtil.get(request, "op");
	String orderBy = ParamUtil.get(request, "orderBy");
	if (orderBy.equals(""))
		orderBy = "id";
	String sort = ParamUtil.get(request, "sort");
	if (sort.equals(""))
		sort = "desc";

	String[] ary = null;
	boolean isMine = ParamUtil.get(request, "isMine").equals("true");
	if (isMine) {
		ary = SQLBuilder.getModuleListSqlAndUrlStr(request, fd, op, orderBy, sort, privilege.getUser(request), "user_name");
	}
	else
		ary = SQLBuilder.getModuleListSqlAndUrlStr(request, fd, op, orderBy, sort);
	String sql = ary[0];
// System.out.println("sql = " + sql);
	String sqlUrlStr = ary[1];

	FormDAO fdao = new FormDAO();
	Vector v = fdao.list(formCode, sql);

	String listField = StrUtil.getNullStr(msd.getString("list_field"));
	String cols = ParamUtil.get(request, "cols");
	if (!"".equals(cols)) {
		listField = cols;
	}
	String[] fields = StrUtil.split(listField, ",");

// 是否导出全部字段
	boolean isAll = ParamUtil.getBoolean(request, "isAll", false);
// 主表字段与嵌套表formCode对应关系
	HashMap<String, String> nestMapping = new HashMap<String, String>();
// 嵌套表需显示的字段
	HashMap<String, String> nestFieldName = new HashMap<String, String>();
// 嵌套表需显示的字段的对应名称
	HashMap<String, String[]> nestFields = new HashMap<String, String[]>();
// 嵌套表的id数据集
	HashMap<String, Vector> nestData = new HashMap<String, Vector>();
// 列宽
	HashMap<Integer, Integer> columnWidthMap = new HashMap<Integer, Integer>();
// 所有嵌套表formCode
	ArrayList<String> list = new ArrayList<String>();
// isAll = true;
	if (true) {
		Vector vt = fd.getFields();
		Iterator ir = vt.iterator();
		while (ir.hasNext()) {
			FormField ff = (FormField)ir.next();
			// 当默认未用模板时，如果嵌套表不显示，则使得list为空，否则会导致表头两行合并为一行，如果嵌套表中有数据，也会出现多行合并为一行的情况
			if (templateId==-1) {
				boolean isShow = false;
				for (String field : fields) {
					if (field.endsWith(ff.getName())) {
						isShow = true;
						break;
					}
				}
				if (!isShow) {
					continue;
				}
			}
			if (ff.getMacroType().equals("nest_table") || ff.getMacroType().equals("nest_sheet")) {
				String nestFormCode = ff.getDescription();
				try {
					String defaultVal = StrUtil.decodeJSON(ff.getDescription());
					JSONObject json = new JSONObject(defaultVal);
					nestFormCode = json.getString("destForm");
				} catch (JSONException e) {
					out.println(e.toString());
				}
				nestMapping.put(ff.getName(), nestFormCode);
				list.add(nestFormCode);
			}
		}
	}

	MacroCtlMgr mm = new MacroCtlMgr();
	String fileName = fd.getName();

	ModuleExportTemplateDb metd = new ModuleExportTemplateDb();
	if (templateId!=-1) {
		metd = metd.getModuleExportTemplateDb(templateId);
		fileName = metd.getString("name");
	}

	response.setContentType("application/vnd.ms-excel");
	response.setHeader("Content-disposition","attachment; filename=" + StrUtil.GBToUnicode(fileName) + ".xls");
// response.setHeader("Content-disposition","attachment; filename=" + fd.getName() + ".xls");
	OutputStream os = response.getOutputStream();

	try {
		File file = new File(Global.getAppPath() + "visual/template/blank.xls");
		Workbook wb = Workbook.getWorkbook(file);
		WorkbookSettings settings = new WorkbookSettings ();
		settings.setWriteAccess(null);

		UserMgr um = new UserMgr();
		Map map = new HashMap();

		// 打开一个文件的副本，并且指定数据写回到原文件
		WritableWorkbook wwb = Workbook.createWorkbook(os, wb, settings);
		WritableSheet ws = wwb.getSheet(0);

		for (String ntCode : list) {
			ModuleSetupDb nestmsd = new ModuleSetupDb();
			nestmsd = nestmsd.getModuleSetupDbOrInit(ntCode);

			FormDb ntfd = new FormDb();
			ntfd = ntfd.getFormDb(ntCode);

			String ntlistField = StrUtil.getNullStr(nestmsd.getString("list_field"));

			String[] ntfields = StrUtil.split(ntlistField, ",");
			String[] ntfiledsName = new String[ntfields.length];

			Vector ntvt = ntfd.getFields();

			if (ntvt.size() == 0) {
				continue;
			}

			Iterator ntir = ntvt.iterator();
			while (ntir.hasNext()) {
				FormField ff = (FormField) ntir.next();
				for (int i = 0; i < ntfields.length; i++) {
					if (ff.getName().equals(ntfields[i])) {
						ntfiledsName[i] = ff.getTitle();
						continue;
					}
				}
			}
			nestFields.put(ntCode, ntfiledsName);
			nestFieldName.put(ntCode, ntlistField);
		}

		int len = 0;
		if (fields != null)
			len = fields.length;
		int index = 0;

		/*
		 * WritableFont.createFont("宋体")：设置字体为宋体
		 * 10：设置字体大小
		 * WritableFont.NO_BOLD:设置字体非加粗（BOLD：加粗     NO_BOLD：不加粗）
		 * false：设置非斜体
		 * UnderlineStyle.NO_UNDERLINE：没有下划线
		 */

		boolean isBar = false;
		int rowHeader = 0;
		Map mapWidth = new HashMap();
		WritableFont font;
		String backColor = "", foreColor = "";
		if (templateId!=-1) {
			String barName = StrUtil.getNullStr(metd.getString("bar_name"));
			if (!"".equals(barName)) {
				isBar = true;
			}

			String fontFamily = metd.getString("font_family");
			int fontSize = metd.getInt("font_size");
			backColor = metd.getString("back_color");
			foreColor = metd.getString("fore_color");
			boolean isBold = metd.getInt("is_bold") == 1;
			if (isBold) {
				font = new WritableFont(WritableFont.createFont(fontFamily),
						fontSize,
						WritableFont.BOLD);
			}
			else {
				font = new WritableFont(WritableFont.createFont(fontFamily),
						fontSize,
						WritableFont.NO_BOLD);
			}

			if (!"".equals(foreColor)) {
				Color color = Color.decode(foreColor); // 自定义的颜色
				wwb.setColourRGB(Colour.BLUE, color.getRed(), color.getGreen(), color.getBlue());
				font.setColour(Colour.BLUE);
			}

			String columns = metd.getString("cols");
			// 第一列的序号
			boolean isSerialNo = metd.getString("is_serial_no").equals("1");
			if (isSerialNo) {
				columns = columns.substring(1); // [{}, {},...]去掉[
				columns = "[{\"field\":\"serialNoForExp\",\"title\":\"序号\",\"link\":\"#\",\"width\":80,\"name\":\"serialNoForExp\"}," + columns;
			}

			JSONArray arr = new JSONArray(columns);
			StringBuffer colsSb = new StringBuffer();
			for (int i=0; i<arr.length(); i++) {
				JSONObject json = arr.getJSONObject(i);

				// System.out.println(getClass() + " " + i + " " + json.getInt("width"));
				ws.setColumnView(i, (int)(json.getInt("width") * 0.09 * 0.94)); // 设置列的宽度 ，单位是自己根据实际的像素值推算出来的

				StrUtil.concat(colsSb, ",", json.getString("field"));
				mapWidth.put(json.getString("field"), json.getInt("width"));
			}

			listField = colsSb.toString();
			fields = StrUtil.split(listField, ",");
			len = fields.length;


			if (isBar) {
				WritableFont barFont;
				String barBackColor = metd.getString("bar_back_color");
				String barForeColor = metd.getString("bar_fore_color");
				String barFontFamily = metd.getString("bar_font_family");
				int barFontSize = metd.getInt("bar_font_size");
				boolean isBarbBold = metd.getInt("bar_is_bold")==1;
				if (isBarbBold) {
					barFont = new WritableFont(WritableFont.createFont(barFontFamily),
							barFontSize,
							WritableFont.BOLD);
				}
				else {
					barFont = new WritableFont(WritableFont.createFont(barFontFamily),
							barFontSize,
							WritableFont.NO_BOLD);
				}

				if (!"".equals(barForeColor)) {
					Color color = Color.decode(barForeColor); // 自定义的颜色
					wwb.setColourRGB(Colour.RED, color.getRed(), color.getGreen(), color.getBlue());
					barFont.setColour(Colour.RED);
				}

				WritableCellFormat barFormat = new WritableCellFormat(barFont);
				// 水平居中对齐
				barFormat.setAlignment(Alignment.CENTRE);
				// 竖直方向居中对齐
				barFormat.setVerticalAlignment(VerticalAlignment.CENTRE);
				barFormat.setBorder(Border.ALL, BorderLineStyle.THIN);

				if (!"".equals(barBackColor)) {
					Color bClr = Color.decode(barBackColor); // 自定义的颜色
					wwb.setColourRGB(Colour.GREEN, bClr.getRed(), bClr.getGreen(), bClr.getBlue());
					barFormat.setBackground(Colour.GREEN);
				}

				Label a = new Label(0, 0, barName, barFormat);
				ws.addCell(a);

				ws.mergeCells(0, 0, len-1, 0);

				ws.setRowView(0, metd.getInt("bar_line_height") * 10); // 设置行的高度 ，setRowView(row, 200) 在excel中的实际高度为10像素

				rowHeader = 1;
			}
			ws.setRowView(rowHeader, metd.getInt("line_height") * 10); // 设置行的高度 ，setRowView(row, 200) 在excel中的实际高度为10像素
		}
		else {
			font = new WritableFont(WritableFont.createFont("宋体"),
					12,
					WritableFont.BOLD);
		}

		WritableCellFormat wcFormat = new WritableCellFormat(font);
		//水平居中对齐
		wcFormat.setAlignment(Alignment.CENTRE);
		//竖直方向居中对齐
		wcFormat.setVerticalAlignment(VerticalAlignment.CENTRE);
		wcFormat.setBorder(Border.ALL, BorderLineStyle.THIN);

		if (templateId!=-1) {
			if (!"".equals(backColor)) {
				Color color = Color.decode(backColor); // 自定义的颜色
				wwb.setColourRGB(Colour.ORANGE, color.getRed(), color.getGreen(), color.getBlue());
				wcFormat.setBackground(Colour.ORANGE);
			}
		}

		for (int i = 0; i < len; i++) {
			String fieldName = fields[i];
			String title = "";
			if (fieldName.equals("serialNoForExp")) {
				title = "序号";
			}
			else if (fieldName.startsWith("main:")) {
				String[] mainToSub = StrUtil.split(fieldName, ":");
				if (mainToSub != null && mainToSub.length == 3) {
					FormDb ntfd = new FormDb();
					ntfd = ntfd.getFormDb(mainToSub[1]);
					FormDAO ntfdao = new FormDAO(ntfd);
					FormField ff = ntfdao.getFormField(mainToSub[2]);
					title = ff.getTitle();
					if (!list.contains(mainToSub[1])) {
						list.add(mainToSub[1]);
					}
				} else {
					title = fieldName;
				}
			}
			else if (fieldName.startsWith("other:")) {
				String[] otherFields = StrUtil.split(fieldName, ":");
				if (otherFields.length == 5) {
					FormDb otherFormDb = new FormDb(otherFields[2]);
					title = otherFormDb.getFieldTitle(otherFields[4]);
				}
			}
			else if (fieldName.equals("cws_creator")) {
				title = "创建者";
			}
			else if (fieldName.equalsIgnoreCase("ID") || fieldName.equalsIgnoreCase("CWS_MID")) {
				title = "ID";
			}
			else if (fieldName.equals("cws_status")) {
				title = "状态";
			}
			else if (fieldName.equals("cws_flag")) {
				title = "冲抵状态";
			}
			else {
				title = fd.getFieldTitle(fieldName);
			}

			//判断是不是嵌套表，如果是嵌套表就需要显示嵌套表这个字段
			if(!nestMapping.containsKey(fieldName)){
				Label a = new Label(i + index, rowHeader, title, wcFormat);
				ws.addCell(a);
			}
			else {
				Label a = new Label(i + index, 0, title, wcFormat);
				ws.addCell(a);			
			}

			// 加粗+4
			columnWidthMap.put(i + index, title.getBytes().length + 4);
			if (fieldName.equals("cws_creator")) {
				ws.mergeCells(i + index, 0, i + index, list.isEmpty() ? 0 : 1);
			}
			else if (fieldName.equals("cws_flag")) {
				ws.mergeCells(i + index, 0, i + index, list.isEmpty() ? 0 : 1);
			}
			else if (fieldName.startsWith("main:")) {
				ws.mergeCells(i + index, 0, i + index, list.isEmpty() ? 0 : 1);
			} else if (fieldName.startsWith("other:")) {
				ws.mergeCells(i + index, 0, i + index, list.isEmpty() ? 0 : 1);
			}
			else if (fieldName.equalsIgnoreCase("CWS_MID")) {
				ws.mergeCells(i + index, 0, i + index, list.isEmpty() ? 0 : 1);
			}
			else {
				FormField myFf = fd.getFormField(fieldName);
				if (myFf==null) {
					fieldName = null;
				}
				else {
					fieldName = nestMapping.get(myFf.getName());
				}
				if (fieldName == null) { // && !nestFields.containsKey(fieldName)) {
					if (templateId==-1) {
						ws.mergeCells(i + index, 0, i + index, list.isEmpty() ? 0 : 1);
					}
				} else {
					String[] ntFields = nestFields.get(fieldName);
					// System.out.println("fieldName=" + fieldName + " " + ntFields);
					if (templateId==-1) {
						ws.mergeCells(i + index, 0, i + index + ntFields.length - 1, 0);
					}

					for (int j = 0; j < ntFields.length; j++) {
						columnWidthMap.put(i + index, ntFields[j].getBytes().length + 4);
						if (j < ntFields.length - 1) {
							index++;
						}
						if (templateId==-1) {
							Label b = new Label(i + j, 1, ntFields[j], wcFormat);
							ws.addCell(b);						
						}
						else {
							Label b = new Label(i + j, rowHeader, ntFields[j], wcFormat);
							ws.addCell(b);
						}
					}
				}
			}
		}

		Iterator ir = v.iterator();

		// int j = list.isEmpty() ? 0 : 1;
		int j = rowHeader + 1;
		int group = 0;
		int serialNo = 0;

		while (ir.hasNext()) {
			index = 0;
			fdao = (FormDAO)ir.next();

			// 置SQL宏控件中需要用到的fdao
			RequestUtil.setFormDAO(request, fdao);

			long fid = fdao.getId();
			int maxCount = 1;

			if (templateId!=-1) {
				ws.setRowView(j, metd.getInt("line_height") * 10); // 设置行的高度 ，setRowView(row, 200) 在excel中的实际高度为10像素
			}

			for (String ntCode : list) {
				//String ntsql = "select " + nestFieldName.get(ntCode) + " from form_table_" + ntCode + " where cws_id=" + fid;
				String ntsql = "select id from form_table_" + ntCode + " where cws_id=" + fid;
				JdbcTemplate jt = new JdbcTemplate();
				ResultIterator ri = jt.executeQuery(ntsql);
				nestData.put(ntCode, ri.getResult());

				if (ri.getRows() > maxCount) {
					maxCount = ri.getRows();
				}
			}

			for (int i = 0; i < len; i++) {
				boolean isSingle = true;
				String fieldName = fields[i];
				String fieldValue = "";
				if (fieldName.equals("serialNoForExp")) {
					fieldValue = String.valueOf(++serialNo);
				}
				else if (fieldName.startsWith("main:")) {
					isSingle = false;
					String[] mainToSub = StrUtil.split(fieldName, ":");
					if (mainToSub != null && mainToSub.length == 3) {
						Vector riData = nestData.get(mainToSub[1]);
						if (riData != null) {
							int rowInc = 0;
							Iterator it = riData.iterator();
							while (it.hasNext()) {
								Vector rrv = (Vector) it.next();
								long ntid = StrUtil.toLong(rrv.get(0).toString(), 0);
								FormDb ntfd = new FormDb(mainToSub[1]);
								FormDAO ntfdao = new FormDAO(ntid, ntfd);

								if (ntfdao != null && ntfdao.isLoaded()) {
									// 单元格宽度
									int width = columnWidthMap.get(i + index);
									String content = ntfdao.getFieldValue(mainToSub[2]);
									FormField ntff = ntfdao.getFormField(mainToSub[2]);
									if (content != null && content.getBytes().length > width) {
										columnWidthMap.put(i + index, content.getBytes().length);
									}

									// 保存格式
									int fieldType = FormField.FIELD_TYPE_TEXT;
									if (ntff != null) {
										fieldType = ntff.getFieldType();
									}
									wcFormat = setCellFormat(fieldType, group, map);

									// 设置列格式
									WritableCell wc = createWritableCell(fieldType, i + index, j + rowInc, content, wcFormat);
									ws.addCell(wc);
									rowInc++;
								}
							}
							// 将没有值的单元格补色
							for (int m = rowInc; m < maxCount; m++) {
								wcFormat = setCellFormat(FormField.FIELD_TYPE_TEXT, group, map);
								Label a = new Label(i + index, j + m, "", wcFormat);
								ws.addCell(a);
							}
						}
					}
				}
				else if (fieldName.startsWith("other:")) {
					fieldValue = com.redmoon.oa.visual.FormDAOMgr.getFieldValueOfOther(request, fdao, fieldName);
				}
				else if (fieldName.equalsIgnoreCase("ID") || fieldName.equalsIgnoreCase("CWS_MID")) {
					fieldValue = String.valueOf(fdao.getId());
				}
				else if (fieldName.equals("cws_flag")) {
					fieldValue = String.valueOf(fdao.getCwsFlag());
				}
				else if (fieldName.equals("cws_creator")) {
					fieldValue = StrUtil.getNullStr(um.getUserDb(fdao.getCreator()).getRealName());
				}
				else if (fieldName.equals("cws_status")) {
					fieldValue = com.redmoon.oa.flow.FormDAO.getStatusDesc(fdao.getCwsStatus());
				}
				else {
					FormField ff = fd.getFormField(fieldName);
					if (ff == null) {
						fieldValue = "不存在！";
					} else {
						if (ff.getType().equals(FormField.TYPE_MACRO)) {
							MacroCtlUnit mu = mm.getMacroCtlUnit(ff.getMacroType());
							if (mu != null) {
								if (mu.getCode().equals("nest_sheet") || mu.getCode().equals("nest_table")) {
									isSingle = false;
									String ntFormCode = nestMapping.get(ff.getName());
									if (ntFormCode != null) {
										String ntFieldNames = nestFieldName.get(ntFormCode);
										String[] ntFieldAry = StrUtil.split(ntFieldNames, ",");
										Vector riData = nestData.get(ntFormCode);
										if (riData != null) {
											int rowInc = 0;
											Iterator it = riData.iterator();
											while (it.hasNext()) {
												int columnInc = 0;
												Vector rrv = (Vector) it.next();
												long ntid = StrUtil.toLong(rrv.get(0).toString(), 0);
												FormDb ntfd = new FormDb(ntFormCode);
												FormDAO ntfdao = new FormDAO(ntid, ntfd);

												if (ntfdao != null && ntfdao.isLoaded()) {
													for (int k = 0; k < ntFieldAry.length; k++) {
														int width = columnWidthMap.get(i + index + columnInc);
														String content = ntfdao.getFieldValue(ntFieldAry[k]);

														FormField ntff = ntfdao.getFormField(ntFieldAry[k]);

														if (ntff.getType().equals(FormField.TYPE_MACRO)) {
															MacroCtlUnit ntmu = mm.getMacroCtlUnit(ntff.getMacroType());
															if (ntmu != null) {
																content = StrUtil.getAbstract(request, ntmu.getIFormMacroCtl().converToHtml(request, ntff, ntfdao.getFieldValue(ntFieldAry[k])), 1000, "");
															}
														}

														if (content != null && content.getBytes().length > width) {
															columnWidthMap.put(i + index + columnInc, content.getBytes().length);
														}

														int fieldType = FormField.FIELD_TYPE_TEXT;
														if (ntff != null) {
															fieldType = ntff.getFieldType();
														}
														WritableCellFormat wcf = setCellFormat(fieldType, group, map);

														// 设置列格式
														// 如果是嵌套表，则数据从第三行开始，所以要在j+rowInc 基础上+1
														if (templateId==-1) {
															WritableCell wc = createWritableCell(fieldType, i + index + columnInc++, j + rowInc + 1, content, wcf);
															ws.addCell(wc);
														}
														else {
															WritableCell wc = createWritableCell(fieldType, i + index + columnInc++, j + rowInc, content, wcf);
															ws.addCell(wc);
														}
													}
													rowInc++;
												}
											}
											// 将没有值的单元格补色
											for (int m = rowInc; m < maxCount; m++) {
												for (int k = 0; k < ntFieldAry.length; k++) {
													WritableCellFormat wcf = setCellFormat(FormField.FIELD_TYPE_TEXT, group, map);
													if (templateId==-1) {
														Label a = new Label(i + index + k, j + m + 1, "", wcf);
														ws.addCell(a);
													}
													else {
														Label a = new Label(i + index + k, j + m, "", wcf);
														ws.addCell(a);
													}
												}
											}
											index += ntFieldAry.length - 1;
										}
									}
								} else if (!mu.getCode().equals("macro_raty")) {
									fieldValue = StrUtil.getAbstract(request, mu.getIFormMacroCtl().converToHtml(request, ff, fdao.getFieldValue(fieldName)), 1000, "");
								} else {
									fieldValue = FuncUtil.renderFieldValue(fdao, fdao.getFormField(fieldName));
								}
							}
						} else {
							// fieldValue = fdao.getFieldValue(fieldName);
							fieldValue = FuncUtil.renderFieldValue(fdao, fdao.getFormField(fieldName));
						}
					}
				}

				if (isSingle) {
					int width = columnWidthMap.get(i + index);

					if (fieldValue != null && fieldValue.getBytes().length > width) {
						columnWidthMap.put(i + index, fieldValue.getBytes().length);
					}

					FormField ff = fdao.getFormField(fieldName);
					int fieldType = FormField.FIELD_TYPE_TEXT;
					if (ff != null) {
						fieldType = ff.getFieldType();
					}
					wcFormat = setCellFormat(fieldType, group, map);

					// 设置列格式

					WritableCell wc = createWritableCell(fieldType, i + index, j, fieldValue, wcFormat);
					ws.addCell(wc);

					// 设置每个单元格的值
					if (templateId!=-1) {
						for (int a = j + 1; a <= j + maxCount - 1; a++) {
							WritableCell wc1 = createWritableCell(fieldType, i + index, a, fieldValue, wcFormat);
							ws.addCell(wc1);
						}
					}
					if (templateId==-1) {
						// 扩展至多行,合并单元格
						ws.mergeCells(i + index, j, i + index, j + maxCount - 1);
					}
				}
			}
			group++;
			j += maxCount;
		}

		// 如果未选择导出模板
		if (templateId==-1) {
			// 设置列宽
			for (int i = 0; i < ws.getColumns(); i++) {
				ws.setColumnView(i, columnWidthMap.get(i) > 30 ? 30 : columnWidthMap.get(i));
			}
		}

		wwb.write();
		wwb.close();
		wb.close();
	} catch (Exception e) {
		e.printStackTrace();
		out.println(e.toString());
	}
	finally {
		os.close();
	}

	out.clear();
	out = pageContext.pushBody();
%>

<%!
	// 20170419 fgf 一个WritableCellFormat不能被重复引用多次，否则会报错
// 在module_excel.jsp页面中，优化了setCellFormat，使其从map中复用取值，但是map不能置于中作为本页的全局变量，而必须作为一个参数来传
// Map map = new HashMap();
// 设置单元格格式
	private WritableCellFormat setCellFormat(int fieldType, int row, Map map) {
		WritableCellFormat wcf = null;
		boolean isFirst = false;
		try {
			// 单元格格式
			switch (fieldType) {
				case FormField.FIELD_TYPE_DOUBLE:
				case FormField.FIELD_TYPE_FLOAT:
				case FormField.FIELD_TYPE_PRICE:
					if (map.get("double")!=null) {
						wcf = (WritableCellFormat)map.get("double");
					}
					else {
						NumberFormat nf1 = new NumberFormat("0.00");
						wcf = new WritableCellFormat(nf1);
						map.put("double", wcf);
						isFirst = true;
					}
					break;
				case FormField.FIELD_TYPE_INT:
				case FormField.FIELD_TYPE_LONG:
					if (map.get("long")!=null) {
						wcf = (WritableCellFormat)map.get("long");
					}
					else {
						NumberFormat nf2 = new NumberFormat("#");
						wcf = new WritableCellFormat(nf2);
						map.put("long", wcf);
						isFirst = true;
					}
					break;
				case FormField.FIELD_TYPE_DATE:
					if (map.get("date")!=null) {
						wcf = (WritableCellFormat)map.get("date");
					}
					else {
						jxl.write.DateFormat df1 = new jxl.write.DateFormat("yyyy-MM-dd");
						wcf = new jxl.write.WritableCellFormat(df1);
						map.put("date", wcf);
						isFirst = true;
					}
					break;
				case FormField.FIELD_TYPE_DATETIME:
					if (map.get("datetime")!=null) {
						wcf = (WritableCellFormat)map.get("datetime");
					}
					else {
						jxl.write.DateFormat df2 = new jxl.write.DateFormat("yyyy-MM-dd HH:mm:ss");
						wcf = new jxl.write.WritableCellFormat(df2);
						map.put("datetime", wcf);
						isFirst = true;
					}
					break;
				default:
					if (map.get("str")!=null) {
						wcf = (WritableCellFormat)map.get("str");
					}
					else {
						wcf = new WritableCellFormat();
						map.put("str", wcf);
						isFirst = true;
					}

					break;
			}

			if (isFirst) {
				// 不能修改已指向的format， jxl.write.biff.JxlWriteException: Attempt to modify a referenced format
				// 对齐方式
				wcf.setAlignment(Alignment.CENTRE);
				wcf.setVerticalAlignment(VerticalAlignment.CENTRE);
				// 边框
				wcf.setBorder(Border.ALL,BorderLineStyle.THIN);
				//自动换行
				wcf.setWrap(true);

				// 背景色
	        /*
	        if (row % 2 == 0) {
	        	wcf.setBackground(jxl.format.Colour.ICE_BLUE);
			} else {
				wcf.setBackground(jxl.format.Colour.WHITE);
			}	
			*/
			}

		} catch (WriteException e) {
			e.printStackTrace();
		}
		return wcf;
	}

	// 创建单元格
	private WritableCell createWritableCell(int fieldType, int column, int row, String data, WritableCellFormat wcf) {
		WritableCell wc = null;
		if (data == null || data.equals("")) {
			wc = new Label(column, row, "", wcf);
		} else {
			switch (fieldType) {
				case FormField.FIELD_TYPE_TEXT:
				case FormField.FIELD_TYPE_VARCHAR:
					wc = new Label(column, row, data, wcf);
					break;
				case FormField.FIELD_TYPE_DOUBLE:
				case FormField.FIELD_TYPE_FLOAT:
				case FormField.FIELD_TYPE_PRICE:
					wc = new jxl.write.Number(column, row, StrUtil.toDouble(data), wcf);
					break;
				case FormField.FIELD_TYPE_INT:
				case FormField.FIELD_TYPE_LONG:
					wc = new jxl.write.Number(column, row, StrUtil.toLong(data), wcf);
					break;
				case FormField.FIELD_TYPE_DATE:
					wc = new jxl.write.DateTime(column, row, DateUtil.parse(data, "yyyy-MM-dd"), wcf);
					break;
				case FormField.FIELD_TYPE_DATETIME:
					wc = new jxl.write.DateTime(column, row, DateUtil.parse(data, "yyyy-MM-dd HH:mm:ss"), wcf);
					break;
				default:
					wc = new jxl.write.Number(column, row, StrUtil.toDouble(data), wcf);
					break;
			}
		}
		return wc;
	}
%>
