//
//  QuickHull3D.swift
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
* Computes the convex hull of a set of three dimensional points.
*
* <p>The algorithm is a three dimensional implementation of Quickhull, as
* described in Barber, Dobkin, and Huhdanpaa, <a
* href=http://citeseer.ist.psu.edu/barber96quickhull.html> ``The Quickhull
* Algorithm for Convex Hulls''</a> (ACM Transactions on Mathematical Software,
* Vol. 22, No. 4, December 1996), and has a complexity of O(n log(n)) with
* respect to the number of points. A well-known C implementation of Quickhull
* that works for arbitrary dimensions is provided by <a
* href=http://www.qhull.org>qhull</a>.
*
* <p>A hull is constructed by providing a set of points
* to either a constructor or a
* {@link #build(Point3d[]) build} method. After
* the hull is built, its vertices and faces can be retrieved
* using {@link #getVertices()
* getVertices} and {@link #getFaces() getFaces}.
* A typical usage might look like this:
* <pre>
*   // x y z coordinates of 6 points
*   Point3d[] points = new Point3d[]
*    { new Point3d (0.0,  0.0,  0.0),
*      new Point3d (1.0,  0.5,  0.0),
*      new Point3d (2.0,  0.0,  0.0),
*      new Point3d (0.5,  0.5,  0.5),
*      new Point3d (0.0,  0.0,  2.0),
*      new Point3d (0.1,  0.2,  0.3),
*      new Point3d (0.0,  2.0,  0.0),
*    };
*
*   QuickHull3D hull = new QuickHull3D();
*   hull.build (points);
*
*   println ("Vertices:");
*   Point3d[] vertices = hull.getVertices();
*   for (int i = 0; i < vertices.length; i++)
*    { Point3d pnt = vertices[i];
*      println (pnt.x + " " + pnt.y + " " + pnt.z);
*    }
*
*   println ("Faces:");
*   int[][] faceIndices = hull.getFaces();
*   for (int i = 0; i < faceIndices.length; i++)
*    { for (int k = 0; k < faceIndices[i].length; k++)
*       { print (faceIndices[i][k] + " ");
*       }
*      println ("");
*    }
* </pre>
* As a convenience, there are also {@link #build(double[]) build}
* and {@link #getVertices(double[]) getVertex} methods which
* pass point information using an array of doubles.
*
* <h3><a name=distTol>Robustness</h3> Because this algorithm uses floating
* point arithmetic, it is potentially vulnerable to errors arising from
* numerical imprecision.  We address this problem in the same way as <a
* href=http://www.qhull.org>qhull</a>, by merging faces whose edges are not
* clearly convex. A face is convex if its edges are convex, and an edge is
* convex if the centroid of each adjacent plane is clearly <i>below</i> the
* plane of the other face. The centroid is considered below a plane if its
* distance to the plane is less than the negative of a {@link
* #getDistanceTolerance() distance tolerance}.  This tolerance represents the
* smallest distance that can be reliably computed within the available numeric
* precision. It is normally computed automatically from the point data,
* although an application may {@link #setExplicitDistanceTolerance set this
* tolerance explicitly}.
*
* <p>Numerical problems are more likely to arise in situations where data
* points lie on or within the faces or edges of the convex hull. We have
* tested QuickHull3D for such situations by computing the convex hull of a
* random point set, then adding additional randomly chosen points which lie
* very close to the hull vertices and edges, and computing the convex
* hull again. The hull is deemed correct if {@link #check check} returns
* <code>true</code>.  These tests have been successful for a large number of
* trials and so we are confident that QuickHull3D is reasonably robust.
*
* <h3>Merged Faces</h3> The merging of faces means that the faces returned by
* QuickHull3D may be convex polygons instead of triangles. If triangles are
* desired, the application may {@link #triangulate triangulate} the faces, but
* it should be noted that this may result in triangles which are very small or
* thin and hence difficult to perform reliable convexity tests on. In other
* words, triangulating a merged face is likely to restore the numerical
* problems which the merging process removed. Hence is it
* possible that, after triangulation, {@link #check check} will fail (the same
* behavior is observed with triangulated output from <a
* href=http://www.qhull.org>qhull</a>).
*
* <h3>Degenerate Input</h3>It is assumed that the input points
* are non-degenerate in that they are not coincident, colinear, or
* colplanar, and thus the convex hull has a non-zero volume.
* If the input points are detected to be degenerate within
* the {@link #getDistanceTolerance() distance tolerance}, an
* IllegalArgumentException will be thrown.
*
* @author John E. Lloyd, Fall 2004 */
public class QuickHull3D
{
    /**
     Specifies that (on output) vertex indices for a face should be
     listed in clockwise order.
    */
    public static let CLOCKWISE = 0x1;
    
    /**
     Specifies that (on output) the vertex indices for a face should be
     numbered starting from 1.
    */
    public static let INDEXED_FROM_ONE = 0x2;
    
    /**
     Specifies that (on output) the vertex indices for a face should be
     numbered starting from 0.
    */
    public static let INDEXED_FROM_ZERO = 0x4;
    
    /**
     Specifies that (on output) the vertex indices for a face should be
     numbered with respect to the original input points.
    */
    public static let POINT_RELATIVE = 0x8;
    
    /**
     Specifies that the distance tolerance should be
     computed automatically from the input point data.
    */
    public static let AUTOMATIC_TOLERANCE = -1.0
    
    
    private static let NONCONVEX_WRT_LARGER_FACE = 1;
    private static let NONCONVEX = 2;
    var findIndex = -1;

    var charLength = 0.0
    var pointBuffer = [Vertex]()
    var vertexPointIndices = [Int]()
    var discardedFaces =  [Face]()
    
    var maxVtxs = [Vertex](count:3, repeatedValue:Vertex())
    var minVtxs = [Vertex](count:3, repeatedValue:Vertex())

    var horizon = [HalfEdge]()
    var faces = [Face]()

    
    
    private let newFaces =  FaceList();
    private let unclaimed = VertexList();
    private let claimed =  VertexList();
    
    var numVertices = 0;
    var numFaces = 0;
    var numPoints = 0;
    
    var debug = false;
    var explicitTolerance = QuickHull3D.AUTOMATIC_TOLERANCE;
    var tolerance = 0.0

    
    /**
    * Creates an empty convex hull object.
    */
    public init() {  }

    
    
    
    
    /**
    * Returns the vertex points in this hull.
    *
    * @return array of vertex points
    * @see QuickHull3D#getVertices(double[])
    * @see QuickHull3D#getFaces()
    */
    public func getVertices()-> [Point3d]
    {
        var vtxs =  [Point3d]()
        for i in 0..<numVertices{
            vtxs.append(pointBuffer[vertexPointIndices[i]].pnt);
        }
        return vtxs;
    }

    
    
    /**
    * Returns the faces associated with this hull.
    *
    * <p>Each face is represented by an integer array which gives the
    * indices of the vertices. These indices are numbered
    * relative to the
    * hull vertices, are zero-based,
    * and are arranged counter-clockwise. More control
    * over the index format can be obtained using
    * {@link #getFaces(int) getFaces(indexFlags)}.
    *
    * @return array of integer arrays, giving the vertex
    * indices for each face.
    * @see QuickHull3D#getVertices()
    * @see QuickHull3D#getFaces(int)
    */
    public func getFaces()->[[Int]]
    {
        return getFaces(0);
    }
    
    
    /**
    * Returns the faces associated with this hull.
    *
    * <p>Each face is represented by an integer array which gives the
    * indices of the vertices. By default, these indices are numbered with
    * respect to the hull vertices (as opposed to the input points), are
    * zero-based, and are arranged counter-clockwise. However, this
    * can be changed by setting {@link #POINT_RELATIVE
    * POINT_RELATIVE}, {@link #INDEXED_FROM_ONE INDEXED_FROM_ONE}, or
    * {@link #CLOCKWISE CLOCKWISE} in the indexFlags parameter.
    *
    * @param indexFlags specifies index characteristics (0 results
    * in the default)
    * @return array of integer arrays, giving the vertex
    * indices for each face.
    * @see QuickHull3D#getVertices()
    */
    public func getFaces (indexFlags:Int)->[[Int]]{
        var allFaces =  [[Int]]()
        var k = 0;
        for face in faces{
        
            allFaces.append([Int](count:face.numVertices(),repeatedValue:0));
            getFaceIndices(&allFaces[k], face: face, flags: indexFlags);
            k++;
        }
        return allFaces;
    }
    
    public func normalOfFace(index:Int)->Vector3d{
        return faces[index].getNormal()
    }
    
    func getFaceIndices (inout indices:[Int],  face:Face,  flags:Int)
    {
        let ccw = ((flags & QuickHull3D.CLOCKWISE) == 0);
        let indexedFromOne = ((flags & QuickHull3D.INDEXED_FROM_ONE) != 0);
        let pointRelative = ((flags & QuickHull3D.POINT_RELATIVE) != 0);
        
        var hedge = face.he0;
        var k = 0;
        do
        {
            var idx = hedge.head().index;
            if (pointRelative)
            {
                idx = vertexPointIndices[idx];
            }
            if (indexedFromOne)
            {
                idx++;
            }
            indices[k++] = idx;
            hedge = (ccw ? hedge.next! : hedge.prev!);
        }while (hedge !== face.he0);
    }
    
    /**
    * Creates a convex hull object and initializes it to the convex hull
    * of a set of points.
    *
    * @param points input points.
    * @throws IllegalArgumentException the number of input points is less
    * than four, or the points appear to be coincident, colinear, or
    * coplanar.
    */
    public init(points:[Point3d])
    {
	   build(points, nump: points.count);
    }
    
    
    /**
    * Returns true if debugging is enabled.
    *
    * @return true is debugging is enabled
    * @see QuickHull3D#setDebug
    */
    public func getDebug()->Bool
    {
	   return debug;
    }
    
    /**
    * Enables the printing of debugging diagnostics.
    *
    * @param enable if true, enables debugging
    */
    public func setDebug ( enable:Bool)
    { 
        debug = enable;
    }

    /**
    * Precision of a double.
    */
    static let DOUBLE_PREC = 2.2204460492503131e-16;
    

    
    
    func addPointToFace ( vtx:Vertex,  face:Face)
    {
        vtx.face = face;
        if (face.outside == nil){
            claimed.add (vtx);
        }
        else{
            claimed.insertBefore (vtx, next: face.outside!);
        }
        face.outside = vtx;
    }
    
    func removePointFromFace (vtx:Vertex,  face:Face)
    {
        if (vtx === face.outside)
        {
            if (vtx.next != nil && vtx.next!.face === face){
                face.outside = vtx.next;
            }
            else{
                face.outside = nil;
            }
        }
        claimed.delete (vtx);
    }
    
    private func removeAllPointsFromFace (face:Face)->Vertex?
    {
        if (face.outside != nil){
            var end = face.outside!;
            while (end.next != nil && end.next!.face === face){
                end = end.next!;
            }
            claimed.delete (face.outside!, vtx2: end);
            end.next = nil;
            return face.outside;
        }
        else{
            return nil;
        }
    }
    
    public func build (points:[Point3d])
    {
        build(points,nump:points.count)
    }
    /**
    * Constructs the convex hull of a set of points.
    *
    * @param points input points
    * @param nump number of input points
    * @throws IllegalArgumentException the number of input points is less
    * than four or greater then the length of <code>points</code>, or the
    * points appear to be coincident, colinear, or coplanar.
    */
    public func build (points:[Point3d],  nump:Int)
    {
        assert(nump >= 4,"Less than four input points specified");
        assert(points.count >= nump,  "Point array too small for specified number of points");
        initBuffers (nump);
        setPoints(points, nump: nump);
        buildHull();
    }
    
    func initBuffers ( nump:Int){
        if (pointBuffer.count < nump){
            var newBuffer =  [Vertex](count:nump, repeatedValue:Vertex())
            vertexPointIndices = [Int](count:nump,repeatedValue:0)
            for i in 0..<pointBuffer.count
            {
                newBuffer[i] = pointBuffer[i];
            }
            for i in pointBuffer.count..<nump
            {
                newBuffer[i] = Vertex();
            }
            pointBuffer = newBuffer;
        }
        faces.removeAll(keepCapacity: true)
        claimed.clear();
        numFaces = 0;
        numPoints = nump;
    }

    func setPoints (pnts:[Point3d],  nump:Int){
        for i in 0..<nump{
            let vtx = pointBuffer[i];
            vtx.pnt.set (pnts[i]);
            vtx.index = i;
        }
    }
    
    func buildHull(){
        var cnt = 0;
        var eyeVtx:Vertex;
    
        computeMaxAndMin();
        createInitialSimplex ();
        while let eyeVtx = nextPointToAdd() {
            addPointToHull (eyeVtx);
            cnt++;
            if (debug)
            {
                println("iteration \(cnt) done");
            }
        }
        reindexFacesAndVertices();
        if (debug)
        {
            println("hull done");
        }
    }
    
    
    func computeMaxAndMin (){
        var max = Vector3d();
        var min = Vector3d();
    
        for i in 0..<3{
            minVtxs[i] = pointBuffer[0];
            maxVtxs[i] = minVtxs[i]
        }
        max.set (pointBuffer[0].pnt);
        min.set (pointBuffer[0].pnt);
    
        for i in 1..<numPoints
        {
            let pnt = pointBuffer[i].pnt;
            if (pnt.x > max.x)
            {
                max.x = pnt.x;
                maxVtxs[0] = pointBuffer[i];
            }
            else if (pnt.x < min.x)
            {
                min.x = pnt.x;
                minVtxs[0] = pointBuffer[i];
            }
            if (pnt.y > max.y)
            {
                max.y = pnt.y;
                maxVtxs[1] = pointBuffer[i];
            }
            else if (pnt.y < min.y)
            {
                min.y = pnt.y;
                minVtxs[1] = pointBuffer[i];
            }
            if (pnt.z > max.z)
            {
                max.z = pnt.z;
                maxVtxs[2] = pointBuffer[i];
            }
            else if (pnt.z < min.z)
            {
                min.z = pnt.z;
                minVtxs[2] = pointBuffer[i];
            }
        }
    
        // this epsilon formula comes from QuickHull, and I'm
        // not about to quibble.
        charLength = Swift.max(max.x-min.x, max.y-min.y);
        charLength = Swift.max(max.z-min.z, charLength);
        if (explicitTolerance == QuickHull3D.AUTOMATIC_TOLERANCE){
            tolerance = 3 * QuickHull3D.DOUBLE_PREC * (Swift.max(abs(max.x),abs(min.x)) + Swift.max(abs(max.y),abs(min.y)) + Swift.max( abs(max.z),abs(min.z)));
        }
	   else{
            tolerance = explicitTolerance;
        }
    }

    
    
    /**
    * Creates the initial simplex from which the hull will be built.
    */
    func createInitialSimplex(){
	   var max = 0.0;
	   var imax = 0;
    
        for i in 0..<3{
            let diff = maxVtxs[i].pnt.get(i)-minVtxs[i].pnt.get(i);
            if (diff > max)
            {
                max = diff;
                imax = i;
            }
        }
        assert(max > tolerance, "Input points appear to be coincident")

        var vtx =  [Vertex](count:4, repeatedValue:Vertex());
        // set first two vertices to be those with the greatest
        // one dimensional separation
        vtx[0] = maxVtxs[imax];
        vtx[1] = minVtxs[imax];
    
        // set third vertex to be the vertex farthest from
        // the line between vtx0 and vtx1
        var u01 = Vector3d();
        var diff02 = Vector3d();
        var nrml = Vector3d();
        var xprod = Vector3d();
        
        var maxSqr = 0.0;
        u01.sub(vtx[1].pnt, v2: vtx[0].pnt);
        u01.normalize();
        for  i in 0..<numPoints{
            diff02.sub(pointBuffer[i].pnt, v2: vtx[0].pnt);
            xprod.cross(u01, v2: diff02);
            let lenSqr = xprod.normSquared();
            if (lenSqr > maxSqr && pointBuffer[i] !== vtx[0] && pointBuffer[i] !== vtx[1])
            {
                maxSqr = lenSqr;
                vtx[2] = pointBuffer[i];
                nrml.set (xprod);
            }
        }
        assert(sqrt(maxSqr) > 100 * tolerance, "Input points appear to be colinear");
    
        nrml.normalize();
    
    
        var maxDist = 0.0;
        var d0 = vtx[2].pnt.dot (nrml);
        
        for i in 0..<numPoints{
            let dist = abs (pointBuffer[i].pnt.dot(nrml) - d0);
            if (dist > maxDist && pointBuffer[i] !== vtx[0] && pointBuffer[i] !== vtx[1] && pointBuffer[i] !== vtx[2]){
                maxDist = dist;
                vtx[3] = pointBuffer[i];
            }
        }
        
        assert(sqrt(maxDist) > 100 * tolerance, "Input points appear to be colinear");

    
        if (debug){
            println("initial vertices:");
            println("\(vtx[0].index): \(vtx[0].pnt)");
            println("\(vtx[1].index): \(vtx[1].pnt)");
            println("\(vtx[2].index): \(vtx[2].pnt)");
            println("\(vtx[3].index): \(vtx[3].pnt)");
        }
    
        var tris = [Face](count:4, repeatedValue:Face());
    
        if (vtx[3].pnt.dot (nrml) - d0 < 0)
        {
            tris[0] = Face.createTriangle (vtx[0], v1: vtx[1], v2: vtx[2]);
            tris[1] = Face.createTriangle (vtx[3], v1: vtx[1], v2: vtx[0]);
            tris[2] = Face.createTriangle (vtx[3], v1: vtx[2], v2: vtx[1]);
            tris[3] = Face.createTriangle (vtx[3], v1: vtx[0], v2: vtx[2]);
        
            for i in 0..<3{
                let k = (i+1)%3;
                tris[i+1].getEdge(1).setOpposite (tris[k+1].getEdge(0));
                tris[i+1].getEdge(2).setOpposite (tris[0].getEdge(k));
            }
        }
        else{
            tris[0] = Face.createTriangle (vtx[0], v1: vtx[2], v2: vtx[1]);
            tris[1] = Face.createTriangle (vtx[3], v1: vtx[0], v2: vtx[1]);
            tris[2] = Face.createTriangle (vtx[3], v1: vtx[1], v2: vtx[2]);
            tris[3] = Face.createTriangle (vtx[3], v1: vtx[2], v2: vtx[0]);
    
            for i in 0..<3{
                let k = (i+1)%3;
                tris[i+1].getEdge(0).setOpposite (tris[k+1].getEdge(1));
                tris[i+1].getEdge(2).setOpposite (tris[0].getEdge((3-i)%3));
            }
        }
    
    
        for i in 0..<4{
            faces.append(tris[i]);
        }
    
        for i in 0..<numPoints{
            let v = pointBuffer[i];
    
            if (v === vtx[0] || v === vtx[1] || v === vtx[2] || v === vtx[3])
            {
                continue;
            }
    
            maxDist = tolerance;
            var maxFace:Face? = nil;
            for k in 0..<4{
                let dist = tris[k].distanceToPlane (v.pnt);
                if (dist > maxDist)
                {
                    maxFace = tris[k];
                    maxDist = dist;
                }
            }
            
            if (maxFace != nil)
            {
                addPointToFace (v, face: maxFace!);
            }
        }
    }
    
    
    func nextPointToAdd()->Vertex?{
        if (!claimed.isEmpty())
        {
            let eyeFace = claimed.first()!.face;
            var eyeVtx:Vertex? = nil;
            var maxDist = 0.0;
            for (var vtx = eyeFace!.outside; vtx != nil && vtx!.face === eyeFace; vtx = vtx!.next){
                let dist = eyeFace!.distanceToPlane(vtx!.pnt);
                if (dist > maxDist)
                {
                    maxDist = dist;
                    eyeVtx = vtx;
                }
            }
            return eyeVtx;
        }
        else
        {
            return nil;
        }
    }
    func addPointToHull(eyeVtx:Vertex ){
        horizon.removeAll(keepCapacity: true);
        unclaimed.clear();
    
        if (debug)
        {
            println ("Adding point:\(eyeVtx.index)");
            println (" which is \(eyeVtx.face!.distanceToPlane(eyeVtx.pnt)) above face \(eyeVtx.face!.getVertexString())");
        }
        removePointFromFace (eyeVtx, face: eyeVtx.face!);
        calculateHorizon (eyeVtx.pnt, edge: nil, face: eyeVtx.face!, horizon: &horizon);
        newFaces.clear();
        addNewFaces (newFaces, eyeVtx: eyeVtx, horizon: horizon);
    
        // first merge pass ... merge faces which are non-convex
        // as determined by the larger face
    
        for var face = newFaces.first(); face != nil; face = face!.next{
            if (face!.mark == Face.VISIBLE){
                while (doAdjacentMerge(face!, mergeType: QuickHull3D.NONCONVEX_WRT_LARGER_FACE))
                {}
            }
        }
        // second merge pass ... merge faces which are non-convex
        // wrt either face
        for var face = newFaces.first(); face != nil; face = face!.next{
            if (face!.mark == Face.NON_CONVEX)
            {
                face!.mark = Face.VISIBLE;
                while (doAdjacentMerge(face!, mergeType: QuickHull3D.NONCONVEX)){}
    
            }
        }
        resolveUnclaimedPoints(newFaces);
    }

    
    func reindexFacesAndVertices()
    {
        for i in 0..<numPoints{
            pointBuffer[i].index = -1;
        }
        // remove inactive faces and mark active vertices
        numFaces = 0;
        var newFaces = [Face]()
        for face in faces{
            if (face.mark == Face.VISIBLE){
                markFaceVertices (face, mark: 0);
                numFaces++;
                newFaces.append(face)
            }
        }
        faces = newFaces
        
        // reindex vertices
        numVertices = 0;
        for i in 0..<numPoints{
            let vtx = pointBuffer[i];
            if (vtx.index == 0)
            {
                vertexPointIndices[numVertices] = i;
                vtx.index = numVertices++;
            }
        }
    }
    
    func calculateHorizon (  eyePnt:Point3d,  edge edgeIn:HalfEdge?,  face:Face,inout horizon:[HalfEdge]){
        //     oldFaces.add (face);
        var edge0 = edgeIn
        deleteFacePoints (face, absorbingFace: nil);
        face.mark = Face.DELETED;
        if (debug){
            println("visiting face \(face.getVertexString())");
        }
        var edge:HalfEdge ;
        if (edge0 == nil)
        {
            edge0 = face.getEdge(0);
            edge = edge0!;
        }
        else
        {
            edge = edge0!.next!;
        }
        do
        {
            var oppFace = edge.oppositeFace()!;
            if (oppFace.mark == Face.VISIBLE)
            {
                if (oppFace.distanceToPlane (eyePnt) > tolerance){
        
                    calculateHorizon(eyePnt, edge: edge.opposite, face: oppFace, horizon: &horizon);
                }
                else
                {
                    horizon.append(edge);
                    if (debug){
                        println ("  adding horizon edge \(edge.getVertexString())");
                    }
                }
            }
            edge = edge.next!;
        }while (edge !== edge0);
    }
    func addNewFaces(newFaces:FaceList,  eyeVtx:Vertex, horizon:[HalfEdge]){
        newFaces.clear();
    
        var hedgeSidePrev:HalfEdge? = nil;
        var hedgeSideBegin:HalfEdge? = nil;
    
        for horizonHe in horizon{
            let hedgeSide = addAdjoiningFace (eyeVtx, he: horizonHe);
            if (debug){
                println("new face: \( hedgeSide.face.getVertexString())");
            }
            if (hedgeSidePrev != nil){
                hedgeSide.next!.setOpposite (hedgeSidePrev!);
            }
            else{
                hedgeSideBegin = hedgeSide;
            }
            newFaces.add(hedgeSide.face);
            hedgeSidePrev = hedgeSide;
        }
        hedgeSideBegin!.next!.setOpposite (hedgeSidePrev!);
    }
    
    
    func doAdjacentMerge ( face:Face,  mergeType:Int)->Bool{
        var hedge = face.he0;
        var convex = true;
        do
        {
            let oppFace = hedge.oppositeFace()!;
            var merge = false
            var dist1 = 0.0
            var dist2 = 0.0
    
            if (mergeType == QuickHull3D.NONCONVEX){ // then merge faces if they are definitively non-convex
                if (oppFaceDistance (hedge) > -tolerance || oppFaceDistance (hedge.opposite!) > -tolerance){
                    merge = true;
                }
            }
            else // mergeType == NONCONVEX_WRT_LARGER_FACE
            {
                // merge faces if they are parallel or non-convex
                // wrt to the larger face; otherwise, just mark
                // the face non-convex for the second pass.
                if (face.area > oppFace.area){
                    dist1 = oppFaceDistance (hedge)
                    if ( dist1 > -tolerance){
                        merge = true;
                    }
                    else if (oppFaceDistance (hedge.opposite!) > -tolerance){
                        convex = false;
                    }
                }
                else{
                    if (oppFaceDistance (hedge.opposite!) > -tolerance){
                        merge = true;
                    }
                    else if (oppFaceDistance (hedge) > -tolerance){
                        convex = false;
                    }
                }
            }
    
            if (merge){
                if (debug){
                    println ("  merging \(face.getVertexString()) and \( oppFace.getVertexString())");
                }
    
                let numd = face.mergeAdjacentFace (hedge, discarded: &discardedFaces);
                for  i in 0..<numd{
                    deleteFacePoints (discardedFaces[i], absorbingFace: face);
                }
                if (debug){
                    println("  result:\(face.getVertexString())");
                }
                return true;
            }
            hedge = hedge.next;
        }while (hedge !== face.he0);
        if (!convex)
        {
            face.mark = Face.NON_CONVEX;
        }
        return false;
    }

    func resolveUnclaimedPoints(newFaces:FaceList){
        var vtxNext = unclaimed.first();
        for var vtx = vtxNext; vtx != nil; vtx = vtxNext {
            vtxNext = vtx!.next;
            
            var maxDist = tolerance;
            var maxFace:Face? = nil;
            for var newFace = newFaces.first(); newFace != nil; newFace = newFace!.next {
                if (newFace!.mark == Face.VISIBLE){
                    let dist = newFace!.distanceToPlane(vtx!.pnt);
                    if (dist > maxDist){
                        maxDist = dist;
                        maxFace = newFace;
                    }
                    if (maxDist > 1000*tolerance){
                        break;
                    }
                }
            }
            if (maxFace != nil){
                addPointToFace (vtx!, face: maxFace!);
                if (debug && vtx!.index == findIndex){
                    println("\(findIndex) CLAIMED BY \(maxFace!.getVertexString())");
                }
            }
            else{
                if (debug && vtx!.index == findIndex){
                    println ("\(findIndex)  DISCARDED");
                } 
            }
        }
    }
    
    func markFaceVertices ( face:Face,  mark:Int)
    {
        let he0 = face.getFirstEdge();
        var he = he0;
        do
        {
            he.head().index = mark;
            he = he.next!;
        }while (he !== he0);
    }
    
    
    func deleteFacePoints ( face:Face,  absorbingFace:Face?){
        let faceVtxs = removeAllPointsFromFace (face);
        if (faceVtxs != nil){
            if (absorbingFace == nil){
                unclaimed.addAll (faceVtxs!);
            }
            else{
                var vtxNext = faceVtxs;
                for var vtx = vtxNext; vtx != nil; vtx = vtxNext{
                    vtxNext = vtx!.next;
                    let dist = absorbingFace!.distanceToPlane(vtx!.pnt);
                    if (dist > tolerance){
                        addPointToFace(vtx!,face: absorbingFace!);
                    }
                    else{
                        unclaimed.add(vtx!);
                    }
                }
            }
        }
    }
    
    func addAdjoiningFace(eyeVtx:Vertex, he:HalfEdge ) -> HalfEdge{
        var face = Face.createTriangle (eyeVtx, v1: he.tail()!, v2: he.head());
        faces.append(face);
        face.getEdge(-1).setOpposite(he.opposite!);
        return face.getEdge(0);
    }
    
    func oppFaceDistance (he:HalfEdge )->Double
    {
        return he.face.distanceToPlane (he.opposite!.face.getCentroid());
    }
    
    
    /**
    * Triangulates any non-triangular hull faces. In some cases, due to
    * precision issues, the resulting triangles may be very thin or small,
    * and hence appear to be non-convex (this same limitation is present
    * in <a href=http://www.qhull.org>qhull</a>).
    */
    public func triangulate()
    {
        let minArea = 1000 * charLength * QuickHull3D.DOUBLE_PREC;
        newFaces.clear();
        
        for face in faces{
            if(face.mark == Face.VISIBLE)
            {
                face.triangulate(newFaces, minArea: minArea);

            }
        }
        
        for var face = newFaces.first(); face != nil; face = face!.next{
            faces.append(face!);
        }
    }
    
}
    