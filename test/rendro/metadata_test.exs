defmodule Rendro.MetadataTest do
  use ExUnit.Case, async: true

  alias Rendro.Metadata

  describe "struct construction" do
    test "creates with defaults" do
      meta = %Metadata{}
      assert meta.title == nil
      assert meta.author == nil
      assert meta.creator == nil
      assert meta.creation_date == nil
      assert meta.modification_date == nil
      assert meta.custom == %{}
    end

    test "creates with all fields" do
      now = DateTime.utc_now()

      meta = %Metadata{
        title: "Report",
        author: "Jane",
        creator: "Rendro",
        creation_date: now,
        modification_date: now,
        custom: %{department: "Engineering"}
      }

      assert meta.title == "Report"
      assert meta.author == "Jane"
      assert meta.creator == "Rendro"
      assert meta.creation_date == now
      assert meta.custom.department == "Engineering"
    end
  end
end
