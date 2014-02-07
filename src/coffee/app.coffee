Array.prototype.random = ->
    @[Math.floor(Math.random() * @length)]

class Board
    constructor: (@width, @height) ->
        @colors =
            empty: "#FFFFFF"
            red: "#EE6699"
            blue: "#3300EE"
            black: "#000000"
            lgreen: "#00BB77"
            dgreen: "#008822"
            yellow: "#E7FF69"
            purple: "#660033"
            brown: "#331900"

        @size = 25
        @border = 5
        @space = @size + @border

        @canvasEl = document.getElementById 'tetris'
        @canvasEl.width = @width * (@size + @border)
        @canvasEl.height = @height * (@size + @border)
        @ctx = @canvasEl.getContext '2d'

        @tiles = []

        for wi in [0...@width]
            h = []
            for hi in [0...@height]
                h.push "empty"
            @tiles.push h

    draw: (activeShape) ->
        @ctx.clearRect 0, 0, @canvasEl.width, @canvasEl.height

        # draw static tiles
        for h_arr, x in @tiles
            for color, y in h_arr
                @ctx.fillStyle = @colors[color]
                @ctx.fillRect (x*@space), (y*@space), @size, @size
        # draw active shape
        if activeShape
            @ctx.fillStyle = @colors[activeShape.color]
            for tile in activeShape.tiles
                @ctx.fillRect (tile.x*@space), (tile.y*@space), @size, @size

    add: (activeShape) ->
        for tile in activeShape.tiles
            @tiles[tile.x][tile.y] = activeShape.color

    collision: (activeShape, movement) ->
        # side, bottom, or shape
        for tile in activeShape.tiles

            tileCompareX = @tiles[tile.x + movement.x]
            if tileCompareX
                tileCompare = tileCompareX[tile.y + movement.y]
                if (typeof tileCompare is "undefined") or tileCompare isnt "empty"
                    return true
            else
                return true
        return false

    fullLines: ->
        lines = []
        for y in [0...@height]
            full = true
            for x in [0...@width]
                if @tiles[x][y] is "empty"
                    full = false
                    break
            if full
                lines.push(y)

        console.log lines
        return lines

    lines: (animationSpeed) ->
        # clear any lines
        fullLines = @fullLines()

        if not fullLines
            return 0

        for line in fullLines
            for x in [0...@width]
                @tiles[x][line] = "black"
        @draw()

        # shift down... picked up next draw
        for line in fullLines
            for x in [0...@width]
                @tiles[x].splice(line, 1)
                @tiles[x].unshift "empty"

        # return number of found lines
        return fullLines.length

class Game
    constructor: ->
        @board = new Board(8, 12)
        @speed = 500
        @bindKeyboard()

        @lines = 0

    updateScore: ->
        score = 
            if @playing
                @lines
            else
                "GAMEOVER - Score: #{@lines}"

        document.getElementById("lines").innerHTML = score

    bindKeyboard: ->
        window.onkeydown = (e) =>
            if @playing
                toMove = 
                    switch e.keyCode
                        when 39 then 1 #right
                        when 37 then -1 #left
                        else 0

                if toMove
                    if not @board.collision @activeShape, {x:toMove,y:0}
                        for tile in @activeShape.tiles
                            tile.x += toMove
                        @board.draw @activeShape

                else if e.keyCode is 38
                    # pick a random point and pivot around it...
                    pivot = @activeShape.tiles.random()

                    newTiles = []
                    for tile in @activeShape.tiles
                        xOffset = pivot.x - tile.x
                        yOffset = pivot.y - tile.y
                        newX = pivot.x - yOffset
                        newY = pivot.y + xOffset
                        newTiles.push({x:newX, y:newY})
                    newShape = {tiles: newTiles, color:@activeShape.color, type:@activeShape.type}
                    if not @board.collision newShape, {x:0, y:0}
                        @activeShape = newShape
                        @board.draw @activeShape

                else if e.keyCode is 40
                    if not @board.collision @activeShape, {x:0,y:1}
                        for tile in @activeShape.tiles
                            tile.y += 1
                        @board.draw @activeShape

    play: ->
        @playing = true
        @activeShape = @newPiece()
        @board.draw @activeShape

        tick = =>

            bottom = @board.collision @activeShape, {x:0, y:1}

            if not bottom
                for tile in @activeShape.tiles
                    tile.y += 1
                setTimeout tick, @speed
            else
                console.log "shape reached bottom"
                @board.add @activeShape
                @activeShape = @newPiece()
                setTimeout tick, @speed*4

                @lines += @board.lines @speed*2
                @updateScore()


            @board.draw @activeShape

        # kick us off
        setTimeout tick, @speed

    newPiece: ->
        options = ["box", "line", "l", "r", "pyramid", "ldag", "rdag"]
        shapeType = options.random()
        console.log "new shape: #{shapeType}"
        shape = 
            switch shapeType
                when "box"
                    tiles: [{x:0,y:0},{x:0,y:1},{x:1,y:0},{x:1,y:1}]
                    color: "blue"
                when "line"
                    tiles:  [{x:0,y:0},{x:1,y:0},{x:2,y:0},{x:3,y:0}]
                    color: "red"
                when "l"
                    tiles:  [{x:0,y:0},{x:1,y:0},{x:2,y:0},{x:0,y:1}]
                    color: "lgreen"
                when "r"
                    tiles:  [{x:0,y:0},{x:1,y:0},{x:2,y:0},{x:2,y:1}]
                    color: "dgreen"
                when "pyramid"
                    tiles:  [{x:0,y:0},{x:1,y:0},{x:2,y:0},{x:1,y:1}]
                    color: "yellow"
                when "ldag"
                    tiles:  [{x:0,y:0},{x:1,y:0},{x:2,y:1},{x:1,y:1}]
                    color: "purple"
                when "rdag"
                    tiles:  [{x:0,y:1},{x:1,y:1},{x:2,y:0},{x:1,y:0}]
                    color: "brown"
                else
                    throw "wrong shape type: #{shapeType}"

        shape.type = shapeType
        if @board.collision shape, {x:0, y:0}
            @gameover()

        return shape

    gameover: ->
        @playing = false
        console.log "gameover"
        @updateScore()
        throw "gameover"


game = new Game()
game.play()
