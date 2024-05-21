use Display.{Dimension, point, translate, mapY, mapX, maxCorner, Square, Point}

enum Looping[msg] {
    case Fixed(Unit -> List[msg])
    case AfterRender(Unit -> List[msg])
}

type alias AppElm[model, msg, display] = {
    init = model,
    update = (msg, model) -> model,
    view = model -> display,

    triggers = List[Looping[msg]]
}

def main(): Unit \ IO = region rc {
    let (frame, isClosed) = SwingRender.makeFrameWithClosed("Bouncy Square", rc);
    run(bouncySquareElm({w=50, h=50}, 3, {w=400, h=300}), SwingRender.render(frame), isClosed)
}

// TODO fixed updates funs asap
def run(app: AppElm[model, msg, display], render: display -> Unit \ ef2, quit: Unit -> Bool \ ef3): Unit \ {ef1, ef2, ef3, IO} = region rc {
    let nextFixed = ref Time.Instant.now() @ rc;

    let model = ref app.init @ rc;
    let msgs = MutDeque.empty(rc);

    def updates(): _ \ rc = match MutDeque.popFront(msgs) {
        case None => ()
        case Some(msg) =>
            model |> Ref.transform(app.update(msg));
            updates()
    };

    def tightLoop(): _ \ {ef1, ef2, ef3, rc, IO} = {
        let now = Time.Instant.now();
        if (Time.Instant.after(now, deref nextFixed)) {
            nextFixed := Time.Instant.plus(deref nextFixed, 1000i64);
            foreach (trigger <- app.triggers) match trigger {
                case Looping.Fixed(f) => f() |> List.forEach(x -> MutDeque.pushBack(x, msgs))
                case _ => ()
            }
        } else ();
        render(app.view(deref model));
        foreach (trigger <- app.triggers) match trigger {
            case Looping.AfterRender(f) => f() |> List.forEach(x -> MutDeque.pushBack(x, msgs))
            case _ => ()
        };
        updates();
        if (quit()) () else tightLoop()
    };
    tightLoop()
}

def frameTimeMillis(_app: AppElm[mode, msg, display]): Float64 = {
    1000.0 / 5.0
}


type alias Model = {sq = Square, velo = Point}
def bouncySquareElm(square: Dimension, speed: Int32, bounding: Dimension): AppElm[Model, Unit, Display] = {
    let initSquare = {minCorner = point(0, 0), dim = square};
    let initVelo = point(speed, speed);
    let initModel = {sq = initSquare, velo = initVelo};

    def reflect(v0, s0) = {
        let maxC = maxCorner(s0);
        let minC = s0.minCorner;
        let v1 = if (maxC.y > bounding.h) mapY(y -> -y, v0) else v0;
        let v2 = if (maxC.x > bounding.w) mapX(x -> -x, v1) else v1;
        let v3 = if (minC.y < 0) mapY(y -> -y, v2) else v2;
        if (minC.x < 0) mapX(x -> -x, v3) else v3
    };

    def update(_msg, model): Model = {
        // move box
        let moved = model.sq |> translate(model.velo);
        let reflectedVelo = reflect(model.velo, moved);
        let newSquare = model.sq |> translate(reflectedVelo);
        // create display
        {sq = newSquare, velo = reflectedVelo}
    };

    let trigger = Looping.Fixed(
        () -> () :: Nil
    );

    def view(model): Display = {
        size = bounding,
        square = model.sq
    };

    {
        init = initModel,
        triggers = trigger :: Nil,
        update = update,
        view = view
    }
}
