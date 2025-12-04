const std = @import("std");

pub fn main() !void {}

const MAX_OPERATOR_LEN = 16;

pub const CalcStatus = enum(u32) {
    success = 0,
    invalid_operator,
    division_by_zero,
    out_of_domain,
};

const CalcError = error{
    DivisionByZero,
    InvalidOperator,
    OutOfDomain,
};

pub export fn calc(
    operator_ptr: [*]const u8,
    operator_len: usize,
    operand1: f64,
    operand2: f64,
    out_result: *f64,
) CalcStatus {
    if (operator_len == 0 or operator_len > MAX_OPERATOR_LEN) return .invalid_operator;

    const operator = operator_ptr[0..operator_len];
    const result = performCalculator(operand1, operand2, operator) catch |err| return mapError(err);

    out_result.* = result;
    return .success;
}

pub export fn calc_modulo(a: f64, b: f64, out_result: *f64) CalcStatus {
    const value = safeModulo(a, b) catch |err| return mapError(err);
    out_result.* = value;
    return .success;
}

pub export fn calc_divide(a: f64, b: f64, out_result: *f64) CalcStatus {
    const value = safeDivide(a, b) catch |err| return mapError(err);
    out_result.* = value;
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

pub export fn calc_asin(value: f64, out_result: *f64) CalcStatus {
    const safe_value = safeAsin(value) catch |err| return mapError(err);
    out_result.* = safe_value;
    return .success;
}

pub export fn calc_acos(value: f64, out_result: *f64) CalcStatus {
    const safe_value = safeAcos(value) catch |err| return mapError(err);
    out_result.* = safe_value;
    return .success;
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
    const safe_value = safeSqrt(value) catch |err| return mapError(err);
    out_result.* = safe_value;
    return .success;
}

fn mapError(err: CalcError) CalcStatus {
    return switch (err) {
        error.DivisionByZero => .division_by_zero,
        error.OutOfDomain => .out_of_domain,
        error.InvalidOperator => .invalid_operator,
    };
}

fn performCalculator(num1: f64, num2: f64, operator: []const u8) CalcError!f64 {
    if (std.mem.eql(u8, operator, "sqrt")) return safeSqrt(num1);
    if (std.mem.eql(u8, operator, "sin")) return std.math.sin(num1);
    if (std.mem.eql(u8, operator, "cos")) return std.math.cos(num1);
    if (std.mem.eql(u8, operator, "tan")) return std.math.tan(num1);
    if (std.mem.eql(u8, operator, "asin")) return try safeAsin(num1);
    if (std.mem.eql(u8, operator, "acos")) return try safeAcos(num1);
    if (std.mem.eql(u8, operator, "atan")) return std.math.atan(num1);
    if (std.mem.eql(u8, operator, "atan2")) return std.math.atan2(num1, num2);
    if (std.mem.eql(u8, operator, "hypot")) return std.math.hypot(num1, num2);
    if (std.mem.eql(u8, operator, "expm1")) return std.math.expm1(num1);

    if (operator.len == 0) return error.InvalidOperator;

    return switch (operator[0]) {
        '+' => num1 + num2,
        '-' => num1 - num2,
        '*' => num1 * num2,
        '/' => try safeDivide(num1, num2),
        '^' => std.math.pow(f64, num1, num2),
        '%' => try safeModulo(num1, num2),
        else => error.InvalidOperator,
    };
}

fn safeDivide(a: f64, b: f64) CalcError!f64 {
    if (b == 0) return error.DivisionByZero;
    return a / b;
}

fn safeModulo(a: f64, b: f64) CalcError!f64 {
    if (b == 0) return error.DivisionByZero;
    return @mod(a, b);
}

fn safeSqrt(value: f64) CalcError!f64 {
    if (value < 0) return error.OutOfDomain;
    return std.math.sqrt(value);
}

fn safeAsin(value: f64) CalcError!f64 {
    if (value < -1 or value > 1) return error.OutOfDomain;
    return std.math.asin(value);
}

fn safeAcos(value: f64) CalcError!f64 {
    if (value < -1 or value > 1) return error.OutOfDomain;
    return std.math.acos(value);
}
