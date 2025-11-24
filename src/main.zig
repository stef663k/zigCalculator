const std = @import("std");

pub fn main() !void {}

pub const CalcStatus = enum(u32) {
    success = 0,
    invalid_operator,
    division_by_zero,
};

pub export fn calc(
    operator_ptr: [*]const u8,
    operator_len: usize,
    operand1: f64,
    operand2: f64,
    out_result: *f64,
) CalcStatus {
    const operator = operator_ptr[0..operator_len];
    const result = performCalculator(operand1, operand2, operator) catch |err| {
        return mapError(err);
    };

    out_result.* = result;
    return .success;
}

pub export fn calc_add(a: f64, b: f64) f64 {
    return a + b;
}

pub export fn calc_subtract(a: f64, b: f64) f64 {
    return a - b;
}

pub export fn calc_multiply(a: f64, b: f64) f64 {
    return a * b;
}

pub export fn calc_power(a: f64, b: f64) f64 {
    return std.math.pow(f64, a, b);
}

pub export fn calc_modulo(a: f64, b: f64, out_result: *f64) CalcStatus {
    if (b == 0) return .division_by_zero;
    out_result.* = @mod(a, b);
    return .success;
}

pub export fn calc_divide(a: f64, b: f64, out_result: *f64) CalcStatus {
    if (b == 0) return .division_by_zero;
    out_result.* = a / b;
    return .success;
}

pub export fn calc_sin(value: f64) f64 {
    return std.math.sin(value);
}

pub export fn calc_cos(value: f64) f64 {
    return std.math.cos(value);
}

pub export fn calc_tan(value: f64) f64 {
    return std.math.tan(value);
}

pub export fn calc_asin(value: f64) f64 {
    return std.math.asin(value);
}

pub export fn calc_acos(value: f64) f64 {
    return std.math.acos(value);
}

pub export fn calc_atan(value: f64) f64 {
    return std.math.atan(value);
}

pub export fn calc_atan2(a: f64, b: f64) f64 {
    return std.math.atan2(a, b);
}

pub export fn calc_hypot(a: f64, b: f64) f64 {
    return std.math.hypot(a, b);
}

pub export fn calc_expm1(value: f64) f64 {
    return std.math.expm1(value);
}

pub export fn calc_sqrt(value: f64, out_result: *f64) CalcStatus {
    out_result.* = std.math.sqrt(value);
    return .success;
}

fn mapError(err: anyerror) CalcStatus {
    return switch (err) {
        error.DivisionByZero => .division_by_zero,
        error.InvalidOperator => .invalid_operator,
        else => .invalid_operator,
    };
}

fn performCalculator(num1: f64, num2: f64, operator: []const u8) !f64 {
    if (std.mem.eql(u8, operator, "sqrt")) return std.math.sqrt(num1);
    if (std.mem.eql(u8, operator, "sin")) return std.math.sin(num1);
    if (std.mem.eql(u8, operator, "cos")) return std.math.cos(num1);
    if (std.mem.eql(u8, operator, "tan")) return std.math.tan(num1);
    if (std.mem.eql(u8, operator, "asin")) return std.math.asin(num1);
    if (std.mem.eql(u8, operator, "acos")) return std.math.acos(num1);
    if (std.mem.eql(u8, operator, "atan")) return std.math.atan(num1);
    if (std.mem.eql(u8, operator, "atan2")) return std.math.atan2(num1, num2);
    if (std.mem.eql(u8, operator, "hypot")) return std.math.hypot(num1, num2);
    if (std.mem.eql(u8, operator, "expm1")) return std.math.expm1(num1);

    if (operator.len == 0) return error.InvalidOperator;

    return switch (operator[0]) {
        '+' => num1 + num2,
        '-' => num1 - num2,
        '*' => num1 * num2,
        '/' => if (num2 == 0) error.DivisionByZero else num1 / num2,
        '^' => std.math.pow(f64, num1, num2),
        '%' => if (num2 == 0) error.DivisionByZero else @mod(num1, num2),
        else => error.InvalidOperator,
    };
}
