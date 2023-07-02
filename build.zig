const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sliderule = b.dependency("sliderule", .{});
    const chalk = b.addModule("chalk", .{
        .source_file = std.Build.FileSource.relative("src/chalk.zig"),
        .dependencies = &.{.{ .name = "sliderule", .module = sliderule.module("sliderule") }},
    });

    const chalk_test = b.addTest(.{ .root_source_file = chalk.source_file, .target = target, .optimize = optimize });
    chalk_test.addModule("sliderule", sliderule.module("sliderule"));

    const run_chalk_test = b.addRunArtifact(chalk_test);
    //TODO: test chalk dependencies
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_chalk_test.step);
}
