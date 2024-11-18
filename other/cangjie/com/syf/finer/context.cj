
public open class JsonContext {
    var tabs_: Int
    public mut prop tabs: Int {
        get() {
            tabs_
        }
        set(tabs) {
            tabs_ = tabs
        }
    }
    JsonContext(tabs!:Int = 0) {this.tabs_ = tabs}
}