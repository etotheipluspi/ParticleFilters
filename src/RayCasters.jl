# TODO: dealing with type assertions for points tuples vs arrays


# module for determining line of sight visibility in 2D
module RayCasters


export isVisible, inBuilding
export rayIntersectsSeg, segmentsIntersect
export nearest_wall


using Maps


# returns true if p1 and p2 are within LOS given the map geometry
function isVisible(map::Map, p1, p2)
    return isVisible(map, p1[1], p1[2], p2[1], p2[2])
end


function isVisible(map::Map, p1x, p1y, p2x, p2y)
    for b in map.buildings
        if !isVisible(b, p1x, p1y, p2x, p2y) 
            return false
        end
    end
    return true
end


# check if points within line of sight given a polygon
# overloaded to add more shapes
function isVisible(b::Polygon, p1x, p1y, p2x, p2y) 
    points = b.points
    nPoints = size(points,1)

    for i = 1:nPoints
        # last point makes a segment with the first
        if i == nPoints
            if segmentsIntersect(p1x, p1y, p2x, p2y, 
                                 points[i,1], points[i,2], points[1,1], points[1,2])
                return false
            end
        else
            if segmentsIntersect(p1x, p1y, p2x, p2y, 
                                 points[i,1], points[i,2], points[i+1,1], points[i+1,2])
                return false
            end
        end
    end
    return true
end


# checks if a point is inside a building 
function inBuilding(map::Map, p)
    return inBuilding(map, p[1], p[2])
end


# checks if a point is inside a building 
function inBuilding(map::Map, p1, p2)
    for b in map.buildings
        if inBuilding(b, p1, p2)
            return true
        end
    end
    return false
end

# check if a point p is inside a polygon
function inBuilding(b::Polygon, px, py)

    points = b.points
    nPoints = size(points,1)
    count = 0

    for i = 1:nPoints
        # last point makes a segment with the first
        if i == nPoints
            if rayIntersectsSeg(px, py, points[i,1], points[i,2], points[1,1], points[1,2])
                count += 1
            end
        else
            if rayIntersectsSeg(px, py, points[i,1], points[i,2], points[i+1,1], points[i+1,2])
                count += 1
            end
        end
    end

    if count % 2 == 1
        return true
    end
    return false
end


# checks if a point p intersect a line segment with ends a, b
# adopted from python implementation on Rosetta Code
# source: http://rosettacode.org/wiki/Ray-casting_algorithm#Python
function rayIntersectsSeg(px, py, ax, ay, bx, by)
    EPSILON = 0.001
    _huge = 1e300
    _tiny = 1e-300

    if ay > by
        ax,ay,bx,by = bx,by,ax,ay
    end
    if py == ay || py == by
        py = py + EPSILON
    end

    intersect = false

    if (py > by || py < ay) || (px > max(ax, bx))
        return false
    end

    if px < min(ax, bx)
        intersect = true
    else
        if abs(ax - bx) > _tiny
            m_red = (by - ay) / float(bx - ax)
        else
            m_red = _huge
        end
        if abs(ax - px) > _tiny
            m_blue = (py - ay) / float(px - ax)
        else
            m_blue = _huge
        end
        intersect = m_blue >= m_red
    end
    return intersect
end


# check if two 2D line segments intersect
# based on javascript code from:
# https://github.com/pgkelley4/line-segments-intersect/blob/master/js/line-segments-intersect.js
function segmentsIntersect(p::Array, p2::Array, q::Array, q2::Array)
    r = p2 - p
    s = q2 - q
    uNum = cross2D(q - p, r)
    denom = cross2D(r, s)
    # check if lines are collinear
    if uNum == 0 && denom == 0
        # do they touch?
        if p == q || p == p2 || p2 == q || p2 == q2
            return true
        end
        # do they overlap?
        return ((q[1] - p[1] < 0) != (q[1] - p2[1] < 0) != (q2[1] - p[1] < 0) != (q2[1] - p2[1] < 0) ||
                (q[2] - p[2] < 0) != (q[2] - p2[2] < 0) != (q2[2] - p[2] < 0) != (q2[2] - p2[2] < 0))
    end
    # lines are parallel
    if denom == 0
        return false
    end
    u = uNum / denom
    t = cross2D(q - p, s) / denom
    return (t >= 0) && (t <= 1) && (u >= 0) && (u <= 1)
end

function segmentsIntersect(px::Float64, py::Float64, p2x::Float64, p2y::Float64, 
                           qx::Float64, qy::Float64, q2x::Float64, q2y::Float64)
    p  = [px, py]
    p2 = [p2x, p2y]
    q  = [qx, qy]
    q2 = [q2x, q2y]
    return segmentsIntersect(p, p2, q, q2)
end

# compute cross product in 2D
function cross2D(l1, l2)
    return l1[1] * l2[2] - l1[2] * l2[1]
end


# computes distance to nearest wall for a given direction
function nearest_wall(map::Map, p::Vector{Float64}, dir::Symbol)

    # find y-intercept
    d = Inf
    for b in map.buildings
        nd = nearest_wall(b, p, dir)
        if nd < d
            d = nd
        end
    end

    return d
end

function nearest_wall(b::Polygon, p::Vector{Float64}, dir::Symbol)
    x = p[1]
    y = p[2]
    yo = p[2]

    # only works for down
    step = y / 100.
    for i = 1:100
        y -= i*step
        if inBuilding(b, x, y)
            return abs(yo - y)
        end
    end
    return yo
end

end # module
