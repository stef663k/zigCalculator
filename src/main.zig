const std = @import("std");
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        if (args.len == 2 and try handleInlineExpression(args[1])) {
            return;
        }
        printUsage(args[0]);
        return;
    }

    if (try handlePrefixForm(args)) {
        return;
    }

    const num1 = std.fmt.parseFloat(f64, args[1]) catch {
        std.debug.print("Invalid number: {s}\n", .{args[1]});
        return;
    };
    const operator = args[2];

    const unary = isUnaryOperator(operator);

    var num2: f64 = 0;
    if (!unary) {
        if (args.len < 4) {
            std.debug.print("Operator '{s}' requires two operands.\n", .{operator});
            printUsage(args[0]);
            return;
        }

        num2 = std.fmt.parseFloat(f64, args[3]) catch {
            std.debug.print("Invalid number: {s}\n", .{args[3]});
            return;
        };
    }

    const result = performCalculator(num1, num2, operator) catch |err| {
        std.debug.print("Calculation failed: {s}\n", .{@errorName(err)});
        return;
    };

    std.debug.print("Result: {d}\n", .{result});
}

const unaryOperators = [_][]const u8{
    "sqrt", "sin", "cos", "tan", "asin", "acos", "atan", "expm1",
};

const binarySpecialOperators = [_][]const u8{
    "atan2", "hypot",
};

fn handlePrefixForm(args: []const [:0]u8) !bool {
    if (args.len < 3) return false;

    const op_token = args[1];

    if (std.mem.indexOfScalar(u8, op_token, '(')) |_| {
        if (try handleInlineExpression(op_token)) {
            return true;
        }
    }

    if (isUnaryOperator(op_token)) {
        const operand_token = normalizeOperandToken(args[2]);
        if (operand_token.len == 0) {
            std.debug.print("Error: missing operand for operator '{s}'\n", .{op_token});
            return true;
        }

        const num1 = std.fmt.parseFloat(f64, operand_token) catch {
            std.debug.print("Invalid number: {s}\n", .{operand_token});
            return true;
        };

        const result = try performCalculator(num1, 0, op_token);
        std.debug.print("Result: {d}\n", .{result});
        return true;
    }

    if (isBinaryOperator(op_token)) {
        if (args.len < 4) {
            std.debug.print("Operator '{s}' requires two operands.\n", .{op_token});
            return true;
        }

        const left_slice = normalizeOperandToken(args[2]);
        const right_slice = normalizeOperandToken(args[3]);

        if (left_slice.len == 0 or right_slice.len == 0) {
            std.debug.print("Error: missing operand for operator '{s}'\n", .{op_token});
            return true;
        }

        const num1 = std.fmt.parseFloat(f64, left_slice) catch {
            std.debug.print("Invalid number: {s}\n", .{left_slice});
            return true;
        };

        const num2 = std.fmt.parseFloat(f64, right_slice) catch {
            std.debug.print("Invalid number: {s}\n", .{right_slice});
            return true;
        };

        const result = try performCalculator(num1, num2, op_token);
        std.debug.print("Result: {d}\n", .{result});
        return true;
    }

    return false;
}

