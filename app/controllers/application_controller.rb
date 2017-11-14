class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :check_auth

  def check_auth
  	sign_in current_or_guest_user
  end

  # if user is logged in, return current_user, else return guest_user
  def current_or_guest_user
    if current_user
      if session[:user_id] && session[:user_id] != current_user.id
        guest_user(with_retry = false).try(:reload).try(:destroy)
        session[:user_id] = nil
      end
      current_user
    else
      guest_user
    end
  end

  def guest_user(with_retry = true)
    @cached_guest_user ||= User.find(session[:user_id] ||= create_guest_user.id)

  rescue ActiveRecord::RecordNotFound # if session[:user_id] invalid
     session[:user_id] = nil
     guest_user if with_retry
  end

  private
    def create_guest_user
      u = User.new()
      u.save!
      u.remember_me!
      session[:user_id] = u.id
      u
    end
end
