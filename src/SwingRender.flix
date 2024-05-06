mod SwingRender {
use Display.{Square, Dimension}

pub def render(frame: ##javax.swing.JFrame, disp: Display): Unit \ IO = {
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

pub def makeFrame(title: String): ##javax.swing.JFrame \ IO = {
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

pub def isClosed(frame: ##javax.swing.JFrame): Bool \ IO = {
    import javax.swing.JFrame.isDisplayable(): Bool \ IO;
    not isDisplayable(frame)
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
