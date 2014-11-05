document.onkeydown = cancelRefresh;

function cancelRefresh() {
  if (window.event && window.event.keyCode == 116) {
    window.event.keyCode = 8;
  }
  if (window.event && window.event.keyCode == 8) {
    window.event.cancelBubble = true;
    window.event.returnValue = false;
    return false;
  }
}