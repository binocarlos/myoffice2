
<!--
/////////////////////////////////////////////////
// Coalesys WebMenu Studio NN4 DHTML script
// Build 65 COPYRIGHT 2000-2002 Coalesys, Inc.
/////////////////////////////////////////////////
var cswmMBZ=false;var cswmCSDS=false;var cswmP=new Object();var cswmBP=3;var cswmRP=10;var cswmBS=2;var cswmTI="";var cswmClkd=new String();var cswmPI=new Array();var cswmPL=new Array();var cswmPT=new Array();var cswmPS=new Array();var cswmNH=new Array();var cswmNHPL=new Array();var cswmPW=0;var cswmPH=0;var cswmSPnt="";var cswmDir="";var cswmMB=0;var cswmSI="";var cswmSE=new Object();var cswmSEL=0;var cswmSET=0;var cswmSEH=0;var cswmSEW=0;var cswmBW=self.innerWidth-16;var cswmBH=self.innerHeight-16;var cswmAR=0;var cswmAB=0;var cswmSLA=0;var cswmSTA=0;var cswmIW=0;var cswmC=0;var cswmHS=0;var cswmL=0;var cswmCTH=true;var cswmPrL=new String();cswmWinY=window.outerHeight;cswmWinX=window.outerWidth;var cswmXOff=0;var cswmYOff=0;var cswmFP=0;var cswmSTI=0;function cswmT(ms){if(ms!="off"){if(cswmCTH!=0){cswmTI=setTimeout("cswmHP(0);",ms);}}else{clearTimeout(cswmTI);}}function cswmST(l,g,i){if(i){cswmSTI = setTimeout("cswmHP("+l+");cswmSP("+g+",'"+i+"');",350);}else if(l){cswmSTI = setTimeout("cswmHP("+l+");",350);}else{clearTimeout(cswmSTI);}}function cswmShow(id,srcid,relpos,offsetX,offsetY,fixedpos,temp){if(!temp){if(!offsetX)offsetX=0;if(!offsetY)offsetY=0;if(!fixedpos)fixedpos=0;setTimeout("cswmShow('"+id+"','"+srcid+"','"+relpos+"',"+offsetX+","+offsetY+","+fixedpos+",1);",10);return;}clearTimeout(cswmTI);if(cswmClkd!=id){cswmHP(0);cswmSI="layers.cswmButtons.layers[0].document." + srcid;cswmSPnt=relpos;cswmClkd=id;cswmDir="right";if(eval("document.cswmPopup"+id)){if(offsetX)cswmXOff=offsetX;if(offsetY)cswmYOff=offsetY;if(fixedpos)cswmFP=fixedpos;cswmButtonClickState=true;cswmSP(id);}}}function cswmHide(){cswmTI=setTimeout("cswmHP(0);",350);}function cswmHiI(id, PrntLayer,l){cswmL=id;cswmPrL=PrntLayer;eval("document.cswmPopup"+PrntLayer+".document.cswmItemHover"+id+".visibility=\"show\"");eval("document.cswmPopup"+PrntLayer+".document.cswmItemMask"+id+".captureEvents(Event.CLICK)");eval("document.cswmPopup"+PrntLayer+".document.cswmItemMask"+id+".onclick=cswmHC");if(cswmNH[l-1]!=id){var count=l-1;for(count=l-1;count<cswmNH.length;count++){cswmDiI(cswmNH[count],cswmNHPL[count]);}cswmNH.length=l;cswmNHPL.length=l;}cswmNH[l-1]=id;cswmNHPL[l-1]=PrntLayer;}function cswmDiI(id,PrntLayer){eval("document.cswmPopup"+PrntLayer+".document.cswmItemHover"+id+".visibility=\"hide\"");eval("document.cswmPopup"+PrntLayer+".document.cswmItemMask"+id+".document.releaseEvents(Event.CLICK)");}function cswmHC(evt){eval("document.cswmPopup"+cswmPrL+".document.cswmItemMask"+cswmL+".document.links[0].handleEvent(evt)");}function cswmSP(id, itemid){cswmP=eval("document.cswmPopup"+id);cswmP.zIndex=1999;cswmC=0;cswmHS=0;var cswmCount=0;for(cswmCount=0;cswmCount<cswmPS.length;cswmCount++){if(cswmPS[cswmCount]==id){cswmHS=1;break;}}if(!itemid){if(cswmFP){cswmSEL=cswmXOff;cswmSET=cswmYOff;cswmSEH=1;cswmSEW=1;cswmFP=0;}else{if(!eval("document."+cswmSI)){return;}cswmSE=new Object(eval("document."+cswmSI));cswmSEL=cswmSE.x+cswmXOff+document.cswmButtons.left;cswmSET=cswmSE.y+cswmYOff+document.cswmButtons.top;cswmSEH=cswmSE.height;cswmSEW=cswmSE.width;}cswmRenP();cswmSLA=self.pageXOffset;cswmSTA=self.pageYOffset;switch(cswmSPnt){case "above":cswmPL[cswmPL.length]=cswmSEL;cswmPT[cswmPT.length]=cswmSET-cswmPH;cswmCA();cswmCR();break;case "below":cswmPL[cswmPL.length]=cswmSEL;cswmPT[cswmPT.length]=cswmSET+cswmSEH;cswmCB();cswmCR();break;case "right":cswmPL[cswmPL.length]=cswmSEL+cswmSEW;cswmPT[cswmPT.length]=cswmSET;cswmCR();cswmCB();break;case "left":cswmPL[cswmPL.length]=cswmSEL-cswmPW;cswmPT[cswmPT.length]=cswmSET;cswmCL();cswmCB();cswmDir="left";break;}cswmXOff=0;cswmYOff=0;}else{cswmPL[cswmPL.length]=eval("document.cswmPopup"+cswmPI[cswmPI.length-1]+".clip.width")+cswmPL[cswmPL.length-1]-4;cswmPT[cswmPT.length]=eval("document.cswmPopup"+cswmPI[cswmPI.length-1]+".document.cswmItem"+itemid+".top")+cswmPT[cswmPT.length-1];cswmRenP();var cswmPrW = eval("document.cswmPopup"+cswmPI[cswmPI.length-1]+".clip.width");cswmAR=cswmBW-cswmPL[cswmPL.length-1]+cswmSLA;cswmAB=cswmBH-cswmPT[cswmPT.length-1]+cswmSTA;if(cswmPL[cswmPL.length-2]==cswmSLA){cswmDir="right";}if((cswmAR<cswmPW)||(cswmDir=="left")){cswmMB=(cswmPL[cswmPL.length-1]-cswmPW-cswmPrW)+8;if((cswmMB>=0)&&(cswmMB>cswmSLA)){cswmDir="left";}else{cswmMB=cswmSLA;}cswmPL[cswmPL.length-1]=cswmMB;}if(cswmAB<cswmPH){cswmMB=cswmPT[cswmPT.length-1]-(cswmPH-cswmAB);if(cswmMB<0){cswmMB=cswmSTA;}cswmPT[cswmPT.length-1]=cswmMB;}}cswmP.pageX=cswmPL[cswmPL.length-1];cswmP.pageY=cswmPT[cswmPT.length-1];if(cswmHS==0){if(cswmBS!=0){cswmMBrd(id);}}if(cswmHS==0);{cswmPS.push(id);}cswmPI[cswmPI.length]=id;cswmIW=0;cswmP.visibility="show";}function cswmHP(level){if(cswmClkd==-1){return false;}else if(level==0){cswmClkd=-1;var count=0;for(count=0;count<cswmNH.length;count++){cswmDiI(cswmNH[count],cswmNHPL[count]);}cswmNH.length=0;cswmNHPL.length=0;cswmButtonClickState=false;}var count=level;for(count=level;count<cswmPI.length; count++){eval("document.cswmPopup"+cswmPI[count]+".visibility=\"hidden\"");}cswmPI.length=level;cswmPL.length=level;cswmPT.length=level;}function cswmCR(){cswmAR=(cswmBW+cswmSLA)-cswmPL[cswmPL.length-1];if(cswmAR<cswmPW){if(cswmSPnt=="below"||cswmSPnt=="above"){cswmMB=cswmPL[cswmPL.length-1]-(cswmPW-cswmAR);if(cswmMB<0||cswmMB<cswmSLA){cswmMB=cswmSLA;}cswmPL[cswmPL.length-1]=cswmMB;}else{cswmMB=cswmSEL-cswmPW;if(cswmMB>=0){cswmPL[cswmPL.length-1]=cswmMB;}}}}function cswmCL(){if(cswmPL[cswmPL.length-1]<(cswmSLA)){cswmPL[cswmPL.length-1]=cswmSEL+cswmSEW;cswmCR();}}function cswmCB(){cswmAB=(cswmBH+cswmSTA)-cswmPT[cswmPT.length-1];if(cswmAB<cswmPH){if(cswmSPnt=="below"){cswmMB=cswmPT[cswmPT.length-1]-cswmPH-cswmSEH - cswmButtonsObj.clip.height;if(cswmMB>=0){cswmPT[cswmPT.length-1]=cswmMB;}}else{cswmMB=cswmPT[cswmPT.length-1]-(cswmPH-cswmAB);if(cswmMB<0||cswmMB<cswmSTA){cswmMB=cswmSTA;}cswmPT[cswmPT.length-1]=cswmMB;}}}function cswmCA(){if(cswmPT[cswmPT.length-1]<(cswmSTA)){cswmPT[cswmPT.length-1]=cswmSET+cswmSEH;cswmCB();}}function cswmMBrd(id){var cswmIT=new Layer(1,cswmP);var cswmIR=new Layer(1,cswmP);var cswmIL=new Layer(1,cswmP);var cswmIB=new Layer(1,cswmP);cswmIT.bgColor="#ffffff";cswmIT.left=cswmBS-1;cswmIT.top=cswmBS-1;cswmIT.clip.width=cswmIW+1;cswmIT.clip.height=1;cswmIT.visibility="inherit";cswmIR.bgColor="#808080";cswmIR.left=cswmIW+cswmBS;cswmIR.top=cswmBS-1;cswmIR.clip.width=1;cswmIR.clip.height=cswmPH;cswmIR.visibility="inherit";cswmIL.bgColor="#ffffff";cswmIL.left=cswmBS-1;cswmIL.top=cswmBS;cswmIL.clip.width=1;cswmIL.clip.height=cswmPH-cswmBS;cswmIL.visibility="inherit";cswmIB.bgColor="#808080";cswmIB.left=cswmBS-1;cswmIB.top=cswmPH-cswmBS;cswmIB.clip.width=cswmIW+1;cswmIB.clip.height=1;cswmIB.visibility="inherit";if(cswmBS==2){var cswmOT=new Layer(1,cswmP);var cswmOR=new Layer(1,cswmP);var cswmOB=new Layer(1,cswmP);var cswmOL=new Layer(1,cswmP);cswmOT.bgColor="#d4d0c8";cswmOT.left=0;cswmOT.top=0;cswmOT.clip.width=cswmIW+3;cswmOT.clip.height=1;cswmOT.visibility="inherit";cswmOR.bgColor="#404040";cswmOR.left=cswmIW+3;cswmOR.top=0;cswmOR.clip.width=1;cswmOR.clip.height=cswmPH;cswmOR.visibility="inherit";cswmOB.bgColor="#404040";cswmOB.left=0;cswmOB.top=cswmPH-1;cswmOB.clip.width=cswmIW+3;cswmOB.clip.height=1;cswmOB.visibility="inherit";cswmOL.bgColor="#d4d0c8";cswmOL.left=0;cswmOL.top=1;cswmOL.clip.width=1;cswmOL.clip.height=cswmPH-2;cswmOL.visibility="inherit";}}function cswmRenP(){var cswmCIO=cswmP.above;var cswmTP=new Number(cswmBS);while(cswmCIO){var cswmLI=cswmCIO.id;if(cswmLI.indexOf("Item")>-1){if(cswmCIO.document.layers.length){cswmC=1;}if(cswmHS==0){cswmCIO.clip.height=cswmCIO.clip.height+cswmBP;}if(cswmCIO.clip.width>(cswmIW-cswmRP)){if(cswmHS==0){cswmIW=cswmCIO.clip.width+cswmRP;}else{cswmIW=cswmCIO.clip.width;}}cswmCIO.top=cswmTP;cswmTP+=cswmCIO.clip.height;cswmCIO.left=cswmBS;cswmCIO=cswmCIO.siblingAbove;var cswmCount=0;for(cswmCount=0;cswmCount<2;cswmCount++){cswmCIO.top=cswmCIO.siblingBelow.top;cswmCIO.left=cswmBS;cswmCIO.clip.height=cswmCIO.siblingBelow.clip.height;cswmCIO=cswmCIO.siblingAbove;}}else if(cswmLI.indexOf("Divider")>-1){cswmCIO.top=cswmTP;cswmCIO.left=cswmBS;cswmTP+=cswmCIO.clip.height;cswmCIO=cswmCIO.siblingAbove;}else{break;}}cswmCIO=cswmP.above;while(cswmCIO){if(cswmLI.indexOf("Divider")>-1){if(cswmCIO.clip.width>cswmIW){cswmIW=cswmCIO.clip.width;if(cswmC && !cswmHS){cswmIW-=15;}}cswmCIO=cswmCIO.siblingAbove;}else if(cswmLI.indexOf("Item")>-1){cswmCIO=cswmCIO.siblingAbove;}else{break;}}if(cswmC && !cswmHS){cswmIW+=15;cswmCIO=cswmP.above;while(cswmCIO){if(cswmCIO.document.layers.length){cswmCIO.above.left=cswmIW-15;cswmCIO.above.top=(cswmCIO.clip.height/2)-5;}cswmCIO=cswmCIO.siblingAbove;}}cswmPH=cswmTP+cswmBS;cswmPW=cswmIW+(cswmBS*2);cswmP.clip.height=cswmPH;cswmP.clip.width=cswmPW;cswmCIO=cswmP.above;while(cswmCIO){var cswmLI=cswmCIO.id;if(cswmLI.indexOf("cswm")>-1){cswmCIO.clip.width=cswmIW;cswmCIO=cswmCIO.siblingAbove;}else{break;}}}function cswmShowInFrame(MenuID,x,y){x+=window.pageXOffset;y+=window.pageYOffset;cswmShow(MenuID,'','below',x,y,1);}function cswmHideSelectBox(){}function cswmRefresh(){if(cswmWinX!=window.outerWidth||cswmWinY!=window.outerHeight){location.reload()}}var cswmButtonClickState = false;var cswmCurrentButtonId;var cswmButtonsObj;var cswmButtonsWidth;var cswmNeedPosInit = true;var cswmDockObj;var cswmIsDock = false;var cswmDockSpace = "";var cswmTop=10;var cswmLeft=10;function cswmButtonDown(id){cswmCurrentButtonId = id;if(cswmIsDock){cswmShow(id, 'cswmImage' + id, 'below');}else{cswmShow(id, 'cswmImage' + id, 'below');}}function cswmButtonSelect(id){if(cswmButtonClickState){clearTimeout(cswmTI);cswmButtonDown(id);}}function cswmButtonUnSelect(id){if(cswmButtonClickState){cswmHide();}}function cswmMenuBarPos(){cswmButtonsObj = document.cswmButtons;cswmDockObj = document.cswmDock;cswmButtonsObj.left = cswmLeft;cswmButtonsObj.top = cswmTop;cswmButtonsWidth = cswmButtonsObj.clip.width;cswmNeedPosInit = false;}function cswmDock(location){cswmButtonsObj.resizeTo(self.innerWidth, cswmButtonsObj.clip.height);cswmDisplayDock(false);cswmLeft = 0;cswmButtonsObj.left = cswmLeft + window.pageXOffset;if(String(location) != "undefined"){if(cswmNeedPosInit){cswmMenuBarPos();}cswmDockSpace = location;}if(cswmDockSpace == "top"){var csdsAdjust=0;if(cswmCSDS){csdsAdjust=_csdsTop;}cswmTop=0+csdsAdjust;cswmButtonsObj.top = cswmTop + window.pageYOffset;if(cswmCSDS){_csdsCoopDock('cswm','top',parseInt(cswmButtonsObj.clip.height));}}else if(cswmDockSpace == "bottom"){var csdsAdjust=0;if(cswmCSDS){csdsAdjust=_csdsBottom;}cswmTop=(self.innerHeight)-cswmButtonsObj.clip.height-csdsAdjust;cswmButtonsObj.top = cswmTop + window.pageYOffset;if(cswmCSDS){_csdsCoopDock('cswm','bottom',parseInt(cswmButtonsObj.clip.height));}}cswmIsDock = true;}function cswmUnDock(){cswmDisplayDock(true);cswmButtonsObj.resizeTo(cswmButtonsWidth, cswmButtonsObj.clip.height);cswmIsDock = false;cswmDockSpace = "";if(cswmCSDS){_csdsCoopUnDock('cswm',parseInt(cswmButtonsObj.clip.height));}}function cswmDisplayDock(state){if(state){if(cswmDockSpace == "top"){var csdsAdjust=0;if(cswmCSDS){csdsAdjust=_csdsTop;}cswmDockObj.top=0+window.pageYOffset+csdsAdjust;}else{var csdsAdjust=0;if(cswmCSDS){csdsAdjust=_csdsBottom;}cswmDockObj.top=((self.innerHeight)-cswmDockObj.clip.height)+window.pageYOffset-csdsAdjust;}cswmDockObj.left = window.pageXOffset;cswmDockObj.visibility = "show";}else{cswmDockObj.visibility = "hidden";}}function cswmFloat(){if(cswmNeedPosInit){cswmMenuBarPos();}cswmButtonsObj.top = cswmTop + window.pageYOffset;cswmButtonsObj.left = cswmLeft + window.pageXOffset;}function cswmResize(){}function cswmMenuBarInit(){if(typeof(_csds)!='undefined'){cswmCSDS=true;if(_csdsZIndex<999){_csdsZIndex=999;}}cswmMenuBarPos();cswmDock('top');}var cswmOldPageYOffset = window.pageYOffset;var cswmOldPageXOffset = window.pageXOffset;setInterval('if (window.cswmOldPageYOffset != window.pageYOffset) cswmFloat(); window.cswmOldPageYOffset = window.pageYOffset; ', 25);setInterval('if (window.cswmOldPageXOffset != window.pageXOffset) cswmFloat(); window.cswmOldPageXOffset = window.pageXOffset; ', 25);
//-->

