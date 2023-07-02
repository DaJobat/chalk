const std = @import("std");
const Allocator = std.mem.Allocator;

const log = std.log.scoped(.convex_hull);
const Vec2 = @import("sliderule").Vec2;
const line_seg = @import("line_segment.zig");

pub fn convexHullAlloc(
    comptime PointType: type,
    allocator: Allocator,
    unsorted_points: []const PointType,
) (Allocator.Error || error{TooFewPoints})![]const PointType {
    var sorted_points = try allocator.alloc(PointType, unsorted_points.len);
    defer allocator.free(sorted_points);
    @memcpy(sorted_points, unsorted_points);
    std.sort.heap(PointType, sorted_points, {}, PointType.asc(.x));

    var out_buf = try allocator.alloc(PointType, sorted_points.len);
    const num = try convexHullBuf(PointType, sorted_points, out_buf);
    const shrink = allocator.resize(out_buf, num);
    std.debug.assert(shrink == true);
    return out_buf[0..num];
}

pub fn convexHullBuf(comptime PointType: type, sorted_points: []const PointType, out_buf: []PointType) error{TooFewPoints}!usize {
    if (sorted_points.len < 3) return error.TooFewPoints;

    out_buf[0] = sorted_points[0];
    out_buf[1] = sorted_points[1];
    var upper_buf_ptr: usize = 2;
    for (sorted_points[2..]) |point| {
        const current_buf = out_buf[0..upper_buf_ptr];
        const num_removed = convexInner(PointType, current_buf, point);

        upper_buf_ptr -= num_removed;
        out_buf[upper_buf_ptr] = point;
        upper_buf_ptr += 1;
    }

    //Copy out the last two points from the upper hull, we'll replace these after using the memory for the lower hull
    const upper_last_two: [2]PointType = .{ out_buf[upper_buf_ptr - 2], out_buf[upper_buf_ptr - 1] };

    //the lower hull buffer starts here
    const lower_start = upper_buf_ptr - 2;
    out_buf[lower_start] = sorted_points[sorted_points.len - 1];
    out_buf[lower_start + 1] = sorted_points[sorted_points.len - 2];
    var lower_buf_ptr: usize = 2;

    var lower_buf = out_buf[lower_start..];

    //FIXME: Hopefully reverse for loops will work sometime
    var i: usize = sorted_points.len - 2;
    while (i > 0) {
        i -= 1;
        const point = sorted_points[i];

        const lower_hull = lower_buf[0..lower_buf_ptr];
        const num_removed = convexInner(PointType, lower_hull, point);

        lower_buf_ptr -= num_removed;
        lower_buf[lower_buf_ptr] = point;
        lower_buf_ptr += 1;
    }

    std.mem.copyBackwards(PointType, lower_buf[2..lower_buf_ptr], lower_buf[1 .. lower_buf_ptr - 1]);
    //get rid of the first and last points in lower_buf, as they're guaranteed duplicates (last is the first sorted point, first is the last sorted point)
    @memcpy(lower_buf[0..2], &upper_last_two); //replace the last two points of the upper buf

    return upper_buf_ptr + lower_buf_ptr - 2;
}

fn convexInner(comptime PointType: type, points: []PointType, next_point: PointType) usize {
    const Line = line_seg.LineSegment(PointType.NumberType);
    var num_removed: usize = 0;
    while (points.len - num_removed > 1) {
        const last_but_two = points.len - num_removed - 2;
        const last_but_one = points.len - num_removed - 1;

        const line = Line{ .start = points[last_but_two], .end = points[last_but_one] };
        if (line.pointDirection(next_point) != .right) {
            num_removed += 1;
        } else break; //break if the last three points all go right
    }

    return num_removed;
}

const testing = std.testing;
test {
    const Point = Vec2(i32);
    var pts = [5]Point{
        .{ .x = 4, .y = 0 },
        .{ .x = 3, .y = 0 },
        .{ .x = 2, .y = 0 },
        .{ .x = 1, .y = 0 },
        .{ .x = 0, .y = 0 },
    };
    const hull_pts = try convexHullAlloc(Point, testing.allocator, &pts);
    testing.allocator.free(hull_pts);
}
