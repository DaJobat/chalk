const std = @import("std");
const Vec2 = @import("sliderule").Vec2;
const assert = std.debug.assert;
const meta = std.meta;

pub const Direction = enum { left, on, right };
pub fn LineSegment(comptime NumberType: type) type {
    comptime assert(meta.trait.isNumber(NumberType));

    return struct {
        const LineSeg = @This();
        pub const Point = Vec2(NumberType);

        start: Point,
        end: Point,

        pub fn length(l: LineSeg) NumberType {
            return (l.start.sub(l.end)).len();
        }

        pub fn pointDirection(l: LineSeg, pt: Point) Direction {
            const cross = (l.end.sub(l.start)).cross(pt.sub(l.start));
            if (cross > 0) {
                return .left;
            } else if (cross < 0) {
                return .right;
            } else return .on;
        }
    };
}

const testing = std.testing;
test "length" {
    const LS = LineSegment(f32);
    var ls = LS{ .start = .{}, .end = .{ .x = 3, .y = 4 } };
    try testing.expectEqual(@as(f32, 5), ls.length());
}

test "point direction" {
    const LS = LineSegment(f32);
    var ls = LS{ .start = .{}, .end = .{ .x = 3, .y = 4 } };

    try testing.expectEqual(Direction.right, ls.pointDirection(.{ .x = 1, .y = 0 }));
    try testing.expectEqual(Direction.on, ls.pointDirection(.{ .x = 3, .y = 4 }));
    try testing.expectEqual(Direction.left, ls.pointDirection(.{ .x = 0, .y = 2 }));
}
