
<!--
/////////////////////////////////////////////////
// Coalesys WebMenu Studio IE4 DHTML script
// Build 65 COPYRIGHT 2000-2002 Coalesys, Inc.
/////////////////////////////////////////////////
var cswmMBZ=false;var cswmCSDS=false;var cswmOM="document.all.";var cswmBgCo=".style.backgroundColor";var cswmCo=".style.color";var cswmDi=".style.display";var cswmTI="";var cswmClkd=-1;var cswmPI=new Array();var cswmPx=new Array();var cswmPy=new Array();var cswmNH=new Array();var cswmPW=0;var cswmPH=0;var cswmSPnt="";var cswmDir="";var cswmMB=0;var cswmSI="";var cswmSE=new Object();var cswmSEL=0;var cswmSET=0;var cswmSEH=0;var cswmSEW=0;var cswmBW=0;var cswmBH=0;var cswmAR=0;var cswmAB=0;var cswmSLA=0;var cswmSTA=0;var cswmExIS=new Image();cswmExIS.src="/images/holiday/popup.gif";var cswmExdIS=new Image();cswmExdIS.src="/images/holiday/selectedpopup.gif";var cswmCTH=true;var cswmXOff=0;var cswmYOff=0;var cswmFP=0;var cswmSTI=0;function cswmT(ms){if(ms!="off"){if(cswmCTH!=0){cswmTI=setTimeout("cswmHP(0);",ms);}}else{clearTimeout(cswmTI);}}function cswmST(l,g,i){if(i){cswmSTI = setTimeout("cswmHP("+l+");cswmSP("+g+",'"+i+"');",350);}else if(l){cswmSTI = setTimeout("cswmHP("+l+");",350);}else{clearTimeout(cswmSTI);}}function cswmShow(id,srcid,relpos,offsetX,offsetY,fixedpos){clearTimeout(cswmTI);if(cswmClkd!=id){cswmHP(0);cswmSI=srcid;cswmSPnt=relpos;cswmClkd=id;cswmDir="right";if(eval(cswmOM+"cswmPopup"+id)){if(offsetX)cswmXOff=offsetX;if(offsetY)cswmYOff=offsetY;if(fixedpos)cswmFP=fixedpos;cswmSP(id);}}}function cswmHide(){cswmTI=setTimeout("cswmHP(0);",350);}function cswmHiI(id){if(!document.all["cswmItem"+id]){return;}var bgco;try{bgco =  document.all['cswmItem'+id].getAttribute('cswmSelColor');}catch(e){bgco = false;}eval(cswmOM+"cswmItem"+id+cswmCo+"=\"#ffffff\"");eval(cswmOM+"cswmExpand"+id+cswmCo+"=\"#ffffff\"");if(bgco){document.all["cswmItem"+id].style.backgroundColor=bgco;document.all["cswmExpand"+id].style.backgroundColor=bgco;}else{eval(cswmOM+"cswmItem"+id+cswmBgCo+"=\"#0a246a\"");eval(cswmOM+"cswmExpand"+id+cswmBgCo+"=\"#0a246a\"");}if(eval(cswmOM+"cswmExpandIc"+id)){eval(cswmOM+"cswmExpandIc"+id+".src=cswmExdIS.src");}if(cswmNH[l-1]!=id){var count=l-1;for(count=l-1;count<cswmNH.length;count++){cswmDiI(cswmNH[count]);}cswmNH.length=l;}cswmNH[l-1]=id;}function cswmDiI(id){if(!document.all["cswmItem"+id]){return;}var bgco;try{bgco =  document.all["cswmItem"+id].getAttribute('cswmUnSelColor');}catch(e){bgco = false;}eval(cswmOM+"cswmItem"+id+cswmCo+"=\"#000000\"");eval(cswmOM+"cswmExpand"+id+cswmCo+"=\"#000000\"");if(bgco){document.all["cswmItem"+id].style.backgroundColor=bgco;document.all["cswmExpand"+id].style.backgroundColor=bgco;}else{eval(cswmOM+"cswmItem"+id+cswmBgCo+"=\"#d4d0c8\"");eval(cswmOM+"cswmExpand"+id+cswmBgCo+"=\"#d4d0c8\"");}if(eval(cswmOM+"cswmExpandIc"+id)){eval(cswmOM+"cswmExpandIc"+id+".src=cswmExIS.src");}}function cswmSP(id,itemid){if(!itemid){if(cswmFP){cswmSEL=cswmXOff;cswmSET=cswmYOff;cswmSEH=1;cswmSEW=1;cswmFP=0;}else{if(!document.all[cswmSI]){return;}cswmSE=new Object(eval(cswmOM+cswmSI));var cswmPrO=cswmSE;var cswmPrT="";cswmSEL=cswmSE.offsetLeft+cswmXOff;cswmSET=cswmSE.offsetTop+cswmYOff;cswmSEH=cswmSE.offsetHeight;cswmSEW=cswmSE.offsetWidth;while(cswmPrT!="BODY"){cswmPrO=cswmPrO.offsetParent;cswmSEL+=cswmPrO.offsetLeft;cswmSET+=cswmPrO.offsetTop;cswmPrT=cswmPrO.tagName;}}eval(cswmOM+"cswmPopup"+id+".style.width=1");eval(cswmOM+"cswmPopup"+id+".style.height=1");eval(cswmOM+"cswmPopup"+id+cswmDi+"=\"block\"");cswmPW=eval(cswmOM+"cswmPopup"+id+".clientWidth");cswmPH=eval(cswmOM+"cswmPopup"+id+".clientHeight");cswmBW=document.body.clientWidth;cswmBH=document.body.clientHeight;cswmSLA=document.body.scrollLeft;cswmSTA=document.body.scrollTop;switch(cswmSPnt){case "above":cswmPx[cswmPx.length]=cswmSEL;cswmPy[cswmPy.length]=cswmSET-cswmPH;cswmCA();cswmCR();break;case "below":cswmPx[cswmPx.length]=cswmSEL;cswmPy[cswmPy.length]=cswmSET+cswmSEH;cswmCB();cswmCR();break;case "right":cswmPx[cswmPx.length]=cswmSEL+cswmSEW;cswmPy[cswmPy.length]=cswmSET;cswmCR();cswmCB();break;case "left":cswmPx[cswmPx.length]=cswmSEL-cswmPW;cswmPy[cswmPy.length]=cswmSET;cswmCL();cswmCB();cswmDir="left";break;}cswmXOff=0;cswmYOff=0;eval(cswmOM+"cswmPopup"+id+".style.left=cswmPx[cswmPx.length-1]");eval(cswmOM+"cswmPopup"+id+".style.top=cswmPy[cswmPy.length-1]");cswmPI[cswmPI.length]=id;}else{cswmPx[cswmPx.length]=eval(cswmOM+"cswmPopup"+cswmPI[cswmPI.length-1]+".clientWidth")+cswmPx[cswmPx.length-1]-4;var szPrE="";if(document.all["cswmItem"+itemid].offsetParent.offsetTop==0){if(document.all["cswmItem"+itemid].offsetParent.offsetParent.offsetParent.offsetParent.className!="cswmPopupBox"){var szPrE="offsetParent.offsetParent.offsetParent.";}}cswmPy[cswmPy.length]=eval(cswmOM+"cswmItem"+itemid+".offsetParent."+szPrE+"offsetTop")+cswmPy[cswmPy.length-1];eval(cswmOM+"cswmPopup"+id+".style.width=1");eval(cswmOM+"cswmPopup"+id+".style.height=1");eval(cswmOM+"cswmPopup"+id+cswmDi+"=\"block\"");cswmPW=eval(cswmOM+"cswmPopup"+id+".clientWidth");cswmPH=eval(cswmOM+"cswmPopup"+id+".clientHeight");var cswmPrW=eval(cswmOM+"cswmPopup"+cswmPI[cswmPI.length-1]+".clientWidth");cswmAR=cswmBW-cswmPx[cswmPx.length-1]+cswmSLA;cswmAB=cswmBH-cswmPy[cswmPy.length-1]+cswmSTA;if(cswmPx[cswmPx.length-2]==cswmSLA){cswmDir="right";}if((cswmAR<cswmPW)||(cswmDir=="left")){cswmMB=(cswmPx[cswmPx.length-1]-cswmPW-cswmPrW)+8;if((cswmMB>=0)&&(cswmMB>cswmSLA)){cswmDir="left";}else{cswmMB=cswmSLA;}cswmPx[cswmPx.length-1]=cswmMB;}if(cswmAB<cswmPH){cswmMB=cswmPy[cswmPy.length-1]-(cswmPH-cswmAB);if(cswmMB<0){cswmMB=cswmSTA;}cswmPy[cswmPy.length-1]=cswmMB;}eval(cswmOM+"cswmPopup"+id+".style.left=cswmPx[cswmPx.length-1]");eval(cswmOM+"cswmPopup"+id+".style.top=cswmPy[cswmPy.length-1]");cswmPI[cswmPI.length]=id;}}function cswmHP(level){if(cswmClkd==-1){return false;}else if(level==0){cswmClkd=-1;var id = cswmPI[0];var count=0;for(count=0;count<cswmNH.length;count++){cswmDiI(cswmNH[count]);}cswmNH.length=0;cswmButtonNormal("cswmMenuButton"+id);cswmButtonClickState=false;}var count=level;for(count=level;count<cswmPI.length;count++){eval(cswmOM+"cswmPopup"+cswmPI[count]+cswmDi+"=\"none\"");}cswmPI.length=level;cswmPx.length=level;cswmPy.length=level;}function cswmCR(){cswmAR=(cswmBW+cswmSLA)-cswmPx[cswmPx.length-1];if(cswmAR<cswmPW){if(cswmSPnt=="below"||cswmSPnt=="above"){cswmMB=cswmPx[cswmPx.length-1]-(cswmPW-cswmAR);if(cswmMB<0||cswmMB<cswmSLA){cswmMB=cswmSLA;}cswmPx[cswmPx.length-1]=cswmMB;}else{cswmMB=cswmSEL-cswmPW;if(cswmMB>=0){cswmPx[cswmPx.length-1]=cswmMB;}}}}function cswmCL(){if(cswmPx[cswmPx.length-1]<(cswmSLA)){cswmPx[cswmPx.length-1]=cswmSEL+cswmSEW;cswmCR();}}function cswmCB(){cswmAB=(cswmBH+cswmSTA)-cswmPy[cswmPy.length-1];if(cswmAB<cswmPH){if(cswmSPnt=="below"){cswmMB=cswmPy[cswmPy.length-1]-cswmPH-cswmSEH;if(cswmMB>=0){cswmPy[cswmPy.length-1]=cswmMB;}}else{cswmMB=cswmPy[cswmPy.length-1]-(cswmPH-cswmAB);if(cswmMB<0||cswmMB<cswmSTA){cswmMB=cswmSTA;}cswmPy[cswmPy.length-1]=cswmMB;}}}function cswmCA(){if(cswmPy[cswmPy.length-1]<(cswmSTA)){cswmPy[cswmPy.length-1]=cswmSET+cswmSEH;cswmCB();}}function cswmHideSelectBox(){}function cswmShowInFrame(MenuID,x,y){x+=document.body.scrollLeft;y+=document.body.scrollTop;cswmShow(MenuID,'','below',x,y,1);}function cswmRefresh(){}var cswmButtonClickState=false;var cswmCurrentButtonId;var cswmButtonsObj;var cswmNeedPosInit=true;var cswmDockObj;var cswmIsDock=false;var cswmDockSpace="";var cswmTop=10;var cswmLeft=10;function cswmButtonDown(id,gid){cswmCurrentButtonId=id;cswmButtonSunken(id);if(cswmIsDock){cswmShow(gid, id, 'below', 1, 1);}else{cswmShow(gid, id, 'below', 2, 2);}}function cswmButtonSelect(id,gid){if(!cswmButtonClickState){cswmButtonRaised(id);}else{cswmButtonNormal(cswmCurrentButtonId);clearTimeout(cswmTI);cswmButtonDown(id,gid);}}function cswmButtonUnSelect(id){if(!cswmButtonClickState){cswmButtonNormal(id);}else{cswmHide();}}function cswmButtonRaised(id){var obj = document.all(id).style;obj.borderTopColor = "#ffffff";obj.borderLeftColor = "#ffffff";obj.borderBottomColor = "#808080";obj.borderRightColor = "#808080";obj.backgroundColor = "#d4d0c8";obj.paddingBottom = "4px";obj.paddingTop = "4px";obj.paddingLeft = "6px";obj.paddingRight = "6px";obj.color = "#000000";}function cswmButtonSunken(id){var obj = document.all(id).style;obj.borderTopColor = "#808080";obj.borderLeftColor = "#808080";obj.borderBottomColor = "#ffffff";obj.borderRightColor = "#ffffff";obj.backgroundColor = "#d4d0c8";obj.paddingBottom = "3px";obj.paddingTop = "5px";obj.paddingLeft = "7px";obj.paddingRight = "5px";obj.color = "#000000";}function cswmButtonNormal(id){var obj = document.all(id).style;obj.borderTopColor = "#d4d0c8";obj.borderLeftColor = "#d4d0c8";obj.borderBottomColor = "#d4d0c8";obj.borderRightColor = "#d4d0c8";obj.backgroundColor = "#d4d0c8";obj.paddingBottom = "4px";obj.paddingTop = "4px";obj.paddingLeft = "6px";obj.paddingRight = "6px";obj.color = "#000000";}function cswmMenuBarPos(){cswmButtonsObj = document.all.cswmButtons;cswmDockObj = document.all.cswmDock;cswmButtonsObj.style.left = cswmLeft;cswmButtonsObj.style.top = cswmTop;cswmNeedPosInit = false;cswmDockObj.style.height = cswmButtonsObj.offsetHeight;document.all.cswmInrDck.style.height = cswmButtonsObj.offsetHeight-2;}function cswmDock(location){cswmButtonsObj.style.width = "100%";cswmButtonsObj.children[0].style.width = "100%";cswmButtonsObj.style.borderWidth = "0px";cswmDisplayDock(false);cswmLeft = 0;cswmButtonsObj.style.left = cswmLeft + document.body.scrollLeft;if(String(location) != "undefined"){if(cswmNeedPosInit){cswmMenuBarPos();}cswmDockSpace = location;}if(cswmDockSpace == "top"){var csdsAdjust=0;if(cswmCSDS){csdsAdjust=_csdsTop;}cswmTop=0+csdsAdjust;cswmButtonsObj.style.top = cswmTop + document.body.scrollTop;document.body.style.paddingTop = parseInt(cswmDockObj.style.height)-2+csdsAdjust;if(cswmCSDS){_csdsCoopDock('cswm','top',parseInt(cswmDockObj.style.height)-2);}}else if(cswmDockSpace == "bottom"){var csdsAdjust=0;if(cswmCSDS){csdsAdjust=_csdsBottom;}cswmTop = (document.body.clientHeight - cswmButtonsObj.offsetHeight)-csdsAdjust;cswmButtonsObj.style.top = cswmTop + document.body.scrollTop;document.body.style.paddingBottom = parseInt(cswmDockObj.style.height)-2+csdsAdjust;if(cswmCSDS){_csdsCoopDock('cswm','bottom',parseInt(cswmDockObj.style.height)-2);}}cswmIsDock = true;}function cswmUnDock(){cswmDisplayDock(true);cswmButtonsObj.style.borderWidth = "1px";cswmButtonsObj.style.width = 3;cswmButtonsObj.children[0].style.width = 3;cswmIsDock = false;cswmDockSpace = "";if(cswmCSDS){_csdsCoopUnDock('cswm',parseInt(cswmDockObj.style.height));document.body.style.paddingTop=_csdsTop;document.body.style.paddingBottom=_csdsBottom;}else{document.body.style.paddingTop=0;document.body.style.paddingBottom=0;}}function cswmDisplayDock(state){if(state){if(cswmDockSpace == "top"){var csdsAdjust=0;if(cswmCSDS){csdsAdjust=_csdsTop;}cswmDockObj.style.top = 0 + document.body.scrollTop + csdsAdjust;}else{var csdsAdjust=0;if(cswmCSDS){csdsAdjust=_csdsBottom;}cswmDockObj.style.top = ((document.body.clientHeight - cswmDockObj.offsetHeight) + document.body.scrollTop) - csdsAdjust;}cswmDockObj.style.left = document.body.scrollLeft;cswmDockObj.style.display = "block";}else{cswmDockObj.style.display = "none";}}function cswmFloat(){if(cswmNeedPosInit){cswmMenuBarPos();}cswmButtonsObj.style.top = cswmTop + document.body.scrollTop;cswmButtonsObj.style.left = cswmLeft + document.body.scrollLeft;}function cswmResize(){if(cswmDockSpace == 'bottom'){cswmDock('bottom');}}function cswmAttachScrollHandler(){var e = window.onscroll;if (typeof(e)=="function" ){e = e.toString();e = e.substring(e.indexOf("{")+1,e.lastIndexOf("}"));var f = cswmFloat.toString();f = f.substring(f.indexOf("{")+1,f.lastIndexOf("}"));var sh = new Function(f + e);window.onscroll=sh;}else{window.onscroll=cswmFloat;}}function cswmMenuBarInit(){if(typeof(_csds)!='undefined'){cswmCSDS=true;if(_csdsZIndex<999){_csdsZIndex=999;}}cswmMenuBarPos();cswmAttachScrollHandler();cswmDock('top');}
//-->

