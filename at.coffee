define (require)->
  require 'css!./at'
  util = require './util'

  [UP_KEY, DOWN_KEY, LEFT_KEY, RIGHT_KEY, ENTER_KEY, SPACE_KEY, ESC_KEY, DELETE_KEY] = [38, 40, 37, 39, 13, 32, 27, 8]

  $.fn.at = ->
    @each ->
      $body = $ 'body'
      $input = $ this
      input = $input.get 0

      #-----------------name list -----------------
      isNameListShow = false
      $nameList = $('<ul class="name-list"></ul>')
      $nameList.append $('<li class="at-tips">选择最近@的人或直接输入</li>')
      $body.append $nameList
      nameList = []  
      selectedName = ''
      selectedNameOrder = 0

      renderNameList = (list, tooltips="按Enter键选择昵称")->
        nameList = list
        selectedName = nameList[0] #default 第一个
        selectedNameOrder = 0

        $nameList.find('li.at-tips:eq(0)').html tooltips
        i = 0
        $fragment = $()
        for name in nameList
          $nameItem = $('<li class="name-item" order=' + "#{i++}" + '>' + name + '</li>')
          if i is 1 then $nameItem.addClass 'high-light'
          $nameItem.on 'mouseenter', selectThisNameItem
          $nameItem.on 'click', insertSelectedNameIntoTextarea
          $fragment = $fragment.add $nameItem

        $nameList.find('li.name-item').remove()
        $nameList.append $fragment

      showNameList =  ->
        isNameListShow = true
        $nameList.show()

      hideNameList = ->
        isNameListShow = false
        $nameList.hide()

      selectThisNameItem = (event)->
        $item = $(event.target)
        order = parseInt ($item.attr 'order')
        selectedName = nameList[order]
        selectedNameOrder = order
        highLightSelectedNameItem()

      selectNameFromNameList = (direction)->
        if direction is 'up'
          if selectedNameOrder - 1 >= 0
            selectedNameOrder -= 1
          else
            selectedNameOrder = nameList.length - 1
        else if direction is 'down'
          if selectedNameOrder + 1 <= nameList.length - 1
            selectedNameOrder += 1
          else
            selectedNameOrder = 0
        selectedName = nameList[selectedNameOrder]
        highLightSelectedNameItem()

      highLightSelectedNameItem = ->
        $nameList.find('li.high-light').removeClass 'high-light'
        $nameList.find("li.name-item:eq(#{selectedNameOrder})").addClass 'high-light'

      #-------------------@的主要逻辑-------------------

      currentCursorPos = 0 
      lastAtPos = 0
      isActive = false      # 开启了@

      # @时，禁掉这些键默认的上下移动光标，换行的行为
      $input.on 'keydown', (event)->
        keyCode = event.keyCode
        if isActive and (keyCode is UP_KEY or keyCode is DOWN_KEY or keyCode is ENTER_KEY)
          event.preventDefault()

      $input.on 'keyup', (event)->
        keyCode = event.keyCode
        # 上下左右，删除键，都是会改变光标位置的,这个时候应当判断： 光标与他左边最近的@之间是否连续, 之间是有效字符, _中文，英文
        if  keyCode is LEFT_KEY or keyCode is RIGHT_KEY or keyCode is DELETE_KEY
          $input.trigger 'cursor-position-changed'
          return

        if not isActive and (keyCode is UP_KEY or keyCode is DOWN_KEY)
          $input.trigger 'cursor-position-changed'
          return

        if isActive 
          if keyCode is ENTER_KEY #选中full name, stop @
            insertSelectedNameIntoTextarea()
            isActive = false
            $input.trigger 'at-mode-stop'
            return

          if keyCode is ESC_KEY #退出@
            isActive = false
            $input.trigger 'at-mode-stop'
            return

          if keyCode is SPACE_KEY            #输入中文的时候，空格键完成输入，这个要区分
            textContent = $input.val()
            lastChar = textContent[util.getCaretPosition(input) - 1]
            if lastChar is ' ' then stopAtMode()

          if keyCode is UP_KEY or keyCode is DOWN_KEY           #上下选择
            direction = if keyCode is UP_KEY then 'up' else 'down'
            selectNameFromNameList direction
            return

      $input.on 'input', ->
        if isActive then $input.trigger 'cursor-position-changed'
        else
          textContent = $input.val()
          lastChar = textContent[util.getCaretPosition(input) - 1]
          if lastChar is '@' 
            $input.trigger 'cursor-position-changed'

      $input.on 'click', ->
        $input.trigger 'cursor-position-changed'

      $input.on 'blur', ->
        isActive = false
        setTimeout ->
          $input.trigger 'at-mode-stop'
        , 200

      $input.on 'cursor-position-changed',->
        handleCursorPositionChanged()
        setInputDuplicateAndResetNameListPostion()

      $input.on 'at-mode-start', showNameList

      $input.on 'at-mode-stop', hideNameList


      handleCursorPositionChanged = ->
        textContent = $input.val()
        currentCursorPos = util.getCaretPosition input
        lastAtPos = getLastAtPos()
        if $.trim(textContent) is ''
          if isActive then stopAtMode()
          return
        if lastAtPos > 0                    #如果有@，便截取这一段，判断其是否连续
          partName = textContent.slice lastAtPos, currentCursorPos
          if isValidPartName partName 
            $input.trigger 'at-mode-start', {partName, renderNameList}
            isActive = true   
          else if isActive
            stopAtMode()
            return
        else if isActive
          stopAtMode()
          return

      getLastAtPos = ->
        textContent = $input.val()
        i = currentCursorPos-1
        while i >=0 and textContent[i] isnt '@'
          i--
        i+1               #返回的是@后面的光标位置

      stopAtMode = ->
        isActive = false
        $input.trigger 'at-mode-stop'

      isValidPartName = (partName)->
        #有效的partName: '', 下划线，中文，英文
        regex = /[a-zA-Z0-9\u4e00-\u9fa5_]/
        if partName is '' then return true
        for char in partName
          if char is '\\' then return false
          if not regex.test char then return false
        true

      insertSelectedNameIntoTextarea = ->
        if nameList.length is 0 then return
        fullName = selectedName
        selectedName = ''
        textContent = $input.val()
        contentBeforeLastAt = textContent.slice 0, lastAtPos
        contentAfterCursor = textContent.slice currentCursorPos
        fullName += ' '
        $input.val contentBeforeLastAt + fullName + contentAfterCursor
        util.setCaretPosition input, contentBeforeLastAt.length + fullName.length



      # --------------- cursor track 光标位置跟随 ------
      $inputDuplicate = $('<pre class="input-duplicate"></pre>')
      $cursorDuplicate = null

      styleOfInputDuplicate = 
        'width': $input.width() + 1
        'height': $input.height()
        'font': $input.css('font')
        'padding': $input.css('padding')
        'border': $input.css('border')
        'overflow': $input.css('overflow')

        'word-wrap': 'break-word'
        'margin': 0
        'position': 'absolute'
        'left': 0
        'top': 0

        'background-color': 'transparent'
        'color': 'transparent'
        'border-color': 'transparent'
        'z-index': '-100000'

      fontSize = parseInt $input.css('font-size')
      $inputDuplicate.css styleOfInputDuplicate
      $body.append $inputDuplicate

      setInputDuplicateAndResetNameListPostion = ->
        setInputDuplicate()
        resetNameListPositionBasedOnPositionOfCursor()
      
      setInputDuplicate = ->
        setInputDuplicateContent()
        setInputDuplicateStyle()

      setInputDuplicateContent = ->
        textContent = $input.val()
        contentBeforeCursor = textContent.slice 0, util.getCaretPosition(input)
        $inputDuplicate.text contentBeforeCursor
        $cursorDuplicate = $('<span class="cursor-duplicate">')
        $cursorDuplicate.css 
          'display': 'inline-block'
          'width': '1px'
          'height': fontSize + 'px'
        $inputDuplicate.append $cursorDuplicate

      setInputDuplicateStyle = ->
        scrollTop = $input.scrollTop()
        scrollLeft = $input.scrollLeft()
        $inputDuplicate.scrollTop scrollTop
        $inputDuplicate.scrollLeft scrollLeft
        $inputDuplicate.css 
          'width': $input.width() - 1
          'height': $input.height - 1

      hasListen = false
      resetNameListPositionBasedOnPositionOfCursor = ->
        detalTop = 0
        if not hasListen
          hasListen = true
          # 监听host-page滚动事件，以及window resize事件，及时调整@列表
          $(document).on 'window-action-change', ->
            setTimeout resetNameListPositionBasedOnPositionOfCursor, 0
          $(window).on 'resize', resetNameListPositionBasedOnPositionOfCursor
        inputRect = input.getBoundingClientRect()
        cursorRect = $cursorDuplicate[0].getBoundingClientRect()
        position = 
          'left': inputRect.left + cursorRect.left
          'top': inputRect.top + cursorRect.top +  fontSize* 2
        $nameList.css position
        util.adjustPosition $nameList

