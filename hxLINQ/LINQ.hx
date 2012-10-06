/*
	hxLINQ
	HaXe version of LINQ. Based on the "LINQ to JavaScript (JSLINQ)":http://jslinq.codeplex.com Project.

	JSLINQ is licensed under the Microsoft Reciprocal License (Ms-RL)
	Copyright (C) 2009 Chris Pietschmann (http://pietschsoft.com). All rights reserved.
	The license can be found here: http://jslinq.codeplex.com/license
*/

package hxLINQ;

typedef LINQ<T,C:Iterable<T>> = hxLINQ.iterable.LINQtoIterable<T,C>;