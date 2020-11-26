function out = isPositiveIntegerValuedNumeric(input)
    out = rem(input, 1) == 0 && input > 0;
end

