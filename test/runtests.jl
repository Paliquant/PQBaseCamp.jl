using PQBaseCamp
using Test

# -- Default test ------------------------------------------------------ #
function default_pqbasecamp_test() 
    return true
end
# ------------------------------------------------------------------------------- #

@testset "default_test_set" begin
    @test default_pqbasecamp_test() == true
end