document.write("\r\n<!-- Coalesys WebMenu Studio -->\r\n<!-- WebMenu HTML Structure COPYRIGHT 2000-2002 Coalesys, Inc. -->\r\n<layer id=\"cswmPopupGroup_141c\" visibility=\"hidden\" onmouseout=\"cswmT(350)\" onmouseover=\"cswmT(\'off\')\"><layer id=\"cswmItemGroup_141c_0\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">Add New</layer><layer visibility=\"hide\" id=\"cswmItemHoverGroup_141c_0\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">Add New</layer><layer id=\"cswmItemMaskGroup_141c_0\" onmouseover=\"cswmHiI(\'Group_141c_0\',\'Group_141c\',1);cswmST(1)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=add_user\');\"></a></layer><layer id=\"cswmItemGroup_141c_1\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">View / Edit</layer><layer visibility=\"hide\" id=\"cswmItemHoverGroup_141c_1\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">View / Edit</layer><layer id=\"cswmItemMaskGroup_141c_1\" onmouseover=\"cswmHiI(\'Group_141c_1\',\'Group_141c\',1);cswmST(1)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=users_home\');\"></a></layer></layer><layer id=\"cswmPopupGroup_5208\" visibility=\"hidden\" onmouseout=\"cswmT(350)\" onmouseover=\"cswmT(\'off\')\"><layer id=\"cswmItemGroup_5208_0\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">Holiday<layer><img src=\"/images/holiday/popup.gif\" width=10 height=10 alt=\"\" border=0></layer></layer><layer visibility=\"hide\" id=\"cswmItemHoverGroup_5208_0\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">Holiday<layer><img src=\"/images/holiday/selectedpopup.gif\" width=10 height=10 alt=\"\" border=0></layer></layer><layer id=\"cswmItemMaskGroup_5208_0\" onmouseover=\"cswmHiI(\'Group_5208_0\',\'Group_5208\',1);cswmST(1,0,\'Group_5208_0\')\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);\"></a></layer><layer id=\"cswmItemGroup_5208_1\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">Sick<layer><img src=\"/images/holiday/popup.gif\" width=10 height=10 alt=\"\" border=0></layer></layer><layer visibility=\"hide\" id=\"cswmItemHoverGroup_5208_1\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">Sick<layer><img src=\"/images/holiday/selectedpopup.gif\" width=10 height=10 alt=\"\" border=0></layer></layer><layer id=\"cswmItemMaskGroup_5208_1\" onmouseover=\"cswmHiI(\'Group_5208_1\',\'Group_5208\',1);cswmST(1,1,\'Group_5208_1\')\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);\"></a></layer><layer id=\"cswmItemGroup_5208_2\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">Owed Days<layer><img src=\"/images/holiday/popup.gif\" width=10 height=10 alt=\"\" border=0></layer></layer><layer visibility=\"hide\" id=\"cswmItemHoverGroup_5208_2\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">Owed Days<layer><img src=\"/images/holiday/selectedpopup.gif\" width=10 height=10 alt=\"\" border=0></layer></layer><layer id=\"cswmItemMaskGroup_5208_2\" onmouseover=\"cswmHiI(\'Group_5208_2\',\'Group_5208\',1);cswmST(1,2,\'Group_5208_2\')\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);\"></a></layer><layer id=\"cswmItemGroup_5208_3\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">Other Reason<layer><img src=\"/images/holiday/popup.gif\" width=10 height=10 alt=\"\" border=0></layer></layer><layer visibility=\"hide\" id=\"cswmItemHoverGroup_5208_3\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">Other Reason<layer><img src=\"/images/holiday/selectedpopup.gif\" width=10 height=10 alt=\"\" border=0></layer></layer><layer id=\"cswmItemMaskGroup_5208_3\" onmouseover=\"cswmHiI(\'Group_5208_3\',\'Group_5208\',1);cswmST(1,3,\'Group_5208_3\')\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);\"></a></layer></layer><layer id=\"cswmPopup0\" visibility=\"hidden\" onmouseout=\"cswmT(350)\" onmouseover=\"cswmT(\'off\'); cswmHiI(\'Group_5208_0\',\'Group_5208\',1);\"><layer id=\"cswmItem0_0\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">One Days Holiday</layer><layer visibility=\"hide\" id=\"cswmItemHover0_0\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">One Days Holiday</layer><layer id=\"cswmItemMask0_0\" onmouseover=\"cswmHiI(\'0_0\',\'0\',2);cswmST(2)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=holiday\');\"></a></layer><layer id=\"cswmItem0_1\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">Several Days Holiday</layer><layer visibility=\"hide\" id=\"cswmItemHover0_1\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">Several Days Holiday</layer><layer id=\"cswmItemMask0_1\" onmouseover=\"cswmHiI(\'0_1\',\'0\',2);cswmST(2)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=holiday&multi=y\');\"></a></layer></layer><layer id=\"cswmPopup1\" visibility=\"hidden\" onmouseout=\"cswmT(350)\" onmouseover=\"cswmT(\'off\'); cswmHiI(\'Group_5208_1\',\'Group_5208\',1);\"><layer id=\"cswmItem1_0\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">One Day Sick</layer><layer visibility=\"hide\" id=\"cswmItemHover1_0\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">One Day Sick</layer><layer id=\"cswmItemMask1_0\" onmouseover=\"cswmHiI(\'1_0\',\'1\',2);cswmST(2)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=sick\');\"></a></layer><layer id=\"cswmItem1_1\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">Several Days Sick</layer><layer visibility=\"hide\" id=\"cswmItemHover1_1\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">Several Days Sick</layer><layer id=\"cswmItemMask1_1\" onmouseover=\"cswmHiI(\'1_1\',\'1\',2);cswmST(2)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=sick&multi=y\');\"></a></layer></layer><layer id=\"cswmPopup2\" visibility=\"hidden\" onmouseout=\"cswmT(350)\" onmouseover=\"cswmT(\'off\'); cswmHiI(\'Group_5208_2\',\'Group_5208\',1);\"><layer id=\"cswmItem2_0\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">One Owed Day</layer><layer visibility=\"hide\" id=\"cswmItemHover2_0\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">One Owed Day</layer><layer id=\"cswmItemMask2_0\" onmouseover=\"cswmHiI(\'2_0\',\'2\',2);cswmST(2)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=owed\');\"></a></layer><layer id=\"cswmItem2_1\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">Several Owed Days</layer><layer visibility=\"hide\" id=\"cswmItemHover2_1\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">Several Owed Days</layer><layer id=\"cswmItemMask2_1\" onmouseover=\"cswmHiI(\'2_1\',\'2\',2);cswmST(2)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=owed&multi=y\');\"></a></layer></layer><layer id=\"cswmPopup3\" visibility=\"hidden\" onmouseout=\"cswmT(350)\" onmouseover=\"cswmT(\'off\'); cswmHiI(\'Group_5208_3\',\'Group_5208\',1);\"><layer id=\"cswmItem3_0\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">One Day</layer><layer visibility=\"hide\" id=\"cswmItemHover3_0\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">One Day</layer><layer id=\"cswmItemMask3_0\" onmouseover=\"cswmHiI(\'3_0\',\'3\',2);cswmST(2)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=other\');\"></a></layer><layer id=\"cswmItem3_1\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">Several Days</layer><layer visibility=\"hide\" id=\"cswmItemHover3_1\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">Several Days</layer><layer id=\"cswmItemMask3_1\" onmouseover=\"cswmHiI(\'3_1\',\'3\',2);cswmST(2)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=add_holiday&reason=other&multi=y\');\"></a></layer></layer><layer id=\"cswmPopupGroup_6f59\" visibility=\"hidden\" onmouseout=\"cswmT(350)\" onmouseover=\"cswmT(\'off\')\"><layer id=\"cswmItemGroup_6f59_0\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">Days</layer><layer visibility=\"hide\" id=\"cswmItemHoverGroup_6f59_0\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">Days</layer><layer id=\"cswmItemMaskGroup_6f59_0\" onmouseover=\"cswmHiI(\'Group_6f59_0\',\'Group_6f59\',1);cswmST(1)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=view_day&day=today\');\"></a></layer><layer id=\"cswmItemGroup_6f59_1\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">Weeks</layer><layer visibility=\"hide\" id=\"cswmItemHoverGroup_6f59_1\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">Weeks</layer><layer id=\"cswmItemMaskGroup_6f59_1\" onmouseover=\"cswmHiI(\'Group_6f59_1\',\'Group_6f59\',1);cswmST(1)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=view_week&week=thisweek\');\"></a></layer><layer id=\"cswmItemGroup_6f59_2\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">Months</layer><layer visibility=\"hide\" id=\"cswmItemHoverGroup_6f59_2\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">Months</layer><layer id=\"cswmItemMaskGroup_6f59_2\" onmouseover=\"cswmHiI(\'Group_6f59_2\',\'Group_6f59\',1);cswmST(1)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=view_month&month=thismonth\');\"></a></layer></layer><layer id=\"cswmPopupGroup_8a7e\" visibility=\"hidden\" onmouseout=\"cswmT(350)\" onmouseover=\"cswmT(\'off\')\"><layer id=\"cswmItemGroup_8a7e_0\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">Customer Support</layer><layer visibility=\"hide\" id=\"cswmItemHoverGroup_8a7e_0\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">Customer Support</layer><layer id=\"cswmItemMaskGroup_8a7e_0\" onmouseover=\"cswmHiI(\'Group_8a7e_0\',\'Group_8a7e\',1);cswmST(1)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=customer_support\');\"></a></layer><layer id=\"cswmItemGroup_8a7e_1\" bgcolor=\"#d4d0c8\" class=\"cswmItem\">About WebKit</layer><layer visibility=\"hide\" id=\"cswmItemHoverGroup_8a7e_1\" bgcolor=\"#0a246a\" class=\"cswmItemOn\">About WebKit</layer><layer id=\"cswmItemMaskGroup_8a7e_1\" onmouseover=\"cswmHiI(\'Group_8a7e_1\',\'Group_8a7e\',1);cswmST(1)\" onmouseout=\"cswmST()\"><a href=\"\" onclick=\"cswmHP(0);get_xTree_query(\'&method=about_webkit\');\"></a></layer></layer><layer class=\"cswmNNDck\" id=\"cswmDock\" visibility=\"hidden\" bgcolor=\"#f0f0f0\">Dock</layer><layer class=\"cswmNNBtns\" id=\"cswmButtons\" bgcolor=\"#d4d0c8\"><table border=\"0\" cellspacing=\"0\" cellpadding=\"0\"><tr><td><span class=\"cswmNNBtn\"><a onmouseover=\"cswmButtonSelect(\'Group_141c\');\" onmouseout=\"cswmButtonUnSelect(\'Group_141c\');\" onmousedown=\"cswmButtonDown(\'Group_141c\');\" class=\"cswmNNBtnTxt\" href=\"javascript:void(0);\">Employees</a></span><img id=\"cswmImageGroup_141c\" name=\"cswmImageGroup_141c\" src=\"/images/holidayClearPixel.gif\" height=\"1\" width=\"1\"></td><td><span class=\"cswmNNBtn\"><a onmouseover=\"cswmButtonSelect(\'Group_5208\');\" onmouseout=\"cswmButtonUnSelect(\'Group_5208\');\" onmousedown=\"cswmButtonDown(\'Group_5208\');\" class=\"cswmNNBtnTxt\" href=\"javascript:void(0);\">Attendance</a></span><img id=\"cswmImageGroup_5208\" name=\"cswmImageGroup_5208\" src=\"/images/holidayClearPixel.gif\" height=\"1\" width=\"1\"></td><td><span class=\"cswmNNBtn\"><a onmouseover=\"cswmButtonSelect(\'Group_6f59\');\" onmouseout=\"cswmButtonUnSelect(\'Group_6f59\');\" onmousedown=\"cswmButtonDown(\'Group_6f59\');\" class=\"cswmNNBtnTxt\" href=\"javascript:void(0);\">View</a></span><img id=\"cswmImageGroup_6f59\" name=\"cswmImageGroup_6f59\" src=\"/images/holidayClearPixel.gif\" height=\"1\" width=\"1\"></td><td><span class=\"cswmNNBtn\"><a onmouseover=\"cswmButtonSelect(\'Group_8a7e\');\" onmouseout=\"cswmButtonUnSelect(\'Group_8a7e\');\" onmousedown=\"cswmButtonDown(\'Group_8a7e\');\" class=\"cswmNNBtnTxt\" href=\"javascript:void(0);\">Help</a></span><img id=\"cswmImageGroup_8a7e\" name=\"cswmImageGroup_8a7e\" src=\"/images/holidayClearPixel.gif\" height=\"1\" width=\"1\"></td></tr></table></layer>\r\n<!-- End WebMenu HTML -->\r\n\r\n");
