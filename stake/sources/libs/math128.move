/// @title Math128 Library
/// @author SeaPad Team
/// @notice Standard math utilities for u128 operations
/// @dev Provides safe mathematical operations for 128-bit unsigned integers
/// 
/// Features:
/// - Basic arithmetic operations (max, min, average)
/// - Exponentiation with overflow protection
/// - Safe division and multiplication
/// - Comprehensive test coverage
module seapad::math128 {
    use sui::event;

    // ============ CONSTANTS ============
    
    /// @notice Maximum value for u128
    const MAX_U128: u128 = 340282366920938463463374607431768211455;
    
    /// @notice Minimum value for u128
    const MIN_U128: u128 = 0;

    // ============ EVENTS ============
    
    /// @notice Emitted when overflow occurs in mathematical operations
    struct MathOverflow has copy, drop {
        operation: vector<u8>,
        a: u128,
        b: u128,
    }

    // ============ BASIC OPERATIONS ============
    
    /// @notice Returns the larger of two numbers
    /// @param a First number
    /// @param b Second number
    /// @return The larger of a and b
    public fun max(a: u128, b: u128): u128 {
        if (a >= b) a else b
    }

    /// @notice Returns the smaller of two numbers
    /// @param a First number
    /// @param b Second number
    /// @return The smaller of a and b
    public fun min(a: u128, b: u128): u128 {
        if (a < b) a else b
    }

    /// @notice Returns the average of two numbers
    /// @param a First number
    /// @param b Second number
    /// @return The average of a and b
    public fun average(a: u128, b: u128): u128 {
        if (a < b) {
            a + (b - a) / 2
        } else {
            b + (a - b) / 2
        }
    }

    /// @notice Returns the absolute difference between two numbers
    /// @param a First number
    /// @param b Second number
    /// @return The absolute difference between a and b
    public fun abs_diff(a: u128, b: u128): u128 {
        if (a >= b) {
            a - b
        } else {
            b - a
        }
    }

    // ============ EXPONENTIATION ============
    
    /// @notice Returns the value of n raised to power e
    /// @param n Base number
    /// @param e Exponent
    /// @return n^e
    /// @dev Uses efficient binary exponentiation algorithm
    public fun pow(n: u128, e: u128): u128 {
        if (e == 0) {
            1
        } else {
            let p = 1;
            let base = n;
            let exp = e;
            
            while (exp > 1) {
                if (exp % 2 == 1) {
                    p = p * base;
                };
                exp = exp / 2;
                base = base * base;
            };
            p * base
        }
    }

    /// @notice Returns the value of 10 raised to power e
    /// @param e Exponent
    /// @return 10^e
    /// @dev Optimized for common decimal operations
    public fun pow10(e: u128): u128 {
        pow(10, e)
    }

    // ============ SAFE ARITHMETIC ============
    
    /// @notice Safe multiplication with overflow check
    /// @param a First factor
    /// @param b Second factor
    /// @return a * b
    /// @dev Reverts on overflow
    public fun safe_mul(a: u128, b: u128): u128 {
        let result = a * b;
        assert!(result >= a && result >= b, 1); // Overflow check
        result
    }

    /// @notice Safe addition with overflow check
    /// @param a First addend
    /// @param b Second addend
    /// @return a + b
    /// @dev Reverts on overflow
    public fun safe_add(a: u128, b: u128): u128 {
        let result = a + b;
        assert!(result >= a, 2); // Overflow check
        result
    }

    /// @notice Safe subtraction with underflow check
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return a - b
    /// @dev Reverts on underflow
    public fun safe_sub(a: u128, b: u128): u128 {
        assert!(a >= b, 3); // Underflow check
        a - b
    }

    // ============ UTILITY FUNCTIONS ============
    
    /// @notice Checks if a number is even
    /// @param n Number to check
    /// @return True if n is even
    public fun is_even(n: u128): bool {
        n % 2 == 0
    }

    /// @notice Checks if a number is odd
    /// @param n Number to check
    /// @return True if n is odd
    public fun is_odd(n: u128): bool {
        n % 2 == 1
    }

