//
//  FaceList.swift
//  QuickHull
//
//  Created by Carl Wieland on 4/20/15.
//  Copyright (c) 2015 Carl Wieland. All rights reserved.
//

import Foundation

/**
* Maintains a single-linked list of faces for use by QuickHull3D
*/
public class FaceList
{
    private var head:Face? = nil;
    private var tail:Face? = nil;
    
    /**
    * Clears this list.
    */
    public func clear(){
        head = nil
        tail = nil;
    }
    
    /**
    * Adds a vertex to the end of this list.
    */
    public func add (vtx:Face){
        if (head == nil){
            head = vtx;
        }
        else{
            tail!.next = vtx;
        }
        vtx.next = nil;
        tail = vtx;
    }
    
    public func first()->Face?
    {
	   return head;
    }
    
    /**
    * Returns true if this list is empty.
    */
    public func isEmpty()->Bool
    {
	   return head == nil;
    }
}
