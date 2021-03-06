~ MathDefs
\newcommand{\pdv}[1]{\frac{\partial{}}{\partial{#1}}}
~

# A Tour of Koka { #tour }

This is a short introduction to the Koka programming language.

Koka is a _function-oriented_ language that separates pure values from
side-effecting computations (The word 'k&omacron;ka' (or &#x52B9;&#x679C;) means
"effect" or "effective" in Japanese). Koka is also
flexible and `fun`: Koka has many features that help programmers to easily
change their data types and code organization correctly even in large-scale
programs, while having a small strongly-typed language core with a familiar
brace syntax.

## Basics { #sec-basics }

### Hello world

As usual, we start with the familiar _Hello world_ program:<span id=`examplemain`></span>
```
fun main() {
  println("Hello world!") // println output
}
```
Koka uses familiar curly-braces syntax where `//` starts a line
comment. Functions are declared using the `fun` keyword (and anonymous functions with `fn`).

Here is another short example program that encodes a string using the
_Caesar cipher_, where each lower-case letter in a string is replaced by the letter
three places up in the alphabet:

```
fun main() { println(caesar("koka is fun")) }
////
fun encode( s : string, shift : int )
{
  fun encode-char(c) {
    if (c < 'a' || c > 'z') return c
    val base = (c - 'a').int
    val rot  = (base + shift) % 26
    (rot.char + 'a')
  }
  s.map(encode-char)
}

fun caesar( s : string ) : string {
  s.encode( 3 )
}
```

In this example, we declare a local function `encode-char` which encodes a
single character `c`. The final statement `s.map(encode-char)` applies the
`encode-char` function to each character in the string `s`, returning a
new string where each character is Caesar encoded. The result of the final
statement in a function is also the return value of that function, and you can
generally leave out an explicit `return` keyword.

### Dot selection {#sec-dot}

Koka is a _function-oriented_ language where _functions_ and _data_ form the
core of the language (in contrast to objects for example). In particular, the
expression `s.encode(3)` does _not_ select the `encode` method from the
`:string` object, but it is simply syntactic sugar for the function call
`encode(s,3)` where `s` becomes the first argument. Similarly, `c.int`
converts a character to an integer by calling `int(c)` (and both expressions
are equivalent). The dot notation is intu&iuml;tive and quite convenient to
chain multiple calls together, as in:

```
fun showit( s : string ) { s.encode(3).count.println }
```

for example (where the body desugars as `println(length(encode(s,3)))`). An
advantage of the dot notation as syntactic sugar for function calls is that it
is easy to extend the 'primitive' methods of any data type: just write a new
function that takes that type as its first argument. In most object-oriented
languages one would need to add that method to the class definition itself
which is not always possible if such class came as a library for example.

### Type Inference

Koka is also strongly typed. It uses a powerful type inference engine to
infer most types, and types generally do not get in the way. In
particular, you can always leave out the types of any local variables.
This is the case for example for ``base`` and ``rot`` values in the
previous example; hover with the mouse over the example to see the types
that were inferred by Koka. Generally, it is good practice though to
write type annotations for function parameters and the function result
since it both helps with type inference, and it provides useful
documentation with better feedback from the compiler.

For the `encode` function it is actually essential to give the type of
the `s` parameter: since the `map` function is defined for both `:list`
and `:string` types and the program is ambiguous without an annotation.
Try to load the example in the editor and remove the annotation to see
what error Koka produces.

### Anonymous Functions and Trailing Lambdas {#sec-anon}

Koka also allows for anonymous function expressions using the `fn` keyword.
For example, instead of
declaring the `encode-char` function, we can also pass it directly to
the `map` function as a function expression:

```
fun encode2( s : string, shift : int )
{
  s.map( fn(c) {
    if (c < 'a' || c > 'z') return c
    val base = (c - 'a').int
    val rot  = (base + shift) % 26
    (rot.char + 'a')
  });
}
```

It is a bit annoying we had to put the final right-parenthesis after the last
brace in the previous example. As a convenience, Koka allows anonymous functions to _follow_
the function call instead -- this is also known as _trailing lambdas_. 
For example, here is how we can print the numbers
``1`` to ``10``:

```
fun main() { print10() }
////
fun print10()
{
  for(1,10) fn(i) {
    println(i)
  }
}
```

which is desugared to `for( 1, 10, fn(i){ println(i) } )`. (In fact, since we
pass the `i` argument directly to `println`, we could have also passed the function itself
directly, and write `for(1,10,println)`.)

Anonymous functions without any arguments can be shortened further by leaving
out the `fn` keyword as well and just use braces directly. Here is an example using
the `repeat` function:

```
fun main() { printhi10() }
////
fun printhi10()
{
  repeat(10) {
    println("hi")
  }
}
```

where the body desugars to `repeat( 10, fn(){println(``hi``)} )`. The is
especially convenient for the `while` loop since this is not a built-in
control flow construct but just a regular function:

```
fun main() { print11() }
////
fun print11() {
  var i := 10
  while { i >= 0 } {
    println(i)
    i := i - 1
  }
}
```

Note how the first argument to `while` is in braces instead of the usual
parenthesis. In Koka, an expression between _parenthesis_ is always evaluated
before a function call, whereas an expression between _braces_ (ah,
_suspenders_!) is suspended and may be never evaluated or more than once
(as in our example). 


### With Statements { #sec-with; }

To the best of our knowledge, Koka was the first language to have
generalized _dot notation_ and _trailing lambdas_. Another novel 
syntactical feature is the `with` statement.
With the ease of passing a function block as a parameter, these
often become nested. For example:
```
fun twice(f) {
  f()
  f()
}

fun test-twice() {
  twice fn(){
    twice fn(){
      println("hi")
    }
  }
}
```
where `"hi"` is printed four times. Using the `with` statement 
we can write this more concisely as:
```
public fun test-with1() {
  with twice
  with twice
  println("hi")
}
```

The `with` statement essentially puts all statements that follow it into 
an anynomous function block and passes that as the last parameter. In general:

~~ begin row
```unchecked
with f(e1,...,eN)
<body>
```
&mapsto;
```unchecked
f(e1,...,eN, fn(){ <body> })
```
~~ end row

Moreover, a `with` statement can also bind a variable parameter as:

~ row
```unchecked
with x = f(e1,...,eN)
<body>
```
&mapsto;
```unchecked
f(e1,...,eN, fn(x){ <body> })
```
~

Here is an examply using `foreach` to span over the rest of the function body:

```
public fun test-with2() {
  with x = list(1,10).foreach
  println(x)
}
```

which desugars to `list(1,10).foreach( fn(x){ println(x) } )`. 
This is a bit reminiscent of Haskell ``do`` notation. 
Using the `with` statement this way may look a bit strange at first
but is very convenient in practice -- it helps thinking of `with` as
a closure over the rest of the lexical scope. 

#### With Finally

As a final example, the `finally` function takes as it first argument a
function that is run when exiting the scope -- either normally, 
or through an "exception" (&ie; when an effect operation does not resume).
Again, `with` is a natural fit:

```
fun test-finally() {
  with finally{ println("exiting..") }
  println("entering..")
  throw("oops") + 42
}
```
which desugars to `finally(fn(){ println(...) }), fn(){ println("entering"); throw("oops") + 42 })`,
and prints:

````
entering..
exiting..
uncaught exception: oops
````

This is another example of the _min-gen_ principle: many languages have
have special built-in support for this kind of pattern, like a ``defer`` statement, but in Koka
it is all just function applications with minimal syntactic sugar.


#### With Handlers  { #sec-with-handlers; }

The `with` statement is especially useful in combination with 
effect handlers. Generally, a `handler` takes as its last argument
a function block so it can be used directly with `with`. Here
is an example where an effect handler declares a dynamically bound
value:
```
effect val ask : int

fun use-ask() {
  ask + ask
}

public fun test-ask1() {
  with handler{ val ask = 21 }
  println( use-ask() )
}
```
(where the `with` desugars to `(handler{ val ask = 21 })( fn(){ println(use-ask()) } )`).

Moreover, as a convenience, we can leave out the `handler` keyword 
when it follows the `with` keyword, where:

~ row
```unchecked
with { <ops> }
```
&mapsto;
```unchecked
with handler{ <ops> }
```
~

and for effects with just one operation (like `:ask`), this leads to the following
desugaring:

~ row
```unchecked
with val op = <expr> 
with fun op(x){ <stats> }
with control op(x){ <stats> }
```
&mapsto;
```unchecked
with handler{ val op = <expr> }
with handler{ fun op(x){ <stats> } }
with handler{ control op(x){ <stats> } }
```
~

Using this, we can write the previous example in a more concise and natural way as:

```unchecked
public fun test-ask2() {
  with val ask = 21
  println(use-ask())
}
```

[Read more about effect handlers][#sec-handlers]
{.learn}


### Optional and Named Parameters

Being a function-oriented language, Koka has powerful support for function
calls where it supports both optional and named parameters. For example, the
function `replace-all` takes a string, a pattern (named ``pattern``), and
a replacement string (named ``repl``):

```
fun main() { println(world()) }
////
fun world() {
  replace-all("hi there", "there", "world")  // returns "hi world"
}
```

Using named parameters, we can also write the function call as:

```
fun main() { println(world2()) }
////
fun world2() {
  "hi there".replace-all( repl="world", pattern="there" )
}
```

Optional parameters let you specify default values for parameters that do not
need to be provided at a call-site.  As an example, let's define a function
`sublist` that takes a list, a ``start`` position, and the length ``len`` of the desired
sublist.  We can make the ``len`` parameter optional and by default return all
elements following the ``start`` position by picking the length of the input list by
default:

```
fun main() { println( ['a','b','c'].sublist(1).string ) }
////
fun sublist( xs : list<a>, start : int, len : int = xs.length ) : list<a> {
  if (start <= 0) return xs.take(len)
  match(xs) {
    Nil        -> Nil
    Cons(_,xx) -> xx.sublist(start - 1, len)
  }
}
```

Hover over the `sublist` identifier to see its full type, where the ``len``
parameter has gotten an optional `:int` type signified by the question mark:
`:?int`.


### A larger example: cracking Caesar encoding


```
fun main() { test-uncaesar() }

fun encode( s : string, shift : int )
{
  function encode-char(c) {
    if (c < 'a' || c > 'z') return c
    val base = (c - 'a').int
    val rot  = (base + shift) % 26
    (rot.char + 'a')
  }

  s.map(encode-char)
}
////
// The letter frequency table for English
val english = [8.2,1.5,2.8,4.3,12.7,2.2,
               2.0,6.1,7.0,0.2,0.8,4.0,2.4,
               6.7,7.5,1.9,0.1, 6.0,6.3,9.1,
               2.8,1.0,2.4,0.2,2.0,0.1]

// Small helper functions
fun percent( n : int, m : int ) {
  100.0 * (n.double / m.double)
}

fun rotate( xs, n ) {
  xs.drop(n) + xs.take(n)
}

// Calculate a frequency table for a string
fun freqs( s : string ) : list<double>
{
  val lowers = list('a','z')
  val occurs = lowers.map( fn(c){ s.count(c.string) })
  val total  = occurs.sum
  occurs.map( fn(i){ percent(i,total) } )
}

// Calculate how well two frequency tables match according
// to the _chi-square_ statistic.
fun chisqr( xs : list<double>, ys : list<double> ) : double
{
  zipwith(xs,ys, fn(x,y){ ((x - y)^2.0)/y } ).foldr(0.0,(+))
}

// Crack a Caesar encoded string
fun uncaesar( s : string ) : string
{
  val table  = freqs(s)                   // build a frequency table for `s`
  val chitab = list(0,25).map( fn(n) {    // build a list of chisqr numbers for each shift between 0 and 25
                  chisqr( table.rotate(n), english )
               })
  val min    = chitab.minimum()           // find the mininal element
  val shift  = chitab.index-of( fn(f){ f == min } ).negate  // and use its position as our shift
  s.encode( shift )
}

fun test-uncaesar() {
  println( uncaesar( "nrnd lv d ixq odqjxdjh" ) )
}
```

The `val` keyword declares a static value. In the example, the value `english`
is a list of floating point numbers (of type `:double `) denoting the average
frequency for each letter. The function `freqs` builds a frequency table for a
specific string, while the function `chisqr` calculates how well two frequency
tables match. In the function `crack` these functions are used to find a
`shift` value that results in a string whose frequency table matches the
`english` one the closest -- and we use that to decode the string. 
You can try out this example directly in the interactive environment:
````
> :l samples/basic/caesar.kk
````


## Effect types

A novel part about Koka is that it automatically infers all the _side effects_
that occur in a function. The absence of any effect is denoted as `:total` (or
`<>`) and corresponds to pure mathematical functions. If a function can raise
an exception the effect is `:exn`, and if a function may not terminate the
effect is `:div` (for divergence). The combination of `:exn` and `:div` is
`:pure` and corresponds directly to Haskell's notion of purity. Non-
deterministic functions get the `:ndet` effect. The 'worst' effect is `:io`
and means that a program can raise exceptions, not terminate, be non-
deterministic, read and write to the heap, and do any input/output operations.
Here are some examples of effectful functions:

```
fun square1( x : int ) : total int   { x*x }
fun square2( x : int ) : console int { println( "a not so secret side-effect" ); x*x }
fun square3( x : int ) : div int     { x * square3( x ) }
fun square4( x : int ) : exn int     { throw( "oops" ); x*x }
```

When the effect is `:total` we usually leave it out in the type annotation.
For example, when we write:

```
fun square5( x : int ) : int { x*x }
```

the assumed effect is `:total`. Sometimes, we write an effectful
function, but are not interested in explicitly writing down its effect type.
In that case, we can use a _wildcard type_ which stands for some inferred
type. A wildcard type is denoted by writing an identifier prefixed with an
underscore, or even just an underscore by itself:

```
fun square6( x : int ) : _e int {
  println("I did not want to write down the \"console\" effect")
  x*x
}
```

Hover over `square6` to see the inferred effect for `:_e`

### Semantics of effects

The inferred effects are not just considered as some extra type information on
functions. On the contrary, through the inference of effects, Koka has a very
strong connection to its denotational semantics. In particular, _the full type
of a Koka functions corresponds directly to the type signature of the
mathematical function that describes its denotational semantics_. For example,
using &#x301A;`:t`&#x301B; to translate a type `:t` into its corresponding
mathematical type signature, we have:

|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~| ~~~~~~~~~~~~~~| ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|
|&#x301A;`:int -> total int `&#x301B;        | =&nbsp;&nbsp; | $\mathbb{Z} \rightarrow \mathbb{Z}$                              |
|&#x301A;`:int -> exn int `&#x301B;          | =             | $\mathbb{Z} \rightarrow (\mathbb{Z} + 1)$ |
|&#x301A;`:int -> pure int `&#x301B;         | =             | $\mathbb{Z} \rightarrow (\mathbb{Z} + 1)_\bot$ |
|&#x301A;`:int -> <st<h>,pure> int `&#x301B; | =             | $(\mathbb{Z} \times \mathbb{H}) \rightarrow ((\mathbb{Z} + 1) \times \mathbb{H})_\bot$ |

In the above translation, we use $1 + \tau$ as a sum
where we have either a unit $1$ (i.e. exception) or a type $\tau$, and we use
$\mathbb{H}\times \tau$ for a product consisting of a pair of a
heap and a type $\tau$. From the above correspondence, we can immediately see that
a `:total` function is truly total in the mathematical sense, while a stateful
function (`:st<h> `) that can raise exceptions or not terminate (`:pure`)
takes an implicit heap parameter, and either does not terminate ($\bot$) or
returns an updated heap together with either a value or an exception ($1$).

We believe that this semantic correspondence is the true power of full effect
types and it enables effective equational reasoning about the code by a
programmer. For almost all other existing programming languages, even the most
basic semantics immediately include complex effects like heap manipulation and
divergence. In contrast, Koka allows a layered semantics where we can easily
separate out nicely behaved parts, which is essential for many domains, like
safe LINQ queries, parallel tasks, tier-splitting, sand-boxed mobile code,
etc.


### Combining effects

Often, a function contains multiple effects, for example:

```unchecked
fun combine-effects() {
  val i = srandom-int() // non-deterministic
  throw("oops")         // exception raising
  combine-effects()     // and non-terminating
}
```

The effect assigned to `combine-effects` are `:ndet`, `:div`, and `:exn`. We
can write such combination as a _row_ of effects as `: <div,exn,ndet> `. When
you hover over the `combine-effects` identifiers, you will see that the type
inferred is really `: <pure,ndet> ` where `:pure` is a type alias defined as

```unchecked
alias pure = <div,exn>
```


### Polymorphic effects

Many functions are polymorphic in their effect. For example, the
`map:forall<a,b,e> (xs : list<a>, f : (a) -> e b) -> e list<b> ` function
applies a function `f` to each element of a (finite) list. As such, the effect
depends on the effect of `f`, and the type of `map` becomes:

```unchecked
map : (xs : list<a>, f : (a) -> e b) -> e list<b>
```

We use single letters (possibly followed by digits) for polymorphic types.
Here, the `map` functions takes a list with elements of some type `:a`, and a
function ``f`` that takes an element of type `:a` and returns a new element of
type `:b`. The final result is a list with elements of type `:b`. Moreover,
the effect of the applied function `:e` is also the effect of the `map`
function itself; indeed, this function has no other effect by itself since it
does not diverge, nor raises exceptions.

We can use the notation `: <l|e>` to extend an effect `:e` with another effect
`:l`. This is used for example in the `while` function which has type:
`while : ( pred : () -> <div|e> bool, action : () -> <div|e> () ) -> <div|e> ()`.
The `while` function takes a
predicate function and an action to perform, both with effect `: <div|e>`.
Indeed, since while may diverge depending on the predicate its effect must
include divergence.

The reader may be worried that the type of `while` forces the predicate and
action to have exactly the same effect `: <div|e>`, which even includes
divergence. However, when effects are inferred at the call-site, both the
effects of predicate and action are extended automatically until they match.
This ensures we take the union of the effects in the predicate and action.
Take for example the following loop

```unchecked
import std/num/random
fun main() { looptest() }
////
fun looptest() {
  while { is-odd(srandom-int()) } {
    throw("odd")
  }
}
```

Koka infers that the predicate ``odd(srandom-int())`` has
effect `: <ndet|e1> ` while the action has effect `: <exn|e2> ` for some `:e1` and `:e2`.
When applying `while`, those
effects are unified to the type `: <exn,ndet,div|e3> ` for some `:e3`.

### Local Mutable Variables

The Fibonacci numbers are a sequence where each subsequent Fibonacci number is
the sum of the previous two, where `fib(0) == 0` and `fib(1) == 1`. We can
easily calculate Fibonacci numbers using a recursive function:

```
fun main() { println(fib(10)) }
////
fun fib(n : int) : div int {
  if (n <= 0)   then 0
  elif (n == 1) then 1
  else fib(n - 1) + fib(n - 2)
}
```

Note that the type inference engine is currently not powerful enough to
prove that this recursive function always terminates, which leads to
inclusion of the divergence effect `:div` in the result type.


Here is another version of the Fibonacci function but this time
implemented using local mutable variables. 
We use the `repeat` function to iterate `n` times:

```
fun main() { println(fib2(10)) }
////
fun fib2(n) {
  var x := 0
  var y := 1
  repeat(n) {
    val y0 = y
    y := x+y
    x := y0
  }
  x
}
```
In contrast to a `val` declaration that binds an immutable value (as in `val y0 = y`),
a `var` declaration declares a _mutable_ variable, where the `(:=)` operator 
can assign a new value to the variable. Internally, the `var` declarations use 
a _state_ effect handler which ensures
that the state has the proper semantics even if resuming multiple times.

<!--
However, that also means that mutable local variables are not quite first-class
and we cannot pass them as parameters to other functions for example (as they
are always dereferenced). You will also get a type error if a local variable
escapes through a function expression, for example:
```unchecked
fun wrong() : (() -> console ()) {
  var x := 1
  (fn(){ x := x + 1; println(x) })
}
```
is statically rejected as the reference to the local variable escapes its scope.
-->

[Read more about state and multiple resumptions][#sec-multi-resume]
{.learn}


### Reference Cells and Isolated state {#sec-runst}

Koka also has heap allocated mutable reference cells. 
A reference to an
integer is allocated using `val r = ref(0)` (since the reference itself is
actually a value!), and can be dereferenced using the bang operator, as ``!r``.
We can write the Fibonacci function using reference cells as:

```
fun main() { println(fib3(10)) }
////
fun fib3(n) {
  val x = ref(0)
  val y = ref(1)
  repeat(n) {
    val y0 = !y
    y := !x + !y
    x := y0
  }
  return !x
}
```

As we can see, using `var` declarations are generally preferred as these 
behave better under multiple resumptions, but also are syntactically more
concise as they do not need a dereferencing operator. (Nevertheless, we 
still need reference cells as those are first-class while `var` variables
cannot be passed to other functions.)

When we look at the types inferred for the references, we see that `x` and `y`
have type `:ref<h,int> ` which stands for a reference to a mutable value of
type `:int` in some heap `:h`. The effects on heaps are allocation as
`:heap<h>`, reading from a heap as `:read<h>` and writing to a heap as
`:write<h>`. The combination of these effects is called stateful and denoted
with the alias `:st<h>`.

Clearly, the effect of the body of `fib3` is `:st<h> `; but when we hover over
`fib3`, we see the type inferred is actually the `:total` effect: `:(n:int) -> int`.
Indeed, even though `fib3` is stateful inside, its side-effects can
never be observed. It turns out that we can safely discard the `:st<h> `
effect whenever the heap type `:h` cannot be referenced outside this function,
i.e. it is not part of an argument or return type. More formally, the Koka
compiler proves this by showing that a function is fully polymorphic in the
heap type `:h` and applies the `run` function (corresponding to ``runST`` in
Haskell) to discard the `:st<h> ` effect.

The Garsia-Wachs algorithm is nice example where side-effects are used
internally across function definitions and data structures, but where the
final algorithm itself behaves like a pure function, see the
[``samples/basic/garsia-wachs.kk``][garsia-wachs].

[garsia-wachs]: https://github.com/koka-lang/koka/tree/master/samples/basic/garsia-wachs.kk {target='_top'}


## Data Types


### Structs

An important aspect of a function-oriented language is to be able to define
rich data types over which the functions work. A common data type is that of a
_struct_ or _record_. Here is an example of a struct that contains information
about a person:

```
struct person { 
  age : int
  name : string
  realname : string = name
}

val brian = Person( 29, "Brian" )
```

Every `struct` (and other data types) come with constructor functions to
create instances, as in `Person(19,"Brian")`. Moreover, these
constructors can use named arguments so we can also call the constructor
as `Person( name = "Brian", age = 19, realname = "Brian H. Griffin" )`
which is quite close to regular record syntax but without any special rules;
it is just functions all the way down!

Also, Koka automatically generates accessor functions for each field in a
struct (or other data type), and we can access the `age` of a `:person` as
`brian.age` (which is of course just syntactic sugar for `age(brian)`).

### Copying

By default, all structs (and other data types) are _immutable_. Instead of
directly mutating a field in a struct, we usually return a new struct where
the fields are updated. For example, here is a `birthday` function that
increments the `age` field:

```
fun main() { println( brian.birthday.age ) }

struct person { 
  age : int
  name : string
  realname : string = name 
}

val brian = Person( 29, "Brian" )
////
fun birthday( p : person ) : person {
  p( age = p.age + 1 )
}
```

Here, `birthday` returns a fresh `:person` which is equal to `p` but with the
`age` incremented. The syntax ``p(...)`` is syntactic sugar for calling the copy constructor of
a `:person`. This constructor is also automatically generated for each data
type, and is internally generated as:

```
fun main() { println( brian.copy().age ) }

struct person( age : int, name : string, realname : string = name )

val brian = Person( 29, "Brian" )
////
fun copy( p, age = p.age, name = p.name, realname = p.realname ) {
  return Person(age, name, realname)
}
```

When arguments follow a data value, as in ``p( age = age + 1)``, it is expanded to call this
copy function, as in `p.copy( age = p.age+1 )`. In adherence with the _min-gen_ principle,
there are no special rules for record updates but using plain function calls with optional
and named parameters.

### Alternatives (or Unions)

Koka also supports algebraic data types where there are multiple alternatives.
For example, here is an enumeration:

```unchecked
type colors {
  Red
  Green
  Blue
}
```

Special cases of these enumerated types are the `:void` type which has no
alternatives (and therefore there exists no value with this type), the unit
type `:()` which has just one constructor, also written as `()` (and
therefore, there exists only one value with the type `:()`, namely `()`), and
finally the boolean type `:bool` with two constructors `True` and `False`.

```unchecked
type void
type () {
  ()
}
type bool {
  False
  True
}
```

Constructors can have parameters. For example, here is how to create a
`:number` type which is either an integer or the infinity value:

```unchecked
type number {
  Infinity
  Integer( i : int )
}
```

We can create such number by writing `integer(1)` or `infinity`. Moreover,
data types can be polymorphic and recursive. Here is the definition of the
`:list` type which is either empty (`Nil`) or is a head element followed by a
tail list (`Cons`):

```unchecked
type list<a> {
  Nil
  Cons{ head : a; tail : list<a> }
}
```

Koka automatically generates accessor functions for each named parameter. For
lists for example, we can access the head of a list as `Cons(1,Nil).head`.

We can now also see that `struct` types are just syntactic sugar for regular a
`type` with a single constructor of the same name as the type. For example,
our earlier `:person` struct, defined as

```unchecked
struct person{ age : int; name : string; realname : string = name }
```

desugars to:

```unchecked
type person {
  Person( age : int, name : string, realname : string = name )
}
```

### Matching

Todo

### Inductive, co-inductive, and recursive types

For the purposes of equational reasoning and termination checking, a `type`
declaration is limited to finite inductive types. There are two more
declarations, namely `co type` and `rec type` that allow for co-inductive types,
and arbitrary recursive types respectively.

## Effect Handlers { #sec-handlers }

Todo

## FBIP: Functional but In-Place { #sec-fbip; }

With [Perceus][#why-fbip] reuse analysis we can
write algorithms that dynamically adapt to use in-place mutation when
possible (and use copying when used persistently). Importantly,
you can rely on this optimization happening, &eg; see
the `match` patterns and pair them to same-sized constructors in each branch.

This style of programming leads to a new paradigm that we call FBIP:
"functional but in place". Just like tail-call optimization lets us
describe loops in terms of regular function calls, reuse analysis lets us
describe in-place mutating imperative algorithms in a purely functional
way (and get persistence as well).


### Tree Rebalancing

As an example, we consider
insertion into a red-black tree [@guibas1978dichromatic]. 
A polymorphic version of this example is part of the [``samples``][samples] directory when you have
installed Koka and can be loaded as ``:l`` [``samples/basic/rbtree``][rbtree].
We define red-black trees as:
```unchecked
type color { 
  Red 
  Black 
}

type tree {
  Leaf
  Node(color: color, left: tree, key: int, value: bool, right: tree)
}
```
The red-black tree has the invariant that the number of black nodes from
the root to any of the leaves is the same, and that a red node is never a
parent of red node. Together this ensures that the trees are always
balanced. When inserting nodes, the invariants need to be maintained by
rebalancing the nodes when needed. Okasaki's algorithm [@Okasaki:rbtree]
implements this elegantly and functionally:
```unchecked
fun balance-left( l : tree, k : int, v : bool, r : tree ): tree {
  match(l) {
    Node(_, Node(Red, lx, kx, vx, rx), ky, vy, ry)
      -> Node(Red, Node(Black, lx, kx, vx, rx), ky, vy, Node(Black, ry, k, v, r))
    ...
}

fun ins( t : tree, k : int, v : bool ): tree {
  match(t) {
    Leaf -> Node(Red, Leaf, k, v, Leaf)
    Node(Red, l, kx, vx, r)             
      -> if (k < kx) then Node(Red, ins(l, k, v), kx, vx, r)
         ...
    Node(Black, l, kx, vx, r)
      -> if (k < kx && is-red(l)) then balance-left(ins(l,k,v), kx, vx, r)
         ...
}
```

The Koka compiler will inline the `balance-left` function. At that point,
every matched `Node` constructor in the `ins` function has a corresponding `Node` allocation --
if we consider all branches we can see that we either match one `Node`
and allocate one, or we match three nodes deep and allocate three. Every 
`Node` is actually reused in the fast path without doing any allocations!
When studying the generated code, we can see the Perceus assigns the 
fields in the nodes in the fast path _in-place_ much like the 
usual non-persistent rebalancing algorithm in C would do.

Essentially this means that for a unique tree, the purely functional
algorithm above adapts at runtime to an in-place mutating re-balancing
algorithm (without any further allocation). Moreover, if we use the tree
_persistently_ [@Okasaki:purefun], and the tree is shared or has
shared parts, the algorithm adapts to copying exactly the shared _spine_
of the tree (and no more), while still rebalancing in place for any
unshared parts.


### Morris Traversal

As another example of FBIP, consider mapping a function `f` over
all elements in a binary tree in-order as shown in the `tmap-inorder` example:

```
type tree {
  Tip
  Bin( left: tree, value : int, right: tree )
}

fun tmap-inorder( t : tree, f : int -> int ) : tree {
  match(t) {
    Bin(l,x,r) -> Bin( l.tmap-inorder(f), f(x), r.tmap-inorder(f) )
    Tip        -> Tip 
  }
}
```

This is already quite efficient as all the `Bin` and `Tip` nodes are
reused in-place when `t` is unique. However, the `tmap` function is not
tail-recursive and thus uses as much stack space as the depth of the
tree.

````cpp {.aside}
void inorder( tree* root, void (*f)(tree* t) ) {
  tree* cursor = root;
  while (cursor != NULL /* Tip */) {
    if (cursor->left == NULL) {
      // no left tree, go down the right
      f(cursor->value);
      cursor = cursor->right;
    } else {
      // has a left tree
      tree* pre = cursor->left;  // find the predecessor
      while(pre->right != NULL && pre->right != cursor) {
        pre = pre->right;
      }
      if (pre->right == NULL) {
        // first visit, remember to visit right tree
        pre->right = cursor;
        cursor = cursor->left;
      } else {
        // already set, restore
        f(cursor->value);
        pre->right = NULL;
        cursor = cursor->right;
      } 
    } 
  } 
}
````

In 1968, Knuth posed the problem of visiting a tree in-order while using
no extra stack- or heap space [@Knuth:aocp1] (For readers not familiar
with the problem it might be fun to try this in your favorite imperative
language first and see that it is not easy to do). Since then, numerous
solutions have appeared in the literature. A particularly elegant
solution was proposed by @Morris:tree. This is an in-place mutating
algorithm that swaps pointers in the tree to "remember" which parts are
unvisited. It is beyond this tutorial to give a full explanation, but a C
implementation is shown here on the side. The traversal
essentially uses a _right-threaded_ tree to keep track of which nodes to
visit. The algorithm is subtle, though. Since it transforms the tree into
an intermediate graph, we need to state invariants over the so-called
_Morris loops_ [@Mateti:morris] to prove its correctness.

We can derive a functional and more intuitive solution using the FBIP
technique. We start by defining an explicit _visitor_ data structure
that keeps track of which parts of the tree we still need to visit. In
Koka we define this data type as `:visitor`:
```
type visitor {
  Done
  BinR( right:tree, value : int, visit : visitor )
  BinL( left:tree, value : int, visit : visitor )
}
```

(As an aside, 
Conor McBride [@Mcbride:derivative] describes how we can
generically derive a _zipper_ [@Huet:zipper] visitor for any
recursive type $\mu x. F$ as a list of the derivative of that type,
namely $@list (\pdv{x} F\mid_{x =\mu x.F})$.
In our case, the algebraic representation of the inductive `:tree`
type is $\mu x. 1 + x\times int\times x  \,\cong\, \mu x. 1 + x^2\times int$.
Calculating the derivative $@list (\pdv{x} (1 + x^2\times int) \mid_{x = tree})$
and by further simplification, 
we get $\mu x. 1 + (tree\times int\times x) + (tree\times int\times x)$,
which corresponds exactly to our `:visitor` datatype.)

We also keep track of which `:direction` in the tree 
we are going, either `Up` or `Down` the tree.

```
type direction { 
  Up 
  Down 
}
```

We start our traversal by going downward into the tree with an empty
visitor, expressed as `tmap(f, t, Done, Down)`:

```
fun tmap( f : int -> int, t : tree, visit : visitor, d : direction ) {
  match(d) {
    Down -> match(t) {    // going down a left spine
      Bin(l,x,r) -> tmap(f,l,BinR(r,x,visit),Down) // A
      Tip        -> tmap(f,Tip,visit,Up)           // B
    }
    Up -> match(visit) {  // go up through the visitor
      Done        -> t                             // C
      BinR(r,x,v) -> tmap(f,r,BinL(t,f(x),v),Down) // D
      BinL(l,x,v) -> tmap(f,Bin(l,x,t),v,Up)       // E
    } 
  } 
}
```
 
The key idea is that we
are either `Done` (`C`), or, on going downward in a left spine we
remember all the right trees we still need to visit in a `BinR` (`A`) or,
going upward again (`B`), we remember the left tree that we just
constructed as a `BinL` while visiting right trees (`D`). When we come
back up (`E`), we restore the original tree with the result values. Note
that we apply the function `f` to the saved value in branch `D` (as we
visit _in-order_), but the functional implementation makes it easy to
specify a _pre-order_ traversal by applying `f` in branch `A`, or a
_post-order_ traversal by applying `f` in branch `E`.

Looking at each branch we can see that each `Bin` matches up with a
`BinR`, each `BinR` with a `BinL`, and finally each `BinL` with a `Bin`.
Since they all have the same size, if the tree is unique, each branch
updates the tree nodes _in-place_ at runtime without any allocation,
where the `:visitor` structure is effectively overlaid over the tree
nodes while traversing the tree. Since all `tmap` calls are tail calls,
this also compiles to a tight loop and thus needs no extra stack- or heap
space.

Finally, just like with re-balancing tree insertion, the algorithm as
specified is still purely functional: it uses in-place updating when a
unique tree is passed, but it also adapts gracefully to the persistent
case where the input tree is shared, or where parts of the input tree are
shared, making a single copy of those parts of the tree.

[Read the Perceus technical report][Perceus]
{.learn}