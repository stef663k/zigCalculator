const std = @import("std");

pub fn main() !void {}

pub const CalcStatus = enum(u32) {
    success = 0,
    invalid_operator,
    division_by_zero,
};

/// Evaluates the given operator with the operands.
/// Returns a status code and writes the result to `out_result` on success.
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

/// Convenience exports for direct use from JavaScript or other hosts.
pub export fn calc_add(a: f64, b: f64) f64 {
    return opAdd(a, b);
}

pub export fn calc_subtract(a: f64, b: f64) f64 {
    return opSubtract(a, b);
}

pub export fn calc_multiply(a: f64, b: f64) f64 {
    return opMultiply(a, b);
}

pub export fn calc_power(a: f64, b: f64) f64 {
    return opPower(a, b);
}

pub export fn calc_modulo(a: f64, b: f64, out_result: *f64) CalcStatus {
    const result = opModulo(a, b) catch |err| {
        return mapError(err);
    };
    out_result.* = result;
    return .success;
}

pub export fn calc_divide(a: f64, b: f64, out_result: *f64) CalcStatus {
    const result = opDivide(a, b) catch |err| {
        return mapError(err);
    };
    out_result.* = result;
    return .success;
}

pub export fn calc_sin(value: f64) f64 {
    return opSin(value);
}

pub export fn calc_cos(value: f64) f64 {
    return opCos(value);
}

pub export fn calc_tan(value: f64) f64 {
    return opTan(value);
}

pub export fn calc_asin(value: f64) f64 {
    return opAsin(value);
}

pub export fn calc_acos(value: f64) f64 {
    return opAcos(value);
}

pub export fn calc_atan(value: f64) f64 {
    return opAtan(value);
}

pub export fn calc_atan2(a: f64, b: f64) f64 {
    return opAtan2(a, b);
}

pub export fn calc_hypot(a: f64, b: f64) f64 {
    return opHypot(a, b);
}

pub export fn calc_expm1(value: f64) f64 {
    return opExpm1(value);
}

pub export fn calc_sqrt(value: f64, out_result: *f64) CalcStatus {
    const result = opSqrt(value) catch |err| {
        return mapError(err);
    };
    out_result.* = result;
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
    if (std.mem.eql(u8, operator, "sqrt")) return try opSqrt(num1);
    if (std.mem.eql(u8, operator, "sin")) return opSin(num1);
    if (std.mem.eql(u8, operator, "cos")) return opCos(num1);
    if (std.mem.eql(u8, operator, "tan")) return opTan(num1);
    if (std.mem.eql(u8, operator, "asin")) return opAsin(num1);
    if (std.mem.eql(u8, operator, "acos")) return opAcos(num1);
    if (std.mem.eql(u8, operator, "atan")) return opAtan(num1);
    if (std.mem.eql(u8, operator, "atan2")) return opAtan2(num1, num2);
    if (std.mem.eql(u8, operator, "hypot")) return opHypot(num1, num2);
    if (std.mem.eql(u8, operator, "expm1")) return opExpm1(num1);

    if (operator.len == 0) {
        return error.InvalidOperator;
    }

    return switch (operator[0]) {
        '+' => opAdd(num1, num2),
        '-' => opSubtract(num1, num2),
        '*' => opMultiply(num1, num2),
        '/' => try opDivide(num1, num2),
        '^' => opPower(num1, num2),
        '%' => try opModulo(num1, num2),
        else => error.InvalidOperator,
    };
}

fn opAdd(a: f64, b: f64) f64 {
    return a + b;
}

fn opSubtract(a: f64, b: f64) f64 {
    return a - b;
}

fn opMultiply(a: f64, b: f64) f64 {
    return a * b;
}

fn opDivide(a: f64, b: f64) !f64 {
    if (b == 0) return error.DivisionByZero;
    return a / b;
}

fn opPower(a: f64, b: f64) f64 {
    return std.math.pow(f64, a, b);
}

fn opModulo(a: f64, b: f64) !f64 {
    if (b == 0) return error.DivisionByZero;
    return @mod(a, b);
}

fn opSqrt(value: f64) !f64 {
    return std.math.sqrt(value);
}

fn opSin(value: f64) f64 {
    return std.math.sin(value);
}

fn opCos(value: f64) f64 {
    return std.math.cos(value);
}

fn opTan(value: f64) f64 {
    return std.math.tan(value);
}

fn opAsin(value: f64) f64 {
    return std.math.asin(value);
}

fn opAcos(value: f64) f64 {
    return std.math.acos(value);
}

fn opAtan(value: f64) f64 {
    return std.math.atan(value);
}

fn opAtan2(a: f64, b: f64) f64 {
    return std.math.atan2(a, b);
}

fn opHypot(a: f64, b: f64) f64 {
    return std.math.hypot(a, b);
}

fn opExpm1(value: f64) f64 {
    return std.math.expm1(value);
}
