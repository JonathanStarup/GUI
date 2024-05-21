type alias App[ef: Eff] = {
    loopsPerSecond = Float64,
    size = Display.Dimension,
    title = String,
    loop = Unit -> Display \ ef
}

mod App {

pub def run(app: App[ef1], render: Display -> Unit \ ef2, quit: Unit -> Bool \ ef3): Unit \ {ef1, ef2, ef3, IO} = region rc {
    let frameTime = debug(frameTimeNano(app));
    let frameTimeInt64 = Float64.clampToInt64(frameTime, 1i64, 1_000_000_000i64, 0_033_333_333i64);
    let before = ref Time.Instant.now() @ rc;
    def tightLoop(): _ \ {ef1, ef2, ef3, rc, IO} = {
        let now = Time.Instant.now();
        if (Time.Instant.after(now, deref before)) {
            before := Time.Instant.plus(deref before, frameTimeInt64);
            render(app.loop())
        } else ();
        if (quit()) () else tightLoop()
    };
    tightLoop()
}

def frameTimeNano(app: App[ef]): Float64 = {
    1_000_000_000.0 / app.loopsPerSecond
}

}
