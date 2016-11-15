class ReportsController < ApplicationController
  def show
    @id = params[:id]
    render
  end
end
