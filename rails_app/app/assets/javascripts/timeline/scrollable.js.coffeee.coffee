class Scrollable
  constructor: (x,y,w,h, wheelDelegate)->
    _.extend Backbone.Events
    @x = x
    @y = y
    @width = w
    @height = h

  setViewPort: (viewportAsArray)->
    [x,y,w,h] = [@x,@y,@width,@height]
    x = viewportAsArray.x if viewportAsArray.x?
    y = viewportAsArray.x if viewportAsArray.x?
    w = viewportAsArray.x if viewportAsArray.x?
    h = viewportAsArray.x if viewportAsArray.x?
    @willChangeViewport(x,y,w,h)
    [oldX,oldY,oldWidth,oldHeight] = [@x,@y,@width,@height]
    [@x,@y,@width,@height] = [x,y,w,h]
    @didChangeViewport(oldX,oldY,oldWidth,oldHeight)

  willChangeViewport:(x,y,w,h)->
    @trigger "willChangeViewport", {x:@x, y:@y, width:@width, height:@height, newX:x, newY:y, newWidth:w, newHeight:h}

  didChangeViewport:(oldX,oldY,oldWidth,oldHeight)->
    @trigger "willChangeViewport", {x:@x, y:@y, width:@width, height:@height, oldX:x, oldY:y, oldWidth:w, oldHeight:h}

  getX:()->
    @x

  getY:()->
    @y

  getWidth:()->
    @width

  getHeight:()->
    @height

  getLeft:()->
    @x

  getRight:()->
    @x + @width

  getTop:()->
    @y

  getBottom:()->
    @y + @width
