package hxLINQ;

typedef LINQ<T,C:Iterable<T>> = hxLINQ.iterable.LINQtoIterable<T,C>;
typedef OrderedLINQ<T,C:Iterable<T>> = hxLINQ.iterable.OrderedLINQtoIterable<T,C>;