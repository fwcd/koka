// Note: this corresponds to the implicit paper but we changed
// the name to ambients instead and moved tests to the `test/ambients` directory.
implicit val width : int

fun f() {
  //with val width = 78
  val g = with val width = 80 in (fn(){ width + 1 })
  val h = fn() { with val width = 80 in width + 1 }
  g().println
  h().println
}

fun half(action) {
  with val width = width / 2
  action()
}


implicit val emitx : ((s:string) -> io ())

fun emit1(action) {
  with val emitx = fn( s : string ){ s.println }
  action()
}

implicit fun emit( s : string ) : ()

fun pretty-emit1(action) {
  try {
    with fun emit(s) { s.println }
    action()
  }
}

// dynamic binding with local reasoning
fun pretty-emit2(action) {
  with fun emit(s) { s.truncate(width).println }
  action()
}

// with lexically scoped state
fun pretty-emit(action) {
  var out := ""
  with fun emit(s) { out := out + s + "\n" } in action()
  out
}

implicit state<s> {
  fun get()      : s
  fun set(x : s) : ()
}

fun state1(action) {
  var s := 0
  with {
    fun get()  { s }
    fun set(x) { s := x }
  }
  action()
}


implicit fun total() : int

fun emit4(action) {
  var out := ""
  with return(x) { out }
  with fun emit(s) { out := out + s + "\n" }
  with fun total() { out.count }
  action()
}

implicit fun abort() : ()

fun pretty-abort(action) {
  with pretty-emit
  with control abort() { () }
  action()
}

implicit control choice() : bool

fun pretty-all(action) {
  with control choice() { resume(True) + (resume(False) : list<string>) }
  [pretty-abort(action)]
}


fun pretty-all2(action) {
  with control choice() { resume(True) + (resume(False) : list<string>) }
  with return(x) { [x] }
  pretty-abort(action)
}

fun state2(init,action) {
  val f = with {
            control get()  { (fn(s) { resume(s)(s) }) }
            control set(x) { (fn(s) { resume(())(x) }) }
          } in {
            val x = action()
            (fn(s) { x })
          }
  f(init)
}


implicit val cwd : string

fun is-home() {
  cwd == "/home"
}

fun test1() {
  with val cwd = "/"
  is-home()
}


fun gchildren( g : graph, v : vertex ) : list<vertex> {
  []
}

fun bound( g : graph ) {
  10
}

alias vertex = int;
struct graph()
struct rose(v : vertex, sub : list<rose> )


implicit fun marked( v : vertex ) : bool
implicit fun mark( v : vertex ) : ()
implicit fun children( v : vertex ) : list<vertex>

fun dfs( g : graph, vs : list<vertex> ) : pure list<rose> {
  var visited := vector(g.bound,False)
  with fun children(v) { g.gchildren(v) }
  with fun marked(v)   { visited[v] }
  with fun mark(v)     { visited[v] := True }
  dfs-loop(vs)
}

fun dfs-loop( vs : list<vertex> ) {
  match(vs) {
    Nil -> Nil
    Cons(v,vv) ->
      if (marked(v)) then dfs-loop(vv) else {
        mark(v)
        val sub = dfs-loop( children(v) )
        Cons( Rose(v,sub), dfs-loop(vv) )
      }
  }
}

fun main() {
  (with val width = 78 in f().println)
  (with val width = 78 in half(f).println)
  (with val cwd = "/" in is-home().println)
}
