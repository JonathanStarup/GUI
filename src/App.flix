type alias App[ef: Eff] = {
    loopsPerSecond = Float64,
    size = Display.Dimension,
    title = String,
    loop = Unit -> Display \ ef
}

mod App {

pub def run(app: App[ef1], render: Display -> Unit \ ef2, quit: Unit -> Bool \ ef3): Unit \ {ef1, ef2, ef3, IO} = region rc {
    let frameTime = frameTimeMillis(app);
    let frameTimeInt32 = Float64.clampToInt32(frameTime, 1, 2000, 33);
    let frameTimeInt64 = Int32.toInt64(frameTimeInt32);
    let waitingTime = Time.Duration.fromMilliSeconds(frameTimeInt32 / 6);
    let before = ref Time.Instant.now() @ rc;
    def tightLoop(): _ \ {ef1, ef2, ef3, rc, IO} = {
        let now = Time.Instant.now();
        if (Time.Instant.after(now, deref before)) {
            before := Time.Instant.plus(deref before, frameTimeInt64);
            render(app.loop());
            // avoid budy idling for slow framerate
            Thread.sleep(waitingTime)
        } else ();
        if (quit()) () else tightLoop()
    };
    tightLoop()
}

def frameTimeMillis(app: App[ef]): Float64 = {
    1000.0 / app.loopsPerSecond
}

}
