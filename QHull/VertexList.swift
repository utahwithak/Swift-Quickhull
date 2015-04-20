//
//  VertexList.swift
//  QuickHull
//
//  Created by Carl Wieland on 4/20/15.
//  Copyright (c) 2015 Carl Wieland. All rights reserved.
//

import Foundation

/**
* Maintains a double-linked list of vertices for use by QuickHull3D
*/
public class VertexList
{
    private var head:Vertex? = nil;
    private var tail:Vertex? = nil;
    
    /**
    * Clears this list.
    */
    public func clear()
    {
        head = nil
        tail = nil;
    }
    
    /**
    * Adds a vertex to the end of this list.
    */
    public func add(vtx:Vertex)
    {
        if (head == nil){
            head = vtx;
        }
        else{
            tail!.next = vtx;
        }
        vtx.prev = tail;
        vtx.next = nil;
        tail = vtx;
    }
    
    /**
    * Adds a chain of vertices to the end of this list.
    */
    public func addAll ( vtx:Vertex)
    {
        if (head == nil){
            head = vtx;
        }
        else{
            tail!.next = vtx;
        }
        vtx.prev = tail;
        var runner:Vertex? = vtx;
        while (runner!.next != nil){
            runner = runner!.next;
        }
        tail = runner;
    }
    
    /**
    * Deletes a vertex from this list.
    */
    public func delete (vtx:Vertex ){
        if (vtx.prev == nil){
            head = vtx.next;
        }
        else{
            vtx.prev!.next = vtx.next;
        }
        if (vtx.next == nil){
            tail = vtx.prev;
        }
        else{
            vtx.next!.prev = vtx.prev;
        }
    }
    
    /**
    * Deletes a chain of vertices from this list.
    */
    public func delete (vtx1:Vertex, vtx2:Vertex){
        if (vtx1.prev == nil){
            head = vtx2.next;
        }
        else{
            vtx1.prev!.next = vtx2.next;
        }
        if (vtx2.next == nil){
            tail = vtx1.prev;
        }
        else{
            vtx2.next!.prev = vtx1.prev;
        }
    }
    
    /**
    * Inserts a vertex into this list before another
    * specificed vertex.
    */
    public func insertBefore (vtx:Vertex ,  next:Vertex)
    {
        vtx.prev = next.prev;
        if (next.prev == nil){
            head = vtx;
        }
        else{
            next.prev!.next = vtx;
        }
        vtx.next = next;
        next.prev = vtx;
    }
    
    /**
    * Returns the first element in this list.
    */
    public func first()->Vertex?
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
