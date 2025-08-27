class HomepageController < ApplicationController
  skip_before_action :authenticate_user!

  def index
  end

  def test
    render layout: false
  end
end
