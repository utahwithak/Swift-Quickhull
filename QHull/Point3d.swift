//
//  Point3d.swift
//  QuickHull
//
//  Created by Carl Wieland on 4/20/15.
//  Copyright (c) 2015 Carl Wieland. All rights reserved.
//
/**
* Copyright John E. Lloyd, 2004. All rights reserved. Permission to use,
* copy, modify and redistribute is granted, provided that this copyright
* notice is retained and the author is given credit whenever appropriate.
*
* This  software is distributed "as is", without any warranty, including
* any implied warranty of merchantability or fitness for a particular
* use. The author assumes no responsibility for, and shall not be liable
* for, any special, indirect, or consequential damages, or any damages
* whatsoever, arising out of or in connection with the use of this
* software.
*/

import Foundation

/**
* A three-element spatial point.
*
* The only difference between a point and a vector is in the
* the way it is transformed by an affine transformation. Since
* the transform method is not included in this reduced
* implementation for QuickHull3D, the difference is
* purely academic.
*
* @author John E. Lloyd, Fall 2004
*/
public class Point3d:Vector3d {
    public override init(){
        super.init()
    }
    /**
    * Creates a Point3d by copying a vector
    *
    * @param v vector to be copied
    */
    public override init( v:Vector3d)
    {
        super.init(v: v)
    }
    
    /**
    * Creates a Point3d with the supplied element values.
    *
    * @param x first element
    * @param y second element
    * @param z third element
    */
    public override init ( x:Double,  y:Double,  z:Double)
    {
        super.init(x: x, y: y, z: z)
    }
}