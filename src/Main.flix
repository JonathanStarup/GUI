type alias Point = {x = Int32, y = Int32}
type alias Dimension = {w = Int32, h = Int32}
type alias Square = {minCorner = Point, dim = Dimension}
type alias Display = {size = Dimension, square = Square}

def point(x: Int32, y: Int32): Point = {x = x, y = y}
def add(p1: Point, p2: Point): Point = {x = p1.x + p2.x, y = p1.y + p2.y}
def translate(p: Point, square: Square): Square = {
    minCorner = square.minCorner `add` p,
    dim = square.dim
}
def dimToPoint(dim: Dimension): Point = {x = dim.w, y = dim.h}
def maxCorner(square: Square): Point = square.minCorner `add` dimToPoint(square.dim)
def mapX(f: Int32 -> Int32, p: Point): Point = {x = f(p.x), y = p.y}
def mapY(f: Int32 -> Int32, p: Point): Point = {x = p.x, y = f(p.y)}

type alias App[ef: Eff] = {
    loopsPerSecond = Float64,
    size = Dimension,
    title = String,
    loop = Unit -> Display \ ef
}

def main(): Unit \ IO = region rc {
    run(bouncySquare(rc, {w=50, h=50}, 3,{w=400, h=300}))
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

def makeFrame(title: String): ##javax.swing.JFrame \ IO = {
    // make frame
    import java_new javax.swing.JFrame(String): ##javax.swing.JFrame \ IO as newJFrame;
    let frame = newJFrame(title);
    import javax.swing.JFrame.setSize(Int32, Int32): Unit \ IO;
    setSize(frame, 400, 400);
    import javax.swing.JFrame.setResizable(Bool): Unit \ IO;
    setResizable(frame, false);
    import javax.swing.JFrame.setDefaultCloseOperation(Int32): Unit \ IO;
    import static java_get_field javax.swing.JFrame.DISPOSE_ON_CLOSE: Int32 \ IO as disposeOnClose;
    setDefaultCloseOperation(frame, disposeOnClose());
    import javax.swing.JFrame.setVisible(Bool): Unit \ IO;
    setVisible(frame, true);
    frame
}

def makeCanvas(size: Dimension, f: ##java.awt.Graphics2D -> Unit \ IO): ##javax.swing.JComponent \ IO = {
    new ##javax.swing.JComponent {
        def paint(_this: ##javax.swing.JComponent, g: ##java.awt.Graphics): Unit \ IO = {
            f(unchecked_cast (g as ##java.awt.Graphics2D))
        }
        def getPreferredSize(_this: ##javax.swing.JComponent): ##java.awt.Dimension \ IO = {
            checked_ecast (());
            import java_new java.awt.Dimension(Int32, Int32): ##java.awt.Dimension \ IO as newDimension;
            newDimension(size.w, size.h)
        }
    }
}

def makeSquare(square: Square, g: ##java.awt.Graphics2D): Unit \ IO = {
    import java_new java.awt.Color(Int32, Int32, Int32): ##java.awt.Color \ IO as newColor;
    import java.awt.Graphics2D.setColor(##java.awt.Color): Unit \ IO;
    setColor(g, newColor(54, 54, 54));
    import java.awt.Graphics2D.fillRect(Int32, Int32, Int32, Int32): Unit \ IO;
    fillRect(g, square.minCorner.x, square.minCorner.y, square.dim.w, square.dim.h)
}

def render(frame: ##javax.swing.JFrame, disp: Display): Unit \ IO = {
    // clear
    import javax.swing.JFrame.getContentPane(): ##java.awt.Container \ IO;
    let container = getContentPane(frame);
    import java.awt.Container.removeAll(): Unit \ IO;
    removeAll(container);

    // make square
    let square = makeCanvas(disp.size, makeSquare(disp.square));

    // add square
    import java.awt.Container.add(##java.awt.Component): ##java.awt.Component \ IO;
    add(container, checked_cast (square));
    import javax.swing.JFrame.pack(): Unit \ IO;
    pack(frame);
    import javax.swing.JFrame.validate(): Unit \ IO;
    validate(frame);
    import javax.swing.JFrame.repaint(): Unit \ IO;
    repaint(frame)
}

def frameTimeMillis(app: App[ef]): Float64 = {
    1000.0 / app.loopsPerSecond
}

def isClosed(frame: ##javax.swing.JFrame): Bool \ IO = {
    import javax.swing.JFrame.isDisplayable(): Bool \ IO;
    not isDisplayable(frame)
}

def run(app: App[ef]): Unit \ ef + IO = region rc {
    let frame = makeFrame(app.title);
    let frameTime = frameTimeMillis(app);
    let frameTimeInt32 = Float64.clampToInt32(frameTime, 1, 2000, 33);
    let frameTimeInt64 = Int32.toInt64(frameTimeInt32);
    let waitingTime = Time.Duration.fromMilliSeconds(frameTimeInt32 / 6);
    let before = ref Time.Instant.now() @ rc;
    def tightLoop() = {
        let now = Time.Instant.now();
        if (Time.Instant.after(now, deref before)) {
            before := Time.Instant.plus(deref before, frameTimeInt64);
            render(frame, app.loop());
            // avoid budy idling for slow framerate
            Thread.sleep(waitingTime)
        } else ();
        if (isClosed(frame)) () else tightLoop()
    };
    tightLoop()
}
