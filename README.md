# @ jQuery Plugin

## 使用方法
1. $textarea.at() //为textarea jquery选择器加入@功能
2. $textarea.on('at-mode-start', function(event,atObject){}) //@模式开启
   * 回调函数中的atObject : {  
        partName: 
          @type: String 
          @description: 获取full name时传入的part name  
        ,  
        renderNameList:    
          @type: function
          @param: 1. nameList(full name数组),  2. tooltips(@时的提示语，可选)   
          @description: 获取到full name之后, 渲染@中的提示名列表   } 
3. $textarea.on ('at-mode-stop', function() {}) //@模式关闭

## 代码示例
```coffeescript
      @doms['textarea'].at []
      @doms['textarea'].on 'at-mode-start', (event, at)=>
        isAtListShow = true
        @re.trigger 'server:users:retrieve-matched-friends-name-with-part-name', {partName: at.partName}, (data)=>
          if data.result is 'success'
            nameList = data.matchedFriendsName
            if nameList.length > 0 then tooltips = "选择昵称或轻敲空格完成输入"
            else tooltips = "轻敲空格完成输入"

            at.renderNameList nameList, tooltips
      @doms['textarea'].on 'at-mode-stop', ()->
        isAtListShow = false
```
