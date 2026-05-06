if Code.ensure_loaded?(Mailglass) do
  defmodule Rendro.Adapters.Mailglass do
    @moduledoc """
    Optional Mailglass/Swoosh integration for attaching rendered PDFs to
    transactional emails.

    This module is only compiled when `Mailglass` is available at compile
    time (via `Code.ensure_loaded?/1`). If `:mailglass` is not in your
    project's dependencies, this module is absent and core Rendro is
    unaffected.

    ## Usage

        email
        |> Rendro.Adapters.Mailglass.attach_pdf(document, "invoice.pdf")
        |> MyApp.Mailer.deliver()

    `attach_pdf/3` is the render-and-attach convenience path for unprotected PDFs.
    Protected delivery must pass an already-protected `%Rendro.Artifact{}` to `attach_artifact/3`.
    Mailglass never accepts, persists, derives, or manages password material.

    The first argument may be:

      * a `Swoosh.Email` struct
      * a `Mailglass.Message` struct (it will be unwrapped, the attachment
        added to its underlying Swoosh email, and re-wrapped via
        `Mailglass.Message.update_swoosh/2` if available)

    ## Errors

    `attach_pdf/3` never raises — all failure paths return an `{:error, _}` tuple:

      * `{:error, %Rendro.Error{reason: {:invalid_email_target, value}}}` — the first
        argument is neither a `%Swoosh.Email{}` nor a recognized `Mailglass.*` message
        struct (i.e. not a `%Mailglass.Message{}` and not a struct whose module name ends
        in `.Message` and exports `update_swoosh/2`). Callers should guard the input type
        before calling `attach_pdf/3`.

      * `{:error, {:unrecognized_message_shape, module}}` — the first argument looks like
        a Mailglass message (passes the `mailglass_message?/1` check) but its struct has
        neither a `:swoosh` field nor an `:email` field holding a `%Swoosh.Email{}`.
        Callers using custom `Mailglass.*` wrapper structs must ensure one of those fields
        is present, or implement `update_swoosh/2`.

      * `{:error, %Rendro.Error{}}` — the document rendering step itself failed (e.g.
        empty document, max-pages/bytes policy violation, timeout). Rendering is subject
        to the existing core render policy (max pages/bytes), bounding the size of
        attachments produced.
    """

    @default_filename "document.pdf"
    @content_type "application/pdf"

    @doc """
    Attaches a rendered `Rendro.Artifact` as a PDF to `email_or_message`.

    Protected delivery must pass an already-protected `%Rendro.Artifact{}` to `attach_artifact/3`.
    Mailglass never accepts, persists, derives, or manages password material.

    Returns the modified email/message on success, or `{:error, error}` if
    the target is invalid.
    """
    @spec attach_artifact(term(), Rendro.Artifact.t(), String.t()) ::
            term()
            | {:error, Rendro.Error.t()}
            | {:error, {:unrecognized_message_shape, atom() | term()}}
    def attach_artifact(
          email_or_message,
          %Rendro.Artifact{binary: binary},
          filename \\ @default_filename
        )
        when is_binary(filename) do
      attach_binary(email_or_message, binary, filename)
    end

    @doc """
    Renders `document` and attaches it to `email_or_message` as a PDF.

    `attach_pdf/3` is the render-and-attach convenience path for unprotected
    PDFs. Use `attach_artifact/3` when the artifact has already been protected.

    Returns the modified email/message on success, or `{:error, error}` if
    rendering fails.
    """
    @spec attach_pdf(term(), Rendro.Document.t(), String.t()) ::
            term()
            | {:error, Rendro.Error.t()}
            | {:error, {:unrecognized_message_shape, atom() | term()}}
    def attach_pdf(email_or_message, document, filename \\ @default_filename)

    def attach_pdf(email_or_message, %Rendro.Document{} = document, filename)
        when is_binary(filename) do
      case Rendro.render(document) do
        {:ok, binary} -> attach_binary(email_or_message, binary, filename)
        {:error, _} = err -> err
      end
    end

    defp attach_binary(email_or_message, binary, filename) do
      attachment = build_attachment(binary, filename)

      cond do
        mailglass_message?(email_or_message) ->
          attach_to_mailglass(email_or_message, attachment)

        swoosh_email?(email_or_message) ->
          Swoosh.Email.attachment(email_or_message, attachment)

        true ->
          {:error,
           Rendro.Error.from_stage(:render, {:invalid_email_target, email_or_message}, %{})}
      end
    end

    defp build_attachment(binary, filename) do
      Swoosh.Attachment.new({:data, binary},
        filename: filename,
        content_type: @content_type
      )
    end

    defp mailglass_message?(%Mailglass.Message{}), do: true

    defp mailglass_message?(value) when is_struct(value) do
      mod = value.__struct__

      mod
      |> Atom.to_string()
      |> String.ends_with?(".Message") and
        function_exported?(mod, :update_swoosh, 2)
    end

    defp mailglass_message?(_), do: false

    defp swoosh_email?(%Swoosh.Email{}), do: true
    defp swoosh_email?(_), do: false

    defp attach_to_mailglass(message, attachment) do
      case extract_swoosh(message) do
        {:ok, swoosh} ->
          updated = Swoosh.Email.attachment(swoosh, attachment)
          put_swoosh(message, updated)

        {:error, _} = err ->
          err
      end
    end

    defp extract_swoosh(%{swoosh: %Swoosh.Email{} = email}), do: {:ok, email}
    defp extract_swoosh(%{email: %Swoosh.Email{} = email}), do: {:ok, email}
    defp extract_swoosh(%Swoosh.Email{} = email), do: {:ok, email}

    defp extract_swoosh(other) when is_struct(other),
      do: {:error, {:unrecognized_message_shape, other.__struct__}}

    defp extract_swoosh(other),
      do: {:error, {:unrecognized_message_shape, other}}

    defp put_swoosh(message, swoosh_email) do
      cond do
        function_exported?(Mailglass.Message, :update_swoosh, 2) ->
          Mailglass.Message.update_swoosh(message, swoosh_email)

        Map.has_key?(message, :swoosh) ->
          %{message | swoosh: swoosh_email}

        Map.has_key?(message, :email) ->
          %{message | email: swoosh_email}

        true ->
          swoosh_email
      end
    end
  end
end
