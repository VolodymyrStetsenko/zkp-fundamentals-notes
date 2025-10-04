// Secret Guess example written by Volodymyr
// Prove knowledge of x such that x^2 = 4 without revealing x
fn main(private secret: Field) {
    let result: Field = secret * secret;
    assert(result == 4);
}
