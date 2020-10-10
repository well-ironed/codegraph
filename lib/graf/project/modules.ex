defmodule Graf.Project.Modules do
  alias MapSet, as: Set

  def projects_abstract_code(projects_dirs) do
    projects_dirs
    |> Enum.flat_map(&project_beam_files/1)
    |> Enum.map(&:beam_disasm.file/1)
  end

  def deps_abstract_code(projects_dirs) do
    projects_dirs
    |> Enum.flat_map(&deps_beam_files/1)
    |> Enum.map(&:beam_disasm.file/1)
  end

  def names(abstract_code) do
    abstract_code
    |> Enum.map(fn {:beam_file, module, _, _, _, _} -> module end)
  end

  defp deps_beam_files(project_dir) do
    all = Set.new(beam_files([project_dir, "**", "ebin"]))
    project = Set.new(project_beam_files(project_dir))

    Set.difference(all, project) |> Set.to_list()
  end

  defp project_beam_files(project_dir) do
    project_dir
    |> compile_paths()
    |> Enum.flat_map(&beam_files(&1))
  end

  defp beam_files(dir) do
    (dir ++ ["*.beam"])
    |> Path.join()
    |> Path.wildcard()
    |> Enum.map(&String.to_charlist/1)
  end

  defp compile_paths(project_dir) do
    case umbrella_project?(project_dir) do
      true ->
        [project_dir, "apps", "*"]
        |> Path.join()
        |> Path.wildcard()
        |> Enum.map(&compile_path/1)

      false ->
        [compile_path(project_dir)]
    end
  end

  defp umbrella_project?(project_dir) do
    {output, 0} =
      System.cmd(
        "mix",
        ["run", "-e", "IO.puts Mix.Project.umbrella?()"],
        cd: project_dir
      )

    output
    |> String.split("\n", trim: true)
    |> List.last()
    |> case do
      "true" -> true
      "false" -> false
    end
  end

  defp compile_path(dir) do
    {output, 0} =
      System.cmd(
        "mix",
        ["run", "-e", "IO.puts Mix.Project.compile_path()"],
        cd: dir
      )

    output
    |> String.split("\n", trim: true)
    |> List.last()
    |> Path.split()
  end
end
