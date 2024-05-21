mod SwingRender {
use Display.{Square, Dimension}

pub def render(frame: ##javax.swing.JFrame, disp: Display): Unit \ IO = {
    import javax.swing.JFrame.getContentPane(): ##java.awt.Container \ IO;
    let container = getContentPane(frame);

    // make square
    let square = makeCanvas(disp.size, makeSquare(disp.square));

    // remove square
    import java.awt.Container.removeAll(): Unit \ IO;
    removeAll(container);
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

/// onClose must not use algebraic effects
pub def makeFrame(title: String, onClose: Unit -> any \ ef): ##javax.swing.JFrame \ IO = {
    import java_new javax.swing.JFrame(String): ##javax.swing.JFrame \ IO as newJFrame;
    let frame = newJFrame(title);
    import javax.swing.JFrame.setSize(Int32, Int32): Unit \ IO;
    setSize(frame, 400, 400);
    import javax.swing.JFrame.setResizable(Bool): Unit \ IO;
    setResizable(frame, false);
    import javax.swing.JFrame.setDefaultCloseOperation(Int32): Unit \ IO;
    import static java_get_field javax.swing.JFrame.DISPOSE_ON_CLOSE: Int32 \ IO as disposeOnClose;
    setDefaultCloseOperation(frame, disposeOnClose());
    import javax.swing.JFrame.addWindowListener(##java.awt.event.WindowListener): Unit \ IO;
    addWindowListener(frame)({
        new ##java.awt.event.WindowListener {
            def windowClosed(_this: ##java.awt.event.WindowListener, _e: ##java.awt.event.WindowEvent): Unit \ ef = {
                onClose();
                ()
            }
            def windowClosing(_this: ##java.awt.event.WindowListener, _e: ##java.awt.event.WindowEvent): Unit = ()
            def windowIconified(_this: ##java.awt.event.WindowListener, _e: ##java.awt.event.WindowEvent): Unit = ()
            def windowDeiconified(_this: ##java.awt.event.WindowListener, _e: ##java.awt.event.WindowEvent): Unit = ()
            def windowActivated(_this: ##java.awt.event.WindowListener, _e: ##java.awt.event.WindowEvent): Unit = ()
            def windowOpened(_this: ##java.awt.event.WindowListener, _e: ##java.awt.event.WindowEvent): Unit = ()
            def windowDeactivated(_this: ##java.awt.event.WindowListener, _e: ##java.awt.event.WindowEvent): Unit = ()
        }
    });
    import javax.swing.JFrame.setVisible(Bool): Unit \ IO;
    setVisible(frame, true);
    frame
}

pub def makeFrameWithClosed(title: String, rc: Region[r]): (##javax.swing.JFrame, Unit -> Bool \ r) \ IO + r = {
    let isClosed = ref false @ rc;
    let frame = makeFrame(title, () -> Ref.put(true, isClosed));
    (frame, () -> Ref.get(isClosed))
}

def makeSquare(square: Square, g: ##java.awt.Graphics2D): Unit \ IO = {
    import java_new java.awt.Color(Int32, Int32, Int32): ##java.awt.Color \ IO as newColor;
    import java.awt.Graphics2D.setColor(##java.awt.Color): Unit \ IO;
    setColor(g, newColor(54, 54, 54));
    import java.awt.Graphics2D.fillRect(Int32, Int32, Int32, Int32): Unit \ IO;
    fillRect(g, square.minCorner.x, square.minCorner.y, square.dim.w, square.dim.h)
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

}
