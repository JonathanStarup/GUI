pub type alias Display = {size = Display.Dimension, square = Display.Square}
mod Display {

pub type alias Point = {x = Int32, y = Int32}
pub type alias Dimension = {w = Int32, h = Int32}
pub type alias Square = {minCorner = Point, dim = Dimension}

pub def point(x: Int32, y: Int32): Point = {x = x, y = y}
pub def add(p1: Point, p2: Point): Point = {x = p1.x + p2.x, y = p1.y + p2.y}
pub def translate(p: Point, square: Square): Square = {
    minCorner = square.minCorner `add` p,
    dim = square.dim
}
pub def dimToPoint(dim: Dimension): Point = {x = dim.w, y = dim.h}
pub def maxCorner(square: Square): Point = square.minCorner `add` dimToPoint(square.dim)
pub def mapX(f: Int32 -> Int32, p: Point): Point = {x = f(p.x), y = p.y}
pub def mapY(f: Int32 -> Int32, p: Point): Point = {x = p.x, y = f(p.y)}

}
