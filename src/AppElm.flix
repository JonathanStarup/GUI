type alias AppElm[model, msg, display] = {
    init = model,
    update = (msg, model) -> model,
    view = model -> display
}
