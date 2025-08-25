defmodule ServerWeb.ErrorControllerTest do
  use ServerWeb.ConnCase, async: true

  test "renders 404" do
    assert ServerWeb.ErrorController.render("404.json", %{}) == %{
             errors: %{detail: "Not Found"}
           }
  end

  test "renders 500" do
    assert ServerWeb.ErrorController.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
