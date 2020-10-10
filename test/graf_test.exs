defmodule GrafTest do
  use ExUnit.Case, async: true

  test "a module calling another module creates an edge on the graph" do
    # given
    project = "module_a_calls_b"
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project)

    # then
    assert Jason.decode!(output) ==
             [%{"name" => "A", "imports" => ["B"]}, %{"name" => "B", "imports" => []}]
  end

  test "a module calling another module non-tail recursively creates an edge on the graph" do
    # given
    project = "module_a_calls_b_no_tail_recursion"
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project)

    # then
    assert Jason.decode!(output) ==
             [%{"name" => "A", "imports" => ["B"]}, %{"name" => "B", "imports" => []}]
  end

  test "a module calling another module and being called by that module generates cycle on the graph" do
    # given
    project = "module_a_calls_b_and_b_calls_a"
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project)

    # then
    assert Jason.decode!(output) ==
             [%{"name" => "A", "imports" => ["B"]}, %{"name" => "B", "imports" => ["A"]}]
  end

  test "a module referencing another via capture creates an edge on the graph" do
    # given
    project = "module_a_references_function_from_b"
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project)

    # then
    assert Jason.decode!(output) ==
             [%{"name" => "A", "imports" => ["B"]}, %{"name" => "B", "imports" => []}]
  end

  test "a module referencing a module in another module in umbrella creates an edge on the graph" do
    # given
    project = "module_a_calls_b_in_umbrella"
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project)

    # then
    assert Jason.decode!(output) ==
             [%{"name" => "A", "imports" => ["B"]}, %{"name" => "B", "imports" => []}]
  end

  test "a module referencing a module in another module in different projects creates an edge on the graph" do
    # given
    project1 = "module_a_calls_b"
    project2 = "module_c_calls_b"
    project_compiled(project1)
    project_compiled(project2)
    graph_generator_compiled()

    # when
    output = graph_generated([project1, project2])

    # then
    assert Jason.decode!(output) ==
             [
               %{"name" => "A", "imports" => ["B"]},
               %{"name" => "B", "imports" => []},
               %{"name" => "C", "imports" => ["B"]}
             ]
  end

  test "a module using a struct from another module creates an edge on the graph" do
    # given
    project = "module_a_uses_struct_from_b"
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project)

    # then
    assert Jason.decode!(output) ==
             [%{"name" => "A", "imports" => ["B"]}, %{"name" => "B", "imports" => []}]
  end

  test "a module matching on a struct from another module creates an edge on the graph" do
    # given
    project = "module_a_matches_on_a_struct_from_b"
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project)

    # then
    assert Jason.decode!(output) ==
             [%{"name" => "A", "imports" => ["B"]}, %{"name" => "B", "imports" => []}]
  end

  test "a module matching on multiple structs creates edges on the graph" do
    # given
    project = "module_a_matches_on_a_struct_from_b_and_c"
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project)

    # then
    assert Jason.decode!(output) ==
             [
               %{"name" => "A", "imports" => ["B", "C"]},
               %{"name" => "B", "imports" => []},
               %{"name" => "C", "imports" => []}
             ]
  end

  test "a module matching on multiple structs in different clauses creates edges on the graph" do
    # given
    project = "module_a_matches_on_a_struct_from_b_and_c_in_different_clauses"
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project)

    # then
    assert Jason.decode!(output) ==
             [
               %{"name" => "A", "imports" => ["B", "C"]},
               %{"name" => "B", "imports" => []},
               %{"name" => "C", "imports" => []}
             ]
  end

  test "a module calling dependency module with --max-deps-depth=0 " <>
         "doesn't create an edge on the graph" do
    # given
    project = "module_a_calls_dep_without_any_deps"
    deps_fetched_for_project(project)
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project, ["--max-deps-depth=0"])

    # then
    assert Jason.decode!(output) == []
  end

  test "a module calling dependency module with --max-deps-depth=1 " <>
         "creates an edge on the graph" do
    # given
    project = "module_a_calls_dep_without_any_deps"
    deps_fetched_for_project(project)
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project, ["--max-deps-depth=1"])

    # then
    assert Jason.decode!(output) == [
             %{"name" => "A", "imports" => ["FE.Maybe"]},
             %{"name" => "FE.Maybe", "imports" => []}
           ]
  end

  test "a module calling dependency module with --max-deps-depth=2 " <>
         "creates edges from module to dep and from dep to called modules" do
    # given
    project = "module_a_calls_dep_without_any_deps"
    deps_fetched_for_project(project)
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project, ["--max-deps-depth=2"])

    # then
    assert Jason.decode!(output) == [
             %{"name" => "A", "imports" => ["FE.Maybe"]},
             %{"name" => "FE.Maybe", "imports" => ["FE.Maybe.Error", "FE.Result", "FE.Review"]},
             %{"name" => "FE.Maybe.Error", "imports" => []},
             %{"name" => "FE.Result", "imports" => ["FE.Maybe", "FE.Review"]},
             %{"name" => "FE.Review", "imports" => ["FE.Maybe", "FE.Result"]}
           ]
  end

  test "a module calling dependency module with --max-deps-depth=0 " <>
         "in an umbrella app creates an edge on the graph" do
    # given
    project = "modules_a_and_b_call_dep_in_an_umbrella"
    deps_fetched_for_project(project)
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project, ["--max-deps-depth=0"])

    # then
    assert Jason.decode!(output) == [
             %{"name" => "A", "imports" => ["B"]},
             %{"name" => "B", "imports" => []}
           ]
  end

  test "a module calling dependency module with --max-deps-depth=1 " <>
         "in an umbrella app creates an edge on the graph" do
    # given
    project = "modules_a_and_b_call_dep_in_an_umbrella"
    deps_fetched_for_project(project)
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project, ["--max-deps-depth=1"])

    # then
    assert Jason.decode!(output) == [
             %{"name" => "A", "imports" => ["B", "FE.Maybe"]},
             %{"name" => "B", "imports" => ["FE.Maybe"]},
             %{"name" => "FE.Maybe", "imports" => []}
           ]
  end

  test "a module calling Enum without --builtin doesn't create an edge on the graph" do
    # given
    project = "module_a_calls_enum"
    deps_fetched_for_project(project)
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project, [])

    # then
    assert Jason.decode!(output) == []
  end

  test "a module calling Enum with --builtin creates an edge on the graph" do
    # given
    project = "module_a_calls_enum"
    deps_fetched_for_project(project)
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project, ["--builtin"])

    # then
    assert Jason.decode!(output) == [
             %{"name" => "A", "imports" => ["Enum"]},
             %{"name" => "Enum", "imports" => []}
           ]
  end

  test "a module calling dependency module with --max-deps-depth=0 and no --builtin " <>
         "in an umbrella app calling builtin modules creates an edge on the graph" do
    # given
    project = "modules_a_and_b_call_dep_and_builtin_in_an_umbrella"
    deps_fetched_for_project(project)
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project, ["--max-deps-depth=0"])

    # then
    assert Jason.decode!(output) == [
             %{"name" => "A", "imports" => ["B"]},
             %{"name" => "B", "imports" => []}
           ]
  end

  test "a module calling dependency module with --max-deps-depth=0 and --builtin " <>
         "in an umbrella app calling builtin modules creates edges on the graph" do
    # given
    project = "modules_a_and_b_call_dep_and_builtin_in_an_umbrella"
    deps_fetched_for_project(project)
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project, ["--max-deps-depth=0", "--builtin"])

    # then
    assert Jason.decode!(output) == [
             %{"name" => "A", "imports" => ["B", "List"]},
             %{"name" => "B", "imports" => ["Enum"]},
             %{"name" => "Enum", "imports" => []},
             %{"name" => "List", "imports" => []}
           ]
  end

  test "a module calling dependency module with --max-deps-depth=1 and no --builtin " <>
         "in an umbrella app calling builtin modules creates edges on the graph" do
    # given
    project = "modules_a_and_b_call_dep_and_builtin_in_an_umbrella"
    deps_fetched_for_project(project)
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project, ["--max-deps-depth=1"])

    # then
    assert Jason.decode!(output) == [
             %{"name" => "A", "imports" => ["B", "FE.Maybe"]},
             %{"name" => "B", "imports" => ["FE.Maybe"]},
             %{"name" => "FE.Maybe", "imports" => []}
           ]
  end

  test "a module calling dependency module with --max-deps-depth=1 and --builtin " <>
         "in an umbrella app calling builtin modules creates edges on the graph" do
    # given
    project = "modules_a_and_b_call_dep_and_builtin_in_an_umbrella"
    deps_fetched_for_project(project)
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project, ["--max-deps-depth=1", "--builtin"])

    # then
    assert Jason.decode!(output) == [
             %{"name" => "A", "imports" => ["B", "FE.Maybe", "List"]},
             %{"name" => "B", "imports" => ["Enum", "FE.Maybe"]},
             %{"name" => "Enum", "imports" => []},
             %{"name" => "Enum.EmptyError", "imports" => []},
             %{"name" => "FE.Maybe", "imports" => ["Enum", "Enum.EmptyError", "erlang"]},
             %{"name" => "List", "imports" => []},
             %{"name" => "erlang", "imports" => []}
           ]
  end

  test "a module calling protocol implementation creates an edge on the graph" do
    # given
    project = "module_a_calls_protocol"
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project)

    # then
    assert Jason.decode!(output) ==
             [
               %{"name" => "A", "imports" => ["FooProtocol"]},
               %{"name" => "FooProtocol", "imports" => ["FooProtocol.Map"]},
               %{"name" => "FooProtocol.Map", "imports" => []}
             ]
  end

  test "json with relationships can be generated for an application that logs at startup" do
    # given
    project = "application_logging_at_startup"
    project_compiled(project)
    graph_generator_compiled()

    # when
    output = graph_generated(project, ["--builtin"])

    # then
    assert Jason.decode!(output) ==
             [
               %{
                 "name" => "ApplicationLoggingAtStartup.Application",
                 "imports" => ["Logger", "Supervisor"]
               },
               %{"name" => "Logger", "imports" => []},
               %{"name" => "Supervisor", "imports" => []}
             ]
  end

  defp deps_fetched_for_project(project_name) do
    {_, 0} = System.cmd("mix", ["deps.get"], cd: project_dir(project_name))
  end

  defp project_compiled(project_name) do
    {_, 0} = System.cmd("mix", ["compile"], cd: project_dir(project_name))
  end

  defp graph_generator_compiled do
    {_, 0} = System.cmd("mix", ["compile"])
  end

  defp graph_generated(projects, options \\ [])

  defp graph_generated(projects, options) when is_list(projects) do
    projects_dirs = Enum.map(projects, &project_dir/1)

    {output, 0} =
      System.cmd(
        "mix",
        ["run", "priv/graf.exs"] ++ options ++ projects_dirs
      )

    output
  end

  defp graph_generated(project_name, options) do
    graph_generated([project_name], options)
  end

  defp project_dir(project_name) do
    Path.join([File.cwd!(), "test", "test_projects", project_name])
  end
end