document.write("\r\n<!-- Coalesys WebMenu Studio -->\r\n<!-- WebMenu HTML Structure COPYRIGHT 2000-2002 Coalesys, Inc. -->\r\n<div id=\"cswmPopupGroup_141c\" class=\"cswmPopupBox\" onselectstart=\"return false;\"><table border=0 cellpadding=0 cellspacing=0><tr><td><div style=\"border-style:solid; border-width: 1px; border-color:#d4d0c8 #404040 #404040 #d4d0c8\"><div style=\"border-style:solid; border-width: 1px; border-color:#ffffff #808080 #808080 #ffffff\"><table border=0 cellpadding=0 cellspacing=0><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'Group_141c_0\',1);cswmST(1);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=add_user\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItemGroup_141c_0\" class=\"cswmItem\">Add New</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpandGroup_141c_0\" class=\"cswmExpand\"></td></tr><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'Group_141c_1\',1);cswmST(1);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=users_home\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItemGroup_141c_1\" class=\"cswmItem\">View / Edit</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpandGroup_141c_1\" class=\"cswmExpand\"></td></tr></table></div></div></td></tr></table></div><div id=\"cswmPopupGroup_5208\" class=\"cswmPopupBox\" onselectstart=\"return false;\"><table border=0 cellpadding=0 cellspacing=0><tr><td><div style=\"border-style:solid; border-width: 1px; border-color:#d4d0c8 #404040 #404040 #d4d0c8\"><div style=\"border-style:solid; border-width: 1px; border-color:#ffffff #808080 #808080 #ffffff\"><table border=0 cellpadding=0 cellspacing=0><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'Group_5208_0\',1);cswmST(1,0,\'Group_5208_0\');\" onmouseout=\"cswmT(350);cswmST();\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItemGroup_5208_0\" class=\"cswmItem\">Holiday</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpandGroup_5208_0\" class=\"cswmExpand\" style=\"padding-right:5\"><img id=\"cswmExpandIcGroup_5208_0\" src=\"/images/holiday/popup.gif\" width=10 height=10 alt=\"\" border=0></td></tr><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'Group_5208_1\',1);cswmST(1,1,\'Group_5208_1\');\" onmouseout=\"cswmT(350);cswmST();\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItemGroup_5208_1\" class=\"cswmItem\">Sick</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpandGroup_5208_1\" class=\"cswmExpand\" style=\"padding-right:5\"><img id=\"cswmExpandIcGroup_5208_1\" src=\"/images/holiday/popup.gif\" width=10 height=10 alt=\"\" border=0></td></tr><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'Group_5208_2\',1);cswmST(1,2,\'Group_5208_2\');\" onmouseout=\"cswmT(350);cswmST();\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItemGroup_5208_2\" class=\"cswmItem\">Owed Days</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpandGroup_5208_2\" class=\"cswmExpand\" style=\"padding-right:5\"><img id=\"cswmExpandIcGroup_5208_2\" src=\"/images/holiday/popup.gif\" width=10 height=10 alt=\"\" border=0></td></tr><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'Group_5208_3\',1);cswmST(1,3,\'Group_5208_3\');\" onmouseout=\"cswmT(350);cswmST();\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItemGroup_5208_3\" class=\"cswmItem\">Other Reason</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpandGroup_5208_3\" class=\"cswmExpand\" style=\"padding-right:5\"><img id=\"cswmExpandIcGroup_5208_3\" src=\"/images/holiday/popup.gif\" width=10 height=10 alt=\"\" border=0></td></tr></table></div></div></td></tr></table></div><div id=\"cswmPopup0\" class=\"cswmPopupBox\" onselectstart=\"return false;\" onmouseover=\"cswmHiI(\'Group_5208_0\',1);\"><table border=0 cellpadding=0 cellspacing=0><tr><td><div style=\"border-style:solid; border-width: 1px; border-color:#d4d0c8 #404040 #404040 #d4d0c8\"><div style=\"border-style:solid; border-width: 1px; border-color:#ffffff #808080 #808080 #ffffff\"><table border=0 cellpadding=0 cellspacing=0><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'0_0\',2);cswmST(2);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=holiday\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItem0_0\" class=\"cswmItem\">One Days Holiday</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpand0_0\" class=\"cswmExpand\"></td></tr><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'0_1\',2);cswmST(2);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=holiday&multi=y\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItem0_1\" class=\"cswmItem\">Several Days Holiday</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpand0_1\" class=\"cswmExpand\"></td></tr></table></div></div></td></tr></table></div><div id=\"cswmPopup1\" class=\"cswmPopupBox\" onselectstart=\"return false;\" onmouseover=\"cswmHiI(\'Group_5208_1\',1);\"><table border=0 cellpadding=0 cellspacing=0><tr><td><div style=\"border-style:solid; border-width: 1px; border-color:#d4d0c8 #404040 #404040 #d4d0c8\"><div style=\"border-style:solid; border-width: 1px; border-color:#ffffff #808080 #808080 #ffffff\"><table border=0 cellpadding=0 cellspacing=0><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'1_0\',2);cswmST(2);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=sick\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItem1_0\" class=\"cswmItem\">One Day Sick</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpand1_0\" class=\"cswmExpand\"></td></tr><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'1_1\',2);cswmST(2);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=sick&multi=y\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItem1_1\" class=\"cswmItem\">Several Days Sick</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpand1_1\" class=\"cswmExpand\"></td></tr></table></div></div></td></tr></table></div><div id=\"cswmPopup2\" class=\"cswmPopupBox\" onselectstart=\"return false;\" onmouseover=\"cswmHiI(\'Group_5208_2\',1);\"><table border=0 cellpadding=0 cellspacing=0><tr><td><div style=\"border-style:solid; border-width: 1px; border-color:#d4d0c8 #404040 #404040 #d4d0c8\"><div style=\"border-style:solid; border-width: 1px; border-color:#ffffff #808080 #808080 #ffffff\"><table border=0 cellpadding=0 cellspacing=0><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'2_0\',2);cswmST(2);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=owed\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItem2_0\" class=\"cswmItem\">One Owed Day</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpand2_0\" class=\"cswmExpand\"></td></tr><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'2_1\',2);cswmST(2);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=owed&multi=y\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItem2_1\" class=\"cswmItem\">Several Owed Days</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpand2_1\" class=\"cswmExpand\"></td></tr></table></div></div></td></tr></table></div><div id=\"cswmPopup3\" class=\"cswmPopupBox\" onselectstart=\"return false;\" onmouseover=\"cswmHiI(\'Group_5208_3\',1);\"><table border=0 cellpadding=0 cellspacing=0><tr><td><div style=\"border-style:solid; border-width: 1px; border-color:#d4d0c8 #404040 #404040 #d4d0c8\"><div style=\"border-style:solid; border-width: 1px; border-color:#ffffff #808080 #808080 #ffffff\"><table border=0 cellpadding=0 cellspacing=0><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'3_0\',2);cswmST(2);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=other\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItem3_0\" class=\"cswmItem\">One Day</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpand3_0\" class=\"cswmExpand\"></td></tr><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'3_1\',2);cswmST(2);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=other&multi=y\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItem3_1\" class=\"cswmItem\">Several Days</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpand3_1\" class=\"cswmExpand\"></td></tr></table></div></div></td></tr></table></div><div id=\"cswmPopupGroup_6f59\" class=\"cswmPopupBox\" onselectstart=\"return false;\"><table border=0 cellpadding=0 cellspacing=0><tr><td><div style=\"border-style:solid; border-width: 1px; border-color:#d4d0c8 #404040 #404040 #d4d0c8\"><div style=\"border-style:solid; border-width: 1px; border-color:#ffffff #808080 #808080 #ffffff\"><table border=0 cellpadding=0 cellspacing=0><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'Group_6f59_0\',1);cswmST(1);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=view_day&day=today\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItemGroup_6f59_0\" class=\"cswmItem\">Days</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpandGroup_6f59_0\" class=\"cswmExpand\"></td></tr><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'Group_6f59_1\',1);cswmST(1);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=view_week&week=thisweek\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItemGroup_6f59_1\" class=\"cswmItem\">Weeks</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpandGroup_6f59_1\" class=\"cswmExpand\"></td></tr><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'Group_6f59_2\',1);cswmST(1);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=view_month&month=thismonth\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItemGroup_6f59_2\" class=\"cswmItem\">Months</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpandGroup_6f59_2\" class=\"cswmExpand\"></td></tr></table></div></div></td></tr></table></div><div id=\"cswmPopupGroup_8a7e\" class=\"cswmPopupBox\" onselectstart=\"return false;\"><table border=0 cellpadding=0 cellspacing=0><tr><td><div style=\"border-style:solid; border-width: 1px; border-color:#d4d0c8 #404040 #404040 #d4d0c8\"><div style=\"border-style:solid; border-width: 1px; border-color:#ffffff #808080 #808080 #ffffff\"><table border=0 cellpadding=0 cellspacing=0><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'Group_8a7e_0\',1);cswmST(1);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=customer_support\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItemGroup_8a7e_0\" class=\"cswmItem\">Customer Support</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpandGroup_8a7e_0\" class=\"cswmExpand\"></td></tr><tr onmouseover=\"cswmT(\'off\');cswmHiI(\'Group_8a7e_1\',1);cswmST(1);\" onmouseout=\"cswmT(350);cswmST();\" onClick=\"cswmHP(0);get_xTree_query(\'&method=about_webkit\');;\"><td nowrap bgcolor=\"#d4d0c8\" id=\"cswmItemGroup_8a7e_1\" class=\"cswmItem\">About WebKit</td><td bgcolor=\"#d4d0c8\" id=\"cswmExpandGroup_8a7e_1\" class=\"cswmExpand\"></td></tr></table></div></div></td></tr></table></div>\r\n<div class=\"cswmDock\" id=\"cswmDock\"><span id=\"cswmInrDck\" style=\"border:dotted #ffffff 1px; width:100%;\"><img src=\"/images/holidayClearPixel.gif\" width=1 height=1></span></div><div class=\"cswmButtons\"id=\"cswmButtons\" onselectstart=\"return false;\"><div class=\"cswmInnerBorder\"><table width=1 cellspacing=0 cellpadding=0 border=0><tr><td class=\"cswmButton\" id=\"cswmMenuButtonGroup_141c\" onmouseover=\"cswmButtonSelect(this.id, \'Group_141c\')\" onmouseout=\"cswmButtonUnSelect(this.id)\" onmousedown=\"cswmButtonDown(this.id, \'Group_141c\')\" nowrap>Employees</td><td class=\"cswmButton\" id=\"cswmMenuButtonGroup_5208\" onmouseover=\"cswmButtonSelect(this.id, \'Group_5208\')\" onmouseout=\"cswmButtonUnSelect(this.id)\" onmousedown=\"cswmButtonDown(this.id, \'Group_5208\')\" nowrap>Attendance</td><td class=\"cswmButton\" id=\"cswmMenuButtonGroup_6f59\" onmouseover=\"cswmButtonSelect(this.id, \'Group_6f59\')\" onmouseout=\"cswmButtonUnSelect(this.id)\" onmousedown=\"cswmButtonDown(this.id, \'Group_6f59\')\" nowrap>View</td><td class=\"cswmButton\" id=\"cswmMenuButtonGroup_8a7e\" onmouseover=\"cswmButtonSelect(this.id, \'Group_8a7e\')\" onmouseout=\"cswmButtonUnSelect(this.id)\" onmousedown=\"cswmButtonDown(this.id, \'Group_8a7e\')\" nowrap>Help</td><td width=\"100%\"></td></tr></table></div></div>\r\n<!-- End WebMenu HTML -->\r\n\r\n");