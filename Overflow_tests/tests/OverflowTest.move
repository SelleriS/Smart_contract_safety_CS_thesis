#[test_only]
module testing::overflowTest{
    const EOVERFLOW: u64 = 1;

    //Overflow caught by compiler
    #[test]
    //#[expected_failure(arithmetic_error)]
    fun test_overflow(): u8 {
    let integer: u8 = 255;
    integer = integer + 1;
    return integer
    }


    //Overflow not caught by compiler. It had to be checked separatly 
    #[test]
    #[expected_failure(abort_code = EOVERFLOW)]
   fun test_overflow_bitshift(): u8 {
       let num1: u8 = 255;
       let num2: u8 = num1 << 2;
       assert!(num2>num1, EOVERFLOW);
       return num2
   }
}