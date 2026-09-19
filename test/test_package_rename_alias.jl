@testset "package rename compatibility alias" begin
    package_root = dirname(@__DIR__)
    check_code = """
    using GLLVModels
    GLLVModels.GLLVM === GLLVModels || error("GLLVM compatibility alias is not GLLVModels")
    """

    stdout_buffer = Pipe()
    stderr_buffer = Pipe()
    command = `$(Base.julia_cmd()) --startup-file=no --project=$package_root -e $check_code`
    process = run(pipeline(command; stdout=stdout_buffer, stderr=stderr_buffer); wait=false)
    close(stdout_buffer.in)
    close(stderr_buffer.in)
    stdout_text = read(stdout_buffer, String)
    stderr_text = read(stderr_buffer, String)
    wait(process)

    @test success(process)
    @test isempty(stdout_text)
    @test isempty(stderr_text)
end
