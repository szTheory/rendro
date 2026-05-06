defmodule Rendro.AuditTest do
  use ExUnit.Case, async: true

  alias Rendro.Audit

  test "scrub_metadata/1 removes password keys recursively from protection-shaped metadata" do
    metadata = %{
      stage: :protect,
      protection: %{
        algorithm: :aes_256,
        advisory_permissions: [:print],
        has_open_password: true,
        has_owner_password: true,
        open_password: "open-secret",
        owner_password: "owner-secret",
        nested: %{
          password: "nested-secret",
          safe: true
        }
      }
    }

    assert Audit.scrub_metadata(metadata) == %{
             stage: :protect,
             protection: %{
               algorithm: :aes_256,
               advisory_permissions: [:print],
               has_open_password: true,
               has_owner_password: true,
               nested: %{
                 safe: true
               }
             }
           }
  end

  test "scrub_metadata/1 removes password keys from maps inside lists" do
    metadata = %{
      audit_events: [
        %{
          protection: %{
            "open_password" => "open-secret",
            "owner_password" => "owner-secret",
            "password" => "fallback-secret",
            "algorithm" => "aes_256",
            "advisory_permissions" => ["print"],
            "has_open_password" => true
          }
        }
      ]
    }

    assert Audit.scrub_metadata(metadata) == %{
             audit_events: [
               %{
                 protection: %{
                   "algorithm" => "aes_256",
                   "advisory_permissions" => ["print"],
                   "has_open_password" => true
                 }
               }
             ]
           }
  end
end
