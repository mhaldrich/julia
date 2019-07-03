@testset "var_str" begin
    @test macroexpand(@__MODULE__, :(var"@foo")) == Symbol("@foo")
    @test macroexpand(@__MODULE__, :(var"##")) == Symbol("##")
    @test macroexpand(@__MODULE__, :(var"a-b")) == Symbol("a-b")
end
