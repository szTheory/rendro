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

    The first argument may be:

      * a `Swoosh.Email` struct
      * a `Mailglass.Message` struct (it will be unwrapped, the attachment
        added to its underlying Swoosh email, and re-wrapped via
        `Mailglass.Message.update_swoosh/2` if available)

    ## Errors

    If rendering fails, `attach_pdf/3` returns `{:error, Rendro.Error.t()}`
    so that callers can surface the failure or fall back. Rendering is
    subject to the existing core render policy (max pages/bytes), bounding
    the size of attachments produced.
    """

    @default_filename "document.pdf"
    @content_type "application/pdf"

    @doc """
    Renders `document` and attaches it to `email_or_message` as a PDF.

    Returns the modified email/message on success, or `{:error, error}` if
    rendering fails.
    """
    @spec attach_pdf(term(), Rendro.Document.t(), String.t()) ::
            term() | {:error, Rendro.Error.t()}
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
          # Best-effort: assume the value behaves like a Swoosh email.
          Swoosh.Email.attachment(email_or_message, attachment)
      end
    end

    defp build_attachment(binary, filename) do
      Swoosh.Attachment.new({:data, binary},
        filename: filename,
        content_type: @content_type
      )
    end

    defp mailglass_message?(value) do
      is_struct(value) and is_mailglass_struct(value)
    end

    defp is_mailglass_struct(%{__struct__: mod}) do
      mod_str = Atom.to_string(mod)
      String.starts_with?(mod_str, "Elixir.Mailglass.")
    end

    defp is_mailglass_struct(_), do: false

    defp swoosh_email?(%Swoosh.Email{}), do: true
    defp swoosh_email?(_), do: false

    defp attach_to_mailglass(message, attachment) do
      swoosh = extract_swoosh(message)
      updated = Swoosh.Email.attachment(swoosh, attachment)
      put_swoosh(message, updated)
    end

    defp extract_swoosh(%{swoosh: %Swoosh.Email{} = email}), do: email
    defp extract_swoosh(%{email: %Swoosh.Email{} = email}), do: email
    defp extract_swoosh(%Swoosh.Email{} = email), do: email
    defp extract_swoosh(_), do: %Swoosh.Email{}

    defp put_swoosh(message, swoosh_email) do
      cond do
        function_exported?(Mailglass.Message, :update_swoosh, 2) ->
          apply(Mailglass.Message, :update_swoosh, [message, swoosh_email])

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
