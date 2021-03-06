defmodule Surface.Components.MarkdownTest do
  use Surface.ConnCase, async: true

  alias Surface.Components.Markdown

  test "translate markdown into HTML" do
    html =
      render_surface do
        ~H"""
        <#Markdown>
          # Head 1
          Bold: **bold**
          Code: `code`
        </#Markdown>
        """
      end

    assert html =~ """
           <div>\
           <h1>
           Head 1</h1>
           <p>
           Bold: <strong>bold</strong>
           Code: <code class="inline">code</code></p>
           </div>
           """
  end

  test "setting the class" do
    html =
      render_surface do
        ~H"""
        <#Markdown class="markdown">
          # Head 1
        </#Markdown>
        """
      end

    assert html =~ """
           <div class="markdown">\
           <h1>
           Head 1</h1>
           </div>
           """
  end

  test "setting multiple classes" do
    html =
      render_surface do
        ~H"""
        <#Markdown class="markdown small">
          # Head 1
        </#Markdown>
        """
      end

    assert html =~ """
           <div class="markdown small">\
           <h1>
           Head 1</h1>
           </div>
           """
  end

  test "setting unwrap removes the wrapping <div>" do
    html =
      render_surface do
        ~H"""
        <#Markdown unwrap>
          # Head 1
        </#Markdown>
        """
      end

    assert html == """
           <h1>
           Head 1</h1>
           """
  end

  test "setting opts forward options to Earmark" do
    html =
      render_surface do
        ~H"""
        <#Markdown opts={{ code_class_prefix: "language-" }}>
          ```elixir
          code
          ```
        </#Markdown>
        """
      end

    assert html =~ """
           <pre><code class="elixir language-elixir">code</code></pre>
           """
  end
end

defmodule Surface.Components.MarkdownSyncTest do
  use Surface.ConnCase

  import ExUnit.CaptureIO
  alias Surface.Components.Markdown

  describe "config" do
    test ":default_class config", %{conn: conn} do
      using_config Markdown, default_class: "content" do
        code =
          quote do
            ~H"""
            <#Markdown>
              # Head 1
            </#Markdown>
            """
          end

        view = compile_surface(code)
        {:ok, _view, html} = live_isolated(conn, view)

        assert html =~ """
               <div class="content"><h1>
               Head 1</h1></div>\
               """
      end
    end

    test "override the :default_class config", %{conn: conn} do
      using_config Markdown, default_class: "content" do
        code =
          quote do
            ~H"""
            <#Markdown class="markdown">
              # Head 1
            </#Markdown>
            """
          end

        view = compile_surface(code)
        {:ok, _view, html} = live_isolated(conn, view)

        assert html =~ """
               <div class="markdown"><h1>
               Head 1</h1></div>\
               """
      end
    end

    test ":default_opts config", %{conn: conn} do
      using_config Markdown, default_opts: [code_class_prefix: "language-"] do
        code =
          quote do
            ~H"""
            <#Markdown>
              ```elixir
              var = 1
              ```
            </#Markdown>
            """
          end

        view = compile_surface(code)
        {:ok, _view, html} = live_isolated(conn, view)

        assert html =~ """
               <div><pre><code class="elixir language-elixir">var = 1</code></pre></div>\
               """
      end
    end

    test "property opts gets merged with global config :opts (overriding existing keys)", %{
      conn: conn
    } do
      using_config Markdown, default_opts: [code_class_prefix: "language-", smartypants: false] do
        code =
          quote do
            ~H"""
            <#Markdown>
              "Elixir"
            </#Markdown>
            """
          end

        view = compile_surface(code)
        {:ok, _view, html} = live_isolated(conn, view)

        assert html =~ """
               <div><p>
               &quot;Elixir&quot;</p></div>\
               """

        code =
          quote do
            ~H"""
            <#Markdown opts={{ smartypants: true }}>
              "Elixir"

              ```elixir
              code
              ```
            </#Markdown>
            """
          end

        view = compile_surface(code)
        {:ok, _view, html} = live_isolated(conn, view)

        assert html =~
                 """
                 <div><p>
                 “Elixir”</p><pre><code class="elixir language-elixir">code</code></pre></div>\
                 """
      end
    end
  end

  describe "error/warnings" do
    test "do not accept runtime expressions" do
      code =
        quote do
          ~H"""
          <#Markdown
            class={{ @class }}>
            # Head 1
          </#Markdown>
          """
        end

      message = ~r"""
      code:2: invalid value for property "class"

      Expected a string while evaluating {{ @class }}, got: nil

      Hint: properties of macro components can only accept static values like module attributes,
      literals or compile-time expressions. Runtime variables and expressions, including component
      assigns, cannot be avaluated as they are not available during compilation.
      """

      assert_raise(CompileError, message, fn ->
        capture_io(:standard_error, fn ->
          compile_surface(code, %{class: "markdown"})
        end)
      end)
    end

    test "show parsing errors/warnings at the right line" do
      code =
        quote do
          ~H"""
          <#Markdown>
            Text
            Text `code
            Text
          </#Markdown>
          """
        end

      output =
        capture_io(:standard_error, fn ->
          compile_surface(code, %{class: "markdown"})
        end)

      assert output =~ ~r"""
             Closing unclosed backquotes ` at end of input
               code:2:\
             """
    end
  end
end
