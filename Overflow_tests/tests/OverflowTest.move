#[test_only]
module testing::overflowTest{
    const EOVERFLOW: u64 = 1;
    const EUNDERFLOW: u64 = 2;

// ARITHMETIC OPERATIONS
    //Overflow caught by compiler
    #[test]
    fun test_overflow(): u8 {
        let num1: u8 = 255;
        num1 = num1 + 1;
        return num1
    }

    //Underflow caught by compiler
    #[test]
    fun test_underflow(): u8 {
        let num1: u8 = 0;
        num1 = num1 - 1;
        return num1
    }

// BITWISE OPERATIONS
    //Overflow not caught by compiler. It has to be checked separatly 
    #[test]
    #[expected_failure(abort_code = EOVERFLOW)]
    fun test_overflow_bitshift(): u8 {
       let num1: u8 = 255;
       let num2: u8 = num1 << 2;
       assert!(num2 > num1, EOVERFLOW);
       return num2
    }
}