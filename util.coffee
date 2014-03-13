define =>
  getCaretPosition = (ctrl)->
    carePos = 0
    if document.selection
      ctrl.focus();
      sel = moveStart 'character', -ctrl.value.length
      carePos = sel.text.length
    else if ctrl.selectionStart or ctrl.selectionStart is '0'
      carePos = ctrl.selectionStart
    carePos

  setCaretPosition = (ctrl, pos)->
    if ctrl.setSelectionRange
      ctrl.focus();
      ctrl.setSelectionRange pos, pos

    else if ctrl.createTextRange
      range = ctrl.createTextRange()
      range.collapse true
      range.moveEnd 'character', pos
      range.moveStart 'character', pos
      range.select();

  # 自动调整@列表的位置
  adjustPosition = ($elem)=>
    elemHeight = $elem.height()
    elemWidth = $elem.width()
    elemTop = $elem.position().top
    elemLeft = $elem.position().left
    if elemWidth + elemLeft + 10 > $(window).width()
      $elem.css 'left', elemLeft - elemWidth - 10
    if elemHeight + elemTop + 10 > $(window).height()
      $elem.css 'top', elemTop - elemHeight - 45

  exports = {
    getCaretPosition
    setCaretPosition
    adjustPosition
  }
