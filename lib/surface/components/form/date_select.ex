defmodule Surface.Components.Form.DateSelect do
  @moduledoc """
  Generates select tags for date.

  Provides a wrapper for Phoenix.HTML.Form's `date_select/3` function.

  All options passed via `opts` will be sent to `date_select/3`, `value`
  can be set directly and will override anything in `opts`.


  ## Examples

  ```
  <DateSelect form="user" field="born_at" />

  <Form for={{ :user }}>
    <DateSelect field={{ :born_at }} />
  </Form>
  ```
  """

  use Surface.Component

  import Phoenix.HTML.Form, only: [date_select: 3]
  import Surface.Components.Form.Utils

  alias Surface.Components.Form.Input.InputContext

  @doc "The form identifier"
  prop form, :form

  @doc "The field name"
  prop field, :string

  @doc "Value to pre-populate the select"
  prop value, :any

  @doc "Default value to use when none was given in 'value' and none is available in the form data"
  prop default, :any

  @doc "Options passed to the underlying 'year' select"
  prop year, :keyword

  @doc "Options passed to the underlying 'month' select"
  prop month, :keyword

  @doc "Options passed to the underlying 'day' select"
  prop day, :keyword

  @doc """
  Specify how the select can be build. It must be a function that receives a builder
  that should be invoked with the select name and a set of options.
  """
  prop builder, :fun

  @doc "Options list"
  prop opts, :keyword, default: []

  def render(assigns) do
    props =
      get_non_nil_props(assigns, [
        :value,
        :default,
        :year,
        :month,
        :day,
        :builder
      ])

    props =
      props
      |> parse_css_class_for(:year)
      |> parse_css_class_for(:month)
      |> parse_css_class_for(:day)

    ~H"""
    <InputContext assigns={{ assigns }} :let={{ form: form, field: field }}>
      {{ date_select(form, field, props) }}
    </InputContext>
    """
  end

  defp parse_css_class_for(props, field) do
    class = props[field][:class]

    if class do
      put_in(props, [field, :class], do_parse_class(class))
    else
      props
    end
  end

  defp do_parse_class(class) when is_list(class), do: Surface.css_class(class)
  defp do_parse_class(class), do: class
end