fn handleInlineExpression(expr: []const u8) !bool {
    const open_idx = std.mem.indexOfScalar(u8, expr, '(') orelse return false;
    const close_idx = std.mem.lastIndexOfScalar(u8, expr, ')') orelse {
        std.debug.print("Error: missing closing parenthesis in '{s}'\n", .{expr});
        return true;
    };

    const raw_operator = trimWhitespace(expr[0..open_idx]);
    if (raw_operator.len == 0) {
        std.debug.print("Error: missing operator before '('\n", .{});
        return true;
    }

    const inner = expr[open_idx + 1 .. close_idx];
    const comma_idx = std.mem.indexOfScalar(u8, inner, ',');

    const left_slice = if (comma_idx) |idx| inner[0..idx] else inner;
    const empty: []const u8 = "";
    const right_slice = if (comma_idx) |idx| inner[idx + 1 ..] else empty;

    const num1_slice = trimWhitespace(left_slice);
    if (num1_slice.len == 0) {
        std.debug.print("Error: missing operand inside parentheses\n", .{});
        return true;
    }

    const num1 = std.fmt.parseFloat(f64, num1_slice) catch {
        std.debug.print("Invalid number: {s}\n", .{num1_slice});
        return true;
    };

    var num2: f64 = 0;
    const has_second = comma_idx != null;

    if (has_second) {
        const num2_slice = trimWhitespace(right_slice);
        if (num2_slice.len == 0) {
            std.debug.print("Error: missing second operand after comma\n", .{});
            return true;
        }
        num2 = std.fmt.parseFloat(f64, num2_slice) catch {
            std.debug.print("Invalid number: {s}\n", .{num2_slice});
            return true;
        };
    }

    const unary = isUnaryOperator(raw_operator);
    const binary_special = isBinarySpecialOperator(raw_operator);

    if (has_second and unary and !binary_special) {
        std.debug.print("Operator '{s}' only accepts one operand.\n", .{raw_operator});
        return true;
    }

    if (!has_second and !unary and !binary_special) {
        std.debug.print("Operator '{s}' requires two operands.\n", .{raw_operator});
        return true;
    }

    const result = performCalculator(num1, num2, raw_operator) catch |err| {
        std.debug.print("Error: {s}\n", .{@errorName(err)});
        return true;
    };

    std.debug.print("Result: {d}\n", .{result});
    return true;
}

fn trimWhitespace(slice: []const u8) []const u8 {
    return std.mem.trim(u8, slice, " \t\r\n");
}

fn normalizeOperandToken(token: []const u8) []const u8 {
    return std.mem.trim(u8, token, " \t\r\n()");
}

fn isUnaryOperator(operator: []const u8) bool {
    for (unaryOperators) |op| {
        if (std.mem.eql(u8, operator, op)) return true;
    }
    return false;
}

fn isBinaryOperator(operator: []const u8) bool {
    return isBinarySpecialOperator(operator) or isBasicBinaryOperator(operator);
}

fn isBasicBinaryOperator(operator: []const u8) bool {
    if (operator.len != 1) return false;
    return switch (operator[0]) {
        '+', '-', '*', '/', '^', '%' => true,
        else => false,
    };
}

fn isBinarySpecialOperator(operator: []const u8) bool {
    for (binarySpecialOperators) |op| {
        if (std.mem.eql(u8, operator, op)) return true;
    }
    return false;
}

fn printUsage(exe_name: []const u8) void {
    std.debug.print("Usage:\n", .{});
    std.debug.print("  {s} <number1> <operator> <number2>\n", .{exe_name});
    std.debug.print("  {s} <number> <unary-operator>\n", .{exe_name});
    std.debug.print("  {s} operator(number)\n", .{exe_name});
    std.debug.print("  {s} operator(number1,number2)\n", .{exe_name});
    std.debug.print(
        "Operators: +, -, *, /, ^, %, sqrt, sin, cos, tan, asin, acos, atan, expm1, atan2, hypot\n",
        .{},
    );
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

    if (operator.len == 0) {
        std.debug.print("Error: Missing operator\n", .{});
        return error.InvalidOperator;
    }

    return switch (operator[0]) {
        '+' => num1 + num2,
        '-' => num1 - num2,
        '*' => num1 * num2,
        '/' => if (num2 == 0) {
            std.debug.print("Error: Division by zero\n", .{});
            return error.DivisionByZero;
        } else num1 / num2,
        '^' => std.math.pow(f64, num1, num2),
        '%' => if (num2 == 0) {
            std.debug.print("Error: Division by zero\n", .{});
            return error.DivisionByZero;
        } else @mod(num1, num2),
        else => {
            std.debug.print("Error: Invalid operator: {s}\n", .{operator});
            return error.InvalidOperator;
        },
    };
}