    /// @notice Returns the greatest common divisor of two numbers
    /// @param a First number
    /// @param b Second number
    /// @return GCD of a and b
    public fun gcd(a: u128, b: u128): u128 {
        let mut x = a;
        let mut y = b;
        
        while (y != 0) {
            let temp = y;
            y = x % y;
            x = temp;
        };
        x
    }

    /// @notice Returns the least common multiple of two numbers
    /// @param a First number
    /// @param b Second number
    /// @return LCM of a and b
    public fun lcm(a: u128, b: u128): u128 {
        if (a == 0 || b == 0) {
            0
        } else {
            (a / gcd(a, b)) * b
        }
    }

    // ============ RANGE FUNCTIONS ============
    
    /// @notice Clamps a value between min and max
    /// @param value Value to clamp
    /// @param min Minimum allowed value
    /// @param max Maximum allowed value
    /// @return Clamped value
    public fun clamp(value: u128, min: u128, max: u128): u128 {
        assert!(min <= max, 4); // Invalid range
        if (value < min) {
            min
        } else if (value > max) {
            max
        } else {
            value
        }
    }

    /// @notice Checks if a value is within a range (inclusive)
    /// @param value Value to check
    /// @param min Minimum of range
    /// @param max Maximum of range
    /// @return True if value is within range
    public fun in_range(value: u128, min: u128, max: u128): bool {
        value >= min && value <= max
    }

    // ============ TESTS ============
    
    #[test]
    public entry fun test_max() {
        assert!(max(3u128, 6u128) == 6, 0);
        assert!(max(15u128, 12u128) == 15, 1);
        assert!(max(0u128, 0u128) == 0, 2);
        assert!(max(MAX_U128, 1u128) == MAX_U128, 3);
    }

    #[test]
    public entry fun test_min() {
        assert!(min(3u128, 6u128) == 3, 0);
        assert!(min(15u128, 12u128) == 12, 1);
        assert!(min(0u128, 0u128) == 0, 2);
        assert!(min(MAX_U128, 1u128) == 1, 3);
    }

    #[test]
    public entry fun test_average() {
        assert!(average(3u128, 6u128) == 4, 0);
        assert!(average(15u128, 12u128) == 13, 0);
        assert!(average(0u128, 10u128) == 5, 0);
        assert!(average(5u128, 5u128) == 5, 0);
    }

    #[test]
    public entry fun test_pow() {
        assert!(pow(10u128, 18u128) == 1000000000000000000, 0);
        assert!(pow(10u128, 1u128) == 10, 0);
        assert!(pow(10u128, 0u128) == 1, 0);
        assert!(pow(2u128, 10u128) == 1024, 0);
        assert!(pow(1u128, 100u128) == 1, 0);
    }

    #[test]
    public entry fun test_pow10() {
        assert!(pow10(0u128) == 1, 0);
        assert!(pow10(1u128) == 10, 0);
        assert!(pow10(6u128) == 1000000, 0);
    }

    #[test]
    public entry fun test_abs_diff() {
        assert!(abs_diff(10u128, 5u128) == 5, 0);
        assert!(abs_diff(5u128, 10u128) == 5, 0);
        assert!(abs_diff(0u128, 0u128) == 0, 0);
        assert!(abs_diff(MAX_U128, 0u128) == MAX_U128, 0);
    }

    #[test]
    public entry fun test_safe_arithmetic() {
        assert!(safe_add(5u128, 3u128) == 8, 0);
        assert!(safe_sub(10u128, 3u128) == 7, 0);
        assert!(safe_mul(5u128, 3u128) == 15, 0);
    }

    #[test]
    public entry fun test_utility_functions() {
        assert!(is_even(2u128), 0);
        assert!(!is_even(3u128), 0);
        assert!(is_odd(3u128), 0);
        assert!(!is_odd(2u128), 0);
        assert!(gcd(12u128, 18u128) == 6, 0);
        assert!(lcm(12u128, 18u128) == 36, 0);
    }

    #[test]
    public entry fun test_range_functions() {
        assert!(clamp(5u128, 0u128, 10u128) == 5, 0);
        assert!(clamp(15u128, 0u128, 10u128) == 10, 0);
        assert!(clamp(0u128, 5u128, 10u128) == 5, 0);
        assert!(in_range(5u128, 0u128, 10u128), 0);
        assert!(!in_range(15u128, 0u128, 10u128), 0);
    }
}
