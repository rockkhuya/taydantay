# coding: utf-8

class Ability
  include CanCan::Ability

  def initialize(current_user, options = {})
    current_user ||= User.new

    can :read, :all

    # NOTE: Update authorizations
    can :access, :updates do |update|
      update.project.user_id == current_user.id
    end
    can :see, :updates do |update|
      !update.exclusive || !current_user.backs.with_state('confirmed').where(project_id: update.project.id).empty?
    end

    # NOTE: Project FAQ authorizations
    can :access, :project_faqs do |project_faq|
      project_faq.project.user_id == current_user.id
    end

    # NOTE: Project Document authorizations
    can :access, :project_documents do |project_document|
      project_document.project.user_id == current_user.id
    end

    # NOTE: Project authorizations
    can :create, :projects if current_user.persisted?

    can :update, :projects, [:about, :video_url, :background, :uploaded_image, :hero_image, :headline, :budget, :terms, :address_neighborhood, :address, :address_city, :address_state, :hash_tag, :site, :tag_list] do |project|
      (project.user == current_user || project.last_channel.try(:user) == current_user || current_user.channels.include?(project.last_channel)) && ( project.online? || project.waiting_funds? || project.successful? || project.failed? )
    end

    can :update, :projects do |project|
      (project.user == current_user || project.last_channel.try(:user) == current_user || current_user.channels.include?(project.last_channel)) && ( project.draft? || project.soon? || project.rejected? || project.in_analysis? )
    end

    can :send_to_analysis, :projects do |project|
      project.user == current_user
    end

    # Yes, this name is a crap. But if I use only show, it does not work.
    can :show_project, :projects do |project|
      if project.draft? || project.in_analysis?
        (current_user.admin? || project.user == current_user || project.last_channel.try(:user) == current_user || current_user.channels.include?(project.last_channel))
      else
        true
      end
    end

    # NOTE: Reward authorizations
    can :create, :rewards do |reward|
      reward.project.user == current_user
    end

    can [:update, :destroy], :rewards do |reward|
      reward.backers.with_state('waiting_confirmation').empty? && reward.backers.with_state('confirmed').empty? && (reward.project.user == current_user || reward.project.last_channel.try(:user) == current_user || current_user.channels.include?(reward.project.last_channel))
    end

    can [:update, :sort], :rewards, [:title, :description, :maximum_backers] do |reward|
      reward.project.user == current_user || reward.project.last_channel.try(:user) == current_user || current_user.channels.include?(reward.project.last_channel)
    end

    can :update, :rewards, :days_to_delivery do |reward|
      (reward.project.user == current_user || reward.project.last_channel.try(:user) == current_user || current_user.channels.include?(reward.project.last_channel)) && !reward.project.successful? && !reward.project.failed?
    end

    # NOTE: User authorizations
    can :set_email, :users do |user|
      current_user.persisted?
    end

    can :destroy, :authorizations do |authorization|
      authorization.user == current_user || current_user.admin?
    end

    can [:edit, :update, :credits, :manage, :update_password, :update_email, :settings], :users  do |user|
      current_user == user || current_user.admin?
    end

    # NOTE: Backer authorizations
    cannot :show, :backers
    can :create, :backers if current_user.persisted?

    can [ :request_refund, :credits_checkout, :show, :update, :edit], :backers do |backer|
      backer.user == current_user
    end

    cannot :update, :backers, [:user_attributes, :user_id, :user, :value, :payment_service_fee, :payment_id] do |backer|
      backer.user == current_user
    end

    # Channel authorizations
    # Due to previous abilities, first I activate all things
    # and in the final I deactivate unnecessary abilities.
    can :create, :channels_subscribers if current_user.persisted?
    can :destroy, :channels_subscribers do |cs|
      cs.user == current_user
    end

    can [:update, :edit], :channels do |c|
      c == current_user.channel || c.members.include?(current_user)
    end

    if options[:channel]  && (options[:channel] == current_user.channel || options[:channel].members.include?(current_user))
      can :access, :admin
      can :access, :admin_projects_path
      can :access, :edit_channels_profile_path
      can :access, :channels_admin_followers_path
    end

    # NOTE: admin can access everything.
    # It's the last ability to override all previous abilities.
    can :access, :all if current_user.admin?
  end
end
