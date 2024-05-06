use Display.{Point, Dimension, Square, mapY, mapX, translate, point, maxCorner}

def main(): Unit \ IO = region rc {
    let app = bouncySquare(rc, {w=50, h=50}, 3,{w=400, h=300});
    let frame = SwingRender.makeFrame(app.title);
    App.run(app, SwingRender.render(frame), () -> SwingRender.isClosed(frame))
}

def bouncySquare(rc: Region[r], square: Dimension, speed: Int32, bounding: Dimension): App[r] \ r = {
    let sq = ref {minCorner = point(0, 0), dim = square} @ rc;
    let velo = ref point(speed, speed) @ rc;

    def loop(): Display \ r = {
        // move box
        let moved = (deref sq) |> translate(deref velo);
        let maxC = maxCorner(moved);
        let minC = moved.minCorner;
        if (maxC.y > bounding.h) velo := mapY(y -> -y, deref velo) else ();
        if (maxC.x > bounding.w) velo := mapX(x -> -x, deref velo) else ();
        if (minC.y < 0) velo := mapY(y -> -y, deref velo) else ();
        if (minC.x < 0) velo := mapX(x -> -x, deref velo) else ();
        sq := (deref sq) |> translate(deref velo);
        // create display
        {size = bounding, square = deref sq}
    };
    {
        title = "BouncySquare",
        size = bounding,
        loopsPerSecond = 20.0,
        loop = loop
    }
}
