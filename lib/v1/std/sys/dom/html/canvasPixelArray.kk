public module sys/dom/html/canvasPixelArray

// Interface CanvasPixelArray (generated by esidl 0.2.0).

import sys/dom/types

/* safe and unsafe conversion from all types including `any */
external inline maybeCanvasPixelArray  : forall<a> (a) -> maybe<canvasPixelArray>
{ inline "(#1.toString()==='[object CanvasPixelArray]'?std_core.Just(#1):std_core.Nothing)" }
external inline toCanvasPixelArray : forall<a> (a) -> exn canvasPixelArray
{ inline "(#1.toString()==='[object CanvasPixelArray]'?#1:std_core.error('toCanvasPixelArray: cast failed'))" }


// CanvasPixelArray implements CanvasPixelArray (supplemental)
external inline length : (this: canvasPixelArray) -> dom uint32
{ inline "#1.length" }
external inline getElement : (this: canvasPixelArray, index: uint32) -> dom octet
{ inline "#1.getElement(#2)" }

external inline setElement : (this: canvasPixelArray, index: uint32, value: octet) -> dom ()
{ inline "#1.setElement(#2, #3)" }

