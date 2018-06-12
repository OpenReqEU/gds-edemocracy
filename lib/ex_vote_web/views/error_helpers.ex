defmodule ExVoteWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn (error) ->
      content_tag :p, translate_error(error), class: "help is-danger"
    end)
  end

  @doc """
  Checks a field for errors.
  """
  def errors?(form, field) do
    Enum.any?(Keyword.get_values(form.errors, field), fn _ -> true end)
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext "errors", "is invalid"
    #
    #     # Translate the number of files with plural rules
    #     dngettext "errors", "1 file", "%{count} files", count
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(ExVoteWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ExVoteWeb.Gettext, "errors", msg, opts)
    end
  end

  def error_json({field, [message]}) do
    %{
      field => error_message_json(message)
    }
  end

  def error_message_json(messages) when is_map(messages) do
    Enum.reduce(messages, %{}, fn (error, acc) ->
      Map.merge(acc, error_json(error))
    end)
  end

  def error_message_json(message), do: message

end
