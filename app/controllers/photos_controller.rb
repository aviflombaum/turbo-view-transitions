class PhotosController < ApplicationController
  before_action :set_photo, only: [:show, :update]

  def index
    @photos = Photo.all
  end

  def show
  end

  def update
    @photo.increment(:likes_count)
    @photo.save
    redirect_to photo_path(@photo)
  end

  private

  def set_photo
    @photo = Photo.find(params[:id])
  end
end
